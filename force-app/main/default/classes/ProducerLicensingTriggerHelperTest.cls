/**
 * @description  Test class to test inserts and updates of Producer Licensing records
 * @author       Praveen Sethu
 * @date         03-16-2023
 * @see          ProducerLicensingTriggerHelperTest
 **/
@isTest
public class ProducerLicensingTriggerHelperTest {
	@testSetup
	static void setupTestData() {
		User objLicenseUser = new TestDataFactory.UserBuilder()
			.setAlias('testuser')
			.setEmail('licenseuser@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('licenseuser@testorg.com')
            .setAgentSyncTracking('Active')
            .setAgentSyncNPN('11111')
            .setIsActive(true)
			.build();
		objLicenseUser.IsActive = true;
		insert objLicenseUser;
	}

    /**
	 * @description Test if Active License field on User is updated when active Producer Licensing record is created
	 * @author      Praveen Sethu
	 **/
	@isTest
	public static void testProducerLicensingInsert() {
		User objLicenseUser = [SELECT Id FROM User WHERE Email = 'licenseuser@testorg.com'];
		agentsync__Producer_Licensing__c objProducerLicense = new TestDataFactory.ProducerLicenseBuilder().setName('AZ: 190098981').setStateCode('AZ').setUser(objLicenseUser.Id).build();

		Test.startTest();
		insert objProducerLicense;
		Test.stopTest();
        
        // Assert Active License is updated on User
		User objLicenseUserAssert = [SELECT Id, Active_License__c FROM User WHERE Id = :objLicenseUser.Id];
		System.assertEquals('AZ', objLicenseUserAssert.Active_License__c, 'Active License not set on User');
	}

    /**
	 * @description Test if Active License field is reset on User when agentSync user is changed
	 * @author      Praveen Sethu
	 **/
	@isTest
	public static void testProducerLicensingUpdate() {
		User objLicenseUser = [SELECT Id FROM User WHERE Email = 'licenseuser@testorg.com'];
		agentsync__Producer_Licensing__c objProducerLicense = new TestDataFactory.ProducerLicenseBuilder().setName('AZ: 190098981').setStateCode('AZ').setUser(objLicenseUser.Id).build();
		insert objProducerLicense;

		Test.startTest();
		objProducerLicense.agentsync__User__c = UserInfo.getUserId();
		update objProducerLicense;
		Test.stopTest();

        // Assert Active License is reset on User
		User objLicenseUserAssert = [SELECT Id, Active_License__c FROM User WHERE Id = :objLicenseUser.Id];
		System.assertEquals(true, String.isBlank(objLicenseUserAssert.Active_License__c), 'Active License was not updated on User');
	}
}