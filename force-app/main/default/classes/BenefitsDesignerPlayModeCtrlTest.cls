/**
 * @name		BenefitsDesignerPlayModeCtrlTest
 * @author      Neha Dabas
 * @date        June 9 2021
 * @description Unit tests BenefitsDesignerPlayModeCtrl
 * @class	BenefitsDesignerPlayModeCtrl
 * @revisions   Date ------------ Name ------------ Comments
 **/
@isTest
class BenefitsDesignerPlayModeCtrlTest {
	/**
	 * @Author      : Neha Dabas
	 * @Description : Create User Role Data
	 * @Parm        : null
	 * @Return      : null
	 **/
	static void createUserRoleData() {
		User_Role__c objUserRole = new User_Role__c();
		objUserRole.User__c = UserInfo.getUserId();
		objUserRole.User_Skill_Team__c = 'Benefits Advising';
		objUserRole.User_Skill_Type__c = 'Core';
		insert objUserRole;

		Role__c objBenefitsDesignerRole = new Role__c(Name = 'Benefits Designer', Skill_Type__c = 'Core');
		insert (objBenefitsDesignerRole);

		List<Skill__c> list_Skills = new List<Skill__c>();
		list_Skills.add(
			new Skill__c(
				Role__c = objBenefitsDesignerRole.Id,
				Coverage_Type__c = 'Medical',
				State_Group__c = 'Arizona'
			)
		);
		list_Skills.add(
			new Skill__c(
				Role__c = objBenefitsDesignerRole.Id,
				Coverage_Type__c = 'Dental',
				State_Group__c = 'Arizona'
			)
		);
		list_Skills.add(
			new Skill__c(
				Role__c = objBenefitsDesignerRole.Id,
				Coverage_Type__c = 'Vision',
				State_Group__c = 'Arizona'
			)
		);
		list_Skills.add(
			new Skill__c(
				Role__c = objBenefitsDesignerRole.Id,
				Coverage_Type__c = 'Short Term Disability',
				State_Group__c = 'Arizona'
			)
		);
		list_Skills.add(
			new Skill__c(
				Role__c = objBenefitsDesignerRole.Id,
				Coverage_Type__c = 'Long Term Disability',
				State_Group__c = 'Arizona'
			)
		);
		list_Skills.add(
			new Skill__c(Role__c = objBenefitsDesignerRole.Id, Coverage_Type__c = 'Life', State_Group__c = 'Arizona')
		);
		insert list_Skills;

		List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();
		for (Skill__c objSkl : list_Skills) {
			User_Skill__c objUR = new User_Skill__c();
			objUR.Skill__c = objSkl.Id;
			objUR.User_Role__c = objUserRole.Id;
			objUR.Skill_Role_Name__c = objBenefitsDesignerRole.Name;
			objUR.Active__c = true;
			list_UserSkills.add(objUR);
		}

		insert list_UserSkills;

		State__c testState = TestUtility.State();
		testState.Name = 'Arizona';
		testState.Abbreviation__c = 'AZ';

		update testState;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Create Opporutnities
	 * @Parm        : null
	 * @Return      : null
	 **/
	static void createOpportunities() {
		AccountTriggerHelper.skipTrigger = true;
		CarrierTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		
		Carrier__c objCarrier = TestUtility.createTestCarrier('Test Carrier', 'Arizona', true);

		Opportunity objOpp = TestUtility.BenefitsRenewalOpportunity();
		objOpp.Priority_Reason__c = 'EE escalation';
		objOpp.Submission_Deadline__c = System.today().addDays(30);
		objOpp.UW_Carrier_Previous_Year__c = objCarrier.Id;
		objOpp.UW_State_PY__c = 'Arizona';
		objOpp.StageName = 'Ready for default package';
		objOpp.HI_Effective_Date__c = System.today().addDays(40);
		update objOpp;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is not a Benefits Designer
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModeNotABenefitsDesigner() {
		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == false);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is a Benefits Designer without any opporutnities assigned
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModeNoAssignedOpp() {
		createUserRoleData();
		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		objCtrl.playOpportunities();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == true);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is a Benefits Designer with opportunity
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModePositive() {
		createUserRoleData();
		createOpportunities();
		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		objCtrl.playOpportunities();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == true);
		system.assert([SELECT COUNT() FROM Opportunity WHERE Benefits_Designer__c = :userInfo.getUserId()] == 1);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is a Benefits Designer with Carrier Preference
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModeWithCarrierPreference() {
		createUserRoleData();
		createOpportunities();
		User_Role__c objUserRole = [
			SELECT BD_User_Preference_Carrier__c, BD_User_Preference_State__c
			FROM User_Role__c
			WHERE User__c = :userInfo.getUserId()
		];

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c LIMIT 1];
		objUserRole.BD_User_Preference_Carrier__c = objCarrier.Id;
		update objUserRole;

		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		objCtrl.playOpportunities();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == true);
		system.assert([SELECT COUNT() FROM Opportunity WHERE Benefits_Designer__c = :userInfo.getUserId()] == 1);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is a Benefits Designer with Child Opportunity
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModeWithEligibleChildOpportunties() {
		createUserRoleData();
		createOpportunities();

		Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];

		Opportunity objOppChild = TestUtility.BenefitsRenewalOpportunity();
		objOppChild.Submission_Deadline__c = System.today().addDays(30);
		objOppChild.StageName = 'Ready for default package';
		objOppChild.HI_Effective_Date__c = System.today().addDays(40);
		objOppChild.Parent_Opportunity__c = objOpp.Id;
		update objOppChild;

		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		objCtrl.playOpportunities();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == true);
		system.assert([SELECT COUNT() FROM Opportunity WHERE Benefits_Designer__c = :userInfo.getUserId()] == 2);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is a Benefits Designer with Ineligible Child Opportunity
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModeWithInEligibleChildOpportunties() {
		createUserRoleData();
		createOpportunities();

		Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];

