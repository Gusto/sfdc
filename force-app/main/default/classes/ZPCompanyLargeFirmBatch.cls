/**
 * @author       Praveen Sethu
 * @description  Main batch class to process company records that are linked to large firms
 * @see ZPCompanyBatchTest
 */
public without sharing class ZPCompanyLargeFirmBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'SELECT Id FROM ZP_Company__c WHERE Is_Large_Firm_Id__c = TRUE AND (Processing_State__c=\'Error\' OR Processing_State__c=\'Queued\')';
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		try {
			ZPCompanyTriggerHelper.queue = true;
			List<ZP_Company__c> list_Companies = (List<ZP_Company__c>) scope;

			update list_Companies;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ZPCompanyLargeFirmBatch', 'execute', null, objException);
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}