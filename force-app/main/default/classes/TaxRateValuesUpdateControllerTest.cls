/**
 * @name         TaxRateValuesUpdateControllerTest
 * @author       Pravesh Rana
 * @date         Nov 4 2022
 * @description  Test class for TaxRateValuesUpdateController class.
 **/
@isTest
public with sharing class TaxRateValuesUpdateControllerTest {
	static final String CASE_STATUS_READYFORDATACAPTURE = 'Ready for Data Capture';
	static final String AUTOMATION_STATUS_COMPLETED = 'Completed';

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void handleTestData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);

		List<Case> list_cases = new List<Case>();
		List<Tax_Notice_Index__c> list_NoticeIndex = new List<Tax_Notice_Index__c>();

		Agency_Information__c objAgency = new Agency_Information__c(Name = 'test1', Active__c = true);
		insert objAgency;

		Tax_Rate__c objRates = new Tax_Rate__c(Agency_Information__c = objAgency.Id, Name = 'Rate1', ZP_Tax_Rate_Name__c = 'Rate1');
		insert objRates;

		Case objCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase.ContactId = objContact.Id;
		objCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS;
		objCase.Agency_Information__c = objAgency.Id;
		list_cases.add(objCase);

		Case objCase2 = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase2.ContactId = objContact.Id;
		objCase2.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS;
		objCase2.Notice_Type__c = 'Credit listed or refund check';
		list_cases.add(objCase2);

		CaseTriggerHelper.skipTrigger = true;
		update list_cases;

		Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(Case__c = list_Cases[0].Id);
		list_NoticeIndex.add(objNotice);

		Tax_Notice_Index__c objNotice2 = new Tax_Notice_Index__c(Case__c = list_Cases[1].Id);
		list_NoticeIndex.add(objNotice2);

		insert list_NoticeIndex;

		Tax_Rate_Values__c objValues = new Tax_Rate_Values__c(Rate_Decimal__c = 1, Tax_Notice_Index__c = objNotice.Id, Tax_Rate_Type__c = objRates.Id);
		insert objValues;
	}

	@isTest
	static void getTaxRateValuesTest() {
		List<Case> list_Case = [SELECT Id FROM Case WHERE Agency_Information__c != NULL];

		Test.startTest();
		List<Tax_Rate_Values__c> list_Values = TaxRateValuesUpdateController.getTaxRateValues(list_Case[0].Id);
		System.assert(list_Values.size() > 0);
		Test.stopTest();
	}

	@isTest
	static void getFieldsTest() {
		Test.startTest();
		List<String> list_Values = TaxRateValuesUpdateController.getFields();
		System.assert(list_Values.size() > 0);
		Test.stopTest();
	}
}