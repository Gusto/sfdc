/*
 * @name         AutoSolvePackageTriggerHelperTest
 * @author       Ankit Rajput
 * @date         07-16-2024
 * @description  This class is the test class of AutoSolvePackageTrigger, AutoSolvePackageTriggerHandler, AutoSolvePackageTriggerHelper
 */

@isTest
public class AutoSolvePackageTriggerHelperTest {
	
    @isTest
    public static void unitTestMethod() {
        Id autoSolveBatchRecordTypeId = Schema.getGlobalDescribe().get('Auto_Solve_Package__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Solve_Batch').getRecordTypeId();
        Agency_Information__c objAgencyInfo =	TestDataFactory.createOneAgencyInforation('Test Agency');
        Auto_Solve_Package__c objAutoSolvePackage = new Auto_Solve_Package__c();
        objAutoSolvePackage.Name = 'TestAutoSolvePackage';
        objAutoSolvePackage.Agency_Information__c = objAgencyInfo.Id;
        objAutoSolvePackage.Client_Ids__c = '4324234\n42342347\n42342378\n4234243\n787\n908\n98989';
        insert objAutoSolvePackage; 
        
        Auto_Solve_Package__c objPackage1 = [SELECT Id, Client_Ids_Count__c FROM Auto_Solve_Package__c ];
        System.assertEquals(objPackage1.Client_Ids_Count__c, 7, 'Seven Client Ids');
        
        objAutoSolvePackage.Client_Ids__c = '4324234\n42342347\n42342378\n4234243\n787\n908\n98989\n989';
        update objAutoSolvePackage;
        
        Auto_Solve_Package__c objPackage2 = [SELECT Id, Client_Ids_Count__c FROM Auto_Solve_Package__c ];
        System.assertEquals(objPackage2.Client_Ids_Count__c, 8, 'Eight Client Ids');
        
        TriggerBypass__c.getInstance().AutoSolvePackageTrigger__c = true;
        AutoSolvePackageTriggerHelper.skipTrigger =  true;
        update objAutoSolvePackage;
    }    
}