/*
 * @name         AutoSolvePackageTrigger
 * @author       Ankit Rajput
 * @date         07-16-2024
 * @description  This is the trigger for Auto_Solve_Package__c custom object
 * @test classes AutoSolvePackageTriggerHelperTest
 */
trigger AutoSolvePackageTrigger on Auto_Solve_Package__c (before insert, before update) {
	
    if( AutoSolvePackageTriggerHelper.skipTrigger || TriggerBypass__c.getInstance().AutoSolvePackageTrigger__c) {
        return;
    }
    new AutoSolvePackageTriggerHandler().run();
}