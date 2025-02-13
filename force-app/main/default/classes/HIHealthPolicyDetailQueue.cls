public with sharing class HIHealthPolicyDetailQueue implements Queueable{
    
    private List<HI_Health_Policy_Detail__c> policyList;
        
    public HIHealthPolicyDetailQueue(List<HI_Health_Policy_Detail__c> inputPolicyList){
        policyList = inputPolicyList;
    }
    
    public void execute(QueueableContext context) {
        HIHealthPolicyDetailTriggerHelper.queue=true;
        if(policyList.size() > 0){ 
            update policyList;
        }
    }
}