/**
 * @name         : S3FileArchivalBatchScheduler
 * @author       : David (Dato) Tsamalshvili
 * @date         : 11-23-2022
 * @description  : Scheduler class for S3FileArchivalBatch
 * @test classes : S3FileArchivalBatchTest
 **/
global with sharing class S3FileArchivalBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		//Execute Batch
		Database.executebatch(new S3FileArchivalBatch('', '', false), 50);
	}
}