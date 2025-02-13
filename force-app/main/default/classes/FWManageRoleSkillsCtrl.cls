/***
 * @name         FWManageRoleSkillsCtrl
 * @author       Anand Singh
 * @date         06/01/2020
 * @description  Build Logic to Store all filter criteria by team wise and role wise
 * @test class   FWManageRoleSkillsCtrlTest
 * @Modified By  Bhagat Singh 7 Aug 2020
 * @revisions    Date ------------ Name ------------ Comments
 ***/
public class FWManageRoleSkillsCtrl {
	//Skill Type pick-list,eg: Flex/Core/Training
	public List<System.SelectOption> list_SkillType { get; set; }
	//Region POD object
	public Region_POD__c objRegionPOD { get; set; }
	//Which skill type, user have selected on UI.
	public string strSkillType { get; set; }
	//Map of active states getting from State_Name_to_abbreviations_Mapping__c custom setting.
	public static final Map<String, String> map_ActiveStates = UtilitiesFactory.getActiveState();
	//Set of Carrier name getting from Flexible_Workforce_Carriers__c custom setting.
	public Set<String> set_CarrierName = new Set<String>();
	public boolean blnShowStateSection { get; set; }
	public boolean blnShowRegionSection { get; set; }
	public boolean blnShowOrderTypeSection { get; set; }
	public boolean blnShowSPartnerSection { get; set; }
	public boolean blnShowTADASection { get; set; }
	public boolean blnShowCarrierPODSection { get; set; }
	//Action button label save/update
	public string strButtonLabel { get; set; }
	//Set of Skills__c Ids related to user edited Role__c.
	private Set<string> set_ExistingSkillId;

	public List<System.SelectOption> list_SelectedCoverageTypes = new List<System.SelectOption>();

	//variables to show, State multi-select pick-list on UI.
	public List<System.SelectOption> list_UnSelectedState { get; set; }
	public List<System.SelectOption> list_SelectedState { get; set; }
	//variables to show, OrderType multi-select pick-list on UI.
	public List<System.SelectOption> list_UnSelectedOrderType { get; set; }
	public List<System.SelectOption> list_SelectedOrderType { get; set; }
	//variables to show, Partner multi-select pick-list on UI.
	public List<System.SelectOption> list_UnSelectedPartner { get; set; }
	public List<System.SelectOption> list_SelectedPartner { get; set; }
	//Is TADA selected on UI.
	public boolean blnTADA { get; set; }
	//which Role__c id user have edited
	public string strRoleId { get; set; }
	//Get configuration setting from Skill_Criteria_Setup__c custom setting.
	public map<string, Skill_Criteria_Setup__c> map_SkillSetupCriteria;
	//Section header name : eg : Manage Region/Manage Carrier
	public string strTitle { get; set; }
	//List to maintain existing and newly created Region PODs.
	public List<RegionPODWrapper> list_RegionPODWrapper { get; set; }

	//get the List of assigned Carriers-POD
	public List<CarrierWrapper> list_SelectedAssignedCarrier { get; set; }
	//set of Select Carriers from UI.
	public Set<String> set_CheckedCarrier = new Set<String>();
	public List<Carrier__c> list_CombinationCarriers = new List<Carrier__c>();
	//Which role user have selected from UI.
	public string strRoleName { get; set; }
	//Login user is Admin.
	public boolean blnIsAdmin { get; set; }
	//Show list on existing role on UI.
	public List<System.SelectOption> list_ExistingRole { get; set; }
	//Show dynamic created role name on UI.
	public boolean blnShowNameRoleName { get; set; }
	//Map to a input field, so user can enter pod name from UI.
	public string strRegionName { get; set; }
	public boolean blnCarierPODAvailable { get; set; }
	public set<string> set_SelectedCarrierPOD { get; set; }
	public boolean blnShowSecondBlock { get; set; }
	private Set<string> set_SelectedStateTemp;
	private set<string> set_AllState;

	/**DS[21/7/2020] For comparing the previous values with new saving values----Start*/
	public Set<string> set_SelectedState = new Set<string>();
	public Set<string> set_SelectedOrderType = new Set<string>();
	public Set<string> set_SelectedPartner = new Set<string>();
	public Boolean blnTADATemp = false;
	public Set<Id> set_CarrierPOD = new Set<Id>();
	public Boolean blnShowSaveSkillButton { get; set; }
	public static String strStateMissing = 'Please select state.';

	//Max DML Row Limit.
	public Integer INT_MAX_DML_ROWS = 9000;
	/**DS[21/7/2020] For comparing the previous values with new saving values ----End*/

	//Constructor
	public FWManageRoleSkillsCtrl(ApexPages.StandardController sc) {
		list_RegionPODWrapper = new List<RegionPODWrapper>();
		set_SelectedCarrierPOD = new Set<String>();
		set_CarrierPOD = new Set<Id>();
		string strResult = Apexpages.currentpage().getparameters().get('res');
		/*if(strResult=='success'){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Successfully saved');
            ApexPages.addMessage(myMsg);
       }*/
		blnIsAdmin = UtilitiesFactory.CheckLoggedInUser();
		strRoleId = 'create';
		blnCarierPODAvailable = false;
		strButtonLabel = 'Save & Add More';
		strRoleName = null;
		objRegionPOD = new Region_POD__c();
		ResetSection();
		RetriveAllSetupCriteria();
		strRegionName = null;
		blnShowSaveSkillButton = false;
	}

	//Getting values from custom setting(Skill_Criteria_Setup__c) and create a map of user role and skill.
	private void RetriveAllSetupCriteria() {
		map_SkillSetupCriteria = new Map<string, Skill_Criteria_Setup__c>();
		List<Skill_Criteria_Setup__c> list_RoleSetup = Skill_Criteria_Setup__c.getall().values();
		if (list_RoleSetup != null && list_RoleSetup.size() > 0) {
			for (Skill_Criteria_Setup__c srs : list_RoleSetup) {
				map_SkillSetupCriteria.put(srs.Team__c + '-' + srs.Skill_Type__c, srs);
			}
		}
	}

