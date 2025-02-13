trigger CustomEmailMessageTrigger on Email_Message__c (before insert, after insert, before update, after update) {
    CustomEmailMessageTriggerHelper objHandler = new CustomEmailMessageTriggerHelper();
    
    if (CustomEmailMessageTriggerHelper.skipTrigger == false) {
        if (Trigger.isInsert && Trigger.isBefore) {
            objHandler.onBeforeInsert(Trigger.new);
        } else if(Trigger.isInsert && Trigger.isAfter) {
            objHandler.OnAfterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate && Trigger.isBefore) {
            objHandler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        } 
    }
}