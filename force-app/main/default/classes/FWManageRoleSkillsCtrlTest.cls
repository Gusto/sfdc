@isTest
private class FWManageRoleSkillsCtrlTest {
	@TestSetup
	static void setupData() {
		CarrierTriggerHelper.skipTrigger = true;
		TestUtility.createSkillCriteriaSetupRecord();
		TestUtility.createCarrierList();
		TestUtility.createFlexibleWorkforceCarriers();
		TestUtility.createStateNametoAbbreviationsMapping();
		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		for (Carrier__c objCarrier : [SELECT Name, Submission_BOR_Assignment__c FROM Carrier__c]) {
			objCarrier.Submission_BOR_Assignment__c = false;
			list_Carriers.add(objCarrier);
		}
		update list_Carriers;
	}

	
	
	//Implementation Advocate
	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, create Implementation Advocate - core  skills
	 * @param         null
	 * @return       null
	 **/
	@isTest
	static void createImplementationCoreSkill() {
		Test.startTest();
		User objUser = new User(Id = UserInfo.getUserId());
		ApexPages.Standardcontroller objStandardCtrl = new ApexPages.Standardcontroller(objUser);
		FWManageRoleSkillsCtrl objRole = new FWManageRoleSkillsCtrl(objStandardCtrl);
		objRole.objRegionPOD.Team__c = 'Implementation Advocate';
		objRole.ShowTeamSkillType();
		objRole.strSkillType = 'Core';
		objRole.ChangeSkillType();
		objRole.strRegionName = 'IA Region East';
		objRole.list_SelectedState.add(new SelectOption('Alabama', 'Alabama (AL)'));
		objRole.list_SelectedState.add(new SelectOption('Alaska', 'Alaska (AK)'));
		objRole.SaveRegionPODRecords();
		objRole.list_SelectedState.add(new SelectOption('Alabama', 'Alabama (AL)'));
		objRole.list_SelectedState.add(new SelectOption('Alaska', 'Alaska (AK)'));
		objRole.SaveSkill();
		
		objRole = new FWManageRoleSkillsCtrl(objStandardCtrl);
		objRole.objRegionPOD.Team__c = 'Implementation Advocate';
		objRole.ShowTeamSkillType();
		objRole.strSkillType = 'Core';

		objRole.cancelSelectedRegionPOD();
		List<Region_POD__c> list_RegionPOD = [SELECT Id, Key__c FROM Region_POD__c WHERE Team__c = 'Implementation Advocate' AND Skill_Type__c = 'Core' LIMIT 1];
		if (list_RegionPOD.size() > 0) {
			assignSkillToUserRole('Implementation Advocate', 'Core');
			ApexPages.currentPage().getParameters().put('Id', list_RegionPOD[0].Id);
			objRole.updateRegionPOD();
			objRole.list_SelectedState.clear();
			objRole.list_SelectedState.add(new SelectOption('Alabama', 'Alabama (AL)'));
			objRole.list_SelectedState.add(new SelectOption('Washington', 'Washington (WA)'));
			objRole.list_SelectedState.add(new SelectOption('Wisconsin', 'Wisconsin (WI)'));
			objRole.SaveRegionPODRecords();
		}
		Test.stopTest();
		System.assertEquals([SELECT COUNT() FROM Skill__c WHERE Role__r.Team__c = 'Implementation Advocate' AND Role__r.Skill_Type__c = 'Core'] > 0, true);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Create the User Role and assign to User
	 * @param         null
	 * @return       null
	 **/
	public static void assignSkillToUserRole(String strTeam, String strSkillType) {
		User_Role__c objUserRole = new User_Role__c();
		List<User_Role__c> list_UserRoles = [SELECT Id, User__c FROM User_Role__c WHERE User__c = :UserInfo.getUserId()];
		if (list_UserRoles.size() > 0) {
			objUserRole = list_UserRoles[0];
		} else {
			objUserRole = new User_Role__c(User__c = UserInfo.getUserId());
			insert objUserRole;
		}

		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		ApexPages.currentPage().getParameters().put('id', objUserRole.Id);
		AddSkillsForUserRoleCtrl objSkillCtrl = new AddSkillsForUserRoleCtrl();
		objSkillCtrl.strRoleData = strTeam;
		objSkillCtrl.ShowTeamSkillType();
		objSkillCtrl.strSkillType = strSkillType;
		objSkillCtrl.DisplayCriteriaSection();
		

		if (strTeam == 'Implementation Advocate' && strSkillType == 'Core') {
			if (!objSkillCtrl.list_RegionPODWrapper.isEmpty()) {
				objSkillCtrl.list_RegionPODWrapper[0].blnIsChecked = true;
			}

			objSkillCtrl.populateStates();
			objSkillCtrl.list_SelectedOrderType = objSkillCtrl.list_UnSelectedOrderType;
			objSkillCtrl.list_SelectedPartner = objSkillCtrl.list_UnSelectedPartner;
			objSkillCtrl.SaveSkill();
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Skills of Advisor Role using FWManageRoleSkills Page
	 * @param         null
	 * @return       null
	 **/
	@isTest
	static void createAdvisorCoreSkill() {
		Test.startTest();
		ApexPages.Standardcontroller objStandardCtrl = new ApexPages.Standardcontroller(new User(Id = UserInfo.getUserId()));
		FWManageRoleSkillsCtrl objFWManageRole = new FWManageRoleSkillsCtrl(objStandardCtrl);

		objFWManageRole.objRegionPOD.Team__c = FWManageRoleUtil.ROLE_ADVISOR;
		objFWManageRole.ShowTeamSkillType();
		objFWManageRole.SaveSkill();

		Test.stopTest();

		List<Skill__c> list_Skills = [SELECT Id, Role__r.Name, State_Group__c FROM Skill__c LIMIT 1];

		System.assert(list_Skills.size() > 0);
		System.assertEquals(FWManageRoleUtil.ROLE_ADVISOR, list_Skills[0].Role__r.Name);
		System.assertNotEquals(null, list_Skills[0].State_Group__c);
		System.assertEquals([SELECT COUNT() FROM Skill__c WHERE Role__r.Team__c = :FWManageRoleUtil.ROLE_ADVISOR AND Role__r.Skill_Type__c = 'Core'] > 0, true);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Skills of Renewal Specialist Role using FWManageRoleSkills Page
	 * @param         null
	 * @return       null
	 **/
	@isTest
	static void createRenewalSpecialistCoreSkill() {
		Test.startTest();
		ApexPages.Standardcontroller objStandardCtrl = new ApexPages.Standardcontroller(new User(Id = UserInfo.getUserId()));
		FWManageRoleSkillsCtrl objFWManageRole = new FWManageRoleSkillsCtrl(objStandardCtrl);

		objFWManageRole.objRegionPOD.Team__c = FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST;
		objFWManageRole.ShowTeamSkillType();
		objFWManageRole.SaveSkill();

		Test.stopTest();

		List<Skill__c> list_Skills = [SELECT Id, Role__r.Name, State_Group__c FROM Skill__c LIMIT 1];

		System.assert(list_Skills.size() > 0);
		System.assertEquals(FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST, list_Skills[0].Role__r.Name);
		System.assertNotEquals(null, list_Skills[0].State_Group__c);
		System.assertEquals([SELECT COUNT() FROM Skill__c WHERE Role__r.Team__c = :FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST AND Role__r.Skill_Type__c = 'Core'] > 0, true);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Skills of Benefits Designer Role using FWManageRoleSkills Page
	 * @param         null
	 * @return       null
	 **/
	@isTest
	static void createBenefitDesignerCoreSkill() {
		Test.startTest();
		ApexPages.Standardcontroller objStandardCtrl = new ApexPages.Standardcontroller(new User(Id = UserInfo.getUserId()));
		FWManageRoleSkillsCtrl objFWManageRole = new FWManageRoleSkillsCtrl(objStandardCtrl);

		objFWManageRole.objRegionPOD.Team__c = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER;
		objFWManageRole.ShowTeamSkillType();
		objFWManageRole.SaveSkill();

		Test.stopTest();

		List<Skill__c> list_Skills = [SELECT Id, Role__r.Name, State_Group__c, Coverage_Type__c FROM Skill__c LIMIT 1];

		System.assert(list_Skills.size() > 0);
		System.assertEquals(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER, list_Skills[0].Role__r.Name);
		System.assertNotEquals(null, list_Skills[0].Coverage_Type__c);
		System.assertNotEquals(null, list_Skills[0].State_Group__c);
		System.assertEquals([SELECT COUNT() FROM Skill__c WHERE Role__r.Name = :FWManageRoleUtil.ROLE_BENEFITS_DESIGNER AND Role__r.Skill_Type__c = 'Core'] > 0, true);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Region for Benefit Designer Role using FWManageRoleSkills Page
	 * @param         null
	 * @return       null
	 **/
	@isTest
	static void createRegionBenefitDesigner() {
		Test.startTest();
		ApexPages.Standardcontroller objStandardCtrl = new ApexPages.Standardcontroller(new User(Id = UserInfo.getUserId()));
		FWManageRoleSkillsCtrl objFWManageRole = new FWManageRoleSkillsCtrl(objStandardCtrl);

		objFWManageRole.objRegionPOD.Team__c = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER;
		objFWManageRole.ShowTeamSkillType();

		objFWManageRole.strRegionName = 'BD Region East';
		objFWManageRole.list_SelectedState.add(new SelectOption('Alabama', 'Alabama'));
		objFWManageRole.list_SelectedState.add(new SelectOption('Alaska', 'Alaska'));
		objFWManageRole.SaveRegionPODRecords();

		Test.stopTest();

		List<Region_POD__c> list_RegionPODs = [SELECT Id, Team__c, Skill_Type__c FROM Region_POD__c LIMIT 1];

		System.assert(list_RegionPODs.size() > 0);
		System.assertEquals(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER, list_RegionPODs[0].Team__c);
		System.assertEquals(FWManageRoleUtil.SKILL_TYPE_CORE, list_RegionPODs[0].Skill_Type__c);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Region for Advisor Role using FWManageRoleSkills Page
	 * @param         null
	 * @return       null
	 **/
	@isTest
	static void createRegionAdvisor() {
		Test.startTest();
		ApexPages.Standardcontroller objStandardCtrl = new ApexPages.Standardcontroller(new User(Id = UserInfo.getUserId()));
		FWManageRoleSkillsCtrl objFWManageRole = new FWManageRoleSkillsCtrl(objStandardCtrl);

		objFWManageRole.objRegionPOD.Team__c = FWManageRoleUtil.ROLE_ADVISOR;
		objFWManageRole.ShowTeamSkillType();

		objFWManageRole.strRegionName = 'Advisor Region East';
		objFWManageRole.list_SelectedState.add(new SelectOption('Alabama', 'Alabama'));
		objFWManageRole.list_SelectedState.add(new SelectOption('Alaska', 'Alaska'));
		objFWManageRole.SaveRegionPODRecords();

		Test.stopTest();

		List<Region_POD__c> list_RegionPODs = [SELECT Id, Team__c, Skill_Type__c FROM Region_POD__c LIMIT 1];

		System.assert(list_RegionPODs.size() > 0);
		System.assertEquals(FWManageRoleUtil.ROLE_ADVISOR, list_RegionPODs[0].Team__c);
		System.assertEquals(FWManageRoleUtil.SKILL_TYPE_CORE, list_RegionPODs[0].Skill_Type__c);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Region for Renewal Specialist Role using FWManageRoleSkills Page
	 * @param         null
	 * @return       null
	 **/
	@isTest
	static void createRegionRenewalSpecialist() {
		Test.startTest();
		ApexPages.Standardcontroller objStandardCtrl = new ApexPages.Standardcontroller(new User(Id = UserInfo.getUserId()));
		FWManageRoleSkillsCtrl objFWManageRole = new FWManageRoleSkillsCtrl(objStandardCtrl);

		objFWManageRole.objRegionPOD.Team__c = FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST;
		objFWManageRole.ShowTeamSkillType();

		objFWManageRole.strRegionName = 'RS Region East';
		objFWManageRole.list_SelectedState.add(new SelectOption('Alabama', 'Alabama'));
		objFWManageRole.list_SelectedState.add(new SelectOption('Alaska', 'Alaska'));
		objFWManageRole.SaveRegionPODRecords();

		Test.stopTest();

		List<Region_POD__c> list_RegionPODs = [SELECT Id, Team__c, Skill_Type__c FROM Region_POD__c LIMIT 1];

		System.assert(list_RegionPODs.size() > 0);
		System.assertEquals(FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST, list_RegionPODs[0].Team__c);
		System.assertEquals(FWManageRoleUtil.SKILL_TYPE_CORE, list_RegionPODs[0].Skill_Type__c);
	}
}