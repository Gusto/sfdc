/**
 * Trigger for `Product_Discount__c` object. When PD records are inserted or updated, we recalculate the line items for all Opportunity Line Item records for the Product Discont's Opportunity.
 * @author David Schach
 * @since Jan 2022
 * @see ProductDiscountTest
 * @group Product Discount
 */
trigger ProductDiscountTrigger on Product_Discount__c(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	if (FeatureManagement.checkPermission('Bypass_Triggers')) {	return;	} //NOPMD
	new ProductDiscountTriggerHandler().run();
}