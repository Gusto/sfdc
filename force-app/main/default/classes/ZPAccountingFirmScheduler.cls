/**
 * @name         : ZPAccountingFirmScheduler
 * @author       : Prity Kumari
 * @date         : 09-16-2022
 * @description  : Schedule Batch classes to re-process pending (queued and error) accounting firm
 * @test classes : ZPAccountingFirmSchedulerTest
 **/
global with sharing class ZPAccountingFirmScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		// Check if there are any existing batch jobs running
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();

		Integer intFirmBatch = config.ZP_Accounting_Firm_Batch_Size__c != null &&
			config.ZP_Accounting_Firm_Batch_Size__c.intValue() != null &&
			config.ZP_Accounting_Firm_Batch_Size__c.intValue() != 0
			? config.ZP_Accounting_Firm_Batch_Size__c.intValue()
			: 1;

		Database.executeBatch(new ZPAccountingFirmBatch(''), intFirmBatch);
	}
}