trigger HIBenefitsAdminTrigger on HI_Benefits_Admin__c ( after insert, after update, before insert, before update) {

    if (HIBenefitsAdminTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }
    
    new HIBenefitsAdminTriggerHelper().run();
}