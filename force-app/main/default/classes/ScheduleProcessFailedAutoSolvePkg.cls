/**
* Author: Ankit Rajput
* Date: 21/12/2024
* Desc: Batch scheduler for BatchProcessFailedAutoSolvePkgCases class 
**/

global class ScheduleProcessFailedAutoSolvePkg implements Schedulable {
     global void execute(SchedulableContext sc) {
        Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
        Integer intBatch = objConfigSettings?.ProcessFailedAutoSolvePkgCasesBatch__c != null ? (Integer) objConfigSettings.ProcessFailedAutoSolvePkgCasesBatch__c : 20;

        BatchProcessFailedAutoSolvePkgCases objProcessFailedAutoSolvePkgCases = new BatchProcessFailedAutoSolvePkgCases(); 
        Database.executebatch(objProcessFailedAutoSolvePkgCases, intBatch);
    }
}