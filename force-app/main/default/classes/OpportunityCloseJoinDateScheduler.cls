/*
 * @name         OpportunityCloseJoinDateScheduler
 * @author       Praveen Sethu
 * @date         07-03-20201
 * @description  Schedules Batch Class
 * @test classes OpportunityCloseJoinDateSchedulerTest
 */
global with sharing class OpportunityCloseJoinDateScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new OpportunityCloseJoinDateJob(), 10);
	}
}