@isTest
public with sharing class CareCaseButtonsTest {
	@testSetup
	public static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Account a = new Account(Name = 'Test Account', Tier__c = objTierConfig.New_Tier_1__c);
		insert a;

		Contact c = new Contact(AccountId = a.Id, FirstName = 'contactFirst', LastName = 'contactLast', Email = 'test1@test.com', Phone = '0000000000');
		insert c;

		Group grp = new Group(Type = 'Queue', Name = 'test queue 1');

		insert grp;

		setupFuture();

		Case cse = new Case(Subject = 'test subject', RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care'), Type = 'Payroll Care', Status = 'Open', ContactId = c.Id, AccountId = a.Id);

		insert cse;
		String strGroupIds = grp.Id + ';';

		User_Preference__c up = new User_Preference__c(User__c = UserInfo.getUserId(), Case_Play_Selected_Queues__c = strGroupIds);
		insert up;

		Group objGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Social & Executive Escalations Queue'];

		User objUser = new User(Id = UserInfo.getUserId());
		System.runAs(objUser) {
			GroupMember objGroupMember = new GroupMember(UserOrGroupId = UserInfo.getUserId(), GroupId = objGroup.Id);
			insert objGroupMember;
		}
	}
	@future
	public static void setupFuture() {
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		User objUserWithoutPermission = new User(
			Alias = 'testU',
			Email = 'careCaseButtons@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'careCaseButtons@test.com',
			ProfileId = objProfile.Id
		);
		insert objUserWithoutPermission;

		Group g = [SELECT Id FROM Group WHERE Name = 'test queue 1'];
		QueueSobject mappingObject = new QueueSobject(QueueId = g.Id, SobjectType = 'Case');

		insert mappingObject;
	}

	/**
	 * tests queryCase, queryRecord, queryCaseRefFields
	 */
	@isTest
	public static void testQueryCase() {
		Case c = [SELECT Id FROM Case WHERE Subject = 'test subject'];
		Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'contactLast'];

		String strQueriedRecord = CareCaseButtons.queryRecord(contact.Id);
		Case queriedCase = CareCaseButtons.queryCase(c.Id);
		Map<String, Object> map_CaseFields = CareCaseButtons.queryCaseRefFields(c.Id);
		Contact cont = CareCaseButtons.queryContact(contact.Id);
		Account act = CareCaseButtons.queryAccount(contact.AccountId);

		Boolean boolIsNull = queriedCase == null ? true : false;
		Boolean boolIsContactNull = strQueriedRecord == null ? true : false;
		Boolean boolIsMapNull = map_CaseFields == null ? true : false;
		Boolean boolIsContactNull2 = cont == null ? true : false;
		Boolean boolIsAccountNull = act == null ? true : false;

		System.assertEquals(false, boolIsNull, 'Incorect Result');
		System.assertEquals(false, boolIsContactNull, 'Incorect Result');
		System.assertEquals(false, boolIsMapNull, 'Incorect Result');
		System.assertEquals(false, boolIsContactNull2, 'Incorect Result');
		System.assertEquals(false, boolIsAccountNull, 'Incorect Result');
	}

	@isTest
	public static void testCaseMethods() {
		Case objCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'test subject' LIMIT 1];
		CareCaseButtons.acceptCase(objCase);

		Test.startTest();
		Case objQueriedCase = [SELECT Id, OwnerId FROM Case LIMIT 1];
		System.assertEquals(UserInfo.getUserId(), objQueriedCase.OwnerId, 'Incorect Result');

		CareCaseButtons.skipCaseRecord(objQueriedCase.Id, 'test skip record');
		Case_Skip_History__c objSkip = [SELECT Id, Skip_Comment__c FROM Case_Skip_History__c LIMIT 1];
		Case objCaseAfterSkip = [SELECT Id, Assigned_by_Play_Mode__c FROM Case LIMIT 1];

		System.assertEquals('test skip record', objSkip.Skip_Comment__c, 'Incorect Result');
		System.assertEquals(false, objCaseAfterSkip.Assigned_by_Play_Mode__c, 'Incorect Result');
		Test.stopTest();
	}

	@isTest
	public static void updateCase() {
		User objUser = [SELECT Id FROM User WHERE Email = 'careCaseButtons@test.com'];

		// Get org default tier config settings and assert new tier 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Tier_1__c, 'Incorrect Result');

		Test.startTest();
		System.runAs(objUser) {
			Case c = [SELECT Id, AccountId, ContactId FROM Case];
			Group g = [SELECT Id FROM Group WHERE Name = 'test queue 1'];
			Account a = new Account(Name = 'test account 2', Tier__c = objTierConfig.New_Tier_1__c);
			insert a;

			Contact cnt = new Contact(FirstName = 'first2', LastName = 'last2');

			insert cnt;

			c.OwnerId = g.Id;
			CaseTriggerHelper.skipTrigger = true;
			update c;

			CareCaseButtons.changeOwner(c.Id, UserInfo.getUserId());
			CareCaseButtons.updateAccount(c.Id, a.Id);
			CareCaseButtons.updateContact(c.Id, cnt.Id);

			Case caseAfterChange = [SELECT Id, AccountId, OwnerId, ContactId FROM Case];
			System.assertNotEquals(c.OwnerId, caseAfterChange.OwnerId, 'Incorrect Result');
			System.assertNotEquals(c.AccountId, caseAfterChange.AccountId, 'Incorrect Result');
			System.assertNotEquals(c.ContactId, caseAfterChange.ContactId, 'Incorrect Result');
			System.assertEquals(false, CareCaseButtons.setSurveyOverride(), 'Incorrect Result');
			System.assertEquals(CareCaseButtons.setSurveyOverride(), CareCaseButtons.getPermissions().blnSurveyOverride, 'Incorrect Result');

			CareCaseButtons.skipSurvey(c.Id);
			Case caseAfterSkipSurvey = [SELECT Id, Skip_Survey__c FROM Case];
			System.assertEquals(true, caseAfterSkipSurvey.Skip_Survey__c, 'Incorrect Result');

			CareCaseButtons.updateCaseOnUnmerge(c.Id, 'Benefits Care', true);
			Case caseAfterUnmerge = [SELECT Id, RecordType.Name, Status FROM Case];
			System.assertEquals('Benefits Care', caseAfterUnmerge.RecordType.Name, 'Incorrect Result');
			System.assertEquals('Open', caseAfterUnmerge.Status, 'Incorrect Result');
			CaseTriggerHelper.skipTrigger = false;
		}

		Test.stopTest();
	}

	/**
	 * @Author : Ankit CS
	 * @Description : To assert if the user has access to Escalate Case.
	 **/
	@isTest
	public static void testCanUserEscalate() {
		Test.startTest();

		List<User> list_Users = new List<User>();
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		List<String> list_EscalateRoles = Label.Escalate_Case_Roles.split(',');
		UserRole objUserRole = [SELECT Id, Name FROM UserRole WHERE Name LIKE :list_EscalateRoles LIMIT 1];
		Boolean blnResult1;
		Boolean blnResult2;
		CareCaseButtons.PermissionWrapper objWrap1;
		CareCaseButtons.PermissionWrapper objWrap2;

		User objUserWithEscalateAccess = new User(
			Alias = 'testU',
			Email = 'test@gusto.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'escalateaccessuser@gusto.com',
			ProfileId = objProfile.Id,
			UserRoleId = objUserRole.Id
		);
		list_Users.add(objUserWithEscalateAccess);

		User objUserWOEscalateAccess = new User(
			Alias = 'testU',
			Email = 'test@gusto.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'noescalateaccessuser@gusto.com',
			ProfileId = objProfile.Id
		);
		list_Users.add(objUserWOEscalateAccess);

		insert list_Users;

		System.runAs(objUserWithEscalateAccess) {
			blnResult1 = CareCaseButtons.canUserEscalate();
			objWrap1 = CareCaseButtons.getPermissions();
		}

		System.runAs(objUserWOEscalateAccess) {
			blnResult2 = CareCaseButtons.canUserEscalate();
			objWrap2 = CareCaseButtons.getPermissions();
		}

		Test.stopTest();

		//Assert if the user has access to Escalate Case.
		System.assert(blnResult1, 'Incorrect Result');
		System.assertEquals(blnResult1, objWrap1.blnReroutePerm, 'Incorrect Result');
		//Assert if the user doesn't has access to Escalate Case.
		System.assertEquals(false, blnResult2, 'Incorrect Result');
		System.assertEquals(blnResult2, objWrap2.blnReroutePerm, 'Incorrect Result');
	}

	/**
	 * @Author : Ankit CS
	 * @Description : To assert if the user has access to Escalate Case. Test against CareCaseButtons.getPermssions()
	 * @Parm : N/A
	 * @Return : N/A
	 **/
	@isTest
	public static void testCanUserCreateEscalationCase() {
		Test.startTest();
		List<User> list_Users = new List<User>();
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		CareCaseButtons.CaseEsclalationWrapper objWrapper = new CareCaseButtons.CaseEsclalationWrapper();
		CareCaseButtons.CaseEsclalationWrapper objWrapper2 = new CareCaseButtons.CaseEsclalationWrapper();
		List<Create_Escalation_Case_Role__mdt> list_EscalateCaseMetadata = [SELECT Id, Label, Escalation_Type__c FROM Create_Escalation_Case_Role__mdt WHERE Label = 'Payroll Care' LIMIT 1];
		UserRole objUserRole = [SELECT Id, Name FROM UserRole WHERE Name = :list_EscalateCaseMetadata[0].Label];

		User objUserWithEscalateAccess = new User(
			Alias = 'testU',
			Email = 'objUserWithAccess@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objUserWithAccess@CareCaseButtonsTest.com',
			ProfileId = objProfile.Id,
			UserRoleId = objUserRole.Id
		);
		list_Users.add(objUserWithEscalateAccess);

		User objUserWOEscalateAccess = new User(
			Alias = 'testU',
			Email = 'objUserWithoutAccess@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objUserWOAccess@CareCaseButtonsTest.com',
			ProfileId = objProfile.Id
		);
		list_Users.add(objUserWOEscalateAccess);
		insert list_Users;

		System.runAs(objUserWithEscalateAccess) {
			objWrapper = CareCaseButtons.canUserCreateEscalationCase();
		}

		System.runAs(objUserWOEscalateAccess) {
			objWrapper2 = CareCaseButtons.canUserCreateEscalationCase();
		}

		Test.stopTest();

		System.assertEquals(true, objWrapper.blnCaseEscalationAccess, 'Incorrect Result');
		System.assertEquals(list_EscalateCaseMetadata[0].Escalation_Type__c, objWrapper.strEscalationType, 'Incorrect Result');

		System.assertEquals(false, objWrapper2.blnCaseEscalationAccess, 'Incorrect Result');
		System.assertEquals('', objWrapper2.strEscalationType, 'Incorrect Result');
	}

	/**
	 * @Author : Ankit CS
	 * @Description : To assert if the user has access to change Case Owner
	 **/
	@isTest
	public static void testCanUserChangeOwner() {
		Test.startTest();

		List<User> list_Users = new List<User>();
		Boolean blnResult1;
		Boolean blnResult2;
		CareCaseButtons.PermissionWrapper objWrap1;
		CareCaseButtons.PermissionWrapper objWrap2;

		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		List<String> list_ChangeOwnerRoles = Label.Change_Owner_Roles.split(',');
		UserRole objUserRole = [SELECT Id, Name FROM UserRole WHERE Name = :list_ChangeOwnerRoles[0]];

		User objUserWOChangeOwnerAccess = new User(
			Alias = 'testU',
			Email = 'objUserWithAccess@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objUserWithAccess@CareCaseButtonsTest.com',
			ProfileId = objProfile.Id,
			UserRoleId = objUserRole.Id
		);
		list_Users.add(objUserWOChangeOwnerAccess);

		User objUserWithChangeOwnerAccess = new User(
			Alias = 'testU',
			Email = 'objUserWithoutAccess@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objUserWOAccess@CareCaseButtonsTest.com',
			ProfileId = objProfile.Id
		);
		list_Users.add(objUserWithChangeOwnerAccess);
		insert list_Users;

		System.runAs(objUserWithChangeOwnerAccess) {
			blnResult1 = CareCaseButtons.canUserChangeOwner();
			objWrap1 = CareCaseButtons.getPermissions();
		}

		System.runAs(objUserWOChangeOwnerAccess) {
			blnResult2 = CareCaseButtons.canUserChangeOwner();
			objWrap2 = CareCaseButtons.getPermissions();
		}

		Test.stopTest();

		//Assert if the user has access to Change Case Owner.
		System.assert(blnResult1, 'Incorect Result');
		System.assertEquals(blnResult1, objWrap1.blnChangeOwnerPerm, 'Incorect Result');

		//Assert if the user doesn't has access to Change Case Owner.
		System.assertEquals(false, blnResult2, 'Incorrect Result');
		System.assertEquals(blnResult2, objWrap2.blnChangeOwnerPerm, 'Incorect Result');
	}

	/**
	 * @Author : Ankit CS
	 * @Description : To assert if the user has access to create Social or Executive Escalation
	 **/
	@isTest
	public static void testGetSocialEscalationPermission() {
		Test.startTest();
		Boolean blnPermission = CareCaseButtons.getSocialEscalationPermission();
		Test.stopTest();

		System.assert(blnPermission, 'Incorect Result');
	}
}