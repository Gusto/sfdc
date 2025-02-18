/**
 * @name         BTManageTicketsCtrl
 * @author       Anand Singh
 * @date         03/08/2020
 * @description  Tickets screen controller to manage ticket creation
 * @test class   BTManageTicketsCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class BTManageTicketsCtrl {
	//set the ticket Owner
	public Boolean blnIsError { get; set; }
	// To store current record Id from parameter
	public ID idCurrentRecord { get; set; }
	// Used in Ticket creation page
	public Ticket__c objTicket { get; set; }
	// Used in QC Error creation page
	public QA_Errors__c objQcError { get; set; }
	// To show user lookup on ticket creation page
	public Benefit_Order__c objBO { get; set; }
	// store From team
	public List<selectOption> list_FromTeam { get; set; }
	// store all Ticket reason
	public List<selectOption> list_ReasonList { get; set; }
	// store all Ticket Reason Detail
	public List<selectOption> list_ReasonDetail { get; set; }
	// store all Ticket To Team
	public List<selectOption> list_Team { get; set; }
	// store all Ticket To Sub Team
	public List<selectOption> list_SubTeam { get; set; }
	//Show SubTeam Exit or not
	public Boolean blnIsSubTeamExit { get; set; }
	// store selected Reason
	public string strSelectedReason { get; set; }
	// store selected Reason Detail
	public string strSelectedReasonDetail { get; set; }
	// store selected Team
	public string strSelectedTeam { get; set; }
	// store selected Sub Team
	public string strSelectedSubTeam { get; set; }

	// carrier order List for selection of ticket owner if Update CO Only is True in Ticket Mapping
	public List<selectOption> list_CarrierOrder { get; set; }
	// to hold carrierOrder id and Co.OwnerId
	private Map<Id, Id> map_COToOwner;
	//map to hold carrierOrder id and Co.Implementation stage
	private Map<Id, String> map_COToImplementationStage;
	// to hold selected CarrierOrder when subTeam = Submission
	public String strSelectedCO { get; set; }

	public List<Benefit_Order__c> list_BenefitOrderToUpdate { get; set; }
	public List<Carrier_Order__c> list_CarrierOrderToUpdate { get; set; }
	public List<Carrier_Order__c> list_AllCarrierOrder { get; set; }
	public string strScriptvar { get; set; }
	Map<String, Ticket_Mapping__c> map_TicketMapping = new Map<String, Ticket_Mapping__c>();
	// this Variable contains the value as 'Ticket' or 'QC Error'
	String strSource;
	public Boolean blnIsCOUpdateOnly { get; set; }
	public Boolean blnIsBOObject { get; set; }
	public Boolean blnIsTicketForFaciliator { get; set; }
	Set<String> set_ReportingTeam = new Set<String>();
	List<Carrier_Order__c> list_MultiEINCO = new List<Carrier_Order__c>();

	static String strCO_OrderType = 'Terminated Order';
	static String strIncorrectEnrollment = 'Incorrect Enrollment Review Information';
	static String strIncorrectPlan = 'Incorrect Plan Review Information';
	static String strBTFulfillment = 'Benefit Transfer Fulfillment';

	static Id idLoggedInUser = UserInfo.getUserId();

	public BTManageTicketsCtrl() {
		list_BenefitOrderToUpdate = new List<Benefit_Order__c>();
		list_CarrierOrderToUpdate = new List<Carrier_Order__c>();
		objQcError = new QA_Errors__c();
		objBO = new Benefit_Order__c();
		list_ReasonDetail = new List<selectOption>();
		list_FromTeam = new List<selectOption>();
		blnIsCOUpdateOnly = false;
		blnIsTicketForFaciliator = false;
		blnIsBOObject = false;
		idCurrentRecord = (Id) ApexPages.CurrentPage().getparameters().get('id');
		objTicket = new Ticket__c();
		strSelectedTeam = '';

		if (String.isNotBlank(idCurrentRecord)) {
			if (idCurrentRecord.getSObjectType().getDescribe().getName() == 'Benefit_Order__c') {
				blnIsBOObject = true;
			}

			if (blnIsBOObject) {
				list_BenefitOrderToUpdate = [
					SELECT
						Id,
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
						Renewal_Date__c,
						Submission_Deadline__c,
						(
							SELECT Id, Implementation_Stage__c, Name, Facilitator_2_Plan_Review__c, Facilitator_2_Enrollment_Review__c, Audit_Owner__c, OwnerId, Carrier__c, TAdA__c
							FROM Carrier_Orders__r
							WHERE Order_Type__c != :strCO_OrderType
						),
						(SELECT Id, AccountId FROM Cases__r WHERE Type = 'BOR')
					FROM Benefit_Order__c
					WHERE Id = :idCurrentRecord
				];
				objTicket.Benefit_Order__c = idCurrentRecord;
				objQcError.Benefit_Order__c = idCurrentRecord;
			} else {
				list_CarrierOrderToUpdate = [
					SELECT
						Id,
						Benefit_Order__c,
						Audit_Owner__c,
						Benefit_Order__r.Coverage_Effective_Date__c,
						Facilitator_2_Plan_Review__c,
						RecordType.Name,
						Benefit_Order__r.Opportunity__r.RecordTypeId,
						Benefit_Order__r.Status_Detail__c,
						Benefit_Order__r.Order_Status__c,
						Benefit_Order__r.UW_Owner__c,
						Benefit_Order__r.OwnerId,
						Benefit_Order__r.RecordTypeId,
						Benefit_Order__r.Opportunity__c,
						Facilitator_2_Enrollment_Review__c,
						Benefit_Order__r.Opportunity__r.Account_Filing_State__c,
						Is_Multi_EIN__c,
						Parent_Carrier_Order__c,
						Benefit_Order__r.Opportunity__r.Renewal_Date__c,
						Benefit_Order__r.Renewal_Date__c,
						Benefit_Order__r.Opportunity__r.OwnerId,
						Implementation_Stage__c,
						OwnerId,
						Follow_Up_Date__c,
						Submission_Deadline_Date__c,
						(SELECT Id, AccountId FROM Cases__r WHERE Type = 'Benefits BOR Carrier Case')
					FROM Carrier_Order__c
					WHERE Id = :idCurrentRecord
				];

				if (list_CarrierOrderToUpdate != null && list_CarrierOrderToUpdate.size() > 0) {
					if (list_CarrierOrderToUpdate[0].Is_Multi_EIN__c && list_CarrierOrderToUpdate[0].Parent_Carrier_Order__c == null) {
						list_MultiEINCO = [
							SELECT Id, Parent_Carrier_Order__c, Carrier__c, Implementation_Stage__c, TAdA__c
							FROM Carrier_Order__c
							WHERE Parent_Carrier_Order__c = :list_CarrierOrderToUpdate[0].Id AND Is_Multi_EIN__c = TRUE
						];
					}
					objTicket.Benefit_Order__c = list_CarrierOrderToUpdate[0].Benefit_Order__c;
					objTicket.Carrier_Order__c = list_CarrierOrderToUpdate[0].Id;
					objQcError.Carrier_Order__c = list_CarrierOrderToUpdate[0].Id;
					objQcError.Benefit_Order__c = list_CarrierOrderToUpdate[0].Benefit_Order__c;
				}
			}
		}
		/**
        To filter some of the ticket mapping which should not be displayed while creating, that ticket mapping only be used 
        while creating QC Error. 
        if strSource == ticket, then we will not show the ticket Mapping records who does not have any value in two fields
        (Order Status when Ticket is Closed, Order Status while Ticket is Open)
        if strSource == QCError, then all the ticket Mapping are used
         */
		strSource = ApexPages.CurrentPage().getparameters().get('source');

		populateInitialReportingTeam();
		if (set_ReportingTeam.isEmpty()) {
			List<User> objUserRec = [SELECT Id, UserRole.Name FROM User WHERE Id = :idLoggedInUser AND UserRole.Name = :strBTFulfillment];
			if (!objUserRec.isEmpty()) {
				set_ReportingTeam.add(strBTFulfillment);
				list_FromTeam.add(new SelectOption(strBTFulfillment, strBTFulfillment));
				objTicket.Reporting_Team__c = (new List<String>(set_ReportingTeam))[0];
				objQcError.From_Sub_Team_s__c = objTicket.Reporting_Team__c;
				ticketToTeam();
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'You are not allowed to create ticket'));
			}
		} else {
			ticketToTeam();
		}
	}
	public void populateInitialReportingTeam() {
		if (blnIsBOObject) {
			if (list_BenefitOrderToUpdate != null && list_BenefitOrderToUpdate.size() > 0) {
				if (list_BenefitOrderToUpdate[0].OwnerId == idLoggedInUser) {
					set_ReportingTeam.add('Advocate');
					list_FromTeam.add(new SelectOption('Advocate', 'Advocate'));
				}
				if (list_BenefitOrderToUpdate[0].UW_Owner__c == idLoggedInUser) {
					set_ReportingTeam.add('Qualifier');
					list_FromTeam.add(new SelectOption('Qualifier', 'Qualifier'));
				}
			}
		} else {
			if (list_CarrierOrderToUpdate != null && list_CarrierOrderToUpdate.size() > 0) {
				if (list_CarrierOrderToUpdate[0].Benefit_Order__r.OwnerId == idLoggedInUser) {
					set_ReportingTeam.add('Advocate');
					list_FromTeam.add(new SelectOption('Advocate', 'Advocate'));
				}
				if (list_CarrierOrderToUpdate[0].OwnerId == idLoggedInUser) {
					set_ReportingTeam.add('Facilitator 1');
					list_FromTeam.add(new SelectOption('Facilitator 1', 'Facilitator 1'));
				}
				if (list_CarrierOrderToUpdate[0].Facilitator_2_Plan_Review__c == idLoggedInUser || list_CarrierOrderToUpdate[0].Facilitator_2_Enrollment_Review__c == idLoggedInUser) {
					set_ReportingTeam.add('Facilitator 2');
					list_FromTeam.add(new SelectOption('Facilitator 2', 'Facilitator 2'));
				}
			}
		}
		if (!set_ReportingTeam.isEmpty()) {
			objTicket.Reporting_Team__c = (new List<String>(set_ReportingTeam))[0];
			objQcError.From_Sub_Team_s__c = objTicket.Reporting_Team__c;
		}
	}
	public void ticketToTeam() {
		ApexPages.getMessages().clear();
		strSelectedTeam = '';
		strSelectedReason = '';
		strSelectedReasonDetail = '';
		strSelectedCO = '';
		blnIsSubTeamExit = false;
		list_Team = new List<selectOption>();
		list_Team.add(new SelectOption('', 'None'));
		objQcError.From_Sub_Team_s__c = objTicket.Reporting_Team__c;
		set<String> set_teamTicket = new Set<String>();

		//Dynamic Query on the Basis of From sub team
		String strQueryToBeExecuted = formQuery();
		strQueryToBeExecuted = strQueryToBeExecuted + ' WHERE From_Sub_Team_s__c =\'' + objTicket.Reporting_Team__c + '\'';
		if (!'Ticket'.equalsIgnoreCase(strSource)) {
			strQueryToBeExecuted += ' AND Automated_QC_Error_Required__c = \'Yes\'';
		}

		// fetch all 'To Team' related to 'From Team' from Ticket Mapping
		for (Ticket_Mapping__c objTicketMapping : Database.query(strQueryToBeExecuted)) {
			if (!set_teamTicket.contains(objTicketMapping.To_Team__c)) {
				if (String.isNotBlank(objTicketMapping.To_Team__c)) {
					list_Team.add(new SelectOption(objTicketMapping.To_Team__c, objTicketMapping.To_Team__c));
					set_teamTicket.add(objTicketMapping.To_Team__c);
				}
			}
		}
	}
	//Make generic Query on Ticket_Mapping__c
	private string formQuery() {
		String strQueryToBeExecuted = 'SELECT Id, Ticket_Reason_s__c, Automated_QC_Error_Required__c, To_Sub_team__c, ';
		strQueryToBeExecuted += ' Order_Status_when_Ticket_is_Closed__c, Order_Status_while_Ticket_is_Open__c, Ticket_Reason_Details__c, ';
		strQueryToBeExecuted += ' From_Sub_Team_s__c, To_Team__c, Update_Order_Status__c FROM Ticket_Mapping__c ';
		return strQueryToBeExecuted;
	}

	// Method to fetch all Ticket reason based on selected 'From' and 'To' team.
	public void subTeam() {
		ApexPages.getMessages().clear();
		strSelectedReason = '';
		strSelectedReasonDetail = '';
		strSelectedCO = '';
		blnIsSubTeamExit = false;

		strSelectedSubTeam = '';
		list_SubTeam = new List<selectOption>();
		list_SubTeam.add(new SelectOption('', 'None'));
		Set<String> setSubTeam = new Set<String>();

		Map<String, String> stateNameMap = new Map<String, String>();

		// Query all State from custom setting
		for (State_Name_to_abbreviations_Mapping__c st : State_Name_to_abbreviations_Mapping__c.getall().values()) {
			if (!stateNameMap.containsKey(st.State_Name__c))
				stateNameMap.put(st.State_Name__c, st.State_Abbreviation__c);
		}

		// Query all Ticket Mapping records
		if (String.isNotBlank(objTicket.Reporting_Team__c) && String.isNotBlank(strSelectedTeam)) {
			//Dynamic Query on the Basis of From sub team and To team
			String strTicketMappingQuery = formQuery();
			strTicketMappingQuery = strTicketMappingQuery + ' Where From_Sub_Team_s__c =\'' + objTicket.Reporting_Team__c;
			strTicketMappingQuery += '\' And To_Team__c = \'' + strSelectedTeam + '\' ';
			if ('Ticket'.equalsIgnoreCase(strSource)) {
				strTicketMappingQuery += ' AND Order_Status_when_Ticket_is_Closed__c !=NULL AND Order_Status_while_Ticket_is_Open__c != Null';
			} else {
				strTicketMappingQuery += ' AND Automated_QC_Error_Required__c = \'Yes\'';
			}

			for (Ticket_Mapping__c objTicketMapping : Database.query(strTicketMappingQuery)) {
				String strTicketMappingKey =
					objTicketMapping.From_Sub_Team_s__c +
					strSelectedTeam +
					objTicketMapping.To_Sub_team__c +
					objTicketMapping.Ticket_Reason_s__c +
					objTicketMapping.Ticket_Reason_Details__c +
					'';
				if (!map_TicketMapping.containsKey(strTicketMappingKey))
					map_TicketMapping.put(strTicketMappingKey, objTicketMapping);

				/*
				 *Dynamically populate the subTeams based on Ticket Mapping Table
				 */
				if (
					String.isNotBlank(objTicket.Reporting_Team__c) &&
					String.isNotBlank(objTicketMapping.From_Sub_Team_s__c) &&
					String.isNotBlank(objTicketMapping.To_Sub_team__c) &&
					String.isNotBlank(objTicketMapping.To_Team__c) &&
					objTicket.Reporting_Team__c.equalsIgnoreCase(objTicketMapping.From_Sub_Team_s__c) &&
					objTicketMapping.To_Team__c.equalsIgnoreCase(strSelectedTeam) &&
					!setSubTeam.contains(objTicketMapping.To_Sub_team__c)
				) {
					setSubTeam.add(objTicketMapping.To_Sub_team__c);
					list_SubTeam.add(new SelectOption(objTicketMapping.To_Sub_team__c, objTicketMapping.To_Sub_team__c));
					if (!blnIsSubTeamExit)
						blnIsSubTeamExit = true;
				}
			}
		}
		objTicket.Status__c = 'New';
		// Assign Ticket fields from Benefit Order and related objects
		if (blnIsBOObject) {
			if (list_BenefitOrderToUpdate != null && list_BenefitOrderToUpdate.size() > 0) {
				// This should be set to Renewal Date on BO
				objTicket.Renewal_Date__c = list_BenefitOrderToUpdate[0].Renewal_Date__c;

				if (list_BenefitOrderToUpdate[0].Opportunity__c != null) {
					objTicket.Opportunity__c = list_BenefitOrderToUpdate[0].Opportunity__c;
					if (
						stateNameMap.containsKey(list_BenefitOrderToUpdate[0].Opportunity__r.Account_Filing_State__c) &&
						stateNameMap.get(list_BenefitOrderToUpdate[0].Opportunity__r.Account_Filing_State__c) != null &&
						stateNameMap.get(list_BenefitOrderToUpdate[0].Opportunity__r.Account_Filing_State__c) != ''
					)
						objTicket.States__c = stateNameMap.get(list_BenefitOrderToUpdate[0].Opportunity__r.Account_Filing_State__c);
				}
				if (!list_BenefitOrderToUpdate[0].Cases__r.isEmpty()) {
					objTicket.Case__c = list_BenefitOrderToUpdate[0].Cases__r[0].Id;
					objTicket.Account__c = list_BenefitOrderToUpdate[0].Cases__r[0].AccountId;
				}
			}
		} else {
			if (list_CarrierOrderToUpdate != null && list_CarrierOrderToUpdate.size() > 0) {
				objTicket.Renewal_Date__c = list_CarrierOrderToUpdate[0].Benefit_Order__r.Renewal_Date__c;

				if (list_CarrierOrderToUpdate[0].Benefit_Order__r.Opportunity__c != null) {
					objTicket.Opportunity__c = list_CarrierOrderToUpdate[0].Benefit_Order__r.Opportunity__c;
					if (
						stateNameMap.containsKey(list_CarrierOrderToUpdate[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c) &&
						stateNameMap.get(list_CarrierOrderToUpdate[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c) != null &&
						stateNameMap.get(list_CarrierOrderToUpdate[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c) != ''
					)
						objTicket.States__c = stateNameMap.get(list_CarrierOrderToUpdate[0].Benefit_Order__r.Opportunity__r.Account_Filing_State__c);
				}
				if (!list_CarrierOrderToUpdate[0].Cases__r.isEmpty()) {
					objTicket.Case__c = list_CarrierOrderToUpdate[0].Cases__r[0].Id;
					objTicket.Account__c = list_CarrierOrderToUpdate[0].Cases__r[0].AccountId;
				}
			}
		}

		//set ticket owner when subTeam selection changes
		assignOwner();
	}

	// Method to fetch all Ticket reason based on selected 'From', 'To' team and 'Reason'.
	public void ticketDetail() {
		ApexPages.getMessages().clear();
		set<String> reasonDetailSet = new Set<String>();
		list_ReasonDetail = new List<selectOption>();
		list_ReasonDetail.add(new SelectOption('', 'None'));
		blnIsCOUpdateOnly = false;
		blnIsTicketForFaciliator = false;

		//Dynamic Query on the Basis of From sub team and To team and To SubTeam and Ticket Reason
		String strQueryToBeExecuted = formQuery();
		strQueryToBeExecuted += ' WHERE From_Sub_Team_s__c =\'' + objTicket.Reporting_Team__c + '\' AND ';
		strQueryToBeExecuted += ' To_Team__c =\'' + strSelectedTeam + '\' AND To_Sub_team__c =\'' + strSelectedSubTeam + '\' AND ';
		strQueryToBeExecuted += ' Ticket_Reason_s__c =\'' + strSelectedReason + '\'';
		if (!'Ticket'.equalsIgnoreCase(strSource)) {
			strQueryToBeExecuted += ' AND Automated_QC_Error_Required__c = \'Yes\'';
		}
		// Query all Ticket Mapping records
		for (Ticket_Mapping__c objTicketMapping : Database.query(strQueryToBeExecuted)) {
			if (String.isNotBlank(objTicketMapping.Ticket_Reason_Details__c) && !reasonDetailSet.contains(objTicketMapping.Ticket_Reason_Details__c)) {
				list_ReasonDetail.add(new SelectOption(objTicketMapping.Ticket_Reason_Details__c, objTicketMapping.Ticket_Reason_Details__c));
				reasonDetailSet.add(objTicketMapping.Ticket_Reason_Details__c);
			}
			String strTicketMappingKey =
				objTicketMapping.From_Sub_Team_s__c +
				strSelectedTeam +
				objTicketMapping.To_Sub_team__c +
				objTicketMapping.Ticket_Reason_s__c +
				objTicketMapping.Ticket_Reason_Details__c +
				'';
			if (!map_TicketMapping.containsKey(strTicketMappingKey))
				map_TicketMapping.put(strTicketMappingKey, objTicketMapping);
		}
		ticketUpdateCoOnlyValue();
	}
	public void ticketUpdateCoOnlyValue() {
		blnIsCOUpdateOnly = false;

		//Dynamic Query on the Basis of From sub team and To team and To SubTeam and Ticket Reason and Reason Detail
		String strQueryToBeExecuted = formQuery();
		strQueryToBeExecuted += ' WHERE From_Sub_Team_s__c =\'' + objTicket.Reporting_Team__c + '\' ';
		strQueryToBeExecuted += ' AND To_Team__c =\'' + strSelectedTeam + '\' AND To_Sub_team__c =\'' + strSelectedSubTeam + '\'';
		strQueryToBeExecuted += ' AND Ticket_Reason_s__c =\'' + strSelectedReason + '\' AND Ticket_Reason_Details__c =\'' + strSelectedReasonDetail + '\' ';
		if (!'Ticket'.equalsIgnoreCase(strSource)) {
			strQueryToBeExecuted += ' AND Automated_QC_Error_Required__c = \'Yes\'';
		}
		for (Ticket_Mapping__c objTicketMapping : Database.query(strQueryToBeExecuted)) {
			if (String.isNotBlank(objTicketMapping.Update_Order_Status__c) && 'Only Affected CO'.equalsIgnoreCase(objTicketMapping.Update_Order_Status__c)) {
				blnIsCOUpdateOnly = true;
			}
		}
		if (blnIsBOObject) {
			blnIsTicketForFaciliator = false;
			map_COToImplementationStage = new Map<Id, String>();
			if (String.isNotBlank(strSelectedSubTeam) && ('Facilitator 1'.equalsIgnoreCase(strSelectedSubTeam) || 'Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam))) {
				blnIsTicketForFaciliator = true;
			}

			if (blnIsCOUpdateOnly || blnIsTicketForFaciliator) {
				if (!list_BenefitOrderToUpdate[0].Carrier_Orders__r.isEmpty()) {
					list_CarrierOrder = new List<SelectOption>();
					Integer intdx = 0;
					for (Carrier_Order__c co : list_BenefitOrderToUpdate[0].Carrier_Orders__r) {
						if (!updateCOStatusOrNot(co, strSelectedReasonDetail)) {
							continue;
						}
						if (intdx == 0) {
							strSelectedCO = co.Id;
							if (!'BoR Sales'.equalsIgnoreCase(strSelectedTeam) && !(String.isNotBlank(strSelectedSubTeam) && 'Qualifier'.equalsIgnoreCase(strSelectedSubTeam))) {
								objBO.Escalated_User__c = null;
								if (String.isNotBlank(strSelectedSubTeam) && ('Facilitator 1'.equalsIgnoreCase(strSelectedSubTeam) && String.valueOf(co.OwnerId).left(3).toLowercase() == '005')) {
									objBO.Escalated_User__c = co.OwnerId;
								} else if (
									String.isNotBlank(strSelectedSubTeam) &&
									String.isNotBlank(co.Facilitator_2_Plan_Review__c) &&
									String.isNotBlank(strSelectedReason) &&
									strIncorrectPlan.equalsIgnoreCase(strSelectedReason) &&
									'Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) &&
									String.valueOf(co.Facilitator_2_Plan_Review__c).left(3).toLowercase() == '005'
								) {
									objBO.Escalated_User__c = co.Facilitator_2_Plan_Review__c;
								} else if (
									String.isNotBlank(strSelectedSubTeam) &&
									String.isNotBlank(co.Facilitator_2_Enrollment_Review__c) &&
									'Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) &&
									strIncorrectEnrollment.equalsIgnoreCase(strSelectedReason) &&
									String.valueOf(co.Facilitator_2_Enrollment_Review__c).left(3).toLowercase() == '005'
								) {
									objBO.Escalated_User__c = co.Facilitator_2_Enrollment_Review__c;
								}
							}
							intdx++;
						}
						if (!'BoR Sales'.equalsIgnoreCase(strSelectedTeam) && !(String.isNotBlank(strSelectedSubTeam) && 'Qualifier'.equalsIgnoreCase(strSelectedSubTeam))) {
							if (
								String.isNotBlank(strSelectedSubTeam) &&
								String.isNotBlank(co.Facilitator_2_Plan_Review__c) &&
								'Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) &&
								strIncorrectPlan.equalsIgnoreCase(strSelectedReason) &&
								String.valueOf(co.Facilitator_2_Plan_Review__c).left(3).toLowercase() == '005'
							) {
								map_COToOwner.put(co.Id, co.Facilitator_2_Plan_Review__c);
								map_COToImplementationStage.put(co.Id, co.Implementation_Stage__c);
								list_CarrierOrder.add(new SelectOption(co.Id, co.Name));
							} else if (
								String.isNotBlank(strSelectedSubTeam) &&
								String.isNotBlank(co.Facilitator_2_Enrollment_Review__c) &&
								'Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) &&
								strIncorrectEnrollment.equalsIgnoreCase(strSelectedReason) &&
								String.valueOf(co.Facilitator_2_Enrollment_Review__c).left(3).toLowercase() == '005'
							) {
								map_COToOwner.put(co.Id, co.Facilitator_2_Enrollment_Review__c);
								map_COToImplementationStage.put(co.Id, co.Implementation_Stage__c);
								list_CarrierOrder.add(new SelectOption(co.Id, co.Name));
							} else if (String.isNotBlank(strSelectedSubTeam) && ('Facilitator 1'.equalsIgnoreCase(strSelectedSubTeam) && String.valueOf(co.OwnerId).left(3).toLowercase() == '005')) {
								map_COToOwner.put(co.Id, co.OwnerId);
								map_COToImplementationStage.put(co.Id, co.Implementation_Stage__c);
								list_CarrierOrder.add(new SelectOption(co.Id, co.Name));
							}
						} else {
							map_COToImplementationStage.put(co.Id, co.Implementation_Stage__c);
							list_CarrierOrder.add(new SelectOption(co.Id, co.Name));
						}
					}
				}
			}
		}
		isTicketOwnerAssigned();
		if (!blnIsCOUpdateOnly && !blnIsBOObject) {
			list_AllCarrierOrder = [
				SELECT Id, Implementation_Stage__c, Name, Facilitator_2_Plan_Review__c, OwnerId, Carrier__c, TAdA__c
				FROM Carrier_Order__c
				WHERE Order_Type__c != :strCO_OrderType AND Benefit_Order__c = :list_CarrierOrderToUpdate[0].Benefit_Order__r.Id
			];
		}
	}
	public void assignOwnerAsFac2() {
		if (!blnIsBOObject) {
			if (list_CarrierOrderToUpdate != null && list_CarrierOrderToUpdate.size() > 0) {
				if ('Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) && String.isNotBlank(strSelectedReason) && strIncorrectPlan.equalsIgnoreCase(strSelectedReason)) {
					objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].Facilitator_2_Plan_Review__c;
				} else if ('Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) && String.isNotBlank(strSelectedReason) && strIncorrectEnrollment.equalsIgnoreCase(strSelectedReason)) {
					objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].Facilitator_2_Enrollment_Review__c;
				}
			}
		}
	}
	public void isTicketOwnerAssigned() {
		assignOwnerAsFac2();
		if (blnIsBOObject) {
			if (
				String.isNotBlank(strSelectedSubTeam) &&
				String.isNotBlank(strSelectedReason) &&
				('Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) || 'Facilitator 1'.equalsIgnoreCase(strSelectedSubTeam)) &&
				(list_CarrierOrder == null || list_CarrierOrder.isEmpty())
			) {
				blnIsError = true;
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Tickets for Selected Sub Team must have associated Carrier Order which is assigned.'));
			} else {
				blnIsError = false;
				ApexPages.getMessages().clear();
			}
		} else {
			if (String.isNotBlank(strSelectedSubTeam) && 'Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam)) {
				if (String.isNotBlank(strSelectedReason) && list_CarrierOrderToUpdate[0].Facilitator_2_Plan_Review__c == null && strIncorrectPlan.equalsIgnoreCase(strSelectedReason)) {
					blnIsError = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Carrier Order is not assigned to the ' + strSelectedSubTeam + ' Plan Review.'));
				} else if (
					String.isNotBlank(strSelectedReason) &&
					list_CarrierOrderToUpdate[0].Facilitator_2_Enrollment_Review__c == null &&
					strIncorrectEnrollment.equalsIgnoreCase(strSelectedReason)
				) {
					blnIsError = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Carrier Order is not assigned to the ' + strSelectedSubTeam + ' Enrollment Review.'));
				} else {
					blnIsError = false;
					ApexPages.getMessages().clear();
				}
			} else if (
				String.isNotBlank(strSelectedSubTeam) &&
				'Facilitator 1'.equalsIgnoreCase(strSelectedSubTeam) &&
				String.valueOf(list_CarrierOrderToUpdate[0].OwnerId).left(3).toLowercase() != '005'
			) {
				blnIsError = true;
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Carrier Order is not assigned to the ' + strSelectedSubTeam + '.'));
			} else {
				blnIsError = false;
				ApexPages.getMessages().clear();
			}
		}
	}

	/*
	 *Description : Method to fetch all Ticket reason based on selected 'From', 'To' team and 'ToSubTeam'.
	 */
	private void ticketReason() {
		set<String> reasonSet = new Set<String>();
		list_ReasonList = new List<selectOption>();
		list_ReasonList.add(new SelectOption('', 'None'));
		list_ReasonDetail = new List<selectOption>();
		list_ReasonDetail.add(new SelectOption('', 'None'));
		strSelectedReason = '';
		blnIsCOUpdateOnly = false;
		blnIsTicketForFaciliator = false;
		if (String.isNotBlank(objTicket.Reporting_Team__c) && String.isNotBlank(strSelectedTeam)) {
			//Dynamic Query on the Basis of From sub team and To team
			String strQueryToBeExecuted = formQuery();
			strQueryToBeExecuted += ' Where From_Sub_Team_s__c =\'' + objTicket.Reporting_Team__c;
			strQueryToBeExecuted += '\' And To_Team__c = \'' + strSelectedTeam + '\' ';
			if ('Ticket'.equalsIgnoreCase(strSource)) {
				strQueryToBeExecuted += ' AND Order_Status_when_Ticket_is_Closed__c !=NULL AND Order_Status_while_Ticket_is_Open__c != Null';
			} else {
				strQueryToBeExecuted += ' AND Automated_QC_Error_Required__c = \'Yes\'';
			}

			for (Ticket_Mapping__c objTicketMapping : Database.query(strQueryToBeExecuted)) {
				if (String.isNotBlank(objTicketMapping.Ticket_Reason_s__c) && !reasonSet.contains(objTicketMapping.Ticket_Reason_s__c)) {
					if (String.isNotBlank(strSelectedSubTeam)) {
						if (strSelectedSubTeam.equalsIgnoreCase(objTicketMapping.To_Sub_team__c)) {
							list_ReasonList.add(new SelectOption(objTicketMapping.Ticket_Reason_s__c, objTicketMapping.Ticket_Reason_s__c));
							reasonSet.add(objTicketMapping.Ticket_Reason_s__c);
						}
					} else if (String.isNotBlank(objQcError.To_Sub_team__c)) {
						if (objQcError.To_Sub_team__c.equalsIgnoreCase(objTicketMapping.To_Sub_team__c)) {
							list_ReasonList.add(new SelectOption(objTicketMapping.Ticket_Reason_s__c, objTicketMapping.Ticket_Reason_s__c));
							reasonSet.add(objTicketMapping.Ticket_Reason_s__c);
						}
					} else {
						list_ReasonList.add(new SelectOption(objTicketMapping.Ticket_Reason_s__c, objTicketMapping.Ticket_Reason_s__c));
						reasonSet.add(objTicketMapping.Ticket_Reason_s__c);
					}
				}
			}
		}
	}
	/*
	 *Description : Assign owner to ticket if strSelectedSubTeam is Submission
	 */

	public PageReference assignOwnerFromCO() {
		if (blnIsCOUpdateOnly || blnIsTicketForFaciliator) {
			if (String.isNotBlank(strSelectedCO) && null != map_COToOwner && map_COToOwner.containsKey(strSelectedCO)) {
				if (String.valueOf(map_COToOwner.get(strSelectedCO)).left(3).toLowercase() == '005' && !'BoR Sales'.equalsIgnoreCase(strSelectedTeam)) {
					objBO.Escalated_User__c = map_COToOwner.get(strSelectedCO);
					objQcError.Error_Owner__c = map_COToOwner.get(strSelectedCO);
				}
			}
		}
		return null;
	}

	/*
	 *Description : Assign owner to ticket based to strSelectedTeam and strSelectedSubTeam
	 */
	public PageReference assignOwner() {
		objQcError.Error_Owner__c = null;
		// using objBO just to ensure that changing values for ownerId are recorded without setting OwnerId = NULL
		objBO.Escalated_User__c = null;
		map_COToOwner = new Map<Id, Id>();
		// Assign Ticket Owner based on Ticket team and Sub Team
		if ('BoR Sales'.equalsIgnoreCase(strSelectedTeam)) {
			if (blnIsBOObject) {
				objBO.Escalated_User__c = list_BenefitOrderToUpdate[0].Opportunity__r.OwnerId;
			} else {
				objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].Benefit_Order__r.Opportunity__r.OwnerId;
			}
		}
		if ('Benefits Transfer'.equalsIgnoreCase(strSelectedTeam)) {
			if (!blnIsBOObject) {
				if ('Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) && String.isNotBlank(strSelectedReason) && strIncorrectPlan.equalsIgnoreCase(strSelectedReason)) {
					objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].Facilitator_2_Plan_Review__c;
				} else if ('Facilitator 2'.equalsIgnoreCase(strSelectedSubTeam) && String.isNotBlank(strSelectedReason) && strIncorrectEnrollment.equalsIgnoreCase(strSelectedReason)) {
					objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].Facilitator_2_Enrollment_Review__c;
				} else if ('Facilitator 1'.equalsIgnoreCase(strSelectedSubTeam) && String.valueOf(list_CarrierOrderToUpdate[0].OwnerId).left(3).toLowercase() == '005') {
					objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].OwnerId;
				} else if ('Qualifier'.equalsIgnoreCase(strSelectedSubTeam)) {
					objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].Benefit_Order__r.UW_Owner__c;
				} else if ('Advocate'.equalsIgnoreCase(strSelectedSubTeam)) {
					objBO.Escalated_User__c = list_CarrierOrderToUpdate[0].Benefit_Order__r.OwnerId;
				}
			} else {
				if ('Qualifier'.equalsIgnoreCase(strSelectedSubTeam)) {
					objBO.Escalated_User__c = list_BenefitOrderToUpdate[0].UW_Owner__c;
				} else if ('Advocate'.equalsIgnoreCase(strSelectedSubTeam)) {
					objBO.Escalated_User__c = list_BenefitOrderToUpdate[0].OwnerId;
				}
			}
		}

		//Load ticket reason on change of team selection
		ticketReason();
		ticketUpdateCoOnlyValue();
		return null;
	}

	// Method to insert Ticket, QC Error and Ticket Status History.
	public PageReference saveTicket() {
		SavePoint sp = Database.setSavepoint();
		try {
			// Sub Team as required when Team is Onboarding

			if (blnIsSubTeamExit && String.isBlank(strSelectedSubTeam)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select Sub Team.'));
				return null;
			}

			if (String.isBlank(strSelectedReason)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select Ticket Reason.'));
				return null;
			}

			if (String.isBlank(strSelectedReasonDetail) && list_ReasonDetail.size() > 1) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select Ticket Reason Detail.'));
				return null;
			}

			if ((blnIsCOUpdateOnly || blnIsTicketForFaciliator) && String.isBlank(strSelectedCO) && blnIsBOObject) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Tickets for Selected Sub Team must have associated Carrier Order which is assigned.'));
				return null;
			}
			isTicketOwnerAssigned();
			if (blnIsError) {
				return null;
			}
			if (String.isNotBlank(strSelectedReason))
				objTicket.Escalation_Reason__c = strSelectedReason;
			if (String.isNotBlank(strSelectedReasonDetail))
				objTicket.Escalation_Reason_Detail__c = strSelectedReasonDetail;
			objTicket.Team__c = strSelectedTeam;
			if (String.isNotBlank(strSelectedSubTeam))
				objTicket.Sub_Team__c = strSelectedSubTeam;

			// assign Ticket RecordType  based on Ticket Team
			if ('Benefits Transfer'.equalsIgnoreCase(strSelectedTeam) || 'BoR Sales'.equalsIgnoreCase(strSelectedTeam)) {
				objTicket.RecordTypeId = cache.getRecordTypeId('Ticket__c', 'Benefits Transfer');
			}

			/* Assign Ticket Owner
			 * Using objBO.Escalated_User__c just as a mask to show lookups on VF page for capturing ticket owner
			 */

			if (null != objBO.Escalated_User__c) {
				objTicket.Skip_Assignment__c = true;
				objTicket.OwnerId = objBO.Escalated_User__c;
			}

			/* Assign Carrier Order when subTeam is Submission
			 */

			if ((blnIsCOUpdateOnly || blnIsTicketForFaciliator) && String.isNotBlank(strSelectedCO)) {
				objTicket.Carrier_Order__c = strSelectedCO;
			}

			objTicket.Ticket_Status_Change_Date__c = System.now();
			String strTicketMappingKey = objTicket.Reporting_Team__c + objTicket.Team__c + objTicket.Sub_Team__c + objTicket.Escalation_Reason__c + objTicket.Escalation_Reason_Detail__c + '';
			if (map_TicketMapping.containsKey(strTicketMappingKey) && map_TicketMapping.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == 'Back to status prior to ticket creation') {
				setInitialStatus();
			}
			TicketTriggerHelper.skipTrigger = true;
			insert objTicket;
			TicketTriggerHelper.skipTrigger = false;

			// Create Ticket Status History record
			Ticket_Status_History__c historyObj = new Ticket_Status_History__c();
			historyObj.End_Time__c = System.now();
			historyObj.Ticket__c = objTicket.Id;
			historyObj.Start_Time__c = System.now();
			historyObj.Ticket_Creation__c = true;
			historyObj.Status_Change_User__c = idLoggedInUser;
			historyObj.To_Status__c = 'New';
			insert historyObj;

			// Updating Benefit Order 'Status' and Carrier Order 'Implementation Stage' from related Ticket Mapping
			List<Carrier_Order__c> lstToUpdateCO = new List<Carrier_Order__c>();
			if (map_TicketMapping.containsKey(strTicketMappingKey) && map_TicketMapping.get(strTicketMappingKey).Order_Status_while_Ticket_is_Open__c != 'No Impact on Status') {
				Benefit_Order__c objBenefitOrder = new Benefit_Order__c();
				if (objTicket.Status__c != 'Closed') {
					if (blnIsBOObject) {
						if (objTicket.Carrier_Order__c == null || !blnIsCOUpdateOnly) {
							//If there is an associated CO eg. when TO_Sub_Team is Submission, then donot update BO Status directly
							list_BenefitOrderToUpdate[0].Order_Status__c = map_TicketMapping.get(strTicketMappingKey).Order_Status_while_Ticket_is_Open__c;
						}

						if (!list_BenefitOrderToUpdate[0].Carrier_Orders__r.isEmpty()) {
							for (Carrier_Order__c co : list_BenefitOrderToUpdate[0].Carrier_Orders__r) {
								//Neha , 15 Aug 2019, related carrier orders need to be updated only when ticket has no carrier order set on it, otherwise just update bo and co on ticket
								if (!blnIsCOUpdateOnly || objTicket.Carrier_Order__c == null) {
									if (!updateCOStatusOrNot(co, strSelectedReasonDetail)) {
										continue;
									}
									co.Implementation_Stage__c = map_TicketMapping.get(strTicketMappingKey).Order_Status_while_Ticket_is_Open__c;
									lstToUpdateCO.add(co);
								} else if (blnIsCOUpdateOnly && objTicket.Carrier_Order__c == co.Id) {
									co.Implementation_Stage__c = map_TicketMapping.get(strTicketMappingKey).Order_Status_while_Ticket_is_Open__c;
									lstToUpdateCO.add(co);
								}
							}
						}

						update list_BenefitOrderToUpdate[0];
						if (!lstToUpdateCO.isEmpty()) {
							update lstToUpdateCO;
						}
					} else {
						if (blnIsCOUpdateOnly) {
							Map<Id, Carrier_Order__c> map_COToUpdate = new Map<Id, Carrier_Order__c>();
							list_CarrierOrderToUpdate[0].Implementation_Stage__c = map_TicketMapping.get(strTicketMappingKey).Order_Status_while_Ticket_is_Open__c;
							if (!list_MultiEINCO.isEmpty() && ('Facilitator 1'.equalsIgnoreCase(objTicket.Reporting_Team__c) || 'Facilitator 2'.equalsIgnoreCase(objTicket.Reporting_Team__c))) {
								for (Carrier_Order__c objCO : list_MultiEINCO) {
									if (objCO.Parent_Carrier_Order__c == list_CarrierOrderToUpdate[0].Id) {
										if (!updateCOStatusOrNot(objCO, strSelectedReasonDetail)) {
											continue;
										}
										objCO.Implementation_Stage__c = list_CarrierOrderToUpdate[0].Implementation_Stage__c;
										map_COToUpdate.put(objCO.Id, objCO);
									}
								}
							}
							map_COToUpdate.put(list_CarrierOrderToUpdate[0].Id, list_CarrierOrderToUpdate[0]);
							update map_COToUpdate.values();
						} else {
							objBenefitOrder.Id = list_CarrierOrderToUpdate[0].Benefit_Order__r.Id;
							objBenefitOrder.Order_Status__c = map_TicketMapping.get(strTicketMappingKey).Order_Status_while_Ticket_is_Open__c;
							if (list_AllCarrierOrder != null && !list_AllCarrierOrder.isEmpty()) {
								for (Carrier_Order__c objCO : list_AllCarrierOrder) {
									if (!updateCOStatusOrNot(objCO, strSelectedReasonDetail)) {
										continue;
									}
									objCO.Implementation_Stage__c = map_TicketMapping.get(strTicketMappingKey).Order_Status_while_Ticket_is_Open__c;
								}
								update list_AllCarrierOrder;
							}
							if (objBenefitOrder.Id != null) {
								update objBenefitOrder;
							}
						}
					}
				}
				Ticket__c updatedTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
				String qcError = map_TicketMapping.get(strTicketMappingKey).Automated_QC_Error_Required__c;
				// Create QC Error when 'Automated QC Error Required' as 'Yes' in Ticket Mapping
				if ('Yes'.equalsIgnoreCase(qcError)) {
					QA_Errors__c objQAError = new QA_Errors__c();
					objQAError.Benefit_Order__c = objTicket.Benefit_Order__c;
					objQAError.Carrier_Order__c = objTicket.Carrier_Order__c;

					objQAError.Description__c = objTicket.Description__c;
					if (String.isNotBlank(strSelectedReason))
						objQAError.Error_Type__c = strSelectedReason;
					if (String.isNotBlank(strSelectedReasonDetail))
						objQAError.Error_Type_Detail__c = strSelectedReasonDetail;
					if (String.isNotBlank(strSelectedSubTeam))
						objQAError.To_Sub_team__c = strSelectedSubTeam;
					objQAError.From_Sub_Team_s__c = objTicket.Reporting_Team__c;
					objQAError.Ticket__c = objTicket.Id;
					if ('Benefits Transfer'.equalsIgnoreCase(objTicket.Team__c)) {
						objQAError.QA_Error_Team__c = 'Benefits Transfer';
					}
					String preFix = String.valueOf(updatedTicket.OwnerId).left(3).toLowercase();
					if (preFix == '005') {
						objQAError.Error_Owner__c = updatedTicket.OwnerId;
					}
					insert objQAError;
				}
			}

			strScriptvar = '<script> RefreshPrimaryTab(); </script>';
			return null;
		} catch (Exception e) {
			objTicket.Id = null;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Error in Ticket creation.'));
			Database.rollback(sp);
			ExceptionLogUtil.logException('BTManageTicketsCtrl', 'saveTicket', e.getMessage(), e.getStackTraceString());
			return null;
		}
	}

	public void setInitialStatus() {
		String strInitalStatus = '';
		if (blnIsBOObject) {
			if (blnIsCOUpdateOnly) {
				if (!map_COToImplementationStage.isEmpty() && map_COToImplementationStage.containsKey(strSelectedCO)) {
					strInitalStatus += strSelectedCO + ' => ' + map_COToImplementationStage.get(strSelectedCO);
				}
			} else if (!blnIsCOUpdateOnly) {
				strInitalStatus += list_BenefitOrderToUpdate[0].Id + ' => ' + list_BenefitOrderToUpdate[0].Order_Status__c;
				for (Carrier_Order__c objCarrierOrder : list_BenefitOrderToUpdate[0].Carrier_Orders__r) {
					strInitalStatus += ',' + objCarrierOrder.id + ' => ' + objCarrierOrder.Implementation_Stage__c;
				}
			}
		} else {
			if (blnIsCOUpdateOnly) {
				strInitalStatus += list_CarrierOrderToUpdate[0].Id + ' => ' + list_CarrierOrderToUpdate[0].Implementation_Stage__c;
			} else if (!blnIsCOUpdateOnly) {
				strInitalStatus += list_CarrierOrderToUpdate[0].Benefit_Order__r.Id + ' => ' + list_CarrierOrderToUpdate[0].Benefit_Order__r.Order_Status__c;
				for (Carrier_Order__c objCarrierOrder : list_AllCarrierOrder) {
					strInitalStatus += ',' + objCarrierOrder.id + ' => ' + objCarrierOrder.Implementation_Stage__c;
				}
			}
		}
		objTicket.Initial_Status__c = strInitalStatus;
	}
	// Method to Create New QC Error.
	public PageReference saveQCError() {
		try {
			// QC Error Team required
			if (String.isBlank(strSelectedTeam)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select QC Error Team.'));
				return null;
			}
			// QC Error Type required
			if (String.isBlank(strSelectedReason)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select QC Error Type.'));
				return null;
			}
			if (blnIsSubTeamExit && String.isBlank(strSelectedSubTeam)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select Sub Team.'));
				return null;
			}
			if (String.isBlank(strSelectedReasonDetail) && list_ReasonDetail.size() > 1) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select QC Error Type Detail.'));
				return null;
			}
			if (String.isBlank(objQcError.Description__c)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select QC Error Description.'));
				return null;
			}
			isTicketOwnerAssigned();
			if (blnIsError) {
				return null;
			}

			if ('Benefits Transfer'.equalsIgnoreCase(strSelectedTeam)) {
				objQcError.QA_Error_Team__c = 'Benefits Transfer';
			}
			if (String.isNotBlank(strSelectedCO)) {
				objQcError.Carrier_Order__c = strSelectedCO;
			}
			if (String.isNotBlank(strSelectedTeam))
				objQcError.To_Team__c = strSelectedTeam;
			if (String.isNotBlank(strSelectedReason))
				objQcError.Error_Type__c = strSelectedReason;
			if (String.isNotBlank(strSelectedReasonDetail))
				objQcError.Error_Type_Detail__c = strSelectedReasonDetail;
			if (String.isNotBlank(strSelectedSubTeam))
				objQcError.To_Sub_team__c = strSelectedSubTeam;
			if (objBO.Escalated_User__c != null)
				objQcError.Error_Owner__c = objBO.Escalated_User__c;
			insert objQcError;
			strScriptvar = '<script> RefreshPrimaryTab(); </script>';
			return null;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Error in QC Error creation.'));
			ExceptionLogUtil.logException('BTManageTicketsCtrl', 'saveQCError', e.getMessage(), e.getStackTraceString());
			return null;
		}
	}
	public static Boolean updateCOStatusOrNot(Carrier_Order__c objCO, String strReasonDetail) {
		Boolean blnIsCOStatusUpdate = true;
		Set<String> set_ClosedStatuses = new Set<String>{ 'Canceled', 'Closed Admin' };

		if (!objCO.TAdA__c && 'Tada Escalation'.equalsIgnoreCase(strReasonDetail)) {
			blnIsCOStatusUpdate = false;
		} else if (objCO.TAdA__c && !'Tada Escalation'.equalsIgnoreCase(strReasonDetail)) {
			blnIsCOStatusUpdate = false;
		}
		// SJay - 06/15/2020 - Added CO Closed Admin, Canceled status exclusion
		if (set_ClosedStatuses.contains(objCO.Implementation_Stage__c)) {
			blnIsCOStatusUpdate = false;
		}

		return blnIsCOStatusUpdate;
	}
}