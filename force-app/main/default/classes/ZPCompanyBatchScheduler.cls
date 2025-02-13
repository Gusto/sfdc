/**
 * @name         : ZPCompanyBatchScheduler
 * @author       : Praveen Sethu
 * @date         : 11-19-2021
 * @description  : Schedule Batch classes to re-process pending (queued and error) companies
 * @test classes : ZPCompanyBatchSchedulerTest
 **/
global with sharing class ZPCompanyBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Integer intBatch;
		Integer intThreshold = 5;
		Integer intTotalRemaining = 200;

		List<String> list_BatchPendingStatus = new List<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };
		// Check if there are any existing batch jobs running
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		intThreshold = config?.Job_Threshold__c?.intValue() != null && config?.Job_Threshold__c?.intValue() != 0 ? config.Job_Threshold__c.intValue() : 5;
		intTotalRemaining = config?.Total_Items_Remaining__c?.intValue() != null && config?.Total_Items_Remaining__c?.intValue() != 0 ? config.Total_Items_Remaining__c.intValue() : 200;

		// Abort old jobs before starting a new one
		List<AsyncApexJob> list_jobs = [SELECT Id, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Status IN :list_BatchPendingStatus AND ApexClass.Name IN ('ZPCompanyBatch') LIMIT 150];

		// Add dummy apex job during test runs
		if (Test.isRunningTest()) {
			list_jobs.add(new AsyncApexJob());
		}
		if (!list_jobs.isEmpty()) {
			try {
				for (AsyncApexJob job : list_jobs) {
					if (job.TotalJobItems - job.JobItemsProcessed > intTotalRemaining) {
						System.abortJob(job.Id);
					}
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('ZPCompanyBatchScheduler', 'process', ex);
			}
		}

		AggregateResult numAsyncJobs = [SELECT COUNT(id) JOB_COUNT FROM AsyncApexJob WHERE Status IN :list_BatchPendingStatus AND JOBTYPE = 'BatchApex'];

		if (Integer.valueOf(numAsyncJobs.get('JOB_COUNT')) > intThreshold) {
			intBatch = config?.ZP_Company_Batch_Size__c?.intValue() != null && config?.ZP_Company_Batch_Size__c?.intValue() != 0 ? config.ZP_Company_Batch_Size__c.intValue() : 10;
		} else {
			intBatch = config?.Night_Batch_Size_Company__c?.intValue() != null && config?.Night_Batch_Size_Company__c?.intValue() != 0 ? config.Night_Batch_Size_Company__c.intValue() : 25;
		}

		Database.executeBatch(new ZPCompanyBatch(), intBatch);
	}
}