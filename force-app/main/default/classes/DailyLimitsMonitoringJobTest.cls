@isTest
public with sharing class DailyLimitsMonitoringJobTest {
    public static testmethod void testCheckOrgLimits(){
		String strHour = String.valueOf(Datetime.now().hour());
		String strMin = String.valueOf(Datetime.now().minute()); 
		String strSS = String.valueOf(Datetime.now().second());

		//parse to cron expression
		String nextFireTime = strSS + ' ' + strMin + ' ' + strHour + ' * * ?';
		Test.startTest();
		DailyLimitsMonitoringJob objDLMJob = new DailyLimitsMonitoringJob(); 
		System.schedule('testCheckOrgLimits', nextFireTime, objDLMJob);
		Test.stopTest();
	}  
}