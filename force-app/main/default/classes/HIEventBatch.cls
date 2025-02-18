/**
* @name         : HiEventBatch
* @author       : Udit Jain
* @date         : 04/18/2024
* @description  : Batch class which will pick any dead, queued or errorred HI Events and reprocess them
* @test classes : HiEventBatchTest
**/
public with sharing class HIEventBatch implements Schedulable, Database.Batchable<SObject> {
    public static Integer intMarkDeadAfterDays;
    public static Integer intErrorReprocessHrs;
    public static Integer intDeleteAfterDays;
    public static String strMarkDeadAfterDays;
    public static String strErrorReprocessHrs;
    public static String strDeleteAfterDays;
    public static String BATCH_CLASS_NAME = '';
    public static final String FILTER_TYPE_BASE_QUERY = 'Base Query';
    public static final String FILTER_TYPE_WHERE_CLAUSE = 'Where Clause';
    public static final String FILTER_TYPE_ORDER_BY = 'Order By';
    public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
    
    public HIEventBatch(String deadAfterDays,String reprocessAfterDays,String deleteAfterDays,String batchName){
        strMarkDeadAfterDays = deadAfterDays;
        strErrorReprocessHrs = reprocessAfterDays;
        strDeleteAfterDays = deleteAfterDays;
        intMarkDeadAfterDays=Integer.valueof(HI_Configuration__mdt.getInstance(deadAfterDays).Value__c);
        
        intErrorReprocessHrs = Integer.valueof(HI_Configuration__mdt.getInstance(reprocessAfterDays).Value__c);
        
        intDeleteAfterDays = Integer.valueof(HI_Configuration__mdt.getInstance(deleteAfterDays).Value__c);
        
        BATCH_CLASS_NAME = batchName;
    }
    
    
    
    public Map<String, HI_Configuration__mdt> map_HIConfigurations;
    
    /**ewq	t
* @Author      : Udit Jain
* @Description : Get HI Configurations
**/
    private void fetchHIConfigurations(String strClassName) {
        map_HIConfigurations = new Map<String, HI_Configuration__mdt>();
        
        for (HI_Configuration__mdt objConfig : [
            SELECT MasterLabel, DeveloperName, Filter_Type__c, Value__c
            FROM HI_Configuration__mdt
            WHERE Active__c = TRUE AND MasterLabel = :strClassName
        ]) {
            if (!map_HIConfigurations.containsKey(objConfig.Filter_Type__c)) {
                map_HIConfigurations.put(objConfig.Filter_Type__c, objConfig);
            }
        }
    }
    
    public void execute(SchedulableContext objSC) {
        if(String.isNotBlank(BATCH_CLASS_NAME)){
            Integer intBatchSize = 10;
            HIEventBatch batchInstance = new HIEventBatch(strMarkDeadAfterDays, strErrorReprocessHrs, strDeleteAfterDays,BATCH_CLASS_NAME);
            if (
                map_HIConfigurations != null &&
                map_HIConfigurations.containsKey(FILTER_TYPE_BATCH_SIZE) &&
                map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c != null
            ) {
                intBatchSize = Integer.valueOf( map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c );
            }
            Database.executeBatch(batchInstance, intBatchSize);
        }
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        fetchHIConfigurations(BATCH_CLASS_NAME);
        String strQuery = '';
        String strDefaultQuery =
		'SELECT Id,Processing_State__c,Processed_At__c,CreatedDate' +
		' FROM HIGroupEvent__c WHERE Processing_State__c IN (\'Error\', \'Dead\',\'Queued\') ORDER BY CreatedDate DESC';
        
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
                String str_whereClause = map_HIConfigurations.get(FILTER_TYPE_WHERE_CLAUSE).Value__c;
                DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
                DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
                str_whereClause = str_whereClause.replace('dateForError', 'dtDeadCheck');
                str_whereClause = str_whereClause.replace('dateForDead', 'dtDeleteCheck');
                strQuery += ' ' + str_whereClause;
            }
            
            if (
                map_HIConfigurations.containsKey(FILTER_TYPE_ORDER_BY) &&
                String.isNotBlank(
                    map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c
                )
            ) {
                strQuery +=
                    ' ' + map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c;
            }else{
                strQuery = strDefaultQuery;
            }
        }
        
        if (String.isBlank(strQuery)) {
            strQuery = strDefaultQuery;
        }
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        Boolean blnHasEventsToSkipTrigger = false;
        String strProcessedFieldName = '';
        if(BATCH_CLASS_NAME=='HIAasmEventsBatch'){
            strProcessedFieldName = 'Last_Processed__c';
            blnHasEventsToSkipTrigger = true;
            HIAasmEventTriggerHelper.skipTrigger = true;
        }else if(BATCH_CLASS_NAME=='HIBenefitApplicationUserBatch'){
            strProcessedFieldName = 'Last_Processed__c';
            blnHasEventsToSkipTrigger = true;
            HIBenefitApplicationUserTriggerHelper.queue = true;
        }else if(BATCH_CLASS_NAME=='HICarrierVersionDetailBatch'){
            strProcessedFieldName = 'Processed_At__c';
            blnHasEventsToSkipTrigger = true;
            HICarrierVersionDetailTriggerHandler.blnSkipTrigger = true;
        }else if(BATCH_CLASS_NAME=='HIGroupEventBatch'){
            strProcessedFieldName = 'Processed_At__c';
            blnHasEventsToSkipTrigger = true;
            HIGroupEventTriggerHelper.queue = true;
        }
        
        DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
        DateTime dtReprocessCheck = System.now().addHours(-intErrorReprocessHrs);
        DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
        
        List<sObject> list_HIEventToUpdate = new List<sObject>();
        List<sObject> list_HIEventToProcess = new List<sObject>();
        List<sObject> list_HIEventToDelete = new List<sObject>();
        
        List<sObject> list_HIEvents =  scope;
        for (sObject objHIEvent : list_HIEvents) {
            if ((String) objHIEvent.get('Processing_State__c') == IntegrationUtils.DEAD_STATE) {
                if (
                    ((DateTime) objHIEvent.get(strProcessedFieldName) == null &&
                     (DateTime) objHIEvent.get('CreatedDate') < dtDeleteCheck) ||
                    ((DateTime) objHIEvent.get(strProcessedFieldName) != null &&
                     (DateTime) objHIEvent.get(strProcessedFieldName) < dtDeleteCheck)
                ) {
                    list_HIEventToDelete.add(objHIEvent);
                    blnHasEventsToSkipTrigger = true;
                }
            } else if (
                (String) objHIEvent.get('Processing_State__c') == IntegrationUtils.ERROR_STATE
            ) {
                if ((DateTime) objHIEvent.get('CreatedDate') < dtDeadCheck) {
                    objHIEvent.put('Processing_State__c',IntegrationUtils.DEAD_STATE);
                    objHIEvent.put(strProcessedFieldName,System.now());
                    list_HIEventToUpdate.add(objHIEvent);
                    blnHasEventsToSkipTrigger = true;
                } else if (
                    (DateTime) objHIEvent.get(strProcessedFieldName) < dtReprocessCheck
                ) {
                    list_HIEventToProcess.add(objHIEvent);
                }
            } else {
                list_HIEventToProcess.add(objHIEvent);
            }
        }
        
        if (!list_HIEventToProcess.isEmpty()) {
            update list_HIEventToProcess;
        }
        
        if (blnHasEventsToSkipTrigger) {
            Boolean blnHIEventSkipTriggerFlag;
            if(BATCH_CLASS_NAME=='HIAasmEventsBatch'){
                blnHIEventSkipTriggerFlag = HIAasmEventTriggerHelper.skipTrigger;
                HIAasmEventTriggerHelper.skipTrigger = true;
            }else if(BATCH_CLASS_NAME=='HIBenefitApplicationUserBatch'){
                blnHIEventSkipTriggerFlag = HIBenefitApplicationUserTriggerHelper.skipTrigger;
                HIBenefitApplicationUserTriggerHelper.queue = true;
            }else if(BATCH_CLASS_NAME=='HICarrierVersionDetailBatch'){
                blnHIEventSkipTriggerFlag = HICarrierVersionDetailTriggerHandler.blnSkipTrigger;
                HICarrierVersionDetailTriggerHandler.blnSkipTrigger = true;
            }else if(BATCH_CLASS_NAME=='HIGroupEventBatch'){
                blnHIEventSkipTriggerFlag = HIGroupEventTriggerHelper.queue;
                HIGroupEventTriggerHelper.queue = true;
            }
            
            if (!list_HIEventToDelete.isEmpty()) {
                delete list_HIEventToDelete;
            }
            
            if (!list_HIEventToUpdate.isEmpty()) {
                update list_HIEventToUpdate;
            }
            
            if(BATCH_CLASS_NAME=='HIAasmEventsBatch'){
                HIAasmEventTriggerHelper.skipTrigger = blnHIEventSkipTriggerFlag;
            }else if(BATCH_CLASS_NAME=='HIBenefitApplicationUserBatch'){
                HIAasmEventTriggerHelper.skipTrigger = blnHIEventSkipTriggerFlag;
            }else if(BATCH_CLASS_NAME=='HICarrierVersionDetailBatch'){
                HIAasmEventTriggerHelper.skipTrigger = blnHIEventSkipTriggerFlag;
            }else if(BATCH_CLASS_NAME=='HIGroupEventBatch'){
                HIAasmEventTriggerHelper.skipTrigger = blnHIEventSkipTriggerFlag;
            }
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
        String strSubject = 'HIEvent__c ' + objJob.Status;
        String strBody =
            'Records processed ' +
            objJob.TotalJobItems +
            ' with ' +
            objJob.NumberOfErrors +
            ' failures.';  
      
    }
}