/**
 * @description  Test class to check the functionality of UpdateAccountController
 * @author       Praveen Sethu
 **/
@isTest
public without sharing class UpdateAccountControllerTest {
	/**
	 * @description Positive test case to validate if account is updated successfully
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testUpdateAccountPositive() {
		// create test account
		AccountTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('86896897').build();
		insert objAcc;

		Test.startTest();
		UpdateAccountController.UpdateAccountResponse objResponse = UpdateAccountController.updateAccount(objAcc);
		Test.stopTest();

		System.assertEquals(true, objResponse.blnSuccess, 'Account was not updated');
	}

	/**
	 * @description Negative test case to return error message if account is not updated
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testUpdateAccountNegative() {
		// create test account and do not insert it
		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('86896897').build();

		// start test and update account without inserting it
		Test.startTest();
		UpdateAccountController.UpdateAccountResponse objResponse = UpdateAccountController.updateAccount(objAcc);
		Test.stopTest();

		System.assertEquals(false, objResponse.blnSuccess, 'Account was updated successfully');
	}
}