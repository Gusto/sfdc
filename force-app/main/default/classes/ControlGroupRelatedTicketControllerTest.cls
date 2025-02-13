/**
 * @description Test class for ControlGroupRelatedTicketViewController
 * @author  Ajay Krishna P U
 * @since 2023-05-24
 */
@isTest
public with sharing class ControlGroupRelatedTicketControllerTest {
	//Test data identifiers
	static final String TEST_ACCOUNT_NAME = 'Test Account Ref';
	static final String TICKET_REF_1 = 'New';
	static final String TICKET_REF_2 = 'Report Creation';
	static final List<String> LIST_TICKET_FIELDS = new List<String>{ 'Id', 'Name' };
	static final List<String> LIST_CASE_FIELDS = new List<String>{ 'Id', 'CaseNumber', 'Case_Owner_Name__c', 'Status', 'CreatedDate' };

	/**
	 * Test data setup
	 */
	@TestSetup
	static void makeData() {
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName(TEST_ACCOUNT_NAME).setOwnerId(UserInfo.getUserId()).build();
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		TicketTriggerHelper.skipTrigger = true;
		List<Ticket__c> list_objTickets = new List<Ticket__c>();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setStatus(TICKET_REF_1)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setAccountId(objAccount.Id)
			.build();
		list_objTickets.add(objTicket);

		Ticket__c objTicketCloseDate = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setStatus(TICKET_REF_2)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setAccountId(objAccount.Id)
			.build();
		list_objTickets.add(objTicketCloseDate);

		insert list_objTickets;
		TicketTriggerHelper.skipTrigger = false;

		EmailMessageTriggerHelper.skipTrigger = true;
		EmailMessage objEmail = new TestDataFactory.EmailMessageBuilder().setRelatedToId(list_objTickets[0].Id).build();
		insert objEmail;
		EmailMessageTriggerHelper.skipTrigger = false;

		CaseTriggerHelper.skipTrigger = true;
		Case objCase = new TestDataFactory.CaseBuilder().setRecordTypeId('R&D Tax Credits').setSourceId(objEmail.Id).build();
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;
	}

	/**
	 * @description Test Get Tickets function when ControlGroup is Empty
	 * With an Empty control group, The function always should return empty Ticket list
	 */
	@isTest
	static void testGetTicketsByEmptyControlGroup() {
		Ticket__c objTicket = getTicket(TICKET_REF_1);

		Test.startTest();
		List<Ticket__c> list_ResultTickets = ControlGroupRelatedTicketViewController.getControlGroupRelatedTickets(objTicket.Id, LIST_TICKET_FIELDS, null, null);
		System.assert(list_ResultTickets.isEmpty(), 'Invalid Tickets for Control group = null');

		list_ResultTickets = ControlGroupRelatedTicketViewController.getControlGroupRelatedTickets(objTicket.Id, LIST_TICKET_FIELDS, '', null);
		System.assert(list_ResultTickets.isEmpty(), 'Invalid Tickets for Control group = ""');
		Test.stopTest();
	}

	/**
	 * @description Test Get Tickets function when valid inputs
	 * The resulted list always should omit the ticket specified on request
	 */
	@isTest
	static void testGetTicketsByControlGroup() {
		Account objAccount = getAccount();
		objAccount.Control_Group__c = 'CG 1';
		update objAccount;

		Test.startTest();

		Ticket__c objTicket = getTicket(TICKET_REF_1);
		List<Ticket__c> list_ResultTickets = ControlGroupRelatedTicketViewController.getControlGroupRelatedTickets(objTicket.Id, LIST_TICKET_FIELDS, 'CG 1', 'Status__c');
		System.assert(list_ResultTickets.size() == 1, 'Invalid Tickets for Control group = CG 1');

		Ticket__c objTicket2 = getTicket(TICKET_REF_2);
		System.assert(list_ResultTickets[0].Id == objTicket2.Id, 'Invalid Return Ticket, expected Ticket 2');

		list_ResultTickets = ControlGroupRelatedTicketViewController.getControlGroupRelatedTickets(objTicket.Id, LIST_TICKET_FIELDS, 'CG 2', 'Status__c');
		System.assert(list_ResultTickets.isEmpty(), 'Invalid Tickets for Control group = CG 2');

		Test.stopTest();
	}

	/**
	 * @author: Deepesh Rao
	 * @description Test Get cases when Email is linked to Ticket
	 */
	@isTest
	static void testGetCasesByTicketEmails() {
		EmailMessage objEmail = [SELECT Id, RelatedToId FROM EmailMessage WHERE FromAddress = 'from.address@test.com'];
		Assert.areEqual(objEmail.Id != null, true, 'Email Message record not present');
		Ticket__c objTicket = getTicket(TICKET_REF_1);
		Assert.areEqual(objEmail.RelatedToId, objTicket.Id, 'Email not linked to ticket');
		Test.startTest();
		List<Case> list_resultCases = ControlGroupRelatedTicketViewController.getCasesLinkedToEmail(objTicket.Id, LIST_CASE_FIELDS, 'CreatedDate');
		Assert.areEqual(list_resultCases.size() == 1, true, 'Case count more than 1');
		Test.stopTest();
	}

	/**
	 * @author: Deepesh Rao
	 * @description Test Get cases when Email is linked to Ticket
	 */
	@isTest
	static void testGetCasesByTicketEmailsEmailIsNotPresent() {
		EmailMessage objEmail = [SELECT Id, RelatedToId FROM EmailMessage WHERE FromAddress = 'from.address@test.com'];
		Assert.areEqual(objEmail.Id != null, true, 'Email Message record not present');
		Ticket__c objTicket = getTicket(TICKET_REF_2);
		Assert.areNotEqual(objEmail.RelatedToId, objTicket.Id, 'Email linked to ticket');
		Test.startTest();
		List<Case> list_resultCases = ControlGroupRelatedTicketViewController.getCasesLinkedToEmail(objTicket.Id, LIST_CASE_FIELDS, 'CreatedDate');
		Assert.areEqual(list_resultCases.isEmpty(), true, 'Case Record Exists');
		Test.stopTest();
	}

	/**
	 * @author: Deepesh Rao
	 * @description test get cases when ticket is not present
	 */
	@isTest
	static void testGetCasesByTicketEmailsWhenTicketIsNotPresent() {
		Test.startTest();
		List<Case> list_resultCases = ControlGroupRelatedTicketViewController.getCasesLinkedToEmail(null, LIST_CASE_FIELDS, 'CreatedDate');
		Assert.areEqual(list_resultCases.isEmpty(), true, 'Ticket Id is present');
		Test.stopTest();
	}

	/**
	 * @description Service function to get Test Account
	 * @return      `Account`
	 */
	static Account getAccount() {
		List<Account> list_Accounts = [SELECT Id, Control_Group__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME];
		System.assert(!list_Accounts.isEmpty(), 'Invalid Test Account data');
		return list_Accounts[0];
	}

	/**
	 * @description  Service function to get Test Tickets
	 * @param strRef The Ticket reference
	 * @return       `Ticket__c`
	 */
	static Ticket__c getTicket(String strRef) {
		List<Ticket__c> list_Tickets = [SELECT Id, Account__c, Status__c FROM Ticket__c WHERE Status__c = :strRef];
		System.assert(!list_Tickets.isEmpty(), 'Invalid Test Ticket data');
		return list_Tickets[0];
	}
}