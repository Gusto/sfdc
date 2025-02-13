public with sharing class HICarrierInformationQueue  implements Queueable {

    private List<HI_Carrier_Information__c> carrierList;
	private Boolean isBoInsert;
     
    public HICarrierInformationQueue(List<HI_Carrier_Information__c> inputCarrierList, Boolean isInputBoInsert){
        carrierList = inputCarrierList;
        isBoInsert = isInputBoInsert; 
    }   
    
    public void execute(QueueableContext context) {
        HICarrierInformationTriggerHelper.queue=true;
        HICarrierInformationTriggerHelper.isBOInsert = isBoInsert;
        if(carrierList.size() > 0){ 
            update carrierList;
        }
    }
}