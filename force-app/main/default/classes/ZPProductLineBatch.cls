/**
 * @description Batch job for ZP_Product_Line__c records.
 *
 * @author Anurag Gautam
 * @since 06/06/2023
 * @group ZP_Product_Line__c
 * test class: ZPProductLineBatchTest
 */
public without sharing class ZPProductLineBatch implements Database.Batchable<sObject> {
	String strSOQLQuery = 'SELECT Id FROM ZP_Product_Line__c WHERE Processing_State__c=\'Error\' OR Processing_State__c=\'Backlog\' OR Processing_State__c=\'Queued\' OR Processing_State__c = null';

	public ZPProductLineBatch(String strQuery) {
		if (String.isNotBlank(strQuery)) {
			strSOQLQuery = strQuery;
		}
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(strSOQLQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		ZPProductLineTriggerHelper.blnQueue = true;
		List<ZP_Product_Line__c> list_ZPProductLines = (List<ZP_Product_Line__c>) scope;
		update list_ZPProductLines;
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ZPProductLineBatch', false);
		Database.executeBatch(new ZPCompanySuspensionBatch(), 5);
	}
}