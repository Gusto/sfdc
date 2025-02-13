@isTest
public without sharing class AttachmentRelatedAccountCasesCntTest {
    @testSetup 
    static void setUp() {
        Account accRec1 = new Account();
    	accRec1.Name = 'Test Demo AccountName 1';
    	accRec1.BillingStreet = 'Testing Avenue 1';
    	accRec1.BillingPostalCode = '123456';
    	accRec1.Company_Trade_Name__c = 'Company trade name 1';
    	accRec1.Phone = '19992344444';
    	accRec1.ShippingStreet = 'Testing Avenue 1';
    	accRec1.ShippingPostalCode = '123455';
    	accRec1.ZP_Company_ID__c = '5464365436434';
    	insert accRec1;

        Contact contact = new Contact();
        contact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
        contact.Phone = '1234567890';
        contact.FirstName = 'Test';
        contact.LastName = 'TestEngagementCaseViewExtension';            
        contact.AccountId = accRec1.id;
        contact.Email = 'EngagementUser@gusto1.com';
        insert contact;

        Case cse = new Case();
        cse.AccountId=accRec1.id;
        cse.ContactId=contact.id;
        insert Cse;
    }
    static testMethod void testAttachmentRelatedAccountCases() {
        List<Case> caseList = [Select id, AccountId,ContactId from Case];
        PageReference accPage = Page.AttachmentRelatedAccountCases;
        Test.setCurrentPage(accPage);
        ApexPages.currentPage().getParameters().put('id', caseList[0].Id);
        ApexPages.currentPage().getParameters().put('sortField', 'Parent.Account.Name');
        AttachmentRelatedAccountCasesController ctrlObj = new AttachmentRelatedAccountCasesController();
        ctrlObj.strSearch = 'test';
        List<SelectOption> selOpts=ctrlObj.getItems();
        ctrlObj.next();
        ctrlObj.previous();
        ctrlObj.filter = 'Company';
        ctrlObj.init();
        ctrlObj.filter = 'Contact';
        ctrlObj.init();
        ctrlObj.filter = 'CompanyContact';
        ctrlObj.init();
		list<EmailMessage> lstEmailMessage = ctrlObj.allEmailMessageList;

    }
}