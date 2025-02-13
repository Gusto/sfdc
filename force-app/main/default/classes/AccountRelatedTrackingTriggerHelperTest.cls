/**
 * @name         AccountRelatedTrackingTriggerHelperTest
 * @author       Seshu Korivi
 * @date         02-23-2021
 * @description  Tests if Account Related Tracking is updated
 **/
@isTest
public class AccountRelatedTrackingTriggerHelperTest {
	@testSetup
	static void createTestData() {
		User objcurrentUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()][0];
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('Admin')
			.setEmail('admin@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('admin@testorg.com.test2')
			.build();
		objAdminUser.Exempt_from_Validation_Rules__c = true;
		objAdminUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'sales_partner_xx_xx_mgr'][0].Id;
		System.runAs(objcurrentUser) {
			insert objAdminUser;
		}
		Account objAccount = TestUtils.createAccount(AccountUtil.COMPANY_ACCOUNT_RT_ID, 'Test Company Account', true);
		Task objTaskConnect = TestUtils.createTask(Cache.getRecordTypeId('Task', 'Call'), 'Subject', objAccount.Id, true);
	}

	/*** Test if a Connect Task is updated, Check Account Related Tracking Connects_by_Owner__c is updated ***/
	@isTest
	static void testConnectUpdate() {
		Task objTask = [SELECT Id, Status FROM Task LIMIT 1];

		Test.startTest();
		objTask.Status = 'Connect';
		update objTask;
		Test.stopTest();

		List<Account_Related_Tracking__c> list_RelatedTrackings = [SELECT Id, Attempts_by_Owner__c, Connects_by_Owner__c, Voicemails_by_Owner__c FROM Account_Related_Tracking__c];
		System.assertEquals(list_RelatedTrackings[0].Connects_by_Owner__c, 1, 'Related Tracking Connects_by_Owner__c is not updated');
	}

	/*** Test if a Voicemail Task is updated, Check Account Related Tracking Voicemails_by_Owner__c is updated ***/
	@isTest
	static void testVoicemailUpdate() {
		Task objTask = [SELECT Id, Status FROM Task LIMIT 1];

		Test.startTest();
		objTask.Status = 'Voicemail';
		update objTask;
		Test.stopTest();

		List<Account_Related_Tracking__c> list_RelatedTrackings = [SELECT Id, Attempts_by_Owner__c, Connects_by_Owner__c, Voicemails_by_Owner__c FROM Account_Related_Tracking__c];
		System.assertEquals(list_RelatedTrackings[0].Voicemails_by_Owner__c, 1, 'Related Tracking Voicemails_by_Owner__c is not updated');
	}

	/*** Test if a Attempt Task is updated, Check Account Related Tracking Attempts_by_Owner__c is updated ***/
	@isTest
	static void testAttemptUpdate() {
		Task objTask = [SELECT Id, Status FROM Task LIMIT 1];

		Test.startTest();
		objTask.Status = 'Attempt';
		update objTask;
		Test.stopTest();

		List<Account_Related_Tracking__c> list_RelatedTrackings = [SELECT Id, Attempts_by_Owner__c, Connects_by_Owner__c, Voicemails_by_Owner__c FROM Account_Related_Tracking__c];
		System.assertEquals(list_RelatedTrackings[0].Attempts_by_Owner__c, 1, 'Related Tracking Attempts_by_Owner__c is not updated');
	}

	/*** Test if Account Owner is updated, the fields need to be reset ***/
	@isTest
	static void testOwnershipUpdate() {
		Task objTask = [SELECT Id, Status FROM Task LIMIT 1];
		Account objAccount = [SELECT Id, OwnerId FROM Account LIMIT 1];
		User objUser = [SELECT Id FROM User LIMIT 1];

		Test.startTest();
		objAccount.OwnerId = objUser.Id;
		Test.stopTest();

		List<Account_Related_Tracking__c> list_AccountRealtedTrackings = [SELECT Id, Time_To_First_Call_Minutes__c FROM Account_Related_Tracking__c];
		System.assertEquals(list_AccountRealtedTrackings[0].Time_To_First_Call_Minutes__c, 0, 'The field is not being reset');
	}
}