/**
 * @name         : BenefitsNewPlanOppCreationBatchScheduler
 * @author       : Debasmita Rawooth
 * @date         : 11-10-2021
 * @description  : Scheduler class for BenefitsNewPlanOppCreationBatch.
 * @test classes : BenefitsNewPlanOppCreationBatchTest
 **/
global class BenefitsNewPlanOppCreationBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		database.executebatch(new BenefitsNewPlanOppCreationBatch(), 20);
	}
}