/**
 * Author:Prashnat &Yuvraj
 * Date Created: 05-05-2020
 * Asana Ticket: https://app.asana.com/0/1165890935117693/1173895437712897
 * Desc: Dynamic Call logging page for Account/Opportunity/Lead
 * Test Classes  :   LogSmartCallingControllerTest
 * Modified By   :   Neha Dabas, 11-November-2020, For Benefits Onboarding call tracking
 * Modified By   :   Debas, 20-July-2021, Added new field - Primary Call Objective
 */
public class LogSmartCallingController {
	String currentPageId;
	String strProfileName;
	String str_leadtempVal;
	public String currentObject { get; set; }
	public List<AllSmartCalling__mdt> list_mdtSmartCall { get; set; }
	public Lead objLead { get; set; }
	public Lead leadFieldset { get; set; }
	public List<Opportunity> relatedOpportunities { get; set; }
	public List<OpportunityContactRole> objOppContRole { get; set; }
	public List<ZP_User_Role__c> zpUserRoleList { get; set; }
	public Map<Id, ZP_User_Role__c> zpUserRoleMap { get; set; }
	public Boolean isCXUser { get; set; }
	public List<Contact> list_contactsList { get; set; }
	public Map<Id, String> contactIdToRoleMap { get; set; }
	public String selDispostion { get; set; }
	//BT-17370
	public String strSelectedObjective { get; set; }
	public String agentNotes { get; set; }
	public String taskSubject { get; set; } // Yuvraj : 10-06-2020
	public String DateTimeStr { get; set; }
	public String caseWhoid { get; set; }
	public Boolean reRenderCases { get; set; }
	public Map<Id, List<Case>> contactIdToCaseListMap { get; set; }
	public String str_DefaultSections = 'General,FollowUp';
	public String str_taskType { get; set; } //Yuvraj : 14 May 2020
	public Task followTaskObj { get; set; }
	public Task objtask { get; set; }
	public wrapperSections wrapSections { get; set; }
	public string integrationId { get; set; }
	public string guid { get; private set; }
	//Yuvraj - merged varibales
	public List<Schema.FieldSetMember> lstFields { get; set; }
	public Opportunity objOpp { get; set; }
	private final Id callRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId();
	public Boolean bol_OutboundEmail { get; set; }
	public Boolean bol_InboundCall { get; set; }
	public Boolean blnShowLeadSection { get; set; }
	public Boolean blnShowOppSection { get; set; }
	public Boolean isMMPROrMDr { get; set; }
	public String selectedPointOfContact { get; set; }
	public String whoid { get; set; }
	public String strSelectedPhoneNumber { get; set; }
	public String strSelectedPhoneNumberNormalized { get; set; }
	public String productUpsellId { get; set; }
	public String sucessMsg { get; set; }
	public String errorMsg { get; set; }
	public List<SelectOption> pointOfContactOptions { get; set; }
	public List<SelectOption> tierUpselOptions { get; set; }
	public List<SelectOption> hiOppStageOptions { get; set; }
	public List<SelectOption> payrollOppStageOptions { get; set; }
	public List<SelectOption> stateOptions { get; set; }
	public List<SelectOption> dispositionOptions { get; set; }
	//BT-17370
	public List<SelectOption> list_objectiveOptions { get; set; }
	public List<SelectOption> taskTypeOptions { get; set; }
	public TierUpsellWrapper upsellTier { get; set; }
	public PayrollOpportutnityWrapper payrollOpp { get; set; }
	public HIOpportutnityWrapper hiOpportunity { get; set; }
	public Account theAccount { get; set; }
	public Account objAccount { get; set; } //Yuvraj : 18-06-2020
	public Opportunity theOpportunity { get; set; }
	public Boolean createPayrollOpp { get; set; }
	public Boolean createHIOpp { get; set; }
	public Boolean blnShowOppInfoSection { get; set; }
	public Opportunity objOppInfo { get; set; }
	public DateTime startTime { get; private set; }
	public DateTime endTime { get; private set; }
	public Boolean bol_DoNotCall { get; set; }
	Boolean isMDRLead = false;
	User userDetails;
	public String currentUserRole { get; set; } //11-06-2020 :By:prashant
	public Boolean displaySave { get; set; }
	public Boolean displayLtc { get; set; }
	public List<SelectOption> taskTypeOptionsByProfile { get; set; } //BY :Prashant:24-06-2020
	public Boolean bln_isSaveWOCall { get; set; } //11-06-2020 :By:prashant

	//Neha Dabas, 11-Nov-2020, For Benefit Order OA Tracking
	public Benefit_Order__c objBenefitOrder { get; set; }
	public String strPhoneNumber { get; set; }
	public String strCurrentPageRecord { get; set; }
	public List<Case> list_CasesOnBO { get; set; }
	public List<SelectOption> list_CallTypeOptions { get; private set; }
	public String strSelectedCallType { get; set; }
	public List<OpportunityContactRole> list_OppCRole { get; private set; }
	public Sales_Call_Tracking__c objCallTrackPlaceholder { get; set; } // to display differnt sales call tracking fields and capture user selection on UI

	static final Id SCT_RECTYPE_SALES = Cache.getRecordTypeId('Sales_Call_tracking__c', 'Sales');
	static final String CALL_TYPE_INBOUND = 'Inbound',
		CALL_TYPE_OUTBOUND = 'Outbound',
		OBJ_BENEFIT_ORDER = 'Benefit Order',
		INTEGRATION_ID_PREFIX = 'hippo-%',
		BENEFIT_ORDER_API_NAME = 'Benefit_Order__c',
		UNDEFINED_VALUE = 'undefined';

	public static final String USER_PROFILE_NAME_BENEFITS_USER = 'Benefits User';
	public static final String USER_PROFILE_NAME_MMPR_USER = 'MMPR User';
	public static final String USER_PROFILE_NAME_GUSTO_DIRECT_MDR = 'Gusto Direct MDR';
	public static final String HI_OPPORTUNITY_TYPE_HI_BENEFITS_NEW_PLAN = 'HI Benefits New Plan';
	public static final String HI_OPPORTUNITY_TYPE_HI_BENEFITS_BYOB = 'HI Benefits BYOB';
	public static final String OPPORTUNITY_TYPE_HI_ASSIGNMENT_STATE_CALIFORNIA = 'California';

	public static String strTaskType = '';
	public static String strHiAssignmentState = '';
	public static String strHiOpportunityType = '';

	public List<SelectOption> list_AccountingPartners { get; set; }
	public List<SelectOption> list_PartnerSalesPickListValueInto { get; set; }
	public String strPartnerTaskType { get; set; }
	// tier config custom settings that stores old and new tiers
	public static Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults() != null ? Tier_Config__c.getOrgDefaults() : new Tier_Config__c();
	public static String strNewTierSwitch = Label.New_Tier_Switch;

