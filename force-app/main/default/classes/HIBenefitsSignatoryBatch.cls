public with sharing class HIBenefitsSignatoryBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'Select Id from HI_Benefits_Signatory__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HIBenefitSignatoryTriggerHelper.queue = true;
		List<HI_Benefits_Signatory__c> signatoryList = (List<HI_Benefits_Signatory__c>) scope;

		update signatoryList;
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new HIOpenEnrollmentWindowBatch(), 10);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIBenefitsSignatoryBatch', false);
	}
}