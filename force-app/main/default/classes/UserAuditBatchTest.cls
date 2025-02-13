/**
 * @description Test class for UserAuditBatch
 * @author      Ajay Krishna P U
 * @since       2024-05-01
 */
@isTest
public class UserAuditBatchTest {
	private final static String USER_ROLE_IDENTIFIER_OTHER = 'Other';
	private final static String PROFILE_ARDIUS_BASE_USER = 'Ardius Base User';
	private final static Integer SIX_MONTHS = 180; //(30*6) days
	private final static Integer FIVE_MONTHS = 150; //(30*5) days
	private final static Integer THREE_MONTHS = 90; //(30*3) days
	private final static Integer TWO_MONTHS = 60; //(30*2) days
	private final static Integer ONE_MONTH = 30; //30 days
	private final static String TEST_USERNAME = 'objTestUser@gusto.com';

	/**
	 * @description Setup data
	 */
	@testSetup
	static void setUpData() {
		Profile objArdiusProfile = [SELECT Id, Name FROM Profile WHERE Name = :PROFILE_ARDIUS_BASE_USER];

		User objTestUser = new TestDataFactory.UserBuilder()
			.setUserName(TEST_USERNAME)
			.setEmail('objuser@gmail.com')
			.setIsActive(true)
			.setProfileId(objArdiusProfile.Id)
			.setIsApiIntegration(false)
			.setHRWorkerInformationStatus('Terminated')
			.build();

		insert objTestUser;
	}

