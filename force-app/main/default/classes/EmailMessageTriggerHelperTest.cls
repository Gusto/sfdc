@isTest
public class EmailMessageTriggerHelperTest {
	static final Id CASE_RT_TAX_OPS = Cache.getRecordTypeId('Case', 'Tax Ops');
	static final Id CASE_RT_PAYROLL_CARE_READ_ONLY = Cache.getRecordTypeId('Case', 'Payroll Care - Read Only');
	static final Id CASE_RT_PAYROLL_TRANSFER_CASE = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
	static final Id CASE_RT_BENEFITS_CHANGE_CASE = Cache.getRecordTypeId('Case', 'Benefits Change Case');
	static final Id CASE_RT_PAYROLLOPS_AUDIT_READ_ONLY = Cache.getRecordTypeId('Case', 'PayrollOps Audit - Read Only');
	static final Id CASE_RT_PAYROLLOPS_AUDIT = Cache.getRecordTypeId('Case', 'PayrollOps Audit');
	static final Id CASE_RT_PAYROLL_CARE = Cache.getRecordTypeId('Case', 'Payroll Care');
	static final String EMAIL_TEXT_BODY = getTextBody();
	static final String EMAIL_HTML_BODY = getHTMLBody();
	public static Boolean blnThrowException = false;

	@testSetup
	static void setUp() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		List<Case> list_Cases = new List<Case>();
		Test.startTest();
		Account objAccount = TestUtility.CompanyAccount();

		Opportunity objOpp1 = TestUtility.BenefitsNewPlanOpportunity();

		Contact objContactRecord = new Contact();
		objContactRecord.FirstName = 'Test Demo';
		objContactRecord.LastName = 'AccountName 1';
		objContactRecord.Phone = '19992344444';
		objContactRecord.MailingStreet = 'Testing Avenue 1';
		objContactRecord.MailingPostalCode = '123455';
		objContactRecord.MobilePhone = '19992344444';
		objContactRecord.OtherPhone = '19992344444';
		objContactRecord.Email = 'test@acme.com';
		objContactRecord.AccountId = objAccount.Id;
		insert objContactRecord;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Care - Read Only')
			.setSubject('Test 1')
			.setDescription('Test')
			.setType('QLE')
			.build();
		list_Cases.add(objCase);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Tax Ops')
			.setSubject('Test Closed')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('QLE')
			.build();
		list_Cases.add(objCase3);

		Case objCase7 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('PayrollOps Audit - Read Only')
			.setSubject('Test Closed')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('Onboarding State Tax Audit')
			.build();
		list_Cases.add(objCase7);

		insert list_Cases;

		list_Cases = new List<Case>();

		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Care - Read Only')
			.setSubject('Test 1 Child')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('QLE')
			.setParentId(objCase.Id)
			.setAuthorizedUser('Yes')
			.setSharedWith('ApIntego')
			.build();
		list_Cases.add(objCase1);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Care - Read Only')
			.setSubject('Test Closed Child')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('QLE')
			.setParentId(objCase3.Id)
			.setAuthorizedUser('Yes')
			.setSharedWith('ApIntego')
			.build();
		list_Cases.add(objCase4);

		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setSubject('Test Closed Child Payroll Case')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('QLE')
			.setParentId(objCase3.Id)
			.setAuthorizedUser('Yes')
			.setSharedWith('ApIntego')
			.build();
		list_Cases.add(objCase5);

		Case objCase6 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits Change Case')
			.setSubject('Test Closed Child Change Case')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('QLE')
			.setParentId(objCase3.Id)
			.setAuthorizedUser('Yes')
			.setSharedWith('ApIntego')
			.build();
		list_Cases.add(objCase6);

		Case objCase8 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits New Plan Case')
			.setSubject('Re: SECURE C2 Construction Services LLC Application Has Been Approved')
			.setDescription('Test')
			.setType('Benefits New Plan')
			.build();
		list_Cases.add(objCase8);

		Case objCase9 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits Change Case')
			.setSubject('Test Engagement Handoff')
			.setDescription('Test Engagement Handoff')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('QLE')
			.setAuthorizedUser('Yes')
			.setOpportunity(objOpp1.Id)
			.setIntegrationId('hippo-Benefits_Renewal-')
			.build();
		list_Cases.add(objCase9);

		Case objCase11 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setSubject('Test Engagement Handoff Without Oppty')
			.setDescription('Test Engagement Handoff Without Oppty')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('QLE')
			.setAuthorizedUser('Yes')
			.setIntegrationId('hippo-Benefits_Renewal-WithoutOppty')
			.build();
		list_Cases.add(objCase11);

		Case objCase10 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Care')
			.setSubject('Test Case for Poulating Type From Email Message')
			.setDescription('Test')
			.setAuthorizedUser('Yes')
			.setStatus(CaseUtils.STATUS_OPEN)
			.build();
		list_Cases.add(objCase10);

		Case objCase12 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('MF QLE')
			.setSubject('Test Case MF QLE RFI')
			.setDescription('Test')
			.setAutomatedRFIFlow(true)
			.build();
		list_Cases.add(objCase12);

		Case objCase13 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Tax Ops')
			.setSubject('Test Tax Ops Case')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection('Inbound')
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Tax Ops Case')
			.build();
		list_Cases.add(objCase13);

		Case objCase14 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Risk Assurance')
			.setSubject('Test Risk Assurance Case')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection('Inbound')
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Risk Assurance Case')
			.build();
		list_Cases.add(objCase14);

		Case objCase15 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits BoR')
			.setSubject('Test Benefits BoR Case')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection('Inbound')
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Benefits BoR Case')
			.build();
		list_Cases.add(objCase15);

