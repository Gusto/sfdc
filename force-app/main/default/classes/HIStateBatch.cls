public with sharing class HIStateBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'SELECT Id FROM HI_State__c WHERE Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<HI_State__c> list_HIStates = (List<HI_State__c>) scope;

		update list_HIStates;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIStateBatch', false);
		Database.executeBatch(new HIStateCarrierBatch(), 10);
	}
}