public with sharing class HIStateCarrierBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string strQuery = 'SELECT Id FROM HI_State_Carrier__c WHERE Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HIStateCarrierTriggerHelper.queue = true;
		List<HI_State_Carrier__c> list_StateCarriers = (List<HI_State_Carrier__c>) scope;

		update list_StateCarriers;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIStateCarrierBatch', false);
	}
}