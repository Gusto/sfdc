/**
 * @name         : OneHourBatchSchedulerTest
 * @date         : 08-30-2023
 * @description  : Test run Scheduler every one hour to execute batch
 **/
@isTest
public class OneHourBatchSchedulerTest {
    /**
       * @description Setup Test Data
   	**/
    @testSetup
    static void setupData(){
        //Create the configuration setting record to get the batch size for GF Ticket 
        Configuration_Settings__c objConfigSetting = new TestDataFactory.ConfigurationSettingsBuilder()
            .setGFTicketProcessingBatchSize(2)
            .build();
        
		insert objConfigSetting;
    }
    
    /**
       * @description Run batch every one hour
   	**/
	@isTest
    static void oneHourBatchSchedulerUniTest(){
        //Cron Expression to run every hour
        String strCronExp = '0 0 0/1 1/1 * ? *';
        
        Test.startTest();
        //Schedule batch for one hour
		String strJobId = System.schedule('One Hour Batch Scheduler ' + System.now(), strCronExp, new OneHourBatchScheduler());
        
        CronTrigger objConTrigger = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime 
            FROM CronTrigger 
            WHERE Id = :strJobId
        ];
        
        //Verify the expressions are the same
        System.assertEquals(strCronExp, objConTrigger.CronExpression);
        Test.stopTest();
    }
}