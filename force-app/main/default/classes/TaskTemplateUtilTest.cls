/**
 * @author       Ajay Krishna P U
 * @date         12-19-2022
 * @description  Test class for TaskTemplateUtil
 */
@isTest
public with sharing class TaskTemplateUtilTest {
	/**
	 * @description Create Test Data
	 */
	@testSetup
	static void testData() {
		Set<String> set_ProfileNames = new Set<String>{ TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR };
		Map<String, Profile> map_Profiles = new Map<String, Profile>();
		for (Profile objProfile : [SELECT Id, Name FROM Profile WHERE Name IN :set_ProfileNames]) {
			map_Profiles.put(objProfile.Name, objProfile);
		}

		User objSysAdminUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR).Id)
			.setUserRoleId(TaskUtil.USER_ROLE_ID_EXEC)
			.setUserName('testsysadmin@testtask.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testsysadmin@testtask.com')
			.setAlias('sysadm')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		List<User> list_Users = new List<User>{ objSysAdminUser };

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objCurrentUser) {
			UserTriggerHelper.skipTrigger = true;
			insert list_Users;
			UserTriggerHelper.skipTrigger = false;
		}

		System.runAs(objSysAdminUser) {
			Account objAccountCompany = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 1').build();
			List<Account> list_Accounts = new List<Account>{ objAccountCompany };
			insert list_Accounts;

			Ticket__c objTicket = new TestDataFactory.TicketBuilder()
				.setStatus('New')
				.setDescription('Test Ardius Ticket')
				.setOwnerId(UserInfo.getUserId())
				.setAccountId(objAccountCompany.Id)
				.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius'))
				.build();
			objTicket.Close_Date__c = System.today();
			insert objTicket;
		}
	}

	/**
	 * @description Test Get SObject Field value dynamically
	 */
	@isTest
	static void testGetFieldValue() {
		User objSysAdmin = [SELECT Id FROM User WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND ISActive = TRUE LIMIT 1];
		System.runAs(objSysAdmin) {
			Ticket__c objTicket = [SELECT Id, Status__c, Close_Date__c, Account__r.Name, Opportunity__r.Name FROM Ticket__c LIMIT 1];

			Test.startTest();

			System.assert(ObjTicket.Status__c == TaskTemplateUtil.getFieldValue(objTicket, 'Status__c'), 'Test direct field failed');
			System.assert(ObjTicket.Account__r.Name == TaskTemplateUtil.getFieldValue(objTicket, 'Account__r.Name'), 'Test parent field failed');
			System.assert(ObjTicket.Opportunity__r.Name == TaskTemplateUtil.getFieldValue(objTicket, 'Opportunity__r.Name'), 'Test parent of null failed');

			System.assert(null == TaskTemplateUtil.getFieldValue(null, 'Opportunity__r.Name'), 'Test null object failed');
			Test.stopTest();
		}
	}

	/**
	 * @description Test Resolve Merge fields
	 */
	@isTest
	static void testResolveMergeFields() {
		Ticket__c objTicket = new Ticket__c(
            Description__c = 'Test Tick', 
            Status__c = 'New', 
            Account__r = new Account(Name = 'Test Account'), 
            Opportunity__c = null
        );

		Task_Template__mdt objTemplate = new Task_Template__mdt(Merge_Fields__c = 'Name,Account__r.Name');

		Test.startTest();
		System.assert(null == TaskTemplateUtil.resolveMergeFields(null, objTicket, objTemplate), 'Invalid result for Null inputStr');
		System.assert(null == TaskTemplateUtil.resolveMergeFields(null, objTicket, new Task_Template__mdt()), 'Invalid result for Null template Merge fields');

		System.assert('abcd' == TaskTemplateUtil.resolveMergeFields('abcd', objTicket, objTemplate), 'Invalid result for Non Merge field text');
		System.assert('abcd{}' == TaskTemplateUtil.resolveMergeFields('abcd{}', objTicket, objTemplate), 'Invalid result for {} Merge field');

		System.assert('New-abcd' == TaskTemplateUtil.resolveMergeFields('{{Status__c}}-abcd', objTicket, objTemplate), 'Invalid result for Same obj Merge fields - beginning');
		System.assert('abcd-New' == TaskTemplateUtil.resolveMergeFields('abcd-{{Status__c}}', objTicket, objTemplate), 'Invalid result for Same obj Merge fields - end');
		System.assert('abcd-New-fgddf' == TaskTemplateUtil.resolveMergeFields('abcd-{{Status__c}}-fgddf', objTicket, objTemplate), 'Invalid result for Same obj Merge fields - mid');

		System.assert(
			'New-Test Tick-abcd' == TaskTemplateUtil.resolveMergeFields('{{Status__c}}-{{Description__c}}-abcd', objTicket, objTemplate),
			'Invalid result for Same obj Multiple Merge fields - beginning'
		);
		System.assert(
			'abcd-New-Test Tick' == TaskTemplateUtil.resolveMergeFields('abcd-{{Status__c}}-{{Description__c}}', objTicket, objTemplate),
			'Invalid result for Same obj Multiple Merge fields - end'
		);
		System.assert(
			'abcd-New-Test Tick-fgddf' == TaskTemplateUtil.resolveMergeFields('abcd-{{Status__c}}-{{Description__c}}-fgddf', objTicket, objTemplate),
			'Invalid result for Same obj Multiple Merge fields - mid'
		);

		System.assert('Test Account-abcd' == TaskTemplateUtil.resolveMergeFields('{{Account__r.Name}}-abcd', objTicket, objTemplate), 'Invalid result for Parent obj Merge fields - beginning');
		System.assert('abcd-Test Account' == TaskTemplateUtil.resolveMergeFields('abcd-{{Account__r.Name}}', objTicket, objTemplate), 'Invalid result for Parent obj Merge fields - end');
		System.assert('abcd-Test Account-fgddf' == TaskTemplateUtil.resolveMergeFields('abcd-{{Account__r.Name}}-fgddf', objTicket, objTemplate), 'Invalid result for Parent obj Merge fields - mid');

		System.assert(
			'Test Account-Test Tick-abcd' == TaskTemplateUtil.resolveMergeFields('{{Account__r.Name}}-{{Description__c}}-abcd', objTicket, objTemplate),
			'Invalid result for Parent obj Multiple Merge fields - beginning'
		);
		System.assert(
			'abcd-Test Account-Test Tick' == TaskTemplateUtil.resolveMergeFields('abcd-{{Account__r.Name}}-{{Description__c}}', objTicket, objTemplate),
			'Invalid result for Parent obj Multiple Merge fields - end'
		);
		System.assert(
			'abcd-Test Account-Test Tick-fgddf' == TaskTemplateUtil.resolveMergeFields('abcd-{{Account__r.Name}}-{{Description__c}}-fgddf', objTicket, objTemplate),
			'Invalid result for Parent obj Multiple Merge fields - mid'
		);

		System.assert('abcd--bcd' == TaskTemplateUtil.resolveMergeFields('abcd-{{Opportunity__c}}-bcd', objTicket, objTemplate), 'Invalid result Empty field');
		Test.stopTest();
	}

	/**
	 * @description Test dynamically Query SObject
	 */
	@isTest
	static void testQuerySObjects() {
		User objSysAdmin = [SELECT Id FROM User WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND ISActive = TRUE LIMIT 1];
		System.runAs(objSysAdmin) {
			Ticket__c objTicket = [SELECT Id, Status__c, Close_Date__c, Account__r.Name, Opportunity__r.Name FROM Ticket__c LIMIT 1];

			Test.startTest();
			System.assert(true == TaskTemplateUtil.querySObjects('Ticket__c', new Set<String>(), new Set<Id>()).isEmpty(), 'Invalid result for Empty target ids');

			Map<Id, SObject> map_SObjects = TaskTemplateUtil.querySObjects('Ticket__c', new Set<String>{ 'Close_Date__c', 'Account__r.Name' }, new Set<Id>{ objTicket.Id });
			System.assert(null != map_SObjects.get(objTicket.Id), 'Invalid Ticket Object');
			System.assert(objTicket.Close_Date__c == ((Ticket__c) map_SObjects.get(objTicket.Id)).Close_Date__c, 'Invalid Ticket Object - Close_Date__c');
			System.assert(objTicket.Account__r.Name == ((Ticket__c) map_SObjects.get(objTicket.Id)).Account__r.Name, 'Invalid Ticket Object - Account__r.Name');
			Test.stopTest();
		}
	}

	/**
	 * @description Test generate Map Type --> SUbtype --> Template
	 */
	@isTest
	static void testGetTypeSubTypeTemplateMap() {
		User objSysAdmin = [SELECT Id FROM User WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND ISActive = TRUE LIMIT 1];
		System.runAs(objSysAdmin) {
			Task_Template__mdt objTemplate = [SELECT Type__c, Sub_Type__c, DeveloperName FROM Task_Template__mdt WHERE Is_Active__c = TRUE LIMIT 1];

			Test.startTest();
			Map<String, Map<String, Task_Template__mdt>> map_TypeToSubTypeTaskTemplates = TaskTemplateUtil.getTypeSubTypeTemplateMap();
			System.assert(null != map_TypeToSubTypeTaskTemplates.get(objTemplate.Type__c), 'Invalid Map, unable to find Type');
			System.assert(null != map_TypeToSubTypeTaskTemplates.get(objTemplate.Type__c).get(objTemplate.Sub_Type__c), 'Invalid Map, unable to find SubType');
			System.assert(objTemplate.DeveloperName == map_TypeToSubTypeTaskTemplates.get(objTemplate.Type__c).get(objTemplate.Sub_Type__c).DeveloperName, 'Invalid Map, unable to find Template ');
			Test.stopTest();
		}
	}

	/**
	 * @description Test generate Tasks
	 */
	@isTest
	static void testGenerateTasks() {
		User objSysAdmin = [SELECT Id FROM User WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND ISActive = TRUE LIMIT 1];
		System.runAs(objSysAdmin) {
			Task_Template__mdt objTemplate = [SELECT Type__c, Sub_Type__c, Task_Type__c FROM Task_Template__mdt WHERE Is_Active__c = TRUE LIMIT 1];
			Ticket__c objTicket = [SELECT Id, Status__c, Close_Date__c, Account__r.Name, Opportunity__r.Name FROM Ticket__c LIMIT 1];

			Test.startTest();
			List<Task> list_Tasks = TaskTemplateUtil.generateTasks(
				new List<TaskTemplateUtil.TemplateType>{ new TaskTemplateUtil.TemplateType(objTicket.Id, objTemplate.Type__c, objTemplate.Sub_Type__c) },
				'Ticket__c'
			);

			System.assert(false == list_Tasks.isEmpty(), 'Invalid result, No task');
			System.assert(objTicket.Id == list_Tasks[0].WhatId, 'Invalid field value - WhatId');
			System.assert(objTemplate.Task_Type__c == list_Tasks[0].Type, 'Invalid field value - Task_Type__c');
			Test.stopTest();
		}
	}

	/**
	 * @description Test Get Template subTypes
	 */
	@isTest
	static void testGetTemplateSubTypes() {
		User objSysAdmin = [SELECT Id FROM User WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND ISActive = TRUE LIMIT 1];
		System.runAs(objSysAdmin) {
			Task_Template__mdt objTemplate = [SELECT Type__c, Sub_Type__c, DeveloperName FROM Task_Template__mdt WHERE Is_Active__c = TRUE LIMIT 1];

			Test.startTest();
			Set<String> set_SubTypes = TaskTemplateUtil.getTemplateSubTypes(objTemplate.Type__c);
			System.assert(false == set_SubTypes.isEmpty(), 'Invalid result, No Subtypes');
			System.assert(true == set_SubTypes.contains(objTemplate.Sub_Type__c), 'Invalid result, unable to find SubType');
			Test.stopTest();
		}
	}

	/**
	 * @description Test Due date calculation based on Business hours
	 */
	@isTest
	static void testResolveDueDate() {
		Task_Template__mdt objTemplate = new Task_Template__mdt(No_of_Business_Days_from_Creation_to_Due__c = 1);
		Date dtAfterCalc = TaskTemplateUtil.resolveDueDate(objTemplate);
		System.assert(dtAfterCalc > Date.today(), 'Due date calculation failed');
	}

	/**
	 * @description Test Owner Id Calculation - Queue Id/ target Object
	 */
	@isTest
	static void testResolveOwnerId() {
		Group objQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' LIMIT 1];
		Map<String, Id> map_QueueNameToId = new Map<String, Id>{ objQueue.DeveloperName => objQueue.Id };

		Ticket__c objTicket = new Ticket__c(OwnerId = UserInfo.getUserId());

		Task_Template__mdt objTemplate = new Task_Template__mdt(Assigned_To__c = TaskTemplateUtil.ASSIGN_TO_TARGET_OWNER);
		Id idResolved = TaskTemplateUtil.resolveOwnerId(objTemplate, map_QueueNameToId, objTicket, null);
		System.assert(idResolved == objTicket.OwnerId, 'Calculation of Target Owner Id Failed');

		objTemplate = new Task_Template__mdt(Assigned_To__c = TaskTemplateUtil.ASSIGN_TO_QUEUE, Assign_To_Queue_Name__c = objQueue.DeveloperName);
		idResolved = TaskTemplateUtil.resolveOwnerId(objTemplate, map_QueueNameToId, objTicket, null);
		System.assert(idResolved == objQueue.Id, 'Calculation of Queue Id Failed');

		objTicket.OwnerId = objQueue.Id;
		objTemplate = new Task_Template__mdt(
			Assigned_To__c = TaskTemplateUtil.ASSIGN_TO_TARGET_OWNER,
			Assign_To_Queue_Name__c = objQueue.DeveloperName,
			Assign_To_Queue_If_Target_Owner_Is_Queue__c = true
		);
		idResolved = TaskTemplateUtil.resolveOwnerId(objTemplate, map_QueueNameToId, objTicket, null);
		System.assert(idResolved == objQueue.Id, 'Calculation of Owner Id where Target owner is a Queue Failed');
	}
	/**
	 * @description Test Owner Id Calculation - when Onboarding User
	 */
	@isTest
	static void testResolveOwnerIdForOnboardingTeam() {
		Group objQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' LIMIT 1];
		PermissionSet objPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = :TaskTemplateUtil.ARDIUS_TEAM_PERMISSION LIMIT 1];
		Assert.areEqual(objPermissionSet != null, true, 'Permission Set not found');
		Map<String, Id> map_QueueNameToId = new Map<String, Id>{ objQueue.DeveloperName => objQueue.Id };

		PermissionSetAssignment objPermissionSetAssignment = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = objPermissionSet.Id);
		Map<String, Set<Id>> map_PermissionSetUsers = new Map<String, Set<Id>>{ objPermissionSet.Name => new Set<Id>{ objPermissionSetAssignment.AssigneeId } };
		Task_Template__mdt objTemplate = new Task_Template__mdt(
			Assigned_To__c = TaskTemplateUtil.ASSIGN_TO_PERMISSION_SET,
			Assign_To_Queue_Name__c = objQueue.DeveloperName,
			Assign_To_Queue_If_Target_Owner_Is_Queue__c = true,
			Permission_Set_Name__c = TaskTemplateUtil.ARDIUS_TEAM_PERMISSION
		);
		Ticket__c objTicket = new Ticket__c(OwnerId = UserInfo.getUserId());

		Id idResolved = TaskTemplateUtil.resolveOwnerId(objTemplate, map_QueueNameToId, objTicket, map_PermissionSetUsers);
		Assert.areEqual(idResolved, UserInfo.getUserId(), 'Calculation of Owner Id when Ardius Onboarding team Failed');
	}

	/**
	 * @description Test Owner Id Calculation - when not Onboarding User
	 */
	@isTest
	static void testResolveOwnerIdForNoOnboardingUser() {
		Group objQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' LIMIT 1];
		PermissionSet objPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = :TaskTemplateUtil.ARDIUS_TEAM_PERMISSION LIMIT 1];
		Assert.areEqual(objPermissionSet != null, true, 'Permission Set not found');
		Map<String, Id> map_QueueNameToId = new Map<String, Id>{ objQueue.DeveloperName => objQueue.Id };

		PermissionSetAssignment objPermissionSetAssignment = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = objPermissionSet.Id);
		Map<String, Set<Id>> map_PermissionSetUsers = new Map<String, Set<Id>>{ objPermissionSet.Name => new Set<Id>{ objPermissionSetAssignment.AssigneeId } };
		Task_Template__mdt objTemplate = new Task_Template__mdt(
			Assigned_To__c = TaskTemplateUtil.ASSIGN_TO_PERMISSION_SET,
			Assign_To_Queue_Name__c = objQueue.DeveloperName,
			Assign_To_Queue_If_Target_Owner_Is_Queue__c = true
		);
		Ticket__c objTicket = new Ticket__c(OwnerId = UserInfo.getUserId());

		Id idResolved = TaskTemplateUtil.resolveOwnerId(objTemplate, map_QueueNameToId, objTicket, map_PermissionSetUsers);
		System.assert(idResolved == objQueue.Id, 'Calculation of Owner Id when Ardius Onboarding team for queue Failed');
	}
}