public with sharing class NachaEntryReturnBatch implements Database.Batchable<sObject> {
	public list<string> NachaList;

	public Database.QueryLocator start(Database.BatchableContext bc) {
		string querystr = 'select id from ZP_Nacha_Entry_Returns__c where Processing_Status__c = \'Error\'  or Processing_Status__c = \'Queued\' ';

		return Database.getQueryLocator(querystr);
	}

	public void execute(Database.BatchableContext bc, List<ZP_Nacha_Entry_Returns__c> listZPNacha) {
		ZPNachaEntryReturnsTriggerHelper.queue = true;
		update listZPNacha;
	}

	public void finish(Database.BatchableContext bc) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'NachaEntryReturnBatch', false);
	}
}