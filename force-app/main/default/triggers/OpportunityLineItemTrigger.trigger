/**
 * Trigger for `OpportunityLineItem` object. We only have methods for before insert and before update, but we leave all applicable contexts here to be uncommented if they are used later. `OpportunityLineItem` cannot be undeleted; it is hard-deleted and does not go to the Recycle Bin. We leave the extra contexts here.
 * @author David Schach
 * @since Jan 2022
 * @see ProductDiscountTest
 * @group Opportunity
 */
trigger OpportunityLineItemTrigger on OpportunityLineItem(before insert, before update, before delete){ //after insert, after update, before delete, after delete) {
	// Check if Logged In User has custom permissions to bypass trigger
	if (FeatureManagement.checkPermission('Bypass_Triggers')) {	return;	} //NOPMD
	new OpportunityLineItemTriggerHandler().run();
}