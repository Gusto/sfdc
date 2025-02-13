/**
* @name         ProcessFormAttachmentsScheduler
* @author       Neha Dabas
* @date         24 June 2020
* @description  Schedule batch to process ContentVersions records with Status as Error
* @test class   ProcessFormAttachmentsSchedulerTest
* @revisions   
**/
public without sharing class ProcessFormAttachmentsScheduler implements Schedulable{
    public void execute(SchedulableContext SC) {
        ProcessFormAttachmentsBatch batch = new ProcessFormAttachmentsBatch();
        if(test.isRunningTest())	Database.executeBatch(batch);
        else	Database.executeBatch(batch, 50);        
    }
}