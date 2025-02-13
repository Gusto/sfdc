trigger HINPABPTrigger on HI_New_Plans_ApplicationsBenefitsPackage__c(after insert) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || HINPABPTriggerHelper.skipTrigger) {
		return;
	}

	new HINPABPTriggerHandler().run();
}