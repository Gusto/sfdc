/**
 * @author Aurobind Ravichandran
 * @date 3/28/2017
 * @see ZPCompanyTriggerHelper
 * @group ZP Staging Tables
 */
@isTest
public class ZPCompanyTriggerHelperTest {
	/**
	 * @author       Veeresh Kumar
	 * @description  Sets common data for all the test methods
	 **/
	@testSetup
	static void testData() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setZPCompanyBatchSize(10).build();
		insert objConfigSettings;

		List<Account> list_Accounts;
		List<User> list_Users;
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		User objAPIHerokuUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(UserInfo.getProfileId())
			.setUserRoleId(Label.Integration_Users_Role_Id)
			.setUserName('testheroku@gusto.com')
			.setFirstName('API')
			.setLastName('Heroku')
			.setEmail('testheroku@gusto.com')
			.setAlias('apiHer')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		User objNewUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(UserInfo.getProfileId())
			.setUserName('testnewuser@gusto.com')
			.setFirstName('Test')
			.setLastName('User')
			.setEmail('testnewuser@gusto.com')
			.setAlias('tstUser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		list_Users = new List<User>{ objAPIHerokuUser, objNewUser };

		System.runAs(objCurrentUser) {
			UserTriggerHelper.skipTrigger = true;
			insert list_Users;
			UserTriggerHelper.skipTrigger = false;
		}

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account 1').setZPFirmId('setupfirmId1').build();
		Account objCompany = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test ZP Company 2').setZPCompanyId('765665766').build();
		Account objResellerAccount1 = new TestDataFactory.AccountBuilder()
			.setZPFirmId('Reseller Account')
			.setName('Accountants R Us')
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setAMTier('Bronze')
			.build();
		list_Accounts = new List<Account>{ objResellerAccount, objResellerAccount1, objCompany };
		TriggerHandler.bypass('AccountTriggerHandler');
		insert list_Accounts;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('765665766')
			.setName('Test ZP Company 2')
			.setProcessingState(IntegrationUtils.MANUAL_ENQUEUE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setJoinedDate(System.today())
			.build();

		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('765665768')
			.setName('Test ZP Company 3')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setPartnerProgramCompanyDataId('12131323')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setManagingAccountingFirmId('Reseller Account 1')
			.build();
		List<ZP_Company__c> list_Companies = new List<ZP_Company__c>{ objZPCompany, objZPCompany1 };
		insert list_Companies;

		Lead_Randomize__c objRandomize = new Lead_Randomize__c(
			Current_Company_Account_Index__c = 1,
			Number_of_Company_Accounts__c = 2,
			Number_of_Company_Leads__c = 3,
			Number_of_Reseller_Accounts__c = 3,
			Number_of_Reseller_Leads__c = 3
		);
		insert objRandomize;
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Create a ZP Company record with Dead State and asserts if it is not processed.
	 **/
	@isTest
	static void createNewCompanyWithDeadState() {
		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId1')
			.setCompanyLeadId('companyLeadId1')
			.setName('Test ZP Company 1')
			.setProcessingState(IntegrationUtils.DEAD_STATE)
			.setCreatedAtDate(System.today())
			.setJoinedDate(System.today().addDays(-5))
			.build();

		ZPCompanyTriggerHelper.skipTrigger = true;
		insert objZPCompany;
		ZPCompanyTriggerHelper.skipTrigger = false;

		objZPCompany.Processing_State__c = IntegrationUtils.DEAD_STATE;
		objZPCompany.Joined_Date__c = System.today().addDays(-1);
		update objZPCompany;

		Test.stopTest();

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objZPCompanyAssert.Processing_State__c, 'Processing State not updated to Dead.');

		List<Lead> list_LeadsAssert = [SELECT Id, IsConverted FROM Lead WHERE ZP_Company_ID__c = :objZPCompany.Id__c];
		System.assertEquals(true, list_LeadsAssert.isEmpty(), 'List of leads not empty.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if an existing Lead is converted upon insertion of a ZP Company record, whose Created By Email matches with Lead email.
	 **/
	@isTest
	static void testLeadConversion() {
		User objAPIHerokuUser = [SELECT Id FROM User WHERE Email = 'testheroku@gusto.com' LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE ZP_Firm_Id__c = 'Reseller Account' LIMIT 1];
		System.runAs(objAPIHerokuUser) {
			Lead objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('Company1')
				.setLastName('Lead LName1')
				.setEmail('zpcompanylead1@zpcompany.com')
				.setPhone('8976567823')
				.setCompany('Test Company Name 1')
				.setOwnerId(UserInfo.getUserId())
				.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
				.setZPCompanyID('companyId1')
				.setReferredBy(objResellerAccount.Id)
				.build();

			TriggerHandler.bypass('LeadTriggerHandler');
			insert objLead;
			TriggerHandler.clearBypass('LeadTriggerHandler');

			System.assertEquals(UserInfo.getUserId(), objLead.OwnerId, 'Lead Owner not updated.');

			Test.startTest();

			ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
				.setZPCompanyId(objLead.ZP_Company_ID__c)
				.setName('Test ZP Company 1')
				.setCreatedByEmail(objLead.Email)
				.setProcessingState(IntegrationUtils.ERROR_STATE)
				.setCreatedAtDate(System.today())
				.setCompanyLeadNumberofEmployees(50)
				.setBenefitsEffectiveDate(System.today())
				.setNumberOfActiveEEs(6)
				.setContractorCount(8)
				.setAnchorPayDate(System.today())
				.build();
			insert objZPCompany;

			ZP_Company__c company = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
			System.assertEquals(IntegrationUtils.QUEUED_STATE, company.Processing_State__c, 'Processing state not updated to Queued.');

			Test.stopTest();

			// Assert if Lead is Conveted and Account, Oppty are created
			Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId, Status FROM Lead WHERE Id = :objLead.Id];
			Account objAccountAssert = [SELECT Id, Referred_By__c, Number_of_Active_Employees__c, Number_of_Active_Contractors__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
			Opportunity objOpportunityAssert = [SELECT Id, Referred_By__c, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE Id = :objLeadAssert.ConvertedOpportunityId];
			System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
			System.assertEquals(Config.LeadConversion.CONVERTED_LEAD_STATUS, objLeadAssert.Status, 'Lead Status not updated to converted status.');
			System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead on Lead.');
			System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');
			System.assertEquals(6, objAccountAssert.Number_of_Active_Employees__c, 'Number of Active Employees not updated on account.');
			System.assertEquals(8, objAccountAssert.Number_of_Active_Contractors__c, 'Number of Active Contractors not updated on account.');
			System.assertEquals(6, objOpportunityAssert.NumberOfEmployees__c, 'Number of Employees not updated on account.');
			System.assertEquals(8, objOpportunityAssert.Number_of_Contractors__c, 'Number of Contractors not updated on account.');
			System.assertEquals(null, objAccountAssert.Referred_By__c, 'Referred By not updated on Account.');
			System.assertEquals(null, objOpportunityAssert.Referred_By__c, 'Referred By not updated on Opportunity.');
			checkForExceptions();
		}
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Company Id on Lead is updated upon insertion of a ZP Company record.
	 **/
	@isTest
	static void testCompanyIdUpdateOnLead() {
		Account objResellerAccount = [SELECT Id, ZP_Firm_Id__c FROM Account WHERE ZP_Firm_Id__c = 'Reseller Account' LIMIT 1];
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId1')
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setReferredbyAccountingFirmID(objResellerAccount.ZP_Firm_Id__c)
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.build();
		insert objZPCompany;

		Test.stopTest();

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objZPCompanyAssert.Processing_State__c, 'Processing state not updated to Processed.');

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId, ZP_Company_ID__c FROM Lead WHERE Id = :objLead.Id];
		Account objAccountAssert = [SELECT Id, Referred_By__c, Number_of_Active_Employees__c, Number_of_Active_Contractors__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		Opportunity objOpportunityAssert = [SELECT Id, Referred_By__c, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE Id = :objLeadAssert.ConvertedOpportunityId];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated.');

		// Assert if ZP Company Id is updated on Lead.
		System.assertEquals(objZPCompany.Id__c, objLeadAssert.ZP_Company_ID__c, 'ZP Company id not populated on lead.');
		System.assertEquals(objResellerAccount.Id, objAccountAssert.Referred_By__c, 'Referred By not updated on Account.');
		System.assertEquals(objResellerAccount.Id, objOpportunityAssert.Referred_By__c, 'Referred By not updated on Opportunity.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if converted Opportunity has data from ZP Company Onboarding Funnel.
	 **/
	@isTest
	static void testExistingLeadWithFunnel() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		ZP_Company_Onboarding_Funnel__c objFunnel = new TestDataFactory.ZPCompanyOnboardingFunnelBuilder()
			.setCompanyId(objLead.ZP_Company_Id__c)
			.setSign('testSign')
			.setAddAddressesCompleted(true)
			.build();

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		insert objFunnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_Id__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.build();

		insert objZPCompany;

		Test.stopTest();

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objZPCompanyAssert.Processing_State__c, 'ZP Company Processing state not updated to Processed.');

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		// Assert whether Onboarding Funnel fields are updated on Opportunity
		Opportunity objOpportunityAssert = [SELECT Id, ZP_Company_Setup_Step__c FROM Opportunity WHERE Id = :objLeadAssert.ConvertedOpportunityId];
		System.assertEquals(objFunnel.Sign__c, objOpportunityAssert.ZP_Company_Setup_Step__c, 'ZP Company Setup Step not crrectly populated on opportunity.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if converted Opportunity has data from ZP Company Onboarding Funnel.
	 **/
	@isTest
	static void testUpdateSoldByAccountantLeadOnCompanyAccount() {
		List<Lead> list_LeadsToInsert = new List<Lead>();

		Lead objResellerLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('Reseller Company1')
			.setLastName('Reseller LName1')
			.setEmail('zpcompanyresellerlead@zpcompany.com')
			.setPhone('8976567821')
			.setCompany('Test Reseller Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPFirmId('firmId1')
			.build();
		list_LeadsToInsert.add(objResellerLead);

		Lead objCompanyLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.setZPCompanyLeadID('companyLeadId1')
			.setZPAccountantLeadID(objResellerLead.ZP_Firm_ID__c)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		list_LeadsToInsert.add(objCompanyLead);

		TriggerHandler.bypass('LeadTriggerHandler');
		insert list_LeadsToInsert;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objCompanyLead.ZP_Company_ID__c)
			.setCompanyLeadId(objCompanyLead.ZP_Company_Lead_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objCompanyLead.Email)
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setJoinedDate(System.today())
			.setAccountantLeadId(objResellerLead.ZP_Firm_Id__c)
			.build();
		insert objZPCompany;

		Test.stopTest();

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objZPCompanyAssert.Processing_State__c, 'ZP Company Processing state not updated to processed.');

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objCompanyLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		// Assert if Sold_By_Accountant_Lead__c on Account is updated with Reseller Lead Id.
		Account objAccount = [SELECT Id, Sold_By_Accountant_Lead__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		System.assertEquals(objResellerLead.Id, objAccount.Sold_By_Accountant_Lead__c, 'Sold By Accountant Lead not updated on account.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if a Company Lead is created and converted by the Partner Lead.
	 **/
	@isTest
	static void testLeadCreatedAndConvertedByPartner() {
		Account objResellerAccount = [SELECT Id, ZP_Firm_Id__c FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID AND ZP_Firm_Id__c = 'setupfirmId1' LIMIT 1];

		Lead objResellerLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('Reseller Company1')
			.setLastName('Reseller LName1')
			.setEmail('zpcompanyresellerlead@zpcompany.com')
			.setPhone('8976567821')
			.setCompany('Test Reseller Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPFirmId(objResellerAccount.ZP_Firm_Id__c)
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objResellerLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('zpCompanyId2')
			.setName('Test ZP Company 1')
			.setCreatedByEmail('zpcompanylead1@zpcompany.com')
			.setCompanyCreatedThrough(ZPCompanyUtil.ONBOARDING_COMPANIES_SERVICE)
			.setCompanyLeadLastName('Lead Last Name 1')
			.setCompanyLeadPhone('8976567823')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setAccountantLeadId(objResellerLead.ZP_Firm_Id__c)
			.setReferredbyAccountingFirmID(objResellerAccount.ZP_Firm_ID__c)
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setOriginalAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setReferralType(LeadUtil.REFERRAL_TYPE_UR)
			.setCompanyLeadSource('LinkedIn')
			.build();

		insert objZPCompany;

		Test.stopTest();

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [
			SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId, Referral_Type__c, MQL_Reason__c, Referred_By__c
			FROM Lead
			WHERE ZP_Company_ID__c = :objZPCompany.Id__c
		];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		System.assertEquals(objZPCompany.Referral_Type__c, objLeadAssert.Referral_Type__c, 'Referral Type not updated on lead.');
		System.assertEquals(objResellerAccount.Id, objLeadAssert.Referred_By__c, 'Referred by not updated on account.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PR, objLeadAssert.MQL_Reason__c, 'MQL Reason not updated on lead.');

		Account objAccountAssert = [SELECT Id, Referral_Type__c, Referred_By__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		// Assert if Referral Type on Account is updated with ZP Company referral Type.
		System.assertEquals(objZPCompany.Referral_Type__c, objAccountAssert.Referral_Type__c, 'Referral Type not updated on account.');

		// Assert if Referral By on Account is updated with Reseller Account Id.
		System.assertEquals(objResellerAccount.Id, objAccountAssert.Referred_By__c, 'Referred by not updated on account.');

		Opportunity objOpportunityAssert = [SELECT Id, Referral_Type__c, Referred_By__c FROM Opportunity WHERE Id = :objLeadAssert.ConvertedOpportunityId];
		System.assertEquals(objZPCompany.Referral_Type__c, objOpportunityAssert.Referral_Type__c, 'Referral Type not uppdated on opportunity.');
		System.assertEquals(objResellerAccount.Id, objOpportunityAssert.Referred_By__c, 'Referred By not updated on opportunity.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Lead is created via ZP Company sets MQL reason as Product Registration.
	 **/
	@isTest
	static void testLeadZPCompanyProductRegistration() {
		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('zpCompanyId1')
			.setName('Test ZP Company 1')
			.setCreatedByEmail('zpcompanylead1@zpcompany.com')
			.setCompanyCreatedThrough(ZPCompanyUtil.ONBOARDING_COMPANIES_SERVICE)
			.setCompanyLeadLastName('Lead Last Name 1')
			.setCompanyLeadPhone('8976567823')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadSource(LeadUtil.LEADSOURCE_WEB)
			.build();

		insert objZPCompany;

		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, MQL_Reason__c FROM Lead WHERE Email = :objZPCompany.Created_by_Email__c];
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROD_GEN, objLeadAssert.MQL_Reason__c, 'MQL Reason not updated on lead.');
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Anchor Pay Date of ZP Company is updated on related Account & Opportunity.
	 **/
	@isTest
	static void testAnchorPayDate() {
		List<ZP_Company__c> list_ZPCompanies;
		List<Account> list_Accounts;

		Account objAccountCompany1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 1').setZPCompanyId('companyId1').build();

		Account objAccountCompany2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 2').setZPCompanyId('companyId2').build();

		list_Accounts = new List<Account>{ objAccountCompany1, objAccountCompany2 };

		TriggerHandler.bypass('AccountTriggerHandler');
		insert list_Accounts;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Opportunity objCompanyOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setAccountId(objAccountCompany1.Id)
			.setName('Test Company opp 1')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.setCloseDate(System.today())
			.setSourceId(objAccountCompany1.ZP_Company_Id__c + '-newbusiness' + '-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year())
            .setZPCompanyId(objAccountCompany1.ZP_Company_Id__c)
			.build();

		TriggerHandler.bypass('OpportunityTriggerHandler');
		insert objCompanyOpportunity;
		TriggerHandler.clearBypass('OpportunityTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objAccountCompany1.ZP_Company_Id__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail('zpcompanylead1@zpcompany.com')
			.setAnchorPayDate(Date.today())
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setJoinedDate(System.today())
			.build();

		ZP_Company__c objZPCompany2 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objAccountCompany2.ZP_Company_Id__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail('zpcompanylead1@zpcompany.com')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setJoinedDate(System.today())
			.build();

		list_ZPCompanies = new List<ZP_Company__c>{ objZPCompany1, objZPCompany2 };
		insert list_ZPCompanies;

		Test.stopTest();

		// Assert if Anchor Pay Date on Account is updated with Anchor Pay Date of ZP Company.
		Account objAccountCompany1Assert = [SELECT Anchor_Pay_Date__c FROM Account WHERE Id = :objAccountCompany1.Id];
		System.assertEquals(objZPCompany1.Anchor_Pay_Date__c, objAccountCompany1Assert.Anchor_Pay_Date__c, 'APD not updated on account.');

		Account objAccountCompany2Assert = [SELECT Anchor_Pay_Date__c FROM Account WHERE Id = :objAccountCompany2.Id];
		System.assertEquals(null, objAccountCompany2Assert.Anchor_Pay_Date__c, 'APD not updated on account.');

		Opportunity objCompanyOpportunityAssert = [SELECT Anchor_Pay_Date__c FROM Opportunity WHERE Id = :objCompanyOpportunity.Id];
		System.assertEquals(objZPCompany1.Anchor_Pay_Date__c, objCompanyOpportunityAssert.Anchor_Pay_Date__c, 'APD not updated on opportunity.');

		checkForExceptions();
	}
	/**
	 * @author       Prity Kumari
	 * @description  Test if blank Referred By Accounting Firm field on ZP Company does not delete the Referred By field on Opportunity
	 */
	@isTest
	static void testReferredByAccFirmUpdate() {
		List<Account> list_Reseller_Accounts;

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();

		Account objResellerAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account1').setZPFirmId('987456124').build();

		list_Reseller_Accounts = new List<Account>{ objResellerAccount, objResellerAccount1 };

		// Skip Account Trigger for faster Account inserts
		TriggerHandler.bypass('AccountTriggerHandler');
		insert list_Reseller_Accounts;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName1')
			.setLastName('LName1')
			.setEmail('testuser1@test.com')
			.setPhone('8976567890')
			.setCompany('Test Accountant')
			.setOwnerId(UserInfo.getUserId())
			.setReferredBy(objResellerAccount.Id)
			.setLeadSource('LinkedIn')
			.build();

		// Skip Lead Trigger for faster Lead inserts
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setReferredbyAccountingFirmID(objResellerAccount.ZP_Firm_ID__c)
			.build();

		insert objZPCompany;

		Test.stopTest();

		Opportunity objOpp = [SELECT Id, ZP_Add_Company_Addresses__c, Referred_by__c, StageName FROM Opportunity WHERE ZP_Company_Id__c = :objZPCompany.Id__c];
		System.assertEquals(objOpp.Referred_by__c, objResellerAccount.Id, 'Referred by not updated on opportunity.');

		checkForExceptions();
	}

	// ZP PPCD to ZP Company Transition Test Methods
	/**
	 * @author       Praveen Sethu
	 * @description  Test if Sold By on Account and Opportunity are updated based on Managing Accounting Firm Id from ZP Company
	 */
	@isTest
	static void testSoldByUpdateBasedOnManagingAccountingFirm() {
		// Skip Account Trigger for faster Account inserts
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		// Create a company lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company')
			.setLastName('Lead LName')
			.setEmail('zpcompanylead@zpcompany.com')
			.setPhone('8976567890')
			.setCompany('Test Company Name')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource('LinkedIn')
			.build();
		insert objLead;

		// Create ZP Company which will trigger lead conversion [NO PPCD RECORD REQUIRED!!!]
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setCreatedByEmail(objLead.Email)
			.setName('Test ZP Company')
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setOriginalAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.build();

		insert objZPCompany;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		// Assert if Lead is Conveted and Account, Oppty are created
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		// Assert if Sold By and Original Firm is updated on Lead and Opportunity
		Account objAccountAssert = [SELECT Id, Sold_By__c, Original_Firm__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		System.assertEquals(objResellerAccount.Id, objAccountAssert.Sold_By__c, 'Sold By not correctly updated on account.');
		System.assertEquals(objResellerAccount.Id, objAccountAssert.Original_Firm__c, 'Original Firm not correctly populated on account.');

		Opportunity objOpptyAssert = [SELECT Id, Sold_By__c, Original_Firm__c FROM Opportunity WHERE Id = :objLeadAssert.ConvertedOpportunityId];
		System.assertEquals(objResellerAccount.Id, objOpptyAssert.Sold_By__c, 'Sold By not correctly updated on opportunity.');
		System.assertEquals(objResellerAccount.Id, objOpptyAssert.Original_Firm__c, 'Original Firm not correctly populated on account.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Billed To, Discount Eligible on Opportunity & Partner Billing,
	 * 					Reward Eligible on Account are updated based on Partner Billing from ZP Company
	 */
	@isTest
	static void testPartnerAttributionOnOpptyAndAccount() {
		List<Lead> list_LeadsToInsert = new List<Lead>();
		List<ZP_Company__c> list_ZPComapniesToInsert = new List<ZP_Company__c>();

		// Skip Account Trigger for faster Account inserts
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		// Create a company lead
		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource('LinkedIn')
			.build();
		list_LeadsToInsert.add(objLead1);

		Lead objLead2 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company 2')
			.setLastName('Lead LName 2')
			.setEmail('zpcompanylead2@zpcompany.com')
			.setPhone('8976567843')
			.setCompany('Test Company Name 2')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource('LinkedIn')
			.build();
		list_LeadsToInsert.add(objLead2);

		TriggerHandler.bypass('LeadTriggerHandler');
		insert list_LeadsToInsert;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		// Create ZP Company which will trigger lead conversion [NO PPCD RECORD REQUIRED!!!]
		Test.startTest();
		ZP_Company__c objZPCompanyPartnerBilled = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId1')
			.setCompanyLeadId('companyLeadId1')
			.setCreatedByEmail(objLead1.Email)
			.setName('Test ZP Company 1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setRewardEligible(true)
			.setOriginalAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.build();
		list_ZPComapniesToInsert.add(objZPCompanyPartnerBilled);

		ZP_Company__c objZPCompanyClientBilled = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId2')
			.setCompanyLeadId('companyLeadId2')
			.setCreatedByEmail(objLead2.Email)
			.setName('Test ZP Company 2')
			.setPartnerBilling(ZPCompanyUtil.BILLING_CLIENT_BILLED)
			.setRewardEligible(true)
			.build();
		list_ZPComapniesToInsert.add(objZPCompanyClientBilled);

		insert list_ZPComapniesToInsert;

		objZPCompanyPartnerBilled.Is_Original_Firm__c = true;
		update objZPCompanyPartnerBilled;
		Test.stopTest();

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadPartnerBilledAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead1.Id];

		System.assertEquals(true, objLeadPartnerBilledAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadPartnerBilledAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadPartnerBilledAssert.ConvertedOpportunityId, 'Converted account id not populated on Lead.');

		Lead objLeadClientBilledAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead2.Id];

		System.assertEquals(true, objLeadClientBilledAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadClientBilledAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadClientBilledAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		// Assert if Sold By is updated on Lead and Opportunity
		Account objAccountPartnerBilledAssert = [SELECT Id, Partner_Billing__c, Reward_Eligible__c FROM Account WHERE Id = :objLeadPartnerBilledAssert.ConvertedAccountId];
		System.assertEquals(objZPCompanyPartnerBilled.Partner_Billing__c, objAccountPartnerBilledAssert.Partner_Billing__c, 'Partner Billing not propertly populated on account.');
		System.assertEquals(true, objAccountPartnerBilledAssert.Reward_Eligible__c, 'Reward Eligible not set correctly on account.');

		Account objAccountClientBilledAssert = [SELECT Id, Partner_Billing__c, Reward_Eligible__c FROM Account WHERE Id = :objLeadClientBilledAssert.ConvertedAccountId];
		System.assertEquals(objZPCompanyClientBilled.Partner_Billing__c, objAccountClientBilledAssert.Partner_Billing__c, 'Partner Billing not propertly populated on account.');
		System.assertEquals(true, objAccountClientBilledAssert.Reward_Eligible__c, 'Reward Eligible not set correctly on account.');

		Opportunity objOpptyPartnerBilledAssert = [SELECT Id, Billed_To__c, Discount_Eligible__c FROM Opportunity WHERE Id = :objLeadPartnerBilledAssert.ConvertedOpportunityId];
		System.assertEquals(ZPCompanyUtil.BILLING_ACCOUNTANT_BILLED, objOpptyPartnerBilledAssert.Billed_To__c, 'Billed To not correctly populated on opportunity.');
		System.assertEquals(true, objOpptyPartnerBilledAssert.Discount_Eligible__c, 'Discount Eligible not set to true on opportunity.');

		Opportunity objOpptyClientBilledAssert = [SELECT Id, Billed_To__c, Discount_Eligible__c FROM Opportunity WHERE Id = :objLeadClientBilledAssert.ConvertedOpportunityId];
		System.assertEquals(ZPCompanyUtil.CLIENT_BILLED, objOpptyClientBilledAssert.Billed_To__c, 'Billed To not correctly populated on opportunity.');
		System.assertEquals(true, objOpptyClientBilledAssert.Discount_Eligible__c, 'Discount Eligible not set to true on opportunity.');

		// Update Asserts:
		Account objResellerAccountAssert = [SELECT Id, Reseller_Company__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(objAccountPartnerBilledAssert.Id, objResellerAccountAssert.Reseller_Company__c, 'Reseller Company not correctly populated on account.');

		checkForExceptions();
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test if Potential fraud is getting updated on Account from Zp Company
	 **/
	@isTest
	static void testPotentialFraudUpdate1() {
		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder().setZPCompanyId('companyId2').setName('Test ZP Company 2').setCreatedAtDate(System.today()).setPotentialFraud(true).build();

		insert objZPCompany;

		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Potential_Fraud_Account__c, Potential_Fraud_History__c FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(true, objAccountAssert.Potential_Fraud_Account__c, 'Potential Fraud not updated on Account.');
		System.assertEquals(true, objAccountAssert.Potential_Fraud_History__c, 'Potential Fraud History not updated on Account.');

		checkForExceptions();
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test if Potential fraud history should not get updated again on Account once updated
	 **/
	@isTest
	static void testPotentialFraudUpdate2() {
		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder().setZPCompanyId('companyId2').setName('Test ZP Company 2').setCreatedAtDate(System.today()).setPotentialFraud(true).build();

		insert objZPCompany;

		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Potential_Fraud_Account__c, Potential_Fraud_History__c FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(true, objAccountAssert.Potential_Fraud_Account__c, 'Potential Fraud not updated on Account.');
		System.assertEquals(true, objAccountAssert.Potential_Fraud_History__c, 'Potential Fraud History not updated on Account.');

		objZPCompany.Potential_Fraud__c = false;
		update objZPCompany;

		Account objAccountAssert2 = [SELECT Id, Potential_Fraud_Account__c, Potential_Fraud_History__c FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(false, objAccountAssert2.Potential_Fraud_Account__c, 'Potential Fraud not updated on Account.');
		System.assertEquals(true, objAccountAssert2.Potential_Fraud_History__c, 'Potential Fraud History not updated on Account.');

		checkForExceptions();
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test if Fraud ZP Companies are Not Processed
	 **/
	@isTest
	static void testFraudZPCompaniesAreNotProcessed() {
		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCreatedByEmail('fraudemail@uniromax.com')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.build();
		insert objZPCompany;

		Test.stopTest();

		// Assert processing state is set to Dead
		ZP_Company__c objZPCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objZPCompanyAssert.Processing_State__c, 'ZP Company Processing state not updated to Dead.');

		// Assert no Lead was created
		List<Lead> list_Leads = [SELECT Id FROM Lead WHERE Email = :objZPCompany.Created_By_Email__c];
		System.assertEquals(true, list_Leads.isEmpty(), 'Leads list not empty.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if a PPCD record is created from a ZP Company record.
	 **/
	@isTest
	static void testPPCDTransition() {
		// Skip Account Trigger for faster Account inserts
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource('LinkedIn')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();
		ZP_Company__c objZPCompanyReseller = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId1')
			.setCompanyLeadId('companyLeadId1')
			.setCreatedByEmail(objLead.Email)
			.setName('Test ZP Company 1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setRewardEligible(true)
			.setOriginalAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setPartnerProgramCompanyDataId('PPCD1')
			.build();

		insert objZPCompanyReseller;
		Test.stopTest();

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		Partner_Program_Company_Data__c objPartnerProgramAssert = [
			SELECT
				Id,
				Is_Original_Firm__c,
				Deleted_At__c,
				Partner_Billing__c,
				Reward_Eligible__c,
				Company_Id__c,
				Account__c,
				Managing_Accounting_Firm_Id__c,
				Managing_Accounting_Firm__c,
				Original_Accounting_Firm_Id__c,
				Original_Accounting_Firm__c
			FROM Partner_Program_Company_Data__c
			WHERE Id__c = :objZPCompanyReseller.Partner_Program_Company_Data_Id__c
		];

		System.assertEquals(objZPCompanyReseller.Is_Original_Firm__c, objPartnerProgramAssert.Is_Original_Firm__c, 'Is Original Firm not updated on PPCD.');
		System.assertEquals(objZPCompanyReseller.Deleted_At__c, objPartnerProgramAssert.Deleted_At__c, 'Deleted At not updated on PPCD.');
		System.assertEquals(objZPCompanyReseller.Partner_Billing__c, objPartnerProgramAssert.Partner_Billing__c, 'Partner Billing not updated on PPCD.');

		System.assertEquals(objZPCompanyReseller.ID__c, objPartnerProgramAssert.Company_Id__c, 'Company Id not updated on PPCD.');
		System.assertEquals(objLeadAssert.ConvertedAccountId, String.valueOf(objPartnerProgramAssert.Account__c), 'Account Id not updated on PPCD.');

		System.assertEquals(objZPCompanyReseller.Managing_Accounting_Firm_Id__c, objPartnerProgramAssert.Managing_Accounting_Firm_Id__c, 'Managing Accounting Firm Id not updated on PPCD.');
		System.assertEquals(objResellerAccount.Id, objPartnerProgramAssert.Managing_Accounting_Firm__c, 'Managing Accounting Firm not updated on PPCD.');

		System.assertEquals(objZPCompanyReseller.Original_Accounting_Firm_Id__c, objPartnerProgramAssert.Original_Accounting_Firm_Id__c, 'Original Accounting Firm Id not updated on PPCD.');
		System.assertEquals(objResellerAccount.Id, objPartnerProgramAssert.Original_Accounting_Firm__c, 'Original Accounting Firm not updated on PPCD.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Account & Opportunity fields are reset when Deleted_At__c is set to a non-null value
	 **/
	@isTest
	static void testResetAccAndOppFields() {
		// Skip Account Trigger for faster Account inserts
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource('LinkedIn')
			.build();
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();
		ZP_Company__c objZPCompanyReseller = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId1')
			.setCompanyLeadId('companyLeadId1')
			.setCreatedByEmail(objLead.Email)
			.setName('Test ZP Company 1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setOriginalAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setPartnerProgramCompanyDataId('PPCD1')
			.build();

		insert objZPCompanyReseller;

		objZPCompanyReseller.Deleted_At__c = System.now();
		update objZPCompanyReseller;

		Test.stopTest();

		Account objAccountUpdateAssert = [SELECT Id, Sold_By__c, Partner_Billing__c, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :objZPCompanyReseller.ID__c];
		System.assertEquals(null, objAccountUpdateAssert.Sold_By__c, 'Sold By not correctly set on account.');
		System.assertEquals(null, objAccountUpdateAssert.Partner_Billing__c, 'Partner Billing not correctly set on account.');
		System.assertEquals(false, objAccountUpdateAssert.Reward_Eligible__c, 'Reward Eligible not correctly set on account.');

		Opportunity objOpportunityUpdateAssert = [SELECT Id, Billed_To__c, Sold_By__c FROM Opportunity WHERE ZP_Company_ID__c = :objZPCompanyReseller.Id__c];

		System.assertEquals(null, objOpportunityUpdateAssert.Sold_By__c, 'Sold By not correctly set on opportunity.');
		System.assertEquals(null, objOpportunityUpdateAssert.Billed_To__c, 'Billed To not correctly set on opportunity.');

		checkForExceptions();
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test if Partner Attribution Fields are set properly based on Reward Eligibility
	 **/
	@isTest
	static void testCustomersReferralLink() {
		// Skip Account Trigger for faster Account inserts
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		TriggerHandler.bypass('LeadTriggerHandler');
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setZPCompanyId('123456')
			.setReferredBy(objResellerAccount.Id)
			.setLeadSource('LinkedIn')
			.build();
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		TriggerHandler.bypass('OpportunityTriggerHandler');
		// Convert Lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });
		Lead objCmpLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		// Assert if lead was converted
		System.assertEquals(true, objCmpLead.IsConverted, 'Lead not converted.');

		Test.startTest();
		ZP_Company__c objZPCompanyReseller = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_Id__c)
			.setCompanyLeadId(objLead.ZP_Company_Id__c)
			.setCreatedByEmail(objLead.Email)
			.setName('Test ZP Company 1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setRewardEligible(true)
			.setOriginalAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setPartnerProgramCompanyDataId('PPCD1')
			.setReferredbyAccountingFirmID(objResellerAccount.ZP_Firm_ID__c)
			.setJoinedDate(Date.today())
			.setWithFundedPayrolls(true)
			.build();

		insert objZPCompanyReseller;
		Test.stopTest();

		Account objCompanyAcctAssert = [SELECT Id, Referred_By__c FROM Account WHERE ZP_Company_ID__c = :objZPCompanyReseller.ID__c];
		System.assertEquals(objResellerAccount.Id, objCompanyAcctAssert.Referred_By__c, 'Referred by not correctly set on account.');

		Account objResellerAcctAssert = [
			SELECT Id, Customers_Referral_Link__c, (SELECT Id, Is_Active_Customer__c, With_Funded_Payrolls__c FROM AccountsReferredBy__r)
			FROM Account
			WHERE Id = :objResellerAccount.Id
		];
		System.assertEquals(1, objResellerAcctAssert.AccountsReferredBy__r.size(), 'Number of - Accounts Referred By not correctly set on account.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Old_Managing_Accounting_Firm_ID__c is populated on ZP Company Fields,
	 * 					upon changing the Accountant Lead Id.
	 **/
	@isTest
	static void testChangeAccoutantLeadId() {
		List<Account> list_Accounts;

		Account objResellerAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account 1').setZPFirmId('zpfirmId1').build();

		Account objResellerAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account 2').setZPFirmId('zpfirmId2').build();

		list_Accounts = new List<Account>{ objResellerAccount1, objResellerAccount2 };

		TriggerHandler.bypass('AccountTriggerHandler');
		insert list_Accounts;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource('LinkedIn')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId1')
			.setCompanyLeadId('companyLeadId1')
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setJoinedDate(System.today().addDays(-5))
			.setAccountantLeadID(objResellerAccount1.ZP_Firm_ID__c)
			.setManagingAccountingFirmId(objResellerAccount1.ZP_Firm_ID__c)
			.setOnboardingSurveyOfferBenefits(false)
			.setFilingCountryCode('USA')
			.setFilingStateCode('NY')
			.setSkipOnboardingOppCreation(true)
			.build();

		ZPCompanyTriggerHelper.skipTrigger = true;
		insert objZPCompany;
		ZPCompanyTriggerHelper.skipTrigger = false;

		objZPCompany.Processing_State__c = IntegrationUtils.QUEUED_STATE;
		objZPCompany.Accountant_Lead_Id__c = objResellerAccount2.ZP_Firm_ID__c;
		objZPCompany.Managing_Accounting_Firm_Id__c = objResellerAccount2.ZP_Firm_ID__c;
		objZPCompany.Onboarding_Survey_Interested_Benefit_Opt__c = ZPCompanyUtil.SMALL_GROUP_HEALTH_INSURANCE;
		objZPCompany.Joined_Date__c = System.today().addDays(-1);
		objZPCompany.Filing_State_Code__c = 'MI';
		update objZPCompany;

		Test.stopTest();

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Processing_State__c, Old_Managing_Accounting_Firm_ID__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objZPCompanyAssert.Processing_State__c, 'ZP Company processing state not updated to processed.');
		System.assertEquals(objResellerAccount1.ZP_Firm_ID__c, objZPCompanyAssert.Old_Managing_Accounting_Firm_ID__c, 'ZP Firm Id not matching Old Managing Acc Firm id.');

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Sold_By__c is populated on related Account & Opportunity with
	 * 					the help of ZP Accounting Firm, ZP User, ZP User Role records.
	 **/
	@isTest
	static void companyCreatedByPartnerWithoutLead() {
		List<ZP_User_Role__c> list_ZPUserRoles;

		Test.startTest();

		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('firdId1')
			.setName('test name')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAt(System.today().addDays(1))
			.build();
		insert objZPAccFirm;

		ZP_Company_Onboarding_Funnel__c objFunnel = new TestDataFactory.ZPCompanyOnboardingFunnelBuilder().setCompanyId('companyId1').setSign('testSign').setAddAddressesCompleted(true).build();

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		insert objFunnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('userId1')
			.setExternalKey('userExternalKey1')
			.setEmail('zpuser1@zpcompany.com')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();

		ZPUserTriggerHelper.skipTrigger = true;
		insert objZPUser;
		ZPUserTriggerHelper.skipTrigger = false;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRole1')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objFunnel.Company_Id__c)
			.setType('Role::PayrollAdmin')
			.setIsPrimary(true)
			.setAccFirmId(objZPAccFirm.Id__c)
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(objZPUser.Created_At__c)
			.build();

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRole2')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objFunnel.Company_Id__c)
			.setType('Role::Accountant')
			.setAccFirmId(objZPAccFirm.Id__c)
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(objZPUser.Created_At__c)
			.build();

		list_ZPUserRoles = new List<ZP_User_Role__c>{ objZPUserRole1, objZPUserRole2 };
		ZPUserRoleTriggerHelper.skipTrigger = true;
		insert list_ZPUserRoles;
		ZPUserRoleTriggerHelper.skipTrigger = false;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objFunnel.Company_Id__c)
			.setName('Test ZP Company 1')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setRewardEligible(true)
			.setPartnerProgramCompanyDataId('PPCD1')
			.setManagingAccountingFirmId(objZPAccFirm.Id__c)
			.build();

		insert objZPCompany;

		Test.stopTest();

		Account objResellerAccountAssert = [SELECT Id, RecordTypeId FROM Account WHERE ZP_Firm_Id__c = :objZPAccFirm.Id__c];

		System.assertEquals(AccountUtil.RESELLER_ACCOUNT_RT_ID, objResellerAccountAssert.RecordTypeId, 'Account Record Type is invalid.');

		Account objCompanyAccountAssert = [SELECT Id, Sold_By__c FROM Account WHERE ZP_Company_Id__c = :objZPCompany.Id__c];
		System.assertEquals(objResellerAccountAssert.Id, objCompanyAccountAssert.Sold_By__c, 'Sold By not correctly populated on account.');

		Opportunity objCompanyOppAssert = [SELECT Id, Sold_By__c, False_Sold_By__c FROM Opportunity WHERE ZP_Company_Id__c = :objZPCompany.Id__c];
		System.assertEquals(objResellerAccountAssert.Id, objCompanyOppAssert.Sold_By__c, 'Sold By not correctly populated on opportunity.');
		System.assertEquals(true, objCompanyOppAssert.False_Sold_By__c, 'False Sold By not correctly updated on opportunity.');
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Throws exceptions
	 * <br>Result - List of Exceptions should not be empty
	 **/
	@isTest
	static void testExceptions() {
		ZPCompanyTriggerHelper.blnTestExceptions = true;

		Test.startTest();

		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder().setZPCompanyId('companyId1').setName('Test ZP Company 1').setProcessingState(IntegrationUtils.QUEUED_STATE).build();

		insert objZPCompany1;

		ZP_Company__c objZPCompany2 = new TestDataFactory.ZPCompanyBuilder().setZPCompanyId('companyId2').setName('Test ZP Company 2').setProcessingState(IntegrationUtils.QUEUED_STATE).build();

		ZPCompanyTriggerHelper.skipTrigger = true;
		insert objZPCompany2;
		ZPCompanyTriggerHelper.skipTrigger = false;

		update objZPCompany2;

		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'ZPCompanyTriggerHelper'];
		System.assertEquals(false, list_Exceptions.isEmpty(), 'Leads list is empty.');

		ZPCompanyTriggerHelper.blnTestExceptions = false;
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if no exceptions are logged
	 **/
	public static void checkForExceptions() {
		// Assert no exceptions are logged from Task Trigger
		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'ZPCompanyTriggerHelper'];
		System.assertEquals(0, list_Exceptions.size(), 'Exception during zp company processing.');
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test if Account and PPCD records are linked when there is no created by email
	 **/
	@isTest
	static void testPPCDCreateWithBlankEmail() {
		Test.startTest();
		// Create ZP Company and Set Blank Created By Email
		ZP_Company__c objCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('1212121')
			.setName('Test ZP Company 1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setRewardEligible(true)
			.setPartnerProgramCompanyDataId('PPCD1')
			.build();
		insert objCompany;

		Test.stopTest();

		// Assert Company Account and Company Opportunity got created
		Account objAccntAssert = [SELECT Id, (SELECT Id FROM Opportunities WHERE RecordType.Name = 'Acquisition') FROM Account WHERE ZP_Company_Id__c = :objCompany.Id__c];
		System.assertNotEquals(null, objAccntAssert, 'Account not created.');
		System.assertEquals(1, objAccntAssert.Opportunities.size(), 'Opportunity not created or multiple opportunities.');

		Partner_Program_Company_Data__c objPPCD = [SELECT Id, Account__c FROM Partner_Program_Company_Data__c WHERE Company_Id__c = :objCompany.Id__c];
		System.assertEquals(objAccntAssert.Id, objPPCD.Account__c, 'Account Id not updated on PPCD.');
	}
	/**
	 * @author       Prity Kumari
	 * @description  Test if ZP Company populates Active Contractors and Employees on create
	 **/
	@isTest
	static void testAccountEmployeeUpdate() {

		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('1234887')
			.setName('Test ZP Company 1')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setNumberOfActiveEEs(6)
			.setContractorCount(3)
			.build();
		insert objZPCompany;
	
		Test.stopTest();

		Account objAssertAccount = [SELECT Id, Number_of_Active_Contractors__c, Number_of_Active_Employees__c FROM Account WHERE ZP_Company_ID__c = '1234887'];
		System.assertEquals(6, objAssertAccount.Number_of_Active_Employees__c, 'Employee counts do not match');
		System.assertEquals(3, objAssertAccount.Number_of_Active_Contractors__c, 'Contractor counts do not match');

		Opportunity objAssertOpportunity = [SELECT Id, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE ZP_Company_ID__c = '1234887'];
		System.assertEquals(6, objAssertOpportunity.NumberOfEmployees__c, 'Employee counts do not match');
		System.assertEquals(3, objAssertOpportunity.Number_of_Contractors__c, 'Contractor counts do not match');
		// Finally check if there are any exceptions logged
		checkForExceptions();
		
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test ZP Company Processing during Bulk Updates
	 **/
	@isTest
	static void testZPCompanyBulkUpdate() {
		// Test if zp companies are processed by queuable jobs during bulk update
		// Expectation - All records must go into Queued Status and Batch job will process records

		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = config.ZP_Company_Batch_Size__c.intValue() != null && config.ZP_Company_Batch_Size__c.intValue() != 0 ? config.ZP_Company_Batch_Size__c.intValue() : 3;
		intBatch = intBatch + 10;

		List<ZP_Company__c> list_Companies = new List<ZP_Company__c>();
		for (Integer i = 0; i < intBatch; i++) {
			ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
				.setZPCompanyId(String.valueOf(i))
				.setName('Test ZP Company ' + i)
				.setProcessingState(IntegrationUtils.QUEUED_STATE)
				.setCreatedAtDate(System.today())
				.build();
			list_Companies.add(objZPCompany);
		}

		Test.startTest();
		insert list_Companies;
		Test.stopTest();

		Integer intQueuedRecords = [SELECT COUNT() FROM ZP_Company__c WHERE Processing_State__c = 'Queued'];
		// Assert all of them are Queued Status
		System.assertEquals(intBatch, intQueuedRecords, 'Queued records not matching batch size.');
	}

	@isTest
	private static void createNewCompanyWithExistingLeadWithoutCompanyId() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('Test')
			.setLastName('Test')
			.setEmail('test.abc1@gusto.com')
			.setCompany('Test Company')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('legalzoom')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		objLead.OwnerId = UserInfo.getUserId();
		System.assertEquals(UserInfo.getUserId(), objLead.OwnerId, 'Lead owner is incorrect.');

		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('OpportunityTriggerHandler');

		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setName('Test Company')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('test.abc1@gusto.com')
			.build();

		insert objZPCompany;
		Test.stopTest();

		ZP_Company__c objCompanyRec = [SELECT Id, Processing_State__c, Message__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals('Processed', objCompanyRec.Processing_State__c, 'ZP Company Processing state not updated to Processed.');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if dummy updates are not processed on ZP Company
	 **/
	@isTest
	private static void testDummyUpdateOnZPCompany() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		System.assertEquals(UserInfo.getUserId(), objLead.OwnerId, 'Lead owner is incorrect.');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.build();
		insert objZPCompany;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to Queued.');

		Test.stopTest();

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		objCompanyAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to processed.');

		// Perform dummy update without updating any fields
		update objCompanyAssert;

		objCompanyAssert = [SELECT Id, Processing_State__c, Message__c, No_Update_Counter__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to processed.');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Message__c, 'ZP Company messagenot set correctly.');
		System.assertEquals(1, objCompanyAssert.No_Update_Counter__c, 'ZP Company Number of updates incorrect.');
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Test if Matching ZP Accounting Firm by email the update ZP Company's account and related Opp
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	private static void testMatchingZPAcctFirmByEmailOnZpCompany() {
		Account objResellerAccount = [SELECT Id, ZP_Firm_Id__c FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID AND ZP_Firm_Id__c = 'setupfirmId1' LIMIT 1];

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId(objResellerAccount.ZP_Firm_Id__c)
			.setEmail(objLead.Email)
			.setName('test name')
			.setAccountantLeadId('1212121')
			.setCreatedAt(DateTime.now().addDays(-1))
			.build();
		insert objZPAccFirm;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.build();
		insert objZPCompany;

		ZP_Company__c objCompany = [SELECT Id, Deleted_At__c, ID__c, Processing_State__c, Message__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		objCompany.Deleted_At__c = System.now();
		update objCompany;
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompany.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();
		checkForExceptions();
		Opportunity objCompanyOppAssert = [SELECT Id, False_Sold_By__c FROM Opportunity WHERE ZP_Company_ID__c = :objZPCompany.Id__c];
		System.assertEquals(false, objCompanyOppAssert.False_Sold_By__c, 'False Sold By is incorrect on opportunity.');
	}

	/**
	 * @Author		Prity Kumari
	 * @description	Test if Sold By populates after Closed Lost
	 * @Parm		void
	 * @Return		void
	 **/
	@isTest
	static void testSoldByFromAccount() {
		TriggerHandler.bypass('AccountTriggerHandler, OpportunityTriggerHandler');

		List<Account> listAccounts = [
			SELECT Id, Discount__c, ZP_Firm_Id__c, RecordTypeId, Name
			FROM Account
			WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID AND ZP_Firm_Id__c = 'Reseller Account'
		];
		ZP_Company__c objZPCompany = [SELECT Id, Managing_Accounting_Firm_Id__c FROM ZP_Company__c WHERE Id__c = '765665768'];

		Test.startTest();
		Opportunity objOpportunity = [SELECT Id, StageName FROM Opportunity WHERE ZP_Company_Id__c = '765665768'];
		objOpportunity.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
		update objOpportunity;
		objZPCompany.Managing_Accounting_Firm_Id__c = listAccounts[0].ZP_Firm_Id__c;
		update objZPCompany;
		Test.stopTest();

		List<Opportunity> listOppAssert = [SELECT Id, Name, RecordType.Name, StageName, Sold_By__r.ZP_Firm_Id__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(listAccounts[0].ZP_Firm_Id__c, listOppAssert[0].Sold_By__r.ZP_Firm_Id__c, 'ZP Firm Id is incorrect on account.');

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test if Account ParentId gets populated from ZP Company on insert
	 **/
	@isTest
	private static void testZPCompanyInsertWithParentCompany() {
		Account objParentCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('7653567890').build();

		TriggerHandler.bypass('AccountTriggerHandler');
		insert objParentCompanyAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('87535678995')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.build();
		objZPCompany.Parent_Company_Id__c = objParentCompanyAccount.ZP_Company_ID__c;
		insert objZPCompany;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		objCompanyAssert = [SELECT Id, Processing_State__c, Message__c, ID__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to processed.');

		// Assert if Lead is Converted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		Account objAccountAssert = [SELECT Id, Name, ParentId FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		System.assertEquals(objParentCompanyAccount.Id, objAccountAssert.ParentId, 'Parent Id not correctly populated on account.');
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test if Account ParentId gets updated on update of ZP Company
	 **/
	@isTest
	private static void testZPCompanyUpdateWithParentCompany() {
		Account objParentCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('7653567890').build();

		TriggerHandler.bypass('AccountTriggerHandler');
		insert objParentCompanyAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('87535678995')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.build();
		insert objZPCompany;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		objCompanyAssert = [SELECT Id, Processing_State__c, Message__c, ID__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to processed.');

		// Assert if Lead is Converted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		Account objAccountAssert1 = [SELECT Id, Name, ParentId FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		System.assertEquals(null, objAccountAssert1.ParentId, 'Account Parent Id not null.');

		objZPCompany.Parent_Company_Id__c = objParentCompanyAccount.ZP_Company_ID__c;
		update objZPCompany;

		Account objAccountAssert2 = [SELECT Id, Name, ParentId FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		System.assertEquals(objParentCompanyAccount.Id, objAccountAssert2.ParentId, 'Account Parent Id is incorrect.');
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test if Account ParentId gets updated on Account created by already converted Lead
	 **/
	@isTest
	private static void testParentUpdateWithLeadConversion() {
		Account objParentCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('7653567890').build();

		TriggerHandler.bypass('AccountTriggerHandler');
		insert objParentCompanyAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('87535678995')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();

		Test.startTest();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		// Convert Lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted opportunity id not populated on Lead.');

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.build();
		objZPCompany.Parent_Company_Id__c = objParentCompanyAccount.ZP_Company_ID__c;
		insert objZPCompany;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		objCompanyAssert = [SELECT Id, Processing_State__c, Message__c, ID__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to processed.');

		Account objAccountAssert = [SELECT Id, Name, ParentId FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		System.assertEquals(objParentCompanyAccount.Id, objAccountAssert.ParentId, 'Parent Id not correctly populated on account.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test that Account does not get created and error handling works if Company Id & Parent Id are same
	 **/
	@isTest
	private static void testParentCompayIdValidation1() {
		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('87535678995')
			.setZPParentCompanyId('87535678995')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		insert objZPCompany;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to processed.');

		Test.stopTest();

		objCompanyAssert = [SELECT Id, Id__c, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to dead.');

		List<Account> list_accountAssert = [SELECT Id, Name, ParentId FROM Account WHERE ZP_Company_ID__c = :objCompanyAssert.Id__c];
		System.assertEquals(0, list_accountAssert.size(), 'Account list not empty.');
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test that Account does not get updated if Parent company Id is an existing child in the hiererachy of the same account(upto 5 levels)
	 **/
	@isTest
	private static void testParentCompayIdValidation2() {
		Test.startTest();
		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('9953567891')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		insert objZPCompany1;

		ZP_Company__c objZPCompany2 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('9953567892')
			.setZPParentCompanyId('9953567891')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		insert objZPCompany2;

		objZPCompany1.Parent_Company_Id__c = '9953567892';
		update objZPCompany1;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		objCompanyAssert = [SELECT Id, Id__c, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to dead.');

		Account objAccountAssert = [SELECT Id, Name, ParentId FROM Account WHERE ZP_Company_ID__c = :objCompanyAssert.Id__c];
		System.assertEquals(null, objAccountAssert.ParentId, 'Account Parent id is not null.');
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test that ZP Company gets processed and Message fie4ld is updated if Parent company Id doesnot exist on Salesforce
	 **/
	@isTest
	private static void testParentCompayIdValidation3() {
		Test.startTest();

		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('9953567892')
			.setZPParentCompanyId('12340000')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		insert objZPCompany1;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		objCompanyAssert = [SELECT Id, Id__c, Processing_State__c, Message__c FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to processed.');
		System.assertEquals('Parent Company not found, no parent has been set.', objCompanyAssert.Message__c, 'ZP Company Message is incorrect.');

		Account objAccountAssert = [SELECT Id, Name, ParentId FROM Account WHERE ZP_Company_ID__c = :objCompanyAssert.Id__c];
		System.assertEquals(null, objAccountAssert.ParentId, 'Parent Id is not null on account.');
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test that Owner on Account, Contact and Opportunity gets updated based on Active Parent Account Owner
	 **/
	@isTest
	private static void testOwnerUpdate1() {
		User objUser = [SELECT Id FROM User WHERE Email = 'testnewuser@gusto.com' LIMIT 1];

		Test.startTest();
		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('9953567891')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		objZPCompany1.OwnerId = objUser.Id;
		insert objZPCompany1;

		ZP_Company__c objZPCompany2 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('9953567892')
			.setZPParentCompanyId('9953567891')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		insert objZPCompany2;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c, OwnerId FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		ZP_Company__c objCompanyAssert1 = [SELECT Id, Id__c, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert1.Processing_State__c, 'ZP Company processing status not updated to processed.');

		ZP_Company__c objCompanyAssert2 = [SELECT Id, Id__c, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany2.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert2.Processing_State__c, 'ZP Company processing status not updated to processed.');

		Account objParentAccountAssert = [SELECT Id, Name, ParentId, OwnerId FROM Account WHERE ZP_Company_ID__c = :objCompanyAssert1.Id__c LIMIT 1];

		Account objChildAccountAssert = [SELECT Id, Name, ParentId, OwnerId FROM Account WHERE ZP_Company_ID__c = :objCompanyAssert2.Id__c LIMIT 1];
		System.assertEquals(objParentAccountAssert.OwnerId, objChildAccountAssert.OwnerId, 'Account Owner incorrect on child account.');

		Opportunity objOpportunityAssert = [SELECT Id, Name, OwnerId FROM Opportunity WHERE ZP_Company_ID__c = :objCompanyAssert2.Id__c LIMIT 1];
		System.assertEquals(objParentAccountAssert.OwnerId, objOpportunityAssert.OwnerId, 'Account Owner incorrect on child opportunity.');
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test that Owner on Account and Opportunity gets updated based on Active Parent Account Owner
	 **/
	@isTest
	private static void testOwnerUpdate2() {
		User objUser = [SELECT Id FROM User WHERE Email = 'testnewuser@gusto.com' LIMIT 1];

		Test.startTest();
		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('9953567891')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		objZPCompany1.OwnerId = objUser.Id;
		insert objZPCompany1;

		ZP_Company__c objZPCompany2 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('9953567892')
			.setName('Test ZP Company 1')
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(5)
			.build();
		insert objZPCompany2;

		objZPCompany2.Parent_Company_Id__c = '9953567891';
		update objZPCompany2;

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c, OwnerId FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompanyAssert.Processing_State__c, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		ZP_Company__c objCompanyAssert1 = [SELECT Id, Id__c, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert1.Processing_State__c, 'ZP Company processing status not updated to processed.');

		ZP_Company__c objCompanyAssert2 = [SELECT Id, Id__c, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany2.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert2.Processing_State__c, 'ZP Company processing status not updated to processed.');

		Account objParentAccountAssert = [SELECT Id, Name, ParentId, OwnerId FROM Account WHERE ZP_Company_ID__c = :objCompanyAssert1.Id__c LIMIT 1];

		Account objChildAccountAssert = [SELECT Id, Name, ParentId, OwnerId FROM Account WHERE ZP_Company_ID__c = :objCompanyAssert2.Id__c LIMIT 1];
		System.assertEquals(objParentAccountAssert.OwnerId, objChildAccountAssert.OwnerId, 'Child Account owner is incorrect.');

		Opportunity objOpportunityAssert = [SELECT Id, Name, OwnerId FROM Opportunity WHERE ZP_Company_ID__c = :objCompanyAssert2.Id__c LIMIT 1];
		System.assertEquals(objParentAccountAssert.OwnerId, objOpportunityAssert.OwnerId, 'Child Opportunity owner is incorrect.');
	}

	/**
	 * @author       Swati Arya
	 * @description  Test if NAICS Code and Has Benefits 401 populated on account
	 **/
	@isTest
	static void testNAICSCodeAndHasBenefits401k() {
		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder().setZPCompanyId('SwatiTest1234').setName('Swati Test Company').setNAICSCode('Test123').setHasBenefits401k(true).build();

		insert objZPCompany;

		Test.stopTest();

		Account objAccountAssert = [SELECT Id, NAICS_Code__c, Has_Benefits_401k__c FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(objZPCompany.NAICS_Code__c, objAccountAssert.NAICS_Code__c, 'NAICS Code incorrect on account.');
		System.assertEquals(objZPCompany.Has_Benefits_401k__c, objAccountAssert.Has_Benefits_401k__c, 'Has Benefits 401K is incorrect on account.');

		checkForExceptions();
	}

	/**
	 * @author       Swati Arya
	 * @description  Test if Embedded Company Account and Contact is created when Gusto Embedded Payroll Company is set to true
	 **/
	@isTest
	static void testEmbeddedCompanyAccountCreation() {
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('SwatiTest1234')
			.setZPCompanyId('112233445566')
			.setName('Swati Test Company')
			.setEmbeddedPayrollCompany(true)
			.build();

		insert objZPCompany;

		Test.stopTest();

		Account objAccountAssert = [SELECT Id, RecordType.Name FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(objAccountAssert.RecordType.Name, 'Embedded Company', 'Account Record Type is not correct.');

		objZPCompany.Embedded_Payroll_Company__c = false;

		update objZPCompany;

		Account objAccountAssert1 = [SELECT Id, RecordType.Name FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(objAccountAssert1.RecordType.Name, 'Company', 'Account Record Type is incorrect.');

		checkForExceptions();
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Embedded Partner population on ZP Company record for matching partner id and referred by field on account
	 **/
	@isTest
	static void testEmbeddedPatrnerAccOnZPCompanyMatchingPartnerId() {
		Test.startTest();

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 1').setZPCompanyId('111111111111111').build();

		insert objAccount;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('22222222222')
			.setName('Swati Test Company')
			.setEmbeddedPayrollCompany(true)
			.setEmbeddedPartnerId('111111111111111')
			.build();

		insert objZPCompany;

		Test.stopTest();

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Embedded_Partner__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];

		System.assertEquals(objZPCompanyAssert.Embedded_Partner__c, objAccount.Id, 'ZP Company Embedded Partner should be same as Account Inserted');

		Account objAccountAssert = [SELECT Id, RecordType.Name, Referred_By__c FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(objAccountAssert.RecordType.Name, 'Embedded Company', 'Account Record Type is incorrect.');
		System.assertEquals(objAccountAssert.Referred_By__c, objZPCompanyAssert.Embedded_Partner__c, 'Referred by on account should be same as zp company embedded partner');

		checkForExceptions();
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Embedded Partner population on ZP Company record for matching partner uuid
	 **/
	@isTest
	static void testEmbeddedPatrnerAccOnZPCompanyMatchingPartnerUUID() {
		Test.startTest();

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 1').setZPCompanyId('111111111111111').build();

		insert objAccount;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('22222222222')
			.setName('Swati Test Company')
			.setEmbeddedPayrollCompany(true)
			.setEmbeddedPartnerUUID('111111111111111')
			.build();

		insert objZPCompany;

		Test.stopTest();

		Account objAccountAssert = [SELECT Id, RecordType.Name FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(objAccountAssert.RecordType.Name, 'Embedded Company', 'Account Record Type is incorrect.');

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Embedded_Partner__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];

		System.assertEquals(objZPCompanyAssert.Embedded_Partner__c, objAccount.Id, 'ZP Company Embedded Partner should be same as Account Inserted');

		checkForExceptions();
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Referred By field population on account null when no matching partner record is found
	 **/
	@isTest
	static void testReferredByOnAccountNullEmbeddedPayroll() {
		Test.startTest();

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 1').setZPCompanyId('111111111111111').build();

		insert objAccount;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('22222222222')
			.setName('Swati Test Company')
			.setEmbeddedPayrollCompany(true)
			.setEmbeddedPartnerId('222222222222')
			.build();

		insert objZPCompany;

		Test.stopTest();

		ZP_Company__c objZPCompanyAssert = [SELECT Id, Embedded_Partner__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];

		System.assertEquals(null, objZPCompanyAssert.Embedded_Partner__c, 'Embedded partner should be null since there is no matching partner account');

		Account objAccountAssert = [SELECT Id, RecordType.Name, Referred_By__c FROM Account WHERE ZP_Company_ID__c = :objZPCompany.Id__c];

		System.assertEquals(objAccountAssert.RecordType.Name, 'Embedded Company', 'Account Record Type is incorrect.');
		System.assertEquals(null, objAccountAssert.Referred_By__c, 'Referred by on account should be null');

		checkForExceptions();
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Account & related Opportunities to Unqualified.
	 **/
	@isTest
	static void testUpdateAccAndOppToUnqualified() {
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('firdId1')
			.setName('test name')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAt(System.today())
			.setEmail('firmid01@test.com')
			.build();

		ZPAccountingFirmTriggerHelper.skipTrigger = true;
		insert objZPAccFirm;
		ZPAccountingFirmTriggerHelper.skipTrigger = false;

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('zpcompanyid01')
			.setName('Test ZP Company 1')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCreatedByEmail('firmid01@test.com')
			.setDeletedAt(System.now())
			.setOriginalAccountingFirmId(objZPAccFirm.Id__c)
			.setProcessingState((IntegrationUtils.QUEUED_STATE))
			.build();

		insert objZPCompany;

		Test.stopTest();

		Account objCompanyAccountAssert = [SELECT Id, Qualified_Status__c, Qualified_Status_Detail__c FROM Account WHERE ZP_Company_Id__c = :objZPCompany.Id__c];
		System.assertEquals(AccountUtil.QUALIFIED_STATUS_UNQUALIFIED, objCompanyAccountAssert.Qualified_Status__c, 'Account Qualified status is incorrect.');
		System.assertEquals(AccountUtil.QUALIFIED_STATUS_DETAIL_DELETED_ACCOUNT, objCompanyAccountAssert.Qualified_Status_Detail__c, 'Account Qualified status detail is incorrect.');

		Opportunity objCompanyOppAssert = [SELECT Id, StageName, Stage_Detail__c FROM Opportunity WHERE ZP_Company_Id__c = :objZPCompany.Id__c];
		System.assertEquals(OpportunityUtil.CLOSED_LOST_STAGE, objCompanyOppAssert.StageName, 'Opportunity Stage not Closed Lost.');
		System.assertEquals(OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL, objCompanyOppAssert.Stage_Detail__c, 'Opportunity Stage detail is incorrect.');

		checkForExceptions();
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test if embedded opportunites are created for embedded companies
	 **/
	@isTest
	static void testOpptyCreationForEmbeddedCompany() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Embedded')
			.setLastName('last name 1')
			.setEmail('embeded@payrolldemo.com')
			.setPhone('8976567823')
			.setCompany('Embedded Company 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('22543464576')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setNumberOfActiveEEs(6)
			.setContractorCount(8)
			.setAnchorPayDate(System.today())
			.setEmbeddedPayrollCompany(true)
			.build();
		insert objZPCompany;

		ZP_Company__c company = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(company.Processing_State__c, IntegrationUtils.QUEUED_STATE, 'ZP Company processing status not updated to queued.');

		Test.stopTest();

		// Assert if Lead is Conveted into Account and no opportunity is created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];
		Account objAccountAssert = [
			SELECT
				Id,
				Number_of_Active_Employees__c,
				Number_of_Active_Contractors__c,
				(SELECT Id FROM Opportunities WHERE RecordTypeId = :Cache.getRecordTypeId('Opportunity', 'Embedded Company Opportunity'))
			FROM Account
			WHERE Id = :objLeadAssert.ConvertedAccountId
		];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Converted account id not populated on Lead.');
		System.assertEquals(1, objAccountAssert.Opportunities.size(), 'Number of opportunities is not 1.');

		checkForExceptions();
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Generic test method to test all integrations between zp company and account/opportunity.
	 **/
	@isTest
	static void testCompanyToAccountOpptyIntegration() {
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('55765645435')
			.setName('Product Experiments Demo')
			.setCreatedByEmail('product@experiments.com')
			.setCompanyCreatedThrough(ZPCompanyUtil.ONBOARDING_COMPANIES_SERVICE)
			.setCompanyLeadLastName('Lead Last Name 1')
			.setCompanyLeadPhone('8976567823')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadSource(LeadUtil.LEADSOURCE_WEB)
			.setProductExperiments(ZPCompanyUtil.PRIORITY_SUPPORT_EXPERIMENT_FLAT_FEE)
			.build();
		insert objZPCompany;
		Test.stopTest();

		System.assertEquals(ZPCompanyUtil.PRIORITY_SUPPORT_EXPERIMENT_FLAT_FEE, objZPCompany.Product_Experiments__c, 'ZP Company Product Experiment is incorrect.');

		// Assert statements to validate if product experiments sycned to Account & Opportunity
		Account objAccAsert = [SELECT Id, Product_Experiments__c FROM Account WHERE ZP_Company_Id__c = :objZPCompany.Id__c];
		System.assertEquals(objZPCompany.Product_Experiments__c, objAccAsert.Product_Experiments__c, 'Account Product Experiment is incorrect.');

		Opportunity objOpptyAssert = [SELECT Id, Product_Experiments_Opportunity__c FROM Opportunity WHERE AccountId = :objAccAsert.Id];
		System.assertEquals(objZPCompany.Product_Experiments__c, objOpptyAssert.Product_Experiments_Opportunity__c, 'Opportunity Product Experiment is incorrect.');
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test lead conversion with existing contact matching the same email address as lead.
	 **/
	@isTest
	static void testLeadConversionWithExistingContact() {
		// skip core object triggers
		LeadTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		// create a company lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('leaddemo@gmail.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.build();
		insert objLead;

		// create a company account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company 1').setZPCompanyId('22543464576').build();
		insert objAccount;

		// create a company contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setFirstName('Test')
			.setLastName('last name 1')
			.setEmail(objLead.Email)
			.setAccountId(objAccount.Id)
			.build();
		insert objContact;

		Test.startTest();
		// create a zp company with the same email address as lead
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('987987889')
			.setName('Company Demo 1')
			.setCreatedByEmail(objLead.Email)
			.setCompanyCreatedThrough(ZPCompanyUtil.ONBOARDING_COMPANIES_SERVICE)
			.setCreatedAtDate(System.today())
			.build();
		insert objZPCompany;
		Test.stopTest();

		// assert if lead got converted to new account, existing contact
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead not converted.');
		System.assertNotEquals(objAccount.Id, objLeadAssert.ConvertedAccountId, 'Lead converted to new account');
		System.assertEquals(objContact.Id, objLeadAssert.ConvertedContactId, 'Lead not converted to existing contact.');
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test processing of companies linked to large firms
	 */
	@isTest
	static void testProcessingLargeFirms() {
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('7756161242710583').build();

		// Skip Account Trigger for faster Account inserts
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName1')
			.setLastName('LName1')
			.setEmail('testuser1@test.com')
			.setPhone('8976567890')
			.setCompany('Test Accountant')
			.setOwnerId(UserInfo.getUserId())
			.setReferredBy(objResellerAccount.Id)
			.setLeadSource('LinkedIn')
			.build();

		// Skip Lead Trigger for faster Lead inserts
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.build();
		insert objZPCompany;

		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, IsConverted FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'Company not Processed');

		checkForExceptions();
	}
	/**
	 * @author       Anurag Gautam
	 * @description  Test if ZP Company have Product interest values
	 **/
	@isTest
	static void testProductInterestUpdate() {
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('1234')
			.setName('Test ZP Company 1')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setNumberOfActiveEEs(4)
			.setContractorCount(5)
			.build();
		insert objZPCompany;
		objZPCompany.Product_Interest_Countries__c = 'US;CA;IN;';
		objZPCompany.Product_Interest__c = 'international_payroll_add_iee;';
		update objZPCompany;

		Test.stopTest();
		Account objAssertAccount = [SELECT Id, Product_Interest_Countries__c, Product_Interest__c FROM Account WHERE ZP_Company_ID__c = '1234'];
		System.assertEquals(true, objAssertAccount.Product_Interest_Countries__c.contains('US'), 'US is the part of Product Interest countries.');
		System.assertEquals(true, objAssertAccount.Product_Interest_Countries__c.contains('CA'), 'Canada is the part of Product Interest countries.');
		System.assertEquals(true, objAssertAccount.Product_Interest_Countries__c.contains('IN'), 'India is the part of Product Interest countries.');
		System.assertEquals('international_payroll_add_iee', objAssertAccount.Product_Interest__c, 'Product Interest value is updated.');
	}

	/**
	 * @author       Ankit C
	 * @description  Test if Help Journey Routing is updated on Account if ZP Company has Has_any_Invited_International_Employee__c true.
	 **/
	@isTest
	static void testInvitedInternationalEmployeeUpdate() {
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('12344321567')
			.setName('Test ZP 12344321567')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setNumberOfActiveEEs(4)
			.setInvitedInternationalEmployee(true)
			.build();
		insert objZPCompany;
		Test.stopTest();

		Account objAccount = [SELECT Id, Help_Journey_Routing__c FROM Account WHERE ZP_Company_ID__c = '12344321567'];
		Assert.isTrue(objAccount.Help_Journey_Routing__c.contains(ZPCompanyTriggerHelper.GUSTO_GLOBAL), 'Help Journey Routing was not updated');
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test if Confirmed MRB is updated on Account if ZP Company has Confirmed_MRB__c true.
	 **/
	@isTest
	static void testInformationUpdateOnAccount() {
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('12344321567')
			.setName('Test ZP 12344321567')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setNumberOfActiveEEs(4)
			.setConfirmedMRB(true)
			.setWorkersCompStatus('eligible_for_renewal')
			.set401KProvider('testprovider')
			.build();
		insert objZPCompany;
		Test.stopTest();

		Account objAccount = [SELECT Id, Confirmed_MRB__c,Workers_Comp_Status__c,Provider_401K__c  FROM Account WHERE ZP_Company_ID__c = '12344321567'];
		Assert.isTrue(objAccount.Confirmed_MRB__c, 'Confirmed MRB was not updated');
		Assert.areEqual(objAccount.Workers_Comp_Status__c, objZPCompany.Workers_Comp_Status__c, 'Worker Comp Status is incorrect.');
		Assert.areEqual(objAccount.Provider_401K__c, objZPCompany.Provider_401K__c, '401k Provider is incorrect.');
	}

	/**
	 * @See       ZPCompanyQueue
	 * @description  Test prioritized processing.
	 **/
	@isTest
	static void testPrioritizedProcessing() {
		// Skip Account Trigger for faster Account inserts
		//Given a reseller account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		//Given a list of ZP Companies
		List<ZP_Company__c> list_testZPCompanies = new List<ZP_Company__c>();
		for (Integer i = 0; i < 17; i++) {
			ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
				.setZPCompanyId('12344321567' + i)
				.setName('Test ZP ' + i)
				.setProcessingState(IntegrationUtils.QUEUED_STATE)
				.setCreatedAtDate(System.today())
				.setNumberOfActiveEEs(4)
				.build();
			list_testZPCompanies.add(objZPCompany);
		}
		insert list_testZPCompanies;
		Test.startTest();
		//When some ZP Companies have a field getting updated thats prioritized
		for (Integer i = 0; i < list_testZPCompanies.size(); i++) {
			if (Math.mod(i, 2) == 0) {
				list_testZPCompanies[i].Managing_Accounting_Firm_Id__c = objResellerAccount.ZP_Firm_ID__c;
			}
		}
		update list_testZPCompanies;
		Test.stopTest();
		//Then the ZP Companies with the prioritized field updated should be processed first
		List<ZP_Company__c> listZPCompanies = [SELECT Id, Processing_State__c, Managing_Accounting_Firm_Id__c FROM ZP_Company__c WHERE Id IN :list_testZPCompanies];
		for (ZP_Company__c objZPCompany : listZPCompanies) {
			if (objZPCompany.Managing_Accounting_Firm_Id__c != null) {
				Assert.areEqual(IntegrationUtils.PROCESSED_STATE, objZPCompany.Processing_State__c, 'ZP Company not processed');
			} else {
				Assert.areEqual(IntegrationUtils.QUEUED_STATE, objZPCompany.Processing_State__c, 'ZP Company not queued');
			}
		}

		checkForExceptions();
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test if BDO fields are mapped from ZP Company to opportunity
	 **/
	@isTest
	static void testBDOFieldsUpdatesOnOpportunity() {
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('12344321569')
			.setName('Test ZP 12344321567')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setNumberOfActiveEEs(4)
			.setContributionToEEHealthCoverage('Yes')
			.setCurrentOfferHealthBenefits('No')
			.setExistingHealthRenewalDate('2024-05-08')
			.setInterestInAddingBenefitsToGusto('Yes')
			.setInterestedInOfferingHIToEmp('Yes')
			.setOpenToSwitchingBroker('USE_GUSTO')
			.build();
		insert objZPCompany;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Name FROM Account WHERE ZP_Company_ID__c = '12344321569'];
		Opportunity objOpportunityAssert = [
			SELECT
				Id,
				Contribution_to_EE_Health_Coverage_cost__c,
				Currently_Offer_Health_Benefits__c,
				Existing_Health_Benefits_Renewal_Date__c,
				Interest_in_adding_benefits_to_Gusto__c,
				Interested_in_offering_HI_to_employees__c,
				Open_to_Switching_Broker__c
			FROM Opportunity
			WHERE AccountId = :objAccountAssert.Id
		];

		System.assertEquals(
			objOpportunityAssert.Contribution_to_EE_Health_Coverage_cost__c,
			objZPCompany.Contribution_to_EE_Health_Coverage_cost__c,
			'Contribution_to_EE_Health_Coverage_cost__c was not updated'
		);
		System.assertEquals(objOpportunityAssert.Currently_Offer_Health_Benefits__c, objZPCompany.Currently_Offer_Health_Benefits__c, 'Currently_Offer_Health_Benefits__c was not updated');
		System.assertEquals(
			objOpportunityAssert.Existing_Health_Benefits_Renewal_Date__c,
			objZPCompany.Existing_Health_Benefits_Renewal_Date__c,
			'Existing_Health_Benefits_Renewal_Date__c was not updated'
		);
		System.assertEquals(
			objOpportunityAssert.Interest_in_adding_benefits_to_Gusto__c,
			objZPCompany.Interest_in_adding_benefits_to_Gusto__c,
			'Interest_in_adding_benefits_to_Gusto__c was not updated'
		);
		System.assertEquals(
			objOpportunityAssert.Interested_in_offering_HI_to_employees__c,
			objZPCompany.Interested_in_offering_HI_to_employees__c,
			'Interested_in_offering_HI_to_employees__c was not updated'
		);
		System.assertEquals(objOpportunityAssert.Open_to_Switching_Broker__c, objZPCompany.Open_to_Switching_Broker__c, 'Open_to_Switching_Broker__c was not updated');
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test if Last Payroll Run date is mapped from ZP Company to Account on Insert
	 **/
	@isTest
	static void testLastPayrollRunDateInsert() {
		Test.startTest();
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('12344321544')
			.setName('Test ZP 12344321544')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setNumberOfActiveEEs(4)
			.setLastPayrollRunDate(System.today() - 2)
			.build();
		insert objZPCompany;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Name, Last_Payroll_Run_Date__c FROM Account WHERE ZP_Company_ID__c = '12344321544'];
		System.assertEquals(objAccountAssert.Last_Payroll_Run_Date__c, objZPCompany.Last_Payroll_Run_Date__c, 'Last_Payroll_Run_Date__c was not updated on Account.');
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test if Last Payroll Run date is mapped from ZP Company to Account on Update
	 **/
	@isTest
	static void testLastPayrollRunDateUpdate() {
		
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('12344321545')
			.setName('Test ZP 12344321545')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setNumberOfActiveEEs(4)
			.setLastPayrollRunDate(System.today() - 2)
			.build();
		insert objZPCompany;

		Test.startTest();
		objZPCompany.Last_Payroll_Run_Date__c  = System.today() - 5;
		update objZPCompany;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Name, Last_Payroll_Run_Date__c FROM Account WHERE ZP_Company_ID__c = '12344321545'];
		System.assertEquals(objAccountAssert.Last_Payroll_Run_Date__c, objZPCompany.Last_Payroll_Run_Date__c, 'Last_Payroll_Run_Date__c was not updated on Account.');
	}
}