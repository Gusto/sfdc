/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* Created by............: <<Lirik>>
* Test Classes----------: <<UR_ResearchIntegrationDataTgr>>
* Description...........: <<This Trigger is used to handle all data which is coming from third party related to Calendly and Qualtrics .>>
*-------------------------------------------------------------------------------*/
trigger UR_ResearchIntegrationDataTgr on Research_Integration_Data__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    UR_ResearchIntegrationDataTriggerHelper handler = new UR_ResearchIntegrationDataTriggerHelper();
    if(UR_ResearchIntegrationDataTriggerHelper.skipTrigger==false){ 
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