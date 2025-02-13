public with sharing class ChatTranscriptUpdateExt {

    public Id transcriptId {get; set;}
    public LiveChatTranscript transcript {get; set;}
    public Boolean boolRefreshPage {get; set;}
    public Case theCase {get; set;}
    public ChatTranscriptUpdateExt(ApexPages.StandardController standardController) {
        if(!Test.isRunningTest()) {
            standardController.addFields(new List<String>{'Auto_Close_Time__c', 'Case'});
        }
        
            
        LiveChatTranscript lct = (LiveChatTranscript) standardController.getRecord();
        transcriptId = lct.Id;
        transcript = lct;
        boolRefreshPage = false;
        if(lct.Case != null) {
            theCase = [SELECT Id, CaseNumber, Status FROM Case WHERE Id = :lct.Case.Id];
        }
    }
    
    public PageReference pollerRefresh(){
        if(transcript != null){
            try{
                boolRefreshPage = true;
            } catch (Exception ex){
                return null;
            }                
            
        }

        return null;
    }

}