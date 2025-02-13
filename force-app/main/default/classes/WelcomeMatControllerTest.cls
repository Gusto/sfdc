/**
 * @description  Used to test sales users' visibility to sales welcome mat
 * @author       Praveen Sethu
 * @date         07-28-2022
 * @see          NA
 **/
@isTest
public with sharing class WelcomeMatControllerTest {
	@testSetup
	static void setup() {
		List<Welcome_Mat_Config__c> listWelcomeMat = new List<Welcome_Mat_Config__c>();
		Welcome_Mat_Config__c objConfigSales = new Welcome_Mat_Config__c(Name = WelcomeMatController.SALES_LIGHTNING_SETTING, Visibility_Threshold__c = 1);
		listWelcomeMat.add(objConfigSales);
		Welcome_Mat_Config__c objConfigPT = new Welcome_Mat_Config__c(Name = WelcomeMatController.PT_LIGHTNING_SETTING, Visibility_Threshold__c = 1);
		listWelcomeMat.add(objConfigPT);
		
		insert listWelcomeMat; 

		//create user
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('partam')
			.setEmail('user@welcomemat.gmail.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('user@welcomemat.gmail.com')
			.build();
		insert objAdminUser;
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if user is able to see welcome mat for the first time
	 **/
	@isTest
	static void testWelcomeMatVisibilityForFirstTime() {
		User objAdminUser = [SELECT Id FROM User WHERE Email = 'user@welcomemat.gmail.com'];

		Test.startTest();
		System.runAs(objAdminUser) {
			WelcomeMatController.WelcomeMatWrapper objWrapper = WelcomeMatController.showWelcomeMat(WelcomeMatController.SALES_LIGHTNING_SETTING);
			System.assert(objWrapper.blnSuccess);
		}
		Test.stopTest();

		User objUserAssert = [SELECT Id, Welcome_Mat_Disabled__c, Welcome_Mat_Last_Seen_At__c, Welcome_Mat_Count__c FROM User WHERE Id = :objAdminUser.Id];

		System.assertEquals(false, objUserAssert.Welcome_Mat_Disabled__c);
		System.assertEquals(Date.today(), objUserAssert.Welcome_Mat_Last_Seen_At__c);
		System.assertEquals(1, objUserAssert.Welcome_Mat_Count__c);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if user is able not able to see welcome mat for the second time
	 **/
	@isTest
	static void testWelcomeMatForSecondTime() {
		// User should not able to see welcome mat for second time
		User objAdminUser = [SELECT Id FROM User WHERE Email = 'user@welcomemat.gmail.com'];
		Test.startTest();
		System.runAs(objAdminUser) {
			WelcomeMatController.WelcomeMatWrapper objWrapper = WelcomeMatController.showWelcomeMat(WelcomeMatController.SALES_LIGHTNING_SETTING);
			System.assert(objWrapper.blnSuccess);

			objWrapper = WelcomeMatController.showWelcomeMat(WelcomeMatController.SALES_LIGHTNING_SETTING);
			System.assert(objWrapper.blnSuccess == false);
		}
		Test.stopTest();

		User objUserAssert = [SELECT Id, Welcome_Mat_Disabled__c, Welcome_Mat_Last_Seen_At__c, Welcome_Mat_Count__c FROM User WHERE Id = :objAdminUser.Id];

		System.assertEquals(false, objUserAssert.Welcome_Mat_Disabled__c);
		System.assertEquals(Date.today(), objUserAssert.Welcome_Mat_Last_Seen_At__c);
		System.assertEquals(1, objUserAssert.Welcome_Mat_Count__c);
	}

	/**
	 * @author      Debasmita rawooth
	 * @description Test welcome mat for payroll transfers
	 **/
	@isTest
	static void testWelcomeMatForPT() {
		User objAdminUser = [SELECT Id FROM User WHERE Email = 'user@welcomemat.gmail.com'];
		Test.startTest();
		System.runAs(objAdminUser) {
			WelcomeMatController.WelcomeMatWrapper objWrapper = WelcomeMatController.showWelcomeMat(WelcomeMatController.PT_LIGHTNING_SETTING);
			System.assert(objWrapper.blnSuccess);

			objWrapper = WelcomeMatController.showWelcomeMat(WelcomeMatController.PT_LIGHTNING_SETTING);
			System.assert(objWrapper.blnSuccess == false);
		}
		Test.stopTest();

		User objUserAssert = [SELECT Id, Welcome_Mat_Disabled__c, Welcome_Mat_Last_Seen_At__c, Welcome_Mat_Count__c FROM User WHERE Id = :objAdminUser.Id];

		System.assertEquals(false, objUserAssert.Welcome_Mat_Disabled__c);
		System.assertEquals(Date.today(), objUserAssert.Welcome_Mat_Last_Seen_At__c);
		System.assertEquals(1, objUserAssert.Welcome_Mat_Count__c);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if user is able not able to see welcome mat after user choose not to see welcome mat
	 **/
	@isTest
	static void testWelcomeMatDisabled() {
		User objAdminUser = [SELECT Id FROM User WHERE Email = 'user@welcomemat.gmail.com'];
		Test.startTest();
		System.runAs(objAdminUser) {
			Boolean blnUpdateSuccess = WelcomeMatController.updateWelcomeMatPreference(true);

			WelcomeMatController.WelcomeMatWrapper objWrapper = WelcomeMatController.showWelcomeMat(WelcomeMatController.SALES_LIGHTNING_SETTING);
			System.assert(objWrapper.blnSuccess == false);
		}
		Test.stopTest();

		User objUserAssert = [SELECT Id, Welcome_Mat_Disabled__c, Welcome_Mat_Last_Seen_At__c, Welcome_Mat_Count__c FROM User WHERE Id = :objAdminUser.Id];

		System.assertEquals(true, objUserAssert.Welcome_Mat_Disabled__c);
	}
}