/**
 * The TethrEventTrigger is a trigger on the Tethr__Tethr_Event__c object.
 * It handles the after insert context for Tethr events.
 * Test class: TethrEventTriggerHelperTest
 */
trigger TethrEventTrigger on Tethr__Tethr_Event__c (after insert) {

    // Check if the logged-in user has custom permissions to bypass triggers
    // or if the static variable blnSkipTrigger is set to true.
    // If either condition is true, the trigger execution is bypassed.
    if (FeatureManagement.checkPermission('Bypass_Triggers') || TethrEventTriggerHandler.blnSkipTrigger) {
    } else {
        // Create an instance of the TethrEventTriggerHandler and run it.
        // The handler will process the after insert logic for Tethr events.
        new TethrEventTriggerHandler().run();
    }

    
}