	//Constructor
	public LogSmartCallingController() {
		integrationId = '';
		strPhoneNumber = '';
		str_leadtempVal = '';
		str_taskType = '';
		bol_OutboundEmail = false;
		selDispostion = '';
		upsellTier = new TierUpsellWrapper();
		payrollOpp = new PayrollOpportutnityWrapper();
		hiOpportunity = new HIOpportutnityWrapper();
		productUpsellId = null;
		list_mdtSmartCall = new List<AllSmartCalling__mdt>();
		wrapSections = new wrapperSections();
		bol_InboundCall = false;
		displaySave = true;
		displayLtc = false;
		taskSubject = ''; //Yuvraj : 10-06-2020
		currentUserRole = '';
		taskTypeOptionsByProfile = new List<SelectOption>();
		strPartnerTaskType = '';
		list_PartnerSalesPickListValueInto = new List<SelectOption>();
		objtask = new Task(); //Yuvraj  06-08-2020
		//get current user info
		Id userId = UserInfo.getUserId();
		//11-06-2020 :Commented query and used GLobalQueryHelper to get the user details
		userDetails = GlobalQueryHelper.getUserInfoById(userId);
		//userDetails = [SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id=:userId];
		strProfileName = userDetails.Profile.Name;
		strProfileName = strProfileName.startsWith('_') ? strProfileName.substring(1).replace(' ', '_') : strProfileName.replace(' ', '_');
		// 11-06-2020 :By:prashant
		currentUserRole = userDetails.UserRole.Name;
		bln_isSaveWOCall = false;
		//check for CX User
		if (userDetails.Profile.Name.contains('CX User')) {
			isCXUser = true;
		} else {
			isCXUser = false;
		}

		//Generate fake guid in case Pure cloud id return null;
		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertTohex(b);
		guid = h.SubString(0, 8) + '-' + h.SubString(8, 12) + '-' + h.SubString(12, 16) + '-' + h.SubString(16, 20) + '-' + h.substring(20);
		guid = 'FK-' + guid;

		if (Test.isRunningTest()) {
			if (String.isNotBlank(strTaskType)) {
				str_taskType = strTaskType;
			}

			if (String.isNotBlank(strHiAssignmentState) && String.isBlank(hiOpportunity.hiAssignmentState)) {
				hiOpportunity.hiAssignmentState = strHiAssignmentState;
			}

			if (String.isNotBlank(strHiOpportunityType) && String.isBlank(hiOpportunity.hiOpportunityType)) {
				hiOpportunity.hiOpportunityType = strHiOpportunityType;
			}
		}

		//get Current Object Info
		currentPageId = apexPages.currentPage().getParameters().get('Id');
		integrationId = ApexPages.currentPage().getParameters().get('_c');
		if (String.isNotBlank(currentPageId)) {
			if (currentPageId.substring(0, 3) == '001') {
				currentObject = 'Account';

				theAccount = [
					SELECT
						Id,
						Name,
						OwnerId,
						Number_of_Active_Employees__c,
						RecordTypeId,
						ZP_Company_ID__c,
						CS_Notes__c,
						Account_Owner_Role__c,
						SDR_Notes__c,
						Benefits_Notes__c, //Yuvraj : 9 june 2020
						(SELECT Id, Name, Type, Description, RecordType.Name FROM Opportunities)
					FROM Account
					WHERE Id = :currentPageId
				];

				stateOptions = new List<SelectOption>();
				stateOptions.add(new SelectOption('', ''));

				for (State__c stt : [SELECT Id, Name FROM State__c ORDER BY Name ASC]) {
					stateOptions.add(new SelectOption(stt.Name, stt.Name));
				}
				hiOpportunity.employeesNumber = theAccount.Number_of_Active_Employees__c != null ? theAccount.Number_of_Active_Employees__c : 0;
				hiOpportunity.hiCloseDate = getLastDateofMonth(); //Yuvraj : 26-05-2020
			} else if (currentPageId.substring(0, 3) == '00Q') {
				currentObject = 'Lead';
				blnShowLeadSection = true;
				bol_DoNotCall = false;

				if (userDetails.Profile.Name == 'Gusto Direct MDR') {
					isMDRLead = true;
				} else {
					isMDRLead = false;
				}
			} else if (currentPageId.substring(0, 3) == '006') {
				currentObject = 'Opportunity';
				blnShowOppSection = true;

				if (userDetails.Profile.Name == 'MMPR User' || userDetails.Profile.Name == 'Gusto Direct MDR') {
					isMMPROrMDr = false;
				} else {
					isMMPROrMDr = true;
				}

				theOpportunity = [
					SELECT
						Id,
						Name,
						OwnerId,
						NumberOfEmployees__c,
						Owner_Role__c,
						Description,
						RecordTypeId,
						ZP_Company_ID__c,
						StageName,
						Sold_Not_Sold__c,
						CloseDate,
						AccountId,
						Account.Name,
						No_Phone_Bad_Number__c,
						Benefits_Notes__c,
						IsClosed
					FROM Opportunity
					WHERE Id = :currentPageId
				];

				// populateOppStage(); Yuvraj : 19-05-2020
				stateOptions = new List<SelectOption>();
				stateOptions.add(new SelectOption('', ''));
				for (State__c stt : [SELECT Id, Name FROM State__c ORDER BY Name ASC]) {
					stateOptions.add(new SelectOption(stt.Name, stt.Name));
				}
				hiOpportunity.employeesNumber = theOpportunity.NumberOfEmployees__c != null ? theOpportunity.NumberOfEmployees__c : 0;
				hiOpportunity.hiCloseDate = getLastDateofMonth(); //Yuvraj : 26-05-2020
			} else if (BENEFIT_ORDER_API_NAME.equalsIgnoreCase(Id.valueOf(currentPageId).getSObjectType().getDescribe().getName())) {
				// SJay - 10/28/2020 - Updated to include Benefit Order
				currentObject = OBJ_BENEFIT_ORDER;
				blnShowOppSection = true;
				objBenefitOrder = [SELECT ID, Name, Account__c, Opportunity__c, RecordType.Name FROM Benefit_Order__c WHERE ID = :currentPageId];

				list_CasesOnBO = [SELECT ID FROM Case WHERE Benefit_Order__c = :currentPageId AND Carrier_Order__c = NULL AND Integration_Id__c LIKE :INTEGRATION_ID_PREFIX];

				list_CallTypeOptions = new List<SelectOption>();
				list_CallTypeOptions.add(new SelectOption(CALL_TYPE_INBOUND, CALL_TYPE_INBOUND));
				list_CallTypeOptions.add(new SelectOption(CALL_TYPE_OUTBOUND, CALL_TYPE_OUTBOUND));

				list_OppCRole = new List<OpportunityContactRole>();
				if (objBenefitOrder != null && objBenefitOrder.Opportunity__c != null) {
					list_OppCRole = [
						SELECT ContactId, Role, Contact.Email, Contact.Phone
						FROM OpportunityContactRole
						WHERE OpportunityId = :objBenefitOrder.Opportunity__c AND ContactId IN (SELECT Id FROM Contact WHERE Inactive_ZP_User__c = FALSE)
					];
				}

				objCallTrackPlaceholder = new Sales_Call_Tracking__c();
				if (objBenefitOrder != null && objBenefitOrder.Id != null) {
					objCallTrackPlaceholder.RecordTypeId = SalesCallTrackingUtil.BO_RT_NAME_WITH_SALES_CALL_TRACKING_RT_IDS?.get(objBenefitOrder.RecordType.Name);
				}
			} else {
				currentObject = '';
			}
		}
		DateTimeStr = String.valueOf(System.now().format('MM/dd/yyyy, hh:mm:ss a'));
		//By:Prashant : 24-06-2020: SideBar Enhanchment : Populate Tasktype based on Profile
		taskTypeOptionsByProfile = populateTaskType();
		//Query over Custom metadata to get to know available section for an object/Profile/role
		list_mdtSmartCall = [
			SELECT
				MasterLabel,
				QualifiedApiName,
				Object_Name__c,
				Profile_Name__c,
				Role_Name__c,
				Current_Record__c,
				Follow_Up__c,
				Outbound_Email__c,
				HI_Opportunity__c,
				Inbound_Call__c,
				Payroll_Opportunity__c,
				Product_Upsell__c,
				Hi_Opp_Stages__c,
				Payroll_Opp_Stages__c,
				Close_Previous_Tasks__c,
				Do_Not_Call__c,
				Task_Type__c,
				Play_Next_Record__c,
				Additional_Info__c, // Yuvraj : 26-05-2020
				Show_No_Phone_Bad_Number__c,
				Show_Sold_Not_Sold__c
			FROM AllSmartCalling__mdt
			WHERE Object_Name__c = :currentObject AND Profile_Name__c = :userDetails.Profile.Name
		];

		if (list_mdtSmartCall.size() > 0) {
			if (list_mdtSmartCall[0].Follow_Up__c == true) {
				wrapSections.bol_FollowUpSection = true;
				wrapSections.list_taskTypeOptions = getPickListValueIntoList();
			}

			if (list_mdtSmartCall[0].Outbound_Email__c == true)
				wrapSections.bol_OutboundEmail = true;
			else
				wrapSections.bol_OutboundEmail = false;

			if (list_mdtSmartCall[0].Inbound_Call__c == true)
				wrapSections.bol_InboundCall = true;
			else
				wrapSections.bol_InboundCall = false;

			if (list_mdtSmartCall[0].HI_Opportunity__c == true)
				wrapSections.bol_HIOpsSection = true;
			else
				wrapSections.bol_HIOpsSection = false;

			if (list_mdtSmartCall[0].Payroll_Opportunity__c == true)
				wrapSections.bol_PayrollOpsSection = true;
			else
				wrapSections.bol_PayrollOpsSection = false;

			if (list_mdtSmartCall[0].Product_Upsell__c == true)
				wrapSections.bol_ProductUpsellSection = true;
			else
				wrapSections.bol_ProductUpsellSection = false;

			if (list_mdtSmartCall[0].Current_Record__c == true)
				wrapSections.bol_CurrentRecord = true;
			else
				wrapSections.bol_CurrentRecord = false;

			if (list_mdtSmartCall[0].Close_Previous_Tasks__c == true)
				wrapSections.bol_ClosePrevTasks = true;
			else
				wrapSections.bol_ClosePrevTasks = false;

			if (list_mdtSmartCall[0].Do_Not_Call__c == true)
				wrapSections.bol_DoNotCall = true;
			else
				wrapSections.bol_DoNotCall = false;

			if (list_mdtSmartCall[0].Play_Next_Record__c == true)
				wrapSections.bol_PlayNextRecord = true;
			else
				wrapSections.bol_PlayNextRecord = false;
			//Yuvraj : 26-05-2020
			if (list_mdtSmartCall[0].Additional_Info__c == true)
				wrapSections.bol_AdditionalInfo = true;
			else
				wrapSections.bol_AdditionalInfo = false;

			wrapSections.blnShowNoPhoneBadNumber = list_mdtSmartCall[0].Show_No_Phone_Bad_Number__c;
			wrapSections.blnShowSoldNotSold = list_mdtSmartCall[0].Show_Sold_Not_Sold__c;
		}

		GeneralSection(); //show general section
		if (wrapSections.bol_CurrentRecord)
			CurrentRecordSection(); //show Current Record Section
		FollowUpSection(); // show follow up section
		updateFieldFilterConditions();
	}

