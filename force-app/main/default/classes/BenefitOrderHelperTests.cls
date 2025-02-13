@isTest
public class BenefitOrderHelperTests {
	@testSetup
	static void setup() {
		BenefitOrderHelperTests.skipTrigger(true);

		User systemAdminUser = [SELECT ID FROM User WHERE ID = :UserInfo.getUserId()];
		User objAdminUser;
		System.runAs(systemAdminUser) {
			objAdminUser = new TestDataFactory.UserBuilder()
				.setAlias('testo')
				.setEmail('testAdvocate@test.com')
				.setUserName('Implementation.Advocate@Advocate.Implementation')
				.setEmailEncoding('UTF-8')
				.setFirstName('Implementation')
				.setLastName('Advocate')
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setTimeZoneSidKey('America/Los_Angeles')
				.setProfileId(UserInfo.getProfileId())
				.setExemptfromValidationRules(true)
				.build();
			objAdminUser.Phone = '(555) 555-1234';
			insert objAdminUser;
		}

		List<Contact> list_Contacts = new List<Contact>();
		List<OpportunityContactRole> list_OppContactsRole = new List<OpportunityContactRole>();
		Id idRT = ContactUtil.COMPANY_CONTACT_RT_ID;
		//Create carrier record.
		Carrier__c objCarrier = TestUtility.createTestCarrier('Carrier', 'CA', false);
		objCarrier.Composite_Rated__c = 'Y';
		insert objCarrier;

		Opportunity objOppRenewal = TestUtility.BenefitsRenewalOpportunity();
		objOppRenewal.numberOfEmployees__c = 5;
		objOppRenewal.HI_Effective_Date__c = Date.today().addDays(2);
		objOppRenewal.Benefits_Current_Setup_Step__c = 'Verifying Eligibility';
		update objOppRenewal;

		Opportunity objOpportunityNewPlan = TestUtility.BenefitsNewPlanOpportunity();
		//Update Opportunity record
		objOpportunityNewPlan.numberOfEmployees__c = 5;
		objOpportunityNewPlan.HI_Effective_Date__c = Date.today().addDays(5);
		objOpportunityNewPlan.Benefits_Current_Setup_Step__c = 'Verifying Eligibility';
		update objOpportunityNewPlan;

		Opportunity objBenefitBYBOpportunity = TestUtility.getNewOpportunity('Benefits BYOB', objOpportunityNewPlan.AccountId);

		System.runAs(objAdminUser) {
			Account objAccount = new Account(Id = objOpportunityNewPlan.AccountId, EE_Active_Count_Panda__c = 10);
			update objAccount;
		}

		//Create New Plan Benefit Order
		Benefit_Order__c objBenefitOrderNewPlan = TestUtility.createTestBenefitOrder('New Plan', objOpportunityNewPlan.Id, 'Test Benefit Order New Plan', false);
		objBenefitOrderNewPlan.Account__c = objOpportunityNewPlan.AccountId;
		objBenefitOrderNewPlan.Coverage_Effective_Date__c = System.today().addDays(-10);
		objBenefitOrderNewPlan.OwnerId = objAdminUser.Id;
		insert objBenefitOrderNewPlan;

		//Create New Plan Carrier Order
		Carrier_Order__c objCarrierOrderNewPlan = new Carrier_Order__c();
		objCarrierOrderNewPlan.Carrier__c = objCarrier.Id;
		objCarrierOrderNewPlan.Benefit_Order__c = objBenefitOrderNewPlan.id;
		objCarrierOrderNewPlan.Name = 'Test CarrierORderHandlerTest';
		objCarrierOrderNewPlan.RecordtypeId = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		objCarrierOrderNewPlan.Order_Assignment__c = 'New To Gusto';
		objCarrierOrderNewPlan.Benefit_Types__c = 'Test';
		insert objCarrierOrderNewPlan;

		//Create Benefit BOR Oppoertunity
		Opportunity objBOROpportunity = TestUtility.BenefitsBoROpportunity();
		objBOROpportunity.Id_And_Source_Id__c = 'Id=>12345,Source_ID__c=>125';
		objBOROpportunity.HI_Effective_Date__c = Date.today().addDays(4);
		update objBOROpportunity;

		Benefit_Order__c objBenefitOrder = TestUtility.createTestBenefitOrder('Benefits BoR', objBOROpportunity.Id, 'Test Benefit Order', false);
		objBenefitOrder.BoR_Id__c = '1123';
		objBenefitOrder.Order_Status__c = 'Ready for Qualification';
		objBenefitOrder.Application_Status__c = 'Forms Signed';
		objBenefitOrder.OwnerId = objAdminUser.Id;
		insert objBenefitOrder;

		//Create Change benefit Order
		Account objAccChange = new Account(Name = 'test acc2', ZP_Company_Id__c = '100989002');

		Opportunity objOpportunityChange = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change'));
		objOpportunityChange.AccountId = objAccChange.Id;
		objOpportunityChange.StageName = 'SAL';
		objOpportunityChange.Name = 'test';
		objOpportunityChange.closeDate = System.today();
		objOpportunityChange.Id_And_Source_Id__c = 'Id=>12345,Source_ID__c=>125';
		objOpportunityChange.HI_Effective_Date__c = Date.today().addDays(3);
		insert objOpportunityChange;

		Benefit_Order__c objBenefitOrderChange = TestUtility.createTestBenefitOrder('Change', objOpportunityChange.Id, 'Test Change Benefit Order', false);
		objBenefitOrderChange.OwnerId = objAdminUser.Id;
		objBenefitOrderChange.Account__c = objAccChange.Id;
		insert objBenefitOrderChange;

		Benefit_Order__c objBenefitOrderBYB = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB'))
			.setName('New BYB')
			.setAccount(objBenefitBYBOpportunity.AccountId)
			.setOpp(objBenefitBYBOpportunity.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenefitOrderBYB;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits BYB')
			.setSubject('Test Benefits BYB')
			.setAccountId(objOpportunityNewPlan.AccountId)
			.setOpportunity(objOpportunityNewPlan.Id)
			.setBenefitOrder(objBenefitOrderBYB.Id)
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testunauthorized@gmail.com')
			.setDescription('Test Benefits BYB')
			.setAudience('Employee')
			.setReason('BYB General')
			.build();
		insert objCase;

		//Create Change Carrier Order
		Carrier_Order__c objCarrierOrderChange = new Carrier_Order__c();
		objCarrierOrderChange.Carrier__c = objCarrier.Id;
		objCarrierOrderChange.Benefit_Order__c = objBenefitOrderChange.Id;
		objCarrierOrderChange.Name = 'Test CarrierORderHandlerTest';
		objCarrierOrderChange.RecordtypeId = cache.getRecordTypeId('Carrier_Order__c', 'Benefit Change');
		objCarrierOrderChange.Order_Assignment__c = 'New To Gusto';
		objCarrierOrderChange.Benefit_Types__c = 'Test';
		insert objCarrierOrderChange;

		//Create Contact records
		list_Contacts.add(
			new Contact(FirstName = 'Test', LastName = 'User01', recordTypeId = idRT, AccountId = objOpportunityNewPlan.AccountId, Email = 'testuser01@gusto.com', Zp_User_Id__c = '75001')
		);

		list_Contacts.add(
			new Contact(FirstName = 'Test', LastName = 'User02', recordTypeId = idRT, AccountId = objOpportunityChange.AccountId, Email = 'testuser02@gusto.com', Zp_User_Id__c = '75002')
		);

		list_Contacts.add(new Contact(FirstName = 'Test', LastName = 'User03', recordTypeId = idRT, AccountId = objOppRenewal.AccountId, Email = 'testuser03@gusto.com', Zp_User_Id__c = '75003'));

		list_Contacts.add(new Contact(FirstName = 'Test', LastName = 'User04', recordTypeId = idRT, AccountId = objBOROpportunity.AccountId, Email = 'testuser04@gusto.com', Zp_User_Id__c = '75004'));
		insert list_Contacts;

		//Create Opportunity Contact Role.

		list_OppContactsRole.add(
			new OpportunityContactRole(ContactId = list_Contacts[0].Id, OpportunityId = objOpportunityNewPlan.Id, IsPrimary = true, Check_Additional_POC__c = false, Role = 'Benefits Admin')
		);

		list_OppContactsRole.add(
			new OpportunityContactRole(ContactId = list_Contacts[1].Id, OpportunityId = objOpportunityChange.Id, IsPrimary = true, Check_Additional_POC__c = true, Role = 'Benefits Admin')
		);

		list_OppContactsRole.add(
			new OpportunityContactRole(ContactId = list_Contacts[2].Id, OpportunityId = objOppRenewal.Id, IsPrimary = true, Check_Additional_POC__c = true, Role = 'Benefits Admin')
		);

		list_OppContactsRole.add(
			new OpportunityContactRole(ContactId = list_Contacts[3].Id, OpportunityId = objBOROpportunity.Id, IsPrimary = true, Check_Additional_POC__c = true, Role = 'Benefits Admin')
		);

		insert list_OppContactsRole;
		BenefitOrderHelperTests.skipTrigger(false);
	}

	@isTest
	static void testCreateBOR() {
		Test.startTest();
		BenefitOrderHelperTests.skipTrigger(true);
		List<OpportunityContactRole> list_OppContactRoles = new List<OpportunityContactRole>();
		List<Contact> list_Contacts = [SELECT Id FROM Contact LIMIT 2];

		HI_BOR_Transfer__c objHIBOR = new HI_BOR_Transfer__c();
		objHIBOR.Benefit_Types__c = '["dca", "vision", "short_term_disability", "long_term_disability", "medical", "dental", "fsa", "hsa", "hra", "commuter", "life"]';
		objHIBOR.Id__c = '11234';
		objHIBOR.Status__c = 'form_created';
		objHIBOR.Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "dca"=>"Zenefits", "commuter"=>"Wage Works", "hsa"=>"Zenefits"}, "title"=>"President", "effective_month"=>6, "effective_month_same_as_medical"=>"no", "effective_month_fsa"=>5, "effective_month_dca"=>5}';
		insert objHIBOR;

