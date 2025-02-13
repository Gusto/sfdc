/**
    BY: PR
    Date: Feb/13/2020
    Desc: This [Extension] class is used by [BTCarrierOrderCreateEdit.page]. This page is used to manage(Create and Modify) related Carrier Order records
            for a Benefit Order
 */
public with sharing class BTCarrierOrderCreateEditExtension {
	public list<carrierOrderWrapper> list_CarrierOrderDetails { get; set; }
	public string strRowToDelete { get; set; }

	//contains BO Ids for which this functionality is called
	Id idBOId;
	//contains Account name linked with the BO// This variable is ued to create CO name
	String strBOAccountName;
	//This stores list of [Benefit Type] valid for Non-Tada type CO
	List<SelectOption> list_NONTadaBenefitTypeList = new List<SelectOption>();
	//This stores list of [Benefit Type] valid for Tada type CO
	List<SelectOption> list_TadaBenefitTypeList = new List<SelectOption>();
	Map<string, map<string, Carrier_Order_Line_Item__c>> map_OriginalCOIdBenefitTypeLineItemDetails = new Map<string, map<string, Carrier_Order_Line_Item__c>>();

	//constructor
	public BTCarrierOrderCreateEditExtension(ApexPages.StandardController sc) {
		idBOId = ApexPages.currentPage().getParameters().get('id');

		list_CarrierOrderDetails = new List<carrierOrderWrapper>();

		list_NONTadaBenefitTypeList.add(new SelectOption('Medical', 'Medical'));
		list_NONTadaBenefitTypeList.add(new SelectOption('Dental', 'Dental'));
		list_NONTadaBenefitTypeList.add(new SelectOption('Vision', 'Vision'));
		list_NONTadaBenefitTypeList.add(new SelectOption('Life', 'Life'));
		list_NONTadaBenefitTypeList.add(new SelectOption(utils.BENEFIT_TYPE_LTD, utils.BENEFIT_TYPE_LTD));
		list_NONTadaBenefitTypeList.add(new SelectOption(utils.BENEFIT_TYPE_STD, utils.BENEFIT_TYPE_STD));

		list_TadaBenefitTypeList.add(new SelectOption('HSA', 'HSA'));
		list_TadaBenefitTypeList.add(new SelectOption('Flexible Spending Account - Medical', 'Flexible Spending Account - Medical'));
		list_TadaBenefitTypeList.add(new SelectOption('Flexible Spending Account - Dependent Care', 'Flexible Spending Account - Dependent Care'));
		list_TadaBenefitTypeList.add(new SelectOption('Commuter', 'Commuter'));

		if (string.isBlank(idBOId)) {
			ApexPages.addMessage(new ApexPages.Message(Apexpages.severity.ERROR, 'Page not loaded properly. Please try again.'));
		} else {
			getCarrierOrderDetails();

			if (string.isBlank(strBOAccountName)) {
				list<Benefit_Order__c> list_BORecord = [SELECT Id, Account__r.Name FROM Benefit_Order__c WHERE Id = :idBOId LIMIT 1];
				if (list_BORecord.size() > 0) {
					strBOAccountName = list_BORecord.get(0).Account__r.Name;
				}
			}
		}

		/* BBO-1971
	  list<Carrier__c> list_tempCarrier = [SELECT Id FROM Carrier__c WHERE Name = :strTADACarrierName LIMIT 1];
		  if (list_tempCarrier.size() > 0) {
		strTadaCarrierId = list_tempCarrier.get(0).id;
	  }
	*/
	}

	/**This method is querying "Carrier Orders" using the related "Benefit Order" Id retrieved from the page url*/
	void getCarrierOrderDetails() {
		if (idBOId != null) {
			list_CarrierOrderDetails = new List<carrierOrderWrapper>();
			map_OriginalCOIdBenefitTypeLineItemDetails = new Map<string, map<string, Carrier_Order_Line_Item__c>>();

			set<string> set_ToExcludeOrderStatus = new Set<String>{ 'Canceled', 'Closed Lost', 'Closed Admin', 'Fulfilled' };
			//{DS}24-03-2020 added Number_Of_Collected_Documents__c, Total_Number_Of_Documents__c,Carrier__r.BT_Facilitator_POD__c in SQOL
			for (Carrier_Order__c objCO : [
				SELECT
					Id,
					Carrier__c,
					Carrier__r.Name,
					Benefit_Types__c,
					Renewal_Date__c,
					Benefit_Order__c,
					Benefit_Order__r.Account__r.Name,
					Benefit_Order__r.Qualification_Follow_Up_Date__c,
					Start_Date__c,
					Initial_Owner__c,
					Implementation_Stage__c,
					OwnerId,
					Benefit_Order__r.OwnerId,
					Benefit_Order__r.UW_Owner__c,
					Number_Of_Collected_Documents__c,
					Total_Number_Of_Documents__c,
					Carrier__r.BT_Facilitator_POD__c,
					Carrier__r.Partner_Type__c, 
					Is_Multi_EIN__c,
					(SELECT Id, Renewal_Date__c, Benefit_Types__c FROM Carrier_Order_Line_Item__r)
				FROM Carrier_Order__c
				WHERE Benefit_Order__c = :idBOId AND Implementation_Stage__c NOT IN :set_ToExcludeOrderStatus
			]) {
				carrierOrderWrapper wrapperInstance = new carrierOrderWrapper();
				wrapperInstance.objCarrierOrder = objCO;

				//populating master picklist option list
				if (objCO.Carrier__r.Partner_Type__c == 'TAdA') {					
					wrapperInstance.list_UnSelectedBenefitType = list_TadaBenefitTypeList;
					wrapperInstance.blnIsTada = true; 
				} else {
					wrapperInstance.list_UnSelectedBenefitType = list_NONTadaBenefitTypeList;
				}

				//populating already present Benefit type picklist option list
				if (objCO.Carrier_Order_Line_Item__r != null && objCO.Carrier_Order_Line_Item__r.size() > 0) {
					map<string, Carrier_Order_Line_Item__c> map_benefitTypeLI = new Map<string, Carrier_Order_Line_Item__c>();

					for (Carrier_Order_Line_Item__c objLI : objCO.Carrier_Order_Line_Item__r) {
						map_benefitTypeLI.put(objLI.Benefit_Types__c, objLI);
					}

					if (map_benefitTypeLI.size() > 0) {
						wrapperInstance.list_SelectedBenefitType.addAll(map_benefitTypeLI.keyset());
					}

					map_OriginalCOIdBenefitTypeLineItemDetails.put(objCO.Id, map_benefitTypeLI);
				}

				if (string.isBlank(strBOAccountName))
					strBOAccountName = objCO.Benefit_Order__r.Account__r.Name;
				list_CarrierOrderDetails.add(wrapperInstance);
			}
		}
	}

	// BBO-1971 check TAdA value
	public PageReference checkTAdAType() {
		Id idCarrierId = list_CarrierOrderDetails.get(list_CarrierOrderDetails.Size() - 1).objCarrierOrder.Carrier__c;
		List<Carrier__c> list_CarrierDetails = [SELECT Id, Name, Partner_Type__c FROM Carrier__c WHERE Id = :idCarrierId];
		if (list_CarrierDetails[0].Partner_Type__c != null && !String.isEmpty(list_CarrierDetails[0].Partner_Type__c)) {
			list_CarrierOrderDetails.get(list_CarrierOrderDetails.Size() - 1).blnIsTada = true;
		}
		return null;
	}

	/**This method is called when user wants to introduce a new CO records via VF page */
	public void addNewRow() {
		carrierOrderWrapper newInstance = new carrierOrderWrapper();
		newInstance.objCarrierOrder = new Carrier_Order__c();
		newInstance.objCarrierOrder.Benefit_Order__c = idBOId;
		newInstance.objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');

		if (list_CarrierOrderDetails.size() > 0) {
			Carrier_Order__c objTempCO = list_CarrierOrderDetails.get(0).objCarrierOrder;
			if (objTempCO.Benefit_Order__r.UW_Owner__c == null && objTempCO.Benefit_Order__r.Qualification_Follow_Up_Date__c == null) {
				newInstance.objCarrierOrder.Implementation_Stage__c = 'Ready For Qualification';
			} else if (objTempCO.Benefit_Order__r.UW_Owner__c != null && objTempCO.Benefit_Order__r.Qualification_Follow_Up_Date__c == null) {
				newInstance.objCarrierOrder.Implementation_Stage__c = 'Qualification';
			} else if (objTempCO.Benefit_Order__r.UW_Owner__c != null && objTempCO.Benefit_Order__r.Qualification_Follow_Up_Date__c != null) {
				newInstance.objCarrierOrder.Implementation_Stage__c = 'Ready for Document Collection';
			}
		} else {
			newInstance.objCarrierOrder.Implementation_Stage__c = 'Ready For Qualification';
		}

		list_CarrierOrderDetails.add(newInstance);
	}

	//This method is used id user wants to delete a newly introduced [Carrier Order] row
	public void removeNewRow() {
		if (string.isNotBlank(strRowToDelete) && list_CarrierOrderDetails.size() > Integer.valueOf(strRowToDelete)) {
			if (list_CarrierOrderDetails.get(Integer.valueOf(strRowToDelete)).objCarrierOrder.Id != null) {
				apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Fatal Error: Can not delete old carrier orders.'));
				return;
			}
			list_CarrierOrderDetails.remove(Integer.valueOf(strRowToDelete));
			strRowToDelete = '';
		} else {
			apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Fatal Error: Page not loaded properly refresh the page and try again.'));
		}
	}

	//following method is called to get the [Benefit type] list based on the selected Carrier for a new CO
	public void getBenefitType() {
		carrierOrderWrapper wrapperInstance = list_CarrierOrderDetails.get(list_CarrierOrderDetails.Size() - 1);
		if (wrapperInstance.objCarrierOrder.Carrier__c != null) {
			if (wrapperInstance.blnIsTada) {
				list_CarrierOrderDetails.get(list_CarrierOrderDetails.Size() - 1).list_UnSelectedBenefitType = list_TadaBenefitTypeList;

				if (string.valueof(list_CarrierOrderDetails.get(0).objCarrierOrder.Benefit_Order__r.OwnerId).startsWith('005')) {
					list_CarrierOrderDetails.get(list_CarrierOrderDetails.Size() - 1).objCarrierOrder.OwnerId = list_CarrierOrderDetails.get(0).objCarrierOrder.Benefit_Order__r.OwnerId;
					list_CarrierOrderDetails.get(list_CarrierOrderDetails.Size() - 1).objCarrierOrder.Initial_Owner__c = list_CarrierOrderDetails.get(0).objCarrierOrder.Benefit_Order__r.OwnerId;
				}
			} else {
				list_CarrierOrderDetails.get(list_CarrierOrderDetails.Size() - 1).list_UnSelectedBenefitType = list_NONTadaBenefitTypeList;
			}
		}
	}

	/**This method is processing and updating the database using user provided details via Vf page */
	public Pagereference syncCarrierOrders() {
		validateCarrierOrderDetails();
		//if validation has introduced the page messages, we want the user to handle all the messages
		if (apexPages.hasMessages()) {
			return null;
		}

		/**If page does not have any messages following code is processing the [Carrier Order] wrapper details */
		if (list_CarrierOrderDetails.size() > 0) {
			list<Carrier_Order_Line_Item__c> list_NewLineItems = new List<Carrier_Order_Line_Item__c>();
			list<Carrier_Order_Line_Item__c> list_TODeleteLineItems = new List<Carrier_Order_Line_Item__c>();
			map<string, Carrier_Order__c> map_CarrierIdNewCarrierOrders = new Map<string, Carrier_Order__c>();
			map<Id, Boolean> map_CarrierIdNewCarrierTada = new Map<Id, Boolean>(); 

			for (carrierOrderWrapper wrapperInstance : list_CarrierOrderDetails) {
				//code to handle newly added CO
				if (wrapperInstance.objCarrierOrder.Id == null) {
					map_CarrierIdNewCarrierOrders.put(wrapperInstance.objCarrierOrder.Carrier__c, wrapperInstance.objCarrierOrder);
					map_CarrierIdNewCarrierTada.put(wrapperInstance.objCarrierOrder.Carrier__c, wrapperInstance.blnIsTada);
					continue;
				}

				//following code is handling [Benefit Type] mods introduced by the user via VF Page
				Carrier_Order__c objCarrierOrder = wrapperInstance.objCarrierOrder;
				if (objCarrierOrder != null && objCarrierOrder.Id != null) {
					set<string> set_BenefitTypeProcessed = new Set<string>();

					for (string strBenefitType : wrapperInstance.list_SelectedBenefitType) {
						if (
							!map_OriginalCOIdBenefitTypeLineItemDetails.containsKey(objCarrierOrder.Id) ||
							!map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).containsKey(strBenefitType)
						) {
							if (strBenefitType == 'Commuter') {
								list_NewLineItems.add(new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenefitType));
							} else {
								list_NewLineItems.add(
									new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenefitType, Renewal_Date__c = objCarrierOrder.Renewal_Date__c)
								);
							}
						} else {
							set_BenefitTypeProcessed.add(strBenefitType);
						}
					}
					if (set_BenefitTypeProcessed.size() > 0 && set_BenefitTypeProcessed.size() != map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).size()) {
						for (string strBT : map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).keyset()) {
							if (!set_BenefitTypeProcessed.contains(strBT)) {
								list_TODeleteLineItems.add(map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).get(strBT));
							}
						}
					}
				}
			}

			/**Following code is handling newly introduced [Carrier Order] creation and related [Carrier Order lIne Item] creation */
			if (map_CarrierIdNewCarrierOrders.size() > 0) {
				for (Carrier__c objCarrier : [SELECT id, Name FROM Carrier__c WHERE Id IN :map_CarrierIdNewCarrierOrders.Keyset()]) {
					//DS[21-05-2020]:- add check for 80 charcter limit
					String strCarrierOrderName = strBOAccountName + ' - ' + objCarrier.Name;
					if (strCarrierOrderName.length() > 80) {
						strCarrierOrderName = objCarrier.Name;
					}
					map_CarrierIdNewCarrierOrders.get(objCarrier.Id).Name = strCarrierOrderName;
				}

				try {
					insert map_CarrierIdNewCarrierOrders.values();
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Records Successfully Updated.'));
				} catch (exception ex) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
					return null;
				}

				for (carrierOrderWrapper wrapperInstance : list_CarrierOrderDetails) {
					if (map_CarrierIdNewCarrierOrders.containsKey(wrapperInstance.objCarrierOrder.Carrier__c)) {
						Carrier_Order__c objCarrierOrder = map_CarrierIdNewCarrierOrders.get(wrapperInstance.objCarrierOrder.Carrier__c);

						for (string strBenefitType : wrapperInstance.list_SelectedBenefitType) {
							list_NewLineItems.add(
								new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenefitType, Renewal_Date__c = objCarrierOrder.Renewal_Date__c)
							);
						}
					}
				}
			}

			/**Following code is handling new [ carrier Order line Item] creation and deletion */
			if (list_NewLineItems.size() > 0 || list_TODeleteLineItems.size() > 0) {
				try {
					if (list_NewLineItems.size() > 0)
						insert list_NewLineItems;
					if (list_TODeleteLineItems.size() > 0)
						delete list_TODeleteLineItems;
					getCarrierOrderDetails();
					if (list_CarrierOrderDetails.get(0).objCarrierOrder.Benefit_Order__r.Qualification_Follow_Up_Date__c != null) {
						//{DS}24-03-2020 update the wrapper with rollup Number of Document and Total Doc
						for (carrierOrderWrapper wrapperInstance : list_CarrierOrderDetails) {
							map_CarrierIdNewCarrierTada.put(wrapperInstance.objCarrierOrder.Carrier__c, wrapperInstance.blnIsTada);
							if (!string.valueof(wrapperInstance.objCarrierOrder.OwnerId).startsWith('005')) {
								map_CarrierIdNewCarrierOrders.put(wrapperInstance.objCarrierOrder.Carrier__c, wrapperInstance.objCarrierOrder);
								continue;
							}
						}
						CarrierOrderFacilitatorAssignment(map_CarrierIdNewCarrierOrders.values(), map_CarrierIdNewCarrierTada);
					}

					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Records Successfully Updated.'));

					return new Pagereference('/' + idBOId);
				} catch (exception ex) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
					return null;
				}
			}
		}

		return null;
	}

	// @TestVisible
	void CarrierOrderFacilitatorAssignment(list<Carrier_Order__c> list_NewCarrierOrders, map<Id, Boolean> map_CarrierIdNewCarrierTada) {
		if (list_NewCarrierOrders == null || list_NewCarrierOrders.size() == 0) {
			return;
		}

		list<Carrier_Order__c> list_NonTadaCOs = new List<Carrier_Order__c>();
		list<Carrier_Order__c> list_TadaCOs = new List<Carrier_Order__c>();

		for (Carrier_Order__c objCO : list_NewCarrierOrders) {
			if (!map_CarrierIdNewCarrierTada.isEmpty() && map_CarrierIdNewCarrierTada.containsKey(objCO.Id) && map_CarrierIdNewCarrierTada.get(objCO.Id)) {
				list_TadaCOs.add(objCO);
			} else {
				list_NonTadaCOs.add(objCO);
			}
		}

		if (list_NonTadaCOs.size() > 0 || list_TadaCOs.size() > 0) {
			BTAssignmentUtil objBTFacilitatorAssignement = new BTAssignmentUtil();
			List<Carrier_Order__c> list_COWithFAC1Owner = objBTFacilitatorAssignement.processCOForFacilitator1Assignment(list_NonTadaCOs, list_TadaCOs);

			update list_COWithFAC1Owner;
		}
	}

	/**Following method is validating the integrity of the user provided details*/
	//@TestVisible
	void validateCarrierOrderDetails() {
		if (list_CarrierOrderDetails.size() > 0) {
			set<String> set_CarrierOrderIds = new Set<String>();
			for (carrierOrderWrapper wrapperInstance : list_CarrierOrderDetails) {
				if (set_CarrierOrderIds.contains(wrapperInstance.objCarrierOrder.Carrier__c)) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Duplicate Records: Not allowed for one Carrier.'));
				} else if (wrapperInstance.list_SelectedBenefitType.size() == 0) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required: Benefit Type field.'));
				}
				if (wrapperInstance.objCarrierOrder.Renewal_Date__c == null) {
					boolean blnIsOnlyCommuter = false;
					if (wrapperInstance.blnIsTada) {
						if (wrapperInstance.list_SelectedBenefitType != null && wrapperInstance.list_SelectedBenefitType.size() == 1 && wrapperInstance.list_SelectedBenefitType.get(0) == 'Commuter') {
							blnIsOnlyCommuter = true;
						}
					}
					if (!blnIsOnlyCommuter) {
						apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required: Renewal Date field.'));
					}
				}
				//BY:PR, Desc: https://app.asana.com/0/1149920908637905/1170649748837574/f
				if (wrapperInstance.objCarrierOrder.Renewal_Date__c != null && !UtilitiesFactory.isBTRenewalDateValid(wrapperInstance.objCarrierOrder.Renewal_Date__c)) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Renewal Date must be in the future, within the next year, 1st or 15th of month.'));
				}

				set_CarrierOrderIds.add(wrapperInstance.objCarrierOrder.Carrier__c);
			}
		} else {
			apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No record found.'));
		}
	}

	/**This wrapper is used to show the data on the VF page */
	public class carrierOrderWrapper {
		public Carrier_Order__c objCarrierOrder { get; set; }
		public list<SelectOption> list_UnSelectedBenefitType { get; set; }
		public list<string> list_SelectedBenefitType { get; set; }
		public Boolean blnIsTada { get; set; }

		public carrierOrderWrapper() {
			objCarrierOrder = new Carrier_Order__c();
			list_UnSelectedBenefitType = new List<SelectOption>();
			list_SelectedBenefitType = new List<string>();
			blnIsTada = false;
		}
	}
}