		Opportunity objOppChild = TestUtility.BenefitsRenewalOpportunity();
		objOppChild.Submission_Deadline__c = System.today().addDays(30);
		objOppChild.HI_Effective_Date__c = System.today().addDays(40);
		objOppChild.Parent_Opportunity__c = objOpp.Id;
		update objOppChild;

		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		objCtrl.playOpportunities();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == true);
		system.assert([SELECT COUNT() FROM Opportunity WHERE Benefits_Designer__c = :userInfo.getUserId()] == 0);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is a Benefits Designer with Bucket 2 Opportunity
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModeWithBucket2Opportunity() {
		createUserRoleData();
		createOpportunities();

		Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
		objOpp.Submission_Deadline__c = System.today().addDays(50);
		objOpp.HI_Effective_Date__c = System.today().addDays(60);
		objOpp.Priority_Reason__c = '';
		update objOpp;

		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		objCtrl.playOpportunities();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == true);
		system.assert([SELECT COUNT() FROM Opportunity WHERE Benefits_Designer__c = :userInfo.getUserId()] == 1);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Method to check, if user who is a Benefits Designer with Bucket 2 Opportunity With Carrier Preference
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testBDPlayModeWithBucket2OpportunityCarrierPref() {
		createUserRoleData();
		createOpportunities();
		User_Role__c objUserRole = [
			SELECT BD_User_Preference_Carrier__c, BD_User_Preference_State__c
			FROM User_Role__c
			WHERE User__c = :userInfo.getUserId()
		];

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c LIMIT 1];
		objUserRole.BD_User_Preference_Carrier__c = objCarrier.Id;
		update objUserRole;

		Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
		objOpp.Submission_Deadline__c = System.today().addDays(50);
		objOpp.HI_Effective_Date__c = System.today().addDays(60);
		objOpp.Priority_Reason__c = '';
		update objOpp;

		Test.startTest();
		BenefitsDesignerPlayModeCtrl objCtrl = new BenefitsDesignerPlayModeCtrl();
		objCtrl.playOpportunities();
		Test.stopTest();
		system.assert(objCtrl.blnIsBenefitDesginer == true);
		system.assert([SELECT COUNT() FROM Opportunity WHERE Benefits_Designer__c = :userInfo.getUserId()] == 1);
	}
}