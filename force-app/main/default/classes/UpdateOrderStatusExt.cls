/***************************************************
Purpose : Update Order Status and Implementation Stage on Mass Update Stages.
Written By : Deepak Tyagi
Test Classes : UpdateOrderStatusExtTest
****************************************************/
public class UpdateOrderStatusExt {
	Benefit_Order__c benefitObj;
	public Carrier_Order__c objNonTadaCO { get; set; }
	public Carrier_Order__c coTerObj { get; set; }
	public Carrier_Order__c objTadaCO { get; set; }
	public Boolean blnIsNonTadaCarrierOrder { get; set; }
	public Boolean blnIsTadaCarrierOrder { get; set; }
	// Boolean to show Error
	public Boolean blnHasError { get; set; }
	// Set to store all userId from Public Group
	set<Id> set_userPublicGroup;
	public List<SelectOption> list_TadaImplementationStageBor { get; set; }
	public List<SelectOption> list_NonTadaImplementationStageBor { get; set; }
	public List<SelectOption> list_TadaImplementationStageDetail { get; set; }
	public List<SelectOption> list_NonTadaImplementationStageDetail { get; set; }
	public Boolean blnIsBoR { get; set; }
	public UpdateOrderStatusExt(ApexPages.StandardSetController standardSetController) {
		coTerObj = new Carrier_Order__c();
		objNonTadaCO = new Carrier_Order__c();
		objTadaCO = new Carrier_Order__c();
		blnIsNonTadaCarrierOrder = false;
		blnIsTadaCarrierOrder = false;
		blnHasError = false;
		blnIsBoR = false;
		set_userPublicGroup = new Set<Id>();
		list_TadaImplementationStageBor = new List<SelectOption>();
		list_NonTadaImplementationStageBor = new List<SelectOption>();
		list_TadaImplementationStageDetail = new List<SelectOption>();
		list_NonTadaImplementationStageDetail = new List<SelectOption>();
		String currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
		//get the Selected Carrier Order List
		List<Carrier_Order__c> lst_CarrierOrderIds = (List<Carrier_Order__c>) standardSetController.getSelected();

		if (!lst_CarrierOrderIds.isEmpty()) {
			//update the status only if user belong to order stage update users group
			for (GroupMember gm : [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = 'Order Stage Update Users']) {
				set_userPublicGroup.add(gm.UserOrGroupId);
			}
			benefitObj = [
				SELECT
					Id,
					Order_Status__c,
					OwnerId,
					RecordTypeId,
					RecordType.Name,
					Opportunity__r.Source_ID__c,
					Opportunity__r.ID__c,
					Opportunity__r.Id_And_Source_Id__c,
					(SELECT Id, Implementation_Stage__c, Benefit_Types__c, RecordTypeId, Additional_Details__c, OwnerId FROM Carrier_Orders__r WHERE Id IN :lst_CarrierOrderIds)
				FROM Benefit_Order__c
				WHERE Id = :currentRecordId
			];
			if (benefitObj.OwnerId != userInfo.getUserId() && !set_userPublicGroup.contains(UserInfo.getUserId())) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.ChangeStagesError));
				blnHasError = true;
			}
			if (benefitObj != null && benefitObj.Carrier_Orders__r != null && benefitObj.Carrier_Orders__r.size() > 0) {
				//if user active/reopen the canceled Benefit Order
				if (
					(benefitObj.RecordType.Name == 'New Plan' ||
					benefitObj.RecordType.Name == 'Benefits BoR') &&
					(benefitObj.Order_Status__c == 'Canceled' ||
					benefitObj.Order_Status__c == 'Closed Admin') &&
					benefitObj.Opportunity__r.ID__c == null &&
					benefitObj.Opportunity__r.Source_ID__c == null &&
					benefitObj.Opportunity__r.Id_And_Source_Id__c != null
				) {
					Map<String, String> map_OppIdAndSourceId = new Map<String, String>();
					map_OppIdAndSourceId = UtilitiesFactory.readStringAsMap(benefitObj.Opportunity__r.Id_And_Source_Id__c);
					String strSourceId = '';
					String strId = '';
					if (!map_OppIdAndSourceId.isEmpty()) {
						if (map_OppIdAndSourceId.containsKey('Source_ID__c'))
							strSourceId = map_OppIdAndSourceId.get('Source_ID__c');
						if (map_OppIdAndSourceId.containsKey('Id__c'))
							strId = map_OppIdAndSourceId.get('Id__c');
					}
					if (String.isNotBlank(strId) && String.isNotBlank(strSourceId)) {
						List<Opportunity> lst_Opportunity = [SELECT Id FROM Opportunity WHERE ID__c = :strId AND Source_ID__c = :strSourceId];
						if (!lst_Opportunity.isEmpty()) {
							ApexPages.addmessage(
								new ApexPages.message(
									ApexPages.severity.WARNING,
									'The carrier orders and Benefit order is canceled and you will not be able to reopen the orders. The sales already has a new opportunity which is still open, create biztech jira to reopen the order'
								)
							);
							blnHasError = true;
						}
					}
				}
				if (benefitObj.RecordType.Name == 'Benefits BoR') {
					blnIsBoR = true;
				}
				for (Carrier_Order__c co : benefitObj.Carrier_Orders__r) {
					if (blnIsNonTadaCarrierOrder && blnIsTadaCarrierOrder) {
						break;
					} else {
						if (
							co.Benefit_Types__c != null &&
							(co.Benefit_Types__c.contains('HSA') ||
							co.Benefit_Types__c.contains('Commuter') ||
							co.Benefit_Types__c.contains('Flexible Spending Account - Medical') ||
							co.Benefit_Types__c.contains('Flexible Spending Account - Dependent Care'))
						) {
							blnIsTadaCarrierOrder = true;
						} else {
							blnIsNonTadaCarrierOrder = true;
						}
					}
				}

				if (benefitObj.RecordTypeId == Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR')) {
					getBorImplementationStage();
					string strBoRCarrierOrderId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
					objNonTadaCO.RecordTypeId = strBoRCarrierOrderId;
					objTadaCO.RecordTypeId = strBoRCarrierOrderId;
				}
			}
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Select the carrier order from the list'));
			blnHasError = true;
		}
	}
	public void getBorImplementationStage() {
		Set<String> set_TAdaImplementationStage = new Set<String>();
		Set<String> set_NonTAdaImplementationStage = new Set<String>();
		for (BoR_Implementation_Stage__mdt objBORStage : [SELECT Id, Type_of_Record__c, Stage_Value__c, Sequence__c FROM BoR_Implementation_Stage__mdt ORDER BY Sequence__c]) {
			if (objBORStage.Type_of_Record__c == 'TAda' || objBORStage.Type_of_Record__c == 'Both') {
				set_TAdaImplementationStage.add(objBORStage.Stage_Value__c);
			}
			if (objBORStage.Type_of_Record__c == 'Non TAda' || objBORStage.Type_of_Record__c == 'Both') {
				set_NonTAdaImplementationStage.add(objBORStage.Stage_Value__c);
			}
		}
		//for Non Tada Carrier order
		if (blnIsNonTadaCarrierOrder && !set_NonTAdaImplementationStage.isEmpty()) {
			getOrderStatusForBOR(set_NonTAdaImplementationStage, false);
		}
		//for Tada Carrier order
		if (blnIsTadaCarrierOrder && !set_TAdaImplementationStage.isEmpty()) {
			getOrderStatusForBOR(set_TAdaImplementationStage, true);
		}
	}
	private void getOrderStatusForBOR(Set<String> set_ImplementationStage, Boolean isTada) {
		for (String objStageName : set_ImplementationStage) {
			SelectOption so = new selectOption(objStageName.trim(), objStageName.trim());
			if (isTada)
				list_TadaImplementationStageBor.add(so);
			else
				list_NonTadaImplementationStageBor.add(so);
		}
	}
	public void GetTadaStageDetail() {
		if (String.isNotBlank(objTadaCO.Implementation_Stage__c)) {
			list_TadaImplementationStageDetail = new List<SelectOption>();
			list_TadaImplementationStageDetail = GetStageDetail(objTadaCO.Implementation_Stage__c, list_TadaImplementationStageDetail, 'TAda');
		}
	}
	public void GetNonTadaStageDetail() {
		if (String.isNotBlank(objNonTadaCO.Implementation_Stage__c)) {
			list_NonTadaImplementationStageDetail = new List<SelectOption>();
			list_NonTadaImplementationStageDetail = GetStageDetail(objNonTadaCO.Implementation_Stage__c, list_NonTadaImplementationStageDetail, 'Non TAda');
		}
	}
	public List<SelectOption> GetStageDetail(String strImplementationStage, List<SelectOption> list_ImplementationStage, String strOrderType) {
		if (String.isNotBlank(strImplementationStage)) {
			Set<String> set_ImplementationStageDetial = new Set<String>();
			for (BoR_Implementation_Stage_Detail__mdt objBORStage : [
				SELECT Id, Detail_Value__c, Type_of_Record__c, Sequence__c
				FROM BoR_Implementation_Stage_Detail__mdt
				WHERE Implementation_Stage__c = :strImplementationStage
				ORDER BY Sequence__c
			]) {
				if (objBORStage.Type_of_Record__c == strOrderType || objBORStage.Type_of_Record__c == 'Both') {
					set_ImplementationStageDetial.add(objBORStage.Detail_Value__c);
				}
			}
			if (!set_ImplementationStageDetial.isEmpty()) {
				list_ImplementationStage.add(new selectOption('', '--None--'));
				for (String objStageName : set_ImplementationStageDetial) {
					SelectOption so = new selectOption(objStageName.trim(), objStageName.trim());
					list_ImplementationStage.add(so);
				}
			}
		}
		return list_ImplementationStage;
	}

	// Method to update Carrier Order
	public PageReference updateStatus() {
		if (blnIsBoR) {
			if ((String.isBlank(objNonTadaCO.Implementation_Stage__c) && blnIsNonTadaCarrierOrder) || (String.isBlank(objTadaCO.Implementation_Stage__c) && blnIsTadaCarrierOrder)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Implementation Stage: You must enter a value'));
				return null;
			}
		}
		if (!String.isBlank(objTadaCO.Implementation_Stage__c) && objTadaCO.Implementation_Stage__c == 'Canceled' && String.isBlank(objTadaCO.Stage_Detail__c)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Implementation Stage Detail: You must enter a value'));
			return null;
		}
		if (!String.isBlank(objNonTadaCO.Implementation_Stage__c) && objNonTadaCO.Implementation_Stage__c == 'Canceled' && String.isBlank(objNonTadaCO.Stage_Detail__c)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Implementation Stage Detail: You must enter a value'));
			return null;
		}
		if (objNonTadaCO.Implementation_Stage__c == 'Canceled' && 'Other'.equalsIgnoreCase(objNonTadaCO.Stage_Detail__c) && String.isBlank(objNonTadaCO.Additional_Details__c)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Additional Details: You must enter a value'));
			return null;
		}
		if (objTadaCO.Implementation_Stage__c == 'Canceled' && 'Other'.equalsIgnoreCase(objTadaCO.Stage_Detail__c) && String.isBlank(objTadaCO.Additional_Details__c)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Additional Details: You must enter a value'));
			return null;
		}
		try {
			List<Carrier_Order__c> lstToUpdateCO = new List<Carrier_Order__c>();
			Set<Id> set_COBORId = new Set<Id>();
			if (benefitObj != null && benefitObj.Carrier_Orders__r != null && benefitObj.Carrier_Orders__r.size() > 0) {
				for (Carrier_Order__c co : benefitObj.Carrier_Orders__r) {
					//updating bor carrier order line item
					if (co.Implementation_Stage__c == 'Canceled' && co.RecordTypeId == cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR')) {
						set_COBORId.add(co.Id);
					}
					if (
						co.Benefit_Types__c != null &&
						(co.Benefit_Types__c.contains('HSA') ||
						co.Benefit_Types__c.contains('Commuter') ||
						co.Benefit_Types__c.contains('Flexible Spending Account - Medical') ||
						co.Benefit_Types__c.contains('Flexible Spending Account - Dependent Care'))
					) {
						co.Implementation_Stage__c = objTadaCO.Implementation_Stage__c;
						/*
                        Updated by:- Deepika Saini
                        Reason:- Added the Stage detail field which is mandetory in some cases where Implemetation Stage 
                        (Approved,Canceled)
                         */
						co.Stage_Detail__c = objTadaCO.Stage_Detail__c;
						if (objTadaCO.Implementation_Stage__c == 'Canceled' && objTadaCO.Stage_Detail__c == 'Other') {
							co.Additional_Details__c = objTadaCO.Additional_Details__c;
						}
					} else {
						co.Implementation_Stage__c = objNonTadaCO.Implementation_Stage__c;
						co.Stage_Detail__c = objNonTadaCO.Stage_Detail__c;
						if (objNonTadaCO.Implementation_Stage__c == 'Canceled' && objNonTadaCO.Stage_Detail__c == 'Other') {
							co.Additional_Details__c = objNonTadaCO.Additional_Details__c;
						}
					}
					if (!set_COBORId.isEmpty() && set_COBORId.contains(co.Id) && co.RecordTypeId == cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR')) {
						if (co.Implementation_Stage__c == 'Canceled') {
							set_COBORId.remove(co.Id);
						} else {
							set_COBORId.add(co.Id);
						}
					}
					lstToUpdateCO.add(co);
				}

				if (lstToUpdateCO != null && lstToUpdateCO.size() > 0) {
					update lstToUpdateCO;
					if (!set_COBORId.isEmpty()) {
						update ([SELECT Id FROM Carrier_Order_Line_Item__c WHERE Carrier_Order__c IN :set_COBORId]);
					}
				}
			}

			PageReference pageRef = new PageReference('/' + benefitObj.id);
			return pageRef;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Error in Status update.'));
			return null;
		}
	}
}