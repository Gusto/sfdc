/*
 * Trigger on Order Facilitator Checklist
 * Created By : Neha Dabas
 * Created Date : 4 October 2019
 */
trigger OrderFacilitatorChecklistTrigger on Order_Facilitator_Checklist__c (before update,before insert) {
    
    OrderFacilitatorChecklistTriggerHelper helper = new OrderFacilitatorChecklistTriggerHelper();
    
    if(OrderFacilitatorChecklistTriggerHelper.skipTrigger == false){
    	//Before Update
    	if(Trigger.isUpdate && Trigger.isBefore){
    		helper.onBeforeUpdate(Trigger.new,Trigger.oldMap);
    	}
    	//Before Insert
    	if(Trigger.isInsert && Trigger.isBefore){
    		helper.onBeforeInsert(Trigger.new);
    	}
    }
}