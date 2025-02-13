/*
 * @name         TaxResAutoSolveEmailHelperTest
 * @author       Shyam Nasare
 * @date         24-08-2023
 * @description  This class validates code coverage for "TaxResAutoSolveEmailHelper" class
 * @test classes N/A
 */

@isTest
public class TaxResAutoSolveEmailHelperTest {
	static final String CASE_STATUS_READYFORDATACAPTURE = 'Ready for Data Capture';
	static final String NO_NOTICE_FIELD_SET = 'No_Notice_Case_Updates';
	@TestVisible
	public static Boolean blnTestRevertCases = false;
 
	/**
	 * @Author      : Shyam
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void createTestData() {
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
			.setSubject('With 4 Attachment')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp@test.com')
			.setMassEmailStep('Duplicate Notice Auto-Solve fired')
			.setTaxNoticeFormNumber('1234')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase);
 
		Case objCase1 = new TestDataFactory.CaseBuilder()
		.setRecordTypeId('Tax Res')
		.setAccountId(objAccount.Id)
		.setContactId(objContact.Id)
		.setSubject('With Email Attachment')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp@test.com')
			.setMassEmailStep('Duplicate Notice Auto-Solve fired')
			.setTaxNoticeFormNumber('123456')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase1);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('With 2 Attachment')
			.setType('Tax Res')
			.setDescription('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CASE_STATUS_READYFORDATACAPTURE)
			.setAgencyInformation(objAgencyInfo.Id)
			.setSuppliedEmail('temp@test.com')
			.setMassEmailStep('Duplicate Notice Auto-Solve fired')
			.setTaxNoticeFormNumber('123456')
			.setPhysicalMail(true)
			.build();
		list_cases.add(objCase3);
 
		 CaseTriggerHelper.skipTrigger = true;
		 Test.startTest();
		 insert list_cases;
 
		List<ContentVersion> list_ContentVersion = new List<ContentVersion>();
		ContentVersion objContentVersionPack = new TestDataFactory.ContentVersionBuilder()
			.setPathOnClient('TestFile1')
			.setTitle('TestFile1')
			.setVersionData(Blob.valueOf('sample content1'))
			.build();
		list_ContentVersion.add(objContentVersionPack);
		insert list_ContentVersion;

		List<ContentVersion> list_InsertedFiles = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :list_ContentVersion];
		List<ContentDocumentLink> list_ContDocLinks = new List<ContentDocumentLink>();
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder()
			.setLinkedEntityId(objCase.Id)
			.setContentDocumentId(list_InsertedFiles[0].ContentDocumentId)
			.build());
		list_ContDocLinks.add(new TestDataFactory.ContentDocumentLinkBuilder()
			.setLinkedEntityId(objCase3.Id)
			.setContentDocumentId(list_InsertedFiles[0].ContentDocumentId)
			.build());
		 insert list_ContDocLinks;
 
		EmailMessage objEmailMsg = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase1.Id)
			.setStatus('1')
			.setSubject('With Email Attachment')
			.build();
		objEmailMsg.CreatedDate = objCase1.CreatedDate;
		insert objEmailMsg;

		List<Attachment> list_Attachments = new List<Attachment>();
		Attachment objAttachment1 = new TestDataFactory.AttachmentBuilder()
			.setName('Test')
			.setBody(Blob.valueOf('Test Body'))
			.setParent(objCase.Id)
			.build();
		list_Attachments.add(objAttachment1);
 
		Attachment objAttachment2 = new TestDataFactory.AttachmentBuilder()
			.setName('Test')
			.setBody(Blob.valueOf('Test Body'))
			.setParent(objEmailMsg.Id)
			.build();
		list_Attachments.add(objAttachment2);

		Attachment objAttachment3 = new TestDataFactory.AttachmentBuilder()
			.setName('Test')
			.setBody(Blob.valueOf('Test Body'))
			.setParent(objCase.Id)
			.build();
		list_Attachments.add(objAttachment3);

		Attachment objAttachment4 = new TestDataFactory.AttachmentBuilder()
			.setName('Test')
			.setBody(Blob.valueOf('Test Body'))
			.setParent(objCase.Id)
			.build();
		list_Attachments.add(objAttachment4);

		Attachment objAttachment5 = new TestDataFactory.AttachmentBuilder()
			.setName('Test')
			.setBody(Blob.valueOf('Test Body'))
			.setParent(objCase3.Id)
			.build();
		list_Attachments.add(objAttachment5);
 
		insert list_Attachments;

		Utils.skipTrigger(false);
		Test.stopTest();
	 }
 
	 /**
	  * @author        Shyam
	  * @description   This method is used to test the send email for Package with Gusto Adressee of record = true
	  * @param         NA
	  * @return 		  NA
	  */
	 @isTest
	 static void testSendAutoSolveEmailAttachment() {
		 Test.startTest();
		List<Case> list_Cases = [SELECT Id, Status, Mass_Email_Step__c, ContactId, ContactEmail, subject, SuppliedEmail, Physical_Mail__c, Origin, Automation_Message__c, Automation_Message_Follow_Up__c, CreatedDate FROM Case];
 
		 TaxResAutoSolveEmailHelper.sendAutoSolveEmail(list_Cases);
		 Test.stopTest();
 
		list_Cases = [SELECT Id, Automation_Status__c, Status FROM Case];
		List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
		System.assertEquals(true, list_EmailMessages.size() == 0, 'Email is sent');
	 }
 }