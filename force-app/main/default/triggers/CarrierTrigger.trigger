trigger CarrierTrigger on Carrier__c (before insert, after insert, before update) {
    if (CarrierTriggerHelper.skipTrigger)
        return;
    
    CarrierTriggerHelper handler = new CarrierTriggerHelper();

    if (Trigger.isInsert && Trigger.isBefore) {
        handler.onBeforeInsert(Trigger.New);
    } else if (Trigger.isInsert && Trigger.isAfter) {
        handler.OnAfterInsert(Trigger.New, Trigger.newMap);
    } else if (Trigger.isUpdate && Trigger.isBefore) {
        handler.onBeforeUpdate(Trigger.New, Trigger.oldMap);
    }
}