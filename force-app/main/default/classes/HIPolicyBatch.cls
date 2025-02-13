/**
 * @description HI Policy Batch
 * @see HIPolicyTriggerHelperTest
 */
public with sharing class HIPolicyBatch implements Database.Batchable<sObject> {
	public static final String BATCH_CLASS_NAME = 'HIPolicyBatch';

	// If Group Event has been in 'Error' state for 10 days since creation, mark the record ‘Dead’
	public static Integer intMarkDeadAfterDays = Integer.valueof(HI_Configuration__mdt.getInstance('HIPolicyBatch_Dead_After_Days').Value__c);
	// For any Group Event that is in 'Dead' state and one of the conditions is true,
	// 1. Deleted_At__c populated
	// 2. It has been 30 days or earlier since it was last Processed
	public static Integer intDeleteAfterDays = Integer.valueof(HI_Configuration__mdt.getInstance('HIPolicyBatch_Delete_After_Days').Value__c);

	public Map<String, HI_Configuration__mdt> map_HIConfigurations;

	public HIPolicyBatch() {
		// Default value
		intMarkDeadAfterDays = 7;
		intDeleteAfterDays = 180;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(BATCH_CLASS_NAME);
		String strQuery =
			'SELECT Id, Message__c, Processing_State__c FROM HI_Policy__c WHERE Processing_State__c IN (\'Error\', \'Queued\') ' +
			' OR (Processing_State__c=\'Backlog\' AND LastModifiedDate >= LAST_N_DAYS:30)';
		if (map_HIConfigurations != null) {
			if (map_HIConfigurations.containsKey(HIBatchUtil.FILTER_TYPE_BASE_QUERY) && String.isNotBlank(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_BASE_QUERY).Value__c)) {
				strQuery = map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_BASE_QUERY).Value__c;
			}

			if (map_HIConfigurations.containsKey(HIBatchUtil.FILTER_TYPE_WHERE_CLAUSE) && String.isNotBlank(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_WHERE_CLAUSE).Value__c)) {
				DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
				DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
				strQuery += ' ' + HIBatchUtil.getHIBatchConfigWhereClause(map_HIConfigurations.get(HIBatchUtil.FILTER_TYPE_WHERE_CLAUSE).Value__c, intMarkDeadAfterDays, intDeleteAfterDays);
			}
		}

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		try {
			HIPolicyTriggerHelper.queue = true;
			List<HI_Policy__c> policyList = new List<HI_Policy__c>();
			if (intMarkDeadAfterDays < 0) {
				throw new CustomException('Mark Dead After Days value cannot be negative.');
			}
			if (intDeleteAfterDays < 0) {
				throw new CustomException('Delete After Days cannot be negative.');
			}
			DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
			DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
			List<HI_Policy__c> list_PoliciesToDelete = new List<HI_Policy__c>();

			for (HI_Policy__c objPolicy : (List<HI_Policy__c>) scope) {
				if (objPolicy.Processing_State__c == HIBatchUtil.PROCESSING_STATE_DEAD && objPolicy.CreatedDate < dtDeleteCheck) {
					list_PoliciesToDelete.add(objPolicy);
				} else if (
					(objPolicy.Processing_State__c == HIBatchUtil.PROCESSING_STATE_ERROR || objPolicy.Processing_State__c == HIBatchUtil.PROCESSING_STATE_BACKLOG) &&
					objPolicy.CreatedDate < dtDeadCheck
				) {
					objPolicy.Processing_State__c = HIBatchUtil.PROCESSING_STATE_DEAD;
					policyList.add(objPolicy);
				} else if (objPolicy.Message__c != HIBatchUtil.BEN_PACKAGE_MISSING) {
					policyList.add(objPolicy);
				}
			}

			if (!list_PoliciesToDelete.isEmpty()) {
				delete list_PoliciesToDelete;
			}
			if (!policyList.isEmpty()) {
				update policyList;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('HIPolicyBatch', 'execute', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new HICarrierInformationBatch(), 10);
		Database.executeBatch(new HIAasmEventsBatch(), 10);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'HIPolicyBatch', false);
	}

	public class CustomException extends Exception {
	}
}