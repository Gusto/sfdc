/**
 * @description Trigger handler for OpportunityLineItem
 *
 * @author      David Schach
 * @since       Jan 2022
 * @group       Opportunity
 * @see         ProductDiscountHelper
 * @see         ProductDiscountTest
 */
public without sharing class OpportunityLineItemTriggerHandler extends TriggerHandler {
	private List<OpportunityLineItem> list_newRecords;
	private List<OpportunityLineItem> list_oldRecords;
	private Map<Id, OpportunityLineItem> map_newRecordsMap;
	private Map<Id, OpportunityLineItem> map_oldRecordsMap;

	public static String DISCOUNT_TYPE_ACCOUNTANT = 'accountant';

	/**
	 * Constructor for trigger handler
	 * @author David Schach
	 */
	public OpportunityLineItemTriggerHandler() {
		super('OpportunityLineItemTriggerHandler');
		this.list_newRecords = (List<OpportunityLineItem>) Trigger.new;
		this.list_oldRecords = (List<OpportunityLineItem>) Trigger.old;
		this.map_newRecordsMap = (Map<Id, OpportunityLineItem>) Trigger.newMap;
		this.map_oldRecordsMap = (Map<Id, OpportunityLineItem>) Trigger.oldMap;
	}

	/**
	 * Before insert, apply discounts
	 * @author David Schach
	 */
	public override void beforeInsert() {
		applyProductDiscounts(list_newRecords);
	}

	/**
	 * Before update, apply discounts
	 * @author David Schach
	 */
	public override void beforeUpdate() {
		applyProductDiscounts(list_newRecords);
		validateProductDiscounts(this.list_newRecords, this.map_oldRecordsMap);
	}

	/**
	 * Handles before delete logic and prevents record deletion
	 * @author Praveen Sethu
	 */
	public override void beforeDelete() {
		handleGrowthExpansionDeletion(list_oldRecords);
	}

	/* @description Prevents deletion of Growth/Expansion OpportunityLineItems if there is only one OLI on the Opportunity
	 *
	 * @author Praveen Sethu
	 * @param  list_triggerRecords   Trigger.old
	 */
	public void handleGrowthExpansionDeletion(List<OpportunityLineItem> list_oldRecords) {
		// Variables declaration
		Set<Id> set_OpptyIds = new Set<Id>();
		Map<Id, Opportunity> map_Opportunities = new Map<Id, Opportunity>();

		// Collect opportunity Ids from Trigger.Old context
		for (OpportunityLineItem objOLI : list_oldRecords) {
			if (objOLI.OpportunityId != null) {
				set_OpptyIds.add(objOLI.OpportunityId);
			}
		}

		// Query opportunity from set of opportunity Ids
		if (!set_OpptyIds.isEmpty()) {
			// Build a map of Opportunity Id and Opportunity Id
			for (Opportunity objOppty : [SELECT Id, RecordTypeId, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE Id IN :set_OpptyIds]) {
				map_Opportunities.put(objOppty.Id, objOppty);
			}

			for (OpportunityLineItem objOLI : list_oldRecords) {
				// Get the opportunity from the map
				if (map_Opportunities.containsKey(objOLI.OpportunityId)) {
					Opportunity objOppty = map_Opportunities.get(objOLI.OpportunityId);
					// If line item size is 1 & record type is Growth/Expansion - throw an error
					System.debug(objOppty.OpportunityLineItems.size());
					if (objOppty.OpportunityLineItems.size() == 1 && objOppty.RecordTypeId == OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID) {
						objOLI.addError('At least one product is required on this Opportunity. If you need to close the Opportunity, please update the Stage to \'Closed Lost\' instead.');
					}
				}
			}
		}
	}

	/**
	 * @description For each OLI, calculate the total discount from all Product_Discount__c records that apply to that OLI
	 *
	 * @author David Schach
	 * @param  list_triggerRecords   Trigger.new (or all collected OLIs when invoicing)
	 * @return                       Those OLI records, in case another method in the future will need to use them
	 */
	public List<OpportunityLineItem> applyProductDiscounts(List<OpportunityLineItem> list_triggerRecords) {
		Set<Id> set_opportunityIDs = new Set<Id>();
		Set<Id> set_pbeIDs = new Set<Id>();
		Map<Id, PricebookEntry> map_PricebookEntryToProductPricebook = new Map<Id, PricebookEntry>();
		Map<Id, List<Product_Discount__c>> map_PDsByOppId = new Map<Id, List<Product_Discount__c>>();

		// collecting pricebook entry ids
		for (OpportunityLineItem objOLI : list_triggerRecords) {
			set_opportunityIDs.add(objOLI.OpportunityId);
			set_pbeIDs.add(objOLI.PricebookEntryId);
		}

		for (PricebookEntry objPBE : [SELECT Id, Product2.ExternalId, Pricebook2.Product_Tier__c, Product2.Name, Product2.Discounts_Available__c FROM PricebookEntry WHERE Id IN :set_pbeIDs]) {
			map_PricebookEntryToProductPricebook.put(objPBE.Id, objPBE);
		}

		Map<Id, Opportunity> map_Opportunities = new Map<Id, Opportunity>(
			[
				SELECT Id, IsClosed, IsWon, CloseDate, Account.Tier__c, Payment_Invoice__c, Joined_Date_Panda__c, Discount__c, Calculation_Fee_Discount__c, RecordTypeId
				FROM Opportunity
				WHERE Id IN :set_opportunityIDs
			]
		);

		for (Product_Discount__c objPD : [
			SELECT Id, ZP_Product_Id__c, Discount_Amount__c, Discount_Percent__c, Discount_Type__c, Date_End__c, Date_Start__c, Opportunity__c, Active__c, Opportunity__r.RecordTypeId
			FROM Product_Discount__c
			WHERE Opportunity__c IN :set_opportunityIDs AND Opportunity__r.RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID
		]) {
			List<Product_Discount__c> list_existingPDs = map_PDsByOppId.get(objPD.Opportunity__c);
			if (list_existingPDs == null) {
				list_existingPDs = new List<Product_Discount__c>();
			}
			list_existingPDs.add(objPD);
			map_PDsByOppId.put(objPD.Opportunity__c, list_existingPDs);
		}

		for (OpportunityLineItem objOLI : list_triggerRecords) {
			// We want to calculate on all opps
			// If we edited Product Discount records, we recalculate based on thoe
			// If we edit OLIs, we override whatever we put in the discount field and use the PDs

			Opportunity objParentOpp = map_Opportunities.get(objOLI.OpportunityId);
			//Blocks Discount recalculation - Ardius Opportunity Line Items
			if (OpportunityUtil.set_ArdiusRecordTypeIds.contains(objParentOpp?.RecordTypeId)) {
				continue;
			}

			//Resets Discount value to 0
			objOLI.Discount = 0;
			Date dtOppCloseDate = objParentOpp.CloseDate;

			if (map_PDsByOppId.containsKey(objOLI.OpportunityId)) {
				// iteratimg over prpdcut discounts
				for (Product_Discount__c objPD : map_PDsByOppId.get(objOLI.OpportunityId)) {
					String strDiscountType = objPD.Discount_Type__c.toLowerCase();
					PricebookEntry objPBE = map_PricebookEntryToProductPricebook.get(objOLI.PricebookEntryId);
					String strAvailableProductDiscount = objPBE.Product2.Discounts_Available__c;

					//if inactive product discount then we will consider for the discounting process
					if (!objPD.Active__c) {
						continue;
					}

					// checking if current prodcut is eligible the discount. Discount type is being matched from product discount type.
					if (String.isNotBlank(strDiscountType) && String.isNotBlank(strAvailableProductDiscount) && strAvailableProductDiscount.contains(strDiscountType)) {
						// check for the accountant
						if (strDiscountType.equalsIgnoreCase(DISCOUNT_TYPE_ACCOUNTANT)) {
							if (String.isBlank(objPD.ZP_Product_Id__c) && ProductDiscountHelper.SET_VALID_GLOBAL_DISCOUNTS.contains(objPD.Discount_Type__c)) {
								objOLI.Discount += objPD.Discount_Percent__c;
							}
						} else {
							// check for the other discount types
							String strProductTier = objPBE.Pricebook2.Product_Tier__c;
							String strProductExternalId = objPBE.Product2.ExternalId;

							if (objPBE != null) {
								if (String.isNotBlank(strProductTier) && objPD.Date_Start__c == null) {
									continue;
								}

								if (
									String.isNotBlank(strProductExternalId) &&
									strProductExternalId.equalsIgnoreCase(objPD.ZP_Product_Id__c) &&
									objPD.Date_Start__c <= dtOppCloseDate &&
									(objPD.Date_End__c == null || (objPD.Date_End__c != null && objPD.Date_End__c >= dtOppCloseDate))
								) {
									objOLI.Discount += objPD.Discount_Percent__c;
								}
							}
						}
					} else {
						objOLI.Discount += 0;
					}
				}
			}
		}
		return list_triggerRecords;
	}

	/**
	 * @description	Validate Product Discount changes
	 * @author	Ajay Krishna P U
	 * @since	2023-10-20
	 * @param list_NewOppLineItems New version of Opportunity Line Items
	 * @param map_OldOppLineItems  Old version of Opportunity Line items
	 */
	private void validateProductDiscounts(List<OpportunityLineItem> list_NewOppLineItems, Map<Id, OpportunityLineItem> map_OldOppLineItems) {
		//Process only If Block Discounts functionality is Enabled & Updating Product Discounts
		if (Ardius_Configuration__c.getInstance()?.Block_Discounts_After_Customer_Approval__c != true || map_OldOppLineItems == null) {
			return;
		}
		Set<String> set_BlockDiscountTicketStatuses = new Set<String>(System.Label.Ardius_Block_Discounts_Statuses.split(';'));

		// Find the Opportunity & Line Items to Process
		Map<Id, List<OpportunityLineItem>> map_OppIdToLineItemsToProcess = new Map<Id, List<OpportunityLineItem>>();
		for (OpportunityLineItem objLineItem : list_NewOppLineItems) {
			if (objLineItem.Discount != map_OldOppLineItems.get(objLineItem.Id).Discount) {
				List<OpportunityLineItem> list_LineItems = map_OppIdToLineItemsToProcess.get(objLineItem.OpportunityId);
				if (list_LineItems == null) {
					list_LineItems = new List<OpportunityLineItem>();
					map_OppIdToLineItemsToProcess.put(objLineItem.OpportunityId, list_LineItems);
				}

				list_LineItems.add(objLineItem);
			}
		}

		// Add Error If Opportunity.Ticket.Status Is in Block statues
		for (Opportunity objOpportunity : [
			SELECT Id, (SELECT Id, Status__c FROM Tickets__r WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID ORDER BY LastModifiedDate DESC LIMIT 1)
			FROM Opportunity
			WHERE Id IN :map_OppIdToLineItemsToProcess.keySet() AND RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID
		]) {
			if (!objOpportunity.Tickets__r.isEmpty() && set_BlockDiscountTicketStatuses.contains(objOpportunity.Tickets__r[0].Status__c)) {
				List<OpportunityLineItem> list_LineItems = map_OppIdToLineItemsToProcess.get(objOpportunity.Id);
				if (list_LineItems == null || list_LineItems.isEmpty()) {
					continue;
				}

				//Add Error
				for (OpportunityLineItem objLineItem : list_LineItems) {
					objLineItem.addError(OpportunityLineItem.Discount, System.Label.Ardius_Block_Discounts_Error_Message);
				}
			}
		}
	}
}