	/**
	 * @description  Test method to validate the deactivation of Gusto Desk Partner Community Users based on their LastLoginDate
	 *               and CreatedDate
	 **/
	@isTest
	static void testDeactivateGustoDeskUser() {
		Profile objProfile1 = [SELECT Id, Name FROM Profile WHERE Name = :UserAuditBatch.USER_ROLE_GUSTO_DESK];

		User objGustoDeskUser = new TestDataFactory.UserBuilder()
			.setUserName('TestGusto@desk.com')
			.setEmail('GustoDeskUser1@gmail.com')
			.setIsActive(true)
			.setProfileId(objProfile1.Id)
			.setIsApiIntegration(false)
			.build();

		Test.startTest();

		//If user was Never logged in for Past 6 Months  ==> Deactivate
		UserAuditBatch.OPERATION_TYPE OperationStatus1 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-SIX_MONTHS),
			Datetime.now().addDays(-SIX_MONTHS),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_DEACTIVATE_GUSTO_DESK_USER, OperationStatus1, 'Failed-User was Never logged in for Past 6 Months');

		//If User was Never logged in for Past (6 Months + 1)  ==> Deactivate
		UserAuditBatch.OPERATION_TYPE OperationStatus2 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-(SIX_MONTHS + 1)),
			Datetime.now().addDays(-(SIX_MONTHS + 1)),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_DEACTIVATE_GUSTO_DESK_USER, OperationStatus2, 'Failed-User was Never logged in for Past (6 Months + 1)');

		//If last login date == null  ==> Deactivate
		UserAuditBatch.OPERATION_TYPE OperationStatus3 = UserAuditBatch.identifyOperation(objGustoDeskUser, Datetime.now().addDays(-(SIX_MONTHS + 1)), null, UserAuditBatch.USER_ROLE_GUSTO_DESK);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_DEACTIVATE_GUSTO_DESK_USER, OperationStatus3, 'Failed-User was Never logged in for Past (6 Months + 1)');

		Test.stopTest();
	}

	/**
	 * @description  Test method to send email alerts to Gusto Desk Partner Community Users based on their LastLoginDate
	 *               and CreatedDate
	 **/
	@isTest
	static void testSendRemainderGustoDeskUser() {
		Profile objProfile1 = [SELECT Id, Name FROM Profile WHERE Name = :UserAuditBatch.USER_ROLE_GUSTO_DESK];

		User objGustoDeskUser = new TestDataFactory.UserBuilder()
			.setUserName('TestGusto@desk.com')
			.setEmail('GustoDeskUser1@gmail.com')
			.setIsActive(true)
			.setProfileId(objProfile1.Id)
			.setIsApiIntegration(false)
			.build();

		Test.startTest();

		//If user was Never logged in for Past 5 Months to 6M - 1 , No operation
		UserAuditBatch.OPERATION_TYPE OperationStatus1 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-(FIVE_MONTHS + 10)),
			Datetime.now().addDays(-(FIVE_MONTHS + 10)),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(null, OperationStatus1, 'Failed-User was Never logged in for Past 5 Months to 6M - 1, no operation');

		//If user was Never logged in for Past 5 Months to 6M - 1 , No operation
		UserAuditBatch.OPERATION_TYPE OperationStatus2 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-(SIX_MONTHS - 10)),
			Datetime.now().addDays(-(SIX_MONTHS - 10)),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(null, OperationStatus2, 'Failed-User was Never logged in for Past 5 Months to 6M - 1, no operation');

		//If user was Never logged in for Past (5 Months - 1) ==> No Operation
		UserAuditBatch.OPERATION_TYPE OperationStatus3 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-(FIVE_MONTHS - 1)),
			Datetime.now().addDays(-(FIVE_MONTHS - 1)),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(null, OperationStatus3, 'Failed-User was Never logged in for Past (5 Months - 1)');

		//If user was Never logged in for Past (1 month - 10) ==> No Operation
		UserAuditBatch.OPERATION_TYPE OperationStatus4 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-(ONE_MONTH - 10)),
			Datetime.now().addDays(-(ONE_MONTH - 10)),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(null, OperationStatus4, 'Failed-User was Never logged in for Past (1 month - 10)');

		//If user was Never logged in for Past 5 Months to 6M - 1 , Send Remainder Emails only 30 days and 7 days before LastLogin (180 days)
		UserAuditBatch.OPERATION_TYPE OperationStatus5 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-(SIX_MONTHS - 30)),
			Datetime.now().addDays(-(SIX_MONTHS - 30)),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_GUSTO_DESK_USER, OperationStatus5, 'Failed-User was Never logged in for Past 5 Months to 6M - 1, send email alert');

		//If user was Never logged in for Past 5 Months to 6M - 1 , Send Remainder Emails only 30 days and 7 days before LastLogin (180 days)
		UserAuditBatch.OPERATION_TYPE OperationStatus6 = UserAuditBatch.identifyOperation(
			objGustoDeskUser,
			Datetime.now().addDays(-(SIX_MONTHS - 7)),
			Datetime.now().addDays(-(SIX_MONTHS - 7)),
			UserAuditBatch.USER_ROLE_GUSTO_DESK
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_GUSTO_DESK_USER, OperationStatus6, 'Failed-User was Never logged in for Past 5 Months to 6M - 1, send email alert');

		//If last login date == null --> Send Remainder Emails only 30 days and 7 days before LastLogin (180 days)
		UserAuditBatch.OPERATION_TYPE OperationStatus7 = UserAuditBatch.identifyOperation(objGustoDeskUser, Datetime.now().addDays(-(SIX_MONTHS - 7)), null, UserAuditBatch.USER_ROLE_GUSTO_DESK);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_GUSTO_DESK_USER, OperationStatus6, 'Failed-User was Never logged in for Past 5 Months to 6M - 1, send email alert');

		Test.stopTest();
	}

	/**
	 * @description  Test method to validate the deactivation of other Users based on their LastLoginDate
	 *               and CreatedDate
	 **/
	@isTest
	static void testDeactivateOtherUsers() {
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('Test@User1.com')
			.setEmail('User1@gmail.com')
			.setIsActive(true)
			.setIsApiIntegration(false)
			.setHRWorkerInformationStatus('Active')
			.setLastUpdatedAt(Date.today().addDays(-90))
			.build();

		Test.startTest();

		//If user was Never logged in for Past 3 Months  + HR worker info NOT updated for Past 3 Months ==> Deactivate
		UserAuditBatch.OPERATION_TYPE OperationStatus1 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-THREE_MONTHS),
			Datetime.now().addDays(-THREE_MONTHS),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(
			UserAuditBatch.OPERATION_TYPE.OPERATION_DEACTIVATE_OTHER_USERS,
			OperationStatus1,
			'Failed-User was Never logged in for Past 3 Months + HR worker info NOT updated for Past 3 Months'
		);

		//If Last_Updated_At == null
		objUser.Last_Updated_At__c = null;
		System.assertEquals(
			UserAuditBatch.OPERATION_TYPE.OPERATION_DEACTIVATE_OTHER_USERS,
			OperationStatus1,
			'Failed-User was Never logged in for Past 3 Months + HR worker info NOT updated for Past 3 Months'
		);

		//If user was Never logged in for Past (3 Months + 1)  + HR worker info NOT updated for Past (3 Months +1) ==> Deactivate
		UserAuditBatch.OPERATION_TYPE OperationStatus2 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-(THREE_MONTHS + 1)),
			Datetime.now().addDays(-(THREE_MONTHS + 1)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(
			UserAuditBatch.OPERATION_TYPE.OPERATION_DEACTIVATE_OTHER_USERS,
			OperationStatus2,
			'Failed-User was Never logged in for Past (3 Months + 1) + HR worker info NOT updated for Past (3 Months + 1)'
		);

		Test.stopTest();
	}

	/**
	 * @description  Test method to send email alerts to other Users based on their LastLoginDate
	 *               and CreatedDate
	 **/
	@isTest
	static void testSendRemainderOtherUsers() {
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('Test@User1.com')
			.setEmail('User1@gmail.com')
			.setIsActive(true)
			.setIsApiIntegration(false)
			.setHRWorkerInformationStatus('Active')
			.setLastUpdatedAt(Date.today().addDays(-90))
			.build();

		Test.startTest();

		//If user is on Never logged in for Past 2 Months to 3M - 1 ==> Send Remainder Emails once every week
		UserAuditBatch.OPERATION_TYPE OperationStatus1 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-(THREE_MONTHS - 30)),
			Datetime.now().addDays(-(THREE_MONTHS - 30)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_OTHER_USERS, OperationStatus1, 'Failed-User Never logged in for Past 2 Months to 3M - 1, send email alerts');

		//If Last_Updated_At == null
		objUser.Last_Updated_At__c = null;
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_OTHER_USERS, OperationStatus1, 'Failed-User Never logged in for Past 2 Months to 3M - 1, send email alerts');

		//If user is on Never logged in for Past 2 Months to 3M - 1 ==> No operation
		UserAuditBatch.OPERATION_TYPE OperationStatus2 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-(THREE_MONTHS - 26)),
			Datetime.now().addDays(-(THREE_MONTHS - 26)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(null, OperationStatus2, 'Failed-User Never logged in for Past 2 Months to 3M - 1, no operation');

		//If user is on Never logged in for Past 2 Months to 3M - 1 ==> Send Remainder Emails once every week
		UserAuditBatch.OPERATION_TYPE OperationStatus3 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-(THREE_MONTHS - 21)),
			Datetime.now().addDays(-(THREE_MONTHS - 21)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_OTHER_USERS, OperationStatus3, 'Failed-User Never logged in for Past 2 Months to 3M - 1, send email alerts');

		//If user is on Never logged in for Past 2 Months to 3M - 1 ==> Send Remainder Emails once every week
		UserAuditBatch.OPERATION_TYPE OperationStatus4 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-(THREE_MONTHS - 14)),
			Datetime.now().addDays(-(THREE_MONTHS - 14)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_OTHER_USERS, OperationStatus4, 'Failed-User Never logged in for Past 2 Months to 3M - 1, send email alerts');

		//If user is on Never logged in for Past 2 Months to 3M - 1 ==> Send Remainder Emails once every week
		UserAuditBatch.OPERATION_TYPE OperationStatus5 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-(THREE_MONTHS - 7)),
			Datetime.now().addDays(-(THREE_MONTHS - 7)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_OTHER_USERS, OperationStatus5, 'Failed-User Never logged in for Past 2 Months to 3M - 1, send email alerts');

		//If user is on Never logged in for Past 2 Month - 1 ==> No operation
		UserAuditBatch.OPERATION_TYPE OperationStatus6 = UserAuditBatch.identifyOperation(
			objUser,
			Datetime.now().addDays(-(TWO_MONTHS - 1)),
			Datetime.now().addDays(-(TWO_MONTHS - 1)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(null, OperationStatus6, 'Failed-User Never logged in for Past 2 Months - 1, no operation');

		Test.stopTest();
	}

	/**
	 * @description  Test method to validate the operation to be performed on users based on HR_Worker_Information_Status__c
	 **/
	@isTest
	static void testBasedOnHRWorkerInfoStatus() {
		User objUser1 = new TestDataFactory.UserBuilder()
			.setUserName('Test@User1.com')
			.setEmail('User1@gmail.com')
			.setIsActive(true)
			.setIsApiIntegration(false)
			.setHRWorkerInformationStatus('Terminated')
			.build();

		User objUser2 = new TestDataFactory.UserBuilder()
			.setUserName('Test@User2.com')
			.setEmail('User2@gmail.com')
			.setIsActive(true)
			.setIsApiIntegration(false)
			.setHRWorkerInformationStatus('Vacation')
			.build();

		Test.startTest();

		//If user is Not an Admin| Integration-If user is Terminated ==> Never send a Remainder Emails
		UserAuditBatch.OPERATION_TYPE OperationStatus1 = UserAuditBatch.identifyOperation(
			objUser1,
			Datetime.now().addDays(-THREE_MONTHS),
			Datetime.now().addDays(-THREE_MONTHS),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertNotEquals(UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_OTHER_USERS, OperationStatus1, 'Failed-User is Terminated');

		//If user is Not an Admin| Integration-If user is on Vacation or Leave ==> Never send a Remainder Email Nor Deactivate
		UserAuditBatch.OPERATION_TYPE OperationStatus2 = UserAuditBatch.identifyOperation(
			objUser2,
			Datetime.now().addDays(-(ONE_MONTH - 10)),
			Datetime.now().addDays(-(ONE_MONTH - 10)),
			USER_ROLE_IDENTIFIER_OTHER
		);
		System.assertEquals(null, OperationStatus2, 'Failed-User is on Vacation or leave');

		Test.stopTest();
	}

	/**
	 * @description  Test method to validate the working of batch class
	 **/
	@isTest
	static void testUserAuditBatchSchedule() {
		Test.startTest();
		Database.executeBatch(
			new UserAuditBatch(
				'SELECT Id,CreatedDate,LastLoginDate,HR_Worker_Information_Status__c, IsActive, Last_Updated_At__c, User_Role_Identifier__c FROM User WHERE UserName = \'' +
					TEST_USERNAME +
					'\' LIMIT 1'
			),
			UserAuditBatch.CUSTOM_BATCH_SIZE
		);
		Test.stopTest();

		List<User> list_Users = [SELECT Id, IsActive FROM User WHERE UserName = :TEST_USERNAME AND IsActive = TRUE];
		system.assertEquals(1, list_Users.size(), 'No deactivated user found');
	}

	/**
	 * @description  Test method to validate the working of BatchUserUpdateQueue Queueable method
	 **/
	@isTest
	static void testUserUpdateQueue() {
		List<User> list_Users = [SELECT Id, Notes__c FROM User WHERE UserName = :TEST_USERNAME LIMIT 1];
		System.assertEquals(1, list_Users.size(), 'Invalid Test data - Users');
		list_Users[0].Notes__c = UserAuditBatch.NOTE_FOR_DEACTIVATE;

		Test.startTest();
		System.enqueueJob(new UserAuditBatch.BatchUserUpdateQueue(list_Users, UserAuditBatch.CUSTOM_QUEUE_BATCH_SIZE));
		Test.stopTest();

		list_Users = [SELECT Id, Notes__c FROM User WHERE UserName = :TEST_USERNAME];
		system.assertEquals(UserAuditBatch.NOTE_FOR_DEACTIVATE, list_Users[0].Notes__c, 'User not updated');
	}

	/**
	 * @description Test processing Results Email/ DML results
	 */
	@isTest
	static void testProcessResultFunctions() {
		Messaging.SingleEmailMessage objEmail = new UserAuditBatch().getEmailMessage(null, UserAuditBatch.OPERATION_TYPE.OPERATION_SEND_NOTIFY_GUSTO_DESK_USER);
		List<Messaging.SendEmailResult> list_EmailResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ objEmail }, false);
		List<Exception_Log__c> list_EmailExceptions = new UserAuditBatch().processEmailResults(list_EmailResults);
		System.assertEquals(false, list_EmailExceptions.isEmpty(), 'Email Result processing failed.');

		List<Database.SaveResult> list_SaveResult = Database.update(new List<User>{ new User() }, false);
		List<Exception_Log__c> list_Exceptions = new UserAuditBatch.BatchUserUpdateQueue().processSaveResults(list_SaveResult);
		System.assertEquals(false, list_Exceptions.isEmpty(), 'DML Result processing failed.');

		Test.startTest();
		System.enqueueJob(new UserAuditBatch.ExceptionCreateQueue(list_Exceptions));
		Test.stopTest();

		list_Exceptions = [SELECT Id, Class_Name__c, Method_Name__c FROM Exception_Log__c WHERE Class_Name__c = 'UserAuditBatch'];
		system.assertEquals(false, list_Exceptions.isEmpty(), 'Exception logs not created');
	}
}