/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   03/27/2023
 * @Desc         :   Schedule class for batch AutoClosePhoneRoutingQueueCasesBatch
 * @TestClass    :   AutoClosePhoneRoutingQueueCasesBatchTest
**/
global class AutoClosePhoneRoutingQueueCasesJob implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
        Integer intBatch = 20;
        
        if (objConfigSettings != null && objConfigSettings.Auto_Close_Phone_Routing_Batch_Size__c != null) {          
            intBatch = (Integer) objConfigSettings.Auto_Close_Phone_Routing_Batch_Size__c; 
        }
        
        AutoClosePhoneRoutingQueueCasesBatch objBatch = new AutoClosePhoneRoutingQueueCasesBatch(); 
        Database.executeBatch(objBatch, intBatch);
    }
}