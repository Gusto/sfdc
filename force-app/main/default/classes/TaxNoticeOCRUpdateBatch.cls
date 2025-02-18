/**
 * Class Name : TaxNoticeOCRUpdateBatch
 * Date Created : 2022-06-22
 * Author : Rushi R
 * Description : Batch class to update Case Status and Owner for Tax Notice OCR Processed Cases
 * Test Class : TaxNoticeIndexOCRUtilTest
 */
public with sharing class TaxNoticeOCRUpdateBatch implements Database.Batchable<SObject>, Schedulable {
    public static Id OCR_CAPTURE_QUEUE_ID = CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
    public static List<Id> RECORD_TYPE_IDS = new List<Id> { CaseUtils.RECTYPE_TAXRES };
    public static Set<String> CASE_STATUS_TO_EXCLUDE = new Set<String>{ CaseUtils.STATUS_CLOSED, CaseUtils.STATUS_SOLVED };
    public static LONG BATCH_RUN_TIME = DateTime.now().getTime();
    public static Integer DAYS_TO_LOOK_BACK = 1;
    public static final Id TAX_NOTICE_INDEX_RECTYPE_OCR = Cache.getRecordTypeId('Tax_Notice_Index__c', 'IDP Indexing');

    /* Query all the Cases that are,
     *  Record Type = 'Tax Res'
     *  OwnerId = 'OCR Capture Queue'
     *  Status != 'Closed' or 'Solved'
     * and process them in batches
     */
    public Database.QueryLocator start(Database.BatchableContext objBatchContext) {
        
        String strQuery = 'SELECT Id, OwnerId, Status, Type, Is_OCR_Processed__c, CreatedDate, (SELECT Id FROM Tax_Notice_Indexs__r WHERE RecordTypeId =: TAX_NOTICE_INDEX_RECTYPE_OCR ) FROM Case WHERE OwnerId = :OCR_CAPTURE_QUEUE_ID ' +
            ' AND RecordTypeId IN :RECORD_TYPE_IDS AND Status NOT IN :CASE_STATUS_TO_EXCLUDE';
        return Database.getQueryLocator(strQuery);
    }

    /* For all the cases that has Status assigned to 'Data Capture Complete' more than 1 day ago,
     * If Case was ever in 'Data Capture Compete' status, consider OCR Processed.
     *
     * For all Cases that were not OCR Processed,
     *  - Update Status to 'Ready for Data Capture'
     *  - Update Case Owner to 'TaxRes Data Capture Queue'
     *
     * For all Cases that were OCR Processed, call CaseUtils.taxResCaseOwnerUpdate
     */
    public void execute(Database.BatchableContext objBatchContext, List<sObject> list_sObjects) {
 
        Set<Id> set_CaseIds = new Set<Id>();
        List<Case> list_CasesToUpdate = new List<Case>();
        for (Case objCase : (List<Case>) list_sObjects) {
            
            Long lngTimeDiff = BATCH_RUN_TIME - objCase.CreatedDate.getTime();
            Integer intHoursDiff = Integer.valueOf(lngTimeDiff / 1000 / 60 / 60 / 24);

            System.debug('objCase.Tax_Notice_Indexs__r  : '+objCase.Tax_Notice_Indexs__r);
            System.debug('objCase.Tax_Notice_Indexs__r.size()  : '+objCase.Tax_Notice_Indexs__r.size());
            if(objCase.Status == CaseUtils.CASE_STATUS_OCR_CAPTUREINPROGRESS  && (objCase.Tax_Notice_Indexs__r == null || objCase.Tax_Notice_Indexs__r.size() == 0)) {
                System.debug('Inside the loop if objCase  : '+objCase.ID);
                objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
                objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
                list_CasesToUpdate.add(objCase);
            } else {
                set_CaseIds.add(objCase.Id);
            } 
        }

        // Get Case History for all the Cases
        List<CaseHistory> list_CaseHistory = new List<CaseHistory>();
        Set<Id> set_CaseIdToProcess = new Set<Id>();
        if(!set_CaseIds.isEmpty()) {
            list_CaseHistory = GlobalQueryHelper.getCaseHistoryByUpdatedField(set_CaseIds, null);

            // Identify all the Cases that were in 'Data Capture Complete' status more than 1 day ago
            for (CaseHistory objCaseHistory : list_CaseHistory) {
                if (objCaseHistory.NewValue != '' && objCaseHistory.NewValue == OCR_CAPTURE_QUEUE_ID) {
                    Long lngTimeDiff = BATCH_RUN_TIME - objCaseHistory.CreatedDate.getTime();
                    Integer intHoursDiff = Integer.valueOf(lngTimeDiff / 1000 / 60 / 60 / 24);

                    if (intHoursDiff > DAYS_TO_LOOK_BACK) {
                        set_CaseIdToProcess.add(objCaseHistory.CaseId);
                    }
                }
            }
        }

        // Case History is not available in Test context, so add all the Cases to be processed
        if(Test.isRunningTest()) {
            set_CaseIdToProcess.addAll(set_CaseIds);
        }

        // If case were OCR Processed, call CaseUtils.taxResCaseOwnerUpdate
        // else update Case Status to 'Ready for Data Capture' and Case Owner to 'TaxRes Data Capture Queue'
        Map<Id, Case> map_CasesToEvaluate = new Map<Id, Case>();
        for (Case objCase : (List<Case>) list_sObjects) {
            if (!set_CaseIdToProcess.contains(objCase.Id)) {
                continue;
            }

            if(!objCase.Is_OCR_Processed__c && set_CaseIds.contains(objCase.Id)) {
                System.debug('objCase.Is_OCR_Processed__c false objCase.ID  : '+objCase.ID);
                
                if( !(objCase.Tax_Notice_Indexs__r != null || objCase.Tax_Notice_Indexs__r.size() > 0) ) {
                    objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
                    objCase.OwnerId = CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE;
                    list_CasesToUpdate.add(objCase);                    
                }
            } else {
                map_CasesToEvaluate.put(objCase.Id, objCase);
            }
        }

        if (!map_CasesToEvaluate.isEmpty()) {
            CaseUtils.taxResCaseOwnerUpdate(map_CasesToEvaluate, list_CaseHistory);
            list_CasesToUpdate.addAll(map_CasesToEvaluate.values());
        }

        if (!list_CasesToUpdate.isEmpty()) {
            List<Database.SaveResult> saveResult = Database.update(list_CasesToUpdate, false);
            Utils.processSaveResult(saveResult, list_CasesToUpdate, 'Id', true, 'TaxNoticeOCRUpdateBatch-execute');
        }
    }

    // Batchable - Finish method
    public void finish(Database.BatchableContext objBatchContext) {
        AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :objBatchContext.getJobId()];
        Utils.processBatchFinish(objAsyncJob, 'TaxNoticeOCRUpdateBatch', false);
    }

    // Scheduleable - Execute method
    public void execute(SchedulableContext objSC) {
        Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
        Integer intBatch = objConfigSettings?.AutoUpdateCaseStatusBatchSize__c != null ? (Integer) objConfigSettings.AutoUpdateCaseStatusBatchSize__c : 20;

        Database.executeBatch(new TaxNoticeOCRUpdateBatch(), intBatch);
    }
}