public with sharing class HIFulfillmentEventBatch implements Schedulable, Database.Batchable<SObject> {
    // If Fulfillment Event has been in 'Error' state for 10 days since creation, mark the record ‘Dead’
    public static final Integer intMarkDeadAfterDays = Integer.valueof(HI_Configuration__mdt.getInstance('HIFulfillmentEventBatch_Dead_After_Days').Value__c);
    // If Fulfillment Event has been in 'Error' state, reprocess it every 2nd hour based on Processed At
    public static final Integer intErrorReprocessHrs = Integer.valueof(HI_Configuration__mdt.getInstance('HIFulfillmentEventBatch_Reprocess_Hours').Value__c);
    // For any Fulfillment Event that is in 'Dead' state and one of the conditions is true,
    // 1. Deleted_At__c populated
    // 2. It has been 180 days or earlier since it was last Processed
    public static final Integer intDeleteAfterDays = Integer.valueof(HI_Configuration__mdt.getInstance('HIFulfillmentEventBatch_Delete_After_Day').Value__c);
    
    public static final String BATCH_CLASS_NAME = 'HIFulfillmentEventBatch';
    public static final String FILTER_TYPE_BASE_QUERY = 'Base Query';
    public static final String FILTER_TYPE_WHERE_CLAUSE = 'Where Clause';
    public static final String FILTER_TYPE_ORDER_BY = 'Order By';
    public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
    
    public Map<String, HI_Configuration__mdt> map_HIConfigurations;
    
    public void execute(SchedulableContext objSC) {
        Integer intBatchSize = 10;
        HIFulfillmentEventBatch objBatch = new HIFulfillmentEventBatch();
        if (map_HIConfigurations != null && map_HIConfigurations.containsKey(FILTER_TYPE_BATCH_SIZE) && map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c != null) {
            intBatchSize = Integer.valueOf(map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c);
        }
        
        Database.executeBatch(objBatch, intBatchSize);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(BATCH_CLASS_NAME);
        String strQuery = '';
        String strDefaultQuery = 'SELECT Id,Processing_State__c,Processed_At__c,CreatedDate' +
            ' FROM HI_Fulfillment_Event__c WHERE Processing_State__c IN (\'Error\', \'Dead\') ORDER BY CreatedDate DESC';
        
        if (map_HIConfigurations != null) {
            if (map_HIConfigurations.containsKey(FILTER_TYPE_BASE_QUERY) && String.isNotBlank(map_HIConfigurations.get(FILTER_TYPE_BASE_QUERY).Value__c)) {
                strQuery = map_HIConfigurations.get(FILTER_TYPE_BASE_QUERY).Value__c;
            }
            
            if (map_HIConfigurations.containsKey(FILTER_TYPE_WHERE_CLAUSE) && String.isNotBlank(map_HIConfigurations.get(FILTER_TYPE_WHERE_CLAUSE).Value__c)) {
                DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
                DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
                strQuery += ' '+ HIBatchUtil.getHIBatchConfigWhereClause(map_HIConfigurations.get(FILTER_TYPE_WHERE_CLAUSE).Value__c, intMarkDeadAfterDays, intDeleteAfterDays);                
            }
            
            if (map_HIConfigurations.containsKey(FILTER_TYPE_ORDER_BY) && String.isNotBlank(map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c)) {
                strQuery += ' ' + map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c;
            }
        }
        
        if(Test.isRunningTest() || String.isBlank(strQuery)) {
            strQuery = strDefaultQuery;
        }
        
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        HIFulfillmentEventTriggerHelper.queue = true;
        Boolean blnHasEventsToSkipTrigger = false;
        DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
        DateTime dtReprocessCheck = System.now().addHours(-intErrorReprocessHrs);
        DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
        
        List<HI_Fulfillment_Event__c> list_HIFulfillmentEventToUpdate = new List<HI_Fulfillment_Event__c>();
        List<HI_Fulfillment_Event__c> list_HIFulfillmentEventToProcess = new List<HI_Fulfillment_Event__c>();
        List<HI_Fulfillment_Event__c> list_HIFulfillmentEventToDelete = new List<HI_Fulfillment_Event__c>();
        
        List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents = (List<HI_Fulfillment_Event__c>) scope;
        for(HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents){
            if (objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE) {
                if ((objHIFulfillmentEvent.Processed_At__c == null && objHIFulfillmentEvent.CreatedDate < dtDeleteCheck) || (objHIFulfillmentEvent.Processed_At__c != null && objHIFulfillmentEvent.Processed_At__c < dtDeleteCheck)) {
                    list_HIFulfillmentEventToDelete.add(objHIFulfillmentEvent);
                    blnHasEventsToSkipTrigger = true;
                }
            } else if (objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
                if (objHIFulfillmentEvent.CreatedDate < dtDeadCheck) {
                    objHIFulfillmentEvent.Processing_State__c = IntegrationUtils.DEAD_STATE;
                    objHIFulfillmentEvent.Processed_At__c = System.now();
                    list_HIFulfillmentEventToUpdate.add(objHIFulfillmentEvent);
                    blnHasEventsToSkipTrigger = true;
                } else if (objHIFulfillmentEvent.Processed_At__c != null && objHIFulfillmentEvent.Processed_At__c < dtReprocessCheck) {
                    list_HIFulfillmentEventToProcess.add(objHIFulfillmentEvent);
                }
            } else {
                list_HIFulfillmentEventToProcess.add(objHIFulfillmentEvent);
            }
        }
        
        
        if (!list_HIFulfillmentEventToProcess.isEmpty()) {
            update list_HIFulfillmentEventToProcess;
        }
        
        if (blnHasEventsToSkipTrigger) {
            Boolean blnHIEventSkipTriggerFlag = HIFulfillmentEventTriggerHelper.skipTrigger;
            HIFulfillmentEventTriggerHelper.skipTrigger = true;
            if (!list_HIFulfillmentEventToDelete.isEmpty()) {
                delete list_HIFulfillmentEventToDelete;
            }
            
            if (!list_HIFulfillmentEventToUpdate.isEmpty()) {
                update list_HIFulfillmentEventToUpdate;
            }
            HIFulfillmentEventTriggerHelper.skipTrigger = blnHIEventSkipTriggerFlag;
        }
        
    }
    
    public void finish(Database.BatchableContext BC) {
        // Creating a exception log record only if there are errors in processing a batch of records.
        AsyncApexJob objJob = [
            SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :BC.getJobId()
        ];
        String strSubject = 'HI_Fulfillment_Event__c ' + objJob.Status;
        strSubject += 
            ' Records processed ' +
            objJob.TotalJobItems +
            ' with ' +
            objJob.NumberOfErrors +
            ' failures.';
        
        if (objJob.NumberOfErrors > 0) {
            ExceptionLogUtil.logException('HIFulfillmentEventBatch', 'execute', strSubject, objJob.ExtendedStatus);
        }
    }
}