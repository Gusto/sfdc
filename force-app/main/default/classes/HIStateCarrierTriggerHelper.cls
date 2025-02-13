public with sharing class HIStateCarrierTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer counter = 0;
	public static Boolean queue = false;

	public void OnBeforeInsert(List<HI_State_Carrier__c> list_StateCarriers) {
		counter++;
		processInformation(list_StateCarriers);
	}

	public void OnBeforeUpdate(Map<ID, HI_State_Carrier__c> map_OldStateCarrier, Map<ID, HI_State_Carrier__c> map_NewStateCarrier) {
		counter++;
		processInformation(map_NewStateCarrier.values());
	}

	//BY:PR, Date: Sep/20/2020, Desc: introduced third parameter and update name from HI_Carrier_Detail__c
	public Carrier__c mapStateCarrierInfo(HI_State_Carrier__c objHiStateCarrier, Carrier_Info__c objCarrierInfo, HI_Carrier_Detail__c objCarrierDetail) {
		Carrier__c objCarrier = new Carrier__c();
		objCarrier.Key__c = objHiStateCarrier.Key__c;
		if (objCarrierDetail != null) {
			objCarrier.Name = objCarrierDetail.Name__c;
			objCarrier.Carrier_Unique_Name__c = objCarrierDetail.Name__c;
		}

		objCarrier.Id__c = objHiStateCarrier.Id__c;
		objCarrier.State__c = objHiStateCarrier.State__c;
		objCarrier.Carrier_Info__c = objCarrierInfo.Id;
		objCarrier.Carrier_Id__c = objCarrierInfo.Id__c;
		return objCarrier;
	}

	private void processInformation(List<HI_State_Carrier__c> list_StateCarrier) {
		Set<String> set_CarrierID = new Set<String>();
		Set<String> set_CarrierDetailId = new Set<String>();
		List<Carrier__c> list_ToUpsertCarrier = new List<Carrier__c>();

		for (HI_State_Carrier__c objStateCarrier : list_StateCarrier) {
			if (objStateCarrier.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (string.isNotBlank(objStateCarrier.Carrier_Id__c)) {
				set_CarrierID.add(objStateCarrier.Carrier_Id__c);
			}

			if (string.isNotBlank(objStateCarrier.Carrier_Detail_Id__c)) {
				set_carrierDetailId.add(objStateCarrier.Carrier_Detail_Id__c);
			}
		}

		map<String, Carrier_Info__c> map_CarrierInfo = getCarrierInfoData(set_CarrierID);
		Map<String, HI_Carrier_Detail__c> map_CarrierDetailIdHICarrierDetail = new Map<String, HI_Carrier_Detail__c>();
		if (set_CarrierDetailId.size() > 0) {
			map_CarrierDetailIdHICarrierDetail = getCarrierDetailData(set_CarrierDetailId);
		}

		for (HI_State_Carrier__c objHiStateCarrier : list_StateCarrier) {
			if (objHiStateCarrier.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (objHiStateCarrier.Carrier_Id__c == null || objHiStateCarrier.Carrier_Id__c == '') {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, 'HI Carrier Id: field value is missing in the record.', objHiStateCarrier);
				continue;
			}

			if (!map_CarrierInfo.containsKey(objHiStateCarrier.Carrier_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, 'Carrier Info does not exist.', objHiStateCarrier);
				continue;
			}

			Carrier__c objToUpsertCarrierRec = mapStateCarrierInfo(
				objHiStateCarrier,
				map_CarrierInfo.get(objHiStateCarrier.Carrier_Id__c),
				map_CarrierDetailIdHICarrierDetail.get(objHiStateCarrier.Carrier_Detail_Id__c)
			);
			list_ToUpsertCarrier.add(objToUpsertCarrierRec);
		}

		Map<String, String> map_DMLUpsertErrors = new Map<String, String>();
		if (list_ToUpsertCarrier.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(list_ToUpsertCarrier, Carrier__c.Fields.Key__c, false);
			map_DMLUpsertErrors = Utils.processUpsertResult(saveResult, list_ToUpsertCarrier, 'Key__c', true, 'HIStateCarrierTriggerHelper-processInformation');

			for (HI_State_Carrier__c objHiStateCarrier : list_StateCarrier) {
				if (map_DMLUpsertErrors.containsKey(objHiStateCarrier.Key__c)) {
					setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, map_DMLUpsertErrors.get(objHiStateCarrier.Key__c), objHiStateCarrier);
				} else {
					setProcessingStateCarrier(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', objHiStateCarrier);
				}
			}
		}
	}

	// querying carrier object records present in the org using ID__c field
	private Map<String, Carrier_Info__c> getCarrierInfoData(Set<String> set_CarrierID) {
		Map<String, Carrier_Info__c> map_ToReturnIdCarrierRec = new Map<String, Carrier_Info__c>();

		if (set_CarrierID != null && set_CarrierID.size() > 0) {
			for (Carrier_Info__c objCarrier : [SELECT Id, Id__c, Name FROM Carrier_Info__c WHERE Id__c IN :set_CarrierID]) {
				map_ToReturnIdCarrierRec.put(objCarrier.Id__c, objCarrier);
			}
		}
		return map_ToReturnIdCarrierRec;
	}

	//BY:PR, Date: Sep/20/2020, Desc:  querying HI_Carrier_Detail__c object records present in the org using ID__c field
	private Map<String, HI_Carrier_Detail__c> getCarrierDetailData(Set<String> set_carrierDetailIds) {
		Map<String, HI_Carrier_Detail__c> map_ToReturnIdCarrierDetailRec = new Map<String, HI_Carrier_Detail__c>();

		if (set_carrierDetailIds != null && set_carrierDetailIds.size() > 0) {
			for (HI_Carrier_Detail__c objCarrier : [SELECT Id, Id__c, Name__c FROM HI_Carrier_Detail__c WHERE Id__c IN :set_carrierDetailIds AND Id__c != NULL]) {
				map_ToReturnIdCarrierDetailRec.put(objCarrier.Id__c, objCarrier);
			}
		}
		return map_ToReturnIdCarrierDetailRec;
	}

	// populating HI_State_carrier__c object fields
	private HI_State_Carrier__c setProcessingStateCarrier(String strProcessingState, String strmessage, HI_State_Carrier__c objStateCarrier) {
		objStateCarrier.Processing_State__c = strProcessingState;
		objStateCarrier.Message__c = strmessage;
		objStateCarrier.Last_Processed__c = System.now();
		return objStateCarrier;
	}
}