	//Fetch all the existing Role based on selected Team and Skill Type.
	private void RetriveRoleData() {
		list_ExistingRole = new List<System.SelectOption>();
		blnShowNameRoleName = true;
		for (Role__c objRoleTemp : [SELECT id, name, Skill_Type__c, Team__c FROM Role__c WHERE Team__c = :objRegionPOD.Team__c AND Skill_Type__c = :strSkillType ORDER BY Name]) {
			list_ExistingRole.add(new SelectOption(objRoleTemp.Id, objRoleTemp.Name));
			//In case of Implementation Advocate if record already exist then no need to give option to create new
			if (objRoleTemp.Skill_Type__c == 'Core' && (objRoleTemp.Team__c == 'Implementation Advocate')) {
				blnShowNameRoleName = false;
			}
		}
		if (blnShowNameRoleName == true) {
			list_ExistingRole.add(new SelectOption('create', 'Create New'));
		}
	}

	//If user change, Role and Skill type on UI then we will rest all this boolean flags and calculate again, which section should be visible on UI.
	private void ResetSection() {
		blnShowRegionSection = false;
		blnShowStateSection = false;
		blnShowCarrierPODSection = false;
		blnShowOrderTypeSection = false;
		blnShowSPartnerSection = false;
		blnShowTADASection = false;
		strRegionName = null;
		blnShowSecondBlock = false;
	}

	//When we view/edit exiting role(Role__c) then this method fetch, selected Role related information like : state, order type, Partner.
	private void PopulateData() {
		blnTADA = false;
		//get Saved Skill In case of Edit mode
		List<Skill__c> list_SkillTemp = new List<Skill__c>();
		/**DS[21/7/2020] For comparing the previous values with new saving values ----Start*/
		set_SelectedState = new Set<string>();
		set_SelectedOrderType = new Set<string>();
		set_SelectedPartner = new Set<string>();
		
		//Populate State
		list_UnSelectedState = new List<System.SelectOption>();
		list_SelectedState = new List<System.SelectOption>();

		if (blnShowStateSection == true) {
			if (map_ActiveStates != null && map_ActiveStates.size() > 0) {
				for (string str : map_ActiveStates.keySet()) {
					string strStateFullName = map_ActiveStates.get(str);
					//In case of Core show all as prefilled
					list_SelectedState.add(new SelectOption(strStateFullName, strStateFullName + '(' + str + ')'));
				}
			}
		}
		//In case Carrier POD and region then populate state from carrier Object and State Custom Settings
		if (blnShowCarrierPODSection == true || blnShowRegionSection == true) {
			ResetStatePickVal();
		}

		//get Order Type
		list_UnSelectedOrderType = new List<System.SelectOption>();
		list_SelectedOrderType = new List<System.SelectOption>();

		list_SelectedOrderType = UtilitiesFactory.getPickListValues('Skill__c', 'Order_Type__c', set_SelectedOrderType);

		//get partner
		list_UnSelectedPartner = new List<System.SelectOption>();
		list_SelectedPartner = new List<System.SelectOption>();
		//In case of Core show all as prefilled
		list_SelectedPartner = UtilitiesFactory.getPickListValues('Skill__c', 'Partner__c', null);
		blnTADA = true;

		list_SelectedCoverageTypes = UtilitiesFactory.getPickListValues('Skill__c', 'Coverage_Type__c', null);
	}

