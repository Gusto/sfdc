@isTest
public class GFLeadTriggerHelperTest {
	@testSetup
	static void setupTestData() {
		//create configuration setup
		Configuration_Settings__c objConfig = new TestDataFactory.ConfigurationSettingsBuilder().setZPOnbFunelBatchSize(4).setZPCompanyBatchSize(5).setGFLeadReprocessingLimit(0).build();
		insert objConfig;

		// Create Lead_Randomize__c Custom Setting
		Lead_Randomize__c objRandomize = new Lead_Randomize__c(Current_Company_Lead_Index__c = 1, Number_of_Company_Leads__c = 2, Number_of_Reseller_Leads__c = 2);
		insert objRandomize;

		List<User> list_Users;
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		User objAPIHerokuUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(UserInfo.getProfileId())
			.setUserRoleId(LeadUtil.ID_INTEGRATION_USERS_ROLE)
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

		list_Users = new List<User>{ objAPIHerokuUser };

		System.runAs(objCurrentUser) {
			UserTriggerHelper.skipTrigger = true;
			insert list_Users;
			UserTriggerHelper.skipTrigger = false;
		}
	}

	@isTest
	static void processNewCompanyLeadData() {
		GFLeadTriggerHelper.queue = true;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test.abc@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Source__c = 'Outbound';
		insert gfLead;

		Lead l = [SELECT Id, Visitor_Id__c, Session_Id__c, IsConverted FROM Lead WHERE email = 'test.test.abc@gusto.com'];
		update gfLead;
		system.assertEquals('12345', l.Visitor_Id__c);
		system.assertEquals('12345', l.Session_Id__c);
	}

	@isTest
	static void processCompanyContactInfo() {
		AccountTriggerHelper.skipTrigger = false;
		Account account = (Account) SmartFactory.createSObject('Account');
		account.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		insert account;

		test.startTest();

		ContactTriggerHelper.skipTrigger = false;
		Contact cntct = (Contact) SmartFactory.createSObject('Contact');
		cntct.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
		cntct.AccountId = account.id;
		cntct.Infer_Fit_Score__c = 'D';
		cntct.Email = 'testuer@abccompany.com';
		insert cntct;

		GFLeadTriggerHelper.queue = false;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'testuer@abccompany.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Source__c = 'Outbound';
		insert gfLead;

		GFLeadTriggerHelper.getContactInfoForUpdate(cntct, 'lead form submission');
		Set<String> companyIdSet = new Set<String>();
		companyIdSet.add(account.Id);
		GFLeadTriggerHelper helper = new GFLeadTriggerHelper();
		helper.queryAccounts(companyIdSet, new Set<String>());
	}

	@isTest
	static void processResellerContactInfo() {
		AccountTriggerHelper.skipTrigger = false;
		Account account = (Account) SmartFactory.createSObject('Account');
		account.RecordTypeId = Cache.getRecordTypeId('Account', 'Reseller');
		account.ZP_Company_ID__c = 'Company3214325';
		account.Zp_Firm_id__c = '44444444444444';
		insert account;

		test.startTest();

		ContactTriggerHelper.skipTrigger = false;
		Contact cntct = (Contact) SmartFactory.createSObject('Contact');
		cntct.RecordTypeId = Cache.getRecordTypeId('Contact', 'Reseller');
		cntct.AccountId = account.id;
		cntct.Infer_Fit_Score__c = 'D';
		cntct.Email = 'testuer@abccompany.com';
		insert cntct;

		GFLeadTriggerHelper.queue = false;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'testuer@abccompany.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Reseller';
		gfLead.Source__c = 'Outbound';
		insert gfLead;

		GFLeadTriggerHelper.getContactInfoForUpdate(cntct, 'lead form submission');
		Set<String> set_FirmIds = new Set<String>();
		set_FirmIds.add(account.Id);
		GFLeadTriggerHelper helper = new GFLeadTriggerHelper();
		helper.queryAccounts(new Set<String>(), set_FirmIds);
	}

	@isTest
	static void processXeroCompanyLeadData() {
		GFLeadTriggerHelper.queue = true;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test.abc@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Created_At__c = system.now();
		gfLead.Source__c = 'xero_partnership';
		gfLead.Campaign__c = 'Xero0719_Reduced';
		insert gfLead;

		List<Lead> l = [SELECT Id, Visitor_Id__c, Session_Id__c, IsConverted FROM Lead WHERE email = 'test.test.abc@gusto.com'];
	}

