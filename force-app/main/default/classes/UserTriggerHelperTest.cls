/**
 * @name         : UserTriggerHelperTest
 * @author       : Old Authors & Prity Kumari
 * @date         : 07-27-2021
 * @description  : UserTriggerHelperTest Class
 * @test classes : N/A
 **/
@isTest
public class UserTriggerHelperTest {
	@testSetup
	static void testUserFeatureChange() {
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		UserRole objUserRole = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		System.runAs(objcurrentUser) {
			insert objUserRole;
		}

		Profile objProfile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		Profile objProfile2 = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

		String strOrgId = UserInfo.getOrganizationId();
		String strDateTime = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer intRandom = Integer.valueOf(math.rint(math.random() * 1000000));
		Integer intRandom2 = Integer.valueOf(math.rint(math.random() * 1000000));
		Integer intRandom3 = Integer.valueOf(math.rint(math.random() * 1000000));
		String strUniqueName = strOrgId + strDateTime + intRandom;
		String strUniqueName2 = strOrgId + strDateTime + intRandom2;
		String strUniqueName3 = strOrgId + strDateTime + intRandom3;

		User objUser1 = new User();
		objUser1.FirstName = 'Test FName 1';
		objUser1.LastName = 'User1';
		objUser1.UserRoleId = objUserRole.Id;
		objUser1.ProfileId = objProfile1.Id;
		objUser1.Benefits_Class__c = 'Class 1';
		objUser1.Class_Queue__c = 'Class 1';
		objUser1.alias = strUniqueName.substring(18, 23);
		objUser1.email = 'usr' + strUniqueName + '@test' + strOrgId + '.org';
		objUser1.username = 'usr' + strUniqueName + '@test' + strOrgId + '.org';
		objUser1.TimeZoneSidKey = 'GMT';
		objUser1.LanguageLocaleKey = 'en_US';
		objUser1.EmailEncodingKey = 'UTF-8';
		objUser1.LocaleSidKey = 'en_US';
		objUser1.Active_License__c = 'CA;CO;';
		objUser1.IsActive = true;
		System.runAs(objcurrentUser) {
			insert objUser1;
		}
		UserRole objUserRole1 = new UserRole(Name = 'CEO');
		System.runAs(objcurrentUser) {
			insert objUserRole1;
		}

		objUser1.LastName = 'test12';
		objUser1.UserRoleId = objUserRole1.id;
		objUser1.ProfileId = objProfile2.Id;
		objUser1.Benefits_Class__c = 'Class 2';
		objUser1.Class_Queue__c = 'Class 2';
		System.runAs(objcurrentUser) {
			update objUser1;
		}

		//creating this user with Manager as  objUser1
		User objUser2 = new User();
		objUser2.FirstName = 'Test FName 2';
		objUser2.LastName = 'User2';
		objUser2.UserRoleId = objUserRole.Id;
		objUser2.ProfileId = objProfile1.Id;
		objUser2.Benefits_Class__c = 'Class 2';
		objUser2.Class_Queue__c = 'Class 2';
		objUser2.ManagerId = objUser1.Id;
		objUser2.alias = strUniqueName2.substring(18, 23);
		objUser2.email = 'usr' + strUniqueName2 + '@test' + strOrgId + '.org';
		objUser2.username = 'usr' + strUniqueName2 + '@test' + strOrgId + '.org';
		objUser2.TimeZoneSidKey = 'GMT';
		objUser2.LanguageLocaleKey = 'en_US';
		objUser2.EmailEncodingKey = 'UTF-8';
		objUser2.LocaleSidKey = 'en_US';
		objUser2.Active_License__c = 'CA;CO;';
		objUser2.IsActive = true;
		System.runAs(objcurrentUser) {
			insert objUser2;
		}

		//creating this user for checking Manager change criteria
		User objUser3 = new User();
		objUser3.FirstName = 'Test3';
		objUser3.LastName = 'User3';
		objUser3.UserRoleId = objUserRole1.Id;
		objUser3.ProfileId = objProfile2.Id;
		objUser3.Benefits_Class__c = 'Class 3';
		objUser3.Class_Queue__c = 'Class 3';
		objUser3.ManagerId = objUser2.Id;
		objUser3.alias = strUniqueName3.substring(18, 23);
		objUser3.email = 'usr' + strUniqueName3 + '@test' + strOrgId + '.org';
		objUser3.username = 'usr' + strUniqueName3 + '@test' + strOrgId + '.org';
		objUser3.TimeZoneSidKey = 'GMT';
		objUser3.LanguageLocaleKey = 'en_US';
		objUser3.EmailEncodingKey = 'UTF-8';
		objUser3.LocaleSidKey = 'en_US';
		System.runAs(objcurrentUser) {
			insert objUser3;
		}

		objUser3.ManagerId = objUser1.Id;
		System.runAs(objcurrentUser) {
			update objUser3;
		}
		User objPartnerUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(objProfile1.Id)
			.setUserRoleId(objUserRole.Id)
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

		System.runAs(objcurrentUser) {
			UserTriggerHelper.skipTrigger = true;
			insert objPartnerUser;
		}
		Account objAccountReseller = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('ABC Reseller Account 1').build();
		insert objAccountReseller;
		Contact objResellerContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.RESELLER_CONTACT_RT_ID)
			.setAccountId(objAccountReseller.Id)
			.setFirstName('Test Company')
			.setLastName('Contact 1')
			.setPhone('1234561234')
			.setEmail('newcontact1@task.com')
			.setNormalizedPhone('1234561234')
			.setOwnerId(objPartnerUser.Id)
			.build();
		ContactTriggerHelper.skipTrigger = true;
		insert objResellerContact;
		ContactTriggerHelper.skipTrigger = false;
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('Test Reseller')
			.setLastName('Lead1')
			.setEmail('test1@test.com')
			.setCompany('ABC Lead')
			.setLeadCreationOffer('List Upload')
			.setLeadSource('Test Class')
			.setAccountCreatedDate(DateTime.now().addDays(-10))
			.setOwnerId(objPartnerUser.Id)
			.build();
		insert objLead;

