/**
 * @name         BTFacilitatorCompCtrlTest
 * @author       Sanjay Paryani
 * @date         04/02/2020
 * @description  Test class for BTFacilitatorCompCtrl
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
public class BTFacilitatorCompCtrlTest {
	static testMethod void testUserSkillRole() {
		List<Role__c> RoleList = new List<Role__c>();
		Role__c BARole = new Role__c();
		BARole.name = 'Benefit Transfer Facilitator 1';
		RoleList.add(BARole);
		Role__c BF1Role = new Role__c();
		BF1Role.name = 'Benefit Transfer Facilitator 2';
		RoleList.add(BF1Role);
		insert (RoleList);
		List<Skill__c> lstSkill = new List<Skill__c>();
		lstSkill.add(new Skill__c(Role__c = BARole.Id));
		lstSkill.add(new Skill__c(Role__c = BF1Role.Id));
		insert lstSkill;
		User_Role__c userRoleObj = new User_Role__c();
		userRoleObj.User__c = UserInfo.getUserId();
		insert userRoleObj;
		List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, User_Role__c = userRoleObj.Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 1'));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, User_Role__c = userRoleObj.Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2'));
		insert list_UserSkill;
		BTFacilitatorCompCtrl objBtFacilitatorView = new BTFacilitatorCompCtrl();

		//Since the user is associated with both roles, the flags should be set to true
		System.assertEquals(true, objBtFacilitatorView.blnIsFAC1, 'The user should have the role "Benefit Transfer Facilitator 1"');
		System.assertEquals(true, objBtFacilitatorView.blnIsFAC2, 'The user should have the role "Benefit Transfer Facilitator 2"');
	}
}