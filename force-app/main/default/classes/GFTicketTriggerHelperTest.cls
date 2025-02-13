/**
 * @name         : GFTicketTriggerHelperTest
 * @author       : Pradeep Chary
 * @date         : 04/26/2021
 * @description  : Test class for GFTicketTriggerHelper
 **/

@isTest
private class GFTicketTriggerHelperTest {
	@testSetup
	static void setup() {
		//create the Case Reason Classification
		List<Case_Reason_Classification__c> list_CaseReasonClassifications = new List<Case_Reason_Classification__c>();
		Case_Reason_Classification__c objTaxResReason = new Case_Reason_Classification__c(
			Name = 'Route to Tax Res',
			Type__c = GFTicketUtil.TAX_RES_CASE_RECORD_TYPE,
			Priority__c = 'High',
			Active__c = true,
			Reason_Code__c = 'route_to_taxres'
		);
		list_CaseReasonClassifications.add(objTaxResReason);

		//create the Accounts
		List<Account> list_Accounts = new List<Account>();
		AccountTriggerHelper.skipTrigger = true;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('222222222222')
			.setJoinedDate(Date.today())
			.setZPCompanyOverallStatus('Active')
			.build();

		list_Accounts.add(objCompanyAccount);

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account').setZPFirmId('1111111111').build();
		list_Accounts.add(objResellerAccount);

		insert list_Accounts;

		//create the Contacts
		List<Contact> list_Contacts = new List<Contact>();
		ContactTriggerHelper.skipTrigger = true;

		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setLastName('TestCompanyUser')
			.setEmail('testuser@abccompany.com')
			.build();
		list_Contacts.add(objCompanyContact);

		//create reseller contact
		Contact objResellerContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.RESELLER_CONTACT_RT_ID)
			.setAccountId(objResellerAccount.Id)
			.setLastName('TestResellerUser')
			.setEmail('testuserreseller@abccompany.com')
			.setZPUserId(UserInfo.getUserId())
			.build();
		list_Contacts.add(objResellerContact);

		insert list_Contacts;

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;

		Case_Reason_Classification__c objCaseReasonClassification = new Case_Reason_Classification__c();
		objCaseReasonClassification.Name = 'Test Reason';
		objCaseReasonClassification.Type__c = GFTicketUtil.TAX_RES_CASE_RECORD_TYPE;
		objCaseReasonClassification.Active__c = true;
		objCaseReasonClassification.Reason_Code__c = 'test_reason';
		list_CaseReasonClassifications.add(objCaseReasonClassification);

		List<Product_Area__c> list_productAreas = new List<Product_Area__c>();
		Product_Area__c objProductArea = new TestDataFactory.ProductAreaBuilder().setName('Managing your team').build();
		list_productAreas.add(objProductArea);
		insert list_productAreas;
		List<Sub_Product_Area__c> list_subProductAreas = new List<Sub_Product_Area__c>();
		Sub_Product_Area__c objSubProductArea = new TestDataFactory.SubProductAreaBuilder().setName('Team member profiles').setProductArea(list_productAreas[0].Id).build();
		list_subProductAreas.add(objSubProductArea);
		insert list_subProductAreas;

		Case_Reason_Classification__c objBackdatedAddressCRC = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Backdated Employee Address Change')
			.setIsActive(true)
			.setType(CaseUtils.TYPE_ENGAGEMENT)
			.setProductArea(list_productAreas[0].Id)
			.setSubProductArea(list_subProductAreas[0].Id)
			.setReasonCode('backdated_employee_address_change')
			.setCaseTypePillar(CaseUtils.TAXES_CASE_PILLAR)
			.setSupportLevel(CaseUtils.TIER_2)
			.build();
		list_CaseReasonClassifications.add(objBackdatedAddressCRC);

		Case_Reason_Classification__c objEOYSpotCheck = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('EoY Spot Check Squad Action Required')
			.setIsActive(true)
			.setClass('Class 3')
			.setType(CaseUtils.TYPE_ENGAGEMENT)
			.build();
		list_CaseReasonClassifications.add(objEOYSpotCheck);
		insert list_CaseReasonClassifications;

		List<Case> list_Cases = new List<Case>();

