/**
 * @name         BTBOSideViewCtrl
 * @author       Anand Singh
 * @date         15-02-2020
 * @description  This is used in Benefit order Side view in console
 * @test class   BTBOSideViewCtrlTest
 **/
public class BTBOSideViewCtrl {
	// Variables & Collections
	public Id IdOwner { get; set; }
	public Benefit_Order__c objBenefitOrder { get; set; }
	public Id IdBenefitOrder { get; set; }
	public List<Benefit_Order__c> list_BenefitOrders { get; set; }
	public list<CarrierOrderWrapper> list_CarrierOrderWrapper { get; set; }
	public List<Benefit_Order__c> list_BOsToUpdate { get; set; }
	public Boolean blnShowQualifyButton { get; set; }
	public Boolean blnShowAcceptOrderButton { get; set; }
	public boolean blnShowTADASection { get; set; }
	public set<string> setExclude = Utils.setCOExclude;
	public Carrier_Order__c objCarrierOrder { get; set; }
	public boolean blnShowTADAAcceptBtn { get; set; }
	public List<Case> list_CarrierCases { get; set; }
	public boolean blnCustomerSignedApp { get; set; }
	public Boolean blnIsQF { get; set; }
	public Boolean blnIsADV { get; set; }
	static String ROLE_BT_QF = 'Benefit Transfer Qualifier';
	static String ROLE_BT_ADV = 'Benefit Transfer Advocate';
	public static final String BENEFIT_TRANSFER_QUEUE = 'Benefit_Transfer';
	public string blnLoggedInUserType { get; set; }
	public list<BenefitOrderWrapper> list_AllMultiBOWrapper { get; set; }
	static string strTADACarrierName = Utils.strTADACarrierName;
	static string strOrderStatus_Ready = 'Ready for Qualification';
	static string strOrderStatus_ReadyDocCollection = 'Ready for Document Collection';
	static string strOrderStatus_ERSignature = 'Pending ER Signature';
	static string strOrderStatus_Qualification = 'Qualification';
	static set<string> set_ExcludeMultiEINBO = new Set<string>{ 'Canceled', 'Closed Lost', 'Closed Admin' };

	//Constructor
	public BTBOSideViewCtrl(ApexPages.StandardController controller) {
		blnCustomerSignedApp = false;
		blnLoggedInUserType = null;
		blnIsQF = false;
		blnIsADV = false;
		IdOwner = UserInfo.getUserId();
		IdBenefitOrder = controller.getId();
		ValidateLoggedInUser();
		GetBoDetail();
		//Show view based on logged in user
		if (blnLoggedInUserType == 'Qualifier') {
			blnIsQF = true;
			blnIsADV = false;
		}
		if (blnLoggedInUserType == 'Advocate') {
			blnIsQF = false;
			blnIsADV = true;
		}
	}

