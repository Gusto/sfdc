trigger CustomerHealthTrigger on Customer_Health__c (before insert, after insert, before update, after update) {
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to TRUE
    if (
        CustomerHealthTriggerHelper.skipTrigger ||
        FeatureManagement.checkPermission('Bypass_Triggers')
    ) {
        return;
    }

    new CustomerHealthTriggerHandler().run();
}