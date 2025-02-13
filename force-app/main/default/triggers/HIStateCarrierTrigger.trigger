trigger HIStateCarrierTrigger on HI_State_Carrier__c (before insert, before update) {
    
    HIStateCarrierTriggerHelper handler = new HIStateCarrierTriggerHelper(); 
    
    if (Trigger.isInsert && Trigger.isBefore) {
        handler.OnBeforeInsert(Trigger.new); 
    } else if(Trigger.isUpdate && Trigger.isBefore) {
        handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}