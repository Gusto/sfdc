/**
Created by : Deepak Tyagi
Created Date : 11/27/2018
**/
public class TicketTriggerHelper {
	public static boolean skipTrigger = false;
	static Map<String, Ticket_Mapping__c> map_objTicketMapping = new Map<String, Ticket_Mapping__c>();
	public static boolean blnStatusHistoryProcessed = false;
	public static Boolean blnUpdateBOStatusAsFulfilled = false;
	public static Boolean blnSkipTicketTriggerAssignment = false;
	public static Map<String, Account> map_QueriedAccounts;
	public static Map<Id, Task> map_Tasks = new Map<Id, Task>();
	public static Set<Id> set_ArdiusOwnerChangeTicketIds = new Set<Id>();
	public static Map<String, Account> map_TicketAccounts;
	public static Map<String, Id> map_GroupIdsByName = GlobalQueryHelper.getNameQueueMap(TicketUtil.set_QueueNames);
	public static String strLoggedInUserRoleName = TicketUtil.getLoggedInUserRoleName();
	public static List<Case> list_TicketCases;
	public static Map<String, Ticket__c> map_TicketByCaseIds;
	public static List<Ticket__c> list_ArdiusCustomRoutingTickets;
	private static final String BENEFITS_COMPLIANCE_PROFILE = 'Benefits Compliance';
	private static Set<Id> set_TaskResyncTicketIds = new Set<Id>();
	private static Set<Id> set_OpptyIdsToClosedWon = new Set<Id>();
	private static Set<Id> set_OpptyIdsToClosedLost = new Set<Id>();
	private static Set<Id> set_OpptyIdsToReOpen = new Set<Id>();
	private static List<Ticket__c> list_ArdiusStatusChangedTickets = new List<Ticket__c>();

