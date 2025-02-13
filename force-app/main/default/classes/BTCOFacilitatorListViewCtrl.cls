/**
 * @name         BTCOFacilitatorSideViewCtrl
 * @author       Anand Singh
 * @date         25-02-2020
 * @description
 **/

public class BTCOFacilitatorListViewCtrl {
	public Id idOwnerId { get; set; }
	public Boolean blnIsFAC1 { get; set; }
	public Boolean blnIsFAC2 { get; set; }
	static String strROLE_BT_FAC1 = 'Benefit Transfer Facilitator 1';
	static String strROLE_BT_FAC2 = 'Benefit Transfer Facilitator 2';
	static String strCO_STAGE_COLLECTING_DOCUMENTS = 'Collecting Documents';
	static String strCO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS = 'Enrollment Review Entry in Progress'; // Enrollment Review
	static String strCO_STAGE_IMPLEMENTATION_PLANS = 'Implementing Plans'; // Plan Review
	public set<string> set_Include = new Set<string>{ 'Ready for Document Collection', 'Collecting Documents' };
	//For carriers
	public list<System.SelectOption> list_UnselectedCarrier { get; set; }
	public list<String> list_SelectedCarrier { get; set; }
	//For States
	public list<System.SelectOption> list_UnselectedState { get; set; }
	public list<String> list_SelectedState { get; set; }
	//For Stages
	public list<System.SelectOption> list_UnselectedStage { get; set; }
	public list<String> list_SelectedStage { get; set; }
	//For Filters
	public string strFromAge { get; set; }
	public string strToAge { get; set; }
	public string strTotalDoc { get; set; }
	public string strDocCollectedPercentage { get; set; }
	//For Tickets
	public list<TicketWrapper> list_TicketWrapper { get; set; }
	//For Carrier Orders
	public list<CarrierOrderWrapper> list_CarrierOrderWrapper { get; set; }
	public list<CarrierOrderWrapper> list_CarrierOrderOOOWrapper { get; set; }
	public set<string> setExclude = Utils.setCOExclude;
	private Map<string, Set<string>> map_carrierState;
	static string strBORRecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');

	public BTCOFacilitatorListViewCtrl() {
		idOwnerId = UserInfo.getUserId();
		blnIsFAC1 = false;
		blnIsFAC2 = false;
		getUserData();
	}

	public PageReference RefreshFacPanel() {
		if (blnIsFAC1) {
			map_carrierState = new Map<string, Set<string>>();
			PopulateSearchPanel();
			SearchCarrierOrder();
			//Retrive Ticket
			RetriveTicket();
		}
		if (blnIsFAC2 && !blnIsFAC1) {
			PageReference redirectToFac2 = new PageReference('/apex/BTCOFacilitator2ListView');
			redirectToFac2.setRedirect(true);
			return redirectToFac2;
		}
		return null;
	}

	public PageReference RefreshFacOOOPanel() {
		RetriveCOForOOO();
		return null;
	}

	public void getUserData() {
		Set<String> set_CurrentUserRoles = new Set<String>();
		set_CurrentUserRoles = UtilitiesFactory.RetriveUserRole(idOwnerId);
		if (!set_CurrentUserRoles.isEmpty() && set_CurrentUserRoles.contains(strROLE_BT_FAC1)) {
			blnIsFAC1 = true;
		}
		if (!set_CurrentUserRoles.isEmpty() && set_CurrentUserRoles.contains(strROLE_BT_FAC2)) {
			blnIsFAC2 = true;
		}
	}

