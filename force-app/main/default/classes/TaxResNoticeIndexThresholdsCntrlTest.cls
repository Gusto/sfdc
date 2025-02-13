/**
 * @name         TaxResNoticeIndexThresholdsCntrlTest
 * @author       Shyam Nasare
 * @date         02/16/2024
 * @description  test class for TaxResNoticeIndexThresholdsCntrl
 **/
@IsTest
public with sharing class TaxResNoticeIndexThresholdsCntrlTest {
	@IsTest
	static void testBelowToleranceThreshold() {
		List<TaxResIndexNoticeThresholds__c> list_CustomSetting = new List<TaxResIndexNoticeThresholds__c>();

		TaxResIndexNoticeThresholds__c objCustomSetting1 = new TestDataFactory.NoticeIndexThresholdBuilder()
		.setCustomSettingName('Below Tolerance - Total Amount Due')
		.setValueDecimal(50)
		.build();
		list_CustomSetting.add(objCustomSetting1);

		TaxResIndexNoticeThresholds__c objCustomSetting2 = new TestDataFactory.NoticeIndexThresholdBuilder()
		.setCustomSettingName('Below Tolerance Case Types')
		.setValueText('941,944,940')
		.build();
		list_CustomSetting.add(objCustomSetting2);

		insert list_CustomSetting;

		Test.startTest();
		TaxResIndexNoticeThresholds__c objCustomSetting = TaxResNoticeIndexThresholdsCntrl.getBelowToleranceThreshold();
		System.assertEquals(50, objCustomSetting.Value_Decimal__c, 'Custom Setting not created');

		TaxResNoticeIndexThresholdsCntrl.updateThresholdValue('40');
		
		objCustomSetting = TaxResNoticeIndexThresholdsCntrl.getBelowToleranceThreshold();
		System.assertEquals(40, objCustomSetting.Value_Decimal__c, 'Custom Setting not updated');
		Test.stopTest();
	}
}