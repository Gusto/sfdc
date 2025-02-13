/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   02/14/2024
 * @Desc         :   Schedule class for batch AutoCloseAbandonedChatCasesBatch
 * @TestClass    :   AutoCloseAbandonedChatCasesBatchTest
**/
global class AutoCloseAbandonedChatCasesJob implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
        Integer intBatch = 20;
        
        if (objConfigSettings != null && objConfigSettings.Auto_Close_Chat_Cases_Batch_Size__c != null) {          
            intBatch = (Integer) objConfigSettings.Auto_Close_Chat_Cases_Batch_Size__c; 
        }

        Set<String> set_OwnerIds = new Set<String>();
        Set<String> set_RecordTypeIds = new Set<String>{ CaseUtils.RECTYPE_ENGAGEMENT };
        Set<String> set_Statuses = new Set<String>{ CaseUtils.STATUS_OPEN };

        List<User> list_Users = [SELECT Id FROM User WHERE Name = 'Automated Process' LIMIT 1];
        if (!list_Users.isEmpty()) {
            set_OwnerIds.add(list_Users[0].Id);
        }
        AutoCloseAbandonedChatCasesBatch objBatch = new AutoCloseAbandonedChatCasesBatch(set_OwnerIds, set_RecordTypeIds, set_Statuses);
        Database.executeBatch(objBatch, intBatch);
    }
}