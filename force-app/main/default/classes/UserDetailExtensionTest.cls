@isTest
private class UserDetailExtensionTest {
	@isTest
	static void userUpdateFunctionalityTest() {
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setUserName('mdruser@testorg.com')
			.setEmail('mdruser@testorg.com')
			.setProfileId([SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'].Id)
			.setExemptfromValidationRules(true)
			.build();
		insert objAdminUser;

		Test.startTest();
		System.runAs(objAdminUser) {
			apexPages.StandardController sc = new apexPages.StandardController(objAdminUser);
			UserDetailExtension controller = new UserDetailExtension(sc);
			controller.selectedUserId = objAdminUser.id;
			controller.editUser();
			controller.selectedAllQueueList.add(controller.getAllQueueAvailableList().get(0));
			controller.selectedIndividualQueueList.add(controller.getIndividualQueueAvailableList().get(0));
			controller.updateUser();

			// updating user check;
			list<User> loggedInUserList = [SELECT id, Individual_Queues__c, All_Queues__c FROM User WHERE Id = :userInfo.getUserId()];
			System.assert(loggedInUserList.get(0).Individual_Queues__c != null, 'Individual Queues should not be null.');
			System.assert(loggedInUserList.get(0).All_Queues__c != null, 'All Queues should not be null.');

			controller.cancelEditUser();

			list<User> list_Users = new List<User>();
			list_Users.add(objAdminUser);
			apexPages.StandardSetController sc2 = new apexPages.StandardSetController(list_Users);
			UserDetailExtension setController = new UserDetailExtension(sc2);
			setController.selectedUserId = objAdminUser.id;
			setController.editUser();
			controller.userFooterRec.Out_Of_Office__c = true;
			controller.updateUserFooterRecord();
			loggedInUserList = [SELECT id, Out_Of_Office__c FROM User WHERE Id = :userInfo.getUserId()];
			System.assert(loggedInUserList.get(0).Out_Of_Office__c, 'Out_Of_Office__c should be true.'); //outofoffice functionality check;
		}
		Test.stopTest();
	}
}