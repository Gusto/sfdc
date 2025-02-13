/**
 * Author: Aslam Juneid
 * Description: This test class validates the functionality of the ClientRelationsCaseHandler class, including the creation of Client Relations cases from email messages.
 */
@isTest
public class ClientRelationsCaseHandlerTest {

    /**
     * Author: Aslam Juneid
     * Description: Sets up test data for the test class, including creating an account, contact, and case records.
     */
    @testSetup
    static void setUp() {
        // Skip triggers to prevent unnecessary processing during test setup
        AccountTriggerHelper.skipTrigger = true;
        CaseTriggerHelper.skipTrigger = true;
        OpportunityTriggerHelper.skipTrigger = true;

        List<Case> list_Cases = new List<Case>();
        Test.startTest();
        
        // Create a test account using a utility method
        Account objAccount = TestUtility.CompanyAccount();

        // Create a test contact associated with the account
        Contact objContactRecord = new Contact();
        objContactRecord.FirstName = 'Test Demo';
        objContactRecord.LastName = 'AccountName 1';
        objContactRecord.Phone = '19992344444';
        objContactRecord.MailingStreet = 'Testing Avenue 1';
        objContactRecord.MailingPostalCode = '123455';
        objContactRecord.MobilePhone = '19992344444';
        objContactRecord.OtherPhone = '19992344444';
        objContactRecord.Email = 'test@acme.com';
        objContactRecord.AccountId = objAccount.Id;
        insert objContactRecord;

        // Create a test case using a builder pattern
        Case objCase1 = new TestDataFactory.CaseBuilder()
            .setAccountId(objAccount.Id)
            .setContactId(objContactRecord.Id)
            .setRecordTypeId('Engagement')
            .setSubject('Test Engagement status update')
            .setDescription('Test')
            .setStatus(CaseUtils.STATUS_NEW)
            .setAuthorizedUser('Yes')
            .build();
        list_Cases.add(objCase1);

        // Insert the list of cases
        insert list_Cases;
        Test.stopTest();
    }

    /**
     * Author: Aslam Juneid
     * Description: Tests the creation of a Client Relations case from a forwarded client email.
     */
    @isTest
    static void testForwardClientEmailCaseCreation() {
        // Retrieve and update the test case
        Case objCase = [SELECT Id, AccountId, Status, Origin, Subject FROM Case WHERE Subject = 'Test Engagement status update'];
        objCase.Status = CaseUtils.STATUS_AWAITING_RESPONSE;
        objCase.Origin = CaseUtils.ORIGIN_CHAT;
        update objCase;

        // Create a test email message associated with the case
        Test.startTest();
        EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
            .setParentId(objCase.Id)
            .setFromAddress('test@acme.com')
            .setToAddress(Label.Client_Relations_Email)
            .setIncoming(true)
            .setSubject('test again [ ref:!00DG00hKQi.!500R70Nx2yF:ref ]')
            .setTextBody('test Body please ignore')
            .build();
        objEmailMessage.Status = '3';
        insert objEmailMessage;
        Test.stopTest();

        // Verify that a new Client Relations case is created with the correct subject
        objCase = [SELECT Id, Origin, Channel__c, Subject FROM Case WHERE RecordTypeId = :EmailMessageUtil.RECTYPE_CLIENT_RELATIONS];
        System.assertEquals(objCase.Subject, 'test again');
    }
}