/**
 * @name         : BenefitsNewPlanOppCreationBatchTest
 * @author       : Debasmita Rawooth
 * @date         : 11-11-2021
 * @description  : Test Class for BenefitsNewPlanOppCreationBatch and BenefitsNewPlanOppCreationHandler
 * @test classes : NA
 **/
@isTest
public class BenefitsNewPlanOppCreationBatchTest {
	@testSetup
	static void testData() {
		List<Account> list_Accounts;
		List<Opportunity> list_Opportunities;
		List<User> list_Users;
		Map<String,Id> map_ProfileNameAndId = new Map<String,Id>();
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		map_ProfileNameAndId = GlobalQueryHelper.getProfileNameAndIdMap();

		UserRole objUserRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Integration_Users' LIMIT 1];
		System.runAs(objCurrentUser) {
			User objUser1 = new TestDataFactory.UserBuilder()
				.setUniqueUserName()
				.setFirstName('Sales Routing')
				.setLastName('Test User')
				.setEmail('sales_routing_test@gusto.com')
				.setProfileId(map_ProfileNameAndId.get(TaskUtil.USER_PROFILE_NAME_GUSTO_INTEGRATION_PROFILE))
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.setUserRoleId(objUserRole.Id)
				.build();

			User objUser2 = new TestDataFactory.UserBuilder()
				.setUniqueUserName()
				.setFirstName('Interation User')
				.setLastName('Test')
				.setEmail('testuser2@gusto.com')
				.setProfileId(map_ProfileNameAndId.get(TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR))
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.setUserRoleId(objUserRole.Id)
				.build();

			list_Users = new List<User>{ objUser1, objUser2 };
			UserTriggerHelper.skipTrigger = true;
			insert list_Users;
		}

		insert new TestDataFactory.PriceBookBuilder().setName('Benefits 2017').setActive().build();

		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc1')
			.setZpCompanyId('11111111111111')
			.setBillingState('California')
			.setNumberOfActiveEEs(20)
			.setBillingCountry('United States')
			.build();

		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc2').setZpCompanyId('22222222222222').build();

		list_Accounts = new List<Account>{ objAccount1, objAccount2 };
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;

		Opportunity objOpportunity1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Opp1')
			.setAccountId(list_Accounts[0].Id)
			.setStage('Raw')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity2 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test Opp2')
			.setAccountId(list_Accounts[1].Id)
			.setStage('Raw')
			.setCloseDate(System.today())
			.build();

		list_Opportunities = new List<Opportunity>{ objOpportunity1, objOpportunity2 };
		OpportunityTriggerHelper.skipTrigger = true;

		insert list_Opportunities;

		List<EmailTemplate> list_EmailTemplates = [SELECT Id, Name, Subject, Body FROM EmailTemplate WHERE DeveloperName = :Label.HI_QuoteEmailTemplate];

		EmailMessage objEmailMessage1 = new TestDataFactory.EmailMessageBuilder().setSubject(Label.HI_QuoteEmailSubject).setToAddress('testcontactemail@test.com').setIncoming(true).build();

		objEmailMessage1.RelatedToId = list_Opportunities[0].Id;
		EmailMessageTriggerHelper.skipTrigger = true;

		insert objEmailMessage1;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test creation of Benefits New Plan Opportunity if no open Benefits Opp present
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testBenefitsNewPlanOppCreationBatch() {
		List<User> list_Users = [SELECT Id, Name FROM User where Email = 'sales_routing_test@gusto.com'];
		List<Account> list_Accounts = [SELECT Id, Name FROM Account ORDER BY Name ASC];
		List<Opportunity> list_Opportunities = [SELECT Id, RecordTypeId, Name FROM Opportunity ORDER BY Name ASC];
		List<Insurance_Quote__c> list_InsuranceQuotes;

		Insurance_Quote__c objInsuranceQuote1 = new TestDataFactory.InsuranceQuoteBuilder()
			.setAccountId(list_Accounts[0].Id)
			.setOpportunityId(list_Opportunities[0].Id)
			.setSalesRepId(list_Users[0].Id)
			.setQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		insert objInsuranceQuote1;

		Test.startTest();

		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;
		BenefitsNewPlanOppCreationBatchScheduler objScheduler = new BenefitsNewPlanOppCreationBatchScheduler();
		String jobId = System.schedule('Test InsuranceQuoteEmailBatch', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);

		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [
			SELECT Id, Status__c, NewPlanProcessed__c, NewPlan_Reason__c, Sales_Rep__c, Account__r.BillingState, Account__r.Number_of_Active_Employees__c, Account__r.ZP_Company_ID__c
			FROM Insurance_Quote__c
			WHERE Id = :objInsuranceQuote1.Id
		];

		List<Opportunity> list_HIOpportunities = [
			SELECT Id, NumberOfEmployees__c, HI_Opportunity_Assignment_State__c, ZP_Company_ID__c, Owner.Id, PriceBook2Id, LeadSource
			FROM Opportunity
			WHERE AccountId = :list_Accounts[0].Id AND RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID AND IsClosed = FALSE
		];

		List<QA_Sheet__c> list_QASheets = [SELECT Id FROM QA_Sheet__c WHERE Opportunity__c = :list_HIOpportunities[0].Id];

		List<Account> list_AccountsAssert = [SELECT Id, HI_Owner__c FROM Account WHERE Id = :list_Accounts[0].Id];

		System.assertEquals(true, objInsuranceQuoteAssert.NewPlanProcessed__c, 'New Plan Opportunity successfully created.');
		System.assertEquals(1, list_HIOpportunities.size(), 'Opportunity record is present against account.');
		System.assertEquals(1, list_QASheets.size(), 'QA_Sheet record is present against opportunity.');
		System.assertEquals(objInsuranceQuoteAssert.Account__r.Number_of_Active_Employees__c, list_HIOpportunities[0].NumberOfEmployees__c, 'Number of employees have been copied from Quote Insurance to oppty.');
		System.assertEquals(objInsuranceQuoteAssert.Account__r.BillingState, list_HIOpportunities[0].HI_Opportunity_Assignment_State__c, 'State value is populated.');
		System.assertEquals(objInsuranceQuoteAssert.Account__r.ZP_Company_ID__c, list_HIOpportunities[0].ZP_Company_ID__c,' Company Id is copied.');
		System.assertEquals(OpportunityUtil.INSURANCE_QUOTE, list_HIOpportunities[0].LeadSource, 'Lead Source Should be Insurance Quote');
		System.assert(list_HIOpportunities[0].PriceBook2Id != null, 'Pricebook is present.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test that New Plan Opportunity is not created if open Benefits Opp present
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testBenefitsNewPlanOppCreationBatch2() {
		List<User> list_Users = [SELECT Id, Name FROM User where Email = 'sales_routing_test@gusto.com'];
		List<Account> list_Accounts = [SELECT Id, Name FROM Account ORDER BY Name ASC];
		List<Opportunity> list_Opportunities = [SELECT Id, RecordTypeId, RecordType.Name, Name FROM Opportunity ORDER BY Name ASC];
		List<Insurance_Quote__c> list_InsuranceQuotes;

		Insurance_Quote__c objInsuranceQuote1 = new TestDataFactory.InsuranceQuoteBuilder()
			.setAccountId(list_Accounts[1].Id)
			.setOpportunityId(list_Opportunities[1].Id)
			.setSalesRepId(list_Users[0].Id)
			.setQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();

		insert objInsuranceQuote1;

		Test.startTest();

		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;
		BenefitsNewPlanOppCreationBatchScheduler objScheduler = new BenefitsNewPlanOppCreationBatchScheduler();
		String jobId = System.schedule('Test InsuranceQuoteEmailBatch', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);

		Test.stopTest();

		Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Status__c, NewPlanProcessed__c, NewPlan_Reason__c FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote1.Id];

		List<Opportunity> list_HIOpportunities = [
			SELECT Id
			FROM Opportunity
			WHERE AccountId = :list_Accounts[1].Id AND RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID AND IsClosed = FALSE
		];

		System.assertEquals(true, objInsuranceQuoteAssert.NewPlanProcessed__c,'New Plan Opportunity successfully created.');
		System.assertEquals(1, list_HIOpportunities.size(), 'Opportunity record is present against account.');
	}
}