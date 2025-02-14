/*
 * @name         TaxResAutoSolveUtilTest
 * @author       Pravesh Rana
 * @date         08-24-2022
 * @description  This class validates code coverage for "TaxResAutoSolveUtil" class
 * @test classes N/A
 */
@isTest
public with sharing class TaxResAutoSolveUtilTest {
	static final String CASE_STATUS_READYFORDATACAPTURE = 'Ready for Data Capture';
	static final String NO_NOTICE_FIELD_SET = 'No_Notice_Case_Updates';
	public static Boolean blnTestRevertCases = false;

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void createTestData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		Utils.skipTrigger(true);
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);

		Agency_Information__c objAgencyInfo = new TestDataFactory.AgencyInformationBuilder().setName('Test Agency').setActive(true).build();
		insert objAgencyInfo;

		List<Case> list_cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Tax Res')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.build();
		list_cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Tax Res')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setNoticeType('Credit listed or refund check')
			.build();
		list_cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Both Attachment')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp@test.com')
			.setMassEmailStep('Duplicate Notice1')
			.setTaxNoticeFormNumber('1234')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Automation Failed')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp@test.com')
			.setMassEmailStep('Duplicate Notice1')
			.setTaxNoticeFormNumber('1234')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase4);

		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Only Package')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp2@test.com')
			.setMassEmailStep('Duplicate Notice2')
			.setTaxNoticeFormNumber('5678')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase5);

		Case objCase6 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Non Physical email')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp2@test.com')
			.setMassEmailStep('Duplicate Notice2')
			.setTaxNoticeFormNumber('5678')
			.build();
		list_cases.add(objCase6);

		Case objCase7 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Physical email - only package')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp3@test.com')
			.setMassEmailStep('Duplicate Notice3')
			.setTaxNoticeFormNumber('333333')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase7);

		Case objCase8 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Physical email - only case')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp4@test.com')
			.setMassEmailStep('Duplicate Notice4')
			.setTaxNoticeFormNumber('444444')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase8);

		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		insert list_cases;

		//No Notice Attached
		List<Auto_Solve_Package__c> list_AutoSolvePackages = new List<Auto_Solve_Package__c>();
		Auto_Solve_Package__c objSolve = new TestDataFactory.AutoSolvePackageBuilder()
			.setActive(true)
			.setAutomationMessage('no notice attached auto-solve fired')
			.setAutomationStatus('Completed')
			.setAutoSolvePackageStatus('Active')
			.setCustomerJourney('Client Unresponsive')
			.setEmailTemplate('Email Body')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setName('No Notice Attached')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', TaxResAutoSolveUtil.AUTOSOLVE_RELATIVE_RT_NAME))
			.setFieldSetUsed(NO_NOTICE_FIELD_SET)
			.build();
		list_AutoSolvePackages.add(objSolve);

		Auto_Solve_Package__c objSolveBatch1 = new TestDataFactory.AutoSolvePackageBuilder()
			.setActive(true)
			.setAutomationMessage('no notice attached auto-solve fired')
			.setAutomationStatus('Completed')
			.setAutoSolvePackageStatus('Active')
			.setCustomerJourney('Client Unresponsive')
			.setEmailTemplate('Email Body')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setName('Duplicate Notice1')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Batch'))
			.setAgencyInformationId(objAgencyInfo.Id)
			.setGustoIsAddresseeOfRecord(true)
			.setTaxNoticeFormNumber('1234')
			.build();
		list_AutoSolvePackages.add(objSolveBatch1);

		Auto_Solve_Package__c objSolveBatch2 = new TestDataFactory.AutoSolvePackageBuilder()
			.setActive(true)
			.setAutomationMessage('no notice attached auto-solve fired')
			.setAutomationStatus('Completed')
			.setAutoSolvePackageStatus('Active')
			.setCustomerJourney('Client Unresponsive')
			.setEmailTemplate('Email Body')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setName('Duplicate Notice2')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Batch'))
			.setAgencyInformationId(objAgencyInfo.Id)
			.setTaxNoticeFormNumber('5678')
			.build();
		list_AutoSolvePackages.add(objSolveBatch2);

		Auto_Solve_Package__c objSolveBatch3 = new TestDataFactory.AutoSolvePackageBuilder()
			.setActive(true)
			.setAutomationMessage('no notice attached auto-solve fired')
			.setAutomationStatus('Completed')
			.setAutoSolvePackageStatus('Active')
			.setCustomerJourney('Client Unresponsive')
			.setEmailTemplate('Email Body')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setName('Duplicate Notice3')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Batch'))
			.setAgencyInformationId(objAgencyInfo.Id)
			.setGustoIsAddresseeOfRecord(true)
			.setTaxNoticeFormNumber('333333')
			.build();
		list_AutoSolvePackages.add(objSolveBatch3);

		Auto_Solve_Package__c objSolveBatch4 = new TestDataFactory.AutoSolvePackageBuilder()
			.setActive(true)
			.setAutomationMessage('no notice attached auto-solve fired')
			.setAutomationStatus('Completed')
			.setAutoSolvePackageStatus('Active')
			.setCustomerJourney('Client Unresponsive')
			.setEmailTemplate('Email Body')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setName('Duplicate Notice4')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Batch'))
			.setAgencyInformationId(objAgencyInfo.Id)
			.setGustoIsAddresseeOfRecord(true)
			.setTaxNoticeFormNumber('444444')
			.build();
		list_AutoSolvePackages.add(objSolveBatch4);
		insert list_AutoSolvePackages;

		List<ContentVersion> list_ContentVersion = new List<ContentVersion>();
		ContentVersion objContentVersionPack = new TestDataFactory.ContentVersionBuilder().setPathOnClient('TestFile1').setTitle('TestFile1').setVersionData(Blob.valueOf('sample content1')).build();
		list_ContentVersion.add(objContentVersionPack);

		ContentVersion objContentVersionPack1 = new TestDataFactory.ContentVersionBuilder().setPathOnClient('TestFile2').setTitle('TestFile2').setVersionData(Blob.valueOf('sample content2')).build();
		list_ContentVersion.add(objContentVersionPack1);

		ContentVersion objContentVersionCase = new TestDataFactory.ContentVersionBuilder().setPathOnClient('TestFile3').setTitle('TestFile3').setVersionData(Blob.valueOf('sample content3')).build();
		list_ContentVersion.add(objContentVersionCase);
		insert list_ContentVersion;

		List<ContentVersion> list_InsertedFiles = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :list_ContentVersion];
		List<ContentDocumentLink> list_ContDocLinks = new List<ContentDocumentLink>();
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objSolveBatch1.Id).setContentDocumentId(list_InsertedFiles[0].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objSolveBatch1.Id).setContentDocumentId(list_InsertedFiles[1].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objSolveBatch2.Id).setContentDocumentId(list_InsertedFiles[1].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objSolveBatch2.Id).setContentDocumentId(list_InsertedFiles[2].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objSolveBatch3.Id).setContentDocumentId(list_InsertedFiles[2].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objCase3.Id).setContentDocumentId(list_InsertedFiles[2].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objCase4.Id).setContentDocumentId(list_InsertedFiles[0].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objCase4.Id).setContentDocumentId(list_InsertedFiles[1].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objCase6.Id).setContentDocumentId(list_InsertedFiles[1].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objCase6.Id).setContentDocumentId(list_InsertedFiles[2].ContentDocumentId).build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder().setLinkedEntityId(objCase8.Id).setContentDocumentId(list_InsertedFiles[0].ContentDocumentId).build());
		insert list_ContDocLinks;

		List<Attachment> list_Attachments = new List<Attachment>();
		Attachment objAttachment1 = new TestDataFactory.AttachmentBuilder()
			.setName('Test')
			.setBody(Blob.valueOf('Test Body'))
			.setParent(objCase3.Id)
			.build();
		list_Attachments.add(objAttachment1);

		insert list_Attachments;

		Utils.skipTrigger(false);
		Test.stopTest();
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    validates "No Notice Attached" auto solve logic
	 * @param:          N/A
	 * @return:         N/A
	 */
	@isTest
	static void validateHandleFieldSyncMethod() {
		Test.startTest();
		List<Case> list_Cases = getCases();
		Auto_Solve_Package__c objSolve = TaxResAutoSolveUtil.getAutoSolvePackage(TaxResAutoSolveUtil.NO_NOTICE_AUTO_SOLVE_PACKAGE)[0];
		System.assertEquals('Completed', objSolve.Automation_Status__c);

		Case objCase = TaxResAutoSolveUtil.handleFieldSync(list_Cases[0], new Case(Id = list_Cases[0].Id), TaxResAutoSolveUtil.NO_NOTICE_AUTO_SOLVE_PACKAGE);
		System.assertEquals(list_Cases[0].Id, objCase.Id);
		System.assertEquals(objCase.Customer_Journey__c, objSolve.Customer_Journey__c);
		System.assertEquals(objCase.Root_Cause__c, objSolve.Root_Cause__c);
		System.assertEquals(objCase.Sub_Root_Cause__c, objSolve.Sub_Root_Cause__c);
		Test.stopTest();
	}

	static List<Case> getCases() {
		return [SELECT Id, Agency_Information__c, Agency_Information__r.Name, Status, AccountId, Account.Name, Origin FROM Case];
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = true and Case with Gusto Addressee = true with one attchment on case and two attachments on package.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testsendAutoSolveEmailBothAttachment() {
		Test.startTest();
		List<Case> list_Cases = [
			SELECT Id, Status, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin
			FROM Case
			WHERE SuppliedEmail = 'temp@test.com' AND Subject = 'Both Attachment'
		];
		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);
		Test.stopTest();
		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
			List<Attachment> list_Attchment = [SELECT id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the Auto Solve Failed functionality.(where case attachement size is greater than 1)
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testsendAutoSolveEmailAutomationFailed() {
		Test.startTest();
		List<Case> list_Cases = [
			SELECT Id, Status, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin
			FROM Case
			WHERE SuppliedEmail = 'temp@test.com' AND Subject = 'Automation Failed'
		];

		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);
		Test.stopTest();
		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
			System.assertEquals(false, list_EmailMessages.size() > 0, 'Email is not sent');
			System.assertEquals(CaseUtils.STR_IB_FAILED_STATUS, objCase.Automation_Status__c, 'Automation status is not failed.');
			System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCase.Status, 'Case Status in not Ready for Research.');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = false and Case with Gusto Addressee = false.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testsendAutoSolveEmailWithCheckFalse() {
		Test.startTest();
		List<Case> list_Cases = [
			SELECT Id, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, Status
			FROM Case
			WHERE SuppliedEmail = 'temp2@test.com' AND Subject = 'Only Package'
		];

		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);

		Test.stopTest();
		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
			List<Attachment> list_Attchment = [SELECT id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent.');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = true and
	 * Case with Gusto Addressee = true with one attchment on case and no attachment on package.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testsendAutoSolveEmailBothAttachment2() {
		Test.startTest();
		Auto_Solve_Package__c objAutoSolvePack = [SELECT Id FROM Auto_Solve_Package__c WHERE Name = 'Duplicate Notice1' LIMIT 1];

		List<ContentDocumentLink> list_ContentDocumentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :objAutoSolvePack.Id];
		delete list_ContentDocumentLinks;
		List<Case> list_Cases = [
			SELECT Id, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, CreatedDate, Status
			FROM Case
			WHERE SuppliedEmail = 'temp@test.com' AND Subject = 'Both Attachment'
		];
		
		EmailMessage objMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Cases[0].Id)
			.setSubject('Test')
			.setStatus('1')
			.build();
		insert objMessage;
		
		Attachment objAttachment = new Attachment();
		objAttachment.ParentId = objMessage.Id;
		objAttachment.Body = Blob.valueOf('Test Data');
		objAttachment.Name = 'TestAttachment';
		insert objAttachment;

		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);
		Test.stopTest();
		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
			List<Attachment> list_Attchment = [SELECT id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = false and Case with Gusto Addressee = false with one case attachment and no attachment on package.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testsendAutoSolveEmailWithCheckFalse2() {
		Test.startTest();

		Auto_Solve_Package__c objAutoSolvePack = [SELECT Id FROM Auto_Solve_Package__c WHERE Name = 'Duplicate Notice2' LIMIT 1];

		List<ContentDocumentLink> list_ContentDocumentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :objAutoSolvePack.Id];
		delete list_ContentDocumentLinks;

		List<Case> list_Cases = [
			SELECT Id, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, Status
			FROM Case
			WHERE SuppliedEmail = 'temp2@test.com' AND Subject = 'Non Physical email'
		];

		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);

		Test.stopTest();

		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
			List<Attachment> list_Attchment = [SELECT Id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			List<ContentDocumentLink> list_CaseAttchment = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :list_Cases[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent.');
			System.assertEquals(true, list_Attchment.size() == 0, 'Email is sent with package attchment.');
			System.assertEquals(true, list_CaseAttchment.size() == 2, 'Case attachment is null.');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = true and Case with Gusto Addressee = true with no attachment on case and one attachment on package.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testSendAutoSolvePhysicalEmailOnlyPackgAtt() {
		Test.startTest();
		List<Case> list_Cases = [
			SELECT Id, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, Status
			FROM Case
			WHERE SuppliedEmail = 'temp3@test.com' AND Subject = 'Physical email - only package'
		];

		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);
		Test.stopTest();

		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
			List<Attachment> list_Attchment = [SELECT id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent.');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = true and Case with Gusto Addressee = true with one attachment on case and no attachment on package.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testSendAutoSolvePhysicalEmailOnlyCaseAtt() {
		Test.startTest();
		List<Case> list_Cases = [
			SELECT Id, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, Status
			FROM Case
			WHERE SuppliedEmail = 'temp4@test.com' AND Subject = 'Physical email - only case'
		];

		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);
		Test.stopTest();

		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
			List<Attachment> list_Attchment = [SELECT id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent.');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = false and Case with Gusto Addressee = false with no attachment on case and one attachment on package.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testSendAutoSolveNonPhysicalEmailOnlyPKGAtt() {
		Test.startTest();
		Auto_Solve_Package__c objAutoSolvePack = [SELECT Id FROM Auto_Solve_Package__c WHERE Name = 'Duplicate Notice2' LIMIT 1];

		List<ContentDocumentLink> list_ContentDocumentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :objAutoSolvePack.Id LIMIT 1];
		delete list_ContentDocumentLinks;
		List<Case> list_Cases = [
			SELECT Id, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, Status
			FROM Case
			WHERE SuppliedEmail = 'temp2@test.com' AND Subject = 'Only Package'
		];

		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);

		Test.stopTest();
		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :objCase.Id];
			List<Attachment> list_Attchment = [SELECT id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent.');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the send email for Package with Gusto Adressee of record = false and Case with Gusto Addressee = false with one attachment on case and no attachment on package.
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testSendAutoSolveNonPhysicalEmailOnlyCaseAtt() {
		Test.startTest();

		Auto_Solve_Package__c objAutoSolvePack = [SELECT Id FROM Auto_Solve_Package__c WHERE Name = 'Duplicate Notice2' LIMIT 1];

		List<ContentDocumentLink> list_ContentDocumentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :objAutoSolvePack.Id];
		delete list_ContentDocumentLinks;

		List<Case> list_Cases = [
			SELECT Id, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, Status
			FROM Case
			WHERE SuppliedEmail = 'temp2@test.com' AND Subject = 'Non Physical email'
		];

		delete [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :list_Cases[0].Id LIMIT 1];
		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);

		Test.stopTest();

		if (OrganizationUtilities.canSendEmails()) {
			Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :objCase.Id];
			List<Attachment> list_Attchment = [SELECT Id, name FROM Attachment WHERE ParentId = :list_EmailMessages[0].Id];
			List<ContentDocumentLink> list_CaseAttchment = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :list_Cases[0].Id];
			System.assertEquals(true, list_EmailMessages.size() > 0, 'Email is not sent.');
			System.assertEquals(true, list_Attchment.size() == 0, 'Email is sent with package attchment.');
			System.assertEquals(true, list_CaseAttchment.size() == 1, 'Case attachment is null.');
		}
	}

	/**
	 * @author        Rushi R
	 * @description   This method is used to test reverting the Cases
	 */
	@isTest
	static void testsendAutoSolveRevertCases() {
		blnTestRevertCases = true;

		Test.startTest();
		List<Case> list_Cases = [
			SELECT Id, Status, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin
			FROM Case
			WHERE SuppliedEmail = 'temp@test.com' AND Subject = 'Both Attachment'
		];
		TaxResAutoSolveUtil.sendAutoSolveEmail(list_Cases);
		Test.stopTest();

		Case objCase = [SELECT Id, Automation_Status__c, Status FROM Case WHERE Id = :list_Cases[0].Id LIMIT 1];
		System.assertEquals(CaseUtils.STR_IB_FAILED_STATUS, objCase.Automation_Status__c, 'Automation status is not failed.');
		System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCase.Status, 'Case Status in not Ready for Research.');
	}
}