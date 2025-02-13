trigger HICarrierTrigger on HI_Carrier__c (before insert, before update) {

    if (HICarrierTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HICarrierTriggerHelper().run();
}