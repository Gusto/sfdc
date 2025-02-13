public with sharing class ChatTranscriptUpdate_LEX {
    public Id transcriptId {get; set;}
    public LiveChatTranscript transcript {get; set;}
    public Boolean boolRefreshPage {get; set;}
    public Case theCase {get; set;}

    @AuraEnabled
    public static String queryChatTranscript(String strTranscriptId){
        LiveChatTranscript transcript = [SELECT Id, Auto_Close_Time__c, CaseId, Status FROM LiveChatTranscript WHERE Id =: strTranscriptId];
        return JSON.serialize(transcript);
    }
    

}