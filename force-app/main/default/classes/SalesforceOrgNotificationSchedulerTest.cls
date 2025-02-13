/**
 * @author Yogesh Kherajani
 * @since 02/20/2024
 **/
@isTest
public class SalesforceOrgNotificationSchedulerTest {
    //Uni test to test if the scheduler is correctly working
	@isTest
    private static void unitTest(){
        Test.startTest();
        String jobId = System.schedule('SalesforceOrgNotificationScheduler Scheduler Test', '0 05 * * * ?', new SalesforceOrgNotificationScheduler());
        CronTrigger objConTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals('0 05 * * * ?', objConTrigger.CronExpression);
        System.assertEquals(0, objConTrigger.TimesTriggered);
        Test.stopTest();
    }
}