/**
Created by : Anshul Agrawal
Created Date : 7/11/2018
**/
public class TransitiontoFulfilmentTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;
	static final String TTF_RT_BENEFIT_NEW_PLAN = 'Benefits New Plan';
	static final String TTF_RT_BENEFIT_RENEWAL = 'Benefits Renewal';
	static final String TTF_RT_BENEFIT_CHANGE = 'Benefits Change';
	static final String TTF_RT_BENEFIT_BOR = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BoR');
	static final String TTF_RT_BENEFIT_BYB = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BYB');
	string parollTransferRecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');

	static final String TTS_RT_SUBMISSION_NEW_PLAN = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission New Plan');
	static final String TTS_RT_SUBMISSION_RENEWAL_CHANGE = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission Renewal/Change');
	public static final Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();

	public map<Id, Opportunity> opportunityMap;
	//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
	map<Id, Order> map_OrderMapForBulkUpdate = new Map<Id, Order>();
	static final String TEAM_INVITATION_PREFERENCE_ADMIN = 'admin';
	static final Set<String> set_AutoAssignOffProviders = new Set<String>{ 'QuickBooks Online', 'Intuit Online Payroll', 'ADP Run', 'Paychex' };

	//Getting Previous Payroll Provider Collect_Options based on Previous Payroll Provider
	public static Map<String, String> map_PreviousPayrollProviders = TransitiontoFulfilmentUtil.getPreviousPayrollProviders();

	public void OnBeforeInsert(List<Transition_to_Fulfillment__c> transitiontoFulfillment) {
		counter++;
		cacheData(transitiontoFulfillment);
		list<Transition_to_Fulfillment__c> payrollTransferRecList = new List<Transition_to_Fulfillment__c>();
		list<Transition_to_Fulfillment__c> lst_autoAssignPayrollTransferTTFForOrderAssignment = new List<Transition_to_Fulfillment__c>();

		for (Transition_to_Fulfillment__c rec : transitiontoFulfillment) {
			if (rec.Order__c == null && rec.Opportunity__c != null && rec.RecordTypeId == parollTransferRecordTypeId) {
				payrollTransferRecList.add(rec);
			}

			if (rec.Opportunity__c != null && opportunityMap.containsKey(rec.Opportunity__c)) {
				Opportunity opp = opportunityMap.get(rec.Opportunity__c);
				if (rec.Account__c == null) {
					rec.Account__c = opp.AccountId;
				}
				rec.Payroll_Start_Date__c = opp.Account.First_Payroll_Date__c;
			}

			if (rec.RecordTypeId == parollTransferRecordTypeId && rec.TTF_Status__c == 'Sales Submitted' && isPayrollTransferAutoAssignedOrder(rec)) {
				lst_autoAssignPayrollTransferTTFForOrderAssignment.add(rec);
			}
		}

		updateBenefitAndBoR(transitiontoFulfillment);
		if (payrollTransferRecList.size() > 0) {
			upateOrderOnTTF(payrollTransferRecList, true);
		}

		//Auto assign TTF logic
		if (lst_autoAssignPayrollTransferTTFForOrderAssignment.size() > 0) {
			autoAssignTTF(lst_autoAssignPayrollTransferTTFForOrderAssignment);
		}
		List<Transition_To_Fulfillment__c> lst_TTSRecords = new List<Transition_To_Fulfillment__c>();
		for (Transition_To_Fulfillment__c objTTS : (List<Transition_To_Fulfillment__c>) Trigger.new) {
			if (
				(objTTS.RecordTypeId == TTS_RT_SUBMISSION_NEW_PLAN || objTTS.RecordTypeId == TTS_RT_SUBMISSION_RENEWAL_CHANGE) &&
				(UserInfo.getName().equalsIgnoreCase('Workato Integration') || Test.isRunningTest())
			) {
				lst_TTSRecords.add(objTTS);
			}
		}

		if (!lst_TTSRecords.isEmpty()) {
			autoPopulateTTSFieldValues(lst_TTSRecords);
		}
	}

	public void OnAfterInsert(Map<Id, Transition_to_Fulfillment__c> newTransitiontoFulfillmentMap) {
		Map<Id, Transition_to_Fulfillment__c> newTTFforTTFCompleted = new Map<Id, Transition_to_Fulfillment__c>();
		Map<Id, string> map_ttfIdUpdatedStatus = new Map<Id, string>();
		Set<Id> set_ttfWithContractorPaid = new Set<Id>();

		if (newTransitiontoFulfillmentMap.keyset().size() > 0) {
			list<Transition_to_Fulfillment__c> payrollTransferRecList = new List<Transition_to_Fulfillment__c>();

			for (Transition_to_Fulfillment__c rec : newTransitiontoFulfillmentMap.values()) {
				if (rec.Opportunity__c != null && rec.RecordTypeId == parollTransferRecordTypeId) {
					payrollTransferRecList.add(rec);
				}

				if (rec.Send_Order__c && rec.RecordTypeId != TTF_RT_BENEFIT_BOR && rec.RecordTypeId != TTF_RT_BENEFIT_BYB) {
					newTTFforTTFCompleted.put(rec.Id, rec);
				}

				if (rec.RecordTypeId == parollTransferRecordTypeId && rec.TTF_Status__c != null && (rec.TTF_Status__c == 'Sales Submitted' || rec.TTF_Status__c == 'Sales Follow-up')) {
					map_ttfIdUpdatedStatus.put(rec.Id, rec.TTF_Status__c);
				}

				//By: PR, Date: Oct-22-2019, Desc: On change of [Contractors_paid_on_first_pay_date__c] we want to update the related order's "run date"
				if (rec.Contractors_paid_on_first_pay_date__c == 'Yes') {
					set_ttfWithContractorPaid.add(rec.Id);
				}
			}

			if (payrollTransferRecList.size() > 0) {
				upateOrderOnTTF(payrollTransferRecList, false);
			}
		}
		counter++;

		if (newTTFforTTFCompleted.size() > 0) {
			BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
			objBOCreationUtil.createBenefitOrder(null, null, newTTFforTTFCompleted, null);
		}

		if (map_ttfIdUpdatedStatus.keyset().size() > 0) {
			updateRelatedOrderStatus(map_ttfIdUpdatedStatus);
		}

		//By: PR, Date: Oct-22-2019, Desc: On change of [Contractors_paid_on_first_pay_date__c] we want to update the related order's "run date"
		if (set_ttfWithContractorPaid.size() > 0) {
			updateRelatedOrderRunDate(set_ttfWithContractorPaid);
		}

		//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
		updateRelatedOrder(); //this method should always be placed in the end
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedTransitiontoFulfillmentIDs) {
	}

	public void OnBeforeUpdate(Map<ID, Transition_to_Fulfillment__c> oldTransitiontoFulfillmentMap, Map<ID, Transition_to_Fulfillment__c> newTransitiontoFulfillmentMap) {
		counter++;

		list<Transition_to_Fulfillment__c> payrollTransferRecList = new List<Transition_to_Fulfillment__c>();
		map_OrderMapForBulkUpdate = new Map<Id, Order>();

		list<Transition_to_Fulfillment__c> lst_PayrollTransferTTFForOrderAssignment = new List<Transition_to_Fulfillment__c>();
		list<Transition_to_Fulfillment__c> lst_autoAssignPayrollTransferTTFForOrderAssignment = new List<Transition_to_Fulfillment__c>();

		for (Transition_to_Fulfillment__c rec : newTransitiontoFulfillmentMap.values()) {
			Transition_to_Fulfillment__c oldTTFRec = oldTransitiontoFulfillmentMap.get(rec.id);
			if (rec.RecordTypeId == parollTransferRecordTypeId && (rec.Order__c == null || (rec.Opportunity__c != null && oldTTFRec.Opportunity__c != rec.Opportunity__c))) {
				payrollTransferRecList.add(rec);
			}

			if (rec.RecordTypeId == parollTransferRecordTypeId) {
				if (rec.TTF_Status__c == 'Sales Submitted' && isPayrollTransferAutoAssignedOrder(rec)) {
					//auto assigned TTF logic
					lst_autoAssignPayrollTransferTTFForOrderAssignment.add(rec);
				} else if (rec.TTF_Status__c == 'PT Approved' && rec.TTF_Status__c != oldTTFRec.TTF_Status__c) {
					rec.PT_Approved_Date_Time__c = System.Now();
					lst_PayrollTransferTTFForOrderAssignment.add(rec); //TTF assignment logic
				}
			}
		}

		updateBenefitAndBoR(newTransitiontoFulfillmentMap.values());
		if (payrollTransferRecList.size() > 0) {
			upateOrderOnTTF(payrollTransferRecList, true);
		}

		//By:PR, Date:Sep 9,2019, Desc: code calling assignment logic
		if (lst_PayrollTransferTTFForOrderAssignment.size() > 0) {
			PayrollTransferAssignmentUtil controller = new PayrollTransferAssignmentUtil();
			controller.assignOrdersToAdvocates(lst_PayrollTransferTTFForOrderAssignment);
		}

		//Auto assign TTF logic
		if (lst_autoAssignPayrollTransferTTFForOrderAssignment.size() > 0) {
			autoAssignTTF(lst_autoAssignPayrollTransferTTFForOrderAssignment);
		}

		List<Transition_To_Fulfillment__c> lst_TTSRecords = new List<Transition_To_Fulfillment__c>();
		for (Transition_To_Fulfillment__c objTTS : (List<Transition_To_Fulfillment__c>) Trigger.new) {
			if (
				(objTTS.RecordTypeId == TTS_RT_SUBMISSION_NEW_PLAN || objTTS.RecordTypeId == TTS_RT_SUBMISSION_RENEWAL_CHANGE) &&
				(UserInfo.getName().equalsIgnoreCase('Workato Integration') || Test.isRunningTest())
			) {
				lst_TTSRecords.add(objTTS);
			}
		}

		if (!lst_TTSRecords.isEmpty()) {
			autoPopulateTTSFieldValues(lst_TTSRecords);
		}
	}

	public void OnAfterUpdate(Map<ID, Transition_to_Fulfillment__c> oldTransitiontoFulfillmentMap, Map<ID, Transition_to_Fulfillment__c> newTransitiontoFulfillmentMap) {
		counter++;
		Map<ID, Transition_to_Fulfillment__c> newTTFforTTFCompleted = new Map<ID, Transition_to_Fulfillment__c>();
		list<Transition_to_Fulfillment__c> ttfForUpdateOrderTypeList = new List<Transition_to_Fulfillment__c>();
		map<Id, string> map_ttfIdUpdatedStatus = new Map<Id, string>();
		set<Id> set_ttfWithContractorPaid = new Set<Id>();
		Map<Id, String> map_TTFForUpdateOrderStatus = new Map<Id, String>();
		Map<Id, Id> map_BOIdWithTTFIds = new Map<Id, Id>();

		for (Transition_to_Fulfillment__c newTtf : newTransitiontoFulfillmentMap.values()) {
			Transition_to_Fulfillment__c oldTTFObj = oldTransitiontoFulfillmentMap.get(newTtf.id);

			if (
				newTtf.Send_Order__c != oldTransitiontoFulfillmentMap.get(newTtf.Id).Send_Order__c &&
				newTtf.Send_Order__c &&
				newTtf.recordtypeId != TTF_RT_BENEFIT_BOR &&
				newTtf.RecordTypeId != TTF_RT_BENEFIT_BYB
			) {
				newTTFforTTFCompleted.put(newTtf.Id, newTtf);
			} else if (
				newTtf.Benefit_Order__c != null &&
				(newTtf.Medical_Plan_Change__c != oldTTFObj.Medical_Plan_Change__c ||
				newTtf.Medical_Contribution_Change__c != oldTTFObj.Medical_Contribution_Change__c ||
				newTtf.Medical_Waiting_Period_Change__c != oldTTFObj.Medical_Waiting_Period_Change__c)
			) {
				String strOrderType = TransitiontoFulfilmentUtil.checkOrderStatus(newTtf);
				map_TTFForUpdateOrderStatus.put(newTtf.Id, strOrderType);

				map_BOIdWithTTFIds.put(newTtf.Benefit_Order__c, newTtf.Id);
			}

			//BY: PR, Date: Oct,17,2019, Desc: on status update we are updating related orders status
			if (newTtf.TTF_Status__c != oldTTFObj.TTF_Status__c && (newTtf.TTF_Status__c == 'Sales Submitted' || newTtf.TTF_Status__c == 'Sales Follow-up')) {
				map_ttfIdUpdatedStatus.put(newTtf.Id, newTtf.TTF_Status__c);
			}

			//By: PR, Date: Oct-22-2019, Desc: On change of [Contractors_paid_on_first_pay_date__c] we want to update the related order's "run date"
			if (newTtf.Contractors_paid_on_first_pay_date__c != oldTTFObj.Contractors_paid_on_first_pay_date__c && newTtf.Contractors_paid_on_first_pay_date__c == 'Yes') {
				set_ttfWithContractorPaid.add(newTtf.Id);
			}
		}

		if (newTTFforTTFCompleted.size() > 0) {
			//InsertBenefitOrderCarrierOrderandCases(newTTFforTTFCompleted);
			BenefitOrderHelperFunctions objCreateBO = new BenefitOrderHelperFunctions();
			objCreateBO.createBenefitOrder(null, null, newTTFforTTFCompleted, null);
		}

		if (map_TTFForUpdateOrderStatus.size() > 0) {
			updateBOAndCOOrderStatus(map_TTFForUpdateOrderStatus, map_BOIdWithTTFIds);
		}

		if (map_ttfIdUpdatedStatus.keyset().size() > 0) {
			updateRelatedOrderStatus(map_ttfIdUpdatedStatus);
		}

		//By: PR, Date: Oct-22-2019, Desc: On change of [Contractors_paid_on_first_pay_date__c] we want to update the related order's "run date"
		if (set_ttfWithContractorPaid.size() > 0) {
			updateRelatedOrderRunDate(set_ttfWithContractorPaid);
		}

		//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
		updateRelatedOrder(); //this method should always be placed in the end
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedTransitiontoFulfillmentIDs) {
	}

	public void OnBeforeDelete(Transition_to_Fulfillment__c[] transitiontoFulfillmentToDelete, Map<ID, Transition_to_Fulfillment__c> oldTransitiontoFulfillmentMap) {
		counter++;
	}

	public void OnAfterDelete(Transition_to_Fulfillment__c[] deletedTransitiontoFulfillments, Map<ID, Transition_to_Fulfillment__c> oldTransitiontoFullfilmentMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedTransitiontoFulfillmentIDs) {
	}

	public void OnUndelete(Transition_to_Fulfillment__c[] restoredTransitiontoFulfillments) {
		counter++;
	}

	//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
	public void updateRelatedOrder() {
		if (map_OrderMapForBulkUpdate.size() > 0) {
			try {
				update map_OrderMapForBulkUpdate.values();
			} catch (exception ex) {
				ExceptionLogUtil.logException('TransitiontoFulfilmentTriggerHelper', 'updateRelatedOrder', ex.getMessage(), ex.getStackTraceString());
			}
		}
	}

	//By: PR, Date: Oct-22-2019, Desc: On change of [Contractors_paid_on_first_pay_date__c] we want to update the related order's "run date"
	public void updateRelatedOrderRunDate(set<Id> set_ttfIds) {
		if (set_ttfIds == null || set_ttfIds.size() == 0) {
			return;
		}

		map<Id, Order> map_orderIdRecord = new Map<Id, Order>(
			[
				SELECT Id, First_Check_Date__c, Fast_ACH__c, OpportunityId, Transition_to_Fulfillment__c, Payroll_Run_Date__c
				FROM Order
				WHERE Transition_to_Fulfillment__c IN :set_ttfIds AND First_Check_Date__c != NULL
			]
		);

		if (map_orderIdRecord.keyset().size() > 0) {
			OrderTriggerHelper controller = new OrderTriggerHelper();
			controller.updateRunDate(map_orderIdRecord.values());

			//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
			for (Order objOrder : map_orderIdRecord.values()) {
				Order objOrderTemp = new Order(Id = objOrder.Id);
				if (map_OrderMapForBulkUpdate.containsKey(objOrder.Id)) {
					objOrderTemp = map_OrderMapForBulkUpdate.get(objOrder.Id);
				}
				objOrderTemp.Payroll_Run_Date__c = objOrder.Payroll_Run_Date__c;
				//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
				map_OrderMapForBulkUpdate.put(objOrderTemp.Id, objOrderTemp);
			}
		}
	}

	/*By: PR, Date: Oct 17,2019, Description: On TTF Status update we are updating  related Orders status*/
	public void updateRelatedOrderStatus(map<Id, String> map_ttfIdStatus) {
		if (map_ttfIdStatus == null || map_ttfIdStatus.keyset().size() == 0) {
			return;
		}

		for (Order orderObj : [SELECT Id, Status, Transition_to_Fulfillment__c FROM Order WHERE Transition_to_Fulfillment__c IN :map_ttfIdStatus.keyset() AND Status NOT IN :Utils.setOrderExclude]) {
			if (map_ttfIdStatus.containsKey(orderObj.Transition_to_Fulfillment__c)) {
				string ttfStatusStr = map_ttfIdStatus.get(orderObj.Transition_to_Fulfillment__c);
				//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
				Order objOrderTemp = new Order(Id = orderObj.Id);
				if (ttfStatusStr == 'Sales Submitted' && orderObj.Status != 'Sales Submitted') {
					if (map_OrderMapForBulkUpdate.containsKey(orderObj.Id)) {
						objOrderTemp = map_OrderMapForBulkUpdate.get(orderObj.Id);
					}
					objOrderTemp.Status = 'Sales Submitted';
					map_OrderMapForBulkUpdate.put(objOrderTemp.Id, objOrderTemp);
				}

				if (ttfStatusStr == 'Sales Follow-up' && orderObj.Status != 'Sales Follow-up') {
					if (map_OrderMapForBulkUpdate.containsKey(orderObj.Id)) {
						objOrderTemp = map_OrderMapForBulkUpdate.get(orderObj.Id);
					}
					objOrderTemp.Status = 'Sales Follow-up';
					map_OrderMapForBulkUpdate.put(objOrderTemp.Id, objOrderTemp);
				}
			}
		}
	}

	/*By: PR, Date: Oct 3, 19, Description:  */
	public boolean isPayrollTransferAutoAssignedOrder(Transition_to_Fulfillment__c ttfObj) {
		if (ttfObj != null && String.isNotBlank(ttfObj.Previous_Payroll_Provider__c)) {
			String autoAssignedPayrollProvider = label.Payroll_Transfer_Auto_Assigned_Providers;
			string strPreviousPayrollProvider = ttfObj.Previous_Payroll_Provider__c;
			string strPreviousPayrollProviderCollectOption = ttfObj.Previous_Payroll_Provider_Collect_Option__c;
			String strTeamInvitationPreference = ttfObj.Team_Invitation_Preference__c;

			if (
				ttfObj.Order__c != null &&
				map_PreviousPayrollProviders != null &&
				String.isNotBlank(strPreviousPayrollProviderCollectOption) &&
				map_PreviousPayrollProviders.get(strPreviousPayrollProvider) != null &&
				map_PreviousPayrollProviders.get(strPreviousPayrollProvider).indexOf(strPreviousPayrollProviderCollectOption) > -1
			) {
				return false;
			}

			if (set_AutoAssignOffProviders.contains(strPreviousPayrollProvider) && strTeamInvitationPreference == TEAM_INVITATION_PREFERENCE_ADMIN) {
				return false;
			}

			if (
				string.isNotBlank(autoAssignedPayrollProvider) &&
				autoAssignedPayrollProvider.indexOf(ttfObj.Previous_Payroll_Provider__c) > -1 &&
				(ttfObj.Exception_Request__c == null ||
				ttfObj.Exception_Request__c == 'No') &&
				(ttfObj.Same_Login__c == null ||
				ttfObj.Same_Login__c == 'N') &&
				(ttfObj.Bulk_Deal__c == null ||
				ttfObj.Bulk_Deal__c == 'N') &&
				(ttfObj.Multi_EIN__c == null ||
				ttfObj.Multi_EIN__c == 'N')
			) {
				return true;
			}
		}

		return false;
	}

	//By: PR, Date:Sep-16-19, Desc: we are aggregating the employee & Contractor count to get the "auto assignment" eligible TTF records
	public List<Transition_to_Fulfillment__c> getEligibleAutoAssignPayrollTransferTTF(Transition_to_Fulfillment__c[] lst_ttfObj) {
		list<Transition_to_Fulfillment__c> lst_toAssignTTF = new List<Transition_to_Fulfillment__c>();

		if (lst_ttfObj.size() > 0) {
			map<Id, Transition_to_Fulfillment__c> map_ttfOpportunityIdObj = new Map<Id, Transition_to_Fulfillment__c>();
			for (Transition_to_Fulfillment__c rec : lst_ttfObj) {
				map_ttfOpportunityIdObj.put(rec.Opportunity__c, rec);
			}

			for (AggregateResult result : [
				SELECT OpportunityId, SUM(Active_Employee_Count__c) eeSum, SUM(Contractor_Count__c) contractorSum, SUM(Inactive_Employee_Count__c) inActiveEESum
				FROM Order
				WHERE Order.Status != 'Closed: Payroll Run' AND Order.Status != 'Closed: Canceled' AND OpportunityId IN :map_ttfOpportunityIdObj.keyset()
				GROUP BY OpportunityID
			]) {
				Decimal decSumOfEE;
				Decimal decSumOfContractor;
				Decimal decSumOfInActive;

				if (result.get('eeSum') == null) {
					decSumOfEE = 0;
				} else {
					decSumOfEE = (Decimal) result.get('eeSum');
				}

				if (result.get('contractorSum') == null) {
					decSumOfContractor = 0;
				} else {
					decSumOfContractor = (Decimal) result.get('contractorSum');
				}

				if (result.get('inActiveEESum') == null) {
					decSumOfInActive = 0;
				} else {
					decSumOfInActive = (Decimal) result.get('inActiveEESum');
				}

				if ((decSumOfEE + decSumOfContractor + decSumOfInActive) < 100) {
					Id oppId = (Id) result.get('OpportunityId');
					lst_toAssignTTF.add(map_ttfOpportunityIdObj.get(oppId));
				}
			}
		}

		return lst_toAssignTTF;
	}

	private void updateBenefitAndBoR(List<Transition_to_Fulfillment__c> transitiontoFulfillmentList) {
		Set<Id> opportunityIdSet = new Set<Id>();
		for (Transition_to_Fulfillment__c transitionToFulFillmentRec : transitiontoFulfillmentList) {
			if (transitionToFulFillmentRec.Opportunity__c != null && transitionToFulFillmentRec.Benefit_Order__c == null) {
				opportunityIdSet.add(transitionToFulFillmentRec.Opportunity__c);
			}
		}
		if (opportunityIdSet.size() > 0) {
			Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
				[SELECT RecordTypeId, (SELECT Id, Name FROM Benefit_Orders__r WHERE RecordType.Name != 'Renewal Alignment') FROM Opportunity WHERE id IN :opportunityIdSet]
			);

			for (Transition_to_Fulfillment__c transitionToFulFillmentRec : transitiontoFulfillmentList) {
				if (transitionToFulFillmentRec.Opportunity__c != null && oppMap.containskey(transitionToFulFillmentRec.Opportunity__c)) {
					String recordTypeName = cache.getRecordTypeName('Opportunity', oppMap.get(transitionToFulFillmentRec.Opportunity__c).RecordTypeId);
					if (
						recordTypeName.equalsIgnoreCase('Benefits Change') ||
						recordTypeName.equalsIgnoreCase('Benefits New Plan') ||
						recordTypeName.equalsIgnoreCase('Benefits Renewal') ||
						recordTypeName.equalsIgnoreCase('Benefits BoR') ||
						recordTypeName.equalsIgnoreCase('Benefits BYOB')
					) {
						List<Benefit_Order__c> benefitOrderList = oppMap.get(transitionToFulFillmentRec.Opportunity__c).Benefit_Orders__r;
						if (benefitOrderList != null && benefitOrderList.size() > 0) {
							transitionToFulFillmentRec.Benefit_Order__c = benefitOrderList[0].id;
						}
					}
				}
			}
		}
	}

	/*BY: PR, 12/17/2018
       Desc: This method is called from beforeInsert and beforeUpdate event
            This methods populates the order field on Transition to Fulfillement recod of recordtype Payroll Transfer.
            Based on matching opportunity record. 
     */
	public void upateOrderOnTTF(List<Transition_to_Fulfillment__c> transitiontoFulfillmentList, Boolean updateTTF) {
		Set<Id> opportunityIdSet = new Set<Id>();
		List<Order> ordersToUpdate = new List<Order>();
		for (Transition_to_Fulfillment__c transitionToFulFillmentRec : transitiontoFulfillmentList) {
			if (transitionToFulFillmentRec.Opportunity__c != null) {
				opportunityIdSet.add(transitionToFulFillmentRec.Opportunity__c);
			}
		}

		if (opportunityIdSet.size() > 0) {
			Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT id, RecordTypeId, (SELECT id FROM Orders ORDER BY CreatedDate DESC) FROM Opportunity WHERE id IN :opportunityIdSet]);

			String companyOpportunityRecordTypeId = cache.getRecordTypeId('Opportunity', 'Company Opportunity');
			String strAcquisitionOpptyRecordTypeId = cache.getRecordTypeId('Opportunity', 'Acquisition');
			for (Transition_to_Fulfillment__c transitionToFulFillmentRec : transitiontoFulfillmentList) {
				if (
					oppMap.keyset().size() > 0 &&
					transitionToFulFillmentRec.Opportunity__c != null &&
					oppMap.containsKey(transitionToFulFillmentRec.Opportunity__c) &&
					(oppMap.get(transitionToFulFillmentRec.Opportunity__c).RecordTypeId.equals(companyOpportunityRecordTypeId) ||
					oppMap.get(transitionToFulFillmentRec.Opportunity__c).RecordTypeId.equals(strAcquisitionOpptyRecordTypeId)) &&
					oppMap.get(transitionToFulFillmentRec.Opportunity__c).Orders.size() > 0
				) {
					if (updateTTF) {
						transitionToFulFillmentRec.Order__c = oppMap.get(transitionToFulFillmentRec.Opportunity__c).Orders.get(0).id;
					}

					if (transitionToFulFillmentRec.Order__c != null && !updateTTF) {
						//BY:PR, Date: July/3/2020, Desc: to Resolve 101 SOQL issue https://app.asana.com/0/1181416203938674/1182686956599057/f
						Order objOrderTemp = new Order(Id = oppMap.get(transitionToFulFillmentRec.Opportunity__c).Orders.get(0).id, Transition_to_Fulfillment__c = transitionToFulFillmentRec.Id);
						map_OrderMapForBulkUpdate.put(objOrderTemp.Id, objOrderTemp);
					}
				}
			}
		}
	}

	//Calculate BusinessHours for SLA qual hours on Opportunity for New Plan, Renewal and Change
	public static decimal calculateBusinessHoursOpp(List<BusinessHours> listBusinessHours, Opportunity opp) {
		if (listBusinessHours != null && listBusinessHours.size() > 0 && opp.ER_Confirm_TimeStamp__c != null && opp.Send_Order_TimeStamp__c != null) {
			return (decimal) BusinessHours.diff(listBusinessHours[0].id, opp.ER_Confirm_TimeStamp__c, opp.Send_Order_TimeStamp__c) / 1000 / 60 / 60;
		}

		return null;
	}

	public void cacheData(List<Transition_to_Fulfillment__c> transitiontoFulfillmentList) {
		opportunityMap = new Map<Id, Opportunity>();
		Set<id> oppIdSet = new Set<id>();
		for (Transition_to_Fulfillment__c ttf : transitiontoFulfillmentList) {
			if (ttf.Opportunity__c != null) {
				oppIdSet.add(ttf.Opportunity__c);
			}
		}
		if (oppIdSet.size() > 0) {
			opportunityMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.First_Payroll_Date__c FROM Opportunity WHERE id IN :oppIdSet]);
		}
	}

	//BY:DS, Desc: Move the commen code the the below method
	private void autoAssignTTF(List<Transition_to_Fulfillment__c> lst_autoAssignPayrollTransferTTFForOrderAssignment) {
		// auto approve TTF only if Disable_Auto_Approve_TTF__c is set to False
		if (objConfig != null && objConfig.Disable_Auto_Approve_TTF__c == false) {
			list<Transition_to_Fulfillment__c> lst_autoAssignEligibleTTFObj = getEligibleAutoAssignPayrollTransferTTF(lst_autoAssignPayrollTransferTTFForOrderAssignment);

			if (lst_autoAssignEligibleTTFObj != null && lst_autoAssignEligibleTTFObj.size() > 0) {
				for (Transition_to_Fulfillment__c ttfRec : lst_autoAssignEligibleTTFObj) {
					ttfRec.TTF_Status__c = 'PT Approved';
					ttfRec.Auto_Approved__c = true;
					ttfRec.PT_Approved_Date_Time__c = System.Now();
				}

				PayrollTransferAssignmentUtil controller = new PayrollTransferAssignmentUtil();
				controller.assignOrdersToAdvocates(lst_autoAssignEligibleTTFObj);
			}
		}
	}
	/*
	* @author:         Anurag Gautam
	* @description:    Auto Populate Field values from TTS event by using Custom metadata TTS_Template_Fields_Setting__mdt
					   This method is written on before insert event. 
	* @parm:           NA
	* @return:         NA
	*/
	public static void autoPopulateTTSFieldValues(List<Transition_To_Fulfillment__c> lst_TTSRecords) {
		HIGroupEventTTSNotePostOEEmailJSON objHIGroupEventTTSNotePostOEEmailJSON = new HIGroupEventTTSNotePostOEEmailJSON();
		HIQaSheetWrapper objHIQaSheetWrapper = new HIQaSheetWrapper();
		Map<String, Schema.SObjectField> map_TTFFields = Schema.SObjectType.Transition_to_Fulfillment__c.fields.getMap();
		Set<String> set_BOIds = new Set<String>();
		Map<String, String> map_BOIdAndCompanyId = new Map<String, String>();
		Map<String, String> map_BOIdAndApplicationId = new Map<String, String>();
		Set<String> set_ApplicationId = new Set<String>();
		Set<String> set_CompanyId = new Set<String>();
		Map<String, String> map_FieldAPINameAndSourceObject = new Map<String, String>();
		Map<String, String> map_FieldAPINameAndSourceAttribute = new Map<String, String>();
		Map<String, List<Transition_To_Fulfillment__c>> map_BOIdAndTTFList = new Map<String, List<Transition_To_Fulfillment__c>>();
		Set<String> set_OpptyIds = new Set<String>();
		Set<String> set_TTFRecordTypeIds = new Set<String>{
			TransitiontoFulfilmentUtil.strTTFBenChangeRecTypeId,
			TransitiontoFulfilmentUtil.strTTFBenNewPlanRecTypeId,
			TransitiontoFulfilmentUtil.strBenRenewalRecTypeId
		};

		for (Transition_To_Fulfillment__c objTTS : lst_TTSRecords) {
			if (objTTS.Benefit_Order__c != null) {
				set_BOIds.add(objTTS.Benefit_Order__c);
			}
		}

		for (Benefit_Order__c objBO : [SELECT Id, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.Account.ZP_Company_ID__c, Application_Id__c FROM Benefit_Order__c WHERE ID IN :set_BOIds]) {
			if (String.isNotBLank(objBO.Application_Id__c)) {
				set_ApplicationId.add(objBO.Application_Id__c);
				map_BOIdAndApplicationId.put(objBO.ID, objBO.Application_Id__c);
			}

			if (objBO.Opportunity__c != null && objBO.Opportunity__r.AccountId != null && String.isNotBLank(objBO.Opportunity__r.Account.ZP_Company_ID__c)) {
				map_BOIdAndCompanyId.put(objBO.ID, objBO.Opportunity__r.Account.ZP_Company_ID__c);
				set_CompanyId.add(objBO.Opportunity__r.Account.ZP_Company_ID__c);
			}

			if (objBO.Opportunity__c != null) {
				set_OpptyIds.add(objBO.Opportunity__c);
			}
		}

		for (TTS_Template_Fields_Setting__mdt objTTSTemplateFieldsSetting : TTS_Template_Fields_Setting__mdt.getAll().values()) {
			if (
				String.isNotBLank(objTTSTemplateFieldsSetting.Source__c) &&
				objTTSTemplateFieldsSetting.Source__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.AUTOPOPULATE) &&
				String.isNotBLank(objTTSTemplateFieldsSetting.Field_API_Name__c) &&
				String.isNotBLank(objTTSTemplateFieldsSetting.Object_API_Name__c) &&
				objTTSTemplateFieldsSetting.Object_API_Name__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.TTS_OBJECT_NAME)
			) {
				if (String.isNotBLank(objTTSTemplateFieldsSetting.Source_Object__c) && String.isNotBLank(objTTSTemplateFieldsSetting.Source_Attribute__c)) {
					map_FieldAPINameAndSourceObject.put(objTTSTemplateFieldsSetting.Field_API_Name__c, objTTSTemplateFieldsSetting.Source_Object__c);
					map_FieldAPINameAndSourceAttribute.put(objTTSTemplateFieldsSetting.Field_API_Name__c, objTTSTemplateFieldsSetting.Source_Attribute__c);
				}
			}
		}

		List<Transition_to_Fulfillment__c> lstTTQrec = new List<Transition_to_Fulfillment__c>();
		if (!set_BOIds.isEmpty()) {
			String strTTFQsoql =
				'SELECT ' +
				String.join(TransitiontoFulfilmentUtil.list_TTFFields, ',') +
				', Account__r.Anchor_Pay_Date__c, Account__r.ParentId FROM Transition_to_Fulfillment__c ' +
				' WHERE ( Opportunity__c IN :set_OpptyIds OR Benefit_Order__c IN :set_BOIds ) AND RecordTypeId IN :set_TTFRecordTypeIds';

			for (Transition_to_Fulfillment__c objTTF : Database.query(strTTFQsoql)) {
				if (objTTF.Benefit_Order__c != null) {
					List<Transition_to_Fulfillment__c> lst_tempTTFs = map_BOIdAndTTFList.get(objTTF.Benefit_Order__c);
					if (lst_tempTTFs == null) {
						lst_tempTTFs = new List<Transition_to_Fulfillment__c>();
					}
					lst_tempTTFs.add(objTTF);
					map_BOIdAndTTFList.put(objTTF.Benefit_Order__c, lst_tempTTFs);
				}
			}
		}

		if (map_BOIdAndTTFList.isEmpty()) {
			return;
		}

		for (Transition_To_Fulfillment__c objTTSRecord : lst_TTSRecords) {
			if (objTTSRecord.Benefit_Order__c != null) {
				for (String strFieldAPIName : map_FieldAPINameAndSourceObject.keySet()) {
					String strAppIdAndCompanyId = map_BOIdAndApplicationId.get(objTTSRecord.Benefit_Order__c) + ';' + map_BOIdAndCompanyId.get(objTTSRecord.Benefit_Order__c);
					String attributeValue;
					if (map_FieldAPINameAndSourceObject.get(strFieldAPIName) == TransitiontoFulfilmentUtil.TTS_OBJECT_NAME) {
						if (map_BOIdAndTTFList.containsKey(objTTSRecord.Benefit_Order__c) && !map_BOIdAndTTFList.get(objTTSRecord.Benefit_Order__c).isEmpty()) {
							objTTSRecord.put(strFieldAPIName, map_BOIdAndTTFList.get(objTTSRecord.Benefit_Order__c)[0].get(strFieldAPIName));
						}
					}
				}
			}
		}
	}

	/*
	 * @author:         Bhagat Singh
	 * @description:    Update BO & CO Order Status.
	 * @parm:           NA
	 * @return:         NA
	 */
	public static void updateBOAndCOOrderStatus(Map<Id, String> map_TTFForUpdateOrderStatus, Map<Id, Id> map_BOIdWithTTFIds) {
		Set<Id> set_BOIds = map_BOIdWithTTFIds.keySet();
		Map<Id, Benefit_Order__c> map_BOs = new Map<Id, Benefit_Order__c>();
		List<Carrier_Order__c> list_COs = new List<Carrier_Order__c>();
		String strOrderStage = '';
		Id idTTF = null;

		for (Carrier_Order__c objCO : [SELECT Id, Order_Type__c, Benefit_Order__c FROM Carrier_Order__c WHERE Benefit_Order__c != NULL AND Benefit_Order__c IN :set_BOIds]) {
			if (map_BOIdWithTTFIds.containsKey(objCO.Benefit_Order__c)) {
				idTTF = map_BOIdWithTTFIds.get(objCO.Benefit_Order__c);

				if (map_TTFForUpdateOrderStatus.containsKey(idTTF)) {
					strOrderStage = map_TTFForUpdateOrderStatus.get(idTTF);
					objCO.Order_Type__c = strOrderStage;
					list_COs.add(objCO);

					if (!map_BOs.containsKey(objCO.Benefit_Order__c)) {
						map_BOs.put(objCO.Benefit_Order__c, new Benefit_Order__c(Id = objCO.Benefit_Order__c, Type__c = strOrderStage));
					}
				}
			}
		}

		for (Id idBo : set_BOIds) {
			if (map_BOIdWithTTFIds.containsKey(idBo)) {
				idTTF = map_BOIdWithTTFIds.get(idBo);
				if (map_TTFForUpdateOrderStatus.containsKey(idTTF) && !map_BOs.containsKey(idBo)) {
					strOrderStage = map_TTFForUpdateOrderStatus.get(idTTF);
					map_BOs.put(idBo, new Benefit_Order__c(Id = idBo, Type__c = strOrderStage));
				}
			}
		}

		if (map_BOs.size() > 0) {
			List<Database.SaveResult> list_SaveResults = Database.update(map_BOs.values(), false);
			Map<String, String> map_InsuranceQuotesErrors = Utils.processSaveRecords(list_SaveResults, map_BOs.values(), 'Id', true, 'TransitiontoFulfilmentTriggerHelper', 'updateBOAndCOOrderStatus');
		}

		if (list_COs.size() > 0) {
			List<Database.SaveResult> list_SaveResults = Database.update(list_COs, false);
			Map<String, String> map_InsuranceQuotesErrors = Utils.processSaveRecords(list_SaveResults, list_COs, 'Id', true, 'TransitiontoFulfilmentTriggerHelper', 'updateBOAndCOOrderStatus');
		}
	}
}