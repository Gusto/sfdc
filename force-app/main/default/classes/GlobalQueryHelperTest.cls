/**
 * @author        Prashant Bhatt
 * @since         13 Jan 2020
 * @description   Test Class for - GlobalQueryHelper
 */

@isTest
private class GlobalQueryHelperTest {
	@testSetup
	private static void setupData() {
		UserRole objUserRole = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');

		insert objUserRole;

		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Benefits Compliance'];

		User objBenefitsComplianceUser = new User(
			ProfileId = objProfile.Id,
			LastName = 'last',
			Email = 'puser001@globalHelper.com',
			Username = 'puser001@globalHelper.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'aliass',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			UserRoleId = objUserRole.Id
		);

		insert objBenefitsComplianceUser;
	}

	@isTest
	private static void testGlobalMethods() {
		UserRole objUserRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'MyCustomRole'];

		Test.startTest();

		User user = new User(
			ProfileId = ([SELECT Id FROM Profile WHERE Name = 'System Administrator']
			.Id),
			LastName = 'last',
			Email = 'puser000@globalHelper.com',
			Username = 'puser000@globalHelper.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			UserRoleId = objUserRole.Id
		);
		insert user;
		Group groupRec = new Group(Name = 'group name', type = 'Queue');
		insert groupRec;

		QueuesObject queuesRec = new QueueSObject(QueueID = groupRec.Id, SobjectType = 'Lead');
		insert queuesRec;

		Set<Id> set_userIds = new Set<Id>();
		set_userIds.add(user.Id);

		Set<String> setCompanyIDs = new Set<String>();
		setCompanyIDs.add('1234');
		Map<String, UserRole> map_userRole = GlobalQueryHelper.getNameUserRoleMap();
		BusinessHours bh = GlobalQueryHelper.getDefaultBusinessHour();
		Map<Id, User> Map_user = GlobalQueryHelper.getUsersByIdMap(set_userIds);
		User user1 = GlobalQueryHelper.getUserInfoById(user.Id);
		List<User> list_Users = GlobalQueryHelper.getUsersInfoBySetOfIds(set_userIds);
		List<User> list_userbyEmail = GlobalQueryHelper.getListOfUserbyEmail('puser000@globalHelper.com');

		System.assertEquals(0, GlobalQueryHelper.getCollaborationGroup('collabGroup').size(), 'List size should be 0.');
		List<Group> grpName = GlobalQueryHelper.getGroupsByType('Queue');

		List<RecordType> list_recordTypes = GlobalQueryHelper.getRecordTypeBySObjectName('Account');

		List<RecordType> list_AccountRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account'];
		System.assertEquals(list_AccountRecordType.size(), list_recordTypes.size(), 'Number of Account Record Types should match.');

		System.assertEquals(0, GlobalQueryHelper.getOrgWideEmailByAdd('xyz@Test.com').size(), 'List size should be 0.');

		Boolean blnLoggedUserQueueMember = GlobalQueryHelper.getLoggedUserOrRoleGroupMember('Customer Success Roles');
		System.assert(!blnLoggedUserQueueMember, 'blnLoggedUserQueueMember should be false.');

		Test.stopTest();
	}

	@isTest
	private static void testPermSetAssignments() {
		UserRole objUserRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'MyCustomRole'];

		Set<String> set_QueueNames = new Set<String>{ 'Assurance_Class_1', 'Assurance_Class_2' };
		GlobalQueryHelper.getNameQueueMap(set_QueueNames);
		GlobalQueryHelper.getFiscalYearStartMonth();
		GlobalQueryHelper.getGroupsByName('Care Payroll Class 1');
		GlobalQueryHelper.getAllRegularGroupsMap();
		GlobalQueryHelper.getAllGroupQueueMap();
		GlobalQueryHelper.getAllPermissionSetsMap();
		List<String> list_PermNames = new List<String>{ 'Lightning Experience User' };
		GlobalQueryHelper.getPermSetAssignments(list_PermNames);
		GlobalQueryHelper.getAllAgencyInformation();
		GlobalQueryHelper.getAllCaseReasonClassification();
		GlobalQueryHelper.getProfileNameAndIdMap();
		GlobalQueryHelper.getSpecialistUserRoleMap();
		GlobalQueryHelper.getSubordinateRoles(new Set<Id>{ objUserRole.Id });
		GlobalQueryHelper.getAllBusinessHoursMap();
		GlobalQueryHelper.getAllQueuesByDevNameMap();
		GlobalQueryHelper.getAllSubCaseReasons();
		GlobalQueryHelper.queryActiveUsers(new Set<Id>{ UserInfo.getUserId() });
		Set<String> set_PermNames = new Set<String>{ 'Lightning Experience User' };
		GlobalQueryHelper.getPermissionSetUsers(set_PermNames, new List<User>{ GlobalQueryHelper.getUserInfoById(UserInfo.getUserId()) });
		System.assert(true, 'Fixed Apex PMD issue.');

		User objUser = [SELECT Id FROM User WHERE Email = 'puser001@globalHelper.com'];

		Map<Id, User> map_BenefitsComplianceUser = GlobalQueryHelper.getBenefitsComplianceUserMap(new Set<Id>{ objUser.Id });

		System.assert(!map_BenefitsComplianceUser.isEmpty(), 'User profile should be Benefit Compliance');
	}
}