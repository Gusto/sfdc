@isTest
public class HICarrierSchedulerTest {
	@isTest
	static void testBatchExecution() {
		HI_Carrier_Detail__c detail = new HI_Carrier_Detail__c();
		detail.id__c = '222';
		detail.Name__c = 'Test';
		insert detail;

		HI_Carrier__c carrier = new HI_Carrier__c();
		carrier.Id__c = '111';
		carrier.Processing_State__c = 'Error';
		carrier.Carrier_Detail_Id__c = '222';
		insert carrier;

		test.startTest();
		String CRON_EXP = '0 0 * * * ?';
		HICarrierScheduler sch = new HICarrierScheduler();
		system.schedule('Hourly Example Batch Schedule job', CRON_EXP, sch);
		test.stopTest();

		//Verify that the job was scheduled successfully. Also check if the CRON_EXP match the CronExpression.
		CronTrigger[] cronJobs = [SELECT Id, CronExpression, State FROM CronTrigger WHERE CronJobDetail.Name = 'Hourly Example Batch Schedule job'];
		System.assertEquals(1, cronJobs.size(), 'Scheduled job should exist.');
		System.assertEquals(CRON_EXP, cronJobs[0].CronExpression, 'Cron expression should match the expected value.');

		//Assert that the carrier's processing state is 'Processed'.
		HI_Carrier__c list_insertedCarrier = [SELECT Processing_State__c FROM HI_Carrier__c WHERE Id__c = '111'];
		System.assertEquals('Processed', list_insertedCarrier.Processing_State__c, 'Carrier should have a Processing_State of "Processed".');
	}
}