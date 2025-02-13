/**
 * @name         ContactJobsTest
 * @date         07-24-2024
 * @description  Test class for ContactJobs. Contains test methods for ContactJobs class; test methods for different operations.
 * @see          ContactJobs
 **/

@isTest
public class ContactJobsTest {
	/**
	 * @description Setup required test records
	 **/
	@testSetup
	static void setup() {
		Test.startTest();
		List<Account> list_Accounts;
		List<Contact> list_Contacts;
		List<ZP_User__c> list_ZPUsers;
		List<ZP_User_Role__c> list_ZPUserRoles;

		DateTime dtDateTime = System.now() - 1;

		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId('Company')
			.setFirstName('Test Lead1 FirstName')
			.setLastName('Test Lead1 LastName')
			.setEmail('testlead100@test.com')
			.setCompany('ABC Company')
			.build();
		insert objLead1;

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 2').setZPCompanyId('00000000000012').build();

		Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('ABC Account 3')
			.setZPFirmId('00000000000021')
			.setLastLoginTime(dtDateTime - 1)
			.build();

		list_Accounts = new List<Account>{ objAccount1, objAccount2 };
		insert list_Accounts;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(list_Accounts[0].Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('testcontact100@test.com')
			.setZPUserId('176458136499')
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(list_Accounts[0].Id)
			.setFirstName('Test First Name2')
			.setLastName('Test Last Name2')
			.setEmail('testcontact200@test.com')
			.setZPUserId('176458136491')
			.setInactiveZPUser(true)
			.build();

		Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(list_Accounts[0].Id)
			.setFirstName('Test First Name3')
			.setLastName('Test Last Name3')
			.setEmail('testcontact300@test.com')
			.setZPUserId('176458136493')
			.setZPUserRole('Primary Payroll Admin;Employee')
			.setInactiveZPUser(true)
			.build();

		list_Contacts = new List<Contact>{ objContact1, objContact2, objContact3 };
		insert list_Contacts;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId(list_Contacts[0].ZP_User_Id__c)
			.setExternalKey('ZP777777777777771')
			.setEmail('testcontact100@test.com')
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setUUID('109b6e20-c23b-4365-aa69-48b3d7763e81')
			.build();

		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 2')
			.setCustomId(list_Contacts[1].ZP_User_Id__c)
			.setExternalKey('ZP777777777777772')
			.setEmail('testcontact200@test.com')
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setUUID('109b6e20-c23b-4365-aa69-48b3d7763e82')
			.build();

		ZP_User__c objZPUser3 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 3')
			.setCustomId(list_Contacts[2].ZP_User_Id__c)
			.setExternalKey('ZP777777777777773')
			.setEmail('testcontact300@test.com')
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setUUID('109b6e20-c23b-4365-aa69-48b3d7763e83')
			.build();

		list_ZPUsers = new List<ZP_User__c>{ objZPUser1, objZPUser2, objZPUser3 };
		insert list_ZPUsers;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(list_Contacts[0].ZP_User_Id__c)
			.setCompanyId(list_Accounts[0].ZP_Company_Id__c)
			.setType('Role::Employee')
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343435')
			.setUserId(list_Contacts[1].ZP_User_Id__c)
			.setCompanyId(list_Accounts[0].ZP_Company_Id__c)
			.setType('Role::Payroll Admin')
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole3 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343436')
			.setUserId(list_Contacts[2].ZP_User_Id__c)
			.setAccFirmId(list_Accounts[1].ZP_Firm_Id__c)
			.setType('Role::Primary Payroll Admin')
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole4 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343437')
			.setUserId(list_Contacts[2].ZP_User_Id__c)
			.setAccFirmId(list_Accounts[1].ZP_Firm_Id__c)
			.setType('Role::Employee')
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		list_ZPUserRoles = new List<ZP_User_Role__c>{ objZPUserRole1, objZPUserRole2, objZPUserRole3, objZPUserRole4 };
		insert list_ZPUserRoles;

		for (ZP_User_Role__c objRole : list_ZPUserRoles) {
			objRole.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}
		update list_ZPUserRoles;

		for (ZP_User__c zpUser : list_ZPUsers) {
			zpUser.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}
		update list_ZPUsers;
		Test.stopTest();
	}

	/**
	 * When contact role is updated such that Marketo Sync is false, check sync to marketo. Run batch to test callout.
	 **/
	@isTest
	static void testSyncToMarketoSchedule() {
		Contact objContact = [SELECT ZP_User_Role__c, Marketo_Sync__c FROM Contact WHERE ZP_User_Id__c = '176458136493'];
		Assert.isTrue(objContact.Marketo_Sync__c, 'Marketo Sync should be true');
		objContact.ZP_User_Role__c = 'Employee';
		update objContact;
		objContact = [SELECT Email, ZP_User_Id__c, ZP_User_Role__c, Marketo_Sync__c, Sync_To_Marketo__c, Sync_To_Marketo_Request_Time__c FROM Contact WHERE Id = :objContact.Id];
		Assert.isFalse(objContact.Marketo_Sync__c, 'Marketo Sync should be false');
		Assert.isTrue(objContact.Sync_To_Marketo__c, 'Sync To Marketo should be true');
		Assert.isTrue(
			objContact.Sync_To_Marketo_Request_Time__c != null && objContact.Sync_To_Marketo_Request_Time__c.date() == System.today(),
			'Sync to Marketo request time should be populated with current date'
		);
		Test.setMock(HttpCalloutMock.class, new ContactJobs.HttpClientMockResponse());
		// Schedule and run the batch job
		Test.startTest();
		String cronExp = '0 0 * * * ?';
		String jobId = System.schedule('Test sync to marketo job', cronExp, new ContactJobs(ContactJobs.SYNC_TO_MARKETO));
		Test.stopTest();
		ContactJobs objJob = new ContactJobs(ContactJobs.SYNC_TO_MARKETO);
		Map<Id, String> map_response = objJob.syncContactsToMarketo(new List<Contact>{ objContact }, objJob.strToken);

		// Assert the contact has been synced
		Assert.areEqual(200, Integer.valueOf(map_response.get(objContact.Id)), 'Callout failed');
		objContact = [SELECT Sync_To_Marketo__c FROM Contact WHERE Id = :objContact.Id];
		Assert.isFalse(objContact.Sync_To_Marketo__c, 'Sync To Marketo should be false');
	}

	/**
	 * When contact role is updated such that Marketo Sync is false, check sync to marketo. Run batch to test callout.
	 **/
	@isTest
	static void testSyncToMarketo() {
		Contact objContact = [SELECT Email, ZP_User_Role__c, Marketo_Sync__c FROM Contact WHERE ZP_User_Id__c = '176458136493'];
		Assert.isTrue(objContact.Marketo_Sync__c, 'Marketo Sync should be true');
		objContact.ZP_User_Role__c = 'Employee';
		update objContact;
		Test.setMock(HttpCalloutMock.class, new ContactJobs.HttpClientMockResponse());
		Test.startTest();
		//Execute batch separately for testing
		Database.executeBatch(new ContactJobs(ContactJobs.SYNC_TO_MARKETO), 5);
		Test.stopTest();

		// Assert the contact has been synced
		Integer intSyncedCount = [SELECT COUNT() FROM Contact WHERE Sync_To_Marketo__c = FALSE];
		Assert.isTrue(intSyncedCount > 1, 'Sync To Marketo should increase');
	}

	/**
	 * Exception Handling tests
	 **/
	@isTest
	static void testExceptionHandling() {
		Contact objContact = [SELECT Email, ZP_User_Role__c, Marketo_Sync__c FROM Contact WHERE ZP_User_Id__c = '176458136493'];
		Assert.isTrue(objContact.Marketo_Sync__c, 'Marketo Sync should be true');
		objContact.ZP_User_Role__c = 'Employee';
		update objContact;
		Test.setMock(HttpCalloutMock.class, new ContactJobs.HttpClientMockResponse());
		Test.startTest();
		//Execute batch separately for testing
		ContactJobs objJob = new ContactJobs(ContactJobs.SYNC_TO_MARKETO);
		ContactJobs.blnTestException = true;
		Database.executeBatch(objJob, 5);
		Test.stopTest();

		// Verify that the exception was logged
		List<Exception_Log__c> list_logs = [SELECT Id, Message__c FROM Exception_Log__c];
		Assert.areNotEqual(0, list_logs.size(), 'Exceptions should be logged.');
	}
}