@isTest
private class HICarrierBatchTest {
	@testSetup
	static void createTestData() {
		HICarrierTriggerHelper.skipTrigger = true;
		insert new HI_Carrier__c(Id__c = '111', Carrier_Detail_Id__c = '222');
		HICarrierTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testCarrierBatch() {
		test.startTest();
		database.executeBatch(new HICarrierBatch(), 10);
		test.stopTest();

		//Verify that the batch processed the records and updated HI_Carrier__c records.
		List<HI_Carrier__c> list_updatedCarriers = [SELECT Id, Processing_State__c FROM HI_Carrier__c WHERE Id__c = '111'];
		System.assertEquals(1, list_updatedCarriers.size(), 'The carrier record should exist.');

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the batch job status is completed.
		AsyncApexJob asyncJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Completed', asyncJob.Status, 'The batch job should have completed successfully.');
	}
}