/**
 * @name         : PayrollAuditTriggerHelperTest
 * @author       : Debasmita Rawooth
 * @date         : 07-28-2021
 * @description  : Test Class for PayrollAuditTriggerHelper
 * @test classes : NA
 **/
@isTest
public class PayrollAuditTriggerHelperTest {
	@testSetup
	static void testData() {
		List<Account> listAccounts;
		List<Contact> listContacts;

		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc1')
			.setZpCompanyId('11111111111111')
			.build();

		Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc2')
			.setZpCompanyId('22222222222222')
			.build();

		listAccounts = new List<Account>{ objAccount1, objAccount2 };
		AccountTriggerHelper.skipTrigger = true;
		insert listAccounts;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(listAccounts[0].Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@test.com')
			.setZpUserId('777777777777772')
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(listAccounts[1].Id)
			.setFirstName('First Name2')
			.setLastName('Last Name2')
			.setEmail('testuser2@test.com')
			.setZpUserId('777777777777778')
			.setInactiveZpUser(true)
			.build();

		listContacts = new List<Contact>{ objContact1, objContact2 };
		ContactTriggerHelper.skipTrigger = true;
		insert listContacts;
	}

	@isTest
	static void testInsertWithoutValues() {
		Payroll_Audit__c objPayrollAudit1 = new TestDataFactory.PayrollAuditBuilder()
			.setRecordTypeId('Enrollment')
			.build();

		Test.startTest();
		insert objPayrollAudit1;
		Test.stopTest();

		Payroll_Audit__c objPayrollAuditAssert = [
			SELECT Id, Account__c, Contact__c, Admin_First_Name__c, Admin_Last_Name__c, Admin_Email__c
			FROM Payroll_Audit__c
			WHERE Id = :objPayrollAudit1.Id
		];
		System.assertEquals(null, objPayrollAuditAssert.Account__c);
		System.assertEquals(null, objPayrollAuditAssert.Contact__c);
		System.assertEquals(null, objPayrollAuditAssert.Admin_First_Name__c);
		System.assertEquals(null, objPayrollAuditAssert.Admin_Last_Name__c);
		System.assertEquals(null, objPayrollAuditAssert.Admin_Email__c);
	}

	@isTest
	static void testInsertWithValues() {
		Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		Contact objContact = [SELECT Id, ZP_User_Id__c, FirstName, LastName, Email FROM Contact LIMIT 1];

		Payroll_Audit__c objPayrollAudit1 = new TestDataFactory.PayrollAuditBuilder()
			.setRecordTypeId('Enrollment')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		Test.startTest();
		insert objPayrollAudit1;
		Test.stopTest();

		Payroll_Audit__c objPayrollAuditAssert = [
			SELECT Id, Account__c, Contact__c, Admin_First_Name__c, Admin_Last_Name__c, Admin_Email__c
			FROM Payroll_Audit__c
			WHERE Id = :objPayrollAudit1.Id
		];
		System.assertEquals(objAccount.Id, objPayrollAuditAssert.Account__c);
		System.assertEquals(objContact.Id, objPayrollAuditAssert.Contact__c);
		System.assertEquals(objContact.FirstName, objPayrollAuditAssert.Admin_First_Name__c);
		System.assertEquals(objContact.LastName, objPayrollAuditAssert.Admin_Last_Name__c);
		System.assertEquals(objContact.Email, objPayrollAuditAssert.Admin_Email__c);
	}

	@isTest
	static void testUpdateOfValues() {
		List<Account> list_Accounts = [SELECT Id, ZP_Company_ID__c FROM Account ORDER BY ZP_Company_ID__c];
		List<Contact> list_Contacts = [
			SELECT Id, ZP_User_Id__c, FirstName, LastName, Email
			FROM Contact
			ORDER BY ZP_User_Id__c
		];

		Payroll_Audit__c objPayrollAudit1 = new TestDataFactory.PayrollAuditBuilder()
			.setRecordTypeId('Enrollment')
			.setCompanyId(list_Accounts[0].ZP_Company_ID__c)
			.setAdminUserId(list_Contacts[0].ZP_User_Id__c)
			.build();

		Test.startTest();
		insert objPayrollAudit1;

		objPayrollAudit1.company_id__c = list_Accounts[1].ZP_Company_ID__c;
		objPayrollAudit1.admin_user_id__c = list_Contacts[1].ZP_User_Id__c;

		update objPayrollAudit1;
		Test.stopTest();

		Payroll_Audit__c objPayrollAuditAssert = [
			SELECT Id, Account__c, Contact__c, Admin_First_Name__c, Admin_Last_Name__c, Admin_Email__c
			FROM Payroll_Audit__c
			WHERE Id = :objPayrollAudit1.Id
		];
		System.assertEquals(list_Accounts[1].Id, objPayrollAuditAssert.Account__c);
		System.assertEquals(list_Contacts[1].Id, objPayrollAuditAssert.Contact__c);
		System.assertNotEquals(list_Accounts[0].Id, objPayrollAuditAssert.Account__c, 'Account was not updated');
		System.assertNotEquals(list_Contacts[0].Id, objPayrollAuditAssert.Contact__c, 'Contact was not updated');
		System.assertEquals(list_Contacts[1].FirstName, objPayrollAuditAssert.Admin_First_Name__c);
		System.assertEquals(list_Contacts[1].LastName, objPayrollAuditAssert.Admin_Last_Name__c);
		System.assertEquals(list_Contacts[1].Email, objPayrollAuditAssert.Admin_Email__c);
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:    Test if Payroll Audit Trigger is Skipped
	 * @parm:           NA
	 * @return:         NA
	 */
	@isTest
	static void testSkipTrigger() {
		List<Account> list_Accounts = [SELECT Id, ZP_Company_ID__c FROM Account ORDER BY ZP_Company_ID__c];
		List<Contact> list_Contacts = [
			SELECT Id, ZP_User_Id__c, FirstName, LastName, Email
			FROM Contact
			ORDER BY ZP_User_Id__c
		];

		Payroll_Audit__c objPayrollAudit1 = new TestDataFactory.PayrollAuditBuilder()
			.setRecordTypeId('Enrollment')
			.setCompanyId(list_Accounts[0].ZP_Company_ID__c)
			.setAdminUserId(list_Contacts[0].ZP_User_Id__c)
			.build();

		Test.startTest();
		PayrollAuditTriggerHelper.skipTrigger = true;
		insert objPayrollAudit1;

		objPayrollAudit1.company_id__c = list_Accounts[1].ZP_Company_ID__c;
		objPayrollAudit1.admin_user_id__c = list_Contacts[1].ZP_User_Id__c;

		update objPayrollAudit1;
		Test.stopTest();

		Payroll_Audit__c objPayrollAuditAssert = [
			SELECT Id, Account__c, Contact__c, Admin_First_Name__c, Admin_Last_Name__c, Admin_Email__c
			FROM Payroll_Audit__c
			WHERE Id = :objPayrollAudit1.Id
		];
		System.assertNotEquals(list_Accounts[1].Id, objPayrollAuditAssert.Account__c);
	}
}