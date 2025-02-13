trigger HICarrierInformationTrigger on HI_Carrier_Information__c (after insert, after update, before insert, before update) {

    if (HICarrierInformationTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HICarrierInformationTriggerHelper().run();
}