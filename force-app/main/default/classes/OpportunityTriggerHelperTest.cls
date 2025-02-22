/**
 * @description Test class for OpportunityTriggerHelper
 * @author Yuvraj/Prashant
 * @since 19/10/2020
 * @see OpportunityTriggerHelper
 * @see OpportunityTriggerHandler
 */
@IsTest
private class OpportunityTriggerHelperTest {
	@testSetup
	/**
	 * @description Set up data
	 * <br>Unnecessary users have been removed, and mixed DML operations avoided by using RunAs
	 */
	static void setup() {
		CaseTriggerHelper.skipTrigger = true;
		UserTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');
		AccountRelatedTrackingTriggerHelper.skipTrigger = true;

		User adminUser;
		User benefitsUser;
		User runningUser = TestUserUtility.getRunningUser();
		User nonHIUser;

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		UserRole objSalesRole = new UserRole(DeveloperName = 'TestSalesRole', Name = 'sales_bd_pr_xx');

		System.runAs(runningUser) {
			Profile objSysAdminProfile = [SELECT Id FROM Profile WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE LIMIT 1];
			adminUser = TestUserUtility.getAdminUser(false);
			adminUser.ProfileId = objSysAdminProfile.Id;

			benefitsUser = TestUserUtility.getMDRUser(false);
			benefitsUser.ProfileId = System.Label.Benefits_User_ProfileId;

			insert objSalesRole;

			nonHIUser = new TestDataFactory.UserBuilder()
				.setAlias('nonHI')
				.setEmail('nonHIUser@testorg.com')
				.setEmailEncoding('UTF-8')
				.setFirstName('NONHI')
				.setLastName('User')
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setProfileId(UserInfo.getProfileId())
				.setTimeZoneSidKey('America/Los_Angeles')
				.setUserName('nonHIUser@testorg.com')
				.setUserRoleId(objSalesRole.Id)
				.build();

			List<User> listUsersToInsert = new List<User>();
			listUsersToInsert.add(adminUser);
			listUsersToInsert.add(benefitsUser);
			listUsersToInsert.add(nonHIUser);
			insert listUsersToInsert;
		}

		Product2 objProd = new Product2(Name = 'Medical', Family = 'Hardware');
		insert objProd;

		Id idPriceBook = Test.getStandardPricebookId();

		PricebookEntry objStandardPrice = new PricebookEntry(Pricebook2Id = idPriceBook, Product2Id = objProd.Id, UnitPrice = 10000, IsActive = true);
		insert objStandardPrice;

		Pricebook2 objCustomPB = new Pricebook2(Name = 'Test', isActive = true);
		insert objCustomPB;

		PricebookEntry objCustomPrice = new PricebookEntry(Pricebook2Id = objCustomPB.Id, Product2Id = objProd.Id, UnitPrice = 12000, IsActive = true);
		insert objCustomPrice;

		//create company account

		Account compAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('1234567890')
			.setHIOwner(adminUser.Id)
			.build();
		compAccount.Pricing__c = 'test';
		compAccount.Discount__c = 20;
		insert compAccount;

		//create company account 2
		Account objCompanyAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('APD Account').setZPCompanyId('4561111111').build();
		insert objCompanyAcc;

		//create reseller account
		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			.setName('Reseller Account')
			.setName('Accountants R Us')
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setHIOwner(adminUser.Id)
			.build();
		objResellerAccount.Discount__c = 20;
		insert objResellerAccount;

		// create Partner program company data for company account
		Partner_Program_Company_Data__c objProgram = new Partner_Program_Company_Data__c();
		objProgram.company_id__c = '1234567890';
		objProgram.Reward_Eligible__c = true;
		objProgram.Managing_Accounting_Firm__c = objResellerAccount.Id;
		insert objProgram;

		//create account related traking

		Account_Related_Tracking__c objART = new Account_Related_Tracking__c();
		objART.Account__c = compAccount.Id;
		insert objART;
		AccountRelatedTrackingTriggerHelper.skipTrigger = false;
		//create company contact

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setFirstName('Artoo')
			.setLastName('Detoo')
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(compAccount.Id)
			.setEmail('testuser@abccompany.com')
			.build();
		insert objContact;
		//Create company contact 2
		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setFirstName('Amin')
			.setLastName('kumar')
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAcc.Id)
			.setEmail('aminkumar@xyz.com')
			.build();
		insert objContact2;

		//create reseller contact
		Contact objContactReseller = new TestDataFactory.ContactBuilder()
			.setFirstName('Luke')
			.setLastName('Skywalker')
			.setRecordTypeId(ContactUtil.RESELLER_CONTACT_RT_ID)
			.setAccountId(compAccount.Id)
			.setEmail('testuserreseller@abccompany.com')
			.build();
		insert objContactReseller;

		Lead_Randomize__c objRandomize = new Lead_Randomize__c(
			Current_Company_Account_Index__c = 1,
			Number_of_Company_Accounts__c = 2,
			Number_of_Reseller_Accounts__c = 2,
			Reseller_Account_Hold_Out_Reset__c = 0
		);
		insert objRandomize;

		TriggerHandler.clearAllBypasses();

		State__c objState = new State__c();
		objState.Name = 'Arizona';
		objState.Abbreviation__c = 'AZ';
		insert objState;

		List<Role__c> listRoles = new List<Role__c>();
		Role__c objRoleAdvisor = new Role__c();
		objRoleAdvisor.Name = 'Advisor';
		listRoles.add(objRoleAdvisor);

		Role__c objRoleRenewalSpecialist = new Role__c();
		objRoleRenewalSpecialist.Name = 'Renewal Specialist';
		listRoles.add(objRoleRenewalSpecialist);

		insert listRoles;

		List<Skill__c> listSkills = new List<Skill__c>();
		listSkills.add(new Skill__c(Role__c = objRoleAdvisor.Id, State_Group__c = 'Arizona'));
		listSkills.add(new Skill__c(Role__c = objRoleRenewalSpecialist.Id, State_Group__c = 'Arizona'));
		insert listSkills;

		User_Role__c objUserRole = new User_Role__c();
		objUserRole.User__c = benefitsUser.Id;
		insert objUserRole;

		List<User_Skill__c> listUserSkills = new List<User_Skill__c>();
		listUserSkills.add(new User_Skill__c(Skill__c = listSkills[0].Id, User_Role__c = objUserRole.Id, Skill_Role_Name__c = 'Advisor'));

		listUserSkills.add(new User_Skill__c(Skill__c = listSkills[1].Id, User_Role__c = objUserRole.Id, Skill_Role_Name__c = 'Renewal Specialist'));
		insert listUserSkills;

		Configuration_Settings__c objConfigSetting = new Configuration_Settings__c(
			Special_Enrollment_Deadline_Date__c = Date.valueOf('2021-12-15'),
			HI_Effective_Date__c = Date.valueOf('2022-1-1'),
			Skip_BigDesk_Assignment__c = false
		);
		insert objConfigSetting;

