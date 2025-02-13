/**
 * @name         BTCOQualifierListViewCtrl
 * @author       Sanjay Paryani
 * @date         01/29/2020
 * @description
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class BTCOQualifierListViewCtrl {
	// Variables & Collections
	public Id IdOwner { get; set; }
	public List<Benefit_Order__c> list_BenefitOrders { get; set; }
	//For Tickets
	public list<TicketWrapper> list_TicketWrapper { get; set; }
	//For Benefit Orders
	public list<BenefitOrderWrapper> list_BenefitOrderWrapper { get; set; }
	public list<BenefitOrderWrapper> list_BenefitOrderWithTicketsWrapper { get; set; }
	public set<String> setIncludeBOStatus = new Set<string>{ 'Ready for Qualification', 'Qualification' };
	//For Status selection
	public List<SelectOption> list_UnselectedStatus { get; set; }
	public list<String> list_SelectedStatus { get; set; }
	public Boolean blnShowBOWithTickets { get; set; }
	public String strViewFilter { get; set; }
	public Integer intBOsWithTickets { get; set; }
	static string strUnassigned = 'Unassigned Orders';
	static string strMyOrders = 'My Orders';
	static string strOrdersWithTicket = 'Orders with Tickets';
	static string strAssignedOrders = 'Assigned Orders';

	// Constructor
	public BTCOQualifierListViewCtrl() {
		IdOwner = UserInfo.getUserId();
		blnShowBOWithTickets = false;
		strViewFilter = strUnassigned;
		intBOsWithTickets = 0;
		PopulateSearchPanel();
		SearchBenefitOrder();
		//Calls Retrive Ticket method to get all tickets assigned to qualifier
		RetriveTicket();
	}

	public PageReference ResetSearch() {
		blnShowBOWithTickets = false;
		list_SelectedStatus = new List<String>();
		strViewFilter = strUnassigned;

		SearchBenefitOrder();
		return null;
	}

	private void PopulateSearchPanel() {
		//Initliaze values
		list_UnselectedStatus = new List<SelectOption>();
		list_SelectedStatus = new List<String>();
		for (String status : setIncludeBOStatus) {
			list_UnselectedStatus.add(new SelectOption(status, status));
		}
		list_UnselectedStatus.add(new SelectOption('With Sales', 'With Sales'));
	}

	public PageReference SearchBenefitOrder() {
		try {
			list_BenefitOrderWrapper = new List<BenefitOrderWrapper>();
			//created this list so as not to loose selected status values from the main list
			set<string> set_SelectedStatusTemp = new Set<string>();
			set_SelectedStatusTemp.addAll(list_SelectedStatus);

			string strQuery = 'SELECT ID,Age__c,Parent_Benefit_Order__c,Parent_Benefit_Order__r.Name,Name,Renewal_Date__c,Days_Until_Renewal_Date__c,UW_Owner__c,UW_Owner__r.Name,Order_Status__c,';
			strQuery = strQuery + ' (Select Id,Name,Status__c From Tickets__r where Status__c!=\'Closed\')';
			strQuery = strQuery + ' FROM Benefit_Order__c';
			strQuery = strQuery + ' WHERE RecordType.DeveloperName = \'Benefits_BoR\' ';
			//strQuery = strQuery + ' AND Order_Status__c IN :setIncludeBOStatus' ;

			if (string.isNotBlank(strViewFilter) && strViewFilter == strUnassigned) {
				strQuery = strQuery + ' AND UW_Owner__c = null';
			} else if (string.isNotBlank(strViewFilter) && strViewFilter == strMyOrders) {
				strQuery = strQuery + ' AND UW_Owner__c = :IdOwner';
			} else if (string.isNotBlank(strViewFilter) && strViewFilter == strAssignedOrders) {
				strQuery = strQuery + ' AND UW_Owner__c != null';
			}
			if (string.isNotBlank(strViewFilter) && strViewFilter == strOrdersWithTicket) {
				blnShowBOWithTickets = true;
			} else if (string.isNotBlank(strViewFilter) && strViewFilter != strOrdersWithTicket) {
				blnShowBOWithTickets = false;
			}

			//By: PR, Date: May/7/20 ,Asana: https://app.asana.com/0/1149920908637905/1174631227725745/f
			if (!set_SelectedStatusTemp.isEmpty()) {
				if (set_SelectedStatusTemp.contains('With Sales')) {
					if (set_SelectedStatusTemp.size() > 1) {
						set_SelectedStatusTemp.remove('With Sales');
						strQuery += ' AND ((Order_Status__c IN :set_SelectedStatusTemp) OR (Order_Status__c = \'With Sales\' AND Start_Date__c = NULL)) ';
					} else {
						strQuery += ' AND Order_Status__c = \'With Sales\' AND Start_Date__c = NULL ';
					}
				} else {
					strQuery += ' AND Order_Status__c in :set_SelectedStatusTemp';
				}
			} else {
				strQuery += ' AND ((Order_Status__c IN :setIncludeBOStatus) OR (Order_Status__c = \'With Sales\' AND Start_Date__c = NULL)) ';
			}

			strQuery = strQuery + ' ORDER BY Days_Until_Renewal_Date__c ASC';
			List<Benefit_Order__c> list_BenefitOrders = database.query(strQuery);

			if (list_BenefitOrders != null && list_BenefitOrders.size() > 0) {
				intBOsWithTickets = 0;
				for (Benefit_Order__c bo : list_BenefitOrders) {
					BenefitOrderWrapper bow = new BenefitOrderWrapper();
					bow.objBenefitOrder = bo;
					bow.strRenewalStyleClass = null;
					bow.strTicketStyleClass = null;
					bow.strCaseId = null;
					bow.strCaseNumber = null;
					bow.strTicketId = null;
					bow.strTicketNumber = null;
					if (bo.Tickets__r != null && bo.Tickets__r.size() > 0) {
						Ticket__c objTicket = bo.Tickets__r[0];
						bow.strTicketId = objTicket.id;
						bow.strTicketNumber = objTicket.Name;
						bow.strTicketStyleClass = 'bg-red';
						intBOsWithTickets++;
					}
					if (bo.Renewal_Date__c != null) {
						bow.strRenewalDate = string.valueOf(bo.Renewal_Date__c);
						integer intDaysDiff = Date.Today().daysBetween(bo.Renewal_Date__c);
						if (intDaysDiff < 100) {
							bow.strRenewalStyleClass = 'bg-yellow';
						}
					}
					if (!blnShowBOWithTickets) {
						list_BenefitOrderWrapper.add(bow);
					} else {
						if (bow.strTicketId != null) {
							list_BenefitOrderWrapper.add(bow);
						}
					}
				}
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no beneift order(s) availble. Kindly change the search filters'));
				return null;
			}
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
		}

		return null;
	}

	public void fetchAllBenefitOrders() {
		list_BenefitOrders = [
			SELECT ID, Age__c, Name, Renewal_Date__c, Days_Until_Renewal_Date__c
			FROM Benefit_Order__c
			WHERE RecordType.DeveloperName = 'Benefits_BoR' AND Closed__c = FALSE
			ORDER BY Days_Until_Renewal_Date__c ASC, Age__c DESC
		];
	}

	public PageReference RetriveTicket() {
		list_TicketWrapper = new List<TicketWrapper>();
		set<string> setTicketStatus = new Set<string>{ 'New', 'InProgress' };

		List<Ticket__c> list_Tickets = [
			SELECT
				ID,
				Name,
				Status__c,
				Escalation_Reason__c,
				Escalation_Reason_Detail__c,
				Ticket_Creator_Role__c,
				CreatedDate,
				LastModifiedDate,
				Age__c,
				Carrier_Order__c,
				Carrier_Order__r.Renewal_Date__c
			FROM Ticket__c
			WHERE Status__c IN :setTicketStatus AND OwnerId = :IdOwner
		];
		for (Ticket__c objTicket : list_Tickets) {
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

	public class BenefitOrderWrapper {
		public Benefit_Order__c objBenefitOrder { get; set; }
		public string strCaseId { get; set; }
		public string strCaseNumber { get; set; }
		public string strRenewalStyleClass { get; set; }
		public string strRenewalDate { get; set; }
		public string strTicketId { get; set; }
		public string strTicketNumber { get; set; }
		public string strTicketStyleClass { get; set; }
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