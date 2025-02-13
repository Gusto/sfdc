trigger HIAasmEventTrigger on HI_Aasm_Event__c (after insert, after update, before insert, before update) {

    if (HIAasmEventTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HIAasmEventTriggerHelper().run();
}