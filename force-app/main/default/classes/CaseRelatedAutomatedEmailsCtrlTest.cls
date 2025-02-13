@isTest
public class CaseRelatedAutomatedEmailsCtrlTest {
    
	@TestSetup
    static void setupData() {  
        Account objAccount = TestUtility.CompanyAccount();
        caseTriggerHelper.skipTrigger=true;
        //Create new Case record.
        Case objCase = new Case();
        objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
        objCase.AccountId = objAccount.Id;
        objCase.Subject = 'Advising Intro Email';
        objCase.Description = 'Test';
        objCase.Type = 'QLE';
        objCase.Origin = 'Email';
        objCase.SuppliedEmail = 'TestEmail_0@gusto.com';
        insert objCase;
		
        //Create new Case record.
        Case objNewCase = new Case();
        objNewCase.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
        objNewCase.AccountId = objAccount.Id;
        objNewCase.Subject = 'Negative Test';
        objNewCase.Description = 'Negative Test';
        objNewCase.Origin = 'Email';
        objNewCase.SuppliedEmail = 'TestEmail_1@gusto.com';
        insert objNewCase;
        
        //Create Email Message on case.	
        EmailMessage objNewEmail = new EmailMessage();
        objNewEmail.FromAddress = 'TestEmail_1@gusto.com';
        objNewEmail.FromName='Test Class User';
        objNewEmail.ToAddress = 'TestEmail_0@gusto.com';
        objNewEmail.Subject = 'Advising Intro Email';
        objNewEmail.TextBody ='Test Email Body';
        objNewEmail.HtmlBody = 'Test Email HMTL Body';
        objNewEmail.Email_Template_Name__c = 'Advising_Intro_Email';
        objNewEmail.RelatedToId = objCase.Id;
        insert objNewEmail;
        
        caseTriggerHelper.skipTrigger=false;
    }
    
    static testMethod void advisingIntroEmailPositiveTest(){
        Test.startTest();
        List<Case> list_Case = [SELECT Id FROM Case WHERE Subject='Advising Intro Email'];
        System.assert(list_Case.size()>0);
        if(list_Case.size()>0){
            ApexPages.StandardController objStdCtrl = new ApexPages.StandardController(list_Case[0]);
            CaseRelatedAutomatedEmailsCtrl obj = new CaseRelatedAutomatedEmailsCtrl(objStdCtrl);
            System.assert(obj.list_AdvisingEmail.size()>0);
        }
        Test.stopTest();
    }   
    
    static testMethod void advisingIntroEmailNegativeTest(){
        Test.startTest();
        List<Case> list_Case = [SELECT Id FROM Case WHERE Subject='Negative Test'];
        System.assert(list_Case.size()>0);
        if(list_Case.size()>0){
            ApexPages.StandardController objStdCtrl = new ApexPages.StandardController(list_Case[0]);
            CaseRelatedAutomatedEmailsCtrl obj = new CaseRelatedAutomatedEmailsCtrl(objStdCtrl);
            System.assert(obj.list_AdvisingEmail.size() == 0);
        }
        Test.stopTest();
    }   
}