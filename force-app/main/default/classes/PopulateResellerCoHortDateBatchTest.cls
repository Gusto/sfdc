@isTest
public class PopulateResellerCoHortDateBatchTest {
	/*
	 * @author:         Prity Kumari
	 * @description:    Setup test data
	 * @parm:           NA
	 * @return:         NA
	 */
	@testSetup
	static void setupData() {
		TriggerHandler.bypass('AccountTriggerHandler');
		// Create a new reseller account
		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Sold by Acc')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.build();
		insert objResellerAccount;

		List<Account> list_Accounts = new List<Account>();
		// Insert a new company account and set sold by and joined date
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc 1')
			.setJoinedDate(System.today().addDays(-10))
			.setSoldBy(objResellerAccount.Id)
			.setZPCompanyId(String.valueOf(Utils.getRandomIntValue(10)))
			.build();
		list_Accounts.add(objAccount);
		// Insert second company account and set sold by and joined date (earlier than the first company account)
		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc 2')
			.setJoinedDate(System.today().addDays(20))
			.setReferredBy(objResellerAccount.Id)
			.setZPCompanyId(String.valueOf(Utils.getRandomIntValue(10)))
			.build();
		list_Accounts.add(objAccount1);

		Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc 3')
			.setJoinedDate(System.today().addDays(21))
			.setReferredBy(objResellerAccount.Id)
			.setZPCompanyId(String.valueOf(Utils.getRandomIntValue(10)))
			.build();
		list_Accounts.add(objAccount2);
		insert list_Accounts;

		TriggerHandler.clearAllBypasses();
	}
	@isTest
	static void testPopulateCohortDate() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objResellerAccount = [SELECT Id FROM Account WHERE ZP_Firm_Id__c = '4561111111'];
		// Set a sample cron expression
		Date dtSchedulerDate = Date.today().addDays(2);
		Integer intYear = Date.today().year();
		String strCronExp = '0 0 0 ' + String.valueOf(dtSchedulerDate.day()) + ' ' + String.valueOf(dtSchedulerDate.month()) + ' ? ' + intYear;

		Test.startTest();

		PopulateResellerCohortDateBatchScheduler objScheduler = new PopulateResellerCohortDateBatchScheduler();
		String jobId = System.schedule('Test Cohort Date Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		// Assert that cohort date is set to the earliest joined date
		Account objAccountToAssert = [SELECT Id, Cohort_Date__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(Date.today().addDays(-10), objAccountToAssert.Cohort_Date__c, 'Cohort date on Account was not updated to the earliest joined date');
	}
	@isTest
	static void testPopulateCohortDateNegative() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objResellerAccount = [SELECT Id,  Reseller_Company__c, Referred_By__c FROM Account WHERE ZP_Firm_Id__c = '4561111111'];
		List<Account> list_Accounts = [SELECT Id FROM Account WHERE Name IN ('Test Acc 1', 'Test Acc 2')];
		
		objResellerAccount.Reseller_Company__c = list_Accounts[0].Id;
		objResellerAccount.Referred_By__c = list_Accounts[1].Id;
		update objResellerAccount;

		Account objAccount = [SELECT Id,  Reseller_Company__c, Referred_By__c FROM Account WHERE Name = 'Test Acc 3'];
		objAccount.Managing_Firm__c = objResellerAccount.Id;
		update objAccount;

		// Start test and call schedular class that inturn calls the batch classs
		Test.startTest();
	
		// Set a sample cron expression
		Date dtSchedulerDate = Date.today().addDays(2);
		Integer intYear = Date.today().year();
		String strCronExp = '0 0 0 ' + String.valueOf(dtSchedulerDate.day()) + ' ' + String.valueOf(dtSchedulerDate.month()) + ' ? ' + intYear;

		PopulateResellerCohortDateBatchScheduler objScheduler = new PopulateResellerCohortDateBatchScheduler();
		String strJobId = System.schedule('Test Cohort Date Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();
		// Test.stopTest() ends all asynchronous calls

		// Assert that cohort date is set to the earliest joined date
		Account objAccountToAssert = [SELECT Id, Cohort_Date__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(System.today().addDays(21), objAccountToAssert.Cohort_Date__c, 'Cohort date on Account was not updated to the earliest joined date');
	}
}