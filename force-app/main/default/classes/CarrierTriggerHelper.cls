/**
 * @name         CarrierTriggerHelper
 * @author       Neha Dabas
 * @date         11 May 2020
 * @description  Helper class to execute trigger events for CarrierTrigger
 * @test class   UpdateCarrierPlayInformationCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class CarrierTriggerHelper {
	public static Boolean skipTrigger = false;

	public void onBeforeInsert(List<Carrier__c> list_NewCarriers) {
		if (list_NewCarriers == null || list_NewCarriers.isEmpty()) {
			return;
		}
		setDefaultFieldsValue(list_NewCarriers, null);
	}

	public void onBeforeUpdate(List<Carrier__c> list_NewCarriers, Map<Id, Carrier__c> map_OldCarriers) {
		if (list_NewCarriers == null || list_NewCarriers.isEmpty()) {
			return;
		}

		setDefaultFieldsValue(list_NewCarriers, map_OldCarriers);
	}

	/*
	 * After Insert
	 */
	public void OnAfterInsert(List<Carrier__c> list_NewCarriers, Map<Id, Carrier__c> map_NewCarriers) {
		if (map_NewCarriers == null || map_NewCarriers.isEmpty()) {
			return;
		}
		insertCarrierPlayInformationRecords(map_NewCarriers.keySet());
	}
	/*
	 * Author       :   Neha Dabas, 10th May 2020
	 * Description  :   Insert Carrier Play Information records for each carrier on insert, using default values specified in custom setting
	 */
	public void insertCarrierPlayInformationRecords(Set<Id> set_CarrierIds) {
		if (set_CarrierIds == null || set_CarrierIds.isEmpty()) {
			return;
		}
		//fetch Carrier Play Info Defaults
		Map<String, Carrier_Play_Information_Defaults__c> map_CarrierPlayDefaults = Carrier_Play_Information_Defaults__c.getAll();

		if (map_CarrierPlayDefaults != null && !map_CarrierPlayDefaults.isEmpty()) {
			//Create Carrier Play Info record for each Carrier based on default settings
			List<Carrier_Play_Information__c> list_carrierPlayInfo = new List<Carrier_Play_Information__c>();

			for (Id id_Carrier : set_CarrierIds) {
				for (Carrier_Play_Information_Defaults__c objDefaultVal : map_CarrierPlayDefaults.values()) {
					list_carrierPlayInfo.add(
						new Carrier_Play_Information__c(
							Carrier__c = id_Carrier,
							From__c = objDefaultVal.From__c,
							To__c = objDefaultVal.To__c,
							Before_After__c = objDefaultVal.Before_After__c,
							Event_Type__c = objDefaultVal.Event_Type__c,
							Play_Mode_Type__c = objDefaultVal.Play_Mode_Type__c,
							Number_Of_Days__c = objDefaultVal.Number_Of_Days__c
						)
					);
				}
			}

			if (!list_carrierPlayInfo.isEmpty()) {
				//BatchDML.Operation e = BatchDML.Operation.INS;

				//ID jobID = System.enqueueJob(new BatchDML(e, list_carrierPlayInfo));
				insert list_carrierPlayInfo;
			}
		}
	}

	public void setDefaultFieldsValue(List<Carrier__c> list_NewCarriers, Map<Id, Carrier__c> map_OldCarriers) {
		List<Group> list_Groups = GlobalQueryHelper.getGroupsByName(CarrierOrderUtil.CARRIER_ORDER_QUEUE);
		for (Carrier__c objCarrier : list_NewCarriers) {
			if (map_OldCarriers != null && !map_OldCarriers.isEmpty() && map_OldCarriers.containsKey(objCarrier.Id)) {
				Carrier__c objOldCarrier = map_OldCarriers.get(objCarrier.Id);
				if (String.isBlank(objOldCarrier.Carrier_Unique_Name__c)) {
					objCarrier.Carrier_Unique_Name__c = objCarrier.Name;
				}
			} else {
				objCarrier.Submission_BOR_Assignment__c = true;
				objCarrier.Group_Submission_Event__c = CarrierOrderUtil.BEFORE_MONTH;
				objCarrier.Group_Variation_Number__c = 10;
				objCarrier.Member_Submission_Event__c = CarrierOrderUtil.BEFORE_MONTH;
				objCarrier.Member_Variation_Number__c = 15;
				objCarrier.New_Plan_Submission_Event__c = CarrierOrderUtil.BEFORE_MONTH;
				objCarrier.New_Plan_Variation_Num1__c = 15;
                objCarrier.Carrier_Unique_Name__c = objCarrier.Name;
				if (!list_Groups.isEmpty())
					objCarrier.OwnerId = list_Groups[0].Id;
			}
		}
	}
}