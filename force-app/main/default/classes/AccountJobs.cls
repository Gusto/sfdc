/**
 * @description  Batch class to perform operations on Account records. Reusable for different operations.
 * @date         05-06-2024
 * @see          AccountJobsTest
 **/
public class AccountJobs implements Database.Batchable<sObject>, Database.Stateful {
	public static final String UPDATE_PARTNER_CHILD_ACCOUNTS = 'UpdatePartnerChildAccounts';
	public static Boolean blnTestException = false;
	public String strOperation;
	public Map<Id, Account> map_childAccountsToUpdate;
	public Map<Account, List<Account>> map_AccountsToChildAccounts;
	public List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();

	// Parameterized constructor to set the operation type, record ids and parameters
	public AccountJobs(String strOperation, Map<Account, List<Account>> map_AccountsToChildAccounts) {
		this.strOperation = strOperation;
		this.map_AccountsToChildAccounts = map_AccountsToChildAccounts;
		if (strOperation == UPDATE_PARTNER_CHILD_ACCOUNTS && map_AccountsToChildAccounts != null && !map_AccountsToChildAccounts.isEmpty()) {
			map_childAccountsToUpdate = new Map<Id, Account>();
			for (Account objAccount : map_AccountsToChildAccounts.keySet()) {
				for (Account objChildAccount : map_AccountsToChildAccounts.get(objAccount)) {
					map_childAccountsToUpdate.put(objChildAccount.Id, objAccount);
				}
			}
		}
	}

	//Default Constructor
	public AccountJobs() {
	}

	/**
	 * @description Start method of the batch to get the list of records that need to be updated.
	 *              Fetches the records that need to be updated based on the operation type.
	 * @param       Batchable context
	 **/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = '';
		if (strOperation == UPDATE_PARTNER_CHILD_ACCOUNTS) {
			Set<Id> set_parentAccountIds = map_childAccountsToUpdate.keySet();
			query = 'SELECT Id, RecordTypeId, Benefits_Email_Opt_Out__c, Benefits_Opt_Out_Details__c FROM Account WHERE Id IN :set_parentAccountIds';
		}
		return Database.getQueryLocator(query);
	}

	/**
	 * @description Execute method of the batch to perform the operations on the records in scope.
	 * @param       Batchable context, List of sobjects
	 **/
	public void execute(Database.BatchableContext BC, List<SObject> scope) {
		try {
			if (strOperation == UPDATE_PARTNER_CHILD_ACCOUNTS) {
				updatePartnerChildAccounts(scope, map_childAccountsToUpdate);
			}
			// Test Exception
			if (Test.isRunningTest() && blnTestException) {
				Integer intInfinity = 1 / 0;
			}
			// Additional operations can be added here
		} catch (Exception objException) {
			ExceptionLogUtil.logException('AccountJobs', 'execute', 'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), objException.getStackTraceString());
		}
	}

	/**
	 * @description Finish method of the batch to log the completion of the batch.
	 * @param       Batchable context
	 **/
	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'AccountJobs', false);
		if (!list_ExceptionLogs.isEmpty()) {
			insert list_ExceptionLogs;
		}
	}

	/**
	 * @description Method to update the partner child accounts based on the parameters provided.
	 * @param       List of accounts to update, List of parameters
	 * @return      void
	 * @see         AccountJobsTest
	 * */
	public void updatePartnerChildAccounts(List<Account> list_partnerAccountsToUpdate, Map<Id, Account> map_childAccountsToUpdate) {
		Map<Id, Account> map_accountsToUpdate = new Map<Id, Account>();
		if (list_partnerAccountsToUpdate.isEmpty()) {
			return;
		}
		for (Account objAccount : list_partnerAccountsToUpdate) {
			Account objParentAccount = map_childAccountsToUpdate?.get(objAccount.Id);
			if (objParentAccount != null) {
				String strOptOut = objParentAccount.Benefits_Email_Opt_Out__c != null ? objParentAccount.Benefits_Email_Opt_Out__c : null;
				String strOptOutDetails = objParentAccount.Benefits_Opt_Out_Details__c != null ? objParentAccount.Benefits_Opt_Out_Details__c : null;
				objAccount.Benefits_Email_Opt_Out__c = strOptOut;
				objAccount.Benefits_Opt_Out_Details__c = strOptOutDetails;
				map_accountsToUpdate.put(objAccount.Id, objAccount);
				map_accountsToUpdate.put(objParentAccount.Id, new Account(Id = objParentAccount.Id, Apply_to_all_clients__c = false));
			}
		}
		if (!map_accountsToUpdate.values().isEmpty()) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Database.SaveResult[] list_updateResults = Database.update(map_accountsToUpdate.values(), false);
			TriggerHandler.clearBypass('AccountTriggerHandler');
			for (Integer intIndex = 0; intIndex < list_updateResults.size(); intIndex++) {
				Database.SaveResult objSR = list_updateResults[intIndex];
				if (!objSR.isSuccess() || blnTestException) {
					Exception_Log__c objLog = new Exception_Log__c(
						Type__c = 'ERROR',
						Class_Name__c = 'AccountJobs',
						Method_Name__c = 'execute',
						Record_ID__c = objSR.getId(),
						Message__c = blnTestException ? null : objSR.getErrors()[0].getMessage()
					);
					list_ExceptionLogs.add(objLog);
				}
			}
		}
	}
}