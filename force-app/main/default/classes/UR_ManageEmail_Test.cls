@isTest
private class UR_ManageEmail_Test
{
    @TestSetup
    static void setupData() {
       ContactTriggerHelper.skipTrigger = true;
       AccountTriggerHelper.skipTrigger=true;
       UR_TestDataUtil.createResearchConfig();
       UR_TestDataUtil.createEmailMapping();
       List<Contact> contactList = UR_TestDataUtil.createContact(2);
       Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 01');
	   List<Research_Project_Detail__c> participantList = UR_TestDataUtil.createProjectParticipantTest(projectObj, contactList); 
    }
    
    static testMethod void replyEmailTest() 
    {
       ContactTriggerHelper.skipTrigger = true;
       AccountTriggerHelper.skipTrigger=true;
       List<Research_Project_Master__c> projectObjList = [select id, Project_Id__c from Research_Project_Master__c where Name = 'Test Case 01'];       
       List<Research_Project_Detail__c> participantList = [Select id, Research_Project_Master__r.Project_Id__c from Research_Project_Detail__c where Research_Project_Master__c=:projectObjList[0].id]; Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       email.subject = 'Test [Ref:' + participantList[0].Research_Project_Master__r.Project_Id__c + '~' + participantList[0].Id + ':Ref]';
       email.plainTextBody = 'Test Contact Email';
	    email.fromAddress = 'TestEmail_0@gmail.com';
       email.htmlBody = 'Email Body [Ref:' + participantList[0].Research_Project_Master__r.Project_Id__c + '~' + participantList[0].Id + ':Ref]';
        
       // add an Binary attachment
       Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
       attachment.body = blob.valueOf('my attachment text');
       attachment.fileName = 'textfileone.txt';
       attachment.mimeTypeSubType = 'text/plain';
       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

       // add an Text atatchment
       Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
       attachmenttext.body = 'my attachment text ';
       attachmenttext.fileName = 'textfiletwo3.txt';
       attachmenttext.mimeTypeSubType = 'texttwo/plain';
       email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
            
       env.fromAddress = 'TestEmail_0@gmail.com';
       UR_ManageEmail obj= new UR_ManageEmail();
       obj.handleInboundEmail(email, env );
                            
    }
     
    static testMethod void ur_ViewEmailTest() {
       ContactTriggerHelper.skipTrigger = true;
       AccountTriggerHelper.skipTrigger=true;
       List<Research_Project_Master__c> projectObjList = [select id, Project_Id__c from Research_Project_Master__c where Name = 'Test Case 01'];       
       List<Research_Project_Detail__c> participantList = [Select id, Research_Project_Master__r.Project_Id__c from Research_Project_Detail__c where Research_Project_Master__c=:projectObjList[0].id];
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       email.subject = 'Test [Ref:' + participantList[0].Research_Project_Master__r.Project_Id__c + '~' + participantList[0].Id + ':Ref]';
       email.plainTextBody = 'Test Contact Email';
	    email.fromAddress = 'TestEmail_0@gmail.com';
       email.htmlBody = 'Email Body [Ref:' + participantList[0].Research_Project_Master__r.Project_Id__c + '~' + participantList[0].Id + ':Ref]';
       env.fromAddress = 'TestEmail_0@gmail.com';
       UR_ManageEmail obj= new UR_ManageEmail();
       obj.handleInboundEmail(email, env );
       
       List<EmailTemplate> emailTemplateList = [select id,name from EmailTemplate where Folder.DeveloperName ='UX_Research' and IsActive = true ORDER BY name asc limit 1];
        
       Research_Schedule_Email__c scEmailObj = new Research_Schedule_Email__c(UXR_Scout__c=projectObjList[0].Id);
       scEmailObj.Schedule_Email_Template_Id__c = emailTemplateList[0].Id;
       scEmailObj.Schedule_Email_Date__c = Date.today().addDays(1);
       scEmailObj.Schedule_Email_Time__c = '10';
       insert scEmailObj;
        
       Research_Schedule_Email_Participant__c participantObj = new Research_Schedule_Email_Participant__c();
       participantObj.Research_Project_Detail__c = participantList[0].Id;
       participantObj.Research_Schedule_Email__c = scEmailObj.Id;
       participantObj.Schedule_Email_Status__c = 'Schedule';
       insert participantObj;
        
       Research_Schedule_Email_Participant__c participantObj1 = new Research_Schedule_Email_Participant__c();
       participantObj1.Research_Project_Detail__c = participantList[1].Id;
       participantObj1.Research_Schedule_Email__c = scEmailObj.Id;
       participantObj1.Schedule_Email_Status__c = 'Schedule';
       insert participantObj1;
        
       scEmailObj.Schedule_Email_Time__c = '12';
       update scEmailObj;
        
       UR_ScheduleEmail scheduleBatchObj = new UR_ScheduleEmail();
       Database.executeBatch(scheduleBatchObj, 1);
       List<Research_Schedule_Email_Participant__c> scList = new List<Research_Schedule_Email_Participant__c>();
       scList.add(participantObj);
       UR_ScheduleEmail scheduleBatchObj1 = new UR_ScheduleEmail(); 
	    scheduleBatchObj1.updateProjectMaster(scList,'TestError'); 
       
       UR_VewEmailCtrl.searchContact(''+ projectObjList[0].Id,'tes'); 
       ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObjList[0]);
       ApexPages.currentPage().getParameters().put('projectId',projectObjList[0].Id);
       UR_VewEmailCtrl viewEmailObj = new UR_VewEmailCtrl(sc);
       List<EmailMessage> messageList = [Select Id from EmailMessage];
       if(messageList.size()>0){
       	   ApexPages.currentPage().getParameters().put('currentTaskId',messageList[0].Id);
           viewEmailObj.getobjEmailMsgWrapper();
           viewEmailObj.UpdateReadEmailStatus();
           viewEmailObj.emailReplyBody = 'Test';
           viewEmailObj.currentPartId = participantList[0].id;
           viewEmailObj.ReplyEmail();
           viewEmailObj.BackToProject();
           viewEmailObj.first();
           viewEmailObj.next();
           viewEmailObj.previous();
           viewEmailObj.last();
           viewEmailObj.getTotalRecord();
           viewEmailObj.getTotalPages();
           viewEmailObj.sortParticipantList();
           
           ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(scEmailObj);
           UR_ViewScheduleEmailCtrl viewScheduleobj = new UR_ViewScheduleEmailCtrl(sc1);
           viewScheduleobj.objProject = projectObjList[0];
           viewScheduleobj.isEditable = true;
           viewScheduleobj.viewTemplateId = emailTemplateList[0].Id;
           viewScheduleobj.showEmailBody();
           viewScheduleobj.participantJobId = participantList[0].id;
           viewScheduleobj.removeParticipant();
           viewScheduleobj.scheduleJobId = scEmailObj.id;
           viewScheduleobj.cancelSchedulejob(); 
           ApexPages.currentPage().getParameters().put('strPartId',participantObj.Id);
           viewScheduleobj.resendEmail();
           viewScheduleobj.reScheduleJobId = scEmailObj.id;
           viewScheduleobj.scheduleEmail.Schedule_Email_Date__c = Date.today().addDays(1);
           viewScheduleobj.scheduleEmail.Schedule_Email_Time__c = '10';
           viewScheduleobj.reScheduleEmail();
       } 
    }
}