/**
 * @name         BTTADACheckList
 * @author       Anand
 * @date         24-01-2020
 * @description  TADA carriers Assignement
 **/
public class BTTADACheckListCtrl {
	//>>>>>>>>>>Varible assignment>>>>>>>>>>>>>>>>
	public Carrier_Order__c obj_CarrierOrder { get; set; }
	public string strCarrierOrderId { get; set; }
	public Map<String, List<BOR_Checklist__c>> map_borCheckList { get; set; }
	public Set<String> set_BenefitType { get; set; }
	public boolean isChecklistAvailable { get; set; }
	public String str_benefitOrder = 'Flexible Spending Account - Medical;Flexible Spending Account - Dependent Care;HSA;Commuter';
	public set<String> setCoStage = new Set<String>{ 'Collecting Documents', 'Implementing TAdA Plans', 'Balance Collection', 'Transferring Balances' };

	public list<COStageWrapper> lstStageWrapper { get; set; }
	public map<string, boolean> mapAllChecklistStageSelected;
	public map<String, List<BOR_Checklist__c>> mapStageWiseChecklist;
	public string strCOStage { get; set; }
	public boolean blnPreviousChecklist { get; set; }
	public boolean blnDisableAll { get; set; }
	//public boolean blnMarkComplete{get;set;}
	public boolean blnIsCheckAll { get; set; }
	public boolean blnIsLastTADAStatus { get; set; }
	//>>>>>>>>>>>>>>>>>>>>>Constructor of the Page>>>>>>>>>>>>>>>>>>>>>>>>
	public BTTADACheckListCtrl() {
		blnIsCheckAll = false;
		blnIsLastTADAStatus = false;
		strCarrierOrderId = Apexpages.currentPage().getParameters().get('COID');
		GetStageChecklistValue();
		if (String.isBlank(obj_CarrierOrder.Id)) {
			Cache.displayErrorMessage('Carrier order\'s Id is Missing', ApexPages.Severity.ERROR);
		}
	}
	public PageReference GetStageChecklistValue() {
		strCOStage = Apexpages.currentPage().getParameters().get('costage');
		map_borCheckList = new Map<String, List<BOR_Checklist__c>>();
		set_BenefitType = new Set<String>();
		isChecklistAvailable = false;
		blnPreviousChecklist = false;
		blnIsLastTADAStatus = false;
		GetAllCompletedCheckListBasedOnStage();
		GetCarrierDetail(); //get carrier Order detail
		GetTADACheckList(); //get All Checklist based on carrier Order Id
		return null;
	}

