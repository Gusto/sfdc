/**
 * Trigger Handler for ZP Adjustment. Designed so it can be cloned for a Platform Event in the future
 * @author      David Schach
 * @since       Jan 2022
 * @group       Product Discount
 * @see ZPAdjustmentTriggerHandlerTest
 */
public without sharing class ZPAdjustmentTriggerHandler extends TriggerHandler {
	private List<ZP_Adjustments__c> list_newRecords;
	private Map<Id, ZP_Adjustments__c> map_oldRecordsMap;
	/**
	 * Constructor
	 * @author David Schach
	 */
	public ZPAdjustmentTriggerHandler() {
		super('ZPAdjustmentTriggerHandler');
		this.list_newRecords = (List<ZP_Adjustments__c>) Trigger.new;
		this.map_oldRecordsMap = (Map<Id, ZP_Adjustments__c>) Trigger.oldMap;
	}

	public override void afterInsert() {
		try {
			upsertProductDiscountsFromZPAdjustments(list_newRecords, null);
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ZPAdjustmentTriggerHandler', 'afterInsert', null, objEx);
		}
	}

	public override void afterUpdate() {
		try {
			upsertProductDiscountsFromZPAdjustments(list_newRecords, map_oldRecordsMap);
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ZPAdjustmentTriggerHandler', 'afterUpdate', null, objEx);
		}
	}

	/**
	 * When a `ZP_Adjustment__c` record is created, make a `Product_Discount__c` record. We filter for specific adjustment types.
	 * <br>Because we may have multiple, conflicting adjustments coming in from integration, we will only update a `Product_Discount__c` record if the ZP_Adjustment Id
	 * is greater than the objPD record's ZP_Adjustment Id.
	 * <br>Note: This will prevent records in different trigger batches overwriting newer ones, but it does not (yet) check in the same trigger batch.
	 * @author David Schach
	 * @param  list_newZPAs   new `ZP_Adjustment__c` Records
	 * @param  map_oldZPAsMap Trigger.oldMap
	 * @return                The created `Product_Discount__c` records
	 */
	private List<Product_Discount__c> upsertProductDiscountsFromZPAdjustments(List<ZP_Adjustments__c> list_newZPAs, Map<Id, ZP_Adjustments__c> map_oldZPAsMap) {
		Set<String> set_payerPricingPlanIDs = new Set<String>();
		Set<String> set_EligibleDiscountType = new Set<String>();
		Map<String, ZP_Payer_Pricing_Plan__c> map_ZPPayerPricingPlans = new Map<String, ZP_Payer_Pricing_Plan__c>();
		Set<String> set_zpCompanyIDs = new Set<String>();
		Map<String, Account> map_ZPCompanyIdToAccount = new Map<String, Account>();
		Set<String> set_proposedPDUniqueIDs = new Set<String>();
		Map<String, Product_Discount__c> map_ProposedPDsToUpsertByUniqueId = new Map<String, Product_Discount__c>();
		set_EligibleDiscountType.addAll(System.Label.Eligible_Discount_Types.split(';'));
		// Building a map of Account Id to Account to update
		Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();
		// Building a map of Payer Pricing Plan Id to ZP Adjustments
		Map<String, List<ZP_Adjustments__c>> map_PayerPricingPlanIdToZPAdjustments = new Map<String, List<ZP_Adjustments__c>>();

		for (ZP_Adjustments__c objZPAdj : list_newZPAs) {
			set_payerPricingPlanIDs.add(objZPAdj.Payer_Pricing_Plan_Id__c);
		}

		for (ZP_Payer_Pricing_Plan__c objZPppp : [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c WHERE Id__c IN :set_payerPricingPlanIDs]) {
			map_ZPPayerPricingPlans.put(objZPppp.Id__c, objZPppp);
			set_zpCompanyIDs.add(objZPppp.Payer_Id__c);
		}

		for (Account objAcct : [
			SELECT
				Id,
				ZP_Company_ID__c,
				Tier__c,
				Premium_Tier_Discount__c,
				(
					SELECT Id, RecordType.Name, IsClosed, IsWon, Is_Invoiced__c, CloseDate, Payment_Invoice__c
					FROM Opportunities
					WHERE RecordTypeId = :RecordTypes.getRecordTypeIdFromDeveloperName('Opportunity', 'Company_Opportunity') AND Payment_Invoice__c = NULL
				)
			FROM Account
			WHERE ZP_Company_ID__c IN :set_zpCompanyIDs
		]) {
			map_ZPCompanyIdToAccount.put(objAcct.ZP_Company_ID__c, objAcct);
		}

		// Query existing zp adjustments based on eligible discount types and build a map of payer pricing plan Id and zp adjustments
		for (ZP_Adjustments__c objAdjustment : [
			SELECT Id, Adjustment_Type__c, Percentage__c, Period_Start__c, Period_End__c, Payer_Pricing_Plan_Id__c
			FROM ZP_Adjustments__c
			WHERE Payer_Pricing_Plan_Id__c IN :set_payerPricingPlanIDs AND Adjustment_Type__c IN :set_EligibleDiscountType
		]) {
			if (!map_PayerPricingPlanIdToZPAdjustments.containsKey(objAdjustment.Payer_Pricing_Plan_Id__c)) {
				map_PayerPricingPlanIdToZPAdjustments.put(objAdjustment.Payer_Pricing_Plan_Id__c, new List<ZP_Adjustments__c>());
			}

			map_PayerPricingPlanIdToZPAdjustments.get(objAdjustment.Payer_Pricing_Plan_Id__c).add(objAdjustment);
		}

		for (ZP_Adjustments__c objZPAdj : list_newZPAs) {
			if (map_ZPPayerPricingPlans.containsKey(objZPAdj.Payer_Pricing_Plan_Id__c)) {
				ZP_Payer_Pricing_Plan__c objZPPPP = map_ZPPayerPricingPlans.get(objZPAdj.Payer_Pricing_Plan_Id__c);
				String strZPCompanyId = objZPPPP.Payer_Id__c;

				if (map_ZPCompanyIdToAccount.containsKey(strZPCompanyId)) {
					Account objcustomerAccount = map_ZPCompanyIdToAccount.get(strZPCompanyId);
					List<Opportunity> list_NonInvoicedOpps = objcustomerAccount.Opportunities;

					// check if map of payer pricing plan Id and zp adjustments contains key
					if (map_PayerPricingPlanIdToZPAdjustments.containsKey(objZPAdj.Payer_Pricing_Plan_Id__c)) {
						Decimal decPremiumTierDiscount = 0;
						// iterate over all adjustment records for the payer pricing plan Id
						for (ZP_Adjustments__c objAdjustment : map_PayerPricingPlanIdToZPAdjustments.get(objZPAdj.Payer_Pricing_Plan_Id__c)) {
							// update premium tier discount on account
							if (
								objAdjustment.Adjustment_Type__c == AccountUtil.PREMIUM_TIER_DISCOUNT &&
								objAdjustment.Period_End__c != null &&
								objAdjustment.Period_End__c >= Date.today() &&
								objAdjustment.Percentage__c != null &&
								objAdjustment.Percentage__c > 0
							) {
								decPremiumTierDiscount = decPremiumTierDiscount + objAdjustment.Percentage__c;
							}
						}

						// update premium tier discount only when data does not match on the account
						if (objcustomerAccount != null && objcustomerAccount.Premium_Tier_Discount__c != decPremiumTierDiscount) {
							objcustomerAccount.Premium_Tier_Discount__c = decPremiumTierDiscount;
							map_AccountsToUpdate.put(objcustomerAccount.Id, objcustomerAccount);
						}
					}

					for (Opportunity objOpp : list_NonInvoicedOpps) {
						// Exclusion criteria for each allowed discount type. Add more types here.
						Product_Discount__c objPD = new Product_Discount__c();

						// Handle dates
						objPD.Date_End__c = objZPAdj.Period_End__c;
						objPD.Date_Start__c = objZPAdj.Period_Start__c;

						// In case the adjustment type is blank on ZPAdjustment UPDATE, set the matching Product Discount amount and percent to 0 so it will be deleted
						if (map_oldZPAsMap?.get(objZPAdj.Id) != null && String.isBlank(objZPAdj.Adjustment_Type__c)) {
							objPD.Discount_Amount__c = 0;
							objPD.Discount_Percent__c = 0;
							objPD.Discount_Type__c = map_oldZPAsMap.get(objZPAdj.Id).Adjustment_Type__c; // Don't clear it so we can delete it later
						} else {
							objPD.Discount_Amount__c = objZPAdj.Amount__c;
							objPD.Discount_Percent__c = objZPAdj.Percentage__c;
							objPD.Discount_Type__c = objZPAdj.Adjustment_Type__c;
						}

						// Handle each adjustment type - this is where we filter only for the types we want to include
						String strAdjustmentType = objPD.Discount_Type__c?.toLowerCase();

						if (String.isBlank(strAdjustmentType)) {
							// skip if adjustment type is blank
							continue;
						} else if (set_EligibleDiscountType.contains(strAdjustmentType)) {
							// process only adjusment type is select tier old or new discount
							if (String.isBlank(objZPAdj.Product_Id__c) || objZPAdj.Period_Start__c == null || objOpp.Is_Invoiced__c) {
								continue;
							}
						} else {
							// skip if adjusment type is NOT select tier old and new discount
							continue;
						}

						// Fill in the rest of the fields
						objPD.Opportunity__c = objOpp.Id;

						objPD.ZP_Product_Id__c = objZPAdj.Product_Id__c != null ? objZPAdj.Product_Id__c : '';
						objPD.ZP_Adjustment_Id__c = objZPAdj.Id__c;

						objPD.UniqueID__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
						set_proposedPDUniqueIDs.add(objPD.UniqueID__c);

						if (!map_ProposedPDsToUpsertByUniqueId.containsKey(objPD.UniqueID__c)) {
							map_ProposedPDsToUpsertByUniqueId.put(objPD.UniqueID__c, objPD);
						} else {
							Integer intinboundZPAId = Integer.valueof(objPD.ZP_Adjustment_Id__c);
							Integer intexistingZPAId = Integer.valueof(map_ProposedPDsToUpsertByUniqueId.get(objPD.UniqueID__c).ZP_Adjustment_Id__c);

							if (intexistingZPAId <= intinboundZPAId) {
								map_ProposedPDsToUpsertByUniqueId.put(objPD.UniqueID__c, objPD);
							}
						}
					}
				}
			}
		}

		Map<String, String> map_ProductDiscountUniqueIDtoZPAdjustmentID = new Map<String, String>();
		Map<String, Product_Discount__c> map_ProductDiscountsToUpsert = new Map<String, Product_Discount__c>();

		for (Product_Discount__c objExistingPD : [SELECT Id, UniqueId__c, ZP_Adjustment_Id__c FROM Product_Discount__c WHERE UniqueID__c IN :set_proposedPDUniqueIDs]) {
			map_ProductDiscountUniqueIDtoZPAdjustmentID.put(objExistingPD.UniqueID__c, objExistingPD.ZP_Adjustment_Id__c);
		}

		for (Product_Discount__c objPD : map_ProposedPDsToUpsertByUniqueId.values()) {
			if (!map_ProductDiscountUniqueIDtoZPAdjustmentID.containsKey(objPD.UniqueID__c)) {
				map_ProductDiscountsToUpsert.put(objPD.UniqueID__c, objPD);
			} else {
				Integer intinboundZPAId = Integer.valueof(objPD.ZP_Adjustment_Id__c);
				Integer intexistingZPAId = Integer.valueof(map_ProductDiscountUniqueIDtoZPAdjustmentID.get(objPD.UniqueID__c));

				if (intexistingZPAId <= intinboundZPAId) {
					map_ProductDiscountsToUpsert.put(objPD.UniqueID__c, objPD);
				}
			}
		}

		upsert map_ProductDiscountsToUpsert.values() UniqueID__c;

		if (!map_AccountsToUpdate.isEmpty()) {
			Database.update(map_AccountsToUpdate.values(), false);
		}

		return map_ProductDiscountsToUpsert.values();
	}
}