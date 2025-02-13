/*
 * @name         OpportunityCloseJoinDateSchedulerTest
 * @author       Praveen Sethu
 * @date         07-03-20201
 * @description  Test Oppty Close Date and Join Date Sync
 * @test classes OpportunityCloseJoinDateSchedulerTest
 */
// Using SeeAllData=true because Test methods do not have visibility into OpportunityHistory records
// Batch Class OpportunityCloseJoinDateJob works on querying records from OpportunityHistory object
@isTest(SeeAllData=true)
public with sharing class OpportunityCloseJoinDateSchedulerTest {
	@isTest
	static void testCloseJoinDateSync() {
		// Skip Account Trigger for Faster Inserts
		AccountTriggerHelper.skipTrigger = true;
		Account objAccnt = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Company Account')
			.setZpCompanyId('ABC87767COMPANYSFDC')
			.build();
		insert objAccnt;
		AccountTriggerHelper.skipTrigger = false;

		// Skip Opportunity Trigger for Faster Inserts
		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objCompanyOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setAccountId(objAccnt.Id)
			.setCloseDate(Date.today())
			.setStage(OpportunityUtil.MQL_STAGE)
			.setName('Payroll Opportunity')
			.build();
		insert objCompanyOppty;
		OpportunityTriggerHelper.skipTrigger = false;

		// Create a scenario where Close Date and Join Date do not sync
		AccountTriggerHelper.skipTrigger = true;
		objAccnt.Joined_Date_Panda__c = Date.today().addDays(30);
		update objAccnt;
		AccountTriggerHelper.skipTrigger = false;

		// Update Oppty to Closed Won and Set a Different Joined Date
		OpportunityTriggerHelper.skipTrigger = true;
		objCompanyOppty.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		objCompanyOppty.CloseDate = Date.today().addDays(60);
		objCompanyOppty.Joined_Date_Panda__c = Date.today().addDays(30);
		update objCompanyOppty;
		OpportunityTriggerHelper.skipTrigger = false;

		Test.startTest();
		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;
		OpportunityCloseJoinDateScheduler objScheduler = new OpportunityCloseJoinDateScheduler();
		String jobId = System.schedule('Test Oppty Join and Close Date Sync', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();
	}
}