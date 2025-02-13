trigger HIBenefitChangeApplicationTrigger on HI_Benefit_Change_Application__c (before insert, before update, before delete, after undelete, after insert, after update, after delete) {

    HIBenefitChangeApplicationTriggerHelper handler = new HIBenefitChangeApplicationTriggerHelper(); 
    
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