	private void PopulateSearchPanel() {
		//Initliaze values
		map_carrierState = new Map<string, Set<string>>();
		list_UnselectedCarrier = new List<System.SelectOption>();
		list_SelectedCarrier = new List<String>();
		list_UnselectedState = new List<System.SelectOption>();
		list_SelectedState = new List<String>();

		list_UnselectedStage = new List<System.SelectOption>();
		list_SelectedStage = new List<String>();
		
		List<Carrier_Order__c> lstCarrierOrder = [
			SELECT id, Carrier__c, Carrier__r.Name, Carrier__r.State__c, Ownerid, Implementation_Stage__c,TAdA__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND RecordTypeId = :strBORRecordTypeId
				AND Implementation_Stage__c NOT IN :setExclude
				AND TAdA__c = false
				AND (Implementation_Stage__c IN :set_Include
				OR Percent_Of_Documents_Completed__c < 100)
				AND ownerid = :idOwnerId
			ORDER BY Carrier__r.Name
			LIMIT 1000
		];
		
		//To Add Unique value
		Set<string> set_Carrier = new Set<string>();
		Set<string> set_State = new Set<string>();
		Set<string> set_Stage = new Set<string>();
		
		for (Carrier_Order__c co : lstCarrierOrder) {
			string strCarrierName = '';
			// SJay - 05/21/2020 - Added Null checks for carrier name and state
			if (co.Carrier__c != null && co.Carrier__r.Name != null)
				strCarrierName = co.Carrier__r.Name.Trim();
			string strCarrierState = '';
			if (co.Carrier__c != null && co.Carrier__r.State__c != null)
				strCarrierState = co.Carrier__r.State__c.Trim();
			if (map_carrierState.containsKey(strCarrierName)) {
				map_carrierState.get(strCarrierName).add(strCarrierState);
			} else {
				map_carrierState.put(strCarrierName, new Set<string>{ strCarrierState });
			}

			if (set_Carrier.contains(strCarrierName) == false) {
				//Change value from Id to name beacue due to state duplicate value was coming
				list_UnselectedCarrier.add(new SelectOption(strCarrierName, strCarrierName));
				set_Carrier.add(strCarrierName);
			}
			if (set_State.contains(strCarrierState) == false) {
				list_UnselectedState.add(new SelectOption(strCarrierState, strCarrierState));
				set_State.add(strCarrierState);
			}
			
			if (co.Implementation_Stage__c != null && set_Stage.contains(co.Implementation_Stage__c) == false) {
				list_UnselectedStage.add(new SelectOption(co.Implementation_Stage__c, co.Implementation_Stage__c));
				set_Stage.add(co.Implementation_Stage__c);
			}
		}
	}
	public PageReference PopulateState() {
		list_UnselectedState = new List<System.SelectOption>();
		list_SelectedState = new List<String>();
		if (list_SelectedCarrier != null && list_SelectedCarrier.size() > 0 && map_carrierState != null && map_carrierState.size() > 0) {
			Set<string> set_UniqueState = new Set<string>();
			for (string strCarrier : list_SelectedCarrier) {
				//get State of All Selected carrier
				if (map_carrierState.get(strCarrier) != null && map_carrierState.get(strCarrier).size() > 0) {
					for (string strState : map_carrierState.get(strCarrier)) {
						if (set_UniqueState.contains(strState) == false) {
							list_UnselectedState.add(new SelectOption(strState, strState));
							set_UniqueState.add(strState);
						}
					}
				}
			}
			set_UniqueState = new Set<string>();
		}
		return null;
	}

	//If the logged in user is a facilitator 1,
	//their OOO view should only show orders in "Collecting Documents" status.
	//If the logged in user is a Facilitator 2,
	//their OOO view should only show orders in "Implementing Plans" and "Enrollment Review Entry in Progress" statuses.
	public string formQuery() {
		string strQuery = 'select id,Number_Of_Collected_Documents__c,Total_Number_Of_Documents__c,Parent_Carrier_Order__c,Parent_Carrier_Order__r.Name,Initial_Owner__c,Name,OwnerId,Is_Multi_EIN__c,Carrier__r.Name,Carrier__r.State__c,Carrier__r.BT_Facilitator_POD__c,';
		strQuery += ' Start_Date__c,Implementation_Stage__c,Initial_Owner__r.Name,OOO_Comments__c,OOO_Timestamp__c,Facilitator_2_Enrollment_Review__c,Facilitator_2_Plan_Review__c';
		strQuery += ' from Carrier_Order__c';
		strQuery += ' where Benefit_Order__c!=null and Renewal_Date__c!=null and RecordTypeId=:strBORRecordTypeId';
		strQuery += ' and TAdA__c = false';

		if (blnIsFAC1 && blnIsFAC2) {
			strQuery += ' and ((Implementation_Stage__c not in:setExclude';
			//strQuery += ' and (Implementation_Stage__c in:set_Include or (Checklist_For_Plan_Build__c=false or Checklist_For_Enrollment_Review__c=false))';
			strQuery += ' and (Implementation_Stage__c in:set_Include or Percent_Of_Documents_Completed__c<100))';
			strQuery += ' and ownerid = :idOwnerId)';
			strQuery += ' OR';
			strQuery += ' ((Implementation_Stage__c = :strCO_STAGE_IMPLEMENTATION_PLANS or Implementation_Stage__c = :strCO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS)';
			strQuery += ' and (Facilitator_2_Enrollment_Review__c=:idOwnerId or Facilitator_2_Plan_Review__c=:idOwnerId)))';
		} else if (!blnIsFAC2) {
			strQuery += ' and Implementation_Stage__c not in:setExclude';
			//strQuery += ' and (Implementation_Stage__c in:set_Include or (Checklist_For_Plan_Build__c=false or Checklist_For_Enrollment_Review__c=false))';
			strQuery += ' and (Implementation_Stage__c in:set_Include or Percent_Of_Documents_Completed__c<100)';
			strQuery += ' and ownerid = :idOwnerId';
		} else if (blnIsFAC2) {
			strQuery += ' and (Implementation_Stage__c = :strCO_STAGE_IMPLEMENTATION_PLANS or Implementation_Stage__c = :strCO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS)';
			strQuery += ' and (Facilitator_2_Enrollment_Review__c=:idOwnerId or Facilitator_2_Plan_Review__c=:idOwnerId)';
		}

		return strQuery;
	}

