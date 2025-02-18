trigger MessagingSessionTrigger on MessagingSession (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to True
    if (FeatureManagement.checkPermission('Bypass_Triggers') || MessagingSessionTriggerHelper.skipTrigger) {
        return;
    }
    
    new MessagingSessionTriggerHandler().run();
}