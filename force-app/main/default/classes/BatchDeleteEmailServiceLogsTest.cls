/*
@Author -Gaurav Khare
@CreateDate 20-Jan-2020
@Description - Test class for BatchDeleteEmailServiceLogs
*/
@isTest
public with sharing class BatchDeleteEmailServiceLogsTest {
    @isTest static void testEmailServiceLogsDelete(){
        Email_Service_Log__c objlog = new Email_Service_Log__c();
        objlog.CreatedDate = system.today()-7;
        insert objlog;

        test.startTest();
           // String query = 'SELECT Id FROM ';
            BatchDeleteEmailServiceLogs objBatch = new BatchDeleteEmailServiceLogs();
            Database.executeBatch(objBatch);        
        test.stopTest();

        List<Email_Service_Log__c> listLogs = [SELECT Id FROM Email_Service_Log__c];
        system.assertEquals(listLogs.size(), 0);


    }
}