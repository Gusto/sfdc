@isTest
public class ChatTranscriptUpdate_LEXTest {
	//Method to get chat transcript
    static testmethod void testGetChatTranscript(){
         Case objCase= new Case(Status = 'New', Origin = 'Phone',SuppliedEmail = 'test@test.com');
        insert objCase;
        
        
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        
        LiveChatTranscript objChat = new LiveChatTranscript(CaseId = objCase.Id,liveChatVisitorId = visitor.id);
        insert objChat;
        
        ChatTranscriptUpdate_LEX classObj = new ChatTranscriptUpdate_LEX();
        classObj.boolRefreshPage = true;
        classObj.theCase = objCase;
        classObj.transcript = objChat;
        classObj.transcriptId = objChat.Id;
        Test.startTest();
        String strChatTranscript = ChatTranscriptUpdate_LEX.queryChatTranscript(objChat.Id);
        System.assertEquals(true, strChatTranscript != '');
        Test.stopTest();
    }
}