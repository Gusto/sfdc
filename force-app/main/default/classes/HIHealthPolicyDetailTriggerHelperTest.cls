@isTest
public with sharing class HIHealthPolicyDetailTriggerHelperTest {
    
    @TestSetup
    static void dataSetup(){
        HI_Policy__c policyRec = new HI_Policy__c();
        policyRec.Id__c = '111';
        policyRec.Policy_Detail_Id__c = '111';
        policyRec.Policy_Detail_Type__c = 'HealthPolicyDetail';
        policyRec.State__c = 'CA';
        policyRec.Benefits_Package_Id__c = '333';
        policyRec.External_Key__c = 'hawaiian_ice-policy-62917';
        insert policyRec;
    }

    @isTest
    static void createEditHealthPolicy(){
        test.startTest();
            HI_Health_Policy_Detail__c objHealth = new HI_Health_Policy_Detail__c();
            objHealth.Id__c = '111'; 
            objHealth.Group_Number__c = '222';       
            objHealth.External_Key__c = 'hawaiian_ice-health_policy_detail-111';
            objHealth.State__c = 'CA';
            insert objHealth;
        test.stopTest();

        list<HI_Policy__c> lst_policy = [select id,Group_Number__c from HI_Policy__c where Policy_Detail_Id__c=: objHealth.Id__c];
        
        if(lst_policy.size()>0)
        //System.assert(lst_policy.get(0).Group_Number__c == objHealth.Group_Number__c);

        update objHealth;
    }

    @isTest
    static void deleteHealthPolicy(){
        HI_Health_Policy_Detail__c objHealth = new HI_Health_Policy_Detail__c();
        objHealth.Id__c = '111'; 
        objHealth.Group_Number__c = '222';       
        objHealth.External_Key__c = 'hawaiian_ice-health_policy_detail-111';
        objHealth.State__c = 'CA';
        HIHealthPolicyDetailTriggerHelper.queue = true;
        insert objHealth;

        delete objHealth;

        list<HI_Health_Policy_Detail__c> lst_health = [SELECT Id FROM HI_Health_Policy_Detail__c WHERE  Id__c =: objHealth.Id__c];
        system.assert(lst_health.size()==0);
    }
}