/*
 * Created : June 19, 2020
 */
trigger ContentVersionTrigger on ContentVersion (before insert,after insert) {
    if(!ContentVersionTriggerHelper.skipTrigger){
        ContentVersionTriggerHelper helper = new ContentVersionTriggerHelper();
        if(Trigger.isInsert){
            if(Trigger.isBefore){
                helper.onBeforeInsert(trigger.new);
            }
        }
    }
}