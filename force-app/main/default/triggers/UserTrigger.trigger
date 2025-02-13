trigger UserTrigger on User (before update, after update) {

    UserTriggerHelper handler = new UserTriggerHelper();
    if(UserTriggerHelper.skipTrigger==false){
        if(Trigger.isUpdate && Trigger.isBefore){
            handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        } 
    }
}