	public PageReference ValidateLoggedInUser() {
		blnIsQF = false;
		blnLoggedInUserType = null;
		blnIsADV = false;
		Set<String> set_CurrentUserRoles = new Set<String>();
		set_CurrentUserRoles = UtilitiesFactory.RetriveUserRole(IdOwner);
		if (!set_CurrentUserRoles.isEmpty() && set_CurrentUserRoles.contains(ROLE_BT_QF)) {
			blnIsQF = true;
			blnLoggedInUserType = 'Qualifier';
		} else if (!set_CurrentUserRoles.isEmpty() && set_CurrentUserRoles.contains(ROLE_BT_ADV)) {
			blnIsADV = true;
			blnLoggedInUserType = 'Advocate';
		}

		return null;
	}
	private void GetBoDetail() {
		blnShowQualifyButton = false;
		blnShowAcceptOrderButton = true;
		blnShowTADASection = false;
		blnShowTADAAcceptBtn = false;
		objCarrierOrder = new Carrier_Order__c();
		list_CarrierCases = new List<Case>();

		if (string.isNotBlank(IdBenefitOrder)) {
			objBenefitOrder = new Benefit_Order__c();
			list_BenefitOrders = [
				SELECT
					Id,
					Letters_sent_to_all_carriers__c,
					Name,
					Start_Date__c,
					Type__c,
					Is_Multi_EIN__c,
					Parent_Benefit_Order__c,
					Follow_Up_Notes__c,
					Follow_Up_Date__c,
					Total_Number_Of_Documents__c,
					Percent_Of_Documents_Completed__c,
					Number_Of_Collected_Documents__c,
					Action_Necessary_Notes__c,
					Qualification_Follow_Up_Notes__c,
					External_Deductions__c,
					Useful_docs_in_attachments__c,
					External_Deductions_for_LiDi__c,
					GDrive_Link__c,
					Qualification_Follow_Up_Date__c,
					Transition_to_Fulfillment__c,
					Transition_to_Fulfillment__r.Name,
					Order_Status__c,
					OwnerId,
					(SELECT id, name, Is_Multi_EIN__c, Order_Status__c FROM Benefit_Orders__r WHERE Is_Multi_EIN__c = TRUE),
					UW_Owner__c,
					(SELECT Id, Carrier_Order__c, CaseNumber, Subject, Origin FROM Cases__r WHERE Carrier_Order__c = NULL ORDER BY createddate DESC),
					(SELECT Id, Carrier_Order__c, Name, Escalation_Reason__c, Owner.Name, OwnerId, CreatedDate, Status__c FROM Tickets__r ORDER BY createddate DESC)
				FROM Benefit_Order__c
				WHERE Id = :IdBenefitOrder
			];

			if (list_BenefitOrders != null && list_BenefitOrders.size() > 0) {
				objBenefitOrder = list_BenefitOrders[0];
				//In case of Multi EIN take all related BO in list
				if (objBenefitOrder.Is_Multi_EIN__c == true) {
					list_AllMultiBOWrapper = new List<BenefitOrderWrapper>();
					if (objBenefitOrder.Parent_Benefit_Order__c == null) {
						for (Benefit_Order__c bo : objBenefitOrder.Benefit_Orders__r) {
							//Eliminate Cancelled BO
							if (bo.Order_Status__c != null && set_ExcludeMultiEINBO.contains(bo.Order_Status__c) == false) {
								list_AllMultiBOWrapper.add(new BenefitOrderWrapper(bo, 'Child'));
							}
						}
					} else {
						//get Parent Bo Detail
						Benefit_Order__c objParent = [SELECT id, Name FROM Benefit_Order__c WHERE id = :objBenefitOrder.Parent_Benefit_Order__c LIMIT 1];
						list_AllMultiBOWrapper.add(new BenefitOrderWrapper(objParent, 'Parent'));
					}
				}
				//Show Tab after Qualification
				if (objBenefitOrder.Qualification_Follow_Up_Date__c != null && objBenefitOrder.UW_Owner__c != null) {
					blnIsADV = true;
				}
				//If benefit order has any TADA then show accept button for carrier Order
				string strBenefitType = objBenefitOrder.Type__c;
				if (strBenefitType != null && strBenefitType.toLowerCase().indexOf('tada') > -1) {
					blnShowTADASection = true;
				}

				List<Carrier_Order__c> lstCarrierOrder = [
					SELECT
						Id,
						Carrier__c,
						Is_Multi_EIN__c,
						Parent_Carrier_Order__c,
						Name,
						Implementation_Stage__c,
						Renewal_Date__c,
						Carrier__r.Name,
						Owner.Name,
						Benefit_Types__c,
						(SELECT Id, CaseNumber, Subject FROM Cases__r WHERE Carrier_Order__c != NULL ORDER BY createddate DESC)
					FROM Carrier_Order__c
					WHERE Benefit_Order__c = :IdBenefitOrder AND RecordType.Name = 'Benefits BoR'
				];

				if (lstCarrierOrder != null && lstCarrierOrder.size() > 0) {
					list_CarrierOrderWrapper = new List<CarrierOrderWrapper>();
					for (Carrier_Order__c co : lstCarrierOrder) {
						if (blnIsADV == false || (blnIsADV == true && co.Carrier__r.Name != strTADACarrierName) || (co.Implementation_Stage__c == strOrderStatus_ERSignature)) {
							CarrierOrderWrapper cow = new CarrierOrderWrapper();
							cow.objCarrierOrder = co;
							list_CarrierOrderWrapper.add(cow);
						}
						//If Any TADA Carrier take into another object to show on Advocate View
						if (co.Implementation_Stage__c != strOrderStatus_ERSignature && co.Carrier__r.Name == strTADACarrierName) {
							objCarrierOrder = co;

							if (
								blnIsADV == true &&
								(objCarrierOrder.Implementation_Stage__c == strOrderStatus_ReadyDocCollection ||
								objCarrierOrder.Implementation_Stage__c == strOrderStatus_Ready ||
								objCarrierOrder.Implementation_Stage__c == strOrderStatus_Qualification)
							) {
								blnShowTADAAcceptBtn = true;
							}
						}
						//get All carrier Related cases
						list_CarrierCases.addAll(co.Cases__r);
					}
				} else {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no carrier order(s) availble.'));
				}
				checkAcceptOrder();
				checkQualifyOrder();
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Benefit Order not found'));
			}
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select benefit order to get detail.'));
		}
	}
	public void checkAcceptOrder() {
		blnShowAcceptOrderButton = false;
		if (blnIsQF == true && objBenefitOrder.Order_Status__c == strOrderStatus_Ready && objBenefitOrder.UW_Owner__c == null) {
			blnShowAcceptOrderButton = true;
		}
	}

