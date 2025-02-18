/*
 * Description: Contains methods related saving a case, retrieving dynamic fields etc
 * Author: Praveeen Sethu
 * Date: 09/16/2020
 */
public without sharing class EngagementCaseViewExtension_LEX {
	public static String strProductArea;
	public static String strSubProductArea;
	public static Boolean blnIsInitLoad = false;
	public static String strLwcPageName;
	public static final String TYPE_TAX_RES = 'Tax Res';
	public static final String CASE_STATUS_READY_FOR_DATA_CAPTURE = 'Ready for Data Capture';
	public static final String CASE_STATUS_SOLVED = 'Solved';
	public static final String SOLVE_CASE = 'Solve Case';
	public static final String StrEngagementType = CaseUtils.TYPE_ENGAGEMENT;
	/* Wrapper class to share data between Apex and LWC */
	public class CaseWrapper {
		@AuraEnabled
		public Case objCase;

		@AuraEnabled
		public Map<String, Map<Id, String>> map_caseReasonToGroupMap;

		@AuraEnabled
		public Map<Id, String> map_caseReasonIdToTypeMap;

		@AuraEnabled
		public Case_Action_Fields__c list_caseActionField;

		@AuraEnabled
		public List<String> list_subCaseReasons;

		@AuraEnabled
		public User_Preference__c objUserPreference;

		@AuraEnabled
		public Map<Id, Map<String, Boolean>> map_RequiredFieldsByCaseReason;
	}

	public class CaseAuraResponse {
		@AuraEnabled
		public Boolean blnIsSuccess;

		@AuraEnabled
		public String strMessage;

		@AuraEnabled
		public Case objCase;

		public CaseAuraResponse(Boolean blnIsSuccess, String strMessage) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
		}
	}

	public class ProductAndSubproductAreaWrapper {
		@AuraEnabled
		public List<Product_Area__c> list_ProductArea;

		@AuraEnabled
		public List<Sub_Product_Area__c> list_SubproductArea;
	}

	/**
    Description: Fetches Product Area, Sub Product Area options on page load
    By: Elavarasan Nagarathinam
    Params: None
    Return:  ProductAndSubproductAreaWrapper (wrapper class)
    **/
	@AuraEnabled(cacheable=true)
	public static ProductAndSubproductAreaWrapper getProductSubproductArea() {
		ProductAndSubproductAreaWrapper objWrapper = new ProductAndSubproductAreaWrapper();
		List<Product_Area__c> list_ProductArea = new List<Product_Area__c>();
		List<Sub_Product_Area__c> list_SubproductArea = new List<Sub_Product_Area__c>();

		list_ProductArea = [SELECT Id, Name FROM Product_Area__c WHERE Name != NULL AND Name != '' ORDER BY Name];
		list_SubproductArea = [SELECT Id, Name, Product_Area__c, Product_Area__r.Name FROM Sub_Product_Area__c WHERE Name != NULL AND Name != '' ORDER BY Name];

		objWrapper.list_ProductArea = list_ProductArea;
		objWrapper.list_SubproductArea = list_SubproductArea;
		return objWrapper;
	}

	/**
    Description: Fetches Product Area, Sub Product Area based on the selected confirm case reason
    By: Elavarasan Nagarathinam
    Params: Id of the case reason classification record
    Return:  Case_Reason_Classification__c
    **/
	@AuraEnabled(cacheable=true)
	public static Case_Reason_Classification__c getCaseReasonDetails(Id idCaseReason) {
		Case_Reason_Classification__c caseReason = new Case_Reason_Classification__c();
		caseReason = [SELECT Id, Product_Area__c, Product_Area__r.Name, Sub_Product_Area__c, Sub_Product_Area__r.Name FROM Case_Reason_Classification__c WHERE Id = :idCaseReason];
		return caseReason;
	}

	/* Fetches Case Details for a Particular Case */
	/* This method is called when product area or sub product area are selected from Case Actions Component on Lightning Console. */
	/* As the case reasons should be filtered based on product area and sub product area, set those values based on the UI change. */
	@AuraEnabled(cacheable=true)
	public static CaseWrapper setCaseActionInfo(Id idCase, String strProductAreaName, String strSubProductAreaName, Boolean blnIsInitLoadValue, Boolean blnIsCalledFromRoutingCmp) {
		strProductArea = strProductAreaName;
		strSubProductArea = strSubProductAreaName;
		blnIsInitLoad = blnIsInitLoadValue;
		strLwcPageName = 'Solve Case';
		return setCaseInfo(idCase, blnIsCalledFromRoutingCmp);
	}
	/* Fetches Case Details for a Particular Case */
	/* This method is called on doInit of Case Actions Component on Lightning Console. */
	@AuraEnabled
	public static CaseWrapper setCaseInfo(Id idCase, Boolean blnIsCalledFromRoutingCmp) {
		// Initialize all objects
		CaseWrapper objWrapper = new CaseWrapper();
		List<string> list_caseReasons = new List<string>();
		Map<String, Map<Id, String>> map_caseReasonToGroupMap = new Map<String, Map<Id, String>>();
		Map<Id, String> map_caseReasonIdToTypeMap = new Map<Id, String>();
		List<Case_Reason_Classification__c> list_caseReasonClassifications = new List<Case_Reason_Classification__c>();
		Map<String, Map<Id, String>> map_caseReasonToGroupMapOrdered = new Map<String, Map<Id, String>>();
		String strRecordTypeToAdd;
		Map<String, String> map_FieldLabelToApiName = new Map<String, String>();
		Map<Id, Map<String, Boolean>> map_RequiredFieldsByCaseReason = new Map<Id, Map<String, Boolean>>();
		Map<String, Boolean> map_FieldRequiredByFieldName = new Map<String, Boolean>();
		List<String> list_CaseReasonTypes = new List<String>();

		// Check whether SObject Type is Case or LiveChatTranscript
		// Case actions component can be placed either on LiveChatTranscript or Case Record Page
		String strSObjectType = idCase.getSObjectType().getDescribe().getName();
		// If SObject Type is LiveChatTranscript, fetch Parent Case Id and override the parameter value
		if (strSObjectType.equals('LiveChatTranscript')) {
			// SOQL #1
			idCase = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :idCase].CaseId;
		}
		// Get Current Case Indo
		Case objCase = getCurrentCaseInfo(idCase);
		// Render Dynamic fields from based on config found on Case Actions object
		// SOQL #2
		objWrapper.list_caseActionField = renderDynamicFields(objCase, idCase);
		// If Confirm Case Reason is not blank, get list of confirm case reasons
		if (String.isNotBlank(objCase.Confirm_Case_Reason__c)) {
			// SOQL #3
			objWrapper.list_subCaseReasons = getConfirmSubCaseReason(objCase.Confirm_Case_Reason__c, objCase.Record_Type_Name__c);
		}
		// Set case obj wrapper
		objWrapper.objCase = objCase;

		//get all Record Types available to User
		Schema.DescribeSObjectResult objResult = Schema.SObjectType.Case;
		Map<Id, Schema.RecordTypeInfo> map_RecordTypeInfo = objResult.getRecordTypeInfosById();
		String strRecordTypeName;

		for (Id idRecordType : map_RecordTypeInfo.keySet()) {
			if (map_RecordTypeInfo.get(idRecordType).isAvailable()) {
				strRecordTypeName = map_RecordTypeInfo.get(idRecordType).getName();
				if (strRecordTypeName == 'Sales Cases') {
					strRecordTypeName = 'Sales';
				}

				if (blnIsCalledFromRoutingCmp && strRecordTypeName != 'Engagement') {
					list_CaseReasonTypes.add(strRecordTypeName);
				} else if (!blnIsCalledFromRoutingCmp) {
					list_CaseReasonTypes.add(strRecordTypeName);
				}
			}
		}

		if (String.isNotBlank(strLwcPageName) && strLwcPageName == 'Solve Case') {
			// When page loads first time, take the value from record otherwise choose the selected value from UI
			if (blnIsInitLoad) {
				strProductArea = objCase.Product_Area__c;
				strSubProductArea = objCase.Sub_Product_Area__c;
			}

			String strCaseReasonQuery = 'SELECT Id, Name, Class__c, Type__c, Default_Type__c,  Generic_Routing_Reason__c, Fields_To_Require__c, Product_Area__r.Name, Sub_Product_Area__r.Name, Case_Type_Pillar__c, Support_Level__c ';
			if (!blnIsCalledFromRoutingCmp && objCase.RecordType.Name == 'GEP CX') {
				strCaseReasonQuery += ' FROM Case_Reason_Classification__c WHERE Active__c = true AND (Type__c = \'GEP CX\')  ';
			} else if (!blnIsCalledFromRoutingCmp && objCase.RecordType.Name == CaseUtils.TYPE_ENGAGEMENT) {
				strCaseReasonQuery += ' FROM Case_Reason_Classification__c WHERE Active__c = true AND (Default_Type__c =: StrEngagementType)  ';
			} else {
				strCaseReasonQuery += ' FROM Case_Reason_Classification__c WHERE Active__c = true AND (Type__c IN :list_CaseReasonTypes OR Generic_Routing_Reason__c = true) ';
			}
			if (String.isNotBlank(strProductArea)) {
				strCaseReasonQuery += 'AND Product_Area__c = :strProductArea ';
			}

			if (String.isNotBlank(strSubProductArea)) {
				strCaseReasonQuery += 'AND Sub_Product_Area__c = :strSubProductArea ';
			}

			strCaseReasonQuery += 'ORDER BY Product_Area__r.Name NULLS LAST';
			// SOQL #4 - Get total list of case reason classification
			list_caseReasonClassifications = Database.query(strCaseReasonQuery);
		} else {
			// SOQL #4 - Get total list of case reason classification
			list_caseReasonClassifications = [
				SELECT Id, Name, Class__c, Type__c, Generic_Routing_Reason__c, Fields_To_Require__c, Case_Type_Pillar__c, Support_Level__c
				FROM Case_Reason_Classification__c
				WHERE Active__c = TRUE AND (Type__c IN :list_CaseReasonTypes OR Generic_Routing_Reason__c = TRUE)
			];
		}

		// SOQL #4 - Get total list of case reason classification
		// Arrange in such a way that all generic routing cases appear first, followed by reasons related to case record type
		// Iterate over list of case reason classification
		// Create a map of type and list of case reason classsification
		for (Case_Reason_Classification__c objCaseReason : list_caseReasonClassifications) {
			if (String.isNotBlank(strLwcPageName) && strLwcPageName == 'Solve Case') {
				if (map_caseReasonToGroupMap.containsKey(objCaseReason.Product_Area__r.Name)) {
					Map<Id, String> map_IdToCaseReasonClassification = map_caseReasonToGroupMap.get(objCaseReason.Product_Area__r.Name);
					map_IdToCaseReasonClassification.put(objCaseReason.Id, objCaseReason.Name);
					map_caseReasonToGroupMap.put(objCaseReason.Product_Area__r.Name, map_IdToCaseReasonClassification);
				} else {
					map_caseReasonToGroupMap.put(objCaseReason.Product_Area__r.Name, new Map<Id, String>{ objCaseReason.Id => objCaseReason.Name });
				}

				if (String.isNotBlank(objCaseReason.Type__c)) {
					map_caseReasonIdToTypeMap.put(objCaseReason.Id, objCaseReason.Type__c);
				}
			} else {
				if (objCaseReason.Generic_Routing_Reason__c) {
					objCaseReason.Type__c = 'Generic Routing';
				}

				if (map_caseReasonToGroupMap.containsKey(objCaseReason.Type__c)) {
					Map<Id, String> map_IdToCaseReasonClassification = map_caseReasonToGroupMap.get(objCaseReason.Type__c);
					map_IdToCaseReasonClassification.put(objCaseReason.Id, objCaseReason.Name);
					map_caseReasonToGroupMap.put(objCaseReason.Type__c, map_IdToCaseReasonClassification);
				} else {
					map_caseReasonToGroupMap.put(objCaseReason.Type__c, new Map<Id, String>{ objCaseReason.Id => objCaseReason.Name });
				}
			}

			list_caseReasons.add(objCaseReason.Name);

			if (String.isNotBlank(objCaseReason.Fields_To_Require__c)) {
				Map<String, String> map_FieldTypeByFieldName = new Map<String, String>();
				Map<String, Schema.SObjectField> map_Fields = Utils.getSObjectDescribe('Case').fields.getMap();
				for (Schema.SObjectField objSObjectField : map_Fields.Values()) {
					Schema.DescribeFieldResult objDescribeField = objSObjectField.getDescribe();
					map_FieldLabelToApiName.put(objDescribeField.getLabel(), objDescribeField.getName());
					if (String.valueOf(objDescribeField.getSOAPType()) == 'BOOLEAN') {
						map_FieldRequiredByFieldName.put(objDescribeField.getName(), false);
					} else {
						map_FieldRequiredByFieldName.put(objDescribeField.getName(), true);
					}
				}
				Map<String, Boolean> map_FieldApiNames = new Map<String, Boolean>();
				for (String strField : objCaseReason.Fields_To_Require__c.split(';')) {
					if (map_FieldLabelToApiName.keySet().contains(strField)) {
						String strFieldName = map_FieldLabelToApiName.get(strField);
						map_FieldApiNames.put(strFieldName, map_FieldRequiredByFieldName.get(strFieldName));
					}
				}
				map_RequiredFieldsByCaseReason.put(objCaseReason.Id, map_FieldApiNames);
			}
		}

		objWrapper.map_RequiredFieldsByCaseReason = map_RequiredFieldsByCaseReason;

		if (strLwcPageName != 'Solve Case') {
			// Add Generic Routing Cases first
			if (map_caseReasonToGroupMap.containsKey('Generic Routing')) {
				map_caseReasonToGroupMapOrdered.put('Generic Routing', map_caseReasonToGroupMap.get('Generic Routing'));
			}
			// Add Payroll Care and Benefits Care = Toggle the Order depending upon case record type;
			// The below condition could either add payroll care or benefits care
			if (map_caseReasonToGroupMap.containsKey(objCase.RecordType.Name)) {
				map_caseReasonToGroupMapOrdered.put(objCase.RecordType.Name, map_caseReasonToGroupMap.get(objCase.RecordType.Name));
			}
			// If Benefits Care Type is added, add Payroll Care case reason classsification and vice-versa
			if (objCase.RecordType.Name == 'Benefits Care')
				strRecordTypeToAdd = 'Payroll Care';
			else if (objCase.RecordType.Name == 'Payroll Care')
				strRecordTypeToAdd = 'Benefits Care';

			if (!String.isBlank(strRecordTypeToAdd)) {
				if (map_caseReasonToGroupMap.containsKey(strRecordTypeToAdd)) {
					map_caseReasonToGroupMapOrdered.put(strRecordTypeToAdd, map_caseReasonToGroupMap.get(strRecordTypeToAdd));
				}
			}
		}

		// Add remaining elements = iterate over original map check if key is not generic routing or payroll care or benefits care
		for (String key : map_caseReasonToGroupMap.keySet()) {
			if (!map_caseReasonToGroupMapOrdered.containsKey(key)) {
				map_caseReasonToGroupMapOrdered.put(key, map_caseReasonToGroupMap.get(key));
			}
		}
		// Ordered Map of Case Reason Classifications for Auto Complete
		objWrapper.map_caseReasonToGroupMap = map_caseReasonToGroupMapOrdered;
		objWrapper.map_caseReasonIdToTypeMap = map_caseReasonIdToTypeMap;

		// SOQL #5 - Fetch User Preference and use them for Save and Next & Solve buttons
		if (strLwcPageName != SOLVE_CASE) {
			objWrapper.objUserPreference = PlayModeCaseListControllerLightning.fetchUserPreference();
		}
		return objWrapper;
	}

	/* This methods build necessary dynamic fields configured from Case Actions object */
	/* Searchs for an active record that matches case's record type and display type as Action */
	@AuraEnabled
	public static Case_Action_Fields__c renderDynamicFields(Case objCase, Id idCase) {
		// Variable declaraions - Dynamic case object
		Case objDynamicCase = new Case();
		Set<String> set_SOQLFields = new Set<String>();
		// Searchs for an active record that matches case's record type and display type as Action
		List<Case_Action_Fields__c> list_caseActionFields = [
			SELECT Id, Configuration_Json__c
			FROM Case_Action_Fields__c
			WHERE Record_Type__c = :objCase.Record_Type_Name__c AND Display_Type__c = 'Action' AND Is_Active__c = TRUE AND SObject_Type__c = 'Case'
		];
		// If config is found, deserialize config json and process them
		if (!list_caseActionFields.isEmpty()) {
			// deserialize into list of casefieldwrapper records
			List<CaseActionsFieldConfigurationController.CaseFieldWrapper> list_caseFieldConfigWrappers = (List<CaseActionsFieldConfigurationController.CaseFieldWrapper>) System.JSON.deserialize(
				list_caseActionFields.get(0).Configuration_Json__c,
				List<CaseActionsFieldConfigurationController.CaseFieldWrapper>.class
			);
			// Create a new list = update the list as they satisfy filter criteria
			List<CaseActionsFieldConfigurationController.CaseFieldWrapper> list_serializedWrappers = new List<CaseActionsFieldConfigurationController.CaseFieldWrapper>();
			Map<String, String> fieldLabelToApiMap = CaseActionsFieldConfigurationController.getCaseFieldLabelToApiMap('Case');
			// Go over each criteria list, Fetch SObject Fields and Form a SOQL
			for (CaseActionsFieldConfigurationController.CaseFieldWrapper objWrapper : list_caseFieldConfigWrappers) {
				// If Criteria List is not nukk
				if (objWrapper.criteriaList != null) {
					// Iterate over list of criterias
					for (CaseActionsFieldConfigurationController.CaseFilterCriteria objFilterCriteria : objWrapper.criteriaList) {
						// Check for name and operator
						if (String.isNotBlank(objFilterCriteria.name) && String.isNotBlank(objFilterCriteria.operator)) {
							// If both values exist, fetch corresponding api name
							if (fieldLabelToApiMap.containsKey(objFilterCriteria.name)) {
								// Add them to set of soql fields to query
								set_SOQLFields.add(fieldLabelToApiMap.get(objFilterCriteria.name));
							}
						}
					}
				}
			}
			// If Set of SOQL fields ist not empty
			if (!set_SOQLFields.isEmpty()) {
				// Build a dynamic query = iterate over each value on the set
				String strSoqlFields = '';
				for (String eachField : set_SOQLFields) {
					strSoqlFields = strSoqlFields + ',' + eachField;
				}
				strSoqlFields = strSoqlFields.removeEnd(',');
				// Fetch dynamic case object
				String strSoqlQuery = 'SELECT Id ' + strSoqlFields + ' FROM Case WHERE Id = :idCase';
				objDynamicCase = Database.query(strSoqlQuery);
			}
			// Iterate over config wrapper list
			for (CaseActionsFieldConfigurationController.CaseFieldWrapper objWrapper : list_caseFieldConfigWrappers) {
				// Check if each wrapper has a criteria
				if (objWrapper.criteriaList != null) {
					// Assume it meets criteria
					Boolean blnIsMeetCriteria = true;
					// Iterate over criteria list
					for (CaseActionsFieldConfigurationController.CaseFilterCriteria objFilterCriteria : objWrapper.criteriaList) {
						// Check if criteria has a name and operator
						if (String.isNotBlank(objFilterCriteria.name) && String.isNotBlank(objFilterCriteria.operator)) {
							// Fetch corresponding api name from label
							if (fieldLabelToApiMap.containsKey(objFilterCriteria.name)) {
								// Value set by the user
								String strValueSetByUser = objFilterCriteria.value;
								// Value present on the case
								String strValueFetchedCase = String.valueOf(objDynamicCase.get(fieldLabelToApiMap.get(objFilterCriteria.name)));
								// If the operator is equals. Check if the criteria does not match, set meetCriteria to false
								// Same check for not equals
								if (objFilterCriteria.operator.equals('Equals')) {
									if (!strValueSetByUser.equals(strValueFetchedCase)) {
										blnIsMeetCriteria = false;
									}
								} else if (objFilterCriteria.operator.equals('Not Equals')) {
									if (strValueSetByUser.equals(strValueFetchedCase)) {
										blnIsMeetCriteria = false;
									}
								} else if (objFilterCriteria.operator.equals('Contains')) {
									if (!strValueFetchedCase.contains(strValueSetByUser)) {
										blnIsMeetCriteria = false;
									}
								} else if (objFilterCriteria.operator.equals('Not Contains')) {
									if (strValueFetchedCase.contains(strValueSetByUser)) {
										blnIsMeetCriteria = false;
									}
								} else if (objFilterCriteria.operator.equals('Contains Ignore Case')) {
									if (!strValueFetchedCase.containsIgnoreCase(strValueSetByUser)) {
										blnIsMeetCriteria = false;
									}
								} else if (objFilterCriteria.operator.equals('Not Contains Ignore Case')) {
									if (strValueFetchedCase.containsIgnoreCase(strValueSetByUser)) {
										blnIsMeetCriteria = false;
									}
								}
							}
						}
					}
					// If criteria match is still true, add them to list to serialize
					if (blnIsMeetCriteria) {
						list_serializedWrappers.add(objWrapper);
					}
				} else {
					// If there is no criteria, add them to list to serialize
					list_serializedWrappers.add(objWrapper);
				}
			}
			// Complete iteraton = Serialize filtered list and send back to Front End
			list_caseActionFields.get(0).Configuration_Json__c = System.JSON.serialize(list_serializedWrappers);
			return list_caseActionFields.get(0);
		} else {
			return null;
		}
	}

	/* Get Current Case Info */
	@AuraEnabled
	public static Case getCurrentCaseInfo(Id idCase) {
		return [
			SELECT
				Id,
				RecordTypeId,
				Savings_Complaint_Type__c,
				AccountId,
				Record_Type_Name__c,
				Reviewed_by_Dedicated_Support__c,
				Account.name,
				ContactId,
				Contact.Name,
				Followup_Needed__c,
				Benefits_and_Payroll_Care_Support_Needed__c,
				CaseNumber,
				Complaint__c,
				Contact.SSN_Last_4__c,
				Next_Steps__c,
				Related_Case__c,
				Partner_Record_Id__c,
				Shared_With__c,
				Source_of_Complaint__c,
				Carrier_Call_Required__c,
				SuppliedEmail,
				ParentId,
				Closed_Reason__c,
				Carrier__c,
				LSI__c,
				Type,
				Blocker__c,
				Summary_of_Complaint__c,
				Global_Issue__c,
				Anticipated_Effective_Date__c,
				Origin,
				Affect_Filing_Payment__c,
				CreatedDate,
				Genesys_Call_Id__c,
				Authorized_User__c,
				Jira_Id__c,
				Subject,
				Description,
				Direction__c,
				Audience__c,
				Escalation_Type__c,
				Auth__c,
				Follow_Up_Method__c,
				Follow_Up_Date__c,
				Reason,
				Priority,
				Status,
				Routing_Case_Reason__c,
				Confirm_Case_Reason__c,
				Employee_Ids__c,
				Otter_Audit_Type__c,
				Tax_Id__c,
				ContactEmail,
				Status_Detail__c,
				Requires_Action__c,
				Complaint_Method__c,
				Zendesk_Id__c,
				RecordType.Name,
				Amount__c,
				Error_Origin__c,
				Class__c,
				Non_English_Preferred_Language__c,
				OwnerId,
				Send_Survey__c,
				Skip_Survey__c,
				Routing_Group__c,
				Notice_Priority__c,
				Notice_Period__c,
				Summary_of_Resolution__c,
				Notice_Response_Deadline__c,
				Agency_Information__c,
				Root_Cause__c,
				Sub_Root_Cause__c,
				Large_Scale_Issue__c,
				Current_LSI__c,
				Account.ZP_Company_Id__c,
				Contact.ZP_User_Id__c,
				Contact.Employee_Id__c,
				Complaint_Type__c,
				Other_Case_Reason_Description__c,
				Next_Payroll_Provider__c,
				Unresponsive_Customer__c,
				Opt_Out_Updating_Phone__c,
				Large_Scale_Issue_Classification__c,
				suppliedPhone,
				Customer_Journey__c,
				Area_Impacted__c,
				Escalatedto__c,
				Process_Step__c,
				Average_FTE__c,
				POA_Info__c,
				Related_to_Incident__c,
				Confirm_Sub_Case_Reason__c,
				Owner.Name,
				Routing_Case_Reason_Classification__r.Name,
				Confirm_Case_Reason_Classification__c,
				Partner_Account__c,
				Product_Area__c,
				Sub_Product_Area__c,
				Product_Area__r.Name,
				Sub_Product_Area__r.Name,
				Channel__c,
				Reason_for_Call__c,
				Resolution__c,
				Ticket_Jira_Link__c,
				Did_the_call_drop__c,
				How_many_times_attempt_to_call_back__c,
				Re_Route_Count__c,
				Toggle__c
			FROM Case
			WHERE Id = :idCase
		];
	}

	/* This method is called when user clicks Take it from Lightning console. Updates Case Owner Id to Logged In User Id */
	@AuraEnabled
	public static CaseAuraResponse acceptCase(Case objCaseToUpdate) {
		try {
			// Set Case Owner Id to Logged In User Id
			objCaseToUpdate.OwnerId = UserInfo.getUserId();

			if (objCaseToUpdate.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
				// Set Case Status to Checklist In Progress in case of Tax Res record type
				objCaseToUpdate.Status = CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS;
			} else if (objCaseToUpdate.RecordTypeId == CaseUtils.RECTYPE_MODERN_BANK) {
				// Set Case Status to Working if it's a Modern Bank case
				objCaseToUpdate.Status = CaseUtils.STATUS_WORKING;
			} else {
				// Set Case Status to In Progress
				objCaseToUpdate.Status = CaseConstants.CASE_STATUS_IN_PROGRESS;
			}

			// Update Case
			update objCaseToUpdate;
			// Send response back and set flag to true
			CaseAuraResponse objCaseResponse = new CaseAuraResponse(true, null);
			// Get Current Case Info - Query Case and set them to response
			objCaseResponse.objCase = getCurrentCaseInfo(objCaseToUpdate.Id);
			return objCaseResponse;
		} catch (Exception objException) {
			//Skip validation rule errors since they come from bad user input
			if (!objException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
				ExceptionLogUtil.logException('EngagementCaseViewExtension_LEX', 'acceptCase', objException.getMessage(), objException.getStackTraceString());
			}

			return new CaseAuraResponse(false, objException.getMessage());
		}
	}

	/* Saves case record and changes record type and type based on confirm case reason */
	@AuraEnabled
	public static CaseAuraResponse saveCaseRecord(Case objCaseToUpdate, String strRecordType) {
		// Declare a list of case reason classifications
		List<Case_Reason_Classification__c> list_CaseReasonClassifications = new List<Case_Reason_Classification__c>();
		try {
			List<Case> list_Cases = [SELECT Id, OwnerId, Confirm_Case_Reason__c, Type, Confirm_Sub_Case_Reason_Classification__c FROM Case WHERE Id = :objCaseToUpdate.Id];

			if (!list_Cases.isEmpty()) {
				if (String.isNotBlank(objCaseToUpdate.Confirm_Sub_Case_Reason__c) && strRecordType == System.Label.Engagement_RecordType_Name) {
					List<Sub_Case_Reason_Classification__c> list_SubReason = [
						SELECT Id
						FROM Sub_Case_Reason_Classification__c
						WHERE Name = :objCaseToUpdate.Confirm_Sub_Case_Reason__c AND Active__c = TRUE AND Case_Reason__c = :objCaseToUpdate.Confirm_Case_Reason_Classification__c
						LIMIT 1
					];
					if (!list_SubReason.isEmpty() && list_SubReason != null) {
						objCaseToUpdate.Confirm_Sub_Case_Reason_Classification__c = list_SubReason[0].id;
					}
					//BTE-4205 - Automate Auto-Solve Status on Case
					if(objCaseToUpdate.Auto_Solve_Status__c == CaseUtils.AUTO_SOLVE_STATUS_ATTEMPTED){
						objCaseToUpdate.Auto_Solve_Status__c = CaseUtils.STATUS_SOLVED;
					}
				}
				objCaseToUpdate.OwnerId = list_Cases[0].OwnerId;
				String strOldCaseToUpdateType = list_Cases[0].Type;

				// Check if Confirm Case Reason is not blank
				if (String.isNotBlank(objCaseToUpdate.Confirm_Case_Reason__c)) {
					// Get correspending case reason classification record
					list_CaseReasonClassifications = [
						SELECT Id, Name, Class__c, Type__c
						FROM Case_Reason_Classification__c
						WHERE Name = :objCaseToUpdate.Confirm_Case_Reason__c AND Active__c = TRUE AND Type__c = :strRecordType
					];

					if (!list_CaseReasonClassifications?.isEmpty()) {
						if (String.isNotBlank(list_CaseReasonClassifications?.get(0)?.Type__c)) {
							if (objCaseToUpdate.Status != CaseUtils.STATUS_CLOSED) {
								// Set record type of the case
								objCaseToUpdate.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(list_CaseReasonClassifications?.get(0)?.Type__c)?.getRecordTypeId();
							}
							// Set type of the case
							if (objCaseToUpdate.RecordTypeId != CaseUtils.RECTYPE_ENGAGEMENT) {
								objCaseToUpdate.Type = list_CaseReasonClassifications?.get(0)?.Type__c;
							}
						}

						String strType = String.isNotBlank(objCaseToUpdate.Confirm_Case_Reason__c) ? objCaseToUpdate.Type : list_Cases[0].Type;
						if (objCaseToUpdate.Status != CASE_STATUS_SOLVED && strType == TYPE_TAX_RES && strOldCaseToUpdateType != TYPE_TAX_RES) {
							objCaseToUpdate.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
						}
					}
				}

				if (String.isNotBlank(objCaseToUpdate.Other_Case_Reason_Description__c)) {
					objCaseToUpdate.Other_Case_Reason_Description__c = objCaseToUpdate.Other_Case_Reason_Description__c.left(255);
				}

				// Update Case record record and set success flag to true
				update objCaseToUpdate;
				// return success
				return new CaseAuraResponse(true, 'Case saved successfully!');
			} else {
				// return the case does not exist
				return new CaseAuraResponse(false, 'The case does not exist');
			}
		} catch (Exception objException) {
			//Skip validation rule errors since they come from bad user input
			if (!objException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') && !objException.getMessage().contains('CIRCULAR_DEPENDENCY')) {
				ExceptionLogUtil.logException('EngagementCaseViewExtension_LEX', 'saveCaseRecord', objException.getMessage(), objException.getStackTraceString());
			}

			// In case of an exception, set flag to false and return exception message back to front end
			return new CaseAuraResponse(false, objException.getMessage());
		}
	}

	/* Returns a list of sub case reason corresponding to one confirm case reason */
	@AuraEnabled
	public static List<String> getConfirmSubCaseReason(String strConfirmCaseReason, String strRecordType) {
		List<String> list_SubCaseReasons = new List<String>();
		// Build a dynamic query to fetch sub case reasons
		String strSubCaseReasonQuery = 'SELECT Id, Name, Case_Reason__c, Case_Reason__r.Name FROM Sub_Case_Reason_Classification__c WHERE Active__c = TRUE AND Case_Reason__r.Name = :strConfirmCaseReason AND Case_Reason__r.Type__c = :strRecordType';
		// For Query and update the list
		for (Sub_Case_Reason_Classification__c objSubCaseReason : Database.query(strSubCaseReasonQuery)) {
			list_SubCaseReasons.add(objSubCaseReason.Name);
		}
		// Return list back to Front End
		return list_SubCaseReasons;
	}

	/**
	 * @description Returns a list of sub case reason corresponding to one confirm case reason
	 * @author      Elavarasan Nagarathinam
	 * @param       Confirm Case Reason name and the related grouping name (product area name)
	 * @return      List<String> of sub reason names
	 **/
	@AuraEnabled
	public static List<String> getConfirmSubCaseReasonByCaseReason(String strCaseReasonId) {
		List<String> list_SubCaseReasons = new List<String>();
		// Build a dynamic query to fetch sub case reasons
		String strSubCaseReasonQuery = 'SELECT Id, Name, Case_Reason__c, Case_Reason__r.Name FROM Sub_Case_Reason_Classification__c WHERE Active__c = TRUE AND Case_Reason__c = :strCaseReasonId';
		// For Query and update the list
		for (Sub_Case_Reason_Classification__c objSubCaseReason : Database.query(strSubCaseReasonQuery)) {
			list_SubCaseReasons.add(objSubCaseReason.Name);
		}
		// Return list back to Front End
		return list_SubCaseReasons;
	}

	/**
	 * @description Check eligibillity criteria for creating cases from transcript
	 * @author      Praveen Sethu
	 * @param       Transcript Id
	 * @return      Boolean returning eligibility
	 **/
	@AuraEnabled
	public static Boolean checkCaseCreateFromTranscript(Id idChatTranscript) {
		String strChatButtonName;
		try {
			LiveChatTranscript objTranscript = [SELECT Id, CaseId, LiveChatButtonId, EndTime FROM LiveChatTranscript WHERE Id = :idChatTranscript];

			if (objTranscript.LiveChatButtonId != null) {
				strChatButtonName = [SELECT Id, DeveloperName FROM LiveChatButton WHERE Id = :objTranscript.LiveChatButtonId].DeveloperName;
			}
			// If transcript is linked to wallet chatbot & no case exists, create new Modern Bank case
			if (objTranscript.EndTime == null && objTranscript.CaseId == null && strChatButtonName == 'Wallet_Chatbot') {
				return true;
			}
		} catch (Exception ex) {
			return false;
		}
		return false;
	}

	/**
	 * @description Creates case and links it to transcript
	 * @author      Praveen Sethu
	 * @param       Chat Transcript Id and Case Record Type
	 * @return      Newly created Case Id
	 **/
	@AuraEnabled
	public static String createCaseFromTranscript(Id idChatTranscript, String strRecordType) {
		String strCaseId = '';
		String strChatButtonName;
		try {
			LiveChatTranscript objTranscript = [SELECT Id, CaseId, LiveChatButtonId, ContactId, EndTime FROM LiveChatTranscript WHERE Id = :idChatTranscript];

			// Create a case and link to chat transcript
			Case objCaseToInsert = new Case(
				RecordTypeId = Cache.getRecordTypeId('Case', strRecordType),
				Type = 'Modern Bank',
				Origin = 'Gusto',
				Status = 'New',
				Priority = 'Medium',
				First_Level__c = 'wallet_chatbot',
				ContactId = objTranscript.ContactId,
				OwnerId = UserInfo.getUserId()
			);

			// insert case
			insert objCaseToInsert;

			// update live chat transcript with newly inserted case id
			objTranscript.CaseId = objCaseToInsert.Id;
			update objTranscript;

			return objCaseToInsert.Id;
		} catch (Exception ex) {
			return strCaseId;
		}
	}
	/**
	 * @description Returns user's email signature
	 * @author      Sirisha Kodi
	 * @param       Null
	 * @return      User's email signature
	 **/
    @AuraEnabled
    public static String getUserEmailSignature() {
		User userCurrent = [Select Id,Signature from User where Id=:userinfo.getuserId()];
		string userSignature = userCurrent.Signature;
		if (String.isNotBlank(userSignature)) {
        	userSignature = userSignature.replace('\n','<br>');
			return userSignature;
		}
		return '';
    }
}