/**
 * @author Brent
 * @date 1/7/16
 * @author David Schach
 * @date 12/2021
 *
 * Created by brent on 1/7/16. Updated by David Schach to combine task triggers on 12/2021
 */
public class TriggerTaskDispatchClass {
	public static Map<Id, Account> mapAccountsToUpdate = new Map<Id, Account>();
	public static Map<Id, Lead> mapLeadsToUpdate = new Map<Id, Lead>();

	public static Boolean skipTrigger = false;

	public static void triggerTaskDispatch(List<Task> newList, Map<Id, Task> newMap, List<Task> oldList, Map<Id, Task> oldMap) {
		if (Trigger.isAfter) {
			if (Trigger.isDelete) {
				taskResponseTime(newList, newMap, oldList, oldMap);
			} else if (Trigger.isInsert) {
				taskResponseTime(newList, newMap, oldList, oldMap);
			} else if (Trigger.isUpdate) {
				taskResponseTime(newList, newMap, oldList, oldMap);
			}
		}

		if (!mapAccountsToUpdate.isEmpty()) {
			Boolean accTriggerSkip = AccountTriggerHelper.skipTrigger || TriggerHandler.isBypassed('AccountTriggerHandler');
			TriggerHandler.bypass('AccountTriggerHandler');
			updateRelatedAccounts();
			if (!accTriggerSkip) {
				TriggerHandler.clearBypass('AccountTriggerHandler');
			}
		}

		if (!mapLeadsToUpdate.isEmpty()) {
			Boolean leadTriggerSkip = LeadTriggerHelper.skipTrigger || TriggerHandler.isBypassed('LeadTriggerHandler');
			TriggerHandler.bypass('LeadTriggerHandler');
			updateRelatedLeads();
			if (!leadTriggerSkip) {
				TriggerHandler.clearBypass('LeadTriggerHandler');
			}
		}
	}

	private static void updateRelatedAccounts() {
		try {
			update mapAccountsToUpdate.values();
		} catch (Exception ex) {
			ExceptionLogUtil.logException('TriggerTaskDispatchClass', 'updateRelatedAccounts', ex.getMessage(), ex.getStackTraceString());
			throw ex;
		}
	}

	private static void updateRelatedLeads() {
		try {
			update mapLeadsToUpdate.values();
		} catch (Exception ex) {
			ExceptionLogUtil.logException('TriggerTaskDispatchClass', 'updateRelatedLeads', ex.getMessage(), ex.getStackTraceString());
			throw ex;
		}
	}

	private static final Id CALL_RECORDTYPEID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId();
	private static final String TASK_TYPE = 'Outbound Call';
	private static final Integer ROLLING_DAYS = -7;
	private static final Datetime S_TIME = System.Now().addDays(-7);

	public static void taskResponseTime(List<Task> newlist, Map<ID, Task> newmap, List<Task> oldlist, Map<ID, Task> oldmap) {
		List<Task> theList;
		Map<Id, Task> theMap;
		Map<Id, Task> otherMap;

		if (Trigger.isDelete) {
			theList = oldlist;
			theMap = oldmap;
			otherMap = null;
		} else if (Trigger.isInsert) {
			theList = newlist;
			theMap = newmap;
			otherMap = oldmap;
		} else if (Trigger.isUpdate) {
			theList = newlist;
			theMap = newmap;
			otherMap = oldmap;
		}
		bestCaseResponseTime(theList, theMap, otherMap);
	}

	private static void bestCaseResponseTime(List<Task> taskList, Map<ID, Task> taskMap, Map<Id, Task> oldMap) {
		Set<Id> setImpactedAccountIds = new Set<Id>();
		Set<Id> setImpactedTaskIds = new Set<Id>();

		for (Task t : taskList) {
			if (t.IsClosed && t.RecordTypeId == CALL_RECORDTYPEID && t.Type == TASK_TYPE && t.AccountId != null) {
				if (Trigger.isUpdate) {
					if (t.CreatedDate > S_TIME) {
						if ((t.IsClosed != oldMap.get(t.Id).IsClosed) || (t.AccountId != oldMap.get(t.Id).AccountId)) {
							setImpactedAccountIds.add(t.AccountId);
						}
					}
				} else {
					setImpactedAccountIds.add(t.AccountId);
					if (Trigger.isDelete) {
						setImpactedTaskIds.add(t.Id);
					}
				}
			}
		}
		if (setImpactedAccountIds.isEmpty()) {
			return;
		}
		if (!Trigger.isDelete) {
			setImpactedTaskIds.clear();
		}
		List<Task> RelatedOutboundCalls = [
			SELECT AccountId, CreatedDate, Id, Account.Response_Date_Time__c, Account.CreatedDate
			FROM Task
			WHERE AccountId IN :setImpactedAccountIds AND Id NOT IN :setImpactedTaskIds AND RecordTypeId = :CALL_RECORDTYPEID AND Type = :TASK_TYPE AND IsClosed = TRUE
			ORDER BY CreatedDate DESC
		];

		Map<Id, DateTime> mapBestCaseResponseTime = new Map<Id, DateTime>();

		if (Trigger.isDelete) {
			for (Id accId : setImpactedAccountIds) {
				mapBestCaseResponseTime.put(accId, null);
			}
		}

		for (Task t : RelatedOutboundCalls) {
			if (t.CreatedDate > t.Account.CreatedDate.addDays(ROLLING_DAYS)) {
				DateTime bcrt = mapBestCaseResponseTime.get(t.AccountId);
				DateTime tDate = t.CreatedDate;
				DateTime rTime = t.Account.Response_Date_Time__c;
				Boolean key = mapBestCaseResponseTime.containsKey(t.AccountId);

				if (!key && (tDate < rTime || rTime == null)) {
					mapBestCaseResponseTime.put(t.AccountId, tDate);
				} else if (key) {
					if (tDate < bcrt || bcrt == null) {
						mapBestCaseResponseTime.put(t.AccountId, tDate);
					}
				}
			}
		}
		List<Account> accountsToUpdate = new List<Account>();
		for (Id accId : mapBestCaseResponseTime.keySet()) {
			accountsToUpdate.add(new Account(Id = accId, Response_Date_Time__c = mapBestCaseResponseTime.get(accId)));
		}
		mapAccountsToUpdate.putAll(accountsToUpdate);
	}
}