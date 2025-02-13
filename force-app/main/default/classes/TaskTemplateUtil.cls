/**
 * @author       Ajay Krishna P U
 * @date         12-19-2022
 * @description  Utility Class to dynamically generate Tasks based on Templates
 * @test classes TaskTemplateUtilTest
 */
public without sharing class TaskTemplateUtil {
	//Constants
	private final static Pattern MERGE_PATTERN = Pattern.compile('\\{\\{[^\\}]+\\}\\}'); // {{[^}]}}
	private final static String USER_PREFIX = User.sObjectType.getDescribe().getKeyPrefix();
	public final static String ASSIGN_TO_TARGET_OWNER = 'Owner of Target Object';
	public final static String ASSIGN_TO_QUEUE = 'Queue';
	public final static String ASSIGN_TO_PERMISSION_SET = 'Permission Set User';
	public final static String ARDIUS_TEAM_PERMISSION = 'Ardius_Onboarding_Team';

	//Variables
	private static Map<String, Map<String, Task_Template__mdt>> map_TypeToSubTypeTaskTemplates;

	/**
	 * @description   Get Task Template Sub Types of Type @strType
	 *
	 * @param strType Type value
	 * @return        `Set<String>`
	 */
	public static Set<String> getTemplateSubTypes(String strType) {
		Set<String> set_SubTypes = getTypeSubTypeTemplateMap().get(strType)?.keySet();
		return set_SubTypes == null ? new Set<String>() : set_SubTypes;
	}

	/**
	 * @description     Generate Task
	 *
	 * @param list_TemplateTypes Template Types
	 * @param strSObjectName     SObject API Name
	 * @return                   `List<Task>`
	 * @exception                throws CustomException if Template not found
	 */
	public static List<Task> generateTasks(List<TemplateType> list_TemplateTypes, String strSObjectName) {
		Map<String, Map<String, Task_Template__mdt>> map_TypeToSubTypeTaskTemplates = getTypeSubTypeTemplateMap();

		Set<String> set_QueueNames = new Set<String>();
		Set<String> set_QueryFields = new Set<String>();
		Set<Id> set_TargetIds = new Set<Id>();
		Set<String> set_PermissionSetNames = new Set<String>();
		Map<String, Id> map_TaskRecordTypeNameToId = new Map<String, Id>();
		Map<String, Set<Id>> map_PermissionSetUsers = new Map<String, Set<Id>>();

		//Pre calculate required QueueIds, RecordTypeIds, TargetFields to query, etc
		for (TemplateType objTemplateType : list_TemplateTypes) {
			Task_Template__mdt objTemplate = map_TypeToSubTypeTaskTemplates.get(objTemplateType.strType)?.get(objTemplateType.strSubType);
			if (objTemplate == null) {
				throw new CustomException('Template Not found, Type:' + objTemplateType.strType + ' SubType:' + objTemplateType.strSubType);
			}

			//If Have Merge fields
			if (objTemplate.Merge_Fields__c != null) {
				set_QueryFields.addAll(objTemplate.Merge_Fields__c.split(','));
				set_TargetIds.add(objTemplateType.idTargetObj);
			}

			// If Assign To is Target Owner or Permission Set User
			if (objTemplate.Assigned_To__c == ASSIGN_TO_TARGET_OWNER || objTemplate.Assigned_To__c == ASSIGN_TO_PERMISSION_SET) {
				set_TargetIds.add(objTemplateType.idTargetObj);
			}

			//If permission set names are mentioned
			if (objTemplate.Permission_Set_Name__c != null) {
				set_PermissionSetNames.add(objTemplate.Permission_Set_Name__c);
			}

			set_QueueNames.add(objTemplate.Assign_To_Queue_Name__c);
			map_TaskRecordTypeNameToId.put(objTemplate.Task_Record_Type_Name__c, RecordTypes.getRecordTypeIdFromDeveloperName('Task', objTemplate.Task_Record_Type_Name__c));
		}

		//Cleanup query sets
		set_QueueNames.remove(null);
		set_QueryFields.remove(null);

		//Get the Queue Ids
		Map<String, Id> map_TaskQueueNameToId = GlobalQueryHelper.getQueueNameAndIdMap(set_QueueNames);

		//Query SObjects
		Map<Id, SObject> map_SObjects = querySObjects(strSObjectName, set_QueryFields, set_TargetIds);

		//Query permission set users for the mentioned permission
		if (set_PermissionSetNames != null) {
			map_PermissionSetUsers = GlobalQueryHelper.getPermissionSetUsers(set_PermissionSetNames, null);
		}

		//Generate Tasks
		List<Task> list_Tasks = new List<Task>();
		for (TemplateType objTemplateType : list_TemplateTypes) {
			Task_Template__mdt objTemplate = map_TypeToSubTypeTaskTemplates.get(objTemplateType.strType)?.get(objTemplateType.strSubType);
			Map<String, String> map_OverrideTaskFields = objTemplateType.map_OverrideTaskFields;
			SObject objTarget = map_SObjects.get(objTemplateType.idTargetObj);

			list_Tasks.add(
				new Task(
					RecordTypeId = map_TaskRecordTypeNameToId.get(objTemplate.Task_Record_Type_Name__c),
					OwnerId = resolveOwnerId(objTemplate, map_TaskQueueNameToId, objTarget, map_PermissionSetUsers),
					Description = resolveMergeFields(objTemplate.Comments__c, objTarget, objTemplate),
					ActivityDate = resolveDueDate(objTemplate),
					Priority = overrideFieldDefaults(TicketUtil.TASK_FIELD_PRIORITY, map_OverrideTaskFields, objTemplate.Priority__c),
					Status = overrideFieldDefaults(TicketUtil.TASK_FIELD_STATUS, map_OverrideTaskFields, objTemplate.Status__c),
					Subject = resolveMergeFields(objTemplate.Subject__c, objTarget, objTemplate),
					Type = overrideFieldDefaults(TicketUtil.TASK_FIELD_TYPE, map_OverrideTaskFields, objTemplate.Task_Type__c),
					WhatId = objTemplateType.idTargetObj,
					Feature_Request__c = String.isNotBlank(objTemplate.Task_Identifier__c) ? objTemplate.Task_Identifier__c : objTemplateType.strSubType
				)
			);
		}

		return list_Tasks;
	}

	/**
	 * @description                  Override Default values If specified in Template Request
	 * @param strFieldName           Field Api Name to which value will be overbidden
	 * @param map_OverrideTaskFields Map of Field --> Value to override
	 * @param strDefaultValue        Default Value, If no Override
	 * @return                       `String`
	 */
	private static String overrideFieldDefaults(String strFieldName, Map<String, String> map_OverrideTaskFields, String strDefaultValue) {
		if (map_OverrideTaskFields != null && map_OverrideTaskFields.containsKey(strFieldName)) {
			return map_OverrideTaskFields.get(strFieldName);
		}

		return strDefaultValue;
	}

	/**
	 * @description Calculate, Backup & return map of Type --> SubType --> Task Template
	 *
	 * @return      `Map<String, Map<String, Task_Template__mdt>>`
	 */
	@TestVisible
	private static Map<String, Map<String, Task_Template__mdt>> getTypeSubTypeTemplateMap() {
		if (map_TypeToSubTypeTaskTemplates != null) {
			return map_TypeToSubTypeTaskTemplates;
		}

		map_TypeToSubTypeTaskTemplates = new Map<String, Map<String, Task_Template__mdt>>();
		for (Task_Template__mdt objTemplate : [
			SELECT
				Type__c,
				Sub_Type__c,
				Assigned_To__c,
				Assign_To_Queue_Name__c,
				Assign_To_Queue_If_Target_Owner_Is_Queue__c,
				Comments__c,
				No_of_Business_Days_from_Creation_to_Due__c,
				Priority__c,
				Status__c,
				Subject__c,
				Task_Record_Type_Name__c,
				Task_Type__c,
				Merge_Fields__c,
				Permission_Set_Name__c,
				DeveloperName,
				Task_Identifier__c
			FROM Task_Template__mdt
			WHERE Is_Active__c = TRUE
		]) {
			Map<String, Task_Template__mdt> map_SubTypeToTemplate = map_TypeToSubTypeTaskTemplates.get(objTemplate.Type__c);
			if (map_SubTypeToTemplate == null) {
				map_SubTypeToTemplate = new Map<String, Task_Template__mdt>();
				map_TypeToSubTypeTaskTemplates.put(objTemplate.Type__c, map_SubTypeToTemplate);
			}

			map_SubTypeToTemplate.put(objTemplate.Sub_Type__c, objTemplate);
		}

		return map_TypeToSubTypeTaskTemplates;
	}

	/**
	 * @description           Query SObjects dynamically
	 *
	 * @param strSObjectName  SObject API Name to Query
	 * @param set_QueryFields Set of Query fields
	 * @param set_TargetIds   Set of SObject Ids of Type @strSObjectName
	 * @return                `Map<Id, SObject>`
	 */
	@TestVisible
	private static Map<Id, SObject> querySObjects(String strSObjectName, Set<String> set_QueryFields, Set<Id> set_TargetIds) {
		if (set_TargetIds.isEmpty()) {
			return new Map<Id, SObject>();
		}

		set_QueryFields.add('Id');
		set_QueryFields.add('OwnerId');
		String strQuery = String.format('SELECT {0} FROM {1} WHERE Id IN:{2}', new List<String>{ String.join(new List<String>(set_QueryFields), ','), strSObjectName, 'set_TargetIds' });
		return new Map<Id, SObject>(Database.query(strQuery));
	}

	/**
	 * @description                 Calculates Task Owner based on selected Assigned To type
	 *
	 * @param objTemplate           Task Template Configuration
	 * @param map_TaskQueueNameToId Map of Queue Name to Id
	 * @param objTarget             Target SObject or Parent of generated Task
	 * @return                      `Id`
	 */
	@TestVisible
	private static Id resolveOwnerId(Task_Template__mdt objTemplate, Map<String, Id> map_TaskQueueNameToId, SObject objTarget, Map<String, Set<Id>> map_PermissionSetUsers) {
		Id idOwnerId = (Id) objTarget.get('OwnerId');

		//If Owner has the mentioned permission set then Task owner is same as Target Object
		if (
			objTemplate.Assigned_To__c == ASSIGN_TO_PERMISSION_SET &&
			String.valueOf(idOwnerId).startsWithIgnoreCase(USER_PREFIX) &&
			String.isNotBlank(objTemplate.Permission_Set_Name__c) &&
			map_PermissionSetUsers.containsKey(objTemplate.Permission_Set_Name__c) &&
			map_PermissionSetUsers.get(objTemplate.Permission_Set_Name__c)?.contains(idOwnerId) == true
		) {
			return idOwnerId;
		}
		//If Target Object Owner is a Queue then resolve OwnerId to "Assign to Queue" value.
		if (objTemplate.Assigned_To__c == ASSIGN_TO_TARGET_OWNER) {
			return objTemplate.Assign_To_Queue_If_Target_Owner_Is_Queue__c && !String.valueOf(idOwnerId).startsWithIgnoreCase(USER_PREFIX)
				? map_TaskQueueNameToId.get(objTemplate.Assign_To_Queue_Name__c)
				: idOwnerId;
		}

		//If Assign to is Queue
		return map_TaskQueueNameToId.get(objTemplate.Assign_To_Queue_Name__c);
	}

	/**
	 * @description       Return Merge fields resolved template string @strValue
	 *
	 * @param strValue    A template string have Merge fields in format {{MergeFieldName}}
	 * @param obj         Target SObject from which Merge fields are resolved
	 * @param objTemplate TaskTemplate
	 * @return            `String`
	 */
	@TestVisible
	private static String resolveMergeFields(String strValue, SObject obj, Task_Template__mdt objTemplate) {
		if (objTemplate.Merge_Fields__c == null || strValue == null) {
			return strValue;
		}

		Matcher objMatcher = MERGE_PATTERN.matcher(strValue);
		String strMerged = '';
		Integer intLastProcessedIndex = 0;

		while (objMatcher.find()) {
			//Find the field Name
			String strFieldName = objMatcher.group(); // {{fieldName}}
			strFieldName = strFieldName.substring(2, strFieldName.length() - 2).trim(); //fieldName

			//Find field value
			String strFieldValue = getFieldValue(obj, strFieldName);
			strFieldValue = String.isBlank(strFieldValue) ? '' : strFieldValue;

			//Concatenate Last processed to matching start
			strMerged += strValue.substring(intLastProcessedIndex, objMatcher.start());

			//Concatenate Field Value
			strMerged += strFieldValue;

			//Update last Process Index
			intLastProcessedIndex = objMatcher.end();
		}

		//Merge Remaining
		strMerged += strValue.substring(intLastProcessedIndex, strValue.length());

		return strMerged;
	}

	/**
	 * @description       Calculate Due date from Configured No.Of Business days
	 * 					  Calculation is based on Business days - Utilizes Default Org Business Hours
	 *
	 * @param objTemplate Task Template Configuration
	 * @return            `Date`
	 */
	@TestVisible
	private static Date resolveDueDate(Task_Template__mdt objTemplate) {
		Integer intNoOfDays = Integer.valueOf(objTemplate.No_of_Business_Days_from_Creation_to_Due__c);
		return Utils.addBusinessDays(Date.today(), intNoOfDays);
	}

	/**
	 * @description        Get SObject Field value of any levels
	 *
	 * @param obj          SObject instance
	 * @param strFieldName Field Name, supports multiple levels like Opportunity__r.Contact.Account__r.Name
	 * @return             `String`
	 */
	@TestVisible
	private static String getFieldValue(SObject obj, String strFieldName) {
		List<String> list_FieldLevels = strFieldName.split('\\.');
		String strLastField = list_FieldLevels.remove(list_FieldLevels.size() - 1);
		for (String strFieldLevel : list_FieldLevels) {
			if (obj == null) {
				return null;
			}

			obj = obj.getSObject(strFieldLevel);
		}

		if (obj == null) {
			return null;
		}

		Object objValue = obj.get(strLastField);
		return objValue == null ? null : String.valueOf(objValue);
	}

	/**
	 * Task Template Generator Type
	 */
	public class TemplateType {
		Id idTargetObj;
		String strType;
		String strSubType;
		Map<String, String> map_OverrideTaskFields; // Task Field Override FieldName --> Value

		/**
		 * @description       Constrictor for TemplateType
		 *
		 * @param idTargetObj Id of Target Object, The generated task will be link to Target object as well Merged fields are populated from Target Object
		 * @param strType     Task Template
		 * @param strSubType  Task Template Sub Type
		 */
		public TemplateType(Id idTargetObj, String strType, String strSubType) {
			this(idTargetObj, strType, strSubType, null);
		}

		/**
		 * @description       Constrictor for TemplateType
		 *
		 * @param idTargetObj Id of Target Object, The generated task will be link to Target object as well Merged fields are populated from Target Object
		 * @param strType     Task Template
		 * @param strSubType  Task Template Sub Type
		 * @param map_OverrideTaskFields Map Field Override FieldName --> Value
		 */
		public TemplateType(Id idTargetObj, String strType, String strSubType, Map<String, String> map_OverrideTaskFields) {
			this.idTargetObj = idTargetObj;
			this.strType = strType;
			this.strSubType = strSubType;
			this.map_OverrideTaskFields = map_OverrideTaskFields;
		}
	}

	/**
	 * Top Create specific Exceptions for Task generation
	 */
	public class CustomException extends Exception {
	}
}