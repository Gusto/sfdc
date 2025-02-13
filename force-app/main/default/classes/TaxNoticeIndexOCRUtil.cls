/**
 * @description TaxNoticeIndexOCRUtil
 * @see TaxNoticeIndexOCRUtilTest
 */
public with sharing class TaxNoticeIndexOCRUtil {
	//Constants
	public static final Id TAX_NOTICE_INDEX_RECTYPE_OCR = Cache.getRecordTypeId('Tax_Notice_Index__c', 'IDP Indexing');
	public static final Id TAX_NOTICE_INDEX_RECTYPE_MANUAL = Cache.getRecordTypeId('Tax_Notice_Index__c', 'Manual Indexing');
	public final static Id COMPANY_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Company');
	public static string STR_SFDC_SUCCESS_MSG = 'SFDC - Passed';
	public static string STR_SFDC_SUCCESS_STATUS = 'Completed';
	public static string STR_IB_FAILED_MSG = 'OCR Failed';
	public static string STR_IB_FAILED_STATUS = 'Failed';
	public static string CASE_STATUS_OCR_CAPTURE_COMPLETE = 'OCR Capture Complete';
	public static string STR_SFDC_ERROR_ACCOUNTNOTFOUND_MSG = 'SFDC - unable to find account name';
	public static string STR_SFDC_ERROR_AGENCYNOTFOUND_MSG = 'SFDC - unable to find agency/account';
	public static string STR_SFDC_ERROR_STATUS = 'Failed';
	public static string STR_SUCCESS_MSG_TNDC_CREATED = 'SFDC - TNDC Record Created';
	public static string AGENCY_IRS = 'Internal Revenue Service';
	public static string AGENCY_CAEDD = 'CA-EDD';
	public static string AGENCY_TX = 'Texas Workforce Commission';
	public static string AGENCY_WA = 'Washington State Employment Security Department';
	public static string PROCESSINGSTATE_PROCESSED = 'Processed';
	public static string PROCESSINGSTATE_ERROR = 'Error';
	public static Map<String, Agency_Information__c> map_AllAgencies = GlobalQueryHelper.getAllAgencyNamesWithAgencyInformation();
	public static Map<Id, Agency_Information__c> map_AgencyById = GlobalQueryHelper.map_Agency;
	public static final String CFG_ACCT_STR_END_TO_IGNORE = 'Strings_to_Ignore';
	public static final String CFG_ACCT_STR_FRONT_TO_IGNORE = 'Strings_to_Ignore_at_Front';
	public static final Set<String> set_stringsOnAcctsEndToIgnore = getStringsToIgnore(CFG_ACCT_STR_END_TO_IGNORE);
	public static final Set<String> set_stringsOnAcctsFrontToIgnore = getStringsToIgnore(CFG_ACCT_STR_FRONT_TO_IGNORE);
	public static final String STR_NON_ACTIONABLE_NOTICE_MESSAGE = 'Note: There is a non actionable TNDC available on the case';
	public static Tax_Res_Play_Mode_Configuration__mdt paperMailExclusionsSettings = Tax_Res_Play_Mode_Configuration__mdt.getInstance('Paper_Mail_Exclusions');

	//Case related variables
	Map<Id, Case> map_CaseRecords = new Map<Id, Case>();
	public static Map<Id, Case> map_TriggeredCaseRecords = new Map<Id, Case>();
	public Set<String> set_OCRClientNameTextsQuery = new Set<String>();
	Map<String, Account> map_AccountNames = new Map<String, Account>();
	Map<Id, Account> map_AccountIds = new Map<Id, Account>();
	Map<Id, Id> map_TNDCRecCaseId = new Map<Id, Id>();

	public static List<Tax_Res_TNDC_Confidence_Score_Setting__mdt> list_ConfidenceScoreSetting = Tax_Res_TNDC_Confidence_Score_Setting__mdt.getAll().values();

	//tax notice index default values
	static Id IRS_AGENCY_ID_DEFAULT = getAgencyId(AGENCY_IRS);
	static Id CAEDD_AGENCY_ID_DEFAULT = getAgencyId(AGENCY_CAEDD);
	static Id TX_AGENCY_ID_DEFAULT = getAgencyId(AGENCY_TX);
	static Id WA_AGENCY_ID_DEFAULT = getAgencyId(AGENCY_WA);
	static String AGENCY_ASSIGNED_DEFAULT = 'FEIN';
	static String TAX_NOTICE_TYPE_DEFAULT = '941';
	public static String TNDC_FORM_NUMBER_CP161 = 'CP161';
    public static String TNDC_FORM_NUMBER_CP = 'CP';
	public static String TNDC_FORM_TYPE_940 = '940';
	public static String TNDC_FORM_TYPE_941 = '941';
	public static String TNDC_FORM_TYPE_944 = '944';
	public static String TNDC_FORM_TYPE_UNSUPPORTED = 'Unsupported';
	static Date TAX_NOTICE_DATE_DEFAULT = System.today();
	static Date TAX_NOTICE_DUE_DATE_DEFAULT = System.today();
	static String TAX_NOTICE_FORM_NUMBER_DEFAULT = 'NOFORMNUMBER';
	static String TAX_NOTICE_NUMERATION_DEFAULT = '1st';
	static Integer TAX_NOTICE_AMOUNT_TOTAL_DEFAULT = 0;
	static Integer TAX_NOTICE_TAX_AMOUNT_DEFAULT = 0;
	static Integer TAX_NOTICE_PI_DEFAULT = 0;
	static String TAX_NOTICE_YR_QTR_DEFAULT = TaxResNoticeIndexDetailsController.getQuarterAndYear(System.today());
	static String TAX_NOTICE_MULTI_YR_QTR_DEFAULT = 'N';
	static Integer PENALTY_AMOUNT_DUE_DEFAULT = 0;
	static Integer INTEREST_AMOUNT_DUE_DEFAULT = 0;
	public static String TNDC_FORM_TYPE_SUI = 'SUI';

	public static List<SelectOption> lst_YrQtrValues = UtilitiesFactory.getPickListValues('Tax_Notice_Index__c', 'Yr_Qtr__c', null);
	public static Set<String> set_YrQtrValues = new Set<String>();
	public static Set<Id> set_SUIAgencyIds = new Set<Id>();

	public TaxNoticeIndexOCRUtil() {
		for (SelectOption s : lst_YrQtrValues) {
			set_YrQtrValues.add(s.getValue());
		}

		set_SUIAgencyIds.add(CAEDD_AGENCY_ID_DEFAULT);
		set_SUIAgencyIds.add(TX_AGENCY_ID_DEFAULT);
		set_SUIAgencyIds.add(WA_AGENCY_ID_DEFAULT);
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : contains logic to process TNDC records for eligible Cases
	 * @Parm        : list_TaxNoticeIndexes - List of TNDC records
	 *                map_OldTaxNoticeIndexes - old trigger map for Tax_Notice_Index__c records
	 * @Return      : N/A
	 **/
	public void processOcrTNDCRecords(List<Tax_Notice_Index__c> list_TaxNoticeIndexes, Map<Id, Case> map_CaseRecords) {
		Map<Tax_Notice_Index__c, Case> map_NewNoticeRelatedCases = new Map<Tax_Notice_Index__c, Case>();
		Map<Id, Integer> map_CaseIdTNDCRecordCount = new Map<Id, Integer>();
		List<String> paperMailExclusions = paperMailExclusionsSettings.Filter_Value__c.split(';');
		Set<Id> set_CaseIdsToSkip = new Set<Id>();
		map_TriggeredCaseRecords = map_CaseRecords;

		String strClientNameSOSL = null;
		if (map_CaseRecords.size() > 0) {
			for (Tax_Notice_Index__c objNotice : list_TaxNoticeIndexes) {
				if (String.isNotBlank(objNotice.Client_Name_Text__c) && String.isBlank(objNotice.Client_Name_Match__c) && String.isBlank(objNotice.Client_Name__c)) {
					String strClientNameTextTemp = '';
					// Remove all trailing spaces and convert to lowercase and add to set
					strClientNameTextTemp = objNotice.Client_Name_Text__c?.normalizeSpace().toLowerCase();
					objNotice.Client_Name_Match__c = strClientNameTextTemp;
					set_OCRClientNameTextsQuery.add(strClientNameTextTemp + '%');

					if (objNotice.Case__r.Physical_Mail__c) {
						for (Integer i = 0; i < paperMailExclusions.size(); i++) {
							String strExclusions = paperMailExclusions[i].toLowerCase();
							if (strClientNameTextTemp.contains(strExclusions)) {
								set_OCRClientNameTextsQuery.add(strClientNameTextTemp.replace(strExclusions, '').trim() + '%');
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
									set_OCRClientNameTextsQuery.add(strClientNameTextTemp + '%');
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
									set_OCRClientNameTextsQuery.add('%' + strClientNameTextTemp);
									break;
								}
							}
						}
					}

					if (String.isNotBlank(strClientNameTextTemp)) {
						strClientNameSOSL = strClientNameTextTemp;
					}
				}
			}

			if (!set_OCRClientNameTextsQuery.isEmpty()) {
				for (Account objAccount : [
					SELECT Id, Name, Is_Active_Customer__c, RecordTypeId, Tier__c, AM_Tier__c, RecordType.Name
					FROM Account
					WHERE Name != NULL AND Is_Active_Customer__c = TRUE AND Name LIKE :set_OCRClientNameTextsQuery
				]) {
					map_AccountNames.put(objAccount.Name, objAccount);
					map_AccountIds.put(objAccount.Id, objAccount);
				}
			}

			if (map_AccountNames.isEmpty() && String.isNotBlank(strClientNameSOSL)) {
				List<List<SObject>> list_Results = [
					FIND :strClientNameSOSL
					IN NAME FIELDS
					RETURNING Account(Id, Name, Is_Active_Customer__c, RecordTypeId, Tier__c, AM_Tier__c, RecordType.Name WHERE Is_Active_Customer__c = TRUE)
				];
				for (Account objAccount : (List<Account>) list_Results[0]) {
					map_AccountNames.put(objAccount.Name, objAccount);
					map_AccountIds.put(objAccount.Id, objAccount);
				}
			}

			for (Tax_Notice_Index__c objNotice : list_TaxNoticeIndexes) {
				Id IdMatchedAccount;
				Case objCase = map_CaseRecords.get(objNotice.Case__c);
				if (String.isNotBlank(objNotice.Client_Name_Text__c) && String.isNotBlank(objNotice.Client_Name_Match__c) && String.isBlank(objNotice.Client_Name__c) && objNotice.Case__c != null) {
					String strClientNameMatch = objNotice.Client_Name_Match__c;
					if (map_AccountNames?.size() > 0) {
						for (Account objAcc : map_AccountNames.values()) {
							if (objAcc.Name.equalsIgnoreCase(objNotice.Client_Name_Text__c)) {
								IdMatchedAccount = objAcc.Id;
								break;
							}
						}

						// check for physical email check
						if (String.isBlank(IdMatchedAccount) && objNotice.Case__r.Physical_Mail__c) {
							for (Integer i = 0; i < paperMailExclusions.size(); i++) {
								String strNameTemp = objNotice.Client_Name_Text__c.replace(paperMailExclusions[i].toLowercase(), '').trim();
								if (map_AccountNames.containsKey(strNameTemp)) {
									IdMatchedAccount = map_AccountNames.get(strNameTemp).Id;
									break;
								}
							}
						}

						if (String.isBlank(IdMatchedAccount)) {
							for (Account objAcc : map_AccountNames.values()) {
								if (objAcc.Name.containsIgnoreCase(strClientNameMatch) || strClientNameMatch.containsIgnoreCase(objAcc.Name)) {
									//cloud 9 infosystems, inc. contains cloud 9 infosystems
									IdMatchedAccount = objAcc.Id;
									break;
								}
							}
						}
					}

					if (IdMatchedAccount != null) {
						objNotice.Client_Name__c = IdMatchedAccount;
						objNotice.Automation_Message__c = STR_SFDC_SUCCESS_MSG;
						objNotice.Processing_State__c = PROCESSINGSTATE_PROCESSED;
					} else {
						objNotice.Automation_Message__c = STR_SFDC_ERROR_ACCOUNTNOTFOUND_MSG;
						objNotice.Processing_State__c = PROCESSINGSTATE_ERROR;
					}
				}

				if (objNotice.Processing_State__c == PROCESSINGSTATE_ERROR) {
					set_CaseIdsToSkip.add(objNotice.Case__c);
				}

				//skip error out TNDC records
				if (set_CaseIdsToSkip.contains(objCase.Id)) {
					objCase = moveCaseToSpecialist(objCase, STR_SFDC_ERROR_ACCOUNTNOTFOUND_MSG, STR_SFDC_ERROR_STATUS, false);
					continue;
				} else if (objCase.Status == CASE_STATUS_OCR_CAPTURE_COMPLETE && objCase.OCR_Status__c != STR_IB_FAILED_STATUS && objNotice.Processing_State__c != PROCESSINGSTATE_ERROR) {
					Integer intCaseIndexRecordsCount = map_CaseIdTNDCRecordCount.containsKey(objCase.Id) ? map_CaseIdTNDCRecordCount.get(objCase.Id) : 0; //1
					if (intCaseIndexRecordsCount == 0) {
						Tax_Notice_Index__c objManualIndex = getNewTNDC(objNotice, true);
						objManualIndex.Gusto_is_addressee_of_record__c = objCase.Physical_Mail__c;
						map_NewNoticeRelatedCases.put(objManualIndex, objCase);
						map_TNDCRecCaseId.put(objNotice.Id, objCase.Id);
					} else {
						map_NewNoticeRelatedCases.put(objNotice, getNewCase(objCase, objNotice));
					}

					map_CaseIdTNDCRecordCount.put(objCase.Id, intCaseIndexRecordsCount + 1); //2
				}
			}

			if (map_NewNoticeRelatedCases?.size() > 0) {
				//saveRecords(map_NewNoticeRelatedCases, map_CaseRecords, null);
			}
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : contains logic to clone Attachment from TNDC to related Case
	 * @Parm        : list_Attachments - List of TNDC related Attachment Records
	 *                set_TNDCIds - set of related TNDC records
	 * @Return      : N/A
	 **/
	public void processOCRTNDCAttachments(Map<Id, Id> map_TNDCIDCaseId) {
		List<Attachment> list_InsertAttachments = new List<Attachment>();
		List<Attachment> list_deleteAttachments = new List<Attachment>();

		if (map_TNDCIDCaseId?.size() > 0) {
			for (Attachment objAttachment : [SELECT Id, ParentId, Name, Body FROM Attachment WHERE ParentId != NULL AND ParentId IN :map_TNDCIDCaseId.keySet()]) {
				if (map_TNDCIdCaseId.containsKey(objAttachment.ParentId)) {
					Id idCase = map_TNDCIdCaseId.get(objAttachment.ParentId);
					//cloning attachment to related case
					Attachment objNewAtt = objAttachment.clone();
					objNewAtt.ParentId = idCase;
					list_InsertAttachments.add(objNewAtt);
					list_deleteAttachments.add(objAttachment);
				}
			}

			insert list_InsertAttachments;
			delete list_deleteAttachments;
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Returns new Case record
	 * @Parm        : objParentCase - case object
	 *                  objIndex - TNDC record
	 * @Return      : Case instance
	 **/
	public Case getNewCase(Case objParentCase, Tax_Notice_Index__c objIndex) {
		Case objNewCase = new Case(
			Subject = 'Your Request Has Been Split: New Ticket [New_Case_No] Created from ' + objParentCase.CaseNumber,
			Description = objParentCase.Description,
			Direction__c = objParentCase.Direction__c,
			Related_Case__c = objParentCase.Id,
			ParentId = objParentCase.Id,
			AccountId = objIndex.Client_Name__c,
			ContactId = objParentCase.ContactId,
			Agency_Information__c = objIndex.Agency_Information__c,
			RecordTypeId = CaseUtils.RECTYPE_TAXRES,
			Type = 'Tax Res',
			Baby_Case_Identifier__c = 'Baby Case for Parent Case #' + objParentCase.CaseNumber,
			OCR_Status__c = objParentCase.OCR_Status__c,
			Automation_Message_Details__c = objParentCase.Automation_Message_Details__c,
			Is_OCR_Processed__c = objParentCase.Is_OCR_Processed__c,
			Physical_Mail__c = objParentCase.Physical_Mail__c,
			Origin = objParentCase.Origin
		);

		TaxResIDPNoticeController idpController = new TaxResIDPNoticeController();
		idpController.caseUpdatesAfterOCRComplete(objNewCase, objIndex, false);

		//update auto indexing status to partially indexed if confidence score is null or < 0.95
		if (!objIndex.Manual_Review_Required__c && objNewCase.Auto_Indexing_Status__c != TaxResIDPNoticeController.AUTO_INDEX_STATUS_PARTIALLY_INDEXED) {
			for (Tax_Res_TNDC_Confidence_Score_Setting__mdt objMetadata : list_ConfidenceScoreSetting) {
				if (objIndex.get(objMetadata.Field_Api_Name__c) == null || (Decimal) objIndex.get(objMetadata.Field_Api_Name__c) < objMetadata.Confidence_Score__c) {
					objNewCase.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_PARTIALLY_INDEXED;
					break;
				}
			}
		}

		return objNewCase;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Returns new TNDC reord by cloning already present TNDC record
	 * @Parm        : objIndex - List of Payroll Audit rows from CSV
	 *                  blnManual
	 * @Return      : Tax_Notice_Index__c instance
	 **/
	public Tax_Notice_Index__c getNewTNDC(Tax_Notice_Index__c objIndex, Boolean blnManual) {
		Tax_Notice_Index__c objNewIndex = objIndex.clone();
		Account objAccount = new Account();
		Case objParentCase = map_TriggeredCaseRecords.get(objIndex.Case__c);
		Set<String> set_ImpactedFields = new Set<String>();

		if (map_AccountIds?.containsKey(objNewIndex.Client_Name__c)) {
			objAccount = map_AccountIds.get(objNewIndex.Client_Name__c);
		}
		if (blnManual) {
			objNewIndex.RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL;

			// adding fields to map which are present in the MRR Reason
			if (objIndex.TNDC_MRR_Reasons__r != null) {
				for (TNDC_MRR_Reasons__c objMRRReason : objIndex.TNDC_MRR_Reasons__r) {
					set_ImpactedFields.add(objMRRReason.Field__c);
				}
			}
		}

		//assign default values
		if (objIndex.No_Notice_Attached__c) {
			objNewIndex.No_Notice_Attached__c = objIndex.No_Notice_Attached__c;
		} else {
			objNewIndex.Agency_Information__c = objNewIndex.Agency_Information__c == null && IRS_AGENCY_ID_DEFAULT != null ? IRS_AGENCY_ID_DEFAULT : objIndex.Agency_Information__c;
			//update tax notice type as per BPO-1936
			if (objNewIndex.Agency_Information__c != null && set_SUIAgencyIds.contains(objNewIndex.Agency_Information__c) && String.isBlank(objNewIndex.Tax_Notice_Type__c)) {
				objNewIndex.Tax_Notice_Type__c = TNDC_FORM_TYPE_SUI;
			}

			//update tax notice type update as per BPO-1831
			if (
                objNewIndex.Tax_Notice_Form_Number__c != null &&
                (objNewIndex.Tax_Notice_Form_Number__c).startsWith(TNDC_FORM_NUMBER_CP) &&
				objNewIndex.Tax_Notice_Type__c != TNDC_FORM_TYPE_940 &&
				objNewIndex.Tax_Notice_Type__c != TNDC_FORM_TYPE_941 &&
				objNewIndex.Tax_Notice_Type__c != TNDC_FORM_TYPE_944
			) {
				objNewIndex.Tax_Notice_Type__c = TNDC_FORM_TYPE_UNSUPPORTED;
			}
			objNewIndex.Tax_Notice_Date__c = objNewIndex.Tax_Notice_Date__c == null ? TAX_NOTICE_DATE_DEFAULT : objIndex.Tax_Notice_Date__c;
			objNewIndex.Tax_Notice_Numeration__c = objNewIndex.Tax_Notice_Numeration__c == null ? TAX_NOTICE_NUMERATION_DEFAULT : objIndex.Tax_Notice_Numeration__c;
			objNewIndex.Tax_Notice_Amount_Total__c = objNewIndex.Tax_Notice_Amount_Total__c == null ? TAX_NOTICE_AMOUNT_TOTAL_DEFAULT : objIndex.Tax_Notice_Amount_Total__c;
			objNewIndex.Tax_Notice_Tax_Amount__c = objNewIndex.Tax_Notice_Tax_Amount__c == null ? TAX_NOTICE_TAX_AMOUNT_DEFAULT : objIndex.Tax_Notice_Tax_Amount__c;
			objNewIndex.Yr_Qtr__c = objNewIndex.Yr_Qtr__c == null ? TAX_NOTICE_YR_QTR_DEFAULT : objIndex.Yr_Qtr__c;
			objNewIndex.Multi_YR_QTR_Indicator__c = objNewIndex.Multi_YR_QTR_Indicator__c == null ? TAX_NOTICE_MULTI_YR_QTR_DEFAULT : objIndex.Multi_YR_QTR_Indicator__c;
			objNewIndex.Segment__c = objAccount?.RecordType?.Name;
			objNewIndex.Penalty_Amount_Due__c = objNewIndex.Penalty_Amount_Due__c == null ? PENALTY_AMOUNT_DUE_DEFAULT : objIndex.Penalty_Amount_Due__c;
			objNewIndex.Interest_Amount_Due__c = objNewIndex.Interest_Amount_Due__c == null ? INTEREST_AMOUNT_DUE_DEFAULT : objIndex.Interest_Amount_Due__c;

			//populate SUI rate to manual indexing TNDC record
			objNewIndex.SUI_Rate_Effective_Date__c = objIndex.SUI_Rate_Effective_Date__c;
			objNewIndex.Tax_Rate_Json__c = objIndex.Tax_Rate_Json__c;
			objNewIndex.Gusto_is_addressee_of_record__c = objParentCase.Physical_Mail__c;

			if (objAccount?.RecordTypeId == COMPANY_ACCOUNT_RT_ID) {
				objNewIndex.Tier__c = objAccount?.Tier__c;
				objNewIndex.Partner_Tier__c = null;
			} else {
				objNewIndex.Partner_Tier__c = objAccount?.AM_Tier__c;
				objNewIndex.Tier__c = null;
			}

			//for "Electronic Notice" Origin cases RAF indicator should be true by default
			if (objParentCase?.Id != null && objParentCase.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE) {
				objNewIndex.RAF_Indicator__c = 'Y';
			}

			//Assign Confidence Score values
			objNewIndex.Client_Tax_ID_Conf_Score__c = objIndex.Client_Tax_ID_Conf_Score__c;
			objNewIndex.Interest_Amount_Due_Conf_Score__c = objIndex.Interest_Amount_Due_Conf_Score__c;
			objNewIndex.Multi_Yr_Qtr_Indicator_Conf_Score__c = objIndex.Multi_Yr_Qtr_Indicator_Conf_Score__c;
			objNewIndex.Notice_Form_Number_Conf_Score__c = objIndex.Notice_Form_Number_Conf_Score__c;
			objNewIndex.Penalty_Amount_Due_Conf_Score__c = objIndex.Penalty_Amount_Due_Conf_Score__c;
			objNewIndex.Tax_Amount_Due_Conf_Score__c = objIndex.Tax_Amount_Due_Conf_Score__c;
			objNewIndex.Tax_Notice_Date_Conf_Score__c = objIndex.Tax_Notice_Date_Conf_Score__c;
			objNewIndex.Tax_Notice_Numeration_Conf_Score__c = objIndex.Tax_Notice_Numeration_Conf_Score__c;
			objNewIndex.Tax_Notice_Type_Conf_Score__c = objIndex.Tax_Notice_Type_Conf_Score__c;
			objNewIndex.Total_Amount_Due_Conf_Score__c = objIndex.Total_Amount_Due_Conf_Score__c;
			objNewIndex.Year_Quarter_Conf_Score__c = objIndex.Year_Quarter_Conf_Score__c;
			objNewIndex.Tax_Notice_Due_Date_Conf_Score__c = objIndex.Tax_Notice_Due_Date_Conf_Score__c;

			objNewIndex.Manual_Review_Required__c = objIndex.Manual_Review_Required__c;
			objNewIndex.MRR_Reason__c = objIndex.MRR_Reason__c;

			// make the Yr/Qtr confident score is 0 when the pick list value is not valid. So that, in TNDC tabl manually validated checkbox will appear
			if (String.isNotBlank(objNewIndex.Yr_Qtr__c) && set_YrQtrValues != null && !set_YrQtrValues.isEmpty() && !set_YrQtrValues.contains(objNewIndex.Yr_Qtr__c)) {
				objNewIndex.Year_Quarter_Conf_Score__c = 0;
			}

			if (
				objIndex.Client_Name__c != null &&
				objIndex.Agency_Information__c != null &&
				objNewIndex.Agency_Information__c == IRS_AGENCY_ID_DEFAULT &&
				!objNewIndex.Manual_Review_Required__c &&
				set_ImpactedFields.isEmpty() &&
				String.isNotBlank(objNewIndex.Assigned_Client_Tax_ID_Agency_Assigned__c) &&
				objNewIndex.Tax_Notice_Amount_Total__c != null &&
				objNewIndex.Tax_Notice_Amount_Total__c != 0
			) {
				objNewIndex.Bypass_Manual_Validation__c = true;
			}

			if (set_ImpactedFields != null && !set_ImpactedFields.isEmpty()) {
				for (String strFieldName : set_ImpactedFields) {
					for (Tax_Res_TNDC_Confidence_Score_Setting__mdt objMetadata : list_ConfidenceScoreSetting) {
						if (String.isNotBlank(objMetadata.Field_Name_in_MRR_Reason__c) && strFieldName == objMetadata.Field_Name_in_MRR_Reason__c) {
							objNewIndex.put(objMetadata.Field_Api_Name__c, 0);
						}
					}
				}
			}
		}

		return objNewIndex;
	}

	/**
	 * @Author      : Pawan Kumar
	 * @Description : moveBothSystemSuccessCasesToSpecialist
	 * @Parm        : map_IdCaseRecords - Case object map from trigger
	 **/
	public static void moveBothSystemSuccessCasesToSpecialist(Map<Id, Case> map_IdCaseRecords, Set<Id> set_ChildCaseIds) {
		List<Id> list_CaseIds = new List<Id>();
		for (Id IdCase : map_IdCaseRecords.keySet()) {
			Case objCaseDetail = map_IdCaseRecords.get(IdCase);
			//Shyam: Added Autosolve check flag instead of IRS
			if (
				objCaseDetail.Agency_Information__c != null &&
				map_AgencyById.get(objCaseDetail.Agency_Information__c).AutoSolve_Enabled__c &&
				(objCaseDetail.Auto_Indexing_Status__c == TaxResIDPNoticeController.AUTO_INDEX_STATUS_FULLY_INDEXED || Test.isRunningTest()) &&
				(objCaseDetail.Status == CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE || Test.isRunningTest())
			) {
				list_CaseIds.add(IdCase);
			}
		}

		if (list_CaseIds?.size() > 0) {
			TaxResNoticeIndexDetailsController.blnBothSystemSuccess = true;
			List<Case> list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(list_CaseIds);
			List<Case> list_updateBabyCaseRecords = new List<Case>();
			if (list_CaseRecords?.size() > 0) {
				for (Case objCaseRecord : list_CaseRecords) {
					if (map_IdCaseRecords?.size() > 0 && map_IdCaseRecords.containsKey(objCaseRecord.Id)) {
						Case objCase = map_IdCaseRecords.get(objCaseRecord.Id);
						objCase.Automation_Message_Follow_Up__c = String.isNotBlank(objCaseRecord.Automation_Message_Follow_Up__c) ? objCaseRecord.Automation_Message_Follow_Up__c : '';

						// for child cases, the status field will be empty so make sure if the status is null, assign to OCR DATA CAPTURE COMP
						objCase.Status = String.isNotBlank(objCaseRecord.Status) ? objCaseRecord.Status : objCase.Status;
						// when child case instance is created, status is not populated
						// for child cases, it will be empty status so update it here.
						objCase.Status = String.isNotBlank(objCase.Status) ? objCase.Status : CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE;
						objCase.OwnerId = objCaseRecord.OwnerId != null ? objCaseRecord.OwnerId : objCase.OwnerId;
						// when child case instance is created, owner is not populated
						// for child cases, it will be empty owner so update it here.
						objCase.OwnerId = objCase.OwnerId != null ? objCase.OwnerId : CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
						objCase.Agency_Information__c = objCaseRecord.Agency_Information__c != null ? objCaseRecord.Agency_Information__c : objCase.Agency_Information__c;
						objCase.Related_Company__c = objCaseRecord.Related_Company__c != null ? objCaseRecord.Related_Company__c : objCase.Related_Company__c;
						objCase.Notice_Period__c = objCaseRecord.Notice_Period__c != null ? objCaseRecord.Notice_Period__c : objCase.Notice_Period__c;
						objCase.Tax_Notice_Type__c = objCaseRecord.Tax_Notice_Type__c != null ? objCaseRecord.Tax_Notice_Type__c : objCase.Tax_Notice_Type__c;
						objCase.Payment_Due_Date__c = objCaseRecord.Payment_Due_Date__c != null ? objCaseRecord.Payment_Due_Date__c : objCase.Payment_Due_Date__c;
						objCase.Tax_Notice_Date__c = objCaseRecord.Tax_Notice_Date__c != null ? objCaseRecord.Tax_Notice_Date__c : objCase.Tax_Notice_Date__c;
						objCase.Tax_Notice_Form_Number__c = objCaseRecord.Tax_Notice_Form_Number__c != null ? objCaseRecord.Tax_Notice_Form_Number__c : objCase.Tax_Notice_Form_Number__c;
						objCase.Tax_Notice_Numeration__c = objCaseRecord.Tax_Notice_Numeration__c != null ? objCaseRecord.Tax_Notice_Numeration__c : objCase.Tax_Notice_Numeration__c;
						objCase.Penalty_Amount__c = objCaseRecord.Penalty_Amount__c != null ? objCaseRecord.Penalty_Amount__c : objCase.Penalty_Amount__c;
						objCase.Tax_Notice_Amount_Total__c = objCaseRecord.Tax_Notice_Amount_Total__c != null ? objCaseRecord.Tax_Notice_Amount_Total__c : objCase.Tax_Notice_Amount_Total__c;
						objCase.Multi_YR_QTR_Indicator__c = objCaseRecord.Multi_YR_QTR_Indicator__c != null ? objCaseRecord.Multi_YR_QTR_Indicator__c : objCase.Multi_YR_QTR_Indicator__c;
						objCase.Assigned_Client_Tax_ID__c = objCaseRecord.Assigned_Client_Tax_ID__c != null ? objCaseRecord.Assigned_Client_Tax_ID__c : objCase.Assigned_Client_Tax_ID__c;
						objCase.Action_Taken__c = objCaseRecord.Action_Taken__c != null ? objCaseRecord.Action_Taken__c : objCase.Action_Taken__c;
						objCase.Notes__c = objCaseRecord.Notes__c != null ? objCaseRecord.Notes__c : objCase.Notes__c;
						objCase.Skill_Pattern__c = objCaseRecord.Skill_Pattern__c != null ? objCaseRecord.Skill_Pattern__c : objCase.Skill_Pattern__c;
						objCase.Mass_Email_Step__c = objCaseRecord.Mass_Email_Step__c != null ? objCaseRecord.Mass_Email_Step__c : objCase.Mass_Email_Step__c;
						objCase.Auto_Response_Email_Content__c = objCaseRecord.Auto_Response_Email_Content__c != null
							? objCaseRecord.Auto_Response_Email_Content__c
							: objCase.Auto_Response_Email_Content__c;
						objCase.Customer_Actions_Required__c = objCaseRecord.Customer_Actions_Required__c != null ? objCaseRecord.Customer_Actions_Required__c : objCase.Customer_Actions_Required__c;
						objCase.Customer_Journey__c = objCaseRecord.Customer_Journey__c != null ? objCaseRecord.Customer_Journey__c : objCase.Customer_Journey__c;
						objCase.Root_Cause__c = objCaseRecord.Root_Cause__c != null ? objCaseRecord.Root_Cause__c : objCase.Root_Cause__c;
						objCase.Sub_Root_Cause__c = objCaseRecord.Sub_Root_Cause__c != null ? objCaseRecord.Sub_Root_Cause__c : objCase.Sub_Root_Cause__c;

						if (String.isNotBlank(objCase.Baby_Case_Identifier__c) && set_ChildCaseIds != null && set_ChildCaseIds.contains(objCase.Id)) {
							list_updateBabyCaseRecords.add(objCase);
						}
						// when OCR auto index the case, make sure the related case and parent id is populated for previously answered cases
						if (String.isNotBlank(objCaseRecord.Mass_Email_Step__c) && objCaseRecord.Mass_Email_Step__c.contains(TaxResNoticeIndexDetailsController.PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED)) {
							objCase.Related_Case__c = objCaseRecord.Related_Case__c;
						}
					}
				}

				if (list_updateBabyCaseRecords?.size() > 0) {
					Boolean blnPreviousVal = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = false;
					update list_updateBabyCaseRecords;
					CaseTriggerHelper.skipTrigger = blnPreviousVal;
				}
			}
		}
	}

	public static Case moveCaseToSpecialist(Case objCase, String strAutomationMessage, String strAutomationStatus, Boolean blnBothSystemSuccessCase) {
		if (String.isBlank(objCase.OCR_Message__c)) {
			objCase.OCR_Message__c = strAutomationMessage;
		}
		if (String.isBlank(objCase.OCR_Status__c)) {
			objCase.OCR_Status__c = strAutomationStatus;
		}

		if (!blnBothSystemSuccessCase || (blnBothSystemSuccessCase && objCase.Auto_Indexing_Status__c != TaxResIDPNoticeController.AUTO_INDEX_STATUS_FULLY_INDEXED)) {
			objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
			objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
		}
		return objCase;
	}

	public Map<Id, String> saveRecords(Map<Tax_Notice_Index__c, Case> map_NewNoticeRelatedCases, Map<Id, Case> map_CaseRecords, Map<String, List<Tax_Notice_Index__c>> map_KeyWithTNDCRecords) {
		try {
			List<Tax_Notice_Index__c> list_TempTNDC = new List<Tax_Notice_Index__c>();
			List<Case> list_ChildCases = new List<Case>();
			Set<Id> set_ChildCaseIds = new Set<Id>();
			Set<Id> set_ParentCaseIds = new Set<Id>();
			Map<Id, String> map_OCRTriggerdCaseIdWithRelevantCases = new Map<Id, String>();

			if (map_NewNoticeRelatedCases?.size() > 0) {
				for (Tax_Notice_Index__c objNotice : map_NewNoticeRelatedCases.keySet()) {
					Case objCase = map_NewNoticeRelatedCases.get(objNotice);
					//Shyam: Added Autosolve check flag instead of IRS
					Boolean blnBthSystemSuccess = map_AgencyById.containsKey(objCase.Agency_Information__c) && map_AgencyById.get(objCase.Agency_Information__c).AutoSolve_Enabled__c ? true : false;
					objCase = moveCaseToSpecialist(
						objCase,
						String.isNotBlank(objNotice.Automation_Message__c) ? objNotice.Automation_Message__c : STR_SUCCESS_MSG_TNDC_CREATED,
						STR_SFDC_SUCCESS_STATUS,
						blnBthSystemSuccess
					);

					set_ParentCaseIds.add(objCase.ParentId);
					if (objCase.Id == null) {
						list_ChildCases.add(objCase);
					}
				}

				if (list_ChildCases?.size() > 0) {
					Boolean blnPreviousVal = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = false;
					insert list_ChildCases;
					CaseTriggerHelper.skipTrigger = blnPreviousVal;
				}

				for (Case objCase : map_NewNoticeRelatedCases.values()) {
					map_TriggeredCaseRecords.put(objCase.Id, objCase);
				}

				Map<Id, Tax_Notice_Index__c> map_CaseIdWithTNDCRecord = new Map<Id, Tax_Notice_Index__c>();
				Map<String, Set<Id>> map_keyWithRelevantCaseIds = new Map<String, Set<Id>>();

				for (Tax_Notice_Index__c objIndex : map_NewNoticeRelatedCases.keySet()) {
					if (objIndex.RecordTypeId != TAX_NOTICE_INDEX_RECTYPE_MANUAL) {
						Case objCase = map_NewNoticeRelatedCases.get(objIndex);
						objIndex.Case__c = objCase.Id; //OCR 2
						objIndex.Processing_State__c = PROCESSINGSTATE_PROCESSED;
						list_TempTNDC.add(objIndex);
						// Create the 2nd Manual TNDC onwards till nth.
						list_TempTNDC.add(getNewTNDC(objIndex, true));
						map_TNDCRecCaseId.put(objIndex.Id, objCase.Id);

						map_CaseIdWithTNDCRecord.put(objCase.Id, objIndex);

						String strKey; // = objIndex.Agency_Information__c + ''+ objIndex.Client_Name_Text__c + ''+objIndex.Yr_Qtr__c;

						if (objIndex.Agency_Information__c != null && objIndex.ZP_Company_Id__c != null && objIndex.ZP_Company_Id__c != '' && objIndex.Yr_Qtr__c != null && objIndex.Yr_Qtr__c != '') {
							strKey = objIndex.Agency_Information__c + '' + objIndex.ZP_Company_Id__c + '' + objIndex.Yr_Qtr__c; //
						} else if (
							objIndex.Agency_Information__c != null &&
							objIndex.Client_Name_Text__c != null &&
							objIndex.Client_Name_Text__c != '' &&
							objIndex.Yr_Qtr__c != null &&
							objIndex.Yr_Qtr__c != ''
						) {
							strKey = objIndex.Agency_Information__c + '' + objIndex.Client_Name_Text__c + '' + objIndex.Yr_Qtr__c;
						}

						if (!map_keyWithRelevantCaseIds.containsKey(strKey)) {
							map_keyWithRelevantCaseIds.put(strKey, new Set<Id>{ objCase.Id });
						} else {
							map_keyWithRelevantCaseIds.get(strKey).add(objCase.Id);
						}
					} else {
						// when there is no child case needes, the manual TNDC instance is already  created
						objIndex.Processing_State__c = PROCESSINGSTATE_PROCESSED;
						list_TempTNDC.add(objIndex);
					}
				}

				if (list_TempTNDC?.size() > 0) {
					upsert list_TempTNDC;
				}
				List<Tax_Notice_Index__c> list_AllQueriedTNDCRecords = new List<Tax_Notice_Index__c>();

				Set<Id> set_ocrProcessedCaseIds = new Set<Id>();

				if (map_TNDCRecCaseId?.size() > 0) {
					processOCRTNDCAttachments(map_TNDCRecCaseId);
				}

				List<Case> list_ChildCasesToUpdate = new List<Case>();
				Map<Id, List<Case>> map_parentCaseWithChildCases = new Map<Id, List<Case>>();

				Set<Id> set_AllCaseIds = new Set<Id>();
				for (Case objNewChildCase : list_ChildCases) {
					map_CaseRecords.put(objNewChildCase.Id, objNewChildCase);
					set_ChildCaseIds.add(objNewChildCase.Id);
					if (objNewChildCase.ParentId != null) {
						set_ParentCaseIds.add(objNewChildCase.ParentId);
					}
				}

				Map<Id, Case> map_ChildCases = new Map<Id, Case>(
					[
						SELECT
							Id,
							CaseNumber,
							Subject,
							Relevant_Cases__c,
							Related_Case__c,
							Related_Case__r.CaseNumber,
							Related_Case__r.Relevant_Cases__c,
							(SELECT Id, ZP_Company_Id__c, Yr_Qtr__c, Agency_Information__c, Client_Name_Text__c FROM Tax_Notice_Indexs__r WHERE RecordType.DeveloperName = 'Manual_Indexing')
						FROM Case
						WHERE Id IN :map_CaseRecords.keySet() OR Id IN :set_ParentCaseIds
					]
				);
				Map<String, List<Case>> map_RelevantCases = new Map<String, List<Case>>();

				for (Case objCase : map_ChildCases.values()) {
					if (set_ChildCaseIds.contains(objCase.Id)) {
						objCase.Subject = objCase.Subject.replace('[New_Case_No]', objCase.CaseNumber);
					}
					Tax_Notice_Index__c objIndex = new Tax_Notice_Index__c();
					if (objCase.Tax_Notice_Indexs__r != null && objCase.Tax_Notice_Indexs__r.size() > 0) {
						objIndex = objCase.Tax_Notice_Indexs__r[0];
					}
					if (objIndex.Id != null) {
						String strKey = '';
						if (String.isNotBlank(objIndex.ZP_Company_Id__c)) {
							strKey = objIndex.Agency_Information__c + '' + objIndex.ZP_Company_Id__c + '' + objIndex.Yr_Qtr__c;
						} else if (String.isNotBlank(objIndex.Client_Name_Text__c)) {
							strKey = objIndex.Agency_Information__c + '' + objIndex.Client_Name_Text__c + '' + objIndex.Yr_Qtr__c;
						}
						if (map_RelevantCases != null && map_RelevantCases.containsKey(strKey)) {
							map_RelevantCases.get(strKey).add(objCase);
						} else {
							map_RelevantCases.put(strKey, new List<Case>{ objCase });
						}
					}
				}
				Map<Case, List<Case>> map_caseIdWithRelevantCaseId = new Map<Case, List<Case>>();
				for (String strKey : map_RelevantCases.keyset()) {
					if (map_RelevantCases.get(strKey).size() > 1) {
						Integer intCount = map_RelevantCases.get(strKey).size();
						for (Integer i = 0; i < map_RelevantCases.get(strKey).size(); i++) {
							Case objCaseMain = map_RelevantCases.get(strKey)[i];
							List<Case> list_CaseIds = new List<Case>();
							for (Case objCase : map_RelevantCases.get(strKey)) {
								if (objCase.Id != objCaseMain.Id) {
									list_CaseIds.add(objCase);
								}
							}
							map_caseIdWithRelevantCaseId.put(objCaseMain, list_CaseIds);
						}
					}
				}

				for (Case objMainCase : map_ChildCases.values()) {
					if (set_ChildCaseIds.contains(objMainCase.Id)) {
						objMainCase.Subject = objMainCase.Subject.replace('[New_Case_No]', objMainCase.CaseNumber);
					}
					String strRelevantCases = '';
					if (map_caseIdWithRelevantCaseId.get(objMainCase) != null) {
						for (Case objRelvantCases : map_caseIdWithRelevantCaseId.get(objMainCase)) {
							strRelevantCases =
								strRelevantCases +
								'<a href="' +
								URL.getOrgDomainURL().toExternalForm() +
								'/' +
								objRelvantCases.Id +
								'">' +
								map_ChildCases.get(objRelvantCases.Id).CaseNumber +
								'</a>\n';
						}
					}

					objMainCase.Relevant_Cases__c = strRelevantCases;
					if (objMainCase.Relevant_Cases__c != null && set_ChildCaseIds.contains(objMainCase.Id)) {
						list_ChildCasesToUpdate.add(objMainCase);
					} else {
						if (!map_OCRTriggerdCaseIdWithRelevantCases.containsKey(objMainCase.Id) && !set_ChildCaseIds.contains(objMainCase.Id)) {
							map_OCRTriggerdCaseIdWithRelevantCases.put(objMainCase.Id, strRelevantCases);
						}
					}
				}

				if (list_ChildCasesToUpdate?.size() > 0) {
					Boolean blnPreviousVal = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = true;
					update list_ChildCasesToUpdate;
					CaseTriggerHelper.skipTrigger = blnPreviousVal;
				}

				if (map_CaseRecords?.size() > 0) {
					moveBothSystemSuccessCasesToSpecialist(map_CaseRecords, set_ChildCaseIds);
				}
			}
			return map_OCRTriggerdCaseIdWithRelevantCases;
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'TaxNoticeIndexOCRUtil',
				'saveRecords',
				'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(),
				objException.getStackTraceString()
			);
			return null;
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : retrieve agency information from agency name
	 * @Parm        : strAgencyName - Agency Name
	 * @Return      : Id - Agency SFDC ID
	 **/
	static Id getAgencyId(String strAgencyName) {
		Id idAgency;
		if (map_AllAgencies?.size() > 0 && map_AllAgencies?.containsKey(strAgencyName)) {
			idAgency = map_AllAgencies?.get(strAgencyName)?.Id;
		}

		return idAgency;
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Get Set of strings to ignore from Account search
	 * @Parm        : N/A
	 * @Return      : Set of records.
	 **/
	static Set<String> getStringsToIgnore(String strConfigName) {
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