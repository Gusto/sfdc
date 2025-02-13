/**
 * @author Elavarasan N
 * @description helper class for TaxNoticeIndexTrigger
 * @see TaxNoticeIndexTriggerHelperTest
 */

public class TaxNoticeIndexTriggerHelper {
	public static boolean skipTrigger = false;

	/**
	 * @Author      : Elavarasan Nagarathinam
	 * @Description : Method executed on before insert of the TNDC record
	 * @Parm        : List<Tax_Notice_Index__c>
	 **/
	public void processBeforeInsert(List<Tax_Notice_Index__c> list_TaxResNotices) {
		Set<Id> set_CaseIds = new Set<Id>();
		Map<Id, Case> map_CaseRecords = new Map<Id, Case>();
		for (Tax_Notice_Index__c objTaxNotice : list_TaxResNotices) {
			// collect the case ids for the OCR TNDC records
			if (objTaxNotice.RecordTypeId == TaxNoticeIndexOCRUtil.TAX_NOTICE_INDEX_RECTYPE_OCR && String.isNotBlank(objTaxNotice.Case__c)) {
				set_CaseIds.add(objTaxNotice.Case__c);
			}
		}

		// get the case details
		if (!set_CaseIds.isEmpty()) {
			map_CaseRecords = prepareCaseDetails(set_CaseIds);
		}

		if (map_CaseRecords != null && !map_CaseRecords.isEmpty()) {
			// populate through TNDC records again to populate the client name text for FBED Cases
			for (Tax_Notice_Index__c objTaxNotice : list_TaxResNotices) {
				Case objCaseRecord = map_CaseRecords.containsKey(objTaxNotice.Case__c) ? map_CaseRecords.get(objTaxNotice.Case__c) : null;
				// collect the case ids for the OCR TNDC records
				if (objTaxNotice.RecordTypeId == TaxNoticeIndexOCRUtil.TAX_NOTICE_INDEX_RECTYPE_OCR && objCaseRecord != null && objCaseRecord.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE) {
					objTaxNotice.Client_Name_Text__c = objCaseRecord.Account.Name;
					objTaxNotice.Client_Name_Match__c = objCaseRecord.Account.Name;
					objTaxNotice.Client_Name__c = objCaseRecord.AccountId;
				}
			}
		}
	}

	/**
	 * @Author      : Elavarasan Nagarathinam
	 * @Description : Method executed on after insert of the TNDC record
	 * @Parm        : Map<Id, Tax_Notice_Index__c>
	 **/
	public void processAfterInsert(Map<ID, Tax_Notice_Index__c> map_TaxResNotices) {
		List<Tax_Notice_Index__c> list_TaxNoticeWithTaxRate = new List<Tax_Notice_Index__c>();

		for (Tax_Notice_Index__c objTaxNotice : map_TaxResNotices.values()) {
			if (String.isNotBlank(objTaxNotice.Tax_Rate_Json__c) && objTaxNotice.Tax_Notice_Type__c == CaseUtils.STR_SUI_FORM_TYPE) {
				list_TaxNoticeWithTaxRate.add(objTaxNotice);
			}
		}

		if (!list_TaxNoticeWithTaxRate.isEmpty()) {
			populateSUITaxRates(list_TaxNoticeWithTaxRate);
		}
	}

	/**
	 * @Author      : Elavarasan Nagarathinam
	 * @Description : Get the case record details based on the ids provided
	 * @Parm        : Set<Id>
	 **/
	public static Map<Id, Case> prepareCaseDetails(Set<Id> set_CaseIds) {
		Map<Id, Case> map_CaseRecords = new Map<Id, Case>();
		if (set_CaseIds == null || set_CaseIds.isEmpty()){
			return null;
		} 

		map_CaseRecords = new Map<Id, Case>([SELECT Id, Origin, AccountId, Account.Name FROM Case WHERE Id IN :set_CaseIds]);
		return map_CaseRecords;

	}

