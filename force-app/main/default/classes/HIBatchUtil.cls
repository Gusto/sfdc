/**
 * @description       Utility methods for HI Benefits Batch processing
 * @author            Nigam Goyal
 * TestClassName 	  HIBatchUtilTest
 **/
public with sharing class HIBatchUtil {
	public static final String FILTER_TYPE_BASE_QUERY = 'Base Query';
	public static final String FILTER_TYPE_WHERE_CLAUSE = 'Where Clause';
	public static final String FILTER_TYPE_ORDER_BY = 'Order By';
	public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
	public static final String FILTER_TYPE_DEAD_AFTER_DAYS = 'Dead After Days';
	public static final String FILTER_TYPE_DELETE_AFTER_DAYS = 'Delete After Days';
	public static final String PROCESSING_STATE_DEAD = 'Dead';
	public static final String PROCESSING_STATE_ERROR = 'Error';
	public static final String PROCESSING_STATE_BACKLOG = 'Backlog';
	public static final String PROCESSING_STATE_Queued = 'Queued';
	public static final String BEN_PACKAGE_MISSING = 'Benefits Package does not exist.';

	/**
	 * @description
	 * @author Nigam Goyal | 05-22-2024
	 * @param strWhereClause Replace the date placeholder with actual date variable
	 * @param intMarkDeadAfterDays Hold the value of Number of Days to Mark Dead Status
	 * @param intDeleteAfterDays Hold the value of Number of Days to Delete the record after marking it as Dead
	 * @return String Return the where clause with actual date variable
	 **/
	public static String getHIBatchConfigWhereClause(String strWhereClause, Integer intMarkDeadAfterDays, Integer intDeleteAfterDays) {
		if (String.isNotBlank(strWhereClause)) {
			DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
			DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
			strWhereClause = strWhereClause.replace('dateForError', 'dtDeadCheck');
			strWhereClause = strWhereClause.replace('dateForDead', 'dtDeleteCheck');
			return strWhereClause;
		}
		return '';
	}

	/**
	 * @description To Build Map of Filter Type and HI_Configuration__mdt Instance
	 * @author Nigam Goyal | 05-29-2024
	 * @param strClassName To get setting for specfic HI Class
	 * @return Map<String, HI_Configuration__mdt>
	 **/
	public static Map<String, HI_Configuration__mdt> fetchHIConfigurations(String strClassName) {
		Map<String, HI_Configuration__mdt> map_HIConfigurations = new Map<String, HI_Configuration__mdt>();
		List<HI_Configuration__mdt> list_HIConfigurations = [
			SELECT MasterLabel, DeveloperName, Filter_Type__c, Value__c
			FROM HI_Configuration__mdt
			WHERE Active__c = TRUE AND MasterLabel = :strClassName
		];
		if (Test.isRunningTest()) {
			for (HI_Configuration__mdt objConfig : getHIConfigurationCustomMetadataTestRecords()) {
				if (!map_HIConfigurations.containsKey(objConfig.Filter_Type__c) && objConfig.MasterLabel == strClassName) {
					map_HIConfigurations.put(objConfig.Filter_Type__c, objConfig);
				}
			}
		}
		for (HI_Configuration__mdt objConfig : list_HIConfigurations) {
			if (!map_HIConfigurations.containsKey(objConfig.Filter_Type__c)) {
				map_HIConfigurations.put(objConfig.Filter_Type__c, objConfig);
			}
		}
		return map_HIConfigurations;
	}

	/**
	* @description To create instance of custom metadata setting to test in test class
	* @author Nigam Goyal | 08-06-2024 
	* @param strMasterLabel 
	* @param strDeveloperName 
	* @param strFilterType 
	* @param strValue 
	* @return HI_Configuration__mdt 
	**/
	public static HI_Configuration__mdt getHIConfigurationCustomMetadataRecord(String strMasterLabel, String strDeveloperName, String strFilterType, String strValue) {
		HI_Configuration__mdt objHIConfiguration = new HI_Configuration__mdt();
		objHIConfiguration.MasterLabel = strMasterLabel;
		objHIConfiguration.DeveloperName = strDeveloperName;
		objHIConfiguration.Filter_Type__c = strFilterType;
		objHIConfiguration.Value__c = strValue;
		return objHIConfiguration;
	}

	/**
	* @description To create instances of custom metadata setting to test in test class
	* @author Nigam Goyal | 08-06-2024 
	* @return List<HI_Configuration__mdt> 
	**/
	public static List<HI_Configuration__mdt> getHIConfigurationCustomMetadataTestRecords() {
		List<HI_Configuration__mdt> list_HIConfigurations = new List<HI_Configuration__mdt>();
		// HIPolicyBatch Records
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HIPolicyBatch',
				'HIPolicyBatch_Base_Query',
				'Base Query',
				'SELECT Id, Message__c, Processing_State__c, CreatedDate FROM HI_Policy__c')
		);
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HIPolicyBatch',
				'HIPolicyBatch_Dead_After_Days',
				'Dead After Days',
				'7'));
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HIPolicyBatch',
				'HIPolicyBatch_Delete_After_Days',
				'Delete After Days',
				'180'));
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HIPolicyBatch',
				'HIPolicyBatch_Where_Clause',
				'Where Clause',
				'WHERE Processing_State__c IN (\'Error\', \'Queued\',\'Backlog\')  OR (Processing_State__c = \'Dead\' AND CreatedDate < :dateForDead)'
			)
		);
		// HICarrierInformationBatch records
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HICarrierInformationBatch',
				'HICarrierInformation_Base_Query',
				'Base Query',
				'Select Id, Processing_State__c, CreatedDate FROM HI_Carrier_Information__c')
		);
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HICarrierInformationBatch',
				'HICarrierInformation_Dead_After_Days',
				'Dead After Days',
				'7'));
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HICarrierInformationBatch',
				'HICarrierInformation_Delete_After_Days',
				'Delete After Days',
				'180'));
		list_HIConfigurations.add(
			getHIConfigurationCustomMetadataRecord(
				'HICarrierInformationBatch',
				'HICarrierInformation_Where_Clause',
				'Where Clause',
				'WHERE Processing_State__c IN (\'Error\', \'Queued\',\'Backlog\') OR (Processing_State__c = \'Dead\' AND CreatedDate < :dateForDead)'
			)
		);
		return list_HIConfigurations;
	}
}