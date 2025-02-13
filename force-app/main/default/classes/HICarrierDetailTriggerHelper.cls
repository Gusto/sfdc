/*BY: PR
 * Date: May/21/2020
 * Description: This is Helper class for "HI_Carrier_Detail__c" object's apex trigger
 */
public class HICarrierDetailTriggerHelper {
	public static boolean skipTrigger = false;
	public static boolean queue = false;
	public static integer counter = 0;

	public void OnBeforeInsert(List<HI_Carrier_Detail__c> list_carrierDetails) {
	}

	public void OnAfterInsert(Map<ID, HI_Carrier_Detail__c> map_newCarrierDetails) {
	}

	public void OnBeforeUpdate(Map<ID, HI_Carrier_Detail__c> map_oldCarrierDetails, Map<ID, HI_Carrier_Detail__c> map_newCarrierDetails) {
		if (queue == true) {
			processInformation(map_newCarrierDetails.values());
		} else {
			for (HI_Carrier_Detail__c objDetail : map_newCarrierDetails.values()) {
				objDetail.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, HI_Carrier_Detail__c> map_oldCarrierDetails, Map<ID, HI_Carrier_Detail__c> map_newCarrierDetails) {
		if (queue == false) {
			HICarrierDetailQueue insertJob = new HICarrierDetailQueue(map_newCarrierDetails.values());
			ID jobID = System.enqueueJob(insertJob);
		}
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedCarrierDetails) {
	}

	public void OnBeforeDelete(HI_Carrier_Detail__c[] list_CarrierDetailsToDelete, Map<ID, HI_Carrier_Detail__c> map_oldCarrierDetails) {
		counter++;
	}

	public void OnAfterDelete(HI_Carrier_Detail__c[] list_deletedCarrierDetails, Map<ID, HI_Carrier_Detail__c> map_oldCarrierDetails) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedCarrierDetailIDs) {
	}

	public void OnUndelete(HI_Carrier_Detail__c[] list_restoredCarrierDetails) {
		counter++;
	}

	private void processInformation(List<HI_Carrier_Detail__c> list_CarrierDetails) {
		set<string> set_carrierDetailIds = new Set<string>();
		map<string, Carrier_Info__c> map_CarrierDetailIdInfoRec = new Map<string, Carrier_Info__c>();
		//BY:PR, Date: Sep/20/2020, Desc: To properly populate the name on Carrier https://app.asana.com/0/1195411211351298/1195499046602897/f
		map<string, Carrier_Info__c> map_CarrierDetailIdHIStateCarrierRec = new Map<string, Carrier_Info__c>();
		//contains HI_State_Carrier__c records with carrier_Id as key
		map<string, list<HI_State_Carrier__c>> map_CarrierIdStateCarrierRec = new Map<string, list<HI_State_Carrier__c>>();
		//maintains carrier infor Id__c & carrier_Detail field mapping
		map<string, string> map_CarrierDetailIdcarrierInfoId = new Map<string, string>();
		//contains carrier info records that we want to update
		list<Carrier_Info__c> list_toUpdateCarrierInfo = new List<Carrier_Info__c>();
		//contains HI_State_Carrier__c records that we want to update
		list<HI_State_Carrier__c> list_toUpdateStateCarrier = new List<HI_State_Carrier__c>();

		for (HI_Carrier_Detail__c objDetail : list_CarrierDetails) {
			if (objDetail.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (objDetail.Deleted_At__c != null) {
				continue;
			}

			if (string.isBlank(objDetail.Id__c)) {
				setProcessingCarrierDetails(IntegrationUtils.ERROR_STATE, 'External Id__c field can not be blank.', objDetail);
				continue;
			}

			set_carrierDetailIds.add(objDetail.Id__c);
		}

		if (set_carrierDetailIds.size() > 0) {
			map_CarrierDetailIdInfoRec = getCarrierInfoRecords(set_carrierDetailIds);
			//BY:PR, Date: Sep/20/2020, Desc: To properly populate the name on Carrier https://app.asana.com/0/1195411211351298/1195499046602897/f
			map_CarrierIdStateCarrierRec = getHIStateCarrierRecords(set_carrierDetailIds);

			set<string> set_InfoId = new Set<string>();

			if (map_CarrierDetailIdInfoRec.size() > 0) {
				for (Carrier_Info__c objInfo : map_CarrierDetailIdInfoRec.values()) {
					set_InfoId.add(objInfo.Id__c);
					map_CarrierDetailIdcarrierInfoId.put(objInfo.Carrier_Detail_Id__c, objInfo.Id__c);
				}
			}
		}

		for (HI_Carrier_Detail__c objDetail : list_CarrierDetails) {
			if (objDetail.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (objDetail.Deleted_At__c != null) {
				continue;
			}

			if (map_CarrierDetailIdInfoRec.containsKey(objDetail.Id__c)) {
				Carrier_Info__c objCarrierInfo = map_CarrierDetailIdInfoRec.get(objDetail.Id__c);
				objCarrierInfo = mapCarrierInfo(objDetail, objCarrierInfo);
				list_toUpdateCarrierInfo.add(objCarrierInfo);
			}

			//BY:PR, Date: Sep/20/2020, Desc: To properly populate the name on Carrier https://app.asana.com/0/1195411211351298/1195499046602897/f
			if (map_CarrierIdStateCarrierRec.containsKey(objDetail.Id__c)) {
				list_toUpdateStateCarrier.addAll(map_CarrierIdStateCarrierRec.get(objDetail.Id__c));
			}
		}

		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
		if (list_toUpdateCarrierInfo.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(list_toUpdateCarrierInfo, Carrier_Info__c.Fields.Id__c, false);
			dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, list_toUpdateCarrierInfo, 'Carrier_Detail_Id__c', true, 'HICarrierDetailTriggerHelper-processInformation');
		}

		//BY:PR, Date: Sep/20/2020, Desc: moved the loop out side of upsert list to update the process status properly
		for (HI_Carrier_Detail__c objDetail : list_CarrierDetails) {
			string strCarrierInfoId = '';
			strCarrierInfoId = map_CarrierDetailIdcarrierInfoId.containsKey(objDetail.Id__c) ? map_CarrierDetailIdcarrierInfoId.get(objDetail.Id__c) : '';

			if (string.isNotBlank(strCarrierInfoId) && dmlUpsertErrorsMap.containsKey(strCarrierInfoId)) {
				setProcessingCarrierDetails(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(objDetail.Id__c), objDetail);
			} else {
				setProcessingCarrierDetails(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', objDetail);
			}
		}

		if (list_toUpdateStateCarrier.size() > 0) {
			update list_toUpdateStateCarrier;
		}
	}

	//mapping Carrier Info records with related HI Carrier Detail record
	public Carrier_Info__c mapCarrierInfo(HI_Carrier_Detail__c objDetail, Carrier_Info__c objCarrierInfo) {
		objCarrierInfo.Name = objDetail.Name__c;
		objCarrierInfo.Address_Addressed_To__c = objDetail.Address_Addressed_To__c;
		objCarrierInfo.Address_City__c = objDetail.Address_City__c;
		objCarrierInfo.Address_State__c = objDetail.Address_State__c;
		objCarrierInfo.Address_Street__c = objDetail.Address_Street__c;
		objCarrierInfo.Address_Zip__c = objDetail.Address_Zip__c;
		objCarrierInfo.Customer_Support__c = IntegrationUtils.getJsonParsedMap(objDetail.Customer_Support__c, 'default');
		objCarrierInfo.Email__c = objDetail.Email__c;
		objCarrierInfo.Lidi_Census_Email__c = objDetail.Lidi_Census_Email__c;
		objCarrierInfo.Min_Eligible_Employees_Required__c = objDetail.Min_Eligible_Employees_Required__c;
		objCarrierInfo.Qualifying_Life_Event_Requirements__c = objDetail.Qualifying_Life_Event_Requirements__c;
		objCarrierInfo.Sell_Description__c = objDetail.Sell_Description__c;
		return objCarrierInfo;
	}

	// populating HI_Carrier_Detail__c object fields
	private HI_Carrier_Detail__c setProcessingCarrierDetails(String ProcessingState, String message, HI_Carrier_Detail__c carrierDetail) {
		carrierDetail.Processing_State__c = ProcessingState;
		carrierDetail.Message__c = message;
		carrierDetail.Last_Processed__c = System.now();
		return carrierDetail;
	}

	public map<string, Carrier_Info__c> getCarrierInfoRecords(set<string> set_CarrierDetailsIds) {
		map<string, Carrier_Info__c> map_CarrierDetailIdInfoRec = new Map<string, Carrier_Info__c>();
		if (set_CarrierDetailsIds != null && set_CarrierDetailsIds.size() > 0) {
			for (Carrier_Info__c objInfo : [SELECT Id, Id__c, Carrier_Detail_Id__c FROM Carrier_Info__c WHERE Carrier_Detail_Id__c IN :set_CarrierDetailsIds]) {
				map_CarrierDetailIdInfoRec.put(objInfo.Carrier_Detail_Id__c, objInfo);
			}
		}

		return map_CarrierDetailIdInfoRec;
	}

	//BY:PR, Date: Sep/20/2020, Desc: moved mapping and filter from Carrier_Id__c to Carrier_Detail_Id__c
	public map<string, list<HI_State_Carrier__c>> getHIStateCarrierRecords(set<string> set_CarrierIds) {
		map<string, list<HI_State_Carrier__c>> map_CarrierIdStateCarrierRec = new Map<string, list<HI_State_Carrier__c>>();
		if (set_CarrierIds != null && set_CarrierIds.size() > 0) {
			for (HI_State_Carrier__c objState : [SELECT Id, Carrier_Id__c, Carrier_Detail_Id__c FROM HI_State_Carrier__c WHERE Carrier_Detail_Id__c IN :set_CarrierIds]) {
				list<HI_State_Carrier__c> list_HIStateCarrier = new List<HI_State_Carrier__c>();

				if (map_CarrierIdStateCarrierRec.containsKey(objState.Carrier_Detail_Id__c)) {
					list_HIStateCarrier = map_CarrierIdStateCarrierRec.get(objState.Carrier_Detail_Id__c);
				}
				list_HIStateCarrier.add(objState);
				map_CarrierIdStateCarrierRec.put(objState.Carrier_Detail_Id__c, list_HIStateCarrier);
			}
		}

		return map_CarrierIdStateCarrierRec;
	}
}