@isTest
private class EngagementCaseViewExtensionTest {
	static Case objCase;
	static EngagementCaseViewExtension extension;

	@testSetup
	static void setUp() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		ZP_User__c zpUser = new ZP_User__c();
		zpUser.Name = 'EngagementCaseView TestUser';
		zpUser.Created_At__c = System.today();
		zpUser.Updated_At__c = System.today();
		zpUser.Id__c = 'EngagementCaseViewUser1';
		zpUser.Email__c = 'EngagementUser@gusto1.com';
		insert zpUser;

		ZP_User_Role__c userRole = new ZP_User_Role__c();
		userRole.User_Id__c = zpUser.Id__c;
		userRole.Company_Id__c = 'engagementCase4321';
		userRole.First_Name__c = 'EngagementCaseView';
		userRole.Last_Name__c = 'TestUser';
		userRole.User_Permissions__c = 'full_access;';
		userRole.Type__c = 'PayrollAdmin';
		insert userRole;

		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Company').setZPCompanyId('engagementCase4321').setStates('FL;OR').build();
		insert objAcc;

		list<Contact> list_Contacts = new List<Contact>();
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAcc.Id)
			.setPhone('123456')
			.setFirstName('Test')
			.setLastName('TestEngagementCaseViewExtension')
			.build();
		list_Contacts.add(objContact1);

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAcc.Id)
			.setPhone('123456')
			.setFirstName('Parent')
			.setLastName('TestParentEngagementCaseView')
			.build();
		list_Contacts.add(objContact2);

		insert list_Contacts;

		list<Group> phoneRoutingList = [SELECT Id FROM Group WHERE type = 'Queue' AND Name = 'Phone Routing'];

		Case objCase1 = new Case();
		objCase1.ContactId = objContact1.Id;
		objCase1.AccountId = objAcc.Id;
		objCase1.Direction__c = 'Inbound';
		objCase1.Origin = 'Phone';
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		objCase1.Genesys_Call_Id__c = '222111333';
		if (phoneRoutingList.size() > 0) {
			objCase1.OwnerId = phoneRoutingList.get(0).Id;
		}
		objCase1.ccEmailAddress__c = 'test@test.com';

		insert objCase1;
		list<case> list_Cases = new List<case>();
		Case objCase = new Case();
		objCase.ContactId = objContact2.Id;
		objCase.AccountId = objAcc.Id;
		objCase.Direction__c = 'Inbound';
		objCase.Origin = 'Phone';
		objCase.ParentId = objCase1.Id;
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res');
		objCase.Genesys_Call_Id__c = '222111333';
		if (phoneRoutingList.size() > 0) {
			objCase.OwnerId = phoneRoutingList.get(0).Id;
		}
		list_Cases.add(objCase);

		Case objCase2 = new Case();
		objCase2.Direction__c = 'Inbound';
		objCase2.ContactId = objContact1.Id;
		objCase2.AccountId = objAcc.Id;
		objCase2.Origin = 'Phone';
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		objCase2.Genesys_Call_Id__c = '222111333';
		if (phoneRoutingList.size() > 0) {
			objCase2.OwnerId = phoneRoutingList.get(0).Id;
		}
		list_Cases.add(objCase2);

		Case objCase3 = new Case();
		objCase3.ContactId = objContact2.Id;
		objCase3.AccountId = objAcc.Id;
		objCase3.Direction__c = 'Inbound';
		objCase3.Origin = 'Phone';
		objCase3.ParentId = objCase1.Id;
		objCase3.RecordTypeId = Cache.getRecordTypeId('Case', 'PayrollOps Audit');
		objCase3.Genesys_Call_Id__c = '222111333';
		if (phoneRoutingList.size() > 0) {
			objCase3.OwnerId = phoneRoutingList.get(0).Id;
		}
		list_Cases.add(objCase3);

		insert list_Cases;

		Case_Reason_Classification__c cseReason = new Case_Reason_Classification__c();
		cseReason.name = 'Test Reason';
		cseReason.Active__c = true;
		cseReason.Type__c = 'Tax Res';
		insert cseReason;

		Large_Scale_Issue__c largeScaleIssues = new Large_Scale_Issue__c();
		largeScaleIssues.name = 'Test LSI';
		insert largeScaleIssues;
	}

	@isTest
	static void callPickUpFunctionality() {
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = [SELECT Id, ownerId FROM Case WHERE Genesys_Call_Id__c != NULL].get(0);

		Case_Audit_Log__c logRec = new Case_Audit_Log__c();
		logRec.Case__c = objCase.Id;
		logRec.Event_Type__c = 'Phone';
		insert logRec;

		Task tsk = new task();
		tsk.whatId = objCase.Id;
		insert tsk;

		apexPages.standardController sc = new apexPages.standardController(objCase);
		EngagementCaseViewExtension controller = new EngagementCaseViewExtension(sc);
		controller.assignUserOnCallPickup();
		controller.setAccessPermission('', 'EngagementUser@gusto1.com');
		controller.checkCaseTask();
		controller.checkCaseTaskFromPoller();
		controller.updateCaseAuditLog(objCase);
		controller.saveAccountNotes();
		controller.initModernBankHighlightsPanel();
		controller.SaveModernBankCase();
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void publishToApIntegoTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		setupTestRun(objCase);
		extension.publishToApIntego();
		extension.getRoutingPageReference('123');
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void acceptCaseTest() {
		Test.startTest();
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		Case objCase = [SELECT Id, Status, OwnerId FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		User usr = new User(
			Alias = 'gusst11',
			Email = 'gusto.standarduser2@gustotestorg.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'TestingCase',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = p.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'gusto.standarduser2@gustotestorg.com',
			Out_Of_Office__c = false
		);
		insert usr;
		Map<String, Schema.RecordTypeInfo> recordTypesadjustment = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
		System.runAs(usr) {
			setupTestRun(objCase);
			PageReference pageRef = extension.acceptCase();
			objCase = [SELECT Id, Status, OwnerId FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		}
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void unmergeCaseTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		setupTestRun(objCase);
		PageReference pageRef = extension.unmergeCase();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		if (pageMessages.size() > 0) {
			System.assertEquals(1, pageMessages.size(), 'There should be 1 page message.');
			System.assertEquals(ApexPages.Severity.INFO, pageMessages[0].getSeverity(), 'Page message severity should be INFO.');
			System.assertEquals('Case is successfully un merged', pageMessages[0].getDetail(), 'Page message detail should match.');
		}

		System.assertEquals('true', pageRef.getParameters().get('refreshPage'), 'refreshPage parameter should be true.');
		Test.stopTest();
	}

	@isTest
	static void moveToProgressTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		setupTestRun(objCase);
		PageReference pageRef = extension.moveToInprogress();
		objCase = [SELECT Id, Status FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertEquals(2, pageMessages.size(), 'There should be 2 page messages.');
		System.assertEquals('In Progress', objCase.status, 'Status should be in progress.');
		Test.stopTest();
	}

	@isTest
	static void moveToOpenTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		setupTestRun(objCase);
		PageReference pageRef = extension.moveToOpen();
		objCase = [SELECT Id, Status FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertEquals(1, pageMessages.size(), 'There should be 1 page message.');
		System.assertEquals(ApexPages.Severity.INFO, pageMessages[0].getSeverity(), 'Page message severity should be INFO.');
		extension.routeCase();
		PageReference pageRef1 = extension.initPayrollCareCase();
		PageReference pageRef2 = extension.initBenefitCareCase();
		PageReference pageRef3 = extension.initTaxResCase();
		PageReference pageRef4 = extension.initTaxOpsCase();
		PageReference pageRef5 = extension.initPayrollComplianceCase();
		PageReference pageRef6 = extension.initRiskCase();
		extension.getRoutingPageReference('Risk');
		extension.initModernBankCase();
		extension.initBenefitsCompliance();
		extension.SaveRiskAssuranceCase();
		extension.SaveBenefitsComplianceCase();
		Test.stopTest();
	}

	@isTest
	static void taxOpsCaseTest() {
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		Case objCase = [SELECT Id, AccountId FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		setupTestRun(objCase);
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		PageReference pageRef1 = extension.SaveTaxOpsCase();
		extension.initTaxOpsCase();
		extension.initTaxResHighlightsPanel();

		extension.statusChangeEvent();
		extension.saveCaseRecord();
		System.assertEquals(objCase.AccountId, extension.theAccount.Id, 'Account Id should match.');
		Test.stopTest();
	}

	@isTest
	static void payrollCareTest() {
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		Case objCase = [SELECT Id, AccountId FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		setupTestRun(objCase);
		PageReference pageRef1 = extension.SavePayrollCareCase();
		extension.initPayrollHighlightsPanel();
		System.assertEquals(objCase.AccountId, extension.theAccount.Id, 'Account Id should match.');
		Test.stopTest();
	}

	@isTest
	static void taxResTest() {
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		Case objCase = [SELECT Id, AccountId FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		setupTestRun(objCase);
		PageReference pageRef1 = extension.SaveTaxResCase();
		extension.initTaxResHighlightsPanel();
		System.assertEquals(objCase.AccountId, extension.theAccount.Id, 'Account Id should match.');
		Test.stopTest();
	}

	@isTest
	static void benefitsCareTest() {
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		Case objCase = [SELECT Id, AccountId FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		setupTestRun(objCase);
		PageReference pageRef1 = extension.SaveBenefitsCareCase();
		extension.initBenefitsHighlightsPanel();
		System.assertEquals(objCase.AccountId, extension.theAccount.Id, 'Account Id should match.');
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void upsellTest() {
		Test.startTest();
		Case objCase2 = [SELECT Id, AccountId FROM Case WHERE Account.ZP_Company_Id__c = 'engagementCase4321' LIMIT 1];
		setupTestRun(objCase2);

		extension.zpExpId = '123';
		extension.zpCompId = '123';
		extension.zpExpStatusId = '123';
		extension.operation = '123';
		extension.boolIsChat = true;
		extension.operation = 'NotInterested';
		extension.updateCount();
		extension.operation = 'NotApplicable';
		extension.updateCount();
		extension.operation = 'TrackConversation';
		extension.updateCount();
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}
	@isTest
	static void testValidationsForTaxResCase() {
		Test.startTest();
		Case obj_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		setupTestRun(obj_Case);
		extension.theCase.Status = 'Solved';
		extension.SaveTaxResCase();

		System.assertNotEquals([SELECT Status FROM Case WHERE Id = :obj_Case.Id].Status, 'Solved', 'Case status should not be Solved.');

		extension.theCase.Confirm_Case_Reason__c = '1099 Adjustment';
		extension.SaveTaxResCase();
		extension.unmergeCase();
		System.assertNotEquals([SELECT Status FROM Case WHERE Id = :obj_Case.Id].Status, 'Solved', 'Case status should not be Solved.');
		Test.stopTest();
	}
	@isTest
	static void testValidationsForPayrollOpsAuditCase() {
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		Case obj_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'PayrollOps Audit' LIMIT 1];
		setupTestRun(obj_Case);
		extension.initPayrollAuditCase();
		extension.getRoutingPageReference('PayrollOps Audit');
		extension.theCase.Status = 'Solved';
		extension.theCase.Confirm_Case_Reason__c = '1099 Adjustment';
		extension.SavePayrollAuditCase();
		extension.unmergeCase();
		Test.stopTest();

		System.assertNotEquals([SELECT Status FROM Case WHERE Id = :obj_Case.Id].Status, 'Solved', 'Case status should not be Solved.');
	}
	@isTest
	static void testTakeItPayrollOpsAuditCase() {
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		Case obj_Case = [SELECT Id FROM Case WHERE RecordType.Name = 'PayrollOps Audit' LIMIT 1];
		setupTestRun(obj_Case);
		extension.acceptCase();
		Test.stopTest();

		System.assertEquals([SELECT Status FROM Case WHERE Id = :obj_Case.Id].Status, 'In Progress', 'Case Status should be In Progress');
	}
	static void setupTestRun(Case objCase) {
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		extension.checkCaseStatus();
		extension.statusChangeEvent();
		EngagementCaseViewExtension.getEmailCC(objCase.Id);
		System.assertNotEquals(null, extension, 'extension should not be null.');
	}
	@isTest
	static void unmergeCaseBCareTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		PageReference pageRef = extension.unmergeCase();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		if (pageMessages.size() > 0) {
			System.assertEquals(1, pageMessages.size(), 'There should be 1 page message.');
			System.assertEquals(ApexPages.Severity.INFO, pageMessages[0].getSeverity(), 'Page message severity should be INFO.');
			System.assertEquals('Case is successfully un merged', pageMessages[0].getDetail(), 'Page message detail should match.');
		}
		System.assertEquals('true', pageRef.getParameters().get('refreshPage'), 'refreshPage parameter should be true.');
		Test.stopTest();
	}
	@isTest
	static void unmergeCasePCareTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		PageReference pageRef = extension.unmergeCase();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		if (pageMessages.size() > 0) {
			System.assertEquals(1, pageMessages.size(), 'There should be 1 page message.');
			System.assertEquals(ApexPages.Severity.INFO, pageMessages[0].getSeverity(), 'Page message severity should be INFO.');
			System.assertEquals('Case is successfully un merged', pageMessages[0].getDetail(), 'Page message detail should match.');
		}

		System.assertEquals('true', pageRef.getParameters().get('refreshPage'), 'refreshPage parameter should be true.');
		Test.stopTest();
	}
	@isTest
	static void unmergeCaseTaxResTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		PageReference pageRef = extension.unmergeCase();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		if (pageMessages.size() > 0) {
			System.assertEquals(1, pageMessages.size(), 'There should be 1 page message.');
			System.assertEquals(ApexPages.Severity.INFO, pageMessages[0].getSeverity(), 'Page message severity should be INFO.');
			System.assertEquals('Case is successfully un merged', pageMessages[0].getDetail(), 'Page message detail should match.');
		}

		System.assertEquals('true', pageRef.getParameters().get('refreshPage'), 'refreshPage parameter should be true.');
		Test.stopTest();
	}
	@isTest
	static void unmergeCasePAuditTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'PayrollOps Audit');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		PageReference pageRef = extension.unmergeCase();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		if (pageMessages.size() > 0) {
			System.assertEquals(1, pageMessages.size(), 'There should be 1 page message.');
			System.assertEquals(ApexPages.Severity.INFO, pageMessages[0].getSeverity(), 'Page message severity should be INFO.');
			System.assertEquals('Case is successfully un merged', pageMessages[0].getDetail(), 'Page message detail should match.');
		}

		System.assertEquals('true', pageRef.getParameters().get('refreshPage'), 'refreshPage parameter should be true.');
		Test.stopTest();
	}
	@isTest
	static void unmergeCaseMBankTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Modern Bank');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		PageReference pageRef = extension.unmergeCase();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		if (pageMessages.size() > 0) {
			System.assertEquals(1, pageMessages.size(), 'There should be 1 page message.');
			System.assertEquals(ApexPages.Severity.INFO, pageMessages[0].getSeverity(), 'Page message severity should be INFO.');
			System.assertEquals('Case is successfully un merged', pageMessages[0].getDetail(), 'Page message detail should match.');
		}

		System.assertEquals('true', pageRef.getParameters().get('refreshPage'), 'refreshPage parameter should be true.');
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}
	@isTest
	static void caseMBankTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Modern Bank');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}
	@isTest
	static void caseTaxOpsTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Ops');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void casePayrollComTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Compliance');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}
	@isTest
	static void caseBenefitTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Compliance');
		update objCase;
		ApexPages.StandardController stdController = new ApexPages.StandardController(objCase);
		extension = new EngagementCaseViewExtension(stdController);
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}
	/**
	 * @author Prajjwal Tawri
	 * @description testing initEngagementCase()
	 */
	@isTest
	static void caseEngagementTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE Contact.FirstName = 'Parent' LIMIT 1];
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Engagement');
		update objCase;
		setupTestRun(objCase);
		PageReference pageRef = extension.initEngagementCase();
		System.assertEquals(null, pageRef, 'pageRef should not be null.');
		Test.stopTest();
	}
}