	@isTest
	static void processXeroCompanyLeadData1() {
		Lead l = new Lead();
		l.FirstName = 'Test';
		l.LastName = 'Test';
		l.RecordTypeId = cache.getRecordTypeId('Lead', 'Company');
		l.Company = 'Test';
		l.Email = 'test.test@gusto.com';
		l.External_Accountant_Email__c = 'test@test3.com';
		insert l;

		GFLeadTriggerHelper.queue = true;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test.abc@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Source__c = 'xero_migration_partner';
		gfLead.Campaign__c = 'Xero0719_Reduced';
		gfLead.External_Accountant_Email__c = 'test@test2.com';
		insert gfLead;

		List<Lead> lead = [SELECT Id, Visitor_Id__c, Session_Id__c, IsConverted FROM Lead WHERE email IN ('test.test.abc@gusto.com', 'test@test2.com')];
		//system.assertEquals(2, lead.size());
		//system.assertEquals('12345', l.Session_Id__c);
	}

	@isTest
	static void processXeroCompanyLeadData2() {
		Lead l = new Lead();
		l.FirstName = 'Test';
		l.LastName = 'Test';
		l.RecordTypeId = cache.getRecordTypeId('Lead', 'Company');
		l.Company = 'Test';
		l.Email = 'test.test@gusto.com';
		l.External_Accountant_Email__c = 'test@test2.com';
		insert l;

		GFLeadTriggerHelper.queue = true;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test.abc@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Source__c = 'xero_partnership';
		gfLead.Campaign__c = 'Xero0719_Reduced';
		gfLead.External_Accountant_Email__c = 'test@test2.com';
		insert gfLead;

		List<Lead> lead = [SELECT Id, Visitor_Id__c, Session_Id__c, IsConverted FROM Lead WHERE email IN ('test.test.abc@gusto.com', 'test@test2.com')];
		//system.assertEquals(1, lead.size());
		//system.assertEquals('12345', l.Session_Id__c);
	}

	@isTest
	static void processSecondCompanyLeadData() {
		GFLeadTriggerHelper.queue = true;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test.abc@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Source__c = 'LinkedIn';
		insert gfLead;

		Lead l = [SELECT Id, Visitor_Id__c, Session_Id__c, IsConverted FROM Lead WHERE email = 'test.test.abc@gusto.com'];
		system.assertEquals(gfLead.Visitor_Id__c, l.Visitor_Id__c);
		system.assertEquals(gfLead.Session_Id__c, l.Session_Id__c);

		GF_Lead__c gfLead1 = new GF_Lead__c();
		gfLead1.First_Name__c = 'test';
		gfLead1.Last_Name__c = 'test';
		gfLead1.Email__c = 'test.test.abc@gusto.com';
		gfLead1.Company_Name__c = 'Test';
		gfLead1.Session_Id__c = '123456';
		gfLead1.Visitor_Id__c = '123456';
		gfLead1.Lead_Type__c = 'Company';
		gfLead1.External_Practice_Id__c = '123354dts';
		gfLead1.Source__c = 'LinkedIn';
		insert gfLead1;

		gfLead1 = [SELECT Id, Processing_State__c, Message__c, Session_Id__c FROM GF_Lead__c WHERE id = :gfLead1.id];
		system.assertEquals('Processed', gfLead1.Processing_State__c);
		system.assertEquals('Processed', gfLead1.Message__c);

		l = [SELECT Id, Visitor_Id__c, Session_Id__c, IsConverted, email FROM Lead WHERE id = :l.Id];
		system.assertEquals(gfLead.Visitor_Id__c, l.Visitor_Id__c);
		system.assertEquals(gfLead1.Session_Id__c, l.Session_Id__c);
	}

	@isTest
	static void processNewAccountantLeadData() {
		GFLeadTriggerHelper.queue = true;

		Lead l = new Lead();
		l.FirstName = 'Test';
		l.LastName = 'Test';
		l.RecordTypeId = cache.getRecordTypeId('Lead', 'Reseller');
		l.Company = 'Test';
		l.Email = 'test.test@gusto.com';
		insert l;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Accountant';
		insert gfLead;

		l = [SELECT Id, Visitor_Id__c, Session_Id__c FROM Lead l WHERE id = :l.id];
		system.assertEquals(gfLead.Visitor_Id__c, l.Visitor_Id__c);
		system.assertEquals(gfLead.Session_Id__c, l.Session_Id__c);

		Gf_Lead__c gfLead2 = new Gf_Lead__c();
		gfLead2.First_Name__c = 'test';
		gfLead2.Last_Name__c = 'test';
		gfLead2.Email__c = 'test.test@gusto.com';
		gfLead2.Company_Name__c = 'Test';
		gfLead2.Session_Id__c = '123456';
		gfLead2.Visitor_Id__c = '123456';
		gfLead2.Lead_Type__c = 'Accountant';
		insert gfLead2;

		gfLead2 = [SELECT Id, Processing_State__c, Message__c, Session_Id__c FROM GF_Lead__c WHERE id = :gfLead2.id];
		system.assertEquals('Processed', gfLead2.Processing_State__c);
		system.assertEquals('Processed', gfLead2.Message__c);

		l = [SELECT Id, Visitor_Id__c, Session_Id__c FROM Lead l WHERE id = :l.id];
		system.assertEquals(gfLead.Visitor_Id__c, l.Visitor_Id__c);
		system.assertEquals(gfLead2.Session_Id__c, l.Session_Id__c);
	}

