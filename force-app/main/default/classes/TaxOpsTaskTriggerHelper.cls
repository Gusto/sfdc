public with sharing class TaxOpsTaskTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;
	private static List<Tax_Ops_Task_Log__c> taxOpsTaskAuditLogList = new List<Tax_Ops_Task_Log__c>();

	public void OnBeforeInsert(List<Tax_Ops_Task__c> tasks) {
		counter++;
		for (Tax_Ops_Task__c reC : tasks) {
			rec.Status_Change_Date_Time__c = system.now();
		}
		assignAgencyInfo(tasks);
	}

	public void OnAfterInsert(Map<ID, Tax_Ops_Task__c> newTaxOpsTaskMap) {
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedTaxOpsTaskIDs) {
	}

	public void OnBeforeUpdate(Map<ID, Tax_Ops_Task__c> oldTaxOpsTaskMap, Map<ID, Tax_Ops_Task__c> newTaxOpsTaskMap) {
		counter++;
		list<Tax_Ops_Task__c> withoutAgencyTaskList = new List<Tax_Ops_Task__c>();
		//process step changes automatically update the status to in progress
		for (Tax_Ops_Task__c rec : newTaxOpsTaskMap.values()) {
			Tax_Ops_Task__c oldRec = oldTaxOpsTaskMap.get(rec.id);
			if (oldRec.Process_step__c != rec.Process_step__c && string.valueof(rec.OwnerId).indexof('005') == 0) {
				if (rec.Confirmation_Complete__c && rec.Process_step__c.equalsIgnoreCase('Confirmation')) {
					rec.Status__c = 'Completed';
				} else if (rec.Failed_Filings_Completed__c && rec.Process_step__c.equalsIgnoreCase('Failed Filing')) {
					rec.Status__c = 'Completed';
				} else if (rec.Filing_Completed__c && rec.Process_step__c.equalsIgnoreCase('Filing')) {
					rec.Status__c = 'Completed';
				} else if (rec.Payments_Completed__c && rec.Process_step__c.equalsIgnoreCase('Payments')) {
					rec.Status__c = 'Completed';
				} else {
					rec.Status__c = 'In Progress';
				}
			}

			if (rec.Agency_Information__c == null) {
				withoutAgencyTaskList.add(rec);
			}
		}
		if (withoutAgencyTaskList.size() > 0) {
			assignAgencyInfo(withoutAgencyTaskList);
		}
		processStatusChangeAuditLog(oldTaxOpsTaskMap, newTaxOpsTaskMap);
	}

	public void OnAfterUpdate(Map<ID, Tax_Ops_Task__c> oldTaxOpsTaskMap, Map<ID, Tax_Ops_Task__c> newTaxOpsTaskMap) {
		if (taxOpsTaskAuditLogList.size() > 0 && counter == 1) {
			try {
				insert taxOpsTaskAuditLogList;
			} catch (exception ex) {
			}
			taxOpsTaskAuditLogList = new List<Tax_Ops_Task_Log__c>();
		}
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedTaxOpsTaskIDs) {
	}

	public void OnBeforeDelete(Tax_Ops_Task__c[] taxOpsTaskToDelete, Map<ID, Tax_Ops_Task__c> oldTaxOpsTaskMap) {
		counter++;
	}

	public void OnAfterDelete(Tax_Ops_Task__c[] deletedTaxOpsTasks, Map<ID, Tax_Ops_Task__c> oldTaxOpsTaskMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedTaxOpsTaskIDs) {
	}

	public void OnUndelete(Tax_Ops_Task__c[] restoredTaxOpsTasks) {
		counter++;
	}
	//BY: PR, 1/15/2019, Desc: We are creating Task Logs on the change of the Tax Ops Task's status change
	public void processStatusChangeAuditLog(Map<ID, Tax_Ops_Task__c> oldTaxOpsTaskMap, Map<ID, Tax_Ops_Task__c> newTaxOpsTaskMap) {
		List<BusinessHours> bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']); //'Test IST'
		List<Tax_Ops_Task_Log__c> logList = new List<Tax_Ops_Task_Log__c>();
		for (Tax_Ops_Task__c c : newTaxOpsTaskMap.values()) {
			Tax_Ops_Task__c oldTask = oldTaxOpsTaskMap.get(c.Id);
			DateTime statusChange = c.Status_Change_Date_Time__c;

			if (oldTask.Status__c != c.Status__c || oldTask.Process_Step__c != c.Process_Step__c) {
				Tax_Ops_Task_Log__c log = new Tax_Ops_Task_Log__c();
				log.Tax_Ops_Task__c = c.id;
				if (oldTask.Status__c == c.Status__c && oldTask.Process_Step__c != c.Process_Step__c) {
					log.From_Status__c = c.Status__c;
					log.To_Status__c = c.Status__c;
					log.Process_Step__c = oldTask.Process_Step__c;
				} else if (oldTask.Status__c != c.Status__c && oldTask.Process_Step__c != c.Process_Step__c) {
					log.From_Status__c = oldTask.Status__c;
					log.To_Status__c = c.Status__c;
					log.Process_Step__c = oldTask.Process_Step__c;
				} else {
					log.From_Status__c = oldTask.Status__c;
					log.To_Status__c = c.Status__c;
					log.Process_Step__c = c.Process_Step__c;
				}
				log.From_Date_Time__c = statusChange;
				log.To_Date_Time__c = System.now();

				if (bizHours.size() > 0) {
					log.Business_Hours__c = bizHours[0].Id;
					Id hoursId = log.Business_Hours__c;
					DateTime fromTime = log.From_Date_Time__c;
					DateTime toTime = log.To_Date_Time__c;
					if (fromTime != null) {
						Long milliSeconds = BusinessHours.diff(hoursId, fromTime, toTime);
						log.Duration_in_seconds__c = milliSeconds / 1000;
					}
				}
				taxOpsTaskAuditLogList.add(log);
				c.Status_Change_Date_Time__c = System.now();
			}
		}
	}

	public void assignAgencyInfo(Tax_Ops_Task__c[] taskList) {
		if (taskList != null && taskList.size() > 0) {
			map<string, Agency_Information__c> taxCodeAgencyMap = new Map<string, Agency_Information__c>();
			string findVarStr;
			String queryString = 'Select id,Tax_Code__c,Agency_Rep__c From Agency_Information__c Where ';

			

			for (Tax_Ops_Task__c rec : taskList) {
				if (String.isBlank(findVarStr))
					findVarStr = 'Tax_Code__c LIKE \'%' + rec.Tax_Code__c + '%\'';
				else
					findVarStr += ' OR Tax_Code__c LIKE \'%' + rec.Tax_Code__c + '%\'';
			}

			// we are using sosl to find tax ops in Tax_code field because we can not us "In" as it is a comma separated string
			if (findVarStr != null && findVarStr.length() > 0) {
				String query = queryString + findVarStr;

				for (Agency_Information__c rec : Database.query(query)) {
					set<string> tempSet = new Set<string>();
					if (rec.Tax_Code__c != null) {
						for (string taxCode : rec.Tax_Code__c.split(',')) {
							if (string.isnotblank(taxCode)) {
								taxCode = taxCode.trim();
								taxCodeAgencyMap.put(taxCode, rec);
							}
						}
					}
				}

				for (Tax_Ops_Task__c rec : taskList) {
					if (taxCodeAgencyMap.containsKey(rec.Tax_Code__c) && taxCodeAgencyMap.get(rec.Tax_Code__c).id != null) {
						rec.Agency_Information__c = taxCodeAgencyMap.get(rec.Tax_Code__c).id;
						if (taxCodeAgencyMap.get(rec.Tax_Code__c).Agency_Rep__c != null) {
							rec.ownerId = taxCodeAgencyMap.get(rec.Tax_Code__c).Agency_Rep__c;
						}
					}
				}
			}
		}
	}
}