	private void GetAllCompletedCheckListBasedOnStage() {
		mapStageWiseChecklist = new Map<String, List<BOR_Checklist__c>>();
		for (BOR_Checklist__c obj_BOR : [
			SELECT id, TADA_Status__c, IsCheckPointImplemented__c, Carrier_Order_Line_Item__r.Carrier_Order__r.Implementation_Stage__c
			FROM BOR_Checklist__c
			WHERE Carrier_Order_Line_Item__r.Carrier_Order__c = :strCarrierOrderId
		]) {
			String strCoStage = obj_BOR.TADA_Status__c;
			if (mapStageWiseChecklist.containsKey(strCoStage)) {
				mapStageWiseChecklist.get(strCoStage).add(obj_BOR);
			} else {
				mapStageWiseChecklist.put(strCoStage, new List<BOR_Checklist__c>{ obj_BOR });
			}
		}
	}
	private void GetCarrierDetail() {
		obj_CarrierOrder = new Carrier_Order__c();
		blnIsLastTADAStatus = false;
		List<Carrier_Order__c> lstCarrierOrder = [
			SELECT Id, Implementation_Stage__c, Benefit_Types__c
			FROM Carrier_Order__c
			WHERE id = :strCarrierOrderId
		];
		if (lstCarrierOrder != null && lstCarrierOrder.size() > 0) {
			obj_CarrierOrder = lstCarrierOrder[0];
			//In case of Full filled assign first Stage
			string strStage = obj_CarrierOrder.Implementation_Stage__c;
			//Check last status based on benefit Type
			if (obj_CarrierOrder.Benefit_Types__c == 'HSA') {
				if (strStage == 'Implementing TAdA Plans') {
					blnIsLastTADAStatus = true;
				}
			} else {
				if (strStage == 'Transferring Balances') {
					blnIsLastTADAStatus = true;
				}
			}
			//If user hit TADA order staus then from screen
			if (strCOStage != null && strCOStage != strStage) {
				blnIsLastTADAStatus = false;
			}
			PopulateCOStage(strStage);
		}
	}
	//get TADA Checklist based on Carrier Ordre Status
	private void GetTADACheckList() {
		blnDisableAll = false;
		map_borCheckList.clear();
		blnPreviousChecklist = false;
		Set<String> set_ExistingBenefitType = new Set<String>();
		String str_BenefitType = '';
		string strTempStage = obj_CarrierOrder.Implementation_Stage__c;
		//If All Check list complete and Stage is 'Fullfiled'
		if (strTempStage == 'Approved') {
			if (string.isBlank(strCOStage)) {
				//Assign previous value to show all checklist and notes in disable format
				strTempStage = 'Collecting Documents';
			}
			blnDisableAll = true;
		}
		if (string.isNotBlank(strCOStage)) {
			strTempStage = strCOStage;
			if (strCOStage != obj_CarrierOrder.Implementation_Stage__c) {
				blnPreviousChecklist = true;
			}
		}
		if (blnDisableAll == true) {
			blnPreviousChecklist = true;
		}

		for (BOR_Checklist__c obj_BOR : [
			SELECT
				id,
				Name,
				BOR_Checkpoints__c,
				Carrier_Order_Line_Item__r.Benefit_Types__c,
				TADA_Status__c,
				Carrier_Order_Line_Item__r.Carrier_Order__c,
				IsCheckPointImplemented__c,
				BOR_Checkpoints__r.BOR_Checklist_Name__c,
				Facilitator_Notes__c,
				Carrier_Order_Line_Item__r.Carrier_Order__r.Facilitator_2_Plan_Build__c,
				Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required__c,
				Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required_Reason__c,
				Carrier_Order_Line_Item__r.Carrier_Order__r.Contribution_per_the_ER__c,
				BOR_Checkpoints__r.Sequence__c,
				BOR_Checkpoints__r.Mandatory__c,
				BOR_Checkpoints__r.Optional_Checklist__c,
				Carrier_Order_Line_Item__r.Carrier_Order__r.Implementation_Stage__c
			FROM BOR_Checklist__c
			WHERE Carrier_Order_Line_Item__r.Carrier_Order__c = :obj_CarrierOrder.Id AND TADA_Status__c = :strTempStage
			ORDER BY BOR_Checkpoints__r.Sequence__c
		]) {
			str_BenefitType = obj_BOR.Carrier_Order_Line_Item__r.Benefit_Types__c;
			if (String.isNotBlank(str_BenefitType)) {
				//Categorize checklist on the basis of Benefit Type
				set_ExistingBenefitType.add(str_BenefitType);
				if (map_borCheckList.containsKey(str_BenefitType)) {
					List<BOR_Checklist__c> list_BORCheck = map_borCheckList.get(str_BenefitType);
					list_BORCheck.add(obj_BOR);
					map_borCheckList.put(str_BenefitType, list_BORCheck);
				} else {
					List<BOR_Checklist__c> list_BORCheck = new List<BOR_Checklist__c>();
					list_BORCheck.add(obj_BOR);
					map_borCheckList.put(str_BenefitType, list_BORCheck);
				}
			}
		}

		//Set default order of Benefit Type Name.
		for (String strOrder : str_benefitOrder.split(';')) {
			if (set_ExistingBenefitType.contains(strOrder) && !set_BenefitType.contains(strOrder)) {
				set_BenefitType.add(strOrder);
				isChecklistAvailable = true;
			}
		}

		if (set_BenefitType.size() == 0) {
			Cache.displayErrorMessage('Checklist is not available for "' + obj_CarrierOrder.Implementation_Stage__c + '" stage.', ApexPages.Severity.ERROR);
		}
	}

	private boolean CheckAllCheckList() {
		boolean chkAll = true;
		List<BOR_Checklist__c> lstCheckList = [
			SELECT IsCheckPointImplemented__c
			FROM BOR_Checklist__c
			WHERE IsCheckPointImplemented__c = FALSE AND Carrier_Order_Line_Item__r.Carrier_Order__c = :strCarrierOrderId
		];
		if (lstCheckList != null && lstCheckList.size() > 0) {
			chkAll = false;
		}
		return chkAll;
	}
	public PageReference SaveChecklist() {
		Save();
		Cache.displayErrorMessage('Successfully Saved.', ApexPages.Severity.CONFIRM);
		return null;
	}

	public PageReference SaveAndSubmitChecklist() {
		SaveAndSubmit(false);
		return null;
	}

