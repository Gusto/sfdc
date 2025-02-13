/**
 * @name         : SearchRelatedChatsControllerTest
 * @author       : Ankit CS
 * @date         : 06-30-2021
 * @description  : Test class for SearchRelatedChatsController, ChatInternalWidgetLEXExt  Apex classes.
**/
@isTest
public class SearchRelatedChatsControllerTest {
    @TestSetup
    public static void testSetup() {
        LiveChatVisitor objChatVisitor = new LiveChatVisitor();
        insert objChatVisitor;

        LiveChatTranscript objChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
            .setRecordTypeId('Internal')
            .setQuestion('Test')
            .setChatVisitor(objChatVisitor.Id)
            .build();
        insert objChatTranscript;
    }

    /**
     * @Author      : Ankit CS
     * @Description : Test method for SearchRelatedChatsController.getSessionCache()
    **/
    @isTest
    public static void testGetSessionCache() {
        String strResult = ChatInternalWidgetLEXExt.createSessionCache('Test Question', 'ctab0');
        System.assertEquals(strResult, 'Success');
        Test.startTest();
        SearchRelatedChatsController.SessionCacheWrapper objWrapper = SearchRelatedChatsController.getSessionCache();
        Test.stopTest();
        System.assertEquals(objWrapper.strQuestion, 'Test Question');
        System.assertEquals(objWrapper.strFocusedCase, 'ctab0');
    }
    
    /**
     * @Author      : Ankit CS
     * @Description : Test method for SearchRelatedChatsController.fetchRelatedChats()
    **/
    @isTest
    public static void testFetchRelatedChats() {
        LiveChatTranscript objChatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{objChatTranscript.Id});
        Test.startTest();
        List<LiveChatTranscript> list_ChatTranscripts = SearchRelatedChatsController.fetchRelatedChats('Test');
        System.assert(list_ChatTranscripts.size() > 0);
        Test.stopTest();
    }

    /**
     * @Author      : Alex Xiong
     * @Description : test exception for getSessionCache()
     */
    @isTest
    public static void testGetSessionCacheException() {
        Test.startTest();
        SearchRelatedChatsController.blnTestException = true;
        try {
            SearchRelatedChatsController.SessionCacheWrapper objWrapper = SearchRelatedChatsController.getSessionCache();
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script-thrown exception'));
        }


        SearchRelatedChatsController.blnTestException = false;
        Test.stopTest();
    }

    /**
     * @Author      : Alex Xiong
     * @Description : test exception for fetchRelatedChats()
     */
    @isTest
    public static void testFetchRelatedChatsException() {
        Test.startTest();
        SearchRelatedChatsController.blnTestException = true;
        try {
            List<LiveChatTranscript> list_ChatTranscripts = SearchRelatedChatsController.fetchRelatedChats('Test');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains('Script-thrown exception'));
        }

        SearchRelatedChatsController.blnTestException = false;
        Test.stopTest();
    }
}