		Case objCase = new Case();
		objCase.RecordTypeId = cache.getRecordTypeId('Case', GFTicketUtil.PAYROLL_CARE_RECORD_TYPE);
		objCase.AccountId = objCompanyAccount.Id;
		objCase.ContactId = objCompanyContact.Id;
		objCase.Subject = 'Payroll Care Case';
		objCase.Description = 'Payroll Care Case';
		objCase.SuppliedEmail = 'test.contact@gusto.com';
		objCase.Type = GFTicketUtil.PAYROLL_CARE_RECORD_TYPE;
		objCase.Origin = 'Email';
		objCase.Direction__c = 'Inbound';
		objCase.Integration_Id__c = '222222222222';
		objCase.Integration_Key__c = '222222222222';
		objCase.Routing_Case_Reason_Classification__c = objCaseReasonClassification.Id;
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objCompanyAccount.Id)
			.setContactId(objCompanyContact.Id)
			.setSubject('Case for auto closed test')
			.setDescription('desc')
			.setSuppliedEmail('test.contact@gusto.com')
			.setType('Payroll Care')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setSuppliedPhone('1234567890')
			.build();
		list_Cases.add(objCase2);

		CaseTriggerHelper.skipTrigger = true;
		insert list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		Agency_Information__c objAgency = new Agency_Information__c();
		objAgency.Name = 'Test Name';
		objAgency.Tax_type__c = 'Unemployment';
		objAgency.Agency_Slug__c = 'wa_lni';
		insert objAgency;

		List<GF_Ticket__c> list_GFTix = new List<GF_Ticket__c>();
		GF_Ticket__c objValidCaseReasonTixWithUnknownAgencySlug = new TestDataFactory.GFTicketBuilder()
			.setExternalId('000002345')
			.setCompanyId('0101111')
			.setSubject('objValidCaseReasonTixWithUnknownAgencySlug')
			.setEmail('objValidCaseReasonTixWithUnknownAgencySlug@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"unknown","is_in_app_notice":"false","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();
		list_GFTix.add(objValidCaseReasonTixWithUnknownAgencySlug);

		GF_Ticket__c objValidCaseReasonTixWithBlankAgencySlug = new TestDataFactory.GFTicketBuilder()
			.setExternalId('2345678910')
			.setCompanyId('0101111')
			.setSubject('objValidCaseReasonTixWithBlankAgencySlug')
			.setEmail('objValidCaseReasonTixWithBlankAgencySlug@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"","is_in_app_notice":"true","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();

		list_GFTix.add(objValidCaseReasonTixWithBlankAgencySlug);

		GF_Ticket__c objValidCaseReasonTixWithNoticeType = new TestDataFactory.GFTicketBuilder()
			.setExternalId('234567899')
			.setCompanyId('0101111')
			.setSubject('objValidCaseReasonTixWithNoticeType')
			.setEmail('objValidCaseReasonTixWithNoticeType@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"","is_in_app_notice":"true","notice_type":"Missing or late payment","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();
		list_GFTix.add(objValidCaseReasonTixWithNoticeType);

		GF_Ticket__c objValidCaseReasonTixWithAgencySlug = new TestDataFactory.GFTicketBuilder()
			.setExternalId('2345678911')
			.setCompanyId('0101111')
			.setSubject('objValidCaseReasonTixWithAgencySlug')
			.setEmail('objValidCaseReasonTixWithAgencySlug@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"wa_lni","is_in_app_notice":"true","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();
		list_GFTix.add(objValidCaseReasonTixWithAgencySlug);

		CaseTriggerHelper.skipTrigger = true;
		insert list_GFTix;
		CaseTriggerHelper.skipTrigger = false;
	}

	/* 
	 * @Author:          Alex Xiong
	 * @Description:     Test if document_mapping GF Tickets will create Document Mapping Cases. 
						 Test if udpating GF Ticket to eoy_spot_check will add EoY Spot Check Squad Action Required Case Reason
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testDocumentMapping() {
		Test.startTest();

		GF_Ticket__c objDocumentMappingTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('00000002')
			.setCompanyId('222222222222')
			.setSubject(GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE)
			.setEmail('test@test.com')
			.setTicketType(GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE)
			.setAdditionalData('{"external_comment":{"isPublic":true, "html_body":"test Body"}, "accounting_firm_id":"1111111111"}')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert objDocumentMappingTix;

		List<Case> list_Cases = [SELECT Type FROM Case WHERE Subject = :GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE];
		if (!list_Cases.isEmpty()) {
			System.assertEquals(GFTicketUtil.DOCUMENT_MAPPING_CASE_TYPE, list_Cases[0].Type, 'Case Type should match.');
		}

		GFTicketTriggerHelper.blnIsFirstEOYSpotCase = true;

		GF_Ticket__c objGFTicket = [SELECT Id, Subject__c FROM GF_Ticket__c WHERE Id__c = '00000002'];
		objGFTicket.Ticket_Type__c = GFTicketUtil.EOY_SPOT_CHECK_TICKET_TYPE;
		update objGFTicket;

		GFTicketTriggerHelper.blnQueue = false;
		GFTicketTriggerHelper.blnIsFirstEOYSpotCase = false;
		CaseTriggerHelper.skipTrigger = false;

		List<Case> list_UpdatedCases = [SELECT Routing_Case_Reason__c FROM Case WHERE Subject = :objGFTicket.Subject__c];
		if (!list_UpdatedCases.isEmpty()) {
			System.assertEquals(GFTicketUtil.EOY_SPOT_CHECK_SQUAD_ACTION_REQUIRED_REASON, list_UpdatedCases[0].Routing_Case_Reason__c, 'Routing Case Reason should match.');
		}

		delete objGFTicket;
		undelete objGFTicket;

		Test.stopTest();
	}

	/*
	 * @Author:          Sanjay Paryani
	 * @Description:     Test if backdated_address_changes GF Tickets will create a Payroll Care case
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testBackdateAddressChangeCase() {
		Test.startTest();

		GF_Ticket__c objBackdatedGFTicket = new TestDataFactory.GFTicketBuilder()
			.setExternalId('11111111111114')
			.setCompanyId('222222222222')
			.setSubject(GFTicketUtil.ADDRESS_CHANGE_TICKET_TYPE)
			.setEmail('test@test.com')
			.setTicketType(GFTicketUtil.ADDRESS_CHANGE_TICKET_TYPE)
			.setAdditionalData('')
			.setDIVR('')
			.setTags('')
			.setReason(GFTicketUtil.BACKDATEDADDRESSCHANGE_REASONCODE)
			.build();

		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert objBackdatedGFTicket;

		List<Case> list_Cases = [SELECT Routing_Case_Reason__c, RecordTypeId, Type, Support_Level__c FROM Case WHERE Subject = :GFTicketUtil.ADDRESS_CHANGE_TICKET_TYPE];
		Case_Reason_Classification__c objCaseReason = [
			SELECT Id, Name, Support_Level__c, Case_Type_Pillar__c 
			FROM Case_Reason_Classification__c 
			WHERE Reason_Code__c = :GFTicketUtil.BACKDATEDADDRESSCHANGE_REASONCODE AND Active__c = true
		];
		System.assert(list_Cases.size() > 0, 'Case list should not be empty.');
		System.assertEquals(objCaseReason.Name, list_Cases[0].Routing_Case_Reason__c, 'Routing_Case_Reason__c should match.');
		System.assertEquals(objCaseReason.Case_Type_Pillar__c, list_Cases[0].Type, 'Case Type should match.');
		System.assertEquals(GFTicketUtil.ENGAGEMENT_RT_ID, list_Cases[0].RecordTypeId, 'RecordTypeId should match.');
		System.assertEquals(objCaseReason.Support_Level__c, list_Cases[0].Support_Level__c, 'Support Level should match.');

		Test.stopTest();
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     Test if ach_update_failed GF Tickets will add ACH Failure Reason to Case
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testACHUpdateFailed() {
		Test.startTest();

		GF_Ticket__c objACHTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('11111111111114')
			.setCompanyId('222222222222')
			.setSubject(GFTicketUtil.ACH_UPDATE_FAILED_TICKET_TYPE)
			.setEmail('test@test.com')
			.setTicketType(GFTicketUtil.ACH_UPDATE_FAILED_TICKET_TYPE)
			.setAdditionalData('')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert objACHTix;

		List<Case> list_Cases = [SELECT Routing_Case_Reason__c FROM Case WHERE Subject = :GFTicketUtil.ACH_UPDATE_FAILED_TICKET_TYPE];
		if (!list_Cases.isEmpty()) {
			System.assertEquals(GFTicketUtil.ACH_FAILURE_REASON, list_Cases[0].Routing_Case_Reason__c, 'Routing_Case_Reason__c should match.');
		}

		Test.stopTest();
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     Test if defer_payments GF Tickets will create Defer Repayment Case
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testDeferPayments() {
		Test.startTest();

		GF_Ticket__c objDeferPaymentTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('11111111111115')
			.setCompanyId('222222222222')
			.setSubject(GFTicketUtil.DEFER_PAYMENTS_TICKET_TYPE)
			.setEmail('test@test.com')
			.setTicketType(GFTicketUtil.DEFER_PAYMENTS_TICKET_TYPE)
			.setAdditionalData('')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert objDeferPaymentTix;

		List<Case> list_Cases = [SELECT Type FROM Case WHERE Subject = :GFTicketUtil.DEFER_PAYMENTS_TICKET_TYPE];
		if (!list_Cases.isEmpty()) {
			System.assertEquals(GFTicketUtil.PAYROLL_CASE_TYPE, list_Cases[0].Type, 'Case Type should match.');
		}

		objDeferPaymentTix.Reason__c = 'test_reason';
		update objDeferPaymentTix;

		List<Case> list_Cases2 = [
			SELECT Confirm_Case_Reason__c, Routing_Case_Reason__c, Confirm_Case_Reason_Classification__c, Routing_case_reason_Classification__c
			FROM Case
			WHERE Subject = :GFTicketUtil.DEFER_PAYMENTS_TICKET_TYPE
		];
		System.assertEquals(list_Cases2[0].Confirm_Case_Reason__c, list_Cases2[0].Routing_Case_Reason__c, 'Routing_Case_Reason__c should match.');
		System.assertEquals(list_Cases2[0].Confirm_Case_Reason_Classification__c, list_Cases2[0].Routing_Case_Reason_Classification__c, 'Routing_Case_Reason_Classification__c should match.');
		System.assertNotEquals(null, list_Cases2[0].Confirm_Case_Reason__c, 'Confirm_Case_Reason__c should not be null.');
		System.assertNotEquals(null, list_Cases2[0].Confirm_Case_Reason_Classification__c, 'Confirm_Case_Reason_Classification__c should not be null.');
		Test.stopTest();
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     Test if a GF Ticket with a Tax Res case reason will create a Tax Res Case
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testTaxResCaseReason() {
		Test.startTest();

		GF_Ticket__c objValidCaseReasonTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('00000001')
			.setCompanyId('222222222222')
			.setSubject('route_to_taxres')
			.setEmail('test2@test.com')
			.setTicketType(GFTicketUtil.SUPPORT_FORM_TICKET_TYPE)
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021"}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();

		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert objValidCaseReasonTix;

		List<Case> list_Cases = [SELECT RecordType.Name, Notice_Period__c, HTML_Description__c FROM Case WHERE Subject = 'route_to_taxres'];
		if (!list_Cases.isEmpty()) {
			System.assertEquals('Q1 2021', list_Cases[0].Notice_Period__c, 'Notice_Period__c should match.');
			System.assertEquals(GFTicketUtil.TAX_RES_CASE_RECORD_TYPE, list_Cases[0].RecordType.Name, 'RecordType name should match.');
			System.assertEquals(objValidCaseReasonTix.Body__c, list_Cases[0].HTML_Description__c, 'HTML_Description__c should match.');
		}

		Test.stopTest();
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     Test if a GF Ticket with no valid case reason case reason will create a Payroll Care Case
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testNoValidCaseReason() {
		Test.startTest();

		GF_Ticket__c objNoCaseReasonTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('00000000')
			.setCompanyId('222222222222')
			.setSubject('no case reason')
			.setEmail('test1@test.com')
			.setTicketType(GFTicketUtil.SUPPORT_FORM_TICKET_TYPE)
			.setAdditionalData('')
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('')
			.build();

		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert objNoCaseReasonTix;

		List<Case> list_Cases = [SELECT RecordType.Name FROM Case WHERE Subject = 'no case reason'];
		if (!list_Cases.isEmpty()) {
			System.assertEquals(GFTicketUtil.ENGAGEMENT_RECORD_TYPE, list_Cases[0].RecordType.Name, 'RecordType name should match.');
		}

		Test.stopTest();
	}

	/* 
	 * @Author:          Pradeep Chary
	 * @Description:     Test if document_mapping GF Tickets will create Document Mapping Cases. 
						 Test if udpating GF Ticket to eoy_spot_check will add EoY Spot Check Squad Action Required Case Reason
						 blnQueue and blnIsFirstEOYSpotCase are set to false
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testDocumentMappingNegative() {
		Test.startTest();

		GF_Ticket__c objDocumentMappingTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('00000002')
			.setCompanyId('222222222222')
			.setSubject(GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE)
			.setEmail('test@test.com')
			.setTicketType(GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE)
			.setAdditionalData('{"external_comment":{"isPublic":true, "html_body":"test Body"}, "accounting_firm_id":"1111111111"}')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		insert objDocumentMappingTix;

		List<Case> list_Cases = [SELECT Type FROM Case WHERE Subject = :GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE];
		if (!list_Cases.isEmpty()) {
			System.assertEquals(GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE, list_Cases[0].Type, 'Case Type should match.');
		}

		GF_Ticket__c objGFTicket = [SELECT Id, Subject__c FROM GF_Ticket__c WHERE Id__c = '00000002'];
		objGFTicket.Ticket_Type__c = GFTicketUtil.EOY_SPOT_CHECK_TICKET_TYPE;
		update objGFTicket;

		GFTicketTriggerHelper.blnQueue = false;
		GFTicketTriggerHelper.blnIsFirstEOYSpotCase = false;
		CaseTriggerHelper.skipTrigger = false;

		List<Case> list_UpdatedCases = [SELECT Routing_Case_Reason__c FROM Case WHERE Subject = :objGFTicket.Subject__c];
		if (!list_UpdatedCases.isEmpty()) {
			System.assertEquals(GFTicketUtil.EOY_SPOT_CHECK_SQUAD_ACTION_REQUIRED_REASON, list_UpdatedCases[0].Routing_Case_Reason__c, 'Routing_Case_Reason__c should match.');
		}

		delete objGFTicket;
		undelete objGFTicket;

		Test.stopTest();
	}

	/*
	 * @Author:          Pradeep Chary
	 * @Description:     Test if the method queries Accounts based on a Set of ZP Company and Firm ids
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testGetAccounts() {
		Test.startTest();

		// Defines a new set of company Ids and Firm Ids
		Set<String> set_CompanyIds = new Set<String>{ '222222222222' };
		Set<String> set_FirmIds = new Set<String>{ '1111111111' };

		GFTicketTriggerHelper objGFTicketTriggerHelper = new GFTicketTriggerHelper();
		objGFTicketTriggerHelper.map_ZPCompanyIdToAccount = new Map<String, Account>();
		objGFTicketTriggerHelper.getAccounts(set_CompanyIds, set_FirmIds);

		System.assert(!objGFTicketTriggerHelper.map_ZPCompanyIdToAccount.isEmpty(), 'map_ZPCompanyIdToAccount should not be empty.');
		System.assert(!objGFTicketTriggerHelper.map_ZPFirmIdToAccount.isEmpty(), 'map_ZPFirmIdToAccount should not be empty.');

		Test.stopTest();
	}

	/*
	 * @Author:          Pradeep Chary
	 * @Description:     Test if the method queries Contacts based on a Set of ZP user ids and email addresses
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testGetContacts() {
		Test.startTest();

		// Defines a new set of user Ids and emails
		Set<String> set_UserIds = new Set<String>{ UserInfo.getUserId() };
		Set<String> set_Emails = new Set<String>{ 'testuser@abccompany.com' };

		GFTicketTriggerHelper objGFTicketTriggerHelper = new GFTicketTriggerHelper();
		objGFTicketTriggerHelper.getContacts(set_UserIds, set_Emails);

		System.assert(!objGFTicketTriggerHelper.map_UserIdToContact.isEmpty(), 'map_UserIdToContact should not be empty.');
		System.assert(!objGFTicketTriggerHelper.map_EmailToContact.isEmpty(), 'map_EmailToContact should not be empty.');

		Test.stopTest();
	}

	/*
	 * @Author:          Pradeep Chary
	 * @Description:     Test if the method queries Cases based on a Set of Integration Ids and put them into map_Cases
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testGetMapCases() {
		Test.startTest();

		// Defines a new set of Ticket Ids
		Set<String> set_TicketIds = new Set<String>{ '222222222222' };

		GFTicketTriggerHelper objGFTicketTriggerHelper = new GFTicketTriggerHelper();
		objGFTicketTriggerHelper.getMapCases(set_TicketIds);

		System.assert(!objGFTicketTriggerHelper.map_Cases.isEmpty(), 'map_Cases should not be empty.');

		Test.stopTest();
	}

	/*
	 * @Author:          Pradeep Chary
	 * @Description:     Test if the method returns Case Classification reason when Case Reason is passed
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testCaseClassificationReason() {
		Test.startTest();

		GFTicketTriggerHelper objGFTicketTriggerHelper = new GFTicketTriggerHelper();
		Id idCaseClassificationReason = objGFTicketTriggerHelper.caseClassificationReason('Test Reason');

		System.assert(String.isNotBlank(Id.valueOf(idCaseClassificationReason)), 'idCaseClassificationReason should not be blank.');

		Test.stopTest();
	}

	/* 
	 * @Author:          Pradeep Chary
	 * @Description:     Test if Tickets have Requester User Id
						 and org does not have a Contact with this ZP User Id nor Email provided,
						 then create the Contact record
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testCreateContacts() {
		Test.startTest();

		GF_Ticket__c objDocumentMappingTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('00000002')
			.setCompanyId('222222222222')
			.setSubject('document_mapping')
			.setEmail('test@test.com')
			.setTicketType('document_mapping')
			.setAdditionalData('{"external_comment":{"isPublic":true, "html_body":"test Body"}, "accounting_firm_id":"1111111111"}')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();
		objDocumentMappingTix.Requester_User_Id__c = '00000003';

		insert objDocumentMappingTix;

		List<GF_Ticket__c> list_Tickets = [
			SELECT Id, Id__c, Body__c, Ticket_Type__c, User_Role_Id__c, Company_Id__c, Requester_User_Id__c, Requester_Email__c, Subject__c, Processing_State__c
			FROM GF_Ticket__c
			LIMIT 1
		];

		GFTicketTriggerHelper objGFTicketTriggerHelper = new GFTicketTriggerHelper();
		objGFTicketTriggerHelper.createContacts(list_Tickets);

		System.assert(objGFTicketTriggerHelper.map_UserIdToContact.isEmpty(), 'map_UserIdToContact should be empty.');

		Test.stopTest();
	}

	/*
	 * @Author:          Pradeep Chary
	 * @Description:     Test to Set fields on Case under method setCaseInfo
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void testSetCaseInfo() {
		Test.startTest();

		GF_Ticket__c objDocumentMappingTix = new TestDataFactory.GFTicketBuilder()
			.setExternalId('00000002')
			.setCompanyId('222222222222')
			.setSubject('document_mapping')
			.setEmail('test@test.com')
			.setTicketType('document_mapping')
			.setAdditionalData('{"external_comment":{"isPublic":true, "html_body":"test Body"}, "accounting_firm_id":"1111111111"}')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		insert objDocumentMappingTix;
		List<GF_Ticket__c> list_Tickets = [
			SELECT Id, Id__c, Body__c, Ticket_Type__c, User_Role_Id__c, Company_Id__c, Requester_User_Id__c, Requester_Email__c, Subject__c, Processing_State__c
			FROM GF_Ticket__c
			LIMIT 1
		];

		String jsonStr = '{"external_comment":{"isPublic":true, "html_body":"test Body"}, "accounting_firm_id": "1111111111", "employee_ids":"222222222", "tax_id":"333333333", "doc_request_status":"Pending"}';
		GFTicketAdditionalInfoJSON objGFTicketAdditionalInfoJSON = GFTicketAdditionalInfoJSON.parse(jsonStr);

		GFTicketTriggerHelper objGFTicketTriggerHelper = new GFTicketTriggerHelper();
		objGFTicketTriggerHelper.setCaseInfo(new Case(), objGFTicketAdditionalInfoJSON, list_Tickets[0]);

		System.assert(objGFTicketTriggerHelper.map_ZPFirmIdToAccount.isEmpty(), 'map_ZPFirmIdToAccount should be empty.');

		Test.stopTest();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Tests agency slug functionality and if its carried over to case correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithAgencyPositive() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id, Agency_Information__c, Agency_Information__r.Agency_Slug__c, In_App_Notice__c FROM Case WHERE Agency_Information__c != NULL AND In_App_Notice__c = TRUE];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'List size should be more than 0.');
		System.assertEquals('wa_lni', list_Case[0].Agency_Information__r.Agency_Slug__c, 'Agency_Slug__c should match.');
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Tests unknown agency slug functionality and if its carried over to case correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithAgencyNegativeWithUnknownAgencySlug() {
		Test.startTest();

		List<GF_Ticket__c> list_GFTicket = [SELECT Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c = '000002345'];
		List<Case> list_Case = [SELECT Id, Agency_Information__c, In_App_Notice__c FROM Case WHERE Agency_Information__c = NULL AND In_App_Notice__c = FALSE AND RecordType.Name = 'Tax Res'];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'Case list size should be greater than 0.');
		System.assert(list_GFTicket.size() > 0, 'GFTicket list size should be greater than 0.');
		System.assertEquals(list_GFTicket[0].Case_Id__c, list_Case[0].Id, 'Id should match.');
		System.assertEquals(null, list_Case[0].Agency_Information__c, 'Agency_Information__c should be null.');
		System.assert(!list_Case[0].In_App_Notice__c, 'In_App_Notice__c should be false.');
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Test functionality without agency slug and if case is created correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithAgencyNegativeWithBlankAgencySlug() {
		Test.startTest();
		List<GF_Ticket__c> list_GFTicket = [SELECT Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c = '2345678910'];
		List<Case> list_Case = [SELECT Agency_Information__c, In_App_Notice__c FROM Case WHERE Agency_Information__c = NULL AND In_App_Notice__c = TRUE AND RecordType.Name = 'Tax Res'];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'Case list size should be greater than 0.');
		System.assert(list_GFTicket.size() > 0, 'GFTicket list size should be greater than 0.');
		System.assertEquals(list_GFTicket[0].Case_Id__c, list_Case[0].Id, 'Id should match.');
		System.assertEquals(null, list_Case[0].Agency_Information__c, 'Agency_Information__c should be null.');
		System.assert(list_Case[0].In_App_Notice__c, 'In_App_Notice__c should be true.');
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Tests notice type functionality and if its carried over to case correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithNoticeType() {
		Test.startTest();
		List<GF_Ticket__c> list_GFTicket = [SELECT Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c = '234567899'];
		List<Case> list_Case = [SELECT Agency_Information__c, In_App_Notice__c, Notice_Type__c FROM Case WHERE Notice_Type__c != NULL AND In_App_Notice__c = TRUE AND RecordType.Name = 'Tax Res'];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'List size should be more than 0.');
		System.assert(list_GFTicket.size() > 0, 'List size should be more than 0.');
		System.assertEquals(list_GFTicket[0].Case_Id__c, list_Case[0].Id, 'Id should match.');
		System.assertEquals('Missing or late payment', list_Case[0].Notice_Type__c, 'Notice_Type__c should match.');
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Tests Penalty Amount functionality and if its carried over to case correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithPenaltyAmount() {
		Test.startTest();

		GF_Ticket__c objCaseWithPenaltyAmount = new TestDataFactory.GFTicketBuilder()
			.setExternalId('2345678991')
			.setCompanyId('222222222222')
			.setSubject('route_to_taxres')
			.setEmail('test2@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"","is_in_app_notice":"true","notice_type":"Missing or late payment","penalty_amount":"55.00","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();

		List<GF_Ticket__c> list_GFTix = new List<GF_Ticket__c>();
		list_GFTix.add(objCaseWithPenaltyAmount);
		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert list_GFTix;

		List<GF_Ticket__c> list_GFTicket = [SELECT Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c = '2345678991'];
		List<Case> list_Case = [
			SELECT Agency_Information__c, In_App_Notice__c, Penalty_Amount__c
			FROM Case
			WHERE Penalty_Amount__c != NULL AND In_App_Notice__c = TRUE AND RecordType.Name = 'Tax Res'
		];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'List size should be more than 0.');
		System.assert(list_GFTicket.size() > 0, 'List size should be more than 0.');
		System.assertEquals(list_GFTicket[0].Case_Id__c, list_Case[0].Id, 'Id should match.');
		System.assertEquals(55.00, list_Case[0].Penalty_Amount__c, 'Penalty_Amount__c should match.');
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Tests variations of Penalty Amount functionality and if its carried over to case correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithPenaltyAmountV2() {
		Test.startTest();

		GF_Ticket__c objCaseWithPenaltyAmount = new TestDataFactory.GFTicketBuilder()
			.setExternalId('2345678993')
			.setCompanyId('222222222222')
			.setSubject('route_to_taxres')
			.setEmail('test2@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"","is_in_app_notice":"true","notice_type":"Missing or late payment","penalty_amount":"3,079.75","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();

		List<GF_Ticket__c> list_GFTix = new List<GF_Ticket__c>();
		list_GFTix.add(objCaseWithPenaltyAmount);
		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert list_GFTix;

		List<GF_Ticket__c> list_GFTicket = [SELECT Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c = '2345678993'];
		List<Case> list_Case = [
			SELECT Agency_Information__c, In_App_Notice__c, Penalty_Amount__c
			FROM Case
			WHERE Penalty_Amount__c != NULL AND In_App_Notice__c = TRUE AND RecordType.Name = 'Tax Res'
		];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'List size should be more than 0.');
		System.assert(list_GFTicket.size() > 0, 'List size should be more than 0.');
		System.assertEquals(list_GFTicket[0].Case_Id__c, list_Case[0].Id, 'Id should match.');
		System.assertEquals(3079.75, list_Case[0].Penalty_Amount__c, 'Penalty_Amount__c should match.');
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Tests Payment Due Date functionality and if its carried over to case correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithPaymentDueDate() {
		Date dtPaymentDueDate = date.newInstance(2021, 12, 12);

		Test.startTest();
		GF_Ticket__c objCaseWithPaymentDueDate = new TestDataFactory.GFTicketBuilder()
			.setExternalId('2345678992')
			.setCompanyId('222222222222')
			.setSubject('route_to_taxres')
			.setEmail('test2@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"","is_in_app_notice":"true","notice_type":"Missing or late payment","payment_due_date":"12/12/2021","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();

		List<GF_Ticket__c> list_GFTix = new List<GF_Ticket__c>();
		list_GFTix.add(objCaseWithPaymentDueDate);
		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert list_GFTix;

		List<GF_Ticket__c> list_GFTicket = [SELECT Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c = '2345678992'];
		List<Case> list_Case = [
			SELECT Agency_Information__c, In_App_Notice__c, Payment_Due_Date__c
			FROM Case
			WHERE Payment_Due_Date__c != NULL AND In_App_Notice__c = TRUE AND RecordType.Name = 'Tax Res'
		];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'List size should be more than 0.');
		System.assert(list_GFTicket.size() > 0, 'List size should be more than 0.');
		System.assertEquals(list_GFTicket[0].Case_Id__c, list_Case[0].Id, 'Id should match.');
		System.assertEquals(dtPaymentDueDate, list_Case[0].Payment_Due_Date__c, 'Payment_Due_Date__c should match.');
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Tests skip trigger
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void testSkipTrigger() {
		Test.startTest();
		GFTicketTriggerHelper.skipTrigger = true;
		List<GF_Ticket__c> list_GFTix = [SELECT Id FROM GF_Ticket__c LIMIT 1];
		update list_GFTix;

		GFTicketTriggerHandler.resetSkipTriggerFlags();

		//insert a duplicate GF Ticket from setup
		GF_Ticket__c objValidCaseReasonTixWithUnknownAgencySlug = new TestDataFactory.GFTicketBuilder()
			.setExternalId('000002345')
			.setCompanyId('0101111')
			.setSubject('objValidCaseReasonTixWithUnknownAgencySlug')
			.setEmail('objValidCaseReasonTixWithUnknownAgencySlug@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"unknown","is_in_app_notice":"false","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();

		try {
			insert objValidCaseReasonTixWithUnknownAgencySlug;
		} catch (Exception ex) {
			System.assert(ex.getMessage().contains('DUPLICATE_VALUE'), 'Exception message should contain \'DUPLICATE_VALUE\'.');
		}

		Test.stopTest();
	}

	/*
	 * @Author         Pradeep Chary
	 * @Description    Test Benefit Adjustment cases Request Id to populating on Case Integration Id
	 */
	@isTest
	static void testCaseIntegrationIdPopulation() {
		Test.startTest();

		GF_Ticket__c objGFTicket = new TestDataFactory.GFTicketBuilder()
			.setExternalId('11111111111116')
			.setCompanyId('222222222222')
			.setSubject('Test Int.Id Check')
			.setEmail('test@test.com')
			.setTicketType(GFTicketUtil.SUPPORT_FORM_TICKET_TYPE)
			.setAdditionalData('{"benefit_adjustment_request_id":"1234"}')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert objGFTicket;

		List<Case> list_Cases = [SELECT Integration_Key__c, OwnerId FROM Case WHERE Subject = 'Test Int.Id Check'];
		Group objGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :GFTicketUtil.DEFAULT_ROUTING_QUEUE];
		if (!list_Cases.isEmpty()) {
			System.assert(list_Cases[0].Integration_Key__c == '1234', 'Failed to populate Integration id');
			System.assertEquals(list_Cases[0].OwnerId, objGroup.Id, 'Case should be routed to default routing queue');
		}

		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description make sure that a GF Ticket that creates an auto solved case - merged duplicate
	 * will not attempt to make another email message
	 */
	@isTest
	static void testMergedDuplicateGFTicket() {
		Test.startTest();
		GF_Ticket__c objGF = new TestDataFactory.GFTicketBuilder()
			.setExternalId('111')
			.setCompanyId('222222222222')
			.setSubject('Case for auto closed test')
			.setEmail('test.contact@gusto.com')
			.setTicketType(GFTicketUtil.SUPPORT_FORM_TICKET_TYPE)
			.setAdditionalData('{}')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CaseAuditLogTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;
		UserTriggerHelper.skipTrigger = true;
		ZPUserTriggerHelper.skipTrigger = true;
		ZPUserRoleTriggerHelper.skipTrigger = true;
		IVRRoutingLogTriggerHelper.skipTrigger = true;
		GFTicketTriggerHelper.blnQueue = true;
		CaseAuditLogTriggerHelper.skipTrigger = true;
		insert objGF;
		Test.stopTest();

		list<Case> list_Case = [SELECT Id, Status, Closed_Reason__c FROM Case WHERE Integration_Id__c = '111'];
		System.assertEquals('Merged Duplicate', list_Case[0].Closed_Reason__c, 'Closed_Reason__c should match.');

		List<Exception_Log__c> list_Logs = [SELECT Id FROM Exception_Log__c];
		//System.assertEquals(0, list_Logs.size(), 'List size should be 0.');
	}

	/**
	 * @author Alex Xiong
	 * @description make sure EOY tickets are created without error
	 */
	@isTest
	static void testEOYCreation() {
		Test.startTest();
		GF_Ticket__c objGF = new TestDataFactory.GFTicketBuilder()
			.setExternalId('111')
			.setCompanyId('222222222222')
			.setSubject('EOY test')
			.setEmail('test.contact@gusto.com')
			.setTicketType(GFTicketUtil.EOY_SPOT_CHECK_TICKET_TYPE)
			.setAdditionalData('{}')
			.setDIVR('')
			.setTags('[]')
			.setReason('')
			.build();

		GFTicketTriggerHelper.blnQueue = false;
		GFTicketTriggerHelper.blnIsFirstEOYSpotCase = false;

		insert objGF;

		Test.stopTest();
		List<FeedItem> list_Feed = [SELECT Id FROM FeedItem];
		System.assertEquals(0, list_Feed.size(), 'List size should be 0.');
		List<Exception_Log__c> list_Logs = [SELECT Id FROM Exception_Log__c];
		//System.assertEquals(0, list_Logs.size(), 'List size should be 0.');
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : Tests variations of Penalty Amount limit functionality and if its carried over to case correctly
	 * @Parm        :
	 * @Return      :
	 **/
	@isTest
	public static void caseWithPenaltyAmountV3() {
		Test.startTest();

		GF_Ticket__c objCaseWithPenaltyAmount = new TestDataFactory.GFTicketBuilder()
			.setExternalId('2345678993')
			.setCompanyId('222222222222')
			.setSubject('route_to_taxres')
			.setEmail('test2@test.com')
			.setTicketType('support_form')
			.setAdditionalData(
				'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"","is_in_app_notice":"true","notice_type":"Missing or late payment","penalty_amount":"9,999,999,999,999,999,999,993,079.75","is_wallet_app":false}'
			)
			.setDIVR('SomeRandomString')
			.setTags('[]')
			.setReason('route_to_taxres')
			.build();

		List<GF_Ticket__c> list_GFTix = new List<GF_Ticket__c>();
		list_GFTix.add(objCaseWithPenaltyAmount);
		GFTicketTriggerHelper.blnQueue = true;
		CaseTriggerHelper.skipTrigger = true;
		insert list_GFTix;

		List<GF_Ticket__c> list_GFTicket = [SELECT Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c = '2345678993'];
		List<Case> list_Case = [
			SELECT Agency_Information__c, In_App_Notice__c, Penalty_Amount__c
			FROM Case
			WHERE Penalty_Amount__c != NULL AND In_App_Notice__c = TRUE AND RecordType.Name = 'Tax Res'
		];

		Test.stopTest();
		System.assert(list_Case.size() > 0, 'List size should be more than 0.');
		System.assert(list_GFTicket.size() > 0, 'List size should be more than 0.');
		System.assertEquals(list_GFTicket[0].Case_Id__c, list_Case[0].Id, 'Id should match.');
		System.assertEquals(Decimal.valueOf('9999999999999999.00'), list_Case[0].Penalty_Amount__c, 'Penalty_Amount__c should match.');
	}
}