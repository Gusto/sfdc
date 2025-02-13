public class ZPCompanyOnboardingQueue  implements Queueable {

    private List<ZP_Company_Onboarding_Funnel__c> companyList;
        
    public ZPCompanyOnboardingQueue(List<ZP_Company_Onboarding_Funnel__c> inputCompanyList){
        companyList = inputCompanyList;
    }
    
    public void execute(QueueableContext context) {
        ZPCompanyOnboardingFunnelTriggerHelper.queue=true; 
        if(companyList.size() > 0){ 
            update companyList;
        }
    }
}