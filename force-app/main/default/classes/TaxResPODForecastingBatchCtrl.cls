/**
 * @name         TaxResPODForecastingBatchCtrl
 * @author       Anand Singh
 * @Date         12th October 2021
 * @description  This class handles the TaxRes POD Forecast after case creation
 * @test class   TaxResPODForecastingBatchCtrlTest.cls
 **/
public class TaxResPODForecastingBatchCtrl implements Schedulable, Database.Batchable<sObject> {
	static Date dtTOday = Date.today();
	static String CASE_STATUS_SOLVED = 'Solved';
	static String CASE_STATUS_CLOSED = 'Closed';
	static String EMAIL_TEMPLATE_NAME = 'Automated_E_Mail_to_Customer';
	static String CASE_RECORD_TYPE_ID = Cache.getRecordTypeId('Case', 'Tax Res');
	static Set<string> set_ExcludeCases = new Set<String>{ CASE_STATUS_SOLVED, CASE_STATUS_CLOSED };
	static String METADATA_FEATURE = 'Feature';
	static String METADATA_PODFORECAST = 'Tax_Res_POD_Forecast';
	static String AGENCY = 'Agency';
	public static String ACCOUNT_SPECIALIST = 'Account Specialist';
	static Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_FeatureConfigurationsTemp = getQueryConfigurationRecords(
		METADATA_FEATURE
	);

	static Map<String, String> map_AgencyPODMappings = getPODBasedOnAgencies();
	Configuration_Settings__c objConfiguration = Configuration_Settings__c.getOrgDefaults();

	/**
	 * @Author      : Anand Singh
	 * @Description : Start metod of Batch
	 * @Parm        : Object of BatchableContext.
	 * @Return      : List of Cases
	 **/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strQuery = '';
		if (map_FeatureConfigurationsTemp?.size() > 0) {
			if (map_FeatureConfigurationsTemp.containsKey(METADATA_PODFORECAST)) {
				strQuery = map_FeatureConfigurationsTemp.get(METADATA_PODFORECAST).Filter_Value__c;
			}

			if (Test.isRunningTest()) {
				strQuery = '';
				strQuery = 'SELECT ID,Account_Specialist_POD__c, ';
				strQuery = strQuery + ' Account_Specialist__c, ';
				strQuery = strQuery + ' Email_Status__c,Status,Agency_Information__c, ';
				strQuery = strQuery + ' RecordTypeId, Last_out_bound_email__c, ContactId, OwnerId FROM Case ';
				strQuery =
					strQuery + ' WHERE RecordTypeId =:CASE_RECORD_TYPE_ID AND Status NOT IN :set_ExcludeCases ';
				strQuery = strQuery + ' AND ContactId != null  AND Agency_Information__c != null ';
			}
		}

		return Database.getQueryLocator(strQuery);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : describle execute method.
	 * @Parm        : Object of SchedulableContext.
	 * @Return      : void
	 **/
	public void execute(SchedulableContext ctx) {
		Integer intBatchSize = 10;
		if (objConfiguration != null && objConfiguration.POD_Forecast_Batch_Size__c != null) {
			intBatchSize = Integer.valueOf(objConfiguration.POD_Forecast_Batch_Size__c);
		}

		TaxResPODForecastingBatchCtrl objCommBatch = new TaxResPODForecastingBatchCtrl();
		Database.executeBatch(objCommBatch, intBatchSize);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Execute metod of Batch
	 * @Parm        : Object of BatchableContex and list of Cases
	 * @Return      : NA
	 **/
	public void execute(Database.BatchableContext BC, List<Case> list_Cases) {
		TaxResPODForecastingBatchCtrl.PopulatePOD(list_Cases);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Finish metod of Batch
	 * @Parm        : Object of BatchableContex
	 * @Return      : NA
	 **/
	public void finish(Database.BatchableContext BC) {
		// Creating a exception log record only if there are errors in processing a batch of records.
		AsyncApexJob objAsyncJob = [
			SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
			FROM AsyncApexJob
			WHERE Id = :BC.getJobId()
		];
		Utils.processBatchFinish(objAsyncJob, 'TaxResPODForecastingBatchCtrl', false);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Method to get Case based on filter criteria to send an email
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public static void PopulatePOD(List<Case> list_TempCases) {
		Date dtToday = Date.today();
		List<Case> list_UpdateCases = new List<Case>();
		Set<Id> set_Agencies = new Set<Id>();

		if (list_TempCases?.size() > 0) {
			for (Case objCase : list_TempCases) {
				if (map_AgencyPODMappings?.size() > 0) {
					String strASKey = objCase.Agency_Information__c + '~' + ACCOUNT_SPECIALIST;
					if (
						map_AgencyPODMappings.containsKey(strASKey) != null &&
						objCase.Account_Specialist__c == null
					) {
						objCase.Account_Specialist_POD__c = map_AgencyPODMappings.get(strASKey);
					}

					if (
						objCase.Account_Specialist_POD__c != null
					) {
						list_UpdateCases.add(objCase);
					}
				}
			}
		}

		if (list_TempCases?.size() > 0) {
			RegionPODMappingTriggerHelper.skipTrigger(true);
			update list_UpdateCases;
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : get Feature value from Metadata
	 * @Parm        : String Team Name.
	 * @Return      : Map of Meta data records.
	 **/
	public static Map<String, Tax_Res_Play_Mode_Configuration__mdt> getQueryConfigurationRecords(String strTeamName) {
		Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_FeatureConfigurationsTemp = new Map<String, Tax_Res_Play_Mode_Configuration__mdt>();
		for (Tax_Res_Play_Mode_Configuration__mdt objConfig : [
			SELECT Id, Active__c, Filter_Value__c, DeveloperName
			FROM Tax_Res_Play_Mode_Configuration__mdt
			WHERE Team__c = :strTeamName
		]) {
			map_FeatureConfigurationsTemp.put(objConfig.DeveloperName, objConfig);
		}

		return map_FeatureConfigurationsTemp;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : get Mapping of Pod based on Agency and team
	 * @Parm        : null
	 * @Return      : Map of Region POD
	 **/
	public static Map<String, String> getPODBasedOnAgencies() {
		Map<String, String> map_AgencyPODMappingsTemp = new Map<String, String>();
		for (Region_POD_mapping__c objPODMapping : [
			SELECT Id, Agency__c, Region_POD__c, Region_POD__r.Team__c
			FROM Region_POD_mapping__c
			WHERE Region_POD__r.Type__c = :AGENCY
		]) {
			String strKey = objPODMapping.Agency__c + '~' + objPODMapping.Region_POD__r.Team__c;
			map_AgencyPODMappingsTemp.put(strKey, objPODMapping.Region_POD__c);
		}

		return map_AgencyPODMappingsTemp;
	}

}