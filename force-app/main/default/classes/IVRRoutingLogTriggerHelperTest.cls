@isTest
public with sharing class IVRRoutingLogTriggerHelperTest {
	@TestSetup
	static void testSetup() {
		String strPhone1 = '0009998888';
		List<Account> list_Accounts = new List<Account>();
		List<Contact> list_Contacts = new List<Contact>();
		List<IVR_Routing_Log__c> list_IVR_Logs = new List<IVR_Routing_Log__c>();
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		Account objAcct = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Account from test setup 1').setZPCompanyId('1111111111').build();
		list_Accounts.add(objAcct);

		Account objAcct1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test acct').setZPCompanyId('00000').build();
		list_Accounts.add(objAcct1);

		insert list_Accounts;

		Contact objContact = new TestDataFactory.ContactBuilder().setRecordTypeId(ContactUtil.COMPANY_RT_NAME).setFirstName('Matching1').setLastName('Phone1').setZPPhone(strPhone1).build();
		list_Contacts.add(objContact);

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objAcct1.Id)
			.setFirstName('testFirst')
			.setLastName('testLast')
			.setZPUserId('11111')
			.setZPPhone('3034567890')
			.build();
		list_Contacts.add(objContact1);

		insert list_Contacts;

		IVR_Routing_Log__c objIVRRoutingLog = new TestDataFactory.IVR_Routing_LogBuilder().setConversationId('0000000000').setANI(strPhone1).setInQueue_Queue_Name('queue 1').build();
		list_IVR_Logs.add(objIVRRoutingLog);

		insert list_IVR_Logs;

		// Create ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setFirstName(objContact1.FirstName)
			.setLastName(objContact1.LastName)
			.setPhone(objContact1.Phone)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setContact(objContact1.Id)
			.setCompanyAccount(objAcct.Id)
			.setCustomId('7757869459027224')
			.setUserId('7757869455114985')
			.setCompanyId(objAcct.ZP_Company_ID__c)
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		ZPUserRoleTriggerHelper.skipTrigger = true;
		insert list_ZPUserRoles;
		ZPUserRoleTriggerHelper.skipTrigger = false;
	}

	@isTest
	public static void testCallTimes() {
		IVR_Routing_Log__c objIVRRoutingLog = new TestDataFactory.IVR_Routing_LogBuilder().setConversationId('1234567890').build();
		insert objIVRRoutingLog;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_PAYROLL_CARE)
			.setType(CaseUtils.TYPE_PAYROLL_CARE)
			.setIVRroutingLog(objIVRRoutingLog.Id)
			.setOrigin(CaseUtils.ORIGIN_PHONE)
			.setStatus(CaseUtils.STATUS_OPEN)
			.setDirection(CaseUtils.DIRECTION_INBOUND)
			.build();
		insert objCase;

		Test.startTest();
		IVR_Routing_Log__c objQueriedIVRRoutingLog = [SELECT Id, ConversationId__c FROM IVR_Routing_Log__c WHERE ConversationId__c = '1234567890'];
		//call start = now, call end = a minute from now
		objQueriedIVRRoutingLog.Call_Start__c = System.now();
		objQueriedIVRRoutingLog.Call_End__c = System.now().addMinutes(1);

		update objQueriedIVRRoutingLog;

		Case caseQueried = [SELECT Id, Call_Start__c, Call_End__c FROM Case WHERE IVR_Routing_Log__c = :objQueriedIVRRoutingLog.Id];
		System.assertEquals(objQueriedIVRRoutingLog.Call_Start__c, caseQueried.Call_Start__c);
		System.assertEquals(objQueriedIVRRoutingLog.Call_End__c, caseQueried.Call_End__c);
		Test.stopTest();
	}

	@isTest
	public static void testAccountAndContact() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '00000' LIMIT 1];

		Contact objContact = [SELECT Id FROM Contact WHERE ZP_User_Id__c = '11111' LIMIT 1];

		IVR_Routing_Log__c objIVRRoutingLog = new TestDataFactory.IVR_Routing_LogBuilder().setConversationId('1234567890').setCIP_Company_Id('').setZP_User_Id('').build();
		insert objIVRRoutingLog;

		objIVRRoutingLog.CIP_Company_Id__c = '00000';
		objIVRRoutingLog.ZP_User_Id__c = '11111';

		update objIVRRoutingLog;

		Test.startTest();
		IVR_Routing_Log__c objQueriedIVRRoutingLog = [SELECT Id, CIP_Company_Id__c, ZP_User_Id__c, CIP_Account__c, Contact__c FROM IVR_Routing_Log__c WHERE Id = :objIVRRoutingLog.Id];
		System.assertEquals(objAccount.Id, objQueriedIVRRoutingLog.CIP_Account__c, 'Account Id does not match IVR Routing Log CIP_Account__c');
		System.assertEquals(objContact.Id, objQueriedIVRRoutingLog.Contact__c, 'Contact Id does not match IVR Routing Log Contact__c');
		Test.stopTest();
	}

	/**
	 * @author      : Alex Xiong
	 * @description : test getting contact with phone when IVR Routing Log has no ZP User Id
	 */
	@isTest
	public static void testGetContactWithPhone() {
		Test.startTest();
		Contact objContact = [SELECT Id FROM Contact WHERE FirstName = 'Matching1'];
		List<IVR_Routing_Log__c> list_IVR = [SELECT Id, ANI__c, ZP_User_Id__c FROM IVR_Routing_Log__c WHERE ConversationId__c = '0000000000'];
		IVRRoutingLogTriggerHelper.linkContactsToIVR(list_IVR);

		System.assertEquals(objContact.Id, list_IVR[0].Contact__c);
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test tranfer field updates
	 */
	public static void testTransfer() {
		Test.startTest();
		IVR_Routing_Log__c objIVR = [SELECT Id, InQueue_Queue_Name__c FROM IVR_Routing_Log__c WHERE InQueue_Queue_Name__c != ''];
		objIVR.InQueue_Queue_Name__c = 'queue 2';
		update objIVR;
		Test.stopTest();

		IVR_Routing_Log__c objIVRAfter = [SELECT Id, InQueue_Queue_Name__c, Previous_Queue_Name__c, Transferred__c FROM IVR_Routing_Log__c WHERE Id = :objIVR.Id];

		System.assertEquals(objIVR.InQueue_Queue_Name__c, objIVRAfter.Previous_Queue_Name__c);
		System.assert(objIVRAfter.Transferred__c);
	}

	/**
	 * @author Todd Dowdy
	 * @description test Associate Account based on ZP User Role Id when CIP Company Id is UUID from Panda
	 */
	@isTest
	public static void testAccountWithZPRoleId() {
		Test.startTest();
		// Create IVR Routing Log with UUID. Account associated to case linked by ZP User Role Account
		IVR_Routing_Log__c objIVRRoutingLog = new TestDataFactory.IVR_Routing_LogBuilder()
			.setConversationId('463745234098')
			.setCIP_Company_Id('7caec697-0b6e-4a17-8a98-8cf3cd3316a2')
			.setZP_User_Id('11111')
			.setZPUserRoleId('7757869459027224')
			.setType(TaskUtil.TASK_TYPE_INBOUND_CALL)
			.build();
		insert objIVRRoutingLog;

		// Case created through Telephony as inbound call
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_PAYROLL_CARE)
			.setType(CaseUtils.TYPE_PAYROLL_CARE)
			.setGenesysCallId(objIVRRoutingLog.ConversationId__c)
			.setIVRroutingLog(objIVRRoutingLog.Id)
			.setOrigin(CaseUtils.ORIGIN_PHONE)
			.setStatus(CaseUtils.STATUS_OPEN)
			.setDirection(CaseUtils.DIRECTION_INBOUND)
			.build();
		insert objCase;

		// Validate Account and Contact associated to Case
		List<ZP_User_Role__c> list_ZPUserRoles = [SELECT Id, Company_Account__c, Contact__c FROM ZP_User_Role__c WHERE Id__c = :objIVRRoutingLog.ZP_User_Role_Id__c];
		List<Case> list_Cases = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(list_Cases[0].AccountId, list_ZPUserRoles[0].Company_Account__c, 'Case Account does not match IVR Routing Log');
		System.assertEquals(list_Cases[0].ContactId, list_ZPUserRoles[0].Contact__c, 'Case Contact does not match IVR Routing Log');

		// Validate Account and Contact associated to IVR Routing Log
		List<Account> list_Accts = [SELECT Id, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = '1111111111'];
		objIVRRoutingLog.CIP_Company_Id__c = list_Accts[0].ZP_Company_ID__c;
		update objIVRRoutingLog;
		List<IVR_Routing_Log__c> list_QueriedIVRRoutingLog = [SELECT Id, CIP_Company_Id__c, ZP_User_Id__c, CIP_Account__c, Contact__c FROM IVR_Routing_Log__c WHERE Id = :objIVRRoutingLog.Id];
		System.assertEquals(list_QueriedIVRRoutingLog[0].CIP_Account__c, list_Accts[0].Id, 'IVR Routing Log Account was not updated');
		Test.stopTest();
	}
}