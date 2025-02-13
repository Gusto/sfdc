/**
 * @author brent.johnson
 * @date 7/9/16
 * @see CacheTest
 */
public without sharing class Cache {
	public static boolean skipfunc = false; // skip functionality, required in some cases

	/**
	 * @description          Unsafe method to get Record Type Id, as it relies on RecordTypeName
	 *
	 * @param objectType     SObject name
	 * @param recordTypeName Record Type Name (not DeveloperName)
	 * @return               `Id`
	 * @deprecated Use RecordTypes.getRecordTypeIdFromName(objectType, recordTypeName)
	 */
	public static Id getRecordTypeId(String objectType, String recordTypeName) {
		return RecordTypes.getRecordTypeIdFromName(objectType, recordTypeName);
	}

	/**
	 * @description Get RecordTypeName from Id and ObjectType
	 * @param  objectType   SObject name
	 * @param  recordTypeId `RecordType` Id
	 * @return              Name
	 * @deprecated Use RecordTypes.getRecordTypeNameFromId(objectType, recordTypeId)
	 */
	public static String getRecordTypeName(String objectType, Id recordTypeId) {
		return RecordTypes.getRecordTypeNameFromId(objectType, recordTypeId);
	}

	/**
	 * @description Get RecordTypeName from Id and ObjectType
	 * @param  objectType   SObject name
	 * @param  recordTypeId `RecordType` Id
	 * @return              DeveloperName
	 * @deprecated Use RecordTypes.getRecordTypeDeveloperNameFromId(objectType, recordTypeId)
	 */
	public static String getRecordTypeDeveloperName(String objectType, Id recordTypeId) {
		return RecordTypes.getRecordTypeDeveloperNameFromId(objectType, recordTypeId);
	}

	/**
	 * @description
	 *
	 * @param objectType SObject Name
	 * @return           `Map<String, String>` RecordType Id, RecordType Name
	 */
	public static Map<String, String> getAllRecordTypeMap(String objectType) {
		Map<String, String> mapRecordTypeIdToName = new Map<String, String>();
		Map<String, Id> mapRecordTypeNameToId = RecordTypes.getRecordTypeNameIdMap(objectType);
		for (String s : mapRecordTypeNameToId.keyset()) {
			mapRecordTypeIdToName.put(mapRecordTypeNameToId.get(s), s);
		}
		return mapRecordTypeIdToName;
	}

	/**
	 * @description access picklist values from fields
	 * @param  Objectname Object name
	 * @param  FieldName  Field name
	 * @return            picklist (Label, Value)
	 */
	public static List<System.SelectOption> getFieldPickListValues(String Objectname, String FieldName) {
		List<System.SelectOption> pickListValues = new List<System.SelectOption>();
		Schema.DescribeSObjectResult sobject_describe = Utils.getSObjectDescribe(ObjectName);
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
		List<Schema.PicklistEntry> pick_list_values = field_map.get(FieldName).getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			SelectOption so = new selectOption(a.getLabel().trim(), a.getValue().trim());
			pickListValues.add(so);
		}
		return pickListValues;
	}

	/**
	 * To get the picklist values for a dependent picklist field along with its controlling field values
	 */
	public static Map<String, Map<String, String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
		Schema.DescribeFieldResult depend = dependToken.getDescribe();
		Schema.sObjectField controlToken = depend.getController();
		if (controlToken == null) {
			return null;
		}
		Schema.DescribeFieldResult control = controlToken.getDescribe();
		List<Schema.PicklistEntry> controlEntries = (control.getType() == Schema.DisplayType.Boolean ? null : control.getPicklistValues());

		String strBase64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
		Map<String, Map<String, String>> dependentPicklistValues = new Map<String, Map<String, String>>();
		for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
			if (entry.isActive()) {
				List<String> list_strBase64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
				for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
					Object controlValue = (controlEntries == null ? (Object) (index == 1) : (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null));
					Integer bitIndex = index / 6, bitShift = 5 - Math.mod(index, 6);
					if (controlValue == null ||  bitIndex >= list_strBase64chars.size() || (strBase64map.indexOf(list_strBase64chars[bitIndex]) & (1 << bitShift)) == 0) {
						continue;
					}
					if (!dependentPicklistValues.containsKey(String.ValueOf(controlValue))) {
						dependentPicklistValues.put(String.ValueOf(controlValue), new Map<String, String>());
					}
					dependentPicklistValues.get(String.ValueOf(controlValue)).put(entry.getValue(), entry.getLabel());
				}
			}
		}
		return dependentPicklistValues;
	}

	/**
	 * @description set all the textarea with the Specific rows or number of line of the data
	 * @author
	 * @param  objRecord              sobject
	 * @param  set_FieldsName         Set of fields
	 * @param  map_RowCountOfTextArea map of row count (String, Integer)
	 * @param  intRowCount            row count
	 * @param  intColsCount           columns count
	 * @return                        `Map<String, Inteber>`
	 */
	public static Map<String, Integer> setRowCountOfTextArea(sobject objRecord, Set<String> set_FieldsName, Map<String, Integer> map_RowCountOfTextArea, Integer intRowCount, Integer intColsCount) {
		for (String strTempFieldName : set_FieldsName) {
			if (String.valueof(objRecord.get(strTempFieldName)) != null && String.valueof(objRecord.get(strTempFieldName)).trim() != null) {
				objRecord.put(strTempFieldName, String.valueOf(objRecord.get(strTempFieldName)).trim());
				intRowCount = 0;
				if (string.valueOf(objRecord.get(strTempFieldName)).length() > intColsCount) {
					intRowCount = string.valueOf(objRecord.get(strTempFieldName)).length() / intColsCount;
				}
				intRowCount = intRowCount + string.valueOf(objRecord.get(strTempFieldName)).split('\n').size();
				if (intRowCount < 4) {
					intRowCount = 4;
				}
			}
			map_RowCountOfTextArea.put(strTempFieldName, intRowCount);
		}
		return map_RowCountOfTextArea;
	}

	/**
	 * @description add error Message to Apex Page Message
	 * @param  strMessage Message body
	 * @param  severity   Message severity
	 */
	public static void displayErrorMessage(string strMessage, ApexPages.Severity severity) {
		if (!String.isBlank(strMessage) && severity != null) {
			ApexPages.getMessages().clear();
			ApexPages.Message objApexMessage;
			objApexMessage = new ApexPages.Message(severity, strMessage);
			ApexPages.addMessage(objApexMessage);
		}
	}
}