/**
 * @name         TaxResCaseHelper
 * @author       Ela N
 * @description  This contains the logic for IDP indexing
 **/
public class TaxResCaseHelper {
	Map<Id, Case> map_TriggeredCaseRecords = new Map<Id, Case>();
    public static Tax_Res_Play_Mode_Configuration__mdt paperMailExclusionsSettings = Tax_Res_Play_Mode_Configuration__mdt.getInstance('Paper_Mail_Exclusions');
    public Set<String> set_OCRClientNameTextsQuery = new Set<String>();
    public Set<String> set_ZPCompanyIds = new Set<String>();
    public static final String CFG_ACCT_STR_END_TO_IGNORE = 'Strings_to_Ignore';
	public static final String CFG_ACCT_STR_FRONT_TO_IGNORE = 'Strings_to_Ignore_at_Front';
    public static final Set<String> set_stringsOnAcctsEndToIgnore = getStringsToIgnore(CFG_ACCT_STR_END_TO_IGNORE);
	public static final Set<String> set_stringsOnAcctsFrontToIgnore = getStringsToIgnore(CFG_ACCT_STR_FRONT_TO_IGNORE);
	Map<String, Account> map_AccountNames = new Map<String, Account>();
	Map<Id, Account> map_AccountIds = new Map<Id, Account>();
	Map<Id, Id> map_TNDCRecCaseId = new Map<Id, Id>();
    TaxNoticeIndexOCRUtil objOCRUtilController = new TaxNoticeIndexOCRUtil();
    Map<Id, Set<Id>> map_CaseWithNATNDCS = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> map_CaseWithTNDCS = new Map<Id, Set<Id>>();
    Map<Id, List<Tax_Notice_Index__c>> map_CaseWithOCRTNDC = new Map<Id, List<Tax_Notice_Index__c>>();
    Map<Id, Tax_Notice_Index__c> map_TNDC = new Map<Id, Tax_Notice_Index__c>();
    
    /*
    public void initiateIndexing(Map<Id, Case> oldMap, Map<Id, Case> newMap) {
        CaseTriggerHelper helper = new CaseTriggerHelper();
        Map<String, String> map_MRRReasonIndexingStatus = GlobalQueryHelper.getMRRReasonIndexingStatusMap();
		Map<Id, Case> map_OCRProcessedCases = new Map<Id, Case>();
        Map<Id, String> map_OCRTriggerdCaseIdWithRelevantCases = new Map<Id, String>();
        
        if(newMap == null || newMap.isEmpty()) {
            return;
        }
        
        for(Case objCase : newMap.values()) {
            Case objOldCase = oldMap.get(objCase.Id);
            
            // 1. If the case is mrr checked, then assign it to manual queue
            if(objCase.Electronic_Notice_MRR__c) {
                objCase.Status = CaseTriggerHelper.CASE_STATUS_READY_FOR_DATA_CAPTURE;
                objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
                objCase.Is_OCR_Processed__c = true;
                objCase.OCR_Message__c = objCase.Automation_Message_Details__c;
                objCase.OCR_Status__c = CaseUtils.STR_IB_FAILED_STATUS;
                
                //Populate auto indexing status based on the metadata between mrr reason and status
                if(String.isNotBlank(objCase.Automation_Message_Details__c) && map_MRRReasonIndexingStatus != null && map_MRRReasonIndexingStatus.containsKey(objCase.Automation_Message_Details__c)) {
                    objCase.Auto_Indexing_Status__c = map_MRRReasonIndexingStatus.get(objCase.Automation_Message_Details__c);
                } else {
                    objCase.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_FAILED;
                }
            } else {
                map_OCRProcessedCases.put(objCase.Id, objCase);
            }
        }
        
        // Calling processOCRTNDCRecords for successfully OCR'd Tax Res cases
        if (map_OCRProcessedCases?.size() > 0) {
            map_OCRTriggerdCaseIdWithRelevantCases = getAllTNDCGrouping(map_OCRProcessedCases);
        }
    }*/
    
