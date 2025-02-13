/**
 * @name         OpportunityPlayModeBatchScheduler
 * @author       Praveen Sethu
 * @date         03-07-2021
 * @description  Scheduler class for OpportunityPlayModeBatch
 * @test classes OpportunityPlayModeBatchTest
 **/
global with sharing class OpportunityPlayModeBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new OpportunityPlayModeBatch(), 20);
	}
}