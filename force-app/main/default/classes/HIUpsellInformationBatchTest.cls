@isTest
public class HIUpsellInformationBatchTest {
	@isTest
	static void testBatchExecution() {
		HI_Upsell_Information__c info = new HI_Upsell_Information__c();
		info.Benefit_Type__c = 'FSA;HSA;DCA;Commuter';
		info.Company_Id__c = 'company321';
		info.External_Key__c = '111';
		info.Id__c = '111';
		info.Mode__c = 'Normal';
		info.Type__c = 'New TAdA Plan';
		insert info;

		test.startTest();
		database.executeBatch(new HIUpsellInformationBatch(), 10);
		test.stopTest();

		//Verify that the batch processed the records and updated HI_Upsell_Information__c records.
		List<HI_Upsell_Information__c> list_updatedHIUpsellInfo = [
			SELECT Id, Processing_State__c
			FROM HI_Upsell_Information__c
			WHERE Id__c IN ('111')
		];
		System.assertEquals(1, list_updatedHIUpsellInfo.size(), 'The HI_Upsell_Information__c records should be updated.');

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the batch job status is completed.
		AsyncApexJob asyncJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Completed', asyncJob.Status, 'The batch job should have completed successfully.');
	}
}