	@isTest
	static void processNewAccountantLeadDataNoLead() {
		GFLeadTriggerHelper.queue = true;

		Lead l = new Lead();
		l.FirstName = 'Test';
		l.LastName = 'Test';
		l.RecordTypeId = cache.getRecordTypeId('Lead', 'Reseller');
		l.Company = 'Test';
		l.Email = 'test.test.1@gusto.com';
		l.Visitor_Id__c = '11111';
		l.Session_Id__c = '11111';
		insert l;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Accountant';
		insert gfLead;

		l = [SELECT Id, Visitor_Id__c, Session_Id__c FROM Lead l WHERE id = :l.id];
		system.assertEquals('11111', l.Visitor_Id__c);
		system.assertEquals('11111', l.Session_Id__c);

		delete gfLead;
	}

	@isTest
	static void processNewResellerLeadData() {
		GFLeadTriggerHelper.queue = true;

		Lead l = new Lead();
		l.FirstName = 'Test';
		l.LastName = 'Test';
		l.RecordTypeId = cache.getRecordTypeId('Lead', 'Reseller');
		l.Company = 'Test';
		l.Email = 'test.test@gusto.com';
		l.Visitor_Id__c = '11111';
		l.Session_Id__c = '11111';
		insert l;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'test';
		gfLead.Last_Name__c = 'test';
		gfLead.Email__c = 'test.test@gusto.com';
		gfLead.Company_Name__c = 'Test';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Reseller';
		insert gfLead;

		l = [SELECT Id, Visitor_Id__c, Session_Id__c FROM Lead l WHERE id = :l.id];
		system.assertEquals('11111', l.Visitor_Id__c);
		system.assertEquals('11111', l.Session_Id__c);

		delete gfLead;
	}

	@isTest
	static void testLeadStatus() {
		GFLeadTriggerHelper.queue = true;
		List<GF_Lead__c> list_GFLeads = new List<GF_Lead__c>();
		List<String> list_emails = new List<String>();

		GF_Lead__c objGFLead = new GF_Lead__c();
		objGFLead.First_Name__c = 'test';
		objGFLead.Last_Name__c = 'test';
		objGFLead.Email__c = 'test.test.abc@gusto.com';
		objGFLead.Company_Name__c = 'Test';
		objGFLead.Session_Id__c = '12345';
		objGFLead.Visitor_Id__c = '12345';
		objGFLead.Lead_Type__c = 'Accountant';
		objGFLead.Partner_Program_Request_Create_Date__c = system.now();
		objGFLead.Source__c = 'LinkedIn';
		list_GFLeads.add(objGFLead);

		GF_Lead__c objGFLeadRamp = new GF_Lead__c();
		objGFLeadRamp.First_Name__c = 'test';
		objGFLeadRamp.Last_Name__c = 'test';
		objGFLeadRamp.Email__c = 'test.test.abc@gusto.com';
		objGFLeadRamp.Company_Name__c = 'Test';
		objGFLeadRamp.Session_Id__c = '123456';
		objGFLeadRamp.Visitor_Id__c = '123456';
		objGFLeadRamp.Lead_Type__c = 'Accountant';
		objGFLeadRamp.Ramp_Intent__c = true;
		objGFLeadRamp.Source__c = 'LinkedIn';
		list_GFLeads.add(objGFLeadRamp);

		Test.startTest();

		insert list_GFLeads;

		update list_GFLeads;
		for (GF_Lead__c objGfLeads : list_GFLeads) {
			list_emails.add(objGfLeads.Email__c);
		}
		Test.stopTest();

		List<Lead> list_leads = [SELECT Id, MQL_Reason__c, Status FROM Lead WHERE Email IN :list_emails];

		System.assertEquals(LeadUtil.MQL_REASON_IN_APP_JOIN_REQ, list_leads[0].MQL_Reason__c);
	}