	private void SaveAndSubmit(boolean blnIsComplete) {
		boolean isSubmit = Save();
		blnIsCheckAll = CheckAllCheckList();
		Boolean isStatusUpdated = false;
		if (isSubmit && obj_CarrierOrder.Implementation_Stage__c != null) {
			if (blnIsComplete == true && blnIsCheckAll == false) {
				Cache.displayErrorMessage('To mark complete you have to complete all stages checklist', ApexPages.Severity.ERROR);
			} else {
				isStatusUpdated = updateImplementationStage(blnIsCheckAll, blnIsComplete);
				if (isStatusUpdated) {
					GetStageChecklistValue();
				}
			}
		} else {
			if (blnIsComplete == true) {
				Cache.displayErrorMessage('To mark complete you have to complete all stages checklist', ApexPages.Severity.ERROR);
			} else {
				Cache.displayErrorMessage('To move on next stage you have to complete all.', ApexPages.Severity.ERROR);
			}
		}
	}
	public PageReference MarkComplete() {
		SaveAndSubmit(true);
		return null;
	}

	private boolean Save() {
		boolean isSubmit = false;
		List<BOR_Checklist__c> list_BenefitType = new List<BOR_Checklist__c>();
		for (String str_BenefitType : set_BenefitType) {
			if (map_borCheckList.containsKey(str_BenefitType)) {
				list_BenefitType.addAll(map_borCheckList.get(str_BenefitType));
			}
		}

		if (list_BenefitType.size() > 0) {
			isSubmit = true;
			for (BOR_Checklist__c obj_BORCheckList : list_BenefitType) {
				if (obj_BORCheckList.IsCheckPointImplemented__c == false) {
					isSubmit = false;
				}
			}
			update list_BenefitType;
		}
		return isSubmit;
	}

	public boolean updateImplementationStage(boolean isCheckAll, boolean isComplete) {
		/*
        	Collecting Documents
			Implementing TAdA Plans
			Balance Collection
			Transferring Balances
        */
		boolean isStatusUpdated = false;
		string origialStage = obj_CarrierOrder.Implementation_Stage__c;
		if ('Collecting Documents' == obj_CarrierOrder.Implementation_Stage__c) {
			obj_CarrierOrder.Implementation_Stage__c = 'Implementing TAdA Plans';
			isStatusUpdated = true;
		} else if ('Implementing TAdA Plans' == obj_CarrierOrder.Implementation_Stage__c) {
			obj_CarrierOrder.Implementation_Stage__c = 'Balance Collection';
			isStatusUpdated = true;
		} else if ('Balance Collection' == obj_CarrierOrder.Implementation_Stage__c) {
			obj_CarrierOrder.Implementation_Stage__c = 'Transferring Balances';
			isStatusUpdated = true;
		}
		if (isCheckAll == true && isComplete == true) {
			obj_CarrierOrder.Implementation_Stage__c = 'Approved';
			isStatusUpdated = true;
		}
		if (isStatusUpdated) {
			update obj_CarrierOrder;
		}
		return isStatusUpdated;
	}

	private void PopulateCOStage(string stage) {
		lstStageWrapper = new List<COStageWrapper>();
		for (string st : setCoStage) {
			if (mapStageWiseChecklist != null && mapStageWiseChecklist.get(st) != null && mapStageWiseChecklist.containsKey(st) == true) {
				List<BOR_Checklist__c> lstCheckList = mapStageWiseChecklist.get(st);
				COStageWrapper cw = new COStageWrapper();
				//get Completed Checklist
				cw.strCSS = 'slds-is-incomplete';
				//If All previous stage is get complete then mark complete
				if (st != stage) {
					boolean selected = false;
					for (BOR_Checklist__c bor : lstCheckList) {
						if (bor.IsCheckPointImplemented__c == true) {
							selected = true;
							break;
						}
					}
					if (selected == true) {
						cw.strCSS = 'slds-is-incomplete completed';
					}
				}
				if (string.isNotBlank(strCOStage)) {
					if (st == stage) {
						cw.strCSS = 'slds-is-incomplete completed';
					}
					if (strCOStage == st) {
						cw.strCSS = 'slds-is-active';
					}
				} else {
					if (st == stage) {
						cw.strCSS = 'slds-is-active';
					}
				}
				cw.strCOStage = st;
				lstStageWrapper.add(cw);
			}
		}
	}

	public class COStageWrapper {
		public string strCSS { get; set; }
		public string strCOStage { get; set; }
	}
}