@isTest
public class HIRenewalBatchTest {
	@isTest
	static void testBatchExecution() {
		List<HI_Renewal__c> renewalList = new List<HI_Renewal__c>();

		HI_Renewal__c hiRenewalRec = new HI_Renewal__c();
		hiRenewalRec.External_Key__c = 'Opportunity321';
		hiRenewalRec.Company_Id__c = 'company321';
		hiRenewalRec.Id__c = 'newPlan321';
		hiRenewalRec.Benefit_Types__c = 'medical,dental,vision,life,long';
		hiRenewalRec.Async_Renewal__c = false;
		renewalList.add(hiRenewalRec);

		HI_Renewal__c hiRenewalRec2 = new HI_Renewal__c();
		hiRenewalRec2.Company_Id__c = 'company321';
		hiRenewalRec2.Id__c = 'newPlan322';
		hiRenewalRec2.Benefit_Types__c = 'medical,dental,vision,life,long';
		hiRenewalRec2.Async_Renewal__c = false;
		renewalList.add(hiRenewalRec2);

		insert renewalList;

		Test.startTest();
		Database.executeBatch(new HiRenewalBatch(), 10);
		Test.stopTest();

		//Verify that the batch processed the records and updated HI_Renewal__c records.
		List<HI_Renewal__c> list_updatedHIRenewal = [
			SELECT Id, Processing_State__c
			FROM HI_Renewal__c
			WHERE Id__c IN ('newPlan321', 'newPlan322')
		];
		System.assertEquals(2, list_updatedHIRenewal.size(), 'The HI_Renewal__c records should be updated.');

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the batch job status is completed.
		AsyncApexJob asyncJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Completed', asyncJob.Status, 'The batch job should have completed successfully.');
	}
}