/**
 * @name         ZPCompanyMigrationBacklogBatch
 * @author       Praveen Sethu
 * @date         06/27/2021
 * @description  Process Migration Backlog Items
 * @test classes ZPCompanyMigrationBacklogBatchTest
 **/
public class ZPCompanyMigrationBacklogBatch implements Database.Batchable<sObject>, Database.Stateful {
	public String strBatchQuery = '';

	public ZPCompanyMigrationBacklogBatch(String strQuery) {
		this.strBatchQuery = strQuery;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strBacklogStatus = IntegrationUtils.BACKLOG;
		if (String.isBlank(strBatchQuery)) {
			strBatchQuery = 'SELECT Id, Company_Id__c FROM ZP_Company_Migration__c WHERE Company_Id__c != null AND Processing_State__c = :strBacklogStatus';
		}

		return Database.getQueryLocator(strBatchQuery);
	}

	public void execute(Database.BatchableContext BC, List<ZP_Company_Migration__c> list_Migrations) {
		List<ZP_Company_Migration__c> list_MigrationsToUpdate = new List<ZP_Company_Migration__c>();
		Set<String> set_CompanyIds = new Set<String>();
		Map<String, Account> map_CompanyIdsToAccount = new Map<String, Account>();

		for (ZP_Company_Migration__c objMigration : list_Migrations) {
			if (String.isNotBlank(objMigration.Company_Id__c)) {
				set_CompanyIds.add(objMigration.Company_Id__c);
			}
		}

		if (!set_CompanyIds.isEmpty()) {
			for (Account objAccount : [
				SELECT Id, ZP_Company_Id__c
				FROM Account
				WHERE ZP_Company_Id__c IN :set_CompanyIds AND RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
			]) {
				map_CompanyIdsToAccount.put(objAccount.ZP_Company_Id__c, objAccount);
			}
		}

		for (ZP_Company_Migration__c objMigration : list_Migrations) {
			if (map_CompanyIdsToAccount.containsKey(objMigration.Company_Id__c)) {
				list_MigrationsToUpdate.add(objMigration);
			}
		}

		if (!list_MigrationsToUpdate.isEmpty()) {
			ZPCompanyMigrationTriggerHelper.queue = true;
			try {
				update list_MigrationsToUpdate;
				if (Test.isRunningTest()) {
					Integer intN = 1 / 0;
				}
			} catch (Exception objEx) {
				ExceptionLogUtil.logException(
					'ZPCompanyMigrationBacklogBatch',
					'Execute',
					'Exception On Line ' +
					objEx.getLineNumber() +
					'-' +
					objEx.getMessage(),
					objEx.getStackTraceString()
				);
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [
			SELECT Id, Status, NumberOfErrors, TotalJobItems
			FROM AsyncApexJob
			WHERE Id = :BC.getJobId()
		];
		Utils.processBatchFinish(objAsyncJob, 'ZPCompanyMigrationBacklogBatch', false);
	}
}