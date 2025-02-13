/**
 * @author       David (Dato) Tsamalashvili
 * @date         11/30/2021
 * @description  Test class for OnboardingHIOppCreationService
 * @see          OnboardingHIOppCreationService
 * @group        Health Insurance
 **/
@isTest
public class OnboardingHIOppCreationServiceTest {
	@isTest
	static void testSkipCriteria() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');

		List<Account> list_Accounts;
		List<ZP_Company__c> list_ZPCompanies;
		List<Opportunity> list_Opportunities;

		//create accounts
		Account objAcc_0 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Company 0').setZPCompanyId('3827659254255').build();

		Account objAcc_1 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Company 1').setZPCompanyId('3827659254256').build();

		Account objAcc_2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Company 2')
			.setZPCompanyId('3827659254257')
			.setBillingState('Colorado')
			.setBillingCountry('United States')
			.build();

		list_Accounts = new List<Account>{ objAcc_0, objAcc_1, objAcc_2 };
		insert list_Accounts;

		//create opportunities
		Opportunity objOpportunity_0 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test Opp2')
			.setAccountId(list_Accounts[0].Id)
			.setStage('Raw')
			.setCloseDate(System.today())
			.build();

		Opportunity objOpportunity_1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(list_Accounts[2].Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		list_Opportunities = new List<Opportunity>{ objOpportunity_0, objOpportunity_1 };
		insert list_Opportunities;

		//ZP Company W/O Account
		ZP_Company__c objZPCompany_0 = new TestDataFactory.ZPCompanyBuilder()
			.setCreatedAtDate(System.today())
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setSkipOnboardingOppCreation(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();

		ZP_Company__c objZPCompany_1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('3827659254255')
			.setAccountId(objAcc_0.Id)
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc2@gusto.com')
			.setName('Test Company 2')
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setSkipOnboardingOppCreation(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();

		ZP_Company__c objZPCompany_2 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('3827659254256')
			.setAccountId(objAcc_1.Id)
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc3@gusto.com')
			.setName('Test Company 3')
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setSkipOnboardingOppCreation(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();

		ZP_Company__c objZPCompany_3 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('3827659254257')
			.setAccountId(objAcc_1.Id)
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc4@gusto.com')
			.setName('Test Company 4')
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setSkipOnboardingOppCreation(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();

		list_ZPCompanies = new List<ZP_Company__c>{ objZPCompany_0, objZPCompany_1, objZPCompany_2, objZPCompany_3 };
		insert list_ZPCompanies;

		//set created date in the past for batch job to pick it up
		for (ZP_Company__c objZPCompany : list_ZPCompanies) {
			Test.setCreatedDate(objZPCompany.Id, Date.today().adddays(-1));
		}

		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
	}

	@isTest
	static void testCreateOpprole() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		//Account records
		List<Account> list_Accounts = new List<Account>();
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();
		List<Opportunity> list_Opportunities = new List<Opportunity>();

		User objUserSB = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sb_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];

		HI_Opportunity_Router_State__c objOppROuterState = new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('California').setState('CA').build();

		insert objOppROuterState;

		//create accounts
		Account objAcc_0 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('testAccount')
			.setZPCompanyId('21321312')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setNumberOfActiveEEs(10)
			.setHIOwner(objUserSB.Id)
			.build();

		list_Accounts = new List<Account>{ objAcc_0 };
		insert list_Accounts;

		//create opportunities
		Opportunity objOpportunity_0 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Opp BNP')
			.setAccountId(list_Accounts[0].Id)
			.setStage('Raw')
			.setCloseDate(System.today())
			.build();

		list_Opportunities = new List<Opportunity>{ objOpportunity_0 };
		insert list_Opportunities;

		//ZP Company W/O Account
		ZP_Company__c objZPCompany_0 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('21321312')
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.setName('Test Company')
			.setAccountId(objAcc_0.Id)
			.setNumberOfActiveEEs(10)
			.setSkipOnboardingOppCreation(false)
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setOnboardingSurveyOfferBenefits(true)
			.setAccountCreatedDate(System.now() - 1)
			.build();

		list_ZPCompanies = new List<ZP_Company__c>{ objZPCompany_0 };
		insert list_ZPCompanies;

		for (ZP_Company__c objZpComp : list_ZPCompanies) {
			Test.setCreatedDate(objZpComp.Id, Date.today().adddays(-1));
		}

		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test if batch job creates BoR opportunity
	 */
	@isTest
	static void testBOROpportunityCreationPositive() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();

		// Insert a valid HI Supporting State
		User objUserSB = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sb_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		HI_Opportunity_Router_State__c objOppROuterState = new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('California').setState('CA').build();
		insert objOppROuterState;

		// Create Test Account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('testAccountt')
			.setZPCompanyId('21321312')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setNumberOfActiveEEs(10)
			.setHIOwner(objUserSB.Id)
			.setLastLoginTime(System.now())
			.build();
		insert objAccount;

		ZP_Company__c objCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('21321312')
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.setName('Test Company')
			.setAccountId(objAccount.Id)
			.setNumberOfActiveEEs(10)
			.setSkipOnboardingOppCreation(false)
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setOnboardingSurveyOfferBenefits(true)
			.setAccountCreatedDate(System.now() - 1)
			.build();
		objCompany.Want_to_switch_brokers__c = true;
		insert objCompany;

		Test.setCreatedDate(objCompany.Id, Date.today().adddays(-1));

		// Start test and run scheduler class which will invoke batch job
		Test.startTest();
		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		// Assert if BoR opportunity got created
		// Asserts on ZP Company
		ZP_Company__c objCompanyAssert = [SELECT Id, Onboarding_HI_Opp_Created__c, HI_Reason__c FROM ZP_Company__c WHERE Id = :objCompany.Id];
		System.AssertEquals(true, objCompanyAssert.Onboarding_HI_Opp_Created__c, 'BoR Opportunity not created');
		System.AssertEquals(OnboardingHIOppCreationUtil.HI_REASON_BOR_CREATED, objCompanyAssert.HI_Reason__c, 'HI Reason is incorrect on ZP Company.');

		// Assert on Opportunity
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordType.Name = :OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BOR], 'Opportunity not created');
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test if batch job doesn't create benefits opportunity as existing open opportunity of the same type is available
	 */
	@isTest
	static void testBOROpportunityCreationNegative() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();

		// Insert a valid HI Supporting State
		User objUserSB = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sb_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		HI_Opportunity_Router_State__c objOppROuterState = new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('California').setState('CA').build();
		insert objOppROuterState;

		// Create Test Account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('testAccountt')
			.setZPCompanyId('21321312')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setNumberOfActiveEEs(10)
			.setHIOwner(objUserSB.Id)
			.setLastLoginTime(System.now())
			.build();
		insert objAccount;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Test Opp 7')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setSourceID('Test Opp 7')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		ZP_Company__c objCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('21321312')
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.setName('Test Company')
			.setAccountId(objAccount.Id)
			.setNumberOfActiveEEs(10)
			.setSkipOnboardingOppCreation(false)
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setOnboardingSurveyOfferBenefits(true)
			.setAccountCreatedDate(System.now() - 1)
			.build();
		objCompany.Want_to_switch_brokers__c = true;
		insert objCompany;

		Test.setCreatedDate(objCompany.Id, Date.today().adddays(-1));

		// Start test and run scheduler class which will invoke batch job
		Test.startTest();
		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		// Assert if BoR opportunity didn't get created
		// Asserts on ZP Company
		ZP_Company__c objCompanyAssert = [SELECT Id, Onboarding_HI_Opp_Created__c, HI_Reason__c FROM ZP_Company__c WHERE Id = :objCompany.Id];
		System.AssertEquals(false, objCompanyAssert.Onboarding_HI_Opp_Created__c, 'BoR Opportunity created');
		System.AssertEquals('Account already has ' + OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BOR + ' Opportunity', objCompanyAssert.HI_Reason__c, 'HI Reason is incorrect on ZP Company.');

		// Assert on Opportunity
		System.assertEquals(
			1,
			[SELECT COUNT() FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordType.Name = :OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BOR],
			'New opportunity not created'
		);
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test if batch job creates New Plan opportunity
	 */
	@isTest
	static void testNewPlanOpportunityCreationPositive() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();

		// Insert a valid HI Supporting State
		User objUserSB = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sb_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		HI_Opportunity_Router_State__c objOppROuterState = new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('California').setState('CA').build();
		insert objOppROuterState;

		// Create Test Account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('testAccountt')
			.setZPCompanyId('21321312')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setNumberOfActiveEEs(10)
			.setHIOwner(objUserSB.Id)
			.setLastLoginTime(System.now())
			.build();
		insert objAccount;

		ZP_Company__c objCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('21321312')
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.setName('Test Company')
			.setAccountId(objAccount.Id)
			.setNumberOfActiveEEs(10)
			.setSkipOnboardingOppCreation(false)
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setOnboardingSurveyOfferBenefits(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();
		objCompany.Onboarding_Survey_Interested_Benefit_Opt__c = OnboardingHIOppCreationUtil.SMALL_GROUP_HEALTH_INSURANCE;
		insert objCompany;

		Test.setCreatedDate(objCompany.Id, Date.today().adddays(-1));

		// Start test and run scheduler class which will invoke batch job
		Test.startTest();
		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		// Assert if New Plan opportunity got created
		// Asserts on ZP Company
		ZP_Company__c objCompanyAssert = [SELECT Id, Onboarding_HI_Opp_Created__c, HI_Reason__c FROM ZP_Company__c WHERE Id = :objCompany.Id];
		System.AssertEquals(true, objCompanyAssert.Onboarding_HI_Opp_Created__c, 'New Plan Opportunity not created');
		System.AssertEquals(OnboardingHIOppCreationUtil.HI_REASON_NP_CREATED, objCompanyAssert.HI_Reason__c, 'HI Reason is incorrect on ZP Company.');

		// Assert on Opportunity
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordType.Name = :OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_NP], 'Opportunity not created');
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test if batch job doesn't create benefits opportunity as existing open opportunity of the same type is available
	 */
	@isTest
	static void testNewPlanOpportunityCreationNegative() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();