	public PageReference UpdateStage() {
		try {
			blnShowTADAAcceptBtn = false;
			objCarrierOrder.Implementation_Stage__c = 'Collecting Documents';
			update objCarrierOrder;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public PageReference MarkTADAComplete() {
		try {
			objCarrierOrder.Implementation_Stage__c = 'Fulfilled';
			update objCarrierOrder;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public void checkQualifyOrder() {
		try {
			blnShowQualifyButton = false;
			//[DS]24-03-2020 Quailification notes is not mandetory
			if (
				objBenefitOrder != null &&
				objBenefitOrder.External_Deductions__c != null &&
				objBenefitOrder.Letters_sent_to_all_carriers__c == true &&
				objBenefitOrder.External_Deductions_for_LiDi__c != null &&
				objBenefitOrder.Useful_docs_in_attachments__c != null &&
				objBenefitOrder.GDrive_Link__c != null &&
				objBenefitOrder.Order_Status__c == strOrderStatus_Qualification
			) {
				blnShowQualifyButton = true;
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
	}

	public PageReference acceptOrder() {
		List<Benefit_Order__c> list_BenefitAcceptOrder = new List<Benefit_Order__c>();
		//get Current BO in list to Qualify
		list_BenefitAcceptOrder.add(objBenefitOrder);
		//Check if Current Benefit order is MUlti EIN or not
		if (objBenefitOrder.Is_Multi_EIN__c == true && objBenefitOrder.Parent_Benefit_Order__c == null) {
			for (Benefit_Order__c bo : [SELECT id, Order_Status__c, UW_Owner__c, RecordTypeId FROM Benefit_Order__c WHERE Parent_Benefit_Order__c = :objBenefitOrder.id]) {
				list_BenefitAcceptOrder.add(bo);
			}
		}
		BenefitOrderHelperFunctions bohfInstance = new BenefitOrderHelperFunctions();
		bohfInstance.setBenefitOrderFields('Benefits BoR', list_BenefitAcceptOrder, true, IdOwner, BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID);

		if (objBenefitOrder.Order_Status__c == strOrderStatus_Qualification && objBenefitOrder.UW_Owner__c != null) {
			blnShowAcceptOrderButton = false;
		} else {
			blnShowAcceptOrderButton = true;
		}
		GetBoDetail();
		return null;
	}

	public PageReference qualifyOrder() {
		try {
			objBenefitOrder.Order_Status__c = strOrderStatus_ReadyDocCollection;
			objBenefitOrder.Qualification_Follow_Up_Date__c = Date.today();
			objBenefitOrder.Start_Date__c = Date.today();
			update objBenefitOrder;
			//Send Intro Email only from parent BO
			//Validate if we need to send intro email BBO-2047
			Id iDBenefitTransferQueue = GlobalQueryHelper.getQueueNameAndIdMap(new Set<String>{ BTBOSideViewCtrl.BENEFIT_TRANSFER_QUEUE }).get(BTBOSideViewCtrl.BENEFIT_TRANSFER_QUEUE);
			if (objBenefitOrder.Parent_Benefit_Order__c == null && objBenefitOrder.OwnerId != iDBenefitTransferQueue) {
				Case objCaseToUpdate = new Case();
				BusinessHours businessHourObj = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE][0];
				Datetime dateAfterFiveBusinessDays = BusinessHours.add(businessHourObj.Id, system.now(), 5 * 8 * 60 * 60 * 1000);

				for (Case objCase : objBenefitOrder.Cases__r) {
					if (objCase.Origin == 'Hippo') {
						objCaseToUpdate = objCase;
						objCaseToUpdate.BT_Notification__c = 'Intro Email';
						objCaseToUpdate.X5_Business_Days_From_Last_Notification__c = dateAfterFiveBusinessDays;
					}
				}
				Boolean blnIsSkipTrigger = CaseTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;
				update objCaseToUpdate;
				CaseTriggerHelper.skipTrigger = blnIsSkipTrigger;
			}
			blnShowQualifyButton = false;
			Cache.displayErrorMessage('Successfully Saved.', ApexPages.Severity.CONFIRM);
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public PageReference saveBO() {
		try {
			List<Carrier_Order__c> list_COsToUpdate = new List<Carrier_Order__c>();
			List<Carrier_Order_Line_Item__c> list_COLIsToUpdate = new List<Carrier_Order_Line_Item__c>();
			MAP<ID, Date> map_COTORenewalDate = new Map<ID, Date>();

			// Updating Carrier Orders for any renewal date changes done on UI
			if (list_CarrierOrderWrapper.size() > 0) {
				for (CarrierOrderWrapper cow : list_CarrierOrderWrapper) {
					map_COTORenewalDate.put(cow.objCarrierOrder.Id, cow.objCarrierOrder.Renewal_Date__c);
					// In case of Customer Signed App
					if (blnCustomerSignedApp == true) {
						cow.objCarrierOrder.Implementation_Stage__c = strOrderStatus_Ready;
						//In BO has only TADA case
						if (objBenefitOrder.Type__c == 'BOR TAdA Only' && cow.objCarrierOrder.Carrier__r.Name == strTADACarrierName) {
							cow.objCarrierOrder.Implementation_Stage__c = strOrderStatus_ReadyDocCollection;
						}
						list_COsToUpdate.add(cow.objCarrierOrder);
					}
				}
			}
			//In case of Advocate View Add Tada carrier Order in list if any
			if (blnIsADV == true && blnShowTADASection == true && objCarrierOrder.Id != null) {
				map_COTORenewalDate.put(objCarrierOrder.id, objCarrierOrder.Renewal_Date__c);
				// In case of Customer Signed App
				if (blnCustomerSignedApp == true) {
					objCarrierOrder.Implementation_Stage__c = strOrderStatus_Ready;
					if (objBenefitOrder.Type__c == 'BOR TAdA Only') {
						objCarrierOrder.Implementation_Stage__c = strOrderStatus_ReadyDocCollection;
					}
					list_COsToUpdate.add(objCarrierOrder);
				}
			}
			//In case of Customer signed no need to run this section

			// Updating Carrier Orders Line Items for any renewal date changes done on UI
			if (blnCustomerSignedApp == false && map_COTORenewalDate.size() > 0) {
				for (Carrier_Order_Line_Item__c colineItem : [SELECT Id, Carrier_Order__c, Renewal_Date__c FROM Carrier_Order_Line_Item__c WHERE Carrier_Order__c IN :map_COTORenewalDate.keyset()]) {
					if (map_COTORenewalDate.get(colineItem.Carrier_Order__c) != colineItem.Renewal_Date__c) {
						colineItem.Renewal_Date__c = map_COTORenewalDate.get(colineItem.Carrier_Order__c);
						list_COLIsToUpdate.add(colineItem);

						if (!UtilitiesFactory.isBTRenewalDateValid(colineItem.Renewal_Date__c)) {
							Cache.displayErrorMessage('Renewal Date must be in the future, within the next year, 1st or 15th of month.', ApexPages.Severity.ERROR);
							return null;
						}
					}
				}
			}
			if (list_COLIsToUpdate.size() > 0) {
				//BY:PR, Date:Oct-15-2020, Desc: Introduce the boolean so that to recalculate the "renewal date" logic
				// as line item trigger code is where we update the "renewal date" on related carrier order
				HICarrierInformationTriggerHelper.isBOInsert = true;
				update list_COLIsToUpdate; //must not skip trigger
				HICarrierInformationTriggerHelper.isBOInsert = false;
			}

			if (objBenefitOrder != null) {
				List<Benefit_Order__c> list_IsBOUpdated = [SELECT ID, Application_Status__c, Order_Status__c FROM Benefit_Order__c WHERE ID = :objBenefitOrder.Id FOR UPDATE];

				//In case of Advocate
				if (blnIsADV == true && objBenefitOrder.Follow_Up_Date__c == null) {
					objBenefitOrder.Follow_Up_Date__c = Date.Today();
				}
				//In case of Pending ER Signature if customer signed app
				if (blnCustomerSignedApp == true) {
					string strOrderStatus = null;
					//In case of only TADA
					if (objBenefitOrder.Type__c == 'BOR TAdA Only') {
						strOrderStatus = strOrderStatus_ReadyDocCollection;
						objBenefitOrder.Start_Date__c = Date.today();
					} else {
						strOrderStatus = strOrderStatus_Ready;
					}
					objBenefitOrder.Order_Status__c = strOrderStatus;
				}
				// SJay - 05/26/2020 - Check if BO has latest order status from any HI Updates that might have happened.
				if (list_IsBOUpdated != null && list_IsBOUpdated.size() > 0 && list_IsBOUpdated.get(0).Order_Status__c != objBenefitOrder.Order_Status__c) {
					objBenefitOrder.Order_Status__c = list_IsBOUpdated.get(0).Order_Status__c;
				}
				list_BOsToUpdate = new List<Benefit_Order__c>();
				list_BOsToUpdate.add(objBenefitOrder);
			}

			if (list_BOsToUpdate.size() > 0) {
				update list_BOsToUpdate;
				Cache.displayErrorMessage('Successfully Saved.', ApexPages.Severity.CONFIRM);
			}
			if (list_COsToUpdate != null && list_COsToUpdate.size() > 0) {
				update list_COsToUpdate;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('BTBOSideViewCtrl', 'saveBO', ex.getMessage(), ex.getStackTraceString());
		}

		return null;
	}

	public class CarrierOrderWrapper {
		public Carrier_Order__c objCarrierOrder { get; set; }
		public Id IdCase { get; set; }
		public String strCaseNumber { get; set; }
	}
	//In case of Multi EIN
	public class BenefitOrderWrapper {
		public Benefit_Order__c objBenefitOrder { get; set; }
		public string strBORelation { get; set; }
		public BenefitOrderWrapper(Benefit_Order__c objBenefitOrder, string BORelation) {
			this.objBenefitOrder = objBenefitOrder;
			this.strBORelation = BORelation;
		}
	}
}