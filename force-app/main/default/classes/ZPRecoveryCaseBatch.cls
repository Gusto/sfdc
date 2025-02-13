public with sharing class ZPRecoveryCaseBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'Select Id from ZP_Recovery_Case__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		ZPRecoveryCaseTriggerHelper.queue = true;
		List<ZP_Recovery_Case__c> ZPRecoveryCaseList = (List<ZP_Recovery_Case__c>) scope;

		update ZPRecoveryCaseList;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ZPRecoveryCaseBatch', false);
	}
}