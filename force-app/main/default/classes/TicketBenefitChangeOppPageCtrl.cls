/*
	By: Deepak Tyagi
	Date: Dec 26, 2018
	JIRA # BT-2629
	Desc: Automation for Mid Year Benefit Adds
*/
public class TicketBenefitChangeOppPageCtrl {
	Ticket__c tcktObj;
	public Opportunity oppObj { get; set; }
	public Boolean hasError { get; set; }
	public String oppStage { get; set; }
	public Transition_to_Fulfillment__c objTTFRecord { get; set; }
	public List<OpportunityContactRole> list_OpptyContactRole { get; set; }
	string strBOId;
	string strBOAccountName;
	string strBOAccountHIOwner;
	public string rowIndex { get; set; }
	public list<carrierOrderWrapper> lst_AlegeusCarrierOrderDetails { get; set; }
	public list<carrierOrderWrapper> lst_CarrierOrderDetails { get; set; }
	map<string, map<string, Carrier_Order_Line_Item__c>> map_OriginalCOIdBenefitTypeLineItemDetails = new Map<string, map<string, Carrier_Order_Line_Item__c>>();
	list<SelectOption> lst_TadaBenefitTypeList = new List<SelectOption>();
	list<SelectOption> lst_NONTadaBenefitTypeList = new List<SelectOption>();
	public Boolean isTransferType { get; set; }
	public Boolean isAlegeus { get; set; }
	string strTadaCarrierId;
	public static final string CONTACT_ROLE = Label.Benefits_Admin;
	public List<AlegeusBenefitOrder> lst_Alegeus { get; set; }

	public TicketBenefitChangeOppPageCtrl(apexPages.standardController sc) {
		hasError = false;
		oppStage = 'Closed Won';
		oppObj = new Opportunity();
		objTTFRecord = new Transition_to_Fulfillment__c();
		tcktObj = (Ticket__c) sc.getRecord();
		tcktObj = [
			SELECT Id, Account__c, Account__r.Name, Account__r.HI_Owner__c, Benefit_Order__c, Fulfillment_Case__c, Opportunity__c, Notes__c, OwnerId, Description__c, Status__c, Priority__c
			FROM Ticket__c
			WHERE Id = :tcktObj.Id
		];
		strBOId = tcktObj.Benefit_Order__c;
		strBOAccountName = tcktObj.Account__r.Name;
		strBOAccountHIOwner = tcktObj.Account__r.HI_Owner__c;
		oppObj.Name = 'Benefits Change';
		oppObj.CloseDate = system.today();
		oppObj.AccountId = tcktObj.Account__c;
		oppObj.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Change');
		oppObj.Notes__c = tcktObj.Notes__c;
		oppObj.Description = tcktObj.Description__c;
		oppObj.Amount = 0.0;

		lst_Alegeus = new List<AlegeusBenefitOrder>();
		createAlegeusList();
		lst_NONTadaBenefitTypeList.add(new SelectOption('Dental', 'Dental'));
		lst_NONTadaBenefitTypeList.add(new SelectOption('Vision', 'Vision'));
		lst_NONTadaBenefitTypeList.add(new SelectOption('Life', 'Life'));
		lst_NONTadaBenefitTypeList.add(new SelectOption(Utils.BENEFIT_TYPE_LTD, Utils.BENEFIT_TYPE_LTD));
		lst_NONTadaBenefitTypeList.add(new SelectOption(Utils.BENEFIT_TYPE_STD, Utils.BENEFIT_TYPE_STD));

		lst_TadaBenefitTypeList.add(new SelectOption('HSA', 'HSA'));
		lst_TadaBenefitTypeList.add(new SelectOption('Flexible Spending Account - Medical', 'Flexible Spending Account - Medical'));
		lst_TadaBenefitTypeList.add(new SelectOption('Flexible Spending Account - Dependent Care', 'Flexible Spending Account - Dependent Care'));
		lst_TadaBenefitTypeList.add(new SelectOption('Commuter', 'Commuter'));

		lst_CarrierOrderDetails = new List<carrierOrderWrapper>();
		lst_AlegeusCarrierOrderDetails = new List<carrierOrderWrapper>();
		isTransferType = false;
		isAlegeus = false;
		list<Carrier__c> lst_tempCarrier = [SELECT Id FROM Carrier__c WHERE Name = 'Alegeus' LIMIT 1];
		if (lst_tempCarrier.size() > 0) {
			strTadaCarrierId = lst_tempCarrier.get(0).id;
		}
		map_OriginalCOIdBenefitTypeLineItemDetails = new Map<string, map<string, Carrier_Order_Line_Item__c>>();
	}

