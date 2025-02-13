/**
 * @name         : ImportCSVDataControllerTest
 * @author       : Nigam Goyal
 * @date         : 12-08-2022
 * @description  : Cover test Coverage ImportCSVDataController
 **/
@isTest
public with sharing class ImportCSVDataControllerTest {

    @isTest
    public static void generateLeadTestDataCheck() {
    
        Test.startTest();   
        System.enqueueJob(new ImportCSVDataController.ImportGFLeadData());
        Test.stopTest();
        
        List<GF_Lead__c> listGFLeads = [SELECT Id FROM GF_Lead__c];
        //Assert list is not empty
        System.assert(!listGFLeads.isEmpty(),'listGFLeads should not be empty');
    }

    @isTest
    public static void generateZPAccountingFirmTestDataCheck() {
    
        Test.startTest();   
        System.enqueueJob(new ImportCSVDataController.ImportZPAccountingFirm());
        Test.stopTest();
        
        List<ZP_Accounting_Firm__c> listZPAccountingFirmCompanies= [SELECT Id FROM ZP_Accounting_Firm__c];
        //Assert list is not empty
        System.assert(!listZPAccountingFirmCompanies.isEmpty(),'listZPAccountingFirmCompanies should not be empty');
    }

    @isTest
    public static void generateAccountTestDataCheck() {
    
        Test.startTest();   
        System.enqueueJob(new ImportCSVDataController.ImportZPCompanyData());
        Test.stopTest();
        
        List<ZP_Company__c> listZPCompanies= [SELECT Id FROM ZP_Company__c];
        //Assert list is not empty
        System.assert(!listZPCompanies.isEmpty(),'listZPCompanies should not be empty');
    }

    @isTest
    public static void generateZPUserTestDataCheck() {
    
        Test.startTest();   
        System.enqueueJob(new ImportCSVDataController.ImportZPUserData());
        Test.stopTest();
        
        List<ZP_User__c> listZPUsers= [SELECT Id FROM ZP_User__c];
        //Assert list is not empty
        System.assert(!listZPUsers.isEmpty(),'listZPUsers should not be empty');
    }

    @isTest
    public static void generateZPUserRoleTestDataCheck() {
    
        Test.startTest();   
        System.enqueueJob(new ImportCSVDataController.ImportZPUserRoleData());
        Test.stopTest();
        
        List<ZP_User_Role__c> listZPUserRoles= [SELECT Id FROM ZP_User_Role__c];
        //Assert list is not empty
        System.assert(!listZPUserRoles.isEmpty(),' listZPUserRoles should not be empty');
    }
}