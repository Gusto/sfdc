/**
 * @name         : BatchCloseOverdueOpportunitiesTest
 * @author       : Ankit CS
 * @date         : 11-29-2021
 * @description  : Test class for BatchCloseOverdueOpportunities & SchedulerCloseOverdueOpportunities
**/
@isTest
public class BatchCloseOverdueOpportunitiesTest {
    public static Boolean blnThrowException = false;
    /**
     * @Author      : Ankit CS
     * @Description : Method for test data setup
    **/
    @testSetup
    static void setupData(){
        Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
            .setName('Test Customer Success Opportunity')
            .setCloseDate(System.today() - 5)
            .setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Customer Success'))
            .setStage('New')
            .build();
        OpportunityTriggerHelper.skipTrigger = true;
        insert objOpportunity;
        OpportunityTriggerHelper.skipTrigger = false;

        Configuration_Settings__c objConfig = new TestDataFactory.ConfigurationSettingsBuilder()
            .setCloseOppsBatchSize(10)
            .build();
        insert objConfig;
    }

    /**
     * @Author      : Ankit CS
     * @Description : Test method for SchedulerCloseOverdueOpportunities schedule apex
    **/
    static testMethod void testBatchScheduler() {
        SchedulerCloseOverdueOpportunities objScheduler = new SchedulerCloseOverdueOpportunities();
        String strSchedule = '0 0 0 1 * ? *';
        Test.startTest();
        String strJobId = System.schedule('Test close opps schedule', strSchedule, objScheduler);
        Test.stopTest();

        System.assert(strJobId != null);
        
    }

    /**
     * @Author      : Ankit CS
     * @Description : Test method for BatchCloseOverdueOpportunities batch apex
    **/
    static testMethod void testBatch() {
        Test.startTest();
        BatchCloseOverdueOpportunities objBatchInstance = new BatchCloseOverdueOpportunities();
        Database.executeBatch(objBatchInstance);
        Test.stopTest();

        Opportunity objOpportunity = [SELECT Id, StageName, Closed_via_Automation__c 
                                      FROM Opportunity 
                                      WHERE RecordType.Name = 'Customer Success'];
        System.assertEquals('Closed Lost', objOpportunity.StageName);
        System.assert(objOpportunity.Closed_via_Automation__c);
    }

    /**
     * @Author      : Ankit CS
     * @Description : Test method for BatchCloseOverdueOpportunities batch apex when 
     *                there are exceptions during update
    **/
    static testMethod void testBatchErrors() {
        Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
            .setName('Test Customer Success Opportunity 2')
            .setCloseDate(System.today() - 10)
            .setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Customer Success'))
            .setStage('Attempting Contact')
            .build();
        OpportunityTriggerHelper.skipTrigger = true;
        insert objOpportunity;
        OpportunityTriggerHelper.skipTrigger = false;

        Test.startTest();
        blnThrowException = true;
        BatchCloseOverdueOpportunities objBatchInstance = new BatchCloseOverdueOpportunities();
        Database.executeBatch(objBatchInstance);
        Test.stopTest();

        List<Exception_Log__c> list_ExceptionLogs = [SELECT Id FROM Exception_Log__c];
        System.assert(!list_ExceptionLogs.isEmpty());
    }
}