/**
 * @author Lalitha kasturi
 * @date June 29, 2022
 * @description  Test class for SalesCaseEmailHelper
 */
@isTest
public class SalesCaseEmailHelperTest {
	public static Integer generateRandomId() {
		return Integer.valueOf(10000000 + Math.rint(Math.random() * 90000000));
	}

	@testSetup
	static void setUp() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('ContactTriggerHanlder');
		OpportunityTriggerHelper.skipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('TEST CONTACT')
			.setLastName('CONTACT')
			.setPhone('1234567890')
			.setEmail('test.contact@gusto.com')
			.setZPUserId(String.valueOf(generateRandomId()))
			.build();

		insert objContact;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objAccount.Id)
			.setName('Test Sales Opportunity')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
			.setSourceID('343434')
			.setStage('SAL')
			.build();
		insert objOpportunity;

		OpportunityContactRole objContactRole = new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(objOpportunity.Id).setContactId(objContact.Id).build();

		insert objContactRole;

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objOpportunity.Id)
			.setSubject('Subject')
			.setStatus(TaskUtil.TASK_STATUS_IN_PROGRESS)
			.setContactReason('Onboarding')	
			.setSubContactReason('Add Accountant')
			.build();
		insert objTask;
	}

	@isTest
	private static void SendFollowUpEmailTest() {
		Task objTask = [SELECT Id, WhatId, Case__c FROM Task LIMIT 1];

		SalesCaseEmailHelper.Requests objReqInput = new SalesCaseEmailHelper.Requests();
		objReqInput.strTaskRecordInputId = objTask.Id;
		List<SalesCaseEmailHelper.Requests> list_Requests = new List<SalesCaseEmailHelper.Requests>();
		list_Requests.add(objReqInput);

		Test.startTest();
		List<SalesCaseEmailHelper.Results> list_Results = SalesCaseEmailHelper.CreateCaseForFollowUpEmail(list_Requests);
		Test.stopTest();

		Case objCase = [SELECT Id, CaseNumber, RecordTypeId, Primary_Call_Reason__c, Secondary_Call_Reason__c FROM Case WHERE Id = :list_Results[0].strCaseId LIMIT 1];
		Task objTaskResult = [SELECT Id, Case__c, Primary_Call_Reason__c, Secondary_Call_Reason__c FROM Task WHERE Id = :objTask.Id LIMIT 1];

		System.assert(list_Results[0].strCaseId != null);
		System.assertEquals(objCase.RecordTypeId, CaseUtils.RECTYPE_SALES_CASES);
		System.assert(objTaskResult.Case__c == objCase.Id);
		System.assertEquals(objCase.Primary_Call_Reason__c.toLowerCase(), objTaskResult.Primary_Call_Reason__c.toLowerCase());
		System.assertEquals(objCase.Secondary_Call_Reason__c.toLowerCase(), objTaskResult.Secondary_Call_Reason__c.toLowerCase());

		EmailMessage objMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setFromAddress('supporttest@gustotest.com')
			.setToAddress('test.contact@gusto.com')
			.setSubject('test outbound email to auto close')
			.setIncoming(false)
			.setTextBody('Sending test email outbound to auto close sales case')
			.build();
		insert objMessage;
		Case objCaseUpdated = [SELECT Id, Status FROM Case WHERE Id = :list_Results[0].strCaseId LIMIT 1];
		System.assertEquals(objCaseUpdated.Status, CaseUtils.STATUS_CLOSED);
	}
}