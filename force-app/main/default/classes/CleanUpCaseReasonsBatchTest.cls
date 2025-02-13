/**
* @Author       :   Pradeep Chary
* @CreatedDate  :   11/22/2022
* @Desc         :   Test class for BatchCleanUpCaseReasonClassifications
**/
@isTest
public class CleanUpCaseReasonsBatchTest {
    
    @TestSetup
    static void setup() {
        AccountTriggerHelper.skipTrigger = true;
        ContactTriggerHelper.skipTrigger = true;
        CaseTriggerHelper.skipTrigger = true;
        
        Account objAccount = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account Test Builder')
            .setZPCompanyId('1111111111')
            .build();
        insert objAccount;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
            .setRecordTypeId('Company')
            .setAccountId(objAccount.Id)
            .setFirstName('First Name1')
            .setLastName('Last Name1')
            .setEmail('testuser1@firstcontact.com')
            .build();
        insert objContact;
        
        //Creating Case Reason Classifications
        List<Case_Reason_Classification__c> list_CaseReasonClassifications = new List<Case_Reason_Classification__c>();
        Case_Reason_Classification__c objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder()
            .setName('IRS/State Notice')
            .setClass('Class 1')
            .setIsActive(true)
            .setType('Payroll Care')
            .build();
        list_CaseReasonClassifications.add(objCaseReasonClassification);
        
        Case_Reason_Classification__c objCaseReasonClassification2 = new TestDataFactory.CaseReasonClassificationBuilder()
            .setName('IRS/State Notice')
            .setClass('Class 1')
            .setIsActive(false)
            .setType('Payroll Care')
            .build();
        list_CaseReasonClassifications.add(objCaseReasonClassification2);
        
        insert list_CaseReasonClassifications;
        
        List<Case> list_Cases = new List<Case>();
        Case objCase = new TestDataFactory.CaseBuilder()
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setRecordTypeId('Payroll Care')
            .setType('Payroll Care')
            .setSubject('Test Duplicate Case')
            .setOrigin('Email')
            .setDirection('Inbound')
            .setStatus('New')
            .setSuppliedEmail('pradeeptest@acme.com')
            .setDescription('Test Duplicate Case')
            .build();
        objCase.Routing_Case_Reason_Classification__c = objCaseReasonClassification2.Id;
        objCase.Confirm_Case_Reason_Classification__c = objCaseReasonClassification2.Id;
        list_Cases.add(objCase);
        
        Case objCase2 = new TestDataFactory.CaseBuilder()
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setRecordTypeId('Payroll Care')
            .setType('Payroll Care')
            .setSubject('Test Require Action')
            .setOrigin('Email')
            .setDirection('Inbound')
            .setStatus('New')
            .setSuppliedEmail('pradeepchary@acme.com')
            .setDescription('Test Require Action')
            .build();
        objCase.Routing_Case_Reason_Classification__c = objCaseReasonClassification2.Id;
        objCase.Confirm_Case_Reason_Classification__c = objCaseReasonClassification2.Id;
        list_Cases.add(objCase2);
        
        insert list_Cases;
        
        AccountTriggerHelper.skipTrigger = false;
        ContactTriggerHelper.skipTrigger = false;
        CaseTriggerHelper.skipTrigger = false;
    }
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Test method for replace Routing_Case_Reason_Classification__c duplicate values
    **/
    @isTest
    static void CleanUpMethodTestOne() {
        Test.startTest();
        
        Case_Reason_Classification__c objCaseReasonClassificationActive = [SELECT Id FROM Case_Reason_Classification__c WHERE Active__c = true LIMIT 1];
        Case_Reason_Classification__c objCaseReasonClassificationInActive = [SELECT Id FROM Case_Reason_Classification__c WHERE Active__c = false LIMIT 1];
        
        CleanUpCaseReasonClassificationsBatch objCleanUpCaseReasonClassificationsBatch = new CleanUpCaseReasonClassificationsBatch(
            objCaseReasonClassificationActive.Id,
            objCaseReasonClassificationInActive.Id,
            'Routing_Case_Reason_Classification__c'
        );
        Database.executeBatch(objCleanUpCaseReasonClassificationsBatch);
        
        Test.stopTest();
        
        List<Case> list_Cases = [SELECT Id, Routing_Case_Reason_Classification__c FROM Case LIMIT 2];
        System.assertEquals(list_Cases[0].Routing_Case_Reason_Classification__c, objCaseReasonClassificationActive.Id);
    }
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Test method for replace Confirm_Case_Reason_Classification__c duplicate values
    **/
    @isTest
    static void CleanUpMethodTestTwo() {
        Test.startTest();
        
        Case_Reason_Classification__c objCaseReasonClassificationActive = [SELECT Id FROM Case_Reason_Classification__c WHERE Active__c = true LIMIT 1];
        Case_Reason_Classification__c objCaseReasonClassificationInActive = [SELECT Id FROM Case_Reason_Classification__c WHERE Active__c = false LIMIT 1];
        
        CleanUpCaseReasonClassificationsBatch objCleanUpCaseReasonClassificationsBatch = new CleanUpCaseReasonClassificationsBatch(
            objCaseReasonClassificationActive.Id,
            objCaseReasonClassificationInActive.Id,
            'Confirm_Case_Reason_Classification__c'
        );
        Database.executeBatch(objCleanUpCaseReasonClassificationsBatch);
        
        Test.stopTest();
        
        List<Case> list_Cases = [SELECT Id, Confirm_Case_Reason_Classification__c FROM Case LIMIT 2];
        System.assertEquals(list_Cases[0].Confirm_Case_Reason_Classification__c, objCaseReasonClassificationActive.Id);
    }
}