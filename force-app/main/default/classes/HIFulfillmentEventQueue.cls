public with sharing class HIFulfillmentEventQueue implements Queueable{
    
    private List<HI_Fulfillment_Event__c> fulfillmentList;
        
    public HIFulfillmentEventQueue (List<HI_Fulfillment_Event__c> inputFulfillmentList){
        fulfillmentList = inputFulfillmentList;
    }
    
    public void execute(QueueableContext context) {
        HIFulfillmentEventTriggerHelper.queue=true;
        if(fulfillmentList.size() > 0){ 
            update fulfillmentList;
        }
    }
}