/**
* @name         TaxComplianceEmailHandler
* @author       Sindhu
* @date         04th April 2024
* @description  Handles Email to case functionality for compliance case records.
* @Email Address: 'taxcomplaince@gusto.com'
* @test class   ComplianceInboundEmailHandlerTest
* @revisions    Date ------------ Name ------------ Comments
**/
//Handles Email to case functionality for compliance case records.
global class TaxComplianceEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            Case objCase = new Case();
            // Try to find the Case ID using threading tokens in email attributes.
            Id caseId = EmailMessages.getRecordIdFromEmail(email.subject, email.plainTextBody, email.htmlBody);
            
            // If we haven't found the Case ID, try finding it using headers.
            //if(!Test.isrunningTest()){
                if (caseId == null) {
                    caseId = Cases.getCaseIdFromEmailHeaders(email.headers);  
                }
           // }
            system.debug('caseId...'+caseId);
            
            if (caseId != null) {
                objCase = [SELECT ID FROM CASE WHERE ID =:caseId];
            }
            else{
                String threadId = email.subject.substringBetween('[', ']');
                String encodedCaseId = threadId != null ? threadId.substringBetween('.!', ':ref'):null;
                if(encodedCaseId != null){
                    String caseIdString = encodedCaseId?.substring(0, 4) + '00000' + encodedCaseId?.substring(4);
                    objCase = [SELECT ID FROM CASE WHERE ID =:caseIdString]; 
                }
            } 
            if (caseId == null && objCase != null) {
                objCase = TaxComplianceController.populateEmailToCaseForCompliance(email.FromAddress, email.subject, objCase, CaseUtils.STRG_TAX_COMPLIANCE_EMAIL);
                if (String.isNotBlank(email.htmlBody)) {
                    objCase.HTML_Description__c = email.htmlBody;
                } else if (String.isNotBlank(email.plainTextBody)) {
                    objCase.Description = email.plainTextBody;
                }
                insert objCase;
                TaxComplianceController.insertComplianceRecords(objCase);
            }
            //Save any Binary Attachment and Text Attachments on created cases.
            if (email.binaryAttachments != null) {
                TaxComplianceController.insertCaseAttachments(objCase, email.binaryAttachments);
            }          
            
            TaxComplianceController.createEmailMessage(objCase, email);
        } catch (Exception ex) {
            Database.rollback(sp);
            ExceptionLogUtil.logException('TaxComplianceEmailHandler', 'handleInboundEmail', ex.getMessage(), ex.getStackTraceString());
        } 
        return result;
    }
    
}