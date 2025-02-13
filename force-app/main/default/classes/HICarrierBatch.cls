public with sharing class HICarrierBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'Select Id from HI_Carrier__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HICarrierTriggerHelper.queue = true;
		//List<HI_Carrier__c> carrierList= (List<HI_Carrier__c>)scope;

		update scope;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HICarrierBatch', false);

		database.executeBatch(new HIStateBatch(), 10);
	}
}