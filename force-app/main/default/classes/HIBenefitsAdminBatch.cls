public with sharing class HIBenefitsAdminBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'Select Id from HI_Benefits_Admin__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HIBenefitsAdminTriggerHelper.queue = true;
		List<HI_Benefits_Admin__c> carrierList = (List<HI_Benefits_Admin__c>) scope;

		update carrierList;
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new HIBenefitsSignatoryBatch(), 10);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIBenefitsAdminBatch', false);
	}
}