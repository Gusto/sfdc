/**
 * @author Alex Xiong
 * @description Test class for AlertBannerCtrl
 */
@isTest
public with sharing class AlertBannerCtrlTest {
	/**
	 * @author Alex Xiong
	 * @description test getBanner() method. Uses mocking method b/c Custom Metadata can't be created during tests
	 */
	@isTest
	static void testGetBanner() {
		Test.startTest();
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		User objUser = new TestDataFactory.UserBuilder()
			.setUniqueUserName()
			.setFirstName('')
			.setLastName('Test Active User')
			.setEmail('testactiveuser@gusto.com')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('test')
			.setIsActive(true)
			.build();
		UserTriggerHelper.skipTrigger = true;
		insert objUser;

		System.runAs(objUser) {
			List<AppDefinition> list_Def = [SELECT DurableId, Label FROM AppDefinition LIMIT 1];
			UserAppInfo objUserAppInfo = new UserAppInfo(AppDefinitionId = list_Def[0].DurableId, UserId = objUser.Id, FormFactor = 'Small');
			insert objUserAppInfo;

			String strMessage = AlertBannerCtrl.getBannerTestOnly('Engagement');
			System.assertEquals('This is a banner for Engagement', strMessage, 'Incorrect Message');

			strMessage = AlertBannerCtrl.getBannerTestOnly('Sales');
			System.assertEquals('This is a banner for Sales', strMessage, 'Incorrect Message');

			strMessage = AlertBannerCtrl.getBannerTestOnly('Inactive');
			System.assertEquals(null, strMessage, 'Incorrect Message');
		}

		Test.stopTest();
	}
}