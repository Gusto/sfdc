trigger HICommuterBenefitTrigger on HI_Commuter_Benefits__c (after insert, after update, before insert, before update) {

    if (HICommuterBenefitTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HICommuterBenefitTriggerHelper().run();
}