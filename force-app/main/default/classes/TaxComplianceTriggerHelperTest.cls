/**
 * @name         TaxComplianceTriggerHelper
 * @author       Sindhu
 * @date         06/28/2024
 * @description  Test Class for TaxComplianceTriggerHelper and TaxComplianceTriggerHandler
 **/
@isTest
public class TaxComplianceTriggerHelperTest {

   @TestSetup
    static void setupTestData() {
        Case objParentCase = TestDataFactory.createCaseRecord('Compliance', true);
        Case objChildCase = TestDataFactory.createCaseRecord('Compliance', true);
        Tax_Compliance__c objTaxCompliance = new Tax_Compliance__c();
        objTaxCompliance.Agency_Due_Date__c = System.Today();
        objTaxCompliance.Eng_Due_Date__c = System.Today().addDays(1);
        objTaxCompliance.System_impacted__c = 'Compliance Tracker';        
        objTaxCompliance.Case__c = objParentCase.Id;
        objTaxCompliance.Classification_Type__c = 'Compliance Requirement';
        objTaxCompliance.Compliance_Team_POC__c = '	Payroll Product Compliance';
        objTaxCompliance.Customer_Count__c = 20;
        objTaxCompliance.Resource_Link__c = 'https://www.google.com';
        objTaxCompliance.EPDD_DRI__c = UserInfo.getUserId();
        objTaxCompliance.Frequency_of_Update__c = 'One time Task';
        objTaxCompliance.System_impacted__c = 'Payments & Filings';
        objTaxCompliance.Impacts__c = 'Worker Payments';
        objTaxCompliance.CX_Comms__c = 'ABCD';
        objTaxCompliance.Help_Center_IKB_External__c = false;
        objTaxCompliance.Help_Center_IKB_Internal__c = 'https://www.google.com';
        objTaxCompliance.Knowledge_Management_Readiness__c = true;
        objTaxCompliance.Customer_Comms__c = 'BCS';
        objTaxCompliance.In_App_content__c = 'Test ABCD';
        objTaxCompliance.Eng_Status__c = 'In progress';
        objTaxCompliance.Follow_up_Date__c = System.Today();
        objTaxCompliance.Agency_Due_Date__c = System.Today().addDays(2);
        insert objTaxCompliance;
    }
    
    @isTest
    static void unitTestMethod() {
        
        // Parent case
        List<Case> list_Cases = [SELECT Id, Subject,Status, Description, Batch_Id__c, Agency_Information__r.Name, Compliance_Score__c, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 2];
        Case objParentCase = list_Cases[0];
        Case objChildCase = list_Cases[1];
        Tax_Compliance__c objTaxCompliance =  [SELECT Id, Compliance_Team_POC__c FROM  Tax_Compliance__c LIMIT 1];
        TaxComplianceTriggerHandler.resetSkipTriggerFlags();
        Test.startTest();
        // Tax_Compliance__c objTaxCompliance = mapTaxCompliance.values()[0];
        objTaxCompliance.Compliance_Team_POC__c = 'Symmetry Compliance';
        update objTaxCompliance;
        Test.stopTest();
    }   
}