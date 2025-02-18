public class OrderTriggerHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	public static boolean isPayrollTransferAutoAssignment = false;
	public static boolean autoAssignedGlobal = false;
	public static final Id idOrder_RT_CompanyMigration = Cache.getRecordTypeId('Order', 'Company Migration');
	public static final Id idFBOSForecast_RT_Advocate = cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate');
	public static final Id idFBOSForecast_RT_Facilitator = cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Facilitator');
	public static final Id idOpportunity_RT_Company = cache.getRecordTypeId('Opportunity', 'Company Opportunity');
	public static final Id idAcquisitionRecordType = cache.getRecordTypeId('Opportunity', 'Acquisition');
	public static final Id idCase_RT_PTCase = cache.getRecordTypeId('Case', 'Payroll Transfer Case');
	public static BusinessHours objBusinessHour = GlobalQueryHelper.getDefaultBusinessHour();
	//BY:PR, Date: Desc-7-2020, Desc: constant which we can use to calculate Due Date
	public static Integer intFacilitatorDueDateDaysFromPayrollRunDate = Utils.ORG_WIDE_CONFIG_SETTINGS?.PT_Facilitation_SLA__c != null
		? Integer.valueOf(Utils.ORG_WIDE_CONFIG_SETTINGS.PT_Facilitation_SLA__c)
		: -3;
	public static Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults() != null ? Tier_Config__c.getOrgDefaults() : new Tier_Config__c();

	static final String ERROR_MESSAGE_MISSING_CONTACT_ACCOUNT = 'Contact/Account is missing from the Case.';
	static final String ORDER_STATUS_CLOSEDPAYROLLRUN = 'Closed: Payroll Run';
	static final String ORDER_STATUS_CLOSEDCANCELED = 'Closed: Canceled';
	static final String ORDER_STATUS_READYFORFACILITATOR = 'Ready for Facilitator';
	static final String CASE_ORIGIN_PANDA = 'Panda';
	static final String CASE_ORIGIN_GUSTO = 'Gusto';
	static final String CASE_ORIGIN_EMAIL = 'Email';
	static final String TTF_STATUS_PTAPPROVED = 'PT Approved';
	static final String PREVIOUS_PAYROLL_PROVIDER_ADP_RUN = 'ADP Run';
	static final String INTRO_EMAIL_ADP_RUN = 'Intro Email - ADP Run';
	static final String USER_PREFIX = '005';
	static final String GROUP_PREFIX = '00G';
	static final String BIG_DESK_100PLUS = 'Big Desk 100+';
	static final String PT_FACILITATOR_ASSIGNMENT_REASON_BMR_FACILITATOR = 'BMR Facilitator';
	static final String BIGDESK_FIELD_VALUE = 'Big Desk 100+';
	static final Set<String> set_PayrollRunEmailEligibleStatuses = new Set<String>{ 'Account Approved', 'Onboarding Step 10', 'Onboarding Steps 8 - 9', 'Ready for Approval' };
	static final String ACCOUNT_TIER_CONCIERGE = objTierConfig.Old_Tier_3__c; // Old Tier 3
	static final String ACCOUNT_TIER_SELECT = objTierConfig.Old_Tier_4__c; // Old Tier 4
	static final String ACCOUNT_TIER_PLUS = objTierConfig.New_Tier_2__c; // New Tier 2
	static final String ACCOUNT_TIER_PREMIUM = objTierConfig.New_Tier_3__c; // New Tier 3

	public OrderTriggerHelper() {
		super('OrderTriggerHelper');
	}

	public override void beforeInsert() {
		List<Order> orders = (List<Order>) Trigger.new;

		updateTransitionToFulfillmentOnOrder(orders);

		list<Order> lst_OrderWithAccount = new List<Order>(); //WF: Reference account field values
		set<id> set_OrderAccountId = new Set<id>(); //WF: Reference account field values

		//WF:Company Migration : Assign orders to Unassigned Queue
		//WF: Company Migration : Assign orders to Xero Migration Queue
		Id migrationUnAssignedOrdersQueueId;
		Id migrationUnassignedXeroOrderId;

		list<Order> lst_bmrOrders = new List<Order>();
		set<Id> set_relatedBMRIds = new Set<ID>();
		list<Order> lst_BMRAssignedUpdatedOrders = new List<Order>();

		list<Order> lst_rundDateCalculationOrders = new List<Order>();

		for (Group queueRec : [SELECT id, Name FROM GROUP WHERE Type = 'Queue' AND (Name = 'Company Migration - Unassigned Orders' OR Name = 'Migration - Unassigned Xero Orders')]) {
			if (queueRec.Name == 'Company Migration - Unassigned Orders') {
				migrationUnAssignedOrdersQueueId = queueRec.id;
			}

			if (queueRec.Name == 'Migration - Unassigned Xero Orders') {
				migrationUnassignedXeroOrderId = queueRec.id;
			}
		}

		Id companyMigrationRecordTypeID = idOrder_RT_CompanyMigration;

		for (Order orderObj : orders) {
			//ND, 27 Nov 2019, Set Facilitator Assigned timestamp
			if (null != orderObj.Data_Entry_Assist__c) {
				orderObj.Facilitator_Assigned_DateTime__c = system.now();
			}
			if (orderObj.Active_Employee_Count__c == null) {
				orderObj.Active_Employee_Count__c = 0;
			}
			if (orderObj.Inactive_Employee_Count__c == null) {
				orderObj.Inactive_Employee_Count__c = 0;
			}
			if (orderObj.Contractor_Count__c == null) {
				orderObj.Contractor_Count__c = 0;
			}

			if (orderObj.AccountId != null) {
				//WF: Reference account field values
				lst_OrderWithAccount.add(orderObj);
				set_OrderAccountId.add(orderObj.AccountId);
			}

			//wf:Company Migration : Assign orders to Unassigned Queue
			if (orderObj.RecordTypeId == companyMigrationRecordTypeID && string.isBlank(orderObj.Xero_Migration_Selection__c)) {
				//assigning owner id to 'Company Migration - Unassigned' Orders queue
				if (migrationUnAssignedOrdersQueueId != null) {
					orderObj.OwnerId = migrationUnAssignedOrdersQueueId;
				}
			}

			//WF: Company Migration : Assign orders to Xero Migration Queue
			if (orderObj.RecordTypeId == companyMigrationRecordTypeID && string.isNotBlank(orderObj.Xero_Migration_Selection__c)) {
				//assigning owner id to 'Company Migration - Unassigned' Orders queue
				if (migrationUnassignedXeroOrderId != null) {
					orderObj.OwnerId = migrationUnassignedXeroOrderId;
				}
			}

			if (orderObj.First_Check_Date__c != null) {
				// run date based on opp owner role
				lst_rundDateCalculationOrders.add(orderObj);
			}

			//sync BMR and Order owner is order is manually created logic
			if (orderObj.Bulk_Migration__c != null) {
				lst_bmrOrders.add(orderObj);
				set_relatedBMRIds.add(orderObj.Bulk_Migration__c);
			}

			// Logic to sync Order BMR with the related Opportunity and Account. We want to cover both assignment and disassociation of BMR on order
			if (orderObj.bulk_migration__c != null && (orderObj.OpportunityId != null || orderObj.AccountId != null)) {
				lst_BMRAssignedUpdatedOrders.add(orderObj);
			}

			reCalculateBigDeskFieldValue(orderObj, null);

			if (orderObj.Ready_For_Facilitator_Due_Date__c == null && orderObj.Facilitator_Due_Date__c != null) {
				setReadyForFacilitatorDueDate(orderObj);
			}
		}

		//WF: Reference account field values
		if (lst_OrderWithAccount.size() > 0) {
			syncOrderAccountAddress(lst_OrderWithAccount, set_OrderAccountId);
		}

		if (lst_bmrOrders.size() > 0) {
			updateSynOrderAndBMROwners(lst_bmrOrders, set_relatedBMRIds);
		}

		//run date calculating logic
		if (lst_rundDateCalculationOrders.size() > 0) {
			updateRunDate(lst_rundDateCalculationOrders);
		}

		if (lst_BMRAssignedUpdatedOrders.size() > 0) {
			updateBMRonRelatedOpportunityAndAccount(lst_BMRAssignedUpdatedOrders);
		}

		//By: Neha 31 Oct 2019, To Update Original Check date for the first time
		setOriginalCheckDateAndCalculatePayDateFields(orders, null);

		calculateComplexityScoring(orders, null);
		//31 Dec, 2021, Update Week Number when First Check Dates is changed
		for (Order newOrderObj : orders) {
			if (newOrderObj.First_Check_Date__c != null) {
				calcWeekNumberForFirstCheckDate(newOrderObj);
			}
		}
	}

	public override void afterInsert() {
		List<Order> orders = (List<Order>) Trigger.new;
		List<Order> lst_ManuallyAssignedPTOrders = new List<Order>();
		List<Order> lst_ManuallyAssignedFacilitatorPTOrders = new List<Order>(); //for facilitator
		//for Submit TTF Notification
		List<Order> list_submitTTFNotificationEligibleOrders = new List<Order>();
		string companyMigrationRecordTypeId = idOrder_RT_CompanyMigration;

		populateOrderOnMatchingOpportunities(orders, null);
		Set<Id> setBulkMigrationId = new Set<Id>();
		for (Order orderObj : orders) {
			if (orderObj.Bulk_Migration__c != null) {
				setBulkMigrationId.add(orderObj.Bulk_Migration__c);
			}

			if (orderObj.RecordTypeId == companyMigrationRecordTypeId) {
				if (orderObj.OwnerId != null && string.valueOf(orderObj.OwnerId).startsWith('005') && orderObj.Bulk_Migration__c != null) {
					lst_ManuallyAssignedPTOrders.add(orderObj);
				}

				if (orderObj.Data_Entry_Assist__c != null) {
					lst_ManuallyAssignedFacilitatorPTOrders.add(orderObj);
				}
			}

			if (String.isNotBlank(orderObj.Migration_State__c) && orderObj.Migration_State__c == OrderUtils.BASICS_COMPLETED && orderObj.OpportunityId != null) {
				list_submitTTFNotificationEligibleOrders.add(orderObj);
			}
		}

		//BY: PR, Desc: manually assigned "payroll transfer" Order handling code
		if (lst_ManuallyAssignedPTOrders.size() > 0) {
			createOrderBOARelationForManuallyAssignedOrders(lst_ManuallyAssignedPTOrders);
		}

		if (lst_ManuallyAssignedFacilitatorPTOrders.size() > 0) {
			syncOrderBOARelationForManuallyAssignedFacilitatorOrders(lst_ManuallyAssignedFacilitatorPTOrders);
		}

		//Update Bulk Migration
		if (setBulkMigrationId != null && setBulkMigrationId.size() > 0) {
			UpdateOrderBulkMigrationRequest(setBulkMigrationId);
		}

		//send Submit TTF notification email
		if (list_submitTTFNotificationEligibleOrders.size() > 0) {
			sendSubmitTTFNotification(list_submitTTFNotificationEligibleOrders);
		}
	}

	public override void beforeUpdate() {
		Map<Id, Order> oldOrderMap = (Map<Id, Order>) Trigger.oldMap;
		Map<Id, Order> newOrderMap = (Map<Id, Order>) Trigger.newMap;

		calculateOrderSLAUpdate(oldOrderMap, newOrderMap.values());
		updateRelatedCase(oldOrderMap, newOrderMap.values());
		updateTransitionToFulfillmentOnOrder(newOrderMap.values());

		list<Order> lst_OrderWithUpdatedAccount = new List<Order>(); //WF: Reference account field values
		set<id> set_OrderAccountId = new Set<id>(); //WF: Reference account field values
		list<Order> lst_rundDateCalculationOrders = new List<Order>(); //contains orders eligible for run date recalculation
		list<Order> lst_BMRAssignedUpdatedOrders = new List<Order>();
		list<Order> list_BMROrderFacilitatorSync = new List<Order>();

		String autoAssignedPayrollProviders = Label.Payroll_Transfer_Auto_Assigned_Providers; // to determine if an Order is auto Assigned or not

		for (Order newOrderObj : newOrderMap.values()) {
			Order oldOrderObj = oldOrderMap.get(newOrderObj.id);

			//ND, 2 Dec 2019, Set startDate(Effective Date) and End Date on Order
			Boolean isAutoAssigned = false; // to determine if an Order is auto Assigned or not

			//If previous payroll provider is one of those mentioned in label AND there is no BMR associated with Order, then it is auto assigned
			if (
				null != newOrderObj.Previous_Payroll_Provider__c &&
				String.isNotBlank(autoAssignedPayrollProviders) &&
				autoAssignedPayrollProviders.contains(newOrderObj.Previous_Payroll_Provider__c) &&
				newOrderObj.Bulk_Migration__c == null
			) {
				isAutoAssigned = true;
				autoAssignedGlobal = isAutoAssigned;
			}
			if (
				null == newOrderObj.EffectiveDate &&
				((isAutoAssigned && 'Collecting Documents'.equalsIgnoreCase(newOrderObj.Status) && newOrderObj.Status != oldOrderObj.Status) ||
				(!isAutoAssigned &&
				'Sales Submitted'.equalsIgnoreCase(newOrderObj.Status) &&
				newOrderObj.Status != oldOrderObj.Status))
			) {
				newOrderObj.EffectiveDate = system.today();
			}
			if ((ORDER_STATUS_CLOSEDPAYROLLRUN.equalsIgnoreCase(newOrderObj.Status) || ORDER_STATUS_CLOSEDCANCELED.equalsIgnoreCase(newOrderObj.Status)) && newOrderObj.Status != oldOrderObj.Status) {
				// Check current date is after Order Start Date
				// To avoid Order End Date can't be earlier than Order Start Date error
				if (System.today() >= newOrderObj.EffectiveDate) {
					newOrderObj.EndDate = System.today();
				}
			}
			//WF: Reference account field values
			if (newOrderObj.AccountId != null && newOrderObj.AccountId != oldOrderObj.AccountId) {
				lst_OrderWithUpdatedAccount.add(newOrderObj);
				set_OrderAccountId.add(newOrderObj.AccountId);
			}

			//WF: Update Order to Assigned
			if (newOrderObj.Status != oldOrderObj.Status && oldOrderObj.Status == 'Drafted' && newOrderObj.Status == 'Collecting Documents') {
				newOrderObj.Order_Assigned_Timestamp__c = System.now();
			}

			//WF: Change order status to assigned
			if (
				newOrderObj.OwnerId != oldOrderObj.OwnerId &&
				string.valueOf(oldOrderObj.OwnerId).startsWith('00G') &&
				string.valueOf(newOrderObj.OwnerId).startsWith('005') &&
				newOrderObj.Status == 'Drafted'
			) {
				newOrderObj.Status = 'Assigned';
			}

			//wf: Update Payroll Run Date 4 Day
			if (
				(newOrderObj.First_Check_Date__c != oldOrderObj.First_Check_Date__c || newOrderObj.Fast_ACH__c != oldOrderObj.Fast_ACH__c || newOrderObj.Payroll_Run_Date__c == null) &&
				newOrderObj.First_Check_Date__c != null
			) {
				lst_rundDateCalculationOrders.add(newOrderObj);
			} else if (newOrderObj.Payroll_Run_Date__c != null && newOrderObj.Payroll_Run_Date__c != oldOrderObj.Payroll_Run_Date__c) {
				//[BS: 10 Nov 2020] When Payroll_Run_Date__c manually changed by login user then Facilitator Due date will be recalculated.
				newOrderObj.Facilitator_Due_Date__c = Utils.getBusinessDayFromDate(newOrderObj.Payroll_Run_Date__c, intFacilitatorDueDateDaysFromPayrollRunDate);
			}

			if (newOrderObj.Status != oldOrderObj.status) {
				if (oldOrderObj.status == 'Assigned' && newOrderObj.Status != 'Drafted') {
					//WF: Update Order From Assigned
					newOrderObj.Time_Updated_from_Assigned__c = System.now();
				}

				if (newOrderObj.Status == ORDER_STATUS_CLOSEDPAYROLLRUN) {
					//WF: Update Closed: Payroll Run
					newOrderObj.Closed_Payroll_Run__c = System.today();
					newOrderObj.Assign_to_Advocate__c = false;
					newOrderObj.Assign_Facilitator__c = false;
				}

				if (newOrderObj.Status == ORDER_STATUS_CLOSEDCANCELED) {
					//WF: Update Closed: Cancelled
					newOrderObj.Closed_Canceled__c = System.today();
					newOrderObj.Assign_to_Advocate__c = false;
					newOrderObj.Assign_Facilitator__c = false;
				}
			}

			// Logic to sync Order BMR with the related Opportunity and Account. We want to cover both assignment and disassociation of BMR on order
			if (newOrderObj.Bulk_Migration__c != oldOrderObj.Bulk_Migration__c) {
				lst_BMRAssignedUpdatedOrders.add(newOrderObj);
			}

			//[BS: 23 Oct 2020] Populate Initial Facilitator field value.
			if (newOrderObj.Initial_Facilitator__c == null) {
				if (oldOrderObj.Data_Entry_Assist__c != null) {
					newOrderObj.Initial_Facilitator__c = oldOrderObj.Data_Entry_Assist__c;
				} else if (newOrderObj.Data_Entry_Assist__c != null) {
					newOrderObj.Initial_Facilitator__c = newOrderObj.Data_Entry_Assist__c;
				}
			}

			//[BS: 26 Oct 2020] Calculate "No Of Times Assign to Advocate".
			if (newOrderObj.Assign_to_Advocate__c != oldOrderObj.Assign_to_Advocate__c && newOrderObj.Assign_to_Advocate__c) {
				if (newOrderObj.No_Of_Times_Assign_to_Advocate__c == null) {
					newOrderObj.No_Of_Times_Assign_to_Advocate__c = 1;
				} else {
					newOrderObj.No_Of_Times_Assign_to_Advocate__c = newOrderObj.No_Of_Times_Assign_to_Advocate__c + 1;
				}
			}

			//[BS: 26 Oct 2020] Calculate "No Of Times Assign to Facilitator".
			if (newOrderObj.Assign_Facilitator__c != oldOrderObj.Assign_Facilitator__c && newOrderObj.Assign_Facilitator__c) {
				if (newOrderObj.No_Of_Times_Assign_to_Facilitator__c == null) {
					newOrderObj.No_Of_Times_Assign_to_Facilitator__c = 1;
				} else {
					newOrderObj.No_Of_Times_Assign_to_Facilitator__c = newOrderObj.No_Of_Times_Assign_to_Facilitator__c + 1;
				}
			}

			//[BS: 05 Nov 2020] Calculate "Facilitator Follow Up Date" change.
			if (newOrderObj.Facilitator_Follow_Up_Date__c != null && newOrderObj.Facilitator_Follow_Up_Date__c != oldOrderObj.Facilitator_Follow_Up_Date__c) {
				if (newOrderObj.No_Of_Times_Follow_Up_Date_Set__c == null) {
					newOrderObj.No_Of_Times_Follow_Up_Date_Set__c = 1;
				} else {
					newOrderObj.No_Of_Times_Follow_Up_Date_Set__c = newOrderObj.No_Of_Times_Follow_Up_Date_Set__c + 1;
				}
			}

			//[BS: 06 Nov 2020] populate "Last Assigned To Facilitator or Advocate Date/Time" change.
			if (newOrderObj.Assign_Facilitator__c == true && newOrderObj.Assign_Facilitator__c != oldOrderObj.Assign_Facilitator__c) {
				newOrderObj.Last_Assigned_To_Facilitator__c = Datetime.now();
			}
			if (newOrderObj.Assign_to_Advocate__c == true && newOrderObj.Assign_to_Advocate__c != oldOrderObj.Assign_to_Advocate__c) {
				newOrderObj.Last_Assigned_to_Advocate__c = Datetime.now();
			}

			//[BS: 11 Nov 2020] populate "Ready For Facilitator Assigned Timestamp" field value.
			if (newOrderObj.Ready_For_Facilitator_Assigned_Timestamp__c == null && newOrderObj.Assign_Facilitator__c) {
				newOrderObj.Ready_For_Facilitator_Assigned_Timestamp__c = Datetime.now();
			}

			//[BS: 26 Oct 2020] populate "Checklist Status" value.
			if (newOrderObj.Checklist_Completed__c) {
				newOrderObj.Checklist_Status__c = 'Checklists Completed';
			} else if (!newOrderObj.Checklist_Completed__c && newOrderObj.Assign_Facilitator__c) {
				newOrderObj.Checklist_Status__c = ORDER_STATUS_READYFORFACILITATOR;
			} else if (newOrderObj.Data_Entry_Assist__c != null && !newOrderObj.Checklist_Completed__c && newOrderObj.Assign_to_Advocate__c) {
				newOrderObj.Checklist_Status__c = 'With Advocate';
			} else if (newOrderObj.Data_Entry_Assist__c != null && !newOrderObj.Checklist_Completed__c && !newOrderObj.Assign_Facilitator__c && !newOrderObj.Assign_to_Advocate__c) {
				newOrderObj.Checklist_Status__c = 'With Facilitator';
			}

			if (
				newOrderObj.Checklist_Status__c == ORDER_STATUS_READYFORFACILITATOR &&
				newOrderObj.RecordTypeId == idOrder_RT_CompanyMigration &&
				newOrderObj.Bulk_Migration__c != null &&
				newOrderObj.Data_Entry_Assist__c == null
			) {
				list_BMROrderFacilitatorSync.add(newOrderObj);
			}

			reCalculateBigDeskFieldValue(newOrderObj, oldOrderObj);

			if (
				(newOrderObj.Ready_For_Facilitator_Due_Date__c == null &&
				newOrderObj.Facilitator_Due_Date__c != null) ||
				newOrderObj.Facilitator_Due_Date__c != oldOrderObj.Facilitator_Due_Date__c ||
				newOrderObj.Big_Desk_Sandbox_Type__c != oldOrderObj.Big_Desk_Sandbox_Type__c
			) {
				setReadyForFacilitatorDueDate(newOrderObj);
			}
		}

		//BY:PR, Date:Dec-9-2020, desc: Moved down to let the checklist_status run before calling this method
		updateStageChangeDateTime(oldOrderMap, newOrderMap.values()); // Rahul Joshi, BT-3524, Jan 8th, 2019.

		//WF: Reference account field values
		if (lst_OrderWithUpdatedAccount.size() > 0) {
			syncOrderAccountAddress(lst_OrderWithUpdatedAccount, set_OrderAccountId);
		}

		//run date calculating logic
		if (lst_rundDateCalculationOrders.size() > 0) {
			updateRunDate(lst_rundDateCalculationOrders);
		}

		if (lst_BMRAssignedUpdatedOrders.size() > 0) {
			updateBMRonRelatedOpportunityAndAccount(lst_BMRAssignedUpdatedOrders);
		}

		if (list_BMROrderFacilitatorSync.size() > 0) {
			synBMROrderFacilitators(list_BMROrderFacilitatorSync);
		}

		//By: Neha 31 Oct 2019, To Update Original Check date for the first time
		setOriginalCheckDateAndCalculatePayDateFields(newOrderMap.values(), oldOrderMap);

		calculateComplexityScoring(newOrderMap.values(), oldOrderMap);
		for (Order newOrderObj : newOrderMap.values()) {
			Order oldOrderObj = oldOrderMap.get(newOrderObj.id);
			//ND, 27 Nov 2019, Set Facilitator Assigned timestamp, when Facilitator is assigned on Order for the first time
			if (null != newOrderObj.Data_Entry_Assist__c && oldOrderObj.Data_Entry_Assist__c == null && null == newOrderObj.Facilitator_Assigned_DateTime__c)
				newOrderObj.Facilitator_Assigned_DateTime__c = system.now();
			//ND, 27 Nov 2019, Set Facilitator_Work_Start_DateTime__c, when Facilitator was assigned earlier assigned and now removed from Order
			if (null == newOrderObj.Data_Entry_Assist__c && oldOrderObj.Data_Entry_Assist__c != null && null == newOrderObj.Facilitator_Work_Start_DateTime__c) {
				newOrderObj.Facilitator_Work_Start_DateTime__c = system.now();
			}
			//31 Dec, 2021, Update Week Number when First Check Dates is changed
			if (newOrderObj.First_Check_Date__c != oldOrderObj.First_Check_Date__c && newOrderObj.First_Check_Date__c != null) {
				calcWeekNumberForFirstCheckDate(newOrderObj);
			}
		}
	}

	public override void afterUpdate() {
		Map<Id, Order> oldOrderMap = (Map<Id, Order>) Trigger.oldMap;
		Map<Id, Order> newOrderMap = (Map<Id, Order>) Trigger.newMap;

		List<Order> changeOrderStatusList = new List<Order>();
		set<Id> changeOppStatus = new Set<Id>();
		set<Id> bulkMReqIdSet = new Set<Id>(); // To store list of Bulk Mig Req Ids
		List<Order> lst_ManuallyAssignedPTOrders = new List<Order>(); //for advocates
		List<Order> lst_ManuallyAssignedFacilitatorPTOrders = new List<Order>(); //for facilitator
		string companyMigrationRecordTypeId = idOrder_RT_CompanyMigration;
		//for Submit TTF Notification
		List<Order> list_submitTTFNotificationEligibleOrders = new List<Order>();

		Map<Id, Order> map_BOARelatedCountsToBeUpdated = new Map<Id, Order>(); // Orders for which Active_Employee_Count__c or Inactive_Employee_Count__c or Contractor_Count__c is changed

		Set<Id> setBulkMigrationId = new Set<Id>();
		for (Order ord : newOrderMap.values()) {
			Order oldOrderRec = oldOrderMap.get(ord.Id);

			if (
				ord.Active_Employee_Count__c != oldOrderRec.Active_Employee_Count__c ||
				ord.Inactive_Employee_Count__c != oldOrderRec.Inactive_Employee_Count__c ||
				ord.Contractor_Count__c != oldOrderRec.Contractor_Count__c ||
				ord.Status != oldOrderRec.Status
			) {
				map_BOARelatedCountsToBeUpdated.put(ord.Id, ord);
			}

			if (
				ord.Bulk_Migration__c != null &&
				(ord.Bulk_Migration__c != oldOrderRec.Bulk_Migration__c ||
				(ord.First_Check_Date__c != oldOrderRec.First_Check_Date__c) ||
				(ord.Status != oldOrderRec.Status) ||
				(ord.Facilitator_Due_Date__c != oldOrderRec.Facilitator_Due_Date__c))
			) {
				setBulkMigrationId.add(ord.Bulk_Migration__c);
			}

			if (oldOrderMap.containskey(ord.id) && ord.Status != null && ord.OpportunityId != null && ord.Status != oldOrderRec.Status && !changeOppStatus.contains(ord.OpportunityId)) {
				changeOrderStatusList.add(ord);
				changeOppStatus.add(ord.OpportunityId);
			}
			// If updated case has Bulk_Migration__c and its status has changed to either 'Closed: Payroll Run' Or 'Closed: Canceled'
			if (ord.Bulk_Migration__c != null && ord.Status != null && (oldOrderRec.Status != ord.Status || oldOrderRec.Bulk_Migration__c != ord.Bulk_Migration__c)) {
				bulkMReqIdSet.add(ord.Bulk_Migration__c);
			}

			//BY: PR, Desc: manually assigned Advocate "payroll transfer" Order handling code
			if (oldOrderRec.OwnerId != ord.OwnerId && !isPayrollTransferAutoAssignment && ord.RecordTypeId == companyMigrationRecordTypeId) {
				lst_ManuallyAssignedPTOrders.add(ord);
			} else if (
				ord.OwnerId != null &&
				string.valueOf(ord.OwnerId).startsWith('005') &&
				ord.recordTypeId == companyMigrationRecordTypeId &&
				ord.First_Check_Date__c != null &&
				ord.First_Check_Date__c != oldOrderRec.First_Check_Date__c &&
				!isPayrollTransferAutoAssignment
			) {
				if (oldOrderRec.First_Check_Date__c == null) {
					lst_ManuallyAssignedPTOrders.add(ord);
				} else if (oldOrderRec.First_Check_Date__c != null && oldOrderRec.First_Check_Date__c.toStartOfWeek() != ord.First_Check_Date__c.toStartOfWeek()) {
					lst_ManuallyAssignedPTOrders.add(ord);
				}
			}

			//BY: PR, Desc: manually assigned facilitator "payroll transfer" Order handling code
			if (oldOrderRec.Data_Entry_Assist__c != ord.Data_Entry_Assist__c && ord.RecordTypeId == companyMigrationRecordTypeId && !isPayrollTransferAutoAssignment) {
				lst_ManuallyAssignedFacilitatorPTOrders.add(ord);
			} else if (
				ord.Data_Entry_Assist__c != null &&
				ord.recordTypeId == companyMigrationRecordTypeId &&
				ord.Facilitator_Due_Date__c != null &&
				ord.Facilitator_Due_Date__c != oldOrderRec.Facilitator_Due_Date__c &&
				!isPayrollTransferAutoAssignment
			) {
				if (oldOrderRec.Facilitator_Due_Date__c == null) {
					lst_ManuallyAssignedFacilitatorPTOrders.add(ord);
				} else if (oldOrderRec.Facilitator_Due_Date__c != null && oldOrderRec.Facilitator_Due_Date__c.toStartOfWeek() != ord.Facilitator_Due_Date__c.toStartOfWeek()) {
					lst_ManuallyAssignedFacilitatorPTOrders.add(ord);
				}
			}

			if (
				String.isNotBlank(ord.Migration_State__c) &&
				ord.Migration_State__c == OrderUtils.BASICS_COMPLETED &&
				oldOrderRec.Migration_State__c != OrderUtils.BASICS_COMPLETED &&
				ord.OpportunityId != null
			) {
				list_submitTTFNotificationEligibleOrders.add(ord);
			}
		}

		//Update Bulk Migration
		if (setBulkMigrationId != null && setBulkMigrationId.size() > 0) {
			UpdateOrderBulkMigrationRequest(setBulkMigrationId);
		}

		// SJay - 12/3/2020 - Added size/null check
		if (changeOrderStatusList != null && changeOrderStatusList.size() > 0) {
			populateOrderStatusOnMatchingOpportunities(changeOrderStatusList, null);
		}

		createOrderStatusChangeHistory(oldOrderMap, newOrderMap.values()); // Rahul Joshi, BT-3524, Jan 8th, 2019.

		//Update BMR records on order.Status or Relationship update
		if (bulkMReqIdSet.size() > 0) {
			updateBulkMigrationObject(bulkMReqIdSet);
		}

		//on manual owner assignment update BOR ORder relationship object
		if (lst_ManuallyAssignedPTOrders.size() > 0) {
			createOrderBOARelationForManuallyAssignedOrders(lst_ManuallyAssignedPTOrders);
		}

		//on manual facilitator assignment update BOA Order relationship object
		if (lst_ManuallyAssignedFacilitatorPTOrders.size() > 0) {
			syncOrderBOARelationForManuallyAssignedFacilitatorOrders(lst_ManuallyAssignedFacilitatorPTOrders);
		}

		//By: Neha 31 Oct 2019, copy over Employee&Contracts counts to BOA relationship records
		if (map_BOARelatedCountsToBeUpdated.size() > 0) {
			setEmployeeCountFieldOnBOARelationship(map_BOARelatedCountsToBeUpdated);
		}

		//send Submit TTF notification email
		if (list_submitTTFNotificationEligibleOrders.size() > 0) {
			sendSubmitTTFNotification(list_submitTTFNotificationEligibleOrders);
		}

		updateCaseStatus_OwnerAndOrderNotifications(oldOrderMap, newOrderMap);
	}

	/**
	 * @Description             : populate "Ready_For_Facilitator_Due_Date__c" based on
	 *                              "Facilitator_Due_Date__c"
	 * @Parm                    : objOrder[Eligible Order record]
	 * @Return                  : null
	 */
	public void setReadyForFacilitatorDueDate(Order objOrder) {
		Integer intDefaultInterval = Utils.ORG_WIDE_CONFIG_SETTINGS?.PT_Ready_For_Facilitator_SLA__c != null ? Integer.valueOf(Utils.ORG_WIDE_CONFIG_SETTINGS?.PT_Ready_For_Facilitator_SLA__c) : -2;
		if (objOrder != null) {
			if (objOrder.Big_Desk_Sandbox_Type__c == BIGDESK_FIELD_VALUE) {
				intDefaultInterval = Utils.ORG_WIDE_CONFIG_SETTINGS?.PT_Ready_For_Facilitator_Big_Desk_SLA__c != null
					? Integer.valueOf(Utils.ORG_WIDE_CONFIG_SETTINGS?.PT_Ready_For_Facilitator_Big_Desk_SLA__c)
					: -7;
			}

			objOrder.Ready_For_Facilitator_Due_Date__c = Utils.getBusinessDayFromDate(objOrder.Facilitator_Due_Date__c, intDefaultInterval);
		}
	}

	/*Logic to update BigDesk type field */
	public void reCalculateBigDeskFieldValue(Order objOrder, Order objOldOrder) {
		if (
			objOldOrder == null ||
			(objOrder.Contractor_Count__c != objOldOrder.Contractor_Count__c ||
			objOrder.Inactive_Employee_Count__c != objOldOrder.Inactive_Employee_Count__c ||
			objOrder.Active_Employee_Count__c != objOldOrder.Active_Employee_Count__c)
		) {
			Decimal decAICCount = objOrder.Contractor_Count__c == null ? 0 : objOrder.Contractor_Count__c;
			decAICCount += objOrder.Inactive_Employee_Count__c == null ? 0 : objOrder.Inactive_Employee_Count__c;
			decAICCount += objOrder.Active_Employee_Count__c == null ? 0 : objOrder.Active_Employee_Count__c;

			objOrder.Big_Desk_Sandbox_Type__c = null;
			if (decAICCount >= 100) {
				objOrder.Big_Desk_Sandbox_Type__c = BIG_DESK_100PLUS;
			}
		}
	}

	//Desc: This method calculate the run date based on related Opportunity owner Role
	public void updateRunDate(list<Order> lst_orders) {
		string partnerSalesRoleStr = 'sales_partner_xx_xx_mgr,sales_partner_am_xx,sales_partner_ae_xx,sales_partner_cvr_xx,sales_partner_sam_xx';
		string midMarketRoleStr = 'sales_mm_pr_xx,sales_mm_den_pr_mgr';

		if (lst_orders == null || lst_orders.size() == 0) {
			return;
		}

		set<Id> set_oppIds = new Set<Id>();
		set<Id> set_TTFIds = new Set<Id>();
		for (Order orderRec : lst_orders) {
			if (orderRec.OpportunityId != null)
				set_oppIds.add(orderRec.OpportunityId);

			if (orderRec.Transition_To_Fulfillment__c != null) {
				set_TTFIds.add(orderRec.Transition_To_Fulfillment__c);
			}
		}

		map<Id, Transition_to_Fulfillment__c> map_payedOnFirstCheckDateTTFIdRec = new Map<Id, Transition_to_Fulfillment__c>(
			[SELECT id FROM Transition_to_Fulfillment__c WHERE Id IN :set_TTFIds AND Contractors_paid_on_first_pay_date__c = 'Yes']
		);
		map<Id, Opportunity> map_opportunityIdRec = new Map<Id, Opportunity>(
			[SELECT Id, Owner.UserRoleId, Owner.UserRole.DeveloperName, Account.ACH_Speed__c FROM Opportunity WHERE Id IN :set_oppIds]
		);

		for (Order orderObj : lst_orders) {
			if (orderObj.OpportunityId != null && map_opportunityIdRec.containsKey(orderObj.OpportunityId)) {
				Opportunity oppRec = map_opportunityIdRec.get(orderObj.OpportunityId);
				boolean isPayedOnFirstCheckDate = map_payedOnFirstCheckDateTTFIdRec.containsKey(orderObj.Transition_To_Fulfillment__c);

				if (orderObj.First_Check_Date__c == null) {
					continue;
				}

				orderObj.Payroll_Run_Date__c = getOrderNextPayrollRunDate(objBusinessHour, orderObj.First_Check_Date__c, oppRec.Account.ACH_Speed__c);

				if (orderObj.Payroll_Run_Date__c != null) {
					orderObj.Facilitator_Due_Date__c = Utils.getBusinessDayFromDate(orderObj.Payroll_Run_Date__c, intFacilitatorDueDateDaysFromPayrollRunDate);
				}
			}
		}
	}

	/*
        BY: PR, Date: June/18/2020, Ticket: https://app.asana.com/0/1177941845157306/1179845649246264/f
        Desc: utility method to process and return calculated Payroll Run Date for Order
    */
	public Date getOrderNextPayrollRunDate(BusinessHours objBusinessHour, Date dtFirstCheckDate, string strAchType) {
		//defauly is 2 days
		integer intDaysBeforeRunDate = 2;

		if (string.isNotBlank(strAchType)) {
			if (strAchType == 'Next day') {
				intDaysBeforeRunDate = 1;
			}
		}

		if (objBusinessHour != null) {
			long lngDaysInMiliSeconds = intDaysBeforeRunDate * 8 * 60 * 60 * 1000;
			DateTime dtDaysEarlierDT = BusinessHours.add(objBusinessHour.Id, dtFirstCheckDate, -lngDaysInMiliSeconds);
			if (dtDaysEarlierDT != null) {
				return dtDaysEarlierDT.date();
			}
		} else {
			return dtFirstCheckDate.addDays(-intDaysBeforeRunDate);
		}

		return null;
	}

	/**
	 * @Description             : Sync Owner for BMR orders
	 * @Parm                    : lst_orders[list of bmr orders], set_bmrIds[set of bmr Ids]
	 * @Return                  : null
	 */
	public void updateSynOrderAndBMROwners(list<Order> lst_orders, set<Id> set_bmrIds) {
		if (!set_bmrIds.isEmpty()) {
			Map<Id, Bulk_Migration_Request__c> map_BMRIdRecords = getBulkMigrations(set_bmrIds);

			for (Order objOrder : lst_orders) {
				Bulk_Migration_Request__c objBMR = map_BMRIdRecords.get(objOrder.Bulk_migration__c);
				if (objOrder.OwnerId != objBMR.OwnerId) {
					objOrder.OwnerId = objBMR.OwnerId;
				}
			}
		}
	}

	/**
	 * @Description             : Sync Facilitator for BMR orders
	 * @Parm                    : lst_orders[list of bmr orders]
	 * @Return                  : null
	 * @last Modified by        : PR
	 * @last Modification date  : October 28, 2021
	 */
	public void synBMROrderFacilitators(list<Order> lst_orders) {
		Set<Id> set_bmrIds = new Set<Id>();
		for (Order objOrder : lst_orders) {
			set_bmrIds.add(objOrder.Bulk_Migration__c);
		}

		Map<Id, Bulk_Migration_Request__c> map_BMRIdRecords = getBulkMigrations(set_bmrIds);

		for (Order objOrder : lst_orders) {
			Bulk_Migration_Request__c objBMR = map_BMRIdRecords.get(objOrder.Bulk_Migration__c);
			if (objOrder.RecordTypeId == idOrder_RT_CompanyMigration && objBMR != null && objBMR.Facilitator__c != null && objOrder.Data_Entry_Assist__c == null) {
				objOrder.Data_Entry_Assist__c = objBMR.Facilitator__c;
				objOrder.PT_Facilitator_Assignment_Reason__c = PT_FACILITATOR_ASSIGNMENT_REASON_BMR_FACILITATOR;
				objOrder.Facilitator_Assigned_DateTime__c = System.now();
			}
		}
	}

	//WF: Reference account field values
	public void syncOrderAccountAddress(list<Order> lst_OrderObj, set<id> set_accountId) {
		if (lst_OrderObj != null && lst_OrderObj.size() > 0 && set_accountId != null && set_accountId.size() > 0) {
			map<id, Account> map_accIdRecord = new Map<id, Account>(
				[
					SELECT Id, BillingCity, BillingCountry, BillingState, BillingStreet, BillingPostalCode, ShippingCity, ShippingCountry, ShippingState, ShippingStreet, ShippingPostalCode
					FROM Account
					WHERE Id IN :set_accountId
				]
			);

			for (order orderObj : lst_OrderObj) {
				if (orderObj.AccountId != null && map_accIdRecord.containsKey(orderObj.AccountId)) {
					Account accObj = map_accIdRecord.get(orderObj.AccountId);
					orderObj.BillingCity = accObj.BillingCity;
					orderObj.BillingCountry = accObj.BillingCountry;
					orderObj.BillingState = accObj.BillingState;
					orderObj.BillingStreet = accObj.BillingStreet;
					orderObj.BillingPostalCode = accObj.BillingPostalCode;
					orderObj.ShippingCity = accObj.ShippingCity;
					orderObj.ShippingCountry = accObj.ShippingCountry;
					orderObj.ShippingState = accObj.ShippingState;
					orderObj.ShippingStreet = accObj.ShippingStreet;
					orderObj.ShippingPostalCode = accObj.ShippingPostalCode;
				}
			}
		}
	}

	/*By: PR, Date:9/16/19, 
    Desc: We are deleting old "Order BOA Relationship" records for the eligible orders, And creating new 
        relationship records with correct order 
    */
	public void createOrderBOARelationForManuallyAssignedOrders(list<Order> lst_manuallyAssignedOrders) {
		list<Order_BOA_Relationship__c> lst_toInsertOrderBOARelationshipObj = new List<Order_BOA_Relationship__c>();
		list<Order_BOA_Relationship__c> lst_oldRelationRecords = new List<Order_BOA_Relationship__c>();

		string advocateRecordTypeId = idFBOSForecast_RT_Advocate;

		if (lst_manuallyAssignedOrders != null && lst_manuallyAssignedOrders.size() > 0) {
			set<Date> set_WeekStartDate = new Set<Date>();
			set<Id> set_orderIds = new Set<Id>();
			PayrollTransferAssignmentUtil assignmentUtil = new PayrollTransferAssignmentUtil();

			for (Order orderObj : lst_manuallyAssignedOrders) {
				if (orderObj.First_Check_Date__c != null) {
					set_WeekStartDate.add(assignmentUtil.getWeekStartEndDate_MonthVise(orderObj.First_Check_Date__c).get(0));
				}
				set_orderIds.add(orderObj.Id);
			}

			//to delete old advocate relationShip records
			lst_oldRelationRecords = [
				SELECT Id
				FROM Order_BOA_Relationship__c
				WHERE Orders__c IN :set_orderIds AND Benefit_Order_Allocation__r.Payroll_Transfer_FBOS_Forecast__r.RecordTypeId = :advocateRecordTypeId
			];

			//calling order assignment uti class to query the correct records.
			assignmentUtil.getUserBOADetails(set_WeekStartDate);

			if (assignmentUtil.map_startEndDate2UserIdBOA.keyset().size() > 0) {
				for (Order orderObj : lst_manuallyAssignedOrders) {
					if (orderObj.OwnerId == null || !String.valueOf(orderObj.OwnerId).startsWith('005')) {
						continue;
					}

					string orderWeekStartEndDateTime = assignmentUtil.getWeekStartEndDateString(orderObj.First_Check_Date__c);
					if (
						assignmentUtil.map_startEndDate2UserIdBOA.containsKey(orderWeekStartEndDateTime) &&
						assignmentUtil.map_startEndDate2UserIdBOA.get(orderWeekStartEndDateTime).containsKey(orderObj.OwnerId)
					) {
						Benefit_Order_Allocation__c tempBOAObj = assignmentUtil.map_startEndDate2UserIdBOA.get(orderWeekStartEndDateTime).get(orderObj.OwnerId);

						if (tempBOAObj != null && tempBOAObj.id != null) {
							Order_BOA_Relationship__c newRelationObj = new Order_BOA_Relationship__c(Benefit_Order_Allocation__c = tempBOAObj.id, Orders__c = orderObj.id);
							lst_toInsertOrderBOARelationshipObj.add(newRelationObj);
						}
					}
				}
			}
		}

		try {
			if (lst_oldRelationRecords.size() > 0) {
				delete lst_oldRelationRecords;
			}

			if (lst_toInsertOrderBOARelationshipObj.size() > 0) {
				insert lst_toInsertOrderBOARelationshipObj;
			}
		} catch (exception ex) {
		}
	}

	/*By: PR, Date:9/16/19, 
    Desc: We are deleting old "Order BOA Relationship" records for the eligible orders, And creating new 
        relationship records with correct order ..... For facilitator
    */
	public void syncOrderBOARelationForManuallyAssignedFacilitatorOrders(list<Order> lst_manuallyAssignedOrders) {
		list<Order_BOA_Relationship__c> lst_toInsertOrderBOARelationshipObj = new List<Order_BOA_Relationship__c>();
		list<Order_BOA_Relationship__c> lst_oldRelationRecords = new List<Order_BOA_Relationship__c>();

		string facilitatorRecordTypeId = idFBOSForecast_RT_Facilitator;

		if (lst_manuallyAssignedOrders != null && lst_manuallyAssignedOrders.size() > 0) {
			set<Date> set_WeekStartDate = new Set<Date>();
			set<Id> set_orderIds = new Set<Id>();
			PayrollTransferAssignmentUtil assignmentUtil = new PayrollTransferAssignmentUtil();

			for (Order orderObj : lst_manuallyAssignedOrders) {
				if (orderObj.First_Check_Date__c != null) {
					set_WeekStartDate.add(assignmentUtil.getWeekStartEndDate_MonthVise(orderObj.Facilitator_Due_Date__c).get(0));
				}
				set_orderIds.add(orderObj.Id);
			}

			//to delete old facilitator relationShip records
			lst_oldRelationRecords = [
				SELECT Id
				FROM Order_BOA_Relationship__c
				WHERE Orders__c IN :set_orderIds AND Benefit_Order_Allocation__r.Payroll_Transfer_FBOS_Forecast__r.RecordTypeId = :facilitatorRecordTypeId
			];

			//calling order assignment uti class to query the correct records.
			assignmentUtil.getFacilitatorBOADetails(set_WeekStartDate);

			if (assignmentUtil.map_startEndDate2UserIdBOA.keyset().size() > 0) {
				for (Order orderObj : lst_manuallyAssignedOrders) {
					if (orderObj.Data_Entry_Assist__c == null) {
						continue;
					}
					string orderWeekStartEndDateTime = assignmentUtil.getWeekStartEndDateString(orderObj.Facilitator_Due_Date__c);
					if (
						assignmentUtil.map_startEndDate2UserIdBOA.containsKey(orderWeekStartEndDateTime) &&
						assignmentUtil.map_startEndDate2UserIdBOA.get(orderWeekStartEndDateTime).containsKey(orderObj.Data_Entry_Assist__c)
					) {
						Benefit_Order_Allocation__c tempBOAObj = assignmentUtil.map_startEndDate2UserIdBOA.get(orderWeekStartEndDateTime).get(orderObj.Data_Entry_Assist__c);

						if (tempBOAObj != null && tempBOAObj.id != null) {
							Order_BOA_Relationship__c newRelationObj = new Order_BOA_Relationship__c(Benefit_Order_Allocation__c = tempBOAObj.id, Orders__c = orderObj.id);
							lst_toInsertOrderBOARelationshipObj.add(newRelationObj);
						}
					}
				}
			}
		}

		try {
			if (lst_oldRelationRecords.size() > 0) {
				delete lst_oldRelationRecords;
			}

			if (lst_toInsertOrderBOARelationshipObj.size() > 0) {
				insert lst_toInsertOrderBOARelationshipObj;
			}
		} catch (exception ex) {
		}
	}

	/*
	 * Modified By  : @Neha Dabas, 16th April 2020,
	 * Desciption   : Consolidated the code to calculate various complexity scores on Order.
	 */
	public static void calculateComplexityScoring(List<Order> list_newOrders, Map<ID, Order> map_OldOrders) {
		//For State Complexity
		String tier1States = 'ME, NH, VT, RI, CT';
		String tier2States = 'NM, OR, CO, KS, MO, MI, MA,DC, AR, LA, IN, OK';
		String tier3States = 'WA, NJ, NY';
		String tier4States = 'OH, PA, KY, GA, MN';

		for (Order objOrder : list_newOrders) {
			//Calculate number of Deductions
			if (objOrder.Deductions_List__c != null && objOrder.Deductions_List__c != '') {
				if (objOrder.Deductions_List__c.indexOf('\n') > -1) {
					objOrder.of_Deductions__c = objOrder.Deductions_List__c.split('\n').size();
				} else if (objOrder.Deductions_List__c.indexOf(',') > -1) {
					objOrder.of_Deductions__c = objOrder.Deductions_List__c.split(',').size();
				} else if (objOrder.Deductions_List__c.indexOf(';') > -1) {
					objOrder.of_Deductions__c = objOrder.Deductions_List__c.split(';').size();
				} else {
					objOrder.of_Deductions__c = 1;
				}
			} else {
				objOrder.of_Deductions__c = 0;
			}

			//Calculate No. of Benefits
			objOrder.of_Benefits__c = 0;

			if (String.isNotBlank(objOrder.Financial_Health_Benefits__c)) {
				if (objOrder.Financial_Health_Benefits__c.indexOf('\n') > -1) {
					objOrder.of_Benefits__c += objOrder.Financial_Health_Benefits__c.split('\n').size();
				} else if (objOrder.Financial_Health_Benefits__c.indexOf(',') > -1) {
					objOrder.of_Benefits__c += objOrder.Financial_Health_Benefits__c.split(',').size();
				} else if (objOrder.Financial_Health_Benefits__c.indexOf(';') > -1) {
					objOrder.of_Benefits__c += objOrder.Financial_Health_Benefits__c.split(';').size();
				} else {
					objOrder.of_Benefits__c += 1;
				}
			}

			if (String.isNotBlank(objOrder.Other_Financial_Benefits_Currently_Offer__c)) {
				if (objOrder.Other_Financial_Benefits_Currently_Offer__c.indexOf('\n') > -1) {
					objOrder.of_Benefits__c += objOrder.Other_Financial_Benefits_Currently_Offer__c.split('\n').size();
				} else if (objOrder.Other_Financial_Benefits_Currently_Offer__c.indexOf(',') > -1) {
					objOrder.of_Benefits__c += objOrder.Other_Financial_Benefits_Currently_Offer__c.split(',').size();
				} else if (objOrder.Other_Financial_Benefits_Currently_Offer__c.indexOf(';') > -1) {
					objOrder.of_Benefits__c += objOrder.Other_Financial_Benefits_Currently_Offer__c.split(';').size();
				} else {
					objOrder.of_Benefits__c += 1;
				}
			}

			if (String.isNotBlank(objOrder.Other_Health_Benefits_Currently_Offered__c)) {
				if (objOrder.Other_Health_Benefits_Currently_Offered__c.indexOf('\n') > -1) {
					objOrder.of_Benefits__c += objOrder.Other_Health_Benefits_Currently_Offered__c.split('\n').size();
				} else if (objOrder.Other_Health_Benefits_Currently_Offered__c.indexOf(',') > -1) {
					objOrder.of_Benefits__c += objOrder.Other_Health_Benefits_Currently_Offered__c.split(',').size();
				} else if (objOrder.Other_Health_Benefits_Currently_Offered__c.indexOf(';') > -1) {
					objOrder.of_Benefits__c += objOrder.Other_Health_Benefits_Currently_Offered__c.split(';').size();
				} else {
					objOrder.of_Benefits__c += 1;
				}
			}

			if (String.isNotBlank(objOrder.Transportation_Benefits__c)) {
				if (objOrder.Transportation_Benefits__c.indexOf('\n') > -1) {
					objOrder.of_Benefits__c += objOrder.Transportation_Benefits__c.split('\n').size();
				} else if (objOrder.Transportation_Benefits__c.indexOf(',') > -1) {
					objOrder.of_Benefits__c += objOrder.Transportation_Benefits__c.split(',').size();
				} else if (objOrder.Transportation_Benefits__c.indexOf(';') > -1) {
					objOrder.of_Benefits__c += objOrder.Transportation_Benefits__c.split(';').size();
				} else {
					objOrder.of_Benefits__c += 1;
				}
			}

			if (String.isNotBlank(objOrder.Which_Health_Benefits_Currently_Offered__c)) {
				if (objOrder.Which_Health_Benefits_Currently_Offered__c.indexOf('\n') > -1) {
					objOrder.of_Benefits__c += objOrder.Which_Health_Benefits_Currently_Offered__c.split('\n').size();
				} else if (objOrder.Which_Health_Benefits_Currently_Offered__c.indexOf(',') > -1) {
					objOrder.of_Benefits__c += objOrder.Which_Health_Benefits_Currently_Offered__c.split(',').size();
				} else if (objOrder.Which_Health_Benefits_Currently_Offered__c.indexOf(';') > -1) {
					objOrder.of_Benefits__c += objOrder.Which_Health_Benefits_Currently_Offered__c.split(';').size();
				} else {
					objOrder.of_Benefits__c += 1;
				}
			}

			//Calculate Payrate count
			if (objOrder.Pay_Rates__c != null && objOrder.Pay_Rates__c != '') {
				if (objOrder.Pay_Rates__c.indexOf('\n') > -1) {
					objOrder.of_Pay_Rates__c = objOrder.Pay_Rates__c.split('\n').size();
				} else if (objOrder.Pay_Rates__c.indexOf(',') > -1) {
					objOrder.of_Pay_Rates__c = objOrder.Pay_Rates__c.split(',').size();
				} else if (objOrder.Pay_Rates__c.indexOf(';') > -1) {
					objOrder.of_Pay_Rates__c = objOrder.Pay_Rates__c.split(';').size();
				} else {
					objOrder.of_Pay_Rates__c = 1;
				}
			} else {
				objOrder.of_Pay_Rates__c = 0;
			}
		}
	}

	// check if the case is blank on order update the related case
	public static void updateRelatedCase(Map<ID, Order> oldOrderMap, List<Order> newOrdersList) {
		for (Order obj : newOrdersList) {
			if (oldOrderMap.containskey(obj.id) && obj.case__c == null && oldOrderMap.get(obj.Id).case__c != null && oldOrderMap.get(obj.Id).case__c != obj.case__c) {
				obj.case__c = oldOrderMap.get(obj.Id).case__c;
			}
			// By: Deepak Tyagi JIRA #2807, Date: Dec 28, 2018 Desc: Update Order Closed_Payroll_Run__c
			if (obj.Status != oldOrderMap.get(obj.Id).Status && ORDER_STATUS_CLOSEDPAYROLLRUN.equalsIgnoreCase(obj.Status)) {
				obj.Closed_Payroll_Run__c = system.today();
			}
		}
	}

	// check if its changes from last map  Time_Updated_from_Assigned__c
	private static void calculateOrderSLAUpdate(Map<ID, Order> oldOrderMap, List<Order> newOrdersList) {
		Set<Id> caseIdSet = new Set<Id>();
		for (Order ord : newOrdersList) {
			if (oldOrderMap.containskey(ord.id) && ord.Time_Updated_from_Assigned__c != null && ord.Time_Updated_from_Assigned__c != oldOrderMap.get(ord.id).Time_Updated_from_Assigned__c) {
				caseIdSet.add(ord.Case__c);
			}
		}
		//Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, BusinessHoursId FROM Case WHERE Id IN :caseIdSet]);
		if (caseIdSet.size() > 0) {
			List<BusinessHours> listBusinessHours = [SELECT Id, TimeZoneSidKey, IsDefault FROM BusinessHours WHERE name = 'Gusto - Denver'];
			if (listBusinessHours != null) {
				for (Order ord : newOrdersList) {
					if (ord.Time_Updated_from_Assigned__c != null && ord.Order_Assigned_Timestamp__c != null) {
						ord.Order_SLA_hours__c = (Decimal) BusinessHours.diff(listBusinessHours[0].id, ord.Order_Assigned_Timestamp__c, ord.Time_Updated_from_Assigned__c) / 1000 / 60 / 60;
					}
				}
			}
		}
	}

	public static void populateOrderStatusOnMatchingOpportunities(List<Order> newOrdersList, Map<Id, Order> oldOrderMap) {
		Set<Id> accountIdSet = new Set<Id>();
		Set<Id> oppIdSet = new Set<Id>();
		for (Order ord : newOrdersList) {
			oppIdSet.add(ord.OpportunityId);
		}

		Id companyRecordTypeId = idOpportunity_RT_Company;

		// Query all open opportunities where record type = company opportunity and Company_Migration__c is blank
		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
			[SELECT Id, Order_Status__c, Order__c, AccountId FROM Opportunity WHERE id IN :oppIdSet AND (RecordTypeId = :companyRecordTypeId OR RecordTypeId = :idAcquisitionRecordType)]
		);

		List<Opportunity> toBeUpdatedOppList = new List<Opportunity>();
		for (Order ord : newOrdersList) {
			if (ord.OpportunityId != null && oppMap.containsKey(ord.OpportunityId)) {
				Opportunity opp = oppMap.get(ord.OpportunityId);
				opp.Order_Status__c = ord.Status;
				toBeUpdatedOppList.add(opp);
			}
		}

		if (toBeUpdatedOppList.size() > 0) {
			boolean previousVal = OpportunityTriggerHelper.skipTrigger;
			OpportunityTriggerHelper.skipTrigger = true;
			Map<String, String> errorOppMap = Utils.doDMLAndReturnAllErrors(
				'Update', // type of DML operation
				'OpportunityId', // Return map key
				toBeUpdatedOppList, // sObject list
				false, // all or none flag
				true, // log the error
				'OrderTriggerHelper-populateOrderStatusOnMatchingOpportunities'
			);
			OpportunityTriggerHelper.skipTrigger = previousVal;
			// if there are any errors, show them on the screen
			for (Order ord : newOrdersList) {
				if (errorOppMap.containsKey(ord.AccountId)) {
					ord.addError(errorOppMap.get(ord.AccountId));
				}
			}
		}
	}

	/*
        By: Deepak Tyagi
        Date: Dec 28, 2018
        JIRA #2807
        Desc: Update Case owner and Case status From Order

        Latest Mods By: PR
        Date: Oct 9, 2019
    */
	public static void updateCaseStatus_OwnerAndOrderNotifications(Map<Id, Order> map_oldOrders, Map<Id, Order> map_newOrders) {
		Map<Id, Case> map_OrderCases = new Map<Id, Case>();
		Map<Id, Case> map_ToUpdateCases = new Map<Id, Case>();
		Map<Id, List<Case>> map_OrderIdCases = new Map<Id, List<Case>>();
		Map<Id, Case> map_AllCasesToUpdate = new Map<Id, Case>();
		Map<Order, Case> map_OrderCases_IntroEmail_IntuitQuickBook = new Map<Order, Case>();

		map<Id, Case> map_toUpdateNewlyClosedOwnerUpdateCases = new Map<Id, Case>();

		Set<Id> orderIdSet = new Set<Id>();
		Set<Id> orderOwnerIdSet = new Set<Id>();

		if (map_newOrders == null || map_oldOrders == null) {
			return;
		}

		for (Order orderObj : map_newOrders.values()) {
			orderIdSet.add(orderObj.Id);

			if (string.valueOf(orderObj.OwnerId).startsWith('005'))
				orderOwnerIdSet.add(orderObj.OwnerId);
		}
		// SJay - 12/3/2020 - Commented out below query and using the globally defined business hours.
		//BusinessHours businessHourObj = [SELECT Id FROM BusinessHours WHERE IsDefault = true][0];
		BusinessHours businessHourObj = objBusinessHour;
		Datetime dateAfterTwoBusinessDays = BusinessHours.add(businessHourObj.Id, system.now(), 2 * 8 * 60 * 60 * 1000);

		Set<Id> set_OrderOwnerWithNoPhone = new Set<Id>(); // Id of OrderOwners whose phone number is not set on case
		// @Neha, For Email Signature change : Added Order_Owner_Phone__c to case query
		for (
			Case objCase : [
				SELECT
					Id,
					X2_Business_Days_From_Last_Notification__c,
					Status,
					Order_Owner_Calendly_Link__c,
					Send_Survey__c,
					Order_Owner_Phone__c,
					Order_Owner_Phone_Extension__c,
					Order_Payroll_Run_Date__c,
					Order__c,
					Order__r.Transition_to_Fulfillment__r.Exception_Request__c,
					OwnerId,
					Contact_Related_Concierge_Account__c,
					Order__r.Owner.FirstName,
					Order__r.Owner.LastName,
					Order_Owner_Name__c,
					account.Tier__c,
					account.Priority_Support__c,
					Order__r.OwnerId,
					Order_AE_Email__c,
					ContactId,
					Order_Notification__c,
					Origin,
					Account.Name,
					AccountId,
					Error_Message__c,
					Contact_First_Name__c,
					Case_Reference__c
				FROM Case
				WHERE
					Order__c IN :orderIdSet
					AND RecordTypeId = :idCase_RT_PTCase // SJay - 12/3/2020 - Defined RT globally
					AND ((Integration_Key__c != NULL
					AND origin = :CASE_ORIGIN_PANDA)
					OR origin = :CASE_ORIGIN_GUSTO
					OR origin = :CASE_ORIGIN_EMAIL)
					AND Status != :CaseUtils.STATUS_CLOSED
			]
		) {
			if (objCase.origin != CASE_ORIGIN_EMAIL) {
				map_OrderCases.put(objCase.Order__c, objCase);

				//to check if PhoneNumberAssignment record needs to be fetched or not
				if (objCase.Order_Owner_Phone__c == null) {
					set_OrderOwnerWithNoPhone.add(objCase.Order__r.OwnerId);
				}
			} else {
				//In Else condition we handles Closing the cases where origin = 'Email'
				Order objOldOrder = map_oldOrders.get(objCase.Order__c);
				Order objNewOrder = map_newOrders.get(objCase.Order__c);

				if (
					objOldOrder.Status != objNewOrder.Status &&
					(objNewOrder.Bulk_Migration__c == null ||
					objNewOrder.Bulk_Case__c == null ||
					(objNewOrder.Bulk_Case__c != objCase.Id)) &&
					objNewOrder.Status.indexOf('Closed') > -1
				) {
					objCase.Status = CaseUtils.STATUS_CLOSED;
					map_toUpdateNewlyClosedOwnerUpdateCases.put(objCase.Id, objCase);
				}
			}
		}

		//@Neha, For Email Signature change : Fetch Phone for Order Owner
		map<Id, User> map_userIdRec = new Map<Id, User>([SELECT Id, Name, FirstName, Calendar_Link__c, Email, Phone, Extension FROM User WHERE Id IN :orderOwnerIdSet]);

		for (Order orderObj : map_newOrders.values()) {
			Order oldOrder = map_oldOrders.get(orderObj.id);
			if (map_OrderCases.containsKey(orderObj.Id)) {
				Case cse = map_OrderCases.get(orderObj.Id);
				if (orderObj.OwnerId != cse.OwnerId && orderObj.OwnerId != null && string.valueOf(orderObj.OwnerId).startsWith('005')) {
					cse.OwnerId = orderObj.OwnerId;
					map_toUpdateNewlyClosedOwnerUpdateCases.put(cse.Id, cse);
				}
				if (
					orderObj.Status != oldOrder.Status &&
					(orderObj.Bulk_Migration__c == null || (orderObj.Bulk_Migration__c != null && orderObj.Bulk_Case__c != cse.Id)) &&
					ORDER_STATUS_CLOSEDPAYROLLRUN.equalsIgnoreCase(orderObj.Status)
				) {
					cse.Status = CaseUtils.STATUS_CLOSED;
					if (orderObj.Bulk_Migration__c == null) {
						cse.Send_Survey__c = true;
					}
					map_toUpdateNewlyClosedOwnerUpdateCases.put(cse.Id, cse);
				}
				if (
					orderObj.Status != oldOrder.Status &&
					(orderObj.Bulk_Migration__c == null || (orderObj.Bulk_Migration__c != null && orderObj.Bulk_Case__c != cse.Id)) &&
					ORDER_STATUS_CLOSEDCANCELED.equalsIgnoreCase(orderObj.Status)
				) {
					cse.Status = CaseUtils.STATUS_CLOSED;
					cse.Send_Survey__c = false;
					map_toUpdateNewlyClosedOwnerUpdateCases.put(cse.Id, cse);
				}

				if (cse != null && string.valueOf(orderObj.OwnerId).startsWith('005')) {
					if (cse.Order_Payroll_Run_Date__c == null || cse.Order_Payroll_Run_Date__c != orderObj.Payroll_Run_Date__c) {
						cse.Order_Payroll_Run_Date__c = orderObj.Payroll_Run_Date__c;
						map_ToUpdateCases.put(cse.Id, cse);
					}
					if (cse.Order_Owner_Name__c == null || cse.Order_Owner_Name__c != map_userIdRec.get(orderObj.OwnerId).FirstName) {
						cse.Order_Owner_Name__c = map_userIdRec.get(orderObj.OwnerId).FirstName;
						map_ToUpdateCases.put(cse.Id, cse);
					}

					if (cse.Order_Owner_Calendly_Link__c == null || cse.Order_Owner_Calendly_Link__c != map_userIdRec.get(orderObj.OwnerId).Calendar_Link__c) {
						cse.Order_Owner_Calendly_Link__c = map_userIdRec.get(orderObj.OwnerId).Calendar_Link__c;
						map_ToUpdateCases.put(cse.Id, cse);
					}

					if ((cse.Order_AE_Email__c == null || cse.Order_AE_Email__c != orderObj.Agent_Email__c) && orderObj.Agent_Email__c != null) {
						cse.Order_AE_Email__c = orderObj.Agent_Email__c;
						map_ToUpdateCases.put(cse.Id, cse);
					}

					if (cse.Order_Owner_Phone__c == null && map_userIdRec.containsKey(cse.Order__r.OwnerId)) {
						String str_unformattedPhone = map_userIdRec.get(cse.Order__r.OwnerId).Phone;
						if (String.isNotBlank(str_unformattedPhone)) {
							str_unformattedPhone = str_unformattedPhone.replace('(', '').replace(')', '').replace('-', '').replace(' ', '');
							cse.Order_Owner_Phone__c = str_unformattedPhone.subString(0, 3) + '-' + str_unformattedPhone.subString(3, 6) + '-' + str_unformattedPhone.subString(6, 10); //map_userIdRec.get(orderObj.OwnerId).Phone;  @Neha, For Email Signature change
							map_ToUpdateCases.put(cse.Id, cse);
						}
					}

					if (cse.Order_Owner_Phone_Extension__c == null && map_userIdRec.containsKey(cse.Order__r.OwnerId)) {
						cse.Order_Owner_Phone_Extension__c = map_userIdRec.get(cse.Order__r.OwnerId).Extension;
						map_ToUpdateCases.put(cse.Id, cse);
					}

					if (orderObj.Bulk_Migration__c != null)
						continue;

					//intro emails logic
					if (
						oldOrder != null &&
						orderObj.Bulk_Migration__c == null &&
						((orderObj.OwnerId != oldOrder.OwnerId && string.valueOf(oldOrder.OwnerId).startsWith('00G') && string.valueOf(orderObj.OwnerId).startsWith('005')) ||
						string.valueOf(orderObj.OwnerId).startsWith('005')) &&
						(orderObj.Previous_Payroll_Provider__c == 'QuickBooks Online' ||
						orderObj.Previous_Payroll_Provider__c == 'Intuit Online Payroll' ||
						orderObj.Previous_Payroll_Provider__c == 'QuickBooks Desktop') &&
						oldOrder.Previous_Payroll_Provider__c != orderObj.Previous_Payroll_Provider__c &&
						(cse.Account.Tier__c != ACCOUNT_TIER_SELECT &&
						cse.Account.Tier__c != ACCOUNT_TIER_PREMIUM)
					) {
						if (
							(orderObj.Team_Invitation_Preference__c != null && OrderUtils.PT_TEAM_INVITATION_PREFERENCE.indexOf(orderObj.Team_Invitation_Preference__c.toLowerCase()) > -1) ||
							orderObj.Previous_Payroll_Provider__c == 'QuickBooks Desktop'
						) {
							if (cse.ContactId != null && cse.AccountId != null) {
								map_OrderCases_IntroEmail_IntuitQuickBook.put(orderObj, cse);
								cse.X2_Business_Days_From_Last_Notification__c = dateAfterTwoBusinessDays;
							} else {
								cse.Error_Message__c = ERROR_MESSAGE_MISSING_CONTACT_ACCOUNT;
							}
						}

						//for "QuickBooks Desktop" both emails will be sent
						if (
							orderObj.Previous_Payroll_Provider__c == 'QuickBooks Desktop' ||
							orderObj.Team_Invitation_Preference__c == null ||
							OrderUtils.PT_TEAM_INVITATION_PREFERENCE.indexOf(orderObj.Team_Invitation_Preference__c.toLowerCase()) < 0
						) {
							cse.Order_Notification__c = 'Intro Email - IOP/QBOI';
							cse.X2_Business_Days_From_Last_Notification__c = dateAfterTwoBusinessDays;
						}

						map_ToUpdateCases.put(cse.Id, cse);
					} else if (
						oldOrder != null &&
						orderObj.Bulk_Migration__c == null &&
						orderObj.OwnerId != oldOrder.OwnerId &&
						string.valueOf(oldOrder.OwnerId).startsWith('00G') &&
						string.valueOf(orderObj.OwnerId).startsWith('005') &&
						cse.Order__r.Transition_to_Fulfillment__r.Exception_Request__c == 'Yes' &&
						(cse.Account.Tier__c != ACCOUNT_TIER_SELECT &&
						cse.Account.Tier__c != ACCOUNT_TIER_PREMIUM)
					) {
						cse.Order_Notification__c = 'Intro Email - Exception Request';
						cse.X2_Business_Days_From_Last_Notification__c = dateAfterTwoBusinessDays;
						map_ToUpdateCases.put(cse.Id, cse);
					} else if (
						oldOrder != null &&
						orderObj.Bulk_Migration__c == null &&
						orderObj.OwnerId != oldOrder.OwnerId &&
						string.valueOf(oldOrder.OwnerId).startsWith('00G') &&
						string.valueOf(orderObj.OwnerId).startsWith('005') &&
						((autoAssignedGlobal == true &&
						orderObj.Previous_Payroll_Provider__c != 'QuickBooks Online' &&
						orderObj.Previous_Payroll_Provider__c != 'Intuit Online Payroll' &&
						orderObj.Previous_Payroll_Provider__c != 'QuickBooks Desktop' &&
						orderObj.Previous_Payroll_Provider__c != null) || autoAssignedGlobal == false) &&
						(cse.Account.Tier__c != ACCOUNT_TIER_SELECT &&
						cse.Account.Tier__c != ACCOUNT_TIER_PREMIUM)
					) {
						cse.Order_Notification__c = 'Intro Email';
						cse.X2_Business_Days_From_Last_Notification__c = dateAfterTwoBusinessDays;
						map_ToUpdateCases.put(cse.Id, cse);
					}

					if (oldOrder != null && OrderObj.Status != oldOrder.Status && orderObj.Status == 'Account Approved') {
						cse.Order_Notification__c = 'Post Risk Approval';
						cse.X2_Business_Days_From_Last_Notification__c = dateAfterTwoBusinessDays;
						map_ToUpdateCases.put(cse.Id, cse);
					}

					if (
						oldOrder != null &&
						OrderObj.Status != oldOrder.Status &&
						orderObj.Status == ORDER_STATUS_CLOSEDPAYROLLRUN &&
						(cse.account.Tier__c == null || (cse.account.Tier__c != ACCOUNT_TIER_CONCIERGE && (cse.account.Tier__c == ACCOUNT_TIER_PLUS && !cse.account.Priority_Support__c)))
					) {
						cse.Order_Notification__c = 'Handoff To Care';
						cse.X2_Business_Days_From_Last_Notification__c = dateAfterTwoBusinessDays;
						map_ToUpdateCases.put(cse.Id, cse);
					} else if (
						oldOrder != null &&
						OrderObj.Status != oldOrder.Status &&
						orderObj.Status == ORDER_STATUS_CLOSEDPAYROLLRUN &&
						cse.account.Tier__c != null &&
						(cse.account.Tier__c == ACCOUNT_TIER_CONCIERGE || cse.account.Tier__c == ACCOUNT_TIER_PLUS && cse.account.Priority_Support__c)
					) {
						cse.Order_Notification__c = 'Handoff To ' + ACCOUNT_TIER_CONCIERGE;
						cse.X2_Business_Days_From_Last_Notification__c = dateAfterTwoBusinessDays;
						map_ToUpdateCases.put(cse.Id, cse);
					}
				}
			}
		}

		if (map_toUpdateNewlyClosedOwnerUpdateCases != null && map_toUpdateNewlyClosedOwnerUpdateCases.size() > 0) {
			map_AllCasesToUpdate.putAll(map_toUpdateNewlyClosedOwnerUpdateCases);
		}

		if (map_ToUpdateCases != null && map_ToUpdateCases.size() > 0) {
			map_AllCasesToUpdate.putAll(map_ToUpdateCases);
		}

		if (map_OrderCases_IntroEmail_IntuitQuickBook.size() > 0) {
			OrderUtils.sendIntroEmail(map_OrderCases_IntroEmail_IntuitQuickBook);
		}

		if (map_AllCasesToUpdate != null && map_AllCasesToUpdate.size() > 0) {
			boolean previousValue = CaseTriggerHelper.skipTrigger;
			boolean blnPrevTaskTriggerSkipValue = TaskTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;
			TaskTriggerHelper.skipTrigger = true;

			try {
				update map_AllCasesToUpdate.values();
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'OrderTriggerHelper',
					'updateCaseStatus_OwnerAndOrderNotifications',
					objException.getMessage(),
					objException.getStackTraceString() +
					'. line number: ' +
					objException.getLineNumber()
				);
			}

			CaseTriggerHelper.skipTrigger = previousValue;
			TaskTriggerHelper.skipTrigger = blnPrevTaskTriggerSkipValue;
		}
	}

	/*By: PR, Date: Oct/18/2019,
    Desc: This method will be called from a Scheduled job. In this method we will update the "Order Notification" field on Case
    with "Payroll Run", for those Cases that have "Payroll Run Date" == Today.   
    
    Last Mod: PR, Date: Nov,18,2019
    Desc: we have converted this method to a future method to resolve the "CPU timelimit" issue we were facing when this method is called from Scheduler class*/
	@future
	public static void updateOrderNotificationOnCase() {
		list<Case> lst_toUpdateCases = new List<Case>();
		for (Case caseRec : [
			SELECT Id, Order_Payroll_Run_Date__c, Order_Notification__c
			FROM Case
			WHERE
				Status != 'Closed'
				AND Integration_Key__c != NULL
				AND origin = 'Panda'
				AND Order__c != NULL
				AND Order__r.Bulk_Migration__c = NULL
				AND Order__r.Payroll_Run_Date__c = TODAY
				AND Order__r.Status NOT IN ('Payroll Submitted', 'Closed: Payroll Run', 'Closed: Canceled')
				AND Order__r.Status IN :set_PayrollRunEmailEligibleStatuses
			FOR UPDATE
		]) {
			caseRec.Order_Notification__c = 'Run Payroll';
			lst_toUpdateCases.add(caseRec);
		}

		if (lst_toUpdateCases.size() > 0) {
			try {
				boolean previousval = CaseTriggerHelper.skipTrigger;
				boolean previousValTask = TaskTriggerHelper.skipTrigger;
				boolean previousValEM = EmailMessageTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;
				TaskTriggerHelper.skipTrigger = true;
				EmailMessageTriggerHelper.skipTrigger = true;

				update lst_toUpdateCases;

				CaseTriggerHelper.skipTrigger = previousval;
				TaskTriggerHelper.skipTrigger = previousValTask;
				EmailMessageTriggerHelper.skipTrigger = previousValEM;
			} catch (exception ex) {
			}
		}
	}

	/*By: PR, Date: Oct/23/2019, 
    Desc: This method will be called from a Scheduled job. In this method we will update the "Order Notification" field on Case
    with "Final Step Not Completed", for those Cases that have "ORder.Stage_Change_Date_Time__c" <= two days  */
	public static void UpdateOrderNotificationForFinalStepOnCase() {
		list<Case> lst_toUpdateCases = new List<Case>();
		List<BusinessHours> listBusinessHours = [SELECT Id, TimeZoneSidKey, IsDefault FROM BusinessHours WHERE name = 'Gusto - Denver'];

		if (listBusinessHours.size() > 0) {
			long twoDaysInMilliSecond = 2 * 8 * 60 * 60 * 100;
			Datetime twoWorkingDaysOldDatetime = BusinessHours.add(listBusinessHours[0].Id, system.today(), -twoDaysInMilliSecond);

			for (Case caseRec : [
				SELECT Id, Order_Payroll_Run_Date__c, Order_Notification__c
				FROM Case
				WHERE
					Status != 'Closed'
					AND Integration_Key__c != NULL
					AND origin = 'Panda'
					AND Order__c != NULL
					AND Order__r.Bulk_Migration__c = NULL
					AND Order__r.Stage_Change_Date_Time__c <= :twoWorkingDaysOldDatetime
					AND (Order__r.Status = 'Onboarding Steps 8 - 9'
					OR Order__r.Status = 'Onboarding Step 10')
				FOR UPDATE
			]) {
				caseRec.Order_Notification__c = 'Final Step Not Completed';
				lst_toUpdateCases.add(caseRec);
			}
		}

		if (lst_toUpdateCases.size() > 0) {
			try {
				boolean previousval = CaseTriggerHelper.skipTrigger;
				boolean previousValTask = TaskTriggerHelper.skipTrigger;
				boolean previousValEM = EmailMessageTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;
				TaskTriggerHelper.skipTrigger = true;
				EmailMessageTriggerHelper.skipTrigger = true;

				update lst_toUpdateCases;

				CaseTriggerHelper.skipTrigger = previousval;
				TaskTriggerHelper.skipTrigger = previousValTask;
				EmailMessageTriggerHelper.skipTrigger = previousValEM;
			} catch (exception ex) {
			}
		}
	}

	public static void populateOrderOnMatchingOpportunities(List<Order> newOrdersList, Map<Id, Order> oldOrderMap) {
		Set<Id> accountIdSet = new Set<Id>();
		for (Order ord : newOrdersList) {
			accountIdSet.add(ord.AccountId);
		}

		Id companyRecordTypeId = idOpportunity_RT_Company;
		// Query all open opportunities where record type = company opportunity and Company_Migration__c is blank
		// Yuvraj 29-06-2020 : Added Benefits_List__c in query
		Map<Id, Account> accounWithOppMap = new Map<Id, Account>(
			[
				SELECT
					Id,
					Name,
					Benefits_List__c,
					(SELECT Id, Order_Status__c, Order__c, AccountId FROM Opportunities WHERE isWon = FALSE AND (RecordTypeId = :companyRecordTypeId OR RecordTypeId = :idAcquisitionRecordType))
				FROM Account
				WHERE Id IN :accountIdSet
			]
		); //AND Order__c = null //BY:PR, Date: June/11/2020, Desc: https://app.asana.com/0/1174533066073284/1176388309449401/f

		List<Opportunity> toBeUpdatedOppList = new List<Opportunity>();
		List<Account> list_accountToUpdate = new List<Account>(); //Yuvraj 29-06-2020
		for (Order ord : newOrdersList) {
			if (ord.AccountId != null && accounWithOppMap.containsKey(ord.AccountId)) {
				//Yuvraj 29-06-2020 - To sync benefit list value from order to account.
				Account objAccount = accounWithOppMap.get(ord.AccountId);
				if (String.isNotBlank(ord.Benefits_List__c)) {
					objAccount.Benefits_List__c = ord.Benefits_List__c;
					list_accountToUpdate.add(objAccount);
				}

				for (Opportunity opp : accounWithOppMap.get(ord.AccountId).Opportunities) {
					//BY:PR, Date: June/11/2020, Desc: https://app.asana.com/0/1174533066073284/1176388309449401/f
					if (opp.Order__c != null && Utils.setOrderExclude.contains(opp.Order_Status__c)) {
						opp.Order__c = ord.Id;
					} else if (opp.Order__c == null) {
						opp.Order__c = ord.Id; //inset it when we have a new insert in update we already have a order on opp
					}

					if (ord.Xero_Migration_Selection__c != null && ord.Xero_Migration_Selection__c != '')
						opp.Xero_Migration_Selection__c = ord.Xero_Migration_Selection__c;

					toBeUpdatedOppList.add(opp);
				}
			}
		}
		if (toBeUpdatedOppList.size() > 0) {
			Map<String, String> errorOppMap = Utils.doDMLAndReturnAllErrors(
				'Update', // type of DML operation
				'AccountId', // Return map key
				toBeUpdatedOppList, // sObject list
				false, // all or none flag
				true, // log the error
				'OrderTriggerHelper-populateOrderOnMatchingOpportunities'
			);
			// if there are any errors, show them on the screen
			for (Order ord : newOrdersList) {
				if (errorOppMap.containsKey(ord.AccountId)) {
					ord.addError(errorOppMap.get(ord.AccountId));
				}
			}
		}

		if (list_accountToUpdate.size() > 0) {
			Boolean blnskiAccTrigger = AccountTriggerHelper.skipTrigger;
			AccountTriggerHelper.skipTrigger = true; //Yuvraj 16-07-2020 - Skip account trigger set as true
			try {
				update list_accountToUpdate;
			} catch (Exception ex) {
				ExceptionLogUtil.logException('OrderTriggerHelper', 'populateOrderOnMatchingOpportunities', ex.getMessage(), 'High');
			}
			AccountTriggerHelper.skipTrigger = blnskiAccTrigger; //Yuvraj 16-07-2020 - Skip account trigger set as false
		}
	}

	public void updateBMRonRelatedOpportunityAndAccount(list<Order> lst_orders) {
		if (lst_orders == null || lst_orders.size() == 0) {
			return;
		}

		map<id, Opportunity> map_toUpdateOppIdRecord = new Map<Id, Opportunity>();
		map<id, Account> map_toUpdateAccIdRecord = new Map<Id, Account>();

		for (Order o_obj : lst_orders) {
			if (o_obj.OpportunityId != null) {
				map_toUpdateOppIdRecord.put(o_obj.OpportunityId, new Opportunity(id = o_obj.OpportunityId, Bulk_Migration__c = o_obj.Bulk_Migration__c));
			}
			if (o_obj.AccountId != null) {
				map_toUpdateAccIdRecord.put(o_obj.AccountId, new Account(id = o_obj.AccountId, Bulk_Migration__c = o_obj.Bulk_Migration__c));
			}
		}

		try {
			if (map_toUpdateOppIdRecord.values().size() > 0) {
				boolean oldValue = OpportunityTriggerHelper.skipTrigger;
				OpportunityTriggerHelper.skipTrigger = true;
				update map_toUpdateOppIdRecord.values();
				OpportunityTriggerHelper.skipTrigger = oldValue;
			}

			if (map_toUpdateAccIdRecord.values().size() > 0) {
				boolean oldValue = AccountTriggerHelper.skipTrigger;
				AccountTriggerHelper.skipTrigger = true;
				update map_toUpdateAccIdRecord.values();
				AccountTriggerHelper.skipTrigger = oldValue;
			}
		} catch (exception ex) {
		}
	}

	//Written By AKS dated 14th Oct 2019
	//Update Bulk Migration depending upon related orders
	public static void UpdateOrderBulkMigrationRequest(Set<Id> setBulkMigrationId) {
		String query = 'SELECT Id, First_Check_Date__c, Facilitator_Due_Date__c, OrderNumber, OpportunityId, Opportunity.Amount, Opportunity.StageName,';
		query = query + ' Opportunity.IsClosed, Opportunity.IsWon, Status, Bulk_Migration__c, Big_Desk_Sandbox_Type__c ';
		query = query + '  FROM Order WHERE Bulk_Migration__c!=null';

		if (setBulkMigrationId != null && setBulkMigrationId.size() > 0) {
			query = query + '  AND Bulk_Migration__c IN :setBulkMigrationId';
		}
		query = query + ' ORDER BY First_Check_Date__c ASC, Facilitator_Due_Date__c ASC ';

		Map<string, List<Order>> mapMigrationOrder = new Map<string, List<Order>>();
		for (Order od : Database.query(query)) {
			if (mapMigrationOrder.containsKey(od.Bulk_Migration__c) == true) {
				mapMigrationOrder.get(od.Bulk_Migration__c).add(od);
			} else {
				mapMigrationOrder.put(od.Bulk_Migration__c, new List<Order>{ od });
			}
		}
		if (mapMigrationOrder != null && mapMigrationOrder.size() > 0) {
			List<Bulk_Migration_Request__c> lstMigrationUpdate = new List<Bulk_Migration_Request__c>();
			for (string st : mapMigrationOrder.keySet()) {
				integer countClosedPayrollRun = 0;
				integer countClosedOpportunity = 0;
				integer countClosedWonOpportunity = 0;
				integer countCancelledOrders = 0;
				decimal sumTotalOpportunityAmount = 0;
				Bulk_Migration_Request__c mg = new Bulk_Migration_Request__c(id = st);
				//Count Total Client Orders
				mg.Total_Client_Orders__c = mapMigrationOrder.get(st).size();
				Date RequestedDate = null;
				Date dtFirstFaciliatatorDueDate = null;
				Date FinalDate = null;
				String strBigDesk = '';
				for (Order od : mapMigrationOrder.get(st)) {
					if (od.First_Check_Date__c != null) {
						if (RequestedDate == null) {
							RequestedDate = od.First_Check_Date__c;
						}
						//get Last Order date
						FinalDate = mapMigrationOrder.get(st)[mapMigrationOrder.get(st).size() - 1].First_Check_Date__c;
					}

					//BY: PR, Date:Nov-17-2020, Desc: Need to populate first due date
					if (od.Facilitator_Due_Date__c != null && (dtFirstFaciliatatorDueDate == null || dtFirstFaciliatatorDueDate > od.Facilitator_Due_Date__c)) {
						dtFirstFaciliatatorDueDate = od.Facilitator_Due_Date__c;
					}
					//Count Have Run Payroll
					if (od.Status == ORDER_STATUS_CLOSEDPAYROLLRUN) {
						countClosedPayrollRun = countClosedPayrollRun + 1;
					}
					//Count Cancelled Orders
					if (od.Status == ORDER_STATUS_CLOSEDCANCELED) {
						countCancelledOrders = countCancelledOrders + 1;
					}
					//Count Number of Closed Opportunity
					if (od.Opportunity.IsClosed == true) {
						countClosedOpportunity = countClosedOpportunity + 1;
					}
					//Count Number of Closed Won Opportunity
					if (od.Opportunity.IsClosed == true && od.Opportunity.IsWon == true) {
						countClosedWonOpportunity = countClosedWonOpportunity + 1;
					}
					//Count Number of Closed Won Opportunity
					if (od.Opportunity.Amount != null) {
						sumTotalOpportunityAmount = sumTotalOpportunityAmount + od.Opportunity.Amount;
					}

					if (String.isNotBlank(od.Big_Desk_Sandbox_Type__c)) {
						strBigDesk = od.Big_Desk_Sandbox_Type__c;
					}
				}
				//Update Requested First Check Date and Final Check Date  dated 18th oct 2019
				//Get All order of that migration and get min First check date of order and update Requested First Check Date
				//Max First chek date to Final Check Date in bulk migration
				mg.Requested_First_Check_Date__c = RequestedDate;
				mg.Final_Check_Date__c = FinalDate;
				mg.First_Facilitator_Due_Date__c = dtFirstFaciliatatorDueDate;

				mg.Total_Amount__c = sumTotalOpportunityAmount;
				mg.Have_Run_Payroll__c = countClosedPayrollRun;
				mg.Number_of_Closed_Opportunities__c = countClosedOpportunity;
				mg.Total_Closed_Won_MRR__c = countClosedWonOpportunity;
				mg.Total_Cancelled_Orders__c = countCancelledOrders;
				mg.Big_Desk_Sandbox_Type__c = strBigDesk;
				lstMigrationUpdate.add(mg);
			}
			if (lstMigrationUpdate != null && lstMigrationUpdate.size() > 0) {
				BulkMigrationRequestTriggerHelper.skipTrigger = true;
				update lstMigrationUpdate;
				BulkMigrationRequestTriggerHelper.skipTrigger = false;
			}
		}
	}

	public void updateTransitionToFulfillmentOnOrder(list<Order> orderList) {
		set<id> opportunityIdSet = new Set<id>();
		list<Order> eligibleOrderList = new List<order>();
		map<id, Transition_to_Fulfillment__c> oppIdTransitionRecMap = new Map<id, Transition_to_Fulfillment__c>();
		for (order rec : orderList) {
			if (rec.Transition_to_Fulfillment__c == null && rec.OpportunityId != null) {
				opportunityIdSet.add(rec.OpportunityId);
				eligibleOrderList.add(rec);
			}
		}

		if (opportunityIdSet.size() > 0) {
			string parollTransferRecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
			for (Transition_to_Fulfillment__c rec : [
				SELECT id, Opportunity__c
				FROM Transition_to_Fulfillment__c
				WHERE Opportunity__c IN :opportunityIdSet AND RecordTypeId = :parollTransferRecordTypeId
			]) {
				oppIdTransitionRecMap.put(rec.Opportunity__c, rec);
			}

			for (order rec : eligibleOrderList) {
				if (oppIdTransitionRecMap.containsKey(rec.OpportunityId)) {
					rec.Transition_to_Fulfillment__c = oppIdTransitionRecMap.get(rec.OpportunityId).id;
				}
			}
		}
	}

	/* -- Author: Rahul Joshi.
          Date: Jan 8th, 2019.
          Jira: BT-3545
          Desc: Process Builder: 'Track Order Stage Change History' is failing. Below code is to  
                replace the functionalty in Process Builder (Criterion Name: Status Change).
       -- */
	public void updateStageChangeDateTime(Map<ID, Order> oldOrderMap, List<Order> newOrdersList) {
		for (Order newOrderObj : newOrdersList) {
			// If Status changed, create a record in Order_Status_Change_History__c.
			if (newOrderObj.Status != oldOrderMap.get(newOrderObj.Id).Status) {
				newOrderObj.Stage_Change_Date_Time__c = System.now();
			}
			//BY:PR, Date: Desc/10/2020, Desc: If Facilitator status changed, update date/time val
			if (newOrderObj.Checklist_Status__c != oldOrderMap.get(newOrderObj.Id).Checklist_Status__c) {
				newOrderObj.Checklist_Status_Change_Date_Time__c = System.now();
			}
		}
	}

	/* -- Author: Rahul Joshi.
          Date: Jan 8th, 2019.
          Jira: BT-3545
          Desc: Process Builder: 'Track Order Stage Change History' is failing. Below code is to replace
                the functionalty in Process Builder (Criterion Name: Stage Changed And Date is not empty).
       -- */
	static boolean blnhasStatusChangeProcessed = false;
	public void createOrderStatusChangeHistory(Map<ID, Order> map_oldOrders, List<Order> list_NewOrders) {
		List<Order_Status_Change_History__c> list_ordStatuChangeHist = new List<Order_Status_Change_History__c>();

		for (Order objNewOrder : list_NewOrders) {
			blnhasStatusChangeProcessed = false;
			// If Status changed And Date is not empty, create a record in Order_Status_Change_History__c.
			if (
				((objNewOrder.Status != map_oldOrders.get(objNewOrder.Id).Status && objNewOrder.Stage_Change_Date_Time__c != null) ||
				(objNewOrder.Checklist_Status__c != map_oldOrders.get(objNewOrder.Id).Checklist_Status__c &&
				map_oldOrders.get(objNewOrder.Id).Checklist_Status__c != null &&
				objNewOrder.Checklist_Status_Change_Date_Time__c != null)) && !blnhasStatusChangeProcessed
			) {
				blnhasStatusChangeProcessed = true;

				Order_Status_Change_History__c objOSCHRec = new Order_Status_Change_History__c();
				objOSCHRec.Order__c = objNewOrder.Id;
				objOSCHRec.End_Time__c = System.now();

				if (objNewOrder.Status != map_oldOrders.get(objNewOrder.Id).Status) {
					//Commented by AKS dated 7th oct 2019 to populate from date of history
					objOSCHRec.Start_Time__c = map_oldOrders.get(objNewOrder.Id).Stage_Change_Date_Time__c;
					objOSCHRec.Status_Type__c = 'Order Status';
					objOSCHRec.From_Status__c = map_oldOrders.get(objNewOrder.Id).Status;
					objOSCHRec.To_Status__c = objNewOrder.Status;
				} else {
					objOSCHRec.Start_Time__c = map_oldOrders.get(objNewOrder.Id).Checklist_Status_Change_Date_Time__c;
					objOSCHRec.Status_Type__c = 'Checklist Status';
					objOSCHRec.From_Status__c = map_oldOrders.get(objNewOrder.Id).Checklist_Status__c;
					objOSCHRec.To_Status__c = objNewOrder.Checklist_Status__c;
				}

				list_ordStatuChangeHist.add(objOSCHRec);
			}
		}

		if (list_ordStatuChangeHist.size() > 0) {
			insert list_ordStatuChangeHist;
		}
	}
	/*
        By: Gaurav Khare
        Date: Apr 26, 2019
        Desc: Update Bulk MigrationObject : On Order Update:Check if Order has Bulk Migration Id - query orders and 
        get all Orders associated with this migration Id.Iterate over all those orders and check -> if status for ALL orders 
        is ‘Closed: Payroll Run’ OR ‘Closed: Canceled’ - Update Bulk Migration object status to - ‘Completed’. 
        But if there is even a single order with any different status - NO ACTION NEEDED.

        By: PR, Date: Oct 11, 2019, Desc: New = all orders are in ‘assigned’ status 
                                        In Progress = orders are in various onboarding statuses
                                        Closed = all orders have either run payroll or closed/cancelled

    */
	public void updateBulkMigrationObject(Set<Id> bulkMReqIdSet) {
		Map<Id, Bulk_Migration_Request__c> map_BMRIdRecords = new Map<Id, Bulk_Migration_Request__c>();
		Set<Id> set_BulkCaseIds = new Set<Id>();
		Map<Id, Id> map_BMRIdCases = new Map<Id, Id>();

		if (bulkMReqIdSet == null || bulkMReqIdSet.size() == 0) {
			return;
		}

		set<Id> set_bmrIDForDraftOrders = new Set<Id>();
		set<Id> set_bmrIDForOnboardingOrders = new Set<Id>();
		set<Id> set_bmrIDForClosedCancelledOrders = new Set<Id>();

		for (Order orderObj : [SELECT Id, Status, Bulk_Migration__c, Bulk_Migration__r.Bulk_Case__c FROM Order WHERE Bulk_Migration__c IN :bulkMReqIdSet AND Bulk_Migration__c != NULL]) {
			if (orderObj.status == 'Draft' || orderObj.status == 'Sales Submitted' || orderObj.status == 'Sales Follow-up') {
				set_bmrIDForDraftOrders.add(orderObj.Bulk_Migration__c);
			} else if (
				orderObj.status.indexOf('Onboarding') > -1 ||
				orderObj.status == 'Collecting Documents' ||
				orderObj.status == 'Ready for Approval' ||
				orderObj.status == 'Account Approved' ||
				orderObj.status == 'Payroll Submitted' ||
				orderObj.status == 'Assurance RFI' ||
				orderObj.status == 'Activated'
			) {
				set_bmrIDForOnboardingOrders.add(orderObj.Bulk_Migration__c);
			} else if (orderObj.status.indexOf('Closed') > -1) {
				set_bmrIDForClosedCancelledOrders.add(orderObj.Bulk_Migration__c);
			}

			if (orderObj.Bulk_Migration__r?.Bulk_Case__c != null) {
				map_BMRIdCases.put(orderObj.Bulk_Migration__c, orderObj.Bulk_Migration__r.Bulk_Case__c);
			}
		}

		// if size() of complete Orders  =  Size() all orders for a bulkMigReq then mark its status as complete
		for (Id bulkId : bulkMReqIdSet) {
			Bulk_Migration_Request__c bulkObj = new Bulk_Migration_Request__c(id = bulkId);

			if (set_bmrIDForDraftOrders.contains(bulkId) && !set_bmrIDForOnboardingOrders.contains(bulkId) && !set_bmrIDForClosedCancelledOrders.contains(bulkId)) {
				bulkObj.Bulk_Migration_Status__c = 'New';
				map_BMRIdRecords.put(bulkId, bulkObj);
			} else if (!set_bmrIDForDraftOrders.contains(bulkId) && !set_bmrIDForOnboardingOrders.contains(bulkId) && set_bmrIDForClosedCancelledOrders.contains(bulkId)) {
				bulkObj.Bulk_Migration_Status__c = 'Completed';
				map_BMRIdRecords.put(bulkId, bulkObj);

				if (map_BMRIdCases.containsKey(bulkObj.Id) && map_BMRIdCases.get(bulkObj.Id) != null) {
					set_BulkCaseIds.add(map_BMRIdCases.get(bulkObj.Id));
				}
			} else if (set_bmrIDForDraftOrders.contains(bulkId) || set_bmrIDForOnboardingOrders.contains(bulkId) || set_bmrIDForClosedCancelledOrders.contains(bulkId)) {
				bulkObj.Bulk_Migration_Status__c = 'In Progress';
				map_BMRIdRecords.put(bulkId, bulkObj);
			}
		}
		if (map_BMRIdRecords.values().size() > 0) {
			BulkMigrationRequestTriggerHelper.skipTrigger = true;
			update map_BMRIdRecords.values();
			BulkMigrationRequestTriggerHelper.skipTrigger = false;

			if (set_BulkCaseIds.size() > 0) {
				BulkMigrationRequestTriggerHelper BMRController = new BulkMigrationRequestTriggerHelper();
				BMRController.updateRelatedCaseStatus(set_BulkCaseIds);
			}
		}
	}

	/*
     * By: Neha 31 Oct 2019, 1)To Update Original Check date for the first time
                             2)Update Pay Date fields on Requested pay date extended button operation
     */
	public void setOriginalCheckDateAndCalculatePayDateFields(List<Order> lst_Orders, Map<Id, Order> map_OldOrders) {
		for (Order objOrder : lst_Orders) {
			//set Original Check Date only for the first time
			if (null == objOrder.Original_Check_Date__c && null != objOrder.First_Check_Date__c) {
				objOrder.Original_Check_Date__c = objOrder.First_Check_Date__c;
			}
			//CLear Pay Date Fields if reason is Clerical Error and FirstCheckDate is set back to Original CheckDate
			if (objOrder.Pay_Date_Extension_Reason__c == 'Clerical Error' && objOrder.Original_Check_Date__c == objOrder.First_Check_Date__c && objOrder.Pay_Date_Extension_count__c > 0) {
				objOrder.Pay_Date_Extension_days__c = 0;
				objOrder.Pay_Date_Extension_count__c = 0;
			}

			Order objOldOrder;
			if (null != map_OldOrders && map_OldOrders.containsKey(objOrder.Id)) {
				objOldOrder = map_OldOrders.get(objOrder.Id);
			}
			//Calculate Pay Date Fields if reason is not Clerical Error and FirstCheckDate is pushed to a future date
			if (
				objOldOrder != null &&
				objOrder.Pay_Date_Extension_Reason__c != null &&
				objOrder.Pay_Date_Extension_Reason__c != 'Clerical Error' &&
				objOrder.First_Check_Date__c != objOldOrder.First_Check_Date__c &&
				objOrder.First_Check_Date__c > objOldOrder.First_Check_Date__c
			) {
				decimal extensionDays = (objOrder.Pay_Date_Extension_days__c != null ? objOrder.Pay_Date_Extension_days__c : 0);
				extensionDays += decimal.valueof(objOldOrder.First_Check_Date__c.daysBetween(objOrder.First_Check_Date__c));
				objOrder.Pay_Date_Extension_days__c = extensionDays;

				decimal extensionCount = (objOrder.Pay_Date_Extension_count__c != null ? objOrder.Pay_Date_Extension_count__c : 0);
				objOrder.Pay_Date_Extension_count__c = extensionCount + 1;
			}

			if (
				objOldOrder != null &&
				objOrder.Pay_Date_Extension_Reason__c != null &&
				objOrder.Pay_Date_Extension_Reason__c == 'Clerical Error' &&
				objOrder.First_Check_Date__c != objOldOrder.First_Check_Date__c &&
				objOrder.First_Check_Date__c > objOldOrder.First_Check_Date__c
			) {
				setReadyForFacilitatorDueDate(objOrder);
			}
		}
	}
	/*
	 * By: Neha 31 Oct 2019, To Update Employee count fields on Order BOA Relationship records for orders which have respective values updated
	 */
	public void setEmployeeCountFieldOnBOARelationship(Map<Id, Order> map_BOARelatedCountsToBeUpdated) {
		Set<Id> setOrderId = new Set<Id>(map_BOARelatedCountsToBeUpdated.keySet());
		String strBOARelQuery = 'SELECT Contractor_Count__c,Inactive_Employee_Count__c,Order_Employee_Count__c, Orders__c FROM Order_BOA_Relationship__c WHERE Orders__c IN :setOrderId';

		List<Order_BOA_Relationship__c> lstOrderBOARelationship = Database.query(strBOARelQuery);

		if (lstOrderBOARelationship.size() > 0) {
			if (lstOrderBOARelationship.size() > 0) {
				boolean previousVal = OrderBOARelationshipTriggerHelper.skipTrigger;
				OrderBOARelationshipTriggerHelper.skipTrigger = true;
				update lstOrderBOARelationship;
				OrderBOARelationshipTriggerHelper.skipTrigger = previousVal;
			}
		}
	}

	private Map<Id, Bulk_Migration_Request__c> getBulkMigrations(Set<Id> set_BMRIds) {
		if (!set_BMRIds.isEmpty()) {
			return new Map<Id, Bulk_Migration_Request__c>([SELECT Id, Facilitator__c, OwnerId FROM Bulk_Migration_Request__c WHERE Id IN :set_BMRIds]);
		}

		return new Map<Id, Bulk_Migration_Request__c>();
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Generate the Week Number from First Check Date
	 * @Parm        : objOrder - New Order
	 * @Return      : N/A
	 **/
	public void calcWeekNumberForFirstCheckDate(Order objOrder) {
		Map<String, Integer> map_WeekDay = new Map<String, Integer>{ 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6, 'Sun' => 7 };
		Map<Integer, Integer> map_WeekDayNextVal = new Map<Integer, Integer>{ 1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 1, 6 => 1, 7 => 1 };

		Date dtWeekStartDate;
		Date dtWeekEndDate;

		Date dtFirstCheckDate = objOrder.First_Check_Date__c;
		Integer intFirstCheckDateMon = dtFirstCheckDate.month();
		Integer intFirstCheckDateYear = Integer.valueOf(dtFirstCheckDate.year());
		// First day of selected month
		Date dtFirstDay = Date.newInstance(intFirstCheckDateYear, intFirstCheckDateMon, 1);
		Date dtStartDateOfMonth = dtFirstDay;
		// Last day of selected month
		Integer intDaysInMon = Date.daysInMonth(intFirstCheckDateYear, intFirstCheckDateMon);
		Date dtLastDay = Date.newInstance(intFirstCheckDateYear, intFirstCheckDateMon, intDaysInMon);
		Date dtEndDateOfMonth = dtLastDay;

		DateTime fdDateTime = DateTime.newInstance(dtFirstDay, Time.newInstance(0, 0, 0, 0));
		String strDayOfWeek = fdDateTime.format('E'); // day of week for 1st day ie. Mon,Tue,Wed etc

		Integer intWkDay = map_WeekDay.get(strDayOfWeek); // day of week value ie. 1,2,3...etc
		Integer intIndex = 0, intWkNumber = 1; //intIndex is used to identify start of a week and count for no. of working days in a week

		// if 1st day of month is a weekend then start with first monday of that month
		if (intWkDay > 5) {
			Integer intDaysToNxtMonday = 7 - intWkDay + 1;
			intWkDay = 1;
			dtFirstDay = dtFirstDay.addDays(intDaysToNxtMonday);
		}
		// loop iterates till end of month
		while (dtFirstDay <= dtLastDay) {
			if (intIndex == 0 && intWkDay < 6) {
				//WeekStart
				dtWeekStartDate = dtFirstDay;
			}
			//current day is friday or last day of month
			if (intwkDay == 5 || dtFirstDay == dtLastDay) {
				dtWeekEndDate = dtFirstDay;
				// Check First Check date fall under this week if yes the come out of this loop else iterate next week
				if (dtWeekStartDate != null && dtWeekEndDate != null && dtWeekStartDate <= dtFirstCheckDate && dtWeekEndDate >= dtFirstCheckDate) {
					//Update order week number here and break the iteration
					objOrder.First_Check_Date_Week_Number__c = intWkNumber;
					break;
				} else {
					// Re initialize loop variables for next week
					intWkNumber++;
					intIndex = 0;
					intwkDay = 1;
					dtFirstDay = Date.newInstance(dtFirstDay.year(), dtFirstDay.month(), dtFirstDay.day() + 3);
				}
			} else {
				intIndex++;
				dtFirstDay = Date.newInstance(dtFirstDay.year(), dtFirstDay.month(), dtFirstDay.day() + 1);
				intwkDay = map_WeekDayNextVal.get(intwkDay);
			}
		}
	}

	/*
	 * @Author      : Pravesh Rana
	 * @Description : Send reminder email to sales team for TTF Submission
	 * @Parm        : list_Orders [Eligible Orders]
	 * @Return      : N/A
	 */
	public void sendSubmitTTFNotification(List<Order> list_Orders) {
		String EMAIL_TEMPLATE_NAME = 'Payroll_Transfer_Submit_TTF_Reminder';
		Map<String, EmailTemplate> map_TemplateNameRecords = new Map<String, EmailTemplate>();
		Map<Id, Messaging.SingleEmailMessage> map_OrderIdEmailMessageInstances = new Map<Id, Messaging.SingleEmailMessage>();
		Map<Id, EmailMessage> map_OpportunityOwnerIdsEmailMessageToInsert = new Map<Id, EmailMessage>();
		Set<Id> set_ErroredTargetObjectIds = new Set<Id>();

		if (list_Orders?.size() > 0) {
			Set<Id> set_OpportunityIds = new Set<Id>();
			for (Order objOrder : list_Orders) {
				set_OpportunityIds.add(objOrder.OpportunityId);
			}

			//Querying Email Templates related to Advising Email
			for (EmailTemplate objET : [SELECT Id, Subject, DeveloperName, Name FROM EmailTemplate WHERE DeveloperName = :EMAIL_TEMPLATE_NAME]) {
				map_TemplateNameRecords.put(objET.DeveloperName, objET);
			}

			list<OrgWideEmailAddress> list_OrgWideAddresses = GlobalQueryHelper.getOrgWideEmailByAdd(OrderUtils.PT_DEFAULT_EMAIL_ADDRESS);
			Map<Id, Opportunity> map_Opportunities = new Map<Id, Opportunity>([SELECT ID, OwnerId FROM Opportunity WHERE Id IN :set_OpportunityIds]);

			for (Order objOrder : list_Orders) {
				try {
					EmailTemplate objEmailTemplate = map_TemplateNameRecords.get(EMAIL_TEMPLATE_NAME);

					//code for OutboundEmail instance creation---------starts-----------
					Messaging.SingleEmailMessage objMail = Messaging.renderStoredEmailTemplate(objEmailTemplate.Id, map_Opportunities.get(objOrder.OpportunityId).OwnerId, objOrder.OpportunityId);
					objMail.setUseSignature(false);
					objMail.setSaveAsActivity(false);

					if (list_OrgWideAddresses?.size() > 0) {
						objMail.setOrgWideEmailAddressId(list_OrgWideAddresses.get(0).Id);
					}
					map_OrderIdEmailMessageInstances.put(objOrder.Id, objMail);

					//code for Email Message instance creation---------starts-----------
					EmailMessage objMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
					objMsg.ToAddress = map_Opportunities.get(objOrder.OpportunityId).OwnerId;
					objMsg.Subject = objEmailTemplate.Subject;
					objMsg.RelatedToId = objOrder.Id;
					objMsg.ParentId = objOrder.Case__c;
					objMsg.MessageDate = System.now();
					objMsg.Status = '3';
					objMsg.Email_Template_Name__c = objEmailTemplate.DeveloperName;
					objMsg.FromName = OrderUtils.PT_DEFAULT_EMAIL_ADDRESS;
					objMsg.FromAddress = OrderUtils.PT_DEFAULT_EMAIL_ADDRESS;
					map_OpportunityOwnerIdsEmailMessageToInsert.put(map_Opportunities.get(objOrder.OpportunityId).OwnerId, objMsg);
				} catch (Exception objExeption) {
					ExceptionLogUtil.logException(
						'OrderTriggerHelper',
						'sendTTFSubmitNotification',
						objExeption.getMessage() +
						' ON Line ' +
						objExeption.getLineNumber(),
						objExeption.getStackTraceString()
					);
				}
			}

			if (map_OrderIdEmailMessageInstances.size() > 0) {
				Messaging.SendEmailResult[] list_objResults;
				if (!Test.isRunningTest()) {
					list_objResults = Messaging.sendEmail(map_OrderIdEmailMessageInstances.values(), false);
				}

				//Outbound Email error handling code
				if (list_objResults != null) {
					for (Messaging.SendEmailResult objResult : list_objResults) {
						if (!objResult.isSuccess() && !Test.isRunningTest()) {
							set_ErroredTargetObjectIds.add(objResult.getErrors().get(0).getTargetObjectId());
						}
					}
				}

				//making sure that we are not creating "Email Message" reccords for failed emails
				for (Order objOrder : list_Orders) {
					Opportunity objOpp = map_Opportunities.get(objOrder.OpportunityId);
					if (objOpp.OwnerId != null && set_ErroredTargetObjectIds?.contains(objOpp.OwnerId)) {
						map_OpportunityOwnerIdsEmailMessageToInsert.remove(objOpp.OwnerId);
					} else {
						//updating email body on email message
						map_OpportunityOwnerIdsEmailMessageToInsert.get(objOpp.OwnerId).HtmlBody = map_OrderIdEmailMessageInstances.get(objOrder.Id).getHtmlBody();
					}
				}

				//Creating Email Message
				if (map_OpportunityOwnerIdsEmailMessageToInsert.size() > 0) {
					insert map_OpportunityOwnerIdsEmailMessageToInsert.values();
				}
			}
		}
	}
}