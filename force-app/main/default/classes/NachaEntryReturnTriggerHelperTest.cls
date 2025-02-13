@isTest
private class NachaEntryReturnTriggerHelperTest {

    @testsetup
    static void dataMethod(){
        
        ZP_User_Role__c roleRec = new ZP_User_Role__c();
        roleRec.User_Id__c = '0000999900001';
        roleRec.Company_Id__c = '00009999000011';
        roleRec.Type__c = 'Role:Signatory';
        insert roleRec;
        
        Account acc = TestUtility.CompanyAccount();
        acc.ZP_Company_ID__c = '00009999000011';
        update acc;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.Id)
			.setFirstName('Test Contact')
			.setLastName('ZPNachaEntry')
			.setEmail('ZPNachaEntry@gusto.com')
			.setPhone('999999123')
			.setZPUserId('0000999900001')
			.build();

        insert objContact;
        
        Case cse = new Case();
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Recovery Cases');
        cse.AccountId = acc.Id;
        cse.Subject='Test';
        cse.Description='Test';
        cse.Type='Recovery';
        cse.Integration_Key__c = 'zenpayroll-payroll-01010101010101';  
        cse.Event_ID__c ='01010101010101'; 
        cse.Origin='Panda';     
        cse.Bank_Error_Code__c = 'R01';
        cse.Expedite_reason__c = 'Two Day';
        insert cse;

        Recovery_Case_Class_Assignment_Setting__c settingObj = new Recovery_Case_Class_Assignment_Setting__c();
        settingObj.Error_Code__c = 'R01,R02';
        settingObj.Expedite_Reason__c = 'Two Day';
        settingObj.Eligible_Class__c = 'Class 1';
        settingObj.Name = 'CS01';
        settingObj.Recovery_Amount_End_Limit__c = 0.1;
        settingObj.Recovery_Amount_Starting_Limit__c = 50000;
        insert settingObj;
    }
    
    @isTest
    static void rollUPAmtToCaseTest() {
        
        list<Case> tempCaseList = [select id, Initial_Recovery_Amount__c from Case where Event_ID__c ='01010101010101'];
        system.assert(tempCaseList.get(0).Initial_Recovery_Amount__c == null );
        
        Nacha_Entry_Return__c nachaRec = new Nacha_Entry_Return__c();
        nachaRec.Event_Id__c = '01010101010101';
        nachaRec.Event_Type__c = 'Payroll';
        nachaRec.Id__c = '999333000';
        nachaRec.External_Key__c = 'zenpayroll-nacha_entry_return-999333000';
        nachaRec.Error_Code__c = 'R01';
        nachaRec.Company_Id__c = '0000999900001';
        nachaRec.Amount__c = 200;
        nachaRec.Case__c = tempCaseList.get(0).id;
        insert nachaRec;
        
        
        tempCaseList = [select id, Initial_Recovery_Amount__c,Class__c from Case where Event_ID__c ='01010101010101'];
        
        system.assert(tempCaseList.size()>0);
        system.assert(tempCaseList.get(0).Initial_Recovery_Amount__c == 200.00 );
        
        nachaRec.Amount__c = 100;
        update nachaRec;
        
        delete nachaRec;
        undelete nachaRec;
    }
}