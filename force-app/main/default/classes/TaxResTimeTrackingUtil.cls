/**
 * @name         TaxResTimeTrackingUtil
 * @author       Pravesh Rana
 * @date         08/11/2021
 * @description  Process Case records for tracking metrics for Tax Res Case Analytics
 * @test class   TaxResAnalyticsBatchTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class TaxResTimeTrackingUtil {
	String TIME_TRACKING_TAX_RES = Cache.getRecordTypeId('Analytics_Time_Tracker__c', 'Tax Resolution');
	static final String TEAM = 'Team';
	static final String METRIC_TYPE = 'Wait Time';
	static final String CYCLE_TIME = 'Cycle Time';
	static final String CONFIG_EVENT = 'Web';
	static final String ADD_HAS_PRIORITY = 'Has Priority';
	static final String CONFFIG_TYPE_TAXRES = 'Tax Res Case';

	/*
	 * Map Structure : Map<Metric_Type__c(Cycle Time/Processing Time),Map<Category__c(Qualification etc.),List<Analytics_Configurations__mdt>>>
	 */
	Map<String, Map<String, List<Analytics_Configurations__mdt>>> map_categoryConfig = new Map<String, Map<string, List<Analytics_Configurations__mdt>>>();
	static final String MIN_VALUE = 'min', MAX_VALUE = 'max', START_DATE_TYPE = 'Start', END_DATE_TYPE = 'End', EARLIEST_VALUE = 'Earliest', LATEST_VALUE = 'Latest';
	//To hold Analytics Time Tracker records as per Order per Metric and per Category
	Map<Id, Map<String, Map<string, Analytics_Time_Tracker__c>>> map_orderId_CategoryTrackerRecord = new Map<Id, Map<String, Map<string, Analytics_Time_Tracker__c>>>();

	/**
	 * @Author      : Pravesh Rana
	 * @Description : set up 'map_categoryConfig' map by populating "Analytics_Configurations__mdt"
	 *                  custom metadata records based on metric-type, category and finally list of records
	 * @Parm        : Type of "Analytics_Configurations__mdt"
	 * @Return      : void
	 **/
	public void getConfigData(String strRecTypeName) {
		for (Analytics_Configurations__mdt objConfig : [
			SELECT Id, Metric_Type__c, Category__c, Date_Type__c, Event__c, Event_Criteria__c, Event_Value__c, Additional_Info__c, Record_Type__c
			FROM Analytics_Configurations__mdt
			WHERE Record_Type__c = :strRecTypeName
		]) {
			Map<String, List<Analytics_Configurations__mdt>> map_PerMetricConfig; // key is Date Type (Start or End)
			List<Analytics_Configurations__mdt> list_configRecords; // key is Date Type (Start or End)
			String strCategory = objConfig.Category__c;

			if (strCategory == TEAM && objConfig.Metric_Type__c == METRIC_TYPE) {
				strCategory += '-' + objConfig.Additional_Info__c;
			}

			//Check for Metric Type
			if (map_categoryConfig.containsKey(objConfig.Metric_Type__c)) {
				map_PerMetricConfig = map_categoryConfig.get(objConfig.Metric_Type__c);
			} else {
				map_PerMetricConfig = new Map<String, List<Analytics_Configurations__mdt>>();
			}

			//Check for CAtegory
			if (map_PerMetricConfig.containsKey(strCategory)) {
				list_configRecords = map_PerMetricConfig.get(strCategory);
			} else {
				list_configRecords = new List<Analytics_Configurations__mdt>();
			}

			list_configRecords.add(objConfig); // Key is Date Type (Start or End)
			map_PerMetricConfig.put(strCategory, list_configRecords); // Key is category (Qualification, Advocate Collection,...etc)
			map_categoryConfig.put(objConfig.Metric_Type__c, map_PerMetricConfig); // Key is Metric Type (Cycle Time, Processing Time)
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : set up already present "Analytics_Time_Tracker__c" records in map_orderId_CategoryTrackerRecord
	 * @Parm        : set of Case Ids
	 * @Return      : void
	 **/
	public void getTimeStampData(Set<Id> set_RelatedCaseIds) {
		if (set_RelatedCaseIds != null && set_RelatedCaseIds.size() > 0) {
			map_orderId_CategoryTrackerRecord = new Map<Id, Map<String, map<string, Analytics_Time_Tracker__c>>>();
			map<String, Map<string, Analytics_Time_Tracker__c>> map_PerMetricTrackerRecord;
			map<string, Analytics_Time_Tracker__c> map_categoryTrackerRecord;

			//Construct map to hold the time tracker records for each category for each relatedRecord(BO or CO)
			for (Analytics_Time_Tracker__c objTracker : [
				SELECT Start_Date__c, Metric_Type__c, End_Date__c, Event_Type__c, Benefit_Order__c, Case__c, Carrier_Order__c, Record_Id__c, Object_Name__c, Tax_Res_Total_Wait_Duration__c
				FROM Analytics_Time_Tracker__c
				WHERE Case__c != NULL AND Case__c IN :set_RelatedCaseIds AND RecordType.Id = :TIME_TRACKING_TAX_RES
			]) {
				Id idRelatedRec = objTracker.Case__c;

				//Check for Record Id
				if (map_orderId_CategoryTrackerRecord.containsKey(idRelatedRec)) {
					map_PerMetricTrackerRecord = map_orderId_CategoryTrackerRecord.get(idRelatedRec);
				} else {
					map_PerMetricTrackerRecord = new Map<String, Map<string, Analytics_Time_Tracker__c>>();
				}

				//Check for Metric Type
				if (map_PerMetricTrackerRecord.containsKey(objTracker.Metric_Type__c)) {
					map_categoryTrackerRecord = map_PerMetricTrackerRecord.get(objTracker.Metric_Type__c);
				} else {
					map_categoryTrackerRecord = new Map<String, Analytics_Time_Tracker__c>();
				}

				//Put the existing Time_Tracker record for a given category in the map
				map_categoryTrackerRecord.put(objTracker.Event_Type__c, objTracker);
				map_PerMetricTrackerRecord.put(objTracker.Metric_Type__c, map_categoryTrackerRecord);
				map_orderId_CategoryTrackerRecord.put(idRelatedRec, map_PerMetricTrackerRecord);
			}
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : main method that is being called from "TaxResAnalyticsBatch"
	 * @Parm        : list of Case records and Type of Configuration(Tax Res)
	 * @Return      : void
	 **/
	public void syncTimeTrackingDetails(list<Case> list_Cases) {
		try {
			Map<String, Analytics_Time_Tracker__c> map_TimeTrackerRecords = new Map<String, Analytics_Time_Tracker__c>();
			if (list_Cases == null || list_Cases.size() == 0) {
				return;
			}

			//Fetch configuration records based on Record Type field on Analytics Configuration
			getConfigData(CONFFIG_TYPE_TAXRES);

			map_TimeTrackerRecords = syncTimeTrackingDetailsForCase(list_Cases, map_TimeTrackerRecords);

			if (map_TimeTrackerRecords.size() > 0) {
				Database.upsert(map_TimeTrackerRecords.values());
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('TaxResTimeTrackingUtil', 'syncTimeTrackingDetails', objExp.getMessage(), objExp.getStackTraceString() + '. line number: ' + objExp.getLineNumber());
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : loops through all the cases and created/updates instances of Analytics_Time_Tracker__c object
	 *                  based on "Analytics_Configurations__mdt" metadata records.
	 * @Parm        : list of Case records + list of already present Analytics_Time_Tracker__c records
	 * @Return      : retruns list of new created/udpdated Analytics_Time_Tracker__c object records
	 **/
	public Map<String, Analytics_Time_Tracker__c> syncTimeTrackingDetailsForCase(list<Case> list_Cases, Map<String, Analytics_Time_Tracker__c> map_TimeTracker) {
		//To get related Case ids in order to fetch existing time tracker records
		Set<Id> set_RelatedRecIds = new Set<Id>();
		Map<Id, List<Case_Audit_Log__c>> map_CaseRelatedAuditLog = new Map<Id, List<Case_Audit_Log__c>>();

		for (Case objCase : list_Cases) {
			set_RelatedRecIds.add(objCase.Id);
			if (objCase.Case_Audit_Logs__r?.size() > 0) {
				for (Case_Audit_Log__c objCaseAuditLog : objCase.Case_Audit_Logs__r) {
					if (map_CaseRelatedAuditLog.containsKey(objCase.Id)) {
						List<Case_Audit_Log__c> list_CaseAuditLogs = map_CaseRelatedAuditLog.get(objCase.Id);
						list_CaseAuditLogs.add(objCaseAuditLog);
						map_CaseRelatedAuditLog.put(objCase.Id, list_CaseAuditLogs);
					} else {
						map_CaseRelatedAuditLog.put(objCase.Id, new List<Case_Audit_Log__c>{ objCaseAuditLog });
					}
				}
			}
		}

		//fetch existing timestamp records
		getTimeStampData(set_RelatedRecIds);

		for (Case objCase : list_Cases) {
			List<Case_Audit_Log__c> list_CaseAuditLogs = new List<Case_Audit_Log__c>();
			if (map_CaseRelatedAuditLog?.containsKey(objCase.Id)) {
				list_CaseAuditLogs = map_CaseRelatedAuditLog.get(objCase.Id);
			}

			Id idSpecialist = objCase.Account_Specialist__c != null ? objCase.Account_Specialist__c : null;
			Id idCoordinator;

			if (objCase.OwnerId == objCase.Coordinator__c || (String.valueOf(objCase.OwnerId).startsWith('005') && objCase.OwnerId != objCase.Account_Specialist__c)) {
				idCoordinator = objCase.OwnerId;
			}

			//for each Metric Type and Category, compare the metrics
			if (map_categoryConfig != null && map_categoryConfig.size() > 0 && list_CaseAuditLogs.size() > 0) {
				for (String strMetricName : map_categoryConfig.keyset()) {
					Map<String, List<Analytics_Configurations__mdt>> map_PerCategoryConfig = map_categoryConfig.get(strMetricName);
					Analytics_Time_Tracker__c objWaitTimeAnalyticRecord;

					for (string strCategoryName : map_PerCategoryConfig.keyset()) {
						//this map will always have 2 values, one config record for End date and one for START date
						List<Analytics_Configurations__mdt> list_configRec = map_PerCategoryConfig.get(strCategoryName);
						Analytics_Time_Tracker__c objTracker; // current tracker record
						Map<string, Map<String, Analytics_Time_Tracker__c>> map_MetricViseTrackerRec;
						Map<string, Analytics_Time_Tracker__c> map_categoryTrackerRecord;

						if (strMetricName == METRIC_TYPE) {
							strCategoryName = TEAM;
							if (objWaitTimeAnalyticRecord != null) {
								objTracker = objWaitTimeAnalyticRecord;
							}
						}

						if (map_orderId_CategoryTrackerRecord != null && map_orderId_CategoryTrackerRecord.containsKey(objCase.Id)) {
							map_MetricViseTrackerRec = map_orderId_CategoryTrackerRecord.get(objCase.Id);

							if (map_MetricViseTrackerRec != null && map_MetricViseTrackerRec.containsKey(strMetricName)) {
								map_categoryTrackerRecord = map_MetricViseTrackerRec.get(strMetricName);

								//Time Tracker record already exists
								if (map_categoryTrackerRecord != null && map_categoryTrackerRecord.containsKey(strCategoryName)) {
									objTracker = map_categoryTrackerRecord.get(strCategoryName);
								}
							}
						}

						//Time Tracker record doesnot exist
						if (objTracker == null) {
							//create a new instance of Time TRacker
							objTracker = new Analytics_Time_Tracker__c(
								Case__c = objCase.Id,
								Event_Type__c = strCategoryName,
								Object_Name__c = 'Case',
								Record_Id__c = objCase.Id,
								RecordTypeId = TIME_TRACKING_TAX_RES,
								Metric_Type__c = strMetricName
							);
						}

						if (list_configRec != null && list_configRec.size() > 0) {
							if (strMetricName == METRIC_TYPE) {
								getWaitTimeDetails(objTracker, list_configRec, list_CaseAuditLogs);
							} else {
								for (Analytics_Configurations__mdt objConfig : list_configRec) {
									if (objConfig != null) {
										caseStatusCheck(objTracker, objConfig, list_CaseAuditLogs, idSpecialist, idCoordinator);
									}
								}
							}
						}

						//If either of start date or end date is populated, then add it to time tracker map and list
						if (objTracker.Start_Date__c != null || objTracker.End_Date__c != null || objTracker.Tax_Res_Total_Wait_Duration__c != null) {
							if (
								(strCategoryName == CaseUtils.TAXRES_ACCOUNT_SPECIALIST &&
								objCase.Account_Specialist__c != null) ||
								strCategoryName == CaseUtils.TAXRES_COORDINATOR ||
								(strCategoryName.indexOf(TEAM) > -1 &&
								strMetricName == CYCLE_TIME)
							) {
								map_TimeTracker.put(String.valueOf(objTracker.Start_Date__c) + String.valueOf(objTracker.End_Date__c) + objTracker.Tax_Res_Total_Wait_Duration__c, objTracker);
							}

							if (map_MetricViseTrackerRec == null) {
								map_MetricViseTrackerRec = new Map<string, Map<String, Analytics_Time_Tracker__c>>();
							}

							if (map_categoryTrackerRecord == null) {
								map_categoryTrackerRecord = new Map<string, Analytics_Time_Tracker__c>();
							}

							map_categoryTrackerRecord.put(strCategoryName, objTracker);
							map_MetricViseTrackerRec.put(strMetricName, map_categoryTrackerRecord);
							map_orderId_CategoryTrackerRecord.put(objCase.Id, map_MetricViseTrackerRec);
						}

						if (strMetricName == METRIC_TYPE) {
							objWaitTimeAnalyticRecord = objTracker;
						}
					}

					if (strMetricName == METRIC_TYPE && objWaitTimeAnalyticRecord != null) {
						map_TimeTracker.put(
							String.valueOf(objWaitTimeAnalyticRecord.Start_Date__c) + String.valueOf(objWaitTimeAnalyticRecord.End_Date__c) + objWaitTimeAnalyticRecord.Tax_Res_Total_Wait_Duration__c,
							objWaitTimeAnalyticRecord
						);
					}
				}
			}
		}

		return map_TimeTracker;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : calculated total "Waiting Time" for a particular case, based on exact matching of  "Analytics_Configurations__mdt"
	 *                  records criteria with the "Case_Audit_Log__c" object records
	 * @Parm        : Analytics_Time_Tracker__c object record + List of Analytics_Configurations__mdt custom meta data +
	 *                  list of related Case_Audit_Log__c records
	 * @Return      : void
	 **/
	public void getWaitTimeDetails(Analytics_Time_Tracker__c objTracker, List<Analytics_Configurations__mdt> list_objConfigs, list<Case_Audit_Log__c> list_CaseAuditLogs) {
		if (list_objConfigs != null && list_objConfigs.size() > 0) {
			String strStartStatus = '';
			String strEndStatus = '';
			DateTime dtStartDateTime;
			DateTime dtEndDateTime;
			Decimal decDurationInSec = 0;

			//Will always have two records i.e. Start and End records
			for (Analytics_Configurations__mdt objConfig : list_objConfigs) {
				if (objConfig.Category__c == TEAM && objConfig.Metric_Type__c == METRIC_TYPE) {
					if (objConfig.Date_Type__c == 'Start') {
						strStartStatus = objConfig.Event_Value__c;
					} else {
						strEndStatus = objConfig.Event_Value__c;
					}
				}
			}

			//this loop will have only 2 iterations per Config Category, one for START date and another for END Date
			for (Case_Audit_Log__c objLog : list_CaseAuditLogs) {
				if (objLog.From_Status__c == strStartStatus && objLog.To_Status__c == strEndStatus) {
					if (objLog.Duration_In_Seconds__c != null) {
						decDurationInSec = objLog.Duration_In_Seconds__c;
					}

					continue;
				}
			}

			if (decDurationInSec != null) {
				Decimal decTotalWaitingTime = objTracker.Tax_Res_Total_Wait_Duration__c == null ? 0 : objTracker.Tax_Res_Total_Wait_Duration__c;
				objTracker.Tax_Res_Total_Wait_Duration__c = decTotalWaitingTime + (decDurationInSec / 60);
			}
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : loops through "Case_Audit_Log__c" oject records to find the correct datetime based on "Analytics_Configurations__mdt"
	 *                  custom-meta data configuration
	 * @Parm        : Analytics_Time_Tracker__c object record + List of Analytics_Configurations__mdt custom meta data +
	 *                  list of related Case_Audit_Log__c records +
	 *                  Related Aaccount Specialist Id + Related Coordinator Id
	 * @Return      : void
	 **/
	public void caseStatusCheck(Analytics_Time_Tracker__c objTracker, Analytics_Configurations__mdt objConfig, list<Case_Audit_Log__c> list_CaseAuditLogs, Id idSpecialist, Id idCoordinator) {
		//Proceed further only if either start date or end date is not set, or Criteria is to find the latest date
		if (
			objConfig.Event_Criteria__c.containsIgnoreCase(LATEST_VALUE) ||
			(START_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && null == objTracker.Start_Date__c) ||
			(END_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && null == objTracker.End_Date__c)
		) {
			DateTime dtmValue;
			String strCriteria;
			//To determine how the comparison should be based on whether the Earliest or the Latest value is needed
			if (objConfig.Event_Criteria__c.containsIgnoreCase(EARLIEST_VALUE)) {
				strCriteria = MIN_VALUE;
			} else {
				strCriteria = MAX_VALUE;
			}

			if (START_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && null != objTracker.Start_Date__c) {
				dtmValue = objTracker.Start_Date__c;
			} else if (END_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && null != objTracker.End_Date__c) {
				dtmValue = objTracker.End_Date__c;
			}

			String strCaseStatusToCompare;
			strCaseStatusToCompare = objConfig.Event_Value__c;

			String strFieldName;
			if (objConfig.Event_Criteria__c.contains(END_DATE_TYPE)) {
				strFieldName = 'To_Status__c';
			} else {
				strFieldName = 'From_Status__c';
			}

			for (Case_Audit_Log__c objLog : list_CaseAuditLogs) {
				String strLogCategory = '';

				if (objLog.CreatedById == idSpecialist) {
					strLogCategory = 'Account Specialist';
				} else if (objLog.CreatedById == idCoordinator) {
					strLogCategory = 'Coordinator';
				}

				//for email status we want to make sure that we only consider matching role records
				if (objConfig.Category__c != strLogCategory && objConfig.Event__c == 'Status Update' && objConfig.Category__c != 'Team') {
					continue;
				}

				DateTime dtComparisonDate = objLog.To_Date_Time__c;
				if (strFieldName == 'From_Status__c') {
					dtComparisonDate = objLog.From_Date_Time__c;
				}

				String val = objLog.get(strFieldName) != null ? String.valueOf(objLog.get(strFieldName)) : '';
				if (val.equalsIgnoreCase(strCaseStatusToCompare)) {
					if (null == dtmValue || (strCriteria == MIN_VALUE && dtmValue > dtComparisonDate) || (strCriteria == MAX_VALUE && dtmValue < dtComparisonDate)) {
						dtmValue = dtComparisonDate;
						if (CONFIG_EVENT.equalsIgnoreCase(objConfig.Event__c) && START_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c)) {
							dtmValue = objLog.createdDate;
						}
					}
				}
			}

			if (objConfig.Metric_Type__c == METRIC_TYPE) {
				if (START_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && dtmValue != objTracker.Start_Date__c) {
					objTracker.Start_Date__c = dtmValue;
				} else if (END_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && dtmValue != objTracker.End_Date__c) {
					objTracker.End_Date__c = dtmValue;
				}
			} else {
				if (START_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && dtmValue != objTracker.Start_Date__c) {
					if (objTracker.Start_Date__c == null || (objTracker.Start_Date__c != null && objConfig.Additional_Info__c == ADD_HAS_PRIORITY)) {
						objTracker.Start_Date__c = dtmValue;
					}
				} else if (END_DATE_TYPE.equalsIgnoreCase(objConfig.Date_Type__c) && dtmValue != objTracker.End_Date__c) {
					if (objTracker.End_Date__c == null || (objTracker.End_Date__c != null && objConfig.Additional_Info__c == ADD_HAS_PRIORITY)) {
						objTracker.End_Date__c = dtmValue;
					}
				}
			}
		}
	}
}