/**
 * @name         BenefitOrderHelperFunctions
 * @author       Sourav Mitra
 * @date         05/31/2019
 * @description
 * @test class   BenefitOrderHelperFunctionTest,CarrierOrderTriggerHelperTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class BenefitOrderHelperFunctions {
	public static boolean blnIsPlayModeAssigned = false;
	public static Map<Id, Carrier_Order__c> map_CarrierOrder;
	public static final String strYes = 'Y';
	public static final String QUEUE_RENEWAL_BENEFITS_OPERATIONS = 'Renewal Benefits Operations';
	public static final String QUEUE_NEW_PLAN_BENEFITS_OPERATIONS = 'New Plan Benefits Operations';
	public static final String QUEUE_CHANGE_BENEFITS_OPERATIONS = 'Change Benefit Operations';
	public static final String QUEUE_RENEWAL_ALIGNMENT = 'Renewal Alignment Queue';
	public static final String QUEUE_BENEFIT_BYOB = 'Benefits BYOB';
	public final static Id BENEFIT_NEW_PLAN_TTF_RT = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Benefits New Plan');
	public final static Id BENEFIT_RENEWAL_TTF_RT = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Benefits Renewal');
	public final static Id BENEFIT_CHANGE_TTF_RT = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Benefits Change');
	public final static Id BENEFIT_BYB_TTF_RT = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Benefits BYB');

	static final String BENEFIT_ORDER_NEW_PLAN_RT_NAME = 'New Plan';
	static final String BENEFIT_ORDER_RENEWAL_RT_NAME = 'Renewal';
	static final String BENEFIT_ORDER_CHANGE_RT_NAME = 'Change';
	static final String BENEFIT_ORDER_BOR_RT_NAME = 'Benefits BoR';
	static final String BENEFIT_ORDER_BYB_RT_NAME = 'Benefits BYB';
	static final String BENEFIT_ORDER_RENEWAL_ALIGN_RT_NAME = 'Renewal Alignment';

	static final String TTF_NEW_PLAN_RT_NAME = 'Benefits New Plan';
	static final String TTF_RENEWAL_RT_NAME = 'Benefits Renewal';
	static final String TTF_CHANGE_RT_NAME = 'Benefits Change';
	static final String TTF_BYB_RT_NAME = 'Benefits BYB';

	static final String OPP_CLOSED_LOST = 'Closed Lost';

	static final Id BENEFIT_ORDER_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	static final Id BENEFIT_ORDER_RT_RENEWAL = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
	static final Id BENEFIT_ORDER_RT_CHANGE = Cache.getRecordTypeId('Benefit_Order__c', 'Change');
	static final Id BENEFIT_ORDER_BOR_RT = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
	static final Id BENEFIT_ORDER_BYB_RT = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB');
	static final Id BENEFIT_ORDER_RT_RENEWAL_ALIGNMENT = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal Alignment');

	public static final Set<String> set_BenefitsQueueNames = new Set<String>{
		QUEUE_RENEWAL_BENEFITS_OPERATIONS,
		QUEUE_NEW_PLAN_BENEFITS_OPERATIONS,
		QUEUE_CHANGE_BENEFITS_OPERATIONS,
		QUEUE_RENEWAL_ALIGNMENT,
		QUEUE_BENEFIT_BYOB
	};
	public static Map<String, Id> map_BenefitsQueue = GlobalQueryHelper.getNameQueueMap(set_BenefitsQueueNames);
	public static List<BusinessHours> list_BusinessHours = new List<BusinessHours>{ GlobalQueryHelper.getDefaultBusinessHour() };
	map<string, integer> map_MultiEINParentAccountNONClosedWonOppCount = new Map<string, integer>();
	map<string, map<Id, Opportunity>> map_MultiEINParentAccountIdListOfOpp = new Map<string, Map<Id, Opportunity>>();
	list<Opportunity> list_toProcessMultiEINOpportunityRecords = new List<Opportunity>();

	public static Boolean blnIsBYBRenewalOpp = false;
	public Date dateBOR;
	public String strBenefitOrderType;

	public BenefitOrderHelperFunctions() {
	}

	public static Map<Id, Account> getAccountsByAccountId(Set<Id> set_AccountIds) {
		Map<Id, Account> map_Accounts = new Map<Id, Account>();
		for (Account objAccount : [
			SELECT
				Id,
				Name,
				Corporation_Type__c,
				ShippingAddress,
				Sic,
				Number_of_Active_Employees__c,
				BillingCountry,
				BillingPostalCode,
				BillingState,
				BillingCity,
				BillingStreet,
				Tier__c,
				ParentId,
				Parent.Name,
				Parent.Number_of_Active_Employees__c,
				FEIN__c,
				Big_Desk_Sandbox_BenOps__c,
				Priority_Support__c
			FROM Account
			WHERE ID IN :set_AccountIds
		]) {
			map_Accounts.put(objAccount.Id, objAccount);
		}

		return map_Accounts;
	}

	public static Map<Id, Carrier_Order__c> getCarrierOrderMap(Set<Id> set_BenefitOrderIds) {
		//if(map_CarrierOrder == null){Commented By: PR, Date: April/10/2020, Desc: filter has logic flow as it does not cross check present data against the requested BO ids
		map_CarrierOrder = new Map<Id, Carrier_Order__c>(
			[
				SELECT
					id,
					Benefit_Order__c,
					Benefit_Order__r.RecordTypeId,
					Additional_Details__c,
					Implementation_Stage__c,
					Stage_Detail__c,
					RecordTypeId,
					Open_Enrollment_Start_Date__c,
					Start_Date__c,
					Open_Enrollment_End_Date__c,
					Carrier__r.BT_Facilitator_POD__c,
					Total_Number_Of_Documents__c,
					Number_Of_Collected_Documents__c,
					OwnerId,
					OOO_Timestamp__c,
					Initial_Owner__c,
					Is_Multi_EIN__c,
					Parent_Carrier_Order__c,
					Submitted_Completed_Datetime__c,
					Carrier__r.Partner_Type__c,
					Effective_Date_Change__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c IN :set_BenefitOrderIds
			]
		);
		//}
		return map_CarrierOrder;
	}

	public static map<Id, Opportunity> getOppsByOppId(Set<Id> opportunityIdSet) {
		map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
		opportunityMap = new Map<Id, Opportunity>(
			[
				SELECT
					id,
					Name,
					ownerid,
					Notes__c,
					StageName,
					Order_Lost_Date__c,
					Stage_Detail__c,
					Source_ID__c,
					HI_Effective_Date__c,
					Waiting_Period__c,
					AccountId,
					Account.Name,
					Account.Joined_Date_Panda__c,
					Account.EE_Active_Count_Panda__c,
					Type,
					UW_state__c,
					CloseDate,
					Id_And_Source_Id__c,
					Id__c,
					Big_Desk_BenOps__c,
					X1_3_ee_Pilot__c,
					Owner_Role_Name__c,
					Maestro__c,
					(SELECT Id, Type_of_TADA_s__c, Adding_TADA__c, Renewing_TAdA_s__c, Types_of_Renewing_TAdAs__c FROM NP_Complexity_Scorings__r),
					(SELECT Id, New_TAdAs__c, Renewing_TAdAs__c FROM QA_Sheet__r)
				FROM Opportunity
				WHERE Id IN :opportunityIdSet
			]
		);
		return opportunityMap;
	}

	public static map<String, Id> getQueuesByName() {
		map<String, Id> queueMap = new Map<String, Id>();
		for (Group groupRec : [
			SELECT Id, Name
			FROM Group
			WHERE Type = 'Queue' AND NAME IN (:QUEUE_RENEWAL_BENEFITS_OPERATIONS, :QUEUE_NEW_PLAN_BENEFITS_OPERATIONS, :QUEUE_CHANGE_BENEFITS_OPERATIONS)
		]) {
			queueMap.put(groupRec.Name, groupRec.Id);
		}
		return queueMap;
	}

	//>>>>>>>>>>>>>>>>>>>>>>>Benefit Order creation logic of "Benefits BOR, Benefit Renewal Alignment, Benefit New plan, Benefit Change, Benefit Renewal" type  ==============START=================
	public void createBenefitOrder(List<Opportunity> lst_NewOpp, Map<id, Opportunity> map_OldOpp, Map<ID, Transition_to_Fulfillment__c> map_NewTTF, map<Id, Benefit_Order__c> benefitOrderMap) {
		List<Benefit_Order__c> lst_BenefitOrderToInsert = new List<Benefit_Order__c>();
		List<Benefit_Order__c> lst_BenefitOrderToUpsert = new List<Benefit_Order__c>();
		List<Opportunity> lst_UpdateOpp = new List<Opportunity>();
		set<Id> set_AccountIds = new Set<Id>();
		set<Id> set_OpportunityIds = new Set<Id>();
		Map<Id, Account> map_Account = new Map<Id, Account>();
		Map<ID, ID> map_OppAndTTFIds = new Map<ID, ID>();
		set<string> set_MultiEinTtfIds = new Set<string>();
		//stores multi-ein opp triggering this event
		map<string, Opportunity> map_TriggeringMultiEINOppIdRecord = new Map<string, Opportunity>();
		Set<String> set_BYBRenewalTouchTypes = new Set<String>{ 'HI BAT Creation', 'HI EBBP Creation' };

		//Benefit Order creation logic of "Benefits BOR, Benefit Renewal Alignment
		if (null != lst_NewOpp && !lst_NewOpp.isEmpty()) {
			for (Opportunity objOpp : lst_NewOpp) {
				// Get the Account id of BOR Opportunity record
				if (
					(objOpp.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID || (objOpp.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID && objOpp.Type == 'Transfer TAdA Plan')) &&
					!objOpp.Order_Generated__c
				) {
					set_AccountIds.add(objOpp.AccountId);
					set_OpportunityIds.add(objOpp.Id);
				} else if (map_OldOpp == null && objOpp.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID && objOpp.Async_Renewal__c) {
					// Get the Account id of Renewal Opportunity record
					set_AccountIds.add(objOpp.AccountId);
				} else if (
					objOpp.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID &&
					objOpp.StageName == OpportunityUtil.ER_CONFIRM_STAGE &&
					(objOpp.Touch_Type__c != null && set_BYBRenewalTouchTypes.contains(objOpp.Touch_Type__c)) &&
					!objOpp.Order_Generated__c
				) {
					// Get the Account id of BYOB Renewal Opportunity record
					set_AccountIds.add(objOpp.AccountId);
					set_OpportunityIds.add(objOpp.Id);
					blnIsBYBRenewalOpp = true;
				}
			}

			//[DS]24-03-2020 get Transition for Fulfilment for BOr Creation
			if (map_OldOpp != null && !set_OpportunityIds.isEmpty()) {
				for (Transition_to_Fulfillment__c objTTf : [SELECT Id, Opportunity__c, Multi_EIN__c FROM Transition_to_Fulfillment__c WHERE Opportunity__c IN :set_OpportunityIds]) {
					map_OppAndTTFIds.put(objTTf.Opportunity__c, objTTf.Id);
					if (objTTf.Multi_EIN__c != null && objTTf.Multi_EIN__c == 'Y') {
						set_MultiEinTtfIds.add(objTTf.Id);
					}
				}
			}

			if (set_AccountIds != null && set_AccountIds.size() > 0) {
				List<Account> lst_Accounts = queryAccounts(set_AccountIds);
				getMultiEinRecordsDetails(set_AccountIds);
				if (lst_Accounts.size() > 0) {
					map_Account = new Map<Id, Account>(lst_Accounts);
				}

				for (Opportunity objOpp : lst_NewOpp) {
					Opportunity objOldOppRec = new Opportunity();
					if (map_Account.containsKey(objOpp.AccountId)) {
						if (map_OldOpp != null && map_OldOpp.containsKey(objOpp.Id)) {
							objOldOppRec = map_OldOpp.get(objOpp.id);
						}
						Benefit_Order__c objBenefitOrder = new Benefit_Order__c();
						//Benefit Order creation logic of "Benefit Renewal Alignment"
						if (map_OldOpp == null && objOpp.Async_Renewal__c && objOpp.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
							setBenefitOrderFields(BENEFIT_ORDER_RENEWAL_ALIGN_RT_NAME, objBenefitOrder, objOpp, map_Account, map_BenefitsQueue, BENEFIT_ORDER_RT_RENEWAL_ALIGNMENT);
							lst_BenefitOrderToInsert.add(objBenefitOrder);
						} else if (
							objOpp.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID &&
							objOpp.StageName == OpportunityUtil.ER_CONFIRM_STAGE &&
							(objOpp.Touch_Type__c != null && set_BYBRenewalTouchTypes.contains(objOpp.Touch_Type__c))
						) {
							setBenefitOrderFields(BENEFIT_ORDER_BYB_RT_NAME, objBenefitOrder, objOpp, map_Account, map_BenefitsQueue, BENEFIT_ORDER_BYB_RT);
							lst_BenefitOrderToInsert.add(objBenefitOrder);
						} else if (
							(objOpp.IsWon || objOpp.StageName == 'Closed Won') &&
							(objOpp.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID ||
							(objOpp.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID &&
							objOpp.Type == 'Transfer TAdA Plan')) &&
							!objOpp.Order_Generated__c
						) {
							//Benefit Order creation logic of "Benefits BOR"
							//Filter removed by PR: objOpp.IsWon != objOldOppRec.IsWon &&
							if (!map_OppAndTTFIds.isEmpty() && map_OppAndTTFIds.containsKey(objOpp.Id)) {
								objBenefitOrder.Transition_to_Fulfillment__c = map_OppAndTTFIds.get(objOpp.Id);
							}

							// if opp is "Benefit BOR" + has TTF Record + TTF record is of type Multi EIN
							if (
								objOpp.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID &&
								objBenefitOrder.Transition_to_Fulfillment__c != null &&
								set_MultiEinTtfIds.contains(objBenefitOrder.Transition_to_Fulfillment__c)
							) {
								//If Child Account + have non "CLosed WON" opp Rec [OR] Parent Record + has non "Closed Won" rec
								if (
									(map_Account.get(objOpp.AccountId).ParentId != null &&
									map_MultiEINParentAccountNONClosedWonOppCount.containsKey(map_Account.get(objOpp.AccountId).ParentId) &&
									map_MultiEINParentAccountNONClosedWonOppCount.get(map_Account.get(objOpp.AccountId).ParentId) > 0) ||
									(map_Account.get(objOpp.AccountId).ParentId == null &&
									map_MultiEINParentAccountNONClosedWonOppCount.containsKey(objOpp.AccountId) &&
									map_MultiEINParentAccountNONClosedWonOppCount.get(objOpp.AccountId) > 0)
								) {
									continue;
								} else {
									map<Id, Opportunity> map_OppIdRec = new Map<Id, Opportunity>();
									if (map_Account.get(objOpp.AccountId).ParentId != null && map_MultiEINParentAccountIdListOfOpp.containsKey(map_Account.get(objOpp.AccountId).ParentId)) {
										map_OppIdRec = map_MultiEINParentAccountIdListOfOpp.get(map_Account.get(objOpp.AccountId).ParentId);
									} else if (map_Account.get(objOpp.AccountId).ParentId == null && map_MultiEINParentAccountIdListOfOpp.containsKey(objOpp.AccountId)) {
										map_OppIdRec = map_MultiEINParentAccountIdListOfOpp.get(objOpp.AccountId);
									}

									map_OppIdRec.remove(objOpp.Id);
									list_toProcessMultiEINOpportunityRecords.addAll(map_OppIdRec.values());
									if (map_OppIdRec.size() > 0) {
										objOpp.Order_Generated__c = true;
										map_TriggeringMultiEINOppIdRecord.put(objOpp.Id, objOpp);
										continue;
									}
									objBenefitOrder.Is_Multi_EIN__c = true;
								}
							}

							setBenefitOrderFields(BENEFIT_ORDER_BOR_RT_NAME, objBenefitOrder, objOpp, map_Account, map_BenefitsQueue, BENEFIT_ORDER_BOR_RT);
							objOpp.Order_Generated__c = true;
							if (string.isBlank(objBenefitOrder.BoR_Id__c) && String.isNotBlank(objBenefitOrder.Transition_to_Fulfillment__c)) {
								objBenefitOrder.BoR_Id__c = objBenefitOrder.Transition_to_Fulfillment__c;
							}
							lst_BenefitOrderToUpsert.add(objBenefitOrder);
						}
					}
				}
			}
		} else if (null != map_NewTTF && !map_NewTTF.isEmpty()) {
			//Benefit Order creation logic of "Benefit New plan, Benefit Change, Benefit Renewal" type
			for (Transition_to_Fulfillment__c objTTFRec : map_NewTTF.Values()) {
				if (objTTFRec.Opportunity__c != null)
					map_OppAndTTFIds.put(objTTFRec.Opportunity__c, objTTFRec.Id);
			}
			if (!map_OppAndTTFIds.isEmpty()) {
				Map<Id, Opportunity> map_Opportunity = new Map<Id, Opportunity>(
					[
						SELECT
							Signing_Forms_Completed_Timestamp__c,
							Send_Order_TimeStamp__c,
							ER_Confirm_TimeStamp__c,
							(
								SELECT Benefit_Type__c
								FROM Policies__r
								WHERE Benefit_Type__c != NULL AND Benefit_Type__c IN ('HSA', 'Commuter', 'Flexible Spending Account - Medical', 'Flexible Spending Account - Dependent Care')
							),
							(
								SELECT Id, PEO_Switcher__c, Applied_for_benefits_previously__c, Secretary_of_State_Registration_Status__c, New_TAdAs__c, Renewing_TAdAs__c
								FROM QA_Sheet__r
							),
							ID,
							Type,
							Verifying_Eligibility_Start__c,
							HI_Effective_Date__c,
							Notes__c,
							AccountId,
							Account.Name,
							BYOB_Broker__c,
							Account.Joined_Date_Panda__c,
							Account.EE_Active_Count_Panda__c,
							StageName,
							Maestro__c
						FROM Opportunity
						WHERE ID IN :map_OppAndTTFIds.keySet() AND Order_Generated__c = FALSE
					]
				);

				if (!map_Opportunity.isEmpty()) {
					for (Opportunity objOpp : map_Opportunity.Values()) {
						if (map_OppAndTTFIds.containsKey(objOpp.id)) {
							Benefit_Order__c objBORec = new Benefit_Order__c(
								Coverage_Effective_Date__c = objOpp.HI_Effective_Date__c,
								Opportunity__c = objOpp.Id,
								Maestro__c = objOpp.Maestro__c,
								Start_Date__c = System.today(),
								Account__c = objOpp.AccountId
							);
							Transition_to_Fulfillment__c objTTF;
							if (map_NewTTF.containskey(map_OppAndTTFIds.get(objOpp.Id))) {
								objTTF = map_NewTTF.get(map_OppAndTTFIds.get(objOpp.Id));
								objBORec.Transition_to_Fulfillment__c = objTTF.Id;
							}

							Id idTTFRecType = objTTF.RecordTypeId;
							if (idTTFRecType == BENEFIT_NEW_PLAN_TTF_RT || idTTFRecType == BENEFIT_CHANGE_TTF_RT || idTTFRecType == BENEFIT_RENEWAL_TTF_RT || idTTFRecType == BENEFIT_BYB_TTF_RT) {
								String strBORecName = '';
								String strTTFRecordTypeName = '';

								if (idTTFRecType == BENEFIT_NEW_PLAN_TTF_RT) {
									objBORec.RecordTypeId = BENEFIT_ORDER_RT_NEW_PLAN;
									strTTFRecordTypeName = TTF_NEW_PLAN_RT_NAME;
									strBORecName = BENEFIT_ORDER_NEW_PLAN_RT_NAME;
								} else if (idTTFRecType == BENEFIT_RENEWAL_TTF_RT) {
									objBORec.RecordTypeId = BENEFIT_ORDER_RT_RENEWAL;
									strTTFRecordTypeName = TTF_RENEWAL_RT_NAME;
									strBORecName = BENEFIT_ORDER_RENEWAL_RT_NAME;
								} else if (idTTFRecType == BENEFIT_CHANGE_TTF_RT) {
									objBORec.RecordTypeId = BENEFIT_ORDER_RT_CHANGE;
									strTTFRecordTypeName = TTF_CHANGE_RT_NAME;
									strBORecName = BENEFIT_ORDER_CHANGE_RT_NAME;
								} else if (idTTFRecType == BENEFIT_BYB_TTF_RT) {
									objBORec.RecordTypeId = BENEFIT_ORDER_BYB_RT;
									strTTFRecordTypeName = TTF_BYB_RT_NAME;
									strBORecName = BENEFIT_ORDER_BYB_RT_NAME;
								}

								if (idTTFRecType == BENEFIT_BYB_TTF_RT) {
									objBORec.Transition_to_Fulfillment__c = objTTF.Id;
									objBORec.Is_Multi_EIN__c = objTTF.Do_they_have_affiliates__c;
									if ((objTTF.Adding_TADA__c != null && objTTF.Adding_TADA__c == 'Y') || (objTTF.Renewing_TAdA_s__c != null && objTTF.Renewing_TAdA_s__c == 'Y')) {
										objBORec.Has_TADA__c = true;
									}

									objBORec.Prioritized_Customer__c = false;
									if (strYes == objTTF.Priority__c) {
										objBORec.Prioritized_Customer__c = true;
										objBORec.Priority_Reasons__c = objTTF.Priority_Reasons__c;
									}
								} else if (idTTFRecType == BENEFIT_NEW_PLAN_TTF_RT || idTTFRecType == BENEFIT_RENEWAL_TTF_RT || idTTFRecType == BENEFIT_CHANGE_TTF_RT) {
									if (objOpp.QA_Sheet__r != null && objOpp.QA_Sheet__r.size() > 0) {
										QA_Sheet__c objQASheet = objOpp.QA_Sheet__r[0];
										objBORec.QA_Sheet__c = objQASheet.Id;
										
										if (idTTFRecType == BENEFIT_ORDER_RT_RENEWAL || idTTFRecType == BENEFIT_ORDER_RT_CHANGE) {
											if (String.isNotEmpty(objQASheet.New_TAdAs__c) || String.isNotEmpty(objQASheet.Renewing_TAdAs__c)) {
												objBORec.Has_TADA__c = true;
											}
										}

										objBORec.Prioritized_Customer__c = false;
										if (strYes == objTTF.Priority__c) {
											objBORec.Prioritized_Customer__c = true;
											objBORec.Priority_Reasons__c = objTTF.Priority_Reasons__c;
										}
									}
								}
								if (!objOpp.policies__r.isEmpty()) {
									objBORec.Has_TADA__c = true;
								}

								objBORec = convertedCodeOfWFR(objBORec, objOpp, map_BenefitsQueue, strBORecName);
								objBORec.Type__c = (NewTransitionToFulfillmentController.BO_order_type != null
									? NewTransitionToFulfillmentController.BO_order_type[0]
									: (strBenefitOrderType != null ? strBenefitOrderType : null));
								objBORec.BoR_Date__c = dateBOR;
								objBORec.Order_Status__c = BenefitOrderUtil.STATUS_READY_FOR_OE_PREP;

								if (idTTFRecType == BENEFIT_BYB_TTF_RT) {
									objBORec.Prioritized_Customer__c = (objTTF.Priority__c != null && objTTF.Priority__c == 'Y');
									objBORec.Priority_Reasons__c = objTTF.Priority_Reasons__c;
									objBORec.Broker_Name__c = objOpp.BYOB_Broker__c;
									objBORec.Does_group_require_OE__c = (objTTF.Requires_Open_Enrollment_on_Gusto__c != null && objTTF.Requires_Open_Enrollment_on_Gusto__c == 'Y');
									objBORec.Order_Status__c = 'Ready for Intro';
								}

								//update opportunity
								OpportunityTriggerHelper.populateOpportunityStage(objOpp, strTTFRecordTypeName, lst_UpdateOpp, list_BusinessHours);
							}
							lst_BenefitOrderToInsert.add(objBORec);
						}
					}
				}
			}
		}

		if (!lst_BenefitOrderToInsert.isEmpty()) {
			if (null != map_NewTTF && !map_NewTTF.isEmpty()) {
				insert lst_BenefitOrderToInsert;
				// associate BO to TTF
				updateBenefitOrderInTTF(lst_BenefitOrderToInsert, map_OppAndTTFIds);
				if (lst_UpdateOpp.size() > 0) {
					update lst_UpdateOpp;
				}
			} else {
				if (!blnIsBYBRenewalOpp) {
					for (Benefit_Order__c objBO : lst_BenefitOrderToInsert) {
						objBO.OwnerId = Label.Advising_Team_User;
					}
					BenefitOrderHelper.skipTrigger = true;
				}
				insert lst_BenefitOrderToInsert;

				for (Benefit_Order__c objBenOrder : lst_BenefitOrderToInsert) {
					if (objBenOrder.Opportunity__c != null) {
						benefitOrderMap.put(objBenOrder.Opportunity__c, objBenOrder);
					}
				}
				BenefitOrderHelper.skipTrigger = false;

				if (blnIsBYBRenewalOpp) {
					updateOppsAfterInsert(benefitOrderMap.keySet());
				}
			}
		} else {
			if (!lst_BenefitOrderToUpsert.isEmpty()) {
				upsert lst_BenefitOrderToUpsert BoR_Id__c;
				//update Benefit order Id in TTF Record
				updateBenefitOrderInTTF(lst_BenefitOrderToUpsert, map_OppAndTTFIds);
			}

			if (list_toProcessMultiEINOpportunityRecords != null && list_toProcessMultiEINOpportunityRecords.size() > 0) {
				createBOForAffiliates(list_toProcessMultiEINOpportunityRecords, map_TriggeringMultiEINOppIdRecord);
			}
		}
	}

	private void updateBenefitOrderInTTF(List<Benefit_Order__c> lst_BenefitOrder, Map<ID, ID> map_OppAndTTFIds) {
		List<Transition_to_Fulfillment__c> lst_UpdateTTF = new List<Transition_to_Fulfillment__c>();

		for (Benefit_Order__c objNewBO : lst_BenefitOrder) {
			if (map_OppAndTTFIds.containsKey(objNewBO.Opportunity__c)) {
				lst_UpdateTTF.add(new Transition_to_Fulfillment__c(Id = map_OppAndTTFIds.get(objNewBO.Opportunity__c), Benefit_Order__c = objNewBO.Id));
			}
		}
		if (lst_UpdateTTF.size() > 0) {
			boolean ttfTriggerFlag = TransitiontoFulfilmentTriggerHelper.skipTrigger;
			TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
			update lst_UpdateTTF;
			TransitiontoFulfilmentTriggerHelper.skipTrigger = ttfTriggerFlag;
		}
	}

	//BY:PR, Date: March-26-2020, Dec: Multi-EIN functionality to get Multi-EIN Details
	public void getMultiEinRecordsDetails(set<ID> set_AccountIds) {
		if (set_AccountIds == null || set_AccountIds.size() == 0) {
			return;
		}
		set<String> set_MultiEINAccoutIds = new Set<String>();
		set<string> set_MultiEINParentAccountIds = new Set<string>();

		map_MultiEINParentAccountIdListOfOpp = new Map<string, Map<Id, Opportunity>>();
		map_MultiEINParentAccountNONClosedWonOppCount = new Map<string, integer>();

		for (Transition_to_Fulfillment__c objTTF : [
			SELECT Id, Account__c, Account__r.ParentId, Multi_EIN__c
			FROM Transition_to_Fulfillment__c
			WHERE Account__c IN :set_AccountIds AND Multi_EIN__c = 'Y' AND Opportunity__r.RecordType.Name = 'Benefits BoR'
		]) {
			set_MultiEINAccoutIds.add(objTTF.Account__c);
			if (objTTF.Account__r.ParentId != null) {
				set_MultiEINParentAccountIds.add(objTTF.Account__r.ParentId);
			} else {
				set_MultiEINParentAccountIds.add(objTTF.Account__c);
			}
		}

		//following code to further process the multiein accounts
		if (set_MultiEINParentAccountIds.size() > 0) {
			for (Opportunity objOpp : [
				SELECT Id, StageName, AccountId, Account.ParentId, HI_Effective_Date__c, Benefits_Current_Setup_Step__c, Renewal_Date__c, Id__c, Order_Generated__c, Maestro__c
				FROM Opportunity
				WHERE
					RecordType.Name = :BENEFIT_ORDER_BOR_RT_NAME
					AND (Account.ParentId IN :set_MultiEINParentAccountIds
					OR AccountId IN :set_MultiEINParentAccountIds)
					AND AccountId NOT IN :set_AccountIds
					AND StageName != :OPP_CLOSED_LOST
					AND Id__c != NULL
					AND IsClosed = FALSE
			]) {
				map<Id, Opportunity> map_TempOpp = new Map<Id, Opportunity>();
				string strKey;
				if (objOpp.Account.ParentId != null) {
					if (map_MultiEINParentAccountIdListOfOpp.containsKey(objOpp.Account.ParentId)) {
						map_TempOpp = map_MultiEINParentAccountIdListOfOpp.get(objOpp.Account.ParentId);
					}
					strKey = objOpp.Account.ParentId;
				} else if (objOpp.Account.ParentId == null) {
					if (map_MultiEINParentAccountIdListOfOpp.containsKey(objOpp.AccountId)) {
						map_TempOpp = map_MultiEINParentAccountIdListOfOpp.get(objOpp.AccountId);
					}
					strKey = objOpp.AccountId;
				}

				map_TempOpp.put(objOpp.Id, objOpp);
				map_MultiEINParentAccountIdListOfOpp.put(strKey, map_TempOpp);
				if (objOpp.StageName != 'Closed Won' && objOpp.StageName != 'Closed Lost') {
					integer lastCount = 0;
					if (map_MultiEINParentAccountNONClosedWonOppCount.containsKey(strKey)) {
						lastCount = map_MultiEINParentAccountNONClosedWonOppCount.get(strKey);
					}
					lastCount++;
					map_MultiEINParentAccountNONClosedWonOppCount.put(strKey, lastCount);
				}
			}
		}
	}

	//By: PR, Date: March-25-2020, Desc: Multi-EIN functionality to create BO for Affiliates
	public void createBOForAffiliates(list<Opportunity> list_AffiliateOppRecords, map<string, Opportunity> map_TriggeringOppIdRecord) {
		if (list_AffiliateOppRecords == null || list_AffiliateOppRecords.size() == 0) {
			return;
		}
		list_AffiliateOppRecords.addAll(map_TriggeringOppIdRecord.values());

		set<Id> set_AccountIds = new Set<Id>();
		set<Id> set_OpportunityIds = new Set<Id>();
		map<Id, Id> map_OppAndTTFIds = new Map<Id, Id>();
		Map<Id, Account> map_Account = new Map<Id, Account>();
		list<Benefit_Order__c> lst_BenefitOrderToUpsert = new List<Benefit_Order__c>();
		list<Opportunity> list_toUpdateOpportunity = new List<Opportunity>();

		for (Opportunity objOpp : list_AffiliateOppRecords) {
			set_AccountIds.add(objOpp.AccountId);
			set_OpportunityIds.add(objOpp.Id);
		}

		if (!set_OpportunityIds.isEmpty()) {
			for (Transition_to_Fulfillment__c objTTf : [SELECT id, Opportunity__c, Multi_EIN__c FROM Transition_to_Fulfillment__c WHERE Opportunity__c IN :set_OpportunityIds]) {
				map_OppAndTTFIds.put(objTTf.Opportunity__c, objTTf.Id);
			}
		}

		if (set_AccountIds != null && set_AccountIds.size() > 0) {
			List<Account> lst_Accounts = queryAccounts(set_AccountIds);
			if (lst_Accounts.size() > 0) {
				map_Account = new Map<Id, Account>(lst_Accounts);
			}
			for (Opportunity objOpp : list_AffiliateOppRecords) {
				Opportunity objOldOppRec = new Opportunity();
				if (map_Account.containsKey(objOpp.AccountId)) {
					Benefit_Order__c objBenefitOrder = new Benefit_Order__c();

					if (!map_OppAndTTFIds.isEmpty() && map_OppAndTTFIds.containsKey(objOpp.Id)) {
						objBenefitOrder.Transition_to_Fulfillment__c = map_OppAndTTFIds.get(objOpp.Id);
					}
					objBenefitOrder.Is_Multi_EIN__c = true;
					setBenefitOrderFields(BENEFIT_ORDER_BOR_RT_NAME, objBenefitOrder, objOpp, map_Account, map_BenefitsQueue, BENEFIT_ORDER_BOR_RT);

					objOpp.Order_Generated__c = true;
					lst_BenefitOrderToUpsert.add(objBenefitOrder);
					if (!map_TriggeringOppIdRecord.containsKey(objOpp.Id)) {
						list_toUpdateOpportunity.add(objOpp);
					}
				}
			}
		}

		try {
			if (lst_BenefitOrderToUpsert.size() > 0) {
				upsert lst_BenefitOrderToUpsert BoR_Id__c;
				//update Benefit order Id in TTF Record
				updateBenefitOrderInTTF(lst_BenefitOrderToUpsert, map_OppAndTTFIds);
			}

			if (list_toUpdateOpportunity.size() > 0) {
				boolean blnPrevSkipTrigger = OpportunityTriggerHelper.skipTrigger;
				OpportunityTriggerHelper.skipTrigger = true;

				update list_toUpdateOpportunity;
				OpportunityTriggerHelper.skipTrigger = blnPrevSkipTrigger;
			}
		} catch (exception objException) {
			ExceptionLogUtil.logException('BenefitOrderHelperFunctions', 'createBOForAffiliates', 'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), objException.getStackTraceString());
		}
	}

	public void setBenefitOrderFields(String strRecordType, Benefit_Order__c objBenefitOrder, Opportunity objOpp, Map<Id, Account> map_Account, Map<String, Id> map_BenefitsQueue, Id IdRecordType) {
		objBenefitOrder.RecordTypeId = IdRecordType;
		String recordTypeName = ' - ' + strRecordType;
		objBenefitOrder.Name = map_Account.get(objOpp.AccountId).Name.left(80 - recordTypeName.length()) + ' - ' + strRecordType;
		objBenefitOrder.Opportunity__c = objOpp.Id;
		objBenefitOrder.Maestro__c = objOpp.Maestro__c;
		objBenefitOrder.Account__c = objOpp.AccountId;
		if (strRecordType == BENEFIT_ORDER_RENEWAL_ALIGN_RT_NAME) {
			objBenefitOrder.Type__c = 'Renewal Alignment';
			objBenefitOrder.Coverage_Effective_Date__c = objOpp.HI_Effective_Date__c;
			objBenefitOrder.Follow_Up_Date__c = system.today();
			if (!map_BenefitsQueue.isEmpty() && map_BenefitsQueue.containsKey(QUEUE_RENEWAL_ALIGNMENT)) {
				objBenefitOrder.OwnerId = map_BenefitsQueue.get(QUEUE_RENEWAL_ALIGNMENT);
			}

			if (objOpp.stageName == 'Alignment In Progress' && objOpp.Benefits_Current_Setup_Step__c == 'Awaiting Offerings') {
				objBenefitOrder.Order_Status__c = 'Ready for alignment';
			} else {
				objBenefitOrder.Order_Status__c = 'New';
			}
		} else if (strRecordType == BENEFIT_ORDER_BOR_RT_NAME) {
			if (objOpp.stageName == 'Closed Won') {
				objBenefitOrder.Order_Status__c = 'Ready for Qualification';
				//objBenefitOrder.Start_Date__c= System.today();
			} else if (objOpp.stageName == 'Pending PR') {
				objBenefitOrder.Order_Status__c = 'Pending Qualification';
			}

			objBenefitOrder.Renewal_Date__c = objOpp.Renewal_Date__c;
			if (String.isNotBlank(objOpp.Id__c)) {
				objBenefitOrder.BoR_Id__c = objOpp.Id__c.replace('HIBORTRANSFER', '');
			}
		} else if (strRecordType == BENEFIT_ORDER_BYB_RT_NAME) {
			objBenefitOrder.Type__c = BenefitOrderUtil.BYB_RENEWAL;
			objBenefitOrder.Order_Status__c = BenefitOrderUtil.STATUS_READY_FOR_INTRO;
			objBenefitOrder.Prioritized_Customer__c = true;
			objBenefitOrder.Priority_Reasons__c = BenefitOrderUtil.PRIORITY_REASON_EFFECTIVE_DATE;
			objBenefitOrder.Does_group_require_OE__c = true;
			objBenefitOrder.Start_Date__c = System.now().date();
			objBenefitOrder.Additional_Details__c = null;

			objBenefitOrder.Broker_Name__c = objOpp.BYOB_Broker__c;
			objBenefitOrder.Coverage_Effective_Date__c = objOpp.HI_Effective_Date__c;

			if (!map_BenefitsQueue.isEmpty() && map_BenefitsQueue.containsKey(QUEUE_BENEFIT_BYOB)) {
				objBenefitOrder.OwnerId = map_BenefitsQueue.get(QUEUE_BENEFIT_BYOB);
			}
		}
	}

	public void setBenefitOrderFields(String strRecordType, List<Benefit_Order__c> lst_BOrder, Boolean isAcceptedOrder, Id loggedInUser, Id IdRecordType) {
		List<Benefit_Order__c> lst_BOs = new List<Benefit_Order__c>();
		string strRecTypeID = IdRecordType;
		for (Benefit_Order__c objBO : lst_BOrder) {
			objBO.RecordTypeId = strRecTypeID;
			if (isAcceptedOrder && objBO.Order_Status__c == 'Ready for Qualification') {
				objBO.Order_Status__c = 'Qualification';
				objBO.UW_Owner__c = loggedInUser;
				lst_BOs.add(objBO);
			}
		}
		update lst_BOs;
	}

	private Benefit_Order__c convertedCodeOfWFR(Benefit_Order__c updateBO, Opportunity op, Map<String, Id> queueMap, String strBORecName) {
		// WFR-Set Order Name
		String boName = op.Account.Name + ' ' + strBORecName;
		if (boName.length() > 80) {
			boName = boName.subString(0, 80);
		}
		updateBO.Name = boName;
		//TADA New Plan- Assign benefit order and type
		if (updateBO.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID && op.Type == 'New TAdA Plan') {
			updateBO.Type__c = 'New TAdA Plan';
			if (queueMap.containsKey(QUEUE_CHANGE_BENEFITS_OPERATIONS)) {
				updateBO.OwnerId = queueMap.get(QUEUE_CHANGE_BENEFITS_OPERATIONS);
			}
		}
		//TADA Transfer Plan- Assign benefit order and type
		if (updateBO.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID && op.Type == 'Transfer TAdA Plan') {
			updateBO.Type__c = 'Transfer TAdA Plan';
			if (queueMap.containsKey(QUEUE_CHANGE_BENEFITS_OPERATIONS)) {
				updateBO.OwnerId = queueMap.get(QUEUE_CHANGE_BENEFITS_OPERATIONS);
			}
		}
		//TADA-Assign benefit order and type
		if (updateBO.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID && op.Type == 'TADA') {
			updateBO.Type__c = 'TADA';
			if (queueMap.containsKey(QUEUE_CHANGE_BENEFITS_OPERATIONS)) {
				updateBO.OwnerId = queueMap.get(QUEUE_CHANGE_BENEFITS_OPERATIONS);
			}
		}
		//Update EE at Fulfillment
		if (updateBO.Order_Status__c == 'Fulfilled') {
			updateBO.EE_at_Fulfillment__c = op.Account.EE_Active_Count_Panda__c;
		}
		//Change Order Assignement
		if (updateBO.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID) {
			if (queueMap.containsKey(QUEUE_CHANGE_BENEFITS_OPERATIONS) && queueMap.get(QUEUE_CHANGE_BENEFITS_OPERATIONS) != null) {
				updateBO.OwnerId = queueMap.get(QUEUE_CHANGE_BENEFITS_OPERATIONS);
			}
		}
		//Change Order Assignement
		if (updateBO.RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID) {
			if (queueMap.containsKey(QUEUE_RENEWAL_BENEFITS_OPERATIONS) && queueMap.get(QUEUE_RENEWAL_BENEFITS_OPERATIONS) != null) {
				updateBO.OwnerId = queueMap.get(QUEUE_RENEWAL_BENEFITS_OPERATIONS);
			}
		}
		//Change Order Assignement
		if (updateBO.RecordTypeId == BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID) {
			if (queueMap.containsKey(QUEUE_NEW_PLAN_BENEFITS_OPERATIONS) && queueMap.get(QUEUE_NEW_PLAN_BENEFITS_OPERATIONS) != null) {
				updateBO.OwnerId = queueMap.get(QUEUE_NEW_PLAN_BENEFITS_OPERATIONS);
			}
		}
		return updateBO;
	}

	//Lirik- Migration for BOR to BO -- Start ---
	//Get the raw values of the Status of the Hi bor transfer to SF value
	//Where This Used:- BenefitOrderhelper (before insert) and HiBORTranferTriggerHelper
	public static void updateBoRApplicationStatus(Map<String, HI_BoR_Transfer__c> mapHIBoRTransfer, List<Benefit_Order__c> lstBenefitOrders) {
		Map<String, String> integrationMap = IntegrationUtils.getIntegrationValueMap('Benefit_Order__c', 'Status__c');
		for (Benefit_Order__c obj : lstBenefitOrders) {
			if (String.isNotBlank(obj.BoR_Id__c) && mapHIBoRTransfer.containsKey(obj.BoR_Id__c)) {
				//Order Status
				string hiStatus = mapHIBoRTransfer.get(obj.BoR_Id__c).Status__c;
				if (integrationMap.containsKey(hiStatus)) {
					obj.Application_Status__c = integrationMap.get(hiStatus);
				}
			}
		}
	}

	/**BY: PR, Date: Frb-18-2020,
	Desc: This method is called from "UserTRiggerHelper.cls" after update event. this method is querying all the "Benefit transfer" BO records and then
		we are reassigning the record to the "Initial Owner" who is back in office. */
	public static void reAssignBOtoInitialAdvocateOnReturnToOffice(set<string> set_ReturnToOfficeUserIds) {
		if (set_ReturnToOfficeUserIds == null || set_ReturnToOfficeUserIds.size() == 0) {
			return;
		}

		ID idBenefitTransfer = BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID;
		list<Benefit_Order__c> list_ToReAssignBOs = new List<Benefit_Order__c>();

		for (Benefit_Order__c objBO : [
			SELECT Id, OwnerId, Initial_Owner__c
			FROM Benefit_Order__c
			WHERE Initial_Owner__c IN :set_ReturnToOfficeUserIds AND OwnerId NOT IN :set_ReturnToOfficeUserIds AND recordTypeId = :idBenefitTransfer AND Order_Status__c NOT IN :Utils.setBOExclude
		]) {
			if (objBO.OwnerId != objBO.Initial_Owner__c) {
				objBO.OwnerId = objBO.Initial_Owner__c;
				list_ToReAssignBOs.add(objBO);
			}
		}

		if (list_ToReAssignBOs.size() > 0) {
			try {
				update list_ToReAssignBOs;
			} catch (exception ex) {
				ExceptionLogUtil.logException('BenefitOrderHelperFunctions', 'Update BO::reAssignBOtoInitialAdvocateOnReturnToOffice', ex.getMessage(), 'High');
			}
		}
	}

	public static List<Account> queryAccounts(Set<Id> acctIdSet) {
		return [SELECT Id, Name, Joined_Date_Panda__c, ParentId FROM Account WHERE Id IN :acctIdSet];
	}

	@future
	public static void updateOppsAfterInsert(Set<Id> set_OppIds) {
		List<Opportunity> list_OppsToUpdate = new List<Opportunity>();
		for (Id idOppId : set_OppIds) {
			Opportunity objOppToUpdate = new Opportunity(Id = idOppId, Order_Generated__c = true, StageName = OpportunityUtil.CLOSED_WON_STAGE);
			list_OppsToUpdate.add(objOppToUpdate);
		}

		if (!list_OppsToUpdate.isEmpty()) {
			OpportunityTriggerHelper.skipTrigger = true;
			update list_OppsToUpdate;
			OpportunityTriggerHelper.skipTrigger = false;
		}
	}
}