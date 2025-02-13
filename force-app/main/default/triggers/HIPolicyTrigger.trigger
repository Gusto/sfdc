trigger HIPolicyTrigger on HI_Policy__c (after insert, after update, before insert, before update) {

    if (HIPolicyTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HIPolicyTriggerHelper().run();
}