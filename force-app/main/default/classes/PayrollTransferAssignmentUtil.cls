/*
    By: PR
    Date: Sep-2-19
    Description: This class contains "Payroll Transfer" Order assignment logic.
*/
public with sharing class PayrollTransferAssignmentUtil {
	map<string, set<Id>> map_skillTypeAdvocateIdSet = new Map<string, set<Id>>();

	map<string, list<Benefit_Order_Allocation__c>> map_monthDateBOAList = new Map<string, list<Benefit_Order_Allocation__c>>();
	Map<Id, Transition_to_Fulfillment__c> map_TTFIdsRecord = new Map<Id, Transition_to_Fulfillment__c>();
	Map<Id, Transition_to_Fulfillment__c> map_OppIdTTFRecord = new Map<Id, Transition_to_Fulfillment__c>(); //need this map for TTF Auto assignment on before insert of TTF record
	public Map<string, Map<Id, Benefit_Order_Allocation__c>> map_startEndDate2UserIdBOA = new Map<string, Map<Id, Benefit_Order_Allocation__c>>();
	Map<string, Map<Id, Decimal>> map_startEndDate2UserIdCurrentOrderCount = new Map<string, Map<Id, Decimal>>();
	Map<string, Map<Id, Decimal>> map_startEndDate2UserIdWeekCap = new Map<string, Map<Id, Decimal>>();
	Map<string, Map<Id, Datetime>> map_startEndDate2UserIdLastAssignedDateTime = new Map<string, Map<Id, Datetime>>();
	Map<string, Set<Id>> map_startEndDate2RecentlyBackInOfficeUserIdSet = new Map<string, Set<Id>>();
	map<Id, Decimal> map_BOAIdEmployeeCount = new Map<Id, Decimal>(); //this map is used for containing the updated Employee count for each BOA during the process
	set<Id> set_usersWithBOAAvailable = new Set<Id>();
	static final String BIGDESKORDER = 'BigDesk Order';
	static final String BIGDESK_100PLUS = 'Big Desk 100+';
	static final String BULKDIRECTORDER = 'Bulk Direct Order';
	static final String ISBULKDEAL = 'Y';
	static final String BULKORDER = 'Bulk Order';
	static final String DIRECTORDER = 'Direct Order';
	static final String GOLDTIER = 'Gold';

	public PayrollTransferAssignmentUtil() {
	}

	//======================================Data Setup Section Starts===========================
	// set up Adovcate Skill based data
	public void getAdvocateDetails() {
		Map<Id, set<string>> map_UserIdSkillSet = new Map<Id, set<string>>();
		map_skillTypeAdvocateIdSet = new Map<string, set<Id>>();

		//setting up "user & Advocate Skills" to confirm number of skilss for an advocate
		for (User_Skill__c skillRec : [
			SELECT
				Id,
				Skill__r.Payroll_Transfer_Skills__c,
				Skill__r.Partner__c,
				User_Name__c,
				User_Role__c,
				User_Role__r.User__c,
				User_Role__r.User__r.Out_Of_Office__c,
				User_Role__r.User__r.Back_In_Office_Date_Time__c
			FROM User_Skill__c
			WHERE
				Skill_Role_Name__c = 'Payroll Transfer Advocate'
				AND User_Role__r.User__r.IsActive = TRUE
				AND Skill__r.Payroll_Transfer_Skills__c != NULL
				AND User_Role__r.User__r.Out_Of_Office__c = FALSE
		]) {
			if (set_usersWithBOAAvailable.size() > 0 && !set_usersWithBOAAvailable.contains(skillRec.User_Role__r.User__c)) {
				continue;
			}

			set<String> set_tempSkillSet = new Set<String>();
			if (map_UserIdSkillSet.containsKey(skillRec.User_Role__r.User__c)) {
				set_tempSkillSet = map_UserIdSkillSet.get(skillRec.User_Role__r.User__c);
			}
			set_tempSkillSet.add(skillRec.Skill__r.Payroll_Transfer_Skills__c);
			map_UserIdSkillSet.put(skillRec.User_Role__r.User__c, set_tempSkillSet);

			if (skillRec?.Skill__r?.Partner__c != null) {
				if (map_UserIdSkillSet.containsKey(skillRec.User_Role__r.User__c)) {
					set_tempSkillSet = map_UserIdSkillSet.get(skillRec.User_Role__r.User__c);
				}
				set_tempSkillSet.add(skillRec.Skill__r.Partner__c);
				map_UserIdSkillSet.put(skillRec.User_Role__r.User__c, set_tempSkillSet);
			}
		}

		// segregate "Advocates" based on skills
		if (map_UserIdSkillSet.keySet().size() > 0) {
			for (Id userId : map_UserIdSkillSet.keySet()) {
				set<string> set_UserSkill = map_UserIdSkillSet.get(userId);

				if (set_UserSkill != null && set_UserSkill.size() > 0) {
					set<Id> set_tempUserId = new Set<Id>();

					if (set_UserSkill.contains(BIGDESKORDER)) {
						if (map_skillTypeAdvocateIdSet.containsKey(BIGDESKORDER)) {
							set_tempUserId = map_skillTypeAdvocateIdSet.get(BIGDESKORDER);
						}

						set_tempUserId.add(userId);
						map_skillTypeAdvocateIdSet.put(BIGDESKORDER, set_tempUserId);
						set_UserSkill.remove(BIGDESKORDER);
					}

					if (set_UserSkill?.contains(GOLDTIER)) {
						if (map_skillTypeAdvocateIdSet.containsKey(GOLDTIER)) {
							set_tempUserId = map_skillTypeAdvocateIdSet.get(GOLDTIER);
						}
						set_tempUserId.add(userId);
						map_skillTypeAdvocateIdSet.put(GOLDTIER, set_tempUserId);
						set_UserSkill.remove(GOLDTIER);
					}

					if (set_UserSkill.size() > 1 && set_UserSkill.contains('Bulk Order') && set_UserSkill.contains('Direct Order')) {
						if (map_skillTypeAdvocateIdSet.containsKey('Bulk Direct Order')) {
							set_tempUserId = map_skillTypeAdvocateIdSet.get('Bulk Direct Order');
						}
						set_tempUserId.add(userId);
						map_skillTypeAdvocateIdSet.put('Bulk Direct Order', set_tempUserId);
						continue;
					}

					if (set_UserSkill.size() == 1 && set_UserSkill.contains('Bulk Order')) {
						if (map_skillTypeAdvocateIdSet.containsKey('Bulk Order')) {
							set_tempUserId = map_skillTypeAdvocateIdSet.get('Bulk Order');
						}
						set_tempUserId.add(userId);
						map_skillTypeAdvocateIdSet.put('Bulk Order', set_tempUserId);
						continue;
					} else if (set_UserSkill.size() == 1 && set_UserSkill.contains('Direct Order')) {
						if (map_skillTypeAdvocateIdSet.containsKey('Direct Order')) {
							set_tempUserId = map_skillTypeAdvocateIdSet.get('Direct Order');
						}
						set_tempUserId.add(userId);
						map_skillTypeAdvocateIdSet.put('Direct Order', set_tempUserId);
					}
				}
			}
		}
	}

	//This method populates the BOA, ORder Count and Week Cap
	public void getUserBOADetails(set<Date> set_weekStartDate) {
		map_startEndDate2UserIdBOA = new Map<string, Map<Id, Benefit_Order_Allocation__c>>();
		map_startEndDate2UserIdCurrentOrderCount = new Map<string, Map<Id, Decimal>>();
		map_startEndDate2UserIdWeekCap = new Map<string, Map<Id, Decimal>>();
		map_startEndDate2UserIdLastAssignedDateTime = new Map<string, Map<Id, Datetime>>();
		map_startEndDate2RecentlyBackInOfficeUserIdSet = new Map<string, Set<Id>>();
		map_BOAIdEmployeeCount = new Map<Id, Decimal>();

		Boolean boolOldValue = Cache.skipfunc;
		Cache.skipfunc = true;
		string advocateRecordTypeId = cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate');
		Cache.skipfunc = boolOldValue;

		BusinessHours businessHourObj = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE][0];

		if (set_weekStartDate != null && set_weekStartDate.size() > 0) {
			for (Benefit_Order_Allocation__c boaObj : [
				SELECT
					Id,
					Week_End_Date__c,
					Week_Start_Date__c,
					Month__c,
					Year__c,
					Last_Order_Assigned_Date_Time__c,
					Payroll_Transfer_FBOS_Forecast__c,
					User__c,
					Open_Order_Count__c,
					Week_Order_Capacity__c,
					Open_Order_Employee_Count__c,
					User_Role__r.User__r.Back_In_Office_Date_Time__c,
					User_Role__r.User__c
				FROM Benefit_Order_Allocation__c
				WHERE
					Week_Start_Date__c IN :set_weekStartDate
					AND User_Role__r.User__r.Out_Of_Office__c = FALSE
					AND Payroll_Transfer_FBOS_Forecast__c != NULL
					AND Payroll_Transfer_FBOS_Forecast__r.RecordTypeId = :advocateRecordTypeId
			]) {
				string StartEndDateStr = getDateString(boaObj.Week_Start_Date__c, boaObj.Week_End_Date__c);
				set_usersWithBOAAvailable.add(boaObj.User_Role__r.User__c); //to track eligible users with BOA
				Map<Id, Benefit_Order_Allocation__c> map_UserIdBOARec = new Map<Id, Benefit_Order_Allocation__c>();
				Map<Id, Decimal> map_UserIdOpenOrderCount = new Map<Id, Decimal>();
				Map<Id, Decimal> map_UserIdWeekCap = new Map<Id, Decimal>();
				Map<Id, Datetime> map_UserIdLastAssignedDateTime = new Map<Id, Datetime>();
				Set<Id> set_latestBackInOfficeuserId = new Set<Id>();

				//Employee count map
				map_BOAIdEmployeeCount.put(boaObj.Id, boaObj.Open_Order_Employee_Count__c);

				//user iD & BOA
				if (map_startEndDate2UserIdBOA.containsKey(StartEndDateStr)) {
					map_UserIdBOARec = map_startEndDate2UserIdBOA.get(StartEndDateStr);
				}
				map_UserIdBOARec.put(boaObj.User__c, boaObj);
				map_startEndDate2UserIdBOA.put(StartEndDateStr, map_UserIdBOARec);

				//order Count logic
				if (map_startEndDate2UserIdCurrentOrderCount.containsKey(StartEndDateStr)) {
					map_UserIdOpenOrderCount = map_startEndDate2UserIdCurrentOrderCount.get(StartEndDateStr);
				}
				map_UserIdOpenOrderCount.put(boaObj.User__c, boaObj.Open_Order_Count__c);
				map_startEndDate2UserIdCurrentOrderCount.put(StartEndDateStr, map_UserIdOpenOrderCount);

				//User Id & Week Cap logic
				if (map_startEndDate2UserIdWeekCap.containsKey(StartEndDateStr)) {
					map_UserIdWeekCap = map_startEndDate2UserIdWeekCap.get(StartEndDateStr);
				}
				//Back In office in last 8 hours "logic"
				decimal weekCap = boaObj.Week_Order_Capacity__c;
				if (boaObj.User_Role__r.User__r.Back_In_Office_Date_Time__c != null) {
					long milliSeconds = BusinessHours.diff(businessHourObj.Id, boaObj.User_Role__r.User__r.Back_In_Office_Date_Time__c, System.now());
					long diffInHours = milliSeconds / 1000 / 60 / 60;

					if (diffInHours < 8) {
						weekCap = (weekCap - boaObj.Open_Order_Count__c) / 2;
						weekCap = weekCap.round(System.RoundingMode.DOWN);
					}
				}
				map_UserIdWeekCap.put(boaObj.User__c, weekCap);
				map_startEndDate2UserIdWeekCap.put(StartEndDateStr, map_UserIdWeekCap);

				//User Id & last assignment date/time
				if (map_startEndDate2UserIdLastAssignedDateTime.containsKey(StartEndDateStr)) {
					map_UserIdLastAssignedDateTime = map_startEndDate2UserIdLastAssignedDateTime.get(StartEndDateStr);
				}
				map_UserIdLastAssignedDateTime.put(boaObj.User__c, boaObj.Last_Order_Assigned_Date_Time__c);
				map_startEndDate2UserIdLastAssignedDateTime.put(StartEndDateStr, map_UserIdLastAssignedDateTime);
			}
		}
	}

	//returns string for the dates received as parameters.
	public string getDateString(date startDate, date endDate) {
		if (startDate != null && endDate != null) {
			return string.valueof(startDate.Day()) +
				'/' +
				string.valueof(startDate.Month()) +
				'/' +
				string.valueof(startDate.Year()) +
				':' +
				string.valueof(endDate.Day()) +
				'/' +
				string.valueof(endDate.Month()) +
				'/' +
				string.valueof(endDate.Year());
		}
		return null;
	}

	//========================================Data Setup Section Ends=====================================

	//=========================================Assignment Logic==========================================

	//Desc: main method handling assignmeent core logic
	public void assignOrdersToAdvocates(list<Transition_to_Fulfillment__c> lst_transitionRecords) {
		if (lst_transitionRecords != null && lst_transitionRecords.size() > 0) {
			List<Order> lst_toUpateAssignedOrdersList = new List<Order>();
			List<Order_BOA_Relationship__c> lst_toInsertOrderBOARelationshipObj = new List<Order_BOA_Relationship__c>();
			Map<Id, Bulk_Migration_Request__c> map_toUpdateBMRRecords = new Map<Id, Bulk_Migration_Request__c>();

			for (Transition_to_Fulfillment__c ttfRec : lst_transitionRecords) {
				if (ttfRec.Id == null) {
					map_OppIdTTFRecord.put(ttfRec.Opportunity__c, ttfRec);
				} else {
					map_TTFIdsRecord.put(ttfRec.Id, ttfRec);
				}
			}

			list<Order> lst_TTFRelatedOrders;
			if (map_TTFIdsRecord.size() > 0) {
				lst_TTFRelatedOrders = [
					SELECT
						Id,
						Transition_to_Fulfillment__c,
						First_Check_Date__c,
						Active_Employee_Count__c,
						Bulk_Migration__c,
						Contractor_Count__c,
						Inactive_Employee_Count__c,
						Status,
						Transition_to_Fulfillment__r.Bulk_Deal__c,
						OwnerId,
						Bulk_Migration__r.OwnerId,
						Bulk_Migration__r.Facilitator__c,
						OpportunityId,
						Big_Desk_Sandbox_Type__c,
						Bulk_Migration__r.Big_Desk_Sandbox_Type__c,
						Account.Sold_By_Partner_Tier__c
					FROM Order
					WHERE
						Status != 'Closed: Payroll Run'
						AND Status != 'Closed: Canceled'
						AND Status != 'Blocked'
						AND Status != 'Rejected'
						AND Order_Owner_Name__c = 'Company Migration - Unassigned Orders'
						AND Transition_to_Fulfillment__c IN :map_TTFIdsRecord.keySet()
						AND First_Check_Date__c != NULL
					ORDER BY First_Check_Date__c ASC
				];
			} else if (map_OppIdTTFRecord.size() > 0) {
				lst_TTFRelatedOrders = [
					SELECT
						Id,
						Transition_to_Fulfillment__c,
						First_Check_Date__c,
						Active_Employee_Count__c,
						Bulk_Migration__c,
						Contractor_Count__c,
						Inactive_Employee_Count__c,
						Status,
						Transition_to_Fulfillment__r.Bulk_Deal__c,
						OwnerId,
						Bulk_Migration__r.OwnerId,
						Bulk_Migration__r.Facilitator__c,
						OpportunityId,
						Big_Desk_Sandbox_Type__c,
						Bulk_Migration__r.Big_Desk_Sandbox_Type__c,
						Account.Sold_By_Partner_Tier__c
					FROM Order
					WHERE
						Status != 'Closed: Payroll Run'
						AND Status != 'Closed: Canceled'
						AND Status != 'Blocked'
						AND Status != 'Rejected'
						AND Order_Owner_Name__c = 'Company Migration - Unassigned Orders'
						AND OpportunityId IN :map_OppIdTTFRecord.keySet()
						AND First_Check_Date__c != NULL
					ORDER BY First_Check_Date__c ASC
				];
			}

			// not able to find any related Order
			if (lst_TTFRelatedOrders == null || lst_TTFRelatedOrders.size() == 0) {
				return;
			}

			Set<Date> set_weekStartDate = new Set<Date>();
			Map<Id, Date> map_bmrObjIdOrderEarliestCheckDate = new Map<Id, Date>();

			// filter out all the months and year for the eligible orders
			for (Order orderObj : lst_TTFRelatedOrders) {
				set_weekStartDate.add(getWeekStartEndDate_MonthVise(orderObj.First_Check_Date__c).get(0));

				if (orderObj.Bulk_Migration__c != null && !string.valueOf(orderObj.Bulk_Migration__r.OwnerId).startsWith('005')) {
					if (!map_bmrObjIdOrderEarliestCheckDate.containsKey(orderObj.Bulk_Migration__c)) {
						map_bmrObjIdOrderEarliestCheckDate.put(orderObj.Bulk_Migration__c, orderObj.First_Check_Date__c);
					}
				}
			}

			// call this method to setup related BOA info into data aggregation components
			getUserBOADetails(set_weekStartDate);
			getAdvocateDetails();

			//populating TTF and related Orders map
			for (Order orderRec : lst_TTFRelatedOrders) {
				List<Id> lst_advocateIdsWithLowestAssignedOrders = new List<Id>();
				string StartEndDateStr = getWeekStartEndDateString(orderRec.First_Check_Date__c);
				Map<Id, Benefit_Order_Allocation__c> map_userIdBOARec = map_startEndDate2UserIdBOA.get(StartEndDateStr);
				Transition_to_Fulfillment__c ttfObj = (orderRec.Transition_to_Fulfillment__c != null
					? map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c)
					: map_OppIdTTFRecord.get(orderRec.OpportunityId));
				//map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c);
				Map<Id, DateTime> map_AdvocateIdLastAssignmentDateTime = map_startEndDate2UserIdLastAssignedDateTime.get(StartEndDateStr);

				//SJay - 12-27-2019 - Added Previous Payroll assignment here.
				if (ttfObj != null && ttfObj.Previous_Payroll_Provider__c != null) {
					orderRec.Previous_Payroll_Provider__c = ttfObj.Previous_Payroll_Provider__c;
				}

				// If Order has a BMR attached, 1) if BMR is assigned we want BMR owner 2) If BMR
				if (orderRec.Bulk_Migration__c != null) {
					if (string.valueOf(orderRec.Bulk_Migration__r.OwnerId).StartsWith('005')) {
						lst_advocateIdsWithLowestAssignedOrders.add(orderRec.Bulk_Migration__r.OwnerId);
					} else if (map_toUpdateBMRRecords.containsKey(orderRec.Bulk_Migration__c)) {
						//finding owner in this execution instance handling logic
						lst_advocateIdsWithLowestAssignedOrders.add(map_toUpdateBMRRecords.get(orderRec.Bulk_Migration__c).OwnerId);
					} else if (map_bmrObjIdOrderEarliestCheckDate.containsKey(orderRec.Bulk_Migration__c)) {
						//trying to find a new Advocate for BMR first time, we want to find Advocate for earliest date handling logic
						Order tempOrderObj = new Order(First_Check_Date__c = map_bmrObjIdOrderEarliestCheckDate.get(orderRec.Bulk_Migration__c));
						lst_advocateIdsWithLowestAssignedOrders = getAdvocatesWith_LowestNumberOfOrdersAssigned_ForOrderCheckDateWeek(getSetOfAdvocateIdsBasedOnSkills(orderRec), tempOrderObj);
					}
				} else {
					lst_advocateIdsWithLowestAssignedOrders = getAdvocatesWith_LowestNumberOfOrdersAssigned_ForOrderCheckDateWeek(getSetOfAdvocateIdsBasedOnSkills(orderRec), orderRec);
				}

				//criteria based assignment starts===========================
				if (lst_advocateIdsWithLowestAssignedOrders.size() > 0 && lst_advocateIdsWithLowestAssignedOrders.get(0) != null && map_userIdBOARec != null && map_userIdBOARec.size() > 0) {
					Map<Id, Decimal> map_AdvocateCurrentOrderCount = new Map<Id, Decimal>();
					if (lst_advocateIdsWithLowestAssignedOrders.size() == 1) {
						orderRec.OwnerId = lst_advocateIdsWithLowestAssignedOrders.get(0);
						orderRec.Status = 'Collecting Documents';
						lst_toUpateAssignedOrdersList.add(orderRec);
						//Update order BOA relation

						lst_toInsertOrderBOARelationshipObj.add(new Order_BOA_Relationship__c(Orders__c = orderRec.Id, Benefit_Order_Allocation__c = map_userIdBOARec.get(orderRec.OwnerId).Id));

						//update BMR owner Logic
						if (orderRec.Bulk_Migration__c != null && !map_toUpdateBMRRecords.containsKey(orderRec.Bulk_Migration__c)) {
							Bulk_Migration_Request__c bmrObj = new Bulk_Migration_Request__c(Id = orderRec.Bulk_Migration__c);
							bmrObj.OwnerId = orderRec.OwnerId;
							map_toUpdateBMRRecords.put(orderRec.Bulk_Migration__c, bmrObj);
						}

						//==============after assigned: Order & Employee count increment in the map code========!START!==============

						if (String.isNotBlank(StartEndDateStr)) {
							//order count increment logic
							map_AdvocateCurrentOrderCount = map_startEndDate2UserIdCurrentOrderCount.get(StartEndDateStr);
							decimal lastCount = map_AdvocateCurrentOrderCount.get(orderRec.OwnerId);
							map_AdvocateCurrentOrderCount.put(orderRec.OwnerId, ++lastCount);
							map_startEndDate2UserIdCurrentOrderCount.put(StartEndDateStr, map_AdvocateCurrentOrderCount);

							//employee count increment logic
							Benefit_Order_Allocation__c boaObj = map_userIdBOARec.get(orderRec.OwnerId);
							lastCount = 0;
							Decimal decLastActiveEmployeeCount = orderRec.Active_Employee_Count__c != null ? orderRec.Active_Employee_Count__c : 0;
							if (map_BOAIdEmployeeCount.containsKey(boaObj.Id)) {
								lastCount = map_BOAIdEmployeeCount.get(boaObj.Id);
								map_BOAIdEmployeeCount.put(boaObj.Id, lastCount + decLastActiveEmployeeCount);
							} else {
								lastCount = (boaObj.Open_Order_Employee_Count__c != null ? boaObj.Open_Order_Employee_Count__c : 0);
								map_BOAIdEmployeeCount.put(boaObj.Id, lastCount + decLastActiveEmployeeCount);
							}

							//last datetime updating logic
							map_AdvocateIdLastAssignmentDateTime.put(orderRec.OwnerId, System.now());
							map_startEndDate2UserIdLastAssignedDateTime.put(StartEndDateStr, map_AdvocateIdLastAssignmentDateTime);
						}

						//==============assigned order count increment in the map code=========!END!=============
					} else {
						//if more than two Advocates matched the "Lowest assigned order count" criteria than we execute below logic

						set<Id> set_advocateIdWithLowestEmployeeCount = new Set<Id>();
						Decimal lowestEECount_deci;
						if (string.isNotBlank(StartEndDateStr)) {
							for (Id advocateId : lst_advocateIdsWithLowestAssignedOrders) {
								if (map_userIdBOARec.containsKey(advocateId)) {
									Benefit_Order_Allocation__c boaObj = map_userIdBOARec.get(advocateId);
									decimal newEECount_deci = boaObj.Open_Order_Employee_Count__c; //how to handle exact value...can we get it from order ?

									if (newEECount_deci == null) {
										newEECount_deci = 0;
									}

									if (lowestEECount_deci == null || newEECount_deci < lowestEECount_deci) {
										lowestEECount_deci = newEECount_deci;
										set_advocateIdWithLowestEmployeeCount = new Set<Id>();
										set_advocateIdWithLowestEmployeeCount.add(advocateId);
									} else if (newEECount_deci == lowestEECount_deci) {
										set_advocateIdWithLowestEmployeeCount.add(advocateId);
									}
								}
							}
						}

						if (set_advocateIdWithLowestEmployeeCount.size() == 1) {
							list<Id> lst_advocateIds = new List<Id>();
							lst_advocateIds.addAll(set_advocateIdWithLowestEmployeeCount);
							orderRec.OwnerId = lst_advocateIds.get(0);
							orderRec.Status = 'Collecting Documents';
							lst_toUpateAssignedOrdersList.add(orderRec);
							lst_toInsertOrderBOARelationshipObj.add(new Order_BOA_Relationship__c(Orders__c = orderRec.Id, Benefit_Order_Allocation__c = map_userIdBOARec.get(orderRec.OwnerId).Id));

							//update BMR owner Logic
							if (orderRec.Bulk_Migration__c != null && !map_toUpdateBMRRecords.containsKey(orderRec.Bulk_Migration__c)) {
								Bulk_Migration_Request__c bmrObj = new Bulk_Migration_Request__c(Id = orderRec.Bulk_Migration__c);
								bmrObj.OwnerId = orderRec.OwnerId;
								map_toUpdateBMRRecords.put(orderRec.Bulk_Migration__c, bmrObj);
							}
							//==============assigned Employee count increment in the map code========!START!==============

							if (string.isNotBlank(StartEndDateStr)) {
								//eomplyee count increment
								Benefit_Order_Allocation__c boaObj = map_userIdBOARec.get(orderRec.OwnerId);
								decimal lastCount;
								Decimal decActiveEmployeeCount = 0;
								if (orderRec.Active_Employee_Count__c != null) {
									decActiveEmployeeCount = orderRec.Active_Employee_Count__c;
								}

								if (map_BOAIdEmployeeCount.containsKey(boaObj.Id)) {
									lastCount = map_BOAIdEmployeeCount.get(boaObj.Id);
									map_BOAIdEmployeeCount.put(boaObj.Id, lastCount + decActiveEmployeeCount);
								} else {
									lastCount = (boaObj.Open_Order_Employee_Count__c != null ? boaObj.Open_Order_Employee_Count__c : 0);
									map_BOAIdEmployeeCount.put(boaObj.Id, lastCount + decActiveEmployeeCount);
								}

								//order count increment logic
								lastCount = 0;
								map_AdvocateCurrentOrderCount = map_startEndDate2UserIdCurrentOrderCount.get(StartEndDateStr);
								lastCount = map_AdvocateCurrentOrderCount.get(orderRec.OwnerId);
								map_AdvocateCurrentOrderCount.put(orderRec.OwnerId, ++lastCount);
								map_startEndDate2UserIdCurrentOrderCount.put(StartEndDateStr, map_AdvocateCurrentOrderCount);

								//last datetime updating logic
								map_AdvocateIdLastAssignmentDateTime.put(orderRec.OwnerId, System.now());
								map_startEndDate2UserIdLastAssignedDateTime.put(StartEndDateStr, map_AdvocateIdLastAssignmentDateTime);
							}
							//==============assigned Employee count increment in the map code========!END!==============
						} else if (set_advocateIdWithLowestEmployeeCount.size() > 1) {
							set<Id> set_advocateIdWithLatestAssignmentDate = new Set<Id>();
							DateTime oldestAssignmentDateTime;
							if (string.isNotBlank(StartEndDateStr)) {
								for (Id advocateId : set_advocateIdWithLowestEmployeeCount) {
									if (map_AdvocateIdLastAssignmentDateTime.containsKey(advocateId)) {
										Datetime newAssignmentDateTime = map_AdvocateIdLastAssignmentDateTime.get(advocateId);

										if (set_advocateIdWithLatestAssignmentDate.size() == 0 || newAssignmentDateTime < oldestAssignmentDateTime) {
											oldestAssignmentDateTime = newAssignmentDateTime;
											set_advocateIdWithLatestAssignmentDate = new Set<Id>();
											set_advocateIdWithLatestAssignmentDate.add(advocateId);
										} else if (newAssignmentDateTime == oldestAssignmentDateTime) {
											set_advocateIdWithLatestAssignmentDate.add(advocateId);
										}
									}
								}
							}

							if (set_advocateIdWithLatestAssignmentDate.size() > 0) {
								list<Id> lst_advocateIds = new List<Id>();
								lst_advocateIds.addAll(set_advocateIdWithLatestAssignmentDate);

								Id highestCapUser;
								decimal previousHighestCap = 0;
								for (Id userId : lst_advocateIds) {
									if (
										map_startEndDate2UserIdWeekCap.get(StartEndDateStr).containsKey(userId) && map_startEndDate2UserIdWeekCap.get(StartEndDateStr).get(userId) > previousHighestCap
									) {
										highestCapUser = userId;
										previousHighestCap = map_startEndDate2UserIdWeekCap.get(StartEndDateStr).get(userId);
									}
								}

								orderRec.OwnerId = (highestCapUser != null ? highestCapUser : lst_advocateIds.get(0));
								orderRec.Status = 'Collecting Documents';
								lst_toUpateAssignedOrdersList.add(orderRec);
								lst_toInsertOrderBOARelationshipObj.add(
									new Order_BOA_Relationship__c(Orders__c = orderRec.Id, Benefit_Order_Allocation__c = map_userIdBOARec.get(orderRec.OwnerId).Id)
								);

								//update BMR owner Logic
								if (orderRec.Bulk_Migration__c != null && !map_toUpdateBMRRecords.containsKey(orderRec.Bulk_Migration__c)) {
									Bulk_Migration_Request__c bmrObj = new Bulk_Migration_Request__c(Id = orderRec.Bulk_Migration__c);
									bmrObj.OwnerId = orderRec.OwnerId;
									map_toUpdateBMRRecords.put(orderRec.Bulk_Migration__c, bmrObj);
								}

								//order count increment logic
								map_AdvocateCurrentOrderCount = map_startEndDate2UserIdCurrentOrderCount.get(StartEndDateStr);
								decimal lastCount = map_AdvocateCurrentOrderCount.get(orderRec.OwnerId);
								map_AdvocateCurrentOrderCount.put(orderRec.OwnerId, ++lastCount);
								map_startEndDate2UserIdCurrentOrderCount.put(StartEndDateStr, map_AdvocateCurrentOrderCount);

								//employee count increment logic
								Benefit_Order_Allocation__c boaObj = map_userIdBOARec.get(orderRec.OwnerId);
								lastCount = 0;
								decimal orderActiveEmployeeCount = (orderRec.Active_Employee_Count__c != null ? orderRec.Active_Employee_Count__c : 0);
								if (map_BOAIdEmployeeCount.containsKey(boaObj.Id)) {
									lastCount = (map_BOAIdEmployeeCount.get(boaObj.Id) != null ? map_BOAIdEmployeeCount.get(boaObj.Id) : 0);
									map_BOAIdEmployeeCount.put(boaObj.Id, lastCount + orderActiveEmployeeCount);
								} else {
									lastCount = (boaObj.Open_Order_Employee_Count__c != null ? boaObj.Open_Order_Employee_Count__c : 0);
									map_BOAIdEmployeeCount.put(boaObj.Id, lastCount + orderActiveEmployeeCount);
								}

								//==============assigned last assignment date/time in the map code========!START!==============
								map_AdvocateIdLastAssignmentDateTime.put(orderRec.OwnerId, System.now());
								map_startEndDate2UserIdLastAssignedDateTime.put(StartEndDateStr, map_AdvocateIdLastAssignmentDateTime);
								//==============assigned Employee count increment in the map code========!END!==============
							} else {
								orderRec.Assignment_Error_Message__c = 'Not able to find eligible advocates based on last assigned count.';
								if (orderRec.Transition_to_Fulfillment__c != null) {
									map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c).TTF_Status__c = 'Sales Submitted';
								} else {
									map_OppIdTTFRecord.get(orderRec.OpportunityId).TTF_Status__c = 'Sales Submitted';
								}

								lst_toUpateAssignedOrdersList.add(orderRec);

								//update BMR error message too
								if (orderRec.Bulk_Migration__c != null && !map_toUpdateBMRRecords.containsKey(orderRec.Bulk_Migration__c)) {
									Bulk_Migration_Request__c bmrObj = new Bulk_Migration_Request__c(Id = orderRec.Bulk_Migration__c);
									bmrObj.Assignment_Error_Message__c = 'Not able to find eligible advocates based on last assigned count.';
									map_toUpdateBMRRecords.put(orderRec.Bulk_Migration__c, bmrObj);
									if (orderRec.Transition_to_Fulfillment__c != null) {
										map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c).TTF_Status__c = 'Sales Submitted';
									} else {
										map_OppIdTTFRecord.get(orderRec.OpportunityId).TTF_Status__c = 'Sales Submitted';
									}
								}

								continue;
							}
						} else if (set_advocateIdWithLowestEmployeeCount.size() == 0) {
							orderRec.Assignment_Error_Message__c = 'Not able to find eligible advocates based on employee count.';
							if (orderRec.Transition_to_Fulfillment__c != null) {
								map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c).TTF_Status__c = 'Sales Submitted';
							} else {
								map_OppIdTTFRecord.get(orderRec.OpportunityId).TTF_Status__c = 'Sales Submitted';
							}

							lst_toUpateAssignedOrdersList.add(orderRec);

							//update BMR error message too
							if (orderRec.Bulk_Migration__c != null && !map_toUpdateBMRRecords.containsKey(orderRec.Bulk_Migration__c)) {
								Bulk_Migration_Request__c bmrObj = new Bulk_Migration_Request__c(Id = orderRec.Bulk_Migration__c);
								bmrObj.Assignment_Error_Message__c = 'Not able to find eligible advocates based on employee count.';
								if (orderRec.Transition_to_Fulfillment__c != null) {
									map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c).TTF_Status__c = 'Sales Submitted';
								} else {
									map_OppIdTTFRecord.get(orderRec.OpportunityId).TTF_Status__c = 'Sales Submitted';
								}
								map_toUpdateBMRRecords.put(orderRec.Bulk_Migration__c, bmrObj);
							}
							continue;
						}
					}
				} else {
					//error handling
					orderRec.Assignment_Error_Message__c = 'Forecast allocations not setup/Cap already reached for the week of ' + StartEndDateStr.split(':').get(0);
					if (orderRec.Transition_to_Fulfillment__c != null) {
						map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c).TTF_Status__c = 'Sales Submitted';
					} else {
						map_OppIdTTFRecord.get(orderRec.OpportunityId).TTF_Status__c = 'Sales Submitted';
					}
					lst_toUpateAssignedOrdersList.add(orderRec);

					//update BMR error message too
					if (orderRec.Bulk_Migration__c != null && !map_toUpdateBMRRecords.containsKey(orderRec.Bulk_Migration__c)) {
						Bulk_Migration_Request__c bmrObj = new Bulk_Migration_Request__c(Id = orderRec.Bulk_Migration__c);
						bmrObj.Assignment_Error_Message__c = 'Forecast allocations not setup/Cap already reached for the week of ' + StartEndDateStr.split(':').get(0);
						if (orderRec.Transition_to_Fulfillment__c != null) {
							map_TTFIdsRecord.get(orderRec.Transition_to_Fulfillment__c).TTF_Status__c = 'Sales Submitted';
						} else {
							map_OppIdTTFRecord.get(orderRec.OpportunityId).TTF_Status__c = 'Sales Submitted';
						}
						map_toUpdateBMRRecords.put(orderRec.Bulk_Migration__c, bmrObj);
					}
				}
			}

			try {
				if (lst_toUpateAssignedOrdersList.size() > 0) {
					OrderTriggerHelper.isPayrollTransferAutoAssignment = true;
					update lst_toUpateAssignedOrdersList;
					OrderTriggerHelper.isPayrollTransferAutoAssignment = false;
				}
				if (lst_toInsertOrderBOARelationshipObj.size() > 0) {
					insert lst_toInsertOrderBOARelationshipObj;
				}
				if (map_toUpdateBMRRecords.keySet().size() > 0) {
					update map_toUpdateBMRRecords.values();
				}
			} catch (exception ex) {
				if (Trigger.isExecuting)
					Trigger.new[0].addError(ex.getMessage());
				else
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ex.getMessage()));
			}
		}
	}

	// method returns eligible advocates based on "Lowest Assigned Orders" criteria
	public list<Id> getAdvocatesWith_LowestNumberOfOrdersAssigned_ForOrderCheckDateWeek(set<Id> set_eligibleAdvocatesBasedOnSkills, Order orderObj) {
		if (set_eligibleAdvocatesBasedOnSkills != null && set_eligibleAdvocatesBasedOnSkills.size() > 0 && orderObj != null) {
			string StartEndDateStr = getWeekStartEndDateString(orderObj.First_Check_Date__c);

			Map<Id, Decimal> map_AdvocateCurrentOrderCount = new Map<Id, Decimal>();
			Map<Id, Decimal> map_UserIdWeekCap = new Map<Id, Decimal>();

			if (string.isNotBlank(StartEndDateStr)) {
				if (map_startEndDate2UserIdCurrentOrderCount.containsKey(StartEndDateStr)) {
					map_AdvocateCurrentOrderCount = map_startEndDate2UserIdCurrentOrderCount.get(StartEndDateStr);
				} else {
					//not able to find BOA records
					return new List<Id>();
				}

				if (map_startEndDate2UserIdWeekCap.containsKey(StartEndDateStr)) {
					map_UserIdWeekCap = map_startEndDate2UserIdWeekCap.get(StartEndDateStr);
				} else {
					//not able to find BOA records
					return new List<Id>();
				}

				set<Id> set_usersWithLowestOrdersAssigned = new Set<Id>();
				decimal lowestOrderAssignedCount_deci;
				set<Id> set_latestBackInOfficeUserIds = new Set<Id>();

				if (map_startEndDate2RecentlyBackInOfficeUserIdSet.containsKey(StartEndDateStr)) {
					set_latestBackInOfficeUserIds = map_startEndDate2RecentlyBackInOfficeUserIdSet.get(StartEndDateStr);
				}

				//this loop will give us "Lowest assigned orders to an advocate" count and "Advocates with the matching lowest assigned Order" count
				for (Id advocateId : set_eligibleAdvocatesBasedOnSkills) {
					decimal userWeekCap_deci = 0;
					if (map_UserIdWeekCap.containsKey(advocateId)) {
						userWeekCap_deci = map_UserIdWeekCap.get(advocateId);
					}

					if (userWeekCap_deci == null || userWeekCap_deci == 0) {
						//if week cap for Advocate is zero we want to skip that user
						continue;
					}

					if (map_AdvocateCurrentOrderCount.containsKey(advocateId)) {
						decimal newOrderAssignedCount_deci = map_AdvocateCurrentOrderCount.get(advocateId);

						if (newOrderAssignedCount_deci == null) {
							newOrderAssignedCount_deci = 0;
						}

						if (newOrderAssignedCount_deci >= userWeekCap_deci) {
							//Skip the users that have met their CAP
							continue;
						}

						if (lowestOrderAssignedCount_deci == null || newOrderAssignedCount_deci < lowestOrderAssignedCount_deci) {
							lowestOrderAssignedCount_deci = newOrderAssignedCount_deci;
							set_usersWithLowestOrdersAssigned = new Set<Id>();
							set_usersWithLowestOrdersAssigned.add(advocateId);
						} else if (newOrderAssignedCount_deci == lowestOrderAssignedCount_deci) {
							set_usersWithLowestOrdersAssigned.add(advocateId);
						}
					}
				}
				if (set_usersWithLowestOrdersAssigned != null && set_usersWithLowestOrdersAssigned.size() > 0) {
					List<Id> lst_tempIds = new List<Id>();
					lst_tempIds.addAll(set_usersWithLowestOrdersAssigned);
					return lst_tempIds;
				}
			}
		}

		return new List<Id>();
	}

	//=================================================Utility Section Starts=============================================
	/*
    This method returns set of User Ids based on Order Type
    Note: This method should be called only if "bulk & ttf owner" check has already been performed
    */
	public set<Id> getSetOfAdvocateIdsBasedOnSkills(Order objOrder) {
		set<Id> set_AdvocateIdsBasedOnSkill = new Set<Id>();
		set<Id> set_GoldAdvocates = new Set<Id>();
		set<Id> set_AdvocateIdsToReturn = new Set<Id>();

		Transition_to_Fulfillment__c objTTF = (objOrder.Transition_to_Fulfillment__c != null
			? map_TTFIdsRecord.get(objOrder.Transition_to_Fulfillment__c)
			: map_OppIdTTFRecord.get(objOrder.OpportunityId));

		String strOrderBigDeskFieldVal = objOrder.Big_Desk_Sandbox_Type__c;
		String strPartnerTierVal = objOrder.Account?.Sold_By_Partner_Tier__c;
		if (objOrder?.Bulk_Migration__r.Big_Desk_Sandbox_Type__c != null && objOrder.Bulk_Migration__r.Big_Desk_Sandbox_Type__c == BIGDESK_100PLUS) {
			strOrderBigDeskFieldVal = objOrder.Bulk_Migration__r.Big_Desk_Sandbox_Type__c;
		}

		if (String.isNotBlank(strOrderBigDeskFieldVal) && strOrderBigDeskFieldVal == BIGDESK_100PLUS && map_skillTypeAdvocateIdSet.containsKey(BIGDESKORDER)) {
			set_AdvocateIdsBasedOnSkill.addAll(map_skillTypeAdvocateIdSet.get(BIGDESKORDER));
		} else {
			if (map_skillTypeAdvocateIdSet != null && map_skillTypeAdvocateIdSet.keySet().size() > 0 && map_skillTypeAdvocateIdSet.containsKey(BULKDIRECTORDER)) {
				set_AdvocateIdsBasedOnSkill = map_skillTypeAdvocateIdSet.get(BULKDIRECTORDER);
			}

			if (objTTF?.Bulk_Deal__c == ISBULKDEAL) {
				if (map_skillTypeAdvocateIdSet.containsKey(BULKORDER)) {
					set_AdvocateIdsBasedOnSkill.addAll(map_skillTypeAdvocateIdSet.get(BULKORDER));
				}
			} else {
				if (map_skillTypeAdvocateIdSet.containsKey(DIRECTORDER)) {
					set_AdvocateIdsBasedOnSkill.addAll(map_skillTypeAdvocateIdSet.get(DIRECTORDER));
				}
			}
		}
		if (String.isNotBlank(strPartnerTierVal) && strPartnerTierVal == GOLDTIER) {
			if (map_skillTypeAdvocateIdSet.containsKey(GOLDTIER)) {
				set_GoldAdvocates = map_skillTypeAdvocateIdSet.get(GOLDTIER);
				for (Id IdUser : set_AdvocateIdsBasedOnSkill) {
					if (set_GoldAdvocates.contains(IdUser)) {
						set_AdvocateIdsToReturn.add(IdUser);
					}
				}
			}
			return set_AdvocateIdsToReturn;
		} else {
			return set_AdvocateIdsBasedOnSkill;
		}
	}

	/*Desc: This method receives "First Check Date", and return string containing Start Date and End Date
            for same week and same month of check date.
    */
	public string getWeekStartEndDateString(Date order_FirstCheckDate) {
		Date weekStartDate;
		Date weekEndDate;
		string returnStr;

		if (order_FirstCheckDate != null) {
			List<Date> lst_WeekStartEndDate = getWeekStartEndDate_MonthVise(order_FirstCheckDate);
			if (lst_WeekStartEndDate.size() > 1) {
				weekStartDate = lst_WeekStartEndDate.get(0);
				weekEndDate = lst_WeekStartEndDate.get(1);
				if (weekStartDate != null && weekEndDate != null) {
					returnStr = getDateString(weekStartDate, weekEndDate);
				}
			}
		}

		return returnStr;
	}

	//Desc: receive "Date" as parameter. Return Week Start date and End DAte in list for same week & same month
	public list<date> getWeekStartEndDate_MonthVise(date weekDate) {
		list<Date> lst_weekStartEndDateMonthVise = new List<Date>();
		Date weekStartDate;
		Date weekEndDate;

		weekStartDate = weekDate.toStartOfWeek().addDays(1); //to get the monday date
		weekEndDate = weekStartDate.addDays(4);

		while (weekStartDate.month() != weekDate.month()) {
			weekStartDate = weekStartDate.addDays(1);
		}

		while (weekDate.month() != weekEndDate.month()) {
			weekEndDate = weekEndDate.addDays(-1);
		}

		lst_weekStartEndDateMonthVise.add(weekStartDate);
		lst_weekStartEndDateMonthVise.add(weekEndDate);
		return lst_weekStartEndDateMonthVise;
	}

	//======================================================Utility Section Ends====================================

	/*================================================================================================================
    ==================================Facilitator=Assignment=Code=Below===============================================
    ================================================================================================================*/

	map<Id, String> map_BOAIdUniqueStates = new Map<Id, String>();
	//This method populates the BOA, ORder Count and Week Cap
	public void getFacilitatorBOADetails(set<Date> set_weekStartDate) {
		map_startEndDate2UserIdBOA = new Map<string, Map<Id, Benefit_Order_Allocation__c>>();
		map_startEndDate2UserIdWeekCap = new Map<string, Map<Id, Decimal>>();
		map_startEndDate2UserIdLastAssignedDateTime = new Map<string, Map<Id, Datetime>>();
		map_startEndDate2RecentlyBackInOfficeUserIdSet = new Map<string, Set<Id>>();
		map_BOAIdEmployeeCount = new Map<Id, Decimal>();
		map_BOAIdUniqueStates = new Map<Id, string>();

		string facilitatorRecordTypeId = OrderTriggerHelper.idFBOSForecast_RT_Facilitator;

		BusinessHours businessHourObj = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE][0];

		if (set_weekStartDate != null && set_weekStartDate.size() > 0) {
			for (Benefit_Order_Allocation__c boaObj : [
				SELECT
					Id,
					Week_End_Date__c,
					Week_Start_Date__c,
					Month__c,
					Year__c,
					Last_Order_Assigned_Date_Time__c,
					Payroll_Transfer_FBOS_Forecast__c,
					Inactive_Employee_Count__c,
					User__c,
					Unique_States__c,
					Week_Order_Capacity__c,
					Open_Order_Employee_Count__c,
					User_Role__r.User__c,
					Contractor_Count__c
				FROM Benefit_Order_Allocation__c
				WHERE
					Week_Start_Date__c IN :set_weekStartDate
					AND User_Role__r.User__r.Out_Of_Office__c = FALSE
					AND Payroll_Transfer_FBOS_Forecast__c != NULL
					AND Payroll_Transfer_FBOS_Forecast__r.RecordTypeId = :facilitatorRecordTypeId
			]) {
				string StartEndDateStr = getDateString(boaObj.Week_Start_Date__c, boaObj.Week_End_Date__c);
				decimal AICCount = boaObj.Open_Order_Employee_Count__c + boaObj.Inactive_Employee_Count__c + boaObj.Contractor_Count__c;

				//if(AICCount >= boaObj.Week_Order_Capacity__c){
				//  continue;
				//}

				Map<Id, Benefit_Order_Allocation__c> map_UserIdBOARec = new Map<Id, Benefit_Order_Allocation__c>();
				Map<Id, Decimal> map_UserIdWeekCap = new Map<Id, Decimal>();
				Map<Id, Datetime> map_UserIdLastAssignedDateTime = new Map<Id, Datetime>();

				//unique State Count
				map_BOAIdUniqueStates.put(boaObj.Id, boaObj.Unique_States__c);

				//Employee count map

				map_BOAIdEmployeeCount.put(boaObj.Id, AICCount);

				//user iD & BOA
				if (map_startEndDate2UserIdBOA.containsKey(StartEndDateStr)) {
					map_UserIdBOARec = map_startEndDate2UserIdBOA.get(StartEndDateStr);
				}
				map_UserIdBOARec.put(boaObj.User__c, boaObj);
				map_startEndDate2UserIdBOA.put(StartEndDateStr, map_UserIdBOARec);

				//User Id & Week Cap logic
				if (map_startEndDate2UserIdWeekCap.containsKey(StartEndDateStr)) {
					map_UserIdWeekCap = map_startEndDate2UserIdWeekCap.get(StartEndDateStr);
				}
				map_UserIdWeekCap.put(boaObj.User__c, boaObj.Week_Order_Capacity__c);
				map_startEndDate2UserIdWeekCap.put(StartEndDateStr, map_UserIdWeekCap);

				//User Id & last assignment date/time
				if (map_startEndDate2UserIdLastAssignedDateTime.containsKey(StartEndDateStr)) {
					map_UserIdLastAssignedDateTime = map_startEndDate2UserIdLastAssignedDateTime.get(StartEndDateStr);
				}
				map_UserIdLastAssignedDateTime.put(boaObj.User__c, boaObj.Last_Order_Assigned_Date_Time__c);
				map_startEndDate2UserIdLastAssignedDateTime.put(StartEndDateStr, map_UserIdLastAssignedDateTime);
			}
		}
	}
}