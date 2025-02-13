/**
 * @name         : ZPUserRoleAccountantScheduler
 * @author       : Praveen Sethu
 * @date         : 03-24-2021
 * @description  : Scheduler class to schedule batch class
 * @test classes : ZPUserRoleAccountantBatchTest
 **/
global with sharing class ZPUserRoleAccountantScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new ZPUserRoleAccountantBatch(), 50);
	}
}