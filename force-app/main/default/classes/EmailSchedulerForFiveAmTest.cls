/**
 * @name         EmailSchedulerForFiveAmTest
 * @author       Sanjay Paryani
 * @date         08/24/2020
 * @description  Test class for EmailSchedulerForFiveAm
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
public class EmailSchedulerForFiveAmTest {
	private static List<Account> list_Accounts;
	private static List<Opportunity> list_Opportunities;

	static void createTestData() {
		// insert accounts list
		list_Accounts = new List<Account>();
		Id companyRecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		for (Integer i = 0; i < 50; i++) {
			Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(companyRecordTypeId).setName('TestAccount').build();
			list_Accounts.add(objAcc);
		}
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		// assert if accounts are inserted successfully
		for (Account objAcc : list_Accounts) {
			System.assertNotEquals(null, objAcc.Id, 'Account Id should not be null.');
		}

		// insert opportunity list
		list_Opportunities = new List<Opportunity>();
		for (Integer i = 0; i < 5; i++) {
			Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
				.setName('Test Oppty')
				.setStage('New')
				.setCloseDate(Date.today().addDays(5))
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setAccountId(list_Accounts[i].Id)
				.build();
			list_Opportunities.add(objOpp);
		}
		OpportunityTriggerHelper.skipTrigger = true;
		insert list_Opportunities;
		// assert if opportunities are inserted successfully
		for (Opportunity objOpp : list_Opportunities) {
			System.assertNotEquals(null, objOpp.Id, 'Opportunity Id should not be null.');
		}

		Order objOrder = new Order();
		objOrder.AccountId = list_Accounts[0].Id;
		objOrder.Active_Employee_Count__c = 20;
		objOrder.EffectiveDate = System.today();
		objOrder.Payroll_Run_Date__c = System.today();
		objOrder.Status = 'Onboarding Step 7';
		OrderTriggerHelper.skipTrigger = true;
		insert objOrder;
		objOrder.Status = 'Onboarding Steps 8 - 9';
		update objOrder;
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Transfer Case'),
			AccountId = list_Accounts[0].Id,
			Subject = 'Test',
			Description = 'Test',
			Type = 'Payroll Transfer',
			Origin = 'Panda',
			SuppliedEmail = 'test.test@test.com',
			Large_Scale_Issue__c = 'Test LSI',
			Order__c = objOrder.Id,
			Order_Payroll_Run_Date__c = objOrder.Payroll_Run_Date__c
		);
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
	}

	@isTest
	private static void testScheduler() {
		Integer intNextYear = Date.today().year() + 1;
		String CRON_EXP = '0 0 0 3 9 ? ' + intNextYear;
		Test.startTest();
		createTestData();
		String jobId = System.schedule('EmailSchedulerForFiveAmTest', CRON_EXP, new EmailSchedulerForFiveAm());
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
		Test.stopTest();
		System.assertEquals(CRON_EXP, ct.CronExpression, 'Cron Expression should match.');
		System.assertEquals(0, ct.TimesTriggered, 'TimesTriggered should be 0.');
	}
}