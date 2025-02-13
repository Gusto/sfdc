/**
 *  @author Prashant/Yuvraj
 *  @since 15/10/2020
 *  New Refactored LeadTriggerHelper Test Class
 **/
@isTest
public class LeadTriggerHelperTest {
	@testSetup
	static void setupTestData() {
		List<UserRole> list_roles = [SELECT Id FROM UserRole WHERE Name = 'sales_sdr_partner_xx' LIMIT 1];

		TestDataFactory.UserBuilder objUserBuilder = new TestDataFactory.UserBuilder()
			.setAlias('testo')
			.setUserName('Implementation.Advocate@Advocate.Implementation')
			.setEmailEncoding('UTF-8')
			.setFirstName('Implementation')
			.setLastName('Advocate')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setExemptfromValidationRules(true);

		if (list_roles != null && list_roles.size() > 0) {
			objUserBuilder = objUserBuilder.setUserRoleId(list_roles.get(0).Id).setProfileId(UserInfo.getProfileId()).setEmail('mdruser@testorg.com');
		}

		User objMdrUser = objUserBuilder.build();

		User objcurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objcurrentUser) {
			insert objMdrUser;
		}

		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHandler');
		TaskTriggerHelper.skipTrigger = true;

		//create company account
		Account objComAccount = new TestDataFactory.AccountBuilder().setName('name').setRecordTypeId('Company').setZPCompanyId('1234567890').build();

		insert objComAccount;

		//create reseller account
		Account objReslAccount = new TestDataFactory.AccountBuilder().setName('name').setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setZPFirmId('45678332133').build();
		insert objReslAccount;

		Task objTask = new Task();
		objTask.RecordTypeId = Cache.getRecordTypeId('Task', 'Chat');
		insert objTask;

		//insert company account
		Contact objComContact = new Contact();
		objComContact.LastName = 'Test';
		objComContact.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		objComContact.Email = 'abccompany@test.com';
		objComContact.AccountId = objComAccount.Id;
		insert objComContact;

		//insert reseller account
		Contact objRescontact = new Contact();
		objRescontact.LastName = 'Test';
		objRescontact.RecordTypeId = ContactUtil.RESELLER_CONTACT_RT_ID;
		objRescontact.Email = 'abcreseller@test.com';
		objRescontact.AccountId = objReslAccount.Id;
		insert objRescontact;

		ZPUserTriggerHelper.skipTrigger = true;
		ZPUserRoleTriggerHelper.skipTrigger = true;

		ZP_User__c objZPUser = new ZP_User__c();
		objZPUser.Name = 'Test';
		objZPUser.Email__c = 'test1@test.com';
		objZPUser.Id__c = '11111111';
		objZPUser.External_Key__c = 'ZP11111111';
		objZPUser.Referral_Token__c = '3333333';
		objZPUser.Created_At__c = System.Now();
		objZPUser.Updated_At__c = System.Now();
		insert objZPUser;

		List<ZP_User_Role__c> list_UserRoles = new List<ZP_User_Role__c>();
		ZP_User_Role__c objUserRole = new ZP_User_Role__c();
		objUserRole.User_Id__c = '11111111';
		objUserRole.Id__c = '9343434343434';
		objUserRole.Accounting_Firm_Id__c = '45678332133';
		objUserRole.Created_At__c = System.now();
		objUserRole.Updated_At__c = System.now();
		objUserRole.Type__c = 'Role::Accountant';
		objUserRole.ZP_User__c = objZPUser.Id;
		objUserRole.Collaborator_Type__c = 'External Accountant';
		list_UserRoles.add(objUserRole);

		ZP_User_Role__c objUserRole1 = new ZP_User_Role__c();
		objUserRole1.User_Id__c = '11111111';
		objUserRole1.Id__c = '9343434343499';
		objUserRole1.Company_Id__c = '1234567890';
		objUserRole1.Created_At__c = System.now();
		objUserRole1.Updated_At__c = System.now();
		objUserRole1.Type__c = 'Role::Contractor';
		objUserRole1.ZP_User__c = objZPUser.Id;
		objUserRole1.Collaborator_Type__c = 'Payroll Admin';
		list_UserRoles.add(objUserRole1);
		insert list_UserRoles;

		// Create Lead_Randomize__c Custom Setting
		Lead_Randomize__c objRandomize = new Lead_Randomize__c(Current_Company_Lead_Index__c = 1, Number_of_Company_Leads__c = 2, Number_of_Reseller_Leads__c = 2);
		insert objRandomize;
		ZPUserRoleTriggerHelper.skipTrigger = false;
		ZPUserTriggerHelper.skipTrigger = false;

