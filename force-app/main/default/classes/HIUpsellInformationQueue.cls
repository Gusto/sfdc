public with sharing class HIUpsellInformationQueue  implements Queueable {

    private List<HI_Upsell_Information__c> adminList;
        
    public HIUpsellInformationQueue(List<HI_Upsell_Information__c> inputAdminList){ 
        adminList = inputAdminList;
    }
    
    public void execute(QueueableContext context) {
        HIUpsellInformationTriggerHelper.queue=true; 
        if(adminList.size() > 0){ 
            update adminList; 
        }
    }
}