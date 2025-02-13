public with sharing class ZPDedicatedSupContactTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	public static boolean queue = false;

	public void OnBeforeInsert(List<ZP_Company_Dedicated_Support_Contact__c> listContact) {
		processInformation(listContact);
	}

	public void OnAfterInsert(Map<ID, ZP_Company_Dedicated_Support_Contact__c> newContactMap) {
		processCaseInformation(newContactMap.values());
	}

	public void OnBeforeUpdate(Map<ID, ZP_Company_Dedicated_Support_Contact__c> oldContactMap, Map<ID, ZP_Company_Dedicated_Support_Contact__c> newContactMap) {
		counter++;
		processInformation(newContactMap.values());
	}

	private void processInformation(List<ZP_Company_Dedicated_Support_Contact__c> listContact) {
		Set<String> companyIdSet = new Set<String>();
		Set<String> supportContactIdSet = new Set<String>();
		List<Account> accountList = new List<Account>();

		for (ZP_Company_Dedicated_Support_Contact__c cont : listContact) {
			if (cont.Processing_State__c != INtegrationUtils.DEAD_STATE) {
				cont.Processing_State__c = INtegrationUtils.QUEUED_STATE;
			}
			if (cont.Company_Id__c != null) {
				companyIdSet.add(cont.Company_Id__c);
			}
			if (cont.Dedicated_Support_Contact_Id__c != null) {
				supportContactIdSet.add(cont.Dedicated_Support_Contact_Id__c);
			}
		}
		map<String, Account> accMap = getAccountMap(companyIdSet);
		for (ZP_Company_Dedicated_Support_Contact__c cont : listContact) {
			if (cont.Company_Id__c == null) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Company Id is missing', cont);
				continue;
			}
			if (cont.Dedicated_Support_Contact_Id__c == null) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Support Contact Id is missing', cont);
				continue;
			}
			if (!accMap.containsKey(cont.Company_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Company record does not exist', cont);
				continue;
			}
			Account acc = accMap.get(cont.Company_Id__c);
            acc.Concierge_Group__c = null;
            acc.Concierge_Group_Id__c = null;
			accountList.add(acc);
		}

		Map<String, String> dmlSaveErrorsMap = new Map<String, String>();
		if (accountList.size() > 0) {
			List<Database.SaveResult> saveResult = database.update(accountList, false);
			dmlSaveErrorsMap = Utils.processSaveResult(saveResult, accountList, 'ZP_Company_ID__c', true, 'ZPDedicatedSupContactTriggerHepler-processInformation');
		}
		for (ZP_Company_Dedicated_Support_Contact__c cont : listContact) {
			if (cont.Processing_State__c != IntegrationUtils.QUEUED_STATE) {
				continue;
			}
			if (dmlSaveErrorsMap.containsKey(cont.Company_id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlSaveErrorsMap.get(cont.Company_id__c), cont);
			} else {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Processed', cont);
			}
		}
	}

	private void processCaseInformation(List<ZP_Company_Dedicated_Support_Contact__c> listContact) {
		Set<String> companyIdSet = new Set<String>();
		List<Case> caseList = new List<Case>();

		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		for (ZP_Company_Dedicated_Support_Contact__c cont : listContact) {
			if (cont.Company_Id__c != null) {
				companyIdSet.add(cont.Company_Id__c);
			}
		}
		Id payrollCareRecTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		Id benCareRecTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
		caseList = new List<Case>(
			[
				SELECT Id, CaseNumber
				FROM Case
				WHERE
					Status != 'Solved'
					AND Status != 'Closed'
					AND Account.ZP_Company_Id__c IN :companyIdSet
					AND Account.ZP_Company_Id__c != NULL
					AND RecordTypeId IN (:payrollCareRecTypeId, :benCareRecTypeId)
					AND Origin != 'Chat'
					AND Origin != 'Gusto'
					AND Channel__c != 'Chat'
			]
		);
		for (Case c : caseList) {
			c.setOptions(dmo);
		}
		if (caseList.size() > 0) {
			update caseList;
		}
	}

	private ZP_Company_Dedicated_Support_Contact__c setProcessingState(String state, String message, ZP_Company_Dedicated_Support_Contact__c cont) {
		cont.Processing_State__c = state;
		cont.Message__c = message;
		cont.Last_Processed__c = System.now();
		return cont;
	}

	private map<String, Account> getAccountMap(Set<String> companyIdSet) {
		map<String, Account> accountMap = new Map<String, Account>();
		for (Account acc : [SELECT Id, ZP_Company_Id__c, Name FROM Account WHERE ZP_Company_Id__c IN :companyIdSet AND ZP_Company_Id__c != NULL]) {
			accountMap.put(acc.ZP_Company_Id__c, acc);
		}
		return accountMap;
	}
}