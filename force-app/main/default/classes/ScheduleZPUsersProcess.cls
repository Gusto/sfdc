/**
 * @name         : ScheduleZPUsersProcess
 * @author       : David (Dato) Tsamalashvili
 * @date         : 10-13-2021
 * @description  : Scheduler class for ScheduleZPUsersProcess
 * @test classes : ScheduleZPUsersProcessTest
 **/
global class ScheduleZPUsersProcess implements Schedulable {
	global void execute(SchedulableContext sc) {
		List<String> list_BatchPendingStatus = new List<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };

		// Abort old jobs before starting a new one
		List<AsyncApexJob> list_jobs = [SELECT Id FROM AsyncApexJob WHERE Status IN :list_BatchPendingStatus AND ApexClass.Name IN ('BatchCleanUpZpUsers') LIMIT 150];

		// Add dummy apex job during test runs
		if (Test.isRunningTest()) {
			list_jobs.add(new AsyncApexJob());
		}
		if (!list_jobs.isEmpty()) {
			try {
				for (AsyncApexJob job : list_jobs) {
					System.abortJob(job.Id);
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('ScheduleZPUsersProcess', 'execute', ex.getMessage(), ex.getStackTraceString());
			}
		}

		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = config.Batch_Size__c.intValue() != null && config.Batch_Size__c.intValue() != 0 ? config.Batch_Size__c.intValue() : 100;

		database.executebatch(new BatchCleanUpZpUsers(), intBatch);
	}
}