/*
 * Created By : Neha Dabas, 30 Oct 2019
 * Description : To Unit test PTPayrollRunNotificationScheduler functionality
 */

@isTest
private class PTPayrollRunNotificationSchedulerTest {
	private static List<Account> testAccountList;
	private static List<Opportunity> testOppList;

	static void createTestData() {
		// insert accounts list
		testAccountList = new List<Account>();
		for (Integer count = 0; count < 50; count++) {
			Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
			testAccountList.add(objAcc);
		}

		insert testAccountList;
		// assert if accounts are inserted successfully
		for (Account acc : testAccountList) {
			System.assertNotEquals(null, acc.Id, 'Account Id should not be null.');
		}

		// insert opportunity list
		testOppList = new List<Opportunity>();
		Id companyOpportunityRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		for (integer i = 0; i < 5; i++) {
			Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
				.setName('Test Opportunity Account')
				.setAccountId(testAccountList[i].Id)
				.build();
			testOppList.add(objOpp);
		}
		insert testOppList;
		// assert if opportunities are inserted successfully
		for (Opportunity objOpp : testOppList) {
			System.assertNotEquals(null, objOpp.Id, 'Opportunity Id should not be null.');
		}

		Order ord = new Order();
		ord.AccountId = testAccountList[0].Id;
		ord.Active_Employee_Count__c = 20;
		ord.EffectiveDate = System.today();
		ord.Payroll_Run_Date__c = System.today();
		ord.Status = 'Onboarding Step 7';
		insert ord;
		ord.Status = 'Onboarding Steps 8 - 9';
		update ord;
		CaseTriggerHelper.skipTrigger = true;
		Case cse = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Transfer Case'),
			AccountId = testAccountList[0].Id,
			Subject = 'Test',
			Description = 'Test',
			Type = 'Payroll Transfer',
			Origin = 'Panda',
			SuppliedEmail = 'test.test@test.com',
			Large_Scale_Issue__c = 'Test LSI',
			Order__c = ord.Id,
			Order_Payroll_Run_Date__c = ord.Payroll_Run_Date__c
		);
		insert cse;
	}
	@isTest
	private static void testScheduler() {
		Integer intNextYear = Date.today().year() + 1;
		String CRON_EXP = '0 0 0 3 9 ? ' + intNextYear;
		Test.startTest();
		createTestData();
		String jobId = System.schedule('TestPTORderAnalyticsBatchJob', CRON_EXP, new PTPayrollRunNotificationScheduler());
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
		Test.stopTest();
		System.assertEquals(CRON_EXP, ct.CronExpression, 'Cron expression should match.');
		System.assertEquals(0, ct.TimesTriggered, 'TimesTriggered should be 0.');
	}
}