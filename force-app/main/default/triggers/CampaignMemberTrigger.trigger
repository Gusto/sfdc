/**
 * @description  Trigger on Campaign Member. Delegates control to CampaignMemberTriggerHelper.
 * @author       Praveen Sethu
 * @date         03-30-2022
 * @see          CampaignMemberTriggerHelperTest
 **/
trigger CampaignMemberTrigger on CampaignMember (before insert, after insert, before update, after update,after delete) {
    try {
        CampaignMemberTriggerHelper objHandler = new CampaignMemberTriggerHelper();
        if(!CampaignMemberTriggerHelper.skipTrigger){
            if(Trigger.isInsert && Trigger.isBefore){
                objHandler.onBeforeInsert(Trigger.new); 
            } else if(Trigger.isInsert && Trigger.isAfter){
                objHandler.onAfterInsert(Trigger.new);
            } else if(Trigger.isUpdate && Trigger.isBefore){
                objHandler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
            } else if(Trigger.isUpdate && Trigger.isAfter){
                objHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
            } 
        }
    } catch(Exception objEx) {
        ExceptionLogUtil.logException('CampaignMemberTrigger', 'trigger', null, objEx);
    }
}