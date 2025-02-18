public with sharing class CaseEmailAttachmentCmp {
   @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getEmailMessage(String caseId) {
        return [SELECT Id, Subject, FromAddress, ToAddress, MessageDate, AttachmentIds FROM EmailMessage where ParentId=: caseId];
    }
}