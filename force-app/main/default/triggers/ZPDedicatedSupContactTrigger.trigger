trigger ZPDedicatedSupContactTrigger on ZP_Company_Dedicated_Support_Contact__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    ZPDedicatedSupContactTriggerHelper handler = new ZPDedicatedSupContactTriggerHelper();
        if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new); 
        }
        else if(Trigger.isInsert && Trigger.isAfter){
            handler.OnAfterInsert(Trigger.newMap);
        }
        else if(Trigger.isUpdate && Trigger.isBefore){
            handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
}