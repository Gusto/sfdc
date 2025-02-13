/**
 * @name         BTBenefitOrderAnalyticsBatch
 * @author       Neha Dabas
 * @date         03/03/2020
 * @description  Process Benfit Order records in batches, for tracking metrics for Benefits Transfer Analytics
 * @test class   BTBenefitOrderAnalyticsBatchTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
global class BTBenefitOrderAnalyticsBatch implements Database.Batchable<sObject> {
	/*
	 * Construct BO Query and return query locator
	 */
	global Database.QueryLocator start(Database.BatchableContext bContext) {
		//Get Benefit Order and related Benefit Order Status History of record type Benefits BoR and which were modified yesterday or later and are not closed or cancelled

		Set<String> set_StatusToExclude = new Set<String>{ 'Canceled', 'Closed Lost', 'Closed Admin' };

		String strBOQuery = 'SELECT Type__c,CreatedDate, (SELECT Id,From_Status__c,To_Status__c,Start_Time__c,End_Time__c FROM Benefit_Order_Status_Change_History__r)';
		strBOQuery += ' FROM Benefit_Order__c WHERE RecordType.Name = \'Benefits BoR\' AND LastModifiedDate >= YESTERDAY AND Order_Status__c NOT IN :set_StatusToExclude';

		return Database.getQueryLocator(strBOQuery);
	}
	/*
	 * Process the chunck of benefit Order  history records to insert/update Analytics records
	 */
	global void execute(Database.batchableContext bc, List<Benefit_Order__c> lst_BO) {
		try {
			BTTimeTrackingUtil timeTrackingUtil = new BTTimeTrackingUtil();
			//Pass Configuration record type as parameter to indicate which object are we dealing with, CO or BO
			timeTRackingUtil.syncTimeTrackingDetails(lst_BO, 'Benefits Transfer BO');
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('BTBenefitOrderAnalyticsBatch', 'execute', objExp.getMessage(), objExp.getStackTraceString());
		}
	}
	global void finish(Database.BatchableContext bc) {
	}
}