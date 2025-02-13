/**
 * Created by brent.johnson on 12/15/16.
 */

@isTest
private without sharing class ConfigTest {
	@isTest
	static void batch_size_lead_conversion_test() {
		Config.LeadConversionConfig leadConversion = Config.LeadConversion;
		System.assertNotEquals(null, leadConversion.LEAD_CONVERSION_BATCH_SIZE);
	}

	@isTest
	static void send_notification_email_lead_conversion_test() {
		Config.LeadConversionConfig leadConversion = Config.LeadConversion;
		System.assertNotEquals(null, leadConversion.SEND_NOTIFICATION_EMAIL);
	}

	@isTest
	static void converted_lead_status_lead_conversion_test() {
		Config.LeadConversionConfig leadConversion = Config.LeadConversion;
		System.assertNotEquals(null, leadConversion.CONVERTED_LEAD_STATUS);
	}

	@isTest
	static void get_location_describe_null_test() {
		Test.startTest();
		Map<String, Config.LocationSetting> locationSettingMap = Config.getLocationDescribe();
		Test.stopTest();
		System.assert(locationSettingMap != null);
	}

	@isTest
	static void get_location_describe_test() {
		insertLocationSetting();
		Test.startTest();
		Map<String, Config.LocationSetting> locationSettingMap = Config.getLocationDescribe();
		Test.stopTest();
		System.assert(!locationSettingMap.isEmpty());
	}

	@isTest
	static void describe_location_result_test() {
		insertLocationSetting();
		Map<String, Config.LocationSetting> locationSettingMap = Config.getLocationDescribe();
		Config.LocationSetting locationSetting = locationSettingMap.get('TS');
		Test.startTest();
		Config.DescribeLocationResult describeLocationResult = locationSetting.getDescribe();
		Test.stopTest();
		System.assert(describeLocationResult != null);
	}

	@isTest
	static void get_name_describe_location_result_test() {
		insertLocationSetting();
		Map<String, Config.LocationSetting> locationSettingMap = Config.getLocationDescribe();
		Config.LocationSetting locationSetting = locationSettingMap.get('TS');
		Config.DescribeLocationResult describeLocationResult = locationSetting.getDescribe();
		Test.startTest();
		String result = describeLocationResult.getName();
		Test.stopTest();
		System.assertEquals('TEST', result);
	}

	@isTest
	static void get_code_describe_location_result_test() {
		insertLocationSetting();
		Map<String, Config.LocationSetting> locationSettingMap = Config.getLocationDescribe();
		Config.LocationSetting locationSetting = locationSettingMap.get('TS');
		Config.DescribeLocationResult describeLocationResult = locationSetting.getDescribe();
		Test.startTest();
		String result = describeLocationResult.getCode();
		Test.stopTest();
		System.assertEquals('TS', result);
	}

	@isTest
	static void is_bor_eligible_describe_location_result_test() {
		insertLocationSetting();
		Map<String, Config.LocationSetting> locationSettingMap = Config.getLocationDescribe();
		Config.LocationSetting locationSetting = locationSettingMap.get('TS');
		Config.DescribeLocationResult describeLocationResult = locationSetting.getDescribe();
		Test.startTest();
		Boolean result = describeLocationResult.isBorEligible();
		Test.stopTest();
		System.assert(result);
	}

	@isTest
	static void is_new_plan_eligible_describe_location_result_test() {
		insertLocationSetting();
		Map<String, Config.LocationSetting> locationSettingMap = Config.getLocationDescribe();
		Config.LocationSetting locationSetting = locationSettingMap.get('TS');
		Config.DescribeLocationResult describeLocationResult = locationSetting.getDescribe();
		Test.startTest();
		Boolean result = describeLocationResult.isNewPlanEligible();
		Test.stopTest();
		System.assert(result);
	}

	static void insertLocationSetting() {
		Location_Setting__c locationSetting = createLocationSetting();
		insert locationSetting;
	}

	static Location_Setting__c createLocationSetting() {
		return new Location_Setting__c(Name = 'TEST', Code__c = 'TS', BoR_Eligible__c = true, New_Plan_Eligible__c = true);
	}
}