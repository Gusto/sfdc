/**
 * @name         : ScheduleZPUsersAndRoles
 * @author       : Seshu Korivi
 * @date         : 03-23-2021
 * @description  : Scheduler class for ScheduleZPUsersAndRoles
 * @test classes : BatchCleanUpZpUsersTest
 **/
global class ScheduleZPUsersAndRoles implements Schedulable {
	global void execute(SchedulableContext sc) {
		List<String> list_BatchPendingStatus = new List<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };
		Id API_HEROKU_USER_ID = System.Label.Heroku_User;

		// Abort old jobs before starting a new one
		// Update for BSS-1519 - Abort only jobs created by API Heroku user (scheduled).
		// This batch is being re-purposed to process prioritized roles at the moment of their creation (by BizTech Integration user) which shouldn't be aborted.
		List<AsyncApexJob> list_jobs = [
			SELECT Id
			FROM AsyncApexJob
			WHERE Status IN :list_BatchPendingStatus AND ApexClass.Name IN ('BatchCleanUpZPUserRoles') AND CreatedById = :API_HEROKU_USER_ID
			LIMIT 150
		];

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
				ExceptionLogUtil.logException('ScheduleZPUsersAndRoles', 'execute', ex.getMessage(), ex.getStackTraceString());
			}
		}

		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = config.Batch_Size__c.intValue() != null && config.Batch_Size__c.intValue() != 0 ? config.Batch_Size__c.intValue() : 100;

		database.executebatch(new BatchCleanUpZPUserRoles(), intBatch);
	}
}