    /**
    * @name         TaxResCaseHelper
    * @author       Ela N
    * @description  This method is used for grouping all actionable and nonactionable TNDC records
    **/
    public Map<Id, String> getAllTNDCGrouping(Map<Id, Case> map_IdCaseReccords) {
        System.debug('******************* getAllTNDCGrouping');
        
        map_CaseWithNATNDCS = new Map<Id, Set<Id>>();
    	map_CaseWithTNDCS = new Map<Id, Set<Id>>();
        map_TNDC = new Map<Id, Tax_Notice_Index__c>();
        map_CaseWithOCRTNDC = new Map<Id, List<Tax_Notice_Index__c>>();
		set_OCRClientNameTextsQuery = new Set<String>();
        set_ZPCompanyIds = new Set<String>();
        
        Map<Id, String> map_OCRTriggerdCaseIdWithRelevantCases = new Map<Id, String>();
        
		if (map_IdCaseReccords?.size() > 0) {
            Map<String , List<Tax_Notice_Index__c>> map_KeyWithTNDCRecords = new Map<String , List<Tax_Notice_Index__c>>();
            
			List<Tax_Notice_Index__c> list_OCRTNDC = new List<Tax_Notice_Index__c>();
            
			for (Tax_Notice_Index__c objTNDC : [
				SELECT
					Id,
					Case__c,
                    Case__r.Physical_Mail__c,
					Multi_YR_QTR_Indicator__c,
					Client_Name__c,
					Client_Name__r.RecordTypeId,
					Client_Name__r.RecordType.Name,
					Client_Name__r.Tier__c,
					Client_Name__r.AM_Tier__c,
					Client_Name_Match__c,
					Agency_Information__c,
					Agency_Information__r.Name,
					Attachment_Name__c,
					Attachment_Names__c,
					No_Notice_Attached__c,
					Notes_Field__c,
					Partner_Tier__c,
					RecordTypeId,
					Yr_Qtr__c,
					Tier__c,
					Tax_Notice_Numeration__c,
					Tax_Notice_Form_Number__c,
					Tax_Notice_Due_Date__c,
					Tax_Notice_Date__c,
					Tax_Notice_Amount_Total__c,
					Tax_Notice_Amount_Aggregate__c,
					Tax_Notice_Tax_Amount__c,
					Tax_Notice_Type__c,
					SUI_Rate_Effective_Date__c,
					SUI_ER_Rate__c,
					Segment__c,
					Client_Name_Text__c,
					Assigned_Client_Tax_ID_Agency_Assigned__c,
					Processing_State__c,
					Tax_Rate_Json__c,
					Client_Tax_ID_Conf_Score__c,
					Client_Tax_ID_Conf_Score_Reason__c,
					Interest_Amount_Due_Conf_Score__c,
					Interest_Amount_Due_Conf_Score_Reason__c,
					Multi_Yr_Qtr_Indicator_Conf_Score__c,
					Multi_Yr_Qtr_Indicator_Conf_Score_Reason__c,
					Notice_Form_Number_Conf_Score__c,
					Notice_Form_Number_Conf_Score_Reason__c,
					Penalty_Amount_Due_Conf_Score__c,
					Penalty_Amount_Due_Conf_Score_Reason__c,
					Tax_Amount_Due_Conf_Score__c,
					Tax_Amount_Due_Conf_Score_Reason__c,
					Tax_Notice_Date_Conf_Score__c,
					Tax_Notice_Date_Conf_Score_Reason__c,
					Tax_Notice_Numeration_Conf_Score__c,
					Tax_Notice_Numeration_Conf_Score_Reason__c,
					Tax_Notice_Type_Conf_Score__c,
					Tax_Notice_Type_Conf_Score_Reason__c,
					Total_Amount_Due_Conf_Score__c,
					Total_Amount_Due_Conf_Score_Reason__c,
					Year_Quarter_Conf_Score__c,
					Year_Quarter_Conf_Score_Reason__c,
					Tax_Notice_Due_Date_Conf_Score__c,
					Tax_Notice_Due_Date_Conf_Score_Reason__c,
					Manual_Review_Required__c,
					MRR_Reason__c,
					Interest_Amount_Due__c,
					Penalty_Amount_Due__c,
					ZP_Company_Id__c,
                	Automation_Message__c,
                	Bypass_Manual_Validation__c,
                	(SELECT Id,
                    Field__c,
                    Reason__c
                    FROM TNDC_MRR_Reasons__r WHERE Field__c <> NULL)
				FROM Tax_Notice_Index__c
				WHERE Case__c != NULL AND Case__c IN :map_IdCaseReccords.keyset() AND RecordType.DeveloperName = 'OCR'
				ORDER BY Name ASC
			]) {
				list_OCRTNDC.add(objTNDC);
                map_TNDC.put(objTNDC.Id, objTNDC);
                map_TNDCRecCaseId.put(objTNDC.Id, objTNDC.Case__c);
                
                if (String.isNotBlank(objTNDC.ZP_Company_Id__c)) {
					set_ZPCompanyIds.add((objTNDC.ZP_Company_Id__c).trim());
				}
				Set<String> set_ClientNameText = getAllAccountNameSearchString(objTNDC);
                if(set_ClientNameText != null && !set_ClientNameText.isEmpty()) {
                    set_OCRClientNameTextsQuery.addAll(set_ClientNameText);
                }
                System.debug('set_OCRClientNameTextsQuery ===> ' + set_OCRClientNameTextsQuery);
                
                
                // relevant case related settings
				String strKey;
                if(objTNDC.Agency_Information__c != null && objTNDC.ZP_Company_Id__c != null && objTNDC.ZP_Company_Id__c != '' 
				&& objTNDC.Yr_Qtr__c != null && objTNDC.Yr_Qtr__c != '') {
					strKey = objTNDC.Agency_Information__c + ''+ objTNDC.ZP_Company_Id__c + ''+objTNDC.Yr_Qtr__c;
				}
				else if(objTNDC.Agency_Information__c != null && objTNDC.Client_Name_Text__c != null && objTNDC.Client_Name_Text__c != '' 
				 && objTNDC.Yr_Qtr__c != null && objTNDC.Yr_Qtr__c != '') {
					strKey = objTNDC.Agency_Information__c + ''+ objTNDC.Client_Name_Text__c + ''+objTNDC.Yr_Qtr__c;
				}
                if(!map_KeyWithTNDCRecords.containsKey(strKey)) {
                    map_KeyWithTNDCRecords.put(strKey, new List<Tax_Notice_Index__c> {objTNDC});
                }
                else {
                    map_KeyWithTNDCRecords.get(strKey).add(objTNDC);
                }
                
                // grouping the TNDCs as actionable and non actionable
                if(String.isBlank(objTNDC.Agency_Information__c) || (String.isBlank(objTNDC.Client_Name_Text__c) && String.isBlank(objTNDC.ZP_Company_Id__c))) {
                    if(map_CaseWithNATNDCS != null && map_CaseWithNATNDCS.containsKey(objTNDC.Case__c)) {
                        map_CaseWithNATNDCS.get(objTNDC.Case__c).add(objTNDC.Id);
                    } else {
                        map_CaseWithNATNDCS.put(objTNDC.Case__c, new Set<Id> {objTNDC.Id});
                    }
                } else {
                    if(map_CaseWithTNDCS != null && map_CaseWithTNDCS.containsKey(objTNDC.Case__c)) {
                        map_CaseWithTNDCS.get(objTNDC.Case__c).add(objTNDC.Id);
                    } else {
                        map_CaseWithTNDCS.put(objTNDC.Case__c, new Set<Id> {objTNDC.Id});
                    }
                }
                
                // group all TNDCs against the case record
                if(map_CaseWithOCRTNDC != null && map_CaseWithOCRTNDC.containsKey(objTNDC.Case__c)) {
                    map_CaseWithOCRTNDC.get(objTNDC.Case__c).add(objTNDC);
                } else {
                    map_CaseWithOCRTNDC.put(objTNDC.Case__c, new List<Tax_Notice_Index__c> {objTNDC});
                }
			}
            
			map_OCRTriggerdCaseIdWithRelevantCases = processOCRTNDCRecords(list_OCRTNDC, map_IdCaseReccords, map_KeyWithTNDCRecords);
            System.debug('map_OCRTriggerdCaseIdWithRelevantCases  : '+map_OCRTriggerdCaseIdWithRelevantCases);
		}
        return map_OCRTriggerdCaseIdWithRelevantCases;
	}
    
