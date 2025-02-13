public class HICarrierDetailQueue implements Queueable {

    private List<HI_Carrier_Detail__c> list_carrierDetail;
     
    public HICarrierDetailQueue(List<HI_Carrier_Detail__c> list_inputCarriers){
        list_carrierDetail = list_inputCarriers;
    }   
    
    public void execute(QueueableContext context) {
        HICarrierDetailTriggerHelper.queue=true;
        if(list_carrierDetail.size() > 0){ 
            update list_carrierDetail;
        }
    }
}