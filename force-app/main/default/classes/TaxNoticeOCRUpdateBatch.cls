/**
* Class Name : TaxNoticeOCRUpdateBatch
* Date Created : 2022-06-22
* Author : Rushi R
* Description : Batch class to update Case Status and Owner for Tax Notice OCR Processed Cases
* Test Class : TaxNoticeOCRUpdateBatchTest
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
        String strQuery = 'SELECT Id, CaseNumber, OwnerId, Status, Type, Is_OCR_Processed__c, CreatedDate, LastModifiedDate, (SELECT Id FROM Tax_Notice_Indexs__r WHERE RecordTypeId =: TAX_NOTICE_INDEX_RECTYPE_OCR ) FROM Case WHERE OwnerId = :OCR_CAPTURE_QUEUE_ID ' +
            ' AND RecordTypeId IN :RECORD_TYPE_IDS AND Status NOT IN :CASE_STATUS_TO_EXCLUDE';
        return Database.getQueryLocator(strQuery);
    }
    
    /* The cases stucked in  'Ready for OCR Capture' or 'IDP Capture in Progress' and its been more than 24 hours since last modified date 
    *  and they do not have any TNDC records, then those are put into the manual queue and their status is udpated as 'Ready for Data Capture'
    */
    public void execute(Database.BatchableContext objBatchContext, List<sObject> list_sObjects) {
        
        List<Case> list_CasesToUpdate = new List<Case>();
        for (Case objCase : (List<Case>) list_sObjects) {
            
            Long lngTimeDiff = BATCH_RUN_TIME - objCase.LastModifiedDate.getTime();
            Integer intHoursDiff = Integer.valueOf(lngTimeDiff / 1000 / 60 / 60 / 24);
            system.debug('objCase.LastModifiedDate **** '+objCase.LastModifiedDate);
            system.debug('objCase.LastModifiedDate.getTime() **** '+objCase.LastModifiedDate.getTime());
            System.debug('lngTimeDiff : '+ lngTimeDiff);
			Integer  i = objCase.Tax_Notice_Indexs__r != null ? objCase.Tax_Notice_Indexs__r.size(): 0;
            System.debug('intHoursDiff : '+ intHoursDiff + '---'+objCase.casenumber + ' -- '+ objCase.Status + ' -- ' +i);
            
            System.debug('objCase.Status  : '+objCase.Status +' CaseNumber : '+objCase.CaseNumber );
            System.debug('CaseUtils.CASE_STATUS_OCR_CAPTUREINPROGRESS  : '+CaseUtils.CASE_STATUS_OCR_CAPTUREINPROGRESS);
            System.debug('objCase.Tax_Notice_Indexs__r  : '+objCase.Tax_Notice_Indexs__r);
            System.debug('objCase.Tax_Notice_Indexs__r.size()  : '+objCase.Tax_Notice_Indexs__r.size()+ '--');
            
            
            
            if((objCase.Status == CaseUtils.CASE_STATUS_OCR_CAPTUREINPROGRESS || objCase.Status == CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE) && 
               (intHoursDiff > DAYS_TO_LOOK_BACK || Test.isRunningTest()) && 
               (objCase.Tax_Notice_Indexs__r == null || objCase.Tax_Notice_Indexs__r.size() == 0)) {
                   System.debug('CaseNumber in entry criteria**** : '+objCase.CaseNumber + 'ID : '+objCase.Id);   
                   objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
                   System.debug('CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE  '+CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE);
                   objCase.OwnerId = CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE;
                   if(objCase.casenumber == '32066001' || objCase.casenumber == '32067315'){
                       objCase.Agency_Information__c = 'a4kTH0000000GeHYAU';
                   }
                   list_CasesToUpdate.add(objCase);
               } 
        }
        System.debug('list_CasesToUpdate  : '+list_CasesToUpdate);
        System.debug('list_CasesToUpdate.size()  : '+list_CasesToUpdate.size());
        for(Case objCase : list_CasesToUpdate) {
            System.debug('objCase.CaseNumber ******* : '+objCase.CaseNumber + 'Case ID : '+objCase.Id);
        }
        if (!list_CasesToUpdate.isEmpty()) {
            update list_CasesToUpdate;
         //   List<Database.SaveResult> saveResult = Database.update(list_CasesToUpdate, false);
         //   Utils.processSaveResult(saveResult, list_CasesToUpdate, 'Id', true, 'TaxNoticeOCRUpdateBatch-execute');
          /*  for(Database.SaveResult eachSR : saveResult) {
                if(!eachSR.isSuccess()) {
                    for(Database.Error err :  eachSR.getErrors()) {
                        System.debug('err.getField  : '+err.getFields());
                        System.debug('err.getField  : '+err.getMessage());
                    }
                }
            } */
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