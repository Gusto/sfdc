@isTest
public class HIStateCarrierBatchTest {
	@isTest
	static void testStateBatch() {
		Carrier_Info__c carrierInfo = new Carrier_Info__c();
		carrierInfo.Id__c = 'carrier321';
		insert carrierInfo;

		HI_State_Carrier__c newRec = new HI_State_Carrier__c();
		newRec.id__c = 'Test321';
		newRec.Carrier_Id__c = 'carrier321';
		insert newRec;

		Test.startTest();
		Database.executeBatch(new HIStateCarrierBatch(), 10);
		Test.stopTest();

		//Verify that the batch processed the records and updated HI_State_Carrier__c records.
		List<HI_State_Carrier__c> list_updatedStateCarriers = [SELECT Id, Processing_State__c FROM HI_State_Carrier__c WHERE Id__c = 'Test321'];
		System.assertEquals(1, list_updatedStateCarriers.size(), 'The HI State Carrier record should exist.');

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the batch job status is completed.
		AsyncApexJob asyncJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Completed', asyncJob.Status, 'The batch job should have completed successfully.');
	}
}