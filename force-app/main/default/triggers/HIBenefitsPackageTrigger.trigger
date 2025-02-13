trigger HIBenefitsPackageTrigger on HI_Benefits_Package__c(after insert, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || HIBenefitsPackageTriggerHelper.skipTrigger) {
		return;
	}

	new HIBenefitsPackageTriggerHandler().run();
}