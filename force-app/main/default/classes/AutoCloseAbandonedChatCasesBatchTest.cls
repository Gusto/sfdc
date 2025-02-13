/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   02/09/2024
 * @Desc         :   Test class for AutoCloseAbandonedChatCasesBatch
**/
@isTest
public class AutoCloseAbandonedChatCasesBatchTest {
    
    @TestSetup
    static void setup() {
        AccountTriggerHelper.skipTrigger = true;
        ContactTriggerHelper.skipTrigger = true;
        CaseTriggerHelper.skipTrigger = true;        
        Account objAccount = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account Test Builder')
            .setZPCompanyId('1111111111')
            .build();
        insert objAccount;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
            .setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
            .setAccountId(objAccount.Id)
            .setFirstName('First Name1')
            .setLastName('Last Name1')
            .setEmail('testuser1@firstcontact.com')
            .build();
        insert objContact;
        
        User objAutomatedUser = [SELECT Id FROM User WHERE Name = 'Automated Process' LIMIT 1];
        
        List<Case> list_Cases = new List<Case>();
        Case objCase = new TestDataFactory.CaseBuilder()
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
            .setType(CaseUtils.TYPE_ENGAGEMENT)
            .setSubject('Test Abandoned Chat Case')
            .setOrigin(CaseUtils.ORIGIN_CHAT)
            .setStatus(CaseUtils.STATUS_OPEN)
            .setSuppliedEmail('testuser1@firstcontact.com')
            .setDescription('Test Duplicate Case')
            .setOwnerId(objAutomatedUser?.Id)
            .build();
        list_Cases.add(objCase);
        
        Case objCase2 = new TestDataFactory.CaseBuilder()
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
            .setType(CaseUtils.TYPE_ENGAGEMENT)
            .setSubject('Test Abandoned Chat Case')
            .setOrigin(CaseUtils.ORIGIN_CHAT)
            .setStatus(CaseUtils.STATUS_OPEN)
            .setSuppliedEmail('testuser1@firstcontact.com')
            .setDescription('Test Duplicate Case1')
            .setOwnerId(objAutomatedUser?.Id)
            .build();
        list_Cases.add(objCase2);
        
        insert list_Cases;
        
        LiveChatVisitor objChatVisitor = new LiveChatVisitor();
        insert objChatVisitor;
        
        LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
            .setChatVisitor(objChatVisitor.Id)
            .setRecordTypeId('External')
            .setCaseId(list_Cases[0].Id)
            .setChatKey('53454364')
            .setDivrid('2606f4a3-d2a6-44d9-8bf9-18de3ce97b25')
            .build();
        insert objLiveChatTranscript;
        
        AccountTriggerHelper.skipTrigger = false;
        ContactTriggerHelper.skipTrigger = false;
        CaseTriggerHelper.skipTrigger = false;
    }
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Test method for batch AutoCloseAbandonedChatCasesBatch
    **/
    @isTest
    static void testAutoCloseAbandonedChatCasesBatch() {
        List<Case> list_Cases = [SELECT Id FROM Case WHERE Subject = 'Test Abandoned Chat Case'];
        Datetime dtPastDatetime = Datetime.now().addDays(-3);
        for (Case objCase : list_Cases) {
            Test.setCreatedDate(objCase.Id, dtPastDatetime);
        }
        
        Set<String> set_OwnerIds = new Set<String>();
        Set<String> set_RecordTypeIds = new Set<String>{ CaseUtils.RECTYPE_ENGAGEMENT };
        Set<String> set_Statuses = new Set<String>{ CaseUtils.STATUS_OPEN };
        Test.startTest();

        List<User> list_Users = [SELECT Id FROM User WHERE Name = 'Automated Process' LIMIT 1];
        if (!list_Users.isEmpty()) {
            set_OwnerIds.add(list_Users[0].Id);
        }
        AutoCloseAbandonedChatCasesBatch objBatch = new AutoCloseAbandonedChatCasesBatch(set_OwnerIds, set_RecordTypeIds, set_Statuses);
        Database.executeBatch(objBatch);
        
        Test.stopTest();
        
        String strStatusClosed = CaseUtils.STATUS_CLOSED;
        list_Cases = [SELECT Id, Status FROM Case WHERE Status = :strStatusClosed LIMIT 1];
        System.assertNotEquals(list_Cases.size(), 0, 'Abandoned Chat Cases should Auto-Close');
    }

    /**
     * @Author      : Pradeep Chary
     * @Description : Test method for batch AutoCloseAbandonedChatCasesJob
    **/
    @isTest
    static void testAutoCloseAbandonedChatCasesJob() {
        List<Case> list_Cases = [SELECT Id FROM Case WHERE Subject = 'Test Abandoned Chat Case'];
        Datetime dtPastDatetime = Datetime.now().addDays(-3);
        for (Case objCase : list_Cases) {
            Test.setCreatedDate(objCase.Id, dtPastDatetime);
        }

        Test.startTest();
        AutoCloseAbandonedChatCasesJob job = new AutoCloseAbandonedChatCasesJob();
        Integer intYear = Date.today().year() + 1;
        String strCronExpr = '0 0 0 15 3 ? ' + intYear;
        String strJobId = System.schedule('job name', strCronExpr, job);
        job.execute(null);
        Test.stopTest();
    }
}