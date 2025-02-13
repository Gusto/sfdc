public with sharing class HIAasmEventQueue implements Queueable{
    
    private List<HI_Aasm_Event__c> eventList;
        
    public HIAasmEventQueue(List<HI_Aasm_Event__c> inputEventList){
        eventList = inputEventList;
    }
    
    public void execute(QueueableContext context) {
        HIAasmEventTriggerHelper.queue=true;
        if(eventList.size() > 0){ 
            update eventList;
        }
    }
}