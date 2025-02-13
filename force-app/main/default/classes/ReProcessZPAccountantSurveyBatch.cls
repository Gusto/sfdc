/**
 * @name         : ReProcessZPAccountantSurveyBatch
 * @author       : Praveen Sethu
 * @date         : 05-19-2021
 * @description  : Hourly Batch Job to Re-Process Failed ZP Accountant Survey Responses
 * @test classes : ReProcessZPAccountantSurveyBatchTest
 **/

public with sharing class ReProcessZPAccountantSurveyBatch implements Database.Batchable<sObject>, Database.Stateful {
	public static final Set<String> PENDING_PROCESSING_STATES = new Set<String>{ 'Queued', 'Error' };
	public static Boolean blnTestException = false;

	public class ReProcessZPSurveyException extends Exception {
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'SELECT Id FROM ZP_Accountant_Survey_Response__c WHERE Processing_State__c IN :PENDING_PROCESSING_STATES AND Accountant_Lead_Id__c != null';
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<ZP_Accountant_Survey_Response__c> list_ZPSurveyResponses) {
		try {
			// Test Exception
			if (Test.isRunningTest() && blnTestException) {
				Integer intInfinity = 1 / 0;
			}

			if (list_ZPSurveyResponses != null && !list_ZPSurveyResponses.isEmpty()) {
				update list_ZPSurveyResponses;
			}
			if (Test.isRunningTest()) {
				// Insert custom exception when run during test class
				throw new ReProcessZPSurveyException('Insert custom exception for test class');
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ReProcessZPAccountantSurveyBatch', 'execute', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ReProcessZPAccountantSurveyBatch', false);
	}
}