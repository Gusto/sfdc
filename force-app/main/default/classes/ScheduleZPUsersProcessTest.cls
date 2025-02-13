/**
 * @name         : ScheduleZPUsersProcessTest
 * @author       : David (Dato) Tsamalalshvili
 * @date         : 10-13-2021
 * @description  : Test class for batch job - ScheduleZPUsersProces
 **/
@isTest
public with sharing class ScheduleZPUsersProcessTest {
	@TestSetup
	static void setup() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder()
			.setBatchSize(10)
			.build();

		insert objConfigSettings;

		List<Contact> list_Contacts;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('testcontact1@test.com')
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setFirstName('Test First Name2')
			.setLastName('Test Last Name2')
			.setEmail('testcontact2@test.com')
			.build();

		list_Contacts = new List<Contact>{ objContact1, objContact2 };
		ContactTriggerHelper.skipTrigger = true;
		insert list_Contacts;
	}

	@isTest
	static void BatchCleanUpZpUsersTest() {
		List<ZP_User__c> list_ZPUsers;
		DateTime dtDateTime = System.Now() - 1;

		List<Contact> list_Contacts = [SELECT Id, Email FROM Contact];

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId('11111111')
			.setExternalKey('ZP11111111')
			.setEmail(list_Contacts[0].Email)
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setProcessingState('Dead')
			.build();

		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 2')
			.setCustomId('22222222')
			.setExternalKey('ZP22222222')
			.setEmail(list_Contacts[1].Email)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setLastSignInAt(System.now())
			.setCurrentSignInAt(System.now())
			.setProcessingState('Queued')
			.setDeletedAt(System.now())
			.build();

		list_ZPUsers = new List<ZP_User__c>{ objZPUser1, objZPUser2 };
		ZpUserTriggerHelper.skipTrigger = true;
		insert list_ZPUsers;

		Test.startTest();

		ScheduleZPUsersProcess clsScehule = new ScheduleZPUsersProcess();
		clsScehule.execute(null);

		Test.stopTest();

		Contact objContact1Assert = [SELECT Id, Inactive_ZP_User__c FROM Contact WHERE Id = :list_Contacts[0].Id];
		System.assert(objContact1Assert.Inactive_ZP_User__c == false);

		Contact objContact2Assert = [SELECT Id, Inactive_ZP_User__c FROM Contact WHERE Id = :list_Contacts[1].Id];
		System.assert(objContact2Assert.Inactive_ZP_User__c == true);
	}
}