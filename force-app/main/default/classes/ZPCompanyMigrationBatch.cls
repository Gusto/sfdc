public with sharing class ZPCompanyMigrationBatch implements Database.Batchable<sObject> {
	String strQuery = '';

	public ZPCompanyMigrationBatch(String strInputQuery) {
		strQuery = strInputQuery;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (strQuery == '') {
			strQuery = 'SELECT Id FROM ZP_Company_Migration__c WHERE Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\'';
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		ZPCompanyMigrationTriggerHelper.queue = true;
		List<ZP_Company_Migration__c> list_CompMigrations = (List<ZP_Company_Migration__c>) scope;

		update list_CompMigrations;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ZPCompanyMigrationBatch', false);
	}
}