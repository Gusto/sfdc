/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   03/27/2023
 * @Desc         :   Test class for AutoClosePhoneRoutingQueueCasesBatch
**/
@isTest
public class AutoClosePhoneRoutingQueueCasesBatchTest {
    
    @TestSetup
    static void setup() {
        AccountTriggerHelper.skipTrigger = true;
        ContactTriggerHelper.skipTrigger = true;
        CaseTriggerHelper.skipTrigger = true;
        String strPhoneRoutingQueueId = GlobalQueryHelper.getQueueIdByDevName('Phone_Routing');
        
        Account objAccount = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account Test Builder')
            .setZPCompanyId('1111111111')
            .build();
        insert objAccount;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
            .setRecordTypeId('Company')
            .setAccountId(objAccount.Id)
            .setFirstName('First Name1')
            .setLastName('Last Name1')
            .setEmail('testuser1@firstcontact.com')
            .build();
        insert objContact;
        
        List<Case> list_Cases = new List<Case>();
        Case objCase = new TestDataFactory.CaseBuilder()
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setRecordTypeId('Payroll Care')
            .setType('Payroll Care')
            .setSubject('Test Phone Routing Case')
            .setOrigin('Email')
            .setDirection('Inbound')
            .setStatus('New')
            .setSuppliedEmail('testuser1@firstcontact.com')
            .setDescription('Test Duplicate Case')
            .setOwnerId(strPhoneRoutingQueueId)
            .build();
        list_Cases.add(objCase);
        insert list_Cases;
        
        AccountTriggerHelper.skipTrigger = false;
        ContactTriggerHelper.skipTrigger = false;
        CaseTriggerHelper.skipTrigger = false;
    }
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Test method for batch AutoClosePhoneRoutingQueueCasesBatch
    **/
    @isTest
    static void testAutoClosePhoneRoutingQueueCasesBatch() {
        List<Case> list_Cases = [SELECT Id FROM Case WHERE Subject = 'Test Phone Routing Case' LIMIT 1];
        
        Datetime dtPastDatetime = Datetime.now().addDays(-3);
        Test.setCreatedDate(list_Cases[0].Id, dtPastDatetime);
        
        Test.startTest();
        AutoClosePhoneRoutingQueueCasesBatch objAutoClosePhoneRoutingQueueCasesBatch = new AutoClosePhoneRoutingQueueCasesBatch();
        Database.executeBatch(objAutoClosePhoneRoutingQueueCasesBatch);
        
        Test.stopTest();
        
        list_Cases = [SELECT Id, Status FROM Case WHERE Subject = 'Test Phone Routing Case' LIMIT 1];
        System.assertEquals(list_Cases[0].Status, 'Closed', 'Phone Routing Cases should Auto-Close after 3 days');
    }

    /**
     * @Author      : Pradeep Chary
     * @Description : Test method for AutoClosePhoneRoutingQueueCasesJob
    **/
    @isTest
    static void testAutoClosePhoneRoutingQueueCasesJob() {
        List<Case> list_Cases = [SELECT Id FROM Case WHERE Subject = 'Test Phone Routing Case' LIMIT 1];
        
        Datetime dtPastDatetime = Datetime.now().addDays(-3);
        Test.setCreatedDate(list_Cases[0].Id, dtPastDatetime);
        
        Test.startTest();
        AutoClosePhoneRoutingQueueCasesJob job = new AutoClosePhoneRoutingQueueCasesJob();
        Integer intYear = Date.today().year() + 1;
        String strCronExpr = '0 0 0 15 3 ? ' + intYear;
        String strJobId = System.schedule('job name', strCronExpr, job);
        job.execute(null);
        Test.stopTest();
    }
    
}