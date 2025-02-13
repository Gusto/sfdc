public with sharing class GFLeadBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	String strQuery = '';

	public GFLeadBatch(String strInputQuery) {
		strQuery = strInputQuery;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (String.isBlank(strQuery)) {
			strQuery = 'SELECT Id FROM GF_Lead__c WHERE Processing_State__c=\'Error\' or Processing_State__c=\'Queued\' ';
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<GF_Lead__c> list_Leads = (List<GF_Lead__c>) scope;

		update list_Leads;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'GFLeadBatch', false);
	}
}