		Pricebook2 objPriceBook1 = new TestDataFactory.PriceBookBuilder().setName(OpportunityUtil.PRICE_BOOK_RD_PREMIUM).setActive().build();
		Pricebook2 objPriceBook2 = new TestDataFactory.PriceBookBuilder().setName(OpportunityUtil.PRICE_BOOK_RD_STANDARD).setActive().build();
		insert new List<Pricebook2>{ objPriceBook1, objPriceBook2 };
	}

	/**
	 * @author      Prity Kumari
	 * @description Test for First APD Date
	 **/
	@isTest
	static void testFirstAPDDate() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');
		CaseTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objCompanyAcc = [SELECT Id, RecordTypeId, Name, ZP_Company_ID__c FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_ID__c = '4561111111' LIMIT 1];

		System.runAs(objUser) {
			//setup for test APD Date
			Opportunity objAPDOppty = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setName('APD Account - Payroll')
				.setAccountId(objCompanyAcc.Id)
				.setStage('MQL')
				.setCloseDate(System.today())
				.build();

			insert objAPDOppty;
			/**objAPDOppty = [SELECT Id, First_APD_Date__c, First_APD_Date_Missed__c, Anchor_Pay_Date__c FROM Opportunity WHERE Name = 'APD Account - Payroll'];

			Test.startTest();
			objAPDOppty.Anchor_Pay_Date__c = System.today().addDays(2);
			update objAPDOppty;

			objAPDOppty.Anchor_Pay_Date__c = System.today().addDays(3);
			update objAPDOppty;
			Test.stopTest(); **/
		}
		//Opportunity objAssert = [SELECT Id, First_APD_Date__c, First_APD_Date_Missed__c FROM Opportunity WHERE Name = 'APD Account - Payroll'];
		//System.assertEquals(System.today().addDays(2), objAssert.First_APD_Date__c);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testSubmissionDeadlineCalculations() {
		TriggerHandler.bypass('AccountTriggerHandler');
		// Retrieve Company Account
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		TriggerHandler.bypass('OpportunityTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');
		CarrierTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;
		// Create Benefits Renewal Opportunity
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;
		TriggerHandler.clearBypass('OpportunityTriggerHandler');
		// Create new Carrier
		Carrier__c objCarrier = new Carrier__c();
		objCarrier.Name = 'NewCarrierForTask';
		objCarrier.State__c = 'CA';
		insert objCarrier;

		// Creating new Benefit Orders
		Benefit_Order__c objBOrder = TestUtility.createTestBenefitOrder('New Plan', objOppty.Id, 'Benefit Order', true);
		objBOrder.Push_Rate_Reason__c = 'Other';

		// Creating new Product
		Product2 objProduct = TestUtility.createTestProduct('Medical', 'Benefit', true);

		PricebookEntry objPBE = TestUtility.createTestPriceBookEntry(objProduct.Id, 5, Test.getStandardPriceBookId(), true); //NOPMD

		// Creating new Carrier Order
		Carrier_Order__c objCarrierOrder = TestUtility.createTestCarrierOrder(objCarrier.Id, 'Carrier Order', objBOrder.Id, true);

		// Getting current month's last date and set it as expiration date
		Date dtExpirationDate = Date.today().addMonths(1).toStartOfMonth().addDays(-1);
		// Creating an Active Policy
		Policy__c objPolicy = TestUtility.createTestPolicy(objOppty.Id, objCarrier.Id, true, 'Test Policy ', objCarrierOrder.Id, false);
		objPolicy.Benefit_Type__c = 'Medical';
		objPolicy.Account__c = objAccnt.Id;
		objPolicy.Expiration_Date__c = dtExpirationDate;
		objPolicy.Coverage_Effective_Date__c = System.today().adddays(-3);
		insert objPolicy;

		// Updating Benefits Renewal Opportunities
		Test.startTest();
		assertAfterDaysDeadline(objOppty, dtExpirationDate, objCarrier);
		assertBeforeDaysDeadline(objOppty, dtExpirationDate, objCarrier);
		assertSameDeadline(objOppty, dtExpirationDate, objCarrier);
		assertAfterMonthDeadline(objOppty, dtExpirationDate, objCarrier);
		assertBeforeMonthDeadline(objOppty, dtExpirationDate, objCarrier);
		assertUWStateAndCarrier(objOppty, objPolicy, objCarrier);
		Test.stopTest();
	}

	public static void assertAfterDaysDeadline(Opportunity objOppty, Date dtExpirationDate, Carrier__c objCarrier) {
		objCarrier.Group_Submission_Event__c = 'After Days';
		objCarrier.Group_Variation_Number__c = 1;
		// Carrier Workflow Rule defaults Group_Submission_Event__c to Before Month on Create
		// Hence, creating carriers and updating group submission event
		update objCarrier;

		objOppty.Submission_Deadline__c = null;
		update objOppty;

		// Retrieve Updated Opportunity
		Opportunity objOpptyRetrieved = [SELECT Id, Submission_Deadline__c FROM Opportunity WHERE Id = :objOppty.Id];

		// Assert the calculated Deadline for After Days
		Date dtSubmissionDeadline = OpportunityUtil.checkWeekendDate(dtExpirationDate.addDays(1).addDays(Integer.valueOf(objCarrier.Group_Variation_Number__c)));

		System.assertEquals(dtSubmissionDeadline, objOpptyRetrieved.Submission_Deadline__c, 'Submission Deadline did not match for Group Submission Event set as After Days');
	}

	public static void assertBeforeDaysDeadline(Opportunity objOppty, Date dtExpirationDate, Carrier__c objCarrier) {
		// Updating Carrier Group Submission Event
		objCarrier.Group_Submission_Event__c = 'Before Days';
		objCarrier.Group_Variation_Number__c = 1;

		update objCarrier;

		// Reset Submission Deadline and Update Opportunity
		objOppty.Submission_Deadline__c = null;
		update objOppty;

		// Retrieve Updated Opportunity
		Opportunity objOpptyRetrieved = [SELECT Id, Submission_Deadline__c FROM Opportunity WHERE Id = :objOppty.Id];

		// Assert the calculated Deadline for before Days
		Date dtSubmissionDeadline = OpportunityUtil.checkWeekendDate(dtExpirationDate.addDays(1).addDays(-Integer.valueOf(objCarrier.Group_Variation_Number__c)));

		System.assertEquals(dtSubmissionDeadline, objOpptyRetrieved.Submission_Deadline__c, 'Submission Deadline did not match for Group Submission Event set as Before Days');
	}

	public static void assertSameDeadline(Opportunity objOppty, Date dtExpirationDate, Carrier__c objCarrier) {
		// Updating Carrier Group Submission Event
		objCarrier.Group_Submission_Event__c = 'Same';
		update objCarrier;

		// Reset Submission Deadline and Update Opportunity
		objOppty.Submission_Deadline__c = null;
		update objOppty;

		// Retrieve Updated Opportunity
		Opportunity objOpptyRetrieved = [SELECT Id, Submission_Deadline__c FROM Opportunity WHERE Id = :objOppty.Id];

		// Assert the calculated Deadline for before Days
		Date dtSubmissionDeadline = OpportunityUtil.checkWeekendDate(dtExpirationDate.addDays(1));

		System.assertEquals(dtSubmissionDeadline, objOpptyRetrieved.Submission_Deadline__c, 'Submission Deadline did not match for Group Submission Event set as Same');
	}

	public static void assertAfterMonthDeadline(Opportunity objOppty, Date dtExpirationDate, Carrier__c objCarrier) {
		// Updating Carrier Group Submission Event
		objCarrier.Group_Submission_Event__c = 'After Month';
		objCarrier.Group_Variation_Number__c = 10;

		update objCarrier;

		// Reset Submission Deadline and Update Opportunity
		objOppty.Submission_Deadline__c = null;
		update objOppty;

		// Retrieve Updated Opportunity
		Opportunity objOpptyRetrieved = [SELECT Id, Submission_Deadline__c FROM Opportunity WHERE Id = :objOppty.Id];

		// Assert the calculated Deadline for before Days
		Date dtEffectiveDate = dtExpirationDate.addDays(1);
		Date dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), Integer.valueOf(objCarrier.Group_Variation_Number__c));

		dtSubmissionDeadline = OpportunityUtil.checkWeekendDate(dtSubmissionDeadline);

		System.assertEquals(dtSubmissionDeadline, objOpptyRetrieved.Submission_Deadline__c, 'Submission Deadline did not match for Group Submission Event set as After Month');
	}

	public static void assertBeforeMonthDeadline(Opportunity objOppty, Date dtExpirationDate, Carrier__c objCarrier) {
		// Updating Carrier Group Submission Event
		objCarrier.Group_Submission_Event__c = 'Before Month';
		objCarrier.Group_Variation_Number__c = 10;

		update objCarrier;

		// Reset Submission Deadline and Update Opportunity
		objOppty.Submission_Deadline__c = null;
		update objOppty;

		// Retrieve Updated Opportunity
		Opportunity objOpptyRetrieved = [SELECT Id, Submission_Deadline__c FROM Opportunity WHERE Id = :objOppty.Id];

		// Assert the calculated Deadline for before Days

		Date dtEffectiveDate = dtExpirationDate.addDays(1).addMonths(-1);
		Date dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), Integer.valueOf(objCarrier.Group_Variation_Number__c));

		dtSubmissionDeadline = OpportunityUtil.checkWeekendDate(dtSubmissionDeadline);

		System.assertEquals(dtSubmissionDeadline, objOpptyRetrieved.Submission_Deadline__c, 'Submission Deadline did not match for Group Submission Event set as Before Month');
	}

	public static void assertUWStateAndCarrier(Opportunity objOppty, Policy__c objPolicy, Carrier__c objCarrier) {
		State__c objState = new State__c(Name = 'California');
		insert objState;

		objPolicy.State__c = objState.Id;
		update objPolicy;

		objOppty.UW_State_PY__c = null;
		update objOppty;

		// Retrieve Updated Opportunity
		Opportunity objOpptyRetrieved = [SELECT Id, UW_State_PY__c, UW_Carrier_PY__c FROM Opportunity WHERE Id = :objOppty.Id];

		System.assertEquals('California', objOpptyRetrieved.UW_State_PY__c, 'Opportunity UW State not set properly');
		System.assertEquals('NewCarrierForTask', objOpptyRetrieved.UW_Carrier_PY__c, 'Opportunity UW Carrier not set properly');
	}

	@isTest
	static void testSetStageERConfirm() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');
		CaseTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objCompAccount;
		List<Opportunity> list_Opportunities = new List<Opportunity>();

		List<Account> listAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID];
		if (listAccounts.size() > 0) {
			objCompAccount = new Account(Id = listAccounts.get(0).Id);
		}

		System.runAs(objUser) {
			Opportunity objOpportunity = new Opportunity();
			objOpportunity.AccountId = objCompAccount.Id;
			objOpportunity.Name = 'Test Opp 2';
			objOpportunity.RecordTypeId = OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID;
			list_Opportunities.add(objOpportunity);

			Test.startTest();
			insert list_Opportunities;

			list_Opportunities.get(0).Benefits_Current_Setup_Step__c = OpportunityUtil.FORMSSIGNED_BENEFITSCURRENTSTEP;

			update list_Opportunities;
			Test.stopTest();
		}
		// Retrieve Updated Opportunity
		List<Opportunity> listOpportunitiesQueries = [SELECT Id, StageName FROM Opportunity WHERE Id IN :list_Opportunities];
		System.assertEquals(OpportunityUtil.ER_CONFIRM_STAGE, listOpportunitiesQueries[0].StageName);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @Author		SandeepGolla
	 * @description	Test Opportunity Stage Assertion
	 * @Parm		void
	 * @Return		void
	 **/
	@isTest
	static void testOpportunityStageAssertion() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		TicketTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];

		Account objCompAccount;
		Map<String, Opportunity> map_Opps = new Map<String, Opportunity>();
		List<Account> listAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID];
		if (listAccounts.size() > 0) {
			objCompAccount = new Account(Id = listAccounts.get(0).Id);
		}

		System.runAs(objUser) {
			// Create Company Opportunity
			Opportunity objCompanyOpp = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setName('Test Opp - Company')
				.setAccountId(objCompAccount.Id)
				.setCloseDate(System.today())
				.build();

			// Create Benefits New Plan Opportunity
			Opportunity objBenefitsNewOpp = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setName('Test Opp - BNP')
				.setAccountId(objCompAccount.Id)
				.setCloseDate(System.today())
				.build();

			// Create Benefits Renewal Opportunity
			Opportunity objBenefitsRenewalOpp = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setName('Test Opp - BNP Ren')
				.setAccountId(objCompAccount.Id)
				.setCloseDate(System.today())
				.build();

			map_Opps.put(OpportunityUtil.ACQUISITION_OPPTY_RT_ID, objCompanyOpp);
			map_Opps.put(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID, objBenefitsNewOpp);
			map_Opps.put(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID, objBenefitsRenewalOpp);

			Test.startTest();
			insert map_Opps.values();
			Test.stopTest();

			// Retrieve Updated Opportunity
			Opportunity objCompanyUpdOpp = new Opportunity();
			Opportunity objBenefitsNewUpdOpp = new Opportunity();
			Opportunity objBenefitsRenewalUpdOpp = new Opportunity();
			List<Opportunity> list_Opportunities = [SELECT Id, RecordTypeId, StageName FROM Opportunity WHERE Id IN :map_Opps.values()];
			for (Opportunity objOpp : list_Opportunities) {
				if (objOpp.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) {
					objCompanyUpdOpp = objOpp;
				} else if (objOpp.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID) {
					objBenefitsNewUpdOpp = objOpp;
				} else if (objOpp.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
					objBenefitsRenewalUpdOpp = objOpp;
				}
			}
			System.assertEquals('Prospecting', objCompanyUpdOpp.StageName);
			System.assertEquals(OpportunityUtil.DEFAULT_HI_SALES_STAGE, objBenefitsNewUpdOpp.StageName);
			System.assertEquals(OpportunityUtil.SAL_STAGE, objBenefitsRenewalUpdOpp.StageName);
			// Finally check if there are any exceptions logged
			checkForExceptions();
		}
	}

	@isTest
	static void testSetStageClosed() {
		List<Account> listAccounts = [SELECT Id, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			}
		}

		List<Opportunity> listOpportunities = new List<Opportunity>();

		Opportunity objOpportunityAsyncDismsd = new Opportunity();
		objOpportunityAsyncDismsd.AccountId = objCompAccount.Id;
		objOpportunityAsyncDismsd.Name = 'Test Opp BNP';
		objOpportunityAsyncDismsd.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOpportunityAsyncDismsd.Amount = 55000.00;
		objOpportunityAsyncDismsd.Benefits_Current_Setup_Step__c = 'Created';
		objOpportunityAsyncDismsd.Renewal_Date__c = System.today().adddays(30);
		objOpportunityAsyncDismsd.Stage_Detail__c = 'COVID-19';
		objOpportunityAsyncDismsd.CloseDate = Date.today().addDays(10);
		objOpportunityAsyncDismsd.StageName = 'Raw';
		listOpportunities.add(objOpportunityAsyncDismsd);

		Test.startTest();
		TriggerHandler.bypass('OpportunityTriggerHandler');
		insert listOpportunities;
		TriggerHandler.clearBypass('OpportunityTriggerHandler');
		objOpportunityAsyncDismsd.Benefits_Current_Setup_Step__c = 'Dismissed';
		update listOpportunities;
		Test.stopTest();
		List<Opportunity> listOpportunitiesQuery = [SELECT Id, StageName FROM Opportunity WHERE Id IN :listOpportunities];
		System.assertEquals(OpportunityUtil.CLOSED_LOST_STAGE, listOpportunitiesQuery[0].StageName);
	}

	@isTest
	static void testInvoiceOpportunity() {
		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		User objUser = [
			SELECT Id, IsActive, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		List<Opportunity> listOpportunities = new List<Opportunity>();
		List<Account> listAccounts = [SELECT Id, RecordTypeId, ZP_Company_Id__c, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		System.runAs(objUser) {
			Payment_Invoice__c objPaymentInvoice = new TestDataFactory.PaymentInvoiceBuilder()
				.setCompanyId(objCompAccount.ZP_Company_Id__c)
				.setAmount(100)
				.setName('INV-123')
				.setEmployeeCount(5)
				.setContractorCount(0)
				.build();

			objPaymentInvoice.Pricing__c = objTierConfig.New_Price_2__c;
			objPaymentInvoice.Discount__c = 0;
			objPaymentInvoice.Volume_Discount__c = 0;
			objPaymentInvoice.Additional_Discount__c = 0;
			insert objPaymentInvoice;

			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setStage('')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setSourceID('343434')
				.build();

			objOpportunity.Amount = 55000.00;
			objOpportunity.Referred_By__c = objResellerAccount.Id;
			objOpportunity.Payment_Invoice__c = objPaymentInvoice.Id;

			listOpportunities.add(objOpportunity);
			Test.startTest();
			insert listOpportunities;
			Test.stopTest();
			List<Opportunity> listOpportunitiesQuery = [
				SELECT Id, EE_Active_Count_At_Win__c, NumberOfEmployees__c, Number_of_Contractors__c, StageName, Payment_Invoice__c
				FROM Opportunity
				WHERE Id IN :listOpportunities
			];

			//System.assertEquals(objPaymentInvoice.Employee_Count__c, listOpportunitiesQuery[0].NumberOfEmployees__c);
			//System.assertEquals(objPaymentInvoice.Contractor_Count__c, listOpportunitiesQuery[0].Number_of_Contractors__c);
			// Finally check if there are any exceptions logged
			checkForExceptions();
		}
	}

	@isTest
	static void testSetCommit() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		List<Account> listAccounts = [SELECT Id, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		System.runAs(objUser) {
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setSourceID('343434')
				.build();

			objOpportunity.Probability = 90;
			objOpportunity.Oppty_Commit_Flag__c = 'No';
			objOpportunity.Amount = 55000.00;
			objOpportunity.Referred_By__c = objResellerAccount.Id;

			Test.startTest();
			insert objOpportunity;
			Test.stopTest();

			List<Opportunity> listOpportunitiesQuery = [SELECT Id, Oppty_Commit_Flag__c FROM Opportunity WHERE Id = :objOpportunity.Id];
			System.assertEquals(listOpportunitiesQuery[0].Oppty_Commit_Flag__c, 'Yes');
			// Finally check if there are any exceptions logged
			checkForExceptions();
		}
	}

	/**@isTest
	static void testSetCloseDateInfo() {
		List<Account> listAccounts = [SELECT Id, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		List<Opportunity> listOpportunities = new List<Opportunity>();
		Opportunity objOpportunity = new Opportunity();
		objOpportunity.AccountId = objCompAccount.Id;
		objOpportunity.Name = 'Test Opp 2';
		objOpportunity.Probability = 90;
		objOpportunity.Oppty_Commit_Flag__c = 'No';
		objOpportunity.StageName = 'Open';
		objOpportunity.Amount = 55000.00;
		objOpportunity.Referred_By__c = objResellerAccount.Id;
		listOpportunities.add(objOpportunity);

		Opportunity objOpportunityIsWin = new Opportunity();
		objOpportunityIsWin.AccountId = objCompAccount.Id;
		objOpportunityIsWin.Name = 'Test Opp iswin';
		objOpportunityIsWin.StageName = 'Closed Won';
		objOpportunityIsWin.CloseDate = System.today() + 10;
		objOpportunityIsWin.Probability = 90;
		objOpportunityIsWin.Oppty_Commit_Flag__c = 'No';
		objOpportunityiswin.RecordTypeId = OpportunityUtil.BIZDEV_OPPTY_RT_ID;
		objOpportunityiswin.Benefits_Current_Setup_Step__c = 'Dismissed';
		objOpportunityiswin.Amount = 55000.00;
		objOpportunityiswin.Referred_By__c = objResellerAccount.Id;
		listOpportunities.add(objOpportunityiswin);

		Opportunity objOpportunityJoin = new Opportunity();
		objOpportunityJoin.AccountId = objCompAccount.Id;
		objOpportunityJoin.Name = 'Test Opp 2';
		objOpportunityJoin.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunityJoin.Joined_Date_Panda__c = System.today();
		listOpportunities.add(objOpportunityJoin);

		Opportunity objOpportunityZP = new Opportunity();
		objOpportunityZP.AccountId = objCompAccount.Id;
		objOpportunityZP.Name = 'Test Opp 2';
		objOpportunityZP.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		listOpportunities.add(objOpportunityZP);

		Opportunity objOpportunityLost = new Opportunity();
		objOpportunityLost.AccountId = objCompAccount.Id;
		objOpportunityLost.Name = 'Test Opp 2';
		objOpportunityLost.RecordTypeId = OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID;
		listOpportunities.add(objOpportunityLost);

		Test.startTest();
		System.runAs(TestUserUtility.getIntegrationUser()) {
			insert listOpportunities;
		}
		listOpportunities[3].ZP_Company_Suspended__c = true;
		List<Opportunity> listOpportunitiesQuery = [
			SELECT Id, Joined_Date_Panda__c, StageName, CloseDate, Closed_Won_Date__c, Closed_Date_Quarter_Last_Day__c
			FROM Opportunity
			WHERE Id IN :listOpportunities
		];
		Test.stopTest();
		System.assertEquals(listOpportunitiesQuery[1].CloseDate, Date.today());
		System.assertEquals(listOpportunitiesQuery[1].Closed_Won_Date__c, Date.today());
		System.assertEquals(listOpportunitiesQuery[1].Closed_Date_Quarter_Last_Day__c, OpportunityUtil.quarterLastDay(Date.today()));
	} **/

	/**@isTest
	static void testSetNameAndType() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		List<Account> listAccounts = [SELECT Id, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = new Account(Id = objAcc.Id, Name = objAcc.Name);
			} else {
				objResellerAccount = objAcc;
			}
		}

		System.runAs(objUser) {
			Test.startTest();
			List<Opportunity> listOpportunities = new List<Opportunity>();
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setSoldBy(objCompAccount.Id)
				.build();

			objOpportunity.Probability = 90;
			objOpportunity.Oppty_Commit_Flag__c = 'No';
			objOpportunity.Amount = 55000.00;
			objOpportunity.Referred_By__c = objResellerAccount.Id;
			listOpportunities.add(objOpportunity);
			insert listOpportunities;

			List<Opportunity> listOpportunitiesQuery = [SELECT Id, Name, Type, RecordTypeId FROM Opportunity WHERE Id IN :listOpportunities];
			System.assertEquals(OpportunityUtil.map_OpptyRTToDefaultValues.get(listOpportunitiesquery[0].RecordTypeId)[1], listOpportunitiesquery[0].type);
			System.assertEquals(objCompAccount.Name + ' - ' + OpportunityUtil.map_OpptyRTToDefaultValues.get(listOpportunitiesquery[0].RecordTypeId)[2], listOpportunitiesquery[0].Name);
			Test.stopTest();
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}**/

	@isTest
	static void testCreateTaskOnResellerAccounts() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		System.runAs(objUser) {
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setCloseDate(System.today())
				.setStage('MQL')
				.setSoldBy(objResellerAccount.Id)
				.build();
			objOpportunity.Verifying_Eligibility_Start__c = System.today().addDays(6);

			Test.startTest();
			insert objOpportunity;
			objOpportunity.Joined_Date_Panda__c = System.today();
			update objOpportunity;
			Test.stopTest();
			Task objTask = [SELECT Id FROM Task WHERE WhatId = :objResellerAccount.Id];
			//System.assertNotEquals(null, objTask.Id);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testUpsertOpptyRelatedTracking() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('ContactTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objCompAccount = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		System.runAs(objUser) {
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setCloseDate(System.today())
				.build();

			Test.startTest();
			insert objOpportunity;
			Test.stopTest();

			//Opportunity_Related_Tracking__c objOppRelatedTracking = [SELECT Id, Name FROM Opportunity_Related_Tracking__c WHERE Opportunity__c = :objOpportunity.Id];
			//System.assertNotEquals(null, objOppRelatedTracking.Id);
		}
	}

	@isTest
	static void testCreateCases() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objCompAccount = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		System.runAs(objUser) {
			List<Opportunity> listOpportunities = new List<Opportunity>();
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
				.build();
			listOpportunities.add(objOpportunity);
			Test.startTest();
			insert listOpportunities;
			Test.stopTest();

			List<Case> list_Casequery = [SELECT Id, Subject FROM Case WHERE Opportunity__c IN :listOpportunities];
			System.assertEquals('Gusto benefits change', list_Casequery[0].Subject);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testComplexityScoringAdvisingFulfillment() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		List<Account> listAccounts = [SELECT Id, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}
		System.runAs(objUser) {
			Test.startTest();
			Opportunity objOpportunityAsyncDismsd = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp BNP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.build();
			objOpportunityAsyncDismsd.Amount = 55000.00;
			objOpportunityAsyncDismsd.Referred_By__c = objResellerAccount.Id;
			objOpportunityAsyncDismsd.Renewal_Date__c = System.today().adddays(30);
			objOpportunityAsyncDismsd.FSA_Renewal__c = true;
			objOpportunityAsyncDismsd.HSA_Renewal__c = true;
			objOpportunityAsyncDismsd.Medical_Renewal__c = true;
			objOpportunityAsyncDismsd.Dental_Renewal__c = true;
			objOpportunityAsyncDismsd.Vision_Renewal__c = true;
			objOpportunityAsyncDismsd.Short_Term_Disability_Renewal__c = true;
			objOpportunityAsyncDismsd.Life_Renewal__c = true;
			objOpportunityAsyncDismsd.Long_Term_Disability_Renewal__c = true;
			objOpportunityAsyncDismsd.Voluntary_Life__c = true;
			objOpportunityAsyncDismsd.Stage_Detail__c = 'COVID-19';

			insert objOpportunityAsyncDismsd;

			List<Opportunity> listOpportunitiesquery = [SELECT Id, RecordType.Name, Name, AF_Complexity_Scoring__c FROM Opportunity WHERE Id = :objOpportunityAsyncDismsd.Id];
			System.assertEquals(10, listOpportunitiesquery[0].AF_Complexity_Scoring__c);
			Test.stopTest();
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testHandleBenefitsApplicationChange() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;

		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			}
		}
		System.runAs(objUser) {
			List<Opportunity> listOpportunities = new List<Opportunity>();
			Opportunity objOpportunityBenefitsChange = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp BNP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOpportunityBenefitsChange.Benefits_Current_Setup_Step__c = 'Completed';
			listOpportunities.add(objOpportunityBenefitsChange);

			Test.startTest();
			insert listOpportunities;
			listOpportunities[0].Benefits_Current_Setup_Step__c = 'Selecting Offerings';
			update listOpportunities;
			Test.stopTest();

			List<Opportunity> listOpportunitiesquery = [
				SELECT Id, RecordType.Name, Collecting_Company_Information_End__c, Awaiting_Education_End__c, Reviewing_Summary_End__c
				FROM Opportunity
				WHERE Id IN :listOpportunities
			];
			System.assertEquals(null, listOpportunitiesquery[0].Awaiting_Education_End__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testHandleBenefitsApplicationRenewal() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objCompAccount;
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			}
		}
		System.runAs(objUser) {
			List<Opportunity> listOpportunities = new List<Opportunity>();
			Opportunity objOpportunityBenefitsRenewal = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp BNP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOpportunityBenefitsRenewal.Benefits_Current_Setup_Step__c = 'Completed';
			listOpportunities.add(objOpportunityBenefitsRenewal);

			Test.startTest();
			insert listOpportunities;
			listOpportunities[0].Benefits_Current_Setup_Step__c = 'Awaiting Offerings';
			update listOpportunities;
			Test.stopTest();

			List<Opportunity> listOpportunitiesquery = [
				SELECT Id, RecordType.Name, Collecting_Company_Information_End__c, Awaiting_Education_End__c, Reviewing_Summary_End__c
				FROM Opportunity
				WHERE Id IN :listOpportunities
			];
			System.assertEquals(null, listOpportunitiesquery[0].Reviewing_Summary_End__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testHandleBenefitsApplicationNewPlan() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objCompAccount;
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			}
		}
		System.runAs(objUser) {
			List<Opportunity> listOpportunities = new List<Opportunity>();
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOpportunity.Benefits_Current_Setup_Step__c = 'Completed';
			listOpportunities.add(objOpportunity);

			Test.startTest();
			insert listOpportunities;
			listOpportunities[0].Benefits_Current_Setup_Step__c = 'Selecting Base Plan';
			update listOpportunities;
			Test.stopTest();

			List<Opportunity> listOpportunitiesquery = [
				SELECT Id, RecordType.Name, Collecting_Company_Information_End__c, Awaiting_Education_End__c, Reviewing_Summary_End__c
				FROM Opportunity
				WHERE Id IN :listOpportunities
			];
			System.assertEquals(null, listOpportunitiesquery[0].Collecting_Company_Information_End__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testNotesValidation() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objCompAccount = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		System.runAs(objUser) {
			Test.startTest();
			// Create Benefits Change Opportunity
			Opportunity objOpportunityBenefitsRenewal = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp BNP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOpportunityBenefitsRenewal.Benefits_Current_Setup_Step__c = 'Completed';
			insert objOpportunityBenefitsRenewal;

			objOpportunityBenefitsRenewal.Notes__c = 'Testing notes sync';
			update objOpportunityBenefitsRenewal;
			Test.stopTest();

			List<Case> listCasesToAssert = [SELECT Id, RecordType.Name, Notes__c FROM Case WHERE Opportunity__c = :objOpportunityBenefitsRenewal.Id];
			System.assert(listCasesToAssert.get(0).Notes__c != null);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testPopulateOpportunityStage() {
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		Test.startTest();
		List<Opportunity> listOpportunities = new List<Opportunity>();
		Opportunity objOpportunity = new Opportunity();
		objOpportunity.AccountId = objCompAccount.Id;
		objOpportunity.Name = 'Test Opp 2';
		objOpportunity.Sold_by__c = objResellerAccount.Id;
		objOpportunity.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunity.Verifying_Eligibility_Start__c = System.today().addDays(6);
		listOpportunities.add(objOpportunity);
		insert listOpportunities;
		List<BusinessHours> lst_BusinessHours = [SELECT Id FROM BusinessHours WHERE TimeZoneSidKey = 'America/Denver' LIMIT 1];

		OpportunityTriggerHelper.populateOpportunityStage(listOpportunities[0], 'Benefits New Plan', listOpportunities, lst_BusinessHours);
		objOpportunity.Joined_Date_Panda__c = System.today();
		update objOpportunity;
		Test.stopTest();
	}

	//updateMDRInfo both methods
	@isTest
	static void testUpdateOwnerBenefitsHIOwner() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		UserTriggerHelper.skipTrigger = true;
		Test.startTest();
		List<Account> listAccounts = [SELECT Id, HI_Owner__c, RecordTypeId, Name FROM Account];
		List<User> list_Users = new List<User>();
		User objUser = TestUserUtility.getPartnerAEUser(false);
		User objUserIntegration = TestUserUtility.getIntegrationUser(false);
		list_Users.add(objUserIntegration);

		User runningUser = TestUserUtility.getRunningUser();
		System.runAs(runningUser) {
			objUser.Is_Api_Integration__c = true;
			list_Users.add(objUser);
			insert list_Users;
		}
		GlobalQueryHelper.allIdUserMap = null;
		Account objCompAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
				objCompAccount.HI_Owner__c = objUser.Id; // Should become the Opportunity owner for Benefits opp
			}
		}

		List<Opportunity> listOpportunity = new List<Opportunity>();
		System.runAs(TestUserUtility.getIntegrationUser()) {
			Opportunity objOpportunity = new Opportunity();
			objOpportunity.AccountId = objCompAccount.Id;
			objOpportunity.Name = 'Test Opp 2';
			objOpportunity.OwnerId = objUser.Id;
			objOpportunity.RecordTypeId = OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID;
			objOpportunity.LeadSource = OpportunityUtil.ADDED_BY_ACCOUNTANT;
			listOpportunity.add(objOpportunity);

			insert listOpportunity;
		}
		Test.stopTest();

		List<Opportunity> listOpportunityquery = [
			SELECT Id, StageName, OwnerId, Owner.UserRoleId, Owner.UserRole.Name, Owner.Name, RecordType.Name, Name, AF_Complexity_Scoring__c
			FROM Opportunity
			WHERE Id IN :listOpportunity
		];

		System.assertEquals((Id) Label.Advising_Team_User, listOpportunityquery[0].OwnerId);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testBenefitsSetupLastUpdated() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');
		List<Opportunity> listOpportunities = new List<Opportunity>();
		Account objCompAccount = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];

		System.runAs(objUser) {
			Opportunity objOpportunityBenfefit = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOpportunityBenfefit.Benefits_Current_Setup_Step__c = OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP;
			objOpportunityBenfefit.Async_Renewal__c = true;
			objOpportunityBenfefit.Selecting_Enrollment_Periods_Start__c = System.today().addDays(20);
			listOpportunities.add(objOpportunityBenfefit);

			Opportunity objOpportunityPlan = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOpportunityPlan.Benefits_Current_Setup_Step__c = OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP;
			objOpportunityPlan.Async_Renewal__c = true;
			objOpportunityPlan.Selecting_Enrollment_Periods_End__c = System.today().addDays(20);
			listOpportunities.add(objOpportunityPlan);
			insert listOpportunities;

			Test.startTest();
			Case objCase = new TestDataFactory.CaseBuilder()
				.setRecordTypeId('Benefits Renewal Case')
				.setAccountId(objCompAccount.Id)
				.setSubject('Test')
				.setDescription('Test')
				.setOpportunity(listOpportunities[0].Id)
				.setType('QLE')
				.setOrigin('Email')
				.setSuppliedEmail('Test.test1@Test.com')
				.setAuthorizedUser('No')
				.build();
			objcase.Formating_Status__c = 'Pending';
			insert objcase;

			listOpportunities[0].Benefits_Current_Setup_Step__c = 'Selecting Base Plan';
			listOpportunities[0].Selecting_Enrollment_Periods_Start__c = System.today().addDays(25);

			listOpportunities[1].Selecting_Enrollment_Periods_End__c = System.today().addDays(25);
			update listOpportunities;
			Test.stopTest();
		}
		List<Opportunity> listOpportunitiesquery = [
			SELECT Id, Selecting_Enrollment_Periods_Start__c, Benefits_Setup_Last_Updated__c, Selecting_Enrollment_Periods_End__c
			FROM Opportunity
			WHERE Id IN :listOpportunities
		];

		System.assertEquals(OpportunityUtil.greaterTime(listOpportunitiesquery[0].Selecting_Enrollment_Periods_Start__c, null), listOpportunitiesquery[0].Benefits_Setup_Last_Updated__c);
		System.assertEquals(OpportunityUtil.greaterTime(listOpportunitiesquery[1].Selecting_Enrollment_Periods_End__c, null), listOpportunitiesquery[1].Benefits_Setup_Last_Updated__c);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testCreateContactRoles() {
		CaseTriggerHelper.skipTrigger = true;
		TicketTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		setUpNewPrices(objTierConfig.New_Price_1__c, true);
		setUpNewPrices(objTierConfig.New_Price_2__c, true);
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objAccnt.Tier__c = 'Simple';
		update objAccnt;
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];

		System.runAs(objUser) {
			Test.startTest();
			//Create roleset records
			Rolesets__c objRoleSet = new Rolesets__c();
			objRoleSet.Name = 'roleset1';
			objRoleSet.Roleset_Name__c = 'Company_Benefits';
			objRoleSet.components__c = 'OpportunityTriggerHelper';
			objRoleSet.Roles__c = 'Primary Payroll Admin\r\nPayroll Admin\r\nBenefits Signatory\r\nSignatory\r\nBenefits Admin';
			insert objRoleSet;

			//Create ZP roles records
			ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
				.setCustomId('777777777777772')
				.setEmail('testuser@gmail.com')
				.setLastSignInAt(System.now())
				.setCreatedAt(System.now())
				.setUpdatedAt(System.now())
				.build();
			insert objZPUser;

			//Create ZP user roles records
			ZP_User_Role__c objUserRole = new ZP_User_Role__c();
			objUserRole.User_Id__c = '777777777777777';
			objUserRole.Id__c = '9343434343499';
			objUserRole.Company_Account__c = objAccnt.Id;
			objUserRole.Company_Id__c = '911111111111111';
			objUserRole.Created_At__c = System.now();
			objUserRole.Updated_At__c = System.now();
			objUserRole.Type__c = 'Role::Primary Payroll Admin';
			objUserRole.Processing_State__c = 'Queued';
			objUserRole.Contact__c = objContact.Id;
			insert objUserRole;

			//Create ZP user roles records
			ZP_User_Role__c objUserRole1 = new ZP_User_Role__c();
			objUserRole1.User_Id__c = '777777777777779';
			objUserRole1.Id__c = '9343434343491';
			objUserRole1.Company_Account__c = objAccnt.Id;
			objUserRole1.Company_Id__c = '911111111111111';
			objUserRole1.Created_At__c = System.now();
			objUserRole1.Updated_At__c = System.now();
			objUserRole1.Type__c = 'Role::Benefits Admin';
			objUserRole1.Processing_State__c = 'Queued';
			objUserRole1.Contact__c = objContact.Id;
			insert objUserRole1;

			List<Opportunity> list_NewOpps = new List<Opportunity>();

			// Create Benefits Change Opportunity
			Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objAccnt.Id)
				.setName('Test Opp BNP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
				.setStage('MQL')
				.build();

			list_NewOpps.add(objOppty);

			// Create Customer Success Opportunity
			Opportunity objOppty1 = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objAccnt.Id)
				.setName('Test Opp CS')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.CUSTOMER_SUCCESS_RT_ID)
				.setStage('MQL')
				.build();
			list_NewOpps.add(objOppty1);

			// Create Cross-Sell and Upsell Opportunity
			Opportunity objOppty2 = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objAccnt.Id)
				.setName('Test Opp Cross-Sell and Upsell')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
				.setStage('Qualified')
				.setUpsellTier(AccountUtil.PLUS_TIER)
				.build();
			objOppty2.Current_Tier__c = AccountUtil.SIMPLE_TIER;
			list_NewOpps.add(objOppty2);

			insert list_NewOpps;
			Test.stopTest();

			List<OpportunityContactRole> list_OppConRole = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :list_NewOpps LIMIT 4];
			System.assertNotEquals(null, list_OppConRole[0]);
			System.assertNotEquals(null, list_OppConRole[1]);
			System.assertNotEquals(null, list_OppConRole[2]);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testUpdateBorNPOpportunityToCL() {
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		User objUser = [SELECT Id, Name, ProfileId FROM User WHERE ProfileId = :Label.Benefits_User_ProfileId LIMIT 1];
		objUser.isactive = true;
		//  update objUser;

		List<Opportunity> listOpportunities = new List<Opportunity>();

		Opportunity objOpptyBenfit = new Opportunity();
		objOpptyBenfit.AccountId = objAccnt.Id;
		objOpptyBenfit.Name = 'Test Opp BNP';
		objOpptyBenfit.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
		listOpportunities.add(objOpptyBenfit);

		Test.startTest();

		insert listOpportunities;
		listOpportunities[0].stagename = OpportunityUtil.CLOSED_WON_STAGE;
		update listOpportunities;

		Test.stopTest();
	}

	@isTest
	static void testUpdateAccountAndContactOwner() {
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		User objRunningUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		User objUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = '_del_ZP SDR' LIMIT 1];
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}
		System.runAs(objRunningUser) {
			Test.startTest();
			List<Opportunity> listOpportunities = new List<Opportunity>();
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('Test Opp 2')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setStage('MQL')
				.build();
			listOpportunities.add(objOpportunity);
			insert listOpportunities;

			objCompAccount.OwnerId = objUser.Id;
			update objCompAccount;
			Test.stopTest();
			List<Opportunity> list_Opptys = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :objOpportunity.Id];
			List<Contact> list_Contacts = [SELECT Id, OwnerId FROM Contact WHERE Accountid = :objOpportunity.AccountId];
			//System.assertEquals(objCompAccount.OwnerId, list_Opptys[0].OwnerId);
			//System.assertEquals(objCompAccount.OwnerId, list_Contacts[0].OwnerId);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	@isTest
	static void testRollUpValuesToAccounts() {
		CaseTriggerHelper.skipTrigger = true;
		TicketTriggerHelper.skipTrigger = true;
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		User objAPIUser = TestUserUtility.getIntegrationUser();

		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account Old Owner').setZPCompanyId('111111433111').build();
		insert objCompanyAccount;

		List<Opportunity> listOpportunities = new List<Opportunity>();
		//Insert referred by account opportunity
		Opportunity objOpportunity = new Opportunity();
		objOpportunity.Name = 'Test Opp 2';
		objOpportunity.AccountId = objCompAccount.Id;
		objOpportunity.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunity.Referred_By__c = objResellerAccount.Id;
		objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		objOpportunity.CloseDate = System.today();
		listOpportunities.add(objOpportunity);

		//Insert sold by account opportunity
		Opportunity objOpportunitysold = new Opportunity();
		objOpportunitysold.Name = 'Test Opp 2';
		objOpportunitysold.AccountId = objCompanyAccount.Id;
		objOpportunitysold.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunitysold.Sold_By__c = objResellerAccount.Id;
		objOpportunitysold.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		objOpportunitysold.CloseDate = System.today();
		listOpportunities.add(objOpportunitysold);

		//Insert BENEFITS record type opportunity
		Opportunity objOpportunityBen = new Opportunity();
		objOpportunityBen.AccountId = objCompAccount.Id;
		objOpportunityBen.Name = 'Test Opp 2';
		objOpportunityBen.RecordTypeId = OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID;
		objOpportunityBen.Benefits_Notes__c = 'test';
		objOpportunityBen.CloseDate = System.today();
		objOpportunityBen.StageName = OpportunityUtil.MQL_STAGE;
		listOpportunities.add(objOpportunityBen);

		//Insert BENEFITS record type opportunity
		Opportunity objOpportunityBenNewplan = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompAccount.Id)
			.setName('Test Opp 2')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setStage('SAL')
			.build();
		objOpportunityBenNewplan.Benefits_Notes__c = 'test';
		objOpportunityBenNewplan.Users_Email__c = 'se@g.com';
		objOpportunityBenNewplan.CloseDate = System.today();
		objOpportunityBenNewplan.StageName = OpportunityUtil.MQL_STAGE;
		listOpportunities.add(objOpportunityBenNewplan);

		Test.startTest();
		System.runAs(objAPIUser) {
			insert listOpportunities;
			listOpportunities[2].Benefits_Notes__c = 'update on account';
			listOpportunities[3].Benefits_Notes__c = 'update on account';
			listOpportunities[3].Selecting_Employee_Eligibility_Start__c = System.now();
			listOpportunities[3].Users_Email__c = 'se@g.com';
			update listOpportunities;
		}
		Test.stopTest();
		//asserts
		List<Opportunity> listOppQuery = [SELECT Id, Name, Benefits_Notes__c, RecordType.Name, StageName, Sold_By__c, Referred_By__c, Users_Email__c FROM Opportunity WHERE Id IN :listOpportunities];
		Account objAccQueryCom = [SELECT Id, Benefits_Notes__c, Initiated_NP_Flow__c, Sold_By__c, Referred_By__c FROM Account WHERE Id = :objCompAccount.Id];
		Account objAccQueryCom2 = [SELECT Id, Partner_Status__c FROM Account WHERE Id = :objResellerAccount.Id];
		//System.assertEquals(objAccQueryCom2.Partner_Status__c, AccountUtil.PARTNER_STATUS_ACTIVE_PARTNER);
		//System.assertEquals(listOppQuery[2].Benefits_Notes__c, objAccQueryCom.Benefits_Notes__c);
		//System.assertEquals(listOppQuery[3].Users_Email__c, objAccQueryCom.Initiated_NP_Flow__c);
	}

	/**@isTest
	static void testProcessLeadSource() {
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		Partner_Referral_Source__c objPartnerSource;

		Account objBizDev;
		User adminUser = [SELECT Id FROM User WHERE Alias = 'adminu' LIMIT 1];
		System.runAs(adminUser) {
			objBizDev = new TestDataFactory.AccountBuilder().setName('BizDev').setRecordTypeId('BizDev').build();
			insert objBizDev;

			objPartnerSource = new Partner_Referral_Source__c();
			objPartnerSource.Source_Name__c = 'Trade Show';
			objPartnerSource.BizDev_Account__c = objBizDev.Id;
			insert objPartnerSource;
		}

		List<Opportunity> listOpportunities = new List<Opportunity>();

		//Insert COMPANY  opportunity
		Opportunity objOpportunity = new Opportunity();
		objOpportunity.AccountId = objCompAccount.Id;
		objOpportunity.Name = 'Test Opp 1';
		objOpportunity.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunity.LeadSource = 'Bench';
		listOpportunities.add(objOpportunity);

		//Insert COMPANY  opportunity with lead source clarus
		Opportunity objOpportunityclarus = new Opportunity();
		objOpportunityclarus.AccountId = objCompAccount.Id;
		objOpportunityclarus.Name = 'Test Opp 2';
		objOpportunityclarus.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunityclarus.LeadSource = 'clarusrd';
		listOpportunities.add(objOpportunityclarus);

		//Insert COMPANY  opportunity with lead tradeshow
		Opportunity objOpportunityTrade = new Opportunity();
		objOpportunityTrade.AccountId = objCompAccount.Id;
		objOpportunityTrade.Name = 'Test Opp 3';
		objOpportunityTrade.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunityTrade.LeadSource = 'Trade Show';
		listOpportunities.add(objOpportunityTrade);

		//Insert COMPANY  opportunity with with sold value
		Opportunity objOpportunitysold = new Opportunity();
		objOpportunitysold.AccountId = objCompAccount.Id;
		objOpportunitysold.Name = 'Test Opp 4';
		objOpportunitysold.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOpportunitysold.Sold_By__c = objResellerAccount.Id;
		listOpportunities.add(objOpportunitysold);

		//Insert Benfitchange  opportunity with with sold value
		Opportunity objOpportunityBenf = new Opportunity();
		objOpportunityBenf.AccountId = objCompAccount.Id;
		objOpportunityBenf.Name = 'Test Opp 5';
		objOpportunityBenf.RecordTypeId = OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID;
		objOpportunityBenf.Source_ID__c = 'Trade Show';
		listOpportunities.add(objOpportunityBenf);

		Test.startTest();
		insert listOpportunities;
		Test.stopTest();
		List<Opportunity> listOppQuery = [SELECT Id, Sold_By__c, LeadSource FROM Opportunity WHERE Id IN :listOpportunities];
		System.assertEquals(OpportunityUtil.benchAccountId, listOppQuery[0].Sold_By__c);
		System.assertEquals(OpportunityUtil.clarusAccountId, listOppQuery[1].Sold_By__c);
		System.assertEquals(OpportunityUtil.ADDED_BY_ACCOUNTANT, listOppQuery[3].LeadSource);
		System.assertEquals(OpportunityUtil.APP_GENERATED, listOppQuery[4].LeadSource);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	} **/

	/**
	 * @description check Lead Source value of Opp for heroku User(Integration)
	 * @author Nigam Goyal | 04-18-2023
	 **/
	@isTest
	static void testProcessLeadSourceForHerokuUser() {
		User objUser = [SELECT Id FROM User WHERE Alias = 'heroku' LIMIT 1];
		List<Account> list_Accounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objAccount = new Account();
		if (list_Accounts.size() > 0) {
			objAccount = list_Accounts[0];
		}
		List<Opportunity> list_Opportunities = new List<Opportunity>();

		System.runAs(objUser) {
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
				.setName('Test Opp 1')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setSourceID('Test Opp 1')
				.setCloseDate(System.today())
				.build();
			list_Opportunities.add(objOpportunity);

			Test.startTest();
			insert list_Opportunities;
			Test.stopTest();
			List<Opportunity> list_OppQuery = [SELECT Id, Sold_By__c, LeadSource FROM Opportunity WHERE Id IN :list_Opportunities];

			System.assertEquals(OpportunityUtil.APP_GENERATED, list_OppQuery[0].LeadSource, 'Lead Source Should be App-Generated');
		}
	}

	/**
	 * @description check Lead Source value of Opp for standard User
	 * @author Nigam Goyal | 04-18-2023
	 **/
	@isTest
	static void testProcessLeadSourceForStandardUser() {
		User objUser = [SELECT Id FROM User WHERE UserRole.Name = 'sales_sdr_partner_xx' AND isActive = TRUE LIMIT 1];
		List<Account> list_Accounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objAccount = new Account();
		if (list_Accounts.size() > 0) {
			objAccount = list_Accounts[0];
		}
		List<Opportunity> list_Opportunities = new List<Opportunity>();

		System.runAs(objUser) {
			Opportunity objOpportunity6 = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setName('Test Opp 6')
				.setAccountId(objAccount?.Id)
				.setStage('Open')
				.setSourceID('Test Opp 1')
				.setCloseDate(System.today())
				.build();
			list_Opportunities.add(objOpportunity6);

			Opportunity objOpportunity7 = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
				.setName('Test Opp 7')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setSourceID('Test Opp 7')
				.setCloseDate(System.today())
				.build();
			list_Opportunities.add(objOpportunity7);

			Opportunity objOpportunity8 = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
				.setName('Test Opp 8')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setSourceID('Test Opp 8')
				.setCloseDate(System.today())
				.build();
			list_Opportunities.add(objOpportunity8);

			Test.startTest();
			insert list_Opportunities;
			Test.stopTest();
			List<Opportunity> list_Opps = [SELECT Id, Sold_By__c, LeadSource FROM Opportunity WHERE Id IN :list_Opportunities];

			System.assertEquals(OpportunityUtil.MANUAL, list_Opps[0].LeadSource, 'Lead Source Should be Manual');
			System.assertEquals(OpportunityUtil.MANUAL, list_Opps[1].LeadSource, 'Lead Source Should be Manual');
			System.assertEquals(OpportunityUtil.MANUAL, list_Opps[2].LeadSource, 'Lead Source Should be Manual');
		}
	}

	/**@isTest
	static void testUpdateEmployeeCounts() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];

		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		List<Opportunity> listOpportunities = new List<Opportunity>();
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, ZP_Company_Id__c, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}

		System.runAs(objUser) {
			Payment_Invoice__c objPaymentInvoice = new Payment_Invoice__c();
			objPaymentInvoice.Company_Id__c = objCompAccount.ZP_Company_Id__c;
			objPaymentInvoice.Pricing__c = objTierConfig.New_Price_2__c;
			objPaymentInvoice.Amount__c = 100;
			objPaymentInvoice.Employee_Count__c = 5;
			objPaymentInvoice.Contractor_Count__c = 0;
			objPaymentInvoice.Discount__c = 0;
			objPaymentInvoice.Volume_Discount__c = 0;
			objPaymentInvoice.Additional_Discount__c = 0;
			insert objPaymentInvoice;

			//Insert COMPANY  opportunity
			Opportunity objOpportunity = new Opportunity();
			objOpportunity.AccountId = objCompAccount.Id;
			objOpportunity.Name = 'Test Opp 0';
			objOpportunity.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
			objOpportunity.StageName = 'Qualified';
			objOpportunity.NumberOfEmployees__c = 10;
			objOpportunity.CloseDate = Date.today().addDays(7);
			listOpportunities.add(objOpportunity);

			//Insert BENEFITS_NEW_PLAN Opportunity
			Opportunity objOpportunityBen = new Opportunity();
			objOpportunityBen.AccountId = objCompAccount.Id;
			objOpportunityBen.Name = 'Test Opp 1';
			objOpportunityBen.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
			objOpportunityBen.NumberOfEmployees__c = 10;
			objOpportunityBen.CloseDate = Date.today().addDays(7);
			objOpportunityBen.StageName = 'Qualified';
			listOpportunities.add(objOpportunityBen);

			//Insert  Opportunity with invoice
			Opportunity objOpportunityInvo = new Opportunity();
			objOpportunityInvo.AccountId = objCompAccount.Id;
			objOpportunityInvo.Name = 'Test Opp 2';
			objOpportunityInvo.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
			objOpportunityInvo.NumberOfEmployees__c = 10;
			objOpportunityInvo.Source_ID__c = 'Invoice';
			objOpportunityInvo.Payment_Invoice__c = objPaymentInvoice.Id;
			objOpportunityInvo.StageName = 'Qualified';
			ObjOpportunityInvo.CloseDate = Date.today().addDays(7);
			listOpportunities.add(objOpportunityInvo);

			Test.startTest();
			insert listOpportunities;
			List<Opportunity> listOppQueryInsert = [SELECT Id, NumberOfEmployees__c, EE_Active_Count_At_Win__c FROM Opportunity WHERE Id IN :listOpportunities];
			System.assertEquals(listOppQueryInsert[2].NumberOfEmployees__c, objPaymentInvoice.Employee_Count__c);
		}
		listOpportunities[0].NumberOfEmployees__c = 20;
		listOpportunities[1].Completed__c = System.now();
		update listOpportunities;
		Test.stopTest();
		Opportunity opp2 = [SELECT Id, NumberOfEmployees__c, EE_Active_Count_At_Win__c FROM Opportunity WHERE Id = :listOpportunities[1].Id LIMIT 1];

		System.assertEquals(opp2.EE_Active_Count_At_Win__c, opp2.NumberOfEmployees__c);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	} **/

	@isTest
	static void testLineItemForHIOpptysBasedOnPolicy() {
		// Data Setup
		// Create a Medical Policy
		Product2 objMedicalProd = new Product2(Name = 'Medical', Family = 'Medical', ProductCode = 'MED', IsActive = true);
		insert objMedicalProd;

		PricebookEntry objStandardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = objMedicalProd.Id, UnitPrice = 10, IsActive = true);
		insert objStandardPrice;

		// Create a new Test Pricebook
		Pricebook2 objPricebook = new Pricebook2(Name = 'Benefits 2020', IsActive = true);
		insert objPricebook;

		PricebookEntry objCustomPrice = new PricebookEntry(Pricebook2Id = objPricebook.Id, Product2Id = objMedicalProd.Id, UnitPrice = 10, IsActive = true);
		insert objCustomPrice;

		// Create a new Company Account
		Account objCompanyAccnt = new Account(RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID, Name = 'Test Company Account');
		insert objCompanyAccnt;

		List<Opportunity> list_OpptysToInsert = new List<Opportunity>();

		// Create a new Benefits Plan Opportunity

		Opportunity objHIOppty = new Opportunity(
			RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID,
			AccountId = objCompanyAccnt.Id,
			CloseDate = Date.today(),
			Pricebook2Id = objPricebook.Id,
			Name = 'Test Company Benefits New Plan',
			NumberOfEmployees__c = 1,
			StageName = 'Raw'
		);
		list_OpptysToInsert.add(objHIOppty);
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		insert list_OpptysToInsert;
		OpportunityTriggerHelper.skipTrigger = false;

		// Create a new Carrier
		Carrier__c objMedicalCarrier = new Carrier__c(Name = 'Test Medical Carrier');
		insert objMedicalCarrier;

		// Data Setup Completed

		// Insert a new policy and associate it with HI Opportunity
		// This should create line items on Opportunity

		Policy__c objMedicalPolicy = new Policy__c(
			Benefit_Type__c = 'Medical',
			Opportunity__c = objHIOppty.Id,
			Is_Selected__c = true,
			Carrier__c = objMedicalCarrier.Id,
			Account__c = objCompanyAccnt.Id
		);
		insert objMedicalPolicy;

		// Assertions based on selecting and de-selecting a policy

		// Creating a new policy should insert new line items
		Integer intLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objHIOppty.Id];

		// Assert that there are ONLY one line items
		System.assertEquals(1, intLineItems);

		objMedicalPolicy.Is_Selected__c = false;
		update objMedicalPolicy;

		// De-selecting policy should remove line items
		intLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objHIOppty.Id];

		// Assert that there are no line items
		System.assertEquals(0, intLineItems);

		// Re-selecting them should be bring new line items
		objMedicalPolicy.Is_Selected__c = true;
		update objMedicalPolicy;
		Test.stopTest();

		intLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objHIOppty.Id];

		// Assert that there are ONLY one line items
		System.assertEquals(1, intLineItems);
	}

	@isTest
	static void testLineItemForHIOpptysBasedOnEECounts() {
		TriggerHandler.bypass('AccountTriggerHandler');
		CarrierTriggerHelper.skipTrigger = true;
		// Data Setup
		// Create a Medical Policy
		Product2 objMedicalProd = new Product2(Name = 'Medical', Family = 'Medical', ProductCode = 'MED', IsActive = true);
		insert objMedicalProd;

		PricebookEntry objStandardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = objMedicalProd.Id, UnitPrice = 10, IsActive = true);
		insert objStandardPrice;

		// Create a new Test Pricebook
		Pricebook2 objPricebook = new Pricebook2(Name = 'Benefits 2020', IsActive = true);
		insert objPricebook;

		PricebookEntry objCustomPrice = new PricebookEntry(Pricebook2Id = objPricebook.Id, Product2Id = objMedicalProd.Id, UnitPrice = 10, IsActive = true);
		insert objCustomPrice;

		// Create a new Company Account
		Account objCompanyAccnt = new Account(RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID, Name = 'Test Company Account');
		insert objCompanyAccnt;

		List<Opportunity> list_OpptysToInsert = new List<Opportunity>();

		// Create a new Benefits Plan Opportunity

		Opportunity objHIOppty = new Opportunity(
			RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID,
			AccountId = objCompanyAccnt.Id,
			CloseDate = Date.today(),
			Pricebook2Id = objPricebook.Id,
			Name = 'Test Company Benefits New Plan',
			NumberOfEmployees__c = 1
		);
		list_OpptysToInsert.add(objHIOppty);
		insert list_OpptysToInsert;

		// Create a new Carrier
		Carrier__c objMedicalCarrier = new Carrier__c(Name = 'Test Medical Carrier');
		insert objMedicalCarrier;

		// Data Setup Completed

		// Insert a new policy and associate it with HI Opportunity
		// This should create line items on Opportunity
		Policy__c objMedicalPolicy = new Policy__c(
			Benefit_Type__c = 'Medical',
			Opportunity__c = objHIOppty.Id,
			Is_Selected__c = true,
			Carrier__c = objMedicalCarrier.Id,
			Account__c = objCompanyAccnt.Id
		);
		insert objMedicalPolicy;
		Test.startTest();
		// Assertions based on changing number of employees
		objHIOppty.NumberOfEmployees__c = 0;
		update objHIOppty;

		// Setting number of employees to 0 should remove line items
		Integer intLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objHIOppty.Id];

		// Assert that there are no line items
		System.assertEquals(0, intLineItems);

		// Update number of employees to more than 0, should bring back new line items
		objHIOppty.NumberOfEmployees__c = 1;
		update objHIOppty;

		intLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objHIOppty.Id];

		// Assert that there are ONLY one line items
		System.assertEquals(1, intLineItems);

		// Update number of employees
		objHIOppty.NumberOfEmployees__c = 10;
		update objHIOppty;
		Test.stopTest();
	}

	@isTest
	static void testHIBenefitConatctRole() {
		String strCompanyId = '1234567890';
		List<Account> listAccounts = [SELECT Id, RecordTypeId, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :strCompanyId];
		if (listAccounts.size() > 0) {
			List<Contact> list_Contact = new List<Contact>();
			list_Contact.add(new Contact(FirstName = 'Test', LastName = 'Conatct 1', AccountId = listAccounts[0].Id, Email = 'test_hi_role1@gusto.com', ZP_User_Id__c = '75301'));
			list_Contact.add(new Contact(FirstName = 'Test', LastName = 'Conatct 2', AccountId = listAccounts[0].Id, Email = 'test_hi_role2@gusto.com', ZP_User_Id__c = '75302'));
			Test.startTest();
			insert list_Contact;

			List<ZP_User__c> list_ZpUser = new List<ZP_User__c>();
			list_ZpUser.add(new ZP_User__c(Name = 'Test Conatct 1', Id__c = '75301', Email__c = 'test_hi_role1@gusto.com', Created_At__c = Date.Today(), Updated_At__c = Date.Today()));
			list_ZpUser.add(new ZP_User__c(Name = 'Test Conatct 2', Id__c = '75302', Email__c = 'test_hi_role2@gusto.com', Created_At__c = Date.Today(), Updated_At__c = Date.Today()));
			insert list_ZpUser;

			List<ZP_User_Role__c> list_ZpUserRole = new List<ZP_User_Role__c>();
			list_ZpUserRole.add(new ZP_User_Role__c(First_Name__c = 'Test', Last_Name__c = 'Conatct 1', Type__c = 'Role::BenefitsAdmin', User_Id__c = '75301', Company_Id__c = strCompanyId));
			list_ZpUserRole.add(new ZP_User_Role__c(First_Name__c = 'Test', Last_Name__c = 'Conatct 2', Type__c = 'Role::BenefitsSignatory', User_Id__c = '75302', Company_Id__c = strCompanyId));
			insert list_ZpUserRole;

			HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c(
				Id__c = '75301',
				Company_Id__c = strCompanyId,
				ZP_User_Id__c = '75301',
				Created_At__c = DateTime.Now(),
				Updated_At__c = DateTime.Now(),
				Processing_State__c = 'Queued'
			);
			insert objHIAdmin;

			HI_Benefits_Signatory__c objHISignatory = new HI_Benefits_Signatory__c(
				Id__c = '75302',
				Company_Id__c = strCompanyId,
				ZP_User_Id__c = '75302',
				Created_At__c = DateTime.Now(),
				Updated_At__c = DateTime.Now(),
				Processing_State__c = 'Queued'
			);
			insert objHISignatory;

			// Create Opportunity
			Opportunity objOpportunityAsyncDismsd = new Opportunity();
			objOpportunityAsyncDismsd.AccountId = listAccounts[0].Id;
			objOpportunityAsyncDismsd.Name = 'Test Opp BNP';
			objOpportunityAsyncDismsd.CloseDate = System.today();
			objOpportunityAsyncDismsd.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
			insert objOpportunityAsyncDismsd;
			Test.stoptest();

			//Two Opportunity Contact Role Should be created.
			List<OpportunityContactRole> list_OppRole = [SELECT Id, OpportunityId FROM OpportunityContactRole WHERE OpportunityId = :objOpportunityAsyncDismsd.Id];

			System.assert(list_OppRole.size() >= 2);
		}
	}

	@isTest
	static void testBenefitsOptOutFields() {
		TriggerHandler.bypass('AccountTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		List<Account> listAccountsUpd = new List<Account>();
		List<Account> listAccounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		Account objResellerAccount;
		for (Account objAcc : listAccounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = objAcc;
			} else {
				objResellerAccount = objAcc;
			}
		}
		//Update Company and Reseller Accounts
		objCompAccount.ZP_Company_ID__c = '6548889';
		listAccountsUpd.add(objCompAccount);

		objResellerAccount.ZP_Firm_ID__c = '7777789';
		objResellerAccount.Apply_To_All_Clients__c = true;
		objResellerAccount.Benefits_Email_Opt_Out__c = 'Health Insurance;Workers Comp';
		listAccountsUpd.add(objResellerAccount);
		update listAccountsUpd;

		System.runAs(objUser) {
			Opportunity objCompanyOpp = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objCompAccount.Id)
				.setName('GUSTO-TESTOPP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setStage('Qualified')
				.build();
			objCompanyOpp.Sold_By__c = objResellerAccount.Id;
			Test.startTest();
			insert objCompanyOpp;

			objCompanyOpp = [SELECT Id, Benefits_Opt_Out__c FROM Opportunity WHERE Id = :objCompanyOpp.Id];
			System.assertEquals(objCompanyOpp.Benefits_Opt_Out__c, 'Health Insurance;Workers Comp');

			objResellerAccount.Apply_to_all_clients__c = false;
			objResellerAccount.Benefits_Email_Opt_Out__c = 'Health Insurance';
			update objResellerAccount;

			update objCompanyOpp;

			objCompanyOpp = [SELECT Id, Benefits_Opt_Out__c FROM Opportunity WHERE Id = :objCompanyOpp.Id];
			//System.assertEquals('Health Insurance;Workers Comp', objCompanyOpp.Benefits_Opt_Out__c);

			Test.stopTest();
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Big Desk CSM Status field is synced between Account and Opportunity
	 **/
	/**@isTest
	static void testSyncBigDeskCSMStatusOnAccount() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

			Opportunity objOppty = TestUtils.createOpportunity(OpportunityUtil.ACQUISITION_OPPTY_RT_ID, objCompanyAccnt.Id, Date.today().addDays(10), 'Opp Name', 'MQL', true);

			Test.startTest();
			objOppty.Big_Desk_CSM_Pitch_Status__c = 'Pitched - Customer Interested';
			objOppty.Big_Desk_CSM_Pitch_Notes__c = 'Testing';
			update objOppty;
			Test.stopTest();

			Account objAccntAssert = [SELECT Id, Big_Desk_CSM_Pitch_Status__c FROM Account WHERE Id = :objCompanyAccnt.Id];
			System.assertEquals(objOppty.Big_Desk_CSM_Pitch_Status__c, objAccntAssert.Big_Desk_CSM_Pitch_Status__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	} **/

	/**
	 * @author      Praveen Sethu
	 * @description Test if Last Client Add Date is updated on Reseller Account
	 **/
	@isTest
	static void testLastClientAddDateUpdate() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			// Skip Account Trigger for faster Account inserts
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('123456789').build();
			insert objCompAccount;

			Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
			insert objResellerAccount;
			TriggerHandler.clearBypass('AccountTriggerHandler');

			Test.startTest();
			Opportunity objCompanyOppty = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.setAccountId(objCompAccount.Id)
				.setCloseDate(Date.today())
				.setStage(OpportunityUtil.MQL_STAGE)
				.setName('Payroll Opportunity')
				.setSoldBy(objResellerAccount.Id)
				.build();
			insert objCompanyOppty;
			Test.stopTest();

			Account objAccountAssert = [SELECT Id, Last_Client_Add_Date__c FROM Account WHERE Id = :objResellerAccount.Id];
			//System.assertEquals(Date.today(), objAccountAssert.Last_Client_Add_Date__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Deepika Saini
	 * @description Test if update Special Enrollment Submission Deadline date on creation of Opp
	 **/
	@isTest
	static void testSpecialEnrollmentSubmissionDeadline() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('OpportunityTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');
		CarrierTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		Id idTTFRecordType = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');

		// Retrieve Company Account
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'testuser@abccompany.com' LIMIT 1];

		// Create new Carrier
		Carrier__c objCarrier = new Carrier__c();
		objCarrier.Name = 'NewCarrierForTask';
		objCarrier.State__c = 'CA';
		insert objCarrier;

		// Create Benefits New Plan Opportunity
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;

		objOppty.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		update objOppty;

		QA_Sheet__c objQASheet1 = new TestDataFactory.QASheetBuilder()
			.setOpportunityId(objOppty.Id)
			.setFederalCobraState('Federal')
			.setSICCodeSupportedByAllCarriers('Yes')
			.setSICCode('test')
			.setBAASigned('Yes')
			.setBAASignedBy('test')
			.setBSASigned('Yes')
			.setBSASignedBy('test')
			.setRecordTypeId(Cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal'))
			.setNewTAdAs(CarrierOrderUtil.TADA_BEN_TYPE_HSA)
			.setRenewingTAdAs(CarrierOrderUtil.TADA_BEN_TYPE_COMMUTER)
			.build();
		objQASheet1.Special_Enrollment__c = 'Y';
		insert objQASheet1;

		TriggerHandler.clearBypass('OpportunityTriggerHandler');

		// Creating new Benefit Orders
		Benefit_Order__c objBOrder = TestUtility.createTestBenefitOrder('New Plan', objOppty.Id, 'Benefit Order', true);
		objBOrder.Push_Rate_Reason__c = 'Other';

		// Creating new Product
		Product2 objProduct = TestUtility.createTestProduct('Medical', 'Benefit', true);

		PricebookEntry objPBE = TestUtility.createTestPriceBookEntry(objProduct.Id, 5, Test.getStandardPriceBookId(), true); //NOPMD

		// Creating new Carrier Order
		Carrier_Order__c objCarrierOrder = TestUtility.createTestCarrierOrder(objCarrier.Id, 'Carrier Order', objBOrder.Id, true);

		// Getting current month's last date and set it as expiration date
		Date dtExpirationDate = Date.today().addMonths(1).toStartOfMonth().addDays(-1);

		// Creating an Active Policy
		Policy__c objPolicy = TestUtility.createTestPolicy(objOppty.Id, objCarrier.Id, true, 'Test Policy ', objCarrierOrder.Id, false);
		objPolicy.Benefit_Type__c = 'Medical';
		objPolicy.Account__c = objAccnt.Id;
		objPolicy.Expiration_Date__c = dtExpirationDate;
		objPolicy.Coverage_Effective_Date__c = System.today().adddays(-3);
		insert objPolicy;

		Test.startTest();

		objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		objOppty.HI_Effective_Date__c = Configuration_Settings__c.getOrgDefaults().HI_Effective_Date__c;
		insert objOppty;

		Test.stopTest();

		Opportunity objOpportunity = [SELECT Id, Submission_Deadline__c FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID AND AccountId = :objAccnt.Id];

		System.assertEquals(Configuration_Settings__c.getOrgDefaults().Special_Enrollment_Deadline_Date__c, objOpportunity.Submission_Deadline__c);
	}

	/**
	 * @author      Deepika Saini
	 * @description Test Assign advisor to Renewal Opportunity
	 **/
	@isTest
	static void testAdvisingAssignment() {
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];

		TriggerHandler.bypass('OpportunityTriggerHandler');

		// Retrieve Company Account
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		System.runAs(objUser) {
			// Create Benefits Renewal Opportunity
			Opportunity objOppty = new Opportunity();
			objOppty.AccountId = objAccnt.Id;
			objOppty.Name = 'Test Opp BNP';
			objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
			objOppty.CloseDate = System.today();
			objOppty.StageName = OpportunityUtil.SAL_STAGE;
			objOppty.Pricebook2Id = Test.getStandardPriceBookId();
			objOppty.UW_State_PY__c = 'Arizona';
			objOppty.HI_Effective_Date__c = System.today();
			insert objOppty;

			TriggerHandler.clearBypass('OpportunityTriggerHandler');

			Test.startTest();
			objOppty.Advisor_Assignment__c = 'Jira required';
			update objOppty;
			Test.stopTest();

			Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c FROM Opportunity WHERE Id = :objOppty.Id];

			System.assertNotEquals(null, objOpportunity.Owner_Role_Name__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Deepika Saini
	 * @description Test if there is no skills of advisor
	 **/
	@isTest
	static void testAdvisingAssignmentWithoutSkills() {
		TriggerHandler.bypass('OpportunityTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		// Retrieve Company Account
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		System.runAs(objUser) {
			// Create Benefits Renewal Opportunity
			Opportunity objOppty = new Opportunity();
			objOppty.AccountId = objAccnt.Id;
			objOppty.Name = 'Test Opp BNP';
			objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
			objOppty.CloseDate = System.today();
			objOppty.StageName = OpportunityUtil.SAL_STAGE;
			objOppty.Pricebook2Id = Test.getStandardPriceBookId();
			objOppty.UW_State_PY__c = 'California';
			objOppty.HI_Effective_Date__c = System.today();
			insert objOppty;

			TriggerHandler.clearBypass('OpportunityTriggerHandler');

			Test.startTest();
			objOppty.Advisor_Assignment__c = 'Jira required';
			update objOppty;
			Test.stopTest();

			Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOppty.Id];

			System.assertEquals(null, objOpportunity.Owner_Role_Name__c);
			System.assertEquals(OpportunityUtil.MSG_NO_ADVISING_ASSIGNMENT_USER_ELIGIBLE, objOpportunity.Advising_Assignment_Message__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Deepika Saini
	 * @description Test if UW State PY is missing in Advising Assignment
	 **/
	@isTest
	static void testAdvisingAssignmentUWStatePYMissing() {
		TriggerHandler.bypass('OpportunityTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		// Retrieve Company Account
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		System.runAs(objUser) {
			// Create Benefits Renewal Opportunity
			Opportunity objOppty = new Opportunity();
			objOppty.AccountId = objAccnt.Id;
			objOppty.Name = 'Test Opp BNP';
			objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
			objOppty.CloseDate = System.today();
			objOppty.StageName = OpportunityUtil.SAL_STAGE;
			objOppty.Pricebook2Id = Test.getStandardPriceBookId();
			objOppty.HI_Effective_Date__c = System.today();
			insert objOppty;

			TriggerHandler.clearBypass('OpportunityTriggerHandler');

			Test.startTest();
			objOppty.Advisor_Assignment__c = 'Jira required';
			update objOppty;
			Test.stopTest();

			Opportunity objOpportunity = [SELECT Id, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOppty.Id];

			System.assertEquals(OpportunityUtil.MSG_UW_STATE_PY_IS_MISSING, objOpportunity.Advising_Assignment_Message__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Deepika Saini
	 * @description Test if Coverage Effective date is missing in Advising Assignment
	 **/
	@isTest
	static void testAdvisingAssignmentEffectiveDateMissing() {
		TriggerHandler.bypass('OpportunityTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		// Retrieve Company Account
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		System.runAs(objUser) {
			// Create Benefits Renewal Opportunity
			Opportunity objOppty = new Opportunity();
			objOppty.AccountId = objAccnt.Id;
			objOppty.Name = 'Test Opp BNP';
			objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
			objOppty.CloseDate = System.today();
			objOppty.StageName = OpportunityUtil.SAL_STAGE;
			objOppty.Pricebook2Id = Test.getStandardPriceBookId();
			objOppty.UW_State_PY__c = 'Arizona';
			insert objOppty;

			TriggerHandler.clearBypass('OpportunityTriggerHandler');

			Test.startTest();
			objOppty.Advisor_Assignment__c = 'Jira required';
			update objOppty;
			Test.stopTest();

			Opportunity objOpportunity = [SELECT Id, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOppty.Id];

			System.assertEquals(OpportunityUtil.MSG_COVERAGE_EFFECTIVE_DATE_IS_MISSING, objOpportunity.Advising_Assignment_Message__c);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Deepika Saini
	 * @description Test Assign advisor to Renewal Big Desk Opportunity
	 **/
	@isTest
	static void testAdvisingAssignmentBigDesk() {
		// Retrieve Company Account
		TriggerHandler.bypass('AccountTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objAccnt.Big_Desk_Sandbox_BenOps__c = true;
		update objAccnt;

		TriggerHandler.clearBypass('AccountTriggerHandler');

		Test.startTest();
		System.runAs(objUser) {
			// Create Benefits Renewal Opportunity
			Opportunity objOppty = new Opportunity();
			objOppty.AccountId = objAccnt.Id;
			objOppty.Name = 'Test Opp BNP';
			objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
			objOppty.CloseDate = System.today();
			objOppty.StageName = OpportunityUtil.SAL_STAGE;
			objOppty.Pricebook2Id = Test.getStandardPriceBookId();
			objOppty.UW_State_PY__c = 'Arizona';
			objOppty.HI_Effective_Date__c = System.today();
			objOppty.Big_Desk_BenOps__c = true;
			insert objOppty;
			Test.stopTest();

			Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOppty.Id];

			System.assertNotEquals(null, objOpportunity.Owner_Role_Name__c);
			System.assert(objOpportunity.Advising_Assignment_Message__c.contains(OpportunityUtil.MSG_BIGDESK_OPP_ASSIGNED_TO_NON_BIGDESK_USER));
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Offers Health Insurance update on Account
	 **/
	@isTest
	static void testOffersHealthInsuranceUpdate() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('123456789').build();
		insert objCompAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		insert objOpportunity;

		objOpportunity.Offers_Health_Insurance__c = 'Yes';

		Test.startTest();
		update objOpportunity;
		Test.stopTest();

		Account objAssertAccount = [SELECT Id, Name, Offers_Health_Insurance__c FROM Account WHERE Id = :objCompAccount.Id];
		//System.assertEquals(objAssertAccount.Offers_Health_Insurance__c, objOpportunity.Offers_Health_Insurance__c);
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Offers Health Insurance update on Account with blank value
	 **/
	@isTest
	static void testOffersHealthInsuranceNullUpdate() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('123456789').build();

		objCompAccount.Offers_Health_Insurance__c = 'No';
		insert objCompAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		objOpportunity.Offers_Health_Insurance__c = 'No';
		insert objOpportunity;

		objOpportunity.Offers_Health_Insurance__c = 'Yes';

		Test.startTest();
		update objOpportunity;
		Test.stopTest();

		Account objAssertAccount = [SELECT Id, Name, Offers_Health_Insurance__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertNotEquals('', objAssertAccount.Offers_Health_Insurance__c);
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test BYOB Opp creation when BOR Opp is Closed Lost and required critera are met
	 **/
	@isTest
	static void testBYOBClosedLostOpp() {
		TriggerHandler.bypass('AccountTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account BOR').setZPCompanyId('98989898989898').build();

			objAccount.Number_of_Active_Employees__c = 20;
			objAccount.BillingCountry = 'United States';
			objAccount.BillingState = 'California';
			insert objAccount;
			TriggerHandler.Bypass('OpportunityTriggerHandler');
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
				.setName('BOR Opp')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();
			insert objOpportunity;
			TriggerHandler.clearBypass('OpportunityTriggerHandler');

			Test.startTest();
			objOpportunity.stageName = OpportunityUtil.CLOSED_LOST_STAGE;
			objOpportunity.Stage_Detail__c = OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL;
			objOpportunity.Stage_Detail_2__c = OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL2;

			update objOpportunity;
			Test.stopTest();

			Opportunity objOppAssert = [
				SELECT Id, Name, RecordTypeId, StageName, Type, HI_Opportunity_Assignment_State__c, NumberOfEmployees__c, OwnerId, ZP_Company_ID__c, Source_ID__c, CloseDate
				FROM Opportunity
				WHERE ZP_Company_ID__c = :objAccount.ZP_Company_ID__c AND RecordTypeId = :OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID
			];
			Date dtToday = System.today();
			Integer intNumberOfDays = Date.daysInMonth(dtToday.year(), dtToday.month());
			Date dtLastDayOfMonth = Date.newInstance(dtToday.year(), dtToday.month(), intNumberOfDays);

			System.assertEquals(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID, objOppAssert.RecordTypeId);
			System.assertEquals('Raw', objOppAssert.StageName);
			System.assertEquals('Direct BYB', objOppAssert.Type);
			System.assertEquals(objAccount.BillingState, objOppAssert.HI_Opportunity_Assignment_State__c);
			System.assertEquals(objAccount.Number_of_Active_Employees__c, objOppAssert.NumberOfEmployees__c);
			System.assertEquals(objAccount.ZP_Company_ID__c, objOppAssert.ZP_Company_ID__c);
			System.assertEquals(dtLastDayOfMonth, objOppAssert.CloseDate);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test BYOB Opp should not get created if all defined criteria are not met
	 **/
	@isTest
	static void testBYOBClosedLostOpp2() {
		TriggerHandler.bypass('AccountTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account BOR').setZPCompanyId('98989898989899').build();

			objAccount.Number_of_Active_Employees__c = 20;
			objAccount.BillingCountry = 'United States';
			objAccount.BillingState = 'California';
			insert objAccount;
			TriggerHandler.Bypass('OpportunityTriggerHandler');
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
				.setName('BOR Opp')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();
			insert objOpportunity;
			TriggerHandler.clearBypass('OpportunityTriggerHandler');
			Test.startTest();
			objOpportunity.stageName = OpportunityUtil.CLOSED_LOST_STAGE;
			objOpportunity.Stage_Detail__c = OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL;
			objOpportunity.Stage_Detail_2__c = 'Other';

			update objOpportunity;
			Test.stopTest();

			List<Opportunity> list_OppAssert = [
				SELECT Id, Name, RecordTypeId, StageName, Type, HI_Opportunity_Assignment_State__c, NumberOfEmployees__c, OwnerId, ZP_Company_ID__c, Source_ID__c, CloseDate
				FROM Opportunity
				WHERE ZP_Company_ID__c = :objAccount.ZP_Company_ID__c AND RecordTypeId = :OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID
			];
			System.assertEquals(list_OppAssert.size(), 0);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test BYOB Opp Amount gets calculated on insert of Opportunity
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUpdateBYOBPricingOnInsert() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account BYOB').setZPCompanyId('98989898989888').build();
		objAccount.Number_of_Active_Employees__c = 20;
		insert objAccount;

		Date dtClose = Date.newInstance(2021, 8, 30);

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setName('BYOB Opp 1')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setTouchType('HI EBBP Creation')
			.setCloseDate(dtClose)
			.setType('Direct BoR')
			.build();
		objOpportunity.NumberOfEmployees__c = 45;

		Test.startTest();
		insert objOpportunity;
		Test.stopTest();

		List<Opportunity> list_OppAssert = [
			SELECT Id, Name, RecordTypeId, StageName, Type, NumberOfEmployees__c, Amount, ZP_Company_ID__c, Source_ID__c, CloseDate
			FROM Opportunity
			WHERE Id = :objOpportunity.Id
		];
		//Assert that on insert the Number of Employees will come from Account
		Date dtCloseDateToAssert = Date.today().addMonths(1).toStartofMonth().addDays(-1);
		System.assertEquals(20, list_OppAssert[0].NumberOfEmployees__c);
		System.assertEquals('BYOB Opp 1', list_OppAssert[0].Name);
		System.assertEquals('Open', list_OppAssert[0].StageName);
		System.assertEquals(dtCloseDateToAssert, list_OppAssert[0].CloseDate);
		System.assertEquals('Direct BoR', list_OppAssert[0].Type);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Bhagat Singh
	 * @description Test Opportunity Engaged Stage - Updated @21/02/2022 merged both positive & negative scenario
	 **/
	@isTest
	static void testOppEngagedStage() {
		TriggerHandler.bypass('AccountTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			Test.startTest();
			Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
			Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objAccnt.Id)
				.setName('Test Opp BNP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOppty.Pricebook2Id = Test.getStandardPriceBookId();
			insert objOppty;

			objOppty.Selecting_Offerings_Start__c = DateTime.now();
			update objOppty;

			Test.stopTest();

			System.assertEquals([SELECT Id, StageName FROM Opportunity WHERE Id = :objOppty.Id].StageName, 'Engaged');
			//Negative Scenario
			Opportunity objOppty1 = new TestDataFactory.OpportunityBuilder()
				.setAccountId(objAccnt.Id)
				.setName('Test Opp BNP')
				.setCloseDate(System.today())
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setStage('SAL')
				.build();
			objOppty1.Selecting_Offerings_Start__c = DateTime.now();
			objOppty.Pricebook2Id = Test.getStandardPriceBookId();
			insert objOppty1;

			objOppty1.StageName = 'Alternates Requested';
			update objOppty1;

			System.assertEquals([SELECT Id, StageName FROM Opportunity WHERE Id = :objOppty1.Id].StageName, 'Alternates Requested');
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test BYOB Opp creation
	 **/
	@isTest
	static void testBYOBOpportunintyInsert() {
		TriggerHandler.bypass('AccountTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account BYOB').setZPCompanyId('98989898989898').build();

			objAccount.Number_of_Active_Employees__c = 20;
			objAccount.BillingCountry = 'United States';
			objAccount.BillingState = 'California';
			insert objAccount;

			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
				.setName('BYOB Opp')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();

			Test.startTest();
			insert objOpportunity;
			Test.stopTest();

			Opportunity objOppAssert = [
				SELECT Id, Name, RecordTypeId, StageName, Type, HI_Opportunity_Assignment_State__c, NumberOfEmployees__c, OwnerId, ZP_Company_ID__c, Source_ID__c, CloseDate
				FROM Opportunity
				WHERE Id = :objOpportunity.Id
			];
			Date dtToday = System.today();
			Integer numberOfDays = Date.daysInMonth(dtToday.year(), dtToday.month());
			Date lastDayOfMonth = Date.newInstance(dtToday.year(), dtToday.month(), numberOfDays);

			System.assertEquals(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID, objOppAssert.RecordTypeId);
			System.assertEquals('Raw', objOppAssert.StageName);
			System.assertEquals('Direct BYB', objOppAssert.Type);
			System.assertEquals(objAccount.BillingState, objOppAssert.HI_Opportunity_Assignment_State__c);
			System.assertEquals(objAccount.Number_of_Active_Employees__c, objOppAssert.NumberOfEmployees__c);
			System.assertEquals(objAccount.ZP_Company_ID__c, objOppAssert.ZP_Company_ID__c);
			System.assert(objOppAssert.Source_ID__c.startsWith('BYB - ' + objAccount.ZP_Company_ID__c));
			System.assertEquals(lastDayOfMonth, objOppAssert.CloseDate);
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @Author        Deepika Saini
	 * @Description	  Test Create Recertification Ticket on Needs_Recertification__c = true
	 * @Parm          void
	 * @Return        void
	 **/
	@isTest
	static void testCreateRecertificationTickets() {
		List<Account> list_Accounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		for (Account objAcc : list_accounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = new Account(Id = objAcc.Id);
			}
		}

		Test.startTest();

		Group objGroupRT = new Group(Name = 'Recertification Team', type = 'Queue');
		insert objGroupRT;
		System.runAs(TestUserUtility.getRunningUser()) {
			QueuesObject objQueues = new QueueSObject(QueueID = objGroupRT.id, SobjectType = 'Ticket__c');
			insert objQueues;
		}

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunityBenefitsRenewal = new Opportunity();
		objOpportunityBenefitsRenewal.AccountId = objCompAccount.Id;
		objOpportunityBenefitsRenewal.Name = 'Test Opp BNP';
		objOpportunityBenefitsRenewal.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOpportunityBenefitsRenewal.Benefits_Current_Setup_Step__c = 'Completed';
		objOpportunityBenefitsRenewal.StageName = 'SAL';
		objOpportunityBenefitsRenewal.CloseDate = Date.today().addDays(10);
		insert objOpportunityBenefitsRenewal;
		OpportunityTriggerHelper.skipTrigger = false;

		objOpportunityBenefitsRenewal.Needs_Recertification__c = true;
		update objOpportunityBenefitsRenewal;

		Test.stopTest();

		List<Ticket__c> list_Tickets = [
			SELECT Id, Team__c, Escalation_Reason__c, Opportunity__c, OwnerId, Opportunity__r.Advising_Blocked_Reason__c
			FROM Ticket__c
			WHERE Opportunity__c = :objOpportunityBenefitsRenewal.Id
		];

		System.assert(list_Tickets.get(0).Opportunity__r.Advising_Blocked_Reason__c == OpportunityUtil.PENDING_RECERT);
		System.assert(list_Tickets.get(0).Team__c == TicketUtil.TICKET_TEAM_ADVISING);
		System.assert(list_Tickets.get(0).Escalation_Reason__c == TicketUtil.TICKET_REASON_RECERTIFICATION);
		System.assert(list_Tickets.get(0).OwnerId == objGroupRT.Id);
	}

	/**
	 * @Author		SandeepGolla
	 * @description	Test if no exceptions are logged
	 * @Parm		void
	 * @Return		void
	 **/
	public static void checkForExceptions() {
		// Assert no exceptions are logged from Opportunity Trigger
		List<Exception_Log__c> list_Exceptions = [SELECT Id, Line_Number__c, Message__c, Method_Name__c FROM Exception_Log__c WHERE Class_Name__c = 'OpportunityTriggerHandler'];
		//System.assertEquals(0, list_Exceptions.size());
	}

	/** @author        Deepika Saini
	 * @description	  Test Bigdesk Assignment functionality Skip_Assigning_Advising__c = false
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testSkipBigDeskAssignmentNegative() {
		TriggerHandler.bypass('AccountTriggerHandler');

		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objAccnt.Big_Desk_Sandbox_BenOps__c = true;
		update objAccnt;

		TriggerHandler.clearBypass('AccountTriggerHandler');
		Configuration_Settings__c objConfigSetting = [SELECT Skip_BigDesk_Assignment__c FROM Configuration_Settings__c LIMIT 1];
		objConfigSetting.Skip_BigDesk_Assignment__c = false;
		update objConfigSetting;
		Test.startTest();

		// Create Benefits Renewal Opportunity
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		objOppty.UW_State_PY__c = 'Arizona';
		objOppty.HI_Effective_Date__c = System.today();
		objOppty.Big_Desk_BenOps__c = true;
		insert objOppty;
		Test.stopTest();

		Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOppty.Id];
		System.assertNotEquals(null, objOpportunity.Owner_Role_Name__c);
		System.assert(objOpportunity.Advising_Assignment_Message__c.contains(OpportunityUtil.MSG_BIGDESK_OPP_ASSIGNED_TO_NON_BIGDESK_USER));
	}

	/**
	 * @author        Deepika Saini
	 * @description	  Test Assign advisor functionality Skip_Assigning_Advising__c = TRUE
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testSkipBigDeskAssignmentPositive() {
		TriggerHandler.bypass('AccountTriggerHandler');

		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objAccnt.Big_Desk_Sandbox_BenOps__c = true;
		update objAccnt;

		TriggerHandler.clearBypass('AccountTriggerHandler');
		Configuration_Settings__c objConfigSetting = [SELECT Skip_BigDesk_Assignment__c FROM Configuration_Settings__c LIMIT 1];
		objConfigSetting.Skip_BigDesk_Assignment__c = true;
		update objConfigSetting;
		Test.startTest();

		// Create Benefits Renewal Opportunity
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		objOppty.UW_State_PY__c = 'Arizona';
		objOppty.HI_Effective_Date__c = System.today();
		objOppty.Big_Desk_BenOps__c = true;
		insert objOppty;
		Test.stopTest();

		Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOppty.Id];
		System.assert(String.isEmpty(objOpportunity.Owner_Role_Name__c));
		System.assert(String.isEmpty(objOpportunity.Advising_Assignment_Message__c));
	}

	/**
	 * @description Setting up test data for creating pricebook and pricebook entries
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public static void setUpNewPrices(String strPriceName, Boolean blnPrioritySupport) {
		// Start setting up data and create pricebook and pricebook entries
		// Create a new pricebook
		Pricebook2 objPriceBookOne = new TestDataFactory.PriceBookBuilder().setName(strPriceName).setActive().build();
		objPriceBookOne.Product_Tier__c = 'Plus';
		insert objPriceBookOne;

		// Create new products
		List<Product2> list_Products = new List<Product2>();
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Company').setFamily('Company').setProductType(OpportunityUtil.PRODUCT_TYPE_MONTHLY).setProductCategory('Payroll').build());
		list_Products.add(
			new TestDataFactory.ProductBuilder().setName('Active Employee').setFamily('Payroll').setProductType(OpportunityUtil.PRODUCT_TYPE_EMPLOYEES).setProductCategory('Payroll').build()
		);
		list_Products.add(
			new TestDataFactory.ProductBuilder().setName('Contractor').setFamily('Payroll').setProductType(OpportunityUtil.PRODUCT_TYPE_CONTRACTORS).setProductCategory('Payroll').build()
		);
		if (blnPrioritySupport) {
			list_Products.add(
				new TestDataFactory.ProductBuilder()
					.setName(OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE)
					.setFamily('Payroll')
					.setProductType(OpportunityUtil.PRODUCT_TYPE_EMPLOYEES)
					.setProductCategory(OpportunityUtil.PRIORITY_SUPPORT)
					.build()
			);
			list_Products.add(
				new TestDataFactory.ProductBuilder()
					.setName(OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR)
					.setFamily('Payroll')
					.setProductType(OpportunityUtil.PRODUCT_TYPE_CONTRACTORS)
					.setProductCategory(OpportunityUtil.PRIORITY_SUPPORT)
					.build()
			);
			list_Products.add(
				new TestDataFactory.ProductBuilder()
					.setName(OpportunityUtil.INTERNATIONAL_CONTRACTOR_ADD_ON_PRODUCT)
					.setFamily('Payroll')
					.setProductType(OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_CONTRACTORS)
					.setProductCategory(OpportunityUtil.PRIORITY_SUPPORT)
					.build()
			);
		}
		insert list_Products;

		// Create pricebook entries
		List<PricebookEntry> list_Entries = new List<PricebookEntry>();
		// create standard pricebook entries before creating custom ones
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, Test.getStandardPriceBookId(), false));
		if (blnPrioritySupport) {
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, 5, Test.getStandardPriceBookId(), false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[4].Id, 5, Test.getStandardPriceBookId(), false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[5].Id, 5, Test.getStandardPriceBookId(), false));
		}

		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objPriceBookOne.id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, objPriceBookOne.id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, objPriceBookOne.id, false));
		if (blnPrioritySupport) {
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, 5, objPriceBookOne.id, false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[4].Id, 5, objPriceBookOne.id, false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[5].Id, 5, objPriceBookOne.id, false));
		}

		insert list_Entries;
	}

	/**
	 * @description To test if opportunity is inserted with priority support, corresponding line items should be inserted
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	/**@isTest
	static void testPrioritySupportForPlusTierOnInsert() {
		AccountTriggerHelper.skipTrigger = true;

		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		// Create new products, pricebooks and pricebook entries for Plus Tier
		setUpNewPrices(objTierConfig.New_Price_2__c, true);

		// Create company and set custom pricing
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing(objTierConfig.New_Price_2__c)
			.setAdditionalServices(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)
			.build();
		insert objAccount;

		// insert a company opportunity with more than one employee and contractor and set priority add on support to true
		Test.startTest();
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.build();
		insert objOpportunity;
		Test.stopTest();

		Integer intCountLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id];
		// Assert four line items got created
		System.assertEquals(5, intCountLineItems);
		// Assert company line item got created
		System.assertEquals(1, [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.COMPANY_PROD].Quantity);
		// Assert active employee line item got created
		System.assertEquals(
			objOpportunity.NumberOfEmployees__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.ACTIVE_EMPLOYEE_PROD]
			.Quantity
		);
		// Assert active employee line item got created
		System.assertEquals(
			objOpportunity.Number_of_Contractors__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.CONTRACTOR_PROD]
			.Quantity
		);
		// Assert priority support line item got created
		System.assertEquals(
			objOpportunity.NumberOfEmployees__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE]
			.Quantity
		);

		System.assertEquals(
			objOpportunity.Number_of_Contractors__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR]
			.Quantity
		);
	} **/

	/**
	 * @description Test if number of employees is updated on company opportunity with priority support, corresponding line items should be updated
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	/**@isTest
	static void testPrioritySupportEmployeeChange() {
		AccountTriggerHelper.skipTrigger = true;

		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		// Create new products, pricebooks and pricebook entries for Plus Tier
		setUpNewPrices(objTierConfig.New_Price_2__c, true);

		// Create company and set custom pricing
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing(objTierConfig.New_Price_2__c)
			.build();
		insert objAccount;

		// insert a company opportunity with more than one employee and contractor and set priority add on support to true
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.setAdditionalServices(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)
			.build();
		insert objOpportunity;
		// assume opportunity already has line items
		List<OpportunityLineItem> list_LineItemsToInsert = new List<OpportunityLineItem>();
		for (PricebookEntry objPBE : [SELECT Id, Product2.Name, UnitPrice FROM PricebookEntry WHERE Pricebook2.Name = :objAccount.Pricing__c]) {
			list_LineItemsToInsert.add(new OpportunityLineItem(OpportunityId = objOpportunity.Id, PriceBookEntryId = objPBE.Id, UnitPrice = objPBE.UnitPrice, Quantity = 1));
		}
		insert list_LineItemsToInsert;
		OpportunityTriggerHelper.skipTrigger = false;

		// update number of employees on opportunity
		Opportunity objUpdateOppty = new Opportunity(Id = objOpportunity.Id);
		objUpdateOppty.NumberOfEmployees__c = 20;
		objUpdateOppty.Number_of_Contractors__c = 20;
		update objUpdateOppty;
		Test.stopTest();

		Integer intCountLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id];
		// Assert four line items got created
		System.assertEquals(5, intCountLineItems);
		// Assert company line item got created
		System.assertEquals(1, [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.COMPANY_PROD].Quantity);
		// Assert active employee line item got updated
		System.assertEquals(
			objUpdateOppty.NumberOfEmployees__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.ACTIVE_EMPLOYEE_PROD]
			.Quantity
		);
		// Assert contractor line item got updated
		System.assertEquals(
			objUpdateOppty.Number_of_Contractors__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.CONTRACTOR_PROD]
			.Quantity
		);
		// Assert priority support line item got updated
		System.assertEquals(
			objUpdateOppty.NumberOfEmployees__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE]
			.Quantity
		);

		System.assertEquals(
			objUpdateOppty.Number_of_Contractors__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR]
			.Quantity
		);
	} **/

	/**
	 * @description Test if priority support flag is updated to false, corresponding opportunity line item is deleted.
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	/**@isTest
	static void testPrioritySupportFlagReset() {
		AccountTriggerHelper.skipTrigger = true;

		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		// Create new products, pricebooks and pricebook entries for Plus Tier
		setUpNewPrices(objTierConfig.New_Price_2__c, true);

		// Create company and set custom pricing
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing(objTierConfig.New_Price_2__c)
			.build();
		insert objAccount;

		// insert a company opportunity with more than one employee and contractor and set priority add on support to true
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.setAdditionalServices(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)
			.build();
		insert objOpportunity;
		// assume opportunity already has line items
		List<OpportunityLineItem> list_LineItemsToInsert = new List<OpportunityLineItem>();
		for (PricebookEntry objPBE : [SELECT Id, Product2.Name, UnitPrice FROM PricebookEntry WHERE Pricebook2.Name = :objAccount.Pricing__c]) {
			list_LineItemsToInsert.add(new OpportunityLineItem(OpportunityId = objOpportunity.Id, PriceBookEntryId = objPBE.Id, UnitPrice = objPBE.UnitPrice, Quantity = 1));
		}
		insert list_LineItemsToInsert;
		OpportunityTriggerHelper.skipTrigger = false;

		// update number of employees on opportunity
		Opportunity objUpdateOppty = new Opportunity(Id = objOpportunity.Id);
		objUpdateOppty.NumberOfEmployees__c = 20;
		objUpdateOppty.Number_of_Contractors__c = 20;
		objUpdateOppty.Additional_Opportunity_Services__c = '';
		update objUpdateOppty;
		Test.stopTest();

		Integer intCountLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id];
		// Assert three line items got created
		System.assertEquals(3, intCountLineItems);
		// Assert company line item got created
		System.assertEquals(1, [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.COMPANY_PROD].Quantity);
		// Assert active employee line item got updated
		System.assertEquals(
			objUpdateOppty.NumberOfEmployees__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.ACTIVE_EMPLOYEE_PROD]
			.Quantity
		);
		// Assert contractor line item got updated
		System.assertEquals(
			objUpdateOppty.Number_of_Contractors__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.CONTRACTOR_PROD]
			.Quantity
		);
		// Assert priority support line item got deleted
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE]);
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR]);
	}**/

	/**
	 * @description Test if number of employees and contractors are updated to 0, all line items except company are deleted
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	/**@isTest
	static void testPrioritySupportFlagEmployeeReset() {
		AccountTriggerHelper.skipTrigger = true;

		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		// Create new products, pricebooks and pricebook entries for Plus Tier
		setUpNewPrices(objTierConfig.New_Price_2__c, true);

		// Create company and set custom pricing
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing(objTierConfig.New_Price_2__c)
			.build();
		insert objAccount;

		// insert a company opportunity with more than one employee and contractor and set priority add on support to true
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.setAdditionalServices(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)
			.build();
		insert objOpportunity;
		// assume opportunity already has line items
		List<OpportunityLineItem> list_LineItemsToInsert = new List<OpportunityLineItem>();
		for (PricebookEntry objPBE : [SELECT Id, Product2.Name, UnitPrice FROM PricebookEntry WHERE Pricebook2.Name = :objAccount.Pricing__c]) {
			list_LineItemsToInsert.add(new OpportunityLineItem(OpportunityId = objOpportunity.Id, PriceBookEntryId = objPBE.Id, UnitPrice = objPBE.UnitPrice, Quantity = 1));
		}
		insert list_LineItemsToInsert;
		OpportunityTriggerHelper.skipTrigger = false;

		// update number of employees on opportunity to zero
		Opportunity objUpdateOppty = new Opportunity(Id = objOpportunity.Id);
		objUpdateOppty.NumberOfEmployees__c = 0;
		objUpdateOppty.Number_of_Contractors__c = 0;
		update objUpdateOppty;
		Test.stopTest();

		Integer intCountLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id];
		// Assert only one line item is available
		System.assertEquals(1, intCountLineItems);
		// Assert company line item got created
		System.assertEquals(1, [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.COMPANY_PROD].Quantity);
		// Assert active employee line item got deleted
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.ACTIVE_EMPLOYEE_PROD]);
		// Assert contractor line item got deleted
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.CONTRACTOR_PROD]);
		// Assert priority support line item got deleted
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE]);
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR]);
	}**/

	/**
	 * @description Test if Payment Plan and Add-on Line items were created when Payment Invoice is attached on Opportunity
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testPricingChangeBasedOnPaymentInvoice() {
		Map<String, String> map_AddServicesApiToLabel = new Map<String, String>();
		for (Schema.PicklistEntry objPicklistEntry : Payment_Invoice__c.Additional_Invoiced_Services__c.getDescribe().getPicklistValues()) {
			map_AddServicesApiToLabel.put(objPicklistEntry.getLabel(), objPicklistEntry.getValue());
		}

		// Assume Company Opportunity is on a Simple Plan
		// Attach a Payment Invoice that is on Plus Tier with Add-on
		// Expect Payment Plan on Company Opportunity to be changed and add-on line items getting created.
		TriggerHandler.bypass('AccountTriggerHandler');

		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c);

		// Create new products, pricebooks and pricebook entries for Plus Tier
		setUpNewPrices(objTierConfig.New_Price_2__c, true);
		setUpNewPrices(objTierConfig.New_Price_1__c, true);

		// Create company and set custom pricing
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.setAdditionalServices(map_AddServicesApiToLabel.get(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT))
			.build();
		insert objOpportunity;

		Payment_Invoice__c objPaymentInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setAmount(100)
			.setName('INV-123')
			.setEmployeeCount(25)
			.setContractorCount(25)
			.setPricing(objTierConfig.New_Price_2__c)
			.setPaymentPlan(objTierConfig.New_Tier_2__c)
			.setPrioritySupport(true)
			.setAdditionalServices(map_AddServicesApiToLabel.get(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT))
			.build();
		insert objPaymentInvoice;

		Test.startTest();
		objOpportunity.Payment_Invoice__c = objPaymentInvoice.Id;
		update objOpportunity;
		Test.stopTest();

		Integer intCountLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id];
		// Assert four line items got created
		/**System.assertEquals(5, intCountLineItems);
		// Assert company line item got created
		System.assertEquals(1, [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.COMPANY_PROD].Quantity);
		// Assert active employee line item got updated
		System.assertEquals(
			objPaymentInvoice.Employee_Count__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.ACTIVE_EMPLOYEE_PROD]
			.Quantity
		);
		// Assert contractor line item got updated
		System.assertEquals(
			objPaymentInvoice.Contractor_Count__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.CONTRACTOR_PROD]
			.Quantity
		);
		// Assert priority support line item got updated
		System.assertEquals(
			objPaymentInvoice.Employee_Count__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE]
			.Quantity
		);
		System.assertEquals(
			objPaymentInvoice.Contractor_Count__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR]
			.Quantity
		);**/
	}

	/**
	 * @description Test if Payment Invoice (without add-on) is updated Company Opportunity with add-on, additional line item must be removed
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	/**@isTest
	static void testPlusTierAddOnUpdateByPaymentInvoice() {
		AccountTriggerHelper.skipTrigger = true;

		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		// Create new products, pricebooks and pricebook entries for Plus Tier
		setUpNewPrices(objTierConfig.New_Price_2__c, true);

		// Create company and set custom pricing
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing(objTierConfig.New_Price_2__c)
			.setAdditionalServices(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)
			.build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.build();
		insert objOpportunity;

		Opportunity objOpptyAssert = [SELECT Id, Pricebook2.Name FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(objOpptyAssert.Pricebook2.Name, objTierConfig.New_Price_2__c);

		Payment_Invoice__c objPaymentInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setAmount(100)
			.setName('INV-123')
			.setEmployeeCount(25)
			.setContractorCount(25)
			.setPricing(objTierConfig.New_Price_2__c)
			.setPaymentPlan(objTierConfig.New_Tier_2__c)
			.build();
		insert objPaymentInvoice;

		Test.startTest();
		objOpptyAssert.Payment_Invoice__c = objPaymentInvoice.Id;
		update objOpptyAssert;
		Test.stopTest();

		Integer intCountLineItems = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id];
		// Assert four line items got created
		System.assertEquals(3, intCountLineItems);
		// Assert company line item got created
		System.assertEquals(1, [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.COMPANY_PROD].Quantity);
		// Assert active employee line item got updated
		System.assertEquals(
			objPaymentInvoice.Employee_Count__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.ACTIVE_EMPLOYEE_PROD]
			.Quantity
		);
		// Assert contractor line item got updated
		System.assertEquals(
			objPaymentInvoice.Contractor_Count__c,
			[SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.CONTRACTOR_PROD]
			.Quantity
		);
		// Assert priority support line item got deleted
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE]);
		System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id AND Product2.Name = :OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR]);
	}**/

	/**
	 * @author        Deepika Saini
	 * @description	  Test Assign advisor functionality Skip_Assigning_Advising__c = TRUE
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testSkipBigDeskAssignmentPos() {
		TriggerHandler.bypass('AccountTriggerHandler');

		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objAccnt.Big_Desk_Sandbox_BenOps__c = true;
		update objAccnt;

		TriggerHandler.clearBypass('AccountTriggerHandler');
		Configuration_Settings__c objConfigSetting = [SELECT Skip_BigDesk_Assignment__c FROM Configuration_Settings__c LIMIT 1];
		objConfigSetting.Skip_BigDesk_Assignment__c = true;
		update objConfigSetting;
		Test.startTest();

		// Create Benefits Renewal Opportunity
		Opportunity objOPP = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('Test Opp BNP')
			.setAccountId(objAccnt.Id)
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.setHIEffectiveDate(System.today())
			.setPriceBookId(Test.getStandardPriceBookId())
			.build();
		objOPP.UW_State_PY__c = 'Arizona';
		objOPP.Big_Desk_BenOps__c = true;

		OpportunityTriggerHelper.skipTrigger = true;
		insert objOPP;
		OpportunityTriggerHelper.skipTrigger = false;

		Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c, Advisor_Assignment__c FROM Opportunity WHERE Id = :objOPP.Id];
		objOpportunity.Advisor_Assignment__c = 'Escalated ER';
		update objOpportunity;
		Test.stopTest();

		Opportunity objOpportunity1 = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assert(String.isNotBlank(objOpportunity1.Owner_Role_Name__c));
		System.assert(String.isNotBlank(objOpportunity1.Advising_Assignment_Message__c));
	}

	/**
	 * @author        Deepika Saini
	 * @description	  Test Assign advisor functionality Skip_Assigning_Advising__c = TRUE
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testSkipBigDeskAssignment() {
		TriggerHandler.bypass('AccountTriggerHandler');

		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objAccnt.Big_Desk_Sandbox_BenOps__c = true;
		update objAccnt;

		TriggerHandler.clearBypass('AccountTriggerHandler');
		Configuration_Settings__c objConfigSetting = [SELECT Skip_BigDesk_Assignment__c FROM Configuration_Settings__c LIMIT 1];
		objConfigSetting.Skip_BigDesk_Assignment__c = true;
		update objConfigSetting;
		Test.startTest();

		// Create Benefits Renewal Opportunity
		Opportunity objOPP = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('Test Opp BNP')
			.setAccountId(objAccnt.Id)
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.setHIEffectiveDate(System.today())
			.setPriceBookId(Test.getStandardPriceBookId())
			.build();
		objOPP.UW_State_PY__c = 'Arizona';
		objOPP.Big_Desk_BenOps__c = true;

		OpportunityTriggerHelper.skipTrigger = true;
		insert objOPP;
		OpportunityTriggerHelper.skipTrigger = false;

		Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c, Advisor_Assignment__c FROM Opportunity WHERE Id = :objOPP.Id];
		objOpportunity.Advisor_Assignment__c = 'Big Desk (25+ EEs)';
		update objOpportunity;
		Test.stopTest();

		Opportunity objOpportunity1 = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assert(String.isEmpty(objOpportunity1.Owner_Role_Name__c));
		System.assert(String.isEmpty(objOpportunity1.Advising_Assignment_Message__c));
	}

	/**
	 * @author      Lalitha Kasturi
	 * @description Test sandler picklist with respective to stage mapping
	 **/
	/**@isTest
	static void testUpdateSandlerBusinessProcess() {
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account1').setZPCompanyId('1111111111').build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		objOpportunity.ZP_Company_ID__c = '1111111111';

		insert objOpportunity;

		Test.startTest();
		objOpportunity.StageName = OpportunityUtil.QUALIFIED_STAGE;
		update objOpportunity;
		Test.stopTest();

		Opportunity objOppUpdated = [SELECT Id, Sandler_Business_Process__c, StageName FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(objOppUpdated.Sandler_Business_Process__c, 'Pain Step');
	} **/

	/**
	 * @author        Deepika Saini
	 * @description	  Test population of Advisor Assignment Timestamp
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testAdvisorAssignmentTimestamp() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objAccnt.Big_Desk_Sandbox_BenOps__c = true;
		update objAccnt;

		TriggerHandler.clearBypass('AccountTriggerHandler');
		Test.startTest();

		// Create Benefits Renewal Opportunity
		Opportunity objOPP = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('Test Opp BNP')
			.setAccountId(objAccnt.Id)
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.setHIEffectiveDate(System.today())
			.setPriceBookId(Test.getStandardPriceBookId())
			.build();
		objOPP.UW_State_PY__c = 'Arizona';
		objOPP.Big_Desk_BenOps__c = true;

		OpportunityTriggerHelper.skipTrigger = true;
		insert objOPP;
		OpportunityTriggerHelper.skipTrigger = false;

		Opportunity objOpportunity = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c, Advisor_Assignment__c FROM Opportunity WHERE Id = :objOPP.Id];
		objOpportunity.Advisor_Assignment__c = 'Escalated ER';
		update objOpportunity;
		Test.stopTest();

		Opportunity objOpportunity1 = [SELECT Id, Owner_Role_Name__c, Advising_Assignment_Message__c, Dedicated_Advisor_Assignment_Timestamp__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assert(String.isNotBlank(objOpportunity1.Owner_Role_Name__c));
		System.assert(String.isNotBlank(objOpportunity1.Advising_Assignment_Message__c));
		System.assert(objOpportunity1.Dedicated_Advisor_Assignment_Timestamp__c != null);
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Test BYOB Oppty Stage not defaulting to Raw for Workato Integration User
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testBYOBOpptyStageInsertWorkatoUser() {
		User objWorkatoIntUser = [SELECT Id, Username FROM User WHERE UserName LIKE 'workato.integration@gusto.com%' LIMIT 1];

		TriggerHandler.bypass('AccountTriggerHandler');
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account BYOB').setZPCompanyId('98989898989888').build();
		objAccount.Number_of_Active_Employees__c = 20;
		insert objAccount;

		Date dtClose = Date.newInstance(2022, 10, 30);
		System.runAs(objWorkatoIntUser) {
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
				.setName('BYOB Opp Swati Test')
				.setAccountId(objAccount.Id)
				.setStage('ER Confirm')
				.setCloseDate(dtClose)
				.setType('Direct BYB')
				.build();

			Test.startTest();
			insert objOpportunity;
			Test.stopTest();

			List<Opportunity> list_OppAssert = [
				SELECT Id, Name, RecordTypeId, StageName, Type, NumberOfEmployees__c, Amount, ZP_Company_ID__c, Source_ID__c, CloseDate
				FROM Opportunity
				WHERE Id = :objOpportunity.Id
			];

			System.assertEquals('ER Confirm', list_OppAssert[0].StageName);
			// Finally check if there are any exceptions logged
			checkForExceptions();
		}
	}

	/**
	 * @Author      : Prity Kumari
	 * @Description : Test Cross-Sell and Upsell Opportunity creation
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testTierUpsellOppCreation() {
		// Setup pricebooks and pricebook entries
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		setUpNewPrices(objTierConfig.New_Price_1__c, true);
		setUpNewPrices(objTierConfig.New_Price_2__c, true);
		Account objAccount = [
			SELECT Id, Number_of_Active_Contractors__c, Number_of_Active_Employees__c, Current_MRR__c, Discount__c, Pricing__c, Tier__c
			FROM Account
			WHERE ZP_Company_Id__c = '4561111111'
		];
		objAccount.Tier__c = AccountUtil.SIMPLE_TIER;
		objAccount.Pricing__c = AccountUtil.SIMPLE_PAYMENT_PLAN;
		objAccount.Number_of_Active_Contractors__c = 1;
		objAccount.Number_of_Active_Employees__c = 1;
		objAccount.First_Month_Invoice_Generated__c = true;
		update objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('APD Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.PLUS_TIER)
			.setType('Upsell')
			.build();
		objOpportunity.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		objOpportunity.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);
		Test.startTest();
		insert objOpportunity;
		Account objAssertAccount = [
			SELECT Id, Number_of_Active_Contractors__c, Number_of_Active_Employees__c, Current_MRR__c, Discount__c, Pricing__c, Tier__c
			FROM Account
			WHERE ZP_Company_Id__c = '4561111111'
		];

		Opportunity objAssertOpportunity = [
			SELECT Id, Name, RecordTypeId, StageName, Type, NumberOfEmployees__c, Number_of_Contractors__c, Amount, ZP_Company_ID__c, Source_ID__c, CloseDate, MRR__c, Discount__c, Pricebook2Id
			FROM Opportunity
			WHERE Id = :objOpportunity.Id
		];
		System.assertEquals('New', objAssertOpportunity.StageName, 'Stage name will be New for Cross-Sell and Upsell.');
		System.assertEquals('Upsell', objAssertOpportunity.Type);
		System.assertEquals(objAssertAccount.Number_of_Active_Employees__c, objAssertOpportunity.NumberOfEmployees__c);
		System.assertEquals(objAssertAccount.Number_of_Active_Contractors__c, objAssertOpportunity.Number_of_Contractors__c);
		System.assertEquals(objAssertAccount.Current_MRR__c, objAssertOpportunity.MRR__c);
		System.assertEquals(Date.today().addDays(45), objAssertOpportunity.CloseDate);
		// Finally check if there are any exceptions logged
		//checkForExceptions();
		// Create Cross-Sell and Upsell Payment Invoice
		PaymentInvoiceTriggerHandler.blnSkipTrigger = true;
		Payment_Invoice__c objPaymentInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setAccountId(objAssertAccount.Id)
			.setAmount(100)
			.setName('PayInv-123')
			.setEmployeeCount(10)
			.setContractorCount(0)
			.build();
		objPaymentInvoice.Payment_Plan__c = 'Plus';
		objPaymentInvoice.Pricing__c = '$80 Base, $12: 1+';
		objPaymentInvoice.Paid__c = true;
		objPaymentInvoice.Employee_Count__c = 10;
		objPaymentInvoice.Contractor_Count__c = 10;
		objPaymentInvoice.Additional_Invoiced_Services__c = 'PRP-00000083;';
		insert objPaymentInvoice;

		objOpportunity.StageName = 'SAL';
		objOpportunity.Payment_Invoice__c = objPaymentInvoice.Id;
		update objOpportunity;

		Test.stopTest();

		Opportunity objOpp = [SELECT Id, Amount, MRR__c, NumberOfEmployees__c, Number_of_Contractors__c, Upsell_Tier__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		Decimal decSalesPrice = OpportunityUtil.calculateMRROppNew(
			objPaymentInvoice.Employee_Count__c,
			objPaymentInvoice.Contractor_Count__c,
			0,
			0,
			objPaymentInvoice.Additional_Invoiced_Services__c,
			objPaymentInvoice.Discount__c,
			0,
			objPaymentInvoice.Pricing__c
		);
		// Assert data on Cross-Sell and Upsell opportunity matches with Invoice
		System.assertEquals(objPaymentInvoice.Employee_Count__c, objOpp.NumberOfEmployees__c, 'Number of Employees on Opportunity does not match with Invoice');
		System.assertEquals(objPaymentInvoice.Contractor_Count__c, objOpp.Number_of_Contractors__c, 'Number of Contractors on Opportunity does not match with Invoice');
		System.assertEquals('Plus with Priority Support', objOpp.Upsell_Tier__c, 'Upsell tier is not updated from Invoice');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test changing of upsell tier to trigger recalculation of amount and updating additional opportunity services
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testChangeOfUpsellTier() {
		// Setup pricebooks and pricebook entries
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		setUpNewPrices(objTierConfig.New_Price_1__c, true);
		setUpNewPrices(objTierConfig.New_Price_2__c, true);
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = [
			SELECT Id, Number_of_Active_Contractors__c, Number_of_Active_Employees__c, Current_MRR__c, Discount__c, Pricing__c, Tier__c
			FROM Account
			WHERE ZP_Company_Id__c = '4561111111'
		];
		objAccount.Tier__c = AccountUtil.SIMPLE_TIER;
		objAccount.Pricing__c = AccountUtil.SIMPLE_PAYMENT_PLAN;
		objAccount.Number_of_Active_Contractors__c = 1;
		objAccount.Number_of_Active_Employees__c = 1;
		objAccount.First_Month_Invoice_Generated__c = true;
		update objAccount;

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('APD Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.PLUS_TIER)
			.setType('Upsell')
			.build();
		objOpportunity.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		objOpportunity.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);
		objOpportunity.StageName = 'New';
		insert objOpportunity;
		OpportunityTriggerHelper.skipTrigger = false;

		Test.startTest();
		// Change the upsell tier
		objOpportunity.Upsell_Tier__c = 'Plus with Priority Support';
		update objOpportunity;
		Test.stopTest();
	}

	/**
	 * @description Test if calculate reseller metrics is set on account during opportunity insert
	 * @author      Praveen Sethu
	 **/
	@isTest
	private static void testOpenOpptyMetricsOnInsert() {
		AccountTriggerHelper.skipTrigger = true;

		// Insert reseller account and company account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account').build();

		insert new List<Account>{ objCompanyAccount, objResellerAccount };

		Test.startTest();

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Company Account - Payroll')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.setSoldBy(objResellerAccount.Id)
			.build();
		objOppty.Referred_By__c = objResellerAccount.Id;
		insert objOppty;

		Account objResellerAccountAssert = [SELECT Id, Calculate_Reseller_Metrics__c FROM Account WHERE Id = :objResellerAccount.Id];
		//System.assertEquals(true, objResellerAccountAssert.Calculate_Reseller_Metrics__c);

		Test.stopTest();
	}

	/**
	 * @description Test if calculate reseller metrics is set on account during opportunity update
	 * @author      Praveen Sethu
	 **/
	@isTest
	private static void testClosedOpptyMetricsOnUpdate() {
		AccountTriggerHelper.skipTrigger = true;

		// Insert reseller account and company account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account').build();

		insert new List<Account>{ objCompanyAccount, objResellerAccount };

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Company Account - Payroll')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		Test.startTest();

		// move opportunity to closed won
		objOppty.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		objOppty.Sold_By__c = objResellerAccount.Id;
		objOppty.Referred_By__c = objResellerAccount.Id;
		update objOppty;

		Test.stopTest();

		Account objResellerAccountAssert = [SELECT Id, Calculate_Reseller_Metrics__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(true, objResellerAccountAssert.Calculate_Reseller_Metrics__c);
	}

	/**
	 * @description Test Payment Invoice with multiple add-ons is updated on Payroll Opportunity
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testInvoiceWithMultipleAddOns() {
		Map<String, String> map_AddServicesApiToLabel = new Map<String, String>();
		for (Schema.PicklistEntry objPicklistEntry : Payment_Invoice__c.Additional_Invoiced_Services__c.getDescribe().getPicklistValues()) {
			map_AddServicesApiToLabel.put(objPicklistEntry.getLabel(), objPicklistEntry.getValue());
		}

		AccountTriggerHelper.skipTrigger = true;

		// Get org default tier config settings and assert new price 2 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_2__c);

		// Create new products, pricebooks and pricebook entries for Plus Tier
		setUpNewPrices(objTierConfig.New_Price_2__c, true);

		// Create company and set custom pricing & include both add-ons
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing(objTierConfig.New_Price_2__c)
			.setAdditionalServices(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT + ';' + OpportunityUtil.ADD_SERVICES_INTERNATIONAL_CONTRACTOR)
			.build();
		insert objAccount;

		// create a payroll opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.build();
		insert objOpportunity;

		// create a payment invoice and link it to company account & include multiple add-ons
		Payment_Invoice__c objPaymentInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setAccountId(objAccount.Id)
			.setAmount(100)
			.setName('INV-123')
			.setEmployeeCount(12)
			.setContractorCount(12)
			.setPrioritySupport(true)
			.setAdditionalServices(
				map_AddServicesApiToLabel.get(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT) +
				';' +
				map_AddServicesApiToLabel.get(OpportunityUtil.ADD_SERVICES_INTERNATIONAL_CONTRACTOR)
			)
			.setInternationalContractors(20)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setPricing(objTierConfig.New_Price_2__c)
			.build();
		insert objPaymentInvoice;

		Test.startTest();
		// update invoice on opportunity - this will kick off future call which will take care of opportunity recon
		objOpportunity.Payment_Invoice__c = objPaymentInvoice.Id;
		update objOpportunity;
		Test.stopTest();

		Integer intCountLineItems = 0;
		Map<String, OpportunityLineItem> map_ProductToLineItems = new Map<String, OpportunityLineItem>();

		for (OpportunityLineItem objLineItem : [SELECT Id, Product2.Name, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOpportunity.Id]) {
			map_ProductToLineItems.put(objLineItem.Product2.Name, objLineItem);
			intCountLineItems = intCountLineItems + 1;
		}

		// Assert 6 line items got created (1 for company, 1 for employee, 1 for contractor, 2 for priority support and 1 for international contracotr)
		/**System.assertEquals(6, intCountLineItems);

		// Assert company line item got created
		System.assertEquals(true, map_ProductToLineItems.containsKey(OpportunityUtil.COMPANY_PROD));
		System.assertEquals(1, map_ProductToLineItems.get(OpportunityUtil.COMPANY_PROD).Quantity);

		// Assert active employee line item got created
		System.assertEquals(true, map_ProductToLineItems.containsKey(OpportunityUtil.ACTIVE_EMPLOYEE_PROD));
		System.assertEquals(objOpportunity.NumberOfEmployees__c, map_ProductToLineItems.get(OpportunityUtil.ACTIVE_EMPLOYEE_PROD).Quantity);

		// Assert contractor line item got created
		System.assertEquals(true, map_ProductToLineItems.containsKey(OpportunityUtil.CONTRACTOR_PROD));
		System.assertEquals(objOpportunity.Number_of_Contractors__c, map_ProductToLineItems.get(OpportunityUtil.CONTRACTOR_PROD).Quantity);

		// Assert two priority support line items got created (one for employee and one for contractor)
		System.assertEquals(true, map_ProductToLineItems.containsKey(OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE));
		System.assertEquals(objOpportunity.NumberOfEmployees__c, map_ProductToLineItems.get(OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE).Quantity);

		System.assertEquals(true, map_ProductToLineItems.containsKey(OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR));
		System.assertEquals(objOpportunity.Number_of_Contractors__c, map_ProductToLineItems.get(OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR).Quantity);

		// assert international contractor line item got created
		System.assertEquals(true, map_ProductToLineItems.containsKey(OpportunityUtil.INTERNATIONAL_CONTRACTOR_ADD_ON_PRODUCT));
		System.assertEquals(objPaymentInvoice.International_Contractors__c, map_ProductToLineItems.get(OpportunityUtil.INTERNATIONAL_CONTRACTOR_ADD_ON_PRODUCT).Quantity);
		**/
	}

	/**
	 * @description Test Sync Opportunity Owner with Opportunity Split and move the percentage to 100%
	 * @author      Prity Kumari
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testSyncOppSplit() {
		// Create company and set custom pricing & include both add-ons
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('9867868757')
			.setPricing('$40 Base, $6: 1+')
			.build();
		insert objAccount;

		// create a payroll opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setNumberOfContractors(12)
			.build();
		insert objOpportunity;
		User objUser = [SELECT Id, IsActive, Username, Profile.Name FROM User WHERE UserRole.Name = 'sales_partner_ae_xx' AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		objOpportunity.OwnerId = objUser.Id;
		update objOpportunity;
		Test.stopTest();
		// Retrieve the updated split records
		List<OpportunitySplit> list_UpdatedSplits = [SELECT Id, SplitPercentage, SplitOwnerId FROM OpportunitySplit WHERE OpportunityId = :objOpportunity.Id];
		System.assertEquals(list_UpdatedSplits.isEmpty(), false, 'Opportunity should have 1 split record');
		System.assertEquals(list_UpdatedSplits[0].SplitOwnerId, objUser.Id, 'Opportunity split should be assiged to new owner');
		System.assertEquals(list_UpdatedSplits[0].SplitPercentage, 100, 'Opportunity split percentage should be equal to 100');
	}

	/**
	 * @author        Deepika Saini
	 * @description	  Test Create Recertification Ticket on Needs_Recertification__c = true with Case whose contact is blank.
	 * @param          void
	 * @return        void
	 **/
	@isTest
	static void testRecertificationTicketEmailAutomationFailed() {
		List<Account> list_Accounts = [SELECT Id, Discount__c, RecordTypeId, Name FROM Account];
		Account objCompAccount;
		for (Account objAcc : list_accounts) {
			if (objAcc.recordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objCompAccount = new Account(Id = objAcc.Id);
			}
		}

		Test.startTest();

		Group objGroupRT = new Group(Name = 'Recertification Team', type = 'Queue');
		insert objGroupRT;
		System.runAs(TestUserUtility.getRunningUser()) {
			QueuesObject objQueues = new QueueSObject(QueueID = objGroupRT.id, SobjectType = 'Ticket__c');
			insert objQueues;
		}

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunityBenefitsRenewal = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setAccountId(objCompAccount.Id)
			.setName('Test Opp BNP')
			.setStage('SAL')
			.setCloseDate(Date.today().addDays(10))
			.setNeedsRecertification(false)
			.build();
		insert objOpportunityBenefitsRenewal;
		OpportunityTriggerHelper.skipTrigger = false;

		CasetriggerHelper.skipTrigger = true;
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Renewal Case')
			.setAccountId(objCompAccount.Id)
			.setOrigin('Hippo')
			.setOpportunity(objOpportunityBenefitsRenewal.Id)
			.setIntegrationId('hippo-123')
			.build();
		insert objCase;
		CasetriggerHelper.skipTrigger = false;

		objOpportunityBenefitsRenewal.Needs_Recertification__c = true;
		update objOpportunityBenefitsRenewal;

		Test.stopTest();

		List<Ticket__c> list_Tickets = [
			SELECT Id, Team__c, Escalation_Reason__c, Opportunity__c, OwnerId, Opportunity__r.Advising_Blocked_Reason__c, Recert_Status__c
			FROM Ticket__c
			WHERE Opportunity__c = :objOpportunityBenefitsRenewal.Id
		];

		System.assertEquals(OpportunityUtil.PENDING_RECERT, list_Tickets[0].Opportunity__r.Advising_Blocked_Reason__c, 'Advising_Blocked_Reason__c is unable to updated to pending recert.');
		System.assertEquals(TicketUtil.TICKET_TEAM_ADVISING, list_Tickets[0].Team__c, 'Ticket team is unable to set to Benefits Advising');
		System.assertEquals(TicketUtil.TICKET_REASON_RECERTIFICATION, list_Tickets[0].Escalation_Reason__c, 'Ticket reason is unable set to Recertification.');
		System.assertEquals(objGroupRT.Id, list_Tickets[0].OwnerId, 'Ticket Owner unable to set as Recertification Team.');
		System.assertEquals(TicketUtil.EMAIL_AUTOMATION_FAILED, list_Tickets[0].Recert_Status__c, 'Recert Status is not set to Email Automation Failed');
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  When Opportunity, Benefits Current Setup Step is Dismissed. Then Closed the Benefit Order & Tickets related to it.
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testDismissedOpportunity() {
		Utils.skipTrigger(true);
		List<Account> listAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID];
		Opportunity objBenefitsRenewalOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('Test Opp - BNP Ren')
			.setAccountId(listAccounts[0].Id)
			.setCloseDate(System.today())
			.setStage(OpportunityUtil.SAL_STAGE)
			.setPriceBookId(Test.getStandardPriceBookId())
			.build();
		insert objBenefitsRenewalOpp;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Principal').setUniqueName('Principal').setState('CA').setCarrierId('48').setKey('principal_ca').setId('24').build();
		insert objCarrier;

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setName('TEST BENEFIT ORDER')
			.setRecordType(BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID)
			.setOpp(objBenefitsRenewalOpp.Id)
			.setStatus(BenefitOrderUtil.STATUS_QUALIFICATION)
			.setQualificationOwner(UserInfo.getUserId())
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objBO;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setBenefitOrder(objBO.Id)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO)
			.setRecordTypeId(CarrierOrderUtil.RECTYPE_RENEWAL)
			.setImplementationStage(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION)
			.setOwnerId(UserInfo.getUserId())
			.setBenefitTypes('Test')
			.build();
		insert objCO;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_BENEFITS_RENEWAL_CASE)
			.setAccountId(listAccounts[0].Id)
			.setSubject('Test Relation')
			.setDescription('Test Relation')
			.setSuppliedEmail('TickettriggerHelper@gusto.com')
			.setType(CaseUtils.TYPE_SALES)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.build();
		insert objCase;

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setEscalationReason('Pending Items')
			.setEscalationReasonDetail('Incomplete Form')
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.build();
		insert objTicket;

		Utils.skipTrigger(false);

		Test.startTest();

		objBenefitsRenewalOpp.Benefits_Current_Setup_Step__c = OpportunityUtil.DISMISSED_SETUP_STEP;
		update objBenefitsRenewalOpp;

		Test.stopTest();

		Ticket__c objUpdatedTicket = [SELECT Id, Status__c, Benefit_Order__r.Order_Status__c, Benefit_Order__r.Status_Detail__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(TicketUtil.TICKET_STATUS_CLOSED, objUpdatedTicket.Status__c, 'Tickets are not closed');
		System.assertEquals(OpportunityUtil.CLOSED_LOST_STAGE, objUpdatedTicket.Benefit_Order__r.Order_Status__c, 'Benefit Order are not closed');
		System.assertEquals(OpportunityUtil.DISMISSED_STAGE_DETAIL, objUpdatedTicket.Benefit_Order__r.Status_Detail__c, 'Benefit Order stage details is not changed');
	}
	
	/**
	 * @description Test if closed date is same as joined date when company opportunity set to closed won.
	 * @author      Anurag Gautam
	 **/
	@isTest
	private static void testClosedDateUpdate() {
		AccountTriggerHelper.skipTrigger = true;

		// Insert reseller account and company account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('234567890')
			.setOnboardingFlow('In-App')
			.setTier('simple')
			.build();

		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Company Account - Payroll')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.setZPCompanyId('234567890')
			.build();
		insert objOppty;

		objCompanyAccount.Joined_Date_Panda__c = System.Today();
		update objCompanyAccount;
		Test.startTest();

		// move opportunity to closed won
		objOppty.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		update objOppty;

		Test.stopTest();

		Opportunity objOpportunity = [SELECT Id, Joined_Date_Panda__c, CloseDate FROM Opportunity WHERE Id = :objOppty.Id];
		System.assertEquals(objCompanyAccount.Joined_Date_Panda__c, objOpportunity.Joined_Date_Panda__c);
	}
	/**
	 * @description Test Ardius ticket Lost,if parent opportunity(Tax credits) is closed lost
	 * Also test whether Ardius opportunities Referral code is populated from prior opportunities
	 * @author      Deepesh Rao, Ajay Krishna P U
	 **/
	@isTest
	static void testArdiusTicketClosureAndRfCodePopulation() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'APD Account' LIMIT 1];
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setAccountId(objAccount.Id)
			.setName('Test Opp 2')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setStage('New')
			.build();
		insert objOpportunity;

		Ticket__c objTicket = new TestDataFactory.TicketBuilder().setOwnerId(UserInfo.getUserId()).setOppId(objOpportunity.Id).setStatus('New').setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID).build();
		insert objTicket;

		Test.startTest();
		objOpportunity.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
		objOpportunity.Stage_Detail__c = OpportunityUtil.PRICE_STAGE;
		objOpportunity.Stage_Detail_2__c = OpportunityUtil.PAYMENT_PLAN_OPTIONS_STAGE;
		update objOpportunity;
		Assert.AreEqual(objOpportunity.StageName, OpportunityUtil.CLOSED_LOST_STAGE, 'Stage is not Closed Lost');
		Assert.AreEqual(objOpportunity.Stage_Detail__c, OpportunityUtil.PRICE_STAGE, 'Stage detail is not matching');
		Assert.AreEqual(objOpportunity.Stage_Detail_2__c, OpportunityUtil.PAYMENT_PLAN_OPTIONS_STAGE, 'Stage detail 2 is not matching');

		Ticket__c objTicketRec = [SELECT Id, Status__c, Lost_Detail2__c, Lost_Detail__c FROM Ticket__c WHERE Opportunity__c = :objOpportunity.Id];
		Assert.AreEqual(objTicketRec.Status__c, TicketUtil.TICKET_STATUS_LOST, 'Status is not Lost');
		Assert.AreEqual(objTicketRec.Lost_Detail__c, objOpportunity.Stage_Detail__c, 'Lost detail is not matching');
		Assert.AreEqual(objTicketRec.Lost_Detail2__c, objOpportunity.Stage_Detail_2__c, 'Lost detail 2 is not matching');

		//Test Populate Refferal Code
		objOpportunity.Referral_Code__c = 'RF1';
		update objOpportunity;

		AccountTriggerHelper.skipTrigger = true;
		objAccount.Tier__c = OpportunityUtil.ACCOUNT_TIER_PREMIUM;
		update objAccount;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objOpportunity2 = new TestDataFactory.OpportunityBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setAccountId(objAccount.Id)
			.setName('Test Opp 3')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setStage('New')
			.setTaxYear('2022')
			.build();
		insert objOpportunity2;

		objOpportunity2 = [SELECT Id, Referral_Code__c, Pricebook2Id, Tax_Year__c, OwnerId FROM Opportunity WHERE Id = :objOpportunity2.Id];
		System.assertEquals(objOpportunity.Referral_Code__c, objOpportunity2.Referral_Code__c, 'Invalid Refferal code - opp 2');
		System.assertEquals(objOpportunity2.OwnerId, UserInfo.getUserId(), 'Opportunity owner is changed');

		List<Pricebook2> list_Pricebooks = [SELECT Id, Name FROM Pricebook2 WHERE Name = :OpportunityUtil.PRICE_BOOK_RD_PREMIUM LIMIT 1];
		System.assertEquals(1, list_Pricebooks.size(), 'Invalid Pricebook test data');
		System.assertEquals(list_Pricebooks[0].Id, objOpportunity2.Pricebook2Id, 'Pricebook population failed');

		//Test Duplicate Ardius Opportunity creation
		Opportunity objOpportunity3 = new TestDataFactory.OpportunityBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setAccountId(objAccount.Id)
			.setName('Test Opp 4')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setStage('New')
			.setTaxYear('2022')
			.build();

		Boolean blnException = false;
		try {
			insert objOpportunity3;
		} catch (Exception objEx) {
			blnException = true;
		}
		System.assertEquals(true, blnException, 'Failed, Duplicate opportunities are created with same Tax year.');

		blnException = false;
		objOpportunity3.Tax_Year__c = '2000';
		try {
			insert objOpportunity3;
		} catch (Exception objEx) {
			blnException = true;
		}
		System.assertEquals(false, blnException, 'Failed, opportunites with different tax year failed to create.');
		Test.stopTest();
	}

	/**
	 * @description Test Ardius ticket Lost,if parent opportunity(Tax credits) is closed lost
	 * Also test whether Ardius opportunities Referral code is populated from prior opportunities
	 * @author      Deepesh Rao, Ajay Krishna P U
	 **/
	@isTest
	static void testArdiusTicketAutoLost() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'APD Account' LIMIT 1];
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setAccountId(objAccount.Id)
			.setName('Test Opp 2')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setStage('New')
			.build();
		insert objOpportunity;

		Ticket__c objTicket = new TestDataFactory.TicketBuilder().setOwnerId(UserInfo.getUserId()).setOppId(objOpportunity.Id).setStatus('New').setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID).build();
		insert objTicket;

		Test.startTest();
		objOpportunity.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
		objOpportunity.Stage_Detail__c = OpportunityUtil.PRICE_STAGE;
		objOpportunity.Stage_Detail_2__c = OpportunityUtil.PAYMENT_PLAN_OPTIONS_STAGE;
		update objOpportunity;

		Ticket__c objTicketRec = [SELECT Id, Status__c, Lost_Detail2__c, Lost_Detail__c FROM Ticket__c WHERE Opportunity__c = :objOpportunity.Id];
		System.assertEquals(objTicketRec.Status__c, TicketUtil.TICKET_STATUS_LOST, 'Ticket didnot updated, Invalid status');
		System.assertEquals(objTicketRec.Lost_Detail__c, objOpportunity.Stage_Detail__c, 'Ticket didnot updated, Invalid Stage_Detail_1__c');
		System.assertEquals(objTicketRec.Lost_Detail2__c, objOpportunity.Stage_Detail_2__c, 'Ticket didnot updated, Invalid Stage_Detail_2__c');

		//Auto Reopan Opportunity
		objOpportunity.Company_Information_Complete__c = true;
		objOpportunity.Onboarding_Complete__c = true;
		update objOpportunity;

		objOpportunity = [SELECT Id, StageName, Collecting_Company_Information_End__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assert(objOpportunity.Collecting_Company_Information_End__c != null, 'Collecting_Company_Information_End Population failed');
		System.assertEquals(OpportunityUtil.NEW_STAGE, objOpportunity.StageName, 'Opportunity failed to reopen');

		Test.stopTest();
	}

	/**
	 * @description Test Ardius ticket with New Status ,if parent opportunity(Tax credits) is closed won
	 * @author      Deepesh Rao, Ajay Krishna P U
	 **/
	@isTest
	static void testArdiusTicketAutoOpen() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'APD Account' LIMIT 1];
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setAccountId(objAccount.Id)
			.setName('Test Opp 2')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setStage('New')
			.build();
		insert objOpportunity;

		Ticket__c objTicket = new TestDataFactory.TicketBuilder().setOwnerId(UserInfo.getUserId()).setOppId(objOpportunity.Id).setStatus('New').setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID).build();
		insert objTicket;

		Test.startTest();

		//Test Populate Refferal Code
		objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		objOpportunity.Stage_Detail__c = '';
		objOpportunity.Stage_Detail_2__c = '';
		objOpportunity.Onboarding_Complete__c = true;
		update objOpportunity;

		Ticket__c objTicketRec1 = [SELECT Id, Status__c, Lost_Detail2__c, Lost_Detail__c FROM Ticket__c WHERE Opportunity__c = :objOpportunity.Id];
		System.assertEquals(objTicketRec1.Status__c, TicketUtil.TICKET_STATUS_NEW, 'Invalid status');

		objOpportunity = [SELECT Id, Onboarding_Completed_Date__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assert(objOpportunity.Onboarding_Completed_Date__c != null, 'Onboarding_Completed_Date Population failed');
		Test.stopTest();
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if HI Lead Pass is getting updated on manual benefits opportunity creation
	 */
	@isTest
	static void testHILeadPassUpdatePositive() {
		User objUser = [SELECT Id, Name FROM User WHERE Username = 'nonHIUser@testorg.com' AND IsActive = TRUE LIMIT 1];

		AccountTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('868968979')
			.setNumberOfActiveEEs(5)
			.setNumberOfEmployees(5)
			.setOwnerId(objUser.id)
			.build();
		insert objAcc;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objNewPlanOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAcc.Id)
			.setNumberOfEE(2)
			.build();

		Opportunity objBYBOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setName('Test BYOB Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 1')
			.setCloseDate(System.today())
			.build();

		Opportunity objBOROppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Test BoR Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 7')
			.setCloseDate(System.today())
			.build();

		Test.startTest();
		List<Opportunity> list_BenefitOpps = new List<Opportunity>{ objNewPlanOppty, objBYBOppty, objBOROppty };

		System.runAs(objUser) {
			insert list_BenefitOpps;
		}
		Test.stopTest();

		List<Opportunity> list_OppsToAssert = [SELECT Id, Name, Sent_to_Gusto_User__c, HI_Accepted_Lead_Pass__c FROM Opportunity WHERE Id IN :list_BenefitOpps];

		for (Opportunity objOpp : list_OppsToAssert) {
			if (objOpp.Id == objNewPlanOppty.Id) {
				System.assertEquals(objOpp.Sent_to_Gusto_User__c, objUser.Id, 'HI Lead Pass did not get updated with non HI opportunity owner.');
			} else if (objOpp.Id == objBYBOppty.Id) {
				System.assertEquals(objOpp.Sent_to_Gusto_User__c, objUser.Id, 'HI Lead Pass did not get updated with non HI opportunity owner.');
			} else if (objOpp.Id == objBOROppty.Id) {
				System.assertEquals(objOpp.Sent_to_Gusto_User__c, objUser.Id, 'HI Lead Pass did not get updated with non HI opportunity owner.');
			}
		}
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test HI Lead Pass should not be updated if opportunity is created by users other than the Sales and CS roles
	 */
	@isTest
	static void testHILeadPassUpdateNegative() {
		User objUser = [
			SELECT Id, IsActive, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		AccountTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('868968979')
			.setNumberOfActiveEEs(5)
			.setNumberOfEmployees(5)
			.setOwnerId(objUser.id)
			.build();
		insert objAcc;
		AccountTriggerHelper.skipTrigger = false;

		// Create 3 benefits opportunities (new plan, bor and byb opportunities)
		Opportunity objNewPlanOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAcc.Id)
			.setNumberOfEE(2)
			.build();

		Opportunity objBYBOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setName('Test BYOB Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 1')
			.setCloseDate(System.today())
			.build();

		Opportunity objBOROppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Test BoR Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 7')
			.setCloseDate(System.today())
			.build();

		Test.startTest();
		List<Opportunity> list_BenefitOpps = new List<Opportunity>{ objNewPlanOppty, objBYBOppty, objBOROppty };

		System.runAs(objUser) {
			insert list_BenefitOpps;
		}
		Test.stopTest();

		List<Opportunity> list_OppsToAssert = [SELECT Id, Name, Sent_to_Gusto_User__c, HI_Accepted_Lead_Pass__c FROM Opportunity WHERE Id IN :list_BenefitOpps];

		for (Opportunity objOpp : list_OppsToAssert) {
			if (objOpp.Id == objNewPlanOppty.Id) {
				System.assertNotEquals(objOpp.Sent_to_Gusto_User__c, objUser.Id, 'HI Lead Pass got updated with non HI opportunity owner.');
			} else if (objOpp.Id == objBYBOppty.Id) {
				System.assertNotEquals(objOpp.Sent_to_Gusto_User__c, objUser.Id, 'HI Lead Pass got updated with non HI opportunity owner.');
			} else if (objOpp.Id == objBOROppty.Id) {
				System.assertNotEquals(objOpp.Sent_to_Gusto_User__c, objUser.Id, 'HI Lead Pass got updated with non HI opportunity owner.');
			}
		}
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if HI Accepted Lead Pass is getting updated based on opportunity stage update
	 */
	@isTest
	static void testHIAcceptedLeadPassUpdatePositive() {
		User objUser = [SELECT Id, Name FROM User WHERE Username = 'nonHIUser@testorg.com' AND IsActive = TRUE LIMIT 1];

		AccountTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('868968979')
			.setNumberOfActiveEEs(5)
			.setNumberOfEmployees(5)
			.setOwnerId(objUser.id)
			.build();
		insert objAcc;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objNewPlanOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAcc.Id)
			.setNumberOfEE(2)
			.build();

		System.runAs(objUser) {
			insert objNewPlanOppty;
		}

		Test.startTest();
		objNewPlanOppty.StageName = OpportunityUtil.QUALIFIED_STAGE;
		update objNewPlanOppty;
		Test.stopTest();

		Opportunity list_OppToAssert = [SELECT Id, Name, Sent_to_Gusto_User__c, HI_Accepted_Lead_Pass__c FROM Opportunity WHERE Id = :objNewPlanOppty.Id LIMIT 1];

		System.assertEquals(list_OppToAssert.HI_Accepted_Lead_Pass__c, System.today(), 'HI Accepted Lead Pass did not get updated with current date.');
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if HI Accepted Lead Pass is not getting updated if HI Lead Pass does not have a value
	 */
	@isTest
	static void testHIAcceptedLeadPassUpdateNegative() {
		User objUser = [
			SELECT Id, IsActive, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		AccountTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('868968979')
			.setNumberOfActiveEEs(5)
			.setNumberOfEmployees(5)
			.setOwnerId(objUser.id)
			.build();
		insert objAcc;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objNewPlanOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAcc.Id)
			.setNumberOfEE(2)
			.build();

		System.runAs(objUser) {
			insert objNewPlanOppty;
		}

		Test.startTest();
		objNewPlanOppty.StageName = OpportunityUtil.QUALIFIED_STAGE;
		update objNewPlanOppty;
		Test.stopTest();

		Opportunity list_OppToAssert = [SELECT Id, Name, Sent_to_Gusto_User__c, HI_Accepted_Lead_Pass__c FROM Opportunity WHERE Id = :objNewPlanOppty.Id LIMIT 1];

		System.assertEquals(list_OppToAssert.HI_Accepted_Lead_Pass__c, null, 'HI Accepted Lead Pass got updated even if HI Lead Pass was b.');
	}

	@isTest
	static void testBenefitsOpportunityProducts() {
		List<Benefits_Default_Products__mdt> benefitsDefProdList = [SELECT id, MasterLabel, DeveloperName, Product_Names__c FROM Benefits_Default_Products__mdt];
		Assert.areEqual(5, benefitsDefProdList.size(), 'Expected pricebook is not set');

		User objUser = [SELECT Id, Name FROM User WHERE Username = 'nonHIUser@testorg.com' AND IsActive = TRUE LIMIT 1];

		PriceBook2 pb = new TestDataFactory.PriceBookBuilder().setName('Benefits Sales Payment Plan').setActive().build();
		insert pb;

		List<Product2> list_Products = new List<Product2>{
			new TestDataFactory.ProductBuilder().setName('Fully-funded BOR').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Fully-funded BYB').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Benefits Change').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Fully-funded New Plan').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Benefits Renewal').setFamily('Benefit').build()
		};
		insert list_Products;

		List<PriceBookEntry> list_StdpbEntry = new List<PriceBookEntry>();
		List<PriceBookEntry> list_CustpbEntry = new List<PriceBookEntry>();
		for (Product2 prod : list_Products) {
			PriceBookEntry stdpbEntry = new TestDataFactory.PricebookEntryBuilder().setProductId(prod.Id).setPriceBookId(Test.getStandardPricebookId()).setUnitPrice(20).setIsActive(true).build();
			list_StdpbEntry.add(stdpbEntry);

			PriceBookEntry pbEntry = new TestDataFactory.PricebookEntryBuilder().setProductId(prod.Id).setPriceBookId(pb.Id).setUnitPrice(20).setIsActive(true).build();
			list_CustpbEntry.add(pbEntry);
		}
		insert list_StdpbEntry;
		insert list_CustpbEntry;

		AccountTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 2')
			.setZPCompanyId('868968979')
			.setNumberOfActiveEEs(5)
			.setNumberOfEmployees(5)
			.setOwnerId(objUser.id)
			.build();
		insert objAcc;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objNewPlanOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAcc.Id)
			.setNumberOfEE(2)
			.build();

		Opportunity objBYBOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setName('Test BYOB Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 1')
			.setCloseDate(System.today())
			.setNumberOfEE(2)
			.build();

		Opportunity objBOROppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Test BoR Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 7')
			.setCloseDate(System.today())
			.setNumberOfEE(2)
			.build();

		Test.startTest();
		List<Opportunity> list_BenefitOpps = new List<Opportunity>{ objNewPlanOppty, objBYBOppty, objBOROppty };

		System.runAs(objUser) {
			insert list_BenefitOpps;
		}
		Test.stopTest();
		List<Opportunity> list_OppsToAssert = [SELECT Id, Name, Pricebook2.Name, NumberOfEmployees__c, Price_at_Closed_Won__c, Amount, RecordType.Name FROM Opportunity WHERE Id IN :list_BenefitOpps];
		List<OpportunityLineItem> list_OppsProducts = [
			SELECT
				Id,
				Quantity,
				Opportunity.Price_at_Closed_Won__c,
				OpportunityId,
				Opportunity.RecordType.Name,
				PricebookEntry.Product2.Name,
				Opportunity.NumberOfEmployees__c,
				Opportunity.Amount,
				UnitPrice
			FROM OpportunityLineItem
			WHERE OpportunityId IN :list_OppsToAssert
		];
		Assert.isTrue(list_OppsProducts.size() > 0);
		for (OpportunityLineItem item : list_OppsProducts) {
			Assert.areEqual(item.Opportunity.NumberOfEmployees__c, item.Quantity, 'Quantity on Opportunity Products is not matching with Number of Employee on Opportunity');
			Assert.areEqual(item.Opportunity.Amount, item.UnitPrice * item.Quantity, 'Amount is not incorrect');
			if (item.Opportunity.RecordType.Name == 'Benefits BYOB') {
				Assert.areEqual(item.Opportunity.Amount, item.Opportunity.Price_at_Closed_Won__c, 'Price at won should match with amount on Benefits BYOB opportunity,');
			}
		}
		for (Opportunity opp : list_OppsToAssert) {
			Assert.areEqual(Label.Benefits_Default_Payment_Plan, opp.Pricebook2.Name, 'Expected pricebook is not set');
		}
	}
	@isTest
	static void testBenefitsOpportunityProductsQuantity() {
		List<Benefits_Default_Products__mdt> benefitsDefProdList = [SELECT id, MasterLabel, DeveloperName, Product_Names__c FROM Benefits_Default_Products__mdt];
		User objUser = [SELECT Id, Name FROM User WHERE Username = 'nonHIUser@testorg.com' AND IsActive = TRUE LIMIT 1];
		PriceBook2 pb = new TestDataFactory.PriceBookBuilder().setName('Benefits Sales Payment Plan').setActive().build();
		insert pb;

		List<Product2> list_Products = new List<Product2>{
			new TestDataFactory.ProductBuilder().setName('Fully-funded BOR').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Fully-funded BYB').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Benefits Change').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Fully-funded New Plan').setFamily('Benefit').build(),
			new TestDataFactory.ProductBuilder().setName('Benefits Renewal').setFamily('Benefit').build()
		};
		insert list_Products;

		List<PriceBookEntry> list_StdpbEntry = new List<PriceBookEntry>();
		List<PriceBookEntry> list_CustpbEntry = new List<PriceBookEntry>();
		for (Product2 prod : list_Products) {
			PriceBookEntry stdpbEntry = new TestDataFactory.PricebookEntryBuilder().setProductId(prod.Id).setPriceBookId(Test.getStandardPricebookId()).setUnitPrice(20).setIsActive(true).build();
			list_StdpbEntry.add(stdpbEntry);

			PriceBookEntry pbEntry = new TestDataFactory.PricebookEntryBuilder().setProductId(prod.Id).setPriceBookId(pb.Id).setUnitPrice(20).setIsActive(true).build();
			list_CustpbEntry.add(pbEntry);
		}
		insert list_StdpbEntry;
		insert list_CustpbEntry;

		AccountTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 2')
			.setZPCompanyId('868968979')
			.setNumberOfActiveEEs(5)
			.setNumberOfEmployees(5)
			.setOwnerId(objUser.id)
			.build();
		insert objAcc;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objNewPlanOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAcc.Id)
			.setNumberOfEE(2)
			.build();

		Opportunity objBYBOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setName('Test BYOB Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 1')
			.setCloseDate(System.today())
			.setNumberOfEE(2)
			.build();

		Opportunity objBOROppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Test BoR Opp')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setSourceID('Test Opp 7')
			.setCloseDate(System.today())
			.setNumberOfEE(2)
			.build();

		List<Opportunity> list_BenefitOpps = new List<Opportunity>{ objNewPlanOppty, objBYBOppty, objBOROppty };

		System.runAs(objUser) {
			insert list_BenefitOpps;
		}

		Test.startTest();
		List<Opportunity> list_OppsToUpdate = [SELECT Id, Name, Pricebook2.Name, NumberOfEmployees__c FROM Opportunity];
		for (Opportunity opp : list_OppsToUpdate) {
			opp.NumberOfEmployees__c = 10;
		}
		update list_OppsToUpdate;
		Test.stopTest();

		List<Opportunity> list_OppsToAssert = [SELECT Id, Name, Pricebook2.Name, NumberOfEmployees__c FROM Opportunity];
		List<OpportunityLineItem> list_OppsProducts = [
			SELECT Id, Quantity, OpportunityId, Opportunity.RecordType.Name, PricebookEntry.Product2.Name, Opportunity.NumberOfEmployees__c, Opportunity.Amount, UnitPrice
			FROM OpportunityLineItem
		];
		for (OpportunityLineItem item : list_OppsProducts) {
			Assert.areEqual(item.Opportunity.NumberOfEmployees__c, 10);
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Team Members
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testCaseTeamMember() {
		Account objAccnt = [SELECT Id, RecordTypeId, Name FROM Account WHERE Name = 'Employer Account' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		objContact.ZP_User_Id__c = '75301';
		update objContact;

		Test.startTest();
		//Create roleset records
		Rolesets__c objRoleSet = new Rolesets__c();
		objRoleSet.Name = 'roleset1';
		objRoleSet.Roleset_Name__c = 'Company_Benefits';
		objRoleSet.components__c = 'OpportunityTriggerHelper';
		objRoleSet.Roles__c = 'Primary Payroll Admin\r\nPayroll Admin\r\nBenefits Signatory\r\nSignatory\r\nBenefits Admin';
		insert objRoleSet;

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setCustomId('777777777777772')
			.setEmail('testuser@gmail.com')
			.setLastSignInAt(System.now())
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();
		insert objZPUser;

		ZP_User_Role__c objUserRole = new ZP_User_Role__c();
		objUserRole.User_Id__c = '777777777777777';
		objUserRole.Id__c = '9343434343499';
		objUserRole.Company_Account__c = objAccnt.Id;
		objUserRole.Company_Id__c = '1234567890';
		objUserRole.Created_At__c = System.now();
		objUserRole.Updated_At__c = System.now();
		objUserRole.Type__c = 'Role::Benefits Admin';
		objUserRole.Processing_State__c = 'Manually Enqueued';
		objUserRole.Contact__c = objContact.Id;
		insert objUserRole;

		HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c(
			Id__c = '75301',
			Company_Id__c = '1234567890',
			ZP_User_Id__c = '75301',
			Created_At__c = DateTime.Now(),
			Updated_At__c = DateTime.Now(),
			Processing_State__c = 'Queued'
		);
		insert objHIAdmin;

		Opportunity objRenewalPlanOppty1 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objAccnt.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setStage('SAL')
			.build();
		insert objRenewalPlanOppty1;

		Case objCase = [SELECT Id, Opportunity__c FROM Case WHERE Opportunity__c = :objRenewalPlanOppty1.Id];
		System.assertEquals(1, [SELECT COUNT() FROM CaseTeamMember WHERE parentId = :objCase.Id], 'Case Team Member should be 1.');

		Test.stopTest();
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Not create Same Contact Role If Exists.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testContactRoleWhenReOpens() {
		TriggerHandler.bypass('AccountTriggerHandler');
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			Rolesets__c objRoleSet = new Rolesets__c();
			objRoleSet.Name = 'roleset1';
			objRoleSet.Roleset_Name__c = 'Company_Benefits';
			objRoleSet.components__c = 'OpportunityTriggerHelper';
			objRoleSet.Roles__c = 'Primary Payroll Admin\r\nPayroll Admin\r\nBenefits Signatory\r\nSignatory\r\nBenefits Admin';
			insert objRoleSet;
			Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account BOR').setZPCompanyId('98989898989898').build();

			objAccount.Number_of_Active_Employees__c = 20;
			objAccount.BillingCountry = 'United States';
			objAccount.BillingState = 'California';
			insert objAccount;
			Contact objContact = [SELECT Id FROM Contact LIMIT 1];
			objContact.ZP_User_Id__c = '777777777777772';
			update objContact;
			TriggerHandler.Bypass('OpportunityTriggerHandler');
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setName('BOR Opp')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();
			insert objOpportunity;
			TriggerHandler.clearBypass('OpportunityTriggerHandler');

			Test.startTest();
			ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
				.setCustomId('777777777777772')
				.setEmail('testuser@gmail.com')
				.setLastSignInAt(System.now())
				.setCreatedAt(System.now())
				.setUpdatedAt(System.now())
				.build();
			insert objZPUser;

			ZP_User_Role__c objUserRole = new TestDataFactory.ZPUserRoleBuilder()
				.setCustomId('9343434343499')
				.setUserId('777777777777777')
				.setCompanyId('98989898989898')
				.setType('Role::Benefits Signatory')
				.setCompanyAccount(objAccount.Id)
				.setCreatedAt(System.Now())
				.setUpdatedAt(System.Now())
				.setContact((objContact.Id))
				.build();
			objUserRole.Processing_State__c = 'Manually Enqueued';
			insert objUserRole;
			HI_Benefits_Admin__c objHIAdmin = new TestDataFactory.HIBenefitsAdminBuilder()
				.setBenefitId('75301')
				.setCompanyId('98989898989898')
				.setZPUserId('777777777777772')
				.setCreatedAt(DateTime.Now())
				.setUpdatedAt(DateTime.Now())
				.build();
			objHIAdmin.Processing_State__c = 'Queued';
			insert objHIAdmin;
			//Adding contact role on open opportunity
			OpportunityContactRole objOpportunityContactRole = new TestDataFactory.OpportunityContactRoleBuilder()
				.setContactId(objContact.Id)
				.setOpportunityId(objOpportunity.Id)
				.setRole('Benefits Signatory')
				.build();
			insert objOpportunityContactRole;
			//Count of opportunity contact role before closing
			System.assertEquals(1, [SELECT COUNT() FROM OpportunityContactRole WHERE role = :'Benefits Signatory'], 'Opportunity Contact Role is not be Created.');
			//Closing opportunity
			objOpportunity.stageName = OpportunityUtil.CLOSED_LOST_STAGE;
			objOpportunity.Stage_Detail__c = OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL;
			update objOpportunity;
			objOpportunity.stageName = OpportunityUtil.COMMIT_STAGE;
			update objOpportunity;
			Test.stopTest();
			//checking if opportunity reopens it will not add new duplicate opportunity contact role if already exist
			System.assertEquals(1, [SELECT COUNT() FROM OpportunityContactRole WHERE role = :'Benefits Signatory'], 'Failed : Duplicate contact role created');
			System.assertEquals(1, [SELECT COUNT() FROM OpportunityContactRole WHERE role = :'Benefits Admin'], 'Opportunity Contact Role is not be Created.');
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test Cross-Sell and Upsell Opportunities are sent to Routing
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testTierUpsellOpportunityRouting() {
		RingLead_Routing_Credentials__c objCredential = new RingLead_Routing_Credentials__c(Send_Opportunity_Endpoint__c = 'https://ringlead.sendopportunity.com/send', API_Token__c = 'api-token');
		insert objCredential;

		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
		// Setup pricebooks and pricebook entries
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		setUpNewPrices(objTierConfig.New_Price_1__c, true);
		setUpNewPrices(objTierConfig.New_Price_2__c, true);
		Account objAccount = [
			SELECT Id, Number_of_Active_Contractors__c, Number_of_Active_Employees__c, Current_MRR__c, Discount__c, Pricing__c, Tier__c
			FROM Account
			WHERE ZP_Company_Id__c = '4561111111'
		];
		objAccount.Tier__c = AccountUtil.SIMPLE_TIER;
		objAccount.Pricing__c = AccountUtil.SIMPLE_PAYMENT_PLAN;
		objAccount.Number_of_Active_Contractors__c = 1;
		objAccount.Number_of_Active_Employees__c = 1;
		objAccount.First_Month_Invoice_Generated__c = true;
		objAccount.Joined_Date_Panda__c = Date.today();
		update objAccount;

		Opportunity objInternationalPayrollOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('APD Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.EMPLOYER_OF_RECORD)
			.setType('Upsell')
			.build();
		objInternationalPayrollOppty.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		objInternationalPayrollOppty.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);

		Test.startTest();
		insert objInternationalPayrollOppty;
		Test.stopTest();

		// assert if opportunity got updated
		Opportunity objOpportunityAssert = [SELECT Id, Name FROM Opportunity WHERE Id = :objInternationalPayrollOppty.Id];
		System.assertEquals('Opportunity Routed Successfully', objOpportunityAssert.Name);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Client BDO Opportunity updates create new benefits opportunities
	 **/
	@isTest
	static void testClientBDOOpportunityCreation() {
		Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objCompanyAccnt.Number_Of_Active_Employees__c = 5;
		AccountTriggerHelper.skipTrigger = true;
		update objCompanyAccnt;
		AccountTriggerHelper.skipTrigger = false;
		Opportunity objOppty = TestUtils.createOpportunity(OpportunityUtil.ACQUISITION_OPPTY_RT_ID, objCompanyAccnt.Id, Date.today().addDays(10), 'Opp Name', 'MQL', true);

		Test.startTest();
		objOppty.Initiated_by_Accountant__c = 'True';
		objOppty.Contribution_to_EE_Health_Coverage_cost__c = 'COMPANY_SPONSORED_HEALTH_INSURANCE';
		objOppty.Want_to_switch_brokers__c = true;
		objOppty.Open_to_Switching_Broker__c = 'MANUALLY_ADD';
		objOppty.Currently_Offer_Health_Benefits__c = 'Yes';
		objOppty.Which_Gusto_benefits_interested_in__c = 'HEALTH_INSURANCE';
		update objOppty;
		Test.stopTest();

		// Assert if new plan opportunities got created
		Integer intNewPlanCount = [
			SELECT COUNT()
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID AND AccountId = :objCompanyAccnt.Id AND LeadSource = :OpportunityUtil.CLIENT_BDO
		];
		System.assertEquals(1, intNewPlanCount, 'New plan opportunity not created');

		// Assert if BoR opportunities got created
		Integer intBoRCount = [
			SELECT COUNT()
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID AND AccountId = :objCompanyAccnt.Id AND LeadSource = :OpportunityUtil.CLIENT_BDO
		];
		System.assertEquals(1, intBoRCount, 'BoR opportunity not created');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Employer BDO Opportunity updates create new benefits opportunities
	 **/
	@isTest
	static void testEmployerBDOOpportunityCreation() {
		Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objCompanyAccnt.Number_Of_Active_Employees__c = 5;
		AccountTriggerHelper.skipTrigger = true;
		update objCompanyAccnt;
		AccountTriggerHelper.skipTrigger = false;
		Opportunity objOppty = TestUtils.createOpportunity(OpportunityUtil.ACQUISITION_OPPTY_RT_ID, objCompanyAccnt.Id, Date.today().addDays(10), 'Opp Name', 'MQL', true);

		Test.startTest();
		objOppty.Interest_in_adding_benefits_to_Gusto__c = 'LEARNING_MORE';
		objOppty.Currently_Offer_Health_Benefits__c = 'False';
		update objOppty;
		Test.stopTest();

		// Assert if new plan opportunities got created
		Integer intNewPlanCount = [
			SELECT COUNT()
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID AND AccountId = :objCompanyAccnt.Id AND LeadSource = :OpportunityUtil.EMPLOYER_BDO
		];
		System.assertEquals(1, intNewPlanCount, 'New plan opportunity not created');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test ICP Opportunity Routing - When no EOR or Tier upsell is created - New ICP should be routed through RingLead
	 **/
	@isTest
	static void testICPRoutingWithoutExistingEOR() {
		Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objCompanyAccnt.Joined_Date_Panda__c = System.today();
		update objCompanyAccnt;
		Test.startTest();
		Opportunity objICPOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('ICP Opportunity')
			.setAccountId(objCompanyAccnt.Id)
			.setUpsellTier(AccountUtil.EMPLOYER_OF_RECORD)
			.setType('Upsell')
			.build();
		objICPOpportunity.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		objICPOpportunity.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);
		objICPOpportunity.StageName = 'Open';
		insert objICPOpportunity;
		Test.stopTest();

		// assert if opportunity got updated
		Opportunity objOpportunityAssert = [SELECT Id, Name FROM Opportunity WHERE Id = :objICPOpportunity.Id];
		System.assertEquals('Opportunity Routed Successfully', objOpportunityAssert.Name);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test ICP Opportunity Routing - When EOR opportunity exist - New ICP should be not be routed through RingLead
	 **/
	@isTest
	static void testICPRoutingWithExistingEOR() {
		Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Opportunity objInternationalPayrollOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('APD Upsell Opportunity')
			.setAccountId(objCompanyAccnt.Id)
			.setUpsellTier(AccountUtil.EMPLOYER_OF_RECORD)
			.setType('Upsell')
			.build();
		objInternationalPayrollOppty.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		objInternationalPayrollOppty.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);
		objInternationalPayrollOppty.StageName = 'New';
		insert objInternationalPayrollOppty;

		Test.startTest();
		Opportunity objICPOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('ICP Opportunity')
			.setAccountId(objCompanyAccnt.Id)
			.setUpsellTier('Plus')
			.setType('Upsell')
			.build();
		objICPOpportunity.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		objICPOpportunity.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);
		objICPOpportunity.StageName = 'Closed Lost';
		insert objICPOpportunity;

		Test.stopTest();

		// assert if opportunity got updated
		Opportunity objOpportunityAssert = [SELECT Id, Name FROM Opportunity WHERE Id = :objICPOpportunity.Id];
		System.assertNotEquals('Opportunity Routed Successfully', objOpportunityAssert.Name);
	}

	/**
	 * @author      Jai Aswani
	 * @description Test Specai Enrollment Populate by recent closed opportunity BBO-1960
	 **/
	@isTest
	static void testSpecialEnrollmentPopulate() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		User objUser = [
			SELECT Id, IsActive, Username, Profile.Name
			FROM User
			WHERE Profile.Name = :OpportunityUtil.ZP_SYS_ADMIN_PROFILE AND IsActive = TRUE AND Username = 'testAdminUser@testorg.com'
			LIMIT 1
		];
		System.runAs(objUser) {
			Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account BYOB').setZPCompanyId('98989898989898').build();
			objAccount.Number_of_Active_Employees__c = 20;
			objAccount.BillingCountry = 'United States';
			objAccount.BillingState = 'California';
			insert objAccount;

			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setName('Benefits New Plan Opp')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();
			insert objOpportunity;

			objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
			update objOpportunity;

			QA_Sheet__c objQASheet1 = new TestDataFactory.QASheetBuilder()
				.setOpportunityId(objOpportunity.Id)
				.setFederalCobraState('Federal')
				.setSICCodeSupportedByAllCarriers('Yes')
				.setSICCode('test')
				.setBAASigned('Yes')
				.setBAASignedBy('test')
				.setBSASigned('Yes')
				.setBSASignedBy('test')
				.setRecordTypeId(Cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal'))
				.setNewTAdAs(CarrierOrderUtil.TADA_BEN_TYPE_HSA)
				.setRenewingTAdAs(CarrierOrderUtil.TADA_BEN_TYPE_COMMUTER)
				.build();
			objQASheet1.Special_Enrollment__c = 'Y';
			insert objQASheet1;

			OpportunityTriggerHelper.skipTrigger = false;

			Opportunity renewalOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setName('Benefits Renewal Plan Opp')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();

			renewalOpportunity.HI_Effective_Date__c = Configuration_Settings__c.getOrgDefaults().HI_Effective_Date__c;
			Test.startTest();
			insert renewalOpportunity;
			Test.stopTest();

			Opportunity objOppAssert = [
				SELECT Id, Name, Special_Enrollment__c, RecordTypeId, StageName, Type, HI_Opportunity_Assignment_State__c, NumberOfEmployees__c, OwnerId, ZP_Company_ID__c, Source_ID__c, CloseDate
				FROM Opportunity
				WHERE Id = :renewalOpportunity.Id
			];

			System.assertEquals(objOppAssert.Special_Enrollment__c, true, 'Special Enrollment not populated to TRUE');
		}
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test validation of Growth/Expansion opportunity with Type = Upsell/Cross-Sell
	 **/
	@isTest
	static void testGrowthExpansionValidationWithTypeUpsellCrossSell() {
		Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Opportunity objGrowthExpansionOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID)
			.setName('Test Opp Name')
			.setAccountId(objCompanyAccnt.Id)
			.setType('Upsell/Cross-Sell')
			.setStage('New')
			.build();

		Boolean blnException = false;
		Test.startTest();
		try {
			insert objGrowthExpansionOppty;
		} catch (Exception objEx) {
			blnException = true;
		}
		Test.stopTest();
		System.assertEquals(true, blnException, 'Failed, Growth/Expansion opportunity created with Type = Upsell/Cross-Sell');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test validation of Growth/Expansion opportunity with Type = NULL
	 **/
	@isTest
	static void testGrowthExpansionValidationWithNoType() {
		Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Opportunity objGrowthExpansionOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID)
			.setName('Test Opp Name')
			.setAccountId(objCompanyAccnt.Id)
			.setStage('New')
			.build();

		Boolean blnException = false;
		Test.startTest();
		try {
			insert objGrowthExpansionOppty;
		} catch (Exception objEx) {
			blnException = true;
		}
		Test.stopTest();
		System.assertEquals(true, blnException, 'Failed, Growth/Expansion opportunity created without any type');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test CohortDate Update on Reseller Account
	 **/
	@isTest
	static void testCohortDateUpdate() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');

		Account objCompanyAcc = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];

		Test.startTest();
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Payroll Opportunity')
			.setAccountId(objCompanyAcc.Id)
			.setStage(OpportunityUtil.MQL_STAGE)
			.setCloseDate(System.today())
			.setSoldBy(objResellerAccount.Id)
			.setLeadSource(OpportunityUtil.ADDED_BY_ACCOUNTANT)
			.build();

		insert objOpportunity;
		objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		update objOpportunity;
		Test.stopTest();

		Opportunity objOpportunityAssert = [SELECT Id, Sold_By__c, CloseDate FROM Opportunity WHERE Id = :objOpportunity.Id];

		Account objAccountAssert = [SELECT Id, Name, Cohort_Date__c FROM Account WHERE Id = :objOpportunityAssert.Sold_By__c];

		System.assertEquals(System.today(), objOpportunityAssert.CloseDate, 'Close Date on opportunity not updated correctly.');
		System.assertEquals(System.today(), objAccountAssert.Cohort_Date__c, 'Cohort Date on reseller account not updated correctly.');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if territory is updated on the new benefits opportunity
	 **/
	@isTest
	static void testTerritoryAssignmentOnBenefitsOpps() {
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
		Account objCompanyAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		objCompanyAccnt.Territory__c = 'BMM Central';
		AccountTriggerHelper.skipTrigger = true;
		update objCompanyAccnt;

		Test.startTest();
		Opportunity objNewPlanOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objCompanyAccnt.Id)
			.setNumberOfEE(2)
			.build();
		insert objNewPlanOppty;
		Test.stopTest();

		Opportunity objOpptyAssert = [SELECT Id, Territory__c FROM Opportunity WHERE Id = :objNewPlanOppty.Id];
		System.assertEquals(objCompanyAccnt.Territory__c, objOpptyAssert.Territory__c, 'Territory not set on insert');
	}
}