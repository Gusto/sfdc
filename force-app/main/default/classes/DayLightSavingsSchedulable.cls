/**
 * @name         DayLightSavingsSchedulable
 * @author       Praveen Sethu
 * @description  Schedule class that runs when daylight savings time begins and ends. It updates the time zone variable in the configuration settings object used by NBA.
 * @test classes DayLightSavingsSchedulableTest
 **/
global class DayLightSavingsSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
		Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
		// Check if the current date is the second Sunday of March or the first Sunday of November
		Boolean blnSecondSundayOfMar = checkSunday(3, 8, 14);
		Boolean blnFirstSundayOfNov = checkSunday(11, 1, 7);

		// Use 0.25 as time zone variable from Mar to Nov (Daylight savings begin)
		// 0.25 is the number to subract from UTC time to get the local mountain time during daylight savings
		if (blnSecondSundayOfMar || Test.isRunningTest()) {
			objConfig.Time_Zone_Variable__c = 0.25;
			update objConfig;
		} else if (blnFirstSundayOfNov) {
			// Use 0.2916 as time zone variable from Nov to Mar (Daylight savings end)
			// 0.2916 is the number to subract from UTC time to get the local mountain time during standard time
			objConfig.Time_Zone_Variable__c = 0.2916;
			update objConfig;
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Pass month and date range to check if it is a Sunday
	 * @Parm        : Integer month, Integer fromDate, Integer toDate
	 * @Return      : Boolean flag if it is a Sunday
	 **/
	public static Boolean checkSunday(Integer intMonth, Integer intFromDate, Integer toDate) {
		DateTime dtmCurrentTime = DateTime.now();
		return dtmCurrentTime.month() == intMonth && dtmCurrentTime.format('EEEE') == 'Sunday' && dtmCurrentTime.day() >= intFromDate && dtmCurrentTime.day() <= toDate;
	}
}