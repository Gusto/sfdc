/*
 * @name         : ReProcessZPAccountantSurveyScheduler
 * @author       : Praveen Sethu
 * @date         : 05-19-2021
 * @description  : Scheduler class for ReProcessZPAccountantSurveyBatch
 * @test classes : ReProcessZPAccountantSurveyBatchTest
 **/

global with sharing class ReProcessZPAccountantSurveyScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new ReProcessZPAccountantSurveyBatch(), 10);
	}
}