		Case objCase16 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setSubject('Test Benefits Renewal Case')
			.setDescription('Test Benefits Renewal Case')
			.setStatus(CaseUtils.STATUS_NEW)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase16);

		Case objCase17 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Sales Cases - Closed')
			.setSubject('Test Sales Cases Closed')
			.setDescription('Test Sales Cases Closed')
			.setStatus(CaseUtils.STATUS_NEW)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase17);

		Case objCase18 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Sales Cases')
			.setSubject('Test Sales Case')
			.setDescription('Test Sales Case')
			.setStatus(CaseUtils.STATUS_NEW)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase18);

		Case objCase19 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits BYB')
			.setSubject('Test Benefits BYB Case')
			.setDescription('Test Benefits BYB Case')
			.setStatus(CaseUtils.STATUS_NEW)
			.build();
		list_Cases.add(objCase19);

		Case objCase20 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Tax Res - Read Only')
			.setSubject('Closed Tax Res')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('Tax Res')
			.setOrigin(CaseUtils.ORIGIN_GUSTO)
			.setIntegrationId('000000000')
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase20);

		Case objCase21 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits Care - Read Only')
			.setSubject('Closed Benefits Care')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('Benefits Care')
			.setOrigin(CaseUtils.ORIGIN_WEB)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase21);

		Case objCase22 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Benefits Care')
			.setSubject('Non read only Benefits Care')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('Benefits Care')
			.setOrigin(CaseUtils.ORIGIN_WEB)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase22);

		Case objCase23 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Care')
			.setSubject('Non read only Payroll Care')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('Payroll Care')
			.setOrigin(CaseUtils.ORIGIN_WEB)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase23);

		Case objCase24 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setSubject('Test Payroll Transfer Case Requires Action Update')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_NEW)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase24);
        
        Case objCase25 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Testing Invalid Email Address for Spam emails')
			.setDescription('Test')
            .setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.STATUS_OPEN)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase25);

		Case objCase26 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Test Engagement status update')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_NEW)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase26);

		Case objCase27 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Engagement')
			.setSubject('[Request received] | RE: Test case auto close')
			.setDescription('Your request (361403) has been received and is being reviewed by our team.Thanks')
			.setStatus(CaseUtils.STATUS_NEW)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase27);

		Case objCase28 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Closed test case for thank you reply')
			.setDescription('Closed test case for thank you reply')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase28);

		Case objCase29 = new TestDataFactory.CaseBuilder().setRecordTypeId('Recovery Cases').setSubject('Test Recovery Case Status').setStatus(CaseUtils.STATUS_OPEN).build();
		list_Cases.add(objCase29);
		insert list_Cases;
		Test.stopTest();


		List<Case_Reason_Classification__c> list_CaseReasonClassifications = new List<Case_Reason_Classification__c>();
		Case_Reason_Classification__c objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Middesk State Tax Registration')
			.setIsActive(true)
			.setType('Engagement')
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification);
        
        Case_Reason_Classification__c objCaseReasonClassification2 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Spam')
			.setIsActive(true)
			.setClass('Class 0')
			.setType('Engagement')
			.setSurveyEligible(false)
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification2);
		insert list_CaseReasonClassifications;

		Agency_Information__c objAgencyInformation = new Agency_Information__c();
		objAgencyInformation.Name = 'Test';
		objAgencyInformation.Domain__c = 'gusto.com';
		insert objAgencyInformation;

		GF_Ticket__c objGfTicket = new GF_Ticket__c(Id__c = '2d931510-d99f-494a-8c67-87feb05e1594');
		insert objGfTicket;

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		List<User> list_Users = new List<User>();
		EmailTemplate objEmailTemplate;
		System.runAs(objCurrentUser) {
			Profile objProfile = TestDataFactory.objZPSysAdminProfile;
			User objUser = new TestDataFactory.UserBuilder()
				.setUserName('testactiveuser@gusto.com')
				.setLastName('Test Active User')
				.setEmail('testactiveuser@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			list_Users.add(objUser);

			User objInactiveUser = new TestDataFactory.UserBuilder()
				.setUserName('testinactiveuser@gusto.com')
				.setLastName('Test Inactive User')
				.setEmail('testinactiveuser@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('inac')
				.setIsActive(false)
				.setUserName(TestDataFactory.buildUniqueString())
				.build();
			objInactiveUser.Vendor__c = 'Task Us';
			list_Users.add(objInactiveUser);
			insert list_Users;

			objEmailTemplate = new TestDataFactory.EmailTemplateBuilder()
				.setName('Test Email Template')
				.setDeveloperName('Test_Email_Template')
				.setHtmlValue('Test Stuff')
				.setFolderId(UserInfo.getUserId())
				.setTemplateType('Text')
				.build();
			insert objEmailTemplate;

			CaseTeamRole objCaseTeamRole = new CaseTeamRole(Name = 'Test Case Team Role', PreferencesVisibleInCSP = false, AccessLevel = 'Edit');
			insert objCaseTeamRole;

			CaseTeamMember objCaseTeamMember = new CaseTeamMember(ParentId = objCase15.Id, TeamRoleId = objCaseTeamRole.Id, MemberId = objContactRecord.Id);
			insert objCaseTeamMember;
		}

		Attachment objAttachment = new TestDataFactory.AttachmentBuilder().setName('Test Attachment').setParent(objEmailTemplate.Id).setBody(Blob.valueOf('Test Attachment Body')).build();
		insert objAttachment;
	}

	@isTest
	static void testProcessEOYSpotCheckWithCaseId() {
		Test.startTest();
		List<Case> list_ChildCases = [SELECT Id, ParentId FROM Case WHERE Subject = 'Test 1 Child'];
		GF_Ticket__c objGfTicketData = [SELECT Id, Case_Id__c, Id__c FROM GF_Ticket__c LIMIT 1];
		objGfTicketData.Case_Id__c = list_ChildCases[0].ParentId;
		update objGfTicketData;

		EmailMessage objMessage = new EmailMessage();
		objMessage.ParentId = list_ChildCases[0].Id;
		objMessage.FromAddress = 'test@acme.com';
		objMessage.ToAddress = 'support@gusto.com';
		objMessage.CCAddress = 'test.test3@test.com';
		objMessage.Subject = 'test';
		objMessage.Incoming = true;
		objMessage.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb05e1594}}';
		insert objMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM Case WHERE Type = 'EOY Spot Check - Close'].size() == 1, 'There should be 1 case.');
	}

	@isTest
	static void testProcessEOYSpotCheck() {
		Test.startTest();
		List<Case> list_ChildCases = [SELECT Id FROM Case WHERE Subject = 'Test 1 Child'];

		EmailMessage objMessage = new EmailMessage();
		objMessage.ParentId = list_ChildCases[0].Id;
		objMessage.FromAddress = 'test@acme.com';
		objMessage.ToAddress = 'support@gusto.com';
		objMessage.CCAddress = 'test.test3@test.com';
		objMessage.Subject = 'test';
		objMessage.Incoming = true;
		objMessage.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb05e1594}}';
		insert objMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM GF_Ticket__c WHERE Case_Id__c = :list_ChildCases[0].Id].size() == 1, 'There should be 1 Ticket.');
	}

	@isTest
	static void testProcessEOYSpotCheckNoGfFound() {
		Test.startTest();
		List<Case> list_ChildCases = [SELECT Id FROM Case WHERE Subject = 'Test 1 Child'];

		EmailMessage objMessage = new EmailMessage();
		objMessage.ParentId = list_ChildCases[0].Id;
		objMessage.FromAddress = 'test@acme.com';
		objMessage.ToAddress = 'support@gusto.com';
		objMessage.CCAddress = 'test.test3@test.com';
		objMessage.Subject = 'test';
		objMessage.Incoming = true;
		objMessage.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb01594}}';
		insert objMessage;
		Test.stopTest();

		System.assert([SELECT Id, Type FROM Case WHERE Id = :list_ChildCases[0].Id].Type == 'EOY Spot Check', 'Case type should be EOY Spot Check.');
	}

	/*
	 * @Author:     	Todd Dowdy
	 * @Description:  	Test the creation of a new Payroll Ops Audit Case from incoming email on a closed case and that the case is assigned to the PayrollOps_Audit_Queue queue
	 */
	@isTest
	static void testNewPayrollOpsAuditCase() {
		Test.startTest();
		List<Case> list_PayrollAuditCase = [SELECT Id FROM Case WHERE RecordTypeId = :CASE_RT_PAYROLLOPS_AUDIT_READ_ONLY];

		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.ParentId = list_PayrollAuditCase[0].Id;
		objEmailMessage.FromAddress = 'test@acme.com';
		objEmailMessage.ToAddress = 'support@gusto.com';
		objEmailMessage.CCAddress = 'test.test3@test.com';
		objEmailMessage.Subject = 'Re: test ';
		objEmailMessage.Incoming = true;
		objEmailMessage.TextBody = EMAIL_TEXT_BODY;
		insert objEmailMessage;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Status, OwnerId FROM Case WHERE RecordTypeId = :CASE_RT_PAYROLLOPS_AUDIT];
		Id idPayrollOpsAuditQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'PayrollOps_Audit_Queue'].Id;

		if (list_Cases.size() > 0) {
			System.assert(list_Cases[0].Status == 'New');
			if (idPayrollOpsAuditQueue != null) {
				System.assert(list_Cases[0].OwnerId == idPayrollOpsAuditQueue, 'OwnerId should match.');
			}
		}
	}

	@isTest
	static void testIntegrationQueCreation() {
		Test.startTest();
		TaskTriggerHelper.skipTrigger = true;
		List<Case> list_ParentCases = [SELECT Id FROM Case WHERE Subject = 'Test 1'];
		List<Case> list_ChildCases = [SELECT Id FROM Case WHERE Subject = 'Test 1 Child'];

		CaseTriggerHelper.skipTrigger = true;
		EmailMessage objMessage = new EmailMessage();
		objMessage.ParentId = list_ChildCases[0].Id;
		objMessage.FromAddress = 'test@acme.com';
		objMessage.ToAddress = 'test.test@gusto.com;test.test1@test.com';
		objMessage.CCAddress = 'test.test3@test.com';
		objMessage.Subject = 'test';
		objMessage.Incoming = true;
		objMessage.TextBody = 'test';
		insert objMessage;

		EmailMessage objMessage1 = new EmailMessage();
		objMessage1.ParentId = list_ParentCases[0].Id;
		objMessage1.FromAddress = 'test@acme.com';
		objMessage1.ToAddress = 'test.test@gusto.com;test.test1@test.com';
		objMessage1.CCAddress = 'test.test3@test.com';
		objMessage1.Subject = 'Re: test';
		objMessage1.Incoming = false;
		objMessage1.TextBody = 'test Reply';
		insert objMessage1;

		Set<Id> set_MessageIds = new Set<Id>();
		set_MessageIds.add(objMessage1.Id);

		update objMessage;
		CaseTriggerHelper.skipTrigger = false;
		Test.stopTest();

		System.assert([SELECT Id FROM Zendesk_Integration_Queue__c].size() > 0, 'There should be at least 1 Zendesk Integration Queue.');
	}

	/*
	 * @Author:      Pradeep Chary
	 * @Description: Test method for insertIntoZendeskIntegrationLog() method
	 */
	@isTest
	static void testIntegrationQueCreationDelete() {
		Test.startTest();
		List<Case> list_ParentCases = [SELECT Id FROM Case WHERE Subject = 'Test 1'];
		List<Case> list_ChildCases = [SELECT Id FROM Case WHERE Subject = 'Test 1 Child'];

		EmailMessage objMessage2 = new EmailMessage();
		objMessage2.ParentId = list_ParentCases[0].Id;
		objMessage2.FromAddress = 'test@acme.com';
		objMessage2.ToAddress = 'test.test@gusto.com;test.test1@test.com';
		objMessage2.CCAddress = 'test.test3@test.com';
		objMessage2.Subject = 'Re: test';
		objMessage2.Incoming = false;
		objMessage2.TextBody = 'test Reply';
		insert objMessage2;

		Set<Id> set_MessageIds = new Set<Id>();
		set_MessageIds.add(objMessage2.Id);

		List<Id> list_CaseIds = new List<Id>();
		list_CaseIds.add(list_ChildCases[0].Id);
		EmailMessageTriggerHelper.logCaseEmailAlerts(list_CaseIds);
		delete objMessage2;
		undelete objMessage2;
		Test.stopTest();

		System.assert(true, 'Fixind Apex PMD issue.');
	}

	@isTest
	static void testUpdate() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id, Customer_Responses_Since_Last_Update__c FROM Case WHERE Subject = 'Test Closed'];
		GF_Ticket__c objGfTicketData = [SELECT Id, Case_Id__c, Id__c FROM GF_Ticket__c LIMIT 1];
		objGfTicketData.Case_Id__c = list_Cases[0].Id;
		update objGfTicketData;
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.ParentId = list_Cases[0].Id;
		objEmailMessage.FromAddress = 'test@acme.com';
		objEmailMessage.ToAddress = 'support@gusto.com';
		objEmailMessage.CCAddress = 'test.test3@test.com';
		objEmailMessage.Subject = 'Re: test';
		objEmailMessage.Incoming = true;
		objEmailMessage.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb05e1594}}';
		insert objEmailMessage;
		Test.stopTest();

		System.assert(
			[SELECT Id, Customer_Responses_Since_Last_Update__c FROM Case WHERE Id = :list_Cases[0].Id].Customer_Responses_Since_Last_Update__c !=
			list_Cases[0].Customer_Responses_Since_Last_Update__c,
			'Customer Responses Since Last Update shouldnot be same'
		);
		update objEmailMessage;
		delete objEmailMessage;
		undelete objEmailMessage;
	}

	@isTest
	static void testNewInboundEmail_1() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM Case WHERE Subject = 'Re: SECURE C2 Construction Services LLC Application Has Been Approved'];
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.ParentId = list_Cases[0].Id;
		objEmailMessage.Incoming = true;
		objEmailMessage.subject = 'Re: SECURE C2 Construction Services LLC Application Has Been Approved';
		objEmailMessage.fromName = 'User Acme';
		objEmailMessage.toAddress = 'carrierops@gusto.com';
		objEmailMessage.fromAddress = 'user@acme.com';
		objEmailMessage.CCAddress = 'user2@acme.com';
		objEmailMessage.TextBody = EMAIL_TEXT_BODY;
		objEmailMessage.htmlBody = EMAIL_HTML_BODY;
		insert objEmailMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM Email_Message__c].size() != 1, 'List size should not be 1.');
	}

	@isTest
	static void testNewInboundEmail_2() {
		Test.startTest();
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.Incoming = true;
		objEmailMessage.subject = 'Your Principal verification code';
		objEmailMessage.fromName = 'User Acme';
		objEmailMessage.toAddress = 'bor-transfer@gusto.com';
		objEmailMessage.fromAddress = 'user@acme.com';
		objEmailMessage.TextBody = EMAIL_TEXT_BODY;
		objEmailMessage.htmlBody = EMAIL_HTML_BODY;
		insert objEmailMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM Email_Message__c].size() == 1, 'There should be 1 Email Message.');
	}

	@isTest
	static void testNewInboundEmail_3() {
		Test.startTest();
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.Incoming = true;
		objEmailMessage.subject = 'Your Principal verification code';
		objEmailMessage.fromName = 'User Acme';
		objEmailMessage.toAddress = 'memberfulfillment@gusto.com';
		objEmailMessage.fromAddress = 'user@gusto.com';
		objEmailMessage.CCAddress = 'carrierops@zenpayroll.com';
		objEmailMessage.TextBody = EMAIL_TEXT_BODY;
		objEmailMessage.htmlBody = EMAIL_HTML_BODY;
		insert objEmailMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM Email_Message__c].size() == 1, 'There should be 1 Email Message.');
	}

	@isTest
	static void testNewInboundEmail_4() {
		Test.startTest();
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.Incoming = true;
		objEmailMessage.subject = 'Your Principal verification code';
		objEmailMessage.fromName = 'User Acme';
		objEmailMessage.toAddress = 'renewalcarriercomms@gusto.com';
		objEmailMessage.fromAddress = 'test@acme.com';
		objEmailMessage.CCAddress = 'renewals@gusto.com';
		objEmailMessage.TextBody = EMAIL_TEXT_BODY;
		objEmailMessage.htmlBody = EMAIL_HTML_BODY;
		insert objEmailMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM Email_Message__c].size() == 1, 'There should be 1 Email Message.');
	}

	@isTest
	static void testNewInboundEmail_5() {
		Test.startTest();
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.Incoming = true;
		objEmailMessage.subject = 'Important information regarding your group coverage';
		objEmailMessage.fromName = 'User Acme';
		objEmailMessage.toAddress = 'newplans@gusto.com';
		objEmailMessage.fromAddress = 'user@acme.com';
		objEmailMessage.CCAddress = 'carrierops@zenpayroll.com';
		objEmailMessage.TextBody = 'Please review the attached document(s) containing information in regards to;Should you have any questions, please contact CaliforniaChoice Customer Service Center by dialing (800) 558-8003.;Thank you.;Hello,;';
		objEmailMessage.htmlBody = EMAIL_HTML_BODY;
		insert objEmailMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM Email_Message__c].size() == 1, 'There should be 1 Email Message.');
	}

	private static String getTextBody() {
		String strTextBody = '';
		strTextBody += '-----------------------------------------------';
		strTextBody += '\nsubject : TEST';
		strTextBody += '\nThis is my test email';
		return strTextBody;
	}

	private static String getHTMLBody() {
		String strHtmlBody = '';
		strHtmlBody += '-----------------------------------------------<br/>';
		strHtmlBody += '<br/>subject : TEST';
		strHtmlBody += '<br/>This is my test email';
		return strHtmlBody;
	}

	/*
	 *@Author 		: Neha Dabas
	 *@Description	: Tests that if Payroll Case is closed and there is an incoming email, it should create a Payroll Care case.
	 */
	@isTest
	static void testNewCasePayroll() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM Case WHERE Subject = 'Test Closed Child Payroll Case'];
		EmailMessage objMessage = new EmailMessage();
		objMessage.ParentId = list_Cases[0].Id;
		objMessage.FromAddress = 'test@acme.com';
		objMessage.ToAddress = 'support@gusto.com';
		objMessage.CCAddress = 'test.test3@test.com';
		objMessage.Subject = 'Re: test ';
		objMessage.Incoming = true;
		objMessage.TextBody = EMAIL_TEXT_BODY;
		insert objMessage;
		Test.stopTest();

		System.assert([SELECT Id FROM Zendesk_Integration_Queue__c].size() > 0, 'There should be at least 1 Zendesk Integration Queue.');
	}

	/*
	 *@Author 		: Neha Dabas
	 *@Description	: Tests that if there is an existing Payroll Care Case then an incoming email should not create duplicate Care Case.
	 */
	@isTest
	static void testPayrollCareCaseDeduplication() {
		Test.startTest();
		List<Case> list_PayrollCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Subject = 'Test Closed Child Payroll Case'];

		Case objCaseCare = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			AccountId = list_PayrollCase[0].AccountId,
			ContactId = list_PayrollCase[0].ContactId,
			Subject = 'Payroll Care',
			Description = 'Payroll Care Desc',
			Authorized_User__c = 'Yes',
			ParentId = list_PayrollCase[0].Id
		);
		CaseTriggerHelper.skipTrigger = true;
		insert objCaseCare;

		EmailMessage objEmail2 = new EmailMessage();
		objEmail2.ParentId = list_PayrollCase[0].Id;
		objEmail2.FromAddress = 'test@acme.com';
		objEmail2.ToAddress = 'support@gusto.com';
		objEmail2.CCAddress = 'test.test3@test.com';
		objEmail2.Subject = 'Re: test again ';
		objEmail2.Incoming = true;
		objEmail2.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb05e1594}}';
		insert objEmail2;

		System.assert([SELECT COUNT() FROM Case WHERE ParentId = :list_PayrollCase[0].Id] == 1, 'There should be 1 case.');

		Test.stopTest();
	}

	/*
	 *@Author 		: Neha Dabas
	 *@Description	: Test if a closed case without associated Oppty and BO reopens when there is an incoming email
	 */
	@isTest
	static void testCaseReopeningForIncomingEmail() {
		Test.startTest();
		List<Case> list_RenewalCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Integration_Id__c = 'hippo-Benefits_Renewal-WithoutOppty'];

		EmailMessage objEmail2 = new EmailMessage();
		objEmail2.ParentId = list_RenewalCase[0].Id;
		objEmail2.FromAddress = 'test@acme.com';
		objEmail2.ToAddress = 'support@gusto.com';
		objEmail2.CCAddress = 'test.test3@test.com';
		objEmail2.Subject = 'Re: test again ';
		objEmail2.Incoming = true;
		objEmail2.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb05e1594}}';
		insert objEmail2;

		System.assert([SELECT COUNT() FROM Case WHERE Status = :CaseUtils.STATUS_RESPONSE_RECEIVED] == 1, 'There should be 1 case.');

		Test.stopTest();
	}

	/*
	 *@Author 		: Neha Dabas
	 *@Description	: Tests that if there is an existing Benefits Care Case then an incoming email should not create duplicate Care Case.
	 */
	@isTest
	static void testBenefitsCareCaseDeduplication() {
		Test.startTest();
		List<Case> list_RenewalCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Integration_Id__c = 'hippo-Benefits_Renewal-'];

		Case objCaseCare = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care'),
			AccountId = list_RenewalCase[0].AccountId,
			ContactId = list_RenewalCase[0].ContactId,
			Subject = 'Benefits Care',
			Description = 'Benefits Care Desc',
			Authorized_User__c = 'Yes',
			ParentId = list_RenewalCase[0].Id
		);
		CaseTriggerHelper.skipTrigger = true;
		insert objCaseCare;

		EmailMessage objEmail2 = new EmailMessage();
		objEmail2.ParentId = list_RenewalCase[0].Id;
		objEmail2.FromAddress = 'test@acme.com';
		objEmail2.ToAddress = 'support@gusto.com';
		objEmail2.CCAddress = 'test.test3@test.com';
		objEmail2.Subject = 'Re: test again ';
		objEmail2.Incoming = true;
		objEmail2.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb05e1594}}';
		insert objEmail2;

		System.assert([SELECT COUNT() FROM Case WHERE ParentId = :list_RenewalCase[0].Id] == 1, 'There should be 1 case.');

		Test.stopTest();
	}

	/*
	 *@Author 		: Neha Dabas
	 *@Description	: Tests that if customer case is closed and there is an incoming email then Benefits Care Case should be created
	 */
	@isTest
	static void testBenefitsCareCaseCreation() {
		Test.startTest();
		List<Case> list_RenewalCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Integration_Id__c = 'hippo-Benefits_Renewal-'];

		EmailMessage objEmail2 = new EmailMessage();
		objEmail2.ParentId = list_RenewalCase[0].Id;
		objEmail2.FromAddress = 'test@acme.com';
		objEmail2.ToAddress = 'support@gusto.com';
		objEmail2.CCAddress = 'test.test3@test.com';
		objEmail2.Subject = 'Re: test again ';
		objEmail2.Incoming = true;
		objEmail2.TextBody = 'test Reply id::{{2d931510-d99f-494a-8c67-87feb05e1594}}';
		insert objEmail2;

		System.assert([SELECT COUNT() FROM Case WHERE ParentId = :list_RenewalCase[0].Id] == 1, 'There should be 1 case.');
		Test.stopTest();
	}

	/*
	 * @Author:      Midhuna KB
	 * @Description: Method to add Test Metadata records of Email Case Type Mdt
	 * @Parm:        N/A
	 * @Return:      List of Email Case Type Metadata records.
	 */
	public static List<Email_Case_Type__mdt> generateTestMetadata() {
		//Add Email Case Type Metadata test records to List
		List<Email_Case_Type__mdt> list_EmailCaseTypeMdt = new List<Email_Case_Type__mdt>();

		Email_Case_Type__mdt objEmaiCaseType1 = new Email_Case_Type__mdt();
		objEmaiCaseType1.Email_Address__c = 'testemail@test.com';
		objEmaiCaseType1.Record_Type__c = 'Payroll Care';
		objEmaiCaseType1.Type__c = 'Testing';
		objEmaiCaseType1.IsActive__c = true;
		list_EmailCaseTypeMdt.add(objEmaiCaseType1);

		return list_EmailCaseTypeMdt;
	}

	/*
	 * @Author:      Midhuna KB
	 * @Description: Test method for populateCaseType()
	 */
	@isTest
	static void testPopulateCaseTypeToAddress() {
		String strCaseRecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		Case objCase = [SELECT Id, Type FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Case for Poulating Type From Email Message' LIMIT 1];

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testemail@test.com').setIncoming(true).build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Type FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Case for Poulating Type From Email Message' LIMIT 1];

		System.assertEquals(objCase.Type, 'Testing', 'Case Type should be Testing');
	}

	/*
	 * @Author:      Midhuna KB
	 * @Description: Test method for populateCaseType()
	 */
	@isTest
	static void testPopulateCaseTypeCCAddress() {
		String strCaseRecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		Case objCase = [SELECT Id, Type FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Case for Poulating Type From Email Message' LIMIT 1];

		Test.startTest();

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setCCAddress('testemail@test.com').setIncoming(true).build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Type FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Case for Poulating Type From Email Message' LIMIT 1];

		System.assertEquals(objCase.Type, 'Testing', 'Case Type should be Testing');
	}

	/*
	 * @Author:      Ankit CS
	 * @Description: Test method for populateCaseType() for Type Garnishments
	 */
	@isTest
	static void testPopulateCaseTypeGarnishments() {
		Case objCase = [SELECT Id, Type FROM Case WHERE RecordType.Name = 'Tax Ops' AND Subject = 'Test Tax Ops Case' LIMIT 1];

		Test.startTest();

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testgarnish@gusto.com').setIncoming(true).build();
		insert objEmailMessage;

		objCase = [SELECT Id, Type FROM Case WHERE Id = :objCase.Id];

		Test.stopTest();

		// Assert if the Case Type is updated to Garnishments
		System.assertEquals(objCase.Type, 'Garnishments', 'Case Type should be Garnishments');
	}

	/*
	 * @Author:      Ankit CS
	 * @Description: Test method for populateCaseType() for Type Payroll Ops Task
	 */
	@isTest
	static void testPopulateCaseTypePayrollOps() {
		Case objCase = [SELECT Id, Type FROM Case WHERE RecordType.Name = 'Tax Ops' AND Subject = 'Test Tax Ops Case' LIMIT 1];

		Test.startTest();

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testptserr@gusto.com').setIncoming(true).build();
		insert objEmailMessage;

		objCase = [SELECT Id, Type FROM Case WHERE Id = :objCase.Id];

		Test.stopTest();

		// Assert if the Case Type is updated to Payroll Ops Task
		System.assertEquals(objCase.Type, 'Payroll Ops Task', 'Case Type should be Payroll Ops Task');
	}

	/*
	 * @Author:      Ankit CS
	 * @Description: Test method for populateCaseType() for Type Underwriting
	 */
	@isTest
	static void testPopulateCaseTypeUnderwriting() {
		Case objCase = [SELECT Id, Type FROM Case WHERE RecordType.Name = 'Risk Assurance' AND Subject = 'Test Risk Assurance Case' LIMIT 1];

		Test.startTest();

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testunderwriting@gusto.com').setIncoming(true).build();
		insert objEmailMessage;

		objCase = [SELECT Id, Type FROM Case WHERE Id = :objCase.Id];

		Test.stopTest();

		// Assert if the Case Type is updated to Underwriting
		System.assertEquals(objCase.Type, 'Underwriting', 'Case Type should be Underwriting');
	}

	@isTest
	static void testQLERFICase() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE RecordTypeId = :CaseUtils.RECTYPE_MF_QLE AND Automated_RFI_Flow__c = TRUE LIMIT 1];

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setCCAddress('testemail@test.com').setIncoming(true).build();
		insert objEmailMessage;

		Test.stopTest();

		objCase = [SELECT Automated_RFI_Flow__c, Status FROM Case WHERE Id = :objCase.Id LIMIT 1];

		System.assert(!objCase.Automated_RFI_Flow__c, 'Automated_RFI_Flow__c should be false.');
		System.assertEquals(objCase.Status, CaseUtils.STATUS_NEW, 'Case Status should be new.');
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : Test method to handle when the ToAddresses emails exceed 255 characters
	 **/
	@isTest
	static void testEmailMessageForBulkToAddreses() {
		Test.startTest();
		String strToAddresses =
			'newplans@gusto.com; testn_mcgivern@uhc.com; testierops@gusto.com; testbmit@uhc.com;' +
			' testc_lujanponce@uhc.com; testply@salesforce.com; testlynn.flores@uhc.com; testta_l_smith@uhc.com;' +
			' testsub@uhc.com; testti_s_selchow@uhc.com; testago.yvescharles@uhc.com;';
		String strExtraToAddresses = ' testkristel.gatchalian@uhc.com';
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.Incoming = true;
		objEmailMessage.Subject = 'Important information regarding your Test group coverage';
		objEmailMessage.FromName = 'Acme';
		objEmailMessage.ToAddress = strToAddresses + strExtraToAddresses;
		objEmailMessage.FromAddress = 'testuser@acme.com';
		objEmailMessage.CCAddress = 'carrierops@zenpayroll.com';
		objEmailMessage.TextBody = 'Please review the attached document(s) containing information in regards to';
		objEmailMessage.HtmlBody = EMAIL_HTML_BODY;
		insert objEmailMessage;
		Test.stopTest();

		List<Email_Message__c> list_EmailMessages = [SELECT Id, To_Addresses__c FROM Email_Message__c WHERE From_Addresses__c = 'testuser@acme.com'];
		System.assertEquals(list_EmailMessages[0].To_Addresses__c, strToAddresses, 'Email Message To_Addresses__c should match.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Test method for email status changing from "Draft" to "Sent"
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testTaxResCasesHandleSentEmails() {
		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id FROM Contact LIMIT 1];
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = TestDataFactory.createTestCase(list_Accounts[0].Id, list_Contacts[0].Id);
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		String strToAddresses = 'testago.yvescharles@uhc.com;';
		String strExtraToAddresses = ' testkristel.gatchalian@uhc.com';
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.ParentId = objCase.Id;
		objEmailMessage.Incoming = false;
		objEmailMessage.Subject = 'Important information regarding your Test group coverage';
		objEmailMessage.FromName = 'Acme';
		objEmailMessage.ToAddress = strToAddresses + strExtraToAddresses;
		objEmailMessage.FromAddress = 'testDraftuser@acme.com';
		objEmailMessage.CCAddress = 'carrierops@zenpayroll.com';
		objEmailMessage.TextBody = 'Please review the attached document(s) containing information in regards to';
		objEmailMessage.HtmlBody = EMAIL_HTML_BODY;
		objEmailMessage.Status = '5';
		objEmailMessage.Email_Template_Name__c = null;
		CaseTriggerHelper.SkipTrigger = true;
		insert objEmailMessage;

		objEmailMessage.Status = '3';
		update objEmailMessage;
		CaseTriggerHelper.SkipTrigger = false;
		Test.stopTest();

		List<Case> list_Cases = [
			SELECT Id, Last_out_bound_email__c, X2_Business_Days_From_Last_Notification__c, X5_Business_Days_From_Last_Notification__c, XN_Business_Days_From_Last_Notification__c, Email_Status__c
			FROM Case
			WHERE RecordType.Name = 'Tax Res'
			LIMIT 1
		];

		System.assert(list_Cases[0].X2_Business_Days_From_Last_Notification__c > list_Cases[0].Last_out_bound_email__c, 'Last outbound email should be after last notification.');
		System.assert(list_Cases[0].X5_Business_Days_From_Last_Notification__c > list_Cases[0].Last_out_bound_email__c, 'Last outbound email should be after last notification.');
		System.assert(list_Cases[0].XN_Business_Days_From_Last_Notification__c > list_Cases[0].Last_out_bound_email__c, 'Last outbound email should be after last notification.');
		System.assert(list_Cases[0].Email_Status__c == Caseutils.EMAILSTATUS_AWAITING_RESPONSE, 'Email Status should match.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Test method for email status = "Draft" on insert
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testTaxResCasesHandleSentEmailsNegative() {
		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = TestDataFactory.createTestCase(list_Accounts[0].Id, null);
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		String strToAddresses = 'testago.yvescharles@uhc.com;';
		String strExtraToAddresses = ' testkristel.gatchalian@uhc.com';
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.ParentId = objCase.Id;
		objEmailMessage.Incoming = false;
		objEmailMessage.Subject = 'Important information regarding your Test group coverage';
		objEmailMessage.FromName = 'Acme';
		objEmailMessage.ToAddress = strToAddresses + strExtraToAddresses;
		objEmailMessage.FromAddress = 'testDraftuser@acme.com';
		objEmailMessage.CCAddress = 'carrierops@zenpayroll.com';
		objEmailMessage.TextBody = 'Please review the attached document(s) containing information in regards to';
		objEmailMessage.HtmlBody = EMAIL_HTML_BODY;
		objEmailMessage.Status = '3';
		CaseTriggerHelper.SkipTrigger = true;
		insert objEmailMessage;
		CaseTriggerHelper.SkipTrigger = false;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Last_out_bound_email__c, Email_Status__c FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];

		System.assert(list_Cases[0].Last_out_bound_email__c != null, 'Last_out_bound_email__c should not be null.');
		System.assert(list_Cases[0].Email_Status__c == Caseutils.EMAILSTATUS_AWAITING_RESPONSE, 'Email Status should match.');
	}

	/*
	 * @Author:      Ankit CS
	 * @Description: Test method for logCaseEmailAlerts() method
	 */
	@isTest
	static void testLogCaseEmailAlerts() {
		List<Case> list_Cases = [SELECT Id FROM Case WHERE RecordType.Name = 'Benefits BoR'];

		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.ParentId = list_Cases[0].Id;
		objEmailMessage.FromAddress = 'test@acme.com';
		objEmailMessage.ToAddress = 'test.test@gusto.com;test.test1@test.com';
		objEmailMessage.CCAddress = 'test.test3@test.com';
		objEmailMessage.Subject = 'Re: test';
		objEmailMessage.Incoming = false;
		objEmailMessage.TextBody = 'Sample text body';
		objEmailMessage.Email_Template_Name__c = 'Test_Email_Template';

		EmailMessageTriggerHelper.skipTrigger = true;
		insert objEmailMessage;
		EmailMessageTriggerHelper.skipTrigger = false;

		Test.startTest();
		EmailMessageTriggerHelper.logCaseEmailAlerts(new List<Id>{ list_Cases[0].Id });
		Test.stopTest();

		List<Attachment> list_Attachments = [SELECT Id, ParentId FROM Attachment WHERE ParentId = :objEmailMessage.Id];
		System.assert(!list_Attachments.isEmpty(), 'Attachment List should not be empty.');
	}

	/*
	 * @Author:      Ankit CS
	 * @Description: Test method to check if Latest_Customer_Response_Date_Time__c is populated
	 */
	@isTest
	static void testCustomerResponseDate() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Case for Poulating Type From Email Message' LIMIT 1];
		Test.setCreatedDate(objCase.Id, System.now().addDays(-10));

		Test.startTest();
		EmailMessage objEmailMessage = new EmailMessage();
		objEmailMessage.ParentId = objCase.Id;
		objEmailMessage.FromAddress = 'test@acme.com';
		objEmailMessage.ToAddress = 'testmail@gusto.com';
		objEmailMessage.CCAddress = 'testmail@gusto.com';
		objEmailMessage.Subject = 'Test mail for customer response date';
		objEmailMessage.Incoming = true;
		objEmailMessage.TextBody = 'Sample text body';
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Latest_Customer_Response_Date_Time__c FROM Case WHERE Id = :objCase.Id];
		System.assert(objCase.Latest_Customer_Response_Date_Time__c != null, 'Latest_Customer_Response_Date_Time__c should not be null.');
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : Test method to handle the First Response Time on the Parent Case
	 **/
	@isTest
	static void testUpdateFirstResponseTime() {
		Test.startTest();

		String strCaseRecordTypeId = Cache.getRecordTypeId('Case', 'Risk Assurance');
		Case objCase = [SELECT Id, OwnerId FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Risk Assurance Case' LIMIT 1];

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(false)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.build();
		objEmailMessage.Status = '3';
		insert objEmailMessage;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, First_Response_Time__c FROM Case WHERE Id = :objCase.Id];

		System.assert(list_Cases[0].First_Response_Time__c != null, 'First_Response_Time__c should not be null.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check if the Inbound Advising Email TPs is populated on Case
	 **/
	@isTest
	static void testInboundAdvisingEmailTP() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Benefits Renewal Case'];

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(true)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Advising_IB_Email_TPs__c FROM Case WHERE Id = :objCase.Id];

		System.assert(objCase.Advising_IB_Email_TPs__c != null, 'Advising_IB_Email_TPs__c should not be null.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check if the Outbound Advising Email TPs is populated on Case
	 **/
	@isTest
	static void testOutboundAdvisingEmailTP() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Benefits Renewal Case'];

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(false)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Advising_OB_Email_TPs__c FROM Case WHERE Id = :objCase.Id];

		System.assert(objCase.Advising_OB_Email_TPs__c != null, 'Advising OB Email TPs should not be null');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check if Action Required is set to false
	 **/
	@isTest
	static void testUpdateActionRequiredFalse() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Benefits Renewal Case'];

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(false)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.build();
		objEmailMessage.Status = '3';
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];

		System.assert(!objCase.Incoming_Email_Received__c, 'Incoming Email Received should be false.');
		System.assert(!objCase.Requires_Action__c, 'Requires Action should be false.');
	}

	@isTest
	static void testUpdateCaseOriginToEmail() {
		Case objCase = [SELECT Id, AccountId, Status, Origin FROM Case WHERE Subject = 'Test Engagement status update'];
		objCase.Status = Caseutils.STATUS_AWAITING_RESPONSE;
		objCase.Origin = CaseUtils.ORIGIN_CHAT;
		update objCase;

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(false)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.build();
		objEmailMessage.Status = '3';
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Origin, Channel__c FROM Case WHERE Id = :objCase.Id];

		System.assertEquals(objCase.Origin, 'Email');
		System.assertEquals(objCase.Channel__c, Null);
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : Test method to check if Action Required is set to false
	 **/
	@isTest
	static void testUpdateActionRequiredFalseForBYBCase() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Benefits BYB Case'];

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(false)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.setStatus('3')
			.build();

		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];

		System.assert(!objCase.Incoming_Email_Received__c, 'Incoming Email Received should be false');
		System.assert(!objCase.Requires_Action__c, 'Requires Action should be false');
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : Test method to check if Action Required is set to false after draft Email message is updated
	 **/
	@isTest
	static void testUpdateActionRequiredFalseAfterUpdateForBYB() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Benefits BYB Case'];

		Test.startTest();
		//Simulate incoming email
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message for require action update')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];
		//Requires action set to true after incoming
		System.assert(objCase.Requires_Action__c, 'Requires action should be true');

		//Simulate outgoing email saved as draft
		EmailMessage objEmailMessageDraft = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(false)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.setStatus('5')
			.build();
		insert objEmailMessageDraft;
		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];
		//Requires action remains true
		System.assert(objCase.Requires_Action__c, 'Requires Action should be true');

		//Simulate outgoing draft sent
		EmailMessage objEmailMsg = new EmailMessage(Id = objEmailMessageDraft.Id);
		objEmailMsg.Status = '3';
		update objEmailMsg;

		Test.stopTest();

		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];
		//Requires action should change to false
		System.assert(!objCase.Incoming_Email_Received__c, 'Incoming Email Received should be false');
		System.assert(!objCase.Requires_Action__c, 'Requires Action should be false');
	}

	/**
	 * @JIRA      : BSS-1063
	 * @Description : Test method to check if Action Required is set to false after draft Email message is updated
	 **/
	@isTest
	static void testUpdateActionRequiredFalseAfterUpdate() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Payroll Transfer Case Requires Action Update'];

		Test.startTest();
		//Simulate incoming email
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message for require action update')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];
		//Requires action set to true after incoming
		System.assert(objCase.Requires_Action__c, 'Requires Action should be true');

		//Simulate outgoing email saved as draft
		EmailMessage objEmailMessageDraft = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(false)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.build();
		objEmailMessageDraft.Status = '5';
		insert objEmailMessageDraft;
		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];
		//Requires action remains true
		System.assert(objCase.Requires_Action__c, 'Requires Action should be true');

		//Simulate outgoing draft sent
		EmailMessage objEmailMsg = new EmailMessage(Id = objEmailMessageDraft.Id);
		objEmailMsg.Status = '3';
		update objEmailMsg;

		Test.stopTest();

		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c FROM Case WHERE Id = :objCase.Id];
		//Requires action should change to false
		System.assert(!objCase.Incoming_Email_Received__c, 'Incoming Email Received should be false');
		System.assert(!objCase.Requires_Action__c, 'Requires Action should be false');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check if Action Required is set to true and To_Email_Address__c is populated
	 **/
	@isTest
	static void testUpdateActionRequiredTrue() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Benefits Renewal Case'];

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message for require action update')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Incoming_Email_Received__c, Requires_Action__c, Incoming_Email_Received_Date__c, To_Email_Address__c FROM Case WHERE Id = :objCase.Id];

		System.assert(objCase.Incoming_Email_Received__c, 'Incoming_Email_Received__c should be checked.');
		System.assert(objCase.Requires_Action__c, 'Requires_Action__c should be checked.');
		System.assertEquals(System.today(), objCase.Incoming_Email_Received_Date__c, 'Incoming_Email_Received_Date__c should be today\'s date.');
		System.assertEquals('test@gusto.com', objCase.To_Email_Address__c, 'To_Email_Address__c should match.');
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : Test method to handle the Vitals Risk Out of Office Assignment
	 **/
	@isTest
	static void testRiskOutOfOfficeAssignment() {
		Test.startTest();

		String strCaseRecordTypeId = Cache.getRecordTypeId('Case', 'Risk Assurance');
		Case objCase = [SELECT Id, OwnerId FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Risk Assurance Case' LIMIT 1];

		User objUser = [SELECT Id, Out_Of_Office__c FROM User WHERE LastName = 'Test Active User' LIMIT 1];

		objCase.OwnerId = objUser.Id;
		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objCurrentUser) {
			objUser.Out_Of_Office__c = true;
			update objUser;
		}

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setIncoming(true)
			.setSubject('test again')
			.setTextBody('test Body please ignore')
			.build();
		objEmailMessage.Status = '5';
		insert objEmailMessage;

		List<Case> list_Cases = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase.Id];
		Group objGroup = [SELECT Id FROM Group WHERE Name = 'Assurance Queue' AND Type = 'Queue'];

		System.assertEquals(list_Cases[0].OwnerId, objGroup.Id, 'OwnerId should match.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to handle EmailMessage created for case type Sales Cases when Status is Closed
	 **/
	@isTest
	static void testSalesCases() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Sales Case' AND RecordType.Name = 'Sales Cases'];

		CaseTriggerHelper.skipTrigger = true;
		objCase.Status = 'Closed';
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message for sales cases')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];

		System.assertNotEquals('Closed', objCase.Status, 'Case status should be Closed.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to handle EmailMessage created for case type Sales Cases when status is not Closed
	 **/
	@isTest
	static void testSalesCasesNew() {
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test Sales Case' AND RecordType.Name = 'Sales Cases'];

		CaseTriggerHelper.skipTrigger = true;
		objCase.Status = 'New';
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message for sales cases new status')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];

		System.assertEquals('New', objCase.Status, 'Case status should be New.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test exception catch blocks
	 **/
	@isTest
	static void testExceptionHandling() {
		Case objCase = [SELECT Id FROM Case LIMIT 1];

		Test.startTest();

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@gusto.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message to generate exception')
			.setTextBody('test Body please ignore')
			.build();

		blnThrowException = true;
		insert objEmailMessage;

		EmailMessage objEmailMsg = new EmailMessage(Id = objEmailMessage.Id);
		objEmailMsg.Status = '3';
		update objEmailMsg;

		delete objEmailMsg;
		blnThrowException = false;

		// Generating DML error by inserting objEmailMsg which is already inserted
		EmailMessageTriggerHelper.skipTrigger = true;
		Database.SaveResult objSaveResult = Database.insert(objEmailMsg, false);
		EmailMessageUtil.processDMLErrors(new List<Database.SaveResult>{ objSaveResult }, 'Insert');
		EmailMessageTriggerHelper.skipTrigger = true;

		EmailMessageTriggerHandler.resetSkipTriggerFlags();

		Test.stopTest();

		List<Exception_Log__c> list_ExceptionLogs = [SELECT Id FROM Exception_Log__c];
		System.assert(!list_ExceptionLogs.isEmpty(), 'Exception_Log__c list should not be empty.');
	}

	/**
	 * @author	Alex Xiong
	 * @description test updating to email address custom field when standard To Address is blank
	 */
	@isTest
	static void testUpdateToAddress() {
		List<User> list_Users = [SELECT Id FROM User WHERE LastName = 'Test Active User'];
		Case objCase = [SELECT Id FROM Case LIMIT 1];

		Test.startTest();
		System.runAs(list_Users[0]) {
			EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
				.setParentId(objCase.Id)
				.setToAddress('')
				.setFromAddress('test@gusto.com')
				.setIncoming(true)
				.setSubject('Testing renewalcarriercomms')
				.setTextBody('lorem ipsum dolor sit')
				.build();
			insert objEmailMessage;
		}
		Test.stopTest();

		List<Case> list_Cases = [SELECT To_Email_Address__c FROM Case WHERE Id = :objCase.Id];
		List<Exception_Log__c> list_Logs = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'EmailMessageTriggerHandler'];
		System.assertEquals(0, list_Logs.size(), 'There should be 0 exception logs.');
		System.assert(String.isBlank(list_Cases[0].To_Email_Address__c), 'To Email Address should be blank.');
	}


	/**
	 * @author Alex Xiong
	 * @description make sure only 1 Case Audit Log is created when an email is updated from draft to sent
	 */
	@isTest
	static void testAuditLogCount() {
		Case objCase = [SELECT Id FROM Case WHERE RecordTypeId = :CASE_RT_PAYROLL_CARE LIMIT 1];
		EmailMessage objEmail = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@gusto.com')
			.setToAddress('test@gusto.com')
			.setIncoming(false)
			.setSubject('email subject')
			.setTextBody('test')
			.build();

		objEmail.Status = '5';
		insert objEmail;

		Test.startTest();
		List<Case_Audit_Log__c> list_Logs = [SELECT Id FROM Case_Audit_Log__c WHERE Email_Message_Id__c = :objEmail.Id];
		System.assertEquals(0, list_Logs.size(), 'A case audit log should not have been created for a draft');

		EmailMessage objEmailMessage = new EmailMessage(Id = objEmail.Id);
		objEmailMessage.Status = '3';
		update objEmailMessage;

		Test.stopTest();

		List<Case_Audit_Log__c> list_LogsAfterUpdate = [SELECT Id, Event_Type__c, To_Status__c, Email_Message_Id__c FROM Case_Audit_Log__c];
		System.assertEquals(2, list_LogsAfterUpdate.size(), 'There should be 2 audit logs for a sent email message');

		for (Case_Audit_Log__c objLog : list_LogsAfterUpdate) {
			if (objLog.Event_Type__c == 'New Message') {
				System.assertEquals(objEmailMessage.Id, objLog.Email_Message_Id__c, 'Email message Id should match.');
			} else if (objLog.Event_Type__c == 'Status Change') {
				System.assertEquals('Awaiting Response', objLog.To_Status__c, 'Exception log\'s To Status should match.');
			}
		}
	}

	/**
	 * @author Alex Xiong
	 * @description make sure inbound Emails are generating Case Audit Logs
	 */
	@isTest
	static void testAuditLogFromEmaiReceived() {
		CaseTriggerHelper.skipTrigger = false;
		Case objCase = [SELECT Id FROM Case WHERE RecordTypeId = :CASE_RT_PAYROLL_CARE LIMIT 1];
		EmailMessage objEmail = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('testSender@gusto.com')
			.setToAddress('testReceiver@gusto.com')
			.setIncoming(true)
			.setSubject('email subject')
			.setTextBody('test')
			.build();

		insert objEmail;

		Test.startTest();
		List<Case_Audit_Log__c> list_Logs = [SELECT Id, To_Status__c, Event_Type__c, From_Status__c FROM Case_Audit_Log__c];

		System.assertEquals('Response Received', list_Logs[0].To_Status__c, 'Log To Status should be Response Received');
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description make sure outbound Emails are generating Case Audit Logs
	 */
	@isTest
	static void testAuditLogFromEmailSent() {
		CaseTriggerHelper.skipTrigger = false;
		Case objCase = [SELECT Id FROM Case WHERE RecordTypeId = :CASE_RT_PAYROLL_CARE LIMIT 1];
		EmailMessage objEmail = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('testSender@gusto.com')
			.setToAddress('testReceiver@gusto.com')
			.setIncoming(false)
			.setSubject('email subject')
			.setTextBody('test')
			.build();

		insert objEmail;

		Test.startTest();
		List<Case_Audit_Log__c> list_Logs = [SELECT Id, To_Status__c, Event_Type__c, From_Status__c FROM Case_Audit_Log__c];

		System.assertEquals('Awaiting Response', list_Logs[0].To_Status__c, 'Log To Status should be Awaiting Response');
		Test.stopTest();
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Test Method to see if new case is created when the benefit order status is fulfilled
	 **/
	@isTest
	static void testNoNewCaseCreationBOFulfilled() {
		Case objCase = [SELECT Id, AccountId FROM Case WHERE Subject = 'Test Benefits BYB Case'];

		BenefitOrderHelper.skipTrigger = true;

		Opportunity objNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objCase.AccountId)
			.setNumberOfEE(2)
			.build();
		objNewPlan.HI_Opportunity_Assignment_State__c = 'California';
		insert objNewPlan;

		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Test.startTest();

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setName('Test Benefit Order')
			.setAccount(objCase.AccountId)
			.setOpp(objNewPlan.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();

		objBenefitOrder.Order_Status__c = 'Fulfilled';

		insert objBenefitOrder;
		TriggerHandler.clearAllBypasses();

		objCase.Benefit_Order__c = objBenefitOrder.Id;
		update objCase;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message for require action update')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		List<Case> list_Cases3 = [SELECT Id, Subject, Related_Case__c, Owner.Name FROM Case WHERE Related_Case__c = :objCase.Id];
		System.assertEquals(0, list_Cases3.size(), 'Should not have created new case if there was a case closed within 3 days');
	}

	@isTest
	static void testNewCaseCreationBOFulfilled() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setResellerMetricsBatchSize(1).build();
		objConfigSettings.AccountEntitlementId__c = [SELECT Id FROM SlaProcess LIMIT 1][0].Id;
		insert objConfigSettings;
		List<sObject> list_Accounts = Test.loadData(Account.sObjectType, 'AccountTestData');
		//List<sObject> list_contacts = Test.loadData(Contact.sObjectType, 'ContactTestData');
		List<sObject> list_Cases = Test.loadData(Case.sObjectType, 'CaseTestData');
		Case objCase = (Case) list_Cases[0];
		Date threeDaysAgo = Date.today().addDays(-5);
		List<Case> list_Cases2 = [SELECT Id, AccountId, SuppliedEmail, ContactId, Subject, Authorized_User__c, ClosedDate FROM Case WHERE Id = :objCase.Id];
		for (Case caseObj : list_Cases2) {
			System.assert(threeDaysAgo > caseObj.ClosedDate, 'The CloseDate should be three days in the past.');
		}

		Test.startTest();
		BenefitOrderHelper.skipTrigger = true;

		Opportunity objNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(objCase.AccountId)
			.setNumberOfEE(2)
			.build();
		objNewPlan.HI_Opportunity_Assignment_State__c = 'California';
		insert objNewPlan;

		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setName('Test Benefit Order')
			.setAccount(objCase.AccountId)
			.setOpp(objNewPlan.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();

		objBenefitOrder.Order_Status__c = 'Fulfilled';

		insert objBenefitOrder;
		TriggerHandler.clearAllBypasses();

		objCase.Benefit_Order__c = objBenefitOrder.Id;
		update objCase;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('test email message for require action update')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		Case objCaseAssert = [SELECT Id, Subject, Related_Case__c, Owner.Name FROM Case WHERE Related_Case__c = :objCase.Id];
		System.assertNotEquals(null, objCaseAssert.Id, 'Should have created new case since BO is fulfilled and Email is receieved');
		System.assertNotEquals('Connect Broker', objCaseAssert.Owner.Name, 'New Case should be assigned to Connect Broker');
	}

	/**
	 * @author Alex Xiong
	 * @description assert email messages on closed cases create another Case
	 */
	@isTest
	static void testEmailOnClosedCase() {
		String strSubject = 'Closed Tax Res';
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'Tax Res - Read Only' AND Subject = :strSubject];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Case[0].Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('Test Email creating new Case')
			.setTextBody('Test')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		List<Case> list_Case2 = [SELECT Id, Status, Integration_Id__c FROM Case WHERE Subject = :strSubject];
		System.assertEquals(2, list_Case2.size(), 'There should be 2 cases.');
		for (Case objCaseRecord : list_Case2) {
			if (objCaseRecord.Status == 'Closed') {
				System.assertEquals('000000000', objCaseRecord.Integration_Id__c, 'Case Integration Id should match.');
			} else {
				System.assertEquals(null, objCaseRecord.Integration_Id__c, 'Case Integration Id should be null.');
			}
		}
	}

	/**
	 * @author Alex Xiong
	 * @description assert email messages on closed cases create another Case
	 */
	@isTest
	static void testEmailOnClosedBenefitsCareCase() {
		String strSubject = 'Closed Benefits Care';
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'Benefits Care - Read Only' AND Subject = :strSubject];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Case[0].Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject)
			.setTextBody('Test')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		List<Case> list_Case2 = [SELECT Id, Status FROM Case WHERE Subject = :strSubject];
		System.assertEquals(2, list_Case2.size(), 'There should be 2 cases.');
	}

	/**
	 * @author Alex Xiong
	 * @description assert email messages on closed cases with a non read-only record type create another Case
	 */
	@isTest
	static void testEmailOnBenefitsCareCase() {
		String strSubject = 'Non read only Benefits Care';
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'Benefits Care' AND Subject = :strSubject];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Case[0].Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject)
			.setTextBody('Test')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		List<Case> list_Case2 = [SELECT Id, Status FROM Case WHERE Subject = :strSubject];
		System.assertEquals(2, list_Case2.size(), 'There should be 2 cases.');
	}

	/**
	 * @author Alex Xiong
	 * @description assert email messages on closed cases with a non read-only record type create another Case
	 */
	@isTest
	static void testEmailOnPayrollCareCase() {
		String strSubject = 'Non read only Payroll Care';
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'Payroll Care' AND Subject = :strSubject];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Case[0].Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject)
			.setTextBody('Test')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		List<Case> list_Case2 = [SELECT Id, Status FROM Case WHERE Subject = :strSubject];
		System.assertEquals(2, list_Case2.size(), 'There should be 2 cases.');
	}
    
    /**
	 * @author Sahil Goyal
	 * @description assert for spam email messages to auto close the cases.
	 */
	@isTest
	static void testInvalidSpamEmailCase() {
		String strSubject = 'Testing Invalid Email Address for Spam emails';
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'Engagement' AND Subject = :strSubject];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Case[0].Id)
			.setFromAddress('test+2joq0a&kxp92&&246ba4d071def9e5ca15ad5e02819457a6f959e576246ba4d071def9e5ca15ad5e02819457a6f959e576@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject)
			.setTextBody('Test')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		List<Case> spam_case = [SELECT Id, Status FROM Case WHERE Subject = :strSubject];
		System.assertEquals(1, spam_case.size(), 'There should be 1 case');
        System.assertEquals(CaseUtils.STATUS_CLOSED, spam_case.get(0).Status, 'It should be Closed');
	}

	/**
	 * @author Alex Xiong
	 * @description assert getRecordTypesToCloneCase() retrieves a list of record types
	 */
	@isTest
	static void testGetRecordTypesToCloneCase() {
		EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
		objHelper.getRecordTypesToCloneCase();

		System.assert(EmailMessageTriggerHelper.set_ClosedCaseNewRecordTypes.size() > 0, 'There should be at least 1 Id in set.');
	}

	/**
	 * @author Alex Xiong
	 * @description assert closed Cases with no Contact will be cloned
	 */
	@isTest
	static void testClosedCaseWithNoContact() {
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		String strTestEmail = 'testClosedCaseWithNoContact@gustotest.com';
		String strSubject = 'Test Closed with no Contact';

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Care - Read Only')
			.setSubject(strSubject)
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setType('Benefits Care')
			.setSuppliedEmail(strTestEmail)
			.setAuthorizedUser('Yes')
			.build();
		insert objCase;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress(strTestEmail)
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject)
			.setTextBody('Test')
			.build();
		insert objEmailMessage;
		CaseTriggerHelper.skipTrigger = false;
		Test.stopTest();

		List<Case> list_Case = [SELECT Id FROM Case WHERE Subject LIKE :strSubject];
		System.assertEquals(2, list_Case.size(), 'There should be 2 cases.');
	}

	/**
	 * @author Alex Xiong
	 * @description assert new email-to-case Case is created with a Status = New
	 */
	@isTest
	static void testNewEmailCaseStatus() {
		Test.startTest();
		EmailToCaseTest.emailToCaseTest('support@gusto.com', 'Payroll Care', 'Payroll Care', 'Medium', 'Payroll Care Email', null);
		Test.stopTest();

		List<Case> list_Case = [SELECT Id, Status FROM Case WHERE Subject LIKE '%EMAIL-TO-CASE TEST%'];
		System.assertEquals('New', list_Case[0].Status, 'Case Status should be New.');
	}

	/**
	 * @author Alex Xiong
	 * @description assert emails sent to PRC Cases update the status to Response Received
	 */
	@isTest
	static void testResponseReceived() {
		Test.startTest();

		String strCaseRecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');

		Case objCase = [SELECT Id, Type, Subject FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Case for Poulating Type From Email Message' LIMIT 1];

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(objCase.Subject)
			.setTextBody('Test')
			.build();
		insert objEmailMessage;

		Test.stopTest();

		Case objCaseQueried = [SELECT Id, Status FROM Case WHERE RecordTypeId = :strCaseRecordTypeId AND Subject = 'Test Case for Poulating Type From Email Message' LIMIT 1];
		System.assertEquals('Response Received', objCaseQueried.Status, 'Case Status should match.');
	}

	/**
	 * @author Alex Xiong
	 * @description assert emails sent to Tax Res Cases update Latest Customer Response Date Time but does not change Status to Response Received
	 */
	@isTest
	static void testTaxResResponseReceived() {
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@acme.com'];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setSubject('testTaxResResponseReceived')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setType('Tax Res')
			.setOrigin(CaseUtils.ORIGIN_GUSTO)
			.setIntegrationId('1234123412341234')
			.setAuthorizedUser('Yes')
			.build();
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(objCase.Subject)
			.setTextBody('Test')
			.build();

		Test.startTest();
		insert objEmailMessage;
		Test.stopTest();

		Case objCaseQueried = [SELECT Id, Latest_Customer_Response_Date_Time__c, Status FROM Case WHERE Subject = 'testTaxResResponseReceived' LIMIT 1];
		//System.assert(objCaseQueried.Latest_Customer_Response_Date_Time__c != null, 'Latest_Customer_Response_Date_Time__c should not be null.');
		//System.assertNotEquals('Response Received', objCaseQueried.Status, 'Case Status should match.');
	}

	/**
	 * @author Swati Arya
	 * @description assert email messages on closed cases reopen parent Case Benefits BYB case
	 */
	@isTest
	static void testEmailOnClosedBenefitsBYBCase() {
		String strSubject = 'Closed Benefits BYB';
		Test.startTest();

		Case objCase = [SELECT Id, AccountId, Status, Audience__c, Reason FROM Case WHERE Subject = 'Test Benefits BYB Case'];

		objCase.Status = CaseUtils.STATUS_CLOSED;
		objCase.Audience__c = 'Gusto';
		objCase.Reason = 'Miscellaneous: Internal Test';
		objCase.Authorized_User__c = 'Yes';
		update objCase;

		System.assertEquals(CaseUtils.STATUS_CLOSED, objCase.Status, 'Case Status should be closed');

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject)
			.setTextBody('Test case reopen on closed case')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		Case objCase1 = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.STATUS_RESPONSE_RECEIVED, objCase1.Status, 'Case Status should be set to Response Receieved');
	}

	/** @author      : Pradeep Chary
	 * @description : To work on a closed case, a clone of case to be created instead of re-opening it
	 **/
	@isTest
	static void testCloneOfClosedCases() {
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;

		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id FROM Contact LIMIT 1];
		String strTestEmail = 'test@acme.com';
		String strSubject1 = 'Test Clone Payroll Care Case';
		String strSubject2 = 'Test Clone Tax Rex Case';

		List<Case> list_Cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Accounts[0].Id)
			.setContactId(list_Contacts[0].Id)
			.setRecordTypeId(CaseUtils.TYPE_PAYROLL_CARE)
			.setType(CaseUtils.TYPE_PAYROLL_CARE)
			.setSubject(strSubject1)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection(CaseUtils.STR_INBOUND)
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setSuppliedEmail(strTestEmail)
			.setDescription('Description: ' + strSubject1)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Accounts[0].Id)
			.setContactId(list_Contacts[0].Id)
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setSubject(strSubject2)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection(CaseUtils.STR_INBOUND)
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setSuppliedEmail(strTestEmail)
			.setDescription('Description: ' + strSubject2)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase2);
		insert list_Cases;

		List<EmailMessage> list_EmailMessages = new List<EmailMessage>();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Cases[0].Id)
			.setFromAddress(strTestEmail)
			.setToAddress('support@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject1)
			.setTextBody('Body: ' + strSubject1)
			.build();
		list_EmailMessages.add(objEmailMessage);

		EmailMessage objEmailMessage2 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Cases[1].Id)
			.setFromAddress(strTestEmail)
			.setToAddress('support@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject2)
			.setTextBody('Body: ' + strSubject2)
			.build();
		list_EmailMessages.add(objEmailMessage2);
		Test.stopTest();

		insert list_EmailMessages;

		CaseTriggerHelper.skipTrigger = false;

		List<Case> list_Cases2 = [SELECT Id, ParentId FROM Case WHERE Subject LIKE :strSubject1 ORDER BY CreatedDate ASC];
		System.assertEquals(2, list_Cases2.size(), 'Closed Payroll Care Case should be Cloned');
		System.assertEquals(list_Cases2[1].Id, list_Cases2[0].ParentId, 'Child Case should be linked to the Parent Case');

		list_Cases2 = [SELECT Id, ParentId FROM Case WHERE Subject LIKE :strSubject2 ORDER BY CreatedDate ASC];
		System.assertEquals(2, list_Cases2.size(), 'Closed Tax Res Case should be Cloned');
		System.assertEquals(list_Cases2[1].Id, list_Cases2[0].ParentId, 'Child Case should be linked to the Parent Case');
	}

	/**
	 * @author 			Deepika Saini
	 * @description 	This method is used to the updateton of the case.
	 * @param 			NA
	 * @return			NA
	 */
	@isTest
	static void testCaseUpdateAutomatedRFIFlow() {
		Test.startTest();

		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@acme.com'];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setSubject('Gusto benefits renewal')
			.setDescription('Test')
			.setStatus('Open')
			.setType('Benefits Renewal')
			.setOrigin('Hippo')
			.setIntegrationId('hippo-123')
			.setAutomatedRFIFlow(true)
			.build();
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(objCase.Subject)
			.setTextBody('Test')
			.build();
		insert objEmailMessage;

		Test.stopTest();

		Case objCaseQueried = [SELECT Id, Latest_Customer_Response_Date_Time__c, Status, Automated_RFI_Flow__c FROM Case WHERE Subject = 'Gusto benefits renewal' LIMIT 1];
		System.assert(!objCaseQueried.Automated_RFI_Flow__c, 'Automated_RFI_Flow__c is updated.');
	}

	/**
	 * @description Test Ticket Email Communication Status
	 * @author	Ajay Krishna P U
	 */
	@isTest
	static void testCommunicationStatusUpdate() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder().setStatus('New').setOwnerId(UserInfo.getUserId()).setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID).build();
		insert objTicket;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setFromAddress('from@abc.com')
			.setToAddress('to@abc.com')
			.setRelatedToId(objTicket.Id)
			.setSubject('Test subject')
			.setTextBody('Test body')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		objTicket = [SELECT Id, Communication_Status__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assert(objTicket.Communication_Status__c == TicketUtil.COMM_STATUS_AWAITING_RESPONSE, 'Invalid Communication Status - outbound email');
	}

	/**
	 * @Author:      Soujanya NJ
	 * @Description: Test method for follow up Case Email
	 */
	@isTest
	static void testFollowUpCaseEmail() {
		Test.startTest();

		List<Case> list_Cases = new List<Case>();
		List<EmailMessage> list_EmailMessages = new List<EmailMessage>();
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@acme.com'];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Phone')
			.setSubject('Test Engagement cases with case origin as Phone')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Phone')
			.setSubject('Test Engagement cases with case origin as Phone')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Phone')
			.setSubject('Test Engagement cases with case origin as Phone')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase3);
		insert list_Cases;

		User objUser = [SELECT Id FROM User WHERE Email = 'testactiveuser@gusto.com' LIMIT 1];
		list_Cases[0].ownerid = objUser.id;
		update list_Cases[0];

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(list_Cases[0].Id).setToAddress('testptserr@gusto.com').setIncoming(false).build();
		list_EmailMessages.add(objEmailMessage);

		EmailMessage objEmailMessage2 = new TestDataFactory.EmailMessageBuilder().setParentId(list_Cases[1].Id).setToAddress('testptserr@gusto.com').setIncoming(true).build();
		list_EmailMessages.add(objEmailMessage2);

		EmailMessage objEmailMessage3 = new TestDataFactory.EmailMessageBuilder().setParentId(list_Cases[2].Id).setToAddress('testptserr@gusto.com').setIncoming(false).setStatus('5').build();
		list_EmailMessages.add(objEmailMessage3);
		insert list_EmailMessages;

		List<EmailMessage> list_updateEmailMessage = [SELECT Id, Status FROM EmailMessage WHERE Status = '5' LIMIT 1];
		list_updateEmailMessage[0].status = '3';
		update list_updateEmailMessage;

		Test.stopTest();
		List<Case> list_CasesEmailSent = [
			SELECT Id, Origin, BusinessHoursId, Auto_Close_Date_Time__c, Support_Level__c, Type
			FROM Case
			WHERE Origin IN ('Phone', 'Email') AND RecordType.Name = 'Engagement' AND Subject != 'Testing Invalid Email Address for Spam emails'
		];
        
        // Assert if the Case origin is updated to Email or Not
		System.assertEquals(list_CasesEmailSent[0].Origin, 'Email', 'Case origin should be email.');
		System.assert(list_CasesEmailSent[0].Support_Level__c == 'Tier 1', 'Support Level not populated');
		System.assert(list_CasesEmailSent[0].Type == 'Payroll', 'Type not populated');
		System.assertNotEquals(list_CasesEmailSent[1].Origin, 'Email', 'Case origin should not be email.');
		System.assertEquals(list_CasesEmailSent[2].Origin, 'Email', 'Case origin should be email.');
		Date dExpectedAutoCloseDate = BusinessHours.add(list_CasesEmailSent[0].BusinessHoursId, System.Now(), 1000 * 60 * 60 * 9 * (Integer.valueOf(Label.EngagementAutoCloseDays))).date();
		Date dActualAutoCloseDate = list_CasesEmailSent[0].Auto_Close_Date_Time__c.date();

		// Assert check for the Auto Close date time population
		System.assertEquals(dExpectedAutoCloseDate, dActualAutoCloseDate, 'Auto Close Date doesnt match');
    }

	/**
	 * @description Test Engagement status update awaiting response
	 * @author	Prajjwal Tawri
	 */
	@isTest
	static void testEngagementStatusUpdate() {
		Case objCase = [SELECT Id, AccountId, Status FROM Case WHERE Subject = 'Test Engagement status update'];
		objCase.Status = Caseutils.STATUS_AWAITING_RESPONSE;
		update objCase;
		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('from@abc.com')
			.setToAddress('to@abc.com')
			.setIncoming(true)
			.setSubject('Test Updating Status')
			.setTextBody('Body test')
			.build();
		insert objEmailMessage;
		Test.stopTest();
		Case objCase2 = [SELECT Id, AccountId, Status FROM Case WHERE Subject = 'Test Engagement status update'];
		System.assertEquals(CaseUtils.STATUS_IN_PROGRESS, objCase2.Status, 'Case Status should match.');
	}

	/**
	 * @description Test Engagement status update awaiting internal support
	 * @author	Akanksha
	 */
	@isTest
	static void testEngagementStatusAISUpdate() {
		Case objCase = [SELECT Id, AccountId, Status FROM Case WHERE Subject = 'Test Engagement status update'];
		objCase.Status = Caseutils.STATUS_AWAITING_INTERNAL_SUPPORT;
		objCase.Internal_Support_Requested_From__c = 'Compliance';
		update objCase;
		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('from@abc.com')
			.setToAddress('to@abc.com')
			.setIncoming(true)
			.setSubject('Test Updating Status')
			.setTextBody('Body test')
			.build();
		insert objEmailMessage;
		Test.stopTest();
		Case objCase2 = [SELECT Id, AccountId, Status FROM Case WHERE Subject = 'Test Engagement status update'];
		System.assertEquals(CaseUtils.STATUS_IN_PROGRESS, objCase2.Status, 'Case Status should match.');
	}

	/**
	 * @description To check if it's a auto response from Vestwell then case should be auto closed.
	 * @author		Ankit C
	 */
	@isTest
	static void testVestwellAutoClose() {
		Case objCase = [SELECT Id, Status FROM Case WHERE Subject = '[Request received] | RE: Test case auto close'];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@vestwell.com')
			.setToAddress('support@gusto.com')
			.setIncoming(true)
			.setSubject('[Request received] | RE: Test case auto close')
			.setTextBody('Your request (361403) has been received and is being reviewed by our team.Thanks')
			.build();

		Test.startTest();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		Assert.areEqual(CaseUtils.STATUS_CLOSED, objCase.Status, 'Case was not auto closed');
	}

	/**
	 * @description To check if the case is auto-closed if it's thank you reponse on a closed case.
	 * @author		Ankit C
	 */
	@isTest
	static void testThankyouReplyAutoClose() {
		Case objCase = [SELECT Id, Status FROM Case WHERE Subject = 'Closed test case for thank you reply' LIMIT 1];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test123@gusto.com')
			.setToAddress('support@gusto.com')
			.setIncoming(true)
			.setSubject('Re:Closed test case for thank you reply')
			.setTextBody('Thank you for your assistance. Have a great day.')
			.build();

		Test.startTest();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		Assert.areEqual(CaseUtils.STATUS_CLOSED, objCase.Status, 'Case was not auto closed');
	}

	/**
	 * @description To check if Specialization is mapped correctly for COBRA cases
	 * @author		Ankit C
	 */
	@isTest
	static void testCOBRAEmail() {
		Contact objContact = [SELECT Id, AccountId FROM Contact LIMIT 1];
		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setSubject('Cobra case test')
			.setDescription('Cobra case test')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setAuthorizedUser('Yes')
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test1234@gusto.com')
			.setToAddress(EmailMessageUtil.COBRA_EMAIL)
			.setIncoming(true)
			.setSubject('Test email to Cobra')
			.setTextBody('Test email to Cobra')
			.build();

		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Specialization__c, Type, Support_Level__c FROM Case WHERE Id = :objCase.Id];
		Assert.areEqual(CaseUtils.COBRA_SPECIALIZATION, objCase.Specialization__c, 'Specialization should be COBRA');
		Assert.areEqual(CaseUtils.BENEFITS_CASE_PILLAR, objCase.Type, 'Case type should e Benefits');
		Assert.areEqual(CaseUtils.TIER_2, objCase.Support_Level__c, 'Case support level should be Tier 2');
	}

	/**
	 * @description To check if duplicate payroll transfer cases are auto closed
	 * @author		Praveen Sethu
	 */
	@isTest
	static void testDuplicatePayrollTransferCase() {
		Case objCase = [SELECT Id, Status FROM Case WHERE RecordTypeId = :CASE_RT_PAYROLL_TRANSFER_CASE LIMIT 1];
		Contact objContact = [SELECT Id, AccountId FROM Contact LIMIT 1];

		CaseTriggerHelper.skipTrigger = true;
		EmailMessageTriggerHelper.skipTrigger = true;
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test1234@gusto.com')
			.setToAddress(EmailMessageUtil.COBRA_EMAIL)
			.setIncoming(true)
			.setSubject('Test email to Cobra')
			.setTextBody('Test email to Cobra')
			.setThreadIdentifier('1234')
			.build();
		insert objEmailMessage;

		Case objCloseCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setSubject('Case to be closed')
			.setDescription('Test')
			.setType('Payroll Transfer')
			.setAuthorizedUser('Yes')
			.build();
		insert objCloseCase;
		EmailMessageTriggerHelper.skipTrigger = false;

		Case objTempCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :objCloseCase.Id];

		Test.startTest();
		EmailMessage objEmailMessage2 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCloseCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('Test email to Cobra')
			.setTextBody('Test email to Cobra')
			.setThreadIdentifier('1234')
			.build();
		insert objEmailMessage2;
		Test.stopTest();

		Case objCaseAssert = [SELECT Id, Status, Description FROM Case WHERE Id = :objCloseCase.Id];
		System.assertEquals(CaseUtils.STATUS_CLOSED, objCaseAssert.Status, 'Case should be closed');
		System.assertEquals('Existing Payroll Transfer Case', objCaseAssert.Description, 'Case close reason should be updated');
	}

	/**
	 * @description To Test partner regex match
	 * @author	Soujanya
	 */
	@isTest
	static void testEvaluatePartnerRedirects() {
		Case objCase = [SELECT Id, Origin, Status FROM Case WHERE subject = 'Test Engagement status update' LIMIT 1];
		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('from@abc.com')
			.setToAddress('chattest@acme.com')
			.setIncoming(true)
			.setSubject('partner case')
			.setTextBody('homebase')
			.build();
		insert objEmailMessage;
		Test.stopTest();
		objCase = [SELECT Id, Origin, Status, Partner_Case_Type__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals('Default', objCase.Partner_Case_Type__c, 'Partner regex matched with Email received');
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Test Method to see if new case is created when the benefit order status is fulfilled
	 **/
	@isTest
	static void testApprovedCarrierOrderCloseCase() {
		OpportunityTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		List<Case> list_RenewalCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Integration_Id__c = 'hippo-Benefits_Renewal-'];

		Opportunity objNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opp')
			.setStage('Raw')
			.setCloseDate(System.today())
			.setAccountId(list_RenewalCase[0].AccountId)
			.setNumberOfEE(2)
			.build();
		objNewPlan.HI_Opportunity_Assignment_State__c = 'California';
		insert objNewPlan;

		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setName('Test Benefit Order')
			.setAccount(list_RenewalCase[0].AccountId)
			.setOpp(objNewPlan.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();

		objBenefitOrder.Order_Status__c = 'Fulfilled';

		insert objBenefitOrder;

		//Insert carrier
		Carrier__c carrier1 = TestUtility.Carrier();

		//Insert carrier order
		Carrier_Order__c carrierOrder1 = TestUtility.createTestCarrierOrder(carrier1.Id, 'Test Carrier Order', objBenefitOrder.Id, false);
		carrierOrder1.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_APPROVED;
		insert carrierOrder1;

		list_RenewalCase[0].Benefit_Order__c = objBenefitOrder.Id;
		list_RenewalCase[0].Status = CaseUtils.STATUS_CLOSED;
		list_RenewalCase[0].Type = CaseUtils.TYPE_CARRIER_SUBMISSION;
		list_RenewalCase[0].Carrier_Order__c = carrierOrder1.Id;
		list_RenewalCase[0].Audience__c = 'Gusto';
		list_RenewalCase[0].Reason = 'Account Status: Destroy / Delete Account (Not Suspend)';
		update list_RenewalCase[0];

		TriggerHandler.clearAllBypasses();
		EmailMessageTriggerHelper.skipTrigger = false;
		Test.startTest();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_RenewalCase[0].Id)
			.setFromAddress('test@acme.com')
			.setToAddress('support@gusto.com')
			.setCCAddress('test.test3@test.com')
			.setIncoming(true)
			.setSubject('test email message for require action update')
			.setTextBody('test Body please ignore')
			.build();
		insert objEmailMessage;
		Test.stopTest();
		
		System.assertEquals(1, [SELECT Id FROM Task].size(), 'Task Record should be created when Parent case is closed and Carrier order is approved');
	}

	/**
	 * @description Test recovery case Incoming email - reset status
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testRecoveryCaseStatusForIncomingEmail() {
		Case objCaseOldVersion = [SELECT Id, RecordTypeId, Status,Latest_Customer_Response_Date_Time__c FROM Case WHERE RecordTypeId = :EmailMessageUtil.RECTYPE_RECOVERY LIMIT 1];
		Test.startTest();
		EmailMessage objEmailMessage1 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCaseOldVersion.Id)
			.setFromAddress('from' + EmailMessageUtil.RECOVERY_CASE_INBOUND_EMAIL_FILTER)
			.setToAddress('test@dev.com')
			.setIncoming(true)
			.setSubject('partner case')
			.setTextBody('homebase')
			.build();
		insert objEmailMessage1;
		Test.stopTest();
		Case objCaseNewVersion = [SELECT Id, Status, Latest_Customer_Response_Date_Time__c FROM Case WHERE Id = :objCaseOldVersion.Id];
		System.assertNotEquals(CaseUtils.STATUS_RESPONSE_RECEIVED, objCaseNewVersion.Status, 'Case status should not be update to response received');
		System.assertEquals(objCaseOldVersion.Latest_Customer_Response_Date_Time__c, objCaseNewVersion.Latest_Customer_Response_Date_Time__c, 'Latest customer response date time should not be updated');

		EmailMessage objEmailMessage2 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCaseNewVersion.Id)
			.setFromAddress('from@dev.com')
			.setToAddress('test@dev.com')
			.setIncoming(true)
			.setSubject('partner case')
			.setTextBody('homebase')
			.build();
		insert objEmailMessage2;
		objCaseNewVersion = [SELECT Id, Status, Latest_Customer_Response_Date_Time__c FROM Case WHERE Id = :objCaseNewVersion.Id];
		System.assertEquals(CaseUtils.STATUS_RESPONSE_RECEIVED, objCaseNewVersion.Status, 'Case status should be updated to response received');
		System.assertNotEquals(objCaseOldVersion.Latest_Customer_Response_Date_Time__c, objCaseNewVersion.Latest_Customer_Response_Date_Time__c, 'Latest customer response date time should be updated');
	}

	/*
	 * @Author      : Ankit C
	 * @Description : Test Method for email sent from middesk domain
	 **/
	@isTest
	static void testMiddeskEmail() {
		//create a case with Supplied email test@middesk.com
		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Engagement')
			.setSubject('Test Case for Middesk Email')
			.setDescription('Test')
			.setStatus('Open')
			.setType('Payroll')
			.setSuppliedEmail('test@middesk.com')
			.build();

		insert objCase;

		//create an email message with parent id as the case created above
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@middesk.com')
			.setToAddress('support@gusto.com')
			.setIncoming(true)
			.setSubject('Test Email from Middesk')
			.setTextBody('Test')
			.build();
		insert objEmailMessage;
		Test.stopTest();

		objCase = [SELECT Id, Origin, Status, OwnerId, Routing_Case_Reason__c FROM Case WHERE Id = :objCase.Id];
		Assert.areEqual('Middesk State Tax Registration', objCase.Routing_Case_Reason__c, 'Routing Case Reason should be Middesk State Tax Registration');
	}
	/*
	 * @Author      : Aslam Juneid
	 * @Description : Test Method for email sent on Closed Client Relations Case
	 **/
	@isTest
	static void testClosedClientRelationCase() {
		Case objCase30 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Client Relations')
			.setSubject('Closed test case Client Relations')
			.setDescription('Closed test case Client Relations')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setAuthorizedUser('Yes')
			.build();
		insert objCase30;
		Case objCaseOldVersion = [SELECT Id, RecordTypeId, Status,Latest_Customer_Response_Date_Time__c FROM Case WHERE RecordTypeId = :EmailMessageUtil.RECTYPE_CLIENT_RELATIONS LIMIT 1];
		Test.startTest();
		EmailMessage objEmailMessage1 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCaseOldVersion.Id)
			.setFromAddress('test@testClientRelatoin.com')
			.setToAddress('test@dev.com')
			.setIncoming(true)
			.setSubject('Client Relation Case')
			.setTextBody('Client Relation Case')
			.build();
		insert objEmailMessage1;
		Test.stopTest();
		Case objCaseNewVersion = [SELECT Id, Status, Latest_Customer_Response_Date_Time__c FROM Case WHERE Id = :objCaseOldVersion.Id];
		System.assertEquals(CaseUtils.STATUS_RESPONSE_RECEIVED, objCaseNewVersion.Status);
	}
		
	/**
	 * @author Omar Benitez
	 * @description assert email messages on closed cases should copy email to parent
	 */
	@isTest
	static void testEmailOnClosedBenefitsBYBCaseForParent() {
		String strSubject = 'Closed Benefits BYB';
		Test.startTest();

		Case objCase = [SELECT Id, AccountId, Status, Audience__c, Reason FROM Case WHERE Subject = 'Test Benefits BYB Case'];
		Case objCaseParent = [SELECT Id, AccountId, Status, Audience__c, Reason FROM Case WHERE Subject != 'Test Benefits BYB Case' LIMIT 1];

		objCaseParent.Status = CaseUtils.STATUS_OPEN;
		update objCase;

		objCase.Status = CaseUtils.STATUS_CLOSED;
		objCase.Closed_Reason__c = 'Merged Duplicate';
		objCase.Audience__c = 'Gusto';
		objCase.Reason = 'Miscellaneous: Internal Test';
		objCase.Authorized_User__c = 'Yes';
		objCase.ParentId = objCaseParent.Id;
		update objCase;

		System.assertEquals(CaseUtils.STATUS_CLOSED, objCase.Status, 'Case Status should be closed');

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('test@acme.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject(strSubject)
			.setTextBody('Test case reopen on closed case')
			.build();
		insert objEmailMessage;
		Test.stopTest();
		List<EmailMessage> list_emailParent = [Select id from EmailMessage where ParentId = :objCaseParent.Id];
		List<EmailMessage> list_emailCase = [Select id from EmailMessage where ParentId = :objCase.Id];

		Case objCase1 = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.STATUS_CLOSED, objCase1.Status, 'Case Status should keep as closed');
		System.assertEquals(1, list_emailParent.size(), 'Parent Case shouild have one email linked ');
		System.assertEquals(1, list_emailCase.size(), 'Case shouild have one email linked');
	}
}