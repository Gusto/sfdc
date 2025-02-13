@isTest
public with sharing class HILiDiPolicyDetailTriggerHelperTest {
    
    @TestSetup
    static void dataCreation(){
        HI_Policy__c policyRec = new HI_Policy__c();
        policyRec.Id__c = '111';
        policyRec.Policy_Detail_Id__c = '111';
        policyRec.Policy_Detail_Type__c = 'LiDiPolicyDetail';
        policyRec.State__c = 'CA';
        policyRec.Benefits_Package_Id__c = '333';
        policyRec.External_Key__c = 'hawaiian_ice-policy-62917';
        insert policyRec;
    }

    @isTest
    static void createUpdateLiDiRecord(){
        test.startTest();
            HI_LiDi_Policy_Detail__c objLidi = new HI_LiDi_Policy_Detail__c();
            objLidi.Id__c = '111'; 
            objLidi.Group_Number__c = '222';       
            objLidi.External_Key__c = 'hawaiian_ice-li_di_policy_detail-129';
            objLidi.Elimination_Period__c = 90;
            objLidi.State__c = 'CA';
            insert objLidi;
        test.stopTest();

        list<HI_Policy__c> lst_policy = [select id,Group_Number__c from HI_Policy__c where Policy_Detail_Id__c=: objLidi.Id__c];
        
        if(lst_policy.size()>0)
        System.assert(lst_policy.get(0).Group_Number__c == objLidi.Group_Number__c);

        update objLidi;

        
    }

    @isTest
    static void deleteLiDiRecord(){
        HI_LiDi_Policy_Detail__c objLidi = new HI_LiDi_Policy_Detail__c();
        objLidi.Id__c = '111'; 
        objLidi.Group_Number__c = '222';       
        objLidi.External_Key__c = 'hawaiian_ice-li_di_policy_detail-129';
        objLidi.Elimination_Period__c = 90;
        objLidi.State__c = 'CA';
        HILiDiPolicyDetailTriggerHelper.queue = true;
        insert objLidi;

        delete objLidi;

        list<HI_LiDi_Policy_Detail__c> lst_lidi = [SELECT Id FROM HI_LiDi_Policy_Detail__c WHERE  Id__c =: objLidi.Id__c];
        system.assert(lst_lidi.size()==0);
    }


    
}