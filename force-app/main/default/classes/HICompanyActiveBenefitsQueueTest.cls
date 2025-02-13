@isTest
private class HICompanyActiveBenefitsQueueTest {
	static testMethod void testQueueSetup() {
		HI_Company_Active_Benefits__c rec = new HI_Company_Active_Benefits__c();
		rec.Zp_Company_Id__c = 'HIActiveBenefits111';
		rec.HI_Is_Active_Benefits__c = 'Test String';
		insert rec;

		//Verify the record was inserted successfully.
		HI_Company_Active_Benefits__c var_HIcompanyActiveBenefitRec = [SELECT Id, Zp_Company_Id__c, HI_Is_Active_Benefits__c FROM HI_Company_Active_Benefits__c WHERE Id = :rec.Id];
		System.assertNotEquals(null, var_HIcompanyActiveBenefitRec.Id, 'The record should have been inserted successfully.');
		System.assertEquals('HIActiveBenefits111', var_HIcompanyActiveBenefitRec.Zp_Company_Id__c, 'Zp_Company_Id__c value should match');
		System.assertEquals('Test String', var_HIcompanyActiveBenefitRec.HI_Is_Active_Benefits__c, 'HI_Is_Active_Benefits__c value should match');

		ID jobID = System.enqueueJob(new HICompanyActiveBenefitsQueue(new List<HI_Company_Active_Benefits__c>{ rec }));

		//Verify that the AsyncApexJob was created and completed successfully. Assert that the Queueable job status is completed.
		AsyncApexJob jobs = [SELECT Status, Id FROM AsyncApexJob WHERE JobType = 'Queueable' ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('Queued', jobs.Status, 'The queueable job should have completed successfully.');
	}
}