	/*** Test if Campaign field on Lead is overriden when the value is Other ***/
	@isTest
	static void testOtherCampaignOverride() {
		// Insert a Lead - Set Campaign as "Other"
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@testcampaign.com', '123456789', 'Other Campaign Lead', false);
		objLead.ZP_Lead_Campaign__c = 'Other';
		insert objLead;

		// Insert GF Lead Set Campaign as not "Other"
		GF_Lead__c objGFLead = TestUtils.createNewGFLead('Company', objLead.Email, 'FName', 'LName', '123456789', false);
		objGFLead.Campaign__c = 'Test Campaign';

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, ZP_Lead_Campaign__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(objGFLead.Campaign__c, objLeadAssert.ZP_Lead_Campaign__c);
	}

	/*** Test if Source field on Lead is overriden when the value is Sourcing Error ***/
	@isTest
	static void testSourcingErrorOverride() {
		// Insert a Lead - Set Source as "Sourcing Error"
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@sourcingerror.com', '123456789', 'Sourcing Error Lead', false);
		objLead.LeadSource = LeadUtil.LEADSOURCE_SRC_ERROR;
		insert objLead;

		LeadTriggerHelper.skipTrigger = true;
		// Insert GF Lead Set Source as not "Sourcing Error"
		GF_Lead__c objGFLead = TestUtils.createNewGFLead('Company', objLead.Email, 'FName', 'LName', '123456789', false);
		objGFLead.Source__c = 'Web';

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, LeadSource FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(objGFLead.Source__c, objLeadAssert.LeadSource);
	}

	/*** Test if Source field on Lead is overriden when the value is Inbound Phone ***/
	@isTest
	static void testInboundPhoneSourceOverride() {
		// Insert a Lead - Set Source as "Inbound Phone"
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@inboundphone.com', '123456789', 'Inbound Phone Lead', false);
		objLead.LeadSource = LeadUtil.LEADCREATION_OFFER_IB_PHONE;
		insert objLead;

		LeadTriggerHelper.skipTrigger = true;
		// Insert GF Lead Set Source as not "Inbound Phone"
		GF_Lead__c objGFLead = TestUtils.createNewGFLead('Company', objLead.Email, 'FName', 'LName', '123456789', false);
		objGFLead.Source__c = 'Web';

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, LeadSource FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(objGFLead.Source__c, objLeadAssert.LeadSource);
	}

	/*** Test if Referral Type field on Lead is overriden when the value is User ***/
	@isTest
	static void testReferralTypeOverride() {
		// Insert a Lead - Set Referral_Type__c as "user"
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@referraloverride.com', '123456789', 'Referral Type Lead', false);
		objLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_US;
		insert objLead;

		// Insert GF Lead Set Source as PartnerReferralUser
		GF_Lead__c objGFLead = TestUtils.createNewGFLead('Company', objLead.Email, 'FName', 'LName', '123456789', false);
		objGFLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_PRU;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Referral_Type__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(LeadUtil.REF_TYPE_USER_ROLE, objLeadAssert.Referral_Type__c);
	}

	/*** Test if Company Contact Phone is updated post Lead Conversion ***/
	@isTest
	static void testCompanyContactPhoneOverride() {
		// Create a Company Lead, Set Phone as Blank and Convert
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@companycontact.com', '', 'Blank Phone Lead', false);
		// ZP Company Id is required before conversion
		objLead.ZP_Company_Id__c = '123456';
		insert objLead;

		LeadConversion.ConversionResult objConversionResult = LeadConversion.convert(new List<Lead>{ objLead });

		Test.startTest();
		GF_Lead__c objGFLead = TestUtils.createNewGFLead('Company', objLead.Email, 'FName', 'LName', '123456789', true);
		Test.stopTest();

		Contact objContactAssert = [SELECT Id, Phone FROM Contact WHERE Email = :objLead.Email];
		System.assertEquals(objGFLead.Phone__c, objContactAssert.Phone);
	}

