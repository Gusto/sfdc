trigger ZPCompanySuspensionTriggerHelper on ZP_Company_Suspension__c (before insert, after insert, before update, after update) {

    ZPCompanySuspensionTriggerHelper handler = new ZPCompanySuspensionTriggerHelper();
    
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new); 
    }
    else if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.newMap);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }    
}