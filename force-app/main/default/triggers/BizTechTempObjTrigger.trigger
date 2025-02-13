trigger BizTechTempObjTrigger on BizTech_Temp_Obj__c (after update) {
    
    if(BizTechTempObjTriggerHandler.skipTrigger==false){
        BizTechTempObjTriggerHandler handler = new BizTechTempObjTriggerHandler();
        if (Trigger.isUpdate && Trigger.isAfter){
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}