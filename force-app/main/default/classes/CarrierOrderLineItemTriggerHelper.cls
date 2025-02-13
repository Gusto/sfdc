/*
    BY: AKS
    Date: Jan 22, 2020
    Desc: This class is used as a helper/util class for [Carrier_Order_Line_Item__c] object [CarrierOrderLineItemTrigger.trigger] trigger component.
*/
public class CarrierOrderLineItemTriggerHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	private List<Carrier_Order_Line_Item__c> list_NewRecords;
	private List<Carrier_Order_Line_Item__c> list_OldRecords;
	private Map<Id, Carrier_Order_Line_Item__c> map_NewRecords;
	private Map<Id, Carrier_Order_Line_Item__c> map_OldRecords;

	Set<string> set_ToExcludeOrderStatus = new Set<String>{ 'Canceled', 'Closed Lost', 'Closed Admin', 'Fulfilled' };
	//to make sure that we update carrier order only once from the trigger helper this map manages the modified 'carrier order' records
	Map<string, Carrier_Order__c> map_CarrierOrderIdCORecord = new Map<string, Carrier_Order__c>();
	//to update carrier order only once from the trigger helper this map manages the modified 'Benefit order' records
	Map<string, Benefit_Order__c> map_BenefitOrderIdBORecord = new Map<string, Benefit_Order__c>();
	//using below set to contains BO and
	Set<id> set_benefitOrderId = new Set<Id>();
	//set contains status values for CO we are considering as void
	Set<string> set_COExclude = new Set<string>{ 'Canceled', 'Closed Admin'};
	Set<String> set_BOsBORType = new Set<string>{ BenefitOrderUtil.BO_ORDER_TYPE_BOR, BenefitOrderUtil.BO_ORDER_TYPE_BOR_AND_TADA, BenefitOrderUtil.BO_ORDER_TYPE_BOR_TADA_ONLY };

	public CarrierOrderLineItemTriggerHelper() {
		super('CarrierOrderLineItemTriggerHelper');
		this.list_NewRecords = (List<Carrier_Order_Line_Item__c>) Trigger.new;
		this.list_OldRecords = (List<Carrier_Order_Line_Item__c>) Trigger.old;
		this.map_NewRecords = (Map<Id, Carrier_Order_Line_Item__c>) Trigger.newMap;
		this.map_OldRecords = (Map<Id, Carrier_Order_Line_Item__c>) Trigger.oldMap;
	}

	public override void afterInsert() {
		createCheckListForBTCarrierOrderLineItems(map_NewRecords.values()); //1
		syncRenewalDateBenefitType(map_NewRecords.values(), null); //2

		//always call these two methods in the end
		updateCarrierOrderWithTriggerSkip();
		updateBenefitOrderWithTriggerSkip();
	}

	public override void afterUpdate() {
		calculateNonTADAChecklistDocuments(list_NewRecords, map_OldRecords);
		syncRenewalDateBenefitType(list_NewRecords, map_OldRecords);

		//always call these two methods in the end
		updateCarrierOrderWithTriggerSkip();
		updateBenefitOrderWithTriggerSkip();
	}

	public override void afterDelete() {
		syncRenewalDateBenefitType(list_OldRecords, null);

		//always call these two methods in the end
		updateCarrierOrderWithTriggerSkip();
		updateBenefitOrderWithTriggerSkip();
	}

	/* Calculate Non TADA Checklist Documents i.e. Number Of Collected Documents & Total Number Of Documents */
	public void calculateNonTADAChecklistDocuments(List<Carrier_Order_Line_Item__c> list_newCarrierOrderLineItem, Map<ID, Carrier_Order_Line_Item__c> map_OldCarrierOrderLineItem) {
		List<Carrier_Order_Line_Item__c> list_CarrierOrderLineItems = new List<Carrier_Order_Line_Item__c>();
		Set<id> set_CarrierOrderIds = new Set<id>();

		List<Benefit_Order__c> list_NewBenefitOrder = new List<Benefit_Order__c>();

		// Checking the oldCarrierOrderLineItem and (Number_Of_Collected_Documents__c, Total_Number_Of_Documents__c fields) are null or not
		for (Carrier_Order_Line_Item__c objCarrierOrderLineItem : list_newCarrierOrderLineItem) {
			Carrier_Order_Line_Item__c oldCarrierOrderLineItem = map_OldCarrierOrderLineItem.get(objCarrierOrderLineItem.Id);
			if (
				(objCarrierOrderLineItem.Number_Of_Collected_Documents__c != null &&
				objCarrierOrderLineItem.Number_Of_Collected_Documents__c != oldCarrierOrderLineItem.Number_Of_Collected_Documents__c) ||
				(objCarrierOrderLineItem.Total_Number_Of_Documents__c != null &&
				objCarrierOrderLineItem.Total_Number_Of_Documents__c != oldCarrierOrderLineItem.Total_Number_Of_Documents__c)
			) {
				set_CarrierOrderIds.add(objCarrierOrderLineItem.Carrier_Order__c);
			}
		}
		if (!set_CarrierOrderIds.isEmpty()) {
			List<Carrier_Order__c> list_NewCarrierOrder = new List<Carrier_Order__c>();
			set_benefitOrderId = new Set<Id>();

			// Storing  the sum of Number_Of_Collected_Documents__c and Total_Number_Of_Documents__c of Carrier_Order_Line_Item
			for (AggregateResult agg : [
				SELECT sum(Number_Of_Collected_Documents__c) collectedNO, sum(Total_Number_Of_Documents__c) TotalNO, Carrier_Order__c, Carrier_Order__r.Benefit_Order__c boId
				FROM Carrier_Order_Line_Item__c
				WHERE Carrier_Order__c IN :set_CarrierOrderIds AND Carrier_Order__r.Implementation_Stage__c != 'Canceled'
				GROUP BY Carrier_Order__c, Carrier_Order__r.Benefit_Order__c
			]) {
				set_benefitOrderId.add((string) agg.get('boId'));
				Carrier_Order__c objTempCO = new Carrier_Order__c(Id = (string) agg.get('Carrier_Order__c'));
				objTempCO.Number_Of_Collected_Documents__c = (decimal) agg.get('collectedNO');
				objTempCO.Total_Number_Of_Documents__c = (decimal) agg.get('TotalNO');
				map_CarrierOrderIdCORecord.put(objTempCO.Id, objTempCO);
			}
		}
	} // End of Method

	void updateBOCollectingDocumentsCounts() {
		// Storing Number_Of_Collected_Documents and Total_Number_Of_Documents fields on Benefit_Order, except for Carrier_Order.Implementation_Stage is cancelled
		if (set_benefitOrderId != null && set_benefitOrderId.size() > 0) {
			for (AggregateResult agg : [
				SELECT sum(Number_Of_Collected_Documents__c) collectedNO, sum(Total_Number_Of_Documents__c) TotalNO, Benefit_Order__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c IN :set_benefitOrderId AND Implementation_Stage__c != 'Canceled'
				GROUP BY Benefit_Order__c
			]) {
				Benefit_Order__c objTempCO = new Benefit_Order__c(Id = (string) agg.get('Benefit_Order__c'));
				objTempCO.Number_Of_Collected_Documents__c = (decimal) agg.get('collectedNO');
				objTempCO.Total_Number_Of_Documents__c = (decimal) agg.get('TotalNO');
				map_BenefitOrderIdBORecord.put(objTempCO.Id, objTempCO);
			}
			set_benefitOrderId = new Set<Id>();
		}
	}

	/**BY: PR, Date:Jan/29/2019, Desc: this method syncs "latest Renewal Date" to related CO and BO on 'Carrier Line Item' record insert and
	 on change of the 'Renewal Date' field val*/
	private void syncRenewalDateBenefitType(List<Carrier_Order_Line_Item__c> list_newCarrierOrderLineItem, Map<ID, Carrier_Order_Line_Item__c> map_OldCarrierOrderLineItem) {
		if (list_newCarrierOrderLineItem.size() > 0) {
			set<string> set_COIds = new Set<string>();

			for (Carrier_Order_Line_Item__c objLI : list_newCarrierOrderLineItem) {
				Carrier_Order_Line_Item__c objOldLI;
				if (map_OldCarrierOrderLineItem != null && map_OldCarrierOrderLineItem.size() > 0 && map_OldCarrierOrderLineItem.ContainsKey(objLI.Id)) {
					objOldLI = map_OldCarrierOrderLineItem.get(objLI.Id);
				}

				set_COIds.add(objLI.Carrier_Order__c);
			}

			List<Carrier_Order_Line_Item__c> list_LITemp = new List<Carrier_Order_Line_Item__c>();
			Set<String> set_BOIds = new Set<string>();
			Map<string, Carrier_Order__c> map_COIdCoRecord = new Map<String, Carrier_Order__c>();
			Map<string, Benefit_Order__c> map_BOIdBORecord = new Map<String, Benefit_Order__c>();
			List<Carrier_Order__c> lst_toUpdateCarrierOrder = new List<Carrier_Order__c>();

			//following map maintains the "carrier order" and Group number relationship
			Map<string, string> map_CarrierOrderGroupNumber = new Map<string, string>();
			//loop on 'carrier order Line Item' to calculate 'latest renewal date' for related CO
			for (Carrier_Order_Line_Item__c objLI : [
				SELECT Id, Carrier_Order__c, Carrier_Order__r.Benefit_Order__c, Renewal_Date__c, Benefit_Types__c, Carrier_Order__r.Implementation_Stage__c, Group_Number__c
				FROM Carrier_Order_Line_Item__c
				WHERE Carrier_Order__c IN :set_COIds
			]) {
				if (set_COExclude.contains(objLI.Carrier_Order__r.Implementation_Stage__c)) {
					set_BOIds.add(objLI.Carrier_Order__r.Benefit_Order__c);
					continue;
				}

				Date dt_LatestRenewal = objLI.Renewal_Date__c;
				if (map_COIdCoRecord.containsKey(objLI.Carrier_Order__c) && (map_COIdCoRecord.get(objLI.Carrier_Order__c).Renewal_Date__c < dt_LatestRenewal || dt_LatestRenewal == null)) {
					dt_LatestRenewal = map_COIdCoRecord.get(objLI.Carrier_Order__c).Renewal_Date__c;
				}

				String strBType;
				if (map_COIdCoRecord.containsKey(objLI.Carrier_Order__c)) {
					strBType = map_COIdCoRecord.get(objLI.Carrier_Order__c).Benefit_Types__c;
				}

				if (String.isBlank(strBType)) {
					strBType = objLI.Benefit_Types__c;
				} else if (strBType.IndexOf(objLI.Benefit_Types__c) < 0) {
					strBType = strBType + ';' + objLI.Benefit_Types__c;
				}

				if (String.isNotBlank(objLI.Group_Number__c)) {
					map_CarrierOrderGroupNumber.put(objLI.Carrier_Order__c, objLI.Group_Number__c);
				}

				map_COIdCoRecord.put(objLI.Carrier_Order__c, new Carrier_Order__c(id = objLI.Carrier_Order__c, Renewal_Date__c = dt_LatestRenewal, Benefit_Types__c = strBType));
				set_BOIds.add(objLI.Carrier_Order__r.Benefit_Order__c);
			} //for ends

			//once loop has ended if we have matching "Carrier Order" records we want to map correct "Group Number" values
			if (map_CarrierOrderGroupNumber.size() > 0) {
				for (String strCOId : map_CarrierOrderGroupNumber.keyset()) {
					if (map_COIdCoRecord.containsKey(strCOId)) {
						map_COIdCoRecord.get(strCOId).Group_Number__c = map_CarrierOrderGroupNumber.get(strCOId);
					}
				}
			}

			Map<String, Integer> map_NONTadaBOIdCount = new Map<String, Integer>();
			Set<String> set_TadaBOId = new Set<String>();

			//loop on 'carrier order' to calculate 'latest renewal date' for related BO
			for (Carrier_Order__c objCo : [
				SELECT Id, Renewal_Date__c, Benefit_Order__c, Benefit_Types__c, Carrier__r.Name, Carrier__r.Partner_Type__c, Group_Number__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c IN :set_BOIds AND Implementation_Stage__c NOT IN :set_COExclude
			]) {
				date dt_LatestRenewal = null;

				if (map_COIdCoRecord.containsKey(objCo.Id)) {
					dt_LatestRenewal = map_COIdCoRecord.get(objCo.Id).Renewal_Date__c;
				} else {
					dt_LatestRenewal = objCo.Renewal_Date__c;
				}
				if (map_BOIdBORecord.containsKey(objCo.Benefit_Order__c) && (map_BOIdBORecord.get(objCo.Benefit_Order__c).Renewal_Date__c < dt_LatestRenewal || dt_LatestRenewal == null)) {
					dt_LatestRenewal = map_BOIdBORecord.get(objCo.Benefit_Order__c).Renewal_Date__c;
				}
				if (objCo.Carrier__r.Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA) {
					set_TadaBOId.add(objCo.Benefit_Order__c);
				} else {
					integer intCount = 0;
					if (map_NONTadaBOIdCount.containsKey(objCo.Benefit_Order__c)) {
						intCount = map_NONTadaBOIdCount.get(objCo.Benefit_Order__c);
					}
					intCount++;
					map_NONTadaBOIdCount.put(objCo.Benefit_Order__c, intCount);
				}
				map_BOIdBORecord.put(objCo.Benefit_Order__c, new Benefit_Order__c(id = objCo.Benefit_Order__c, Renewal_Date__c = dt_LatestRenewal));
			} //for ends

			if (map_COIdCoRecord.values().size() > 0) {
				for (String idCO : map_COIdCoRecord.keyset()) {
					if (map_CarrierOrderIdCORecord.containsKey(idCO)) {
						map_CarrierOrderIdCORecord.get(idCO).Renewal_Date__c = map_COIdCoRecord.get(idCO).Renewal_Date__c;
						map_CarrierOrderIdCORecord.get(idCO).Benefit_Types__c = map_COIdCoRecord.get(idCO).Benefit_Types__c;
						map_CarrierOrderIdCORecord.get(idCO).Group_Number__c = map_COIdCoRecord.get(idCO).Group_Number__c;
					} else {
						map_CarrierOrderIdCORecord.put(idCO, map_COIdCoRecord.get(idCO));
					}
				}
			}

			if (map_BOIdBORecord.values().size() > 0) {
				for (String idBO : map_BOIdBORecord.keyset()) {
					String strOrderType;
					if (set_TadaBOId.contains(idBO) && map_NONTadaBOIdCount.containsKey(idBO)) {
						strOrderType = 'BOR + TAdA';
					}
					if (set_TadaBOId.contains(idBO) && !map_NONTadaBOIdCount.containsKey(idBO)) {
						strOrderType = 'BOR TAdA Only';
					}
					if (!set_TadaBOId.contains(idBO) && map_NONTadaBOIdCount.containsKey(idBO)) {
						strOrderType = 'BOR';
					}

					if (map_BenefitOrderIdBORecord.containsKey(idBO)) {
						map_BenefitOrderIdBORecord.get(idBO).Renewal_Date__c = map_BOIdBORecord.get(idBO).Renewal_Date__c;
						map_BenefitOrderIdBORecord.get(idBO).Type__c = strOrderType;
						map_BenefitOrderIdBORecord.get(idBO).No_Of_TADA_Carrier_Order__c = (set_TadaBOId.contains(idBO) ? 1 : 0);
						map_BenefitOrderIdBORecord.get(idBO).No_Of_Non_TADA_Carrier_Order__c = (map_NONTadaBOIdCount.containsKey(idBO) ? map_NONTadaBOIdCount.get(idBO) : 0);
					} else {
						map_BOIdBORecord.get(idBO).Type__c = strOrderType;
						map_BOIdBORecord.get(idBO).No_Of_TADA_Carrier_Order__c = (set_TadaBOId.contains(idBO) ? 1 : 0);
						map_BOIdBORecord.get(idBO).No_Of_Non_TADA_Carrier_Order__c = (map_NONTadaBOIdCount.containsKey(idBO) ? map_NONTadaBOIdCount.get(idBO) : 0);
						map_BOIdBORecord.get(idBO).Renewal_Date__c = map_BOIdBORecord.get(idBO).Renewal_Date__c;
						map_BenefitOrderIdBORecord.put(idBO, map_BOIdBORecord.get(idBO));
					}
				}
			}
		}
	}

	//method to update "Carrier order"
	public void updateCarrierOrderWithTriggerSkip() {
		if (map_CarrierOrderIdCORecord.size() > 0) {
			boolean blnPreviousValue = CarrierOrderTriggerHelper.skipTrigger;
			Boolean blnSkipBOTrigger = true;
			if (!HICarrierInformationTriggerHelper.isBOInsert) {
				CarrierOrderTriggerHelper.skipTrigger = true;
			}

			try {
				update map_CarrierOrderIdCORecord.values();
				updateBOCollectingDocumentsCounts();

				List<Benefit_Order__c> list_toAssignOwnerEligibleBO = new List<Benefit_Order__c>();
				Set<Id> set_BOIds = new Set<Id>();

				for (String strBOId : map_BenefitOrderIdBORecord.keySet()) {
					set_BOIds.add(strBOId);
				}
				for (Benefit_Order__c objBO : CarrierOrderHelperFunctions.getBenefitOrdersById(set_BOIds).values()) {
					if (objBO?.Type__c != map_BenefitOrderIdBORecord.get(objBO.Id)?.Type__c && set_BOsBORType.contains(map_BenefitOrderIdBORecord.get(objBO.Id)?.Type__c)) {
						objBO.Type__c = map_BenefitOrderIdBORecord.get(objBO.Id).Type__c;
						list_toAssignOwnerEligibleBO.add(objBO);
					}

					if (objBO.RecordTypeId == BenefitOrderHelper.BO_REC_TYPE_ID_BOR) {
						blnSkipBOTrigger = false;
					}
				}
				new BTAssignmentUtil().processBOForAdvocateAssignment(list_toAssignOwnerEligibleBO, false);

				if (list_toAssignOwnerEligibleBO.size() > 0) {
					try {
						BenefitOrderHelper.skipTrigger = blnSkipBOTrigger;
						DataBase.update(list_toAssignOwnerEligibleBO, true);
					} catch (exception ex) {
						ExceptionLogUtil.logException('CarrierOrderLineItemTriggerHelper', 'Update BO::processBOForAdvocateAssignment', ex.getMessage(), 'High');
					}
				}
			} catch (exception ex) {
				ExceptionLogUtil.logException('CarrierOrderLineItemTriggerHelper.cls', 'updateCarrierOrderWithTriggerSkip', ex.getMessage(), 'High');
			}
			CarrierOrderTriggerHelper.skipTrigger = blnPreviousValue;
		}
	}

	//method to update "Benefit order"
	public void updateBenefitOrderWithTriggerSkip() {
		if (map_BenefitOrderIdBORecord.size() > 0) {
			boolean previousVal = BenefitOrderHelper.skipTrigger;
			BenefitOrderHelper.skipTrigger = true;
			try {
				update map_BenefitOrderIdBORecord.values();
			} catch (exception ex) {
				ExceptionLogUtil.logException('CarrierOrderLineItemTriggerHelper.cls', 'updateBenefitOrderWithTriggerSkip', ex.getMessage(), 'High');
			}
			BenefitOrderHelper.skipTrigger = previousVal;
		}
	}

	/**BY:PR, Date:Jan/29/2019, Desc: This method creating "bor checklist" object records for newly created "carrier order line item" */
	private void createCheckListForBTCarrierOrderLineItems(list<Carrier_Order_Line_Item__c> list_LineItems) {
		if (list_LineItems.isEmpty()) {
			return;
		}

		List<BOR_Master_Checklist__c> list_masterCheckListRecords = [
			SELECT Non_TADA_Type__c, TADA_Type__c, TADA_Status__c, Mandatory__c
			FROM BOR_Master_Checklist__c
			WHERE BOR_Checklist_Status__c = 'Active' AND REcordType.Name = 'Benefits'
			ORDER BY Sequence__c ASC
		];

		if (list_masterCheckListRecords.isEmpty()) {
			return;
		}

		List<BOR_Checklist__c> list_toInsertBOCheckList = new List<BOR_Checklist__c>();
		for (Carrier_Order_Line_Item__c objLI : list_LineItems) {
			String strBenefitType = objLI.Benefit_Types__c;
			for (BOR_Master_Checklist__c objMC : list_masterCheckListRecords) {
				Boolean blnHasTadaType = false;
				if (objLI.Benefit_Types__c.equalsIgnoreCase('Flexible Spending Account - Medical')) {
					if (objMC.TADA_Type__c == 'FSA') {
						blnHasTadaType = true;
					}
				} else if (objLI.Benefit_Types__c.equalsIgnoreCase('hsa')) {
					if (objMC.TADA_Type__c == 'HSA') {
						blnHasTadaType = true;
					}
				} else if (objLI.Benefit_Types__c.equalsIgnoreCase('Flexible Spending Account - Dependent Care')) {
					if (objMC.TADA_Type__c == 'DCA') {
						blnHasTadaType = true;
					}
				} else if (objLI.Benefit_Types__c.equalsIgnoreCase('commuter')) {
					if (objMC.TADA_Type__c == 'Commuter') {
						blnHasTadaType = true;
					}
				} else if (objMC.TADA_Type__c == null) {
					list_toInsertBOCheckList.add(
						new BOR_Checklist__c(BOR_Checkpoints__c = objMC.id, Non_TADA_Type__c = objMC.Non_TADA_Type__c, Carrier_Order_Line_Item__c = objLI.Id, Mandatory__c = objMC.Mandatory__c)
					);
				}

				if (blnHasTadaType) {
					list_toInsertBOCheckList.add(
						new BOR_Checklist__c(BOR_Checkpoints__c = objMC.id, Carrier_Order_Line_Item__c = objLI.Id, Mandatory__c = objMC.Mandatory__c, TADA_Status__c = objMC.TADA_Status__c)
					);
				}
			}
		}

		if (list_toInsertBOCheckList.size() > 0) {
			try {
				insert list_toInsertBOCheckList;
			} catch (exception ex) {
				ExceptionLogUtil.logException('CarrierOrderLineItemTriggerHelper', 'createCheckListForBTCarrierOrderLineItems', ex.getMessage(), 'High');
			}
		}
	}
}