	public List<SelectOption> getPickListValueIntoList() {
		//str_defaultVal;
		List<SelectOption> pickListValuesList = new List<SelectOption>();
		Schema.DescribeFieldResult fieldResult = AllSmartCalling__mdt.Task_Type__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			pickListValuesList.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
		}
		return pickListValuesList;
	}

	public void updateFieldFilterConditions() {
		list_PartnerSalesPickListValueInto = new List<SelectOption>();
		List<SelectOption> list_PickListValues = new List<SelectOption>();
		List<String> list_CallPicklist = Label.Task_Call_Picklist.toLowerCase().split(',');
		Schema.DescribeFieldResult fieldResult = Task.Partner_Sales_Task_Type__c.getDescribe();
		List<Schema.PicklistEntry> list_PickListValue = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry str_PickListVal : list_PickListValue) {
			if (
				list_CallPicklist.size() > 0 &&
				list_CallPicklist.contains(str_PickListVal.getLabel().toLowerCase()) &&
				String.isNotBlank(str_taskType) &&
				(str_taskType.equalsIgnoreCase('Inbound Call') || str_taskType.equalsIgnoreCase('Outbound Call'))
			) {
				list_PartnerSalesPickListValueInto.add(new SelectOption(str_PickListVal.getLabel(), str_PickListVal.getValue()));
			} else if (String.isNotBlank(str_taskType) && !str_taskType.equalsIgnoreCase('Inbound Call') && !str_taskType.equalsIgnoreCase('Outbound Call')) {
				list_PartnerSalesPickListValueInto.add(new SelectOption(str_PickListVal.getLabel(), str_PickListVal.getValue()));
			}
		}
	}

	public void GeneralSection() {
		objOppContRole = new List<OpportunityContactRole>();
		zpUserRoleList = new List<ZP_User_Role__c>();
		zpUserRoleMap = new Map<Id, ZP_User_Role__c>();
		list_contactsList = new List<Contact>();
		contactIdToRoleMap = new Map<Id, String>();
		Set<Id> contactIdSet = new Set<Id>();

		relatedOpportunities = new List<Opportunity>();
		dispositionOptions = populateDisposition();
		// BT-17370
		list_objectiveOptions = populateCallObjectives();
		if (String.isNotBlank(currentPageId) && String.isNotBlank(currentObject)) {
			if (currentObject == 'Lead') {
				objLead = [
					SELECT Id, Name, Status, Email, Phone, MobilePhone, Secondary_Phone__c, Alternate_Phone__c, MDR_Notes__C, Description, ConvertedOpportunityId__c, ConvertedContactId__c
					FROM Lead
					WHERE Id = :currentPageId
				];
				str_leadtempVal = objLead.Status;
				//enable LTC button if phone doesn't exist.
				if (
					(objLead.Phone == '' ||
					objLead.Phone == null) &&
					(objLead.MobilePhone == '' ||
					objLead.MobilePhone == null) &&
					(objLead.Secondary_Phone__c == '' ||
					objLead.Secondary_Phone__c == null)
				) {
					displaySave = false;
					displayLtc = true;
				}
			}
			if (currentObject == 'Opportunity') {
				objOppContRole = [
					SELECT Id, Role, Contact.Id, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Title, Contact.Phone, Contact.Email, ContactId, Contact.ZP_Phone__c, Contact.MobilePhone
					FROM OpportunityContactRole
					WHERE OpportunityId = :currentPageId
				];
				//if there are no roles or 1 role and phoone is black - display LTC button instead of Save
				if (objOppContRole.size() == 0) {
					displaySave = false;
					displayLtc = true;
				} else if (objOppContRole.size() > 0) {
					Boolean hasNumber = false;
					for (OpportunityContactRole opRole : objOppContRole) {
						contactIdSet.add(opRole.Contact.Id);
						if (opRole.Contact.Phone != null || opRole.Contact.ZP_Phone__c != null || opRole.Contact.MobilePhone != null)
							hasNumber = true;
					}

					if (hasNumber == false) {
						displaySave = false;
						displayLtc = true;
					}
				}
				populateOppStage(); //Yuvraj : 19-05-2020
				if (contactIdSet.size() > 0) {
					getContactRelatedCases(contactIdSet);
				}
			}
			if (currentObject == 'Account') {
				//check if account has related opportunities
				if (theAccount.opportunities.size() > 0) {
					for (Opportunity rOpp : theAccount.opportunities) {
						relatedOpportunities.add(rOpp);
					}
				}
				if (isCXUser) {
					zpUserRoleList = [
						SELECT Id, Company_Id__c, Company_Account__c, Accounting_Firm_Id__c, Role_Name__c, Contact__c, Contact__r.Id, Contact__r.Email
						FROM ZP_User_Role__c
						WHERE
							(Company_Account__c = :currentPageId
							OR Accounting_Firm_Account__c = :currentPageId)
							AND (Role_Name__c = 'Payroll Admin'
							OR Role_Name__c = 'Primary Payroll Admin')
							AND Deleted_At__c = NULL
					];
				} else {
					zpUserRoleList = [
						SELECT
							Id,
							Company_Id__c,
							Company_Account__c,
							Accounting_Firm_Id__c,
							Role_Name__c,
							Contact__c,
							Contact__r.Id,
							Contact__r.Email,
							Contact__r.Name,
							Contact__r.FirstName,
							Contact__r.LastName,
							Contact__r.Title,
							Contact__r.Phone
						FROM ZP_User_Role__c
						WHERE
							(Company_Account__c = :currentPageId
							OR Accounting_Firm_Account__c = :currentPageId)
							AND (Role_Name__c = 'Payroll Admin'
							OR Role_Name__c = 'Primary Payroll Admin'
							OR Role_Name__c = 'Accountant')
							AND Deleted_At__c = NULL
					];
				}
				if (zpUserRoleList.size() > 0) {
					for (ZP_User_Role__c zpRel : zpUserRoleList) {
						if (zpRel.Contact__c != null) {
							contactIdSet.add(zpRel.Contact__r.Id);
							if (zpRel.Role_Name__c == 'Primary Payroll Admin')
								contactIdToRoleMap.put(zpRel.Contact__r.Id, 'Primary Payroll Admin');
							else if (zpRel.Role_Name__c == 'Payroll Admin')
								contactIdToRoleMap.put(zpRel.Contact__r.Id, 'Payroll Admin');
							else if (zpRel.Role_Name__c == 'Accountant' && !isCXUser) {
								contactIdToRoleMap.put(zpRel.Contact__r.Id, 'Accountant');
							}
						}
					}

					//if we have contact ids from acc->contact relationship (and are payroll admins) - get actual contact info.
					if (contactIdSet.size() > 0) {
						list_contactsList = [SELECT Id, Name, FirstName, LastName, Title, Phone, Email, ZP_Phone__c, MobilePhone FROM Contact WHERE Id IN :contactIdSet];
					}
					populateOppStage();
					tierUpselOptions = populateUpsellTiers();
					populateAccountingPartners();
					pointOfContactOptions = populatePointOfContacts(list_contactsList);
					if (contactIdSet.size() > 0) {
						getContactRelatedCases(contactIdSet);
					}
				}
			}
		}
	}
	//Get all cases related to each Contact
	private void getContactRelatedCases(Set<Id> contactId) {
		contactIdToCaseListMap = new Map<Id, List<Case>>();

		List<Case> contactCaseList = [SELECT Id, CaseNumber, ContactId, Type, Status, Priority, Description FROM Case WHERE ContactId IN :contactId ORDER BY CreatedDate DESC LIMIT 5];
		if (contactCaseList.size() > 0) {
			for (Case cse : contactCaseList) {
				List<Case> caseList = new List<Case>();
				if (contactIdToCaseListMap.containsKey(cse.ContactId))
					caseList = contactIdToCaseListMap.get(cse.ContactId);

				caseList.add(cse);
				contactIdToCaseListMap.put(cse.ContactId, caseList);
			}
		}
	}

	public void CurrentRecordSection() {
		String str_queryString;
		if (String.isNotBlank(currentPageId) && String.isNotBlank(currentObject)) {
			if (currentObject == 'Lead') {
				//if metadata record does not exist make leadFieldset null;
				if (list_mdtSmartCall.size() > 0) {
					lstFields = Schema.SObjectType.Lead.fieldSets.getMap().get(strProfileName).getfields();

					if (lstFields != null || lstFields.size() > 0) {
						str_queryString = 'SELECT Id,Name';
						for (Schema.FieldSetMember fld : lstFields) {
							str_queryString += ', ' + fld.getFieldPath();
						}
						str_queryString += ' from Lead WHERE ID =: currentPageId';

						leadFieldset = Database.query(str_queryString);
					}
				} else {
					leadFieldset = null;
				}

				stateOptions = new List<SelectOption>();
				stateOptions.add(new SelectOption('', ''));
				for (State__c stt : [SELECT Id, Name FROM State__c ORDER BY Name ASC]) {
					stateOptions.add(new SelectOption(stt.Name, stt.Name));
				}
			} else if (currentObject == 'Opportunity') {
				if (list_mdtSmartCall.size() > 0 && wrapSections.bol_CurrentRecord) {
					lstFields = Schema.SObjectType.Opportunity.fieldSets.getMap().get(strProfileName).getfields();
					if (lstFields != null || lstFields.size() > 0) {
						str_queryString = 'SELECT Id';
						for (Schema.FieldSetMember fld : lstFields) {
							str_queryString += ', ' + fld.getFieldPath();
						}
						str_queryString += ' from Opportunity WHERE ID =: currentPageId';
						objOpp = Database.query(str_queryString);
					}
				}
			} else if (currentObject == 'Account') {
				//Yuvraj : 18-06-2020
				if (list_mdtSmartCall.size() > 0 && Schema.SObjectType.Account.fieldSets.getMap().containskey(strProfileName)) {
					lstFields = Schema.SObjectType.Account.fieldSets.getMap().get(strProfileName).getfields();
					if (lstFields != null || lstFields.size() > 0) {
						str_queryString = 'SELECT Id';
						for (Schema.FieldSetMember fld : lstFields) {
							str_queryString += ', ' + fld.getFieldPath();
						}
						str_queryString += ' from Account WHERE ID =: currentPageId';
						objAccount = Database.query(str_queryString);
					}
				}
			}
		}
	}

	public void callbegain() {
		startTime = System.now();
	}

	public void callend() {
		endTime = System.now();
	}

	public void FollowUpSection() {
		taskTypeOptions = new List<SelectOption>();
		followTaskObj = new Task();
		//define follow up task pre populate fields
		followTaskObj.Subject = 'Follow up Call';
		followTaskObj.ActivityDate = null;
	}

	public void setDisplayCases() {
		if (caseWhoid != null && contactIdToCaseListMap.containsKey(caseWhoid))
			reRenderCases = true;
		else
			reRenderCases = false;
	}

	public class wrapperSections {
		public Boolean bol_FollowUpSection { get; set; }
		public Boolean bol_RelatedOpps { get; set; }
		public Boolean bol_PayrollOpsSection { get; set; }
		public Boolean bol_HIOpsSection { get; set; }
		public Boolean bol_ProductUpsellSection { get; set; }
		public Boolean bol_OutboundEmail { get; set; }
		public Boolean bol_InboundCall { get; set; }
		public Boolean bol_CurrentRecord { get; set; }
		public Boolean bol_DoNotCall { get; set; }
		public Boolean bol_ClosePrevTasks { get; set; }
		public List<SelectOption> list_taskTypeOptions { get; set; }
		public Boolean bol_PlayNextRecord { get; set; }
		public Boolean bol_AdditionalInfo { get; set; } //Yuvraj : 26-05-2020
		public Boolean blnShowNoPhoneBadNumber { get; set; }
		public Boolean blnShowSoldNotSold { get; set; }

		public wrapperSections() {
			bol_FollowUpSection = false;
			bol_PayrollOpsSection = false;
			bol_RelatedOpps = false;
			bol_HIOpsSection = false;
			bol_ProductUpsellSection = false;
			bol_OutboundEmail = false;
			bol_InboundCall = false;
			bol_CurrentRecord = false;
			bol_DoNotCall = false;
			bol_ClosePrevTasks = false;
			list_taskTypeOptions = new List<SelectOption>();
			bol_PlayNextRecord = false;
			bol_AdditionalInfo = false;
			blnShowNoPhoneBadNumber = false;
			blnShowSoldNotSold = false;
		}
	}

	//*************Product upsell
	public class TierUpsellWrapper {
		public String workersCompInterest { get; set; }
		public String fourOonekInterest { get; set; }
		public String twentynineInterese { get; set; }
		public String tierUpsellType { get; set; }
		public String upsellNotes { get; set; }
		public String strAccountingPartner { get; set; }

		public TierUpsellWrapper() {
		}
	}

	public void createProductUpsell() {
		Partnership_Interest__c productUpsell = new Partnership_Interest__c();
		productUpsell.RecordTypeId = Cache.getRecordTypeId('Partnership_Interest__c', 'New Partnership Interest');

		if (whoid != null && whoid != '')
			productUpsell.Contact__c = whoid;

		//if Opportunity
		if (currentObject == 'Opportunity') {
			productUpsell.Account__c = theOpportunity.AccountId;
		}
		//if Account
		if (currentObject == 'Account') {
			if (selectedPointOfContact == null || selectedPointOfContact == '') {
				if (whoid != null && whoid != '')
					selectedPointOfContact = whoid;
				else if (list_contactsList.size() > 0)
					selectedPointOfContact = list_contactsList[0].Id;
				else
					selectedPointOfContact = null;
			}
			productUpsell.Point_Of_Contact__c = selectedPointOfContact;
			productUpsell.Account__c = theAccount.Id;
			if (String.isNotBlank(upsellTier.upsellNotes)) {
				productUpsell.Upsell_Conversation_Notes__c = upsellTier.upsellNotes;
			}
			productUpsell.Upsell_Tier__c = upsellTier.tierUpsellType;
		}
		//common fields to update
		if (String.isNotBlank(upsellTier.workersCompInterest)) {
			productUpsell.Workers_Comp_Interest__c = true;
			productUpsell.Workers_Comp_Notes__c = upsellTier.workersCompInterest;
		}
		if (String.isNotBlank(upsellTier.fourOonekInterest)) {
			productUpsell.X401k_Interest__c = true;
			productUpsell.X401k_Notes__c = upsellTier.fourOonekInterest;
		}
		if (String.isNotBlank(upsellTier.twentynineInterese)) {
			productUpsell.X529_Interest__c = true;
			productUpsell.X529_Notes__c = upsellTier.twentynineInterese;
		}
		if (String.isNotBlank(upsellTier.strAccountingPartner)) {
			productUpsell.Accounting_Partner__c = upsellTier.strAccountingPartner;
		}

		insert productUpsell;
		productUpsellId = productUpsell.Id;
	}

	public List<SelectOption> populatePointOfContacts(List<Contact> contactsList) {
		List<SelectOption> pocs = new List<SelectOption>();
		pocs.add(new SelectOption('None', 'None'));

		if (contactsList.size() > 0) {
			for (Contact ct : contactsList) {
				String fullName = ct.FirstName + ' ' + ct.LastName;
				pocs.add(new SelectOption(ct.Id, fullName));
			}
		}

		return pocs;
	}

	public List<SelectOption> populateUpsellTiers() {
		List<SelectOption> tierList = new List<SelectOption>();
		tierList.add(new SelectOption('None', 'None'));
		tierList.add(new SelectOption(objTierConfig.Old_Tier_1__c, objTierConfig.Old_Tier_1__c));
		tierList.add(new SelectOption(objTierConfig.Old_Tier_2__c, objTierConfig.Old_Tier_2__c));
		tierList.add(new SelectOption(objTierConfig.Old_Tier_3__c, objTierConfig.Old_Tier_3__c));
		tierList.add(new SelectOption(objTierConfig.Old_Tier_4__c, objTierConfig.Old_Tier_4__c));
		tierList.add(new SelectOption(objTierConfig.Old_Tier_5__c, objTierConfig.Old_Tier_5__c));

		if (strNewTierSwitch == 'Yes') {
			tierList.add(new SelectOption(objTierConfig.New_Tier_1__c, objTierConfig.New_Tier_1__c));
			tierList.add(new SelectOption(objTierConfig.New_Tier_2__c, objTierConfig.New_Tier_2__c));
			tierList.add(new SelectOption(objTierConfig.Upsell_Tier_Priority_Support__c, objTierConfig.Upsell_Tier_Priority_Support__c));
			tierList.add(new SelectOption(objTierConfig.New_Tier_3__c, objTierConfig.New_Tier_3__c));
		}

		return tierList;
	}

	/*** Populate list of available accounting partners ***/
	public void populateAccountingPartners() {
		list_AccountingPartners = new List<SelectOption>();
		list_AccountingPartners.add(new SelectOption('', ''));

		Schema.DescribeFieldResult objFieldResult = Partnership_Interest__c.Accounting_Partner__c.getDescribe();
		List<Schema.PicklistEntry> list_Entries = objFieldResult.getPicklistValues();
		for (Schema.PicklistEntry objEntry : list_Entries) {
			list_AccountingPartners.add(new SelectOption(objEntry.getLabel(), objEntry.getValue()));
		}
	}

	//By:Prashant : 17-06-2020: SideBar Enhanchment : Populate Tasktype based on Profile/Role
	public List<SelectOption> populateTaskType() {
		List<SelectOption> list_taskOptions = new List<SelectOption>();

		if (userDetails.Profile.Name == 'Benefits User') {
			list_taskOptions.add(new SelectOption('New Cold Call', 'New Cold Call'));
			list_taskOptions.add(new SelectOption('Regular Call', 'Regular Call'));
			list_taskOptions.add(new SelectOption('Pitch/Demo', 'Pitch/Demo'));
		}

		if (userDetails.Profile.Name == 'MMPR User') {
			list_taskOptions.add(new SelectOption('Call', 'Call'));
			list_taskOptions.add(new SelectOption('Pitch w/o Demo', 'Pitch w/o Demo'));
			list_taskOptions.add(new SelectOption('Demo', 'Demo'));
		}

		if (currentUserRole.containsIgnoreCase('sales_sb_ob_xx') || currentUserRole.containsIgnoreCase('sales_sb_ob_sme')) {
			list_taskOptions.add(new SelectOption('Outbound Call', 'Outbound Call'));
			list_taskOptions.add(new SelectOption('Pitch/Demo', 'Pitch/Demo'));
		}

		if (currentUserRole.containsIgnoreCase('Partner')) {
			list_taskOptions.add(new SelectOption('None', 'None'));
			list_taskOptions.add(new SelectOption('Outbound Call', 'Outbound Call'));
			list_taskOptions.add(new SelectOption('Demo', 'Demo'));
			list_taskOptions.add(new SelectOption('Inbound Call', 'Inbound Call'));
			list_taskOptions.add(new SelectOption('Pitch w/o Demo', 'Pitch w/o Demo'));
			list_taskOptions.add(new SelectOption('New Cold Call', 'New Cold Call'));
			list_taskOptions.add(new SelectOption('Call', 'Call'));
			list_taskOptions.add(new SelectOption('Pitch/Demo', 'Pitch/Demo'));
		}

		return list_taskOptions;
	}

	//***************Payroll opportunity
	public class PayrollOpportutnityWrapper {
		public String oppName { get; set; }
		public String oppStage { get; set; }
		public Date oppCloseDate { get; set; }

		public PayrollOpportutnityWrapper() {
		}
	}

	public void createPayrollOpportunity() {
		if (payrollOpp.oppName != null && payrollOpp.oppStage != null && payrollOpp.oppCloseDate != null) {
			Opportunity prlOpportunity = new Opportunity();
			prlOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
			prlOpportunity.CloseDate = payrollOpp.oppCloseDate;
			prlOpportunity.StageName = payrollOpp.oppStage;
			prlOpportunity.Name = payrollOpp.oppName;
			prlOpportunity.AccountId = theAccount.Id;
			prlOpportunity.ZP_Company_ID__c = theAccount.ZP_Company_ID__c;

			AccountTriggerHelper.SkipTrigger = true;
			TaskTriggerHelper.SkipTrigger = true;
			//OpportunityTriggerHelper.SkipTrigger = true;
			insert prlOpportunity;
			AccountTriggerHelper.SkipTrigger = false;
			TaskTriggerHelper.SkipTrigger = false;
			//OpportunityTriggerHelper.SkipTrigger = false;
		} else {
			if (payrollOpp.oppName == null)
				errorMsg += ' Error : Please Select Name for Payroll Opportunity; ';
			if (payrollOpp.oppCloseDate == null)
				errorMsg += ' Error : Please Select Close Date for Payroll Opportunity ';
			if (payrollOpp.oppStage == null)
				errorMsg += ' Error : Please Select Stage for Payroll Opportunity ';
		}
	}

	//******create HI Opportunity
	public void createHIOpportunity() {
		String str_OppName = '';
		if (
			hiOpportunity.hiStage != null &&
			hiOpportunity.employeesNumber != null &&
			hiOpportunity.hiCloseDate != null &&
			hiOpportunity.hiAssignmentState != null &&
			hiOpportunity.hiOpportunityType != null
		) {
			Opportunity objHiOpp = new Opportunity();
			if (currentObject == 'Account') {
				str_OppName = theAccount.Name;
				objHiOpp.AccountId = theAccount.Id;
			}
			if (currentObject == 'Opportunity') {
				str_OppName = theOpportunity.Account.Name;
				objHiOpp.AccountId = theOpportunity.AccountId;
			}

			if (hiOpportunity.hiOpportunityType.equalsIgnoreCase('HI Benefits New Plan')) {
				objHiOpp.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
				str_OppName += ' - New Plan';
			} else if (hiOpportunity.hiOpportunityType.equalsIgnoreCase('HI Benefits BoR')) {
				objHiOpp.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
				str_OppName += ' - BoR';
			} else if (hiOpportunity.hiOpportunityType.equalsIgnoreCase('HI Benefits BYOB')) {
				objHiOpp.RecordTypeId = OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID;
				str_OppName += ' - BYOB';
			}

			objHiOpp.HI_Opportunity_Assignment_State__c = hiOpportunity.hiAssignmentState;
			objHiOpp.CloseDate = hiOpportunity.hiCloseDate;
			objHiOpp.NumberOfEmployees__c = hiOpportunity.employeesNumber;
			objHiOpp.StageName = hiOpportunity.hiStage;

			if (
				userDetails.Profile.Name == 'MMPR User' ||
				currentUserRole.containsIgnoreCase('Partner') ||
				currentUserRole.containsIgnoreCase('sales_sb_ob_xx') ||
				currentUserRole.containsIgnoreCase('sales_sb_ob_sme')
			)
				objHiOpp.Live_HI_Transfer__c = hiOpportunity.hiOppLiveTransfer; //Yuvraj 24-06-2020

			objHiOpp.Name = str_OppName;
			objHiOpp.Notes__c = hiOpportunity.hiOppNotes;
			if (objHiOpp.RecordTypeId != null) {
				AccountTriggerHelper.SkipTrigger = true;
				TaskTriggerHelper.SkipTrigger = true;
				insert objHiOpp;
				AccountTriggerHelper.SkipTrigger = false;
				TaskTriggerHelper.SkipTrigger = false;
			}
		} else {
			if (hiOpportunity.hiStage == null)
				errorMsg += ' Error : Please Select Stage for HI Opportunity; ';
			if (hiOpportunity.hiCloseDate == null)
				errorMsg += ' Error : Please Select Close Date for HI Opportunity ';
			if (hiOpportunity.hiAssignmentState == null)
				errorMsg += ' Error : Please Select State for HI Opportunity ';
		}
	}

	public void populateOppStage() {
		hiOppStageOptions = new List<SelectOption>();
		payrollOppStageOptions = new List<SelectOption>();
		List<String> list_hiOppStage = new List<String>();
		List<String> list_payrllOppStage = new List<String>();

		if (wrapSections.bol_HIOpsSection && !list_mdtSmartCall.isEmpty() && list_mdtSmartCall[0].Hi_Opp_Stages__c != null) {
			list_hiOppStage = list_mdtSmartCall[0].Hi_Opp_Stages__c.split(',');
			for (String str : list_hiOppStage) {
				if (
					str == 'Raw' //Yuvraj : 26-05-2020 default value for hi opp stage
				)
					hiOpportunity.hiStage = str;
				hiOppStageOptions.add(new SelectOption(str, str));
			}
		}
		if (wrapSections.bol_PayrollOpsSection && !list_mdtSmartCall.isEmpty() && list_mdtSmartCall[0].Payroll_Opp_Stages__c != null) {
			list_payrllOppStage = list_mdtSmartCall[0].Payroll_Opp_Stages__c.split(',');
			for (String str : list_payrllOppStage) {
				payrollOppStageOptions.add(new SelectOption(str, str));
			}
		}
	}

	//************HI Opportunity
	public class HIOpportutnityWrapper {
		public String hiStage { get; set; }
		public Decimal employeesNumber { get; set; }
		public Date hiCloseDate { get; set; }
		public String hiAssignmentState { get; set; }
		public String hiOpportunityType { get; set; }
		public String hiOppNotes { get; set; }
		public Boolean hiOppLiveTransfer { get; set; } //Yuvraj 24-06-2020

		public HIOpportutnityWrapper() {
			this.hiOppLiveTransfer = false;
		}
	}

	//*********************save method**********************
	public Pagereference save() {
		try {
			ContactTriggerHelper.skipTrigger = true;
			List<Task> list_Tasks = new List<Task>();

			if (!bln_isSaveWOCall) {
				if (String.isNotBlank(strSelectedPhoneNumber)) {
					NormalizationUtil objNormalizeController = new NormalizationUtil();
					strSelectedPhoneNumberNormalized = objNormalizeController.normalisePhoneField(strSelectedPhoneNumber);

					List<NICE_Interaction__c> list_NiceDetails = [
						SELECT Id, ContactID__c
						FROM NICE_Interaction__c
						WHERE Email_Id__c = :UserInfo.getUserEmail() AND (DNIS__c = :strSelectedPhoneNumberNormalized OR DNIS__c = :strSelectedPhoneNumber) AND CreatedDate = TODAY
						ORDER BY CreatedDate DESC
						LIMIT 1
					];

					if (list_NiceDetails?.size() == 0) {
						integrationId = '';
					} else {
						integrationId = list_NiceDetails[0].ContactID__c;
						list_Tasks = [SELECT ID FROM Task WHERE Genesys_Interaction_Id__c = :integrationId];
					}
				} else {
					apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Please select a contact before saving.'));
				}
			}
			saveTask();

			if (currentObject == 'Account') {
				updateAccount();
				if (wrapSections.bol_ClosePrevTasks)
					closePreviousOpenTasks();

				if (String.isNotBlank(followTaskObj.Subject) && followTaskObj.ActivityDate != null && wrapSections.bol_FollowUpSection == true)
					createFollowTask();
			}

			if (currentObject == 'Lead') {
				updateLead();
				if (String.isNotBlank(followTaskObj.Subject) && followTaskObj.ActivityDate != null && wrapSections.bol_FollowUpSection == true && !bol_DoNotCall)
					createFollowTask();
			}

			if (currentObject == 'Opportunity') {
				updateOpportunity();
				if (wrapSections.bol_FollowUpSection == true) {
					if (String.isNotBlank(followTaskObj.Subject) && followTaskObj.ActivityDate != null)
						createFollowTask();
				}

				if (wrapSections.bol_ProductUpsellSection) {
					if (
						whoid != null && objOppContRole != null && objOppContRole.size() > 0 && String.isNotBlank(upsellTier.workersCompInterest) ||
						String.isNotBlank(upsellTier.fourOonekInterest) ||
						String.isNotBlank(upsellTier.twentynineInterese) ||
						String.isNotBlank(upSellTier.strAccountingPartner)
					) {
						createProductUpsell();
					}
				}

				if (createHIOpp && wrapSections.bol_HIOpsSection == true) {
					createHIOpportunity();
				}
			}
			sucessMsg = 'Task Completed.';
			if (currentObject == OBJ_BENEFIT_ORDER) {
				return null;
			}
			//PAGEREFERENCE
			PageReference redirectPage = Page.LogSmartCallingPage;
			redirectPage.setRedirect(true);
			redirectPage.getParameters().put('id', currentPageId);
			return redirectPage;
		} catch (Exception e) {
			return null;
		}
	}

	//***************close previous tasks***********/
	public void closePreviousOpenTasks() {
		Map<Id, Task> mapOfOpenTasksToClose = new Map<Id, Task>();
		if (currentObject == 'Account') {
			for (Task tsk : [SELECT Id, Status FROM Task WHERE WhatId = :theAccount.Id AND (Status = 'Open' OR Status = 'Scheduled') AND Id != :objtask.Id]) {
				tsk.Status = 'Completed';
				mapOfOpenTasksToClose.put(tsk.Id, tsk);
			}
		}
		if (currentObject == 'Opportunity') {
			for (Task tsk : [SELECT Id, Status FROM Task WHERE WhatId = :theOpportunity.Id AND (Status = 'Open' OR Status = 'Scheduled') AND Id != :objtask.Id]) {
				tsk.Status = 'Completed';
				mapOfOpenTasksToClose.put(tsk.Id, tsk);
			}
		}

		if (mapOfOpenTasksToClose.size() > 0) {
			TaskTriggerHelper.SkipTrigger = true;
			update mapOfOpenTasksToClose.values();
			TaskTriggerHelper.SkipTrigger = false;
		}
	}

	//******************Create Follow up task************/
	public PageReference createFollowTask() {
		if (currentObject == 'Account') {
			if (String.isNotBlank(theAccount.Id))
				followTaskObj.WhatId = theAccount.Id;
			if (whoId != null)
				followTaskObj.WhoId = whoid;
		}
		if (currentObject == 'Opportunity') {
			if (String.isNotBlank(theOpportunity.Id))
				followTaskObj.WhatId = theOpportunity.Id;
			if (whoId != null)
				followTaskObj.WhoId = whoid;
		}
		if (currentObject == 'Lead') {
			if (String.isNotBlank(objLead.ConvertedOpportunityId__c))
				followTaskObj.WhatId = objLead.ConvertedOpportunityId__c;
			else
				followTaskObj.WhoId = objLead.Id;

			if (String.isNotBlank(objLead.ConvertedContactId__c))
				followTaskObj.WhoId = objLead.ConvertedContactId__c;
		}

		followTaskObj.Status = 'Open';
		followTaskObj.RecordTypeId = Cache.getRecordTypeId('Task', 'Standard');
		followTaskObj.OwnerId = UserInfo.getUserId();
		TaskTriggerHelper.SkipTrigger = true;
		insert followTaskObj;
		TaskTriggerHelper.SkipTrigger = false;
		sucessMsg = 'Task Created';
		return null;
	}

	//*****************Save Task**************** */
	/* Mod by 				Date 			Desc
	 * Yuvraj  				06-08-2020 		Commented objtask initialization and moved to constructor.
	 * 										https://app.asana.com/0/1165890935117693/1187772362720721
	 * Prashant Bhatt		11-08-2020		Updated the logic to create sales call tracking record when integration id exits.
	 * 										https://app.asana.com/0/1165890935117693/1187772362720721
	 * Neha Dabas		    17-11-2020		Create Call tracking for Benefits Onboarding.
	 */
	private void saveTask() {
		Boolean bol_CreateSCT = false; //yuvraj@12may
		Sales_Call_Tracking__c objSalClTrack = new Sales_Call_Tracking__c();
		List<FeedItem> list_InsertFeedItems = new List<FeedItem>();
		//BT-13670 - checking if task already exists - in case of transfer
		List<Task> list_purecloudTasks = new List<Task>();
		if (String.isNotBlank(integrationId)) {
			integrationId = integrationId.equalsIgnoreCase('undefined') ? '' : integrationId;
		}
		if (currentObject != OBJ_BENEFIT_ORDER && String.isNotBlank(integrationId) && !bln_isSaveWOCall) {
			list_purecloudTasks = [SELECT Id, CallDisposition, Description, RecordTypeId FROM Task WHERE Genesys_Interaction_Id__c = :integrationId AND CreatedById = :UserInfo.getUserId()];
			if (list_purecloudTasks != null && list_purecloudTasks.size() > 0) {
				objtask = list_purecloudTasks[0];
			}
		}

		//objtask = new Task(); //Yuvraj  06-08-2020
		objtask.CallDisposition = selDispostion;
		// BT-17370
		if (String.isNotBlank(strSelectedObjective)) {
			objtask.Primary_Call_Objective__c = strSelectedObjective;
		}
		objtask.Description = agentNotes;

		if (
			userDetails.Profile.Name == 'Benefits User' //Yuvraj : 10-06-2020
		)
			objtask.Date_Completed__c = System.now();

		//For account record
		if (currentObject == 'Account') {
			AccountTriggerHelper.SkipTrigger = true;
			TaskTriggerHelper.SkipTrigger = true;

			if (wrapSections.bol_ProductUpsellSection == true) {
				if (
					String.isNotBlank(upsellTier.workersCompInterest) ||
					String.isNotBlank(upsellTier.fourOonekInterest) ||
					String.isNotBlank(upsellTier.twentynineInterese) ||
					String.isNotBlank(upSellTier.strAccountingPartner)
				) {
					createProductUpsell();
				}
			}

			
			objtask.RecordTypeId = callRecordTypeId;

			if (wrapSections.bol_InboundCall && bol_InboundCall)
				objtask.Type = 'Inbound Call';
			else if (wrapSections.bol_OutboundEmail && bol_OutboundEmail)
				objtask.Type = 'Email';
			else
				objtask.Type = 'Outbound Call';

			if (String.isNotBlank(whoid))
				objtask.WhoId = whoid;
			objtask.WhatId = theAccount.Id;
			objSalClTrack.Account__c = theAccount.Id; // sales call tracking
			if (productUpsellId != null)
				objtask.Product_Upsell__c = productUpsellId;
		}
		//for Opportunity Page
		if (currentObject == 'Opportunity') {
			objtask.RecordTypeId = callRecordTypeId;
			if (wrapSections.bol_InboundCall == true) {
				if (bol_InboundCall) {
					objtask.Type = 'Inbound Call';
				} else {
					objtask.Type = 'Outbound Call';
				}
			} else {
				objtask.Type = 'Outbound Call';
			}
			if (String.isNotBlank(whoid))
				objtask.WhoId = whoid;
			objtask.WhatId = theOpportunity.Id;
			objSalClTrack.Opportunity__c = theOpportunity.Id; // sales call tracking
		}

		if (currentObject == 'Lead') {
			objtask.RecordTypeId = callRecordTypeId;
			objtask.WhoId = objLead.Id;
			objSalClTrack.Lead__c = objLead.Id; // sales call tracking

			if (bol_InboundCall) {
				objtask.Type = 'Inbound Call';
			} else {
				objtask.Type = 'Outbound Call';
			}

			objtask.WhatId = null;
		}
		// SJay - 10/28/2020 - Updated to include Benefit Order
		if (currentObject == OBJ_BENEFIT_ORDER) {
			FeedItem item = new FeedItem();
			objSalClTrack.Genesys_Integration_Id__c = integrationId;

			objSalClTrack.Is_PureCloud_Call__c = true;

			if (String.isNotBlank(strPhoneNumber)) {
				String strPhoneQuery = '%' + strPhoneNumber + '%';
				list_contactsList = [SELECT Id FROM Contact WHERE AccountId = :objBenefitOrder.Account__c AND Normalized_Phone__c LIKE :strPhoneQuery];
				if (list_contactsList != null && !list_contactsList.isEmpty()) {
					objSalClTrack.Contact__c = list_contactsList[0].Id;
				}
			}

			if (objBenefitOrder != null && objBenefitOrder.Id != null) {
				objSalClTrack.Benefit_Order__c = objBenefitOrder.Id;
				objSalClTrack.RecordTypeId = SalesCallTrackingUtil.BO_RT_NAME_WITH_SALES_CALL_TRACKING_RT_IDS?.get(objBenefitOrder.RecordType.Name);
			} else if (String.isNotBlank(strCurrentPageRecord)) {
				objSalClTrack.Benefit_Order__c = strCurrentPageRecord;
				Benefit_Order__c objBO = [SELECT ID, RecordType.Name FROM Benefit_Order__c WHERE ID = :strCurrentPageRecord LIMIT 1];

				if (objBO != null && objBO.Id != null) {
					objSalClTrack.RecordTypeId = SalesCallTrackingUtil.BO_RT_NAME_WITH_SALES_CALL_TRACKING_RT_IDS?.get(objBO.RecordType.Name);
				}
			}

			if (list_CasesOnBO != null && !list_CasesOnBO.isEmpty()) {
				objSalClTrack.Case__c = list_CasesOnBO.get(0).Id;
				item.ParentId = list_CasesOnBO.get(0).Id;
			}
			if (objCallTrackPlaceholder != null) {
				if (String.isNotBlank(objCallTrackPlaceholder.Was_this_a_scheduled_call_calendly__c)) {
					objSalClTrack.Was_this_a_scheduled_call_calendly__c = objCallTrackPlaceholder.Was_this_a_scheduled_call_calendly__c;
				}
				if (String.isNotBlank(objCallTrackPlaceholder.Reason_for_Call__c)) {
					objSalClTrack.Reason_for_Call__c = objCallTrackPlaceholder.Reason_for_Call__c;
				}
			}
			if (String.isNotBlank(strSelectedCallType)) {
				objSalClTrack.Call_Type__c = strSelectedCallType;
			}
			item.Type = 'TextPost';
			item.Body = 'Call log ::\n' + agentNotes;
			item.Visibility = 'AllUsers';
			//item.RelatedRecordId = tsk.Id;
			list_InsertFeedItems.add(item);
		} else {
			objSalClTrack.RecordTypeId = SCT_RECTYPE_SALES;
		}
		//update type for benefits user : yuvraj - 20-05-2020
		//MOdified BY:prashant: 24-jun-2020
		if (
			(userDetails.Profile.Name == 'Benefits User' ||
			userDetails.Profile.Name == 'MMPR User' ||
			currentUserRole.containsIgnoreCase('Partner') ||
			currentUserRole.containsIgnoreCase('sales_sb_ob_xx') ||
			currentUserRole.containsIgnoreCase('sales_sb_ob_sme')) && str_taskType != null
		) {
			objtask.Type = str_taskType;
			objtask.Partner_Sales_Task_Type__c = strPartnerTaskType;
		}

		objtask.CallType = 'Outbound';
		//Yuvraj : 10-06-2020  //modifed by:Prashant 11-june :include partner role as well
		if ((userDetails.Profile.Name == 'Benefits User' || currentUserRole.Contains('partner')) && !string.isBlank(taskSubject)) {
			//Yuvraj : 12-06-2020
			objtask.Subject = taskSubject;
		} else {
			objtask.Subject = 'Call ' + (System.now().format('MM/dd/yyyy, hh:mm:ss a'));
		}
		objtask.ActivityDate = System.today();
		if (bln_isSaveWOCall && selDispostion == null) {
			objtask.Status = 'Attempt';
		} else {
			objtask.Status = selDispostion;
		}
		if (!bln_isSaveWOCall) {
			// By :prashant :11-06-2020 : if Save W/O Call is true do not save integration id or genesys id
			objtask.CallObject = integrationId;
			objtask.Genesys_Interaction_Id__c = integrationId;
		}

		if (startTime != null && endTime != null) {
			Integer duration = Integer.valueOf(endTime.getTime() - startTime.getTime());
			objtask.CallDurationInSeconds = (duration / 1000);
		}
		//if(integrationId == '' && !bln_isSaveWOCall){ // By :prashant :11-06-2020 :include save W/O call check as well
		if (!bln_isSaveWOCall) {
			// By :prashant :11-06-2020 :include save W/O call check as well
			bol_CreateSCT = true;
			// sales call tracking object
			if (String.isNotBlank(whoid)) {
				if (currentObject != 'Lead') {
					objSalClTrack.Contact__c = whoid;
				}
				if (!String.isEmpty(integrationId)) {
					if (currentObject == 'Lead') {
						objSalClTrack.Lead__c = whoid;
					} else if (currentObject == 'Opportunity') {
						objSalClTrack.Opportunity__c = theOpportunity.Id;
					} else if (currentObject == 'Account') {
						objSalClTrack.Account__c = theAccount.Id;
					}
					objSalClTrack.Is_PureCloud_Call__c = true;
					objSalClTrack.Genesys_Integration_Id__c = integrationId;
				}
			}
			//objSalClTrack.Contact__c = whoid;
			objSalClTrack.Date_Time__c = DateTime.now();
			objSalClTrack.Owner_Role__c = userDetails.userRole.Name;
			objSalClTrack.Owner__c = userDetails.Id;
			objSalClTrack.Task_Status__c = objtask.Status;
			objSalClTrack.Task_Notes__c = objtask.Description;
		}
		//set random guid if PureCloud covnersation does not exist.
		if (currentObject != OBJ_BENEFIT_ORDER && String.isBlank(integrationId))
			objtask.Genesys_Interaction_Id__c = guid;
		//BY:Prashant:11-06-2020 : We should not upsert task based on genesys Id if Save without call is clicked .only insert should run.
		if (!bln_isSaveWOCall) {
			if (list_purecloudTasks != null && list_purecloudTasks.size() > 0) {
				update objtask;
			} else {
				insert objtask;
			}
		} else if (currentObject != OBJ_BENEFIT_ORDER) {
			insert objtask;
		}
		if (bol_CreateSCT) {
			if (currentObject != OBJ_BENEFIT_ORDER) {
				objSalClTrack.Task__c = objtask.Id;
				insert objSalClTrack;
			} else {
				if (String.isBlank(objSalClTrack.Genesys_Integration_Id__c) || UNDEFINED_VALUE.equalsIgnoreCase(objSalClTrack.Genesys_Integration_Id__c)) {
					insert objSalClTrack;
				} else {
					upsert objSalClTrack Genesys_Integration_Id__c;
				}
			}
		}
		if (list_InsertFeedItems != null && list_InsertFeedItems.size() > 0) {
			insert list_InsertFeedItems;
		}
	}

	/****************************Process LTC Activity********************** */
	public PageReference processLTCLead() {
		// Updated on :10-06-2020 : To process all data we are mimicing save functionality for LTC button https://app.asana.com/0/1165890935117693/1179358112324219
		if (userDetails.Profile.Name == 'Benefits User') {
			//  bln_isSaveWOCall = true;//Yuvraj 24-07-2020 to bypass Sales_Call_Tracking__c creation
			save();
		} else {
			Task ltcTask = new Task();
			ltcTask.CallDisposition = 'Attempt';
			ltcTask.CallType = 'Outbound';
			ltcTask.Subject = 'Attempt ' + (System.now().format('MM/dd/yyyy, hh:mm:ss a'));
			ltcTask.ActivityDate = System.today();
			ltcTask.Status = 'Attempt';
			ltcTask.Description = 'Attempt || ' + (System.now().format('MM/dd/yyyy, hh:mm:ss a')) + ' || LTC';
			ltcTask.RecordTypeId = Cache.getRecordTypeId('Task', 'Call');
			if (currentObject == 'Lead') {
				ltcTask.WhoId = objLead.Id;
				ltcTask.Lead__c = objLead.Id;
			} else if (currentObject == 'Opportunity') {
				ltcTask.WhatId = theOpportunity.Id;
			}
			insert ltcTask;
			sucessMsg = 'Task Created';
		}
		return null;
	}

	/****************************Process Task W/O Call***********************/
	/**
	 * By:Yuvraj 27-05-2020
	 * Updated By :Prashant :11-06-2020
	 * Desc : If TaskWOCAll button is clicked we will process everything as it is except we will not create sales tracking object
	 * NOTE-: we have commented existing task creation part since it is already happening in Save method.
	 */
	public PageReference processTaskWOCall() {
		bln_isSaveWOCall = true;
		save();
		return null;
	}

	/****************************Update Lead********************** */
	private void updateLead() {
		Lead objLeadTemp = [SELECT Id, Status FROM Lead WHERE Id = :objLead.Id];
		str_leadtempVal = objLeadTemp.Status;
		Lead objLeadtoUpdate = new Lead(Id = objLeadTemp.Id);
		//for every User last call and notes field will be updated.
		objLeadtoUpdate.Last_Call__c = System.today();
		objLeadtoUpdate.MDR_Notes__C = objtask.Description + '\n' + objLead.MDR_Notes__C;
		objLeadtoUpdate.PlayMode_Date__c = null;

		//if Field set exist for a profile then update fields accordingly
		if (wrapSections.bol_CurrentRecord == true) {
			if (lstFields.size() > 0) {
				for (Schema.FieldSetMember fieldset : lstFields) {
					if (fieldset.getFieldPath().contains('Status') && fieldset.getFieldPath().contains('Lead_Status_Detail__c')) {
						if (
							leadFieldset.get('Status') == 'Future Opportunity' &&
							leadFieldset.get('Lead_Status_Detail__c') == 'Feature Not Listed' ||
							leadFieldset.get('Status') == 'Unqualified' &&
							leadFieldset.get('Lead_Status_Detail__c') == 'Other'
						) {
							apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Please provide additional context about the closed reasons for this lead'));
						}
						if (leadFieldset.get('Status') == 'Unqualified' && leadFieldset.get('Lead_Status_Detail__c') == null) {
							apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Lead Status Detail is required'));
						}
						if (str_leadtempVal == 'Unqualified' && (leadFieldset.get('Status') == 'AQL' || leadFieldset.get('Status') == 'MQL')) {
							apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A lead in Unqualified cannot go back to MQL or AQL'));
						}
					}
					objLeadtoUpdate.put(fieldset.getFieldPath(), leadFieldset.get(fieldset.getFieldPath()));
				}
			}
		}
		//check do not call check box
		if (bol_DoNotCall) {
			//yuvraj@12may to check donotcall and update lead
			objLeadtoUpdate.DoNotCall = true;
			objLeadtoUpdate.Status = 'Unqualified';
			objLeadtoUpdate.Lead_Status_Detail__c = 'Bad Phone';
		}
		Database.SaveResult results = Database.update(objLeadtoUpdate);

		if (!results.isSuccess()) {
			Database.Error[] errs = results.getErrors();
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, errs[0].getMessage()));
			String strFields = '';
			for (String strField : errs[0].getFields()) {
				strFields += strField + ', ';
			}
		} else {
			sucessMsg = 'Task Completed.';
		}
	}

	/****************************Update Account******************* */
	private void updateAccount() {
		if (theAccount != null) {
			Account objAccountToUpdate = new Account(Id = theAccount.Id); //Yuvraj : 18-06-2020
			if (isCXUser) {
				objAccountToUpdate.CS_Notes__c = objtask.Description + '\n' + theAccount.CS_Notes__c;
			} else {
				objAccountToUpdate.SDR_Notes__c = objtask.Description + '\n' + theAccount.SDR_Notes__c;
				objAccountToUpdate.Last_Activity_Date__c = System.today();
			}

			if (wrapSections.bol_CurrentRecord == true) {
				if (lstFields.size() > 0) {
					for (Schema.FieldSetMember fieldset : lstFields) {
						objAccountToUpdate.put(fieldset.getFieldPath(), objAccount.get(fieldset.getFieldPath()));
					}
				}
			} //Yuvraj : 18-06-2020
			AccountTriggerHelper.skipTrigger = true;
			Database.SaveResult results = Database.update(objAccountToUpdate);
			if (!results.isSuccess()) {
				Database.Error[] errs = results.getErrors();
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, errs[0].getMessage()));
				String strFields = '';
				for (String strField : errs[0].getFields()) {
					strFields += strField + ', ';
				}
			} else {
				//Yuvraj : 09-06-2020 to updating benefits notes on eligible opportunities for benefits users
				if (userDetails.Profile.Name == 'Benefits User') {
					List<Opportunity> list_benfitsOpp = queryBenefitsOpp(new Set<Id>{ theAccount.Id });

					for (Opportunity objOpp : list_benfitsOpp) {
						if (String.isNotBlank(theAccount.Benefits_Notes__c))
							objOpp.Benefits_Notes__c = theAccount.Benefits_Notes__c;
					}
					if (list_benfitsOpp.size() > 0) {
						OpportunityTriggerHelper.skipTrigger = true;
						update list_benfitsOpp;
						OpportunityTriggerHelper.skipTrigger = false;
					}
				}
				sucessMsg = 'Task Completed.';
			}
		}

		AccountTriggerHelper.SkipTrigger = false;
		TaskTriggerHelper.SkipTrigger = false;

		if (createHIOpp && wrapSections.bol_HIOpsSection == true) {
			createHIOpportunity();
		}

		if (createPayrollOpp && wrapSections.bol_PayrollOpsSection == true) {
			createPayrollOpportunity();
		}
	}

	/****************************Update Opportunity*************** */
	private void updateOpportunity() {
		//check if any Field set exist for current profile if Current record Section is seleted from custom metatdata
		//OpportunitytriggerHelper.SkipTrigger = true;
		Opportunity objOppToUpdate = new Opportunity(Id = theOpportunity.Id);
		objOppToUpdate.Description = objtask.Description + '\n' + theOpportunity.Description;
		objOppToUpdate.Last_Call__c = System.today();
		objOppToUpdate.Playmode_Date__c = null;
		//Yuvraj : 19 - 05-2020 opportuity info section
		if (wrapSections.bol_AdditionalInfo) {
			objOppToUpdate.No_Phone_Bad_Number__c = theOpportunity.No_Phone_Bad_Number__c;
			objOppToUpdate.Sold_Not_Sold__c = theOpportunity.Sold_Not_Sold__c;
		}
		//Yuvraj : 20-05-2020 updating Benefits_Notes__c field for benefits user
		if (userDetails.Profile.Name == 'Benefits User') {
			if (
				String.isNotBlank(theOpportunity.Benefits_Notes__c) &&
				theOpportunity.IsClosed == false &&
				(theOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
				theOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			)
				objOppToUpdate.Benefits_Notes__c = theOpportunity.Benefits_Notes__c;
		}

		//In case there are open tasks for current opportunity - close them out before logging new task for current call.
		if (wrapSections.bol_ClosePrevTasks)
			closePreviousOpenTasks();

		update objOppToUpdate;

		//update account for Benfits Notes
		if (
			userDetails.Profile.Name == 'Benefits User' &&
			String.isNotBlank(theOpportunity.Benefits_Notes__c) &&
			theOpportunity.IsClosed == false &&
			(theOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
			theOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
		) {
			Account objAcc = [SELECT Id, Benefits_Notes__c FROM Account WHERE Id = :theOpportunity.AccountId];
			if (objAcc != null) {
				objAcc.Benefits_Notes__c = theOpportunity.Benefits_Notes__c;
				AccountTriggerHelper.skipTrigger = true;
				update objAcc;
				AccountTriggerHelper.skipTrigger = false;
			}
		}
	}
	//populate disposition picklist
	public List<SelectOption> populateDisposition() {
		dispositionOptions = new List<SelectOption>();
		dispositionOptions.add(new SelectOption('', ''));
		dispositionOptions.add(new SelectOption('Attempt', 'Attempt'));
		dispositionOptions.add(new SelectOption('Voicemail', 'Voicemail'));
		dispositionOptions.add(new SelectOption('Connect', 'Connect'));
		return dispositionOptions;
	}

	/*
	 * Author: Debasmita
	 * Date:   07-07-2021
	 * Desc :  Adding Call Objectives field for BT-17370
	 */
	public List<SelectOption> populateCallObjectives() {
		List<SelectOption> list_SelectOptions = new List<SelectOption>();
		Schema.DescribeFieldResult fieldResult = Task.Primary_Call_Objective__c.getDescribe();
		List<Schema.PicklistEntry> list_PickListValues = fieldResult.getPicklistValues();
		list_SelectOptions.add(new SelectOption('', ''));
		for (Schema.PicklistEntry pickListVal : list_PickListValues) {
			list_SelectOptions.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
		}
		return list_SelectOptions;
	}

	/*
	 * By: Yuvraj : 26-05-2020
	 * Desc : to get last day date of current month
	 */
	public Date getLastDateofMonth() {
		Integer numberOfDays = Date.daysInMonth(date.today().year(), date.today().month());
		Date lastDayOfMonth = Date.newInstance(date.today().year(), date.today().month(), numberOfDays);
		return lastDayOfMonth;
	}

	/*** Query Benefits Opportunities ****/
	public static List<Opportunity> queryBenefitsOpp(Set<Id> set_AccId) {
		List<Opportunity> list_oppResult = new List<Opportunity>();
		Id newPlanBenefitRecordType = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Id boRBenefitRecordType = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');

		return [
			SELECT Id, StageName, IsClosed, AccountId, Benefits_Notes__c
			FROM Opportunity
			WHERE AccountId IN :set_AccId AND IsClosed = FALSE AND (RecordTypeId = :newPlanBenefitRecordType OR RecordTypeId = :boRBenefitRecordType)
		];
	}
}