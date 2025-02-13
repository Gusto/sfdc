/*
 * Created By   :   Neha
 * Created Date :   19-Nov-2020
 * Description  :   Unit Test for CreateSalesCallTrackingController
 * Apex classes :   CreateSalesCallTrackingController
 *                  SalesCallTrackingTriggerHelper
 */

@isTest
private class CreateSalesCallTrackingControllerTest {
	@testSetup
	static void createData() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;

		List<Opportunity> list_OpportunitiesToInsert = new List<Opportunity>();
		List<Account> list_AccountsToInsert = new List<Account>();
		List<Contact> list_Contact = new List<Contact>();
		List<Benefit_Order__c> list_BO = new List<Benefit_Order__c>();
		List<Case> list_Case = new List<Case>();

		Id idNewPlan = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		Id idRenewal = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		Id idChange = Cache.getRecordTypeId('Case', 'Benefits Change Case');
		Id idBoR = Cache.getRecordTypeId('Case', 'Benefits BoR');

		Account objAcc = new Account(Name = 'test acc1', ZP_Company_Id__c = '100989001');
		list_AccountsToInsert.add(objAcc);

		Account objAccChange = new Account(Name = 'test acc2', ZP_Company_Id__c = '100989002');
		list_AccountsToInsert.add(objAccChange);

		Account objAccBoR = new Account(Name = 'test acc3', ZP_Company_Id__c = '100989003');
		list_AccountsToInsert.add(objAccBoR);

		insert list_AccountsToInsert;

		Opportunity objOpp = new Opportunity(
			RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan')
		);
		objOpp.AccountId = objAcc.Id;
		objOpp.StageName = 'SAL';
		objOpp.Name = 'test';
		objOpp.closeDate = System.today();
		list_OpportunitiesToInsert.add(objOpp);

		Opportunity objOppChange = new Opportunity(
			RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change')
		);
		objOppChange.AccountId = objAccChange.Id;
		objOppChange.StageName = 'SAL';
		objOppChange.Name = 'test';
		objOppChange.closeDate = System.today();
		list_OpportunitiesToInsert.add(objOppChange);

		Opportunity objOppBoR = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits BoR'));
		objOppBoR.AccountId = objAccBoR.Id;
		objOppBoR.StageName = 'SAL';
		objOppBoR.Name = 'test';
		objOppBoR.closeDate = System.today();
		list_OpportunitiesToInsert.add(objOppBoR);

		insert list_OpportunitiesToInsert;

		Opportunity objOpptyRenewal = TestUtility.BenefitsRenewalOpportunity();

		list_Contact.add(
			new Contact(
				FirstName = 'Neha 1',
				LastName = 'Test August 6 ',
				Email = 'neha.dabastest+1@lirik.io',
				AccountId = objOpp.AccountId,
				Phone = '(437) 654-6678'
			)
		);

		list_Contact.add(
			new Contact(
				FirstName = 'Neha 2',
				LastName = 'Test August 6 ',
				Email = 'neha.dabastest+2@lirik.io',
				AccountId = objOpptyRenewal.AccountId,
				Phone = '6567654432'
			)
		);

		list_Contact.add(
			new Contact(
				FirstName = 'Change 2',
				LastName = 'Test August 6 ',
				Email = 'neha.dabastest+3@lirik.io',
				AccountId = objOppChange.AccountId,
				Phone = '6567654409'
			)
		);

		list_Contact.add(
			new Contact(
				FirstName = 'Benefits BoR',
				LastName = 'Test August 6 ',
				Email = 'neha.dabastest+4@lirik.io',
				AccountId = objOppBoR.AccountId,
				Phone = '6567654410'
			)
		);

		insert list_Contact;

		Benefit_Order__c objBONewPlan = new Benefit_Order__c();
		objBONewPlan.Opportunity__c = objOpp.Id;
		objBONewPlan.Account__c = objOpp.AccountId;
		objBONewPlan.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		objBONewPlan.OwnerId = userInfo.getUserId();
		list_BO.add(objBONewPlan);

