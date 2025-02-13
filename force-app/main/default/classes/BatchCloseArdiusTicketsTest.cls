@isTest
public class BatchCloseArdiusTicketsTest {
	@testSetup
	static void setup() {
		//create the Account
		AccountTriggerHelper.skipTrigger = true;
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setOwnerId(UserInfo.getUserId()).setName('Test Co.').build();
		insert objCompanyAccount;

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objArdiusSalesOpp = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setOwnerId(UserInfo.getUserId())
			.setName('Test Tax Credits Opp')
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setCloseDate(Date.today() + 30)
			.setStage('New')
			.build();
		insert objArdiusSalesOpp;

		TicketTriggerHelper.skipTrigger = true;
		Ticket__c objArdiusTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Ticket__c', 'Ardius'))
			.setOwnerId(UserInfo.getUserId())
			.setStatus('Calc Approval Pending')
			.setAccountId(objCompanyAccount.Id)
			.setOppId(objArdiusSalesOpp.Id)
			.setAnticipatedCloseDate(system.today())
			.build();
		objArdiusTicket.Ticket_Status_Change_Date__c = Date.Today().addDays(-14);
		insert objArdiusTicket;
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : Test method for BatchCloseArdiusTicketScheduler schedule apex
	 **/
	static testMethod void testBatchScheduler() {
		BatchCloseArdiusTicketScheduler objScheduler = new BatchCloseArdiusTicketScheduler();
		String strSchedule = '0 0 0 1 * ? *';
		Test.startTest();
		String strJobId = System.schedule('Test close opps schedule', strSchedule, objScheduler);
		Test.stopTest();

		System.assert(strJobId != null);
	}

	@isTest
	static void ardiusTicketsClosureTest() {
		String strTASK_FEATURE_REQUEST = TaskUtil.TASK_FEATURE_REQUEST;
		String strTICKET_STATUS_CALC_APPROVAL_PENDING = TicketUtil.TICKET_STATUS_CALC_APPROVAL_PENDING;
		String strARDIUS_TICKET_RT_ID = TicketUtil.ARDIUS_TICKET_RT_ID;
		test.startTest();
		Database.executeBatch(new BatchCloseArdiusTickets(), 10);
		test.stopTest();

		Ticket__c objArdiusTicket = [
			SELECT Id, Ticket_Status_Change_Date__c, Opportunity__c, OwnerId
			FROM Ticket__c
			WHERE Status__c = :strTICKET_STATUS_CALC_APPROVAL_PENDING AND Ticket_Status_Change_Date__c < Last_N_Days:13 AND RecordTypeId = :strARDIUS_TICKET_RT_ID
		];

		List<Task> lst_Tasks = [
			SELECT Id
			FROM Task
			WHERE WhatId = :objArdiusTicket.Opportunity__c AND Feature_Request__c = :strTASK_FEATURE_REQUEST
		];

		system.assertEquals(lst_Tasks.size() > 0, true, 'No APPROVAL_CALL Tasks Records found');
	}
}