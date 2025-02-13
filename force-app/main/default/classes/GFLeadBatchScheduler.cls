/**
 * @name         : GFLeadBatchScheduler
 * @author       : David (Dato) Tsamalashvili
 * @date         : 12-28-2021
 * @description  : Scheduler class for GFLeadBatch
 * @test classes : GFLeadBatchTest
 **/
global class GFLeadBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = config.GF_Lead_Batch_Size__c.intValue() != null && config.GF_Lead_Batch_Size__c.intValue() != 0 ? config.GF_Lead_Batch_Size__c.intValue() : 1;

		Database.executeBatch(new GFLeadBatch(''), intBatch);
	}
}