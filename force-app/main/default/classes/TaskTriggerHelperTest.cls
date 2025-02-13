/**
 * @name         TaskTriggerHelperTest
 * @author       Praveen Sethu & Veeresh
 * @date         06/05/2021
 * @description  New Refactored TaskTriggerHelperTest Class
 * @see TaskTriggerHelper
 * @see TaskTriggerHandler
 **/
@isTest
public class TaskTriggerHelperTest {
	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Sets common data for all the test methods
	 **/
	@testSetup
	static void testData() {
		List<Account> list_Accounts;
		List<Case> list_Cases;
		List<Lead> list_Leads;
		List<User> list_Users;

		Set<String> set_ProfileNames = new Set<String>{
			TaskUtil.USER_PROFILE_NAME_GUSTO_INTEGRATION_PROFILE,
			TaskUtil.USER_PROFILE_NAME_GUSTO_DIRECT_MDR,
			TaskUtil.USER_PROFILE_PARTNER_AE,
			TaskUtil.USER_PROFILE_SDR,
			TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR
		};

		Map<String, Profile> map_Profiles = new Map<String, Profile>();

		for (Profile objProfile : [SELECT Id, Name FROM Profile WHERE Name IN :set_ProfileNames]) {
			map_Profiles.put(objProfile.Name, objProfile);
		}

		User objSalesMDRXUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(TaskUtil.USER_PROFILE_NAME_GUSTO_DIRECT_MDR).Id)
			.setUserRoleId(Label.MDR_Role_ID)
			.setUserName('testSalesMDR_XX_User@task.com')
			.setFirstName('Test FName')
			.setLastName('Test Lastname')
			.setEmail('testSalesMDR_XX_User@task.com')
			.setAlias('SaleMDR')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		User objPartnerUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR).Id)
			.setUserRoleId(TaskUtil.USER_ROLE_ID_PARTNER_MGR)
			.setUserName('testsalespartneruserfortask@testtask.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testsalespartneruserfortask@testtask.com')
			.setAlias('puser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		User objSmallBizUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(TaskUtil.USER_PROFILE_SDR).Id)
			.setUserRoleId(TaskUtil.USER_ROLE_ID_SMALL_BIZ_INBOUND)
			.setUserName('testsbizuserfortask@testtask.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testsbizuserfortask@testtask.com')
			.setAlias('sbuser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		// For the purpose of this test class, provide admin permissions to mmpr user
		// This is to test if mmpr user with admin permissions is prevented from deleting task records created by mdr users
		User objSalesMMPRUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR).Id)
			.setUserRoleId(TaskUtil.USER_ROLE_ID_SALES_MM_PR_XX)
			.setUserName('testmmpradmin@testtask.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testmmpradmin@testtask.com')
			.setAlias('mmpruser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		User objSysAdminUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR).Id)
			.setUserRoleId(TaskUtil.USER_ROLE_ID_EXEC)
			.setUserName('testsysadmin' + DateTime.now().getTime() + '@testtask.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testsysadmin@testtask.com')
			.setAlias('sysadm')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		list_Users = new List<User>{ objSalesMDRXUser, objPartnerUser, objSmallBizUser, objSalesMMPRUser, objSysAdminUser };

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objcurrentUser) {
			UserTriggerHelper.skipTrigger = true;
			insert list_Users;
			UserTriggerHelper.skipTrigger = false;
		}

		Account objAccountCompany = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 1').build();

		Account objAccountReseller = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('ABC Reseller Account 1').build();

		list_Accounts = new List<Account>{ objAccountCompany, objAccountReseller };
		insert list_Accounts;

		List<Contact> list_contactsToInsert = new List<Contact>();
		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objAccountCompany.Id)
			.setFirstName('Test Company')
			.setLastName('Contact 1')
			.setPhone('1234561234')
			.setEmail('newcontact1@task.com')
			.setNormalizedPhone('1234561234')
			.build();
		list_contactsToInsert.add(objCompanyContact);

		Contact objResellerContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.RESELLER_RT_NAME)
			.setAccountId(objAccountReseller.Id)
			.setFirstName('Test Reseller')
			.setLastName('Contact 1')
			.setPhone('1234661234')
			.setEmail('newcontact2@task.com')
			.setNormalizedPhone('1234661234')
			.build();
		list_contactsToInsert.add(objResellerContact);

		ContactTriggerHelper.skipTrigger = true;
		insert list_contactsToInsert;
		ContactTriggerHelper.skipTrigger = false;

		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Test Company')
			.setLastName('Lead1')
			.setEmail('test1@test.com')
			.setCompany('ABC Lead')
			.setLeadCreationOffer('List Upload')
			.setLeadSource('Test Class')
			.setAccountCreatedDate(DateTime.now().addDays(-10))
			.build();

		Lead objLead2 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('Test Company')
			.setLastName('Lead2')
			.setEmail('test2@test.com')
			.setCompany('ABC Lead')
			.setLeadCreationOffer('List Upload')
			.setLeadSource('Test Class')
			.setAccountCreatedDate(DateTime.now().addDays(-10))
			.build();

		list_Leads = new List<Lead>{ objLead1, objLead2 };
		insert list_Leads;

		Opportunity objCompanyOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setAccountId(objAccountCompany.Id)
			.setSoldBy(objAccountReseller.Id)
			.setName('Test Company')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.build();
		insert objCompanyOpportunity;

		TicketTriggerHelper.skipTrigger = true;
		List<Ticket__c> list_tickets = new List<Ticket__c>();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius'))
			.setOwnerId(UserInfo.getUserId())
			.setStatus('New')
			.build();
		list_tickets.add(objTicket);

		Ticket__c objWritingDocumentationTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius'))
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_REPORT_CREATION)
			.build();
		list_tickets.add(objWritingDocumentationTicket);

		Ticket__c objInternalReviewTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius'))
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_REPORT_CREATION)
			.build();
		list_tickets.add(objInternalReviewTicket);

		Ticket__c objRevisionNeededTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius'))
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_REPORT_CREATION)
			.build();
		list_tickets.add(objRevisionNeededTicket);

		insert list_tickets;

		TicketTriggerHelper.skipTrigger = false;

		TaskTriggerHelper.skipTrigger = true;
		List<Task> list_tasks = new List<Task>();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objTicket.Id)
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setType(TaskUtil.TASK_TYPE_EMAIL)
			.setPriority(TaskUtil.TASK_PRIORITY_LOW)
			.setSubject(TaskUtil.TASK_SUBJECT_REQUESTED)
			.setStartDate(System.now())
			.setOwnerId(UserInfo.getUserId())
			.build();
		list_tasks.add(objTask);

		Task objExecutiveDocumentationTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objWritingDocumentationTicket.Id)
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setType(TaskUtil.TASK_TYPE_EMAIL)
			.setPriority(TaskUtil.TASK_PRIORITY_LOW)
			.setSubject(TaskUtil.TASK_SUBJECT_EXECUTIVE_DOCUMENTATION)
			.setStartDate(System.now())
			.setOwnerId(UserInfo.getUserId())
			.build();
		list_tasks.add(objExecutiveDocumentationTask);

		Task objLeadReviewTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objInternalReviewTicket.Id)
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setType(TaskUtil.TASK_TYPE_EMAIL)
			.setPriority(TaskUtil.TASK_PRIORITY_LOW)
			.setSubject(TaskUtil.TASK_SUBJECT_PEER_REVIEW)
			.setStartDate(System.now())
			.setOwnerId(UserInfo.getUserId())
			.build();
		list_tasks.add(objLeadReviewTask);

		Task objRevisionNeededTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objRevisionNeededTicket.Id)
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setType(TaskUtil.TASK_TYPE_EMAIL)
			.setPriority(TaskUtil.TASK_PRIORITY_LOW)
			.setSubject(TaskUtil.TASK_SUBJECT_REVISION_NEEDED)
			.setStartDate(System.now())
			.setOwnerId(UserInfo.getUserId())
			.build();
		list_tasks.add(objRevisionNeededTask);

		insert list_tasks;
		TaskTriggerHelper.skipTrigger = false;
	}

	// TEST METHODS FOR BEFORE CONTEXT STARTS HERE
	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Insert a new task and set Who Id as Lead
	 *                Result - Lead__c field must be set
	 **/
	@isTest
	static void testIfWhoIdIsLead() {
		Lead objLead = [SELECT Id FROM Lead LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_IN_PROGRESS)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.setStartDate(System.now())
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, Lead__c FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objLead.Id, objTaskAssert.Lead__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Insert a new task and set What Id as Opportunity
	 *                Result - Opportunity__c field must be set
	 **/
	@isTest
	static void testIfWhatIdIsOppty() {
		Opportunity objOppty = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objOppty.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, Opportunity__c FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objOppty.Id, objTaskAssert.Opportunity__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Creates new feed Items based on Task Description
	 *                Result - Feed_Created__c field must be set to true
	 *                         FeedItem record should be created
	 **/
	@isTest
	static void testCreateFeedItem() {
		// Skip Account Trigger for faster account inserts
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objAccount.Id)
			.setWhoId(objContact.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setDescription('Test Description')
			.setCallObject('5ace9134-c55b-45fe-8843-450b1ded0b70')
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, Feed_Created__c FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(true, objTaskAssert.Feed_Created__c);

		FeedItem objFeedItemAssert = [SELECT Id FROM FeedItem WHERE ParentId = :objTask.WhatId LIMIT 1];
		System.assertNotEquals(null, objFeedItemAssert);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Updates/ sets Start and End dates based on Status of the Task
	 *                Result - Start_Date__c should not be set if Task is Not Started yet
	 * 						   Date_Completed__c should be set to Current Datetime if the task is Completed
	 * 						   Start_Date__c should be set to Current Datetime if the task is In Progress and Start Date is null
	 **/

	@isTest
	public static void testUpdateDurationFields() {
		Test.startTest();

		Task objTask1 = new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_CALL_RT_ID).setStatus(TaskUtil.TASK_STATUS_NOT_STARTED).setType(TaskUtil.TASK_TYPE_CALL).build();

		Task objTask2 = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setStatus(TaskUtil.TASK_STATUS_COMPLETE)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setStartDate(System.now() - 1)
			.build();

		Task objTask3 = new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_CALL_RT_ID).setStatus(TaskUtil.TASK_STATUS_IN_PROGRESS).setType(TaskUtil.TASK_TYPE_CALL).build();

		insert new List<Task>{ objTask1, objTask2, objTask3 };

		Test.stopTest();

		Task objTask1Assert = [SELECT Id, Start_Date__c FROM Task WHERE Id = :objTask1.Id];
		System.assertEquals(null, objTask1Assert.Start_Date__c);

		Task objTask2Assert = [SELECT Id, Date_Completed__c FROM Task WHERE Id = :objTask2.Id];
		System.assertEquals(Date.valueOf(System.now()), Date.valueOf(objTask2Assert.Date_Completed__c));

		Task objTask3Assert = [SELECT Id, Start_Date__c FROM Task WHERE Id = :objTask3.Id];
		System.assertEquals(Date.valueOf(System.now()), Date.valueOf(objTask3Assert.Start_Date__c));

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Sets Start_Date__c to Current Date when Status is updated In Progress
	 *                Result - Start_Date__c should be set to Current Date
	 **/

	@isTest
	public static void testUpdateDurationFieldsUPDATE() {
		String strTaskSubject = 'Test change to In Progress from completed';

		Task objTaskUpdate = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setStatus(TaskUtil.TASK_STATUS_COMPLETE)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setSubject(strTaskSubject)
			.build();

		insert objTaskUpdate;

		Test.startTest();

		objTaskUpdate.Status = TaskUtil.TASK_STATUS_IN_PROGRESS;
		update objTaskUpdate;

		Test.stopTest();

		Task objTaskUpdateAssert = [SELECT Id, Reopened__c FROM Task WHERE Id = :objTaskUpdate.Id];
		System.assertEquals(true, objTaskUpdateAssert.Reopened__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Sets Booked_By__c on the Task if the current user is MDR User
	 *                Result - Booked_By__c should be set to Current User
	 **/

	@isTest
	static void testSetBookedBy() {
		User objSalesMDRXUser = [
			SELECT Id, UserRole.Name
			FROM User
			WHERE Email = 'testSalesMDR_XX_User@task.com' AND Profile.Name = :TaskUtil.USER_PROFILE_NAME_GUSTO_DIRECT_MDR AND UserRoleId = :Label.MDR_Role_ID
			LIMIT 1
		];

		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		System.runAs(objSalesMDRXUser) {
			Test.startTest();
			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhatId(objAccount.Id)
				.setWhoId(objContact.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.build();
			insert objTask;
			Test.stopTest();

			Task objTaskAssert = [SELECT Id, Booked_By__c FROM Task WHERE Id = :objTask.Id];
			System.assertEquals(objSalesMDRXUser.Id, objTaskAssert.Booked_By__c);
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if exceptions thrown in TriggerHandler class are caught
	 *                Result - List of Exceptions should not be empty
	 **/

	@isTest
	static void testExceptionsInHandler() {
		TaskTriggerHandler.blnTestException = true;
		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_CHAT_RT_ID).setStatus(TaskUtil.TASK_STATUS_COMPLETE).setType('Email').setDescription('Test Exception').build();
		insert objTask;
		update objTask;
		delete objTask;
		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'TaskTriggerHandler'];
		System.assertNotEquals(0, list_Exceptions.size());
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Activity Type is updated on Account
	 * 				  On Completing a Task, Last Activity Type must be updated on Account
	 **/

	@isTest
	static void testLastActivityTypeUpdateOnAccount() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objAccount.Id)
			.setWhoId(objContact.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setDescription('Test Description')
			.build();

		insert objTask;

		Test.startTest();
		objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
		update objTask;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Last_Activity_Type__c FROM Account WHERE Id = :objTask.WhatId];
		System.assertEquals(objTask.Type, objAccountAssert.Last_Activity_Type__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Sales Activity Type is updated on Account
	 * 				  On Completing a Task by a Sales User, Last Sales Activity Type must be updated on Account
	 **/

	@isTest
	static void testLastSalesActivityTypeUpdateOnAccount() {
		String strMDRRoleId = Label.MDR_Role_ID;
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		User objMDRUser = [SELECT Id, Name FROM User WHERE UserRoleId = :strMDRRoleId AND IsActive = TRUE LIMIT 1];

		System.runAs(objMDRUser) {
			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhatId(objAccount.Id)
				.setWhoId(objContact.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_CALL)
				.setDescription('Test Description')
				.setOwnerId(objMDRUser.Id)
				.build();

			insert objTask;

			// Complete Task using Sales User

			Test.startTest();
			objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
			update objTask;
			Test.stopTest();

			Account objAccountAssert = [SELECT Id, Last_Sales_Activity_Type__c FROM Account WHERE Id = :objTask.WhatId];
			System.assertEquals(objTask.Type, objAccountAssert.Last_Sales_Activity_Type__c);
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Activity Date is updated on Account when Task Status and Activity Date Changes Changes
	 **/

	@isTest
	static void testLastActivityDateUpdateOnAccount() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objAccount.Id)
			.setWhoId(objContact.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setDescription('Test Description')
			.build();

		insert objTask;

		// Trigger Task Status and Activity Date Change Change
		// Result - Last Activity Date must be updated on Account
		Test.startTest();
		objTask.Status = TaskUtil.TASK_STATUS_VOICEMAIL;
		objTask.ActivityDate = Date.today().addDays(2);
		update objTask;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Id = :objTask.WhatId];
		System.assertEquals(objTask.ActivityDate, objAccountAssert.Last_Activity_Date__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @see TaskTriggerHelper.populateActivityDatesOnAccLeadOpp()
	 * @description Test if Last Activity Date is updated on the Reseller Account when Task is created/updated on the company account
	 **/
	@isTest
	static void onAccountTask_testLastActivityDateUpdateOnResellerAccount() {
		Account objCompanyAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];
		objCompanyAccount.Sold_By__c = objResellerAccount.Id;
		update objCompanyAccount;

		System.runAs(objSalesUser) {
			Test.startTest();

			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhatId(objCompanyAccount.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_CALL)
				.setDescription('Test Description')
				.build();
			insert objTask;

			Account objResellerAccountAssert = [SELECT Id, Last_Activity_Date__c, Last_Call_Connect__c FROM Account WHERE Id = :objResellerAccount.Id];
			Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
			System.assertEquals(objTaskAssert.ActivityDate, objResellerAccountAssert.Last_Activity_Date__c);
			System.assertEquals(objTaskAssert.ActivityDate, objResellerAccountAssert.Last_Call_Connect__c);

			Test.stopTest();
		}
	}

	/**
	 * @see TaskTriggerHelper.populateActivityDatesOnAccLeadOpp()
	 * @description Test if Last Activity Date is updated on the Reseller Account when Task is created/updated on the company opportunity
	 **/
	@isTest
	static void onOpportunityTask_testLastActivityDateUpdateOnResellerAccount() {
		Account objCompanyAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];
		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.RESELLER_CONTACT_RT_ID LIMIT 1];
		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID AND AccountId = :objCompanyAccount.Id LIMIT 1];
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];
		objCompanyAccount.Sold_By__c = objResellerAccount.Id;
		update objCompanyAccount;

		System.runAs(objSalesUser) {
			Test.startTest();

			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhatId(objOpportunity.Id)
				.setWhoId(objContact.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_CALL)
				.setDescription('Test Description')
				.build();
			objTask.ActivityDate = Date.today().addDays(2);
			insert objTask;

			Account objResellerAccountAssert = [SELECT Id, Last_Activity_Date__c, Last_Call_Connect__c FROM Account WHERE Id = :objResellerAccount.Id];
			Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
			Contact objContactAssert = [SELECT Id, Last_Contact_Activity__c, Last_Contact_Connect__c FROM Contact WHERE Id = :objContact.Id];
			System.assertEquals(objTaskAssert.ActivityDate, objResellerAccountAssert.Last_Activity_Date__c);
			System.assertEquals(objTaskAssert.ActivityDate, objResellerAccountAssert.Last_Call_Connect__c);
			System.assertEquals(objTaskAssert.ActivityDate, objContactAssert.Last_Contact_Activity__c);
			System.assertEquals(objTaskAssert.ActivityDate, objContactAssert.Last_Contact_Connect__c);

			Test.stopTest();
		}
	}

	/**
	 * @see TaskTriggerHelper.populateActivityDatesOnAccLeadOpp()
	 * @description Test if Last Activity Date is updated on the Reseller Account when Task is created/updated on the company contact
	 **/
	@isTest
	static void onContactTask_testLastActivityDateUpdateOnResellerAccount() {
		Account objCompanyAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];
		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.RESELLER_CONTACT_RT_ID LIMIT 1];
		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID AND AccountId = :objCompanyAccount.Id LIMIT 1];
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];
		objCompanyAccount.Sold_By__c = objResellerAccount.Id;
		update objCompanyAccount;

		System.runAs(objSalesUser) {
			Test.startTest();

			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhoId(objContact.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_CALL)
				.setDescription('Test Description')
				.build();
			objTask.ActivityDate = Date.today().addDays(-2);
			insert objTask;

			Account objResellerAccountAssert = [SELECT Id, Last_Activity_Date__c, Last_Call_Connect__c FROM Account WHERE Id = :objResellerAccount.Id];
			Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
			Contact objContactAssert = [SELECT Id, Last_Contact_Activity__c, Last_Contact_Connect__c FROM Contact WHERE Id = :objContact.Id];
			System.assertEquals(objTaskAssert.ActivityDate, objResellerAccountAssert.Last_Activity_Date__c);
			System.assertEquals(objTaskAssert.ActivityDate, objResellerAccountAssert.Last_Call_Connect__c);
			System.assertEquals(objTaskAssert.ActivityDate, objContactAssert.Last_Contact_Activity__c);
			System.assertEquals(objTaskAssert.ActivityDate, objContactAssert.Last_Contact_Connect__c);

			Test.stopTest();
		}
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Account Activity Date is updated on Account
	 **/

	@isTest
	static void testLastAccountActivityDateUpdateOnAccount() {
		String strMDRRoleId = Label.MDR_Role_ID;
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		User objMDRUser = [SELECT Id, Name FROM User WHERE UserRoleId = :strMDRRoleId AND IsActive = TRUE LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objAccount.Id)
			.setWhoId(objContact.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setDescription('Test Description')
			.setOwnerId(objMDRUser.Id)
			.build();

		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
		Account objAccountAssert = [SELECT Id, Last_Rep_Activity_Date_New__c, Last_Account_Activity_Date__c FROM Account WHERE Id = :objTask.WhatId];

		System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Rep_Activity_Date_New__c);
		System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Account_Activity_Date__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Account Activity Date is updated on Account for Email Task
	 **/

	@isTest
	static void testLastAccountActivityDateUpdateOnAccountByEmailTask() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		User objExecUser = [SELECT Id FROM User WHERE UserRole.Name = :TaskUtil.USER_ROLE_EXEC AND Profile.Name = 'ZP System Administrator' AND IsActive = TRUE LIMIT 1];
		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		System.runAs(objExecUser) {
			Test.startTest();
			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_EMAIL_RT_ID)
				.setWhatId(objAccount.Id)
				.setWhoId(objContact.Id)
				.setStatus(TaskUtil.TASK_STATUS_EMAIL_SENT)
				.setType(TaskUtil.TASK_TYPE_EMAIL)
				.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
				.build();

			insert objTask;
			Test.stopTest();

			Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
			Account objAccountAssert = [SELECT Id, Last_Rep_Activity_Date_New__c, Last_Account_Activity_Date__c FROM Account WHERE Id = :objTask.WhatId];
			System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Account_Activity_Date__c);
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Account Activity Date is updated on Opportunity and Account
	 **/

	@isTest
	static void testLastActivityDateUpdateOnOpportunity() {
		String strMDRRoleId = Label.MDR_Role_ID;
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		User objMDRUser = [SELECT Id, Name FROM User WHERE UserRoleId = :strMDRRoleId AND IsActive = TRUE LIMIT 1];

		Opportunity objOppty = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID AND AccountId = :objAccount.Id LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objOppty.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.setOwnerId(objMDRUser.Id)
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
		Opportunity objOpptyAssert = [SELECT Id, Last_Activity_Date__c FROM Opportunity WHERE Id = :objTask.WhatId];
		Account objAccountAssert = [SELECT Id, Last_Rep_Activity_Date_New__c, Last_Account_Activity_Date__c FROM Account WHERE Id = :objAccount.Id];

		System.assertEquals(objTaskAssert.ActivityDate, objOpptyAssert.Last_Activity_Date__c);
		System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Rep_Activity_Date_New__c);
		System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Account_Activity_Date__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Account Activity Date is updated on Opportunity by Email Task
	 **/

	@isTest
	static void testLastAccountActivityDateUpdateOnOpportunityByEmailTask() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		User objExecUser = [SELECT Id FROM User WHERE UserRole.Name = :TaskUtil.USER_ROLE_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objExecUser) {
			OpportunityTriggerHelper.skipTrigger = true;
			Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
				.setAccountId(objAccount.Id)
				.setName('Test Company')
				.setStage(OpportunityUtil.SAL_STAGE)
				.setCloseDate(System.today())
				.build();
			insert objOppty;
			OpportunityTriggerHelper.skipTrigger = false;

			Test.startTest();
			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_EMAIL_RT_ID)
				.setWhatId(objOppty.Id)
				.setStatus(TaskUtil.TASK_STATUS_EMAIL_SENT)
				.setType(TaskUtil.TASK_TYPE_EMAIL)
				.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
				.build();

			insert objTask;
			Test.stopTest();

			Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];

			Account objAccountAssert = [SELECT Id, Last_Rep_Activity_Date_New__c, Last_Account_Activity_Date__c FROM Account WHERE Id = :objAccount.Id];

			System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Account_Activity_Date__c);
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Call Connect and Last Call are updated on Opportunity
	 **/
	@isTest
	static void testIfLastCallConnectIsUpdatedOnOpportunity() {
		Opportunity objOppty = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objOppty.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
		Opportunity objOpptyAssert = [SELECT Id, Last_Call_Connect__c, Last_Call__c FROM Opportunity WHERE Id = :objTask.WhatId];

		System.assertEquals(objTaskAssert.ActivityDate, objOpptyAssert.Last_Call_Connect__c);
		System.assertEquals(objTaskAssert.ActivityDate, objOpptyAssert.Last_Call__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Rep Activity Date and Last Call  & Connect Date is updated on Lead
	 **/
	@isTest
	static void testLastActivityDateUpdateOnLead() {
		Lead objLead = [SELECT Id FROM Lead WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
		Lead objLeadAssert = [SELECT Id, Last_Rep_Activity_Date__c, Last_Call_Connect__c, Last_Call__c FROM Lead WHERE Id = :objTask.WhoId];

		System.assertEquals(objTaskAssert.ActivityDate, objLeadAssert.Last_Rep_Activity_Date__c);
		System.assertEquals(objTaskAssert.ActivityDate, objLeadAssert.Last_Call_Connect__c);
		System.assertEquals(objTaskAssert.ActivityDate, objLeadAssert.Last_Call__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Lead Activity Date is updated on Account
	 **/

	@isTest
	static void testLastLeadActivityDateUpdateOnLead() {
		String strMDRRoleId = Label.MDR_Role_ID;
		Lead objLead = [SELECT Id FROM Lead WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID LIMIT 1];

		User objMDRUser = [SELECT Id, Name FROM User WHERE UserRoleId = :strMDRRoleId AND IsActive = TRUE LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setDescription('Test Description')
			.setOwnerId(objMDRUser.Id)
			.build();

		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
		Lead objLeadAssert = [SELECT Id, Last_Lead_Activity_Date__c, Last_Rep_Activity_Date_New__c FROM Lead WHERE Id = :objTask.WhoId];

		System.assertEquals(objTaskAssert.ActivityDate, objLeadAssert.Last_Lead_Activity_Date__c);
		System.assertEquals(objTaskAssert.ActivityDate, objLeadAssert.Last_Rep_Activity_Date_New__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Lead Activity Date is updated on Lead by Email Task
	 **/
	@isTest
	static void testLastLeadActivityDateUpdateOnLeadByEmailTask() {
		User objExecUser = [SELECT Id FROM User WHERE UserRole.Name = :TaskUtil.USER_ROLE_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objExecUser) {
			Test.startTest();

			Lead objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('Test Company')
				.setLastName('Lead1')
				.setEmail('newleadtest@newleadtes.com')
				.setCompany('ABC Lead')
				.setLeadCreationOffer('List Upload')
				.setLeadSource('Test Class')
				.setAccountCreatedDate(DateTime.now().addDays(-10))
				.build();
			insert objLead;
			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_EMAIL_RT_ID)
				.setWhoId(objLead.Id)
				.setStatus(TaskUtil.TASK_STATUS_EMAIL_SENT)
				.setType(TaskUtil.TASK_TYPE_EMAIL)
				.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
				.build();

			insert objTask;
			Test.stopTest();

			Task objTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Id = :objTask.Id];
			Lead objLeadAssert = [SELECT Id, Last_Lead_Activity_Date__c FROM Lead WHERE Id = :objTask.WhoId];

			System.assertEquals(objTaskAssert.ActivityDate, objLeadAssert.Last_Lead_Activity_Date__c);
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	// TEST METHODS FOR BEFORE CONTEXT ENDS HERE
	// TEST METHODS FOR AFTER CONTEXT STARTS HERE

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Intentionally delete existing Lead Related Tracking Record
	 * 				  Validate if Lead Related Tracking Record Is Upserted
	 **/
	@isTest
	static void testIfLeadRelatedTrackingRecordIsCreated() {
		// Take existing Lead and delete it's lead related tracking record
		Lead objLead = [SELECT Id FROM Lead WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID LIMIT 1];

		List<Lead_Related_Tracking__c> list_Trackings = [SELECT Id FROM Lead_Related_Tracking__c WHERE Lead__c = :objLead.Id];
		delete list_Trackings;

		// Insert a new task for lead and validate new lead related tracking record is upserted
		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_EMAIL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_EMAIL_SENT)
			.setType(TaskUtil.TASK_TYPE_EMAIL)
			.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
			.build();

		insert objTask;
		Test.stopTest();

		List<Lead_Related_Tracking__c> list_TrackingsAssert = [SELECT Id FROM Lead_Related_Tracking__c WHERE Lead__c = :objTask.WhoId];

		// New Lead Related Tracking Record should be created
		System.assertEquals(1, list_TrackingsAssert.size());

		// Finally check if there are any exceptions logged
		checkForExceptions();
		delete objTask;
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Intentionally delete existing Account Related Tracking Record
	 * 				  Validate if Account Related Tracking Record Is Upserted
	 **/
	@isTest
	static void testIfAccountRelatedTrackingRecordIsCreated() {
		// Take existing Account and delete it's Account related tracking record
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		List<Account_Related_Tracking__c> list_Trackings = [SELECT Id FROM Account_Related_Tracking__c WHERE Account__c = :objAccount.Id];

		if (!list_Trackings.isEmpty()) {
			delete list_Trackings;
		}

		// Insert a new task for Account and validate new Account related tracking record is upserted
		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_EMAIL_RT_ID)
			.setWhatId(objAccount.Id)
			.setStatus(TaskUtil.TASK_STATUS_EMAIL_SENT)
			.setType(TaskUtil.TASK_TYPE_EMAIL)
			.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
			.build();

		insert objTask;
		Test.stopTest();

		List<Account_Related_Tracking__c> list_TrackingsAssert = [SELECT Id FROM Account_Related_Tracking__c WHERE Account__c = :objTask.WhatId];

		// New Lead Related Tracking Record should be created
		System.assertEquals(1, list_TrackingsAssert.size());

		// Finally check if there are any exceptions logged
		checkForExceptions();
		delete objTask;
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if HI_Rep_First_Touch__c is updated on Account that has Benefits New Plan or Transfer Opportunities
	 **/
	@isTest
	static void testHIRepFirstTouchUpdateOnAccount() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objBOROppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setAccountId(objAccount.Id)
			.setName('Test BOR Oppty')
			.setStage(OpportunityUtil.DEFAULT_HI_SALES_STAGE)
			.setCloseDate(System.today())
			.build();
		insert objBOROppty;
		OpportunityTriggerHelper.skipTrigger = false;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objBOROppty.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		Test.stopTest();

		Account objAccountAssert = [SELECT Id, HI_Rep_First_Touch__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(true, objAccountAssert != null);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if  Small_Biz_Engagement__c is updated on Contact and Lead If Task is Created By Small Biz User
	 **/
	@isTest
	static void testSmallBizEngagementUpdateOnContactAndLead() {
		User objSmallBizUser = [SELECT Id FROM User WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_SMALL_BIZ_INBOUND AND IsActive = TRUE LIMIT 1];

		Lead objLead = [SELECT Id FROM Lead WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID LIMIT 1];

		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		System.runAs(objSmallBizUser) {
			Task objLeadTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhoId(objLead.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.build();

			Task objContactTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhoId(objContact.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.build();

			List<Task> list_TasksToInsert = new List<Task>{ objLeadTask, objContactTask };

			Test.startTest();
			insert list_TasksToInsert;
			Test.stopTest();
		}

		Contact objContactAssert = [SELECT Id, Small_Biz_Engagement__c FROM Contact WHERE Id = :objContact.Id];
		Lead objLeadAssert = [SELECT Id, Small_Biz_Engagement__c FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objContactAssert.Small_Biz_Engagement__c);
		System.assertEquals(true, objLeadAssert.Small_Biz_Engagement__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last_Call_Connect__c and Last_Call_Connect_by_Owner__c is updated on Account
	 **/
	@isTest
	static void testIfLastConnectIsUpdatedOnAccount() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objAccount.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_OUTBOUND_CALL)
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, ActivityDate, Owner.Name FROM Task WHERE Id = :objTask.Id];
		Account objAccountAssert = [SELECT Id, Last_Call_Connect__c, Last_Call_Connect_by_Owner__c FROM Account WHERE Id = :objAccount.Id];

		System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Call_Connect__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if Last Call Connect is updated on Opportunity, Account Last Call Connect is also updated
	 **/
	@isTest
	static void testLastCallConnectUpdateOnOpportunity() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Opportunity objOppty = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID LIMIT 1];

		TaskTriggerHelper.skipTrigger = true;
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objOppty.Id)
			.setStatus(TaskUtil.TASK_STATUS_VOICEMAIL)
			.setType(TaskUtil.TASK_TYPE_OUTBOUND_CALL)
			.build();
		insert objTask;
		TaskTriggerHelper.skipTrigger = false;

		Test.startTest();

		// set call status as connect and update activity date
		objTask.Status = TaskUtil.TASK_STATUS_CONNECT;
		objTask.ActivityDate = Date.today().addDays(10);
		update objTask;

		Test.stopTest();

		// query task, account & opportunity
		Task objTaskAssert = [SELECT Id, ActivityDate, Owner.Name FROM Task WHERE Id = :objTask.Id];
		Account objAccountAssert = [SELECT Id, Last_Call_Connect__c FROM Account WHERE Id = :objAccount.Id];
		Opportunity objOpptyAssert = [SELECT Id, Last_Call_Connect__c FROM Opportunity WHERE Id = :objOppty.Id];

		// assert last call connect on account and opportunity got updated
		System.assertEquals(objTaskAssert.ActivityDate, objAccountAssert.Last_Call_Connect__c);
		System.assertEquals(objTaskAssert.ActivityDate, objOpptyAssert.Last_Call_Connect__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Case Audit Logs are upserted for Genesys tasks
	 **/
	static testMethod void testGenesysTaskDuration() {
		Contact objContact = [SELECT Id FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.RECTYPE_NAME_SALES_CASES)
			.setContactId(objContact.Id)
			.setDescription('Test Relation')
			.setSubject('Test Relation Subject')
			.setType(CaseUtils.TYPE_SALES_CHAT)
			.setOrigin(CaseUtils.ORIGIN_CHAT)
			.setSBSurveyMailSent(true)
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.setWhatId(objCase.Id)
			.setCallObject('TestCallObject')
			.setCallDurationInSeconds(100)
			.setCallType('Inbound')
			.build();
		insert objTask;
		Test.stopTest();

		Case_Audit_Log__c objCaseAuditLogAssert = [SELECT Id, External_Id__c FROM Case_Audit_Log__c WHERE Case__c = :objCase.Id];
		System.assertEquals(objTask.CallObject, objCaseAuditLogAssert.External_Id__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Callback flag is updated on Case from Task
	 **/
	static testMethod void testUpdateCaseCallBackFromTask() {
		Contact objContact = [SELECT Id FROM Contact WHERE RecordTypeId = :ContactUtil.COMPANY_CONTACT_RT_ID LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.RECTYPE_NAME_SALES_CASES)
			.setContactId(objContact.Id)
			.setDescription('Test Relation')
			.setSubject('Test Relation Subject')
			.setType(CaseUtils.TYPE_SALES_CHAT)
			.setOrigin(CaseUtils.ORIGIN_CHAT)
			.setSBSurveyMailSent(true)
			.setGenesysCallId('TEST-GENESYS-CALL-ID')
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objContact.Id)
			.setStatus(TaskUtil.TASK_STATUS_VOICEMAIL)
			.setType(TaskUtil.TASK_TYPE_INBOUND_CALL)
			.setCallObject(objCase.Genesys_Call_Id__c)
			.setCallDurationInSeconds(100)
			.setCallType('Inbound')
			.setSubject('Callback at 10:00 AM')
			.build();
		insert objTask;
		Test.stopTest();

		Case objCaseAssert = [SELECT Id, Callback__c, Date_Time_Submitted__c, Date_Time_End__c FROM Case WHERE Id = :objCase.Id];

		System.assertEquals(true, objCaseAssert.Callback__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if MDR First Call Date is updated on LRT if Lead is MQL and Owned by MDR
	 **/
	static testMethod void testIfMQLDateIsUpdatedOnLeadRelatedTracking() {
		String strMDRRoleId = Label.MDR_Role_ID;
		Lead objLead = [SELECT Id FROM Lead WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID LIMIT 1];
		User objMDRUser = [SELECT Id, Name FROM User WHERE UserRoleId = :strMDRRoleId AND IsActive = TRUE LIMIT 1];

		// Update Lead Ownership to MDR and Promote Lead to MQL
		objLead.Status = LeadUtil.LEAD_STATUS_MQL;
		objLead.OwnerId = objMDRUser.Id;

		// Skip Lead trigger for Faster Lead Updates
		LeadTriggerHelper.skipTrigger = true;
		update objLead;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		Test.stopTest();

		Lead_Related_Tracking__c objLeadTrackingAssert = [SELECT Id, MDR_First_Call_Date__c FROM Lead_Related_Tracking__c WHERE Lead__c = :objLead.Id];
		System.assertNotEquals(null, objLeadTrackingAssert.MDR_First_Call_Date__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Lead Initiated & Form Submitted Date are updated on Lead - Scenario 1
	 * 				  Test when Lead Creation Offer is Null
	 **/
	static testMethod void testIfLeadDateFieldsAreUpdatedScenario1() {
		Lead objLead = [SELECT Id, Lead_Creation_Offer__c FROM Lead WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID LIMIT 1];

		// Reset Lead Creation Offer
		objLead.Lead_Creation_Offer__c = '';
		LeadTriggerHelper.skipTrigger = true;
		update objLead;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Lead_Initiated_Date__c, Form_Submitted_Date__c FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(null, objLeadAssert.Lead_Initiated_Date__c);
		System.assertNotEquals(null, objLeadAssert.Form_Submitted_Date__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Lead Initiated & Form Submitted Date are updated on Converted Lead - Scenario 2
	 * 				  Test when Lead Creation Offer is List Upload
	 **/
	static testMethod void testIfLeadDateFieldsAreUpdatedScenario2() {
		Lead objLead = [
			SELECT Id, ZP_Company_ID__c, Email, Unique_Email_Address__c, ZP_Company_Lead_ID__c, OwnerId, ZP_Firm_ID__c, Lead_Creation_Offer__c, RecordTypeId
			FROM Lead
			WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID
			LIMIT 1
		];

		// Set Lead Creation Offer as List Upload and Convert Lead
		objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_LIST_UPL;
		objLead.Account_Created_Date__c = DateTime.now().addDays(-10);
		LeadTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Lead_Initiated_Date__c, Form_Submitted_Date__c FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(null, objLeadAssert.Lead_Initiated_Date__c);
		System.assertNotEquals(null, objLeadAssert.Form_Submitted_Date__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Lead Initiated & Form Submitted Date are updated on Converted Lead - Scenario 3
	 * 				  Test when Lead Creation Offer is List Upload and Task Record Type is not Connect
	 * 				  Set Subject to 'Filled Out Form'
	 **/
	static testMethod void testIfLeadDateFieldsAreUpdatedScenario3() {
		Lead objLead = [
			SELECT Id, ZP_Company_ID__c, Email, Unique_Email_Address__c, ZP_Company_Lead_ID__c, OwnerId, ZP_Firm_ID__c, Lead_Creation_Offer__c, RecordTypeId
			FROM Lead
			WHERE RecordTypeId = :LeadUtil.COMPANY_LEAD_RT_ID
			LIMIT 1
		];

		// Set Lead Creation Offer as List Upload and Convert Lead
		objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_LIST_UPL;
		objLead.Account_Created_Date__c = DateTime.now().addDays(-10);
		LeadTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_VOICEMAIL)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
			.build();
		insert objTask;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Lead_Initiated_Date__c, Form_Submitted_Date__c FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(null, objLeadAssert.Lead_Initiated_Date__c);
		System.assertNotEquals(null, objLeadAssert.Form_Submitted_Date__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}
	// TEST METHODS FOR AFTER CONTEXT ENDS HERE

	/**
	 * @author      Praveen Sethu
	 * @description Test if Task Trigger is Skipped
	 **/
	static testMethod void testTaskSkipTrigger() {
		TaskTriggerHelper.skipTrigger = true;

		Lead objLead = [SELECT Id FROM Lead LIMIT 1];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_IN_PROGRESS)
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.setStartDate(System.now())
			.build();
		insert objTask;
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, Lead__c FROM Task WHERE Id = :objTask.Id];
		System.assertNotEquals(objLead.Id, objTaskAssert.Lead__c);

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Test if no exceptions are logged
	 **/
	public static void checkForExceptions() {
		// Assert no exceptions are logged from Task Trigger
		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'TaskTriggerHandler'];
		System.assertEquals(0, list_Exceptions.size());
	}

	/**
	 * @author      Bhagat Singh
	 * @description Test Advising Touchpoints on Opportnity and Case records
	 **/
	public static void testAdvisingTouchpoints() {
		Test.startTest();
		skipTrigger(true);
		Opportunity objOpp = TestUtility.BenefitsRenewalOpportunity();
		Case objCase = new Case(
			AccountId = objOpp.AccountId,
			Subject = 'Test onboarding case',
			Priority = 'Medium',
			Opportunity__c = objOpp.Id,
			RecordTypeId = Cache.getRecordTypeName('Case', 'Benefits Renewal Case')
		);
		insert objCase;
		skipTrigger(false);

		Task objTask = new Task(
			RecordTypeId = Cache.getRecordTypeName('Task', 'Advising Call'),
			WhatId = objCase.Id,
			Status = TaskUtil.TASK_STATUS_VOICEMAIL,
			Type = TaskUtil.TASK_TYPE_DEMO,
			Subject = TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM
		);
		insert objTask;

		Test.stopTest();

		objCase = [SELECT Id, Opportunity__c, Advising_Touchpoints__c, Opportunity__r.Advising_Touchpoints__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(1, objCase.Advising_Touchpoints__c);
		System.assertEquals(1, objCase.Opportunity__r.Advising_Touchpoints__c);
	}

	/**
	 * @author      Bhagat Singh
	 * @description Skip Trigger, which is not required for this use case
	 * @param       Boolean True/False
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
	}

	/**
	 * @author      Veeresh Kumar
	 * @description Asserts if certain task fields for outbound phone calls are not overwritten by NICE.
	 **/
	@isTest
	static void testProcessNICETasks() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objAccount.Id)
			.setGenesysInteractionId('test GenesysInteractionId 1')
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_OUTBOUND_CALL)
			.setPriority(TaskUtil.TASK_PRIORITY_LOW)
			.setCallDisposition('test Insert Disposition')
			.build();
		TaskTriggerHelper.skipTrigger = true;
		insert objTask;
		TaskTriggerHelper.skipTrigger = false;
		Task objTaskInsertAssert = [SELECT Id, Genesys_Interaction_Id__c, Type FROM Task WHERE Id = :objTask.Id];
		System.assertNotEquals(null, objTaskInsertAssert.Genesys_Interaction_Id__c);
		System.assertEquals(objTask.Genesys_Interaction_Id__c, objTaskInsertAssert.Genesys_Interaction_Id__c);
		System.assertNotEquals(TaskUtil.TASK_TYPE_CALL, objTaskInsertAssert.Type);
		System.assertEquals(objTask.Type, objTaskInsertAssert.Type);
		Test.startTest();
		update new Task(
			Id = objTask.Id,
			CallDisposition = 'test Update Disposition',
			Priority = TaskUtil.TASK_PRIORITY_NORMAL,
			Status = TaskUtil.TASK_STATUS_COMPLETE,
			Type = TaskUtil.TASK_TYPE_OUTBOUND
		);
		Test.stopTest();
		Task objTaskUpdateAssert = [SELECT Id, CallDisposition, Priority, Status, Type FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objTask.CallDisposition, objTaskUpdateAssert.CallDisposition);
		System.assertEquals(objTask.Priority, objTaskUpdateAssert.Priority);
		System.assertEquals(objTask.Status, objTaskUpdateAssert.Status);
		System.assertEquals(objTask.Type, objTaskUpdateAssert.Type);
		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      David (Dato) Tsamalashvili
	 * @description Test task deletion
	 **/
	@isTest
	static void testTaskDeletion() {
		Test.startTest();
		TaskTriggerHandler.blnTestException = true;
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objAccount.Id)
			.setGenesysInteractionId('test GenesysInteractionId 1')
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_OUTBOUND_CALL)
			.setPriority(TaskUtil.TASK_PRIORITY_LOW)
			.setCallDisposition('test Insert Disposition')
			.build();

		TaskTriggerHelper.skipTrigger = true;
		insert objTask;
		TaskTriggerHelper.skipTrigger = false;

		System.runAs(objSalesUser) {
			try {
				delete objTask;
			} catch (Exception ex) {
				System.assert(ex.getMessage().contains('Delete failed'));
			}
		}

		Test.stopTest();
	}

	/**
	 * @author      Ajay Krishna PU
	 * @description Test Populate Last Activity Date
	 **/
	@isTest
	static void testPopulateLateActivityDate() {
		User objAdminUser = [SELECT Id FROM USER WHERE Email = 'testsysadmin@testtask.com' AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Test.startTest();

			TicketTriggerHelper.skipTrigger = true;
			Ticket__c objTicket = new TestDataFactory.TicketBuilder().setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius')).setOwnerId(UserInfo.getUserId()).build();
			insert objTicket;
			TicketTriggerHelper.skipTrigger = false;

			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
				.setWhatId(objTicket.Id)
				.setStatus(TaskUtil.TASK_STATUS_OPEN)
				.setType(TaskUtil.TASK_TYPE_EMAIL)
				.setPriority(TaskUtil.TASK_PRIORITY_LOW)
				.setStartDate(System.now())
				.setOwnerId(UserInfo.getUserId())
				.build();
			insert objTask;
			Test.stopTest();

			objTicket = [SELECT Id, Last_Activity_Date__c FROM Ticket__c WHERE Id = :objTicket.Id];
			System.assert(objTicket.Last_Activity_Date__c != null, 'PopulateLateActivityDate failed, Last Activity not populated on Insert');

			objTicket.Last_Activity_Date__c = null;
			update objTicket;

			objTask.Subject = 'Test Subject';
			update objTask;

			objTicket = [SELECT Id, Last_Activity_Date__c FROM Ticket__c WHERE Id = :objTicket.Id];
			System.assert(objTicket.Last_Activity_Date__c != null, 'PopulateLateActivityDate failed, Last Activity not populated on Update');
		}
	}

	/**
	 * @author      Jayesh Gawande
	 * @description Test Set Owner_Assigned_as_User__c Date/Time on Task if record is owned by User.
	 **/
	@isTest
	static void testsetOwnerAssignedToTaskTime() {
		User objAdminUser = [SELECT Id, Profile.Name FROM USER WHERE Email = 'testsysadmin@testtask.com' AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Test.startTest();

			TicketTriggerHelper.skipTrigger = true;
			Ticket__c objTicket = new TestDataFactory.TicketBuilder().setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius')).setOwnerId(UserInfo.getUserId()).build();
			insert objTicket;
			TicketTriggerHelper.skipTrigger = false;

			Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
				.setWhatId(objTicket.Id)
				.setStatus(TaskUtil.TASK_STATUS_OPEN)
				.setType(TaskUtil.TASK_TYPE_EMAIL)
				.setPriority(TaskUtil.TASK_PRIORITY_LOW)
				.setStartDate(System.now())
				.setOwnerId(UserInfo.getUserId())
				.build();
			insert objTask;
			Test.stopTest();

			System.assert(String.valueOf(objTask.OwnerId).startsWithIgnoreCase(TaskUtil.USER_PREFIX), 'Owner_Assigned_as_User__c failed populated on Insert');
		}
	}

	/**
	 * @author      Deepesh Rao
	 * @description Test Close ticket if Customer Revision Task is completed
	 **/
	@isTest
	static void testCloseTicketIfTaskCompleted() {
		User objAdminUser = [SELECT Id FROM USER WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Test.startTest();
			Task objTask = [SELECT Id, Status, WhatId FROM Task WHERE Subject = :TaskUtil.TASK_SUBJECT_REQUESTED LIMIT 1];
			System.assertEquals(objTask.Id != null, true, 'Task not present');

			objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
			update objTask;

			System.assertEquals(TaskUtil.TASK_STATUS_COMPLETE, objTask.Status, 'Task not completed');
			Test.stopTest();
		}
	}

	/**
	 * @author      Deepesh Rao
	 * @description mark ticket as internal review if task is completed
	 **/
	@isTest
	static void testWritingDocumentationTicket() {
		User objAdminUser = [SELECT Id FROM USER WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Test.startTest();
			Task objTask = [SELECT Id, Status, WhatId FROM Task WHERE Subject = :TaskUtil.TASK_SUBJECT_EXECUTIVE_DOCUMENTATION LIMIT 1];
			System.assertEquals(objTask.Id != null, true, 'Task not present');

			objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
			update objTask;

			System.assertEquals(TaskUtil.TASK_STATUS_COMPLETE, objTask.Status, 'Task not Completed');
			Test.stopTest();
		}
	}

	/**
	 * @author      Deepesh Rao
	 * @description mark ticket as revision needed if task is completed
	 **/
	@isTest
	static void testInternalReviewTicket() {
		User objAdminUser = [SELECT Id FROM USER WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Test.startTest();
			Task objTask = [SELECT Id, Status, WhatId FROM Task WHERE Subject = :TaskUtil.TASK_SUBJECT_PEER_REVIEW LIMIT 1];
			System.assertEquals(objTask.Id != null, true, 'Task not present');

			objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
			update objTask;

			System.assertEquals(TaskUtil.TASK_STATUS_COMPLETE, objTask.Status, 'Task not Completed');
			Test.stopTest();
		}
	}

	/**
	 * @author      Deepesh Rao
	 * @description mark ticket as customer submission if task is completed
	 **/
	@isTest
	static void testRevisionNeededTicket() {
		User objAdminUser = [SELECT Id FROM USER WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Test.startTest();
			Task objTask = [SELECT Id, Status, WhatId FROM Task WHERE Subject = :TaskUtil.TASK_SUBJECT_REVISION_NEEDED LIMIT 1];
			System.assertEquals(objTask.Id != null, true, 'Task not present');

			objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
			update objTask;

			System.assertEquals(TaskUtil.TASK_STATUS_COMPLETE, objTask.Status, 'Task not Completed');
			Test.stopTest();
		}
	}

	/**
	 * @author      Ajay Krishna P U
	 * @description Test Populate Ticket Status On Ardius Ticket related Task creation
	 **/
	@isTest
	static void testPopulateTicketStatusOnTaskCreation() {
		List<Ticket__c> list_Tickets = [SELECT Id, Status__c FROM Ticket__c WHERE RecordTypeId = :RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius') LIMIT 1];
		System.assert(!list_Tickets.isEmpty(), 'Test Tickets not found');

		Ticket__c objTicket = list_Tickets[0];
		String strInitialTicketStatus = objTicket.Status__c;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objTicket.Id)
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setStartDate(System.now())
			.build();
		insert objTask;
		Test.stopTest();

		//On Creation of task - Ticket Status should populate
		Task objTaskAssert = [SELECT Id, Ticket_Status__c FROM Task WHERE Id = :objTask.Id];
		System.assert(strInitialTicketStatus == objTaskAssert.Ticket_Status__c, 'Ticket Status on task object did not populated.');

		//On Updation of Ticket - No Ticket Status Change
		objTicket.Status__c = TicketUtil.TICKET_STATUS_REPORT_CREATION;
		update objTicket;
		objTaskAssert = [SELECT Id, Ticket_Status__c FROM Task WHERE Id = :objTask.Id];
		System.assert(strInitialTicketStatus == objTaskAssert.Ticket_Status__c, 'Ticket Status should not be updated on Ticket change.');

		//On Updation of Task - No Ticket Status Change
		objTask.Status = TaskUtil.TASK_STATUS_IN_PROGRESS;
		update objTicket;
		objTaskAssert = [SELECT Id, Ticket_Status__c FROM Task WHERE Id = :objTask.Id];
		System.assert(strInitialTicketStatus == objTaskAssert.Ticket_Status__c, 'Ticket Status should not be updated on Task change.');
	}

	/**
	 * @author       Ajay Krishna P U
	 * @description  Test Auto task creation
	 **/
	@isTest
	static void testAutoTaskCreation() {
		List<Task_Template__mdt> list_Templates = [
			SELECT Task_Type__c, Priority__c, Sub_Type__c, Task_Identifier__c
			FROM Task_Template__mdt
			WHERE Is_Active__c = TRUE AND DeveloperName = 'Ardius_Task_TSK_Document_Submission'
			LIMIT 1
		];
		System.assert(!list_Templates.isEmpty(), 'Test Template not found');

		List<Ticket__c> list_Tickets = [SELECT Id, Status__c FROM Ticket__c WHERE RecordTypeId = :RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius') LIMIT 1];
		System.assert(!list_Tickets.isEmpty(), 'Test Tickets not found');

		Task_Template__mdt objTemplate = list_Templates[0];
		Ticket__c objTicket = list_Tickets[0];

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objTicket.Id)
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setStartDate(System.now())
			.build();
		insert objTask;

		objTask.Feature_Request__c = objTemplate.Sub_Type__c;
		objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
		update objTask;

		List<Task> list_Tasks = [SELECT Id, Priority, Type FROM Task WHERE WhatId = :objTicket.Id AND Feature_Request__c = :objTemplate.Task_Identifier__c ORDER BY LastModifiedDate DESC LIMIT 1];
		System.assert(!list_Tasks.isEmpty(), 'Auto Task Creation failed');
		System.assert(list_Tasks[0].Priority == objTemplate.Priority__c, 'Invalid Task Priority');
		System.assert(list_Tasks[0].Type == objTemplate.Task_Type__c, 'Invalid Task Type');
		Test.stopTest();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if NBA fields are copied over from Lead to Task
	 **/
	@isTest
	static void testNBAFieldsUpdateFromLead() {
		Lead objLead = [SELECT Id, Served_Up_Rule__c, Served_Up_Time__c, Served_Other_Rules__c FROM Lead LIMIT 1];
		// Skip lead trigger
		TriggerHandler.bypass('LeadTriggerHandler');
		// update NBA fields on Lead
		objLead.Served_Up_Rule__c = 'Greeter';
		objLead.Served_Up_Time__c = System.now();
		objLead.Served_Other_Rules__c = 'Greeter;After Hours';
		// update lead
		update objLead;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhoId(objLead.Id)
			.setStatus(TaskUtil.TASK_STATUS_IN_PROGRESS)
			.setType(TaskUtil.TASK_TYPE_OUTBOUND_CALL)
			.setStartDate(System.now())
			.build();
		insert objTask;
		Test.stopTest();

		// Assert if NBA fields are updated on Task
		Task objTaskAssert = [SELECT Id, Served_Up_Rule__c, Served_Up_Time__c, Served_Other_Rules__c FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objLead.Served_Up_Rule__c, objTaskAssert.Served_Up_Rule__c, 'Served Up Rule not updated on Task');
		System.assertEquals(true, objTaskAssert.Served_Up_Time__c != null, 'Served Up Time not updated on Task');
		System.assertEquals(objLead.Served_Other_Rules__c, objTaskAssert.Served_Other_Rules__c, 'Served Other Rules not updated on Task');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if NBA fields are copied over from Opportunity to Task
	 **/
	@isTest
	static void testNBAFieldsUpdateFromOpportunity() {
		Opportunity objOppty = [SELECT Id, Served_Up_Rule__c, Served_Up_Time__c, Served_Other_Rules__c FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID LIMIT 1];
		// Skip opportunity trigger
		TriggerHandler.bypass('OpportunityTriggerHandler');
		// update NBA fields on Opportunity
		objOppty.Served_Up_Rule__c = 'Greeter';
		objOppty.Served_Up_Time__c = System.now();
		objOppty.Served_Other_Rules__c = 'Greeter;After Hours';
		update objOppty;

		Test.startTest();
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objOppty.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_OUTBOUND_CALL)
			.build();
		insert objTask;
		Test.stopTest();

		// Assert if NBA fields are updated on Task
		Task objTaskAssert = [SELECT Id, Served_Up_Rule__c, Served_Up_Time__c, Served_Other_Rules__c FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objOppty.Served_Up_Rule__c, objTaskAssert.Served_Up_Rule__c, 'Served Up Rule not updated on Task');
		System.assertEquals(true, objTaskAssert.Served_Up_Time__c != null, 'Served Up Time not updated on Task');
		System.assertEquals(objOppty.Served_Other_Rules__c, objTaskAssert.Served_Other_Rules__c, 'Served Other Rules not updated on Task');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test if Closed_Owenr_Role__c is getting updated on task creation
	 **/

	@isTest
	static void testSetClosedOwnerRoleInsert() {
		User objSalesMDRXUser = [
			SELECT Id, UserRole.Name
			FROM User
			WHERE Email = 'testSalesMDR_XX_User@task.com' AND Profile.Name = :TaskUtil.USER_PROFILE_NAME_GUSTO_DIRECT_MDR AND UserRoleId = :Label.MDR_Role_ID
			LIMIT 1
		];

		System.runAs(objSalesMDRXUser) {
			Test.startTest();
			Task objTask = new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_CALL_RT_ID).setStatus(TaskUtil.TASK_STATUS_OPEN).build();
			insert objTask;
			Test.stopTest();

			Task objTaskAssert = [SELECT Id, Closed_Owner_Role__c FROM Task WHERE Id = :objTask.Id];
			System.assertEquals(objSalesMDRXUser.UserRole.Name, objTaskAssert.Closed_Owner_Role__c, 'Closed Owner Role did not get updated with owner role.');
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test if Closed_Owenr_Role__c is getting updated on task closure
	 **/

	@isTest
	static void testSetClosedOwnerRoleUpdate() {
		User objSalesMDRXUser = [
			SELECT Id, UserRole.Name
			FROM User
			WHERE Email = 'testSalesMDR_XX_User@task.com' AND Profile.Name = :TaskUtil.USER_PROFILE_NAME_GUSTO_DIRECT_MDR AND UserRoleId = :Label.MDR_Role_ID
			LIMIT 1
		];

		System.runAs(objSalesMDRXUser) {
			Test.startTest();
			Task objTask = new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_CALL_RT_ID).setStatus(TaskUtil.TASK_STATUS_OPEN).build();
			insert objTask;

			objTask.Status = TaskUtil.TASK_STATUS_CONNECT;
			update objTask;
			Test.stopTest();

			Task objTaskAssert = [SELECT Id, Closed_Owner_Role__c FROM Task WHERE Id = :objTask.Id];
			System.assertEquals(objSalesMDRXUser.UserRole.Name, objTaskAssert.Closed_Owner_Role__c, 'Closed Owner Role did not get updated with owner role.');
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}
}