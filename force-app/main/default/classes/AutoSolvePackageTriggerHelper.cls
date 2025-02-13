/*
 * @name         AutoSolvePackageTriggerHelper
 * @author       Ankit Rajput
 * @date         07-16-2024
 * @description  This class contains all the method definitions which are called from different trigger contexts.
 * @test classes AutoSolvePackageTriggerHelperTest
 */
public class AutoSolvePackageTriggerHelper {

    public static boolean skipTrigger = false;
    
    public void processBeforeInsert(List<Auto_Solve_Package__c> list_AutoSolvePackage) {
        countNumberOfClientIds(list_AutoSolvePackage);
    }
    
    public void processBeforeUpdate(Map<Id, Auto_Solve_Package__c> map_OldAutoSolvePackage, Map<Id, Auto_Solve_Package__c> map_AutoSolvePackage) {
        countNumberOfClientIds(map_AutoSolvePackage.values());
    }
    
    public static void countNumberOfClientIds(List<Auto_Solve_Package__c> list_AutoSolvePackage) {
        
        for(Auto_Solve_Package__c objAutoSolvePackage : list_AutoSolvePackage) {
            Id autoSolveBatchRecordTypeId = Schema.getGlobalDescribe().get('Auto_Solve_Package__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Solve_Batch').getRecordTypeId();
            //objAutoSolvePackage.RecordTypeId == autoSolveBatchRecordTypeId && 
            if(objAutoSolvePackage.Client_Ids__c != null) {
                Integer numberOfNewLineChars = objAutoSolvePackage.Client_Ids__c.countMatches('\n');
                objAutoSolvePackage.Client_Ids_Count__c = numberOfNewLineChars + 1; 
            }
        }    
    }

}