/**
 * @name         UpdateCarrierPlayInfoCtrl
 * @author       Omar Benitez
 * @date         17th Sep 2024
 * @description  Controller Class for LWC carrierUpdatePlayInfoCmp
 **/
public without sharing class UpdateCarrierPlayInfoCtrl {

	public static final String CARRIERS = 'carriers';
	public static final String MAP_CARRIERS_UNIQ_NAME = 'map_CarrierUniqueName';
	public static final String MAP_ALL_CARRIER_PLAY_INFO = 'map_AllCarrierPlayInfo';
	public static final String MAP_CARRIER_PLAY_INFO = 'map_CarrierPlayInfo';


	/*
	 * Fetch all Carriers and arrange them based on unique Name
	 */
	@AuraEnabled
	public static Map<String, Object> fetchCarriers() {
		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Map<String, Object> map_returnObj = new Map<String, Object>();
		list_Carriers = [SELECT Carrier_Unique_Name__c, State__c FROM Carrier__c WHERE State__c != NULL AND ID__c != NULL ORDER BY Carrier_Unique_Name__c ASC LIMIT 50000];
		List<String> list_CarrierUniqueName = new List<String>();
		Map<String, List<Carrier__c>> map_CarrierUniqueNameMap = new Map<String, List<Carrier__c>>();
		//Segregate Carriers based on Unique Name
		for (Carrier__c objCarrier : list_Carriers) {
			List<Carrier__c> list_CarrierRecByName;
			if (map_CarrierUniqueNameMap.containsKey(objCarrier.Carrier_Unique_Name__c)) {
				list_CarrierRecByName = map_CarrierUniqueNameMap.get(objCarrier.Carrier_Unique_Name__c);
			} else {
				list_CarrierRecByName = new List<Carrier__c>();
				//Add Carrier Name to show in Picklist
				list_CarrierUniqueName.add(objCarrier.Carrier_Unique_Name__c);
			}
			list_CarrierRecByName.add(objCarrier);
			map_CarrierUniqueNameMap.put(objCarrier.Carrier_Unique_Name__c, list_CarrierRecByName);
		}
		map_returnObj.put(CARRIERS, list_CarrierUniqueName);
		map_returnObj.put(MAP_CARRIERS_UNIQ_NAME, map_CarrierUniqueNameMap);
		return map_returnObj;
	}

	/*
	 * Fetch Carrier Play Info records based on based on selected carrier
	 */
	@AuraEnabled
	public static Map<String, Object> fetchCarrierPlayInfo(List<Id> list_CarrierIds) {
		Map<String, Object> map_response = new Map<String, Object>();
		Map<String, List<Carrier_Play_Information__c>> map_AllCarrierPlayInfo = new Map<String, List<Carrier_Play_Information__c>>();
		Map<String, Carrier_Play_Information__c> map_CarrierPlayInfo = new Map<String, Carrier_Play_Information__c>();

		List<Carrier_Play_Information__c> list_CarrierPlayInfo = new List<Carrier_Play_Information__c>();

		//Fetch Carrier Play Info Records
		list_CarrierPlayInfo = [
			SELECT Carrier__c, Carrier__r.Name, Carrier__r.Carrier_Unique_Name__c, Carrier__r.State__c, To__c, From__c, Event_Type__c, Play_Mode_Type__c, Before_After__c, Number_Of_Days__c
			FROM Carrier_Play_Information__c
			WHERE Carrier__c IN :list_CarrierIds
			LIMIT 50000
		];
		//arrange carrier play info records based on various fields like PlayModeType, EventType etc.
		for (Carrier_Play_Information__c objCarrierPlayInfo : list_CarrierPlayInfo) {
			String strKey = objCarrierPlayInfo.Event_Type__c + objCarrierPlayInfo.Play_Mode_Type__c + objCarrierPlayInfo.Before_After__c + objCarrierPlayInfo.From__c + objCarrierPlayInfo.To__c;
			List<Carrier_Play_Information__c> list_CPI;
			if (map_AllCarrierPlayInfo.containsKey(strKey)) {
				list_CPI = map_AllCarrierPlayInfo.get(strKey);
			} else {
				list_CPI = new List<Carrier_Play_Information__c>();
				//Add 1 record for each combination to the placeholder list of Carrier Play Info which is used to record user input
				Carrier_Play_Information__c objCarrierPInfo = new Carrier_Play_Information__c(
					From__c = objCarrierPlayInfo.From__c,
					Id = objCarrierPlayInfo.Id,
					To__c = objCarrierPlayInfo.To__c,
					Before_After__c = objCarrierPlayInfo.Before_After__c,
					Event_Type__c = objCarrierPlayInfo.Event_Type__c,
					Play_Mode_Type__c = objCarrierPlayInfo.Play_Mode_Type__c,
					Number_Of_Days__c = objCarrierPlayInfo.Number_Of_Days__c
				);
				map_CarrierPlayInfo.put(strKey, objCarrierPInfo);
			}
			list_CPI.add(objCarrierPlayInfo);

			map_AllCarrierPlayInfo.put(strKey, list_CPI);
		}
		map_response.put(MAP_ALL_CARRIER_PLAY_INFO, map_AllCarrierPlayInfo);
		map_response.put(MAP_CARRIER_PLAY_INFO, map_CarrierPlayInfo);
		return map_response;
	}
	/*
	 * Save Carrier Play Info
	 */
	@AuraEnabled
	public static void saveCarrierPlayInfo(List<Carrier_Play_Information__c> list_CarrierPlayInfoToUpdate) {
		try {
			update list_CarrierPlayInfoToUpdate;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}