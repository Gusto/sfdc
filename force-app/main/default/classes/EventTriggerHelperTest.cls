@isTest
private class EventTriggerHelperTest {
	@testSetup
	static void setup() {
		Test.startTest();
		Set<String> set_ProfileNames = new Set<String>{ TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR };
		Map<String, Profile> map_Profiles = new Map<String, Profile>();
		for (Profile objProfile : [SELECT Id, Name FROM Profile WHERE Name IN :set_ProfileNames]) {
			map_Profiles.put(objProfile.Name, objProfile);
		}

		User objPartnerAEUser = new TestDataFactory.UserBuilder()
			.setAlias('partae')
			.setEmail('partnerae@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test User')
			.setLastName('Partner AE')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('partnerae@testorg.com')
			.build();

		objPartnerAEUser.Exempt_from_Validation_Rules__c = true;
		objPartnerAEUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName LIKE :AccountUtil.SALES_PARTNER_AE_ROLE][0].Id;
		objPartnerAEUser.IsActive = true;

		User objSalesMDRUser = new TestDataFactory.UserBuilder()
			.setAlias('salesmdr')
			.setEmail('salesmdr@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test User')
			.setLastName('Sales MDR')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('salesmdr@testorg.com')
			.build();

		objSalesMDRUser.Exempt_from_Validation_Rules__c = true;
		objSalesMDRUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName LIKE :AccountUtil.SALES_MDR_MGR_ROLE][0].Id;

		User objIntegrationUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(UserInfo.getProfileId())
			.setUserName('sfdc+chilipiper@testorg.com')
			.setFirstName('')
			.setLastName('ChiliPiper')
			.setEmail('sfdc+chilipiper@testorg.com')
			.setAlias('chil')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setCalendarLink('testCalendarLink')
			.build();

		objIntegrationUser.Exempt_from_Validation_Rules__c = true;
		objIntegrationUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = :'Integration_Users'][0].Id;

		User objSysAdminUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_Profiles.get(TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR).Id)
			.setUserRoleId(TaskUtil.USER_ROLE_ID_EXEC)
			.setUserName('testsysadmin@testevent.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testsysadmin@testevent.com')
			.setAlias('sdevnt')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		User objcurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objcurrentUser) {
			insert new List<User>{ objPartnerAEUser, objSalesMDRUser, objIntegrationUser, objSysAdminUser };
		}

		AccountTriggerHelper.skipTrigger = true;
		Account objResellerAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account').setOwnerId(objPartnerAEUser.Id).build();
		insert objResellerAccnt;

		Account objResellerAccnt2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account 2').setOwnerId(objSalesMDRUser.Id).build();
		insert objResellerAccnt2;

		Account objCompanyAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();
		insert objCompanyAccnt;
		AccountTriggerHelper.skipTrigger = false;

		List<Contact> list_contactsToInsert = new List<Contact>();
		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objCompanyAccnt.Id)
			.setFirstName('Test Company')
			.setLastName('Contact 1')
			.setPhone('1234561234')
			.setEmail('newcontact1@task.com')
			.setNormalizedPhone('1234561234')
			.build();
		list_contactsToInsert.add(objCompanyContact);

		Contact objResellerContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.RESELLER_RT_NAME)
			.setAccountId(objResellerAccnt.Id)
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

		Opportunity objCompanyOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setAccountId(objCompanyAccnt.Id)
			.setName('Test Company')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.build();
		insert objCompanyOpportunity;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testLead1@gusto.com')
			.setPhone('123456789')
			.setCompany('Test Lead')
			.setLeadSource('LinkedIn')
			.build();
		insert objLead;

		TicketTriggerHelper.skipTrigger = true;
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_CALC_APPROVAL_PENDING)
			.build();
		insert objTicket;
		Test.stopTest();
	}

	@isTest
	static void eventWhatIdOpptyOwnerIdUpdateTest() {
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :Userinfo.getUserId()];
		User objMDRUser = [SELECT Id, Name, Exempt_from_Validation_Rules__c FROM User WHERE UserRole.Name = 'sales_sdr_partner_mgr_xx' AND IsActive = TRUE LIMIT 1];
		Contact objContact;
		Opportunity objOppty;

		System.runAs(objCurrentUser) {
			objMDRUser.Exempt_from_Validation_Rules__c = true;
			update objMDRUser;

			TriggerHandler.bypass('OpportunityTriggerHandler');
			objOppty = TestUtility.BenefitsNewPlanOpportunity();
			TriggerHandler.clearBypass('OpportunityTriggerHandler');

			objContact = new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(objOppty.AccountId)
				.setFirstName('First')
				.setLastName('EventContact')
				.setEmail('TestEvent@gusto.com')
				.build();
			insert objContact;

			insert new OpportunityContactRole(ContactId = objContact.Id, OpportunityId = objOppty.Id);
		}

		System.runAs(objMDRUser) {
			Test.startTest();
			System.assertEquals(objCurrentUser.Id, objOppty.OwnerId, 'Oppty Owner Id does not match');

			TriggerHandler.bypass('AccountTriggerHandler');
			TriggerHandler.bypass('ContactTriggerHandler');
			insert new TestDataFactory.EventBuilder()
				.setWhoId(objContact.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(objMDRUser.Id)
				.setSubject('Event Trigger Test')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setType('Meeting')
				.setMeetingType(EventUtil.HI_OPPTY_NEW_PLAN)
				.build();

			objOppty = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :objOppty.Id];
			System.assertEquals(objMDRUser.Id, objOppty.OwnerId, 'Oppty Owner Id does not match');
			Test.stopTest();
		}
	}

	@isTest
	static void testAccActivityFields() {
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :Userinfo.getUserId()];
		User objSalesUser = [SELECT Id, Name, Exempt_from_Validation_Rules__c FROM User WHERE UserRole.Name = 'sales_sdr_partner_mgr_xx' AND IsActive = TRUE LIMIT 1];

		Account objAcc;
		System.runAs(objCurrentUser) {
			objSalesUser.Exempt_from_Validation_Rules__c = true;
			update objSalesUser;

			objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('1111111111').build();
			insert objAcc;

			Test.startTest();
			objAcc = [SELECT Id, Last_Rep_Activity_Date_New__c FROM Account WHERE Id = :objAcc.Id];
			System.assertEquals(null, objAcc.Last_Rep_Activity_Date_New__c, 'Last Rec Activity Date is not null');

			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhatId(objAcc.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(objSalesUser.Id)
				.setSubject('Event Trigger Test')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setType('Demo')
				.setMeetingType(EventUtil.PAYROLL_ONLY_DEMO)
				.build();
			objEvent.Event_Status__c = 'Connect';
			TriggerHandler.bypass('AccountTriggerHandler');
			insert objEvent;

			Test.stopTest();
		}

		objAcc = [SELECT Id, Last_Rep_Activity_Date_New__c FROM Account WHERE Id = :objAcc.Id];
		System.assertNotEquals(null, objAcc.Last_Rep_Activity_Date_New__c, 'Last Rec Activity Date is not set');
	}

	@isTest
	static void testLeadActivityFields() {
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :Userinfo.getUserId()];
		User objSalesUser = [SELECT Id, Name, Exempt_from_Validation_Rules__c FROM User WHERE UserRole.Name = 'sales_sdr_partner_mgr_xx' AND IsActive = TRUE LIMIT 1];

		Lead objLead;
		System.runAs(objCurrentUser) {
			objSalesUser.Exempt_from_Validation_Rules__c = true;
			update objSalesUser;

			TriggerHandler.bypass('LeadTriggerHandler');
			objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.LABEL_COMPANY)
				.setFirstName('testname')
				.setLastName('test')
				.setEmail('Email@email.com')
				.setStatus('MQL')
				.setCompany('test company')
				.setLeadSource('LinkedIn')
				.build();
			insert objLead;
			TriggerHandler.clearBypass('LeadTriggerHandler');

			Test.startTest();
			objLead = [SELECT Id, OwnerId, Last_Rep_Activity_Date_New__c FROM Lead WHERE Id = :objLead.Id];
			System.assertEquals(objCurrentUser.Id, objLead.OwnerId, 'Lead Owner does not match');
			System.assertEquals(null, objLead.Last_Rep_Activity_Date_New__c, 'Last Rec Activity Date is not null');

			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhoId(objLead.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(objSalesUser.Id)
				.setSubject('Event Trigger Test')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setType('Demo')
				.setMeetingType(EventUtil.PAYROLL_ONLY_DEMO)
				.build();
			objEvent.Event_Status__c = 'Connect';
			objEvent.Queue_Name_CP__c = 'MDR';
			TriggerHandler.bypass('AccountTriggerHandler');
			insert objEvent;
			Test.stopTest();
		}

		objLead = [SELECT Id, OwnerId, Lead_Owner_Change__c, Last_Rep_Activity_Date_New__c FROM Lead WHERE Id = :objLead.Id];
		System.assert(objLead.Lead_Owner_Change__c, 'Lead Owner is not changed');
		System.assertEquals(objSalesUser.Id, objLead.OwnerId, 'Lead Owner does not match');
		System.assertNotEquals(null, objLead.Last_Rep_Activity_Date_New__c, 'Last Rec Activity Date is not set');
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Test Account Owner and Status changes when ChiliPiper books an event
	 * @Param       : void
	 * @Return      : void
	 **/
	@isTest
	static void testChilipiperScheduleACallEvtAutomation() {
		Account objAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Owner.UserRole.Name = :AccountUtil.SALES_PARTNER_AE_ROLE];
		Account objAccount2 = [SELECT Id, Name, OwnerId FROM Account WHERE Owner.UserRole.Name = :AccountUtil.SALES_MDR_MGR_ROLE];
		User objUser = [SELECT Id, Name, Email, UserName FROM User WHERE UserName = 'sfdc+chilipiper@testorg.com'];
		User objMDRUser = [SELECT Id, Name, Email, UserName FROM User WHERE UserRole.Name = :AccountUtil.SALES_MDR_MGR_ROLE AND IsActive = TRUE][0];
		User objPartnerAEUser = [SELECT Id, Name, Email, UserName FROM User WHERE UserRole.Name = :AccountUtil.SALES_PARTNER_AE_ROLE AND IsActive = TRUE][0];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Reseller')
			.setAccountId(objAccount2.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@secondcontact.com')
			.build();
		insert objContact;

		Test.StartTest();
		Event objEvent1 = new TestDataFactory.EventBuilder()
			.setWhatId(objAccount.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(objPartnerAEUser.Id)
			.setBookedBy(objUser.Id)
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType(EventUtil.PITCH_TYPE)
			.build();
		objEvent1.Meeting_Type_CP__c = EventUtil.MEETING_TYPE;
		insert objEvent1;

		Event objEvent2 = new TestDataFactory.EventBuilder()
			.setWhatId(objAccount2.Id)
			.setWhoId(objContact.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(objMDRUser.Id)
			.setBookedBy(objUser.Id)
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType(EventUtil.PITCH_TYPE)
			.build();
		objEvent2.Meeting_Type_CP__c = EventUtil.MEETING_TYPE;
		insert objEvent2;
		Test.StopTest();

		Account objAccountAssert = [SELECT Id, Sales_Engagement_Status__c, Sales_Engagement_Status_Detail__c, OwnerId FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objPartnerAEUser.Id, objAccountAssert.OwnerId, 'Account Owner does not match');

		Account objAccountAssert2 = [SELECT Id, Sales_Engagement_Status__c, OwnerId, Sales_Engagement_Status_Detail__c FROM Account WHERE Id = :objAccount2.Id];
		System.assertEquals(objMDRUser.Id, objAccountAssert2.OwnerId, 'Account Owner does not match');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test New Plan Chilipiper event gets attached to the most recently created New plan Opportunity
	 * @Param       : void
	 * @Return      : void
	 **/
	@isTest
	static void testChiliPiperNewPlanOpptyMeetingType() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		User objMDRUser = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sdr_partner_mgr_xx' AND IsActive = TRUE LIMIT 1];

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account Old Owner').setZPCompanyId('111111433111').build();
		insert objCompanyAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('test@oppcontactrole.com')
			.build();
		insert objContact;

		Opportunity objNewPlanOppty1 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setStage('SAL')
			.build();
		objNewPlanOppty1.OwnerId = objMDRUser.Id;
		insert objNewPlanOppty1;
		// set created date of first opportunity as yesterday
		Test.setCreatedDate(objNewPlanOppty1.Id, DateTime.now().addDays(-1));

		Opportunity objNewPlanOppty2 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Opp 2')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setStage('SAL')
			.build();
		objNewPlanOppty2.OwnerId = objMDRUser.Id;
		insert objNewPlanOppty2;

		OpportunityContactRole objOpportunityContactRole1 = new TestDataFactory.OpportunityContactRoleBuilder()
			.setContactId(objContact.Id)
			.setOpportunityId(objNewPlanOppty2.Id)
			.setRole('Benefits Admin')
			.build();
		insert objOpportunityContactRole1;

		OpportunityContactRole objOpportunityContactRole2 = new TestDataFactory.OpportunityContactRoleBuilder()
			.setContactId(objContact.Id)
			.setOpportunityId(objNewPlanOppty1.Id)
			.setRole('Benefits Admin')
			.build();
		insert objOpportunityContactRole2;

		Test.startTest();
		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhoId(objContact.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Meeting')
			.build();
		objEvent.Meeting_Type_CP__c = EventUtil.HI_OPPTY_NEW_PLAN;
		insert objEvent;
		Test.stopTest();

		Event objEventAssert = [SELECT Id, WhoId, WhatId, Type FROM Event WHERE Id = :objEvent.Id];

		// Assert event got associated with most recently created new plan opportunity
		System.assertEquals(objContact.Id, objEventAssert.WhoId, 'WhoId not set to Contact');
		System.assertEquals(objNewPlanOppty2.Id, objEventAssert.WhatId, 'WhatId not set to Oppty');
		System.assertEquals(EventUtil.PITCH_TYPE, objEventAssert.Type, 'Type does not match');

		// Assert owner id of first new plan opportunity was not changed
		Opportunity objNewPlanOppty1Assert = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :objNewPlanOppty1.Id];
		System.assertEquals(objMDRUser.Id, objNewPlanOppty1Assert.OwnerId, 'Oppty Owner does not match');

		// Assert owner id of second new plan opportunity was changed
		Opportunity objNewPlanOppty2Assert = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :objNewPlanOppty2.Id];
		System.assertEquals(UserInfo.getUserId(), objNewPlanOppty2Assert.OwnerId, 'Oppty Owner does not match');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test BoR Chilipiper event gets attached to the most recently created BoR Opportunity
	 * @Param       : void
	 * @Return      : void
	 **/
	@isTest
	static void testChiliPiperBoROpptyMeetingType() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		User objMDRUser = [SELECT Id, Name FROM User WHERE UserRole.Name = 'sales_sdr_partner_mgr_xx' AND IsActive = TRUE LIMIT 1];

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account Old Owner').setZPCompanyId('111111433111').build();
		insert objCompanyAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('test@oppcontactrole.com')
			.build();
		insert objContact;

		Opportunity objBoROppty1 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setStage('SAL')
			.build();
		objBoROppty1.OwnerId = objMDRUser.Id;
		insert objBoROppty1;
		// set created date of first opportunity as yesterday
		Test.setCreatedDate(objBoROppty1.Id, DateTime.now().addDays(-1));

		Opportunity objBoROppty2 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Opp 2')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setStage('SAL')
			.build();
		objBoROppty2.OwnerId = objMDRUser.Id;
		insert objBoROppty2;

		OpportunityContactRole objOpportunityContactRole1 = new TestDataFactory.OpportunityContactRoleBuilder()
			.setContactId(objContact.Id)
			.setOpportunityId(objBoROppty2.Id)
			.setRole('Benefits Admin')
			.build();
		insert objOpportunityContactRole1;

		OpportunityContactRole objOpportunityContactRole2 = new TestDataFactory.OpportunityContactRoleBuilder()
			.setContactId(objContact.Id)
			.setOpportunityId(objBoROppty1.Id)
			.setRole('Benefits Admin')
			.build();
		insert objOpportunityContactRole2;

		Test.startTest();
		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhoId(objContact.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Meeting')
			.build();
		objEvent.Meeting_Type_CP__c = EventUtil.HI_OPPTY_BOR;
		insert objEvent;
		Test.stopTest();

		Event objEventAssert = [SELECT Id, WhoId, WhatId, What.Name FROM Event WHERE Id = :objEvent.Id];

		// Assert event got associated with most recently created BoR opportunity
		System.assertEquals(objContact.Id, objEventAssert.WhoId, 'WhoId not set to Contact');
		System.assertEquals(objBoROppty2.Id, objEventAssert.WhatId, 'WhatId not set to Oppty');

		// Assert owner id of BoR opportunity was not changed
		Opportunity objBoROppty1Assert = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :objBoROppty1.Id];
		System.assertEquals(objMDRUser.Id, objBoROppty1Assert.OwnerId, 'Oppty Owner does not match');

		// Assert owner id of second BoR opportunity was changed
		Opportunity objBoROppty2Assert = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :objBoROppty2.Id];
		System.assertEquals(UserInfo.getUserId(), objBoROppty2Assert.OwnerId, 'Oppty Owner does not match');
	}

	/**
	 * @Author      : Ajay Krishna PU
	 * @Description : Test Populate Last Activity Date on Ticket object
	 * @Param       : void
	 * @Return      : void
	 **/
	@isTest
	static void testPopulateLastActivityDateOnTicket() {
		User objAdminUser = [SELECT Id FROM USER WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Test.startTest();

			TicketTriggerHelper.skipTrigger = true;
			Ticket__c objTicket = new TestDataFactory.TicketBuilder().setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius')).setOwnerId(UserInfo.getUserId()).build();
			insert objTicket;
			TicketTriggerHelper.skipTrigger = false;

			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhatId(objTicket.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(UserInfo.getUserId())
				.setSubject('Test Event')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setType('Meeting')
				.build();
			objEvent.Meeting_Type_CP__c = EventUtil.HI_OPPTY_BOR;
			insert objEvent;
			Test.stopTest();

			objTicket = [SELECT Id, Last_Activity_Date__c FROM Ticket__c WHERE Id = :objTicket.Id];
			System.assert(objTicket.Last_Activity_Date__c != null, 'PopulateLateActivityDate failed, Last Activity not populated on Insert');

			objTicket.Last_Activity_Date__c = null;
			update objTicket;

			objEvent.Subject = 'Test Event updated';
			update objEvent;

			objTicket = [SELECT Id, Last_Activity_Date__c FROM Ticket__c WHERE Id = :objTicket.Id];
			System.assert(objTicket.Last_Activity_Date__c != null, 'PopulateLateActivityDate failed, Last Activity not populated on Update');
		}
	}

	/**
	 * @see EventTriggerHelper.populateActivityDatesOnAccLead
	 * @description Test if Last Activity Date is updated on the Reseller Account when a non connect meeting Event is created/updated on the company Account
	 **/
	@isTest
	static void onAccountEvent_testLastActivityDateUpdateOnResellerAccount() {
		Account objCompanyAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];
		objCompanyAccount.Sold_By__c = objResellerAccount.Id;
		update objCompanyAccount;

		System.runAs(objSalesUser) {
			Test.startTest();

			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhatId(objCompanyAccount.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(UserInfo.getUserId())
				.setSubject('Test Event')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setType('Meeting')
				.setEventStatus('Connect')
				.build();
			insert objEvent;

			Account objResellerAccountAssert = [SELECT Id, Last_Activity_Date__c, Last_Call_Connect__c FROM Account WHERE Id = :objResellerAccount.Id];
			Event objEventAssert = [SELECT Id, ActivityDate FROM Event WHERE Id = :objEvent.Id];
			System.assertEquals(objEventAssert.ActivityDate, objResellerAccountAssert.Last_Activity_Date__c);
			System.assertEquals(objEventAssert.ActivityDate, objResellerAccountAssert.Last_Call_Connect__c);

			Test.stopTest();
		}
	}

	/**
	 * @see EventTriggerHelper.populateActivityDatesOnAccLead
	 * @description Test if Last Activity Date is updated on the Reseller Account when a non connect meeting Event is created/updated on the company opportunity
	 **/
	@isTest
	static void onOpportunityEvent_testLastActivityDateUpdateOnResellerAccount() {
		Account objCompanyAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];
		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID AND AccountId = :objCompanyAccount.Id LIMIT 1];
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];
		objCompanyAccount.Sold_By__c = objResellerAccount.Id;
		update objCompanyAccount;

		System.runAs(objSalesUser) {
			Test.startTest();

			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhatId(objOpportunity.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(UserInfo.getUserId())
				.setSubject('Test Event')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(2))
				.setType('Meeting')
				.setEventStatus('Connect')
				.build();
			insert objEvent;

			Account objResellerAccountAssert = [SELECT Id, Last_Activity_Date__c, Last_Call_Connect__c FROM Account WHERE Id = :objResellerAccount.Id];
			Event objEventAssert = [SELECT Id, ActivityDate FROM Event WHERE Id = :objEvent.Id];
			System.assertEquals(objEventAssert.ActivityDate, objResellerAccountAssert.Last_Activity_Date__c);
			System.assertEquals(objEventAssert.ActivityDate, objResellerAccountAssert.Last_Call_Connect__c);

			Test.stopTest();
		}
	}

	/**
	 * @see EventTriggerHelper.populateActivityDatesOnAccLead
	 * @description Test if Last Activity Date is updated on the Reseller Account when a non connect meeting Event is created/updated on the company contact
	 **/
	@isTest
	static void onContactEvent_testLastActivityDateUpdateOnResellerAccount() {
		Account objCompanyAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objResellerAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];
		Contact objContact = [SELECT Id, Phone FROM Contact WHERE RecordTypeId = :ContactUtil.RESELLER_CONTACT_RT_ID LIMIT 1];
		User objSalesUser = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name LIKE '%sales%' LIMIT 1];
		objCompanyAccount.Sold_By__c = objResellerAccount.Id;
		update objCompanyAccount;

		System.runAs(objSalesUser) {
			Test.startTest();

			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhoId(objContact.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(UserInfo.getUserId())
				.setSubject('Test Event')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(3))
				.setType('Meeting')
				.setEventStatus('Connect')
				.build();
			insert objEvent;

			Account objResellerAccountAssert = [SELECT Id, Last_Activity_Date__c, Last_Call_Connect__c FROM Account WHERE Id = :objResellerAccount.Id];
			Event objEventAssert = [SELECT Id, ActivityDate FROM Event WHERE Id = :objEvent.Id];
			Contact objContactAssert = [SELECT Id, Last_Contact_Activity__c, Last_Contact_Connect__c FROM Contact WHERE Id = :objContact.Id];
			System.assertEquals(objEventAssert.ActivityDate, objResellerAccountAssert.Last_Activity_Date__c);
			System.assertEquals(objEventAssert.ActivityDate, objResellerAccountAssert.Last_Call_Connect__c);
			System.assertEquals(objEventAssert.ActivityDate, objContactAssert.Last_Contact_Activity__c);
			System.assertEquals(objEventAssert.ActivityDate, objContactAssert.Last_Contact_Connect__c);

			Test.stopTest();
		}
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Unit Test for No Show Updates
	 **/
	@isTest
	static void testEventNoShowTest() {
		User objAdminUser = [SELECT Id FROM USER WHERE UserRoleId = :TaskUtil.USER_ROLE_ID_EXEC AND IsActive = TRUE LIMIT 1];

		System.runAs(objAdminUser) {
			Event objEvent = new TestDataFactory.EventBuilder()
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(objAdminUser.Id)
				.setBookedBy(objAdminUser.Id)
				.setSubject('Event Trigger Test')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setEventStatus('Attempt')
				.setType('Demo')
				.build();
			objEvent.No_Show_CP__c = true;
			insert objEvent;

			Test.startTest();
			objEvent = [SELECT Id, Event_Status__c, No_Show_CP__c FROM Event WHERE Id = :objEvent.Id];
			objEvent.Event_Status__c = 'Scheduled';
			update objEvent;

			objEvent = [SELECT Id, Event_Status__c, No_Show_CP__c FROM Event WHERE Id = :objEvent.Id];
			System.assertEquals(false, objEvent.No_Show_CP__c, 'No Show not updated');

			objEvent.No_Show_CP__c = true;
			objEvent.Event_Status__c = 'Attempt';
			update objEvent;

			objEvent = [SELECT Id, Event_Status__c, No_Show_CP__c FROM Event WHERE Id = :objEvent.Id];
			System.assertEquals(true, objEvent.No_Show_CP__c, 'No Show not updated');

			objEvent.No_Show_CP__c = false;
			update objEvent;

			objEvent = [SELECT Id, Event_Status__c, No_Show_CP__c FROM Event WHERE Id = :objEvent.Id];
			System.assertEquals(null, objEvent.Event_Status__c, 'Event Status not updated');
			Test.stopTest();
		}
	}

	/**
	 * @author      Debasmita
	 * @description Test if Last Call Connect is updated on Account when event is created on Account
	 **/
	@isTest
	static void testLastCallConnectUpdateOnAccount() {
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhatId(objAccount.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Meeting')
			.build();
		insert objEvent;

		Test.startTest();
		// set call status as connect and update activity date
		objEvent.Event_Status__c = EventUtil.STATUS_CONNECT;
		objEvent.ActivityDate = Date.today();
		update objEvent;

		Test.stopTest();

		// query task, account & opportunity
		Event objEventAssert = [SELECT Id, ActivityDate, Owner.Name FROM Event WHERE Id = :objEvent.Id];
		Account objAccountAssert = [SELECT Id, Last_Call_Connect__c FROM Account WHERE Id = :objAccount.Id];

		// assert last call connect on account and opportunity got updated
		System.assertEquals(objEventAssert.ActivityDate, objAccountAssert.Last_Call_Connect__c, 'Last Call Connect on Account not updated.');
	}

	/**
	 * @author      Debasmita
	 * @description Test if Last Call Connect is updated on Opportunity, Account Last Call Connect is also updated
	 **/
	@isTest
	static void testLastCallConnectUpdateOnOpportunity() {
		Opportunity objOppty = [SELECT Id FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID LIMIT 1];

		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhatId(objOppty.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Meeting')
			.build();
		insert objEvent;

		Test.startTest();
		// set call status as connect and update activity date
		objEvent.Event_Status__c = EventUtil.STATUS_CONNECT;
		objEvent.ActivityDate = Date.today();
		update objEvent;

		Test.stopTest();

		// query task, account & opportunity
		Event objEventAssert = [SELECT Id, ActivityDate, Owner.Name FROM Event WHERE Id = :objEvent.Id];
		Opportunity objOpptyAssert = [SELECT Id, AccountId, Last_Call_Connect__c FROM Opportunity WHERE Id = :objOppty.Id];
		Account objAccountAssert = [SELECT Id, Last_Call_Connect__c FROM Account WHERE Id = :objOpptyAssert.AccountId];

		// assert last call connect on account and opportunity got updated
		System.assertEquals(objEventAssert.ActivityDate, objAccountAssert.Last_Call_Connect__c, 'Last Call Connect on Account not updated.');
		System.assertEquals(objEventAssert.ActivityDate, objOpptyAssert.Last_Call_Connect__c, 'Last Call Connect on Opportunity not updated.');
	}

	/**
	 * @author      Debasmita
	 * @description Test if Last Call Connect is updated on Account when event is created on related Contact
	 **/
	@isTest
	static void testLastCallConnectUpdateOnAccountFromContact() {
		Contact objContact = [SELECT ID, AccountId FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];

		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhoId(objContact.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Meeting')
			.build();
		insert objEvent;

		Test.startTest();
		// set call status as connect and update activity date
		objEvent.Event_Status__c = EventUtil.STATUS_CONNECT;
		objEvent.ActivityDate = Date.today();
		update objEvent;

		Test.stopTest();

		// query task, account & opportunity
		Event objEventAssert = [SELECT Id, ActivityDate, Owner.Name FROM Event WHERE Id = :objEvent.Id];
		Account objAccountAssert = [SELECT Id, Last_Call_Connect__c FROM Account WHERE Id = :objContact.AccountId];

		// assert last call connect on related account updated
		System.assertEquals(objEventAssert.ActivityDate, objAccountAssert.Last_Call_Connect__c, 'Last Call Connect on Account not updated.');
	}

	/**
	 * @author      Debasmita
	 * @description Test if Last Call Connect is updated on Lead when event is created on related Lead
	 **/
	@isTest
	static void testLastCallConnectUpdateOnLead() {
		Lead objLead = [SELECT ID FROM Lead LIMIT 1];

		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhoId(objLead.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Meeting')
			.build();
		insert objEvent;

		Test.startTest();
		// set call status as connect and update activity date
		objEvent.Event_Status__c = EventUtil.STATUS_CONNECT;
		objEvent.ActivityDate = Date.today();
		update objEvent;

		Test.stopTest();

		// query task, account & opportunity
		Event objEventAssert = [SELECT Id, ActivityDate, Owner.Name FROM Event WHERE Id = :objEvent.Id];
		Lead objLeadAssert = [SELECT Id, Last_Call_Connect__c FROM Lead WHERE Id = :objLead.Id];

		// assert last call connect on related account updated
		System.assertEquals(objEventAssert.ActivityDate, objLeadAssert.Last_Call_Connect__c, 'Last Call Connect on Lead not updated.');
	}

	/**
	 * @author      Ajay Krishna P U
	 * @description Test Populate Ticket Status On Ardius Ticket related Event creation
	 **/
	@isTest
	static void testPopulateTicketStatusOnEventCreation() {
		List<Ticket__c> list_Tickets = [SELECT Id, Status__c FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Invalid test data - Ticket');

		Ticket__c objTicket = list_Tickets[0];
		String strInitialTicketStatus = objTicket.Status__c;

		Test.startTest();
		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhatId(objTicket.Id)
			.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setSubject('Test Event')
			.setDescription('Test Description')
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Meeting')
			.build();
		insert objEvent;

		//On Creation of event - Ticket Status should populate
		Event objEventAssert = [SELECT Id, Ticket_Status__c FROM Event WHERE Id = :objEvent.Id];
		System.assert(strInitialTicketStatus == objEventAssert.Ticket_Status__c, 'Ticket Status on event object not populated.');

		//On Updation of Ticket - No Ticket Status Change
		objTicket.Status__c = TicketUtil.TICKET_STATUS_REPORT_CREATION;
		update objTicket;
		objEventAssert = [SELECT Id, Ticket_Status__c FROM Event WHERE Id = :objEvent.Id];
		System.assert(strInitialTicketStatus == objEventAssert.Ticket_Status__c, 'Ticket Status should not be updated on Ticket change.');
		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test if Closed_Owenr_Role__c is getting updated on event creation
	 **/
	@isTest
	static void testSetClosedOwnerRoleInsert() {
		Account objAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Owner.UserRole.Name = :AccountUtil.SALES_PARTNER_AE_ROLE];
		User objMDRUser = [SELECT Id, Name, Email, UserName, UserRole.Name FROM User WHERE UserRole.Name = :AccountUtil.SALES_MDR_MGR_ROLE AND IsActive = TRUE][0];

		System.runAs(objMDRUser) {
			Test.startTest();
			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhatId(objAccount.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(UserInfo.getUserId())
				.setSubject('Test Event')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setType('Meeting')
				.setEventStatus(EventUtil.STATUS_SCHEDULED)
				.build();
			insert objEvent;

			//On Creation of event - Ticket Status should populate
			Event objEventAssert = [SELECT Id, Event_Status__c, Closed_Owner_Role__c FROM Event WHERE Id = :objEvent.Id LIMIT 1];
			System.assertEquals(objMDRUser.UserRole.Name, objEventAssert.Closed_Owner_Role__c, 'Closed Owner Role did not get updated with owner role.');
			Test.stopTest();
		}
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test if Closed_Owenr_Role__c is getting updated on event creation
	 **/
	@isTest
	static void testSetClosedOwnerRoleUpdate() {
		Account objAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Owner.UserRole.Name = :AccountUtil.SALES_PARTNER_AE_ROLE];
		User objMDRUser = [SELECT Id, Name, Email, UserName, UserRole.Name FROM User WHERE UserRole.Name = :AccountUtil.SALES_MDR_MGR_ROLE AND IsActive = TRUE][0];

		System.runAs(objMDRUser) {
			Test.startTest();
			Event objEvent = new TestDataFactory.EventBuilder()
				.setWhatId(objAccount.Id)
				.setRecordTypeId(EventUtil.AE_DEMO_EVENT_RT_ID)
				.setOwnerId(UserInfo.getUserId())
				.setSubject('Test Event')
				.setDescription('Test Description')
				.setStartDateTime(DateTime.now())
				.setEndDateTime(DateTime.now().addHours(1))
				.setType('Meeting')
				.setEventStatus(EventUtil.STATUS_SCHEDULED)
				.build();
			insert objEvent;

			objEvent.Event_Status__c = EventUtil.STATUS_ATTEMPT;
			update objEvent;

			Event objEventAssert = [SELECT Id, Closed_Owner_Role__c FROM Event WHERE Id = :objEvent.Id LIMIT 1];
			System.assertEquals(objMDRUser.UserRole.Name, objEventAssert.Closed_Owner_Role__c, 'Closed Owner Role did not get updated with owner role.');
			Test.stopTest();
		}
	}
}