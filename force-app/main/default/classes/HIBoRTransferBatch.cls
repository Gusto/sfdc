public with sharing class HIBoRTransferBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'SELECT Id FROM HI_BoR_Transfer__c WHERE Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\'';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HIBoRTransferTriggerHelper.queue = true;
		List<HI_BoR_Transfer__c> transferList = (List<HI_BoR_Transfer__c>) scope;

		update transferList;
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new HIPolicyBatch(), 1);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIBoRTransferBatch', false);
	}
}