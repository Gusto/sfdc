/**
 * Trigger for `ZP_Adjustments__c` object. When records are created, a subset are copied to `Product_Discount__c` records. This acts like a platform event, and we can switch out ZP_Adjustments__c for a platform event in the future with no friction.
 * @author David Schach
 * @since Jan 2022
 * @see ZPAdjustmentTriggerHandlerTest
 * @group Product Discount
 */
trigger ZPAdjustmentTrigger on ZP_Adjustments__c(after insert, after update) {
	if (FeatureManagement.checkPermission('Bypass_Triggers')) {	return; }//NOPMD
	new ZPAdjustmentTriggerHandler().run();
}