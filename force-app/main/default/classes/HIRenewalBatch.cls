public with sharing class HIRenewalBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string strQuery = 'SELECT Id FROM HI_Renewal__c WHERE Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HIRenewalTriggerHelper.queue = true;
		List<HI_Renewal__c> list_Renewals = (List<HI_Renewal__c>) scope;

		update list_Renewals;
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new HIBenefitChangeApplicationBatch(), 10);
		Database.executeBatch(new HIUpsellInformationBatch(), 10);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIRenewalBatch', false);
	}
}