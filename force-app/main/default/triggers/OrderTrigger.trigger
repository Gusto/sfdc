trigger OrderTrigger on Order (before insert, after insert, before update, after update) {

    if (OrderTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new OrderTriggerHelper().run();
}