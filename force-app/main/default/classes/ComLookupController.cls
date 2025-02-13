/**
 * @name         : ComLookupController
 * @author       : Nigam Goyal
 * @date         : 06-22-2022
 * @description  : Used for Custom Lookup Single Select and Multi-Select c
 * @test classes : ComLookupControllerTest
 **/

public with sharing class ComLookupController {
	/**
	 * @description get sobject name
	 * @author Nigam Goyal | 07-26-2022
	 * @param list_SelectedRecordIds
	 * @return string
	 **/
	@AuraEnabled
	public static string getSobjectName(List<Id> list_SelectedRecordIds) {
		try {
			String strSobjName;
			if (list_SelectedRecordIds != null && list_SelectedRecordIds.size() > 0) {
				strSobjName = list_SelectedRecordIds[0].getSObjectType().getDescribe().getName();
			}
			return strSobjName;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : Handle title field for different objects
	 * @Parm        : String sobjectName
	 * @Return      : Name of Title Field of Particular object
	 **/
	public static String selectTitleFieldApiName(String strObjectName) {
		String strTitleFieldApiName;
		strObjectName = strObjectName.toLowerCase();
		switch on strObjectName {
			when 'case' {
				strTitleFieldApiName = ComLookupUtil.CASE_OBJECT_TITLE_FIELDNAME;
			}
			when 'task' {
				strTitleFieldApiName = ComLookupUtil.TASK_OBJECT_TITLE_FIELDNAME;
			}
			when 'event' {
				strTitleFieldApiName = ComLookupUtil.EVENT_OBJECT_TITLE_FIELDNAME;
			}
			when 'assetrelationship' {
				strTitleFieldApiName = ComLookupUtil.ASSET_RELATIONSHIP_OBJECT_TITLE_FIELDNAME;
			}
			when 'knowledge__kav' {
				strTitleFieldApiName = ComLookupUtil.KNOWLEDGE_OBJECT_TITLE_FIELDNAME;
			}
			when 'emailmessage' {
				strTitleFieldApiName = ComLookupUtil.EMAILMESSAGE_OBJECT_TITLE_FIELDNAME;
			}
			when 'contentdocument' {
				strTitleFieldApiName = ComLookupUtil.CONTENTDOCUMENT_OBJECT_TITLE_FIELDNAME;
			}
			when 'contentversion' {
				strTitleFieldApiName = ComLookupUtil.CONTENTVERSION_OBJECT_TITLE_FIELDNAME;
			}
			when else {
				strTitleFieldApiName = ComLookupUtil.DEFAULT_OBJECT_TITLE_FIELDNAME;
			}
		}
		return strTitleFieldApiName;
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : To get recent records or list of records based on entered value in lookup field
	 * @Param       : String strSobjectName,
	 * @Param       : String strShowFieldApiName
	 * @Param       : String strFieldApiName,
	 * @Param       : String strSearchFieldApiName,
	 * @Param       : String strSearchText,
	 * @Param       : List<String> list_SelectedRecordIds,
	 * @Param       : String strWhereConditions,
	 * @Param       : List<String> list_QueryFieldsApiNames
	 * @Return      : list of sobject record from query
	 **/
	@AuraEnabled
	public static List<SObject> getRecordsList(
		String strSobjectName,
		String strShowFieldApiName,
		String strFieldApiName,
		String strSearchFieldApiName,
		String strSearchText,
		List<String> list_SelectedRecordIds,
		String strWhereConditions,
		List<String> list_QueryFieldsApiNames
	) {
		try {
			List<SObject> list_Sobjects = new List<SObject>();
			Set<Id> set_QueryRecordIds = new Set<Id>();
			if (String.isBlank(strSearchText) && String.isNotBlank(strSobjectName)) {
				List<RecentlyViewed> list_RecentlyVieweds = new List<RecentlyViewed>(
					[SELECT Id, Name, Type FROM RecentlyViewed WHERE Type = :strSobjectName WITH SECURITY_ENFORCED ORDER BY LastViewedDate DESC LIMIT 12]
				);
				for (RecentlyViewed objrecentlyViewed : list_RecentlyVieweds) {
					if (set_QueryRecordIds.size() < 6) {
						set_QueryRecordIds.add(objrecentlyViewed.Id);
					}
				}
			}

			if (String.isNotBlank(strSobjectName) && String.isNotBlank(strFieldApiName)) {
				if (String.isBlank(strSearchFieldApiName)) {
					strSearchFieldApiName = selectTitleFieldApiName(strSobjectName);
				}
				if (String.isBlank(strShowFieldApiName)) {
					strShowFieldApiName = selectTitleFieldApiName(strSobjectName);
				}
				String strSearchValue = '\'%' + String.escapeSingleQuotes(strSearchText.trim()) + '%\'';

				String strQuery = 'SELECT ' + strShowFieldApiName + ' ';
				strQuery += ' , ' + strFieldApiName + ' ';
				if (list_QueryFieldsApiNames != null && list_QueryFieldsApiNames.size() > 0) {
					for (String strObjectField : list_QueryFieldsApiNames) {
						if (strObjectField.toLowerCase() != strFieldApiName.toLowerCase() && strObjectField.toLowerCase() != strShowFieldApiName.toLowerCase()) {
							strQuery += ' , ' + strObjectField + ' ';
						}
					}
				}

				strQuery += ' FROM ' + strSobjectName;
				strQuery += ' WHERE ' + strSearchFieldApiName + ' LIKE ' + strSearchValue;
				strQuery += ' AND ' + strFieldApiName + ' <> NULL ';

				if (list_SelectedRecordIds != null && list_SelectedRecordIds.size() > 0) {
					strQuery += ' AND ' + strFieldApiName + ' NOT IN :list_SelectedRecordIds';
				}

				if (set_QueryRecordIds != null && set_QueryRecordIds.size() > 0) {
					strQuery += ' AND ' + strFieldApiName + ' IN :set_QueryRecordIds';
				}

				if (String.isNotEmpty(strWhereConditions)) {
					strQuery += ' AND ' + strWhereConditions;
				}

				strQuery += ' WITH SECURITY_ENFORCED ORDER BY ' + strSearchFieldApiName + ' LIMIT 5';
				list_Sobjects = Database.query(strQuery);
			}
			return list_Sobjects;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class SObjectListAndObjLabel {
		@AuraEnabled
		public String strLabel;
		@AuraEnabled
		public List<SObject> list_Sobjects;
		@AuraEnabled
		public String strShowAndSrchFieldApiName;
	}

	/**
	 * @description Prepopulate the name of recordIds
	 * @author Nigam Goyal | 07-26-2022
	 * @param strObjectName
	 * @param strShowFieldApiName
	 * @param strFieldApiName
	 * @param list_SelectedRecordIds
	 * @param list_QueryFieldsApiNames
	 * @return SObjectListAndObjLabel custom wrapper which has object label and list of records, title field name
	 **/
	@AuraEnabled
	public static SObjectListAndObjLabel getSelectedRecordsList(
		String strObjectName,
		String strShowFieldApiName,
		String strFieldApiName,
		List<String> list_SelectedRecordIds,
		List<String> list_QueryFieldsApiNames
	) {
		try {
			SObjectListAndObjLabel objSobjectListAndLabel = new SObjectListAndObjLabel();

			if (String.isNotEmpty(strObjectName)) {
				objSobjectListAndLabel.strLabel = Utils.getSObjectDescribe(strObjectName).getLabel();
				if (String.isBlank(strShowFieldApiName)) {
					strShowFieldApiName = selectTitleFieldApiName(strObjectName);
					objSobjectListAndLabel.strShowAndSrchFieldApiName = strShowFieldApiName;
				}
			}

			if (String.isNotEmpty(strObjectName) && String.isNotEmpty(strFieldApiName) && list_SelectedRecordIds != null && list_SelectedRecordIds.size() > 0) {
				objSobjectListAndLabel.list_Sobjects = new List<SObject>();
				String strQuery = 'SELECT ' + strShowFieldApiName + ' ';
				strQuery += ' , ' + strFieldApiName + ' ';
				if (list_QueryFieldsApiNames != null && list_QueryFieldsApiNames.size() > 0) {
					for (String strObjectField : list_QueryFieldsApiNames) {
						if (strObjectField.toLowerCase() != strFieldApiName.toLowerCase() && strObjectField.toLowerCase() != strShowFieldApiName.toLowerCase())
							strQuery += ' , ' + strObjectField + ' ';
					}
				}
				strQuery += ' FROM ' + strObjectName;
				strQuery += ' WHERE ' + strFieldApiName + ' IN :list_SelectedRecordIds';
				strQuery += ' AND ' + strFieldApiName + '<> NULL WITH SECURITY_ENFORCED';
				objSobjectListAndLabel.list_Sobjects = Database.query(strQuery);
			}
			return objSobjectListAndLabel;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}