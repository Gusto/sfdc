public with sharing class PrivacyRequestSendDataExt {
    private ApexPages.StandardController stdCtrl;
    private Case c;
    public String redirectUrl {public get; private set;}
    public Boolean shouldRedirect {public get; private set;}

    public PrivacyRequestSendDataExt(ApexPages.StandardController ctrl) {
        this.stdCtrl = ctrl;
        if (!Test.isRunningTest()) ctrl.addFields(new List<String>{'Privacy_Requester_First_Name__c', 'Privacy_Requester_Last_Name__c', 'Privacy_Requester_Data__c', 'Privacy_Requester_Email__c', 'Status'});
        this.c = (Case) ctrl.getRecord();
        shouldRedirect = false;
    }

    public PageReference sendData() {
        if(c.Status == 'Ready to Disclose') {
            try{
                List<String> list_DetailsSplitByNewLine = new List<String>();
                redirectUrl = '/console?tsid='+c.Id;
                shouldRedirect = true;
                
                //get documents from Data Collection records to attach to the email
                List<Data_Collection__c> list_DataCollection = [SELECT Id FROM Data_Collection__c WHERE Case__c =: c.Id AND Exclude_From_Disclosure__c = false];
                List<String> list_DcIds = new List<String>();
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                List<ContentVersion> list_ContentVersion = new List<ContentVersion>();

                for(Data_Collection__c dc : list_DataCollection) {
                    list_DcIds.add(dc.Id);
                }
                if(!list_DcIds.isEmpty()) {
                    List<ContentDocumentLink> list_ContentDocLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : list_dcIds];
                    List<String> list_ContentDocIds = new List<String>();
                    if(!list_ContentDocLink.isEmpty()) {
                        for(ContentDocumentLink cdl : list_ContentDocLink) {
                            list_ContentDocIds.add(cdl.ContentDocumentId);
                        }

                        list_ContentVersion = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId IN: list_ContentDocIds AND IsLatest = true];
                        
                        for(ContentVersion document : list_ContentVersion) {
                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();

                            attachment.setBody(document.VersionData);
                            attachment.setFileName(document.Title);
                            attachments.add(attachment);
                        }
                    }
                }
                String emailBody = '';
                if(!String.isBlank(c.Privacy_Requester_Data__c)) {
                    emailBody += c.Privacy_Requester_Data__c;
                    List<String> list_EmailAddresses = new List<String>{c.Privacy_Requester_Email__c};
                    List<String> list_EmailSubjects = new List<String>{'Response to your California Consumer Privacy Act request'};
                    
                    List<Messaging.SingleEmailMessage> list_mails = new List<Messaging.SingleEmailMessage>();
                    List<OrgWideEmailAddress> list_OrgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply@gusto.com'];

                    //Send email with attachment to requester
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(list_EmailAddresses);
                    mail.setOrgWideEmailAddressId(list_OrgWideEmail[0].Id);
                    mail.setSubject(list_EmailSubjects[0]);
                    mail.setHtmlBody(emailBody);
                    mail.setFileAttachments(attachments);
                    mail.setUseSignature(false);
                    list_mails.add(mail);
                    
                    if (OrganizationUtilities.canSendEmails()) {
                        Messaging.sendEmail(list_mails);
                    }
                    
                    //attach email to the case
                    EmailMessage emailMsg = new EmailMessage();
                    emailMsg.Subject = list_EmailSubjects[0];
                    emailMsg.FromAddress = 'no-reply@gusto.com';
                    emailMsg.ToAddress = c.Privacy_Requester_Email__c;
                    emailMsg.ParentId = c.Id; //Attach with the case
                    emailMsg.MessageDate = System.now();
                    emailMsg.Status = '3';
                    emailMsg.HtmlBody = emailBody;
                    insert emailMsg;

                    List<Attachment> list_EmailLogAttachment = new List<Attachment>();

                    if(!list_DcIds.isEmpty()) {
                        for(ContentVersion document : list_ContentVersion) {
                            Attachment attachment = new Attachment();
                            attachment.Body = document.VersionData;
                            attachment.Name = document.Title;
                            attachment.ParentId = emailMsg.Id; 
                            list_EmailLogAttachment.add(attachment);
                        }
                        insert list_EmailLogAttachment;
                    }
                }
                return null;
            }
            catch(Exception e) {
                ExceptionLogUtil.logException('PrivacyRequestSendDataExt', 'sendData', e.getMessage(), e.getStackTraceString());
                return null;
            }
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Case Status must be Ready to Disclose.'));
            PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
            pageRef.setRedirect(false);
            return pageRef;
        }
        
    }
}