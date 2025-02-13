trigger ZPAccountantSurveyResponseTrigger on ZP_Accountant_Survey_Response__c(after delete, after insert, after undelete, after update, before delete, before insert, before update){
    ZPAccountantSurveyResponseTriggerHelper handler = new ZPAccountantSurveyResponseTriggerHelper();
    
    if(ZPAccountantSurveyResponseTriggerHelper.skipTrigger == false){
        if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new); 
        }else if(Trigger.isInsert && Trigger.isAfter){
            handler.OnAfterInsert(Trigger.newMap);
        }else if(Trigger.isUpdate && Trigger.isBefore){
            handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }else if(Trigger.isUpdate && Trigger.isAfter){
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}