/**
 * @name         : HIGroupEventBatch
 * @author       : Sanjay Paryani
 * @date         : 09/07/2021
 * @description  : Batch class which will pick any queued or errorred HI Group Events and reprocess them
 * @test classes : HIGroupEventBatchTest
 **/
public with sharing class HIGroupEventBatch implements Schedulable, Database.Batchable<SObject> {
	// If Group Event has been in 'Error' state for 10 days since creation, mark the record ‘Dead’
	public static final Integer intMarkDeadAfterDays = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HIGroupEventBatch_Dead_After_Days')
		.Value__c
	);
	// If Group Event has been in 'Error' state, reprocess it every 2nd hour based on Processed At
	public static final Integer intErrorReprocessHrs = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HIGroupEventBatch_Reprocess_Hours')
		.Value__c
	);
	// For any Group Event that is in 'Dead' state and one of the conditions is true,
	// 1. Deleted_At__c populated
	// 2. It has been 30 days or earlier since it was last Processed
	public static final Integer intDeleteAfterDays = Integer.valueof(
	  HI_Configuration__mdt.getInstance('HIGroupEventBatch_Delete_After_Days')
		.Value__c
	);
  
	public static final String BATCH_CLASS_NAME = 'HIGroupEventBatch';
	public static final String FILTER_TYPE_BASE_QUERY = 'Base Query';
	public static final String FILTER_TYPE_WHERE_CLAUSE = 'Where Clause';
	public static final String FILTER_TYPE_ORDER_BY = 'Order By';
	public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
  
	public Map<String, HI_Configuration__mdt> map_HIConfigurations;
  
	public void execute(SchedulableContext objSC) {
	  Integer intBatchSize = 10;
	  HIGroupEventBatch objBatch = new HIGroupEventBatch();
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
		'SELECT Id,Processing_State__c,Processed_At__c,CreatedDate' +
		' FROM HIGroupEvent__c WHERE Processing_State__c IN (\'Error\', \'Dead\') ORDER BY CreatedDate DESC';
  
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
	  HIGroupEventTriggerHelper.queue = true;
	  Boolean blnHasEventsToSkipTrigger = false;
  
	  DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
	  DateTime dtReprocessCheck = System.now().addHours(-intErrorReprocessHrs);
	  DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
  
	  List<HIGroupEvent__c> list_HIGroupEventToUpdate = new List<HIGroupEvent__c>();
	  List<HIGroupEvent__c> list_HIGroupEventToProcess = new List<HIGroupEvent__c>();
	  List<HIGroupEvent__c> list_HIGroupEventToDelete = new List<HIGroupEvent__c>();
  
	  List<HIGroupEvent__c> list_HiGroupEvents = (List<HIGroupEvent__c>) scope;
	  for (HIGroupEvent__c objHIGroupEvent : list_HiGroupEvents) {
		if (objHIGroupEvent.Processing_State__c == IntegrationUtils.DEAD_STATE) {
		  if (
			(objHIGroupEvent.Processed_At__c == null &&
			objHIGroupEvent.CreatedDate < dtDeleteCheck) ||
			(objHIGroupEvent.Processed_At__c != null &&
			objHIGroupEvent.Processed_At__c < dtDeleteCheck)
		  ) {
			list_HIGroupEventToDelete.add(objHIGroupEvent);
			blnHasEventsToSkipTrigger = true;
		  }
		} else if (
		  objHIGroupEvent.Processing_State__c == IntegrationUtils.ERROR_STATE
		) {
		  if (objHIGroupEvent.CreatedDate < dtDeadCheck) {
			objHIGroupEvent.Processing_State__c = IntegrationUtils.DEAD_STATE;
			objHIGroupEvent.Processed_At__c = System.now();
			list_HIGroupEventToUpdate.add(objHIGroupEvent);
			blnHasEventsToSkipTrigger = true;
		  } else if (
			objHIGroupEvent.Processed_At__c != null &&
			objHIGroupEvent.Processed_At__c < dtReprocessCheck
		  ) {
			list_HIGroupEventToProcess.add(objHIGroupEvent);
		  }
		} else {
		  list_HIGroupEventToProcess.add(objHIGroupEvent);
		}
	  }
  
	  if (!list_HIGroupEventToProcess.isEmpty()) {
		update list_HIGroupEventToProcess;
	  }
  
	  if (blnHasEventsToSkipTrigger) {
		Boolean blnHIEventSkipTriggerFlag = HIGroupEventTriggerHelper.skipTrigger;
		HIGroupEventTriggerHelper.skipTrigger = true;
		if (!list_HIGroupEventToDelete.isEmpty()) {
		  delete list_HIGroupEventToDelete;
		}
  
		if (!list_HIGroupEventToUpdate.isEmpty()) {
		  update list_HIGroupEventToUpdate;
		}
		HIGroupEventTriggerHelper.skipTrigger = blnHIEventSkipTriggerFlag;
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
	  String strSubject = 'HIGroupEvent__c ' + objJob.Status;
	  String strBody =
		'Records processed ' +
		objJob.TotalJobItems +
		' with ' +
		objJob.NumberOfErrors +
		' failures.';
  
	  if (objJob.NumberOfErrors > 0) {
		ExceptionLogUtil.logException(
		  'HIGroupEventBatch',
		  'execute',
		  strSubject,
		  strBody
		);
	  }
	}
  }