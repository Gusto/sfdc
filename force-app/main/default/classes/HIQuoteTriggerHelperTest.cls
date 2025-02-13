/**
 * @name         : HIQuoteTriggerHelperTest
 * @author       : Debasmita Rawooth
 * @date         : 09-24-2021
 * @description  : Test Class for HIQuoteTriggerHelper
 * @test classes : NA
 **/
@isTest
public class HIQuoteTriggerHelperTest {
	@testSetup
	static void testData() {
		List<Account> list_Accounts;
		List<Opportunity> list_Opportunities;
		User objUser1;

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		System.runAs(objCurrentUser) {
			objUser1 = new TestDataFactory.UserBuilder()
				.setUniqueUserName()
				.setLastName('Test User')
				.setEmail('testuser@gusto.com')
				.setProfileId(UserInfo.getProfileId())
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			UserTriggerHelper.skipTrigger = true;
			insert objUser1;
		}

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc1').setZpCompanyId('11111111111111').setBillingCountry('United States').build();
		objAccount1.HI_Owner__c = objUser1.Id;

		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc2').setZpCompanyId('22222222222222').build();

		Account objAccount3 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc3').setZpCompanyId('33333333333333').build();

		list_Accounts = new List<Account>{ objAccount1, objAccount2, objAccount3 };
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;

		Opportunity objOpportunity1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objAccount1.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity2 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('HI Opp1')
			.setAccountId(objAccount1.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity3 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp2')
			.setAccountId(objAccount2.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		list_Opportunities = new List<Opportunity>{ objOpportunity1, objOpportunity2, objOpportunity3 };
		OpportunityTriggerHelper.skipTrigger = true;
		insert list_Opportunities;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test Skip HIQuoteTrigger
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testHIQuoteInsertSkipTrigger() {
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc1' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, RecordTypeId, Name FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID];

		HI_Quote__c objHIQuote = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAccount.Id)
			.setHIQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		HIQuoteTriggerHelper.str_skipTrigger = true;
		insert objHIQuote;
		Test.stopTest();

		List<Insurance_Quote__c> list_InsuranceQuoteAssert = [
			SELECT Id, Account__c, Opportunity__c, Census_Link__c, Census_Part_Time_Employees__c, Census_Planned_W2_Hires__c, Quote_Link__c
			FROM Insurance_Quote__c
			WHERE Account__c = :objAccount.Id
		];

		System.assertEquals(0, list_InsuranceQuoteAssert.size(), 'Quote was created incorrectly.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test HI Quote creation for Account having both Payroll and Benefits New Plan Opportunity
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testHIQuoteInsert1() {
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc1' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, RecordTypeId, Name FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID];

		HI_Quote__c objHIQuote = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAccount.Id)
			.setHIQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusState('California')
			.setCensusZipcode('90011')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		insert objHIQuote;
		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [
			SELECT Id, Account__c, Opportunity__c, Census_Link__c, Census_Part_Time_Employees__c, Census_Planned_W2_Hires__c, Quote_Link__c, Census_State__c, Census_Zip_Code__c
			FROM Insurance_Quote__c
			WHERE Account__c = :objAccount.Id
		];

		System.assertEquals(objHIQuote.Salesforce_ID__c, objInsuranceQuoteAssert.Account__c, 'Account not matching on HI Quote and Insurance quote.');
		System.assertEquals(objOpportunity.Id, objInsuranceQuoteAssert.Opportunity__c, 'Opportunity is incorrect on Insurance Quote.');
		System.assertEquals(objHIQuote.Census_Link__c, objInsuranceQuoteAssert.Census_Link__c, 'Census Link not matching on HI Quote and Insurance quote.');
		System.assertEquals(
			objHIQuote.Census_Part_Time_Employees__c,
			objInsuranceQuoteAssert.Census_Part_Time_Employees__c,
			'Census Part Time Employees not matching on HI Quote and Insurance quote.'
		);
		System.assertEquals(objHIQuote.Census_Planned_W2_Hires__c, objInsuranceQuoteAssert.Census_Planned_W2_Hires__c, 'Census Planned W2 Hires not matching on HI Quote and Insurance quote.');
		System.assertEquals(objHIQuote.HI_Quote_Link__c, objInsuranceQuoteAssert.Quote_Link__c, 'Quite Link not matching on HI Quote and Insurance quote.');
		System.assertEquals(objHIQuote.Census_State__c, objInsuranceQuoteAssert.Census_State__c, 'Census State not matching on HI Quote and Insurance quote.');
		System.assertEquals(objHIQuote.Census_Zip_Code__c, objInsuranceQuoteAssert.Census_Zip_Code__c, 'Census Zip Code not matching on HI Quote and Insurance quote.');

		// Test if Billing State on Account is updated
		Account objAccountAssert = [SELECT Id, BillingState FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objHIQuote.Census_State__c, objAccountAssert.BillingState, 'Billing State not matching on Account and Insurance quote.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test HI Quote creation for Account having only Payroll Opportunity
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testHIQuoteInsert2() {
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc2' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, RecordTypeId, Name FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID];

		HI_Quote__c objHIQuote = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAccount.Id)
			.setHIQuoteLink('www.test2quotelink.com')
			.setCensusLink('www.test2censuslink.com')
			.setCensusPartTimeEmployees(78)
			.setPlannedW2Hires(158)
			.build();

		Test.startTest();
		insert objHIQuote;
		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [
			SELECT Id, Account__c, Opportunity__c, Census_Link__c, Census_Part_Time_Employees__c, Census_Planned_W2_Hires__c, Quote_Link__c
			FROM Insurance_Quote__c
			WHERE Account__c = :objAccount.Id
		];

		System.assertEquals(objHIQuote.Salesforce_ID__c, objInsuranceQuoteAssert.Account__c, 'Account not matching on HI Quote and Insurance quote.');
		System.assertEquals(objOpportunity.Id, objInsuranceQuoteAssert.Opportunity__c, 'Opportunity is incorrect on Insurance Quote.');
		System.assertEquals(objHIQuote.Census_Link__c, objInsuranceQuoteAssert.Census_Link__c, 'Census Link not matching on HI Quote and Insurance quote.');
		System.assertEquals(
			objHIQuote.Census_Part_Time_Employees__c,
			objInsuranceQuoteAssert.Census_Part_Time_Employees__c,
			'Census Part Time Employees not matching on HI Quote and Insurance quote.'
		);
		System.assertEquals(objHIQuote.Census_Planned_W2_Hires__c, objInsuranceQuoteAssert.Census_Planned_W2_Hires__c, 'Census Planned W2 Hires not matching on HI Quote and Insurance quote.');
		System.assertEquals(objHIQuote.HI_Quote_Link__c, objInsuranceQuoteAssert.Quote_Link__c, 'Quote Link not matching on HI Quote and Insurance quote.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test HI Quote creation for Account not having a valid Open Opportunity
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testHIQuoteInsert3() {
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc3' LIMIT 1];

		HI_Quote__c objHIQuote = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAccount.Id)
			.setHIQuoteLink('www.test3quotelink.com')
			.setCensusLink('www.test3censuslink.com')
			.setCensusPartTimeEmployees(78)
			.setPlannedW2Hires(158)
			.build();

		Test.startTest();
		insert objHIQuote;
		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [
			SELECT Id, Account__c, Opportunity__c, Census_Link__c, Census_Part_Time_Employees__c, Census_Planned_W2_Hires__c, Quote_Link__c
			FROM Insurance_Quote__c
			WHERE Account__c = :objAccount.Id
		];

		System.assertEquals(objHIQuote.Salesforce_ID__c, objInsuranceQuoteAssert.Account__c, 'Account not matching on HI Quote and Insurance quote.');
		System.assertEquals(null, objInsuranceQuoteAssert.Opportunity__c, 'Opportunity is incorrect on Insurance Quote.');
		System.assertEquals(objHIQuote.Census_Link__c, objInsuranceQuoteAssert.Census_Link__c, 'Census Link not matching on HI Quote and Insurance quote.');
		System.assertEquals(
			objHIQuote.Census_Part_Time_Employees__c,
			objInsuranceQuoteAssert.Census_Part_Time_Employees__c,
			'Census Part Time Employees not matching on HI Quote and Insurance quote.'
		);
		System.assertEquals(objHIQuote.Census_Planned_W2_Hires__c, objInsuranceQuoteAssert.Census_Planned_W2_Hires__c, 'Census Planned W2 Hires not matching on HI Quote and Insurance quote.');
		System.assertEquals(objHIQuote.HI_Quote_Link__c, objInsuranceQuoteAssert.Quote_Link__c, 'Quote Link not matching on HI Quote and Insurance quote.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test HI Quote update
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testHIQuoteUpdate() {
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc1' LIMIT 1];

		HI_Quote__c objHIQuote = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAccount.Id)
			.setHIQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		insert objHIQuote;

		objHIQuote.HI_Quote_Link__c = 'www.testcensuslinkupdate.com';
		objHIQuote.Census_State__c = 'California';
		update objHIQuote;
		Test.stopTest();

		List<Insurance_Quote__c> lst_InsuranceQuoteAssert = [
			SELECT Id, Account__c, Opportunity__c, Census_Link__c, Census_Part_Time_Employees__c, Census_Planned_W2_Hires__c, Quote_Link__c
			FROM Insurance_Quote__c
			WHERE Account__c = :objAccount.Id
		];

		System.assertEquals(2, lst_InsuranceQuoteAssert.size(), 'There should be 2 insurance quotes for the account.');

		// Assert if Billing State is updated on Account
		Account objAccountAssert = [SELECT Id, BillingState FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objHIQuote.Census_State__c, objAccountAssert.BillingState, 'Billing State not matching on Account and Insurance quote.');
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    HI Sales Routing - Test if HI Quote records trigger HI Owner routing based on Aligned Reps
	 */
	@isTest
	static void testHIQuoteAlignedRepAssignment() {
		// build a map of integration user name and user object
		Map<String, User> map_IntegrationUsers = new Map<String, User>();
		for (User objUser : [SELECT Id, Name FROM User WHERE Name IN ('API Heroku', 'Workato Integration') AND IsActive = TRUE]) {
			map_IntegrationUsers.put(objUser.Name, objUser);
		}

		// assume sales all roles is integration users role
		String HI_SALES_ALL_ROLES = 'Integration Users';

		AccountTriggerHelper.skipTrigger = true;
		UserTriggerHelper.skipTrigger = true;
		Account objAcc1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('86896897')
			.setNumberOfActiveEEs(2)
			.setNumberOfEmployees(2)
			.setOwnerId(map_IntegrationUsers.get('API Heroku').Id)
			.setZPCompanyOverallStatus('New')
			.build();

		Account objAcc2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 2')
			.setZPCompanyId('987896896')
			.setNumberOfActiveEEs(7)
			.setNumberOfEmployees(7)
			.setOwnerId(map_IntegrationUsers.get('API Heroku').Id)
			.setZPCompanyOverallStatus('New')
			.build();

		Account objAcc3 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 3')
			.setZPCompanyId('890809890')
			.setNumberOfActiveEEs(7)
			.setNumberOfEmployees(7)
			.setOwnerId(map_IntegrationUsers.get('Workato Integration').Id)
			.setZPCompanyOverallStatus('New')
			.build();

		Account objAcc4 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('253464576456')
			.setNumberOfActiveEEs(2)
			.setNumberOfEmployees(2)
			.setOwnerId(map_IntegrationUsers.get('API Heroku').Id)
			.setZPCompanyOverallStatus('Active')
			.setHasMedicalDeductions(true)
			.build();

		List<Account> list_Accounts = new List<Account>{ objAcc1, objAcc2, objAcc3, objAcc4 };
		insert list_Accounts;

		HI_Quote__c objHIQuote1 = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAcc1.Id)
			.setHIQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		HI_Quote__c objHIQuote2 = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAcc2.Id)
			.setHIQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		HI_Quote__c objHIQuote3 = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAcc3.Id)
			.setHIQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		HI_Quote__c objHIQuote4 = new TestDataFactory.HIQuoteBuilder()
			.setSalesforceId(objAcc4.Id)
			.setHIQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		List<HI_Quote__c> list_HIQuotesToInsert = new List<HI_Quote__c>{ objHIQuote1, objHIQuote2, objHIQuote3, objHIQuote4 };
		insert list_HIQuotesToInsert;
		Test.stopTest();

		List<Account> list_AccountsToAssert = [SELECT Id, HI_Owner__c, HI_Owner__r.UserRole.Name, HI_Routing_Reason__c, HI_Owner__r.IsActive FROM Account WHERE Id IN :list_Accounts];

		for (Account objAcc : list_AccountsToAssert) {
			if (objAcc.Id == objAcc1.Id) {
				// first account should have routed to small biz new plan rep
				System.assertEquals(
					'New Plan - Insurance Quote - HI Owner null value updated to aligned ' + AccountUtil.HI_NEW_PLAN_REP,
					objAcc.HI_Routing_Reason__c,
					'Account not routed to HI New Plan Rep'
				);
				System.assertEquals(true, objAcc.HI_Owner__c != null, 'HI Owner is null on Account');
				System.assertEquals(true, HI_SALES_ALL_ROLES.containsIgnoreCase(objAcc.HI_Owner__r.UserRole.Name), 'HI Owner Role is not from Benefits Roles custom label');
			} else if (objAcc.Id == objAcc2.Id) {
				// second account should have routed to mid market new plan rep
				System.assertEquals(
					'New Plan - Insurance Quote - HI Owner null value updated to aligned ' + AccountUtil.HI_NEW_PLAN_REP,
					objAcc.HI_Routing_Reason__c,
					'Account not routed to HI Broker Rep'
				);
				System.assertEquals(true, objAcc.HI_Owner__c != null, 'HI Owner is null on Account');
				System.assertEquals(true, HI_SALES_ALL_ROLES.containsIgnoreCase(objAcc.HI_Owner__r.UserRole.Name), 'HI Owner Role is not from Benefits Roles custom label');
			} else if (objAcc.Id == objAcc3.Id) {
				// HI owner on third account should be null and sent to routing tool
				System.assertEquals('New Plan - Insurance Quote - HI Owner null value and send to Routing Tool', objAcc.HI_Routing_Reason__c, 'Account not sent to Routing tool');
				System.assertEquals(true, objAcc.HI_Owner__c == null, 'HI Owner is not null on Account');
			} else if (objAcc.Id == objAcc4.Id) {
				// HI owner on fourth account should be null and sent to routing tool because overall status is Active
				System.assertEquals('New Plan - Insurance Quote - HI Owner null value and send to Routing Tool', objAcc.HI_Routing_Reason__c, 'Account not sent to Routing tool');
				System.assertEquals(true, objAcc.HI_Owner__c == null, 'HI Owner is not null on Account');
			}
		}
	}
}