/**
    Created by : Bhagat
    Created Date : 19 Jan 2021
**/
@isTest
public with sharing class AdvisingEmailCARegionAssignmentCtrlTest {
	@testSetup
	static void setup() {
		skipTrigger(true);
		//create company account
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.build();

		insert objAccount;

		List<Opportunity> list_Opportunity = new List<Opportunity>();
		// Create Benefits Renewal Opportunity With Region__c as CA Central.
		Opportunity objOpportunity1 = new Opportunity();
		objOpportunity1.AccountId = objAccount.Id;
		objOpportunity1.Name = 'Test Opp BNP 1';
		objOpportunity1.CloseDate = System.today().addDays(10);
		objOpportunity1.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOpportunity1.StageName = 'Ready for Default Package';
		objOpportunity1.UW_State_PY__c = 'California';
		objOpportunity1.HI_Effective_Date__c = System.today().addMonths(3);
		objOpportunity1.Region__c = 'CA Central';
		list_Opportunity.add(objOpportunity1);

		// Create Benefits Renewal Opportunity With Region__c as blank and Satge as 'Raw'.
		Opportunity objOpportunity2 = new Opportunity();
		objOpportunity2.AccountId = objAccount.Id;
		objOpportunity2.Name = 'Test Opp BNP 2';
		objOpportunity2.CloseDate = System.today().addDays(10);
		objOpportunity2.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOpportunity2.StageName = 'Raw';
		objOpportunity2.UW_State_PY__c = 'California';
		objOpportunity2.HI_Effective_Date__c = System.today().addMonths(3);
		list_Opportunity.add(objOpportunity2);

		// Create Benefits Renewal Opportunity With Region__c as blank and Satge as 'Ready for Default Package'.
		Opportunity objOpportunity3 = new Opportunity();
		objOpportunity3.AccountId = objAccount.Id;
		objOpportunity3.Name = 'Test Opp BNP 3';
		objOpportunity3.CloseDate = System.today().addDays(10);
		objOpportunity3.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		objOpportunity3.Async_Renewal__c = true;
		objOpportunity3.StageName = 'Ready for Default Package';
		objOpportunity3.UW_State_PY__c = 'California';
		objOpportunity3.HI_Effective_Date__c = System.today().addMonths(3);
		list_Opportunity.add(objOpportunity3);

		insert list_Opportunity;

		skipTrigger(false);
	}

	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
	}

	@isTest
	static void testAssignOpportunity() {
		test.startTest();
		AdvisingEmailCARegionAssignmentCtrl obj = new AdvisingEmailCARegionAssignmentCtrl();
		System.assertEquals(obj.objRegionDetails.intCATotalUnassignedRegion, 2, 'There should be 2 Opportunity where Region__c is blank');

		//Assign 2 Opportunity to "CA EAST" Region.
		obj.resetCAPanelValues();
		obj.intCACentralAdditionaRegion = 2;
		obj.saveAssignRegionToOpportunities();

		System.assertEquals(obj.objRegionDetails.intCATotalUnassignedRegion, 0, 'There should be no Opportunity exist where Region__c is blank');
		test.stopTest();
	}

	@isTest
	static void testUnAssignOpportunity() {
		test.startTest();
		AdvisingEmailCARegionAssignmentCtrl obj = new AdvisingEmailCARegionAssignmentCtrl();
		System.assertEquals(obj.objRegionDetails.intCACentralTotal, 1, 'There should be 1 Opportunity where Region__c is CA Central');

		//Unassign 1 Opportunity to "CA Central" Region.
		obj.intCACentralAdditionaRegion = 1;
		obj.blnIsUnassigned = true;
		obj.saveAssignRegionToOpportunities();

		System.assertEquals(obj.objRegionDetails.intCATotalUnassignedRegion, 3, 'There should be 3 Opportunity where Region__c is blank');
		test.stopTest();
	}

	@isTest
	static void testBatchTest() {
		List<Opportunity> list_UpdatedOpps = new List<Opportunity>();
		List<Case> list_NewCases = new List<Case>();
		for (Opportunity oppRec : [
			SELECT Id, Region__c
			FROM Opportunity
			WHERE UW_State_PY__c = 'California' AND Region__c != NULL
		]) {
			oppRec.Region__c = null;
			list_UpdatedOpps.add(oppRec);
			list_NewCases.add(
				new Case(
					Opportunity__c = oppRec.Id,
					RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_CASE_RT_ID,
					Integration_Id__c = 'hippo-Benefits_Renewal-' + String.valueof(oppRec.Id)
				)
			);
		}

		if (list_UpdatedOpps.size() > 0) {
			OpportunityTriggerHelper.skipTrigger = true;
			update list_UpdatedOpps;
		}

		if (list_NewCases.size() > 0) {
			CaseTriggerHelper.skipTrigger = true;
			insert list_NewCases;
		}

		AdvisingEmailCARegionAssignmentBatch objBatch = new AdvisingEmailCARegionAssignmentBatch();
		objBatch.intCAEastCount = 1;
		objBatch.intCAWestCount = 1;
		objBatch.intCACentralCount = 1;
		objBatch.blnIsAssignment = true;
		objBatch.dtSelectedMonthStartDate = System.today().addMonths(3).addDays(-1);
		objBatch.dtSelectedMonthEndDate = System.today().addMonths(3).addDays(+1);
		objBatch.intNumberOfRecordsProcessed = 0;
		test.startTest();
		database.executeBatch(objBatch);
		test.stopTest();

		list_UpdatedOpps = new List<Opportunity>();
		list_UpdatedOpps = [
			SELECT Id, Region__c
			FROM Opportunity
			WHERE UW_State_PY__c = 'California' AND Region__c = NULL
		];
		System.assert(list_UpdatedOpps.size() == 0, 'Unsuccessful Updation');
	}
}