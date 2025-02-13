trigger LiveChatTranscriptTrigger on LiveChatTranscript (after delete, after insert, after undelete, 
    after update, before delete, before insert, before update) {

    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to True
    if (FeatureManagement.checkPermission('Bypass_Triggers') || LiveChatTranscriptTriggerHelper.skipTrigger) {
        return;
    }
   
   LiveChatTranscriptTriggerHelper handler = new LiveChatTranscriptTriggerHelper();
   
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
    /*else if(Trigger.isDelete && Trigger.isBefore){
        handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
    else if(Trigger.isDelete && Trigger.isAfter){
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }    
    else if(Trigger.isUnDelete){
        handler.OnUndelete(Trigger.new);  
    }*/
}