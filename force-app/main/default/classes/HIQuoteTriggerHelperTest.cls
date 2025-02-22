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
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
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
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
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
}