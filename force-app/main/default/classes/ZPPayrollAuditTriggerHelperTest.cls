@isTest
public class ZPPayrollAuditTriggerHelperTest {
	@testSetup
	static void testData() {
		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Acc1').setZpCompanyId('11111111111111').build();

		AccountTriggerHelper.skipTrigger = true;
		insert objAccount1;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount1.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@test.com')
			.setZpUserId('777777777777772')
			.build();

		ContactTriggerHelper.skipTrigger = true;
		insert objContact1;

		Payroll_Audit__c objPayrollAudit1 = new TestDataFactory.PayrollAuditBuilder()
			.setRecordTypeId('Enrollment')
			.setCompanyId(objAccount1.ZP_Company_ID__c)
			.setAdminUserId(objContact1.ZP_User_Id__c)
			.setState('TX')
			.setAgencyName('Texas Workforce Commision')
			.build();

		insert objPayrollAudit1;

		Quarterly_File__c objQuarterlyFile = new TestDataFactory.QuarterlyFileBuilder()
			.setPayrollAuditId(objPayrollAudit1.Id)
			.setCompanyId(objPayrollAudit1.Company_ID__c)
			.setState(objPayrollAudit1.State__c)
			.setQuarterlyWages(53543.00)
			.build();

		insert objQuarterlyFile;
	}

	@isTest
	static void testPayrollAuditCreateWOQuarterlyFile() {
		ZP_Payroll_Audit__c objZPPayrollAudit = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI State Addition')
			.setCompanyId('11111111111111')
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.build();

		Test.startTest();
		insert objZPPayrollAudit;
		Test.stopTest();

		Payroll_Audit__c objPayrollAudit = [
			SELECT Id, Company_ID__c, Company_Name__c, State__c, Agency_Name__c
			FROM Payroll_Audit__c
			WHERE Company_ID__c = :objZPPayrollAudit.Company_ID__c AND State__c = :objZPPayrollAudit.State__c AND Agency_Name__c = :objZPPayrollAudit.Agency_Name__c
		];

		System.assertNotEquals(null, objPayrollAudit);
		System.assertEquals(objZPPayrollAudit.Company_ID__c, objPayrollAudit.Company_ID__c);
		System.assertEquals(objZPPayrollAudit.Company_Name__c, objPayrollAudit.Company_Name__c);
		System.assertEquals(objZPPayrollAudit.State__c, objPayrollAudit.State__c);
		System.assertEquals(objZPPayrollAudit.Agency_Name__c, objPayrollAudit.Agency_Name__c);

		List<Quarterly_File__c> list_QuarterlyFile = [SELECT Id FROM Quarterly_File__c WHERE Payroll_Audit__c = :objPayrollAudit.Id AND State__c = :objPayrollAudit.State__c];

		System.assertEquals(0, list_QuarterlyFile.size());
	}

	@isTest
	static void testPayrollAuditCreateWithQuarterlyFile() {
		Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		Contact objContact = [SELECT Id, ZP_User_Id__c, FirstName, LastName, Email FROM Contact LIMIT 1];

		ZP_Payroll_Audit__c objZPPayrollAudit1 = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.setQuarterlyWages(12345.00)
            .setQuarterName('Quarter 1')
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		ZP_Payroll_Audit__c objZPPayrollAudit2 = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit 1')
			.setState('TX')
			.setAgencyName('Texas Workforce Commision')
			.setQuarterlyWages(22222.00)
			.setQuarterName('Quarter 1')
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		ZP_Payroll_Audit__c objZPPayrollAudit3 = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit 1')
			.setState('TX')
			.setAgencyName('Texas Workforce Commision')
			.setQuarterlyWages(33333.00)
			.setQuarterName('Quarter 2')
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		List<ZP_Payroll_Audit__c> list_zpPayrollAudit = new List<ZP_Payroll_Audit__c>{ objZPPayrollAudit1, objZPPayrollAudit2, objZPPayrollAudit3 };
		Test.startTest();
		insert list_zpPayrollAudit;
		Test.stopTest();

		List<Payroll_Audit__c> list_PayrollAudit = [
			SELECT Id, Company_ID__c, Company_Name__c, State__c, Account__c, Contact__c, Admin_First_Name__c, Admin_Last_Name__c, Admin_Email__c, Agency_Name__c
			FROM Payroll_Audit__c
			WHERE Company_ID__c = :objZPPayrollAudit1.Company_ID__c AND State__c IN ('CA', 'TX') AND Agency_Name__c IN ('CA-EDD', 'Texas Workforce Commision')
		];

		System.assertNotEquals(null, list_PayrollAudit);
		System.assertEquals(objZPPayrollAudit1.Company_ID__c, list_PayrollAudit[0].Company_ID__c);

		System.assertEquals(objAccount.Id, list_PayrollAudit[0].Account__c);
		System.assertEquals(objContact.Id, list_PayrollAudit[0].Contact__c);
		System.assertEquals(objContact.FirstName, list_PayrollAudit[0].Admin_First_Name__c);
		System.assertEquals(objContact.LastName, list_PayrollAudit[0].Admin_Last_Name__c);
		System.assertEquals(objContact.Email, list_PayrollAudit[0].Admin_Email__c);

		List<Quarterly_File__c> list_QuarterlyFile = [
			SELECT Id, Payroll_Audit__c, Quarterly_Taxes__c
			FROM Quarterly_File__c
			WHERE Payroll_Audit__c = :list_PayrollAudit[0].Id AND State__c = :list_PayrollAudit[0].State__c
		];

		System.assertNotEquals(0, list_QuarterlyFile.size());
		System.assertEquals(list_QuarterlyFile[0].Payroll_Audit__c, list_PayrollAudit[0].Id);
	}


