/**
 * @description  Trigger on GF_Lead__c object
 * @author       Veeresh Kumar
 * @date         04/13/2022
 * @see          GFLeadTriggerHelperTest
 **/
trigger GFLeadTrigger on GF_Lead__c(before insert, after insert, before update, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (GFLeadTriggerHelper.skipTrigger || FeatureManagement.checkPermission('Bypass_Triggers')) {
		return;
	}
	new GFLeadTriggerHandler().run();
}