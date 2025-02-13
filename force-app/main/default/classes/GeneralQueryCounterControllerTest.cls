/*
 * Description: Test Class for GeneralQueryCounterController
 * Author: Omar Benitez
 * Date: 08/01/2024
 */
@IsTest
public class GeneralQueryCounterControllerTest {
	//This method test the loadCmp method from the controller
	@IsTest
	static void testLoadCmp() {
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setUserName('Implementation.Advocate@test.Implementation')
			.setExemptfromValidationRules(true)
			.setEmail('partneram@testorg.com')
			.setProfileId(UserInfo.getProfileId())
			.build();
		insert objAdminUser;
		PermissionSet objPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'Benefits_Fulfillment_Team_Lightning_Access_Permission_set'];
		insert new PermissionSetAssignment(AssigneeId = objAdminUser.Id, PermissionSetId = objPermSet.Id);
		Test.startTest();
		Map<String, Integer> map_response = new Map<String, Integer>();
		System.runAs(objAdminUser) {
			map_response = GeneralQueryCounterController.loadCmp();
		}
		Test.stopTest();
		System.assertNotEquals(0, map_response.size(), 'Map should have at least one value');
	}
}