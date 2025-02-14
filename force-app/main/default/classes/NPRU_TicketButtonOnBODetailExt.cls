/***************************************************
Purpose : Ticket Functionality: Creation of Ticket and QC Error from Benefit Order, View All Ticket related to Benefit Order.
Written By : Deepak Tyagi
Test Classes : NPRU_TicketButtonOnBODetailCtrlTest
****************************************************/
public class NPRU_TicketButtonOnBODetailExt {
	public Boolean blnIsOwnerQueue { get; set; }
	public String strAssignedQueueName { get; set; }
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
	//Neha, carrier order list for selection of ticket owner if  To Team = Onboarding & sub team = submission
	public List<SelectOption> list_COsOwner { get; set; }
	//Neha, to hold carrierOrder id and Co.OwnerId
	private Map<Id, Id> map_COToOwners;
	//DS[10-12-2020]: to hold Selected Carrier order's carrier
	private Map<Id, Id> map_COToCarrierIds;
	//Neha, to hold selected CarrierOrder when subTeam = Submission
	public String strSelectedCO { get; set; }
	public List<Benefit_Order__c> list_BenefitOrders { get; set; }
	// Check if Record Type is Onboarding Renewal
	public Boolean blnIsOnboardingRenewal { get; set; }
	public String strScript { get; set; }
	public Boolean blnIsBenefitsBYB { get; set; }
	// Store sorting field name
	String strSortField;
	// Store Previous sorting field name
	String strPreSortField;
	// Store Previous sorting order
	String strPreviousSortOrder;
	Map<String, Ticket_Mapping__c> map_TicketsMapping = new Map<String, Ticket_Mapping__c>();
	//User userObj;
	List<User_Role__c> list_UserRoles = new List<User_Role__c>();
	// this Variable comtains the value as 'Ticket' or 'QC Error'
	String strTypeOFRecordToBeCreated;
	// to mark Require routing in BO
	Boolean blnIsRequireRouting;
	Boolean blnIsNoStatusUpdate = false;
	Boolean blnIsIAReassigned = false;
	Map<Id, Benefit_Order__c> map_BenefitOrdersToBeUpdated = new Map<Id, Benefit_Order__c>();

	//To check if there is an error in page
	public Boolean blnHasError {
		get {
			return ApexPages.hasMessages();
		}
	}
	private static final String NONE = 'None';
	//BY DS[28th Jan 2021]: Submission Automation
	Set<String> set_COIdsSubmissionAuto = new Set<String>();
	static String strUserPrefix = '005';
	static final Id idAutomatedUser = HIGroupEventUtil.fetchAutomatedUserId();
	static final Id idRPAAutomation = Label.RPA_Automation_User_Id;
	public static final String REASON_CONCESSION_REIMBURSEMENT = 'Concession/Reimbursement';
	public static final String REASON_LICENSING = 'Licensing';
	public static final Id BO_REC_TYPE_ID_BYB = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB');

	// store From team
	public List<SelectOption> list_FromTeams { get; set; }
	Set<String> set_ReportingTeams = new Set<String>();
	static Id idLoggedInUser = UserInfo.getUserId();
	public static Set<String> set_CanceledStatus = new Set<String>{ 'Canceled', 'Closed Lost', 'Closed Admin' };

