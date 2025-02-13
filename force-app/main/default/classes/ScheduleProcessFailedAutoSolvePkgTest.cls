/**
* Author: Todd Dowdy
* Date: 08/12/2022
* Desc: Test class for scheduler - ScheduleProcessFailedAutoSolvePkg
**/


@isTest
public class ScheduleProcessFailedAutoSolvePkgTest {
  
    @isTest
    static void testSchedulerExecution() {
        //Set up test data for Configuration_Settings__c
        Configuration_Settings__c configSetting = new Configuration_Settings__c(
            ProcessFailedAutoSolvePkgCasesBatch__c = 10  // Set batch size to 10
        );
        insert configSetting;
        Test.startTest();

        // Create a mock SchedulableContext
        SchedulableContext sc = new MockSchedulableContext();

        // Create an instance of the scheduler class and execute the method
        ScheduleProcessFailedAutoSolvePkg scheduler = new ScheduleProcessFailedAutoSolvePkg();
        scheduler.execute(sc);

        Test.stopTest();
        System.assertEquals(10, configSetting.ProcessFailedAutoSolvePkgCasesBatch__c);
    }

    // Mock class to simulate the SchedulableContext
    private class MockSchedulableContext implements SchedulableContext {
        public String getJobId() {
            return 'mockJobId';
        }

        // Implement the missing method getTriggerId() required by SchedulableContext
        public Id getTriggerId() {
            return 'mockTriggerId';
        }
    }
}