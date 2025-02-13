/**
* @name         UserRoleTrigger
* @Created By   Anand Singh
* @Modify By    Bhagat Singh 31 July 2020
* @description  On change of User_Skill_Team__c, this trigger will assigned or removed user permissions.
*/
trigger UserRoleTrigger on User_Role__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
 	UserRoleTriggerHelper handler = new UserRoleTriggerHelper();
    if(UserRoleTriggerHelper.skipTrigger==false){ 
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
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.new);
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