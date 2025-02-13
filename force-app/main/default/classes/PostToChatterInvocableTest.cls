/**
 * @name            : PostToChatterInvocableTest
 * @author          : Alex Xiong
 * @date            : 03-11-2021
 * @description     : Test class for PostToChatterInvocable.cls
 */
@isTest
public with sharing class PostToChatterInvocableTest {
    @TestSetup
    static void setup(){
        Case objCase1 = new Case(
            RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
            Subject = 'Test Chatter 1',
            Description = 'Test Chatter',
            SuppliedEmail = 'test.test@gusto.com',
            Type = 'Payroll Care',
            Origin = 'Email',
            Direction__c = 'Inbound'
        );
        insert objCase1;

        Guided_Case_Flow__c objCaseFlow = new Guided_Case_Flow__c(
            What_does_customer_need__c = 'neque viverra justo nec ultrices',
            What_does_the_customer_want_from_Gusto__c = 'neque viverra justo nec ultrices',
            Need_to_ask_any_clarifying_question__c = true,
            What_action_do_I_need_to_take__c = 'neque viverra justo nec ultrices',
            Case__c = objCase1.Id,
            Advocate__c = UserInfo.getUserId()
        );
        insert objCaseFlow;
    }

    /**
     * @author          : Alex Xiong
     * @description     : test PostToChatterInvocable.postChatter()
     */
    @isTest
    public static void testPostChatter() {
        Test.startTest();
        List<Case> list_Case = [SELECT Id FROM Case];
        List<Guided_Case_Flow__c> list_GCF = [SELECT Id FROM Guided_Case_Flow__c];
        List<PostToChatterInvocable.PostToChatterInput> list_Input = new List<PostToChatterInvocable.PostToChatterInput>();
        PostToChatterInvocable.PostToChatterInput objInput = new PostToChatterInvocable.PostToChatterInput();

        objInput.idTargetRecord = list_Case[0].Id;
        objInput.idRecordToMention = list_GCF[0].Id;
        objInput.strText = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.';
        list_Input.add(objInput);

        // Set the test data
        ConnectApi.FeedElementPage objTestPage = new ConnectApi.FeedElementPage();
        List<ConnectApi.FeedItem> list_TestItem = new List<ConnectApi.FeedItem>();

        for (Case objCse : list_Case) {
            list_TestItem.add(new ConnectApi.FeedItem());
        }

        objTestPage.Elements = list_TestItem;
        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null, ConnectApi.FeedType.RECORD, 'me', objTestPage);

        PostToChatterInvocable.postChatter(list_Input);
        ConnectAPIMock.getFeedCount();
        Test.stopTest();
    }
}