/*
 * Description: Test Class for UserOOOController
 * Author: Omar Benitez
 * Date: 07/02/2024
 */
@IsTest
public class UserOOOControllerTest {
	/*
	 * Description: Test method for updateUserOOO, it will allow OOO user field update
	 * Author: Omar Benitez
	 * Date: 07/02/2024
	 */
	@isTest
	static void testUpdateUserOOO() {
		Test.startTest();
		UserOOOController.updateUserOOO(UserInfo.getUserId(), true);
		Test.stopTest();
		User objCurrentUser = [SELECT ID, Out_Of_Office__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.assertEquals(true, objCurrentUser.Out_Of_Office__c, 'It should be true');
	}
	/*
	 * Description: Test method for updateUserOOO, fail scenario
	 * Author: Omar Benitez
	 * Date: 07/02/2024
	 */
	@isTest
	static void testUpdateUserOOOError() {
		Test.startTest();
		try {
			UserOOOController.updateUserOOO('NonValidId', true);
			System.assert(false);
		} catch (Exception objException) {
			System.assert(true, 'It should throw an error');
		}
	}
}