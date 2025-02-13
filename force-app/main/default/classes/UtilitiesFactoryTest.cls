@isTest
private class UtilitiesFactoryTest {
	static final Id ID_LOGGED_USER = UserInfo.getUserId();

	@testSetup
	static void setUp() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		List<Role__c> list_Roles = new List<Role__c>();
		List<Skill__c> list_Skills = new List<Skill__c>();
		List<Region_POD__c> list_PODs = new List<Region_POD__c>();
		EncryptionUtils.generateKey('Master');

		Account objAccount = TestUtility.CompanyAccount();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'MF QLE');
		objCase.AccountId = objAccount.Id;
		objCase.Subject = 'Test';
		objCase.Description = 'Test';
		objCase.Type = 'QLE';
		insert objCase;

		Opportunity objOpportunityNewPlan = TestUtility.BenefitsNewPlanOpportunity();

		//Create New Plan Benefit Order
		Benefit_Order__c objBenefitOrderNewPlan = TestUtility.createTestBenefitOrder('New Plan', objOpportunityNewPlan.Id, 'Test Benefit Order New Plan', false);
		objBenefitOrderNewPlan.Type__c = 'New to Gusto';
		objBenefitOrderNewPlan.Account__c = objOpportunityNewPlan.AccountId;
		objBenefitOrderNewPlan.Coverage_Effective_Date__c = System.today().addDays(-10);
		insert objBenefitOrderNewPlan;

		list_Roles.add(new Role__c(Name = 'Qualification', Team__c = 'Qualification', Skill_Type__c = 'Core'));

		list_Roles.add(new Role__c(Name = 'Qualification Flex', Team__c = 'Qualification', Skill_Type__c = 'Flex'));
		list_Roles.add(new Role__c(Name = 'Qualification Training', Team__c = 'Qualification', Skill_Type__c = 'Training'));
		list_Roles.add(new Role__c(Name = 'Submission', Team__c = 'Submission', Skill_Type__c = 'Core'));

		list_Roles.add(new Role__c(Name = 'Submission Flex', Team__c = 'Submission', Skill_Type__c = 'Flex'));
		list_Roles.add(new Role__c(Name = 'Submission Training', Team__c = 'Submission', Skill_Type__c = 'Training'));
		list_Roles.add(new Role__c(Name = 'Confirmation', Team__c = 'Confirmation', Skill_Type__c = 'Core'));

		list_Roles.add(new Role__c(Name = 'Confirmation Flex', Team__c = 'Confirmation', Skill_Type__c = 'Flex'));
		list_Roles.add(new Role__c(Name = 'Confirmation Training', Team__c = 'Confirmation', Skill_Type__c = 'Training'));

		insert list_Roles;

		list_PODs.add(new Region_POD__c(Name = 'Carrier POD 1', Team__c = 'Submission', Type__c = 'POD', Skill_Type__c = 'Core'));
		list_PODs.add(new Region_POD__c(Name = 'Qualification Flex Role 1', Team__c = 'Qualification', Type__c = 'POD', Skill_Type__c = 'Flex'));
		list_PODs.add(new Region_POD__c(Name = 'Qualification Training Role 1', Team__c = 'Qualification', Type__c = 'POD', Skill_Type__c = 'Training'));
		list_PODs.add(new Region_POD__c(Name = 'Carrier POD Flex Role 1', Team__c = 'Submission', Type__c = 'POD', Skill_Type__c = 'Flex'));
		list_PODs.add(new Region_POD__c(Name = 'Carrier POD Training Role 1', Team__c = 'Submission', Type__c = 'POD', Skill_Type__c = 'Training'));
		list_PODs.add(new Region_POD__c(Name = 'Confirmation Flex Role 1', Team__c = 'Confirmation', Type__c = 'POD', Skill_Type__c = 'Flex'));
		list_PODs.add(new Region_POD__c(Name = 'Confirmation Training Role 1', Team__c = 'Confirmation', Type__c = 'POD', Skill_Type__c = 'Training'));
		insert list_PODs;

		list_Skills.add(new Skill__c(Role__c = list_Roles[0].Id, State_Group__c = 'Arizona'));
		list_Skills.add(new Skill__c(Role__c = list_Roles[1].Id, Region_POD__c = list_PODs.get(1).Id, State_Group__c = 'Arizona'));
		list_Skills.add(new Skill__c(Role__c = list_Roles[2].Id, Region_POD__c = list_PODs.get(2).Id, State_Group__c = 'Arizona'));
		list_Skills.add(new Skill__c(Role__c = list_Roles[3].Id, Region_POD__c = list_PODs.get(0).Id));
		list_Skills.add(new Skill__c(Role__c = list_Roles[4].Id, Region_POD__c = list_PODs.get(3).Id));
		list_Skills.add(new Skill__c(Role__c = list_Roles[5].Id, Region_POD__c = list_PODs.get(4).Id));
		list_Skills.add(new Skill__c(Role__c = list_Roles[6].Id));
		list_Skills.add(new Skill__c(Role__c = list_Roles[7].Id, Region_POD__c = list_PODs.get(5).Id));
		list_Skills.add(new Skill__c(Role__c = list_Roles[8].Id, Region_POD__c = list_PODs.get(6).Id));
		insert list_Skills;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Check the Skills of Logged in User
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckSkillsOfLoggedInUser() {
		Test.startTest();
		Map<String, String> map_CurrentUserRoles = new Map<String, String>();
		UserRoleTriggerHelper.skipTrigger = true;

		User objAdminUser = new User(Id = ID_LOGGED_USER);

		Role__c objRole = [SELECT Id FROM Role__c WHERE NAME = 'Qualification' LIMIT 1];
		Skill__c objSkill = [SELECT Id FROM Skill__c WHERE Role__r.Name = 'Qualification' LIMIT 1];

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Qualification', User_Skill_Type__c = 'Core');
		insert objUserRole;

		User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkill.id, User_Role__c = objUserRole.id, Skill_Role_Name__c = 'Qualification', Active__c = true);

		insert objUserSkill;

		map_CurrentUserRoles = UtilitiesFactory.CheckLoggedInUserRole();

		Test.stopTest();

		System.assert(!map_CurrentUserRoles.isEmpty());
		System.assert(map_CurrentUserRoles.containsKey('Qualification'));
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Check the Skills of Logged in User
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckSkillsOfLoggedInUserConfirmation() {
		Test.startTest();
		Map<String, String> map_CurrentUserRoles = new Map<String, String>();
		UserRoleTriggerHelper.skipTrigger = true;

		User objAdminUser = new User(Id = ID_LOGGED_USER);

		Role__c objRole = [SELECT Id FROM Role__c WHERE NAME = 'Confirmation' LIMIT 1];
		Skill__c objSkill = [SELECT Id FROM Skill__c WHERE Role__r.Name = 'Confirmation' LIMIT 1];

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Confirmation', User_Skill_Type__c = 'Core');
		insert objUserRole;

		User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkill.id, User_Role__c = objUserRole.id, Skill_Role_Name__c = 'Confirmation', Active__c = true);

		insert objUserSkill;

		map_CurrentUserRoles = UtilitiesFactory.CheckLoggedInUserRole();
		Test.stopTest();

		System.assert(!map_CurrentUserRoles.isEmpty());
		System.assert(map_CurrentUserRoles.containsKey('Confirmation'));
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Check the Skills of Logged in User
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckSkillsOfLoggedInUserSubmission() {
		Test.startTest();
		Map<String, String> map_CurrentUserRoles = new Map<String, String>();
		UserRoleTriggerHelper.skipTrigger = true;

		User objAdminUser = new User(Id = ID_LOGGED_USER);

		Role__c objRole = [SELECT Id FROM Role__c WHERE NAME = 'Submission' LIMIT 1];
		Skill__c objSkill = [SELECT Id FROM Skill__c WHERE Role__r.Name = 'Submission' LIMIT 1];

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Submission', User_Skill_Type__c = 'Core');
		insert objUserRole;

		User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkill.id, User_Role__c = objUserRole.id, Skill_Role_Name__c = 'Submission', Active__c = true);

		insert objUserSkill;

		map_CurrentUserRoles = UtilitiesFactory.CheckLoggedInUserRole();
		Test.stopTest();

		System.assert(!map_CurrentUserRoles.isEmpty());
		System.assert(map_CurrentUserRoles.containsKey('Submission'));
	}
	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Check the Skills of Logged in User
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckSkillsOfLoggedInUserFlex() {
		Test.startTest();
		Map<String, String> map_CurrentUserRoles = new Map<String, String>();
		UserRoleTriggerHelper.skipTrigger = true;

		User objAdminUser = new User(Id = ID_LOGGED_USER);

		Role__c objRole = [SELECT Id FROM Role__c WHERE NAME = 'Qualification Flex' LIMIT 1];
		Skill__c objSkill = [SELECT Id FROM Skill__c WHERE Role__r.Name = 'Qualification Flex' LIMIT 1];

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Qualification', User_Skill_Type__c = 'Flex');
		insert objUserRole;

		User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkill.id, User_Role__c = objUserRole.id, Skill_Role_Name__c = 'Qualification Flex');

		insert objUserSkill;

		map_CurrentUserRoles = UtilitiesFactory.CheckLoggedInUserRole();

		Test.stopTest();

		System.assert(!map_CurrentUserRoles.isEmpty());
		System.assert(map_CurrentUserRoles.containsKey('Qualification Flex'));
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Check the Skills of Logged in User
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckSkillsOfLoggedInUserConfirmationFlex() {
		Test.startTest();
		Map<String, String> map_CurrentUserRoles = new Map<String, String>();
		UserRoleTriggerHelper.skipTrigger = true;

		User objAdminUser = new User(Id = ID_LOGGED_USER);

		Role__c objRole = [SELECT Id FROM Role__c WHERE NAME = 'Confirmation Flex' LIMIT 1];
		Skill__c objSkill = [SELECT Id FROM Skill__c WHERE Role__r.Name = 'Confirmation Flex' LIMIT 1];

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Confirmation', User_Skill_Type__c = 'Flex');
		insert objUserRole;

		User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkill.id, User_Role__c = objUserRole.id, Skill_Role_Name__c = 'Confirmation Flex');

		insert objUserSkill;

		map_CurrentUserRoles = UtilitiesFactory.CheckLoggedInUserRole();
		Test.stopTest();

		System.assert(!map_CurrentUserRoles.isEmpty());
		System.assert(map_CurrentUserRoles.containsKey('Confirmation Flex'));
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Check the Skills of Logged in User
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckSkillsOfLoggedInUserSubmissionFlex() {
		Test.startTest();
		Map<String, String> map_CurrentUserRoles = new Map<String, String>();
		UserRoleTriggerHelper.skipTrigger = true;

		User objAdminUser = new User(Id = ID_LOGGED_USER);

		Role__c objRole = [SELECT Id FROM Role__c WHERE NAME = 'Submission Flex' LIMIT 1];
		Skill__c objSkill = [SELECT Id FROM Skill__c WHERE Role__r.Name = 'Submission Flex' LIMIT 1];

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Submission', User_Skill_Type__c = 'Flex');
		insert objUserRole;

		User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkill.id, User_Role__c = objUserRole.id, Skill_Role_Name__c = 'Submission Flex');

		insert objUserSkill;

		map_CurrentUserRoles = UtilitiesFactory.CheckLoggedInUserRole();
		Test.stopTest();

		System.assert(!map_CurrentUserRoles.isEmpty());
		System.assert(map_CurrentUserRoles.containsKey('Submission Flex'));
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, if BO is Fulfilled then skills as not checked, User is alwasys valid
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckTicketOwnerIAIsValid() {
		Test.startTest();
		Boolean blnIsOwnerInValid = false;

		List<Benefit_Order__c> list_BenefitOrders = [
			SELECT
				Id,
				Type__c,
				OwnerId,
				Opportunity__r.OwnerId,
				Opportunity__r.Owner_Role_Name__c,
				Order_Status__c,
				Parent_Benefit_Order__c,
				Initial_Owner__c,
				Tier__c,
				Account__c,
				RecordTypeId,
				Partner_Tier__c,
				Assignment_State__c,
				Coverage_Effective_Date__c,
				Opportunity__c,
				Coverage_Effective_Month__c,
				Coverage_Effective_Year__c
			FROM Benefit_Order__c
			WHERE Name = 'Test Benefit Order New Plan'
			LIMIT 1
		];

		BenefitOrderHelper.skipTrigger = true;
		list_BenefitOrders[0].Order_Status__c = 'Fulfilled';
		update list_BenefitOrders;

		Skill__c objSkill = [SELECT Id FROM Skill__c WHERE Role__r.Name = 'Qualification' LIMIT 1];

		User objAdminUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Qualification', User_Skill_Type__c = 'Core');
		insert objUserRole;

		User_Skill__c objUserSkill = new User_Skill__c(Skill__c = objSkill.id, User_Role__c = objUserRole.id, Skill_Role_Name__c = 'Qualification', Active__c = true);

		Ticket__c objTicket = new Ticket__c();
		objTicket.Status__c = 'New';
		objTicket.OwnerId = UserInfo.getUserId();
		objTicket.Escalation_Reason__c = 'Carrier Error';
		objTicket.Escalation_Reason_Detail__c = 'Incorrect Plans/Waiting Period';
		objTicket.Benefit_Order__c = list_BenefitOrders[0].Id;
		objTicket.Skip_Assignment__c = true;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Compliance');
		TicketTriggerHelper.skipTrigger = true;
		insert objTicket;

		blnIsOwnerInValid = UtilitiesFactory.reAssignIAForInvalidTicketOwner(objTicket, list_BenefitOrders, true);
		Test.stopTest();

		System.assert(!blnIsOwnerInValid);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Ticket Onwer is valid or not
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckTicketOwnerFulfilmentIsValidOrNot() {
		Test.startTest();
		Boolean blnIsOwnerInValid = false;
		UserTriggerHelper.skipTrigger = true;

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
		objMDRUser.isActive = false;
		update objMDRUser;
		blnIsOwnerInValid = UtilitiesFactory.CheckTicketOwnerIsValidOrNot(objMDRUser.Id, TicketUtil.TICKET_ROLE_FULFILLMENT, true);
		Test.stopTest();

		System.assert(blnIsOwnerInValid);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Ticket Onwer is valid or not
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testCheckTicketOwnerFulfilmentIsValid() {
		Test.startTest();
		Boolean blnIsOwnerInValid = false;
		UserTriggerHelper.skipTrigger = true;
		User objAdminUser = new User(Id = ID_LOGGED_USER);
		objAdminUser.isActive = true;
		update objAdminUser;

		blnIsOwnerInValid = UtilitiesFactory.CheckTicketOwnerIsValidOrNot(ID_LOGGED_USER, TicketUtil.TICKET_ROLE_FULFILLMENT, true);
		Test.stopTest();

		System.assert(!blnIsOwnerInValid);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Decryption of event fails
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	private static void testGetDecryptedHIEvent() {
		Test.startTest();
		List<HIFullfillmentEventWrapper> list_DataJsons = new List<HIFullfillmentEventWrapper>();
		List<HI_Fulfillment_Event__c> list_FulfillmentLists = new List<HI_Fulfillment_Event__c>();
		String strTestJson = '{"fulfillment_id":312345,"oe_status":"completed","company_id":"Testcompany"}';
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Blob blobEncryptedInfo = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, strTestJson);

		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c();
		ObjHIEvent.Event_Info_Encrypted__c = EncodingUtil.base64Encode(blobEncryptedInfo);

		list_FulfillmentLists.add(ObjHIEvent);
		list_DataJsons = UtilitiesFactory.getDecryptedHIEventStr(list_FulfillmentLists);

		Test.stopTest();

		System.assertEquals(true, list_DataJsons.isEmpty());
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, if we update Benefit Order, then field history record is created
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	private static void testUpdateBOType() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Type__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order New Plan' LIMIT 1];

		objBenefitOrder.Type__c = 'Carrier switch';
		update objBenefitOrder;
		Test.stopTest();

		List<Field_History__c> list_FieldHistories = [SELECT Id, New_Value__c, Old_Value__c FROM Field_History__c WHERE Field_Name__c = 'Type__c'];

		System.assert(list_FieldHistories.size() > 0);
		System.assertEquals('Carrier switch', list_FieldHistories[0].New_Value__c);
		System.assertEquals('New to Gusto', list_FieldHistories[0].Old_Value__c);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, if we update Opportunity, then field history record is created
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	private static void testUpdateOpp() {
		Test.startTest();
		Opportunity objOpp = [SELECT Id, Is_Multi_EIN__c FROM Opportunity LIMIT 1];

		objOpp.Is_Multi_EIN__c = true;
		update objOpp;

		Test.stopTest();

		List<Field_History__c> list_FieldHistories = [SELECT Id, New_Value__c, Old_Value__c FROM Field_History__c WHERE Field_Name__c = 'Is_Multi_EIN__c'];

		System.assert(list_FieldHistories.size() > 0);
		System.assertEquals('true', list_FieldHistories[0].New_Value__c);
		System.assertEquals('false', list_FieldHistories[0].Old_Value__c);
	}

	static testMethod void fieldAccessiblityTest() {
		UtilitiesFactory.accessibleFields('Account', null);
		Account accRec = new Account();
		accRec.CreatedDate = System.now();
		accRec.Joined_Date_Panda__c = System.today();
		UtilitiesFactory.processField(accRec, 'CreatedDate');
		UtilitiesFactory.processField(accRec, 'Joined_Date_Panda__c');
		list<String> tempList = UtilitiesFactory.caseRelevantFields();
		list<Case> tempCaseList = [SELECT id FROM Case];
		if (tempCaseList.size() > 0) {
			UtilitiesFactory.getFullCase(tempCaseList.get(0).id);
		}
	}

	static testMethod void isOverrideTest() {
		UtilitiesFactory.isOverride('ZPCompanyMigrationTrigger');
		UtilitiesFactory.CheckLoggedInUser();
		UtilitiesFactory.getPickListValues('Skill__c', 'Order_Type__c', null);
		UtilitiesFactory.RetriveSkillType();
		UtilitiesFactory.RetriveSkillSetupCriteria();
		UtilitiesFactory.RetriveRoleType();
		UtilitiesFactory.getActiveState();
		UtilitiesFactory.RetriveUserRole(null);
		UtilitiesFactory.isBTRenewalDateValid(Date.today());
		UtilitiesFactory.readStringAsMap('key=>value,key2=>value2');
		UtilitiesFactory.getCarrierNames('Qualification');
		UtilitiesFactory.deleteRecords(null);
	}

	static testMethod void testSendEmailToSystemAdmin() {
		try {
			Integer intCount = 3 / 0;
		} catch (Exception ex) {
			UtilitiesFactory.sendExceptionEmail(ex, 'Test Class', 'Test Class');
		}
		UtilitiesFactory.fetchBatchEmailSettings(UserInfo.getUserId());
	}
}