	/**
	 * @Author      : Elavarasan Nagarathinam
	 * @Description : Insert Tax Rate Type records based on the Tax Rate JSON from OCR.
	 * @Parm        : List<Tax_Notice_Index__c>
	 **/
	public static void populateSUITaxRates(List<Tax_Notice_Index__c> list_TaxNotices) {
		List<Tax_Rate_Values__c> list_NewTaxRateType = new List<Tax_Rate_Values__c>();
		Map<String, Tax_Rate__c> map_TaxRateMap = new Map<String, Tax_Rate__c>();
		Map<Id, Agency_Information__c> map_AgencyMap = new Map<Id, Agency_Information__c>();
		Map<Id, Case> map_CasesFailed = new Map<Id, Case>();
		Set<String> set_CaseIds = new Set<String>();

		//query all the tax rate records in salesforce and create a map
		for (Tax_Rate__c objTaxRate : GlobalQueryHelper.getAllTaxRates()) {
			map_TaxRateMap.put(objTaxRate.ZP_Tax_Rate_Name__c, objTaxRate);
		}

		//get all the agency details in a map with agency id as a key and record as a value
		map_AgencyMap = GlobalQueryHelper.getAllAgencyInformation();

		for (Tax_Notice_Index__c objTaxNotice : list_TaxNotices) {
			// check if TNDC form number is listed as SUI form number in the related agency record
			String strTNDCAgencySUIForm = map_AgencyMap?.get(objTaxNotice.Agency_Information__c)?.SUI_Rate_Form_Numbers__c;
			List<String> list_SUIFormNumbers = new List<String>();
			if (String.isNotBlank(strTNDCAgencySUIForm)) {
				list_SUIFormNumbers = strTNDCAgencySUIForm.split(';');
			}

			if (list_SUIFormNumbers != null && list_SUIFormNumbers.contains(objTaxNotice.Tax_Notice_Form_Number__c)) {
				for (TaxResSUIWrapper objSUIRateWrapper : TaxResSUIWrapper.parse(objTaxNotice.Tax_Rate_Json__c)) {
					if (
						objTaxNotice.Agency_Information__c != null &&
						map_TaxRateMap != null &&
						map_TaxRateMap.containsKey(objSUIRateWrapper.TaxRateKey) &&
						objTaxNotice.Agency_Information__c == map_TaxRateMap.get(objSUIRateWrapper.TaxRateKey).Agency_Information__c
					) {
						if (String.isNotBlank(objSUIRateWrapper.TaxRate)) {
							Tax_Rate_Values__c objTaxResValue = new Tax_Rate_Values__c();
							objTaxResValue.Tax_Notice_Index__c = objTaxNotice.Id;
							objTaxResValue.Rate_Decimal__c = Double.valueOf(objSUIRateWrapper.TaxRate);
							objTaxResValue.Tax_Rate_Type__c = map_TaxRateMap.get(objSUIRateWrapper.TaxRateKey).Id;
							list_NewTaxRateType.add(objTaxResValue);
						}
					} else {
						if (objTaxNotice.RecordTypeID == CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL) {
							set_CaseIds.add(objTaxNotice.Case__c + '-' + CaseUtils.STR_TAX_FORM_TYPE);
						}
					}
				}
			} else {
				// SUI Form number mismatch
				if (objTaxNotice.RecordTypeID == CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL) {
					set_CaseIds.add(objTaxNotice.Case__c + '-' + CaseUtils.STR_SUI_FORM_TYPE);
				}
			}
		}

		try {
			if (!System.isFuture() && !System.isBatch() && !System.isQueueable()) {
				updateFailedCases(set_CaseIds);
			} else {
				ExceptionLogUtil.logException('TaxNoticeIndexTriggerHelper', 'populateSUITaxRates', 'Case trying to update from future/batch/queable methods', String.Join(set_CaseIds, ','));
			}

			if (!list_NewTaxRateType.isEmpty()) {
				insert list_NewTaxRateType;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('TaxNoticeIndexTriggerHelper', 'populateSUITaxRates', objException.getMessage(), objException.getStackTraceString());
		}
	}

	/**
	 * @Author      : Elavarasan Nagarathinam
	 * @Description : Update OCR Status, OCR Message of the case and assign it to manual indexing team
	 * @Parm        : Set<String>
	 **/
	@future
	public static void updateFailedCases(Set<String> strCaseWithError) {
		List<Case> list_Cases = new List<Case>();
		Map<String, String> map_CaseIdWithError = new Map<String, String>();

		for (String strParam : strCaseWithError) {
			List<String> strList = strParam.split('-');
			map_CaseIdWithError.put(strList[0], strList[1]);
		}

		for (Case objCase : [SELECT Id, Status, OCR_Status__c, OCR_Message__c, OwnerId FROM Case WHERE ID IN :map_CaseIdWithError.keySet()]) {
			objCase.OCR_Status__c = CaseUtils.STR_IB_FAILED_STATUS;
			objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
			objCase.OwnerId = CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE;
			if (map_CaseIdWithError.get(objCase.Id) == CaseUtils.STR_SUI_FORM_TYPE) {
				objCase.OCR_Message__c = System.Label.Tax_Res_SUI_Form_Mismatch;
			} else {
				objCase.OCR_Message__c = System.Label.Tax_Res_Missing_Invalid_Tax_Rate;
			}
			list_Cases.add(objCase);
		}
        
		try {
			if (!list_Cases.isEmpty()) {
				CaseTriggerHandler.blnSkipBeforeUpdate = true;
				CaseTriggerHandler.blnSkipAfterUpdate = true;
				update list_Cases;
				CaseTriggerHandler.blnSkipBeforeUpdate = false;
				CaseTriggerHandler.blnSkipAfterUpdate = false;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('TaxNoticeIndexTriggerHelper', 'updateFailedCases', objException.getMessage(), objException.getStackTraceString());
		}
	}
}