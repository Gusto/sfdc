/**
* @name         SandboxEmailMaskSchedulable
* @author       Sanjay Paryani
* @date         07/07/2020
* @description  Scheduler for the SandboxEmailMaskBatch
* @revisions    Date ------------ Name ------------ Comments 
**/
global class SandboxEmailMaskSchedulable implements Schedulable {  
    private List<sObject> list_Scope; 
    public List<String> list_EmailFields = new List<String>();
    
    public SandboxEmailMaskSchedulable(List<sObject> list_Records, List<String> list_EmailFieldsInput) {
        this.list_Scope = list_Records;
        this.list_EmailFields = list_EmailFieldsInput;        
    }    
    
    global void execute(SchedulableContext sc) {
        SandboxEmailMaskQueueable objJob = new SandboxEmailMaskQueueable(list_Scope, list_EmailFields);
        ID idJob = System.enqueueJob(objJob);  
        
        // Abort the job once the job is queued 
        System.abortJob(sc.getTriggerId());          
    }
}