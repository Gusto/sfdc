trigger HIHSABenefitTrigger on HI_HSA_Benefit__c (after insert, after update, before insert, before update) {
    
    if (HIHSABenefitTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HIHSABenefitTriggerHelper().run();
}