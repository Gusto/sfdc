/**
 * Test class for HRWorkerInformation Trigger Handler
 * @author David Schach
 * @group Workday
 */
@isTest
private class HRWorkerInformationTest {
	@IsTest
	static void testUpdateManager() {
		List<HR_Worker_Information__c> list_toInsert = new List<HR_Worker_Information__c>();

		HR_Worker_Information__c objEmp = new HR_Worker_Information__c(Employee_Id__c = '2', Manager_ID__c = '1', First_Name__c = 'Lando', Last_Name__c = 'Calrissian');
		list_toInsert.add(objEmp);
		HR_Worker_Information__c objManager = new HR_Worker_Information__c(Employee_Id__c = '1', First_Name__c = 'Han', Last_Name__c = 'Solo');
		list_toInsert.add(objManager);
		HR_Worker_Information__c objManager2 = new HR_Worker_Information__c(Employee_Id__c = '3', First_Name__c = 'Leia', Last_Name__c = 'Skywalker');
		list_toInsert.add(objManager2);

		insert list_toInsert;

		UserTriggerHelper.skipTrigger = true;

		User objEmployee;
		User objPE;
		User objNewPE;
		User objThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.runAs(objThisUser) {
			objPE = new TestDataFactory.UserBuilder()
				.setIsActive(true)
				.setProfileId(UserInfo.getProfileId())
				.setUserRoleId(TaskUtil.USER_ROLE_ID_EXEC)
				.setUserName('testPE@testtask.com')
				.setFirstName('Test FName')
				.setLastName('Test LName')
				.setEmail('testsysadmin@testtask.com')
				.setAlias('syspe')
				.setTimeZoneSidKey('America/Los_Angeles')
				.setLocaleSidKey('en_US')
				.setEmailEncoding('UTF-8')
				.setLanguageLocaleKey('en_US')
				.build();
			objPE.EmployeeNumber = '1';

			objEmployee = new TestDataFactory.UserBuilder()
				.setIsActive(true)
				.setProfileId(UserInfo.getProfileId())
				.setUserRoleId(TaskUtil.USER_ROLE_ID_EXEC)
				.setUserName('testemployee@testtask.com')
				.setFirstName('Test FName')
				.setLastName('Test LName')
				.setEmail('testsysadmin@testtask.com')
				.setAlias('syse')
				.setTimeZoneSidKey('America/Los_Angeles')
				.setLocaleSidKey('en_US')
				.setEmailEncoding('UTF-8')
				.setLanguageLocaleKey('en_US')
				.build();
			objEmployee.EmployeeNumber = '2';

			objNewPE = new TestDataFactory.UserBuilder()
				.setIsActive(true)
				.setProfileId(UserInfo.getProfileId())
				.setUserRoleId(TaskUtil.USER_ROLE_ID_EXEC)
				.setUserName('testNewPE@testtask.com')
				.setFirstName('Test FName')
				.setLastName('Test LName')
				.setEmail('testsysadmin@testtask.com')
				.setAlias('sysnpe')
				.setTimeZoneSidKey('America/Los_Angeles')
				.setLocaleSidKey('en_US')
				.setEmailEncoding('UTF-8')
				.setLanguageLocaleKey('en_US')
				.build();
			objNewPE.EmployeeNumber = '3';

			List<User> newUsers = new List<User>();
			newUsers.add(objEmployee);
			newUsers.add(objPE);
			newUsers.add(objNewPE);
			insert newUsers;
		}

		UserTriggerHelper.skipTrigger = false;

		// Replicates the update that may have to happen to newly-created records
		objEmployee.ManagerId = objPE.Id;
		update objEmployee;

		User objUserEmployee = [SELECT Id, EmployeeNumber, ManagerId FROM User WHERE EmployeeNumber = '2' LIMIT 1];

		System.assertEquals(objPE.Id, objUserEmployee.ManagerId, 'Linked manager on employee record is incorrect.');

		Test.startTest();

		objEmp.Manager_ID__c = '3';
		update objEmp;

		Test.stopTest();

		System.assertEquals(objNewPE.Id, [SELECT ManagerId FROM User WHERE EmployeeNumber = '2' LIMIT 1].ManagerId, 'Linked manager on employee record is incorrect.');
	}
}