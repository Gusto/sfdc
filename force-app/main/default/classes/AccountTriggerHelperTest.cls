/**
 * @author Yuvraj/Prashant
 * @since 20 Oct 2020
 */
@isTest
public class AccountTriggerHelperTest {
	public static final String strMemberOpsBYB = 'Member_Ops_BYB';
	public static final String strMemberFulfillment = 'Member_Fulfillment';
	public static Map<String, Id> map_Queues = GlobalQueryHelper.getQueueNameAndIdMap(new Set<String>{ strMemberOpsBYB, strMemberFulfillment });

	@testSetup
	static void setup() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setResellerMetricsBatchSize(1).build();
		objConfigSettings.AccountEntitlementId__c = [SELECT Id FROM SlaProcess LIMIT 1][0].Id;
		insert objConfigSettings;

		Set<String> set_ProfileNames = new Set<String>{ AccountUtil.USER_PROFILE_NAME_GUSTO_INTEGRATION_PROFILE };

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Map<String, Profile> map_Profiles = new Map<String, Profile>();

		for (Profile objProfile : [SELECT Id, Name FROM Profile WHERE Name IN :set_ProfileNames]) {
			map_Profiles.put(objProfile.Name, objProfile);
		}

		//create user
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('partam')
			.setEmail('partneram@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('partneram@testorg.com.test')
			.build();

		objAdminUser.Exempt_from_Validation_Rules__c = true;
		objAdminUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName LIKE :AccountUtil.SALES_PARTNER_AM_ROLE][0].Id;
		User objPartnerAEUser = new TestDataFactory.UserBuilder()
			.setAlias('partae')
			.setEmail('partnerae@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('partnerae@testorg.com.test')
			.build();

		objPartnerAEUser.Exempt_from_Validation_Rules__c = true;
		objPartnerAEUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName LIKE :AccountUtil.SALES_PARTNER_AE_ROLE][0].Id;

