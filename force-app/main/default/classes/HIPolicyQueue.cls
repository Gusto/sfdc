public with sharing class HIPolicyQueue implements Queueable{
    
    private List<HI_Policy__c> policyList;
        
    public HIPolicyQueue(List<HI_Policy__c> inputPolicyList){
        policyList = inputPolicyList;
    }
    
    public void execute(QueueableContext context) {
        HIPolicyTriggerHelper.queue=true;
        if(policyList.size() > 0){ 
            update policyList;
        }
    }
}