	private void RetriveCOForOOO() {
		list_CarrierOrderOOOWrapper = new List<CarrierOrderWrapper>();
		try {
			string strQuery = formQuery();
			List<Carrier_Order__c> lstCarrierOrder = database.query(strQuery);
			if (lstCarrierOrder != null && lstCarrierOrder.size() > 0) {
				for (Carrier_Order__c co : lstCarrierOrder) {
					CarrierOrderWrapper cow = new CarrierOrderWrapper();
					cow.objCarrierOrder = co;
					cow.blnReAssign = false;
					if (co.OOO_Comments__c != null) {
						cow.blnReAssign = true;
					}
					list_CarrierOrderOOOWrapper.add(cow);
				}
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no carrier order(s) available for assignment'));
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
	}
	public PageReference SearchCarrierOrder() {
		try {
			list_CarrierOrderWrapper = new List<CarrierOrderWrapper>();
			
			string strQuery = 'select id,Facilitator_1_Notes__c,Parent_Carrier_Order__c,Parent_Carrier_Order__r.Name,Initial_Owner__c,';
			strQuery = strQuery + ' Initial_Owner__r.Name,OOO_Comments__c,Carrier__c,Name,Renewal_Date__c,Carrier__r.Name,';
			strQuery = strQuery + ' 	Carrier__r.State__c,Implementation_Stage__c,';
			strQuery = strQuery + ' Benefit_Order__c,Benefit_Order__r.name,Benefit_Order__r.Age__c,';
			strQuery = strQuery + ' Total_Number_Of_Documents__c,Percent_Of_Documents_Completed__c,';
			strQuery = strQuery + ' Number_Of_Collected_Documents__c,Total_No_Of_Docs_Required_to_Collect__c, ';
			strQuery = strQuery + ' (Select Id,Name,Status__c From Tickets__r where Status__c!=\'Closed\'),';
			strQuery = strQuery + ' (SELECT Id, CaseNumber FROM Cases__r WHERE Status <> \'Closed\' and Requires_Action__c=true LIMIT 1) from ';
			strQuery = strQuery + ' Carrier_Order__c where Benefit_Order__c!=null and Renewal_Date__c!=null and';
			strQuery = strQuery + '  RecordTypeId=:strBORRecordTypeId and Implementation_Stage__c not in:setExclude';
			strQuery = strQuery + '  and TAdA__c = false and (Implementation_Stage__c in:set_Include';
			strQuery = strQuery + ' or Percent_Of_Documents_Completed__c<100)';
			strQuery = strQuery + ' and ownerid=:idOwnerId ';

			//By AKS dated 8th Oct 2020 https://app.asana.com/0/1195411211351298/1188883535551265
			//strQuery = strQuery + ' or (Checklist_For_Plan_Build__c=false or Checklist_For_Enrollment_Review__c=false))';

			if (string.isNotBlank(strFromAge)) {
				integer ageFrom = integer.valueof(strFromAge);
				strQuery = strQuery + ' and Benefit_Order__r.Age__c >=:ageFrom';
			}
			if (string.isNotBlank(strToAge)) {
				integer ageTo = integer.valueof(strToAge);
				strQuery = strQuery + ' and Benefit_Order__r.Age__c <=:ageTo';
			}
			if (string.isNotBlank(strTotalDoc)) {
				integer totalDoc = integer.valueof(strTotalDoc);
				strQuery = strQuery + ' and Total_No_Of_Docs_Required_to_Collect__c =:totalDoc';
			}
			if (string.isNotBlank(strDocCollectedPercentage)) {
				integer percentageDoc = integer.valueof(strDocCollectedPercentage);
				strQuery = strQuery + ' and Percent_Of_Documents_Completed__c =:percentageDoc';
			}
			if (!list_SelectedCarrier.isEmpty()) {
				strQuery += ' and  Carrier__r.Name in :list_SelectedCarrier';
			}

			if (!list_SelectedState.isEmpty()) {
				strQuery += ' and  Carrier__r.State__c in :list_SelectedState';
			}

			if (!list_SelectedStage.isEmpty()) {
				strQuery += ' and  Implementation_Stage__c in : list_SelectedStage';
			}
			strQuery = strQuery + ' order by Renewal_Date__c asc , Benefit_Order__r.Age__c desc limit 1000';

			List<Carrier_Order__c> lstCarrierOrder = database.query(strQuery);
			if (lstCarrierOrder != null && lstCarrierOrder.size() > 0) {
				for (Carrier_Order__c co : lstCarrierOrder) {
					CarrierOrderWrapper cow = new CarrierOrderWrapper();
					cow.objCarrierOrder = co;
					cow.strRenewalStyleClass = null;
					cow.strTicketStyleClass = null;
					cow.strCaseId = null;
					cow.strCaseNumber = null;
					cow.strTicketId = null;
					cow.strTicketNumber = null;
					cow.strInitialOwner = null;
					if (co.Initial_Owner__c != null && co.Initial_Owner__c != idOwnerId) {
						cow.strInitialOwner = co.Initial_Owner__r.Name;
					}
					if (co.Cases__r != null && co.Cases__r.size() > 0) {
						Case cs = co.Cases__r[0];
						cow.strCaseId = cs.id;
						cow.strCaseNumber = cs.CaseNumber;
					}
					if (co.Tickets__r != null && co.Tickets__r.size() > 0) {
						Ticket__c objTicket = co.Tickets__r[0];
						cow.strTicketId = objTicket.id;
						cow.strTicketNumber = objTicket.Name;
						cow.strTicketStyleClass = 'bg-red';
					}
					if (co.Renewal_Date__c != null) {
						cow.strRenewalDate = string.valueOf(co.Renewal_Date__c);
						integer intDaysDiff = Date.Today().daysBetween(co.Renewal_Date__c);
						if (intDaysDiff < 80) {
							cow.strRenewalStyleClass = 'bg-yellow';
						}
					}

					list_CarrierOrderWrapper.add(cow);
				}
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no carrier order(s) availble.Kindly change search filters'));
				return null;
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public PageReference SaveOOONotes() {
		try {
			SaveOOO();
			Cache.displayErrorMessage('Successfully Saved.', ApexPages.Severity.CONFIRM);
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	private void SaveOOO() {
		if (list_CarrierOrderOOOWrapper != null && list_CarrierOrderOOOWrapper.size() > 0) {
			List<Carrier_Order__c> lstCarrierOrder = new List<Carrier_Order__c>();
			for (CarrierOrderWrapper cow : list_CarrierOrderOOOWrapper) {
				lstCarrierOrder.add(cow.objCarrierOrder);
			}
			
			if (lstCarrierOrder != null && lstCarrierOrder.size() > 0) {
				boolean blnSkipOldval = CarrierOrderTriggerHelper.skipTrigger;
				CarrierOrderTriggerHelper.skipTrigger = true;
				update lstCarrierOrder;
				CarrierOrderTriggerHelper.skipTrigger = blnSkipOldval;
			}
		}
	}

	public PageReference ReasignBOOnOOO() {
		try {
			SaveOOO();
			boolean blnSkipOldval = CarrierOrderTriggerHelper.skipTrigger;
			CarrierOrderTriggerHelper.skipTrigger = true;

			//get All carrier order where we have out of the office notes
			List<Carrier_Order__c> list_CarrierOrderTemp = new List<Carrier_Order__c>();
			List<Carrier_Order__c> list_CarrierOrderOOOFAC1 = new List<Carrier_Order__c>();
			List<Carrier_Order__c> list_CarrierOrderOOOFAC2 = new List<Carrier_Order__c>();

			string strQuery = formQuery();
			strQuery += ' AND OOO_Comments__c != null';
			list_CarrierOrderTemp = database.query(strQuery);

			if (list_CarrierOrderTemp.size() != list_CarrierOrderOOOWrapper.size()) {
				Cache.displayErrorMessage('Please mark all and provide OOO Notes before reasign', ApexPages.Severity.ERROR);
			} else {
				//Mark Out of the office
				Boolean blnUserSkipTriger = UserTriggerHelper.skipTrigger;
				UserTriggerHelper.skipTrigger = true;
				User objUser = new User(id = userinfo.getuserid());
				objUser.Out_Of_Office__c = true;
				update objUser;
				UserTriggerHelper.skipTrigger = blnUserSkipTriger;
				// Going through the list of COs from OOO view and depending on orders stage and ownership
				// we kick the assignment logic for FAC1 orders or set the OOO timestamp for FAC2 orders.
				for (Carrier_Order__c co : list_CarrierOrderTemp) {
					// For Facilitator 1 OOO
					if (co.OwnerId == idOwnerId && blnIsFAC1) {
						co.OOO_Timestamp__c = system.now();
						list_CarrierOrderOOOFAC1.add(co);
					} else if ((co.Facilitator_2_Enrollment_Review__c == idOwnerId || co.Facilitator_2_Plan_Review__c == idOwnerId) && blnIsFAC2) {
						// For Facilitator 2 OOO
						co.OOO_Timestamp__c = system.now();
						list_CarrierOrderOOOFAC2.add(co);
					}
				}
				if (!list_CarrierOrderOOOFAC1.isEmpty()) {
					BTAssignmentUtil objBTFacilitatorAssignement = new BTAssignmentUtil();
					List<Carrier_Order__c> list_COWithFAC1Owner = objBTFacilitatorAssignement.processCOForFacilitator1Assignment(list_CarrierOrderOOOFAC1, null);
					if (list_COWithFAC1Owner != null && !list_COWithFAC1Owner.isEmpty())
						update list_COWithFAC1Owner;
				}
				if (!list_CarrierOrderOOOFAC2.isEmpty()) {
					update list_CarrierOrderOOOFAC2;
				}
				CarrierOrderTriggerHelper.skipTrigger = blnSkipOldval;
				Cache.displayErrorMessage('Successfully Saved.', ApexPages.Severity.CONFIRM);
				PageReference pageRef = new PageReference('/apex/BTCOFacilitatorOOOView');
				pageRef.setRedirect(true);
				return pageRef;
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public PageReference RetriveTicket() {
		list_TicketWrapper = new List<TicketWrapper>();
		set<string> set_TicketStatus = new Set<string>{ 'New', 'InProgress' };
		string query = 'select id,CreatedById,CreatedBy.Name,Name,Status__c,Escalation_Reason__c,Escalation_Reason_Detail__c,';
		query = query + ' Ticket_Creator_Role__c,CreatedDate,LastModifiedDate,Age__c,Carrier_Order__c, ';
		query = query + ' Carrier_Order__r.Renewal_Date__c from Ticket__c ';
		//Due to test Coverage
		if (Test.isRunningTest() == false) {
			query = query + ' where ownerid=:idOwnerId and Status__c in :set_TicketStatus order by createdDate desc';
		}
		List<Ticket__c> lstTicket = Database.query(query);
		for (Ticket__c objTicket : lstTicket) {
			TicketWrapper tw = new TicketWrapper();
			tw.objTicket = objTicket;
			if (objTicket.Carrier_Order__r.Renewal_Date__c != null) {
				tw.strRenewalDate = string.valueOf(objTicket.Carrier_Order__r.Renewal_Date__c);
			}
			tw.strCreatedDate = string.valueof(getDate(objTicket.CreatedDate));
			tw.strModifiedDate = string.valueof(getDate(objTicket.LastModifiedDate));
			list_TicketWrapper.add(tw);
		}
		return null;
	}

	public PageReference ResetSearch() {
		list_SelectedCarrier = new List<String>();
		list_SelectedState = new List<String>();
		list_SelectedStage = new List<String>();
		strFromAge = null;
		strToAge = null;
		SearchCarrierOrder();
		return null;
	}

	public class CarrierOrderWrapper {
		public Carrier_Order__c objCarrierOrder { get; set; }
		public boolean blnReAssign { get; set; }
		public string strCaseId { get; set; }
		public string strCaseNumber { get; set; }
		public string strRenewalStyleClass { get; set; }
		public string strRenewalDate { get; set; }
		public string strTicketId { get; set; }
		public string strTicketNumber { get; set; }
		public string strTicketStyleClass { get; set; }
		public string strInitialOwner { get; set; }
	}

	public class TicketWrapper {
		public Ticket__c objTicket { get; set; }
		public string strRenewalDate { get; set; }
		public string strCreatedDate { get; set; }
		public string strModifiedDate { get; set; }
	}

	private Date getDate(DateTime dtm) {
		Date dt = Date.Today();
		if (dtm != null) {
			dt = date.newinstance(dtm.year(), dtm.month(), dtm.day());
		}
		return dt;
	}
}