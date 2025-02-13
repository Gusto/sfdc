trigger HIFulfillmentEventTrigger on HI_Fulfillment_Event__c (after insert, after update, before insert, before update) {

    if (HIFulfillmentEventTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HIFulfillmentEventTriggerHelper().run();
}