		// Insert a valid HI Supporting State
		User objUserSB = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sb_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		HI_Opportunity_Router_State__c objOppROuterState = new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('California').setState('CA').build();
		insert objOppROuterState;

		// Create Test Account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('testAccountt')
			.setZPCompanyId('21321312')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setNumberOfActiveEEs(10)
			.setHIOwner(objUserSB.Id)
			.setLastLoginTime(System.now())
			.build();
		insert objAccount;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test Opp 7')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setSourceID('Test Opp 7')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		ZP_Company__c objCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('21321312')
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.setName('Test Company')
			.setAccountId(objAccount.Id)
			.setNumberOfActiveEEs(10)
			.setSkipOnboardingOppCreation(false)
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setOnboardingSurveyOfferBenefits(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();
		objCompany.Onboarding_Survey_Interested_Benefit_Opt__c = OnboardingHIOppCreationUtil.LEARNING_MORE;
		insert objCompany;

		Test.setCreatedDate(objCompany.Id, Date.today().adddays(-1));

		// Start test and run scheduler class which will invoke batch job
		Test.startTest();
		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		// Assert if New Plan opportunity didn't get created
		// Asserts on ZP Company
		ZP_Company__c objCompanyAssert = [SELECT Id, Onboarding_HI_Opp_Created__c, HI_Reason__c FROM ZP_Company__c WHERE Id = :objCompany.Id];
		System.AssertEquals(false, objCompanyAssert.Onboarding_HI_Opp_Created__c, 'New Plan Opportunity created');
		System.AssertEquals('Account already has ' + OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_NP + ' Opportunity', objCompanyAssert.HI_Reason__c, 'HI Reason is incorrect on ZP Company.');

		// Assert on Opportunity
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordType.Name = :OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_NP], 'New opportunity not created');
	}

	// opp 3

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test if batch job creates BYB opportunity
	 */
	@isTest
	static void testBYBOpportunityCreationPositive() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();

		// Insert a valid HI Supporting State
		User objUserSB = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sb_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		HI_Opportunity_Router_State__c objOppROuterState = new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('California').setState('CA').build();
		insert objOppROuterState;

		// Create Test Account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('testAccountt')
			.setZPCompanyId('21321312')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setNumberOfActiveEEs(10)
			.setHIOwner(objUserSB.Id)
			.setLastLoginTime(System.now())
			.build();
		insert objAccount;

		ZP_Company__c objCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('21321312')
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.setName('Test Company')
			.setAccountId(objAccount.Id)
			.setNumberOfActiveEEs(10)
			.setSkipOnboardingOppCreation(false)
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setOnboardingSurveyOfferBenefits(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();
		objCompany.Currently_Offer_Health_Benefits__c = 'True';
		objCompany.Open_to_Switching_Broker__c = 'UNSURE';
		insert objCompany;

		Test.setCreatedDate(objCompany.Id, Date.today().adddays(-1));

		// Start test and run scheduler class which will invoke batch job
		Test.startTest();
		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		// Assert if BYB opportunity got created
		// Asserts on ZP Company
		ZP_Company__c objCompanyAssert = [SELECT Id, Onboarding_HI_Opp_Created__c, HI_Reason__c FROM ZP_Company__c WHERE Id = :objCompany.Id];
		System.AssertEquals(true, objCompanyAssert.Onboarding_HI_Opp_Created__c, 'BYB Opportunity not created');
		System.AssertEquals(OnboardingHIOppCreationUtil.HI_REASON_BYB_CREATED, objCompanyAssert.HI_Reason__c, 'HI Reason is incorrect on ZP Company.');

		// Assert on Opportunity
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordType.Name = :OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BYB], 'Opportunity not created');
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test if batch job doesn't create benefits opportunity as existing open opportunity of the same type is available
	 */
	@isTest
	static void testBYBOpportunityCreationNegative() {
		ZPCompanyTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();

		// Insert a valid HI Supporting State
		User objUserSB = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sb_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		HI_Opportunity_Router_State__c objOppROuterState = new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('California').setState('CA').build();
		insert objOppROuterState;

		// Create Test Account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('testAccountt')
			.setZPCompanyId('21321312')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setNumberOfActiveEEs(10)
			.setHIOwner(objUserSB.Id)
			.setLastLoginTime(System.now())
			.build();
		insert objAccount;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setName('Test Opp 7')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setSourceID('Test Opp 7')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		ZP_Company__c objCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('21321312')
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.setName('Test Company')
			.setAccountId(objAccount.Id)
			.setNumberOfActiveEEs(10)
			.setSkipOnboardingOppCreation(false)
			.setOnboardingHICreated(false)
			.setProcessOnbHICreatiton(true)
			.setOnboardingSurveyOfferBenefits(false)
			.setAccountCreatedDate(System.now() - 1)
			.build();
		objCompany.Currently_Offer_Health_Benefits__c = 'True';
		objCompany.Open_to_Switching_Broker__c = 'UNSURE';
		insert objCompany;

		Test.setCreatedDate(objCompany.Id, Date.today().adddays(-1));

		// Start test and run scheduler class which will invoke batch job
		Test.startTest();
		OnboardingHIOppCreationScheduler objScheduler = new OnboardingHIOppCreationScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		// Assert if BYB opportunity didn't get created
		// Asserts on ZP Company
		ZP_Company__c objCompanyAssert = [SELECT Id, Onboarding_HI_Opp_Created__c, HI_Reason__c FROM ZP_Company__c WHERE Id = :objCompany.Id];
		System.AssertEquals(false, objCompanyAssert.Onboarding_HI_Opp_Created__c, 'New Plan Opportunity created');
		System.AssertEquals('Account already has ' + OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BYB + ' Opportunity', objCompanyAssert.HI_Reason__c, 'HI Reason is incorrect on ZP Company.');

		// Assert on Opportunity
		System.assertEquals(
			1,
			[SELECT COUNT() FROM Opportunity WHERE AccountId = :objAccount.Id AND RecordType.Name = :OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BYB],
			'New opportunity not created'
		);
	}
}