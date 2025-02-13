/*
Author      :   Pravesh Rana
Date        :   January,5,2021
Description :   This class is related to "AdvisingEmailCARegionAssignment" visual page. This class is developed as a part of
                "Advising Email Automation" module.
                This class is used to bulk assign Region to Renewal Opporutnities where under writing State is "California"
*/
public with sharing class AdvisingEmailCARegionAssignmentCtrl {
	//this variable is used to get the ser selected month value from vf page
	public String strSelectedMonth { get; set; }
	//this variable is used to store current year value
	public String strSelectedYear { get; set; }
	public List<SelectOption> list_Years { get; set; }
	//this variable contains the final region stats details, that we want to display on the page
	public RegionDetailWrapper objRegionDetails { get; set; }
	//indicates that we have to unassign region for the CA Opp
	public Boolean blnIsUnassigned { get; set; }
	//indicates if want to assing only from unassigned Opp where stage = Ready For Default Pending
	public Boolean blnAssignRFDOnly { get; set; }
	//below three variables contains opp count for region assignment filled by user on vf page
	public Integer intCAEastAdditionaRegion { get; set; }
	public Integer intCAWestAdditionaRegion { get; set; }
	public Integer intCACentralAdditionaRegion { get; set; }
	//below three variables are used in "getRegionwiseValues" method
	Integer intRegionTotal = 0;
	Integer intRegionClosedTotal = 0;
	Integer intCARegionTotal = 0;
	Integer intCARegionClosedTotal = 0;
	Integer intTotalReadyForDefault = 0;
	//below two variables contains start and end date of the month selected by user from the Vf page
	Date dtSelectedMonthStartDate;
	Date dtSelectedMonthEndDate;
	Map<String, List<Opportunity>> map_CARegionOpportunityList = new Map<String, List<Opportunity>>();
	Integer intRecordToBeUpdatedInSyncLimit = 30;
	//Constants
	Set<String> set_ToExcludeOpportunityStageNames = new Set<String>{ 'Closed Admin', 'Closed Lost' }; //'Closed Won',
	public static String OPP_StageName_ReadyForDefault = 'Ready for Default Package';
	public Id idAssignmentBatchJob { get; set; }

	static String ErrorMsg_InvalidNumber = 'Incorrect input, please fill up the fields with valid numbers.';
	static String ErrorMsg_AssignedGreaterThenUnAssigned = 'Incorrect input, total proposed assignments can not be greater then available unassigned records.';
	static String ErrorMsg_UnAssignedGreaterThenAssigned = 'Incorrect input, total proposed unassignments can not be greater then available assigned records.';
	static String ErrorMsg_AssignmentInProcess = 'Regions assignment is in process.';
	static String ErrorMsg_AssignmentStillInProcess = 'Regions assignment is still in process.';
	static String ErrorMsg_Success = 'Records updated successfully.';
	static String ErrorMsg_Failure = 'Error while saving records. ';
	static String APEX_JOB_STATUS_COMPLETED = 'Completed';

	//constructor
	public AdvisingEmailCARegionAssignmentCtrl() {
		blnIsUnassigned = false;
		blnAssignRFDOnly = false;
		list_Years = new List<SelectOption>();
		for (integer i = 0; i < 4; i++) {
			list_Years.add(new SelectOption(String.valueOf(system.today().addYears(i).year()), String.valueOf(system.today().addYears(i).year())));
		}

		getRegionDetails();
		resetCAPanelValues();
	}

	//this method is used to get the region stat details based on selected month by the user
	public void getRegionDetails() {
		//SJay - 02/02/2021 - Changed date to 2 months from now.
		//strSelectedMonth = String.valueOf(system.now().addMonths(2).format('MM'));
		if (String.isBlank(strSelectedMonth)) {
			setDefaultFilters();
		}

		dtSelectedMonthStartDate = Date.newInstance(Integer.valueOf(strSelectedYear), Integer.valueof(strSelectedMonth), 1);
		dtSelectedMonthEndDate = dtSelectedMonthStartDate.addDays(Date.daysInMonth(Integer.valueOf(strSelectedYear), Integer.valueof(strSelectedMonth)) - 1);

		objRegionDetails = new RegionDetailWrapper();
		map_CARegionOpportunityList = new Map<String, List<Opportunity>>();

		getRegionWiseValues('East');
		objRegionDetails.intEastTotal = intRegionTotal;
		objRegionDetails.intEastClosedTotal = intRegionClosedTotal;
		objRegionDetails.intCAEastTotal = intCARegionTotal;
		objRegionDetails.intCAEastClosedTotal = intCARegionClosedTotal;
		objRegionDetails.intEastRFDTotal = intTotalReadyForDefault;

		getRegionWiseValues('West');
		objRegionDetails.intWestTotal = intRegionTotal;
		objRegionDetails.intWestClosedTotal = intRegionClosedTotal;
		objRegionDetails.intCAWestTotal = intCARegionTotal;
		objRegionDetails.intCAWestClosedTotal = intCARegionClosedTotal;
		objRegionDetails.intWestRFDTotal = intTotalReadyForDefault;

		getRegionWiseValues('Central');
		objRegionDetails.intCentralTotal = intRegionTotal;
		objRegionDetails.intCentralClosedTotal = intRegionClosedTotal;
		objRegionDetails.intCACentralTotal = intCARegionTotal;
		objRegionDetails.intCACentralClosedTotal = intCARegionClosedTotal;
		objRegionDetails.intCentralRFDTotal = intTotalReadyForDefault;

		objRegionDetails.intCATotalUnassignedRegion = [
			SELECT COUNT()
			FROM Opportunity
			WHERE
				UW_State_PY__c = 'California'
				AND Region__c = NULL
				AND HI_Effective_Date__c >= :dtSelectedMonthStartDate
				AND HI_Effective_Date__c <= :dtSelectedMonthEndDate
				AND RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
		];
		objRegionDetails.intCATotalUnassignedReadyForDefault = [
			SELECT COUNT()
			FROM Opportunity
			WHERE
				UW_State_PY__c = 'California'
				AND StageName = :OPP_StageName_ReadyForDefault
				AND Region__c = NULL
				AND HI_Effective_Date__c >= :dtSelectedMonthStartDate
				AND HI_Effective_Date__c <= :dtSelectedMonthEndDate
				AND RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
		];
	}

	//parameter: Region Name, Process: Queries Opporutnity records that are open based on parameter
	public void getRegionWiseValues(String strRegionName) {
		intRegionTotal = 0;
		intRegionClosedTotal = 0;
		intCARegionTotal = 0;
		intCARegionClosedTotal = 0;
		intTotalReadyForDefault = 0;

		if (String.isNotBlank(strRegionName)) {
			String strTempRegionName = '%' + strRegionName + '%';
			for (Opportunity objOpp : [
				SELECT Id, StageName, Region__c, IsClosed
				FROM Opportunity
				WHERE
					StageName NOT IN :set_ToExcludeOpportunityStageNames
					AND Region__c LIKE :strTempRegionName
					AND HI_Effective_Date__c >= :dtSelectedMonthStartDate
					AND HI_Effective_Date__c <= :dtSelectedMonthEndDate
					AND RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
			]) {
				//CA Region logic
				if (String.isNotBlank(objOpp.Region__c) && objOpp.Region__c != strRegionName) {
					if (objOpp.IsClosed) {
						intCARegionClosedTotal++;
					} else {
						intCARegionTotal++;
						List<Opportunity> list_OppTemp = new List<Opportunity>();
						if (map_CARegionOpportunityList.containsKey(objOpp.Region__c)) {
							list_OppTemp = map_CARegionOpportunityList.get(objOpp.Region__c);
						}
						list_OppTemp.add(objOpp);
						map_CARegionOpportunityList.put(objOpp.Region__c, list_OppTemp);
					}
				} else {
					if (objOpp.IsClosed) {
						intCARegionClosedTotal++;
					} else {
						intRegionTotal++;
					}
				}

				if (objOpp.StageName == OPP_StageName_ReadyForDefault) {
					intTotalReadyForDefault++;
				}
			}
		}
	}

	//sets Current month and Year as default value for month and year filters
	public void setDefaultFilters() {
		if (String.isBlank(strSelectedMonth)) {
			strSelectedMonth = String.valueOf(system.now().addMonths(3).formatGMT('M'));
		}
		if (String.isBlank(strSelectedYear)) {
			strSelectedYear = String.valueOf(system.today().addMonths(3).year());
		}
	}

	public void resetCAPanelValues() {
		intCAEastAdditionaRegion = 0;
		intCAWestAdditionaRegion = 0;
		intCACentralAdditionaRegion = 0;
	}

	public void saveAssignRegionToOpportunities() {
		//validation
		if (intCAEastAdditionaRegion == null || intCAWestAdditionaRegion == null || intCACentralAdditionaRegion == null) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ErrorMsg_InvalidNumber));
			return;
		}

		Integer intTotalOppCount = intCAEastAdditionaRegion + intCAWestAdditionaRegion + intCACentralAdditionaRegion;

		if (intTotalOppCount > 0) {
			Map<Id, Opportunity> map_oppToUpdate = new Map<Id, Opportunity>();

			try {
				if (!blnIsUnassigned) {
					//validation
					if (!blnAssignRFDOnly && intTotalOppCount > objRegionDetails.intCATotalUnassignedRegion) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ErrorMsg_AssignedGreaterThenUnAssigned));
						return;
					}

					if (blnAssignRFDOnly && intTotalOppCount > objRegionDetails.intCATotalUnassignedReadyForDefault) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ErrorMsg_AssignedGreaterThenUnAssigned));
						return;
					}

					AdvisingEmailCARegionAssignmentBatch batchController = new AdvisingEmailCARegionAssignmentBatch();
					batchController.intCAEastCount = intCAEastAdditionaRegion;
					batchController.intCAWestCount = intCAWestAdditionaRegion;
					batchController.intCACentralCount = intCACentralAdditionaRegion;
					batchController.blnIsAssignment = true;
					batchController.blnIsAssignmentRFDOnly = blnAssignRFDOnly;
					batchController.dtSelectedMonthStartDate = dtSelectedMonthStartDate;
					batchController.dtSelectedMonthEndDate = dtSelectedMonthEndDate;
					batchController.intNumberOfRecordsProcessed = 0;
					if (intTotalOppCount <= intRecordToBeUpdatedInSyncLimit) {
						String strQuery = batchController.getRelatedQuery();
						batchController.updateOpportunityRegion(Database.query(strQuery));
					} else {
						idAssignmentBatchJob = database.executeBatch(batchController);
					}
				} else {
					//validation
					Integer intTotalCAAssinged = objRegionDetails.intCAEastTotal + objRegionDetails.intCAWestTotal + objRegionDetails.intCACentralTotal;
					if (intTotalOppCount > intTotalCAAssinged) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ErrorMsg_UnAssignedGreaterThenAssigned));
						return;
					}

					if (intCAEastAdditionaRegion > 0) {
						map_oppToUpdate.putAll(getToUnassignOpportunityRecords(intCAEastAdditionaRegion, map_CARegionOpportunityList.get('CA East')));
					}
					if (intCAWestAdditionaRegion > 0) {
						map_oppToUpdate.putAll(getToUnassignOpportunityRecords(intCAWestAdditionaRegion, map_CARegionOpportunityList.get('CA West')));
					}
					if (intCACentralAdditionaRegion > 0) {
						map_oppToUpdate.putAll(getToUnassignOpportunityRecords(intCACentralAdditionaRegion, map_CARegionOpportunityList.get('CA Central')));
					}

					AdvisingEmailCARegionAssignmentBatch batchController = new AdvisingEmailCARegionAssignmentBatch();
					batchController.blnIsAssignment = false;
					batchController.intNumberOfRecordsProcessed = 0;
					if (intTotalOppCount <= intRecordToBeUpdatedInSyncLimit) {
						batchController.updateOpportunityRegion(map_oppToUpdate.values());
					} else {
						batchController.set_OppIdsForUnassignment = map_oppToUpdate.keySet();
						idAssignmentBatchJob = database.executeBatch(batchController);
					}
				}

				if (intTotalOppCount > intRecordToBeUpdatedInSyncLimit) {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.CONFIRM, ErrorMsg_AssignmentInProcess));
				} else {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.CONFIRM, ErrorMsg_Success));
				}
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ErrorMsg_Failure + ex.getMessage()));
				return;
			}

			resetCAPanelValues();
			getRegionDetails();
		}
	}

	//this method is called to clear out the region and calendly URl in case of unassignment
	public map<Id, Opportunity> getToUnassignOpportunityRecords(Integer intUnassignmentCount, List<Opportunity> list_MasterOppRec) {
		Map<Id, Opportunity> map_toSendOppRecs = new Map<Id, Opportunity>();

		if (intUnassignmentCount != null && intUnassignmentCount > 0 && list_MasterOppRec != null && list_MasterOppRec.size() > 0) {
			for (Integer intCount = 0; intCount < intUnassignmentCount; intCount++) {
				Opportunity objOppRec = list_MasterOppRec.get(intCount);
				map_toSendOppRecs.put(objOppRec.Id, objOppRec);
			}
		}

		return map_toSendOppRecs;
	}

	public void checkBatchJobStatus() {
		if (idAssignmentBatchJob != null) {
			List<AsyncApexJob> list_ApexJobs = [
				SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
				FROM AsyncApexJob
				WHERE ID = :idAssignmentBatchJob
			];
			if (list_ApexJobs != null && list_ApexJobs.size() > 0) {
				if (list_ApexJobs.get(0).Status.equalsIgnoreCase(APEX_JOB_STATUS_COMPLETED)) {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.CONFIRM, ErrorMsg_Success));
					idAssignmentBatchJob = null;
				} else {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.INFO, ErrorMsg_AssignmentStillInProcess));
				}
			}
		}
	}

	//wrapper class to display information on page
	public class RegionDetailWrapper {
		public Integer intEastTotal { get; set; }
		public Integer intWestTotal { get; set; }
		public Integer intCentralTotal { get; set; }

		public Integer intCAEastTotal { get; set; }
		public Integer intCAWestTotal { get; set; }
		public Integer intCACentralTotal { get; set; }

		public Integer intEastRFDTotal { get; set; }
		public Integer intWestRFDTotal { get; set; }
		public Integer intCentralRFDTotal { get; set; }

		public Integer intEastClosedTotal { get; set; }
		public Integer intWestClosedTotal { get; set; }
		public Integer intCentralClosedTotal { get; set; }

		public Integer intCAEastClosedTotal { get; set; }
		public Integer intCAWestClosedTotal { get; set; }
		public Integer intCACentralClosedTotal { get; set; }

		public Integer intCATotalUnassignedRegion { get; set; }
		public Integer intCATotalUnassignedReadyForDefault { get; set; }

		public RegionDetailWrapper() {
			intEastTotal = 0;
			intWestTotal = 0;
			intCentralTotal = 0;
			intCACentralTotal = 0;
			intCAEastTotal = 0;
			intCAWestTotal = 0;
			intEastRFDTotal = 0;
			intWestRFDTotal = 0;
			intCentralRFDTotal = 0;
			intEastRFDTotal = 0;
			intWestClosedTotal = 0;
			intCentralClosedTotal = 0;
			intCAEastClosedTotal = 0;
			intCAWestClosedTotal = 0;
			intCACentralClosedTotal = 0;
			intCATotalUnassignedRegion = 0;
			intCATotalUnassignedReadyForDefault = 0;
		}
	}
}