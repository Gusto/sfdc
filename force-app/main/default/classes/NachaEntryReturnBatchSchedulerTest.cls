@isTest
private class NachaEntryReturnBatchSchedulerTest {

    @testsetup
    static void dataMethod(){
        
        ZP_User_Role__c roleRec = new ZP_User_Role__c();
        roleRec.User_Id__c = '00009999000011';
        roleRec.Company_Id__c = '000099990000111';
        roleRec.Type__c = 'Role:Signatory';
        insert roleRec;
        
        Account acc = TestUtility.CompanyAccount();
        acc.ZP_Company_ID__c = '000099990000111';
        update acc;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.Id)
			.setFirstName('Test Contact')
			.setLastName('BatchSchedulerZPNachaEntry')
			.setEmail('BatchZPNachaEntry@gusto.com')
			.setPhone('9999971234')
			.setZPUserId('00009999000011')
			.build();
        
        insert objContact;
        
        Case cse = new Case();
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Recovery Cases');
        cse.AccountId = acc.Id;
        cse.Subject='Test';
        cse.Description='Test';
        cse.Type='Recovery';
        cse.Origin='Panda';
        cse.Event_Type__c = 'Payroll';
        cse.Integration_Key__c = 'zenpayroll-payroll-01010101010101';        
        insert cse;
    }
    
    @isTest
    static void batchRunTest() {
        
        list<ZP_Nacha_Entry_Returns__c> zpList = new list<ZP_Nacha_Entry_Returns__c>();
        
        ZP_Nacha_Entry_Returns__c ZPRec = new ZP_Nacha_Entry_Returns__c();
        ZPRec.Event_Id__c = '333444555';
        ZPRec.Event_Type__c = 'Payroll';
        ZPRec.Id__c = '9991110003';
        ZPRec.External_Key__c = 'zenpayroll-nacha_entry_return-9991110003';
        ZPRec.Error_Code__c = 'R01';
        ZPRec.Company_Id__c = '000099990000111';
        ZPRec.Amount__c = 110;
        ZPRec.Processing_Status__c = 'Error';
        zpList.add(ZPRec);
        
        ZP_Nacha_Entry_Returns__c ZPRec2 = new ZP_Nacha_Entry_Returns__c();
        ZPRec2.Event_Id__c = '01010101010101';
        ZPRec2.Event_Type__c = 'Payroll';
        ZPRec2.Id__c = '9991110004';
        ZPRec2.External_Key__c = 'zenpayroll-nacha_entry_return-9991110004';
        ZPRec2.Error_Code__c = 'R01';
        ZPRec2.Company_Id__c = '000099990000111';
        ZPRec2.Amount__c = 110;
        ZPRec2.Processing_Status__c = 'Error';
        zpList.add(ZPRec2);
        
        ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;        
        insert zpList;
        ZPNachaEntryReturnsTriggerHelper.skipTrigger = false;
        
        test.startTest(); 
            String CRON_EXP = '0 0 * * * ?';
            NachaEntryReturnBatchScheduler sch = new NachaEntryReturnBatchScheduler();
            system.schedule('Hourly Example Batch Schedule job', CRON_EXP, sch); 
        test.stopTest();
       
        
    }
}