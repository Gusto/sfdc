trigger PolicyTrigger on Policy__c (after insert, after update, after delete,before update, before insert) {

    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False Or Distribution Engine runs an update
    if (PolicyHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }
    
    new PolicyHelper().run();
}