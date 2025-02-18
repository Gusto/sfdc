@IsTest
public class OrderBannerHandlerTest {
	
    @TestSetup
    static void setup() {
        
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User' LIMIT 1];
        Profile profile2 = [SELECT Id FROM Profile WHERE Name = 'MMPR User' LIMIT 1];
        UserRole userRole1 = [SELECT Id, Name FROM UserRole WHERE Name ='Payroll Transfer Fulfillment' LIMIT 1];
        UserRole userRole2 = [SELECT Id, Name FROM UserRole WHERE Name ='sales_partner_ae_xx' LIMIT 1];
        
        User objUser;
        User objUser1;
        User objUser2;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
    
    objUser = new TestDataFactory.UserBuilder()
        .setAlias('dummy1')
        .setEmail('user1@example.com')
        .setEmailEncoding('UTF-8')
        .setLastName('User1')
        .setLanguageLocaleKey('en_US')
        .setLocaleSidKey('en_US')
        .setProfileId(profile1.Id)
        .setUserRoleId(userRole1.Id)
        .setClassQueue('Class 1')
        .setUserName('OrderBanneruser1@example.com')
        .setTimeZoneSidKey('America/Los_Angeles')
        .build();
    insert objUser;

    objUser1 = new TestDataFactory.UserBuilder()
        .setAlias('dummy2')
        .setEmail('user2@example.com')
        .setEmailEncoding('UTF-8')
        .setLastName('User2')
        .setLanguageLocaleKey('en_US')
        .setLocaleSidKey('en_US')
        .setProfileId(profile1.Id)
        .setUserRoleId(userRole1.Id)
        .setClassQueue('Class 2')
        .setUserName('OrderBanneruser2@example.com')
        .setTimeZoneSidKey('America/Los_Angeles')
        .build();
    insert objUser1;

    objUser2 = new TestDataFactory.UserBuilder()
        .setAlias('dummy3')
        .setEmail('user3@example.com')
        .setEmailEncoding('UTF-8')
        .setLastName('User3')
        .setLanguageLocaleKey('en_US')
        .setLocaleSidKey('en_US')
        .setProfileId(profile1.Id)
        .setUserRoleId(userRole1.Id)
        .setClassQueue('Class 1')
        .setUserName('OrderBanneruser3@example.com')
        .setTimeZoneSidKey('America/Los_Angeles')
        .build();
    insert objUser2;

}
        
        AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
        Account objAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setPricebook2Id(Test.getStandardPricebookId())
			 .build();
		 INSERT objAccount;

        Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
            .setStage('SAL')
            .setCloseDate(System.today())
            .setName('test opp')
            .setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
            .setAccountId(objAccount.Id)
            .setNumberOfEE(1)
            .setZPCompanyId('12121212121212')
            .setSourceID('12121212121212')
            .setClosedOwnerDivision('Partner')
            .build();
        insert objOpportunity;

        Order objOrder = new TestDataFactory.OrderBuilder()
            .setEffectiveDate(System.today())
            .setAccountId(objAccount.Id)
            .setStatus('Drafted')
            .setFirstCheckDate(System.today().addDays(4))
            .setCommunicationsTimeCommitment(1.5)
            .setPtoTimeCommitment(0)
            .setBenefitsTimeCommitment(0)
            .setStatesTimeCommitment(0.1666)
            .setEmployeeTimeCommitment(2.5308)
            .setPayrollsTimeCommitment(15.2304)
            .build();
        insert objOrder;
        
        GradientWorks__Queue__c queueRecord = new TestDataFactory.GradientWorksQueueBuilder()
            .setName('PT - Orders Queue - Week Test 1')
            .setAssignmentField('ownerId')
            .setSlotIndex(0)
            .build();
        insert queueRecord;
        
        PT_Order_Team_Capacity__c teamCapacity = new TestDataFactory.PTCapacityBuilder()
            .setName('Partner - Week 1')
            .setQueueId(queueRecord.Id)
            .setUsedCapacity(22)
            .setPercentTotalCapacity(50)
            .setTeamDivisionName('Partner')
            .build();
        insert teamCapacity;
        
