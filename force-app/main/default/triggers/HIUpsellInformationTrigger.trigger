trigger HIUpsellInformationTrigger on HI_Upsell_Information__c(after insert, after update, before insert, before update) {
	if (HIUpsellInformationTriggerHelper.skipTrigger || FeatureManagement.checkPermission('Bypass_Triggers')) {
		return;
	}

	new HIUpsellInformationTriggerHandler().run();
}