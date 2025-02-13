/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   02-03-2023
 * @Desc         :   Test class for FireCaseAssignmentRule
**/
@isTest
public class FireCaseAssignmentRuleTest {
    
    @testSetup
    static void setUp() {
        AccountTriggerHelper.skipTrigger = true;
        ContactTriggerHelper.skipTrigger = true;
        CaseTriggerHelper.skipTrigger = true;
        
        Account objAccount = new TestDataFactory.AccountBuilder()
            .setRecordTypeId('Company')
            .setName('TEST ACCOUNT')
            .setJoinedDate(System.today())
            .setZPCompanyId(String.valueOf(Utils.getRandomIntValue(10)))
            .build();
        insert objAccount;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
            .setRecordTypeId('Company')
            .setAccountId(objAccount.Id)
            .setFirstName('TEST CONTACT')
            .setLastName('CONTACT')
            .setEmail('test.contact@gusto.com.temp')
            .setZPUserId(String.valueOf(Utils.getRandomIntValue(10)))
            .build();
        insert objContact;
        
        Case objCase = new TestDataFactory.CaseBuilder()
            .setRecordTypeId('Payroll Care')
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setSubject('Test Case 1 Subject')
            .setDescription('Test Case 1 Description')
            .setSuppliedEmail('test.contact@gusto.com')
            .setType('Payroll Care')
            .setOrigin('Email')
            .setDirection('Inbound')
            .setSuppliedPhone('1234567890')
            .build();
        insert objCase;
        
        AccountTriggerHelper.skipTrigger = false;
        ContactTriggerHelper.skipTrigger = false;
        CaseTriggerHelper.skipTrigger = false;
    }
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Test method to check case assginment rules are triggered
    **/
    @isTest
    public static void testTriggerCaseAssignmentRule() {
        FireCaseAssignmentRule.CaseAssignmentInput objCaseAssignmentInput = new FireCaseAssignmentRule.CaseAssignmentInput();
        
        Test.startTest();
        objCaseAssignmentInput.idUser = UserInfo.getUserId();
        objCaseAssignmentInput.blnPostMessage = true;
        objCaseAssignmentInput.strMessage = 'Test Case reassignment - advocate OOO';
        FireCaseAssignmentRule.triggerCaseAssignmentRule(new List<FireCaseAssignmentRule.CaseAssignmentInput>{ objCaseAssignmentInput });
        Test.stopTest();
        
        List<Case> list_Cases = [Select Id, OwnerId FROM Case WHERE Subject = 'Test Case 1 Subject'];
        String strOwnerId = list_Cases[0].OwnerId;
        
        System.assertEquals(strOwnerId.startsWith('00G'), true);
    }
}