	public void processBeforeInsert(List<Ticket__c> list_objTickets) {
		list_ArdiusCustomRoutingTickets = new List<Ticket__c>();
		set_TaskResyncTicketIds = new Set<Id>();

		createCollectionsBefore(list_objTickets);

		for (Ticket__c objTicket : list_objTickets) {
			objTicket.Ticket_Status_Change_Date__c = System.now();
			//@Neha For Updating the ClosedBy Field on Ticket
			if (TicketUtil.TICKET_STATUS_CLOSED.equalsIgnoreCase(objTicket.Status__c)) {
				objTicket.Closed_By__c = UserInfo.getUserId();
			}

			//Convert Process Builder - Ticket Assignment at Creation
			if (objTicket.Assign_to__c != null) {
				objTicket.OwnerId = objTicket.Assign_to__c;
			}

			if (objTicket.Status__c == TicketUtil.TICKET_STATUS_NEW) {
				objTicket.Created_Date_Time__c = System.now();
			}

			if (objTicket.RecordTypeId == TicketUtil.PAYROLL_AUDIT_TICKET_RT_ID && String.isNotBlank(objTicket.Company_ID__c)) {
				objTicket.Account__c = map_QueriedAccounts?.containsKey(objTicket.Company_ID__c) ? map_QueriedAccounts?.get(objTicket.Company_ID__c).Id : null;
			}

			if (!blnSkipTicketTriggerAssignment && !map_GroupIdsByName.isEmpty()) {
				if (!objTicket.Skip_Assignment__c) {
					if (objTicket.Assign_to__c == null) {
						if (objTicket.RecordTypeId == TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID) {
							objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_BENEFIT_TRANSFER)
								? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_BENEFIT_TRANSFER)
								: UserInfo.getUserId();
						} else if (objTicket.RecordTypeId == TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID) {
							objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_BENEFITS_COMPLIANCE)
								? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_BENEFITS_COMPLIANCE)
								: UserInfo.getUserId();
						} else if (objTicket.RecordTypeId == TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID || objTicket.RecordTypeId == TicketUtil.ADVISING_FULFILLMENT_CARE_TICKET_RT_ID) {
							objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_ADVISING_FULFILLMENT)
								? map_GroupIdsByName?.get(TicketUtil.QUEUE_ADVISING_FULFILLMENT)
								: UserInfo.getUserId();
						} else if (objTicket.RecordTypeId == TicketUtil.NEW_PLAN_SALES_TICKET_RT_ID) {
							objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_NEW_PLAN_SALES)
								? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_NEW_PLAN_SALES)
								: UserInfo.getUserId();
						} else if (objTicket.RecordTypeId == TicketUtil.PAYROLL_TRANSFER_TICKET_RT_ID) {
							objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_PAYROLL_TRANSFER)
								? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_PAYROLL_TRANSFER)
								: UserInfo.getUserId();
						} else if (objTicket.RecordTypeId == TicketUtil.RISK_INVESTIGATION_TICKET_RT_ID) {
							objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_RISK_INVESTIGATION)
								? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_RISK_INVESTIGATION)
								: UserInfo.getUserId();
						} else if (objTicket.RecordTypeId == TicketUtil.SALES_ESCALATION_TICKET_RT_ID) {
							objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_SALES_ESCALATION)
								? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_SALES_ESCALATION)
								: UserInfo.getUserId();
						}
					}

					if (objTicket.RecordTypeId == TicketUtil.MB_COMPLIANCE_TICKET_RT_ID) {
						objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_MB_COMPLIANCE) ? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_MB_COMPLIANCE) : UserInfo.getUserId();
					}
				}

				if (objTicket.RecordTypeId == TicketUtil.BENEFITS_BYB_TICKET_RT_ID && objTicket.Team__c == TicketUtil.TICKET_TEAM_BYB_MEMBER_OPS) {
					objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_MEMBER_FULFILLMENT_BYB)
						? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_MEMBER_FULFILLMENT_BYB)
						: UserInfo.getUserId();
				}

				if (objTicket.RecordTypeId == TicketUtil.QUALIFICATION_TICKET_RT_ID) {
					objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_QUALIFICATION) ? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_QUALIFICATION) : UserInfo.getUserId();
				}

				if (objTicket.RecordTypeId == TicketUtil.GUSTO_LEARN_SUPPORT_TICKET_RT_ID) {
					objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_GUSTO_LEARN_SUPPORT)
						? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_GUSTO_LEARN_SUPPORT)
						: UserInfo.getUserId();
				}

				if (objTicket.RecordTypeId == TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID) {
					objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_BIZ_DEV) ? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_BIZ_DEV) : UserInfo.getUserId();
					objTicket.Status__c = TicketUtil.TICKET_STATUS_NEW;
				}

				if (
					!strLoggedInUserRoleName.contains(TicketUtil.TICKET_ROLE_CORE_COMPLETE) &&
					!strLoggedInUserRoleName.contains(TicketUtil.TICKET_ROLE_DEDICATED_SUPPORT) &&
					!strLoggedInUserRoleName.contains(TicketUtil.TICKET_ROLE_MODERN_BANK)
				) {
					if (objTicket.RecordTypeId == TicketUtil.CREDIT_COLLECTIONS_TICKET_RT_ID) {
						objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_CREDIT_COLLECTIONS)
							? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_CREDIT_COLLECTIONS)
							: UserInfo.getUserId();
					}

					if (objTicket.RecordTypeId == TicketUtil.FINANCIAL_CRIMES_TICKET_RT_ID) {
						objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_FINANCIAL_CRIMES)
							? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_FINANCIAL_CRIMES)
							: UserInfo.getUserId();
					}
				}

				if (objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_FEIN_INVALID) {
					objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_PAYROLL_AUDIT) ? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_PAYROLL_AUDIT) : UserInfo.getUserId();
				}

				if (objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_CARE_ESCALATION) {
					objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_CARE_ESCALATIONS)
						? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_CARE_ESCALATIONS)
						: UserInfo.getUserId();
				}

				if (objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_CARE_QUESTION) {
					objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_CARE_QUESTION) ? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_CARE_QUESTION) : UserInfo.getUserId();
				}
			}

			if (objTicket.Team__c == TicketUtil.TICKET_TEAM_FULL_STACK_SALES) {
				objTicket.RecordTypeId = TicketUtil.SALES_ESCALATION_TICKET_RT_ID;
			}

			if (objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID && objTicket.Re_Sync_Tasks__c) {
				set_TaskResyncTicketIds.add(objTicket.Id);
				objTicket.Re_Sync_Tasks__c = false;
			}

			stampPriorityAndRiskFields(objTicket, null);
			addToArdiusCustomRoutingTracker(objTicket, null);
			populateTicketNameSearch(objTicket);
		}
		processInformation(list_objTickets);
		routeThroughArdiusCustomRouting();
		handleTicketOwnerChange(list_objTickets, null);
	}

	public void processAfterInsert(Map<ID, Ticket__c> map_newTickets) {
		createCollectionsAfter(map_newTickets.values(), null);
		createTicketStatusHistory(map_newTickets.values(), null);
		autoCreateTask(map_newTickets.values(), null);
		updateCaseForTicketInsert();
		ArdiusIntegrationHelper.triggerTicketIntegration(map_newTickets.values(), null);
		updateCarrierOrder(map_newTickets.values(), null);
		updateRelatedOpportunity();
		updateOpportunityToClosedLost(map_newTickets);
	}

	public void processBeforeUpdate(Map<Id, Ticket__c> map_oldTickets, Map<Id, Ticket__c> map_newTickets) {
		updateAnticipatedCloseDate(map_newTickets.values(), map_oldTickets);
		notifyOwnerClosed(map_newTickets.values(), map_oldTickets);
		createTicketStatusHistory(map_newTickets.values(), map_oldTickets);
		setTimeToFirstResponse(map_newTickets.values(), map_oldTickets);
		Set<Id> set_COrderIds = new Set<Id>();
		Map<Id, String> map_coIdAndOwnerIds = new Map<Id, String>();
		list_ArdiusCustomRoutingTickets = new List<Ticket__c>();
		set_TaskResyncTicketIds = new Set<Id>();

		/*
		 * @Neha 27-Oct-2020, To Set Close_Date for closed tickets. There is an exisiting WF Rule which needs to be dissolved in future
		 */
		for (Ticket__c objTicket : map_newTickets.values()) {
			if (objTicket.Team__c == TicketUtil.TICKET_TEAM_FULL_STACK_SALES) {
				objTicket.RecordTypeId = TicketUtil.SALES_ESCALATION_TICKET_RT_ID;
			}

			if (objTicket.RecordTypeId == TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID && objTicket.Status__c != map_oldTickets.get(objTicket.Id).Status__c) {
				if (map_oldTickets.get(objTicket.Id).Status__c == TicketUtil.TICKET_STATUS_NEW) {
					objTicket.Days_Escalated__c = 0;
					objTicket.Days_Incomplete__c = 0;
					objTicket.Days_in_Progress__c = 0;
					objTicket.Days_to_Resolution__c = 0;
					objTicket.Time_to_First_Response_TFIR__c = Date.today().daysBetween(objTicket.CreatedDate.date());
					objTicket.Last_API_Integration_Status_Change__c = DateTime.now();
				} else if (map_oldTickets.get(objTicket.Id).Status__c == TicketUtil.TICKET_STATUS_INPROGRESS) {
					objTicket.Days_in_Progress__c = Date.today().daysBetween(objTicket.Last_API_Integration_Status_Change__c.date());
					objTicket.Last_API_Integration_Status_Change__c = DateTime.now();
				} else if (map_oldTickets.get(objTicket.Id).Status__c == TicketUtil.TICKET_STATUS_ESCALATED) {
					objTicket.Days_Escalated__c = Date.today().daysBetween(objTicket.Last_API_Integration_Status_Change__c.date());
					objTicket.Last_API_Integration_Status_Change__c = DateTime.now();
				} else if (map_oldTickets.get(objTicket.Id).Status__c == TicketUtil.TICKET_STATUS_INCOMPLETE) {
					objTicket.Days_Incomplete__c = Date.today().daysBetween(objTicket.Last_API_Integration_Status_Change__c.date());
					objTicket.Last_API_Integration_Status_Change__c = DateTime.now();
				}

				if (objTicket.Status__c == TicketUtil.TICKET_STATUS_COMPLETE || objTicket.Status__c == TicketUtil.TICKET_STATUS_CLOSED) {
					objTicket.Days_to_Resolution__c = Date.today().daysBetween(objTicket.CreatedDate.date());
					objTicket.Last_API_Integration_Status_Change__c = DateTime.now();
				}
			}

			if (objTicket.RecordTypeId == TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID && map_oldTickets.get(objTicket.Id).RecordTypeId != TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID) {
				objTicket.OwnerId = map_GroupIdsByName?.containsKey(TicketUtil.QUEUE_NAME_BIZ_DEV) ? map_GroupIdsByName?.get(TicketUtil.QUEUE_NAME_BIZ_DEV) : UserInfo.getUserId();
				objTicket.Status__c = TicketUtil.TICKET_STATUS_NEW;
			}

			if (
				(objTicket.RecordTypeId == TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID ||
				objTicket.RecordTypeId == TicketUtil.BENEFITS_ONBOARDING_RENEWAL_TICKET_RT_ID) &&
				String.isNotBlank(objTicket.Status__c) &&
				objTicket.Status__c.equalsIgnoreCase(TicketUtil.TICKET_STATUS_CLOSED) &&
				objTicket.Status__c != map_oldTickets.get(objTicket.Id).Status__c &&
				String.isNotBlank(objTicket.Reporting_Team__c) &&
				objTicket.Reporting_Team__c.equalsIgnoreCase(TicketUtil.TICKET_ROLE_FULFILLMENT) &&
				objTicket.Carrier_Order__c != null
			) {
				set_COrderIds.add(objTicket.Carrier_Order__c);
			}

			if (objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID && objTicket.Re_Sync_Tasks__c) {
				set_TaskResyncTicketIds.add(objTicket.Id);
				objTicket.Re_Sync_Tasks__c = false;
			}

			stampPriorityAndRiskFields(objTicket, map_oldTickets.get(objTicket.Id));
			addToArdiusCustomRoutingTracker(objTicket, map_oldTickets.get(objTicket.Id));
			populateTicketNameSearch(objTicket);
		}

		if (!set_COrderIds.isEmpty()) {
			for (Carrier_Order__c objCarrierOrder : [
				SELECT Id, OwnerId, Owner.Name
				FROM Carrier_Order__c
				WHERE ID IN :set_COrderIds AND Implementation_Stage__c NOT IN :CarrierOrderUtil.set_EarlySubmissionImplementationStages
			]) {
				map_coIdAndOwnerIds.put(objCarrierOrder.Id, objCarrierOrder.OwnerId);
			}
		}

		for (Ticket__c objTicket : map_newTickets.values()) {
			if (
				map_coIdAndOwnerIds?.containsKey(objTicket.Carrier_Order__c) &&
				map_coIdAndOwnerIds?.get(objTicket.Carrier_Order__c) != null &&
				map_coIdAndOwnerIds?.get(objTicket.Carrier_Order__c).equalsIgnoreCase(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			) {
				objTicket.addError(TicketUtil.TICKET_STATUS_ERROR_MESSAGE);
			}
		}

		resetUnResponsiveFlag(map_newTickets.values(), map_oldTickets);
		routeThroughArdiusCustomRouting();
		handleTicketOwnerChange(map_newTickets.values(), map_oldTickets);
	}

	public void processAfterUpdate(Map<Id, Ticket__c> map_oldTickets, Map<Id, Ticket__c> map_newTickets) {
		createCollectionsAfter(map_newTickets.values(), map_oldTickets);
		createRevisionRequiredtask(map_newTickets.values(), map_oldTickets);
		updateOrderStatus(map_newTickets.values(), map_oldTickets);
		updateOpportunity(map_newTickets.values(), map_oldTickets);
		autoCloseGeneratedTasks(map_newTickets.values(), map_oldTickets);
		autoCreateTask(map_newTickets.values(), map_oldTickets);
		updateCaseForTicketUpdate();
		ArdiusIntegrationHelper.triggerTicketIntegration(map_newTickets.values(), map_oldTickets);
		assignArdiusTicketOwnerToTaskOwner(map_newTickets);
		updateCarrierOrder(map_newTickets.values(), map_oldTickets);
		updateRelatedOpportunity();
		updateOpportunityToClosedLost(map_newTickets);
	}

	private void processInformation(List<Ticket__c> list_objTickets) {
		Set<Id> set_ticketIds = new Set<Id>();
		Set<Id> set_ticketCaseIds = new Set<Id>();
		Map<Id, Order> map_objOrder = new Map<Id, Order>();
		Map<Id, Case> map_objCase = new Map<Id, Case>();
		/*if the related BO of the Ticket is fulfilled and related CO are approved,
        then Ticket should be assign to MFQueue, only if ticket does not update the status
        */
		List<Ticket__c> list_TicketForCheckingBO = new List<Ticket__c>();
		Set<Id> set_TicketBOId = new Set<Id>();

		Set<Id> set_BYBTicketsId = new Set<Id>();
		Map<Id, Benefit_Order__c> map_BYBBenefitOrders = new Map<Id, Benefit_Order__c>();

		for (Ticket__c objTicket : list_objTickets) {
			if (objTicket.RecordTypeId == TicketUtil.PAYROLL_SALES_ESCALATION_RT_ID) {
				set_ticketIds.add(objTicket.Order__c);
			}
			// Deepak Tyagi, Jan 4, 2018, Desc: Update case for Advising Fulfillment
			if (objTicket.RecordTypeId == TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID && String.isNotBlank(objTicket.Case__c)) {
				set_ticketCaseIds.add(objTicket.Case__c);
			}
			if (
				(objTicket.RecordTypeId == TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID || objTicket.RecordTypeId == TicketUtil.BENEFITS_ONBOARDING_RENEWAL_TICKET_RT_ID) &&
				objTicket.Benefit_Order__c != null
			) {
				list_TicketForCheckingBO.add(objTicket);
				set_TicketBOId.add(objTicket.Benefit_Order__c);
			}

			if (objTicket.Benefit_Order__c != null && objTicket.RecordTypeId == TicketUtil.BENEFITS_BYB_TICKET_RT_ID && objTicket.Team__c != TicketUtil.TICKET_TEAM_BYB_MEMBER_OPS) {
				set_BYBTicketsId.add(objTicket.Benefit_Order__c);
			}
		}

		if (!set_BYBTicketsId.isEmpty()) {
			map_BYBBenefitOrders = new Map<Id, Benefit_Order__c>([SELECT Id, OwnerId, Opportunity__r.OwnerId FROM Benefit_Order__c WHERE Id IN :set_BYBTicketsId]);
		}

		if (!list_TicketForCheckingBO.isEmpty() && !set_TicketBOId.isEmpty()) {
			reAssignIAForInvalidTicketOwner(set_TicketBOId, list_TicketForCheckingBO);
		}
		if (!set_ticketIds.isEmpty()) {
			map_objOrder = new Map<Id, Order>([SELECT Id, OpportunityId, Opportunity.OwnerId, Case__c FROM Order WHERE Id IN :set_ticketIds]);
		}
		// Deepak Tyagi, Jan 4, 2018, Desc: Update case for Advising Fulfillment
		if (!set_ticketCaseIds.isEmpty()) {
			map_objCase = new Map<Id, Case>([SELECT Id, AccountId FROM Case WHERE Id IN :set_ticketCaseIds]);
		}

		for (Ticket__c objTicket : list_objTickets) {
			if (map_BYBBenefitOrders?.containsKey(objTicket.Benefit_Order__c)) {
				if (objTicket.Team__c == FWManageRoleUtil.ROLE_BYB_ADVOCATE) {
					objTicket.OwnerId = map_BYBBenefitOrders?.get(objTicket.Benefit_Order__c)?.OwnerId;
				} else if (objTicket.Team__c == TicketUtil.TICKET_TEAM_BOR_SALES || objTicket.Team__c == TicketUtil.TICKET_TEAM_ADVISING) {
					objTicket.OwnerId = map_BYBBenefitOrders?.get(objTicket.Benefit_Order__c)?.Opportunity__r.OwnerId;
				}
			}

			if (map_objOrder?.containsKey(objTicket.Order__c)) {
				Order objOrder = map_objOrder?.get(objTicket.Order__c);
				if (objOrder.OpportunityId != null) {
					objTicket.Opportunity__c = objOrder.OpportunityId;
					objTicket.OwnerId = objOrder.Opportunity.OwnerId;
				}
				if (objOrder.Case__c != null) {
					objTicket.Case__c = objOrder.Case__c;
				}
			}

			// Deepak Tyagi, Jan 4, 2018, Desc: Update case for Advising Fulfillment
			if (map_objCase?.containsKey(objTicket.Case__c)) {
				Case objCase = map_objCase?.get(objTicket.Case__c);
				if (objCase.AccountId != null) {
					objTicket.Account__c = objCase.AccountId;
				}
			}
		}
	}

	public static void reAssignIAForInvalidTicketOwner(Set<Id> set_BOId, List<Ticket__c> list_Ticket) {
		List<Benefit_Order__c> list_UpdatedBO = new List<Benefit_Order__c>();
		Map<Id, Benefit_Order__c> map_BenefitOrder = new Map<Id, Benefit_Order__c>();
		Map<Id, Id> map_BOIdWithOwnerId = new Map<Id, Id>();
		Set<Id> set_ValidUsers = new Set<Id>();
		Set<String> set_FulfilledBO = new Set<String>();
		Set<String> set_OpenedBO = new Set<String>();
		Set<String> set_ClosedBO = new Set<String>();
		List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
		List<Benefit_Order__c> list_BO = [
			SELECT
				Id,
				Order_Status__c,
				OwnerId,
				Parent_Benefit_Order__c,
				Initial_Owner__c,
				Type__c,
				Tier__c,
				Account__c,
				RecordTypeId,
				Partner_Tier__c,
				Assignment_State__c,
				Coverage_Effective_Date__c,
				Opportunity__c,
				Coverage_Effective_Month__c,
				Coverage_Effective_Year__c,
				Account__r.Priority_Support__c,
				(
					SELECT Id, Implementation_Stage__c, Benefit_Order__c
					FROM Carrier_Orders__r
					WHERE
						RecordtypeId != NULL
						AND Implementation_Stage__c != NULL
						AND Implementation_Stage__c NOT IN :TicketUtil.set_CanceledStatus
						AND Implementation_Stage__c NOT IN :CarrierOrderUtil.set_EarlySubmissionImplementationStages
				)
			FROM Benefit_Order__c
			WHERE Id IN :set_BOId AND Order_Status__c != NULL AND Order_Status__c NOT IN :TicketUtil.set_CanceledStatus
		];
		if (!list_BO.isEmpty()) {
			for (Benefit_Order__c objBO : list_BO) {
				map_BOIdWithOwnerId.put(objBO.Id, objBO.OwnerId);
				map_BenefitOrder.put(objBO.Id, objBO);
				if (objBO.Order_Status__c == TicketUtil.FULFILLED) {
					set_FulfilledBO.add(objBO.Id);
					if (objBO.Carrier_Orders__r.size() > 0) {
						list_CO.addAll(objBO.Carrier_Orders__r);
					}
				}
			}
			if (!list_CO.isEmpty()) {
				for (Carrier_Order__c objCO : list_CO) {
					if (objCO.Implementation_Stage__c != TicketUtil.APPROVED) {
						set_OpenedBO.add(objCO.Benefit_Order__c);
					} else {
						set_ClosedBO.add(objCO.Benefit_Order__c);
					}
				}
				if (!set_OpenedBO.isEmpty() && !set_ClosedBO.isEmpty()) {
					set_ClosedBO.removeAll(set_OpenedBO);
				}
			}
			if (!map_BOIdWithOwnerId.isEmpty()) {
				for (User_Role__c obj_UserRole : [
					SELECT Id, User__c
					FROM User_Role__c
					WHERE
						User_Skill_Team__c = :FWManageRoleUtil.ROLE_IMPLEMENTATION
						AND User_Skill_Type__c = :FWManageRoleUtil.SKILL_TYPE_CORE
						AND User__r.IsActive = TRUE
						AND User__c IN :map_BOIdWithOwnerId.values()
				]) {
					set_ValidUsers.add(obj_UserRole.User__c);
				}

				for (Id objBOId : map_BOIdWithOwnerId.keySet()) {
					if (!set_ValidUsers.isEmpty() && set_ValidUsers.contains(map_BOIdWithOwnerId.get(objBOId)) && !Test.isRunningTest()) {
						continue;
					}
					if (!map_BenefitOrder.isEmpty() && map_BenefitOrder.containsKey(objBOId)) {
						list_UpdatedBO.add(map_BenefitOrder.get(objBOId));
					}
				}
			}
		}
		if (!list_UpdatedBO.isEmpty()) {
			FWAssignmentUtil controller = new FWAssignmentUtil();
			list_UpdatedBO = controller.processAdvocateAssignmentForBO(list_UpdatedBO, true, null, null, null, new Map<Id, Id>());
			if (!list_UpdatedBO.isEmpty()) {
				update list_UpdatedBO;
			}
			for (Benefit_Order__c objBO : list_UpdatedBO) {
				map_BOIdWithOwnerId.put(objBO.Id, objBO.OwnerId);
			}
		}
		if (!list_Ticket.isEmpty()) {
			for (Ticket__c objTicket : list_Ticket) {
				if (!set_ClosedBO.isEmpty() && set_ClosedBO.contains(objTicket.Benefit_Order__c)) {
					objTicket.OwnerId = Label.Member_Fulfillment_Queue;
				} else if (!map_BOIdWithOwnerId.isEmpty() && map_BOIdWithOwnerId.containsKey(objTicket.Benefit_Order__c)) {
					objTicket.OwnerId = map_BOIdWithOwnerId.get(objTicket.Benefit_Order__c);
				}
			}
		}
	}

	private void notifyOwnerClosed(List<Ticket__c> list_objTickets, Map<ID, Ticket__c> map_oldTickets) {
		// store 'From Team' on Ticket
		Set<String> set_fromTeam = new Set<String>();
		// store 'To Team' on Ticket
		Set<String> set_toTeam = new Set<String>();
		Set<String> set_ticketReason = new Set<String>();

		for (Ticket__c objTicket : list_objTickets) {
			Ticket__c objOldTicket = null;
			if (map_oldTickets != null && map_oldTickets?.containsKey(objTicket.Id))
				objOldTicket = map_oldTickets?.get(objTicket.Id);
			// Update InProgress Date/Time field on Status Changed to InProgress
			if (objTicket.Status__c != objOldTicket.Status__c && objTicket.Status__c == TicketUtil.TICKET_STATUS_INPROGRESS) {
				objTicket.InProgress_Date_Time__c = System.now();
			}
			//@Neha For Updating the ClosedBy Field on Ticket
			if (objTicket.Status__c != objOldTicket.Status__c && TicketUtil.TICKET_STATUS_CLOSED.equalsIgnoreCase(objTicket.Status__c)) {
				objTicket.Closed_By__c = userInfo.getUserID();
			}
			// Check if Status Changed to Closed
			if (objTicket.Status__c != TicketUtil.TICKET_STATUS_CLOSED && objTicket.Status__c == objOldTicket.Status__c) {
				continue;
			}
			set_fromTeam.add(objTicket.Reporting_Team__c);
			set_toTeam.add(objTicket.Team__c);
			set_ticketReason.add(objTicket.Escalation_Reason__c);
		}

		// fetching all Ticket Mapping records based on 'To Team' and 'From Team' on Ticket
		if (!set_toTeam.isEmpty() || !set_fromTeam.isEmpty()) {
			for (Ticket_Mapping__c objTicketMapping : [
				SELECT
					Id,
					Ticket_Reason_s__c,
					To_Sub_team__c,
					Goes_back_to_Original_Owner__c,
					Automated_QC_Error_Required__c,
					Order_Status_when_Ticket_is_Closed__c,
					Update_Order_Status__c,
					Order_Status_while_Ticket_is_Open__c,
					Ticket_Reason_Details__c,
					From_Sub_Team_s__c,
					To_Team__c
				FROM Ticket_Mapping__c
				WHERE From_Sub_Team_s__c IN :set_fromTeam AND To_Team__c IN :set_toTeam AND Ticket_Reason_s__c IN :set_ticketReason
			]) {
				String strTicketMappingKey =
					objTicketMapping.From_Sub_Team_s__c +
					objTicketMapping.To_Team__c +
					objTicketMapping.To_Sub_team__c +
					objTicketMapping.Ticket_Reason_s__c +
					objTicketMapping.Ticket_Reason_Details__c +
					'';
				if (!map_objTicketMapping?.containsKey(strTicketMappingKey)) {
					map_objTicketMapping.put(strTicketMappingKey, objTicketMapping);
				}
			}
		}
	}

	// method to update Order Status and Implementation Stage related to Ticket
	private void updateOrderStatus(List<Ticket__c> list_objTickets, Map<Id, Ticket__c> map_oldTickets) {
		// Store all 'Benefit Order' related Ticket
		Map<Id, Benefit_Order__c> map_objBenefitOrders = new Map<Id, Benefit_Order__c>();
		// Store all 'Carrier Order' related Ticket
		Map<Id, Carrier_Order__c> map_objCarrierOrders = new Map<Id, Carrier_Order__c>();
		// Carrier Play Information to Carrier
		Map<String, List<Carrier_Play_Information__c>> map_CarrierToPlayInformation = new Map<String, List<Carrier_Play_Information__c>>();
		// Today's Day in integer
		Integer intToday = Date.today().day();
		// Add all 'Benefit Order' Id
		Set<String> set_BenefitOrderIds = new Set<String>();
		// Add all 'Carrier Order' Id
		Set<String> set_CarrierOrderIds = new Set<String>();
		// List to update 'Benefit Order' related to Ticket
		Map<Id, Benefit_Order__c> map_objBenefitOrdersToUpdate = new Map<Id, Benefit_Order__c>();
		// List to update 'Carrier Order' related to Ticket
		Map<Id, Carrier_Order__c> map_objCarrierOrdersToUpdate = new Map<Id, Carrier_Order__c>();
		List<Carrier_Order__c> lst_MultiEINCO = new List<Carrier_Order__c>();
		// Store all Carrier Ids related to Ticket's Carrier Orders
		Set<Id> set_CarrierIds = new Set<Id>();
		//Changed By Deepika
		//list to update BO Fulfilled
		Map<Id, Benefit_Order__c> map_objFulfilledBOToUpdate = new Map<Id, Benefit_Order__c>();
		//DS[13-10-2020]: store the user id to fetch the user role
		Set<Id> set_UserIds = new Set<Id>();
		Map<Id, User> map_Users = new Map<Id, User>();

		for (Ticket__c objTicket : list_objTickets) {
			Ticket__c objOldTicket = null;
			if (map_oldTickets != null && map_oldTickets?.containsKey(objTicket.Id)) {
				objOldTicket = map_oldTickets?.get(objTicket.Id);
			}

			// Check if Status Changed to Closed or Ticket status is changed to 'Awaiting ER response - Pending Item' @Neha 6th April 2020
			if ((objTicket.Status__c != TicketUtil.TICKET_STATUS_CLOSED || objTicket.Status__c == objOldTicket.Status__c) && !TicketUtil.AWAITING_ER_STATUS.equalsIgnoreCase(objTicket.Status__c)) {
				continue;
			}

			//@Neha 6th April 2020, Update CO only if Ticket status is not 'Awaiting ER response - Pending Item'
			if (!TicketUtil.AWAITING_ER_STATUS.equalsIgnoreCase(objTicket.Status__c)) {
				set_CarrierOrderIds.add(objTicket.Carrier_Order__c);
			}

			if (
				(TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(objTicket.Reporting_Team__c) && TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicket.Sub_Team__c)) ||
				TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicket.Reporting_Team__c) //Neha, 12 Aug, Desc: IA to FULFILLMENT and associate CO, then just update Co.status
			) {
				//Neha, 12 Aug, Desc: From FULFILLMENT to any team, then just update Co.status
				continue;
			}
			set_BenefitOrderIds.add(objTicket.Benefit_Order__c);
		}

		// fetch all Benefit Order
		if (!set_BenefitOrderIds.isEmpty()) {
			//@Neha Dabas, 17th April Fetch related ticket for which ER Outreach has been made
			for (Benefit_Order__c objBenefitOrder : [
				SELECT
					Id,
					Order_Status__c,
					RecordTypeId,
					OwnerId,
					UW_Owner__c,
					(
						SELECT Id, Implementation_Stage__c, Carrier__c, Order_Type__c, OwnerId
						FROM Carrier_Orders__r
						WHERE
							Order_Type__c != :TicketUtil.TERMINATED_ORDER
							AND Implementation_Stage__c NOT IN :TicketUtil.set_CanceledStatus
							AND Implementation_Stage__c NOT IN :CarrierOrderUtil.set_EarlySubmissionImplementationStages
					),
					(SELECT Status__c, ER_Outreach_Count__c FROM Tickets__r WHERE Status__c = :TicketUtil.TICKET_STATUS_ER_OUTREACH_REQ LIMIT 1)
				FROM Benefit_Order__c
				WHERE Id IN :set_BenefitOrderIds
			]) {
				map_objBenefitOrders.put(objBenefitOrder.Id, objBenefitOrder);
				if (String.isNotBlank(objBenefitOrder.UW_Owner__c)) {
					set_UserIds.add(objBenefitOrder.UW_Owner__c);
				}
			}
		}

		// fetch all Carrier Order
		if (!set_CarrierOrderIds.isEmpty()) {
			Set<Id> set_COIdMultiEIN = new Set<Id>();
			for (Carrier_Order__c objCarrierOrder : [
				SELECT
					Id,
					Implementation_Stage__c,
					Benefit_Order__c,
					Benefit_Order__r.Order_Status__c,
					Benefit_Order__r.RecordTypeId,
					Parent_Carrier_Order__c,
					Is_Multi_EIN__c,
					Effective_Date__c,
					Carrier__c,
					Follow_Up_Date__c,
					OwnerId,
					Benefit_Order__r.UW_Owner__c
				FROM Carrier_Order__c
				WHERE Id IN :set_CarrierOrderIds AND Implementation_Stage__c NOT IN :CarrierOrderUtil.set_EarlySubmissionImplementationStages
			]) {
				map_objCarrierOrders.put(objCarrierOrder.Id, objCarrierOrder);
				set_CarrierIds.add(objCarrierOrder.Carrier__c);
				set_UserIds.add(objCarrierOrder.OwnerId);
				if (objCarrierOrder.Is_Multi_EIN__c && objCarrierOrder.Parent_Carrier_Order__c == null) {
					set_COIdMultiEIN.add(objCarrierOrder.Id);
				}
			}
			if (!set_COIdMultiEIN.isEmpty()) {
				lst_MultiEINCO = [
					SELECT Id, Parent_Carrier_Order__c, Carrier__c, Implementation_Stage__c, OwnerId
					FROM Carrier_Order__c
					WHERE Parent_Carrier_Order__c IN :set_COIdMultiEIN AND Is_Multi_EIN__c = TRUE AND Implementation_Stage__c NOT IN :CarrierOrderUtil.set_EarlySubmissionImplementationStages
				];
			}
		}

		if (set_UserIds?.size() > 0) {
			for (User objUser : [
				SELECT Id, IsActive
				FROM User
				WHERE Id IN :set_UserIds
			]) {
				map_Users.put(objUser.Id, objUser);
			}
		}

		if (!set_CarrierIds.isEmpty()) {
			for (Carrier_Play_Information__c objPlayInfo : [
				SELECT Id, Before_After__c, Carrier__c, From__c, To__c, Number_of_Days__c, Event_Type__c, Play_Mode_Type__c
				FROM Carrier_Play_Information__c
				WHERE Carrier__c IN :set_CarrierIds AND Event_Type__c IN :TicketUtil.set_EventTypes AND Play_Mode_Type__c = :TicketUtil.STR_POST_PLAY
			]) {
				String strMapKey = objPlayInfo.Carrier__c + '-' + objPlayInfo.Event_Type__c;
				if (!map_CarrierToPlayInformation.containsKey(strMapKey)) {
					map_CarrierToPlayInformation.put(strMapKey, new List<Carrier_Play_Information__c>{ objPlayInfo });
				} else {
					map_CarrierToPlayInformation.get(strMapKey).add(objPlayInfo);
				}
			}
		}

		for (Ticket__c objTicket : list_objTickets) {
			Ticket__c objOldTicket = null;
			String strTicketMappingKey = objTicket.Reporting_Team__c + objTicket.Team__c + objTicket.Sub_Team__c + objTicket.Escalation_Reason__c + objTicket.Escalation_Reason_Detail__c + '';
			if (map_oldTickets != null && map_oldTickets?.containsKey(objTicket.Id)) {
				objOldTicket = map_oldTickets?.get(objTicket.Id);
			}

			// Check if Status Changed to Closed
			if ((objTicket.Status__c != TicketUtil.TICKET_STATUS_CLOSED || objTicket.Status__c == objOldTicket.Status__c) && !TicketUtil.AWAITING_ER_STATUS.equalsIgnoreCase(objTicket.Status__c)) {
				continue;
			}
			Map<String, String> map_InitialStatus = new Map<String, String>();
			if (String.isNotBlank(objTicket.Initial_Status__c)) {
				map_InitialStatus = UtilitiesFactory.readStringAsMap(objTicket.Initial_Status__c);
			}
			// Check if Carrier Order Map contains Carrier Order related to Ticket.
			if (map_objCarrierOrders?.containsKey(objTicket.Carrier_Order__c)) {
				if (map_objTicketMapping?.containsKey(strTicketMappingKey)) {
					// Check 'Ticket Reason' and 'Ticket Reason Detail' in 'Ticket Mapping'
					if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c != Ticketutil.TICKET_ORDER_STATUS_NO_IMPACT) {
						Carrier_Order__c objCarrierOrder = map_objCarrierOrders?.get(objTicket.Carrier_Order__c);
						/*DS[28-11-2019]: If the status of the CO Or Bo changed to canceled,
						 then we don't have to change to status of the BO or CO when ticket is closed*/
						if (objCarrierOrder.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED) {
							//Update status related to Benefit Transfer Ticket
							if (String.isNotBlank(map_objTicketMapping?.get(strTicketMappingKey).Update_Order_Status__c)) {
								if (TicketUtil.STR_ONLY_AFFECTED_CO.equalsIgnoreCase(map_objTicketMapping?.get(strTicketMappingKey).Update_Order_Status__c)) {
									objCarrierOrder.Implementation_Stage__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
									if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == TicketUtil.ORDER_STATUS_BACK_TO_PRIOR) {
										if (!map_InitialStatus.isEmpty() && map_InitialStatus?.containsKey(String.valueOf(objCarrierOrder.id))) {
											objCarrierOrder.Implementation_Stage__c = map_InitialStatus?.get(objCarrierOrder.id);
										}
									}
									if (
										!lst_MultiEINCO.isEmpty() &&
										(map_objTicketMapping?.get(strTicketMappingKey).From_Sub_Team_s__c == TicketUtil.STR_FACILITATOR_1 ||
										map_objTicketMapping?.get(strTicketMappingKey).From_Sub_Team_s__c == TicketUtil.STR_FACILITATOR_2)
									) {
										for (Carrier_Order__c objCO : lst_MultiEINCO) {
											if (!BTManageTicketsCtrl.updateCOStatusOrNot(objCO, map_objTicketMapping?.get(strTicketMappingKey).Ticket_Reason_Details__c)) {
												continue;
											}
											//SJay - 6/15/2020 - Excluding Closed Admin and Canceled statuses when updating multi ein orders
											if (objCO.Parent_Carrier_Order__c == objCarrierOrder.Id && !TicketUtil.set_ClosedStatuses.contains(objCO.Implementation_Stage__c)) {
												objCO.Implementation_Stage__c = objCarrierOrder.Implementation_Stage__c;
												map_objCarrierOrdersToUpdate.put(objCO.Id, objCO);
											}
										}
									}
									map_objCarrierOrdersToUpdate.put(objCarrierOrder.Id, objCarrierOrder);
								} else {
									Benefit_Order__c orderObj = map_objBenefitOrders?.get(objCarrierOrder.Benefit_Order__c);
									orderObj.Order_Status__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
									if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == TicketUtil.ORDER_STATUS_BACK_TO_PRIOR) {
										if (!map_InitialStatus.isEmpty() && map_InitialStatus.containsKey(String.valueOf(orderObj.id))) {
											orderObj.Order_Status__c = map_InitialStatus.get(orderObj.id);
										}
									}
									map_objBenefitOrdersToUpdate.put(orderObj.Id, orderObj);
									for (Carrier_Order__c objCO : map_objBenefitOrders?.get(objTicket.Benefit_Order__c).Carrier_Orders__r) {
										if (!BTManageTicketsCtrl.updateCOStatusOrNot(objCO, map_objTicketMapping?.get(strTicketMappingKey).Ticket_Reason_Details__c)) {
											continue;
										}
										objCO.Implementation_Stage__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
										if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == TicketUtil.ORDER_STATUS_BACK_TO_PRIOR) {
											if (!map_InitialStatus.isEmpty() && map_InitialStatus.containsKey(String.valueOf(objCO.id))) {
												objCO.Implementation_Stage__c = map_InitialStatus.get(objCO.id);
											}
										}
										map_objCarrierOrdersToUpdate.put(objCO.Id, objCO);
									}
								}
							} else if (String.isBlank(map_objTicketMapping?.get(strTicketMappingKey).Update_Order_Status__c)) {
								//Update Status related to New,Renwal, and Change Tickets
								objCarrierOrder.Implementation_Stage__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
								if (
									objCarrierOrder.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP ||
									objCarrierOrder.Implementation_Stage__c == TicketUtil.TICKET_ORDER_STATUS_PENDING_ITEM
								) {
									if (!map_Users.isEmpty() && map_Users?.containsKey(objCarrierOrder.OwnerId) && map_Users?.get(objCarrierOrder.OwnerId) != null) {
										objCarrierOrder.Requires_Routing__c = markRequiresRerouting(map_Users?.get(objCarrierOrder.OwnerId));
									} else if (
										objCarrierOrder.OwnerId != null &&
										String.valueOf(objCarrierOrder.OwnerId).startsWith(TicketUtil.PERFIX_USER) &&
										!UserUtils.isActive(objCarrierOrder.OwnerId)
									) {
										objCarrierOrder.Requires_Routing__c = true;
									}
								}
								//Changes by AKS Dated 10th Sept 2019
								//Given by Ashveej
								// Ticket Close Date Day in integer
								Integer intCloseDay;
								// If Coverage Effective Date is future date i.e., at least 1 month in future then use 1-15 configuration.
								if (OnboardingPlayModeUtility.checkDatesAtleast1MonthApart(System.today(), objCarrierOrder.Effective_Date__c)) {
									intCloseDay = 1;
								} else if (!OnboardingPlayModeUtility.checkDatesAtleast1MonthApart(System.today(), objCarrierOrder.Effective_Date__c) && objTicket.Close_Date__c != null) {
									intCloseDay = objTicket.Close_Date__c.day();
								}
								Integer intSetDays;
								if (objCarrierOrder.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION && objTicket.Close_Date__c != null) {
									// SJay - 4/9/2020 - added new confirmation play mode logic.
									intSetDays = 0;
									if (map_CarrierToPlayInformation?.containsKey(objCarrierOrder.Carrier__c + '-' + TicketUtil.STR_ORDER)) {
										for (Carrier_Play_Information__c objPlayInfo : map_CarrierToPlayInformation?.get(objCarrierOrder.Carrier__c + '-' + TicketUtil.STR_ORDER)) {
											if (
												objTicket.Close_Date__c < objCarrierOrder.Effective_Date__c &&
												//playInfo.Before_After__c == 'Before' &&
												objPlayInfo.Before_After__c.containsIgnoreCase(TicketUtil.BEFORE_EVENT) &&
												objPlayInfo.From__c <= intCloseDay &&
												objPlayInfo.To__c >= intCloseDay
											) {
												intSetDays = (Integer) objPlayInfo.Number_of_Days__c;
											} else if (
												(objTicket.Close_Date__c >= objCarrierOrder.Effective_Date__c || objCarrierOrder.Effective_Date__c < Date.today()) &&
												//objPlayInfo.Before_After__c == 'BeforeOnward')
												TicketUtil.BEFORE_ONWARD_EVENT.equalsIgnoreCase(objPlayInfo.Before_After__c)
											) {
												intSetDays = (Integer) objPlayInfo.Number_of_Days__c;
											}
										}
									}
									objCarrierOrder.Follow_Up_Date__c = objTicket.Close_Date__c.addDays(intSetDays);
								} else if (
									objCarrierOrder.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED_PENDING_EE_AUDIT &&
									objTicket.Close_Date__c != null &&
									objTicket.Close_Date__c >= objCarrierOrder.Effective_Date__c
								) {
									// SJay - 4/9/2020 - added new confirmation play mode logic.
									intSetDays = 0;
									if (map_CarrierToPlayInformation?.containsKey(objCarrierOrder.Carrier__c + '-' + TicketUtil.STR_AUDIT)) {
										for (Carrier_Play_Information__c objPlayInfo : map_CarrierToPlayInformation?.get(objCarrierOrder.Carrier__c + '-' + TicketUtil.STR_AUDIT)) {
											if (TicketUtil.AFTER_EVENT.equalsIgnoreCase(objPlayInfo.Before_After__c) && objPlayInfo.From__c <= intCloseDay && objPlayInfo.To__c >= intCloseDay) {
												intSetDays = (Integer) objPlayInfo.Number_of_Days__c;
											}
										}
									}
									objCarrierOrder.Follow_Up_Date__c = objTicket.Close_Date__c.addDays(intSetDays);
								}
								map_objCarrierOrdersToUpdate.put(objCarrierOrder.Id, objCarrierOrder);
								//if the from team is Confirmation and Order status when ticket is closed is
								// apporved or approved pending EE audit

								//Changed By Deepika
								if (
									TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicket.Reporting_Team__c) &&
									(map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == TicketUtil.APPROVED ||
									map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == TicketUtil.APPROVED_PENDING_EE_AUDIT)
								) {
									Benefit_Order__c objbenefitOrder = map_objBenefitOrders?.get(objCarrierOrder.Benefit_Order__c);
									map_objFulfilledBOToUpdate.put(objbenefitOrder.Id, objbenefitOrder);
								}
								//end

								if (
									(TicketUtil.TICKET_ROLE_IMPLEMENTATION.equalsIgnoreCase(objTicket.Reporting_Team__c) &&
									TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicket.Sub_Team__c)) || //Neha, 12 Aug, Desc: IA to FULFILLMENT and associate CO, then just update Co.status
									TicketUtil.TICKET_ROLE_FULFILLMENT.equalsIgnoreCase(objTicket.Reporting_Team__c)
								) {
									continue;
								}
								Benefit_Order__c objbenefitOrder = map_objBenefitOrders?.get(objCarrierOrder.Benefit_Order__c);

								objbenefitOrder.Order_Status__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
								map_objBenefitOrdersToUpdate.put(objbenefitOrder.Id, objbenefitOrder);
							}
						}
					}
				}
			} else if (map_objBenefitOrders?.containsKey(objTicket.Benefit_Order__c)) {
				// Check if Benefit Order Map contains Benefit Order related to Ticket.
				//@Neha 6th April 2020, Update BO.Status to 'Awaiting ER response - Pending Item' if ticket status is set to 'Awaiting ER response - Pending Item'
				if (TicketUtil.AWAITING_ER_STATUS.equalsIgnoreCase(objTicket.Status__c)) {
					Benefit_Order__c objBenefitOrder = map_objBenefitOrders?.get(objTicket.Benefit_Order__c);
					if (objBenefitOrder.Tickets__r.isEmpty()) {
						objBenefitOrder.Order_Status__c = TicketUtil.AWAITING_ER_STATUS;
					} else
						objBenefitOrder.Order_Status__c = TicketUtil.TICKET_STATUS_ER_OUTREACH_REQ;

					map_objBenefitOrdersToUpdate.put(objBenefitOrder.Id, objBenefitOrder);
					continue;
				}
				if (map_objTicketMapping?.containsKey(strTicketMappingKey)) {
					// Check 'Ticket Reason' and 'Ticket Reason Detail' in 'Ticket Mapping'
					if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c != TicketUtil.TICKET_ORDER_STATUS_NO_IMPACT) {
						Benefit_Order__c objBenefitOrder = map_objBenefitOrders?.get(objTicket.Benefit_Order__c);
						/*DS[28-11-2019]: If the status of the CO Or Bo changed to canceled,
						 then we don't have to change to status of the BO or CO when ticket is closed*/
						if (objBenefitOrder.Order_Status__c != BenefitOrderUtil.STATUS_CANCELLED) {
							//Update status related to Benefit Transfer Ticket
							if (String.isNotBlank(map_objTicketMapping?.get(strTicketMappingKey).Update_Order_Status__c)) {
								if (TicketUtil.STR_ONLY_AFFECTED_CO.equalsIgnoreCase(map_objTicketMapping?.get(strTicketMappingKey).Update_Order_Status__c)) {
									for (Carrier_Order__c objCO : map_objBenefitOrders?.get(objTicket.Benefit_Order__c).Carrier_Orders__r) {
										if (objCO.id == objTicket.Carrier_Order__c) {
											objCO.Implementation_Stage__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
											if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == Ticketutil.ORDER_STATUS_BACK_TO_PRIOR) {
												if (!map_InitialStatus.isEmpty() && map_InitialStatus?.containsKey(String.valueOf(objCO.id))) {
													objCO.Implementation_Stage__c = map_InitialStatus.get(objCO.id);
												}
											}
											map_objCarrierOrdersToUpdate.put(objCO.Id, objCO);
										}
									}
								} else {
									objBenefitOrder.Order_Status__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
									if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == TicketUtil.ORDER_STATUS_BACK_TO_PRIOR) {
										if (!map_InitialStatus.isEmpty() && map_InitialStatus.containsKey(String.valueOf(objBenefitOrder.id))) {
											objBenefitOrder.Order_Status__c = map_InitialStatus.get(objBenefitOrder.id);
										}
									}
									map_objBenefitOrdersToUpdate.put(objBenefitOrder.Id, objBenefitOrder);
									for (Carrier_Order__c objCO : map_objBenefitOrders?.get(objTicket.Benefit_Order__c).Carrier_Orders__r) {
										if (!BTManageTicketsCtrl.updateCOStatusOrNot(objCO, map_objTicketMapping?.get(strTicketMappingKey).Ticket_Reason_Details__c)) {
											continue;
										}
										if (map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c == Ticketutil.ORDER_STATUS_BACK_TO_PRIOR) {
											if (!map_InitialStatus.isEmpty() && map_InitialStatus?.containsKey(String.valueOf(objCO.id))) {
												objCO.Implementation_Stage__c = map_InitialStatus?.get(objCO.id);
											}
										} else {
											objCO.Implementation_Stage__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
										}
										map_objCarrierOrdersToUpdate.put(objCO.Id, objCO);
									}
								}
							} else if (String.isBlank(map_objTicketMapping?.get(strTicketMappingKey).Update_Order_Status__c)) {
								//Update Status related to New,Renwal, and Change Tickets
								objBenefitOrder.Order_Status__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;

								if (objBenefitOrder.Order_Status__c == TicketUtil.ORDER_STATUS_BACK_TO_PRIOR) {
									if (!map_InitialStatus.isEmpty() && map_InitialStatus.containsKey(String.valueOf(objBenefitOrder.id))) {
										objBenefitOrder.Order_Status__c = map_InitialStatus.get(objBenefitOrder.id);
									}
								}

								map_objBenefitOrdersToUpdate.put(objBenefitOrder.Id, objBenefitOrder);

								for (Carrier_Order__c objCO : map_objBenefitOrders?.get(objTicket.Benefit_Order__c).Carrier_Orders__r) {
									if (objCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
										continue;
									}
									objCO.Implementation_Stage__c = map_objTicketMapping?.get(strTicketMappingKey).Order_Status_when_Ticket_is_Closed__c;
									map_objCarrierOrdersToUpdate.put(objCO.Id, objCO);
								}
							}
						}
					}
				}
			}
		}

		CaseTriggerHelper.skipTrigger = true;
		if (!map_objFulfilledBOToUpdate.isEmpty()) {
			blnUpdateBOStatusAsFulfilled = true;
		}

		if (!map_objBenefitOrdersToUpdate.isEmpty()) {
			update map_objBenefitOrdersToUpdate.values();
		}
		if(!map_objCarrierOrdersToUpdate.isEmpty()){
			Map<Id, Carrier_Order__c> map_COToUpdate = new Map<Id, Carrier_Order__c>();	
			Set<Id> set_CarrierOrderTasksIds = new Set<Id>();
			Map<Id, List<Task>> map_OpenTasks = new Map<Id, List<Task>>();
			for (Carrier_Order__c objCo : map_objCarrierOrdersToUpdate.values()) {
				 if(objCo.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED || objCo.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED_PENDING_EE_AUDIT){
					set_CarrierOrderTasksIds.add(objCo.Id);
				 }
			}

			if (!set_CarrierOrderTasksIds.isEmpty()) {
				
		
				for (Task objTask :  [
					SELECT Id, Status, WhatId 
					FROM Task 
					WHERE WhatId IN :set_CarrierOrderTasksIds AND Status != 'Completed'
				]) {
					if (!map_OpenTasks.isEmpty() || !map_OpenTasks.containsKey(objTask.WhatId)) {
						map_OpenTasks.get(objTask.WhatId).add(objTask);
					}
				}

			}
			if(!map_OpenTasks.isEmpty()){
				for (Ticket__c objTicket : list_objTickets) {
					if (objTicket.Carrier_Order__c != null && map_objCarrierOrdersToUpdate.containsKey(objTicket.Carrier_Order__c) && map_OpenTasks.containsKey(objTicket.Carrier_Order__c)) {
						objTicket.addError(TicketUtil.ERR_CARRIER_ORDER_HAS_OPEN_TASK);
					}
				}
				for (Carrier_Order__c objCo : map_objCarrierOrdersToUpdate.values()) {
					if(!map_OpenTasks.containsKey(objCo.Id)){
						map_COToUpdate.put(objCo.Id,objCo);
					}
			   }
			}else{
				map_COToUpdate = map_objCarrierOrdersToUpdate;
			}

			if(!map_COToUpdate.isEmpty()){
				update map_COToUpdate.values();
			}			
		}
		CaseTriggerHelper.skipTrigger = false;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Mark the require Re routing field if Owner is Invalid
	 * @Parm        : objUser - object of User
	 *                strTeam - team of the ticket
	 * @Return      : Boolean - Onwer is valid or not
	 **/
	public Boolean markRequiresRerouting(User objUser) {
		Boolean blnIsOwnerInValid = false;

		if (objUser != null && !objUser.IsActive) {
			// owner is Inactive
			blnIsOwnerInValid = true;
		}

		return blnIsOwnerInValid;
	}

	// Method to create Ticket Status History
	public void createTicketStatusHistory(List<Ticket__c> list_objTickets, Map<Id, Ticket__c> map_oldTicketsObj) {
		List<Ticket_Status_History__c> list_objTicketHistory = new List<Ticket_Status_History__c>();
		for (Ticket__c objTicket : list_objTickets) {
			Ticket__c objOldTicket = null;
			if (map_oldTicketsObj != null && map_oldTicketsObj?.containsKey(objTicket.Id))
				objOldTicket = map_oldTicketsObj?.get(objTicket.Id);

			if (objOldTicket == null) {
				list_objTicketHistory.add(getTicketStatusHistoryRec(objTicket, objOldTicket));
			} else if (objTicket.Status__c != objOldTicket.Status__c && objTicket.Status__c != null && objTicket.Ticket_Status_Change_Date__c != null && !blnStatusHistoryProcessed) {
				list_objTicketHistory.add(getTicketStatusHistoryRec(objTicket, objOldTicket));
			} else if (objTicket.Status__c != objOldTicket.Status__c) {
				objTicket.Ticket_Status_Change_Date__c = System.now();
			}
			blnStatusHistoryProcessed = true;
		}

		if (!list_objTicketHistory.isEmpty()) {
			insert list_objTicketHistory;
		}
	}

	/**
	 * @author:      Swati Arya
	 * @description: build the Ticket Status History Record for Insert
	 * @parm:        new Ticket Record, Old Ticket Record
	 * @return:      Ticket Status History Record
	 **/
	private Ticket_Status_History__c getTicketStatusHistoryRec(Ticket__c objTicket, Ticket__c objOldTicket) {
		Ticket_Status_History__c objTicketHistory = new Ticket_Status_History__c();

		objTicketHistory.End_Time__c = System.now();
		objTicketHistory.Ticket__c = objTicket.Id;
		objTicketHistory.To_Status__c = objTicket.Status__c;
		objTicketHistory.Status_Change_User__c = UserInfo.getUserId();

		if (objOldTicket == null) {
			objTicketHistory.Start_Time__c = System.now();
			objTicketHistory.Ticket_Creation__c = true;
		} else {
			objTicketHistory.From_Status__c = objOldTicket.Status__c;
			objTicketHistory.Start_Time__c = objTicket.Ticket_Status_Change_Date__c;
			objTicket.Ticket_Status_Change_Date__c = System.now();
		}

		return objTicketHistory;
	}
	/**
	 * @author:      Atul
	 * @description: Popuate Ticket Name Search Field
	 * @parm:        new Ticket Record, Old Ticket Record
	 * @return:      void
	 **/
	private void populateTicketNameSearch(Ticket__c objTicket) {
		String strTicketName = '';
		if (map_TicketAccounts != null && map_TicketAccounts.containsKey(objTicket.Account__c)) {
			strTicketName = map_TicketAccounts.get(objTicket.Account__c).Name;
			if (String.isNotBlank(objTicket.Tax_Year__c)) {
				strTicketName = strTicketName + ' ' + objTicket.Tax_Year__c;
			}
			if (objTicket.Controlled_Group__c) {
				strTicketName = strTicketName + ' - ' + TicketUtil.CONTROL_GROUP;
			}
			objTicket.Ticket_Name_Search__c = strTicketName;
		}
	}
	/**
     * @author:      Midhuna KB
     * @description: Populate Assigned_to_User_At__c when a ticket is assigned to a user from a Queue,
                     InProgress_Date_Time__c when the status changes from New to any other
                     and Time_To_FirstResponse__c - business hours between InProgress_Date_Time__c and Time_To_FirstResponse__c
     * @parm:        Trigger.New and Trigger.oldMap
     * @return:      N/A
    **/
	private void setTimeToFirstResponse(List<Ticket__c> list_NewTickets, Map<ID, Ticket__c> map_OldTickets) {
		Map<String, String> map_TicketRecordTypeToBusinessHours = new Map<String, String>();
		Map<String, Id> map_BusinessHoursNameToId = new Map<String, Id>();
		Map<String, String> map_TicketRecordTypeIdToName = Cache.getAllRecordTypeMap('Ticket__c');
		Id idBusinessHourId;

		for (Ticket_Setting__mdt objTicketSetting : Ticket_Setting__mdt.getAll().values()) {
			if (objTicketSetting.IsActive__c == true) {
				map_TicketRecordTypeToBusinessHours.put(objTicketSetting.Record_Type_Name__c, objTicketSetting.Default_Business_Hours__c);
			}
		}

		if (!map_TicketRecordTypeToBusinessHours.isEmpty()) {
			for (BusinessHours objBusinessHours : [SELECT Id, Name FROM BusinessHours WHERE Name IN :map_TicketRecordTypeToBusinessHours.values()]) {
				map_BusinessHoursNameToId.put(objBusinessHours.Name, objBusinessHours.Id);
			}
		}

		for (Ticket__c objTicket : list_NewTickets) {
			Ticket__c objOldTicket = map_OldTickets.get(objTicket.Id);

			if (
				objOldTicket.Assigned_to_User_At__c == null &&
				objOldTicket.OwnerId != objTicket.OwnerId &&
				('' + objTicket.OwnerId).startsWith(TicketUtil.USER_PREFIX) &&
				('' + objOldTicket.OwnerId).startsWith(TicketUtil.GROUP_PREFIX)
			) {
				objTicket.Assigned_to_User_At__c = System.now();
			}

			if (objTicket.Status__c != objOldTicket.Status__c && objOldTicket.Status__c == TicketUtil.TICKET_STATUS_NEW) {
				objTicket.InProgress_Date_Time__c = System.now();
			}

			if (
				map_TicketRecordTypeIdToName.containsKey(objTicket.RecordTypeId) &&
				(map_TicketRecordTypeToBusinessHours.containsKey(map_TicketRecordTypeIdToName.get(objTicket.RecordTypeId))) &&
				(map_BusinessHoursNameToId.containsKey(map_TicketRecordTypeToBusinessHours.get(map_TicketRecordTypeIdToName.get(objTicket.RecordTypeId))))
			) {
				idBusinessHourId = map_BusinessHoursNameToId.get(map_TicketRecordTypeToBusinessHours.get(map_TicketRecordTypeIdToName.get(objTicket.RecordTypeId)));
			}

			if (objTicket.InProgress_Date_Time__c != null && objTicket.Assigned_to_User_At__c != null && idBusinessHourId != null) {
				objTicket.Time_To_FirstResponse__c = (BusinessHours.diff(idBusinessHourId, objTicket.Assigned_to_User_At__c, objTicket.InProgress_Date_Time__c) / 3600000);
			}
		}
	}

	public static Boolean setBOStatusAsFulfilled(Map<Id, Benefit_Order__c> map_BOFulfilled) {
		Boolean blnBOStatusChange = false;
		Map<Id, List<Carrier_Order__c>> map_BOWithCOs = new Map<Id, List<Carrier_Order__c>>();
		List<Carrier_Order__c> list_COs = new List<Carrier_Order__c>();
		for (Carrier_Order__c objCO : [
			SELECT Id, Implementation_Stage__c, Carrier__c, Order_Type__c, OwnerId, Benefit_Order__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c IN :map_BOFulfilled.keySet()
				AND Order_Type__c != :TicketUtil.TERMINATED_ORDER
				AND Implementation_Stage__c NOT IN :TicketUtil.set_CanceledStatus
				AND Implementation_Stage__c NOT IN :CarrierOrderUtil.set_EarlySubmissionImplementationStages
		]) {
			list_COs = new List<Carrier_Order__c>();
			if (map_BOWithCOs?.containsKey(objCO.Benefit_Order__c)) {
				list_COs = map_BOWithCOs?.get(objCO.Benefit_Order__c);
			}
			list_COs.add(objCO);
			map_BOWithCOs.put(objCO.Benefit_Order__c, list_COs);
		}

		Set<String> setBOIdWithOpenTicket = new Set<String>();
		for (Ticket__c objTicket : [SELECT Id, Benefit_Order__c FROM Ticket__c WHERE Status__c != :TicketUtil.TICKET_STATUS_CLOSED AND Benefit_Order__c IN :map_BOFulfilled.keySet()]) {
			setBOIdWithOpenTicket.add(objTicket.Benefit_Order__c);
		}

		Set<Id> set_ApprovedBOId = new Set<Id>();
		for (Benefit_Order_Status_Change_History__c objBOStatus : [
			SELECT id, Benefit_Order__c
			FROM Benefit_Order_Status_Change_History__c
			WHERE Benefit_Order__c IN :map_BOFulfilled.keySet() AND To_Status__c = :TicketUtil.FULFILLED
		]) {
			set_ApprovedBOId.add(objBOStatus.Benefit_Order__c);
		}

		for (Benefit_Order__c objBO : map_BOFulfilled.values()) {
			if (!setBOIdWithOpenTicket.contains(objBO.Id)) {
				Boolean blnBOWithOutApproved = false;
				for (Carrier_Order__c objCO : map_BOWithCOs.get(objBO.Id)) {
					if (objCO.Implementation_Stage__c != TicketUtil.APPROVED && objCO.Implementation_Stage__c != TicketUtil.APPROVED_PENDING_EE_AUDIT) {
						blnBOWithOutApproved = true;
						break;
					}
				}
				if (blnBOWithOutApproved && set_ApprovedBOId?.contains(objBO.Id)) {
					objBO.Order_Status__c = TicketUtil.FULFILLED;
					blnBOStatusChange = true;
				}
			}
		}

		return blnBOStatusChange;
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : To create collections to be used across various methods.
	 * @Parm        : list_Tickets__c - List of new ticket records
	 * @Return      : N/A
	 **/
	public void createCollectionsBefore(List<Ticket__c> list_Tickets) {
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_AccountIds = new Set<String>();
		map_QueriedAccounts = new Map<String, Account>();
		map_TicketAccounts = new Map<String, Account>();
		// Filtering for only Payroll Audit tickets
		for (Ticket__c objTicket : list_Tickets) {
			if (objTicket.RecordTypeId == TicketUtil.PAYROLL_AUDIT_TICKET_RT_ID && String.isNotBlank(objTicket.Company_ID__c)) {
				set_CompanyIds.add(objTicket.Company_ID__c);
			}
			if (objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID && String.IsNotBlank(objTicket.Account__c)) {
				set_AccountIds.add(objTicket.Account__c);
			}
		}

		if (!set_CompanyIds.isEmpty() || !set_AccountIds.isEmpty()) {
			for (Account objAccount : [SELECT Id, ZP_Company_ID__c, Name FROM Account WHERE (ZP_Company_ID__c != NULL AND ZP_Company_ID__c IN :set_CompanyIds) OR Id IN :set_AccountIds]) {
				if (set_CompanyIds.contains(objAccount.ZP_Company_ID__c)) {
					map_QueriedAccounts.put(objAccount.ZP_Company_ID__c, objAccount);
				}
				if (set_AccountIds.contains(objAccount.Id)) {
					map_TicketAccounts.put(objAccount.Id, objAccount);
				}
			}
		}
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : To create collections to be used across various methods.
	 * @Parm        : list_Tickets__c - List of new ticket records
	 * @Return      : N/A
	 **/
	public void createCollectionsAfter(List<Ticket__c> list_Tickets, Map<Id, Ticket__c> map_OldTickets) {
		Set<String> set_AccountIds = new Set<String>();
		map_TicketAccounts = new Map<String, Account>();
		list_TicketCases = new List<Case>();
		map_TicketByCaseIds = new Map<String, Ticket__c>();
		map_Tasks = new Map<Id, Task>();
		set_ArdiusOwnerChangeTicketIds = new Set<Id>();

		Set<Id> set_TaskWhatIdToQuery = new Set<Id>();
		Set<Id> set_ArdiusTicketIntegrationUserIds = TicketUtil.getArdiusTicketIntegrationUsers();
		Set<String> set_TicketStatusesForClientApprovalTracking = TicketUtil.getArdiusTicketStatusesToUpdateOppty();
		Set<String> set_TicketStatusForOpptyToBeClosedLost = TicketUtil.getArdiusTicketStatusToUpdateOppToCloseLost();

		// Filtering for only Ardius tickets
		for (Ticket__c objTicket : list_Tickets) {
			if (objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID && String.IsNotBlank(objTicket.Account__c)) {
				set_AccountIds.add(objTicket.Account__c);
			}
			if (String.isNotBlank(objTicket.Case__c)) {
				map_TicketByCaseIds.put(objTicket.Case__c, objTicket);
			}

			//Ardius Ticket where Owner changes to another User
			Ticket__c objOldTicket = map_OldTickets?.get(objTicket.Id);
			if (
				objOldTicket != null &&
				objTicket.OwnerId != objOldTicket.OwnerId &&
				objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID &&
				!checkIfIdIsGroup(objTicket.OwnerId)
			) {
				set_TaskWhatIdToQuery.add(objTicket.Id);
				set_ArdiusOwnerChangeTicketIds.add(objTicket.Id);
			}

			if (
				objTicket.Opportunity__c != null &&
				objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID &&
				(map_OldTickets == null ||
				objTicket.Status__c != objOldTicket.Status__c) &&
				set_TicketStatusesForClientApprovalTracking.contains(objTicket.Status__c)
			) {
				set_OpptyIdsToClosedWon.add(objTicket.Opportunity__c);
			}

			if (
				objTicket.Opportunity__c != null &&
				objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID &&
				(map_OldTickets == null ||
				objTicket.Status__c != objOldTicket.Status__c) &&
				set_TicketStatusForOpptyToBeClosedLost.contains(objTicket.Status__c)
			) {
				set_OpptyIdsToClosedLost.add(objTicket.Opportunity__c);
			}

			if (
				objTicket.Opportunity__c != null &&
				objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID &&
				objTicket.Status__c != TicketUtil.TICKET_STATUS_CLOSED &&
				(objOldTicket == null || (objTicket.Status__c != objOldTicket.Status__c && objOldTicket.Status__c == TicketUtil.TICKET_STATUS_LOST))
			) {
				set_OpptyIdsToReOpen.add(objTicket.Opportunity__c);
			}

			if (objTicket.Opportunity__c != null && objTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID && (objOldTicket == null || (objTicket.Status__c != objOldTicket.Status__c))) {
				list_ArdiusStatusChangedTickets.add(objTicket);
			}
		}

		if (!set_AccountIds.isEmpty()) {
			for (Account objAccount : [SELECT Id, Name FROM Account WHERE ID IN :set_AccountIds]) {
				map_TicketAccounts.put(objAccount.Id, objAccount);
			}
		}

		list_TicketCases = [SELECT Id, Status, Internal_Support_Requested_From__c, RecordTypeId FROM Case WHERE Id IN :map_TicketByCaseIds.keySet()];

		//Query Tasks
		if (!set_TaskWhatIdToQuery.isEmpty()) {
			map_Tasks = new Map<Id, Task>(queryTasks(set_TaskWhatIdToQuery, new Set<String>{ TAskUtil.TASK_STATUS_OPEN }, new Set<Id>{ TaskUtil.TASK_STANDARD_RT_ID }));
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Update Opportunity related with the Ticket
	 * @param         List of Tickets with new values, MAP of ID and Tickets with old values
	 * @return       N/A
	 **/
	public void updateOpportunity(List<Ticket__c> list_Tickets, Map<Id, Ticket__c> map_oldTickets) {
		Set<Id> set_OpportunityIds = new Set<Id>();
		for (Ticket__c objTicket : list_Tickets) {
			if (
				objTicket.Status__c == TicketUtil.TICKET_STATUS_CLOSED &&
				objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_RECERTIFICATION &&
				objTicket.Status__c != map_oldTickets?.get(objTicket.Id).Status__c
			) {
				set_OpportunityIds.add(objTicket.Opportunity__c);
			}
		}

		if (!set_OpportunityIds.isEmpty()) {
			List<Opportunity> list_Opportunities = [SELECT Id, Advising_Blocked_Reason__c FROM Opportunity WHERE Id IN :set_OpportunityIds];
			for (Opportunity objOpp : list_Opportunities) {
				objOpp.Advising_Blocked_Reason__c = null;
			}

			Boolean blnOppSkipTrigger = OpportunityTriggerHelper.skipTrigger;
			OpportunityTriggerHelper.skipTrigger = true;
			update list_Opportunities;
			OpportunityTriggerHelper.skipTrigger = blnOppSkipTrigger;
		}
	}

	/**
	 * @author Ajay Krishna P U
	 * @description           Auto Create Tasks based on Task_Template__mdt
	 * @param list_NewTickets New version of Tickets
	 * @param map_OldTickets  Old Version of Tickets
	 */
	private static void autoCreateTask(List<Ticket__c> list_NewTickets, Map<Id, Ticket__c> map_OldTickets) {
		Boolean blnIsInsert = map_OldTickets == null;
		List<TaskTemplateUtil.TemplateType> list_TaskTemplateTypes = new List<TaskTemplateUtil.TemplateType>();
		Set<String> set_StatusHaveTemplate = TaskTemplateUtil.getTemplateSubTypes(TicketUtil.ARDIUS_TICKET_TEMPLATE);

		//Identify Tickets to be processed
		for (Ticket__c objTicket : list_NewTickets) {
			if (objTicket.RecordTypeId != TicketUtil.ARDIUS_TICKET_RT_ID) {
				continue;
			}

			Set<String> setTaskIdentifiers = new Set<String>();
			if (
				set_StatusHaveTemplate.contains(objTicket.Task_Template_Identifier__c) &&
				(blnIsInsert ||
				objTicket.Task_Template_Identifier__c != map_OldTickets.get(objTicket.Id).Task_Template_Identifier__c ||
				set_TaskResyncTicketIds.contains(objTicket.Id))
			) {
				setTaskIdentifiers.add(objTicket.Task_Template_Identifier__c);
			}

			if (
				objTicket.Amendment_Eligible__c &&
				objTicket.Qualification_Status__c == TicketUtil.QUALIFICATION_STATUS_QUALIFIED &&
				objTicket.Company_Information_Complete__c &&
				(blnIsInsert ||
				objTicket.Amendment_Eligible__c != map_OldTickets.get(objTicket.Id).Amendment_Eligible__c ||
				objTicket.Qualification_Status__c != map_OldTickets.get(objTicket.Id).Qualification_Status__c ||
				objTicket.Company_Information_Complete__c != map_OldTickets.get(objTicket.Id).Company_Information_Complete__c) &&
				objTicket.Status__c != TicketUtil.TICKET_STATUS_LOST
			) {
				if (!String.isBlank(objTicket.Experiment_Code__c) && objTicket.Experiment_Code__c != null) {
					if (String.valueOf(objTicket.Experiment_Code__c).toLowerCase() == TicketUtil.STR_TICKET_EXPERIMENT_CODE_VALUE.toLowerCase()) {
						setTaskIdentifiers.add(TicketUtil.TICKET_TEMPLATE_EC_FV_AMENDMENT_ELIGIBLE);
					}
				} else {
					setTaskIdentifiers.add(TicketUtil.TICKET_TEMPLATE_FV_AMENDMENT_ELIGIBLE);
				}
			}

			if (map_OldTickets != null && (objTicket.Status__c != map_OldTickets?.get(objTicket.Id).Status__c) && objTicket.Status__c == TicketUtil.TICKET_STATUS_CALC_APPROVAL_PENDING) {
				setTaskIdentifiers.add(TaskUtil.TASK_FEATURE_REQUEST);
			}

			Map<String, String> map_OverrideTaskFields = new Map<String, String>{ TicketUtil.TASK_FIELD_PRIORITY => objTicket.Task_Priority__c };
			for (String strTemplateIdentifier : setTaskIdentifiers) {
				list_TaskTemplateTypes.add(new TaskTemplateUtil.TemplateType(objTicket.Id, TicketUtil.ARDIUS_TICKET_TEMPLATE, strTemplateIdentifier, map_OverrideTaskFields));
			}
		}
		//Reset the tracker to avoid re-processing
		set_TaskResyncTicketIds = new Set<Id>();

		//Return If No data to process
		if (list_TaskTemplateTypes.isEmpty()) {
			return;
		}

		//Generate Task to Insert
		List<Task> list_TaskToInsert = TaskTemplateUtil.generateTasks(list_TaskTemplateTypes, TicketUtil.OBJECT_TICKET);

		//Insert Tasks
		insert list_TaskToInsert;
	}

	/**
	 * @author       Deepesh Rao
	 * @description  Update Anticipated Close Date
	 * @param         List of Tickets with new values, MAP of ID and Tickets with old values
	 * @return       N/A
	 **/
	private void updateAnticipatedCloseDate(List<Ticket__c> list_objTickets, Map<Id, Ticket__c> map_oldTickets) {
		for (Ticket__c objTicket : list_objTickets) {
			if (!map_oldTickets?.get(objTicket.Id).Revisions_Required__c && objTicket.Revisions_Required__c) {
				if (!String.valueOf(objTicket.OwnerId).startsWithIgnoreCase(TicketUtil.USER_PREFIX)) {
					objTicket.addError(TicketUtil.TICKET_OWNER_MSG);
				} else {
					objTicket.Anticipated_Close_Date__c = null;
				}
			}
		}
	}

	/**
	 * @author       Deepesh Rao
	 * @description  Create revision required task
	 * @param         List of Tickets with new values
	 * @return       N/A
	 **/
	private void createRevisionRequiredtask(List<Ticket__c> list_objTickets, Map<Id, Ticket__c> map_oldTickets) {
		List<Task> list_taskToInsert = new List<Task>();
		string strAccountName = '';
		for (Ticket__c objTicket : list_objTickets) {
			if (map_oldTickets?.get(objTicket.Id).Revisions_Required__c == false && objTicket.Revisions_Required__c) {
				Task objTask = new Task();
				strAccountName = map_TicketAccounts?.containsKey(objTicket.Account__c) ? map_TicketAccounts?.get(objTicket.Account__c)?.Name : '';
				objTask.Subject = TaskUtil.TASK_SUBJECT_REQUESTED + strAccountName;
				objTask.RecordTypeId = TaskUtil.TASK_STANDARD_RT_ID;
				objTask.OwnerId = objTicket.OwnerId;
				objTask.WhatId = objTicket.Id;
				list_taskToInsert.add(objTask);
			}
		}

		if (!list_taskToInsert.isEmpty()) {
			insert list_taskToInsert;
		}
	}

	/**
	 * @author	Swati Arya
	 * @description Assign the Priority and Risk Fields
	 * @param objTicket Ticket Record
	 * @param objOldTicket Old Ticket Record
	 */
	private void stampPriorityAndRiskFields(Ticket__c objTicket, Ticket__c objOldTicket) {
		if (objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_COMPANY_ONBOARDING || objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_GENERAL_RISK) {
			objTicket.Priority__c = TicketUtil.TICKET_PRIORITY_HIGH;
		} else if (objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_EXPEDITED_PAYROLL) {
			objTicket.Priority__c = TicketUtil.TICKET_PRIORITY_MEDIUM;
		}

		if (objOldTicket != null) {
			if (
				objTicket.Status__c == TicketUtil.TICKET_STATUS_INPROGRESS &&
				objOldTicket.Status__c == TicketUtil.TICKET_STATUS_NEW &&
				objTicket.Status__c != objOldTicket.Status__c &&
				(objTicket.RecordTypeId == TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID ||
				objTicket.RecordTypeId == TicketUtil.RISK_INVESTIGATION_TICKET_RT_ID ||
				objTicket.RecordTypeId == TicketUtil.SALES_ESCALATION_TICKET_RT_ID ||
				objTicket.RecordTypeId == TicketUtil.SOLUTION_ENGINEER_REQUEST_TICKET_RT_ID)
			) {
				objTicket.InProgress_Date_Time__c = System.now();
			}

			//Update In Review Date Time when SE ticket status is updated to In Review
			if (
				objTicket.Status__c == TicketUtil.TICKET_STATUS_REVIEW &&
				objTicket.Status__c != objOldTicket.Status__c &&
				objTicket.RecordTypeId == TicketUtil.SOLUTION_ENGINEER_REQUEST_TICKET_RT_ID &&
				objTicket.In_Review_Date_Time__c == null
			) {
				objTicket.In_Review_Date_Time__c = System.now();
			}

			//Update Resolved/Closed Date Time when SE ticket status is updated to Resolved or Closed
			if (
				(objTicket.Status__c == TicketUtil.TICKET_STATUS_RESOLVED ||
				objTicket.Status__c == TicketUtil.TICKET_STATUS_CLOSED) &&
				objTicket.Status__c != objOldTicket.Status__c &&
				objTicket.RecordTypeId == TicketUtil.SOLUTION_ENGINEER_REQUEST_TICKET_RT_ID &&
				objTicket.Resolved_Closed_Date_Time__c == null
			) {
				objTicket.Resolved_Closed_Date_Time__c = System.now();
			}

			if (objTicket.Status__c == TicketUtil.TICKET_STATUS_CLOSED && objTicket.Status__c != objOldTicket.Status__c) {
				objTicket.Closed_Date_Time__c = System.now();
				objTicket.Close_Date__c = System.today();
			}
			if (
				objTicket.Assigned_to_User_At__c == null &&
				objTicket.OwnerId != objOldTicket.OwnerId &&
				String.valueOf(objTicket.OwnerId).startsWith(TicketUtil.USER_PREFIX) &&
				String.valueOf(objOldTicket.OwnerId).startsWith(TicketUtil.GROUP_PREFIX) &&
				(objTicket.RecordTypeId == TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID ||
				objTicket.RecordTypeId == TicketUtil.RISK_INVESTIGATION_TICKET_RT_ID)
			) {
				objTicket.Assigned_to_User_At__c = System.now();
			}
		}
	}

	/**
	 * @description	Reset Unresponsive flag & Communication Status If Ticket status changes
	 * Expected to be called from before-update event
	 * @author Ajay Krishna P U
	 * @param list_NewTickets New version of Tickets
	 * @param map_OldTickets  Old version of Tickets
	 */
	private void resetUnResponsiveFlag(List<Ticket__c> list_NewTickets, Map<Id, Ticket__c> map_OldTickets) {
		if (map_OldTickets == null) {
			return;
		}

		for (Ticket__c objTicket : list_NewTickets) {
			//If Not an Ardius Ticket or No Status change => Skip
			if (objTicket.RecordTypeId != TicketUtil.ARDIUS_TICKET_RT_ID || objTicket.Status__c == map_OldTickets.get(objTicket.Id).Status__c) {
				continue;
			}

			//Marked Ticket as Unresposive and not changed and Status changes & Status != LOST => Unresponsive = false
			if (objTicket.Unresponsive__c && objTicket.Unresponsive__c == map_OldTickets.get(objTicket.Id).Unresponsive__c && objTicket.Status__c != TicketUtil.TICKET_STATUS_LOST) {
				objTicket.Unresponsive__c = false;
			}

			//Marked Ticket as closed or Lost => Communication_Status__c = NULL
			if (objTicket.Status__c == TicketUtil.TICKET_STATUS_CLOSED || objTicket.Status__c == TicketUtil.TICKET_STATUS_LOST) {
				objTicket.Communication_Status__c = null;
			}
		}
	}

	/**
	 * @description	Auto close auto generated tasks When Ticket Status Changes
	 * Task_Template_Identifier__c is Ticket Status + additional values.
	 * NOTE: The function is intended to be called only from AFTER_UPDATE Event.
	 * @author Ajay Krishna P U
	 * @param list_NewTickets New version of Tickets
	 * @param map_OldTickets  Old version of Tickets
	 */
	private void autoCloseGeneratedTasks(List<Ticket__c> list_NewTickets, Map<Id, Ticket__c> map_OldTickets) {
		Set<Id> set_TicketIdsToProcess = new Set<Id>();
		Set<Id> set_TicketIdsDisqualified = new Set<Id>();
		Set<Id> set_TicketIdsLost = new Set<Id>();

		for (Ticket__c objTicket : list_NewTickets) {
			//Process only If Ardius Tickets
			if (objTicket.RecordTypeId != TicketUtil.ARDIUS_TICKET_RT_ID) {
				continue;
			}

			Ticket__c objOldTicket = map_OldTickets?.get(objTicket.Id);
			if (objOldTicket == null) {
				continue;
			}

			//Check Task Template identifier Changes =  Status Changes
			if (
				objTicket.Task_Template_Identifier__c != objOldTicket.Task_Template_Identifier__c &&
				objOldTicket.Task_Template_Identifier__c != TicketUtil.TICKET_STATUS_LOST &&
				objTicket.Task_Template_Identifier__c != TicketUtil.TICKET_STATUS_LOST
			) {
				set_TicketIdsToProcess.add(objTicket.Id);
			}

			//Check If Ticket is moved to Lost
			if (objTicket.Task_Template_Identifier__c == TicketUtil.TICKET_STATUS_LOST && objOldTicket.Task_Template_Identifier__c != objTicket.Task_Template_Identifier__c) {
				set_TicketIdsLost.add(objTicket.Id);
				set_TicketIdsToProcess.add(objTicket.Id);
			}
		}

		if (set_TicketIdsToProcess.isEmpty()) {
			return;
		}

		//Task Status to `Completed`
		List<Task> list_TasksToUpdate = new List<Task>();
		for (Task objTask : [
			SELECT Id, Status, Feature_Request__c, WhatId
			FROM Task
			WHERE WhatId IN :set_TicketIdsToProcess AND Feature_Request__c != NULL AND Status != :TaskUtil.TASK_STATUS_COMPLETE
		]) {
			if (set_TicketIdsLost.contains(objTask.WhatId)) {
				//If Ticket is lost then Cancel all open Tasks
				list_TasksToUpdate.add(new Task(Id = objTask.Id, Status = TaskUtil.TASK_STATUS_COMPLETE, Canceled_CP__c = true));
				continue;
			} else {
				//Else auto close Tasks
				list_TasksToUpdate.add(new Task(Id = objTask.Id, Status = TaskUtil.TASK_STATUS_COMPLETE));
			}
		}

		update list_TasksToUpdate;
	}

	/* @author      Deepika Saini
	 * @description Update Fields on Case when Ticket is Created when flow criteria match
	 * @param       List of Recertification Tickets
	 * @return      NA
	 **/
	@InvocableMethod(label='Recertification Ticket Update Case' description='Update case when criteria match.')
	public static void updateBusinessDaysOnCase(List<Id> list_CaseIds) {
		if (list_CaseIds.isEmpty() || list_CaseIds.size() == 0) {
			return;
		} else {
			List<Case> list_Cases = new List<Case>();
			for (Case objCase : [SELECT Id, RFI_3rd_Business_Day__c, RFI_6th_Business_Day__c, Automated_RFI_Flow__c FROM Case WHERE Id IN :list_CaseIds]) {
				objCase.Automated_RFI_Flow__c = true;
				Integer intCount = 1;
				Date dtToday = System.today();
				// BBO-1076 - Ignoring Weekend and Holidays in the Flow
				objCase.RFI_3rd_Business_Day__c = dtToday.addDays(3);
				objCase.RFI_6th_Business_Day__c = dtToday.addDays(6);
				list_Cases.add(objCase);
			}

			if (!list_Cases.isEmpty()) {
				Boolean blnSkipTrigger = CaseTriggerHelper.SkipTrigger;
				CaseTriggerHelper.SkipTrigger = true;
				update list_Cases;
				CaseTriggerHelper.SkipTrigger = blnSkipTrigger;
			}
		}
	}

	/* @author      Soujanya NJ
	 * @description Update case for Engagement Ticket created against the case
	 * @param       NA
	 * @return      NA
	 **/
	public void updateCaseForTicketInsert() {
		List<Case> list_CasesToUpdate = new List<Case>();

		for (Case objCase : list_TicketCases) {
			Ticket__c objTicket = map_TicketByCaseIds.get(objCase.Id);
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT) {
				objCase.Status = CaseUtils.STATUS_AWAITING_INTERNAL_SUPPORT;
				objCase.Internal_Support_Requested_From__c = objTicket.Team__c;
				list_CasesToUpdate.add(objCase);
			}
		}

		try {
			Database.update(list_CasesToUpdate, false);
		} catch (Exception e) {
			ExceptionLogUtil.logException('TicketTriggerHelper', 'updateCaseForTicketInsert', e.getMessage(), e.getStackTraceString());
		}
	}

	/* @author      Soujanya NJ
	 * @description Update case for Engagement Ticket updated against the case
	 * @param       NA
	 * @return      NA
	 **/
	private static void updateCaseForTicketUpdate() {
		List<Case> list_CasesToUpdate = new List<Case>();

		for (Case objCase : list_TicketCases) {
			Ticket__c objTicket = map_TicketByCaseIds.get(objCase.Id);
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && TicketUtil.set_StatusDone.contains(objTicket.status__c)) {
				objCase.Status = CaseUtils.STATUS_IN_PROGRESS;
				list_CasesToUpdate.add(objCase);
			}
		}

		try {
			Database.update(list_CasesToUpdate, false);
		} catch (Exception e) {
			ExceptionLogUtil.logException('TicketTriggerHelper', 'updateCaseForTicketUpdate', e.getMessage(), e.getStackTraceString());
		}
	}

	/**
	 * @author Ajay Krishna P U
	 * @description	Identify Ardius Custom routing Tickets and add in to tracker for processing.
	 * @param objNewTicket New version of Ticket
	 * @param objOldTicket Old version of Ticket,  Can be Null
	 */
	private void addToArdiusCustomRoutingTracker(Ticket__c objNewTicket, Ticket__c objOldTicket) {
		if (
			objNewTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID &&
			objNewTicket.Account__c != null &&
			objNewTicket.Qualification_Status__c == TicketUtil.QUALIFICATION_STATUS_QUALIFIED &&
			(objOldTicket == null ||
			(String.valueOf(objNewTicket.OwnerId).startsWithIgnoreCase(TicketUtil.GROUP_PREFIX) && objNewTicket.Qualification_Status__c != objOldTicket.Qualification_Status__c) ||
			(objNewTicket.Re_route__c && objNewTicket.Re_route__c != objOldTicket.Re_route__c))
		) {
			//Either Opp. Type ='Existing Business' or Have Control group
			if (objNewTicket.Opportunity_Type__c == OpportunityUtil.OPPTY_TYPE_EXISTING_BUSINESS || String.isNotBlank(objNewTicket.Control_Group__c)) {
				list_ArdiusCustomRoutingTickets.add(objNewTicket);
			}
		}
	}

	/**
	 * @author Ajay Krishna P U
	 * @description Route Ardius Tickets using Custom routing logic
	 * If Opportunity_Type = Existing ==> Assign Prior Ticket Owner
	 * If Control_Group != null ==> Assign Prior Ticket Owner
	 */
	private void routeThroughArdiusCustomRouting() {
		if (list_ArdiusCustomRoutingTickets.isEmpty()) {
			return;
		}

		//Prepare set for queries
		Set<Id> set_TicketIds = new Set<Id>();
		Set<Id> set_AccountIds = new Set<Id>();
		Set<String> set_ControlGroups = new Set<String>();
		for (Ticket__c objTicket : list_ArdiusCustomRoutingTickets) {
			set_TicketIds.add(objTicket.Id);
			set_AccountIds.add(objTicket.Account__c);
			set_ControlGroups.add(objTicket.Control_Group__c);
		}

		//Remove if any null value
		set_TicketIds.remove(null);
		set_AccountIds.remove(null);
		set_ControlGroups.remove(null);

		//Do query and segregate by latest prior ticket
		Map<Id, CustomRoutingAccountInfo> map_AccountIdToRoutingInfo = new Map<Id, CustomRoutingAccountInfo>();
		for (Account objAccount : [
			SELECT
				Id,
				(
					SELECT Id, Control_Group__c, Opportunity_Type__c, OwnerId
					FROM Tickets__r
					WHERE
						(Opportunity_Type__c = :OpportunityUtil.OPPTY_TYPE_EXISTING_BUSINESS
						OR Control_Group__c IN :set_ControlGroups)
						AND Id NOT IN :set_TicketIds
						AND RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID
					ORDER BY LastModifiedDate DESC
				)
			FROM Account
			WHERE Id IN :set_AccountIds
		]) {
			map_AccountIdToRoutingInfo.put(objAccount.Id, new CustomRoutingAccountInfo(objAccount.Tickets__r));
		}

		//Route Ardius Ticket to Prior Ticket owner
		for (Ticket__c objTicket : list_ArdiusCustomRoutingTickets) {
			CustomRoutingAccountInfo objInfo = map_AccountIdToRoutingInfo.get(objTicket.Account__c);
			if (objInfo == null) {
				continue;
			}

			Id idRoutedTo = null;
			if (String.isNotBlank(objTicket.Control_Group__c) && objInfo.map_ControlGroupToPriorTicket.containsKey(objTicket.Control_Group__c)) {
				idRoutedTo = objInfo.map_ControlGroupToPriorTicket.get(objTicket.Control_Group__c).OwnerId;
			}

			if (objTicket.Opportunity_Type__c == OpportunityUtil.OPPTY_TYPE_EXISTING_BUSINESS && objInfo.objExistingBusinessPriorTicket != null) {
				idRoutedTo = objInfo.objExistingBusinessPriorTicket.OwnerId;
			}

			if (idRoutedTo != null) {
				objTicket.OwnerId = idRoutedTo;
				objTicket.Block_Ring_Lead_Routing__c = true;
				objTicket.Re_route__c = false;
			}
		}
	}

	/**
	 * @description	Query Tasks based on What Ids
	 * @author	Ajay Krishna P U
	 * @param set_WhatIds The set of WhatIds to query Tasks
	 * @return            `List<Task>`
	 */
	private static List<Task> queryTasks(Set<Id> set_WhatIds, Set<String> set_Statuses, Set<Id> set_RecordTypeIds) {
		return [
			SELECT Id, OwnerId, WhatId, Feature_Request__c, Status
			FROM Task
			WHERE WhatId IN :set_WhatIds AND Status IN :set_Statuses AND RecordTypeId IN :set_RecordTypeIds
		];
	}

	/**
	 * @description	Check if Id value is a Group
	 * @author Ajay Krishna P U
	 * @param objTicket The ticket Object
	 * @return          `Boolean`
	 */
	private Boolean checkIfIdIsGroup(Id idValue) {
		return idValue != null && String.valueOf(idValue).startsWithIgnoreCase(TicketUtil.GROUP_PREFIX);
	}

	/**
	 * @description	Change related Task owner as Ticket owner
	 * @author Ajay Krishna P U
	 * @param map_NewTickets New version of Tasks
	 */
	private void assignArdiusTicketOwnerToTaskOwner(Map<Id, Ticket__c> map_NewTickets) {
		//No Data to process then return
		if (set_ArdiusOwnerChangeTicketIds.isEmpty() || map_Tasks.isEmpty()) {
			return;
		}

		List<Task> list_TaskToUpdate = new List<Task>();
		for (Task objTask : map_Tasks.values()) {
			if (
				objTask.WhatId != null &&
				set_ArdiusOwnerChangeTicketIds.contains(objTask.WhatId) &&
				objTask.Status == TaskUtil.TASK_STATUS_OPEN
			) {
				objTask.OwnerId = map_NewTickets.get(objTask.WhatId).OwnerId;
				list_TaskToUpdate.add(objTask);
			}
		}

		if (!list_TaskToUpdate.isEmpty()) {
			update list_TaskToUpdate;
		}

	}

	/**
	 * Custom Routing Wrapper stores the latest prior ticket of type
	 * with either Existing business or Control group
	 */
	class CustomRoutingAccountInfo {
		Map<String, Ticket__c> map_ControlGroupToPriorTicket = new Map<String, Ticket__c>();
		Ticket__c objExistingBusinessPriorTicket;

		CustomRoutingAccountInfo(List<Ticket__c> list_Tickets) {
			for (Ticket__c objTicket : list_Tickets) {
				if (objExistingBusinessPriorTicket == null && objTicket.Opportunity_Type__c == OpportunityUtil.OPPTY_TYPE_EXISTING_BUSINESS) {
					objExistingBusinessPriorTicket = objTicket;
				}

				if (String.isNotBlank(objTicket.Control_Group__c) && !this.map_ControlGroupToPriorTicket.containsKey(objTicket.Control_Group__c)) {
					this.map_ControlGroupToPriorTicket.put(objTicket.Control_Group__c, objTicket);
				}
			}
		}
	}

	/* @author      Yogesh Kherjani
	 * @description Handle ticket owner change
	 * @param       list_NewTickets - List of new Tickets
	 * 				map_OldTickets - Old List of Tickets
	 * @return      NA
	 **/
	public static void handleTicketOwnerChange(List<Ticket__c> list_NewTickets, Map<Id, Ticket__c> map_OldTickets) {
		Map<Id, List<Ticket__c>> map_UserTicketMap = new Map<Id, List<Ticket__c>>();

		for (Ticket__c objTicket : list_NewTickets) {
			if (map_OldTickets == null || (objTicket.OwnerId != map_OldTickets.get(objTicket.Id).OwnerId)) {
				if (map_UserTicketMap.containsKey(objTicket.OwnerId)) {
					map_UserTicketMap.get(objTicket.OwnerId).add(objTicket);
				} else {
					map_UserTicketMap.put(objTicket.OwnerId, new List<Ticket__c>{ objTicket });
				}
			}
		}

		Set<Id> set_BenefitsComplianceUserIds = GlobalQueryHelper.getBenefitsComplianceUserMap(map_UserTicketMap.keySet()).keySet();

		for (Id idBenefeitsComplianceUserId : set_BenefitsComplianceUserIds) {
			if (map_UserTicketMap.containsKey(idBenefeitsComplianceUserId)) {
				for (Ticket__c objTicket : map_UserTicketMap.get(idBenefeitsComplianceUserId)) {
					objTicket.Is_Ticket_Owner_Benefits_Compliance__c = true;
				}
			}
		}
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method update Ticket_Action_Required__c field on Carrier Order with respect to ticket.
	 *               If ticket is open & ticket owner and Carrier order owner are same.
	 *               Then Ticket_Action_Required__c become true. Else False.
	 * @param        List of new Ticket__c
	 *               Map of old Tikcet__c
	 * @return       Void
	 **/
	public static void updateCarrierOrder(List<Ticket__c> list_objTickets, Map<Id, Ticket__c> map_oldTickets) {
		try {
			Set<Id> set_COIds = new Set<Id>();
			String strClosedStatus = TicketUtil.TICKET_STATUS_CLOSED;
			for (Ticket__c objTicket : list_objTickets) {
				Ticket__c objOldTicket = null;
				if (map_oldTickets != null && map_oldTickets?.containsKey(objTicket.Id)) {
					objOldTicket = map_oldTickets?.get(objTicket.Id);
				}

				if (objTicket.Carrier_Order__c != null && (objOldTicket == null || (objTicket.OwnerId != objOldTicket.OwnerId || objTicket.Status__c != objOldTicket.Status__c))) {
					set_COIds.add(objTicket.Carrier_Order__c);
				}
			}

			if (set_COIds.size() > 0) {
				List<Carrier_Order__c> list_COs = new List<Carrier_Order__c>();
				Boolean blnNoTicketForCOOwner = true;
				for (Carrier_Order__c objCO : [
					SELECT Id, OwnerId, Ticket_Action_Required__c, (SELECT Id, OwnerId FROM Tickets__r WHERE Status__c != :strClosedStatus)
					FROM Carrier_Order__c
					WHERE Id IN :set_COIds
				]) {
					blnNoTicketForCOOwner = true;
					if (objCO.Tickets__r?.size() > 0) {
						for (Ticket__c objTicket : objCO.Tickets__r) {
							if (objTicket.OwnerId == objCO.OwnerId) {
								blnNoTicketForCOOwner = false;
								if (!objCO.Ticket_Action_Required__c) {
									objCO.Ticket_Action_Required__c = true;
									list_COs.add(objCO);
								}
							}
						}
					}

					if (objCO.Ticket_Action_Required__c && blnNoTicketForCOOwner) {
						objCO.Ticket_Action_Required__c = false;
						list_COs.add(objCO);
					}
				}

				if (list_COs.size() > 0) {
					CarrierOrderTriggerHelper.skipTrigger = true;
					update list_COs;
					CarrierOrderTriggerHelper.skipTrigger = false;
				}
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('TicketTriggerHelper', 'updateCarrierOrder', objExp.getMessage(), objExp.getStackTraceString());
		}
	}

	/**
	 * @description Update opportunity to closed won or new
	 * @author Ajay Krishna P U
	 * @since 2024-11-13
	 */
	private void updateRelatedOpportunity() {
		if (set_OpptyIdsToClosedWon.isEmpty() && set_OpptyIdsToReOpen.isEmpty() && list_ArdiusStatusChangedTickets.isEmpty()) {
			return;
		}

		Map<Id, Opportunity> map_OpportunitiesToUpdate = new Map<Id, Opportunity>();
		for (Id idOppty : set_OpptyIdsToClosedWon) {
			map_OpportunitiesToUpdate.put(idOppty, new Opportunity(Id = idOppty, StageName = OpportunityUtil.CLOSED_WON_STAGE));
		}

		//Reopen opportunity if ticket is created or related ticket status changed from 'lost' to any other open status
		for (Id idOppty : set_OpptyIdsToReOpen) {
			if (map_OpportunitiesToUpdate.containsKey(idOppty)) {
				map_OpportunitiesToUpdate.get(idOppty).StageName = OpportunityUtil.NEW_STAGE;
			} else {
				map_OpportunitiesToUpdate.put(idOppty, new Opportunity(Id = idOppty, StageName = OpportunityUtil.NEW_STAGE));
			}
		}

		//Update related Ticket Status on Opportunity
		for (Ticket__c objTicket : list_ArdiusStatusChangedTickets) {
			if (map_OpportunitiesToUpdate.containsKey(objTicket.Opportunity__c)) {
				map_OpportunitiesToUpdate.get(objTicket.Opportunity__c).Ticket_Status__c = objTicket.Status__c;
			} else {
				map_OpportunitiesToUpdate.put(objTicket.Opportunity__c, new Opportunity(Id = objTicket.Opportunity__c, Ticket_Status__c = objTicket.Status__c));
			}
		}

		try {
			if (!map_OpportunitiesToUpdate.isEmpty()) {
				OpportunityTriggerHelper.skipTrigger = true;
				update map_OpportunitiesToUpdate.values();
				OpportunityTriggerHelper.skipTrigger = false;
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('TicketTriggerHelper', 'updateOpportunityToClosedWon', objExp.getMessage(), objExp.getStackTraceString());
		}
		set_OpptyIdsToClosedWon.clear();
		set_OpptyIdsToReOpen.clear();
		list_ArdiusStatusChangedTickets.clear();
	}

	/**
	 * @description Update Opportunity Closed Lost on Ardius Ticket Status Change to Lost
	 * @author Jayesh Gawande
	 * @since 2024-11-18
	 */
	private void updateOpportunityToClosedLost(Map<ID, Ticket__c> map_newTickets) {
		if (set_OpptyIdsToClosedLost.isEmpty()) {
			return;
		}

		Map<Id, Opportunity> map_OpportunitiesToUpdateToCL = new Map<Id, Opportunity>(
			[
				SELECT Id, StageName, Stage_Detail__c, Stage_Detail_2__c
				FROM Opportunity
				WHERE Id IN :set_OpptyIdsToClosedLost
			]
		);

		for (Ticket__c rec_Ticket : map_newTickets.values()) {
			Opportunity rec_Oppty = map_OpportunitiesToUpdateToCL.get(rec_Ticket.Opportunity__c);
			if (rec_Oppty != null) {
				rec_Oppty.Stage_Detail__c = rec_Ticket.Lost_Detail__c;
				rec_Oppty.Stage_Detail_2__c = rec_Ticket.Lost_Detail2__c;
				rec_Oppty.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
			}
		}

		try {
			if (map_OpportunitiesToUpdateToCL.size() > 0 && !map_OpportunitiesToUpdateToCL.isEmpty()) {
				OpportunityTriggerHelper.skipTrigger = true;
				update map_OpportunitiesToUpdateToCL.values();
				OpportunityTriggerHelper.skipTrigger = false;
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('TicketTriggerHelper', 'updateOpportunityToClosedLost', objExp.getMessage(), objExp.getStackTraceString());
		}
		set_OpptyIdsToClosedLost.clear();
	}
}