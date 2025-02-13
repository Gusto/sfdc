/**
* @name         : InsuranceQuoteEmailBatchTest
* @author       : Debasmita Rawooth
* @date         : 10-08-2021
* @description  : Test Class for InsuranceQuoteEmailBatch
* @test classes : NA
**/
@isTest
public with sharing class InsuranceQuoteEmailBatchTest {
    @testSetup
    static void testData() {
        List<Account> list_Accounts;
        List<Opportunity> list_Opportunities;
        List<Contact> list_Contacts;
        List<OpportunityContactRole> list_OpportunityContactRoles;
        List<User> list_Users;
        
        Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setInsuranceQuoteBatchSize(10).build();
        
        insert objConfigSettings;
        
        User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(objCurrentUser) {
            User objUser1 = new TestDataFactory.UserBuilder()
                .setUserName('testuser@insurancequotegusto.com')
                .setFirstName('User1')
                .setLastName('Test User')
                .setEmail('testuser@insurancequotegusto.com')
                .setProfileId(UserInfo.getProfileId())
                .setTimeZoneSidKey('America/Denver')
                .setLocaleSidKey('en_US')
                .setLanguageLocaleKey('en_US')
                .setEmailEncoding('ISO-8859-1')
                .setAlias('test')
                .setIsActive(true)
                .build();
            User objUser2 = new TestDataFactory.UserBuilder()
                .setUserName('testuser2@insurancequotegusto.com')
                .setFirstName('User2')
                .setLastName('Test User2')
                .setEmail('testuser2@insurancequotegusto.com')
                .setProfileId(UserInfo.getProfileId())
                .setTimeZoneSidKey('America/Denver')
                .setLocaleSidKey('en_US')
                .setLanguageLocaleKey('en_US')
                .setEmailEncoding('ISO-8859-1')
                .setAlias('test')
                .setIsActive(true)
                .build();
            list_Users = new List<User>{ objUser1, objUser2 };
                UserTriggerHelper.skipTrigger = true;
            insert list_Users;
        }
        
        Account objAccount1 = new TestDataFactory.AccountBuilder()
            .setRecordTypeId('Company')
            .setName('Test Acc1')
            .setZpCompanyId('11111111111111')
            .build();
        
        Account objAccount2 = new TestDataFactory.AccountBuilder()
            .setRecordTypeId('Company')
            .setName('Test Acc2')
            .setZpCompanyId('22222222222222')
            .build();
        
        Account objAccount3 = new TestDataFactory.AccountBuilder()
            .setRecordTypeId('Company')
            .setName('Test Acc3')
            .setZpCompanyId('33333333333333')
            .build();
        
        Account objAccount4 = new TestDataFactory.AccountBuilder()
            .setRecordTypeId('Company')
            .setName('Test Acc4')
            .setZpCompanyId('44444444444444')
            .build();
        
        Account objAccount5 = new TestDataFactory.AccountBuilder()
            .setRecordTypeId('Company')
            .setName('Test Acc5')
            .setZpCompanyId('55555555555555')
            .build();
        
        list_Accounts = new List<Account>{ objAccount1, objAccount2, objAccount3, objAccount4, objAccount5 };
            AccountTriggerHelper.skipTrigger = true;
        insert list_Accounts;
        
        Opportunity objOpportunity1 = new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
            .setName('Test Opp1')
            .setAccountId(list_Accounts[0].Id)
            .setStage('Open')
            .setCloseDate(System.today())
            .build();
        
        Opportunity objOpportunity2 = new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
            .setName('Test Opp2')
            .setAccountId(list_Accounts[1].Id)
            .setStage('Open')
            .setCloseDate(System.today())
            .build();
        
        Opportunity objOpportunity3 = new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
            .setName('Test Opp3')
            .setAccountId(list_Accounts[2].Id)
            .setStage('Open')
            .setCloseDate(System.today())
            .build();
        
        Opportunity objOpportunity4 = new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
            .setName('Test Opp4')
            .setAccountId(list_Accounts[3].Id)
            .setStage('Open')
            .setCloseDate(System.today())
            .build();
        
        Opportunity objOpportunity5 = new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
            .setName('Test Opp5')
            .setAccountId(list_Accounts[4].Id)
            .setStage('Open')
            .setCloseDate(System.today())
            .build();
        
        list_Opportunities = new List<Opportunity>{ objOpportunity1, objOpportunity2, objOpportunity3, objOpportunity4, objOpportunity5 };
            OpportunityTriggerHelper.skipTrigger = true;
        insert list_Opportunities;
        
        Contact objContact1 = new TestDataFactory.ContactBuilder()
            .setRecordTypeId('Company')
            .setAccountId(list_Accounts[2].Id)
            .setFirstName('Test New')
            .setLastName('Contact 1')
            .setEmail('testcontactemail@test.com')
            .setZPUserRole('Primary Payroll Admin')
            .build();
        
        Contact objContact2 = new TestDataFactory.ContactBuilder()
            .setRecordTypeId('Company')
            .setAccountId(list_Accounts[3].Id)
            .setFirstName('Test New')
            .setLastName('Contact 2')
            .setEmail('testcontactemail2@test.com')
            .setZPUserRole('Payroll Admin')
            .build();
        
        list_Contacts = new List<Contact>{ objContact1, objContact2 };
            ContactTriggerHelper.skiptrigger = true;
        insert list_Contacts;
        
        List<EmailTemplate> list_EmailTemplates = [SELECT Id, Name, Subject, Body FROM EmailTemplate WHERE DeveloperName = :Label.HI_QuoteEmailTemplate];
        
        EmailMessage objEmailMessage1 = new TestDataFactory.EmailMessageBuilder()
            .setSubject(Label.HI_QuoteEmailSubject)
            .setToAddress('testcontactemail@test.com')
            .setIncoming(true)
            .build();
        
        objEmailMessage1.RelatedToId = list_Opportunities[0].Id;
        EmailMessageTriggerHelper.skipTrigger = true;
        insert objEmailMessage1;
    }
    
    /**
* @Author      : Debasmita Rawooth
* @Description : Test with EmailMessage
* @Parm        : void
* @Return      : void
**/
    @isTest
    static void testInsuranceQuoteEmailBatch() {
        List<User> list_Users = [SELECT Id, Name FROM User];
        List<Account> list_Accounts = [SELECT Id, Name FROM Account ORDER BY Name ASC];
        List<Opportunity> list_Opportunities = [SELECT Id, RecordTypeId, Name FROM Opportunity ORDER BY Name ASC];
        List<Insurance_Quote__c> list_InsuranceQuotes;
        
        Insurance_Quote__c objInsuranceQuote1 = new TestDataFactory.InsuranceQuoteBuilder()
            .setAccountId(list_Accounts[0].Id)
            .setOpportunityId(list_Opportunities[0].Id)
            .setSalesRepId(list_Users[0].Id)
            .setQuoteLink('www.testquotelink.com')
            .setCensusLink('www.testcensuslink.com')
            .setCensusPartTimeEmployees(45)
            .setPlannedW2Hires(120)
            .build();
        
        insert objInsuranceQuote1;
        
        Test.startTest();
        
        // Set a sample cron expression
        String strCronExp = '0 0 0 15 3 ? 2025';
        InsuranceQuoteEmailBatchScheduler objScheduler = new InsuranceQuoteEmailBatchScheduler();
        String jobId = System.schedule('Test InsuranceQuoteEmailBatch', strCronExp, objScheduler);
        // Directly call Scheduler's execute method
        objScheduler.execute(null);
        
        Test.stopTest();
        
        Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Status__c, Processing_State__c, Date_Quote_Sent__c FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote1.Id];
        if(OrganizationUtilities.canSendEmails()){
            System.assertEquals('Processed', objInsuranceQuoteAssert.Processing_State__c);
            System.assertNotEquals(null, objInsuranceQuoteAssert.Date_Quote_Sent__c);
        }
    }
    
    /**
* @Author      : Debasmita Rawooth
* @Description : Test with Contacts
* @Parm        : void
* @Return      : void
**/
    @isTest
    static void testInsuranceQuoteEmailBatch2() {
        List<User> list_Users = [SELECT Id, Name FROM User];
        List<Account> list_Accounts = [SELECT Id, Name FROM Account ORDER BY Name ASC];
        List<Opportunity> list_Opportunities = [SELECT Id, RecordTypeId, Name FROM Opportunity ORDER BY Name ASC];
        List<Insurance_Quote__c> list_InsuranceQuotes;
        
        Insurance_Quote__c objInsuranceQuote1 = new TestDataFactory.InsuranceQuoteBuilder()
            .setAccountId(list_Accounts[2].Id)
            .setOpportunityId(list_Opportunities[2].Id)
            .setSalesRepId(list_Users[0].Id)
            .setQuoteLink('www.testquotelink.com')
            .setCensusLink('www.testcensuslink.com')
            .setCensusPartTimeEmployees(45)
            .setPlannedW2Hires(120)
            .build();
        
        Insurance_Quote__c objInsuranceQuote2 = new TestDataFactory.InsuranceQuoteBuilder()
            .setAccountId(list_Accounts[3].Id)
            .setOpportunityId(list_Opportunities[3].Id)
            .setSalesRepId(list_Users[1].Id)
            .setQuoteLink('www.testquotelink.com')
            .setCensusLink('www.testcensuslink.com')
            .setCensusPartTimeEmployees(45)
            .setPlannedW2Hires(120)
            .build();
        
        list_InsuranceQuotes = new List<Insurance_Quote__c>{ objInsuranceQuote1, objInsuranceQuote2 };
            insert list_InsuranceQuotes;
        
        Test.startTest();
        
        // Set a sample cron expression
        String strCronExp = '0 0 0 15 3 ? 2025';
        InsuranceQuoteEmailBatchScheduler objScheduler = new InsuranceQuoteEmailBatchScheduler();
        String jobId = System.schedule('Test InsuranceQuoteEmailBatch', strCronExp, objScheduler);
        // Directly call Scheduler's execute method
        objScheduler.execute(null);
        
        Test.stopTest();
        
        List<Insurance_Quote__c> list_InsuranceQuoteAssert = [SELECT Id, Status__c, Processing_State__c, Date_Quote_Sent__c FROM Insurance_Quote__c];
        if(OrganizationUtilities.canSendEmails()){
            System.assertEquals('Processed', list_InsuranceQuoteAssert[0].Processing_State__c);
            System.assertNotEquals(null, list_InsuranceQuoteAssert[0].Date_Quote_Sent__c);
            System.assertEquals('Processed', list_InsuranceQuoteAssert[1].Processing_State__c);
            System.assertNotEquals(null, list_InsuranceQuoteAssert[1].Date_Quote_Sent__c);
        }
    }
    
    /**
* @Author      : Debasmita Rawooth
* @Description : Test Negative scenario where no email is sent
* @Parm        : void
* @Return      : void
**/
    @isTest
    static void testInsuranceQuoteEmailBatchNegative() {
        List<User> list_Users = [SELECT Id, Name FROM User];
        List<Account> list_Accounts = [SELECT Id, Name FROM Account ORDER BY Name ASC];
        List<Opportunity> list_Opportunities = [SELECT Id, RecordTypeId, Name FROM Opportunity ORDER BY Name ASC];
        List<Insurance_Quote__c> list_InsuranceQuotes;
        
        Insurance_Quote__c objInsuranceQuote1 = new TestDataFactory.InsuranceQuoteBuilder()
            .setAccountId(list_Accounts[1].Id)
            .setOpportunityId(list_Opportunities[1].Id)
            .setSalesRepId(list_Users[0].Id)
            .setQuoteLink('www.testquotelink.com')
            .setCensusLink('www.testcensuslink.com')
            .setCensusPartTimeEmployees(45)
            .setPlannedW2Hires(120)
            .build();
        
        insert objInsuranceQuote1;
        
        Test.startTest();
        
        // Set a sample cron expression
        String strCronExp = '0 0 0 15 3 ? 2025';
        InsuranceQuoteEmailBatchScheduler objScheduler = new InsuranceQuoteEmailBatchScheduler();
        String jobId = System.schedule('Test InsuranceQuoteEmailBatch', strCronExp, objScheduler);
        // Directly call Scheduler's execute method
        objScheduler.execute(null);
        
        Test.stopTest();
        
        Insurance_Quote__c objInsuranceQuoteAssert = [SELECT Id, Status__c, Processing_State__c, Date_Quote_Sent__c FROM Insurance_Quote__c WHERE Id = :objInsuranceQuote1.Id];
        System.assertEquals('Queued', objInsuranceQuoteAssert.Processing_State__c);
        System.assertEquals(null, objInsuranceQuoteAssert.Date_Quote_Sent__c);
    }
}