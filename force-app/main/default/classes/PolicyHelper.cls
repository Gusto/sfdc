/**
 * @name         PolicyHelper
 * @author       Aurobind Ravichandran
 * @date         04/21/2017
 * @description  This class handles policies coming from HI Policy table
 * @see   PolicyHelper_Tests
 **/
public with sharing class PolicyHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	public static boolean forceLineItemLogic = false;
	public static boolean skipOppDispatchTrigger = false;
	public static Set<Id> set_COSwitchIds = new Set<Id>();
	//public static Map<String, Carrier_Order__c> map_TerminatedCOs = new Map<String, Carrier_Order__c>();
	private static Set<Benefit_Order__c> set_BenefitOrders = new Set<Benefit_Order__c>();
	private static Id idMFAutomationQueue = GlobalQueryHelper.getQueueIdByName('MF Automation');
	private static Id idMemberOpsQueue = GlobalQueryHelper.getQueueIdByName(CaseUtils.MEMBER_OPS_QUEUE);
	private static Id CARRIER_ORDER_NEW_PLAN_RT = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
	private static Id CARRIER_ORDER_RENEWAL_RT = Cache.getRecordTypeId('Carrier_Order__c', 'Renewal');
	private static Id CARRIER_ORDER_CHANGE_RT = Cache.getRecordTypeId('Carrier_Order__c', 'Benefit Change');

	public PolicyHelper() {
		super('PolicyHelper');
	}

	/**
	 * Before Insert Handler
	 */
	public override void beforeInsert() {
		List<Policy__c> newPolicyList = (List<Policy__c>) Trigger.new;
		Map<Id, Policy__c> oldPolicyMap = (Map<Id, Policy__c>) Trigger.oldMap;
		populateComplexityScore(newPolicyList, null);
		//update
		policyHandlerBuilder(newPolicyList, oldPolicyMap);
		isPolicyInsertedOnCarrierOrder(newPolicyList, oldPolicyMap); //moved from after insert
		updateCOrderonPolicy(newPolicyList);
	}

	/**
	 * After insert handler
	 */
	public override void afterInsert() {
		List<Policy__c> newPolicyList = (List<Policy__c>) Trigger.new;
		Map<Id, Policy__c> oldPolicyMap = (Map<Id, Policy__c>) Trigger.oldMap;
		Map<Id, Policy__c> newPolicyMap = (Map<Id, Policy__c>) Trigger.newMap;

		updateRelatedOppBenefitsState(newPolicyList, null);
		isPolicySelected(newPolicyList, oldPolicyMap, 'insert');
		updateRelatedCarrierOrdrBenefitTypes(newPolicyList, null);
		validateOppLineItemsAndPerformDML(newPolicyList, null);
		updateBOEffectiveDate(newPolicyList, oldPolicyMap, true);
	}

	/**
	 * Before Update Handler
	 */
	public override void beforeUpdate() {
		List<Policy__c> newPolicyList = (List<Policy__c>) Trigger.new;
		Map<Id, Policy__c> oldPolicyMap = (Map<Id, Policy__c>) Trigger.oldMap;

		populateComplexityScore(newPolicyList, oldPolicyMap);
		policyHandlerBuilder(newPolicyList, oldPolicyMap);

		updateCOrderonPolicy(newPolicyList);
		isPolicySelected(newPolicyList, oldPolicyMap, 'update');
		removePoliciesFromCarrierOrder(newPolicyList, oldPolicyMap);
	}

	/**
	 * After update handler
	 */
	public override void afterUpdate() {
		List<Policy__c> newPolicyList = (List<Policy__c>) Trigger.new;
		Map<Id, Policy__c> oldPolicyMap = (Map<Id, Policy__c>) Trigger.oldMap;
		Map<Id, Policy__c> newPolicyMap = (Map<Id, Policy__c>) Trigger.newMap;
		updateRelatedOppBenefitsState(newPolicyList, oldPolicyMap);
		updateRelatedCarrierOrdrBenefitTypes(newPolicyList, oldPolicyMap);
		validateOppLineItemsAndPerformDML(newPolicyList, oldPolicyMap);
		updateBOEffectiveDate(newPolicyList, oldPolicyMap, false);
		updateCaseGroupNumber(newPolicyList, oldPolicyMap); //BY:PR, Date:Jan.6.2020, Desc: syncing  group name to related Case
	}

	/**
	 * After delete handler
	 */
	public override void afterDelete() {
		Map<Id, Policy__c> oldPolicyMap = (Map<Id, Policy__c>) Trigger.oldMap;

		updateRelatedOppBenefitsState(null, oldPolicyMap);
		updateRelatedCarrierOrdrBenefitTypes(null, oldPolicyMap);
		validateOppLineItemsAndPerformDML(oldPolicyMap.values(), null);
	}

	/**
	 * @description Syncs "Group Number" from Policy to related Case
	 * @author PR
	 * @date Jan 6 2020
	 * @param  newPolicyList Trigger.new
	 * @param  oldPolicyMap  Trigger.oldMap
	 */
	public static void updateCaseGroupNumber(List<Policy__c> newPolicyList, Map<Id, Policy__c> oldPolicyMap) {
		if (newPolicyList.size() > 0) {
			set<Id> set_accountId = new Set<Id>();
			set<Id> set_carrierId = new Set<Id>();

			for (Policy__c objPolicy : newPolicyList) {
				if (oldPolicyMap != null && oldPolicyMap.size() > 0 && oldPolicyMap.containsKey(objPolicy.Id)) {
					Policy__c objOldPolicy = oldPolicyMap.get(objPolicy.Id);

					//getting the account and carrier Id for the policy where "Group Number" is populated recently
					if (
						(objPolicy.Group_Number__c != null && objPolicy.Group_Number__c != objOldPolicy.Group_Number__c) ||
						(objPolicy.policy_Number__c != null &&
						objPolicy.policy_Number__c != objOldPolicy.policy_Number__c)
					) {
						if (objPolicy.Account__c != null && objPolicy.Carrier__c != null) {
							set_accountId.add(objPolicy.Account__c);
							set_carrierId.add(objPolicy.Carrier__c);
						}
					}
				}
			}

			if (set_accountId.size() > 0 && set_carrierId.size() > 0) {
				map<string, List<Case>> map_accountIdCarrierIdCaseObj = new Map<string, List<Case>>();
				list<Case> lst_toUpdateCases = new List<Case>();

				//querying the related Case
				for (Case objCase : [
					SELECT Id, AccountId, Carrier__c, MF_Group_Number__c, MF_Policy_Number__c
					FROM Case
					WHERE
						(recordTypeId = :Cache.getRecordTypeId('Case', 'MF NHE')
						OR recordTypeId = :Cache.getRecordTypeId('Case', 'MF Termination')
						OR recordTypeId = :Cache.getRecordTypeId('Case', 'MF Member/Group Updates')
						OR recordTypeId = :Cache.getRecordTypeId('Case', 'MF Group Updates'))
						AND (MF_Group_Number__c = NULL
						OR MF_Policy_Number__c = NULL)
						AND AccountId IN :set_accountId
						AND Carrier__c IN :set_carrierId
						AND (OwnerId = :idMFAutomationQueue
						OR OwnerId = :idMemberOpsQueue)
						AND status = 'On Hold'
				]) {
					List<Case> cseList = new List<case>();

					if (objCase.AccountId != null && objCase.Carrier__c != null) {
						string strKey = string.valueOf(objCase.AccountId) + string.valueOf(objCase.Carrier__c);
						if (map_accountIdCarrierIdCaseObj.containsKey(strKey)) {
							cseList = map_accountIdCarrierIdCaseObj.get(strKey);
						}
						cseList.add(objCase);
						map_accountIdCarrierIdCaseObj.put(strKey, cseList);
					}
				}

				if (map_accountIdCarrierIdCaseObj.size() > 0) {
					for (Policy__c objPolicy : newPolicyList) {
						if (objPolicy.Account__c != null && objPolicy.Carrier__c != null) {
							string strKey = string.valueOf(objPolicy.Account__c) + string.valueOf(objPolicy.Carrier__c);
							if (map_accountIdCarrierIdCaseObj.containsKey(strKey)) {
								List<Case> cseList = map_accountIdCarrierIdCaseObj.get(strKey);
								for (Case obj_tempCase : cseList) {
									//case obj_tempCase = map_accountIdCarrierIdCaseObj.get(strKey);
									if (string.isBlank(obj_tempCase.MF_Group_Number__c))
										obj_tempCase.MF_Group_Number__c = objPolicy.Group_Number__c;

									if (string.isBlank(obj_tempCase.MF_Policy_Number__c))
										obj_tempCase.MF_Policy_Number__c = objPolicy.Policy_Number__c;

									obj_tempCase.Status = 'New';
									lst_toUpdateCases.add(obj_tempCase);
								}
							}
						}
					}

					Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
					//error handling
					if (lst_toUpdateCases.size() > 0) {
						CaseTriggerHelper.skipTrigger = true;
						dmlUpdateErrorsMap = Utils.doDMLAndReturnAllErrors(
							'Update', // type of DML operation
							'Carrier__c', // Return map key
							lst_toUpdateCases, // sObject list
							false, // all or none flag
							true, // log the error
							'PolicyHelper-updateCaseGroupNumber'
						);

						if (dmlUpdateErrorsMap.keySet().size() > 0) {
							for (Policy__c objPolicy : newPolicyList) {
								if (dmlUpdateErrorsMap.containsKey(objPolicy.Carrier__c)) {
									objPolicy.addError(dmlUpdateErrorsMap.get(objPolicy.Carrier__c));
								}
							}
						}
						CaseTriggerHelper.skipTrigger = false;
					}
				}
			}
		}
	}

	/**
	 * If Is_Selected__c is checked/unchecked, validates if new opp line item needs to be created/existing line item
	 * needs to be deleted. Reports any errors during DML operations.
	 * <br>To handle null pointer exception if selected benefit type does not exist on opportunity price book enteries.
	 *
	 * @date 7/7/2020
	 * @author Yuvraj
	 */
	public static void validateOppLineItemsAndPerformDML(List<Policy__c> newPolicyList, Map<Id, Policy__c> oldPolicyMap) {
		List<Policy__c> policiesToBeProcessed = new List<Policy__c>();
		Set<Id> oppIdSet = new Set<Id>();
		Set<String> benefitProdSet = new Set<String>();
		// Yuvraj 07-07-2020
		Map<String, String> dmlInsertErrorsMap = new Map<String, String>();
		Map<String, String> dmlDeleteErrorsMap = new Map<String, String>();
		for (Policy__c policy : newPolicyList) {
			if ((oldPolicyMap == null && policy.Is_Selected__c) || (oldPolicyMap != null && policy.Is_Selected__c != oldPolicyMap.get(policy.Id).Is_Selected__c) || forceLineItemLogic == true) {
				policiesToBeProcessed.add(policy);
				oppIdSet.add(policy.Opportunity__c);
				benefitProdSet.add(policy.Benefit_Type__c);
			}
		}
		if (newPolicyList == null && oldPolicyMap != null) {
			for (Policy__c policy : oldPolicyMap.values()) {
				if (policy.Is_Selected__c) {
					policiesToBeProcessed.add(policy);
					oppIdSet.add(policy.Opportunity__c);
					benefitProdSet.add(policy.Benefit_Type__c);
				}
			}
		}

		// If no records to be processed, return
		if (policiesToBeProcessed.size() == 0) {
			return;
		}
		//get Opportunities with line items in a map
		Map<Id, Opportunity> oppWithLineItemsMap = getOpportunityWithLineItems(oppIdSet);
		// Get PriceBook Entry records for PriceBook Id + Product Name combination
		Map<String, PricebookEntry> benefitPBIDPlusProdNameToPBEntryMap = getPriceBookentryRecords(benefitProdSet);

		// Lists to perform DML operations
		List<OpportunityLineItem> toBeInsertedLineItemList = new List<OpportunityLineItem>();
		List<OpportunityLineItem> toBeDeletedLineItemList = new List<OpportunityLineItem>();
		List<OpportunityLineItem> toBeUpdatedLineItemList = new List<OpportunityLineItem>();
		// Prepare a map that stores Opp Id + Product Name as a key and all eligible line items as value
		Map<id, Map<String, OpportunityLineItem>> existingProdNameToLineItemMap = prepareProdNameToLineItemsMap(oppWithLineItemsMap);
		Map<id, Map<String, Policy__c>> existingOppBenTypePolicyMap = getOppBenTypePolicyMap(oppWithLineItemsMap);

		for (Id oppId : existingOppBenTypePolicyMap.keySet()) {
			if (oppWithLineItemsMap.containsKey(oppId)) {
				Opportunity exOpp = oppWithLineItemsMap.get(oppId);
				if (exOpp.Recordtype.name == 'Benefits BoR')
					continue;
			}
			Map<String, Policy__c> policyMap = existingOppBenTypePolicyMap.get(oppId);
			Map<String, OpportunityLineItem> lineItemMap = existingProdNameToLineItemMap.get(oppId);

			Boolean containsLTST = policyMap.containsKey('Long Term Disability') && policyMap.containsKey('Short Term Disability') ? true : false;
			Set<String> set_benefitType = new Set<String>();

			for (String benType : policyMap.keySet()) {
				if (benefitProdSet.contains(benType) && benefitProdSet.contains(benType) && containsLTST) {
					for (Id lineId : existingProdNameToLineItemMap.keySet()) {
						Map<String, OpportunityLineItem> currentBenefit = existingProdNameToLineItemMap.get(lineId);
						if (currentBenefit.containsKey('Long Term Disability')) {
							OpportunityLineItem ltdLineItem = currentBenefit.get('Long Term Disability');
							toBeUpdatedLineItemList.add(ltdLineItem);
						}
					}
				}
				if (!benefitProdSet.contains(benType)) {
					continue;
				}
				if (!lineItemMap.containsKey(benType)) {
					Opportunity opp = oppWithLineItemsMap.get(oppId);
					if ((opp.IsClosed == true && opp.IsWon == false) || opp.Locked__c == true) {
						continue;
					}
					Policy__c policy = policyMap.get(benType);
					if ((policy.Benefit_Type__c == null || opp.NumberOfEmployees__c == null || opp.NumberOfEmployees__c == 0) && !test.isRunningTest()) {
						continue;
					}

					OpportunityLineItem item;
					if (benefitPBIDPlusProdNameToPBEntryMap.containsKey(opp.Pricebook2Id + '-' + policy.Benefit_Type__c)) {
						item = OpportunityTriggerHelper.buildOppLineItem(
							policy.Opportunity__c,
							benefitPBIDPlusProdNameToPBEntryMap.get(opp.Pricebook2Id + '-' + policy.Benefit_Type__c),
							opp.numberOfEmployees__c
						);
					} else {
						dmlInsertErrorsMap.put(policy.Opportunity__c, 'Selected benefit type doesnot exist in Opportunity pricebook enteries ');
					}

					if (!set_benefitType.contains(benType)) {
						if (item != null && item.Id == null) {
							toBeInsertedLineItemList.add(item);
						}
						set_benefitType.add(benType);
					}
				}
			}

			for (String benType : lineItemMap.keySet()) {
				if (!policyMap.containsKey(benType)) {
					Opportunity opp = oppWithLineItemsMap.get(oppId);
					if (opp.IsClosed == true || opp.Locked__c == true) {
						continue;
					}
					toBeDeletedLineItemList.add(lineItemMap.get(benType));
				}
			}
		}

		if (toBeInsertedLineItemList.size() > 0) {
			dmlInsertErrorsMap = Utils.doDMLAndReturnAllErrors(
				'Insert', // type of DML operation
				'OpportunityId', // Return map key
				toBeInsertedLineItemList, // sObject list
				false, // all or none flag
				true, // log the error
				'PolicyHelper-validateOppLineItemsAndPerformDML'
			);
		}
		if (toBeDeletedLineItemList.size() > 0) {
			dmlDeleteErrorsMap = Utils.doDMLAndReturnAllErrors(
				'Delete', // type of DML operation
				'OpportunityId', // Return map key
				toBeDeletedLineItemList, // sObject list
				false, // all or none flag
				true, // log the error
				'PolicyHelper-validateOppLineItemsAndPerformDML'
			);
		}
		// Handle the dml errors via addError
		if (dmlInsertErrorsMap.keySet().size() > 0 || dmlDeleteErrorsMap.keySet().size() > 0) {
			for (Policy__c policy : policiesToBeProcessed) {
				if (dmlInsertErrorsMap.containsKey(policy.Opportunity__c)) {
					if (dmlInsertErrorsMap.get(policy.Opportunity__c).contains('benefit type'))
						policy.Benefit_Type__c.addError(dmlInsertErrorsMap.get(policy.Opportunity__c));
					else
						policy.addError(dmlInsertErrorsMap.get(policy.Opportunity__c));
				}
				if (dmlDeleteErrorsMap.containsKey(policy.Opportunity__c)) {
					policy.addError(dmlDeleteErrorsMap.get(policy.Opportunity__c));
				}
			}
		}

		if (toBeUpdatedLineItemList.size() > 0)
			update toBeUpdatedLineItemList;
	}

	/*
	//BBO-455 - Deprecated : Not in used.
	public static void processAncillaryGroups(Set<Id> oppIdSet) {
		List<OpportunityLineItem> lineItemsForUpdate = new List<OpportunityLineItem>();
		for (Opportunity opp : [
			SELECT Id, (SELECT Id, Product2Id, Product2.Name FROM OpportunityLineItems WHERE Product2.Name IN ('Life', 'Long Term Disability', 'Short Term Disability'))
			FROM opportunity
			WHERE id IN :oppIdSet
		]) {
			if (opp.OpportunityLineItems != null) {
				integer i = 1;
				for (OpportunityLineItem lineItem : opp.OpportunityLineItems) {
					if (opp.OpportunityLineItems.size() == 0) {
						lineItem.discount = 0;
						continue;
					}
					if (i == opp.OpportunityLineItems.size()) {
						lineItem.discount = 100 - (100 - ((100 / opp.OpportunityLineItems.size()) * (i - 1)));
						lineItemsForUpdate.add(lineItem);
					} else {
						lineItem.discount = 100 - ((100 / opp.OpportunityLineItems.size()));
						lineItemsForUpdate.add(lineItem);
					}
					i += 1;
				}
			}
		}
		if (lineItemsForUpdate.size() > 0) {
			update lineItemsForUpdate;
		}
	}
	*/
	public static map<id, Map<String, Policy__c>> getOppBenTypePolicyMap(Map<Id, Opportunity> oppWithLineItemsMap) {
		map<id, Map<String, Policy__c>> oppIdBenTypePolicyMap = new Map<id, Map<String, Policy__c>>();

		for (Opportunity o : oppWithLineItemsMap.values()) {
			oppIdBenTypePolicyMap.put(o.id, new Map<String, Policy__c>());
		}

		for (Policy__c policy : [SELECT Id, Benefit_Type__c, Opportunity__c FROM Policy__c WHERE Opportunity__c IN :oppWithLineItemsMap.values() AND Is_Selected__c = TRUE AND Benefit_Type__c != '']) {
			Map<String, Policy__c> benefitTypeToPolicyMap = oppIdBenTypePolicyMap.get(policy.Opportunity__c);

			benefitTypeToPolicyMap.put(policy.Benefit_Type__c, policy);
		}
		return oppIdBenTypePolicyMap;
	}

	/**
	 * Re usable method to return all line Items for a given opportunity, product combination
	 */

	public static map<id, Map<String, OpportunityLineItem>> prepareProdNameToLineItemsMap(Map<Id, Opportunity> oppWithLineItemsMap) {
		map<id, Map<String, OpportunityLineItem>> oppIdLineTypeLineItemMap = new Map<id, Map<String, OpportunityLineItem>>();

		for (Opportunity o : oppWithLineItemsMap.values()) {
			Map<String, OpportunityLineItem> lineItemTypeToLineItemMap = new Map<String, OpportunityLineItem>();
			oppIdLineTypeLineItemMap.put(o.id, lineItemTypeToLineItemMap);

			for (OpportunityLineItem item : o.OpportunityLineItems) {
				lineItemTypeToLineItemMap = oppIdLineTypeLineItemMap.get(o.Id);
				lineItemTypeToLineItemMap.put(item.Product2.Name, item);
			}
		}
		return oppIdLineTypeLineItemMap;
	}

	/*
	 *   By : Pravesh Rana, April 10, 2017
	 *   Introduced this method to udpate the Opportunity's multiselect picklist field "Benefits State(s)"
	 *   with all the unique state codes when a child Policy__c object record trigger a DML operation.
	 *
	 */

	public static void updateRelatedOppBenefitsState(list<Policy__c> newPolicyList, map<id, Policy__c> oldPolicyMap) {
		Set<Id> oppIdSet = new Set<id>();
		List<Policy__c> policies = new List<Policy__c>();
		List<Opportunity> opportunitiesForUpdate = new List<Opportunity>();
		if (oldPolicyMap == null || oldPolicyMap.keyset().size() == 0) {
			policies = newPolicyList;
		}
		if (newPolicyList == null || newPolicyList.size() == 0) {
			policies = oldPolicyMap.values();
		}
		if (oldPolicyMap != null && oldPolicyMap.keyset().size() > 0 && newPolicyList != null) {
			for (Policy__c policy : newPolicyList) {
				Policy__c oldPolicy = oldPolicyMap.get(policy.Id);
				if (oldPolicy.State__c != policy.State__c) {
					oppIdSet.add(policy.Opportunity__c);
				}
			}
		}
		for (Policy__c policy : policies) {
			oppIdSet.add(policy.Opportunity__c);
		}

		if (oppIdSet.size() > 0) {
			for (Opportunity opp : [
				SELECT
					Id,
					Benefits_State__c,
					UW_state__c,
					(SELECT Id, State__c, State__r.Name, State__r.Abbreviation__c, Benefit_Type__c, Carrier__c, Carrier__r.Name FROM Policies__r WHERE Is_Selected__c = TRUE)
				FROM Opportunity
				WHERE Id IN :oppIdSet
			]) {
				opp.Benefits_State__c = '';

				if (opp.Policies__r != null && opp.Policies__r.size() > 0) {
					for (Policy__c poli : opp.Policies__r) {
						if (poli.State__c != null && poli.State__r.Abbreviation__c != null) {
							if (opp.Benefits_State__c == null || opp.Benefits_State__c.IndexOf(poli.State__r.Abbreviation__c) < 0) {
								if (opp.Benefits_State__c != null && opp.Benefits_State__c != '') {
									opp.Benefits_State__c += ';' + poli.State__r.Abbreviation__c;
								} else {
									opp.Benefits_State__c += poli.State__r.Abbreviation__c;
								}
							}
						}
						if (poli.State__c != null && (String.isBlank(opp.UW_state__c) || poli.Benefit_Type__c == 'Medical')) {
							opp.UW_state__c = poli.State__r.Name;
						}
					}
				}
				opportunitiesForUpdate.add(opp);
			}
		}

		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();

		if (opportunitiesForUpdate.size() > 0) {
			boolean oppSkipTrigger = OpportunityTriggerHelper.skipTrigger;
			OpportunityTriggerHelper.skipTrigger = true;
			dmlUpdateErrorsMap = Utils.doDMLAndReturnAllErrors(
				'Update', // type of DML operation
				'Id', // Return map key
				opportunitiesForUpdate, // sObject list
				false, // all or none flag
				true, // log the error
				'PolicyHelper-updateRelatedOppBenefitsState'
			);
			OpportunityTriggerHelper.skipTrigger = oppSkipTrigger;
		}

		// Handle the dml errors via addError
		if (dmlUpdateErrorsMap.keySet().size() > 0) {
			if (newPolicyList != null && newPolicyList.size() > 0) {
				for (Policy__c poli : newPolicyList) {
					if (dmlUpdateErrorsMap.containsKey(poli.Opportunity__c)) {
						poli.addError(dmlUpdateErrorsMap.get(poli.Opportunity__c));
					}
				}
			} else if (oldPolicyMap != null && oldPolicyMap.keyset().size() > 0) {
				for (Policy__c poli : oldPolicyMap.values()) {
					if (dmlUpdateErrorsMap.containsKey(poli.Opportunity__c)) {
						poli.addError(dmlUpdateErrorsMap.get(poli.Opportunity__c));
					}
				}
			}
		}
	}

	/*
	 *   By : Robin Grover, April 27, 2017
	 *   Introduced this method to udpate the Carrier Order's text field "Benefit Types"
	 *   with all the unique benefit types when a child Policy__c object record trigger a DML operation.
	 *
	 */
	public static void updateRelatedCarrierOrdrBenefitTypes(list<Policy__c> newPolicyList, map<id, Policy__c> oldPolicyMap) {
		Set<Id> carrierOrderIdSet = new Set<Id>();
		Set<Id> oppIdSet = new Set<Id>();
		List<Policy__c> policies = new List<Policy__c>();
		List<Carrier_Order__c> list_CarrierOrdersForUpdate = new List<Carrier_Order__c>();
		Map<String, List<Policy__c>> mapOppCarrierToPol = new Map<String, List<Policy__c>>();
		Set<String> set_RenewingTadaOpps = new Set<String>();

		if (oldPolicyMap == null || oldPolicyMap.keyset().size() == 0) {
			policies = newPolicyList;
		}
		if (newPolicyList == null || newPolicyList.size() == 0) {
			policies = oldPolicyMap.values();
		}
		if (oldPolicyMap != null && oldPolicyMap.keyset().size() > 0 && newPolicyList != null) {
			for (Policy__c policy : newPolicyList) {
				Policy__c oldPolicy = oldPolicyMap.get(policy.Id);
				if (
					(oldPolicy.Benefit_Type__c != policy.Benefit_Type__c ||
					oldPolicy.Carrier__c != policy.Carrier__c ||
					oldPolicy.Opportunity__c != policy.Opportunity__c ||
					oldPolicy.Is_Selected__c != policy.Is_Selected__c ||
					oldPolicy.Carrier_Order__c != policy.Carrier_Order__c ||
					oldPolicy.Group_Number__c != policy.Group_Number__c) && policy.Opportunity__c != null
				) {
					oppIdSet.add(policy.Opportunity__c);
				}
			}
		}

		if (newPolicyList != null) {
			for (Policy__c policy : newPolicyList) {
				if (policy.Opportunity__c != null) {
					oppIdSet.add(policy.Opportunity__c);
				} else {
					continue;
				}
			}
		} else {
			for (Policy__c policy : oldPolicyMap.values()) {
				if (policy.Opportunity__c != null) {
					oppIdSet.add(policy.Opportunity__c);
				} else {
					continue;
				}
			}
		}

		Set<Id> oppIdSetForCarrierOrder = new Set<Id>();
		for (Policy__c objPol : [
			SELECT Id, Opportunity__c, Opportunity__r.RecordType.Name, Benefit_Type__c, Carrier__c, Carrier_Order__r.Order_Type__c, Is_Selected__c, Group_Number__c
			FROM Policy__c
			WHERE Benefit_Type__c != NULL AND Opportunity__c != NULL AND Opportunity__c IN :oppIdSet AND Is_Selected__c = TRUE
		]) {
			String strOrderType = '';
			if (objPol.Carrier_Order__r.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE || objPol.Carrier_Order__r.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
				strOrderType = objPol.Carrier_Order__r.Order_Type__c;
				if(objPol.Opportunity__r.RecordType.Name == CarrierOrderUtil.OPP_BENEFITS_RENEWAL && objPol.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_HSA) {
					oppIdSetForCarrierOrder.add(objPol.Opportunity__c);
				}
			}

			if (mapOppCarrierToPol.containsKey(objPol.Opportunity__c + 'ADD' + objPol.Carrier__c + strOrderType)) {
				List<Policy__c> tmpList = mapOppCarrierToPol.get(objPol.Opportunity__c + 'ADD' + objPol.Carrier__c + strOrderType);
				tmpList.add(objPol);
				mapOppCarrierToPol.put(objPol.Opportunity__c + 'ADD' + objPol.Carrier__c + strOrderType, tmpList);
			} else {
				mapOppCarrierToPol.put(objPol.Opportunity__c + 'ADD' + objPol.Carrier__c + strOrderType, new List<Policy__c>{ objPol });
			}
		}

		if(!oppIdSetForCarrierOrder.isEmpty()){
			for (QA_Sheet__c objQA : [
				SELECT
					Id, 
					Name, 
					Renewing_TAdAs__c,
					Opportunity__c	
				FROM QA_Sheet__c
				WHERE Opportunity__c IN :oppIdSetForCarrierOrder and Renewing_TAdAs__c != null
			]) {
				if(objQA.Renewing_TAdAs__c.contains(CarrierOrderUtil.TADA_BEN_TYPE_HSA)) {
					set_RenewingTadaOpps.add(objQA.Opportunity__c);
				}
			}
		}

		for (Carrier_Order__c carrrierOrdr : [
			SELECT Id, Benefit_Types__c, Benefit_Order__r.Opportunity__c, Benefit_Order__r.Order_Status__c, Carrier__c, Order_Type__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Opportunity__c != NULL AND Benefit_Order__r.Opportunity__c IN :oppIdSet
			AND Order_Assignment__c != 'Terminated Order'
			FOR UPDATE
		]) {
			String strOrderType = '';
			if (carrrierOrdr.Order_Type__c == 'TAdA: No Pre OE Setup' || carrrierOrdr.Order_Type__c == 'TAdA: Pre OE Setup') {
				strOrderType = carrrierOrdr.Order_Type__c;
			}

			String key = carrrierOrdr.Benefit_Order__r.Opportunity__c + 'ADD' + carrrierOrdr.Carrier__c + strOrderType;
			Integer totalSelectedPolicyCount = 0;

			if (mapOppCarrierToPol.containsKey(key)) {
				for (Policy__c poli : mapOppCarrierToPol.get(key)) {
					if(!set_RenewingTadaOpps.isEmpty() && set_RenewingTadaOpps.contains(carrrierOrdr.Benefit_Order__r.Opportunity__c) && 
						poli.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_HSA) {
						continue;
					}
					totalSelectedPolicyCount++;
					if (carrrierOrdr.Benefit_Types__c != null && carrrierOrdr.Benefit_Types__c.length() > 0) {
						if (carrrierOrdr.Benefit_Types__c.IndexOf(poli.Benefit_Type__c) == -1) {
							carrrierOrdr.Benefit_Types__c += '; ' + poli.Benefit_Type__c;
						}
					} else {
						carrrierOrdr.Benefit_Types__c = poli.Benefit_Type__c;
					}
					carrrierOrdr.Group_Number__c = poli.Group_Number__c; //@Neha Sept 14,2020, for copying Group Number from Policy to Carrier Order
				}
			}
			
			if (carrrierOrdr.Benefit_Order__r.Order_Status__c != BenefitOrderUtil.STATUS_FULFILLED) {
				list_CarrierOrdersForUpdate.add(carrrierOrdr);
			}
		}

		if (list_CarrierOrdersForUpdate.size() > 0) {
			try {
				update list_CarrierOrdersForUpdate;
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'PolicyHelper',
					'updateRelatedCarrierOrdrBenefitTypes',
					'Exception On Line ' +
					objException.getLineNumber() +
					'-' +
					objException.getMessage(),
					objException.getStackTraceString()
				);
			}
		}

		if (set_BenefitOrders.size() > 0) {
			try {
				List<Benefit_Order__c> list_BOsToUpdate = new List<Benefit_Order__c>();
				list_BOsToUpdate.addAll(set_BenefitOrders);
				update list_BOsToUpdate;
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'PolicyHelper',
					'updateRelatedCarrierOrdrBenefitTypes',
					'Exception On Line ' +
					objException.getLineNumber() +
					'-' +
					objException.getMessage(),
					objException.getStackTraceString()
				);
			}
		}
	}

	/**
	 *	 Ticket : Complexity Score
	 *   Description : Using the method to roll up "Complexity Score" from "Carrier Complexity Order" to "Policy"
	 *                   based on "Benefit Type"
	 */
	public static void populateComplexityScore(list<Policy__c> newPolicyList, map<id, Policy__c> oldPolicyMap) {
		set<string> carrierIdSet = new Set<string>();
		set<string> benefitTypeSet = new Set<string>();

		string renewalBORecordTypeId = Schema.SObjectType.Benefit_Order__c.getRecordTypeInfosByName().get(BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL).getRecordTypeId();

		set<string> carrierOrderIdSet = new Set<string>();

		for (Policy__c policy : newPolicyList) {
			if (!policy.Is_Selected__c) {
				continue;
			}

			/*
                Date : 08/30/17
                Description : Calculate Complexity only when Carrier Order is assigned to the Policy Record.
            */
			if (policy.Carrier_Order__c == null) {
				continue;
			}
			carrierOrderIdSet.add(policy.Carrier_Order__c);
		}

		map<id, Carrier_Order__c> carrierOrderIdRecordMap = new Map<id, Carrier_Order__c>();

		if (carrierOrderIdSet.size() > 0) {
			carrierOrderIdRecordMap = new Map<id, Carrier_Order__c>([SELECT id, Benefit_Order__r.RecordTypeId, Benefit_Order__c FROM Carrier_Order__c WHERE Id IN :carrierOrderIdSet]);
		}

		Map<Id, Benefit_Order__c> benefitOrdermap = new Map<Id, Benefit_Order__c>();
		for (Policy__c policy : newPolicyList) {
			Policy__c oldPolicy = null;

			if (oldPolicyMap != null) {
				oldPolicy = oldPolicyMap.get(policy.id);
				if (policy.Request_Type__c != oldPolicy.Request_Type__c && carrierOrderIdRecordMap.containsKey(policy.Carrier_Order__c)) {
					Carrier_Order__c carOrd = carrierOrderIdRecordMap.get(policy.Carrier_Order__c);
					if (carOrd.Benefit_Order__c != null) {
						Benefit_Order__c benOrd = new Benefit_Order__c(Id = carOrd.Benefit_Order__c);
						benefitOrdermap.put(carOrd.Benefit_Order__c, benOrd);
					}
				}
			} else {
				if (policy.Request_Type__c != null && carrierOrderIdRecordMap.containsKey(policy.Carrier_Order__c)) {
					Carrier_Order__c carOrd = carrierOrderIdRecordMap.get(policy.Carrier_Order__c);
					if (carOrd.Benefit_Order__c != null) {
						Benefit_Order__c benOrd = new Benefit_Order__c(Id = carOrd.Benefit_Order__c);
						benefitOrdermap.put(carOrd.Benefit_Order__c, benOrd);
					}
				}
			}

			if (benefitOrdermap.keyset().size() > 0 && benefitOrdermap != null) {
				for (Benefit_Order__c BO : benefitOrdermap.values()) {
					// SJay - 10-13-2020 - Replaced list with set to avoid duplicates.
					set_BenefitOrders.add(BO);
				}
			}
		}
	}
	
	public static void policyHandlerBuilder(list<Policy__c> newPolicyList, map<id, Policy__c> oldPolicyMap) {
		if (newPolicyList == null) {
			return;
		}
		for (Policy__c policyRecord : newPolicyList) {
			if (oldPolicyMap != null && oldPolicyMap.get(policyRecord.Id).Benefit_Type__c != policyRecord.Benefit_Type__c) {
				policyRecord.Dental__c = false;
				policyRecord.Medical__c = false;
				policyRecord.Vision__c = false;
				if (policyRecord.Benefit_Type__c == 'Medical') {
					policyRecord.Medical__c = true;
				}
				if (policyRecord.Benefit_Type__c == 'Dental') {
					policyRecord.Dental__c = true;
				}
				if (policyRecord.Benefit_Type__c == 'Vision') {
					policyRecord.Vision__c = true;
				}
			}
		}
	}

	public static void isPolicyInsertedOnCarrierOrder(list<Policy__c> newPolicyList, map<id, Policy__c> oldPolicyMap) {
		if (newPolicyList == null) {
			return;
		}

		List<Benefit_Order__c> benefitOrderToUpdate = new List<Benefit_Order__c>();
		Set<Id> idSet = new Set<Id>();
		Map<Id, Carrier_Order__c> coMap = new Map<Id, Carrier_Order__c>();
		List<Policy__c> policyToUpdate = new List<Policy__c>();

		if (oldPolicyMap == null) {
			for (Policy__c policyRecord : newPolicyList) {
				if (policyRecord.Carrier_Order__c != null && policyRecord.Is_Selected__c && policyRecord.Coverage_Effective_Date__c != null) {
					idSet.add(policyRecord.Carrier_Order__c);
				}
			}

			if (idSet != null && idSet.size() > 0) {
				for (Carrier_Order__c coObj : [SELECT Id, Benefit_Order__c, Benefit_Order__r.Coverage_Effective_Date__c FROM Carrier_Order__c WHERE Id IN :idSet]) {
					coMap.put(coObj.Id, coObj);
				}

				for (Policy__c policyRec : newPolicyList) {
					if (
						coMap != null &&
						coMap.containsKey(policyRec.Carrier_Order__c) &&
						coMap.get(policyRec.Carrier_Order__c).Benefit_Order__c != null &&
						coMap.get(policyRec.Carrier_Order__c).Benefit_Order__r.Coverage_Effective_Date__c == null
					) {
						coMap.get(policyRec.Carrier_Order__c).Benefit_Order__r.Coverage_Effective_Date__c = policyRec.Coverage_Effective_Date__c;
						benefitOrderToUpdate.add(coMap.get(policyRec.Carrier_Order__c).Benefit_Order__r);
					} else {
						if (
							coMap != null &&
							coMap.containsKey(policyRec.Carrier_Order__c) &&
							coMap.get(policyRec.Carrier_Order__c).Benefit_Order__c != null &&
							coMap.get(policyRec.Carrier_Order__c).Benefit_Order__r.Coverage_Effective_Date__c != null
						) {
							policyRec.Coverage_Effective_Date__c = coMap.get(policyRec.Carrier_Order__c).Benefit_Order__r.Coverage_Effective_Date__c;
						}
					}
				}
			}
		}
		if (benefitOrderToUpdate.size() > 0 && benefitOrderToUpdate != null) {
			boolean boSkipTrigger = BenefitOrderHelper.skipTrigger;
			BenefitOrderHelper.skipTrigger = true;
			update benefitOrderToUpdate;
			BenefitOrderHelper.skipTrigger = boSkipTrigger;
		}
	}

	public static void isPolicySelected(List<Policy__c> newPolicyListMap, map<id, Policy__c> oldPolicyMap, String context) {
		if (newPolicyListMap == null) {
			return;
		}
		set<Id> carrierIds = new Set<Id>();
		set<Id> oppIds = new Set<Id>();
		Boolean blnRenewalBenfitOrder = false;
		for (Policy__c pl : newPolicyListMap) {
			if ((oldPolicyMap == null || oldPolicyMap.get(pl.Id).Is_Selected__c != pl.Is_Selected__c) && pl.Is_Selected__c && string.isBlank(pl.Carrier_Order__c) && pl.Opportunity__c != null) {
				oppIds.add(pl.Opportunity__c);
			}
			if (pl.Carrier__c != null) {
				carrierIds.add(pl.Carrier__c);
			}
		}

		map<Id, Carrier__c> carrierMap = new Map<Id, Carrier__c>();
		if (carrierIds.size() > 0) {
			for (Carrier__c car : [SELECT id, Name FROM Carrier__c WHERE id IN :carrierIds]) {
				carrierMap.put(car.Id, car);
			}
		}
		Set<string> set_OrderStatus = new Set<String>{ 'Fulfilled', 'Closed Admin', 'Canceled', 'Closed Lost' };
		Map<Id, Benefit_Order__c> map_BenefitOrders = new Map<Id, Benefit_Order__c>();
		for (Benefit_Order__c objBO : [
			SELECT
				Account__r.Name,
				Id,
				RecordType.Name,
				opportunity__c,
				Opportunity__r.RecordType.Name,
				Opportunity__r.Order_Generated__c,
				Is_Multi_EIN__c,
				(SELECT id, Carrier__c, Benefit_Types__c, Order_Type__c, Recordtype.Name, Implementation_Stage__c FROM Carrier_Orders__r)
			FROM Benefit_Order__c
			WHERE opportunity__c IN :oppIds AND Opportunity__r.Order_Generated__c = TRUE AND RecordType.Name != 'Renewal Alignment' AND Order_Status__c NOT IN :set_OrderStatus
		]) {
			map_BenefitOrders.put(objBO.Opportunity__c, objBO);
		}

		list<Carrier_Order__c> newLyCreatedCarrierorders = new List<Carrier_Order__c>();
		Map<String, Carrier_Order__c> map_NewLyCreatedCarrierOrders = new Map<String, Carrier_Order__c>();
		list<Policy__c> updatepolicies = new List<Policy__c>();
		map<String, Policy__c> carrierIdPolicyMap = new Map<String, Policy__c>();

		/*
		 * Update by:- Deepika Saini
		 * Reason:- Non Tada Benefit set for assigning Order type and Order Assignment
		 */
		Set<String> set_NonTadaBenefitType = new Set<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'Long Term Disability', 'Short Term Disability' };
		Map<String, Map<String, QA_Lines_Of_Coverage__c>> map_OppIdQALinesOfCoverageMap = new Map<String, Map<String, QA_Lines_Of_Coverage__c>>();
		
		for (Policy__c objPolicy : newPolicyListMap) {
			if (!objPolicy.is_Selected__c) {
				continue;
			}
			
			if ((oldPolicyMap == null || oldPolicyMap.get(objPolicy.Id).Is_Selected__c != objPolicy.Is_Selected__c) && objPolicy.Is_Selected__c && string.isBlank(objPolicy.Carrier_Order__c) && objPolicy.Opportunity__c != null) {
				if (map_BenefitOrders.containsKey(objPolicy.Opportunity__c)) {
					Benefit_Order__c objbo = map_BenefitOrders.get(objPolicy.Opportunity__c);
					if(
						objPolicy.Benefit_Type__c != null &&
						objbo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL
					){
						blnRenewalBenfitOrder = true;
						break;
					}
				}
			}
		}
		
		Set<String> set_EarlySubmissionRequired = new Set<String>();
		if(blnRenewalBenfitOrder && !map_BenefitOrders.isEmpty()){
			map_OppIdQALinesOfCoverageMap = fetchQALinesOfCoverageMap(map_BenefitOrders.keySet(), set_EarlySubmissionRequired);
		}

		for (Policy__c pl : newPolicyListMap) {
			if (!pl.is_Selected__c)
				continue;

			if (!map_OppIdQALinesOfCoverageMap.isEmpty() && map_OppIdQALinesOfCoverageMap.containsKey(pl.Opportunity__c)) {
				Map<String,QA_Lines_Of_Coverage__c> map_QALinesOfCoverage = map_OppIdQALinesOfCoverageMap.get(pl.Opportunity__c);
				if (map_QALinesOfCoverage.values().size() > 0) {
					List<QA_Lines_Of_Coverage__c> list_QALinesOfCoverage = map_QALinesOfCoverage.values();
					if(list_QALinesOfCoverage.size() > 0 && pl.Benefit_Type__c == 'HSA' &&
						list_QALinesOfCoverage[0].QA_Sheet__r.Renewing_TAdAs__c != null && 
						list_QALinesOfCoverage[0].QA_Sheet__r.Renewing_TAdAs__c.contains('HSA')){
						continue;
					}
				}
			}

			if (map_BenefitOrders.containsKey(pl.Opportunity__c)) {
				Benefit_Order__c bo = map_BenefitOrders.get(pl.Opportunity__c);
				boolean foundMatchingCo = false;
				Boolean blnCarrierSwitch = false;
				if (bo.Carrier_Orders__r != null && bo.Carrier_Orders__r.size() > 0) {
					for (Carrier_Order__c co : bo.Carrier_Orders__r) {
						Boolean isCarrierOrderAlreadyExist = false;

						if (pl.Benefit_Type__c != null && pl.Benefit_Type__c == co.Benefit_Types__c && co.Implementation_Stage__c == CarrierOrderUtil.STAGE_CANCELLED && co.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_CARRIER_SWITCH) {
							blnCarrierSwitch = true;
							set_COSwitchIds.add(co.Id);
						}

						if (co.Carrier__c != null && co.Carrier__c == pl.Carrier__c) {
							if (
								(bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN ||
								bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_CHANGE ||
								bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL)
							) {
								//Check for the HSA or Commuter Benefit type of policy as well as in carrier Order Benefit types
								if (
									pl.Benefit_Type__c != null &&
									(pl.Benefit_Type__c == 'HSA' ||
									pl.Benefit_Type__c == 'Commuter') &&
									co.Benefit_Types__c != null &&
									(co.Benefit_Types__c.contains('HSA') || co.Benefit_Types__c.contains('Commuter'))
								) {
									isCarrierOrderAlreadyExist = true;
								} else if (
									pl.Benefit_Type__c != null &&
									(pl.Benefit_Type__c == 'Flexible Spending Account - Medical' ||
									pl.Benefit_Type__c == 'Flexible Spending Account - Dependent Care') &&
									co.Benefit_Types__c != null &&
									(co.Benefit_Types__c.contains('Flexible Spending Account - Medical') || co.Benefit_Types__c.contains('Flexible Spending Account - Dependent Care'))
								) {
									//Check for the FSA or DCA Benefit type of policy as well as in carrier Order Benefit types
									isCarrierOrderAlreadyExist = true;
								} else if (
									pl.Benefit_Type__c != null &&
									pl.Benefit_Type__c != 'Flexible Spending Account - Medical' &&
									pl.Benefit_Type__c != 'Flexible Spending Account - Dependent Care' &&
									pl.Benefit_Type__c != 'HSA' &&
									pl.Benefit_Type__c != 'Commuter'
								) {
									//Check for the non tada Benefit type of policy as well as in carrier Order Benefit types
									isCarrierOrderAlreadyExist = true;
								}
							}
							if (isCarrierOrderAlreadyExist) {
								if (context == 'insert') {
									updatepolicies.add(new Policy__c(Id = pl.Id, Carrier_Order__c = co.Id));
								} else
									pl.Carrier_Order__c = co.Id;
								foundMatchingCo = true;
								break;
							}
						}
					}
				}
				if (!foundMatchingCo) {
					String strUniqueIdField = bo.Id + '-' + pl.Carrier__c;
					string coRT = '';
					if (bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL) {
						coRT = Cache.getRecordTypeId('Carrier_Order__c', CarrierOrderUtil.RECTYPE_NAME_RENEWAL);
						if (pl.Benefit_Type__c == 'HSA' || pl.Benefit_Type__c == 'Commuter') {
							strUniqueIdField += '-InitialTadaSetup';
						}
					} else if (bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN) {
						coRT = Cache.getRecordTypeId('Carrier_Order__c', CarrierOrderUtil.RECTYPE_NAME_NEW_PLAN);
						if (pl.Benefit_Type__c == 'HSA' || pl.Benefit_Type__c == 'Commuter') {
							strUniqueIdField += '-InitialTadaSetup';
						}
					} else if (bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_CHANGE) {
						coRT = Cache.getRecordTypeId('Carrier_Order__c', CarrierOrderUtil.RECTYPE_NAME_BENEFIT_CHANGE);
						if (pl.Benefit_Type__c == 'HSA' || pl.Benefit_Type__c == 'Commuter') {
							strUniqueIdField += '-InitialTadaSetup';
						}
					}
					//DS[26-11-2019] Added check for the Carrier Order Name
					String coName = bo.Account__r.Name + ' ' + carrierMap.get(pl.Carrier__c).Name + ' ' + 'Order';
					if (coName.length() > 80) {
						coName = carrierMap.get(pl.Carrier__c).Name + ' ' + 'Order';
						coName = coName.left(80);
					}
					System.debug(bo.Id + ' pl.Carrier__c' +  pl.Carrier__c + ' strUniqueIdField' +  strUniqueIdField+ 'coRT ' +  coRT+ 'coName ' +  coName+ ' pl.Group_Number__c' +  pl.Group_Number__c + ' Label.Carrier_Implementation_Queue' + Label.Carrier_Implementation_Queue);
					Carrier_Order__c objCO = new Carrier_Order__c(
						Benefit_Order__c = bo.Id,
						Carrier__c = pl.Carrier__c,
						Unique_id__c = strUniqueIdField,
						RecordTypeId = coRT,
						Name = coName,
						Group_Number__c = pl.Group_Number__c,
						OwnerId = Label.Carrier_Implementation_Queue
					);
					/*
					 * Update by:- Deepika Saini
					 * Reason:- Update Order type and Order Assignment
					 */
					if (objCO != null) {
						if (pl.Benefit_Type__c != null && (bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN || pl.Opportunity__r.RecordType.Name == TransitiontoFulfilmentUtil.BENEFITS_NEW_PLAN)) {
							if (set_NonTadaBenefitType.contains(pl.Benefit_Type__c)) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_NEW_TO_GUSTO;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_NEW_TO_GUSTO;
							} else if (pl.Benefit_Type__c == TransitiontoFulfilmentUtil.HSA || pl.Benefit_Type__c == TransitiontoFulfilmentUtil.COMMUTER) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP;
							} else if (pl.Benefit_Type__c == TransitiontoFulfilmentUtil.FLEXIBLE_SPENDING_ACCOUNT_MEDICAL || pl.Benefit_Type__c == TransitiontoFulfilmentUtil.FLEXIBLE_SPENDING_ACCOUNT_DEPENDENT_CARE) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_NO_PRE_OE_SETUP;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_NO_PRE_OE_SETUP;
							}
						} else if (
							pl.Benefit_Type__c != null &&
							(bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_CHANGE ||
							pl.Opportunity__r.RecordType.Name == TransitiontoFulfilmentUtil.BENEFITS_CHANGE)
						) {
							if (set_NonTadaBenefitType.contains(pl.Benefit_Type__c)) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE;
							} else if (pl.Benefit_Type__c == TransitiontoFulfilmentUtil.HSA || pl.Benefit_Type__c == TransitiontoFulfilmentUtil.COMMUTER) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP;
							} else if (pl.Benefit_Type__c == TransitiontoFulfilmentUtil.FLEXIBLE_SPENDING_ACCOUNT_MEDICAL || pl.Benefit_Type__c == TransitiontoFulfilmentUtil.FLEXIBLE_SPENDING_ACCOUNT_DEPENDENT_CARE) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_NO_PRE_OE_SETUP;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_NO_PRE_OE_SETUP;
							}
						}
						else if (
							pl.Benefit_Type__c != null &&
							bo.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL
						) {
							if (set_NonTadaBenefitType.contains(pl.Benefit_Type__c)) {
								if (!map_OppIdQALinesOfCoverageMap.isEmpty() && map_OppIdQALinesOfCoverageMap.containsKey(bo.Opportunity__c)) {
									Map<String,QA_Lines_Of_Coverage__c> map_QALinesOfCoverage = map_OppIdQALinesOfCoverageMap.get(bo.Opportunity__c);
									List<String> list_BenefitType = new List<String>();
									CarrierOrderHelperFunctions objCOUtilClass = new CarrierOrderHelperFunctions();
									if(pl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_MEDICAL){
										list_BenefitType = TransitiontoFulfilmentUtil.getOrderTypeforMedical(pl.Benefit_Type__c, map_QALinesOfCoverage);
									}else if(pl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_DENTAL){
										list_BenefitType = TransitiontoFulfilmentUtil.getOrderTypeforDental(pl.Benefit_Type__c, map_QALinesOfCoverage);
									}else if(pl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_VISION){
										list_BenefitType = TransitiontoFulfilmentUtil.getOrderTypeforVision(pl.Benefit_Type__c, map_QALinesOfCoverage);
									}else if(pl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_LIFE){
										list_BenefitType = TransitiontoFulfilmentUtil.getOrderTypeforLifeInsurance(pl.Benefit_Type__c, map_QALinesOfCoverage);
									}else if(pl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_LTD){
										list_BenefitType = TransitiontoFulfilmentUtil.getOrderTypeforLTD(pl.Benefit_Type__c, map_QALinesOfCoverage);
									}else if(pl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_STD){
										list_BenefitType = TransitiontoFulfilmentUtil.getOrderTypeforSTD(pl.Benefit_Type__c, map_QALinesOfCoverage);
									}
									if(!list_BenefitType.isEmpty()){
										objCO.Order_Type__c = String.join(list_BenefitType, ';');
										objCO.Order_Assignment__c = objCOUtilClass.calculateOrderAssignmentForCO(objCO);
									}
								}
							} else if (pl.Benefit_Type__c == TransitiontoFulfilmentUtil.HSA || pl.Benefit_Type__c == TransitiontoFulfilmentUtil.COMMUTER) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP;
							} else if (pl.Benefit_Type__c == TransitiontoFulfilmentUtil.FLEXIBLE_SPENDING_ACCOUNT_MEDICAL || pl.Benefit_Type__c == TransitiontoFulfilmentUtil.FLEXIBLE_SPENDING_ACCOUNT_DEPENDENT_CARE) {
								objCO.Order_Type__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_NO_PRE_OE_SETUP;
								objCO.Order_Assignment__c = TransitiontoFulfilmentUtil.CO_ORDER_TYPE_TADA_NO_PRE_OE_SETUP;
							}
						}
						if (objCO.Carrier__c != null && objCO.Benefit_Order__c != null) {
							if (objCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
								objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
							}
							if ((objCO.RecordTypeId == CARRIER_ORDER_RENEWAL_RT || objCO.RecordTypeId == CARRIER_ORDER_NEW_PLAN_RT || objCO.RecordTypeId == CARRIER_ORDER_CHANGE_RT)
								&& String.isNotBlank(objCO.Order_Type__c) && objCO.Order_Type__c != CarrierOrderUtil.ORDER_TYPE_TERMINATED_ORDER && objCO.Order_Type__c != CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
								objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP;
							}
							if(!set_EarlySubmissionRequired.isEmpty() && set_EarlySubmissionRequired.contains(bo.Opportunity__c + '-' + objCO.Carrier__c)) {
								objCO.Implementation_Stage__c = CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION;
							}
						}

						//if BO is part of multi EIN then update the carrier Order as MultiEIN also.
						if (bo.Is_Multi_EIN__c) {
							objCO.Is_Multi_EIN__c = bo.Is_Multi_EIN__c;
						}
					}
					map_NewLyCreatedCarrierOrders.put(strUniqueIdField, objCO);
					carrierIdPolicyMap.put(strUniqueIdField, pl);
				}
			}
		}
		

		if (!map_NewLyCreatedCarrierOrders.isEmpty()) {
			newLyCreatedCarrierorders = map_NewLyCreatedCarrierOrders.Values();
		}

		if (newLyCreatedCarrierorders.size() > 0 || updatepolicies.size() > 0) {
			if (newLyCreatedCarrierorders.size() > 0) {
				upsert newLyCreatedCarrierorders Unique_Id__c;
			}
			if (context == 'insert') {
				list<Policy__c> updatedPolicies = new List<Policy__c>();
				for (Carrier_Order__c co : newLyCreatedCarrierorders) {
					String strUniqueIdField;
					strUniqueIdField = co.Benefit_Order__c + '-' + co.Carrier__c;
					if (
						co.Benefit_Types__c != null &&
						(co.Benefit_Types__c.contains('HSA') || co.Benefit_Types__c.contains('Commuter')) &&
						(co.RecordType.Name == CarrierOrderUtil.RECTYPE_NAME_NEW_PLAN ||
						co.RecordType.Name == CarrierOrderUtil.RECTYPE_NAME_BENEFIT_CHANGE)
					) {
						strUniqueIdField += '-InitialTadaSetup';
					}
					if (carrierIdPolicyMap.containsKey(strUniqueIdField)) {
						updatedPolicies.add(new Policy__c(Id = carrierIdPolicyMap.get(strUniqueIdField).Id, carrier_order__c = co.Id));
					}
				}
				set<Policy__c> policySet = new Set<Policy__c>();
				if (updatedPolicies.size() > 0) {
					policySet.addAll(updatedPolicies);
				}

				if (updatepolicies.size() > 0) {
					policySet.addAll(updatepolicies);
				}

				if (policySet.size() > 0) {
					updatedPolicies = new List<Policy__c>();
					updatedPolicies.addAll(policySet);
					boolean boSkipTrigger = PolicyHelper.skipTrigger;

					PolicyHelper.skipTrigger = true;
					update updatedPolicies;
					PolicyHelper.skipTrigger = boSkipTrigger;
				}
			} else {
				for (Carrier_Order__c co : newLyCreatedCarrierorders) {
					String strUniqueIdField;
					strUniqueIdField = co.Benefit_Order__c + '-' + co.Carrier__c;
					if (
						co.Benefit_Types__c != null &&
						(co.Benefit_Types__c.contains('HSA') || co.Benefit_Types__c.contains('Commuter')) &&
						(co.RecordType.Name == CarrierOrderUtil.RECTYPE_NAME_NEW_PLAN ||
						co.RecordType.Name == CarrierOrderUtil.RECTYPE_NAME_BENEFIT_CHANGE)
					) {
						strUniqueIdField += '-InitialTadaSetup';
					}
					if (carrierIdPolicyMap.containsKey(strUniqueIdField)) {
						carrierIdPolicyMap.get(strUniqueIdField).carrier_order__c = co.Id;
					}
				}
			}
		}
	}

	/**
	 * Updates the carrier order to canceled if the last carrer is unselected
	 */
	public static void removePoliciesFromCarrierOrder(list<Policy__c> newPolicyList, map<id, Policy__c> oldPolicyMap) {
		Set<Id> unSelectedPolicyIds = new Set<Id>();
		Set<Id> oppIdSet = new Set<Id>();
		for (Policy__c policyRec : newPolicyList) {
			if (policyRec.Opportunity__c != null) {
				oppIdSet.add(policyRec.Opportunity__c);
			}
			if (oldPolicyMap.get(policyRec.Id).Is_Selected__c != policyRec.Is_Selected__c && policyRec.Is_Selected__c != true && policyRec.Carrier_Order__c != null) {
				unSelectedPolicyIds.add(policyRec.Id);
			}
		}
		map<id, List<Policy__c>> oppPolicyMap = new Map<id, List<Policy__c>>();
		if (oppIdSet.size() > 0) {
			oppPolicyMap = PolicyTriggerHelperFunctions.getSelectedPoliciesByOpportunityId(oppIdSet);
		}

		Set<id> carrerOrderIdForUpdateSet = new Set<id>();
		for (Policy__c policyRec : newPolicyList) {
			if (oldPolicyMap.get(policyRec.Id).Is_Selected__c != policyRec.Is_Selected__c && policyRec.Is_Selected__c != true && unSelectedPolicyIds.contains(policyRec.id)) {
				if (policyRec.Opportunity__c != null && oppPolicyMap.containsKey(policyRec.Opportunity__c)) {
					List<Policy__c> oppPolicyList = oppPolicyMap.get(policyRec.Opportunity__c);
					boolean anotherOrderExists = false;

					for (Policy__c pol : oppPolicyList) {
						if (pol.Carrier__c == policyRec.Carrier__c && !unSelectedPolicyIds.contains(pol.Id) && policyRec.id != pol.Id) {
							anotherOrderExists = true;
						}
					}

					if (anotherOrderExists == false) {
						carrerOrderIdForUpdateSet.add(policyRec.Carrier_Order__c);
					}
				}
				policyRec.Carrier_Order__c = null;
			}
		}
	}

	public static void updateCOrderonPolicy(List<Policy__c> newPolicyList) {
		Map<Id, Carrier_Order__c> map_COWithIds = new Map<Id, Carrier_Order__c>();
		List<Carrier_Order__c> list_ReopenCOs = new List<Carrier_Order__c>();
		Set<Id> oppId = new Set<Id>();
		Set<Id> carrierId = new Set<Id>();
		Map<Id, Id> relatedBenefitOrderMap = new Map<Id, Id>();
		for (Policy__c policyRec : newPolicyList) {
			oppId.add(policyRec.Opportunity__c);
			carrierId.add(policyRec.Carrier__c);
		}
		for (Benefit_Order__c boRed : [
			SELECT ID, Opportunity__c
			FROM Benefit_Order__c
			WHERE Closed__c = FALSE AND Fulfilled__c = FALSE AND Type__c != 'Renewal Alignment' AND Opportunity__c IN :oppId
		]) {
			relatedBenefitOrderMap.put(boRed.Opportunity__c, boRed.Id);
		}
		Map<String, id> availableCOId = new Map<String, Id>();
		map<String, Id> tadaCarrierOrders = new Map<String, Id>();
		for (Carrier_Order__c coRec : [
			SELECT Carrier__c, Benefit_Order__c, Order_Type__c, Implementation_Stage__c, Benefit_Order__r.Opportunity__c
			FROM Carrier_Order__c
			WHERE Carrier__c IN :carrierId AND Benefit_Order__c IN :relatedBenefitOrderMap.Values()
		]) {
			if (coRec.Order_Type__c == 'TAdA: No Pre OE Setup' || coRec.Order_Type__c == 'TAdA: Pre OE Setup') {
				tadaCarrierOrders.put(coRec.Benefit_Order__r.Opportunity__c + '-' + coRec.Order_Type__c, coRec.Id);
			} else {
				availableCOId.put(coRec.Benefit_Order__c + '-' + coRec.Carrier__c, coRec.id);
			}
			map_COWithIds.put(coRec.id, coRec);
		}

		for (Policy__c policyRec : newPolicyList) {
			Id boId = null;
			if (policyRec.Opportunity__c != null)
				boId = relatedBenefitOrderMap.get(policyRec.Opportunity__c);

			if (policyRec.Benefit_Type__c == 'Flexible Spending Account - Medical' || policyRec.Benefit_Type__c == 'Flexible Spending Account - Dependent Care') {
				policyRec.Carrier_Order__c = tadaCarrierOrders.get(policyRec.Opportunity__c +  '-' + 'TAdA: No Pre OE Setup');
			} else if (policyRec.Benefit_Type__c == 'HSA' || policyRec.Benefit_Type__c == 'Commuter') {
				policyRec.Carrier_Order__c = tadaCarrierOrders.get(policyRec.Opportunity__c +  '-' + 'TAdA: Pre OE Setup');
			} else if (availableCOId.containsKey(boId + '-' + policyRec.Carrier__c)) {
				policyRec.Carrier_Order__c = availableCOId.get(boId + '-' + policyRec.Carrier__c);
			}

			if (policyRec.Is_Selected__c && policyRec.Carrier_Order__c != null && map_COWithIds.containsKey(policyRec.Carrier_Order__c)) {
				Carrier_Order__c objExistingCO =  map_COWithIds.get(policyRec.Carrier_Order__c);
				if (objExistingCO.Implementation_Stage__c == CarrierOrderUtil.STAGE_CANCELLED) {
					objExistingCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP;
					list_ReopenCOs.add(objExistingCO);
				}
			}
		}

		if (!list_ReopenCOs.isEmpty()) {
			CarrierOrderTriggerHelper.skipTrigger = true;
			update list_ReopenCOs;
			CarrierOrderTriggerHelper.skipTrigger = false;
		}
	}

	/**
	 * get Line Items for given Opportunities
	 */
	public static Map<Id, Opportunity> getOpportunityWithLineItems(Set<Id> oppIdSet) {
		List<Opportunity> newoppList = [
			SELECT
				Id,
				Name,
				AccountId,
				NumberOfEmployees__c,
				Locked__c,
				StageName,
				isClosed,
				isWon,
				RecordType.Name,
				Pricebook2Id,
				(SELECT Id, PriceBookEntryId, OpportunityId, UnitPrice, Quantity, Discount, Product2.Name FROM OpportunityLineItems)
			FROM Opportunity
			WHERE Id IN :oppIdSet
		];

		Map<Id, Opportunity> oppToLineItemsMap = new Map<Id, Opportunity>(newoppList);
		return oppToLineItemsMap;
	}

	/**
	 * get PriceBook Entry records for all pricebooks for product names passed to the method
	 */
	public static Map<String, PriceBookEntry> getPriceBookentryRecords(Set<String> prodNameSet) {
		Map<String, PricebookEntry> pbIdPlusProdNameToPBEntryMapTemp = new Map<String, PricebookEntry>();

		for (PricebookEntry pbe : [SELECT Id, UnitPrice, Product2.Name, PriceBook2Id FROM PriceBookEntry WHERE Product2.Name IN :prodNameSet]) {
			pbIdPlusProdNameToPBEntryMapTemp.put(pbe.PriceBook2Id + '-' + pbe.Product2.Name, pbe);
		}
		return pbIdPlusProdNameToPBEntryMapTemp;
	}
	
	public static void updateBOEffectiveDate(list<Policy__c> list_NewPolicy, map<id, Policy__c> map_OldPolicy, Boolean blnIsInsert) {
		if (list_NewPolicy == null) {
			return;
		}

		Map<Id, Policy__c> map_Policy = new Map<Id, Policy__c>();
		Map<Id, Carrier_Order__c> map_CarrierOrders = new Map<Id, Carrier_Order__c>();
		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();

		for (Policy__c objPolicy : list_NewPolicy) {
			if (
				(blnIsInsert || map_OldPolicy.get(objPolicy.Id).Carrier_Order__c != objPolicy.Carrier_Order__c) &&
				objPolicy.Carrier_Order__c != null &&
				objPolicy.Is_Selected__c &&
				objPolicy.Coverage_Effective_Date__c != null
			) {
				map_Policy.put(objPolicy.Carrier_Order__c, objPolicy);
			}
		}

		if (map_Policy != null && map_Policy.size() > 0) {
			Set<Id> set_COIds = map_Policy.keySet();
			String strQuery =
				'SELECT Id, Benefit_Order__c, Benefit_Order__r.Coverage_Effective_Date__c ' +
				'FROM Carrier_Order__c ' +
				'WHERE Id IN :set_COIds AND Benefit_Order__r.Coverage_Effective_Date__c = NULL ';
			if (!blnIsInsert) {
				strQuery += ' AND Benefit_Order__r.Closed__c = FALSE';
			}

			List<Carrier_Order__c> list_COs = Database.query(strQuery);
			for (Carrier_Order__c coObj : list_COs) {
				map_CarrierOrders.put(coObj.Id, coObj);
			}

			Id idBenefitOrder = null;
			Date dtCoverageEffectiveDate = null;
			Set<Id> set_BOIds = new Set<Id>();
			for (Policy__c objPolicy : list_NewPolicy) {
				if (map_CarrierOrders.containsKey(objPolicy.Carrier_Order__c)) {
					idBenefitOrder = map_CarrierOrders.get(objPolicy.Carrier_Order__c).Benefit_Order__c;
					if (set_BOIds.contains(idBenefitOrder)) {
						continue;
					}
					dtCoverageEffectiveDate = objPolicy.Coverage_Effective_Date__c;
					if (!blnIsInsert) {
						dtCoverageEffectiveDate = map_CarrierOrders.get(objPolicy.Carrier_Order__c).Benefit_Order__r.Coverage_Effective_Date__c;
					}
					list_BenefitOrders.add(new Benefit_Order__c(Id = idBenefitOrder, Coverage_Effective_Date__c = dtCoverageEffectiveDate));
					set_BOIds.add(idBenefitOrder);
				}
			}

			if (list_BenefitOrders.size() > 0) {
				update list_BenefitOrders;
			}
		}
	}

	/**
	 *@author      :Deepika Saini
	 *@description :fetch QA Line of Coverage for given Opportunities
	 *@param       :set_OpptyIds -set of Opportunity Ids
	 *@return      :map_OppIdQALinesOfCoverageMap - Map of Oportunity ids and Map of lineOfCoverage value and QA Line Of Coverages record
	 */
	private static Map<String, Map<String, QA_Lines_Of_Coverage__c>> fetchQALinesOfCoverageMap(Set<id> set_OpptyIds, Set<String> set_EarlySubmissionRequired) {
		Map<String, Map<String, QA_Lines_Of_Coverage__c>> map_OppIdQALinesOfCoverageMap = new Map<String, Map<String, QA_Lines_Of_Coverage__c>>();
		for (QA_Lines_Of_Coverage__c objLoC : [
			SELECT
				Lines_Of_Coverage__c,
				QA_Sheet__r.Benefit_Order__c,
				QA_Sheet__r.Renewing_TAdAs__c,
				Does_group_have_an_alignment__c,
				Rate_Change__c,
				New_Line_of_Coverage__c,
				New_Carrier__c,
				Waiting_Period_Change__c,
				Plan_changes__c,
				Contribution_change__c,
				Early_Submission_Required__c,
				Benefits_selected_Carrier__c,
				QA_Sheet__r.Opportunity__c
			FROM QA_Lines_Of_Coverage__c
			WHERE QA_Sheet__r.Opportunity__c IN :set_OpptyIds
		]) {
			Map<String, QA_Lines_Of_Coverage__c> map_QALineOfCoverage = new Map<String, QA_Lines_Of_Coverage__c>();
			if (!map_OppIdQALinesOfCoverageMap.isEmpty() && map_OppIdQALinesOfCoverageMap.containsKey(objLoC.QA_Sheet__r.Opportunity__c)) {
				map_QALineOfCoverage = map_OppIdQALinesOfCoverageMap.get(objLoC.QA_Sheet__r.Opportunity__c);
				map_QALineOfCoverage.put(objLoC.Lines_Of_Coverage__c, objLoC);
				map_OppIdQALinesOfCoverageMap.put(objLoC.QA_Sheet__r.Opportunity__c, map_QALineOfCoverage);
			} else {
				map_QALineOfCoverage.put(objLoC.Lines_Of_Coverage__c, objLoC);
				map_OppIdQALinesOfCoverageMap.put(objLoC.QA_Sheet__r.Opportunity__c, map_QALineOfCoverage);
			}
			if (objLoC.Early_Submission_Required__c) {
				set_EarlySubmissionRequired.add(objLoC.QA_Sheet__r.Opportunity__c + '-' + objLoC.Benefits_selected_Carrier__c);
			}
		}
		return map_OppIdQALinesOfCoverageMap;
	}
}