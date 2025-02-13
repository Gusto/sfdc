public with sharing class PayrollTransferTimeTrackingUtil {
	//To hold Analytics configuration records as per Category
	map<string, Map<String, Analytics_Configurations__mdt>> map_categoryConfigRecord = new Map<string, Map<String, Analytics_Configurations__mdt>>();

	//To hold Analytics Time Tracker records as per Order and Category
	map<Id, map<string, Analytics_Time_Tracker__c>> map_orderId_CategoryTrackerRecord = new Map<Id, map<string, Analytics_Time_Tracker__c>>();

	static final String MIN_VALUE = 'min', MAX_VALUE = 'max', START_DATE_TYPE = 'Start', END_DATE_TYPE = 'End', EARLIEST_VALUE = 'Earliest', LATEST_VALUE = 'Latest';

	Id PT_TimeTrackerRecordType;
	public PayrollTransferTimeTrackingUtil() {
		PT_TimeTrackerRecordType = cache.getRecordTypeId('Analytics_Time_Tracker__c', 'Payroll Transfer');
	}

	/*
	 * Created By PR, 28 Nov 2019
	 * Desc: fetch analytics configuration data and segregate it based on Categories
	 */
	public void getConfigData() {
		map_categoryConfigRecord = new Map<string, MAp<String, Analytics_Configurations__mdt>>();

		for (Analytics_Configurations__mdt config : [
			SELECT Id, Category__c, Date_Type__c, Event__c, Event_Criteria__c, Event_Value__c
			FROM Analytics_Configurations__mdt
			WHERE Record_Type__c = 'Payroll Transfer'
		]) {
			Map<String, Analytics_Configurations__mdt> map_config; // key is Date Type (Start or End)

			if (map_categoryConfigRecord.containsKey(config.Category__c)) {
				map_config = map_categoryConfigRecord.get(config.Category__c);
			} else
				map_config = new Map<String, Analytics_Configurations__mdt>();

			map_config.put(config.Date_Type__c, config);
			map_categoryConfigRecord.put(config.Category__c, map_config); // Key is category (Qualification, Collecting Documents, Facilitator, Customer...etc)
		}
	}
	/*
	 * Created By PR, 28 Nov 2019
	 * Desc: Fetch existing analytics time tracker records and segregate it based on Order and Config Categories i.e. Event Type
	 */
	public void getTimeStampData(set<Id> set_orderId) {
		if (set_orderId != null && set_orderId.size() > 0) {
			map_orderId_CategoryTrackerRecord = new Map<Id, map<string, Analytics_Time_Tracker__c>>();
			map<string, Analytics_Time_Tracker__c> map_categoryTrackerRecord;

			for (Analytics_Time_Tracker__c tracker : [
				SELECT Id, Start_Date__c, End_Date__c, Event_Type__c, Order__c, Record_Id__c, Object_Name__c
				FROM Analytics_Time_Tracker__c
				WHERE Order__c IN :set_orderId AND RecordTypeId = :PT_TimeTrackerRecordType AND Is_PT_Facilitator_Record__c = FALSE
			]) {
				if (map_orderId_CategoryTrackerRecord.containsKey(tracker.Order__c)) {
					map_categoryTrackerRecord = map_orderId_CategoryTrackerRecord.get(tracker.Order__c);
				} else {
					map_categoryTrackerRecord = new Map<string, Analytics_Time_Tracker__c>();
				}
				map_categoryTrackerRecord.put(tracker.Event_Type__c, tracker);
				map_orderId_CategoryTrackerRecord.put(tracker.Order__c, map_categoryTrackerRecord);
			}
		}
	}
	/*
	 * Created By ND, 29 Nov 2019
	 * Compare different metrics for each Order, to update/ create Time TRacker information
	 */
	public void syncTimeTrackingDetails(list<Order> lst_Orders) {
		if (lst_Orders != null && lst_Orders.size() > 0) {
			List<Analytics_Time_Tracker__c> lstTimeTracker = new List<Analytics_Time_Tracker__c>(); // to hold time tracker records to update/insert

			set<Id> set_orderIds = new Set<Id>();
			for (Order ord : lst_Orders) {
				set_orderIds.add(ord.Id);
			}

			getConfigData(); // get analytics configuration records
			getTimeStampData(set_orderIds); // get existing time tracker records

			if (map_categoryConfigRecord.size() > 0) {
				for (Order ord : lst_Orders) {
					//for each category, compare the metrics
					for (string categoryName : map_categoryConfigRecord.keyset()) {
						//this map will always have 2 values, one config record for End date and one for START date
						Map<String, Analytics_Configurations__mdt> map_configRec = map_categoryConfigRecord.get(categoryName);
						Analytics_Time_Tracker__c trackerRec; // current tracker record
						Analytics_Configurations__mdt configRec; // current config record

						map<string, Analytics_Time_Tracker__c> map_categoryTrackerRecord;
						if (null != map_orderId_CategoryTrackerRecord && map_orderId_CategoryTrackerRecord.containsKey(ord.Id)) {
							map_categoryTrackerRecord = map_orderId_CategoryTrackerRecord.get(ord.Id);

							//Time Tracker record already exists
							if (null != map_categoryTrackerRecord && map_categoryTrackerRecord.containsKey(categoryName)) {
								trackerRec = map_categoryTrackerRecord.get(categoryName);
							}
						}
						//Time Tracker record doesnot exist
						if (trackerRec == null) {
							//create a new instance of Time TRacker
							trackerRec = new Analytics_Time_Tracker__c(
								Order__c = ord.Id,
								Event_Type__c = categoryName,
								Object_Name__c = 'Order',
								Record_Id__c = ord.Id,
								RecordTypeId = PT_TimeTrackerRecordType
							);
						}
						if (null != map_configRec && map_configRec.size() > 0) {
							//this loop will have only 2 iterations per Config Category, one for START date and another for END Date
							for (String dateType : map_configRec.keySet()) {
								configRec = map_configRec.get(dateType);

								if (null != configRec) {
									//if Event is Status Update on Order, then we have to check Order_Status_Change_History records
									if ('Status Update'.equalsIgnoreCase(configRec.Event__c) && null != ord.Order_Status_Change_History__r && ord.Order_Status_Change_History__r.size() > 0) {
										orderStatusCheck(trackerRec, configRec, ord.Order_Status_Change_History__r);
									}
									//if Event is Checklist, then we have to check Order_Facilitator_Checklists records
									else if ('Checklist'.equalsIgnoreCase(configRec.Event__c) && null != ord.Order_Facilitator_Checklists__r && ord.Order_Facilitator_Checklists__r.size() > 0) {
										checklistCheck(trackerRec, configRec, ord.Order_Facilitator_Checklists__r);
									}
									//if Event is Order Field Update, then we just check the corresponding field on Order
									else if ('Order Field Update'.equalsIgnoreCase(configRec.Event__c)) {
										if (START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null == trackerRec.Start_Date__c) {
											trackerRec.Start_Date__c = DateTime.valueOf(ord.get(configRec.Event_Value__c));
										} else if (END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null == trackerRec.End_Date__c) {
											trackerRec.End_Date__c = DateTime.valueOf(ord.get(configRec.Event_Value__c));
										}
									}
								}
							}
							//If either of start date or end date is populated, then add it to time tracker map and list
							if (null != trackerRec.Start_Date__c || null != trackerRec.End_Date__c) {
								lstTimeTracker.add(trackerRec);

								if (null == map_categoryTrackerRecord)
									map_categoryTrackerRecord = new Map<string, Analytics_Time_Tracker__c>();

								map_categoryTrackerRecord.put(categoryName, trackerRec);
								map_orderId_CategoryTrackerRecord.put(ord.Id, map_categoryTrackerRecord);
							}
						}
					}
				}

				// if there are time tracker records to be updated, then update/insert those records
				if (lstTimeTracker.size() > 0) {
					Database.upsert(lstTimeTracker);
				}
			}
		}
	}
	/*
	 * Created By ND, 1 Dec 2019
	 * Check if Checklist changes satisfy the criteria on relevant Config records
	 */
	public void checklistCheck(Analytics_Time_Tracker__c trackerRec, Analytics_Configurations__mdt configRec, list<Order_Facilitator_Checklist__c> lst_chklst) {
		//Proceed further only if either start date or end date is not set, or Criteria is to find the latest date
		if (
			configRec.Event_Criteria__c.containsIgnoreCase(LATEST_VALUE) ||
			(START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null == trackerRec.Start_Date__c) ||
			(END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null == trackerRec.End_Date__c)
		) {
			String criteria, field;
			DateTime value;
			//To determine how the comparison should be based on whether the Earliest or the Latest value is needed
			if (configRec.Event_Criteria__c.containsIgnoreCase(EARLIEST_VALUE)) {
				criteria = MIN_VALUE;
			} else {
				criteria = MAX_VALUE;
			}
			//this is to figure out which field needs to be compared, currently it is CreatedDate, but as this is configurable, it might change
			if (configRec.Event_Criteria__c.contains(' ')) {
				field = configRec.Event_Criteria__c.split(' ')[1];
			}
			for (Order_Facilitator_Checklist__c chk : lst_chklst) {
				if (chk.get(field) == null)
					continue;
				DateTime val = DateTime.valueOf(chk.get(field));
				if (value == null) {
					value = val;
					continue;
				}
				if (criteria == MIN_VALUE && val < value) {
					value = val;
				} else if (criteria == MAX_VALUE && val > value) {
					value = val;
				}
			}
			//Set relevant date field on tracker record
			if (START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c)) {
				trackerRec.Start_Date__c = value;
			} else
				trackerRec.End_Date__c = value;
		}
	}
	/*
	 * Created By ND, 1 Dec 2019
	 * Check if Order Status changes satisfy the criteria on relevant Config records
	 */
	public void orderStatusCheck(Analytics_Time_Tracker__c trackerRec, Analytics_Configurations__mdt configRec, list<Order_Status_Change_History__c> lst_orderStatusHistory) {
		//Proceed further only if either start date or end date is not set, or Criteria is to find the latest date
		if (
			configRec.Event_Criteria__c.containsIgnoreCase(LATEST_VALUE) ||
			(START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null == trackerRec.Start_Date__c) ||
			(END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null == trackerRec.End_Date__c)
		) {
			DateTime value;
			String criteria;
			//To determine how the comparison should be based on whether the Earliest or the Latest value is needed
			if (configRec.Event_Criteria__c.containsIgnoreCase(EARLIEST_VALUE)) {
				criteria = MIN_VALUE;
			} else {
				criteria = MAX_VALUE;
			}
			if (START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null != trackerRec.Start_Date__c) {
				value = trackerRec.Start_Date__c;
			} else if (END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && null != trackerRec.End_Date__c) {
				value = trackerRec.End_Date__c;
			}
			String orderStatusToCompare;
			string orderStatusToCompare2;
			//In case of Qualification check, if it is an Auto Assigned order, take the second value in Event_Value__c
			if (configRec.Event_Value__c.contains(';') && 'Qualification'.equalsIgnoreCase(configRec.Category__c)) {
				List<String> statusValues = configRec.Event_Value__c.split(';');

				if (statusValues.size() > 1) {
					orderStatusToCompare = statusValues[0];
					orderStatusToCompare2 = statusValues[1];
				} else if (statusValues.size() > 0) {
					orderStatusToCompare = statusValues[0];
				}
			} else {
				orderStatusToCompare = configRec.Event_Value__c;
			}

			String field;
			//if End Date is needed, then we check if OrderStatusHistory.From_Status = the value in config record, otherwise we check to_Status on orderStatusHistory
			if (configRec.Event_Criteria__c.contains(END_DATE_TYPE)) {
				field = 'From_Status__c';
			} else
				field = 'To_Status__c';

			boolean isPresent = false; //in case of auto assigned PT orders this boolean will remain false
			for (Order_Status_Change_History__c rec : lst_orderStatusHistory) {
				String val = String.valueOf(rec.get(field));
				if (val.equalsIgnoreCase(orderStatusToCompare)) {
					isPresent = true;
					if (null == value || (criteria == MIN_VALUE && value > rec.End_Time__c) || (criteria == MAX_VALUE && value < rec.End_Time__c)) {
						value = rec.End_Time__c;
					}
				}
			}

			//By:PR, Date: Dec-10-19, Desc: If Order is auto assigned, we will not be able to find "Sales Submitted" OSCH record. So we will look for "Collecting documents" OSCH info.
			if ('Qualification'.equalsIgnoreCase(configRec.Category__c) && !isPresent && string.isNotBlank(orderStatusToCompare2)) {
				orderStatusToCompare = orderStatusToCompare2;
				for (Order_Status_Change_History__c rec : lst_orderStatusHistory) {
					String val = String.valueOf(rec.get(field));
					if (val.equalsIgnoreCase(orderStatusToCompare) && (null == value || (criteria == MIN_VALUE && value > rec.End_Time__c) || (criteria == MAX_VALUE && value < rec.End_Time__c))) {
						value = rec.End_Time__c;
					}
				}
			}

			if (START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && value != trackerRec.Start_Date__c) {
				trackerRec.Start_Date__c = value;
			} else if (END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && value != trackerRec.End_Date__c) {
				trackerRec.End_Date__c = value;
			}
		}
	}
}