/**
 * Class Name : TaxNoticeOCRUpdateBatchTest
 * Date Created : 2025-02-18
 * Author : Ankit Rajput
 * Description : This test class provides a thorough validation of the batch logic under various conditions
 */

@isTest
private class TaxNoticeOCRUpdateBatchTest {
    
    @isTest
    static void testBatchExecution() {
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
        
        List<Case> list_CasesToUpdate = new List<Case>();
        String strCaseStatus = CaseUtils.CASE_STATUS_OCR_CAPTUREINPROGRESS;
        for(Case objEachCase : [SELECT Id, Status FROM Case]) {
            objEachCase.Status = strCaseStatus;
            objEachCase.OwnerID = CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
            list_CasesToUpdate.add(objEachCase);
        }
        update list_CasesToUpdate;
        
        Test.startTest();
        TaxNoticeOCRUpdateBatch batch = new TaxNoticeOCRUpdateBatch();
        Database.executeBatch(batch);
        Test.stopTest();
		List<Case> list_CasesAfterUpdate = [SELECT Id, Status, OwnerID FROM Case];
        System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, list_CasesAfterUpdate[0].Status, 'Case Status Updated');
		System.assertEquals(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE, list_CasesAfterUpdate[0].OwnerId, 'Case Owner Updated');
        System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, list_CasesAfterUpdate[1].Status, 'Case Status Updated');
		System.assertEquals(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE, list_CasesAfterUpdate[1].OwnerId, 'Case Owner Updated');
        System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, list_CasesAfterUpdate[2].Status, 'Case Status Updated');
		System.assertEquals(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE, list_CasesAfterUpdate[2].OwnerId, 'Case Owner Updated');

    }
  
}