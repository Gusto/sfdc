public with sharing class HICommuterBenefitQueue implements Queueable{
    
    private List<HI_Commuter_Benefits__c> benefitList;
        
    public HICommuterBenefitQueue(List<HI_Commuter_Benefits__c> inputBenefitList){
        benefitList = inputBenefitList;
    }
    
    public void execute(QueueableContext context) {
        HICommuterBenefitTriggerHelper.queue=true;
        if(benefitList.size() > 0){ 
            update benefitList;
        }
    }
}