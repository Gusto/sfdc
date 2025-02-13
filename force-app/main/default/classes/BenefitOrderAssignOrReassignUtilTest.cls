/**
 * @name         :
 * @author       : Neha Dabas
 * @date         : 04-5-2021
 * @description  : Unit tests for OA Mass Email functionality
 * @apex classes : BenefitOrderAssignOrReassignBatch, BenefitOrderAssignOrReassignUtil
 **/
@isTest
private class BenefitOrderAssignOrReassignUtilTest {
	@testSetup
	static void makeData() {
		skipTriggers();
		String strByPassFlow = 'All_Flows';
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		User objAdminUser = new TestDataFactory.UserBuilder()
			.setUserName('Implementation.Advocate@test.Implementation')
			.setExemptfromValidationRules(true)
			.setEmail('partneram@testorg.com')
			.setProfileId(UserInfo.getProfileId())
			.setBypassFlows(strByPassFlow)
			.build();
		insert objAdminUser;

		CaseTeamRole objTeamRole;
		System.runAs(objAdminUser) {
			objTeamRole = new CaseTeamRole(Name = 'Admin', AccessLevel = 'Edit');
			insert objTeamRole;
		}

		User objUser = new User(Id = UserInfo.getUserId());
		objUser.Out_Of_Office__c = false;
		objUser.isActive = true;
		objUser.Bypass_Flows__c = strByPassFlow;
		update objUser;

		Role__c objRole = new Role__c();
		objRole.Name = 'Implementation Advocate';
		objRole.Skill_Type__c = 'Core';
		objRole.Team__c = 'Implementation Advocate';
		insert objRole;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test').build();
		objCarrier.Carrier_Unique_Name__c = 'Test';
		objCarrier.State__c = 'CA';
		insert objCarrier;

		Skill__c objSkill = new TestDataFactory.SkillBuilder().setRoleId(objRole.Id).build();
		objSkill.Order_Type__c = 'New to Gusto';
		objSkill.Carrier__c = objCarrier.Id;
		objSkill.Partner__c = 'Gold';
		objSkill.Tier__c = objTierConfig.New_Tier_1__c;
		objSkill.State_Group__c = 'California';
		insert objSkill;

		User_Role__c objUserRole = new TestDataFactory.UserRoleBuilder().setUserId(objUser.Id).setUserSkillType('Core').setUserTeam('Implementation Advocate').build();
		insert objUserRole;

		User_Skill__c objUserSkill = new TestDataFactory.UserSkillBuilder().setSkillId(objSkill.Id).setUserRoleId(objUserRole.Id).setSkillRoleName('Implementation Advocate').setActive(true).build();
		insert objUserSkill;

		User objUser1 = new TestDataFactory.UserBuilder().setUserName('Implementation1.Advocate@test.Implementation').setEmail('partneram1@testorg.com').setProfileId(UserInfo.getProfileId()).setBypassFlows(strByPassFlow).build();
		insert objUser1;

		User_Role__c objUserRole1 = new TestDataFactory.UserRoleBuilder().setUserId(objUser1.Id).setUserSkillType('Core').setUserTeam('Implementation Advocate').build();
		insert objUserRole1;

		Skill__c objSkill1 = new TestDataFactory.SkillBuilder().setRoleId(objRole.Id).build();
		objSkill1.Order_Type__c = 'New to Gusto';
		objSkill1.Carrier__c = objCarrier.Id;
		objSkill1.Partner__c = 'Gold';
		objSkill1.Tier__c = objTierConfig.New_Tier_1__c;
		objSkill1.State_Group__c = 'California';
		insert objSkill1;

		Skill__c objSkill2 = new TestDataFactory.SkillBuilder().setRoleId(objRole.Id).build();
		objSkill2.Order_Type__c = 'New to Gusto';
		objSkill2.Carrier__c = objCarrier.Id;
		objSkill2.Partner__c = 'Gold';
		objSkill2.Tier__c = objTierConfig.New_Tier_1__c;
		objSkill2.State_Group__c = 'California';
		insert objSkill2;

		User_Skill__c objUserSkill1 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(objSkill1.Id)
			.setUserRoleId(objUserRole1.Id)
			.setSkillRoleName('Implementation Advocate')
			.setActive(true)
			.build();
		insert objUserSkill1;

		User_Skill__c objUserSkill2 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(objSkill2.Id)
			.setUserRoleId(objUserRole1.Id)
			.setSkillRoleName('Implementation Advocate')
			.setActive(true)
			.build();
		insert objUserSkill2;

		List<State_Name_to_abbreviations_Mapping__c> list_State = new List<State_Name_to_abbreviations_Mapping__c>();
		list_State.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Arizona', State_Abbreviation__c = 'Arizona', State_Name__c = 'AZ', HI_Active__c = true));
		list_State.add(new State_Name_to_abbreviations_Mapping__c(Name = 'California', State_Abbreviation__c = 'California', State_Name__c = 'CA', HI_Active__c = true));
		insert list_State;
	}

