/**
* @name         SandboxEmailMaskBatch 
* @author       Sanjay Paryani
* @date         07/07/2020
* @description  Batch job to mask email ids after sandbox refresh
* @revisions    Date ------------ Name ------------ Comments 
**/
public class SandboxEmailMaskBatch implements Database.Batchable<sObject> {
    public String strQuery = '';
    public List<String> list_EmailFields = new List<String>();

    public SandboxEmailMaskBatch(String strQueryInput, List<String> list_EmailFieldsInput){
      this.strQuery = strQueryInput;
      this.list_EmailFields = list_EmailFieldsInput;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(strQuery);
    }
    
    // Execute
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        system.debug('Jobs in SandboxEmailMaskBatch: ' + Limits.getQueueableJobs());
        
        if(Limits.getQueueableJobs() == 1 || Test.isRunningTest()) {
            String strHour = String.valueOf(Datetime.now().hour());
            String strMin = String.valueOf(Datetime.now().minute()); 
            String strSeconds = String.valueOf(Datetime.now().second() + 5);
            if(Integer.valueOf(strSeconds) > 59)    strSeconds = String.valueOf(0);
            // Parse to CRON expression
            String strNextFireTime = strSeconds + ' ' + strMin + ' ' + strHour + ' * * ?';
            SandboxEmailMaskSchedulable objJob = new SandboxEmailMaskSchedulable(scope, list_EmailFields);
            ID idJobID = System.schedule('SandboxEmailMaskSchedulableJob ' + String.valueOf(Math.random()), strNextFireTime, objJob);
        } else { 
            SandboxEmailMaskQueueable objJob = new SandboxEmailMaskQueueable(scope, list_EmailFields);
            // Enqueue the Job
            ID idJobID = System.enqueueJob(objJob);
        } 
        
        // This is only when test class is running
        if(Test.isRunningTest()) {
            SandboxEmailMaskQueueable objJob = new SandboxEmailMaskQueueable(scope, list_EmailFields);
            // Enqueue the Job
            ID idJobID = System.enqueueJob(objJob);            
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    }
}