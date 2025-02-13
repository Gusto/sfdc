@isTest
public class TransitiontoFulfilmentTriggerHelperTest {
	@testSetup
	static void setup() {

		Configuration_Settings__c objConfig = new Configuration_Settings__c(Disable_Auto_Approve_TTF__c = false, SetupOwnerId = UserInfo.getOrganizationId());
		insert objConfig;

		skipTrigger(true);

		//Create 'Benefits New Plan' & 'Benefits Renewal' & 'Company Opportunity' Opportunity.
		Opportunity objOpportunity = TestUtility.BenefitsNewPlanOpportunity();
		Opportunity objRenewalOpportunity = TestUtility.getNewOpportunity('Benefits Renewal', objOpportunity.AccountId);
		Opportunity objCompanyOpportunity = TestUtility.getNewOpportunity('Company Opportunity', objOpportunity.AccountId);

		//Create company contact
		TestUtility.createTestContact(objOpportunity.AccountId, ContactUtil.COMPANY_CONTACT_RT_ID);

		//Create PriceBook record.
		PriceBook2 objPriceBook = TestUtility.createCompanyPriceBookInformation();

		//Map PriceBook with Opportunity.
		objOpportunity.Pricebook2Id = objPriceBook.id;
		objOpportunity.numberOfEmployees__c = 5;
		objRenewalOpportunity.Pricebook2Id = objPriceBook.id;
		objRenewalOpportunity.Signing_Forms_Completed_Timestamp__c = System.today().addDays(10);

		//Update Opportunity.
		List<Opportunity> list_Opportunity = new List<Opportunity>();
		list_Opportunity.add(objOpportunity);
		list_Opportunity.add(objRenewalOpportunity);
		update list_Opportunity;

		//Create carrier record.
		Carrier__c carrier = TestUtility.createTestCarrier('Carrier', 'CA', true);

		//Associate one policy with 'Benefits New Plan' Opportunity.
		TestUtility.insertPolicyForDifferentBenefitType(objOpportunity.id, carrier.Id, 1);

		//Create 'Benefits BoR' Opportunity.
		Opportunity objBenefitBOROpportunity = TestUtility.getNewOpportunity('Benefits BoR', objOpportunity.AccountId);

		Opportunity objBenefitBYBOpportunity = TestUtility.getNewOpportunity('Benefits BYOB', objOpportunity.AccountId);

		//Create New 'Company Opportunity' Opportunity.
		Opportunity objNewCompanyOpportunity = TestUtility.getNewOpportunity('Company Opportunity', objOpportunity.AccountId);
		List<Group> list_Groups = [SELECT Id FROM Group WHERE Name = 'Company Migration - Unassigned Orders'];

		//Create Order on 'Company Opportunity' Records.
		List<Order> list_Order = new List<Order>();
		list_Order.add(
			new Order(
				OpportunityId = objCompanyOpportunity.Id,
				AccountId = objCompanyOpportunity.AccountId,
				EffectiveDate = system.today().addDays(1),
				Status = 'Started',
				Previous_Payroll_Provider_Collect_Option__c = 'upload',
				OwnerId = list_Groups[0].Id
			)
		);
		list_Order.add(
			new Order(
				OpportunityId = objCompanyOpportunity.Id,
				AccountId = objCompanyOpportunity.AccountId,
				EffectiveDate = system.today().addDays(1),
				Status = 'Started',
				Previous_Payroll_Provider_Collect_Option__c = 'admin',
				OwnerId = list_Groups[0].Id
			)
		);
		list_Order.add(new Order(OpportunityId = objNewCompanyOpportunity.Id, AccountId = objNewCompanyOpportunity.AccountId, EffectiveDate = system.today().addDays(1), Status = 'Started'));
		insert list_Order;
		skipTrigger(false);
	}