	static void createBulkData() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;


		skipTriggers();

		// Get org default tier config settings and assert new tier 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Tier_1__c);

		List<Account> list_Accounts = new List<Account>();
		List<Opportunity> list_Opportunity = new List<Opportunity>();
		List<Benefit_Order__c> list_BOs = new List<Benefit_Order__c>();
		List<Contact> list_Contacts = new List<Contact>();
		List<Case> list_Cases = new List<Case>();
		Id idOppRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Id idBORecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		for (Integer intCount = 0; intCount < 5; intCount++) {
			Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account').setTier(objTierConfig.New_Tier_1__c).setBillingState('California').setBillingCountry('United States').build();
			objAccount.States__c = 'CA';
			list_Accounts.add(objAccount);
		}
		insert list_Accounts;

		Integer intCount = 0;
		for (Account objAcc : list_Accounts) {
			list_Contacts.add(new Contact(AccountId = objAcc.Id, FirstName = 'Test', LastName = 'Contact' + intCount, Email = 'test.contact' + intCount + '@testing.com'));

			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(idOppRecordTypeId)
				.setAccountId(objAcc.Id)
				.setName('Test Opp')
				.setStage('Raw')
				.setCloseDate(System.Today())
				.setHIEffectiveDate(System.Today())
				.build();
			list_Opportunity.add(objOpportunity);
			intCount++;
		}

		insert list_Contacts;

		insert list_Opportunity;

		intCount = 0;
		for (Opportunity objOppty : list_Opportunity) {
			Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
				.setName('Test Benefit Order')
				.setRecordType(idBORecordTypeId)
				.setOpp(objOppty.Id)
				.setAccount(objOppty.AccountId)
				.setCoverageEffectiveDate(System.today())
				.setStatus('Ready for Qualification')
				.setOwnerId(UserInfo.getUserId())
				.build();

			objBO.OwnerId = UserInfo.getUserId();
			objBO.Open_Enrollment_Start_Date__c = System.today();
			objBO.Open_Enrollment_End_Date__c = System.today();
			objBO.Initial_Owner__c = UserInfo.getUserId();
			objBO.Type__c = 'New to Gusto';
			list_BOs.add(objBO);
		}

		insert list_BOs;
		
		List<Benefit_Order__c> list_ParentBOs = new List<Benefit_Order__c>();

		for (Benefit_Order__c objBO : list_BOs) {
			Benefit_Order__c objParentBO = new TestDataFactory.BenefitOrderBuilder()
			.setName('Test Benefit Order1')
			.setRecordType(idBORecordTypeId)
			.setOpp(objBO.Opportunity__c)
			.setAccount(objBO.Account__c)
			.setCoverageEffectiveDate(System.today())
			.setStatus('Ready for Qualification')
			.setOwnerId(UserInfo.getUserId())
			.setParentBenefitOrder(objBO.Id)
			.build();
			list_ParentBOs.add(objParentBO);
		}
		insert list_ParentBOs;

