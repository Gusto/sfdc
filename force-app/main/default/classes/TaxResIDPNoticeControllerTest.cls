/**
 * @name         TaxResIDPNoticeControllerTest
 * @author       Shyam Nasare
 * @date         10/09/2024
 * @description  Test class for 'TaxResIDPNoticeController'
 **/

@IsTest
public with sharing class TaxResIDPNoticeControllerTest {
	@testSetup
	static void setUp() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		List<Tax_Notice_Index__c> list_TNDC = new List<Tax_Notice_Index__c>();

		// Creating new company account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		objAccount.Joined_Date_Panda__c = System.today();
		objAccount.ZP_Company_ID__c = 'ZPCOMPANY123';
		insert objAccount;

		//Creating Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First\' Name1')
			.setLastName('Test Last\' Name1')
			.setEmail('newmember1@campaign.com')
			.setNormalizedPhone('1876543211')
			.build();
		insert objContact;

		//Create tax Res
		Agency_Information__c objAgency = TestDataFactory.CreateOneAgencyInforation('Internal Revenue Service');

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Test Subject')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Amended W-2 for 2019 needed')
			.setAgencyInformation(objAgency.Id)
			.build();
		insert objCase;

		Tax_Notice_Index__c objTaxNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(objCase.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Tax_Notice_Index__c', 'IDP Indexing'))
			.setAgencyInformation(objAgency.Id)
			.build();
		objTaxNotice.Manual_Review_Required__c = true;
		objTaxNotice.MRR_Reason__c = 'Failed: Untrained Document';
		list_TNDC.add(objTaxNotice);

		insert list_TNDC;
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : Test method to check After OCR Capture Complete status updates
	 **/
	@IsTest
	static void testAfterOCRCaptureCompleteUpdates() {
		Test.startTest();
		Case objCase = [SELECT Id, Status, OCR_Message__c, OCR_Status__c FROM Case LIMIT 1];
		objCase.Status = CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE;
		update objCase;
		Test.stopTest();

		objCase = [SELECT Id, Status, OCR_Message__c, OCR_Status__c, Auto_Indexing_Status__c FROM Case LIMIT 1];

		System.assertEquals(TaxResIDPNoticeController.AUTO_INDEX_STATUS_PARTIALLY_INDEXED, objCase.Auto_Indexing_Status__c, 'Auto Indexing Status is not Partially Indexed');
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : Test method to check Custom MetaData for TNDC Confidence Score setting
	 **/
	@IsTest
	static void testCustomMetadata() {
		Test.startTest();
		Case objCase = [SELECT Id, Status, OCR_Message__c, OCR_Status__c FROM Case LIMIT 1];
		List<Tax_Res_TNDC_Confidence_Score_Setting__mdt> list_customMetadata = TaxResIDPNoticeController.getTNDCConfidenceScoreSetting(objCase.Id);
		Test.stopTest();
		System.assert(list_customMetadata != null, 'Custom Metadata not found');
	}
}