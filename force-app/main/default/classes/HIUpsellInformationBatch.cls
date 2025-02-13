public with sharing class HIUpsellInformationBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'Select Id from HI_Upsell_Information__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\' or  Processing_State__c=\'\' ';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HIUpsellInformationTriggerHelper.queue = true;
		List<HI_Upsell_Information__c> applicationList = (List<HI_Upsell_Information__c>) scope;

		update applicationList;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIUpsellInformationBatch', false);
	}
}