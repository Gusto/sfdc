/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* Created by............: <<Lirik>>
* Test Classes----------: <<UR_ProjectMasterTgr>>
* Description...........: <<This Trigger is used to handle all data operation like get Role Hierarchy, Update allowed participant etc .>>
*-------------------------------------------------------------------------------*/

trigger UR_ProjectMasterTgr on Research_Project_Master__c (before insert, after insert, before update, after update, before delete) {

    UR_ProjectMasterTriggerHelper handler = new UR_ProjectMasterTriggerHelper();
    if(UR_ProjectMasterTriggerHelper.skipTrigger==false){ 
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
       /* else if(Trigger.isDelete && Trigger.isAfter){
            handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
        }    
        else if(Trigger.isUnDelete){
            handler.OnUndelete(Trigger.new);  
        }*/
    }
        
}