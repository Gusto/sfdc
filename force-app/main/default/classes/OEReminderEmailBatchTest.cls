/**
* @name         OEReminderEmailBatchTest
* @author       Neha Dabas
* @date         August 18, 2020
* @description  Test class for OEReminderEmailBatch
* @revisions    Date ------------ Name ------------ Comments       
**/
@isTest
private class OEReminderEmailBatchTest {
    @testsetup
    static void createTestData(){
        AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

        Account objAcc =new Account(Name='test acc1',ZP_Company_Id__c = '100989001');
        insert objAcc;
        Opportunity objOpp = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity','Benefits New Plan'));
        objOpp.AccountId = objAcc.Id;
        objOpp.StageName ='SAL';
        insert objOpp; 
        Opportunity objOpptyRenewal = TestUtility.BenefitsRenewalOpportunity();

        List<Contact> list_Contact = new List<Contact>();
        list_Contact.add(new Contact(FirstName = 'Neha 1',LastName = 'Test August 6 ', Email='neha.dabastest+1@lirik.io', AccountId = objOpp.AccountId));
        list_Contact.add(new Contact(FirstName = 'Neha 2',LastName = 'Test August 6 ', Email='neha.dabastest+2@lirik.io', AccountId = objOpptyRenewal.AccountId));
        insert list_Contact;

        List<Benefit_Order__c> list_BO = new List<Benefit_Order__c>();
        Benefit_Order__c objBONewPlan = new Benefit_Order__c();
        objBONewPlan.Opportunity__c = objOpp.Id;
        objBONewPlan.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c','New Plan');
        objBONewPlan.Open_Enrollment_Start_Date__c = system.today().addDays(-3);
        objBONewPlan.Open_Enrollment_End_Date__c = system.today().addDays(1);
        objBONewPlan.OwnerId = userInfo.getUserId();
        objBONewPlan.Order_Status__c = 'OE Extended';
        list_BO.add(objBONewPlan);
        
		Benefit_Order__c objBORenewal = new Benefit_Order__c();
        objBORenewal.Opportunity__c = objOpptyRenewal.Id;
        objBORenewal.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c','Renewal');
        objBORenewal.Open_Enrollment_Start_Date__c = system.today().addDays(-3);
        objBORenewal.Open_Enrollment_End_Date__c = system.today().addDays(1);
        objBORenewal.OwnerId = userInfo.getUserId();
        objBORenewal.Order_Status__c = 'OE';
        list_BO.add(objBORenewal);

        insert list_BO;

		List<Case> list_Case = new List<Case>();
        Id idNewPlan = Cache.getRecordTypeId('Case','Benefits New Plan Case');
        Id idRenewal = Cache.getRecordTypeId('Case','Benefits Renewal Case');
        list_Case.add(new Case( Subject = 'Test Case 1',contactId = list_Contact[0].Id,
                                AccountId = objOpptyRenewal.AccountId,RecordTypeId = idNewPlan,
                                Priority ='Medium',Direction__c='Inbound',Origin = 'Email',
                                Benefit_Order__c = objBONewPlan.Id,
                                Integration_Id__c = 'hippo-Benefits_New_Plan-'+objOpp.Id,
                                Opportunity__c = objOpp.Id));
        list_Case.add(new Case( Subject = 'Test Case 2',contactId = list_Contact[1].Id,
                                AccountId = objOpp.AccountId,RecordTypeId = idRenewal,
                                Priority ='Medium',Direction__c='Inbound',Origin = 'Email',
                                Benefit_Order__c = objBORenewal.Id,
                                Integration_Id__c = 'hippo-Benefits_Renewal-'+objOpptyRenewal.Id,
                                Opportunity__c = objOpptyRenewal.Id));
		insert list_Case;
    }
    static testmethod void testReminderEmailBatch(){
        test.startTest();
            OEReminderEmailBatch  objBatch = new OEReminderEmailBatch();
            Database.executeBatch(objBatch);
        test.stopTest();
    }
}