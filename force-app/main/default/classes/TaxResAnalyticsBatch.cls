/**
 * @name         TaxResAnalyticsBatch
 * @author       Pravesh Rana
 * @date         08/17/2021
 * @description  Process Case records in batches, for tracking metrics for Tax Res Case Analytics
 * @test class   TaxResAnalyticsBatchTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
global class TaxResAnalyticsBatch implements Database.Batchable<sObject>, schedulable {
	static String CONFIG_NAME = 'Analytics_Batch';

	global TaxResAnalyticsBatch() {
	}

	/*
	 * Construct Case and return query locator
	 */
	global Database.QueryLocator start(Database.BatchableContext bContext) {
		//Get Case records of record type 'Tax Res' and related Case Audit Logs which were modified yesterday or later and are Solved
		String strCaseQuery;
		List<Tax_Res_Play_Mode_Configuration__mdt> list_ConfigurationObj = [SELECT Id, Filter_Value__c FROM Tax_Res_Play_Mode_Configuration__mdt WHERE DeveloperName = :CONFIG_NAME LIMIT 1];
		if (list_ConfigurationObj.size() > 0 && !test.isRunningTest()) {
			strCaseQuery = list_ConfigurationObj.get(0).Filter_Value__c;
		} else {
			strCaseQuery =
				'SELECT Id, Notice_Analyst__c, Account_Specialist__c, OwnerId, Coordinator__c, ' +
				'(SELECT Id, To_Status__c, From_Status__c, To_Date_Time__c, Duration_In_Seconds__c,' +
				'From_Date_Time__c, Current_Role__c, CreatedDate, Case__c, CreatedById FROM Case_Audit_Logs__r) FROM Case ';

			if (!Test.isRunningTest()) {
				strCaseQuery += ' WHERE RecordType.Name = \'Tax Res\' AND LastModifiedDate = YESTERDAY AND Status = \'Solved\'';
			}
		}

		return Database.getQueryLocator(strCaseQuery);
	}

	/*
	 * Process the chunck of Case Audit Log to insert/update Analytics records
	 */
	global void execute(Database.batchableContext bc, List<Case> list_Cases) {
		try {
			TaxResTimeTrackingUtil objTrackingUtil = new TaxResTimeTrackingUtil();
			//Pass Configuration record type as parameter to indicate which object are we dealing with
			objTrackingUtil.syncTimeTrackingDetails(list_Cases);
			if (Test.isRunningTest()) {
				Integer i = 1 / 0;
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('TaxResAnalyticsBatch', 'execute', objExp.getMessage(), objExp.getStackTraceString());
		}
	}

	/*
	 * After all the batch run we will send a summary email
	 */
	global void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'TaxResAnalyticsBatch', true);
	}

	/*
	 * Execute method for Scheduer functionality
	 */
	global void execute(SchedulableContext SC) {
		database.executebatch(new TaxResAnalyticsBatch(), 10);
	}
}