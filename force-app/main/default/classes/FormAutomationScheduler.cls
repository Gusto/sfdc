/**
* @name         FormAutomationScheduler
* @author       Neha Dabas
* @date         24 June 2020
* @description  Schedule form
* @test class   FormAutomationSchedulerTest
* @revisions   
**/
public without sharing class FormAutomationScheduler implements Schedulable{
    public void execute(SchedulableContext SC) {
        FormAutomationBatch batch = new FormAutomationBatch();
        if(test.isRunningTest())	Database.executeBatch(batch);
        else	Database.executeBatch(batch, 1);
        
    }
}