/**
 * @name         ContentVersionTriggerTest
 * @author       Neha Dabas
 * @date         24th June 2020
 * @description  This is a test class for ContentVersionTrigger and ContentVersionTriggerHelper
 * @revisions    Date ------------ Name ------------ Comments 
  **/
@isTest
class ContentVersionTriggerTest {
    @TestSetup
    static void makeData(){
        Account objAcc = new Account(Name='test',ZP_Company_Id__c = '7757616923580839');
        insert objAcc;
        Case objCase = new Case(RecordTypeId = Cache.getRecordTypeId('Case', 'MF Member/Group Updates'),Integration_Key__c = 'fd0daef0-6ac6-403b-b3b4-kaiser_ca', Status = 'New');
        insert objCase;   
    }
    @IsTest
    static void testContentVersionTrigger(){
        Test.startTest();
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = false;
            cv.HI_Fulfillment_Event_Id__c = 'fd0daef0-6ac6-403b-b3b4';
            cv.State_Carrier_Key__c = 'kaiser_ca';
            cv.State_Carrier_Id__c = '5';
            cv.Processing_State__c = 'Error';
            Insert cv;
        Test.stopTest();
        //system.assert([SELECT count() FROM ContentVersion WHERE Processing_State__c = 'Processed'] == 1);
    }
}