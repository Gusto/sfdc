public with sharing class HICarrierVersionDetailBatch implements Schedulable, Database.Batchable<SObject> {
	// If CarrierVersion  has been in 'Error' state for 10 days since creation, mark the record ‘Dead’
	public static final Integer intMarkDeadAfterDays = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HICarrierVersionDetailBatch_Dead_After')
		.Value__c
	);
	// If CarrierVersion  has been in 'Error' state, reprocess it every 2nd hour based on Processed At
	public static final Integer intErrorReprocessHrs = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HICarrierVersionDetailBatch_Reprocess')
		.Value__c
	);
	// For any CarrierVersion  that is in 'Dead' state and one of the conditions is true,
	// 1. Deleted_At__c populated
	// 2. It has been 30 days or earlier since it was last Processed
  
	public static final Integer intDeleteAfterDays = Integer.valueof(
	  HI_Configuration__mdt.getInstance(
		  'HICarrierVersionDetailBatch_Delete_After'
		)
		.Value__c
	);
  
	public static final String BATCH_CLASS_NAME = 'HICarrierVersionDetailBatch';
	public static final String FILTER_TYPE_BASE_QUERY = 'Base Query';
	public static final String FILTER_TYPE_WHERE_CLAUSE = 'Where Clause';
	public static final String FILTER_TYPE_ORDER_BY = 'Order By';
	public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
  
	public Map<String, HI_Configuration__mdt> map_HIConfigurations;
  
	public void execute(SchedulableContext objSC) {
	  Integer intBatchSize = 10;
	  HICarrierVersionDetailBatch objBatch = new HICarrierVersionDetailBatch();
	  if (
		map_HIConfigurations != null &&
		map_HIConfigurations.containsKey(FILTER_TYPE_BATCH_SIZE) &&
		map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c != null
	  ) {
		intBatchSize = Integer.valueOf(
		  map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c
		);
	  }
  
	  Database.executeBatch(objBatch, intBatchSize);
	}
  
	public Database.QueryLocator start(
	  Database.BatchableContext objBatchContext
	) {
	  map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(BATCH_CLASS_NAME);
	  String strQuery = '';
	  String strDefaultQuery =
		'SELECT Id,Processing_State__c,Processed_At__c,CreatedDate' +
		' FROM HICarrierVersionDetail__c WHERE Processing_State__c IN (\'Error\', \'Dead\') ORDER BY CreatedDate DESC';
  
	  if (map_HIConfigurations != null) {
		if (
		  map_HIConfigurations.containsKey(FILTER_TYPE_BASE_QUERY) &&
		  String.isNotBlank(
			map_HIConfigurations.get(FILTER_TYPE_BASE_QUERY).Value__c
		  )
		) {
		  strQuery = map_HIConfigurations.get(FILTER_TYPE_BASE_QUERY).Value__c;
		}
  
		if (
		  map_HIConfigurations.containsKey(FILTER_TYPE_WHERE_CLAUSE) &&
		  String.isNotBlank(
			map_HIConfigurations.get(FILTER_TYPE_WHERE_CLAUSE).Value__c
		  )
		) {
			DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
			DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
			strQuery += ' '+ HIBatchUtil.getHIBatchConfigWhereClause(map_HIConfigurations.get(FILTER_TYPE_WHERE_CLAUSE).Value__c, intMarkDeadAfterDays, intDeleteAfterDays);                
		}
  
		if (
		  map_HIConfigurations.containsKey(FILTER_TYPE_ORDER_BY) &&
		  String.isNotBlank(
			map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c
		  )
		) {
		  strQuery +=
			' ' + map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c;
		}
	  }
  
	  if (Test.isRunningTest() || String.isBlank(strQuery)) {
		strQuery = strDefaultQuery;
	  }
  
	  return Database.getQueryLocator(strQuery);
	}
  
	public void execute(
	  Database.BatchableContext objBatchContext,
	  List<sObject> list_HICarrierVersions
	) {
	  HICarrierVersionDetailTriggerHandler.blnQueue = true;
	  Boolean blnHassToSkipTrigger = false;
	  DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
	  DateTime dtReprocessCheck = System.now().addHours(-intErrorReprocessHrs);
	  DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
  
	  List<HICarrierVersionDetail__c> list_HICarrierVersionDetailToUpdate = new List<HICarrierVersionDetail__c>();
	  List<HICarrierVersionDetail__c> list_HICarrierVersionsToProcess = new List<HICarrierVersionDetail__c>();
	  List<HICarrierVersionDetail__c> list_HICarrierVersionDetailToDelete = new List<HICarrierVersionDetail__c>();
  
	  List<HICarrierVersionDetail__c> list_HICarrierVs = (List<HICarrierVersionDetail__c>) list_HICarrierVersions;
	  for (
		HICarrierVersionDetail__c objHICarrierVersionDetail : list_HICarrierVs
	  ) {
		if (
		  objHICarrierVersionDetail.Processing_State__c ==
		  IntegrationUtils.DEAD_STATE
		) {
		  if (
			(objHICarrierVersionDetail.Processed_At__c == null &&
			objHICarrierVersionDetail.CreatedDate < dtDeleteCheck) ||
			(objHICarrierVersionDetail.Processed_At__c != null &&
			objHICarrierVersionDetail.Processed_At__c < dtDeleteCheck)
		  ) {
			list_HICarrierVersionDetailToDelete.add(objHICarrierVersionDetail);
			blnHassToSkipTrigger = true;
		  }
		} else if (
		  objHICarrierVersionDetail.Processing_State__c ==
		  IntegrationUtils.ERROR_STATE
		) {
		  if (objHICarrierVersionDetail.CreatedDate < dtDeadCheck) {
			objHICarrierVersionDetail.Processing_State__c = IntegrationUtils.DEAD_STATE;
			objHICarrierVersionDetail.Processed_At__c = System.now();
			list_HICarrierVersionDetailToUpdate.add(objHICarrierVersionDetail);
			blnHassToSkipTrigger = true;
		  } else if (
			objHICarrierVersionDetail.Processed_At__c != null &&
			objHICarrierVersionDetail.Processed_At__c < dtReprocessCheck
		  ) {
			list_HICarrierVersionsToProcess.add(objHICarrierVersionDetail);
		  }
		} else {
		  list_HICarrierVersionsToProcess.add(objHICarrierVersionDetail);
		}
	  }
  
	  if (!list_HICarrierVersionsToProcess.isEmpty()) {
		update list_HICarrierVersionsToProcess;
	  }
  
	  if (blnHassToSkipTrigger) {
		Boolean blnHISkipTriggerFlag = HICarrierVersionDetailTriggerHandler.blnSkipTrigger;
		HICarrierVersionDetailTriggerHandler.blnSkipTrigger = true;
		if (!list_HICarrierVersionDetailToDelete.isEmpty()) {
		  delete list_HICarrierVersionDetailToDelete;
		}
  
		if (!list_HICarrierVersionDetailToUpdate.isEmpty()) {
		  update list_HICarrierVersionDetailToUpdate;
		}
		HICarrierVersionDetailTriggerHandler.blnSkipTrigger = blnHISkipTriggerFlag;
	  }
	}
  
	public void finish(Database.BatchableContext objBatchContext) {
	  AsyncApexJob objAsyncJob = [
		SELECT Id, Status, NumberOfErrors, TotalJobItems
		FROM AsyncApexJob
		WHERE Id = :objBatchContext.getJobId()
	  ];
	  Utils.processBatchFinish(objAsyncJob, 'HICarrierVersionDetailBatch', false);
	}
  }