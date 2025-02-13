/**
 * @description Processes ZP HI deduction reocrds
 * Test: ZPHIDeductionTriggerHelperTest
 */
public without sharing class ZPHIDeductionBatchScheduler implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strQueuedState = IntegrationUtils.QUEUED_STATE;
		String strQuery = 'SELECT Id FROM ZP_HI_Deduction__c WHERE Processing_State__c=\'Queued\'';
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext BC, List<ZP_HI_Deduction__c> list_Deductions) {
		List<ZP_HI_Deduction__c> list_DeductionsQuery = new List<ZP_HI_Deduction__c>();

		// Get all fields from zp hi deduction object
		List<String> list_DeductionFields = new List<String>(ZP_HI_Deduction__c.SObjectType.getDescribe().fields.getMap().keySet());

		// re-query records to get updated data as record context would have changed since the time batch apex was executed.
		list_DeductionsQuery = Database.query('SELECT ' + String.join(list_DeductionFields, ',') + ' FROM ZP_HI_Deduction__c WHERE Id IN :list_Deductions FOR UPDATE');

		// class variable
		ZPHIDeductionTriggerHelper clsDeduction = new ZPHIDeductionTriggerHelper();

		clsDeduction.processInformation(list_DeductionsQuery, null); //process zp hi deduction records

		//skip trigger and run update to stamp lookup fields, processing state and message
		ZPHIDeductionTriggerHelper.skipTrigger = true;

		if (!list_DeductionsQuery.isEmpty()) {
			update list_DeductionsQuery;
		}
	}

	public void finish(Database.BatchableContext BC) {
	}

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 10);
	}
}