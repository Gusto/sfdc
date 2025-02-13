/**
 * @name         RegionPODMappingTriggerHelper
 * @author       Anand Singh
 * @Date         25th October 2021
 * @description  This class handles the TaxRes POD Forecast once Agancey get update from one Pod to another
 * @test class   RegionPODMappingTriggerHelperTest.cls
 **/
public with sharing class RegionPODMappingTriggerHelper {
	public static boolean blnSkipTrigger = false;
	static String CASE_STATUS_SOLVED = 'Solved';
	static String CASE_STATUS_CLOSED = 'Closed';
	static String CASE_RECORD_TYPE_ID = Cache.getRecordTypeId('Case', 'Tax Res');
	static Set<string> set_ExcludeCases = new Set<String>{ CASE_STATUS_SOLVED, CASE_STATUS_CLOSED };
	public static String ACCOUNT_SPECIALIST = 'Account Specialist';
	public Set<Id> set_Agencies;
	public List<Case> list_Cases;

	/**
	 * @Author      : Anand Singh
	 * @Description : Constructor of the class to initialize the variable
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public RegionPODMappingTriggerHelper() {
		set_Agencies = new Set<Id>();
		list_Cases = new List<Case>();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles Before Insert Context
	 * @Parm        : List of Region_POD_mapping__c.
	 * @Return      : N/A
	 **/
	public void processBeforeInsert(List<Region_POD_mapping__c> list_RegionPodMappings) {
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles After Insert Context
	 * @Parm        : List of Region_POD_mapping__c.
	 * @Return      : N/A
	 **/
	public void processAfterInsert(List<Region_POD_mapping__c> list_RegionPodMappings) {
		//*********Create Collection ******/
		createCollectionsAfter(list_RegionPodMappings);

		//*********Prepare logic ******/
		populatePODOnCase(list_RegionPodMappings);

		// ********** Start : DML ************
		if (list_Cases?.size() > 0) {
			skipTrigger(true);
			if (Test.isRunningTest()) {
				update list_Cases;
			} else {
				ID jobID = System.enqueueJob(new BatchDML(BatchDML.Operation.UPD, list_Cases, false));
			}
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles before update Context
	 * @Parm        : List of Region_POD_mapping__c and map of Region_POD_mapping__c.
	 * @Return      : N/A
	 **/
	public void processBeforeUpdate(List<Region_POD_mapping__c> list_RegionPodMappings, Map<ID, Region_POD_mapping__c> map_RegionPodMappingsOld) {
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles after update Context
	 * @Parm        : List of Region_POD_mapping__c and map of Region_POD_mapping__c.
	 * @Return      : N/A
	 **/
	public void processAfterUpdate(List<Region_POD_mapping__c> list_RegionPodMappings, Map<ID, Region_POD_mapping__c> map_RegionPodMappingsOld) {
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Create data collections to be used across functions
	 * @Parm        : List of Region_POD_mapping__c.
	 * @Return      : N/A
	 **/
	public void createCollectionsAfter(List<Region_POD_mapping__c> list_RegionPodMappings) {
		for (Region_POD_mapping__c objPODMapping : list_RegionPodMappings) {
			if (objPODMapping.Agency__c != null) {
				set_Agencies.add(objPODMapping.Agency__c);
			}
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Populate POD on Case
	 * @Parm        : List of Region_POD_mapping__c.
	 * @Return      : N/A
	 **/
	private void populatePODOnCase(List<Region_POD_mapping__c> list_RegionPodMappingsTemp) {
		//get All the POD associated with this agencies
		if (set_Agencies?.size() > 0) {
			//get me all the open cases where this Agencies is associated
			list_Cases = [
				SELECT
					ID,
					Account_Specialist_POD__c,
					Account_Specialist__c,
					Email_Status__c,
					Status,
					Agency_Information__c,
					RecordTypeId,
					Last_out_bound_email__c,
					ContactId,
					OwnerId
				FROM Case
				WHERE RecordTypeId = :CASE_RECORD_TYPE_ID AND Status NOT IN :set_ExcludeCases AND ContactId != NULL AND Agency_Information__c != NULL AND Agency_Information__c IN :set_Agencies
			];

			if (list_Cases?.size() > 0) {
				//Get All Region POD for the Agencies
				Map<String, String> map_AgencyPODMappings = new Map<String, String>();
				for (Region_POD_mapping__c objRPD : [
					SELECT ID, Region_POD__c, Agency__c, Region_POD__r.Team__c
					FROM Region_POD_mapping__c
					WHERE Agency__c != NULL AND Agency__c IN :set_Agencies
				]) {
					String strKey = objRPD.Agency__c + '~' + objRPD.Region_POD__r.Team__c;
					map_AgencyPODMappings.put(strKey, objRPD.Region_POD__c);
				}
				for (Case objCase : list_Cases) {
					String strASKey = objCase.Agency_Information__c + '~' + ACCOUNT_SPECIALIST;

					if (map_AgencyPODMappings.containsKey(strASKey) != null) {
						objCase.Account_Specialist_POD__c = map_AgencyPODMappings.get(strASKey);
					}
				}
			}
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		EmailMessageTriggerHelper.skipTrigger = blnFlag;
		TriggerTaskDispatchClass.skipTrigger = blnFlag;
		TaskTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
	}
}