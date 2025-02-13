/**
 * @name             TaxResChecklistControllerTest
 * @author           Pravesh Rana
 * @date             July-6-2021
 * @description      This class is used to test the "Code Coverage" of "TaxResChecklistController" class
 *                  which is related to "Tax Res" project.
 * @Covered class    TaxResChecklistController
 * @revisions        Date ------------ Name ------------ Comments
 **/
@isTest
public with sharing class TaxResChecklistControllerTest {
	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void handleTestData() {
		User_Role__c objUserRole = TestDataFactory.CreateUserRole('Account Specialist');
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);
		CaseTriggerHelper.skipTrigger = true;
		Case ObjCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		ObjCase.Account_Specialist__c = objUserRole.User__c;
		update ObjCase;
		CaseTriggerHelper.skipTrigger = false;

		List<Large_Scale_Issue__c> list_LSIs = new List<Large_Scale_Issue__c>();
		list_LSIs.add(new Large_Scale_Issue__c(Status__c = 'Verification', Name = 'LSI 1'));
		list_LSIs.add(new Large_Scale_Issue__c(Status__c = 'Done', Name = 'LSI 2'));
		insert list_LSIs;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validates "getLoggedInUserRoleDetails" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getLoggedInUserRoleDetailsTest() {
		Test.startTest();
		User_Role__c objUserRole = TaxResChecklistController.getLoggedInUserRoleDetails();
		System.assert(objUserRole != null);
		System.assert(objUserRole.Id != null);
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validates negative scenario of "getLoggedInUserRoleDetails" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getLoggedInUserRoleDetailsNegativeTest() {
		Test.startTest();
		List<User_Role__c> list_UserRoles = [SELECT Id FROM User_Role__c];
		if (list_UserRoles.size() > 0) {
			delete list_UserRoles;
		}

		User_Role__c objUserRole = TaxResChecklistController.getLoggedInUserRoleDetails();
		System.assert(objUserRole == null);
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validates "getEmailTemplateBody" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getEmailTemplateBodyTest() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM Case LIMIT 1];
		if (list_Cases.size() > 0) {
			Case objCase = list_Cases.get(0);
			List<EmailTemplate> list_objEmailTemp = TaxResChecklistController.getEmailTemplateBody('Blank_Return');
			System.assert(list_objEmailTemp.size() > 0);

			list_objEmailTemp = TaxResChecklistController.getEmailTemplateBody('');
			System.assert(list_objEmailTemp.size() == 0);
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : validates "TransferToLSI" Positive method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getCaseTranferToLSIMethodPositiveTest() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM Case LIMIT 1];
		if (list_Cases.size() > 0) {
			Case objCase = list_Cases.get(0);
			String strMessage = TaxResChecklistController.TransferToLSI(String.valueOf(objCase.Id));
			System.assert(strMessage == 'success');
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : validates "TransferToLSI" Negative method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void getCaseTranferToLSIMethodNegativeTest() {
		Test.startTest();
		String strMessage = TaxResChecklistController.TransferToLSI(null);
		System.assert(strMessage == null);
		Test.stopTest();
	}
}