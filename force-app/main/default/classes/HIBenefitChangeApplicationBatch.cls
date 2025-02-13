public with sharing class HIBenefitChangeApplicationBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'Select Id from HI_Benefit_Change_Application__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HINewPlansApplicationTriggerHelper.queue = true;
		List<HI_Benefit_Change_Application__c> applicationList = (List<HI_Benefit_Change_Application__c>) scope;

		update applicationList;
	}

	public void finish(Database.BatchableContext BC) {
		database.executeBatch(new HIBoRTransferBatch(), 10);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIBenefitChangeApplicationBatch', false);
	}
}