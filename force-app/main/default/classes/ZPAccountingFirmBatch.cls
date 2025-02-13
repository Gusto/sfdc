public with sharing class ZPAccountingFirmBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	String strQuery = '';

	public ZPAccountingFirmBatch(String strQry) {
		strQuery = strQry;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (strQuery == '') {
			strQuery = 'SELECT Id FROM ZP_Accounting_Firm__c WHERE Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\'';
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		ZPAccountingFirmTriggerHelper.queue = true;
		List<ZP_Accounting_Firm__c> list_AccountingFirms = (List<ZP_Accounting_Firm__c>) scope;

		update list_AccountingFirms;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ZPAccountingFirmBatch', false);
	}
}