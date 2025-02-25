/***************************************************
Purpose : Create User Skill from User role on the basis of user's selection
			(Role Type:-Implementation Advocate, Payroll Transfer Advocate, Payroll Transfer Facilitator, Benefit Transfer)
Created By : Deepika Saini
Last Modified By : Bhagat Singh on 5 Aug 2020
****************************************************/
public without sharing class AddSkillsForUserRoleCtrl {
	public static final String UNASSIGNED = 'Unassigned';
	public static final String OBJECT_SKILL = 'Skill__c';
	public static final String FIELD_POD_SKILL = 'POD_Skills__c';
	public static final String FIELD_PAYROLL_TRANSFER_SKILLS = 'Payroll_Transfer_Skills__c';
	public static final String FIELD_PT_COMPLEXITY_LEVEL = 'PT_Facilitator_Complexity_Level__c';
	public static final String FIELD_ORDER_COMPLEXITY_SCORE = 'Order_Complexity_Score__c';
	public static final String SKILL_FIELD_STATES_COUNT = 'States_Count__c';
	public static final String SKILL_FIELD_STATES = 'States__c';
	public static final String SKILL_FIELD_PREVIOUS_PAYROLL_PROVIDER = 'Previous_Payroll_Providers__c';
	public static final String SKILL_FIELD_BENEFITS_COUNT = 'Benefits_Count__c';
	public static final String FIELD_PAYROLL_PROVIDER_TYPE = 'Payroll_Provider_Type__c';
	public static final String FIELD_PAYROLL_SALES_TEAM = 'Payroll_Sales_Team__c';
	public static final String FIELD_BT_NOTES = 'BT_Notes__c';
	public static final String FIELD_STATE_GROUP = 'State_Group__c';
	public static final String FIELD_ORDER_TYPE = 'Order_Type__c';
	public static final String FIELD_BENEFITS_BIG_DESK = 'Benefits_Big_Desk__c';
	public static final String FIELD_MAESTRO = 'Maestro__c';
	public static final String FIELD_COVERAGE_TYPE = 'Coverage_Type__c';
	public static final String FIELD_PARTNER = 'Partner__c';
	public static final String FIELD_TADA = 'TADA__c';
	public static final String TAX_RES_ACCOUNT_SPECIALIST = 'Account Specialist';
	public static final String FIELD_VALUE_EXT_PAYROLL_TRANSFER_SKILLS = 'Externals';
	public static final String TAX_RES_AGENCY = 'Agency';
	public static final String PAYROLL_SALES_TEAM = 'Payroll Sales Team';
	public static final String COMPLEXITY_LEVEL = 'Complexity Level';
	public static final String PREVIOUS_PAYROLL_PROVIDER_TYPE = 'Previous Payroll Provider Type';
	public static final String COMPLEXITY_SCORE = 'Complexity Score';
	public static final String MAESTRO = 'Maestro';

	//Get index of Bo allocation which is to be deleted
	public Integer intDeleteIndx { get; set; }
	public Integer intDeleteIndxOP { get; set; }

	//Set of years to display
	public Set<Integer> set_Years = new Set<Integer>();

	//Unique value to identify BO allocation
	public static Integer intBOIndex { get; set; }

	//Max DML Row Limit.
	public Integer INT_MAX_DML_ROWS = 9000; //Max limit is 10000.Give less than limit to hnadle if any DML rows left while saving
	//Set of Benefit Transfer Skills
	public Map<String, Boolean> map_BTDefineSkills { get; set; }
	//Build Plan Values
	public Boolean blnIsBuildPlan { get; set; }
	//Contains(Benefit transfer Advocate, Benefit Transfer Facilitator 1, Benefit Transfer Facilitator 2)
	public Set<String> set_BTRoleNames { get; set; }
	//used to Display BT notes data of User Role
	public String strBTNotes { get; set; }
	//Set used to count the Number of Rows of the Textarea
	public Map<String, Integer> map_RowCountTextArea { get; set; }
	//Benefit Transfer Advocate variables
	public Boolean blnIsTada { get; set; }
	//Payroll Transfer Skill variables
	public List<SelectOption> list_unselectedPTSkillValues { get; set; }
	public List<SelectOption> list_selectedPTSkillValues { get; set; }
	//By AKS Dated 23rd Oct 2020
	public List<SelectOption> list_unselectedPTCompScore { get; set; }
	public String strPTCompScore { get; set; }
	public List<SelectOption> list_unselectedPTPrevProvider { get; set; }
	public List<SelectOption> list_selectedPTPrevProvider { get; set; }
	public List<SelectOption> list_unselectedPTSalesTeam { get; set; }
	public List<SelectOption> list_selectedPTSalesTeam { get; set; }
	public Boolean blnPTExceptionRequest { get; set; }
	public Skill__c objSkill { get; set; }
	public Map<String, Skill__c> map_ComplexityLevelToSkillRecord;
	public List<SelectOption> list_PTFacilitatorComplexityLevelOptions { get; set; }
	public String strSelectedPTFacilitatorComplexityLevel { get; set; }
	//BSS-1030
	public List<SelectOption> list_unselectedPTPartnerTierValues { get; set; }
	public List<SelectOption> list_selectedPTPartnerTierValues { get; set; }

	//@Neha to incorporate BOA Record type change
	private Id idBOARecTypePayroll;
	//Exclude values from Order Type, Partner multi-select picklist
	public Set<String> set_ExcludeOrderType = new Set<String>{ 'TAdA: No Pre OE Setup', 'TAdA: Pre OE Setup' };

	//list to select skill type
	public List<System.SelectOption> list_SkillType { get; set; }
	//public Region_POD__c objRegionPOD{get;set;}
	//Which skill type selected by user on UI.
	public String strSkillType { get; set; }
	//Id of User Role.
	public String strUserRoleId { get; set; }
	//Current user role object.
	public User_Role__c objUserRole { get; set; }

	public map<String, Skill_Criteria_Setup__c> map_SkillSetupCriteria;
	//map of active state.
	public static final Map<String, String> map_ActiveStates = UtilitiesFactory.getActiveState();
	//List of region
	public List<RegionPODWrapper> list_RegionPODWrapper { get; set; }
	//public Id idRegionSelected{get;set;}
	//set of selected Region on User Role.
	public Set<String> set_SelectedRegion = new Set<String>();
	//set of selected Region on User Role.
	public Set<String> set_SelectedRegionNames = new Set<String>();
	// Booleans to show the which section to be displayed.
	public Boolean blnShowStateSection { get; set; }
	public Boolean blnShowRegionSection { get; set; }
	public Boolean blnShowOrderTypeSection { get; set; }
	public Boolean blnShowOrderTypeSubSection { get; set; }
	public Boolean blnShowSPartnerSection { get; set; }
	public Boolean blnShowTADASection { get; set; }
	public Boolean blnShowTADARadioBox { get; set; }
	public Boolean blnShowCarrierPODSection { get; set; }
	//BBO-2204
	public Boolean blnShowDeleteCheckbox { get; set; }
	public Boolean blnShowDeleteBtn { get; set; }

	//Which Role user have selected on UI.
	public String strRoleData { get; set; }
	//State Variables
	public List<System.SelectOption> list_UnSelectedState { get; set; }
	public List<System.SelectOption> list_SelectedState { get; set; }
	//Order Type Variables
	public List<System.SelectOption> list_UnSelectedOrderType { get; set; }
	public List<System.SelectOption> list_SelectedOrderType { get; set; }
	public List<System.SelectOption> list_SelectedOrderTypeSub { get; set; }
	public List<System.SelectOption> list_UnSelectedOrderTypeSub { get; set; }
	//Partner Variables
	public List<System.SelectOption> list_UnSelectedPartner { get; set; }
	public List<System.SelectOption> list_SelectedPartner { get; set; }
	//Tada Variables
	public list<System.SelectOption> list_UnSelectedTAdA { get; set; }
	public String strSelectedTAdA { get; set; }
	//Role Id, edit by user on UI
	//Is Tada check-box selected on UI.
	public Boolean blnTADA { get; set; }
	//Assign RoleType on the Picklist
	public List<SelectOption> list_RoleType { get; set; }
	//Implementation Advocate - Core skills variables
	public list<ManageOrderAllocationWrapper> list_ManageBOWrappers { get; set; }
	public List<selectOption> list_MonthsPicklist { get; set; }
	public List<selectOption> list_YearsPicklist { get; set; }

	//list of POD(s)
	public list<System.SelectOption> list_UnselectedPODsValues { get; set; }
	public List<System.SelectOption> list_SelectedPODsValues { get; set; }
	public String strBacktoUserRole { get; set; } //Back button information
	//POD variables
	public Region_POD__c objViewRegionPOD { get; set; }
	public Set<String> set_RegionState { get; set; }
	public Map<String, List<String>> map_CarrierPODWithState { get; set; }
	public Integer int_carrierPODCount { get; set; }
	public Integer int_StateCount { get; set; }

	public Boolean blnShowBenefitsBigDesk { get; set; }
	public Boolean blnShowMaestro { get; set; }
	public Boolean blnSelectedBigDesk { get; set; }
	public Boolean blnSelectedMaestro { get; set; }
	public Boolean blnShowAutomationStatus { get; set; }
	public Boolean blnShowTerminatedOrder { get; set; }
	public Boolean blnSelectedAutomationStatus { get; set; }

	public Map<String, SkillWrapper> map_UserSkillWrapper { get; set; }
	public Integer intOrderAllocRowCount { get; set; }
	public String strOrderAllocRoleType { get; set; }
	public String strSelectedSkillRoleName { get; set; }
	//For Tax Res
	public List<TaxResPODWrapper> list_TaxResRegionsPOD { get; set; } //For Core Only

	public List<TaxResPODWrapper> list_TaxResRegionsPODNA { get; set; } //For Core Only

	public List<SelectOption> list_TaxResSkillsType { get; set; }

	private Set<String> set_SelectedTaxResPODs;
	private Set<String> set_SelectedTaxResPODsNA;

	private String strAnalystType;
	private Boolean blnTaxResPODCaption;
	public List<Region_POD_mapping__c> list_TaxResAgenciesPODMapping { get; set; }
	public Integer intTaxResPODCount { get; set; }
	public Boolean blnPlayMode { get; set; }
	public String strSkillTypeToCheck;
	public String strPrevRoleTeam;

	//List of BO allocation to be deleted
	List<Benefit_Order_Allocation__c> list_BOsToBeDeleted = new List<Benefit_Order_Allocation__c>();

	public static final String TAX_RES_CHANGE_USER_ROLE = 'User Role';
	public static final String TRUE_VALUE = 'true';
	public static final String FALSE_VALUE = 'false';
	public static final String TAX_RES_USER_ROLE_MAIN_QUERY = 'User_Role_Main_Query';
	public static final String TAX_RES_USER_ROLE_ACC_SPECIALIST_FILTER_QUERY = 'User_Role_Acc_Specialist_Filter_Query';
	public static Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_UserRoleChangeQueries = getQueryConfigurationRecords();

	//Constructor
	public AddSkillsForUserRoleCtrl() {
		objViewRegionPOD = new Region_POD__c();
		set_RegionState = new Set<String>();
		int_carrierPODCount = 0;
		intTaxResPODCount = 0;
		strAnalystType = null;
		blnTaxResPODCaption = false;
		int_StateCount = 0;
		map_CarrierPODWithState = new Map<String, List<String>>();
		strBacktoUserRole = '<< Back to User Role';
		list_TaxResRegionsPOD = new List<TaxResPODWrapper>();
		list_TaxResRegionsPODNA = new List<TaxResPODWrapper>();
		objSkill = new Skill__c();

		list_BOsToBeDeleted = new List<Benefit_Order_Allocation__c>();
		set_Years = new Set<Integer>();

		strPrevRoleTeam = '';
		blnPlayMode = false;

		//@Neha to incorporate BOA Record type change
		//Fetch record type info for BOA
		idBOARecTypePayroll = Benefit_Order_Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Benefits').getRecordTypeId();

		strUserRoleId = Apexpages.currentPage().getParameters().get('id');
		objUserRole = new User_Role__c();
		objUserRole = [
			SELECT
				Id,
				User__r.Name,
				POD_Captain__c,
				Tax_Res_Skill_Type__c,
				Original_Team_Type__c,
				Selected_Regions_Id__c,
				Selected_Region_Keys__c,
				Selected_Regions_Name__c,
				User_Skill_Team__c,
				User_Skill_Type__c,
				User__c,
				Remove_From_Assignment__c
			FROM User_Role__c
			WHERE Id = :strUserRoleId
		];

		//Fetch Role and skill-type values ***** Start *****
		list_RoleType = UtilitiesFactory.RetriveRoleType();
		ResetSection();
		map_SkillSetupCriteria = FWManageRoleUtil.retriveAllSetupCriteria();

		if (String.isNotBlank(objUserRole.User_Skill_Team__c) && String.isNotBlank(objUserRole.User_Skill_Type__c)) {
			strRoleData = objUserRole.User_Skill_Team__c;
			strPrevRoleTeam = objUserRole.User_Skill_Team__c;
			ShowTeamSkillType();
			strSkillType = objUserRole.User_Skill_Type__c;

			if (strRoleData == FWManageRoleUtil.ROLE_IMPLEMENTATION && strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
				ManageBOAllocation();
			}

			DisplayCriteriaSection();
			selectRole();
		}

		//Fetch Role and skill-type values ***** End *****
	}

	//Back to the User Role(Parent Page)
	public PageReference Cancel() {
		PageReference pageRef = new PageReference('/' + strUserRoleId);
		return pageRef;
	}

	//Save the selected skill infomation
	public PageReference SaveSkill() {
		//Call the validation Check Method(Required Fields)
		String strMissingField = CheckReqiuredFields();
		PageReference pageRef = new PageReference('/' + strUserRoleId);

		if (String.isNotBlank(strMissingField)) {
			ApexPages.getMessages().clear();
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, strMissingField);
			ApexPages.addMessage(myMsg);
		} else {
			//delete the selected BO allocation record from system\
			if (list_BOsToBeDeleted.size() > 0) {
				delete list_BOsToBeDeleted;
			}
			if (strRoleData == FWManageRoleUtil.TEAM_ADVISING) {
				saveUserSkillsAdvising();
				return pageRef;
			}

			//Create set of existing User_Skill__c.
			Set<Id> set_ExistingUserSkills = new Set<Id>();
			Id idRole = Id.valueOf(strUserRoleId);
			for (User_Skill__c objExistingSkill : [SELECT Id FROM User_Skill__c WHERE User_Role__c = :idRole]) {
				set_ExistingUserSkills.add(objExistingSkill.Id);
			}

			if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER.equalsIgnoreCase(strRoleData)) {
				if (!createBenefitTransferUserSkills(set_ExistingUserSkills)) {
					if (!map_BTDefineSkills.isEmpty() && map_BTDefineSkills.containsKey(FWManageRoleUtil.OA_ROLE_ADVOCATE) && map_BTDefineSkills.get(FWManageRoleUtil.OA_ROLE_ADVOCATE)) {
						CreateBOAllocation();
					}

					return pageRef;
				}
			} else if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_ADV.equalsIgnoreCase(strRoleData) || FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
				if (!createPayrollTransferUserSkills(set_ExistingUserSkills)) {
					return pageRef;
				}
			} else if (strRoleData.equalsIgnoreCase(FWManageRoleUtil.ROLE_IMPLEMENTATION)) {
				String strSkillQuery = getSkillQueryAsPerRoles();

				if (String.isNotBlank(strSkillQuery)) {
					if (!createUserSkillsOnQueryResult(strSkillQuery, set_ExistingUserSkills)) {
						return pageRef;
					}
				}
			} else if (strRoleData.equalsIgnoreCase(TAX_RES_ACCOUNT_SPECIALIST)) {
				List<Case> list_OpenCases = getExistingCasesBeforeChangingRole(strRoleData);
				if (list_OpenCases.size() == 0) {
					if (!createTaxResUserSkills(set_ExistingUserSkills)) {
						return pageRef;
					}
				} else {
					String strOpenCasesErrorMessage = buildErrorMessage(list_OpenCases, objUserRole.User__r.Name);
					ApexPages.getMessages().clear();
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, strOpenCasesErrorMessage);
					ApexPages.addMessage(myMsg);
				}
			} else if (strRoleData.equalsIgnoreCase(FWManageRoleUtil.ROLE_CARRIER_IO) || strRoleData.equalsIgnoreCase(FWManageRoleUtil.ROLE_BYB_ADVOCATE)) {
				if (!createCarrierIOAndBYBAdvocate(set_ExistingUserSkills)) {
					return pageRef;
				}
			}
		}

		return null;
	}

	/*
	 * @author:         Swati Arya
	 * @description:    Method to build the error message with case links
	 * @parm:           list_OpenCases (open cases list), strUserName (User Name)
	 * @return:         Integer
	 */
	public String buildErrorMessage(List<Case> list_OpenCases, String strUserName) {
		String strErrorMessage = '';
		if (!list_OpenCases.isEmpty()) {
			strErrorMessage = 'There are';
			for (Case objCase : list_OpenCases) {
				strErrorMessage += '<a href= "' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + objCase.Id + '">' + objCase.CaseNumber + '</a>' + ',';
				strErrorMessage.trim();
			}
			strErrorMessage = strErrorMessage.removeEnd(',') + ' open cases for ' + strUserName + '. Please close the cases before changing the User Role.';
		}

		return strErrorMessage;
	}

	/*
	 * @author:         Swati Arya
	 * @description:    Method to get list of existing cases
	 * @parm:           strUserRoleVal (existing user role skill)
	 * @return:         Integer
	 */
	public List<Case> getExistingCasesBeforeChangingRole(String strUserRoleVal) {
		Integer intOpenCasesCount = 0;
		List<Case> list_ExistingCasesOpen = new List<Case>();
		String strQuery = '';
		String strUserRoleObjId = objUserRole.User__c;
		if (objUserRole.User_Skill_Team__c == TAX_RES_ACCOUNT_SPECIALIST && !strUserRoleVal.equalsIgnoreCase(objUserRole.User_Skill_Team__c)) {
			strQuery = getUserRoleChangeQuery(map_UserRoleChangeQueries, TAX_RES_USER_ROLE_ACC_SPECIALIST_FILTER_QUERY);
		}
		if (String.isNotBlank(strQuery)) {
			list_ExistingCasesOpen = Database.query(strQuery);
		}

		return list_ExistingCasesOpen;
	}

	/*
	* @author:         Swati Arya
	* @description:    Method to get the case querys from custom metadata with filters
	* @parm:           Map<String, Tax_Res_Play_Mode_Configuration__mdt> (Map of User Role Team Queries),
						strFilterQuery (to identify which filter to be applied)
	* @return:         String 
	*/
	public String getUserRoleChangeQuery(Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_UserRoleChangeQueries, String strFilterQuery) {
		String strQuery = '';
		Tax_Res_Play_Mode_Configuration__mdt objUserRoleMainQuery = new Tax_Res_Play_Mode_Configuration__mdt();
		if (map_UserRoleChangeQueries.containsKey(TAX_RES_USER_ROLE_MAIN_QUERY)) {
			objUserRoleMainQuery = map_UserRoleChangeQueries.get(TAX_RES_USER_ROLE_MAIN_QUERY);
			strQuery = objUserRoleMainQuery.Filter_Value__c;

			Tax_Res_Play_Mode_Configuration__mdt objUserRoleWhereClause = new Tax_Res_Play_Mode_Configuration__mdt();
			objUserRoleWhereClause = map_UserRoleChangeQueries.get(strFilterQuery);

			if (objUserRoleWhereClause != null) {
				strQuery = strQuery + ' AND ' + objUserRoleWhereClause.Filter_Value__c;
			}
		}

		return strQuery;
	}

	/*
		Check the Required Fields to create User Skills
		IA:- Order Type, Tada
			*/
	public String CheckReqiuredFields() {
		String strMissingField = '';
		if (blnShowOrderTypeSection && list_SelectedOrderType.isEmpty()) {
			strMissingField += 'Order Type, ';
		}

		if ((blnShowStateSection || blnShowRegionSection) && list_SelectedState.isEmpty()) {
			strMissingField += 'State, ';
		}

		if (blnShowSPartnerSection && list_SelectedPartner.isEmpty()) {
			strMissingField += 'Partner Tier, ';
		}

		if (blnShowTADASection && blnShowTADARadioBox && String.isBlank(strSelectedTAdA)) {
			strMissingField += 'TAdA, ';
		}

		if (strRoleData.equalsIgnoreCase(TAX_RES_ACCOUNT_SPECIALIST)) {
			Boolean blnAtLeastOneSelected = false;

			for (TaxResPODWrapper objPOD : list_TaxResRegionsPOD) {
				if (objPOD.blnSelected) {
					blnAtLeastOneSelected = true;
				}
			}

			if (!blnAtLeastOneSelected) {
				strMissingField += 'Tax Res Agency POD, ';
			}

			if (objUserRole.Tax_Res_Skill_Type__c == null && strRoleData != TAX_RES_ACCOUNT_SPECIALIST) {
				strMissingField += 'Skill Type, ';
			}
		}

		if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_ADV.equalsIgnoreCase(strRoleData) || FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
			if (list_selectedPTSkillValues == null || list_selectedPTSkillValues.size() == 0) {
				strMissingField += 'Payroll transfer Skills, ';
			}

			//Added by AKS dated 23rd Oct 2020
			if (strRoleData.containsIgnoreCase(FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC)) {
				if (String.isBlank(strPTCompScore)) {
					strMissingField += COMPLEXITY_SCORE + ', ';
				}

				if (list_selectedPTPrevProvider == null || list_selectedPTPrevProvider.size() == 0) {
					strMissingField += PREVIOUS_PAYROLL_PROVIDER_TYPE + ', ';
				}

				if (list_selectedPTSalesTeam == null || list_selectedPTSalesTeam.size() == 0) {
					strMissingField += PAYROLL_SALES_TEAM + ', ';
				}

				/*if (String.isBlank(strSelectedPTFacilitatorComplexityLevel)) {
					strMissingField += COMPLEXITY_LEVEL + ', ';
				}*/
			}
		}

		if (strRoleData.containsIgnoreCase(FWManageRoleUtil.ROLE_BENEFIT_TRANSFER)) {
			if (map_BTDefineSkills.get(FWManageRoleUtil.BT_FACILITATOR1) && list_SelectedPODsValues.isEmpty()) {
				strMissingField += 'POD, ';
			}
		}

		if (strRoleData == FWManageRoleUtil.TEAM_ADVISING) {
			for (SkillWrapper objSkillWrap : map_UserSkillWrapper.values()) {
				if (objSkillWrap.blnSelected) {
					if (objSkillWrap.blnShowCoverageType == true && (objSkillWrap.list_SelectedCoverageType == null || objSkillWrap.list_SelectedCoverageType.isEmpty())) {
						strMissingField += 'Coverage Types, ';
					}

					if ((objSkillWrap.blnShowState == true || objSkillWrap.blnShowRegion == true) && (objSkillWrap.list_SelectedState == null || objSkillWrap.list_SelectedState.isEmpty())) {
						strMissingField += 'States, ';
					}
				}
			}
		}

		if (String.isNotBlank(strMissingField)) {
			strMissingField = strMissingField.removeEnd(', ');
			strMissingField = 'Required Fields(' + strMissingField + ')';
		}

		return strMissingField;
	}

	//Get the values of the Picklist fields using Schema(Metadata)
	public List<System.SelectOption> getPickListValues(String Objectname, String FieldName, Set<String> ExceptFields) {
		List<System.SelectOption> pickListValues = new List<System.SelectOption>();
		Schema.DescribeSObjectResult sobject_describe = Utils.getSObjectDescribe(objectName);
		Map<String, Schema.SObjectField> map_field = sobject_describe.fields.getMap();
		List<Schema.PicklistEntry> pick_list_values = map_field.get(FieldName).getDescribe().getPickListValues();

		for (Schema.PicklistEntry a : pick_list_values) {
			if (a.getValue() != 'TAdA: No Pre OE Setup' && a.getValue() != 'TAdA: Pre OE Setup') {
				if (!ExceptFields.isEmpty()) {
					if (ExceptFields.contains(a.getValue())) {
						continue;
					} else {
						SelectOption so = new selectOption(a.getLabel(), a.getValue());
						pickListValues.add(so);
					}
				} else {
					SelectOption so = new selectOption(a.getLabel(), a.getValue());
					pickListValues.add(so);
				}
			}
		}

		return pickListValues;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Role Change Functionality on the basis of picklist
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	public PageReference selectRole() {
		if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER.equalsIgnoreCase(strRoleData)) {
			map_BTDefineSkills = new Map<String, Boolean>{
				FWManageRoleUtil.OA_ROLE_ADVOCATE => false,
				FWManageRoleUtil.BT_FACILITATOR1 => false,
				FWManageRoleUtil.BT_FACILITATOR2 => false,
				FWManageRoleUtil.BT_QUALIFIER => false
			};

			list_SelectedPODsValues = new List<System.SelectOption>();
			Set<String> set_PODValues = new Set<String>{ UNASSIGNED };
			blnIsTada = false;
			blnIsBuildPlan = false;

			set_BTRoleNames = new Set<String>{
				FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_ADVOCATE,
				FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_FACILITATOR1,
				FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_FACILITATOR2,
				FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_QUALIFIER
			};

			map_RowCountTextArea = new Map<String, Integer>();
			map_RowCountTextArea.put(FIELD_BT_NOTES, 4);

			List<User_Skill__c> list_UserSkill = [
				SELECT Id, User_Role__r.BT_Notes__c, Skill__r.TADA__c, Skill__r.POD_Skills__c, Skill__r.Build_Plans__c, Skill__r.Role__r.Name, Benefits_Big_Desk__c, Maestro__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name IN :set_BTRoleNames
			];

			if (!list_UserSkill.isEmpty()) {
				strBTNotes = list_UserSkill[0].User_Role__r.BT_Notes__c;
				map_RowCountTextArea = Cache.setRowCountOfTextArea(new User_Role__c(Id = strUserRoleId, BT_Notes__c = strBTNotes), new Set<String>{ FIELD_BT_NOTES }, map_RowCountTextArea, 4, 160);

				for (User_Skill__c objUserSkill : list_UserSkill) {
					if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_QUALIFIER.equalsIgnoreCase(objUserSkill.Skill__r.Role__r.Name)) {
						map_BTDefineSkills.put(FWManageRoleUtil.BT_QUALIFIER, true);
					}

					if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_ADVOCATE.equalsIgnoreCase(objUserSkill.Skill__r.Role__r.Name)) {
						map_BTDefineSkills.put(FWManageRoleUtil.OA_ROLE_ADVOCATE, true);

						if (!blnIsTada && objUserSkill.Skill__r.TADA__c) {
							blnIsTada = objUserSkill.Skill__r.TADA__c;
						}
					}

					if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_FACILITATOR1.equalsIgnoreCase(objUserSkill.Skill__r.Role__r.Name)) {
						map_BTDefineSkills.put(FWManageRoleUtil.BT_FACILITATOR1, true);

						if (objUserSkill.Skill__r.POD_Skills__c != UNASSIGNED)
							set_PODValues.add(objUserSkill.Skill__r.POD_Skills__c);
					}

					if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_FACILITATOR2.equalsIgnoreCase(objUserSkill.Skill__r.Role__r.Name)) {
						map_BTDefineSkills.put(FWManageRoleUtil.BT_FACILITATOR2, true);

						if (!blnIsBuildPlan && objUserSkill.Skill__r.Build_Plans__c) {
							blnIsBuildPlan = objUserSkill.Skill__r.Build_Plans__c;
						}
					}
				}

				if (map_BTDefineSkills.get(FWManageRoleUtil.OA_ROLE_ADVOCATE)) {
					ManageBOAllocation();
				}

				if (!set_PODValues.isEmpty()) {
					for (String strPod : set_PODValues) {
						if (!UNASSIGNED.equalsIgnoreCase(strPod))
							list_SelectedPODsValues.add(new SelectOption(strPod, strPod));
					}
				}
			}

			list_UnselectedPODsValues = getPickListValues(OBJECT_SKILL, FIELD_POD_SKILL, set_PODValues);
		} else if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_ADV.equalsIgnoreCase(strRoleData) || FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
			//If payroll transfer role is selected
			blnPTExceptionRequest = false;
			list_unselectedPTSkillValues = new List<SelectOption>();
			list_selectedPTSkillValues = new List<SelectOption>();

			//Added by AKS Dated 23rd Oct 2020
			list_unselectedPTCompScore = new List<SelectOption>();
			list_unselectedPTPrevProvider = new List<SelectOption>();
			list_selectedPTPrevProvider = new List<SelectOption>();
			list_unselectedPTSalesTeam = new List<SelectOption>();
			list_selectedPTSalesTeam = new List<SelectOption>();
			//BSS-1030
			list_unselectedPTPartnerTierValues = new List<SelectOption>();
			list_selectedPTPartnerTierValues = new List<SelectOption>();

			list_PTFacilitatorComplexityLevelOptions = new List<SelectOption>();
			strSelectedPTFacilitatorComplexityLevel = '';

			List<SelectOption> list_PTSkills = Cache.getFieldPickListValues(OBJECT_SKILL, FIELD_PAYROLL_TRANSFER_SKILLS);
			List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
			//Commenting this as for now only Gold Skill is going live
			//List<SelectOption> list_PTPartnerTier = Cache.getFieldPickListValues(OBJECT_SKILL, FIELD_PARTNER);
			List<SelectOption> list_PTPartnerTier = new List<SelectOption>();
			list_PTPartnerTier.add(new SelectOption('Gold', 'Gold'));

			for (User_Skill__c objUserSkill : [
				SELECT
					Id,
					Skill__r.Payroll_Transfer_Skills__c,
					Skill__r.Order_Complexity_Score__c,
					Skill__r.Payroll_Provider_Type__c,
					Skill__r.Payroll_Sales_Team__c,
					Skill__r.Exception__c,
					Skill__r.PT_Facilitator_Complexity_Level__c,
					Skill__r.Partner__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleData
			]) {
				list_UserSkill.add(objUserSkill);
				//Check Exception Request as true is opted for user
				if (objUserSkill.Skill__r.Exception__c && !blnPTExceptionRequest) {
					blnPTExceptionRequest = true;
				}

				if (String.isBlank(strPTCompScore)) {
					strPTCompScore = objUserSkill.Skill__r.Order_Complexity_Score__c;
				}

				if (objUserSkill.Skill__r.PT_Facilitator_Complexity_Level__c != null && FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
					strSelectedPTFacilitatorComplexityLevel = objUserSkill.Skill__r.PT_Facilitator_Complexity_Level__c;
					handleComplexityLevelChange();
				}
			}

			Set<String> set_ExistingSkl = new Set<String>();
			Set<String> set_ExistingPTPayroll = new Set<String>();
			Set<String> set_ExistingPTSalesTeam = new Set<String>();
			Set<String> set_ExistingPTPartnerTier = new Set<String>();

			//Populate selected picklist values if there are existing user_Skill records
			if (null != list_UserSkill && list_UserSkill.size() > 0) {
				for (User_Skill__c objUSkl : list_UserSkill) {
					set_ExistingSkl.add(objUSkl.Skill__r.Payroll_Transfer_Skills__c);
					//For Partner Tier
					set_ExistingPTPartnerTier.add(objUSkl.Skill__r?.Partner__c);
					//If user role is Payroll facilitator
					//Added by AKS Dated 23rd Oct 2020
					if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
						//For Previous Provider
						set_ExistingPTPayroll.add(objUSkl.Skill__r.Payroll_Provider_Type__c);

						//For Sales team
						set_ExistingPTSalesTeam.add(objUSkl.Skill__r.Payroll_Sales_Team__c);
					}
				}
			}

			//Populate unselected skill picklist
			for (SelectOption so : list_PTSkills) {
				if (!set_ExistingSkl.contains(so.getValue())) {
					//For Payroll Tranfer Advocate "Externals" should not be visible
					if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_ADV.equalsIgnoreCase(strRoleData)) {
						if (so.getValue() != FIELD_VALUE_EXT_PAYROLL_TRANSFER_SKILLS) {
							list_unselectedPTSkillValues.add(so);
						}
					} else {
						list_unselectedPTSkillValues.add(so);
					}
				} else {
					list_selectedPTSkillValues.add(so);
				}
			}
			//BSS-1030 Populate unselected Partner Tier
			for (SelectOption so : list_PTPartnerTier) {
				if (!set_ExistingPTPartnerTier.contains(so.getValue())) {
					list_unselectedPTPartnerTierValues.add(so);
				} else {
					list_selectedPTPartnerTierValues.add(so);
				}
			}

			//If user role is Payroll facilitator
			//Added by AKS Dated 23rd Oct 2020
			//Populate unselected and Selected skill picklist
			if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
				List<SelectOption> list_PTCompScoreSkills = Cache.getFieldPickListValues(OBJECT_SKILL, FIELD_ORDER_COMPLEXITY_SCORE);

				List<SelectOption> list_PTPrevProvider = Cache.getFieldPickListValues(OBJECT_SKILL, FIELD_PAYROLL_PROVIDER_TYPE);

				List<SelectOption> list_PTSalesTeam = Cache.getFieldPickListValues(OBJECT_SKILL, FIELD_PAYROLL_SALES_TEAM);

				//For Complexity Score
				for (SelectOption so : list_PTCompScoreSkills) {
					list_unselectedPTCompScore.add(so);
				}

				//For Previous Payroll Provider
				for (SelectOption so : list_PTPrevProvider) {
					if (!set_ExistingPTPayroll.contains(so.getValue())) {
						list_unselectedPTPrevProvider.add(so);
					} else {
						list_selectedPTPrevProvider.add(so);
					}
				}

				//For Sales Team
				for (SelectOption so : list_PTSalesTeam) {
					if (!set_ExistingPTSalesTeam.contains(so.getValue())) {
						list_unselectedPTSalesTeam.add(so);
					} else {
						list_selectedPTSalesTeam.add(so);
					}
				}

				//For Complexity Level
				list_PTFacilitatorComplexityLevelOptions.add(new selectOption('', '--None--'));
				list_PTFacilitatorComplexityLevelOptions.addAll(Cache.getFieldPickListValues(OBJECT_SKILL, FIELD_PT_COMPLEXITY_LEVEL));
			}
		} else if (TAX_RES_ACCOUNT_SPECIALIST.equalsIgnoreCase(strRoleData)) {
			list_TaxResSkillsType = new List<SelectOption>();
			//Initialize with null
			objUserRole.POD_Captain__c = null;
			objUserRole.Tax_Res_Skill_Type__c = null;
			//Get Tax Res Skill Type
			list_TaxResSkillsType = Cache.getFieldPickListValues('User_Role__c', 'Tax_Res_Skill_Type__c');

			PopulateData(strRoleData);

			list_TaxResRegionsPOD = new List<TaxResPODWrapper>();
			//get All skill related to Role
			Boolean blnFlag = false;

			for (Skill__c objSkill : [SELECT Id, Role__c, Role__r.Name, Region_POD__c, Region_POD__r.Name, Name FROM Skill__c WHERE Region_POD__r.Team__c = :strRoleData]) {
				blnFlag = false;

				if (set_SelectedTaxResPODs.contains(objSkill.Region_POD__c)) {
					blnFlag = true;
				}

				list_TaxResRegionsPOD.add(new TaxResPODWrapper(objSkill, blnFlag));
			}
		}

		return null;
	}

	public void handleComplexityLevelChange() {
		objSkill = new Skill__c();

		if (String.isNotBlank(strSelectedPTFacilitatorComplexityLevel)) {
			if (map_ComplexityLevelToSkillRecord == null) {
				map_ComplexityLevelToSkillRecord = new Map<String, Skill__c>();
				for (Skill__c objSkill : [
					SELECT Id, States_Count__c, States__c, Previous_Payroll_Providers__c, Benefits_Count__c, PT_Facilitator_Complexity_Level__c
					FROM Skill__c
					WHERE PT_Facilitator_Complexity_Level__c != NULL AND Role__r.Name = :strRoleData
				]) {
					map_ComplexityLevelToSkillRecord.put(objSkill.PT_Facilitator_Complexity_Level__c, objSkill);
				}
			}

			if (String.isNotBlank(strSelectedPTFacilitatorComplexityLevel) && map_ComplexityLevelToSkillRecord.containsKey(strSelectedPTFacilitatorComplexityLevel)) {
				objSkill.States_Count__c = map_ComplexityLevelToSkillRecord.get(strSelectedPTFacilitatorComplexityLevel).States_Count__c;
				objSkill.States__c = map_ComplexityLevelToSkillRecord.get(strSelectedPTFacilitatorComplexityLevel).States__c;
				objSkill.Previous_Payroll_Providers__c = map_ComplexityLevelToSkillRecord.get(strSelectedPTFacilitatorComplexityLevel).Previous_Payroll_Providers__c;
				objSkill.Benefits_Count__c = map_ComplexityLevelToSkillRecord.get(strSelectedPTFacilitatorComplexityLevel).Benefits_Count__c;
			} else {
				objSkill = new Skill__c();
			}
		}
	}

	//For Manage BO Allocation added on 31st july 2019 to set cap on BO per user - Start here
	//Populate picklist for Month
	private Map<Integer, String> map_MonthName = new Map<Integer, String>{
		1 => 'January',
		2 => 'February',
		3 => 'March',
		4 => 'April',
		5 => 'May',
		6 => 'June',
		7 => 'July',
		8 => 'August',
		9 => 'September',
		10 => 'October',
		11 => 'November',
		12 => 'December'
	};

	public void PopulateMonthAndYear() {
		list_MonthsPicklist = new List<selectOption>();
		list_YearsPicklist = new List<selectOption>();
		set_Years = new Set<Integer>();
		Integer currentYear;
		for (Integer i = 1; i <= 12; i++) {
			list_MonthsPicklist.add(new selectOption(String.valueof(i), map_MonthName.get(i)));
		}
		currentYear = System.Today().Year();
		for (Integer i = currentYear; i <= currentYear + 2; i++) {
			set_Years.add(i);
		}
	}

	private List<selectOption> getSelectOptionList(Set<Integer> set_Years) {
		list_YearsPicklist = new List<selectOption>();
		List<Integer> list_Years = new List<Integer>(set_Years);
		list_Years.sort();
		for (Integer i : list_Years) {
			list_YearsPicklist.add(new selectOption(String.valueof(i), String.valueof(i)));
		}
		return list_YearsPicklist;
	}

	private String userId;
	//This method fetch list of existing Benefit_Order_Allocation__c records.
	public PageReference ManageBOAllocation() {
		PopulateMonthAndYear();
		userId = null;
		list_ManageBOWrappers = new List<ManageOrderAllocationWrapper>();
		intBOIndex = 0;

		if (String.isNotBlank(strUserRoleId)) {
			//get User from User Role
			List<User_Role__c> list_UserRole = [SELECT Id, User__c FROM User_Role__c WHERE id = :strUserRoleId LIMIT 1];
			if (list_UserRole != null && list_UserRole.size() > 0) {
				userId = list_UserRole[0].User__c;
				String strRoleType = '';
				if (
					map_BTDefineSkills != null &&
					!map_BTDefineSkills.isEmpty() &&
					map_BTDefineSkills.containsKey(FWManageRoleUtil.OA_ROLE_ADVOCATE) &&
					map_BTDefineSkills.get(FWManageRoleUtil.OA_ROLE_ADVOCATE)
				) {
					strRoleType = FWManageRoleUtil.OA_ROLE_ADVOCATE;
				}

				//Retrive data from SFDC if any allocation for selected user
				for (Benefit_Order_Allocation__c objBO : [
					SELECT id, Max_BO__c, Month__c, Month_Name__c, User__c, User_Role__c, Year__c, Role_Type__c
					FROM Benefit_Order_Allocation__c
					WHERE User_Role__c = :strUserRoleId AND User__c = :userId AND Role_Type__c = :strRoleType
					ORDER BY Month__c, Year__c
				]) {
					ManageOrderAllocationWrapper objMB = new ManageOrderAllocationWrapper(new Benefit_Order_Allocation__c(), intBOIndex++);
					objMB.objBO = new Benefit_Order_Allocation__c();
					objMB.objBO.RecordTypeId = idBOARecTypePayroll; //@Neha to incorporate BOA Record type change
					objMB.objBO.Role_Type__c = objBO.Role_Type__c;
					objMB.objBO = objBO;
					list_ManageBOWrappers.add(objMB);

					if (!set_Years.contains((Integer) objBO.Year__c)) {
						set_Years.add((Integer) objBO.Year__c);
					}
				}
				//If there is no record then populate with static data
				if (list_ManageBOWrappers.size() == 0) {
					AddBlankRow(3);
				}
			}
		}
		list_YearsPicklist = getSelectOptionList(set_Years);
		return null;
	}

	// evaluate which skills should be link to the User role as a User Skills
	public List<User_Skill__c> evaluateBTUserSkill(List<Skill__c> list_BTSkills) {
		//List of user skills which is used to be insert
		List<User_Skill__c> list_UserSkillsToInsert = new List<User_Skill__c>();
		//List of user skills which is used to be insert
		Boolean blnUserSkillNeedToInsert;

		for (Skill__c objSkillRec : list_BTSkills) {
			blnUserSkillNeedToInsert = false;
			if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_QUALIFIER.equalsIgnoreCase(objSkillRec.Role__r.Name)) {
				blnUserSkillNeedToInsert = true;
			}
			//selected benefit transfer skill will create user skills for that
			if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_ADVOCATE.equalsIgnoreCase(objSkillRec.Role__r.Name)) {
				// if TADA is true then we have to create user skill for both tada and no tada
				if ((blnIsTada && (objSkillRec.TADA__c || !objSkillRec.TADA__c)) || (!blnIsTada && !objSkillRec.TADA__c)) {
					blnUserSkillNeedToInsert = true;
				}
			} else if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_FACILITATOR1.equalsIgnoreCase(objSkillRec.Role__r.Name) && String.isNotBlank(objSkillRec.POD_Skills__c)) {
				SelectOption objPod = new SelectOption(objSkillRec.POD_Skills__c, objSkillRec.POD_Skills__c);
				if (!list_SelectedPODsValues.isEmpty() && list_SelectedPODsValues.contains(objPod)) {
					blnUserSkillNeedToInsert = true;
				}
			} else if (FWManageRoleUtil.ROLE_BENEFIT_TRANSFER_FACILITATOR2.equalsIgnoreCase(objSkillRec.Role__r.Name)) {
				// if Build Plan is true then we have to create user skill for both Build Plan and no Build Plan
				if ((blnIsBuildPlan && (objSkillRec.Build_Plans__c || !objSkillRec.Build_Plans__c)) || (!blnIsBuildPlan && !objSkillRec.Build_Plans__c)) {
					blnUserSkillNeedToInsert = true;
				}
			}
			if (blnUserSkillNeedToInsert) {
				User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkillRec.id, User_Role__c = strUserRoleId, Skill_Role_Name__c = objSkillRec.Role__r.Name, Active__c = true);
				list_UserSkillsToInsert.add(objUserSkill);
			}
		}
		return list_UserSkillsToInsert;
	}

	//Add new record in list_ManageBOWrappers.
	public PageReference AddMore() {
		AddBlankRow(1);
		return null;
	}

	//Remove record in list_ManageBOWrappers
	public PageReference deleteBOAllocation() {
		List<ManageOrderAllocationWrapper> list_ManageBOWrappersNotToBeDeleted = null;
		if (strRoleData != FWManageRoleUtil.TEAM_ADVISING && !list_ManageBOWrappers.isEmpty()) {
			if (intDeleteIndx != null) {
				list_ManageBOWrappersNotToBeDeleted = new List<ManageOrderAllocationWrapper>();

				if (!list_ManageBOWrappers.isEmpty()) {
					for (ManageOrderAllocationWrapper objBOM : list_ManageBOWrappers) {
						if (objBOM.intRecordIndex != intDeleteIndx) {
							list_ManageBOWrappersNotToBeDeleted.add(objBOM);
						} else {
							if (objBOM.objBO.Id != null) {
								list_BOsToBeDeleted.add(objBOM.objBO);
							}
						}
					}
				}

				list_ManageBOWrappers.clear();
			}

			Integer intCount = 0;
			if (list_ManageBOWrappersNotToBeDeleted != null && !list_ManageBOWrappersNotToBeDeleted.isEmpty()) {
				list_ManageBOWrappers = new List<ManageOrderAllocationWrapper>();
				for (ManageOrderAllocationWrapper objBOM : list_ManageBOWrappersNotToBeDeleted) {
					objBOM.intRecordIndex = intCount++;
					list_ManageBOWrappers.add(objBOM);
				}
			}
		}

		if (map_UserSkillWrapper != null && strRoleData == FWManageRoleUtil.TEAM_ADVISING) {
			list_ManageBOWrappersNotToBeDeleted = new List<ManageOrderAllocationWrapper>();
			for (SkillWrapper objSkillWrap : map_UserSkillWrapper.values()) {
				if (objSkillWrap.blnSelected) {
					if (intDeleteIndxOP != null && objSkillWrap.list_AllocationWrapper != null) {
						for (ManageOrderAllocationWrapper objOP : objSkillWrap.list_AllocationWrapper) {
							if (objOP.intRecordIndex != intDeleteIndxOP) {
								list_ManageBOWrappersNotToBeDeleted.add(objOP);
							} else {
								if (objOP.objBO.Id != null) {
									list_BOsToBeDeleted.add(objOP.objBO);
								}
							}
						}
					}
					objSkillWrap.list_AllocationWrapper.clear();

					if (list_ManageBOWrappersNotToBeDeleted != null && !list_ManageBOWrappersNotToBeDeleted.isEmpty()) {
						Integer intCount = 0;
						objSkillWrap.list_AllocationWrapper = new List<ManageOrderAllocationWrapper>();
						for (ManageOrderAllocationWrapper objBO1 : list_ManageBOWrappersNotToBeDeleted) {
							objBO1.intRecordIndex = intCount++;
							objSkillWrap.list_AllocationWrapper.add(objBO1);
						}
					}
				}
			}
		}

		return null;
	}

	//Upsert Benefit_Order_Allocation__c records.
	private void CreateBOAllocation() {
		if (list_ManageBOWrappers != null && list_ManageBOWrappers.size() > 0) {
			List<Benefit_Order_Allocation__c> list_BO = new List<Benefit_Order_Allocation__c>();
			List<Benefit_Order_Allocation__c> list_BODelete = new List<Benefit_Order_Allocation__c>();
			set<String> set_MonthYear = new Set<String>();
			for (ManageOrderAllocationWrapper mb : list_ManageBOWrappers) {
				String key = mb.objBO.Month__c + '~' + mb.objBO.Year__c;
				if (mb.objBO.Max_BO__c != null && mb.objBO.Max_BO__c >= 0 && set_MonthYear.contains(key) == false) {
					mb.objBO.User_Role__c = strUserRoleId;

					if (
						map_BTDefineSkills != null &&
						!map_BTDefineSkills.isEmpty() &&
						map_BTDefineSkills.containsKey(FWManageRoleUtil.OA_ROLE_ADVOCATE) &&
						map_BTDefineSkills.get(FWManageRoleUtil.OA_ROLE_ADVOCATE)
					) {
						mb.objBO.Role_Type__c = FWManageRoleUtil.OA_ROLE_ADVOCATE;
					}

					list_BO.add(mb.objBO);
					//Check if any duplicate then data should not be insert
					set_MonthYear.add(key);
				}
				//get All BO Allocation where update allocation is now set zero or null to delete
				if (mb.objBO.id != null && mb.objBO.Max_BO__c == null) {
					list_BODelete.add(mb.objBO);
				}
			}
			//Delete existing record
			if (list_BODelete != null && list_BODelete.size() > 0) {
				delete list_BODelete;
			}
			//Create Update record
			if (list_BO != null && list_BO.size() > 0) {
				upsert list_BO;
				set_MonthYear = new Set<String>();
			}
		}
	}

	//Add new record in list_ManageBOWrappers.
	private void AddBlankRow(Integer row) {
		//get Current Month and year
		Integer intMonthNum = Date.Today().Month();
		Integer intYearNum = Date.Today().Year();
		String strRoleType = '';
		intBOIndex = list_ManageBOWrappers.size();

		if (
			map_BTDefineSkills != null &&
			!map_BTDefineSkills.isEmpty() &&
			map_BTDefineSkills.containsKey(FWManageRoleUtil.OA_ROLE_ADVOCATE) &&
			map_BTDefineSkills.get(FWManageRoleUtil.OA_ROLE_ADVOCATE)
		) {
			strRoleType = FWManageRoleUtil.OA_ROLE_ADVOCATE;
		}
		for (Integer i = 1; i <= row; i++) {
			Benefit_Order_Allocation__c objBO1 = new Benefit_Order_Allocation__c();
			objBO1.User__c = userId;
			objBO1.Month__c = intMonthNum;
			objBO1.Year__c = intYearNum;
			objBO1.Role_Type__c = strRoleType;
			objBO1.RecordTypeId = idBOARecTypePayroll; //@Neha to incorporate BOA Record type change
			ManageOrderAllocationWrapper objMB = new ManageOrderAllocationWrapper(objBO1, intBOIndex++);
			objMB.objBO = objBO1;

			list_ManageBOWrappers.add(objMB);
		}
	}
	public class ManageOrderAllocationWrapper {
		public Benefit_Order_Allocation__c objBO { get; set; }
		public Integer intRecordIndex { get; set; }

		public ManageOrderAllocationWrapper(Benefit_Order_Allocation__c objBOTemp, Integer intIndex) {
			objBO = objBOTemp;
			intRecordIndex = intIndex;
		}
	}
	//---End here

	//Redirect user to manage forecast and cap assignment page
	public pageReference redirectToFBOS() {
		PageReference pRef;
		pRef = SaveSkill();

		//If there is no error in saving skills
		if (pRef != null) {
			pRef = new PageReference('/apex/PTForecastCreationAndAssignment?userRole=' + strRoleData);
			pRef.setRedirect(true);
		}

		return pRef;
	}

	//Wrapper class to maintain Region POD information.
	public class RegionPODWrapper {
		public Boolean blnIsChecked { get; set; }
		public Id idRegionPOD { get; set; }
		public String strRegionPODName { get; set; }
		public String strRegionPODState { get; set; }
		public String strRegionPODKey { get; set; }

		public RegionPODWrapper(Id idRegionPOD, String strRegionPODName, String strRegionPODState, Boolean blnIsCheckedTemp) {
			this.idRegionPOD = idRegionPOD;
			this.strRegionPODName = strRegionPODName;
			this.strRegionPODState = strRegionPODState;
			this.blnIsChecked = blnIsCheckedTemp;
		}

		public RegionPODWrapper(Id idRegionPOD, String strRegionPODKey, String strRegionPODName, String strRegionPODState, Boolean blnIsCheckedTemp) {
			this.idRegionPOD = idRegionPOD;
			this.strRegionPODKey = strRegionPODKey;
			this.strRegionPODName = strRegionPODName;
			this.strRegionPODState = strRegionPODState;
			this.blnIsChecked = blnIsCheckedTemp;
		}
	}

	//On change of Role type, we will reset all the flags. These flags show different section on UI.
	private void ResetSection() {
		blnShowRegionSection = false;
		blnShowStateSection = false;
		blnShowCarrierPODSection = false;
		blnShowOrderTypeSection = false;
		blnShowOrderTypeSubSection = false;
		blnShowSPartnerSection = false;
		blnShowTADASection = false;
		blnShowTADARadioBox = false;
		blnShowBenefitsBigDesk = false;
		blnShowMaestro = false;
		blnShowAutomationStatus = false;
		blnShowTerminatedOrder = false;
		blnShowDeleteCheckbox = false;
		blnShowDeleteBtn = false;
	}
	/* BBO-2204 This method will delete the related User Role and User Skills */
	public PageReference deleteUserRole() {
		Savepoint objSavePoint = Database.setSavepoint();
		try {
			delete [SELECT ID FROM User_Skill__c WHERE User_Role__c = :strUserRoleId];
			delete [SELECT ID FROM USER_Role__c WHERE ID = :strUserRoleId];
		} catch (Exception objEx) {
			Database.RollBack(objSavePoint);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objEx.getMessage()));
		}
		return null;
	}

	//On change of team this method will called and show "Skill Type" on UI.
	public PageReference ShowTeamSkillType() {
		clearPopup();
		strSkillType = null;
		list_SkillType = new List<System.SelectOption>();
		list_SkillType.add(new SelectOption('', '--None--'));

		if (strRoleData != null) {
			for (Skill_Criteria_Setup__c objSkillSetup : [SELECT Name, Team__c, Filter_Criteria__c, Skill_Type__c FROM Skill_Criteria_Setup__c WHERE Team__c = :strRoleData]) {
				list_SkillType.add(new SelectOption(objSkillSetup.Skill_Type__c, objSkillSetup.Skill_Type__c));
			}
			blnShowDeleteCheckbox = false;
		} else { //BBO-2204
			ApexPages.getMessages().clear();
			ApexPages.Message myMsg = new ApexPages.Message(
				ApexPages.Severity.WARNING,
				'If you Select Role as "None", this will delete all skills for the IC and delete their User Role. This should only be done if the IC is transferring teams. Please confirm you want to delete all skills and the role by selecting the below checkbox to enable the Delete Button, then select delete.'
			);
			ApexPages.addMessage(myMsg);
			blnShowDeleteCheckbox = true;
			return null;
		}
		if (strRoleData == FWManageRoleUtil.ROLE_CARRIER_IO) {
			strSkillType = FWManageRoleUtil.SKILL_TYPE_CORE;
		}

		if (strRoleData == FWManageRoleUtil.TEAM_ADVISING) {
			onTeamChange();
		}
		//BBO-2204
		if (strRoleData != FWManageRoleUtil.ROLE_IMPLEMENTATION) {
			strSkillType = FWManageRoleUtil.SKILL_TYPE_CORE;
			if (strRoleData != FWManageRoleUtil.TEAM_ADVISING) {
				ManageBOAllocation();
			}

			DisplayCriteriaSection();
			selectRole();
		}

		return null;
	}

	//On change of skill type. This method will execute and show, existing role or create new role option.
	public PageReference DisplayCriteriaSection() {
		clearPopup();
		//BBO-2204
		if (strRoleData == FWManageRoleUtil.ROLE_IMPLEMENTATION) {
			if (FWManageRoleUtil.SKILL_TYPE_CORE.equalsIgnoreCase(strSkillType)) {
				ManageBOAllocation();
			} else {
				list_ManageBOWrappers = new List<ManageOrderAllocationWrapper>();
			}
		}

		ResetSection();
		if (String.isNotBlank(strSkillType) && FWManageRoleUtil.SKILL_TYPE_CORE.equalsIgnoreCase(strSkillType)) {
			String strkey = strRoleData + '-' + strSkillType;
			String strCriteria = '';

			if (!map_SkillSetupCriteria.isEmpty() && map_SkillSetupCriteria.containsKey(strkey)) {
				strCriteria = map_SkillSetupCriteria.get(strkey).Filter_Criteria__c;
			}

			if (String.isNotBlank(strCriteria)) {
				if (strCriteria.indexOf(FWManageRoleUtil.TYPE_REGION) > -1) {
					blnShowRegionSection = true;
				}

				if (strCriteria.indexOf(FWManageRoleUtil.STATE) > -1) {
					blnShowStateSection = true;
				}

				if (strCriteria.indexOf(FWManageRoleUtil.CARRIER_POD) > -1) {
					blnShowCarrierPODSection = true;
				}

				if (strCriteria.indexOf(FWManageRoleUtil.ORDER_TYPE) > -1) {
					blnShowOrderTypeSection = true;
				}

				if (strCriteria.indexOf(FWManageRoleUtil.PARTNER) > -1) {
					blnShowSPartnerSection = true;
				}

				if (strCriteria.indexOf(FWManageRoleUtil.TADA) > -1) {
					blnShowTADASection = true;
					if (strRoleData == FWManageRoleUtil.ROLE_IMPLEMENTATION) {
						blnShowTADARadioBox = true;
						addTadaInOptions();
					}
				}

				if (strCriteria.indexOf(FWManageRoleUtil.BENEFITS_BIG_DESK) > -1) {
					blnShowBenefitsBigDesk = true;
				}
				if (strCriteria.indexOf(MAESTRO) > -1) {
					blnShowMaestro = true;
				}
			}

			PopulateData(strRoleData);
		}
		return null;
	}

	//This method fetch value of [State, Order Type, Tier, Partner, TADA] multi-select picklist.
	private void PopulateData(String strRoleNameTemp) {
		Map<String, Map<String, Set<String>>> map_UserExistingSkills;
		if (strRoleNameTemp == FWManageRoleUtil.ROLE_IMPLEMENTATION) {
			map_UserExistingSkills = RetriveUserSkillQualAndIAData(strRoleNameTemp);
		} else {
			map_UserExistingSkills = RetriveUserSkillData(strRoleNameTemp);
		}

		//Populate State

		if (blnShowStateSection || blnShowRegionSection) {
			list_UnSelectedState = new List<System.SelectOption>();
			list_SelectedState = new List<System.SelectOption>();
			RetriveRegionPOD();
			if (
				!map_UserExistingSkills.isEmpty() &&
				map_UserExistingSkills.containsKey(strRoleNameTemp) &&
				map_UserExistingSkills.get(strRoleNameTemp) != null &&
				map_UserExistingSkills.get(strRoleNameTemp).containsKey(FIELD_STATE_GROUP)
			) {
				list_UnSelectedState = getSelectOptionValues(map_ActiveStates, map_UserExistingSkills.get(strRoleNameTemp).get(FIELD_STATE_GROUP), new Set<String>(), new Set<String>());

				if (strPrevRoleTeam == strRoleData) {
					list_SelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), map_UserExistingSkills.get(strRoleNameTemp).get(FIELD_STATE_GROUP), new Set<String>());
				}
			} else {
				list_UnSelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), new Set<String>(), new Set<String>());
			}
		}

		//get Order Type
		if (blnShowOrderTypeSection) {
			list_SelectedOrderType = new List<System.SelectOption>();
			list_UnSelectedOrderType = new List<System.SelectOption>();
			Set<String> set_RemoveValuesForSelection = new Set<String>();
			set_RemoveValuesForSelection.addAll(set_ExcludeOrderType);
			if (
				!map_UserExistingSkills.isEmpty() &&
				map_UserExistingSkills.containsKey(strRoleNameTemp) &&
				map_UserExistingSkills.get(strRoleNameTemp) != null &&
				map_UserExistingSkills.get(strRoleNameTemp).containsKey(FIELD_ORDER_TYPE) &&
				strPrevRoleTeam == strRoleData
			) {
				set_RemoveValuesForSelection.addAll(map_UserExistingSkills.get(strRoleNameTemp).get(FIELD_ORDER_TYPE));

				list_SelectedOrderType = addSelectedValuesToSelectOption(map_UserExistingSkills.get(strRoleNameTemp).get(FIELD_ORDER_TYPE), list_SelectedOrderType);

				list_UnSelectedOrderType = UtilitiesFactory.getPickListValues(OBJECT_SKILL, FIELD_ORDER_TYPE, set_RemoveValuesForSelection);
			} else {
				list_UnSelectedOrderType = UtilitiesFactory.getPickListValues(OBJECT_SKILL, FIELD_ORDER_TYPE, set_RemoveValuesForSelection);
			}
		}

		//get partner
		if (blnShowSPartnerSection) {
			list_UnSelectedPartner = new List<System.SelectOption>();
			list_SelectedPartner = new List<System.SelectOption>();
			Set<String> set_RemoveValuesForSelection = new Set<String>();
			if (!map_UserExistingSkills.isEmpty() && map_UserExistingSkills.get(strRoleNameTemp).containsKey(FIELD_PARTNER) && strPrevRoleTeam == strRoleData) {
				set_RemoveValuesForSelection = map_UserExistingSkills.get(strRoleNameTemp).get(FIELD_PARTNER);
				list_SelectedPartner = addSelectedValuesToSelectOption(map_UserExistingSkills.get(strRoleNameTemp).get(FIELD_PARTNER), list_SelectedPartner);
			}

			set_RemoveValuesForSelection.addAll(set_ExcludeOrderType);
			list_UnSelectedPartner = UtilitiesFactory.getPickListValues(OBJECT_SKILL, FIELD_PARTNER, set_RemoveValuesForSelection);
		}
		//get TAdA
		if (blnShowTADASection && blnShowTADARadioBox) {
			if (!map_UserExistingSkills.isEmpty() && map_UserExistingSkills.get(strRoleNameTemp).containsKey(FIELD_TADA) && strPrevRoleTeam == strRoleData) {
				strSelectedTAdA = setSelectedValuesOnUI(map_UserExistingSkills.get(strRoleNameTemp).get(FIELD_TADA), strSelectedTAdA, 'TAdA');
			}
		}
		//get Benefits Big desk
		if (blnShowBenefitsBigDesk) {
			blnSelectedBigDesk = false;

			if (!map_UserExistingSkills.isEmpty() && map_UserExistingSkills.containsKey(strRoleData) && map_UserExistingSkills.get(strRoleData).containsKey(FIELD_BENEFITS_BIG_DESK)) {
				Set<String> set_BigDesk = map_UserExistingSkills.get(strRoleData).get(FIELD_BENEFITS_BIG_DESK);
				if (set_BigDesk.contains('true')) {
					blnSelectedBigDesk = true;
				}
			}
		}
		// get Maestro
		if (blnShowMaestro) {
			blnSelectedMaestro = false;

			if (!map_UserExistingSkills.isEmpty() && map_UserExistingSkills.containsKey(strRoleData) && map_UserExistingSkills.get(strRoleData).containsKey(FIELD_Maestro)) {
				Set<String> set_Maestro = map_UserExistingSkills.get(strRoleData).get(FIELD_Maestro);
				blnSelectedMaestro = set_Maestro.contains(TRUE_VALUE);
			}
		}
	}

	//This method return what type of tada option was selected by user on UI.
	@TestVisible
	private String setSelectedValuesOnUI(Set<String> setString, String strSelectedValue, String strRadioName) {
		if (setString.contains('true') && setString.contains('false')) {
			strSelectedValue = 'Both ' + strRadioName;
		} else if (setString.contains('true')) {
			strSelectedValue = 'Only ' + strRadioName;
		} else if (setString.contains('false')) {
			strSelectedValue = 'No ' + strRadioName;
		}

		return strSelectedValue;
	}

	//This method add value in Map related to [State, Order Type, Partner] multi-select picklist.
	private List<System.SelectOption> addSelectedValuesToSelectOption(Set<String> set_SkillValues, List<System.SelectOption> list_SelectOption) {
		if (!set_SkillValues.isEmpty()) {
			for (String s : set_SkillValues) {
				if (s != null) {
					list_SelectOption.add(new System.SelectOption(s, s));
				}
			}
		}

		return list_SelectOption;
	}

	//This method return selected, multi-select picklist option value [eg: State, Order Type, Partner, TADA].
	public List<System.SelectOption> getSelectOptionValues(Map<String, String> map_ActiveStates, Set<String> strInvalidValues, Set<String> set_SelectedStates, Set<String> set_UniqueStateName) {
		List<System.SelectOption> list_PicklistValues = new List<System.SelectOption>();

		for (String strStateAbb : map_ActiveStates.keySet()) {
			String strStateName = map_ActiveStates.get(strStateAbb);

			if (!set_UniqueStateName.isEmpty() && !set_UniqueStateName.contains(strStateAbb)) {
				continue;
			}

			if (!strInvalidValues.isEmpty() && (strInvalidValues.contains(strStateAbb) || strInvalidValues.contains(strStateName))) {
				continue;
			}

			if (set_SelectedStates.isEmpty() || set_SelectedStates.contains(strStateAbb) || set_SelectedStates.contains(strStateName)) {
				String strVal = null;
				//In case of carrier POD
				if (blnShowCarrierPODSection) {
					strVal = strStateAbb;
				}

				//In case of Region
				if (blnShowRegionSection || blnShowStateSection) {
					strVal = strStateName;
				}

				SelectOption so = new selectOption(strVal, strStateName + ' (' + strStateAbb + ')');
				list_PicklistValues.add(so);
			}
		}

		return list_PicklistValues;
	}
	//Display Tada option on VF page
	private void addTadaInOptions() {
		list_UnSelectedTAdA = new List<System.SelectOption>();
		list_UnSelectedTAdA.add(new System.SelectOption('Only TAdA', 'Only TAdA'));
		list_UnSelectedTAdA.add(new System.SelectOption('No TAdA', 'No TAdA'));
		list_UnSelectedTAdA.add(new System.SelectOption('Both TAdA', 'Both TAdA'));
	}

	//This method fetch existing user skill information. [like: State, Order Type, Partner, TADA].
	private Map<String, Map<String, Set<String>>> RetriveUserSkillData(String strRoleTeamToCheck) {
		Map<String, Map<String, Set<String>>> map_UserExistingSkills = new Map<String, Map<String, Set<String>>>{};
		set_SelectedTaxResPODs = new Set<String>();

		if (String.isNotBlank(strUserRoleId) && String.isNotBlank(strRoleTeamToCheck)) {
			for (User_Skill__c objUserSkill : [
				SELECT
					User_Skill_Role_Name__c,
					User_Role__r.Tax_Res_Skill_Type__c,
					Skill__r.TADA__c,
					User_Role__r.POD_Captain__c,
					Skill__r.Order_Type__c,
					Skill__r.Partner__c,
					Skill__r.State_Group__c,
					Coverage_Type__c,
					Benefits_Big_Desk__c,
					Maestro__c,
					Skill__r.Region_POD__c,
					Skill__r.Region_POD__r.Name
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleTeamToCheck AND Skill__c != NULL
			]) {
				//addValueToMap(objUserSkill, map_UserExistingSkills, strRoleTeamToCheck);

				//For Account Specialist
				if (strRoleData == TAX_RES_ACCOUNT_SPECIALIST) {
					//Update Tax res Skill type and Captain value
					if (objUserSkill.Skill__r?.Region_POD__c != null) {
						set_SelectedTaxResPODs.add(objUserSkill.Skill__r.Region_POD__c);
					}

					//Update Captain and Tax res Skill Type
					objUserRole.POD_Captain__c = objUserSkill.User_Role__r.POD_Captain__c;
					objUserRole.Tax_Res_Skill_Type__c = objUserSkill.User_Role__r.Tax_Res_Skill_Type__c;
				}
			}
		}

		return map_UserExistingSkills;
	}

	//Retrive Region POD based on Role and skill selection
	private void RetriveRegionPOD() {
		list_RegionPODWrapper = new List<RegionPODWrapper>();
		Map<Id, Set<String>> map_RegionWithStates = new Map<Id, Set<String>>();
		Map<Id, String> map_RegionWithName = new Map<Id, String>();
		Set<String> set_TempStates = new Set<String>();
		Set<String> set_SelectedRegion = new Set<String>();

		String strTeam;
		String strType;
		strTeam = strRoleData;
		strType = strSkillType;

		for (Region_POD_Mapping__c objRegionPOD : [
			SELECT ID, State__c, Region_POD__r.Skill_Type__c, Region_POD__r.Team__c, Region_POD__r.Type__c, Region_POD__r.Name, Region_POD__r.Id
			FROM Region_POD_Mapping__c
			WHERE State__c != NULL AND Region_POD__r.Team__c = :strTeam AND Region_POD__r.Type__c = :FWManageRoleUtil.TYPE_REGION AND Region_POD__r.Skill_Type__c = :strType
			ORDER BY Region_POD__r.Name
		]) {
			set_TempStates = new Set<String>();

			if (!map_RegionWithStates.isEmpty() && map_RegionWithStates.containsKey(objRegionPOD.Region_POD__r.Id)) {
				set_TempStates = map_RegionWithStates.get(objRegionPOD.Region_POD__r.Id);
			}

			set_TempStates.add(objRegionPOD.State__c);
			map_RegionWithStates.put(objRegionPOD.Region_POD__r.Id, set_TempStates);
			map_RegionWithName.put(objRegionPOD.Region_POD__r.Id, objRegionPOD.Region_POD__r.Name);
		}

		if (objUserRole.Selected_Regions_Id__c != null) {
			set_SelectedRegion.addAll((List<String>) objUserRole.Selected_Regions_Id__c.split(','));
		}

		if (objUserRole.Selected_Regions_Name__c != null) {
			set_SelectedRegionNames.addAll(objUserRole.Selected_Regions_Name__c.split(','));
		}

		for (Id objRegionId : map_RegionWithName.keySet()) {
			if (!map_RegionWithStates.isEmpty() && map_RegionWithStates.containsKey(objRegionId)) {
				List<String> list_State = new List<String>();
				list_State.addAll(map_RegionWithStates.get(objRegionId));
				String strStates = String.join(list_State, ', ');
				Boolean blnIsChecked = false;

				if (set_SelectedRegion.contains('' + objRegionId) && strPrevRoleTeam == strRoleData) {
					blnIsChecked = true;
				}

				RegionPODWrapper objRegionTemp = new RegionPODWrapper(objRegionId, map_RegionWithName.get(objRegionId), strStates, blnIsChecked);
				list_RegionPODWrapper.add(objRegionTemp);
			}
		}
	}

	//This method add value in map.
	private void addValueToMap(String strFieldName, String strFieldValue, Map<String, Map<String, Set<String>>> map_UserExistingSkills, String strRoleName) {
		if (!map_UserExistingSkills.isEmpty() && map_UserExistingSkills.containsKey(strRoleName) && !map_UserExistingSkills.get(strRoleName).isEmpty()) {
			Set<String> set_SkillRec = new Set<String>();
			Map<String, Set<String>> map_tempo = map_UserExistingSkills.get(strRoleName);
			if (!map_tempo.isEmpty() && map_tempo.containsKey(strFieldName) && !map_tempo.get(strFieldName).isEmpty()) {
				set_SkillRec = map_tempo.get(strFieldName);
			}
			set_SkillRec.add(strFieldValue);
			map_tempo.put(strFieldName, set_SkillRec);
			map_UserExistingSkills.put(strRoleName, map_tempo);
		} else {
			map_UserExistingSkills.put(strRoleName, new Map<String, Set<String>>{ strFieldName => new Set<String>{ strFieldValue } });
		}
	}

	//This method show available states on UI, which are not assigned in any existing POD.
	public void populateStates() {
		list_UnSelectedState = new List<System.SelectOption>();
		list_SelectedState = new List<System.SelectOption>();
		Set<String> set_States = new Set<String>();
		set_SelectedRegion = new Set<String>();
		set_SelectedRegionNames = new Set<String>();

		for (RegionPODWrapper objRegion : list_RegionPODWrapper) {
			if (objRegion.blnIsChecked) {
				set_States.addAll(objRegion.strRegionPODState.split(', '));
				set_SelectedRegion.add(objRegion.idRegionPOD);

				if (objRegion.strRegionPODName != null) {
					set_SelectedRegionNames.add(objRegion.strRegionPODName);
				}
			}
		}
		if (!set_States.isEmpty()) {
			list_UnSelectedState = getSelectOptionValues(map_ActiveStates, set_States, new Set<String>(), new Set<String>());

			list_SelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), set_States, new Set<String>());
		} else {
			list_UnSelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), new Set<String>(), new Set<String>());
		}
	}

	//Add filter condition in soql query.
	private String getSkillQueryAsPerRoles() {
		String strQueryToGetSkills = 'SELECT Id,Role__r.Name FROM Skill__c WHERE Role__c!=null ';
		if (blnShowOrderTypeSection && !list_SelectedOrderType.isEmpty()) {
			strQueryToGetSkills += getWhereClauseQuery(FIELD_ORDER_TYPE, list_SelectedOrderType);
		}

		if ((blnShowStateSection || blnShowRegionSection) && !list_SelectedState.isEmpty()) {
			strQueryToGetSkills += getWhereClauseQuery(FIELD_STATE_GROUP, list_SelectedState);
		}

		if (blnShowSPartnerSection && !list_SelectedPartner.isEmpty()) {
			strQueryToGetSkills += getWhereClauseQuery(FIELD_PARTNER, list_SelectedPartner);
		}

		if (blnShowTADASection && blnShowTADARadioBox && String.isNotBlank(strSelectedTAdA)) {
			strQueryToGetSkills += getTAdAQuery(FIELD_TADA, strSelectedTAdA);
		}

		Boolean blnRoleNameCheck;

		if (String.isNotBlank(strRoleData) && String.isNotBlank(strSkillType) && FWManageRoleUtil.SKILL_TYPE_CORE.equalsIgnoreCase(strSkillType)) {
			strQueryToGetSkills += ' AND Role__r.Name= :strRoleData';
		} else if (String.isNotBlank(strRoleData) && String.isNotBlank(strSkillTypeToCheck)) {
			if (blnRoleNameCheck) {
				strQueryToGetSkills += ' AND Role__r.Name= :strSkillTypeToCheck';
			} else {
				strQueryToGetSkills += ' AND Role__c= :strSkillTypeToCheck';
			}
		}

		if (blnShowBenefitsBigDesk) {
			strQueryToGetSkills += ' AND Benefits_Big_Desk__c = :blnSelectedBigDesk ';
		}

		if (blnShowMaestro) {
			strQueryToGetSkills += ' AND Maestro__c = :blnSelectedMaestro ';
		}

		return strQueryToGetSkills;
	}

	//get the where clause condition for different list select option
	private String getWhereClauseQuery(String strFieldNameToCompare, List<SelectOption> list_SeletionOption) {
		String strWhereClause = '';
		for (SelectOption s : list_SeletionOption) {
			strWhereClause += '\'' + s.getValue() + '\',';
		}

		strWhereClause = strWhereClause.removeEnd(',');
		return ' AND ' + strFieldNameToCompare + ' IN (' + strWhereClause + ')';
	}

	//for Tada only
	private String getTAdAQuery(String strFieldName, String strSelectedValue) {
		String strWhereClause = '';
		if (strSelectedValue == 'Only TAdA') {
			strWhereClause = ' and ' + strFieldName + ' = true ';
		} else if (strSelectedValue == 'No TAdA') {
			strWhereClause = ' and ' + strFieldName + ' = false ';
		} else if (strSelectedValue == 'Both TAdA') {
			strWhereClause = ' and (' + strFieldName + ' = true or ' + strFieldName + '  = false)';
		}

		return strWhereClause;
	}

	//Delete existing skills.
	//If DML rows limit is greater then 10K we  will used future method. Else we will used Non-future method.
	@future
	public static void deleteExistingUserSkill(Set<Id> set_UserSkillId, String strNewSkillType, String newSkillTeam) {
		deleteUserSkill(set_UserSkillId, strNewSkillType, newSkillTeam);
	}

	public static void deleteUserSkill(Set<Id> set_UserSkillId, String strNewSkillType, String newSkillTeam) {
		List<User_Skill__c> list_ExistingUserCoreSkill = new List<User_Skill__c>();
		List<User_Skill__c> list_ExistingUserOtherSkill = new List<User_Skill__c>();

		for (User_Skill__c objUserSkill : [SELECT id, Active__c, User_Skill_Role_Name__c, Skill_Type__c FROM User_Skill__c WHERE Id IN :set_UserSkillId]) {
			if (String.isBlank(objUserSkill.Skill_Type__c) || objUserSkill.Skill_Type__c == FWManageRoleUtil.SKILL_TYPE_CORE) {
				objUserSkill.Active__c = false;
				list_ExistingUserCoreSkill.add(objUserSkill);
			} else {
				list_ExistingUserOtherSkill.add(objUserSkill);
			}
		}

		if (list_ExistingUserOtherSkill != null && list_ExistingUserOtherSkill.size() > 0) {
			delete list_ExistingUserOtherSkill;
		}

		if (FWManageRoleUtil.SKILL_TYPE_CORE == strNewSkillType) {
			if (list_ExistingUserCoreSkill != null && list_ExistingUserCoreSkill.size() > 0) {
				delete list_ExistingUserCoreSkill; //Check user skill before delete
			}
		} else {
			if (list_ExistingUserCoreSkill != null && list_ExistingUserCoreSkill.size() > 0) {
				update list_ExistingUserCoreSkill; //Deactivate existing core skill
			}
		}
	}

	//In case of Tax res Region POD Start
	public class TaxResPODWrapper {
		public Boolean blnSelected { get; set; }
		public Id idSkill { get; set; }
		public Id idRole { get; set; }
		public Id idRegionPOD { get; set; }
		public String strRegionPODName { get; set; }
		public String strRoleName { get; set; }

		public TaxResPODWrapper(Skill__c objSkill, Boolean blnFlag) {
			this.blnSelected = blnFlag;
			this.idSkill = objSkill.Id;
			this.idRole = objSkill.Role__c;
			this.idRegionPOD = objSkill.Region_POD__c;
			this.strRegionPODName = objSkill.Region_POD__r.Name;
			this.strRoleName = objSkill.Role__r.Name;
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Update Carrier IO Skills and delete the existing skills
	 * @param        Set<Id> set of user skill Ids
	 * @return       Boolean - record updated successfully or not
	 **/
	public Boolean createCarrierIOAndBYBAdvocate(Set<Id> set_ExistingUserSkills) {
		Boolean blnIsError = false;
		Savepoint objSavePoint = Database.setSavepoint();

		try {
			String strQuery;
			List<User_Role__c> list_NewUserRoles = new List<User_Role__c>();
			list_NewUserRoles.add(objUserRole);

			if (objUserRole.User_Skill_Team__c != strRoleData || objUserRole.User_Skill_Type__c != strSkillType) {
				resetUserPreference();
			}

			if (set_ExistingUserSkills.size() > 0) {
				//Calculate current transition DML Rows Limit.
				Integer intTotalDMLRows = Limits.getDMLRows() + set_ExistingUserSkills.size() + list_NewUserRoles.size();
				handleDeletes(set_ExistingUserSkills, strSkillType, strRoleData, intTotalDMLRows);
			}

			//Update User Role and Skill Type on User Role.
			if (list_NewUserRoles.size() > 0) {
				objUserRole.User_Skill_Team__c = strRoleData;
				objUserRole.User_Skill_Type__c = strSkillType;
				objUserRole.Selected_Regions_Id__c = '';
				objUserRole.Selected_Regions_Name__c = '';
				update list_NewUserRoles;
			}
		} catch (Exception objEx) {
			Database.RollBack(objSavePoint);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objEx.getMessage()));
			return true;
		}

		return blnIsError;
	}

	//This method create user skills when Role type is equals to "Benefit Transfer"
	public Boolean createBenefitTransferUserSkills(Set<Id> set_ExistingUserSkills) {
		Boolean blnIsError = false;
		Savepoint sp = Database.setSavepoint();

		try {
			String strQuery;
			Set<String> set_SelectedBTRoleNames = new Set<String>();

			if (!map_BTDefineSkills.isEmpty()) {
				for (String strSkill : map_BTDefineSkills.keySet()) {
					//Check if any of the Skills is selected
					if (map_BTDefineSkills.get(strSkill)) {
						set_SelectedBTRoleNames.add('Benefit Transfer ' + strSkill);
					}
				}
			}

			if (!set_SelectedBTRoleNames.isEmpty()) {
				List<User_Role__c> list_NewUserRole = new List<User_Role__c>();
				list_NewUserRole.add(objUserRole);

				//get All the skills which user has selected the UI
				List<Skill__c> list_BTSkills = new List<Skill__c>();
				for (Skill__c objSKill : [SELECT id, TADA__c, POD_Skills__c, Build_Plans__c, Role__c, Role__r.Name FROM Skill__c WHERE Role__c != NULL AND Role__r.Name IN :set_SelectedBTRoleNames]) {
					list_BTSkills.add(objSKill);
				}

				List<User_Skill__c> list_UserSkillsToInsert = new List<User_Skill__c>();
				if (list_BTSkills.size() > 0) {
					list_UserSkillsToInsert = evaluateBTUserSkill(list_BTSkills);
					objUserRole.BT_Notes__c = strBTNotes;
				}

				if (objUserRole.User_Skill_Team__c != strRoleData || objUserRole.User_Skill_Type__c != strSkillType) {
					resetUserPreference();
				}

				// Delete the Existing records related to Benefit Transfer Qualifier ,Benefit Transfer Advocate, Benefit Transfer Facilitator 1, Benefit Transfer Facilitator 2
				if (set_ExistingUserSkills.size() > 0) {
					//Calculate current transition DML Rows Limit.
					Integer intTotalDMLRows = Limits.getDMLRows() + set_ExistingUserSkills.size() + list_UserSkillsToInsert.size() + list_NewUserRole.size();
					if (list_ManageBOWrappers != null && list_ManageBOWrappers.size() > 0) {
						//In case of 'Benefit Transfer' & 'Implementation Advocate', we will also create Benefit_Order_Allocation__c records. That's why, we need to check this wrapper size.
						intTotalDMLRows = intTotalDMLRows + list_ManageBOWrappers.size();
					}
					handleDeletes(set_ExistingUserSkills, strSkillType, strRoleData, intTotalDMLRows);
				}

				//Insert New User Skill records
				if (!list_UserSkillsToInsert.isEmpty() && list_UserSkillsToInsert.size() > 0) {
					handleInserts(list_UserSkillsToInsert);
				}

				//Update User Role and Skill Type on User Role.
				if (list_NewUserRole.size() > 0) {
					objUserRole.User_Skill_Team__c = strRoleData;
					objUserRole.User_Skill_Type__c = strSkillType;
					objUserRole.Selected_Regions_Id__c = '';
					objUserRole.Selected_Regions_Name__c = '';
					update list_NewUserRole;
				}
			}
		} catch (Exception ex) {
			Database.RollBack(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return true;
		}
		return blnIsError;
	}

	//This method create user skills when Role type is equals to "Payroll Transfer"
	public Boolean createPayrollTransferUserSkills(Set<Id> set_ExistingUserSkills) {
		Boolean blnIsError = false;
		Savepoint sp = Database.setSavepoint();
		List<Skill__c> list_Skills = new List<Skill__c>();
		Set<String> setSelectedPTSkill = new Set<String>();
		//Added by AKS for Facilitator payroll dated 23rd Oct 2020
		Set<String> set_SelectedPTPrevPayroll = new Set<String>();
		Set<String> set_SelectedPTSalesTeam = new Set<String>();
		Set<String> set_SelectedPTPartnerTier = new Set<String>();

		try {
			List<User_Role__c> list_NewUserRole = new List<User_Role__c>();
			list_NewUserRole.add(objUserRole);

			for (SelectOption so : list_selectedPTSkillValues) {
				setSelectedPTSkill.add(so.getValue());
			}
			for (SelectOption so : list_selectedPTPartnerTierValues) {
				set_SelectedPTPartnerTier.add(so.getValue());
			}
			//If User Role is Facilitator
			//Added by AKS dated 23rd Oct 2020
			if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
				//For Previous Payroll
				for (SelectOption so : list_selectedPTPrevProvider) {
					set_SelectedPTPrevPayroll.add(so.getValue());
				}

				//For Sales Team
				for (SelectOption so : list_selectedPTSalesTeam) {
					set_SelectedPTSalesTeam.add(so.getValue());
				}
			}
			//Fetch Skill records
			String strQuery = 'SELECT Id, Payroll_Transfer_Skills__c, Role__r.Name, PT_Facilitator_Complexity_Level__c, Partner__c FROM Skill__c ';
			strQuery += ' WHERE Role__r.Name =: strRoleData ';
			String strFilters = ' Payroll_Transfer_Skills__c != null AND Payroll_Transfer_Skills__c IN: setSelectedPTSkill ';

			if (set_SelectedPTPartnerTier.size() > 0) {
				strFilters += ' AND Partner__c != null AND Partner__c IN: set_SelectedPTPartnerTier ';
			} else {
				strFilters += ' AND Partner__c = null ';
			}

			//In case of facilitator
			if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData)) {
				/*if(blnPTExceptionRequest){
                 	strQuery += ' AND (Exception__c = false OR Exception__c = true)';
                 }else{
                   strQuery += ' AND (Exception__c = false)';  
                 }*/
				if (!blnPTExceptionRequest) {
					strFilters += ' AND Exception__c = false ';
				}
				strFilters += ' AND Order_Complexity_Score__c != null AND Order_Complexity_Score__c =: strPTCompScore';
				strFilters += ' AND Payroll_Provider_Type__c != null AND Payroll_Provider_Type__c IN: set_SelectedPTPrevPayroll';
				strFilters += ' AND Payroll_Sales_Team__c != null AND Payroll_Sales_Team__c IN: set_SelectedPTSalesTeam';
			}

			if (FWManageRoleUtil.ROLE_PAYROLL_TRANSFER_FAC.equalsIgnoreCase(strRoleData) && String.isNotBlank(strSelectedPTFacilitatorComplexityLevel)) {
				strQuery += ' AND ((' + strFilters + ') OR PT_Facilitator_Complexity_Level__c = :strSelectedPTFacilitatorComplexityLevel)';
			} else {
				strQuery += ' AND ' + strFilters;
			}

			for (Skill__c objSkill : Database.query(strQuery)) {
				list_Skills.add(objSkill);
			}

			if (list_Skills != null && list_Skills.size() > 0) {
				List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
				//Construct user skill records based on current transfer skill selection
				for (Skill__c objSkl : list_Skills) {
					if (setSelectedPTSkill.contains(objSkl.Payroll_Transfer_Skills__c) || objSkl.PT_Facilitator_Complexity_Level__c != null) {
						list_UserSkill.add(new User_Skill__c(Skill__c = objSkl.Id, User_Role__c = strUserRoleId, Skill_Role_Name__c = objSkl.Role__r.Name, Active__c = true));
					}
				}

				//Delete Existing skills.
				if (set_ExistingUserSkills.size() > 0) {
					//Calculate current transition DML Rows Limit.
					Integer intTotalDMLRows = Limits.getDMLRows() + set_ExistingUserSkills.size() + list_UserSkill.size() + list_NewUserRole.size();
					handleDeletes(set_ExistingUserSkills, strSkillType, strRoleData, intTotalDMLRows);
				}

				//Insert new User skills
				if (list_UserSkill.size() > 0) {
					handleInserts(list_UserSkill);
				}

				if (objUserRole.User_Skill_Team__c != strRoleData || objUserRole.User_Skill_Type__c != strSkillType) {
					resetUserPreference();
				}

				//Update Role and Skill type on User Role.
				if (list_NewUserRole.size() > 0) {
					objUserRole.User_Skill_Team__c = strRoleData;
					objUserRole.User_Skill_Type__c = strSkillType;
					objUserRole.Selected_Regions_Id__c = '';
					objUserRole.Selected_Regions_Name__c = '';
					update list_NewUserRole;
				}
			}
		} catch (Exception ex) {
			Database.RollBack(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return true;
		}
		return blnIsError;
	}

	//This method create user skills when Role type is equals to "IA"
	public Boolean createUserSkillsOnQueryResult(String strSkillQuery, Set<Id> set_ExistingUserSkills) {
		Boolean blnIsError = false;
		Savepoint sp = Database.setSavepoint();
		List<Skill__c> list_SkillsRec = new List<Skill__c>();

		if (strRoleData == FWManageRoleUtil.ROLE_IMPLEMENTATION && FWManageRoleUtil.SKILL_TYPE_CORE != strSkillType) {
			//Do not fetch and assigned any role. No need to run below soql query.
		} else {
			list_SkillsRec = Database.Query(strSkillQuery);
		}

		List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
		String strRoleName = strRoleData;

		//Construct user skill records based on current transfer skill selection
		for (Skill__c objSkl : list_SkillsRec) {
			if (String.isBlank(strRoleName)) {
				strRoleName = objSkl.Role__r.Name;
			}

			User_Skill__c objUR = new User_Skill__c();
			objUR.Skill__c = objSkl.Id;
			objUR.User_Role__c = strUserRoleId;
			objUR.Skill_Role_Name__c = objSkl.Role__r.Name;
			if (strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
				objUR.Active__c = true;
			}

			list_UserSkill.add(objUR);
		}

		try {
			List<User_Role__c> list_NewUserRole = new List<User_Role__c>();
			list_NewUserRole.add(objUserRole);

			if (!set_SelectedRegion.isEmpty()) {
				List<String> list_SelectedRegion = new List<String>();
				list_SelectedRegion.addAll(set_SelectedRegion);
				objUserRole.Selected_Regions_Id__c = String.join(list_SelectedRegion, ',');
				objUserRole.Selected_Regions_Id__c += ',';
			}

			if (!set_SelectedRegionNames.isEmpty()) {
				List<String> list_SelectedRegion = new List<String>();
				list_SelectedRegion.addAll(set_SelectedRegionNames);
				objUserRole.Selected_Regions_Name__c = String.join(list_SelectedRegion, ',');
				objUserRole.Selected_Regions_Name__c += ',';
			}

			if (objUserRole.User_Skill_Team__c != strRoleData || objUserRole.User_Skill_Type__c != strSkillType) {
				resetUserPreference();
			}

			//Delete existing user skills
			if (set_ExistingUserSkills.size() > 0) {
				//Calculate current transition DML Rows Limit.
				Integer intTotalDMLRows = Limits.getDMLRows() + set_ExistingUserSkills.size() + list_UserSkill.size() + list_NewUserRole.size();

				if (list_ManageBOWrappers != null && list_ManageBOWrappers.size() > 0) {
					//In case of 'Benefit Transfer' & 'Implementation Advocate', we will also create Benefit_Order_Allocation__c records. That's why, we need to check this wrapper size.
					intTotalDMLRows = intTotalDMLRows + list_ManageBOWrappers.size();
				}
				handleDeletes(set_ExistingUserSkills, strSkillType, (intTotalDMLRows < INT_MAX_DML_ROWS) ? strRoleData : strRoleName, intTotalDMLRows);
			}

			//Insert User Skills
			if (!list_UserSkill.isEmpty()) {
				handleInserts(list_UserSkill);
			}

			//update Role and Skill type on User Role.
			if (list_NewUserRole.size() > 0) {
				objUserRole.User_Skill_Team__c = strRoleData;
				objUserRole.User_Skill_Type__c = strSkillType;
				update list_NewUserRole;
			}

			if (strRoleData == FWManageRoleUtil.ROLE_IMPLEMENTATION && FWManageRoleUtil.SKILL_TYPE_CORE == strSkillType) {
				CreateBOAllocation();
			}
		} catch (Exception ex) {
			Database.RollBack(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return true;
		}
		return blnIsError;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : This method create user skills when Role type is equals to skill type equals to Core
	 * @Parm        : Set<Id> set of Existing Skill.
	 * @Return      : Boolean
	 **/
	public Boolean createTaxResUserSkills(Set<Id> set_ExistingUserSkills) {
		Boolean blnIsError = false;
		String strSelectedRegionPODName;
		Savepoint objSavePoint = Database.setSavepoint();
		List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();

		Set<String> set_SelectedTaxResPODs = new Set<String>();
		set_SelectedTaxResPODsNA = new Set<String>();

		try {
			List<User_Role__c> list_NewUserRole = new List<User_Role__c>();
			list_NewUserRole.add(objUserRole);

			//Get Selected Region
			for (TaxResPODWrapper objPOD : list_TaxResRegionsPOD) {
				if (objPOD.blnSelected) {
					set_SelectedTaxResPODs.add(objPOD.idRegionPOD);
				}
			}

			//Fetch Skill records
			String strQuery = 'SELECT Id, Region_POD__c, Region_POD__r.name,Partner__c, Role__c, Role__r.Name FROM Skill__c ';
			strQuery += ' WHERE Role__c != null AND Role__r.Name = :strRoleData ';

			if (!set_SelectedTaxResPODs.isEmpty()) {
				strQuery += ' AND  Region_POD__c != null AND Region_POD__c IN : set_SelectedTaxResPODs';
			}

			for (Skill__c objSkill : Database.query(strQuery)) {
				if (objSkill.Region_POD__c != null && objSkill.Region_POD__r.Name != null) {
					if (strSelectedRegionPODName == null) {
						strSelectedRegionPODName = objSkill.Region_POD__r.Name;
					} else {
						strSelectedRegionPODName = strSelectedRegionPODName + ',' + objSkill.Region_POD__r.Name;
					}
				}
				list_UserSkills.add(new User_Skill__c(Skill__c = objSkill.Id, User_Role__c = strUserRoleId, Skill_Role_Name__c = objSkill.Role__r.Name, Active__c = true));
			}

			if (list_UserSkills?.size() > 0) {
				//Delete Existing skills.
				if (set_ExistingUserSkills.size() > 0) {
					//Calculate current transition DML Rows Limit.
					Integer intTotalDMLRows = Limits.getDMLRows() + set_ExistingUserSkills.size() + list_UserSkills.size() + list_NewUserRole.size();
					handleDeletes(set_ExistingUserSkills, FWManageRoleUtil.SKILL_TYPE_CORE, strRoleData, intTotalDMLRows);
				}

				//Insert new User skills
				if (list_UserSkills.size() > 0) {
					Database.insert(list_UserSkills);
				}

				//Copy value in varible
				strAnalystType = objUserRole.Tax_Res_Skill_Type__c;
				blnTaxResPODCaption = objUserRole.POD_Captain__c;

				resetUserPreference();

				//Update Role and Skill type on User Role.
				if (list_NewUserRole.size() > 0) {
					objUserRole.User_Skill_Team__c = strRoleData;
					objUserRole.User_Skill_Type__c = FWManageRoleUtil.SKILL_TYPE_CORE;
					objUserRole.Tax_Res_Skill_Type__c = strAnalystType;
					objUserRole.POD_Captain__c = blnTaxResPODCaption;
					if (strSelectedRegionPODName != null) {
						objUserRole.Assigned_POD__c = strSelectedRegionPODName;
					}
					update list_NewUserRole;
				}
			}
		} catch (Exception objException) {
			Database.RollBack(objSavePoint);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objException.getMessage()));
			return true;
		}

		return blnIsError;
	}
	//******************Create User Skill End*****************************

	//when team or skill type will changed then we call this method.
	public void clearPopup() {
		int_carrierPODCount = 0;
		intTaxResPODCount = 0;
		int_StateCount = 0;
		objViewRegionPOD = new Region_POD__c();
		set_RegionState.clear();
		map_CarrierPODWithState.clear();
		blnSelectedBigDesk = false;
		blnSelectedMaestro = false;
	}

	//Edit existing POD.
	public void getPODDetails() {
		objViewRegionPOD = new Region_POD__c();
		list_TaxResAgenciesPODMapping = new List<Region_POD_mapping__c>();
		map_CarrierPODWithState = new Map<String, List<String>>();
		set_RegionState.clear();
		String strRecId = ApexPages.currentPage().getParameters().get('strRecId');
		if (String.isNotBlank(strRecId)) {
			String stateKey = '';
			objViewRegionPOD = [
				SELECT Id, Name, Type__c, Team__c, (SELECT Id, State__c, Carrier__c, Carrier__r.Name, Carrier__r.State__c, Agency__c, Agency__r.Name FROM Region_POD_mapping__r)
				FROM Region_POD__c
				WHERE ID = :strRecId
				LIMIT 1
			];

			if (objViewRegionPOD != null) {
				List<Region_POD_mapping__c> list_RegionPODMapping = objViewRegionPOD.Region_POD_mapping__r;

				if (list_RegionPODMapping != null && !list_RegionPODMapping.isEmpty()) {
					for (Region_POD_mapping__c objRegioPOdMap : list_RegionPODMapping) {
						if (FWManageRoleUtil.TYPE_REGION.equalsIgnoreCase(objViewRegionPOD.Type__c)) {
							stateKey = objRegioPOdMap.State__c;
							set_RegionState.add(stateKey);
						} else if (TAX_RES_AGENCY.equalsIgnoreCase(objViewRegionPOD.Type__c)) {
							list_TaxResAgenciesPODMapping.add(objRegioPOdMap);
						} else if (FWManageRoleUtil.TYPE_POD.equalsIgnoreCase(objViewRegionPOD.Type__c)) {
							stateKey = objRegioPOdMap.Carrier__r.State__c;

							if (map_ActiveStates.containsKey(stateKey)) {
								stateKey = map_ActiveStates.get(stateKey);
							}

							if (map_CarrierPODWithState.containsKey(objRegioPOdMap.Carrier__r.Name) && String.isNotBlank(stateKey)) {
								List<String> lst_State = map_CarrierPODWithState.get(objRegioPOdMap.Carrier__r.Name);

								lst_State.add(stateKey);
								map_CarrierPODWithState.put(objRegioPOdMap.Carrier__r.Name, lst_State);
							} else {
								List<String> lst_State = new List<String>();

								if (String.isNotBlank(stateKey)) {
									lst_State.add(stateKey);
								}

								map_CarrierPODWithState.put(objRegioPOdMap.Carrier__r.Name, lst_State);
							}
						}
					}
				}
			}
		}

		int_carrierPODCount = map_CarrierPODWithState.size();
		int_StateCount = set_RegionState.size();
		intTaxResPODCount = list_TaxResAgenciesPODMapping.size();
	}

	//when team or skill type will changed then reset all user preference fields.
	public void resetUserPreference() {
		objUserRole.User_Preference_Count__c = null;
		objUserRole.User_Preference_Order_Type__c = null;
		objUserRole.POD_Captain__c = false;
		objUserRole.Tax_Res_Agency_Information__c = null;
		objUserRole.Tax_Res_Skill_Type__c = null;
		if (strRoleData != FWManageRoleUtil.ROLE_IMPLEMENTATION && strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
			objUserRole.Selected_Regions_Id__c = null;
		}
	}

	//Wrapper to hold skill information
	public class SkillWrapper {
		public String strStyleClassName { get; set; } // the static class to be assigned on UI for toggle purpose
		public Boolean blnSelected { get; set; }
		public Boolean blnBenefitsBigDesk { get; set; }
		public Boolean blnShowMaestro { get; set; }

		public Boolean blnShowCoverageType { get; private set; }
		public Boolean blnShowState { get; private set; }
		public Boolean blnShowRegion { get; private set; }
		public Boolean blnShowAllocation { get; private set; }
		public Boolean blnShowBigDesk { get; private set; }

		public String strUserSkillTeamName { get; private set; }
		public String strUserSkillType { get; private set; }

		public List<System.SelectOption> list_UnSelectedState { get; set; }
		public List<System.SelectOption> list_SelectedState { get; set; }
		private Set<String> set_SelectedStates;
		public List<System.SelectOption> list_UnSelectedCoverageType { get; set; }
		public List<System.SelectOption> list_SelectedCoverageType { get; set; }

		private Set<String> set_SelectedCoverageTypes;

		public List<RegionPODWrapper> list_RegionPODWrapper { get; set; }

		public List<ManageOrderAllocationWrapper> list_AllocationWrapper { get; set; }

		public SkillWrapper() {
		}

		public SkillWrapper(Boolean blnSelected, String strUserSkillTeamName, String strSkillType) {
			this.blnSelected = blnSelected;
			this.strUserSkillTeamName = strUserSkillTeamName;
			this.strUserSkillType = strSkillType;
			this.strStyleClassName = strUserSkillTeamName.replace(' ', '_');
			String strKey = strUserSkillTeamName + '-' + strSkillType;

			Map<String, Skill_Criteria_Setup__c> map_SkillSetupCriteria = FWManageRoleUtil.retriveAllSetupCriteria();
			String strCriteria;

			if (!map_SkillSetupCriteria.isEmpty() && map_SkillSetupCriteria.containsKey(strkey)) {
				strCriteria = map_SkillSetupCriteria.get(strkey).Filter_Criteria__c;
			}

			if (String.isNotBlank(strCriteria)) {
				if (strCriteria.indexOf(FWManageRoleUtil.TYPE_REGION) > -1) {
					blnShowRegion = true;
				}

				if (strCriteria.indexOf(FWManageRoleUtil.STATE) > -1) {
					blnShowState = true;
					list_UnSelectedState = new List<SelectOption>();
					list_SelectedState = new List<SelectOption>();
					set_SelectedStates = new Set<String>();
				}

				if (strCriteria.indexOf(FWManageRoleUtil.ORDER_ALLOCATION) > -1) {
					blnShowAllocation = true;
				}

				if (strCriteria.indexOf(FWManageRoleUtil.COVERAGE_TYPE) > -1) {
					blnShowCoverageType = true;
					list_SelectedCoverageType = new List<SelectOption>();
					list_UnSelectedCoverageType = new List<SelectOption>();
					set_SelectedCoverageTypes = new Set<String>();
				}

				if (strCriteria.indexOf(FWManageRoleUtil.BENEFITS_BIG_DESK) > -1) {
					blnShowBigDesk = true;
				}
			}
		}
	}

	//On change of Role
	public void onRoleSelect() {
		Boolean blnAdvisorSelected = map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).blnSelected;
		Boolean blnRenewalSpecialistSelected = map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST).blnSelected;

		if (strOrderAllocRoleType == FWManageRoleUtil.ROLE_ADVISOR && blnAdvisorSelected == true && blnRenewalSpecialistSelected == true) {
			map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST).blnSelected = false;
			resetRoleSelections(map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST));
		} else if (strOrderAllocRoleType == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST && blnAdvisorSelected == true && blnRenewalSpecialistSelected == true) {
			map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR).blnSelected = false;
			resetRoleSelections(map_UserSkillWrapper.get(FWManageRoleUtil.ROLE_ADVISOR));
		}

		if (map_UserSkillWrapper.get(strOrderAllocRoleType).blnSelected == false) {
			resetRoleSelections(map_UserSkillWrapper.get(strOrderAllocRoleType));
		}
	}

	//If conflicting roles are selected, clear selection for other roles
	@TestVisible
	private void resetRoleSelections(SkillWrapper objSkillWrap) {
		if (objSkillWrap != null) {
			if (objSkillWrap.blnShowRegion == true || objSkillWrap.blnShowState == true) {
				objSkillWrap.list_UnselectedState.addAll(objSkillWrap.list_SelectedState);
				objSkillWrap.list_SelectedState = new List<SelectOption>();
				objSkillWrap.set_SelectedStates = new Set<String>();

				if (objSkillWrap.list_RegionPODWrapper != null) {
					for (RegionPODWrapper objRegion : objSkillWrap.list_RegionPODWrapper) {
						if (objRegion.blnIsChecked == true) {
							objRegion.blnIsChecked = false;

							if (set_SelectedRegionNames != null && set_SelectedRegionNames.contains(objRegion.strRegionPODName)) {
								set_SelectedRegionNames.remove(objRegion.strRegionPODName);
							}

							if (set_SelectedRegion != null && set_SelectedRegion.contains(objRegion.strRegionPODKey)) {
								set_SelectedRegion.remove(objRegion.strRegionPODKey);
							}
						}
					}
				}
			}

			if (objSkillWrap.blnShowCoverageType == true) {
				objSkillWrap.list_UnselectedCoverageType.addAll(objSkillWrap.list_SelectedCoverageType);
				objSkillWrap.list_SelectedCoverageType = new List<SelectOption>();
				objSkillWrap.set_SelectedCoverageTypes = new Set<String>();
			}

			if (objSkillWrap.blnShowBigDesk == true) {
				objSkillWrap.blnBenefitsBigDesk = false;
			}

			map_UserSkillWrapper.put(objSkillWrap.strUserSkillTeamName, objSkillWrap);
		}
	}

	//When team is changed and it is selected as Benefits Advising
	public void onTeamChange() {
		//Initialize User Skills Wrapper based on selected team
		map_UserSkillWrapper = new Map<String, SkillWrapper>();

		if (String.isBlank(strRoleData) || !FWManageRoleUtil.map_TeamToRoleName.containsKey(strRoleData)) {
			return;
		}

		Set<String> set_SkillTypes = new Set<String>();

		Set<String> set_UserRoles = FWManageRoleUtil.map_TeamToRoleName.get(strRoleData);

		for (String strSkillRoleName : set_UserRoles) {
			set_SkillTypes.addAll(FWManageRoleUtil.map_RoleToSkill.get(strSkillRoleName));

			for (String strSkillType : FWManageRoleUtil.map_RoleToSkill.get(strSkillRoleName)) {
				map_UserSkillWrapper.put(strSkillRoleName, new SkillWrapper(false, strSkillRoleName, strSkillType));
			}
		}

		fetchUserSkills();

		if (set_UserRoles != null && !set_UserRoles.isEmpty()) {
			if (set_SkillTypes != null && !set_SkillTypes.isEmpty()) {
				populateRegions(set_UserRoles, set_SkillTypes);
			}

			fetchOrderAllocationRecords(set_UserRoles);
		}
	}

	//Add row to Order Allocation based on selected team
	public PageReference addBlankRowToOrderAllocation() {
		//get Current Month and year
		Integer intMonthNum = date.Today().Month();
		Integer intYearNum = date.Today().Year();

		SkillWrapper objSkillWrap;

		if (!map_UserSkillWrapper.containsKey(strOrderAllocRoleType)) {
			return null;
		}

		objSkillWrap = map_UserSkillWrapper.get(strOrderAllocRoleType);

		if (objSkillWrap.list_AllocationWrapper == null) {
			objSkillWrap.list_AllocationWrapper = new List<ManageOrderAllocationWrapper>();
		}
		intBOIndex = objSkillWrap.list_AllocationWrapper.size();

		for (Integer i = 1; i <= intOrderAllocRowCount; i++) {
			Benefit_Order_Allocation__c objBo1 = new Benefit_Order_Allocation__c();
			objBo1.User__c = userId;
			objBo1.Month__c = intMonthNum;
			objBo1.Year__c = intYearNum;
			objBo1.Role_Type__c = strOrderAllocRoleType;

			ManageOrderAllocationWrapper objMB = new ManageOrderAllocationWrapper(objBo1, intBOIndex++);

			if (strOrderAllocRoleType == FWManageRoleUtil.ROLE_ADVISOR || strOrderAllocRoleType == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST) {
				objBo1.RecordTypeId = FWManageRoleUtil.ADVISING_BOA_RT_ID;
			} else {
				objBo1.RecordTypeId = idBOARecTypePayroll; //@Neha to incorporate BOA Record type change
			}

			objMB.objBO = new Benefit_Order_Allocation__c();
			objMB.objBO = objBo1;

			objSkillWrap.list_AllocationWrapper.add(objMB);

			map_UserSkillWrapper.put(strOrderAllocRoleType, objSkillWrap);
		}

		return null;
	}

	//Retrieve existing OrderAllocation records for given roles
	public void fetchOrderAllocationRecords(Set<String> set_RolesNames) {
		PopulateMonthAndYear();
		userId = null;
		if (String.isNotBlank(strUserRoleId) && map_UserSkillWrapper != null && !map_UserSkillWrapper.isEmpty()) {
			//get User from User Role
			List<User_Role__c> list_UserRole = [SELECT Id, User__c FROM User_Role__c WHERE Id = :strUserRoleId LIMIT 1];
			if (list_UserRole != null && !list_UserRole.isEmpty()) {
				userId = list_UserRole[0].User__c;
				intBOIndex = 0;

				//Retrive data from SFDC if any allocation for selected user
				for (Benefit_Order_Allocation__c objBO : [
					SELECT Max_BO__c, Month__c, Month_Name__c, User__c, User_Role__c, Year__c, Role_Type__c
					FROM Benefit_Order_Allocation__c
					WHERE User_Role__c = :strUserRoleId AND User__c = :userId AND Role_Type__c IN :set_RolesNames
					ORDER BY Month__c, Year__c
				]) {
					ManageOrderAllocationWrapper objMB = new ManageOrderAllocationWrapper(objBO, intBOIndex++);
					objMB.objBO = new Benefit_Order_Allocation__c();

					if (objBO.Role_Type__c == FWManageRoleUtil.ROLE_ADVISOR || objBO.Role_Type__c == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST) {
						objMB.objBO.RecordTypeId = FWManageRoleUtil.ADVISING_BOA_RT_ID;
					} else {
						objMB.objBO.RecordTypeId = idBOARecTypePayroll; //@Neha to incorporate BOA Record type change
					}
					objMB.objBO.Role_Type__c = objBO.Role_Type__c;
					objMB.objBO = objBO;

					List<ManageOrderAllocationWrapper> list_OrderWrapper;
					if (map_UserSkillWrapper.containsKey(objBO.Role_Type__c)) {
						SkillWrapper objSkillWrap = map_UserSkillWrapper.get(objBO.Role_Type__c);

						if (objSkillWrap.list_AllocationWrapper == null) {
							objSkillWrap.list_AllocationWrapper = new List<ManageOrderAllocationWrapper>();
						}

						objSkillWrap.list_AllocationWrapper.add(objMB);

						map_UserSkillWrapper.put(objBO.Role_Type__c, objSkillWrap);
					}

					if (!set_Years.contains((Integer) objBO.Year__c)) {
						set_Years.add((Integer) objBO.Year__c);
					}
				}
				//If there is no record then populate with static data
				for (SkillWrapper objSkillWrap : map_UserSkillWrapper.values()) {
					if (objSkillWrap.blnShowAllocation == true && objSkillWrap.list_AllocationWrapper == null) {
						intOrderAllocRowCount = 3;
						strOrderAllocRoleType = objSkillWrap.strUserSkillTeamName;
						addBlankRowToOrderAllocation();
					}
				}
			}
		}
		list_YearsPicklist = getSelectOptionList(set_Years);
	}

	//Fetch regions and populate based on Roles
	private void populateRegions(Set<String> set_RoleNames, Set<String> set_SkillTypes) {
		Map<String, Set<String>> map_RegionWithStates = new Map<String, Set<String>>();
		Map<String, String> map_RegionWithName = new Map<String, String>();
		Set<String> set_TempStates = new Set<String>();
		set_SelectedRegion = new Set<String>();
		set_SelectedRegionNames = new Set<String>();
		Map<String, String> map_RegionKeyToRoleName = new Map<String, String>();
		Map<String, List<RegionPODWrapper>> map_RegionPODPerRole = new Map<String, List<RegionPODWrapper>>();
		Map<String, Id> map_RegionKeyToId = new Map<String, Id>();

		for (Region_POD_Mapping__c objRegionPOD : [
			SELECT State__c, Region_POD__r.Key__c, Region_POD__r.Skill_Type__c, Region_POD__r.Team__c, Region_POD__r.Type__c, Region_POD__r.Name, Region_POD__r.Id
			FROM Region_POD_Mapping__c
			WHERE State__c != NULL AND Region_POD__r.Team__c IN :set_RoleNames AND Region_POD__r.Type__c = :FWManageRoleUtil.TYPE_REGION AND Region_POD__r.Skill_Type__c IN :set_SkillTypes
			ORDER BY Region_POD__r.Name
		]) {
			set_TempStates = new Set<String>();
			if (!map_RegionWithStates.isEmpty() && map_RegionWithStates.containsKey(objRegionPOD.Region_POD__r.Key__c)) {
				set_TempStates = map_RegionWithStates.get(objRegionPOD.Region_POD__r.Key__c);
			}
			set_TempStates.add(objRegionPOD.State__c);
			map_RegionWithStates.put(objRegionPOD.Region_POD__r.Key__c, set_TempStates);
			map_RegionWithName.put(objRegionPOD.Region_POD__r.Key__c, objRegionPOD.Region_POD__r.Name);
			map_RegionKeyToRoleName.put(objRegionPOD.Region_POD__r.Key__c, objRegionPOD.Region_POD__r.Team__c);
			map_RegionKeyToId.put(objRegionPOD.Region_POD__r.Key__c, objRegionPOD.Region_POD__r.Id);
		}

		if (objUserRole.Selected_Region_Keys__c != null) {
			set_SelectedRegion.addAll(objUserRole.Selected_Region_Keys__c.split(','));
		}

		for (String strRegionKey : map_RegionWithName.keySet()) {
			if (!map_RegionWithStates.isEmpty() && map_RegionWithStates.containsKey(strRegionKey)) {
				List<String> list_State = new List<String>();
				list_State.addAll(map_RegionWithStates.get(strRegionKey));
				String strStates = String.join(list_State, ', ');
				Boolean blnIsChecked = false;
				if (set_SelectedRegion.contains(strRegionKey)) {
					blnIsChecked = true;

					set_SelectedRegionNames.add(map_RegionWithName.get(strRegionKey));
				}
				RegionPODWrapper objRegionTemp = new RegionPODWrapper(map_RegionKeyToId.get(strRegionKey), strRegionKey, map_RegionWithName.get(strRegionKey), strStates, blnIsChecked);

				String strRoleName = map_RegionKeyToRoleName.get(strRegionKey);
				if (map_UserSkillWrapper.containsKey(strRoleName)) {
					SkillWrapper objSkillWrap = map_UserSkillWrapper.get(strRoleName);

					if (objSkillWrap.list_RegionPODWrapper == null) {
						objSkillWrap.list_RegionPODWrapper = new List<RegionPODWrapper>();
					}

					objSkillWrap.list_RegionPODWrapper.add(objRegionTemp);
					map_UserSkillWrapper.put(strRoleName, objSkillWrap);
				}
			}
		}
	}

	//Fetch Existing User Skills
	private void fetchUserSkills() {
		if (map_UserSkillWrapper.isEmpty()) {
			return;
		}

		for (User_Skill__c objUserSkill : [
			SELECT State_Group__c, Skill__r.Role__r.Name, Benefits_Big_Desk__c, Maestro__c, User_Role__r.User_Skill_Team__c, Coverage_Type__c
			FROM User_Skill__c
			WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name IN :map_UserSkillWrapper.keySet()
		]) {
			SkillWrapper objSkillWrap = map_UserSkillWrapper.containsKey(objUserSkill.Skill__r.Role__r.Name) ? map_UserSkillWrapper.get(objUserSkill.Skill__r.Role__r.Name) : null;

			if (objSkillWrap != null) {
				objSkillWrap.blnSelected = true;
				objSkillWrap.blnBenefitsBigDesk = objUserSkill.Benefits_Big_Desk__c;
				objSkillWrap.blnShowMaestro = objUserSkill.Maestro__c;

				if (
					String.isNotBlank(objUserSkill.State_Group__c) &&
					(objSkillWrap.set_SelectedStates == null ||
					objSkillWrap.set_SelectedStates.isEmpty() ||
					!objSkillWrap.set_SelectedStates.contains(objUserSkill.State_Group__c))
				) {
					if (objSkillWrap.set_SelectedStates == null) {
						objSkillWrap.set_SelectedStates = new Set<String>();
					}
					objSkillWrap.set_SelectedStates.add(objUserSkill.State_Group__c);
				}

				if (objSkillWrap.blnShowCoverageType == true) {
					if (String.isNotBlank(objUserSkill.Coverage_Type__c)) {
						if (objSkillWrap.set_SelectedCoverageTypes == null) {
							objSkillWrap.set_SelectedCoverageTypes = new Set<String>();
						}
						objSkillWrap.set_SelectedCoverageTypes.add(objUserSkill.Coverage_Type__c);
					}
				}

				map_UserSkillWrapper.put(objUserSkill.Skill__r.Role__r.Name, objSkillWrap);
			}
		}

		for (SkillWrapper objSkillWrap : map_UserSkillWrapper.values()) {
			if (objSkillWrap.blnShowCoverageType == true) {
				for (String strCoverageType : FWManageRoleUtil.set_CoverageTypes) {
					if (objSkillWrap.set_SelectedCoverageTypes != null && objSkillWrap.set_SelectedCoverageTypes.contains(strCoverageType)) {
						objSkillWrap.list_SelectedCoverageType.add(new SelectOption(strCoverageType, strCoverageType));
					} else {
						objSkillWrap.list_UnSelectedCoverageType.add(new SelectOption(strCoverageType, strCoverageType));
					}
				}

				map_UserSkillWrapper.put(objSkillWrap.strUserSkillTeamName, objSkillWrap);
			}

			if (objSkillWrap.blnShowState == true) {
				blnShowRegionSection = true;
				if (!objSkillWrap.set_SelectedStates.isEmpty()) {
					objSkillWrap.list_UnSelectedState = getSelectOptionValues(map_ActiveStates, objSkillWrap.set_SelectedStates, new Set<String>(), new Set<String>());
					objSkillWrap.list_SelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), objSkillWrap.set_SelectedStates, new Set<String>());
				} else {
					objSkillWrap.list_UnSelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), new Set<String>(), new Set<String>());
				}
				blnShowRegionSection = false;
			}
		}
	}

	public void populateRegionAndStates() {
		SkillWrapper objSkillWrap = map_UserSkillWrapper.get(strSelectedSkillRoleName);
		objSkillWrap.list_UnSelectedState = new List<System.SelectOption>();
		objSkillWrap.list_SelectedState = new List<System.SelectOption>();

		objSkillWrap.set_SelectedStates = new Set<String>();
		if (set_SelectedRegion == null) {
			set_SelectedRegion = new Set<String>();
		}
		if (set_SelectedRegionNames == null) {
			set_SelectedRegionNames = new Set<String>();
		}

		if (objSkillWrap.list_RegionPODWrapper == null) {
			return;
		}

		for (RegionPODWrapper objRegion : objSkillWrap.list_RegionPODWrapper) {
			if (objRegion.blnIsChecked) {
				objSkillWrap.set_SelectedStates.addAll(objRegion.strRegionPODState.split(', '));
				set_SelectedRegion.add(objRegion.strRegionPODKey);
				if (objRegion.strRegionPODName != null) {
					set_SelectedRegionNames.add(objRegion.strRegionPODName);
				}
			} else {
				if (set_SelectedRegion.contains(objRegion.strRegionPODKey)) {
					set_SelectedRegion.remove(objRegion.strRegionPODKey);
				}
				if (set_SelectedRegionNames.contains(objRegion.strRegionPODName)) {
					set_SelectedRegionNames.remove(objRegion.strRegionPODName);
				}
			}
		}

		blnShowRegionSection = true;

		if (!objSkillWrap.set_SelectedStates.isEmpty()) {
			objSkillWrap.list_UnSelectedState = getSelectOptionValues(map_ActiveStates, objSkillWrap.set_SelectedStates, new Set<String>(), new Set<String>());
			objSkillWrap.list_SelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), objSkillWrap.set_SelectedStates, new Set<String>());
		} else {
			objSkillWrap.list_UnSelectedState = getSelectOptionValues(map_ActiveStates, new Set<String>(), new Set<String>(), new Set<String>());
		}
		blnShowRegionSection = false;
		map_UserSkillWrapper.put(objSkillWrap.strUserSkillTeamName, objSkillWrap);
	}

	//Form Skill query and Consolidate Order Allocation records
	private void saveUserSkillsAdvising() {
		Set<Id> set_ExistingUserSkillIds = new Set<Id>();
		for (User_Skill__c objUserSkill : [SELECT Id FROM User_Skill__c WHERE User_Role__c = :strUserRoleId]) {
			set_ExistingUserSkillIds.add(objUserSkill.Id);
		}
		String strSkillQuery = 'SELECT Id, Role__r.Name FROM Skill__c WHERE Role__c != null';

		String strSelectedSkillsWhere = '';
		List<ManageOrderAllocationWrapper> list_OrderAllocations = new List<ManageOrderAllocationWrapper>();

		for (SkillWrapper objSkillWrap : map_UserSkillWrapper.values()) {
			if (objSkillWrap.blnSelected) {
				String strCurrentSkillQuery = '(';
				if (String.isNotBlank(objSkillWrap.strUserSkillTeamName)) {
					strCurrentSkillQuery += ' Role__r.Name = \'' + objSkillWrap.strUserSkillTeamName + '\'';
				}

				if ((objSkillWrap.blnShowState == true || objSkillWrap.blnShowRegion == true) && objSkillWrap.list_SelectedState != null && !objSkillWrap.list_SelectedState.isEmpty()) {
					strCurrentSkillQuery += getWhereClauseQuery(FIELD_STATE_GROUP, objSkillWrap.list_SelectedState);
				}

				if (objSkillWrap.blnShowBigDesk == true) {
					strCurrentSkillQuery += ' AND Benefits_Big_Desk__c = ' + objSkillWrap.blnBenefitsBigDesk;
				}

				if (objSkillWrap.blnShowMaestro == true) {
					strCurrentSkillQuery += ' AND Maestro__c = ' + objSkillWrap.blnShowMaestro;
				}

				if (objSkillWrap.blnShowCoverageType == true && objSkillWrap.list_SelectedCoverageType != null && !objSkillWrap.list_SelectedCoverageType.isEmpty()) {
					strCurrentSkillQuery += getWhereClauseQuery(FIELD_COVERAGE_TYPE, objSkillWrap.list_SelectedCoverageType);
				}

				strCurrentSkillQuery += ')';

				strSelectedSkillsWhere += String.isBlank(strSelectedSkillsWhere) ? strCurrentSkillQuery : ' OR ' + strCurrentSkillQuery;

				if (objSkillWrap.blnShowAllocation == true && objSkillWrap.list_AllocationWrapper != null && !objSkillWrap.list_AllocationWrapper.isEmpty()) {
					list_OrderAllocations.addAll(objSkillWrap.list_AllocationWrapper);
				}
			}
		}

		if (String.isNotBlank(strSelectedSkillsWhere)) {
			strSkillQuery += ' AND (' + strSelectedSkillsWhere + ')';
		} else {
			strSkillQuery = '';
		}
		createUserSkillAdvising(strSkillQuery, set_ExistingUserSkillIds);
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Insert UserSkill records and delete existing ones
	 * @Parm        : strSkillQuery - Query to execute
	 * 				  set_ExistingUserSkillIds - Set of existing user skills
	 * @Return      : Boolean - error exist or not
	 **/
	public Boolean createUserSkillAdvising(String strSkillQuery, Set<Id> set_ExistingUserSkillIds) {
		Boolean blnIsError = false;
		Savepoint sp = Database.setSavepoint();

		List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();
		List<User_Role__c> list_NewUserRole = new List<User_Role__c>();

		try {
			if (String.isNotBlank(strSkillQuery)) {
				List<Skill__c> list_Skills = Database.Query(strSkillQuery);
				String strRoleName = strRoleData;
				//Construct user skill records based on current transfer skill selection
				for (Skill__c objSkl : list_Skills) {
					User_Skill__c objUR = new User_Skill__c();
					objUR.Skill__c = objSkl.Id;
					objUR.User_Role__c = strUserRoleId;
					objUR.Skill_Role_Name__c = objSkl.Role__r.Name;

					if (strSkillType == FWManageRoleUtil.SKILL_TYPE_CORE) {
						objUR.Active__c = true;
					}
					list_UserSkills.add(objUR);
				}
			}

			objUserRole.User_Skill_Team__c = list_UserSkills.isEmpty() ? '' : strRoleData;
			objUserRole.User_Skill_Type__c = FWManageRoleUtil.SKILL_TYPE_CORE;

			objUserRole.Selected_Region_Keys__c = '';
			objUserRole.Selected_Regions_Name__c = '';

			if (!set_SelectedRegion.isEmpty() && String.isNotBlank(objUserRole.User_Skill_Team__c)) {
				List<String> list_SelectedRegion = new List<String>();
				list_SelectedRegion.addAll(set_SelectedRegion);
				objUserRole.Selected_Region_Keys__c = String.join(new List<String>(set_SelectedRegion), ',');
				objUserRole.Selected_Region_Keys__c += ',';
			}

			if (!set_SelectedRegionNames.isEmpty() && String.isNotBlank(objUserRole.User_Skill_Team__c)) {
				List<String> list_SelectedRegion = new List<String>();
				list_SelectedRegion.addAll(set_SelectedRegionNames);
				objUserRole.Selected_Regions_Name__c = String.join(new List<String>(set_SelectedRegionNames), ',');
			}

			list_NewUserRole.add(objUserRole);

			//Delete existing user skills
			if (set_ExistingUserSkillIds.size() > 0) {
				//Calculate current transition DML Rows Limit.
				Integer intTotalDMLRows = Limits.getDMLRows() + set_ExistingUserSkillIds.size() + list_UserSkills.size() + list_NewUserRole.size();
				if (list_ManageBOWrappers != null && list_ManageBOWrappers.size() > 0) {
					//In case of 'Benefit Transfer' & 'Implementation Advocate', we will also create Benefit_Order_Allocation__c records. That's why, we need to check this wrapper size.
					intTotalDMLRows = intTotalDMLRows + list_ManageBOWrappers.size();
				}
				handleDeletes(set_ExistingUserSkillIds, FWManageRoleUtil.SKILL_TYPE_CORE, '', intTotalDMLRows);
			}

			//Insert User Skills
			if (!list_UserSkills.isEmpty()) {
				handleInserts(list_UserSkills);
			}

			//update Role and Skill type on User Role.
			if (list_NewUserRole.size() > 0) {
				update list_NewUserRole;
			}
			manageOrderAllocationRecords();
		} catch (Exception ex) {
			Database.RollBack(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + ' ' + ex.getStackTraceString()));
			return true;
		}
		return blnIsError;
	}

	//Update or delete Order Allocation records based on selected Role
	private void manageOrderAllocationRecords() {
		List<Benefit_Order_Allocation__c> list_BO = new List<Benefit_Order_Allocation__c>();
		List<Benefit_Order_Allocation__c> list_BODelete = new List<Benefit_Order_Allocation__c>();

		for (SkillWrapper objSkillWrap : map_UserSkillWrapper.values()) {
			if (objSkillWrap.blnSelected == true && objSkillWrap.blnShowAllocation == true && objSkillWrap.list_AllocationWrapper != null) {
				Set<String> set_MonthYear = new Set<String>();

				for (ManageOrderAllocationWrapper mb : objSkillWrap.list_AllocationWrapper) {
					String key = mb.objBO.Month__c + '~' + mb.objBO.Year__c;
					if (mb.objBO.Max_BO__c != null && mb.objBO.Max_BO__c >= 0 && set_MonthYear.contains(key) == false) {
						mb.objBO.User_Role__c = strUserRoleId;
						list_BO.add(mb.objBO);

						set_MonthYear.add(key);
					}

					if (mb.objBO.Id != null && mb.objBO.Max_BO__c == null) {
						list_BODelete.add(mb.objBO);
					}
				}
			} else if (objSkillWrap.blnSelected == false && objSkillWrap.list_AllocationWrapper != null) {
				for (ManageOrderAllocationWrapper mb : objSkillWrap.list_AllocationWrapper) {
					if (mb.objBO.Id != null) {
						list_BODelete.add(mb.objBO);
					}
				}
			}
		}
		//Delete existing record
		if (list_BODelete != null && list_BODelete.size() > 0) {
			delete list_BODelete;
		}
		//Create Update record
		if (list_BO != null && list_BO.size() > 0) {
			upsert list_BO;
		}
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Get User role Change Queries from metadata
	 * @Parm        : NA
	 * @Return      : Map of Queries
	 **/
	public static Map<String, Tax_Res_Play_Mode_Configuration__mdt> getQueryConfigurationRecords() {
		Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_CoordinatorQueriesTemp = new Map<String, Tax_Res_Play_Mode_Configuration__mdt>();
		for (Tax_Res_Play_Mode_Configuration__mdt objMetadata : [
			SELECT Id, DeveloperName, Filter_Type__c, Skill_Type__c, Priority__c, Play_Type__c, Order_by_records__c, Filter_Value__c
			FROM Tax_Res_Play_Mode_Configuration__mdt
			WHERE Team__c = :TAX_RES_CHANGE_USER_ROLE AND Active__c = TRUE
		]) {
			map_CoordinatorQueriesTemp.put(objMetadata.DeveloperName, objMetadata);
		}

		return map_CoordinatorQueriesTemp;
	}

	/*
	 * @author:			Rushi R
	 * @description:    Handle Inserts Sync/Async depending on # of records
	 * @parm:           List of User_Skill__c
	 */
	private void handleInserts(List<User_Skill__c> list_UserSkills) {
		Integer intTotalRows = Limits.getDMLRows() + list_UserSkills.size();
		if (intTotalRows < INT_MAX_DML_ROWS || Test.isRunningTest()) {
			insert list_UserSkills;
		} else {
			ID jobID = System.enqueueJob(new BatchDML(BatchDML.Operation.INS, list_UserSkills, true));
		}
	}

	/*
	 * @author:			Rushi R
	 * @description:    Handle Deletes Sync/Async depending on # of records
	 * @parm:           List of User_Skill__c
	 */
	private void handleDeletes(Set<Id> set_SkillIds, String str_SkillType, String str_RoleData, Integer int_DMLRows) {
		if (int_DMLRows < INT_MAX_DML_ROWS) {
			//Call Non-future method.
			AddSkillsForUserRoleCtrl.deleteUserSkill(set_SkillIds, str_SkillType, str_RoleData);
		} else {
			//Call future method.
			AddSkillsForUserRoleCtrl.deleteExistingUserSkill(set_SkillIds, str_SkillType, str_RoleData);
		}
	}

	/*
	 * @author			Deepika Saini
	 * @description    	Retrive the all user skills for Implementation Advocate
	 * @param           String of role name
	 */
	private Map<String, Map<String, Set<String>>> RetriveUserSkillQualAndIAData(String strRoleName) {
		Map<String, Map<String, Set<String>>> map_UserExistingSkills = new Map<String, Map<String, Set<String>>>{};

		if (blnShowStateSection || blnShowRegionSection) {
			for (AggregateResult objUserSkill : [
				SELECT Skill__r.State_Group__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleName AND Skill__c != NULL
				GROUP BY Skill__r.State_Group__c
			]) {
				String str_StateGroup = (String) objUserSkill.get('State_Group__c');
				addValueToMap(FIELD_STATE_GROUP, str_StateGroup, map_UserExistingSkills, strRoleName);
			}
		}

		if (blnShowOrderTypeSection) {
			for (AggregateResult objUserSkill : [
				SELECT Skill__r.Order_Type__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleName AND Skill__c != NULL
				GROUP BY Skill__r.Order_Type__c
			]) {
				String str_OrderType = (String) objUserSkill.get('Order_Type__c');
				addValueToMap(FIELD_ORDER_TYPE, str_OrderType, map_UserExistingSkills, strRoleName);
			}
		}

		if (blnShowSPartnerSection) {
			for (AggregateResult objUserSkill : [
				SELECT Skill__r.Partner__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleName AND Skill__c != NULL
				GROUP BY Skill__r.Partner__c
			]) {
				String str_Partner = (String) objUserSkill.get('Partner__c');
				addValueToMap(FIELD_PARTNER, str_Partner, map_UserExistingSkills, strRoleName);
			}
		}

		if (blnShowTADASection) {
			for (AggregateResult objUserSkill : [
				SELECT Skill__r.TADA__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleName AND Skill__c != NULL
				GROUP BY Skill__r.TADA__c
			]) {
				String blnTaDaValue = (Boolean) objUserSkill.get('TADA__c') ? TRUE_VALUE : FALSE_VALUE;
				addValueToMap(FIELD_TADA, blnTaDaValue, map_UserExistingSkills, strRoleName);
			}
		}

		if (blnShowBenefitsBigDesk) {
			for (AggregateResult objUserSkill : [
				SELECT Benefits_Big_Desk__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleName AND Skill__c != NULL
				GROUP BY Benefits_Big_Desk__c
			]) {
				String blnBigDesk = (Boolean) objUserSkill.get('Benefits_Big_Desk__c') ? TRUE_VALUE : FALSE_VALUE;
				addValueToMap(FIELD_BENEFITS_BIG_DESK, blnBigDesk, map_UserExistingSkills, strRoleName);
			}
		}

		if (blnShowMaestro) {
			for (AggregateResult objUserSkill : [
				SELECT Maestro__c
				FROM User_Skill__c
				WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleName AND Skill__c != NULL
				GROUP BY Maestro__c
			]) {
				String blnMaestro = (Boolean) objUserSkill.get('Maestro__c') ? TRUE_VALUE : FALSE_VALUE;
				addValueToMap(FIELD_MAESTRO, blnMaestro, map_UserExistingSkills, strRoleName);
			}
		}

		return map_UserExistingSkills;
	}
}