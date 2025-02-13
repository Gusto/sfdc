/**
 * @name         : InsuranceQuoteTriggerHelperTest
 * @author       : Debasmita Rawooth
 * @date         : 10-07-2021
 * @description  : Test Class for InsuranceQuoteTriggerHelperTest
 * @test classes : NA
 **/
@isTest
public with sharing class InsuranceQuoteTriggerHelperTest {
	@testSetup
	static void testData() {
		List<Account> list_Accounts;
		List<Opportunity> list_Opportunities;
		List<User> list_Users;

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		System.runAs(objCurrentUser) {
			User objUser1 = new TestDataFactory.UserBuilder()
				.setUserName('testuser@insurancequotegusto.com')
				.setLastName('Test User')
				.setEmail('testuser@insurancequotegusto.com')
				.setProfileId(UserInfo.getProfileId())
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			User objUser2 = new TestDataFactory.UserBuilder()
				.setUserName('testuser2@insurancequotegusto.com')
				.setLastName('Test User2')
				.setEmail('testuser2@insurancequotegusto.com')
				.setProfileId(UserInfo.getProfileId())
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			list_Users = new List<User>{ objUser1, objUser2 };
			UserTriggerHelper.skipTrigger = true;
			insert list_Users;
		}

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc1').setZpCompanyId('11111111111111').build();

		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc2').setZpCompanyId('22222222222222').build();

		Account objAccount3 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc3').setZpCompanyId('33333333333333').build();

		Account objAccount4 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc4').setZpCompanyId('44444444444444').build();

		Account objAccount5 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc5').setZpCompanyId('55555555555555').build();

		list_Accounts = new List<Account>{ objAccount1, objAccount2, objAccount3, objAccount4, objAccount5 };
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;

		Opportunity objOpportunity1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(list_Accounts[0].Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity2 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('HI Opp1')
			.setAccountId(list_Accounts[1].Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity3 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp2')
			.setAccountId(objAccount3.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity4 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('HI Opp2')
			.setAccountId(objAccount4.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity5 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('HI Opp3')
			.setAccountId(objAccount5.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		list_Opportunities = new List<Opportunity>{ objOpportunity1, objOpportunity2, objOpportunity3, objOpportunity4, objOpportunity5 };
		OpportunityTriggerHelper.skipTrigger = true;
		insert list_Opportunities;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test skip Insurance Quote Trigger
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testInsuranceQuoteInsertSkipTrigger() {
		User objUser = [SELECT Id, Name FROM User LIMIT 1];
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc1' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, RecordTypeId, Name FROM Opportunity WHERE AccountId = :objAccount.Id];

		Insurance_Quote__c objInsuranceQuote = new TestDataFactory.InsuranceQuoteBuilder()
			.setAccountId(objAccount.Id)
			.setOpportunityId(objOpportunity.Id)
			.setSalesRepId(objUser.Id)
			.setQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		InsuranceQuoteTriggerHelper.blnSkipTrigger = true;
		insert objInsuranceQuote;
		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Status__c, Processing_State__c FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote.Id];
		System.assertEquals(null, objInsuranceQuoteAssert.Status__c);
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test Insurance Quote creation with SalesRep
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testInsuranceQuoteInsert1() {
		User objUser = [SELECT Id, Name FROM User LIMIT 1];
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc1' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, RecordTypeId, Name FROM Opportunity WHERE AccountId = :objAccount.Id];

		Insurance_Quote__c objInsuranceQuote = new TestDataFactory.InsuranceQuoteBuilder()
			.setAccountId(objAccount.Id)
			.setOpportunityId(objOpportunity.Id)
			.setSalesRepId(objUser.Id)
			.setQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		insert objInsuranceQuote;
		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Status__c, Processing_State__c FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote.Id];
		System.assertEquals('Queued', objInsuranceQuoteAssert.Processing_State__c);
		System.assertEquals('Assigned', objInsuranceQuoteAssert.Status__c);
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test Insurance Quote creation without SalesRep
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testInsuranceQuoteInsert2() {
		User objUser = [SELECT Id, Name FROM User LIMIT 1];
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc3' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, RecordTypeId, Name FROM Opportunity WHERE AccountId = :objAccount.Id];

		Insurance_Quote__c objInsuranceQuote = new TestDataFactory.InsuranceQuoteBuilder()
			.setAccountId(objAccount.Id)
			.setOpportunityId(objOpportunity.Id)
			.setSalesRepId(null)
			.setQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		insert objInsuranceQuote;
		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Status__c, Processing_State__c FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote.Id];

		System.assertEquals(null, objInsuranceQuoteAssert.Status__c);
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test Insurance Quote update with SalesRep
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testInsuranceQuoteUpdate() {
		List<User> list_Users = [SELECT Id, Name FROM User];
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Acc4' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, RecordTypeId, Name FROM Opportunity WHERE AccountId = :objAccount.Id];

		Insurance_Quote__c objInsuranceQuote = new TestDataFactory.InsuranceQuoteBuilder()
			.setAccountId(objAccount.Id)
			.setOpportunityId(objOpportunity.Id)
			.setSalesRepId(null)
			.setQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		Test.startTest();
		insert objInsuranceQuote;

		objInsuranceQuote.Sales_Rep__c = list_Users[1].Id;
		update objInsuranceQuote;
		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Status__c, Processing_State__c FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote.Id];
		System.assertEquals('Queued', objInsuranceQuoteAssert.Processing_State__c);
		System.assertEquals('Assigned', objInsuranceQuoteAssert.Status__c);
	}
}