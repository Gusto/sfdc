/**
 * @author		Neha Dabas
 * @date		3rd March/2019
 * @Description	Process Carrier Order Stage History records in batches, for tracking metrics for Benefits Transfer Analytics
 * @revisions	Date ------------ Name ------------ Comments
 */
global class BTCarrierOrderAnalyticsBatch implements Database.Batchable<sObject> {
	/*
	 * Construct CO History Query and return query locator
	 */
	global Database.QueryLocator start(Database.BatchableContext bContext) {
		//Get CArrier Order Stage History of record type Benefits BoR and which were modified yesterday or later and are not closed or cancelled

		Set<String> set_OrderStageToExclude = new Set<String>{ 'Closed Admin', 'Canceled' };

		String strCOQuery = 'SELECT CreatedDate,Carrier_Information_Name__c, TAdA__c,(SELECT From_Stage__c,To_Stage__c,Start_Time__c,End_Time__c FROM Carrier_Order_Stage_History__r)';
		strCOQuery += ' FROM Carrier_Order__c WHERE RecordType.Name = \'Benefits BoR\' AND LastmodifiedDate >= YESTERDAY AND Implementation_Stage__c NOT IN :set_OrderStageToExclude';

		return Database.getQueryLocator(strCOQuery);
	}
	/*
	 * Process the chunck of carrier Order history records to insert/update Analytics records
	 */
	global void execute(Database.batchableContext bc, List<Carrier_Order__c> lst_CO) {
		try {
			BTTimeTrackingUtil timeTrackingUtil = new BTTimeTrackingUtil();
			//Pass Configuration record type as parameter to indicate which object are we dealing with, CO or BO
			timeTRackingUtil.syncTimeTrackingDetails(lst_CO, 'Benefits Transfer CO');
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('BTCarrierOrderAnalyticsBatch', 'execute', objExp.getMessage(), objExp.getStackTraceString());
		}
	}
	global void finish(Database.BatchableContext bc) {
	}
}