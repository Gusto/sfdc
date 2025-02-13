/**
 * @name         BTAdvocateViewCtrl
 * @author       Anand Singh
 * @date         02/20/2020
 * @description  Build logic for Advocate View
 * @test class   BTAdvocateViewCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class BTAdvocateViewCtrl {
	//Application Status
	public list<System.SelectOption> list_SelectApplicationStatus { get; set; }
	public list<String> list_ApplicationStatus { get; set; }

	//Order Status
	public list<System.SelectOption> list_SelectOrderStatus { get; set; }
	public list<String> list_OrderStatus { get; set; }

	public Benefit_Order__c objFromRenewalDate { get; set; }
	public Benefit_Order__c objToRenewalDate { get; set; }

	public Id idOwnerId { get; set; }

	public List<BenefitOrderWrapper> list_BenefitOrderWarpper { get; set; }
	public list<BenefitOrderWrapper> list_BenefitOrderOOOWarpper { get; set; }

	//Open Task View
	public string strCustActive { get; set; }
	public string strCarrierActive { get; set; }
	public string strCustActiveMoreThan5Days { get; set; }
	public list<CustomerCommWrapper> list_CustomerCommWrapper { get; set; }
	public list<CustomerCommWrapper> list_CustomerCommWrapperMoreThan5Days { get; set; }
	public list<CustomerCommWrapper> list_CarrierCommWrapper { get; set; }
	public string strCreatedActive { get; set; }
	public string strOwnedActive { get; set; }
	public string strClosedActive { get; set; }
	public list<TicketWrapper> list_TicketWrapper { get; set; }
	public integer intNoOfTicketCreated { get; set; }
	public integer intNoOfTicketOnwed { get; set; }
	public integer intNoOfTicketClosed { get; set; }
	public map<string, set<string>> map_OrderHippoStatus;
	public Set<string> set_ApplicationInitialStatus;
	set<string> setBOExcludeStatus = Utils.setBOExclude;

	public boolean bln_ShowAsLoggedInUser { get; set; }
	//public set<String> set_ExcludeStatusForAdvocates {get; set;}
	public BTAdvocateViewCtrl() {
		idOwnerId = UserInfo.getUserId();
		bln_ShowAsLoggedInUser = true;
		string strUserId = ApexPages.currentPage().getParameters().get('userid');
		if (string.isNotBlank(strUserId)) {
			if (strUserId != idOwnerId) {
				bln_ShowAsLoggedInUser = false;
			}
			idOwnerId = strUserId;
		}
	}
	//Add Search Filter
	private void PopulateSearchFilter() {
		list_ApplicationStatus = new List<string>();
		list_OrderStatus = new List<string>();
		objFromRenewalDate = new Benefit_Order__c();
		objToRenewalDate = new Benefit_Order__c();
		map_OrderHippoStatus = new Map<string, set<string>>();
		list_SelectApplicationStatus = new List<System.SelectOption>();
		list_SelectOrderStatus = new List<System.SelectOption>();
		//set_ExcludeStatusForAdvocates = new Set<String>{'Canceled','Closed Admin','Fulfilled'};

		//and OwnerId=:idOwnerId
		for (Benefit_Order__c bo : [
			SELECT id, Order_Status__c, Application_Status__c
			FROM Benefit_Order__c
			WHERE RecordType.DeveloperName = 'Benefits_BoR' AND OwnerId = :idOwnerId AND Order_Status__c != NULL AND Order_Status__c NOT IN :setBOExcludeStatus
		]) {
			// and Application_Status__c!=null
			if (map_OrderHippoStatus.containsKey(bo.Order_Status__c)) {
				map_OrderHippoStatus.get(bo.Order_Status__c).add(bo.Application_Status__c);
			} else {
				map_OrderHippoStatus.put(bo.Order_Status__c, new Set<string>{ bo.Application_Status__c });
			}
		}

		set_ApplicationInitialStatus = new Set<string>();
		if (map_OrderHippoStatus != null && map_OrderHippoStatus.size() > 0) {
			for (string stKey : map_OrderHippoStatus.keySet()) {
				list_SelectOrderStatus.add(new SelectOption(stKey, stKey));
				//Get Application Status
				for (string strAppStatus : map_OrderHippoStatus.get(stKey)) {
					if (strAppStatus != null && set_ApplicationInitialStatus.contains(strAppStatus) == false) {
						list_SelectApplicationStatus.add(new SelectOption(strAppStatus, strAppStatus));
						set_ApplicationInitialStatus.add(strAppStatus);
					}
				}
			}
		}
		/*list_SelectApplicationStatus = Cache.getFieldPickListValues('Benefit_Order__c','Application_Status__c');
    	list_SelectOrderStatus = Cache.getFieldPickListValues('Benefit_Order__c','Order_Status__c');
    	*/
	}

	public PageReference PopulateHippoStatus() {
		list_SelectApplicationStatus = new List<System.SelectOption>();
		Set<string> stTemp = new Set<string>();
		if (list_OrderStatus != null && list_OrderStatus.size() > 0) {
			for (string stKey : list_OrderStatus) {
				for (string strAppStatus : map_OrderHippoStatus.get(stKey)) {
					if (strAppStatus != null && stTemp.contains(strAppStatus) == false) {
						list_SelectApplicationStatus.add(new SelectOption(strAppStatus, strAppStatus));
						stTemp.add(strAppStatus);
					}
				}
			}
		} else {
			//Update with inital value
			for (string st : set_ApplicationInitialStatus) {
				list_SelectApplicationStatus.add(new SelectOption(st, st));
			}
		}
		stTemp = new Set<string>();
		return null;
	}

	public PageReference CallOnBTMyCohort() {
		PopulateSearchFilter();
		SearchBenefitOrder();
		return null;
	}

	public PageReference CallOnOOOView() {
		GetOpenBenefitOrdeForOOO();
		return null;
	}

	public PageReference ResetSearch() {
		list_OrderStatus = new List<string>();
		list_ApplicationStatus = new List<string>();
		objFromRenewalDate = new Benefit_Order__c();
		objToRenewalDate = new Benefit_Order__c();

		PopulateSearchFilter();
		SearchBenefitOrder();
		GetOpenBenefitOrdeForOOO();
		return null;
	}

	public PageReference SearchBenefitOrder() {
		list_BenefitOrderWarpper = new List<BenefitOrderWrapper>();
		String strQuery = 'SELECT Id, Name, Account__c, Follow_Up_Date__c, BOR_DIFOT__c, Follow_Up_Notes__c, Parent_Benefit_Order__c, Parent_Benefit_Order__r.Name, OwnerId, Out_Of_Office_Notes__c,';
		strQuery = strQuery + ' Initial_Owner__c, Initial_Owner__r.Name, Renewal_Date__c, Order_Status__c, Application_Status__c,';
		strQuery = strQuery + ' Type__c,Age__c, (select id, CaseNumber, ContactId, Contact.Name FROM cases__r WHERE ';
		strQuery = strQuery + ' Status != \'Closed\' limit 1) FROM Benefit_Order__c WHERE RecordType.DeveloperName = \'Benefits_BoR\'';
		strQuery = strQuery + ' AND OwnerId = :idOwnerId';
		strQuery = strQuery + ' AND Order_Status__c NOT IN :setBOExcludeStatus';

		Date renewalDateFrom = objFromRenewalDate.Renewal_Date__c;
		Date renewalDateTo = objToRenewalDate.Renewal_Date__c;

		if (renewalDateFrom > renewalDateTo) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a valid renewal date range'));
			return null;
		}

		if (renewalDateFrom != null && renewalDateTo != null) {
			strQuery = strQuery + ' AND Renewal_Date__c >= :renewalDateFrom AND Renewal_Date__c <= :renewalDateTo';
		}

		if (list_OrderStatus != null && list_OrderStatus.size() > 0) {
			strQuery = strQuery + ' AND Order_Status__c IN :list_OrderStatus';
		}
		if (list_ApplicationStatus != null && list_ApplicationStatus.size() > 0) {
			strQuery = strQuery + ' AND Application_Status__c IN :list_ApplicationStatus';
		}
		strQuery = strQuery + '  ORDER BY Renewal_Date__c ASC, Age__c DESC LIMIT 1000';
		List<Benefit_Order__c> lstBenefitOrder = Database.query(strQuery);
		for (Benefit_Order__c bo : lstBenefitOrder) {
			BenefitOrderWrapper bow = new BenefitOrderWrapper();
			bow.objBOOrder = bo;
			bow.strCaseId = null;
			bow.strPreviousOwner = null;
			if (bo.Initial_Owner__c != null && bo.Initial_Owner__c != idOwnerId) {
				bow.strPreviousOwner = bo.Initial_Owner__r.Name;
			}
			bow.strAgeColorCSS = null;
			if (bo.Age__c > 45) {
				bow.strAgeColorCSS = 'bg-yellow';
			}
			if (bo.cases__r != null && bo.cases__r.size() > 0) {
				Case tempCase = bo.cases__r[0];
				bow.objCase = tempCase;
				bow.strCaseId = tempCase.Id;
			}
			bow.strHasTada = 'No';
			if (bo.Type__c != null) {
				string tp = bo.Type__c.toUpperCase();
				if (tp.indexof('TADA') > -1) {
					bow.strHasTada = 'Yes';
				}
			}
			bow.strRenewalDate = null;
			if (bo.Renewal_Date__c != null) {
				bow.strRenewalDate = string.valueOf(bo.Renewal_Date__c);
			}
			list_BenefitOrderWarpper.add(bow);
		}
		if (list_BenefitOrderWarpper.size() == 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no benefit order(s) availble.Kindly change search filters'));
			return null;
		}
		return null;
	}

	private void GetOpenBenefitOrdeForOOO() {
		list_BenefitOrderOOOWarpper = new List<BenefitOrderWrapper>();
		List<Benefit_Order__c> list_BenefitOrderTemp = [
			SELECT
				Id,
				Re_Assign__c,
				Is_Multi_EIN__c,
				Account__c,
				Parent_Benefit_Order__c,
				BOR_DIFOT__c,
				Parent_Benefit_Order__r.Name,
				Name,
				Out_Of_Office_Notes__c,
				Out_Of_Office_Notes_TextBox__c,
				Initial_Owner__c,
				Renewal_Date__c,
				Order_Status__c,
				Application_Status__c,
				Type__c,
				Age__c
			FROM Benefit_Order__c
			WHERE RecordType.DeveloperName = 'Benefits_BoR' AND OwnerId = :idOwnerId AND Order_Status__c NOT IN :setBOExcludeStatus
			ORDER BY Renewal_Date__c ASC
			LIMIT 1000
		];

		if (list_BenefitOrderTemp != null && list_BenefitOrderTemp.size() > 0) {
			for (Benefit_Order__c bo : list_BenefitOrderTemp) {
				BenefitOrderWrapper bow = new BenefitOrderWrapper();
				bow.chReAssign = false;
				bow.strOOONotes = null;
				bow.chReAssign = bo.Re_Assign__c;
				if (string.isNotBlank(bo.Out_Of_Office_Notes__c)) {
					bow.strOOONotes = bo.Out_Of_Office_Notes__c;
				}
				bow.objBOOrder = bo;
				list_BenefitOrderOOOWarpper.add(bow);
			}
		}
		if (list_BenefitOrderOOOWarpper.size() == 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no benefit order(s) available for assignment'));
		}
	}
	private void SaveOOO() {
		if (list_BenefitOrderOOOWarpper != null && list_BenefitOrderOOOWarpper.size() > 0) {
			List<Benefit_Order__c> lstBenefitOrder = new List<Benefit_Order__c>();
			for (BenefitOrderWrapper bow : list_BenefitOrderOOOWarpper) {
				bow.objBOOrder.Out_Of_Office_Notes__c = null;
				bow.objBOOrder.Out_Of_Office_Notes_TextBox__c = null;
				bow.objBOOrder.Re_Assign__c = bow.chReAssign;
				//bow.chReAssign==true &&  remove this check by AKS as per Asana request
				//https://app.asana.com/0/1174988188207533/1177129386033041
				if (string.isNotBlank(bow.strOOONotes)) {
					bow.objBOOrder.Out_Of_Office_Notes__c = bow.strOOONotes;
					//We can not use long text area in query that's why we are taking into text box
					if (bow.strOOONotes.length() > 100) {
						bow.objBOOrder.Out_Of_Office_Notes_TextBox__c = bow.strOOONotes.substring(0, 100);
					} else {
						bow.objBOOrder.Out_Of_Office_Notes_TextBox__c = bow.strOOONotes;
					}
				}
				lstBenefitOrder.add(bow.objBOOrder);
			}
			if (lstBenefitOrder != null && lstBenefitOrder.size() > 0) {
				boolean blnSkipOldval = BenefitOrderHelper.skipTrigger;
				BenefitOrderHelper.skipTrigger = true;
				update lstBenefitOrder;
				BenefitOrderHelper.skipTrigger = blnSkipOldval;
			}
		}
	}
	public PageReference SaveOOONotes() {
		try {
			SaveOOO();
			Cache.displayErrorMessage('Successfully Saved.', ApexPages.Severity.CONFIRM);
			//PageReference pageRef = new PageReference('/apex/BTAdvocateMyCohortView');
			//pageRef.setRedirect(true);
			//return pageRef;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public PageReference ReasignBOOnOOO() {
		try {
			SaveOOO();
			// Get All Benefit Orders where we have out of the office notes
			map<Id, Benefit_Order__c> map_BenefitTemp = new Map<Id, Benefit_Order__c>();

			for (Benefit_Order__c bo : [
				SELECT Id, Account__c, Parent_Benefit_Order__c, Re_Assign__c, Is_Multi_EIN__c, OwnerId, Initial_Owner__c, Type__c
				FROM Benefit_Order__c
				WHERE
					OwnerId = :idOwnerId
					AND RecordType.DeveloperName = 'Benefits_BoR'
					AND Order_Status__c NOT IN :setBOExcludeStatus
					AND Re_Assign__c = TRUE
					AND Out_Of_Office_Notes_TextBox__c != NULL
			]) {
				bo.Re_Assign__c = false;
				map_BenefitTemp.put(bo.Id, bo);
			}

			if (map_BenefitTemp.size() != list_BenefitOrderOOOWarpper.size()) {
				Cache.displayErrorMessage('Please mark all and provide OOO Notes before reasign', ApexPages.Severity.ERROR);
				return null;
			} else {
				//Mark Out of the office
				Boolean blnUserSkipTriger = UserTriggerHelper.skipTrigger;
				UserTriggerHelper.skipTrigger = true;
				User objUser = new User(id = userinfo.getuserid());
				objUser.Out_Of_Office__c = true;
				update objUser;
				UserTriggerHelper.skipTrigger = blnUserSkipTriger;

				processBOAdvocateAssignmentAsync(map_BenefitTemp.keySet());

				/*BTAssignmentUtil controller = new BTAssignmentUtil();
				controller.processBOForAdvocateAssignment(map_BenefitTemp.values());
				List<sObject> list_AsyncBenefitTempUpdate = map_BenefitTemp.values();
                // SJay - 06/04/2020 - Updating asynchronously
                database.updateAsync(list_AsyncBenefitTempUpdate); */

				// After Update we will reset the table to get latest records.
				CallOnOOOView();
				Cache.displayErrorMessage('Reassignment is completed.', ApexPages.Severity.CONFIRM);
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	@future
	public static void processBOAdvocateAssignmentAsync(Set<Id> set_BenefitOrderIds) {
		List<Benefit_Order__c> list_BenefitOrdersForAssignment = new List<Benefit_Order__c>();

		for (Benefit_Order__c objBO : [
			SELECT Id, Account__c, Parent_Benefit_Order__c, Re_Assign__c, Is_Multi_EIN__c, OwnerId, Initial_Owner__c, Type__c
			FROM Benefit_Order__c
			WHERE Id IN :set_BenefitOrderIds
		]) {
			list_BenefitOrdersForAssignment.add(objBO);
		}
		if (list_BenefitOrdersForAssignment.size() > 0) {
			BTAssignmentUtil controller = new BTAssignmentUtil();
			controller.processBOForAdvocateAssignment(list_BenefitOrdersForAssignment, true);
		}
	}

	//Call on Open Task page
	public PageReference CallOnBTOpenTask() {
		strCustActive = 'active';
		strCarrierActive = null;
		strCustActiveMoreThan5Days = null;
		//For Customer Communication
		RetriveCustomerCommunication();
		//For Carrier Communication
		RetriveCarrierCommunication();

		//For Ticket
		strCreatedActive = 'active';
		strOwnedActive = null;
		strClosedActive = null;
		countTicket();
		ShowTicketCreatedByMe();

		return null;
	}

	public PageReference ShowCustomerCommunication() {
		strCustActive = 'active';
		strCarrierActive = null;
		strCustActiveMoreThan5Days = null;
		return null;
	}
	public PageReference ShowCustomerCommunicationMoreThan5Days() {
		strCustActive = null;
		strCarrierActive = null;
		strCustActiveMoreThan5Days = 'active';
		return null;
	}
	public PageReference ShowCarrierCommunication() {
		strCustActive = null;
		strCarrierActive = 'active';
		strCustActiveMoreThan5Days = null;
		return null;
	}

	//**Carrier Communication Start**/
	public PageReference RetriveCarrierCommunication() {
		try {
			list_CarrierCommWrapper = new List<CustomerCommWrapper>();
			set<string> setExcludeCOStatus = new Set<string>{ 'Approved', 'Canceled', 'Closed Lost', 'Closed Admin' };

			Set<string> set_IncludeCaseType = new Set<string>{ 'BOR', 'Benefits BOR Carrier Case' };
			List<Case> list_CaseTemp = [
				SELECT
					id,
					CaseNumber,
					Benefit_Order__c,
					Incoming_Email_Received_Date__c,
					Incoming_Email_Received__c,
					Carrier_Order__c,
					Carrier_Order__r.Name,
					Carrier_Order__r.Implementation_Stage__c,
					Benefit_Order__r.Name,
					Benefit_Order__r.Renewal_Date__c
				FROM case
				WHERE
					RecordType.DeveloperName = 'Benefits_BoR'
					AND Type IN :set_IncludeCaseType
					AND Benefit_Order__c != NULL
					AND Carrier_Order__c != NULL
					AND Carrier_Order__r.Implementation_Stage__c NOT IN :setExcludeCOStatus
					AND Benefit_Order__r.OwnerId = :idOwnerId
					AND Incoming_Email_Received__c = TRUE
					AND Status != 'Closed'
					AND Requires_Action__c = TRUE
				ORDER BY Incoming_Email_Received_Date__c ASC
				LIMIT 1000
			];

			list_CarrierCommWrapper.addAll(PopulateCommunicationWrapper(list_CaseTemp));
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}
	//**Carrier Communication End**/

	//**Customer Communication Start***//
	public PageReference RetriveCustomerCommunication() {
		try {
			list_CustomerCommWrapper = new List<CustomerCommWrapper>();
			list_CustomerCommWrapper = GetCustomerCommunication(false);
			list_CustomerCommWrapperMoreThan5Days = new List<CustomerCommWrapper>();
			list_CustomerCommWrapperMoreThan5Days = GetCustomerCommunication(true);
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}
	private list<CustomerCommWrapper> GetCustomerCommunication(boolean morethan5Days) {
		list<CustomerCommWrapper> list_TempWrapper = new List<CustomerCommWrapper>();
		string query = 'select id,Days_since_last_email_to_customer__c,CaseNumber,ContactId,Requires_Action__c,Contact.Name,Benefit_Order__c,';
		query = query + ' Benefit_Order__r.Name,Benefit_Order__r.Order_Status__c,';
		query = query + ' Benefit_Order__r.Renewal_Date__c,Incoming_Email_Received_Date__c,Incoming_Email_Received__c from case where ';
		query = query + ' RecordType.DeveloperName=\'Benefits_BoR\' and Type!=\'Carrier Submission\'';
		query = query + '  and ContactId!=null and Benefit_Order__c!=null ';
		query = query + '   and ownerId=:idOwnerId  ';
		query = query + ' and Requires_Action__c=true ';
		//Asana request https://app.asana.com/0/1190791132094250/1190903513195318 dated -31st August 2020
		query = query + ' and Status!=\'Closed\'';
		if (morethan5Days == true) {
			query = query + ' and Days_since_last_email_to_customer__c>5';
			query = query + ' order by Days_since_last_email_to_customer__c desc limit 1000';
		} else {
			query = query + ' order by Incoming_Email_Received_Date__c asc limit 1000';
		}
		list_TempWrapper.addAll(PopulateCommunicationWrapper(database.query(query)));
		return list_TempWrapper;
	}
	//**Customer Communication End***//

	private list<CustomerCommWrapper> PopulateCommunicationWrapper(List<Case> lstCase) {
		list<CustomerCommWrapper> list_tempWrapper = new List<CustomerCommWrapper>();
		for (Case objCase : lstCase) {
			integer nod = 0;
			if (objCase.Incoming_Email_Received_Date__c != null) {
				nod = getNoOfdays(objCase.Incoming_Email_Received_Date__c, Date.Today());
			}
			CustomerCommWrapper cw = new CustomerCommWrapper();
			cw.objCase = objCase;
			cw.intDaySinceLastReceived = nod;
			list_tempWrapper.add(cw);
		}
		return list_tempWrapper;
	}
	//Update NDA status on Participant level
	public PageReference updateRequireStatus() {
		string strCaseId = ApexPages.CurrentPage().getparameters().get('strCaseId');
		if (list_CustomerCommWrapper != null && list_CustomerCommWrapper.size() > 0) {
			List<Case> lstCase = new List<Case>();
			for (CustomerCommWrapper cw : list_CustomerCommWrapper) {
				if (strCaseId != null && strCaseId == cw.objCase.Id) {
					Case objCase = new Case(Id = strCaseId);
					objCase.Requires_Action__c = false;
					lstCase.add(objCase);
				}
			}
			if (lstCase != null && lstCase.size() > 0) {
				update lstCase;
			}
		}
		RetriveCustomerCommunication();
		return null;
	}

	//**Customer Communication End***//
	//**Ticket Start ****/

	public PageReference ShowTicketCreatedByMe() {
		strCreatedActive = 'active';
		strOwnedActive = null;
		strClosedActive = null;
		RetriveTickets('created');
		return null;
	}
	public PageReference ShowTicketOwnedByMe() {
		strCreatedActive = null;
		strOwnedActive = 'active';
		strClosedActive = null;
		RetriveTickets('owned');
		return null;
	}
	public PageReference ShowClosedTicket() {
		strCreatedActive = null;
		strOwnedActive = null;
		strClosedActive = 'active';
		RetriveTickets('closed');
		return null;
	}
	private void countTicket() {
		intNoOfTicketCreated = 0;
		intNoOfTicketClosed = 0;
		intNoOfTicketOnwed = 0;
		for (Ticket__c tck : [
			SELECT Id, CreatedById, Benefit_Order__c, OwnerId, Closed_Within_7_Days__c, Closed_By__c, Status__c
			FROM Ticket__c
			WHERE
				Name != NULL
				AND ((CreatedById = :idOwnerId
				AND status__c != 'Closed')
				OR (OwnerId = :idOwnerId
				AND Status__c != 'Closed')
				OR (CreatedById = :idOwnerId
				AND Status__c = 'Closed'
				AND Closed_Within_7_Days__c = TRUE))
		]) {
			//Created By me
			//if(tck.CreatedById==idOwnerId && tck.Benefit_Order__c!=null && tck.Status__c!='Closed')
			if (tck.CreatedById == idOwnerId && tck.Status__c != 'Closed') {
				intNoOfTicketCreated = intNoOfTicketCreated + 1;
			}
			//Owned By me
			if (tck.OwnerId == idOwnerId && tck.Status__c != 'Closed') {
				intNoOfTicketOnwed = intNoOfTicketOnwed + 1;
			}
			//Closed By me
			//if(tck.CreatedById==idOwnerId && tck.Benefit_Order__c!=null && tck.Status__c=='Closed' && tck.Closed_Within_7_Days__c==true)
			if (tck.CreatedById == idOwnerId && tck.Status__c == 'Closed' && tck.Closed_Within_7_Days__c == true) {
				intNoOfTicketClosed = intNoOfTicketClosed + 1;
			}
		}
	}
	private void RetriveTickets(string dataType) {
		try {
			list_TicketWrapper = new List<TicketWrapper>();
			string query = 'select id,Status__c,Benefit_Order__c,Benefit_Order__r.name,Createddate,LastModifieddate,';
			query = query + ' Benefit_Order__r.Renewal_Date__c,Escalation_Reason__c,Escalation_Reason_Detail__c,Name,';
			query = query + ' Description__c, Reporting_Team__c from Ticket__c where Name!=null ';
			if (dataType == 'created') {
				//query = query + '  and Benefit_Order__c!=null and Status__c!=\'Closed\'';
				query = query + '  and Status__c!=\'Closed\'';
				query = query + '  and CreatedById=:idOwnerId';
			}
			if (dataType == 'owned') {
				query = query + ' and Status__c!=\'Closed\'';
				query = query + '  and ownerId=:idOwnerId ';
			}
			if (dataType == 'closed') {
				//query = query + ' and Benefit_Order__c!=null and Status__c=\'Closed\' and Closed_Within_7_Days__c=true';
				query = query + ' and Status__c=\'Closed\' and Closed_Within_7_Days__c=true';
				query = query + ' and CreatedById=:idOwnerId '; //and Closed_By__c!=:idOwnerId
			}
			query = query + ' order by Createddate ASC limit 1000';

			for (Ticket__c objTicket : Database.query(query)) {
				integer nod = 0;
				if (objTicket.Createddate != null) {
					nod = getNoOfdays(objTicket.Createddate, Date.Today());
				}
				TicketWrapper cw = new TicketWrapper();
				cw.objTicket = objTicket;
				cw.intDaySinceLastCreated = nod;
				list_TicketWrapper.add(cw);
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
	}
	//***Ticket End*****/

	private integer getNoOfdays(Datetime dFrom, Datetime dTo) {
		integer nod = 0;
		Date fromDate = date.newinstance(dFrom.year(), dFrom.month(), dFrom.day());
		Date toDate = date.newinstance(dTo.year(), dTo.month(), dTo.day());
		nod = fromDate.daysBetween(toDate);
		return nod;
	}

	public class BenefitOrderWrapper {
		public Benefit_Order__c objBOOrder { get; set; }
		public string strRenewalDate { get; set; }
		public Case objCase { get; set; }
		public string strCaseId { get; set; }
		public string strHasTada { get; set; }
		public boolean chReAssign { get; set; }
		public string strOOONotes { get; set; }
		public string strAgeColorCSS { get; set; }
		public string strPreviousOwner { get; set; }
	}

	//For Customer Communication
	public class CustomerCommWrapper {
		public integer intDaySinceLastReceived { get; set; }
		public Case objCase { get; set; }
	}

	//For Tickets
	public class TicketWrapper {
		public integer intDaySinceLastCreated { get; set; }
		public Ticket__c objTicket { get; set; }
	}
}