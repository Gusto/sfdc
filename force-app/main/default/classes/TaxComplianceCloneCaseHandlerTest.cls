/**
 * @name         TaxComplianceCloneCaseHandlerTest
 * @author       Sujan
 * @date         07/15/2024
 * @description  Test Class for TaxComplianceCloneCaseHandler
 **/
@isTest
public class TaxComplianceCloneCaseHandlerTest {
   @TestSetup
    static void setupTestData() {
        Test.startTest();
        Case objParentCase = TestDataFactory.createCaseRecord('Compliance', false);
        objParentCase.OCR_Message__c = 'Test Parent Case';
        insert objParentCase;
        Case objChildCase = TestDataFactory.createCaseRecord('Compliance', false);
        objChildCase.OCR_Message__c = 'Test Child Case';
        objChildCase.ParentId = objParentCase.id;
        insert objChildCase;
        Tax_Compliance__c objTaxCompliance = new TestDataFactory.TaxComplianceBuilder().setCaseId(objParentCase.id).build();
        insert objTaxCompliance;
        Tax_Compliance__c objChildTaxCompliance = new TestDataFactory.TaxComplianceBuilder().setCaseId(objChildCase.id).build();
        insert objChildTaxCompliance;
        Tax_Questionnaire__c objTaxQuestionnaire = new TestDataFactory.TaxQuestionnaireBuilder().setCaseId(objParentCase.id).build();
        insert objTaxQuestionnaire;
        Tax_Questionnaire__c objChildTaxQuestionnaire = new TestDataFactory.TaxQuestionnaireBuilder().setCaseId(objChildCase.id).build();
        insert objChildTaxQuestionnaire;
        ContentVersion objContentVersion = new TestDataFactory.ContentVersionBuilder().setFlowCreated(false).setPathOnClient('test.pdf').setTitle('test').setVersionData(Blob.valueOf('sample content1')).build();
        insert objContentVersion;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id].ContentDocumentId;

        TestDataFactory.ContentDocumentLinkBuilder objContentDocumentLinkBuilder = new TestDataFactory.ContentDocumentLinkBuilder();
        
        objContentDocumentLinkBuilder.setContentDocumentId(String.valueOf(contentDocumentId));
        objContentDocumentLinkBuilder.setLinkedEntityId(String.valueOf(objParentCase.Id));
        ContentDocumentLink objContentDocumentLink = objContentDocumentLinkBuilder.build();
        insert objContentDocumentLink;
        
        FeedItem objFeedItem = new FeedItem();
        objFeedItem.ParentId = objParentCase.Id;
        objFeedItem.body = '@' + System.UserInfo.getFirstName() + ' ' + System.UserInfo.getLastName();
        FeedItemTriggerHelper.skipTrigger = true;
        insert objFeedItem;
        
        FeedComment objFeedComment = new FeedComment(
            createddate = System.Today(),
            FeedItemId = objFeedItem.Id,
            CommentType = 'TextComment',
            CommentBody = '@' + System.UserInfo.getFirstName() + ' ' + System.UserInfo.getLastName()
        );
        FeedCommentTriggerHelper.skipTrigger = true;
        insert objFeedComment;
        Test.stopTest();
    }
     @isTest
    static void getCaseCloneTest() {
        Test.startTest();
        Case objCaseRecord = [SELECT ID FROM CASE WHERE OCR_Message__c='Test Parent Case'];
        List<Case> lst_CasesCloned = TaxComplianceCloneCaseHandler.getCaseClone(new List<String>{objCaseRecord.id});
        System.assertEquals(lst_CasesCloned.isempty(),false, 'Case clone failed');
        Test.stopTest();
    }
      @isTest
    static void getChildCaseCloneTest() {
        Test.startTest();
        Case objCaseRecord = [SELECT ID FROM CASE WHERE OCR_Message__c='Test Child Case'];
        List<Case> lst_CasesCloned = TaxComplianceCloneCaseHandler.getCaseClone(new List<String>{objCaseRecord.id});
        System.assertEquals(lst_CasesCloned.isempty(),false, 'Case clone failed');
        Test.stopTest();
    }
}