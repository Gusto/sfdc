@isTest
private class OEFinalExtensionEmailBatchTest {
    @testsetup
    static void createTestData(){
        AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
        BenefitOrderHelper.skipTrigger = true;
        OpportunityTriggerHelper.skipTrigger=true;
        CarrierOrderTriggerHelper.skipTrigger = true;
        Account objAcc =new Account(Name='test acc1',ZP_Company_Id__c = '100989001');
        insert objAcc;
        Opportunity objOpp = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity','Benefits New Plan'));
        objOpp.AccountId = objAcc.Id;
        objOpp.StageName ='SAL';
        objOpp.Name = 'Test New Plan Opportunity';
        objOpp.CloseDate = System.Today();
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
        objBONewPlan.Open_Enrollment_End_Date__c = system.today().addDays(-1);
        objBONewPlan.Final_Extension_Date__c = system.today();
        objBONewPlan.OwnerId = userInfo.getUserId();
        objBONewPlan.Order_Status__c = 'OE Extended';
        list_BO.add(objBONewPlan);
        
		Benefit_Order__c objBORenewal = new Benefit_Order__c();
        objBORenewal.Opportunity__c = objOpptyRenewal.Id;
        objBORenewal.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c','Renewal');
        objBORenewal.Open_Enrollment_Start_Date__c = system.today().addDays(-3);
        objBORenewal.Open_Enrollment_End_Date__c = system.today().addDays(-1);
        objBOREnewal.Final_Extension_Date__c = system.today();
        objBORenewal.OwnerId = userInfo.getUserId();
        objBORenewal.Order_Status__c = 'OE';
        list_BO.add(objBORenewal);

        insert list_BO;

        Carrier__c objCarrier = new Carrier__c(Name='Test Carrier', Id__c='4536');
        insert objCarrier;
        List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
        Carrier_Order__c objCO = new Carrier_Order__c(Order_Assignment__c = 'Same carrier, plan/group level changes',
                                                        Benefit_Order__c = objBOREnewal.Id,
                                                        Implementation_Stage__c = 'Ready for OE Prep',
                                                        Carrier__c = objCarrier.Id);
        list_CO.add(objCO);
        Carrier_Order__c objCO1 = new Carrier_Order__c(Order_Assignment__c = 'Carrier Switch',
                                                        Benefit_Order__c = objBONewPlan.Id,
                                                        Implementation_Stage__c = 'Ready for OE Prep',
                                                        Carrier__c = objCarrier.Id);
        list_CO.add(objCO1);
        insert list_CO;

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
    static testmethod void testFinalExtensionEmailBatch(){
        test.startTest();
            OEFinalExtensionEmailBatch  objBatch = new OEFinalExtensionEmailBatch();
            Database.executeBatch(objBatch);
        test.stopTest();
        if(OrganizationUtilities.canSendEmails()){
            System.assert([SELECT count() FROM EmailMessage] > 0);
        }
    }
}