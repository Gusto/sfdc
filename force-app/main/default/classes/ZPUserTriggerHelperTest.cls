/**
 * @name         : ZPUserTriggerHelperTest
 * @author       : Veeresh Kumar
 * @date         : 06-15-2021
 * @description  : Test Class for ZPUserTriggerHelper
 **/
@isTest
public class ZPUserTriggerHelperTest {
	@testSetup
	static void setup() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setBatchSize(10).build();

		insert objConfigSettings;

		List<Lead> list_Leads;

		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testcontact1@test.com')
			.setPhone('123456789')
			.setCompany('ABC Lead')
			.setExtPracticeId('12345')
			.setLeadSource(LeadUtil.LEADSOURCE_LIVE_CHAT)
			.build();

		Lead objLead2 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName22')
			.setLastName('LName22')
			.setEmail('testcontact2@test.com')
			.setPhone('123456798')
			.setCompany('ABC Lead23')
			.setExtPracticeId('12346')
			.setLeadSource(LeadUtil.LEADCREATION_OFFER_IB_PHONE)
			.build();

		list_Leads = new List<Lead>{ objLead1, objLead2 };
		insert list_Leads;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 1').setZPCompanyId('00000000000000').build();
		insert objAccount;
	}

	@isTest
	static void testExceptions() {
		List<Contact> list_Contacts;
		List<ZP_User__c> list_ZPUsers;
		List<ZP_User_Role__c> list_ZPUserRoles;
		List<Lead> list_Leads = [SELECT Id, Email FROM Lead];

		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account LIMIT 1];
		ContactTriggerHelper.skipTrigger = true;
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail(list_Leads[0].Email)
			.setZPUserId('176458136491')
			.setInactiveZPUser(true)
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name2')
			.setLastName('Test Last Name2')
			.setEmail(list_Leads[1].Email)
			.build();

		Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name3')
			.setLastName('Test Last Name3')
			.setEmail('testcontact3@test.com')
			.setZPUserId('176458136493')
			.build();

		list_Contacts = new List<Contact>{ objContact1, objContact2, objContact3 };
		insert list_Contacts;

		DateTime dtDateTime = System.now() - 1;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId(list_Contacts[0].ZP_User_Id__c)
			.setExternalKey('ZP777777777777771')
			.setEmail(list_Contacts[0].Email)
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setDeletedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.build();

		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 2')
			.setCustomId(list_Contacts[2].ZP_User_Id__c)
			.setExternalKey('ZP777777777777772')
			.setEmail(list_Contacts[1].Email)
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setDeletedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setReferralToken('REFERRAL02')
			.build();

		list_ZPUsers = new List<ZP_User__c>{ objZPUser1, objZPUser2 };
		insert list_ZPUsers;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(list_ZPUsers[1].Id__c)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setAccFirmId('ACCFIRM01')
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		insert objZPUserRole1;

		Test.startTest();

		for (ZP_User__c zpUser : list_ZPUsers) {
			zpUser.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}

		ZPUserTriggerHelper.blnSkipTestAccountDmlError = false;
		ZPUserTriggerHelper.blnSkipTestContactDmlError = false;
		ZPUserTriggerHelper.blnSkipTestLeadDmlError = false;
		update list_ZPUsers;
		ZPUserTriggerHelper.blnSkipTestAccountDmlError = true;
		ZPUserTriggerHelper.blnSkipTestContactDmlError = true;
		ZPUserTriggerHelper.blnSkipTestLeadDmlError = true;

		Test.stopTest();

		// Contact & Lead Errors

		ZP_User__c objZPUser1Assert = [SELECT Id__c, Processing_State__c FROM ZP_User__c WHERE Id = :list_ZPUsers[0].Id];
		System.assertEquals(ZPUserTriggerHelper.ERROR_STATE, objZPUser1Assert.Processing_State__c);

		ZP_User__c objZPUser2Assert = [SELECT Id__c, Processing_State__c FROM ZP_User__c WHERE Id = :list_ZPUsers[1].Id];
		System.assertEquals(ZPUserTriggerHelper.PROCESSED_STATE, objZPUser2Assert.Processing_State__c);
	}

	@isTest
	static void testZPUserIdZPUsers() {
		List<Account> list_Accounts;
		List<Contact> list_Contacts;
		List<ZP_User__c> list_ZPUsers;
		List<ZP_User_Role__c> list_ZPUserRoles;
		List<Lead> list_Leads = [SELECT Id, Email FROM Lead];

		DateTime dtDateTime = System.now() - 1;

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

		list_Contacts = new List<Contact>{ objContact1, objContact2 };
		insert list_Contacts;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId(list_Contacts[0].ZP_User_Id__c)
			.setExternalKey('ZP777777777777771')
			.setEmail(list_Leads[0].Email)
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
			.setEmail(list_Leads[1].Email)
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setUUID('109b6e20-c23b-4365-aa69-48b3d7763e82')
			.build();

		list_ZPUsers = new List<ZP_User__c>{ objZPUser1, objZPUser2 };
		insert list_ZPUsers;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(list_Contacts[0].ZP_User_Id__c)
			.setCompanyId(list_Accounts[0].ZP_Company_Id__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343435')
			.setUserId(list_Contacts[0].ZP_User_Id__c)
			.setCompanyId(list_Accounts[0].ZP_Company_Id__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole3 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343436')
			.setUserId(list_Contacts[1].ZP_User_Id__c)
			.setAccFirmId(list_Accounts[1].ZP_Firm_Id__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		list_ZPUserRoles = new List<ZP_User_Role__c>{ objZPUserRole1, objZPUserRole2, objZPUserRole3 };
		insert list_ZPUserRoles;

		Test.startTest();

		for (ZP_User_Role__c objRole : list_ZPUserRoles) {
			objRole.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}
		update list_ZPUserRoles;

		for (ZP_User__c zpUser : list_ZPUsers) {
			zpUser.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}
		update list_ZPUsers;

		Test.stopTest();
		List<Contact> list_ContactsAssert = [SELECT ZP_User_Id__c, UUID__c FROM CONTACT WHERE Id IN :list_Contacts];
		for (ZP_User__c zpUser : [SELECT Id, Id__c, UUID__c, Processing_State__c FROM ZP_User__c WHERE Id IN :list_ZPUsers]) {
			System.assertEquals(ZPUserTriggerHelper.PROCESSED_STATE, zpUser.Processing_State__c);
			if (zpUser.Id__c == list_ContactsAssert[0].ZP_User_Id__c) {
				System.assertEquals(list_ContactsAssert[0].UUID__c, zpUser.UUID__c);
			}
		}
	}

	@isTest
	static void testUniqueEmailZPUsers() {
		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account LIMIT 1];

		List<Contact> list_Contacts;
		List<ZP_User__c> list_ZPUsers;
		List<ZP_User_Role__c> list_Roles;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('testcontact100@test.com')
			.setZPUserId('1764581364911')
			.setInactiveZPUser(true)
			.setUniqueEmailAddressContact('testcontact1@test.com')
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name2')
			.setLastName('Test Last Name2')
			.setEmail('testcontact200@test.com')
			.setInactiveZPUser(true)
			.setZPUserId('1764581364912')
			.setUniqueEmailAddressContact('testcontact2@test.com')
			.build();

		list_Contacts = new List<Contact>{ objContact1, objContact2 };
		ContactTriggerHelper.skipTrigger = true;
		insert list_Contacts;
		ContactTriggerHelper.skipTrigger = false;

		DateTime dtDateTime = System.now() - 1;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId(objContact1.ZP_User_Id__c)
			.setExternalKey('ZP777777777777771')
			.setEmail(list_Contacts[0].Unique_Email_Address_Contact__c)
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('1010101')
			.setUserId(objZPUser1.Id__c)
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setFirstName('FNAME')
			.setLastName('LNAME')
			.build();

		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 2')
			.setCustomId(objContact2.ZP_User_Id__c)
			.setExternalKey('ZP777777777777772')
			.setEmail(list_Contacts[1].Unique_Email_Address_Contact__c)
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('1010102')
			.setUserId(objZPUser2.Id__c)
			.setCompanyId(objAccount.ZP_Company_ID__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setFirstName('FNAME')
			.setLastName('LNAME')
			.build();

		list_ZPUsers = new List<ZP_User__c>{ objZPUser1, objZPUser2 };
		insert list_ZPUsers;

		list_Roles = new List<ZP_User_Role__c>{ objZPUserRole1, objZPUserRole2 };
		insert list_Roles;

		Test.startTest();

		for (ZP_User__c zpUser : list_ZPUsers) {
			zpUser.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}

		for (ZP_user_Role__c objRole : list_Roles) {
			objRole.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}
		update list_ZPUsers;
		update list_Roles;

		Test.stopTest();

		for (ZP_User__c zpUser : [SELECT Id, Processing_State__c FROM ZP_User__c WHERE Id IN :list_ZPUsers]) {
			System.assertEquals(ZPUserTriggerHelper.PROCESSED_STATE, zpUser.Processing_State__c);
		}

		for (ZP_user_Role__c objRole : [SELECT Id, Processing_State__c FROM ZP_user_Role__c WHERE Id IN :list_Roles]) {
			System.assertEquals(ZPUserTriggerHelper.PROCESSED_STATE, objRole.Processing_State__c);
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Re-process failed ZP User Roles from ZP User Trigger
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testReprocessingUserRoles() {
		// Create a Company Account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company').setZPCompanyId('121212').build();

		// Skip Account Trigger for faster inserts
		AccountTriggerHelper.skipTrigger = true;
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		// Insert new user role and assert user role failed because of missing ZP User
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('1010101')
			.setUserId('111111')
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setType(ZPUserRoleUtil.TYPE_INTERNATIONAL_CONTRACTOR)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setFirstName('FNAME')
			.setLastName('LNAME')
			.build();

		insert objZPUserRole;

		// Assume this role is Dead. Skip ZP User Role Trigger and update Processing State
		ZPUserRoleTriggerHelper.skipTrigger = true;
		objZPUserRole.Processing_State__c = IntegrationUtils.DEAD_STATE;
		update objZPUserRole;
		ZPUserRoleTriggerHelper.skipTrigger = false;

		Test.startTest();

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId(objZPUserRole.User_Id__c)
			.setEmail('abcemail@email.com')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.build();

		insert objZPUser;

		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;

		Test.stopTest();

		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];

		// Inserting a new ZP User should have re-processed errored or backlogged zp user roles
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objRoleAssert.Processing_State__c);

		// Updating this record further should trigger successful contact creation
		objRoleAssert.Processing_State__c = 'Manually Enqueued';
		update objRoleAssert;

		objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];

		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c);

		Contact objContactAssert = [SELECT Id FROM Contact WHERE Email = :objZPUser.Email__c];
		System.assertNotEquals(null, objContactAssert);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Try to update ZP User with Blank Email. Result is Record should move to Dead state
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testZPUserWithBlankEmail() {
		// Create ZP User with Blank Email
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('1212121')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.build();
		insert objZPUser;

		Test.startTest();
		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;
		Test.stopTest();

		ZP_User__c objUserAssert = [SELECT Id, Processing_State__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(ZPUserTriggerHelper.DEAD_STATE, objUserAssert.Processing_State__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Fraud ZP Users are Not Processed
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testFraudZPUsersAreNotProcessed() {
		// Create a new user with fraud email
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('121212')
			.setEmail('abcemail@uniromax.com')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.build();
		insert objZPUser;

		Test.startTest();
		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;
		Test.stopTest();

		// Assert processing state is set to Dead
		ZP_User__c objUserAssert = [SELECT Id, Processing_State__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objUserAssert.Processing_State__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Asert if User is getting backlogged when there is no User Role
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserCreationWithMissingRole() {
		// Create a new user with fraud email
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('121212')
			.setEmail('abcemail@abcemail.com')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.build();
		insert objZPUser;

		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;

		ZP_User__c objUserAssert = [SELECT Id, Processing_State__c FROM ZP_User__c WHERE Id = :objZPUser.Id];

		// Assert ZP User errored out because of missing User Role
		System.assertEquals(IntegrationUtils.BACKLOG, objUserAssert.Processing_State__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Testing scenario when multiple users are created with same referral token
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testDuplicateReferralToken() {
		// Create a Company Account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company').setZPCompanyId('121212').build();

		// Skip Account Trigger for faster inserts
		AccountTriggerHelper.skipTrigger = true;
		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		// Insert a new ZP User Record with valid referral token
		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Ref Token 1')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('reftoken1@test.com')
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.setReferralToken('reftoken')
			.build();
		insert objZPUser1;

		// Create a new ZP User Role to trigger new contact creation
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setCustomId('343434343101')
			.setUserId(objZPUser1.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.Now())
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(objZPUser1.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.Now();
		update objZPUserRole;

		// Manually enqueue user to associate it with contact
		objZPUser1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUser1.Updated_At__c = System.Now();
		update objZPUser1;

		// assert contact association happenend on user and referral token was set properly
		ZP_User__c objUser1Assert = [SELECT Id, Contact__c, Contact__r.Referral_Token__c, Referral_Token__c FROM ZP_User__c WHERE Id = :objZPUser1.Id];
		System.assertNotEquals(null, objUser1Assert.Contact__c);
		System.assertNotEquals(null, objUser1Assert.Referral_Token__c);
		System.assertNotEquals(null, objUser1Assert.Contact__r.Referral_Token__c);

		Test.startTest();

		// Insert second zp user with same referral token
		// Result = Old User Referral Token should be wiped out
		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder()
			.setName('Ref Token 2')
			.setCustomId('1764581364533')
			.setExternalKey('ZP777777777777098')
			.setEmail('reftoken2@test.com')
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.setReferralToken(objZPUser1.Referral_Token__c)
			.build();
		insert objZPUser2;

		objZPUser2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUser2.Updated_At__c = System.Now();
		update objZPUser2;

		Test.stopTest();

		// Assert if referral token was set to blank on old processed zp users
		objUser1Assert = [SELECT Id, Contact__c, Contact__r.Referral_Token__c, Referral_Token__c FROM ZP_User__c WHERE Id = :objZPUser1.Id];
		System.assertEquals(null, objUser1Assert.Referral_Token__c);
		System.assertEquals(null, objUser1Assert.Contact__r.Referral_Token__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Backlog User resets Referral token on Contact
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testBacklogUserResetsReferralToken() {
		ContactTriggerHelper.skipTrigger = true;
		// Create a Company Account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company').setZPCompanyId('121212').build();

		// Skip Account Trigger for faster inserts
		AccountTriggerHelper.skipTrigger = true;
		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		String strReferralToken = 'reftoken';
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('test@testdomain1.com')
			.build();
		objContact.Referral_Token__c = strReferralToken;
		insert objContact;

		Test.startTest();

		// Insert a new ZP User Record with same referral token as Contact
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Ref Token 1')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail(objContact.Email)
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.setReferralToken(objContact.Referral_Token__c)
			.build();
		insert objZPUser;

		objZPUser.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		update objZPUser;

		// Referral token on Contact must be set to null
		Contact objContactAssert = [SELECT Id, Referral_Token__c FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(true, String.isBlank(objContactAssert.Referral_Token__c));

		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Test Preferred Name 1')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.Now())
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(objZPUser.Created_At__c)
			.setCollaboratorType('External Accountant')
			.build();
		insert objZPUserRole;

		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;

		Test.stopTest();

		// Referral token on Contact should be populated back
		objContactAssert = [SELECT Id, Referral_Token__c FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(strReferralToken, objContactAssert.Referral_Token__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test whether updating records to Backlog remains in backlog status instead of defaulting to Queued
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testRecordUpdateToBacklog() {
		String strBacklogReason = 'Custom backlog reason';

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Test initial status should remain as Queued when record is created
		ZP_User__c objZPUserAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(ZPUserTriggerHelper.QUEUED_STATE, objZPUserAssert.Processing_State__c);

		Test.startTest();

		// Update record processing status to Backlog
		// Result Record should remain in Backlog instead of defaulting to Queued
		objZPUserAssert.Processing_State__c = ZPUserTriggerHelper.BACKLOG;
		objZPUserAssert.Message__c = strBacklogReason;
		update objZPUserAssert;
		Test.stopTest();

		objZPUserAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(ZPUserTriggerHelper.BACKLOG, objZPUserAssert.Processing_State__c);
		System.assertEquals(strBacklogReason, objZPUserAssert.Message__c);

		// Edit and save record without putting it to Backlog (Mimic update caused by Workato)
		// Result = Records should go to Queued status

		update objZPUserAssert;
		objZPUserAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(ZPUserTriggerHelper.QUEUED_STATE, objZPUserAssert.Processing_State__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test whether updating records to Dead remains in Dead status instead of defaulting to Queued
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testRecordUpdateToDead() {
		String strDeadReason = 'Custom dead reason';

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Test initial status should remain as Queued when record is created
		ZP_User__c objZPUserAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(ZPUserTriggerHelper.QUEUED_STATE, objZPUserAssert.Processing_State__c);

		Test.startTest();

		// Update record processing status to Dead
		// Result Record should remain in Dead instead of defaulting to Queued
		objZPUserAssert.Processing_State__c = ZPUserTriggerHelper.DEAD_STATE;
		objZPUserAssert.Message__c = strDeadReason;
		update objZPUserAssert;
		Test.stopTest();

		objZPUserAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(ZPUserTriggerHelper.DEAD_STATE, objZPUserAssert.Processing_State__c);
		System.assertEquals(strDeadReason, objZPUserAssert.Message__c);

		// Edit and save record without putting it to Dead (Mimic update caused by Workato)
		// Result = Records should go to Queued status

		update objZPUserAssert;
		objZPUserAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(ZPUserTriggerHelper.QUEUED_STATE, objZPUserAssert.Processing_State__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Is_Changed__c flag is set to true on Insert
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testIsChangedFlagOnInsert() {
		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.setReferralToken('REFERRAL01')
			.build();

		Test.startTest();
		insert objZPUser;
		Test.stopTest();

		ZP_User__c objUserAssert = [SELECT Id, Is_Changed__c, Processing_State__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(true, objUserAssert.Is_Changed__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if no update counter is updated when there is no update on ZP User
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testNoUpdateCounterUpdate() {
		// Create a Company Account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company').setZPCompanyId('121212').build();

		// Skip Account Trigger for faster inserts
		AccountTriggerHelper.skipTrigger = true;
		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		// Insert a new ZP User Record with valid referral token
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Ref Token 1')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('reftoken1@test.com')
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.setReferralToken('reftoken')
			.build();
		insert objZPUser;

		// Create a new ZP User Role to trigger new contact creation
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.Now())
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.Now();
		update objZPUserRole;

		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;

		ZP_User__c objUserAssert = [SELECT Id, Is_Changed__c, No_Update_Counter__c, Processing_State__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(false, objUserAssert.Is_Changed__c);
		System.assertEquals(null, objUserAssert.No_Update_Counter__c);
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objUserAssert.Processing_State__c);

		// Dummy update ZP User Record
		Test.startTest();
		update objUserAssert;
		Test.stopTest();

		objUserAssert = [SELECT Id, Is_Changed__c, No_Update_Counter__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(false, objUserAssert.Is_Changed__c);
		System.assertEquals(1, objUserAssert.No_Update_Counter__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if user roles are re-processed from user trigger when there are missing contacts
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testMissingContactsFromZPUser() {
		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account LIMIT 1];

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Ref Token 1')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('missingcontacts@gmail.com')
			.setCreatedAt(System.Now() - 2)
			.setUpdatedAt(System.Now() - 1)
			.setLastSignInAt(System.Now())
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setCreatedAt(System.Now())
			.setType(ZPUserRoleUtil.TYPE_INTERNATIONAL_CONTRACTOR)
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// update processing state to processed
		ZPUserRoleTriggerHelper.skipTrigger = true;
		objZPUserRole.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
		update objZPUserRole;
		ZPUserRoleTriggerHelper.skipTrigger = false;

		// manually re-process zp user
		Test.startTest();
		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;
		Test.stopTest();

		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(objRoleAssert.Processing_State__c, IntegrationUtils.QUEUED_STATE);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test last login date update on Account and Lead
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testLastLoginDateUpdate() {
		AccountTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 1').setZPCompanyId('78687576465').build();

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('ABC Account 3').setZPFirmId('245345346547').build();

		List<Account> list_Accounts = new List<Account>{ objAccount, objResellerAccount };
		insert list_Accounts;

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('786876874765')
			.setEmail('testlastlogindemo@test.com')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setCurrentSignInAt(System.now())
			.build();
		insert objZPUser;

		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();
		insert objZPUserRole;

		ZP_User_Role__c objAccRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('43325356467')
			.setUserId(objZPUser.Id__c)
			.setAccFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();
		insert objAccRole;

		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;

		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;

		ZP_User__c objZPUserAssert = [SELECT Id, Processing_State__c, User_Roles__c, Message__c, Contact__c FROM ZP_User__c WHERE Id = :objZPUser.Id];

		Test.startTest();
		objZPUserAssert.Last_Sign_In_At__c = System.now();
		update objZPUserAssert;

		Database.executeBatch(new BatchCleanUpZpUsers(), 1);
		Test.stopTest();

		// company account assert
		Account objCompAccountAssert = [SELECT Id, Last_Login_Details__c, Last_Login_Time__c FROM Account WHERE Id = :objAccount.Id];

		System.assertEquals(objZPUser.Email__c, objCompAccountAssert.Last_Login_Details__c);
		System.assertEquals(objZPUserAssert.Last_Sign_In_At__c, objCompAccountAssert.Last_Login_Time__c);

		// reseller account assert
		Account objResellerAccountAssert = [SELECT Id, Last_Login_Details__c, Last_Login_Time__c FROM Account WHERE Id = :objResellerAccount.Id];

		System.assertEquals(objZPUser.Email__c, objResellerAccountAssert.Last_Login_Details__c);
		System.assertEquals(objZPUserAssert.Last_Sign_In_At__c, objResellerAccountAssert.Last_Login_Time__c);
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Last Sign In At is updated for Users linked with Payroll Admin Contacts
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testLastSignUpdateForPayrollAdmins() {
		// Create a Company Account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company').setZPCompanyId('121212').build();

		// Skip Account Trigger for faster inserts
		AccountTriggerHelper.skipTrigger = true;
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		// insert new zp user
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('111111')
			.setEmail('abcemail@email.com')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.build();
		insert objZPUser;

		// Insert new zp user role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('1010101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setFirstName('FNAME')
			.setLastName('LNAME')
			.build();
		insert objZPUserRole;

		// update user role processing state to Manually Enqueued to trigger contact creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;

		// update user processing state to Manually Enqueued to link user and contact
		objZPUser.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUser;

		// assert if user processing state is set to processed
		ZP_User__c objUserAssert = [SELECT Id, Processing_State__c, Message__c, User_Roles__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objUserAssert.Processing_State__c);

		Test.startTest();

		// change last sign in on zp user that is linked to payroll admin contact
		objUserAssert.Last_Sign_In_At__c = Datetime.now();
		update objUserAssert;

		Test.stopTest();

		// assert sign in changed is set to true
		objUserAssert = [SELECT Id, Sign_In_Changed__c FROM ZP_User__c WHERE Id = :objZPUser.Id];
		System.assertEquals(true, objUserAssert.Sign_In_Changed__c);
	}
}