		Benefit_Order__c objBORenewal = new Benefit_Order__c();
		objBORenewal.Opportunity__c = objOpptyRenewal.Id;
		objBORenewal.Account__c = objOpptyRenewal.AccountId;
		objBORenewal.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
		objBORenewal.OwnerId = userInfo.getUserId();
		list_BO.add(objBORenewal);

		Benefit_Order__c objBOChange = new Benefit_Order__c();
		objBOChange.Opportunity__c = objOppChange.Id;
		objBOChange.Account__c = objOppChange.AccountId;
		objBOChange.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Change');
		objBOChange.OwnerId = UserInfo.getUserId();
		list_BO.add(objBOChange);

		Benefit_Order__c objBOBoR = new Benefit_Order__c();
		objBOBoR.Opportunity__c = objOppBoR.Id;
		objBOBoR.Account__c = objOppBoR.AccountId;
		objBOBoR.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
		objBOBoR.OwnerId = userInfo.getUserId();
		list_BO.add(objBOBoR);

		insert list_BO;

		list_Case.add(
			new Case(
				Subject = 'Test Case 1',
				contactId = list_Contact[0].Id,
				AccountId = objOpptyRenewal.AccountId,
				RecordTypeId = idNewPlan,
				Priority = 'Medium',
				Direction__c = 'Inbound',
				Origin = 'Email',
				Benefit_Order__c = objBONewPlan.Id,
				Integration_Id__c = 'hippo-Benefits_New_Plan-' + objOpp.Id,
				Opportunity__c = objOpp.Id
			)
		);

		list_Case.add(
			new Case(
				Subject = 'Test Case 2',
				contactId = list_Contact[1].Id,
				AccountId = objOpp.AccountId,
				RecordTypeId = idRenewal,
				Priority = 'Medium',
				Direction__c = 'Inbound',
				Origin = 'Email',
				Benefit_Order__c = objBORenewal.Id,
				Integration_Id__c = 'hippo-Benefits_Renewal-' + objOpptyRenewal.Id,
				Opportunity__c = objOpptyRenewal.Id
			)
		);

		list_Case.add(
			new Case(
				Subject = 'Test Case 1',
				contactId = list_Contact[2].Id,
				AccountId = objOppChange.AccountId,
				RecordTypeId = idChange,
				Priority = 'Medium',
				Direction__c = 'Inbound',
				Origin = 'Email',
				Benefit_Order__c = objBOChange.Id,
				Integration_Id__c = 'hippo-Benefits_Change-' + objOppChange.Id,
				Opportunity__c = objOppChange.Id
			)
		);

		list_Case.add(
			new Case(
				Subject = 'Test Case 2',
				contactId = list_Contact[3].Id,
				AccountId = objOppBoR.AccountId,
				RecordTypeId = idBoR,
				Priority = 'Medium',
				Direction__c = 'Inbound',
				Origin = 'Email',
				Benefit_Order__c = objBOBoR.Id,
				Integration_Id__c = 'hippo-Benefits_Renewal-' + objOppBoR.Id,
				Opportunity__c = objOppBoR.Id
			)
		);

