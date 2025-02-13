trigger ContactTrigger on Contact(before insert, after insert, after update, before update, before delete, after delete, after undelete) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || ContactTriggerHelper.skipTrigger || TriggerBypass__c.getInstance().ContactTrigger__c) {return;}

	new ContactTriggerHandler().run();
}