	/**
    * @name         TaxResCaseHelper
    * @author       Ela N
    * @description  This method is used processing the TNDC records after OCR Capture Complete
    **/
    public Map<Id, String> processOCRTNDCRecords(List<Tax_Notice_Index__c> list_TaxNoticeIndexes, Map<Id, Case> map_CaseRecords, Map<String, List<Tax_Notice_Index__c>> map_KeyWithTNDCRecords) {
        System.debug('******************* processOcrTNDCRecords1');
        Map<Tax_Notice_Index__c, Case> map_NewNoticeRelatedCases = new Map<Tax_Notice_Index__c, Case>();
		Map<Id, Integer> map_CaseIdTNDCRecordCount = new Map<Id, Integer>();
        Map<String, Account> map_ZPCompanyIdvsAccountRecord = new Map<String, Account>();
		List<String> paperMailExclusions = paperMailExclusionsSettings.Filter_Value__c.split(';');
		Set<Id> set_CaseIdsToSkip = new Set<Id>();
		map_TriggeredCaseRecords = map_CaseRecords;
        TaxNoticeIndexOCRUtil.map_TriggeredCaseRecords = map_CaseRecords;
		//Set<String> set_ZPCompanyIds = new Set<String>();
        Map<Id, String> map_OCRTriggerdCaseIdWithRelevantCases = new Map<Id, String>();
        TaxResIDPNoticeController idpController = new TaxResIDPNoticeController();
        
        if (!set_OCRClientNameTextsQuery.isEmpty() || !set_ZPCompanyIds.isEmpty()) {
            for (Account objAccount : [
                SELECT Id, Name, Is_Active_Customer__c, RecordTypeId, Tier__c, AM_Tier__c, RecordType.Name, ZP_Company_ID__c
                FROM Account
                WHERE Name != NULL AND Is_Active_Customer__c = TRUE AND (Name LIKE :set_OCRClientNameTextsQuery OR ZP_Company_ID__c IN :set_ZPCompanyIds)
            ]) {
                if (String.isNotBlank(objAccount.ZP_Company_ID__c) && set_ZPCompanyIds.contains(objAccount.ZP_Company_ID__c)) {
                    map_ZPCompanyIdvsAccountRecord.put(objAccount.ZP_Company_ID__c, objAccount);
                } 
                map_AccountNames.put(objAccount.Name.toLowerCase().trim(), objAccount); 
                map_AccountIds.put(objAccount.Id, objAccount);
                
            }
        }
        
        for(Case objCase : map_CaseRecords.values()) {

            System.debug('map_ZPCompanyIdvsAccountRecord ===> ' + map_ZPCompanyIdvsAccountRecord);
            System.debug('map_AccountNames ===> ' + map_AccountNames);
            System.debug('map_AccountIds ===> ' + map_AccountIds);

            String strMRRReasons = '';
            Tax_Notice_Index__c objManualIndex;
            
            System.debug('map_CaseWithOCRTNDC ==> ' + map_CaseWithOCRTNDC);
            
            //when all the attachments are ignored by the IDP
            if (map_CaseWithOCRTNDC == null || map_CaseWithOCRTNDC.isEmpty() || map_CaseWithOCRTNDC.get(objCase.Id) == null) {
                objManualIndex = new Tax_Notice_Index__c();
                objManualIndex.Case__c = objCase.Id;
                objManualIndex.Manual_Review_Required__c = true;
                objManualIndex.MRR_Reason__c = 'There are non actionable notices on this case, which system ignored.'; 
                objManualIndex.Gusto_is_addressee_of_record__c = objCase.Physical_Mail__c;
                objManualIndex.RecordTypeId = TaxNoticeIndexOCRUtil.TAX_NOTICE_INDEX_RECTYPE_MANUAL;
                objManualIndex.Bypass_Manual_Validation__c = true;
                map_NewNoticeRelatedCases.put(objManualIndex, objCase);
                
                objCase.Is_OCR_Processed__c = true;
                objCase.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_FAILED;
                objCase.OCR_Message__c = 'There are non actionable notices on this case';
            	objCase.OCR_Status__c = TaxNoticeIndexOCRUtil.STR_SFDC_ERROR_STATUS;
                objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
                objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
            } else {
                for (Tax_Notice_Index__c objNotice : map_CaseWithOCRTNDC.get(objCase.Id)) {
                    
                    // client match start
                    Id IdMatchedAccount;
                    String strClientNameTextTemp = objNotice.Client_Name_Text__c?.normalizeSpace().toLowerCase();
                    
                    if(map_CaseWithNATNDCS != null && map_CaseWithNATNDCS.containsKey(objCase.Id) && map_CaseWithNATNDCS.get(objCase.Id).contains(objNotice.Id)) {
                        if(String.isNotBlank(objNotice.MRR_Reason__c) && objNotice.MRR_Reason__c != null) {
                            strMRRReasons = strMRRReasons + objNotice.MRR_Reason__c + '; ';
                        }
                        continue;
                    }
                    
                    // find the account based on zp company id
                    if (objNotice.Case__c != null && String.isBlank(objNotice.Client_Name__c) && String.isNotBlank(objNotice.ZP_Company_Id__c)) {
                        if (map_ZPCompanyIdvsAccountRecord?.size() > 0 && map_ZPCompanyIdvsAccountRecord.containsKey(objNotice.ZP_Company_Id__c)) {
                            IdMatchedAccount = map_ZPCompanyIdvsAccountRecord.get(objNotice.ZP_Company_Id__c).Id;
                        }
                    }
                    
                    if (String.isNotBlank(objNotice.Client_Name_Text__c) && String.isBlank(objNotice.Client_Name__c) && objNotice.Case__c != null && IdMatchedAccount == null) {
                        String strClientNameMatch = objNotice.Client_Name_Match__c;
                        String strClientNameText = objNotice.Client_Name_Text__c.toLowerCase().trim();
                        if (map_AccountNames?.size() > 0) {
                            System.debug('Client_Name_Text__c ===> ' + strClientNameText);
                            if(map_AccountNames.containsKey(strClientNameText)) {
                                IdMatchedAccount = map_AccountNames.get(strClientNameText).Id;
                            }
    
                            // check for physical email check
                            if (String.isBlank(IdMatchedAccount) && objNotice.Case__r.Physical_Mail__c) {
                                for (Integer i = 0; i < paperMailExclusions.size(); i++) {
                                    String strNameTemp = strClientNameText.replace(paperMailExclusions[i].toLowercase(), '').trim();
                                    if (map_AccountNames.containsKey(strNameTemp)) {
                                        IdMatchedAccount = map_AccountNames.get(strNameTemp).Id;
                                        break; 
                                    }
                                }
                            }
                            
                            // Remove all the words from ignore list and add to set.
                            if (String.isBlank(IdMatchedAccount) && set_stringsOnAcctsEndToIgnore?.size() > 0) {
                                for (String strLiteral : set_stringsOnAcctsEndToIgnore) {
                                    System.debug('strLiteral ===> ' + strLiteral);
                                    if (strClientNameTextTemp.endsWithIgnoreCase(strLiteral)) {
                                        strClientNameTextTemp = strClientNameTextTemp.removeEndIgnoreCase(strLiteral).trim();
                                        System.debug('strClientNameTextTemp ===> ' + strClientNameTextTemp);
                                        System.debug(map_AccountNames.containsKey(strClientNameTextTemp));
                                        System.debug(map_AccountNames.get(strClientNameTextTemp));
                                        if (String.isNotBlank(strClientNameTextTemp) && map_AccountNames.containsKey(strClientNameTextTemp)) {
                                            IdMatchedAccount = map_AccountNames.get(strClientNameTextTemp).Id;
                                            break;
                                        }
                                    }
                                }
                            }
                            
                            if (String.isBlank(IdMatchedAccount) && set_stringsOnAcctsFrontToIgnore?.size() > 0) {
                                for (String strLiteral : set_stringsOnAcctsFrontToIgnore) {
                                    System.debug('strLiteral ===> ' + strLiteral);
                                    if (strClientNameTextTemp.startsWithIgnoreCase(strLiteral)) {
                                        strClientNameTextTemp = strClientNameTextTemp.removeStartIgnoreCase(strLiteral).trim();
                                        if (String.isNotBlank(strClientNameTextTemp) && map_AccountNames.containsKey(strClientNameTextTemp)) {
                                            IdMatchedAccount = map_AccountNames.get(strClientNameTextTemp).Id;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    System.debug('IdMatchedAccount ===> ' + IdMatchedAccount);
                    // client match end
                    
                    
                    if (IdMatchedAccount != null) {
                        objNotice.Client_Name__c = IdMatchedAccount;
                        objNotice.Automation_Message__c = TaxNoticeIndexOCRUtil.STR_SFDC_SUCCESS_MSG;
                        objNotice.Processing_State__c = TaxNoticeIndexOCRUtil.PROCESSINGSTATE_PROCESSED;
                    } else {
                        if (objNotice.Client_Name__c == null && (String.isNotBlank(objNotice.Client_Name_Text__c) || String.isNotBlank(objNotice.ZP_Company_Id__c))) {
                            objNotice.Automation_Message__c = TaxNoticeIndexOCRUtil.STR_SFDC_ERROR_ACCOUNTNOTFOUND_MSG;
                            objNotice.Processing_State__c = TaxNoticeIndexOCRUtil.PROCESSINGSTATE_ERROR;
                        } else if (objNotice.Client_Name__c != null) {
                            objNotice.Automation_Message__c = TaxNoticeIndexOCRUtil.STR_SFDC_SUCCESS_MSG;
                        	objNotice.Processing_State__c = TaxNoticeIndexOCRUtil.PROCESSINGSTATE_PROCESSED;
                        }
                    }
                    // client name matching end
                } // TNDC loop end
            }

            System.debug('strMRRReasons ===> ' + strMRRReasons);
            System.debug('map_CaseWithNATNDCS ===> ' + map_CaseWithNATNDCS);
            System.debug('map_CaseWithTNDCS ===> ' + map_CaseWithTNDCS);
            
            // case does not have any valid actionable TNDC records.
            if(map_CaseWithTNDCS == null || !map_CaseWithTNDCS.containsKey(objCase.Id)) {
                Id idTNDC;
                
                if(map_CaseWithNATNDCS != null && map_CaseWithNATNDCS.containsKey(objCase.Id)) {
                    if(map_CaseWithNATNDCS.get(objCase.Id).size() > 1) {
                        objManualIndex = new Tax_Notice_Index__c();
                        objCase.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_FAILED;
                    } else if(map_CaseWithNATNDCS.get(objCase.Id).size() == 1) {
                        idTNDC = map_CaseWithNATNDCS.get(objCase.Id).iterator().next();
                        objManualIndex = map_TNDC.containsKey(idTNDC) ? map_TNDC.get(idTNDC).clone() : new Tax_Notice_Index__c();
                        idpController.caseUpdatesAfterOCRComplete(objCase, map_TNDC.get(idTNDC), false);
                    }
                    
                    objManualIndex.Case__c = objCase.Id;
                    objManualIndex.Manual_Review_Required__c = true;
                    objManualIndex.MRR_Reason__c = 'There are non actionable notices on this case with the reasons : ' + strMRRReasons; 
                    objManualIndex.Gusto_is_addressee_of_record__c = objCase.Physical_Mail__c;
                    objManualIndex.RecordTypeId = TaxNoticeIndexOCRUtil.TAX_NOTICE_INDEX_RECTYPE_MANUAL;
                    objManualIndex.Bypass_Manual_Validation__c = true;
                    map_NewNoticeRelatedCases.put(objManualIndex, objCase);
                }
                
                objCase.Is_OCR_Processed__c = true;
                objCase.OCR_Message__c = 'There are non actionable notices on this case';
            	objCase.OCR_Status__c = TaxNoticeIndexOCRUtil.STR_SFDC_ERROR_STATUS;
                objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
                objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
            }
            //if there are actionable notices alone or with non actionable notices together
            //map_NewNoticeRelatedCases will have parent case with manual TNDC on it and child case with its related OCR TNDC
            else if (map_CaseWithTNDCS != null && map_CaseWithTNDCS.containsKey(objCase.Id) && map_CaseWithTNDCS.get(objCase.Id) != null) {
                for (Id idTNDC : map_CaseWithTNDCS.get(objCase.Id)) {
                    Tax_Notice_Index__c objTempTNDC = map_TNDC.get(idTNDC);
                    
                    if (objManualIndex == null) {
                        objManualIndex = objOCRUtilController.getNewTNDC(objTempTNDC, true);
                        idpController.caseUpdatesAfterOCRComplete(objCase, objTempTNDC, false);
                        
                        //update auto indexing status to partially indexed if confidence score is null or < 0.95
                        if (!objManualIndex.Manual_Review_Required__c && objCase.Auto_Indexing_Status__c != TaxResIDPNoticeController.AUTO_INDEX_STATUS_PARTIALLY_INDEXED && !objManualIndex.Bypass_Manual_Validation__c) {
                            for (Tax_Res_TNDC_Confidence_Score_Setting__mdt objMetadata : TaxNoticeIndexOCRUtil.list_ConfidenceScoreSetting) {
                                if (objManualIndex.get(objMetadata.Field_Api_Name__c) == null || (Decimal)objManualIndex.get(objMetadata.Field_Api_Name__c) < objMetadata.Confidence_Score__c) {
                                    objCase.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_PARTIALLY_INDEXED;
                                    break;
                                }
                            }
                        }
                        System.debug('objCase.Auto_Indexing_Status__c ==> ' + objCase.Auto_Indexing_Status__c);
                        map_NewNoticeRelatedCases.put(objManualIndex, objCase);
                    } else {
                        //baby case created if more than 1 actionable notice present
                        map_NewNoticeRelatedCases.put(objTempTNDC, objOCRUtilController.getNewCase(objCase, objTempTNDC));
                    }
                }

                if (map_CaseWithNATNDCS != null && map_CaseWithNATNDCS.containsKey(objCase.Id) && map_CaseWithNATNDCS.get(objCase.Id) != null) {
                    objManualIndex.MRR_Reason__c = String.isNotBlank(objManualIndex.MRR_Reason__c) ? objManualIndex.MRR_Reason__c + '\nThere are non actionable notices on this case with the reasons : ' + strMRRReasons : 'There are non actionable notices on this case with the reasons : ' + strMRRReasons;
					objManualIndex.Manual_Review_Required__c = true;
                    objCase.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_PARTIALLY_INDEXED;
                    objCase.Is_OCR_Processed__c = true;
                    objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
                    objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
                }
            }
        } // case loop end

       

        if (!map_NewNoticeRelatedCases.isEmpty()) {
            map_OCRTriggerdCaseIdWithRelevantCases = objOCRUtilController.saveRecords(map_NewNoticeRelatedCases, map_CaseRecords, map_KeyWithTNDCRecords);
        }
        
        if (!map_TNDCRecCaseId.isEmpty()) {
            objOCRUtilController.processOCRTNDCAttachments(map_TNDCRecCaseId);
        }
        
        return map_OCRTriggerdCaseIdWithRelevantCases;
    }

    /**
    * @name         TaxResCaseHelper
    * @author       Ela N
    * @description  This method is used getting accounts data via text name
    **/
    public Set<String> getAllAccountNameSearchString(Tax_Notice_Index__c objNotice) {
        Set<String> set_OCRClientNameTexts = new Set<String>();
        List<String> paperMailExclusions = paperMailExclusionsSettings.Filter_Value__c.split(';');
        
        if(String.isNotBlank(objNotice.Client_Name_Text__c) && String.isBlank(objNotice.Client_Name__c)) {
            String strClientNameTextTemp = '';
            strClientNameTextTemp = objNotice.Client_Name_Text__c?.normalizeSpace().toLowerCase();
            set_OCRClientNameTexts.add(strClientNameTextTemp + '%');
            
            // remove physical mail related extra strings
            if (objNotice.Case__r.Physical_Mail__c) {
                for (Integer i = 0; i < paperMailExclusions.size(); i++) {
                    String strExclusions = paperMailExclusions[i].toLowerCase();
                    if (strClientNameTextTemp.contains(strExclusions)) {
                        set_OCRClientNameTexts.add(strClientNameTextTemp.replace(strExclusions, '').trim() + '%');
                        break;
                    }
                }
            }
            
            // Remove all the words from ignore list and add to set.
            if (set_stringsOnAcctsEndToIgnore?.size() > 0) {
                for (String strLiteral : set_stringsOnAcctsEndToIgnore) {
                    if (strClientNameTextTemp.endsWithIgnoreCase(strLiteral)) {
                        strClientNameTextTemp = strClientNameTextTemp.removeEndIgnoreCase(strLiteral).trim();
                        if (String.isNotBlank(strClientNameTextTemp)) {
                            objNotice.Client_Name_Match__c = strClientNameTextTemp;
                            set_OCRClientNameTexts.add(strClientNameTextTemp + '%');
                            break;
                        }
                    }
                }
            }
            
            if (set_stringsOnAcctsFrontToIgnore?.size() > 0) {
                for (String strLiteral : set_stringsOnAcctsFrontToIgnore) {
                    if (strClientNameTextTemp.startsWithIgnoreCase(strLiteral)) {
                        strClientNameTextTemp = strClientNameTextTemp.removeStartIgnoreCase(strLiteral).trim();
                        if (String.isNotBlank(strClientNameTextTemp)) {
                            objNotice.Client_Name_Match__c = strClientNameTextTemp;
                            set_OCRClientNameTexts.add('%' + strClientNameTextTemp);
                            break;
                        }
                    }
                }
            }
            
            
        }
        return set_OCRClientNameTexts;
    }
    
    /**
    * @name         TaxResCaseHelper
    * @author       Ela N
    * @description  This method is used getting strings to ignore while searching accounts
    **/
    public static Set<String> getStringsToIgnore(String strConfigName) {
		List<String> list_AccountStrings = new List<String>();
		Set<String> set_AccountStrings = new Set<String>();
		Tax_Res_Play_Mode_Configuration__mdt objAccountStringConfig = new Tax_Res_Play_Mode_Configuration__mdt();
		objAccountStringConfig = CaseUtils.getQueryConfigurationRecords(strConfigName);
		list_AccountStrings = objAccountStringConfig?.Filter_Value__c?.split(';');
		if (list_AccountStrings?.size() > 0) {
			set_AccountStrings.addAll(list_AccountStrings);
		}

		return set_AccountStrings;
	}
}