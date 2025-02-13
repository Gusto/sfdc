/**
 * @name         AddSkillsForUserRoleCtrlTest
 * @author
 * @date         07/19/2022
 * @description  This class is used to test the functionality of AddSkillsForUserRoleCtrl controller .
 **/
@isTest
public class AddSkillsForUserRoleCtrlTest {
	@TestSetup
	static void makeData() {
		User_Role__c objUserRole = newUserRole();

		TestUtility.createSkillCriteriaSetupRecord();
		TestUtility.createCarrierList();
		TestUtility.createFlexibleWorkforceCarriers();
		TestUtility.createStateNametoAbbreviationsMapping();

		List<Role__c> list_Roles = new List<Role__c>();
		Role__c objIARole = new TestDataFactory.RoleBuilder().setName('Implementation Advocate').setSkillType('Core').setTeam('Implementation Advocate').build();
		list_Roles.add(objIARole);

		Role__c objBTAdvocateRole = new TestDataFactory.RoleBuilder().setName('Benefit Transfer Advocate').setSkillType('Core').build();
		list_Roles.add(objBTAdvocateRole);

		Role__c objBTFacilitator1Role = new TestDataFactory.RoleBuilder().setName('Benefit Transfer Facilitator 1').setSkillType('Core').build();
		list_Roles.add(objBTFacilitator1Role);

		Role__c objBTFacilitator2Role = new TestDataFactory.RoleBuilder().setName('Benefit Transfer Facilitator 2').setSkillType('Core').build();
		list_Roles.add(objBTFacilitator2Role);

		Role__c objPTAdvocateRole = new TestDataFactory.RoleBuilder().setName('Payroll Transfer Advocate').setSkillType('Core').build();
		list_Roles.add(objPTAdvocateRole);

		Role__c objPTFacilitatorRole = new TestDataFactory.RoleBuilder().setName('Payroll Transfer Facilitator').setSkillType('Core').build();
		list_Roles.add(objPTFacilitatorRole);

		Role__c objAdvisorRole = new TestDataFactory.RoleBuilder().setName('Advisor').setSkillType('Core').build();
		list_Roles.add(objAdvisorRole);

		Role__c objRenewalSpecialistRole = new TestDataFactory.RoleBuilder().setName('Renewal Specialist').setSkillType('Core').build();
		list_Roles.add(objRenewalSpecialistRole);

		Role__c objBenefitsDesignerRole = new TestDataFactory.RoleBuilder().setName('Benefits Designer').setSkillType('Core').build();
		list_Roles.add(objBenefitsDesignerRole);

		insert (list_Roles);

		List<Skill__c> list_Skills = new List<Skill__c>();
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objIARole.Id).setOrderType('New To Gusto').setPartnerTier('Gold').setStateGroup('Arizona').setTADA(true).setBigDesk(true).build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objIARole.Id).setOrderType('New To Gusto').setPartnerTier('Gold').setStateGroup('Arizona').setTADA(true).setBigDesk(false).build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objPTAdvocateRole.Id).setPTSkills('Bulk Order').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objPTAdvocateRole.Id).setPTSkills('Direct Order').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objPTFacilitatorRole.Id).setPTSkills('Bulk Order').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objPTFacilitatorRole.Id).setPTSkills('Direct Order').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTFacilitator1Role.Id).setPODSkill('POD 1').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTFacilitator1Role.Id).setPODSkill('POD 2').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTFacilitator1Role.Id).setPODSkill('POD 3').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTFacilitator1Role.Id).setPODSkill('Unassigned').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTAdvocateRole.Id).setTADA(true).build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTAdvocateRole.Id).setTADA(false).build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTFacilitator2Role.Id).setBuildPlan(true).build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBTFacilitator2Role.Id).setBuildPlan(false).build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objAdvisorRole.Id).setBigDesk(true).setStateGroup('Arizona').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objAdvisorRole.Id).setBigDesk(false).setStateGroup('Arizona').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objRenewalSpecialistRole.Id).build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBenefitsDesignerRole.Id).setCoverageType('Medical').setStateGroup('Arizona').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBenefitsDesignerRole.Id).setCoverageType('Dental').setStateGroup('Arizona').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBenefitsDesignerRole.Id).setCoverageType('Vision').setStateGroup('Arizona').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBenefitsDesignerRole.Id).setCoverageType('Short Term Disability').setStateGroup('Arizona').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBenefitsDesignerRole.Id).setCoverageType('Long Term Disability').setStateGroup('Arizona').build());
		list_Skills.add(new TestDataFactory.SkillBuilder().setRoleId(objBenefitsDesignerRole.Id).setCoverageType('Life').setStateGroup('Arizona').build());

		Skill__c objComplexityLevel1Skill = new TestDataFactory.SkillBuilder()
			.setRoleId(objPTFacilitatorRole.Id)
			.setComplexityLevel('Level 1')
			.setBenefitCount('0')
			.setState('AK; AL; AR; AZ; CA; CT; DC; FL; GA; HI; IA; ID; IL; KS; LA; MD; ME; MN; MS; MT; NC; ND; NE; NH; NM; NV; OK; PA; RI; SC; SD; TN; TX; UT; VA; VT; WI; WV; WY')
			.setStatesCount('0-1')
			.setPreviousPayrollProvider(
				'ADP Run; ADP Resource; ADP Total Source; BenefitMall; Bank of America; Heartland Payroll; Intuit Online Payroll; iSolved; JustWorks; Namely; Other; Patriot Software; Paychex; Paychex Preview; Paylocity; PEO / Full Service Backend Provider; QuickBooks Desktop; QuickBooks Online; Sage; Square; SurePayroll; Thomson Reuters; Trinet; Zenefits; BambooHR; Toast; Rippling'
			)
			.build();
		list_Skills.add(objComplexityLevel1Skill);

		Skill__c objComplexityLevel2Skill = new TestDataFactory.SkillBuilder()
			.setRoleId(objPTFacilitatorRole.Id)
			.setComplexityLevel('Level 2')
			.setBenefitCount('0; 1-4')
			.setState(
				'AK; AL; AR; AZ; CA; CO; CT; DC; DE; FL; GA; HI; IA; ID; IL; IN; KS; KY; LA; MA; MD; ME; MI; MN; MO; MS; MT; NC; ND; NE; NH; NJ; NM; NV; NY; OK; OR; RI; SC; SD; TN; TX; UT; VA; VT; WA; WI; WV; WY'
			)
			.setStatesCount('0-1; 1-4')
			.setPreviousPayrollProvider(
				'ADP Run; ADP Resource; ADP Total Source; ADP Workforce Now; BenefitMall; Bank of America; Heartland Payroll; Intuit Online Payroll; iSolved; JustWorks; Namely; Other; Patriot Software; Paychex; Paychex Preview; Paylocity; PEO / Full Service Backend Provider; QuickBooks Desktop; QuickBooks Online; Sage; Square; SurePayroll; Thomson Reuters; Trinet; Zenefits; BambooHR; Toast; Rippling'
			)
			.build();
		list_Skills.add(objComplexityLevel2Skill);

		Skill__c objComplexityLevel3Skill = new TestDataFactory.SkillBuilder()
			.setRoleId(objPTFacilitatorRole.Id)
			.setComplexityLevel('Level 3')
			.setBenefitCount('0; 1-4; 4+')
			.setState(
				'AK; AL; AR; AZ; CA; CO; CT; DC; DE; FL; GA; HI; IA; ID; IL; IN; KS; KY; LA; MA; MD; ME; MI; MN; MO; MS; MT; NC; ND; NE; NH; NJ; NM; NV; NY; OH; OK; OR; PA; RI; SC; SD; TN; TX; UT; VA; VT; WA; WI; WV; WY'
			)
			.setStatesCount('0-1; 1-4; 4+')
			.setPreviousPayrollProvider(
				'ADP Run; ADP Resource; ADP Total Source; ADP Workforce Now; BenefitMall; Bank of America; Heartland Payroll; Intuit Online Payroll; iSolved; JustWorks; Namely; Other; Offline (manual); Offline (downloaded reports); Patriot Software; Paychex; Paychex Preview; Paylocity; PEO / Full Service Backend Provider; QuickBooks Desktop; QuickBooks Online; Sage; Square; SurePayroll; Thomson Reuters; Trinet; Zenefits; BambooHR; Toast; Rippling'
			)
			.build();
		list_Skills.add(objComplexityLevel3Skill);

		insert list_Skills;

		State__c objState = new TestDataFactory.StateBuilder().setName('Arizona').setAbbreviation('AZ').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Alegeus').setState(objState.Id).setPartnerType('TAdA').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('TEST CARRIER 1').setState(objState.Id).build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('TEST CARRIER 2').setState(objState.Id).build());
		insert list_Carriers;
		createImplementationCoreSkill();

		list<Region_POD__c> list_POD = new List<Region_POD__c>();
		list_POD.add(new TestDataFactory.RegionPODBuilder().setName('Carrier POD 1').setTeam('Implementation Advocate').setType('Region').setSkillType('Core').build());
		list_POD.add(new TestDataFactory.RegionPODBuilder().setName('Carrier POD 2').setTeam('Implementation Advocate').setType('POD').setSkillType('Core').build());
		list_POD.add(new TestDataFactory.RegionPODBuilder().setName('Advisor Region POD 1').setTeam('Advisor').setType('Region').setSkillType('Core').build());
		list_POD.add(new TestDataFactory.RegionPODBuilder().setName('Advisor Region POD 2').setTeam('Advisor').setType('Region').setSkillType('Core').build());
		insert list_POD;

		list<Region_POD_mapping__c> list_PODMapping = new List<Region_POD_mapping__c>();
		Integer counterM = 0;
		for (Region_POD__c objPod : list_POD) {
			list_PODMapping.add(new TestDataFactory.RegionPODMappingBuilder().setCarrier(list_Carriers[counterM].Id).setRegionPOD(objPod.Id).setState(list_Carriers[counterM].State__c).build());
		}
		insert list_PODMapping;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to create skills for Implementation Advocate
	 * @param        null
	 * @return       null
	 **/
	static void createImplementationCoreSkill() {
		User userObj = new User(Id = UserInfo.getUserId());
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(userObj);
		FWManageRoleSkillsCtrl objRole = new FWManageRoleSkillsCtrl(sc);
		objRole.objRegionPOD.Team__c = 'Implementation Advocate';
		objRole.ShowTeamSkillType();
		objRole.strSkillType = 'Core';
		objRole.ChangeSkillType();
		objRole.strRegionName = 'IA Region East';
		objRole.list_SelectedState.add(new SelectOption('AL', 'Alabama (AL)'));
		objRole.list_SelectedState.add(new SelectOption('AK', 'Alaska (AK)'));
		objRole.SaveRegionPODRecords();
		objRole.SaveSkill();
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to create User Role
	 * @param        null
	 * @return       null
	 **/
	static User_Role__c newUserRole() {
		User_Role__c objUserRole = new TestDataFactory.UserRoleBuilder().setUserId(UserInfo.getUserId()).setUserTeam('Implementation Advocate').setUserSkillType('Core').build();
		insert objUserRole;
		return objUserRole;
	}

	

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, user role creation for Payroll Transfer Advocate
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testPTAdvocateUserSkillPositive() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference pageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('id', objUserRole.id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objAddSkillsCtrl.strRoleData = 'Payroll Transfer Advocate';
		objAddSkillsCtrl.ShowTeamSkillType();
		objAddSkillsCtrl.list_selectedPTSkillValues.add(new selectOption('Bulk Order', 'Bulk Order'));
		objAddSkillsCtrl.SaveSkill();
		objAddSkillsCtrl.redirectToFBOS();
		Test.stopTest();
		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE Skill_Role_Name__c = 'Payroll Transfer Advocate'] > 0, true);
	}

	//Complexity Level check for PT Facilitator Save Skill
	@isTest
	public static void positiveComplexityLevelTestCase() {
		User_Role__c userRole = [SELECT Id FROM User_Role__c LIMIT 1];

		Test.startTest();
		PageReference pageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('id', userRole.id);
		AddSkillsForUserRoleCtrl skillsCtrl = new AddSkillsForUserRoleCtrl();

		skillsCtrl.blnShowStateSection = true;
		skillsCtrl.blnShowRegionSection = true;
		skillsCtrl.blnShowOrderTypeSection = true;
		skillsCtrl.blnShowSPartnerSection = true;
		skillsCtrl.blnShowTADASection = false;

		skillsCtrl.list_SelectedOrderType.add(new System.SelectOption('New to Gusto', 'New to Gusto'));
		skillsCtrl.list_SelectedState.add(new System.SelectOption('Alabama', 'Alabama'));
		skillsCtrl.list_SelectedPartner.add(new System.SelectOption('Gold', 'Gold'));
		skillsCtrl.strPTCompScore = 'Hard';
		skillsCtrl.strSelectedPTFacilitatorComplexityLevel = 'Level 1';
		skillsCtrl.strUserRoleId = userRole.Id;
		skillsCtrl.strRoleData = 'Payroll Transfer Facilitator';

		skillsCtrl.selectRole();
		skillsCtrl.strSelectedPTFacilitatorComplexityLevel = 'Level 3';
		skillsCtrl.handleComplexityLevelChange();
		skillsCtrl.list_selectedPTSkillValues.add(new SelectOption('Direct Order', 'Direct Order'));
		skillsCtrl.list_selectedPTPrevProvider.add(new SelectOption('Instabase', 'Instabase'));
		skillsCtrl.list_selectedPTSalesTeam.add(new SelectOption('Small Business Sales', 'Small Business Sales'));
		skillsCtrl.SaveSkill();
		Test.stopTest();

		List<User_Skill__c> list_userSkills = [
			SELECT Id, Skill__r.PT_Facilitator_Complexity_Level__c
			FROM User_Skill__c
			WHERE Skill__r.PT_Facilitator_Complexity_Level__c != NULL AND User_Role__c = :userRole.Id
		];

		System.assert(list_userSkills != null);
		System.assert(list_userSkills.size() > 0);
	}

	
	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Benefit Transfer user skill creation for user role - positive
	 * @param        null
	 * @return       null
	 **/
	@isTest
	public static void testBenefitTransferPositive() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objAddSkillsCtrl.strRoleData = 'Benefit Transfer';
		objAddSkillsCtrl.ShowTeamSkillType();
		objAddSkillsCtrl.map_BTDefineSkills = new Map<String, Boolean>();
		objAddSkillsCtrl.map_BTDefineSkills.put('Advocate', true);
		objAddSkillsCtrl.map_BTDefineSkills.put('Qualifier', true);
		objAddSkillsCtrl.map_BTDefineSkills.put('Facilitator 1', false);
		objAddSkillsCtrl.map_BTDefineSkills.put('Facilitator 2', false);
		objAddSkillsCtrl.blnIsTada = true;
		objAddSkillsCtrl.strBTNotes = 'test';

		objAddSkillsCtrl.SaveSkill();
		Test.stopTest();
		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE Skill_Role_Name__c LIKE 'Benefit Transfer%'] > 0, true);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Benefit Transfer user skill creation for user role - positive
	 * @param        null
	 * @return       null
	 **/
	@isTest
	public static void testBenefitTransferPos() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objAddSkillsCtrl.strRoleData = 'Benefit Transfer';
		objAddSkillsCtrl.ShowTeamSkillType();
		objAddSkillsCtrl.map_BTDefineSkills = new Map<String, Boolean>();
		objAddSkillsCtrl.map_BTDefineSkills.put('Advocate', true);
		objAddSkillsCtrl.ManageBOAllocation();
		objAddSkillsCtrl.map_BTDefineSkills.put('Facilitator 1', true);
		objAddSkillsCtrl.ManageBOAllocation();
		objAddSkillsCtrl.map_BTDefineSkills.put('Facilitator 2', true);
		objAddSkillsCtrl.ManageBOAllocation();
		objAddSkillsCtrl.map_BTDefineSkills.put('Qualifier', true);
		objAddSkillsCtrl.ManageBOAllocation();

		objAddSkillsCtrl.list_SelectedPODsValues.add(new System.SelectOption('POD 1', 'POD 1'));
		objAddSkillsCtrl.blnIsTada = true;
		objAddSkillsCtrl.blnIsBuildPlan = true;
		objAddSkillsCtrl.SaveSkill();
		Test.stopTest();
		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE Skill_Role_Name__c LIKE 'Benefit Transfer%'] > 0, true);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Implementation Advocate user skill creation for user role - positive
	 * @param        null
	 * @return       null
	 **/
	@isTest
	public static void testIAUserSkillsPositive() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objAddSkillsCtrl.strRoleData = 'Implementation Advocate';
		objAddSkillsCtrl.ShowTeamSkillType();
		objAddSkillsCtrl.strSkillType = 'Core';
		objAddSkillsCtrl.DisplayCriteriaSection();
		Set<String> set_String = new Set<String>();
		set_String.add('true');
		objAddSkillsCtrl.setSelectedValuesOnUI(set_String, '', 'No TAda');
		objAddSkillsCtrl.list_SelectedOrderType.add(new selectOption('New To Gusto', 'New To Gusto'));
		objAddSkillsCtrl.list_SelectedState.add(new selectOption('Arizona', 'Arizona'));
		objAddSkillsCtrl.list_SelectedPartner.add(new selectOption('Gold', 'Gold'));
		objAddSkillsCtrl.SaveSkill();
		Test.stopTest();

		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE Skill_Role_Name__c LIKE 'Implementation Advocate'] == 0, true);
	}


	/**
	 * @author      : Neha Dabas
	 * @description : Test Method to check, Validate that conflicting Advisor and Renewal Specialist Roles are not selected
	 * @param        : null
	 * @return      : null
	 **/
	@isTest
	public static void testAdvisorRoleSkillValidation() {
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];

		Test.startTest();
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		String strRegionPOD = [SELECT Id FROM Region_POD__c LIMIT 1].Id;
		objPageRef.getParameters().put('strRecId', strRegionPOD);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();

		objAddSkillsCtrl.strRoleData = FWManageRoleUtil.TEAM_ADVISING;
		objAddSkillsCtrl.ShowTeamSkillType();

		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).blnSelected = true;
		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST).blnSelected = true;
		objAddSkillsCtrl.strOrderAllocRoleType = FWManageRoleUtil.ROLE_ADVISOR;
		objAddSkillsCtrl.onRoleSelect();

		Test.stopTest();

		System.assertEquals(objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST).blnSelected, false);
	}

	/**
	 * @author      : Neha Dabas
	 * @description : Test Method to check, Advisor Role Skill Creation
	 * @param        : null
	 * @return      : null
	 **/
	@isTest
	public static void testAdvisorRoleSkillCreationPositive() {
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];

		Test.startTest();
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		String strRegionPOD = [SELECT Id FROM Region_POD__c LIMIT 1].Id;
		objPageRef.getParameters().put('strRecId', strRegionPOD);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();

		objAddSkillsCtrl.strRoleData = FWManageRoleUtil.TEAM_ADVISING;
		objAddSkillsCtrl.ShowTeamSkillType();

		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).blnSelected = true;
		objAddSkillsCtrl.strOrderAllocRoleType = FWManageRoleUtil.ROLE_ADVISOR;
		objAddSkillsCtrl.onRoleSelect();

		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).blnBenefitsBigDesk = true;

		if (objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_SelectedState != null) {
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_SelectedState.add(new SelectOption('Arizona', 'Arizona'));
		}

		if (objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_AllocationWrapper != null) {
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_AllocationWrapper[0].objBO.Max_BO__c = 20;
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_AllocationWrapper[0].objBO.Month__c = 6;
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_AllocationWrapper[0].objBO.Year__c = 2021;
		}

		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_RegionPODWrapper[0].blnIsChecked = true;
		objAddSkillsCtrl.strSelectedSkillRoleName = FWManageRoleUtil.ROLE_ADVISOR;
		objAddSkillsCtrl.populateRegionAndStates();

		if (objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_SelectedState != null) {
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).list_SelectedState.add(new SelectOption('Arizona', 'Arizona'));
		}

		objAddSkillsCtrl.SaveSkill();

		objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();

		Test.stopTest();

		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE User_Role__c = :objUserRole.Id AND Skill_Role_Name__c = :FWManageRoleUtil.ROLE_ADVISOR] > 0, true);
	}

	/**
	 * @author      : Neha Dabas
	 * @description : Test Method to check, Benefits Designer Role Skill Creation Validations
	 * @param        : null
	 * @return      : null
	 **/
	@isTest
	public static void testBenefitsDesignerRoleSkillCreationNegative() {
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];

		Test.startTest();
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();

		objAddSkillsCtrl.strRoleData = FWManageRoleUtil.TEAM_ADVISING;
		objAddSkillsCtrl.ShowTeamSkillType();

		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).blnSelected = true;
		objAddSkillsCtrl.strOrderAllocRoleType = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER;
		objAddSkillsCtrl.onRoleSelect();
		objAddSkillsCtrl.SaveSkill();

		Test.stopTest();

		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE User_Role__c = :objUserRole.Id AND Skill_Role_Name__c = :FWManageRoleUtil.ROLE_BENEFITS_DESIGNER], 0);
	}

	/**
	 * @author      : Neha Dabas
	 * @description : Test Method to check, Benefits Designer Role Skill Creation
	 * @param        : null
	 * @return      : null
	 **/
	@isTest
	public static void testBenefitsDesignerRoleSkillCreationPositive() {
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];

		Test.startTest();
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();

		objAddSkillsCtrl.strRoleData = FWManageRoleUtil.TEAM_ADVISING;
		objAddSkillsCtrl.ShowTeamSkillType();

		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).blnSelected = true;
		objAddSkillsCtrl.strOrderAllocRoleType = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER;
		objAddSkillsCtrl.onRoleSelect();
		if (objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedCoverageType != null) {
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedCoverageType.add(new SelectOption('Medical', 'Medical'));
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedCoverageType.add(new SelectOption('Life', 'Life'));

			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedState.add(new SelectOption('Arizona', 'Arizona'));
		}

		objAddSkillsCtrl.SaveSkill();

		objPageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();

		objAddSkillsCtrl.strRoleData = FWManageRoleUtil.TEAM_ADVISING;
		objAddSkillsCtrl.ShowTeamSkillType();

		Test.stopTest();

		System.assert([SELECT COUNT() FROM User_Skill__c WHERE User_Role__c = :objUserRole.Id AND Skill_Role_Name__c = :FWManageRoleUtil.ROLE_BENEFITS_DESIGNER] > 0);
	}

	/**
	 * @author      : Anand Singh
	 * @description : Test Method to check, Account Specialist Role Skill Creation
	 * @param        : null
	 * @return      : null
	 **/
	@isTest
	public static void testTaxResAccountSpecialistRoleSkillCreationPositive() {
		Test.startTest();
		UserRoleTriggerHelper.skipTrigger = true;
		User_Role__c objUserRole = [SELECT Id, User_Skill_Team__c, Tax_Res_Skill_Type__c FROM User_Role__c LIMIT 1];
		objUserRole.User_Skill_Team__c = AddSkillsForUserRoleCtrl.TAX_RES_ACCOUNT_SPECIALIST;
		objUserRole.Tax_Res_Skill_Type__c = 'All Cases';
		update objUserRole;
		UserRoleTriggerHelper.skipTrigger = false;

		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
		Role__c objRole = TestDataFactory.CreateRole(AddSkillsForUserRoleCtrl.TAX_RES_ACCOUNT_SPECIALIST);
		Region_POD__c objRegionPOD = TestDataFactory.CreateAgencyRegion('Test AS Region', AddSkillsForUserRoleCtrl.TAX_RES_ACCOUNT_SPECIALIST);

		List<Region_POD_mapping__c> list_RegionPODMappings = TestDataFactory.CreateAgencyRegionPODMapping(objRegionPOD, list_AgencyInformations);
		List<Skill__c> list_Skills = TestDataFactory.CreateSkill(objRole, list_RegionPODMappings);

		Apexpages.currentPage().getParameters().put('id', objUserRole.Id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objAddSkillsCtrl.strRoleData = AddSkillsForUserRoleCtrl.TAX_RES_ACCOUNT_SPECIALIST;
		objAddSkillsCtrl.selectRole();

		objAddSkillsCtrl.list_TaxResRegionsPOD = new List<AddSkillsForUserRoleCtrl.TaxResPODWrapper>();

		//get All Skill and Add into Wrapper
		for (Skill__c objSkill : [
			SELECT Id, Role__c, Role__r.Name, Region_POD__c, Region_POD__r.Name, Name
			FROM Skill__c
			WHERE Region_POD__r.Team__c = :AddSkillsForUserRoleCtrl.TAX_RES_ACCOUNT_SPECIALIST
		]) {
			objAddSkillsCtrl.list_TaxResRegionsPOD.add(new AddSkillsForUserRoleCtrl.TaxResPODWrapper(objSkill, true));
		}
		objAddSkillsCtrl.objUserRole.Tax_Res_Skill_Type__c = 'All Cases';
		objAddSkillsCtrl.SaveSkill();
		List<User_Role__c> list_UserRole = [SELECT Assigned_POD__c FROM User_Role__c];
		Test.stopTest();
		System.assertEquals(list_UserRole[0].Assigned_POD__c, 'Test AS Region');
		System.assert([SELECT COUNT() FROM User_Skill__c WHERE User_Skill_Role_Name__c = :AddSkillsForUserRoleCtrl.TAX_RES_ACCOUNT_SPECIALIST] > 0);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, user role creation with carrier IO
	 * @param        null
	 * @return       null
	 **/
	@isTest
	public static void testCarrierIOCreation() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		AddSkillsForUserRoleCtrl objSkillsCtrl = new AddSkillsForUserRoleCtrl();

		objSkillsCtrl.strRoleData = 'Carrier IO';
		objSkillsCtrl.ShowTeamSkillType();
		objSkillsCtrl.SaveSkill();
		Test.stopTest();

		User_Role__c objUserRoleTemp = [SELECT Id, User_Skill_Team__c FROM User_Role__c WHERE Id = :objUserRole.Id];
		System.assertEquals('Carrier IO', objUserRoleTemp.User_Skill_Team__c);
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Test Method to check existing cases for Account Specialist before changing Skill
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	public static void testTaxResAccountSpecialistExistingCasesScenario() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account Test Builder').setZPCompanyId('2222222222').build();
		insert objCompAccount;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Test User Role Changes')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test2@gusto.com')
			.setDescription('Test User Role Change')
			.build();

		objCase.Account_Specialist__c = UserInfo.getUserId();
		insert objCase;

		Test.startTest();

		List<Case> list_CaseRecs = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		list_CaseRecs[0].Status = 'Research in progress';

		update list_CaseRecs;

		UserRoleTriggerHelper.skipTrigger = true;
		User_Role__c objUserRole = [SELECT Id, User_Skill_Team__c, Tax_Res_Skill_Type__c FROM User_Role__c LIMIT 1];
		objUserRole.User_Skill_Team__c = AddSkillsForUserRoleCtrl.TAX_RES_ACCOUNT_SPECIALIST;
		objUserRole.Tax_Res_Skill_Type__c = 'All Cases';
		update objUserRole;
		UserRoleTriggerHelper.skipTrigger = false;
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, allocation of Benefit Order
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testBOAllocationPositive() {

		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		AddSkillsForUserRoleCtrl objSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objSkillsCtrl.strRoleData = 'Implementation Advocate';
		objSkillsCtrl.ShowTeamSkillType();
		objSkillsCtrl.strSkillType = 'Core';
		objSkillsCtrl.list_SelectedOrderType.add(new selectOption('New To Gusto', 'New To Gusto'));
		objSkillsCtrl.list_SelectedState.add(new selectOption('Arizona', 'Arizona'));
		objSkillsCtrl.list_SelectedPartner.add(new selectOption('Gold', 'Gold'));
		objSkillsCtrl.list_MonthsPicklist.add(new selectOption('April', 'April'));
		objSkillsCtrl.list_YearsPicklist.add(new selectOption('2022', '2022'));
		objSkillsCtrl.list_ManageBOWrappers[0].objBO.Max_BO__c = 10;
		objSkillsCtrl.SaveSkill();
		Test.stopTest();
		List<Benefit_Order_Allocation__c> objBO = [SELECT Id, User__c FROM Benefit_Order_Allocation__c];
		System.assert(objBO.size() > 0);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, deletion of allocated of Benefit Order
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testBOAllocationDelete() {

		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPage1 = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPage1);
		objPage1.getParameters().put('id', objUserRole.Id);
		AddSkillsForUserRoleCtrl objSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objSkillsCtrl.strRoleData = 'Implementation Advocate';
		objSkillsCtrl.ShowTeamSkillType();
		objSkillsCtrl.strSkillType = 'Core';
		objSkillsCtrl.list_SelectedOrderType.add(new selectOption('New To Gusto', 'New To Gusto'));
		objSkillsCtrl.list_SelectedState.add(new selectOption('Arizona', 'Arizona'));
		objSkillsCtrl.list_SelectedPartner.add(new selectOption('Gold', 'Gold'));
		objSkillsCtrl.list_MonthsPicklist.add(new selectOption('April', 'April'));
		objSkillsCtrl.list_YearsPicklist.add(new selectOption('2022', '2022'));
		objSkillsCtrl.list_ManageBOWrappers[0].objBO.Max_BO__c = 10;
		objSkillsCtrl.SaveSkill();

		PageReference objPage = Page.AddSkillsForUserRolePage;
		Test.setCurrentPageReference(objPage);
		objPage.getParameters().put('id', objUserRole.Id);
		objSkillsCtrl.intDeleteIndx = 0;
		objSkillsCtrl.deleteBOAllocation();
		objSkillsCtrl.SaveSkill();
		Test.stopTest();
		List<Benefit_Order_Allocation__c> objBO = [SELECT Id, User__c FROM Benefit_Order_Allocation__c];
		System.assert(objBO.size() == 0);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Missing fields for Implementation Advocate
	 * @param        null
	 * @return       null
	 **/
	@isTest
	public static void missingIATestCase() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.id);
		AddSkillsForUserRoleCtrl objSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objSkillsCtrl.strRoleData = 'Implementation Advocate';
		objSkillsCtrl.ShowTeamSkillType();
		objSkillsCtrl.strSkillType = 'Core';
		objSkillsCtrl.DisplayCriteriaSection();
		objSkillsCtrl.list_SelectedOrderType = new List<selectOption>();
		objSkillsCtrl.list_SelectedState = new List<selectOption>();
		objSkillsCtrl.list_SelectedPartner = new List<selectOption>();
		objSkillsCtrl.SaveSkill();
		Test.stopTest();

		ApexPages.Message[] objPageMessages = ApexPages.getMessages();
		System.assert(objPageMessages.size() > 0);
		Boolean blnMessageFound = false;
		for (ApexPages.Message objMessage : objPageMessages) {
			if (objMessage.getSummary() == 'Required Fields(Order Type, State, Partner Tier)' && objMessage.getSeverity() == ApexPages.Severity.INFO) {
				blnMessageFound = true;
			}
		}
		System.assert(blnMessageFound, 'Required Fields(Order Type, State, Partner Tier) should be displayed');
	}


	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Missing fields for Payroll Transfer Facilitator
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void missingPTFacTestCase() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objAddSkillsCtrl.strRoleData = 'Payroll Transfer Facilitator';
		objAddSkillsCtrl.ShowTeamSkillType();
		objAddSkillsCtrl.SaveSkill();
		Test.stopTest();
		ApexPages.Message[] objPageMessages = ApexPages.getMessages();
		System.assert(objPageMessages.size() > 0);
		Boolean blnMessageFound = false;
		for (ApexPages.Message objMessage : objPageMessages) {
			if (
				objMessage.getSummary() == 'Required Fields(Payroll transfer Skills, Complexity Score, Previous Payroll Provider Type, Payroll Sales Team)' &&
				objMessage.getSeverity() == ApexPages.Severity.INFO
			) {
				blnMessageFound = true;
			}
		}

		System.assert(blnMessageFound);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create the user skills for Benefit Transfer Advocate and then change to Advising
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void positiveBTAdvocateTestCase() {
		Test.startTest();
		User_Role__c objUserRole = [SELECT Id FROM User_Role__c LIMIT 1];
		PageReference objPageRef = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.id);
		AddSkillsForUserRoleCtrl objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();
		objAddSkillsCtrl.strRoleData = 'Benefit Transfer';
		objAddSkillsCtrl.ShowTeamSkillType();
		objAddSkillsCtrl.selectRole();
		objAddSkillsCtrl.map_BTDefineSkills.put('Advocate', true);
		objAddSkillsCtrl.ManageBOAllocation();
		objAddSkillsCtrl.blnIsTada = true;
		objAddSkillsCtrl.list_ManageBOWrappers[0].objBO.Max_BO__c = 10;
		objAddSkillsCtrl.SaveSkill();

		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE User_Role__c = :objUserRole.Id AND Skill_Role_Name__c LIKE 'Benefit Transfer%'] > 0, true);

		PageReference pageRef1 = Page.AddSkillsForUserRolePage;
		test.setCurrentPageReference(objPageRef);
		objPageRef.getParameters().put('id', objUserRole.Id);
		objAddSkillsCtrl = new AddSkillsForUserRoleCtrl();

		objAddSkillsCtrl.strRoleData = FWManageRoleUtil.TEAM_ADVISING;
		objAddSkillsCtrl.ShowTeamSkillType();

		objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).blnSelected = true;
		objAddSkillsCtrl.strOrderAllocRoleType = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER;
		objAddSkillsCtrl.onRoleSelect();
		if (objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedCoverageType != null) {
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedCoverageType.add(new SelectOption('Medical', 'Medical'));
			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedCoverageType.add(new SelectOption('Life', 'Life'));

			objAddSkillsCtrl.map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_BENEFITS_DESIGNER).list_SelectedState.add(new SelectOption('Arizona', 'Arizona'));
		}

		objAddSkillsCtrl.SaveSkill();
		Test.stopTest();
		System.assertEquals([SELECT COUNT() FROM User_Skill__c WHERE User_Role__c = :objUserRole.Id AND Skill_Role_Name__c = :FWManageRoleUtil.ROLE_BENEFITS_DESIGNER] > 0, true);
	}
}