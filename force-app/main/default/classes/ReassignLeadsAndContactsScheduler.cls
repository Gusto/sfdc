/**
 * @name         ReassignLeadsAndContactsScheduler
 * @author       Prity Kumari
 * @date         04-20-2022
 * @description  Scheduler class for ReassignLeadsAndContactsBatch
 * @test classes ReassignLeadsAndContactsBatchTest
 **/
global with sharing class ReassignLeadsAndContactsScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = objConfig.Reassign_Lead_Contacts_Batch_Size__c.intValue() != null &&
		objConfig.Reassign_Lead_Contacts_Batch_Size__c.intValue() != 0
			? objConfig.Reassign_Lead_Contacts_Batch_Size__c.intValue()
			: 200;
		Database.executeBatch(new ReassignLeadsAndContactsBatch(), intBatch);
	}
}