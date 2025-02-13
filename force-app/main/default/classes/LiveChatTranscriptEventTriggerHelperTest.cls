@isTest
public with sharing class LiveChatTranscriptEventTriggerHelperTest {
    @isTest
    static void testChatEvent(){
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;

        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorid = lcv.id;
        insert lct;

        List<LiveChatTranscriptEvent> list_Events = new List<LiveChatTranscriptEvent>();
        //make sure we save the latest warning on the chat transcript
        LiveChatTranscriptEvent leWarn = new LiveChatTranscriptEvent(Type = 'ChasitorIdleTimeoutWarningTriggered', Time = System.now(), LiveChatTranscriptId = lct.Id);
        LiveChatTranscriptEvent leWarn2 = new LiveChatTranscriptEvent(Type = 'ChasitorIdleTimeoutWarningTriggered', Time = System.now().addSeconds(30), LiveChatTranscriptId = lct.Id);
        LiveChatTranscriptEvent leTimeout = new LiveChatTranscriptEvent(Type = 'ChasitorIdleTimeout', Time = System.now().addSeconds(60), LiveChatTranscriptId = lct.Id);
        
        list_Events.add(leWarn);
        list_Events.add(leWarn2);
        list_Events.add(leTimeout);

        insert list_Events;

        LiveChatTranscript chat = [SELECT Id, Customer_Idle_Warning__c, Customer_Idle_Timeout__c, Timeout_Window__c FROM LiveChatTranscript];
        System.assertEquals(.5, chat.Timeout_Window__c);
        
    }

    @isTest
    public static void testException() {
        LiveChatTranscriptEventTriggerHelper.blnTestException = true;
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;

        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorid = lcv.id;
        insert lct;

        List<LiveChatTranscriptEvent> list_Events = new List<LiveChatTranscriptEvent>();
        //make sure we save the latest warning on the chat transcript
        LiveChatTranscriptEvent leWarn = new LiveChatTranscriptEvent(Type = 'ChasitorIdleTimeoutWarningTriggered', Time = System.now(), LiveChatTranscriptId = lct.Id);
        LiveChatTranscriptEvent leWarn2 = new LiveChatTranscriptEvent(Type = 'ChasitorIdleTimeoutWarningTriggered', Time = System.now().addSeconds(30), LiveChatTranscriptId = lct.Id);
        LiveChatTranscriptEvent leTimeout = new LiveChatTranscriptEvent(Type = 'ChasitorIdleTimeout', Time = System.now().addSeconds(60), LiveChatTranscriptId = lct.Id);
        
        list_Events.add(leWarn);
        list_Events.add(leWarn2);
        list_Events.add(leTimeout);

        insert list_Events;
    }
}