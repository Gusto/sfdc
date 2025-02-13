/**
* @name         EmailSchedulerForFiveAm
* @author       Sanjay Paryani	
* @date         08/24/2020
* @description  Schedules email batches which need to be run at 5 AM everyday including weekends. 
* @test class   EmailSchedulerForFiveAmTest
* @revisions    Date ------------ Name ------------ Comments
*           	08/24/2020	      SJay				Run OEIncompleteEmailBatch and OEIncompleteEmailBatch.
*				09/16/2020		  SJay				Run OEFinalExtensionEmailBatch.
**/
public with sharing class EmailSchedulerForFiveAm implements Schedulable {
    // To get the batch size for which we want to process OE emails.
    Configuration_Settings__c configRec = Configuration_Settings__c.getOrgDefaults();
    
    public void execute(SchedulableContext SC) {
        //Run Batch to send OE Incomplete Emails 1 day and 2 days before the Final Extension Date to the customer.
        OEIncompleteEmailBatch oeIncompleteBatch = new OEIncompleteEmailBatch();
        if(configRec != NULL && configRec.OE_Email_Batch_Size__c != NULL) {          
        	database.executeBatch(oeIncompleteBatch, Integer.valueOf(configRec.OE_Email_Batch_Size__c)); 
        } else {
        	database.executeBatch(oeIncompleteBatch, 10);             
        }
        
        //Run Batch to send OE Reminder Emails 1 day before the Window End Date to the customer.
        OEReminderEmailBatch oeReminderBatch = new OEReminderEmailBatch();
        if(configRec != NULL && configRec.OE_Email_Batch_Size__c != NULL) {        
            database.executeBatch(oeReminderBatch, Integer.valueOf(configRec.OE_Email_Batch_Size__c));   
        } else {
            database.executeBatch(oeReminderBatch, 10);  
        }

        //Run Batch to send OE Reminder Emails 1 day before the Window End Date to the customer.
        OEFinalExtensionEmailBatch oeFinalExtensionBatch = new OEFinalExtensionEmailBatch();
        if(configRec != NULL && configRec.OE_Email_Batch_Size__c != NULL) {        
            database.executeBatch(oeFinalExtensionBatch, Integer.valueOf(configRec.OE_Email_Batch_Size__c));   
        } else {
            database.executeBatch(oeFinalExtensionBatch, 10);  
        }  

        //Run Batch to send QLE RFI Emails to the customer.
        QLERFIAutomateEmailBatch objQLERFIBatch = new QLERFIAutomateEmailBatch();
        if(configRec != NULL && configRec.OE_Email_Batch_Size__c != NULL) {        
            database.executeBatch(objQLERFIBatch, Integer.valueOf(configRec.OE_Email_Batch_Size__c));   
        } else {
            database.executeBatch(objQLERFIBatch, 10);  
        }           
    }
}