/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* Created by............: <<Lirik>>
* Test Classes----------: <<UR_ResearchUploadInfoTgr>>
* Description...........: <<This Trigger is used to manage blacklist and opyout contact and related data based on some criteria .>>
*-------------------------------------------------------------------------------*/
trigger UR_ResearchUploadInfoTgr on Research_Upload_Info__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    UR_ResearchUploadInfoTriggerHelper handler = new UR_ResearchUploadInfoTriggerHelper();
    if(UR_ResearchUploadInfoTriggerHelper.skipTrigger==false){ 
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