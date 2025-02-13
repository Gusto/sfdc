/**
 * @Author       :   Deepesh Rao
 * @CreatedDate  :   01/29/2023
 * @Desc         :   Batch Job to close Ardius Tickets which are matching the close date as Today
 * @TestClass    :   BatchCloseArdiusTicketsTest
 *
 * @UpdatedDate  : 03/27/2024
 * @Desc         :   Batch Job to create an automated task if a ticket has been sitting in the "Calc Approval Pending" for 13 days (9 business days)
 * @TestClass    :   BatchCloseArdiusTicketsTest
 **/
public class BatchCloseArdiusTickets implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext context) {
		String strTASK_FEATURE_REQUEST = TaskUtil.TASK_FEATURE_REQUEST;
		String strTICKET_STATUS_CALC_APPROVAL_PENDING = TicketUtil.TICKET_STATUS_CALC_APPROVAL_PENDING;
		String strARDIUS_TICKET_RT_ID = TicketUtil.ARDIUS_TICKET_RT_ID;
		string queryString = 'SELECT Id,Opportunity__c FROM Ticket__c WHERE Status__c = :strTICKET_STATUS_CALC_APPROVAL_PENDING AND Ticket_Status_Change_Date__c < Last_N_Days:13 AND RecordTypeId= :strARDIUS_TICKET_RT_ID';
		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext context, List<Ticket__c> ticketRecords) {
		try {
			List<Task> list_Tasks = new List<Task>();
			set<Id> set_OppIds = new Set<Id>();

			for (Ticket__c ticketRec : ticketRecords) {
				set_OppIds.add(ticketRec.Opportunity__c);
			}

			List<Opportunity> list_Opps = [SELECT Id, OwnerId, Account.Name, (SELECT Id FROM Tasks WHERE Feature_Request__c = :TaskUtil.TASK_FEATURE_REQUEST) FROM Opportunity WHERE Id IN :set_OppIds];

			for (Opportunity oppRec : list_Opps) {
				if (oppRec.Tasks.size() == 0) {
					list_Tasks.add(
						new Task(
							RecordTypeId = TaskUtil.TASK_STANDARD_RT_ID,
							OwnerId = oppRec.OwnerId,
							ActivityDate = CaseUtils.getNBusinessDaysAfter(3),
							Priority = TaskUtil.TASK_PRIORITY_NORMAL,
							Status = TaskUtil.TASK_STATUS_OPEN,
							Subject = TaskUtil.TASK_SUBJECT_APPROVAL_CALL + oppRec.Account.Name,
							Type = TaskUtil.TASK_TYPE_FOLLOW_UP,
							WhatId = oppRec.Id,
							Feature_Request__c = TaskUtil.TASK_FEATURE_REQUEST
						)
					);
				}
			}
			insert list_Tasks;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('BatchCloseArdiusTickets', 'execute', null, objException);
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}