public with sharing class HIHSABenefitQueue implements Queueable{
    
    private List<HI_HSA_Benefit__c> benefitList;
        
    public HIHSABenefitQueue(List<HI_HSA_Benefit__c> inputBenefitList){
        benefitList = inputBenefitList;
    }
    
    public void execute(QueueableContext context) {
        HIHSABenefitTriggerHelper.queue=true;
        if(benefitList.size() > 0){ 
            update benefitList;
        }
    }
}