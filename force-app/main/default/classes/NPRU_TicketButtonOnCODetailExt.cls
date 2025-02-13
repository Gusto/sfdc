/***************************************************
Purpose : Ticket Functionality: Creation of Ticket and QC Error from Carrier Order, View All Ticket related to Carrier Order.
Written By : Deepak Tyagi
Test Classes : NPRU_TicketButtonOnCODetailCtrlTest
****************************************************/
public class NPRU_TicketButtonOnCODetailExt {
	// To store current record Id from parameter
	public String strCurrentRecord { get; set; }
	// Used in Ticket creation page
	public Ticket__c objTicketRecord { get; set; }
	// Used in QC Error creation page
	public QA_Errors__c objQCError { get; set; }
	// To show user lookup on ticket creation page
	public Benefit_Order__c objBOTemp { get; set; }
	// store all Ticket related to Benefit Order
	public List<Ticket__c> list_Tickets { get; set; }
	// store all Ticket reason
	public List<SelectOption> list_Reasons { get; set; }
	// store all Ticket Reason Detail
	public List<SelectOption> list_ReasonsDetail { get; set; }
	// store all Ticket To Team
	public List<SelectOption> list_Teams { get; set; }
	// store all Ticket To Sub Team
	public List<SelectOption> list_SubTeams { get; set; }
	// store all To Sub Team For QC Error
	public List<SelectOption> list_TeamsForQCError { get; set; }
	// store selected Reason
	public String strSelectedReason { get; set; }
	// store selected Reason Detail
	public String strSelectedReasonDetail { get; set; }
	// store selected Team
	public String strSelectedTeam { get; set; }
	// store selected Sub Team
	public String strSelectedSubTeam { get; set; }
	// Check if Record Type is Onboarding Renewal
	public Boolean blnIsOnboardingRenewal { get; set; }
	public String strScript { get; set; }

	public List<Carrier_Order__c> list_CarrierOrders { get; set; }
	// Store sorting field name
	String strSortField;
	// Store Previous sorting field name
	String strPreSortField;
	// Store Previous sorting order
	String strPreviousSortOrder;
	Map<String, Ticket_Mapping__c> map_TicketsMapping = new Map<String, Ticket_Mapping__c>();
	//User userObj;
	//DS
	List<User> list_Users = new List<user>();
	String strTypeOFRecordToBeCreated;
	// to mark Require routing in BO
	Boolean blnIsRequireRouting = false;
	Boolean blnIsNoStatusUpdate = false;
	Boolean blnIsIAReassigned = false;
	Map<Id, Benefit_Order__c> map_BenefitOrdersToBeUpdated = new Map<Id, Benefit_Order__c>();
	List<Benefit_Order__c> list_BOs = new List<Benefit_Order__c>();
	//To check if there is an error in page
	public Boolean blnHasError {
		get {
			return ApexPages.hasMessages();
		}
	}

	private static final String NONE = 'None';
	static String strUserPrefix = '005';
	static final Id idAutomatedUser = HIGroupEventUtil.fetchAutomatedUserId();

	public static final String REASON_CONCESSION_REIMBURSEMENT = 'Concession/Reimbursement';
	public static final String REASON_LICENSING = 'Licensing';

	public List<SelectOption> list_FromTeams { get; set; }
	Set<String> set_ReportingTeams = new Set<String>();
	static Id idLoggedInUser = UserInfo.getUserId();

