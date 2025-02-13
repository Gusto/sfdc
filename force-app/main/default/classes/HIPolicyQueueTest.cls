@isTest
private class HIPolicyQueueTest {

    static testMethod void hiPolicyQueueTest1() {
        HI_Policy__c hiPolicyRec = new HI_Policy__c();
        hiPolicyRec.id__c = 'Test321';
        insert hiPolicyRec;
        
        list<HI_Policy__c> policyList = new list<HI_Policy__c>();
        policyList.add(hiPolicyRec);
        
        Test.startTest();
        HIPolicyQueue updateJob = new HIPolicyQueue(policyList);
        ID jobID = System.enqueueJob(updateJob);
        system.assert(jobID!=null);
        /*if(jobID != null){
        	system.assert(string.valueof(jobID).length()>0);
        }*/
        Test.stopTest();
    }
}