		CaseTriggerHelper.skipTrigger = true;
		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Tax Res')
			.setDescription('Tax Res')
			.setOrigin('Email')
			.setStatus('Data Capture in Progress')
			.setSuppliedEmail('test.test1@gmail.com')
			.setEmailStatus('Open')
			.build();
		objCase2.OwnerId = objUser1.Id;
		insert objCase2;
		CaseTriggerHelper.skipTrigger = false;

		// Create records for HI opportunity re-routing
		// Create 2 company accounts
		Account objCaliforniaAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account in California')
			.setBillingCity('City')
			.setBillingState('California')
			.setBillingCountry('United States')
			.setBillingPostalCode('12345')
			.build();
		Account objColoradoAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account in Colorado')
			.setBillingCity('City')
			.setBillingState('Colorado')
			.setBillingCountry('United States')
			.setBillingPostalCode('12345')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert new List<Account>{ objCaliforniaAcc, objColoradoAcc };

		// Create Benefits New Plan Opportunities to both accounts and both users (In total 4 benefit opps)
		Opportunity objOpp1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Benefits New Plan Opp 1')
			.setAccountId(objCaliforniaAcc.Id)
			.setCloseDate(System.today())
			.setStage(OpportunityUtil.DEFAULT_HI_SALES_STAGE)
			.setOwnerId(objUser1.Id)
			.build();
		Opportunity objOpp2 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Benefits New Plan Opp 2')
			.setAccountId(objCaliforniaAcc.Id)
			.setCloseDate(System.today())
			.setStage(OpportunityUtil.DEFAULT_HI_SALES_STAGE)
			.setOwnerId(objUser2.Id)
			.build();
		Opportunity objOpp3 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Benefits New Plan Opp 3')
			.setAccountId(objColoradoAcc.Id)
			.setCloseDate(System.today())
			.setStage(OpportunityUtil.DEFAULT_HI_SALES_STAGE)
			.setOwnerId(objUser1.Id)
			.build();
		Opportunity objOpp4 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Benefits New Plan Opp 4')
			.setAccountId(objColoradoAcc.Id)
			.setCloseDate(System.today())
			.setStage(OpportunityUtil.DEFAULT_HI_SALES_STAGE)
			.setOwnerId(objUser2.Id)
			.build();
		List<Opportunity> list_Opps = new List<Opportunity>{ objOpp1, objOpp2, objOpp3, objOpp4 };
		OpportunityTriggerHelper.skipTrigger = true;
		insert list_Opps;