	public NPRU_TicketButtonOnBODetailExt(ApexPages.StandardController sc) {
		strAssignedQueueName = '';
		strSortField = '';
		list_BenefitOrders = new List<Benefit_Order__c>();
		objQCError = new QA_Errors__c();
		objBOTemp = new Benefit_Order__c();
		blnIsOnboardingRenewal = false;
		list_ReasonsDetail = new List<SelectOption>();
		blnIsRequireRouting = false;
		blnIsOwnerQueue = false;
		list_FromTeams = new List<SelectOption>();
		strCurrentRecord = ApexPages.CurrentPage().getparameters().get('id');
		strTypeOFRecordToBeCreated = ApexPages.CurrentPage().getparameters().get('from');

		list_UserRoles = [
			SELECT Id, User__c, User__r.ManagerId, User_Skill_Team__c, User_Skill_Type__c
			FROM User_Role__c
			WHERE User__c = :idLoggedInUser
			LIMIT 1
		];

		list_BenefitOrders = [
			SELECT
				Id,
				ZP_Company_Id__c,
				Order_Status__c,
				UW_Owner__c,
				Coverage_Effective_Date__c,
				OwnerId,
				RecordTypeId,
				Recordtype.Name,
				Opportunity__c,
				Opportunity__r.Account_Filing_State__c,
				Opportunity__r.RecordTypeId,
				Opportunity__r.Renewal_Date__c,
				Opportunity__r.OwnerId,
				Opportunity__r.Owner_Role_Name__c,
				Partner_Tier__c,
				Assignment_State__c,
				Parent_Benefit_Order__c,
				Coverage_Effective_Month__c,
				Coverage_Effective_Year__c,
				Type__c,
				Tier__c,
				Initial_Owner__c,
				Submission_Deadline__c,
				Account__c,
				Account__r.Priority_Support__c,
				Maestro__c,
				(
					SELECT Id, Implementation_Stage__c, Name, OwnerId, Confirmation_Owner__c, Audit_Owner__c, Carrier__c, Sent_to_HI_for_Submission__c
					FROM Carrier_Orders__r
					WHERE
						Order_Type__c != :CarrierOrderUtil.ORDER_TYPE_TERMINATED_ORDER
						AND Order_Type__c != :CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP
						AND Order_Type__c != :CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE
						AND Implementation_Stage__c NOT IN :set_CanceledStatus
				),
				(SELECT Id, AccountId FROM Cases__r WHERE Type = :TicketUtil.CASE_TYPE_NEW_PLAN OR Type = :TicketUtil.CASE_TYPE_RENEWAL OR Type = :TicketUtil.CASE_TYPE_BYOB)
			FROM Benefit_Order__c
			WHERE Id = :strCurrentRecord
		];

		objTicketRecord = new Ticket__c();

		if (!list_BenefitOrders.isEmpty() && list_BenefitOrders[0].RecordTypeId == BO_REC_TYPE_ID_BYB) {
			blnIsBenefitsBYB = true;
		}

		if (!list_BenefitOrders.isEmpty() && list_BenefitOrders[0].RecordTypeId == BO_REC_TYPE_ID_BYB) {
			blnIsBenefitsBYB = true;
		}

		if (!list_UserRoles.isEmpty()) {
			populateInitialReportingTeam();
			if (objTicketRecord.Reporting_Team__c == null) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_NOT_ALLOWED_TO_CREATE_TICKET));
			} else {
				ticketToTeam();
			}
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_NOT_ALLOWED_TO_CREATE_TICKET));
		}

		//Neha, 16 Aug 2019, Fetch all tickets related to BO irrespective of owner
		list_Tickets = [SELECT Id, Name, Escalation_Reason__c, Owner.Name, Status__c FROM Ticket__c WHERE Benefit_Order__c = :strCurrentRecord ORDER BY CreatedDate DESC LIMIT 5];

		// fetching all ticket related to Benefit Order on selected view.
		allTickets();
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Populated the Reporting team on UI
	 * @Parm        : null
	 * @Return      : null
	 **/
	public void populateInitialReportingTeam() {
		String strReportingTeam = '';

		if (String.isNotBlank(list_UserRoles[0].User_Skill_Team__c)) {
			strReportingTeam = list_UserRoles[0].User_Skill_Team__c;

			if (String.isNotBlank(strReportingTeam)) {
				if (strReportingTeam == TicketUtil.TICKET_TEAM_ADVISING) {
					set_ReportingTeams.add(TicketUtil.TICKET_ROLE_IMPLEMENTATION);
					list_FromTeams.add(new SelectOption(TicketUtil.TICKET_ROLE_IMPLEMENTATION, TicketUtil.TICKET_ROLE_IMPLEMENTATION));
				} else {
					set_ReportingTeams.add(strReportingTeam);
					list_FromTeams.add(new SelectOption(strReportingTeam, strReportingTeam));
				}
			}
		}

		if (!set_ReportingTeams.isEmpty()) {
			objTicketRecord.Reporting_Team__c = (new List<String>(set_ReportingTeams))[0];
			objQCError.From_Sub_Team_s__c = objTicketRecord.Reporting_Team__c;
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Populated the TO Team Field on UI
	 * @param        null
	 * @return       null
	 **/
	public void ticketToTeam() {
		ApexPages.getMessages().clear();
		strSelectedTeam = NONE;
		strSelectedSubTeam = NONE;
		strSelectedReason = '';
		strSelectedReasonDetail = '';
		strSelectedCO = '';
		list_Teams = new List<SelectOption>();
		list_Teams.add(new SelectOption(NONE, NONE));
		Set<String> set_TeamTickets = new Set<String>();

		for (Ticket_Mapping__c objTicket : [SELECT Id, From_Sub_Team_s__c, To_Team__c FROM Ticket_Mapping__c WHERE From_Sub_Team_s__c = :objTicketRecord.Reporting_Team__c]) {
			if (!set_TeamTickets.contains(objTicket.To_Team__c)) {
				if (String.isNotBlank(objTicket.To_Team__c)) {
					if (TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(objTicketRecord.Reporting_Team__c)) {
						if (list_BenefitOrders[0].Recordtype.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN && TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(objTicket.To_Team__c)) {
							continue;
						}

						if (
							(list_BenefitOrders[0].Recordtype.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_CHANGE || list_BenefitOrders[0].Recordtype.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL) &&
							TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(objTicket.To_Team__c)
						) {
							continue;
						}
					}

					list_Teams.add(new SelectOption(objTicket.To_Team__c, objTicket.To_Team__c));
					set_TeamTickets.add(objTicket.To_Team__c);
				}
			}
		}
	}

	// Method to show all ticket related to Benefit Order on selected view.
	public void allTickets() {
		strSortField = apexPages.currentPage().getParameters().get('sortField');
		String strSelectedView = ApexPages.CurrentPage().getparameters().get('selectedView');
		String strSortTickets = '';
		String strQueryTicket = '';

		if (String.isNotBlank(strSortField)) {
			if (strPreSortField == strSortField && strPreviousSortOrder == 'ASC') {
				strPreviousSortOrder = 'DESC';
			} else {
				strPreviousSortOrder = 'ASC';
			}

			strPreSortField = strSortField;
			strSortTickets = ' ORDER BY ' + strSortField + ' ' + strPreviousSortOrder;
		}

		if (TicketUtil.LABEL_ALL.equalsIgnoreCase(strSelectedView)) {
			strQueryTicket =
				'SELECT Id, Name, Escalation_Reason__c, ' +
				'CreatedDate, CreatedBy.FirstName, ' +
				'LastModifiedBy.FirstName, Owner.Name, ' +
				'Description__c, LastModifiedDate, ' +
				'Status__c FROM Ticket__c WHERE Benefit_Order__c = :strCurrentRecord' +
				strSortTickets;
			list_Tickets = Database.query(strQueryTicket);
		} else if (TicketUtil.LABEL_MY.equalsIgnoreCase(strSelectedView)) {
			strQueryTicket =
				'SELECT Id, Name, Escalation_Reason__c, ' +
				'CreatedDate, CreatedBy.FirstName, ' +
				'LastModifiedBy.FirstName, Owner.Name, ' +
				'Description__c, LastModifiedDate, ' +
				'Status__c FROM Ticket__c WHERE ' +
				'(OwnerId = :idLoggedInUser OR LastModifiedById = :idLoggedInUser ' +
				'OR CreatedById = :idLoggedInUser) AND Benefit_Order__c = :strCurrentRecord' +
				strSortTickets;
			list_Tickets = Database.query(strQueryTicket);
		}
	}

	// Method to fetch all Ticket reason based on selected 'From' and 'To' team.
	public void subTeam() {
		strSelectedReason = '';
		strSelectedReasonDetail = '';
		strSelectedCO = '';
		objTicketRecord.Status__c = TicketUtil.TICKET_STATUS_NEW;
		strSelectedSubTeam = NONE;
		list_SubTeams = new List<SelectOption>();
		list_SubTeams.add(new SelectOption(NONE, NONE));
		Set<String> set_SubTeams = new Set<String>(); //Neha, 8 Aug 2019
		Map<String, String> stateNameMap = new Map<String, String>();

		// Query all State from custom setting
		for (State_Name_to_abbreviations_Mapping__c st : State_Name_to_abbreviations_Mapping__c.getall().values()) {
			if (!stateNameMap.containsKey(st.State_Name__c)) {
				stateNameMap.put(st.State_Name__c, st.State_Abbreviation__c);
			}
		}

		// fetch Benefit Order and related related records by Id from Parameter
		objQCError.Benefit_Order__c = list_BenefitOrders[0].Id;

		// Query all Ticket Mapping records
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
				String strTicketMapKey = objTM.From_Sub_Team_s__c + strSelectedTeam + objTM.To_Sub_team__c + objTM.Ticket_Reason_s__c + objTM.Ticket_Reason_Details__c + '';
				if (!map_TicketsMapping.containsKey(strTicketMapKey)) {
					map_TicketsMapping.put(strTicketMapKey, objTM);
				}

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
					if (objTM.To_Sub_team__c == TicketUtil.TICKET_ROLE_IMPLEMENTATION && objTM.From_Sub_Team_s__c == TicketUtil.TICKET_ROLE_CARRIER_IO) {
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
		if (!list_BenefitOrders.isEmpty()) {
			objTicketRecord.Benefit_Order__c = strCurrentRecord;
			//Neha, 14 Aug, This should be set to Coverage_Effective_Date__c on BO
			objTicketRecord.Renewal_Date__c = list_BenefitOrders[0].Coverage_Effective_Date__c;

			if (list_BenefitOrders[0].Opportunity__c != null) {
				objTicketRecord.Opportunity__c = list_BenefitOrders[0].Opportunity__c;
				if (
					stateNameMap.containsKey(list_BenefitOrders[0].Opportunity__r.Account_Filing_State__c) &&
					stateNameMap.get(list_BenefitOrders[0].Opportunity__r.Account_Filing_State__c) != null &&
					stateNameMap.get(list_BenefitOrders[0].Opportunity__r.Account_Filing_State__c) != ''
				) {
					objTicketRecord.States__c = stateNameMap.get(list_BenefitOrders[0].Opportunity__r.Account_Filing_State__c);
				}
			}

			if (!list_BenefitOrders[0].Cases__r.isEmpty()) {
				objTicketRecord.Case__c = list_BenefitOrders[0].Cases__r[0].Id;
				objTicketRecord.Account__c = list_BenefitOrders[0].Cases__r[0].AccountId;
			}
		}

		fetchSubTeamForQCError();
		//set ticket owner when subTeam selection changes
		assignOwner();
	}
	public void fetchSubTeamForQCError() {
		list_TeamsForQCError = new List<SelectOption>();
		list_TeamsForQCError.add(new SelectOption(NONE, NONE));
		list_TeamsForQCError.addAll(Cache.getFieldPickListValues(TicketUtil.OBJECT_QC_ERROR, TicketUtil.FIELD_TO_SUB_TEAM));
	}

	// Method to fetch all Ticket reason based on selected 'From', 'To' team and 'Reason'.
	public void ticketDetail() {
		Set<String> set_ReasonDetails = new Set<String>();
		list_ReasonsDetail = new List<SelectOption>();
		setAlegeusCOForSubmission();

		// Query all Ticket Mapping records
		for (Ticket_Mapping__c objTM : [
			SELECT
				Id,
				Ticket_Reason_s__c,
				Automated_QC_Error_Required__c,
				To_Sub_team__c,
				Order_Status_when_Ticket_is_Closed__c,
				Order_Status_while_Ticket_is_Open__c,
				Ticket_Reason_Details__c,
				From_Sub_Team_s__c,
				To_Team__c
			FROM Ticket_Mapping__c
			WHERE From_Sub_Team_s__c = :objTicketRecord.Reporting_Team__c AND To_Team__c = :strSelectedTeam AND Ticket_Reason_s__c = :strSelectedReason
		]) {
			if (String.isNotBlank(objTM.Ticket_Reason_Details__c) && !set_ReasonDetails.contains(objTM.Ticket_Reason_Details__c)) {
				if (String.isNotBlank(strSelectedSubTeam) && !NONE.equalsIgnoreCase(strSelectedSubTeam)) {
					if (strSelectedSubTeam.equalsIgnoreCase(objTM.To_Sub_team__c)) {
						list_ReasonsDetail.add(new SelectOption(objTM.Ticket_Reason_Details__c, objTM.Ticket_Reason_Details__c));

						set_ReasonDetails.add(objTM.Ticket_Reason_Details__c);
					}
				} else if (String.isNotBlank(objQCError.To_Sub_team__c) && !NONE.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
					if (objQCError.To_Sub_team__c.equalsIgnoreCase(objTM.To_Sub_team__c)) {
						list_ReasonsDetail.add(new SelectOption(objTM.Ticket_Reason_Details__c, objTM.Ticket_Reason_Details__c));

						set_ReasonDetails.add(objTM.Ticket_Reason_Details__c);
					}
				} else {
					list_ReasonsDetail.add(new SelectOption(objTM.Ticket_Reason_Details__c, objTM.Ticket_Reason_Details__c));

					set_ReasonDetails.add(objTM.Ticket_Reason_Details__c);
				}
			}

			String strTicketMappingKey = objTM.From_Sub_Team_s__c + strSelectedTeam + objTM.To_Sub_team__c + objTM.Ticket_Reason_s__c + objTM.Ticket_Reason_Details__c + '';

			if (!map_TicketsMapping.containsKey(strTicketMappingKey)) {
				map_TicketsMapping.put(strTicketMappingKey, objTM);
			}
		}

		onChangeDependentPicklist();
		updateTicketOwner();
		if(!list_ReasonsDetail.isEmpty()){
			list_ReasonsDetail.sort();
			list_ReasonsDetail.add(0,new SelectOption(NONE, NONE));
		}else{
			list_ReasonsDetail.add(new SelectOption(NONE, NONE));
		}
	}
	//set the only Alegeus carrier Order in the Selection list
	public PageReference setAlegeusCOForSubmission() {
		if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(strSelectedSubTeam) && TicketUtil.TICKET_REASON_TADA_TERMINATION.equalsIgnoreCase(strSelectedReason)) {
			objQCError.Error_Owner__c = null;
			objBOTemp.Escalated_User__c = null;
			blnIsOwnerQueue = false;
			strAssignedQueueName = '';
			map_COToOwners = new Map<Id, Id>();
			map_COToCarrierIds = new Map<Id, Id>();
			set_COIdsSubmissionAuto = new Set<String>();
			List<Carrier_Order__c> list_AlegeusCarrierOrder = new List<Carrier_Order__c>();

			list_AlegeusCarrierOrder = [
				SELECT Id, Implementation_Stage__c, Name, OwnerId, Confirmation_Owner__c, Audit_Owner__c, Carrier__c, Sent_to_HI_for_Submission__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c = :strCurrentRecord AND (Order_Type__c = :CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP OR Order_Type__c = :CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE)
			];

			list_COsOwner = new List<SelectOption>();
			updateTicketOwnerForSubmission(list_AlegeusCarrierOrder, map_COToOwners, map_COToCarrierIds);
		} else if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(strSelectedSubTeam) && !TicketUtil.TICKET_REASON_TADA_TERMINATION.equalsIgnoreCase(strSelectedReason)) {
			objQCError.Error_Owner__c = null;
			objBOTemp.Escalated_User__c = null;
			blnIsOwnerQueue = false;
			strAssignedQueueName = '';
			map_COToOwners = new Map<Id, Id>();
			map_COToCarrierIds = new Map<Id, Id>();
			list_COsOwner = new List<SelectOption>();
			set_COIdsSubmissionAuto = new Set<String>();
			updateTicketOwnerForSubmission(list_BenefitOrders[0].Carrier_Orders__r, map_COToOwners, map_COToCarrierIds);
		}

		return null;
	}

	//update the ticket Owner for Submission Case
	private void updateTicketOwnerForSubmission(List<Carrier_Order__c> list_CarrierOrder, Map<Id, Id> map_COToOwners, Map<Id, Id> map_COToCarrierIds) {
		if (!list_CarrierOrder.isEmpty()) {
			list_COsOwner = new List<SelectOption>();
			Integer intIndex = 0;

			for (Carrier_Order__c objCO : list_CarrierOrder) {
				String strPrefix = String.valueOf(objCO.OwnerId).left(3).toLowercase();

				if (intIndex == 0) {
					strSelectedCO = objCO.Id;
					if (strPrefix == strUserPrefix) {
						objBOTemp.Escalated_User__c = objCO.OwnerId;
					} else {
						objBOTemp.Escalated_User__c = idAutomatedUser;
					}
					intIndex++;
				}

				if (strPrefix != strUserPrefix) {
					map_COToOwners.put(objCO.Id, idAutomatedUser);
				} else {
					map_COToOwners.put(objCO.Id, objCO.OwnerId);
				}

				if (String.isNotBlank(objCO.Carrier__c)) {
					map_COToCarrierIds.put(objCO.Id, objCO.Carrier__c);
				}

				list_COsOwner.add(new SelectOption(objCO.Id, objCO.Name));

				//BY DS[28th Jan 2021]: Submission Automation
				if (objCO.Sent_to_HI_for_Submission__c) {
					set_COIdsSubmissionAuto.add(objCO.Id);
				}
				
			}
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_ASSOCIATED_CARRIER));
		}
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
		}
		if(!list_Reasons.isEmpty()){
			list_Reasons.sort();
			list_Reasons.add(0,new SelectOption(NONE, NONE));
		}else{
			list_Reasons.add(new SelectOption(NONE, NONE));
		}
	}

	/*
	 *Created By : Neha Dabas
	 *Created Date : 8 Aug 2019
	 *Description : Assign owner to ticket if strSelectedSubTeam is Submission
	 */

	public PageReference assignOwnerFromCO() {
		if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(strSelectedSubTeam)) {
			if (String.isNotBlank(strSelectedCO) && map_COToOwners?.containsKey(strSelectedCO)) {
				objBOTemp.Escalated_User__c = map_COToOwners.get(strSelectedCO);
			}
		}

		if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
			if (String.isNotBlank(strSelectedCO) && map_COToOwners?.containsKey(strSelectedCO)) {
				objQCError.Error_Owner__c = map_COToOwners.get(strSelectedCO);
			}
		}

		return null;
	}

	/*
	 *Created By : Neha Dabas
	 *Created Date : 24 March 2020
	 *Description : For qualification ticket, copy States__c field from selected Carrier to Ticket record
	 */
	public PageReference copyCarrierStatesToTicket() {
		if (objTicketRecord?.Carrier__c != null && REASON_CONCESSION_REIMBURSEMENT.equalsIgnoreCase(strSelectedReason)) {
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
	 *Created Date : 24 July 2019
	 *Description : Assign owner to ticket based to strSelectedTeam and strSelectedSubTeam
	 */
	public PageReference assignOwner() {
		objQCError.Error_Owner__c = null;
		// using objBOTemp just to ensure that changing values for ownerId are recorded without setting OwnerId = NULL
		objBOTemp.Escalated_User__c = null;
		blnIsOwnerQueue = false;
		strAssignedQueueName = '';
		map_COToOwners = new Map<Id, Id>();
		//DS[10-12-2020]:https://app.asana.com/0/1197452023400782/1197910021775329
		map_COToCarrierIds = new Map<Id, Id>();
		set_COIdsSubmissionAuto = new Set<String>();

		// Assign Ticket Owner based on Ticket team and Sub Team
		if (TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(strSelectedSubTeam)) {
			String strPreFix = String.valueOf(list_BenefitOrders[0].OwnerId).left(3).toLowercase();

			if (strPreFix == strUserPrefix) {
				objBOTemp.Escalated_User__c = list_BenefitOrders[0].OwnerId;
			}
		} else if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(strSelectedSubTeam) || TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
			if (!list_BenefitOrders[0].Carrier_Orders__r.isEmpty()) {
				list_COsOwner = new List<SelectOption>();
				Integer intIndex = 0;

				for (Carrier_Order__c objCO : list_BenefitOrders[0].Carrier_Orders__r) {
					String strPreFix = String.valueOf(objCO.OwnerId).left(3).toLowercase();
					if (intIndex == 0) {
						strSelectedCO = objCO.Id;
						if (strPreFix == strUserPrefix) {
							objBOTemp.Escalated_User__c = objCO.OwnerId;
							objQCError.Error_Owner__c = objCO.OwnerId;
						} else {
							objBOTemp.Escalated_User__c = idAutomatedUser;
							objQCError.Error_Owner__c = idAutomatedUser;
						}
						intIndex++;
					}
					if (strPreFix != strUserPrefix) {
						map_COToOwners.put(objCO.Id, idAutomatedUser);
					} else {
						map_COToOwners.put(objCO.Id, objCO.OwnerId);
					}

					if (String.isNotBlank(objCO.Carrier__c)) {
						map_COToCarrierIds.put(objCO.Id, objCO.Carrier__c);
					}
					list_COsOwner.add(new SelectOption(objCO.Id, objCO.Name));

					//BY DS[28th Jan 2021]: Submission Automation
					if (objCO.Sent_to_HI_for_Submission__c) {
						set_COIdsSubmissionAuto.add(objCO.Id);
					}
					
				}
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_ASSOCIATED_CARRIER));
				return null;
			}
		} else if (TicketUtil.TICKET_ROLE_IMPLEMENTATION_PE.equalsIgnoreCase(strSelectedSubTeam) && TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(objTicketRecord.Reporting_Team__c)) {
			if (!list_UserRoles.isEmpty() && list_UserRoles[0].User__r.ManagerId != null) {
				objBOTemp.Escalated_User__c = list_UserRoles[0].User__r.ManagerId;
			}
		} else if (
			TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam) ||
			TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(strSelectedTeam) ||
			TicketUtil.TICKET_TEAM_FULL_STACK_SALES.equalsIgnoreCase(strSelectedTeam) ||
			TicketUtil.TICKET_TEAM_BOR_SALES.equalsIgnoreCase(strSelectedTeam)
		) {
			objBOTemp.Escalated_User__c = list_BenefitOrders[0].Opportunity__r.OwnerId;
		} else if (TicketUtil.TICKET_TEAM_BYB_MEMBER_OPS.equalsIgnoreCase(strSelectedTeam)) {
			strAssignedQueueName = TicketUtil.QUEUE_MEMBER_FULFILLMENT_BYB;
			blnIsOwnerQueue = true;
		}

		//Load ticket reason on change of team selection
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

			if (TicketUtil.TICKET_TEAM_ONBOARDING.equalsIgnoreCase(strSelectedTeam) && strSelectedSubTeam == NONE) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_SUB_TEAM));

				return null;
			}

			if (TicketUtil.TICKET_ROLE_IMPLEMENTATION_AMPLIFIER.equalsIgnoreCase(strSelectedSubTeam) && objBOTemp.Escalated_User__c == null) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_TICKET_AMPLIFIER));

				return null;
			}

			if (strSelectedReason == NONE) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_TICKET_REASON));

				return null;
			}

			if (strSelectedReasonDetail == NONE && list_ReasonsDetail.size() > 1) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_TICKET_REASON_DETAIL));

				return null;
			}

			/*
			 * Neha Dabas, 19th August 2019, Carrier Order must be associated when ticket is created to Submission team
			 */
			if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(strSelectedSubTeam) && String.isBlank(strSelectedCO)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_ASSOCIATED_CARRIER));

				return null;
			}

			if (String.isBlank(objTicketRecord.Description__c) && list_BenefitOrders[0].RecordTypeId == BO_REC_TYPE_ID_BYB) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_DESCRIPTION));
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

			if (TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam) && list_BenefitOrders[0].RecordTypeId != BO_REC_TYPE_ID_BYB) {
				objTicketRecord.RecordTypeId = TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID;
			} else if (TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.NEW_PLAN_SALES_TICKET_RT_ID;
			} else if (TicketUtil.TICKET_MEMBER_PROCESSING.equalsIgnoreCase(strSelectedTeam) || TicketUtil.TICKET_MEMBER_OPERATIONS.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.MEMBER_OPERATIONS_TICKET_RT_ID;
			} else if (strSelectedTeam.contains(TicketUtil.TICKET_TEAM_ONBOARDING) && list_BenefitOrders[0].RecordTypeId == BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID;
			} else if (
				strSelectedTeam.contains(TicketUtil.TICKET_TEAM_ONBOARDING) &&
				(list_BenefitOrders[0].RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID ||
				list_BenefitOrders[0].RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID)
			) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_ONBOARDING_RENEWAL_TICKET_RT_ID;
				blnIsOnboardingRenewal = true;
			} else if (
				TicketUtil.TICKET_BENEFIT_TRANSFER.equalsIgnoreCase(strSelectedTeam) ||
				(TicketUtil.TICKET_TEAM_BOR_SALES.equalsIgnoreCase(strSelectedTeam) && list_BenefitOrders[0].RecordTypeId != BO_REC_TYPE_ID_BYB)
			) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID;
			} else if (TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE.equalsIgnoreCase(strSelectedTeam)) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID;
			} else if (
				TicketUtil.TICKET_TEAM_BYB_MEMBER_OPS.equalsIgnoreCase(strSelectedTeam) ||
				(TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam) && list_BenefitOrders[0].RecordTypeId == BO_REC_TYPE_ID_BYB) ||
				(TicketUtil.TICKET_TEAM_BOR_SALES.equalsIgnoreCase(strSelectedTeam) && list_BenefitOrders[0].RecordTypeId == BO_REC_TYPE_ID_BYB)
			) {
				objTicketRecord.RecordTypeId = TicketUtil.BENEFITS_BYB_TICKET_RT_ID;
			}

			/* Assign Ticket Owner
			 * Neha Dabas, 26-July-2019
			 * Using objBOTemp.Escalated_User__c just as a mask to show lookups on VF page for capturing ticket owner,
			 * Neha Dabas, 24th March 2020, Ticket Owner need to be assigned only if its not a qualification ticket
			 */
			if (blnIsOwnerQueue && String.isNotBlank(strAssignedQueueName) && !TicketUtil.map_AdvisingQueue.isEmpty() && TicketUtil.map_AdvisingQueue.containsKey(strAssignedQueueName)) {
				objTicketRecord.Skip_Assignment__c = true;
				objTicketRecord.OwnerId = TicketUtil.map_AdvisingQueue.get(strAssignedQueueName);
			} else if (objBOTemp.Escalated_User__c != null) {
				objTicketRecord.Skip_Assignment__c = true;
				objTicketRecord.OwnerId = objBOTemp.Escalated_User__c;
			}

			if (TicketUtil.TICKET_ROLE_IMPLEMENTATION_AMPLIFIER.equalsIgnoreCase(strSelectedSubTeam)) {
				objTicketRecord.Skip_Assignment__c = true;
			}

			/* Assign Carrier Order when subTeam is Submission
			 * Neha Dabas, 8- Aug -2019
			 */
			if ((TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(strSelectedSubTeam)) && String.isNotBlank(strSelectedCO)) {
				objTicketRecord.Carrier_Order__c = strSelectedCO;

				//DS[10-12-2020] Track Carrier Name at the time of ticket creation
				if (!map_COToCarrierIds.isEmpty() && map_COToCarrierIds.containsKey(strSelectedCO)) {
					objTicketRecord.Carrier__c = map_COToCarrierIds.get(strSelectedCO);
				}
			}

			objTicketRecord.Ticket_Status_Change_Date__c = System.now();

			/*Written by DS
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
				blnIsIAReassigned = UtilitiesFactory.reAssignIAForInvalidTicketOwner(objTicketRecord, list_BenefitOrders, blnIsNoStatusUpdate);
			} else if (
				objTicketRecord.OwnerId != null &&
				objTicketRecord.Sub_Team__c != null &&
				TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicketRecord.Sub_Team__c) &&
				idAutomatedUser != null &&
				idRPAAutomation != null &&
				(objTicketRecord.OwnerId == idAutomatedUser ||
				objTicketRecord.OwnerId == idRPAAutomation )
			) {
				blnIsRequireRouting = true;
			} else if (objTicketRecord.Sub_Team__c != null && (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_FULFILLMENT)) {
				Boolean blnCheckForReassignment = true;

				blnIsRequireRouting = UtilitiesFactory.CheckTicketOwnerIsValidOrNot(objTicketRecord.OwnerId, objTicketRecord.Sub_Team__c, blnCheckForReassignment);
			}
			//DS[11-09-2020] Track Qualification owner at the time of ticket creation
			if (String.isNotBlank(objTicketRecord.Sub_Team__c) && (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_FULFILLMENT)) {
				if (objTicketRecord.OwnerId != null && String.valueOf(objTicketRecord.OwnerId).startsWith(strUserPrefix)) {
					objTicketRecord.Initial_owner__c = objTicketRecord.OwnerId;
				}
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
			objTicketHistory.Status_Change_User__c = idLoggedInUser;
			objTicketHistory.To_Status__c = TicketUtil.TICKET_STATUS_NEW;
			insert objTicketHistory;

			// Updating Benefit Order 'Status' and Carrier Order 'Implementation Stage' from related Ticket Mapping
			List<Carrier_Order__c> list_COsToUpdated = new List<Carrier_Order__c>();

			if (map_TicketsMapping.containsKey(strTicketMapKey)) {
				//By AKS dated 1st Oct 2020 https://app.asana.com/0/1195411211351298/1195576461466461
				if (
					objTicketRecord.Status__c != TicketUtil.TICKET_STATUS_CLOSED &&
					map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c != TicketUtil.TICKET_ORDER_STATUS_NO_IMPACT
				) {
					if (map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c == TicketUtil.TICKET_ORDER_STATUS_REQUIRES_ER_OUTREACH) {
						list_BenefitOrders[0].Status_Detail__c = map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c;
					} else {
						if (objTicketRecord.Carrier_Order__c == null) {
							//If there is an associated CO eg. when TO_Sub_Team is Submission, then donot update BO Status directly
							if(list_BenefitOrders[0].Order_Status__c != BenefitOrderUtil.STATUS_FULFILLED && list_BenefitOrders[0].Order_Status__c != BenefitOrderUtil.STATUS_CANCELLED && list_BenefitOrders[0].Order_Status__c != BenefitOrderUtil.STATUS_CLOSED_ADMIN){
								list_BenefitOrders[0].Order_Status__c = map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c;
							}
							if (map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c == TicketUtil.TICKET_ORDER_STATUS_BLOCKED) {
								list_BenefitOrders[0].Blocked_Reason__c = strSelectedReason;
							}
						} else {
							//DS[02, June,2020]  related carrier orders need to be updated only
							Carrier_Order__c objCO = new Carrier_Order__c();
							objCO.id = objTicketRecord.Carrier_Order__c;
							objCO.Implementation_Stage__c = map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c;
							//DS[24/7/2020] for setting reRouting true in case ticket owner is not valid
							if (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_FULFILLMENT && !blnIsNoStatusUpdate) {
								objCO.Requires_Routing__c = blnIsRequireRouting;
							}
							list_COsToUpdated.add(objCO);
						}

						if (!list_BenefitOrders[0].Carrier_Orders__r.isEmpty()) {
							for (Carrier_Order__c co : list_BenefitOrders[0].Carrier_Orders__r) {
								//Neha , 15 Aug 2019, when ticket has no carrier order set on it, otherwise just update bo and co on ticket
								if (objTicketRecord.Carrier_Order__c == null) {
									if (
										co.Implementation_Stage__c != CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION &&
										co.Implementation_Stage__c != CarrierOrderUtil.IMPLEMENTATION_STAGE_EARLY_SUBMISSION
									)
										co.Implementation_Stage__c = map_TicketsMapping.get(strTicketMapKey).Order_Status_while_Ticket_is_Open__c;
									list_COsToUpdated.add(co);
								}
							}
						}
					}
				}
				Ticket__c objUpdatedTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicketRecord.Id];
				String strQCError = map_TicketsMapping.get(strTicketMapKey).Automated_QC_Error_Required__c;

				// Create QC Error when 'Automated QC Error Required' as 'Yes' in Ticket Mapping
				if (TicketUtil.AUTOMATED_QC_ERROR_REQUIRED_VALUE_YES.equalsIgnoreCase(strQCError) || TicketUtil.AUTOMATED_QC_ERROR_REQUIRED_VALUE_OPPORTUNITY.equalsIgnoreCase(strQCError)) {
					QA_Errors__c objError = new QA_Errors__c();
					objError.Benefit_Order__c = list_BenefitOrders[0].Id;
					objError.Description__c = objTicketRecord.Description__c;
					if (strSelectedReason != NONE) {
						objError.Error_Type__c = strSelectedReason;
					}
					if (strSelectedReasonDetail != NONE) {
						objError.Error_Type_Detail__c = strSelectedReasonDetail;
					}
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

					if (blnIsOwnerQueue && String.isNotBlank(strAssignedQueueName) && idAutomatedUser != null) {
						objError.Error_Owner__c = idAutomatedUser;
					} else if (TicketUtil.AUTOMATED_QC_ERROR_REQUIRED_VALUE_OPPORTUNITY.equalsIgnoreCase(strQCError) && list_BenefitOrders[0].Opportunity__c != null) {
						strPreFix = String.valueOf(list_BenefitOrders[0].Opportunity__r.OwnerId).left(3).toLowercase();
						if (strPreFix == strUserPrefix) {
							objError.Error_Owner__c = list_BenefitOrders[0].Opportunity__r.OwnerId;
						}
					} else {
						strPreFix = String.valueOf(objUpdatedTicket.OwnerId).left(3).toLowercase();
						if (strPreFix == strUserPrefix) {
							objError.Error_Owner__c = objUpdatedTicket.OwnerId;
						}
					}

					insert objError;
				}
			}

			//reassign IA BO in case of Inactive User
			if (objTicketRecord.Sub_Team__c == TicketUtil.TICKET_ROLE_IMPLEMENTATION && blnIsIAReassigned) {
				//this Boolean is used to handle Case owner update in this scenario
				BenefitOrderHelper.blnIsInvalidIAReassignmentOnTicketCreation = true;
				List<Benefit_Order__c> list_ChildBo = [
					SELECT Id, OwnerId, Parent_Benefit_Order__c, Maestro__c
					FROM Benefit_Order__c
					WHERE Parent_Benefit_Order__c = :list_BenefitOrders[0].Id AND OwnerId != :list_BenefitOrders[0].OwnerId
				];
				if (!list_ChildBo.isEmpty()) {
					for (Benefit_Order__c objBO : list_ChildBo) {
						objBO.OwnerId = list_BenefitOrders[0].OwnerId;
						map_BenefitOrdersToBeUpdated.put(objBO.Id, objBO);
					}
				}
				map_BenefitOrdersToBeUpdated.put(list_BenefitOrders[0].id, list_BenefitOrders[0]);
				if (!map_BenefitOrdersToBeUpdated.isEmpty()) {
					if (list_BenefitOrders[0].Id != null && map_BenefitOrdersToBeUpdated.containsKey(list_BenefitOrders[0].Id)) {
						list_BenefitOrders[0].OwnerId = map_BenefitOrdersToBeUpdated.get(list_BenefitOrders[0].Id).ownerId;
						list_BenefitOrders[0].Assignment_Message__c = map_BenefitOrdersToBeUpdated.get(list_BenefitOrders[0].Id).Assignment_Message__c;
						map_BenefitOrdersToBeUpdated.put(list_BenefitOrders[0].Id, list_BenefitOrders[0]);
					}
					update map_BenefitOrdersToBeUpdated.values();
				}
				BenefitOrderHelper.blnIsInvalidIAReassignmentOnTicketCreation = false;
			}
			if (!map_BenefitOrdersToBeUpdated.isEmpty()) {
				update map_BenefitOrdersToBeUpdated.values();
			} else {
				update list_BenefitOrders[0];
			}

			if (!list_COsToUpdated.isEmpty()) {
				update list_COsToUpdated;
			}

			strScript = '<script> RefreshPrimaryTab(); </script>';
			return null;
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('NPRU_TicketButtonOnBODetailExt', 'saveTicket', objEx.getMessage(), objEx.getStackTraceString());

			objTicketRecord.Id = null;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, TicketUtil.MSG_ERROR_IN_TICKET_CREATION));
			Database.rollback(objSavePoint);
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

			//QC Error Owner Required
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

			if (strSelectedReason != NONE) {
				objQCError.Error_Type__c = strSelectedReason;
			}

			if (strSelectedReasonDetail != NONE) {
				objQCError.Error_Type_Detail__c = strSelectedReasonDetail;
			}

			// Assign Error Owner
			if (TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
				String strPreFix = String.valueOf(list_BenefitOrders[0].OwnerId).left(3).toLowercase();
				if (strPreFix == strUserPrefix) {
					objQCError.Error_Owner__c = list_BenefitOrders[0].OwnerId;
				}
			} else if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
				String strPreFix = String.valueOf(list_BenefitOrders[0].Carrier_Orders__r[0].OwnerId).left(3).toLowercase();
				if (strPreFix == strUserPrefix) {
					objQCError.Error_Owner__c = list_BenefitOrders[0].Carrier_Orders__r[0].OwnerId;
				}
			} else if (TicketUtil.TICKET_TEAM_ADVISING.equalsIgnoreCase(strSelectedTeam) || TicketUtil.TICKET_TEAM_NEW_PLAN_SALES.equalsIgnoreCase(strSelectedTeam)) {
				if (blnIsOwnerQueue && String.isNotBlank(strAssignedQueueName)) {
					objQCError.Error_Owner__c = idAutomatedUser;
				} else {
					String strPreFix = String.valueOf(list_BenefitOrders[0].Opportunity__r.OwnerId).left(3).toLowercase();
					if (strPreFix == strUserPrefix) {
						objQCError.Error_Owner__c = list_BenefitOrders[0].Opportunity__r.OwnerId;
					}
				}
			}

			if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objQCError.To_Sub_team__c)) {
				objQCError.Carrier_Order__c = strSelectedCO;
			}
			//DS[24/7/2020] Saving skill type on QC Error level for reporting
			if (objQCError.To_Sub_team__c != null && (objQCError.To_Sub_team__c == TicketUtil.TICKET_ROLE_FULFILLMENT || objQCError.To_Sub_team__c == TicketUtil.TICKET_ROLE_IMPLEMENTATION)) {
				blnIsIAReassigned = UtilitiesFactory.CheckTicketOwnerIsValidOrNot(objQCError.Error_Owner__c, objQCError.To_Sub_team__c, false);
			}

			insert objQCError;
			strScript = '<script> RefreshPrimaryTab(); </script>';
			return null;
		} catch (Exception objEX) {
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
			} else if (strSelectedReason == REASON_LICENSING) {
				if (objTicketRecord.Broker_s_Name__c == null) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_BROKERS_NAME));
				} else if (String.isBlank(objTicketRecord.Broker_s_Team__c)) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_BROKERS_TEAM));
				} else if (String.isBlank(objTicketRecord.Broker_s_Home_State__c)) {
					blnRequired = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, TicketUtil.REQ_MSG_BROKERS_HOME_STATE));
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

		return blnRequired;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Update the Ticket owner to Inbound Support Queue
	 * @Parm        : null
	 * @Return      : null
	 **/
	public void updateTicketOwner() {
		strAssignedQueueName = '';
		blnIsOwnerQueue = false;
		String strTicketMappingKey = objTicketRecord.Reporting_Team__c + strSelectedTeam;

		if (String.isNotBlank(strSelectedSubTeam) && !NONE.equalsIgnoreCase(strSelectedSubTeam)) {
			strTicketMappingKey += strSelectedSubTeam;
		} else {
			strTicketMappingKey += null;
		}

		strTicketMappingKey += strSelectedReason;

		if (String.isNotBlank(strSelectedReasonDetail) && !NONE.equalsIgnoreCase(strSelectedReasonDetail)) {
			strTicketMappingKey += strSelectedReasonDetail + '';
		} else {
			strTicketMappingKey += null + '';
		}

		if (TicketUtil.TICKET_TEAM_BYB_MEMBER_OPS.equalsIgnoreCase(strSelectedTeam)) {
			strAssignedQueueName = TicketUtil.QUEUE_MEMBER_FULFILLMENT_BYB;
			blnIsOwnerQueue = true;
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to set the initial status of BO/CO when ticket is created.
	 * @param         N/A
	 * @return       N/A
	 **/
	public void setInitialStatus() {
		if (!list_BenefitOrders.isEmpty()) {
			objTicketRecord.Initial_Status__c = list_BenefitOrders[0].Id + '=>' + list_BenefitOrders[0].Order_Status__c;
			if (TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicketRecord.Sub_Team__c) && objTicketRecord.Carrier_Order__c != null) {
				for (Carrier_Order__c objCO : list_BenefitOrders[0].Carrier_Orders__r) {
					if (objCO.Id == objTicketRecord.Carrier_Order__c) {
						objTicketRecord.Initial_Status__c = objCO.Id + '=>' + objCO.Implementation_Stage__c;
						break;
					}
				}
			}
		}
	}
}