	public NPRU_TicketButtonOnCODetailExt(ApexPages.StandardController sc) {
		strSortField = '';
		list_CarrierOrders = new List<Carrier_Order__c>();
		objBOTemp = new Benefit_Order__c();
		objQCError = new QA_Errors__c();
		blnIsOnboardingRenewal = false;
		list_ReasonsDetail = new List<SelectOption>();
		list_FromTeams = new List<SelectOption>();
		strCurrentRecord = ApexPages.CurrentPage().getparameters().get('id');
		/**
        To filter some of the ticket mapping which should not be displayed while creating, that ticket mapping only be used 
        while creating QC Error. 
        if strTypeOFRecordToBeCreated == ticket, then we will not show the ticket Mapping records who does not have any value in two fields
        (Order Status when Ticket is Closed, Order Status while Ticket is Open)
        if strTypeOFRecordToBeCreated == QCError, then all the ticket Mapping are used
         */
		strTypeOFRecordToBeCreated = ApexPages.CurrentPage().getparameters().get('from');

		list_Users = [SELECT Id, ManagerId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		// fetch Carrier Order and related related records by Id from Parameter
		list_CarrierOrders = [
			SELECT
				Id,
				Benefit_Order__c,
				Audit_Owner__c,
				Benefit_Order__r.Coverage_Effective_Date__c,
				Carrier__c,
				RecordTypeId,
				Recordtype.Name,
				Benefit_Order__r.Opportunity__r.RecordTypeId,
				Benefit_Order__r.Status_Detail__c,
				Benefit_Order__r.Order_Status__c,
				Benefit_Order__r.UW_Owner__c,
				Benefit_Order__r.OwnerId,
				Benefit_Order__r.RecordTypeId,
				Benefit_Order__r.Opportunity__c,
				Benefit_Order__r.Opportunity__r.Account_Filing_State__c,
				Benefit_Order__r.Opportunity__r.Renewal_Date__c,
				Benefit_Order__r.Opportunity__r.OwnerId,
				Implementation_Stage__c,
				OwnerId,
				Follow_Up_Date__c,
				Confirmation_Owner__c,
				Sent_to_HI_for_Submission__c,
				Submission_Deadline_Date__c,
				(SELECT Id, AccountId FROM Cases__r WHERE Type = :TicketUtil.CASE_TYPE_CARRIER_SUBMISSION)
			FROM Carrier_Order__c
			WHERE Id = :strCurrentRecord
		];

		objTicketRecord = new Ticket__c();
		list_FromTeams.add(new SelectOption(TicketUtil.TICKET_ROLE_FULFILLMENT, TicketUtil.TICKET_ROLE_FULFILLMENT));
		objTicketRecord.Reporting_Team__c = TicketUtil.TICKET_ROLE_FULFILLMENT;
		objQCError.From_Sub_Team_s__c = TicketUtil.TICKET_ROLE_FULFILLMENT;
		ticketToTeam();
		list_BOs = [
			SELECT
				id,
				Parent_Benefit_Order__c,
				Initial_Owner__c,
				Type__c,
				Ownerid,
				Tier__c,
				Account__c,
				RecordTypeId,
				Order_Status__c,
				Partner_Tier__c,
				Assignment_State__c,
				Coverage_Effective_Date__c,
				Opportunity__c,
				Coverage_Effective_Month__c,
				Coverage_Effective_Year__c,
				Opportunity__r.OwnerId,
				Opportunity__r.Owner_Role_Name__c,
				Account__r.Priority_Support__c,
				Maestro__c,
				(
					SELECT Id, Implementation_Stage__c
					FROM Carrier_Orders__r
					WHERE Implementation_Stage__c NOT IN :UtilitiesFactory.set_COCanceled
				)
			FROM Benefit_Order__c
			WHERE Id = :list_CarrierOrders[0].Benefit_Order__c
		];

		//Neha Dabas, 26 July , To show all tickets related to carrier order in left panel
		list_Tickets = [
			SELECT id, Name, Escalation_Reason__c, CreatedDate, CreatedBy.FirstName, LastModifiedBy.FirstName, Owner.Name, Description__c, LastModifiedDate, Status__c
			FROM Ticket__c
			WHERE Carrier_Order__c = :strCurrentRecord OR Benefit_Order__c = :list_CarrierOrders[0].Benefit_Order__c
			ORDER BY CreatedDate DESC
			LIMIT 5
		];

		// fetching all ticket related to Benefit Order on selected view.
		allTickets();
	}

	public void ticketToTeam() {
		ApexPages.getMessages().clear();
		strSelectedTeam = NONE;
		strSelectedSubTeam = NONE;
		strSelectedReason = '';
		strSelectedReasonDetail = '';
		list_Teams = new List<SelectOption>();
		list_Teams.add(new SelectOption(NONE, NONE));
		Set<String> set_TeamTickets = new Set<String>();

		// fetch all 'To Team' related to 'From Team' from Ticket Mapping
		for (Ticket_Mapping__c objTM : [SELECT Id, From_Sub_Team_s__c, To_Team__c FROM Ticket_Mapping__c WHERE From_Sub_Team_s__c = :objTicketRecord.Reporting_Team__c]) {
			if (!set_TeamTickets.contains(objTM.To_Team__c)) {
				// By: Deepak, Not adding 'To Team' in list
				if (String.isNotBlank(objTM.To_Team__c)) {
					list_Teams.add(new SelectOption(objTM.To_Team__c, objTM.To_Team__c));
					set_TeamTickets.add(objTM.To_Team__c);
				}
			}
		}
	}

	// Method to show all ticket related to Carrier Order on selected view.
	public void allTickets() {
		strSortField = apexPages.currentPage().getParameters().get('sortField');
		String strSelectedView = ApexPages.CurrentPage().getparameters().get('selectedView');
		String strSortTickets = '';
		String strQueryTicket = '';
		Id idBenefitOrder = list_CarrierOrders[0].Benefit_Order__c;

		if (String.isNotBlank(strSortField)) {
			if (strPreSortField == strSortField && strPreviousSortOrder == 'ASC') {
				strPreviousSortOrder = 'DESC';
			} else {
				strPreviousSortOrder = 'ASC';
			}

			strPreSortField = strSortField;
			strSortTickets = ' Order by ' + strSortField + ' ' + strPreviousSortOrder;
		}

		if (TicketUtil.LABEL_ALL.equalsIgnoreCase(strSelectedView)) {
			strQueryTicket =
				'SELECT Id, Name, Escalation_Reason__c, CreatedDate, CreatedBy.FirstName, LastModifiedBy.FirstName, Owner.Name, Description__c, LastModifiedDate, Status__c FROM Ticket__c WHERE (Carrier_Order__c = :strCurrentRecord OR Benefit_Order__c =: idBenefitOrder)' +
				strSortTickets;
			list_Tickets = Database.query(strQueryTicket);
		} else if (TicketUtil.LABEL_MY.equalsIgnoreCase(strSelectedView)) {
			String loggedInUser = UserInfo.getUserId();
			strQueryTicket =
				'SELECT Id, Name, Escalation_Reason__c, CreatedDate, CreatedBy.FirstName, LastModifiedBy.FirstName, Owner.Name, Description__c, LastModifiedDate, Status__c FROM Ticket__c WHERE (Carrier_Order__c = :strCurrentRecord OR Benefit_Order__c =: idBenefitOrder) AND (OwnerId =: loggedInUser OR LastModifiedById =: loggedInUser OR CreatedById =: loggedInUser)' +
				strSortTickets;
			list_Tickets = Database.query(strQueryTicket);
		}
	}

	// Method to fetch all Ticket reason based on selected 'From' and 'To' team.
	public void subTeam() {
		strSelectedReason = '';
		strSelectedReasonDetail = '';
		objTicketRecord.Status__c = TicketUtil.TICKET_STATUS_NEW;
		strCurrentRecord = ApexPages.CurrentPage().getparameters().get('id');
		strSelectedSubTeam = NONE;
		list_SubTeams = new List<SelectOption>();
		list_SubTeams.add(new SelectOption(NONE, NONE));
		Set<String> set_SubTeams = new Set<String>();
		Set<String> set_Reasons = new Set<String>();
		Map<String, String> map_StatesName = new Map<String, String>();

		// Query all State from custom setting
		for (State_Name_to_abbreviations_Mapping__c objStateName : State_Name_to_abbreviations_Mapping__c.getall().values()) {
			if (!map_StatesName.containsKey(objStateName.State_Name__c))
				map_StatesName.put(objStateName.State_Name__c, objStateName.State_Abbreviation__c);
		}

		objQCError.Carrier_Order__c = list_CarrierOrders[0].Id;
		objQCError.Benefit_Order__c = list_CarrierOrders[0].Benefit_Order__c;

		// Query all Ticket Mapping records
		if (String.isNotBlank(objTicketRecord.Reporting_Team__c) && String.isNotBlank(strSelectedTeam) && !NONE.equalsIgnoreCase(strSelectedTeam)) {
			String strTicketMappingQuery =
				'Select id, Ticket_Reason_s__c, To_Sub_team__c, Automated_QC_Error_Required__c, Order_Status_when_Ticket_is_Closed__c, Order_Status_while_Ticket_is_Open__c, Ticket_Reason_Details__c, From_Sub_Team_s__c, To_Team__c FROM Ticket_Mapping__c WHERE From_Sub_Team_s__c =\'' +
				objTicketRecord.Reporting_Team__c +
				'\' And To_Team__c = \'' +
				strSelectedTeam +
				'\' ';

			if ('Ticket'.equalsIgnoreCase(strTypeOFRecordToBeCreated)) {
				strTicketMappingQuery += ' AND Order_Status_when_Ticket_is_Closed__c != null AND Order_Status_while_Ticket_is_Open__c != null';
			}

			List<Ticket_Mapping__c> list_TicketMaps = Database.query(strTicketMappingQuery);

			for (Ticket_Mapping__c objTM : list_TicketMaps) {
				if (!map_TicketsMapping.containsKey(objTM.From_Sub_Team_s__c + strSelectedTeam + objTM.To_Sub_team__c + objTM.Ticket_Reason_s__c + objTM.Ticket_Reason_Details__c + ''))
					map_TicketsMapping.put(objTM.From_Sub_Team_s__c + strSelectedTeam + objTM.To_Sub_team__c + objTM.Ticket_Reason_s__c + objTM.Ticket_Reason_Details__c + '', objTM);

				/*
				 *Neha Dabas, 8th August 2019, Dynamically populate the subTeams based on Ticket Mapping Table
				 */
				if (
					String.isNotBlank(objTicketRecord.Reporting_Team__c) &&
					String.isNotBlank(objTM.From_Sub_Team_s__c) &&
					String.isNotBlank(objTM.To_Sub_team__c) &&
					String.isNotBlank(objTM.To_Team__c) &&
					objTicketRecord.Reporting_Team__c.equalsIgnoreCase(objTM.From_Sub_Team_s__c) &&
					objTM.To_Team__c.equalsIgnoreCase(strSelectedTeam) &&
					!set_SubTeams.contains(objTM.To_Sub_team__c)
				) {
					if (objTM.To_Sub_team__c != TicketUtil.TICKET_ROLE_IMPLEMENTATION && objTM.From_Sub_Team_s__c == TicketUtil.TICKET_ROLE_CARRIER_IO) {
						list_SubTeams.add(new SelectOption(objTM.To_Sub_team__c, objTM.To_Sub_team__c));
						set_SubTeams.add(objTM.To_Sub_team__c);
					} else if (objTM.From_Sub_Team_s__c != TicketUtil.TICKET_ROLE_CARRIER_IO) {
						list_SubTeams.add(new SelectOption(objTM.To_Sub_team__c, objTM.To_Sub_team__c));
						set_SubTeams.add(objTM.To_Sub_team__c);
					}
				}
			}
		}

		// Assign Ticket fields from Benefit Order and related objects
		if (!list_CarrierOrders.isEmpty()) {
			objTicketRecord.Carrier_Order__c = strCurrentRecord;
			objTicketRecord.Benefit_Order__c = list_CarrierOrders[0].Benefit_Order__c;
			//Neha, 14 Aug, This should be set to Coverage_Effective_Date__c on BO
			objTicketRecord.Renewal_Date__c = list_CarrierOrders[0].Benefit_Order__r.Coverage_Effective_Date__c;

			if (list_CarrierOrders[0].Benefit_Order__r.Opportunity__c != null) {
				objTicketRecord.Opportunity__c = list_CarrierOrders[0].Benefit_Order__r.Opportunity__c;

				if (
					map_StatesName.containsKey(list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c) &&
					map_StatesName.get(list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c) != null &&
					map_StatesName.get(list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c) != ''
				)
					objTicketRecord.States__c = map_StatesName.get(list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c);
			}

			if (!list_CarrierOrders[0].Cases__r.isEmpty()) {
				objTicketRecord.Case__c = list_CarrierOrders[0].Cases__r[0].Id;
				objTicketRecord.Account__c = list_CarrierOrders[0].Cases__r[0].AccountId;
			}
		}

		fetchSubTeamForQCError();
		//set ticket owner when selected sub team changes
		assignOwner();
	}

	public void fetchSubTeamForQCError() {
		list_TeamsForQCError = new List<SelectOption>();
		list_TeamsForQCError.add(new SelectOption(NONE, NONE));
		list_TeamsForQCError.addAll(Cache.getFieldPickListValues(TicketUtil.OBJECT_QC_ERROR, TicketUtil.FIELD_TO_SUB_TEAM));
	}

	// Method to fetch all Ticket reason based on selected 'From', 'To' team and 'Reason'.
	public void ticketDetail() {
		Set<String> reasonDetailSet = new Set<String>();
		list_ReasonsDetail = new List<SelectOption>();

		// Query all Ticket Mapping records
		for (Ticket_Mapping__c objTM : [
			SELECT
				Id,
				Ticket_Reason_s__c,
				To_Sub_team__c,
				Automated_QC_Error_Required__c,
				Order_Status_when_Ticket_is_Closed__c,
				Order_Status_while_Ticket_is_Open__c,
				Ticket_Reason_Details__c,
				From_Sub_Team_s__c,
				To_Team__c
			FROM Ticket_Mapping__c
			WHERE From_Sub_Team_s__c = :objTicketRecord.Reporting_Team__c AND To_Team__c = :strSelectedTeam AND Ticket_Reason_s__c = :strSelectedReason
		]) {
			if (String.isNotBlank(objTM.Ticket_Reason_Details__c) && !reasonDetailSet.contains(objTM.Ticket_Reason_Details__c)) {
				if (String.isNotBlank(strSelectedSubTeam) && !NONE.equalsIgnoreCase(strSelectedSubTeam)) {
					if (strSelectedSubTeam.equalsIgnoreCase(objTM.To_Sub_team__c)) {
						list_ReasonsDetail.add(new SelectOption(objTM.Ticket_Reason_Details__c, objTM.Ticket_Reason_Details__c));
						reasonDetailSet.add(objTM.Ticket_Reason_Details__c);
					}
				} else if (String.isNotBlank(objQCError.To_Sub_team__c) && !NONE.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
					if (objQCError.To_Sub_team__c.equalsIgnoreCase(objTM.To_Sub_team__c)) {
						list_ReasonsDetail.add(new SelectOption(objTM.Ticket_Reason_Details__c, objTM.Ticket_Reason_Details__c));
						reasonDetailSet.add(objTM.Ticket_Reason_Details__c);
					}
				} else {
					list_ReasonsDetail.add(new SelectOption(objTM.Ticket_Reason_Details__c, objTM.Ticket_Reason_Details__c));
					reasonDetailSet.add(objTM.Ticket_Reason_Details__c);
				}
			}
			if (!map_TicketsMapping.containsKey(objTM.From_Sub_Team_s__c + strSelectedTeam + objTM.To_Sub_team__c + objTM.Ticket_Reason_s__c + objTM.Ticket_Reason_Details__c + ''))
				map_TicketsMapping.put(objTM.From_Sub_Team_s__c + strSelectedTeam + objTM.To_Sub_team__c + objTM.Ticket_Reason_s__c + objTM.Ticket_Reason_Details__c + '', objTM);
		}

		//Neha Dabas, 25thMArch 2020, Set Carrier if selectedreason is Underwriting Update
		if (REASON_CONCESSION_REIMBURSEMENT.equalsIgnoreCase(strSelectedReason) && list_CarrierOrders != null && list_CarrierOrders.size() > 0) {
			objTicketRecord.Carrier__c = list_CarrierOrders[0].Carrier__c;
			copyCarrierStatesToTicket();
		}

		onChangeDependentPicklist();
		if(!list_ReasonsDetail.isEmpty()){
			list_ReasonsDetail.sort();
			list_ReasonsDetail.add(0,new SelectOption(NONE, NONE));
		}else{
			list_ReasonsDetail.add(new SelectOption(NONE, NONE));
		}
	}

	/*
	 *Created By : Neha Dabas
	 *Created Date : 25 March 2020
	 *Description : For qualification ticket, copy States__c field from selected Carrier to Ticket record
	 */
	public PageReference copyCarrierStatesToTicket() {
		if (objTicketRecord != null && objTicketRecord.Carrier__c != null && REASON_CONCESSION_REIMBURSEMENT.equalsIgnoreCase(strSelectedReason)) {
			//Fetch carrier details
			Carrier__c objCarrier = [SELECT State__c FROM Carrier__c WHERE Id = :objTicketRecord.Carrier__c AND State__c != NULL];

			//Copy State value to ticket record
			if (objCarrier != null) {
				objTicketRecord.States__c = objCarrier.State__c;
			}
		}
		return null;
	}

	/*
	 *Created By : Neha Dabas
	 *Created Date : 8 Aug 2019
	 *Description : Method to fetch all Ticket reason based on selected 'From', 'To' team and 'ToSubTeam'.
	 */
	private void ticketReason() {
		Set<String> set_Reasons = new Set<String>();
		list_Reasons = new List<SelectOption>();
		list_ReasonsDetail = new List<SelectOption>();
		list_ReasonsDetail.add(new SelectOption(NONE, NONE));
		strSelectedReason = NONE;

		if (String.isNotBlank(objTicketRecord.Reporting_Team__c) && String.isNotBlank(strSelectedTeam) && !NONE.equalsIgnoreCase(strSelectedTeam)) {
			String strTicketMappingQuery =
				'Select id, Ticket_Reason_s__c, To_Sub_team__c, Automated_QC_Error_Required__c, Order_Status_when_Ticket_is_Closed__c, Order_Status_while_Ticket_is_Open__c, Ticket_Reason_Details__c, From_Sub_Team_s__c, To_Team__c FROM Ticket_Mapping__c WHERE From_Sub_Team_s__c =\'' +
				objTicketRecord.Reporting_Team__c +
				'\' And To_Team__c = \'' +
				strSelectedTeam +
				'\' ';

			if ('Ticket'.equalsIgnoreCase(strTypeOFRecordToBeCreated)) {
				strTicketMappingQuery += ' AND Order_Status_when_Ticket_is_Closed__c !=NULL AND Order_Status_while_Ticket_is_Open__c != Null';
			}

			List<Ticket_Mapping__c> list_TicketMaps = Database.query(strTicketMappingQuery);

			for (Ticket_Mapping__c objTM : list_TicketMaps) {
				if (String.isNotBlank(objTM.Ticket_Reason_s__c) && !set_Reasons.contains(objTM.Ticket_Reason_s__c)) {
					if (String.isNotBlank(strSelectedSubTeam) && !NONE.equalsIgnoreCase(strSelectedSubTeam)) {
						if (strSelectedSubTeam.equalsIgnoreCase(objTM.To_Sub_team__c)) {
							//[DS] If the Confirmation team create ticket Onborading to Implementation Advocate
							// and Carrier Order's Implemenation stage is Approved Pending EE Audit
							// Then Only Audit Error found should be shown in Ticket Reason.
							// if Carrier Order's Implmetation Stage is not Approved Pending EE Audit
							// Then Audit Error Found should not be shown in Ticket Reason.
							if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicketRecord.Reporting_Team__c) && TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(strSelectedSubTeam)) {
								if (
									!TicketUtil.TICKET_REASON_AUDIT_ERROR.equalsIgnoreCase(objTM.Ticket_Reason_s__c) &&
									CarrierOrderUtil.CO_STATUS_APPROVED_PENDING_EE_AUDIT.equalsIgnoreCase(list_CarrierOrders[0].Implementation_Stage__c)
								) {
									continue;
								}

								if (
									TicketUtil.TICKET_REASON_AUDIT_ERROR.equalsIgnoreCase(objTM.Ticket_Reason_s__c) &&
									!CarrierOrderUtil.CO_STATUS_APPROVED_PENDING_EE_AUDIT.equalsIgnoreCase(list_CarrierOrders[0].Implementation_Stage__c)
								) {
									continue;
								}
							}

							list_Reasons.add(new SelectOption(objTM.Ticket_Reason_s__c, objTM.Ticket_Reason_s__c));
							set_Reasons.add(objTM.Ticket_Reason_s__c);
						}
					} else if (String.isNotBlank(objQCError.To_Sub_team__c) && !NONE.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
						if (objQCError.To_Sub_team__c.equalsIgnoreCase(objTM.To_Sub_team__c)) {
							list_Reasons.add(new SelectOption(objTM.Ticket_Reason_s__c, objTM.Ticket_Reason_s__c));
							set_Reasons.add(objTM.Ticket_Reason_s__c);
						}
					} else {
						list_Reasons.add(new SelectOption(objTM.Ticket_Reason_s__c, objTM.Ticket_Reason_s__c));
						set_Reasons.add(objTM.Ticket_Reason_s__c);
					}
				}
			}
			if(!list_Reasons.isEmpty()){
				list_Reasons.sort();
				list_Reasons.add(0,new SelectOption(NONE, NONE));
			}else{
				list_Reasons.add(new SelectOption(NONE, NONE));
			}
		}
	}

	/*
	 *Created By : Neha Dabas
	 *Created Date : 25 July 2019
	 *Description : Assign owner to ticket based to strSelectedTeam and strSelectedSubTeam
	 */
	public PageReference assignOwner() {
		objQCError.Error_Owner__c = null;
		objBOTemp.Escalated_User__c = null; //Neha, using objBOTemp just to ensure that changing values for ownerId are recorded without setting OwnerId = NULL

		if (TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(strSelectedSubTeam)) {
			String strPreFix = String.valueOf(list_CarrierOrders[0].Benefit_Order__r.OwnerId).left(3).toLowercase();

			if (strPreFix == strUserPrefix) {
				objBOTemp.Escalated_User__c = list_CarrierOrders[0].Benefit_Order__r.OwnerId;
			}
		} else if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(strSelectedSubTeam)) {
			String strPreFix = String.valueOf(list_CarrierOrders[0].OwnerId).left(3).toLowercase();

			if (strPreFix == strUserPrefix) {
				objBOTemp.Escalated_User__c = list_CarrierOrders[0].OwnerId;
			} else if ((strPreFix != strUserPrefix || list_CarrierOrders[0].Sent_to_HI_for_Submission__c) && idAutomatedUser != null) {
				objBOTemp.Escalated_User__c = idAutomatedUser;
			}
		} else if (TicketUtil.TICKET_ROLE_IMPLEMENTATION_PE.equalsIgnoreCase(strSelectedSubTeam) && TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(objTicketRecord.Reporting_Team__c)) {
			//DS[31-07-2020] use User role instead of user object
			if (!list_Users.isEmpty() && list_Users[0].ManagerId != null) {
				objBOTemp.Escalated_User__c = list_Users[0].ManagerId;
			}
		} else if (
			TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam) ||
			TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(strSelectedTeam) ||
			TicketUtil.TICKET_TEAM_FULL_STACK_SALES.equalsIgnoreCase(strSelectedTeam) ||
			TicketUtil.TICKET_TEAM_BOR_SALES.equalsIgnoreCase(strSelectedTeam)
		) {
			objBOTemp.Escalated_User__c = list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.OwnerId;
		}

		if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
			objQCError.Error_Owner__c = list_CarrierOrders[0].OwnerId;
		}

		//fetch ticket reasons when selected team changes
		ticketReason();

		return null;
	}

	// Method to insert Ticket, QC Error and Ticket Status History.
	public PageReference saveTicket() {
		SavePoint objSavePoint = Database.setSavepoint();
		try {
			if (checkRequiredFields()) {
				return null;
			}

			// Sub Team as required when Team is Onboarding
			if (strSelectedTeam == TicketUtil.TICKET_TEAM_ONBOARDING && strSelectedSubTeam == NONE) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_SUB_TEAM));
				return null;
			}

			// Ticket Owner required
			if (TicketUtil.TICKET_ROLE_IMPLEMENTATION_AMPLIFIER.equalsIgnoreCase(strSelectedSubTeam) && objBOTemp.Escalated_User__c == null) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_TICKET_AMPLIFIER));
				return null;
			}

			// Ticket Reason required
			if (strSelectedReason == NONE) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_TICKET_REASON));
				return null;
			}

			if (strSelectedReasonDetail == NONE && list_ReasonsDetail.size() > 1) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_TICKET_REASON_DETAIL));
				return null;
			}

			if (strSelectedReason != NONE) {
				objTicketRecord.Escalation_Reason__c = strSelectedReason;
			}

			if (strSelectedReasonDetail != NONE) {
				objTicketRecord.Escalation_Reason_Detail__c = strSelectedReasonDetail;
			}

			objTicketRecord.Team__c = strSelectedTeam;

			if (strSelectedSubTeam != NONE) {
				objTicketRecord.Sub_Team__c = strSelectedSubTeam;
			}

			if (TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID;
			} else if (TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.NEW_PLAN_SALES_TICKET_RT_ID;
			} else if (TicketUtil.TICKET_MEMBER_PROCESSING.equalsIgnoreCase(strSelectedTeam) || TicketUtil.TICKET_MEMBER_OPERATIONS.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.MEMBER_OPERATIONS_TICKET_RT_ID;
			} else if (strSelectedTeam.contains(TicketUtil.TICKET_TEAM_ONBOARDING) && list_CarrierOrders[0].Benefit_Order__r.RecordTypeId == BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID;
			} else if (
				strSelectedTeam.contains(TicketUtil.TICKET_TEAM_ONBOARDING) &&
				(list_CarrierOrders[0].Benefit_Order__r.RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID ||
				list_CarrierOrders[0].Benefit_Order__r.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID)
			) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_ONBOARDING_RENEWAL_TICKET_RT_ID;
				blnIsOnboardingRenewal = true;
			} else if (TicketUtil.TICKET_BENEFIT_TRANSFER.equalsIgnoreCase(strSelectedTeam) || TicketUtil.TICKET_TEAM_BOR_SALES.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID;
			} else if (TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID;
			}

			/* Assign Ticket Owner
			 * Neha Dabas, 26-July-2019
			 * Using objBOTemp.Escalated_User__c just as a mask to show lookups on VF page for capturing ticket owner
			 * Neha Dabas, 25th March 2020, Ticket Owner need to be assigned only if its not a qualification ticket
			 */
			if (objBOTemp.Escalated_User__c != null) {
				objTicketRecord.Skip_Assignment__c = true;
				objTicketRecord.OwnerId = objBOTemp.Escalated_User__c;
			}

			objTicketRecord.Ticket_Status_Change_Date__c = System.now();

			/*
            if the Ticket owner is OA, and OA is has changed the role, or leaves the Gusto Company
            then We have change the ticket Owner. 
            */
			String strTicketMapKey =
				objTicketRecord.Reporting_Team__c +
				objTicketRecord.Team__c +
				objTicketRecord.Sub_Team__c +
				objTicketRecord.Escalation_Reason__c +
				objTicketRecord.Escalation_Reason_Detail__c +
				'';

			if (map_TicketsMapping.containsKey(strTicketMapKey) && map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c == TicketUtil.TICKET_ORDER_STATUS_NO_IMPACT) {
				blnIsNoStatusUpdate = true;
			}

			if (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_IMPLEMENTATION) {
				blnIsIAReassigned = UtilitiesFactory.reAssignIAForInvalidTicketOwner(objTicketRecord, list_BOs, blnIsNoStatusUpdate);
			} else if (
				objTicketRecord.OwnerId != null &&
				objTicketRecord.Sub_Team__c != null &&
				objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_FULFILLMENT &&
				idAutomatedUser != null &&
				objTicketRecord.OwnerId == idAutomatedUser
			) {
				//BY DS: Submission Automation
				blnIsRequireRouting = true;
			} else if (objTicketRecord.Sub_Team__c != null && (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_FULFILLMENT)) {
				Boolean blnCheckForReassignment = true;

				blnIsRequireRouting = UtilitiesFactory.CheckTicketOwnerIsValidOrNot(objTicketRecord.OwnerId, objTicketRecord.Sub_Team__c, blnCheckForReassignment);
			}

			//DS[11-09-2020] Track Qualification owner at the time of ticket creation
			if (String.isNotBlank(objTicketRecord.Sub_Team__c)) {
				if (objTicketRecord.OwnerId != null && String.valueOf(objTicketRecord.OwnerId).startsWith(strUserPrefix)) {
					objTicketRecord.Initial_owner__c = objTicketRecord.OwnerId;
				}
			}
			//DS[10-12-2020] Track Carrier Name at the time of ticket creation
			if (String.isNotBlank(objTicketRecord.Carrier_Order__c) && list_CarrierOrders != null && list_CarrierOrders.size() > 0 && list_CarrierOrders[0].Carrier__c != null) {
				objTicketRecord.Carrier__c = list_CarrierOrders[0].Carrier__c;
			}

			if (
				!map_TicketsMapping.isEmpty() &&
				map_TicketsMapping.containsKey(strTicketMapKey) &&
				map_TicketsMapping.get(strTicketMapKey).Order_Status_when_Ticket_is_Closed__c == TicketUtil.ORDER_STATUS_BACK_TO_PRIOR
			) {
				setInitialStatus();
			}

			TicketTriggerHelper.skipTrigger = true;
			insert objTicketRecord;

			List<Ticket__c> list_NewTickets = new List<Ticket__c>();
			list_NewTickets.add(objTicketRecord);
			TicketTriggerHelper.updateCarrierOrder(list_NewTickets, null);
			TicketTriggerHelper.skipTrigger = false;

			// Create Ticket Status History record
			Ticket_Status_History__c objTicketHistory = new Ticket_Status_History__c();
			objTicketHistory.End_Time__c = System.now();
			objTicketHistory.Ticket__c = objTicketRecord.Id;
			objTicketHistory.Start_Time__c = System.now();
			objTicketHistory.Ticket_Creation__c = true;
			objTicketHistory.Status_Change_User__c = UserInfo.getUserId();
			objTicketHistory.To_Status__c = TicketUtil.TICKET_STATUS_NEW;
			insert objTicketHistory;

			// Updating Benefit Order 'Status' and Carrier Order 'Implementation Stage' from related Ticket Mapping
			List<Carrier_Order__c> list_COsToBeUpdated = new List<Carrier_Order__c>();

			String strKey =
				objTicketRecord.Reporting_Team__c +
				objTicketRecord.Team__c +
				objTicketRecord.Sub_Team__c +
				objTicketRecord.Escalation_Reason__c +
				objTicketRecord.Escalation_Reason_Detail__c +
				'';
			if (map_TicketsMapping.containsKey(strKey)) {
				Benefit_Order__c objBOToBeUpdated = new Benefit_Order__c();

				if (objTicketRecord.Status__c != TicketUtil.TICKET_STATUS_CLOSED && map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c != TicketUtil.TICKET_ORDER_STATUS_NO_IMPACT) {
					if (map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c == TicketUtil.TICKET_ORDER_STATUS_REQUIRES_ER_OUTREACH) {
						objBOToBeUpdated = new Benefit_Order__c(Id = list_CarrierOrders[0].Benefit_Order__c);
						objBOToBeUpdated.Status_Detail__c = map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c;
					} else {
						list_CarrierOrders[0].Implementation_Stage__c = map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c;

						//DS:[11-11-2019] Follow update should be null when ever we are updating the Implemenation Stage of CO
						if (list_CarrierOrders[0].Follow_Up_Date__c != null)
							list_CarrierOrders[0].Follow_Up_Date__c = null;

						if (
							TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicketRecord.Reporting_Team__c) &&
							(map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c != TicketUtil.TICKET_ORDER_STATUS_PENDING_ITEM &&
							(!(map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c == TicketUtil.TICKET_ORDER_STATUS_BLOCKED &&
							map_TicketsMapping.get(strKey).Ticket_Reason_s__c == TicketUtil.TICKET_REASON_EXISTING_GROUP)))
						) {
							objBOToBeUpdated = new Benefit_Order__c(Id = list_CarrierOrders[0].Benefit_Order__c);

							objBOToBeUpdated.Order_Status__c = map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c;
						}

						if (
							map_TicketsMapping.get(strKey).Order_Status_while_Ticket_is_Open__c == TicketUtil.TICKET_ORDER_STATUS_BLOCKED &&
							objBOToBeUpdated.Order_Status__c == TicketUtil.TICKET_ORDER_STATUS_BLOCKED
						) {
							objBOToBeUpdated.Blocked_Reason__c = strSelectedReason;
						}
					}
				}

				Ticket__c objUpdatedTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicketRecord.Id];
				String strQCError = map_TicketsMapping.get(strKey).Automated_QC_Error_Required__c;

				// Create QC Error when 'Automated QC Error Required' as 'Yes' in Ticket Mapping
				if (TicketUtil.AUTOMATED_QC_ERROR_REQUIRED_VALUE_YES.equalsIgnoreCase(strQCError) || TicketUtil.AUTOMATED_QC_ERROR_REQUIRED_VALUE_OPPORTUNITY.equalsIgnoreCase(strQCError)) {
					QA_Errors__c objError = new QA_Errors__c();
					objError.Benefit_Order__c = list_CarrierOrders[0].Benefit_Order__c;
					objError.Carrier_Order__c = list_CarrierOrders[0].Id;
					objError.Description__c = objTicketRecord.Description__c;

					if (strSelectedReason != NONE)
						objError.Error_Type__c = strSelectedReason;

					if (strSelectedReasonDetail != NONE)
						objError.Error_Type_Detail__c = strSelectedReasonDetail;

					objError.From_Sub_Team_s__c = objTicketRecord.Reporting_Team__c;
					objError.Ticket__c = objTicketRecord.Id;

					if (TicketUtil.TICKET_BENEFIT_TRANSFER.equalsIgnoreCase(objTicketRecord.Team__c)) {
						objError.QA_Error_Team__c = TicketUtil.TICKET_BENEFIT_TRANSFER;
					} else if (TicketUtil.TICKET_MEMBER_PROCESSING.equalsIgnoreCase(objTicketRecord.Team__c) || TicketUtil.TICKET_MEMBER_OPERATIONS.equalsIgnoreCase(strSelectedTeam)) {
						objError.QA_Error_Team__c = TicketUtil.TICKET_MEMBER_OPERATIONS;
					} else if (TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(objTicketRecord.Team__c)) {
						objError.QA_Error_Team__c = TicketUtil.TICKET_TEAM_NEW_PLAN_SALES;
					} else if (TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(objTicketRecord.Team__c)) {
						objError.QA_Error_Team__c = TicketUtil.QA_ERROR_TEAM_ADVISING;
					} else if (TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE.equalsIgnoreCase(objTicketRecord.Team__c)) {
						objError.QA_Error_Team__c = TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE;
					} else if (TicketUtil.TICKET_TEAM_ONBOARDING.equalsIgnoreCase(objTicketRecord.Team__c)) {
						objError.QA_Error_Team__c = TicketUtil.TICKET_TEAM_ONBOARDING;
						objError.To_Sub_team__c = strSelectedSubTeam;
					}

					String strPreFix;

					if (TicketUtil.AUTOMATED_QC_ERROR_REQUIRED_VALUE_OPPORTUNITY.equalsIgnoreCase(strQCError) && list_CarrierOrders[0].Benefit_Order__r.Opportunity__c != null) {
						strPreFix = String.valueOf(list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.OwnerId).left(3).toLowercase();

						if (strPreFix == strUserPrefix) {
							objError.Error_Owner__c = list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.OwnerId;
						}
					} else {
						strPreFix = String.valueOf(objUpdatedTicket.OwnerId).left(3).toLowercase();

						if (strPreFix == strUserPrefix) {
							objError.Error_Owner__c = objUpdatedTicket.OwnerId;
						}
					}

					insert objError;
				}

				//reassign IA BO in case of Inactive User
				if (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_IMPLEMENTATION && blnIsIAReassigned) {
					//this Boolean is used to handle Case owner update in this scenario
					BenefitOrderHelper.blnIsInvalidIAReassignmentOnTicketCreation = true;

					List<Benefit_Order__c> list_ChildBo = [
						SELECT Id, OwnerId, Parent_Benefit_Order__c, Assignment_Message__c
						FROM Benefit_Order__c
						WHERE Parent_Benefit_Order__c = :list_BOs[0].Id AND OwnerId != :list_BOs[0].OwnerId
					];

					if (!list_ChildBo.isEmpty()) {
						for (Benefit_Order__c objBO : list_ChildBo) {
							objBO.OwnerId = list_BOs[0].OwnerId;
							map_BenefitOrdersToBeUpdated.put(objBO.Id, objBO);
						}
					}

					map_BenefitOrdersToBeUpdated.put(list_BOs[0].id, list_BOs[0]);

					if (!map_BenefitOrdersToBeUpdated.isEmpty()) {
						if (objBOToBeUpdated.Id != null && map_BenefitOrdersToBeUpdated.containsKey(objBOToBeUpdated.Id)) {
							objBOToBeUpdated.ownerId = map_BenefitOrdersToBeUpdated.get(objBOToBeUpdated.Id).ownerId;
							objBOToBeUpdated.Assignment_Message__c = map_BenefitOrdersToBeUpdated.get(objBOToBeUpdated.Id).Assignment_Message__c;
							map_BenefitOrdersToBeUpdated.put(objBOToBeUpdated.Id, objBOToBeUpdated);
						}

						update map_BenefitOrdersToBeUpdated.values();
					}

					BenefitOrderHelper.blnIsInvalidIAReassignmentOnTicketCreation = false;
				} else if (objBOToBeUpdated.Id != null) {
					update objBOToBeUpdated;
				}

				//DS[24/7/2020] for setting reRouting true in case ticket owner is not valid
				if (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_FULFILLMENT && !blnIsNoStatusUpdate) {
					list_CarrierOrders[0].Requires_Routing__c = blnIsRequireRouting;
				}

				update list_CarrierOrders[0];
			}

			strScript = '<script> RefreshPrimaryTab(); </script>';
			return null;
		} catch (Exception objEX) {
			Database.rollback(objSavePoint);
			objTicketRecord.Id = null;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, TicketUtil.MSG_ERROR_IN_TICKET_CREATION + ': ' + objEX.getMessage()));
			return null;
		}
	}

	// Method to Create New QC Error.
	public PageReference saveQCError() {
		try {
			// QC Error Team required
			if (strSelectedTeam == NONE) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_QC_ERROR_TEAM));
				return null;
			}

			if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
				if (String.isBlank(objQCError.Error_Owner__c)) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_QC_ERROR_OWNER));
					return null;
				}
			}

			// QC Error Type required
			if (strSelectedReason == NONE) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_QC_ERROR_TYPE));
				return null;
			}

			if (strSelectedReasonDetail == NONE && list_ReasonsDetail.size() > 1) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_QC_ERROR_TYPE_DETAIL));
				return null;
			}

			if (TicketUtil.TICKET_BENEFIT_TRANSFER.equalsIgnoreCase(strSelectedTeam)) {
				objQCError.QA_Error_Team__c = TicketUtil.TICKET_BENEFIT_TRANSFER;
			} else if (TicketUtil.TICKET_MEMBER_PROCESSING.equalsIgnoreCase(strSelectedTeam) || TicketUtil.TICKET_MEMBER_OPERATIONS.equalsIgnoreCase(strSelectedTeam)) {
				objQCError.QA_Error_Team__c = TicketUtil.TICKET_MEMBER_OPERATIONS;
			} else if (TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(strSelectedTeam)) {
				objQCError.QA_Error_Team__c = TicketUtil.TICKET_TEAM_NEW_PLAN_SALES;
			} else if (TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam)) {
				objQCError.QA_Error_Team__c = TicketUtil.QA_ERROR_TEAM_ADVISING;
			} else if (TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE.equalsIgnoreCase(strSelectedTeam)) {
				objQCError.QA_Error_Team__c = TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE;
			} else if (TicketUtil.TICKET_TEAM_ONBOARDING.equalsIgnoreCase(strSelectedTeam)) {
				objQCError.QA_Error_Team__c = TicketUtil.TICKET_TEAM_ONBOARDING;
			}

			if (strSelectedReason != NONE)
				objQCError.Error_Type__c = strSelectedReason;
			if (strSelectedReasonDetail != NONE)
				objQCError.Error_Type_Detail__c = strSelectedReasonDetail;

			// Assign Error Owner
			if (TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
				String strPreFix = String.valueOf(list_CarrierOrders[0].Benefit_Order__r.OwnerId).left(3).toLowercase();

				if (strPreFix == strUserPrefix) {
					objQCError.Error_Owner__c = list_CarrierOrders[0].Benefit_Order__r.OwnerId;
				}
			} else if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
				String strPreFix = String.valueOf(list_CarrierOrders[0].OwnerId).left(3).toLowercase();

				if (strPreFix == strUserPrefix) {
					objQCError.Error_Owner__c = list_CarrierOrders[0].OwnerId;
				}
			} else if (TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam) || TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(strSelectedTeam)) {
				String strPreFix = String.valueOf(list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.OwnerId).left(3).toLowercase();

				if (strPreFix == strUserPrefix) {
					objQCError.Error_Owner__c = list_CarrierOrders[0].Benefit_Order__r.Opportunity__r.OwnerId;
				}
			}
			//DS[24/7/2020] Saving skill type on QC Error level for reporting
			if (objQCError.To_Sub_team__c != null && (objQCError.To_Sub_team__c == TicketUtil.TICKET_ROLE_FULFILLMENT || objQCError.To_Sub_team__c == TicketUtil.TICKET_ROLE_IMPLEMENTATION)) {
				blnIsIAReassigned = UtilitiesFactory.CheckTicketOwnerIsValidOrNot(objQCError.Error_Owner__c, objQCError.To_Sub_team__c, false);
			}

			insert objQCError;
			strScript = '<script> RefreshPrimaryTab(); </script>';
			return null;
		} catch (Exception objEx) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Error in QC Error creation.'));
			return null;
		}
	}

	public void onChangeDependentPicklist() {
		//On change dependent picklist value.
		if (strSelectedReason == REASON_CONCESSION_REIMBURSEMENT && strSelectedTeam == TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE) {
			objTicketRecord.Escalation_Reason__c = strSelectedReason;

			if (TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID;
			}
		}
	}

	public Boolean checkRequiredFields() {
		Boolean blnRequired = false;
		if (strSelectedTeam == TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE) {
			if (strSelectedReason == REASON_CONCESSION_REIMBURSEMENT) {
				if (String.isBlank(objTicketRecord.Carrier__c)) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_CARRIER));
				} else if (String.isBlank(objTicketRecord.States__c)) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_STATES));
				} else if (String.isBlank(objTicketRecord.Error_Type__c)) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_ERROR_TYPE));
				} else if (String.isBlank(objTicketRecord.Error_Origin__c)) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_ERROR_ORIGIN));
				} else if (objTicketRecord.Error_Origin_Date__c == null) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_ERROR_ORIGIN_DATE));
				} else if (objTicketRecord.Reimbursement_Amount_Requested__c == null) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_IMREBURSEMENT_AMT_REQ));
				} else if (objTicketRecord.Number_of_Discounted_Months_Requested__c == null) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_DISCOUNT_MONTH_REQ));
				} else if (objTicketRecord.Discount_Amount_Requested__c == null) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_DISCOUNT_AMT_REQ));
				}
			}
		}

		if (strSelectedTeam == TicketUtil.TICKET_TEAM_NEW_PLAN_SALES || strSelectedTeam == TicketUtil.TICKET_TEAM_FULL_STACK_SALES) {
			if (objTicketRecord.Due_Date__c == null) {
				blnRequired = true;
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_DUE_DATE));
			}
		}

		if (strSelectedTeam == TicketUtil.TICKET_TEAM_ONBOARDING) {
			if (objTicketRecord.Summary__c == null) {
				blnRequired = true;
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_SUMMARY));
			}
		}

		if (String.isBlank(objTicketRecord.Description__c)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_DESCRIPTION));
			return null;
		}

		return blnRequired;
	}

	/**
	 * @author       Rushi Ravisaheb
	 * @description  This method is used to set the initial status of BO when ticket is created.
	 * @param        N/A
	 * @return       N/A
	 **/
	public void setInitialStatus() {
		if (!list_CarrierOrders.isEmpty()) {
			objTicketRecord.Initial_Status__c = list_CarrierOrders[0].Id + '=>' + list_CarrierOrders[0].Implementation_Stage__c;
		}
	}
}