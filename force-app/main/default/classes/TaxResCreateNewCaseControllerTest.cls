/**
 * @name             TaxResCreateNewCaseControllerTest.cls
 * @author           Pravesh Rana
 * @date             July-7-2021
 * @description      This class is used to test the "Code Coverage" of "TaxResCreateNewCaseController" class
 *                   which is related to "Tax Res" project.
 * @Covered class    TaxResCreateNewCaseController
 * @revisions        Date ------------ Name ------------ Comments
 **/
@isTest
public with sharing class TaxResCreateNewCaseControllerTest {
	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void handleTestData() {
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);
		Case ObjCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		CaseTriggerHelper.skipTrigger = true;
		Case objTaxResCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test Case Tax Res Subject')
			.setDescription('Test Case Tax Res Description')
			.setSuppliedEmail('test.contact@gusto.com')
			.setType('Tax Res')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('Data Capture in Progress')
			.build();
		insert objTaxResCase;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "getCaseDetails" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getCaseDetailsTest() {
		Test.startTest();

		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];

		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			Attachment objAttachment = new TestDataFactory.AttachmentBuilder().setName('Attachment 1').setBody(blob.valueOf('Attachment 1')).setParent(objCase.Id).build();
			insert objAttachment;

			TaxResCreateNewCaseController.CaseDetail objCaseDetails = TaxResCreateNewCaseController.getCaseDetails(objCase.Id);
			System.assert(objCaseDetails.strParentCaseAccountId != null);
			System.assert(objCaseDetails.list_Attachments.size() > 0);
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate negative scenario of "getCaseDetails" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getCaseDetailsNegativeTest() {
		Test.startTest();

		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];

		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);

			TaxResCreateNewCaseController.CaseDetail objCaseDetails = TaxResCreateNewCaseController.getCaseDetails(objCase.Id);
			System.assert(objCaseDetails.strParentCaseAccountId != null);
			System.assert(objCaseDetails.list_Attachments.size() == 0);
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "updateCaseAttachment" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void updateCaseAttachmentTest() {
		Test.startTest();

		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];

		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			Account objAccount = list_Account.get(0);

			Attachment objAttachment = new TestDataFactory.AttachmentBuilder().setName('Attachment 1').setBody(blob.valueOf('Attachment 1')).setParent(objAccount.Id).build();
			insert objAttachment;

			TaxResCreateNewCaseController.updateCaseAttachment(objCase.Id, objAttachment.Id);
		}

		Test.stopTest();

		list_Case = [SELECT Id FROM Case LIMIT 1];
		Case objCase = list_Case.get(0);
		List<Attachment> list_attachment = [SELECT Id FROM Attachment WHERE ParentId = :objCase.Id];
		System.assert(list_attachment.size() > 0);
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : validate "getCaseDetails" method for data capture status
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getCaseDetailsForDataCaptureTest() {
		Test.startTest();

		List<Case> list_Case = [SELECT Id FROM Case WHERE Status = 'Data Capture in Progress'];

		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			Attachment objAttachment = new TestDataFactory.AttachmentBuilder().setName('Attachment 1').setBody(blob.valueOf('Attachment 1')).setParent(objCase.Id).build();
			insert objAttachment;

			TaxResCreateNewCaseController.CaseDetail objCaseDetails = TaxResCreateNewCaseController.getCaseDetails(objCase.Id);
			System.assertEquals(objCaseDetails.strTaxResQueue, GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue'));
			System.assertEquals(objCaseDetails.strCaseStatus, 'Ready for Data Capture');
		}
		Test.stopTest();
	}
}