	public pageReference navigateToOpportunity() {
		if (tcktObj.Opportunity__c == null) {
			if (tcktObj.OwnerId != userInfo.getuserId()) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This ticket is accessible only by ticket owner.'));
				hasError = true;
			} else {
				oppObj.OwnerId = tcktObj.OwnerId;
			}
			return null;
		} else {
			return new pageReference('/' + tcktObj.Opportunity__c);
		}
	}

	public boolean validateAlegeusCarrierOrderDetails() {
		boolean isValidCarrier = true;
		if (lst_AlegeusCarrierOrderDetails.size() > 0) {
			boolean isLineItemSelected = false;
			String selectedBenefitType = '';
			for (AlegeusBenefitOrder wrapperObj : lst_Alegeus) {
				if (wrapperObj.isChecked == true && wrapperObj.lineItem.Renewal_Date__c == null && wrapperObj.orderName != 'Commuter') {
					isLineItemSelected = true;
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required: TADA Order(s) Renewal Date field.'));
					isValidCarrier = false;
					break;
				}
				if (wrapperObj.isChecked == true) {
					selectedBenefitType = selectedBenefitType + ';' + wrapperObj.orderName;
					isLineItemSelected = true;
				}
			}

			if (isLineItemSelected == false) {
				apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required: TADA Order(s) Benefit Type field.'));
				isValidCarrier = false;
			}

			if (isLineItemSelected == true && isValidCarrier == true) {
				if (String.isNotBlank(selectedBenefitType)) {
					selectedBenefitType = selectedBenefitType.subString(1, selectedBenefitType.length());
				}
				lst_AlegeusCarrierOrderDetails[0].lst_SelectedBenefitType = selectedBenefitType.split(';');
			}
		}
		return isValidCarrier;
	}

	public pageReference savemethod() {
		//If Ticket Do not have account then get account from opp level
		if (string.isBlank(strBOAccountName)) {
			List<Account> lst_tempAccount = [SELECT name, HI_Owner__c FROM Account WHERE id = :oppObj.AccountId LIMIT 1];
			if (lst_tempAccount != null && lst_tempAccount.size() > 0) {
				strBOAccountName = lst_tempAccount[0].Name;
				strBOAccountHIOwner = lst_tempAccount[0].HI_Owner__c;
			}
		}

		if (isTransferType) {
			if (objTTFRecord.Contact__c == null) {
				apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select primary point of contact.'));
				return null;
			}

			Boolean isValidCarrier = validateAlegeusCarrierOrderDetails();
			if (isValidCarrier == false) {
				return null;
			}

			isValidCarrier = validateCarrierOrderDetails();
			if (isValidCarrier == false) {
				return null;
			}
		}

		Benefit_Order__c benObj = null;
		List<Case> caseList = [SELECT Id, Opportunity__c FROM Case WHERE Id = :tcktObj.Fulfillment_Case__c LIMIT 1];
		try {
			oppObj.StageName = 'SAL';
			OpportunityTriggerHelper.skipTrigger = true;
			insert oppObj;
			OpportunityTriggerHelper.skipTrigger = false;
			try {
				if (caseList != null && caseList.size() > 0) {
					CaseTriggerHelper.skipTrigger = true;
					caseList[0].Opportunity__c = oppObj.Id;
					update caseList[0];
					CaseTriggerHelper.skipTrigger = false;
				}
			} catch (Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in Case.'));
				return null;
			}

			if (isTransferType) {
				createRelatedObject();
			}
			List<Benefit_Order__c> lst_BenefitOrder = [SELECT Id, OwnerId, opportunity__c FROM Benefit_Order__c WHERE Opportunity__c = :oppObj.Id LIMIT 1];
			if (lst_BenefitOrder != null && lst_BenefitOrder.size() > 0) {
				benObj = lst_BenefitOrder[0];
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in Opportunity Creation.'));
			return null;
		}

		tcktObj.Opportunity__c = oppObj.Id;
		if (tcktObj.Account__c == null) {
			tcktObj.Account__c = oppObj.AccountId;
		}
		if (benObj != null) {
			tcktObj.Benefit_Order__c = benObj.Id;

			OpportunityTriggerHelper.skipTrigger = true;
			//Close Opportunity and also update OwnerId.
			oppObj.StageName = 'Closed Won';
			oppObj.Benefits_Current_Setup_Step__c = 'Completed';
			oppObj.Order_Generated__c = true;
			String preFix = String.valueOf(benObj.OwnerId).left(3).toLowercase();
			//if the BO Owner is a queue, we need to assign the opportunity to the HI Owner
			if (preFix == '005') {
				oppObj.OwnerId = benObj.OwnerId;
			} else {
				oppObj.OwnerId = strBOAccountHIOwner;
			}
			update oppObj;
			OpportunityTriggerHelper.skipTrigger = false;
		}
		update tcktObj;
		return new pageReference('/' + oppObj.Id);
	}

	public void createRelatedObject() {
		//Create Opportinity Control
		if (isTransferType) {
			OpportunityContactRole oppContactObj = new OpportunityContactRole();
			oppContactObj.OpportunityId = oppObj.Id;
			oppContactObj.ContactId = objTTFRecord.Contact__c;
			oppContactObj.IsPrimary = true;
			oppContactObj.Role = CONTACT_ROLE;

			insert oppContactObj;
		}
		Benefit_Order__c benefitObj = new Benefit_Order__c();
		if (String.isBlank(strBOId)) {
			//If ticket have blank value of "Benefit Order"
			String recordTypeName = ' - ' + 'Benefits BoR';
			benefitObj.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
			benefitObj.Opportunity__c = oppObj.Id;
			benefitObj.Account__c = oppObj.AccountId;
			benefitObj.Name = strBOAccountName.left(80 - recordTypeName.length()) + recordTypeName;
			benefitObj.Order_Status__c = 'Pending ER Signature';
			if ('Transfer TAdA Plan' == oppObj.Type) {
				benefitObj.Qualification_Follow_Up_Date__c = Date.today();
			}

			insert benefitObj;
		}

		if (isTransferType) {
			enabledDisabledContactTrigger(true);
			Contact contactObj = new Contact(Id = objTTFRecord.Contact__c);
			contactObj.Phone = objTTFRecord.Point_of_Contact_Phone__c;
			contactObj.Email = objTTFRecord.Point_of_Contact_Email__c;
			update contactObj;
			enabledDisabledContactTrigger(false);

			lst_CarrierOrderDetails.addAll(lst_AlegeusCarrierOrderDetails);

			if (String.isBlank(strBOId)) {
				//If ticket have blank value of "Benefit Order"
				for (carrierOrderWrapper wrapper : lst_CarrierOrderDetails) {
					wrapper.objCarrierOrder.Benefit_Order__c = benefitObj.Id;
				}
			}
			createCarrierOrders();
		}

		if (String.isBlank(strBOId)) {
			list<Benefit_Order__c> benefitOrderList = new List<Benefit_Order__c>();
			benefitOrderList.add(benefitObj);
			BTAssignmentUtil assignmentObj = new BTAssignmentUtil();
			// SJay - 08/11/2020 - Added boolean parameter to function call
			assignmentObj.processBOForAdvocateAssignment(benefitOrderList, false);
			update benefitOrderList;
		}
	}

	public void enabledDisabledContactTrigger(Boolean flag) {
		ContactTriggerHelper.skipTrigger = flag;
		AccountTriggerHelper.skipTrigger = flag;
	}

	public void createAlegeusList() {
		lst_Alegeus.clear();
		lst_Alegeus.add(new AlegeusBenefitOrder(false, 'HSA', new Carrier_Order_Line_Item__c()));
		lst_Alegeus.add(new AlegeusBenefitOrder(false, 'Flexible Spending Account - Medical', new Carrier_Order_Line_Item__c()));
		lst_Alegeus.add(new AlegeusBenefitOrder(false, 'Flexible Spending Account - Dependent Care', new Carrier_Order_Line_Item__c()));
		lst_Alegeus.add(new AlegeusBenefitOrder(false, 'Commuter', new Carrier_Order_Line_Item__c()));
	}

	public void checkBenefitType() {
		createAlegeusList();
		lst_CarrierOrderDetails.clear();
		lst_AlegeusCarrierOrderDetails.clear();
		objTTFRecord.Contact__c = null;
		objTTFRecord.Point_of_Contact_Phone__c = '';
		objTTFRecord.Point_of_Contact_Email__c = '';

		if ('Transfer TAdA Plan' == oppObj.Type || 'Transfer Ancillary Coverage' == oppObj.Type || 'Transfer TAdA and Ancillary Coverage' == oppObj.Type) {
			isTransferType = true;
			getCarrierOrderDetails();
			Boolean isAlegeusCarrierExist = false;
			if ('Transfer TAdA Plan' == oppObj.Type) {
				isAlegeus = true;
				addNewTadaRow();
				lst_AlegeusCarrierOrderDetails[0].lst_UnSelectedBenefitType = lst_TadaBenefitTypeList;
				lst_AlegeusCarrierOrderDetails[0].objCarrierOrder.Carrier__c = strTadaCarrierId;
				lst_AlegeusCarrierOrderDetails[0].isAlegeusRecord = true;
				lst_AlegeusCarrierOrderDetails[0].isFirstRecord = true;
			} else {
				Boolean isTadaAndAncillary = false;
				if ('Transfer TAdA and Ancillary Coverage' == oppObj.Type) {
					isTadaAndAncillary = true;
					addNewTadaRow();
					lst_AlegeusCarrierOrderDetails[0].objCarrierOrder.Carrier__c = strTadaCarrierId;
					lst_AlegeusCarrierOrderDetails[0].lst_UnSelectedBenefitType = lst_TadaBenefitTypeList;
					lst_AlegeusCarrierOrderDetails[0].isAlegeusRecord = true;
					lst_AlegeusCarrierOrderDetails[0].isFirstRecord = true;
				}
				addNewRow();
				if (isTadaAndAncillary == false) {
					lst_CarrierOrderDetails[0].isFirstRecord = true;
				}
				isAlegeus = false;
			}
		} else {
			isTransferType = false;
			isAlegeus = false;
			lst_CarrierOrderDetails.clear();
			lst_AlegeusCarrierOrderDetails.clear();
		}
	}

	//This method is used id user wants to delete a newly introduced [Carrier Order] row
	public void removeNewRow() {
		if (string.isNotBlank(rowIndex) && lst_CarrierOrderDetails.size() > Integer.valueOf(rowIndex)) {
			if (lst_CarrierOrderDetails.get(Integer.valueOf(rowIndex)).objCarrierOrder.Id != null) {
				apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Fatal Error: Can not delete old carrier orders.'));
				return;
			}
			lst_CarrierOrderDetails.remove(Integer.valueOf(rowIndex));
			rowIndex = '';
		} else {
			apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Fatal Error: Page not loaded properly refresh the page and try again.'));
		}
	}

	public void fetchBenefitType() {
		if (string.isNotBlank(rowIndex) && lst_CarrierOrderDetails.size() > Integer.valueOf(rowIndex)) {
			Integer iIndex = Integer.valueOf(rowIndex);
			if (lst_CarrierOrderDetails[iIndex].objCarrierOrder.Carrier__c == strTadaCarrierId) {
				lst_CarrierOrderDetails[iIndex].lst_UnSelectedBenefitType = lst_TadaBenefitTypeList;
			} else {
				lst_CarrierOrderDetails[iIndex].lst_UnSelectedBenefitType = lst_NONTadaBenefitTypeList;
			}

			if (objTTFRecord.Contact__c != null && String.isBlank(objTTFRecord.Point_of_Contact_Email__c)) {
				fetchPrimaryContact();
			}
		}
	}

	public void fetchPrimaryContact() {
		if (objTTFRecord.Contact__c != null) {
			List<Contact> contactList = [SELECT id, Phone, Email FROM Contact WHERE Id = :objTTFRecord.Contact__c];
			if (contactList.size() > 0) {
				objTTFRecord.Point_of_Contact_Phone__c = contactList[0].Phone;
				objTTFRecord.Point_of_Contact_Email__c = contactList[0].Email;
			}
		}
	}

	/**This method is called when user wants to introduce a new CO records via VF page */
	public void addNewRow() {
		carrierOrderWrapper newInstance = new carrierOrderWrapper();
		newInstance.objCarrierOrder = new Carrier_Order__c();
		newInstance.objCarrierOrder.Benefit_Order__c = strBOId;
		newInstance.objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		newInstance.objCarrierOrder.Implementation_Stage__c = 'Pending ER Signature';
		lst_CarrierOrderDetails.add(newInstance);
	}

	/**This method is called when user wants to introduce a new CO records via VF page */
	public void addNewTadaRow() {
		carrierOrderWrapper newInstance = new carrierOrderWrapper();
		newInstance.objCarrierOrder = new Carrier_Order__c();
		newInstance.objCarrierOrder.Benefit_Order__c = strBOId;
		newInstance.objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		newInstance.objCarrierOrder.Implementation_Stage__c = 'Pending ER Signature';
		lst_AlegeusCarrierOrderDetails.add(newInstance);
	}

	public boolean validateCarrierOrderDetails() {
		boolean isValidCarrier = true;
		if (lst_CarrierOrderDetails.size() > 0) {
			set<String> set_CarrierOrderIds = new Set<String>();
			Boolean isAlegeusRecordExist = false;

			for (carrierOrderWrapper wrapperInstance : lst_CarrierOrderDetails) {
				if (wrapperInstance.objCarrierOrder.Carrier__c == strTadaCarrierId) {
					isAlegeusRecordExist = true;
				}

				if ('Transfer TAdA and Ancillary Coverage' == oppObj.Type && isAlegeusRecordExist == true) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'TADA carrier is now allowed in  ancillary coverage section.'));
					isValidCarrier = false;
					break;
				} else if (set_CarrierOrderIds.contains(wrapperInstance.objCarrierOrder.Carrier__c)) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Duplicate Records: Same carrier not allowed.'));
					isValidCarrier = false;
					break;
				} else if (wrapperInstance.lst_SelectedBenefitType.size() == 0) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required: Benefit Type field.'));
					isValidCarrier = false;
					break;
				} else if (wrapperInstance.objCarrierOrder.Renewal_Date__c == null) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required: Renewal Date field.'));
					isValidCarrier = false;
					break;
				} else if (wrapperInstance.objCarrierOrder.Carrier__c == null) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required: Carrier Name field.'));
					isValidCarrier = false;
					break;
				}

				//by:PR, Jira:https://app.asana.com/0/1149920908637905/1170649748837574/f
				if (wrapperInstance.objCarrierOrder.Renewal_Date__c != null && !UtilitiesFactory.isBTRenewalDateValid(wrapperInstance.objCarrierOrder.Renewal_Date__c)) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Renewal Date must be in the future, within the next year, 1st or 15th of month.'));
					isValidCarrier = false;
					break;
				}

				set_CarrierOrderIds.add(wrapperInstance.objCarrierOrder.Carrier__c);
			}

			if ('Transfer Ancillary Coverage' == oppObj.Type && isAlegeusRecordExist == true) {
				apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Tada is not allowed for this type of opportunity.'));
				isValidCarrier = false;
			}
		} else {
			if (lst_AlegeusCarrierOrderDetails.size() == 0) {
				apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No record found.'));
				isValidCarrier = false;
			}
		}
		return isValidCarrier;
	}

	/**This method is processing and updating the database using user provided details via Vf page */
	public Pagereference createCarrierOrders() {
		/**If page does not have any messages following code is processing the [Carrier Order] wrapper details */
		if (lst_CarrierOrderDetails.size() > 0) {
			list<Carrier_Order_Line_Item__c> lst_NewLineItems = new List<Carrier_Order_Line_Item__c>();
			list<Carrier_Order_Line_Item__c> lst_TODeleteLineItems = new List<Carrier_Order_Line_Item__c>();
			map<string, Carrier_Order__c> map_CarrierIdNewCarrierOrders = new Map<string, Carrier_Order__c>();

			for (carrierOrderWrapper wrapperInstance : lst_CarrierOrderDetails) {
				//code to handle newly added CO
				if (wrapperInstance.objCarrierOrder.Id == null) {
					map_CarrierIdNewCarrierOrders.put(wrapperInstance.objCarrierOrder.Carrier__c, wrapperInstance.objCarrierOrder);
					continue;
				}

				//following code is handling [Benefit Type] mods introduced by the user via VF Page
				Carrier_Order__c objCarrierOrder = wrapperInstance.objCarrierOrder;
				if (objCarrierOrder.Id != null) {
					set<string> set_BenefitTypeProcessed = new Set<string>();

					for (string strBenefitType : wrapperInstance.lst_SelectedBenefitType) {
						if (!map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).containsKey(strBenefitType)) {
							if (wrapperInstance.isAlegeusRecord) {
								Carrier_Order_Line_Item__c lineItem = new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenefitType);
								lineItem.Renewal_Date__c = getRenewalDate(strBenefitType);
								lst_NewLineItems.add(lineItem);
							} else {
								lst_NewLineItems.add(
									new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenefitType, Renewal_Date__c = objCarrierOrder.Renewal_Date__c)
								);
							}
						} else {
							set_BenefitTypeProcessed.add(strBenefitType);
						}
					}
					if (set_BenefitTypeProcessed.size() != map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).size()) {
						for (string strBT : map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).keyset()) {
							if (!set_BenefitTypeProcessed.contains(strBT)) {
								lst_TODeleteLineItems.add(map_OriginalCOIdBenefitTypeLineItemDetails.get(objCarrierOrder.Id).get(strBT));
							}
						}
					}
				}
			}

			/**Following code is handling newly introduced [Carrier Order] creation and related [Carrier Order lIne Item] creation */
			if (map_CarrierIdNewCarrierOrders.size() > 0) {
				for (Carrier__c objCarrier : [SELECT id, Name FROM Carrier__c WHERE Id IN :map_CarrierIdNewCarrierOrders.Keyset()]) {
					//DS[21-05-2020]:- add check for 80 charcter limit
					if (String.isNotBlank(strBOAccountName)) {
						String strCarrierOrderName = strBOAccountName + ' - ' + objCarrier.Name;
						if (strCarrierOrderName.length() > 80) {
							strCarrierOrderName = objCarrier.Name + ' Order';
						}
						map_CarrierIdNewCarrierOrders.get(objCarrier.Id).Name = strCarrierOrderName;
					}
				}

				try {
					insert map_CarrierIdNewCarrierOrders.values();
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Records Successfully Updated.'));
				} catch (exception ex) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
					return null;
				}

				for (carrierOrderWrapper wrapperInstance : lst_CarrierOrderDetails) {
					if (map_CarrierIdNewCarrierOrders.containsKey(wrapperInstance.objCarrierOrder.Carrier__c)) {
						Carrier_Order__c objCarrierOrder = map_CarrierIdNewCarrierOrders.get(wrapperInstance.objCarrierOrder.Carrier__c);

						for (string strBenefitType : wrapperInstance.lst_SelectedBenefitType) {
							if (wrapperInstance.isAlegeusRecord) {
								Carrier_Order_Line_Item__c lineItem = new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenefitType);
								lineItem.Renewal_Date__c = getRenewalDate(strBenefitType);
								lst_NewLineItems.add(lineItem);
							} else {
								lst_NewLineItems.add(
									new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenefitType, Renewal_Date__c = objCarrierOrder.Renewal_Date__c)
								);
							}
						}
					}
				}
			}

			/**Following code is handling new [ carrier Order line Item] creation and deletion */
			if (lst_NewLineItems.size() > 0 || lst_TODeleteLineItems.size() > 0) {
				try {
					if (lst_NewLineItems.size() > 0)
						insert lst_NewLineItems;
					if (lst_TODeleteLineItems.size() > 0)
						delete lst_TODeleteLineItems;
					getCarrierOrderDetails();
					if (lst_CarrierOrderDetails.get(0).objCarrierOrder.Benefit_Order__r.Qualification_Follow_Up_Date__c != null) {
						//{DS}24-03-2020 update the wrapper with rollup Number of Document and Total Doc
						for (carrierOrderWrapper wrapperInstance : lst_CarrierOrderDetails) {
							if (!string.valueof(wrapperInstance.objCarrierOrder.OwnerId).startsWith('005')) {
								map_CarrierIdNewCarrierOrders.put(wrapperInstance.objCarrierOrder.Carrier__c, wrapperInstance.objCarrierOrder);
								continue;
							}
						}
						CarrierOrderFacilitatorAssignment(map_CarrierIdNewCarrierOrders.values());
					}

					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Records Successfully Updated.'));

					return new Pagereference('/' + strBOId);
				} catch (exception ex) {
					apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
					return null;
				}
			}
		}

		return null;
	}

	// @TestVisible
	void CarrierOrderFacilitatorAssignment(list<Carrier_Order__c> list_NewCarrierOrders) {
		if (list_NewCarrierOrders == null || list_NewCarrierOrders.size() == 0) {
			return;
		}

		list<Carrier_Order__c> list_NonTadaCOs = new List<Carrier_Order__c>();
		list<Carrier_Order__c> list_TadaCOs = new List<Carrier_Order__c>();

		for (Carrier_Order__c objCO : list_NewCarrierOrders) {
			if (objCO.Carrier__c == strTadaCarrierId) {
				list_TadaCOs.add(objCO);
			} else {
				list_NonTadaCOs.add(objCO);
			}
		}

		if (list_NonTadaCOs.size() > 0 || list_TadaCOs.size() > 0) {
			BTAssignmentUtil objBTFacilitatorAssignement = new BTAssignmentUtil();
			List<Carrier_Order__c> lst_COWithFAC1Owner = objBTFacilitatorAssignement.processCOForFacilitator1Assignment(list_NonTadaCOs, list_TadaCOs);

			update lst_COWithFAC1Owner;
		}
	}

	/**This method is querying "Carrier Orders" using the related "Benefit Order" Id retrieved from the page url*/
	void getCarrierOrderDetails() {
		if (string.isNotBlank(strBOId)) {
			lst_CarrierOrderDetails = new List<carrierOrderWrapper>();
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
					Benefit_Order__r.Account__r.HI_Owner__c,
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
					(SELECT Id, Renewal_Date__c, Benefit_Types__c FROM Carrier_Order_Line_Item__r)
				FROM Carrier_Order__c
				WHERE Benefit_Order__c = :strBOId AND Implementation_Stage__c NOT IN :set_ToExcludeOrderStatus
			]) {
				carrierOrderWrapper wrapperInstance = new carrierOrderWrapper();
				wrapperInstance.objCarrierOrder = objCO;

				//populating master picklist option list
				if (objCO.Carrier__r.Name == 'Alegeus')
					wrapperInstance.lst_UnSelectedBenefitType = lst_TadaBenefitTypeList;
				else
					wrapperInstance.lst_UnSelectedBenefitType = lst_NONTadaBenefitTypeList;

				//populating already present Benefit type picklist option list
				if (objCO.Carrier_Order_Line_Item__r != null && objCO.Carrier_Order_Line_Item__r.size() > 0) {
					map<string, Carrier_Order_Line_Item__c> map_benefitTypeLI = new Map<string, Carrier_Order_Line_Item__c>();

					for (Carrier_Order_Line_Item__c objLI : objCO.Carrier_Order_Line_Item__r) {
						map_benefitTypeLI.put(objLI.Benefit_Types__c, objLI);
					}

					if (map_benefitTypeLI.size() > 0) {
						wrapperInstance.lst_SelectedBenefitType.addAll(map_benefitTypeLI.keyset());
					}

					map_OriginalCOIdBenefitTypeLineItemDetails.put(objCO.Id, map_benefitTypeLI);
				}

				if (string.isBlank(strBOAccountName))
					strBOAccountName = objCO.Benefit_Order__r.Account__r.Name;
					strBOAccountHIOwner = objCO.Benefit_Order__r.Account__r.HI_Owner__c;
				lst_CarrierOrderDetails.add(wrapperInstance);
			}
		}
	}

	public Date getRenewalDate(String benefitType) {
		Date dateObj = null;
		if ('HSA' == benefitType) {
			dateObj = lst_Alegeus[0].lineItem.Renewal_Date__c;
		} else if ('Flexible Spending Account - Medical' == benefitType) {
			dateObj = lst_Alegeus[1].lineItem.Renewal_Date__c;
		} else if ('Flexible Spending Account - Dependent Care' == benefitType) {
			dateObj = lst_Alegeus[2].lineItem.Renewal_Date__c;
		}
		return dateObj;
	}

	/**This wrapper is used to show the data on the VF page */
	public class carrierOrderWrapper {
		public Carrier_Order__c objCarrierOrder { get; set; }
		public list<SelectOption> lst_UnSelectedBenefitType { get; set; }
		public list<string> lst_SelectedBenefitType { get; set; }
		public boolean isAlegeusRecord { get; set; }
		public boolean isFirstRecord { get; set; }
		public carrierOrderWrapper() {
			isAlegeusRecord = false;
			isFirstRecord = false;
			objCarrierOrder = new Carrier_Order__c();
			lst_UnSelectedBenefitType = new List<SelectOption>();
			lst_SelectedBenefitType = new List<string>();
		}
	}

	public class AlegeusBenefitOrder {
		public boolean isChecked { get; set; }
		public String orderName { get; set; }
		public Carrier_Order_Line_Item__c lineItem { get; set; }
		public AlegeusBenefitOrder(boolean isChecked, String orderName, Carrier_Order_Line_Item__c lineItem) {
			this.isChecked = isChecked;
			this.orderName = orderName;
			this.lineItem = lineItem;
		}
	}
}