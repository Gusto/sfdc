/**
 * @description Central class that takes an Opportunity Id and finds all related records, such as Accounts, Line Items, and Product Discounts,
 * and recalculates all OLI discounts
 *
 * @author      David Schach
 * @since       Jan 2022
 * @see         AccountTriggerHandler
 * @see         AccountTriggerHelper
 * @see         OpportunityLineItemTriggerHandler
 * @see         OpportunityTriggerHelper
 * @see         ProductDiscountTest
 * @see         ProductDiscountTriggerHandler
 * @see         ZPAdjustmentTriggerHandler
 * @group       Product Discount
 */
public without sharing class ProductDiscountHelper {
	public static final Set<String> SET_VALID_GLOBAL_DISCOUNTS = new Set<String>{ 'accountant','wholesale_partner_discount'};
	public static final String WHOLESALE_PARTNER_DISCOUNT = 'wholesale_partner_discount';

	/**
	 * Unified place to generate the unique identifier for ProductDiscount (OpportunityId + Discount Type + ProductID [if present])
	 *
	 * @author David Schach
	 * @param  objPD `Product_Discount__c` record
	 * @return       Unique string
	 */
	public static String createProductDiscountUniqueId(Product_Discount__c objPD) {
		return '' + objPD.Opportunity__c + objPD.Discount_Type__c + (String.isNotBlank(objPD.ZP_Product_Id__c) ? objPD.ZP_Product_Id__c : '');
	}

	/**
	 * Given an OpportunityID, query all required fields and iterate over each Opportunity. Update all line items and allow their discounts to be handled
	 * in the OpportunityLineItem trigger handler.
	 * <br>This method updates the OpportunityLineItem records, and returns them so they can be updated in other contexts, or even used in a future method (if the Boolean is set to false)
	 *
	 * @author David Schach
	 * @param  setOpportunityIDs All impacted OpportunityIDs, collected via triggers on multiple other objects
	 * @return                   The OpportunityLineItem records that have been updated or will be updated
	 */
	public List<OpportunityLineItem> applyDiscountsToOLIs(Set<Id> setOpportunityIDs) {
		List<Opportunity> list_Opportunities = [
			SELECT Id, Sold_By__c, Sold_By__r.Discount__c, Account.Reward_Eligible__c, RecordTypeId, (SELECT Id, Discount, Product2Id, Product2.ExternalId FROM OpportunityLineItems)
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID AND Id IN :setOpportunityIDs
		];
		List<OpportunityLineItem> list_olisToUpdate = new List<OpportunityLineItem>();
		for (Opportunity objOpp : list_Opportunities) {
			list_olisToUpdate.addAll(objOpp.OpportunityLineItems);
		}
		TriggerHandler.bypass('OpportunityTriggerHandler');
		TriggerHandler.bypass('AccountTriggerHandler');
		update list_olisToUpdate;
		TriggerHandler.clearBypass('OpportunityTriggerHandler');
		TriggerHandler.clearBypass('AccountTriggerHandler');
		return list_olisToUpdate;
	}

	/**
	 * Given an Opportunity (already queried with proper fields) we store the criteria for creating an Accountant discount record in this central place
	 *                  <br>Is also called from OpportunityTriggerHelper to save a possible query on new Opportunity creation
	 *
	 * @author             David Schach
	 * @param objOppToEval Pass in the Opportunity to be considered
	 * @return             `Boolean` is this Opportunity eligible for a Product Discount?
	 */
	private static Boolean accountantDiscountEligible(Opportunity objOppToEval) {
		// Only opps with Sold-by populated and are Payroll opops are eligible
		if (objOppToEval.Sold_By__c == null || (Trigger.isExecuting && Trigger.isDelete)) {
			return false;
		} else if (objOppToEval.RecordTypeId != OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && objOppToEval.RecordTypeId != OpportunityUtil.COMPANY_OPPTY_RT_ID) {
			return false;
		} else if (objOppToEval.Account?.Reward_Eligible__c == false) {
			return false;
		} else if (objOppToEval.Sold_By__r?.Discount__c == null) {
			return false;
		} else if (objOppToEval.Sold_By__r?.Discount__c <= 0) {
			return false;
		}
		return true;
	}

	/**
	 * We can call this method from any trigger once we've collected OpportunityIDs and can update Accountant Product Discount records
	 * <br>Called from AccountTriggerHelper (change to Reward_Eligible or Partner Discount)
	 * <br>Called from OpportunityTriggerHelper
	 * @author David Schach
	 * @param  set_AccountIDs        Set of Accounts to recalculate Accountant discounts for
	 * @param  set_DeletedAccountIDs Deleted Accounts so we don't try to query for them
	 */
	public void handleAccountantProductDiscounts(Set<Id> set_AccountIDs, Set<Id> set_DeletedAccountIDs) {
		List<Product_Discount__c> list_ProductDiscountToUpsert = new List<Product_Discount__c>();
		List<Product_Discount__c> list_ProductDiscountToDelete = new List<Product_Discount__c>();
		Map<Id, Account> map_Accounts = new Map<Id, Account>();
		Set<Id> set_OpportunityIDs = new Set<Id>();
		Set<Id> set_OpportunityRecordTypeIDs = new Set<Id>{ OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID, OpportunityUtil.COMPANY_OPPTY_RT_ID };
		Decimal decSalesPrice = 0;
		List<Opportunity> list_Opportunity = new List<Opportunity>();

		// We have to split the query in two parts because the OR made it non-selective
		Map<Id, Opportunity> map_Opportunities = new Map<Id, Opportunity>();
		for (Opportunity objOpp : [
			SELECT
				Id,
				Name,
				MRR__c,
				Sold_By__c,
				AccountId,
				Current_Tier__c,
				Additional_Opportunity_Services__c,
				Pricebook2.Name,
				Discount__c,
				Sold_By__r.Discount__c,
				Account.Sold_By__r.Discount__c,
				Account.Reward_Eligible__c,
				Account.Number_of_Active_Employees__c,
				Account.Number_of_Active_Contractors__c,
				Account.International_Employees__c,
				Account.International_Contractors__c,
				Account.Additional_Services__c,
				Account.Tier__c,
				RecordTypeId,
				IsClosed,
				IsWon,
				Is_Invoiced__c,
				Tier__c,
				Account.Premium_Tier_Discount__c,
				Upsell_Tier__c,
				(SELECT Id, ZP_Product_Id__c, Discount_Amount__c, Discount_Percent__c, Discount_Type__c, Date_End__c, Date_Start__c FROM Product_Discounts__r WHERE Discount_Type__c = 'accountant')
			FROM Opportunity
			WHERE
				RecordTypeId = :set_OpportunityRecordTypeIDs
				AND (AccountId IN :set_AccountIDs
				OR Sold_By__c IN :set_AccountIDs)
				AND Is_Invoiced__c = FALSE
				AND StageName != :OpportunityUtil.CLOSED_LOST_STAGE
		]) {
			System.debug('objOpp.Product_Discounts__r: ' + objOpp.Product_Discounts__r);
			map_Opportunities.put(objOpp.Id, objOpp);
		}

		System.debug('map_Opportunities: ' + map_Opportunities);
		
		for (Opportunity objOpp : map_Opportunities.values()) {
			Decimal decPremiumTierDiscount = 0;
			Decimal decInternationalEmployeesForUpsell = objOpp.Account.International_Employees__c;
			// if upsell opp contains Employer of Record and international employees is null, set to 1 or else use value from account
			if (
				objOpp.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
				String.isNotBlank(objOpp.Upsell_Tier__c) &&
				objOpp.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)
			) {
				if ((objOpp.Account.International_Employees__c == null)) {
					decInternationalEmployeesForUpsell = 1;
				}
			}

			if (!map_Accounts.containsKey(objOpp.AccountId) && !objOpp.Is_Invoiced__c) {
				// get accountand discount from sold by reseller account
				Decimal decAccountantDiscount = objOpp.Account.Reward_Eligible__c && Account.Sold_By__c != null ? objOpp.Sold_By__r.Discount__c : 0;
				Account objAccount = new Account(Id = objOpp.AccountId);
				objAccount.Current_MRR__c = OpportunityUtil.calculateMRROppNew(
					objOpp.Account.Number_of_Active_Employees__c,
					objOpp.Account.Number_of_Active_Contractors__c,
					objOpp.Account.International_Employees__c,
					objOpp.Account.International_Contractors__c,
					objOpp.Account.Additional_Services__c,
					decAccountantDiscount,
					String.isNotBlank(objOpp.Tier__c) && objOpp.Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER) ? objOpp.Account.Premium_Tier_Discount__c : 0,
					AccountUtil.map_TierPaymentPlan.get(objOpp.Account.Tier__c?.toLowerCase())
				);
				map_Accounts.put(objAccount.Id, objAccount);
			}
			if (accountantDiscountEligible(objOpp) && !set_DeletedAccountIDs.contains(objOpp.Sold_By__c)) {
				if (objOpp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
					Product_Discount__c objPD = new Product_Discount__c();
					objPD.Discount_Percent__c = objOpp.Sold_By__r.Discount__c;
					objPD.Discount_Type__c = 'accountant';
					objPD.Opportunity__c = objOpp.Id;
					objPD.UniqueID__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
					list_ProductDiscountToUpsert.add(objPD);
					set_OpportunityIDs.add(objOpp.Id);
				} else if (objOpp.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID) {
					objOpp.Discount__c = objOpp.Sold_By__r.Discount__c;
					String strAdditionalServicesToCalculateAmount = '';
					if (objOpp.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
						strAdditionalServicesToCalculateAmount = AccountUtil.EMPLOYER_OF_RECORD;
						if ((objOpp.Account.International_Employees__c == null || objOpp.Account.International_Employees__c == 0)) {
							decInternationalEmployeesForUpsell = 1;
						}
					} else {
						strAdditionalServicesToCalculateAmount = objOpp.Additional_Opportunity_Services__c;
					}

					decSalesPrice = OpportunityUtil.calculateMRROppNew(
						objOpp.Account.Number_of_Active_Employees__c,
						objOpp.Account.Number_of_Active_Contractors__c,
						decInternationalEmployeesForUpsell,
						objOpp.Account.International_Contractors__c,
						strAdditionalServicesToCalculateAmount,
						objOpp.Discount__c, // accountant discount
						String.isNotBlank(objOpp.Upsell_Tier__c) && objOpp.Upsell_Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER) ? objOpp.Account.Premium_Tier_Discount__c : 0,
						objOpp.Pricebook2?.Name
					);
					objOpp.Amount = decSalesPrice - (objOpp.MRR__c != null ? objOpp.MRR__c : 0);
					list_Opportunity.add(objOpp);
				}
			} else {
				for (Product_Discount__c objPD : objOpp.Product_Discounts__r) {
					if (objPD.Discount_Type__c.equalsIgnoreCase('accountant')) {
						objPD.Discount_Percent__c = 0; // Is this line necessary if we are deleting?
						list_ProductDiscountToDelete.add(objPD);
						set_OpportunityIDs.add(objOpp.Id); // Collect Opportunity IDs only if the objOpp has Product Discount lines
					}
				}
				if (objOpp.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && objOpp.Discount__c > 0) {
					objOpp.Discount__c = 0;

					String strAdditionalServicesToCalculateAmount = '';
					if (objOpp.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
						strAdditionalServicesToCalculateAmount = AccountUtil.EMPLOYER_OF_RECORD;
						if ((objOpp.Account.International_Employees__c == null || objOpp.Account.International_Employees__c == 0)) {
							decInternationalEmployeesForUpsell = 1;
						}
					} else {
						strAdditionalServicesToCalculateAmount = objOpp.Additional_Opportunity_Services__c;
					}
					
					decSalesPrice = OpportunityUtil.calculateMRROppNew(
						objOpp.Account.Number_of_Active_Employees__c,
						objOpp.Account.Number_of_Active_Contractors__c,
						decInternationalEmployeesForUpsell,
						objOpp.Account.International_Contractors__c,
						strAdditionalServicesToCalculateAmount,
						objOpp.Discount__c, // accountant discount
						String.isNotBlank(objOpp.Upsell_Tier__c) && objOpp.Upsell_Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER) ? objOpp.Account.Premium_Tier_Discount__c : 0,
						objOpp.Pricebook2?.Name
					);
					objOpp.Amount = decSalesPrice - (objOpp.MRR__c != null ? objOpp.MRR__c : 0);
					list_Opportunity.add(objOpp);
				}
			}
		}
		List<String> list_HandlersToBypass = new List<String>{ 'ProductDiscountTriggerHandler' };
		// We bypass the PD trigger handler so we can get all ProductDiscount lines set, and then we call the discount application method
		Boolean blnRunDiscountUpdate = false;
		TriggerHandler.bypass(list_HandlersToBypass);
		if (!list_ProductDiscountToUpsert.isEmpty()) {
			blnRunDiscountUpdate = true;
			upsert list_ProductDiscountToUpsert UniqueID__c;
		}
		if (!list_ProductDiscountToDelete.isEmpty()) {
			blnRunDiscountUpdate = true;
			delete list_ProductDiscountToDelete;
		}
		TriggerHandler.clearBypass(list_HandlersToBypass);
		if (blnRunDiscountUpdate) {
			applyDiscountsToOLIs(set_OpportunityIDs);
		}
		TriggerHandler.bypass(new List<String>{ 'OpportunityTriggerHandler', 'AccountTriggerHandler' });
		if (!list_Opportunity.isEmpty()) {
			update list_Opportunity;
		}
		if (map_Accounts != null && !map_Accounts.values().isEmpty()) {
			update map_Accounts.values();
		}

		TriggerHandler.clearBypass(new List<String>{ 'OpportunityTriggerHandler', 'AccountTriggerHandler' });
	}

	/**
	 * @description When we change Sold_By__c on an Opportunity, check for Accountant eligibility. We need to trigger on Opportunity in case one is assigned after creation to a reseller.
	 * @author David Schach
	 * @param  list_Opportunities   Trigger.new
	 * @param  map_OldOpportunities Trigger.oldMap (null on insert)
	 */
	public void collectCompanyOpportunitiesForDiscounts(List<Opportunity> list_Opportunities, Map<Id, Opportunity> map_OldOpportunities) {
		Set<Id> set_AccountIDs = new Set<Id>();
		Set<Id> set_OpportunityIDs = new Set<Id>();

		for (Opportunity objOpp : list_Opportunities) {
			if (objOpp.RecordTypeId != OpportunityUtil.COMPANY_OPPTY_RT_ID) {
				continue;
			}
			if ((map_OldOpportunities == null && objOpp.Sold_By__c != null) || (map_OldOpportunities != null && objOpp.Sold_By__c != map_OldOpportunities.get(objOpp.Id).Sold_By__c)) {
				if (objOpp.AccountId != null) {
					set_AccountIDs.add(objOpp.AccountId);
				}
				if (objOpp.Sold_By__c != null) {
					set_AccountIDs.add(objOpp.Sold_By__c);
				}
			}
			if (objOpp.CloseDate != map_OldOpportunities?.get(objOpp.Id)?.CloseDate) {
				set_OpportunityIDs.add(objOpp.Id);
			}
		}
		System.debug('set_AccountIDs: ' + set_AccountIDs);
		if (!set_AccountIDs.isEmpty()) {
			new ProductDiscountHelper().handleAccountantProductDiscounts(set_AccountIDs, new Set<Id>());
		}
		System.debug('set_OpportunityIDs: ' + set_OpportunityIDs);
		if (!set_OpportunityIDs.isEmpty()) {
			new ProductDiscountHelper().applyDiscountsToOLIs(set_OpportunityIDs);
		}
	}
	
	/**
	 * @description  Method to apply wholesale discount to all the OpportunityLineItems            
	 *
	 * @param set_OpportunityIds 
	 */
	public void applyWholeSaleDiscount(Set<String> set_OpportunityIds) {

		
		List<Opportunity> list_Opportunities = [
			SELECT Id, Sold_By__c, Sold_By__r.Discount__c, Account.Reward_Eligible__c, RecordTypeId, (SELECT Id, Discount, Product2Id, Product2.ExternalId FROM OpportunityLineItems)
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID AND Id IN :set_OpportunityIds
		];
		List<OpportunityLineItem> list_olisToUpdate = new List<OpportunityLineItem>();
		for (Opportunity objOpp : list_Opportunities) {
			list_olisToUpdate.addAll(objOpp.OpportunityLineItems);
		}
		TriggerHandler.bypass('OpportunityTriggerHandler');
		TriggerHandler.bypass('AccountTriggerHandler');
		update list_olisToUpdate;
		TriggerHandler.clearBypass('OpportunityTriggerHandler');
		TriggerHandler.clearBypass('AccountTriggerHandler');
	}
}