/**
 * @description  Test routing of child opportunities and leads when account owner changes
 * @author       Praveen Sethu
 * @date         11-11-2022
 **/
@isTest
public with sharing class AccountOwnerRouterTest {
	@testSetup
	static void setup() {
		// insert new MDR user
		User objMDRUser = new TestDataFactory.UserBuilder()
			.setAlias('mdruser')
			.setEmail('mdruser@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('mdruser@testorg.com')
			.setUserRoleId([SELECT Id FROM UserRole WHERE Name = 'sales_sdr_partner_xx' LIMIT 1][0].Id)
			.build();
		insert objMDRUser;
	}

	/**
	 * @description Test routing of child opportunities and leads when account owner changes
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testAccountOwnerChange() {
		RingLead_Routing_Credentials__c objCredential = new RingLead_Routing_Credentials__c(Account_Owner_Routing_Endpoint__c = 'https://ringlead.ownerchange.com/send', API_Token__c = 'api-token');
		insert objCredential;

		AccountTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());

		// create new company account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		insert objAccount;

		// create reseller lead and set referred by
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@ringlead.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('LinkedIn')
			.build();
		objLead.Referred_By__c = objAccount.Id;
		insert objLead;

		User objMDRuser = [SELECT Id, Name, UserRole.Name FROM User WHERE Email = 'mdruser@testorg.com' LIMIT 1];

		Test.startTest();

		AccountOwnerRouter.RequestWrapper objWrapper = new AccountOwnerRouter.RequestWrapper();
		AccountOwnerRouter.reAssignChildOpportunities(
			new List<AccountOwnerRouter.RequestWrapper>{
				new AccountOwnerRouter.RequestWrapper(
					(String) objAccount.Id,
					(String) AccountUtil.COMPANY_ACCOUNT_RT_ID,
					(String) objMDRuser.Id,
					objAccount.Name,
					objMDRuser.Name,
					objMDRuser.UserRole.Name
				)
			}
		);

		Test.stopTest();

		// assert if account route count is updated
		Account objAccAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(2, objAccAssert.Account_Route_Count__c, 'Account_Route_Count__c should be 2.');
	}

	/**
	 * @description Test routing of child opportunities and leads when account owner changes
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testAccountOwnerChangeFromPartnerHouseAccount() {
		RingLead_Routing_Credentials__c objCredential = new RingLead_Routing_Credentials__c(Account_Owner_Routing_Endpoint__c = 'https://ringlead.ownerchange.com/send', API_Token__c = 'api-token');
		insert objCredential;

		AccountTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());

		// create new company account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		insert objAccount;

		// create reseller lead and set referred by
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@ringlead.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('LinkedIn')
			.build();
		objLead.Referred_By__c = objAccount.Id;
		insert objLead;

		User objPartnerManager = [SELECT Id, Name, UserRole.Name FROM User WHERE UserRole.Name = 'sales_partner_xx_xx_mgr' LIMIT 1];

		Test.startTest();

		AccountOwnerRouter.RequestWrapper objWrapper = new AccountOwnerRouter.RequestWrapper();
		AccountOwnerRouter.reAssignChildOpportunities(
			new List<AccountOwnerRouter.RequestWrapper>{
				new AccountOwnerRouter.RequestWrapper(
					(String) objAccount.Id,
					(String) AccountUtil.COMPANY_ACCOUNT_RT_ID,
					(String) objPartnerManager.Id,
					objAccount.Name,
					objPartnerManager.Name,
					objPartnerManager.UserRole.Name
				)
			}
		);

		Test.stopTest();

		// assert if account route count is updated
		Account objAccAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(null, objAccAssert.Account_Route_Count__c, 'Account_Route_Count__c should be null.');
	}
}