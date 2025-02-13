/**
 * Created by brent.johnson on 12/14/16.
 */

public without sharing class Config {
	public class LeadConversionConfig {
		public final Integer LEAD_CONVERSION_BATCH_SIZE = 50;

		public final String CONVERTED_LEAD_STATUS = 'Converted';

		public final Boolean SEND_NOTIFICATION_EMAIL = false;
	}

	public static LeadConversionConfig LeadConversion {
		get {
			if (LeadConversion == null) {
				return new LeadConversionConfig();
			}
			return LeadConversion;
		}
		set;
	}

	static Map<String, Config.LocationSetting> LOCATION_SETTING_MAP {
		get {
			if (LOCATION_SETTING_MAP == null) {
				LOCATION_SETTING_MAP = new Map<String, Config.LocationSetting>();
				Map<String, Location_Setting__c> LocationSettingMap = Location_Setting__c.getall();
				for (String state : LocationSettingMap.keySet()) {
					Location_Setting__c location_setting = LocationSettingMap.get(state);
					LOCATION_SETTING_MAP.put(location_setting.Code__c, new LocationSetting(location_setting));
				}
			}
			return LOCATION_SETTING_MAP;
		}
		set;
	}

	public static Map<String, Config.LocationSetting> getLocationDescribe() {
		return LOCATION_SETTING_MAP;
	}

	//todo: group by country
	public class LocationSetting {
		Location_Setting__c location_setting;

		LocationSetting(Location_Setting__c location_setting) {
			this.location_setting = location_setting;
		}

		public DescribeLocationResult getDescribe() {
			return new DescribeLocationResult(this);
		}
	}

	public class DescribeLocationResult {
		String name;
		String code;
		Boolean borEligible;
		Boolean newPlanEligible;

		DescribeLocationResult(LocationSetting LocationSetting) {
			this.name = LocationSetting.location_setting.Name;
			this.code = LocationSetting.location_setting.Code__c;
			this.borEligible = LocationSetting.location_setting.BoR_Eligible__c;
			this.newPlanEligible = LocationSetting.location_setting.New_Plan_Eligible__c;
		}

		public String getName() {
			return name;
		}

		public String getCode() {
			return code;
		}

		public Boolean isBorEligible() {
			return borEligible;
		}

		public Boolean isNewPlanEligible() {
			return newPlanEligible;
		}
	}
}