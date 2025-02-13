/**
 * @name         DeleteUserRolesAndSkillsTest
 * @description  Test class for DeleteUserRolesAndSkillsBatch
 * @author       Deepika Saini
 * @date         May 18, 2021
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
public class DeleteUserRolesAndSkillsTest {
	public static boolean blnRunCatchTest = false;

	@testSetup
	static void setupData() {
		Profile objProfile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		
		User adminUser = new TestDataFactory.UserBuilder()
		.setAlias('ImplAdv')
		.setEmail('Implementation.Advocate@test.com')
		.setFirstName('Implementation')
		.setLastName('Advocate')
		.setProfileId(objProfile1.Id)
		.setUserName('Implementation.Advocate@test.Implementation')
		.setIsActive(true)
		.setExemptfromValidationRules(true)
		.build();
		insert adminUser;

		User_Role__c userRoleObj = new User_Role__c();
		userRoleObj.User__c = adminUser.Id;
		insert userRoleObj;

		List<Role__c> roleList = new List<Role__c>();
		Role__c roleObj = new Role__c();
		roleObj.Name = 'Implementation Advocate';
		roleList.add(roleObj);

		Role__c roleObj1 = new Role__c();
		roleObj1.Name = 'Confirmation';
		roleList.add(roleObj1);
		insert roleList;

		List<Skill__c> lstSkill = new List<Skill__c>();
		Skill__c skillObj = new Skill__c();
		skillObj.Order_Type__c = 'Carrier switch';
		skillObj.Tier__c = objTierConfig.New_Tier_2__c;
		skillObj.Role__c = roleList[0].Id;
		skillObj.IA_Exception__c = true;
		skillObj.Prioritized_Customer__c = true;
		lstSkill.add(skillObj);

		Skill__c skillObj1 = new Skill__c();
		skillObj1.Order_Type__c = 'Carrier switch';
		skillObj1.Tier__c = objTierConfig.New_Tier_2__c;
		skillObj1.Role__c = roleList[0].Id;
		skillObj1.IA_Exception__c = false;
		skillObj1.Prioritized_Customer__c = false;
		lstSkill.add(skillObj1);
		insert skillObj;

		User_Skill__c userSkillObj = new User_Skill__c();
		userSkillObj.Skill__c = skillObj.Id;
		userSkillObj.User_Role__c = userRoleObj.Id;
		userSkillObj.Skill_Role_Name__c = 'Implementation Advocate';
		insert userSkillObj;
	}

	@isTest
	static void createDeleteUserRoleAndSkills() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@test.Implementation' LIMIT 1];
		objUser.isActive = false;
		update objuser;

		DeleteUserRolesAndSkillsBatch objBatch = new DeleteUserRolesAndSkillsBatch();
		Database.executeBatch(objBatch, 1000);

		Test.stopTest();

		List<User_Role__c> list_UserRoles = [SELECT Id FROM User_Role__c WHERE User__c = :objuser.id];
		System.assertEquals(0, list_UserRoles.size(), 'There should be 0 user roles in list.');
	}

	@isTest
	static void testDeleteUserRoleAndSkillsBatchExceptionCase() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@test.Implementation' LIMIT 1];
		objUser.isActive = false;
		update objuser;

		blnRunCatchTest = true;
		DeleteUserRolesAndSkillsBatch objBatch = new DeleteUserRolesAndSkillsBatch();
		Database.executeBatch(objBatch, 1000);

		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id, Class_Name__c FROM Exception_Log__c];
		System.assert(list_Exceptions.size() > 0, 'There should be at least 1 exception.');
		System.assertEquals('DeleteUserRolesAndSkillsBatch', list_Exceptions[0].Class_Name__c, 'Class name should match.');
	}
}