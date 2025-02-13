/**
 * @name         ZPCompanyMigrationBatchScheduler
 * @author       Praveen Sethu
 * @date        06/27/2021
 * @description  Scheduler class for ZPCompanyMigrationBacklogBatch
 * @test classes ZPCompanyMigrationBacklogBatchTest
 **/
global with sharing class ZPCompanyMigrationBatchScheduler implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		String strQuery = '';
		if (Test.isRunningTest()) {
			strQuery = 'SELECT Id, Company_Id__c FROM ZP_Company_Migration__c WHERE Company_Id__c != null';
		}

		Database.executeBatch(new ZPCompanyMigrationBacklogBatch(strQuery), Integer.valueOf(Label.ZP_Company_Migration_Batch_Size));
	}
}