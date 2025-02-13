public with sharing class HIOpenEnrollmentWindowBatch implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        string queryString = 'Select Id from HI_Open_Enrollment_Window__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';
        
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        HIOpenEnrollmentWindowTriggerHelper.queue=true;
        List<HI_Open_Enrollment_Window__c> windowList= (List<HI_Open_Enrollment_Window__c>)scope;
        
        update windowList;
    }
    
    public void finish(Database.BatchableContext BC){
        
        AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIOpenEnrollmentWindowBatch', false);
    }
}