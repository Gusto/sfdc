/*
@Author - Debasmita Rawooth
@CreateDate - 05/28/2021
@Description - Test class for BatchCleanUpZPUserRoles
*/
@isTest
public with sharing class BatchCleanUpZPUserRolesTest {
	@TestSetup
	static void setup() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder()
			.setBatchSize(10)
			.build();

		insert objConfigSettings;
	}

	@isTest
	static void BatchCleanUpZpUserRolesTest1() {
		ZPUserTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		Test.startTest();

		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Account 1')
			.setZpCompanyId('22222222222222')
			.build();
		insert objAccount1;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount1.Id)
			.setFirstName('Test New')
			.setLastName('Contact 1')
			.setEmail('testuser@test.com')
			.build();
		insert objContact1;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('11111111111111')
			.setExternalKey('ZP777777777777771')
			.setEmail('testzpuser@test.com')
			.setCreatedAt(System.Now())
			.setUpdatedAt(System.Now())
			.setLastSignInAt(System.Now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser1;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(objZPUser1.Id__c)
			.setCompanyId(objAccount1.ZP_Company_Id__c)
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.Now())
			.build();
		insert objZPUserRole1;

		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = config.Batch_Size__c.intValue();

		Database.executebatch(new BatchCleanUpZPUserRoles(), intBatch);

		Test.stopTest();
		List<ZP_User_Role__c> checkZPUserRoleList = [
			SELECT User_Id__c, Company_Id__c, Processing_State__c, Message__c
			FROM ZP_User_Role__c
		];
		List<Contact> checkContactList = [
			SELECT Id, FirstName, LastName, Email
			FROM Contact
			WHERE Email = 'testzpuser@test.com'
		];

		System.assert(checkZPUserRoleList[0].Processing_State__c == IntegrationUtils.PROCESSED_STATE);
		System.assert(checkContactList.Size() > 0);
	}

	@isTest
	static void BatchCleanUpZpUserRolesTest2() {
		ZPUserTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		Test.startTest();

		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Account 1')
			.setZpCompanyId('22222222222222')
			.build();
		insert objAccount1;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount1.Id)
			.setFirstName('Test New')
			.setLastName('Contact 1')
			.setEmail('testuser@test.com')
			.build();
		insert objContact1;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('11111111111111')
			.setExternalKey('ZP777777777777771')
			.setEmail('testzpuser@test.com')
			.setCreatedAt(System.Now())
			.setUpdatedAt(System.Now())
			.setLastSignInAt(System.Now())
			.setReferralToken('REFERRAL01')
			.build();
		insert objZPUser1;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(objZPUser1.Id__c)
			.setCompanyId(objAccount1.ZP_Company_Id__c)
			.setType('Role::PayrollAdmin')
			.setCreatedAt(System.Now())
			.build();
		insert objZPUserRole1;

		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = config.Batch_Size__c.intValue();

		Database.executebatch(
			new BatchCleanUpZPUserRoles(
				'SELECT FIELDS(ALL) FROM ZP_User_Role__c WHERE Processing_State__c IN (\'Queued\',\'Error\') ORDER BY CreatedDate DESC Limit 100'
			),
			intBatch
		);

		Test.stopTest();
		List<ZP_User_Role__c> checkZPUserRoleList = [
			SELECT User_Id__c, Company_Id__c, Processing_State__c, Message__c
			FROM ZP_User_Role__c
		];
		List<Contact> checkContactList = [
			SELECT Id, FirstName, LastName, Email
			FROM Contact
			WHERE Email = 'testzpuser@test.com'
		];

		System.assert(checkZPUserRoleList[0].Processing_State__c == IntegrationUtils.PROCESSED_STATE);
		System.assert(checkContactList.Size() > 0);
	}
}