		User objIntegrationUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(AccountUtil.USER_PROFILE_NAME_GUSTO_INTEGRATION_PROFILE).Id)
			.setUserName('testIntegrationUser@account.com.test')
			.setLastName('Integration User')
			.setEmail('testIntegrationUser@account.com')
			.setAlias('Integrtn')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setCalendarLink('testCalendarLink')
			.build();

		// Setup pricebooks and pricebook entries
		setUpNewPrices(objTierConfig.New_Price_1__c, false, 5);
		setUpNewPrices(objTierConfig.New_Price_2__c, false, 10);
		setUpNewPrices(objTierConfig.New_Price_3__c, false, 20);
		setUpNewPrices(objTierConfig.New_Price_4__c, false, 30);
		setUpNewPrices(objTierConfig.New_Price_5__c, false, 40);
		setUpNewPrices(objTierConfig.New_Price_6__c, false, 50);

		//create user
		User adminUser = new TestDataFactory.UserBuilder()
			.setAlias('Admin')
			.setEmail('admin@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('admin@testorg.com.test')
			.build();
		adminUser.Exempt_from_Validation_Rules__c = true;
		adminUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = :AccountUtil.SALES_PARTNER_MANAGER_ROLE][0].Id;

		User objcurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objcurrentUser) {
			insert new List<User>{ adminUser, objAdminUser, objPartnerAEUser, objIntegrationUser };
		}

		// create company account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.setTier('simple')
			.setSetUpSteps(20.0)
			.build();

		insert objCompanyAccount;

		//create reseller account
		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('partner Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('123')
			.build();

		insert objResellerAccount;

		Account objCompanyICPAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('ICP Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567899')
			.setTier('simple')
			.setSetUpSteps(20.0)
			.build();

		insert objCompanyICPAccount;

		// create Partner program company data for company account
		List<Partner_Program_Company_Data__c> list_PPCD = new List<Partner_Program_Company_Data__c>();
		Partner_Program_Company_Data__c program = new Partner_Program_Company_Data__c();
		program.Company_Id__c = '1234567890';
		list_PPCD.add(program);
		//for reseller account
		Partner_Program_Company_Data__c program_2 = new Partner_Program_Company_Data__c();
		program_2.Account__c = objResellerAccount.Id;
		list_PPCD.add(program_2);
		insert list_PPCD;

		//create account related traking
		Account_Related_Tracking__c objART = new Account_Related_Tracking__c();
		objART.Account__c = objCompanyAccount.Id;
		insert objART;

		//create company contact
		TriggerHandler.bypass('ContactTriggerHandler');
		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Test')
			.setLastName('User1')
			.setEmail('testuser@abccompany.com')
			.build();
		insert objCompanyContact;

		//create reseller contact
		Contact objResellerContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.RESELLER_CONTACT_RT_ID)
			.setAccountId(objResellerAccount.Id)
			.setFirstName('Test')
			.setLastName('User2')
			.setEmail('testuser2@abccompany.com')
			.build();
		insert objResellerContact;

		//create opportunity
		TriggerHandler.bypass('OpportunityTriggerHandler');
		Opportunity objOpportunity = new Opportunity();
		objOpportunity.AccountId = objCompanyAccount.Id;
		objOpportunity.Name = 'Test Opp';
		objOpportunity.StageName = 'Raw';
		objOpportunity.CloseDate = System.today();
		objOpportunity.Sold_By__c = objCompanyAccount.Id;
		objOpportunity.RecordTypeId = OpportunityUtil.COMPANY_OPPTY_RT_ID;
		objOpportunity.Amount = 55000.00;
		objOpportunity.ZP_Company_Id__c = objCompanyAccount.ZP_Company_ID__c;
		insert objOpportunity;

		//create opportunity Benefits BoR
		Opportunity objOpportunity_BoR = new Opportunity();
		objOpportunity_BoR.AccountId = objCompanyAccount.Id;
		objOpportunity_BoR.Name = 'Test Opp 2';
		objOpportunity_BoR.StageName = 'Pending PR';
		objOpportunity_BoR.CloseDate = System.today();
		objOpportunity_BoR.RecordTypeId = OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID;
		objOpportunity_BoR.Amount = 55000.00;
		insert objOpportunity_BoR;

		//create ICP closed lost opportunity
		Opportunity objTierUpsellOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('ICP Opportunity')
			.setAccountId(objCompanyICPAccount.Id)
			.setUpsellTier(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)
			.setType('Upsell')
			.setStage(OpportunityUtil.CLOSED_LOST_STAGE)
			.setCloseDate(System.today())
			.build();
		insert objTierUpsellOpp;

		// Create Lead_Randomize__c Custom Setting
		Lead_Randomize__c objRandomize = new Lead_Randomize__c(
			Current_Company_Account_Index__c = 1,
			Number_of_Company_Accounts__c = 2,
			Number_of_Reseller_Accounts__c = 3,
			Number_of_Reseller_Leads__c = 3
		);
		insert objRandomize;

		TriggerHandler.clearAllBypasses();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCreatedByEmail('hello@abc.com')
			.setName('Test ZP Company')
			.setProcessingState('Manually Enqueued')
			.setPartnerProgramCompanyDataId('PPCD1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.build();
		insert objZPCompany;
	}

	/**
	 * @description DML test purely for coverage of AccountTriggerHandler exceptions
	 * @author David Schach
	 */
	@isTest
	private static void testExceptions() {
		try {
			insert new Account();
		} catch (DMLException e) {
			System.assert(true, 'Exception Occurred during inserting account');
		}

		Account objAcct = new Account(Name = 'TestAccount');
		objAcct.RecordTypeId = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Reseller');
		insert objAcct;
		System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :objAcct.Id], 'Account count not matching');
		objAcct.Name = null;

		try {
			update objAcct;
		} catch (DMLException e) {
			System.assert(true, 'Exception Occurred during updating account');
		}
		objAcct.Name = 'NewName';
		update objAcct;
		System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :objAcct.Id], 'Account count not matching');

		delete objAcct;

		System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id = :objAcct.Id], 'Account count not matching after deleting');
		objAcct = [SELECT Id FROM Account WHERE Id = :objAcct.Id LIMIT 1 ALL ROWS];
		undelete objAcct;
		System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :objAcct.Id], 'Account count not matching after un-deleting');
	}

	/**
	 * @author:         Prity Kumari
	 * @description:    Test if Discovery Survey Duplicate Accounts are assigned to Partner House
	 */
	@isTest
	static void testDiscoverySurveyDupe() {
		User objUser = [SELECT Id, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.DeveloperName LIKE :AccountUtil.SALES_PARTNER_MANAGER_ROLE LIMIT 1];
		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Discovery Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('my18.com')
			.build();

		insert objResellerAcc;

		Test.startTest();
		Account objResellerAcc1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Discovery Account1')
			.setOnboardingFlow('In-App')
			.setZPFirmId('456111111111')
			.setNormalizedEmailDomain('my18.com')
			.setOwnerId(objUser.Id)
			.build();
		insert objResellerAcc1;
		Test.stopTest();

		objResellerAcc1 = [SELECT OwnerId FROM Account WHERE ZP_Firm_ID__c = '456111111111'];
		System.assertEquals(objResellerAcc1.OwnerId, Label.Partner_House_Account, 'Owner not marching Partner House Account Owner.');
	}

	/**
	 * @description data from lead on account
	 */
	@isTest
	static void dataFromLeadConversionTest() {
		Lead objLead = new Lead(LastName = 'Test', FirstName = 'Tester', Status = 'Raw', Company = 'ACCOUNTNAME', ZP_Company_ID__c = '12345678901');

		Test.startTest();
		insert objLead;

		Database.LeadConvert objLeadConvert = new database.LeadConvert();
		objLeadConvert.setLeadId(objLead.Id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);

		Database.LeadConvertResult lcr = Database.convertLead(objLeadConvert);
		Test.stopTest();
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = :'ACCOUNTNAME'];
		System.assert(objAccount != null, 'Account was not created from lead conversion.');
	}

	/**
	 * @description insert/update new reseller account
	 */
	@isTest
	static void insertResellerAccountTest() {
		//create reseller account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('partner Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('1223345')
			.build();

		Test.startTest();
		insert objAccount;

		Account objAccountAssert = [SELECT Id, Name FROM Account WHERE Id = :objAccount.Id];
		System.assert(objAccountAssert != null, 'Error during account creation.');

		objAccount.Name = 'Name updated';
		objAccount.ZP_Firm_ID__c = '3456543';
		update objAccount;
		Test.stopTest();
	}

	/**
	 * @description insert/update new company account
	 */
	@isTest
	static void insertCompanyAccountTest() {
		//create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('4567876')
			.build();

		Test.startTest();
		insert objAccount;

		Account objAccountAssert = [SELECT Id, Name FROM Account WHERE Id = :objAccount.Id];
		System.assert(objAccountAssert != null, 'Error during account creation');

		objAccount.ZP_Company_Overall_Status__c = 'Suspended';
		objAccount.ZP_Company_ID__c = '45673336';
		objAccount.Name = 'Name updated';
		update objAccount;
		Test.stopTest();
	}

	/**
	 * @description test account Benefit_Deduction_Category__c field value populated on change of BillingState from ZP_HI_Deduction__c object
	 * @author Nigam Goyal | 04-21-2023
	 **/
	@isTest
	static void testAccountFieldsPopulateOnBillingStateChange() {
		Utils.skipTrigger(true);
		List<Account> list_Accounts = new List<Account>();

		Account objAcctCaliforniaState = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Demo Account')
			.setZPCompanyId('56465453434')
			.setBillingState('California')
			.setBillingCountry('United States')
			.build();
		list_Accounts.add(objAcctCaliforniaState);

		Account objAcctNoState = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account 1').setZPCompanyId('77885453434').build();
		list_Accounts.add(objAcctNoState);

		Account objAcctValidState = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Account 2')
			.setBillingCountry('United States')
			.setZPCompanyId('88775453434')
			.setBillingState('California')
			.build();
		list_Accounts.add(objAcctValidState);

		Account objAcctInvalidState = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Account 3')
			.setBillingCountry('United States')
			.setZPCompanyId('9877545344')
			.setBillingState('Rhode Island')
			.build();
		list_Accounts.add(objAcctInvalidState);

		insert list_Accounts;
		Utils.skipTrigger(false);

		Test.startTest();
		List<ZP_HI_Deduction__c> list_Deductions = new List<ZP_HI_Deduction__c>{
			new TestDataFactory.ZPHIDeductionBuilder().setName('Test - No State').setCompanyId('77885453434').setActiveEECount(6).setCarrier('Aetna,Other').setMedicalCarriersSupported(true).build(), // BYB
			new TestDataFactory.ZPHIDeductionBuilder().setName('Test - HI State').setCompanyId('88775453434').setActiveEECount(3).setCarrier('Aetna,Other').setMedicalCarriersSupported(true).build(), // BoR Partial
			new TestDataFactory.ZPHIDeductionBuilder().setName('Test - CA State').setCompanyId('56465453434').setActiveEECount(3).setCarrier('Aetna').setMedicalCarriersSupported(true).build() // BoR
		};

		insert list_Deductions;
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 10);
		Test.stopTest();

		List<Account> list_AccountsFetch = [
			SELECT Id, Benefit_Deduction_Category__c, ZP_Company_Id__c, BillingState, BillingStateCode
			FROM Account
			WHERE ZP_Company_Id__c IN ('77885453434', '88775453434', '56465453434')
		];

		Account objAccountWithBillingState = new Account();

		for (Account objAccount : list_AccountsFetch) {
			if (objAccount.ZP_Company_Id__c == '77885453434') {
				System.assertEquals('BYB', objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
				objAccountWithBillingState.BillingState = 'California';
				objAccountWithBillingState.BillingStateCode = 'CA';
				objAccountWithBillingState.BillingCountry = 'United States';
				objAccountWithBillingState.BillingCountryCode = 'US';
				objAccountWithBillingState.Id = objAccount.Id;
			}

			if (objAccount.ZP_Company_Id__c == '88775453434') {
				System.assertEquals('BoR Partial', objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
			}

			if (objAccount.ZP_Company_Id__c == '56465453434') {
				System.assertEquals('BoR', objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
			}
		}

		update objAccountWithBillingState;
	}

	/**
	 * @description updating description field
	 */
	@isTest
	static void updateAccountDescTest() {
		Account objAccount = [SELECT Id, Name, Description FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_Id__c = '1234567890'];
		objAccount.Description = 'account record updated';
		Test.startTest();
		update objAccount;

		Account objAccountAssert = [SELECT Id, Name, Description FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals('account record updated', objAccountAssert.Description, 'Error during account update.');
		Test.stopTest();
	}

	/**
	 * @description creation from reseller lead conversion
	 */
	@isTest
	static void testCreateAcctFrmResllrLeadConversion() {
		Lead objLead = new Lead(FirstName = 'firstname', Company = 'Company Name', LastName = 'LirikTest', Email = 'gustolead@gusto.Test.com', RecordTypeId = LeadUtil.RESELLER_LEAD_RT_ID);

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');
		Test.startTest();
		Database.LeadConvert objLeadConvert = new Database.LeadConvert();
		objLeadConvert.setLeadId(objLead.Id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		objLeadConvert.donotcreateopportunity = true;
		Database.LeadConvertResult lcr = Database.convertLead(objLeadConvert);

		objLead = [SELECT Id, Visitor_Id__c, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.ConvertedAccountId != null, 'Error during lead conversion.');
		Test.stopTest();
	}

	/**
	 * @description creation from company lead conversion
	 */
	@isTest
	static void testCreateAcctFrmCompanyLeadConversion() {
		Lead objLead = new Lead(
			FirstName = 'firstname',
			Company = 'Company Name',
			ZP_Company_ID__c = '12345678902',
			LastName = 'LirikTest',
			Email = 'gustolead@gusto.Test.com',
			RecordTypeId = LeadUtil.COMPANY_LEAD_RT_ID
		);
		Test.startTest();
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Database.LeadConvert objLeadConvert = new Database.LeadConvert();
		objLeadConvert.setLeadId(objLead.Id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		objLeadConvert.donotcreateopportunity = true;
		Database.LeadConvertResult lcr = Database.convertLead(objLeadConvert);

		objLead = [SELECT Id, Visitor_Id__c, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.ConvertedAccountId != null, 'Error during lead conversion.');
		Account objAccountAssert = [SELECT Name FROM Account WHERE Id = :objLead.ConvertedAccountId];
		System.assertequals('Company Name', objAccountAssert.Name, 'Account name not matching lead company name');
		Test.stopTest();
	}

	/**
	 * @description creation from resller  lead conversion
	 */
	@isTest
	static void testCreateAcctFrmResellerLeadConversion() {
		Lead objLead = new Lead(FirstName = 'firstname', Company = 'Company Name', LastName = 'LirikTest', Email = 'gustolead@gusto.Test.com', RecordTypeId = LeadUtil.RESELLER_LEAD_RT_ID);
		Test.startTest();
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Database.LeadConvert objLeadConvert = new Database.LeadConvert();
		objLeadConvert.setLeadId(objLead.Id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		objLeadConvert.donotcreateopportunity = true;
		Database.LeadConvertResult lcr = Database.convertLead(objLeadConvert);

		objLead = [SELECT Id, Visitor_Id__c, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.ConvertedAccountId != null, 'Error during lead conversion.');

		Account objAccountAssert = [SELECT Name FROM Account WHERE Id = :objLead.ConvertedAccountId];
		System.assertequals('Company Name', objAccountAssert.Name, 'Account name not matching lead company name');
		Test.stopTest();
	}

	/**
	 * @description updating sold by/ Referred By field
	 */
	@isTest
	static void testSoldRefByUpdateonAccount() {
		Account objAccountReseller = [SELECT Id, Name, Description FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID];

		//create reseller account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('partner Account').setOnboardingFlow('In-App').build();

		objAccount.Sold_By__c = objAccountReseller.Id;
		Test.startTest();
		insert objAccount;

		Account objAccountAssert = [SELECT Id, Sold_By__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objAccountReseller.Id, objAccountAssert.Sold_By__c, 'Sold by id not matching with reseller id.');

		objAccount.Referred_By__c = objAccountReseller.Id;
		objAccount.Sold_By__c = null;
		objAccount.ZP_Company_Approval_Status__c = 'Approved';
		update objAccount;

		Task objTask = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :objAccountReseller.Id AND CreatedDate = TODAY LIMIT 1];
		System.assertEquals(objAccount.Name + ' - ' + ' Just got approved', objTask.Subject, 'Error during task creation');

		objAccountAssert = [SELECT Id, Referred_By__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objAccountReseller.Id, objAccountAssert.Referred_By__c, 'Referred by id not matching with reseller id.');
		Test.stopTest();
	}

	/**
	 * @description updating description field
	 */
	@isTest
	static void testgetOrderInformation() {
		Account objAccount = [SELECT Id, Name, Description FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_Id__c = '1234567890'];
		Opportunity objOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :objAccount.Id LIMIT 1];

		ZP_Company_Onboarding_Funnel__c objZPCompOnFunnel = new ZP_Company_Onboarding_Funnel__c();
		objZPCompOnFunnel.Company_Id__c = '1234567890';
		insert objZPCompOnFunnel;

		Order objOrder = new Order();
		objOrder.AccountId = objAccount.Id;
		objOrder.OpportunityId = objOpportunity.Id;
		objOrder.EffectiveDate = date.today();
		objOrder.Status = 'Drafted';
		OrderTriggerHelper.skipTrigger = true;
		insert objOrder;
		OrderTriggerHelper.skipTrigger = false;

		Order_Facilitator_Checklist__c objOrderFacilator = new Order_Facilitator_Checklist__c();
		objOrderFacilator.Is_Checked__c = true;
		objOrderFacilator.Sequence__c = 2;
		objOrderFacilator.Order__c = objOrder.Id;
		OrderFacilitatorChecklistTriggerHelper.skipTrigger = true;
		insert objOrderFacilator;
		OrderFacilitatorChecklistTriggerHelper.skipTrigger = false;

		objAccount.ZP_Company_Approval_Status__c = 'Request for Information';
		objAccount.Description = 'account record updated';

		Test.startTest();
		update objAccount;

		Account objAccAssert = [SELECT Id, Date_of_RFI__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(System.today(), objAccAssert.Date_of_RFI__c, 'RFI Date not updated on account.');
		Test.stopTest();
	}

	/**
	 * @description create new account related tracking record
	 */
	@isTest
	static void testgetAccountRelatedTracking() {
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('4567876')
			.build();

		Test.startTest();
		insert objAccount;

		objAccount.Account_Priority__c = '2';
		objAccount.No_of_Clients__c = 4;
		update objAccount;

		List<Account_Related_Tracking__c> list_acctRelated = [SELECT Id FROM Account_Related_Tracking__c WHERE Account__c = :objAccount.Id];
		System.assertEquals(1, list_acctRelated.size(), 'Account related tracking not created.');
		Test.stopTest();
	}

	//to  cover updatePartnerChildAccounts
	@isTest
	static void testupdatePartnerChildAccounts() {
		Account objCOmAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1223345')
			.build();

		TriggerHandler.bypass('AccountTriggerHandler');
		insert objCOmAccount;

		//create reseller account
		Account objResellerAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setOnboardingFlow('In-App').build();

		objResellerAccount1.Sold_By__c = objCOmAccount.Id;
		Test.startTest();
		insert objResellerAccount1;
		TriggerHandler.clearBypass('AccountTriggerHandler');
		objResellerAccount1.Benefits_Email_Opt_Out__c = '401k';
		objResellerAccount1.Apply_to_all_clients__c = true;

		update objResellerAccount1;

		List<Account> list_Accounts = [SELECT Id, Apply_to_all_clients__c FROM Account WHERE Id = :objResellerAccount1.Id LIMIT 1];
		System.assertEquals(true, list_Accounts[0].Apply_to_all_clients__c, 'Child Partner Account need to be updated');

		Test.stopTest();
		System.assertEquals(true, objResellerAccount1.Apply_to_all_clients__c, 'Updated Incorrectly');
	}

	//to cover getPartnershpInterest
	@isTest
	static void testgetPartnershpInterest() {
		//create reseller account
		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('4567876')
			.build();
		Test.startTest();
		insert objResellerAccount;

		// Get org default tier config settings and assert new tier 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Tier_1__c, 'Tier config not created.');

		//create Partnership_Interest__c record
		Partnership_Interest__c objPartInt = new Partnership_Interest__c();
		objPartInt.Account__c = objResellerAccount.Id;
		insert objPartInt;

		// Replacing 'Core' with new Tier 1 from custom settings
		objResellerAccount.Tier__c = objTierConfig.New_Tier_1__c;
		update objResellerAccount;

		Partnership_Interest__c objPInt = [SELECT Id, Current_Tier__c, Date_Tier_Changed__c, Account__c FROM Partnership_Interest__c WHERE Id = :objPartInt.Id];
		//System.assertEquals(objTierConfig.New_Tier_1__c, objPInt.Current_Tier__c, 'Tier not matching on Partnership interest.');
		Test.stopTest();
	}

	//to cover  retriveCompletedSteps
	@isTest
	static void testretriveCompletedSteps() {
		Account objAccount = [SELECT Id, Name, Description FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_Id__c = '1234567890'];
		Opportunity objOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :objAccount.Id LIMIT 1];

		ZP_Company_Onboarding_Funnel__c objZPCompOnFunnel = new ZP_Company_Onboarding_Funnel__c();
		objZPCompOnFunnel.Company_Id__c = '1234567890';
		objZPCompOnFunnel.Create_User_Account_Completed__c = true;
		objZPCompOnFunnel.Add_Addresses_Completed__c = true;
		objZPCompOnFunnel.Add_Employees_Completed__c = true;
		objZPCompOnFunnel.Federal_Tax_Setup_Completed__c = true;
		objZPCompOnFunnel.State_Setup_Completed__c = true;
		objZPCompOnFunnel.Add_Bank_Info_Completed__c = true;
		objZPCompOnFunnel.Payroll_Schedule_Completed__c = true;
		objZPCompOnFunnel.Previous_Paystubs_Completed__c = true;
		objZPCompOnFunnel.Add_Signatory_Completed__c = true;
		objZPCompOnFunnel.Sign_All_Forms_Completed__c = true;
		objZPCompOnFunnel.Verify_Bank_Info_Completed__c = true;
		objZPCompOnFunnel.Historical_Liabilities_Completed__c = true;
		insert objZPCompOnFunnel;

		Order objOrder = new Order();
		objOrder.AccountId = objAccount.Id;
		objOrder.OpportunityId = objOpportunity.Id;
		objOrder.EffectiveDate = Date.today();
		objOrder.Status = 'Drafted';
		OrderTriggerHelper.skipTrigger = true;
		insert objOrder;
		OrderTriggerHelper.skipTrigger = false;

		Order_Facilitator_Checklist__c objOrderFacilator = new Order_Facilitator_Checklist__c();
		objOrderFacilator.Is_Checked__c = true;
		objOrderFacilator.Sequence__c = 2;
		objOrderFacilator.Order__c = objOrder.Id;
		OrderFacilitatorChecklistTriggerHelper.skipTrigger = true;
		insert objOrderFacilator;
		OrderFacilitatorChecklistTriggerHelper.skipTrigger = false;

		objAccount.ZP_Company_Approval_Status__c = 'Request for Information';
		objAccount.Description = 'account record updated';

		Test.startTest();
		update objAccount;
		Test.stopTest();
		Order objOrderAssert = [SELECT Id, Onboarding_Steps_Completed__c FROM Order WHERE Id = :objOrder.Id];
		// Verify the expected result
		String strExpected = 'Create User Account,Add Addresses,Add Employees,Federal Tax Setup,State Setup,Add Bank Info,Payroll Schedule,Previous Paystubs,Add Signatory,Sign All Forms,Verify Bank Info ,Historical Liabilities';
		System.assertEquals(strExpected, objOrderAssert.Onboarding_Steps_Completed__c, 'retriveCompletedSteps is setting Onboarding_Steps_Completed__c incorrectly');
	}

	//to cover  setOpportunityJoinDateInfo
	@isTest
	static void testsSetOpportunityJoinDateInfo() {
		Account objAccount = [SELECT Id, Name, Description FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_Id__c = '1234567890'];

		objAccount.Joined_Date_Panda__c = Date.today();
		Test.startTest();
		update objAccount;
		Test.stopTest();

		Opportunity objOpportunity_assert = [
			SELECT Id, AccountId, Joined_Date_Panda__c
			FROM Opportunity
			WHERE AccountId = :objAccount.Id AND RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID
			LIMIT 1
		];
		System.assertEquals(objAccount.Joined_Date_Panda__c, objOpportunity_assert.Joined_Date_Panda__c, 'Join date not updated on Opportunity.');

		Opportunity objOpportunity_benefitAssert = [
			SELECT Id, AccountId, Closed_Won_Eligible__c
			FROM Opportunity
			WHERE AccountId = :objAccount.Id AND RecordTypeId = :OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID
			LIMIT 1
		];
		System.assertEquals(true, objOpportunity_benefitAssert.Closed_Won_Eligible__c, 'Closed Won Eligible not updated on Opportunity');
	}

	//to cover getTaxAuditCaseInformation
	@isTest
	static void testgetTaxAuditCaseInformation() {
		//create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('4567876')
			.build();

		Test.startTest();
		insert objAccount;

		Account objAccountAssert = [SELECT Id, Name FROM Account WHERE Id = :objAccount.Id];
		System.assert(objAccountAssert != null, 'Error during Account creation.');

		objAccount.Taxable_as_Scorp__c = true;
		objAccount.Has_Benefits__c = true;

		CaseTriggerHelper.skipTrigger = true;
		update objAccount;
		Test.stopTest();

		Case objCaseAssert = [SELECT Id, AccountId FROM Case WHERE AccountId = :objAccount.Id AND CreatedDate = TODAY LIMIT 1];
		System.assert(objCaseAssert != null, 'Error during Case creation.');
	}

	@isTest
	static void testBenefitOptOutSyncforBatchJob() {
		List<Account> list_Accounts = new List<Account>();
		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Test Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('7777789')
			.build();

		objResellerAccount.Benefits_Email_Opt_Out__c = 'Health Insurance';
		objResellerAccount.Apply_to_all_clients__c = true;
		list_Accounts.add(objResellerAccount);

		Account objResellerAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Test Account1')
			.setOnboardingFlow('In-App')
			.setZPFirmId('77557789')
			.build();

		objResellerAccount1.Benefits_Email_Opt_Out__c = 'Health Insurance';
		objResellerAccount1.Apply_to_all_clients__c = true;
		list_Accounts.add(objResellerAccount1);

		TriggerHandler.bypass('AccountTriggerHandler');
		insert list_Accounts;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Test.startTest();
		list_Accounts[0].Benefits_Email_Opt_Out__c = 'Health Insurance;Workers Comp';
		list_Accounts[1].Benefits_Email_Opt_Out__c = 'Health Insurance';
		update list_Accounts;
		Test.stopTest();

		list_Accounts = [SELECT Id, Benefit_Opt_Out_Sync__c FROM Account WHERE Id = :list_Accounts];
		System.assertEquals(true, list_Accounts[0].Benefit_Opt_Out_Sync__c, 'Benefits opt out not set to true');
		System.assertEquals(false, list_Accounts[1].Benefit_Opt_Out_Sync__c, 'Benefits opt out not set to false');
	}

	// Testing different scenarios of setting sales engagement statuses
	/**
	 * @author      Praveen Sethu
	 * @description Test Sales Engagement Status and Detail are updated are to Ramp and Firm/Accountant Onboarding
	 **/
	@isTest
	static void testAccountantActiveSalesEngagementStatus() {
		Account objResellerAccount = TestUtils.createAccount(AccountUtil.RESELLER_ACCOUNT_RT_ID, 'Test Reseller Account 1', true);

		Test.startTest();

		objResellerAccount.Cohort_Date__c = Date.today();
		update objResellerAccount;

		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Sales_Engagement_Status__c, Sales_Engagement_Date__c, Calculate_Reseller_Metrics__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(AccountUtil.SALES_ENGMNT_STATUS_ACTIVE, objAccountAssert.Sales_Engagement_Status__c, 'Sales Engagement Status not updated');
		System.assertEquals(true, objAccountAssert.Calculate_Reseller_Metrics__c, 'Calculate_Reseller_Metrics__c not updated');
		System.assertEquals(Date.today(), objAccountAssert.Sales_Engagement_Date__c, 'Sales Engagement Date not updated');
	}
	/**
	 * @author      Praveen Sethu
	 * @description Test Sales Engagement Status and Detail are updated are to Ramp and Firm/Accountant Onboarding
	 **/
	@isTest
	static void testAccountantProspectiveSalesEngagementStatus() {
		Test.startTest();
		Account objResellerAccount = TestUtils.createAccount(AccountUtil.RESELLER_ACCOUNT_RT_ID, 'Test Reseller Account 1', true);
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Sales_Engagement_Status__c, Sales_Engagement_Status_Detail__c, Sales_Engagement_Date__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(AccountUtil.SALES_ENGMNT_STATUS_PROSPECTIVE, objAccountAssert.Sales_Engagement_Status__c, 'Sales Engagement Status not updated');
		System.assertEquals(Date.today(), objAccountAssert.Sales_Engagement_Date__c, 'Sales Engagement Date not updated');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Sales Engagement Status Automation Does not Run When Sales User Updates Record
	 **/
	@isTest
	static void testManualOverrideBySalesUser() {
		User objSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.developerName = 'sales_partner_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		Account objResellerAccount = TestUtils.createAccount(AccountUtil.RESELLER_ACCOUNT_RT_ID, 'Test Reseller Account 1', true);

		Test.startTest();
		if (objSalesUser != null) {
			System.runAs(objSalesUser) {
				objResellerAccount.Cohort_Date__c = Date.today();
				objResellerAccount.Sales_Engagement_Status__c = AccountUtil.SALES_ENGMNT_STATUS_CHURNED;
				update objResellerAccount;
			}
		}
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Sales_Engagement_Status__c, Sales_Engagement_Status_Detail__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(AccountUtil.SALES_ENGMNT_STATUS_CHURNED, objAccountAssert.Sales_Engagement_Status__c, 'Sales Engagement Status not updated');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Normalized Email Domain is set to domain of earliest created contact
	 **/
	@isTest
	static void testNormalizedEmailDomainUpdate() {
		Test.startTest();
		LeadTriggerHelper.skipTrigger = true;
		// Create a new reseller lead and convert them to created accounts and contacts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@normalizeddomain.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead 1')
			.setLeadSource('LinkedIn')
			.build();
		insert objLead;
		Test.stopTest();

		OpportunityTriggerHelper.skipTrigger = true;

		// Convert Lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });

		Lead objLeadAssert = [SELECT Id, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id = :objLead.Id AND IsConverted = TRUE];
		Account objAccount = new Account(Id = objLeadAssert.ConvertedAccountId);
		update objAccount;

		Contact objContactAssert = [SELECT Id, Normalized_Email_Domain__c FROM Contact WHERE Id = :objLeadAssert.ConvertedContactId];
		Account objAccountAssert = [SELECT Id, Normalized_Email_Domain__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];

		System.assertNotEquals(null, objAccountAssert.Normalized_Email_Domain__c, 'Normalized email domain not populated.');
		System.assertEquals(objContactAssert.Normalized_Email_Domain__c, objAccountAssert.Normalized_Email_Domain__c, 'Normalized email domain not matching Contact.');

		// Create second contact for the same reseller account to test if normalized email domain on account changes
		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Reseller')
			.setAccountId(objAccountAssert.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@secondcontact.com')
			.build();
		insert objContact2;

		objContactAssert = [SELECT Id, Normalized_Email_Domain__c FROM Contact WHERE Id = :objLeadAssert.ConvertedContactId];
		objAccountAssert = [SELECT Id, Normalized_Email_Domain__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];

		System.assertNotEquals(null, objAccountAssert.Normalized_Email_Domain__c, 'Normalized email domain not populated.');
		System.assertEquals(objContactAssert.Normalized_Email_Domain__c, objAccountAssert.Normalized_Email_Domain__c, 'Normalized email domain not matching Contact.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Offers Health Insurance update on Opportunity
	 **/
	@isTest
	static void testOffersHealthInsuranceUpdate() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();

		objCompAccount.Offers_Health_Insurance__c = 'Yes';
		insert objCompAccount;

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		objOpportunity.ZP_Company_ID__c = '1111111111';
		objOpportunity.Offers_Health_Insurance__c = 'Yes';
		insert objOpportunity;

		objCompAccount.Offers_Health_Insurance__c = 'No';

		Test.startTest();
		update objCompAccount;
		Test.stopTest();

		TriggerHandler.clearBypass('OpportunityTriggerHandler');

		Opportunity objAssertOpportunity = [SELECT Id, Name, Offers_Health_Insurance__c FROM Opportunity WHERE Id = :objOpportunity.Id];

		System.assertEquals(objAssertOpportunity.Offers_Health_Insurance__c, objCompAccount.Offers_Health_Insurance__c, 'Offers Health Insurance not updated on Opportunity.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Offers Health Insurance value should not get updated on Opportunity in case of null value on Account
	 **/
	@isTest
	static void testOffersHealthInsuranceNullUpdate() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();

		objCompAccount.Offers_Health_Insurance__c = 'Yes';
		insert objCompAccount;

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		objOpportunity.ZP_Company_ID__c = '1111111111';
		objOpportunity.Offers_Health_Insurance__c = 'Yes';
		insert objOpportunity;

		objCompAccount.Offers_Health_Insurance__c = '';

		Test.startTest();
		update objCompAccount;
		Test.stopTest();

		TriggerHandler.clearBypass('OpportunityTriggerHandler');

		Opportunity objAssertOpportunity = [SELECT Id, Name, Offers_Health_Insurance__c FROM Opportunity WHERE Id = :objOpportunity.Id];

		System.assertNotEquals('', objAssertOpportunity.Offers_Health_Insurance__c, 'Offers Health Insurance not populated on Opportunity.');
	}

	/**
	 * @author      Veeresh Kumar
	 * @description Asserts if Old Account Owner is set
	 **/
	@isTest
	static void testsetAccountOldOwner() {
		Set<String> set_UserRoleNames = new Set<String>{ AccountUtil.SALES_PARTNER_AE_ROLE, AccountUtil.SALES_PARTNER_MANAGER_ROLE };
		Map<String, User> map_UserRoleNameToUsers = new Map<String, User>();

		for (User objUser : [SELECT Id, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.developerName IN :set_UserRoleNames]) {
			map_UserRoleNameToUsers.put(objUser.UserRole.developerName, objUser);
		}

		if (map_UserRoleNameToUsers.containsKey(AccountUtil.SALES_PARTNER_AE_ROLE) && map_UserRoleNameToUsers.containsKey(AccountUtil.SALES_PARTNER_MANAGER_ROLE)) {
			User objPartnerAEUser = map_UserRoleNameToUsers.get(AccountUtil.SALES_PARTNER_AE_ROLE);
			User objPartnerManagerUser = map_UserRoleNameToUsers.get(AccountUtil.SALES_PARTNER_MANAGER_ROLE);

			Account objCompanyAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account Old Owner')
				.setZPCompanyId('1111111111')
				.setOwnerId(objPartnerAEUser.Id)
				.build();

			TriggerHandler.bypass('AccountTriggerHandler');
			insert objCompanyAccount;
			TriggerHandler.clearBypass('AccountTriggerHandler');

			Account objCompanyAccountAssert = [SELECT Id, OwnerId, Owner.UserRoleId FROM Account WHERE Id = :objCompanyAccount.Id];

			// Insert Asserts:
			System.assertEquals(objPartnerAEUser.Id, objCompanyAccountAssert.OwnerId, 'Account not routed to AE Rep.');
			System.assertEquals(objPartnerAEUser.UserRoleId, objCompanyAccountAssert.Owner.UserRoleId, 'Account Owner Role not matching partner AE Role.');

			Test.startTest();
			objCompanyAccount.OwnerId = objPartnerManagerUser.Id;
			update objCompanyAccount;
			Test.stopTest();

			Account objCompanyAccountUpdateAssert = [SELECT Id, Old_Owner__c, OwnerId, Owner.UserRoleId FROM Account WHERE Id = :objCompanyAccount.Id];

			// Update Asserts:
			System.assertEquals(objPartnerManagerUser.Id, objCompanyAccountUpdateAssert.OwnerId, 'Account Owner Not updated');
			System.assertEquals(objPartnerManagerUser.UserRoleId, objCompanyAccountUpdateAssert.Owner.UserRoleId, 'Account owner user role not matching.');
			System.assertEquals(objPartnerAEUser.Id, objCompanyAccountUpdateAssert.Old_Owner__c, 'Account owner role not changed from AE rep.');
		}
	}
	/**
	 * @author      Prity Kumari
	 * @description Asserts if Closed Owner Role Values are populated on Oppty
	 **/
	@isTest
	static void testsetClosedOwnerDeatilsAndPrioritySupport() {
		User objSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.developerName = 'sales_partner_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		Account objAccount = [SELECT Id, OwnerId FROM Account WHERE ZP_Company_ID__c = '1234567890'];
		Test.startTest();
		objAccount.OwnerId = objSalesUser.Id;
		objAccount.Additional_Services__c = AccountUtil.ADD_SERVICES_PRIORITY_SUPPORT;
		objAccount.Priority_Support__c = true;
		update objAccount;
		Test.stopTest();
		Opportunity objAssertOpp = [
			SELECT Id, AccountId, OwnerId, Owner_Department__c, Owner_Division__c, Owner_Role__c, Owner_Title__c, MDR__c, MDR_Lead_Owner_Role__c, MDR_Received__c, Additional_Opportunity_Services__c
			FROM Opportunity
			WHERE AccountId = :objAccount.Id AND RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID
		];
		System.assertEquals(objAssertOpp.OwnerId, objSalesUser.Id, 'Account owner is incorrect');
		//System.assertEquals(AccountUtil.ADD_SERVICES_PRIORITY_SUPPORT, objAssertOpp.Additional_Opportunity_Services__c, 'Additional Opportunity Services is incorrect on opportunity.');
	}

	/**
	 * @author      Veeresh Kumar
	 * @description Asserts whether child Company Opportunities are closed, when Joined_Date_Panda__c is set on Account.
	 **/
	@isTest
	static void testCloseCompanyOpportunitiesIfJoinedDateIsSet() {
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();

		TriggerHandler.bypass('AccountTriggerHandler');
		insert objCompanyAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objCompanyAccount.Id)
			.setStage(OpportunityUtil.MQL_STAGE)
			.setCloseDate(System.today())
			.setZPCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.build();

		OpportunityTriggerHelper.skipTrigger = true;
		insert objOpportunity;
		TriggerHandler.clearBypass('OpportunityTriggerHandler');

		Test.startTest();
		objCompanyAccount.Joined_Date_Panda__c = System.today();
		update objCompanyAccount;
		Test.stopTest();

		Opportunity objOpportunityAssert = [SELECT Id, CloseDate, StageName, Joined_Date_Panda__c FROM Opportunity WHERE Id = :objOpportunity.Id];

		// Opportunity Update Asserts:
		System.assertEquals(objCompanyAccount.Joined_Date_Panda__c, objOpportunityAssert.CloseDate, 'Opportunity Close Date not matching account joined date.');
		System.assertEquals(objCompanyAccount.Joined_Date_Panda__c, objOpportunityAssert.Joined_Date_Panda__c, 'Opportunity Joined Date not matching account joined date.');
		System.assertEquals(OpportunityUtil.CLOSED_WON_STAGE, objOpportunityAssert.StageName, 'Opportunity stage not updated to Closed Won');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Asserts if Website info is updated when Account is inserted
	 **/
	@isTest
	static void testWebsiteDataOnInsert() {
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('1111111111')
			.setNormalizedEmailDomain('employer.com')
			.build();

		Test.startTest();
		insert objCompanyAccount;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Website FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals('www.employer.com', objAccountAssert.Website, 'Website not updated on account.');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Asserts if Website info is updated when a new Contact is inserted
	 **/
	@isTest
	static void testWebsiteDataOnContactInsert() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		insert objCompanyAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Test.startTest();
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('newemp@employer.com')
			.build();
		insert objContact;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Website FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals('www.employer.com', objAccountAssert.Website, 'Website not updated on Account.');
	}

	/**
	 * @author      Sandeep Golla
	 * @description Assert if change in Reseller account owner populates on related contacts
	 **/
	@isTest
	static void testContactOwnerChangeBasedOnAccountOwner() {
		User objSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.developerName = 'sales_partner_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];

		Account objAccount = [SELECT Id, OwnerId FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_Id__c = '1234567890'];

		Test.startTest();
		objAccount.OwnerId = objSalesUser.Id;
		update objAccount;
		Test.stopTest();

		Contact objContact = [SELECT Id, Name, AccountId, OwnerId FROM Contact WHERE AccountId = :objAccount.Id LIMIT 1];

		System.assertEquals(objAccount.OwnerId, objContact.OwnerId, 'Contact owner not updated based on account.');
	}

	/**
	 * @author      Sandeep Golla
	 * @description Assert if lead owner is same as Account owner after lead conversion
	 **/
	@isTest
	static void testResellerAccOwnerChangeOnConversion() {
		User objSalesUser = [SELECT Id, FirstName, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.developerName = 'sales_partner_xx_xx_mgr' AND IsActive = TRUE LIMIT 1];
		objSalesUser.FirstName = 'Marketo';
		update objSalesuser;

		System.runAs(objSalesuser) {
			ZPAccountingFirmTriggerHelper.queue = true;

			// Create a new reseller lead and convert them to created accounts and contacts
			Lead objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.LABEL_RESELLER)
				.setFirstName('FName')
				.setLastName('LName')
				.setEmail('Test.test@gusto.com')
				.setPhone('123456789')
				.setCompany('Reseller Lead 1')
				.setLeadSource('Direct')
				.setZPFirmId('3278943681')
				.build();
			insert objLead;

			Test.startTest();
			ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
				.setZPFirmId('3278943681')
				.setEmail('Test.test@gusto.com')
				.setName('FName LName')
				.setProcessingState('Queued')
				.build();
			insert objZPAccFirm;

			Lead objLeadAssert = [SELECT Id, OwnerId, ConvertedAccountId, ConvertedContactId FROM Lead WHERE ZP_Firm_ID__c = '3278943681' AND IsConverted = TRUE];

			Account objAccountAssert = [SELECT Id, OwnerId, Normalized_Email_Domain__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
			System.assertEquals(objLeadAssert.OwnerId, objAccountAssert.OwnerId, 'Reseller owner not update on lead conversion.');
			Test.stopTest();
		}
	}

	/**
	 * @author      Veeresh kumar
	 * @description Assert if Calendar Link is set based on the Owner.
	 **/
	@isTest
	static void testIfOwnerCalendarLinkIsSet() {
		User objIntegrationUser;
		user objcurrentUser;
		Account objCompanyAccount;
		Account objCompanyAccountAssert;

		for (User objUser : [SELECT Id, Calendar_Link__c, Email FROM User WHERE Email = 'testIntegrationUser@account.com' OR Id = :UserInfo.getUserId()]) {
			if (objUser.Id == UserInfo.getUserId()) {
				objcurrentUser = objUser;
			} else if (objUser.Email == 'testIntegrationUser@account.com') {
				objIntegrationUser = objUser;
			}
		}

		Test.startTest();

		System.runAs(objIntegrationUser) {
			objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Account1').build();

			insert objCompanyAccount;
		}

		objCompanyAccountAssert = [SELECT Id, Account_Owner_Calendar_Link__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(objIntegrationUser.Calendar_Link__c, objCompanyAccountAssert.Account_Owner_Calendar_Link__c, 'Calendar link not updated on account.');

		User objUserToAssignAsOwner = [SELECT Id, Calendar_Link__c, Email FROM User WHERE Email = 'admin@testorg.com' LIMIT 1];
		objCompanyAccount.OwnerId = objUserToAssignAsOwner.Id;
		update objCompanyAccount;

		Test.stopTest();

		objCompanyAccountAssert = [SELECT Id, Account_Owner_Calendar_Link__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(objCurrentUser.Calendar_Link__c, objCompanyAccountAssert.Account_Owner_Calendar_Link__c, 'Calendar link not updated on account.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Potential Fraud field update
	 **/
	@isTest
	static void testPotentialFraudHistoryUpdate1() {
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		objCompanyAccount.Potential_Fraud_Account__c = true;

		Test.startTest();
		insert objCompanyAccount;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Potential_Fraud_History__c FROM Account WHERE Id = :objCompanyAccount.Id];

		System.assertEquals(true, objAccountAssert.Potential_Fraud_History__c, 'Account not marked as potential fraud.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Potential Fraud field update
	 **/
	@isTest
	static void testPotentialFraudHistoryUpdate2() {
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		objCompanyAccount.Potential_Fraud_Account__c = true;

		Test.startTest();
		insert objCompanyAccount;
		Test.stopTest();

		objCompanyAccount.Potential_Fraud_Account__c = false;
		update objCompanyAccount;

		Account objAccountAssert = [SELECT Id, Potential_Fraud_History__c FROM Account WHERE Id = :objCompanyAccount.Id];

		System.assertEquals(true, objAccountAssert.Potential_Fraud_History__c, 'Account not marked as potential fraud.');
	}

	/**
	 * @author      Veeresh kumar
	 * @description Assert if Company Id/ Firm Id is set on Account.
	 **/
	@isTest
	static void testSetHybridCompanyFirmId() {
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Discovery Account').setZPFirmId('4561111111').build();

		Test.startTest();
		insert new List<Account>{ objCompanyAccount, objResellerAccount };
		Test.stopTest();

		Account objCompanyAccountAssert = [SELECT Id, Company_Firm_ID__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(objCompanyAccount.ZP_Company_ID__c, objCompanyAccountAssert.Company_Firm_ID__c, 'Company Id not matching firm id.');

		Account objResellerAccountAssert = [SELECT Id, Company_Firm_ID__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(objResellerAccount.ZP_Firm_ID__c, objResellerAccountAssert.Company_Firm_ID__c, 'Firm id not matching company id.');
	}

	/**
	 * @author      Prity Kumari
	 * @description Assert Cross-Sell and Upsell Opportunity
	 **/
	@isTest
	static void testUpsellOpportunity() {
		User objUser = [SELECT id FROM user WHERE email = 'partneram@testorg.com'];
		Account objResellerAccount = [SELECT Id, Discount__c FROM Account WHERE Recordtype.name = 'Reseller' LIMIT 1];
		System.runAs(objUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account OHI')
				.setZPCompanyId('11123334')
				.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
				.setTier(AccountUtil.SIMPLE_TIER)
				.setSoldBy(objResellerAccount.Id)
				.setNumberOfActiveEEs(8)
				.build();
			objAccount.Reward_Eligible__c = true;
			insert objAccount;

			TriggerHandler.clearAllBypasses();
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
				.setName('APD Upsell Opportunity')
				.setAccountId(objAccount.Id)
				.setUpsellTier(AccountUtil.PLUS_TIER)
				.setType('Upsell')
				.build();
			objOpportunity.Current_Tier__c = AccountUtil.SIMPLE_TIER;
			insert objOpportunity;
			Test.startTest();
			objResellerAccount.Discount__c = 10;
			update objResellerAccount;
			Opportunity objUpsellAssertOpp = [SELECT Id, StageName, NumberOfEmployees__c, Discount__c FROM Opportunity WHERE Id = :objOpportunity.Id];
			System.assertEquals(8, objUpsellAssertOpp.NumberOfEmployees__c, 'Number Of EE not updated on opportunity.');
			System.assertEquals(10, objUpsellAssertOpp.Discount__c, 'Discount not updated on opportunity');

			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhatId(objUpsellAssertOpp.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.build();
			insert objTask;
			objAccount.Pricing__c = AccountUtil.PLUS_PAYMENT_PLAN;
			objAccount.Tier__c = AccountUtil.PLUS_TIER;
			update objAccount;
			Test.stopTest();
			objUpsellAssertOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :objOpportunity.Id];
			//System.assertEquals('Closed Won', objUpsellAssertOpp.StageName, 'Opportunity stage not marked as Closed Won.');
		}
	}
	/**
	 * @author      Prity Kumari
	 * @description Assert if Employees are set on Opportunity
	 **/
	@isTest
	static void testSetEmployeeCount() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('OpportunityTriggerHandler');
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account OHI')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.build();
		insert objAccount;
		BenefitOrderHelper.skipTrigger = true;
		Opportunity objNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAccount.Id)
			.setNumberOfEE(2)
			.build();
		objNewPlan.HI_Opportunity_Assignment_State__c = 'California';
		insert objNewPlan;

		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setName('Test Benefit Order')
			.setAccount(objAccount.Id)
			.setOpp(objNewPlan.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenefitOrder;
		TriggerHandler.clearAllBypasses();
		Test.startTest();
		objAccount.Number_of_Active_Employees__c = 8;
		update objAccount;
		//Test Case: When Opportunity is open
		Opportunity objAssertOpp = [SELECT Id, StageName, NumberOfEmployees__c FROM Opportunity WHERE Id = :objNewPlan.Id];
		System.assertEquals(8, objAssertOpp.NumberOfEmployees__c, 'Number Of EE not updated on opportunity.');

		//Test Case: When Opportunity is closed
		objAssertOpp.StageName = 'Closed Won';
		update objAssertOpp;
		objBenefitOrder.Order_Status__c = 'Fulfilled';
		update objBenefitOrder;
		objAccount.Number_of_Active_Employees__c = 6;
		update objAccount;
		objAssertOpp = [SELECT Id, NumberOfEmployees__c FROM Opportunity WHERE Id = :objNewPlan.Id];
		System.assertEquals(8, objAssertOpp.NumberOfEmployees__c, 'Number Of EE not updated on opportunity.');
		Test.stopTest();
	}

	/**
	 * @author      Sandeep Golla
	 * @description Test change in discount based on partner tiers
	 **/
	@isTest
	static void testDiscountChangeBasedPartnerTier() {
		Test.startTest();

		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Discovery Account')
			.setZPFirmId('4561111111')
			.setAMTier(AccountUtil.AM_TIER_STARTER)
			.build();

		insert objResellerAcc;

		//Assert after creation of account
		Account objAccountInsertAssert = [SELECT Id, AM_Tier__c, Discount__c FROM Account WHERE Id = :objResellerAcc.Id];
		System.assertEquals(AccountUtil.AM_TIER_STARTER_DISCOUNT, objAccountInsertAssert.Discount__c, 'Partner Discount not updated on opportunity');

		objResellerAcc.AM_Tier__c = AccountUtil.AM_TIER_SILVER;
		update objResellerAcc;
		Test.stopTest();

		//Assert after updation of account
		Account objAccountUpdateAssert = [SELECT Id, AM_Tier__c, Discount__c FROM Account WHERE Id = :objResellerAcc.Id];
		System.assertEquals(AccountUtil.AM_TIER_SILVER_DISCOUNT, objAccountUpdateAssert.Discount__c, 'Partner Discount not updated on opportunity');
	}

	/**
	 * @author      Veeresh Kumar
	 * @description Test set Standard Fields on Account with 3rd party fields.
	 **/
	@isTest
	static void testSetStandardFieldsFrom3rdParty() {
		Test.startTest();

		List<Account> list_AccountsToInsert = new List<Account>();
		List<Account> list_AccountsToUpdate = new List<Account>();

		Account objResellerAcc1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('test Res Account')
			.setZPFirmId('firmid01')
			.setBillingCity('Wixom')
			.setBillingState('Michigan')
			.setBillingCountry('United States')
			.setBillingPostalCode('48393')
			.setX3rdPartyCity('New York')
			.setX3rdPartyState('New York')
			.setX3rdPartyPostal('10001')
			.build();
		list_AccountsToInsert.add(objResellerAcc1);

		Account objResellerAcc2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('test Res Account')
			.setZPFirmId('firmid02')
			.setX3rdPartyCity('Wixom')
			.setX3rdPartyState('Michigan')
			.build();
		list_AccountsToInsert.add(objResellerAcc2);

		insert list_AccountsToInsert;

		Account objAccInsertAssert1 = [SELECT Id, BillingCity, BillingState, BillingPostalCode FROM Account WHERE Id = :objResellerAcc1.Id];
		System.assertNotEquals(objResellerAcc1.X3rd_Party_City__c, objAccInsertAssert1.BillingCity, 'Billing City Not updated on account.');
		System.assertNotEquals(objResellerAcc1.X3rd_Party_State__c, objAccInsertAssert1.BillingState, 'Billing State Not updated on account.');
		System.assertNotEquals(objResellerAcc1.X3rd_Party_Postal__c, objAccInsertAssert1.BillingPostalCode, 'Billing Postal Code Not updated on account.');

		objResellerAcc1.X3rd_Party_Postal__c = '10002';
		list_AccountsToUpdate.add(objResellerAcc1);

		objResellerAcc2.BillingCountry = 'United States';
		objResellerAcc2.X3rd_Party_Postal__c = '48393';

		objResellerAcc2.X3rd_Party_Annual_Revenue__c = 20000;
		objResellerAcc2.X3rd_Party_Num_Employees__c = 20;
		objResellerAcc2.X3rd_Party_Industry__c = 'Accounting';

		list_AccountsToUpdate.add(objResellerAcc2);

		update list_AccountsToUpdate;

		Test.stopTest();

		Account objAccUpdateAssert1 = [SELECT Id, BillingCity, BillingState, BillingPostalCode FROM Account WHERE Id = :objResellerAcc1.Id];
		System.assertNotEquals(objResellerAcc1.X3rd_Party_City__c, objAccUpdateAssert1.BillingCity, 'Billing City Not updated on account.');
		System.assertNotEquals(objResellerAcc1.X3rd_Party_State__c, objAccUpdateAssert1.BillingState, 'Billing State Not updated on account.');
		System.assertNotEquals(objResellerAcc1.X3rd_Party_Postal__c, objAccUpdateAssert1.BillingPostalCode, 'Billing Postal Code Not updated on account.');

		Account objAccUpdateAssert2 = [SELECT Id, BillingCity, BillingState, BillingPostalCode, AnnualRevenue, NumberOfEmployees, Industry FROM Account WHERE Id = :objResellerAcc2.Id];
		System.assertEquals(objResellerAcc2.X3rd_Party_City__c, objAccUpdateAssert2.BillingCity, 'Billing City Not updated on account.');
		System.assertEquals(objResellerAcc2.X3rd_Party_State__c, objAccUpdateAssert2.BillingState, 'Billing State Not updated on account.');
		System.assertEquals(objResellerAcc2.X3rd_Party_Postal__c, objAccUpdateAssert2.BillingPostalCode, 'Billing Postal Code Not updated on account.');

		System.assertEquals(objResellerAcc2.X3rd_Party_Annual_Revenue__c, objAccUpdateAssert2.AnnualRevenue, 'Anual Revenue not updated on account.');
		System.assertEquals(objResellerAcc2.X3rd_Party_Num_Employees__c, objAccUpdateAssert2.NumberOfEmployees, 'Number of Employees not updated on account.');
		System.assertEquals(objResellerAcc2.X3rd_Party_Industry__c, objAccUpdateAssert2.Industry, 'Industry not updated on account.');
	}

	@IsTest
	static void testBeforeDelete_Sales() {
		Test.startTest();
		TriggerHandler.bypass('AccountTriggerHandler');
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Gustomer')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setZPCompanyId('309712490321')
			.setHIOwner(UserInfo.getUserId())
			.build();

		insert objAccount;

		TriggerHandler.clearBypass('AccountTriggerHandler');

		System.runAs(objSalesUser) {
			try {
				delete objAccount;
			} catch (Exception ex) {
				System.assert(ex.getMessage().contains('Delete failed'), 'Exception not matching.');
			}
		}
	}

	/**
	 * @author      Pradeep Chary
	 * @description Bypass routing for Ardius user
	 **/
	@isTest
	static void testArdiusResellerAccountTest() {
		Test.startTest();

		List<Profile> list_Profiles = [SELECT Id FROM Profile WHERE Name = 'Ardius Base User'];
		List<User> list_Users = new List<User>();

		//create Ardius user
		User objArdiusUser = new TestDataFactory.UserBuilder()
			.setAlias('ardiuser')
			.setEmail('ardiususer@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Ardius')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(list_Profiles[0].Id)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('ardiususer@testorg.com.aridus')
			.build();

		objArdiusUser.Exempt_from_Validation_Rules__c = true;
		objArdiusUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = :UserUtils.LABEL_ARDIUS][0].Id;
		list_Users.add(objArdiusUser);

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objCurrentUser) {
			insert list_Users;
		}

		// create reseller account
		Account objAccount = new Account();
		objAccount.RecordTypeId = AccountUtil.RESELLER_ACCOUNT_RT_ID;
		objAccount.Name = 'Test Ardius Account';
		objAccount.ZP_Firm_ID__c = '1223345';

		System.runAs(list_Users[0]) {
			insert objAccount;
		}

		Test.stopTest();

		Account objUpdatedAccount = [SELECT Id, OwnerId FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(list_Users[0].Id, objUpdatedAccount.OwnerId, 'Account Owner not updated for Ardius.');
	}

	/**
	 * @author     Swati Arya
	 * @description Test Case Owner update to Member Ops when Broker Integartion On Account is set to true
	 **/
	@isTest
	static void testUpdateBYOBCustomerOnCaseRecordsMemberOps() {
		Test.startTest();

		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account 123').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();

		insert objAccount;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test').build();
		objCarrier.Carrier_Unique_Name__c = 'Test';
		objCarrier.State__c = 'CA';
		insert objCarrier;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId('MF Audit')
			.setType('Audit')
			.setSubject('Test Case Owner Change Ben Admin Update Member Ops')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.build();

		objCase.Carrier__c = objCarrier.Id;

		insert objCase;

		objAccount.Big_Desk_Pilot_Customer__c = true;
		update objAccount;

		Id idMemberOpsQueue = map_Queues.get(strMemberOpsBYB);
		Case objCase1 = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase.Id];

		System.assertEquals(objCase1.OwnerId, idMemberOpsQueue, 'Case Owner should be updated to Member Ops - BYB Queue');

		Test.stopTest();
	}

	/**
	 * @author     Swati Arya
	 * @description Test Case Owner update to Member Fulfillment when Broker Integartion On Account is set to false
	 **/
	@isTest
	static void testUpdateBYOBCustomerOnCaseRecordsMemberFulfillment() {
		Test.startTest();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account 123').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();

		objAccount.Big_Desk_Pilot_Customer__c = true;

		insert objAccount;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test').build();
		objCarrier.Carrier_Unique_Name__c = 'Test';
		objCarrier.State__c = 'CA';
		insert objCarrier;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId('MF Audit')
			.setType('Audit')
			.setSubject('Test Case Owner Change Ben Admin Update Member Fulfillment')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.build();

		objCase.Carrier__c = objCarrier.Id;

		insert objCase;

		objAccount.Big_Desk_Pilot_Customer__c = false;
		update objAccount;

		Id idMemberFulfillmentQueue = map_Queues.get(strMemberFulfillment);
		Case objCase1 = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase.Id];

		System.assertEquals(objCase1.OwnerId, idMemberFulfillmentQueue, 'Case Owner should be updated to Member Fulfillment Queue');

		Test.stopTest();
	}

	/**
	 * @author     Swati Arya
	 * @description Test Account Owner update to Workato Integration User for Embedded Company Account Insert
	 **/
	@isTest
	static void testEmbeddedCompanyAccountOwnerChangeOnInsert() {
		Id idWorkatoIntegrationUserId = AccountUtil.getWorkatoIntegrationUserId();
		Test.startTest();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Embedded Account').setRecordTypeId(AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();

		insert objAccount;
		Test.stopTest();

		Account objAccAssert = [SELECT Id, OwnerId FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objAccAssert.OwnerId, idWorkatoIntegrationUserId, 'Account Owner should be Workato Integration User');
	}

	/**
	 * @author     Swati Arya
	 * @description Test Account Owner update to Workato Integration User for Embedded Company Account Update
	 **/
	@isTest
	static void testEmbeddedCompanyAccountOwnerChangeOnUpdate() {
		Id idWorkatoIntegrationUserId = AccountUtil.getWorkatoIntegrationUserId();
		Test.startTest();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Company Account').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();

		insert objAccount;
		Test.stopTest();

		objAccount.RecordTypeId = AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID;
		update objAccount;

		Account objAccAssert = [SELECT Id, OwnerId FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objAccAssert.OwnerId, idWorkatoIntegrationUserId, 'Account Owner should be Workato Integration User');
	}

	/**
	 * @author     Swati Arya
	 * @description Test Contact Record Type Changes when Account Record Type is changed
	 **/
	@isTest
	static void testAssociatedContactRecordTypeChanges() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Embedded Company Account 1')
			.setZPCompanyId('212121212121')
			.build();
		insert objCompanyAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Test.startTest();
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Test Contact Name')
			.setLastName('Test Last Name')
			.setEmail('testContact1@test.com')
			.build();
		insert objContact;

		objCompanyAccount.RecordTypeId = AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID;
		update objCompanyAccount;

		Contact objContactAssert = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(objContactAssert.RecordTypeId, ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID, 'Contact recordtype should be updated to Embedded Company');

		objCompanyAccount.RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID;
		update objCompanyAccount;

		Contact objContactAssert2 = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(objContactAssert2.RecordTypeId, ContactUtil.COMPANY_CONTACT_RT_ID, 'Contact recordtype should be updated to Company');

		objCompanyAccount.Type = AccountUtil.EMBEDDED_PARTNER_TYPE;
		objCompanyAccount.RecordTypeId = AccountUtil.RESELLER_ACCOUNT_RT_ID;
		update objCompanyAccount;

		Contact objContactAssert3 = [SELECT Id, RecordTypeId, RecordType.Name FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(objContactAssert3.RecordTypeId, ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID, 'Contact recordtype should be updated to Embedded Company');

		objCompanyAccount.RecordTypeId = AccountUtil.PARTNER_RT_ID;
		update objCompanyAccount;

		Contact objContactAssert4 = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(objContactAssert4.RecordTypeId, ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID, 'Contact recordtype should be updated to Embedded Company');

		Test.stopTest();
	}

	/**
	 * @description Setting up test data for creating pricebook and pricebook entries
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public static void setUpNewPrices(String strPriceName, Boolean blnPrioritySupport, Decimal decPrice) {
		// Start setting up data and create pricebook and pricebook entries
		// Create a new pricebook
		Pricebook2 objPriceBookOne = new TestDataFactory.PriceBookBuilder().setName(strPriceName).setActive().build();
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
		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Employer of Record - Employee')
				.setFamily('Payroll')
				.setProductType(OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_EMPLOYESS)
				.setProductCategory('Employer of Record')
				.build()
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
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, decPrice, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, decPrice, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, decPrice, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, decPrice, Test.getStandardPriceBookId(), false));
		if (blnPrioritySupport) {
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[4].Id, decPrice, Test.getStandardPriceBookId(), false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[5].Id, decPrice, Test.getStandardPriceBookId(), false));
		}

		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, decPrice, objPriceBookOne.id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, decPrice, objPriceBookOne.id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, decPrice, objPriceBookOne.id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, decPrice, objPriceBookOne.id, false));
		if (blnPrioritySupport) {
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[4].Id, decPrice, objPriceBookOne.id, false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[5].Id, decPrice, objPriceBookOne.id, false));
		}

		insert list_Entries;
	}

	/**
	 * @author     David (Dato) Tsamalashvili
	 * @description Test Account name change
	 **/
	@isTest
	static void testValidateCompanyName() {
		Test.startTest();
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test123@gusto.com').setZPCompanyId('212121212121').build();

		insert objCompanyAccount;

		Account objAccAssert = [SELECT Id, Name FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals('test123 - Payroll', objAccAssert.Name, 'Opportunity name not populated correctly.');

		Test.stopTest();
	}

	/**
	 * @author     Prity Kumari
	 * @description Test  Routing for Accounts created by Sales.
	 **/
	@isTest
	static void testRoutingWithSalesCreatedAccount() {
		User objUser = [SELECT Id, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.DeveloperName = :LeadUtil.LABEL_SDR_PARTNER_USR_ROLE AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		System.runAs(objUser) {
			Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test123@gusto.com').setZPCompanyId('212121212121').build();
			insert objCompanyAccount;

			Account objAccAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objCompanyAccount.Id];
			System.assertEquals(null, objAccAssert.Account_Route_Count__c, 'Account route count not null');

			objCompanyAccount.RecordTypeId = AccountUtil.RESELLER_ACCOUNT_RT_ID;
			update objCompanyAccount;

			objAccAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objCompanyAccount.Id];
			System.assertEquals(null, objAccAssert.Account_Route_Count__c, 'Account route count not null');
		}
		Test.stopTest();
	}

	/**
	 * @author     Prity Kumari
	 * @description Test  Routing for Accounts with Route to Market as null.
	 **/
	@isTest
	static void testRoutingWithRouteToMarket() {
		Test.startTest();

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test123@gusto.com').setZPCompanyId('212121212121').build();
		insert objCompanyAccount;

		Account objAccAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(1, objAccAssert.Account_Route_Count__c, 'Account Route count not updated.');

		objCompanyAccount.RecordTypeId = AccountUtil.RESELLER_ACCOUNT_RT_ID;
		objCompanyAccount.Route_to_Market__c = 'MMPR';
		update objCompanyAccount;

		objAccAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(1, objAccAssert.Account_Route_Count__c, 'Account Route count not updated.');

		Test.stopTest();
	}

	/**
	 * @author     Prity Kumari
	 * @description Test  Routing for Accounts with Sold By.
	 **/
	@isTest
	static void testSoldByRouting() {
		User objUser = [SELECT Id, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.DeveloperName = :LeadUtil.LABEL_SDR_PARTNER_USR_ROLE AND IsActive = TRUE LIMIT 1];
		Account objResellerAccount = [SELECT Id, ZP_Firm_ID__c FROM Account WHERE Recordtype.name = 'Reseller' LIMIT 1];
		ZP_Company__c objZPCompany = [SELECT Id, Id__c FROM ZP_Company__c WHERE Id__c = '11111111111111'];
		Test.startTest();
		Account objAccount = [SELECT Id, Account_Route_Count__c FROM Account WHERE Zp_Company_Id__c = :objZPCompany.Id__c];
		Decimal decRouteCount = objAccount.Account_Route_Count__c != null ? objAccount.Account_Route_Count__c : 0;
		objZPCompany.Managing_Accounting_Firm_Id__c = objResellerAccount.ZP_Firm_ID__c;
		objZPCompany.Original_Accounting_Firm_Id__c = objResellerAccount.ZP_Firm_ID__c;
		objZPCompany.Processing_State__c = 'Manually Enqueued';
		update objZPCompany;
		Test.stopTest();

		System.assertEquals('Processed', [SELECT Id, Id__c, Processing_State__c FROM ZP_Company__c WHERE Id__c = '11111111111111'].Processing_State__c, 'ZP Company is not processed');
		Account objAccountAssert = [
			SELECT Id, Account_Route_Count__c, Original_Firm__r.ZP_Firm_ID__c, Sold_By__r.ZP_Firm_ID__c, Managing_Firm__r.ZP_Firm_ID__c
			FROM Account
			WHERE Zp_Company_Id__c = :objZPCompany.Id__c
		];
		System.assertEquals(decRouteCount + 1, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for Original Accounting Firm update');
		System.assertEquals(objAccountAssert.Original_Firm__r.ZP_Firm_ID__c, objResellerAccount.ZP_Firm_ID__c, 'Account Original Accounting Firm did not set correctly');
		System.assertEquals(objAccountAssert.Sold_By__r.ZP_Firm_ID__c, objResellerAccount.ZP_Firm_ID__c, 'Account Sold_By__c did not set correctly');
		System.assertEquals(objAccountAssert.Managing_Firm__r.ZP_Firm_ID__c, objResellerAccount.ZP_Firm_ID__c, 'Account Managing_Firm__c did not set correctly');
	}

	/**
	 * @description Test Reclaulate Firm MRR Tracker update
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testSetRecalculateMRR() {
		List<Account> list_Accounts = [
			SELECT Id, Current_MRR__c, Recalculate_Metrics_Tracker__c, Number_of_Active_Employees__c, Number_of_Active_Contractors__c, Tier__c
			FROM Account
			WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
			LIMIT 1
		];
		System.assert(!list_Accounts.isEmpty(), 'Test accounts are not found');

		Test.startTest();
		Account objAccount = list_Accounts[0];
		objAccount.Number_of_Active_Employees__c = 172;
		objAccount.Number_of_Active_Contractors__c = 176;
		objAccount.Tier__c = 'simple';
		objAccount.Recalculate_Metrics_Tracker__c = null;
		update objAccount;
		Test.stopTest();

		Account objUpdatedAccount = [SELECT Id, Current_MRR__c, Recalculate_Metrics_Tracker__c FROM Account WHERE Id = :objAccount.Id];
		System.assert(Utils.isMultiPicklistContains(objUpdatedAccount.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Calculation failed, Tracker did not set');
	}

	/**
	 * @description Test Reclaulate Firm MRR Tracker When Account Susupended
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testSetRecalculateMRRClientSuspended() {
		List<Account> list_Accounts = [SELECT Id, ZP_Company_Suspension_Date__c FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		System.assert(!list_Accounts.isEmpty(), 'Test accounts are not found');

		Test.startTest();
		Account objAccount = list_Accounts[0];
		objAccount.ZP_Company_Suspension_Date__c = Date.today();
		objAccount.Tier__c = AccountUtil.SIMPLE_TIER;
		update objAccount;

		Account objUpdatedAccount = [SELECT Id, Recalculate_Metrics_Tracker__c FROM Account WHERE Id = :objAccount.Id];
		System.assert(Utils.isMultiPicklistContains(objUpdatedAccount.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Calculation failed, Tracker did not set');

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setAccountId(objAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setStage('New')
			.build();
		insert objOpportunity;

		objAccount.Tier__c = AccountUtil.PREMIUM_TIER;
		update objAccount;

		objOpportunity = [SELECT Id, PriceBook2Id FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(OpportunityUtil.getPriceBookByName(OpportunityUtil.PRICE_BOOK_RD_PREMIUM)?.Id, objOpportunity.PriceBook2Id, 'Pricebook did not updated');

		Test.stopTest();
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    HI Sales Routing - Test if HI Owner is updated account, related open benefits opps and pending HI Quote records are updated
	 */
	@isTest
	static void testHIOwnerUpdateOnRelatedRecords() {
		// skip all triggers
		AccountTriggerHelper.skipTrigger = true;
		UserTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		User objWorkatoUser = [SELECT Id, Name FROM User WHERE Name = 'Workato Integration' AND IsActive = TRUE LIMIT 1];
		// insert test company account
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('86896897')
			.setNumberOfActiveEEs(8)
			.setNumberOfEmployees(8)
			.build();
		insert objAcc;

		// insert test new plan opportunity
		Opportunity objNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objAcc.Id)
			.setNumberOfEE(2)
			.build();
		insert objNewPlan;

		// insert test insurance quote
		Insurance_Quote__c objInsuranceQuote = new TestDataFactory.InsuranceQuoteBuilder()
			.setAccountId(objAcc.Id)
			.setOpportunityId(objNewPlan.Id)
			.setSalesRepId(UserInfo.getUserId())
			.setQuoteLink('www.testquotelink.com')
			.setCensusLink('www.testcensuslink.com')
			.setCensusPartTimeEmployees(45)
			.setPlannedW2Hires(120)
			.build();
		insert objInsuranceQuote;

		// start test and update hi owner
		Test.startTest();
		AccountTriggerHelper.skipTrigger = false;
		objAcc.HI_Owner__c = objWorkatoUser.Id;
		update objAcc;
		Test.stopTest();

		// assert if open benefits opp went to workato user
		Opportunity objOpptyAssert = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :objNewPlan.Id];
		System.assertEquals(objWorkatoUser.Id, objOpptyAssert.OwnerId, 'Opportunity Owner not updated to Workato Integration user');

		// assert if pending insurance quote went to workato user
		Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Sales_Rep__c, Sales_Rep__r.Id FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote.Id];
		System.assertEquals(objWorkatoUser.Id, objInsuranceQuoteAssert.Sales_Rep__r.Id, 'Insurance Quote Sales Rep not updated to Workato Integration user');
	}

	/**
	 * @description This test method checks insert of Account Team Member on update of CSM owner on Account
	 **/
	@isTest
	static void testCSMRoutingAndATMInsert() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		List<Account> list_Accounts = [
			SELECT Id, Tier__c, Anchor_Pay_Date__c, CSM_Owner__c, ZP_Company_Overall_Status__c, Owner.Name
			FROM Account
			WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
			LIMIT 1
		];
		Account resellerAccount = [SELECT Id, Name FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];
		Test.startTest();
		Account objTestAccount = list_Accounts[0];
		System.assert(objTestAccount.Tier__c != AccountUtil.PREMIUM_TIER, 'Test accounts should initially be non-premium');
		objTestAccount.Tier__c = AccountUtil.PREMIUM_TIER;
		objTestAccount.Anchor_Pay_Date__c = Date.today();
		objTestAccount.CSM_Owner__c = objUser.Id;
		objTestAccount.ZP_Company_Overall_Status__c = 'New';
		objTestAccount.Account_Route_Count__c = 0;
		objTestAccount.Original_Firm__c = resellerAccount.Id;
		objTestAccount.Set_Up_Steps_Completed__c = 80.0;
		update objTestAccount;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
		System.assertEquals(1, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for CSM Update');
		System.assert(objAccountAssert.Send_to_Catalyst__c, 'Send to catalyst was not set for CSM Update');
		List<AccountTeamMember> list_ATM = [SELECT Id, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :objTestAccount.Id];
		System.assertEquals(1, list_ATM.size(), 'Account Team Member record not created for CSM Update');
		System.assertEquals(objUser.Id, list_ATM.get(0).UserId, 'Account Team Member record dosnt have correct user');
		System.assertEquals(AccountUtil.ACCOUNT_TEAM_MEMBER_CSM_ROLE, list_ATM.get(0).TeamMemberRole, 'Account Team Member record dosnt have correct role');
	}

	/**
	 * @description This test method checks update of Account Team Member on update of CSM owner on Account
	 **/
	@isTest
	static void testCSMRoutingAndATMUpdate() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		List<Account> list_Accounts = [
			SELECT Id, Tier__c, Anchor_Pay_Date__c, CSM_Owner__c, ZP_Company_Overall_Status__c, Owner.Name
			FROM Account
			WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
			LIMIT 1
		];
		Test.startTest();
		Account objTestAccount = list_Accounts[0];
		System.assert(objTestAccount.Tier__c != AccountUtil.PREMIUM_TIER, 'Test accounts should initially be non-premium');
		objTestAccount.Tier__c = AccountUtil.PREMIUM_TIER;
		objTestAccount.Anchor_Pay_Date__c = Date.today();
		objTestAccount.CSM_Owner__c = objUser.Id;
		objTestAccount.ZP_Company_Overall_Status__c = 'New';
		objTestAccount.Account_Route_Count__c = 0;
		Utils.skipTrigger(true);
		update objTestAccount;
		insert new AccountTeamMember(AccountId = objTestAccount.Id, UserId = objTestAccount.CSM_Owner__c, TeamMemberRole = AccountUtil.ACCOUNT_TEAM_MEMBER_CSM_ROLE);
		Utils.skipTrigger(false);
		Test.stopTest();

		objTestAccount.CSM_Owner__c = UserInfo.getUserId();
		update objTestAccount;
		List<AccountTeamMember> list_ATM = [SELECT Id, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :objTestAccount.Id];
		System.assertEquals(1, list_ATM.size(), 'Account Team Member record not updated for CSM Update');
		System.assertEquals(UserInfo.getUserId(), list_ATM.get(0).UserId, 'Account Team Member record dosnt have correct user');
		System.assertEquals(AccountUtil.ACCOUNT_TEAM_MEMBER_CSM_ROLE, list_ATM.get(0).TeamMemberRole, 'Account Team Member record dosnt have correct role');
	}

	/**
	 * @description This test method checks deletion Account Team Member on update of CSM owner on Account
	 **/
	@isTest
	static void testCSMRoutingAndATMDelete() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		List<Account> list_Accounts = [
			SELECT Id, Tier__c, Anchor_Pay_Date__c, CSM_Owner__c, ZP_Company_Overall_Status__c, Owner.Name
			FROM Account
			WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
			LIMIT 1
		];
		Test.startTest();
		Account objTestAccount = list_Accounts[0];
		System.assert(objTestAccount.Tier__c != AccountUtil.PREMIUM_TIER, 'Test accounts should initially be non-premium');
		objTestAccount.Tier__c = AccountUtil.PREMIUM_TIER;
		objTestAccount.Anchor_Pay_Date__c = Date.today();
		objTestAccount.CSM_Owner__c = objUser.Id;
		objTestAccount.ZP_Company_Overall_Status__c = 'New';
		objTestAccount.Account_Route_Count__c = 0;
		Utils.skipTrigger(true);
		update objTestAccount;
		insert new AccountTeamMember(AccountId = objTestAccount.Id, UserId = objTestAccount.CSM_Owner__c, TeamMemberRole = AccountUtil.ACCOUNT_TEAM_MEMBER_CSM_ROLE);
		Utils.skipTrigger(false);
		Test.stopTest();

		objTestAccount.CSM_Owner__c = null;
		update objTestAccount;
		List<AccountTeamMember> list_ATM = [SELECT Id, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :objTestAccount.Id];
		System.assertEquals(0, list_ATM.size(), 'Account Team Member record not deleted after CSM Update to blank');
	}

	/**
	 * @description This test method checks for increase in route count on update of Tier to Premium
	 **/
	@isTest
	static void testCSMRoutingOnTierUpdate() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		System.runAs(objUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objTestAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account')
				.setOnboardingFlow('In-App')
				.setZPCompanyId('123456')
				.setTier('simple')
				.build();
			insert objTestAccount;
			TriggerHandler.clearAllBypasses();
			objTestAccount.Tier__c = AccountUtil.PREMIUM_TIER;
			objTestAccount.Anchor_Pay_Date__c = Date.today();
			objTestAccount.ZP_Company_Overall_Status__c = 'New';
			objTestAccount.Account_Route_Count__c = 0;
			update objTestAccount;
			Account objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
			System.assertEquals(1, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for CSM Update');
		}
		Test.stopTest();
	}

	/**
	 * @description This test method checks for increase in route count on update of Tier from blank to Premium and CSM Owner is blank
	 **/
	@isTest
	static void testCSMRoutingOnTierUpdateNoCSM() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		User objNonDedicatedCSMUser = [SELECT Id FROM User WHERE UserRole.Name != :AccountUtil.DEDICATED_CSM_ROLE AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		System.runAs(objUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objTestAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account')
				.setOnboardingFlow('In-App')
				.setZPCompanyId('123456')
				.setTier('simple')
				.build();
			insert objTestAccount;
			TriggerHandler.clearAllBypasses();
			objTestAccount.Tier__c = AccountUtil.PREMIUM_TIER;
			objTestAccount.CSM_Owner__c = objNonDedicatedCSMUser.Id;
			objTestAccount.Account_Route_Count__c = 0;
			update objTestAccount;
			Account objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
			System.assertEquals(1, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for tier Update');
		}
		Test.stopTest();
	}

	/**
	 * @description This test method checks for increase in route count on update of Tier from Premium to other Premium and CSM Owner is already populated
	 **/
	@isTest
	static void testCSMRoutingOnTierUpdateDedicatedCSM() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		User objDedicatedCSMUser = [SELECT Id FROM User WHERE UserRole.Name = :AccountUtil.DEDICATED_CSM_ROLE AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		System.runAs(objUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objTestAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account')
				.setOnboardingFlow('In-App')
				.setZPCompanyId('123456')
				.setTier('Premium')
				.build();
			insert objTestAccount;
			TriggerHandler.clearAllBypasses();
			objTestAccount.Tier__c = AccountUtil.CRB_PREMIUM_TIER;
			objTestAccount.CSM_Owner__c = objDedicatedCSMUser.Id;
			objTestAccount.Account_Route_Count__c = 0;
			update objTestAccount;
			Account objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
			System.assertEquals(1, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for tier Update');
		}
		Test.stopTest();
	}

	/**
	 * @description This test method checks for increase in route count on update of Anchor Pay Date
	 **/
	@isTest
	static void testCSMRoutingOnAnchorPayDateUpdate() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		System.runAs(objUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objTestAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account')
				.setOnboardingFlow('In-App')
				.setZPCompanyId('123457')
				.setTier('simple')
				.build();
			insert objTestAccount;

			Account objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
			Decimal intOldRouteCount = objAccountAssert.Account_Route_Count__c;

			TriggerHandler.clearAllBypasses();
			objTestAccount.Tier__c = AccountUtil.PREMIUM_TIER;
			objTestAccount.Anchor_Pay_Date__c = null;
			objTestAccount.ZP_Company_Overall_Status__c = 'New';
			objTestAccount.Anchor_Pay_Date__c = Date.today();
			update objTestAccount;

			objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
			System.assertNotEquals(intOldRouteCount, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for Anchor pay date change');
		}
		Test.stopTest();
	}

	/**
	 * @description This test method checks for increase in route count on update of Overall Status
	 **/
	@isTest
	static void testCSMRoutingOnOverallStatusUpdate() {
		User objUser = [SELECT Id FROM User WHERE Profile.Name = :AccountUtil.USER_PROFILE_NAME_CX_USER AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		System.runAs(objUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objTestAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account')
				.setOnboardingFlow('In-App')
				.setZPCompanyId('123458')
				.setTier('simple')
				.build();
			insert objTestAccount;

			Account objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
			Decimal intOldRouteCount = objAccountAssert.Account_Route_Count__c;

			TriggerHandler.clearAllBypasses();
			objTestAccount.Tier__c = AccountUtil.PREMIUM_TIER;
			objTestAccount.Anchor_Pay_Date__c = Date.today();
			objTestAccount.ZP_Company_Overall_Status__c = 'Suspended';
			objTestAccount.ZP_Company_Overall_Status__c = 'New';
			update objTestAccount;

			objAccountAssert = [SELECT Id, Account_Route_Count__c, CSM_Owner__c, Send_to_Catalyst__c FROM Account WHERE Id = :objTestAccount.Id];
			System.assertNotEquals(intOldRouteCount, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for Overall status change');
		}
		Test.stopTest();
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test if Account is eligible to add Employer of Record
	 */
	@isTest
	static void testInternationalPayrollEligible() {
		Account objAcc = new Account(Additional_Services__c = AccountUtil.EMPLOYER_OF_RECORD);
		Boolean blnEligible = AccountTriggerHelper.internationalPayrollInterestEligible(objAcc);

		// If company already has Employer of Record, eligibility should be set to false
		System.assertEquals(false, blnEligible, 'Account should not be eligible for Employer of Record');

		objAcc = new Account();
		blnEligible = AccountTriggerHelper.internationalPayrollInterestEligible(objAcc);
		// If company's product Interest or Countries is null, eligibilty should be set to false
		System.assertEquals(false, blnEligible, 'Account should not be eligible for Employer of Record');

		objAcc = new Account(Product_Interest__c = 'Invalid Interest', Product_Interest_Countries__c = 'IN');
		blnEligible = AccountTriggerHelper.internationalPayrollInterestEligible(objAcc);
		// If company's product Interest does not contain Employer of Record, eligibilty should be set to false
		System.assertEquals(false, blnEligible, 'Account should not be eligible for Employer of Record');

		objAcc = new Account(Product_Interest__c = 'international_payroll', Product_Interest_Countries__c = 'CA');
		blnEligible = AccountTriggerHelper.internationalPayrollInterestEligible(objAcc);
		// If company's product Interest contains Employer of Record and country is valid, eligibilty should be set to true
		System.assertEquals(true, blnEligible, 'Account should be eligible for Employer of Record');
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    If Employer of Record Interest is indicated to company account with closed lost opportunity, it should be re-opened
	 */
	@isTest
	static void testAddingInterestToClosedLostPayrollOppty() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.build();
		insert objAccount;

		// create company opportuntity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		insert objOpportunity;

		// update opportunity to closed lost
		objOpportunity.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
		update objOpportunity;

		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;

		Test.startTest();
		objAccount.Product_Interest__c = 'international_payroll_onboarding';
		objAccount.Product_Interest_Countries__c = 'CA';
		update objAccount;
		Test.stopTest();

		List<Opportunity> list_OppAssert = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID AND AccountId = :objAccount.Id];
		System.assertequals(1, list_OppAssert.size(), 'Employer of Record Cross-Sell and Upsell is created.');

		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, IsClosed FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(true, objOpptyAssert.IsClosed, 'Non-Employer of Record Cross-Sell and Upsell will not be closed.');
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    If Employer of Record Interest is indicated to company account, open Cross-Sell and Upsell opportunity should be appended
	 */
	@isTest
	static void testAddingInterestToOpenTierUpsellOppty() {
		AccountTriggerHelper.skipTrigger = true;

		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.build();
		insert objAccount;

		// create Cross-Sell and Upsell opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.PLUS_TIER)
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		objOpportunity.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		insert objOpportunity;

		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();
		objAccount.Product_Interest__c = 'international_payroll_onboarding';
		objAccount.Product_Interest_Countries__c = 'CA';
		update objAccount;
		Test.stopTest();

		// Assert if Employer of Record is added to Cross-Sell and Upsell opportunity
		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, IsClosed FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(
			true,
			objOpptyAssert.Additional_Opportunity_Services__c == null,
			'Additional services should be blank for the normal Cross-Sell and Upsell, if only Employer of Record has been created.'
		);
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    If Employer of Record is added to a valid country, a new Cross-Sell and Upsell opportunity should be created
	 */
	@isTest
	static void testNewTierUpsellOppCreationFromInterest() {
		AccountTriggerHelper.skipTrigger = true;

		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.build();
		insert objAccount;

		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();
		objAccount.Product_Interest__c = 'international_payroll_onboarding';
		objAccount.Product_Interest_Countries__c = 'CA';
		update objAccount;
		Test.stopTest();

		// Assert if new Cross-Sell and Upsell opportunity is created and contains Employer of Record
		/**Opportunity objOpptyAssert = [
			SELECT Id, Additional_Opportunity_Services__c, IsClosed
			FROM Opportunity
			WHERE AccountId = :objAccount.Id AND RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID
		];
		System.assertEquals(true, objOpptyAssert.Additional_Opportunity_Services__c.contains('Employer of Record'), 'Opportunity should contain Employer of Record'); **/
	}

	/**
	 * @author:         Praveen Sethu
	 * @description:    Test updating Cross-Sell and Upsell to closed won with Employer of Record.
	 */
	@isTest
	static void testTierUpsellClosedWonWithProductInterest() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.build();
		insert objAccount;

		// create company opportuntity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		insert objOpportunity;

		objOpportunity.StageName = 'Closed Won';
		update objOpportunity;

		objAccount.Product_Interest__c = 'international_payroll_onboarding';
		objAccount.Product_Interest_Countries__c = 'CA';
		update objAccount;

		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;

		// create Cross-Sell and Upsell opportunity
		Opportunity objTierUpsell = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.PLUS_TIER)
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		objTierUpsell.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		insert objTierUpsell;

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objTierUpsell.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;

		Test.startTest();
		objAccount.Tier__c = AccountUtil.PLUS_TIER;
		update objAccount;
		Test.stopTest();

		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, StageName FROM Opportunity WHERE Id = :objTierUpsell.Id];

		//System.assertEquals(OpportunityUtil.CLOSED_WON_STAGE, objOpptyAssert.StageName, 'Cross-Sell and Upsell opp not moved to Closed Won');
		//System.assertEquals(null, objOpptyAssert.Additional_Opportunity_Services__c, 'Opportunity Additional Services should has the Employer of Record.');
	}

	/**
	 * @author:         Anurag Gautam
	 * @description:    test case for upsell opportunity related new priority table. This method is testing the Simple to Simple and Gusto Global scenario.
	 */
	@isTest
	static void testTierUpsellClosedWonForInternationalPayroll() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setNumberOfActiveEEs(8)
			.setTier(AccountUtil.SIMPLE_TIER)
			.build();
		insert objAccount;

		// create company opportuntity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		insert objOpportunity;

		objOpportunity.StageName = 'Closed Won';
		update objOpportunity;

		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;

		// create Cross-Sell and Upsell opportunity
		Opportunity objTierUpsell = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier('Plus')
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		objTierUpsell.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		insert objTierUpsell;

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objTierUpsell.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;

		Test.startTest();
		objAccount.Additional_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
		update objAccount;
		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, StageName, Upsell_Tier__c FROM Opportunity WHERE Id = :objTierUpsell.Id];
		System.assertEquals(true, objOpptyAssert.StageName != OpportunityUtil.CLOSED_WON_STAGE, 'Cross-Sell and Upsell is open.');
		Test.stopTest();
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if First Client Add Date is stamped on Reseller Account based on Sold By on Insert
	 */
	@isTest
	static void testFirstClientAddDateOnInsertSoldBy() {
		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Reseller Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objResellerAcc;

		Account objCompanyAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setSoldBy(objResellerAcc.Id)
			.setNumberOfActiveEEs(8)
			.build();

		Test.startTest();
		insert objCompanyAcc;
		Test.stopTest();

		Account objResellerAccAssert = [SELECT Id, First_Client_Add_Date__c FROM Account WHERE ZP_Firm_ID__c = '4561111111'];
		System.assertNotEquals(objResellerAccAssert.First_Client_Add_Date__c, null, 'First Client Add Date did not get updated on Reseller Account.');
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if First Client Add Date is stamped on Reseller Account based on Referred By on Insert
	 */
	@isTest
	static void testFirstClientAddDateOnInsertReferredBy() {
		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Reseller Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objResellerAcc;

		Account objCompanyAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setReferredBy(objResellerAcc.Id)
			.setNumberOfActiveEEs(8)
			.build();

		Test.startTest();
		insert objCompanyAcc;
		Test.stopTest();

		Account objResellerAccAssert = [SELECT Id, First_Client_Add_Date__c FROM Account WHERE ZP_Firm_ID__c = '4561111111'];
		System.assertNotEquals(objResellerAccAssert.First_Client_Add_Date__c, null, 'First Client Add Date did not get updated on Reseller Account.');
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if First Client Add Date is stamped on Reseller Account based on Original Firm on Insert
	 */
	@isTest
	static void testFirstClientAddDateOnInsertOriginalFirm() {
		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Reseller Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objResellerAcc;

		Account objCompanyAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setOriginalFirmId(objResellerAcc.Id)
			.setNumberOfActiveEEs(8)
			.build();

		Test.startTest();
		insert objCompanyAcc;
		Test.stopTest();

		Account objResellerAccAssert = [SELECT Id, First_Client_Add_Date__c FROM Account WHERE ZP_Firm_ID__c = '4561111111'];
		System.assertNotEquals(objResellerAccAssert.First_Client_Add_Date__c, null, 'First Client Add Date did not get updated on Reseller Account.');
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if First Client Add Date is stamped on Reseller Account based on Sold By on Update
	 */
	@isTest
	static void testFirstClientAddDateOnUpdateSoldBy() {
		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Reseller Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objResellerAcc;

		Account objCompanyAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setNumberOfActiveEEs(8)
			.build();

		insert objCompanyAcc;

		Test.startTest();
		objCompanyAcc.Sold_By__c = objResellerAcc.Id;
		update objCompanyAcc;
		Test.stopTest();

		Account objResellerAccAssert = [SELECT Id, First_Client_Add_Date__c FROM Account WHERE ZP_Firm_ID__c = '4561111111'];
		System.assertNotEquals(objResellerAccAssert.First_Client_Add_Date__c, null, 'First Client Add Date did not get updated on Reseller Account.');
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if First Client Add Date is stamped on Reseller Account based on Referred By on Update
	 */
	@isTest
	static void testFirstClientAddDateOnUpdateReferredBy() {
		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Reseller Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objResellerAcc;

		Account objCompanyAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setNumberOfActiveEEs(8)
			.build();

		insert objCompanyAcc;

		Test.startTest();
		objCompanyAcc.Referred_By__c = objResellerAcc.Id;
		update objCompanyAcc;
		Test.stopTest();

		Account objResellerAccAssert = [SELECT Id, First_Client_Add_Date__c FROM Account WHERE ZP_Firm_ID__c = '4561111111'];
		System.assertNotEquals(objResellerAccAssert.First_Client_Add_Date__c, null, 'First Client Add Date did not get updated on Reseller Account.');
	}

	/**
	 * @author:         Debasmita Rawooth
	 * @description:    Test if First Client Add Date is stamped on Reseller Account based on Original Firm on Update
	 */
	@isTest
	static void testFirstClientAddDateOnUpdateOriginalFirm() {
		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Reseller Account')
			.setOnboardingFlow('In-App')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objResellerAcc;

		Account objCompanyAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setNumberOfActiveEEs(8)
			.build();

		insert objCompanyAcc;

		Test.startTest();
		objCompanyAcc.Original_Firm__c = objResellerAcc.Id;
		update objCompanyAcc;
		Test.stopTest();

		Account objResellerAccAssert = [SELECT Id, First_Client_Add_Date__c FROM Account WHERE ZP_Firm_ID__c = '4561111111'];
		System.assertNotEquals(objResellerAccAssert.First_Client_Add_Date__c, null, 'First Client Add Date did not get updated on Reseller Account.');
	}

	/**
	 * @description This test method checks Account routing on update of Route to Market to Accountant
	 **/
	@isTest
	static void testRTMAccountantRouting() {
		Account objResellerAccount = [SELECT Id, Name FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setNumberOfActiveEEs(8)
			.setSoldBy(objResellerAccount.Id)
			.build();

		insert objCompanyAccount;

		Test.startTest();
		objCompanyAccount.Route_to_Market__c = AccountUtil.RTM_ACCOUNTANT;
		update objCompanyAccount;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(2, objAccountAssert.Account_Route_Count__c, 'Account route count did not increase for RTM Update');
	}

	/**
	 * @description Test method for createProductUpsell() in AccountTriggerHelper
	 */
	@isTest
	static void testCreateProductUpsell() {
		// Setup test data
		Account testAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).build();
		insert testAccount;

		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(testAccount.Id)
			.setFirstName('Test')
			.setLastName('User1')
			.setEmail('testuser@abccompany.com')
			.setZPUserRole('Payroll Admin')
			.build();
		insert objCompanyContact;

		// Change some values on the account to trigger the product upsell creation
		testAccount.Product_Interest__c = LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL;
		testAccount.Product_Interest_Countries__c = 'AZ';
		Test.startTest();
		update testAccount;
		Test.stopTest();

		// Query for the created Product Upsell records to verify correct creation
		List<Partnership_Interest__c> productUpsells = [SELECT Id, Account__c, Product_Interest__c, Product_Interest_Countries__c FROM Partnership_Interest__c WHERE Account__c = :testAccount.Id];
		System.assertEquals(1, productUpsells.size(), 'Product Upsell record should be created.');
		System.assertEquals(AccountUtil.EMPLOYER_OF_RECORD, productUpsells[0].Product_Interest__c, 'Product interest should be Employer of Record.');
		System.assertEquals('AZ', productUpsells[0].Product_Interest_Countries__c, 'Product interest countries should match.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test Cross-Sell and Upsell Opportunities are sent to Routing when Joined Date is updated
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testTierUpsellOpportunityRoutingOnJoinedDateUpte() {
		RingLead_Routing_Credentials__c objCredential = new RingLead_Routing_Credentials__c(Send_Opportunity_Endpoint__c = 'https://ringlead.sendopportunity.com/send', API_Token__c = 'api-token');
		insert objCredential;

		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setNumberOfActiveEEs(8)
			.setTier(AccountUtil.SIMPLE_TIER)
			.build();
		insert objAccount;

		Opportunity objInternationalPayrollOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('APD Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.EMPLOYER_OF_RECORD)
			.setType('Upsell')
			.setStage('Qualified')
			.build();
		objInternationalPayrollOppty.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		objInternationalPayrollOppty.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);

		OpportunityTriggerHelper.skipTrigger = true;
		insert objInternationalPayrollOppty;
		OpportunityTriggerHelper.skipTrigger = false;

		Test.startTest();
		objAccount.Joined_Date_Panda__c = Date.today();
		update objAccount;
		Test.stopTest();

		// assert if opportunity got updated
		Opportunity objOpportunityAssert = [SELECT Id, Name FROM Opportunity WHERE Id = :objInternationalPayrollOppty.Id];
		System.assertEquals('Opportunity Routed Successfully', objOpportunityAssert.Name);
	}

	/**
	 * @author:         Anurag Gautam
	 * @description:    Test method to test the legacy premium Cross-Sell and Upsell.
	 */
	@isTest
	static void testLegacyPremiumTierUpsell() {
		AccountTriggerHelper.skipTrigger = true;
		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.LEGACY_PREMIUM_PAYMENT_PLAN)
			.setNumberOfActiveEEs(8)
			.setTier(AccountUtil.LEGACY_PREMIUM_TIER)
			.build();
		insert objAccount;

		AccountTriggerHelper.skipTrigger = false;

		// create Cross-Sell and Upsell opportunity
		Opportunity objTierUpsell = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Leagacy Premium Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.LEGACY_PREMIUM_TIER)
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		insert objTierUpsell;

		Test.startTest();
		objAccount.Additional_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
		update objAccount;
		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, StageName, Upsell_Tier__c, Amount, Pricebook2.Name, Pricebook2Id FROM Opportunity WHERE Id = :objTierUpsell.Id];
		Pricebook2 objPricebook = [SELECT Id, Name FROM Pricebook2 WHERE Name = :AccountUtil.LEGACY_PREMIUM_PAYMENT_PLAN LIMIT 1];
		System.assertEquals(true, objOpptyAssert.Pricebook2Id == objPricebook.Id, 'Pricebook is not Legacy Premium');
		Test.stopTest();
	}

	/**
	 * @author:         Anurag Gautam
	 * @description:    Test method to test the premium Cross-Sell and Upsell.
	 */
	@isTest
	static void testPremiumTierUpsell() {
		AccountTriggerHelper.skipTrigger = true;
		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.PREMIUM_PAYMENT_PLAN)
			.setNumberOfActiveEEs(8)
			.setTier(AccountUtil.PREMIUM_TIER)
			.build();
		insert objAccount;

		AccountTriggerHelper.skipTrigger = false;

		// create Cross-Sell and Upsell opportunity
		Opportunity objTierUpsell = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Premium Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.PREMIUM_TIER)
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		insert objTierUpsell;

		Test.startTest();
		objAccount.Additional_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
		update objAccount;
		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, StageName, Upsell_Tier__c, Amount, Pricebook2.Name, Pricebook2Id FROM Opportunity WHERE Id = :objTierUpsell.Id];
		Pricebook2 objPricebook = [SELECT Id, Name FROM Pricebook2 WHERE Name = :AccountUtil.PREMIUM_PAYMENT_PLAN LIMIT 1];
		System.assertEquals(true, objOpptyAssert.Pricebook2Id == objPricebook.Id, 'Pricebook is not Premium');
		Test.stopTest();
	}

	/**
	 * @author:         Anurag Gautam
	 * @description:    Test method to test the premium CRB Cross-Sell and Upsell.
	 */
	@isTest
	static void testPremiumCRBTierUpsell() {
		AccountTriggerHelper.skipTrigger = true;
		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.CRB_PREMIUM_PAYMENT_PLAN)
			.setNumberOfActiveEEs(8)
			.setTier(AccountUtil.CRB_PREMIUM_TIER)
			.build();
		insert objAccount;

		AccountTriggerHelper.skipTrigger = false;

		// create Cross-Sell and Upsell opportunity
		Opportunity objTierUpsell = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Premium CRB Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.CRB_PREMIUM_TIER)
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		insert objTierUpsell;

		Test.startTest();
		objAccount.Additional_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
		update objAccount;
		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, StageName, Upsell_Tier__c, Amount, Pricebook2.Name, Pricebook2Id FROM Opportunity WHERE Id = :objTierUpsell.Id];
		Pricebook2 objPricebook = [SELECT Id, Name FROM Pricebook2 WHERE Name = :AccountUtil.CRB_PREMIUM_PAYMENT_PLAN LIMIT 1];
		System.assertEquals(true, objOpptyAssert.Pricebook2Id == objPricebook.Id, 'Pricebook is not Premium CRB');
		Test.stopTest();
	}

	/**
	 * @author:         Anurag Gautam
	 * @description:    Test method to test the premium Multi-EIN Cross-Sell and Upsell.
	 */
	@isTest
	static void testPremiumMultiEINTierUpsell() {
		AccountTriggerHelper.skipTrigger = true;
		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.MULTI_EIN_PREMIUM_PAYMENT_PLAN)
			.setNumberOfActiveEEs(8)
			.setTier(AccountUtil.MULTI_EIN_PREMIUM_TIER)
			.build();
		insert objAccount;

		AccountTriggerHelper.skipTrigger = false;

		// create Cross-Sell and Upsell opportunity
		Opportunity objTierUpsell = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Premium CRB Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.MULTI_EIN_PREMIUM_TIER)
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		insert objTierUpsell;

		Test.startTest();
		objAccount.Additional_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
		update objAccount;
		Opportunity objOpptyAssert = [SELECT Id, Additional_Opportunity_Services__c, StageName, Upsell_Tier__c, Amount, Pricebook2.Name, Pricebook2Id FROM Opportunity WHERE Id = :objTierUpsell.Id];
		Pricebook2 objPricebook = [SELECT Id, Name FROM Pricebook2 WHERE Name = :AccountUtil.MULTI_EIN_PREMIUM_PAYMENT_PLAN LIMIT 1];
		System.assertEquals(true, objOpptyAssert.Pricebook2Id == objPricebook.Id, 'Pricebook is not Premium Multi-EIN');
		Test.stopTest();
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if International Contrctor Payment Upsell opportunities are moved to Closed Won
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testICPUpsellOpportunityMovingToClosedWon() {
		// create company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('7878798789678')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setNumberOfActiveEEs(8)
			.setTier(AccountUtil.SIMPLE_TIER)
			.build();
		insert objAccount;

		objAccount.Product_Interest__c = 'international_contractor_payment_onboarding';
		update objAccount;

		Test.startTest();
		objAccount.Product_Interest__c = 'international_contractor_payment_paid';
		update objAccount;
		Test.stopTest();

		// assert if opportunity was moved to Closed Won
		Opportunity objOpportunityAssert = [SELECT Id, StageName FROM Opportunity WHERE AccountId = :objAccount.Id LIMIT 1];
		//System.assertEquals(OpportunityUtil.CLOSED_WON_STAGE, objOpportunityAssert.StageName);

		// assert if account additional services is updated to include International Contractor Payment
		Account objAccAssert = [SELECT Id, Additional_Services__c FROM Account WHERE Id = :objAccount.Id];
		//System.assertEquals(true, objAccAssert.Additional_Services__c.contains(AccountUtil.ADD_SERVICES_INTL_CONTRACTOR_PAID));
	}
	/**
	 * @description Test method to test the ICP Creation for Company Account
	 * @author      Anurag Gautam
	 * @param       NA
	 * @return      NA
	 **/

	@isTest
	public static void testCreateICP() {
		// get company account
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];

		// set product interest to ICP
		objCompanyAccount.Product_Interest__c = 'international_contractor_payment_onboarding';
		update objCompanyAccount;

		// get the ICP opportunity
		List<Opportunity> listOpportunities = [
			SELECT Id, Name, AccountId, Product_Interest__c, RecordType.Name, Upsell_Tier__c, Current_Tier__c, StageName, Type, CloseDate, RecordTypeId, CreatedDate
			FROM Opportunity
			WHERE AccountId = :objCompanyAccount.Id AND RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID
		];

		// assert the ICP opportunity
		System.assertEquals(1, listOpportunities.size(), 'ICP Opportunity not created for Account');
		// assert the ICP opportunity fields
		System.assertEquals('international_contractor_payment_onboarding', listOpportunities[0].Product_Interest__c, 'Product Interest not set correctly');
		System.assertEquals(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID, listOpportunities[0].RecordTypeId, 'Record Type not set correctly');
		System.assertEquals(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT, listOpportunities[0].Upsell_Tier__c, 'ICP Upsell Tier not set correctly');
		System.assertEquals(AccountUtil.CROSS_SELL, listOpportunities[0].Type, 'Type not set correctly');
		System.assertEquals(System.Today().addDays(90), listOpportunities[0].CloseDate, 'Close Date not set correctly');
	}

	/**
	 * @description Test method to test the ICP Creation for Company Account
	 * @author      Anurag Gautam
	 * @param       NA
	 * @return      NA
	 **/

	@isTest
	public static void testCloseICP() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];

		objCompanyAccount.Product_Interest__c = 'international_contractor_payment_onboarding';
		update objCompanyAccount;

		objCompanyAccount.Product_Interest__c = 'international_contractor_payment_paid';
		update objCompanyAccount;

		List<Opportunity> listOpportunities = [
			SELECT Id, Name, Additional_Opportunity_Services__c, Product_Interest__c, StageName
			FROM Opportunity
			WHERE AccountId = :objCompanyAccount.Id AND RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID
		];
		//System.assertEquals(1, listOpportunities.size(), 'ICP Opportunity not created for Account');
		//System.assertEquals(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT, listOpportunities[0].Additional_Opportunity_Services__c, 'Additional Opportunity Services not set correctly');
		//System.assertEquals(OpportunityUtil.CLOSED_WON_STAGE, listOpportunities[0].StageName,'Opportunity not moved to Closed Won');
	}

	/**
	 * @description Test method for ICP Creation in case of existing closed lost ICP Opp
	 * @author      Debasmita Rawooth
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	public static void testCreateICPNew() {
		Account objCompanyICPAccount = [SELECT Id, Name, Product_Interest__c, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = '1234567899' LIMIT 1];

		Test.startTest();
		objCompanyICPAccount.Product_Interest__c = 'international_contractor_payment_logacall';
		update objCompanyICPAccount;
		Test.stopTest();

		List<Opportunity> listOpportunitiesNew = [
			SELECT Id, Name, Product_Interest__c, StageName
			FROM Opportunity
			WHERE AccountId = :objCompanyICPAccount.Id AND RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID
		];
		System.assertEquals(2, listOpportunitiesNew.size(), 'Second ICP Opportunity not created for Account');
	}

	/**
	 * @description Test if Territory is updated on all open benefits opportunities when territory is updated on company account
	 **/
	@isTest
	public static void testTerritoryUpdateOnBenefitsOpportunities() {
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('86896897')
			.setNumberOfActiveEEs(8)
			.setNumberOfEmployees(8)
			.setZPCompanyOverallStatus('New')
			.setHasMedicalDeductions(true)
			.build();
		AccountTriggerHelper.skipTrigger = true;
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

		List<Opportunity> list_BenefitOpps = new List<Opportunity>{ objNewPlanOppty, objBYBOppty, objBOROppty };
		insert list_BenefitOpps;

		Test.startTest();
		objAcc.ZP_Company_Overall_Status__c = 'Active';
		objAcc.Number_of_Active_Employees__c = 25;
		objAcc.NumberOfEmployees = 25;
		objAcc.Benefits_Effective_Date__c = Date.today();

		objAcc.Territory__c = 'BMM Central';
		update objAcc;
		Test.stopTest();

		// Assert if territory is updated on benefits opportunities
		for (Opportunity objOpptyAssert : [SELECT Id, Territory__c FROM Opportunity WHERE Id = :objAcc.Id]) {
			System.assertEquals(objAcc.Territory__c, objOpptyAssert.Territory__c, 'Territory not updated on benefits opportunities');
		}
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Client BDO Opportunity updates create new benefits opportunities
	 **/
	@isTest
	static void testClientBDOOpportunityCreation() {
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
		Account objCompanyAccnt = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('8656544577')
			.setBillingCountry('United States')
			.setBillingState('California')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert objCompanyAccnt;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objOppty = TestUtils.createOpportunity(OpportunityUtil.ACQUISITION_OPPTY_RT_ID, objCompanyAccnt.Id, Date.today().addDays(10), 'Opp Name', 'MQL', false);
		objOppty.Type = 'New Business';
		objOppty.Initiated_by_Accountant__c = 'True';
		objOppty.Contribution_to_EE_Health_Coverage_cost__c = 'COMPANY_SPONSORED_HEALTH_INSURANCE';
		objOppty.Want_to_switch_brokers__c = true;
		objOppty.Open_to_Switching_Broker__c = 'MANUALLY_ADD';
		objOppty.Currently_Offer_Health_Benefits__c = 'Yes';
		objOppty.Which_Gusto_benefits_interested_in__c = 'HEALTH_INSURANCE';
		insert objOppty;

		Test.startTest();
		objCompanyAccnt.Number_Of_Active_Employees__c = 5;
		update objCompanyAccnt;
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
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
		Account objCompanyAccnt = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('34354364576')
			.setBillingCountry('United States')
			.setBillingState('California')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert objCompanyAccnt;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objOppty = TestUtils.createOpportunity(OpportunityUtil.ACQUISITION_OPPTY_RT_ID, objCompanyAccnt.Id, Date.today().addDays(10), 'Opp Name', 'MQL', false);
		objOppty.Type = 'New Business';
		objOppty.Interest_in_adding_benefits_to_Gusto__c = 'LEARNING_MORE';
		objOppty.Currently_Offer_Health_Benefits__c = 'False';
		insert objOppty;

		Test.startTest();
		objCompanyAccnt.Number_Of_Active_Employees__c = 5;
		update objCompanyAccnt;
		Test.stopTest();

		// Assert if new plan opportunities got created
		Integer intNewPlanCount = [
			SELECT COUNT()
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID AND AccountId = :objCompanyAccnt.Id AND LeadSource = :OpportunityUtil.EMPLOYER_BDO
		];
		System.assertEquals(1, intNewPlanCount, 'New plan opportunity not created');
	}
}