	//This method calculate state list, which are not available in existing POD.
	private void ResetStatePickVal() {
		list_UnSelectedState = new List<System.SelectOption>();
		list_SelectedState = new List<System.SelectOption>();
		Set<String> set_UniqueStateName = new Set<String>();
		set_SelectedStateTemp = new Set<String>();

		//get All selected state from region POD for team and skill type if skill type is core
		if (strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
			for (Region_POD_mapping__c objRegionPODMapping : [
				SELECT Id, State__c
				FROM Region_POD_mapping__c
				WHERE
					Region_POD__c != NULL
					AND Region_POD__r.Type__c != NULL
					AND Region_POD__r.Team__c != NULL
					AND Region_POD__r.Skill_Type__c != NULL
					AND Region_POD__r.Type__c = :FWManageRoleUtil.TYPE_REGION
					AND Region_POD__r.Skill_Type__c = :strSkillType
					AND Region_POD__r.Team__c = :objRegionPOD.Team__c
			]) {
				set_SelectedStateTemp.add(objRegionPODMapping.State__c);
			}
		}

		if (set_CarrierName != null && set_CarrierName.size() > 0) {
			set_UniqueStateName = getUniqueStateName();

			if (!FWManageRoleUtil.set_AdvisingRoles.isEmpty() && FWManageRoleUtil.set_AdvisingRoles.contains(objRegionPOD.Team__c)) {
				list_UnSelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), new Set<String>(), set_UniqueStateName);
			} else {
				//get list of all state
				list_UnSelectedState = getSelectOptionValues(map_ActiveStates, set_SelectedStateTemp, new Set<String>(), set_UniqueStateName);
			}
		}
	}

	//This method return list of state that are not assigned in any Region and POD
	public List<System.SelectOption> getSelectOptionValues(Map<String, String> map_ActiveStates, Set<String> strInvalidValues, Set<String> set_SelectedStates, Set<String> set_UniqueStateName) {
		List<System.SelectOption> list_PicklistValues = new List<System.SelectOption>();
		set_AllState = new Set<string>();
		for (String strStateAbb : map_ActiveStates.keySet()) {
			String strStateName = map_ActiveStates.get(strStateAbb);
			set_AllState.add(strStateName);
			if (!set_UniqueStateName.isEmpty() && !set_UniqueStateName.contains(strStateAbb)) {
				continue;
			}
			if (!strInvalidValues.isEmpty() && (strInvalidValues.contains(strStateAbb) || strInvalidValues.contains(strStateName))) {
				continue;
			}

			if (set_SelectedStates.isEmpty() || set_SelectedStates.contains(strStateAbb) || set_SelectedStates.contains(strStateName)) {
				string strVal = null;
				//In case of carrier POD
				if (blnShowCarrierPODSection == true) {
					strVal = strStateAbb;
				}
				//In case of Region
				if (blnShowRegionSection == true) {
					strVal = strStateName;
				}
				SelectOption so = new selectOption(strVal, strStateName + ' (' + strStateAbb + ')');
				list_PicklistValues.add(so);
			}
		}
		return list_PicklistValues;
	}

	//On change of Team from UI this method will execute and populate it's related skill type and Carrier list.
	public PageReference ShowTeamSkillType() {
		set_SelectedCarrierPOD.clear();
		strSkillType = null;
		ResetSection();
		list_SkillType = new List<System.SelectOption>();
		strButtonLabel = 'Save & Add More';
		list_SkillType.add(new SelectOption('', '--None--'));
		if (objRegionPOD.Team__c != null) {
			for (Skill_Criteria_Setup__c sct : [SELECT id, Name, Team__c, Filter_Criteria__c, Skill_Type__c FROM Skill_Criteria_Setup__c WHERE Team__c = :objRegionPOD.Team__c]) {
				if (objRegionPOD.Team__c == 'Implementation Advocate' && sct.Skill_Type__c != 'Core') {
					//Do not add value in picklist.
				} else {
					list_SkillType.add(new SelectOption(sct.Skill_Type__c, sct.Skill_Type__c));
				}
			}
			
			set_CarrierName = UtilitiesFactory.getCarrierNames(null);

			if (Test.isRunningTest()) {
				set_CarrierName = UtilitiesFactory.getCarrierNames(null);
			}

			//In case of Implementation Advocate only one skill type, so no need to select skill type aagin
			if (objRegionPOD.Team__c != null && !FWManageRoleUtil.set_RoleWithOnlySkillCore.isEmpty() && FWManageRoleUtil.set_RoleWithOnlySkillCore.contains(objRegionPOD.Team__c)) {
				strSkillType = FWManageRoleUtil.SKILL_TYPE_CORE;
				DisplayCriteriaSection();
			}

			//If Skill type is core then always be only one record will be saved
			RetriveSelecteCoreId();
			blnShowSaveSkillButton = showSaveSkillButton();
		}
		return null;
	}

	//If Selected team is Implementation Advocate and Skill type is core then There should be only one Role exist.
	// This method fetch existing Role.
	private void RetriveSelecteCoreId() {
		if (strSkillType == 'Core' && (objRegionPOD.Team__c == 'Implementation Advocate')) {
			set_ExistingSkillId = new Set<string>();
			set_SelectedCarrierPOD = new Set<String>();
			List<Role__c> list_Role = [
				SELECT id, name, Skill_Type__c, Team__c, (SELECT id, name, Region_POD__c, Role__c, TADA__c, Partner__c, State_Group__c, Order_Type__c FROM Skills__r)
				FROM Role__c
				WHERE Team__c = :objRegionPOD.Team__c AND Skill_Type__c = 'Core'
				ORDER BY Name
				LIMIT 1
			];
			Role__c objRole = new Role__c();
			if (list_Role.size() > 0) {
				strRoleId = list_Role[0].Id;
				objRole = list_Role[0];
				List<Skill__c> list_skills = [
					SELECT id, name, Region_POD__c, Role__c, TADA__c, Partner__c, State_Group__c, Order_Type__c
					FROM Skill__c
					WHERE Role__c = :objRole.Id
					ORDER BY Name
				];
				if (list_skills != null && list_skills.size() > 0) {
					for (Skill__c skl : list_skills) {
						set_ExistingSkillId.add(skl.id);
						if (String.isNotBlank(skl.Region_POD__c)) {
							set_SelectedCarrierPOD.add(skl.Region_POD__c);
						}
					}
				}
			}
			//}
		}
	}

	//From UI, Once skill or team will changed then clear the list.
	public PageReference ChangeSkillType() {
		clearList();
		set_SelectedCarrierPOD.clear();
		Role__c objRole = new Role__c();
		strRoleId = 'create';
		//If Skill type is core then always be only one record will be saved
		RetriveSelecteCoreId();
		blnShowSaveSkillButton = showSaveSkillButton();
		return DisplayCriteriaSection();
	}

	//On the basis of Team and skills, this method calculate, which section would be visible on UI
	public PageReference DisplayCriteriaSection() {
		strTitle = null;
		strButtonLabel = 'Save & Add More';
		ResetSection();
		strRegionName = null;
		if (string.isNotBlank(strSkillType)) {
			RetriveRoleData();
			string strkey = objRegionPOD.Team__c + '-' + strSkillType;
			string strCriteria = map_SkillSetupCriteria.get(strkey).Filter_Criteria__c;

			if (strCriteria.indexOf('Region') > -1) {
				blnShowRegionSection = true;
				strTitle = 'Manage Region';
			}
			if (strCriteria.indexOf('State') > -1) {
				blnShowStateSection = true;
			}

			if (strCriteria.indexOf('Carrier POD') > -1) {
				blnShowCarrierPODSection = true;
				strTitle = 'Manage Carrier';
			}
			if (strCriteria.indexOf('Order Type') > -1) {
				blnShowOrderTypeSection = true;
				blnShowSecondBlock = true;
			}
			if (strCriteria.indexOf('Partner') > -1) {
				blnShowSPartnerSection = true;
				blnShowSecondBlock = true;
			}
			if (strCriteria.indexOf('Tada') > -1) {
				blnShowTADASection = true;
				blnShowSecondBlock = true;
			}
			//Show region/ Carrier POD data
			if (blnShowRegionSection || blnShowCarrierPODSection) {
				RetriveRegionPOD(null);
			}
			//Show carrier list if Carrier POD section true
			if (blnShowCarrierPODSection == true) {
				getCarrierNames();
			}
			populateRoleName();
			//In case of Training skill Type for show filter section
			if (strSkillType == 'Training') {
				blnCarierPODAvailable = true;
			}
		}
		PopulateData();
		return null;
	}

	//Return list of carrier list on UI.
	private void getCarrierNames() {
		list_SelectedAssignedCarrier = new List<CarrierWrapper>();
		if (!set_CarrierName.isEmpty()) {
			for (String strName : set_CarrierName) {
				list_SelectedAssignedCarrier.add(new CarrierWrapper(strName, false));
			}
		}
	}

	//This method dynamically create new role name and display on UI.
	private void populateRoleName() {
		List<Role__c> list_Role = [SELECT Id FROM Role__c WHERE Team__c = :objRegionPOD.Team__c AND Skill_Type__c = :strSkillType];
		strRoleName = objRegionPOD.Team__c + ' ' + strSkillType + ' Role 1';
		if (list_Role != null && list_Role.size() > 0) {
			integer NoofRole = list_Role.size() + 1;
			strRoleName = objRegionPOD.Team__c + ' ' + strSkillType + ' Role ' + NoofRole;
		}
		//In case of Core role for any team there will be always one role set
		if (strSkillType == 'Core') {
			strRoleName = objRegionPOD.Team__c;
		}
	}

	//On click of "Save Skill" button this method will execute.
	public PageReference SaveSkill() {
		Savepoint sp = Database.setSavepoint();
		try {
			Boolean blnIsRoleCreated = false;
			List<Skill__c> list_Skill = new List<Skill__c>();
			string strTeamName = objRegionPOD.Team__c;
			List<Role__c> list_Role = [SELECT id, name, Skill_Type__c, Team__c FROM Role__c WHERE id = :strRoleId ORDER BY Name LIMIT 1];
			Role__c objRole = new Role__c();
			if (list_Role != null && list_Role.size() > 0) {
				objRole = list_Role[0];
			}
			if (objRole != null && objRole.id == null) {
				String RoleName = strRoleName;

				//Create Role
				objRole = new Role__c();
				objRole.Name = RoleName;
				objRole.Team__c = strTeamName;
				objRole.Skill_Type__c = strSkillType;
				insert objRole;
				list_ExistingRole.add(new SelectOption(objRole.Id, objRole.Name));
				strRoleId = objRole.Id;
				blnIsRoleCreated = true;
			} else {
				UtilitiesFactory.deleteRecords(set_ExistingSkillId);
			}
			//Create Skill
			
			if (strTeamName == 'Implementation Advocate') {
				if (list_SelectedState.isEmpty()) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, strStateMissing));
					return null;
				}

				//Core
				if (strSkillType == 'Core') {
					list_Skill.addAll(InsertAdvocateCoreSkill(objRole));
				}
			}

			if (strTeamName == FWManageRoleUtil.ROLE_ADVISOR) {
				if (strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
					list_Skill.addAll(InsertAdvisorAndRenewalSpecialistCoreSkill(objRole));
				}
			}

			if (strTeamName == FWManageRoleUtil.ROLE_BENEFITS_DESIGNER) {
				if (strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
					list_Skill.addAll(InsertBenefitDesginerCoreSkill(objRole));
				}
			}

			if (strTeamName == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST) {
				if (strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
					list_Skill.addAll(InsertAdvisorAndRenewalSpecialistCoreSkill(objRole));
				}
			}

			if (!list_Skill.isEmpty()) {
				Integer intTotalDMLRows = Limits.getDMLRows() + list_Skill.size();
				if (intTotalDMLRows < INT_MAX_DML_ROWS || Test.isRunningTest()) {
					insert list_Skill;
				} else {
					ID jobID = System.enqueueJob(new BatchDML(BatchDML.Operation.INS, list_Skill, true));
				}
			}
		} catch (Exception ex) {
			Database.RollBack(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Successfully saved'));

		return null;
	}

	
	//Create Advocate Core Skill
	private List<Skill__c> InsertAdvocateCoreSkill(Role__c objTempRole) {
		List<Skill__c> list_SkillTemp = new List<Skill__c>();
		//Iterate on Order type
		if (list_SelectedOrderType.size() > 0 && list_SelectedPartner.size() > 0 && list_SelectedState.size() > 0) {
			for (SelectOption sOptionOrderType : list_SelectedOrderType) {
					//iterate on Partner
					for (SelectOption sOptionPartner : list_SelectedPartner) {
						//Iterate on State , Region will get defined while manage skill assignment
						for (SelectOption sOptionState : list_SelectedState) {
							String strState = sOptionState.getValue();
							String strOrderType = sOptionOrderType.getValue();
							String strPartner = sOptionPartner.getValue();

							Skill__c objSkill = BindSkill(objTempRole.Id, null, strState, null, strOrderType, strPartner, false, false, false, null);
							list_SkillTemp.add(objSkill);

							Skill__c objBigDeskSkill = BindSkill(objTempRole.Id, null, strState, null, strOrderType, strPartner, false, true, false, null);
							list_SkillTemp.add(objBigDeskSkill);

							list_SkillTemp.add(BindSkill(objTempRole.Id, null, strState, null, strOrderType, strPartner, false, false, true, null));

							list_SkillTemp.add(BindSkill(objTempRole.Id, null, strState, null, strOrderType, strPartner, false, true, true, null));
						}
					}
			}
		}
		return list_SkillTemp;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Create Advisor and Renewal Specialist skills
	 * @Parm        : objTempRole - Role Object
	 *                blnBenefitsBigDesk - Boolean for Benefits Big Desk
	 * @Return      : list of Advisor skills
	 **/
	private List<Skill__c> InsertAdvisorAndRenewalSpecialistCoreSkill(Role__c objTempRole) {
		List<Skill__c> list_TempSkills = new List<Skill__c>();

		if (list_UnSelectedState.size() > 0) {
			for (SelectOption sOptionState : list_UnSelectedState) {
				String strState = sOptionState.getValue();

				Skill__c objSkill = BindSkill(objTempRole.Id, null, strState, null, null, null, false, false, false, null);

				list_TempSkills.add(objSkill);

				Skill__c objSkillBigDesk = BindSkill(objTempRole.Id, null, strState, null, null, null, false, true, false, null);

				list_TempSkills.add(objSkillBigDesk);
			}
		}

		return list_TempSkills;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Create Benefit Desginer Specialist skills
	 * @Parm        : objTempRole - Role Object
	 *                blnBenefitsBigDesk - Boolean for Benefits Big Desk
	 * @Return      : list of Advisor skills
	 **/
	private List<Skill__c> InsertBenefitDesginerCoreSkill(Role__c objTempRole) {
		List<Skill__c> list_TempSkills = new List<Skill__c>();

		if (list_UnSelectedState.size() > 0) {
			for (SelectOption sOptionState : list_UnSelectedState) {
				for (SelectOption sOptionCoverageType : list_SelectedCoverageTypes) {
					String strState = sOptionState.getValue();
					String strCoverageType = sOptionCoverageType.getValue();

					Skill__c objSkill = BindSkill(objTempRole.Id, null, strState, null, null, null, false, false, false, strCoverageType);

					list_TempSkills.add(objSkill);
				}
			}
		}

		return list_TempSkills;
	}

	//************************Insert Skill method : Start ***************************
	//*******************************************************************************
	/**
	 * @Author      : Deepika Saini
	 * @Description : Populate the values in Skills Object
	 * @Parm        : strRoleId - Id of Role, strState - value of State field
	 *                strRegion - value of Region field, strCarrierPOD - value of CarrierPOD field
	 *                strOrderType - value of OrderType field,
	 *                strPartner - value of Partner field, blnIsTADA - Boolean value of TADA
	 *                strCoverageType - value of CoverageType field
	 * @Return      : Object of Skill
	 **/
	private Skill__c BindSkill(
		String strRoleId,
		String strRegion,
		String strState,
		String strCarrierPOD,
		String strOrderType,
		String strPartner,
		boolean blnIsTADA,
		Boolean blnBenefitsBigDesk,
		Boolean blnMaestro,
		String strCoverageType
	) {
		//Both will go in one lookup and at a time only one have value
		String strRegionPOD = strRegion;

		if (strRegionPOD == null) {
			strRegionPOD = strCarrierPOD;
		}

		Skill__c objTempSkill = new Skill__c();
		objTempSkill.Role__c = strRoleId;
		objTempSkill.Region_POD__c = strRegionPOD;
		objTempSkill.State_Group__c = strState;
		objTempSkill.Order_Type__c = strOrderType;
		objTempSkill.Partner__c = strPartner;
		objTempSkill.TADA__c = blnIsTADA;
		objTempSkill.Benefits_Big_Desk__c = blnBenefitsBigDesk;
		objTempSkill.Maestro__c = blnMaestro;
		objTempSkill.Coverage_Type__c = strCoverageType;
		return objTempSkill;
	}

	//This method return set of unique state.
	private Set<String> getUniqueStateName() {
		Set<String> set_UniqueStateName = new Set<String>();
		if (!set_CarrierName.isEmpty()) {
			for (Carrier__c objCO : [SELECT State__c FROM Carrier__c WHERE Name IN :set_CarrierName AND State__c != NULL]) {
				set_UniqueStateName.addAll(objCO.State__c.split(';'));
			}
		}
		return set_UniqueStateName;
	}

	//Fetch Region POD List, based on selected Team and Skill Type
	private void RetriveRegionPOD(string savedId) {
		blnCarierPODAvailable = false;
		list_RegionPODWrapper = new List<RegionPODWrapper>();
		//In case of Edit populate only selected redgion pod in case of carrier POD section
		string strTeamTemp = objRegionPOD.Team__c;
		string strQuery = 'SELECT id, Name,Skill_Type__c,Team__c,Type__c,(SELECT id,name,Region_POD__c,Role__c, TADA__c,Partner__c,State_Group__c,Order_Type__c FROM Skills__r) FROM Region_POD__c';
		strQuery = strQuery + ' WHERE name!=null AND Team__c=:strTeamTemp AND Skill_Type__c=:strSkillType ';

		if (set_SelectedCarrierPOD.size() > 0 && blnShowCarrierPODSection == true) {
			strQuery = strQuery + ' AND id IN : set_SelectedCarrierPOD';
		}
		strQuery = strQuery + ' order by CreatedDate desc';

		boolean blnIsSkillExist = false;
		List<Role__c> list_Role = [SELECT id, name, Skill_Type__c, Team__c FROM Role__c WHERE id = :strRoleId WITH USER_MODE ORDER BY Name LIMIT 1];
		for (Region_POD__c rp : Database.query(strQuery)) {
			blnIsSkillExist = false;
			//Show only those who do not associates with any skills
			//In Case of edit role show that region pod which already been associated with skill
			Role__c objRole = new Role__c();
			if (list_Role != null && list_Role.size() > 0) {
				objRole = list_Role[0];
			}
			if (objRole != null && ((objRole.id == null && rp.Skills__r.size() == 0) || objRole.id != null)) {
				if (rp.Skills__r.size() > 0) {
					blnIsSkillExist = true;
				}
				blnCarierPODAvailable = true;
				list_RegionPODWrapper.add(new RegionPODWrapper(rp, blnIsSkillExist));
				/**DS[22/7/2020] save the already created CarrierPOD */
				if (savedId == null && blnShowCarrierPODSection) {
					set_CarrierPOD.add(rp.id);
				}
			}
		}
	}

	//on change of team this method will call.
	public void clearList() {
		set_CheckedCarrier = new Set<string>();
		objRegionPOD.Id = null;
		strRegionName = null;
		list_CombinationCarriers = new List<Carrier__c>();
		list_SelectedState = new List<System.SelectOption>();
	}

	//On click on cancel button this method will called.
	public void cancelSelectedRegionPOD() {
		ChangeSkillType();
	}

	//On click on update button this method will called.
	public PageReference updateRegionPOD() {
		try {
			//In case of Carrier Section when user click on edit then table will get hide and filter section get visible
			if (blnShowCarrierPODSection) {
				blnCarierPODAvailable = false;
			}

			objRegionPOD = new Region_POD__c();
			list_UnSelectedState = new List<System.SelectOption>();
			list_SelectedState = new List<System.SelectOption>();

			String strRecId = ApexPages.currentPage().getParameters().get('Id');

			List<Region_POD__c> list_RegionPOD = [
				SELECT Id, Name, Type__c, Team__c, (SELECT Id, State__c, Carrier__c, Carrier__r.Name, Carrier__r.State__c, Carrier__r.Carrier_Unique_Name__c FROM Region_POD_mapping__r)
				FROM Region_POD__c
				WHERE ID = :strRecId
				LIMIT 1
			];

			if (list_RegionPOD.size() > 0) {
				objRegionPOD = list_RegionPOD[0];
				strButtonLabel = 'Update';
				strRegionName = objRegionPOD.Name;
				List<Region_POD_mapping__c> list_RegionPODMapping = objRegionPOD.Region_POD_mapping__r;
				Set<String> set_RegionState = new Set<String>();
				Set<String> set_PODCarrier = new Set<String>();

				if (list_RegionPODMapping != null && !list_RegionPODMapping.isEmpty()) {
					set_SelectedStateTemp = new Set<String>();

					for (Region_POD_mapping__c objRegioPOdMap : list_RegionPODMapping) {
						if (FWManageRoleUtil.TYPE_REGION.equalsIgnoreCase(objRegionPOD.Type__c)) {
							set_RegionState.add(objRegioPOdMap.State__c);
						} else if (FWManageRoleUtil.TYPE_POD.equalsIgnoreCase(objRegionPOD.Type__c)) {
							set_RegionState.add(objRegioPOdMap.Carrier__r.State__c);
							String strCarrierNameOrUniqueName = objRegioPOdMap.Carrier__r.Carrier_Unique_Name__c;

							

							if (String.isNotBlank(strCarrierNameOrUniqueName)) {
								set_PODCarrier.add(strCarrierNameOrUniqueName);
							}
						}
					}

					if (strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE && !FWManageRoleUtil.set_AdvisingRoles.isEmpty() && !FWManageRoleUtil.set_AdvisingRoles.contains(objRegionPOD.Team__c)) {
						//get All selected State from all region of selected team so that we should exclude from unselected list
						//get All selected state from region POD for team and skill type
						for (Region_POD_mapping__c objRegionPODMapping : [
							SELECT Id, State__c
							FROM Region_POD_mapping__c
							WHERE Region_POD__r.Type__c = :FWManageRoleUtil.TYPE_REGION AND Region_POD__r.Skill_Type__c = :strSkillType AND Region_POD__r.Team__c = :objRegionPOD.Team__c
						]) {
							set_SelectedStateTemp.add(objRegionPODMapping.State__c);
						}
					}

					set_SelectedStateTemp.addAll(set_RegionState);

					if (!set_RegionState.isEmpty() && !map_ActiveStates.isEmpty()) {
						Set<String> set_UniqueStateName = new Set<String>();

						if ('POD'.equalsIgnoreCase(objRegionPOD.Type__c) && !set_CarrierName.isEmpty()) {
							set_UniqueStateName = getUniqueStateName();
						}

						list_UnSelectedState = getSelectOptionValues(map_ActiveStates, set_SelectedStateTemp, new Set<String>(), set_UniqueStateName);

						list_SelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), set_RegionState, set_UniqueStateName);
					}

					if (set_PODCarrier != null && set_PODCarrier.size() > 0) {
						displaySelectedCarrier(set_PODCarrier);
					}
				}
			}
		} catch (Exception objEx) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objEx.getMessage()));
			return null;
		}

		return null;
	}

	//when edit any existing POD then this method will execute.
	//This method show the previous POD selected by user.
	private void displaySelectedCarrier(Set<String> set_PODCarrier) {
		if (!set_PODCarrier.isEmpty()) {
			for (CarrierWrapper objCarrierWrapper : list_SelectedAssignedCarrier) {
				if (set_PODCarrier.contains(objCarrierWrapper.strCarrName)) {
					objCarrierWrapper.blnIsChecked = true;
				} else {
					objCarrierWrapper.blnIsChecked = false;
				}
			}
		}
	}

	//If skill will update then it will also update skills on User Role.
	@future
	public static void deleteUserSkillFromUserRole(String strRecId, Set<String> set_RegionPODState, boolean isPODDeleted) {
		deleteUserSkillRelatedToRegionPOD(strRecId, set_RegionPODState, isPODDeleted);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Delete the User Skills related to Region POD
	 * @Parm        : strRecId - Id of Region POD
	 *                set_RegionPODState - Set of States in Region
	 *                isPODDeleted - Boolean value if POD is deleted or not
	 * @Return      : null
	 **/
	public static void deleteUserSkillRelatedToRegionPOD(String strRecId, Set<String> set_RegionPODState, boolean isPODDeleted) {
		if (String.isNotBlank(strRecId) && set_RegionPODState.size() > 0) {
			String strPODRegion = '';
			String strPODRegionKey = '';
			Set<Id> set_UserRoleId = new Set<Id>();
			String strRegionKeyName = '';

			List<Region_POD__c> list_RegionPOD = [SELECT Key__c FROM Region_POD__c WHERE Id = :strRecId];

			if (!list_RegionPOD.isEmpty()) {
				strRegionKeyName = '%' + list_RegionPOD[0].Key__c + ',%';
			}

			String strRegionId = '%' + strRecId + ',%';
			List<User_Role__c> lst_UserRole = new List<User_Role__c>();

			for (User_Role__c objUserRole : [
				SELECT Id, User_Skill_Type__c, Selected_Regions_Id__c, Selected_Region_Keys__c
				FROM User_Role__c
				WHERE (Selected_Region_Keys__c != NULL AND Selected_Region_Keys__c LIKE :strRegionKeyName) OR (Selected_Regions_Id__c != NULL AND Selected_Regions_Id__c LIKE :strRegionId)
			]) {
				set_UserRoleId.add(objUserRole.Id);

				//Update field on user role.
				if (objUserRole.Selected_Regions_Id__c != null) {
					strPODRegion = objUserRole.Selected_Regions_Id__c;
					strPODRegion = strPODRegion.replace(strRecId, '');
					objUserRole.Selected_Regions_Id__c = strPODRegion;
				}

				//Update Selected Region Key
				if (!list_RegionPOD.isEmpty()) {
					strPODRegionKey = list_RegionPOD[0].Key__c;
					strPODRegionKey = strPODRegionKey.replace(strRecId, '');
					objUserRole.Selected_Region_Keys__c = strPODRegionKey;
				}

				lst_UserRole.add(objUserRole);
			}

			if (set_UserRoleId.size() > 0) {
				//We are calling this method from future and batch class.
				//So we need to check database.deleteAsync will work for this use case.
				//delete [select id from User_Skill__c where User_Role__c IN :set_UserRoleId  and State_Group__c IN : set_RegionPODState];
				List<User_Skill__c> list_PreviousUserSkill = new List<User_Skill__c>();

				for (User_Skill__c objUserSkill : [
					SELECT Id
					FROM User_Skill__c
					WHERE User_Role__c != NULL AND User_Role__c IN :set_UserRoleId AND State_Group__c != NULL AND State_Group__c IN :set_RegionPODState
				]) {
					list_PreviousUserSkill.add(objUserSkill);
				}

				if (list_PreviousUserSkill != null && list_PreviousUserSkill.size() > 0) {
					delete list_PreviousUserSkill;
				}
			}

			if (lst_UserRole.size() > 0 && isPODDeleted == true) {
				//We are calling this method from future and batch class.
				//So we need to check database.updateAsync will work for this use case.
				update lst_UserRole;
			}
		}
	}

	//On click of delete Region POD this method will execute.
	public PageReference deleteRegionPOD() {
		Savepoint objSavePoint = Database.setSavepoint();
		try {
			string strRecId = ApexPages.currentPage().getParameters().get('Id');
			if (string.isNotBlank(strRecId)) {
				Id idPOD = Id.valueOf(strRecId);

				if (
					strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE &&
					(objRegionPOD.Team__c == FWManageRoleUtil.ROLE_IMPLEMENTATION ||
					(!FWManageRoleUtil.set_AdvisingRoles.isEmpty() && FWManageRoleUtil.set_AdvisingRoles.contains(objRegionPOD.Team__c)))
				) {
					Set<String> set_RegionPODState = new Set<String>();

					for (Region_POD_mapping__c objRegionPOD : [SELECT Id, State__c FROM Region_POD_mapping__c WHERE Region_POD__c = :strRecId]) {
						if (String.isNotBlank(objRegionPOD.State__c)) {
							set_RegionPODState.add(objRegionPOD.State__c);
						}
					}

					FWManageRoleSkillsCtrl.deleteUserSkillFromUserRole(strRecId, set_RegionPODState, true);
				}

				//delete [SELECT id FROM Region_POD__c WHERE id=:idPOD limit 1];
				List<Region_POD__c> list_ExistingRegionPOD = new List<Region_POD__c>();
				for (Region_POD__c objExistingPOD : [SELECT id FROM Region_POD__c WHERE id = :idPOD LIMIT 1]) {
					list_ExistingRegionPOD.add(objExistingPOD);
				}
				if (list_ExistingRegionPOD.size() > 0) {
					delete list_ExistingRegionPOD;
				}

				RetriveRegionPOD(null);
				resetPODRegionAfterSave();
				strButtonLabel = 'Save & Add More';
				ResetStatePickVal();
			}
		} catch (Exception ex) {
			Database.RollBack(objSavePoint);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
		return null;
	}

	//While creating new region POD this method will execute.
	public PageReference SaveRegionPODRecords() {
		String strMissingField = CheckReqiuredFields();
		Savepoint objSavePoint = Database.setSavepoint();

		if (blnShowRegionSection == true && string.isBlank(strRegionName)) {
			ApexPages.getMessages().clear();
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.error, 'Please enter Region Name');
			ApexPages.addMessage(myMsg);
			return null;
		}
		if (String.isNotBlank(strMissingField)) {
			ApexPages.getMessages().clear();
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, strMissingField);
			ApexPages.addMessage(myMsg);
		} else {
			if (list_CombinationCarriers.isEmpty() && blnShowCarrierPODSection == true) {
				ApexPages.getMessages().clear();
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'There are no carriers available for the selected states. Chose the right combination of states & carriers');
				ApexPages.addMessage(myMsg);
				return null;
			}

			if (objRegionPOD.Id == null) {
				string strType = 'Region';
				if (blnShowCarrierPODSection == true) {
					strType = 'POD';
				}
				objRegionPOD.Type__c = strType;
				objRegionPOD.Skill_Type__c = strSkillType;

				//In case of Manage carrier name would be automatically
				if (blnShowCarrierPODSection == true) {
					objRegionPOD.Name = objRegionPOD.Team__c + ' ' + strSkillType + ' Carrier ';
					List<Region_POD__c> list_RegionPOD = [SELECT id, Name FROM Region_POD__c WHERE Team__c = :objRegionPOD.Team__c AND Type__c = :strType AND Skill_Type__c = :strSkillType];
					if (!list_RegionPOD.isEmpty()) {
						integer intCount = list_RegionPOD.size() + 1;
						objRegionPOD.Name += ' ' + String.valueOf(intCount);
					} else {
						objRegionPOD.Name += ' 1';
					}
				}
			}

			try {
				//In case of Region user can change name
				if (blnShowRegionSection == true) {
					objRegionPOD.Name = strRegionName;
				}

				List<Region_POD__c> list_RegionPOD = new List<Region_POD__c>();
				list_RegionPOD.add(objRegionPOD);
				if (!list_RegionPOD.isEmpty()) {
					upsert list_RegionPOD;
				}

				if (objRegionPOD.Id != null) {
					set_SelectedCarrierPOD.add(objRegionPOD.Id);
				}

				List<Region_POD_mapping__c> list_SavedMapping = [SELECT ID, State__c FROM Region_POD_mapping__c WHERE Region_POD__c = :objRegionPOD.Id];
				//Delete existing Region POD mapping records and Insert new one.
				if (list_SavedMapping.size() > 0) {
					delete list_SavedMapping;

					if (
						strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE &&
						(objRegionPOD.Team__c == FWManageRoleUtil.ROLE_IMPLEMENTATION ||
						(!FWManageRoleUtil.set_AdvisingRoles.isEmpty() && FWManageRoleUtil.set_AdvisingRoles.contains(objRegionPOD.Team__c)))
					) {
						//Check selected state has been changed in Region POD.
						updateRegionPODonUserSkill(list_SavedMapping, objRegionPOD.Id);
					}
				}

				List<Region_POD_mapping__c> list_RegionPODMapping = new List<Region_POD_mapping__c>();
				if (blnShowRegionSection == true && !list_SelectedState.isEmpty()) {
					for (SelectOption s : list_SelectedState) {
						Region_POD_mapping__c objRegionPODMapping = new Region_POD_mapping__c();
						objRegionPODMapping.Region_POD__c = objRegionPOD.Id;
						objRegionPODMapping.State__c = s.getValue();
						list_RegionPODMapping.add(objRegionPODMapping);
					}
				}

				if (blnShowCarrierPODSection == true && !set_CheckedCarrier.isEmpty()) {
					if (!list_CombinationCarriers.isEmpty()) {
						for (Carrier__c objCarrier : list_CombinationCarriers) {
							Region_POD_mapping__c objRegionPODMapping = new Region_POD_mapping__c();
							objRegionPODMapping.Region_POD__c = objRegionPOD.Id;
							objRegionPODMapping.Carrier__c = objCarrier.id;
							list_RegionPODMapping.add(objRegionPODMapping);
						}
					}
				}

				if (!list_RegionPODMapping.isEmpty()) {
					upsert list_RegionPODMapping;
					RetriveRegionPOD(objRegionPOD.id);
					resetPODRegionAfterSave();
					strButtonLabel = 'Save & Add More';
					ResetStatePickVal();

					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Successfully saved');
					ApexPages.addMessage(myMsg);
				}
			} catch (Exception ex) {
				Database.RollBack(objSavePoint);
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				return null;
			}
		}
		return null;
	}

	//This method checked required field before saving any skills
	public String CheckReqiuredFields() {
		String strMissingField = '';

		if (blnShowRegionSection == true && list_SelectedState.isEmpty()) {
			strMissingField += 'States, ';
		}

		if (blnShowCarrierPODSection == true) {
			if (!list_SelectedAssignedCarrier.isEmpty()) {
				for (CarrierWrapper objCarrierWrapper : list_SelectedAssignedCarrier) {
					if (objCarrierWrapper.blnIsChecked) {
						set_CheckedCarrier.add(objCarrierWrapper.strCarrName);
					}
				}
				if (set_CheckedCarrier.isEmpty()) {
					strMissingField += 'Carrier, ';
				}
			} else {
				if (set_CheckedCarrier.isEmpty()) {
					strMissingField += 'Carrier, ';
				}
			}
			if (list_CombinationCarriers == null || list_CombinationCarriers.size() == 0) {
				list_CombinationCarriers = Database.query(getQuery());
			}
		}

		if (strMissingField != '') {
			strMissingField = strMissingField.removeEnd(', ');
			strMissingField = 'Required Fields(' + strMissingField + ')';
		}
		return strMissingField;
	}

	//Rest all the list after successfully skills saved
	private void resetPODRegionAfterSave() {
		set_CheckedCarrier = new Set<string>();
		objRegionPOD.Id = null;
		strRegionName = null;
		list_CombinationCarriers = new List<Carrier__c>();
		list_SelectedState = new List<System.SelectOption>();
		getCarrierNames();
	}

	//Get the carrier list related to selected state.
	private String getQuery() {
		String strQuery = 'SELECT Id FROM Carrier__c WHERE ';
		strQuery += ' Carrier_Unique_Name__c!=null AND Carrier_Unique_Name__c IN :set_CheckedCarrier AND Submission_BOR_Assignment__c=false AND State__c != null ';

		if (!list_SelectedState.isEmpty()) {
			strQuery += 'AND  State__c INCLUDES (';
			for (SelectOption objSelState : list_SelectedState) {
				strQuery += '\'' + objSelState.getValue() + '\',';
			}
			strQuery = strQuery.removeEnd(',');
			strQuery += ') ';
		}
		return strQuery;
	}

	public class RegionPODWrapper {
		public Region_POD__c objRegionPOD { get; set; }
		public boolean blnIsSkillExist { get; set; }
		public RegionPODWrapper(Region_POD__c objRegionPODTemp, Boolean blnIsSkillExist) {
			this.objRegionPOD = objRegionPODTemp;
			this.blnIsSkillExist = blnIsSkillExist;
		}
	}

	//Wrapper Class used to get the selected and unselected record of Carrier
	public class CarrierWrapper {
		public Boolean blnIsChecked { get; set; }
		public String strCarrName { get; set; }
		public CarrierWrapper(String strCarrName, Boolean blnIsChecked) {
			this.strCarrName = strCarrName;
			this.blnIsChecked = blnIsChecked;
		}
	}

	//After successfully saved skill this method reset the existing pod list on UI.
	private void resetExistingSkillIdSet() {
		List<Role__c> list_Role = [SELECT id, name, Skill_Type__c, Team__c FROM Role__c WHERE id = :strRoleId ORDER BY Name LIMIT 1];
		Role__c objRole = new Role__c();
		if (list_Role != null && list_Role.size() > 0) {
			objRole = list_Role[0];
		}
		if (objRole != null && objRole.Id != null) {
			set_SelectedCarrierPOD.clear();
			set_ExistingSkillId = new Set<string>();
			if (list_Role.size() > 0) {
				List<Skill__c> list_skills = [
					SELECT id, name, Region_POD__c, Role__c, TADA__c, Partner__c, State_Group__c, Order_Type__c
					FROM Skill__c
					WHERE Role__c = :objRole.Id
					ORDER BY Name
				];
				if (list_skills != null && list_skills.size() > 0) {
					for (Skill__c skl : list_skills) {
						set_ExistingSkillId.add(skl.id);
						if (String.isNotBlank(skl.Region_POD__c)) {
							set_SelectedCarrierPOD.add(skl.Region_POD__c);
						}
					}
				}
			}
		}
	}

	//If state will added or removed from existing POD then this method call the batch class and create or delete skills on User Role.
	public void updateRegionPODonUserSkill(List<Region_POD_mapping__c> list_SavedMapping, Id objRegionPODId) {
		if (objRegionPODId != null) {
			Set<String> set_PODRegionState = new Set<String>();
			for (Region_POD_mapping__c objPodMapping : list_SavedMapping) {
				if (String.isNotBlank(objPodMapping.State__c)) {
					set_PODRegionState.add(objPodMapping.State__c);
				}
			}

			Set<String> set_NewlyAddedState = new Set<String>();
			Set<String> set_DeletedState = new Set<String>();
			String strState = '';
			for (SelectOption s : list_SelectedState) {
				strState = s.getValue();
				if (set_PODRegionState.contains(strState)) {
					set_PODRegionState.remove(strState);
				} else {
					set_NewlyAddedState.add(strState);
				}
			}
			if (set_PODRegionState.size() > 0) {
				set_DeletedState.addAll(set_PODRegionState);
			}

			//Check size, before calling the Batch class. We will do this task after after production release. Because this change required more testing time.
			if (set_NewlyAddedState.size() > 0) {
				//If state will added or removed from existing region POD then
				//Call FWBatchAssignUserSkills Batch class to create new skill with respect to newly added state. After finish of batch class, we will delete User skills related to set_DeletedState.
				FWBatchAssignUserSkills assignSkillsBatch = new FWBatchAssignUserSkills();
				assignSkillsBatch.strRegionPODId = objRegionPODId;
				assignSkillsBatch.strRoleName = objRegionPOD.Team__c;
				assignSkillsBatch.set_NewRegionPODStates = set_NewlyAddedState;
				assignSkillsBatch.set_DeletedRegionPODStates = set_DeletedState;
				Database.executebatch(assignSkillsBatch, 1);
			} else if (set_DeletedState.size() > 0) {
				//If state removed from existing region POD then
				//Call future method and delete User skills related to set_DeletedState.
				FWManageRoleSkillsCtrl.deleteUserSkillFromUserRole(objRegionPODId, set_DeletedState, false);
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Check Save Skill button should shown or not
	 * @Parm        : null
	 * @Return      : Boolean
	 **/
	public Boolean showSaveSkillButton() {
		if (
			String.isNotBlank(objRegionPOD.Team__c) &&
			String.isNotBlank(strSkillType) &&
			blnIsAdmin &&
			(objRegionPOD.Team__c == FWManageRoleUtil.ROLE_IMPLEMENTATION ||
			objRegionPOD.Team__c == FWManageRoleUtil.ROLE_ADVISOR ||
			objRegionPOD.Team__c == FWManageRoleUtil.ROLE_BENEFITS_DESIGNER ||
			objRegionPOD.Team__c == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST) &&
			strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE
		) {
			return true;
		}

		return false;
	}
}