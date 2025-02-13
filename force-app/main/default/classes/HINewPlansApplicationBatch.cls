public without sharing class HINewPlansApplicationBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String queryString = 'Select Id from HI_New_Plans_Application__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\' or  Processing_State__c=\'\'';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HINewPlansApplicationTriggerHelper.queue = true;
		List<HI_New_Plans_Application__c> applicationList = (List<HI_New_Plans_Application__c>) scope;

		update applicationList;
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new HIRenewalBatch(), 10);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HINewPlansApplicationBatch', false);
	}
}