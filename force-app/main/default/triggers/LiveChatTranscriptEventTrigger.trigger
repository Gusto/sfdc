trigger LiveChatTranscriptEventTrigger on LiveChatTranscriptEvent (after insert) {
    LiveChatTranscriptEventTriggerHelper objHelper = new LiveChatTranscriptEventTriggerHelper();
    if (!FeatureManagement.checkPermission('Bypass_Triggers') && LiveChatTranscriptEventTriggerHelper.skipTrigger == false) {
        if (Trigger.isInsert && Trigger.isAfter) {
            objHelper.OnAfterInsert(Trigger.newMap);
        }
    }
}