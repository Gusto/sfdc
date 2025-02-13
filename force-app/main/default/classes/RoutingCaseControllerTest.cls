@isTest
public class RoutingCaseControllerTest {
	@TestSetup
	static void setup() {
		List<User> list_Users = new List<User>();
		Profile objProfile = TestDataFactory.objZPSysAdminProfile;
		UserRole objUserRole = TestDataFactory.objUserRole;
		UserRole objAdminRole = TestDataFactory.objAdminRole;
		User objUserWithPermission = new User(
			Alias = 'testU',
			Email = 'objUserWithPerm@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objUserWithPerm@RoutingCaseControllerTest.com',
			ProfileId = objProfile.Id,
			UserRoleId = objUserRole.Id
		);
		list_Users.add(objUserWithPermission);

		User objUserWOPermission = new User(
			Alias = 'testU2',
			Email = 'objUserWOPerm@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objUserWOPerm@RoutingCaseControllerTest.com',
			ProfileId = objProfile.Id,
			UserRoleId = objAdminRole.Id
		);
		list_Users.add(objUserWOPermission);

		User objUserWCaseDetailPlayPermission = new User(
			Alias = 'testU3',
			Email = 'objUserWCaseDetailPlayPermission@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objUserWCaseDetailPlayPermission@RoutingCaseControllerTest.com',
			ProfileId = objProfile.Id,
			UserRoleId = objUserRole.Id
		);
		list_Users.add(objUserWCaseDetailPlayPermission);

		insert list_Users;

		//Create Parent Group
		Group objGroup = [SELECT Id FROM Group WHERE DeveloperName = 'Engagement_Case_Routing_Play_Access' LIMIT 1];
		List<GroupMember> list_GroupMembers = new List<GroupMember>();
		//Create Group Member
		GroupMember objGroupMember = new GroupMember();
		objGroupMember.UserOrGroupId = objUserWithPermission.Id;
		objGroupMember.GroupId = objGroup.Id;
		list_GroupMembers.add(objGroupMember);

		GroupMember objGroupMember2 = new GroupMember();
		objGroupMember2.UserOrGroupId = objUserWCaseDetailPlayPermission.Id;
		objGroupMember2.GroupId = objGroup.Id;
		list_GroupMembers.add(objGroupMember2);

		//Create Sub group
		Group objSubGroup = new Group();
		objSubGroup.Name = 'Test Group2';
		objSubGroup.Type = 'Regular';
		insert objSubGroup;

		//Create Group Map Data
		Map<String, Id> map_GroupNameRoleId = new Map<String, Id>();
		for (Group objPayrollGroup : [SELECT Id, Name FROM Group WHERE Type = 'Role']) {
			map_GroupNameRoleId.put('Core & Complete', objPayrollGroup.Id);
		}

		//Assign role to parent group
		GroupMember objGroupMember4 = new GroupMember();
		objGroupMember4.UserOrGroupId = map_GroupNameRoleId.get('Core & Complete');
		objGroupMember4.GroupId = objGroup.Id;
		list_GroupMembers.add(objGroupMember4);
		insert list_GroupMembers;

		//QA permission
		PermissionSet objPerm = [SELECT Id FROM PermissionSet WHERE Name = 'Can_Case_QA'];
		PermissionSetAssignment objPSA = new PermissionSetAssignment(AssigneeId = objUserWithPermission.Id, PermissionSetId = objPerm.Id);
		insert objPSA;
	}

