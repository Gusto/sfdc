trigger HIGroupEventTrigger on HIGroupEvent__c (after delete, after insert, after undelete, 
                                                after update, before delete, before insert, before update) 
{
    HIGroupEventTriggerHelper objTriggerHelper=new HIGroupEventTriggerHelper();
    if(HIGroupEventTriggerHelper.skipTrigger==false){
        switch on Trigger.operationType 	{
            when BEFORE_INSERT {
                objTriggerHelper.OnBeforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                objTriggerHelper.OnBeforeUpdate(Trigger.oldmap,trigger.new);
            }  
            when BEFORE_DELETE {
                //prevent deletion of sensitive data
            }
            when AFTER_INSERT{
                objTriggerHelper.OnAfterInsert(Trigger.new);
            }
            when AFTER_UPDATE {
                 objTriggerHelper.OnAfterUpdate(Trigger.oldMap, Trigger.new);
            }
            
            when AFTER_DELETE {
                //prevent deletion of sensitive data
            }
            when else {
                //do nothing for AFTER_UNDELETE, BEFORE_DELETE, or BEFORE_UPDATE
            }
        } 
    }    
    
    
}