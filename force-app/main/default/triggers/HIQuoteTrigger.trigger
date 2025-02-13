trigger HIQuoteTrigger on HI_Quote__c(after insert, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || HIQuoteTriggerHelper.str_skipTrigger)
		return;

	new HIQuoteTriggerHandler().run();
}