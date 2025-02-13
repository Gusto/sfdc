/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* Created by............: <<Lirik>>
* Test Classes----------: <<UR_ResearchCSVDataTgr>>
* Description...........: <<This Trigger is used to upload CSV records.>>
*-------------------------------------------------------------------------------*/
trigger UR_ResearchCSVDataTgr on UXR_CSV_Staging__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    UR_ResearchCSVDataTriggerHelper handler = new UR_ResearchCSVDataTriggerHelper();
    if(UR_ResearchCSVDataTriggerHelper.skipTrigger==false){ 
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
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap, Trigger.new);
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