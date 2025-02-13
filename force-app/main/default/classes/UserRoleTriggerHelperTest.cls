@isTest
public class UserRoleTriggerHelperTest {
	@TestSetup
	static void setup() {
		User_Role__c objUserRole = new User_Role__c();
		objUserRole.User__c = UserInfo.getUserId();
		objUserRole.User_Skill_Team__c = 'Implementation Advocate';
		objUserRole.User_Skill_Type__c = 'Core';
		insert objUserRole;
	}

	/**
	 * @author       Deepika Saini 
	 * @description  Check for Original Team Type
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void userRolePayroll() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id, User_Skill_Team__c, Original_Team_Type__c FROM User_Role__c LIMIT 1];
		System.debug('objUserRole.Original_Team_Type__c==' + objUserRole.Original_Team_Type__c);
		objUserRole.User_Skill_Team__c = 'Payroll Transfer';
		update objUserRole;
		delete objUserRole;
		undelete objUserRole;
		User_Role__c objUsrRole = [SELECT Id, User__c, User_Skill_Team__c, Original_Team_Type__c FROM User_Role__c WHERE Id = :objUserRole.Id LIMIT 1];
		Test.stopTest();

		System.assert(objUsrRole.Original_Team_Type__c != null);
	}
    
	/**
	 * @author       Deepika Saini
	 * @description  Check for Original Team Type
	 * @param        null
	 * @return       null
	 **/
	@isTest
	public static void testCarrierIOUserRole() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id, User_Skill_Team__c, Original_Team_Type__c FROM User_Role__c LIMIT 1];
		objUserRole.User_Skill_Team__c = 'Carrier IO';
		objUserRole.User_Skill_Type__c = 'Core';
		update objUserRole;
		Test.stopTest();

		User_Role__c objUsrRole1 = [SELECT Id, User__c, User_Skill_Team__c, Original_Team_Type__c FROM User_Role__c WHERE Id = :objUserRole.Id LIMIT 1];
		System.assert(objUsrRole1.Original_Team_Type__c != null);
	}
}