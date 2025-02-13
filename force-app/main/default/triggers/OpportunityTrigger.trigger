trigger OpportunityTrigger on Opportunity(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to True
	if (FeatureManagement.checkPermission('Bypass_Triggers') || OpportunityTriggerHelper.skipTrigger || TriggerBypass__c.getInstance().OpportunityTrigger__c) {
		return;
	}
	new OpportunityTriggerHandler().run();
}