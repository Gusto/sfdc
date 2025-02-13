/**
 * @name         DayLightSavingsSchedulableTest
 * @author       Praveen Sethu
 * @description
 **/
@isTest
public class DayLightSavingsSchedulableTest {
	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if the schedular updates the time zone variable correctly
	 **/
	@isTest
	static void testDaylightSavingsSchedulable() {
		Configuration_Settings__c objConfig = new Configuration_Settings__c(Time_Zone_Variable__c = 0.1, SetupOwnerId = UserInfo.getOrganizationId());
		insert objConfig;

		Test.startTest();
		DayLightSavingsSchedulable obj = new DayLightSavingsSchedulable();
		obj.execute(null);
		Test.stopTest();

		Configuration_Settings__c objConfigAssert = Configuration_Settings__c.getOrgDefaults();
		System.assertEquals(0.25, objConfigAssert.Time_Zone_Variable__c, 'Time zone variable was not updated by schedulable class');
	}
}