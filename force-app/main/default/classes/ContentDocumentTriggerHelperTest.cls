/**
* @name         ContentDocumentTriggerHelperTest
* @author       Sindhu
* @date         27th March 2024
* @description  Test class for ContentDocumentTrigger class
* @revisions    Date ------------ Name ------------ Comments
*/
@isTest
public class ContentDocumentTriggerHelperTest {
    
    @isTest static void testWithFlowCreatedTrue() {
        ContentVersion objContentVersion = new TestDataFactory.ContentVersionBuilder().setFlowCreated(true).setPathOnClient('TestFile1').setTitle('TestFile1').setVersionData(Blob.valueOf('sample content1')).build();
        insert objContentVersion;
        objContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        Test.startTest();
        List<ContentDocument> list_ContentDocuments = [SELECT Id FROM ContentDocument WHERE Id = :objContentVersion.ContentDocumentId];
        try{
            delete list_ContentDocuments;
        }
        catch(Exception e){
        }
        System.assertEquals(1, [SELECT count() FROM ContentDocument WHERE Id = :objContentVersion.ContentDocumentId]);
        Test.stopTest(); 
        
    }
    
    @isTest static void testWithFlowCreatedFalse() {   
        ContentVersion objContentVersion = new TestDataFactory.ContentVersionBuilder().setFlowCreated(false).setPathOnClient('TestFile1').setTitle('TestFile1').setVersionData(Blob.valueOf('sample content1')).build();
        insert objContentVersion;
        objContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        Test.startTest();      
        List<ContentDocument> list_ContentDocuments = [SELECT Id FROM ContentDocument WHERE Id = :objContentVersion.ContentDocumentId];
        delete list_ContentDocuments;
        Test.stopTest(); 
        
        System.assertEquals(0, [SELECT count() FROM ContentDocument WHERE Id = :objContentVersion.ContentDocumentId]);
    }
    
    @isTest static void testWithEmptyList() {
        Test.startTest();
        List<ContentDocument> list_ContentDocuments = new List<ContentDocument>();
        ContentDocumentTriggerHelper contentDocumentTriggerHelper = new ContentDocumentTriggerHelper();
        contentDocumentTriggerHelper.processBeforeDelete(list_ContentDocuments);
        ContentDocumentTgrHandler.resetSkipTriggerFlags();
        Test.stopTest();    
        
        System.assertEquals(0, list_ContentDocuments.size());
    }
}