	@isTest
	static void testPayrollAuditCreateWithUniqueAgency() {
		Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		Contact objContact = [SELECT Id, ZP_User_Id__c, FirstName, LastName, Email FROM Contact LIMIT 1];

		ZP_Payroll_Audit__c objZPPayrollAudit1 = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.setQuarterlyWages(12345.00)
            .setQuarterName('Quarter 1')
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		ZP_Payroll_Audit__c objZPPayrollAudit2 = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit 1')
			.setState('TX')
			.setAgencyName('Texas Workforce Commision')
			.setQuarterlyWages(22222.00)
			.setQuarterName('Quarter 1')
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		ZP_Payroll_Audit__c objZPPayrollAudit3 = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit 1')
			.setState('TX')
			.setAgencyName('Texas Agency')
			.setQuarterlyWages(33333.00)
			.setQuarterName('Quarter 2')
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		List<ZP_Payroll_Audit__c> list_zpPayrollAudit = new List<ZP_Payroll_Audit__c>{ objZPPayrollAudit1, objZPPayrollAudit2, objZPPayrollAudit3 };
		Test.startTest();
		insert list_zpPayrollAudit;
		Test.stopTest();

		List<Payroll_Audit__c> list_PayrollAudit = [
			SELECT Id, Company_ID__c, Company_Name__c, State__c, Account__c, Contact__c, Admin_First_Name__c, Admin_Last_Name__c, Admin_Email__c, Agency_Name__c
			FROM Payroll_Audit__c
			WHERE Company_ID__c = :objZPPayrollAudit1.Company_ID__c AND State__c IN ('CA', 'TX') AND Agency_Name__c IN ('CA-EDD', 'Texas Workforce Commision', 'Texas Agency')
		];

		System.assertNotEquals(null, list_PayrollAudit);
		System.assertEquals(3, list_PayrollAudit.size());
		System.assertEquals(objZPPayrollAudit1.Company_ID__c, list_PayrollAudit[0].Company_ID__c);

		List<Quarterly_File__c> list_QuarterlyFile = [
			SELECT Id, Payroll_Audit__c, Quarterly_Taxes__c
			FROM Quarterly_File__c
			WHERE Payroll_Audit__c = :list_PayrollAudit[0].Id AND State__c = :list_PayrollAudit[0].State__c
		];

		System.assertNotEquals(0, list_QuarterlyFile.size());
		System.assertEquals(list_QuarterlyFile[0].Payroll_Audit__c, list_PayrollAudit[0].Id);
	}

	@isTest
	static void testSkipTrigger() {
		ZP_Payroll_Audit__c objZPPayrollAudit = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('WH State Addition')
			.setCompanyId('11111111111111')
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.build();

		Test.startTest();
		ZPPayrollAuditTriggerHelper.skipTrigger = true;
		insert objZPPayrollAudit;
		Test.stopTest();

		List<Payroll_Audit__c> list_PayrollAudit = [
			SELECT Id, Company_ID__c, Company_Name__c, State__c, Agency_Name__c
			FROM Payroll_Audit__c
			WHERE Company_ID__c = :objZPPayrollAudit.Company_ID__c AND State__c = :objZPPayrollAudit.State__c AND Agency_Name__c = :objZPPayrollAudit.Agency_Name__c
		];

		System.assertEquals(0, list_PayrollAudit.size());
	}

