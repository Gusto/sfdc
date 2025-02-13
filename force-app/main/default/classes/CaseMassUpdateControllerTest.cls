/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CaseMassUpdateControllerTest {
	@testSetup
	static void testData() {
		Account acc = TestUtility.CompanyAccount();
		list<case> toInsertCaseList = new List<Case>();

		test.startTest();
		for (integer counter = 1; counter < 5; counter++) {
			Case cse = new Case();
			cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
			cse.AccountId = acc.Id;
			cse.Subject = 'Test Payroll care' + counter;
			cse.Description = 'Test';
			cse.Type = 'QLE';
			toInsertCaseList.add(cse);
		}

		for (integer counter = 1; counter < 5; counter++) {
			Case cse = new Case();
			cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care');
			cse.AccountId = acc.Id;
			cse.Subject = 'Test Benefit Care' + counter;
			cse.Description = 'Test';
			cse.Type = 'Cobra';
			toInsertCaseList.add(cse);
		}

		for (integer counter = 1; counter < 5; counter++) {
			Case cse = new Case();
			cse.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
			cse.AccountId = acc.Id;
			cse.Subject = 'Test Tax Res' + counter;
			cse.Description = 'Test';
			cse.Type = 'Tax Res';
			toInsertCaseList.add(cse);
		}

		if (toInsertCaseList.size() > 0) {
			insert toInsertCaseList;
		}

		list<Case_RecordType_FieldSet_Setting__c> toInsertCustomSettingRecList = new List<Case_RecordType_FieldSet_Setting__c>();

		Case_RecordType_FieldSet_Setting__c csPayrolCare = new Case_RecordType_FieldSet_Setting__c();
		csPayrolCare.Field_Set_API_Name__c = 'Payroll_care_Mass_Update';
		csPayrolCare.Name = 'Payroll Care';
		toInsertCustomSettingRecList.add(csPayrolCare);

		Case_RecordType_FieldSet_Setting__c csBenefitsCare = new Case_RecordType_FieldSet_Setting__c();
		csBenefitsCare.Field_Set_API_Name__c = 'Benefit_Care_Mass_Update';
		csBenefitsCare.Name = 'Benefits Care';
		toInsertCustomSettingRecList.add(csBenefitsCare);

		Case_RecordType_FieldSet_Setting__c csTaxRes = new Case_RecordType_FieldSet_Setting__c();
		csTaxRes.Field_Set_API_Name__c = 'Tax_Res_Mass_Update';
		csTaxRes.Name = 'Tax Res';
		toInsertCustomSettingRecList.add(csTaxRes);

		insert toInsertCustomSettingRecList;
		test.stopTest();
	}

	@isTest
	static void caseMassUpdateTest() {
		list<Case> caseList = [SELECT id, RecordTypeId FROM Case];

		apexPages.StandardSetController sc = new apexPages.StandardSetController(caseList);
		sc.setSelected(caseList);
		CaseMassUpdateController controller = new CaseMassUpdateController(sc);
		controller.toUpdateCase.Type = 'Otter Case';
		controller.getCaseReasons();
		controller.getlsiList();
		string caseRecordTypeId = controller.recordTypeNameIdMap.get(controller.selectedRecordType);
		controller.toUpdateCase.Type = 'Otter Case';
		controller.massUpdate();

		caseList = [SELECT id, type FROM Case WHERE RecordTypeId = :caseRecordTypeId];
		system.assert(controller.selectedCaseList.size() == caseList.size()); //mass update confirmation check
	}
}