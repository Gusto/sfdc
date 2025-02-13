/**
 * @author        Soujanya Nentur
 * @description   Test Class validating  Closed Batch correctly updates case owner based on Record Type.
 * Date:          03/06/2023
 **/

 @isTest
 public class AutoUpdateEngagementClosedCasesTest {
     public static final String ENGAGEMENT_CASES_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Engagement_Cases');
 
     @TestSetup
     static void setup() {
         List<Case> list_InsertTestCases = new List<Case>();
         List<Case_Reason_Classification__c> list_InsertCaseReasonClassifications = new List<Case_Reason_Classification__c>();
 
         AccountTriggerHelper.skipTrigger = true;
         ContactTriggerHelper.skipTrigger = true;
 
         // Create new company account
         Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
         insert objAccount;
 
         // Create new company Contact
         Contact objContact = new TestDataFactory.ContactBuilder()
             .setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
             .setAccountId(objAccount.Id)
             .setFirstName('Test First Name')
             .setLastName('Test Last Name')
             .setEmail('StatusAutoUpdateBatch@test.com')
             .build();
         insert objContact;
 
         AccountTriggerHelper.skipTrigger = false;
         ContactTriggerHelper.skipTrigger = false;
 
         Case_Reason_Classification__c objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder()
             .setName('No Action or Wrong Email')
             .setIsActive(true)
             .setReasonCode('no_action_or_wrong_email')
             .setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
             .setType('Engagement')
             .setRoutingTeam('External')
             .setSupportLevel(CaseUtils.TIER_1)
             .build();
         list_InsertCaseReasonClassifications.add(objCaseReasonClassification);
 
         insert list_InsertCaseReasonClassifications;
 
         Case objCase1 = new TestDataFactory.CaseBuilder()
             .setAccountId(objAccount.Id)
             .setContactId(objContact.Id)
             .setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
             .setSubject('Test Closed Case')
             .setSuppliedEmail('TestCaseClosure@test.com')
             .setOrigin(CaseUtils.ORIGIN_PHONE)
             .setDescription('Test Closed Case')
             .setConfirmCaseReasonClassification(objCaseReasonClassification.Id)
             .setConfirmCaseReason(objCaseReasonClassification.Name)
             .setAudience('Employee')
             .build();
         list_InsertTestCases.add(objCase1);
 
         if (!list_InsertTestCases.isEmpty()) {
             CaseTriggerHelper.skipTrigger = true;
             insert list_InsertTestCases;
             CaseTriggerHelper.skipTrigger = false;
         }
     }
 
     /**
      * @author          Soujanya Nentur
      * @description     Test Method to verify owner change upon batch run
      **/
     @isTest
     static void TestClosedCases() {
         Case objCaseUpdate = [SELECT Id, Status, OwnerId FROM Case WHERE subject = 'Test Closed Case'];
         objCaseUpdate.OwnerId = ENGAGEMENT_CASES_QUEUE_ID;
         objCaseUpdate.Status = 'Closed';
         update objCaseUpdate;
 
         Test.startTest();
         AutoUpdateEngagementClosedCases job = new AutoUpdateEngagementClosedCases();
         Integer intYear = Date.today().year() + 1;
         String strCronExpr = '0 0 0 15 3 ? ' + intYear;
         String strJobId = System.schedule('job name', strCronExpr, job);
         job.execute(null);
         Test.stopTest();
 
         Case objCase = [SELECT Id, Status, OwnerId FROM Case WHERE subject = 'Test Closed Case'];
         Group objGroup = [SELECT id, name FROM Group WHERE Type = 'queue' AND name = 'Payroll Care - Non Actionable'];
 
         System.assertEquals(objCase.OwnerId, objGroup.Id, 'Owner is not changed to Payroll Care Non Actionable');
     }
 }