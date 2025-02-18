/**
 * @name         : InboundCallControllerTest
 * @author       : Nigam Goyal
 * @date         : 06-30-2022
 * @description  : Cover test Coverage InboundCallController
 **/
@IsTest
public with sharing class InboundCallControllerTest {
	@testSetup
	static void setUp() {
		// create company account

		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;

		// Creating Company Account
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		insert objAccnt;

		// Creating Company Account
		Account objAccnt1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company \'s 2').setZPCompanyId('1111111112').build();
		insert objAccnt1;

		// Creating Company Contact
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First\' Name1')
			.setLastName('Test Last\' Name1')
			.setEmail('newmember1@campaign.com')
			.setNormalizedPhone('1876543211')
			.build();
		insert objContact1;

		// Creating Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('newmember@campaign.com')
			.setNormalizedPhone('9876543211')
			.setPhone('9876543211')
			.build();
		insert objContact;

		// Creating Company Lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('leadcampaign@member.com')
			.setPhone('7898787868')
			.setCompany('Company Lead 1')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('LinkedIn')
			.build();
		insert objLead;

		// Creating Company Lead
		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName \' Special')
			.setLastName('LName \' Special')
			.setEmail('leadcampaign@member.com')
			.setPhone('123456789')
			.setCompany('Company \'s Lead 1')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('LinkedIn')
			.build();
		insert objLead1;

		//create opportunity
		TriggerHandler.bypass('OpportunityTriggerHandler');
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Test Opp')
			.setAccountId(objAccnt.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		objOpportunity.ZP_Company_ID__c = '1111111111';
		objOpportunity.Offers_Health_Insurance__c = 'Yes';
		insert objOpportunity;

		//create opportunity Benefits BoR
		Opportunity objOpportunity_BoR = new Opportunity();
		objOpportunity_BoR.AccountId = objAccnt.Id;
		objOpportunity_BoR.Name = 'Test Opp 2';
		objOpportunity_BoR.StageName = 'Pending PR';
		objOpportunity_BoR.CloseDate = System.today();
		objOpportunity_BoR.RecordTypeId = OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID;
		objOpportunity_BoR.Amount = 55000.00;
		insert objOpportunity_BoR;

		final String USER_ROLE_NAME_SALES_SB_IB_XX = 'sales_sb_ib_xx';
		final String USER_PROFILE_NAME_SDR = '_del_ZP SDR';

		Set<String> set_ProfileNames = new Set<String>{ USER_PROFILE_NAME_SDR };
		Set<String> set_RoleNames = new Set<String>{ USER_ROLE_NAME_SALES_SB_IB_XX };

		Map<String, Profile> map_Profiles = new Map<String, Profile>();
		Map<String, UserRole> map_UserRoles = new Map<String, UserRole>();
		List<User> list_Users = new List<User>();

		for (Profile objProfile : [SELECT Id, Name FROM Profile WHERE Name IN :set_ProfileNames]) {
			map_Profiles.put(objProfile.Name, objProfile);
		}

		for (UserRole objUserRole : [SELECT Id, Name FROM UserRole WHERE Name IN :set_RoleNames]) {
			map_UserRoles.put(objUserRole.Name, objUserRole);
		}

		User objSmallBizInboundUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(USER_PROFILE_NAME_SDR).Id)
			.setUserRoleId(map_UserRoles.get(USER_ROLE_NAME_SALES_SB_IB_XX).Id)
			.setUserName('testsbib@test.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testsbib@test.com')
			.setAlias('sbuser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();
		list_Users.add(objSmallBizInboundUser);

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objCurrentUser) {
			try {
				UserTriggerHelper.skipTrigger = true;
				insert list_Users;
				UserTriggerHelper.skipTrigger = false;
			} catch (Exception objException) {
				System.debug('Error occurred: ' + objException.getMessage());
			}
		}
		//create opportunity Benefits BoR
		Opportunity objBoROppty1 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objAccnt.Id)
			.setName('Test Opp 2')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setStage('SAL')
			.build();
		insert objBoROppty1;

		insert new List<App_URL_Map__c>{
			new TestDataFactory.AppURLMapBuilder().setAppName('Panda').setEnvironment('Dev').setURL('https://app.gusto-staging.com').build(),
			new TestDataFactory.AppURLMapBuilder().setAppName('Panda').setEnvironment('Prod').setURL('https://app.gusto.com').build()
		};
	}

	@isTest
	static void upsertTaskTest() {
		Task objTask = new TestDataFactory.TaskBuilder().setGenesysInteractionId('12312311213').build();

		try {
			InboundCallController.upsertTask(objTask, '9876543210', 'Email', 'Test Source');
		} catch (Exception objException) {
			System.debug('Error occurred: ' + objException.getMessage());
		}

		List<Task> list_Tasks = [SELECT Id FROM Task WHERE Genesys_Interaction_Id__c = '12312311213'];
		System.assert(list_Tasks.size() > 0, 'Task is not created');
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Lead is updated.
	 **/
	@isTest
	static void testUpdateLead() {
		Lead objLead = [SELECT Id FROM Lead WHERE Email = 'leadcampaign@member.com' LIMIT 1];
		Task objTask = new TestDataFactory.TaskBuilder().setGenesysInteractionId('12312311213').setWhoId(objLead.Id).setDescription('Test Description').build();

		try {
			InboundCallController.upsertTask(objTask, '9876543210', 'Email', 'Test Source');
		} catch (Exception objException) {
		}

		List<Task> list_Tasks = [SELECT Id FROM Task WHERE Genesys_Interaction_Id__c = '12312311213'];
		System.assert(list_Tasks.size() > 0, 'Task is not created');

		Lead objLeadAssert = [SELECT Id, MDR_Notes__c FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLeadAssert.MDR_Notes__c.startsWithIgnoreCase(InboundCallController.TASK_TYPE_INBOUND_CALL));

		checkForExceptions(false);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if exceptions are logged
	 **/
	@isTest
	static void testUpdateLeadException() {
		Lead objLead = [SELECT Id FROM Lead WHERE Email = 'leadcampaign@member.com' LIMIT 1];
		Task objTask = new TestDataFactory.TaskBuilder().setGenesysInteractionId('12312311213').setWhoId(objLead.Id).build();

		try {
			InboundCallController.blnTestDMLException = true;
			InboundCallController.upsertTask(objTask, '9876543210', 'Email', 'Test Source');
		} catch (Exception objException) {
		}

		List<Task> list_Tasks = [SELECT Id FROM Task WHERE Genesys_Interaction_Id__c = '12312311213'];
		System.assert(list_Tasks.size() > 0, 'Task is not created');

		checkForExceptions(true);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if Opportunity is updated.
	 **/
	@isTest
	static void testUpdateOpportunity() {
		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
		Task objTask = new TestDataFactory.TaskBuilder().setGenesysInteractionId('12312311213').setWhatId(objOpportunity.Id).setDescription('Test Description').build();

		try {
			InboundCallController.upsertTask(objTask, '9876543210', 'Email', 'Test Source');
		} catch (Exception objException) {
		}

		List<Task> list_Tasks = [SELECT Id FROM Task WHERE Genesys_Interaction_Id__c = '12312311213'];
		System.assert(list_Tasks.size() > 0, 'Task is not created');

		Opportunity objOpportunityAssert = [SELECT Id, Description FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assert(objOpportunityAssert.Description.startsWithIgnoreCase(InboundCallController.TASK_TYPE_INBOUND_CALL));

		checkForExceptions(false);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if exceptions are logged
	 **/
	@isTest
	static void testUpdateOpportunityException() {
		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
		Task objTask = new TestDataFactory.TaskBuilder().setGenesysInteractionId('12312311213').setWhatId(objOpportunity.Id).setDescription('Test Description').build();

		try {
			InboundCallController.blnTestDMLException = true;
			InboundCallController.upsertTask(objTask, '9876543210', 'Email', 'Test Source');
		} catch (Exception objException) {
		}

		List<Task> list_Tasks = [SELECT Id FROM Task WHERE Genesys_Interaction_Id__c = '12312311213'];
		System.assert(list_Tasks.size() > 0, 'Task is not created');

		checkForExceptions(true);
	}

	@isTest
	static void searchContactFirstNameTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('Test First Name1', '', '', '', '');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchContactLastNameTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('', 'Test Last Name1', '', '', '');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchContactFirstNameSpecialCharTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('Test First\' Name1', '', '', '', '');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchContactLastNameSpecialTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('', 'Test Last\' Name1', '', '', '');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchContactEmailTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('', '', '', '', 'newmember@campaign.com');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchContactCompanyTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('', '', 'Company Account 1', '', '');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchContactCompanySpecialTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('', '', 'Company \'s 2', '', '');
		System.assert(list_Contacts.size() == 0, 'Contact is found');
	}

	@isTest
	static void searchContactPhoneTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('', '', '', '9876543211', '');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchContactPhoneANDEmailTest() {
		List<Contact> list_Contacts = InboundCallController.searchContact('', '', '', '9876543211', 'newmember@campaign.com');
		System.assert(list_Contacts.size() > 0, 'Contact is not found');
	}

	@isTest
	static void searchLeadBasedFirstNameTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('FName', '', '', '', '');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}
	@isTest
	static void searchLeadBasedLastNameTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('', 'LName', '', '', '');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}

	@isTest
	static void searchLeadBasedCompanyTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('', '', 'Company Lead 1', '', '');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}
	@isTest
	static void searchLeadBasedPhoneTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('', '', '', '123456789', '');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}
	@isTest
	static void searchLeadBasedEmailTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('', '', '', '', 'leadcampaign@member.com');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}
	@isTest
	static void searchLeadBasedEmailAndPhoneTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('', '', '', '123456789', 'leadcampaign@member.com');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}

	@isTest
	static void searchLeadBasedFirstNameSpecialCharTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('FName \' Special', '', '', '', '');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}
	@isTest
	static void searchLeadBasedLastNameSpecialCharTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('', 'LName \' Special', '', '', '');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}

	@isTest
	static void searchLeadBasedCompanySpecialCharTest() {
		List<Lead> list_Leads = InboundCallController.searchLead('', '', 'Company \'s Lead 1', '', '');
		System.assert(list_Leads.size() > 0, 'Lead is not found');
	}

	@isTest
	static void getOpportunitiesTest() {
		Id accId = [SELECT Id FROM Account LIMIT 1].Id;
		List<Opportunity> list_Opportunites = InboundCallController.getOpportunities(accId);
		System.assert(list_Opportunites.size() > 0, 'Opp is not found');
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if a Case is created & transferred.
	 **/
	@isTest
	static void testTransferCase() {
		User objSOOBUser = [SELECT Id FROM User WHERE Email = 'testsbib@test.com'];
		Lead objLead;
		Task objTask;

		System.runAs(objSOOBUser) {
			objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('Test Company')
				.setLastName('Lead1')
				.setPhone('123456789')
				.setEmail('transfercase@lead.com')
				.setCompany('Company Lead 1')
				.setStatus(LeadUtil.LEAD_STATUS_AQL)
				.setLeadSource('LinkedIn')
				.build();

			LeadTriggerHelper.skipTrigger = true;
			insert objLead;
			LeadTriggerHelper.skipTrigger = false;

			Test.startTest();
			objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhoId(objLead.Id)
				.setStatus(TaskUtil.TASK_STATUS_VOICEMAIL)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
				.build();

			TaskTriggerHelper.skipTrigger = true;
			insert objTask;
			TaskTriggerHelper.skipTrigger = false;

			InboundCallController.transferCase(objTask.Id, InboundCallController.CASE_TYPE_SALES_CASES);

			Test.stopTest();
		}

		Task objTaskAssert = [SELECT Id, Case__c, Primary_Call_Reason__c FROM Task WHERE Id = :objTask.Id];
		System.assertNotEquals(null, objTaskAssert.Case__c);
		System.assertEquals(InboundCallController.TASK_PRIMARY_CALL_REASON_TRANSFER, objTaskAssert.Primary_Call_Reason__c);

		Case objCaseAssert = [SELECT Id, OwnerId, Lead__c FROM Case WHERE Id = :objTaskAssert.Case__c];
		System.assertEquals([SELECT Id FROM Group WHERE DeveloperName = :InboundCallController.QUEUE_SALES_CASE_QUEUE]?.Id, objCaseAssert.OwnerId);
		System.assertEquals(objLead.Id, objCaseAssert.Lead__c);

		checkForExceptions(false);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if exception is logged for Task.
	 **/
	@isTest
	static void testTransferCaseTaskException() {
		User objSOOBUser = [SELECT Id FROM User WHERE Email = 'testsbib@test.com'];
		Lead objLead;
		Task objTask;

		System.runAs(objSOOBUser) {
			objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('Test Company')
				.setLastName('Lead1')
				.setPhone('123456789')
				.setEmail('transfercase@lead.com')
				.setCompany('Company Lead 1')
				.setStatus(LeadUtil.LEAD_STATUS_AQL)
				.setLeadSource('LinkedIn')
				.build();

			LeadTriggerHelper.skipTrigger = true;
			insert objLead;
			LeadTriggerHelper.skipTrigger = false;

			Test.startTest();
			objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhoId(objLead.Id)
				.setStatus(TaskUtil.TASK_STATUS_VOICEMAIL)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
				.build();

			TaskTriggerHelper.skipTrigger = true;
			insert objTask;
			TaskTriggerHelper.skipTrigger = false;

			InboundCallController.blnTestTaskDMLException = true;
			InboundCallController.transferCase(objTask.Id, InboundCallController.CASE_TYPE_SALES_CASES);

			Test.stopTest();
		}

		checkForExceptions(true);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if exception is logged for Case.
	 **/
	@isTest
	static void testTransferCaseException() {
		User objSOOBUser = [SELECT Id FROM User WHERE Email = 'testsbib@test.com'];
		Lead objLead;
		Task objTask;

		System.runAs(objSOOBUser) {
			objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('Test Company')
				.setLastName('Lead1')
				.setPhone('123456789')
				.setEmail('transfercase@lead.com')
				.setCompany('Company Lead 1')
				.setStatus(LeadUtil.LEAD_STATUS_AQL)
				.setLeadSource('LinkedIn')
				.build();

			LeadTriggerHelper.skipTrigger = true;
			insert objLead;
			LeadTriggerHelper.skipTrigger = false;

			Test.startTest();
			objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhoId(objLead.Id)
				.setStatus(TaskUtil.TASK_STATUS_VOICEMAIL)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.setSubject(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
				.build();

			TaskTriggerHelper.skipTrigger = true;
			insert objTask;
			TaskTriggerHelper.skipTrigger = false;

			InboundCallController.blnTestCaseDMLException = true;
			InboundCallController.transferCase(objTask.Id, InboundCallController.CASE_TYPE_SALES_CASES);

			Test.stopTest();
		}

		checkForExceptions(true);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if exceptions are logged
	 **/
	public static void checkForExceptions(Boolean blnHasException) {
		// Assert exceptions are logged from Task Trigger
		Integer intExceptions = [SELECT COUNT() FROM Exception_Log__c WHERE Class_Name__c = 'InboundCallController'];

		if (blnHasException) {
			System.assertNotEquals(0, intExceptions);
		} else {
			System.assertEquals(0, intExceptions);
		}
	}

	/**
	 * @author Lalitha Kasturi
	 * @description test coverage for getCases
	 */
	@isTest
	public static void test_getCases() {
		Contact objContact = [SELECT Id FROM Contact WHERE Phone = '9876543211' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases')
			.setSubject('Test Case for Inbound call controller')
			.setOrigin('Phone')
			.setStatus('New')
			.setDescription('Test Case for Inbound call controller')
			.setContactReason('Transfer')
			.setSubContactReason('Other')
			.setContactId(objContact.Id)
			.build();

		insert objCase;

		List<Case> list_Cases = InboundCallController.getCases('9876543211');
		System.assert(list_Cases.size() > 0);
		System.assertEquals(list_Cases[0].RecordTypeId, CaseUtils.RECTYPE_SALES_CASES);
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test if Task is auto linked to Lead if only 1 matching lead is found
	 **/
	@isTest
	static void autoLinkTaskToLeadTest() {
		Task objTask = new TestDataFactory.TaskBuilder().setGenesysInteractionId('12312311213').build();

		Lead objLead = [SELECT Id, Phone FROM Lead WHERE Phone = '7898787868'];

		Test.startTest();
		// lead with matching number (9876543211) is inserted in testSetup method
		InboundCallController.upsertTask(objTask, objLead.Phone, 'Email', 'Test Source');
		Test.stopTest();

		// Assert if WhoId is set on Task
		Task objTaskAssert = [SELECT Id, WhoId FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objLead.Id, objTaskAssert.WhoId, 'Activity Who Id is not auto linked on insert');
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Test if Task is auto linked to Contact if only 1 matching contact is found
	 **/
	@isTest
	static void autoLinkTaskToContactTest() {
		// create new instance of task
		Task objTask = new TestDataFactory.TaskBuilder().setGenesysInteractionId('12312311213').build();

		Contact objContact = [SELECT Id, AccountId, Phone FROM Contact WHERE Phone = '9876543211'];

		Test.startTest();
		// contact with matching number (9876543211) is inserted in testSetup method
		InboundCallController.upsertTask(objTask, objContact.Phone, 'Email', 'Test Source');
		Test.stopTest();

		// Assert if What Id and Who Id are set on Task
		Task objTaskAssert = [SELECT Id, WhoId, WhatId FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(objContact.Id, objTaskAssert.WhoId, 'Activity Who Id is not auto linked on insert');
		System.assertEquals(objContact.AccountId, objTaskAssert.WhatId, 'Activity What Id is not auto linked on insert');
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if there are any App_URL_Map records.
	 **/
	@isTest
	static void testGetAppUrlMaps() {
		List<App_URL_Map__c> list_App_URLs = InboundCallController.getAppUrlMaps();
		System.assert(!list_App_URLs.isEmpty());
	}

	/**
	 * @description  Test positive and negative scenario of getting sales interaction records
	 **/
	@isTest
	static void testGetSalesInteraction() {
		Sales_Interaction__c objInteraction = new Sales_Interaction__c(DNIS__c = '1234567890', ANI__c = '1234567890', CCID__c = '1234567890');
		insert objInteraction;

		Test.startTest();
		// Test positive scenario
		Sales_Interaction__c objAssert = InboundCallController.querySalesInteraction(objInteraction.Id);
		System.assertEquals(objInteraction.Id, objAssert.Id, 'Sales Interaction query unsuccessful');

		// Test negative scenario
		Sales_Interaction__c objAsser2 = InboundCallController.querySalesInteraction(null);
		System.assertEquals(null, objAsser2, 'Sales Interaction is not null');
		Test.stopTest();
	}
}