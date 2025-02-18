/**
 * @name         SandboxPostRefreshTest
 * @author       Sanjay Paryani
 * @date         07/07/2020
 * @description  Test Class that covers all methods in SandboxPostRefresh
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
public class SandboxPostRefreshTest {
	// Variables
	static List<User> usrList { get; set; }
    

	@testsetup
	static void init() {
		// Generating a Unique Name
		String orgId = UserInfo.getOrganizationId();
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = orgId + dateString + randomInt;
		UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		insert r;
		// Querying for the Profile record matching the input profile name.
		Profile prof = [SELECT ID FROM Profile WHERE Name = 'System Administrator'];
		List<User> usrList = new List<User>();
		User usr = new User(
			firstname = 'test',
		
            lastname = 'usr',
			email = 'usr' + uniqueName + '@test' + '.com' + '.invalid',
			username = 'usr' + uniqueName + '@test' + '.com',
			alias = uniqueName.substring(18, 23),
			TimeZoneSidkey = 'GMT',
			LocaleSidKey = 'en_US',
			emailencodingKey = 'UTF-8',
			languagelocalekey = 'en_US',
			ProfileId = prof.Id
		);
		usrList.add(usr);
		insert usrList;

		User objThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objThisUser) {
			// SandboxRefresh Custom Setting
			Sandbox_Refresh_Config__c objSandboxRefreshSettings = new TestDataFactory.SandboxPostRefreshSettingsBuilder()
				.setEntAccName('Gusto Entitlement - Please Don\'t Delete')
				.setCompEntProcessId('5521M0000009JbX')
				.setEngBusinessHours('01m1M00000005iX')
				.setEngEntProcessId('5521M0000009JbW')
				.setTaxOpsEntProcessId('5521M0000009JbZ')
				.setVitalsBusinessHours('01m1M00000005ic')
				.setVitalsProcessId('5521M0000009JbY')
				.setDevOrgName('dev')
				.setUATOrgName('test')
				.setIntgnOrgName('intgn')
				.setMaskField('Normalized_Alternate_Email__c;Normalized_Alternate_Email_Domain__c;Normalized_Email__c;Normalized_Email_Domain__c;Touchpoint_Email__c')
				.build();

			insert objSandboxRefreshSettings;
		}

		System.runAs(objThisUser) {
			// Config Custom Setting
			Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder()
				.setPRCEntitlementId('55005000000DovlAAC')
				.setCompEntitlementId('55005000000DovoAAC')
				.setRiskEntiltmentId('55005000000DovnAAC')
				.setTaxOpsEntitlmentId('55005000000DovmAAC')
				.build();

			insert objConfigSettings;
		}
	}

	@isTest
	public static void testSandboxPostRefresh_1() {
		usrList = [SELECT Id, ProfileId FROM User WHERE firstname = 'test' AND lastname = 'usr'];

		System.runAs(usrList.get(0)) {
			Sandbox_User_Unmask__c sbUnmask = new Sandbox_User_Unmask__c();
			sbUnmask.SetupOwnerId = usrList.get(0).id;
			sbUnmask.Unmask_Email__c = true;
			insert sbUnmask;

			SandboxPostRefresh cls = new SandboxPostRefresh();
			Test.testSandboxPostCopyScript(
				cls, // the instantiated class that implements the SandboxPostRefresh interface
				UserInfo.getOrganizationId(), // context org ID
				UserInfo.getOrganizationId(), // context SandboxID
				'sandbox'
			);
		}
	}

	@isTest
	public static void testSandboxPostRefresh_2() {
		usrList = [SELECT Id, ProfileId FROM User WHERE firstname = 'test' AND lastname = 'usr'];

		System.runAs(usrList.get(0)) {
			Sandbox_User_Unmask__c sbUnmask = new Sandbox_User_Unmask__c();
			sbUnmask.SetupOwnerId = usrList.get(0).ProfileId;
			sbUnmask.Unmask_Email__c = true;
			insert sbUnmask;

			SandboxPostRefresh cls = new SandboxPostRefresh();
			Test.testSandboxPostCopyScript(
				cls, // the instantiated class that implements the SandboxPostRefresh interface
				UserInfo.getOrganizationId(), // context org ID
				UserInfo.getOrganizationId(), // context SandboxID
				'sandbox'
			);
		}
	}

	@isTest
	public static void testSandboxPostRefresh_3() {
		usrList = [SELECT Id, ProfileId FROM User WHERE firstname = 'test' AND lastname = 'usr'];

		System.runAs(usrList.get(0)) {
			Sandbox_User_Unmask__c sbUnmask = new Sandbox_User_Unmask__c();
			sbUnmask.SetupOwnerId = usrList.get(0).id;
			sbUnmask.SetupOwnerId = usrList.get(0).ProfileId;
			sbUnmask.Unmask_Email__c = true;
			insert sbUnmask;

			SandboxPostRefresh cls = new SandboxPostRefresh();
			Test.testSandboxPostCopyScript(
				cls, // the instantiated class that implements the SandboxPostRefresh interface
				UserInfo.getOrganizationId(), // context org ID
				UserInfo.getOrganizationId(), // context SandboxID
				'sandbox'
			);
		}
	}

	@isTest
	public static void testDevAndTestOrgCheck() {
		// insert new user
		User objSandboxUser = new TestDataFactory.UserBuilder()
			.setAlias('sndbxusr')
			.setEmail('sandboxuser@testorg.com.invalid')
			.setEmailEncoding('UTF-8')
			.setFirstName('Sandboxuser')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUniqueUserName()
			.build();
		insert objSandboxUser;

		Test.startTest();
		List<Sandbox_User_Unmask__c> list_SUURecords = new List<Sandbox_User_Unmask__c>();
		Sandbox_User_Unmask__c objSUU = new TestDataFactory.SandboxUserUnmaskBuilder()
			.setUserId(objSandboxUser.Id)
			.setProfileId(objSandboxUser.ProfileId)
			.setUnmaskCheckbox(true)
			.setApplytoDevTestOrgsCheckbox(true)
			.build();
		list_SUURecords.add(objSUU);
		insert list_SUURecords;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            SandboxPostRefresh objSPR = new SandboxPostRefresh();
            Test.testSandboxPostCopyScript(objSPR, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), 'dev');
            
            List<User> list_QueriedUser = [SELECT ID, Email FROM User WHERE Alias = 'sndbxusr'];
            System.assertEquals('sandboxuser@testorg.com', list_QueriedUser.get(0).Email, 'Since this is dev org, user was unmasked due to apply to dev test setting being set.');
            Test.stopTest();
        }
	}
    
    @isTest
    private static void updateBiztechBSAUserToSysAdminUnitTest(){
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Biztech-BSA'];
        
        User objUser = new User(
            Alias = 'standt', 
            Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = objProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='standarduserABC123@testorg.com'
        );
        
        INSERT objUser;
        
        Test.startTest();
        
        Test.testSandboxPostCopyScript(
            new SandboxPostRefresh(), UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), UserInfo.getOrganizationName()
        );

        Test.stopTest();
        
        objUser = [
            SELECT Id, Profile.Name
            FROM User
            WHERE Id = :objUser.Id
        ];
        
        System.assertEquals('ZP System Administrator', objUser.Profile.Name, 'Profile should be ZP System Administrator');
    }
}