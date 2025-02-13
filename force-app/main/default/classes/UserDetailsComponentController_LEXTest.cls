@isTest
public class UserDetailsComponentController_LEXTest {
	@TestSetup
	static void setup() {
		User objUser = new TestDataFactory.UserBuilder()
			.setAlias('testU')
			.setEmail('test@test.com')
			.setLastName('Testing')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('UserDetailsComponentController_LEXTest@test.com')
			.setProfileId([SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'].Id)
			.setOOO(true)
			.build();
		insert objUser;
	}

	@isTest
	static void testGetUserData() {
		// Get details of currently logged In User
		Test.startTest();
		UserDetailsComponentController_LEX.UserDetailsWrapper wrapper = UserDetailsComponentController_LEX.getUserData();
		System.assertEquals(wrapper.blnIsSuccess, true, 'Unable to find logged in user');
		Test.stopTest();
	}

	@isTest
	static void testUpdateUserWithOutAdvocateData() {
		Test.startTest();
		UserDetailsComponentController_LEX.updateUser(false);
		UserDetailsComponentController_LEX.UserDetailsWrapper objWrapper = UserDetailsComponentController_LEX.getUserData();
		Test.stopTest();
		System.assertEquals(UserInfo.getUserId(), objWrapper.objUser.Id, 'User Id should match.');
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : tests updateUser() with mismatching out of office values
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testUpdateUser() {
		User objUser = [SELECT Id FROM User WHERE UserName = 'UserDetailsComponentController_LEXTest@test.com'];
		Test.startTest();
		System.runAs(objUser) {
			UserDetailsComponentController_LEX.updateUser(false);
		}

		User objUserQueried = [SELECT Out_Of_Office__c FROM User WHERE UserName = 'UserDetailsComponentController_LEXTest@test.com'];
		System.assert(!objUserQueried.Out_Of_Office__c, 'Out_Of_Office__c checkbox on user should be unchecked.');
		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : tests exception handling
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testGetUserDataException() {
		Test.startTest();
		UserDetailsComponentController_LEX.blnFail = true;

		try {
			UserDetailsComponentController_LEX.UserDetailsWrapper wrapper = UserDetailsComponentController_LEX.getUserData();
		} catch (Exception ex) {
			List<Exception_Log__c> list_Log = [SELECT Id FROM Exception_Log__c];
			System.assertEquals(1, list_Log.size(), 'There should be 1 log.');
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : tests exception handling
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	public static void testUpdateUserException() {
		Test.startTest();
		UserDetailsComponentController_LEX.blnFail = true;
		User objUser = [SELECT Id FROM User WHERE UserName = 'UserDetailsComponentController_LEXTest@test.com'];

		try {
			System.runAs(objUser) {
				UserDetailsComponentController_LEX.updateUser(false);
			}
		} catch (Exception ex) {
			List<Exception_Log__c> list_Log = [SELECT Id FROM Exception_Log__c];
			System.assertEquals(1, list_Log.size(), 'There should be 1 log.');
		}

		Test.stopTest();
	}
}