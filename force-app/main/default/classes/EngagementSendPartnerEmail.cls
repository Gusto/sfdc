global class EngagementSendPartnerEmail {
    @InvocableMethod(label='Send Partner Email')
    public static void insertEmailMessage(List<EmailMessage> newEmailMessageList) {
        System.debug('***newEmailMessage'+newEmailMessageList);
        EmailMessage newEmailMessage = newEmailMessageList[0];
        Case caseRecord = [select Id, ContactId, Contact.Email from Case where Id = :newEmailMessage.ParentId];
        System.debug('***CaseRecord'+CaseRecord);
        newEmailMessage.toIds.add(CaseRecord.ContactId);
        Database.insert(newEmailMessage);

        // Add Email Message Relation for id of the sender
        EmailMessageRelation emr = new EmailMessageRelation();
        emr.emailMessageId = newEmailMessage.id;
        emr.relationId = CaseRecord.ContactId; // user id of the sender
        emr.relationType = 'ToAddress';
        insert emr;

        EmailMessage objEmailMessage = [SELECT Id, Subject, TextBody, HtmlBody FROM EmailMessage WHERE Id = :emr.emailMessageId];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(objEmailMessage.Subject);
        email.setPlainTextBody(objEmailMessage.TextBody);
        email.setToAddresses(new String[] { caseRecord.Contact.Email });
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });


        for (Messaging.SendEmailResult result : results) {
    if (result.isSuccess()) {
        System.debug('Email sent successfully to: ' + email.getToAddresses()[0]);
    } else {
        System.debug('Failed to send email: ' + result.getErrors()[0].getMessage());
    }
}
     }
}