		// Create state name & code mapping for California & Colorado
		State_Name_to_Abbreviations_Mapping__c objCal = new TestDataFactory.StateNametoAbbreviationsMappingBuilder()
			.setStateName('California')
			.setStateAbbreviation('CA')
			.setName('California')
			.build();
		State_Name_to_Abbreviations_Mapping__c objCol = new TestDataFactory.StateNametoAbbreviationsMappingBuilder().setStateName('Colorado').setStateAbbreviation('CO').setName('Colorado').build();
		insert new List<State_Name_to_Abbreviations_Mapping__c>{ objCal, objCol };
		CarrierOrderTriggerHelper.skipTrigger = true;
		CarrierTriggerHelper.skipTrigger = true;
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('AK').setPartnerType('TAdA').build();
		insert objCarrier;
		Benefit_Order__c objBORBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR'))
			.setName('TEST BENEFIT ORDER')
			.setOpp(list_Opps[0].Id)
			.setStatusDetail('Owner only group')
			.setType('BOR + TAdA')
			.setTotalNumberOfDocuments(1)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		insert objBORBO;
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();
		String CO_RT_BENEFITS_BOR = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		Carrier_Order__c objBORCO1 = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrder')
			.setCarrier(objCarrier.Id)
			.setStartDate(System.today())
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setImplementationStage('Qualification')
			.setFacilitator2PlanBuild('Y')
			.setResignRequired('No')
			.setContributionPerTheER('test')
			.setBenefitOrder(objBORBO.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objBORCO1);
		Carrier_Order__c objBORCO2 = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrder- ALegeus')
			.setCarrier(objCarrier.Id)
			.setStartDate(System.today())
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setImplementationStage('Qualification')
			.setFacilitator2PlanBuild('Y')
			.setResignRequired('No')
			.setContributionPerTheER('test')
			.setBenefitOrder(objBORBO.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objBORCO2);

		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Parent Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setBenefitOrder(objBORBO.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		Carrier_Order__c objRenewalCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Confirmation Automation Eligible')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setBenefitOrder(objBORBO.Id)
			.setOrderPlayableDate(System.today().addDays(10))
			.setImplementationStage('Ready for Confirmation')
			.setEligibleForConfirmationAutomation(true)
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objRenewalCarrierOrder);
		insert list_CarrierOrders;
	}

	static testMethod void testUserWhoHaveBORRec() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		HIBorTransferTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		List<Role__c> list_Roles = new List<Role__c>();
		List<Skill__c> list_Skills = new List<Skill__c>();
		List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();
		User objUser1 = [SELECT Id, Out_Of_Office__c FROM User WHERE LastName = 'User2' AND IsActive = TRUE LIMIT 1];
		objUser1.Out_Of_Office__c = true;
		update objUser1;

		System.runAs(objUser1) {
			Opportunity objOppty = TestUtility.BenefitsBoROpportunity();

			Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', objOppty.Id, 'Test BO ', false);
			objBO.OwnerId = UserInfo.getUserId();
			objBO.Initial_Owner__c = objUser1.Id;
			insert objBO;

			Carrier__c objCarrier = TestUtility.Carrier();
			Carrier_Order__c objCarOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
			objCarOrder.Name = 'TEST CARRIER ORDER';
			objCarOrder.Carrier__c = objCarrier.Id;
			objCarOrder.Benefit_Order__c = objBO.Id;
			objCarOrder.Order_Type__c = 'Qualification';
			objCarOrder.RecordTypeId = cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
			objCarOrder.OwnerId = UserInfo.getUserId();
			objCarOrder.Initial_Owner__c = objUser1.Id;
			insert objCarOrder;

			Role__c objBARole = new Role__c();
			objBARole.name = 'Benefit Transfer Advocate';
			list_Roles.add(objBARole);

			Role__c objBF1Role = new Role__c();
			objBF1Role.name = 'Benefit Transfer Facilitator 1';
			list_Roles.add(objBF1Role);
			insert (list_Roles);

			list_Skills.add(new Skill__c(Role__c = objBARole.Id));
			list_Skills.add(new Skill__c(Role__c = objBF1Role.Id));
			insert list_Skills;

			User_Role__c objUserRole = new User_Role__c();
			objUserRole.User__c = objUser1.Id;
			insert objUserRole;

			list_UserSkills.add(new User_Skill__c(Skill__c = list_Skills[0].Id, User_Role__c = objUserRole.Id, Skill_Role_Name__c = 'Benefit transfer Advocate'));

			list_UserSkills.add(new User_Skill__c(Skill__c = list_Skills[1].Id, User_Role__c = objUserRole.Id, Skill_Role_Name__c = 'Benefit transfer Facilitator 1'));

			insert list_UserSkills;
		}

		OpportunityTriggerHelper.skipTrigger = false;
		BenefitOrderHelper.skipTrigger = false;

		objUser1.Out_Of_Office__c = false;
		update objUser1;

		Test.stopTest();

		Benefit_Order__c objBenefitOrder = [SELECT Id, OwnerId FROM Benefit_Order__c LIMIT 1];
		System.assertNotEquals(UserInfo.getUserId(), objBenefitOrder.OwnerId);
	}

	static testMethod void testMarkUserAsActive() {
		Test.startTest();

		User objUser1 = [SELECT Id, IsActive FROM User WHERE LastName = 'test12' LIMIT 1];
		objUser1.IsActive = true;
		update objUser1;

		Test.stopTest();

		objUser1 = [SELECT Id, IsActive, Inactive_User_Date_Time__c FROM User WHERE Id = :objUser1.Id];
		System.assertEquals(null, objUser1.Inactive_User_Date_Time__c);
	}

	static testMethod void testMarkUserAsInactive() {
		Map<String, User> map_UsersByName = new Map<String, User>();
		Group objDataCaptureQueue = new Group();
		User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(loggedInUser) {
			List<Group> list_TaxResGroups = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'TaxRes_Data_Capture_Queue' LIMIT 1];
			objDataCaptureQueue = list_TaxResGroups?.get(0);

			//Testing when a tax res case is assigned to an inactive user
			User objUser1 = [SELECT Id, IsActive FROM User WHERE LastName = 'test12' LIMIT 1];

			Test.startTest();
			objUser1.IsActive = false;
			update objUser1;
			Test.stopTest();

			Case objUpdatedTaxResCase = [SELECT Id, OwnerId, Status FROM Case WHERE SuppliedEmail = 'test.test1@gmail.com'];
			System.assertEquals(objDataCaptureQueue.Id, objUpdatedTaxResCase.OwnerId);
			System.assertEquals('Ready for Data Capture', objUpdatedTaxResCase.Status);
			objUser1 = [SELECT Id, IsActive, Inactive_User_Date_Time__c FROM User WHERE Id = :objUser1.Id];
			System.assertNotEquals(null, objUser1.Inactive_User_Date_Time__c);
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method To Update Requires ReRouting To True
	 * @param        N/A
	 * @return       N/A
	 **/
	@IsTest
	static void testUpdateReRoutingPositive() {
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		UserRole objUserRole = [SELECT Id FROM UserRole WHERE Name = 'Submission Advocate'];
		UserRole objUserRole1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MyCustomRole'];
		User objUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
		objUser.UserRoleId = objUserRole.Id;
		UserTriggerHelper.skipTrigger = true;
		update objUser;
		List<Carrier_Order__c> list_CarrierOrder = new List<Carrier_Order__c>();
		for (Carrier_Order__c objCarrier : [SELECT Id, OwnerId, Requires_Routing__c FROM Carrier_Order__c]) {
			objCarrier.OwnerId = objUser.Id;
			objCarrier.Requires_Routing__c = false;
			list_CarrierOrder.add(objCarrier);
		}
		System.runAs(objCurrentUser) {
			CarrierOrderTriggerHelper.skipTrigger = true;
			update list_CarrierOrder;
		}
		Test.startTest();
		objUser.UserRoleId = objUserRole1.Id;
		UserTriggerHelper.skipTrigger = false;
		update objUser;
		Test.stopTest();
		List<Carrier_Order__c> list_CarrierOrder1 = [SELECT Id, OwnerId, Requires_Routing__c FROM Carrier_Order__c];
		system.assertEquals(list_CarrierOrder1[0].Requires_Routing__c, true, 'Carrier Order Requires routing is not updated to true');
	}

	/**
	 * @author       Deepika Saini
	 * @description   Test method To Update Requires ReRouting To False
	 * @param        N/A
	 * @return       N/A
	 **/
	@IsTest
	static void testUpdateReRoutingNegative() {
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		Test.startTest();
		UserRole objUserRole = [SELECT Id FROM UserRole WHERE Name = 'Submission Advocate'];
		UserRole objUserRole1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'MyCustomRole'];
		User objUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
		objUser.UserRoleId = objUserRole1.Id;
		update objUser;
		List<Carrier_Order__c> list_CarrierOrder = new List<Carrier_Order__c>();
		for (Carrier_Order__c objCarrier : [SELECT Id, OwnerId, Requires_Routing__c, Implementation_Stage__c FROM Carrier_Order__c]) {
			objCarrier.OwnerId = objUser.Id;
			objCarrier.Requires_Routing__c = false;
			objCarrier.Implementation_Stage__c = 'Qualification';
			list_CarrierOrder.add(objCarrier);
		}

		System.runAs(objCurrentUser) {
			CarrierOrderTriggerHelper.skipTrigger = true;
			update list_CarrierOrder;
		}
		objUser.UserRoleId = objUserRole.Id;
		update objUser;
		Test.stopTest();
		
		List<Carrier_Order__c> list_CarrierOrder1 = [SELECT Id, OwnerId, Requires_Routing__c FROM Carrier_Order__c];
		system.assertEquals(list_CarrierOrder1[0].Requires_Routing__c, false, 'Carrier Order Requires routing is updated to true');
	}
}