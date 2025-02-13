/**
 * Author: Lakshey Mendiratta
 * Date: 9/15/2020
 * Desc: Controller for massEmail LWC
 */
public with sharing class MassEmail_LEX {

    public static List<Case> list_SearchCase = new List<Case>();
    @AuraEnabled
    public static List<Group> queryQueues(){
        List<Group> list_Queues = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND QueueRoutingConfigId = null];
        return list_Queues;
    }

    /**
     * Desc: get Cases from the queue provided
     */
    @AuraEnabled(cacheable=true)
    public static List<Case> fetchCaseReasons(String strQueueName){
       List<Case> list_Case =  [SELECT Id, Routing_Case_Reason_Classification__c, 
                                Routing_Case_Reason_Classification__r.Name
                                FROM Case 
                                //WHERE Routing_Case_Reason_Classification__r.Type__c = : strCaseType 
                                WHERE Routing_Case_Reason_Classification__r.Active__c = true
                                AND Owner.Name = :strQueueName];
        return list_Case;
    }

    /**
     * Desc: From a queue and case reason, get a list of Cases
     */
    @AuraEnabled
    public static List<Case> fetchSearchResults(String strQueueName, String strCaseReason){
        for (Case objCase : [SELECT Subject, Owner.Name, Type, Description, CaseNumber, Agatha_Confidence__c,
                            Contact.Name, ContactId, Last_out_bound_email__c, Routing_Case_Reason__c,
                            Routing_Case_Reason_Classification__c, Mass_Email_Template_Applied__c,
                            (SELECT Id FROM Case_Skip_Histories__r WHERE User__c = :UserInfo.getUserId()
                            AND Skip_Reason__c = 'Mass Email. User ignored the Case.')
                            FROM Case
                            WHERE Last_out_bound_email__c = null
                            AND ContactId != null
                            AND (Status NOT IN ('Solved') OR Status NOT IN ('Closed') OR Status NOT IN ('Cancelled'))
                            AND (Owner.Name NOT IN ('Engagement - Payroll Unauthorized') OR Owner.Name NOT IN ('Engagement - Benefits Unauthorized') 
                            OR Owner.Name NOT IN ('Full-Stack Care - Non Actionable'))
                            AND Owner.Name = :strQueueName
                            AND (RecordType.Name = 'Benefits Care' OR RecordType.Name = 'Payroll Care' OR RecordType.Name = 'Tax Res')
                            AND Routing_Case_Reason_Classification__r.Name = :strCaseReason]) {
            if (objCase.Case_Skip_Histories__r.isEmpty()) {
                list_SearchCase.add(objCase);
            }
        }                      
        return list_SearchCase;
    }

    /**
     * Get the list of all email templates
     */
    @AuraEnabled
    public static Map<String, Object> fetchAllEmailTemplates(){
        Map<String, Object> map_resp = new Map<String, Object>();
        Map<String,String> map_EmailTemplateName = new Map<String,String>();
        map_EmailTemplateName.put('--None--', '--None--');
        Folder fldrMassEmail = [SELECT Id, Name FROM Folder WHERE Name = 'Mass Email Templates'];
        map_EmailTemplateName.put(fldrMassEmail.Id, fldrMassEmail.Name);

        for ( Folder f : [SELECT Id, Name FROM Folder WHERE Type = 'Email' ORDER BY Name ASC]) {
            if(f.Name != 'Mass Email Templates') {
                map_EmailTemplateName.put(f.Id, f.Name);
            }
        }
        map_EmailTemplateName.put(UserInfo.getOrganizationId(), 'Unfiled Public Classic Email Templates');
        //return [SELECT Id, Name, Description FROM EmailTemplate WHERE FolderId in :map_EmailTemplateName.keySet() ORDER BY Name ASC];
        List<String> list_emailTemplateNames = new  List<String>();
        for(EmailTemplate em : [SELECT Id, Name, Description FROM EmailTemplate WHERE FolderId in :map_EmailTemplateName.keySet() ORDER BY Name ASC]) {
            list_emailTemplateNames.add(em.Name);
        }
        map_resp.put('listEmailTemplatesNames', list_emailTemplateNames);
        map_resp.put('ListEmailTemplatesRecords', [SELECT Id, Name, Description FROM EmailTemplate WHERE FolderId in :map_EmailTemplateName.keySet() ORDER BY Name ASC]);
        //return list_emailTemplateNames;
        return map_resp;
        
    }


    /**
     * Get a map of email folder ids with their names
     */
    @AuraEnabled(cacheable=true)
    public static Map<String,String> fetchEmailFolderNames(){
        Map<String,String> map_EmailTemplateName = new Map<String,String>();
        map_EmailTemplateName.put('--None--', '--None--');
        Folder fldrMassEmail = [SELECT Id, Name FROM Folder WHERE Name = 'Mass Email Templates'];
        map_EmailTemplateName.put(fldrMassEmail.Id, fldrMassEmail.Name);

        for ( Folder f : [SELECT Id, Name FROM Folder WHERE Type = 'Email' ORDER BY Name ASC]) {
            if(f.Name != 'Mass Email Templates') {
                map_EmailTemplateName.put(f.Id, f.Name);
            }
        }
        map_EmailTemplateName.put(UserInfo.getOrganizationId(), 'Unfiled Public Classic Email Templates');
        return map_EmailTemplateName;
    }

    /**
     * Desc: get a list of email templates from a folder id
     */
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplate> fetchEmailTemplate(String idFolder){
        return [SELECT Id, Name, Description FROM EmailTemplate WHERE FolderId = :idFolder ORDER BY Name ASC];
    }

    /**
     * Desc: get a single email template
     */
    @AuraEnabled
    public static EmailTemplate displayTemplate(String strTemplateId){
        return [SELECT Id, Name, Description, Subject, FolderId,Body, BrandTemplateId, TemplateStyle, DeveloperName, Encoding, HtmlValue FROM EmailTemplate WHERE Id = :strTemplateId];
    }

    /**
     * Desc: takes a json of an email template object and a list of case numbers.
     * Search for cases from the numbers provided. 
     */
    @AuraEnabled
    public static void sendEmail(String strEmailTemplateJSON, List<String> list_CaseIds, boolean boolLetCaseBeOpen) {
        List<OrgWideEmailAddress> list_SupportEmailAddress = GlobalQueryHelper.getOrgWideEmailByAdd('support@gusto.com');
        Group massEmailQueue = [SELECT Id FROM Group WHERE Name = 'Mass Email Cases'];
        List<Case> list_RecipientCases = [SELECT Id, 
                                                    CaseNumber, 
                                                    Mass_Email_Template_Applied__c, 
                                                    ContactId,Reopened_after_mass_email__c,
                                                    Subject, OwnerId,
                                                    Routing_Case_Reason_Classification__c,
                                                    Routing_Case_Reason_Classification__r.Default_Type__c,
                                                    Routing_Case_Reason__c
                                            FROM Case
                                            WHERE Id IN :list_CaseIds];
        EmailTemplate emailTemplateRec = (EmailTemplate) JSON.deserialize(strEmailTemplateJSON, EmailTemplate.class);

        try{
            if(emailTemplateRec != null && list_RecipientCases != null && list_RecipientCases.size() > 0) {
                List<Messaging.SingleEmailMessage> list_SingleEmailMessage = new List<Messaging.SingleEmailMessage>();
                List<EmailMessage> list_EmailMessage = new List<EmailMessage>();
                List<Case> list_CasesToUpdate = new List<Case>();
    
                Map<Id, Case> map_RecipientCases = new Map<Id, Case>(list_RecipientCases);
                for(Case objCase : list_RecipientCases) {
                    Id idOriginalOwner;
                    if(objCase.OwnerId != null) {
                        idOriginalOwner = objCase.OwnerId;
                    } 
                    if(map_RecipientCases.get(objCase.Id).Mass_Email_Template_Applied__c == emailTemplateRec.Name) {
                        AuraHandledException ex = new AuraHandledException('Case ' + objCase.CaseNumber + ' has already been sent this email template. Please deselect it before you continue.');
                        ex.setMessage('Case ' + objCase.CaseNumber + ' has already been sent this email template. Please deselect it before you continue.');
                        throw ex;
                    } else{
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setSubject(emailTemplateRec.Subject);
                        if(emailTemplateRec.HtmlValue != null && !emailTemplateRec.HtmlValue.contains('Case.Thread_Id')) {
                            emailTemplateRec.HtmlValue += '<br></br><font color="white">{!Case.Thread_Id}</font>';
                        }
                        mail.setHtmlBody(emailTemplateRec.HtmlValue);
                        mail.setTargetObjectId(objCase.ContactId);
                        mail.setSaveAsActivity(false);
                        mail.setUseSignature(false);
                        mail.setWhatId(objCase.Id);
                        mail.setTreatBodiesAsTemplate(true);
                        mail.setTreatTargetObjectAsRecipient(true);
                        if(!list_SupportEmailAddress.isEmpty()) {
                            mail.setOrgWideEmailAddressId(list_SupportEmailAddress[0].Id);
                        }
                        
                        list_SingleEmailMessage.add(mail);
                        
                        EmailMessage emailMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
                        emailMsg.ToAddress = objCase.ContactId;
                        emailMsg.Subject = emailTemplateRec.Subject;
                        emailMsg.HtmlBody = emailTemplateRec.HtmlValue;
                        emailMsg.ParentId = objCase.Id; //Attaching with the case
                        emailMsg.MessageDate = System.now(); 
                        emailMsg.Status = '0';
                        if(!list_SupportEmailAddress.isEmpty()) {
                            emailMsg.fromAddress = list_SupportEmailAddress[0].Address;
                        }
                        
                        list_EmailMessage.add(emailMsg);
                        
                        objCase.Last_out_bound_email__c = System.now();
                        objCase.Mass_Email_Template_Applied__c = emailTemplateRec.Name;
                        if(objCase.Routing_Case_Reason_Classification__c != null) {
                            objCase.Confirm_Case_Reason_Classification__c = objCase.Routing_Case_Reason_Classification__c;
                            objCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(objCase.Routing_Case_Reason_Classification__r.Default_Type__c).getRecordTypeId();
                            objCase.Type = objCase.Routing_Case_Reason_Classification__r.Default_Type__c;
                        }
                        if(objCase.Routing_Case_Reason__c != null) {
                            objCase.Confirm_Case_Reason__c = objCase.Routing_Case_Reason__c;
                        }
                        objCase.Benefits_and_Payroll_Care_Support_Needed__c = 'No';
                        objCase.status = 'Solved';
                        objCase.Reopened_after_mass_email__c = boolLetCaseBeOpen;
                        if(massEmailQueue != null) {
                            objCase.OwnerId = massEmailQueue.Id;
                        }
                        if(boolLetCaseBeOpen){
                            objCase.Status = 'Open';
                            objCase.OwnerId =  idOriginalOwner;
                        }
                        list_CasesToUpdate.add(objCase);
                    }
                }
                // update list_CasesToUpdate;
                Messaging.sendEmail(list_SingleEmailMessage,false);
                // insert list_EmailMessage;

                String strListCases = JSON.serialize(list_CasesToUpdate);
                String strListEmail = JSON.serialize(list_EmailMessage);
                updateCaseAndAttachEmail(strListCases, strListEmail, false);

            } else {
                throw new AuraHandledException('Please select Email Template');
            }
        } catch(Exception e) {
            ExceptionLogUtil.logException('MassEmail_LEX', 'sendEmail', e.getMessage(), e.getStackTraceString());
            AuraHandledException ex = new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
            ex.setMessage(e.getMessage() + ' ' + e.getStackTraceString());
            throw ex;
        }

    }
    
    /**
     * Author: Alex
     * Date: 10/9/2020
     * Desc: Update Case and attach email message to Case async to avoid governor limits
     */
    @future 
    public static void updateCaseAndAttachEmail(String strListCases, String strListEmail, Boolean blnThrowError) {
        Database.SaveResult[] list_Result;
        Set<String> set_RecipientsIds = new Set<String>{UserInfo.getUserId()};
        Set<String> set_FailedCaseRecordIds = new Set<String>();
        String strTargetId = '';
        try{
            List<Case> list_CasesToUpdate = (List<Case>) JSON.deserialize(strListCases, List<Case>.class);
            list_Result = Database.update(list_CasesToUpdate, false);
            List<EmailMessage> list_EmailMessage = (List<EmailMessage>) JSON.deserialize(strListEmail, List<EmailMessage>.class);
            insert list_EmailMessage;
            if (Test.isRunningTest() && blnThrowError == true) {
                Integer intX = 5 / 0;
            }
        } catch (Exception e) {
            for (Integer i = 0; i < list_Result.size(); i++) { 
                if (!list_Result.get(i).isSuccess() || Test.isRunningTest()) {
                    set_FailedCaseRecordIds.add(list_Result.get(i).Id);
                }
            }
            String strLogRecordId = ExceptionLogUtil.logExceptionWithId('MassEmail_LEX', 'updateCaseAndAttachEmail', e.getMessage(), e.getStackTraceString(), set_FailedCaseRecordIds);
            if (!set_FailedCaseRecordIds.isEmpty()) {
                strTargetId = new List<String> (set_FailedCaseRecordIds).get(0);
            }
            if (String.isNotBlank(strTargetId) && String.isNotBlank(strLogRecordId)) {
                CustomNotificationType objNotificationType = [SELECT Id, DeveloperName 
                                                             FROM CustomNotificationType 
                                                             WHERE DeveloperName = 'Mass_Email_Error_Notification'];
                Messaging.CustomNotification objNotification = new Messaging.CustomNotification();
                objNotification.setTitle(Label.Apex_Custom_Notification_Title);
                objNotification.setBody(Label.Apex_Custom_Notification_Body + ' ' + strLogRecordId);  
                objNotification.setNotificationTypeId(objNotificationType.Id);
                objNotification.setTargetId(strTargetId);
                objNotification.send(set_RecipientsIds); 
            }                                                      
        }
    }

    /**
    * @author       : Ankit CS
    * @date         : 06-09-2021
    * @description  : Wrapper class to return response from canUserCreateEscalationCase
    * @params       : list_CaseIds - list of case records Ids.
    **/
    @AuraEnabled
    public static String ignoreCases(List<String> list_CaseIds) {
        try {
            List<Case_Skip_History__c> list_SkipCaseHistories = new List<Case_Skip_History__c>();
            for (String strCaseId : list_CaseIds) {
                Case_Skip_History__c objCaseSkipHistory = new Case_Skip_History__c(
                    Case__c = strCaseId,
                    User__c = UserInfo.getUserId(),
                    Skip_Reason__c = 'Mass Email. User ignored the Case.',
                    Skip_Comment__c = 'Mass Email. User ignored the Case.'
                );
                list_SkipCaseHistories.add(objCaseSkipHistory);
            }
            insert list_SkipCaseHistories;
            return 'Success';
        } catch (Exception objException) {
            ExceptionLogUtil.logException(
                'MassEmail_LEX', 
                'ignoreCases', 
                'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
                objException.getStackTraceString()
            );
            return objException.getMessage();
        }
    }
    
}