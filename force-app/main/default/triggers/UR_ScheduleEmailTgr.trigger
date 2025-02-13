/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* Created by............: <<Lirik>>
* Trigger----------: <<UR_ScheduleEmailTgr>>
* Description...........: <<This Trigger is used to update schedule email date time.>>
*-------------------------------------------------------------------------------*/
trigger UR_ScheduleEmailTgr on Research_Schedule_Email__c (after delete, after update) {

    UR_ScheduleEmailTriggerHelper handler = new UR_ScheduleEmailTriggerHelper();
    if(UR_ScheduleEmailTriggerHelper.skipTrigger==false){ 
        if(Trigger.isUpdate && Trigger.isAfter){
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap, Trigger.new);
        }             
    }
}