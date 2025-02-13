/**
 * @name         : ChangeOOOUserRoleCtrlTest
 * @author       : Rushi R
 * @date         : 12-27-2022
 * @description  : Unit test for ChangeOOOUserRoleCtrl
 **/
@isTest
private class ChangeOOOUserRoleCtrlTest {
	@testSetup
	static void setup() {
		User_Role__c objUserRole = new User_Role__c();
		objUserRole.User__c = UserInfo.getUserId();
		insert objUserRole;

		objUserRole.User_Skill_Team__c = 'Implementation Advocate';
		objUserRole.User_Skill_Type__c = 'Core';
		update objUserRole;
	}

	@isTest
	static void testChangeOOOBtn() {
		User_Role__c objUserRole = [SELECT Id, User__c FROM User_Role__c LIMIT 1];
		User objUser = [SELECT Out_Of_Office__c FROM User WHERE Id = :objUserRole.User__c];
		Boolean bln_OooValue = objUser.Out_Of_Office__c;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('id', objUserRole.id);
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objUserRole);
		ChangeOOOUserRoleCtrl extension = new ChangeOOOUserRoleCtrl(stdCtrl);
		extension.changeOOOForUser();

		objUser = [SELECT Out_Of_Office__c FROM User WHERE Id = :objUserRole.User__c];
		system.assertNotEquals(bln_OooValue, objUser.Out_Of_Office__c, 'Unable to change Out of Office');

		extension.backToRecord();
		Test.stopTest();
	}
}