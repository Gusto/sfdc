public with sharing class HIBenefitsAdminQueue  implements Queueable {

    private List<HI_Benefits_Admin__c> adminList;
        
    public HIBenefitsAdminQueue(List<HI_Benefits_Admin__c> inputAdminList){
        adminList = inputAdminList;
    }
    
    public void execute(QueueableContext context) {
        HIBenefitsAdminTriggerHelper.queue=true;
        if(adminList.size() > 0){ 
            update adminList; 
        }
    }
}