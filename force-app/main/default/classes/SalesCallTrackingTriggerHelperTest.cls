/**
 * @name         SalesCallTrackingTriggerHelper
 * @author       Deepika Saini
 * @date         09-Apr-2021
 * @description  Unit Test for SalesCallTrackingTriggerHelper
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 */
@isTest
private class SalesCallTrackingTriggerHelperTest {
	@testSetup
	static void createData() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;

		List<Sales_Call_Tracking__c> list_SalesCallTrackingToInsert = new List<Sales_Call_Tracking__c>();
		List<Contact> list_Contact = new List<Contact>();
		List<Case> list_Case = new List<Case>();

		Id idNewPlan = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');

		Account objAcc = new Account(Name = 'test acc1', ZP_Company_Id__c = '100989001');
		insert objAcc;

		Opportunity objOpp = new Opportunity(
			RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan')
		);
		objOpp.AccountId = objAcc.Id;
		objOpp.StageName = 'SAL';
		objOpp.Name = 'test';
		objOpp.closeDate = System.today();
		insert objOpp;

		list_Contact.add(
			new Contact(
				FirstName = 'Neha 1',
				LastName = 'Test August 6 ',
				Email = 'neha.dabastest+1@lirik.io',
				AccountId = objOpp.AccountId,
				Phone = '(437) 654-6678'
			)
		);
		insert list_Contact;

		Benefit_Order__c objBONewPlan = new Benefit_Order__c();
		objBONewPlan.Opportunity__c = objOpp.Id;
		objBONewPlan.Account__c = objOpp.AccountId;
		objBONewPlan.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		objBONewPlan.OwnerId = userInfo.getUserId();
		insert objBONewPlan;

		list_Case.add(
			new Case(
				Subject = 'Test Case 1',
				contactId = list_Contact[0].Id,
				AccountId = objOpp.AccountId,
				RecordTypeId = idNewPlan,
				Priority = 'Medium',
				Direction__c = 'Inbound',
				Origin = 'Email',
				Benefit_Order__c = objBONewPlan.Id,
				Integration_Id__c = 'hippo-Benefits_New_Plan-' + objOpp.Id,
				Opportunity__c = objOpp.Id
			)
		);

		insert list_Case;

		list_SalesCallTrackingToInsert.add(
			new Sales_Call_Tracking__c(
				Processed_By_Workato__c = false,
				Call_Start_Time__c = System.now(),
				Call_End_Time__c = System.now(),
				Case__c = list_Case[0].id,
				Genesys_Integration_Id__c = '415897931556455-5561'
			)
		);

		list_SalesCallTrackingToInsert.add(
			new Sales_Call_Tracking__c(
				Processed_By_Workato__c = false,
				Call_Start_Time__c = System.now(),
				Call_End_Time__c = System.now(),
				Case__c = list_Case[0].id,
				Genesys_Integration_Id__c = '415897931556455-5561'
			)
		);

		list_SalesCallTrackingToInsert.add(
			new Sales_Call_Tracking__c(
				Processed_By_Workato__c = false,
				Call_Start_Time__c = System.now(),
				Call_End_Time__c = System.now(),
				Genesys_Integration_Id__c = '415897571856455-5561'
			)
		);

		insert list_SalesCallTrackingToInsert;
	}

	static testMethod void testCreateCaseAuditRecord() {
		Test.startTest();

		Sales_Call_Tracking__c objSalClTrack = [
			SELECT Id, Processed_By_Workato__c, Case__c, Genesys_Integration_Id__c
			FROM Sales_Call_Tracking__c
			WHERE Genesys_Integration_Id__c = '415897931556455-5561'
			LIMIT 1
		];

		objSalClTrack.Processed_By_Workato__c = true;
		update objSalClTrack;

		Test.stopTest();

		List<Case_Audit_Log__c> list_CaseAuditLogs = [
			SELECT Id, Genesys_Id__c
			FROM Case_Audit_Log__c
			WHERE Case__c = :objSalClTrack.Case__c
		];

		if (!list_CaseAuditLogs.isEmpty()) {
			System.assertEquals(list_CaseAuditLogs[0].Genesys_Id__c, objSalClTrack.Genesys_Integration_Id__c);
		}
	}

	static testMethod void testUpdateSalesCallTrackingsWithSameGenesys() {
		Test.startTest();

		List<Sales_Call_Tracking__c> list_SalesCallTracks = new List<Sales_Call_Tracking__c>();

		for (Sales_Call_Tracking__c objSalesCallTracking : [
			SELECT Id, Processed_By_Workato__c, Case__c, Genesys_Integration_Id__c
			FROM Sales_Call_Tracking__c
			WHERE Genesys_Integration_Id__c = '415897931556455-5561'
		]) {
			objSalesCallTracking.Processed_By_Workato__c = true;
			list_SalesCallTracks.add(objSalesCallTracking);
		}

		update list_SalesCallTracks;

		Test.stopTest();

		List<Case_Audit_Log__c> list_CaseAuditLogs = [
			SELECT Id, Genesys_Id__c
			FROM Case_Audit_Log__c
			WHERE Case__c = :list_SalesCallTracks[0].Case__c
		];

		if (!list_CaseAuditLogs.isEmpty()) {
			System.assertEquals(list_CaseAuditLogs.size(), 1);
			System.assertEquals(
				list_CaseAuditLogs[0].Genesys_Id__c,
				list_SalesCallTracks[0].Genesys_Integration_Id__c
			);
		}
	}

	static testMethod void testNegativeCaseAuditRecordDoesNotCreated() {
		Test.startTest();

		Sales_Call_Tracking__c objSalClTrack = [
			SELECT Id, Processed_By_Workato__c, Genesys_Integration_Id__c
			FROM Sales_Call_Tracking__c
			WHERE Genesys_Integration_Id__c = '415897571856455-5561'
			LIMIT 1
		];

		objSalClTrack.Processed_By_Workato__c = true;
		SalesCallTrackingTriggerHandler.resetSkipTriggerFlags();
		update objSalClTrack;

		Test.stopTest();

		List<Case_Audit_Log__c> list_CaseAuditLogs = [
			SELECT Id
			FROM Case_Audit_Log__c
			WHERE Genesys_Id__c = :objSalClTrack.Genesys_Integration_Id__c
		];

		System.assert(list_CaseAuditLogs.isEmpty());
	}
}