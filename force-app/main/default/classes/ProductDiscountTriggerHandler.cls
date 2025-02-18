/**
 * Trigger handler for Product Discount, which updates Opportunity Line Items
 *
 * @author  David Schach
 * @since   2021-12-29
 * @group   Product Discount
 * @see     ProductDiscountTest
 * @see     ProductDiscountHelper
 */
public without sharing class ProductDiscountTriggerHandler extends TriggerHandler {
	private List<Product_Discount__c> list_newRecords;
	private List<Product_Discount__c> list_oldRecords;
	private Map<Id, Product_Discount__c> map_newRecordsMap;
	private Map<Id, Product_Discount__c> map_oldRecordsMap;

	/**
	 * Trigger handler constructor
	 */
	public ProductDiscountTriggerHandler() {
		super('ProductDiscountTriggerHandler');
		this.list_newRecords = Trigger.new;
		this.list_oldRecords = Trigger.old;
		this.map_newRecordsMap = (Map<Id, Product_Discount__c>) Trigger.newMap;
		this.map_oldRecordsMap = (Map<Id, Product_Discount__c>) Trigger.oldMap;
	}

	/**
	 * Generate Unique ID in beforeInsert
	 * @author David Schach
	 */
	public override void beforeInsert() {
		generateUniqueID(list_newRecords);
		validateProductIDField(list_newRecords);
	}

	/**
	 * After Insert, we delete if percent discount is 0, and then run discounts on remaining `Product_Discount__c` records for each Opportunity
	 * @author David Schach
	 */
	public override void afterInsert() {
		deleteBasedOnCriteria(list_newRecords);
		gatherOpportunityIDs(list_newRecords, null);
	}

	/**
	 * Generate Unique ID in beforeUpdate in case it was changed by a user
	 * @author David Schach
	 */
	public override void beforeUpdate() {
		generateUniqueID(list_newRecords);
		validateProductIDField(list_newRecords);
	}

	/**
	 * After Update, we delete if percent discount is 0, and then run discounts on remaining `Product_Discount__c` records for each Opportunity
	 * @author David Schach
	 */
	public override void afterUpdate() {
		deleteBasedOnCriteria(list_newRecords);
		gatherOpportunityIDs(list_newRecords, map_oldRecordsMap);
	}

	/**
	 * After Delete, we run discounts on remaining `Product_Discount__c` records for each Opportunity
	 * @author David Schach
	 */
	public override void afterDelete() {
		gatherOpportunityIDs(list_oldRecords, null);
	}

	/**
	 * After Undelete, add an error to prevent undeleting Product Discount records. They will need to be recreated, which could be difficult with global ones, but they will need to be inserted again. This is to ensure data integrity for all PD records.
	 * @author David Schach
	 */
	public override void afterUndelete() {
		for (Product_Discount__c objPD : list_newRecords) {
			objPD.addError('Cannot restore Product Discount records from recycle bin. They are created automatically.');
		}
	}

	/**
	 * Ensure that global discounts do not have a product specified
	 * @author David Schach
	 * @param  listnewRecords Trigger.new
	 */
	private void validateProductIDField(List<Product_Discount__c> listnewRecords) {
		Set<String> set_ValidProductDiscounts = new Set<String>();
		set_ValidProductDiscounts.addAll(System.Label.Eligible_Discount_Types.split(';'));
		for (Product_Discount__c objPD : listnewRecords) {
			if (ProductDiscountHelper.SET_VALID_GLOBAL_DISCOUNTS.contains(objPD.Discount_Type__c) && String.isNotBlank(objPD.ZP_Product_Id__c) && (String.isNotBlank(objPD.Discount_Type__c) && !objPD.Discount_Type__c.containsIgnoreCase(ProductDiscountHelper.WHOLESALE_PARTNER_DISCOUNT))) {
				objPD.addError('ZP_Product_Id__c', 'Global discounts such as Accountant discounts cannot be linked to a specific Product');
			} else if (set_ValidProductDiscounts.contains(objPD.Discount_Type__c) && String.isBlank(objPD.ZP_Product_Id__c)) {
				objPD.addError('ZP_Product_Id__c', 'Product-specific discounts must be linked to a specific Product');
			}
		}
	}

	/**
	 * Use the method in ProductDiscountHelper to generate a uniqueID for ProductDiscount, regardless of where it is created from
	 * @author                 David Schach
	 * @param  list_newRecords Trigger.new
	 */
	private void generateUniqueID(List<Product_Discount__c> list_newRecords) {
		for (Product_Discount__c objPD : list_newRecords) {
			objPD.UniqueID__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		}
	}

	/**
	 * Collect OpportunityIDs for new/changed PD records so we can do our work to link OLIs and update discounts
	 * @author                    David Schach
	 * @param  list_newRecords    Trigger.new (or Trigger.old in delete)
	 * @param  map_oldRecordsMap  Trigger.old for update; null if insert or delete (included for future functionality)
	 */
	private void gatherOpportunityIDs(List<Product_Discount__c> list_newRecords, Map<Id, Product_Discount__c> map_oldRecordsMap) {
		Set<Id> setOppIDs = new Set<Id>();
		for (Product_Discount__c objPD : list_newRecords) {
			setOppIDs.add(objPD.Opportunity__c);
		}
		new ProductDiscountHelper().applyDiscountsToOLIs(setOppIDs);
	}

	/**
	 * If we clear or zero the Discount Percent, or we clear the Type, delete the PD record
	 * @author                 David Schach
	 * @param  list_newRecords Trigger.new
	 * @return                 Deleted `Product_Discount__c` records
	 */
	private List<Product_Discount__c> deleteBasedOnCriteria(List<Product_Discount__c> list_newRecords) {
		List<Product_Discount__c> list_DiscountsToDelete = new List<Product_Discount__c>();
		for (Product_Discount__c objPD : list_newRecords) {
			Decimal discAmt = objPD.Discount_Amount__c == null ? 0 : objPD.Discount_Amount__c;
			Decimal discPct = objPD.Discount_Percent__c == null ? 0 : objPD.Discount_Percent__c;
			if (String.isBlank(objPD.Discount_Type__c) || (discAmt <= 0 && discPct <= 0)) {
				list_DiscountsToDelete.add(new Product_Discount__c(Id = objPD.Id));
			}
		}
		if (!list_DiscountsToDelete.isEmpty()) {
			TriggerHandler.bypass('ProductDiscountTriggerHandler');
			delete list_DiscountsToDelete;
			TriggerHandler.clearBypass('ProductDiscountTriggerHandler');
		}
		return list_DiscountsToDelete;
	}
}