	@isTest
	static void testFetchCasesRelatedToQueue() {
		CaseTriggerHelper.skipTrigger = true;
		// Insert Test Case Queues between Test.startTest() and Test.stopTest()
		// All async calls complete after Test.stopTest();
		// Isolating insertTestCaseQueue() to a future method to avoid MIXED_DML_ISSUE
		Test.startTest();
		insertTestCaseQueue();
		Test.stopTest();

		// Create a new Payroll Care Case
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
		List<Group> list_caseGroup = [SELECT Id FROM Group WHERE Name = 'Test Group'];
		// Check if Queues are created properly
		System.assertEquals(false, list_caseGroup.isEmpty(), 'Routing Case Controller - Test Fetch Case Related to Queue - Test queues not inserted');

		if (!list_caseGroup.isEmpty()) {
			objCase.OwnerId = list_caseGroup.get(0).Id;
			update objCase;
			RoutingCaseController.CaseDetailPlayRoutingWrapper objWrapper = RoutingCaseController.fetchCasesRelatedToQueue('Test Group');
			// We cannot use wrapper.list_caseToBeRouted.size() as Owner fields are not accessible using SOQL in test classes
			System.assertEquals(true, objWrapper.blnIsSuccess, 'Routing Case Controller - Test Fetch Case Related to Queue - Cases not assigned to Test Group');
		}
	}

	@isTest
	static void testUpdateCaseInRoute() {
		List<Case> list_Cases = new List<Case>();
		// Insert new Payroll Care Case
		Case objPayrollCareCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		list_Cases.add(objPayrollCareCase);

		// Insert new Benefits Care Case
		Case objBenefitsCareCase = TestDataFactory.createCaseRecord('Benefits Care', false);
		list_Cases.add(objBenefitsCareCase);

		CaseTriggerHelper.skipTrigger = true;
		insert list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		RoutingCaseController.CaseDetailPlayRoutingWrapper objWrapper = RoutingCaseController.updateCaseInRoute(objPayrollCareCase, true, objBenefitsCareCase);
		Test.stopTest();

		objPayrollCareCase = [SELECT Id, Case_In_Route__c FROM Case WHERE Id = :objPayrollCareCase.Id];
		objBenefitsCareCase = [SELECT Id, Case_In_Route__c FROM Case WHERE Id = :objBenefitsCareCase.Id];

		System.assertEquals(true, objPayrollCareCase.Case_In_Route__c, 'Routing Case Controller - Case In Route for first case was not set to true');
		System.assertEquals(false, objBenefitsCareCase.Case_In_Route__c, 'Routing Case Controller - Case In Route for second case was not set to false');
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : tests if RoutingCaseController.getTabVisibilityPermissions() returns true when user has Can_Case_QA permission set
	 **/
	@isTest
	static void testQAPlayPermissionAccept() {
		User objUser = [SELECT Id FROM User WHERE Email = 'objUserWithPerm@test.com'];
		Test.startTest();
		System.runAs(objUser) {
			RoutingCaseController.TabPermissions objTabPermissions = RoutingCaseController.getTabVisibilityPermissions();
			System.assert(objTabPermissions.blnQAPlayPermission, 'blnQAPlayPermission should be true.');
		}
		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : tests if RoutingCaseController.getTabVisibilityPermissions() returns false when user does not have permission set
	 **/
	@isTest
	static void testQAPlayPermissionFailure() {
		User objUser = [SELECT Id FROM User WHERE Email = 'objUserWOPerm@test.com'];
		Test.startTest();
		System.runAs(objUser) {
			RoutingCaseController.TabPermissions objTabPermissions = RoutingCaseController.getTabVisibilityPermissions();
			System.assert(!objTabPermissions.blnQAPlayPermission, 'blnQAPlayPermission should be false.');
		}
		Test.stopTest();
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : tests if RoutingCaseController.getTabVisibilityPermissions() returns true when user has Engagement_Admin permission set
	 **/
	@isTest
	static void testCaseDetailPlayPermissionAccept() {
		User objUser = [SELECT Id FROM User WHERE Email = 'objUserWCaseDetailPlayPermission@test.com'];
		Test.startTest();
		System.runAs(objUser) {
			RoutingCaseController.TabPermissions objTabPermissions = RoutingCaseController.getTabVisibilityPermissions();
			System.assert(objTabPermissions.blnCaseDetailPlayPermission, 'blnCaseDetailPlayPermission should be true.');
		}
		Test.stopTest();
	}

	@future
	public static void insertTestCaseQueue() {
		Group caseGroup = new Group(Name = 'Test Group', type = 'Queue');
		insert caseGroup;
		QueuesObject caseQueue = new QueueSObject(QueueID = caseGroup.Id, SobjectType = 'Case');
		insert caseQueue;
	}
}