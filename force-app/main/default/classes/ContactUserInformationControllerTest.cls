/**
 * @name         : ContactUserInformationControllerTest
 * @author       : Ankit CS
 * @date         : 11-10-2021
 * @description  : Test class for ContactUserInformationController
 **/
@isTest
private class ContactUserInformationControllerTest {
	/**
	 * @Author      : Ankit CS
	 * @Description : Test data setup method
	 **/
	@testSetup
	static void setUp() {
		Test.startTest();

		List<Account> list_Accounts = new List<Account>();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Reseller').setName('Test Company').setZPFirmId('9090909090909009').setZPCompanyId('00000000000000').build();
		list_Accounts.add(objResellerAccount);

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('ContactUserInfo User')
			.setZPFirmId('90909090909090091')
			.setZPCompanyId('000000000000001')
			.build();
		list_Accounts.add(objCompanyAccount);

		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.setName('Test Company')
			.build();

		insert objZPCompany;

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setCustomId('777777777777777')
			.setEmail('testuser@gmail.com')
			.setLastSignInAt(System.now())
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();

		insert objZPUser;

		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('777777777777777')
			.setCustomId('343434343434')
			.setCompanyId('00000000000000')
			.setAccFirmId('9090909090909009')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setType('Role::Accountant')
			.setUserPermission('No Access')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('777777777777777')
			.setCustomId('2222222222222')
			.setAccFirmId('9090909090909009')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setType('Role::Employee')
			.setUserPermission('No Access')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('777777777777777')
			.setCustomId('2222222222233')
			.setCompanyId('11111111111111')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setUserPermission('No Access')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('777777777777777')
			.setCustomId('2222222222244')
			.setCompanyId('11111111111111')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setType('Role::Signatory')
			.setUserPermission('No Access')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		insert list_ZPUserRoles;

		Case objCase = new TestDataFactory.CaseBuilder().setRecordTypeId('Payroll Care').setAccountId(objResellerAccount.Id).setSubject('Test').setDescription('Test').setType('QLE').build();

		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for getUserInformation()
	 **/
	@isTest
	static void testGetUserInformation() {
		List<Case> list_Cases = [SELECT Id, AccountId FROM Case];
		ApexPages.currentPage().getParameters().put('email', 'testuser@gmail.com');
		ContactUserInformationController objController = new ContactUserInformationController();
		objController.caseId = list_Cases.get(0).Id;
		objController.userId = '777777777777777';
		objController.email = 'testuser@gmail.com';
		Test.startTest();

		ContactUserInformationController.userRoleInformation objWrapper = objController.getUserInformation();

		Test.stopTest();
		System.assert(objWrapper.companyUserRoleMap.keySet().contains('00000000000000'), 'Map should contain the key.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for getTitleString()
	 **/
	@isTest
	static void testGetTitleString() {
		Test.startTest();

		ContactUserInformationController objController = new ContactUserInformationController();
		String strTitle = objController.getTitleString('test_test_test');

		Test.stopTest();
		System.assertEquals('Test Test Test', strTitle, 'Title should match.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for updateRerouteAccount()
	 **/
	@isTest
	static void testUpdateRerouteAccount() {
		List<Case> list_Cases = [SELECT Id, AccountId FROM Case];
		ApexPages.currentPage().getParameters().put('email', 'testuser@gmail.com');
		ContactUserInformationController objController = new ContactUserInformationController();
		objController.caseId = list_Cases.get(0).Id;
		objController.userId = '777777777777777';
		objController.email = 'testuser@gmail.com';
		objController.company_FirmId = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '000000000000001' LIMIT 1].Id;
		Test.startTest();

		objController.updateRerouteAccount();

		Test.stopTest();
		list_Cases = [SELECT Id, AccountId FROM Case];
		System.assertEquals(list_Cases.get(0).AccountId, objController.company_FirmId, 'Account Id should match.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for updateAccount()
	 **/
	@isTest
	static void testUpdateAccount() {
		List<Case> list_Cases = [SELECT Id, AccountId FROM Case];
		ApexPages.currentPage().getParameters().put('email', 'testuser@gmail.com');
		ContactUserInformationController objController = new ContactUserInformationController();
		objController.caseId = list_Cases.get(0).Id;
		objController.userId = '777777777777777';
		objController.email = 'testuser@gmail.com';
		objController.company_FirmId = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '000000000000001' LIMIT 1].Id;
		Test.startTest();

		objController.updateAccount();

		Test.stopTest();
		list_Cases = [SELECT Id, AccountId FROM Case];
		System.assertEquals(list_Cases.get(0).AccountId, objController.company_FirmId, 'Account Id should match.');
	}
}