	@isTest
	static void testInsertException() {
		ZP_Payroll_Audit__c objZPPayrollAudit = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('WH State Addition')
			.setCompanyId('11111111111111')
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.build();

		Test.startTest();
		ZPPayrollAuditTriggerHelper.skipTrigger = false;
		ZPPayrollAuditTriggerHandler.blnTestException = true;
		insert objZPPayrollAudit;
		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'ZPPayrollAuditTriggerHandler'];

		System.assertEquals(1, list_Exceptions.size());
	}

	@isTest
	static void testPayrollAuditCreateWithZeroQuarterlyValues() {
		Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		Contact objContact = [SELECT Id, ZP_User_Id__c, FirstName, LastName, Email FROM Contact LIMIT 1];

		ZP_Payroll_Audit__c objZPPayrollAudit = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('WH Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.setQuarterlyWages(0.00)
			.setQuarterlyGrossWages(0.00)
			.setQuarterlySubjectWages(0.00)
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		Test.startTest();
		insert objZPPayrollAudit;
		Test.stopTest();

		Payroll_Audit__c objPayrollAudit = [
			SELECT Id, Company_ID__c, Company_Name__c, State__c, Agency_Name__c
			FROM Payroll_Audit__c
			WHERE Company_ID__c = :objZPPayrollAudit.Company_ID__c AND State__c = :objZPPayrollAudit.State__c AND Agency_Name__c = :objZPPayrollAudit.Agency_Name__c
		];

		System.assertNotEquals(null, objPayrollAudit);
		System.assertEquals(objZPPayrollAudit.Company_ID__c, objPayrollAudit.Company_ID__c);
		System.assertEquals(objZPPayrollAudit.Company_Name__c, objPayrollAudit.Company_Name__c);
		System.assertEquals(objZPPayrollAudit.State__c, objPayrollAudit.State__c);
		System.assertEquals(objZPPayrollAudit.Agency_Name__c, objPayrollAudit.Agency_Name__c);

		List<Quarterly_File__c> objQuarterlyFileLst = [SELECT Id FROM Quarterly_File__c WHERE Payroll_Audit__c = :objPayrollAudit.Id AND State__c = :objPayrollAudit.State__c];

		System.assertEquals(0, objQuarterlyFileLst.size());
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : test update scenario when updating payroll audit no net new change on record
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testPayrollAuditUpdate() {
		Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		Contact objContact = [SELECT Id, ZP_User_Id__c, FirstName, LastName, Email FROM Contact LIMIT 1];

		ZP_Payroll_Audit__c objZPPayrollAudit = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('WH Onboarding')
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.setQuarterlyWages(0.00)
			.setQuarterlyGrossWages(0.00)
			.setQuarterlySubjectWages(0.00)
			.setAdminUserId(objContact.ZP_User_Id__c)
			.build();

		Test.startTest();
		insert objZPPayrollAudit;
		objZPPayrollAudit.Company_Name__c = 'Test Payroll Audit Update';
		update objZPPayrollAudit;
		Test.stopTest();

		List<Payroll_Audit__c> list_PayrollAudits = [
			SELECT Id, Company_ID__c, Company_Name__c, State__c, Agency_Name__c
			FROM Payroll_Audit__c
			WHERE Company_ID__c = :objZPPayrollAudit.Company_ID__c AND State__c = :objZPPayrollAudit.State__c AND Agency_Name__c = :objZPPayrollAudit.Agency_Name__c
		];

		System.assertNotEquals(null, list_PayrollAudits.get(0));
		System.assertEquals(list_PayrollAudits.get(0).Company_ID__c, list_PayrollAudits.get(0).Company_ID__c);
		System.assertEquals(list_PayrollAudits.get(0).Company_Name__c, list_PayrollAudits.get(0).Company_Name__c);
		System.assertEquals(list_PayrollAudits.get(0).State__c, list_PayrollAudits.get(0).State__c);

		// update context will not update any information on Payroll Audits already created. Its just built to reprocess errorred out records.
		System.assertNotEquals('Test Payroll Audit Update', list_PayrollAudits.get(0).Company_Name__c);
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : test exception handling in update scenario
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/	
	@isTest
	static void testUpdateException() {
		ZP_Payroll_Audit__c objZPPayrollAudit = new TestDataFactory.ZPPayrollAuditBuilder()
			.setType('SUI State Addition')
			.setCompanyId('11111111111111')
			.setCompanyName('Test Payroll Audit')
			.setState('CA')
			.setAgencyName('CA-EDD')
			.build();

		Test.startTest();
		insert objZPPayrollAudit;

		ZPPayrollAuditTriggerHandler.blnTestException = true;
		objZPPayrollAudit.Company_Name__c = 'Test Payroll Audit Update';
		update objZPPayrollAudit;
		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c];

		System.assertEquals(true, list_Exceptions.size() > 0);
	}
}