		//Create Benefit BOR Oppoertunity
		Opportunity objBOROpportunity = TestUtility.BenefitsBoROpportunity();
		objBOROpportunity.OwnerId = BenefitOrderUtil.LOGGED_IN_USER_ID;
		update objBOROpportunity;

		list_OppContactRoles.add(new OpportunityContactRole(ContactId = list_Contacts[0].Id, OpportunityId = objBOROpportunity.Id, IsPrimary = true, Role = 'Benefits Signatory'));

		list_OppContactRoles.add(
			new OpportunityContactRole(ContactId = list_Contacts[1].Id, OpportunityId = objBOROpportunity.Id, IsPrimary = false, Check_Additional_POC__c = true, Role = 'Benefits Signatory')
		);
		insert list_OppContactRoles;
		BenefitOrderHelperTests.skipTrigger(false);

		Benefit_Order__c objBenefitOrderBOR = TestUtility.createTestBenefitOrder('Benefits BoR', objBOROpportunity.Id, 'Test Benefit Order', false);
		objBenefitOrderBOR.BoR_Id__c = '11235';
		objBenefitOrderBOR.Order_Status__c = 'Ready for Qualification';
		objBenefitOrderBOR.Application_Status__c = 'Forms Signed';
		insert objBenefitOrderBOR;

