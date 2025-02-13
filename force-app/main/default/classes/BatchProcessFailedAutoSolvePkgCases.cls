/**
 * @author      Ankit Rajput
 * @description It fetches all automation failed cases and updates their automation status as started.
 * Date: 20/12/2024
 **/

public with sharing class BatchProcessFailedAutoSolvePkgCases  implements Database.Batchable<sObject> {
    
    // Define constants for Automation Status
    public static final String AUTOMATION_STATUS_STARTED = 'Started';
    public static final String AUTOMATION_STATUS_FAILED = 'Failed';
    
    public String strCaseQuery;
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Query for all Failed Cases
        String strAutomationMessage = 'Auto-Solve Batch';
        String strCaseSolvedStatus = 'Solved';
        String strCaseClosedStatus = 'Closed';
        List<String> excludedStatuses = new List<String>{strCaseSolvedStatus, strCaseClosedStatus};

        // Construct the query string
        strCaseQuery = 'SELECT Id FROM Case WHERE Automation_Message__c = :strAutomationMessage ' 
                        + 'AND Status NOT IN :excludedStatuses '
                        + 'AND Automation_Status__c = :AUTOMATION_STATUS_FAILED '
                        + 'AND Mass_Email_Step__c != null';
        
        return Database.getQueryLocator(strCaseQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> list_FailedCases) {
        try {
            List<Case> list_CasesToUpdate = new List<Case>();
            for(Case objCase : list_FailedCases) {
                objCase.Automation_Status__c = AUTOMATION_STATUS_STARTED; 
                list_CasesToUpdate.add(objCase);
            }
            update list_CasesToUpdate;
            
        } catch (Exception ex) {
            // Log the exception with the query used
            ExceptionLogUtil.logException('BatchProcessFailedAutoSolvePackageCases', 'execute', ex.getMessage() + ' - Query: ' + strCaseQuery, ex.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        if (objAsyncJob.NumberOfErrors > 0) {
            Utils.processBatchFinish(objAsyncJob, '', false);
        }
    }
}