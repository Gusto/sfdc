trigger HIStateTrigger on HI_State__c (before insert, before update) {
    
    HIStateTriggerHelper handler = new HIStateTriggerHelper(); 
    if (HIStateTriggerHelper.skipTrigger) {
        return;
    }
    
    if (Trigger.isInsert && Trigger.isBefore) {
        handler.OnBeforeInsert(Trigger.new); 
    } else if (Trigger.isUpdate && Trigger.isBefore) {
        handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }   
}