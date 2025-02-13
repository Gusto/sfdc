public class HICarrierVersionQueue implements Queueable {

    private List<HICarrierVersionDetail__c> list_HICarrierVersion;
        
    public HICarrierVersionQueue(List<HICarrierVersionDetail__c> list_HICarrierVersion){
        this.list_HICarrierVersion = list_HICarrierVersion;
    }
    
    public void execute(QueueableContext context) {
        HICarrierVersionDetailTriggerHandler.blnQueue=true;
        if(list_HICarrierVersion.size() > 0){ 
            update list_HICarrierVersion; 
        }
    }
}