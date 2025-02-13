trigger HINewPlansApplicationTrigger on HI_New_Plans_Application__c (after insert, after update, before insert, before update) {

    if (HINewPlansApplicationTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HINewPlansApplicationTriggerHelper().run();
}