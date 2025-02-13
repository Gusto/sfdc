public with sharing class HIBenefitSignatoryQueue  implements Queueable {

    private List<HI_Benefits_Signatory__c> signatoryList;
        
    public HIBenefitSignatoryQueue(List<HI_Benefits_Signatory__c> inputSignatoryList){
        signatoryList = inputSignatoryList;
    }
    
    public void execute(QueueableContext context) {
        HIBenefitSignatoryTriggerHelper.queue=true;
        if(signatoryList.size() > 0){ 
            update signatoryList; 
        }
    }
}