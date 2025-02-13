/*
 * @name         : OpportunityJobsScheduler
 * @author       : David (Dato) Tsamalashvili
 * @date         : 04-21-2021
 * @description  : Scheduler class for OpportunityJobs
 * @test classes : OpportunityJobsTest
 **/
global with sharing class OpportunityJobsScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new OpportunityJobs(''), 50);
	}
}