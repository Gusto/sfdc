/**
 * @name         OpportunityAutoCloseBatchTest
 * @date         03-18-2024
 * @description  Updating stage of opportunities eligible for auto closure. Test class for OpportunityAutoCloseBatch
 * @see          OpportunityAutoCloseBatch
 **/

@isTest
public class OpportunityAutoCloseBatchTest {
	/**
	 * Create test opportunity that fits criteria for auto closure, run job and assert the opportunity is closed lost
	 **/
	@isTest
	static void testAutoCloseOpportunity() {
		User objSalesUser = [SELECT Id FROM User WHERE UserRole.Name LIKE 'sales_sb_ib_xx' AND IsActive = TRUE LIMIT 1][0];

		// Create a test account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account')
			.setLastLoginTime(System.today().addDays(-8))
			.build();
		insert objCompanyAccount;

		// Create an open opportunity with desired age
		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-25))
			.build();
		insert objOppty;
		Test.setCreatedDate(objOppty.Id, Date.today().addDays(-36));

		// Schedule and run the batch job
		Test.startTest();
		String cronExp = '0 0 * * * ?';
		String jobId = System.schedule('Test Opportunity Auto Close', cronExp, new OpportunityAutoCloseBatch());
		//Execute batch separately for testing
		Database.executeBatch(new OpportunityAutoCloseBatch(), 1);
		Test.stopTest();

		// Assert the opportunity is closed lost
		Opportunity objOppToAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :objOppty.Id];
		System.assertEquals('Closed Lost', objOppToAssert.StageName, 'Opportunity stage should be closed lost');
	}

	// Test that the batch job does not close opportunities that do not meet the criteria
	@isTest
	static void testOpportunityNotClosed() {
		User objSalesUser = [SELECT Id FROM User WHERE UserRole.Name LIKE 'sales_sb_ib_xx' AND IsActive = TRUE LIMIT 1][0];

		// Create a test account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account')
			.setLastLoginTime(System.today().addDays(-8))
			.build();
		Account objCompanyAccountLastLogin = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account')
			.setLastLoginTime(System.today())
			.build();
		insert new List<Account>{ objCompanyAccount, objCompanyAccountLastLogin };

		// Create opportunities that do not match criteria for closure
		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Opportunity objOpptyAge = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-25))
			.build();
		list_Opportunities.add(objOpptyAge);

		Opportunity objOpptyLastSetup = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-10))
			.build();
		list_Opportunities.add(objOpptyLastSetup);

		Opportunity objOpptyLastLogin = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccountLastLogin.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-25))
			.build();
		list_Opportunities.add(objOpptyLastLogin);

		Opportunity objOpptyAPD = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-25))
			.setAnchorPayDate(System.today())
			.build();
		list_Opportunities.add(objOpptyAPD);

		Opportunity objOpptyRole = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setLastSetupStep(System.today().addDays(-25))
			.build();
		list_Opportunities.add(objOpptyRole);

		Opportunity objOpptyRecordType = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-25))
			.build();
		list_Opportunities.add(objOpptyRecordType);

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-25))
			.setAnchorPayDate(System.today().addDays(-2))
			.build();
		list_Opportunities.add(objOppty);

		insert list_Opportunities;

		Test.setCreatedDate(objOpptyLastSetup.Id, Date.today().addDays(-36));
		Test.setCreatedDate(objOpptyLastLogin.Id, Date.today().addDays(-36));
		Test.setCreatedDate(objOpptyAPD.Id, Date.today().addDays(-36));
		Test.setCreatedDate(objOpptyRole.Id, Date.today().addDays(-36));
		Test.setCreatedDate(objOpptyRecordType.Id, Date.today().addDays(-36));
		Test.setCreatedDate(objOppty.Id, Date.today().addDays(-36));

		// Schedule and run the batch job
		Test.startTest();
		String cronExp = '0 0 * * * ?';
		String jobId = System.schedule('Test Opportunity Auto Close', cronExp, new OpportunityAutoCloseBatch());
		//Execute batch separately for testing
		Database.executeBatch(new OpportunityAutoCloseBatch(), 10);
		Test.stopTest();

		// Assert the correct opportunities are closed lost
		for (Opportunity objOpportunity : [SELECT Id, StageName FROM Opportunity WHERE Id IN :list_Opportunities]) {
			if (objOpportunity.Id == objOppty.Id) {
				System.assertEquals('Closed Lost', objOpportunity.StageName, 'Opportunity stage should be closed lost');
			} else {
				System.assertNotEquals('Closed Lost', objOpportunity.StageName, 'Opportunity stage should not be closed lost');
			}
		}
	}

	/**
	 * Use exception flag to test exception handling in the batch class
	 **/
	@isTest
	static void testExceptionHandling() {
		User objSalesUser = [SELECT Id FROM User WHERE UserRole.Name LIKE 'sales_sb_ib_xx' AND IsActive = TRUE LIMIT 1][0];

		// Create a test account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account')
			.setLastLoginTime(System.today().addDays(-8))
			.build();
		insert objCompanyAccount;

		// Create an open opportunity with desired age
		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(Date.today().addDays(10))
			.setOwnerId(objSalesUser.Id)
			.setLastSetupStep(System.today().addDays(-25))
			.build();
		insert objOppty;
		Test.setCreatedDate(objOppty.Id, Date.today().addDays(-36));

		// Enable test exception flag in the batch class
		OpportunityAutoCloseBatch.blnTestException = true;

		// Schedule and run the batch job
		Test.startTest();
		String cronExp = '0 0 * * * ?';
		String jobId = System.schedule('Test Opportunity Auto Close', cronExp, new OpportunityAutoCloseBatch());
		//Execute batch separately for testing
		Database.executeBatch(new OpportunityAutoCloseBatch(), 1);
		Test.stopTest();

		// OpportunityAutoCloseBatch should log the exception
		Integer intLogCount = [SELECT COUNT() FROM Exception_Log__c WHERE Class_Name__c = 'OpportunityAutoCloseBatch'];
		System.assertNotEquals(0, intLogCount, 'Exception log count should be greater than 0');

		// Reset the test exception flag
		OpportunityAutoCloseBatch.blnTestException = false;
	}
}