/**
 * @name         BTFacilitator2PlayModeCtrlTest
 * @author       Sanjay Paryani
 * @date         02/18/2020
 * @description  Test class for BTFacilitator2PlayModeCtrl
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
public class BTFacilitator2PlayModeCtrlTest {
	public static User objUserOutofOffice, objUserInOffice;

	static {
		setupTestData();
	}

	public static void setupTestData() {
		UserRole r = [SELECT ID, Name, DeveloperName FROM UserRole WHERE DeveloperName = 'Benefit_Transfer_Fulfillment'].get(0);
		objUserOutofOffice = new User(
			ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
			LastName = 'last',
			firstName = 'first',
			Email = 'puser000@lirik.com',
			Username = 'puser000@amamama.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			UserRoleId = r.Id,
			IsActive = true,
			Out_Of_Office__c = true,
			Back_In_Office_Date_Time__c = system.today().addDays(2)
		);
		insert objUserOutOfOffice;

		objUserInOffice = new User(
			ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
			LastName = 'last1',
			firstName = 'first1',
			Email = 'puser001@lirik.com',
			Username = 'puser000@amamama.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			UserRoleId = r.Id,
			IsActive = true,
			Out_Of_Office__c = false
		);
		insert objUserInOffice;

		System.runAs(objUserOutOfOffice) {
			List<User_Role__c> list_UserRole = new List<User_Role__c>();

			list_UserRole.add(new User_Role__c(User__c = objUserOutOfOffice.Id));
			list_UserRole.add(new User_Role__c(User__c = objUserInOffice.Id));
			insert list_UserRole;

			Role__c roleObj = new Role__c();
			roleObj.Name = 'Benefit Transfer Facilitator 2';
			insert roleObj;

			List<Skill__c> lstSkill = new List<Skill__c>();
			lstSkill.add(new Skill__c(Role__c = roleObj.Id, Build_Plans__c = true));
			lstSkill.add(new Skill__c(Role__c = roleObj.Id, Build_Plans__c = false));
			insert lstSkill;

			List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
			list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[0].Id));
			list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[0].Id));
			list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[1].Id));
			list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[1].Id));
			insert list_UserSkill;
		}
	}

    @isTest
	static void TestEnrolmentReview() {
		Test.startTest();
		System.runAs(objUserInOffice) {
			Utils.skipTrigger(true);
			account acc1 = TestUtility.CompanyAccount();
			Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
			opp1.Account = acc1;
			update opp1;

			Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
			boRec.UW_Owner__c = UserInfo.getUserId();
			update borec;

			Carrier__c objCarrier = TestUtility.createTestCarrier('alegeus', 'NY', true);
			Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1', 'CA', true);

			Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
			obj_CarrierOrder.Carrier__c = objCarrier.Id;
			obj_CarrierOrder.Benefit_Order__c = boRec.id;
			Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
			obj_CarrierOrder.RecordTypeId = rectype;
			obj_CarrierOrder.Renewal_Date__c = date.today();
			obj_CarrierOrder.Benefit_Types__c = 'HSA';
			obj_CarrierOrder.Implementation_Stage__c = 'Enrollment Review Entry in Progress';
			obj_CarrierOrder.Start_Date__c = date.today();
			obj_CarrierOrder.Facilitator_2_Plan_Review__c = userinfo.getUserId();
			obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = userinfo.getUserId();
			obj_CarrierOrder.OwnerId = userinfo.getUserId();
			insert obj_CarrierOrder;

			obj_CarrierOrder.Implementation_Stage__c = 'Enrollment Review Entry in Progress';
			update obj_CarrierOrder;

			list<Carrier_Order__c> CO = new List<Carrier_Order__c>();
			CO.add(obj_CarrierOrder);

			Ticket__c t1 = new Ticket__c();
			t1.Carrier_Order__c = obj_CarrierOrder.id;
			t1.Status__c = 'new';
			insert t1;

			BTFacilitator2PlayModeCtrl Ctrl = new BTFacilitator2PlayModeCtrl();
			Ctrl.seeMyOrders();
			Ctrl.saveMyEnrollmentReviewOrders();
			Ctrl.ShowTicketCreatedByMe();
			Ctrl.ShowTicketOwnedByMe();
			Ctrl.ShowClosedTicket();

			// Check that the Implementation Stage of Carrier Order is updated
			obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
			System.assertEquals('Enrollment Review Entry in Progress', obj_CarrierOrder.Implementation_Stage__c, 'The implementation stage should be correctly set.');

			// Verify ticket creation
			Ticket__c createdTicket = [SELECT Id, Status__c FROM Ticket__c WHERE Carrier_Order__c = :obj_CarrierOrder.Id];
			System.assertNotEquals(null, createdTicket, 'A ticket should have been created for the carrier order.');
			System.assertEquals('New', createdTicket.Status__c, 'The ticket status should be "New"');
		}
		Test.stopTest();
	}

    @isTest
	static void TestPlanReview() {
		Test.startTest();
		System.runAs(objUserInOffice) {
			Utils.skipTrigger(true);
			account acc1 = TestUtility.CompanyAccount();
			Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
			opp1.Account = acc1;
			update opp1;

			Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
			boRec.UW_Owner__c = UserInfo.getUserId();
			update borec;

			Carrier__c objCarrier = TestUtility.createTestCarrier('alegeus', 'NY', true);
			Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1', 'CA', true);

			Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
			obj_CarrierOrder.Carrier__c = objCarrier.Id;
			obj_CarrierOrder.Benefit_Order__c = boRec.id;
			Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
			obj_CarrierOrder.RecordTypeId = rectype;
			obj_CarrierOrder.Renewal_Date__c = date.today();
			obj_CarrierOrder.Benefit_Types__c = 'HSA';
			obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
			obj_CarrierOrder.Start_Date__c = date.today();
			obj_CarrierOrder.Facilitator_2_Plan_Review__c = userinfo.getUserId();
			obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = userinfo.getUserId();
			obj_CarrierOrder.OwnerId = userinfo.getUserId();
			insert obj_CarrierOrder;

			list<Carrier_Order__c> CO = new List<Carrier_Order__c>();
			CO.add(obj_CarrierOrder);

			Ticket__c t1 = new Ticket__c();
			t1.Carrier_Order__c = obj_CarrierOrder.id;
			t1.Status__c = 'new';
			insert t1;

			BTFacilitator2PlayModeCtrl Ctrl = new BTFacilitator2PlayModeCtrl();
			Ctrl.seeMyOrders();
			Ctrl.saveMyPlanReviewOrders();

			// Check that Implementation Stage of Carrier Order is correct
			obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
			System.assertEquals('Implementing Plans', obj_CarrierOrder.Implementation_Stage__c, 'The implementation stage should be updated to "Implementing Plans"');
		}
		Test.stopTest();
	}

    @isTest
	static void TestPlayModeERMultiEIN() {
		System.runAs(objUserInOffice) {
			Utils.skipTrigger(true);
			account acc1 = TestUtility.CompanyAccount();
			Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
			opp1.Account = acc1;
			update opp1;

			Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
			boRec.UW_Owner__c = UserInfo.getUserId();
			update borec;

			Carrier__c objCarrier = TestUtility.createTestCarrier('alegeus', 'NY', true);
			Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1', 'CA', true);

			List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
			Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
			obj_CarrierOrder.Carrier__c = objCarrier.Id;
			obj_CarrierOrder.Benefit_Order__c = boRec.id;
			Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
			obj_CarrierOrder.RecordTypeId = rectype;
			obj_CarrierOrder.Renewal_Date__c = date.today();
			obj_CarrierOrder.Benefit_Types__c = 'HSA';
			obj_CarrierOrder.Implementation_Stage__c = 'Enrollment Review Entry in Progress';
			obj_CarrierOrder.Start_Date__c = date.today();
			obj_CarrierOrder.Facilitator_2_Plan_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.OwnerId = userinfo.getUserId();
			obj_CarrierOrder.Is_Multi_EIN__c = true;
			list_CO.add(obj_CarrierOrder);

			list_CO.add(
				new Carrier_Order__c(
					Carrier__c = objCarrier1.Id,
					Benefit_Order__c = boRec.id,
					RecordTypeId = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId(),
					Renewal_Date__c = date.today(),
					Benefit_Types__c = 'Medical',
					Implementation_Stage__c = 'Implementing Plans',
					Start_Date__c = date.today(),
					OwnerId = userinfo.getUserId(),
					Is_Multi_EIN__c = true,
					OOO_Timestamp__c = system.now()
				)
			);
			insert list_CO;

			list<Carrier_Order__c> CO = new List<Carrier_Order__c>();
			CO.add(obj_CarrierOrder);

			Ticket__c t1 = new Ticket__c();
			t1.Carrier_Order__c = obj_CarrierOrder.id;
			t1.Status__c = 'new';
			insert t1;

			Test.startTest();

			BTFacilitator2PlayModeCtrl Ctrl = new BTFacilitator2PlayModeCtrl();
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.playNewOrders();
			Ctrl.playMyOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Enrollment Review Entry in Progress';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Plans Confirmed';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.fetchEligibleCO();
			Test.stopTest();

			// Check that Implementation Stage of Carrier Order is correct
			obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
			System.assertEquals('Plans Confirmed', obj_CarrierOrder.Implementation_Stage__c, 'The implementation stage should be updated to "Plans Confirmed"');

			// Assert the existence of the ticket
			Ticket__c createdTicket = [SELECT Id FROM Ticket__c WHERE Carrier_Order__c = :obj_CarrierOrder.Id LIMIT 1];
			System.assertNotEquals(null, createdTicket, 'A ticket should have been created for the carrier order');
		}
	}

    @isTest
	static void TestPlayModeER() {
		System.runAs(objUserInOffice) {
			Utils.skipTrigger(true);
			account acc1 = TestUtility.CompanyAccount();
			Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
			opp1.Account = acc1;
			update opp1;

			Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
			boRec.UW_Owner__c = UserInfo.getUserId();
			update borec;

			Carrier__c objCarrier = TestUtility.createTestCarrier('alegeus', 'NY', true);
			Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1', 'CA', true);

			List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
			Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
			obj_CarrierOrder.Carrier__c = objCarrier.Id;
			obj_CarrierOrder.Benefit_Order__c = boRec.id;
			Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
			obj_CarrierOrder.RecordTypeId = rectype;
			obj_CarrierOrder.Renewal_Date__c = date.today();
			obj_CarrierOrder.Benefit_Types__c = 'HSA';
			obj_CarrierOrder.Implementation_Stage__c = 'Enrollment Review Entry in Progress';
			obj_CarrierOrder.Start_Date__c = date.today();
			obj_CarrierOrder.Facilitator_2_Plan_Review__c = objUserInOffice.Id;
			obj_CarrierOrder.OwnerId = userinfo.getUserId();
			obj_CarrierOrder.Facilitator_2_Plan_Build__c = 'N';
			obj_CarrierOrder.Is_Multi_EIN__c = false;
			list_CO.add(obj_CarrierOrder);

			list_CO.add(
				new Carrier_Order__c(
					Carrier__c = objCarrier1.Id,
					Benefit_Order__c = boRec.id,
					Facilitator_2_Plan_Build__c = 'N',
					RecordTypeId = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId(),
					Renewal_Date__c = date.today(),
					Benefit_Types__c = 'Medical',
					Implementation_Stage__c = 'Plans Confirmed',
					Start_Date__c = date.today(),
					OwnerId = userinfo.getUserId(),
					Is_Multi_EIN__c = false
				)
			);
			insert list_CO;

			list<Carrier_Order__c> CO = new List<Carrier_Order__c>();
			CO.add(obj_CarrierOrder);

			Ticket__c t1 = new Ticket__c();
			t1.Carrier_Order__c = obj_CarrierOrder.id;
			t1.Status__c = 'new';
			insert t1;

			Test.startTest();
			BTFacilitator2PlayModeCtrl Ctrl = new BTFacilitator2PlayModeCtrl();
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.playNewOrders();
			Ctrl.playMyOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Enrollment Review Entry in Progress';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();

			// Assert the expected result after updates
			System.assertEquals('Enrollment Review Entry in Progress', obj_CarrierOrder.Implementation_Stage__c);
			System.assertNotEquals(null, [SELECT Id FROM Ticket__c WHERE Carrier_Order__c = :obj_CarrierOrder.Id LIMIT 1]);

			obj_CarrierOrder.Implementation_Stage__c = 'Plans Confirmed';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.fetchEligibleCO();
			Test.stopTest();

			// Check that Implementation Stage of Carrier Order is correct
			obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
			System.assertEquals('Plans Confirmed', obj_CarrierOrder.Implementation_Stage__c, 'The implementation stage should be updated to "Plans Confirmed"');

			// Verify ticket creation
			Ticket__c createdTicket = [SELECT Id FROM Ticket__c WHERE Carrier_Order__c = :obj_CarrierOrder.Id LIMIT 1];
			System.assertNotEquals(null, createdTicket, 'A ticket should have been created for the carrier order');
		}
	}

    @isTest
	static void TestPlayModePlanReviewMultiEIN() {
		Test.startTest();
		System.runAs(objUserInOffice) {
			Utils.skipTrigger(true);
			account acc1 = TestUtility.CompanyAccount();
			Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
			opp1.Account = acc1;
			update opp1;

			Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
			boRec.UW_Owner__c = UserInfo.getUserId();
			update borec;

			Carrier__c objCarrier = TestUtility.createTestCarrier('alegeus', 'NY', true);
			Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1', 'CA', true);

			List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
			Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
			obj_CarrierOrder.Carrier__c = objCarrier.Id;
			obj_CarrierOrder.Benefit_Order__c = boRec.id;
			Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
			obj_CarrierOrder.RecordTypeId = rectype;
			obj_CarrierOrder.Renewal_Date__c = date.today();
			obj_CarrierOrder.Benefit_Types__c = 'FSA';
			obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
			obj_CarrierOrder.Start_Date__c = date.today();
			obj_CarrierOrder.Facilitator_2_Plan_Build__c = 'N';
			obj_CarrierOrder.Facilitator_2_Plan_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.OwnerId = userinfo.getUserId();
			obj_CarrierOrder.Is_Multi_EIN__c = true;
			list_CO.add(obj_CarrierOrder);

			list_CO.add(
				new Carrier_Order__c(
					Carrier__c = objCarrier1.Id,
					Benefit_Order__c = boRec.id,
					Facilitator_2_Plan_Build__c = 'N',
					RecordTypeId = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId(),
					Renewal_Date__c = date.today(),
					Benefit_Types__c = 'Medical',
					Implementation_Stage__c = 'Implementing Plans',
					Start_Date__c = date.today(),
					OwnerId = userinfo.getUserId(),
					Is_Multi_EIN__c = true,
					OOO_Timestamp__c = system.now()
				)
			);
			insert list_CO;

			list<Carrier_Order__c> CO = new List<Carrier_Order__c>();
			CO.add(obj_CarrierOrder);

			Ticket__c t1 = new Ticket__c();
			t1.Carrier_Order__c = obj_CarrierOrder.id;
			t1.Status__c = 'new';
			insert t1;

			BTFacilitator2PlayModeCtrl Ctrl = new BTFacilitator2PlayModeCtrl();
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.playNewOrders();
			Ctrl.playMyOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Plans Confirmed';

			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.fetchEligibleCO();

			// Check that Implementation Stage of Carrier Order is correct
			obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
			System.assertEquals('Plans Confirmed', obj_CarrierOrder.Implementation_Stage__c, 'The implementation stage should be updated to "Plans Confirmed"');

			// Verify ticket creation
			Ticket__c createdTicket = [SELECT Id FROM Ticket__c WHERE Carrier_Order__c = :obj_CarrierOrder.Id LIMIT 1];
			System.assertNotEquals(null, createdTicket, 'A ticket should have been created for the carrier order');
		}
		Test.stopTest();
	}

    @isTest
	static void TestPlayModePlanReview() {
		System.runAs(objUserInOffice) {
			Utils.skipTrigger(true);
			account acc1 = TestUtility.CompanyAccount();
			Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
			opp1.Account = acc1;
			update opp1;

			Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
			boRec.UW_Owner__c = UserInfo.getUserId();
			update borec;

			Carrier__c objCarrier = TestUtility.createTestCarrier('alegeus', 'NY', true);
			Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1', 'CA', true);

			List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
			Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
			obj_CarrierOrder.Carrier__c = objCarrier.Id;
			obj_CarrierOrder.Benefit_Order__c = boRec.id;
			Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
			obj_CarrierOrder.RecordTypeId = rectype;
			obj_CarrierOrder.Renewal_Date__c = date.today();
			obj_CarrierOrder.Benefit_Types__c = 'HSA';
			obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
			obj_CarrierOrder.Start_Date__c = date.today();
			obj_CarrierOrder.Facilitator_2_Plan_Build__c = 'N';
			obj_CarrierOrder.Facilitator_2_Plan_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.OwnerId = userinfo.getUserId();
			obj_CarrierOrder.Is_Multi_EIN__c = false;
			list_CO.add(obj_CarrierOrder);

			list_CO.add(
				new Carrier_Order__c(
					Carrier__c = objCarrier1.Id,
					Benefit_Order__c = boRec.id,
					Facilitator_2_Plan_Build__c = 'N',
					RecordTypeId = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId(),
					Renewal_Date__c = date.today(),
					Benefit_Types__c = 'Medical',
					Implementation_Stage__c = 'Implementing Plans',
					Start_Date__c = date.today(),
					OwnerId = userinfo.getUserId(),
					Is_Multi_EIN__c = false,
					OOO_Timestamp__c = system.now()
				)
			);
			insert list_CO;

			list<Carrier_Order__c> CO = new List<Carrier_Order__c>();
			CO.add(obj_CarrierOrder);

			Ticket__c t1 = new Ticket__c();
			t1.Carrier_Order__c = obj_CarrierOrder.id;
			t1.Status__c = 'new';
			insert t1;

			Test.startTest();
			BTFacilitator2PlayModeCtrl Ctrl = new BTFacilitator2PlayModeCtrl();
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.playNewOrders();
			Ctrl.playMyOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();
			Ctrl.playMyOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Plans Confirmed';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();
			Ctrl.playMyOrders();

			Ctrl.fetchEligibleCO();
			Test.stopTest();

			// Check that Implementation Stage of Carrier Order is correct
			obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
			System.assertEquals('Plans Confirmed', obj_CarrierOrder.Implementation_Stage__c, 'The implementation stage should be updated to "Plans Confirmed"');

			// Assert that a ticket was created for the carrier order
			Ticket__c createdTicket = [SELECT Id, Status__c FROM Ticket__c WHERE Carrier_Order__c = :obj_CarrierOrder.Id LIMIT 1];
			System.assertNotEquals(null, createdTicket, 'A ticket should have been created for the carrier order');
			System.assertEquals('New', createdTicket.Status__c, 'The ticket status should be "New"');
		}
	}

    @isTest
	static void TestPlayModePlanReviewPlanBuild() {
		System.runAs(objUserInOffice) {
			Utils.skipTrigger(true);
			account acc1 = TestUtility.CompanyAccount();
			Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
			opp1.Account = acc1;
			update opp1;

			Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
			boRec.UW_Owner__c = UserInfo.getUserId();
			update borec;

			Carrier__c objCarrier = TestUtility.createTestCarrier('alegeus', 'NY', true);
			Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1', 'CA', true);

			List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
			Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
			obj_CarrierOrder.Carrier__c = objCarrier.Id;
			obj_CarrierOrder.Benefit_Order__c = boRec.id;
			Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
			obj_CarrierOrder.RecordTypeId = rectype;
			obj_CarrierOrder.Renewal_Date__c = date.today();
			obj_CarrierOrder.Benefit_Types__c = 'HSA';
			obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
			obj_CarrierOrder.Start_Date__c = date.today();
			obj_CarrierOrder.Facilitator_2_Plan_Build__c = 'Y';
			obj_CarrierOrder.Facilitator_2_Plan_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = objUserOutofOffice.Id;
			obj_CarrierOrder.OwnerId = userinfo.getUserId();
			obj_CarrierOrder.Is_Multi_EIN__c = false;
			list_CO.add(obj_CarrierOrder);

			list_CO.add(
				new Carrier_Order__c(
					Carrier__c = objCarrier1.Id,
					Benefit_Order__c = boRec.id,
					Facilitator_2_Plan_Build__c = 'Y',
					RecordTypeId = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId(),
					Renewal_Date__c = date.today(),
					Benefit_Types__c = 'Medical',
					Implementation_Stage__c = 'Implementing Plans',
					Start_Date__c = date.today(),
					OwnerId = userinfo.getUserId(),
					Is_Multi_EIN__c = false,
					OOO_Timestamp__c = system.now()
				)
			);
			insert list_CO;

			list<Carrier_Order__c> CO = new List<Carrier_Order__c>();
			CO.add(obj_CarrierOrder);

			Ticket__c t1 = new Ticket__c();
			t1.Carrier_Order__c = obj_CarrierOrder.id;
			t1.Status__c = 'new';
			insert t1;

			Test.startTest();
			BTFacilitator2PlayModeCtrl Ctrl = new BTFacilitator2PlayModeCtrl();
			Ctrl.checkStatusOfCarrierOrders();

			Ctrl.playNewOrders();
			Ctrl.playMyOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();
			Ctrl.playMyOrders();

			obj_CarrierOrder.Implementation_Stage__c = 'Plans Confirmed';
			update obj_CarrierOrder;
			Ctrl.checkStatusOfCarrierOrders();
			Ctrl.playMyOrders();

			Ctrl.fetchEligibleCO();
			Test.stopTest();

			// Check that Implementation Stage of Carrier Order is correct
			obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
			System.assertEquals('Plans Confirmed', obj_CarrierOrder.Implementation_Stage__c, 'The implementation stage should be updated to "Plans Confirmed"');

			// Assert that a ticket was created for the carrier order
			Ticket__c createdTicket = [SELECT Id, Status__c FROM Ticket__c WHERE Carrier_Order__c = :obj_CarrierOrder.Id LIMIT 1];
			System.assertNotEquals(null, createdTicket, 'A ticket should have been created for the carrier order');
			System.assertEquals('New', createdTicket.Status__c, 'The ticket status should be "New"');
		}
	}
}