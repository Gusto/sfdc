trigger SalesCallTrackingTrigger on Sales_Call_Tracking__c (before insert, after insert, before update, after update) {
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
    if(FeatureManagement.checkPermission('Bypass_Triggers') || SalesCallTrackingTriggerHelper.skipTrigger)
        return;
    else
        new SalesCallTrackingTriggerHandler().run();
}