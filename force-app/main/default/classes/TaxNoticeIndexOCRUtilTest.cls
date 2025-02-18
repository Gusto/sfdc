@isTest
public with sharing class TaxNoticeIndexOCRUtilTest {
	@testSetup
	static void setUp() {
		Id OCR_RECORD_TYPE_ID = Schema.SObjectType.Tax_Notice_Index__c.getRecordTypeInfosByDeveloperName().get('OCR').getRecordTypeId();
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		Integer intCount = 1;
		List<Attachment> list_Attachments = new List<Attachment>();
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
		Agency_Information__c objAgency = TestDataFactory.createOneAgencyInforation('Internal Revenue Service');
		Agency_Information__c objAgency2 = TestDataFactory.createOneAgencyInforation('Texas Workforce Commission');

        List<Case> list_Cases = new List<Case>();

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
		list_Cases.add(objCase);
        
        Case objCase1 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Test Subject')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Case')
			.setAgencyInformation(objAgency.Id)
			.build();
		list_Cases.add(objCase1);
        
        Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Test Subject')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Case without notice')
			.setAgencyInformation(objAgency.Id)
			.build();
		list_Cases.add(objCase2);
        
        insert list_Cases;

		Tax_Notice_Index__c objTaxNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(objCase.Id)
			.setRecordTypeId(OCR_RECORD_TYPE_ID)
			.setAgencyInformation(objAgency.Id)
			.setCompanyName('Test Company')
			.build();
		list_TNDC.add(objTaxNotice);

		Tax_Notice_Index__c objTaxNotice2 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(objCase.Id)
			.setRecordTypeId(OCR_RECORD_TYPE_ID)
			.setAgencyInformation(objAgency.Id)
			.setCompanyName('Test Com')
			.build();
		list_TNDC.add(objTaxNotice2);

        Tax_Notice_Index__c objTaxNotice3 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(objCase1.Id)
			.setRecordTypeId(OCR_RECORD_TYPE_ID)
			.setAgencyInformation(objAgency.Id)
			.setCompanyName('Test Company')
			.build();
        objTaxNotice3.Manual_Review_Required__c = true;
        objTaxNotice3.MRR_Reason__c = 'Attachment not found';
		list_TNDC.add(objTaxNotice3);

		insert list_TNDC;

		for (Tax_Notice_Index__c objIndex : list_TNDC) {
            if (objIndex.MRR_Reason__c != 'Attachment not found') {
			Attachment objAttachment = new Attachment(Name = 'TempFile-' + intCount, Body = blob.valueOf('random values as file body'), ParentId = objIndex.Id);
			list_Attachments.add(objAttachment);
			intCount++;
		}
		}

		insert list_Attachments;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Set TaxRes Case Status Based On Agency - Positive Case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testOCRTNDCCasesPositive() {
		//Case objCase;
		Test.startTest();

		//get Case Detail
		List<Case> list_Cases = [SELECT Id, Status, OCR_Message__c, OCR_Status__c FROM Case];
        for (Case objCase : list_Cases) {
		objCase.Status = CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE;
        }
		update list_Cases;

		list_Cases = [SELECT Id, Status, OCR_Message__c FROM Case];
		//child case creation check
		System.assert(list_Cases != null);

		test.stopTest();
	}

	@isTest
	static void testOCRTNDCCasesNegative() {
		Id OCR_RECORD_TYPE_ID = Schema.SObjectType.Tax_Notice_Index__c.getRecordTypeInfosByDeveloperName().get('OCR').getRecordTypeId();
		Agency_Information__c objAgency = [SELECT Id FROM Agency_Information__c WHERE Name = 'Texas Workforce Commission'];
		Case objCase = [SELECT Id, Status, OCR_Message__c FROM Case LIMIT 1];

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		objCase.Agency_Information__c = objAgency.Id;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		Tax_Notice_Index__c objTaxNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(objCase.Id)
			.setRecordTypeId(OCR_RECORD_TYPE_ID)
			.setAgencyInformation(objAgency.Id)
			.build();
		insert objTaxNotice;

		objCase.Status = CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE;
		objCase.OCR_Status__c = CaseUtils.STR_IB_SUCCESS_STATUS;
		objCase.Automation_Message_Details__c = CaseUtils.STR_IB_ATTACHMENTNOTFOUND_MSG;
		update objCase;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Status, OCR_Message__c, OCR_Status__c FROM Case];
		//message check
		//System.assertEquals(CaseUtils.STR_IB_FAILED_STATUS, list_Cases[0].OCR_Status__c, 'Failed');
		System.assertEquals(CaseUtils.STR_SFDC_ERROR_ACCOUNTNOTFOUND_MSG, list_Cases[0].OCR_Message__c, 'Failed');

		List<Tax_Notice_Index__c> list_TaxNotice = [SELECT Id, Client_Name__c FROM Tax_Notice_Index__c WHERE Case__c = :objCase.Id];
		System.assertEquals(null, list_TaxNotice[0].Client_Name__c, 'Failed');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Checks the scheduleable functionality of the batch class
	 **/
	@isTest
	static void testOCRBatchSchedule() {
		Test.startTest();
		TaxNoticeOCRUpdateBatch objBatch = new TaxNoticeOCRUpdateBatch();
		String CRON_EXP = '0 0 23 * * ?';
		String jobId = system.schedule('TaxRes OCR Capture Batch', CRON_EXP, objBatch);
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(CRON_EXP, ct.CronExpression, 'job not scheduled');
		System.assertEquals(0, ct.TimesTriggered, 'should only be triggered once.');
		Test.stopTest();
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Check OCR Batch for Case with Is OCR Process = TRUE
	 **/
	@isTest
	static void testOCRBatchOCRProcessed() {
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = [SELECT Id, Status, OwnerId, Is_OCR_Processed__c FROM Case LIMIT 1];
		objCase.OwnerId = CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
		objCase.Is_OCR_Processed__c = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		System.assertEquals(CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID, objCase.OwnerId, 'Case Owner does not match');
		
		Database.executeBatch(new TaxNoticeOCRUpdateBatch(), 1);
		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId, Is_OCR_Processed__c FROM Case WHERE Id = :objCase.Id];
		//System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, objCase.Status, 'Case Status did not change');
		//System.assertEquals(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE, objCase.OwnerId, 'Case Owner did not change');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Check OCR Batch for Case with Is OCR Process = FALSE
	 **/
	@isTest
	static void testOCRBatchOCRNotProcessed() {
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = [SELECT Id, Status, OwnerId, Is_OCR_Processed__c FROM Case LIMIT 1];
		objCase.OwnerId = CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
		objCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCase.Status, 'Case Status does not match');
		System.assertEquals(CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID, objCase.OwnerId, 'Case Owner does not match');

		Database.executeBatch(new TaxNoticeOCRUpdateBatch(), 1);
		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId, Is_OCR_Processed__c FROM Case WHERE Id = :objCase.Id];
		//System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, objCase.Status, 'Case Status did not change');
		//System.assertEquals(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE, objCase.OwnerId, 'Case Owner did not change');
	}

	/**
	 * @Author      : Ela Nagarathinam
	 * @Description : Test the tax notice type update for CP161
	 **/
	@isTest
	static void testTaxNoticeTypeForCP161() {
		Id OCR_RECORD_TYPE_ID = Schema.SObjectType.Tax_Notice_Index__c.getRecordTypeInfosByDeveloperName().get('OCR').getRecordTypeId();
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		Contact objContact = [SELECT Id, Name FROM Contact LIMIT 1];
		Agency_Information__c objAgency = [SELECT Id, Name FROM Agency_Information__c LIMIT 1];

		Test.startTest();
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
			.setDescription('Test Case')
			.setAgencyInformation(objAgency.Id)
			.build();
		insert objCase;

		Tax_Notice_Index__c objTaxNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(objCase.Id)
			.setRecordTypeId(OCR_RECORD_TYPE_ID)
			.setAgencyInformation(objAgency.Id)
			.setCompanyName('Test Company')
			.setTaxNoticeFormNumber('CP161')
			.setYearQuarter('Q1 2024')
			.build();
		insert objTaxNotice;
		
		objCase.Status = CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE;
		objCase.OCR_Message__c = CaseUtils.STR_IB_SUCCESS_MSG;
		objCase.OCR_Status__c = CaseUtils.STR_IB_SUCCESS_STATUS;
		update objCase; 
		
		List<Tax_Notice_Index__c> list_TaxNotice = [SELECT Id, Client_Name__c, Tax_Notice_Type__c, Tax_Notice_Form_Number__c FROM Tax_Notice_Index__c WHERE Case__c = :objCase.Id AND RecordType.Name = 'Manual Indexing'];
		System.assertEquals(TaxNoticeIndexOCRUtil.TNDC_FORM_TYPE_UNSUPPORTED, list_TaxNotice[0].Tax_Notice_Type__c, 'CP161 should only have notice type unsupported');
		Test.stopTest();
	}
}