		insert list_Case;
	}

	static testMethod void testNewPlanCallWithMatchingContact() {
		Test.startTest();

		ApexPages.StandardController objStandardCrtl = new ApexPages.StandardController(new Sales_Call_Tracking__c());
		CreateSalesCallTrackingController objExtension = new CreateSalesCallTrackingController(objStandardCrtl);

		objExtension.strPhoneNumber = '+14376546678';
		objExtension.strIntegrationID = '8786635463-399473874';

		objExtension.callEvent();

		System.assert(objExtension.objBO != null);

		objExtension.strCallType = CreateSalesCallTrackingController.CALL_TYPE_INBOUND;
		objExtension.onCallEnd();

		List<Sales_Call_Tracking__c> list_SCT = [
			SELECT Processed_by_Workato__c, Call_End_Time__c, Call_Start_Time__c, RecordType.Name
			FROM Sales_Call_Tracking__c
		];

		Test.stopTest();

		System.assert(!list_SCT.isempty());
		System.assertEquals(list_SCT[0].RecordType.Name, 'New Plan');
	}

	static testMethod void testChangeCallWithMatchingContact() {
		Test.startTest();

		ApexPages.StandardController objStandardCrtl = new ApexPages.StandardController(new Sales_Call_Tracking__c());
		CreateSalesCallTrackingController objExtension = new CreateSalesCallTrackingController(objStandardCrtl);

		objExtension.strPhoneNumber = '+16567654409';
		objExtension.strIntegrationID = '8786635463-399473874';

		objExtension.callEvent();

		System.assert(objExtension.objBO != null);

		objExtension.strCallType = CreateSalesCallTrackingController.CALL_TYPE_INBOUND;
		objExtension.onCallEnd();

		List<Sales_Call_Tracking__c> list_SCT = [
			SELECT Processed_by_Workato__c, Call_End_Time__c, Call_Start_Time__c, RecordType.Name
			FROM Sales_Call_Tracking__c
		];

		Test.stopTest();

		System.assert(!list_SCT.isempty());
		System.assertEquals(list_SCT[0].RecordType.Name, 'Change');
	}

	static testMethod void testBoRCallWithMatchingContact() {
		Test.startTest();

		ApexPages.StandardController objStandardCrtl = new ApexPages.StandardController(new Sales_Call_Tracking__c());
		CreateSalesCallTrackingController objExtension = new CreateSalesCallTrackingController(objStandardCrtl);

		objExtension.strPhoneNumber = '+16567654410';
		objExtension.strIntegrationID = '8786635463-399473874';

		objExtension.callEvent();

		System.assert(objExtension.objBO != null);

		objExtension.strCallType = CreateSalesCallTrackingController.CALL_TYPE_INBOUND;
		objExtension.onCallEnd();

		List<Sales_Call_Tracking__c> list_SCT = [
			SELECT Processed_by_Workato__c, Call_End_Time__c, Call_Start_Time__c, RecordType.Name
			FROM Sales_Call_Tracking__c
		];

		Test.stopTest();

		System.assert(!list_SCT.isempty());
		System.assertEquals(list_SCT[0].RecordType.Name, 'Benefits BoR');
	}

	static testMethod void testCallWithoutMatchingContact() {
		Test.startTest();

		ApexPages.StandardController objStandardCrtl = new ApexPages.StandardController(new Sales_Call_Tracking__c());
		CreateSalesCallTrackingController objExtension = new CreateSalesCallTrackingController(objStandardCrtl);

		objExtension.strPhoneNumber = '+14376546670';
		objExtension.strIntegrationID = '8786635463-399473874';
		objExtension.callEvent();

		System.assert(objExtension.objBO == null);

		List<Account> list_Acc = [SELECT Id FROM Account LIMIT 1];

		objExtension.objCallTracking.Account__c = list_Acc[0].Id;
		objExtension.searchForBenefitOrders();

		Test.stopTest();

		System.assert(objExtension.list_OpenBenefitOrders != null && !objExtension.list_OpenBenefitOrders.isEmpty());
	}

	static testMethod void testOutboundCall() {
		Test.startTest();

		ApexPages.StandardController objStandardCrtl = new ApexPages.StandardController(new Sales_Call_Tracking__c());
		CreateSalesCallTrackingController objExtension = new CreateSalesCallTrackingController(objStandardCrtl);

		objExtension.strPhoneNumber = '+14376546678';
		objExtension.strIntegrationID = '8786635463-399473874';
		objExtension.callEvent();

		System.assert(objExtension.objBO != null);

		objExtension.strCallType = CreateSalesCallTrackingController.CALL_TYPE_OUTBOUND;
		ApexPages.currentPage().getParameters().put('activeRecordId', objExtension.objBO.Id);
		objExtension.onCallEnd();

		Test.stopTest();

		System.assert([SELECT COUNT() FROM Sales_Call_Tracking__c] > 0);
	}
}