	/*** Test if Reseller Contact Phone is updated post Lead Conversion ***/
	@isTest
	static void testResellerContactPhoneOverride() {
		// Create a Reseller Lead, Set Phone as Blank and Convert
		Lead objLead = TestUtils.createNewLead(LeadUtil.RESELLER_LEAD_RT_ID, 'FName', 'LName', 'email@resellercontact.com', '', 'Blank Reseller Lead', true);
		LeadConversion.ConversionResult objConversionResult = LeadConversion.convert(new List<Lead>{ objLead });

		Test.startTest();
		GF_Lead__c objGFLead = TestUtils.createNewGFLead('Accountant', objLead.Email, 'FName', 'LName', '123456789', true);
		Test.stopTest();

		Contact objContactAssert = [SELECT Id, Phone FROM Contact WHERE Email = :objLead.Email];
		System.assertEquals(objGFLead.Phone__c, objContactAssert.Phone);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Assert if Unqualified Leads are not promoting to MQL due to GF Lead Insert/Update
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testUnqualifiedLeadsNotPromotingToMQL() {
		LeadTriggerHelper.skipTrigger = true;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('unqualifiedlead@unq.com')
			.setPhone('123456789')
			.setCompany('Unqualified Lead')
			.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		// Update Lead Status to Unqualified
		objLead.Status = LeadUtil.LEAD_STATUS_UNQ;
		objLead.Lead_Status_Detail__c = 'Employee';
		update objLead;

		LeadTriggerHelper.skipTrigger = false;

		Lead objLeadAssert = [SELECT Id, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(LeadUtil.LEAD_STATUS_UNQ, objLeadAssert.Status);

		// Create a GF Lead. Result should be Leads should not be promoted
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail(objLead.Email)
			.setSource('adwords')
			.setPhone('1212121')
			.build();
		insert objGFLead;

		Test.stopTest();

		// Assert Lead Status remains as Unqualified
		objLeadAssert = [SELECT Id, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(LeadUtil.LEAD_STATUS_UNQ, objLeadAssert.Status);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Fraud GF Leads are Not Processed
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testFraudGFLeadsAreNotProcessed() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('fraudemail@uniromax.com')
			.setSource('adwords')
			.setPhone('1212121')
			.build();
		insert objGFLead;

		Test.stopTest();

		// Assert processing state is set to Dead
		GF_Lead__c objGFLeadAssert = [SELECT Id, Processing_State__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objGFLeadAssert.Processing_State__c);

		// Assert no Lead was created
		List<Lead> list_Leads = [SELECT Id FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(0, list_Leads.size());
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if regular non-fraud GF leads are always processed
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testNonFraudGFLeadsAreAlwaysProcessed() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('notfraud@regularmail.com')
			.setSource('adwords')
			.setPhone('1212121')
			.build();
		insert objGFLead;

		Test.stopTest();

		// Assert processing state is set to Processed
		GF_Lead__c objGFLeadAssert = [SELECT Id, Processing_State__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objGFLeadAssert.Processing_State__c);

		// Assert Lead was created
		List<Lead> list_Leads = [SELECT Id FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(1, list_Leads.size());
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test if Potential Fraud gets mapped on insert
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testPotentialFraudOnInsert() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('notfraud@regularmail.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setMDFFlag(true)
			.build();

		insert objGFLead;

		Test.stopTest();

		// Assert processing state is set to Processed
		GF_Lead__c objGFLeadAssert = [SELECT Id, Processing_State__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objGFLeadAssert.Processing_State__c);

		// Assert Lead was created
		List<Lead> list_Leads = [SELECT Id, Potential_Fraud_Lead__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(objGFLead.Potential_Fraud__c, list_Leads[0].Potential_Fraud_Lead__c);
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test if Potential Fraud gets updated on update
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testPotentialFraudOnUpdate() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('notfraud@regularmail.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setMDFFlag(true)
			.build();

		insert objGFLead;

		Test.stopTest();

		objGFLead.Potential_Fraud__c = false;
		update objGFLead;

		// Assert Lead was created
		List<Lead> list_Leads = [SELECT Id, Potential_Fraud_Lead__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(objGFLead.Potential_Fraud__c, list_Leads[0].Potential_Fraud_Lead__c);
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Test for Lead Rating update
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testLeadRatingPopulation() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('leadScoure@mail.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setLeadRating(23)
			.build();

		insert objGFLead;
		Test.stopTest();

		// Assert Lead was created
		List<Lead> list_Leads = [SELECT Id, Lead_Rating__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(objGFLead.Lead_Rating__c, list_Leads[0].Lead_Rating__c);
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Test for Lead Rating update
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testLeadRatingPopulationAccount() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('leadScour2e@mail.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setLeadRating(23)
			.build();

		insert objGFLead;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('3169463710430197')
			.setName('Test ZP Company 1')
			.setCreatedByEmail('leadScour2e@mail.com')
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.build();
		insert objZPCompany;
		Test.stopTest();

		// Assert Lead was created
		List<Lead> list_Leads = [SELECT Id, Lead_Rating__c FROM Lead WHERE Email = :objGFLead.Email__c];
		List<Account> list_Accounts = [SELECT Id, Lead_Rating_Account__c FROM Account WHERE ZP_Company_ID__c = '3169463710430197'];
		System.assertEquals(objGFLead.Lead_Rating__c, list_Leads[0].Lead_Rating__c);
		System.assertEquals(23, list_Accounts[0].Lead_Rating_Account__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Set ZP_Accountant_Lead_ID__c on Lead with ZP_Legacy_Lead_ID__c.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testSetLeadAccLeadId() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testLead01@test.com')
			.setPhone('123456789')
			.setCompany('ABCD.co')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		LeadTriggerHelper.skipTrigger = true;
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName(objLead.FirstName)
			.setLName(objLead.LastName)
			.setCompanyName(objLead.Company)
			.setEmail(objLead.Email)
			.setSource(objLead.LeadSource)
			.setPhone(objLead.Phone)
			.setZPLegacyLeadID('legacyLeadId01')
			.build();
		insert objGFLead;

		Test.stopTest();

		// Assert Lead was created
		Lead objLeadAssert = [SELECT Id, ZP_Accountant_Lead_ID__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertNotEquals(null, objLeadAssert.ZP_Accountant_Lead_ID__c);
		System.assertEquals(objGFLead.ZP_Legacy_Lead_ID__c, objLeadAssert.ZP_Accountant_Lead_ID__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Set Lead_Creation_Offer__c on Lead to Product Registration by Integration User Role.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testSetLeadCreationOfferByIntegrationUserRole() {
		User objAPIHerokuUser = [SELECT Id, UserRoleId FROM User WHERE Email = 'testheroku@gusto.com'];
		GF_Lead__c objGFLead;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testLead01@test.com')
			.setPhone('123456789')
			.setCompany('ABCD.co')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		LeadTriggerHelper.skipTrigger = true;
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();

		System.runAs(objAPIHerokuUser) {
			objGFLead = new TestDataFactory.GFLeadBuilder()
				.setLeadType('Company')
				.setFName(objLead.FirstName)
				.setLName(objLead.LastName)
				.setCompanyName(objLead.Company)
				.setEmail(objLead.Email)
				.setSource(objLead.LeadSource)
				.setPhone(objLead.Phone)
				.build();

			GFLeadTriggerHelper.queue = true;
			insert objGFLead;
			GFLeadTriggerHelper.queue = false;
		}

		Test.stopTest();

		// Assert Lead was created
		Lead objLeadAssert = [SELECT Id, Lead_Creation_Offer__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROD_GEN, objLeadAssert.Lead_Creation_Offer__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Set ZP_Lead_Campaign on Lead is set only when it is blank.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testOverWriteZPLeadCampaign() {
		Test.startTest();

		GFLeadTriggerHelper.queue = true;

		GF_Lead__c objGFLead1 = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test Fname')
			.setLName('test Lname')
			.setCompanyName('GF Lead co.')
			.setEmail('testgflead@gusto.com')
			.setSource(LeadUtil.LEAD_STATUS_AQL)
			.setPhone('123456789')
			.setCampaign('campagnId01')
			.setZPLegacyLeadID('legacyLeadId01')
			.build();

		insert objGFLead1;

		// Assert Lead was created
		Lead objLeadAssert = [SELECT Id, ZP_Lead_Campaign__c FROM Lead WHERE Email = :objGFLead1.Email__c];
		System.assertEquals(objGFLead1.Campaign__c, objLeadAssert.ZP_Lead_Campaign__c);

		GF_Lead__c objGFLead2 = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test Fname')
			.setLName('test Lname')
			.setCompanyName('GF Lead co.')
			.setEmail(objGFLead1.Email__c)
			.setSource(LeadUtil.LEAD_STATUS_AQL)
			.setPhone('123456789')
			.setCampaign('campagnId02')
			.setZPLegacyLeadID('legacyLeadId02')
			.build();

		insert objGFLead2;

		GFLeadTriggerHelper.queue = false;

		Test.stopTest();

		// Assert Lead was created
		objLeadAssert = [SELECT Id, ZP_Lead_Campaign__c FROM Lead WHERE Email = :objGFLead2.Email__c];
		System.assertEquals(objGFLead1.Campaign__c, objLeadAssert.ZP_Lead_Campaign__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Set GF_Lead_Last_Updated_Date_Time__c regardless of RecordType.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void setGFLeadLastUpdatedDateTime() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('testgflead@gusto.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setUpdatedAt(System.now())
			.build();

		insert objGFLead;

		Test.stopTest();

		// Assert Lead was created
		Lead objLeadAssert = [SELECT Id, GF_Lead_Last_Updated_Date_Time__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(objGFLead.Updated_At__c, objLeadAssert.GF_Lead_Last_Updated_Date_Time__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Check if Email__c within character limit.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testEmailTooLong() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('wowardworthy_accountspayabledept@americasbaseballcardsonapprovalservice.sportsontheweb.net')
			.setSource('adwords')
			.setPhone('1212121')
			.setUpdatedAt(System.now())
			.build();

		insert objGFLead;

		Test.stopTest();

		// Test if GF Lead is marked Dead
		GF_Lead__c objGFLeadAssert = [SELECT Id, Message__c, Processing_State__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objGFLeadAssert.Processing_State__c);
		System.assertEquals(GFLeadUtil.ERR_MSG_EMAIL_TOO_LONG, objGFLeadAssert.Message__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Check GF Lead Processing with Invalid Email. Record processing state should be Dead
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testInvalidEmailAddress() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test invalid')
			.setLName('test email address')
			.setCompanyName('test co.')
			.setEmail('maríaguadalupe.guerra@gmail.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setUpdatedAt(System.now())
			.build();

		insert objGFLead;

		Test.stopTest();

		// Test if GF Lead is marked Dead
		GF_Lead__c objGFLeadAssert = [SELECT Id, Message__c, Processing_State__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objGFLeadAssert.Processing_State__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Check if Last_Name__c is trimmed to 40 charecters.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testSubstringLastName() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('I&#39;m a detective astronaught with 23 years college sority professional high class gang military member since 1964 keith Richard')
			.setCompanyName('test co.')
			.setEmail('testgflead@test.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setUpdatedAt(System.now())
			.build();

		insert objGFLead;

		Test.stopTest();

		// Test if GF Lead is trimmed
		GF_Lead__c objGFLeadAssert = [SELECT Id, Last_Name__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assert(objGFLeadAssert.Last_Name__c.length() <= GFLeadUtil.LIMIT_LAST_NAME_CHARACTERS);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Check if Duplicate Records are backlogged after a Config limit times reprocessing.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testBacklogDuplicateRecords() {
		GFLeadTriggerHelper.queue = true;

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Test Fname')
			.setLName('Test Lname')
			.setCompanyName('Apple co.')
			.setEmail('testapple@test.com')
			.setSource(LeadUtil.LEAD_STATUS_AQL)
			.setPhone('9876543210')
			.setZPLegacyLeadID('legacyLeadId01')
			.build();
		insert objGFLead;

		// Assert Lead was created
		Lead objLeadAssert = [SELECT Id, ZP_Accountant_Lead_ID__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertNotEquals(null, objLeadAssert.ZP_Accountant_Lead_ID__c);
		System.assertEquals(objGFLead.ZP_Legacy_Lead_ID__c, objLeadAssert.ZP_Accountant_Lead_ID__c);

		// Change RecordType of Lead.
		objLeadAssert.RecordTypeId = LeadUtil.COMPANY_LEAD_RT_ID;

		LeadTriggerHelper.skipTrigger = true;
		update objLeadAssert;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();

		// Update GF Lead which tries to create a new Lead with same Accountant Lead Id.
		objGFLead.Updated_At__c = System.now();
		update objGFLead;

		Test.stopTest();

		// Test if Duplicate Records are backlogged after a Config limit times of reprocessing.
		GF_Lead__c objGFLeadAssert = [SELECT Id, Message__c, Processing_State__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assertEquals(IntegrationUtils.BACKLOG, objGFLeadAssert.Processing_State__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Check if ReprocessCounter is incremented if duplicates are processed within Config Data Reprocessing Limit.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testIncrementReprocessCounter() {
		GFLeadTriggerHelper.queue = true;

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Test Fname')
			.setLName('Test Lname')
			.setCompanyName('Apple co.')
			.setEmail('testapple@test.com')
			.setSource(LeadUtil.LEAD_STATUS_AQL)
			.setPhone('9876543210')
			.setZPLegacyLeadID('legacyLeadId01')
			.build();
		insert objGFLead;

		// Assert Lead was created
		Lead objLeadAssert = [SELECT Id, ZP_Accountant_Lead_ID__c FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertNotEquals(null, objLeadAssert.ZP_Accountant_Lead_ID__c);
		System.assertEquals(objGFLead.ZP_Legacy_Lead_ID__c, objLeadAssert.ZP_Accountant_Lead_ID__c);

		// Change RecordType of Lead.
		objLeadAssert.RecordTypeId = LeadUtil.COMPANY_LEAD_RT_ID;

		LeadTriggerHelper.skipTrigger = true;
		update objLeadAssert;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();

		// Update Limit from 0 to 1 to check if the Counter field GF Lead is updated.
		Configuration_Settings__c objConfig = Utils.ORG_WIDE_CONFIG_SETTINGS;
		objConfig.GF_Lead_Reprocessing_Limit__c = 1;
		update objConfig;

		// Update GF Lead which tries to create a new Lead with same Accountant Lead Id.
		objGFLead.Updated_At__c = System.now();
		update objGFLead;

		Test.stopTest();

		// Test if Reprocess Counter is updated if Duplicate records are reprocessed within limit.
		GF_Lead__c objGFLeadAssert = [SELECT Id, Message__c, Processing_State__c, Reprocess_Counter__c FROM GF_Lead__c WHERE Id = :objGFLead.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objGFLeadAssert.Processing_State__c);
		System.assertEquals(1, objGFLeadAssert.Reprocess_Counter__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Check if Trigger is skipped.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testSkipTrigger() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Test Fname')
			.setLName('Test Lname')
			.setCompanyName('Apple co.')
			.setEmail('testapple@test.com')
			.setSource(LeadUtil.LEAD_STATUS_AQL)
			.setPhone('9876543210')
			.setZPLegacyLeadID('legacyLeadId01')
			.build();

		GFLeadTriggerHelper.skipTrigger = true;
		insert objGFLead;
		GFLeadTriggerHelper.skipTrigger = false;

		Test.stopTest();
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test exceptions in Handler.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testExceptionsInTriggerHandler() {
		Test.startTest();

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Test Fname')
			.setLName('Test Lname')
			.setCompanyName('Apple co.')
			.setEmail('testapple@test.com')
			.setSource(LeadUtil.LEAD_STATUS_AQL)
			.setPhone('9876543210')
			.setZPLegacyLeadID('legacyLeadId01')
			.build();

		GFLeadTriggerHandler.blnTestException = true;

		insert objGFLead;

		objGFLead.Phone__c = '9876543211';
		update objGFLead;

		GFLeadTriggerHandler.blnTestException = false;

		Test.stopTest();
	}

	@isTest
	static void testTBCFieldUpdateOnLeadPositive() {
		GFLeadTriggerHelper.queue = true;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'testTBC';
		gfLead.Last_Name__c = 'testTBC';
		gfLead.Email__c = 'test.TBC@gusto.com';
		gfLead.Company_Name__c = 'TestTBC';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Source__c = 'Outbound';
		gfLead.No_of_Clients_Bucket__c = '3-9';
		gfLead.No_Of_Clients__c = 39;
		gfLead.No_Clients_Payroll__c = 13;
		insert gfLead;

		Lead l = [SELECT Id, No_of_Clients__c, No_Clients_Payroll__c  FROM Lead WHERE email = 'test.TBC@gusto.com'];
		
		System.assertEquals(gfLead.No_Clients_Payroll__c, l.No_Clients_Payroll__c);
		System.assertEquals(6, l.No_of_Clients__c);
	}
    
    @isTest
	static void testTBCFieldUpdateOnLeadNegative() {
		GFLeadTriggerHelper.queue = true;

		GF_Lead__c gfLead = new GF_Lead__c();
		gfLead.First_Name__c = 'testTBC';
		gfLead.Last_Name__c = 'testTBC';
		gfLead.Email__c = 'test.TBC@gusto.com';
		gfLead.Company_Name__c = 'TestTBC';
		gfLead.Session_Id__c = '12345';
		gfLead.Visitor_Id__c = '12345';
		gfLead.Lead_Type__c = 'Company';
		gfLead.Source__c = 'Outbound';
		gfLead.No_Of_Clients__c = 39;
		gfLead.No_Clients_Payroll__c = 13;
		insert gfLead;

		Lead l = [SELECT Id, No_of_Clients__c, No_Clients_Payroll__c  FROM Lead WHERE email = 'test.TBC@gusto.com'];
		
		System.assertEquals(gfLead.No_Clients_Payroll__c, l.No_Clients_Payroll__c);
		System.assertEquals(gfLead.No_Of_Clients__c, l.No_of_Clients__c);
	}
}