@isTest
public class PartnerNPSAndChurnNotificationsSchTest {
	@isTest
    private static void unitTest(){
        Test.startTest();
        String jobId = System.schedule('PartnerNPSAndChurnNotificationsSch Scheduler Test', '0 05 * * * ?', new PartnerNPSAndChurnNotificationsSch());
        CronTrigger objConTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals('0 05 * * * ?', objConTrigger.CronExpression);
        System.assertEquals(0, objConTrigger.TimesTriggered);
        Test.stopTest();
    }
}