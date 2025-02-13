trigger HIBenefitApplicationUserTrigger on HI_Benefit_Application_User__c (before insert, before update) {
    if (HIBenefitApplicationUserTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }
    
    new HIBenefitApplicationUserTriggerHelper().run();    
}