		Test.stopTest();

		objBenefitOrderBOR = [SELECT Id, OwnerId FROM Benefit_Order__c WHERE Id = :objBenefitOrderBOR.Id LIMIT 1];
		Case ObjCase = [SELECT Id, RecordType.Name FROM Case WHERE Benefit_Order__c = :objBenefitOrderBOR.Id LIMIT 1];

		System.assertEquals('Benefits BoR', ObjCase.RecordType.Name, 'Incorrect RecordType');
		System.assertEquals(objBOROpportunity.OwnerId, objBenefitOrderBOR.OwnerId, 'Incorrect OwnerId');
	}

	@isTest
	static void testCreateChangeBO() {
		BenefitOrderHelperTests.skipTrigger(true);
		List<OpportunityContactRole> list_OppContactRoles = new List<OpportunityContactRole>();
		Account objAcc = TestUtility.CompanyAccount();
		Opportunity objOpp = TestUtility.getNewOpportunity('Benefits Renewal', objAcc.Id);
		List<Contact> list_Contacts = [SELECT Id FROM Contact LIMIT 2];

		//Create TTF record.
		Id idTTFRecordType = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
		Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpp.AccountId, list_Contacts[0].Id, objOpp.Id, idTTFRecordType, true);

		list_OppContactRoles.add(new OpportunityContactRole(ContactId = list_Contacts[0].Id, OpportunityId = objOpp.Id, IsPrimary = true, Role = 'Benefits Signatory'));

		list_OppContactRoles.add(
			new OpportunityContactRole(ContactId = list_Contacts[1].Id, OpportunityId = objOpp.Id, IsPrimary = false, Check_Additional_POC__c = true, Role = 'Benefits Signatory')
		);
		insert list_OppContactRoles;

		BenefitOrderHelperTests.skipTrigger(false);

		Test.startTest();

		Benefit_Order__c objBOChange = (Benefit_Order__c) Benefit_Order__c.SObjectType.newSObject();
		objBOChange.Name = 'TEST BENEFIT ORDER2';
		objBOChange.RecordTypeId = BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID;
		objBOChange.Opportunity__c = objOpp.id;
		objBOChange.Coverage_Effective_Date__c = System.today().addDays(-120);
		objBOChange.Order_Status__c = 'Ready for Qualification';
		objBOChange.Account__c = objOpp.AccountId;
		objBOChange.Prioritized_Customer__c = true;
		insert objBOChange;

		Test.stopTest();

		Case ObjCase = [SELECT Id, RecordType.Name FROM Case WHERE Benefit_Order__c = :objBOChange.Id LIMIT 1];
		System.assertEquals('Benefits Change Case', ObjCase.RecordType.Name, 'Incorrect RecordType');
	}

	@isTest
	static void testCreateNewPlanBO() {
		BenefitOrderHelperTests.skipTrigger(true);
		List<OpportunityContactRole> list_OppContactRoles = new List<OpportunityContactRole>();
		Opportunity objOppNewPlan = TestUtility.BenefitsNewPlanOpportunity();
		List<Contact> list_Contacts = [SELECT Id FROM Contact LIMIT 2];
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c LIMIT 1];

		//Create TTF record.
		Id idTTFRecordType = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOppNewPlan.AccountId, list_Contacts[0].Id, objOppNewPlan.Id, idTTFRecordType, true);

		list_OppContactRoles.add(new OpportunityContactRole(ContactId = list_Contacts[0].Id, OpportunityId = objOppNewPlan.Id, IsPrimary = true, Role = 'Benefits Signatory'));

		list_OppContactRoles.add(
			new OpportunityContactRole(ContactId = list_Contacts[1].Id, OpportunityId = objOppNewPlan.Id, IsPrimary = false, Check_Additional_POC__c = true, Role = 'Benefits Signatory')
		);
		insert list_OppContactRoles;

		BenefitOrderHelperTests.skipTrigger(false);

		Test.startTest();

		Benefit_Order__c objBONewPlan = (Benefit_Order__c) Benefit_Order__c.SObjectType.newSObject();
		objBONewPlan.Name = 'TEST BENEFIT ORDER2';
		objBONewPlan.RecordTypeId = BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID;
		objBONewPlan.Opportunity__c = objOppNewPlan.id;
		objBONewPlan.Coverage_Effective_Date__c = System.today().addDays(-120);
		objBONewPlan.Order_Status__c = 'Ready for Qualification';
		objBONewPlan.Account__c = objOppNewPlan.AccountId;
		objBONewPlan.Prioritized_Customer__c = true;
		insert objBONewPlan;

		Test.stopTest();

		Case ObjCase = [SELECT Id, RecordType.Name FROM Case WHERE Benefit_Order__c = :objBONewPlan.Id LIMIT 1];
		System.assertEquals('Benefits New Plan Case', ObjCase.RecordType.Name, 'Incorrect RecordType');
	}

	@isTest
	static void testCreateRenewalBO() {
		Test.startTest();
		Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID];

		Benefit_Order__c objBO = (Benefit_Order__c) Benefit_Order__c.SObjectType.newSObject();
		objBO.Name = 'TEST BENEFIT ORDER2';
		objBO.RecordTypeId = BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID;
		objBO.Opportunity__c = objOpp.id;
		objBO.Coverage_Effective_Date__c = System.today().addDays(-120);
		objBO.Order_Status__c = 'Ready for Qualification';
		objBO.Account__c = objOpp.AccountId;
		objBO.Prioritized_Customer__c = true;
		insert objBO;

		Test.stopTest();

		Case ObjCase = [SELECT Id, RecordType.Name FROM Case WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		System.assertEquals('Benefits Renewal Case', ObjCase.RecordType.Name, 'Incorrect RecordType');
	}

	@isTest
	static void testCreateRenewalAlignmentBO() {
		Test.startTest();
		Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID];

		Benefit_Order__c objBO = (Benefit_Order__c) Benefit_Order__c.SObjectType.newSObject();
		objBO.Name = 'TEST BENEFIT ORDER2';
		objBO.RecordTypeId = BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID;
		objBO.Opportunity__c = objOpp.id;
		objBO.Coverage_Effective_Date__c = System.today().addDays(-120);
		objBO.Account__c = objOpp.AccountId;
		objBO.Prioritized_Customer__c = true;
		insert objBO;

		Test.stopTest();

		Case ObjCase = [SELECT Id, RecordType.Name FROM Case WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		System.assertEquals('Benefits Renewal Case', ObjCase.RecordType.Name, 'Incorrect RecordType');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : When order Status on BO Is changed then It will reflect on CO as well
	 */
	@isTest
	static void testBOStatusReflectedOnCO() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [
			SELECT Id, Order_Status__c, OwnerId, Coverage_Effective_Date__c, Open_Enrollment_Start_Date__c, Open_Enrollment_End_Date__c, Push_Rate_Reason__c
			FROM Benefit_Order__c
			WHERE Name = 'Test Benefit Order New Plan'
			LIMIT 1
		];

		BenefitOrderHelper.statusHistoryProcessed = false;
		objBenefitOrder.Order_Status__c = 'OE Verification/Checking Participation';
		objBenefitOrder.OwnerId = BenefitOrderUtil.LOGGED_IN_USER_ID;
		objBenefitOrder.Coverage_Effective_Date__c = System.today();
		objBenefitOrder.Open_Enrollment_Start_Date__c = System.today();
		objBenefitOrder.Open_Enrollment_End_Date__c = System.today();
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Test.stopTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c, Effective_Date_Change__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBenefitOrder.Id LIMIT 1];
		System.assertEquals(objCarrierOrder.Implementation_Stage__c, 'OE Verification/Checking Participation', 'Incorrect Result');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : When order Status changed to Plan Reveiw Sent, then Plan_Reviews_Sent_Date__c is Populated
	 */
	@isTest
	static void testUpdateOrderStatusPlanReviewSent() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order' LIMIT 1];

		objBenefitOrder.Order_Status__c = 'Plan Review Sent';
		update objBenefitOrder;

		Test.stopTest();

		objBenefitOrder = [SELECT Id, Plan_Reviews_Sent_Date__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id LIMIT 1];
		System.assertNotEquals(null, objBenefitOrder.Plan_Reviews_Sent_Date__c, 'Plan review sent date cannot be null');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : When order Status changed to Enrollment Review Sent, then Plan_Reviews_Sent_Date__c is Populated
	 */
	@isTest
	static void testUpdateOrderStatusEnrollmentReviewSent() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order' LIMIT 1];

		objBenefitOrder.Order_Status__c = 'Enrollment Review Sent';
		update objBenefitOrder;

		Test.stopTest();

		objBenefitOrder = [SELECT Id, Enrollment_Review_Sent_Date__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id LIMIT 1];
		System.assertNotEquals(null, objBenefitOrder.Enrollment_Review_Sent_Date__c, 'Enrollment review sent date cannot be null');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : When BOR is Canceled, then BOR_Implementation_End_Date__c field on Opportunity is Populated
	 */
	@isTest
	static void testCancelBenefitOrderBOR() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c, Opportunity__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order' LIMIT 1];

		objBenefitOrder.Order_Status__c = 'Canceled';
		update objBenefitOrder;

		Test.stopTest();

		Opportunity objOpp = [SELECT Id, BOR_Implementation_End_Date__c FROM Opportunity WHERE Id = :objBenefitOrder.Opportunity__c LIMIT 1];
		System.assertNotEquals(null, objOpp.BOR_Implementation_End_Date__c, 'Date cannot be null');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : When BOR is Closed Admin, then Opportunity is also Closed Admin
	 */
	@isTest
	static void testClosedAdminBenefitOrderBOR() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c, Opportunity__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order' LIMIT 1];

		objBenefitOrder.Order_Status__c = 'Closed Admin';
		update objBenefitOrder;

		Test.stopTest();

		Opportunity objOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :objBenefitOrder.Opportunity__c LIMIT 1];
		System.assertEquals('Closed Admin', objOpp.StageName, 'Incorrect StageName');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : When Change BO is Closed Admin, then Opportunity is also Closed Admin
	 */
	@isTest
	static void testClosedAdminBenefitOrderChange() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, OwnerId, Opportunity__c FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];

		User objAdminUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];

		BenefitOrderHelperTests.skipTrigger(true);
		Ticket__c objTicket = new Ticket__c();
		objTicket.Benefit_Order__c = objBO.Id;
		objTicket.Status__c = 'New';
		objTicket.OwnerId = objAdminUser.Id;
		objTicket.Escalation_Reason__c = null;
		objTicket.Escalation_Reason_Detail__c = null;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
		objTicket.Status__c = 'Closed';
		insert objTicket;
		BenefitOrderHelperTests.skipTrigger(false);

		Opportunity objOppty = new Opportunity();
		objOppty.Id = objBO.Opportunity__c;
		objOppty.Closed_Lost_Detail__c = 'Other details';
		update objOppty;

		objBO.Order_Status__c = 'Closed Admin';
		objBO.Status_Detail__c = 'Other';
		objBO.Additional_Details__c = 'Test';
		update objBO;
		Test.stopTest();

		Opportunity objOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :objBO.Opportunity__c LIMIT 1];
		System.assertEquals('Closed Admin', objOpp.StageName, 'Incorrect StageName');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : When BO is Reopen, then Case Onboarding_Close_DateTime__c is set to be null
	 */
	@isTest
	static void testReOpenCancelBenefitOrderBOR() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c, Opportunity__c, Account__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order New Plan' LIMIT 1];
		Contact objCon = [SELECT Id, AccountId FROM Contact WHERE AccountId = :objBenefitOrder.Account__c LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];
		BenefitOrderHelperTests.skipTrigger(true);

		//Create New Plan case
		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		objCase.AccountId = objCon.AccountId;
		objCase.ContactId = objCon.Id;
		objCase.Subject = 'Test Relation';
		objCase.Description = 'Test Relation';
		objCase.SuppliedEmail = 'CasetriggerHelper@gusto.com';
		objCase.Type = 'New Plan';
		objCase.Opportunity__c = objBenefitOrder.Opportunity__c;
		ObjCase.Benefit_Order__c = objBenefitOrder.Id;
		objCase.Origin = 'Hippo';
		objCase.Status = CaseUtils.STATUS_NEW;
		objCase.Integration_Id__c = 'hippo-Benefits_New_Plan-' + objBenefitOrder.Opportunity__c;
		objCase.OwnerId = objUser.Id;
		insert objCase;

		objBenefitOrder.Order_Status__c = 'Canceled';
		objBenefitOrder.Status_Detail__c = 'Effective Date Not Supported';
		update objBenefitOrder;

		BenefitOrderHelperTests.skipTrigger(false);

		objBenefitOrder.Order_Status__c = BenefitOrderUtil.STATUS_APPROVED;
		update objBenefitOrder;

		Test.stopTest();

		ObjCase = [SELECT Id, Onboarding_Close_DateTime__c FROM Case WHERE Benefit_Order__c = :objBenefitOrder.Id LIMIT 1];
		System.assertEquals(null, ObjCase.Onboarding_Close_DateTime__c, 'Onboarding_Close_DateTime__c cannot be null');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : on change of Opporttunity Coverage effevtive date is also changed
	 */
	@isTest
	static void testChangeOpportunity() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Opportunity__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order' LIMIT 1];

		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id != :objBenefitOrder.Opportunity__c LIMIT 1];
		objBenefitOrder.Opportunity__c = objOpp.Id;
		update objBenefitOrder;

		Test.stopTest();

		objBenefitOrder = [SELECT Id, Coverage_Effective_Date__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id LIMIT 1];
		System.assertEquals(objOpp.HI_Effective_Date__c, objBenefitOrder.Coverage_Effective_Date__c, 'Inavlid Date');
	}

	@isTest
	static void testChangeOwnerId() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, OwnerId, Opportunity__c, Account__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order' LIMIT 1];
		Contact objCon = [SELECT Id, AccountId FROM Contact WHERE AccountId = :objBenefitOrder.Account__c LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];
		BenefitOrderHelperTests.skipTrigger(true);

		//Create New Plan case
		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits BoR');
		objCase.AccountId = objCon.AccountId;
		objCase.ContactId = objCon.Id;
		objCase.Subject = 'Test Relation';
		objCase.Description = 'Test Relation';
		objCase.SuppliedEmail = 'CasetriggerHelper@gusto.com';
		objCase.Type = 'BoR';
		objCase.Opportunity__c = objBenefitOrder.Opportunity__c;
		ObjCase.Benefit_Order__c = objBenefitOrder.Id;
		objCase.Origin = 'Hippo';
		objCase.Status = CaseUtils.STATUS_NEW;
		objCase.Integration_Id__c = 'hippo-Benefits_New_Plan-' + objBenefitOrder.Opportunity__c;
		objCase.OwnerId = objUser.Id;
		insert objCase;
		BenefitOrderHelperTests.skipTrigger(false);

		objBenefitOrder.OwnerId = BenefitOrderUtil.LOGGED_IN_USER_ID;
		update objBenefitOrder;
		Test.stopTest();

		ObjCase = [SELECT Id, OwnerId FROM Case WHERE Benefit_Order__c = :objBenefitOrder.Id LIMIT 1];
		System.assertEquals(BenefitOrderUtil.LOGGED_IN_USER_ID, ObjCase.OwnerId, 'Incorrect Owner');
	}

	@isTest
	static void testFullfiledBO() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order New Plan' LIMIT 1];

		objBenefitOrder.Order_Status__c = BenefitOrderUtil.STATUS_FULFILLED;
		update objBenefitOrder;
		Test.stopTest();

		objBenefitOrder = [SELECT Id, Order_Fulfilled_Timestamp__c, EE_at_Fulfillment__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id LIMIT 1];
		System.assertNotEquals(null, objBenefitOrder.Order_Fulfilled_Timestamp__c, 'Error');
		System.assertEquals(10, objBenefitOrder.EE_at_Fulfillment__c, 'Incorrect Result');
	}
    
    @isTest
	static void testFullfiledBOBYB() {  
		//BYB Records
        BenefitOrderHelperTests.skipTrigger(true);
        BenefitOrderHelper.skipTrigger = false;
        Account objAccBYB = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test acc3').build();
		insert objAccBYB;
        Opportunity objOpportunityBYB = new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits BYOB'))
            .setName('Company Opp')
            .setAccountId(objAccBYB.Id)
            .setStage('Open')
            .setCloseDate(System.today())
            .build();
		insert objOpportunityBYB;
        Benefit_Order__c objBenefitOrderBYB = new TestDataFactory.BenefitOrderBuilder()
            .setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB'))
            .setName('New BYB')
            .setAccount(objAccBYB.Id)
            .setOpp(objOpportunityBYB.Id)
            .setCoverageEffectiveDate(System.today())
            .setSubmissionDeadline(System.today())
            .setOwnerID(UserInfo.getUserId())
            .build();
		insert objBenefitOrderBYB;
        Contact c = [SELECT ID FROM Contact Limit 1];
        Case caseToUpdate = [SELECT Id, ContactId FROM Case WHERE Benefit_Order__c = :objBenefitOrderBYB.Id LIMIT 1];
		caseToUpdate.ContactId = c.Id;
        update caseToUpdate;
        Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
        config.Send_BYB_Survey_After__c = 14;
        upsert config;
		Test.startTest();

		objBenefitOrderBYB.Order_Status__c = BenefitOrderUtil.STATUS_FULFILLED;
		update objBenefitOrderBYB;
		Test.stopTest();

		Case orderCase = [SELECT Id, Onboarding_Close_DateTime__c, Status, Send_Survey__c FROM Case WHERE Benefit_Order__c = :objBenefitOrderBYB.Id LIMIT 1];
		Assert.areNotEqual(null, orderCase.Onboarding_Close_DateTime__c, 'It should not be null');
        Assert.areEqual(true, orderCase.Send_Survey__c, 'It should be true');
		Assert.areNotEqual(CaseUtils.STATUS_CLOSED, orderCase.Status, 'It should not be closed');

	}

	@isTest
	static void testUpdatePushRateReasonDateBO() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Coverage_Effective_Date__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order New Plan' LIMIT 1];

		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;
		Test.stopTest();

		objBenefitOrder = [SELECT Id, IsCoverageEffectiveDateChanged__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id LIMIT 1];
		System.assertEquals(false, objBenefitOrder.IsCoverageEffectiveDateChanged__c, 'Incorrect Result');
	}

	@isTest
	static void testReOpenFulfilledBO() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c, Opportunity__c, Account__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order New Plan' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];
		Contact objCon = [SELECT Id, AccountId FROM Contact WHERE AccountId = :objBenefitOrder.Account__c LIMIT 1];
		BenefitOrderHelperTests.skipTrigger(true);

		//Create New Plan case
		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		objCase.AccountId = objCon.AccountId;
		objCase.ContactId = objCon.Id;
		objCase.Subject = 'Test Relation';
		objCase.Description = 'Test Relation';
		objCase.SuppliedEmail = 'CasetriggerHelper@gusto.com';
		objCase.Type = 'New Plan';
		objCase.Opportunity__c = objBenefitOrder.Opportunity__c;
		ObjCase.Benefit_Order__c = objBenefitOrder.Id;
		objCase.Origin = 'Hippo';
		objCase.Status = CaseUtils.STATUS_NEW;
		objCase.Integration_Id__c = 'hippo-Benefits_New_Plan-' + objBenefitOrder.Opportunity__c;
		objCase.OwnerId = objUser.Id;
		insert objCase;
		BenefitOrderHelperTests.skipTrigger(false);

		objBenefitOrder.Order_Status__c = BenefitOrderUtil.STATUS_FULFILLED;
		update objBenefitOrder;

		objBenefitOrder.Order_Status__c = BenefitOrderUtil.STATUS_APPROVED;
		update objBenefitOrder;
		Test.stopTest();

		objCase = [SELECT Id, Status FROM Case WHERE Benefit_Order__c = :objBenefitOrder.Id LIMIT 1];
		System.assertNotEquals(CaseUtils.STATUS_CLOSED, objCase.Status, 'Incorrect Status');
	}

	@isTest
	static void testBOStatusMovedBackToRFQ() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order New Plan' LIMIT 1];

		objBenefitOrder.Order_Status__c = 'Qualification';
		objBenefitOrder.Qualification_Follow_Up_Date__c = System.today().addDays(3);
		update objBenefitOrder;
		Test.stopTest();

		objBenefitOrder = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id LIMIT 1];
		System.assertEquals('Ready for Qualification', objBenefitOrder.Order_Status__c, 'Incorrect Status');
	}

	@isTest
	static void testBlockedBO() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Benefit Order New Plan' LIMIT 1];

		objBenefitOrder.Order_Status__c = 'Blocked';
		objBenefitOrder.Blocked_Reason__c = 'Carrier Delay';
		update objBenefitOrder;
		Test.stopTest();

		objBenefitOrder = [SELECT Id, Blocked_Date__c, Blocked__c, Unblocked_Date__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id LIMIT 1];
		System.assertEquals(true, objBenefitOrder.Blocked__c, 'Incorrect Result');
		System.assertNotEquals(null, objBenefitOrder.Blocked_Date__c, 'Blocked Date Cannot be Null');
		System.assertEquals(null, objBenefitOrder.Unblocked_Date__c, 'Unblocked Date cannot be Null');
	}

	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		CarrierOrderTriggerHelper.skipTrigger = blnFlag;
		HIBorTransferTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		OrdertriggerHelper.SkipTrigger = blnFlag;
		TicketTriggerHelper.skipTrigger = blnFlag;
		BenefitOrderHelper.skipTrigger = blnFlag;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = blnFlag;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check on BO Onwer Change, ticket owner of open ticket should be changed
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testUpdateTicketOwnerOnBOOwnerChange() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, OwnerId FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];

		BenefitOrderHelperTests.skipTrigger(true);
		Ticket__c objTicket = new Ticket__c();
		objTicket.Benefit_Order__c = objBO.Id;
		objTicket.Status__c = 'New';
		objTicket.OwnerId = objUser.Id;
		objTicket.Escalation_Reason__c = null;
		objTicket.Escalation_Reason_Detail__c = null;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
		insert objTicket;

		BenefitOrderHelperTests.skipTrigger(false);
		objBO.OwnerId = BenefitOrderUtil.LOGGED_IN_USER_ID;
		update objBO;
		Test.stopTest();

		List<Ticket__c> list_Ticket = [SELECT Id, OwnerId, RecordTypeId FROM Ticket__c WHERE Benefit_Order__c = :objBO.Id];
		System.assertEquals(BenefitOrderUtil.LOGGED_IN_USER_ID, list_Ticket[0].OwnerId, 'Incorrect Result');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check on BO Onwer Change, ticket owner of closed ticket should not changed
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testTicketOwnerDoesNotChangeIfClosed() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, OwnerId FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];

		BenefitOrderHelperTests.skipTrigger(true);
		Ticket__c objTicket = new Ticket__c();
		objTicket.Benefit_Order__c = objBO.Id;
		objTicket.Status__c = 'New';
		objTicket.OwnerId = objUser.Id;
		objTicket.Escalation_Reason__c = null;
		objTicket.Escalation_Reason_Detail__c = null;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
		objTicket.Status__c = 'Closed';
		insert objTicket;

		BenefitOrderHelperTests.skipTrigger(false);

		/* TicketTriggerHelper.skipTrigger = true;
		objTicket.Status__c = 'Closed';
		update objTicket; */

		objBO.OwnerId = BenefitOrderUtil.LOGGED_IN_USER_ID;
		update objBO;
		Test.stopTest();

		List<Ticket__c> list_Ticket = [SELECT Id, OwnerId, RecordTypeId FROM Ticket__c WHERE Benefit_Order__c = :objBO.Id];
		System.assertNotEquals(BenefitOrderUtil.LOGGED_IN_USER_ID, list_Ticket[0].OwnerId, 'Incorrect Owner');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, if there exist any open ticket for bo then we can not fulfilled the order
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testBenefitOrderStatusDoesNotChangeWithOpenTicket() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, OwnerId FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];

		BenefitOrderHelperTests.skipTrigger(true);
		Ticket__c objTicket = new Ticket__c();
		objTicket.Benefit_Order__c = objBO.Id;
		objTicket.Status__c = 'New';
		objTicket.OwnerId = objUser.Id;
		objTicket.Escalation_Reason__c = null;
		objTicket.Escalation_Reason_Detail__c = null;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
		insert objTicket;

		BenefitOrderHelperTests.skipTrigger(false);

		Boolean blnOpenTicketValidation = false;

		try {
			objBO.Order_Status__c = BenefitOrderUtil.STATUS_FULFILLED;
			Database.update(objBO, true);
		} catch (Exception objExp) {
			blnOpenTicketValidation = objExp.getMessage().contains(BenefitOrderUtil.MSQ_CLOSE_OPEN_TICKET_FIRST) ? true : false;
		}

		Test.stopTest();

		objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		System.assertNotEquals(BenefitOrderUtil.STATUS_FULFILLED, objBO.Order_Status__c, 'Incorrect Status');
		System.assertEquals(true, blnOpenTicketValidation, 'Incorrect Result');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, if there exist any open ticket for bo then we can not Canceled the order
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testBOCanceledStatusDoesNotChangeWithOpenTicket() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, OwnerId FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];

		BenefitOrderHelperTests.skipTrigger(true);
		Ticket__c objTicket = new Ticket__c();
		objTicket.Benefit_Order__c = objBO.Id;
		objTicket.Status__c = 'New';
		objTicket.OwnerId = objUser.Id;
		objTicket.Escalation_Reason__c = null;
		objTicket.Escalation_Reason_Detail__c = null;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
		insert objTicket;

		BenefitOrderHelperTests.skipTrigger(false);

		Boolean blnOpenTicketValidation = false;

		try {
			objBO.Order_Status__c = BenefitOrderUtil.STATUS_CANCELLED;
			Database.update(objBO, true);
		} catch (Exception objExp) {
			blnOpenTicketValidation = objExp.getMessage().contains(BenefitOrderUtil.MSQ_CLOSE_OPEN_TICKET_FIRST) ? true : false;
		}

		Test.stopTest();

		objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		System.assertNotEquals(BenefitOrderUtil.STATUS_CANCELLED, objBO.Order_Status__c, 'Incorrect Order Status');
		System.assertEquals(true, blnOpenTicketValidation, 'Incorrect Status');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, if there exist any Benefits Transfer open ticket for bo then we can fulfilled the order
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testBenefitOrderStatusChangesWithOpenTicket() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, OwnerId FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];

		BenefitOrderHelperTests.skipTrigger(true);
		Ticket__c objTicket = new Ticket__c();
		objTicket.Benefit_Order__c = objBO.Id;
		objTicket.Status__c = 'New';
		objTicket.OwnerId = objUser.Id;
		objTicket.Escalation_Reason__c = null;
		objTicket.Escalation_Reason_Detail__c = null;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
		insert objTicket;
		BenefitOrderHelperTests.skipTrigger(false);

		Boolean blnOpenTicketValidation = false;

		try {
			TicketTriggerHelper.skipTrigger = true;
			objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Transfer');
			update objTicket;

			objBO.Order_Status__c = BenefitOrderUtil.STATUS_FULFILLED;
			Database.update(objBO, true);
		} catch (Exception objExp) {
			blnOpenTicketValidation = objExp.getMessage().contains(BenefitOrderUtil.MSQ_CLOSE_OPEN_TICKET_FIRST) ? true : false;
		}

		Test.stopTest();

		objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		System.assertEquals(BenefitOrderUtil.STATUS_FULFILLED, objBO.Order_Status__c, 'Incorrect Order Status');
		System.assertEquals(false, blnOpenTicketValidation, 'Incorrect Status');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Owner of BYOB benefit order assign to Queue
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testBYBOwerIdQueuePositive() {
		Opportunity objOpportunity;
		for (Opportunity objOpp : [SELECT Id, AccountId, RecordType.Name, StageName FROM Opportunity WHERE RecordType.Name = 'Benefits BYOB']) {
			objOpportunity = objOpp;
		}
		Group objGroupBYB = [SELECT Id, Name FROM Group WHERE Name = 'Benefits BYOB' AND Type = 'Queue'];

		System.runAs(new User(id = BenefitOrderUtil.LOGGED_IN_USER_ID)) {
			QueuesObject objQueues = new QueueSObject(QueueID = objGroupBYB.id, SobjectType = 'Benefit_Order__c');
			insert objQueues;
		}

		Test.startTest();
		skipTrigger(true);
		TransitiontoFulfilmentTriggerHelper.skipTrigger = false;
		BenefitOrderHelper.skipTrigger = false;

		//Get Contact Record.
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
		System.assert(list_Contacts.size() > 0, 'List cannot be null');

		//Create TTF record.
		Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BYB');
		Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contacts[0].Id, objOpportunity.Id, idTTFRecordType, true);
		skipTrigger(false);

		OpportunityTriggerHelper.skipTrigger = true;
		BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
		objBOCreationUtil.strBenefitOrderType = 'New to BYB - OE';
		Map<Id, Transition_To_Fulfillment__c> map_NewTTFRec = new Map<Id, Transition_To_Fulfillment__c>();
		map_NewTTFRec.put(objTTF.Id, objTTF);
		objBOCreationUtil.createBenefitOrder(null, null, map_NewTTFRec, null);

		Test.stopTest();

		List<Transition_to_Fulfillment__c> list_TTFs = [SELECT Id, Benefit_Order__c, RecordType.Name FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
		System.assert(list_TTFs[0].Benefit_Order__c != null, 'List Cannot be null');

		List<Benefit_Order__c> list_BenefitOrders = [SELECT Id, OwnerId, RecordType.Name FROM Benefit_Order__c WHERE Id = :list_TTFs[0].Benefit_Order__c];
		System.assertEquals(list_BenefitOrders[0].OwnerId, objGroupBYB.Id, 'List cannot be null');
	}
	/**
	 * @Author      : Anurag Gautam
	 * @Description : Test Method to check FeatureManagement
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testFeatureManagementPermission() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, OwnerId FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE Username = 'Implementation.Advocate@Advocate.Implementation' LIMIT 1];
		TestDataFactory.createFeatureManagementPermission('Bypass_Triggers', objUser.Id);
		System.runAs(objUser) {
			update objBO;
		}
		PermissionSetAssignment objPermissionSetAssignment = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :objUser.Id LIMIT 1];
		System.assertEquals(objUser.Id, objPermissionSetAssignment.AssigneeId, 'Incorrect Result');
	}

	/**
	 * @Author      : Bhagat Singh 
	 * @Description : Test Method to closed connect-broker cases
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void closedConnectBrokerCases() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, OwnerId FROM Benefit_Order__c WHERE RecordType.Name = 'Benefits BYB' LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;
	
		Test.stopTest();
		Case objCase = [SELECT Id, Status FROM Case WHERE Benefit_Order__c = :objBO.Id];
		System.assertEquals(CaseUtils.STATUS_CLOSED, objCase.Status, 'Connect Broker case not closed, when Benefit Order moved to Fulfilled.');
	}
}