/**
 * Test class for UserUtils
 * @author Sandeep Golla
 * @since 11-23-2021
 * @author David Schach
 * @since 12-09-2021
 * @group Utilities
 **/
@isTest
private without sharing class UserUtilsTest {
	/**
	 * @author      Sandeep Golla
	 * @description Test Setup to create users
	 **/
	@testSetup
	static void setup() {
		List<User> list_Users = new List<User>();
		skipTrigger(true);
		User objcurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		UserRole objUserRole = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		System.runAs(objcurrentUser) {
			insert objUserRole;
		}

		//create user
		User objIntAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('marketos')
			.setEmail('marketouser@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Marketo')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('marketouser@testorg.com')
			.build();

		objIntAdminUser.Exempt_from_Validation_Rules__c = true;
		objIntAdminUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName LIKE :AccountUtil.SALES_PARTNER_AM_ROLE][0].Id;
		list_Users.add(objIntAdminUser);

		List<Profile> list_Profiles = [SELECT Id FROM Profile WHERE Name = 'Ardius Base User'];

		if (!list_Profiles.isEmpty()) {
			//create Ardius user
			User objArdiusUser = new TestDataFactory.UserBuilder()
				.setAlias('ardiuser')
				.setEmail('ardiususer@testorg.com')
				.setEmailEncoding('UTF-8')
				.setFirstName('Ardius')
				.setLastName('User')
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setProfileId(list_Profiles[0].Id)
				.setTimeZoneSidKey('America/Los_Angeles')
				.setUserName('ardiususer@testorg.com.aridus')
				.build();

			objArdiusUser.Exempt_from_Validation_Rules__c = true;
			objArdiusUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = :UserUtils.LABEL_ARDIUS][0].Id;
			list_Users.add(objArdiusUser);
		}

		System.runAs(objCurrentUser) {
			insert list_Users;
		}

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test').setUniqueName('Test').setState('CA').build();
		insert objCarrier;

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'New Plan'))
			.setStatus('Ready for Qualification')
			.setName('Test BO 1')
			.setCoverageEffectiveDate(System.Today())
			.setSubmissionDeadline(System.Today())
			.setOwnerID(objIntAdminUser.Id)
			.setInitialOwner(UserInfo.getUserId())
			.setType('New to Gusto')
			.setQualificationOwner(objIntAdminUser.Id)
			.build();
		insert objBO;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test CO 1')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'New Plan'))
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setOrderType('New to Gusto')
			.setImplementationStage('Ready for Confirmation')
			.setOwnerID(objIntAdminUser.Id)
			.setConfirmationOwner(objIntAdminUser.Id)
			.build();
		insert objCO;

		skipTrigger(false);
	}

	@isTest
	static void testIsActive() {
		List<User> users = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 2];
		for (User u : users) {
			System.assert(UserUtils.isActive(u.Id), 'User: ' + u);
		}
		System.assertEquals(null, UserUtils.isActive(null));
	}

	@isTest
	static void testIsUser() {
		List<User> users = [SELECT Id FROM User LIMIT 2];
		for (User u : users) {
			System.assert(UserUtils.isUser(u.Id), 'User: ' + u);
		}
		System.assertEquals(null, UserUtils.isUser(null));
	}

	@isTest
	static void testIsGroup() {
		List<Group> groups = [SELECT Id FROM Group LIMIT 2];
		for (Group g : groups) {
			System.assert(UserUtils.isGroup(g.Id), 'Group: ' + g);
		}
		System.assertEquals(null, UserUtils.isGroup(null));
	}

	@isTest
	static void testProfileName() {
		List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE ProfileId != NULL AND UserType = 'Standard' LIMIT 2];
		for (User u : users) {
			System.assert(String.isNotBlank(UserUtils.getProfileName(u.Id)), 'User ' + UserUtils.getProfileName(u.Id) + ': ' + u + ' ' + u.Profile.Name);
		}
		System.assertEquals(null, UserUtils.getProfileName(null));
	}

	@isTest
	static void testSlackID() {
		List<User> users = [SELECT Id FROM User WHERE Slack_Id__c != NULL LIMIT 1];
		for (User u : users) {
			System.assert(String.isNotBlank(UserUtils.getSlackId(u.Id)), 'User: ' + u);
		}
		User user = [SELECT Id, Slack_Id__c, FirstName FROM User WHERE Slack_Id__c != NULL LIMIT 1][0];
		String slackId = UserUtils.getSlackId(User.Id);
		System.assertEquals(user.Slack_Id__c, slackId);

		User user2 = [SELECT Id, Slack_Id__c, FirstName FROM User WHERE Slack_Id__c = NULL LIMIT 1][0];
		String slackId2 = UserUtils.getSlackId(User2.Id);
		System.assertEquals(null, slackId2);
		System.assertEquals(null, UserUtils.getSlackId(null));
	}

	@isTest
	static void testUserGroupName() {
		User testUser = [SELECT Id, Name, FirstName, LastName FROM User WHERE FirstName != NULL LIMIT 1][0];
		Group testGroup = [SELECT Id, Name FROM Group LIMIT 1][0];
		System.assertEquals(testUser.Name, UserUtils.getName(testUser.Id));
		System.assertEquals(testGroup.Name, UserUtils.getName(testGroup.Id));
	}

	@isTest
	static void testMultipleMethods() {
		//testReturnLoggedInUser
		User objUser = UserUtils.returnLoggedInUser();
		//testGetCurrentOwnerRoleName
		String strResult = UserUtils.getCurrentOwnerRoleName(UserInfo.getUserId());
		//testIsAdminIntgUser
		Boolean blnResult = UserUtils.isAdminIntgUser(UserInfo.getUserId());
		//testGenerateIntAdminUsers
		Set<String> set_Result = UserUtils.generateIntAdminUsers();

		//testGetCurrentUserRoleName
		strResult = UserUtils.getCurrentUserRoleName();
		//testGetOwnerUsrInfo
		objUser = UserUtils.getOwnerUsrInfo(UserInfo.getUserId());
		System.assertEquals(UserInfo.getUserId(), objUser.Id);
	}

	/**
	 * @author      Sandeep Golla
	 * @description Assert if the current user is specific integration user
	 **/
	@isTest
	static void testisIntgUser() {
		User objSalesUser = [SELECT Id, FirstName, LastName, Name, UserRoleId, UserRole.DeveloperName FROM User WHERE Name = 'Penny at Gusto' LIMIT 1];
		Boolean blnResult = UserUtils.isIntgUser(objSalesUser.Id);
		System.assert(blnResult);
		//Boolean blnResult1 = UserUtils.isIntgUser(UserInfo.getUserId());
		//System.assert(!blnResult1);
	}

	/**
	 * @author      Pradeep Chary
	 * @description Assert if the current user is a Ardius User
	 **/
	@isTest
	static void testIsArdiusUser() {
		User objArdiusUser = [SELECT Id, FirstName, LastName, Name, UserRoleId, UserRole.DeveloperName FROM User WHERE FirstName = 'Ardius' LIMIT 1];
		Boolean blnResult = UserUtils.isArdiusUser(objArdiusUser.Id);
		System.assert(blnResult);
	}

	/**
	 * @author      Deepika Saini
	 * @description Test Requires Routing functionality for Benefit Order and Carrier Order
	 **/
	@isTest
	static void testRequireRouting() {
		TicketTriggerHelper.skipTrigger = true;
		Test.startTest();

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		User objUser = [SELECT Id FROM User WHERE UserName = 'marketouser@testorg.com'];
		Carrier_Order__c objCO1 = [SELECT Id, Confirmation_Owner__c FROM Carrier_Order__c WHERE Name = 'Test CO 1' LIMIT 1];
		Benefit_Order__c objBO1 = [SELECT Id FROM Benefit_Order__c WHERE Name = 'Test BO 1' LIMIT 1];
		List<Ticket__c> list_Tickets = new List<Ticket__c>();

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setEscalationReason('Carrier Error')
			.setStatus('New')
			.setOwnerId(objUser.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans'))
			.setEscalationReasonDetail('Incorrect Inrollments')
			.setTeam('Onboarding')
			.setSubTeam('Fulfillment')
			.setReportingTeam('Fulfillment')
			.build();
		objTicket.Carrier_Order__c = objCO1.Id;
		objTicket.Benefit_Order__c = objBO1.Id;
		list_Tickets.add(objTicket);

		Ticket__c objTicket1 = new TestDataFactory.TicketBuilder()
			.setEscalationReason('TAdA')
			.setStatus('New')
			.setOwnerId(objUser.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans'))
			.setEscalationReasonDetail('Incomplete Hippo setup')
			.setTeam('Onboarding')
			.setSubTeam('Fulfillment')
			.setReportingTeam('Fulfillment')
			.build();
		objTicket1.Carrier_Order__c = objCO1.Id;
		objTicket1.Benefit_Order__c = objBO1.Id;
		list_Tickets.add(objTicket1);

		System.runAs(objCurrentUser) {
			insert list_Tickets;
			TicketTriggerHelper.skipTrigger = false;

			objUser.IsActive = false;
			update objUser;
		}

		UserUtils.updateRequireRoutingOnBOCO(new Set<Id>{ objUser.Id });

		Test.stopTest();
		Carrier_Order__c objCO = [SELECT Id, Requires_Routing__c FROM Carrier_Order__c WHERE OwnerId = :objUser.Id LIMIT 1];
		System.assertEquals(objCO.Requires_Routing__c, true);
	}

	static void skipTrigger(Boolean blnIsSkip) {
		BenefitOrderHelper.SkipTrigger = blnIsSkip;
		CarrierOrderTriggerHelper.skipTrigger = blnIsSkip;
	}

	/**
	 * @author      Deepika Saini
	 * @description Test Business Hours
	 **/
	@isTest
	static void testBusinessHours() {
		List<BusinessHours> listBusinessHours = UserUtils.list_BusinessHours;

		System.assertNotEquals(0, listBusinessHours.size(), 'Business Hours is blank');
	}

	/**
	 * @author      Deepika Saini
	 * @description Test User Roles
	 **/
	@isTest
	static void testUserRoles() {
		Map<String, UserRole> map_UserRole = UserUtils.map_NameToUserRole;
		Set<String> set_UserRoleIds = UserUtils.getUserRoleIds(
			new Set<String>{ LeadUtil.LABEL_SDR_MM_MGR_USR_ROLE, LeadUtil.LABEL_SDR_MM_USR_ROLE, LeadUtil.LABEL_BDR_USR_ROLE, LeadUtil.LABEL_SDR_PARTNER_MGR_USR_ROLE, LeadUtil.LABEL_SDR_PARTNER_USR_ROLE }
		);
		System.assertNotEquals(0, map_UserRole.size(), 'User Roles is blank');
		System.assertNotEquals(0, set_UserRoleIds.size(), 'User Roles is blank');
	}

	/**
	 * @author      Deepika Saini
	 * @description Test Group Name
	 **/
	@isTest
	static void testGroupNames() {
		Map<String, Id> map_GroupName = UserUtils.mapGroupNameToId;
		System.assertNotEquals(0, map_GroupName.size(), 'Group Name is blank');
	}
}