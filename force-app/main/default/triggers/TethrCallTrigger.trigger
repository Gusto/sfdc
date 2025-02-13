trigger TethrCallTrigger on Tethr__Tethr_Call__c (before insert) {
    
    
    // Check if the logged-in user has custom permissions to bypass triggers
    // or if the static variable blnSkipTrigger is set to true.
    // If either condition is true, the trigger execution is bypassed.
    if (!FeatureManagement.checkPermission('Bypass_Triggers') && !TethrCallTriggerHandler.blnSkipTrigger) {
        new TethrCallTriggerHandler().run();
    }
}