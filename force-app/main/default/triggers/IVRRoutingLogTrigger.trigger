trigger IVRRoutingLogTrigger on IVR_Routing_Log__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    IVRRoutingLogTriggerHelper helper = new IVRRoutingLogTriggerHelper();
    if(IVRRoutingLogTriggerHelper.skipTrigger == false){
        if(Trigger.isInsert && Trigger.isBefore){
            helper.OnBeforeInsert(Trigger.new); 
        }
        // else if(Trigger.isInsert && Trigger.isAfter){
        //     helper.OnAfterInsert(Trigger.newMap);
        // }
        else if(Trigger.isUpdate && Trigger.isBefore){
            helper.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            helper.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }    
        // else if(Trigger.isDelete && Trigger.isBefore){
        //     helper.OnBeforeDelete(Trigger.old, Trigger.oldMap);
        // }
        // else if(Trigger.isDelete && Trigger.isAfter){
        //     helper.OnAfterDelete(Trigger.old, Trigger.oldMap);
        // }    
        // else if(Trigger.isUnDelete){
        //     helper.OnUndelete(Trigger.new);  
        // }
    }
}