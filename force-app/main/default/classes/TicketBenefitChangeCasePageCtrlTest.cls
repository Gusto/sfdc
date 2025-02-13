@isTest
private class TicketBenefitChangeCasePageCtrlTest {
    
    @isTest
    static void unitTestWithoutCase(){
        Test.startTest();
        CaseTriggerHelper.skipTrigger = true;
        
        Ticket__c tck = new Ticket__c();
        tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
        tck.Status__c = 'New';
        tck.Priority__c = 'Low';
        insert tck;
        tck.OwnerId = UserInfo.getUserId();
        update tck;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
        TicketBenefitChangeCasePageCtrl extension = new TicketBenefitChangeCasePageCtrl(stdController);
        extension.initMethod();
        
        Test.stopTest();
    }
    
    @isTest
    static void unitTestWithCase(){
        Test.startTest();
        CaseTriggerHelper.skipTrigger = true;
        
        Case cse = new Case();
        cse.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Change Case');
        cse.Subject='Test';
        cse.Description='Test';
        cse.Type='QLE';
        insert cse;
        
        Ticket__c tck = new Ticket__c();
        tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
        tck.Status__c = 'New';
        tck.Priority__c = 'Low';
        tck.Fulfillment_Case__c = cse.Id;
        insert tck;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
        TicketBenefitChangeCasePageCtrl extension = new TicketBenefitChangeCasePageCtrl(stdController);
        extension.initMethod();
        
        Test.stopTest();
    }
    
    @isTest
    static void unitTestOwner(){
        Test.startTest();
        CaseTriggerHelper.skipTrigger = true;
        
        Ticket__c tck = new Ticket__c();
        tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
        tck.Status__c = 'New';
        tck.Priority__c = 'Low';
        insert tck;
        
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
        UserRole objCCRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];
        User objUser = new TestDataFactory.UserBuilder()
            .setUserName('testhelpertest@gusto.com')
            .setFirstName('testtriggerhelper')
            .setLastName('testTicket')
            .setEmail('testhelpertest@gusto.com')
            .setProfileId(objProfile.Id)
            .setUserRoleId(objCCRole.Id)
            .setTimeZoneSidKey('America/Denver')
            .setLocaleSidKey('en_US')
            .setLanguageLocaleKey('en_US')
            .setEmailEncoding('ISO-8859-1')
            .setAlias('test')
            .setIsActive(true)
            .build();
        
        User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
        System.runAs(objCurrentUser) {
            insert objUser;
        }
        
        tck.OwnerId = objUser.Id;
        update tck;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
        TicketBenefitChangeCasePageCtrl extension = new TicketBenefitChangeCasePageCtrl(stdController);
        extension.initMethod();
        
        Test.stopTest();
    }
}