/*
@Author:        Prashant Bhatt
@Created Date:  12/11/2019 
@Description:   Test Class for AutoFwdEmail
*/
@IsTest
public class AutoFwdEmailTest {

        static testMethod void testMethod1()
        {
             UserRole role = new UserRole(DeveloperName = 'sales_mm_np_xx01', Name = 'sales_mm_np_xx');
             insert role;
            
             User testSysAdminUser = new User(alias = 'standt', email='standarduser@testorg.com', 
             emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
             localesidkey='en_US', profileId = [select id from profile where name='System Administrator' LIMIT 1].Id, 
             timezonesidkey='America/Los_Angeles',UserRoleId = role.Id, username='ASstandarduser@testorg.com');
            
            insert testSysAdminUser;
            System.runAs(testSysAdminUser)
            {
              Account a = new Account(Name='testaccount',OwnerId=testSysAdminUser.Id);
              insert a;
              Contact  contact = new Contact(lastName='TestContact', Email='test@test.com',AccountId=a.Id);
              insert contact;
              
              Messaging.InboundEmail email = new Messaging.InboundEmail() ;
              Messaging.InboundEnvelope env   = new Messaging.InboundEnvelope();

              email.subject = 'Create email forwarding';
              email.plainTextBody = 'FromEmail';
              email.fromAddress = 'test@test.com';
              email.toAddresses = new List<String>{'test1@test.com'};
              
              Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header(); 
              email.headers=new Messaging.InboundEmail.Header[1]; 
              hditem.name='Date';
              hditem.value='Tue, 06 Dec 2019 14:08:37 -0700'; 
              email.headers[0]=hditem;
                  
              // add an Binary attachment
              Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
              attachment.body = blob.valueOf('my attachment text');
              attachment.fileName = 'textfileone.txt';
              attachment.mimeTypeSubType = 'text/plain';
              attachment.headers=new Messaging.InboundEmail.Header[1]; 
              attachment.headers[0]= hditem;       
              email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
              // add an Text atatchment
    
              Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
                
              attachmenttext.body = 'my attachment text';
              attachmenttext.fileName = 'textfiletwo3.txt';
              attachmenttext.mimeTypeSubType = 'texttwo/plain';
              attachmenttext.headers=new Messaging.InboundEmail.Header[1]; 
              attachmenttext.headers[0]= hditem; 
              email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
                    
              //define a fixed search result in order to test the SOSL query
              Id [] fixedSearchResults= new Id[1];
              fixedSearchResults[0] = contact.Id;
              Test.setFixedSearchResults(fixedSearchResults);
              List<List<SObject>> searchList = [FIND 'test@test.com'
                                                  IN ALL FIELDS RETURNING
                                                Contact(Id,Email, AccountId LIMIT 1)];
                
              AutoFwdEmail automatedEmailForwarding = new AutoFwdEmail();
              automatedEmailForwarding.handleInboundEmail(email,env); 
        }
      }

}