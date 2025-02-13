/**
    @Created by : Deepesh Rao
    @Created Date : 20-Feb-2023
    @Desc : Scheduler class to close ardius tickets as per close date
**/
global with sharing class BatchCloseArdiusTicketScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchCloseArdiusTickets batchObj = new BatchCloseArdiusTickets();
		Database.executeBatch(batchObj);
	}
}