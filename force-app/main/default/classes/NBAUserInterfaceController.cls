/**
 * @description  Apex class that has business logic related to the NBA User Interface
 * @author       Praveen Sethu
 * @date         01-29-2024
 * @see          NBAUserInterfaceControllerTest
 **/
public without sharing class NBAUserInterfaceController {
	public class NBAUserInterfaceWrapper {
		// Show error or success message if any
		@AuraEnabled
		public String strMessage;

		// Indicate if apex class has thrown an error
		@AuraEnabled
		public Boolean blnError;

		// NBA Rule Set object
		@AuraEnabled
		public NBA_Rule_Set__c objRuleSet;

		// Map of available objects fetched from custom metadata
		@AuraEnabled
		public Map<String, String> map_AvailableObjects = new Map<String, String>();

		// Indicate if logged in user has edit access to the rule set
		@AuraEnabled
		public Boolean blnViewOnlyAccess;

		// Map of reference fields api and label
		@AuraEnabled
		public Map<String, String> map_ReferenceFields = new Map<String, String>();

		// Map of all object fields api and label
		@AuraEnabled
		public Map<String, FieldWrapper> map_AllFields = new Map<String, FieldWrapper>();

		// label of the object
		@AuraEnabled
		public String strObjectLabel;

		// list of requests containing the rules
		@AuraEnabled
		public List<NBARequestWrapper> list_Requests = new List<NBARequestWrapper>();

		// list of old requests to store previous version
		@AuraEnabled
		public List<NBARequestWrapper> list_OldRequests = new List<NBARequestWrapper>();

		// map of object name to map of field api and field wrapper
		@AuraEnabled
		public Map<String, Map<String, FieldWrapper>> map_ObjectFields = new Map<String, Map<String, FieldWrapper>>();

		// Time taken to execute the query
		@AuraEnabled
		public Decimal dblTimeTakenSeconds;

		// load view records template
		@AuraEnabled
		public List<NBA_View_Records_Template__mdt> list_ViewRecordsTemplate = NBA_View_Records_Template__mdt.getAll().values();

		// All active users in the org
		@AuraEnabled
		public List<User> list_ActiveUsers = new List<User>();

		@AuraEnabled
		public Map<String, Map<Id, String>> map_Queues = new Map<String, Map<Id, String>>();

		// adding a constructor to initialize the wrapper
		public NBAUserInterfaceWrapper(String strMessage, Boolean blnError, NBA_Rule_Set__c objRuleSet, Map<String, String> map_AvailableObjects, Boolean blnViewOnlyAccess) {
			this.strMessage = strMessage;
			this.blnError = blnError;
			this.objRuleSet = objRuleSet;
			this.map_AvailableObjects = map_AvailableObjects;
			this.blnViewOnlyAccess = blnViewOnlyAccess;
		}

		// adding a constructor to initialize the wrapper
		public NBAUserInterfaceWrapper(String strMessage, Boolean blnError, Map<String, String> map_ReferenceFields, Map<String, FieldWrapper> map_AllFields) {
			this.strMessage = strMessage;
			this.blnError = blnError;
			this.map_ReferenceFields = map_ReferenceFields;
			this.map_AllFields = map_AllFields;
		}

		public NBAUserInterfaceWrapper(String strMessage, Boolean blnError) {
			this.strMessage = strMessage;
			this.blnError = blnError;
		}
	}

	/**
	 * @description Custom wraper class to hold and return custom and standard fields data
	 **/
	public class FieldWrapper {
		// Object name
		@AuraEnabled
		public String strObjectName;

		// field label
		@AuraEnabled
		public String strFieldLabel;

		// api name of the field
		@AuraEnabled
		public String strFieldAPIName;

		// field data type (e.g. reference, text, number etc)
		@AuraEnabled
		public String strFieldType;

		// if field is lookup or master object, this will hold name of reference object
		@AuraEnabled
		public String strReferenceObject;

		// if field is lookup or master object, this will hold relationship name (lead__r, opportunity__r etc)
		@AuraEnabled
		public String strRelationshipName;

		// list of relationships
		@AuraEnabled
		public List<String> list_Relationships = new List<String>();

		@AuraEnabled
		public List<String> list_PicklistValues = new List<String>();

		// Indicates if a field is updateable
		@AuraEnabled
		public Boolean blnUpdateable = false;

		// Indicates if a field is nillable
		@AuraEnabled
		public Boolean blnNillable = false;

		// contstructor to initialize the wrapper
		public FieldWrapper(
			String strObjectName,
			String strFieldLabel,
			String strFieldAPIName,
			String strFieldType,
			String strReferenceObject,
			String strRelationshipName,
			List<String> list_Relationships,
			List<String> list_PicklistValues,
			Boolean blnUpdateable,
			Boolean blnNillable
		) {
			this.strObjectName = strObjectName;
			this.strFieldLabel = strFieldLabel;
			this.strFieldAPIName = strFieldAPIName;
			this.strFieldType = strFieldType;
			this.strReferenceObject = strReferenceObject;
			this.strRelationshipName = strRelationshipName;
			this.list_Relationships = list_Relationships;
			this.list_PicklistValues = list_PicklistValues;
			this.blnUpdateable = blnUpdateable;
			this.blnNillable = blnNillable;
		}
	}

	/**
	 * @description It is invoked when user clicks "add base object" from user interface
	 * @param      String - strObjectName - object api name
	 * @param      String - strObjectLabel - object label
	 * @return     Wrapper of NBAUserInterfaceWrapper
	 **/
	@AuraEnabled
	public static NBAUserInterfaceWrapper handleAddBaseObject(String strObjectName, String strObjectLabel, Id strRuleSetId) {
		// map of reference fields to return
		Map<String, String> map_ReferenceFields = new Map<String, String>();
		Map<String, Schema.SObjectType> map_Schema = Schema.getGlobalDescribe();
		Map<String, FieldWrapper> map_AllFields = new Map<String, FieldWrapper>();

		try {
			// fetch all fields for the object
			Map<String, Schema.SObjectField> map_Fields = map_Schema.get(strObjectName).getDescribe().fields.getMap();

			// Fetch NBA Rule Set Id
			NBA_Rule_Set__c objRuleSet = [
				SELECT
					Id,
					Rule_Name__c,
					Hold_Out_Percentage__c,
					(SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c, Previous_Criteria__c, Performance__c FROM NBA_Rule_Criteria__r),
					Rule_Frequency_Minutes__c
				FROM NBA_Rule_Set__c
				WHERE Id = :strRuleSetId
			];

			// add object name and label to the map by default
			map_ReferenceFields.put('id', strObjectLabel);
			for (String strField : map_Fields.keySet()) {
				Schema.SObjectField objField = map_Fields.get(strField);

				// only return reference custom fields
				if (String.valueOf(objField.getDescribe().getType()) == 'REFERENCE') {
					// build a map of field api name and label
					map_ReferenceFields.put(objField.getDescribe().getName(), objField.getDescribe().getLabel());
				}

				List<String> list_PicklistValues = new List<String>();
				if (String.valueOf(objField.getDescribe().getType()) == 'PICKLIST' || String.valueOf(objField.getDescribe().getType()) == 'MULTIPICKLIST') {
					List<Schema.PicklistEntry> list_PicklistEntries = objField.getDescribe().getPicklistValues();

					for (Schema.PicklistEntry objEntry : list_PicklistEntries) {
						list_PicklistValues.add(objEntry.getLabel());
					}
				}

				// add all relationship objects to a list
				List<String> list_Relationships = new List<String>();
				if (objField.getDescribe().getReferenceTo().size() > 0) {
					for (Schema.SObjectType objType : objField.getDescribe().getReferenceTo()) {
						list_Relationships.add(objType.getDescribe().getName());
					}
				}
				String strReferenceObject = objField.getDescribe().getReferenceTo().size() > 0 ? String.valueOf(objField.getDescribe().getReferenceTo()[0]) : '';

				if (String.isNotBlank(strReferenceObject) && objField.getDescribe().getRelationshipName() == 'Owner') {
					strReferenceObject = 'User';
				}

				// create a field wrapper object and add it to the map
				map_AllFields.put(
					objField.getDescribe().getName().toLowerCase(),
					new FieldWrapper(
						strObjectName,
						objField.getDescribe().getLabel(),
						objField.getDescribe().getName().toLowerCase(),
						String.valueOf(objField.getDescribe().getType()),
						strReferenceObject,
						objField.getDescribe().getRelationshipName(),
						list_Relationships,
						list_PicklistValues,
						objField.getDescribe().isUpdateable(),
						objField.getDescribe().isNillable()
					)
				);
			}
			// return wrapper with success response
			NBAUserInterfaceWrapper objWrapper = new NBAUserInterfaceWrapper('Reference Fields Loaded', false, map_ReferenceFields, map_AllFields);
			objWrapper.objRuleSet = objRuleSet;
			objWrapper.map_Queues = getQueues(new Set<String>{ strObjectName });
			return objWrapper;
		} catch (Exception objEx) {
			return new NBAUserInterfaceWrapper(objEx.getMessage(), true, map_ReferenceFields, map_AllFields);
		}
	}

	/**
	 * @description Static method that runs when nba user interface is loaded.
	 * @param      String - NBA Rule Set Id
	 * @return     object of NBAUserInterfaceWrapper along with data needed for onload
	 **/
	@AuraEnabled
	public static NBAUserInterfaceWrapper loadUserInterface(String strRuleSetId) {
		Map<String, String> map_ObjecsToReturn = new Map<String, String>();
		try {
			// fetch all available objects from custom metadata
			Map<String, NBA_Available_Objects__mdt> map_AvailableObjects = NBA_Available_Objects__mdt.getAll();
			Map<String, Map<String, FieldWrapper>> map_ObjectFields = new Map<String, Map<String, FieldWrapper>>();
			// Build a map of object api name and label
			for (NBA_Available_Objects__mdt objAvailableObject : map_AvailableObjects.values()) {
				map_ObjecsToReturn.put(objAvailableObject.Object_API__c, objAvailableObject.Label);
			}
			// Fetch NBA Rule Set Id
			NBA_Rule_Set__c objRuleSet = [
				SELECT
					Id,
					Rule_Name__c,
					Hold_Out_Percentage__c,
					Is_Active__c,
					(SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c, Previous_Criteria__c, Performance__c FROM NBA_Rule_Criteria__r),
					Rule_Frequency_Minutes__c
				FROM NBA_Rule_Set__c
				WHERE Id = :strRuleSetId
			];
			List<String> list_Criteria = new List<String>{ 'Current_Criteria__c', 'Previous_Criteria__c' };

			// Return the wrapper with the rule set and available objects
			NBAUserInterfaceWrapper objWrapper = new NBAUserInterfaceWrapper('Rule Set Loaded', false, objRuleSet, map_ObjecsToReturn, RuleSetController.validateRuleSetEditPermission());
			// list of request objects with current criteria
			List<NBARequestWrapper> list_Requests = new List<NBARequestWrapper>();
			// list of request objects with previous criteria
			List<NBARequestWrapper> list_OldRequests = new List<NBARequestWrapper>();
			Set<String> set_ServingObjects = new Set<String>();
			// check if rule set has any criteria
			if (!objRuleSet.NBA_Rule_Criteria__r.isEmpty()) {
				for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
					for (String strCriteria : list_Criteria) {
						String strJson = (String) objCriteria.get(strCriteria);
						// get current and previous criteria and check if the json field is populated
						if (String.isNotBlank(strJson)) {
							NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(strJson, NBARequestWrapper.class);
							// Build a map of Serving object which points to a map of queue ID and queue name for the serving object
							set_ServingObjects.add(objRequest.servingObject);

							// add base object fields
							if (!map_ObjectFields.containsKey(objRequest.baseObject)) {
								NBAUserInterfaceWrapper objFieldsWrapper = getAllFields(objRequest.baseObject);
								map_ObjectFields.put(objRequest.baseObject, objFieldsWrapper.map_AllFields);
							}

							if (!map_ObjectFields.containsKey(objRequest.servingObject)) {
								NBAUserInterfaceWrapper objFieldsWrapper = getAllFields(objRequest.servingObject);
								map_ObjectFields.put(objRequest.servingObject, objFieldsWrapper.map_AllFields);
							}

							// iterate over criteria list and add fields if different objects are used in the criteria
							for (NBARequestWrapper.FilterFieldsList objFilter : objRequest.filterFieldsList) {
								for (NBARequestWrapper.InnerTables objInnerTable : objFilter.innerTables) {
									if (String.isNotBlank(objInnerTable.strReferenceObject) && !map_ObjectFields.containsKey(objInnerTable.strReferenceObject)) {
										NBAUserInterfaceWrapper objFieldsWrapper = getAllFields(objInnerTable.strReferenceObject);
										map_ObjectFields.put(objInnerTable.strReferenceObject, objFieldsWrapper.map_AllFields);
									}
								}
							}

							for (NBARequestWrapper.OrderByField objOrderByField : objRequest.list_OrderByFields) {
								for (NBARequestWrapper.InnerTables objInnerTable : objOrderByField.innerTables) {
									if (String.isNotBlank(objInnerTable.strReferenceObject) && !map_ObjectFields.containsKey(objInnerTable.strReferenceObject)) {
										NBAUserInterfaceWrapper objFieldsWrapper = getAllFields(objInnerTable.strReferenceObject);
										map_ObjectFields.put(objInnerTable.strReferenceObject, objFieldsWrapper.map_AllFields);
									}
								}
							}

							// if the field is current criteria then add it to the list of requests
							if (strCriteria == 'Current_Criteria__c') {
								list_Requests.add(objRequest);
							} else if (strCriteria == 'Previous_Criteria__c') {
								list_OldRequests.add(objRequest);
							}
						}
					}
				}
			}
			// add the list of requests (old and new) to the wrapper
			objWrapper.list_Requests = list_Requests;
			objWrapper.list_OldRequests = list_OldRequests;
			objWrapper.map_ObjectFields = map_ObjectFields;
			objWrapper.list_ActiveUsers = [SELECT Id, Name FROM User WHERE IsActive = TRUE ORDER BY NAME ASC];
			objWrapper.map_Queues = getQueues(new Set<String>(set_ServingObjects));
			return objWrapper;
		} catch (Exception objEx) {
			return new NBAUserInterfaceWrapper(objEx.getMessage(), true, null, null, false);
		}
	}

	/**
	 * @description Get all fields from an object
	 * @param      String - API name of the object
	 * @return     object of NBAUserInterfaceWrapper with field label and api name
	 **/
	@AuraEnabled
	public static NBAUserInterfaceWrapper getAllFields(String strObjectName) {
		Map<String, FieldWrapper> map_AllFields = new Map<String, FieldWrapper>();
		Map<String, Schema.SObjectType> map_Schema = Schema.getGlobalDescribe();
		// get all fields from the object
		Map<String, Schema.SObjectField> map_Fields = map_Schema.get(strObjectName).getDescribe().fields.getMap();
		DescribeSObjectResult objDescribe = map_Schema.get(strObjectName).getDescribe();

		// iterate over the fields and build a map of field api name and label along with other details (relationship name, reference object etc)
		for (String strField : map_Fields.keySet()) {
			Schema.SObjectField objField = map_Fields.get(strField);

			// add all relationship objects to a list
			List<String> list_Relationships = new List<String>();
			if (objField.getDescribe().getReferenceTo().size() > 0) {
				for (Schema.SObjectType objType : objField.getDescribe().getReferenceTo()) {
					list_Relationships.add(objType.getDescribe().getName());
				}
			}

			List<String> list_PicklistValues = new List<String>();
			if (String.valueOf(objField.getDescribe().getType()) == 'PICKLIST' || String.valueOf(objField.getDescribe().getType()) == 'MULTIPICKLIST') {
				List<Schema.PicklistEntry> list_PicklistEntries = objField.getDescribe().getPicklistValues();

				for (Schema.PicklistEntry objEntry : list_PicklistEntries) {
					list_PicklistValues.add(objEntry.getLabel());
				}
			}

			String strReferenceObject = objField.getDescribe().getReferenceTo().size() > 0 ? String.valueOf(objField.getDescribe().getReferenceTo()[0]) : '';

			if (String.isNotBlank(strReferenceObject) && objField.getDescribe().getRelationshipName() == 'Owner') {
				strReferenceObject = 'User';
			}

			// create a field wrapper object and add it to the map
			map_AllFields.put(
				objField.getDescribe().getName().toLowerCase(),
				new FieldWrapper(
					strObjectName,
					objField.getDescribe().getLabel(),
					objField.getDescribe().getName().toLowerCase(),
					String.valueOf(objField.getDescribe().getType()),
					strReferenceObject,
					objField.getDescribe().getRelationshipName(),
					list_Relationships,
					list_PicklistValues,
					objField.getDescribe().isUpdateable(),
					objField.getDescribe().isNillable()
				)
			);
		}

		NBAUserInterfaceWrapper objWrapper = new NBAUserInterfaceWrapper('All Fields Loaded', false, null, map_AllFields);
		objWrapper.strObjectLabel = objDescribe.getLabel();
		objWrapper.map_Queues = getQueues(new Set<String>{ strObjectName });
		return objWrapper;
	}

	/**
	 * @description Validating SOQL query
	 * @param      String - soql query to validate
	 * @return     object of NBAUserInterfaceWrapper with soql query validation result
	 **/
	@AuraEnabled
	public static NBAUserInterfaceWrapper validateSOQLQuery(String strQuery, String strBaseObject, Id idRuleSet) {
		try {
			Long dtmStartTime = System.currentTimeMillis();
			strQuery = NBAUtil.convertCustomFunctionsToSOQL(strQuery);

			List<Sobject> list_objects = Database.query(strQuery);
			Long dtmEndTime = System.currentTimeMillis();
			Double dblTimeTakenSeconds = (dtmEndTime - dtmStartTime) / 1000.0;
			NBAUserInterfaceWrapper objWrapper = new NBAUserInterfaceWrapper('Query Valid', false, null, null);
			objWrapper.dblTimeTakenSeconds = dblTimeTakenSeconds;
			// save performance on the nba rule criteria record
			if (idRuleSet != null && String.isNotBlank(strBaseObject) && strQuery.containsIgnoreCase('LIMIT 1')) {
				List<NBA_Rule_Criteria__c> list_Criteria = [SELECT Id FROM NBA_Rule_Criteria__c WHERE Base_Object__c = :strBaseObject AND NBA_Rule_Set__c = :idRuleSet LIMIT 1];
				if (list_Criteria.size() == 1) {
					NBA_Rule_Criteria__c objCriteriaToUpdate = list_Criteria.get(0);
					if (dblTimeTakenSeconds > 0) {
						if (dblTimeTakenSeconds < 1) {
							objCriteriaToUpdate.Performance__c = 'Excellent';
						} else if (dblTimeTakenSeconds < 4) {
							objCriteriaToUpdate.Performance__c = 'Good';
						} else {
							objCriteriaToUpdate.Performance__c = 'Poor';
						}
					}
					update objCriteriaToUpdate;
				}
			}

			// if no exception is thrown then return success message
			return objWrapper;
		} catch (Exception objEx) {
			// in case of exception, return the error message
			return new NBAUserInterfaceWrapper(objEx.getMessage(), true, null, null);
		}
	}

	/**
	 * @description Saving rule criteria changes
	 * @param      Id - Id of the rule set record
	 * @param      String - JSON string containing the rule criteria
	 * @return     object of NBAUserInterfaceWrapper with save result
	 **/
	@AuraEnabled
	public static NBAUserInterfaceWrapper handleSaveObjects(Id idRuleSet, String strJson, Boolean blnAutoSave, Integer intFrequency) {
		Map<String, NBA_Rule_Criteria__c> map_Criteria = new Map<String, NBA_Rule_Criteria__c>();
		List<NBA_Rule_Criteria__c> list_CriteriaToUpsert = new List<NBA_Rule_Criteria__c>();
		List<NBA_Rule_Criteria__c> list_CriteriaToDelete = new List<NBA_Rule_Criteria__c>();
		Set<String> set_BaseObjects = new Set<String>();

		try {
			// deserialize the json string to a list of request wrapper
			List<NBARequestWrapper> list_Requests = (List<NBARequestWrapper>) JSON.deserialize(strJson, List<NBARequestWrapper>.class);
			NBA_Rule_Set__c objRuleSet = [
				SELECT Id, (SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c, Previous_Criteria__c, Performance__c FROM NBA_Rule_Criteria__r), Is_Active__c
				FROM NBA_Rule_Set__c
				WHERE Id = :idRuleSet
				FOR UPDATE
			];
			// build a map of criteria to understand whether to upsert or delete
			for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
				map_Criteria.put(objCriteria.Base_Object__c, objCriteria);
			}
			// get the list of criteria to delete and upsert
			for (NBARequestWrapper objRequest : list_Requests) {
				// if base object does not already exist, then its an insert.
				NBA_Rule_Criteria__c objCriteria = map_Criteria.get(objRequest.baseObject);
				if (objCriteria == null) {
					objCriteria = new NBA_Rule_Criteria__c();
					objCriteria.Base_Object__c = objRequest.baseObject;
					objCriteria.NBA_Rule_Set__c = idRuleSet;
				}
				objCriteria.Talking_Points__c = objRequest.talkingPoints;
				objCriteria.Performance__c = objRequest.strPerformance;

				// set the talking points on the request object tp null to avoid taking up additional space
				// using separate field to store talking points
				NBARequestWrapper objOldRequest = null;
				if (objCriteria.Id != null && String.isNotBlank(objCriteria.Current_Criteria__c)) {
					objOldRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);
				}

				objRequest.talkingPoints = null;
				// serialize json object to string and store it in the criteria object
				objCriteria.Current_Criteria__c = JSON.serializePretty(objRequest);
				if (
					!blnAutoSave &&
					objOldRequest != null &&
					objRequest != null &&
					(objOldRequest.soqlQuery != objRequest.soqlQuery ||
					JSON.serialize(objOldRequest.userFieldsAssignment) != JSON.serialize(objRequest.userFieldsAssignment) ||
					JSON.serialize(objOldRequest.fieldMapping) != JSON.serialize(objRequest.fieldMapping) ||
					objOldRequest.assignRecordOwner != objRequest.assignRecordOwner)
				) {
					objCriteria.Previous_Criteria__c = JSON.serializePretty(objOldRequest);
				}
				list_CriteriaToUpsert.add(objCriteria);
				set_BaseObjects.add(objRequest.baseObject);
			}
			upsert list_CriteriaToUpsert;

			// update rule record
			objRuleSet.Rule_Last_Updated_By__c = UserInfo.getUserId();
			objRuleSet.Rule_Last_Updated_Time__c = Datetime.now();
			objRuleSet.Rule_Frequency_Minutes__c = intFrequency;
			update objRuleSet;

			// if base object is not in the list of objects to save, then delete it
			for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
				if (!set_BaseObjects.contains(objCriteria.Base_Object__c)) {
					list_CriteriaToDelete.add(objCriteria);
				}
			}

			if (!list_CriteriaToDelete.isEmpty()) {
				delete list_CriteriaToDelete;
			}
			return new NBAUserInterfaceWrapper('Objects Saved', false);
		} catch (Exception objEx) {
			// in case of exception, return the error message
			return new NBAUserInterfaceWrapper(objEx.getMessage(), true);
		}
	}

	@AuraEnabled
	public static List<NBARequestWrapper.DisplayFieldsList> getDisplayFieldsFromTemplate(String strTemplate) {
		List<NBARequestWrapper.DisplayFieldsList> list_DisplayFields = new List<NBARequestWrapper.DisplayFieldsList>();
		try {
			Map<String, Schema.SObjectType> map_Schema = Schema.getGlobalDescribe();
			NBA_View_Records_Template__mdt objTemplate;
			if (Test.isRunningTest()) {
				objTemplate = new NBA_View_Records_Template__mdt(Object_API__c = 'Opportunity_Related_Tracking__c', List_of_fields__c = 'Id\r\nOpportunity__r.Name');
			} else {
				objTemplate = [SELECT Id, Object_API__c, List_of_fields__c FROM NBA_View_Records_Template__mdt WHERE DeveloperName = :strTemplate];
			}

			List<String> list_Fields = objTemplate.List_of_fields__c.split('\r\n');
			Map<String, Schema.SObjectField> map_Fields = map_Schema.get(objTemplate.Object_API__c).getDescribe().fields.getMap();
			DescribeSObjectResult objDescribe = map_Schema.get(objTemplate.Object_API__c).getDescribe();

			for (String strField : list_Fields) {
				if (!strField.contains('.') && map_Fields.containsKey(strField)) {
					objDescribe = map_Schema.get(objTemplate.Object_API__c).getDescribe();
					map_Fields = map_Schema.get(objTemplate.Object_API__c).getDescribe().fields.getMap();

					Schema.SObjectField objField = map_Fields.get(strField);
					String strPath = objDescribe.getLabel() + ' > ' + objField.getDescribe().getLabel();
					list_DisplayFields.add(new NBARequestWrapper.DisplayFieldsList(strPath, strField.toLowerCase(), objField.getDescribe().getLabel()));
				} else {
					String[] list_FieldAPI = strField.split('\\.');
					String strFieldName = list_FieldAPI[list_FieldAPI.size() - 1];

					objDescribe = map_Schema.get(objTemplate.Object_API__c).getDescribe();
					map_Fields = map_Schema.get(objTemplate.Object_API__c).getDescribe().fields.getMap();

					String strPath = objDescribe.getLabel();
					String strFieldLabel = '';
					Integer counter = 0;
					for (String strFieldAPI : list_FieldAPI) {
						strFieldAPI = strFieldAPI.replaceAll('__r', '__c');
						Schema.SObjectField objField = map_Fields.get(strFieldAPI);
						if (counter != list_FieldAPI.size() - 1) {
							if (objField == null) {
								objField = map_Fields.get(strFieldAPI + 'Id');
							}

							strPath = strPath + +' > ' + objField.getDescribe().getLabel();
							String strReferenceObject = objField.getDescribe().getReferenceTo().size() > 0 ? String.valueOf(objField.getDescribe().getReferenceTo()[0]) : '';

							objDescribe = map_Schema.get(strReferenceObject).getDescribe();
							map_Fields = map_Schema.get(strReferenceObject).getDescribe().fields.getMap();
							counter = counter + 1;
						} else {
							strPath = strPath + +' > ' + objField.getDescribe().getLabel();
							strFieldLabel = objField.getDescribe().getLabel();
						}
					}

					list_DisplayFields.add(new NBARequestWrapper.DisplayFieldsList(strPath, strField.toLowerCase(), strFieldLabel));
				}
			}
			return list_DisplayFields;
		} catch (Exception ex) {
			return list_DisplayFields;
		}
	}

	/**
	 * @description Returns current data from NBA Rule Set record
	 * @param      Id of the NBA Rule Set record
	 * @return     Returns the object that has the Rule Set data
	 **/
	@AuraEnabled
	public static NBA_Rule_Set__c getRuleData(Id idRuleSet) {
		return [SELECT Id, Is_Active__c FROM NBA_Rule_Set__c WHERE Id = :idRuleSet];
	}

	/**
	 * @description Method to return all queue names and Ids for a given object or set objects
	 * @param     Set of object API names
	 * @return     Returns a map of object name pointing to a map of queue Id and queue name
	 **/
	public static Map<String, Map<Id, String>> getQueues(Set<String> set_ServingObjects) {
		Map<String, Map<Id, String>> map_Queues = new Map<String, Map<Id, String>>();

		for (String strObjectName : set_ServingObjects) {
			Map<Id, String> map_QueuesDB = new Map<Id, String>();
			for (QueueSobject objQueueObject : [SELECT Id, SobjectType, QueueId, Queue.Name FROM QueueSobject WHERE SobjectType = :strObjectName ORDER BY Queue.Name ASC]) {
				map_QueuesDB.put(objQueueObject.QueueId, objQueueObject.Queue.Name);
			}
			map_Queues.put(strObjectName, map_QueuesDB);
		}
		return map_Queues;
	}
}