public with sharing class HICarrierInformationBatch implements Database.Batchable<sObject> {
	public static final String BATCH_CLASS_NAME = 'HICarrierInformationBatch';

	// If Group Event has been in 'Error' state for 10 days since creation, mark the record ‘Dead’
	public static Integer intMarkDeadAfterDays;
	// For any Group Event that is in 'Dead' state and one of the conditions is true,
	// 1. Deleted_At__c populated
	// 2. It has been 30 days or earlier since it was last Processed
	public static Integer intDeleteAfterDays;

	public Map<String, HI_Configuration__mdt> map_HIConfigurations;

	public HICarrierInformationBatch() {
		// Default value
		intMarkDeadAfterDays = 7;
		intDeleteAfterDays = 180;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(BATCH_CLASS_NAME);
		String strQuery = 'SELECT Id FROM HI_Carrier_Information__c WHERE Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';

		if (map_HIConfigurations != null) {
			if (map_HIConfigurations.containsKey(HIBatchUtil.FILTER_TYPE_DEAD_AFTER_DAYS) && String.isNotBlank(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_DEAD_AFTER_DAYS).Value__c)) {
				intMarkDeadAfterDays = Integer.valueof(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_DEAD_AFTER_DAYS).Value__c);
			}

			if (map_HIConfigurations.containsKey(HIBatchUtil.FILTER_TYPE_DELETE_AFTER_DAYS) && String.isNotBlank(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_DELETE_AFTER_DAYS).Value__c)) {
				intDeleteAfterDays = Integer.valueof(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_DELETE_AFTER_DAYS).Value__c);
			}

			if (map_HIConfigurations.containsKey(HIBatchUtil.FILTER_TYPE_BASE_QUERY) && String.isNotBlank(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_BASE_QUERY).Value__c)) {
				strQuery = map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_BASE_QUERY).Value__c;
			}

			if (map_HIConfigurations.containsKey(HIBatchUtil.FILTER_TYPE_WHERE_CLAUSE) && String.isNotBlank(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_WHERE_CLAUSE).Value__c)) {		
				strQuery += ' ' + HIBatchUtil.getHIBatchConfigWhereClause(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_WHERE_CLAUSE).Value__c, intMarkDeadAfterDays, intDeleteAfterDays);
			}

			if (map_HIConfigurations.containsKey(HIBatchUtil.FILTER_TYPE_ORDER_BY) && String.isNotBlank(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_ORDER_BY).Value__c)) {
				strQuery += ' ' + map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_ORDER_BY).Value__c;
			}
		}
		DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
		DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		HICarrierInformationTriggerHelper.queue = true;
		updateRecords(scope);
	}

	public void updateRecords(List<HI_Carrier_Information__c> scope) {
		try {
			List<HI_Carrier_Information__c> list_HICarrierInformations = (List<HI_Carrier_Information__c>) scope;
			if (intMarkDeadAfterDays < 0) {
				throw new CustomException('Mark Dead After Days value cannot be negative.');
			}
			if (intDeleteAfterDays < 0) {
				throw new CustomException('Delete After Days cannot be negative.');
			}
			DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
			DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
			List<HI_Carrier_Information__c> list_HICarrierInformationToUpdate = new List<HI_Carrier_Information__c>();
			List<HI_Carrier_Information__c> list_HICarrierInformationToDelete = new List<HI_Carrier_Information__c>();

			for (HI_Carrier_Information__c objCarrierInformation : (List<HI_Carrier_Information__c>) scope) {
				if (objCarrierInformation.Processing_State__c == HIBatchUtil.PROCESSING_STATE_DEAD && objCarrierInformation.CreatedDate < dtDeleteCheck) {
					list_HICarrierInformationToDelete.add(objCarrierInformation);
				} else if (
					(objCarrierInformation.Processing_State__c == HIBatchUtil.PROCESSING_STATE_ERROR || objCarrierInformation.Processing_State__c == HIBatchUtil.PROCESSING_STATE_BACKLOG) &&
					objCarrierInformation.CreatedDate < dtDeadCheck
				) {
					objCarrierInformation.Processing_State__c = HIBatchUtil.PROCESSING_STATE_DEAD;
					list_HICarrierInformationToUpdate.add(objCarrierInformation);
				} else {
					list_HICarrierInformationToUpdate.add(objCarrierInformation);
				}
			}

			if (!list_HICarrierInformationToDelete.isEmpty()) {
				delete list_HICarrierInformationToDelete;
			}
			if (!list_HICarrierInformationToUpdate.isEmpty()) {
				update list_HICarrierInformationToUpdate;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('HICarrierInformationBatch', 'updateRecords', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void finish(Database.BatchableContext BC) {
		database.executeBatch(new HIBenefitsAdminBatch(), 10);
		database.executeBatch(new ZPRecoveryCaseBatch(), 1);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HICarrierInformationBatch', false);
	}

	public class CustomException extends Exception {
	}
}