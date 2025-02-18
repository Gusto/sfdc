/**
 * @author      Ankit Rajput
 * @description It fetches all automation failed cases and updates their automation status as started.
 * Date: 20/12/2024
 **/

public with sharing class BatchProcessFailedAutoSolvePkgCases  implements Database.Batchable<sObject> {
    public String strQueryUsed;
    public Database.QueryLocator start(Database.Batchablecontext bc) {
        // Query for all Failed Cases
        String strAutomationMessage = 'Auto-Solve Batch';
        String strCaseSolvedStatus = 'Solved';
        String strCaseClosedStatus = 'Closed';
        String strAutomationStatus = 'Failed';
        String strCaseQuery = 'SELECT Id FROM Case WHERE Automation_Message__c = \'' + strAutomationMessage + '\' AND Status != \'' + strCaseSolvedStatus + '\' AND Status != \'' + strCaseClosedStatus + '\''
            + ' AND Automation_Status__c = \'' + strAutomationStatus + '\' AND Mass_Email_Step__c != null';
        return Database.getQueryLocator(strCaseQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> list_FailedCases) {
        try {
            List<Case> list_CasesToUpdate = new List<Case>();
            for(Case objCase : list_FailedCases) {
                objCase.Automation_Status__c = 'Started';
                list_CasesToUpdate.add(objCase);
            }
            update list_CasesToUpdate;
            
        } catch (Exception ex) {
            ExceptionLogUtil.logException('BatchProcessFailedAutoSolvePackageCases', 'execute', ex.getMessage() + '- Query: ' + strQueryUsed, ex.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        if (objAsyncJob.NumberOfErrors > 0) {
            Utils.processBatchFinish(objAsyncJob, '', false);
        }
    }
}