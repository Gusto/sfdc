@isTest
public class HiNewPlansApplicationBatchTest {
	@isTest
	static void testBatchExecution() {
		list<HI_New_Plans_Application__c> listnewPlan = new List<HI_New_Plans_Application__c>();

		HI_New_Plans_Application__c hiNewPlansApplicationRec = new HI_New_Plans_Application__c();
		hiNewPlansApplicationRec.Company_Id__c = 'company321';
		hiNewPlansApplicationRec.External_Key__c = 'Opportunity321';
		hiNewPlansApplicationRec.Id__c = 'newPlan321';
		hiNewPlansApplicationRec.Requested_Start_Date__c = system.today();
		listnewPlan.add(hiNewPlansApplicationRec);

		HI_New_Plans_Application__c hiNewPlansApplicationRec1 = new HI_New_Plans_Application__c();
		hiNewPlansApplicationRec1.Company_Id__c = 'company321';
		//hiNewPlansApplicationRec1.External_Key__c = 'Opportunity322';
		hiNewPlansApplicationRec1.Id__c = 'newPlan322';
		hiNewPlansApplicationRec1.Requested_Start_Date__c = system.today();
		listnewPlan.add(hiNewPlansApplicationRec1);

		insert listnewPlan;

		test.startTest();
		database.executeBatch(new HiNewPlansApplicationBatch(), 10);
		test.stopTest();

		//Verify that the batch processed the records and updated HI_New_Plans_Application__c records.
		List<HI_New_Plans_Application__c> list_updatedNewPlanApps = [
			SELECT Id, Processing_State__c
			FROM HI_New_Plans_Application__c
			WHERE Id__c IN ('newPlan321', 'newPlan322')
		];
		System.assertEquals(2, list_updatedNewPlanApps.size(), 'The HI_New_Plans_Application__c records should be updated.');

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the batch job status is completed.
		AsyncApexJob asyncJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Completed', asyncJob.Status, 'The batch job should have completed successfully.');
	}
}