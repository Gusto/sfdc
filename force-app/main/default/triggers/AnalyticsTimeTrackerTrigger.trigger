trigger AnalyticsTimeTrackerTrigger on Analytics_Time_Tracker__c (after insert, after update, before insert, before update) {

    AnalyticsTimeTrackerTriggerHelper handler = new AnalyticsTimeTrackerTriggerHelper();
    if(UserTriggerHelper.skipTrigger==false){
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
    }
}