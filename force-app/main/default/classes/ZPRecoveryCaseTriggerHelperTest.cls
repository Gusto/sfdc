@isTest
private class ZPRecoveryCaseTriggerHelperTest {
	@testsetup
	static void setup() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		List<Account> list_Accounts = new List<Account>();

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyId('0000999900001').setName('Test Account').build();
		list_Accounts.add(objAccount);

		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId('Reseller').setZPCompanyId('1234512345').setName('Test Reseller Account').build();
		list_Accounts.add(objAccount2);

		Account objAccount3 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyId('7757616923607181').setName('Test Account').build();
		list_Accounts.add(objAccount3);

		insert list_Accounts;

		//Creating ZP User
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setEmail('test.test@test.com')
			.setCreatedAt(Date.newInstance(2016, 11, 9))
			.setUpdatedAt(Date.newInstance(2016, 12, 9))
			.setLastSignInAt(Date.newInstance(2018, 1, 1))
			.setCustomId('1111111111')
			.build();
		insert objZPUser;

		List<Contact> list_Contacts = new List<Contact>();
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setPhone('999999123')
			.setFirstName('Test Contact')
			.setLastName('ZPNachaEntry')
			.setAccountId(objAccount.Id)
			.setEmail('ZPNachaEntry@gusto.com')
			.setZPUserId('000099990000')
			.build();
		list_Contacts.add(objContact);

		Contact objContactTwo = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setPhone('9999991234')
			.setFirstName('Test Contact Two')
			.setLastName('ZPNachaEntryTwo')
			.setAccountId(objAccount.Id)
			.setEmail('ZPNachaEntryTwo@gusto.com')
			.setZPUserId('000099991111')
			.build();
		list_Contacts.add(objContactTwo);

		Contact objContact3 = new TestDataFactory.ContactBuilder().setRecordTypeId('Company').setLastName('Test name').setAccountId(objAccount3.Id).build();
		list_Contacts.add(objContact3);

		Contact objContact4 = new TestDataFactory.ContactBuilder().setRecordTypeId('Company').setLastName('Test name').setAccountId(objAccount3.Id).build();
		list_Contacts.add(objContact4);

		insert list_Contacts;

		List<AccountContactRole> list_AccContactRoles = new List<AccountContactRole>();

		AccountContactRole objAccContactRole1 = new AccountContactRole(AccountId = objAccount3.Id, ContactId = objContact3.Id, Role = 'Payroll Admin');
		list_AccContactRoles.add(objAccContactRole1);

		AccountContactRole objAccContactRole2 = new AccountContactRole(AccountId = objAccount3.Id, ContactId = objContact4.Id, Role = 'Payroll Admin');
		list_AccContactRoles.add(objAccContactRole2);

		insert list_AccContactRoles;

		Rolesets__c objRoleSet = new Rolesets__c(Name = 'Test Role Set', Components__c = 'ZPRecoveryCaseTriggerHelper', Roles__c = 'Payroll Admin', Roleset_Name__c = 'Company');
		insert objRoleSet;

		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder().setUserId('1111111111').setCompanyId('0000999900001').setType('Role::PayrollAdmin').build();
		objZPUserRole.Company_Account__c = objAccount.Id;
		objZPUserRole.Contact__c = objContact.Id;
		list_ZPUserRoles.add(objZPUserRole);

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder().setUserId('1111111111').setAccFirmId('1234512345').setType('Role::PayrollAdmin').build();
		objZPUserRole2.Accounting_Firm_Account__c = objAccount2.Id;
		objZPUserRole2.Contact__c = objContact.Id;
		list_ZPUserRoles.add(objZPUserRole2);

		insert list_ZPUserRoles;

		List<Case> list_Cases = new List<Case>();

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Recovery Cases')
			.setType('Recovery')
			.setSubject('Test')
			.setOrigin('Panda')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setDescription('Test')
			.setEventType(ZPRecoveryCaseTriggerHelper.PAYROLL)
			.setIntegrationKey('zenpayroll-payroll-0101010101010')
			.build();
		list_Cases.add(objCase);

		objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Recovery Cases')
			.setType('Recovery')
			.setSubject('Test ContractorPayment')
			.setOrigin('Panda')
			.setAccountId(objAccount.Id)
			.setContactId(objContactTwo.Id)
			.setDescription('Test ContractorPayment')
			.setEventType(ZPRecoveryCaseTriggerHelper.PAYROLL)
			.setIntegrationKey('zenpayroll-contractor-payment-123456')
			.build();
		list_Cases.add(objCase);

		objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Recovery Cases')
			.setType('Recovery')
			.setSubject('Test InternationalContractorPayment')
			.setOrigin('Panda')
			.setAccountId(objAccount.Id)
			.setDescription('Test InternationalContractorPayment')
			.setEventType(ZPRecoveryCaseTriggerHelper.PAYROLL)
			.setIntegrationKey('zenpayroll-international-contractor-payment-1234567')
			.setBankErrorCode('1234')
			.build();
		list_Cases.add(objCase);

		objCase = new TestDataFactory.CaseBuilder().setRecordTypeId('Recovery Cases').setSubject('Test').setAccountId(objAccount3.Id).build();
		objCase.Recovery_Case_Id__c = '175750090';
		list_Cases.add(objCase);

		insert list_Cases;

		Nacha_Entry_Return__c objNachaReturn = new Nacha_Entry_Return__c(Event_ID__c = '999888777', Error_Code__c = 'TestR01Test', First_Debit_Failure_Nacha__c = false);
		insert objNachaReturn;

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		CaseTriggerHelper.skipTrigger = false;
	}

	static testMethod void insertZPRecoveryRecord() {
		ZPRecoveryCaseTriggerHelper.queue = true;
		ZP_Recovery_Case__c objZPRecoveryCase = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1201',
			Company_Id__c = '7757616923607181',
			Event_Type__c = ZPRecoveryCaseTriggerHelper.PAYROLL,
			Created_At_Date__c = System.Today(),
			Event_Check_Date__c = System.Today(),
			Last_Processed__c = System.Today(),
			Recovery_Case_Id__c = '175750090'
		);
		insert objZPRecoveryCase;

		objZPRecoveryCase.Initial_Recovery_Amount__c = 200;
		update objZPRecoveryCase;

		System.assertEquals(1, [SELECT COUNT() FROM ZP_Recovery_Case__c]);
		System.assertEquals(4, [SELECT COUNT() FROM Case]);

		delete objZPRecoveryCase;

		undelete objZPRecoveryCase;
	}

	static testMethod void queueFalseZPRecoveryRecord() {
		ZPRecoveryCaseTriggerHelper.queue = false;

		ZP_Recovery_Case__c objZPRecoveryCase = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1201',
			Company_Id__c = '775761692360',
			Event_Type__c = ZPRecoveryCaseTriggerHelper.PAYROLL,
			Event_Check_Date__c = System.Today(),
			Created_At_Date__c = System.Today(),
			Recovery_Case_Id__c = '175750090',
			Last_Processed__c = System.Today()
		);
		insert objZPRecoveryCase;
		System.assertEquals(1, [SELECT COUNT() FROM ZP_Recovery_Case__c]);

		objZPRecoveryCase.Initial_Recovery_Amount__c = 200;
		objZPRecoveryCase.Recovery_Case_Id__c = '';
		objZPRecoveryCase.Company_Id__c = '';
		update objZPRecoveryCase;
	}

	static testMethod void insertZPRecoveryRecordEx() {
		ZPRecoveryCaseTriggerHelper.queue = true;

		ZP_Recovery_Case__c objZPRecoveryCase = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1201',
			Company_Id__c = '7757616923607181',
			Event_Type__c = ZPRecoveryCaseTriggerHelper.CONTRACTOR_PAYMENT,
			Created_At_Date__c = System.Today(),
			Event_Check_Date__c = System.Today(),
			Last_Processed__c = System.Today(),
			Recovery_Case_Id__c = ''
		);
		insert objZPRecoveryCase;
		System.assertEquals(1, [SELECT COUNT() FROM ZP_Recovery_Case__c]);
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test where Case Contact do not change
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testZPRecoveryOne() {
		Test.startTest();

		List<ZP_Recovery_Case__c> list_ZPRecoveries = new List<ZP_Recovery_Case__c>();

		ZP_Recovery_Case__c objZPRecoveryCase = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1201',
			Company_Id__c = '0000999900001',
			Event_Type__c = ZPRecoveryCaseTriggerHelper.PAYROLL,
			Created_At_Date__c = System.today(),
			Event_Check_Date__c = System.today(),
			Last_Processed__c = System.today(),
			Recovery_Case_Id__c = '0101010101010',
			External_Key__c = 'zenpayroll-payroll-0101010101010'
		);
		list_ZPRecoveries.add(objZPRecoveryCase);

		ZP_Recovery_Case__c objZPRecoveryCase2 = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1202',
			Company_Id__c = '1234512345',
			Event_Type__c = ZPRecoveryCaseTriggerHelper.PAYROLL,
			Created_At_Date__c = System.today(),
			Event_Check_Date__c = System.today(),
			Last_Processed__c = System.today(),
			Recovery_Case_Id__c = '0101010101010'
		);
		list_ZPRecoveries.add(objZPRecoveryCase2);

		ZP_Recovery_Case__c objZPRecoveryCase3 = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1201',
			Company_Id__c = '0000999900001',
			Event_Type__c = ZPRecoveryCaseTriggerHelper.PAYROLL,
			Created_At_Date__c = System.today(),
			Event_Check_Date__c = System.today(),
			Last_Processed__c = System.today(),
			Recovery_Case_Id__c = '123123123',
			Event_Id__c = '999888777',
			External_Key__c = 'zenpayroll-payroll-999888777'
		);
		list_ZPRecoveries.add(objZPRecoveryCase3);
		insert list_ZPRecoveries;

		Test.stopTest();

		Case objCase = [SELECT Id, ContactId FROM Case WHERE Subject = 'Test' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'ZPNachaEntry@gusto.com' LIMIT 1];
		System.assertEquals(objCase.ContactId, objContact.Id);

		objCase = [SELECT Id FROM Case WHERE Recovery_Case_Id__c = '123123123' LIMIT 1];
		List<CaseTeamMember> list_CaseTeamMembers = [SELECT Id FROM CaseTeamMember WHERE ParentId = :objCase.Id];
		System.assert(!list_CaseTeamMembers.isEmpty());
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test where Case Contact do not change
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testZPRecoveryTwo() {
		Test.startTest();

		ZP_Recovery_Case__c objZPRecoveryCase = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1201',
			Company_Id__c = '0000999900001',
			Event_Type__c = ZPRecoveryCaseTriggerHelper.CONTRACTOR_PAYMENT,
			Created_At_Date__c = System.today(),
			Event_Check_Date__c = System.today(),
			Last_Processed__c = System.today(),
			Recovery_Case_Id__c = '123456'
		);
		insert objZPRecoveryCase;

		Test.stopTest();

		Case objCase = [SELECT Id, ContactId FROM Case WHERE Subject = 'Test ContractorPayment' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'ZPNachaEntryTwo@gusto.com' LIMIT 1];
		System.assertEquals(objCase.ContactId, objContact.Id);
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test where Case Contact is null and updates with a value
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testZPRecoveryThree() {
		Test.startTest();

		ZP_Recovery_Case__c objZPRecoveryCase = new ZP_Recovery_Case__c(
			Company_Name__c = 'A1201',
			Company_Id__c = '0000999900001',
			Event_Type__c = 'InternationalContractorPayments::Db::InternationalContractorPayment',
			Created_At_Date__c = System.today(),
			Event_Check_Date__c = System.today(),
			Last_Processed__c = System.today(),
			Recovery_Case_Id__c = '1234567'
		);
		insert objZPRecoveryCase;

		Test.stopTest();

		Case objCase = [SELECT Id, ContactId FROM Case WHERE Subject = 'Test' LIMIT 1];
		System.assertEquals(objCase.ContactId != null, true);

		List<Exception_Log__c> list_logs = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'Utils' AND Method_Name__c = 'processUpsertResult'];
		System.assertEquals(0, list_logs.size(), 'No errors occurred for recovery cases');
	}

	/**
	 * @description	To test InternationalEmployeePayroll event type
	 * @author Ajay Krishna P U
	 * @since 2024-09-25
	 */
	@isTest
	static void testInternationalEmployeePayrollZPRecoveryCase() {
		List<Account> list_Accounts = [SELECT Id, ZP_Company_Id__c FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		System.assert(list_Accounts.size() >=  1, 'Failed, Invalid Account data');
		Account objAccount = list_Accounts[0];

		Test.startTest();
		ZP_Recovery_Case__c objZPRecoveryCase = new TestDataFactory.ZPRecoveryCaseBuilder()
			.setPaymentInvestigationId('2547888')
			.setRecoveryCaseId('173291')
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setEventId('592')
			.setEventType(ZPRecoveryCaseTriggerHelper.INT_EMPLOYEE_PAYMENT)
			.setRecoveryStatus('awaiting_tax_recovery')
			.setExternalKey('zenpayroll-payment_investigation-25478881')
			.build();

		insert objZPRecoveryCase;
		Test.stopTest();
		
		List<Case> list_Cases = [SELECT Id, Event_Type__c FROM Case WHERE Event_Type__c =:ZPRecoveryCaseTriggerHelper.INT_EMPLOYEE_PAYMENT LIMIT 1];
		System.assert(list_Cases.size() >= 1, 'Recovery case did not created');
	}
}