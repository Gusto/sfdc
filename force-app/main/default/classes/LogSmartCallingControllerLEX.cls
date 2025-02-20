/*
 * @name         : LogSmartCallingControllerLEX
 * @author       : Alex Xiong
 * @date         : 01-11-2021
 * @description  : Controller for logSmartCallingLwcCmp
 * @test classes : LogSmartCallingControllerLEXTest
 */
public without sharing class LogSmartCallingControllerLEX {
	// only set during apex testing
	public static Boolean blnDMLException = false;
	public static Boolean blnTestException = false;
	public static Id CX_ONE_INTEGRATION_USER_ID = Configuration_Settings__c.getOrgDefaults()?.CXOne_Integration_User_Id__c;

	public static String strCallObjectiveHelpText = '';
	public static Boolean blnIsCXUser = false;
	public static Boolean blnIsBenefitsUser = false;
	// set to include 401K vendor fields
	public static Set<String> set_401FieldsAPI = new Set<String>{ LogSmartCallingUtil.FIELD_X401K_INTEREST_TYPE, LogSmartCallingUtil.FIELD_API_401K_NOTES };

	// set to include 529 vendor fields
	public static Set<String> set_529FieldsAPI = new Set<String>{ LogSmartCallingUtil.FIELD_X529_INTEREST, LogSmartCallingUtil.FIELD_API_529_NOTES };

	// set to include Ardius vendor fields
	public static Set<String> set_ArdiusFieldsAPI = new Set<String>{ LogSmartCallingUtil.FIELD_ARDIUS, LogSmartCallingUtil.FIELD_ARDIUS_NOTES };

	// set to include Worker's comp vendor fields
	public static Set<String> set_WorkersCompFieldsAPI = new Set<String>{
		LogSmartCallingUtil.FIELD_WORKERS_COMP_INTEREST,
		LogSmartCallingUtil.FIELD_API_WORKERS_COMP_NOTES,
		LogSmartCallingUtil.FIELD_WORKERS_COMP_INTERESTPICKLIST
	};

	// fetching account's product interest picklist options
	public static Map<String, String> map_ProductInterestCountriesOptions = getPickListValuesIntoList();

	// fetching product interest country picklist options in a map
	public static Map<String, String> map_ProductInterestCountryCodeAndName = getMapCountryCodeAndName();

	public class LogSmartCallingException extends Exception {
	}

	/*
	 * @author      : Pradeep Chary
	 * @description : On load of the page, get complete details
	 */
	@AuraEnabled
	public static ResponseWrapper getOnLoadProperties(String strObjectName, String strRecordId) {
		ResponseWrapper objResponse = new ResponseWrapper();
		Map<String, International_Payroll_Countries__mdt> map_InternationalPayrollCountriesNew = new Map<String, International_Payroll_Countries__mdt>();

		//creating a new map for Employer of Record countries as we need the Country Name value here.
		if (!AccountTriggerHelper.map_InternationalPayrollCountries.isEmpty()) {
			for (International_Payroll_Countries__mdt objCountryMetadata : AccountTriggerHelper.map_InternationalPayrollCountries.values()) {
				map_InternationalPayrollCountriesNew.put(objCountryMetadata.MasterLabel, objCountryMetadata);
			}
		}
		System.debug('map_InternationalPayrollCountriesNew 53::' + map_InternationalPayrollCountriesNew);
		try {
			Id idUserId = UserInfo.getUserId();
			User objUserDetails = GlobalQueryHelper.queryActiveUsers(new Set<Id>{ idUserId })?.get(idUserId);
			String strProfileName = objUserDetails.Profile.Name;
			blnIsCXUser = strProfileName.containsIgnoreCase(LogSmartCallingUtil.PROFILE_CX_USER);

			List<AllSmartCalling__mdt> list_MdtSmartCall = queryAllSmartCalling(strObjectName, strProfileName);

			if (!list_MdtSmartCall.isEmpty()) {
				objResponse.objUserDetails = objUserDetails;
				objResponse.strMetadataProperties = JSON.serialize(list_MdtSmartCall[0]);

				if (String.isNotBlank(list_MdtSmartCall[0].Product_Upsell_Fieldset__c)) {
					objResponse.list_ProductUpsellProperties = getProductUpsellProperties(list_MdtSmartCall[0].Product_Upsell_Fieldset__c);
				}

				getObjectProperties(objResponse, list_MdtSmartCall[0], strObjectName, strProfileName);

				objResponse.list_States = getStates();

				//preparing map of selected options
				objResponse.map_PICountryOptions.putAll(map_ProductInterestCountriesOptions);

				if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
					objResponse.list_ContactRoles = getOpportunityContactRoles(strRecordId, list_MdtSmartCall[0]);
					Opportunity objOpportunityRecord = queryOpportunity(strRecordId);
					objResponse.list_AccountContacts = queryContactsFromAccount(objOpportunityRecord.AccountId);
					objResponse.objProductInterestAccount = getProductInterestData(strRecordId, strObjectName);
				} else if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT) {
					objResponse.list_ContactRoles = getAccountContacts(strRecordId, objUserDetails);
					objResponse.objAccount = queryAccount(strRecordId);
                    objResponse.list_AccountContacts = queryContactsFromAccount(strRecordId);
					objResponse.objProductInterestAccount = objResponse.objAccount;

					if (objResponse.objAccount.RecordTypeId == LogSmartCallingUtil.COMPANY_ACCOUNT_RT_ID) {
						objResponse.map_CompanyOpportunities = queryCompanyOpportunities(strRecordId);
					} else if (objResponse.objAccount.RecordTypeId == LogSmartCallingUtil.RESELLER_ACCOUNT_RT_ID) {
						objResponse.map_CompanyAccounts = queryCompanyAccounts(strRecordId);
					}
				} else if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_LEAD) {
					objResponse.objLead = queryLead(strRecordId);
				} else if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_TICKET) {
					//Added as part of SIFA-250
					objResponse.objTicket = queryTicket(strRecordId);
					objResponse.list_ContactRoles = getOpportunityContactRoles(objResponse.objTicket.Opportunity__c, list_MdtSmartCall[0]);
				}

				// adding selected countries to list so that we can display in the log a call UI
				if (String.isNotBlank(objResponse.objProductInterestAccount.Product_Interest_Countries__c)) {
					for (String strCountry : objResponse.objProductInterestAccount.Product_Interest_Countries__c.split(';')) {
						objResponse.list_SelectedProductInterestCountries.add(strCountry);
					}
				}

				for (String strKey : map_InternationalPayrollCountriesNew.keySet()) {
					objResponse.list_SupportedCountries.add(String.valueOf(map_InternationalPayrollCountriesNew.get(strKey).MasterLabel));
				}

				if (list_MdtSmartCall[0].Show_Call_Objective__c) {
					objResponse.list_CallObjectives = String.isNotBlank(list_MdtSmartCall[0].Call_Objective_Values__c) ? list_MdtSmartCall[0].Call_Objective_Values__c.split(',') : populateCallObjectives();
					objResponse.strCallObjectiveHelpText = strCallObjectiveHelpText;
				}

				if (list_MdtSmartCall[0].Show_Partner_Sales_Type__c) {
					objResponse.map_PartnerSalesTypes = populatePartnerSalesTypes();
				}
			}
			objResponse.disableArdiusOpp = getExistingOpp(strObjectName, strRecordId);

			return objResponse;
		} catch (Exception objException) {
			ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'getOnLoadProperties', objException.getMessage(), objException.getStackTraceString());
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/**
	 * @description Method called when lead pass is initiated to be created from log a call component.
	 * @param       Id of account for which data needs to be fetched.
	 * @return      Account details and product upsell data to be returned.
	 **/
	@AuraEnabled
	public static ResponseWrapper getLeadPassDetails(String strAccountId) {
		ResponseWrapper objResponse = new ResponseWrapper();
		Map<String, International_Payroll_Countries__mdt> map_InternationalPayrollCountriesNew = new Map<String, International_Payroll_Countries__mdt>();

		//creating a new map for Employer of Record countries as we need the Country Name value here.
		if (!AccountTriggerHelper.map_InternationalPayrollCountries.isEmpty()) {
			for (International_Payroll_Countries__mdt objCountryMetadata : AccountTriggerHelper.map_InternationalPayrollCountries.values()) {
				map_InternationalPayrollCountriesNew.put(objCountryMetadata.Country_Name__c, objCountryMetadata);
			}
		}
		try {
			//Fetching all unsupported countries from product upsells to determine what have already been sent to Remote
			Set<String> set_CountriesSentToRemote = new Set<String>();
			List<Partnership_Interest__c> list_ProductUpsell = [
				SELECT Id, Account__c, Product_Interest_Countries__c, Account__r.Product_Interest_Countries__c
				FROM Partnership_Interest__c
				WHERE Product_Interest_Countries__c != NULL AND Account__c = :strAccountId
			];
			for (Partnership_Interest__c objProductUpsell : list_ProductUpsell) {
				if (String.isNotBlank(objProductUpsell.Product_Interest_Countries__c)) {
					for (String strCountry : objProductUpsell.Product_Interest_Countries__c.split(';')) {
						set_CountriesSentToRemote.add(strCountry);
					}
				}
			}
			if (!set_CountriesSentToRemote.isEmpty()) {
				objResponse.list_CountriesSentToRemote = new List<String>(set_CountriesSentToRemote);
			}
			objResponse.list_ProductInterestCountryOptions.addAll(map_ProductInterestCountriesOptions.values());
			objResponse.objProductInterestAccount = queryAccount(strAccountId);
			for (String strKey : map_InternationalPayrollCountriesNew.keySet()) {
				objResponse.list_SupportedCountries.add(String.valueOf(map_InternationalPayrollCountriesNew.get(strKey).Country_Name__c));
			}
			for (String strCountry : map_ProductInterestCountriesOptions.keySet()) {
				objResponse.map_AllCountries.put(map_ProductInterestCountriesOptions.get(strCountry), strCountry);
			}
			if (String.isNotBlank(objResponse.objProductInterestAccount.Product_Interest_Countries__c)) {
				for (String strCountry : objResponse.objProductInterestAccount.Product_Interest_Countries__c.split(';')) {
					objResponse.list_SelectedProductInterestCountries.add(strCountry);
				}
			}
			return objResponse;
		} catch (Exception objException) {
			ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'getLeadPassDetails', objException.getMessage(), objException.getStackTraceString());
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/*
	 * @author      : Alex Xiong
	 * @description : get contact roles for an opportunity then get the cases for each contact
	 */
	public static List<ContactRoleWithCases> getOpportunityContactRoles(String strRecordId, AllSmartCalling__mdt objAllSmartCalling) {
		List<ContactRoleWithCases> list_ContactRolesWithCases = new List<ContactRoleWithCases>();
		Set<Id> set_ContactIds = new Set<Id>();
		Map<Id, List<Case>> map_ContactIdToCases = new Map<Id, List<Case>>();

		List<OpportunityContactRole> list_OpportunityContactRoles = queryOpportunityContactRoles(strRecordId);

		if (objAllSmartCalling?.Show_Cases__c) {
			for (OpportunityContactRole contactRole : list_OpportunityContactRoles) {
				set_ContactIds.add(contactRole.ContactId);
			}

			if (!set_ContactIds.isEmpty()) {
				for (Case objCase : queryCasesBasedOnContact(set_ContactIds)) {
					if (map_ContactIdToCases.containsKey(objCase.ContactId)) {
						map_ContactIdToCases.get(objCase.ContactId).add(objCase);
					} else {
						map_ContactIdToCases.put(objCase.ContactId, new List<Case>{ objCase });
					}
				}
			}
		}

		for (OpportunityContactRole objOppConRole : list_OpportunityContactRoles) {
			ContactRoleWithCases objContactRoleWithCase = new ContactRoleWithCases();
			objContactRoleWithCase.objOptyContactRole = objOppConRole;
			objContactRoleWithCase.list_Cases = map_ContactIdToCases.containsKey(objOppConRole.ContactId) ? map_ContactIdToCases.get(objOppConRole.ContactId) : new List<Case>();

			list_ContactRolesWithCases.add(objContactRoleWithCase);
		}

		return list_ContactRolesWithCases;
	}

	/**
	 * Author: Pradeep Chary
	 * Date: 2/12/2021
	 * Desc: On load of the page, get current object details
	 **/
	public static void getObjectProperties(ResponseWrapper objResponse, AllSmartCalling__mdt objMdtSmartCall, String strObjectName, String strProfileName) {
		strProfileName = strProfileName.startsWith(LogSmartCallingUtil.UNDERSCORE)
			? strProfileName.substring(1).replace(LogSmartCallingUtil.WHITE_SPACE, LogSmartCallingUtil.UNDERSCORE)
			: strProfileName.replace(LogSmartCallingUtil.WHITE_SPACE, LogSmartCallingUtil.UNDERSCORE);

		if (objMdtSmartCall.Current_Record__c) {
			objResponse.map_CurrentObjectProperties = getFieldSetWrapper(strObjectName, strProfileName);
		}

		if (objMdtSmartCall.Additional_Info__c) {
			objResponse.map_AddtnlInfoObjectProperties = getFieldSetWrapper(strObjectName, strProfileName + LogSmartCallingUtil.ADDITIONAL_INFO);
		}
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Get Fields in the Field Set of  and SObject.
	 * @param       : strObjectName - Name of the SObject.
	 * @param       : strFieldSetName - Name of the Field Set which contains fields.
	 * @return      : Returns List of FieldSet Wrapper objects with Fields in the Field Set.
	 **/
	public static Map<String, FieldSetProperties> getFieldSetWrapper(String strObjectName, String strFieldSetName) {
		Map<String, FieldSetProperties> map_ObjectProperties = new Map<String, FieldSetProperties>();
		List<Schema.FieldSetMember> list_FieldsetMembers = LogSmartCallingUtil.getFieldsInFieldSet(strObjectName, strFieldSetName);

		if (list_FieldsetMembers != null && !list_FieldsetMembers.isEmpty()) {
			for (Schema.FieldSetMember objFieldSetMember : list_FieldsetMembers) {
				FieldSetProperties objCurrentObjectProperty = new FieldSetProperties();
				objCurrentObjectProperty.strFieldApiName = objFieldSetMember.getFieldPath();
				objCurrentObjectProperty.strFieldLabel = objFieldSetMember.getLabel();
				objCurrentObjectProperty.strFieldType = String.valueOf(objFieldSetMember.getType());
				objCurrentObjectProperty.blnFieldRequired = objFieldSetMember.getDBRequired() || objFieldSetMember.getRequired();

				map_ObjectProperties.put(objCurrentObjectProperty.strFieldApiName, objCurrentObjectProperty);
			}
		}
		return map_ObjectProperties;
	}

	/**
	 * Author: Pradeep Chary
	 * Date: 2/12/2021
	 * Desc: On load of the page, get product upsell details
	 **/
	public static List<FieldSetProperties> getProductUpsellProperties(String strProductUpsellFieldset) {
		List<Schema.FieldSetMember> list_FieldsetMembers = Schema.SObjectType.Partnership_Interest__c.fieldSets.getMap().get(strProductUpsellFieldset)?.getFields();
		List<FieldSetProperties> list_ProductUpsellProperties = new List<FieldSetProperties>();

		if (list_FieldsetMembers != null && !list_FieldsetMembers.isEmpty()) {
			for (Schema.FieldSetMember objFieldSetMember : list_FieldsetMembers) {
				FieldSetProperties objProductUpsellProperty = new FieldSetProperties();
				objProductUpsellProperty.strFieldApiName = objFieldSetMember.getFieldPath();
				objProductUpsellProperty.strFieldLabel = objFieldSetMember.getLabel();

				// creating list of different vendot fields to display in the UI.
				if (set_401FieldsAPI.contains(objProductUpsellProperty.strFieldApiName)) {
					objProductUpsellProperty.strTypeDependantCategory = LogSmartCallingUtil.TYPE_401K;
					objProductUpsellProperty.blnTypeDependant = true;
				} else if (set_529FieldsAPI.contains(objProductUpsellProperty.strFieldApiName)) {
					objProductUpsellProperty.strTypeDependantCategory = LogSmartCallingUtil.TYPE_529;
					objProductUpsellProperty.blnTypeDependant = true;
				} else if (set_ArdiusFieldsAPI.contains(objProductUpsellProperty.strFieldApiName)) {
					objProductUpsellProperty.strTypeDependantCategory = LogSmartCallingUtil.TYPE_TAXCREDITS;
					objProductUpsellProperty.blnTypeDependant = true;
				} else if (set_WorkersCompFieldsAPI.contains(objProductUpsellProperty.strFieldApiName)) {
					objProductUpsellProperty.strTypeDependantCategory = LogSmartCallingUtil.TYPE_WORKERSCOMP;
					objProductUpsellProperty.blnTypeDependant = true;
				} else {
					objProductUpsellProperty.strTypeDependantCategory = '';
				}
				objProductUpsellProperty.strFieldType = String.valueOf(objFieldSetMember.getType());

				objProductUpsellProperty.blnFieldRequired = objFieldSetMember.getDBRequired() || objFieldSetMember.getRequired();

				list_ProductUpsellProperties.add(objProductUpsellProperty);
			}
		}
		return list_ProductUpsellProperties;
	}

	/**
	 * Author: Alex
	 * Date: 1/12/2021
	 * Desc: get ZP User Role
	 **/
	public static List<ContactRoleWithCases> getAccountContacts(String strAccountId, User objUserDetails) {
		try {
			List<ContactRoleWithCases> list_ContactRolesWithCases = new List<ContactRoleWithCases>();

			List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();
			Set<Id> set_ContactIds = new Set<Id>();
			Map<Id, List<Case>> map_ContactIdToCases = new Map<Id, List<Case>>();
			Set<String> set_QueryRoleNames = new Set<String>();

			set_QueryRoleNames = blnIsCXUser
				? new Set<String>{ LogSmartCallingUtil.ROLE_PAYROLL_ADMIN, LogSmartCallingUtil.ROLE_PRIMARY_PAYROLL_ADMIN }
				: new Set<String>{ LogSmartCallingUtil.ROLE_PAYROLL_ADMIN, LogSmartCallingUtil.ROLE_PRIMARY_PAYROLL_ADMIN, LogSmartCallingUtil.ROLE_ACCOUNTANT };

			list_ZPUserRoles = queryZPUserRoles(strAccountId, set_QueryRoleNames);

			for (ZP_User_Role__c objZPRole : list_ZPUserRoles) {
				set_ContactIds.add(objZPRole.Contact__c);
			}

			if (!set_ContactIds.isEmpty()) {
				for (Case objCase : queryCasesBasedOnContact(set_ContactIds)) {
					if (map_ContactIdToCases.containsKey(objCase.ContactId)) {
						map_ContactIdToCases.get(objCase.ContactId).add(objCase);
					} else {
						map_ContactIdToCases.put(objCase.ContactId, new List<Case>{ objCase });
					}
				}
			}

			for (ZP_User_Role__c objZPRole : list_ZPUserRoles) {
				ContactRoleWithCases objContactRoleWithCase = new ContactRoleWithCases();
				objContactRoleWithCase.objAcctContact = objZPRole;
				objContactRoleWithCase.list_Cases = map_ContactIdToCases.containsKey(objZPRole.Contact__r.Id) ? map_ContactIdToCases.get(objZPRole.Contact__r.Id) : new List<Case>();

				list_ContactRolesWithCases.add(objContactRoleWithCase);
			}

			return list_ContactRolesWithCases;
		} catch (Exception objException) {
			ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'getAccountContacts', objException.getMessage(), objException.getStackTraceString());
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/**
	 * Author: Pradeep Chary
	 * Date: 1/20/2021
	 * Desc: To save the tasks
	 **/
	@AuraEnabled
	public static String saveRecords(String strDataInJson, String strMetadata, Boolean blnIsSaveWOCall, String strNiceInteraction) {
		ComponentParameters objData = String.isNotBlank(strDataInJson) ? (ComponentParameters) JSON.deserialize(strDataInJson, ComponentParameters.class) : new ComponentParameters();
		AllSmartCalling__mdt objMetadata = String.isNotBlank(strMetadata) ? (AllSmartCalling__mdt) JSON.deserialize(strMetadata, AllSmartCalling__mdt.class) : new AllSmartCalling__mdt();
		NICE_Interaction__c objNiceInteraction = String.isNotBlank(strNiceInteraction)
			? (NICE_Interaction__c) JSON.deserialize(strNiceInteraction, NICE_Interaction__c.class)
			: new NICE_Interaction__c();

		try {
			Boolean blnIsAccount = objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT;
			Boolean blnIsOpportunity = objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY;
			Boolean blnIsTicket = objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_TICKET;
			Boolean blnIsLead = objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_LEAD;
			Lead objTheLead;
			Id idUserId = UserInfo.getUserId();
			User objUserDetails = GlobalQueryHelper.queryActiveUsers(new Set<Id>{ idUserId })?.get(idUserId);
			List<Task> list_PurecloudTasks = new List<Task>();
			List<FeedItem> list_InsertFeedItems = new List<FeedItem>();
			Task objTask = new Task();
			Boolean blnCreateSCT = false;
			blnIsCXUser = objUserDetails.Profile.Name.containsIgnoreCase(LogSmartCallingUtil.PROFILE_CX_USER);
			blnIsBenefitsUser = objUserDetails.Profile.Name.containsIgnoreCase(LogSmartCallingUtil.PROFILE_BENEFITS_USER);
			List<String> list_ProductInterestCountries = new List<String>();
			List<String> list_ProductInterestCountriesName = new List<String>();
			Task objEmailTask = new Task();
			Map<String, International_Payroll_Countries__mdt> map_InternationalPayrollCountriesNew = new Map<String, International_Payroll_Countries__mdt>();

			//creating a new map for Employer of Record countries as we need the Country Name value here.
			if (!AccountTriggerHelper.map_InternationalPayrollCountries.isEmpty()) {
				for (International_Payroll_Countries__mdt objCountryMetadata : AccountTriggerHelper.map_InternationalPayrollCountries.values()) {
					map_InternationalPayrollCountriesNew.put(objCountryMetadata.MasterLabel, objCountryMetadata);
				}
			}
			if (objData.blnAddProductInterest) {
				Account objProductInterestAccountForUpdate = new Account();
				Boolean blnUpdateAccount = false;
				//querying current account data
				objProductInterestAccountForUpdate = queryAccount(objData.productInterestAccountId);
				if ((objData.strProductInterest == LogSmartCallingUtil.INTERNATIONAL_CONTRACTOR_PAYMENT_LOGACALL) || (objData.strProductInterest == LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL)) {
					String strUpsellTier = objData.strProductInterest == LogSmartCallingUtil.INTERNATIONAL_CONTRACTOR_PAYMENT_LOGACALL ? '%' + AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT + '%' : null;
					strUpsellTier = objData.strProductInterest == LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL ? '%' + AccountUtil.EMPLOYER_OF_RECORD + '%' : strUpsellTier;
					List<Opportunity> opportunitiesRelatedToAccountUpsell = [
						SELECT Id, StageName
						FROM Opportunity
						WHERE
							AccountId = :objData.productInterestAccountId
							AND RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID
							AND Upsell_Tier__c LIKE :strUpsellTier
							AND IsWon = TRUE AND IsClosed = TRUE
					];
					List<Opportunity> opportunitiesRelatedToAccountICP = [
						SELECT Id, StageName
						FROM Opportunity
						WHERE
							AccountId = :objData.productInterestAccountId
							AND RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID
							AND Upsell_Tier__c LIKE :strUpsellTier
							AND ((IsWon = TRUE AND IsClosed = TRUE) OR (IsClosed = FALSE))
					];
					if (!opportunitiesRelatedToAccountICP.isEmpty()) {
						if(objData.strProductInterest == LogSmartCallingUtil.INTERNATIONAL_CONTRACTOR_PAYMENT_LOGACALL) {
							return LogSmartCallingUtil.CROSS_SELL_OPPORTUNITY_FOR_ICP_ALREADY_EXISTS;
						}
					}
					if (!opportunitiesRelatedToAccountUpsell.isEmpty()) {
						if(objData.strProductInterest == LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL) {
							return LogSmartCallingUtil.UPSELL_OPPORTUNITY_FOR_EMPLOYER_ALREADY_EXISTS;
						}
					}
				}

				String strCurrentProductInterest = objProductInterestAccountForUpdate.Product_Interest__c;
				String strCurrentProductInterestCountries = objProductInterestAccountForUpdate.Product_Interest_Countries__c;
				// checking if current account's has the log a call product interest value
				if (String.isNotBlank(strCurrentProductInterest) && String.isNotBlank(objData.strProductInterest) && !strCurrentProductInterest.contains(objData.strProductInterest)) {
					strCurrentProductInterest += ';' + objData.strProductInterest;
					objProductInterestAccountForUpdate.Product_Interest__c = strCurrentProductInterest;
					blnUpdateAccount = true;
				}

				if (strCurrentProductInterest == null) {
					if (String.isNotBlank(objData.strProductInterest)) {
						objProductInterestAccountForUpdate.Product_Interest__c = objData.strProductInterest;
					} else {
						objProductInterestAccountForUpdate.Product_Interest__c = LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL;
					}
					blnUpdateAccount = true;
				}

				// if selected countries has value
				if (String.isNotBlank(objData.strProductInterestCountries)) {
					for (String strSelectedCountry : objData.strProductInterestCountries.split(',')) {
						list_ProductInterestCountriesName.add(strSelectedCountry);
						if (map_ProductInterestCountryCodeAndName.containsKey(strSelectedCountry)) {
							list_ProductInterestCountries.add(map_ProductInterestCountryCodeAndName.get(strSelectedCountry));
						}
					}
					// adding countries to the field
					if (!list_ProductInterestCountriesName.isEmpty()) {
						objProductInterestAccountForUpdate.Product_Interest_Countries__c = String.join(list_ProductInterestCountriesName, ';');
						blnUpdateAccount = true;
					}
				}

				if (blnUpdateAccount && objProductInterestAccountForUpdate != null) {
					objProductInterestAccountForUpdate.Id = objData.productInterestAccountId;
					AccountTriggerHelper.blnCreateProductUpsellFromCompany = false;
					update objProductInterestAccountForUpdate;
				}

				// identifier to check if product upsell should be created or not
				Boolean blnLogACallPresent = false;
				Boolean blnCountryUpdates = false;
				Boolean blnSupportedCountry = false;
				Boolean blnNewSupportedCountryAdded = false;
				Boolean blnCreateNewProductUpsell = false;
				String strProductInterestAccountIdToCheck;
				Boolean blnNewAddedCountryIsSupported = false;
				Boolean blnExistingCountryIsSupported = false;
				Boolean blnAllNewAddedCountryIsSupported = false;
				Boolean blnAllExistingCountryIsSupported = false;
				Set<String> set_NewCountries = new Set<String>();
				Set<String> set_ExistingCountries = new Set<String>();
				Set<String> set_NewSupportedCountries = new Set<String>();
				Set<String> set_ExistingSupportedCountries = new Set<String>();
				List<String> list_UnSupportedCountries = new List<String>();
				for (String strSupportedProductInterest : System.Label.Supported_Product_Interest_to_Create_Product_Upsell.split(';')) {
					if (String.isNotBlank(strCurrentProductInterest) && strCurrentProductInterest.contains(LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL)) {
						// if Account already has a log a call product interest
						blnLogACallPresent = true;
					}
				}

				// checking if Account already has the product interst countries
				for (String strCountry : list_ProductInterestCountriesName) {
					if (String.isBlank(strCurrentProductInterestCountries) || !strCurrentProductInterestCountries.contains(strCountry)) {
						blnCountryUpdates = true;
						set_NewCountries.add(strCountry);
					} else {
						set_ExistingCountries.add(strCountry);
					}

					if (map_InternationalPayrollCountriesNew.Containskey(strCountry.trim())) {
						blnSupportedCountry = true;
						if (String.isBlank(strCurrentProductInterestCountries) || !strCurrentProductInterestCountries.contains(strCountry)) {
							set_NewSupportedCountries.add(strCountry);
						} else {
							set_ExistingSupportedCountries.add(strCountry);
						}
					}

					if (!set_NewSupportedCountries.contains(strCountry) && !set_ExistingCountries.contains(strCountry)) {
						list_UnSupportedCountries.add(strCountry);
					}
				}

				if (set_NewCountries.isEmpty()) {
					blnCountryUpdates = false;
				}

				if (!set_NewCountries.isEmpty() && !set_NewSupportedCountries.isEmpty() && set_NewCountries.size() == set_NewSupportedCountries.size()) {
					blnAllNewAddedCountryIsSupported = true;
				}

				if (!set_ExistingCountries.isEmpty() && !set_ExistingSupportedCountries.isEmpty() && set_ExistingCountries.size() == set_ExistingSupportedCountries.size()) {
					blnAllExistingCountryIsSupported = true;
				}

				for (String strSupportedCountry : map_InternationalPayrollCountriesNew.keySet()) {
					if (set_NewCountries.contains(strSupportedCountry) && !blnNewAddedCountryIsSupported) {
						blnNewAddedCountryIsSupported = true;
					}

					if (set_ExistingCountries.contains(strSupportedCountry) && !blnExistingCountryIsSupported) {
						blnExistingCountryIsSupported = true;
					}
				}

				// product upsell details to create the record
				Partnership_Interest__c objProductUpsell = new Partnership_Interest__c();
				// by default value would be a picklist
				objProductUpsell.Product_Interest__c = AccountUtil.EMPLOYER_OF_RECORD;
				// adding countries to the Product upsell
				objProductUpsell.Product_Interest_Countries__c = String.join(list_UnSupportedCountries, ';');

				// adding selected contact to the Product upsell
				if (String.isNotBlank(objData.strWhoId)) {
					objProductUpsell.Contact__c = objData.strWhoId;
				}

				// Recordtype will be New Partenership interest
				objProductUpsell.RecordTypeId = LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET;

				//variable to check if any non-invoiced or open opportunity is associated to the account
				Map<String, Integer> map_AccountIdAndOpenOppCount = new Map<String, Integer>();

				if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
					//if log a call details submitted via Opportunity
					// Querying opportunity contact roles and opportunity details
					List<Opportunity> list_Opportunities = [
						SELECT Id, AccountId, IsClosed, Is_Invoiced__c, (SELECT Id FROM OpportunityContactRoles)
						FROM Opportunity
						WHERE Id = :objData.strRecordId
						LIMIT 1
					];
					if (!list_Opportunities.isEmpty()) {
						Opportunity objOpportunityDetails = list_Opportunities[0];
						if (objOpportunityDetails.OpportunityContactRoles.isEmpty()) {
							return '';
						}

						//associated account to product upsell
						objProductUpsell.Account__c = objOpportunityDetails.AccountId;
						//associated opportunity to product upsell
						objProductUpsell.Opportunity__c = objOpportunityDetails.Id;
						strProductInterestAccountIdToCheck = objOpportunityDetails.AccountId;

						objEmailTask.whatId = objData.strRecordId;
					}
				} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT) {
					//if log a call details submitted via account
					objProductUpsell.Account__c = objData.strRecordId;
					// Querying all company and Cross-Sell and Upsell opportunities from the account

					strProductInterestAccountIdToCheck = objData.strRecordId;
					objEmailTask.whatId = objData.strRecordId;
				}

				// if current opportunity is not closed or not invoiced. This is being used when supported country is present.
				if (objProductUpsell.Account__c != null) {
					for (Opportunity objOpportunity : [
						SELECT Id, AccountId, IsClosed, Is_Invoiced__c, RecordTypeId, Payment_Invoice__c
						FROM Opportunity
						WHERE AccountId = :objProductUpsell.Account__c AND (RecordTypeId = :LogSmartCallingUtil.COMPANY_OPPTY_RT_ID OR RecordTypeId = :LogSmartCallingUtil.UPSELL_OPPTY_RT_ID)
					]) {
						Boolean blnOpenOpptyFound = false;
						if (objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID && objOpportunity.Payment_Invoice__c == null) {
							// if open non-invoiced company opportunity is found, don't create the product upsell
							blnOpenOpptyFound = true;
						} else if (objOpportunity.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && !objOpportunity.IsClosed && objOpportunity.Payment_Invoice__c == null) {
							// if open non-invoiced Cross-Sell and Upsell opportunity is found,  don't create the product upsell
							blnOpenOpptyFound = true;
						}

						if (blnOpenOpptyFound) {
							map_AccountIdAndOpenOppCount.put(objOpportunity.AccountId, 1);
							break;
						} else {
							map_AccountIdAndOpenOppCount.put(objOpportunity.AccountId, 0);
						}
					}
				}

				String strmessage = '';
				/**
				 Employer of Record - Log a Call is added to Product Interest and all Product Interest Countries are not supported, then create Product Upsell and email for any countries not already sent in Product Upsell. 
				*/
				if (!blnLogACallPresent && blnCountryUpdates && !blnNewAddedCountryIsSupported && !blnExistingCountryIsSupported) {
					strmessage = 'when first time and added all non supported country';
					blnCreateNewProductUpsell = true;
				}

				/**
				 Employer of Record - Log a Call is already in Account's Product Interest and all Product Interest Countries are not supported and are either updated/changed from Log a Call or zp company with a new non supported country. Then create Product Upsell and email for any countries not already sent in Product Upsell.
				 */
				if (blnLogACallPresent && blnCountryUpdates && !blnNewAddedCountryIsSupported && !blnExistingCountryIsSupported) {
					strmessage = 'already log a call and added & existing all non supported country';
					blnCreateNewProductUpsell = true;
				}

				/**
				 Employer of Record - Log a Call is added to Product Interest and all Product Interest Countries are supported. Do not create a Product Upsell and email.
				 */

				if (!blnLogACallPresent && blnCountryUpdates && blnAllNewAddedCountryIsSupported) {
					strmessage = 'new log a call and added all supported country';
					blnCreateNewProductUpsell = false;
				}

				/**
				 Employer of Record - Log a Call already exists in Product Interest and all Product Interest Countries are supported and an update is made to add a supported country. Do not create a Product Upsell and email. 
				 */
				if (blnLogACallPresent && blnCountryUpdates && blnAllNewAddedCountryIsSupported && blnAllExistingCountryIsSupported) {
					strmessage = 'existing log a call and added all supported country';
					blnCreateNewProductUpsell = false;
				}

				/**
				 Employer of Record - Log a Call is added to Product Interest and there are supported and non-supported Product Interest Countries. Look to see if there is an Open or Closed Won/Not Invoiced Company Opportunity or Cross-Sell and Upsell Opportunity with Employer of Record (Additional Opportunity Services contains Employer of Record). If yes, then don't created Product Upsell. If no opportunities with IP open or Closed Won/Invoiced, then create Product Upsell for countries not supported.
				 */
				if (!blnLogACallPresent && blnCountryUpdates && !blnAllNewAddedCountryIsSupported && !blnAllExistingCountryIsSupported && blnNewAddedCountryIsSupported) {
					strmessage = 'new log a call and added combination';
					if (map_AccountIdAndOpenOppCount.get(strProductInterestAccountIdToCheck) == 0) {
						blnCreateNewProductUpsell = true;
					}
				}

				/**
				 Employer of Record - Log a Call is already in Product Interest and there are supported and non-supported Product Interest Countries and Product Interest Countries is updated/changed. Look to see if there is an Open or Closed Won/Not Invoiced Company Opportunity or Cross-Sell and Upsell Opportunity with Employer of Record (Additional Opportunity Services contains Employer of Record). If yes, then don't created Product Upsell. If no opportunities with IP open or Closed Won/Invoiced, then create Product Upsell for countries not supported
				 */

				if (blnLogACallPresent && blnCountryUpdates && !blnAllNewAddedCountryIsSupported && (blnNewAddedCountryIsSupported || blnExistingCountryIsSupported)) {
					strmessage = 'already log a call and added combination';
					if (map_AccountIdAndOpenOppCount.get(strProductInterestAccountIdToCheck) == 0) {
						blnCreateNewProductUpsell = true;
					}
				}

				//creating product upsell
				if (blnCreateNewProductUpsell) {
					insert objProductUpsell;
				}
			}

			if (blnIsLead) {
				objTheLead = queryLead(objData.strRecordId);

				if (
					!blnIsCXUser &&
					objTheLead.Status == LogSmartCallingUtil.LEAD_STATUS_UNQUALIFIED &&
					(objData.strLeadCurrentStatus == LogSmartCallingUtil.LEAD_STATUS_AQL ||
					objData.strLeadCurrentStatus == LogSmartCallingUtil.LEAD_STATUS_MQL)
				) {
					throw new AuraHandledException(LogSmartCallingUtil.ERROR_MSG_LEAD_CANT_GO_BACK_TO_MQL_AQL);
				}
			}

			if (objData.strObjectName != LogSmartCallingUtil.OBJ_BENEFIT_ORDER && String.isNotBlank(objNiceInteraction.ContactID__c) && !blnIsSaveWOCall) {
				list_PurecloudTasks = [
					SELECT Id, CallDisposition, Description, RecordTypeId
					FROM Task
					WHERE Genesys_Interaction_Id__c = :objNiceInteraction.ContactID__c AND CreatedById = :UserInfo.getUserId()
				];

				if (!list_PurecloudTasks.isEmpty()) {
					objTask = list_PurecloudTasks[0];
				}
			}
			objTask.CallDisposition = objData.strDisposition;

			if (String.isNotBlank(objData.strCallObjective)) {
				objTask.Primary_Call_Objective__c = objData.strCallObjective;
			}

			objTask.Description = objData.strNotes;

			if (String.isNotBlank(objData.strFeatureRequest)) {
				objTask.Feature_Request__c = String.valueOf(objData.strFeatureRequest).length() > 255 ? (String) objData.strFeatureRequest.substring(0, 256) : objData.strFeatureRequest;
			}

			if (String.isNotBlank(objData.strFeatureRequestType)) {
				objTask.Feature_Request_Type__c = objData.strFeatureRequestType;
			}

			if (objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_BENEFITS_USER) {
				objTask.Date_Completed__c = System.now();
			}

			if (blnIsAccount) {
				String strProductUpsellId;
				if (objData.blnCreateProductUpsell) {
					strProductUpsellId = createProductUpsell(objData);
				}

				objTask.RecordTypeId = LogSmartCallingUtil.callRecordTypeId;

				if (objMetadata.Inbound_Call__c && objData.blnInboundCall) {
					objTask.Type = LogSmartCallingUtil.TASK_TYPE_INBOUND_CALL;
				} else if (objMetadata.Outbound_Email__c && objData.blnOutboundEmail) {
					objTask.Type = LogSmartCallingUtil.TASK_TYPE_EMAIL;
				} else if (objData.blnOutboundCall) {
					objTask.Type = LogSmartCallingUtil.TASK_TYPE_OUTBOUND_CALL;
				} else {
					objTask.Type = LogSmartCallingUtil.TASK_TYPE_OUTBOUND_CALL;
				}

				if (String.isNotBlank(objData.strWhoId)) {
					objTask.WhoId = objData.strWhoId;
				}

				objTask.WhatId = String.isNotBlank(objData.strWhatId) ? objData.strWhatId : objData.strRecordId;

				if (String.isNotBlank(strProductUpsellId)) {
					objTask.Product_Upsell__c = strProductUpsellId;
				}
			} else if (blnIsOpportunity) {
				objTask.RecordTypeId = LogSmartCallingUtil.callRecordTypeId;
				objTask.Type = objMetadata.Show_Task_Type__c
					? objData.strTaskType
					: (objMetadata.Inbound_Call__c && objData.blnInboundCall ? LogSmartCallingUtil.TASK_TYPE_INBOUND_CALL : LogSmartCallingUtil.TASK_TYPE_OUTBOUND_CALL);

				if (String.isNotBlank(objData.strWhoId)) {
					objTask.WhoId = objData.strWhoId;

					if (objData.blnCreateProductUpsell) {
						createProductUpsell(objData);
					}
				}

				objTask.WhatId = objData.strRecordId;
			} else if (blnIsTicket) {
				//Added as part of SIFA-250
				objTask.RecordTypeId = LogSmartCallingUtil.callRecordTypeId;
				objTask.Type = objMetadata.Show_Task_Type__c
					? objData.strTaskType
					: (objMetadata.Inbound_Call__c && objData.blnInboundCall ? LogSmartCallingUtil.TASK_TYPE_INBOUND_CALL : LogSmartCallingUtil.TASK_TYPE_OUTBOUND_CALL);

				if (String.isNotBlank(objData.strWhoId)) {
					objTask.WhoId = objData.strWhoId;
				}
				objTask.WhatId = objData.strRecordId;
			} else if (blnIsLead) {
				objTask.RecordTypeId = LogSmartCallingUtil.callRecordTypeId;
				objTask.WhoId = objData.strRecordId;

				if (objData.blnInboundCall) {
					objTask.Type = LogSmartCallingUtil.TASK_TYPE_INBOUND_CALL;
				} else if (objData.blnOutboundCall) {
					objTask.Type = LogSmartCallingUtil.TASK_TYPE_OUTBOUND_CALL;
				} else {
					objTask.Type = LogSmartCallingUtil.TASK_TYPE_OUTBOUND_CALL;
				}

				objTask.WhatId = null;
			}

			if (
				objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_BENEFITS_USER ||
				objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_MMPR_USER ||
				objUserDetails.UserRole.Name.containsIgnoreCase(LogSmartCallingUtil.ROLE_PARTNER) ||
				objUserDetails.UserRole.Name.containsIgnoreCase(LogSmartCallingUtil.ROLE_SALES_SB_OB_XX) ||
				objUserDetails.UserRole.Name.containsIgnoreCase(LogSmartCallingUtil.ROLE_SALES_SB_OB_SME)
			) {
				if (objMetadata.Show_Task_Type__c && String.isNotBlank(objData.strTaskType)) {
					objTask.Type = objData.strTaskType;

					if (String.isNotBlank(objData.strPartnerSalesTaskType))
						objTask.Partner_Sales_Task_Type__c = objData.strPartnerSalesTaskType;
				}
			}

			objTask.CallType = LogSmartCallingUtil.CALL_TYPE_OUTBOUND;
			if (
				(objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_BENEFITS_USER || objUserDetails.UserRole.Name.containsIgnoreCase(LogSmartCallingUtil.ROLE_PARTNER)) &&
				(String.isNotBlank(objData.strTaskSubject) || String.isNotBlank(objData.strFollowUpSubject))
			) {
				if (String.isNotBlank(objData.strTaskSubject)) {
					objTask.Subject = objData.strTaskSubject;
				} else if (String.isNotBlank(objData.strFollowUpSubject)) {
					objTask.Subject = objData.strFollowUpSubject;
				}
			} else {
				objTask.Subject = LogSmartCallingUtil.TASK_SUBJECT_CALL + LogSmartCallingUtil.WHITE_SPACE + LogSmartCallingUtil.DATETIME_FORMATTED;
			}

			objTask.ActivityDate = System.today();
			objTask.Status = blnIsSaveWOCall && String.isBlank(objData.strDisposition) ? LogSmartCallingUtil.TASK_STATUS_ATTEMPT : objData.strDisposition;

			if (!blnIsSaveWOCall) {
				//if Save W/O Call is true do not save integration id or genesys id
				objTask.CallObject = objNiceInteraction.ContactID__c;
				objTask.Genesys_Interaction_Id__c = objNiceInteraction.ContactID__c;
			}

			if (objNiceInteraction.Call_Duration_in_Sec__c != null) {
				objTask.CallDurationInSeconds = Integer.valueOf(objNiceInteraction.Call_Duration_in_Sec__c);
			}

			if (!blnIsSaveWOCall) {
				blnCreateSCT = true;
			}

			//set random guid if PureCloud covnersation does not exist.
			if (objData.strObjectName != LogSmartCallingUtil.OBJ_BENEFIT_ORDER && String.isBlank(objNiceInteraction.ContactID__c)) {
				objTask.Genesys_Interaction_Id__c = getRandomId();
			}

			//We should not upsert task based on genesys Id if Save without call is clicked .only insert should run.
			if (!blnIsSaveWOCall) {
				//upsert objTask Genesys_Interaction_Id__c;
				if (!list_PurecloudTasks.isEmpty()) {
					update objtask;
				} else {
					insert objtask;
				}
			} else if (objData.strObjectName != LogSmartCallingUtil.OBJ_BENEFIT_ORDER) {
				if (blnIsCXUser || (String.isNotBlank(objData.strDisposition) && objData.strDisposition != LogSmartCallingUtil.TASK_DISPOSITION_NO_CALL)) {
					insert objTask;
				}
			}

			TaskTriggerHelper.SkipTrigger = false;

			if (blnIsAccount) {
				updateAccount(objData, objTask, objMetadata, objUserDetails);
			} else if (blnIsOpportunity) {
				updateOpportunity(objData, objTask, objMetadata, objUserDetails);
			} else if (blnIsLead) {
				updateLead(objData, objTheLead, objTask, objMetadata, objUserDetails);
			}

			logSmartCallingFuture(strDataInJson, objTask.Id, strMetadata, JSON.serialize(objUserDetails), strNiceInteraction, blnCreateSCT, blnIsSaveWOCall);

			if (!list_InsertFeedItems.isEmpty()) {
				insert list_InsertFeedItems;
			}
		} catch (Exception objException) {
			if (!blnTestException) {
				throw new LogSmartCallingException(objException.getMessage());
			}
		}

		return LogSmartCallingUtil.SUCCESS;
	}

	/**
	 * @description Method called from save lead pass button on log a call component.
	 * @param       Data from log a call component when save lead pass button is clicked.
	 * @return      Success / Failure response back to log a call component.
	 **/
	@AuraEnabled
	public static String saveLeadPass(String strDataInJson) {
		try {
			ComponentParameters objData = String.isNotBlank(strDataInJson) ? (ComponentParameters) JSON.deserialize(strDataInJson, ComponentParameters.class) : new ComponentParameters();
			Boolean blnUpdateAccount = false;
			List<String> list_LeadPassCountries = new List<String>();
			List<String> list_LeadPassCountriesAdditional = new List<String>();
			//Countries selected to send to remote
			if (String.isNotBlank(objData.strLeadPassCountries)) {
				for (String strLeadPassCountry : objData.strLeadPassCountries.split(',')) {
					//list_LeadPassCountries.add(map_ProductInterestCountriesOptions.get(strLeadPassCountry));
					list_LeadPassCountries.add(strLeadPassCountry);
				}
			}
			//Additional countries selected to send to remote that are not already sent or waiting to be sent
			if (String.isNotBlank(objData.strLeadPassCountriesAdditional)) {
				for (String strLeadPassCountryAdditional : objData.strLeadPassCountriesAdditional.split(',')) {
					//list_LeadPassCountriesAdditional.add(map_ProductInterestCountriesOptions.get(strLeadPassCountryAdditional));
					list_LeadPassCountriesAdditional.add(strLeadPassCountryAdditional);
					blnUpdateAccount = true;
				}
			}
			// product upsell details to create the record
			Partnership_Interest__c objProductUpsell = new Partnership_Interest__c();
			// default value
			objProductUpsell.Product_Interest__c = AccountUtil.EMPLOYER_OF_RECORD;
			List<String> list_allLeadPassCountries = new List<String>(list_LeadPassCountries);
			list_allLeadPassCountries.addAll(list_LeadPassCountriesAdditional);
			objProductUpsell.Product_Interest_Countries__c = String.join(list_allLeadPassCountries, ';');
			objProductUpsell.Contact__c = objData.strWhoId;
			objProductUpsell.RecordTypeId = LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET;
			objProductUpsell.Account__c = objData.productInterestAccountId;
			if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
				objProductUpsell.Opportunity__c = objData.strRecordId;
			}
			insert objProductUpsell;
			//If additional countries are selected, add to account
			if (blnUpdateAccount) {
				Account objAccount = queryAccount(objData.productInterestAccountId);
				Account objAccountForUpdate = new Account(Id = objAccount.Id);
				String strCurrentProductInterest = objAccount.Product_Interest__c;
				if (String.isNotBlank(strCurrentProductInterest) && String.isNotBlank(objData.strProductInterest) && !strCurrentProductInterest.contains(objData.strProductInterest)) {
					strCurrentProductInterest += ';' + objData.strProductInterest;
					objAccountForUpdate.Product_Interest__c = strCurrentProductInterest;
				}
				if (strCurrentProductInterest == null) {
					if (String.isNotBlank(objData.strProductInterest)) {
						objAccountForUpdate.Product_Interest__c = objData.strProductInterest;
					} else {
						objAccountForUpdate.Product_Interest__c = LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL;
					}
				}
				if (String.isNotBlank(objAccount.Product_Interest_Countries__c)) {
					for (String strCountry : objAccount.Product_Interest_Countries__c.split(';')) {
						if (!list_LeadPassCountriesAdditional.contains(strCountry)) {
							list_LeadPassCountriesAdditional.add(strCountry);
						}
					}
				}
				objAccountForUpdate.Product_Interest_Countries__c = String.join(list_LeadPassCountriesAdditional, ';');
				AccountTriggerHelper.blnCreateProductUpsellFromCompany = false;
				update objAccountForUpdate;
			}
		} catch (Exception objException) {
			if (!blnTestException) {
				throw new LogSmartCallingException(objException.getMessage());
			}
		}
		return LogSmartCallingUtil.SUCCESS;
	}

	/**
	 * @description : Method to update current Lead record.
	 * @param       : objData - Data from LWC component.
	 * @param       : objTheLead - Current Lead record.
	 * @param       : objTask - Task created.
	 * @param       : objMetadata - LogSmartCalling Metadata record.
	 * @param       : objUserDetails - Current User Details.
	 * @return      : NA.
	 **/
	private static void updateLead(ComponentParameters objData, Lead objTheLead, Task objTask, AllSmartCalling__mdt objMetadata, User objUserDetails) {
		if (String.isNotBlank(objData.strRecordId)) {
			//for every User last call and notes field will be updated.
			Lead objLeadToUpdate = new Lead(Id = objTheLead.Id, Last_Call__c = System.today(), PlayMode_Date__c = null);

			objLeadToUpdate.MDR_Notes__c = String.isNotBlank(objTheLead.MDR_Notes__c) ? objTask.Description + LogSmartCallingUtil.NEXT_LINE + objTheLead.MDR_Notes__c : objTask.Description;

			//if Field set exist for a profile then update fields accordingly
			if (objMetadata.Current_Record__c || objMetadata.Additional_Info__c) {
				List<FieldSetProperties> list_ObjectDetailValues = objData.list_ObjectDetailValues;

				if (list_ObjectDetailValues != null && !list_ObjectDetailValues.isEmpty()) {
					Map<String, Object> map_ObjectDetailValues = constructRecord(list_ObjectDetailValues, LogSmartCallingUtil.SOBJECT_API_NAME_LEAD);
					for (String strFieldApi : map_ObjectDetailValues.keySet()) {
						objLeadToUpdate.put(strFieldApi, map_ObjectDetailValues.get(strFieldApi));
					}
				}
			}
			//check do not call check box
			if (objData.blnDoNotCall) {
				objLeadToUpdate.DoNotCall = true;
				objLeadToUpdate.Status = LogSmartCallingUtil.LEAD_STATUS_UNQUALIFIED;
				objLeadToUpdate.Lead_Status_Detail__c = LogSmartCallingUtil.LEAD_STATUS_DETAIL_BAD_PHONE;
			}

			Database.SaveResult list_SaveResults = Database.update(objLeadToUpdate, false);
			if (!list_SaveResults.isSuccess()) {
				Database.Error[] list_Errors = list_SaveResults.getErrors();
				if (!blnTestException) {
					throw new LogSmartCallingException(list_Errors[0].getMessage());
				}
			}
		}
	}

	/**
	 * @description : Method to update current Account record.
	 * @param       : objData - Data from LWC component.
	 * @param       : objTask - Task created.
	 * @param       : objMetadata - LogSmartCalling Metadata record.
	 * @param       : objUserDetails - Current User Details.
	 * @return      : NA.
	 **/
	private static void updateAccount(ComponentParameters objData, Task objTask, AllSmartCalling__mdt objMetadata, User objUserDetails) {
		if (String.isNotBlank(objData.strRecordId)) {
			Account objTheAccount = queryAccount(objData.strRecordId);

			Account objAccountToUpdate = new Account(Id = objTheAccount.Id);
			if (blnIsCXUser) {
				objAccountToUpdate.CS_Notes__c = objTask.Description + LogSmartCallingUtil.NEXT_LINE + objTheAccount.CS_Notes__c;
			} 
			else if (blnIsBenefitsUser) {
				objAccountToUpdate.Benefits_Notes__c = (objTask.Description != null ? objTask.Description + LogSmartCallingUtil.NEXT_LINE : '') + (objTheAccount.Benefits_Notes__c != null ? objTheAccount.Benefits_Notes__c : '');
			}
			else {
				objAccountToUpdate.SDR_Notes__c = objTask.Description + LogSmartCallingUtil.NEXT_LINE + (objTheAccount.SDR_Notes__c != null ? objTheAccount.SDR_Notes__c : '');
				objAccountToUpdate.Last_Activity_Date__c = System.today();
			}

			List<FieldSetProperties> list_ObjectDetailValues = objData.list_ObjectDetailValues;
			if (list_ObjectDetailValues != null && !list_ObjectDetailValues.isEmpty()) 
			{
				Map<String, Object> map_ObjectDetailValues = constructRecord(list_ObjectDetailValues, LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT);
				if (objMetadata.Current_Record__c || objMetadata.Additional_Info__c) {
					for (String strFieldApi : map_ObjectDetailValues.keySet()) {
						objAccountToUpdate.put(strFieldApi, map_ObjectDetailValues.get(strFieldApi));
					}
				}

				if (map_ObjectDetailValues.containsKey(LogSmartCallingUtil.FIELD_API_LIKELIHOOD_TO_STAY_WITH_GUSTO)) {
					objAccountToUpdate.put(LogSmartCallingUtil.FIELD_API_LIKELIHOOD_TO_STAY_WITH_GUSTO, map_ObjectDetailValues.get(LogSmartCallingUtil.FIELD_API_LIKELIHOOD_TO_STAY_WITH_GUSTO));
				}

				if (map_ObjectDetailValues.containsKey(LogSmartCallingUtil.FIELD_API_GUSTO_RETENTION_NOTES)) {
					objAccountToUpdate.put(LogSmartCallingUtil.FIELD_API_GUSTO_RETENTION_NOTES, map_ObjectDetailValues.get(LogSmartCallingUtil.FIELD_API_GUSTO_RETENTION_NOTES));
				}
			}	

			// update last call connect
			if (
				objTask.ActivityDate != null &&
				objTask.Status == TaskUtil.TASK_STATUS_CONNECT &&
				(objTheAccount.Last_Call_Connect__c == null ||
				objTask.ActivityDate >= objTheAccount.Last_Call_Connect__c)
			) {
				objAccountToUpdate.Last_Call_Connect__c = objTask.ActivityDate;
			}

			AccountTriggerHelper.skipTrigger = true;
			Database.SaveResult objSaveResults = Database.update(objAccountToUpdate, false);
			if (!objSaveResults.isSuccess()) {
				Database.Error[] list_Errors = objSaveResults.getErrors();
				ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'updateAccount', list_Errors[0].getMessage(), '');
				throw new LogSmartCallingException(list_Errors[0].getMessage());
			} else {
				//updating benefits notes on eligible opportunities for benefits users
				if (objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_BENEFITS_USER) {
					List<Opportunity> list_BenfitsOpp = queryBenefitsOpp(new Set<Id>{ objTheAccount.Id });

					for (Opportunity objOpp : list_BenfitsOpp) {
						if (String.isNotBlank(objTheAccount.Benefits_Notes__c)) {
							objOpp.Benefits_Notes__c = objTheAccount.Benefits_Notes__c;
						}
					}

					if (!list_BenfitsOpp.isEmpty()) {
						OpportunityTriggerHelper.skipTrigger = true;
						update list_BenfitsOpp;
						OpportunityTriggerHelper.skipTrigger = false;
					}
				}
			}

			AccountTriggerHelper.SkipTrigger = false;
		}
	}

	/**
	 * @description : Method to update current Opportunity record.
	 * @param       : objData - Data from LWC component.
	 * @param       : objTask - Task created.
	 * @param       : objMetadata - LogSmartCalling Metadata record.
	 * @param       : objUserDetails - Current User Details.
	 * @return      : NA.
	 **/
	private static void updateOpportunity(ComponentParameters objData, Task objTask, AllSmartCalling__mdt objMetadata, User objUserDetails) {
		//check if any Field set exist for current profile if Current record Section is seleted from custom metatdata
		if (String.isNotBlank(objData.strRecordId)) {
			Opportunity objTheOpportunity = queryOpportunity(objData.strRecordId);
			String strBenefitNotes = '';

			Opportunity objOpportunityToUpdate = new Opportunity(Id = objTheOpportunity.Id);
			objOpportunityToUpdate.Description = objTask.Description + LogSmartCallingUtil.NEXT_LINE + objTheOpportunity.Description;
			objOpportunityToUpdate.Last_Call__c = System.today();
			objOpportunityToUpdate.Playmode_Date__c = null;

			// Assigning point of contact selected as Primary contact of Opportunity
			if (String.isNotBlank(objData?.strWhoId)) {
				objOpportunityToUpdate.Primary_Contact__c = objData.strWhoId;
			}

			//updating Opportunity Demo and Scheduled Call fields
			objOpportunityToUpdate.Demo_CS__c = objData.blnOpportunityDemo;
			objOpportunityToUpdate.PPA__c = objData.blnOpportunityPPA;

			List<FieldSetProperties> list_ObjectDetailValues = objData.list_ObjectDetailValues;
			Map<String, Object> map_ObjectDetailValues = new Map<String, Object>();
			if (list_ObjectDetailValues != null && !list_ObjectDetailValues.isEmpty()) {
				map_ObjectDetailValues = constructRecord(list_ObjectDetailValues, LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY);

				if (objMetadata.Current_Record__c || objMetadata.Additional_Info__c) {
					for (String strFieldApi : map_ObjectDetailValues.keySet()) {
						objOpportunityToUpdate.put(strFieldApi, map_ObjectDetailValues.get(strFieldApi));
					}

					if (map_ObjectDetailValues.containsKey(LogSmartCallingUtil.FIELD_API_STAGE_NAME) || map_ObjectDetailValues.containsKey(LogSmartCallingUtil.FIELD_API_NUMBER_OF_EMPLOYEES)) {
						objOpportunityToUpdate.put(LogSmartCallingUtil.FIELD_API_SKIP_EMPLOYEE_CHANGE, true);
					}
				}
			}

			//updating Benefits_Notes__c field for benefits user
			if (
				map_ObjectDetailValues.containsKey(LogSmartCallingUtil.FIELD_API_BENEFIT_NOTES) &&
				objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_BENEFITS_USER &&
				!objTheOpportunity.IsClosed &&
				(objTheOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
				objTheOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			) {
				strBenefitNotes = String.valueOf(map_ObjectDetailValues.get(LogSmartCallingUtil.FIELD_API_BENEFIT_NOTES));

				if (String.isNotBlank(strBenefitNotes))
					objOpportunityToUpdate.Benefits_Notes__c = strBenefitNotes;
			}

			if (map_ObjectDetailValues.containsKey(LogSmartCallingUtil.FIELD_API_LIKELIHOOD_TO_STAY_WITH_GUSTO)) {
				objOpportunityToUpdate.put(LogSmartCallingUtil.FIELD_API_LIKELIHOOD_TO_STAY_WITH_GUSTO, map_ObjectDetailValues.get(LogSmartCallingUtil.FIELD_API_LIKELIHOOD_TO_STAY_WITH_GUSTO));
			}

			if (map_ObjectDetailValues.containsKey(LogSmartCallingUtil.FIELD_API_GUSTO_RETENTION_NOTES)) {
				objOpportunityToUpdate.put(LogSmartCallingUtil.FIELD_API_GUSTO_RETENTION_NOTES, map_ObjectDetailValues.get(LogSmartCallingUtil.FIELD_API_GUSTO_RETENTION_NOTES));
			}

			OpportunityTriggerHelper.skipTrigger = true;
			update objOpportunityToUpdate;
			objOpportunityToUpdate.put(LogSmartCallingUtil.FIELD_API_SKIP_EMPLOYEE_CHANGE, false);
			update objOpportunityToUpdate;
			OpportunityTriggerHelper.skipTrigger = false;

			if (objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_CX_USER && String.isNotBlank(objTask.Description)) {
				FeedItem objFeedItem = new FeedItem(ParentId = objTheOpportunity.Id, Body = objTask.Description);
				insert objFeedItem;
			}

			//update account for Benfits Notes
			if (
				objUserDetails.Profile.Name == LogSmartCallingUtil.PROFILE_BENEFITS_USER &&
				String.isNotBlank(strBenefitNotes) &&
				!objTheOpportunity.IsClosed &&
				(objTheOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
				objTheOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			) {
				Account objAcc = [SELECT Id, Benefits_Notes__c FROM Account WHERE Id = :objTheOpportunity.AccountId];
				objAcc.Benefits_Notes__c = objTheOpportunity.Benefits_Notes__c;
				AccountTriggerHelper.skipTrigger = true;
				update objAcc;
				AccountTriggerHelper.skipTrigger = false;
			}
		}
	}

	/**
	 * @description : Receives list of Field Name & Values and constructs a record.
	 * @param       : list_ObjectDetailValues - Data from LWC component.
	 * @param       : strObjectName - SObject Name.
	 * @return      : Map of Field API name and its value based on Datatype of the Field.
	 **/
	private static Map<String, Object> constructRecord(List<FieldSetProperties> list_ObjectDetailValues, String strObjectName) {
		Map<String, Object> map_ObjectDetailValues = new Map<String, Object>();
		SObjectType objSObjectType = ((SObject) (Type.forName('Schema.' + strObjectName).newInstance())).getSObjectType();
		Map<String, Schema.SObjectField> map_fieldsMap = objSObjectType.getDescribe().fields.getMap();

		for (FieldSetProperties field : list_ObjectDetailValues) {
			if (!map_fieldsMap.containsKey(field.strFieldApiName)) {
				continue;
			}

			Schema.DisplayType fieldType = map_fieldsMap.get(field.strFieldApiName)?.getDescribe().getType();
			switch on String.valueOf(fieldType) {
				when 'BOOLEAN' {
					map_ObjectDetailValues.put(field.strFieldApiName, BOOLEAN.valueOf(field.strFieldValue));
				}
				when 'DATE' {
					map_ObjectDetailValues.put(field.strFieldApiName, DATE.valueOf(field.strFieldValue));
				}
				when 'DATETIME' {
					map_ObjectDetailValues.put(field.strFieldApiName, DATETIME.valueOf(field.strFieldValue));
				}
				when 'DECIMAL' {
					map_ObjectDetailValues.put(field.strFieldApiName, DECIMAL.valueOf(field.strFieldValue));
				}
				when 'DOUBLE' {
					map_ObjectDetailValues.put(field.strFieldApiName, DOUBLE.valueOf(field.strFieldValue));
				}
				when 'INTEGER' {
					map_ObjectDetailValues.put(field.strFieldApiName, INTEGER.valueOf(field.strFieldValue));
				}
				when 'LONG' {
					map_ObjectDetailValues.put(field.strFieldApiName, LONG.valueOf(field.strFieldValue));
				}
				when else {
					map_ObjectDetailValues.put(field.strFieldApiName, field.strFieldValue);
				}
			}
		}

		return map_ObjectDetailValues;
	}

	/**
	 * @description : Close other Open Tasks.
	 * @param       : objData - Data from LWC component.
	 * @param       : objTask - Task created.
	 * @return      : Map of Field API name and its value based on Datatype of the Field.
	 **/
	public static void closePreviousOpenTasks(ComponentParameters objData, Task objTask) {
		Map<Id, Task> map_OpenTasksToClose = new Map<Id, Task>();
		for (Task objRecord : [
			SELECT Id, Status
			FROM Task
			WHERE Id != :objTask.Id AND WhatId = :objData.strRecordId AND (Status = :LogSmartCallingUtil.TASK_STATUS_OPEN OR Status = :LogSmartCallingUtil.TASK_STATUS_SCHEDULED)
		]) {
			objRecord.Status = LogSmartCallingUtil.TASK_STATUS_COMPLETED;
			map_OpenTasksToClose.put(objRecord.Id, objRecord);
		}

		if (!map_OpenTasksToClose.isEmpty()) {
			TaskTriggerHelper.SkipTrigger = true;
			update map_OpenTasksToClose.values();
			TaskTriggerHelper.SkipTrigger = false;
		}
	}

	/**
	 * @description : Create a Follow-up Task.
	 * @param       : objData - Data from LWC component.
	 * @return      : NA
	 **/
	public static void createFollowTask(ComponentParameters objData) {
		Task objFollowUpTask = new Task();
		if (
			objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT ||
			objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY ||
			objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_TICKET
		) {
			if (String.isNotBlank(objData.strRecordId)) {
				objFollowUpTask.WhatId = objData.strRecordId;
			}

			if (String.isNotBlank(objData.strWhoId)) {
				objFollowUpTask.WhoId = objData.strWhoId;
			}
		} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_LEAD && String.isNotBlank(objData.strRecordId)) {
			Lead objLead = queryLead(objData.strRecordId);

			if (String.isNotBlank(objLead.ConvertedOpportunityId__c)) {
				objFollowUpTask.WhatId = objLead.ConvertedOpportunityId__c;
			} else {
				objFollowUpTask.WhoId = objLead.Id;
			}

			if (String.isNotBlank(objLead.ConvertedContactId__c)) {
				objFollowUpTask.WhoId = objLead.ConvertedContactId__c;
			}
		}

		objFollowUpTask.Status = LogSmartCallingUtil.TASK_STATUS_OPEN;
		objFollowUpTask.RecordTypeId = LogSmartCallingUtil.STANDARD_TASK_RT_ID;
		objFollowUpTask.OwnerId = UserInfo.getUserId();

		objFollowUpTask.Subject = objData.strFollowUpSubject;
		objFollowUpTask.ActivityDate = Date.valueOf(objData.strFollowUpDate);

		TaskTriggerHelper.SkipTrigger = true;
		genericDmlOperation(objFollowUpTask, LogSmartCallingUtil.DML_TYPE_INSERT);
		TaskTriggerHelper.SkipTrigger = false;
	}

	/**
	 * @description : Create a Payroll Opportunity.
	 * @param       : objData - Data from LWC component.
	 * @param       : objAccount - Account for which Payroll Opportunity needs to be created.
	 * @return      : NA
	 **/
	public static void createPayrollOpportunity(ComponentParameters objData, Account objAccount) {
		Opportunity objPayrollOpportunity = new Opportunity(
			RecordTypeId = LogSmartCallingUtil.COMPANY_OPPTY_RT_ID,
			CloseDate = Date.valueOf(objData.strPayrollOpportunityCloseDate),
			StageName = objData.strPayrollOpportunityStage,
			Name = objData.strPayrollOpportunityName,
			AccountId = objData.strRecordId
		);

		if (!blnIsCXUser && String.isNotBlank(objAccount.ZP_Company_ID__c)) {
			objPayrollOpportunity.ZP_Company_ID__c = objAccount.ZP_Company_ID__c;
		}

		AccountTriggerHelper.SkipTrigger = true;
		TaskTriggerHelper.SkipTrigger = true;
		insert objPayrollOpportunity;
		AccountTriggerHelper.SkipTrigger = false;
		TaskTriggerHelper.SkipTrigger = false;
	}

	/**
	 * @description : Method to create HI Opportunity.
	 * @param       : objData - Data from LWC component.
	 * @param       : objMetadata - LogSmartCalling Metadata record.
	 * @param       : objUserDetails - Current User Details.
	 * @param       : strAccountId - Account for which HI Opportunity needs to be created.
	 * @param       : strOpportunityName - Opportunity Name.
	 * @return      : NA.
	 **/
	public static void createHIOpportunity(ComponentParameters objData, AllSmartCalling__mdt objMetadata, User objUserDetails, String strAccountId, String strOpportunityName) {
		Opportunity objHiOpportunity = new Opportunity();
        	OpportunityContactRole objHiOpportunityContRole;
		if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT || objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
			objHiOpportunity.AccountId = strAccountId;
		}

		if (objData.strHIOpportunityType.equalsIgnoreCase(LogSmartCallingUtil.HI_OPP_TYPE_HI_BENEFITS_NEW_PLAN)) {
			objHiOpportunity.RecordTypeId = LogSmartCallingUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
			strOpportunityName += LogSmartCallingUtil.HI_OPP_SUFFIX_NEW_PLAN;
		} else if (objData.strHIOpportunityType.equalsIgnoreCase(LogSmartCallingUtil.HI_OPP_TYPE_HI_BENEFITS_BOR)) {
			objHiOpportunity.RecordTypeId = LogSmartCallingUtil.BENEFITS_BOR_OPPTY_RT_ID;
			strOpportunityName += LogSmartCallingUtil.HI_OPP_SUFFIX_BOR;
		} else if (objData.strHIOpportunityType.equalsIgnoreCase(LogSmartCallingUtil.HI_OPP_TYPE_BENEFITS_BYOB)) {
			objHiOpportunity.RecordTypeId = LogSmartCallingUtil.BENEFITS_BYOB_OPPTY_RT_ID;
			strOpportunityName += LogSmartCallingUtil.HI_OPP_SUFFIX_BYOB;
		}

		objHiOpportunity.HI_Opportunity_Assignment_State__c = objData.strHIOpportunityState;
		objHiOpportunity.CloseDate = Date.valueOf(objData.strHIOpportunityCloseDate);
		objHiOpportunity.NumberOfEmployees__c = String.isNotBlank(objData.strHIOpportunityEmployees) ? Integer.valueOf(objData.strHIOpportunityEmployees) : null;
		objHiOpportunity.StageName = objData.strHIOpportunityStage;

		if (objMetadata.Show_Live_HI_Transfer__c) {
			objHiOpportunity.Live_HI_Transfer__c = objData.blnHIOpportunityLiveTransfer;
		}

		objHiOpportunity.Name = strOpportunityName;
		objHiOpportunity.Notes__c = objData.strHIOpportunityNotes;

		if (objHiOpportunity.RecordTypeId != null) {
			TaskTriggerHelper.SkipTrigger = true;
			insert objHiOpportunity;
			TaskTriggerHelper.SkipTrigger = false;
		}
        
        	if(String.isNotBlank(objData.strSelectedHIOppConId)){
			objHiOpportunityContRole = new OpportunityContactRole();
			objHiOpportunityContRole.ContactId = objData.strSelectedHIOppConId;
			objHiOpportunityContRole.OpportunityId = objHiOpportunity.Id;
			objHiOpportunityContRole.Role = LogSmartCallingUtil.BENEFITS_OPPORTUNITY_CONTACT_ROLE;

			insert objHiOpportunityContRole;
		}
	}

	/**
	 * @description : Method to create Ardius Opportunity.
	 * @param       : objData - Data from LWC component.
	 * @param       : objMetadata - LogSmartCalling Metadata record.
	 * @param       : objUserDetails - Current User Details.
	 * @param       : strAccountId - Account for which Ardius Opportunity needs to be created.
	 * @param       : strOpportunityName - Opportunity Name.
	 * @return      : NA.
	 **/
	public static void createArdiusOpportunity(ComponentParameters objData, AllSmartCalling__mdt objMetadata, User objUserDetails, String strAccountId, String strOpportunityName) {
		Account acc = queryAccount(strAccountId);
		Opportunity objArdiusOpportunity = new Opportunity();

		if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT || objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
			objArdiusOpportunity.AccountId = strAccountId;
		}

		objArdiusOpportunity.RecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;
		objArdiusOpportunity.CloseDate = Date.valueOf(objData.strArdiusOpportunityCloseDate);
		objArdiusOpportunity.StageName = objData.strArdiusOpportunityStage;
		objArdiusOpportunity.Type = objData.strType;
		objArdiusOpportunity.Name = acc?.Name + ' ' + '-' + ' ' + 'R&D ' + objData.strType;
		if (String.isNotBlank(objData.strTaxYear)) {
			objArdiusOpportunity.Tax_year__c = objData.strTaxYear;
		} else {
			objArdiusOpportunity.Tax_year__c = System.Label.CurrentTaxYear;
		}

		if (objArdiusOpportunity.RecordTypeId != null) {
			AccountTriggerHelper.SkipTrigger = true;
			TaskTriggerHelper.SkipTrigger = true;
			insert objArdiusOpportunity;
			AccountTriggerHelper.SkipTrigger = false;
			TaskTriggerHelper.SkipTrigger = false;
		}
	}

	/**
	 * @description : Generate a random Id if Interaction Id is blank on NICE Interaction.
	 * @return      : Return Random Id
	 **/
	public static String getRandomId() {
		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertTohex(b);
		return LogSmartCallingUtil.RANDOM_ID_PREFIX +
			h.SubString(0, 8) +
			LogSmartCallingUtil.HYPHEN +
			h.SubString(8, 12) +
			LogSmartCallingUtil.HYPHEN +
			h.SubString(12, 16) +
			LogSmartCallingUtil.HYPHEN +
			h.SubString(16, 20) +
			LogSmartCallingUtil.HYPHEN +
			h.substring(20);
	}

	/**
	 * @description : Create a Product Upsell record.
	 * @param       : objData - Data from LWC component.
	 * @return      : String - Created Product Upsell Id.
	 **/
	public static String createProductUpsell(ComponentParameters objData) {
		List<FieldSetProperties> list_ProductUpsellValues = objData.list_ProductUpsellValues;

		if (list_ProductUpsellValues != null && !list_ProductUpsellValues.isEmpty()) {
			Set<String> set_SelectedTypes = new Set<String>();
			Set<String> set_Selected401Types = new Set<String>();
			String strAccountId;
			String strOpportunityId;
			String strContactId;
			String strSecondaryContactId;
			String strPOCId;
			List<Partnership_Interest__c> list_PartnershipInterestForInsert = new List<Partnership_Interest__c>();
			Partnership_Interest__c objProductUpsell = new Partnership_Interest__c();
			objProductUpsell.RecordTypeId = blnIsCXUser ? LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_CUSTOMER_SUCCESS : LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET;

			Map<String, Object> map_ProductUpsellValues = constructRecord(list_ProductUpsellValues, LogSmartCallingUtil.SOBJECT_API_NAME_PRODUCT_UPSELL);

			if (String.isNotBlank(objData.strWhoId)) {
				objProductUpsell.Contact__c = objData.strWhoId;
				strContactId = objData.strWhoId;
			}

			if (String.isNotBlank(objData.strSecContactId)) {
				objProductUpsell.Secondary_Contact_from_Account__c = objData.strSecContactId;
				strSecondaryContactId = objData.strSecContactId;
			}
			if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
				List<Opportunity> list_Opportunities = [SELECT Id, AccountId, (SELECT Id FROM OpportunityContactRoles) FROM Opportunity WHERE Id = :objData.strRecordId LIMIT 1];
				if (!list_Opportunities.isEmpty()) {
					if (!blnIsCXUser && list_Opportunities[0].OpportunityContactRoles.isEmpty()) {
						return '';
					}

					objProductUpsell.Account__c = list_Opportunities[0].AccountId;
					objProductUpsell.Opportunity__c = list_Opportunities[0].Id;
					strAccountId = list_Opportunities[0].AccountId;
					strOpportunityId = list_Opportunities[0].Id;
				}
			} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT) {
				objProductUpsell.Account__c = objData.strRecordId;
				strAccountId = objData.strRecordId;

				if (!blnIsCXUser) {
					objProductUpsell.Point_Of_Contact__c = String.isNotBlank(objData.strSelectedPointOfConId) ? objData.strSelectedPointOfConId : null;
					strPOCId = String.isNotBlank(objData.strSelectedPointOfConId) ? objData.strSelectedPointOfConId : null;
				}
			}

			for (String strFieldName : map_ProductUpsellValues.keySet()) {
				objProductUpsell.put(strFieldName, map_ProductUpsellValues.get(strFieldName));
			}
			if (objProductUpsell.Type__c != null) {
				set_SelectedTypes.addAll(objProductUpsell.Type__c.split(';'));
			}

			if (set_SelectedTypes != null) {
				//iterating over selected Types like 401K, 529, Ardius, Worker's comp
				for (String strSelectedType : set_SelectedTypes) {
					Partnership_Interest__c objProductUpsellRecord = new Partnership_Interest__c();
					objProductUpsellRecord.Account__c = strAccountId;
					objProductUpsellRecord.Opportunity__c = strOpportunityId;
					objProductUpsellRecord.Contact__c = strContactId;
					objProductUpsellRecord.Secondary_Contact_from_Account__c = strSecondaryContactId;
					objProductUpsellRecord.Point_Of_Contact__c = strPOCId;
					objProductUpsellRecord.RecordTypeId = blnIsCXUser ? LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_CUSTOMER_SUCCESS : LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET;
					Boolean blnValidateProductUpsell = false;

					//creating records for the selected 401k vendors
					if (strSelectedType.trim().equalsIgnoreCase(LogSmartCallingUtil.Vender_401k)) {
						if (objProductUpsell.X401K_Interest_Type__c != null) {
							set_Selected401Types.addAll(objProductUpsell.X401K_Interest_Type__c.split(';'));
						}

						for (String strSelected401Type : set_Selected401Types) {
							objProductUpsellRecord = new Partnership_Interest__c();

							// clearing all different vendor fields
							objProductUpsellRecord.Ardius_Notes__c = '';
							objProductUpsellRecord.X529_Notes__c = '';
							objProductUpsellRecord.Workers_Comp_Notes__c = '';
							objProductUpsellRecord.Workers_Comp_InterestPicklist__c = '';
							objProductUpsellRecord.X529_Interest__c = false;
							objProductUpsellRecord.Workers_Comp_Interest__c = false;
							objProductUpsellRecord.Ardius__c = false;
							objProductUpsellRecord.Account__c = strAccountId;
							objProductUpsellRecord.Opportunity__c = strOpportunityId;
							objProductUpsellRecord.Contact__c = strContactId;
							objProductUpsellRecord.Point_Of_Contact__c = strPOCId;
							objProductUpsellRecord.X401k_Notes__c = String.valueOf(map_ProductUpsellValues.get(LogSmartCallingUtil.FIELD_API_401K_NOTES));
							objProductUpsellRecord.RecordTypeId = blnIsCXUser
								? LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_CUSTOMER_SUCCESS
								: LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET;

							if (strSelected401Type.trim().equalsIgnoreCase(LogSmartCallingUtil.GUIDELINE)) {
								objProductUpsellRecord.Interest_401K__c = LogSmartCallingUtil.GUIDELINE;
							}

							if (strSelected401Type.trim().equalsIgnoreCase(LogSmartCallingUtil.HUMAN_INTEREST)) {
								objProductUpsellRecord.Interest_401K__c = LogSmartCallingUtil.HUMAN_INTEREST;
							}

							if (strSelected401Type.trim().equalsIgnoreCase(LogSmartCallingUtil.BETTERMENT)) {
								objProductUpsellRecord.Interest_401K__c = LogSmartCallingUtil.BETTERMENT;
							}

							if (strSelected401Type.trim().equalsIgnoreCase(LogSmartCallingUtil.VESTWELL)) {
								objProductUpsellRecord.Interest_401K__c = LogSmartCallingUtil.VESTWELL;
							}
							objProductUpsellRecord.X401k_Interest__c = true;
							list_PartnershipInterestForInsert.add(objProductUpsellRecord);
							blnValidateProductUpsell = true;
						}
					}
					// 529 type
					if (strSelectedType.trim().equalsIgnoreCase(LogSmartCallingUtil.Vender_529)) {
						// clearing all different vendor fields
						objProductUpsellRecord.Ardius_Notes__c = '';
						objProductUpsellRecord.X401k_Notes__c = '';
						objProductUpsellRecord.Workers_Comp_Notes__c = '';
						objProductUpsellRecord.Workers_Comp_InterestPicklist__c = '';
						objProductUpsellRecord.X401k_Interest__c = false;
						objProductUpsellRecord.Workers_Comp_Interest__c = false;
						objProductUpsellRecord.X401K_Interest_Type__c = '';
						objProductUpsellRecord.Ardius__c = false;
						objProductUpsellRecord.X529_Notes__c = String.valueOf(map_ProductUpsellValues.get(LogSmartCallingUtil.FIELD_API_529_NOTES));

						objProductUpsellRecord.X529_Interest__c = true;
						blnValidateProductUpsell = true;
						list_PartnershipInterestForInsert.add(objProductUpsellRecord);
					}

					// worker's comp type
					if (strSelectedType.trim().containsIgnoreCase(LogSmartCallingUtil.Vender_Worker)) {
						// clearing all different vendor fields
						objProductUpsellRecord.Ardius_Notes__c = '';
						objProductUpsellRecord.X529_Notes__c = '';
						objProductUpsellRecord.X401k_Notes__c = '';
						objProductUpsellRecord.X529_Interest__c = false;
						objProductUpsellRecord.X401k_Interest__c = false;
						objProductUpsellRecord.X401K_Interest_Type__c = '';
						objProductUpsellRecord.Ardius__c = false;
						objProductUpsellRecord.Workers_Comp_Notes__c = String.valueOf(map_ProductUpsellValues.get(LogSmartCallingUtil.FIELD_API_WORKERS_COMP_NOTES));
						objProductUpsellRecord.Workers_Comp_InterestPicklist__c = String.valueOf(map_ProductUpsellValues.get(LogSmartCallingUtil.FIELD_WORKERS_COMP_INTERESTPICKLIST));
						objProductUpsellRecord.Workers_Comp_Interest__c = true;
						blnValidateProductUpsell = true;
						list_PartnershipInterestForInsert.add(objProductUpsellRecord);
					}

					// ardius vendor
					if (strSelectedType.trim().equalsIgnoreCase(LogSmartCallingUtil.Vender_TaxCredits)) {
						// clearing all different vendor fields
						objProductUpsellRecord.X529_Notes__c = '';
						objProductUpsellRecord.X401k_Notes__c = '';
						objProductUpsellRecord.X529_Interest__c = false;
						objProductUpsellRecord.X401k_Interest__c = false;

						objProductUpsellRecord.Workers_Comp_Notes__c = '';
						objProductUpsellRecord.X401K_Interest_Type__c = '';
						objProductUpsellRecord.Ardius_Notes__c = String.valueOf(map_ProductUpsellValues.get(LogSmartCallingUtil.FIELD_ARDIUS_NOTES));

						objProductUpsellRecord.Workers_Comp_Interest__c = false;
						objProductUpsellRecord.Ardius__c = true;
						blnValidateProductUpsell = true;
						list_PartnershipInterestForInsert.add(objProductUpsellRecord);
					}
				}
			} else {
				// if none of the vendor selected.
				list_PartnershipInterestForInsert.add(objProductUpsell);
			}
			Partnership_Interest__c objProductUpsell1 = new Partnership_Interest__c();
			Boolean blnOtherProdUpsell = false;

			for (String strFieldName : map_ProductUpsellValues.keySet()) {
				if (
					!set_401FieldsAPI.contains(strFieldName) &&
					!set_529FieldsAPI.contains(strFieldName) &&
					!set_ArdiusFieldsAPI.contains(strFieldName) &&
					!set_WorkersCompFieldsAPI.contains(strFieldName) &&
					strFieldName != 'Type__c'
				) {
					if (map_ProductUpsellValues.get(strFieldName) != '' && map_ProductUpsellValues.get(strFieldName) != null) {
						objProductUpsell1.put(strFieldName, map_ProductUpsellValues.get(strFieldName));
						blnOtherProdUpsell = true;
					}
				}
			}
			objProductUpsell1.Account__c = strAccountId;
			objProductUpsell1.Opportunity__c = strOpportunityId;
			objProductUpsell1.Contact__c = strContactId;
			objProductUpsell1.Point_Of_Contact__c = strPOCId;
			objProductUpsell1.RecordTypeId = blnIsCXUser ? LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_CUSTOMER_SUCCESS : LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET;

			if (blnOtherProdUpsell) {
				list_PartnershipInterestForInsert.add(objProductUpsell1);
			}

			List<Database.SaveResult> list_ProductUpsellSaveResults = Database.insert(list_PartnershipInterestForInsert, false);
			Utils.processSaveResult(list_ProductUpsellSaveResults, list_PartnershipInterestForInsert, 'Id', true, 'createProductUpsell');
		}
		return '';
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Convert Datetime string to UTC Datetime value.
	 * @param       : strISODateTime - Datetime string value.
	 * @return      : Returns converted DateTime.
	 **/
	public static Datetime convertDatetimeStrToUTC(String strISODateTime) {
		return DateTime.ValueofGmt(strISODateTime.replace('T', ' '));
	}

	/**
	 * @description : Query State records.
	 * @return      : Returns List of State records.
	 **/
	public static List<String> getStates() {
		List<String> list_States = new List<String>();
		for (State__c objState : [SELECT Id, Name FROM State__c ORDER BY Name ASC]) {
			list_States.add(objState.Name);
		}

		return list_States;
	}

	/**
	 * @description : Query Benefits Opportunities.
	 * @param       : set_AccId - Account Ids for which Benefits Opportunities to be queried.
	 * @return      : Returns List of Benefits Opportunities records.
	 **/
	public static List<Opportunity> queryBenefitsOpp(Set<Id> set_AccId) {
		List<Opportunity> list_oppResult = new List<Opportunity>();
		Id newPlanBenefitRecordType = LogSmartCallingUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
		Id boRBenefitRecordType = LogSmartCallingUtil.BENEFITS_BOR_OPPTY_RT_ID;

		return [
			SELECT Id, StageName, IsClosed, AccountId, Benefits_Notes__c
			FROM Opportunity
			WHERE AccountId IN :set_AccId AND IsClosed = FALSE AND (RecordTypeId = :newPlanBenefitRecordType OR RecordTypeId = :boRBenefitRecordType)
		];
	}

	/**
	 * @description : Asynchronous Method to handle additional data insertions/ updates .
	 * @param       : strDataInJson - Stringified Data from LWC component.
	 * @param       : strTaskId - Id of Task created.
	 * @param       : strMetadata - Stringified LogSmartCalling Metadata record.
	 * @param       : strUserDetails - Stringified Current User Details.
	 * @param       : strNiceInteraction - Stringified NICE Interaction record.
	 * @param       : blnIsSaveWOCall - Boolean to differentiate  Save with or without call.
	 * @return      : NA.
	 **/
	@future
	public static void logSmartCallingFuture(
		String strDataInJson,
		String strTaskId,
		String strMetadata,
		String strUserDetails,
		String strNiceInteraction,
		Boolean blnCreateSCT,
		Boolean blnIsSaveWOCall
	) {
		try {
			ComponentParameters objData = String.isNotBlank(strDataInJson) ? (ComponentParameters) JSON.deserialize(strDataInJson, ComponentParameters.class) : new ComponentParameters();
			AllSmartCalling__mdt objMetadata = String.isNotBlank(strMetadata) ? (AllSmartCalling__mdt) JSON.deserialize(strMetadata, AllSmartCalling__mdt.class) : new AllSmartCalling__mdt();
			User objUserDetails = (User) JSON.deserialize(strUserDetails, User.class);
			NICE_Interaction__c objNiceInteraction = String.isNotBlank(strNiceInteraction)
				? (NICE_Interaction__c) JSON.deserialize(strNiceInteraction, NICE_Interaction__c.class)
				: new NICE_Interaction__c();

			Task objTask;

			if (String.isNotBlank(strTaskId)) {
				objTask = [SELECT Id, Status, WhatId, Description FROM Task WHERE Id = :strTaskId];
			}

			if (String.isNotBlank(objData.strRecordId)) {
				blnIsCXUser = objUserDetails.Profile.Name.containsIgnoreCase(LogSmartCallingUtil.PROFILE_CX_USER);
				Sales_Call_Tracking__c objSalClTrack = new Sales_Call_Tracking__c();

				if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT) {
					Account objTheAccount = queryAccount(objData.strRecordId);

					objSalClTrack.Account__c = objData.strRecordId; // sales call tracking

					if (objTheAccount != null && objData.blnCreateHIOpportunity && objMetadata.HI_Opportunity__c) {
						createHIOpportunity(objData, objMetadata, objUserDetails, objTheAccount.Id, objTheAccount.Name);
					}

					if (
						objTheAccount != null &&
						objData.blnCreateArdiusOpportunity &&
						objMetadata.Create_Ardius_Opportunity__c &&
						!getExistingOpp(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objTheAccount.Id)
					) {
						createArdiusOpportunity(objData, objMetadata, objUserDetails, objTheAccount.Id, objTheAccount.Name);
					}

					if (objData.blnCreatePayrollOpportunity && objMetadata.Payroll_Opportunity__c) {
						createPayrollOpportunity(objData, objTheAccount);
					}
					if (objMetadata.Close_Previous_Tasks__c && objTask != null) {
						closePreviousOpenTasks(objData, objTask);
					}

					if (String.isNotBlank(objData.strFollowUpSubject) && String.isNotBlank(objData.strFollowUpDate) && objMetadata.Follow_Up__c) {
						createFollowTask(objData);
					}
				} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
					Opportunity objTheOpportunity = queryOpportunity(objData.strRecordId);

					objSalClTrack.Opportunity__c = objData.strRecordId; // sales call tracking
					if (objTheOpportunity != null && objData.blnCreateHIOpportunity && objMetadata.HI_Opportunity__c) {
						createHIOpportunity(objData, objMetadata, objUserDetails, objTheOpportunity.AccountId, objTheOpportunity.Account.Name);
					}

					if (
						objTheOpportunity != null &&
						objData.blnCreateArdiusOpportunity &&
						objMetadata.Create_Ardius_Opportunity__c &&
						!getExistingOpp(LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY, objTheOpportunity.Id)
					) {
						createArdiusOpportunity(objData, objMetadata, objUserDetails, objTheOpportunity.AccountId, objTheOpportunity.Account.Name);
					}

					//In case there are open tasks for current opportunity - close them out before logging new task for current call
					if (objMetadata.Close_Previous_Tasks__c && objTask != null) {
						closePreviousOpenTasks(objData, objTask);
					}

					if (objMetadata.Follow_Up__c && String.isNotBlank(objData.strFollowUpSubject) && String.isNotBlank(objData.strFollowUpDate)) {
						createFollowTask(objData);
					}
				} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_LEAD) {
					objSalClTrack.Lead__c = objData.strRecordId; //sales call tracking

					if (objMetadata.Follow_Up__c && String.isNotBlank(objData.strFollowUpSubject) && String.isNotBlank(objData.strFollowUpDate) && !objData.blnDoNotCall) {
						createFollowTask(objData);
					}
				} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_TICKET) {
					//Added as part of SIFA-250
					if (objMetadata.Close_Previous_Tasks__c && objTask != null) {
						closePreviousOpenTasks(objData, objTask);
					}
					if (objMetadata.Follow_Up__c && String.isNotBlank(objData.strFollowUpSubject) && String.isNotBlank(objData.strFollowUpDate)) {
						createFollowTask(objData);
					}
				}

				if (objData.strObjectName == LogSmartCallingUtil.OBJ_BENEFIT_ORDER) {
					//No Logic
				} else {
					objSalClTrack.RecordTypeId = LogSmartCallingUtil.SCT_RECTYPE_SALES;
				}

				if (!blnIsSaveWOCall && objTask != null) {
					//sales call tracking object
					if (String.isNotBlank(objData.strWhoId)) {
						if (objData.strObjectName != LogSmartCallingUtil.SOBJECT_API_NAME_LEAD) {
							objSalClTrack.Contact__c = objData.strWhoId;
						}
						if (String.isNotBlank(objNiceInteraction.ContactID__c)) {
							if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_LEAD) {
								objSalClTrack.Lead__c = objData.strWhoId;
							} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
								objSalClTrack.Opportunity__c = objData.strRecordId;
							} else if (objData.strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT) {
								objSalClTrack.Account__c = objData.strRecordId;
							}

							objSalClTrack.Is_PureCloud_Call__c = true;
							objSalClTrack.Genesys_Integration_Id__c = objNiceInteraction.ContactID__c;
							objSalClTrack.Call_Direction__c = objNiceInteraction.Call_Direction__c;
							objSalClTrack.Call_Type__c = objNiceInteraction.Call_Direction__c;

							if (String.isNotBlank(objNiceInteraction.Call_Start_Date_and_Time__c)) {
								objSalClTrack.Call_Start_Time__c = convertDatetimeStrToUTC(objNiceInteraction.Call_Start_Date_and_Time__c);
							}

							if (String.isNotBlank(objNiceInteraction.Call_End_Date_and_Time__c)) {
								objSalClTrack.Call_End_Time__c = convertDatetimeStrToUTC(objNiceInteraction.Call_End_Date_and_Time__c);
							}
						}
					}

					objSalClTrack.Date_Time__c = DateTime.now();
					objSalClTrack.Owner_Role__c = objUserDetails.userRole.Name;
					objSalClTrack.Owner__c = objUserDetails.Id;
					objSalClTrack.Task_Status__c = objTask.Status;
					objSalClTrack.Task_Notes__c = objTask.Description;
				}
				if (blnCreateSCT && objSalClTrack != null) {
					if (objData.strObjectName != LogSmartCallingUtil.OBJ_BENEFIT_ORDER) {
						objSalClTrack.Task__c = objTask.Id;
						insert objSalClTrack;
					} else {
						if (String.isBlank(objSalClTrack.Genesys_Integration_Id__c) || LogSmartCallingUtil.UNDEFINED_VALUE.equalsIgnoreCase(objSalClTrack.Genesys_Integration_Id__c)) {
							insert objSalClTrack;
						} else {
							upsert objSalClTrack Genesys_Integration_Id__c;
						}
					}
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'logSmartCallingFuture', objException.getMessage(), objException.getStackTraceString());
		}
	}

	public class ComponentParameters {
		public String strRecordId { get; set; }
		public String strObjectName { get; set; }
		public String strDisposition { get; set; }
		public String strNotes { get; set; }
		public String strFeatureRequest { get; set; }
		public String strFeatureRequestType { get; set; }
		public Boolean blnInboundCall { get; set; }
		public Boolean blnOutboundCall { get; set; }
		public Boolean blnOutboundEmail { get; set; }
		public Boolean blnOpportunityPPA { get; set; }
		public Boolean blnOpportunityDemo { get; set; }
		public Boolean blnTaskScheduledCall { get; set; }
		public Boolean blnCreateProductUpsell { get; set; }
		public Boolean blnAddProductInterest { get; set; }
		public Boolean blnInAppScheduler { get; set; }
		public List<FieldSetProperties> list_ProductUpsellValues { get; set; }
		public List<FieldSetProperties> list_ObjectDetailValues { get; set; }
		public Boolean blnDoNotCall { get; set; }
		public String strFollowUpDate { get; set; }
		public String strFollowUpSubject { get; set; }
		public Boolean blnCreatePayrollOpportunity { get; set; }
		public String strPayrollOpportunityName { get; set; }
		public String strPayrollOpportunityStage { get; set; }
		public String strPayrollOpportunityCloseDate { get; set; }
		public Boolean blnCreateHIOpportunity { get; set; }
		public Boolean blnCreateArdiusOpportunity { get; set; }
		public String strArdiusOpportunityStage { get; set; }
		public String strHIOpportunityType { get; set; }
		public String strHIOpportunityStage { get; set; }
		public String strHIOpportunityCloseDate { get; set; }
		public String strArdiusOpportunityCloseDate { get; set; }
		public String strHIOpportunityState { get; set; }
		public String strHIOpportunityEmployees { get; set; }
		public String strHIOpportunityNotes { get; set; }
		public Boolean blnHIOpportunityLiveTransfer { get; set; }
		public String strWhoId { get; set; }
		public String strSecContactId { get; set; }
		public String strWhatId { get; set; }
		public String strPhoneNumber { get; set; }
		public String strCallObjective { get; set; }
		public String strTaskType { get; set; }
		public String strPartnerSalesTaskType { get; set; }
		public String strTaskSubject { get; set; }
		public String strSelectedPointOfConId { get; set; }
		public String strLeadCurrentStatus { get; set; }
		public String strType { get; set; }
		public String strTaxYear { get; set; }
		public String strProductInterest { get; set; }
		public String strProductInterestCountries { get; set; }
		public String productInterestAccountId { get; set; }
		public String strLeadPassCountries { get; set; }
		public String strLeadPassCountriesAdditional { get; set; }
		public String strSelectedHIOppConId { get; set; }
		public ComponentParameters() {
			strRecordId = '';
			strObjectName = '';
			strDisposition = '';
			strNotes = '';
			strFeatureRequest = '';
			strFollowUpDate = '';
			strFollowUpSubject = '';
			strPayrollOpportunityName = '';
			strPayrollOpportunityStage = '';
			strPayrollOpportunityCloseDate = '';
			strArdiusOpportunityCloseDate = '';
			strHIOpportunityType = '';
			strHIOpportunityStage = '';
			strArdiusOpportunityStage = '';
			strHIOpportunityCloseDate = '';
			strHIOpportunityState = '';
			strHIOpportunityEmployees = '';
			strHIOpportunityNotes = '';
            		strSelectedHIOppConId = '';
			strWhoId = '';
			strWhatId = '';
			strPhoneNumber = '';
			strCallObjective = '';
			strTaskType = '';
			strPartnerSalesTaskType = '';
			strTaskSubject = '';
			strSelectedPointOfConId = '';
			strLeadCurrentStatus = '';
			strType = '';
			strTaxYear = '';
			productInterestAccountId = '';

			list_ProductUpsellValues = new List<FieldSetProperties>();
			list_ObjectDetailValues = new List<FieldSetProperties>();

			blnInboundCall = false;
			blnOutboundCall = false;
			blnOutboundEmail = false;
			blnOpportunityPPA = false;
			blnOpportunityDemo = false;
			blnTaskScheduledCall = false;
			blnCreateProductUpsell = false;
			blnAddProductInterest = false;
			blnDoNotCall = false;
			blnCreatePayrollOpportunity = false;
			blnCreateHIOpportunity = false;
			blnCreateArdiusOpportunity = false;
			blnHIOpportunityLiveTransfer = false;
			blnInAppScheduler = false;
		}
	}

	public class ResponseWrapper {
		@AuraEnabled
		public List<ContactRoleWithCases> list_ContactRoles { get; set; }
		@AuraEnabled
		public List<String> list_States { get; set; }
		@AuraEnabled
		public List<String> list_ProductInterestCountryOptions { get; set; }
		@AuraEnabled
		public Map<String, String> map_PICountryOptions { get; set; }
		@AuraEnabled
		public List<String> list_SelectedProductInterestCountries { get; set; }
		@AuraEnabled
		public List<String> list_SupportedCountries { get; set; }
		@AuraEnabled
		public Map<String, FieldSetProperties> map_CurrentObjectProperties { get; set; }
		@AuraEnabled
		public Map<String, FieldSetProperties> map_AddtnlInfoObjectProperties { get; set; }
		@AuraEnabled
		public List<FieldSetProperties> list_ProductUpsellProperties { get; set; }
		@AuraEnabled
		public String strMetadataProperties { get; set; }
		@AuraEnabled
		public User objUserDetails { get; set; }
		@AuraEnabled
		public Lead objLead { get; set; }
		@AuraEnabled
		public Account objAccount { get; set; }
		@AuraEnabled
		public Account objProductInterestAccount { get; set; }
		@AuraEnabled
		public Ticket__c objTicket { get; set; }
		@AuraEnabled
		public List<String> list_CallObjectives { get; set; }
		@AuraEnabled
		public String strCallObjectiveHelpText { get; set; }
		@AuraEnabled
		public Boolean disableArdiusOpp { get; set; }
		@AuraEnabled
		public Map<String, String> map_PartnerSalesTypes { get; set; }

		@AuraEnabled
		public Map<Id, Account> map_CompanyAccounts { get; set; }

		@AuraEnabled
		public Map<Id, Opportunity> map_CompanyOpportunities { get; set; }

		@AuraEnabled
		public List<Contact> list_AccountContacts { get; set; }

		@AuraEnabled
		public List<String> list_CountriesSentToRemote { get; set; }
		@AuraEnabled
		public Map<String, String> map_AllCountries { get; set; }

		public ResponseWrapper() {
			list_ContactRoles = new List<ContactRoleWithCases>();
			list_States = new List<String>();
			list_ProductInterestCountryOptions = new List<String>();
			map_PICountryOptions = new Map<String, String>();
			list_SelectedProductInterestCountries = new List<String>();
			list_SupportedCountries = new List<String>();
			list_ProductUpsellProperties = new List<FieldSetProperties>();
			list_CallObjectives = new List<String>();
			list_AccountContacts = new List<Contact>();
			list_CountriesSentToRemote = new List<String>();
			map_AllCountries = new Map<String, String>();

			map_CurrentObjectProperties = new Map<String, FieldSetProperties>();
			map_AddtnlInfoObjectProperties = new Map<String, FieldSetProperties>();
			map_PartnerSalesTypes = new Map<String, String>();

			strMetadataProperties = '';
			strCallObjectiveHelpText = '';

			objUserDetails = new User();
			objLead = new Lead();
			objAccount = new Account();

			objProductInterestAccount = new Account();
			map_CompanyAccounts = new Map<Id, Account>();
			map_CompanyOpportunities = new Map<Id, Opportunity>();
		}
	}

	public class FieldSetProperties {
		@AuraEnabled
		public String strFieldApiName { get; set; }
		@AuraEnabled
		public String strFieldLabel { get; set; }
		@AuraEnabled
		public String strFieldType { get; set; }
		@AuraEnabled
		public String strFieldValue { get; set; }
		@AuraEnabled
		public Boolean blnFieldRequired { get; set; }
		@AuraEnabled
		public Boolean blnTypeDependant { get; set; }
		@AuraEnabled
		public String strTypeDependantCategory { get; set; }

		public FieldSetProperties() {
			strFieldApiName = '';
			strFieldLabel = '';
			strFieldType = '';
			strFieldValue = '';
			strTypeDependantCategory = '';

			blnTypeDependant = false;
			blnFieldRequired = false;
		}
	}

	//for Opportunity record page
	public class ContactRoleWithCases {
		@AuraEnabled
		public OpportunityContactRole objOptyContactRole { get; set; }
		@AuraEnabled
		public ZP_User_Role__c objAcctContact { get; set; }
		@AuraEnabled
		public List<Case> list_Cases { get; set; }

		public ContactRoleWithCases() {
			objOptyContactRole = new OpportunityContactRole();
			objAcctContact = new ZP_User_Role__c();

			list_Cases = new List<Case>();
		}
	}

	/*
	 * @Author	:	Pradeep Chary
	 * @Description	:	Generic DML update method to overcome Update_lock_row error
	 * @Parm	:	objRecord - record to be inserted
	 * @Parm	:	strOperation - a DML operation. insert/update/upsert
	 * @Return	:	void
	 */
	public static void genericDmlOperation(SObject objRecord, String strOperation) {
		Integer intMaxTries = 10;
		Integer intCount = 0;

		while (intCount < intMaxTries) {
			try {
				if (strOperation == LogSmartCallingUtil.DML_TYPE_INSERT) {
					Database.SaveResult objResult = Database.insert(objRecord);
				} else if (strOperation == LogSmartCallingUtil.DML_TYPE_UPDATE) {
					Database.SaveResult objResult = Database.update(objRecord);
				} else if (strOperation == LogSmartCallingUtil.DML_TYPE_UPSERT) {
					Database.UpsertResult objResult = Database.upsert(objRecord);
				}

				if (Test.isRunningTest() && blnDMLException) {
					// Cause DMLException
					DmlException objDmlException = new DmlException();
					objDmlException.setMessage(LogSmartCallingUtil.ERROR_MSG_UNABLE_TO_LOCK_ROW);

					throw objDmlException;
				}

				break;
			} catch (DMLException objDmlException) {
				if (objDmlException.getMessage().contains(LogSmartCallingUtil.ERROR_MSG_UNABLE_TO_LOCK_ROW)) {
					intCount++;
				} else {
					intCount = intMaxTries;
					ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'genericDmlOperation', objDmlException.getMessage(), objDmlException.getStackTraceString());
				}
			}
		}
	}

	/**
	 * @Author		: Alex Xiong
	 * @Description	: Get Call Interaction Id from current record
	 * @Parm		: strSelectedPhoneNumber - phone number to search for
	 * @Return		: Boolean whether a record was found
	 */
	@AuraEnabled
	public static String getNiceInteraction(String strSelectedPhoneNumber) {
		try {
			String strSelectedPhoneNumberNormalized = '';
			NormalizationUtil objNormalizeController = new NormalizationUtil();
			strSelectedPhoneNumberNormalized = objNormalizeController.normalisePhoneField(strSelectedPhoneNumber);

			List<NICE_Interaction__c> list_NiceDetails = [
				SELECT Id, ContactID__c, Call_Duration_in_Sec__c, Call_Direction__c, Call_Start_Date_and_Time__c, Call_End_Date_and_Time__c
				FROM NICE_Interaction__c
				WHERE Email_Id__c = :UserInfo.getUserEmail() AND (DNIS__c = :strSelectedPhoneNumberNormalized OR DNIS__c = :strSelectedPhoneNumber) AND CreatedDate = TODAY
				ORDER BY CreatedDate DESC
				LIMIT 1
			];

			String strJsonNiceDetails = '';
			if (!list_NiceDetails.isEmpty()) {
				strJsonNiceDetails = JSON.serialize(list_NiceDetails[0]);
			}
			return strJsonNiceDetails;
		} catch (Exception objException) {
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Get Call Objectives Picklist Values for BT-17370.
	 * @param       : NA
	 * @return      : Call Objectives Picklist Values.
	 **/
	public static List<String> populateCallObjectives() {
		List<String> list_CallObjectives = new List<String>();
		Schema.DescribeFieldResult objFieldResult = Task.Primary_Call_Objective__c.getDescribe();
		strCallObjectiveHelpText = objFieldResult.getInlineHelpText();

		for (Schema.PicklistEntry objPickListVal : objFieldResult.getPicklistValues()) {
			list_CallObjectives.add(objPickListVal.getLabel());
		}
		return list_CallObjectives;
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Get Partner Sales Task Type Picklist Values.
	 * @param       : NA
	 * @return      : Partner Sales Task Type Picklist Values.
	 **/
	public static Map<String, String> populatePartnerSalesTypes() {
		Map<String, String> map_PartnerSalesTypes = new Map<String, String>();
		Schema.DescribeFieldResult objFieldResult = Task.Partner_Sales_Task_Type__c.getDescribe();

		for (Schema.PicklistEntry objPicklistEntry : objFieldResult.getPicklistValues()) {
			map_PartnerSalesTypes.put(objPicklistEntry.getValue(), objPicklistEntry.getLabel());
		}

		return map_PartnerSalesTypes;
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Save LTC Task.
	 * @param       : strObjectName - SObject Name
	 * @param       : strRecordId - Record Id
	 * @return      : Success Message.
	 **/
	@AuraEnabled
	public static String saveLTC(String strObjectName, String strRecordId) {
		try {
			Task objLtcTask = new Task(
				CallDisposition = LogSmartCallingUtil.TASK_STATUS_ATTEMPT,
				CallType = LogSmartCallingUtil.CALL_TYPE_OUTBOUND,
				Subject = LogSmartCallingUtil.TASK_STATUS_ATTEMPT + LogSmartCallingUtil.WHITE_SPACE + LogSmartCallingUtil.DATETIME_FORMATTED,
				ActivityDate = System.today(),
				Status = LogSmartCallingUtil.TASK_STATUS_ATTEMPT,
				Description = LogSmartCallingUtil.TASK_STATUS_ATTEMPT + ' || ' + LogSmartCallingUtil.DATETIME_FORMATTED + ' || LTC',
				RecordTypeId = LogSmartCallingUtil.CALL_TASK_RT_ID
			);

			if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_LEAD) {
				objLtcTask.WhoId = strRecordId;
				objLtcTask.Lead__c = strRecordId;
			} else if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
				objLtcTask.WhatId = strRecordId;
			}

			insert objLtcTask;
		} catch (Exception objException) {
			ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'saveLTC', objException.getMessage(), objException.getStackTraceString());
			throw new AuraHandledException(objException.getMessage());
		}

		return LogSmartCallingUtil.SUCCESS;
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Opportunity based on Opportunity Id.
	 * @param       : strOppId - Opportunity Record Id
	 * @return      : Opportunity record based on Opportunity Id.
	 **/
	public static Opportunity queryOpportunity(String strOppId) {
		return [
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
			WHERE Id = :strOppId
		];
	}

	/**
	 * @author      : Anurag Gautam
	 * @description : Get product interest account data.
	 * @param       : strRecordId - Record id, strObjectName - object name
	 * @return      : Account data
	 **/
	public static Account getProductInterestData(String strRecordId, String strObjectName) {
		String strProductInterestAccountId;
		if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
			Opportunity objOpportunity = queryOpportunity(strRecordId);
			strProductInterestAccountId = objOpportunity.AccountId;
		} else if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT) {
			strProductInterestAccountId = strRecordId;
		}
		return queryAccount(strProductInterestAccountId);
	}

	/**
	 * @author      : Anurag Gautam
	 * @description : Get product interest countries picklist options.
	 * @param       : NA
	 * @return      : Picklist options
	 **/
	public static Map<String, String> getPickListValuesIntoList() {
		Map<String, String> map_PicklistLabelAndName = new Map<String, String>();
		Schema.DescribeFieldResult fieldResult = Account.Product_Interest_Countries__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			map_PicklistLabelAndName.put(pickListVal.getLabel(), pickListVal.getValue());
		}
		return map_PicklistLabelAndName;
	}

	/**
	 * @author      : Debasmita rawooth
	 * @description : Create map of product interest country codes vs names.
	 * @param       : NA
	 * @return      : Map
	 **/
	public static Map<String, String> getMapCountryCodeAndName() {
		Map<String, String> map_CountryCodeAndName = new Map<String, String>();
		Schema.DescribeFieldResult fieldResult = Account.Product_Interest_Countries__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			map_CountryCodeAndName.put(pickListVal.getValue(), pickListVal.getLabel());
		}
		return map_CountryCodeAndName;
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Lead based on Lead Id.
	 * @param       : strLeadId - Lead Record Id
	 * @return      : Lead record based on Lead Id.
	 **/
	public static Lead queryLead(String strLeadId) {
		return [
			SELECT
				Id,
				Name,
				Status,
				Email,
				Phone,
				MobilePhone,
				Secondary_Phone__c,
				Alternate_Phone__c,
				MDR_Notes__C,
				Description,
				ConvertedOpportunityId__c,
				ConvertedContactId__c,
				State,
				Lead_Status_Detail__c
			FROM Lead
			WHERE Id = :strLeadId
		];
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Account based on Account Id.
	 * @param       : strAccountId - Account Record Id
	 * @return      : Account record based on Account Id.
	 **/
	public static Account queryAccount(String strAccountId) {
		return [
			SELECT
				Id,
				Name,
				OwnerId,
				Number_of_Active_Employees__c,
				RecordTypeId,
				ZP_Company_ID__c,
				Product_Interest__c,
				Product_Interest_Countries__c,
				CS_Notes__c,
				Account_Owner_Role__c,
				SDR_Notes__c,
				Benefits_Notes__c,
				Last_Call_Connect__c,
				RecordType.Name
			FROM Account
			WHERE Id = :strAccountId
		];
	}

	/**
	 * @author      : Deepesh Rao
	 * @description : Query Ticket based on Ticket Id.
	 * @param       :  - Ticket Record Id
	 * @return      : Ticket record based on Ticket Id.
	 **/
	public static Ticket__c queryTicket(String strRecordId) {
		return [SELECT Id, Name, Opportunity__c FROM Ticket__c WHERE Id = :strRecordId AND RecordType.Name = 'Ardius' LIMIT 1];
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Log Smart Calling Metadata records.
	 * @param       : strObjectName - Current SObject Name
	 * @param       : strProfileName - Current User's Profile Name
	 * @return      : AllSmartCalling__mdt config record based on strObjectName && strProfileName.
	 **/
	public static List<AllSmartCalling__mdt> queryAllSmartCalling(String strObjectName, String strProfileName) {
		return [
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
				Additional_Info__c,
				Product_Upsell_Fields__c,
				Product_Upsell_Fieldset__c,
				Product_Interest__c,
				Show_Cases__c,
				Show_Roles__c,
				Show_Task_Type__c,
				Show_Call_Objective__c,
				Show_Partner_Sales_Type__c,
				Show_Subject__c,
				Show_Live_HI_Transfer__c,
				Show_Retention_Notes__c,
				Show_Source__c,
				Show_Feature_Request__c,
				Show_Point_of_Contact__c,
				Ardius_Opp_Stage_Values__c,
				Create_Ardius_Opportunity__c,
				Call_Objective_Values__c,
				Tax_Credits_Type_Values__c,
				Create_Lead_Pass__c,
				Create_Lead_Pass_Roles__c,
            	Show_Secondary_POC__c,
				Secondary_POC_Exclude_Roles__c
			FROM AllSmartCalling__mdt
			WHERE Object_Name__c = :strObjectName AND Profile_Name__c = :strProfileName
		];
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query ZP User Roles based on Account Id.
	 * @param       : strAccountId - Current Account Id.
	 * @param       : set_QueryRoleNames - Set of Profile Name used in Filter clause.
	 * @return      : ZP_User_Role__c records.
	 **/
	public static List<ZP_User_Role__c> queryZPUserRoles(String strAccountId, Set<String> set_QueryRoleNames) {
		return [
			SELECT
				Id,
				Company_Id__c,
				Company_Account__c,
				Accounting_Firm_Id__c,
				Role_Name__c,
				Contact__c,
				Contact__r.Id,
				Contact__r.FirstName,
				Contact__r.LastName,
				Contact__r.Title,
				Contact__r.Email,
				Contact__r.Phone,
				Contact__r.ZP_Phone__c,
				Contact__r.MobilePhone
			FROM ZP_User_Role__c
			WHERE Contact__c != NULL AND (Company_Account__c = :strAccountId OR Accounting_Firm_Account__c = :strAccountId) AND Role_Name__c IN :set_QueryRoleNames AND Deleted_At__c = NULL
		];
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Opportunity Contact Roles based on Opportunity Id.
	 * @param       : strRecordId - Current Opportunity Id.
	 * @return      : OpportunityContactRole records.
	 **/
	public static List<OpportunityContactRole> queryOpportunityContactRoles(String strRecordId) {
		return [
			SELECT Id, Role, Contact.Id, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Title, Contact.Phone, Contact.Email, ContactId, Contact.ZP_Phone__c, Contact.MobilePhone
			FROM OpportunityContactRole
			WHERE OpportunityId = :strRecordId
		];
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Cases based on Contact Id.
	 * @param       : set_ContactIds - Set of Contact Ids.
	 * @return      : Case records.
	 **/
	public static List<Case> queryCasesBasedOnContact(Set<Id> set_ContactIds) {
		return [SELECT Id, CaseNumber, ContactId, Type, Status, Priority, Description FROM Case WHERE ContactId IN :set_ContactIds ORDER BY CreatedDate DESC LIMIT 5];
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Company Accounts & all their Opportunities of a Reseller Account.
	 * @param       : strAccountId - Reseller Account Id.
	 * @return      : Map of Company Accounts.
	 **/
	public static Map<Id, Account> queryCompanyAccounts(String strAccountId) {
		return new Map<Id, Account>(
			[
				SELECT Id, Name, (SELECT Id, Name FROM Opportunities WHERE RecordTypeId = :LogSmartCallingUtil.COMPANY_OPPTY_RT_ID ORDER BY Name)
				FROM Account
				WHERE (Referred_By__c = :strAccountId OR Sold_By__c = :strAccountId) AND RecordTypeId = :LogSmartCallingUtil.COMPANY_ACCOUNT_RT_ID
				ORDER BY Name
			]
		);
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Query Opportunities of a Company Account.
	 * @param       : strAccountId - Company Account Id.
	 * @return      : Map of Opportunities.
	 **/
	public static Map<Id, Opportunity> queryCompanyOpportunities(String strAccountId) {
		Set<Id> set_BenefitsOpptyRecTypes = OpportunityUtil.set_BenefitRTChangeEmployees;
		set_BenefitsOpptyRecTypes.add(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID);
		return new Map<Id, Opportunity>(
			[
				SELECT Id, Name
				FROM Opportunity
				WHERE AccountId = :strAccountId AND (RecordTypeId = :LogSmartCallingUtil.COMPANY_OPPTY_RT_ID OR (IsClosed = FALSE AND RecordTypeId IN :set_BenefitsOpptyRecTypes))
				ORDER BY Name
			]
		);
	}
	/**
	 * @author      : Deepesh Rao
	 * @description : Check for existing Opportunities .
	 * @param       : strRecordId.
	 * @return      : Boolean
	 **/
	public static Boolean getExistingOpp(String strObjectName, String strRecordId) {
		Boolean rejectArdiusOpp = false;
		if (strObjectName == LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY) {
			Opportunity opp = queryOpportunity(strRecordId);
			strRecordId = opp?.AccountId;
		}

		List<Opportunity> list_existingOppty = [
			SELECT Id
			FROM Opportunity
			WHERE
				RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID
				AND StageName != :LogSmartCallingUtil.ARD_OPP_CLOSED_WON
				AND StageName != :LogSmartCallingUtil.ARD_OPP_CLOSED_LOST
				AND Tax_year__c = :System.Label.CurrentTaxYear
				AND AccountId = :strRecordId
			LIMIT 1
		];
		if (!list_existingOppty.isEmpty()) {
			rejectArdiusOpp = true;
		}

		return rejectArdiusOpp;
	}

	/**
	 * @author      : Debasmita Rawooth
	 * @description : Query Contacts based on Account Id.
	 * @param       : strAccountId - Account Record Id
	 * @return      : List of Contact records based on Account Id.
	 **/
	public static List<Contact> queryContactsFromAccount(String strAccountId) {
		return [SELECT Id, Name, Title, Email FROM Contact WHERE AccountId = :strAccountId];
	}

	/**
	 * @description  Invocable class to share output with nice interaction update flow
	 * @see          LogSmartCallingControllerLEXTest.testDoCalculations
	 **/
	public class Output {
		@InvocableVariable
		public DateTime dateTimeCallStart;

		@InvocableVariable
		public DateTime dateTimeCallEnd;
	}

	/**
	 * @description  Invocable class to get input from nice interaction update flow
	 * @see          LogSmartCallingControllerLEXTest.testDoCalculations
	 **/
	public class Input {
		@InvocableVariable
		public String strCallStartDateTime;

		@InvocableVariable
		public String strCallEndDateTime;

		@InvocableVariable
		public Integer intCallDuration;

		@InvocableVariable
		public String strGenesysInteractionId;

		//Nice Interaction Id
		@InvocableVariable
		public Id idNiceInteractionId;

		//Processing State of Nice Interaction
		@InvocableVariable
		public String strProcessingState;

		//Retry Count of Nice Interaction
		@InvocableVariable
		public Integer intRetryCount;

		@InvocableVariable
		public String strComments;

		@InvocableVariable
		public String strCallResult;
	}

	/**
	 * @description Processes nice interaction data, update tasks and returns processed results
	 * @param       list_Inputs - List of objects of Input type
	 * @return      List of objects of type Output
	 **/
	@InvocableMethod(label='Do calculations')
	public static List<Output> doCalculations(List<Input> list_Inputs) {
		List<Output> list_Output = new List<Output>();
		List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();
		try {
			// Map of Genesys Interaction Id to Task to so that we can update tasks in bulk
			Map<String, Task> map_GenesysInteractionIdToTask = new Map<String, Task>();
			Map<String, Nice_Interaction__c> map_GenesysInteractionIdToNiceRec = new Map<String, Nice_Interaction__c>();
			for (Input objInput : list_Inputs) {
				Output objOutput = new Output();
				Task objTask = new Task();
				if (String.isNotBlank(objInput.strCallStartDateTime)) {
					objOutput.dateTimeCallStart = getCalculatedDateTime(objInput.strCallStartDateTime);
					objTask.Start_Date__c = objOutput.dateTimeCallStart;
				}
				if (String.isNotBlank(objInput.strCallEndDateTime)) {
					objOutput.dateTimeCallEnd = getCalculatedDateTime(objInput.strCallEndDateTime);
					objTask.Date_Completed__c = objOutput.dateTimeCallEnd;
				}
				if (objInput.intCallDuration != null) {
					objTask.CallDurationInSeconds = objInput.intCallDuration;
				}

				if (String.isNotBlank(objInput.strComments)) {
					objTask.Description = objInput.strComments;
				}

				if (String.isNotBlank(objInput.strCallResult)) {
					objTask.CallDisposition = objInput.strCallResult;
				}

				map_GenesysInteractionIdToTask.put(objInput.strGenesysInteractionId, objTask);
				map_GenesysInteractionIdToNiceRec.put(
					objInput.strGenesysInteractionId,
					new Nice_Interaction__c(Id = objInput.idNiceInteractionId, Processing_State__c = objInput.strProcessingState, Retry_Process_Count__c = objInput.intRetryCount)
				);
				list_Output.add(objOutput);
			}
			//Query related tasks and update them while skipping triggers to avoid lock row errors
			List<Task> list_TasksToUpdate = new List<Task>();
			Map<Id, Task> map_TasksToUpdate = new Map<Id, Task>();
			Map<String, Nice_Interaction__c> map_NiceInteractionsToUpdate = new Map<String, Nice_Interaction__c>();
			for (Task objTaskToUpdate : [
				SELECT Id, CallDurationInSeconds, Date_Completed__c, Start_Date__c, Genesys_Interaction_Id__c, CreatedById, CallDisposition, Description
				FROM Task
				WHERE Genesys_Interaction_Id__c IN :map_GenesysInteractionIdToTask.keySet()
			]) {
				Task objTask = map_GenesysInteractionIdToTask.get(objTaskToUpdate.Genesys_Interaction_Id__c);
				objTaskToUpdate.CallDurationInSeconds = objTask.CallDurationInSeconds;

				// Update only if the task is created by CX One Integration User
				if (objTaskToUpdate.CreatedById == CX_ONE_INTEGRATION_USER_ID || Test.isRunningTest()) {
					Boolean blnUpdate = false;
					if (String.isBlank(objTaskToUpdate.Description)) {
						objTaskToUpdate.Description = objTask.Description;
						blnUpdate = true;
					}

					if (String.isBlank(objTaskToUpdate.CallDisposition)) {
						objTaskToUpdate.CallDisposition = objTask.CallDisposition;
						blnUpdate = true;
					}
					if (blnUpdate) {
						map_TasksToUpdate.put(objTaskToUpdate.Id, objTaskToUpdate);
					}
				}

				if (objTask.Start_Date__c != null && objTask.Date_Completed__c != null) {
					objTaskToUpdate.Date_Completed__c = objTask.Date_Completed__c;
					objTaskToUpdate.Start_Date__c = objTask.Start_Date__c;

					map_TasksToUpdate.put(objTaskToUpdate.Id, objTaskToUpdate);
				}
				//If a task is found, update the corresponding nice interaction record status to processed
				Nice_Interaction__c objNiceInteraction = map_GenesysInteractionIdToNiceRec.get(objTaskToUpdate.Genesys_Interaction_Id__c);
				if (objNiceInteraction != null) {
					objNiceInteraction.Processing_State__c = LogSmartCallingUtil.PROCESSED_STATE;
					map_NiceInteractionsToUpdate.put(objTaskToUpdate.Genesys_Interaction_Id__c, objNiceInteraction);
				}
			}
			//Update nice interaction records that were not found in the task query to retry or error state based on retry count.
			//Nice interaction reprocessor flow should pick these records and try three times before marking them as error.
			for (String strGenesysInteractionId : map_GenesysInteractionIdToNiceRec.keySet()) {
				if (!map_NiceInteractionsToUpdate.containsKey(strGenesysInteractionId)) {
					Nice_Interaction__c objNiceInteraction = map_GenesysInteractionIdToNiceRec.get(strGenesysInteractionId);
					objNiceInteraction.Retry_Process_Count__c = objNiceInteraction.Retry_Process_Count__c == null
						? 0
						: (objNiceInteraction.Retry_Process_Count__c == 3 ? 3 : objNiceInteraction.Retry_Process_Count__c + 1);
					objNiceInteraction.Processing_State__c = objNiceInteraction.Retry_Process_Count__c < 3 ? LogSmartCallingUtil.RETRY_STATE : LogSmartCallingUtil.ERROR_STATE;
					map_NiceInteractionsToUpdate.put(strGenesysInteractionId, objNiceInteraction);
				}
			}
			list_TasksToUpdate = map_TasksToUpdate.values();
			if (!list_TasksToUpdate.isEmpty()) {
				TaskTriggerHelper.skipTrigger = true;
				Database.SaveResult[] list_updateResults = Database.update(list_TasksToUpdate, false);
				for (Integer i = 0; i < list_updateResults.size(); i++) {
					Database.SaveResult objSR = list_updateResults[i];
					if (!objSR.isSuccess()) {
						Exception_Log__c objLog = new Exception_Log__c(
							Type__c = 'ERROR',
							Class_Name__c = LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS,
							Method_Name__c = 'doCalculations tasks update',
							Record_ID__c = objSR.getId(),
							Message__c = objSR.getErrors()[0].getMessage()
						);
						if (map_NiceInteractionsToUpdate.containsKey(list_TasksToUpdate[i].Genesys_Interaction_Id__c)) {
							Nice_Interaction__c objNiceInteraction = map_GenesysInteractionIdToNiceRec.get(list_TasksToUpdate[i].Genesys_Interaction_Id__c);
							objNiceInteraction.Retry_Process_Count__c = objNiceInteraction.Retry_Process_Count__c == null
								? 0
								: (objNiceInteraction.Retry_Process_Count__c == 3 ? 3 : objNiceInteraction.Retry_Process_Count__c + 1);
							objNiceInteraction.Processing_State__c = objNiceInteraction.Retry_Process_Count__c < 3 ? LogSmartCallingUtil.RETRY_STATE : LogSmartCallingUtil.ERROR_STATE;
							map_NiceInteractionsToUpdate.put(list_TasksToUpdate[i].Genesys_Interaction_Id__c, objNiceInteraction);
						}
						list_ExceptionLogs.add(objLog);
					}
				}
				TaskTriggerHelper.skipTrigger = false;
			}
			if (!map_NiceInteractionsToUpdate.values().isEmpty()) {
				update map_NiceInteractionsToUpdate.values();
			}
			if (!list_ExceptionLogs.isEmpty()) {
				insert list_ExceptionLogs;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS, 'doCalculations', objException.getMessage(), objException.getStackTraceString());
		}
		return list_Output;
	}

	/**
	 * @description Helper method to calculate call start and end date time from its string representation on the nice interaction record
	 * @param       strRawDateTime - String representation of date and time
	 * @return      Corresponding date and time value as a dateTime type
	 **/
	public static DateTime getCalculatedDateTime(String strRawDateTime) {
		String strDatePart = strRawDateTime.split(' ')[0];
		String strTimePart = strRawDateTime.split(' ')[1];
		String strMeridiemPart = strRawDateTime.split(' ')[2];
		String strMonthPart = strDatePart.split('/')[0].leftPad(2, '0');
		String strDayPart = strDatePart.split('/')[1].leftPad(2, '0');
		String strFormattedDate = strDatePart.split('/')[2] + '-' + strMonthPart + '-' + strDayPart;
		String strHourPart = strTimePart.split(':')[0];
		String strMinutePart = strTimePart.split(':')[1];
		String strSecondPart = strTimePart.split(':')[2];
		if (strMeridiemPart == 'PM' && strHourPart != '12') {
			strHourPart = String.valueOf(Integer.valueOf(strHourPart) + 12);
		}
		String strFormattedTime = strHourPart + ':' + strMinutePart + ':' + strSecondPart;
		DateTime dtCalculated = DateTime.valueOf(strFormattedDate + ' ' + strFormattedTime);
		return dtCalculated;
	}

	/**
	 * @author      : Debasmita Rawooth
	 * @description : Query Contact Email based on Id.
	 * @param       : strContactId - Contact Record Id
	 * @return      : Boolean based on if Contact has email.
	 **/
	@AuraEnabled
	public static Boolean checkContactEmail(String strContactId) {
		Contact objContact = [SELECT Id, Email FROM Contact WHERE Id = :strContactId];
		if (!String.isBlank(objContact.Email)) {
			return true;
		} else
			return false;
	}
}