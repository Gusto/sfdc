trigger SalesCaseEmailLeadQueueTrigger on Sales_Case_Email_Lead_Queue__c (before insert, before update, after insert, after update) {

    SalesCaseEmailLeadQueueTriggerHelper handler = new SalesCaseEmailLeadQueueTriggerHelper();
    if(caseTriggerHelper.skipTrigger==false){
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
}