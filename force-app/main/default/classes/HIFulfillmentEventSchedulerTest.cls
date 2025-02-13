@isTest
public class HIFulfillmentEventSchedulerTest {
	@isTest
	static void testBatchExecution() {
		HI_Fulfillment_Event__c event = new HI_Fulfillment_Event__c();
		event.Id__c = '2222';
		event.Event_Type__c = 'Test';
		event.Event_Type__c = '{"test": "test"}';
		insert event;

		test.startTest();
		String CRON_EXP = '0 0 * * * ?';
		HIFulfillmentEventScheduler sch = new HIFulfillmentEventScheduler();
		system.schedule('Hourly Example Batch Schedule job', CRON_EXP, sch);
		test.stopTest();

		//Assert that the HI_Fulfillment_Event__c was successfully inserted
		HI_Fulfillment_Event__c insertedEvent = [SELECT Id, Event_Type__c FROM HI_Fulfillment_Event__c WHERE Id = :event.Id LIMIT 1];
		System.assertNotEquals(null, insertedEvent, 'The HI_Fulfillment_Event__c record should be inserted.');
		System.assertEquals('{"test": "test"}', insertedEvent.Event_Type__c, 'The Event_Type__c field should match the inserted value.');

		//Assert that the job was scheduled with the correct Cron expression
		CronTrigger scheduledJob = [SELECT Id, CronExpression, State FROM CronTrigger WHERE CronJobDetail.Name = 'Hourly Example Batch Schedule job' LIMIT 1];
		System.assertNotEquals(null, scheduledJob, 'The scheduled job should exist.');
		System.assertEquals(CRON_EXP, scheduledJob.CronExpression, 'The Cron expression should match the expected value.');
	}
}