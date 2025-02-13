/**
 * @description  Integration Utils
 * @author       Praveen Sethu
 * @date         02-07-2022
 * @see          IntegrationUtilsTest
 **/
public without sharing class IntegrationUtils {
	public static final String ERROR_STATE = 'Error';
	public static final String QUEUED_STATE = 'Queued';
	public static final String PROCESSED_STATE = 'Processed';
	public static final String DEAD_STATE = 'Dead';
	public static final String BACKLOG = 'Backlog';
	public static final String MANUAL_ENQUEUE = 'Manually Enqueued';

	/**
	 * @description Query Integration Field Value Mapping
	 * @author      Praveen Sethu
	 * @param       String - strObjectName
	 * @param       String - strFieldName
	 * @return      Map of integration value and salesforce value
	 **/
	public static Map<String, String> getIntegrationValueMap(String strObjectName, String strFieldName) {
		Map<String, String> map_Values = new Map<String, String>();

		for (Integration_Field_Value_Mapping__mdt objFieldMap : [
			SELECT Id, Object_Name__c, Field_Name__c, Integration_Value__c, Salesforce_Value__c
			FROM Integration_Field_Value_Mapping__mdt
			WHERE Object_Name__c = :strObjectName AND Field_name__c = :strFieldName
		]) {
			map_Values.put(objFieldMap.Integration_Value__c, objFieldMap.Salesforce_Value__c);
		}
		return map_Values;
	}

	/**
	 * @description We are getting the json string and strKeyWord as parameters and returning the related value back
	 * @author      Praveen Sethu
	 * @param       String - strOriginalJsonString
	 * @param       String - strFieldName
	 * @return      String value
	 **/
	public static String getJsonParsedMap(String strOriginalJsonString, String strKeyWord) {
		String strResult;
		if (strOriginalJsonString != null) {
			strOriginalJsonString = strOriginalJsonString.replace('=>', ':');
		}

		try {
			System.JSONParser objParser = JSON.createParser(strOriginalJsonString);
			while (objParser.nextToken() != null) {
				if (strKeyWord != null && strKeyWord.equalsIgnoreCase(objParser.getCurrentName())) {
					strResult = objParser.getText();
				}
				objParser.nextToken();
			}
		} catch (exception ex) {
		}

		return strResult;
	}

	/**
	 * @description Get Integration System Info
	 * @author      Praveen Sethu
	 * @param       String - strIntegrationName
	 * @return      Integration_System_Information__c
	 **/
	public static Integration_System_Information__c getIntegrationSystemInfo(String strIntegrationName) {
		Integration_System_Information__c objInfo = new Integration_System_Information__c();
		if (Integration_System_Information__c.getValues(strIntegrationName) != null) {
			objInfo = Integration_System_Information__c.getValues(strIntegrationName);
		}

		return objInfo;
	}
}