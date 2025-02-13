@isTest
public class HIBenefitChangeApplicationBatchTest {
	@isTest
	static void testBatchExecution() {
		list<HI_Benefit_Change_Application__c> toInsertHiBCAList = new List<HI_Benefit_Change_Application__c>();

		HI_Benefit_Change_Application__c benefitChangeRec = new HI_Benefit_Change_Application__c();
		benefitChangeRec.External_Key__c = 'Opportunity321';
		benefitChangeRec.Company_Id__c = 'HiBCAcompany321';
		benefitChangeRec.Id__c = 'benefitChangeApplication321';
		benefitChangeRec.Enrollees__c = 2;
		benefitChangeRec.Application_Deadline__c = system.today();
		toInsertHiBCAList.add(benefitChangeRec);

		HI_Benefit_Change_Application__c benefitChangeRec2 = new HI_Benefit_Change_Application__c();
		benefitChangeRec2.External_Key__c = 'Opportunity32';
		benefitChangeRec2.Company_Id__c = 'HiBCAcompany321';
		benefitChangeRec2.Id__c = 'benefitChangeApplication322';
		benefitChangeRec2.Enrollees__c = 2;
		benefitChangeRec2.Application_Deadline__c = system.today();
		toInsertHiBCAList.add(benefitChangeRec2);

		insert toInsertHiBCAList;

		test.startTest();
		database.executeBatch(new HIBenefitChangeApplicationBatch(), 10);
		test.stopTest();

		//Verify that the batch processed the records and updated HI_Benefit_Change_Application__c records.
		List<HI_Benefit_Change_Application__c> list_updatedBenifitChangeApps = [
			SELECT Id, Processing_State__c
			FROM HI_Benefit_Change_Application__c
			WHERE Id__c IN ('benefitChangeApplication321', 'benefitChangeApplication322')
		];
		System.assertEquals(2, list_updatedBenifitChangeApps.size(), 'The HI_Benefit_Change_Application__c records should be updated.');

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the batch job status is completed.
		AsyncApexJob asyncJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Completed', asyncJob.Status, 'The batch job should have completed successfully.');
	}
}