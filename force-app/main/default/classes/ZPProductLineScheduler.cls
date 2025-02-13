/**
 * @description ZPProductLineScheduler.
 * @author Anurag Gautam
 * @since 06/27/2023
 * @group ZP_Product_Line__c
 * test class: ZPProductLineBatchTest
 */
global with sharing class ZPProductLineScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intZPProductLineBatchSize = config.ZP_Product_Line_Batch_Size__c.intValue() != null &&
			config.ZP_Product_Line_Batch_Size__c.intValue() != 0
			? config.ZP_Product_Line_Batch_Size__c.intValue()
			: 100;
		Database.ExecuteBatch(new ZPProductLineBatch(null), intZPProductLineBatchSize);
	}
}