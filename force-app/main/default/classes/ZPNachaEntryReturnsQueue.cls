public with sharing class ZPNachaEntryReturnsQueue implements Queueable {

    private List<ZP_Nacha_Entry_Returns__c> nachaReturnsList;
        
    public ZPNachaEntryReturnsQueue(List<ZP_Nacha_Entry_Returns__c> nachaList){
        nachaReturnsList = nachaList;
    }  
    
    public void execute(QueueableContext context) {
        ZPNachaEntryReturnsTriggerHelper.queue=true; 
        if(nachaReturnsList.size() > 0){ 
            update nachaReturnsList;
        }
    }
}