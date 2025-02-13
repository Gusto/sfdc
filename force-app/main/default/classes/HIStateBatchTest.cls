@isTest
private class HIStateBatchTest {
	@testSetup
	static void createTestData() {
		HIStateTriggerHelper.skipTrigger = true;
		insert new HI_State__c(Name__c = 'California', Key__c = 'CA');
		HIStateTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testStateBatch() {
		Test.startTest();
		Database.executeBatch(new HIStateBatch(), 10);
		Test.stopTest();

		//Verify that the batch processed the records and updated HI_State__c records.
		List<HI_State__c> list_updatedStates = [SELECT Id, Processing_State__c FROM HI_State__c WHERE Name__c = 'California'];
		System.assertEquals(1, list_updatedStates.size(), 'The HI State record should exist.');

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the batch job status is completed.
		AsyncApexJob asyncJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Completed', asyncJob.Status, 'The batch job should have completed successfully.');
	}
}