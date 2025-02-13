public with sharing class HICompanyActiveBenefitsQueue implements Queueable{
    
    private List<HI_Company_Active_Benefits__c> benefitsList;
        
    public HICompanyActiveBenefitsQueue (List<HI_Company_Active_Benefits__c> inputBenefitsList){
        benefitsList = inputBenefitsList;
    }
    
    public void execute(QueueableContext context) {
        HICompanyActiveBenefitsTriggerHelper.queue=true;
        if(benefitsList.size() > 0){ 
            update benefitsList;
        }
    }
}