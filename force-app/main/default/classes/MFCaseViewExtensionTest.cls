@istest
public class MFCaseViewExtensionTest {
	@testsetup
	static void createTestData() {
		MFCaseViewExtensionTest.skipTrigger(true);
		Account objAccount = TestUtility.CompanyAccount();

		Contact objContact = new Contact(
			AccountId = objAccount.Id,
			FirstName = 'Test2',
			LastName = 'Contact',
			Email = 'test.contact2@gusto.com',
			ZP_User_Id__c = '200919002',
			RecordTypeId = Cache.getRecordTypeId('Contact', 'Company')
		);
		insert objContact;

		Case objcase = new Case();
		objcase.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		objcase.AccountId = objAccount.Id;
		objcase.ContactId = objContact.Id;
		objcase.Subject = 'Test MF QLE';
		objcase.Description = 'Test MF QLE Case';
		insert objcase;

		MFCaseViewExtensionTest.skipTrigger(false);
	}

	@istest
	private static void testSaveMFAuditCase() {
		Blob key = EncryptionUtils.generateKey('Master');

		ZP_User_Role__c userRole = new ZP_User_Role__c();
		userRole.User_Id__c = 'test123';
		userRole.User_Permissions__c = 'full_access';
		userRole.Company_Id__c = '32141';
		userRole.Type__c = 'Role:PayrollAdmin';
		insert userRole;

		Account acc = TestUtility.CompanyAccount();
		acc.zp_company_id__c = '32141';
		update acc;
		
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.Id)
			.setFirstName('Test')
			.setLastName('Test')
			.setEmail('testcontact100@test.com')
			.setPhone('123456')
			.setZPUserId('test123')
			.build();
		
		insert objContact;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.ContactId = objContact.id;
		cse.suppliedEmail = 'TestMFCaseView@gusto.com';
		insert cse;
		Attachment atchment = new Attachment();
		atchment.ParentId = cse.id;
		atchment.body = encryptionUtils.getEncryptedBlob(key, 'test');
		atchment.Name = 'encFile.txt';
		insert atchment;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveMFAuditCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@istest
	private static void testSaveMFNHECase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveMFNHECase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@IsTest
	private static void testSaveMFQLECase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveMFQLECase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@isTest
	private static void testSaveMFTerminationCase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveMFTerminationCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@isTest
	private static void testSaveMFUpdatesCase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveMFUpdatesCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@isTEst
	private static void testSaveMFEmailsCase() {
		Account acc = TestUtility.CompanyAccount();

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveMFEmailsCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@isTEst
	private static void testSavePayrollTransferCase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Transfer Case');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Origin = 'Email';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SavePayrollTransferCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@istest
	private static void testSaveBORCase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveBORCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@istest
	private static void testSaveNpCase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveNewPlanCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}

	@istest
	private static void testSavePayrollCase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		PageReference pageRef = extension.SavePayrollCareCase();
		System.assertEquals('/apex/PayrollCareCasePage?id=' + cse.id + '&refreshPage=true', pageRef.getUrl());
		test.stopTest();
	}

	@istest
	private static void testSaveBenefitCareCase() {
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		PageReference pageRef = extension.SaveBenefitsCareCase();
		System.assertEquals('/apex/BenefitsCareCasePage?id=' + cse.id + '&refreshPage=true', pageRef.getUrl());
		extension.routeCase();
		test.stopTest();
	}

	@istest
	private static void testSaveRenewalCase() {
        AccountTriggerHelper.skipTrigger = true;
        CaseTriggerHelper.skipTrigger = true;
		Account acc = TestUtility.CompanyAccount();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.ccEmailAddress__c = 'test@test.com';
		insert cse;

		EmailMessage msg3 = new EmailMessage();
		msg3.ParentId = cse.id;
		msg3.FromAddress = 'test@gusto.com';
		msg3.ToAddress = 'test.test@gusto.com;test.test1@test.com';
		msg3.CCAddress = 'test.test3@test.com';
		msg3.Subject = 'Re: test';
		msg3.Incoming = false;
		msg3.TextBody = 'test Reply';
		insert msg3;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		MFCaseViewExtension extension = new MFCaseViewExtension(stdCase);
		MFCaseViewExtension.getEmailCC(cse.id);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveRenewalCase();
		cse = [SELECT Id, Requires_Action__c FROM Case WHERE id = :cse.id];
		system.assertEquals(true, cse.Requires_Action__c);
		test.stopTest();
	}


	@isTest
	private static void testQLERFIAutomateEmail() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM CASE WHERE RecordType.Name = 'MF QLE'];

		if (list_Cases != null && list_Cases.size() > 0) {
			Case objcase = list_Cases[0];
			ApexPages.currentPage().getParameters().put('Id', objcase.Id);
			ApexPages.StandardController objStdCase = new ApexPages.StandardController(objcase);
			MFCaseViewExtension extension = new MFCaseViewExtension(objStdCase);

			objcase = extension.theCase;
			objcase.Requires_Action__c = true;
			objcase.QLE_RFI_Type__c = 'Divorce';
			objcase.Insufficient_Proof_Reason__c = 'Test';
			extension.sendFirstRFI();

			Test.stopTest();
			if(OrganizationUtilities.canSendEmails()){
				objcase = [SELECT Id, RFI_Status__c FROM Case WHERE Id = :objcase.id];
				System.assertEquals('RFI 1', objcase.RFI_Status__c);
				List<EmailMessage> list_EM = [SELECT Id FROM EmailMessage WHERE ParentId = :objcase.id];
				System.assert(list_EM.size() > 0);
			}
		}
	}

	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
	}
}