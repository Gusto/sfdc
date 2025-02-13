/**
 * @name         TaxResNoticeIndexThresholdsCntrl
 * @author       Shyam Nasare
 * @date         02/16/2024
 * @description  Used by LWC component "taxResNoticeIndexThresholds"
 * @see          TaxResNoticeIndexThresholdsCntrlTest
 **/
public with sharing class TaxResNoticeIndexThresholdsCntrl {
	@AuraEnabled(cacheable=true)
	public static TaxResIndexNoticeThresholds__c getBelowToleranceThreshold() {
		TaxResIndexNoticeThresholds__c objBelowToleranceThreshold = TaxResIndexNoticeThresholds__c.getValues(CaseUtils.BELOW_TOLERANCE_THRESHOLD_CUSTOM_SETTING);
		return objBelowToleranceThreshold;
	}

	@AuraEnabled
	public static void updateThresholdValue(String thresholdValue) {
		try {
			TaxResIndexNoticeThresholds__c objBelowToleranceThreshold = TaxResIndexNoticeThresholds__c.getInstance(CaseUtils.BELOW_TOLERANCE_THRESHOLD_CUSTOM_SETTING);
			objBelowToleranceThreshold.Value_Decimal__c = Decimal.valueOf(thresholdValue);
			update objBelowToleranceThreshold;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}