/**
 * @description  Used for configuring rule sets for Next Best Action
 * @author       Praveen Sethu
 * @date         07-19-2023
 * @see          RuleSetControllerTest
 **/
public without sharing class RuleSetController {
	public final static String NBA_RULE_SET_PERMISSION = 'NBA_Rule_Set_Edit';
	// Custom exception class
	public class RuleSetException extends Exception {
	}

	/**
	 * @description  Wrapper class used to share data between LWC and Apex Class
	 **/
	public class RuleSetWrapper {
		// Success or Error Message
		@AuraEnabled
		public String strMessage;

		// Success or Error Flag
		@AuraEnabled
		public Boolean blnIsSuccess;

		// List of NBA Rule Sets
		@AuraEnabled
		public List<NBA_Rule_Set__c> list_Rules = new List<NBA_Rule_Set__c>();

		// Flag to indicate if user has edit access to NBA rule sets
		@AuraEnabled
		public Boolean blnHasPermissions = false;

		// List of unique team names
		@AuraEnabled
		public List<String> list_TeamNames = new List<String>();

		// List of Opportunities to be displayed in the modal window
		@AuraEnabled
		public List<Opportunity> list_ModalOpps = new List<Opportunity>();

		// List of leads to be displayed in the modal window
		@AuraEnabled
		public List<Lead> list_ModalLeads = new List<Lead>();

		@AuraEnabled
		public NBA_Rule_Set__c objRuleSet = new NBA_Rule_Set__c();

		// List of User roles from the system
		@AuraEnabled
		public List<UserRole> list_UserRoles = new List<UserRole>();

		// List of User skills from the system
		@AuraEnabled
		public List<Skill> list_Skills = new List<Skill>();

		// NBA Rule Set Configuration object
		@AuraEnabled
		public NBA_Rule_Set_Configuration__c objConfig = new NBA_Rule_Set_Configuration__c();

		// Base URL for the org
		@AuraEnabled
		public String strBaseURL = URL.getSalesforceBaseUrl().toExternalForm();

		// Number of leads available in a rule
		@AuraEnabled
		public Integer intLeadsCount = 0;

		// Number of opportunities available in a rule
		@AuraEnabled
		public Integer intOppsCount = 0;

		// Date when the rule was last refreshed
		@AuraEnabled
		public DateTime dtLastRefreshedDate;

		@AuraEnabled
		public List<NBA_Rule_Set_Skill__c> list_RuleSkills;

		@AuraEnabled
		public Boolean blnSkillsChanged;

		@AuraEnabled
		public List<ViewRecordsResponse> list_ViewRecords = new List<ViewRecordsResponse>();

		@AuraEnabled
		public Map<Id, String> map_HoldOutErrors = new Map<Id, String>();

		@AuraEnabled
		public String strOrgId = UserInfo.getOrganizationId();

		// Parameterized Constructors
		public RuleSetWrapper(Boolean blnIsSuccess, String strMessage) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
		}

		public RuleSetWrapper(Boolean blnIsSuccess, String strMessage, List<NBA_Rule_Set__c> list_Rules, NBA_Rule_Set_Configuration__c objConfig, List<Skill> list_Skills) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.list_Rules = list_Rules;
			this.objConfig = objConfig;
			this.list_Skills = list_Skills;
		}

		public RuleSetWrapper(Boolean blnIsSuccess, String strMessage, List<String> list_TeamNames, Boolean blnHasPermissions, List<UserRole> list_UserRoles) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.list_TeamNames = list_TeamNames;
			this.blnHasPermissions = blnHasPermissions;
			this.list_UserRoles = list_UserRoles;
		}

		public RuleSetWrapper(Boolean blnIsSuccess, String strMessage, List<Lead> list_Leads, List<Opportunity> list_Opps, NBA_Rule_Set__c objRuleSet) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.list_ModalLeads = list_Leads;
			this.list_ModalOpps = list_Opps;
			this.objRuleSet = objRuleSet;
		}

		public RuleSetWrapper(Boolean blnIsSuccess, String strMessage, NBA_Rule_Set_Configuration__c objConfig) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.objConfig = objConfig;
		}

		public RuleSetWrapper(Boolean blnIsSuccess, String strMessage, NBA_Rule_Set__c objRuleSet) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.objRuleSet = objRuleSet;
		}

		public RuleSetWrapper(Boolean blnIsSuccess, String strMessage, NBA_Rule_Set__c objRuleSet, List<ViewRecordsResponse> list_ViewRecords) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.objRuleSet = objRuleSet;
			this.list_ViewRecords = list_ViewRecords;
		}
	}

	public class ViewRecordsResponse {
		@AuraEnabled
		public String strTitle;

		@AuraEnabled
		public List<Sobject> list_SObjects = new List<Sobject>();

		@AuraEnabled
		public List<String> list_Columns = new List<String>();

		@AuraEnabled
		public List<String> list_Titles = new List<String>();

		@AuraEnabled
		public Boolean blnRecordsAvailable = false;
	}

	/**
	 * @description Gets list of rules for a given team name
	 * @param       String - Name of the team
	 * @return      List of NBA Rule Sets (Both Active and Inactive)
	 **/
	@AuraEnabled
	public static RuleSetWrapper getRuleSet(String strTeamName) {
		List<NBA_Rule_Set__c> list_Rules = new List<NBA_Rule_Set__c>();
		List<Skill> list_Skills = new List<Skill>();
		try {
			list_Rules = [
				SELECT
					Id,
					Name,
					Rule_Name__c,
					Description__c,
					Is_Active__c,
					Priority__c,
					Weighting__c,
					Rule_Set_Name__c,
					CreatedBy.Name,
					LastModifiedBy.Name,
					Rule_Last_Updated_By__r.Name,
					CreatedDate,
					LastModifiedDate,
					Rule_Last_Updated_Time__c,
					Record_Count__c,
					FORMAT(Last_Refreshed_Date__c),
					Last_Ran_With_Zero_Records__c,
					(SELECT Id, Name, Skill_Id__c, Skill_Level__c, Operator__c FROM NBA_Rule_Set_Skills__r),
					(SELECT Id, Performance__c FROM NBA_Rule_Criteria__r),
					Hold_Out_Percentage__c,
					Rule_Skills_Criteria_Logic__c
				FROM NBA_Rule_Set__c
				WHERE NBA_Rule_Set_Configuration__r.Name = :strTeamName
				ORDER BY Priority__c ASC
			];
			Date objYesterday = Date.today().addDays(-1);
			NBA_Rule_Set_Configuration__c objConfig = [
				SELECT Id, Name, User_Roles__c, Team_Skill_Type__c, Available_Refreshes_Per_Day__c, Refreshes_Triggered_Today__c, Last_Refresh_All_Date__c
				FROM NBA_Rule_Set_Configuration__c
				WHERE Name = :strTeamName
			];
			Date objRuleDate = (objConfig.Last_Refresh_All_Date__c != null) ? objConfig.Last_Refresh_All_Date__c.date() : null;
			//validating if the configuration needs to reset the Refreshes_Triggered_Today__c
			if (
				(objConfig.Available_Refreshes_Per_Day__c >= objConfig.Refreshes_Triggered_Today__c && (objRuleDate <= objYesterday || objRuleDate == null)) ||
				objConfig.Refreshes_Triggered_Today__c == null
			) {
				objConfig.Refreshes_Triggered_Today__c = 0;
				update objConfig;
			}

			if (String.isNotBlank(objConfig.Team_Skill_Type__c)) {
				list_Skills = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE Type.MasterLabel = :objConfig.Team_Skill_Type__c];
			}
			return new RuleSetWrapper(true, 'Rule Set Retrieved Successfully', list_Rules, objConfig, list_Skills);
		} catch (Exception objEx) {
			return new RuleSetWrapper(false, objEx.getMessage(), list_Rules, null, list_Skills);
		}
	}

	/**
	 * @description Get list of unique rule set names. Used as values for dropdown in LWC
	 * @return      Wrapper object along with list of unique rule set names
	 **/
	@AuraEnabled
	public static RuleSetWrapper getRuleSets() {
		Set<String> set_Rules = new Set<String>();
		List<String> list_Rules = new List<String>();
		List<UserRole> list_UserRole = new List<UserRole>();
		try {
			for (NBA_Rule_Set_Configuration__c objConfig : [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c]) {
				set_Rules.add(objConfig.Name);
			}
			list_UserRole = [SELECT Id, Name FROM UserRole];
		} catch (Exception e) {
			return new RuleSetWrapper(false, e.getMessage(), list_Rules, false, list_UserRole);
		}
		list_Rules.addAll(set_Rules);
		RuleSetWrapper objWrapperResponse = new RuleSetWrapper(true, 'Rule Set Retrieved Successfully', list_Rules, validateRuleSetEditPermission(), list_UserRole);
		return objWrapperResponse;
	}

	/**
	 * @description Updates list of rules that we get from LWC
	 * @param      Input list of rules received from LWC
	 * @return     Wrapper object along with success flag and message
	 **/
	@AuraEnabled
	public static RuleSetWrapper updateRuleSets(List<NBA_Rule_Set__c> list_Rules, String strRuleSkillsData) {
		Savepoint objSavepoint = Database.setSavepoint();
		try {
			update list_Rules;
			//Get Custom Settings
			Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
			if (objConfig.NBA_Enforce_Batching_Rule_Set_Size__c != null && objConfig.NBA_Default_Rules_per_Execution__c != null && strRuleSkillsData == null) {
				Integer intActiveRules = 0;
				for (NBA_Rule_Set__c objRule : list_Rules) {
					if (objRule.Is_Active__c) {
						intActiveRules++;
					}
				}
				NBA_Rule_Set_Configuration__c objConfigRecord = [SELECT Id, Rules_per_Execution__c FROM NBA_Rule_Set_Configuration__c WHERE Id = :list_Rules[0].NBA_Rule_Set_Configuration__c];
				if (intActiveRules >= objConfig.NBA_Enforce_Batching_Rule_Set_Size__c && objConfigRecord.Rules_per_Execution__c == null) {
					objConfigRecord.Rules_per_Execution__c = objConfig.NBA_Default_Rules_per_Execution__c;
					update objConfigRecord;
				} else if (intActiveRules < objConfig.NBA_Enforce_Batching_Rule_Set_Size__c && objConfigRecord.Rules_per_Execution__c != null) {
					objConfigRecord.Rules_per_Execution__c = null;
					update objConfigRecord;
				}
			}
			//Validate If we need to update the configuration for batching
			//If yes, update the configuration
			// If rule skills are changed, delete existing skills and insert new skills
			if (String.isNotBlank(strRuleSkillsData) && strRuleSkillsData != 'null') {
				RuleSetWrapper objRuleWrapper = (RuleSetWrapper) System.JSON.deserialize(strRuleSkillsData, RuleSetWrapper.class);
				if (objRuleWrapper.blnSkillsChanged) {
					List<NBA_Rule_Set_Skill__c> list_Skills = [SELECT Id FROM NBA_Rule_Set_Skill__c WHERE NBA_Rule_Set__c = :list_Rules[0].Id];
					if (!list_Skills.isEmpty()) {
						delete list_Skills;
					}
					if (!objRuleWrapper.list_RuleSkills.isEmpty()) {
						List<NBA_Rule_Set_Skill__c> list_SkillsToInsert = new List<NBA_Rule_Set_Skill__c>();
						for (NBA_Rule_Set_Skill__c skill : objRuleWrapper.list_RuleSkills) {
							skill.Id = null;
							list_SkillsToInsert.add(skill);
						}
						insert list_SkillsToInsert;
					}
				}
			}
			return new RuleSetWrapper(true, 'Rule Set Updated Successfully');
		} catch (Exception objEx) {
			Database.rollBack(objSavepoint);
			return new RuleSetWrapper(false, objEx.getMessage());
		}
	}

	/**
	 * @description Method used to validate if user has edit access to NBA rule sets
	 * @return     Wrapper object along with permission flag
	 **/
	public static Boolean validateRuleSetEditPermission() {
		Boolean blnHasPermission = false;
		List<PermissionSetAssignment> list_PSA = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = :NBA_RULE_SET_PERMISSION];

		if (list_PSA != null && !list_PSA.isEmpty() && list_PSA.size() == 1) {
			blnHasPermission = true;
		}
		return blnHasPermission;
	}

	/**
	 * @description Save rule set configuration. Also validates if 1 user role is assigned to only 1 configuration record
	 * @param      String - Name of rule set configuration
	 * @param      String - List of associated user roles
	 * @return     Wrapper object along with success flag, message
	 **/
	@AuraEnabled
	public static RuleSetWrapper saveRuleSetConfig(String strTeamName, String strUserRole) {
		try {
			// if user roles are not blank, validate if user role is not assgined to any other configuration record
			if (String.isNotBlank(strUserRole)) {
				// split the user roles by comma
				List<String> list_Roles = strUserRole.split(',');

				// Iterate over all configuration records and check if user role is already assigned to any other configuration record
				for (NBA_Rule_Set_Configuration__c objConfig : [SELECT Id, Name, User_Roles__c FROM NBA_Rule_Set_Configuration__c WHERE Name != :strTeamName]) {
					Boolean blnExceptionFound = false;
					List<String> list_ExistingRoles = String.isNotBlank(objConfig.User_Roles__c) ? objConfig.User_Roles__c.split(',') : new List<String>();

					// if configuration record is found, throw the exception
					for (String strRole : list_Roles) {
						if (list_ExistingRoles.contains(strRole)) {
							blnExceptionFound = true;
							throw new RuleSetException(strRole + ' is already assigned to ' + objConfig.Name + ' configuration. Please remove ' + strRole);
						}
					}
				}
			}

			// if user roles are not linked to any other configuration record, update the configuration record and send success message
			NBA_Rule_Set_Configuration__c objConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c WHERE Name = :strTeamName];
			objConfig.User_Roles__c = strUserRole;
			update objConfig;
			return new RuleSetWrapper(true, null, objConfig);
		} catch (Exception ex) {
			// In case of exception, send error message
			return new RuleSetWrapper(false, ex.getMessage(), new NBA_Rule_Set_Configuration__c(Name = strTeamName));
		}
	}

	/**
	 * @description Get count of records for each object in a rule set
	 * @param      Id - Id of the rule set record
	 * @return     Wrapper object along with success flag, message
	 **/
	@AuraEnabled
	public static RuleSetWrapper getRecordCount(Id idRecord) {
		try {
			// Get data from Rule Set record
			NBA_Rule_Set__c objRuleSet = [
				SELECT Id, Rule_Name__c, (SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c FROM NBA_Rule_Criteria__r)
				FROM NBA_Rule_Set__c
				WHERE Id = :idRecord
			];

			String strRecordCount = '';
			// if no criteria found, return the message
			if (objRuleSet.NBA_Rule_Criteria__r.isEmpty()) {
				strRecordCount = 'No criteria found.';
			} else {
				for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
					if (String.isNotBlank(objCriteria.Current_Criteria__c)) {
						NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);
						DescribeSObjectResult objDescribe = Utils.getSObjectDescribe(objCriteria.Base_Object__c);
						String strBaseObject = objDescribe.getLabel();
						Map<String, Schema.SObjectField> map_Fields = objDescribe.fields.getMap();

						// build the soql query with the fields and criteria
						String strQuery = 'SELECT COUNT() FROM ' + objCriteria.Base_Object__c + ' WHERE ' + objRequest.soqlQuery;
						if (strQuery.contains('ORDER BY')) {
							strQuery = strQuery.substring(0, strQuery.indexOf('ORDER BY'));
						}

						strQuery = NBAUtil.convertCustomFunctionsToSOQL(strQuery);

						// use count query to get the number of records
						Integer intCount = Database.countQuery(strQuery);
						String strTypeOfServingRecord = '';
						// get plural label of the serving object
						if (objRequest.servingField == 'Id') {
							strTypeOfServingRecord = objDescribe.getLabelPlural();
						} else {
							Schema.SObjectField objField = map_Fields.get(objRequest.servingField);
							String strReferenceObject = objField.getDescribe().getReferenceTo().size() > 0 ? String.valueOf(objField.getDescribe().getReferenceTo()[0]) : '';
							objDescribe = Utils.getSObjectDescribe(strReferenceObject);
							strTypeOfServingRecord = objDescribe.getLabelPlural();
						}

						strRecordCount = strRecordCount + 'Number of ' + strTypeOfServingRecord + ': ' + intCount + '\n';
					}
				}
			}
			// set the record count and last refreshed date
			objRuleSet.Record_Count__c = strRecordCount;
			objRuleSet.Last_Refreshed_Date__c = System.now();

			update objRuleSet;

			// Query the rule set record and return it to LWC
			NBA_Rule_Set__c objRuleSetToReturn = [
				SELECT Id, Record_Count__c, Last_Refreshed_Date__c, Last_Ran_With_Zero_Records__c, LastModifiedDate, LastModifiedBy.Name, Rule_Last_Updated_By__r.Name, Rule_Last_Updated_Time__c
				FROM NBA_Rule_Set__c
				WHERE Id = :idRecord
			];
			// Set success message and return the wrapper object
			return new RuleSetWrapper(true, 'Record count updated successfully', objRuleSetToReturn);
		} catch (Exception ex) {
			return new RuleSetWrapper(false, ex.getMessage(), new NBA_Rule_Set__c(Id = idRecord));
		}
	}

	/**
	 * @description Get records from the rule set
	 * @return      Wrapper object along with success flag, message
	 **/
	@AuraEnabled
	public static RuleSetWrapper getRecordsFromRuleNew(Id idRecordId) {
		// label used to store number of records to be displayed
		String strNBARecordViewSize = System.Label.NBA_Record_View_Size;
		// Get data from Rule Set record
		NBA_Rule_Set__c objRuleSet = [
			SELECT Id, Rule_Name__c, (SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c FROM NBA_Rule_Criteria__r)
			FROM NBA_Rule_Set__c
			WHERE Id = :idRecordId
		];
		List<ViewRecordsResponse> list_ViewRecords = new List<ViewRecordsResponse>();

		// if no criteria found, return the message
		if (objRuleSet.NBA_Rule_Criteria__r.isEmpty()) {
			return new RuleSetWrapper(true, 'No criteria found.', objRuleSet, list_ViewRecords);
		} else {
			// iterate over each criteria and get the records
			for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
				if (String.isNotBlank(objCriteria.Current_Criteria__c)) {
					ViewRecordsResponse objViewRecords = new ViewRecordsResponse();
					// deserialize the criteria and get the fields to be displayed
					NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);
					DescribeSObjectResult objDescribe = Utils.getSObjectDescribe(objCriteria.Base_Object__c);
					String strBaseObject = objDescribe.getLabel();
					Map<String, Schema.SObjectField> map_Fields = objDescribe.fields.getMap();

					List<String> list_FieldNames = new List<String>();
					List<String> list_AdditionalFieldNames = new List<String>();
					List<String> list_Titles = new List<String>();
					if (objRequest.displayFieldsList != null) {
						for (NBARequestWrapper.DisplayFieldsList objField : objRequest.displayFieldsList) {
							list_FieldNames.add(objField.selectedFieldAPI);
							list_Titles.add(objField.customText);
						}
					}

					// if the dields dont contain id and name, add them to the list to additional fields
					if (!list_FieldNames.contains('id')) {
						list_AdditionalFieldNames.add('id');
					}

					if (!list_FieldNames.contains('name') && map_Fields.containsKey('name')) {
						list_AdditionalFieldNames.add('name');
					}

					// if name field is added to the list, add id field to the list of additional fields
					if (objRequest.displayFieldsList != null) {
						for (NBARequestWrapper.DisplayFieldsList objField : objRequest.displayFieldsList) {
							if (objField.selectedFieldAPI.endsWith('.name')) {
								Integer intLastIndex = objField.selectedFieldAPI.lastIndexOf('.name');

								// add id field to the list of additional fields
								if (intLastIndex != -1) {
									String strIdField = objField.selectedFieldAPI.substring(0, intLastIndex) + '.id';
									if (!list_FieldNames.contains(strIdField)) {
										list_AdditionalFieldNames.add(strIdField);
									}
								}
							}
						}
					}

					String strFieldNames = String.join(list_FieldNames, ',');
					if (!list_AdditionalFieldNames.isEmpty()) {
						strFieldNames = strFieldNames + ',' + String.join(list_AdditionalFieldNames, ',');
					}

					// build the soql query with the fields and criteria
					String strQuery = 'SELECT ' + strFieldNames + ' FROM ' + objCriteria.Base_Object__c + ' WHERE ' + objRequest.soqlQuery + ' LIMIT ' + strNBARecordViewSize;
					strQuery = NBAUtil.convertCustomFunctionsToSOQL(strQuery);

					// query the records and add them to the list
					List<Sobject> list_Sobjects = Database.query(strQuery);
					String strTypeOfServingRecord = '';

					// get the plural label of the serving object
					if (objRequest.servingField.equalsIgnoreCase('Id')) {
						strTypeOfServingRecord = objDescribe.getLabelPlural();
					} else {
						Schema.SObjectField objField = map_Fields.get(objRequest.servingField);
						String strReferenceObject = objField.getDescribe().getReferenceTo().size() > 0 ? String.valueOf(objField.getDescribe().getReferenceTo()[0]) : '';
						objDescribe = ((SObject) Type.forName(strReferenceObject).newInstance()).getSObjectType().getDescribe();
						strTypeOfServingRecord = objDescribe.getLabelPlural();
					}
					// set title of each object
					objViewRecords.strTitle = 'Base object: ' + strBaseObject + ' - ' + ' Top ' + strNBARecordViewSize + ' ' + strTypeOfServingRecord;
					objViewRecords.list_Columns = list_FieldNames;
					objViewRecords.list_Titles = list_Titles;
					objViewRecords.blnRecordsAvailable = list_Sobjects.size() > 0;
					objViewRecords.list_SObjects = list_Sobjects;
					list_ViewRecords.add(objViewRecords);
				}
			}
		}

		return new RuleSetWrapper(true, 'Records Retrieved Successfully', objRuleSet, list_ViewRecords);
	}

	/**
	 * @description Creates new rule criteria record - accepts two paramets - Rule Set object and Id of the rule to be cloned
	 * @return      Wrapper object along with success flag, message
	 **/
	@AuraEnabled
	public static RuleSetWrapper createNewRuleSet(NBA_Rule_Set__c objRuleSet, Id idCloneRule) {
		try {
			// Set default field values before inserting the record
			objRuleSet.Rule_Last_Updated_By__c = UserInfo.getUserId();
			objRuleSet.Rule_Last_Updated_Time__c = System.now();
			objRuleSet.Rule_Frequency_Minutes__c = 5;

			insert objRuleSet;

			// if id of clone rule set is not null - fetch the criteria records from the clone rule set and insert them into the new rule set
			if (idCloneRule != null) {
				List<NBA_Rule_Criteria__c> list_Criteria = new List<NBA_Rule_Criteria__c>();
				NBA_Rule_Set__c objCloneRule = [SELECT Id, (SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c FROM NBA_Rule_Criteria__r) FROM NBA_Rule_Set__c WHERE Id = :idCloneRule];

				if (!objCloneRule.NBA_Rule_Criteria__r.isEmpty()) {
					for (NBA_Rule_Criteria__c objCriteria : objCloneRule.NBA_Rule_Criteria__r) {
						NBA_Rule_Criteria__c objNewCriteria = new NBA_Rule_Criteria__c();
						// clone fields (base object, current criteria, talking points, rule set id) to the new criteria record
						objNewCriteria.Base_Object__c = objCriteria.Base_Object__c;
						objNewCriteria.Current_Criteria__c = objCriteria.Current_Criteria__c;
						objNewCriteria.Talking_Points__c = objCriteria.Talking_Points__c;
						objNewCriteria.NBA_Rule_Set__c = objRuleSet.Id;
						list_Criteria.add(objNewCriteria);
					}
					insert list_Criteria;
				}
			}

			return new RuleSetWrapper(true, 'Rule Set Created Successfully', objRuleSet);
		} catch (Exception objEx) {
			return new RuleSetWrapper(false, objEx.getMessage(), objRuleSet);
		}
	}

	/**
	 * @description Creates a new record of rule set configuration
	 * @return      Wrapper object along with success flag, message
	 **/
	@AuraEnabled
	public static RuleSetWrapper createNewRuleConfig(NBA_Rule_Set_Configuration__c objRuleSetConfig) {
		try {
			insert objRuleSetConfig;

			return new RuleSetWrapper(true, 'Rule Set Config created Successfully', objRuleSetConfig);
		} catch (Exception objEx) {
			return new RuleSetWrapper(false, objEx.getMessage(), objRuleSetConfig);
		}
	}

	/**
	 * @description Checks if all serving objects involved in the rule set have hold out field
	 * @return      Wrapper object along with success flag, message
	 **/
	@AuraEnabled
	public static RuleSetWrapper holdOutValidation(List<NBA_Rule_Set__c> list_Rules) {
		Map<Id, String> map_HoldOutErrors = new Map<Id, String>();
		String strHoldOutField = 'Hold_Out_Record__c';
		try {
			list_Rules = [SELECT Id, (SELECT Id, Current_Criteria__c FROM NBA_Rule_Criteria__r) FROM NBA_Rule_Set__c WHERE Id IN :list_Rules];
			for (NBA_Rule_Set__c objRule : list_Rules) {
				if (objRule.NBA_Rule_Criteria__r.isEmpty()) {
					map_HoldOutErrors.put(objRule.Id, 'Hold out cannot be configured for a rule with empty criteria');
				} else {
					List<String> list_MissingObjects = new List<String>();
					for (NBA_Rule_Criteria__c objCriteria : objRule.NBA_Rule_Criteria__r) {
						if (String.isNotBlank(objCriteria.Current_Criteria__c)) {
							NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);
							DescribeSObjectResult objDescribe = Utils.getSObjectDescribe(objRequest.servingObject);
							String strBaseObject = objDescribe.getLabel();
							Map<String, Schema.SObjectField> map_Fields = objDescribe.fields.getMap();

							if (!map_Fields.containsKey(strHoldOutField)) {
								list_MissingObjects.add(objRequest.servingObject);
							} else {
								String strFieldType = map_Fields.get(strHoldOutField).getDescribe().getType().name();
								if (strFieldType != 'MULTIPICKLIST') {
									list_MissingObjects.add(objRequest.servingObject);
								}
							}
						}
					}

					if (!list_MissingObjects.isEmpty()) {
						map_HoldOutErrors.put(objRule.Id, 'Hold out cannot be configured for ' + String.join(list_MissingObjects, ', ') + ' as it does not not have hold out field');
					}
				}
			}

			RuleSetWrapper objWrapper = new RuleSetWrapper(true, 'Hold out validation completed');
			objWrapper.map_HoldOutErrors = map_HoldOutErrors;
			return objWrapper;
		} catch (Exception objEx) {
			return new RuleSetWrapper(false, objEx.getMessage());
		}
	}

	/**
	 * @description Method used to generate JSON for rule set skills. Used in test classes. Helper method to be used to backfill the skills
	 * @param      List of rule set skills
	 * @param      String - Logic to be applied between the skills
	 * @return     JSON string
	 * @see        NBAServeRecordTest.testNBARuleWithAnyServiceResourceSkill
	 **/
	public static String generateSkillsCriteriaJson(List<NBA_Rule_Set_Skill__c> list_ruleSetSkills, String strLogic) {
		String strJson = '{"list_RuleSkills": [';
		String strCriteriaLogic = '"criteriaLogic": "';
		Integer intOrder = 1;
		for (NBA_Rule_Set_Skill__c objSkill : list_ruleSetSkills) {
			strJson += '{"NBA_Rule_Set__c" : "' + objSkill.NBA_Rule_Set__c + '","Id": "' + objSkill.Id + '","Name": "' + objSkill.Name + '", "Skill_Id__c": "' + objSkill.Skill_Id__c + '",';
			if (String.isNotBlank(objSkill.Skill_Level__c) && objSkill.Skill_Level__c != 'null') {
				strJson += '"Skill_Level__c": "' + objSkill.Skill_Level__c + '",';
			}
			if (String.isNotBlank(objSkill.Operator__c) && objSkill.Operator__c != 'null' && objSkill.Operator__c != '--None--') {
				strJson += '"Operator__c": "' + objSkill.Operator__c + '",';
			}
			strJson += '"Order": "' + intOrder + '"},';
			strCriteriaLogic += intOrder + ' ' + strLogic + ' ';
			intOrder++;
		}
		strCriteriaLogic = strCriteriaLogic.removeEnd(' ' + strLogic + ' ') + '",';
		strJson = strJson.removeEnd(',') + '],' + strCriteriaLogic + '"logic": "' + strLogic + '"}';
		return strJson;
	}

	/**
	 * @description Get count of records for each object in a rule set configuration
	 * @param      Id - Id of the rule set configuration record
	 * @return     Wrapper object along with success flag, message
	 **/
	@AuraEnabled
	public static RuleSetWrapper refreshAllRules(Id idRecord) {
		try {
			// Get data from Rule Set record
			List<NBA_Rule_Set__c> list_RuleSet = [
				SELECT Id, Rule_Name__c, Name, (SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c FROM NBA_Rule_Criteria__r), NBA_Rule_Set_Configuration__r.Refreshes_Triggered_Today__c
				FROM NBA_Rule_Set__c
				WHERE NBA_Rule_Set_Configuration__c = :idRecord
			];
			List<String> list_RuleSetWithError = new List<String>();
			// if no criteria found, return the message
			if (!list_RuleSet.isEmpty()) {
				String strRecordCount = '';
				Decimal decimalRefreshAllAvailable = list_RuleSet[0].NBA_Rule_Set_Configuration__r.Refreshes_Triggered_Today__c;
				decimalRefreshAllAvailable = (decimalRefreshAllAvailable == null) ? 0 : decimalRefreshAllAvailable;
				List<NBA_Rule_Set__c> list_RuleSetToRefresh = new List<NBA_Rule_Set__c>();
				for (NBA_Rule_Set__c objRuleSet : list_RuleSet) {
					Boolean blnIsValidCriteria = true;
					if (objRuleSet.NBA_Rule_Criteria__r.isEmpty()) {
						strRecordCount = 'No criteria found.';
					} else {
						strRecordCount = '';
						for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
							if (String.isNotBlank(objCriteria.Current_Criteria__c)) {
								NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);
								DescribeSObjectResult objDescribe = Utils.getSObjectDescribe(objCriteria.Base_Object__c);
								String strBaseObject = objDescribe.getLabel();
								Map<String, Schema.SObjectField> map_Fields = objDescribe.fields.getMap();

								// build the soql query with the fields and criteria
								String strQuery = 'SELECT COUNT() FROM ' + objCriteria.Base_Object__c + ' WHERE ' + objRequest.soqlQuery;
								if (strQuery.contains('ORDER BY')) {
									strQuery = strQuery.substring(0, strQuery.indexOf('ORDER BY'));
								}

								strQuery = NBAUtil.convertCustomFunctionsToSOQL(strQuery);

								// use count query to get the number of records
								try {
									Integer intCount = Database.countQuery(strQuery);
									String strTypeOfServingRecord = '';
									// get plural label of the serving object
									if (objRequest.servingField == 'Id') {
										strTypeOfServingRecord = objDescribe.getLabelPlural();
									} else {
										Schema.SObjectField objField = map_Fields.get(objRequest.servingField);
										String strReferenceObject = objField.getDescribe().getReferenceTo().size() > 0 ? String.valueOf(objField.getDescribe().getReferenceTo()[0]) : '';
										objDescribe = Utils.getSObjectDescribe(strReferenceObject);
										strTypeOfServingRecord = objDescribe.getLabelPlural();
									}
									strRecordCount = strRecordCount + 'Number of ' + strTypeOfServingRecord + ': ' + intCount + '\n';
								} catch (Exception e) {
									blnIsValidCriteria = false;
									list_RuleSetWithError.add(objRuleSet.Rule_Name__c);
								}
							}
						}
					}
					if (blnIsValidCriteria) {
						// set the record count and last refreshed date
						objRuleSet.Record_Count__c = strRecordCount;
						objRuleSet.Last_Refreshed_Date__c = System.now();
						list_RuleSetToRefresh.add(objRuleSet);
					}
				}
				update list_RuleSetToRefresh;
				update new NBA_Rule_Set_Configuration__c(ID = idRecord, Refreshes_Triggered_Today__c = (decimalRefreshAllAvailable + 1), Last_Refresh_All_Date__c = Datetime.now());
			}
			RuleSetWrapper objWrapper = new RuleSetWrapper(true, 'Refresh all rules record count completed successfully!');
			if (list_RuleSetWithError.size() > 0) {
				objWrapper.strMessage =
					'The Rule Set has refreshed. All rules successfully refreshed except for: ' +
					String.join(list_RuleSetWithError, ', ') +
					'. Please check the criteria for the listed rule(s) and refresh individually.';
			}
			return objWrapper;
		} catch (Exception ex) {
			RuleSetWrapper objWrapper = new RuleSetWrapper(false, ex.getMessage());
			return objWrapper;
		}
	}

	/**
	 * @description Returns performance of the rule criteria record
	 * @param      Id of the NBA Rule Set record
	 * @return     Returns the object that has the performance value
	 **/
	@AuraEnabled
	public static List<NBA_Rule_Criteria__c> checkPerformance(Id idRuleSet) {
		return [SELECT Id, Performance__c FROM NBA_Rule_Criteria__c WHERE NBA_Rule_Set__c = :idRuleSet];
	}
}