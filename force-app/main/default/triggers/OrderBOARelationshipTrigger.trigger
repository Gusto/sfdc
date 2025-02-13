trigger OrderBOARelationshipTrigger on Order_BOA_Relationship__c (before insert,after insert, before Update, after update, before delete) {
	
    if(!OrderBOARelationshipTriggerHelper.skipTrigger){
        OrderBOARelationshipTriggerHelper handler = new OrderBOARelationshipTriggerHelper();
        
        if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new); 
        }
        else if(Trigger.isInsert && Trigger.isAfter){
            handler.OnAfterInsert(Trigger.New);
        }
        else if(Trigger.isUpdate && Trigger.isBefore){
            //handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            //handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        else if(trigger.isDelete && trigger.isBefore){
            handler.onBeforeDelete(trigger.Old);
        }
    }
}