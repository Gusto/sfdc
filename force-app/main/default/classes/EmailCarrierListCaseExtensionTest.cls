@istest
public class EmailCarrierListCaseExtensionTest {
	@testSetup
	static void setUp() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Account acc = TestUtility.CompanyAccount();

		Carrier__c car = new Carrier__c();
		car.Name = 'Test Carrier 1';
		car.New_Plan_Email_List__c = 'my new plan::test@test.com';
		car.BOR_Transfer_Email_List__c = 'my BOR::test@test.com';
		car.Renewal_Email_List__c = 'Test::test@test.com';
		insert car;

		Opportunity opp = new Opportunity();
		opp.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		opp.Name = 'Benefits Renewal OPP';
		opp.AccountId = acc.Id;
		opp.StageName = 'SAL';
		opp.CloseDate = system.today();
		insert opp;

		Policy__c policy = new Policy__c();
		policy.Carrier__c = car.Id;
		policy.Opportunity__c = opp.id;
		policy.Is_Selected__c = true;
		insert policy;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test Case 1';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.Opportunity__c = opp.id;
		CaseTriggerHelper.skipTrigger = true;
		insert cse;
	}

	private static testMethod void testCaseExtension() {
		OpportunityTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		List<Case> caseList = [SELECT Id, RecordTypeId, AccountId, Subject, Description, Type, Opportunity__c FROM Case];
		List<Carrier__c> carrierList = [SELECT Id FROM Carrier__c];

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', caseList[0].id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(caseList[0]);
		EmailCarrierListCaseExtension extension = new EmailCarrierListCaseExtension(stdCase);
		extension.carrierId = carrierList[0].Id;
		extension.renderEmailDetails();
		test.stopTest();
	}

	private static testMethod void testCaseExtension2() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Account acc = TestUtility.CompanyAccount();
		Opportunity opp1 = new Opportunity();
		opp1.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
		opp1.Name = 'Benefits BoR OPP';
		opp1.AccountId = acc.Id;
		OpportunityTriggerHelper.skipTrigger = true;
		opp1.StageName = 'Raw';
		opp1.CloseDate = system.today();
		insert opp1;
		test.startTest();

		List<Carrier__c> carrierList = [SELECT Id FROM Carrier__c];
		Case cse1 = new Case();
		cse1.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
		cse1.AccountId = acc.Id;
		cse1.Subject = 'Test Case 2';
		cse1.Description = 'Test';
		cse1.Type = 'QLE';
		cse1.Opportunity__c = opp1.id;
		CaseTriggerHelper.skipTrigger = true;
		insert cse1;

		ApexPages.currentPage().getParameters().put('id', cse1.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse1);
		EmailCarrierListCaseExtension extension = new EmailCarrierListCaseExtension(stdCase);
		extension.carrierId = carrierList[0].Id;
		extension.renderEmailDetails();
		extension.assignEmail();
		test.stopTest();
	}
}