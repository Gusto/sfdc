/**
 * @name         BTFacilitator2PlayModeCtrl
 * @author       Sanjay Paryani
 * @date         02/18/2020
 * @description  Play Mode for BT Facilitator 2. Opens up Carrier Orders for Facilitator 2 to work on.
 * @test class   BTFacilitator2PlayModeCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class BTFacilitator2PlayModeCtrl {
	// Variables & Collections
	public List<Carrier_Order__c> list_COs { get; set; }
	public Set<String> set_ValidCOStages { get; set; }
	public map<string, set<string>> map_skillTypeUserIds { get; set; }
	public String strCarrierImplementationQueue { get; set; }
	public Id IdLoggedInUser { get; set; }
	public Carrier_Order__c objCO { get; set; }
	public Integer totalReadyOrders { get; set; }
	// Constants
	static String TICKET_STATUS_CLOSED = 'Closed';
	static String TICKET_STATUS_NEW = 'New';
	static String TICKET_STATUS_INPROGRESS = 'InProgress';
	static String CO_STAGE_CANCELED = 'Canceled';
	static String CO_STAGE_CLOSED_ADMIN = 'Closed Admin';
	static String CO_STAGE_READY_SEND_PLANREVIEW = 'Ready to Send Plan Review';
	static String CO_STAGE_READY_SEND_ENROLLMENTREVIEW = 'Ready to Send Enrollment Review';
	static String CO_STAGE_PLANS_CONFIRMED = 'Plans Confirmed'; // Enrollment Review
	static String CO_STAGE_READY_IMPLEMENTATION_PLANS = 'Ready for Implementing Plans'; //Plan Review
	static String CO_STAGE_IMPLEMENTATION_PLANS = 'Implementing Plans'; // Plan Review
	static String CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS = 'Enrollment Review Entry in Progress'; // Enrollment Review
	static String ERROR_IMPLEMENTINGPLANSASSIGNED = 'You already have a Implementing Plans order assigned. New orders are not assigned.';
	static String ERROR_ENROLLMENTREVIEWASSIGNED = 'You already have a Enrollment Review Entry in Progress order assigned. New orders are not assigned.';
	static String ERROR_PLANSCONFIRMEDASSIGNED = 'You already have a Plans Confirmed order assigned. New orders are not assigned.';
	static String ERROR_NO_ELIGIBLE_USERS_FOUND = 'No eligible users found for order assignment.';
	static String ERROR_NO_ELIGIBLE_ORDERS_FOUND = 'No eligible orders found for assignment.';
	static String ERROR_OOO_MESSAGE = 'You are currently showing as Out of Office so no new orders will be assigned. Please reset the OOO in your settings and try again.';
	static String ERROR_NO_MY_ORDERS = 'You dont have any orders.';
	static String ERROR_FOLLOWUP_DATE = 'Follow Up Date: has to be under 2 days.';
	static String ERROR_NOT_FAC2 = 'You cannot play these orders since you are not Facilitator 2';
	static String YES_PICKLISTVALUE = 'Y';
	static String NO_PICKLISTVALUE = 'N';
	public String checkAssignment { get; set; }
	public Set<Id> set_BenefitOrders { get; set; }
	public Map<Id, Set<Id>> map_BOToFAC2 { get; set; }
	public Map<Id, List<Carrier_Order__c>> map_ParentCOTOChildren { get; set; }
	public Map<Id, List<Carrier_Order__c>> map_AllRelatedCOToBO { get; set; }
	public List<Carrier_Order__c> list_COToUpdate { get; set; }
	public List<Carrier_Order__c> list_AllMyReadyCarrierOrders { get; set; }
	public List<Id> list_PlayAllMyEnrollmentOrders { get; set; }
	public Set<Id> set_PlayAllNewPlanReviewOrders { get; set; }
	public Set<Id> set_PlayAllNewEnrollmentOrders { get; set; }
	public string strProcessedCOIds { get; set; }
	public string strPlayedCOIds { get; set; }
	public Boolean blnIsUserOOO { get; set; }
	public Boolean blnShowMyCOPanel { get; set; }
	public Boolean blnShowPlayModePanel { get; set; }
	public Set<Id> set_OOOBTFAC2s { get; set; }
	public Set<Id> set_AllOOOFAC2BOs { get; set; }
	public Set<Id> set_BTFAC2s { get; set; }
	public String strCOBTRecordTypeId { get; set; }
	// CO Wrapper to show my carrier orders
	public list<CarrierOrderWrapper> list_CarrierOrderWrapper { get; set; }
	public boolean blnIsTaskCompleted { get; set; }
	public Map<String, CarrierOrderWrapper> map_COGroupedByAccount { get; set; }
	public Map<String, CarrierOrderWrapper> map_COWLI { get; set; }
	public set<string> set_AccountName { get; set; }
	public list<TicketWrapper> list_TicketWrapper { get; set; }
	public String strTicketFilter { get; set; }
	public integer intNoOfTicketCreated { get; set; }
	public integer intNoOfTicketOnwed { get; set; }
	public integer intNoOfTicketClosed { get; set; }
	public String strErrorInEnrollmentReview { get; set; }
	public String strErrorInPlanReview { get; set; }
	public String strErrorInTickets { get; set; }

	//Contructor
	public BTFacilitator2PlayModeCtrl() {
		blnShowPlayModePanel = true;
		blnIsUserOOO = false;
		blnShowMyCOPanel = false;
		strErrorInEnrollmentReview = '';
		strErrorInPlanReview = '';
		strErrorInTickets = '';
		set_ValidCOStages = new Set<String>{ CO_STAGE_READY_IMPLEMENTATION_PLANS, CO_STAGE_PLANS_CONFIRMED };
		strCarrierImplementationQueue = System.Label.Carrier_Implementation_Queue;
		IdLoggedInUser = UserInfo.getUserId();
		strCOBTRecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		map_AllRelatedCOToBO = new Map<Id, List<Carrier_Order__c>>();
		map_BOToFAC2 = new Map<Id, Set<Id>>();
		map_skillTypeUserIds = new Map<string, set<string>>();
	}

	//1. Order by latest Renewal Date and then assign the top most order in play mode.
	//2. If Renewal Date is same for orders then check for Enrollment Review orders and not Plan Review order.
	//PLANS_CONFIRMED = Enrollment Review. READY_IMPLEMENTATION_PLANS = Plan Review
	//3. Order by highest Bor Age and assign the top most order to FC2
	//Play Carrier Orders
	public void playNewOrders() {
		list_COToUpdate = new List<Carrier_Order__c>();
		set_PlayAllNewPlanReviewOrders = new Set<Id>();
		set_PlayAllNewEnrollmentOrders = new Set<Id>();
		checkAssignment = '';
		strPlayedCOIds = '';
		Boolean blnAllFac2OOO = false;
		String strSuccessPlanBuildOrderMessage = '';
		String strSuccessNonPlanBuildOrderMessage = '';

		// Check for Plan Build using the user roles and Facilitator_2_Plan_Build__c field on CO.
		getUserData();
		if (!set_BTFAC2s.contains(IdLoggedInUser)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_NOT_FAC2));
			return;
		}
		// Check if logged in user does not have any orders assigned.
		checkStatusOfCarrierOrders();
		// Check for OOO
		checkOOOField();

		//Only if the current logged in user does not have any orders assigned this code will be called.
		if (String.isBlank(checkAssignment)) {
			// If no orders are assigned to logged in user then get all eligible CO that can be played.
			fetchEligibleCO();

			if (list_COs.size() > 0) {
				for (Carrier_Order__c co : list_COs) {
					if (co.Implementation_Stage__c == CO_STAGE_PLANS_CONFIRMED || co.Implementation_Stage__c == CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS) {
						// Call assignOwnerForAllCO to update the Enrollment Reviewer and stage
						// Checks if all COs for a BO are in Plans Confirmed then assigns those COs else continue to iterate.
						if (assignOwnerForAllCO(co)) {
							break;
						} else {
							continue;
						}
					} else if ((co.Implementation_Stage__c == CO_STAGE_READY_IMPLEMENTATION_PLANS || co.Implementation_Stage__c == CO_STAGE_IMPLEMENTATION_PLANS) && !list_COToUpdate.contains(co)) {
						if (co.Facilitator_2_Plan_Build__c == YES_PICKLISTVALUE && map_skillTypeUserIds.containsKey('Build_Plan') && map_skillTypeUserIds.get('Build_Plan').contains(IdLoggedInUser)) {
							if (co.Is_Multi_EIN__c) {
								if (assignOwnerForAllMultiEINCO(co))
									break;
								else
									continue;
							} else {
								set_PlayAllNewPlanReviewOrders.clear();
								if (!list_COToUpdate.contains(co))
									list_COToUpdate.add(co);
								set_PlayAllNewPlanReviewOrders.add(co.Id);

								if (!set_PlayAllNewPlanReviewOrders.isEmpty()) {
									strPlayedCOIds = '';
									//Plan Review - Plan Build Success Order
									strSuccessPlanBuildOrderMessage = 'SUCCESS: Plan Review (plan build) order';
								}
							}
						} else if (co.Facilitator_2_Plan_Build__c == NO_PICKLISTVALUE) {
							if (co.Is_Multi_EIN__c) {
								if (assignOwnerForAllMultiEINCO(co))
									break;
								else
									continue;
							} else {
								set_PlayAllNewPlanReviewOrders.clear();
								if (!list_COToUpdate.contains(co))
									list_COToUpdate.add(co);
								set_PlayAllNewPlanReviewOrders.add(co.Id);

								if (!set_PlayAllNewPlanReviewOrders.isEmpty()) {
									strPlayedCOIds = '';
									//Plan Review - Non Plan Build Success Order
									strSuccessNonPlanBuildOrderMessage = 'SUCCESS: Plan Review (non plan build) order';
								}
							}
						}
					}
				}

				//Plan Review - Plan Build Success Order
				if (strSuccessPlanBuildOrderMessage == 'SUCCESS: Plan Review (plan build) order' && !set_PlayAllNewPlanReviewOrders.isEmpty()) {
					for (Carrier_Order__c tempCo : [
						SELECT
							Id,
							Facilitator_2_Enrollment_Review__c,
							Facilitator_2_Plan_Review__c,
							Implementation_Stage__c,
							Follow_Up_Date__c,
							OOO_Timestamp__c,
							Benefit_Order__c,
							Is_Multi_EIN__c,
							Assignment_Message__c
						FROM Carrier_Order__c
						WHERE ID IN :set_PlayAllNewPlanReviewOrders
						FOR UPDATE
					]) {
						String strCOId = '';
						if (tempCo.Facilitator_2_Plan_Review__c != IdLoggedInUser) {
							// change stage to implementing plans stage and facilitator 2 plan reviewer as the logged in user
							// Adding assignment message to know how the order got assigned.
							tempCo.Facilitator_2_Plan_Review__c = IdLoggedInUser;
							tempCo.Assignment_Message__c = strSuccessPlanBuildOrderMessage;
							tempCo.Implementation_Stage__c = CO_STAGE_IMPLEMENTATION_PLANS;
							Datetime start = System.Now();
							while (System.Now().getTime() < start.getTime() + 3000) {
							} //Delay
							database.update(tempCo, true);
							strCOId = tempCo.Id;
							strPlayedCOIds += (strPlayedCOIds == '' ? String.valueOf(strCOId) : ',' + String.valueOf(strCOId));
						}
					}
				}
				//Plan Review - Non Plan Build Success Order
				else if (strSuccessNonPlanBuildOrderMessage == 'SUCCESS: Plan Review (non plan build) order' && !set_PlayAllNewPlanReviewOrders.isEmpty()) {
					for (Carrier_Order__c tempCo : [
						SELECT
							Id,
							Facilitator_2_Enrollment_Review__c,
							Facilitator_2_Plan_Review__c,
							Implementation_Stage__c,
							Follow_Up_Date__c,
							OOO_Timestamp__c,
							Benefit_Order__c,
							Is_Multi_EIN__c,
							Assignment_Message__c
						FROM Carrier_Order__c
						WHERE ID IN :set_PlayAllNewPlanReviewOrders
						FOR UPDATE
					]) {
						String strCOId = '';
						if (tempCo.Facilitator_2_Plan_Review__c != IdLoggedInUser) {
							// change stage to implementing plans stage and facilitator 2 plan reviewer as the logged in user
							// Adding assignment message to know how the order got assigned.
							tempCo.Facilitator_2_Plan_Review__c = userInfo.getUserId();
							tempCo.Assignment_Message__c = strSuccessNonPlanBuildOrderMessage;
							tempCo.Implementation_Stage__c = CO_STAGE_IMPLEMENTATION_PLANS;
							Datetime start = System.Now();
							while (System.Now().getTime() < start.getTime() + 3000) {
							} //Delay
							database.update(tempCo, true);
							strCOId = tempCo.Id;
							strPlayedCOIds += (strPlayedCOIds == '' ? String.valueOf(strCOId) : ',' + String.valueOf(strCOId));
						}
					}
				}
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_NO_ELIGIBLE_ORDERS_FOUND));
			}
		}
	}

	// Check if logged in user has any existing orders.
	public void checkStatusOfCarrierOrders() {
		//checkAssignment = '';
		for (Carrier_Order__c coRec : [
			SELECT ID, Implementation_Stage__c, Follow_Up_Date__c, Facilitator_2_Enrollment_Review__c, Facilitator_2_Plan_Review__c, Is_Carrier_Order_In_Play__c
			FROM Carrier_Order__c
			WHERE
				(Implementation_Stage__c = :CO_STAGE_IMPLEMENTATION_PLANS
				AND Facilitator_2_Plan_Review__c = :IdLoggedInUser)
				OR (Implementation_Stage__c = :CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS
				AND Facilitator_2_Enrollment_Review__c = :IdLoggedInUser)
		]) {
			if (
				//Follow up date (less than or equal to today) orders should be assigned to you.
				((coRec.Follow_Up_Date__c != null && Date.today().daysBetween(coRec.Follow_Up_Date__c) <= 0) || coRec.Follow_Up_Date__c == null) &&
				(coRec.Implementation_Stage__c == CO_STAGE_IMPLEMENTATION_PLANS ||
				coRec.Implementation_Stage__c == CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS ||
				coRec.Implementation_Stage__c == CO_STAGE_PLANS_CONFIRMED)
			) {
				if (coRec.Implementation_Stage__c == CO_STAGE_IMPLEMENTATION_PLANS && coRec.Facilitator_2_Plan_Review__c == IdLoggedInUser) {
					checkAssignment = 'implementingPlans';
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_IMPLEMENTINGPLANSASSIGNED));
					break;
				} else if (coRec.Implementation_Stage__c == CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS && coRec.Facilitator_2_Enrollment_Review__c == IdLoggedInUser) {
					checkAssignment = 'enrollmentReviewInPgress';
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_ENROLLMENTREVIEWASSIGNED));
					break;
				} else if (coRec.Implementation_Stage__c == CO_STAGE_PLANS_CONFIRMED) {
					checkAssignment = 'plansConfirmed';
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_PLANSCONFIRMEDASSIGNED));
					break;
				}
			}
		}
	}

	public void checkOOOField() {
		List<User> lst_User = [
			SELECT Out_Of_Office__c
			FROM User
			WHERE ID = :IdLoggedInUser AND IsActive = TRUE AND Out_Of_Office__c = TRUE
		];
		if (!lst_User.isEmpty()) {
			blnIsUserOOO = true;
			checkAssignment = 'cannotAssignOOO';
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_OOO_MESSAGE));
		} else {
			blnIsUserOOO = false;
		}
	}

	/**Using this method we are querying eligible,active,in office users that have the skills with the role of [Benefit Transfer Advocate] */
	public void getUserData() {
		Set<string> set_nonBuildPlanUserId = new Set<string>();
		Set<string> set_BuildPlanUserId = new Set<string>();
		set_BTFAC2s = new Set<Id>();
		set_OOOBTFAC2s = new Set<Id>();

		for (User_Skill__c skillRec : [
			SELECT Id, User_Name__c, User_Role__c, User_Role__r.User__c, Skill__c, Skill__r.Build_Plans__c, User_Role__r.User__r.Out_Of_Office__c, User_Role__r.User__r.Back_In_Office_Date_Time__c
			FROM User_Skill__c
			WHERE
				Skill_Role_Name__c = 'Benefit Transfer Facilitator 2'
				//AND	User_Role__r.User__r.Out_Of_Office__c = false
				AND User_Role__r.User__r.IsActive = TRUE
		]) {
			if (!skillRec.User_Role__r.User__r.Out_Of_Office__c) {
				if (skillRec.Skill__r.Build_Plans__c) {
					set_BuildPlanUserId.add(skillRec.User_Role__r.User__c);
				} else {
					set_nonBuildPlanUserId.add(skillRec.User_Role__r.User__c);
				}
			} else {
				set_OOOBTFAC2s.add(skillRec.User_Role__r.User__c);
			}
			set_BTFAC2s.add(skillRec.User_Role__r.User__c);
		}

		if (set_BuildPlanUserId.size() > 0) {
			map_skillTypeUserIds.put('Build_Plan', set_BuildPlanUserId);
		}

		if (set_nonBuildPlanUserId.size() > 0) {
			if (set_BuildPlanUserId.size() > 0) {
				set_nonBuildPlanUserId.removeAll(set_BuildPlanUserId);
			}
			map_skillTypeUserIds.put('Non_Build_Plan', set_nonBuildPlanUserId);
		}
	}

	// Play orders prioritized as:
	// 1. OOO Orders with tickets
	// 2. OOO Orders
	// 3. All other eligible Orders prioritized by Play Mode logic:
	// a. Order by latest Renewal Date and then assign the top most order in play mode.
	// b. If Renewal Date is same for orders then check for Enrollment Review orders and not Plan Review order.
	// c. Order by highest Bor Age and assign the top most order to FC2
	// Note: PLANS_CONFIRMED = Enrollment Review. READY_IMPLEMENTATION_PLANS = Plan Review
	public void fetchEligibleCO() {
		list_COs = new List<Carrier_Order__c>();
		set_BenefitOrders = new Set<ID>();
		Set<Id> set_MultiEINCarrierOrders = new Set<Id>();
		List<Carrier_Order__c> list_OOOCOs = new List<Carrier_Order__c>();
		List<Carrier_Order__c> list_OrdersWTicekts = new List<Carrier_Order__c>();
		List<Carrier_Order__c> list_OtherOrders = new List<Carrier_Order__c>();

		// OOO Orders with tickets = Which statuses ? // implementing plans and enrollment in progress, ticket status: new.
		// OOO which statuses// implementing plans and enrollment in progress
		// OOO Orders with tickets both fac2 can be ooo? // History track FAC2 PR, ER
		// For OOO users, if any CO is with a new ticket then push that CO to the top of Play Mode.
		if (set_OOOBTFAC2s.size() > 0) {
			for (Carrier_Order__c co : [
				SELECT
					Id,
					OOO_Timestamp__c,
					Benefit_Order__c,
					Implementation_Stage__c,
					Facilitator_2_Plan_Build__c,
					Facilitator_2_Plan_Review__c,
					Facilitator_2_Enrollment_Review__c,
					Is_Multi_EIN__c,
					Follow_Up_Date__c,
					TAdA__c,
					Is_Carrier_Order_In_Play__c,
					(
						SELECT Id, Status__c
						FROM Tickets__r
						WHERE Status__c = :TICKET_STATUS_NEW
					)
				FROM Carrier_Order__c
				WHERE
					RecordTypeId = :strCOBTRecordTypeId
					AND TAdA__c = False
					AND ((Facilitator_2_Plan_Review__c IN :set_OOOBTFAC2s
					AND Implementation_Stage__c = :CO_STAGE_IMPLEMENTATION_PLANS)
					OR (Facilitator_2_Enrollment_Review__c IN :set_OOOBTFAC2s
					AND Implementation_Stage__c = :CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS))
				//FOR UPDATE
			]) {
				//OOO orders with tickets
				if (co.tickets__r.size() > 0) {
					list_OrdersWTicekts.add(co);
				}
				// OOO orders
				if (co.OOO_Timestamp__c != null) {
					list_OOOCOs.add(co);
				}
				// Multi-EIN Orders
				if (co.Is_Multi_EIN__c && co.Implementation_Stage__c == CO_STAGE_IMPLEMENTATION_PLANS)
					set_MultiEINCarrierOrders.add(co.Id);

				set_BenefitOrders.add(co.Benefit_Order__c);
			}
		}

		// All other eligible orders sorted by renewal date, stage, age
		for (Carrier_Order__c co : [
			SELECT
				ID,
				Implementation_Stage__c,
				Carrier__c,
				Name,
				Renewal_Date__c,
				Facilitator_2_Plan_Build__c,
				Facilitator_2_Plan_Review__c,
				Facilitator_2_Enrollment_Review__c,
				Benefit_Types__c,
				Benefit_Order__c,
				Benefit_Order__r.Age__c,
				OOO_Timestamp__c,
				Parent_Carrier_Order__c,
				Is_Multi_EIN__c,
				TAdA__c,
				Follow_Up_Date__c,
				Is_Carrier_Order_In_Play__c,
				(
					SELECT Id, Status__c
					FROM Tickets__r
					WHERE Status__c = :TICKET_STATUS_NEW
				)
			FROM Carrier_Order__c
			WHERE
				Implementation_Stage__c IN :set_ValidCOStages
				AND RecordTypeId = :strCOBTRecordTypeId
				AND TAdA__c = False
				AND (Facilitator_2_Plan_Review__c = NULL
				OR Facilitator_2_Enrollment_Review__c = NULL)
			//AND	    Renewal_Date__c > TODAY // removed for testing purposes
			ORDER BY Renewal_Date__c ASC, Implementation_Stage__c DESC, Benefit_Order__r.Age__c DESC
		]) {
			//Only if Follow up date is less or equal to today, orders are eligible.
			if ((co.Follow_Up_Date__c != null && Date.today().daysBetween(co.Follow_Up_Date__c) <= 0) || co.Follow_Up_Date__c == null) {
				// Regular orders sorted by renewal date, stage, age
				list_OtherOrders.add(co);
				set_BenefitOrders.add(co.Benefit_Order__c);
				// Multi-EIN orders
				if (co.Is_Multi_EIN__c && co.Implementation_Stage__c == CO_STAGE_READY_IMPLEMENTATION_PLANS)
					set_MultiEINCarrierOrders.add(co.Id);
			}
		}

		// Add all OOO orders first, then OOO orders with tickets, then the other orders
		if (!list_OOOCOs.isEmpty())
			list_COs.addAll(list_OOOCOs);
		if (!list_OrdersWTicekts.isEmpty())
			list_COs.addAll(list_OrdersWTicekts);
		if (!list_OtherOrders.isEmpty())
			list_COs.addAll(list_OtherOrders);

		if (set_BenefitOrders.size() > 0) {
			map_AllRelatedCOToBO = new Map<Id, List<Carrier_Order__c>>();
			//map_BOToFAC2 = new map<Id, Set<Id>>();

			for (Carrier_Order__c co : [
				SELECT ID, Facilitator_2_Plan_Review__c, Implementation_Stage__c, Facilitator_2_Enrollment_Review__c, OOO_Timestamp__c, Benefit_Order__c, TAdA__c, Is_Carrier_Order_In_Play__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c IN :set_BenefitOrders AND RecordTypeId = :strCOBTRecordTypeId AND TAdA__c = False
			]) {
				if (!map_AllRelatedCOToBO.containsKey(co.Benefit_Order__c)) {
					map_AllRelatedCOToBO.put(co.Benefit_Order__c, new List<Carrier_Order__c>{ co });
				} else {
					map_AllRelatedCOToBO.get(co.Benefit_Order__c).add(co);
				}
			}
		}

		// Multi-EIN
		if (!set_MultiEINCarrierOrders.isEmpty()) {
			map_ParentCOTOChildren = new Map<Id, List<Carrier_Order__c>>();

			for (Carrier_Order__c co : [
				SELECT
					ID,
					Facilitator_2_Plan_Review__c,
					Implementation_Stage__c,
					Facilitator_2_Enrollment_Review__c,
					OOO_Timestamp__c,
					Benefit_Order__c,
					Parent_Carrier_Order__c,
					Carrier__c,
					Carrier__r.Name,
					TAdA__c,
					Is_Carrier_Order_In_Play__c
				FROM Carrier_Order__c
				WHERE Id IN :set_MultiEINCarrierOrders AND RecordTypeId = :strCOBTRecordTypeId AND TAdA__c = False
			]) {
				// Get all Child Multi-EIN Carrier Order and map them to their parents.
				// Also, add the parent Carrier Order to the map as a value list as well.
				// Because the Facilitator 2 will play all orders from one multi-ein group based on same carrier.
				if (co.Parent_Carrier_Order__c != null) {
					if (map_ParentCOTOChildren.containsKey(co.Parent_Carrier_Order__c))
						map_ParentCOTOChildren.get(co.Parent_Carrier_Order__c).add(co);
					else
						map_ParentCOTOChildren.put(co.Parent_Carrier_Order__c, new List<Carrier_Order__c>{ co });
				} else {
					if (map_ParentCOTOChildren.containsKey(co.Id))
						map_ParentCOTOChildren.get(co.Id).add(co);
					else
						map_ParentCOTOChildren.put(co.Id, new List<Carrier_Order__c>{ co });
				}
			}
		}
	}

	public Boolean assignOwnerForAllCO(Carrier_Order__c COToCheck) {
		set_PlayAllNewEnrollmentOrders.clear();
		//List<Carrier_Order__c> list_COToUpdate = new List<Carrier_Order__c>();
		if (map_AllRelatedCOToBO.values().size() > 0 && map_AllRelatedCOToBO.containsKey(COToCheck.Benefit_Order__c)) {
			for (Carrier_Order__c co : map_AllRelatedCOToBO.get(COToCheck.Benefit_Order__c)) {
				// All COs for a BO need to be in Plans Confirmed stage to be played as Enrollment Review Orders.
				// SJay - 07/2/2020 - Order must be in Plans Confirmed for a group to be played,
				// but if there are orders in Canceled or Closed Admin in the group as well
				// then the Plans Confirmed order from the group can still be played
				if (co.Implementation_Stage__c == CO_STAGE_PLANS_CONFIRMED || co.Implementation_Stage__c == CO_STAGE_CLOSED_ADMIN || co.Implementation_Stage__c == CO_STAGE_CANCELED) {
					// Change stage to enrollment review in progress
					if (co.Implementation_Stage__c == CO_STAGE_PLANS_CONFIRMED) {
						co.Implementation_Stage__c = CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS;
						// Assign the Enrollment Reviewer as the logged in user
						co.Facilitator_2_Enrollment_Review__c = IdLoggedInUser;
						// Adding assignment message to know how the order got assigned.
						co.Assignment_Message__c = 'SUCCESS: Enrollment Review order';
						if (!list_COToUpdate.contains(co))
							list_COToUpdate.add(co);
						set_PlayAllNewEnrollmentOrders.add(co.Id);
					}
				}
				// Handles OOO orders which will be in Enrollment Review in Progress.
				//  && co.OOO_Timestamp__c != null
				else if (co.Implementation_Stage__c == CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS) {
					// Assign the Enrollment Reviewer as the logged in user
					co.Facilitator_2_Enrollment_Review__c = IdLoggedInUser;
					// Adding assignment message to know how the order got assigned.
					co.Assignment_Message__c = 'SUCCESS: Enrollment Review order';
					if (!list_COToUpdate.contains(co))
						list_COToUpdate.add(co);
					set_PlayAllNewEnrollmentOrders.add(co.Id);
				} else {
					return false;
				}
			}
			if (!set_PlayAllNewEnrollmentOrders.isEmpty()) {
				strPlayedCOIds = '';
				try {
					for (Carrier_Order__c tempCo : [
						SELECT
							Id,
							Facilitator_2_Enrollment_Review__c,
							Facilitator_2_Plan_Review__c,
							Implementation_Stage__c,
							Follow_Up_Date__c,
							OOO_Timestamp__c,
							Benefit_Order__c,
							Is_Multi_EIN__c,
							Assignment_Message__c
						FROM Carrier_Order__c
						WHERE ID IN :set_PlayAllNewEnrollmentOrders
						FOR UPDATE
					]) {
						if (tempCo.Facilitator_2_Enrollment_Review__c != userInfo.getUserId()) {
							String strCOId = '';
							tempCo.Facilitator_2_Enrollment_Review__c = IdLoggedInUser;
							tempCo.Assignment_Message__c = 'SUCCESS: Enrollment Review order';
							tempCo.Implementation_Stage__c = CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS;
							Datetime start = System.Now();
							while (System.Now().getTime() < start.getTime() + 3000) {
							} //Delay
							database.update(tempCo, true);
							strCOId = tempCo.Id;
							strPlayedCOIds += (strPlayedCOIds == '' ? strCOId : ',' + strCOId);
						}
					}
					return true;
				} catch (Exception ex) {
					return false;
				}
			}
		} else
			return false;

		return true;
	}

	public Boolean assignOwnerForAllMultiEINCO(Carrier_Order__c COToCheck) {
		set_PlayAllNewPlanReviewOrders.clear();
		// query all the COs for the same parent carrier order.
		if (!map_ParentCOTOChildren.isEmpty() && map_ParentCOTOChildren.containsKey(COToCheck.Id)) {
			for (Carrier_Order__c co : map_ParentCOTOChildren.get(COToCheck.Id)) {
				if (co.Implementation_Stage__c == CO_STAGE_READY_IMPLEMENTATION_PLANS) {
					// change stage to implementing plans stage and facilitator 2 plan reviewer as the logged in user
					co.Facilitator_2_Plan_Review__c = IdLoggedInUser;
					co.Implementation_Stage__c = CO_STAGE_IMPLEMENTATION_PLANS;
					// Adding assignment message to know how the order got assigned.
					co.Assignment_Message__c = 'SUCCESS: Plan Review order (Multi-EIN)';
					if (!list_COToUpdate.contains(co))
						list_COToUpdate.add(co);
					set_PlayAllNewPlanReviewOrders.add(co.Id);
				} else if (co.Implementation_Stage__c == CO_STAGE_IMPLEMENTATION_PLANS && co.OOO_Timestamp__c != null) {
					// Assign the Plan Reviewer as the logged in user
					co.Facilitator_2_Plan_Review__c = IdLoggedInUser;
					// Adding assignment message to know how the order got assigned.
					co.Assignment_Message__c = 'SUCCESS: Plan Review order (Multi-EIN) (OOO)';
					if (!list_COToUpdate.contains(co))
						list_COToUpdate.add(co);
					set_PlayAllNewPlanReviewOrders.add(co.Id);
				} else {
					return false;
				}
			}
			if (!set_PlayAllNewPlanReviewOrders.isEmpty()) {
				strPlayedCOIds = '';
				try {
					for (Carrier_Order__c tempCo : [
						SELECT
							Id,
							Facilitator_2_Enrollment_Review__c,
							Facilitator_2_Plan_Review__c,
							Implementation_Stage__c,
							Follow_Up_Date__c,
							OOO_Timestamp__c,
							Benefit_Order__c,
							Is_Multi_EIN__c,
							Assignment_Message__c
						FROM Carrier_Order__c
						WHERE ID IN :set_PlayAllNewPlanReviewOrders
						FOR UPDATE
					]) {
						if (tempCo.Facilitator_2_Plan_Review__c != userInfo.getUserId()) {
							String strCOId = '';
							tempCo.Facilitator_2_Plan_Review__c = IdLoggedInUser;
							tempCo.Assignment_Message__c = 'SUCCESS: Plan Review order';
							tempCo.Implementation_Stage__c = CO_STAGE_IMPLEMENTATION_PLANS;
							Datetime start = System.Now();
							//Reduced delay time from 3 seconds to 1 second  BT-60475
							while (System.Now().getTime() < start.getTime() + 1000) {
							} //Delay
							database.update(tempCo, true);
							strCOId = tempCo.Id;
							strPlayedCOIds += (strPlayedCOIds == '' ? strCOId : ',' + strCOId);
						}
					}
					return true;
				} catch (Exception ex) {
					return false;
				}
			}
		} else
			return false;

		return true;
	}

	// Play My Carrier Orders
	// 1. Orders with tickets and logged in user as either plan reviewe or enrollment reviewer.
	// 2. Orders for logged in user as either plan reviewer or enrollment reviewer.
	// if Enrollment Review -> play all orders for an Account at the same time.
	public PageReference playMyOrders() {
		PageReference pageRef = new PageReference('/apex/BTFacilitator2PlayMode');
		List<Carrier_Order__c> list_AllMyReadyOrders = new List<Carrier_Order__c>();
		List<Id> list_PlayMyOrdersWithTickets = new List<Id>();
		List<Id> list_PlayMyEnrollmentReviewOrders = new List<Id>();
		List<Id> list_PlayMyPlanReviewOrders = new List<Id>();
		Map<Id, List<Carrier_Order__c>> map_AllMyOtherOrdersPerAccount = new Map<Id, List<Carrier_Order__c>>();
		strProcessedCOIds = '';

		for (Carrier_Order__c co : [
			SELECT
				Id,
				OOO_Timestamp__c,
				Benefit_Order__c,
				Benefit_Order__r.Account__c,
				Benefit_Order__r.Age__c,
				Implementation_Stage__c,
				Facilitator_2_Plan_Build__c,
				Facilitator_2_Plan_Review__c,
				Facilitator_2_Enrollment_Review__c,
				Is_Multi_EIN__c,
				TAdA__c,
				Follow_Up_Date__c,
				(
					SELECT Id, Status__c
					FROM Tickets__r
					WHERE Status__c != :TICKET_STATUS_CLOSED AND OwnerId = :IdLoggedInUser
				)
			FROM Carrier_Order__c
			WHERE
				RecordTypeId = :strCOBTRecordTypeId
				AND TAdA__c = False
				AND Implementation_Stage__c IN (:CO_STAGE_IMPLEMENTATION_PLANS, :CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS)
				AND RecordTypeId = :strCOBTRecordTypeId
				AND (Facilitator_2_Plan_Review__c = :IdLoggedInUser
				OR Facilitator_2_Enrollment_Review__c = :IdLoggedInUser)
			ORDER BY Renewal_Date__c ASC, Implementation_Stage__c DESC, Benefit_Order__r.Age__c DESC
		]) {
			//Only if Follow up date is less or equal to today, orders are eligible.
			if ((co.Follow_Up_Date__c != null && Date.today().daysBetween(co.Follow_Up_Date__c) <= 0) || co.Follow_Up_Date__c == null) {
				if (!map_AllMyOtherOrdersPerAccount.containsKey(co.Benefit_Order__r.Account__c)) {
					map_AllMyOtherOrdersPerAccount.put(co.Benefit_Order__r.Account__c, new List<Carrier_Order__c>{ co });
				} else {
					map_AllMyOtherOrdersPerAccount.get(co.Benefit_Order__r.Account__c).add(co);
				}
				if (co.Tickets__r.size() > 0) {
					list_PlayMyOrdersWithTickets.add(co.Id);
				} else {
					list_AllMyReadyOrders.add(co);
				}
			}
		}

		// Play top most Order with Ticket
		if (!list_PlayMyOrdersWithTickets.isEmpty()) {
			strProcessedCOIds = '';
			strProcessedCOIds += (strProcessedCOIds == '' ? String.valueOf(list_PlayMyOrdersWithTickets.get(0)) : ',' + String.valueOf(list_PlayMyOrdersWithTickets.get(0)));
		} else {
			// else play enrollment review orders per Account else play a plan review next in queue
			for (Carrier_Order__c co : list_AllMyReadyOrders) {
				if (co.Implementation_Stage__c == CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS && co.Facilitator_2_Enrollment_Review__c == IdLoggedInUser) {
					if (map_AllMyOtherOrdersPerAccount.containsKey(co.Benefit_Order__r.Account__c)) {
						strProcessedCOIds = '';
						for (Carrier_Order__c coRec : map_AllMyOtherOrdersPerAccount.get(co.Benefit_Order__r.Account__c)) {
							if (co.Implementation_Stage__c == CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS && co.Facilitator_2_Enrollment_Review__c == IdLoggedInUser) {
								list_PlayMyEnrollmentReviewOrders.add(co.Id);
								strProcessedCOIds += (strProcessedCOIds == '' ? String.valueOf(coRec.Id) : ',' + String.valueOf(coRec.Id));
							}
						}
						if (String.isNotBlank(strProcessedCOIds))
							break;
					}
				} else if (co.Implementation_Stage__c == CO_STAGE_IMPLEMENTATION_PLANS && co.Facilitator_2_Plan_Review__c == IdLoggedInUser) {
					list_PlayMyPlanReviewOrders.add(co.Id);
					strProcessedCOIds = '';
					strProcessedCOIds += (strProcessedCOIds == '' ? String.valueOf(co.Id) : ',' + String.valueOf(co.Id));
					break;
				}
			}
		}

		if (String.isBlank(strProcessedCOIds)) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_NO_MY_ORDERS));
			pageRef.setRedirect(false);
		}

		return null;
	}

	private Date getDate(DateTime dtm) {
		Date dt = Date.Today();
		if (dtm != null) {
			dt = date.newinstance(dtm.year(), dtm.month(), dtm.day());
		}
		return dt;
	}

	public void seeMyOrders() {
		seeMyPlanReviewOrders();
		seeMyEnrollmentReviewOrders();
		seeMyOrdersWithTickets();
		//For Tickets
		strTicketFilter = 'created';
		countTicket();
		ShowTicketCreatedByMe();
	}

	public void seeMyOrdersWithTickets() {
		list_TicketWrapper = new List<TicketWrapper>();
		set<string> setTicketStatus = new Set<string>{ TICKET_STATUS_NEW, TICKET_STATUS_INPROGRESS };

		for (Ticket__c objTicket : [
			SELECT
				Id,
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
			WHERE Status__c IN :setTicketStatus AND Carrier_Order__c != NULL
		]) {
			TicketWrapper tw = new TicketWrapper();
			tw.objTicket = objTicket;
			if (objTicket.Carrier_Order__r.Renewal_Date__c != null) {
				tw.strRenewalDate = string.valueOf(objTicket.Carrier_Order__r.Renewal_Date__c);
			}
			tw.strCreatedDate = string.valueof(getDate(objTicket.CreatedDate));
			tw.strModifiedDate = string.valueof(getDate(objTicket.LastModifiedDate));
			list_TicketWrapper.add(tw);
		}
	}

	//PLANS_CONFIRMED = Enrollment Review. READY_IMPLEMENTATION_PLANS = Plan Review
	//Saved as CO_STAGE_READY_SEND_PLANREVIEW
	//Plan Review Orders
	public void seeMyPlanReviewOrders() {
		strErrorInPlanReview = '';
		list_CarrierOrderWrapper = new List<CarrierOrderWrapper>();

		for (Carrier_Order__c coRec : [
			SELECT
				ID,
				Name,
				Implementation_Stage__c,
				Follow_Up_Date__c,
				Benefit_Order__c,
				Benefit_Order__r.Age__c,
				Renewal_Date__c,
				Follow_Up_Notes__c,
				Facilitator_2_Plan_Review_Notes__c,
				Parent_Carrier_Order__c,
				Parent_Carrier_Order__r.Name
			FROM Carrier_Order__c
			WHERE Implementation_Stage__c IN (:CO_STAGE_IMPLEMENTATION_PLANS) AND RecordTypeId = :strCOBTRecordTypeId AND Facilitator_2_Plan_Review__c = :IdLoggedInUser
			ORDER BY Renewal_Date__c ASC, Benefit_Order__r.Age__c DESC
		]) {
			CarrierOrderWrapper cow = new CarrierOrderWrapper();
			cow.objCarrierOrder = coRec;
			cow.strTicketId = null;
			cow.strTicketNumber = null;
			list_CarrierOrderWrapper.add(cow);
		}
		if (list_CarrierOrderWrapper.isEmpty()) {
			strErrorInPlanReview = ERROR_NO_MY_ORDERS;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_NO_MY_ORDERS));
		}
	}

	//PLANS_CONFIRMED = Enrollment Review. READY_IMPLEMENTATION_PLANS = Plan Review
	//Enrollment Review Orders
	public void seeMyEnrollmentReviewOrders() {
		strErrorInEnrollmentReview = '';
		// Group Carrier Orders by Account
		map_COWLI = new Map<String, CarrierOrderWrapper>();

		set_AccountName = new Set<string>();

		for (Carrier_Order__c coRec : [
			SELECT
				ID,
				Name,
				Implementation_Stage__c,
				Follow_Up_Date__c,
				Benefit_Order__c,
				Benefit_Order__r.Account__c,
				Benefit_Order__r.Account__r.Name,
				Benefit_Order__r.Age__c,
				Renewal_Date__c,
				Follow_Up_Notes__c,
				Facilitator_2_Enrollment_Review_Notes__c,
				Parent_Carrier_Order__c,
				Parent_Carrier_Order__r.Name
			FROM Carrier_Order__c
			WHERE
				Implementation_Stage__c IN (:CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS)
				AND RecordTypeId = :strCOBTRecordTypeId
				AND Facilitator_2_Enrollment_Review__c = :IdLoggedInUser
				AND Benefit_Order__c != NULL
			ORDER BY Renewal_Date__c ASC, Benefit_Order__r.Age__c DESC
		]) {
			if (coRec.Benefit_Order__r.Account__c == null)
				continue;

			string strActName = coRec.Benefit_Order__r.Account__r.name;
			set_AccountName.add(strActName);
			CarrierOrderWrapper cow = map_COWLI.get(strActName);
			if (cow == null) {
				map_COWLI.put(strActName, new CarrierOrderWrapper(new List<CarrierOrderWrapperLineItem>()));
			}
			CarrierOrderWrapperLineItem cowli = new CarrierOrderWrapperLineItem();
			cowli.objCarrierOrderLI = coRec;
			cowli.strRenewalDate = string.valueOf(coRec.Renewal_Date__c);
			cowli.blnIsLineItemMarkedComplete = false;
			map_COWLI.get(strActName).list_COWLines.add(cowli);
		}
		if (map_COWLI.values().size() == 0) {
			strErrorInEnrollmentReview = ERROR_NO_MY_ORDERS;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_NO_MY_ORDERS));
		}
	}

	public PageReference saveMyEnrollmentReviewOrders() {
		strErrorInEnrollmentReview = '';
		List<Carrier_Order__c> list_MyERCOToUpdate = new List<Carrier_Order__c>();

		for (CarrierOrderWrapper cow : map_COWLI.values()) {
			List<CarrierOrderWrapperLineItem> checkCOWLIs = new List<CarrierOrderWrapperLineItem>();
			checkCOWLIs = cow.list_COWLines;
			for (CarrierOrderWrapperLineItem cowli : checkCOWLIs) {
				if (cowli.objCarrierOrderLI.Follow_Up_Date__c != null && cowli.objCarrierOrderLI.Follow_Up_Date__c > system.today().addDays(2)) {
					//cowli.objCarrierOrderLI.Follow_Up_Date__c = null;
					strErrorInEnrollmentReview = ERROR_FOLLOWUP_DATE;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_FOLLOWUP_DATE));
					break;
				}
				if (cowli.blnIsLineItemMarkedComplete) {
					if (cowli.objCarrierOrderLI.Implementation_Stage__c == CO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS) {
						cowli.objCarrierOrderLI.Implementation_Stage__c = CO_STAGE_READY_SEND_ENROLLMENTREVIEW;
						cowli.objCarrierOrderLI.Enrollment_Review_Completed_Date_Time__c = System.now();
					}
				}
				list_MyERCOToUpdate.add(cowli.objCarrierOrderLI);
			}
		}
		if (list_MyERCOToUpdate.size() > 0 && String.isBlank(strErrorInEnrollmentReview)) {
			update list_MyERCOToUpdate;
		}
		if (String.isBlank(strErrorInEnrollmentReview)) {
			redirectToFacilitator2Page();
		}

		return null;
	}

	public PageReference saveMyPlanReviewOrders() {
		strErrorInPlanReview = '';
		List<Carrier_Order__c> list_MyPRCOToUpdate = new List<Carrier_Order__c>();

		for (CarrierOrderWrapper cow : list_CarrierOrderWrapper) {
			if (cow.objCarrierOrder.Follow_Up_Date__c != null && cow.objCarrierOrder.Follow_Up_Date__c > system.today().addDays(2)) {
				cow.objCarrierOrder.Follow_Up_Date__c = null;
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ERROR_FOLLOWUP_DATE));
				strErrorInPlanReview = ERROR_FOLLOWUP_DATE;
				break;
			}
			list_MyPRCOToUpdate.add(cow.objCarrierOrder);
		}
		if (list_MyPRCOToUpdate.size() > 0 && String.isBlank(strErrorInPlanReview)) {
			update list_MyPRCOToUpdate;
		}
		if (String.isBlank(strErrorInPlanReview)) {
			redirectToFacilitator2Page();
		}

		return null;
	}

	public PageReference redirectToFacilitator2Page() {
		PageReference redirectToFac2 = new PageReference('/apex/BTCOFacilitator2ListView');
		redirectToFac2.setRedirect(true);
		return redirectToFac2;
	}

	public class CarrierOrderWrapperLineItem {
		public Carrier_Order__c objCarrierOrderLI { get; set; }
		public String strRenewalDate { get; set; }
		public Boolean blnIsLineItemMarkedComplete { get; set; }
		// Constructor
		public CarrierOrderWrapperLineItem() {
		}
		//map of COW Key to COWLIs
		//COW - >
		//AccountName + list of COWLIs
		//COWLI = CO + bln
	}

	public class CarrierOrderWrapper {
		public Carrier_Order__c objCarrierOrder { get; set; }
		public List<Carrier_Order__c> list_GroupedCO { get; set; }
		public string strTicketId { get; set; }
		public string strTicketNumber { get; set; }
		public String strAccountName { get; set; }
		public List<CarrierOrderWrapperLineItem> list_COWLines { get; set; }
		// Constructor
		public CarrierOrderWrapper() {
		}
		// Constructor
		public CarrierOrderWrapper(List<CarrierOrderWrapperLineItem> wlist_COWLIs) {
			list_COWLines = wlist_COWLIs;
		}
		// Constructor
		public CarrierOrderWrapper(List<Carrier_Order__c> list_COs) {
			list_GroupedCO = list_COs;
		}

		public Integer numOfGroupedCO {
			get {
				return list_COWLines.size();
			}
			set;
		}

		public Id firstOfList {
			get {
				return list_COWLines[0].objCarrierOrderLI.Id;
			}
			set;
		}
	}

	//**Ticket Start ****/
	public PageReference ShowTicketCreatedByMe() {
		strTicketFilter = 'created';
		RetriveTickets(strTicketFilter);
		return null;
	}

	public PageReference ShowTicketOwnedByMe() {
		strTicketFilter = 'owned';
		RetriveTickets(strTicketFilter);
		return null;
	}

	public PageReference ShowClosedTicket() {
		strTicketFilter = 'closed';
		RetriveTickets(strTicketFilter);
		return null;
	}

	private void countTicket() {
		intNoOfTicketCreated = 0;
		intNoOfTicketClosed = 0;
		intNoOfTicketOnwed = 0;
		for (Ticket__c tck : [
			SELECT Id, CreatedById, Carrier_Order__c, OwnerId, Closed_Within_7_Days__c, Closed_By__c, Status__c
			FROM Ticket__c
			WHERE
				Name != NULL
				AND ((CreatedById = :IdLoggedInUser
				AND Carrier_Order__c != NULL
				AND status__c != :TICKET_STATUS_CLOSED)
				OR (OwnerId = :IdLoggedInUser
				AND Status__c != :TICKET_STATUS_CLOSED)
				OR (CreatedById = :IdLoggedInUser
				AND Carrier_Order__c != NULL
				AND Status__c = :TICKET_STATUS_CLOSED
				AND Closed_Within_7_Days__c = TRUE))
		]) {
			//Created By me
			if (tck.CreatedById == IdLoggedInUser && tck.Carrier_Order__c != null && tck.Status__c != TICKET_STATUS_CLOSED) {
				intNoOfTicketCreated = intNoOfTicketCreated + 1;
			}
			//Owned By me
			if (tck.OwnerId == IdLoggedInUser && tck.Status__c != TICKET_STATUS_CLOSED) {
				intNoOfTicketOnwed = intNoOfTicketOnwed + 1;
			}
			//Closed By me
			if (tck.CreatedById == IdLoggedInUser && tck.Carrier_Order__c != null && tck.Status__c == TICKET_STATUS_CLOSED && tck.Closed_Within_7_Days__c == true) {
				intNoOfTicketClosed = intNoOfTicketClosed + 1;
			}
		}
	}

	private void RetriveTickets(string dataType) {
		try {
			list_TicketWrapper = new List<TicketWrapper>();
			string query = 'select id,Status__c,Carrier_Order__c,Carrier_Order__r.name,Createddate,LastModifieddate,';
			query = query + ' Carrier_Order__r.Renewal_Date__c,Escalation_Reason__c,Escalation_Reason_Detail__c,Name,';
			query = query + ' Description__c, Reporting_Team__c from Ticket__c where Name!=null ';
			if (dataType == 'created') {
				query = query + '  and Carrier_Order__c!=null and Status__c!=:TICKET_STATUS_CLOSED';
				query = query + '  and CreatedById=:IdLoggedInUser';
			}
			if (dataType == 'owned') {
				query = query + ' and Status__c!=:TICKET_STATUS_CLOSED';
				query = query + '  and OwnerId=:IdLoggedInUser';
			}
			if (dataType == 'closed') {
				query = query + ' and Carrier_Order__c!=null and Status__c=:TICKET_STATUS_CLOSED and Closed_Within_7_Days__c=true';
				query = query + ' and CreatedById=:IdLoggedInUser and Closed_By__c!=:IdLoggedInUser ';
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

	private integer getNoOfdays(Datetime dFrom, Datetime dTo) {
		integer nod = 0;
		Date fromDate = date.newinstance(dFrom.year(), dFrom.month(), dFrom.day());
		Date toDate = date.newinstance(dTo.year(), dTo.month(), dTo.day());
		nod = fromDate.daysBetween(toDate);
		return nod;
	}

	public class TicketWrapper {
		public Ticket__c objTicket { get; set; }
		public string strRenewalDate { get; set; }
		public string strCreatedDate { get; set; }
		public string strModifiedDate { get; set; }
		public integer intDaySinceLastCreated { get; set; }
	}
	//***Ticket End*****/
}