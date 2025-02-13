public with sharing class HIAasmEventsBatch implements Schedulable, Database.Batchable<sObject> {
	// If Group Event has been in 'Error' state for 10 days since creation, mark the record ‘Dead’
	public static final Integer intMarkDeadAfterDays = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HIAasmEventsBatch_Dead_After_Days')
		.Value__c
	);
	// If Group Event has been in 'Error' state, reprocess it every 2nd hour based on Processed At
	public static final Integer intErrorReprocessHrs = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HIAasmEventsBatch_Reprocess_Hours')
		.Value__c
	);
	// For any Group Event that is in 'Dead' state and one of the conditions is true,
	// 1. Deleted_At__c populated
	// 2. It has been 30 days or earlier since it was last Processed
	public static final Integer intDeleteAfterDays = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HIAasmEventsBatch_Delete_After_Days')
		.Value__c
	);
  
	public static final String BATCH_CLASS_NAME = 'HIAasmEventsBatch';
	public static final String FILTER_TYPE_BASE_QUERY = 'Base Query';
	public static final String FILTER_TYPE_WHERE_CLAUSE = 'Where Clause';
	public static final String FILTER_TYPE_ORDER_BY = 'Order By';
	public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
  
	public Map<String, HI_Configuration__mdt> map_HIConfigurations;
  
	public void execute(SchedulableContext objSC) {
	  Integer intBatchSize = 10;
	  HIAasmEventsBatch objBatch = new HIAasmEventsBatch();
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
  
	public Database.QueryLocator start(Database.BatchableContext bc) {
	  map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(BATCH_CLASS_NAME);
	  String strQuery = '';
	  String strDefaultQuery =
		'SELECT Id,Processing_State__c,Last_Processed__c,CreatedDate' +
		' FROM HI_Aasm_Event__c WHERE Processing_State__c IN (\'Error\', \'Dead\') ORDER BY CreatedDate DESC';
  
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
  
	public void execute(Database.BatchableContext bc, List<sObject> scope) {
	  HIAasmEventTriggerHelper.queue = true;
	  Boolean blnHasEventsToSkipTrigger = false;
	  DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
	  DateTime dtReprocessCheck = System.now().addHours(-intErrorReprocessHrs);
	  DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
  
	  List<HI_Aasm_Event__c> list_HIAasmEventToUpdate = new List<HI_Aasm_Event__c>();
	  List<HI_Aasm_Event__c> list_HIAasmEventToProcess = new List<HI_Aasm_Event__c>();
	  List<HI_Aasm_Event__c> list_HIAasmEventToDelete = new List<HI_Aasm_Event__c>();
  
	  List<HI_Aasm_Event__c> list_HIAasmEvents = (List<HI_Aasm_Event__c>) scope;
	  for (HI_Aasm_Event__c objHIAasmEvent : list_HIAasmEvents) {
		if (objHIAasmEvent.Processing_State__c == IntegrationUtils.DEAD_STATE) {
		  if (
			(objHIAasmEvent.Last_Processed__c == null &&
			objHIAasmEvent.CreatedDate < dtDeleteCheck) ||
			(objHIAasmEvent.Last_Processed__c != null &&
			objHIAasmEvent.Last_Processed__c < dtDeleteCheck)
		  ) {
			list_HIAasmEventToDelete.add(objHIAasmEvent);
			blnHasEventsToSkipTrigger = true;
		  }
		} else if (
		  objHIAasmEvent.Processing_State__c == IntegrationUtils.ERROR_STATE
		) {
		  if (objHIAasmEvent.CreatedDate < dtDeadCheck) {
			objHIAasmEvent.Processing_State__c = IntegrationUtils.DEAD_STATE;
			objHIAasmEvent.Last_Processed__c = System.now();
			list_HIAasmEventToUpdate.add(objHIAasmEvent);
			blnHasEventsToSkipTrigger = true;
		  } else if (
			objHIAasmEvent.Last_Processed__c != null ||
			objHIAasmEvent.Last_Processed__c < dtReprocessCheck
		  ) {
			list_HIAasmEventToProcess.add(objHIAasmEvent);
		  }
		} else {
		  list_HIAasmEventToProcess.add(objHIAasmEvent);
		}
	  }
  
	  if (!list_HIAasmEventToProcess.isEmpty()) {
		update list_HIAasmEventToProcess;
	  }
  
	  if (blnHasEventsToSkipTrigger) {
		Boolean blnHIEventSkipTriggerFlag = HIAasmEventTriggerHelper.skipTrigger;
		HIAasmEventTriggerHelper.skipTrigger = true;
		if (!list_HIAasmEventToDelete.isEmpty()) {
		  delete list_HIAasmEventToDelete;
		}
  
		if (!list_HIAasmEventToUpdate.isEmpty()) {
		  update list_HIAasmEventToUpdate;
		}
		HIAasmEventTriggerHelper.skipTrigger = blnHIEventSkipTriggerFlag;
	  }
	}
  
	public void finish(Database.BatchableContext BC) {
	  // Creating a exception log record only if there are errors in processing a batch of records.
	  AsyncApexJob objJob = [
		SELECT
		  Id,
		  Status,
		  ExtendedStatus,
		  NumberOfErrors,
		  JobItemsProcessed,
		  TotalJobItems,
		  CreatedBy.Email
		FROM AsyncApexJob
		WHERE Id = :BC.getJobId()
	  ];
	  String strSubject = 'HI_Aasm_Event__c ' + objJob.Status;
	  String strBody =
		'Records processed ' +
		objJob.TotalJobItems +
		' with ' +
		objJob.NumberOfErrors +
		' failures.';
  
	  if (objJob.NumberOfErrors > 0) {
		ExceptionLogUtil.logException(
		  'HIAasmEventsBatch',
		  'execute',
		  strSubject,
		  strBody
		);
	  }
	}
  }