		intCount = 0;
		for (Opportunity objOppty : list_Opportunity) {
			Case objCase = new TestDataFactory.CaseBuilder()
				.setIntegrationId('hippo-' + objOppty.Id)
				.setContactId(list_Contacts[intCount].Id)
				.setAccountId(objOppty.AccountId)
				.setRecordTypeId('Benefits New Plan Case')
				.setSubject('Test onboarding case')
				.build();
			objCase.Benefit_Order__c = list_BOs[intCount].Id;
			objCase.Priority = 'Medium';
			list_Cases.add(objCase);
			intCount++;
		}

		insert list_Cases;
	}

	/*
	 *@Author		: Neha Dabas
	 *@Description	: Test Mass Email without customer cases
	 */
	@isTest
	static void testMassEmailNoCase() {
		Test.startTest();

		// Get org default tier config settings and assert new tier 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Tier_1__c);

		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Account')
			.setTier(objTierConfig.New_Tier_1__c)
			.setBillingState('California')
			.setBillingCountry('United States')
			.setStates('CA')
			.build();
		insert objAcc;

		Id idOppRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(idOppRecordTypeId)
			.setAccountId(objAcc.Id)
			.setName('Test Opp')
			.setStage('Raw')
			.setCloseDate(System.Today())
			.setHIEffectiveDate(System.Today())
			.build();
		insert objOpp;

		Benefit_Order__c objBO = new Benefit_Order__c(
			Order_Status__c = 'OE',
			OwnerId = userInfo.getUserId(),
			Coverage_Effective_Date__c = System.today(),
			Open_Enrollment_Start_Date__c = System.today(),
			Open_Enrollment_End_Date__c = System.today(),
			Initial_Owner__c = UserInfo.getUserId(),
			Push_Rate_Reason__c = 'Not enough EE enrolled',
			Opportunity__c = objOpp.Id,
			Account__c = objOpp.AccountId,
			RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan')
		);
		insert objBO;

		User objUser = new User();
		objUser.Id = UserInfo.getUserId();
		objUser.Out_Of_Office__c = true;
		objUser.Bypass_Flows__c = 'All_Flows';
		update objUser;

		ReassignBenefitOrderOwnerCtrl.changeOwner(new List<Id>{ objBO.Id });

		Test.stopTest();

		System.assertEquals([SELECT COUNT() FROM EmailMessage], 0);
	}

	/*
	 *@Description : Test BO Owner Reassignment once user is back in office
	 */
	@isTest
	static void testBOReassignment() {
		createBulkData();

		Test.startTest();

		skipTriggers();

		List<Benefit_Order__c> list_BOs = [
			SELECT Order_Status__c, ownerID, Coverage_Effective_Date__c, Open_Enrollment_Start_Date__c, Open_Enrollment_End_Date__c, Initial_Owner__c, Push_Rate_Reason__c
			FROM Benefit_Order__c
			WHERE Parent_Benefit_Order__c = NULL
		];

		List<Id> list_BOIds = new List<Id>();

		for (Benefit_Order__c objBO : list_BOs) {
			objBO.Initial_Owner__c = UserInfo.getUserId();
			list_BOIds.add(objBO.Id);
		}

		update list_BOs;

		User objUser = new User();
		objUser.Id = UserInfo.getUserId();
		objUser.Out_Of_Office__c = false;
		update objUser;

		System.runAs(objUser) {
			ReassignBenefitOrderOwnerCtrl.changeOwnerToSelf(list_BOIds);
		}

		Test.stopTest();

		System.assertEquals([SELECT OwnerId FROM Benefit_Order__c WHERE Id = :list_BOs[0].Id][0].OwnerId, UserInfo.getUserId());
	}

	/*
	 *@Description : Skip Triggers
	 */
	static void skipTriggers() {
		OppRelatedTrackTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		TaskTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
	}
}