        /*PT_Order_Team_Capacity__c teamCapacity1 = new TestDataFactory.PTCapacityBuilder()
            .setName('Partner - Week 2')
            .setQueueId(queueRecord.Id)
            .setUsedCapacity(5)
            .setPercentTotalCapacity(50)
            .setTeamDivisionName('Partner')
            .build();
        insert teamCapacity1;*/
        
        
        GradientWorks__QueueUser__c queueUser = new TestDataFactory.GradientWorksQueueUserBuilder()
            .setQueueId(queueRecord.Id)
            .setUserId(objUser1.Id)
            .setUsedCapacity(45)
            .setMaxCapacity(50)
            .build();
        insert queueUser;
        
       /* GradientWorks__QueueUser__c queueUser1 = new TestDataFactory.GradientWorksQueueUserBuilder()
            .setQueueId(queueRecord.Id)
            .setUserId(objUser1.Id)
            .setUsedCapacity(0)
            .setMaxCapacity(100)
            .build();
        insert queueUser;*/
}
    @IsTest
    static void CheckUserProfileRole() {
        
        Id userId = [SELECT Id FROM User wHERE Email = 'user1@example.com'].Id;
        Test.startTest();
       	OrderBannerHandler.checkRoleProfileOfUser(userId);
        Test.stopTest();
        }
    
    @IsTest
    static void CheckPTCapacityMorethan80ExistingProfileAndRole() {
        Decimal totalTimeCommitment = 23;
        String orderStatus = 'Drafted';
        Date firstCheckDate = Date.newInstance(2024, 11, 19);
        String closedOwnerDivision = 'Partner';
        Test.startTest();
       	OrderBannerHandler.QueueResult queueResult = OrderBannerHandler.getQueueRecord(totalTimeCommitment, orderStatus, firstCheckDate, closedOwnerDivision);
        Test.stopTest();
        
        System.assertEquals(true, queueResult.blnUsedCapacityMoreThan80, 'Used capacity should be more than 80');
        
     }
    
    @IsTest
    static void CheckNoRepsWithEnoughCapacity() {
        Decimal totalTimeCommitment = 23;
        String orderStatus = 'Drafted';
        Date firstCheckDate = Date.newInstance(2024, 11, 19);
        String closedOwnerDivision = 'Partner';
        Test.startTest();
       	OrderBannerHandler.QueueResult queueResult = OrderBannerHandler.getQueueRecord(totalTimeCommitment, orderStatus, firstCheckDate, closedOwnerDivision);
        Test.stopTest();
        System.assertEquals(true, queueResult.blnNoRepsWithEnoughCapacity, 'There should be reps with enough capacity');
     }
    
    @IsTest
    static void CheckNoRepswithRightSkillsHaveCapacity() {
        Decimal totalTimeCommitment = 23;
        String orderStatus = 'Drafted';
        Date firstCheckDate = Date.newInstance(2024, 11, 19);
        String closedOwnerDivision = 'Partner';
        GradientWorks__QueueUser__c queueUser = [SELECT Id, GradientWorks__Used_Capacity__c,GradientWorks__Maximum_Capacity__c FROM GradientWorks__QueueUser__c];
        queueUser.GradientWorks__Used_Capacity__c = 10;
        update queueUser;
        
        Test.startTest();
       	OrderBannerHandler.QueueResult queueResult = OrderBannerHandler.getQueueRecord(totalTimeCommitment, orderStatus, firstCheckDate, closedOwnerDivision);
		Test.stopTest();
        System.assertEquals(false, queueResult.blnRtmPtTeamHasCapacity, 'RTM PT team should not have capacity');
     }
    
    @IsTest
    static void CheckPtTeamAtCapacity() {
        Decimal totalTimeCommitment = 50;
        String orderStatus = 'Drafted';
        Date firstCheckDate = Date.newInstance(2024, 11, 19);
        String closedOwnerDivision = 'Partner';
        GradientWorks__QueueUser__c queueUser = [SELECT Id, GradientWorks__Used_Capacity__c,GradientWorks__Maximum_Capacity__c FROM GradientWorks__QueueUser__c];
        queueUser.GradientWorks__Used_Capacity__c = 50;
        update queueUser;
        
        Test.startTest();
       	OrderBannerHandler.QueueResult queueResult = OrderBannerHandler.getQueueRecord(totalTimeCommitment, orderStatus, firstCheckDate, closedOwnerDivision);
		Test.stopTest();
        System.assertEquals(true, queueResult.blnPtTeamIsAtCapacity, 'PT team should be at capacity');
     }
	
}