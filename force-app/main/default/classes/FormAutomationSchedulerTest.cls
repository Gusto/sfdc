/**
 * @name         FormAutomationSchedulerTest
 * @author       Neha Dabas
 * @date         24th June 2020
 * @description  This is a test class for FormAutomationScheduler and FormAutomationBatch
 * @revisions    Date ------------ Name ------------ Comments 
  **/
@isTest
class FormAutomationSchedulerTest {
    @TestSetup
    static void makeData(){
        List<Group> list_Queue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Form_Automation'];
        Id idFormAutomationQueue;
        if(list_Queue != NULL && !list_Queue.isEmpty()){
            idFormAutomationQueue = list_Queue[0].Id;
        }
        Account objAccount = new Account(Name='Test Company Account',ZP_Company_Id__c = '2123234323');
        AccountTriggerHelper.skipTrigger = true;
        insert objAccount;

        Contact objContact = new Contact(AccountId = objAccount.Id, LastName='James', Employee_Id__c = '89809',Email = 'james@test.com');
        ContactTriggerHelper.skipTrigger = true;
        insert objContact;
        Carrier__c objCarrier = new Carrier__c( Submission_Email__c = 'kaiser@test.com',
                                                Submission_Method__c = 'Mapped Form',
                                                Name = 'Kaiser',
                                                State__c = 'CA',
                                                Key__c = 'kaiser_ca');
        Carrier__c objCarrierNoEmail = new Carrier__c(Submission_Method__c = 'Mapped Form',
                                                Name = 'Kaiser',
                                                State__c = 'NY',
                                                Key__c = 'kaiser_ny');
        insert new List<Carrier__c>{objCarrier,objCarrierNoEmail};
        Id idNHECase = Cache.getRecordTypeId('Case', 'MF NHE');
        Id idMemberGrpUpdateCase = Cache.getRecordTypeId('Case', 'MF Member/Group Updates');
        Id idTerminationCase = Cache.getRecordTypeId('Case', 'MF Termination');

        List<Case> list_Cases = new List<Case>();
        list_Cases.add(new Case(RecordTypeId = idNHECase,
                                ContactId = objContact.Id, Form_Fits_Dependents__c = true,
                                Integration_Key__c = 'fd0daef0-6ac6-403b-b3b4-e4f0e156f06d-kaiser_ca', Status = 'New',
                                Form_Fully_Mapped__c = true,Number_of_Forms__c = 1,
                                Carrier__c = objCarrier.Id));
        list_Cases.add(new Case(RecordTypeId = idNHECase,
                                Form_Fits_Dependents__c = true,
                                Integration_Key__c = 'abcd-12dfijk-kaiser_ny', Status = 'New',
                                Form_Fully_Mapped__c = true,Number_of_Forms__c = 1,
                                Carrier__c = objCarrier.Id));
        list_Cases.add(new Case(RecordTypeId = idTerminationCase,
                                ContactId = objContact.Id, Form_Fits_Dependents__c = true,
                                Integration_Key__c = 'abcd-12dflmn-kaiser_ca', Status = 'New',
                                Form_Fully_Mapped__c = true,Number_of_Forms__c = 2,
                                Carrier__c = objCarrier.Id));
        list_Cases.add(new Case(RecordTypeId = idTerminationCase,
                                Form_Fits_Dependents__c = true,
                                Integration_Key__c = 'abcd-12dflmni-kaiser_ca', Status = 'New',
                                Form_Fully_Mapped__c = true,Number_of_Forms__c = 1,
                                Carrier__c = objCarrierNoEmail.Id));
        list_Cases.add(new Case(RecordTypeId = idTerminationCase,
                                Form_Fits_Dependents__c = true,
                                Integration_Key__c = 'abcd-12dflmnij-kaiser_ca', Status = 'New',
                                Form_Fully_Mapped__c = true,Number_of_Forms__c = 1,
                                Carrier__c = objCarrierNoEmail.Id,
                                Missing_Form_Attributes__c = 'test'));
        list_Cases.add(new Case(RecordTypeId = idMemberGrpUpdateCase,
                                Form_Fits_Dependents__c = true,
                                Integration_Key__c = 'fd0daef0-6ac6-403b-b3b4-e4f0e156f06e-kaiser_ca', Status = 'New',
                                Form_Fully_Mapped__c = true,Number_of_Forms__c = 1,
                                Carrier__c = objCarrier.Id,
                                Type = 'Group Updates'));
        CaseTriggerHelper.skipTrigger = true;
        insert list_Cases;

        list_Cases[0].OwnerId=idFormAutomationQueue;
        list_Cases[1].OwnerId=idFormAutomationQueue;
        list_Cases[2].OwnerId=idFormAutomationQueue;
        list_Cases[3].OwnerId=idFormAutomationQueue;
        list_Cases[4].OwnerId=idFormAutomationQueue;
        list_Cases[5].OwnerId=idFormAutomationQueue;
        update list_Cases;
        EmailMessageTriggerHelper.skipTrigger = true;
        EmailMessage message = new EmailMessage(FromAddress='memberfulfillment@gusto.com', RelatedToId = list_Cases[0].Id, Incoming = false,Status = '3');
        EmailMessage message1 = new EmailMessage(FromAddress='memberfulfillment@gusto.com', RelatedToId = list_Cases[5].Id, Incoming = false,Status = '3');
        insert new List<EmailMessage>{message,message1};
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.HI_Fulfillment_Event_Id__c = 'fd0daef0-6ac6-403b-b3b4-e4f0e156f06d';
        cv.State_CArrier_Key__c = 'kaiser_ca';
        cv.State_CArrier_Id__c = '5';
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'TestDocument';
        cv2.PathOnClient = 'TestDocument.pdf';
        cv2.IsMajorVersion = true;
        cv2.VersionData = Blob.valueOf('Test Content');
        cv2.HI_Fulfillment_Event_Id__c = 'fd0daef0-6ac6-403b-b3b4-e4f0e156f06e';
        cv2.State_CArrier_Key__c = 'kaiser_ca';
        cv2.State_CArrier_Id__c = '5';
        
        Insert new List<ContentVersion>{cv,cv2};
    }
    @IsTest
    static void testFormAutomationPositive(){
        
        Test.startTest();
            FormAutomationBatch batch = new FormAutomationBatch();
            Database.executeBatch(batch);
        Test.stopTest();
    }

    static testmethod void testScheduler(){
        Test.startTest();
           Id jobId = System.schedule('Form Automation Job', '0 00 * * * ?', new FormAutomationScheduler());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime  FROM CronTrigger WHERE id = :jobId];  	
        System.assertEquals('0 00 * * * ?', ct.CronExpression);
    }
}