	@isTest
	static void testCreateTTFPositiveUseCase() {
		//When TTF record is created then related BO records will also be created and auto-map with TTF record.
		//Get 'Company Opportunity' Opportunity record.
		Opportunity objOpportunity = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, Account.First_Payroll_Date__c FROM Opportunity WHERE recordType.Name = 'Company Opportunity' LIMIT 1]) {
			objOpportunity = objOpp;
		}

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
			Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

			//When TTF record is created and any BO exist related to Opportunity then it will auto-map with TTF record also.
			List<Transition_to_Fulfillment__c> list_TTF = [SELECT Id, Benefit_Order__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
			System.assert(list_TTF[0].Benefit_Order__c != null);

			//Update TTF record.
			objTTF.Dental_Carrier__c = 'VSP';
			update objTTF;

			//Delete TTF record.
			delete objTTF;
			skipTrigger(false);
		}

		Test.stopTest();
	}

	@isTest
	static void testCreateTTFNegativeUseCase() {
		//When TTF record is created then related BO records would not be created.
		//Get 'Benefits New Plan' Opportunity record.
		Opportunity objOpportunity = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, Account.First_Payroll_Date__c FROM Opportunity WHERE recordType.Name = 'Benefits New Plan' LIMIT 1]) {
			objOpportunity = objOpp;
		}

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
			Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, false);

			//When TTF record is created then BO records would not created.
			List<Transition_to_Fulfillment__c> list_TTF = [SELECT Id, Benefit_Order__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
			System.assert(list_TTF[0].Benefit_Order__c == null);

			//Update TTF record.
			objTTF.Dental_Carrier__c = 'VSP';
			update objTTF;
			//Delete TTF record.
			delete objTTF;
			skipTrigger(false);
		}
		Test.stopTest();
	}

	@isTest
	static void testUpdateOpportunityOnTTFPositiveUseCase() {
		//Update Opportunity on TTF record then Order__c field will auto update on TTF.
		//Get 'Benefits New Plan' Opportunity record.
		Opportunity objOpportunity = new Opportunity();
		Opportunity objNewOpportunity = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, Account.First_Payroll_Date__c FROM Opportunity WHERE recordType.Name = 'Company Opportunity' LIMIT 2]) {
			if (objOpportunity.Id == null) {
				objOpportunity = objOpp;
			} else {
				objNewOpportunity = objOpp;
			}
		}

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
			Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, false);

			List<Transition_to_Fulfillment__c> list_TTF = [SELECT Id, Benefit_Order__c, Order__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
			System.assert(list_TTF.size() > 0);
			Id idTTFRelatedOrder = null;
			if (list_TTF.size() > 0) {
				idTTFRelatedOrder = list_TTF[0].Order__c;
			}

			//Update Opportunity on TTF
			if (objNewOpportunity.Id != null) {
				//Update Opportunity on TTF record.
				objTTF.TTF_Status__c = 'Sales Submitted';
				objTTF.Dental_Carrier__c = 'VSP';
				objTTF.Previous_Payroll_Provider__c = 'ADP Run';
				objTTF.Opportunity__c = objNewOpportunity.Id;
				update objTTF;

				//When Opportunity will update on TTF then Order__c field will also update on TTF.
				list_TTF = [SELECT Id, Benefit_Order__c, Order__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
				System.assert(list_TTF.size() > 0);
				if (list_TTF.size() > 0) {
					System.assert(list_TTF[0].Order__c != idTTFRelatedOrder);
				}
			}
			skipTrigger(false);
		}
		Test.stopTest();
	}

	@isTest
	static void testUpdateOpportunityOnTTFNegativeUseCase() {
		//Update Opportunity on TTF record then Order__c field will be not changed on TTF.
		//Get 'Benefits New Plan' Opportunity record.
		Opportunity objOpportunity = new Opportunity();
		Opportunity objNewOpportunity = new Opportunity();
		for (Opportunity objOpp : [
			SELECT Id, AccountId, Account.First_Payroll_Date__c, RecordType.Name
			FROM Opportunity
			WHERE RecordType.Name = 'Company Opportunity' OR recordType.Name = 'Benefits BoR'
		]) {
			if (objOpp.RecordType.Name == 'Company Opportunity') {
				objOpportunity = objOpp;
			} else {
				objNewOpportunity = objOpp;
			}
		}

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
			Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, false);

			List<Transition_to_Fulfillment__c> list_TTF = [SELECT Id, Benefit_Order__c, Order__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
			System.assert(list_TTF.size() > 0);
			Id idTTFRelatedOrder = null;
			if (list_TTF.size() > 0) {
				idTTFRelatedOrder = list_TTF[0].Order__c;
			}

			//Update Opportunity on TTF
			if (objNewOpportunity.Id != null) {
				//Update Opportunity on TTF record.
				objTTF.TTF_Status__c = 'Sales Submitted';
				objTTF.Dental_Carrier__c = 'VSP';
				objTTF.Previous_Payroll_Provider__c = 'ADP Run';
				objTTF.Opportunity__c = objNewOpportunity.Id;
				update objTTF;

				//When Opportunity will update on TTF then Order__c field will not changed on TTF.
				list_TTF = [SELECT Id, Benefit_Order__c, Order__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
				System.assert(list_TTF.size() > 0);
				if (list_TTF.size() > 0) {
					System.assert(list_TTF[0].Order__c == idTTFRelatedOrder);
				}
			}
			skipTrigger(false);
		}
		Test.stopTest();
	}

	@isTest
	static void testAutoAssignTTFPositiveUseCase() {
		// TTF Status will auto-changed from 'Sales Submitted' to 'PT Approved'.
		//Get 'Company Opportunity' Opportunity record.
		Opportunity objOpportunity = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, Account.First_Payroll_Date__c, Order__c FROM Opportunity WHERE recordType.Name = 'Company Opportunity' LIMIT 1]) {
			objOpportunity = objOpp;
		}

		Transition_to_Fulfillment__c objTTF;

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
			objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

			List<Order> list_Orders = [SELECT Id FROM Order WHERE OpportunityId = :objOpportunity.Id];

			//update Order record
			Order objOrder = new Order(Id = list_Orders[0].Id, Team_Invitation_Preference__c = 'admin');
			update objOrder;

			//Update TTF record.
			objTTF.Contact_Preference__c = 'Email';
			objTTF.Order__c = list_Orders[0].Id;
			objTTF.Previous_Payroll_Provider__c = 'QuickBooks Online';
			objTTF.TTF_Status__c = 'Sales Submitted';
			objTTF.Dental_Carrier__c = 'VSP';
			update objTTF;

			//TTF record status should be changed as 'PT Approved'.
			List<Transition_to_Fulfillment__c> list_TTF = [
				SELECT
					Id,
					Benefit_Order__c,
					Order__c,
					TTF_Status__c,
					Previous_Payroll_Provider_Collect_Option__c,
					Previous_Payroll_Provider__c,
					Exception_Request__c,
					Same_Login__c,
					Bulk_Deal__c,
					Multi_EIN__c,
					PT_Approved_Date_Time__c,
					Team_Invitation_Preference__c
				FROM Transition_to_Fulfillment__c
				WHERE Id = :objTTF.Id
			];
			//validating skip auto assignment logic if PPP = IOP/QBO and Team_Invitation_Preference = admin
			System.assert(list_TTF[0].TTF_Status__c == 'Sales Submitted');

			objOrder.Team_Invitation_Preference__c = '';
			update objOrder;

			objTTF.Exception_Request__c = null;
			objTTF.Same_Login__c = null;
			objTTF.Bulk_Deal__c = null;
			objTTF.Multi_EIN__c = null;
			update objTTF;

			list_TTF = [
				SELECT
					Id,
					Benefit_Order__c,
					Order__c,
					TTF_Status__c,
					Previous_Payroll_Provider_Collect_Option__c,
					Previous_Payroll_Provider__c,
					Exception_Request__c,
					Same_Login__c,
					Bulk_Deal__c,
					Multi_EIN__c,
					PT_Approved_Date_Time__c,
					Team_Invitation_Preference__c
				FROM Transition_to_Fulfillment__c
				WHERE Id = :objTTF.Id
			];
			System.assert(list_TTF[0].TTF_Status__c == 'PT Approved');
			System.assertNotEquals(null, list_TTF[0].PT_Approved_Date_Time__c, 'PT Approved Date Time should be populated');

			objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

			objOrder.Previous_Payroll_Provider_Collect_Option__c = 'admin';
			update objOrder;

			objTTF.Contact_Preference__c = 'Email';
			objTTF.Order__c = objOrder.Id;
			objTTF.Previous_Payroll_Provider__c = 'ADP Run';
			objTTF.TTF_Status__c = 'Sales Submitted';
			objTTF.Dental_Carrier__c = 'VSP';
			update objTTF;

			list_TTF = [
				SELECT
					Id,
					Benefit_Order__c,
					Order__c,
					TTF_Status__c,
					Previous_Payroll_Provider_Collect_Option__c,
					Previous_Payroll_Provider__c,
					Exception_Request__c,
					Same_Login__c,
					Bulk_Deal__c,
					Multi_EIN__c,
					PT_Approved_Date_Time__c,
					Team_Invitation_Preference__c
				FROM Transition_to_Fulfillment__c
				WHERE Id = :objTTF.Id
			];

			/*@author:Pravesh Rana, Date:Feb-24-2021, Desc: below code is covering code against "Collect Option" exception logic*/
			TransitiontoFulfilmentTriggerHelper helperController = new TransitiontoFulfilmentTriggerHelper();
			Boolean blnIsAutoAssign = helperController.isPayrollTransferAutoAssignedOrder(list_TTF[0]);
			System.assert(!blnIsAutoAssign);

			//Create TTF record.
			idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
			Transition_to_Fulfillment__c objTTF2 = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

			//Update TTF record.
			objTTF.Previous_Payroll_Provider__c = 'ADP Run';
			objTTF.Contractors_paid_on_first_pay_date__c = 'Yes';
			objTTF.TTF_Status__c = 'Sales Follow-up';
			update objTTF;

			TransitiontoFulfilmentTriggerHelper controller = new TransitiontoFulfilmentTriggerHelper();
			controller.getEligibleAutoAssignPayrollTransferTTF(new List<Transition_to_Fulfillment__c>{ objTTF2 });
			blnIsAutoAssign = controller.isPayrollTransferAutoAssignedOrder(objTTF2);
			System.assert(!blnIsAutoAssign);

			//Delete TTF Record.
			delete objTTF;
			//Undelete TTF Record.
			undelete objTTF;
			skipTrigger(false);
		}
		Test.stopTest();
	}

	@isTest
	static void testAutoAssignTTFNegativeUseCase() {
		// TTF Status will not changed from 'Sales Submitted' to 'PT Approved'.
		//Get 'Company Opportunity' Opportunity record.
		Opportunity objOpportunity = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, Account.First_Payroll_Date__c, Order__c FROM Opportunity WHERE recordType.Name = 'Benefits New Plan' LIMIT 1]) {
			objOpportunity = objOpp;
		}

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
			Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

			//Update TTF status.
			objTTF.Contact_Preference__c = 'Email';
			objTTF.Order__c = objOpportunity.Order__c;
			objTTF.Previous_Payroll_Provider__c = 'ADP Run';
			objTTF.TTF_Status__c = 'Sales Submitted';
			objTTF.Dental_Carrier__c = 'VSP';
			update objTTF;

			//TTF record status should not be changed.
			List<Transition_to_Fulfillment__c> list_TTF = [SELECT Id, Benefit_Order__c, TTF_Status__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
			System.assert(list_TTF[0].TTF_Status__c == 'Sales Submitted');

			//Create TTF record.
			idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
			Transition_to_Fulfillment__c objTTF2 = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

			//Update TTF record.
			objTTF.Previous_Payroll_Provider__c = 'ADP Run';
			objTTF.Contractors_paid_on_first_pay_date__c = 'Yes';
			objTTF.TTF_Status__c = 'Sales Follow-up';
			update objTTF;

			TransitiontoFulfilmentTriggerHelper controller = new TransitiontoFulfilmentTriggerHelper();
			controller.getEligibleAutoAssignPayrollTransferTTF(new List<Transition_to_Fulfillment__c>{ objTTF2 });
			controller.isPayrollTransferAutoAssignedOrder(objTTF2);

			//Delete TTF Record.
			delete objTTF;
			//Undelete TTF Record.
			undelete objTTF;
			skipTrigger(false);
		}
		Test.stopTest();
	}

	@isTest
	static void testOnAfterInsertAsyncTest() {
		Set<Id> set_TestIds = new Set<Id>();
		TransitiontoFulfilmentTriggerHelper.OnAfterInsertAsync(set_TestIds);
	}

	@isTest
	static void testOnAfterDeleteAsyncTest() {
		Set<Id> set_TestIds = new Set<Id>();
		TransitiontoFulfilmentTriggerHelper.OnAfterDeleteAsync(set_TestIds);
	}

	@isTest
	static void testOnAfterUpdateAsyncTest() {
		Set<Id> set_TestIds = new Set<Id>();
		TransitiontoFulfilmentTriggerHelper.OnAfterUpdateAsync(set_TestIds);
	}

	@isTest
	static void testPTApprovedStampedOnTTFApproval() {
		//When TTF record is created then related BO records will also be created and auto-map with TTF record.
		//Get 'Company Opportunity' Opportunity record.
		Opportunity objOpportunity = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, Account.First_Payroll_Date__c FROM Opportunity WHERE recordType.Name = 'Company Opportunity' LIMIT 1]) {
			objOpportunity = objOpp;
		}

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
			Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

			objTTF.TTF_Status__c = 'PT Approved';
			update objTTF;

			//When TTF record is created and any BO exist related to Opportunity then it will auto-map with TTF record also.
			List<Transition_to_Fulfillment__c> list_TTF = [SELECT Id, PT_Approved_Date_Time__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
			System.assertNotEquals(null, list_TTF[0].PT_Approved_Date_Time__c, 'PT Approved Date shoould not be null');

			skipTrigger(false);
		}

		Test.stopTest();
	}

	/*
	 * @author:         Bhagat Singh
	 * @description:    Validate Benefit Order, Status.
	 * @parm:           NA
	 * @return:         NA
	 */
	@isTest
	static void updateBOAndCOOrderStatusAsPlanGroup() {
		Opportunity objOpportunity = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, Account.First_Payroll_Date__c FROM Opportunity WHERE recordType.Name = 'Company Opportunity' LIMIT 1]) {
			objOpportunity = objOpp;
		}

		Test.startTest();
		skipTrigger(true);
		List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
		System.assert(list_Contact.size() > 0);

		NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch', 'Same carrier, plan/group level changes' };
		Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
		Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);

		List<Transition_to_Fulfillment__c> list_TTF = [SELECT Id, Benefit_Order__c FROM Transition_to_Fulfillment__c WHERE Id = :objTTF.Id];
		System.assert(list_TTF[0].Benefit_Order__c != null);

		objTTF.Medical_Waiting_Period_Change__c = 'Y';
		update objTTF;
		skipTrigger(false);

		Test.stopTest();

		System.assertEquals([SELECT Type__c FROM Benefit_Order__c WHERE Id = :list_TTF[0].Benefit_Order__c].Type__c, 'Same carrier, plan/group level changes');
	}

	@isTest
	static void testAutoFieldAssignPositiveUseCase() {
		Opportunity objOpportunity;
		for (Opportunity objOpp : [SELECT Id, AccountId, RecordType.Name FROM Opportunity WHERE RecordType.Name = 'Benefits New Plan']) {
			objOpportunity = objOpp;
		}
		// update objOpportunity;

		Test.startTest();
		if (objOpportunity.Id != null) {
			skipTrigger(true);
			BenefitOrderHelper.skipTrigger = false;

			//Get Contact Record.
			List<Contact> list_Contact = [SELECT Id FROM Contact WHERE AccountId = :objOpportunity.AccountId];
			System.assert(list_Contact.size() > 0);

			//Create TTF record.
			Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission New Plan');
			Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpportunity.AccountId, list_Contact[0].Id, objOpportunity.Id, idTTFRecordType, true);
			System.assert(objTTF.Id != null);
			skipTrigger(false);
		}
		Test.stopTest();
	}

	/**
	 * @description Test if Sales users are unable to approve Payroll Transfer TTF records without adding them to custom settings
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testSalesPTApprovalValidation() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE)
			.setName('Discovery Account')
			.setOnboardingFlow('In-App')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objCompanyAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setName('TEST OPPORTUNITY')
			.setCloseDate(Date.today())
			.setAccountId(objCompanyAccount.id)
			.setStage('SAL')
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.build();
		insert objOpportunity;

		Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setRecordTypeId(cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
			.setOpportunityId(objOpportunity.Id)
			.setBenefitOrderId(null)
			.build();
		insert objTTF;

		User objUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = '_del_ZP SDR' AND IsActive = TRUE LIMIT 1];

		Test.startTest();
		System.runAs(objUser) {
			Boolean blnValidation = false;
			try {
				objTTF.TTF_Status__c = TransitiontoFulfilmentUtil.TTF_STATUS_PT_APPROVED;
				update objTTF;
			} catch (Exception objException) {
				System.assert(objException.getMessage().containsIgnoreCase('You don\'t have permission to update TTF Status to PT Approved'), 'Validation rule message mismatch');
				blnValidation = true;
			}

			System.assertEquals(true, blnValidation, 'Failed to encouter validation rule while approving TTF records');
		}
		Test.stopTest();
	}

	//This method skip required triggers.
	static void skipTrigger(Boolean blnFlag) {
		AccounttriggerHelper.skipTrigger = blnFlag;
		OpportunitytriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		OrdertriggerHelper.SkipTrigger = blnFlag;
		BenefitOrderHelper.skipTrigger = blnFlag;
	}
}