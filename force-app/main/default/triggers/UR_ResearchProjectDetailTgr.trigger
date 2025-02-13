/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* Created by............: <<Lirik>>
* Test Classes----------: <<UR_ResearchProjectDetailTgr>>
* Description...........: <<This Trigger is used to manage all prticipant like update incentive amount, Status , project Status etc .>>
*-------------------------------------------------------------------------------*/

trigger UR_ResearchProjectDetailTgr on Research_Project_Detail__c (before insert, after insert, before update, after update, before delete, after delete) {

    UR_ResearchProjectDetailTriggerHelper handler = new UR_ResearchProjectDetailTriggerHelper();
    if(UR_ResearchProjectDetailTriggerHelper.skipTrigger==false){ 
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