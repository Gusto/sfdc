/**
 * @description  This class is used to test subscription preference update activities
 * to be used as as a common test for preference related activities on Account/Contact/Lead
 * @author       Aviinandaan Dutta
 * @date         04-24-2023
 * @see          SubscriptionCenterUtil
 **/

@isTest
public class SubscriptionCenterUtilTest {
	/**
	 * @description Setup required test records
	 **/
	@testSetup
	static void setup() {
		List<Account> list_Accounts;
		List<Contact> list_Contacts;
		List<ZP_User__c> list_ZPUsers;
		List<ZP_User_Role__c> list_ZPUserRoles;

		DateTime dtDateTime = System.now() - 1;

		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId('Company')
			.setFirstName('Test Lead1 FirstName')
			.setLastName('Test Lead1 LastName')
			.setEmail('testlead100@test.com')
			.setCompany('ABC Company')
			.build();
		insert objLead1;

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 2').setZPCompanyId('00000000000012').build();

		Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('ABC Account 3')
			.setZPFirmId('00000000000021')
			.setLastLoginTime(dtDateTime - 1)
			.build();

		list_Accounts = new List<Account>{ objAccount1, objAccount2 };
		insert list_Accounts;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(list_Accounts[0].Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('testcontact100@test.com')
			.setZPUserId('176458136499')
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(list_Accounts[0].Id)
			.setFirstName('Test First Name2')
			.setLastName('Test Last Name2')
			.setEmail('testcontact200@test.com')
			.setZPUserId('176458136491')
			.setInactiveZPUser(true)
			.build();

		Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(list_Accounts[0].Id)
			.setFirstName('Test First Name3')
			.setLastName('Test Last Name3')
			.setEmail('testcontact300@test.com')
			.setZPUserId('176458136493')
			.setInactiveZPUser(true)
			.build();

		list_Contacts = new List<Contact>{ objContact1, objContact2, objContact3 };
		insert list_Contacts;

		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 1')
			.setCustomId(list_Contacts[0].ZP_User_Id__c)
			.setExternalKey('ZP777777777777771')
			.setEmail('testcontact100@test.com')
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setUUID('109b6e20-c23b-4365-aa69-48b3d7763e81')
			.build();

		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 2')
			.setCustomId(list_Contacts[1].ZP_User_Id__c)
			.setExternalKey('ZP777777777777772')
			.setEmail('testcontact200@test.com')
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setUUID('109b6e20-c23b-4365-aa69-48b3d7763e82')
			.build();

		ZP_User__c objZPUser3 = new TestDataFactory.ZPUserBuilder()
			.setName('Test User 3')
			.setCustomId(list_Contacts[2].ZP_User_Id__c)
			.setExternalKey('ZP777777777777773')
			.setEmail('testcontact300@test.com')
			.setCreatedAt(dtDateTime)
			.setUpdatedAt(System.now())
			.setLastSignInAt(dtDateTime)
			.setCurrentSignInAt(System.now())
			.setUUID('109b6e20-c23b-4365-aa69-48b3d7763e83')
			.build();

		list_ZPUsers = new List<ZP_User__c>{ objZPUser1, objZPUser2, objZPUser3 };
		insert list_ZPUsers;

		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343434')
			.setUserId(list_Contacts[0].ZP_User_Id__c)
			.setCompanyId(list_Accounts[0].ZP_Company_Id__c)
			.setType('Role::Employee')
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343435')
			.setUserId(list_Contacts[1].ZP_User_Id__c)
			.setCompanyId(list_Accounts[0].ZP_Company_Id__c)
			.setType('Role::Payroll Admin')
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		ZP_User_Role__c objZPUserRole3 = new TestDataFactory.ZPUserRoleBuilder()
			.setCustomId('343434343436')
			.setUserId(list_Contacts[2].ZP_User_Id__c)
			.setAccFirmId(list_Accounts[1].ZP_Firm_Id__c)
			.setType('Role::Primary Payroll Admin')
			.setCreatedAt(list_ZPUsers[1].Created_At__c)
			.setUpdatedAt(System.now())
			.build();

		list_ZPUserRoles = new List<ZP_User_Role__c>{ objZPUserRole1, objZPUserRole2, objZPUserRole3 };
		insert list_ZPUserRoles;

		for (ZP_User_Role__c objRole : list_ZPUserRoles) {
			objRole.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}
		update list_ZPUserRoles;

		for (ZP_User__c zpUser : list_ZPUsers) {
			zpUser.Processing_State__c = ZPUserTriggerHelper.MANUAL_ENQUEUE;
		}
		update list_ZPUsers;
	}

	/**
	 * @description This test method checks the applicable subscriptions that should be updated on a contact
	 **/
	@isTest
	static void shouldUpdateSubscriptionsOnContactBySelection() {
		User objZPSalesOpsUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'ZP Sales Operations' AND IsActive = TRUE LIMIT 1];
		objZPSalesOpsUser.Exempt_from_Validation_Rules__c = true;
		update objZPSalesOpsUser;
		Contact objContactToUpdate = [SELECT Customer_Subscriptions__c, ZP_User_Role__c FROM Contact].get(0);
		List<String> list_preferencesToUpdate = new List<String>();
		System.runAs(objZPSalesOpsUser) {
			list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS);
			list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
			list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
			list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
			objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
			//WHEN: update all subscriptions on contact
			update objContactToUpdate;
		}

		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		Set<String> set_subscriptionValues = new Set<String>(objContactToUpdate.Customer_Subscriptions__c.split(';'));
		Boolean blnAllSubscriptionsAdded = true;
		for (String strSubscription : list_preferencesToUpdate) {
			if (!set_subscriptionValues.contains(strSubscription)) {
				blnAllSubscriptionsAdded = false;
			}
		}
		//THEN: all subscriptions should be updated correctly on the contact
		System.assert(blnAllSubscriptionsAdded, 'All subscriptions not added');

		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Test.startTest();
		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.BIZ_NEWSLETTER);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
		//WHEN: Some values from features and announcements category are removed
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		Boolean blnAnnouncementsRemoved = true;
		set_subscriptionValues = new Set<String>(objContactToUpdate.Customer_Subscriptions__c.split(';'));
		for (String strSubscription : set_subscriptionValues) {
			if (SubscriptionCenterUtil.LIST_ANNOUNCEMENTS.contains(strSubscription)) {
				blnAnnouncementsRemoved = false;
			}
		}
		//THEN: All values from features and announcements category should be removed
		System.assert(blnAnnouncementsRemoved, 'All announcement subscriptions not removed');

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.REFERRALS);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
		//WHEN: Some values from deals and promos category are removed
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		Boolean blnReferralsRemoved = true;
		set_subscriptionValues = new Set<String>(objContactToUpdate.Customer_Subscriptions__c.split(';'));
		for (String strSubscription : set_subscriptionValues) {
			if (SubscriptionCenterUtil.LIST_DEALS_REFERRALS.contains(strSubscription)) {
				blnReferralsRemoved = false;
			}
		}
		//THEN: All values from deals and promos category should be removed
		System.assert(blnReferralsRemoved, 'All referral subscriptions not removed');

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.CSAT);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
		//WHEN: Some values from feedbacks and surveys category are removed
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		//THEN: All values from feedbacks and surveys category should be removed
		System.assertEquals(SubscriptionCenterUtil.OUTREACH, objContactToUpdate.Customer_Subscriptions__c, 'All feedback subscriptions not removed');

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.add(SubscriptionCenterUtil.BIZ_NEWSLETTER);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		String applicableSubscriptions = SubscriptionCenterUtil.getApplicableSubscriptionPreferences(new Set<String>(list_preferencesToUpdate), new Set<String>(), false);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
		//WHEN: Some values from features and announcements category are added
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		Boolean blnAnnouncementsAdded = true;
		set_subscriptionValues = new Set<String>(objContactToUpdate.Customer_Subscriptions__c.split(';'));
		for (String strSubscription : SubscriptionCenterUtil.LIST_ANNOUNCEMENTS) {
			if (!set_subscriptionValues.contains(strSubscription)) {
				blnAnnouncementsAdded = false;
			}
		}
		//THEN: All values from features and announcements category should be added
		System.assert(blnAnnouncementsAdded, 'All announcement subscriptions not added');

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.add(SubscriptionCenterUtil.BIZ_NEWSLETTER);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.REFERRALS);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
		//WHEN: Some values from deals and promos category are added
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		Boolean blnReferralsAdded = true;
		set_subscriptionValues = new Set<String>(objContactToUpdate.Customer_Subscriptions__c.split(';'));
		for (String strSubscription : SubscriptionCenterUtil.LIST_DEALS_REFERRALS) {
			if (!set_subscriptionValues.contains(strSubscription)) {
				blnReferralsAdded = false;
			}
		}
		//THEN: All values from deals and promos category should be added
		System.assert(blnReferralsAdded, 'All referral subscriptions not added');

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.add(SubscriptionCenterUtil.BIZ_NEWSLETTER);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.REFERRALS);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.CSAT);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
		//WHEN: Some values from feedback and surveys category are added
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		Boolean blnFeedbackAdded = true;
		set_subscriptionValues = new Set<String>(objContactToUpdate.Customer_Subscriptions__c.split(';'));
		for (String strSubscription : SubscriptionCenterUtil.LIST_CSAT) {
			if (!set_subscriptionValues.contains(strSubscription)) {
				blnFeedbackAdded = false;
			}
		}
		//THEN: All values from feedback and surveys category should be added
		System.assert(blnFeedbackAdded, 'All feedback subscriptions not added');

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';
		//WHEN: Marketing email opt out is added
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		//THEN: All subscriptions should be removed
		System.assertEquals(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT, objContactToUpdate.Customer_Subscriptions__c, 'All subscriptions not removed');

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		objContactToUpdate.Customer_Subscriptions__c = null;
		//WHEN: Marketing email opt out is removed
		System.runAs(objZPSalesOpsUser) {
			update objContactToUpdate;
		}
		objContactToUpdate = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContactToUpdate.Id];
		//THEN: Subscriptions should be empty
		System.assert(String.isBlank(objContactToUpdate.Customer_Subscriptions__c), 'Subscriptions not empty');

		Test.stopTest();
	}

	/**
	 * @description This test method checks applicable update on parent account
	 **/
	@isTest
	static void shouldUpdateParentAccount() {
		User objZPSalesOpsUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'ZP Sales Operations' AND IsActive = TRUE LIMIT 1];
		objZPSalesOpsUser.Exempt_from_Validation_Rules__c = true;
		update objZPSalesOpsUser;
		Contact objContactToUpdate = [SELECT Customer_Subscriptions__c, AccountId FROM Contact WHERE ZP_User_Role__c INCLUDES ('Payroll Admin')].get(0);

		Account objUpdatedAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objContactToUpdate.AccountId];

		List<String> list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.add(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';');

		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Test.startTest();
		Contact objNewContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objUpdatedAccount.Id)
			.setFirstName('Test First Name')
			.setLastName('Test Last Name')
			.setEmail('testcontact980@test.com')
			.setZPUserId('176456646499')
			.build();
		objNewContact.Customer_Subscriptions__c = SubscriptionCenterUtil.BIZ_NEWSLETTER;
		objNewContact.ZP_User_Role__c = 'Accountant';
		System.runAs(objZPSalesOpsUser) {
			//WHEN: An admin contact with subscriptions is inserted
			insert objNewContact;
			objUpdatedAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objContactToUpdate.AccountId];
			//THEN: Subscriptions on the related account should be updated
			System.assert(new Set<String>(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS).containsAll(objUpdatedAccount.Customer_Subscriptions__c.split(';')), 'Account preferences not updated correctly');
			//WHEN: Subscriptions of an admin contact is updated
			update objContactToUpdate;
		}
		Test.stopTest();

		objContactToUpdate = [SELECT Customer_Subscriptions__c, AccountId FROM Contact WHERE Id = :objContactToUpdate.Id];
		objUpdatedAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objContactToUpdate.AccountId];
		Boolean blnSubscriptionsAdded = true;
		Set<String> set_subscriptionValues = new Set<String>(objUpdatedAccount.Customer_Subscriptions__c.split(';'));
		for (String strSubscription : list_preferencesToUpdate) {
			if (!set_subscriptionValues.contains(strSubscription)) {
				blnSubscriptionsAdded = false;
			}
		}
		//THEN: Related account's subscriptions should be updated
		System.assert(blnSubscriptionsAdded, 'Account not updated');
	}

	/**
	 * @description This test method checks applicable update on parent account
	 **/
	@isTest
	static void shouldNotUpdateParentAccount() {
		User objZPSalesOpsUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'ZP Sales Operations' AND IsActive = TRUE LIMIT 1];
		objZPSalesOpsUser.Exempt_from_Validation_Rules__c = true;
		update objZPSalesOpsUser;
		Contact objContactToUpdate = [SELECT Customer_Subscriptions__c, AccountId FROM Contact WHERE ZP_User_Role__c INCLUDES ('Employee')].get(0);

		Account objUpdatedAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objContactToUpdate.AccountId];

		List<String> list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';');

		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Test.startTest();
		Contact objNewContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objUpdatedAccount.Id)
			.setFirstName('Test First Name')
			.setLastName('Test Last Name')
			.setEmail('testcontact980@test.com')
			.setZPUserId('176456646499')
			.build();
		objNewContact.Customer_Subscriptions__c = SubscriptionCenterUtil.BIZ_NEWSLETTER;
		objNewContact.ZP_User_Role__c = 'Employee';
		System.runAs(objZPSalesOpsUser) {
			//WHEN: An non-admin contact with subscriptions is inserted
			insert objNewContact;
			objUpdatedAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objContactToUpdate.AccountId];
			//THEN: Subscriptions on the related account should not be updated
			List<String> list_preferencesToCheck = new List<String>(list_preferencesToUpdate);
			list_preferencesToCheck.addAll(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS);
			System.assert(new Set<String>(objUpdatedAccount.Customer_Subscriptions__c.split(';')).containsAll(list_preferencesToCheck), 'Account preferences updated incorrectly');
			//WHEN: Subscriptions of an admin contact is updated
			update objContactToUpdate;
		}
		Test.stopTest();

		objContactToUpdate = [SELECT Customer_Subscriptions__c, AccountId FROM Contact WHERE Id = :objContactToUpdate.Id];
		objUpdatedAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objContactToUpdate.AccountId];
		//THEN: Related account's subscriptions should not be updated
		System.assertNotEquals(objContactToUpdate.Customer_Subscriptions__c, objUpdatedAccount.Customer_Subscriptions__c, 'Account wrongly updated');
	}

	/**
	 * @description This test method checks applicable updates on related admin contacts
	 **/
	@isTest
	static void shouldUpdateAdminContacts() {
		User objZPSalesOpsUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'ZP Sales Operations' AND IsActive = TRUE LIMIT 1];
		objZPSalesOpsUser.Exempt_from_Validation_Rules__c = true;
		update objZPSalesOpsUser;
		Account objAccountToUpdate = [SELECT Customer_Subscriptions__c FROM Account].get(0);
		List<Contact> objContactsToUpdate = [SELECT Customer_Subscriptions__c, ZP_User_Role__c FROM Contact];
		List<String> list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		for (Contact objContact : objContactsToUpdate) {
			objContact.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';');
		}
		System.runAs(objZPSalesOpsUser) {
			update objContactsToUpdate;
		}

		list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS);
		objAccountToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';');

		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Test.startTest();
		//WHEN: An account's subscriptions are updated
		System.runAs(objZPSalesOpsUser) {
			update objAccountToUpdate;
		}
		Test.stopTest();

		objAccountToUpdate = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objAccountToUpdate.Id];
		Set<String> set_subscriptionValues = new Set<String>(objAccountToUpdate.Customer_Subscriptions__c.split(';'));
		Boolean blnAllSubscriptionsAdded = true;
		for (String strSubscription : list_preferencesToUpdate) {
			if (!set_subscriptionValues.contains(strSubscription)) {
				blnAllSubscriptionsAdded = false;
			}
		}
		System.assert(blnAllSubscriptionsAdded, 'All subscriptions not added');

		objContactsToUpdate = [SELECT Customer_Subscriptions__c, AccountId, ZP_User_Role__c FROM Contact];
		//THEN: Related admin contacts' subscriptions should be updated
		for (Contact objContact : objContactsToUpdate) {
			Set<String> set_contactSubscriptionValues = new Set<String>(objContact.Customer_Subscriptions__c.split(';'));
			if (
				String.isNotBlank(objContact.ZP_User_Role__c) &&
				(objContact.ZP_User_Role__c.contains('Payroll Admin') ||
				objContact.ZP_User_Role__c.contains('Primary Payroll Admin') ||
				objContact.ZP_User_Role__c.contains('Accountant'))
			) {
				System.assert(set_contactSubscriptionValues.containsAll(new Set<String>(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS)), 'Contact not updated correctly');
			} else {
				System.assert(!set_contactSubscriptionValues.containsAll(new Set<String>(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS)), 'Contact updated incorrectly');
			}
		}
	}

	/**
	 * @description This test method checks callout
	 **/
	@isTest
	static void shouldCalloutContact() {
		Contact objContactToUpdate = [SELECT Customer_Subscriptions__c, ZP_User_Id__c, Email, Id FROM Contact].get(0);
		List<String> list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
		list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		objContactToUpdate.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';') + ';';

		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Test.startTest();
		Map<String, Object> objCalloutRequest = new Map<String, Object>();
		objCalloutRequest.put('target', 'iterable');
		objCalloutRequest.put('zpUserRoleIds', new List<String>{ '343434343434' });
		objCalloutRequest.put('offersAndPromotions', 'true');
		objCalloutRequest.put('newFeaturesAndUpdates', 'true');
		//WHEN: Callout is made for subscription change on contact
		Map<Id, String> map_response = SubscriptionCenterUtil.performCallout(new Map<Id, String>{ objContactToUpdate.Id => JSON.serialize(objCalloutRequest) });
		SubscriptionCenterUtil.calloutSubscription(new List<Contact>{ objContactToUpdate }, Contact.SObjectType);
		Test.stopTest();
		//THEN: Callout should be successful
		System.assertEquals(200, Integer.valueOf(map_response.get(objContactToUpdate.Id)), 'Callout unsuccessful');
	}

	/**
	 * @description This test method checks callout on lead
	 **/
	@isTest
	static void shouldCalloutLead() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('subscription@preference.com')
			.setPhone('123456789')
			.setCompany('Subscription')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		insert objLead;

		List<String> list_preferencesToUpdate = new List<String>();
		list_preferencesToUpdate.add(SubscriptionCenterUtil.OUTREACH);
		objLead.Customer_Subscriptions__c = SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT;

		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Test.startTest();
		Map<String, Object> objCalloutRequest = new Map<String, Object>();
		objCalloutRequest.put('target', 'iterable');
		objCalloutRequest.put('offersAndPromotions', 'true');
		objCalloutRequest.put('newFeaturesAndUpdates', 'true');
		//WHEN: Callout is made for subscription change on Lead
		Map<Id, String> map_response = SubscriptionCenterUtil.performCallout(new Map<Id, String>{ objLead.Id => JSON.serialize(objCalloutRequest) });
		SubscriptionCenterUtil.calloutSubscription(new List<Lead>{ objLead }, Lead.SObjectType);
		Test.stopTest();
		//THEN: Callout should be successful
		System.assertEquals(200, Integer.valueOf(map_response.get(objLead.Id)), 'Callout unsuccessful');
	}

	/**
	 * @description This test method checks applicable preferences on Account/Contact/Lead on insert and update
	 **/
	@isTest
	static void shouldUpdatePreferencesOnInsertAndUpdate() {
		User objZPSalesOpsUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'ZP Sales Operations' AND IsActive = TRUE LIMIT 1];
		objZPSalesOpsUser.Exempt_from_Validation_Rules__c = true;
		update objZPSalesOpsUser;

		List<String> list_preferences = new List<String>();
		list_preferences.addAll(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS);
		list_preferences.addAll(SubscriptionCenterUtil.LIST_DEALS_REFERRALS);
		list_preferences.addAll(SubscriptionCenterUtil.LIST_CSAT);
		list_preferences.add(SubscriptionCenterUtil.OUTREACH);
		list_preferences.add(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS);

		Test.setMock(HttpCalloutMock.class, new SubscriptionCenterUtil.HttpClientMockResponse());
		Test.startTest();
		//WHEN: Account/Contact/Lead has been inserted with no preference
		Account objAccount = [SELECT Customer_Subscriptions__c FROM Account].get(0);
		Contact objContact = [SELECT Customer_Subscriptions__c FROM Contact].get(0);
		Lead objLead = [SELECT Customer_Subscriptions__c FROM Lead].get(0);
		//THEN: Account/Contact/Lead preferences should include all opt-in values
		System.assert(new Set<String>(objAccount.Customer_Subscriptions__c.split(';')).containsAll(list_preferences), 'New account preferences not updated correctly');
		System.assert(new Set<String>(objContact.Customer_Subscriptions__c.split(';')).containsAll(list_preferences), 'New contact preferences not updated correctly');
		System.assert(new Set<String>(objLead.Customer_Subscriptions__c.split(';')).containsAll(list_preferences), 'New lead preferences not updated correctly');
		System.runAs(objZPSalesOpsUser) {
			objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 4').setZPCompanyId('00000000000066').build();
			objAccount.Customer_Subscriptions__c = SubscriptionCenterUtil.BIZ_NEWSLETTER;
			insert objAccount;
			objContact = new TestDataFactory.ContactBuilder()
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setAccountId(objAccount.Id)
				.setFirstName('Test First Name4')
				.setLastName('Test Last Name4')
				.setEmail('testcontact900@test.com')
				.setZPUserId('176456636499')
				.build();
			objContact.Customer_Subscriptions__c = SubscriptionCenterUtil.BIZ_NEWSLETTER;
			insert objContact;
			objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId('Company')
				.setFirstName('Test Lead2 FirstName')
				.setLastName('Test Lead2 LastName')
				.setEmail('testlead200@test.com')
				.setCompany('ABC Company')
				.build();
			objLead.Customer_Subscriptions__c = SubscriptionCenterUtil.BIZ_NEWSLETTER;
			insert objLead;
			//WHEN: Account/Contact/Lead has been inserted with some preference
			objAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objAccount.Id];
			objContact = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContact.Id];
			objLead = [SELECT Customer_Subscriptions__c FROM Lead WHERE Id = :objLead.Id];
			//THEN: Account/Contact/Lead preferences should be populated factoring dependencies
			System.assert(new Set<String>(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS).containsAll(objAccount.Customer_Subscriptions__c.split(';')), 'New account preferences not updated correctly');
			System.assert(new Set<String>(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS).containsAll(objContact.Customer_Subscriptions__c.split(';')), 'New contact preferences not updated correctly');
			System.assert(new Set<String>(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS).containsAll(objLead.Customer_Subscriptions__c.split(';')), 'New lead preferences not updated correctly');

			List<String> list_preferencesToUpdate = new List<String>();
			list_preferencesToUpdate.addAll(SubscriptionCenterUtil.LIST_ANNOUNCEMENTS);
			list_preferencesToUpdate.add(SubscriptionCenterUtil.CSAT);
			list_preferencesToUpdate.add(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS);
			objAccount.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';');
			objContact.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';');
			objLead.Customer_Subscriptions__c = String.join(list_preferencesToUpdate, ';');
			//WHEN: Account/Contact/Lead preferences have been updated
			update new List<SObject>{ objAccount, objContact, objLead };
		}
		Test.stopTest();

		objAccount = [SELECT Customer_Subscriptions__c FROM Account WHERE Id = :objAccount.Id];
		objContact = [SELECT Customer_Subscriptions__c FROM Contact WHERE Id = :objContact.Id];
		objLead = [SELECT Customer_Subscriptions__c FROM Lead WHERE Id = :objLead.Id];
		//THEN: Account/Contact/Lead preferences should be populated factoring dependencies
		System.assert(new Set<String>(objAccount.Customer_Subscriptions__c.split(';')).containsAll(SubscriptionCenterUtil.LIST_CSAT), 'Account preferences not updated correctly');
		System.assert(new Set<String>(objContact.Customer_Subscriptions__c.split(';')).containsAll(SubscriptionCenterUtil.LIST_CSAT), 'Contact preferences not updated correctly');
		System.assert(new Set<String>(objLead.Customer_Subscriptions__c.split(';')).containsAll(SubscriptionCenterUtil.LIST_CSAT), 'Lead preferences not updated correctly');
		System.assert(new Set<String>(objAccount.Customer_Subscriptions__c.split(';')).contains(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS), 'Account preferences not updated correctly');
		System.assert(new Set<String>(objContact.Customer_Subscriptions__c.split(';')).contains(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS), 'Contact preferences not updated correctly');
		System.assert(new Set<String>(objLead.Customer_Subscriptions__c.split(';')).contains(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS), 'Lead preferences not updated correctly');
	}
}