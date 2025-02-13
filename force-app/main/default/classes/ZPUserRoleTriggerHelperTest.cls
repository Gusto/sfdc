/**
 * @description  Refactored ZPUserRoleTriggerHelperTest
 * @author       Praveen Sethu
 * @date         02-12-2021
 * @see          ZPUserRoleTriggerHelper
 **/
@isTest
public class ZPUserRoleTriggerHelperTest {
	/**
	 * @description Setting up common test data for all test methods
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@testSetup
	static void testDataSetup() {
		// Create a new company account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Acc').setZPCompanyId('companyIdSetup1').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Test Reseller Acc').setZPFirmId('firmIdSetup1').build();

		AccountTriggerHelper.skipTrigger = true;
		insert new List<Account>{ objCompanyAccount, objResellerAccount };
		AccountTriggerHelper.skipTrigger = false;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('companycontactsetup1@contact.com')
			.setPhone('1234567890')
			.build();
		objContact.ZP_User_Id__c = '8878687';
		insert objContact;

		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('FName1')
			.setLastName('LName1')
			.setEmail('testleadsetup1@lead.com')
			.setPhone('8976567890')
			.setCompany('Test Accountant')
			.setLeadSource(LeadUtil.LEADSOURCE_LIVE_CHAT)
			.build();
		insert objLead1;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test Setup User 1')
			.setCustomId('8878687')
			.setEmail(objContact.Email)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();

		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder()
			.setName('Test Setup User 2')
			.setCustomId('userIdSetup2')
			.setEmail('testusersetup2@test.com')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();

		ZP_User__c objZPUser3 = new TestDataFactory.ZPUserBuilder()
			.setName('Test Setup User 3')
			.setCustomId('userIdSetup3')
			.setEmail(objLead1.Email)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();

		insert new List<ZP_User__c>{ objZPUser1, objZPUser2, objZPUser3 };
	}

	/**
	 * @description Test if Processing State is set to Queued on Insert
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testProcessingStateOnInsert() {
		Test.startTest();
		ZP_User_Role__c objUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('100')
			.setUserId('1212121')
			.setAccFirmId('12313123')
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();
		insert objUserRole;
		Test.stopTest();

		// Assert Processing state changes to Queued
		ZP_User_Role__c objUserRoleAssert = [SELECT Id, Processing_State__c FROM ZP_User_Role__c WHERE Id = :objUserRole.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objUserRoleAssert.Processing_State__c, 'Processing state should be queued.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test whether updating records to Backlog remains in backlog status instead of defaulting to Queued
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testRecordUpdateToBacklog() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		String strBacklogReason = 'Custom backlog reason';

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Test initial status should remain as Queued when record is created
		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be queued.');

		Test.startTest();

		// Update record processing status to Backlog
		// Result Record should remain in Backlog instead of defaulting to Queued
		objRoleAssert.Processing_State__c = IntegrationUtils.BACKLOG;
		objRoleAssert.Message__c = strBacklogReason;
		update objRoleAssert;
		Test.stopTest();

		objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.BACKLOG, objRoleAssert.Processing_State__c, 'Processing state should be backlog.');
		System.assertEquals(strBacklogReason, objRoleAssert.Message__c, 'Processing message is incorrect.');

		// Edit and save record without putting it to Backlog (Mimic update caused by Workato)
		// Result = Records should go to Queued status

		update objRoleAssert;
		objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be queued.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test whether updating records to Dead remains in dead status instead of defaulting to Queued
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testRecordUpdateToDead() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		String strDeadReason = 'Custom dead reason';

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Test initial status should remain as Queued when record is created
		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be queued.');

		Test.startTest();

		// Update record processing status to Dead
		// Result Record should remain in Dead instead of defaulting to Queued
		objRoleAssert.Processing_State__c = IntegrationUtils.DEAD_STATE;
		objRoleAssert.Message__c = strDeadReason;
		update objRoleAssert;
		Test.stopTest();

		objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objRoleAssert.Processing_State__c, 'Processing state should be dead.');
		System.assertEquals(strDeadReason, objRoleAssert.Message__c, 'Processing message is incorrect.');

		// Edit and save record without putting it to Dead state (Mimic update caused by Workato)
		// Result = Records should go to Queued status

		update objRoleAssert;
		objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be queued.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test when User Id is changed, Previous User Id is populated
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserIdChange() {
		String strUserIdOne = '200';
		String strUserIdTwo = '202';

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setUserId(strUserIdOne)
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		Test.startTest();
		objZPUserRole.User_Id__c = strUserIdTwo;
		update objZPUserRole;
		Test.stopTest();

		// Assert Processing state changes to Queued
		ZP_User_Role__c objUserRoleAssert = [SELECT Id, User_Id__c, Previous_User_Id__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(strUserIdOne, objUserRoleAssert.Previous_User_Id__c, 'Previous user id is incorrect.');
		System.assertEquals(strUserIdTwo, objUserRoleAssert.User_Id__c, 'User Id is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test when User role is created without User Id, Update processing state to Dead and set error message
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserRoleCreationWithoutUserId() {
		ZPUserRoleTriggerHelper.skipTrigger = true;
		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setUserId(null)
			.build();
		insert objZPUserRole;
		ZPUserRoleTriggerHelper.skipTrigger = false;

		Test.startTest();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.DEAD_STATE, objRoleAssert.Processing_State__c, 'Processing state should be dead.');
		System.assertEquals(ZPUserRoleUtil.USER_ID_MISSING_ON_USER_ROLE, objRoleAssert.Message__c, 'Processing message is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test when User Role Last name is set to Blank. Last name should be auto populated as '-'
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testBlankLastName() {
		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setUserId('1101')
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setLastName(null)
			.build();
		insert objZPUserRole;

		Test.startTest();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Last_Name__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(ZPUserRoleUtil.DEFAULT_LAST_NAME, objRoleAssert.Last_Name__c, 'Last Name is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test when User role is created with invalid User Id, Update processing state to Backlog and set error message
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserRoleCreationWithInvalidUserId() {
		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setUserId('1101')
			.build();
		insert objZPUserRole;

		Test.startTest();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.BACKLOG, objRoleAssert.Processing_State__c, 'Processing state should be backlog.');
		System.assertEquals(ZPUserRoleUtil.USER_ID_DOES_NOT_EXIST_IN_ZP_USER, objRoleAssert.Message__c, 'Processing message is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test when User role is created with and ser user email as blank, Update processing state to Backlog and set error message
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserRoleCreationWithBlankUserEmail() {
		String strUserId = '1101';

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId(strUserId)
			.setExternalKey('ZP777777777777097')
			.setEmail(null)
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Company')
			.setCustomId('343434343101')
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setCompanyId('1212312312')
			.setUserId(strUserId)
			.build();
		insert objZPUserRole;

		Test.startTest();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.BACKLOG, objRoleAssert.Processing_State__c, 'Processing state should be backlog.');
		System.assertEquals(ZPUserRoleUtil.USER_DOES_NOT_HAVE_EMAIL, objRoleAssert.Message__c, 'Processing message is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test when User role is created with invalid company Id, Update processing state to Backlog and set error message
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserRoleCreationWithInvalidCompanyId() {
		String strUserId = '1101';

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId(strUserId)
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Company')
			.setCustomId('343434343101')
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setCompanyId('1212312312')
			.setUserId(strUserId)
			.build();
		insert objZPUserRole;

		Test.startTest();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.BACKLOG, objRoleAssert.Processing_State__c, 'Processing state should be backlog.');
		System.assertEquals(ZPUserRoleUtil.COMPANY_ID_DOES_NOT_EXIST, objRoleAssert.Message__c, 'Processing message is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test when User role is created with invalid accounting firm Id, Update processing state to Backlog and set error message
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserRoleCreationWithInvalidAccFirmId() {
		String strUserId = '1101';

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId(strUserId)
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setAccFirmId('1212312312')
			.setUserId(strUserId)
			.build();
		insert objZPUserRole;

		Test.startTest();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.BACKLOG, objRoleAssert.Processing_State__c, 'Processing state should be backlog.');
		System.assertEquals(ZPUserRoleUtil.ACC_FIRM_DOES_NOT_EXIST, objRoleAssert.Message__c, 'Processing message is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if User Role is Created without firm or company id and not a payroll admin, the record should be backlogged
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testRoleWithoutCompanyOrFirmIdBacklog() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Accountant')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		Test.startTest();

		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		Test.stopTest();
		// Assert if User Role got backlogged
		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals('Backlog', objRoleAssert.Processing_State__c, 'Processing State should be backlog.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Freelance Accountant is updated on Contact if
	 *                      ZP User Role is Accountant and
	 *                      Collobarator Type is External Accountant
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testFreelanceAccountant() {
		// Skip Account Trigger for faster Account inserts
		AccountTriggerHelper.skipTrigger = true;
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('123456789').build();
		insert objCompAccount;

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		insert objResellerAccount;
		AccountTriggerHelper.skipTrigger = false;

		// Skip Contact Trigger for faster Contact inserts
		ContactTriggerHelper.skipTrigger = true;
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setFirstName('First Name')
			.setLastName('Last Name')
			.setEmail('freelanceaccountant@gusto.com')
			.setAccountId(objCompAccount.Id)
			.setZPUserId('159753')
			.setZPUserRole('Accountant')
			.build();
		insert objContact;
		ContactTriggerHelper.skipTrigger = false;

		Test.startTest();

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('ZP User')
			.setCustomId('159753')
			.setEmail(objContact.Email)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.setProcessingState('Queued')
			.build();

		insert objZPUser;

		List<ZP_User_Role__c> list_RoleToInsert = new List<ZP_User_Role__c>();
		ZP_User_Role__c objAccountantRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('100')
			.setUserId(objZPUser.Id__c)
			.setAccFirmId(objResellerAccount.ZP_Firm_Id__C)
			.setType('Role::Accountant')
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		list_RoleToInsert.add(objAccountantRole);

		// Create a new payroll admin and set them as external collabarator
		ZP_User_Role__c objPayrollAdminRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('200')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompAccount.ZP_Company_Id__c)
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(System.now())
			.setCollaboratorType('External Accountant')
			.build();

		list_RoleToInsert.add(objPayrollAdminRole);
		insert list_RoleToInsert;

		for (ZP_User_Role__c zpUserRole : list_RoleToInsert) {
			zpUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		}
		update list_RoleToInsert;

		Test.stopTest();

		Contact objContactAssert = [SELECT Id, Freelance_Accountant__c FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(true, objContactAssert.Freelance_Accountant__c, 'Freelance Accountant should be set to true on Contact.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Payroll Method Type is updated on ZP_User_Role__c from ZP_Employee__c
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testPayrollMethodTypeUpdateFromZPEmployee() {
		// Skip Account Trigger for faster Account inserts
		AccountTriggerHelper.skipTrigger = true;
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('123456789').build();
		insert objCompAccount;

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		insert objResellerAccount;
		AccountTriggerHelper.skipTrigger = false;

		// Skip Contact Trigger for faster Contact inserts
		ContactTriggerHelper.skipTrigger = true;
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setFirstName('First Name')
			.setLastName('Last Name')
			.setEmail('freelanceaccountant@gusto.com')
			.setAccountId(objCompAccount.Id)
			.setZPUserId('159753')
			.setZPUserRole('Accountant')
			.build();
		insert objContact;
		ContactTriggerHelper.skipTrigger = false;

		Test.startTest();
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('ZP User')
			.setCustomId('159753')
			.setEmail(objContact.Email)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.setProcessingState('Queued')
			.build();

		insert objZPUser;

		ZP_Employee__c objEmployee = new ZP_Employee__c(Id__c = '8521234', Payment_Method_Type__c = 'Direct Deposit');
		insert objEmployee;

		ZP_User_Role__c objEmployeeRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('5425425423')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompAccount.ZP_Company_Id__c)
			.setType('Role::Employee')
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(System.now())
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setZPEmployeeId(objEmployee.Id__c)
			.build();

		insert objEmployeeRole;

		objEmployeeRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objEmployeeRole;

		Test.stopTest();

		ZP_User_Role__c objUserRoleAssert = [SELECT Id, Payment_Method_Type__c FROM ZP_User_Role__c WHERE Id = :objEmployeeRole.Id];
		ZP_Employee__c objEmployeeAssert = [SELECT Id, Payment_Method_Type__c FROM ZP_Employee__c WHERE Id = :objEmployee.Id];

		System.assertNotEquals(null, objUserRoleAssert.Payment_Method_Type__c, 'Payment Method Type is null.');
		System.assertEquals(objEmployeeAssert.Payment_Method_Type__c, objUserRoleAssert.Payment_Method_Type__c, 'Payment Method Type not matching on ZP User Role and ZP Employee');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if First Name of Contact is assigned with
	 * 					 Preferred Name on the latest ZP_User_Role__c created.
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testPreferredNameToFirstNameAssignement() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();
		ContactTriggerHelper.skipTrigger = true;
		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		Test.startTest();
		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Test Preferred Name 1')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setCollaboratorType('External Accountant')
			.build();
		insert objZPUserRole1;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole1.Updated_At__c = System.now();
		update objZPUserRole1;

		// Assert contact got created and preferred name is set properly
		Contact objContactInsertAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole1.User_Id__c LIMIT 1];
		System.assertEquals(objZPUserRole1.Preferred_Name__c, objContactInsertAssert.FirstName, 'First Name on contact not equal to Preferred Name.');

		// Create a second role without any preferred name
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343102')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::Employee')
			.setCreatedAt(objZPUser.Created_At__c)
			.setCollaboratorType('External Accountant')
			.build();
		insert objZPUserRole2;

		// Update Processing State to Manually Enqueuued which should associated contact and zp user role
		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole2.Updated_At__c = System.now();
		update objZPUserRole2;

		Contact objContactUpdateAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole2.User_Id__c LIMIT 1];
		// Assert Preferred name did not get changed as preferred name was not set on second zp user role
		System.assertEquals(objZPUserRole1.Preferred_Name__c, objContactUpdateAssert.FirstName, 'First Name on contact not equal to Preferred Name.');

		// Trigger third zp user role creation and set different preferred name
		ZP_User_Role__c objZPUserRole3 = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Test Preferred Name 3')
			.setCustomId('343434343103')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setCollaboratorType('External Accountant')
			.build();
		insert objZPUserRole3;

		// Update Processing State to 'Manually Enqueued' which should update Preferred Name on Contact
		objZPUserRole3.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole3;

		objContactUpdateAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole1.User_Id__c LIMIT 1];

		// Assert Preferred Name got updated on Contact
		System.assertEquals(objZPUserRole3.Preferred_Name__c, objContactUpdateAssert.FirstName, 'First Name on contact not equal to Preferred Name.');

		// Now trigger an update on first zp user role
		objZPUserRole1.Preferred_Name__c = 'New Preferred Name';
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole1.Updated_At__c = System.now();
		update objZPUserRole1;

		// Assert Contact first name did not get update as zp user role 3 is the most recently created record
		// Requirement - First name on contact must be preferred name of the most recently created zp user role
		objContactUpdateAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole1.User_Id__c LIMIT 1];
		System.assertEquals(objZPUserRole3.Preferred_Name__c, objContactUpdateAssert.FirstName, 'First Name on contact not equal to Preferred Name.');
		Test.stopTest();
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Assert if Backlogged or Error ZP User Roles are re-processed when we get ZP User ROles
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testReProcessingUsers() {
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
		System.assertEquals(IntegrationUtils.BACKLOG, objUserAssert.Processing_State__c, 'Processing state should be backlog.');

		// Insert new User Role and assert ZP User went to Queued
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('1010101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId('21121212')
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setFirstName('FNAME')
			.setLastName('LNAME')
			.build();

		insert objZPUserRole;

		Test.startTest();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		objUserAssert = [SELECT Id, Processing_State__c FROM ZP_User__c WHERE Id = :objZPUser.Id];

		// Assert ZP User is Queued
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objUserAssert.Processing_State__c, 'Processing state should be queued.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test cashout fields are updated on Contact
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testCashoutDataUpdate() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Test Preferred Name 1')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact is null.');

		Test.startTest();

		// Update Cashout fields on ZP User Role which should update the same on Contact
		objZPUserRole.Cashout_Eligible_at__c = Date.today();
		objZPUserRole.Cashout_Invited_At__c = Date.today().addDays(1);
		objZPUserRole.Cashout_Disqualified_At__c = Date.today().addDays(2);
		objZPUserRole.Cashout_Enrolled_At__c = Date.today().addDays(3);
		objZPUserRole.Latest_Cashout_Date__c = Date.today().addDays(4);
		objZPUserRole.Cashout_Disqualification_Reasons__c = 'Delinquency reason';

		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		Test.stopTest();

		objContactInsertAssert = [
			SELECT Id, Cashout_Eligible_at__c, Cashout_Invited_At__c, Cashout_Disqualified_At__c, Cashout_Enrolled_At__c, Latest_Cashout_Date__c, Cashout_Disqualification_Reasons__c
			FROM Contact
			WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c
			LIMIT 1
		];

		System.assertEquals(objZPUserRole.Cashout_Eligible_at__c, objContactInsertAssert.Cashout_Eligible_at__c, 'Cashout Eligible at is incorrect on Contact.');
		System.assertEquals(objZPUserRole.Cashout_Invited_At__c, objContactInsertAssert.Cashout_Invited_At__c, 'Cashout Invited at is incorrect on Contact.');
		System.assertEquals(objZPUserRole.Cashout_Disqualified_At__c, objContactInsertAssert.Cashout_Disqualified_At__c, 'Cashout Disqualified at is incorrect on Contact.');
		System.assertEquals(objZPUserRole.Cashout_Enrolled_At__c, objContactInsertAssert.Cashout_Enrolled_At__c, 'Cashout Enrolled at is incorrect on Contact.');
		System.assertEquals(objZPUserRole.Latest_Cashout_Date__c, objContactInsertAssert.Latest_Cashout_Date__c, 'Latest Cashout date is incorrect on Contact.');
		System.assertEquals(objZPUserRole.Cashout_Disqualification_Reasons__c, objContactInsertAssert.Cashout_Disqualification_Reasons__c, 'Cashout Disqualification Reasons is incorrect on Contact.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if certain cashout fields are not overriden
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testCashoutDataOverride() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role and also set cashout fields
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Test Preferred Name 1')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setDisqualificationReasons('Reason 2')
			.setCashoutEligibleAt(Date.today())
			.setCashoutInvitedAt(Date.today().addDays(1))
			.setCashoutEnrolledAt(Date.today().addDays(2))
			.setCashoutDisqualifiedAt(Date.today().addDays(3))
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact was not created.');

		Test.startTest();

		// Update Cashout fields on ZP User Role which should update the same on Contact
		// Assert cashout data was not overriden on Contact
		objZPUserRole.Cashout_Eligible_at__c = Date.today().addDays(4);
		objZPUserRole.Cashout_Invited_At__c = Date.today().addDays(5);
		objZPUserRole.Cashout_Disqualified_At__c = Date.today().addDays(6);
		objZPUserRole.Cashout_Enrolled_At__c = Date.today().addDays(7);
		objZPUserRole.Latest_Cashout_Date__c = Date.today().addDays(8);
		objZPUserRole.Cashout_Disqualification_Reasons__c = 'Reason 4';

		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		Test.stopTest();

		objContactInsertAssert = [
			SELECT Id, Cashout_Eligible_at__c, Cashout_Invited_At__c, Cashout_Disqualified_At__c, Cashout_Enrolled_At__c, Latest_Cashout_Date__c, Cashout_Disqualification_Reasons__c
			FROM Contact
			WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c
			LIMIT 1
		];

		System.assertNotEquals(objZPUserRole.Cashout_Eligible_at__c, objContactInsertAssert.Cashout_Eligible_at__c, 'Cashout Eligible at is incorrect on Contact.');
		System.assertNotEquals(objZPUserRole.Cashout_Invited_At__c, objContactInsertAssert.Cashout_Invited_At__c, 'Cashout Invited at is incorrect on Contact.');
		System.assertNotEquals(objZPUserRole.Cashout_Disqualified_At__c, objContactInsertAssert.Cashout_Disqualified_At__c, 'Cashout Disqualified at is incorrect on Contact.');
		System.assertNotEquals(objZPUserRole.Cashout_Enrolled_At__c, objContactInsertAssert.Cashout_Enrolled_At__c, 'Cashout Enrolled at is incorrect on Contact.');
		System.assertNotEquals(
			objZPUserRole.Cashout_Disqualification_Reasons__c,
			objContactInsertAssert.Cashout_Disqualification_Reasons__c,
			'Cashout Disqualificatio Reasons is incorrect on Contact.'
		);
		// Latest Cashout data can be overriden
		System.assertEquals(objZPUserRole.Latest_Cashout_Date__c, objContactInsertAssert.Latest_Cashout_Date__c, 'Latest Cashout date is incorrect on Contact.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Preferred Name is more than 40 characters, then contact should use first name from zp user role
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testFirstNamePrioritization() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// insert a lengthy preferred name
		String strPreferredName = 'Inserting preferred name with more than 40 characters';

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName(strPreferredName)
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		Test.startTest();
		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;
		Test.stopTest();

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact was not created.');
		System.assertEquals(objZPUserRole.First_Name__c, objContactInsertAssert.FirstName, 'First Name is incorrect on Contact.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if Has_Accountant__c is set based on ZP User Roles Collaborator Type.
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUpdateHasAccountantOnAccount() {
		List<Account> list_Accounts;
		List<ZP_User_Role__c> list_ZPUserRoles;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('12312').build();

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();

		list_Accounts = new List<Account>{ objResellerAccount, objCompanyAccount };

		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('userId1')
			.setExternalKey('ExternalKey1')
			.setEmail('zpuser1@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Insert an Accountant Role
		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRoleId1')
			.setUserId(objZPUser.Id__c)
			.setAccFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(objZPUser.Created_At__c)
			.setAccountantClientToken('https://gusto-staging.zenefits.com/accountant_client_token')
			.build();

		insert objZPUserRole1;

		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;

		// Assert Reseller Contact got created and linked to Accounting Firm
		Contact objContactAssert = [SELECT Id, RecordTypeId, AccountId, Accountant_Client_Invitation_Link__c FROM Contact WHERE Email = :objZPUser.Email__c];
		System.assertEquals(ContactUtil.RESELLER_CONTACT_RT_ID, objContactAssert.RecordTypeId, 'Contact Record Type is incorrect.');
		System.assertEquals(objResellerAccount.Id, objContactAssert.AccountId, 'Contact Account is incorrect.');
		System.assertEquals(objZPUserRole1.Accountant_Client_Invitation_Link__c, objContactAssert.Accountant_Client_Invitation_Link__c, 'Accountant Client Token is incorrect.');

		Test.startTest();

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('200')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(System.now())
			.setCollaboratorType(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL)
			.setIsAccountant(true)
			.build();

		insert objZPUserRole2;

		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole2;

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole2.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Message__c, 'Processing message is incorrect.');

		// Assert Has Accountant got updated on Account
		Account objCompanyAccountAssert = [SELECT Id, Has_Accountant__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL, objCompanyAccountAssert.Has_Accountant__c, 'Has Accountant is incorrect on account.');

		ZP_User_Role__c objZPUserRole3 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRoleId3')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setCollaboratorType(ZPUserRoleUtil.HAS_ACCOUNTANT_EXTERNAL)
			.setIsAccountant(true)
			.build();

		insert objZPUserRole3;

		objZPUserRole3.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole3;

		Test.stopTest();

		// Assert Has Accountant got updated on Account
		objCompanyAccountAssert = [SELECT Id, Has_Accountant__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL_EXTERNAL, objCompanyAccountAssert.Has_Accountant__c, 'Has Accountant is incorrect on account.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Has Accountant is updated to different values on multiple companies
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testHasAccountantUpdateOnMultipleCompanies() {
		List<Account> list_Accounts;
		List<ZP_User_Role__c> list_ZPUserRoles;

		Account objCompanyAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('12312').build();
		Account objCompanyAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 2').setZPCompanyId('12313').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();

		list_Accounts = new List<Account>{ objResellerAccount, objCompanyAccount1, objCompanyAccount2 };

		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('userId1')
			.setExternalKey('ExternalKey1')
			.setEmail('zpuser1@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Insert an Accountant Role
		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRoleId1')
			.setUserId(objZPUser.Id__c)
			.setAccFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(objZPUser.Created_At__c)
			.build();

		insert objZPUserRole1;

		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;

		// Assert Reseller Contact got created and linked to Accounting Firm
		Contact objContactAssert = [SELECT Id, RecordTypeId, AccountId FROM Contact WHERE Email = :objZPUser.Email__c];
		System.assertEquals(ContactUtil.RESELLER_CONTACT_RT_ID, objContactAssert.RecordTypeId, 'Contact Record Type is incorrect.');
		System.assertEquals(objResellerAccount.Id, objContactAssert.AccountId, 'Contact Account is incorrect.');

		Test.startTest();

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('200')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount1.ZP_Company_Id__c)
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(System.now())
			.setCollaboratorType(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL)
			.setIsAccountant(true)
			.build();

		insert objZPUserRole2;

		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole2;

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole2.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Message__c, 'Processing message is incorrect.');

		// Assert Has Accountant got updated on Account
		Account objCompanyAccountAssert = [SELECT Id, Has_Accountant__c FROM Account WHERE Id = :objCompanyAccount1.Id];
		System.assertEquals(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL, objCompanyAccountAssert.Has_Accountant__c, 'Has Accountant is incorrect on account.');

		ZP_User_Role__c objZPUserRole3 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRoleId3')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount2.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setCollaboratorType(ZPUserRoleUtil.HAS_ACCOUNTANT_EXTERNAL)
			.setIsAccountant(true)
			.build();

		insert objZPUserRole3;

		objZPUserRole3.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole3;

		Test.stopTest();

		// Has Accountant on Company 1 should remain internal
		objCompanyAccountAssert = [SELECT Id, Has_Accountant__c FROM Account WHERE Id = :objCompanyAccount1.Id];
		System.assertEquals(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL, objCompanyAccountAssert.Has_Accountant__c, 'Has Accountant is incorrect on account.');

		// Has Accountant on Company 2 should be External
		objCompanyAccountAssert = [SELECT Id, Has_Accountant__c FROM Account WHERE Id = :objCompanyAccount2.Id];
		System.assertEquals(ZPUserRoleUtil.HAS_ACCOUNTANT_EXTERNAL, objCompanyAccountAssert.Has_Accountant__c, 'Has Accountant is incorrect on account.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if multiple user roles are available, signatory role does not update preferred name on Contact
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testSignatoryPreferredNameUpdate() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact was not created.');
		System.assertEquals(objZPUserRole.Preferred_Name__c, objContactInsertAssert.FirstName, 'Contact Name should be same as ZP User Role Preferred Name.');

		Test.startTest();

		// Create a new  Signatory ZP User Role
		// Result Preferred Name on Contact Should not be updated
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Signatory')
			.setCustomId('343434343102')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::Signatory')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('Signatory')
			.build();
		insert objZPUserRole2;

		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole2.Updated_At__c = System.now();
		update objZPUserRole2;

		Test.stopTest();

		// Assert First name on Contact was not updated to Signatory Role
		objContactInsertAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact was not created.');
		System.assertEquals(objZPUserRole.Preferred_Name__c, objContactInsertAssert.FirstName, 'Contact Name should be same as ZP User Role Preferred Name.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Account Id on Contact is updated with company id on the most recent user role
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testContactUpdateFromUserRole() {
		ContactTriggerHelper.skipTrigger = true;
		// Create Two Accounts with different company ids
		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Company 100').setZpCompanyId('100').build();
		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Company 200').setZpCompanyId('200').build();

		List<Account> list_Accounts = new List<Account>{ objAccount1, objAccount2 };
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('accountupdate@gmail.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount1.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName, AccountId FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact was not created.');
		// Assert contact got mapped to new first account
		System.assertEquals(objAccount1.Id, objContactInsertAssert.AccountId, 'Contact Account is incorrect.');

		Test.startTest();

		// Insert a new user role with different company id
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setCustomId('343434343102')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount2.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole2;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole2.Updated_At__c = System.now();
		update objZPUserRole2;

		Test.stopTest();

		objContactInsertAssert = [SELECT Id, AccountId FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		// Assert contact got mapped to second account
		System.assertEquals(objAccount2.Id, objContactInsertAssert.AccountId, 'Contact Account is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if User Role is Deleted, Account Id on Contact is moved to the company id on most recent non-deleted user role
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUserRoleDeletion() {
		ContactTriggerHelper.skipTrigger = true;
		// Create Two Accounts with different company ids
		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Company 100').setZpCompanyId('100').build();
		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Company 200').setZpCompanyId('200').build();

		List<Account> list_Accounts = new List<Account>{ objAccount1, objAccount2 };
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('accountupdate@gmail.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setLastName('NA')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount1.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName, AccountId FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact was not created.');
		// Assert contact got mapped to first account
		System.assertEquals(objAccount1.Id, objContactInsertAssert.AccountId, 'Contact Account is incorrect.');

		Test.startTest();

		// Insert a new user role with different company id
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setLastName('NA')
			.setCustomId('343434343102')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount2.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole2;

		// Update Processing State to Manually Enqueuued which will trigger Contact update
		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole2.Updated_At__c = System.now();
		update objZPUserRole2;

		objContactInsertAssert = [SELECT Id, AccountId FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		// Assert contact got mapped to second account
		System.assertEquals(objAccount2.Id, objContactInsertAssert.AccountId, 'Contact Account is incorrect.');

		// Delete second User Role. Account Id on Contact must be changed to company id on the first user role

		objZPUserRole2.Deleted_At__c = System.today();
		// Update Processing State to Manually Enqueuued which will trigger Contact update
		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole2.Updated_At__c = System.now();
		update objZPUserRole2;

		Test.stopTest();

		objContactInsertAssert = [SELECT Id, AccountId FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		// Assert contact got mapped to second account
		System.assertEquals(objAccount2.Id, objContactInsertAssert.AccountId, 'Contact Account is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if User Role processing without company or accounting firm id.
	 * 				  If User Role has no company or accounting firm id and if it exists along with payroll admin,
	 * 				  the user role should not be backlogged
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testRoleWithoutCompanyOrFirmIdProcessing() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Payroll Admin')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Contact was not created.');

		Test.startTest();

		// Create a User Role without Company or Accounting Firm Id
		// Result it should be processed
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('No Id')
			.setCustomId('343434343103')
			.setUserId(objZPUser.Id__c)
			.setCreatedAt(System.now())
			.setType('Role::Accountant')
			.setCreatedAt(objZPUser.Created_At__c)
			.build();
		insert objZPUserRole2;

		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole2.Updated_At__c = System.now();
		update objZPUserRole2;

		Test.stopTest();

		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole2.Id];
		System.assertEquals('Processed', objRoleAssert.Processing_State__c, 'Processing State should be Processed.');

		// Assert First name on Contact was not updated to Signatory Role
		objContactInsertAssert = [SELECT Id, FirstName, ZP_User_Role_Text__c FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert.ZP_User_Role_Text__c.contains('Accountant'), 'ZP User Role Text is incorrect on contact.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if inactive contacts are reactivated by ZP User Role
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testReactivateContact() {
		Contact objContact = [SELECT Id, Email FROM Contact WHERE Email = 'companycontactsetup1@contact.com' LIMIT 1];

		objContact.Inactive_Zp_User__c = true;

		ContactTriggerHelper.skipTrigger = true;
		update objContact;
		ContactTriggerHelper.skipTrigger = false;

		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = :objContact.Email LIMIT 1];

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.EMPLOYEE)
			.setZPEmployeeId('employeeId1')
			.setAccFirmId('firmIdSetup1')
			.setCreatedAt(System.now())
			.build();
		insert objZPUserRole1;

		Test.startTest();
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');

		Contact objContactAssert = [SELECT Id, Inactive_Zp_User__c FROM Contact WHERE Email = :objZPUser1.Email__c];
		System.assertEquals(false, objContactAssert.Inactive_Zp_User__c, 'Inactive ZP User is incorrect on Contact - should be set to true.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if user role is deleted, relation between contact and zp user role is removed
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testResetZPUserFieldsIfDeleted() {
		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testusersetup2@test.com' LIMIT 1];

		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Company')
			.setCustomId('343434343101')
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setCompanyId('companyIdSetup1')
			.setUserId(objZPUser1.Id__c)
			.build();
		insert objZPUserRole;

		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Contact__c, Company_Account__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertNotEquals(null, objRoleAssert.Contact__c, 'Contact is null.');
		System.assertNotEquals(null, objRoleAssert.Company_Account__c, 'Company Name is null.');

		Test.startTest();
		objZPUserRole.Deleted_At__c = System.now();
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;
		Test.stopTest();

		objRoleAssert = [SELECT Id, Processing_State__c, Contact__c, Company_Account__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertEquals(null, objRoleAssert.Contact__c, 'Contact is null.');
		System.assertEquals(null, objRoleAssert.Company_Account__c, 'Company Name is null.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if a new Contact is inserted for a UserRole with Accounting Firm Id
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testInsertContactWithResellerUserRole() {
		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testusersetup2@test.com' LIMIT 1];

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.ACCOUNTANT)
			.setAccFirmId('firmIdSetup1')
			.setCreatedAt(System.now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objZPUserRole1;

		Test.startTest();
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		Contact objContactsAssert = [SELECT Id, FirstName, RecordTypeId FROM Contact WHERE Email = :objZPUser1.Email__c];
		System.assertEquals(objContactsAssert.FirstName, objZPUserRole1.First_Name__c, 'Contact first name should be same as on ZP User Role.');
		System.assertEquals(ContactUtil.RESELLER_CONTACT_RT_ID, objContactsAssert.RecordTypeId, 'Contact Record Type is incorrect - should be Reseller.');

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Contact__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertEquals(objContactsAssert.Id, objRoleAssert.Contact__c, 'Contact is incorrect on ZP User Role.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if a new Contact is inserted for a UserRole with Company Id
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testUpdateContactWithCompanyUserRole() {
		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'companycontactsetup1@contact.com' LIMIT 1];

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.SIGNATORY)
			.setCompanyId('companyIdSetup1')
			.setCreatedAt(System.now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objZPUserRole1;

		Test.startTest();
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');

		Contact objContactsAssert = [SELECT Id, FirstName, RecordTypeId FROM Contact WHERE Email = :objZPUser1.Email__c];
		System.assertEquals(objZPUserRole1.First_Name__c, objContactsAssert.FirstName, 'Contact first name should be same as on ZP User Role.');
		System.assertEquals(ContactUtil.COMPANY_CONTACT_RT_ID, objContactsAssert.RecordTypeId, 'Contact Record Type is incorrect.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test If any accountant role is find related to one ZP User. Record type of Contact must be Reseller
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testAccountantPrioiritzation() {
		List<ZP_User_Role__c> list_ZPUserRoles;
		String strAccFirmId = '8788796';

		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testusersetup2@test.com' LIMIT 1];

		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Company')
			.setCustomId('343434343101')
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.now())
			.setFirstName('First Name')
			.setCompanyId('companyIdSetup1')
			.setUserId(objZPUser1.Id__c)
			.build();
		insert objZPUserRole;

		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole;

		Contact objContactsAssert = [SELECT Id, FirstName, RecordTypeId FROM Contact WHERE Email = :objZPUser1.Email__c];
		System.assertEquals(ContactUtil.COMPANY_CONTACT_RT_ID, objContactsAssert.RecordTypeId, 'Contact Record Type is incorrect.');

		// If Accountant Role is Created, Record Type should change from Contact to Reseller

		ZP_User_Role__c objAccountantRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.ACCOUNTANT)
			.setAccFirmId('firmIdSetup1')
			.setCreatedAt(System.now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objAccountantRole;

		Test.startTest();
		objAccountantRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objAccountantRole;
		Test.stopTest();

		objContactsAssert = [SELECT Id, FirstName, RecordTypeId FROM Contact WHERE Email = :objZPUser1.Email__c];
		System.assertEquals(ContactUtil.RESELLER_CONTACT_RT_ID, objContactsAssert.RecordTypeId, 'Contact Record Type is incorrect.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if ABC Lead Match is updated on Lead
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testSetLeadInformation() {
		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testleadsetup1@lead.com' LIMIT 1];

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.CONTRACTOR)
			.setAccFirmId('firmIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.setCollaboratorType(ZPUserRoleUtil.EXTERNAL_ACCOUNTANT)
			.build();
		insert objZPUserRole1;

		Account objResellerAcct = [SELECT Id FROM Account WHERE ZP_Firm_Id__c = :objZPUserRole1.Accounting_Firm_Id__c];
		Account_Email_Domain__c objDomain = new Account_Email_Domain__c(Name = 'lead.com', Account__c = objResellerAcct.Id);
		insert objDomain;

		Test.startTest();
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Accounting_Firm_Account__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertNotEquals(null, objRoleAssert.Accounting_Firm_Account__c, 'Accounting Firm Account is null on ZP User Role.');

		Lead objLeadAssert = [SELECT Id, ZP_User_Id__c, ABC_Lead_Match__c, ABC_Match_Account__c FROM Lead WHERE Email = :objZPUser1.Email__c];
		System.assertEquals(objZPUser1.Id__c, objLeadAssert.ZP_User_Id__c, 'ZP User Id is incorrect on Lead.');
		System.assertEquals(true, objLeadAssert.ABC_Lead_Match__c, 'ABC Lead Match should be true on a Lead.');
		System.assertEquals(objRoleAssert.Accounting_Firm_Account__c, objLeadAssert.ABC_Match_Account__c, 'ABC Match Account is incorrect on a Lead.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if Referred By is updated on Lead
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testSetLeadInformation2() {
		Lead objLead = [SELECT Id, Email FROM Lead WHERE Email = 'testleadsetup1@lead.com'];

		objLead.ABC_Lead_Match__c = true;

		LeadTriggerHelper.skipTrigger = true;
		update objLead;
		LeadTriggerHelper.skipTrigger = false;

		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = :objLead.Email LIMIT 1];

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.CONTRACTOR)
			.setCompanyId('companyIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.setCollaboratorType(ZPUserRoleUtil.EXTERNAL_BOOKKEEPER)
			.build();
		insert objZPUserRole1;

		Test.startTest();
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Company_Account__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertNotEquals(null, objRoleAssert.Company_Account__c, 'Company Account is null on ZP User Role.');

		Lead objLeadAssert = [SELECT Id, Referred_By__c, ZP_User_Id__c FROM Lead WHERE Email = :objZPUser1.Email__c];
		System.assertEquals(objZPUser1.Id__c, objLeadAssert.ZP_User_Id__c, 'ZP User Id on Lead not matching Id__c on zp user role.');
		System.assertEquals(objRoleAssert.Company_Account__c, objLeadAssert.Referred_By__c, 'Lead Referred By not matching ZP User Role Company Account.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if lead update is skipped if contact exists with same email
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testSkipLeadUpdateIfContactsExistsWithEmail() {
		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'companycontactsetup1@contact.com' LIMIT 1];

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('FName1')
			.setLastName('LName1')
			.setEmail(objZPUser1.Email__c)
			.setPhone('1674567890')
			.setCompany('Test Accountant')
			.setLeadSource(LeadUtil.LEADSOURCE_LIVE_CHAT)
			.build();

		LeadTriggerHelper.skipTrigger = true;
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.CONTRACTOR)
			.setAccFirmId('firmIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.setCollaboratorType(ZPUserRoleUtil.EXTERNAL_BOOKKEEPER)
			.build();
		insert objZPUserRole1;

		Test.startTest();
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');

		Lead objLeadAssert = [SELECT Id, ZP_User_Id__c FROM Lead WHERE Email = :objZPUser1.Email__c];
		System.assertNotEquals(objZPUser1.Id__c, objLeadAssert.ZP_User_Id__c, 'ZP User Id on Lead not matching Id__c on zp user role.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if lead update is skipped if lead is converted
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testSkipLeadUpdateIfLeadIsConverted() {
		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testusersetup2@test.com' LIMIT 1];

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail(objZPUser1.Email__c)
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('LinkedIn')
			.build();
		insert objLead;

		// Convert Lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.CONTRACTOR)
			.setAccFirmId('firmIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.setCollaboratorType(ZPUserRoleUtil.EXTERNAL_BOOKKEEPER)
			.build();
		insert objZPUserRole1;

		Test.startTest();
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');

		Lead objLeadAssert = [SELECT Id, ZP_User_Id__c FROM Lead WHERE Email = :objZPUser1.Email__c];
		System.assertNotEquals(objZPUser1.Id__c, objLeadAssert.ZP_User_Id__c, 'ZP User Id on Lead not matching Id__c on zp user role.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Accountng Firm is updated on related payroll admin and signatory roles
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testSetUserRoleAccountingFirmInfo() {
		Account objResellerAcct = [SELECT Id, ZP_Firm_Id__c FROM Account WHERE Name = 'Test Reseller Acc'];

		// Insert new zp user
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Insert payroll admin role
		ZP_User_Role__c objPayrollAdminRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('67887')
			.setUserId(objZPUser.Id__c)
			.setType(ZPUserRoleUtil.PAYROLL_ADMIN)
			.setAccFirmId(objResellerAcct.ZP_Firm_Id__c)
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objPayrollAdminRole;

		// Insert signatory role
		ZP_User_Role__c objSignatoryRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('9877567')
			.setUserId(objZPUser.Id__c)
			.setType(ZPUserRoleUtil.SIGNATORY)
			.setAccFirmId(objResellerAcct.ZP_Firm_Id__c)
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objSignatoryRole;

		// Insert accountant role
		ZP_User_Role__c objAccRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('786767')
			.setUserId(objZPUser.Id__c)
			.setType(ZPUserRoleUtil.ACCOUNTANT)
			.setAccFirmId(objResellerAcct.ZP_Firm_Id__c)
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objAccRole;

		Test.startTest();
		// Process account role
		objAccRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objAccRole;
		Test.stopTest();

		// assert accounting firm role and assert signatory and payroll admin roles
		ZP_User_Role__c objPayrollAdminRoleAssert = [SELECT Id, Accounting_Firm_Account__c, Accounting_Firm_Account__r.Id FROM ZP_User_Role__c WHERE Id = :objPayrollAdminRole.Id];
		System.assertEquals(objResellerAcct.Id, objPayrollAdminRoleAssert?.Accounting_Firm_Account__r?.Id, 'Accoutning Firm Account is incorrect.');

		ZP_User_Role__c objSignatoryRoleAssert = [SELECT Id, Accounting_Firm_Account__c, Accounting_Firm_Account__r.Id FROM ZP_User_Role__c WHERE Id = :objSignatoryRole.Id];
		System.assertEquals(objResellerAcct.Id, objSignatoryRoleAssert?.Accounting_Firm_Account__r?.Id, 'Accoutning Firm Account is incorrect.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if opportunity contact roles are inserted in company opportunities
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testCompanyOppConRoleInsert() {
		Rolesets__c objRolesets = new Rolesets__c(
			Components__c = 'ZPUserRoleTriggerHelper',
			Roles__c = ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN,
			Roleset_Name__c = 'Test-Contact-Role-ZPUserTrigger',
			Name = 'Test-Contact-Role-ZPUserTrigger'
		);
		insert objRolesets;

		Account objCompanyAccount = [SELECT Id FROM Account WHERE ZP_Company_Id__c = 'companyIdSetup1'];

		// Insert company opportunity
		Opportunity objCompanyOpptuy = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(ZPUserRoleUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Oppty - Payroll')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();

		OpportunityTriggerHelper.skipTrigger = true;
		insert objCompanyOpptuy;

		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testusersetup2@test.com' LIMIT 1];

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN)
			.setCompanyId('companyIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objZPUserRole1;

		Test.startTest();
		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;
		Test.stopTest();

		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Role_Name__c, Contact__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertNotEquals(null, objRoleAssert.Contact__c, 'Contact is null on ZP User Role.');

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Account.ZP_Company_Id__c = 'companyIdSetup1' AND RecordTypeId = :ZPUserRoleUtil.COMPANY_OPPTY_RT_ID];

		OpportunityContactRole objOppConRole = [SELECT Id, OpportunityId, Role FROM OpportunityContactRole WHERE ContactId = :objRoleAssert.Contact__c AND OpportunityId = :objOpportunity.Id LIMIT 1];
		System.assertEquals(objRoleAssert.Role_Name__c, objOppConRole.Role, 'Role is not matching on Contact and ZP User Role.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if opportunity contact roles are inserted on BoR opportunities
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testBoRContactRoleInsert() {
		Rolesets__c objRolesets = new Rolesets__c(
			Components__c = 'ZPUserRoleTriggerHelper',
			Roles__c = ZPUserRoleUtil.BENEFITS_ADMIN,
			Roleset_Name__c = 'Test-Contact-Role-ZPUserTrigger',
			Name = 'Test-Contact-Role-ZPUserTrigger'
		);
		insert objRolesets;

		Account objCompanyAccount = [SELECT Id FROM Account WHERE ZP_Company_Id__c = 'companyIdSetup1'];

		// Insert company opportunity
		Opportunity objBoROppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(ZPUserRoleUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Company Oppty - BoR Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();

		OpportunityTriggerHelper.skipTrigger = true;
		insert objBoROppty;

		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testusersetup2@test.com' LIMIT 1];

		ZP_User_Role__c objPayrollAdmin = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('7876567567')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN)
			.setCompanyId('companyIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objPayrollAdmin;

		objPayrollAdmin.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objPayrollAdmin;

		// Assert user role is processed and contact got created
		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Role_Name__c, Contact__c FROM ZP_user_Role__c WHERE Id = :objPayrollAdmin.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertNotEquals(null, objRoleAssert.Contact__c, 'Contact is null on ZP User Role.');

		ZP_User_Role__c objBenefitsAdmin = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('08979798')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.BENEFITS_ADMIN)
			.setCompanyId('companyIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objBenefitsAdmin;

		Test.startTest();
		// Update Benefits Admin role which should create new contact role on BoR opportunity
		objBenefitsAdmin.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objBenefitsAdmin;
		Test.stopTest();

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Account.ZP_Company_Id__c = 'companyIdSetup1' AND RecordTypeId = :ZPUserRoleUtil.BENEFITS_BOR_OPPTY_RT_ID];

		OpportunityContactRole objOppConRole = [SELECT Id, OpportunityId, Role FROM OpportunityContactRole WHERE ContactId = :objRoleAssert.Contact__c AND OpportunityId = :objOpportunity.Id LIMIT 1];
		System.assertEquals(ZPUserRoleUtil.BENEFITS_ADMIN, objOppConRole.Role, 'Contact Role should be Benefits Admin.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if opportunity contact roles are deleted when user role is deleted
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testCompanyOppConRoleDelete() {
		Rolesets__c objRolesets = new Rolesets__c(
			Components__c = 'ZPUserRoleTriggerHelper',
			Roles__c = ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN,
			Roleset_Name__c = 'Test-Contact-Role-ZPUserTrigger',
			Name = 'Test-Contact-Role-ZPUserTrigger'
		);
		insert objRolesets;

		Account objCompanyAccount = [SELECT Id FROM Account WHERE ZP_Company_Id__c = 'companyIdSetup1'];

		// Insert company opportunity
		Opportunity objCompanyOpptuy = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(ZPUserRoleUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Oppty - Payroll')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();

		OpportunityTriggerHelper.skipTrigger = true;
		insert objCompanyOpptuy;

		ZP_User__c objZPUser1 = [SELECT Id, Id__c, Email__c FROM ZP_User__c WHERE Email__c = 'testusersetup2@test.com' LIMIT 1];

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('roleId1')
			.setUserId(objZPUser1.Id__c)
			.setType(ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN)
			.setCompanyId('companyIdSetup1')
			.setCreatedAt(System.Now())
			.setFirstName('Test Role Fname')
			.setLastName('Test Role Lname')
			.build();
		insert objZPUserRole1;

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;

		ZP_user_Role__c objRoleAssert = [SELECT Id, Processing_State__c, Role_Name__c, Contact__c FROM ZP_user_Role__c WHERE Id = :objZPUserRole1.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'Processing state should be processed.');
		System.assertNotEquals(null, objRoleAssert.Contact__c, 'Contact is null on ZP User Role.');

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Account.ZP_Company_Id__c = 'companyIdSetup1' AND RecordTypeId = :ZPUserRoleUtil.COMPANY_OPPTY_RT_ID];

		OpportunityContactRole objOppConRole = [SELECT Id, OpportunityId, Role FROM OpportunityContactRole WHERE ContactId = :objRoleAssert.Contact__c AND OpportunityId = :objOpportunity.Id LIMIT 1];
		System.assertEquals(objRoleAssert.Role_Name__c, objOppConRole.Role, 'Role is not matching on Contact and ZP User Role.');

		// Test deletion part
		Test.startTest();
		objRoleAssert.Deleted_At__c = System.now();
		objRoleAssert.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objRoleAssert;
		Test.stopTest();

		// Assert contact roles got deleted
		Integer intCountRoles = [SELECT COUNT() FROM OpportunityContactRole WHERE ContactId = :objRoleAssert.Contact__c AND OpportunityId = :objOpportunity.Id LIMIT 1];
		System.assertEquals(0, intCountRoles, 'Contact Roles count is incorrect.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if user roles are re-processed
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testReProcessUserRoles() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('test name')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		// Create a second ZP User Role
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('test name')
			.setCustomId('8765654')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole2;

		Test.startTest();
		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;
		Test.stopTest();

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, FirstName, AccountId FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'Error during contact creation.');

		ZP_User_Role__c objRoleAssert = [SELECT Id, Contact__c, Company_Account__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole2.Id];
		System.assertEquals(objContactInsertAssert.Id, objRoleAssert.Contact__c, 'ZP User Role Contact is incorrect.');
		System.assertEquals(objContactInsertAssert.AccountId, objRoleAssert.Company_Account__c, 'Company Account is incorrect on ZP User Role.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if tier update status is updated on insert
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUpdateTierStatusOnInsert() {
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];

		objCompanyAccount.Tier_Update_Status__c = ZPUserRoleUtil.TIER_UPDATE_PROCESSED;
		AccountTriggerHelper.skipTrigger = true;
		update objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		Test.startTest();
		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('test name')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;
		Test.stopTest();

		objCompanyAccount = [SELECT Id, Name, Tier_Update_Status__c FROM Account WHERE Name = 'Test Company Acc'];
		System.assertEquals(ZPUserRoleUtil.TIER_UPDATE_NOT_PROCESSED, objCompanyAccount.Tier_Update_Status__c, 'Tier Update Status is incorrect on Account.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if tier update status is updated on deleting user roles
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUpdateTierStatusOnDelete() {
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];

		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('176458136452')
			.setExternalKey('ZP777777777777097')
			.setEmail('preferredname@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('test name')
			.setCustomId('343434343101')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('First Name')
			.build();
		insert objZPUserRole;

		objCompanyAccount.Tier_Update_Status__c = ZPUserRoleUtil.TIER_UPDATE_PROCESSED;
		AccountTriggerHelper.skipTrigger = true;
		update objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();
		objZPUserRole.Deleted_At__c = System.now();
		update objZPUserRole;
		Test.stopTest();

		objCompanyAccount = [SELECT Id, Name, Tier_Update_Status__c FROM Account WHERE Name = 'Test Company Acc'];
		System.assertEquals(ZPUserRoleUtil.TIER_UPDATE_NOT_PROCESSED, objCompanyAccount.Tier_Update_Status__c, 'Tier Update Status is incorrect on Account.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if unconverted company leads are converted from ZP user role
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testCompanyLeadConversionFlowFromUserRole() {
		// Skip Account Trigger for faster Account inserts
		AccountTriggerHelper.skipTrigger = true;
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('76767645698').build();
		insert objCompAccount;

		// Create a new company lead
		LeadTriggerHelper.skipTrigger = true;
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('email@leadconvert.com')
			.setPhone('123456789')
			.setCompany('Lead Convert')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		// Create a new zp user
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test ZP User')
			.setCustomId('67665654')
			.setEmail(objLead.Email)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('Test Preferred Name 1')
			.setCustomId('67987658')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType('Role::PayrollAdmin')
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('Test Fname')
			.setLastName('Test Lname')
			.build();
		insert objZPUserRole;

		Test.startTest();
		Database.executeBatch(new BatchCleanUpZPUserRoles(), 1);
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedContact.Email, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];
		// Assert lead got converted
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted.');
		System.assertEquals(objCompAccount.Id, objLeadAssert.ConvertedAccountId, 'Account Id is incorrect on Lead ConvertedAccountId');
		System.assertNotEquals(null, objLeadAssert.ConvertedContactId, 'Converted Contact Id is null on Lead.');
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted Opportunity Id is null on Lead.');
		System.assertEquals(objZPUser.Email__c, objLeadAssert.ConvertedContact.Email, 'Email is incorrect on converted contact - should match Email__c on ZP User.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if unconverted reseller leads are converted from ZP user role
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testResellerLeadConversionFlowFromUserRole() {
		// Skip Account Trigger for faster Account inserts
		AccountTriggerHelper.skipTrigger = true;
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Discovery Account').setZPFirmId('4561111111').build();
		insert objResellerAccount;

		// Create a new company lead
		LeadTriggerHelper.skipTrigger = true;
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@leadconvert.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		// Create a new zp user
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test ZP User')
			.setCustomId('67665654')
			.setEmail(objLead.Email)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();
		insert objZPUser;

		// Create a new accountant ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('87786767')
			.setUserId(objZPUser.Id__c)
			.setAccFirmId(objResellerAccount.ZP_Firm_Id__c)
			.setType('Role::Accountant')
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.build();
		insert objZPUserRole;

		Test.startTest();
		Database.executeBatch(new BatchCleanUpZPUserRoles(), 1);
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedContact.Email, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];
		// Assert lead got converted
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted.');
		System.assertEquals(objResellerAccount.Id, objLeadAssert.ConvertedAccountId, 'Account Id is incorrect on Lead ConvertedAccountId');
		System.assertNotEquals(null, objLeadAssert.ConvertedContactId, 'Converted Contact Id is null on Lead.');
		System.assertEquals(null, objLeadAssert.ConvertedOpportunityId, 'Converted Opportunity Id is null on Lead.');
		System.assertEquals(objZPUser.Email__c, objLeadAssert.ConvertedContact.Email, 'Email is incorrect on converted contact - should match Email__c on ZP User.');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if Is_Billing_Admin__c on Contact is set based on ZP User Roles Billing_Admin__c & Deleted_At__c.
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testUpdateIsBillingAdminOnContact() {
		List<Account> list_Accounts;
		List<ZP_User_Role__c> list_ZPUserRoles;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('12312').build();

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();

		list_Accounts = new List<Account>{ objResellerAccount, objCompanyAccount };

		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();
		// Insert a new ZP User Record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test Prefrred Name')
			.setCustomId('userId1')
			.setExternalKey('ExternalKey1')
			.setEmail('zpuser1@test.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.setLastSignInAt(System.now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		// Insert an PayrollAdmin Role
		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRoleId1')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(System.now())
			.setCollaboratorType(ZPUserRoleUtil.EXTERNAL_ACCOUNTANT)
			.setIsAccountant(true)
			.build();
		insert objZPUserRole1;

		objZPUserRole1.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole1;

		// Assert Reseller Contact got created and linked to Accounting Firm
		Contact objContactAssert = [SELECT Id, RecordTypeId, AccountId, Is_Billing_Admin__c FROM Contact WHERE Email = :objZPUser.Email__c];
		System.assertEquals(ContactUtil.COMPANY_CONTACT_RT_ID, objContactAssert.RecordTypeId, 'Contact Record Type is incorrect - should be Company.');
		System.assertEquals(objCompanyAccount.Id, objContactAssert.AccountId, 'Account Id is incorrect on Contact.');
		System.assertEquals(false, objContactAssert.Is_Billing_Admin__c, 'Is Billing Admin should be FALSE on contact.');

		// Skip Triggers.
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		// Insert an Accountant Role
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRoleId2')
			.setUserId(objZPUser.Id__c)
			.setAccFirmId(objResellerAccount.ZP_Firm_ID__c)
			.setCreatedAt(System.now())
			.setType(ZPUserRoleUtil.TYPE_ROLE_ACCOUNTANT)
			.setCreatedAt(objZPUser.Created_At__c)
			.setIsBillingAdmin(true)
			.build();
		insert objZPUserRole2;

		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole2;

		objContactAssert = [SELECT Id, Is_Billing_Admin__c FROM Contact WHERE Email = :objZPUser.Email__c];
		System.assertEquals(true, objContactAssert.Is_Billing_Admin__c, 'Is Billing Admin should be TRUE on contact.');

		// Insert an PayrollAdmin Role
		ZP_User_Role__c objZPUserRole3 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('userRoleId3')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setType(ZPUserRoleUtil.TYPE_ROLE_PAYROLL_ADMIN)
			.setCreatedAt(objZPUser.Created_At__c)
			.setUpdatedAt(System.now())
			.setCollaboratorType(ZPUserRoleUtil.EXTERNAL_ACCOUNTANT)
			.setIsAccountant(true)
			.build();
		insert objZPUserRole3;

		objZPUserRole3.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole3;

		objContactAssert = [SELECT Id, Is_Billing_Admin__c FROM Contact WHERE Email = :objZPUser.Email__c];
		System.assertEquals(true, objContactAssert.Is_Billing_Admin__c, 'Is Billing Admin should be TRUE on contact.');

		objZPUserRole2.Deleted_At__c = System.now();
		objZPUserRole2.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		update objZPUserRole2;

		objContactAssert = [SELECT Id, Is_Billing_Admin__c FROM Contact WHERE Email = :objZPUser.Email__c];
		System.assertEquals(false, objContactAssert.Is_Billing_Admin__c, 'Is Billing Admin should be FALSE on contact.');

		ContactTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;

		Test.stopTest();
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if International Contractor Roles are getting processed and creating contacts
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void processInternationalContractorRoles() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new International contractor user record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('International Contractor')
			.setCustomId('9089798798')
			.setEmail('internationalcontractor@company.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('International')
			.setCustomId('989789789')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType(ZPUserRoleUtil.COMPANY_MEMBER)
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('International Cont')
			.setEmploymentType('InternationalContractor')
			.build();
		insert objZPUserRole;

		Test.startTest();

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;
		Test.stopTest();

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, ZP_User_Role__c FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'International Contractor is not created');
		System.assertEquals(true, objContactInsertAssert.ZP_User_Role__c.containsIgnoreCase(ZPUserRoleUtil.INTERNATIONAL_CONTRACTOR), 'Contact does not have International Contractor');

		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'International Contractor User role not processed');
	}

	/**
	 * @Author      : Prity Kumari
	 * @Description : Test if International Employee Roles are getting processed and creating contacts
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void processInternationalEmployeeRoles() {
		Account objCompanyAccount = [SELECT Id, Name, ZP_Company_Id__c FROM Account WHERE Name = 'Test Company Acc'];
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();

		// Insert a new International contractor user record
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('International Employee')
			.setCustomId('9089798798')
			.setEmail('internationalemployee@company.com')
			.setCreatedAt(System.now() - 2)
			.setUpdatedAt(System.now() - 1)
			.build();
		insert objZPUser;

		// Create a new ZP User Role
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setPreferredName('International')
			.setCustomId('989789789')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objCompanyAccount.ZP_Company_Id__c)
			.setCreatedAt(System.now())
			.setType(ZPUserRoleUtil.COMPANY_MEMBER)
			.setCreatedAt(objZPUser.Created_At__c)
			.setFirstName('International Employee')
			.setEmploymentType('InternationalEmployee')
			.build();
		insert objZPUserRole;

		Test.startTest();

		// Update Processing State to Manually Enqueuued which will trigger Contact Creation
		objZPUserRole.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
		objZPUserRole.Updated_At__c = System.now();
		update objZPUserRole;
		Test.stopTest();

		// Assert contact got created
		Contact objContactInsertAssert = [SELECT Id, ZP_User_Role__c FROM Contact WHERE ZP_User_Id__c = :objZPUserRole.User_Id__c LIMIT 1];
		System.assertEquals(true, objContactInsertAssert != null, 'International Employee is not created');
		System.assertEquals(true, objContactInsertAssert.ZP_User_Role__c.containsIgnoreCase(ZPUserRoleUtil.INTERNATIONAL_EMPLOYEE), 'Contact does not have International Employee');

		ZP_User_Role__c objRoleAssert = [SELECT Id, Processing_State__c FROM ZP_User_Role__c WHERE Id = :objZPUserRole.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRoleAssert.Processing_State__c, 'International Employee User role not processed');
	}

	/**
	 * @Description : Test prioritized roles are processed immediately while others are queued
	 * @See      : ZPUserRoleTriggerHelper.processPrioritizedRoles
	 **/
	@isTest
	static void testPrioritizedRolesProcessing() {
		ZPUserTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Test.startTest();

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Account 1').setZpCompanyId('22222222222222').build();
		insert objAccount;

		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('11111111111111')
			.setExternalKey('ZP777777777777771')
			.setEmail('testzpuser@test.com')
			.setCreatedAt(System.Now())
			.setUpdatedAt(System.Now())
			.setLastSignInAt(System.Now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser;

		//Two roles created, one that should be prioritized and one not
		ZP_User_Role__c objZPUserRoleAdmin = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.Now())
			.build();

		ZP_User_Role__c objZPUserRoleEmployee = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343435')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setType('Role::Employee')
			.setCreatedAt(System.Now())
			.build();

		ZP_User_Role__c objZPUserRoleSignatory = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343436')
			.setUserId(objZPUser.Id__c)
			.setCompanyId(objAccount.ZP_Company_Id__c)
			.setType('Role::Signatory')
			.setCreatedAt(System.Now())
			.build();
		List<ZP_User_Role__c> list_UserRoles = new List<ZP_User_Role__c>{ objZPUserRoleAdmin, objZPUserRoleEmployee, objZPUserRoleSignatory };
		insert list_UserRoles;

		Test.stopTest();
		//Assert that the prioritized role is processed and the other is queued
		List<ZP_User_Role__c> list_assertZPUserRoleList = [SELECT User_Id__c, Company_Id__c, Processing_State__c, Role_Name__c, Contact__c FROM ZP_User_Role__c WHERE Id IN :list_UserRoles];
		for (ZP_User_Role__c objRole : list_assertZPUserRoleList) {
			if (ZPUserRoleTriggerHelper.PRIORITIZED_ROLES.contains(objRole.Role_Name__c)) {
				System.assertEquals(IntegrationUtils.PROCESSED_STATE, objRole.Processing_State__c, 'State should be processed for prioritized roles');
				System.assertEquals(true, objRole.Contact__c != null, 'Contact should be created for prioritized roles');
			} else {
				System.assertEquals(IntegrationUtils.QUEUED_STATE, objRole.Processing_State__c, 'State should be queued for non-prioritized roles');
			}
		}
	}
}