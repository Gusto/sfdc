trigger CarrierVersionDetailTrigger on Carrier_Version_Detail__c (before insert, after insert, before update, after update) {

    CarrierVersionDetailTriggerHelper objHandler = new CarrierVersionDetailTriggerHelper();
    if(!UtilitiesFactory.isOverride('CarrierVersionDetailTrigger') || CarrierVersionDetailTriggerHelper.blnSkipTrigger==false){
         if(Trigger.isInsert && Trigger.isBefore){
            objHandler.OnBeforeInsert(Trigger.new); 
        }
        else if(Trigger.isInsert && Trigger.isAfter){
            objHandler.OnAfterInsert(Trigger.new);
        }
        else if(Trigger.isUpdate && Trigger.isBefore){ 
            objHandler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        } 
        else if(Trigger.isUpdate && Trigger.isAfter){
            objHandler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        } 
    }
}