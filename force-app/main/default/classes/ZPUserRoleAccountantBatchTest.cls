/**
 * @name         : ZPUserRoleAccountantBatchTest
 * @author       : Praveen Sethu
 * @date         : 03-24-2021
 * @description  : Tests ZPUserRoleAccountantBatch class that updates zp user role accountant contact's record type
 **/
@isTest
public with sharing class ZPUserRoleAccountantBatchTest {
	@testSetup
	static void setUpData() {
		Account objResellerAccount = TestUtils.createAccount(AccountUtil.RESELLER_ACCOUNT_RT_ID, 'Reseller Account', false);
		objResellerAccount.ZP_Firm_Id__c = '900';
		insert objResellerAccount;

		Account objCompanyAccount = TestUtils.createAccount(AccountUtil.COMPANY_ACCOUNT_RT_ID, 'Company Account', true);

		Contact objContact1 = TestUtils.createContact(objCompanyAccount.Id, 'First Name', 'Last Name', 'zprole@accountant.com', true);

		Contact objContact2 = TestUtils.createContact(null, 'First Name', 'Last Name', 'zprole@invalidcontact.com', true);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Company Contact associated with Accountant ZP User Roles is updated to Reseller Account
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testAccountantContact() {
		Test.startTest();
		ZP_User__c objUser = new ZP_User__c(Name = 'Test User', Id__c = '98765', Email__c = 'zprole@accountant.com', Created_At__c = System.now(), Updated_At__c = System.now());
		insert objUser;

		Contact objContactUpdate = [SELECT Id FROM Contact WHERE Email = 'zprole@accountant.com'];
		ZPUserRoleTriggerHelper.skipTrigger = true;
		ZP_User_Role__c objRole = new ZP_User_Role__c(
			Type__c = 'Role::Accountant',
			Id__c = '6578383',
			User_Id__c = objUser.Id__c,
			Accounting_Firm_Id__c = '900',
			Contact__c = objContactUpdate.Id,
			Processing_State__c = 'Processed'
		);
		insert objRole;

		// Dynamically scheduling jobs for next year
		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;
		ZPUserRoleAccountantScheduler objScheduler = new ZPUserRoleAccountantScheduler();
		String strJobId = System.schedule('Test ZP User Role Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		ZP_User_Role__c objRoleAssert = [SELECT Id, Contact__c, Contact__r.AccountId, Contact__r.RecordTypeId FROM ZP_User_Role__c WHERE Id = :objRole.Id];

		Account objResellerAccount = [SELECT Id FROM Account WHERE ZP_Firm_Id__c = '900'];
		System.assertEquals(ContactUtil.RESELLER_CONTACT_RT_ID, objRoleAssert.Contact__r.RecordTypeId);
		System.assertEquals(objResellerAccount.Id, objRoleAssert.Contact__r.AccountId);

		Contact objInvalidContact = [SELECT Id FROM Contact WHERE Email = 'zprole@invalidcontact.com'];
		System.assertNotEquals(objRoleAssert.Contact__c, objInvalidContact.Id);
	}
}