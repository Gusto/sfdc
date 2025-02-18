/**
 * Test Class For CustomerFeedbackExtension
 */

@isTest
public class CustomerFeedbackExtensiontest {
	private static testMethod void testSaveFeedbackRecord() {
		Account acc = TestUtility.CompanyAccount();
		Opportunity opp = TestUtility.BenefitsNewPlanOpportunity();

		Customer_Feedback__c custfeed = new Customer_Feedback__c();
		custfeed.Account__c = acc.Id;
		custfeed.Opportunity__c = opp.Id;
		custfeed.Priority__c = 'Not Important';
		custfeed.Reporting_Level__c = 'Payroll';
		custfeed.Request_Subtype__c = 'State Tax';
		custfeed.Request_Type__c = 'Feedback';
		insert custfeed;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('OppId', opp.id);
		ApexPages.currentPage().getParameters().put('accId', acc.Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(custfeed);
		CustomerFeedbackExtension extension = new CustomerFeedbackExtension(sc);
		extension.saveRecord();
		extension.cancelRecord();
		extension.savenextrecord();
		extension.refresh();
		extension.getTypes();
		extension.getFeedbackImp();
		extension.getPainFrequency();
		extension.getPainScale();
		Test.stopTest();
	}

	private static testMethod void testLeadFeedbackRecord() {
		TestUtility.InsertCompanyLeads(1);
		Lead lead = [SELECT Id FROM Lead WHERE RecordType.Name = 'Company' LIMIT 1];

		Customer_Feedback__c custfeed = new Customer_Feedback__c();
		custfeed.Lead__c = lead.Id;
		custfeed.Priority__c = 'Not Important';
		custfeed.Reporting_Level__c = 'Payroll';
		custfeed.Request_Subtype__c = 'State Tax';
		custfeed.Request_Type__c = 'Feedback';
		insert custfeed;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('leadId', lead.Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(custfeed);
		CustomerFeedbackExtension extension = new CustomerFeedbackExtension(sc);
		extension.saveRecord();
		extension.cancelRecord();
		extension.savenextrecord();
		extension.refresh();
		extension.getTypes();
		extension.getFeedbackImp();
		extension.getPainFrequency();
		extension.getPainScale();
		Test.stopTest();
	}

	private static testMethod void testAccountantFirmFeedbackRecord() {
		Account acc = TestUtility.ResellerAccount();

		Customer_Feedback__c custfeed = new Customer_Feedback__c(RecordTypeId = Cache.getRecordTypeId('Customer_Feedback__c', 'Accounting Firm'));
		custfeed.Account__c = acc.Id;
		custfeed.Reporting_Level__c = 'Payroll';
		custfeed.Request_Subtype__c = 'Running Payroll';
		custfeed.Request_Type__c = 'Missing Feature';
		insert custfeed;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('accId', acc.Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(custfeed);
		CustomerFeedbackExtension extension = new CustomerFeedbackExtension(sc);
		extension.saveRecord();
		extension.cancelRecord();
		extension.savenextrecord();
		extension.refresh();
		extension.getTypes();
		extension.getFeedbackImp();
		extension.getPainFrequency();
		extension.getPainScale();
		Test.stopTest();
	}

	private static testMethod void testClientFeedbackRecord() {
		Account acc = TestUtility.CompanyAccount();
		Account accReseller = TestUtility.ResellerAccount();
		Opportunity opp = TestUtility.createOpportunity('Acquisition', acc.Id);
		opp.Sold_By__c = accReseller.Id;
		insert opp;

		Customer_Feedback__c custfeed = new Customer_Feedback__c(RecordTypeId = Cache.getRecordTypeId('Customer_Feedback__c', 'Client of Accountant'));
		custfeed.Account__c = acc.Id;
		custfeed.Opportunity__c = opp.Id;
		custfeed.Priority__c = 'Not Important';
		custfeed.Reporting_Level__c = 'Payroll';
		custfeed.Request_Subtype__c = 'HR';
		custfeed.Request_Type__c = 'Missing Feature';
		insert custfeed;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('OppId', opp.id);
		ApexPages.currentPage().getParameters().put('accId', acc.Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(custfeed);
		CustomerFeedbackExtension extension = new CustomerFeedbackExtension(sc);
		extension.saveRecord();
		extension.cancelRecord();
		extension.savenextrecord();
		extension.refresh();
		extension.getTypes();
		extension.getFeedbackImp();
		extension.getPainFrequency();
		extension.getPainScale();
		Test.stopTest();
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, Customer feedback created from Case
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	private static void testSaveFeedbackRecordForCase() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		Opportunity objOpp = TestUtility.BenefitsRenewalOpportunity();
		Contact objContact = TestUtility.createTestContact(objOpp.AccountId, ContactUtil.COMPANY_CONTACT_RT_ID);
		Case objCase = TestDataFactory.createCaseRecord('Benefits Renewal Case', false);
		objCase.AccountId = objOpp.AccountId;
		objCase.Opportunity__c = objOpp.Id;
		objCase.ContactId = objContact.Id;
		insert objCase;

		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
		CaseTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('caseId', objCase.Id);
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpp);
		CustomerFeedbackExtension objExtension = new CustomerFeedbackExtension(objStandardController);
		objExtension.objCustomerFeedback.Priority__c = 'Not Important';
		objExtension.objCustomerFeedback.Request_Subtype__c = 'Infertility Benefits/Questions';
		objExtension.objCustomerFeedback.Request_Type__c = 'ER Feedback';
		objExtension.saveRecord();
		objExtension.savenextrecord();
		objExtension.cancelRecord();

		Test.stopTest();

		List<Customer_Feedback__c> list_CustomerFeedbacks = [SELECT Id, RecordTypeId, Reporting_Level__c FROM Customer_Feedback__c LIMIT 1];
		System.assert(list_CustomerFeedbacks.size() > 0);
		System.assert(list_CustomerFeedbacks[0].Reporting_Level__c == 'Benefits');
	}
}