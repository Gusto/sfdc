trigger HIEventTrigger on HI_Event__e (after insert) {
    HIEventTriggerHandler.processHIEvents(Trigger.new);
}