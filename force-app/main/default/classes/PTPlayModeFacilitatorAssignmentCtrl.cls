/*Class Name    :   PTPlayModeFacilitatorAssignmentCtrl
 *Test Class     :   PTPlayModeFacilitatorAssignmentCtrlTest
 *Created By     :   PR
 *Created Date   :   October-26-2020
 *
 */
public with sharing class PTPlayModeFacilitatorAssignmentCtrl {
	//This variable will contain Order record to be played
	public order objOrderToPlay { get; set; }
	// Count of available workorders for PT based
	public Integer intAvailableOrders { get; set; }
	// Count of facilitator available workorders
	public Integer intMyAvailableOrders { get; set; }
	public Integer intMyBlockedOrders { get; set; }
	//count of fac orders assinged to advocate
	public Integer intAssignToAdvocateOrders { get; set; }
	public Integer intFollowUpDateOrders { get; set; }
	public Boolean blnIsError { get; set; }
	//static string which handles facilitator
	static String strFacilitatorRoleName = 'Payroll Transfer Facilitator';
	static string strOrderStatusClosedCanceled = 'Closed: Canceled';
	static string strOrderStatusClosedPayrollRun = 'Closed: Payroll Run';
	static string strOOOErrorMessage = 'OOO is checked, please uncheck OOO to play orders.';
	static string strOOOAssignmentMessage = 'Out of Office Assignment';
	static final String INCLUDE_BIGDESK_QUERYFILTER = 'PT Play Mode Big Desk';
	static final String EXCLUDE_BIGDESK_QUERYFILTER = 'PT Play Mode Exclude Big Desk';
	static final String BIGDESK = 'BigDesk Order';
	static final String ERROR_NO_NONBLOCKEDORDERS = 'There are no non-blocked orders to play.';
	static final String ERROR_NO_BLOCKEDORDERS = 'There are no blocked orders to play.';
	userSkillsWrapper objUserSkillDetails;
	Id idLoggedInUser = UserInfo.getUserId();
	public Boolean blnIsUserOutOfOffice { get; set; }
	//this map will maintain play mode configuration details
	Map<String, String> map_PlayModeConfigs = new Map<String, String>();
	Map<Date, Benefit_Order_Allocation__c> map_WeekStartDateBOARecord;
	Benefit_Order_Allocation__c objBOAWeekWithCap;

	//variables related to User Skill Filter
	Map<Integer, Order> map_countOrderRec = new Map<Integer, Order>();
	//variables related to User Skill Filter
	Set<string> set_SalesTeam = new Set<string>();
	//variables related to User Skill Filter
	Set<string> set_previousPayroll = new Set<string>();
	//variables related to User Skill Filter
	Set<Boolean> set_Exceptions = new Set<Boolean>();
	//isNonInstaBase
	Boolean blnIsNonInstabase = false;
	//Handle External Order
	Boolean blnExternalOrder = false;
	//variables related to Order Previous Provider Filter for Complexity level mods
	Set<String> set_PreviousPayrollForComplexityLevel = new Set<String>();
	//variables related to Order states Filter for Complexity level mods
	Set<String> set_StatesForComplexityLevel = new Set<String>();
	//variables related to User Skill Filter
	Set<string> set_PartnerTiers = new Set<string>();

	//Payroll Transfer Skills values
	static final String PTS_EXTERNALS = 'Externals';
	static final String METADATA_EXTERNALS = 'PT Play Mode External Order';
	//Reseller Account Record Type Id
	static final String RESELLER_ACCOUNT_REC_TYPE_ID = AccountUtil.RESELLER_ACCOUNT_RT_ID;

	//constructor
	public PTPlayModeFacilitatorAssignmentCtrl() {
		intMyAvailableOrders = 0;
		intMyBlockedOrders = 0;
		intAvailableOrders = 0;
		intAssignToAdvocateOrders = 0;
		intFollowUpDateOrders = 0;
		blnIsError = false;
		map_WeekStartDateBOARecord = new Map<Date, Benefit_Order_Allocation__c>();
		objBOAWeekWithCap = new Benefit_Order_Allocation__c();
		blnIsUserOutOfOffice = false;
		getUserSkills();

		if (
			objUserSkillDetails == null ||
			(objUserSkillDetails.set_IsException.size() == 0 &&
			objUserSkillDetails.set_PreviousProviderType.size() == 0 &&
			objUserSkillDetails.Set_SalesTeam.size() == 0 &&
			objUserSkillDetails.set_TypeOfOrder.size() == 0 &&
			objUserSkillDetails.strComplexityType.length() == 0)
		) {
			ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Logged in user is missing facilitator skills.'));
		} else if (blnIsUserOutOfOffice) {
			ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.INFO, strOOOErrorMessage));
		}
	}

	//Method to check the available orders
	//getting New order is complicated, Also is doc also this feature is "Good To Have"
	public void checkNewOrderCounts() {
		try {
			String strSkillFilter = getUserSkillsQueryFilter();
			List<Order> list_AllEligibleOrders = [
				SELECT Id
				FROM Order
				WHERE
					Data_Entry_Assist__c = NULL
					AND Status NOT IN (:strOrderStatusClosedCanceled, :strOrderStatusClosedPayrollRun)
					AND Assign_Facilitator__c = TRUE
					AND Facilitator_Due_Date__c != NULL
			];
			intAvailableOrders = list_AllEligibleOrders.size();

			checkMYOrderCounts();
			checkMyAssignToAdvocateOrderCounts();
			checkMyOrdersWithFollowUpCounts();
			getUserNextFreeWeeks();
			if (map_WeekStartDateBOARecord.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Facilitator capacity is full.'));
				intAvailableOrders = 0;
			}
		} catch (exception ex) {
			ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Error while querying the count of orders that are ready to be played by the PTs: ' + ex.getMessage()));
			ExceptionLogUtil.logException('PTPlayModeFacilitatorAssignmentCtrl', 'checkNewOrderCounts', ex.getMessage(), ex.getStackTraceString());
		}
	}

	// method is called from "checkNewOrders" function. This method give us count of Orders assigned to logged in Fac and assigned to advocate
	public void checkMyAssignToAdvocateOrderCounts() {
		try {
			Integer strQueryCount = [
				SELECT COUNT()
				FROM Order
				WHERE Data_Entry_Assist__c = :idLoggedInUser AND Assign_to_Advocate__c = TRUE AND Status != :strOrderStatusClosedCanceled AND Status != :strOrderStatusClosedPayrollRun
			];
			intAssignToAdvocateOrders = strQueryCount;
		} catch (exception ex) {
			ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Error while querying facilitator Assign to Advocate Orders :' + ex.getMessage()));
		}
	}

	// method is called from "checkNewOrders" function. This method give us count of Orders assigned to logged in Fac and assigned to advocate
	public void checkMyOrdersWithFollowUpCounts() {
		try {
			Integer strQueryCount = [
				SELECT COUNT()
				FROM Order
				WHERE Data_Entry_Assist__c = :idLoggedInUser AND Facilitator_Follow_Up_Date__c >= TODAY AND Status != :strOrderStatusClosedCanceled AND Status != :strOrderStatusClosedPayrollRun
			];
			intFollowUpDateOrders = strQueryCount;
		} catch (exception ex) {
			ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Error while querying facilitator order with Follow Up dates :' + ex.getMessage()));
		}
	}

	//method is called from constructor. This method queries records which are with Logged In facilitator
	public void checkMYOrderCounts() {
		try {
			map_countOrderRec = new Map<Integer, Order>();
			Integer intCount = 0;
			intMyBlockedOrders = 0;

			//My Order: Owned by- FAC, Assign to Advocate = false, Order BY due date asc and assign to facilitator true first
			for (Order objOrderRec : [
				SELECT Id, Name, Assign_to_Advocate__c, Assign_Facilitator__c, Blocked_Reason__c
				FROM Order
				WHERE
					Data_Entry_Assist__c = :idLoggedInUser
					AND Status != :strOrderStatusClosedCanceled
					AND Status != :strOrderStatusClosedPayrollRun
					AND Assign_to_Advocate__c = FALSE
					AND Checklist_Completed__c = FALSE
					AND (Facilitator_Follow_Up_Date__c = NULL
					OR Facilitator_Follow_Up_Date__c <= TODAY)
				ORDER BY Facilitator_Due_Date__c ASC, EffectiveDate ASC, Total_Active_Inactive_Contract_Count__c DESC
			]) {
				map_countOrderRec.put(intCount, objOrderRec);
				if (String.isNotBlank(objOrderRec.Blocked_Reason__c)) {
					intMyBlockedOrders++;
				}

				intCount++;
			}
			intMyAvailableOrders = map_countOrderRec.size();
		} catch (exception ex) {
			ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Error while querying faciliator orders: ' + ex.getMessage()));
			ExceptionLogUtil.logException('PTPlayModeFacilitatorAssignmentCtrl', 'checkMYOrderCounts', ex.getMessage(), ex.getStackTraceString());
		}
	}

	//Method to AssignFacilitator for orders
	public void playNewOrders() {
		try {
			//Id idFalicitatorRecordType = Schema.SObjectType.Payroll_Transfer_FBOS_Forecast__c.getRecordTypeInfosByName().get('Facilitator').getRecordTypeId();
			Id idFalicitatorRecordType = Cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Facilitator');
			objOrderToPlay = new Order();
			Date dtWeekStartDate;
			List<Order> list_QueriedOrders = new List<Order>();
			String strAssignmentReason = '';

			//for OOO check
			list_QueriedOrders = getQueryString('ooo', null, null);
			if (list_QueriedOrders != null && list_QueriedOrders.size() > 0) {
				for (Order objOrder : list_QueriedOrders) {
					Benefit_Order_Allocation__c temp_objBOAWeekWithCap = getMatchingAllocationRecord(objOrder);
					if (temp_objBOAWeekWithCap != null) {
						objOrderToPlay = objOrder;
						strAssignmentReason = strOOOAssignmentMessage;
						break;
					}
				}
			}

			if (objOrderToPlay.Id == null) {
				list_QueriedOrders = new List<Order>();
				list_QueriedOrders = getQueryString('related bmr', null, null);
				Set<Id> set_RunningUniqueBMRIds = new Set<Id>();
				if (list_QueriedOrders != null && list_QueriedOrders.size() > 0) {
					for (Order objOrder : list_QueriedOrders) {
						if (objOrder.Bulk_Migration__c != null)
							set_RunningUniqueBMRIds.add(objOrder.Bulk_Migration__c);
					}
				}

				//get week with eligible Order
				list_QueriedOrders = new List<Order>();
				for (Order objOrderRec : getQueryString('latest eligible order', null, null)) {
					objBOAWeekWithCap = getMatchingAllocationRecord(objOrderRec);

					if (objBOAWeekWithCap == null || objBOAWeekWithCap.Id == null)
						continue;

					dtWeekStartDate = objBOAWeekWithCap.Week_Start_Date__c;
					break;
				}

				if (dtWeekStartDate != null || set_RunningUniqueBMRIds.size() > 0) {
					list_QueriedOrders = new List<Order>();
					//objBOAWeekWithCap can be null in scenario where user has assigned BMR but has no capacity..  in this we still want to play BMR to the FAC
					list_QueriedOrders = getQueryString('all', set_RunningUniqueBMRIds, objBOAWeekWithCap);
					/*in following logic: out of the orders from the available capacity week if there is any running BMR family order we process it first
					 other wise we process the earliest Order */
					if (list_QueriedOrders != null && list_QueriedOrders.size() > 0) {
						for (Order objOrder : list_QueriedOrders) {
							if (objOrder.Bulk_Migration__c != null && set_RunningUniqueBMRIds.contains(objOrder.Bulk_Migration__c)) {
								objOrderToPlay = objOrder;
								strAssignmentReason = 'Running BMR order assignment';
								break;
							}

							if (objOrderToPlay == null || objOrderToPlay.Id == null) {
								objOrderToPlay = objOrder;
								strAssignmentReason = 'First order available';
							}
						}
					}
				} else {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, ' Facilitator does not have capacity to play orders. Please contact admin to reassign the allocation.'));
				}
			}

			//In the following logic: 1) we are mantaining BOA records for the Order and logged in user 2) updating Assigned to fields on the order
			if (objOrderToPlay != null && objOrderToPlay.Id != null) {
				list<Order> list_AllOrdersToProcess = new List<Order>();
				set<Date> set_weekStartDate = new Set<Date>();

				if (objOrderToPlay.Bulk_Migration__c != null && strAssignmentReason == strOOOAssignmentMessage) {
					list_AllOrdersToProcess = [
						SELECT
							Id,
							Data_Entry_Assist__c,
							Name,
							Assign_to_Advocate__c,
							Assign_Facilitator__c,
							Opportunity_Team__c,
							Bulk_Migration__c,
							Bulk_Migration__r.Facilitator__c,
							Facilitator_Due_Date__c,
							PT_Facilitator_Assignment_Reason__c,
							Blocked_Reason__c
						FROM Order
						WHERE Bulk_Migration__c = :objOrderToPlay.Bulk_Migration__c AND Id != :objOrderToPlay.Id AND Reassign_Facilitator_For_OOO__c = TRUE AND Data_Entry_Assist__c != NULL
					];
				}

				list_AllOrdersToProcess.add(objOrderToPlay);

				if (list_AllOrdersToProcess.size() > 0) {
					handleOrderRelatedUpdatesBeforePlaying(list_AllOrdersToProcess, strAssignmentReason);
				}
			} else {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.ERROR, 'No eligible orders available to play.'));
			}
		} catch (exception ex) {
			ExceptionLogUtil.logException('PTPlayModeFacilitatorAssignmentCtrl', 'playNewOrders', ex.getMessage(), ex.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error while querying the new playable order: ' + ex.getMessage()));
			objOrderToPlay = null;
		}
	}

	//this method gets the list of orders as parameter and sync Order_BOA_Relationship__c records, update Order and BMR records
	public void handleOrderRelatedUpdatesBeforePlaying(list<Order> list_Orders, string strAssignmentReason) {
		if (list_Orders != null && list_Orders.size() > 0) {
			map<Id, Order> map_OrderIdRecords = new Map<Id, Order>();
			set<Date> set_WeekStartDate = new Set<Date>();
			map<Order, Benefit_Order_Allocation__c> map_OrderBOA = new Map<Order, Benefit_Order_Allocation__c>();
			list<Order_BOA_Relationship__c> list_objToInsertOrderBOA = new List<Order_BOA_Relationship__c>();
			list<Order_BOA_Relationship__c> list_objToDeleteOOOFacBOA = new List<Order_BOA_Relationship__c>();

			for (Order objOrder : list_Orders) {
				Benefit_Order_Allocation__c temp_objBOAWeekWithCap = getMatchingAllocationRecord(objOrder);
				if (temp_objBOAWeekWithCap != null) {
					set_WeekStartDate.add(temp_objBOAWeekWithCap.Week_Start_Date__c);
					map_OrderBOA.put(objOrder, temp_objBOAWeekWithCap);
					map_OrderIdRecords.put(objOrder.Id, objOrder);
				}
			}

			if (map_OrderBOA.size() > 0) {
				if (objOrderToPlay.Data_Entry_Assist__c != null && objOrderToPlay.Data_Entry_Assist__c != idLoggedInUser) {
					for (Order_BOA_Relationship__c objBOARelation : [
						SELECT Id, Benefit_Order_Allocation__c, Orders__c
						FROM Order_BOA_Relationship__c
						WHERE
							Orders__c IN :map_OrderIdRecords.keyset()
							AND Benefit_Order_Allocation__r.Role_Type__c = 'Facilitator'
							AND Benefit_Order_Allocation__r.User__c = :objOrderToPlay.Data_Entry_Assist__c
							AND Benefit_Order_Allocation__r.Week_Start_Date__c IN :set_WeekStartDate
					]) {
						list_objToDeleteOOOFacBOA.add(objBOARelation);
					}
				}

				//only need to insert new BOA of EITHER we are assigning the Facilitator for the first time OR Reassigning the Order to a new facilitator
				if (objOrderToPlay.Data_Entry_Assist__c == null || objOrderToPlay.Data_Entry_Assist__c != idLoggedInUser) {
					for (Order objOrder : map_OrderBOA.keyset()) {
						//create order boa relationships
						Order_BOA_Relationship__c objToInsertOrderBOA = new Order_BOA_Relationship__c();
						objToInsertOrderBOA.Orders__c = objOrder.Id;
						objToInsertOrderBOA.Benefit_Order_Allocation__c = map_OrderBOA.get(objOrder).Id;
						list_objToInsertOrderBOA.add(objToInsertOrderBOA);

						objOrder.Data_Entry_Assist__c = idLoggedInUser;
					}

					//In Case of assigning logged in user as FAC to Order we want to create "Order_BOA_Relationship__c"
					if (list_objToInsertOrderBOA.size() > 0 && !test.isRunningTest()) {
						insert list_objToInsertOrderBOA;
					}
				}

				for (Order objOrder : map_OrderBOA.keyset()) {
					objOrder.Assign_Facilitator__c = false;
					objOrder.Assign_to_Advocate__c = false;
					objOrder.Facilitator_Follow_Up_Date__c = null;
					objOrder.Facilitator_Follow_Up_Date_Reason__c = null;
					objOrder.Reassign_Facilitator_For_OOO__c = false;
					objOrder.PT_Facilitator_Assignment_Reason__c = strAssignmentReason;
				}

				list<Order> list_OrdersUpdate = new List<Order>();
				list_OrdersUpdate.addAll(map_OrderBOA.keyset());

				//update the order
				if (list_OrdersUpdate.size() > 0 && !test.isRunningTest()) {
					OrderTriggerHelper.isPayrollTransferAutoAssignment = true;
					update list_OrdersUpdate;
					OrderTriggerHelper.isPayrollTransferAutoAssignment = false;
				}

				if (objOrderToPlay.Bulk_Migration__c != null && (objOrderToPlay.Bulk_Migration__r.Facilitator__c == null || strAssignmentReason == strOOOAssignmentMessage)) {
					Bulk_Migration_Request__c objBMRRecordToUpdate = new Bulk_Migration_Request__c(Id = objOrderToPlay.Bulk_Migration__c);
					objBMRRecordToUpdate.Facilitator__c = idLoggedInUser;

					Boolean blnPreviousVal = BulkMigrationRequestTriggerHelper.skipTrigger;
					BulkMigrationRequestTriggerHelper.skipTrigger = true;
					update objBMRRecordToUpdate;
					BulkMigrationRequestTriggerHelper.skipTrigger = blnPreviousVal;
				}

				//In case of OOO we want to delete "Order_BOA_Relationship__c" of the OOO Facilitator
				if (list_objToDeleteOOOFacBOA != null && list_objToDeleteOOOFacBOA.size() > 0) {
					delete list_objToDeleteOOOFacBOA;
				}

				createOrderTrackerRecord(objOrderToPlay);
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Not able to to find Allocation record for the due date of ' + objOrderToPlay.Facilitator_Due_Date__c));
			}
		}
	}

	//this method is called from Page
	public void playMyOrders() {
		objOrderToPlay = new Order();
		if (map_countOrderRec.size() > 0) {
			if (map_countOrderRec.size() == 1 && String.isBlank(map_countOrderRec.get(0).Blocked_Reason__c)) {
				objOrderToPlay = map_countOrderRec.get(0);
			} else if (map_countOrderRec.size() > 1 && String.isBlank(map_countOrderRec.get(0).Blocked_Reason__c)) {
				objOrderToPlay = map_countOrderRec.get(0);
			} else if (map_countOrderRec.size() > 1 && String.isBlank(map_countOrderRec.get(1).Blocked_Reason__c)) {
				objOrderToPlay = map_countOrderRec.get(1);
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ERROR_NO_NONBLOCKEDORDERS));
			}

			if (objOrderToPlay != null && objOrderToPlay.Id != null) {
				objOrderToPlay.Assign_Facilitator__c = false;
				objOrderToPlay.Facilitator_Follow_Up_Date__c = null;
				objOrderToPlay.Facilitator_Follow_Up_Date_Reason__c = null;
				objOrderToPlay.Reassign_Facilitator_For_OOO__c = false;
				if (!Test.isRunningTest()) {
					update objOrderToPlay;
				}

				createOrderTrackerRecord(objOrderToPlay);
			}
		}
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : This method is called from vf page on clicking Play My Blocked Orders which should play user's order with Blocked Reason.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public void playMyBlockedOrders() {
		objOrderToPlay = new Order();
		if (map_countOrderRec.size() > 0) {
			if (map_countOrderRec.size() == 1 && String.isNotBlank(map_countOrderRec.get(0).Blocked_Reason__c)) {
				objOrderToPlay = map_countOrderRec.get(0);
			} else if (map_countOrderRec.size() > 1 && String.isNotBlank(map_countOrderRec.get(0).Blocked_Reason__c)) {
				objOrderToPlay = map_countOrderRec.get(0);
			} else if (map_countOrderRec.size() > 1 && String.isNotBlank(map_countOrderRec.get(1).Blocked_Reason__c)) {
				objOrderToPlay = map_countOrderRec.get(1);
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ERROR_NO_BLOCKEDORDERS));
			}

			if (objOrderToPlay != null && objOrderToPlay.Id != null) {
				objOrderToPlay.Assign_Facilitator__c = false;
				objOrderToPlay.Facilitator_Follow_Up_Date__c = null;
				objOrderToPlay.Facilitator_Follow_Up_Date_Reason__c = null;
				objOrderToPlay.Blocked_Reason__c = null;
				objOrderToPlay.Reassign_Facilitator_For_OOO__c = false;
				if (!Test.isRunningTest()) {
					update objOrderToPlay;
				}

				createOrderTrackerRecord(objOrderToPlay);
			}
		}
	}

	//=================================Utility Methods===========================Start
	//this method contains query logic for the "Play mode"
	public list<Order> getQueryString(string strType, set<Id> set_BMRIds, Benefit_Order_Allocation__c objBOAWithOpenCap) {
		string strMainQuery = map_PlayModeConfigs.get('PT Play Mode Main Query') + ' ';

		string strOrderBy = ''; //' ORDER BY Facilitator_Due_Date__c ASC,  EffectiveDate ASC, Total_Active_Inactive_Contract_Count__c Desc ';
		string strOOOQuery = ' ' + map_PlayModeConfigs.get('PT Play Mode OOO Query') + ' ';
		string strRunningBMR = ' ' + map_PlayModeConfigs.get('PT Play Mode Running BMR Query') + ' ';
		string strAllOrders = ' ' + map_PlayModeConfigs.get('PT Play Mode All Order Query') + ' ';

		if (string.isBlank(strMainQuery)) {
			strMainQuery =
				' SELECT Id,Data_Entry_Assist__c,Name,Assign_to_Advocate__c,Assign_Facilitator__c,Opportunity_Team__c,Bulk_Migration__c,' +
				' Bulk_Migration__r.Facilitator__c, Facilitator_Due_Date__c,PT_Facilitator_Assignment_Reason__c, Blocked_Reason__c, States__c FROM Order WHERE ';
		}

		if (string.isBlank(strOOOQuery)) {
			strOOOQuery =
				' Data_Entry_Assist__r.Out_Of_Office__c = true AND Reassign_Facilitator_For_OOO__c = true AND Status != \'Closed: Canceled\' AND Status != \'Closed: Payroll Run\'  ' +
				' AND Assign_to_Advocate__c = false AND (Facilitator_Follow_Up_Date__c = null OR Facilitator_Follow_Up_Date__c <= TODAY) && Blocked_Reason__c = null ';
		}

		if (string.isBlank(strRunningBMR)) {
			strRunningBMR = ' Bulk_Migration__c != NULL AND Data_Entry_Assist__c =:idLoggedInUser AND Bulk_Migration__r.Facilitator__c =:idLoggedInUser  ';
		}

		if (string.isBlank(strAllOrders)) {
			strAllOrders = ' Status != \'Closed: Canceled\' AND Status != \'Closed: Payroll Run\' AND Assign_Facilitator__c = true AND (Facilitator_Follow_Up_Date__c = null OR Facilitator_Follow_Up_Date__c <= TODAY) && Blocked_Reason__c = null AND Data_Entry_Assist__c = null AND Facilitator_Due_date__c != null ';
		}

		if (string.isNotBlank(objUserSkillDetails.strOrderByQueryString)) {
			strOrderBy = ' ORDER BY ' + objUserSkillDetails.strOrderByQueryString;
		} else {
			strOrderBy = ' ORDER BY Facilitator_Due_Date__c ASC,  EffectiveDate ASC, Total_Active_Inactive_Contract_Count__c Desc ';
		}

		// filter string based on logged in user skills
		string strSkillFilter = getUserSkillsQueryFilter();

		string strReturn = '';

		//handle OOO scenario
		if (string.isNotBlank(strType) && strType.equalsIgnoreCase('ooo')) {
			strReturn = strMainQuery + strOOOQuery + strSkillFilter + strOrderBy;
		}
		//to handle "related bmr" scenario
		if (string.isNotBlank(strType) && strType.equalsIgnoreCase('related bmr')) {
			strReturn = strMainQuery + strRunningBMR + strSkillFilter + strOrderBy;
		}

		string strAvailableDueDateFilter = '';

		if (string.isNotBlank(strType) && strType.equalsIgnoreCase('latest eligible order') && map_WeekStartDateBOARecord.size() > 0) {
			for (Benefit_Order_Allocation__c objBOA : map_WeekStartDateBOARecord.values()) {
				if (string.isBlank(strAvailableDueDateFilter)) {
					strAvailableDueDateFilter =
						' (Facilitator_Due_Date__c >=' +
						string.valueof(objBOA.Week_Start_Date__c) +
						' AND Facilitator_Due_Date__c <=' +
						string.valueOf(objBOA.Week_End_Date__c) +
						') ';
				} else {
					strAvailableDueDateFilter +=
						' OR (Facilitator_Due_Date__c >=' +
						string.valueof(objBOA.Week_Start_Date__c) +
						' AND Facilitator_Due_Date__c <=' +
						string.valueOf(objBOA.Week_End_Date__c) +
						') ';
				}
			}

			if (string.isNotBlank(strAvailableDueDateFilter)) {
				strAvailableDueDateFilter = ' AND ( ' + strAvailableDueDateFilter + ' ) ';
			}
		}

		//to handle "All" scenario
		if (string.isNotBlank(strType) && strType.equalsIgnoreCase('all')) {
			strReturn = strMainQuery + strAllOrders + strSkillFilter;
			string strBMRLogic = ' ';

			//This means user has the capacity
			if (objBOAWithOpenCap != null && objBOAWithOpenCap.Week_Start_Date__c != null && objBOAWithOpenCap.Week_End_Date__c != null) {
				//If user has capacity then we want to query BMR records that are "between today and capacity week" OR "in capacity week".
				if (set_BMRIds != null && set_BMRIds.size() > 0) {
					strBMRLogic =
						' AND ( (Bulk_Migration__c IN: set_BMRIds AND Facilitator_Due_Date__c >=' +
						string.valueOf(objBOAWithOpenCap.Week_Start_Date__c) +
						' AND Facilitator_Due_Date__c <=' +
						string.valueOf(objBOAWithOpenCap.Week_End_Date__c) +
						' )  ';
					strBMRLogic +=
						' OR ( Bulk_Migration__c IN: set_BMRIds AND Facilitator_Due_Date__c >= ' +
						string.valueOf(System.today()) +
						' AND Facilitator_Due_Date__c < ' +
						string.valueOf(objBOAWithOpenCap.Week_Start_Date__c) +
						' ) ) ';
				}

				list<Order> list_OrderQuery = new List<Order>();

				if (string.isNotBlank(strBMRLogic)) {
					strReturn += strBMRLogic + strOrderBy;
					list_OrderQuery = Database.query(strReturn);
				}

				if (list_OrderQuery.size() > 0) {
					return list_OrderQuery;
				} else {
					// If there are no related BMR to play then play any order from available week based on priority
					strReturn = strMainQuery + strAllOrders + strSkillFilter;
					strBMRLogic =
						' AND (Bulk_Migration__c = null OR Bulk_Migration__r.Facilitator__c = null ) ' +
						//' (Bulk_Migration__r.Facilitator__c = null AND Bulk_Migration__r.First_Facilitator_Due_Date__c != null AND  Bulk_Migration__r.First_Facilitator_Due_Date__c >= '+string.valueOf(objBOAWithOpenCap.Week_Start_Date__c)+')) '+
						' AND Facilitator_Due_Date__c >=' +
						string.valueOf(objBOAWithOpenCap.Week_Start_Date__c) +
						' AND Facilitator_Due_Date__c <=' +
						string.valueOf(objBOAWithOpenCap.Week_End_Date__c) +
						'  ';
				}
			} else if (set_BMRIds != null && set_BMRIds.size() > 0) {
				// In case user does not have the Cap but still have open related BMR we want to play the BMRs to the user
				strBMRLogic = ' AND Bulk_Migration__c IN: set_BMRIds ';
			}

			strReturn += strBMRLogic + strOrderBy;
		}

		//to handle "latest eligible order" scenario
		if (string.isNotBlank(strType) && strType.equalsIgnoreCase('latest eligible order')) {
			strReturn =
				strMainQuery +
				strAllOrders +
				strSkillFilter +
				' AND (Bulk_Migration__c = null OR Bulk_Migration__r.Facilitator__c = null OR Bulk_Migration__r.Facilitator__c =:idLoggedInUser ) ' +
				strAvailableDueDateFilter +
				strOrderBy +
				' '; //strSkillFilter
		}

		if (string.isNotBlank(strReturn)) {
			//Complexity Level States__c field value check
			List<Order> list_Orders = new List<Order>();
			for (Order objOrder : Database.query(strReturn)) {
				if (objUserSkillDetails.set_stateCodes?.size() > 0) {
					if (objUserSkillDetails.set_stateCodes.containsAll(objOrder.States__c.split(';'))) {
						list_Orders.add(objOrder);
					}
				} else {
					list_Orders.add(objOrder);
				}
			}

			return list_Orders;
		}

		return new List<Order>();
	}

	//This method creates "Analytics Time Tracker" object records to mantain "active processing time"
	public void createOrderTrackerRecord(Order objOrder) {
		if (objOrder != null) {
			blnIsError = false;
			list<Analytics_Time_Tracker__c> list_OpenTrackerRec = [
				SELECT Id
				FROM Analytics_Time_Tracker__c
				WHERE CreatedById = :idLoggedInUser AND Order__c = :objOrder.Id AND Start_Date__c != NULL AND End_Date__c = NULL
			];
			if (list_OpenTrackerRec != null && list_OpenTrackerRec.size() > 0) {
				return;
			}

			//start tracking the facilitator active time
			Analytics_Time_Tracker__c objTracker = new Analytics_Time_Tracker__c();
			objTracker.Order__c = objOrder.Id;
			objTracker.Start_Date__c = System.now();
			objTracker.Metric_Type__c = 'Processing Time';
			objTracker.Is_PT_Facilitator_Record__c = true;
			objTracker.Event_Type__c = 'Facilitator Processing Time';
			objTracker.RecordTypeId = Cache.getRecordTypeId('Analytics_Time_Tracker__c', 'Payroll Transfer');
			objTracker.Object_Name__c = 'Order';
			try {
				insert objTracker;
			} catch (exception ex) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while creating Analytics Time Tracker record for the Facilitator: ' + ex.getMessage()));
				blnIsError = true;
			}
		}
	}

	//this method getting called from Constructor. This method is querying "User Skills" for the logged in user and populating the Skill wrapper.
	public void getUserSkills() {
		objUserSkillDetails = new userSkillsWrapper();
		map_PlayModeConfigs = new Map<String, String>();

		for (PT_Play_Mode_Configuration__mdt objPlayModeConfig : [SELECT Id, MasterLabel, Filter_Type__c, Filter_Value__c FROM PT_Play_Mode_Configuration__mdt WHERE Active__c = TRUE]) {
			if (objPlayModeConfig.MasterLabel.equalsIgnoreCase('PT Play Mode Order')) {
				map_PlayModeConfigs.put('Order by', objPlayModeConfig.Filter_Value__c);
			} else {
				map_PlayModeConfigs.put(objPlayModeConfig.MasterLabel, objPlayModeConfig.Filter_Value__c);
			}
		}

		for (User_Skill__c objUS : [
			SELECT
				Id,
				Skill__r.Order_Complexity_Score__c,
				Skill__r.Exception__c,
				Skill__r.Payroll_Transfer_Skills__c,
				Skill__r.Payroll_Provider_Type__c,
				Skill__r.Payroll_Sales_Team__c,
				User_Role__r.User__r.Out_Of_Office__c,
				Skill__r.PT_Facilitator_Complexity_Level__c,
				Skill__r.States_Count__c,
				Skill__r.States__c,
				Skill__r.Previous_Payroll_Providers__c,
				Skill__r.Benefits_Count__c,
				Skill__r.Partner__c
			FROM User_Skill__c
			WHERE
				User_Role__c != NULL
				AND User_Role__r.User__c != NULL
				AND User_Role__r.User__c = :idLoggedInUser
				AND Skill__c != NULL
				AND Skill__r.Role__c != NULL
				AND Skill__r.Role__r.Name = :strFacilitatorRoleName
				AND Active__c = TRUE
		]) {
			if (objUserSkillDetails.strComplexityType.length() == 0 && objUS.Skill__r.Order_Complexity_Score__c != null && map_PlayModeConfigs.containsKey(objUS.Skill__r.Order_Complexity_Score__c)) {
				objUserSkillDetails.strComplexityType = map_PlayModeConfigs.get(objUS.Skill__r.Order_Complexity_Score__c);
			}

			if (objUS.Skill__r.Payroll_Transfer_Skills__c != null) {
				if (objUS.Skill__r.Payroll_Transfer_Skills__c == PTS_EXTERNALS) {
					blnExternalOrder = true;
				}

				objUserSkillDetails.set_TypeOfOrder.add(objUS.Skill__r.Payroll_Transfer_Skills__c);
			}

			if (objUS.Skill__r.Payroll_Provider_Type__c != null) {
				if (objUS.Skill__r.Payroll_Provider_Type__c == 'Non-instabase') {
					blnIsNonInstabase = true;
				}
				objUserSkillDetails.set_PreviousProviderType.add(objUS.Skill__r.Payroll_Provider_Type__c);
			}

			if (objUS.Skill__r.Payroll_Sales_Team__c != null)
				objUserSkillDetails.Set_SalesTeam.add(objUS.Skill__r.Payroll_Sales_Team__c);
			if (objUS.Skill__r.Exception__c != null)
				objUserSkillDetails.set_IsException.add(objUS.Skill__r.Exception__c);
			if (objUS.Skill__r.Partner__c != null)
				objUserSkillDetails.set_PartnerTier.add(objUS.Skill__r.Partner__c);

			blnIsUserOutOfOffice = objUS.User_Role__r.User__r.Out_Of_Office__c;

			if (String.isNotBlank(objUS.Skill__r.PT_Facilitator_Complexity_Level__c)) {
				objUserSkillDetails.set_stateCodes.addAll(objUS.Skill__r.States__c.trim().split(';'));
				objUserSkillDetails.set_PreviousProvider.addAll(objUS.Skill__r.Previous_Payroll_Providers__c.trim().split(';'));

				if (objUS.Skill__r.Benefits_Count__c.contains('4+')) {
					objUserSkillDetails.intMaxBenefitCount = 10000;
				} else if (objUS.Skill__r.Benefits_Count__c.contains('4')) {
					objUserSkillDetails.intMaxBenefitCount = 4;
				} else {
					objUserSkillDetails.intMaxBenefitCount = 0;
				}

				if (objUS.Skill__r.States_Count__c.contains('4+')) {
					objUserSkillDetails.intMaxStateCount = 10000;
				} else if (objUS.Skill__r.States_Count__c.contains('4')) {
					objUserSkillDetails.intMaxStateCount = 4;
				} else {
					objUserSkillDetails.intMaxStateCount = 1;
				}
			}
		}

		//if person can work on exception then he/she can work on non exceptions too
		if (objUserSkillDetails.set_IsException.contains(true)) {
			objUserSkillDetails.set_IsException.add(false);
		}

		if (map_PlayModeConfigs.containsKey('Order by')) {
			objUserSkillDetails.strOrderByQueryString = map_PlayModeConfigs.get('Order by');
		}

		//objUserSkillDetails.set_PreviousProviderType.addAll(map_PlayModeConfigs.get('Instabase').split(','));
		if (objUserSkillDetails.set_PreviousProviderType == null) {
			objUserSkillDetails.set_PreviousProviderType = new Set<string>();
		} else if (objUserSkillDetails.set_PreviousProviderType.size() == 0 || objUserSkillDetails.set_PreviousProviderType.size() == 2) {
			objUserSkillDetails.set_PreviousProviderType = new Set<string>();
		} else if (objUserSkillDetails.set_PreviousProviderType.size() == 1) {
			objUserSkillDetails.set_PreviousProviderType.addAll(map_PlayModeConfigs.get('Instabase').split(','));
		}
	}

	//This method queries allocation records for the logged in user starting from current week.
	public void getUserNextFreeWeeks() {
		//we have added one day to move the date form sunday to monday
		Date dtCurrentWeekStartDate = System.today().toStartOfWeek().addDays(1);
		if (test.isRunningTest()) {
			dtCurrentWeekStartDate = date.newInstance(2019, 10, 1);
		}
		map_WeekStartDateBOARecord = new Map<Date, Benefit_Order_Allocation__c>();

		for (Benefit_Order_Allocation__c objBOA : [
			SELECT Id, Open_Order_Employee_Count__c, Inactive_Employee_Count__c, Contractor_Count__c, Week_Start_Date__c, Week_Order_Capacity__c, Week_End_Date__c
			FROM Benefit_Order_Allocation__c
			WHERE User_Role__r.User__c = :idLoggedInUser AND Week_Start_Date__c >= :dtCurrentWeekStartDate
		]) {
			Integer aicCount = Integer.valueOf(
				(objBOA.Open_Order_Employee_Count__c != null ? objBOA.Open_Order_Employee_Count__c : 0) +
					(objBOA.Inactive_Employee_Count__c != null ? objBOA.Inactive_Employee_Count__c : 0) +
					(objBOA.Contractor_Count__c != null ? objBOA.Contractor_Count__c : 0)
			);
			if (aicCount < objBOA.Week_Order_Capacity__c) {
				map_WeekStartDateBOARecord.put(objBOA.Week_Start_Date__c, objBOA);
			}
		}
	}

	public String getUserSkillsQueryFilter() {
		set_SalesTeam = new Set<String>();
		set_previousPayroll = new Set<String>();
		set_PreviousPayrollForComplexityLevel = new Set<String>();
		set_StatesForComplexityLevel = new Set<String>();
		set_Exceptions = new Set<Boolean>();
		set_PartnerTiers = new Set<String>();
		set_Exceptions = objUserSkillDetails.set_IsException;
		set_SalesTeam = objUserSkillDetails.Set_SalesTeam;
		set_previousPayroll = objUserSkillDetails.set_PreviousProviderType;
		set_PreviousPayrollForComplexityLevel = objUserSkillDetails.set_PreviousProvider;
		set_StatesForComplexityLevel = objUserSkillDetails.set_stateCodes;
		set_PartnerTiers = objUserSkillDetails.set_PartnerTier;

		Set<String> set_PTSkillTypes = new Set<String>();

		String strSkillFilter = ' AND Exception_Request__c IN: set_Exceptions ';
		if (set_SalesTeam != null && set_SalesTeam.size() > 0) {
			strSkillFilter += ' AND Opportunity_Team__c IN: set_SalesTeam ';
		}
		if (set_previousPayroll != null && set_previousPayroll.size() > 0) {
			if (blnIsNonInstabase) {
				strSkillFilter += ' AND Previous_Payroll_Provider__c NOT IN: set_previousPayroll ';
			} else {
				strSkillFilter += ' AND Previous_Payroll_Provider__c IN: set_previousPayroll ';
			}
		}

		//for complexity Level module
		if (set_previousPayrollForComplexityLevel.size() > 0) {
			strSkillFilter += ' AND Previous_Payroll_Provider__c IN: set_PreviousPayrollForComplexityLevel ';
		}

		if (String.isNotBlank(objUserSkillDetails.strComplexityType)) {
			string strComplexityStr = '  PT_Complexity_Score__c ' + objUserSkillDetails.strComplexityType;

			if (String.isNotBlank(strComplexityStr)) {
				strSkillFilter += ' AND ' + strComplexityStr;
			}
		}
		//If User has any Partner Tier Skills, filter based on related Account attributes
		if (set_PartnerTiers.size() > 0) {
			strSkillFilter += ' AND AccountId != null AND Account.Sold_By_Partner_Tier__c IN: set_PartnerTiers ';
		} else {
			strSkillFilter += ' AND (AccountId = null OR (AccountId != null AND Account.Sold_By_Partner_Tier__c = null)) ';
		}

		//non external users can play only non exteral orders
		if (blnExternalOrder == false) {
			strSkillFilter += ' AND ' + map_PlayModeConfigs.get(METADATA_EXTERNALS);
		}

		if (objUserSkillDetails.set_stateCodes?.size() > 0) {
			if (objUserSkillDetails.intMaxBenefitCount != null) {
				strSkillFilter += ' AND of_Benefits__c <= ' + objUserSkillDetails.intMaxBenefitCount;
			}

			if (objUserSkillDetails.intMaxStateCount != null) {
				strSkillFilter += ' AND of_States__c <= ' + objUserSkillDetails.intMaxStateCount;
			}

			if (set_StatesForComplexityLevel.size() > 0) {
				strSkillFilter += ' AND States__c != null ';
			}
		}

		//if one we have to place the filter otherwise no need for the filter
		if (objUserSkillDetails.set_TypeOfOrder != null && objUserSkillDetails.set_TypeOfOrder.size() > 0) {
			/*BY:PR, Date: Dec-17-2020, Desc: Introduced two string variables below to update the order type logic and include (Multi-ein and Single Login) with 
            //    "direct Order" skills and only "Partner Dulk Deals" with bulk deals.
             *  https://app.asana.com/0/1199395591815000/1199574728882404/f   
            */
			String strDirecLogic = ' AND (Bulk_Migration__c = null OR (Bulk_Migration__c != null AND ( Bulk_Migration__r.Type__c = \'Multi-EIN\' OR Bulk_Migration__r.Type__c = \'Same Login\' ))) ';
			String strMultiEINLogic = ' AND Bulk_Migration__c != null AND Bulk_Migration__r.Type__c = \'Bulk Migration\' ';
			String strBigDeskLogic = ' ';
			String strExcludeBigDeskLogic = ' ';

			if (map_PlayModeConfigs.containsKey(INCLUDE_BIGDESK_QUERYFILTER)) {
				strBigDeskLogic += map_PlayModeConfigs.get(INCLUDE_BIGDESK_QUERYFILTER);
			}

			if (map_PlayModeConfigs.containsKey(EXCLUDE_BIGDESK_QUERYFILTER)) {
				strExcludeBigDeskLogic += map_PlayModeConfigs.get(EXCLUDE_BIGDESK_QUERYFILTER);
			}

			set_PTSkillTypes.addAll(objUserSkillDetails.set_TypeOfOrder);

			//in case user have all the skills no need to place any filter logic
			if (set_PTSkillTypes.size() < 4) {
				if (set_PTSkillTypes.contains(BIGDESK)) {
					strSkillFilter += strBigDeskLogic;
					set_PTSkillTypes.remove(BIGDESK);
				} else {
					strSkillFilter += strExcludeBigDeskLogic;
				}

				if (set_PTSkillTypes.size() == 1) {
					if (set_PTSkillTypes.contains('Direct Order')) {
						strSkillFilter += strDirecLogic;
					} else {
						strSkillFilter += strMultiEINLogic;
					}
				}
			}
		}

		return strSkillFilter;
	}

	//this gives use the BOA record eligible for Order passed in the parameter
	public Benefit_Order_Allocation__c getMatchingAllocationRecord(Order objOrderRec) {
		if (objOrderRec == null || objOrderRec.Id == null || objOrderRec.Facilitator_Due_Date__c == null) {
			return null;
		}

		for (Benefit_Order_Allocation__c objBOA : map_WeekStartDateBOARecord.values()) {
			if (objOrderRec.Facilitator_Due_Date__c >= objBOA.Week_Start_Date__c && objOrderRec.Facilitator_Due_Date__c <= objBOA.Week_End_Date__c) {
				return objBOA;
			}
		}

		//if not able to find BOA record with capacity and order is part of BMR, query the BOA record
		if (objOrderRec.Bulk_Migration__c != null) {
			list<Benefit_Order_Allocation__c> list_TempBOA = [
				SELECT Id, Open_Order_Employee_Count__c, Inactive_Employee_Count__c, Contractor_Count__c, Week_Start_Date__c, Week_Order_Capacity__c, Week_End_Date__c
				FROM Benefit_Order_Allocation__c
				WHERE User_Role__r.User__c = :idLoggedInUser AND Week_Start_Date__c <= :objOrderRec.Facilitator_Due_Date__c AND Week_End_Date__c >= :objOrderRec.Facilitator_Due_Date__c
				LIMIT 1
			];
			if (list_TempBOA.size() > 0) {
				return list_TempBOA.get(0);
			}
		}
		return null;
	}

	public class userSkillsWrapper {
		public String strComplexityType;
		public Set<boolean> set_IsException;
		public Set<string> set_TypeOfOrder;
		public Set<string> set_PreviousProviderType;
		public Set<string> Set_SalesTeam;
		public String strOrderByQueryString;
		public Set<String> set_stateCodes;
		public Set<String> set_PreviousProvider;
		public Integer intMaxStateCount;
		public Integer intMaxBenefitCount;
		public Set<string> set_PartnerTier;

		public userSkillsWrapper() {
			strComplexityType = '';
			set_TypeOfOrder = new Set<string>();
			set_PreviousProviderType = new Set<string>();
			Set_SalesTeam = new Set<string>();
			set_IsException = new Set<boolean>();
			strOrderByQueryString = '';
			set_stateCodes = new Set<String>();
			set_PreviousProvider = new Set<String>();
			intMaxStateCount = 0;
			intMaxBenefitCount = 0;
			set_PartnerTier = new Set<String>();
		}
	}
}