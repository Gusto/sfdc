/**
 * @author       Praveen Sethu
 * @description  Main batch class to process company records that are not linked to large firms
 * @see ZPCompanyBatchTest
 */
public without sharing class ZPCompanyBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'SELECT Id FROM ZP_Company__c WHERE Is_Large_Firm_Id__c = FALSE AND (Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\')';
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		try {
			ZPCompanyTriggerHelper.queue = true;
			List<ZP_Company__c> companyList = (List<ZP_Company__c>) scope;

			update companyList;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ZPCompanyBatch', 'execute', null, objException);
		}
	}

	public void finish(Database.BatchableContext BC) {
		List<String> list_BatchPendingStatus = new List<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();

		Integer intMigrationBatch = config.ZP_Company_Migration_Batch_Size__c != null &&
			config.ZP_Company_Migration_Batch_Size__c.intValue() != null &&
			config.ZP_Company_Migration_Batch_Size__c.intValue() != 0
			? config.ZP_Company_Migration_Batch_Size__c.intValue()
			: 1;

		Database.executeBatch(new ZPCompanyMigrationBatch(''), intMigrationBatch);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ZPCompanyBatch', false);

		// check if there are any large firms that need to be processed
		Integer intLargeFirmCount = [SELECT COUNT() FROM ZP_Company__c WHERE Is_Large_Firm_Id__c = TRUE AND Processing_State__c IN ('Queued', 'Error')];
		if (intLargeFirmCount > 0) {
			// Abort old jobs before starting a new one
			List<AsyncApexJob> list_jobs = [SELECT Id, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Status IN :list_BatchPendingStatus AND ApexClass.Name IN ('ZPCompanyLargeFirmBatch') LIMIT 150];

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
					ExceptionLogUtil.logException('ZPCompanyBatchScheduler', 'process', ex);
				}
			}

			Database.executeBatch(new ZPCompanyLargeFirmBatch(), 1);
		}
	}
}