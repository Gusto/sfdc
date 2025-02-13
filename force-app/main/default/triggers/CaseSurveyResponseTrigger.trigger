trigger CaseSurveyResponseTrigger on Case_Survey_Response__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    CaseSurveyResponseTriggerHelper handler = new CaseSurveyResponseTriggerHelper();
    if(CaseSurveyResponseTriggerHelper.skipTrigger==false){
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
        else if(Trigger.isDelete && Trigger.isBefore){
            handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
        }
        else if(Trigger.isDelete && Trigger.isAfter){
            handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
        }    
        else if(Trigger.isUnDelete){
            handler.OnUndelete(Trigger.new);  
        }
    }
    
}