@isTest
public class TaxNoticeIndexTriggerHelperTest {
	@testSetup
	static void setUp() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		// Creating new company account
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account')
			.setZPCompanyId('ZPCOMPANY123')
			.setJoinedDate(System.today())
			.build();
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
		List<Agency_Information__c> list_Agencies = new List<Agency_Information__c>();
		Agency_Information__c objAgency1 = TestDataFactory.CreateOneAgencyInforation('CA-EDD');
		objAgency1.SUI_Rate_Form_Numbers__c = 'DE8080';
		list_Agencies.add(objAgency1);

		Agency_Information__c objAgency2 = TestDataFactory.CreateOneAgencyInforation('Texas Workforce Commission');
		objAgency2.SUI_Rate_Form_Numbers__c = 'DE123';
		list_Agencies.add(objAgency2);
		update list_Agencies;

		// create tax rates
		List<Tax_Rate__c> list_TaxRates = new List<Tax_Rate__c>{
			new Tax_Rate__c(Agency_Information__c = objAgency1.Id, Name = 'CC Rate1', ZP_Tax_Rate_Name__c = 'cc_ab_1'),
			new Tax_Rate__c(Agency_Information__c = objAgency1.Id, Name = 'CC Rate2', ZP_Tax_Rate_Name__c = 'cc_ab_2'),
			new Tax_Rate__c(Agency_Information__c = objAgency2.Id, Name = 'TX Rate1', ZP_Tax_Rate_Name__c = 'tx_ab_1'),
			new Tax_Rate__c(Agency_Information__c = objAgency2.Id, Name = 'TX Rate2', ZP_Tax_Rate_Name__c = 'tx_ab_2')
		};
		insert list_TaxRates;

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setSubject('Test Subject')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Amended W-2 for 2019 needed')
			.setAgencyInformation(objAgency1.Id)
			.build();
		list_Cases.add(objCase1);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setSubject('Test Subject')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Amended W-2 for 2019 needed')
			.setAgencyInformation(objAgency1.Id)
			.build();
		list_Cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setSubject('Test Subject')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Amended W-2 for 2019 needed')
			.setAgencyInformation(objAgency1.Id)
			.build();
		list_Cases.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setSubject('Test Subject')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Amended W-2 for 2019 needed')
			.setAgencyInformation(objAgency1.Id)
			.build();
		list_Cases.add(objCase4);

		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setSubject('Test Subject')
			.setOrigin(CaseUtils.ORIGIN_ELECTRONIC_NOTICE)
			.setDirection('Inbound')
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Amended W-2 for 2019 needed')
			.setAgencyInformation(objAgency1.Id)
			.build();
		list_Cases.add(objCase5);
		insert list_Cases;
	}

	/**
	 * @author       Elavarasan N
	 * @description  This methos is used to test SUI rate generation positive
	 **/
	@isTest
	static void testSUITaxRateTypeGeneration() {
		Agency_Information__c objAgency = [SELECT Id, Name FROM Agency_Information__c WHERE Name = 'CA-EDD'];
		List<Case> list_Cases = [SELECT Id, Agency_Information__c FROM Case WHERE Agency_Information__c = :objAgency.Id];
		List<Tax_Rate__c> list_TaxRates = [SELECT Id, ZP_Tax_Rate_Name__c FROM Tax_Rate__c WHERE Agency_Information__c = :objAgency.Id];

		// json with 2 positive tax rates
		String str_json_full_positive = '[{"TaxRate": 0.001,"TaxRateKey": "cc_ab_1"},{"TaxRate": 0.06,"TaxRateKey": "cc_ab_2"}]';

		// json with 1 positive and 1 negative tax rate
		String str_json_partial_positive = '[{"TaxRate": 0.001,"TaxRateKey": "cc_ab_1"},{"TaxRate": 0.06,"TaxRateKey": "tx_ab_1"}]';

		// json with 2 negative tax rates
		String str_json_negative = '[{"TaxRate": 0.001,"TaxRateKey": "tx_ab_1"},{"TaxRate": 0.06,"TaxRateKey": "tx_ab_2"}]';

		Test.startTest();
		List<Tax_Notice_Index__c> list_TNDC = new List<Tax_Notice_Index__c>();
		Tax_Notice_Index__c objTaxNotice1 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[0].Id)
			.setRecordTypeId(CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setAgencyInformation(list_Cases[0].Agency_Information__c)
			.setCompanyName('Full Positive')
			.setTaxNoticeFormNumber('DE8080')
			.setTaxNoticeType(CaseUtils.STR_SUI_FORM_TYPE)
			.setTaxRateJson(str_json_full_positive)
			.build();
		list_TNDC.add(objTaxNotice1);

		Tax_Notice_Index__c objTaxNotice2 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[1].Id)
			.setRecordTypeId(CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setAgencyInformation(list_Cases[1].Agency_Information__c)
			.setCompanyName('Partial Positive')
			.setTaxNoticeFormNumber('DE8080')
			.setTaxNoticeType(CaseUtils.STR_SUI_FORM_TYPE)
			.setTaxRateJson(str_json_partial_positive)
			.build();
		list_TNDC.add(objTaxNotice2);

		Tax_Notice_Index__c objTaxNotice3 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[2].Id)
			.setRecordTypeId(CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setAgencyInformation(list_Cases[2].Agency_Information__c)
			.setCompanyName('Full Negative')
			.setTaxNoticeFormNumber('DE8080')
			.setTaxNoticeType(CaseUtils.STR_SUI_FORM_TYPE)
			.setTaxRateJson(str_json_negative)
			.build();
		list_TNDC.add(objTaxNotice3);

		Tax_Notice_Index__c objTaxNotice4 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[3].Id)
			.setRecordTypeId(CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setAgencyInformation(list_Cases[3].Agency_Information__c)
			.setCompanyName('SUI Mismatch')
			.setTaxNoticeFormNumber('DE1111')
			.setTaxNoticeType(CaseUtils.STR_SUI_FORM_TYPE)
			.setTaxRateJson(str_json_full_positive)
			.build();
		list_TNDC.add(objTaxNotice4);

		Tax_Notice_Index__c objTaxNotice5 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[4].Id)
			.setRecordTypeId(CaseUtils.TAX_NOTICE_INDEX_RECTYPE_OCR)
			.setAgencyInformation(list_Cases[4].Agency_Information__c)
			.setCompanyName('Test')
			.setTaxNoticeFormNumber('FBED_CLIENT_MATCH')
			.setTaxNoticeType(CaseUtils.STR_SUI_FORM_TYPE)
			.setTaxRateJson(str_json_full_positive)
			.build();
		list_TNDC.add(objTaxNotice5);
		insert list_TNDC;
		Test.stopTest();

		for (Tax_Notice_Index__c objTaxNotice : [
			SELECT Id, Client_Name_Text__c, Client_Name__c, Case__r.Account.Name, Case__r.AccountId, Case__r.OCR_Status__c, Case__r.Status, Case__r.OCR_Message__c, Tax_Notice_Form_Number__c, (SELECT Id FROM Tax_Rate_Values__r) 
			FROM Tax_Notice_Index__c
		]) {
			if (objTaxNotice.Client_Name_Text__c == 'Full Positive') {
				System.assertEquals(2, objTaxNotice.Tax_Rate_Values__r.size(), '2 tax rates should be generated');
				System.assertNotEquals(objTaxNotice.Case__r.OCR_Message__c, System.Label.Tax_Res_Missing_Invalid_Tax_Rate, 'OCR Message should not be failed');
				System.assertNotEquals(objTaxNotice.Case__r.OCR_Status__c, CaseUtils.STR_IB_FAILED_STATUS, 'OCR Status not should say Failed');
			} else if (objTaxNotice.Client_Name_Text__c == 'Partial Positive') {
				System.assertEquals(1, objTaxNotice.Tax_Rate_Values__r.size(), '1 SUI rates should be generated');
				System.assertEquals(objTaxNotice.Case__r.Status, CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, 'No tax rates should be generated');
				System.assertEquals(objTaxNotice.Case__r.OCR_Message__c, System.Label.Tax_Res_Missing_Invalid_Tax_Rate, 'OCR Message should say SUI mismatch');
				System.assertEquals(objTaxNotice.Case__r.OCR_Status__c, CaseUtils.STR_IB_FAILED_STATUS, 'OCR Status should say Failed');
			} else if (objTaxNotice.Client_Name_Text__c == 'Full Negative') {
				System.assertEquals(null, null, 'No SUI rates should be generated');
				System.assertEquals(objTaxNotice.Case__r.Status, CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, 'No tax rates should be generated');
				System.assertEquals(objTaxNotice.Case__r.OCR_Message__c, System.Label.Tax_Res_Missing_Invalid_Tax_Rate, 'OCR Message should say Tax Rate mismatch');
				System.assertEquals(objTaxNotice.Case__r.OCR_Status__c, CaseUtils.STR_IB_FAILED_STATUS, 'OCR Status should say Failed');
			} else if (objTaxNotice.Client_Name_Text__c == 'SUI Mismatch') {
				System.assertEquals(null, null, 'No tax rates should be generated');
				System.assertEquals(objTaxNotice.Case__r.Status, CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, 'No tax rates should be generated');
				System.assertEquals(objTaxNotice.Case__r.OCR_Message__c, System.Label.Tax_Res_SUI_Form_Mismatch, 'OCR Message should say SUI mismatch');
				System.assertEquals(objTaxNotice.Case__r.OCR_Status__c, CaseUtils.STR_IB_FAILED_STATUS, 'OCR Status should say Failed');
			} else if (objTaxNotice.Tax_Notice_Form_Number__c == 'FBED_CLIENT_MATCH') {
				System.assertEquals(objTaxNotice.Client_Name__c, objTaxNotice.Case__r.AccountId, 'Client name not mapped for FBED case on OCR TNDC');
			}
		}
	}
}