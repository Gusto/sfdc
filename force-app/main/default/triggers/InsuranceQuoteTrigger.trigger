trigger InsuranceQuoteTrigger on Insurance_Quote__c(before insert, before update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || InsuranceQuoteTriggerHelper.blnSkipTrigger)
		return;

	new InsuranceQuoteTriggerHandler().run();
}