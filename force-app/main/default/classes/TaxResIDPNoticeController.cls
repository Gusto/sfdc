/**
 * @name         TaxResIDPNoticeController
 * @author       Shyam Nasare
 * @date         10/09/2024
 * @description  Used by LWC component "TaxResNoticeIndexDetailsNew"
 * @see          TaxResIDPNoticeControllerTest
 **/
public with sharing class TaxResIDPNoticeController {
    public static final String AUTO_INDEX_STATUS_PARTIALLY_INDEXED = 'Partially Indexed';
	public static final String AUTO_INDEX_STATUS_FULLY_INDEXED = 'Fully Indexed';
	public static final String AUTO_INDEX_STATUS_FAILED = 'Failed';
	public static final String AUTO_INDEX_UNTRAINED_DOCUMENT = 'Failed: Untrained Document';
	public static final String AUTO_INDEX_NO_VALID_DOCUMENT = 'Failed: No Valid Document';
	public static final String AUTO_INDEX_SYSTEM_ISSUE = 'Failed: System Issue';
	public static final String MRR_REASON_SYSTEM_EXCEPTION = System.label.TaxRes_MRR_Reason_Exception_Check;
    public static final String CASE_STATUS_READY_FOR_DATA_CAPTURE = CaseTriggerHelper.CASE_STATUS_READY_FOR_DATA_CAPTURE;
    public static final String TAXRESDATACAPTURE_QUEUE_ID = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
    public static final String TNDC_RECORD_TYPE_ID_IDP_INDEXING = Cache.getRecordTypeId('Tax_Notice_Index__c', 'IDP Indexing');

    /**
	 * @Author      : Shyam Nasare
	 * @Description : to get the Custom Metadata type Tax_Res_TNDC_Confidence_Score_Setting__mdt
	 * @Parm        : Case Id
	 * @Return      : List<Tax_Res_TNDC_Confidence_Score_Setting__mdt>
	 **/
    @AuraEnabled(cacheable=true)
    public static List<Tax_Res_TNDC_Confidence_Score_Setting__mdt> getTNDCConfidenceScoreSetting(Id objCaseId){
        List<Tax_Res_TNDC_Confidence_Score_Setting__mdt> list_ConfidenceScores = Tax_Res_TNDC_Confidence_Score_Setting__mdt.getAll().values();

        return list_ConfidenceScores;
    }

     /**
	 * @Author      : Shyam Nasare
	 * @Description : to update the Case after OCR Capture is Complete
	 * @Parm        : Case record, TNDC record, isupdate
	 * @Return      : void
	 **/
    public void caseUpdatesAfterOCRComplete(Case objCase, Tax_Notice_Index__c objNotice, Boolean isUpdate) {
       
		Map<String, String> map_MRRReasonIndexingStatus = GlobalQueryHelper.getMRRReasonIndexingStatusMap();

		if (objNotice.RecordTypeId == TaxNoticeIndexOCRUtil.TAX_NOTICE_INDEX_RECTYPE_OCR) {
			objCase.Is_OCR_Processed__c = true;
			
			if (objNotice.Manual_Review_Required__c && String.isNotBlank(objNotice.MRR_Reason__c)) {
				for (String strMRRReason : objNotice.MRR_Reason__c.split(';')) {
					if (map_MRRReasonIndexingStatus != null && map_MRRReasonIndexingStatus.containsKey(strMRRReason)) {
						objCase.Auto_Indexing_Status__c = map_MRRReasonIndexingStatus.get(strMRRReason);
						break;
					}
				}

				if (String.isBlank(objCase.Auto_Indexing_Status__c)) {
					objCase.Auto_Indexing_Status__c = AUTO_INDEX_STATUS_PARTIALLY_INDEXED;
				}
			} else {
				objCase.Auto_Indexing_Status__c = AUTO_INDEX_STATUS_FULLY_INDEXED;
			}
		}
	}
}