		TriggerHandler.clearBypass('AccountTriggerHandler');
		TriggerHandler.clearBypass('ContactTriggerHandler');
		TaskTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testDefaultFieldUpdates() {
		//to test next business day
		ZP_Sales_Tax_Jurisdictions__c objSalesTaxInfo = new ZP_Sales_Tax_Jurisdictions__c();
		objSalesTaxInfo.State__c = 'AK';
		objSalesTaxInfo.Effective_From__c = System.today() - 1;
		insert objSalesTaxInfo;

		Test.startTest();
		Lead objLead = createLead('GustoTest', 'gusto@gusto.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.LeadSource = 'G2 crowd';
		objLead.G2_Crowd_Company_SIze__c = '2-10 Employees';
		objLead.Session_Id__c = 'Test Session';
		objLead.System_Of_Origin__c = 'GFS';
		objLead.State = 'Alaska';
		objLead.Visitor_Id__c = 'testvisitorId';
		objLead.Status = 'MQL';
		objLead.LeadSource = 'LinkedIn';
		insert objLead;

		//insert campign
		Campaign objcampaign = new Campaign(Name = 'Test', IsActive = true);
		insert objcampaign;

		//insert Campaign Member
		CampaignMember objCampaignmember = new CampaignMember(LeadId = objLead.Id, Status = 'Responded', CampaignId = objcampaign.Id);
		insert objCampaignmember;
		Test.stopTest();

		objLead = [
			SELECT Id, Visitor_Id_First__c, Lead_Stage_Change_Date__c, Session_ID_First__c, Lead_States__c, Sales_Tax_Applicable__c, Sales_Tax_Info__c, Next_Business_Day__c
			FROM Lead
			WHERE Id = :objLead.Id
		];

		//test business days
		System.assertequals(Utils.getNextBusinessDay(), objLead.Next_Business_Day__c, 'Next Business Day is incorrect.');
		System.assertequals(true, objLead.Sales_Tax_Applicable__c, 'Sales Tax Applicable is incorrect.');
		System.assertequals('AK', objLead.Sales_Tax_Info__c, 'Sales Tax info is incorrect.');
		System.assertequals('AK', objLead.Lead_States__c, 'Lead State is incorrect.');
		System.assertequals('testvisitorId', objLead.Visitor_Id_First__c, 'Visitor Id First is incorrect');
		System.assert(objLead.Lead_Stage_Change_Date__c != null, 'Lead Stage Change Date is null');

		//test session Id
		System.assertequals('Test Session', objLead.Session_ID_First__c, 'Session Id First is incorrect.');
		//test tax
	}

	@isTest
	static void testAQLDateTime() {
		Test.startTest();
		Lead objLead = createLead('GustoTest', 'gusto@gusto.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'AQL');
		objLead.Status = LeadUtil.LEAD_STATUS_AQL;
		objLead.LeadSource = 'LinkedIn';
		insert objLead;
		Test.stopTest();

		objLead = [SELECT Id, AQL_Date_Time__c FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.AQL_Date_Time__c != null, 'AQL Date Time is null.');
	}

	@isTest
	static void testG2CrownEmployee() {
		String strG2CrowdLeadSource = LeadUtil.G2_CROWD_LABEL;

		List<Lead> list_Leads = createListOfLeads(9, 'ggustoG2test', LeadUtil.COMPANY_LEAD_RT_ID);
		list_Leads[0].LeadSource = strG2CrowdLeadSource;
		list_Leads[0].G2_Crowd_Company_SIze__c = 'Myself Only';

		list_Leads[1].LeadSource = strG2CrowdLeadSource;
		list_Leads[1].G2_Crowd_Company_SIze__c = '2-10 Employees';

		list_Leads[2].LeadSource = strG2CrowdLeadSource;
		list_Leads[2].G2_Crowd_Company_SIze__c = '11-50 Employees';

		list_Leads[3].LeadSource = strG2CrowdLeadSource;
		list_Leads[3].G2_Crowd_Company_SIze__c = '51-200 Employees';

		list_Leads[4].LeadSource = strG2CrowdLeadSource;
		list_Leads[4].G2_Crowd_Company_SIze__c = '201-500 Employees';

		list_Leads[5].LeadSource = strG2CrowdLeadSource;
		list_Leads[5].G2_Crowd_Company_SIze__c = '501-1000 Employees';

		list_Leads[6].LeadSource = strG2CrowdLeadSource;
		list_Leads[6].G2_Crowd_Company_SIze__c = '1001-5000 Employees';

		list_Leads[7].LeadSource = strG2CrowdLeadSource;
		list_Leads[7].G2_Crowd_Company_SIze__c = '5001-10,000 Employees';

		list_Leads[8].LeadSource = strG2CrowdLeadSource;
		list_Leads[8].G2_Crowd_Company_SIze__c = '10,001+ Employees';
		Test.startTest();
		insert list_Leads;

		list_Leads = [SELECT Id, NumberOfEmployees FROM Lead WHERE Id = :list_Leads];
		System.assertEquals(1, list_Leads[0].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(2, list_Leads[1].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(11, list_Leads[2].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(51, list_Leads[3].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(201, list_Leads[4].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(501, list_Leads[5].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(1000, list_Leads[6].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(5000, list_Leads[7].NumberOfEmployees, 'Number Of Employees is incorrect.');
		System.assertEquals(5000, list_Leads[8].NumberOfEmployees, 'Number Of Employees is incorrect.');
		Test.stopTest();
	}

	@isTest
	static void testInitialDate() {
		Id compLeadRecordTypeId = LeadUtil.COMPANY_LEAD_RT_ID;
		Lead objLead = createLead('gst0', 'gst0@gst.test.com', compLeadRecordTypeId, 'MQL');
		Lead objLead1 = createLead('gst1', 'gst1@gst.test.com', compLeadRecordTypeId, 'MQL');
		Lead objLead2 = createLead('gst2', 'gst2@gst.test.com', compLeadRecordTypeId, 'MQL');
		objLead2.LeadSource = LeadUtil.LEADSOURCE_ABC;

		Test.startTest();
		insert objLead;
		insert objLead2;
		objLead = [SELECT Id, Lead_Initiated_Timestamp__c FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.Lead_Initiated_Timestamp__c != null, 'Lead Initiated Timestamp is null.');

		objLead2 = [SELECT Id, Lead_Initiated_Timestamp__c FROM Lead WHERE Id = :objLead2.Id];
		System.assert(objLead2.Lead_Initiated_Timestamp__c == null, 'Lead Initiated Timestamp is null.');

		objLead1.Status = LeadUtil.LEAD_STATUS_RAW;
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead1;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		objLead1.Status = LeadUtil.LEAD_STATUS_MQL;
		objLead1.Lead_Initiated_Timestamp__c = null;
		update objLead1;

		objLead1 = [SELECT Id, Lead_Initiated_Timestamp__c FROM Lead WHERE Id = :objLead1.Id];
		System.assert(objLead1.Lead_Initiated_Timestamp__c != null, 'Lead Initiated Timestamp is null.');
		Test.stopTest();
	}

	@isTest
	static void testFakeRecord() {
		Lead objLead = createLead('GustoTest', 'testFakerecord@tenable.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		Test.startTest();
		insert objLead;
		objLead = [SELECT Id, Fake_Record__c, Status, Lead_Status_Detail__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLead.Fake_Record__c, 'Lead not marked as fake.');
		System.assertEquals('Unqualified', objLead.Status, 'Lead status is incorrect - should be Unqualified.');
		System.assertEquals('Test/Junk Record', objLead.Lead_Status_Detail__c, 'Lead Status Detail is incorrect.');
		Test.stopTest();
	}

	@isTest
	static void testDulicateContact() {
		Contact objContact = [SELECT Id, Email FROM Contact WHERE Email = 'abccompany@test.com' LIMIT 1];
		Lead objLead = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Email = 'abccompany@test.com';
		Test.startTest();
		insert objLead;

		objLead = [SELECT Id, DuplicateConversionLead__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLead.DuplicateConversionLead__c, 'Duplicate Conversion Lead is incorrect.');
		Test.stopTest();
	}

	@isTest
	static void testMQLleads() {
		Lead objLead = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Status = LeadUtil.LEAD_STATUS_MQL;
		Test.startTest();
		insert objLead;
		objLead = [SELECT Id, MQL_Date__c, MQL_Flag__c, MQL_DateTime__c FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.MQL_Date__c != null, 'MQL Date is null.');
		System.assert(objLead.MQL_DateTime__c != null, 'MQL Date Time is null.');
		System.assertEquals('Yes', objLead.MQL_Flag__c, 'MQL Flag is incorrect.');
		Test.stopTest();
	}

	@isTest
	static void testNormalizePhone() {
		Lead objLead = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Phone = '7778854945';
		objLead.Alternate_Phone__c = '%$&9887654321';
		objLead.MobilePhone = '9898989979';
		objLead.Secondary_Phone__c = '7776655435';
		Test.startTest();
		insert objLead;

		objLead = [SELECT Id, Normalized_Phone__c, Normalized_Secondary_Phone__c, Normalized_Alternate_Phone__c, Normalized_Mobile_Phone__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals('9887654321', objLead.Normalized_Alternate_Phone__c, 'Normalized Alternate Phone is not correct.');
		System.assertEquals('9898989979', objLead.Normalized_Mobile_Phone__c, 'Normalized Mobile Phone is not correct.');
		System.assertEquals('7778854945', objLead.Normalized_Phone__c, 'Normalized Phone is not correct.');
		System.assertEquals('7776655435', objLead.Normalized_Secondary_Phone__c, 'Normalized Secondary Phone is not correct.');
		Test.stopTest();
	}

	@isTest
	static void testCreationOffer() {
		List<Lead> list_Leads = createListOfLeads(9, 'testLeadoffer', LeadUtil.COMPANY_LEAD_RT_ID);

		list_Leads[0].LeadSource = LeadUtil.LEADSOURCE_LIVE_CHAT;
		list_Leads[1].LeadSource = LeadUtil.LEADCREATION_OFFER_IB_PHONE;
		list_Leads[2].LeadSource = LeadUtil.LEADCREATION_OFFER_ABC;
		list_Leads[3].LeadSource = LeadUtil.LEADCREATION_OFFER_G2;
		list_Leads[4].Submitted_From__c = LeadUtil.LEADCREATION_OFFER_INTR_DEMO;
		list_Leads[5].Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;
		list_Leads[6].Referral_Type__c = LeadUtil.REFERRAL_TYPE_US;
		Test.startTest();
		insert list_Leads;

		list_Leads = [SELECT Id, Lead_Creation_Offer__c FROM Lead WHERE Id = :list_Leads];

		System.assertEquals('Inbound Phone', list_Leads[1].Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');
		System.assertEquals('Added by Client', list_Leads[2].Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');
		System.assertEquals('3rd Party Integration', list_Leads[3].Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');
		System.assertEquals('Interactive Demo', list_Leads[4].Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');
		System.assertEquals('Partner Referral', list_Leads[5].Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');
		System.assertEquals('Customer Referral', list_Leads[6].Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');
		Test.stopTest();
	}

	@isTest
	static void testMQLReasonAppJoinRequest() {
		Lead objLead = createLead('GustoTest', 'gusto@gusto.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Partner_Program_Request_Create_Date__c = System.now() - 1;

		Test.startTest();
		insert objLead;
		objLead = [SELECT Id, MQL_Reason__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals('In-App Join Request', objLead.MQL_Reason__c, 'MQL_Reason__c is not set correctly');
		Test.stopTest();
	}

	@isTest
	static void testMQLReasonSignUp() {
		Lead objLead = createLead('GustoTest', 'gusto@gusto.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Ramp_Intent__c = true;

		Test.startTest();
		insert objLead;

		objLead = [SELECT Id, MQL_Reason__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals('Sign-up program interest', objLead.MQL_Reason__c, 'MQL Reason is incorrect.');
		Test.stopTest();
	}

	@isTest
	static void testEmailDomain() {
		Account objAcc = [SELECT Id, RecordTypeId FROM Account WHERE ZP_Firm_ID__c = '45678332133'];
		Account_Email_Domain__c objAccEmailDom = new Account_Email_Domain__c(Name = 'gst.com', Account__c = objAcc.Id);
		insert objAccEmailDom;

		Test.startTest();
		Lead objLead = createLead('GustoTest', 'gusto1@gst.com', LeadUtil.RESELLER_LEAD_RT_ID, 'MQL');
		insert objLead;
		Test.stopTest();

		objLead = [SELECT Id, Domain_Match__c, ABC_Match_Account__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLead.Domain_Match__c, 'LEad DOmain Match should be set to true.');
		System.assertEquals(objAcc.Id, objLead.ABC_Match_Account__c, 'ABC Match Account is not populated correctly.');
	}

	// need to fix -after the code fix
	@isTest
	static void testSourceMap() {
		//Create test data for marketing source map
		Marketing_Source_Map__c objMrkSrcMap0 = new Marketing_Source_Map__c(Lead_Campaign__c = 'testCampaign');

		//Create list of leads to generate different types of sourcekeys
		List<Lead> list_LeadsToInsert = new List<Lead>();
		Id idCompanyLead = LeadUtil.COMPANY_LEAD_RT_ID;
		String strLeadSourcePR = LeadUtil.LEADSOURCE_PR;

		Lead objLead = createLead('GustoTest1', 'GustoTest1@gst.test.com', idCompanyLead, 'MQL');
		Lead objLead1 = createLead('GustoTest2', 'GustoTest2@gst.test.com', idCompanyLead, 'MQL');
		Lead objLead2 = createLead('GustoTest3', 'GustoTest3@gst.test.com', idCompanyLead, 'MQL');
		Lead objLead3 = createLead('GustoTest4', 'GustoTest4@gst.test.com', idCompanyLead, 'MQL');
		Lead objLead4 = createLead('GustoTest5', 'GustoTest5@gst.test.com', idCompanyLead, 'MQL');
		Lead objLead5 = createLead('GustoTest6', 'GustoTest6@gst.test.com', idCompanyLead, 'MQL');

		//sourcekey - leadsource#Campaign
		objLead.LeadSource = strLeadSourcePR;
		objLead.ZP_Lead_Campaign__c = 'testCampaign';
		list_LeadsToInsert.add(objLead);

		// sourcekey - leadsource#
		objLead1.LeadSource = strLeadSourcePR;
		list_LeadsToInsert.add(objLead1);

		// sourcekey - #Campaign
		objLead2.ZP_Lead_Campaign__c = 'testCampaign';
		list_LeadsToInsert.add(objLead2);

		// sourcekey - PartnerReferral#Campaign
		objLead3.LeadSource = strLeadSourcePR;
		objLead3.ZP_Lead_Campaign__c = 'testCampaign';
		objLead3.Referral_Token__c = '12234567876542';
		list_LeadsToInsert.add(objLead3);

		// sourcekey - PartnerReferral#
		objLead4.LeadSource = strLeadSourcePR;
		objLead4.Referral_Token__c = '99999999998877';
		list_LeadsToInsert.add(objLead4);

		// sourcekey -Referral#Referral
		objLead5.Referral_Token__c = '99999999998877';
		list_LeadsToInsert.add(objLead5);

		Test.startTest();
		insert list_LeadsToInsert;
		Test.stopTest();

		objLead2 = [SELECT Source_Map__c FROM Lead WHERE Id = :objLead2.Id];

		System.assertEquals(objMrkSrcMap0.Id, objLead2.Source_Map__c, 'Source map on a Lead is incorrect.');
	}

	@isTest
	static void testAfterInsertMethods() {
		User objMDRUser = [SELECT Id FROM User WHERE Email = 'mdruser@testorg.com'];

		//Test Lead tracking Detail
		Lead objLead = createLead('gst', 'gusto1@gst.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.ZP_Company_ID__c = '321904890214890124';

		System.runAs(objMDRUser) {
			insert objLead;
		}

		Lead_Related_Tracking__c objLeadTrack = [SELECT Id FROM Lead_Related_Tracking__c WHERE Lead__c = :objLead.Id];
		System.assertNotEquals(null, objLeadTrack, 'Lead Related Tracking was not created.');

		Test.startTest();
		System.runAs(objMDRUser) {
			objLead = [SELECT Id, Status, OwnerId FROM Lead WHERE Id = :objLead.Id];
			objLead.Status = 'MQL';
			objLead.OwnerId = objMDRUser.Id;
			update objLead;

			objLeadTrack = [SELECT Id, MQL_Datetime__c, Time_to_First_Call_by_Owner__c, MDR_Rep_assignment_date__c FROM Lead_Related_Tracking__c WHERE Lead__c = :objLead.Id];
			System.assert(objLeadTrack.Time_to_First_Call_by_Owner__c == null, 'Time To First Call By Owner is incorrect.');
			System.assert(objLeadTrack.MQL_Datetime__c != null, 'MQL Date Time is null.');
			System.assert(objLeadTrack.MDR_Rep_assignment_date__c != null, 'MDR Rep assignment date is null.');
		}
		Test.stopTest();
	}

	//to cover setRepNameSBGenHIOpp
	@isTest
	static void testsetRepNameSBGenHIOpp() {
		Lead objLeadCom = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		List<Lead> list_leadToUpsert = new List<Lead>();
		TriggerHandler.bypass('LeadTriggerHandler');
		list_leadToUpsert.add(objLeadCom);
		upsert list_leadToUpsert;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		objLeadCom.Interested_In_Benefits__c = LeadUtil.LABEL_YES;
		objLeadCom.Uncovered_HI_Opportunity__c = null;

		Test.startTest();
		//update objLeadCom;
		upsert list_leadToUpsert;
		Test.stopTest();

		//assert for company lead
		Lead objCompanyLeadAssert = [SELECT Id, Uncovered_HI_Opportunity__c FROM Lead WHERE Id = :objLeadCom.Id];
		System.assert(objCompanyLeadAssert != null, 'Error during lead creation.');
	}

	@isTest
	static void testResetLeadRecType() {
		Lead objLeadCom = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		Lead objLeadReslr = createLead('GustoTest', 'gusto2@gst.test.com', LeadUtil.RESELLER_LEAD_RT_ID, 'MQL');
		List<Lead> list_leadToUpsert = new List<Lead>();
		TriggerHandler.bypass('LeadTriggerHandler');
		list_leadToUpsert.add(objLeadCom);
		list_leadToUpsert.add(objLeadReslr);
		upsert list_leadToUpsert;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		objLeadCom.Lead_Status_Detail__c = LeadUtil.LEAD_STATUS_DET_ACC_BKR;
		objLeadCom.Interested_In_Benefits__c = LeadUtil.LABEL_YES;
		objLeadCom.Uncovered_HI_Opportunity__c = null;
		objLeadReslr.Lead_Status_Detail__c = LeadUtil.LEAD_STATUS_DET_NOT_ACC;

		Test.startTest();
		//update objLeadCom;
		upsert list_leadToUpsert;
		Test.stopTest();

		//assert for company lead
		Lead objCompanyLeadAssert = [SELECT Id, Status, RecordTypeId FROM Lead WHERE Id = :objLeadCom.Id];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objCompanyLeadAssert.Status, 'Lead Status should be MQL.');
		System.assertEquals(LeadUtil.RESELLER_LEAD_RT_ID, objCompanyLeadAssert.RecordTypeId, 'Lead record type should be Reseller.');

		//assert for resller lead
		Lead objResellerLeadAssert = [SELECT Id, Status, RecordTypeId FROM Lead WHERE Id = :objLeadReslr.Id];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objResellerLeadAssert.Status, 'Lead Status should be MQL.');
		System.assertEquals(LeadUtil.COMPANY_LEAD_RT_ID, objResellerLeadAssert.RecordTypeId, 'Lead record type should be Company.');
	}

	@isTest
	static void testConvertedLeadUpdates() {
		// test Scenario's Cases where lead is converted
		Account objAcc = [SELECT Id FROM Account WHERE ZP_Firm_ID__c = '45678332133'];

		Account objReslAccount = new TestDataFactory.AccountBuilder().setName('name').setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).build();

		Lead objLead = createLead('GustoTest', 'gusto1@ggst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Sold_By__c = objAcc.Id;
		objLead.Visitor_ID__c = '111111111';
		objLead.Session_ID_First__c = 'testsessionId';
		objLead.ZP_Company_ID__c = '9218409214801924021';

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		//Test Related Cases - After Update
		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res');
		objCase.Subject = 'Test';
		objCase.Description = 'Test';
		objCase.Type = 'QLE';
		objCase.SuppliedEmail = objLead.Email;
		objCase.lead__c = objLead.id;
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		database.leadConvert lc = new database.leadConvert();
		lc.setLeadId(objLead.id);
		lc.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		Database.LeadConvertResult lcr = Database.convertLead(lc);
		Test.stopTest();

		objLead = [SELECT Id, Visitor_Id__c, ConvertedAccountId, ConvertedOpportunityId, ConvertedContactId FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.ConvertedAccountId != null, 'Error during lead conversion - Account is not populated.');
		System.assert(objLead.ConvertedOpportunityId != null, 'Error during lead conversion - Opportunity is not populated.');
		System.assert(objLead.ConvertedContactId != null, 'Error during lead conversion - Contact is not populated.');
		//Test Related Cases - After Update
	}
	@isTest
	static void testConvertedResellerLeadUpdates() {
		// test Scenario's Cases where lead is converted
		Account objAcc = [SELECT Id FROM Account WHERE ZP_Firm_ID__c = '45678332133'];
		Account objReslAccount = new TestDataFactory.AccountBuilder().setName('name').setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).build();
		Lead objLead = createLead('GustoTest', 'gusto1@ggst.test.com', LeadUtil.RESELLER_LEAD_RT_ID, 'MQL');
		objLead.Sold_By__c = objAcc.Id;
		objLead.Visitor_ID__c = '111111111';
		objLead.Session_ID_First__c = 'testsessionId';

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		//create task
		Task objTask = new Task();
		objTask.WhoId = objLead.Id;
		objTask.Subject = 'test';
		objTask.RecordTypeId = TaskUtil.TASK_DEMO_RT_ID;

		TaskTriggerHelper.skipTrigger = true;
		insert objTask;
		TaskTriggerHelper.skipTrigger = false;

		objTask = [SELECT RecordTypeId, WhoId, CreatedBy.UserRoleId FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(TaskUtil.TASK_DEMO_RT_ID, objTask.RecordTypeId, 'Task Record Type is incorrect.');
		System.assertEquals(objTask.WhoId, objLead.Id, 'Task Who Id is incorrect.');

		update objLead;
		//Test Related Cases - After Update
		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res');
		objCase.Subject = 'Test';
		objCase.Description = 'Test';
		objCase.Type = 'QLE';
		objCase.SuppliedEmail = objLead.Email;
		objCase.lead__c = objLead.id;
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		database.leadConvert lc = new database.leadConvert();
		lc.setLeadId(objLead.id);
		lc.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		lc.donotcreateopportunity = true;
		Database.LeadConvertResult lcr = Database.convertLead(lc);
		Test.stopTest();

		objLead = [SELECT Id, Visitor_Id__c, ConvertedAccountId, ConvertedOpportunityId, ConvertedContactId FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.ConvertedAccountId != null, 'Error during lead conversion - Account is not populated.');
		System.assert(objLead.ConvertedContactId != null, 'Error during lead conversion - Contact is not populated.');
		//Test Related Cases - After Update
	}

	@isTest
	static void testPartnerReferralFields() {
		Account objComAcc = [SELECT Id, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = '1234567890'];
		Contact objCmpContact = [SELECT Id, ZP_User_Id__c FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];
		objCmpContact.ZP_User_Id__c = '11111111';
		update objCmpContact;
		Lead objexstLead = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.RESELLER_LEAD_RT_ID, 'MQL');
		objexstLead.Referral_Token__c = '3333333';
		objexstLead.ZP_Firm_ID__c = '45678332133';
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objexstLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');
		List<Lead> list_Leads = new List<Lead>();
		Lead objLead1 = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.RESELLER_LEAD_RT_ID, 'MQL');
		objLead1.Referral_Token__c = '3333333';
		objLead1.ZP_Firm_ID__c = '45678332133';

		//insert objLead1;
		Lead objLead = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Referral_Token__c = '3333333';
		objLead.ZP_Company_ID__c = '1234567890';

		list_Leads.add(objLead);
		list_Leads.add(objLead1);
		Test.startTest();
		insert list_Leads;

		objLead = [SELECT Id, Referred_by_Accounting_Firm__c, Referred_by_Lead__c, Referred_by_Contact__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(objComAcc.Id, objLead.Referred_by_Accounting_Firm__c, 'Referred by Accounting Firm is incorrect ona a lead.');
		System.assertEquals(objCmpContact.Id, objLead.Referred_by_Contact__c, 'Referred by Contactis incorrect ona a lead.');

		objLead1 = [SELECT Id, Referred_by_Accounting_Firm__c, Referred_by_Lead__c, Referred_by_Contact__c FROM Lead WHERE Id = :objLead1.Id];
		System.assertEquals(objComAcc.Id, objLead1.Referred_by_Accounting_Firm__c, 'Referred by Accounting Firm is incorrect ona a lead.');
		System.assertEquals(objCmpContact.Id, objLead1.Referred_by_Contact__c, 'Referred by Accounting Firm is incorrect ona a lead.');
		Test.stopTest();
	}

	@isTest
	static void testPartnerReferralFieldsByContEmaill() {
		Contact objCmpContact = [SELECT Id, ZP_User_Id__c FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];
		objCmpContact.Email = 'test1@test.com';
		update objCmpContact;

		List<Lead> list_Leads = new List<Lead>();
		Lead objLead1 = createLead('GustoTest', 'test1@test.com', LeadUtil.RESELLER_LEAD_RT_ID, 'MQL');
		objLead1.Referral_Token__c = '3333333';
		objLead1.ZP_Firm_ID__c = '45678332133';
		list_Leads.add(objLead1);

		Lead objLead = createLead('GustoTest', 'test1@test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Referral_Token__c = '3333333';
		objLead.ZP_Company_ID__c = '1234567890';

		list_Leads.add(objLead);
		Test.startTest();
		insert list_Leads;

		objLead = [SELECT Id, Number_of_Referred_Leads__c, Referred_by_Contact__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(objCmpContact.Id, objLead.Referred_by_Contact__c, 'Referred by Accounting Firm is incorrect ona a lead.');

		objCmpContact = [SELECT Id, Number_of_Referred_Leads__c FROM Contact WHERE Id = :objCmpContact.Id];
		System.assertEquals(2, objCmpContact.Number_of_Referred_Leads__c, 'Number of Referred Leads is incorrect on contact.');

		objLead1 = [SELECT Id, Number_of_Referred_Leads__c, Referred_by_Contact__c FROM Lead WHERE Id = :objLead1.Id];
		System.assertEquals(objCmpContact.Id, objLead1.Referred_by_Contact__c, 'Referred by Contact is incorrect on a lead.');
		Test.stopTest();
	}

	@isTest
	static void testOutreachEngagement() {
		//test outreach engagement record - This method will run only on after update.
		Lead objLead = CreateLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();
		objLead.Current_Sequence_Status__c = 'test';
		objLead.Current_Sequence_Name__c = 'testSequencelead';
		objLead.Current_Sequence_Status__c = 'teststatus';
		objLead.Current_Sequence_Step_Number__c = 3;
		objLead.Current_Sequence_Step_Type__c = 'test';
		objLead.Current_Sequence_User_Name__c = 'TestuserName';
		objLead.ID_of_Currently_Active_Sequence__c = '12';
		update objLead;

		Outreach_Engagement__c objOutreachEngmnt = [SELECT Id FROM Outreach_Engagement__c WHERE Lead__c = :objLead.Id LIMIT 1];
		System.assertNotEquals(null, objOutreachEngmnt, 'Outreach engagement record not created.');

		objLead.Current_Sequence_Step_Number__c = 7;
		objLead.Current_Sequence_Step_Type__c = 'test-updated';
		objLead.Current_Sequence_User_Name__c = 'TestuserName-updated';
		update objLead;
		Test.stopTest();

		List<Outreach_Engagement__c> list_OutreachEngmnt = [SELECT Id, Current_Sequence_Step_Type__c FROM Outreach_Engagement__c WHERE Lead__c = :objLead.Id];
		System.assertEquals(1, list_OutreachEngmnt.size(), 'Outreach Engagement records incorrect.');
		System.assertEquals('test-updated', list_OutreachEngmnt[0].Current_Sequence_Step_Type__c, 'Outreach Engagement current sequence step type is incorrect');
	}

	@isTest
	static void testUpdateLeadSourceDetailAffilateMQL() {
		Lead objLead = createLead('GustoTest', 'gusto@gusto.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Expert_Market_Unique_ID__c = 123098;
		objLead.NumberOfEmployees = 12;

		Test.startTest();
		insert objLead;

		objLead = [SELECT Id, Status, Lead_Source_Detail__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLead.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEAD_SRC_DET_AFFILIATES, objLead.Lead_Source_Detail__c, 'Lead Source Detail is incorrect.');
		Test.stopTest();
	}

	// to cover resetSkipTriggerFlags
	@isTest
	static void testresetSkipTriggerFlags() {
		LeadTriggerHandler.resetSkipTriggerFlags();
		System.assertEquals(false, LeadTriggerHandler.blnSkipBeforeInsert, 'blnSkipBeforeInsert is not reset');
		System.assertEquals(false, LeadTriggerHandler.blnSkipAfterInsert, 'blnSkipAfterInsert is not reset');
		System.assertEquals(false, LeadTriggerHandler.blnSkipBeforeUpdate, 'blnSkipBeforeUpdate is not reset');
		System.assertEquals(false, LeadTriggerHandler.blnSkipAfterUpdate, 'blnSkipAfterUpdate is not reset');
		System.assertEquals(false, LeadTriggerHandler.blnSkipBeforeDelete, 'blnSkipBeforeDelete is not reset');
		System.assertEquals(false, LeadTriggerHandler.blnSkipAfterDelete, 'blnSkipAfterDelete is not reset');
	}

	//to cover updateConvertedRecDataAttr - code coverage in progress
	@isTest
	static void testupdateConvertedRecDataAttr() {
		// test Scenario's Cases where lead is converted
		Test.startTest();
		Account objAcc = [SELECT Id FROM Account WHERE ZP_Firm_ID__c = '45678332133'];
		Account objReslAccount = new TestDataFactory.AccountBuilder().setName('name').setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).build();
		User objUser = [SELECT Id FROM User WHERE UserRole.Name = :LeadUtil.LABEL_MDR_USR_ROLE AND IsActive = TRUE LIMIT 1];
		Lead objLead = createLead('GustoTest', 'gusto1@ggst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');
		objLead.Sold_By__c = objAcc.Id;
		objLead.Visitor_ID__c = '111111111';
		objLead.Session_ID_First__c = 'testsessionId';
		objLead.ZP_Company_ID__c = '48219084092184091284';
		objLead.FirstName = 'NA';

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Database.leadConvert lc = new Database.leadConvert();
		lc.setLeadId(objLead.id);
		lc.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		lc.donotcreateopportunity = true;
		Database.LeadConvertResult lcr = Database.convertLead(lc);

		//Requery lead
		Lead objConvertedLead = [SELECT Id, ZP_Company_Lead_ID__c, OwnerId, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id = :objLead.Id];

		objConvertedLead.ZP_Company_Lead_ID__c = '1231232';
		objConvertedLead.OwnerId = objUser.Id;
		// update first name on the lead - that should be update on the converted contact
		objConvertedLead.FirstName = 'Test';
		update objConvertedLead;
		Test.stopTest();
		System.assertNotEquals(null, objConvertedLead.ConvertedAccountId, 'Lead did not convert correctly');
		System.assertNotEquals(null, objConvertedLead.ConvertedContactId, 'Lead did not convert correctly');

		// Name should updated on converted contact
		Contact objConAssert = [SELECT Id, FirstName FROM Contact WHERE Id = :objConvertedLead.ConvertedContactId];
		System.assertNotEquals(LeadUtil.STRING_NA, objConAssert.FirstName, 'First Name on converted contact is incorrect.');
	}

	/*** Intitilize Lead Records *******/
	public static Lead CreateLead(String strLastName, String strEmail, Id idRecordTypeId, String strStatus) {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(idRecordTypeId)
			.setFirstName('GustoTest-test')
			.setLastName(strLastName)
			.setEmail(strEmail)
			.setPhone('123456789')
			.setCompany('GustoTest')
			.setLeadSource('LinkedIn')
			.setStatus(strStatus)
			.build();
		return objLead;
	}

	/*** Intitilize List of Lead Records *******/
	public static List<Lead> createListOfLeads(Integer intTotalNumberOfLeads, String strLastName, Id strRecordTypeId) {
		List<Lead> list_Leads = new List<Lead>();

		for (Integer i = 0; i < intTotalNumberOfLeads; i++) {
			Lead objLead = createLead(strLastName + i, 'testgusto' + i + '@test.com', strRecordTypeId, 'MQL');
			list_Leads.add(objLead);
		}
		return list_Leads;
	}

	@isTest
	static void testLeadOwnerAssignmentReferredBy() {
		Account objComAccount = [SELECT Id, Ownerid FROM Account LIMIT 1];
		List<Lead> list_lead = new List<Lead>();

		Lead objLead = new Lead();
		objLead.FirstName = 'Test';
		objLead.LastName = 'Test';
		objLead.Email = 'test@gusto11.com';
		objLead.Company = 'Test';
		objLead.Status = LeadUtil.LEAD_STATUS_MQL;
		objLead.Phone = '9878323223';
		objLead.LeadSource = 'Webinar';
		objLead.RecordTypeId = LeadUtil.RESELLER_LEAD_RT_ID;
		objLead.Router_Group__c = 'Test';
		objLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;

		Lead objLeadAccount = new Lead();
		objLeadAccount.FirstName = 'Test';
		objLeadAccount.LastName = 'Test';
		objLeadAccount.Email = 'test12@gusto.com';
		objLeadAccount.Company = 'Test';
		objLeadAccount.Status = LeadUtil.LEAD_STATUS_MQL;
		objLeadAccount.Phone = '9878323224';
		objLeadAccount.LeadSource = 'Webinar';
		objLeadAccount.RecordTypeId = LeadUtil.RESELLER_LEAD_RT_ID;
		objLeadAccount.Router_Group__c = 'Test';
		objLeadAccount.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;
		objLeadAccount.Referred_By__c = objComAccount.id;
		list_lead.add(objLeadAccount);
		list_lead.add(objLead);

		Test.startTest();
		insert list_lead;
		Test.stopTest();
		List<Lead> list_LeadQuery = [SELECT Id, Owner_Role__c, OwnerId FROM Lead WHERE Id IN :list_lead];
		System.assertEquals(objComAccount.OwnerId, list_LeadQuery[0].OwnerId, 'Account Owner is different from Lead Owner.');
	}

	@isTest
	static void testLeadOwnerAssignmentReferredByPP() {
		Account objComAccount = [SELECT Id, OwnerId FROM Account LIMIT 1];
		List<Lead> list_lead = new List<Lead>();

		Lead objLead = new Lead();
		objLead.FirstName = 'Test';
		objLead.LastName = 'Test';
		objLead.Email = 'test@gusto11.com';
		objLead.Company = 'Test';
		objLead.Status = LeadUtil.LEAD_STATUS_MQL;
		objLead.Phone = '9878323223';
		objLead.LeadSource = 'Webinar';
		objLead.RecordTypeId = LeadUtil.RESELLER_LEAD_RT_ID;
		objLead.Router_Group__c = 'Test';
		objLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;

		Lead objLeadAccount = new Lead();
		objLeadAccount.FirstName = 'Test';
		objLeadAccount.LastName = 'Test';
		objLeadAccount.Email = 'test12@gusto.com';
		objLeadAccount.Company = 'Test';
		objLeadAccount.Status = LeadUtil.LEAD_STATUS_MQL;
		objLeadAccount.Phone = '9878323224';
		objLeadAccount.LeadSource = 'Webinar';
		objLeadAccount.RecordTypeId = LeadUtil.RESELLER_LEAD_RT_ID;
		objLeadAccount.Router_Group__c = 'Test';
		objLeadAccount.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;
		objLeadAccount.Referred_By__c = objComAccount.id;
		list_lead.add(objLeadAccount);
		list_lead.add(objLead);
		Test.startTest();
		insert list_lead;
		Test.stopTest();
		List<Lead> list_LeadQuery = [SELECT Id, Owner_Role__c, OwnerId FROM Lead WHERE Id IN :list_lead];
		System.assertEquals(objComAccount.OwnerId, list_LeadQuery[0].OwnerId, 'Account Owner is different from Lead Owner.');
	}

	/*** Test Entry Criteria for Promotion - Lead First Name, Last Name, Phone, Email should not be null***/
	@isTest
	static void testEntryCriteriaForPromotion() {
		// Insert a company lead with blank phone
		Test.startTest();
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@nophone.com', '', 'No Phone', true);
		Test.stopTest();

		// Assert if Lead is not promoted to MQL
		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(true, objLeadAssert.Status != LeadUtil.LEAD_STATUS_MQL, 'Lead Status is incorrect.');
	}

	/*** Test if Lead Source is xero_migration_partner , Lead is promoted to MQL and MQL Reason is Product Registration   ***/
	@isTest
	static void testXeroPartnerPromotesToMQL() {
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@xeropartner.com', '123456789', 'Xero Partner', false);
		objLead.LeadSource = LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER;

		Test.startTest();
		insert objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROD_GEN, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/*** Test if Lead Source is xero_migration_partner and External Practice is Set , Lead is promoted to MQL and MQL Reason is Product Registration   ***/
	@isTest
	static void testXeroPartnerWithExternalPracticePromotesToMQL() {
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@externalxero.com', '123456789', 'Xero External Partner', false);
		objLead.LeadSource = LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER;
		objLead.External_Practice_Id__c = '456789';

		Test.startTest();
		insert objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROD_GEN, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/*** Promote based on Lead Routing Settings Custom metadata ***/
	@isTest
	static void testBenchLeadPromotesToMQL() {
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@bench.com', '123456789', 'Bench Lead', false);
		objLead.LeadSource = 'Bench';

		Test.startTest();
		insert objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROD_GEN, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/*** Test if Lead Source is Inbound Phone, promote to MQL and MQL Reason is Inbound Phone ***/
	@isTest
	static void testInboundPhonePromotesToMQL() {
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@inboundphone.com', '123456789', 'Inbound Phone', false);
		objLead.LeadSource = LeadUtil.LEADCREATION_OFFER_IB_PHONE;

		Test.startTest();
		insert objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_IB_PHONE, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/*** Test if Lead is created by User whose role contains 'sales', Promote to MQL and MQL Reason as Sales Generated ***/
	@isTest
	static void testIfSalesLeadPromotesToMQL() {
		List<User> list_SalesUsers = [SELECT Id FROM User WHERE UserRole.Name = 'sales_sdr_partner_xx' AND IsActive = TRUE];

		if (!list_SalesUsers.isEmpty()) {
			System.runAs(list_SalesUsers.get(0)) {
				Test.startTest();
				Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@sales.com', '123456789', 'Sales Lead', true);
				Test.stopTest();

				Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];

				System.assertNotEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
				System.assertNotEquals(LeadUtil.LEADCREATION_OFFER_SALES_GNR, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
			}
		}
	}

	/*** Test if Lead Source is G2 Crowd, Software Suggest, Softwaresuggest then Promote to MQL and set MQL reason as 3rd Party Integration ***/
	@isTest
	static void testG2CrowdLeadPromotesToMQL() {
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@g2crowd.com', '123456789', 'G2 Crowd', false);
		objLead.LeadSource = 'G2 Crowd';

		Test.startTest();
		insert objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_3RD_PARTY, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/*** Test if Referral Type is updated from Lead to Account and Opportunity (Post Conversion)  ***/
	@isTest
	static void testReferralTypeUpdate() {
		TriggerHandler.bypass('LeadTriggerHandler');
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@accountreferraltype.com', '123456789', 'Referral Lead', false);
		// ZP Company Id is required before conversion
		objLead.ZP_Company_Id__c = '123456';
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');
		// Convert Lead
		TriggerHandler.bypass('AccountTriggerHandler');
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Test.startTest();
		Lead objLeadUpdate = [SELECT Id, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];
		objLeadUpdate.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;
		update objLeadUpdate;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Referral_Type__c FROM Account WHERE Id = :objLeadUpdate.ConvertedAccountId];
		System.assertEquals(LeadUtil.REFERRAL_TYPE_UR, objAccountAssert.Referral_Type__c, 'Referral Type is incorrect.');

		Opportunity objOpptyAssert = [SELECT Id, Referral_Type__c FROM Opportunity WHERE Id = :objLeadUpdate.ConvertedOpportunityId];
		System.assertEquals(LeadUtil.REFERRAL_TYPE_UR, objOpptyAssert.Referral_Type__c, 'Referral Type is incorrect.');
	}

	/*** Test if Referral By is updated from Lead to Account and Opportunity (Post Conversion) ***/
	@isTest
	static void testReferredByUpdate() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objResellerAccount = TestUtils.createAccount(AccountUtil.RESELLER_ACCOUNT_RT_ID, 'Reseller Account', true);
		TriggerHandler.clearBypass('AccountTriggerHandler');

		TriggerHandler.bypass('LeadTriggerHandler');
		Lead objLeadInsert = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@accountreferraltype.com', '123456789', 'Referral Lead', false);
		// ZP Company Id is required before conversion
		objLeadInsert.ZP_Company_Id__c = '123456';
		insert objLeadInsert;

		Test.startTest();
		Database.LeadConvert lc = new Database.LeadConvert();
		lc.setLeadId(objLeadInsert.Id);
		lc.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		Database.LeadConvertResult lcr = Database.convertLead(lc);
		Test.stopTest();

		Lead objConveretedLead = [SELECT Id, Visitor_Id__c, ConvertedAccountId, ConvertedOpportunityId, ConvertedContactId, Referred_By__c FROM Lead WHERE Id = :objLeadInsert.Id];

		TriggerHandler.clearBypass('LeadTriggerHandler');
		objConveretedLead.Referred_By__c = objResellerAccount.Id;
		update objConveretedLead;

		Account objAccountAssert = [SELECT Id, Referred_By__c FROM Account WHERE Id = :objConveretedLead.ConvertedAccountId];
		System.assertEquals(objResellerAccount.Id, objAccountAssert.Referred_By__c, 'Referred By is incorrect.');

		Opportunity objOpptyAssert = [SELECT Id, Referred_By__c FROM Opportunity WHERE Id = :objConveretedLead.ConvertedOpportunityId];
		System.assertEquals(objResellerAccount.Id, objOpptyAssert.Referred_By__c, 'Referred By is incorrect.');
	}

	/*** Test to Update MQL to Future Opportunity  ***/
	@isTest
	static void testReUpdateInboundPhonePromotesToMQL() {
		Lead objLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'email@inboundphone.com', '123456789', 'Inbound Phone', false);
		objLead.LeadSource = LeadUtil.LEADCREATION_OFFER_IB_PHONE;

		Test.startTest();
		insert objLead;
		objLead.Status = LeadUtil.LEAD_STATUS_FUT_OPP;
		objLead.Lead_Status_Detail__c = LeadUtil.LABEL_LEAD_CAMP_OTHER;
		objLead.Status_Notes__c = LeadUtil.LABEL_LEAD_CAMP_OTHER;
		update objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objLead.Email];

		System.assertEquals(LeadUtil.LEAD_STATUS_FUT_OPP, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_IB_PHONE, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @author Praveen Sethu
	 * Test if Referral Type is set Company and Reseller Leads
	 * @param   NA
	 * @return NA
	 **/
	@isTest
	static void testSetReferralType() {
		TriggerHandler.bypass('LeadTriggerHandler');
		List<Lead> list_LeadsToInsert = new List<Lead>();

		Lead objCompanyLead = TestUtils.createNewLead(LeadUtil.COMPANY_LEAD_RT_ID, 'FName', 'LName', 'companylead@one.com', '123456789', 'Company 1', false);
		objCompanyLead.ZP_Company_Lead_ID__c = '100';
		objCompanyLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_PRU;

		list_LeadsToInsert.add(objCompanyLead);

		Lead objResellerLead = TestUtils.createNewLead(LeadUtil.RESELLER_LEAD_RT_ID, 'FName', 'LName', 'resellerlead@two.com', '123456789', 'Reseller 2', false);
		objResellerLead.ZP_Accountant_Lead_ID__c = '900';
		objResellerLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;

		list_LeadsToInsert.add(objResellerLead);
		insert list_LeadsToInsert;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();
		update list_LeadsToInsert;
		Test.stopTest();

		Lead objCompanyLeadAssert = [SELECT Id, Referral_Type__c, Lead_Creation_Offer__c FROM Lead WHERE Id = :objCompanyLead.Id];
		System.assertEquals(LeadUtil.REF_TYPE_USER_ROLE, objCompanyLeadAssert.Referral_Type__c, 'Referral Type is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PR, objCompanyLeadAssert.Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');

		Lead objResellerLeadAssert = [SELECT Id, Referral_Type__c, Lead_Creation_Offer__c FROM Lead WHERE Id = :objResellerLead.Id];
		System.assertEquals(LeadUtil.REF_TYPE_PARTNER_REF_USER, objResellerLeadAssert.Referral_Type__c, 'Referral Type is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_P2P, objResellerLeadAssert.Lead_Creation_Offer__c, 'Lead Creation Offer is incorrect.');
	}

	/**
	 * @author Praveen Sethu
	 * Test if Normalized Email Domain is extracted from Lead Email
	 **/
	@isTest
	static void testEmailDomainNormalization() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@normalizeinsert.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.build();
		insert objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Normalized_Email_Domain__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals('normalizeinsert.com', objLeadAssert.Normalized_Email_Domain__c, 'Normalized Email Domain is incorrect.');

		objLead.Email = 'reseller@normalizeupdate.com';
		update objLead;

		objLeadAssert = [SELECT Id, Normalized_Email_Domain__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals('normalizeupdate.com', objLeadAssert.Normalized_Email_Domain__c, 'Normalized Email Domain is incorrect.');
	}

	/**
	 * @author Veeresh Kumar
	 * Asserts if Lead's LeadSource is reset upon it's unnecessary update.
	 **/
	@isTest
	static void testResetLeadSource() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@xeropartner.com')
			.setPhone('123456789')
			.setCompany('Xero Partner')
			.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, LeadSource FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER, objLeadInsertAssert.LeadSource, 'Lead Source is incorrect.');
	}

	/**
	 * @author Debasmita Rawooth
	 * Test Potential Fraud field update
	 **/
	@isTest
	static void testPotentialFraudHistoryFieldUpdate() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setCompany('CompanyAcc')
			.setEmail('company@test.com')
			.setPhone('123456789')
			.setCompany('Company Lead')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setPotentialFraud(true)
			.build();
		insert objLead;

		Lead objLeadAssert = [SELECT Id, Potential_Fraud_Lead__c, Potential_Fraud_Lead_History__c FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(true, objLeadAssert.Potential_Fraud_Lead_History__c, 'Potential Fraud Lead History should be set to true.');
		User objMDRUser = [SELECT Id FROM User WHERE Email = 'mdruser@testorg.com'];
		System.runAs(objMDRUser) {
			objLead.Potential_Fraud_Lead__c = false;
			update objLead;
		}
		Test.stopTest();

		objLeadAssert = [SELECT Id, Potential_Fraud_Lead__c, Potential_Fraud_Lead_History__c FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(true, objLeadAssert.Potential_Fraud_Lead_History__c, 'Potential Fraud Lead History should be set to true.');
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Asserts Lead Rating Sync to the converted account
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testSetAccountLeadRating() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setCompany('CompanyAcc')
			.setEmail('company@rampintent.com')
			.setPhone('123456789')
			.setCompany('Company Lead')
			.setLeadSource('In-app')
			.setLeadRating(29)
			.build();
		objLead.ZP_Company_ID__c = '12313133';

		LeadTriggerHelper.skipTrigger = true;
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		//convert lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });
		//re query lead
		objLead = [SELECT Id, ConvertedAccountId, Lead_Rating__c FROM Lead WHERE Id = :objLead.Id];
		//query converted account
		Account objAccount = [SELECT Id, Lead_Rating_Account__c FROM Account WHERE Id = :objLead.ConvertedAccountId];
		System.assertEquals(29, objAccount.Lead_Rating_Account__c, 'Lead Rating Account is incorrect.');

		Test.startTest();
		objLead.Lead_Rating__c = 120;
		update objLead;
		Test.stopTest();

		//re - query converted account
		objAccount = [SELECT Id, Lead_Rating_Account__c FROM Account WHERE Id = :objLead.ConvertedAccountId];
		System.assertEquals(120, objAccount.Lead_Rating_Account__c, 'Lead Rating Account is incorrect.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Asserts if Potential_Fraud_Lead_History__c gets updated on Lead
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testPotentialFraudHistoryUpdateonLead1() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@fraudtest.com')
			.setPhone('123456789')
			.setCompany('Fraud Test')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setPotentialFraud(true)
			.build();
		insert objLead;
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, Potential_Fraud_Lead__c, Potential_Fraud_Lead_History__c FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(true, objLeadInsertAssert.Potential_Fraud_Lead_History__c, 'Potential Fraud Lead History is incorrect.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Asserts that Potential_Fraud_Lead_History__c does not get updated back to false on update of Potential_Fraud_Lead__c Lead
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testPotentialFraudHistoryUpdateonLead2() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@fraudtest2.com')
			.setPhone('123456789')
			.setCompany('Fraud Test')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setPotentialFraud(true)
			.build();
		insert objLead;
		User objMDRUser = [SELECT Id FROM User WHERE Email = 'mdruser@testorg.com'];
		System.runAs(objMDRUser) {
			objLead.Potential_Fraud_Lead__c = false;
			update objLead;
		}
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, Potential_Fraud_Lead__c, Potential_Fraud_Lead_History__c FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(true, objLeadInsertAssert.Potential_Fraud_Lead_History__c, 'Potential Fraud Lead History is incorrect.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Asserts valid update of Potential_Fraud_Account__c on Account
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testFraudHistoryUpdateOnAccountValid() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test FST')
			.setLName('test LST')
			.setCompanyName('test co.')
			.setEmail('leadfraud1@test.com')
			.setSource('adwords')
			.setPhone('1212121')
			.setMDFFlag(false)
			.build();
		insert objGFLead;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('1111111111')
			.setName('Test ZP Company 2')
			.setPartnerProgramCompanyDataId('1724836129431')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedByEmail('leadfraud1@test.com')
			.build();
		insert objZPCompany;

		Test.startTest();
		objGFLead.Potential_Fraud__c = true;
		update objGFLead;
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, Potential_Fraud_Lead__c, Potential_Fraud_Lead_History__c, ConvertedAccountId FROM Lead WHERE Email = :objGFLead.Email__c];
		Account objAccountAssert = [SELECT Id, Potential_Fraud_Account__c, Potential_Fraud_History__c FROM Account WHERE Id = :objLeadInsertAssert.ConvertedAccountId];

		System.assertEquals(true, objLeadInsertAssert.Potential_Fraud_Lead__c, 'Potential Fraud Lead is incorrect.');
		System.assertEquals(true, objLeadInsertAssert.Potential_Fraud_Lead_History__c, 'Potential Fraud Lead History is incorrect.');
		System.assertEquals(true, objAccountAssert.Potential_Fraud_Account__c, 'Potential Fraud Account is incorrect.');
	}

	/**
	 * @author Veeresh Kumar
	 * Asserts if Lead's set LeadSource strictly based on ReferralType.
	 **/
	@isTest
	static void testSetLeadSourceBasedOnReferralTypeOnInsert() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@referraltype.com')
			.setPhone('123456789')
			.setCompany('Referral Type Lead')
			.setReferralType(LeadUtil.REFERRAL_TYPE_US)
			.setLeadSource('In-app')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		Test.startTest();
		insert objLead;
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, LeadSource FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(LeadUtil.LEADSOURCE_CR, objLeadInsertAssert.LeadSource, 'Lead Source is incorrect.');
	}

	/**
	 * @author Veeresh Kumar
	 * Asserts if Lead's set LeadSource strictly based on ReferralType.
	 **/
	@isTest
	static void testSetLeadSourceBasedOnReferralTypeOnUpdate() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@referraltype.com')
			.setPhone('123456789')
			.setCompany('Referral Type Lead')
			.setLeadSource('In-app')
			.setReferralType(LeadUtil.REFERRAL_TYPE_US)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		Test.startTest();
		insert objLead;
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, LeadSource FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(LeadUtil.LEADSOURCE_CR, objLeadInsertAssert.LeadSource, 'Lead Source is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Company Lead is promoted to MQL if GF Lead Submitted From is interactive Demo and MQL Reason is Interactive Demo
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testInteractiveDemoPromotesTOMQL() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Company Demo')
			.setEmail('email@interactive.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('786746567567')
			.build();
		objGFLead.Submitted_From__c = LeadUtil.LEADCREATION_OFFER_INTR_DEMO;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_INTR_DEMO, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Referral Type is Blank, Lead is promoted to MQL and MQL Reason is Product Registration
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testWithoutReferralTypePromotesToMQL() {
		Test.startTest();
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Company Demo')
			.setEmail('email@noreferral.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('786746567567')
			.build();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROD_GEN, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Referral Type is User, Lead is promoted to MQL and MQL Reason is Customer Referral
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testReferralTypeUserPromotesToMQL() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Company Demo')
			.setEmail('email@userreferral.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('786746567567')
			.build();
		objGFLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_US;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_CR, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if GF Lead Ramp Intent is True, Promote to MQL
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testRampIntentPromotesToMQL() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Acc Firm Demo')
			.setEmail('email@rampintent.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('87897897')
			.build();
		objGFLead.Ramp_Intent__c = true;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status FROM Lead WHERE Email = :objGFLead.Email__c];
		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if GF Lead Partner Program Interest Date is not null, Promote to MQL and set MQL reason as In-App Join Request
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testIfPartnerProgramInterestPromtesToMQL() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Acc Firm Demo')
			.setEmail('email@rampintent.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('87897897')
			.build();
		objGFLead.Partner_Program_Request_Create_Date__c = System.now();

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.MQL_REASON_IN_APP_JOIN_REQ, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if GF Lead Ramp Intent is True and Referral Type is set, Referral should take priority over anything else
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testReferralPriorityOverRampIntent() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Acc Firm Demo')
			.setEmail('email@rampintent.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('87897897')
			.build();
		objGFLead.Ramp_Intent__c = true;
		objGFLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PR, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if GF Lead Partner Program Interest Date is not null and Referral Type is set, Referral should take priority over anything else
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testReferralPriorityOverPartnerProgramInterest() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Acc Firm Demo')
			.setEmail('email@rampintent.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('87897897')
			.build();
		objGFLead.Partner_Program_Request_Create_Date__c = System.now();
		objGFLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PR, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Accountant GF Lead is created, the reseller lead must be promoted
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testAccountantLeadPromotion() {
		Test.startTest();
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Accountant')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Acc Firm Demo')
			.setEmail('email@newgflead.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('87897897')
			.build();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROD_GEN, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Referral Type is UserRole, Lead is promoted to MQL and MQL Reason is Partner Referral
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testReferralTypeUserRolePromotesToMQL() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Company Demo')
			.setEmail('email@userrolereferral.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('786746567567')
			.build();
		objGFLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_UR;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PR, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Referral Type is partnerreferraluser, Lead is promoted to MQL and MQL Reason is P2P Referral
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testReferralTypePartnerReferralUserPromotesToMQL() {
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('Fname')
			.setLName('Lname')
			.setCompanyName('Company Demo')
			.setEmail('email@partnerreferraluser.com')
			.setSource('leadsource')
			.setPhone('1212121')
			.setZPLegacyLeadID('786746567567')
			.build();
		objGFLead.Referral_Type__c = LeadUtil.REFERRAL_TYPE_PRU;

		Test.startTest();
		insert objGFLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Email = :objGFLead.Email__c];

		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadAssert.Status, 'Lead Status is incorrect.');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_P2P, objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect.');
	}

	/**
	 * @author      Veeresh Kumar
	 * @description Test set Standard Fields on Lead with 3rd party fields.
	 **/
	@isTest
	static void testSetStandardFieldsFrom3rdParty() {
		Test.startTest();

		List<Lead> list_LeadsToInsert = new List<Lead>();
		List<Lead> list_LeadsToUpdate = new List<Lead>();

		Lead objResellerLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('FName 1')
			.setLastName('LName 1')
			.setCompany('CompanyAcc')
			.setEmail('company1@rampintent.com')
			.setPhone('123456789')
			.setLeadSource('In-app')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setCity('Wixom')
			.setState('Michigan')
			.setCountry('United States')
			.setPostalCode('48393')
			.setX3rdPartyCity('New York')
			.setX3rdPartyState('New York')
			.setX3rdPartyPostal('10001')
			.build();
		list_LeadsToInsert.add(objResellerLead1);

		Lead objResellerLead2 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('FName 2')
			.setLastName('LName 2')
			.setEmail('company2@rampintent.com')
			.setPhone('123456798')
			.setCompany('Reseller Lead')
			.setLeadSource('In-app')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setX3rdPartyCity('Wixom')
			.setX3rdPartyState('Michigan')
			.build();
		list_LeadsToInsert.add(objResellerLead2);

		insert list_LeadsToInsert;

		Lead objLeadInsertAssert1 = [SELECT Id, City, State, PostalCode FROM Lead WHERE Id = :objResellerLead1.Id];
		System.assertNotEquals(objResellerLead1.X3rd_Party_City__c, objLeadInsertAssert1.City, 'City is incorrect.');
		System.assertNotEquals(objResellerLead1.X3rd_Party_State__c, objLeadInsertAssert1.State, 'State is incorrect.');
		System.assertNotEquals(objResellerLead1.X3rd_Party_Postal__c, objLeadInsertAssert1.PostalCode, 'Postal Code is incorrect.');

		objResellerLead1.X3rd_Party_Postal__c = '10002';
		list_LeadsToUpdate.add(objResellerLead1);

		objResellerLead2.Country = 'United States';
		objResellerLead2.X3rd_Party_Postal__c = '48393';

		objResellerLead2.X3rd_Party_Annual_Revenue__c = 20000;
		objResellerLead2.X3rd_Party_Num_Employees__c = 20;
		objResellerLead2.Data_Sourcing_Industry__c = 'Accounting';

		list_LeadsToUpdate.add(objResellerLead2);

		update list_LeadsToUpdate;

		Test.stopTest();

		Lead objLeadUpdateAssert1 = [SELECT Id, City, State, PostalCode FROM Lead WHERE Id = :objResellerLead1.Id];
		System.assertNotEquals(objResellerLead1.X3rd_Party_City__c, objLeadUpdateAssert1.City, 'City is incorrect.');
		System.assertNotEquals(objResellerLead1.X3rd_Party_State__c, objLeadUpdateAssert1.State, 'State is incorrect.');
		System.assertNotEquals(objResellerLead1.X3rd_Party_Postal__c, objLeadUpdateAssert1.PostalCode, 'Postal Code is incorrect.');

		Lead objLeadUpdateAssert2 = [SELECT Id, City, State, PostalCode, AnnualRevenue, NumberOfEmployees, Industry FROM Lead WHERE Id = :objResellerLead2.Id];
		System.assertEquals(objResellerLead2.X3rd_Party_City__c, objLeadUpdateAssert2.City, 'City is incorrect.');
		System.assertEquals(objResellerLead2.X3rd_Party_State__c, objLeadUpdateAssert2.State, 'State is incorrect.');
		System.assertEquals(objResellerLead2.X3rd_Party_Postal__c, objLeadUpdateAssert2.PostalCode, 'Postal Code is incorrect.');

		System.assertEquals(objResellerLead2.X3rd_Party_Annual_Revenue__c, objLeadUpdateAssert2.AnnualRevenue, 'Annual Revenue is incorrect.');
		System.assertEquals(objResellerLead2.X3rd_Party_Num_Employees__c, objLeadUpdateAssert2.NumberOfEmployees, 'Number of Employees is incorrect.');
		System.assertEquals(objResellerLead2.Data_Sourcing_Industry__c, objLeadUpdateAssert2.Industry, 'Industry is incorrect.');
	}

	/**
	 * @description Test if Recent fields (Source, Campaign, Content are set on Campaign Member from Lead)
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testRecentAttributionOnLead() {
		// Creating Company Lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('campaignmember@recentattribution.com')
			.setPhone('123456789')
			.setCompany('Company Lead 1')
			.setStatus(LeadUtil.LEAD_STATUS_SAL)
			.setLeadSource('LinkedIn')
			.build();

		LeadTriggerHelper.skipTrigger = true;
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Recent Attribution Lead').setIsActive(true).setType(LeadUtil.CAMPAIGN_TYPE_WEBINAR).build();
		CampaignTriggerHelper.blnSkipTrigger = true;
		insert objCampaign;
		CampaignTriggerHelper.blnSkipTrigger = false;

		CampaignMember objMember = new TestDataFactory.CampaignMemberBuilder().setLeadId(objLead.Id).setStatus('Responded').setCampaignId(objCampaign.Id).build();
		CampaignMemberTriggerHelper.skipTrigger = true;
		insert objMember;
		CampaignMemberTriggerHelper.skipTrigger = false;

		Test.startTest();
		Lead objLeadToUpdate = new Lead(Id = objLead.Id, Recent_Source__c = 'Recent Source', Recent_Campaign__c = 'Recent Campaign', Recent_Content__c = 'Recent Content');
		update objLeadToUpdate;
		Test.stopTest();

		CampaignMember objMemberAssert = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM CampaignMember WHERE Id = :objMember.Id];
		System.assertEquals(objMemberAssert.Recent_Source__c, objLeadToUpdate.Recent_Source__c, 'Recent Source is incorrect.');
		System.assertEquals(objMemberAssert.Recent_Campaign__c, objLeadToUpdate.Recent_Campaign__c, 'Recent Campaign is incorrect.');
		System.assertEquals(objMemberAssert.Recent_Content__c, objLeadToUpdate.Recent_Content__c, 'Recent Content is incorrect.');
	}
	
	/**
	 * @author      Prity Kumari
	 * @description Test  Routing for Lead created by Sales.
	 **/
	@isTest
	static void testRoutingWithSalesCreatedLead() {
		User objSalesUser = [SELECT Id FROM User WHERE UserRole.Name = 'sales_partner_ae_xx' AND IsActive = TRUE LIMIT 1];
		Test.startTest();
		System.runAs(objSalesUser) {
			Lead objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('FName')
				.setLastName('LName')
				.setEmail('prity@gusto.com')
				.setPhone('123456789')
				.setCompany('Xero Partner')
				.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
				.setStatus(LeadUtil.LEAD_STATUS_AQL)
				.build();
			insert objLead;
			// assert if lead route count is updated
			Lead objLeadAssert = [SELECT Id, Lead_Route_Count__c FROM Lead WHERE Id = :objLead.Id];
			System.assertEquals(0, objLeadAssert.Lead_Route_Count__c, 'Lead Route Count is incorrect.');
			objLead.Status = 'mql';
			update objLead;
			objLeadAssert = [SELECT Id, Lead_Route_Count__c FROM Lead WHERE Id = :objLead.Id];
			System.assertEquals(0, objLeadAssert.Lead_Route_Count__c, 'Lead Route Count is incorrect.');
		}
		Test.stopTest();
	}

	/**
	 * @author     Prity Kumari
	 * @description Test  Routing for Lead with Route to Market as null.
	 **/
	@isTest
	static void testRoutingWithRouteToMarket() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('prity@gusto.com')
			.setPhone('123456789')
			.setCompany('Xero Partner')
			.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;
		objLead = [SELECT Id, Lead_Route_Count__c FROM Lead WHERE Id = :objLead.Id];
		Test.startTest();
		objLead.Route_to_Market__c = 'MMPR';
		objLead.Status = 'MQL';
		update objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Lead_Route_Count__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(objLead.Lead_Route_Count__c, objLeadAssert.Lead_Route_Count__c, 'RTM populated leads should not be routing');
	}

	/**
	 * @author      Rushi Ravisaheb
	 * @description Test for SAL_Date__c field values [BMM-493]
	 **/
	@isTest
	static void testSALDates() {
		Lead objLead = createLead('GustoTest', 'gusto1@gst.test.com', LeadUtil.COMPANY_LEAD_RT_ID, 'MQL');

		Test.startTest();
		insert objLead;

		objLead = [SELECT Id, SAL_Date__c, Status FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.SAL_Date__c == null, 'SAL Date should be null.');

		objLead.Status = LeadUtil.LEAD_STATUS_SAL;
		update objLead;

		objLead = [SELECT Id, SAL_Date__c, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(Date.Today(), objLead.SAL_Date__c, 'SAL Date is incorrect.');
		Test.stopTest();
	}

	/**
	 * @author     Prity Kumari
	 * @description Test  unique email address change when recordtype changes
	 **/
	@isTest
	static void testUniqueEmailAddress() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('prity@gusto.com')
			.setPhone('123456789')
			.setCompany('Xero Partner')
			.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		System.AssertEquals('company-' + objLead.Email, [SELECT Unique_Email_Address__c FROM Lead WHERE Id = :objLead.Id].Unique_Email_Address__c, 'Unique email id is incorrect.');

		Test.startTest();
		objLead.RecordtypeId = LeadUtil.RESELLER_LEAD_RT_ID;
		update objLead;
		Test.stopTest();

		System.AssertEquals('reseller-' + objLead.Email, [SELECT Unique_Email_Address__c FROM Lead WHERE Id = :objLead.Id].Unique_Email_Address__c, 'Unique email id is incorrect.');
	}
	/**
	 * @author     Prity Kumari
	 * @description Test  Routing for Lead with Lead Owner as Sales.
	 **/
	@isTest
	static void testRoutingWithSalesUser() {
		User objMDRUser = [SELECT Id, UserRole.Name FROM User WHERE Email = 'mdruser@testorg.com'];

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('prity@gusto.com')
			.setPhone('123456789')
			.setCompany('Xero Partner')
			.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setOwnerId(objMDRUser.Id)
			.build();
		Leadtriggerhelper.skipTrigger = true;
		insert objLead;
		Leadtriggerhelper.skipTrigger = true;
		objLead = [SELECT Id, Lead_Route_Count__c, Status, Owner.UserRole.Name FROM lead WHERE email = 'prity@gusto.com'];
		Decimal decRouteCount = objLead.Lead_Route_Count__c;
		System.AssertEquals(objMDRUser.UserRole.Name, objLead.Owner.UserRole.Name, 'Lead Owner is not set correctly');

		Test.startTest();
		objLead.Status = 'MQL';
		update objLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Lead_Route_Count__c, Status, Owner.UserRole.Name FROM lead WHERE email = 'prity@gusto.com'];
		System.AssertEquals(objMDRUser.UserRole.Name, objLeadAssert.Owner.UserRole.Name, 'Lead Owner is not set correctly');
		System.AssertEquals(decRouteCount, objLeadAssert.Lead_Route_Count__c, 'Lead Route Count should not increase');
	}

	/**
	 * @author     Praveen Sethu
	 * @description Test if new subscription preferences and legacy subscription fields are updated
	 **/
	@isTest
	static void testSubscriptionPreferences() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('subscription@preference.com')
			.setPhone('123456789')
			.setCompany('Subscription')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		insert objLead;

		Lead objLeadAssert = [SELECT Id, Customer_Subscriptions__c FROM Lead WHERE Id = :objLead.Id];

		// Assert new subscription fields are updated
		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.BIZ_NEWSLETTER), 'Biz News Letter is not updated');
		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.FEATURE_ANNOUNCEMENTS), 'Features and announcements is not updated');
		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.BENEFIT_ANNOUNCEMENTS), 'Benefits and announcements is not updated');
		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.DEALS_PROMOS), 'Deals and Promos is not updated');
		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.FINANCIAL_PRODUCTS), 'Financial Products is not updated');
		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS), 'Account Partner News is not updated');

		Test.startTest();
		// update subscription preference and check legacy checkbox subscription fields are updated
		objLead.Customer_Subscriptions__c = null;
		update objLead;
		Test.stopTest();

		objLeadAssert = [
			SELECT
				Id,
				Subscription_Center_Small_Biz_Newslet__c,
				Subscription_Center_Feature_Announce__c,
				Subscription_Center_Benefits_Announce__c,
				Subscription_Center_Deals_and_Promos__c,
				Subscription_Center_Financial_Products__c,
				Subscription_Center_Acct_Partner_Newsl__c
			FROM Lead
			WHERE Id = :objLead.Id
		];

		System.assertEquals(false, objLeadAssert.Subscription_Center_Small_Biz_Newslet__c, 'Biz News Letter is not updated');
		System.assertEquals(false, objLeadAssert.Subscription_Center_Feature_Announce__c, 'Features and announcements is not updated');
		System.assertEquals(false, objLeadAssert.Subscription_Center_Benefits_Announce__c, 'Benefits and announcements is not updated');
		System.assertEquals(false, objLeadAssert.Subscription_Center_Deals_and_Promos__c, 'Deals and Promos is not updated');
		System.assertEquals(false, objLeadAssert.Subscription_Center_Financial_Products__c, 'Financial Products is not updated');
		System.assertEquals(false, objLeadAssert.Subscription_Center_Acct_Partner_Newsl__c, 'Account Partner News is not updated');
	}

	/*
	 * @See      	: LeadTriggerHelper.updateChatTranscripts
	 * @Description : Test chat transcript update with converted contact and account ids when lead is converted
	 * 				: Chat activities should also get related to the new records. | BSS-1363
	 */
	@isTest
	static void testConvertedLeadChatTranscriptUpdates() {
		//GIVEN: A lead with chat transcript and activity
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Xero Partner')
			.setStatus('New')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		Task objTask = new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_STANDARD_RT_ID).setWhoId(objLead.Id).setStatus(TaskUtil.TASK_STATUS_OPEN).setStartDate(System.now()).build();
		objTask.Chat_Transcript__c = objLiveChat.Id;

		TaskTriggerHelper.skipTrigger = true;
		insert objTask;
		TaskTriggerHelper.skipTrigger = false;

		objTask = [SELECT Id, WhoId, WhatId FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objTask.WhoId, objLead.Id, 'Task Who Id is incorrect.');
		System.assertEquals(true, String.isBlank(objTask.WhatId), 'Task WhatId is incorrect.');

		//WHEN: The lead is converted
		Test.startTest();
		database.leadConvert lc = new database.leadConvert();
		lc.setLeadId(objLead.id);
		lc.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		lc.setDoNotCreateOpportunity(true);
		Database.LeadConvertResult lcr = Database.convertLead(lc);
		Test.stopTest();

		//THEN: The chat transcript and task should be updated with the converted contact and account ids
		objLiveChat = [SELECT Id, LeadId, ContactId, AccountId FROM LiveChatTranscript WHERE Id = :objLiveChat.Id];
		System.assertEquals(objLiveChat.ContactId, lcr.getContactId(), 'ContactId on LiveChatTranscript was not updated correctly after Lead Conversion.');
		System.assertEquals(objLiveChat.AccountId, lcr.getAccountId(), 'AccountId on LiveChatTranscript was not updated correctly after Lead Conversion.');

		objTask = [SELECT Id, WhoId, WhatId FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objTask.WhoId, lcr.getContactId(), 'Task Who Id was not updated correctly after Lead Conversion.');
		System.assertEquals(objTask.WhatId, lcr.getAccountId(), 'Task WhatId was not updated correctly after Lead Conversion.');
	}

	/**
	 * @author     Debasmita Rawooth
	 * @description Test if Email Opt Out - Outreach is getting updated based on subscription preferences
	 **/
	@isTest
	static void testEmailOptOutOutreachUpdate() {
		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Set<String> set_finalSubscriptionValues = new Set<String>();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('subscription@preference.com')
			.setPhone('123456789')
			.setCompany('Subscription')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		insert objLead;

		Lead objLeadAssert = [SELECT Id, Salesloft_Email_Opt_Out__c, Customer_Subscriptions__c FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.OUTREACH), 'Outreach preference is not updated');
		System.assertEquals(false, objLeadAssert.Salesloft_Email_Opt_Out__c, 'Email Opt Out - Outreach is updated on insert.');

		if (objLeadAssert.Customer_Subscriptions__c != null) {
			set_finalSubscriptionValues.addAll(objLeadAssert.Customer_Subscriptions__c.split(';'));
		}
		if (set_finalSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH)) {
			set_finalSubscriptionValues.remove(SubscriptionCenterUtil.OUTREACH);
		}

		Test.startTest();
		// update subscription preference to remove Outreach and check Email Opt Out - Outreach is updated
		objLead.Customer_Subscriptions__c = String.join(new List<String>(set_finalSubscriptionValues), ';');
		update objLead;
		Test.stopTest();

		objLeadAssert = [SELECT Id, Salesloft_Email_Opt_Out__c FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.Salesloft_Email_Opt_Out__c, 'Email Opt Out - Outreach is not updated.');
	}

	/**
	 * @author     Debasmita Rawooth
	 * @description Test if subscription preferences are getting updated based on Email Opt Out - Outreach update.
	 **/
	@isTest
	static void testSubscriptionPreferenceOutreachUpdate() {
		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('subscription@preference.com')
			.setPhone('123456789')
			.setCompany('Subscription')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		insert objLead;

		Lead objLeadAssert = [SELECT Id, Salesloft_Email_Opt_Out__c, Customer_Subscriptions__c FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.OUTREACH), 'Outreach preference is not updated');
		System.assertEquals(false, objLeadAssert.Salesloft_Email_Opt_Out__c, 'Email Opt Out - Outreach is updated on insert.');

		Test.startTest();
		// update subscription preference to remove Outreach and check Email Opt Out - Outreach is updated
		objLead.Salesloft_Email_Opt_Out__c = true;
		update objLead;
		Test.stopTest();

		objLeadAssert = [SELECT Id, Salesloft_Email_Opt_Out__c, Customer_Subscriptions__c FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(false, objLeadAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.OUTREACH), 'Outreach preference is not removed.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Asserts if TBC fields get updated on Account from lead upon conversion
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testTBCUpdatesBeforeLeadConversion() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@tbctest.com')
			.setPhone('123456789')
			.setCompany('Fraud Test')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setTBC(75)
			.setTBCWithPayroll(39)
			.setTBCPayrollByFirm(5)
			.build();
		insert objLead;

		database.leadConvert objLeadConvert = new database.leadConvert();
		objLeadConvert.setLeadId(objLead.id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		Database.LeadConvertResult objLeadConversionResult = Database.convertLead(objLeadConvert);
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, ConvertedAccountId, No_of_Clients__c, No_Clients_Payroll__c, Total_Business_Clients_Payroll_by_Firm__c FROM Lead WHERE Email = :objLead.Email];
		System.assertNotEquals(null, objLeadInsertAssert.ConvertedAccountId, 'Account didnot get created');

		Account objAccountAssert = [SELECT Id, No_of_Clients__c, No_Clients_Payroll__c, Total_Business_Clients_Payroll_by_Firm__c FROM Account WHERE Id = :objLeadInsertAssert.ConvertedAccountId];
		System.assertEquals(objLead.No_of_Clients__c, objAccountAssert.No_of_Clients__c, 'TBC did not get updated');
		System.assertEquals(objLead.No_Clients_Payroll__c, objAccountAssert.No_Clients_Payroll__c, 'TBC with Payroll did not get updated');
		System.assertEquals(objLead.Total_Business_Clients_Payroll_by_Firm__c, objAccountAssert.Total_Business_Clients_Payroll_by_Firm__c, 'TBC Payroll by Firm did not get updated');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Asserts if TBC fields get updated on Account after lead is already converted
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testTBCUpdatesAfterLeadConversion() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@tbctest.com')
			.setPhone('123456789')
			.setCompany('Fraud Test')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.build();
		insert objLead;

		database.leadConvert objLeadConvert = new database.leadConvert();
		objLeadConvert.setLeadId(objLead.id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		Database.LeadConvertResult objLeadConversionResult = Database.convertLead(objLeadConvert);

		//Requery lead
		Lead objConvertedLead = [SELECT Id, ZP_Company_Lead_ID__c, OwnerId, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		objConvertedLead.No_of_Clients__c = 54;
		objConvertedLead.No_Clients_Payroll__c = 25;
		objConvertedLead.Total_Business_Clients_Payroll_by_Firm__c = 4;
		update objConvertedLead;
		Test.stopTest();

		Lead objLeadInsertAssert = [SELECT Id, ConvertedAccountId, No_of_Clients__c, No_Clients_Payroll__c, Total_Business_Clients_Payroll_by_Firm__c FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(null, objLeadInsertAssert.ConvertedAccountId, 'Account did not get created');

		Account objAccountAssert = [SELECT Id, No_of_Clients__c, No_Clients_Payroll__c, Total_Business_Clients_Payroll_by_Firm__c FROM Account WHERE Id = :objLeadInsertAssert.ConvertedAccountId];
		System.assertEquals(objLeadInsertAssert.No_of_Clients__c, objAccountAssert.No_of_Clients__c, 'TBC did not get updated');
		System.assertEquals(objLeadInsertAssert.No_Clients_Payroll__c, objAccountAssert.No_Clients_Payroll__c, 'TBC with Payroll did not get updated');
		System.assertEquals(objLeadInsertAssert.Total_Business_Clients_Payroll_by_Firm__c, objAccountAssert.Total_Business_Clients_Payroll_by_Firm__c, 'TBC Payroll by Firm did not get updated');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Asserts if Number of Clients is being calculated correctly
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testSetNumberOfClients() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@tbctest.com')
			.setPhone('123456789')
			.setCompany('Fraud Test')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.build();
		insert objLead;

		database.leadConvert objLeadConvert = new database.leadConvert();
		objLeadConvert.setLeadId(objLead.id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		Database.LeadConvertResult objLeadConversionResult = Database.convertLead(objLeadConvert);

		//Requery lead
		Lead objConvertedLead = [SELECT Id, ZP_Company_Lead_ID__c, OwnerId, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		objConvertedLead.No_of_Clients_Bucket__c = '3-9';
		update objConvertedLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, ConvertedAccountId, No_of_Clients__c, No_of_Clients_Bucket__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(6, objLeadAssert.No_of_Clients__c, 'Number of clients did not get updated correctly on Lead.');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Asserts if Number of Clients is being calculated correctly
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testSetNumberOfClients2() {
		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@tbctest.com')
			.setPhone('123456789')
			.setCompany('Fraud Test')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.build();
		insert objLead;

		database.leadConvert objLeadConvert = new database.leadConvert();
		objLeadConvert.setLeadId(objLead.id);
		objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
		Database.LeadConvertResult objLeadConversionResult = Database.convertLead(objLeadConvert);

		//Requery lead
		Lead objConvertedLead = [SELECT Id, ZP_Company_Lead_ID__c, OwnerId, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		objConvertedLead.No_of_Clients_Bucket__c = '4-6';
		update objConvertedLead;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, ConvertedAccountId, No_of_Clients__c, No_of_Clients_Bucket__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(5, objLeadAssert.No_of_Clients__c, 'Number of clients did not get updated correctly on Lead.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Lead ownership is reverted anytime it is changed to Platform Integration User
	 **/
	@isTest
	static void testLeadRoutingOwnershipCheck() {
		User objAdminUser = [SELECT Id FROM User WHERE UserRole.Name = 'admin' AND IsActive = TRUE LIMIT 1];
		User objUser = [SELECT Id, Name FROM User WHERE Name = :LeadUtil.PLATFORM_INTEGRATION_USER LIMIT 1];

		Test.startTest();
		System.runAs(objAdminUser) {
			Lead objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('FName')
				.setLastName('LName')
				.setEmail('prity@gusto.com')
				.setPhone('123456789')
				.setCompany('Xero Partner')
				.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
				.setStatus(LeadUtil.LEAD_STATUS_AQL)
				.setOwnerId(UserInfo.getUserId())
				.build();
			insert objLead;

			objLead.OwnerId = objUser.Id;
			update objLead;

			// assert if lead owner is updated
			Lead objLeadAssert = [SELECT Id, OwnerId FROM Lead WHERE Id = :objLead.Id];
			System.assertNotEquals(objUser.Id, objLeadAssert.OwnerId, 'Lead Owner got incorrectly updated.');
		}
		Test.stopTest();
	}

	@isTest
    static void testSetCampaignInfoInLead() {
        // Retrieve the Qualified Integration user
		String QUALIFIED_INTEGRATION_USERNAME = 'Qualified Integration';
        User objQualifiedUser = [SELECT Id FROM User WHERE Name = :QUALIFIED_INTEGRATION_USERNAME LIMIT 1];

		Lead objLead1 = new TestDataFactory.LeadBuilder()
		.setRecordTypeId(LeadUtil.LABEL_COMPANY)
		.setFirstName('FName')
		.setLastName('LName')
		.setEmail('leadcampaign@member.com')
		.setPhone('123456789')
		.setCompany('Company Lead 1')
		.setStatus(LeadUtil.LEAD_STATUS_AQL)
		.setLeadSource('LinkedIn')
		.setRecentSource('Recent Source')
		.setRecentCampaign('Recent Campaign')
		.setRecentContent('Recent Content')
		.build();

		insert objLead1;
		// Create Campaigns with Accutics IDs and Affiliate Partner IDs
        Campaign objCamp1 = new Campaign(
            Name = 'Campaign 1', 
            Accutics_ID__c = 'A1', 
            Accutics_LeadChannel__c = 'Channel 1', 
            Accutics_AffiliatePlatform__c = 'Platform 1', 
            Accutics_AffiliateType__c = 'Type 1',
            Accutics_BDPartner__c = 'Partner 1',
			Accutics_LeadSource__c = 'LinkedIn'
        );
		insert objCamp1;
        // Run the test method as the Qualified Integration user
        System.runAs(objQualifiedUser) {
			objLead1.accutics_id__c ='A1';
			update objLead1;
        }

        // Reload the leads to verify updates
        Lead objUpdatedLead1 = [SELECT Accutics_ID__c, Lead_Channel__c, Accutics_Affiliate_Platform__c, Accutics_Affiliate_Type__c FROM Lead WHERE Id = :objLead1.Id];

        // Assertions to verify field mappings
        System.assertEquals('Channel 1', objUpdatedLead1.Lead_Channel__c, 'Lead 1 channel mismatch');
        System.assertEquals('Platform 1', objUpdatedLead1.Accutics_Affiliate_Platform__c, 'Lead 1 platform mismatch');
    }
}