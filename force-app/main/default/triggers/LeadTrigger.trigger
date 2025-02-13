trigger LeadTrigger on Lead(before insert, after insert, before update, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to TRUE
	if (
		LeadTriggerHelper.skipTrigger ||
		FeatureManagement.checkPermission('Bypass_Triggers') ||
		TriggerBypass__c.getInstance().LeadTrigger__c
	) {
		return;
	}

	new LeadTriggerHandler().run();
}