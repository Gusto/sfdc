/**
 * @description  Trigger on ZP_User_Role__c object
 * @author       Praveen Sethu
 * @date         02-12-2021
 * @see          ZPUserRoleTriggerHelperTest
 **/
trigger ZPUserRoleTrigger on ZP_User_Role__c(before insert, after insert, before update, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || ZPUserRoleTriggerHelper.skipTrigger) {
		return;
	}

	new ZPUserRoleTriggerHandler().run();
}