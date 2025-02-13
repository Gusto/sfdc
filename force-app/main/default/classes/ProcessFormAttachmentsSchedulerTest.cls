@isTest
class ProcessFormAttachmentsSchedulerTest {
    @TestSetup
    static void makeData(){
        AccountTriggerHelper.skipTrigger = true;
        Account objAcc = new Account(Name='test',ZP_Company_Id__c = '7757616923580839');
        insert objAcc;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.HI_Fulfillment_Event_Id__c = 'fd0daef0-6ac6-403b-b3b4';
        cv.State_CArrier_Key__c = 'kaiser_ca';
        cv.State_CArrier_Id__c = '5';
        insert cv;
        CaseTriggerHelper.skipTrigger = true;
        Case objCase = new Case(RecordTypeId = Cache.getRecordTypeId('Case', 'MF Member/Group Updates'),Integration_Key__c = 'fd0daef0-6ac6-403b-b3b4-kaiser_ca', Status = 'New');
        insert objCase;
    }
    @IsTest
    static void testProcessFormAttachmentsBatch(){
        
        Test.startTest();
            ProcessFormAttachmentsBatch batch = new ProcessFormAttachmentsBatch();
            Database.executeBatch(batch);
        Test.stopTest();
        system.assert([SELECT count() FROM ContentVersion WHERE Processing_State__c = 'Processed'] == 1);
    }
    @isTest
    static void testScheduler(){
        Test.startTest();
           Id jobId = System.schedule('Form Attachment Job', '0 00 * * * ?', new ProcessFormAttachmentsScheduler());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime  FROM CronTrigger WHERE id = :jobId];  	
        System.assertEquals('0 00 * * * ?', ct.CronExpression);
    }
}