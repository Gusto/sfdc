/**
 * @description  Apex class that business logic related to serving up leads or opportunities to Small Biz reps
 * @author       Praveen Sethu
 * @date         07-19-2023
 * @see          NBAServeRecordTest
 **/
public without sharing class NBAServeRecord {
	public static final String SOBJECT_TYPE_LEAD = 'Lead';
	public static final String SOBJECT_TYPE_OPPORTUNITY = 'Opportunity';
	public static String strServingRecordName = '';
	public static String NAME_FIELD = 'Name';
	public static String TASK_OBJ = 'Task';
	public static String EVENT_OBJ = 'Event';
	public static String SUBJECT_FIELD = 'Subject';
	public static String HOLD_OUT_FIELD = 'Hold_Out_Record__c';
	public static final String LOGIC_AND = 'AND';
	public static final String LOGIC_OR = 'OR';
	public static final String LOGIC = 'logic';
	public static final String EMPTY_VALUE = 'Empty Value';
	public static final String ANY_VALUE = 'Any Value';

	public class MyException extends Exception {
	}

	public class UserZeroRecordsWrapper {
		public String strUserId;
		public String strName;
		public DateTime dtmLastRanWithZeroRecords;

		public UserZeroRecordsWrapper(String strUserId, String strName, DateTime dtmLastRanWithZeroRecords) {
			this.strUserId = strUserId;
			this.strName = strName;
			this.dtmLastRanWithZeroRecords = dtmLastRanWithZeroRecords;
		}
	}

	/**
	 * @description  Wrapper class to return the results of the serve up operation back to Aura/LWC component
	 * @author       Praveen Sethu
	 * @date         07-19-2023
	 **/
	public class NBAServeRecordWrapper {
		// Success flag used for showing error or success message in the front-end
		@AuraEnabled
		public Boolean blnSuccess;

		// Success or error (exception) message
		@AuraEnabled
		public String strMessage;

		// Generic object that can be either Lead or Opportunity
		@AuraEnabled
		public SObject objRecord;

		// Flag to indicate if there was an exception
		@AuraEnabled
		public Boolean blnException;

		// Base URL for the org
		@AuraEnabled
		public String strBaseURL = URL.getSalesforceBaseUrl().toExternalForm();

		// Type of exception
		@AuraEnabled
		public String strExceptionType;

		@AuraEnabled
		public String strRecordName;

		@AuraEnabled
		public String strRecordId;

		@AuraEnabled
		public String strRecordType;

		@AuraEnabled
		public Integer intExecutionNumber;

		@AuraEnabled
		public NBA_Rule_Set_Configuration__c objRuleConfig;

		@AuraEnabled
		public List<NBA_Rule_Set__c> list_RuleSets;

		@AuraEnabled
		public List<ServiceResourceSkill> list_ServiceResourceSkills;

		public void setResponse(Boolean blnSuccess, String strMessage, SObject objRecord, Boolean blnException, String strExceptionType, String strRecordName) {
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
			this.objRecord = objRecord;
			this.blnException = blnException;
			this.strExceptionType = strExceptionType;
			this.strRecordName = strRecordName;
		}
	}

	public static List<NBA_Rule_Set__c> getRecordsByChunk(List<NBA_Rule_Set__c> list_records, Integer intRecordsPerChunk, Integer intChunkNumber) {
		List<NBA_Rule_Set__c> list_result = new List<NBA_Rule_Set__c>();

		Integer intStartIndex = (intChunkNumber - 1) * intRecordsPerChunk;
		Integer intEndIndex = intStartIndex + intRecordsPerChunk;

		for (Integer i = intStartIndex; i < intEndIndex && i < list_records.size(); i++) {
			list_result.add(list_records[i]);
		}

		return list_result;
	}

	@AuraEnabled
	public static String serveNextRecord(String strWrapper) {
		// Initialize variables
		String strLeadQuery;
		String strOpportunityQuery;
		String strRecordName;
		// lead and opp record to return
		Lead objLead = null;
		Opportunity objOpportunity = null;
		SObject objRecordToReturn = null;
		// Bypass lead and opportunity triggers
		TriggerHandler.bypass('LeadTriggerHandler');
		TriggerHandler.bypass('OpportunityTriggerHandler');
		TriggerHandler.bypass('AccountTriggerHandler');
		Boolean blnHoldOut = false;
		Boolean blnIsBatch = false;
		String strPrimaryServingField = '';
		List<String> list_userLookupFields = new List<String>();
		Object objMaxValue = null;
		String strTypeOfServingRecord = '';
		NBARequestWrapper objPrimaryWrapper = null;
		List<String> list_RulesToSkip = new List<String>();
		Map<Id, NBA_Rule_Set__c> map_RuleSetsToUpdate = new Map<Id, NBA_Rule_Set__c>();
		List<SObject> list_HoldOutRecordsToUpdate = new List<SObject>();
		Boolean blnExcludeServedOtherRules = false;
		NBAServeRecordWrapper objWrapper = (strWrapper != null) ? (NBAServeRecordWrapper) JSON.deserialize(strWrapper, NBAServeRecordWrapper.class) : new NBAServeRecordWrapper();
		String strServedRuleSet = '';
		try {
			List<NBA_Rule_Set__c> list_RuleSets = null;
			// validating if it is the first execution
			if (objWrapper.intExecutionNumber == null) {
				// Fetch the rule set of the logged in user
				objWrapper.objRuleConfig = returnUserRuleSet();

				if (objWrapper.objRuleConfig == null) {
					objWrapper.setResponse(false, 'No rule set found for the logged in user. Please contact admin', null, false, null, null);
					return JSON.serialize(objWrapper);
				}
				// fetch all service resource skill records for the logged in user
				objWrapper.list_ServiceResourceSkills = [
					SELECT Id, SkillNumber, ServiceResourceId, SkillId, SkillLevel, EffectiveStartDate, EffectiveEndDate, Skill.DeveloperName, Skill.MasterLabel
					FROM ServiceResourceSkill
					WHERE ServiceResource.RelatedRecordId = :UserInfo.getUserId()
				];
				objWrapper.list_RuleSets = [
					SELECT
						Id,
						Rule_Name__c,
						NBA_Rule_Set_Configuration__r.Abbreviation__c,
						NBA_Rule_Set_Configuration__r.Exclude_Served_Other_Rules__c,
						Last_Ran_With_Zero_Records__c,
						Rule_Frequency_Minutes__c,
						(SELECT Id, Skill_Level__c, Skill_Id__c, Name, Operator__c FROM NBA_Rule_Set_Skills__r),
						(SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c FROM NBA_Rule_Criteria__r),
						Hold_Out_Percentage__c,
						Rule_Skills_Criteria_Logic__c,
						User_Last_Ran_With_Zero_Records__c
					FROM NBA_Rule_Set__c
					WHERE Is_Active__c = TRUE AND NBA_Rule_Set_Configuration__r.Name = :objWrapper.objRuleConfig.Name
					ORDER BY Priority__c ASC
				];
				// validating if it needs to be batching
				if (objWrapper?.objRuleConfig?.Rules_per_Execution__c != null) {
					//getting the list for the first chunk
					objWrapper.intExecutionNumber = 1;
					list_RuleSets = getRecordsByChunk(objWrapper.list_RuleSets, Integer.ValueOf(objWrapper.objRuleConfig.Rules_per_Execution__c), objWrapper.intExecutionNumber);
					blnIsBatch = true;
				} else {
					list_RuleSets = objWrapper.list_RuleSets;
				}
			} else {
				blnIsBatch = true;
				//getting the list for the next chunk
				list_RuleSets = getRecordsByChunk(objWrapper.list_RuleSets, Integer.ValueOf(objWrapper.objRuleConfig.Rules_per_Execution__c), objWrapper.intExecutionNumber);
			}

			// Iterate over all active rules and filter by team name - also fetch skills
			for (NBA_Rule_Set__c objRuleSet : list_RuleSets) {
				list_userLookupFields = new List<String>();
				if (objRuleSet.NBA_Rule_Criteria__r.isEmpty()) {
					// if no criteria, move to the next rule
					continue;
				} else {
					// check if rule set needs skills
					if (!objRuleSet.NBA_Rule_Set_Skills__r.isEmpty()) {
						// if skills are needed, check if the logged in user has the skills
						// assume that user doesn't have skills
						Boolean blnHasSkills = checkSkills(objWrapper.list_ServiceResourceSkills, objRuleSet.NBA_Rule_Set_Skills__r, objRuleSet.Rule_Skills_Criteria_Logic__c);
						// if user does not have the skills, move to the next rule
						if (!blnHasSkills) {
							list_RulesToSkip.add(objRuleSet.Rule_Name__c);
							continue;
						}
					}

					// check based on rule frequency
					DateTime dtmLastRandWithZeroRecords = returnLastZeroRecords(objRuleSet);
					if (objRuleSet.Rule_Frequency_Minutes__c != null && objRuleSet.Rule_Frequency_Minutes__c > 0 && dtmLastRandWithZeroRecords != null) {
						if (dtmLastRandWithZeroRecords > DateTime.now().addMinutes(-Integer.valueOf(objRuleSet.Rule_Frequency_Minutes__c))) {
							list_RulesToSkip.add(objRuleSet.Rule_Name__c);
							continue;
						}
					}

					Map<String, SObject> map_ServingObjects = new Map<String, SObject>();
					Map<String, NBARequestWrapper> map_Requests = new Map<String, NBARequestWrapper>();
					for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
						if (String.isNotBlank(objCriteria.Current_Criteria__c)) {
							NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);
							String strServingField = objRequest.servingField;
							List<String> list_Fields = new List<String>();

							// add the serving fields
							list_Fields.add(objRequest.servingField);

							// get order by field (either directly from the base object or from the inner tables if present)

							if (objRequest.list_OrderByFields.size() == 1) {
								String strOrderByField = NBAServeRecord.getOrderByField(objRequest.list_OrderByFields.get(0));
								if (!list_Fields.contains(strOrderByField)) {
									list_Fields.add(strOrderByField);
								}
							}

							// add id fields if not present
							if (!list_Fields.contains('Id') && !list_Fields.contains('id')) {
								list_Fields.add('Id');
							}

							String strQuery = 'SELECT ' + String.join(list_Fields, ',') + ' FROM ' + objCriteria.Base_Object__c + ' WHERE ' + objRequest.soqlQuery + ' LIMIT 1';
							Sobject objServingObject = null;

							strQuery = NBAUtil.convertCustomFunctionsToSOQL(strQuery);

							List<SObject> list_ServingObjects = Database.query(strQuery);
							if (!list_ServingObjects.isEmpty()) {
								objServingObject = list_ServingObjects.get(0);
							}

							map_Requests.put(objCriteria.Base_Object__c, objRequest);
							if (objServingObject != null) {
								map_ServingObjects.put(objCriteria.Base_Object__c, objServingObject);
							}
						}
					}

					if (map_ServingObjects.isEmpty()) {
						// if no records are available, move to the next rule
						// Indicate the time when the rule returned zero records
						objRuleSet = setLastRanWithZeroRecords(objRuleSet);
						list_RulesToSkip.add(objRuleSet.Rule_Name__c);
						map_RuleSetsToUpdate.put(objRuleSet.Id, objRuleSet);
						continue;
					} else {
						// find the serving object with the most recent created date
						if (map_ServingObjects.size() == 1) {
							// if there is only one record, return it
							for (String strKey : map_ServingObjects.keySet()) {
								objRecordToReturn = map_ServingObjects.get(strKey);
								NBARequestWrapper objRequest = map_Requests.get(strKey);
								strPrimaryServingField = objRequest.servingField;
								objPrimaryWrapper = objRequest;
							}
						} else {
							// if there are multiple object - get all records and their order by field and get the most recent record
							for (String strKey : map_ServingObjects.keySet()) {
								Sobject objServingObject = map_ServingObjects.get(strKey);
								Sobject objServingObjectToUse = objServingObject;

								NBARequestWrapper objRequest = map_Requests.get(strKey);
								String strOrderByField = NBAServeRecord.getOrderByField(objRequest.list_OrderByFields.get(0));
								String strFieldName = '';

								// if order by field contains a . then it is a relationship field - split the field based on . to get to the actual field name
								// last value of the array will be name of the field - all of the other values will be lookup or master detail relationship names
								if (strOrderByField.contains('.')) {
									String[] list_FieldAPI = strOrderByField.split('\\.');
									strFieldName = list_FieldAPI[list_FieldAPI.size() - 1];

									Integer counter = 0;
									for (String strFieldAPI : list_FieldAPI) {
										if (counter != list_FieldAPI.size() - 1) {
											objServingObjectToUse = (Sobject) objServingObjectToUse.getSObject(strFieldAPI);

											// if the relationship field is null, break out of the loop
											counter = counter + 1;
											if (objServingObjectToUse == null) {
												break;
											}
										}
									}
								} else {
									objServingObjectToUse = objServingObject;
									strFieldName = strOrderByField;
								}
								// serving object to use is only need in case the order by field has a relationship field
								if (objServingObjectToUse != null && objServingObjectToUse.get(strFieldName) != null) {
									// get the maximum value of the order by field and return the record
									if (objRecordToReturn == null) {
										objRecordToReturn = objServingObject;
										objMaxValue = objServingObjectToUse.get(strFieldName);
										strPrimaryServingField = objRequest.servingField;
										objPrimaryWrapper = objRequest;
									} else {
										Boolean blnGreater = NBAServeRecord.compareValues(objServingObjectToUse.get(strFieldName), objMaxValue);
										if (blnGreater) {
											objRecordToReturn = objServingObject;
											objMaxValue = objServingObjectToUse.get(strFieldName);
											strPrimaryServingField = objRequest.servingField;
											objPrimaryWrapper = objRequest;
										}
									}
								}
							}

							// if the record is still null, it could possibly mean the order by field is null.
							if (objRecordToReturn == null) {
								for (String strKey : map_ServingObjects.keySet()) {
									Sobject objServingObject = map_ServingObjects.get(strKey);

									objRecordToReturn = map_ServingObjects.get(strKey);
									NBARequestWrapper objRequest = map_Requests.get(strKey);
									strPrimaryServingField = objRequest.servingField;
									objPrimaryWrapper = objRequest;
									break;
								}
							}
						}
					}
				}

				if (objRecordToReturn == null) {
					// if no records are available, move to the next rule
					// Indicate the time when the rule returned zero records
					objRuleSet = setLastRanWithZeroRecords(objRuleSet);
					list_RulesToSkip.add(objRuleSet.Rule_Name__c);
					map_RuleSetsToUpdate.put(objRuleSet.Id, objRuleSet);
					continue;
				}

				// at this point we have a record to serve
				String strRecordId = (String) objRecordToReturn.get(strPrimaryServingField);
				strTypeOfServingRecord = Id.valueOf(strRecordId).getSObjectType().getDescribe().getName();
				objRecordToReturn = ((SObject) Type.forName(strTypeOfServingRecord).newInstance()).getSObjectType().newSObject();
				objRecordToReturn.put('Id', strRecordId);
				String strObject = Id.valueOf(strRecordId).getSObjectType().getDescribe().getName();
				//adding fields for mapping
				List<String> list_SelectedFieldMapping = new List<String>();
				String strFieldsForMapping = '';
				if (objPrimaryWrapper.fieldMapping != null && objPrimaryWrapper.fieldMapping.size() > 0) {
					for (NBARequestWrapper.FieldMapping field : objPrimaryWrapper.fieldMapping) {
						list_SelectedFieldMapping.add(field.selectedField);
					}
					strFieldsForMapping = ', ' + String.join(list_SelectedFieldMapping, ',');
				}
				objRecordToReturn = Database.query('SELECT Id' + strFieldsForMapping + ' FROM ' + strObject + ' WHERE Id = :strRecordId FOR UPDATE');

				// set served up time and served up rule and break out of the loop
				if (objRecordToReturn != null) {
					String strRuleName = objRuleSet.Rule_Name__c + ' - ' + objRuleSet.NBA_Rule_Set_Configuration__r?.Abbreviation__c;
					// Set abbreviation of the served rule set
					strServedRuleSet = objRuleSet.NBA_Rule_Set_Configuration__r?.Abbreviation__c;
					blnExcludeServedOtherRules = objRuleSet.NBA_Rule_Set_Configuration__r?.Exclude_Served_Other_Rules__c;
					objRecordToReturn.put('Served_Up_Time__c', DateTime.now());
					objRecordToReturn.put('Served_Up_Rule__c', strRuleName);
					objRecordToReturn.put('Served_User__c', UserInfo.getUserId());

					// check if the rule set requires certain records to be hold out
					if (objRuleSet.Hold_Out_Percentage__c != null) {
						// get hold out percentage
						Integer intHoldOutPercentage = Integer.valueOf(objRuleSet.Hold_Out_Percentage__c);
						// get name of the object from the record Id
						Id idRecord = (Id) objRecordToReturn.get('Id');
						String strObjectType = idRecord.getSObjectType().getDescribe().getName();

						// find out how many records have been served today
						Integer intRecordsServedToday = Database.countQuery('SELECT COUNT() FROM ' + strObjectType + ' WHERE Served_Up_Time__c = TODAY AND Served_Up_Rule__c = :strRuleName');
						// find out how many records have been served today that are hold out
						String strHoldOutNewValue = 'Hold Out - ' + objRuleSet.Rule_Name__c + ' - ' + objRuleSet.NBA_Rule_Set_Configuration__r?.Abbreviation__c;
						List<String> list_RuleName = new List<String>{ strHoldOutNewValue };
						String strRuleList = '(\'' + String.join(list_RuleName, '\', \'') + '\')';

						Integer intRecordsHoldOutToday = Database.countQuery(
							'SELECT COUNT() FROM ' +
							strObjectType +
							' WHERE Served_Up_Time__c = TODAY AND Served_Up_Rule__c = :strRuleName AND Hold_Out_Record__c INCLUDES ' +
							strRuleList
						);

						Decimal intHoldOutPercentageToday = (Decimal.valueOf((intRecordsHoldOutToday + 1)) / Decimal.valueOf((intRecordsServedToday + 1))) * 100.0;
						if (intHoldOutPercentageToday <= objRuleSet.Hold_Out_Percentage__c) {
							Sobject objQuery = Database.query('SELECT Id, Hold_Out_Record__c FROM ' + strObjectType + ' WHERE Id = :idRecord FOR UPDATE');

							// if hold out record is empty, add the rule set name to it
							// if hold out record is already present, append the rule set name to it
							String strExistingValue = (String) objQuery.get(HOLD_OUT_FIELD);
							if (String.isBlank(strExistingValue)) {
								strHoldOutNewValue = 'Hold Out - ' + objRuleSet.Rule_Name__c + ' - ' + objRuleSet.NBA_Rule_Set_Configuration__r?.Abbreviation__c;
								objRecordToReturn.put(HOLD_OUT_FIELD, strHoldOutNewValue);
							} else if (!strExistingValue.contains(strHoldOutNewValue)) {
								strHoldOutNewValue = strExistingValue + ';' + strHoldOutNewValue;
								objRecordToReturn.put(HOLD_OUT_FIELD, strHoldOutNewValue);
							}

							// if record is unavailable, send an error message
							if (!checkRecordAccess(objRecordToReturn)) {
								throw new MyException('unable to obtain exclusive access');
							}
							list_HoldOutRecordsToUpdate.add(objRecordToReturn);
							blnHoldOut = true;
						}
					}
					break;
				}
			}

			// update hold out records - Removing DML outside of for loop
			if (!list_HoldOutRecordsToUpdate.isEmpty()) {
				update list_HoldOutRecordsToUpdate;
			}

			// do not update served other rules if record is hold out
			if (!blnHoldOut) {
				// if record is available, figure out other rules that the record satisfies and update the record
				if (objRecordToReturn != null) {
					//If blnExcludeServedOtherRules is true, it will only set the first rule in the field
					List<String> list_OtherCategories = (blnExcludeServedOtherRules)
						? new List<String>{ (String) objRecordToReturn.get('Served_Up_Rule__c') }
						: getCategoryAlignment(objRecordToReturn, list_RulesToSkip, objWrapper.objRuleConfig.name);
					objRecordToReturn.put('Served_Other_Rules__c', String.join(list_OtherCategories, ';'));

					//Adding user lookup fields for serving record
					if (objPrimaryWrapper.userFieldsAssignment != null) {
						for (String strField : objPrimaryWrapper.userFieldsAssignment) {
							objRecordToReturn.put(strField, UserInfo.getUserId());
						}
					}

					//Validate and update Field Mappings
					if (objPrimaryWrapper.fieldMapping != null) {
						for (NBARequestWrapper.FieldMapping field : objPrimaryWrapper.fieldMapping) {
							Boolean blnHasAnyValueMapping = false;
							String strAnyValueTo = '';
							Boolean blnHasChanged = false;
							for (NBARequestWrapper.Mapping mapping : field.mapping) {
								String strToValue = (mapping.toValue == EMPTY_VALUE) ? null : mapping.toValue;
								String strFromValue = (mapping.fromValue == EMPTY_VALUE) ? null : mapping.fromValue;
								if (mapping.fromValue == ANY_VALUE) {
									blnHasAnyValueMapping = true;
									strAnyValueTo = strToValue;
									continue;
								}
								if (objRecordToReturn.get(field.selectedField) == strFromValue) {
									objRecordToReturn.put(field.selectedField, strToValue);
									blnHasChanged = true;
									break;
								}
							}
							if (blnHasAnyValueMapping && !blnHasChanged) {
								objRecordToReturn.put(field.selectedField, strAnyValueTo);
							}
						}
					}

					// Set record owner if the rule has assign record owner set to true
					if (objPrimaryWrapper != null && objPrimaryWrapper.assignRecordOwner != null && objPrimaryWrapper.assignRecordOwner) {
						objRecordToReturn.put('OwnerId', UserInfo.getUserId());
					}
					// if record is unavailable, send an error message
					if (!checkRecordAccess(objRecordToReturn)) {
						throw new MyException('unable to obtain exclusive access');
					}
					// If record is not served before, update the record and return back to the user
					List<SObject> list_RecordsToUpdate = new List<SObject>{ objRecordToReturn };

					// If served rule set is GPROC, check sold by and update served up time on sold by record
					if (String.isNotBlank(strServedRuleSet) && strServedRuleSet == 'GPROC') {
						Id idRecord = (Id) objRecordToReturn.get('Id');
						String strObjectType = idRecord.getSObjectType().getDescribe().getName();

						if (strObjectType == 'Opportunity') {
							Opportunity objOppty = [SELECT Id, Sold_By__c, Sold_By__r.Id FROM Opportunity WHERE Id = :idRecord];
							// Update the reseller Sold by account if one of their clients is served on the same day
							if (objOppty != null && objOppty.Sold_By__c != null) {
								Sobject objSoldBy = new Account();
								objSoldBy.put('Id', objOppty.Sold_By__r.Id);
								objSoldBy.put('Served_Up_Time__c', DateTime.now());
								objSoldBy.put('Served_Up_Rule__c', objRecordToReturn.get('Served_Up_Rule__c'));
								objSoldBy.put('Served_User__c', UserInfo.getUserId());
								list_RecordsToUpdate.add(objSoldBy);
							}
						}
					}

					update list_RecordsToUpdate;
					objWrapper.setResponse(true, null, objRecordToReturn, false, null, strServingRecordName);
					objWrapper.strRecordType = strTypeOfServingRecord;

					// update rule sets with last ran with zero records
					updateRuleSets(map_RuleSetsToUpdate);

					// update is successful, return the record with success flag and message
					return JSON.serialize(objWrapper);
				} else {
					// if no records are available, return the wrapper with error message
					// update rule sets with last ran with zero records
					updateRuleSets(map_RuleSetsToUpdate);
					List<NBA_Rule_Set__c> list_nextRules = blnIsBatch
						? getRecordsByChunk(objWrapper.list_RuleSets, Integer.ValueOf(objWrapper.objRuleConfig.Rules_per_Execution__c), (objWrapper.intExecutionNumber + 1))
						: new List<NBA_Rule_Set__c>();
					Boolean isSuccessful = (blnIsBatch && !list_nextRules.isEmpty()) ? true : false;
					objWrapper.setResponse(isSuccessful, 'No records to play. Please try again later.', null, false, null, null);

					return JSON.serialize(objWrapper);
				}
			} else {
				return serveNextRecord(JSON.serialize(objWrapper));
			}
		} catch (Exception ex) {
			// in case of exception, retrun the wrapper with exception flag and message
			objWrapper.setResponse(false, ex.getMessage(), null, true, ex.getTypeName(), null);
			return JSON.serialize(objWrapper);
		}
	}

	/**
	 * @description Runs all active rules for a rule set and returns the categories that the record satisfies
	 * @param	   recordId - Id of the record to serve
	 * @return      Wrapper containing the record to serve along with success or error message and flags
	 **/
	@AuraEnabled
	public static List<String> getCategoryAlignment(SObject objRecord, List<String> list_RulesToSkip, String strRuleSetName) {
		List<Lead_Related_Tracking__c> list_LeadRelatedTrackings = new List<Lead_Related_Tracking__c>();
		List<Opportunity_Related_Tracking__c> list_OpptyRelatedTrackings = new List<Opportunity_Related_Tracking__c>();
		// Decide type based on object prefix
		Id recordId = (Id) objRecord.get('Id');
		String strObjectType = recordId.getSObjectType().getDescribe().getName();
		String strQuery = '';
		List<String> list_Categories = String.valueOf(objRecord.get('Served_Up_Rule__c'))?.split(';');

		try {
			if (String.isBlank(strRuleSetName)) {
				return new List<String>();
			}

			// Iterate over all active rules and filter by team name
			for (NBA_Rule_Set__c objRuleSet : [
				SELECT Id, Name, Rule_Name__c, NBA_Rule_Set_Configuration__r.Abbreviation__c, (SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c FROM NBA_Rule_Criteria__r)
				FROM NBA_Rule_Set__c
				WHERE Is_Active__c = TRUE AND NBA_Rule_Set_Configuration__r.Name = :strRuleSetName AND Rule_Name__c NOT IN :list_RulesToSkip
			]) {
				// iterate over all criteria and check if the record satisfies the criteria
				for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
					if (String.isNotBlank(objCriteria.Current_Criteria__c)) {
						NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);

						if (objRequest.servingObject == strObjectType) {
							// the only difference in building the query is that we need to add the record Id to the query
							strQuery = 'SELECT Id FROM ' + objCriteria.Base_Object__c + ' WHERE ' + objRequest.servingField + ' = :recordId AND ' + objRequest.soqlQuery;
							strQuery = NBAUtil.convertCustomFunctionsToSOQL(strQuery);

							// query the record
							List<SObject> list_ServingObjects = Database.query(strQuery);
							// if record is available, add the rule set name to the list of categories
							if (!list_ServingObjects.isEmpty()) {
								String strRuleToAdd = objRuleSet.Rule_Name__c + ' - ' + objRuleSet.NBA_Rule_Set_Configuration__r?.Abbreviation__c;
								if (!list_Categories.contains(strRuleToAdd)) {
									list_Categories.add(strRuleToAdd);
								}
							}
						}
					}
				}
			}

			return list_Categories;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('NBAServeRecord', 'getCategoryAlignment', null, objException);
			return new List<String>();
		}
	}

	/**
	 * @description Returns rule set of the logged in user based on user role
	 * @return      String - Rule set name
	 **/
	public static NBA_Rule_Set_Configuration__c returnUserRuleSet() {
		// Get logged in user role Id
		Id idLoggedInUserRoleId = UserInfo.getUserRoleId();
		NBA_Rule_Set_Configuration__c objRuleSet = null;
		// Check if logged in user has a role
		if (idLoggedInUserRoleId != null) {
			// Query from user role object
			UserRole objUserRole = [SELECT Id, Name FROM UserRole WHERE Id = :idLoggedInUserRoleId];
			if (objUserRole != null && String.isNotBlank(objUserRole.Name)) {
				// Query from NBA Rule Set Configuration that is linked to the logged in user's role
				for (NBA_Rule_Set_Configuration__c objConfig : [SELECT Id, Name, User_Roles__c, Rules_per_Execution__c FROM NBA_Rule_Set_Configuration__c]) {
					if (String.isNotBlank(objConfig.User_Roles__c) && objConfig.User_Roles__c.contains(objUserRole.Name)) {
						objRuleSet = objConfig;
						break;
					}
				}
			}
		}
		return objRuleSet;
	}

	/**
	 * @description Uses the operator from nba rule set skill and compares it with the skill level of the service resource skill
	 * @param      ServiceResourceSkill - service resource skill of the logged in user
	 * @param      NBA_Rule_Set_Skill__c - rule set skill record
	 * @return     Boolean - true if the skill level is eligible, false otherwise
	 **/
	public static Boolean skillLevelEligibility(ServiceResourceSkill objServiceResourceSkill, NBA_Rule_Set_Skill__c objSkill) {
		try {
			// if skill level or operator level is blank, return true
			if (String.isBlank(objSkill.Operator__c) || objSkill.Operator__c == '--None--' || String.isBlank(objSkill.Skill_Level__c)) {
				return true;
			}
			if (objSkill.Operator__c == '>=') {
				return objServiceResourceSkill.SkillLevel >= Decimal.valueOf(objSkill.Skill_Level__c);
			} else if (objSkill.Operator__c == '<=') {
				return objServiceResourceSkill.SkillLevel <= Decimal.valueOf(objSkill.Skill_Level__c);
			} else if (objSkill.Operator__c == '>') {
				return objServiceResourceSkill.SkillLevel > Decimal.valueOf(objSkill.Skill_Level__c);
			} else if (objSkill.Operator__c == '<') {
				return objServiceResourceSkill.SkillLevel < Decimal.valueOf(objSkill.Skill_Level__c);
			} else if (objSkill.Operator__c == '=') {
				return objSkill.Skill_Level__c.contains(String.valueOf(Integer.valueOf(objServiceResourceSkill.SkillLevel)));
			} else if (objSkill.Operator__c == '!=') {
				return !objSkill.Skill_Level__c.contains(String.valueOf(Integer.valueOf(objServiceResourceSkill.SkillLevel)));
			}
		} catch (Exception objEx) {
			return false;
		}
		return false;
	}

	/**
	 * @description Uses the operator from nba rule set skill and compares it with the skill level of the service resource skill
	 * @param      ServiceResourceSkill - service resource skill of the logged in user
	 * @param      NBA_Rule_Set_Skill__c - rule set skill record
	 * @return     Boolean - true if the skill level is eligible, false otherwise
	 **/
	public static Boolean skillDateEligibility(ServiceResourceSkill objServiceResourceSkill) {
		try {
			// If the user has the matching skill but the start date is in the future, the work item should NOT be served
			if (objServiceResourceSkill.EffectiveStartDate > Datetime.now()) {
				return false;
			}
			// If the user has the matching skill but the end date is in the past, the work item should NOT be served
			if (objServiceResourceSkill.EffectiveEndDate != null && objServiceResourceSkill.EffectiveEndDate < Datetime.now()) {
				return false;
			}
			// If the user has the matching skill, the start date is in the past, and the end date is blank, the work item may be served
			if (objServiceResourceSkill.EffectiveStartDate < Datetime.now() && objServiceResourceSkill.EffectiveEndDate == null) {
				return true;
			}
			// If the user has the matching skill, and the current date/time is between the start and end date, the work item may be served
			if (objServiceResourceSkill.EffectiveStartDate < Datetime.now() && objServiceResourceSkill.EffectiveEndDate > Datetime.now()) {
				return true;
			}
		} catch (Exception objEx) {
			return false;
		}
		return false;
	}

	/**
	 * @description Checks if the logged in user has the skills required by the rule set
	 * @param      list_ServiceResourceSkills - list of service resource skills of the logged in user
	 * @param      list_ruleSetSkills - list of rule set skills
	 * @param      strRuleSkillsCriteriaLogic - logic to use for checking the skills
	 * @return     Boolean - true if the user has the skills, false otherwise
	 **/
	public static Boolean checkSkills(List<ServiceResourceSkill> list_ServiceResourceSkills, List<NBA_Rule_Set_Skill__c> list_ruleSetSkills, String strRuleSkillsCriteriaLogic) {
		Map<String, Object> objJson = (Map<String, Object>) JSON.deserializeUntyped(strRuleSkillsCriteriaLogic);
		String strLogic = (String) objJson.get(LOGIC);
		Boolean blnHasSkills = false;
		if (strLogic == LOGIC_OR) {
			for (NBA_Rule_Set_Skill__c objruleSetSkill : list_ruleSetSkills) {
				if (blnHasSkills) {
					break;
				}
				for (ServiceResourceSkill objServiceResourceSkill : list_ServiceResourceSkills) {
					if (
						objServiceResourceSkill.Skill.MasterLabel == objruleSetSkill.Name &&
						skillLevelEligibility(objServiceResourceSkill, objruleSetSkill) &&
						skillDateEligibility(objServiceResourceSkill)
					) {
						blnHasSkills = true;
						break;
					}
				}
			}
		} else if (strLogic == LOGIC_AND) {
			Integer intSkillsCount = list_ruleSetSkills.size();
			Integer intSkillsMatched = 0;
			for (NBA_Rule_Set_Skill__c objruleSetSkill : list_ruleSetSkills) {
				for (ServiceResourceSkill objServiceResourceSkill : list_ServiceResourceSkills) {
					if (
						objServiceResourceSkill.Skill.MasterLabel == objruleSetSkill.Name &&
						skillLevelEligibility(objServiceResourceSkill, objruleSetSkill) &&
						skillDateEligibility(objServiceResourceSkill)
					) {
						intSkillsMatched++;
					}
				}
			}
			blnHasSkills = intSkillsMatched == intSkillsCount;
		}
		return blnHasSkills;
	}

	/**
	 * @description Checks if record is available and not recently served to a user
	 * @param      objRecordToReturn - Record to check
	 * @return     Boolean - returns a flag indicating if the record is available to be served
	 **/
	public static Boolean checkRecordAccess(SObject objRecordToReturn) {
		Boolean blnRecordAvailable = true;
		// check if already updated by another user
		// Get record Id and type of object
		Id idRecord = (Id) objRecordToReturn.get('Id');
		String strObjectType = idRecord.getSObjectType().getDescribe().getName();
		// Build query based on sobject type and query the served up time
		String strNameField = NAME_FIELD;
		if (strObjectType == TASK_OBJ || strObjectType == EVENT_OBJ) {
			strNameField = SUBJECT_FIELD;
		}
		Sobject objRecordCheck = Database.query('SELECT Id, Served_Up_Time__c, ' + strNameField + ' FROM ' + strObjectType + ' WHERE Id = :idRecord');
		if (objRecordCheck.get('Served_Up_Time__c') != null) {
			// if record has a served up time, check time difference. if it is less than 2 minutes. return error message
			DateTime dtmServedTime = (DateTime) objRecordCheck.get('Served_Up_Time__c');
			Integer intMinutes = Utils.getTimeStampDiff(dtmServedTime, System.now(), Utils.MINUTES);
			if (intMinutes < 2) {
				blnRecordAvailable = false;
			}
		}
		strServingRecordName = (String) objRecordCheck.get(strNameField);
		return blnRecordAvailable;
	}

	public static String getOrderByField(NBARequestWrapper.OrderByField objOrderByField) {
		String strField = '';

		if (objOrderByField.innerTables == null || objOrderByField.innerTables.isEmpty()) {
			strField = objOrderByField.selectedField;
		} else {
			List<String> list_OrderFields = new List<String>();
			for (NBARequestWrapper.InnerTables objInnerTable : objOrderByField.innerTables) {
				if (String.isNotBlank(objInnerTable.strRelationshipName)) {
					list_OrderFields.add(objInnerTable.strRelationshipName);
				}
			}
			strField = String.join(list_OrderFields, '.') + '.' + objOrderByField.selectedField;
		}

		return strField;
	}

	public static Boolean compareValues(Object value1, Object value2) {
		if (value1 == null || value2 == null) {
			return false;
		}

		if (value1 instanceof Comparable && value2 instanceof Comparable) {
			return ((Comparable) value1).compareTo(value2) > 0;
		} else if (value1 instanceof DateTime && value2 instanceof DateTime) {
			return DateTime.valueOf(value1) > DateTime.valueOf(value2);
		} else if (value1 instanceof Date && value2 instanceof Date) {
			return ((Date) value1).daysBetween((Date) value2) > 0;
		} else if (value1 instanceof Decimal && value2 instanceof Decimal) {
			return Decimal.valueOf((Double) value1) > Decimal.valueOf((Double) value2);
		} else if (value1 instanceof Integer && value2 instanceof Integer) {
			return Integer.valueOf(value1) > Integer.valueOf(value2);
		} else if (value1 instanceof Double && value2 instanceof Double) {
			return (Double) value1 > (Double) value2;
		} else if (value1 instanceof String && value2 instanceof String) {
			return ((String) value1).compareTo((String) value2) > 0;
		}

		return false;
	}

	/**
	 * @Description : Sets last ran with zero records for the rule or for a particluar user
	 * @Parm        : objRuleSet - Rule set record
	 * @Return      : objRuleSet - Rule set record
	 **/
	public static NBA_Rule_Set__c setLastRanWithZeroRecords(NBA_Rule_Set__c objRuleSet) {
		// if rule does not contain MYSELF - set the last ran with zero records for the rule
		if (!ruleContainsMyself(objRuleSet)) {
			objRuleSet.Last_Ran_With_Zero_Records__c = DateTime.now();
		} else {
			// if rule contains MYSELF - set the last ran with zero records for the user
			String strUserZeroRecords = objRuleSet.User_Last_Ran_With_Zero_Records__c;

			if (String.isBlank(strUserZeroRecords)) {
				List<UserZeroRecordsWrapper> list_UserZeroRecords = new List<UserZeroRecordsWrapper>();
				list_UserZeroRecords.add(new UserZeroRecordsWrapper(UserInfo.getUserId(), UserInfo.getName(), DateTime.now()));
				objRuleSet.User_Last_Ran_With_Zero_Records__c = JSON.serializePretty(list_UserZeroRecords);
			} else {
				// find the user if it exists within the list of users
				List<UserZeroRecordsWrapper> list_UserZeroRecords = (List<UserZeroRecordsWrapper>) JSON.deserialize(strUserZeroRecords, List<UserZeroRecordsWrapper>.class);
				Boolean blnUserFound = false;
				for (UserZeroRecordsWrapper objUserZeroRecord : list_UserZeroRecords) {
					if (objUserZeroRecord.strUserId == UserInfo.getUserId()) {
						objUserZeroRecord.dtmLastRanWithZeroRecords = DateTime.now();
						blnUserFound = true;
						break;
					}
				}

				// if user not found, create a new entry in the list
				if (!blnUserFound) {
					list_UserZeroRecords.add(new UserZeroRecordsWrapper(UserInfo.getUserId(), UserInfo.getName(), DateTime.now()));
				}

				objRuleSet.User_Last_Ran_With_Zero_Records__c = JSON.serializePretty(list_UserZeroRecords);
			}
		}

		return objRuleSet;
	}

	/**
	 * @Description : Check if rule contains any criteria that contains myself
	 * @Parm        : objRuleSet - Rule set record
	 * @Return      : Boolean - true if rule contains myself, false otherwise
	 **/
	public static Boolean ruleContainsMyself(NBA_Rule_Set__c objRuleSet) {
		Boolean blnRuleContainsMyself = false;

		for (NBA_Rule_Criteria__c objCriteria : objRuleSet.NBA_Rule_Criteria__r) {
			if (String.isNotBlank(objCriteria.Current_Criteria__c)) {
				NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objCriteria.Current_Criteria__c, NBARequestWrapper.class);

				if (String.isNotBlank(objRequest.soqlQuery) && objRequest.soqlQuery.containsIgnoreCase(NBAUtil.OWNER_ID_MYSELF)) {
					blnRuleContainsMyself = true;
					break;
				}
			}
		}
		return blnRuleContainsMyself;
	}

	/**
	 * @Description : Return the last ran with zero records. Checks if rule contains myself - then returns the last ran with zero records for the user
	 * @Parm        : objRuleSet - Rule set record
	 * @Return      : DateTime - Last ran with zero records of the user or the rule
	 **/
	public static DateTime returnLastZeroRecords(NBA_Rule_Set__c objRuleSet) {
		// if rule does not contain myself, return the last ran with zero records of the rule
		if (!ruleContainsMyself(objRuleSet)) {
			return objRuleSet.Last_Ran_With_Zero_Records__c;
		} else {
			// if rule contains myself, return the last ran with zero records of the user
			String strUserZeroRecords = objRuleSet.User_Last_Ran_With_Zero_Records__c;

			if (String.isBlank(strUserZeroRecords)) {
				return null;
			} else {
				List<UserZeroRecordsWrapper> list_UserZeroRecords = (List<UserZeroRecordsWrapper>) JSON.deserialize(strUserZeroRecords, List<UserZeroRecordsWrapper>.class);
				for (UserZeroRecordsWrapper objUserZeroRecord : list_UserZeroRecords) {
					if (objUserZeroRecord.strUserId == UserInfo.getUserId()) {
						return objUserZeroRecord.dtmLastRanWithZeroRecords;
					}
				}
			}
		}
		return null;
	}

	/**
	 * @Description : Update rule sets with last ran with zero records
	 * @Parm        : map_RuleSetsToUpdate - map of rule sets to update
	 * @Return      : NA
	 **/
	public static void updateRuleSets(Map<Id, NBA_Rule_Set__c> map_RuleSetsToUpdate) {
		if (!map_RuleSetsToUpdate.isEmpty()) {
			// check if rule sets have been updated recently - if they are not updated, update them again
			for (NBA_Rule_set__c objRuleSet : [
				SELECT Id, Last_Ran_With_Zero_Records__c, User_Last_Ran_With_Zero_Records__c, (SELECT Id, Current_Criteria__c FROM NBA_Rule_Criteria__r)
				FROM NBA_Rule_Set__c
				WHERE Id IN :map_RuleSetsToUpdate.keySet()
			]) {
				// check if Last_Ran_With_Zero_Records__c is in the past 2 minutes - then do not update
				// this is done to avoid lock row errors when multiple users are trying to serve records
				DateTime dtmLastZeroRecords = returnLastZeroRecords(objRuleSet);
				if (dtmLastZeroRecords != null && dtmLastZeroRecords > DateTime.now().addMinutes(-2)) {
					map_RuleSetsToUpdate.remove(objRuleSet.Id);
				}
			}
			if (!map_RuleSetsToUpdate.isEmpty()) {
				Database.update(map_RuleSetsToUpdate.values(), false);
			}
		}
	}
}