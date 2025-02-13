public with sharing class HILiDiPolicyDetailQueue implements Queueable{
    private List<HI_LiDi_Policy_Detail__c> policyList;
        
    public HILiDiPolicyDetailQueue(List<HI_LiDi_Policy_Detail__c> inputPolicyList){
        policyList = inputPolicyList;
    }
    
    public void execute(QueueableContext context) {
        HILiDiPolicyDetailTriggerHelper.queue=true;
        if(policyList.size() > 0){ 
            update policyList;
        }
    }
}