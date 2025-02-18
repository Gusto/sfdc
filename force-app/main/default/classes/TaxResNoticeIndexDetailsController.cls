/**
 * @name         TaxResNoticeIndexDetailsController
 * @author       Pravesh Rana
 * @date         05/30/2022
 * @description  Used by LWC component "TaxResNoticeIndexDetails"
 * @see          TaxResNoticeIndexDetailsCtrlTest
 **/
public with sharing class TaxResNoticeIndexDetailsController {
	public static Boolean blnIsInactiveAutoSolvePkg = false;
	public static final String QUEUE = 'Queue';
	public static final String FAILED = 'Failed';
	public static final String DUPLICATE_NOTICE = 'Duplicate Notice';
	public static final String DUPLICATE_NOTICE_FALSE_POSITIVE_CHECK = 'Duplicate Notice F/P Check';
	public static final String ERROR_FORMNUMBERVALIDATION = 'Tax Form Number can have only alphanumeric values';
	public static final String ERROR_CLIENTTAXIDVALIDATION = 'Client Tax Id can have only alphanumeric values';
	public static final String INCORRECT_CASE_STATUS = 'This functionality is only available for "Data Capture in Progress" cases.';
	public static final String MISSING_CONTACT_ERROR = 'Contact is not linked with the case.';
	public static final String DUMMY_ACCOUNT_ERROR = 'Case is linked with Dummy Account';
	public static final String DUPLICATE_NOTICE_MAIN_QUERY = 'Duplicate Notice Main Query';
	public static final String DUPLICATE_NOTICE_TNDC_FILTERS = 'Duplicate Notice TNDC Filters';
	public static final String DUPLICATE_NOTICE_FALSE_POSITIVE_FILTERS = 'Duplicate Notice FalsePositiveFilters';
	public static final String DUPLCIATE_NOTICE_CLOSED_CASE_FILTERS = 'Duplicate Notice ClosedCaseFilters';
	public static final String DUPLICATE_NOTICE_INPROGRESS_CASE_FILTERS = 'Duplicate Notice InProgressCaseFilters';
	public static final String DUPLICATE_NOTICE_CASE_QUERY = 'Duplicate Notice Case Query';
	public static final String STR_MAIN = 'Main';
	public static final String STR_FILTER = 'Filter';
	public static final Set<String> set_DNClosedCaseFilters = new Set<String>{ CaseUtils.STATUS_CLOSED, CaseUtils.STATUS_SOLVED };
	public static String strDuplicateNoticeType = '';
	public static final Set<String> set_DNInProgressFilters = new Set<String>{ CaseUtils.CASE_STATUS_READY_FOR_RESEARCH, CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS, CaseUtils.CASE_STATUS_SHELVED };
	public static final Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_TaxResNoticeConfigDetail = TaxResAutoSolveUtil.getTNDCQueryConfigurationRecords();
	public static String SPECIALIST_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Specialist_Queue');
	public static Boolean blnBothSystemSuccess = false;
	public static final String PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED = 'Previously Answered Auto-Solve Fired';
	public static final String PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED_CLOSED = 'Previously Answered Auto-Solve Fired Closed/Solved';
	public static final String PREVIOUSLY_ANSWERED_MAIN_QUERY = 'Previously Answered Main Query';
	public static final String PREVIOUSLY_ANSWERED_CASE_FILTER = 'Previously Answered CaseFilter';
	public static final String PREVIOUSLY_ANSWERED_CASE_QUERY = 'Previously Answered CaseQuery';
	public static final String STR_PREVIOUSLY_ANSWERED = 'Previously Answered';
	public static final String STR_DUPLICATE_NOTICE = 'Duplicate Notice';
	public static final String STR_DUPLICATE_CASE_FILTER = 'Duplicate Case';
	public static final String PICKLIST_VALUE_NO = 'N';
	public static Map<String, Account> map_AccountContactDetails = new Map<String, Account>();
	public static final Set<String> set_BelowToleranceCaseTypes = Test.isRunningTest() ? new Set<String>{'940', '941', '944'} : new Set<String>((TaxResIndexNoticeThresholds__c.getValues(CaseUtils.BELOW_TOLERANCE_CASE_TYPES_CUSTOM_SETTING)?.Value_Text__c)?.split(','));
	public static final Decimal BELOW_TOLERANCE_THRESHOLD = Test.isRunningTest() ? 50 : TaxResIndexNoticeThresholds__c.getValues(CaseUtils.BELOW_TOLERANCE_THRESHOLD_CUSTOM_SETTING)?.Value_Decimal__c;
	public static final Set<String> set_MergeFormNumbers = Test.isRunningTest() ? new Set<String>{'DE6601', 'DE2176'} : new Set<String>((TaxResIndexNoticeThresholds__c.getValues(CaseUtils.MERGE_FORM_NUMBERS_CUSTOM_SETTING)?.Value_Text__c)?.split(','));
	public static final String DE6601_DE2176_MERGE = 'DE6601/DE2176 Merge';
	public static final Set<String> set_PILateDepositFormNumbers = Test.isRunningTest() ? new Set<String>{'CP161', 'CP171'} : new Set<String>((TaxResIndexNoticeThresholds__c.getValues(CaseUtils.PI_LATE_DEPOSIT_FORM_NUMBERS_CUSTOM_SETTING)?.Value_Text__c)?.split(','));
	public static final Set<String> set_PILateDepositCaseTypes = Test.isRunningTest() ? new Set<String>{'940', '941', '944'} : new Set<String>((TaxResIndexNoticeThresholds__c.getValues(CaseUtils.PI_LATE_DEPOSIT_CASE_TYPES_CUSTOM_SETTING)?.Value_Text__c)?.split(','));
	public static final String PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED = 'P&I Late Deposit/Amendment Partial Auto-Solve Fired';
	public static final String PI_LATE_DEPOSIT_AUTOSOLVE_FIRED = 'P&I Late Deposit/Amendment Auto-Solve Fired';

	public static final Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_TaxResPlayModeConfigQuery = new Map<String, Tax_Res_Play_Mode_Configuration__mdt>{
		DUPLICATE_NOTICE_FALSE_POSITIVE_FILTERS +
		'-' +
		STR_MAIN => map_TaxResNoticeConfigDetail?.get(DUPLICATE_NOTICE_MAIN_QUERY),
		DUPLCIATE_NOTICE_CLOSED_CASE_FILTERS +
		'-' +
		STR_MAIN => map_TaxResNoticeConfigDetail?.get(DUPLICATE_NOTICE_MAIN_QUERY),
		DUPLICATE_NOTICE_INPROGRESS_CASE_FILTERS +
		'-' +
		STR_MAIN => map_TaxResNoticeConfigDetail?.get(DUPLICATE_NOTICE_MAIN_QUERY),
		PREVIOUSLY_ANSWERED_CASE_FILTER +
		'-' +
		STR_MAIN => map_TaxResNoticeConfigDetail?.get(PREVIOUSLY_ANSWERED_MAIN_QUERY),
		DUPLICATE_NOTICE_FALSE_POSITIVE_FILTERS +
		'-' +
		STR_FILTER => map_TaxResNoticeConfigDetail?.get(DUPLICATE_NOTICE_FALSE_POSITIVE_FILTERS),
		DUPLCIATE_NOTICE_CLOSED_CASE_FILTERS +
		'-' +
		STR_FILTER => map_TaxResNoticeConfigDetail?.get(DUPLCIATE_NOTICE_CLOSED_CASE_FILTERS),
		DUPLICATE_NOTICE_INPROGRESS_CASE_FILTERS +
		'-' +
		STR_FILTER => map_TaxResNoticeConfigDetail?.get(DUPLICATE_NOTICE_INPROGRESS_CASE_FILTERS),
		PREVIOUSLY_ANSWERED_CASE_FILTER +
		'-' +
		STR_FILTER => map_TaxResNoticeConfigDetail?.get(PREVIOUSLY_ANSWERED_CASE_FILTER),
		STR_DUPLICATE_CASE_FILTER +
		'-' +
		STR_MAIN => map_TaxResNoticeConfigDetail?.get(DUPLICATE_NOTICE_CASE_QUERY),
		STR_DUPLICATE_CASE_FILTER +
		'-' +
		STR_FILTER => new Tax_Res_Play_Mode_Configuration__mdt(),
		PREVIOUSLY_ANSWERED_CASE_QUERY +
		'-' +
		STR_MAIN => map_TaxResNoticeConfigDetail?.get(PREVIOUSLY_ANSWERED_CASE_QUERY),
		PREVIOUSLY_ANSWERED_CASE_QUERY +
		'-' +
		STR_FILTER => new Tax_Res_Play_Mode_Configuration__mdt()
	};

	/*
	 * @author:         Pravesh Rana
	 * @description:    return record of Case object based on parameter Id
	 * @param:          strCaseId [Case record Id]
	 * @return:			Instance of Case
	 */
	@AuraEnabled
	public static Case getCaseDetails(String strCaseId) {
		try {
			if (String.isBlank(strCaseId)) {
				return null;
			}

			return [
				SELECT
					Id,
					Status,
					Owner.Name,
					CreatedDate,
					LastModifiedDate,
					Account.RecordType.Name,
					Agency_Information__c,
					Agency_Information__r.SUI_Rate_Form_Numbers__c,
					AccountId,
					Account.Tier__c,
					Account.Partner_Segment__c,
					Account.AM_Tier__c,
					Related_Company__c,
					Physical_Mail__c,
					Origin,
					Mass_Email_Step__c,
					(
						SELECT
							Id,
							Agency_Information__c,
							Agency_Information__r.SUI_Rate_Form_Numbers__c,
                        	Agency_Information__r.OCR_Enabled__c,
							Client_Name__c,
							Tier__c,
							Segment__c,
							SUI_ER_Rate__c,
							Yr_Qtr__c,
							Client_Name__r.RecordType.Name,
							Partner_Tier__c,
							No_Notice_Attached__c,
							Tax_Notice_Form_Number__c,
							SUI_Rate_Effective_Date__c,
							Gusto_is_addressee_of_record__c,
							Tax_Notice_Due_Date__c,
							RAF_Indicator__c,
							Late_Deposit_Amount__c,
							Tax_Notice_Type__c,
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
							MRR_Reason__c,
							Manual_Review_Required__c,
							Bypass_Manual_Validation__c
						FROM Tax_Notice_Indexs__r
						WHERE RecordType.Name = 'Manual Indexing'
					)
				FROM Case
				WHERE Id = :strCaseId
			];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    return "Sui Rate Auto Solve" eligible form numbers
	 * @param:          N/A
	 * @return:			Semi Colon separated form numbers
	 */
	@AuraEnabled
	public static String getSuiRateFormNumbers(String strAgencyId) {
		String strEligibleFormNumbers = '';
		try {
			List<Agency_Information__c> list_agencyInformation = [SELECT Id, SUI_Rate_Form_Numbers__c FROM Agency_Information__c WHERE Id = :strAgencyId];
			if (list_agencyInformation != null && list_agencyInformation.size() > 0) {
				strEligibleFormNumbers = list_agencyInformation[0].SUI_Rate_Form_Numbers__c;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}

		return strEligibleFormNumbers;
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    return record of Account object based on parameter Id
	 * @param:          strAccountId [Account record Id]
	 * @return:			Instance of Account
	 */
	@AuraEnabled
	public static Account getAccountDetails(String strAccountId) {
		try {
			if (String.isBlank(strAccountId)) {
				return null;
			}

			return [SELECT Id, Tier__c, AM_Tier__c, RecordType.Name FROM Account WHERE Id = :strAccountId];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    return comma separated field api names
	 * @param:          N/A
	 * @return:			comma separated field api names
	 */
	@AuraEnabled
	public static String getRequiredFields() {
		try {
			String strFieldsAPINames = '';
			for (Schema.FieldSetMember objField : SObjectType.Tax_Notice_Index__c.FieldSets.Notice_Index_Required_Fields.getFields()) {
				strFieldsAPINames += objField.getFieldPath() + ',';
			}

			return strFieldsAPINames;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    updated case status, owner based on parameter
	 * @param:          strCaseId [Case record Id]
	 * @return:			case record id
	 */
	@AuraEnabled
	public static List<Case> completeNoticeIndexRecord(list<Id> list_CaseRecordId) {
		List<Case> list_CaseToUpate = new List<Case>();
		Set<Id> set_CaseIdForAuditLogs = new Set<Id>();
		Map<Id, Case> map_CaseRecords = new Map<Id, Case>();
		Set<String> set_TNDCCompanyId = new Set<String>();
		Map<String, ZP_Company_Suspension__c> map_CompanyIdToZPCompanySuspension = new Map<String, ZP_Company_Suspension__c>();

		if (list_CaseRecordId == null || list_CaseRecordId?.size() == 0) {
			return null;
		}

		for (Case objCase : getCasesWithTNDC(list_CaseRecordId)) {
			if (objCase.Tax_Notice_Indexs__r.isEmpty()) {
				continue;
			}
			map_CaseRecords.put(objCase.Id, objCase);
			Tax_Notice_Index__c objTaxNoticIndex = objCase.Tax_Notice_Indexs__r[0];
			String strZPCompanyId = objTaxNoticIndex?.Client_Name__r.ZP_Company_ID__c;
			if (String.isNotBlank(strZPCompanyId)) {
				set_TNDCCompanyId.add(strZPCompanyId);
			}
		}

		if (set_TNDCCompanyId?.size() > 0) {
			for (ZP_Company_Suspension__c objZPCompanySuspension : [
				SELECT Id, Last_Active_Day__c, Unsuspended_At__c, Company_Id__c
				FROM ZP_Company_Suspension__c
				WHERE Company_Id__c IN :set_TNDCCompanyId AND Deleted_At__c = NULL
				ORDER BY CreatedDate DESC
			]) {
				map_CompanyIdToZPCompanySuspension.put(objZPCompanySuspension.Company_Id__c, objZPCompanySuspension);
			}
			getAccountDetails(set_TNDCCompanyId);
		}

		if (map_CaseRecords?.size() > 0) {
			for (Id idCase : map_CaseRecords.keySet()) {
				Boolean blnIsAutoSolved = false;
				//Get Notice period for before gusto
				Date dtNPLastDate_Before = null;
				Date dtNPFirstDate_Before = null;

				//Get Notice period for after gusto
				Date dtNPLastDate_After = null;
				Date dtNPFirstDate_After = null;

				//For before gusto
				Date dtJoinedDate = null;
				//For After gusto
				Date dtLastActiveDate = null;
				Date dtUnsuspendedDate = null;
				Date dtFixedUnsuspendedDate = Date.newInstance(3000, 1, 1);
				Case objCaseRecord = map_CaseRecords.get(idCase);

				Boolean blnCaseReasonIsSuiRate = (objCaseRecord.Routing_Case_Reason_Classification__c != null && objCaseRecord.Routing_Case_Reason_Classification__r.Name == 'SUI Rate') ? true : false;
				Boolean blnIsOCREnabledAgency = objCaseRecord.Agency_Information__r.OCR_Enabled__c;
				Boolean blnIsAutosolveEnabledAgency = objCaseRecord.Agency_Information__r.AutoSolve_Enabled__c;
				Boolean blnSendToIndexer = false;

				//Shyam:Added to check 'Gusto is addressee of record'
				Boolean blnGustoIsAddresseeOfRecord = (objCaseRecord.Physical_Mail__c || objCaseRecord.Tax_Notice_Indexs__r[0].Gusto_is_addressee_of_record__c);

				Boolean blnOCRManualValidationBypassed = false;
				Boolean blnValidationError = false;
				//Shyam: added to check autosolve enabled
				if (objCaseRecord.Agency_Information__r.AutoSolve_Enabled__c) {
					blnOCRManualValidationBypassed = true;
				}

				Case objCase = new Case(Id = idCase);
				ZP_Company_Suspension__c objZPCompanySus = null;
				if (objCaseRecord != null && objCaseRecord.Tax_Notice_Indexs__r?.size() > 0) {
					Tax_Notice_Index__c objTaxNotice = objCaseRecord.Tax_Notice_Indexs__r[0];
					Boolean blnIsFinalTaxNoticeNumeration = (objTaxNotice.Tax_Notice_Numeration__c == CaseUtils.TAX_NOTICE_NUMERATION_FINAL);
					//For After Gusto
					String strZPCompanyId = objCaseRecord.Tax_Notice_Indexs__r[0].Client_Name__r.ZP_Company_ID__c;
					if (String.isNotBlank(strZPCompanyId)) {
						if (map_CompanyIdToZPCompanySuspension?.size() > 0 && map_CompanyIdToZPCompanySuspension.containsKey(strZPCompanyId)) {
							objZPCompanySus = map_CompanyIdToZPCompanySuspension.get(strZPCompanyId);
							if (objZPCompanySus.Last_Active_Day__c != null) {
								dtLastActiveDate = objZPCompanySus.Last_Active_Day__c;
							}

							if (objZPCompanySus.Unsuspended_At__c != null) {
								dtUnsuspendedDate = objZPCompanySus.Unsuspended_At__c;
							}
						}
					}

					if (objCaseRecord.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE && objCaseRecord.AccountId != objTaxNotice.Client_Name__c) {
						objCase.AccountId = objTaxNotice.Client_Name__c;

						if (map_AccountContactDetails?.size() > 0 && map_AccountContactDetails.containsKey(strZPCompanyId) && 
							map_AccountContactDetails.get(strZPCompanyId).Contacts?.size() > 0) {
							objCase.ContactId = map_AccountContactDetails.get(strZPCompanyId).Contacts[0].Id;
						}
					}

					//Validation Logics
					if (!blnBothSystemSuccess && objCaseRecord.Status != CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS && objCaseRecord.Status != CaseUtils.STATUS_CLOSED) {
						if (blnOCRManualValidationBypassed) {
							objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
							objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
							objCase.Automation_Message_Follow_Up__c = INCORRECT_CASE_STATUS;
							blnValidationError = true;
						} else {
							throw new AuraHandledException(INCORRECT_CASE_STATUS);
						}
					}

					if (objTaxNotice.Client_Name__c == Label.FBED_Dummy_Account) {
						if (blnOCRManualValidationBypassed && blnBothSystemSuccess) {
							objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
							objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
							objCase.Automation_Message_Follow_Up__c = DUMMY_ACCOUNT_ERROR;
							blnValidationError = true;
						} else {
							throw new AuraHandledException(DUMMY_ACCOUNT_ERROR);
						}
					}

					if (objCaseRecord.ContactId == null && objCaseRecord.Origin != CaseUtils.ORIGIN_ELECTRONIC_NOTICE) {
						if (blnOCRManualValidationBypassed && blnBothSystemSuccess) {
							objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
							objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
							objCase.Automation_Message_Follow_Up__c = MISSING_CONTACT_ERROR;
							blnValidationError = true;
						} else {
							throw new AuraHandledException(MISSING_CONTACT_ERROR);
						}
					}

					if (objCase.ContactId == null && objCaseRecord.ContactId == null && objCaseRecord.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE) {
						if (blnOCRManualValidationBypassed && blnBothSystemSuccess) {
							objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
							objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
							objCase.Automation_Message_Follow_Up__c = MISSING_CONTACT_ERROR;
							blnValidationError = true;
						} else {
							throw new AuraHandledException(MISSING_CONTACT_ERROR);
						}
					}

					// Validate if Client Tax Id is alphanumeric
					String strClientId = objCaseRecord?.Tax_Notice_Indexs__r[0]?.Assigned_Client_Tax_ID_Agency_Assigned__c;
					strClientId = strClientId?.toUpperCase();
					if (String.isNotBlank(strClientId) && !strClientId?.isAlphanumeric()) {
						if (blnOCRManualValidationBypassed) {
							objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
							objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
							objCase.Automation_Message_Follow_Up__c = ERROR_CLIENTTAXIDVALIDATION;
							blnValidationError = true;
						} else {
							throw new AuraHandledException(ERROR_CLIENTTAXIDVALIDATION);
						}
					}

					// Duplicate Notices Auto Solve
					strDuplicateNoticeType = '';
					if (!blnValidationError) {
						Boolean blnContinue = true;

						// Duplicate Notice - Auto Solve
						Case objDuplicateNoticeCase = retrieveDuplicateNoticeCase(objCaseRecord);
						if (objDuplicateNoticeCase?.Id != null && !objCaseRecord?.Tax_Notice_Indexs__r[0]?.No_Notice_Attached__c) {
							if (strDuplicateNoticeType == DUPLICATE_NOTICE_FALSE_POSITIVE_CHECK) {
								if (
									objDuplicateNoticeCase.Tax_Notice_Indexs__r != null &&
									objDuplicateNoticeCase.Tax_Notice_Indexs__r.size() > 0 &&
									objDuplicateNoticeCase.Tax_Notice_Indexs__r[0].RAF_Indicator__c == 'Y'
								) {
									blnIsAutoSolved = true;
									TaxResAutoSolveUtil.handleFieldSync(
										objDuplicateNoticeCase,
										objCase,
										populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.DUPLICATE_NOTICE_CLOSED_CASE_AUTO_SOLVE_PACKAGE)
									);
								} else {
									blnIsAutoSolved = false;
									objCase.Mass_Email_Step__c = DUPLICATE_NOTICE_FALSE_POSITIVE_CHECK;
									objCase.Automation_Status__c = FAILED;
									objCase.Related_Case__c = objDuplicateNoticeCase?.Id;
								}
							} else if (strDuplicateNoticeType == TaxResAutoSolveUtil.DUPLICATE_NOTICE_CLOSED_CASE_AUTO_SOLVE_PACKAGE && !blnIsFinalTaxNoticeNumeration) {
								blnIsAutoSolved = true;
								TaxResAutoSolveUtil.handleFieldSync(
									objDuplicateNoticeCase,
									objCase,
									populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.DUPLICATE_NOTICE_CLOSED_CASE_AUTO_SOLVE_PACKAGE)
								);
							} else if (strDuplicateNoticeType == TaxResAutoSolveUtil.DUPLICATE_NOTICE_INPROGRESS_CASE_AUTO_SOLVE_PACKAGE) {
								blnIsAutoSolved = true;
								TaxResAutoSolveUtil.handleFieldSync(
									objDuplicateNoticeCase,
									objCase,
									populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.DUPLICATE_NOTICE_INPROGRESS_CASE_AUTO_SOLVE_PACKAGE)
								);
							}
							blnContinue = false;
						}

						if (blnContinue) {
							if (objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c != null) {
								if (objCaseRecord.Tax_Notice_Indexs__r[0].Client_Name__r?.Joined_Date_Panda__c != null) {
									dtJoinedDate = objCaseRecord.Tax_Notice_Indexs__r[0].Client_Name__r?.Joined_Date_Panda__c;
								}
								//Before Gusto
								dtNPFirstDate_Before = getQuarterMonthLastDate(objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c, true)[0];
								dtNPLastDate_Before = getQuarterMonthLastDate(objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c, true)[1];

								//After Gusto
								dtNPFirstDate_After = getQuarterMonthLastDate(objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c, false)[0];
								dtNPLastDate_After = getQuarterMonthLastDate(objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c, false)[1];
							}

							// No Notice Attached Auto-Solve
							if (objCaseRecord.Tax_Notice_Indexs__r[0].No_Notice_Attached__c) {
								if (!objCaseRecord.Tax_Notice_Indexs__r[0].Manually_Indexed__c) {
									blnSendToIndexer = true;
								} else if (
									!blnIsOCREnabledAgency ||
									(blnIsOCREnabledAgency && !blnIsAutosolveEnabledAgency) ||
									(blnIsOCREnabledAgency &&
									blnIsAutosolveEnabledAgency &&
									!blnCaseReasonIsSuiRate &&
									objCaseRecord.Origin != CaseUtils.ORIGIN_ELECTRONIC_NOTICE) ||
									(objCaseRecord.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE && !blnBothSystemSuccess)
								) {
									blnIsAutoSolved = true;
									objCase = TaxResAutoSolveUtil.handleFieldSync(objCaseRecord, objCase, TaxResAutoSolveUtil.NO_NOTICE_AUTO_SOLVE_PACKAGE);
								} else {
									blnSendToIndexer = true;
								}
								blnContinue = false;
							} else if (
								// Before Gusto Auto-Solve
								dtJoinedDate != null &&
								objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c != null &&
								checkPriorToGusto(objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c, dtJoinedDate) &&
								objCaseRecord.Tax_Notice_Indexs__r[0].Multi_Yr_Qtr_Indicator__c != TaxResAutoSolveUtil.INDICATOR_YES &&
								!blnIsFinalTaxNoticeNumeration
							) {
								blnIsAutoSolved = true;
								objCase = TaxResAutoSolveUtil.handleFieldSync(objCaseRecord, objCase, populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.BEFORE_GUSTO_SERVICE));
								blnContinue = false;
							} else if (
								// SUI Rate Auto-Solve
								objCaseRecord.Tax_Notice_Indexs__r[0].Tax_Notice_Form_Number__c != null &&
								objCaseRecord.Tax_Notice_Indexs__r[0].Yr_Qtr__c != null &&
								objCaseRecord.Tax_Notice_Indexs__r[0].SUI_Rate_Effective_Date__c != null &&
								objCaseRecord.Tax_Notice_Indexs__r[0].Multi_Yr_Qtr_Indicator__c != TaxResAutoSolveUtil.INDICATOR_YES &&
								!blnIsFinalTaxNoticeNumeration
							) {
								blnIsAutoSolved = true;
								objCase = TaxResAutoSolveUtil.handleFieldSync(objCaseRecord, objCase, populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.SUI_RATE_AUTO_SOLVE_PACKAGE));
								blnContinue = false;
							} else if (
								// After Gusto Auto-Solve
								dtNPFirstDate_After != null &&
								dtNPLastDate_After != null &&
								dtLastActiveDate != null &&
								dtUnsuspendedDate != null &&
								dtNPFirstDate_After > dtLastActiveDate &&
								dtFixedUnsuspendedDate == dtUnsuspendedDate &&
								objCaseRecord.Tax_Notice_Indexs__r[0].Multi_Yr_Qtr_Indicator__c != TaxResAutoSolveUtil.INDICATOR_YES &&
								!blnIsFinalTaxNoticeNumeration
							) {
								blnIsAutoSolved = true;
								objCase = TaxResAutoSolveUtil.handleFieldSync(objCaseRecord, objCase, populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.AFTER_GUSTO_SERVICE));
								blnContinue = false;
							} else if (set_MergeFormNumbers.contains(objTaxNotice.Tax_Notice_Form_Number__c) && objTaxNotice.Agency_Information__r.Name == CaseUtils.AGENCY_CAEDD) {
								//DE6601/DE2176 Merge
								List<Tax_Notice_Index__c> list_TaxNoticeWithOldCase = getTNDCWithOldestOpenCase(objTaxNotice);
								if (list_TaxNoticeWithOldCase != null && !list_TaxNoticeWithOldCase.isEmpty()) {
									blnIsAutoSolved = true;
									objCase.Mass_Email_Step__c = DE6601_DE2176_MERGE;
									objCase.Automation_Status__c = CaseUtils.STATUS_COMPLETED;
									objCase.Related_Case__c = list_TaxNoticeWithOldCase[0]?.Case__c;
									objCase.Status = CaseUtils.STATUS_CLOSED;
								}
								blnContinue = false;
							} else if (
								//Below Tolerance Autosolve
								objTaxNotice.Tax_Notice_Amount_Total__c <= BELOW_TOLERANCE_THRESHOLD &&
								objTaxNotice.Tax_Notice_Amount_Total__c > CaseUtils.TAX_NOTICE_AMOUNT_TOTAL_DEFAULT &&
								objTaxNotice.Tax_Notice_Tax_Amount__c == CaseUtils.TAX_NOTICE_TAX_AMOUNT_DEFAULT &&
								set_BelowToleranceCaseTypes.contains(objTaxNotice.Tax_Notice_Type__c) &&
								objTaxNotice.Multi_Yr_Qtr_Indicator__c == CaseUtils.TAX_NOTICE_MULTI_YR_QTR_DEFAULT &&
								objTaxNotice.Tax_Notice_Numeration__c != CaseUtils.TAX_NOTICE_NUMERATION_FINAL &&
								objTaxNotice.Agency_Information__c == CaseUtils.IRS_AGENCY_ID_DEFAULT
							) {
								blnIsAutoSolved = true;
								TaxResAutoSolveUtil.handleFieldSync(objCaseRecord, objCase, populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.BELOW_TOLERANCE_AUTO_SOLVE_PACKAGE));
								blnContinue = false;
							} else if (
								//P&I Late Deposit/Amendment Autosolve
								objTaxNotice.Agency_Information__c == CaseUtils.IRS_AGENCY_ID_DEFAULT &&
								set_PILateDepositFormNumbers.contains(objTaxNotice.Tax_Notice_Form_Number__c) &&
								set_PILateDepositCaseTypes.contains(objTaxNotice.Tax_Notice_Type__c) &&
								objTaxNotice.Tax_Notice_Tax_Amount__c == CaseUtils.TAX_NOTICE_TAX_AMOUNT_DEFAULT &&
								(objTaxNotice.Penalty_Amount_Due__c != CaseUtils.TAX_NOTICE_TAX_AMOUNT_DEFAULT || objTaxNotice.Interest_Amount_Due__c != CaseUtils.TAX_NOTICE_TAX_AMOUNT_DEFAULT) &&
								objTaxNotice.Multi_YR_QTR_Indicator__c == CaseUtils.TAX_NOTICE_MULTI_YR_QTR_DEFAULT &&
								objTaxNotice.Tax_Notice_Numeration__c != CaseUtils.TAX_NOTICE_NUMERATION_FINAL
							) {
								objCase.Mass_Email_Step__c = PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED;
								blnContinue = false;
							}
						}

						//Shyam: BPO-1622 Previously Answered Autosolve Sequence Reordering
						// Previously Answered - Auto Solve
						if (blnContinue && objTaxNotice.Multi_Yr_Qtr_Indicator__c == PICKLIST_VALUE_NO) {
							Case objPrevAnsweredCase = null;
							String strAutoSolvePackageName = '';
							Map<String, Case> map_previouslyAnsweredCases = retrievePreviouslyAnsweredCase(objCaseRecord);

							Decimal decTaxIncrease = 0.00;
							Double decTaxNoticeAmoutTotalFifteenPercentValue = 0.00;

							// In Progress Case
							objPrevAnsweredCase = map_previouslyAnsweredCases?.get('InProgress');
							if (objPrevAnsweredCase != null && !blnIsFinalTaxNoticeNumeration) {
								if (objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c != null) {
									decTaxNoticeAmoutTotalFifteenPercentValue = objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c * 0.15;
									if(decTaxNoticeAmoutTotalFifteenPercentValue < 0) {
										decTaxNoticeAmoutTotalFifteenPercentValue = decTaxNoticeAmoutTotalFifteenPercentValue * (-1);
									}
									decTaxIncrease = objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c + decTaxNoticeAmoutTotalFifteenPercentValue;
								}

								if (
									objTaxNotice.Tax_Notice_Amount_Total__c >= objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c &&
									objTaxNotice.Tax_Notice_Amount_Total__c <= decTaxIncrease
								) {
									strAutoSolvePackageName = populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.PREVIOUSLY_ANSWERED_IN_PROGRESS_PACKAGE);
								}
							} else {
								// Closed Case
								objPrevAnsweredCase = map_previouslyAnsweredCases?.get('Closed');
								if (objPrevAnsweredCase != null) {
									if (objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c != null) {
										decTaxNoticeAmoutTotalFifteenPercentValue = objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c * 0.15; //Updated from 10% to 15%
										if(decTaxNoticeAmoutTotalFifteenPercentValue < 0) {
											decTaxNoticeAmoutTotalFifteenPercentValue = decTaxNoticeAmoutTotalFifteenPercentValue * (-1);
										}
										decTaxIncrease = objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c + decTaxNoticeAmoutTotalFifteenPercentValue;
									}

									Integer intDaysBetweenTaxNotices = 0;
									if (objTaxNotice.Tax_Notice_Date__c != null && objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Date__c != null) {
										intDaysBetweenTaxNotices = objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Date__c.daysBetween(objTaxNotice.Tax_Notice_Date__c);
									}

									Integer intDaysBetweenSolvedIndexed = 0;
									if (objPrevAnsweredCase.Solved_Closed_Date_Time__c != null) {
										intDaysBetweenSolvedIndexed = objPrevAnsweredCase.Solved_Closed_Date_Time__c.date().daysBetween(Date.Today());
									}

									if (
										objTaxNotice.Tax_Notice_Numeration__c != 'Final' &&
										objTaxNotice.Tax_Notice_Amount_Total__c >= objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c &&
										objTaxNotice.Tax_Notice_Amount_Total__c <= decTaxIncrease &&
										intDaysBetweenTaxNotices >= 0 &&
										intDaysBetweenTaxNotices <= 60 && //updated from 31 to 60 days
										intDaysBetweenSolvedIndexed >= 0 &&
										intDaysBetweenSolvedIndexed <= 45 //updated from 31 to 45 days
									) {
										strAutoSolvePackageName = populateAutoSolvePackageDetails(objCaseRecord, TaxResAutoSolveUtil.PREVIOUSLY_ANSWERED_CLOSED_PACKAGE);
									}
								}
							}

							if (objPrevAnsweredCase != null && String.isNotBlank(strAutoSolvePackageName)) {
								blnIsAutoSolved = true;
								objPrevAnsweredCase.Notice_Period__c = objPrevAnsweredCase?.Tax_Notice_Indexs__r[0]?.Yr_Qtr__c;
								TaxResAutoSolveUtil.handleFieldSync(objPrevAnsweredCase, objCase, strAutoSolvePackageName);
								if (strAutoSolvePackageName.contains(TaxResAutoSolveUtil.PREVIOUSLY_ANSWERED_CLOSED_PACKAGE)) {
									objCase.Mass_Email_Step__c = PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED_CLOSED;
								} else {
									objCase.Mass_Email_Step__c = PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED;
								}
								objCase.Related_Case__c = objPrevAnsweredCase.Id;
								objCase.Customer_Journey__c = objPrevAnsweredCase.Customer_Journey__c;
								objCase.Root_Cause__c = objPrevAnsweredCase.Root_Cause__c;
								objCase.Sub_Root_Cause__c = objPrevAnsweredCase.Sub_Root_Cause__c;
								objCase.Auto_Response_Email_Content__c = objCase?.Auto_Response_Email_Content__c?.replace('[CASE_NUMBER]', objPrevAnsweredCase.CaseNumber);
								blnContinue = false;
							}
						}
					}

					objCase = processCaseForRouting(new List<Case>{ objCaseRecord }, objCase);
					if ((!blnIsAutoSolved || blnIsInactiveAutoSolvePkg) && !blnValidationError && !blnSendToIndexer) {
						objCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE;
						objCase.OwnerId = SPECIALIST_QUEUE_ID;
					}

					if (blnSendToIndexer) {
						objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
						objCase.OwnerId = CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID;
					}

					list_CaseToUpate.add(objCase);
					set_CaseIdForAuditLogs.add(objCase.Id);
				}
			}
		}

		try {
			if (list_CaseToUpate?.size() > 0) {
				if (blnBothSystemSuccess) {
					// This will be use case for any case which is OCR'd successfully
					return list_CaseToUpate;
				} else {
					update list_CaseToUpate;
				}

				List<Case> list_TempCases = [SELECT Id, Email_Status__c, Status, RecordTypeId, OwnerId, Account_Specialist__c FROM Case WHERE Id IN :set_CaseIdForAuditLogs];
				CaseTriggerHelper.createTaxResAuditLogs(list_TempCases, CaseUtils.STATUS_CHANGE, false, false);

				return list_CaseToUpate;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}

		return list_CaseToUpate;
	}

	/**
	 * @Author      : Pawan Kumar
	 * @Description : Will Return the duplciate case if exist for same TNDC record
	 * @Parm        : objCase : case on which indexer is working
	 * @Return      : duplciate case if found
	 **/
	public static Map<String, Case> retrievePreviouslyAnsweredCase(Case objNewCase) {
		String strPreviouslyAnsweredMainQuery = prepareTaxResConfigQuery(PREVIOUSLY_ANSWERED_CASE_FILTER);
		String strPreviouslyAnsweredCaseQuery = prepareTaxResConfigQuery(PREVIOUSLY_ANSWERED_CASE_QUERY);
		Map<String, Case> map_prevAnsCases = new Map<String, Case>();
		Set<Id> set_CaseIds = new Set<Id>();

		Tax_Notice_Index__c objTaxNoticeIndex = objNewCase.Tax_Notice_Indexs__r[0];
		String strAgentInfo = objTaxNoticeIndex?.Agency_Information__c;
		String strClientName = objTaxNoticeIndex?.Client_Name__c;
		String strYearQuarter = objTaxNoticeIndex?.Yr_Qtr__c;
		String strNoticeType = objTaxNoticeIndex?.Tax_Notice_Type__c;
		String strCaseId = objNewCase.Id;

		if (String.isNotBlank(strPreviouslyAnsweredMainQuery) && String.isNotBlank(strPreviouslyAnsweredCaseQuery)) {
			for (Tax_Notice_Index__c objNotice : Database.query(strPreviouslyAnsweredMainQuery)) {
				set_CaseIds.add(objNotice.Case__c);
			}

			for (Case objCase : Database.query(strPreviouslyAnsweredCaseQuery)) {
				if (objCase.Status == null) {
					continue;
				}

				if (set_DNInProgressFilters.contains(objCase.Status)) {
					if (!map_prevAnsCases.containsKey('InProgress')) {
						map_prevAnsCases.put('InProgress', objCase);
					}
				} else if (set_DNClosedCaseFilters.contains(objCase.Status)) {
					if (!map_prevAnsCases.containsKey('Closed')) {
						map_prevAnsCases.put('Closed', objCase);
					}
				}
			}
		}

		return map_prevAnsCases;
	}

	/**
	 * @Author      : Elavarasan N
	 * @Description : Will Return the query string based on the taxnotice config type
	 * @Parm        : String : Tax notice config type
	 * @Return      : query string
	 **/
	public static String prepareTaxResConfigQuery(String strConfigType) {
		Tax_Res_Play_Mode_Configuration__mdt objTaxResPlayModeConfigMain = map_TaxResPlayModeConfigQuery?.get(strConfigType + '-' + STR_MAIN);
		Tax_Res_Play_Mode_Configuration__mdt objTaxResPlayModeConfigFilter = map_TaxResPlayModeConfigQuery?.get(strConfigType + '-' + STR_FILTER);
		String strQuery = '';

		if (String.isNotBlank(strConfigType) && objTaxResPlayModeConfigMain != null && objTaxResPlayModeConfigFilter != null) {
			strQuery += objTaxResPlayModeConfigMain.Filter_Value__c + ' ';
			strQuery += (String.isNotBlank(objTaxResPlayModeConfigFilter.Filter_Value__c) ? objTaxResPlayModeConfigFilter.Filter_Value__c : ' ') + ' ';
			strQuery += (String.isNotBlank(objTaxResPlayModeConfigFilter.Order_by_records__c) ? objTaxResPlayModeConfigFilter.Order_by_records__c : ' ') + '';
		}

		return strQuery;
	}

	/*
	 * @author:         Rushi R
	 * @description:    Re-evaluate Skill Patterns on Case based on TNDC
	 * @param:          List of Case IDs
	 * @return:         List of updated cases
	 */
	public static List<Case> reEvaluateSkillPatterns(List<Id> list_caseIds) {
		List<Case> list_CaseToUpate = new List<Case>();

		for (Case objCase : getCasesWithTNDC(list_caseIds)) {
			if (objCase.Tax_Notice_Indexs__r.isEmpty()) {
				continue;
			}

			objCase = processCaseForRouting(new List<Case>{ objCase }, objCase);
			list_CaseToUpate.add(objCase);
		}

		return list_CaseToUpate;
	}

	/**
	 * @Author      : Pawan Kumar
	 * @Description : Will Return the duplciate case if exist for same TNDC record
	 * @Parm        : objCase : case on which indexer is working
	 * @Return      : duplciate case if found
	 **/
	public static Case retrieveDuplicateNoticeCase(Case objCase) {
		Case objParentCase = new Case();
		List<Case> list_Cases = new List<Case>();
		List<Tax_Notice_Index__c> list_TNDCs = new List<Tax_Notice_Index__c>();
		try {
			if (map_TaxResNoticeConfigDetail?.size() > 0) {
				Tax_Notice_Index__c objTaxNoticeIndex = objCase.Tax_Notice_Indexs__r[0];
				String strAgentInfo = objTaxNoticeIndex.Agency_Information__c;
				String strClientName = objTaxNoticeIndex.Client_Name__c;
				String strTaxNoticeFormNumber = objTaxNoticeIndex.Tax_Notice_Form_Number__c;
				Date dtTaxNoticeDate = objTaxNoticeIndex.Tax_Notice_Date__c;
				String strSegment = objTaxNoticeIndex.Segment__c;
				String strTaxNoticeType = objTaxNoticeIndex.Tax_Notice_Type__c;
				String strTier = objTaxNoticeIndex.Tier__c;
				String strYearQuarter = objTaxNoticeIndex.Yr_Qtr__c;
				Decimal decTaxAmount = objTaxNoticeIndex.Tax_Notice_Tax_Amount__c;
				Double dbTaxNoticeAmountTotal = objTaxNoticeIndex.Tax_Notice_Amount_Total__c;
				String strAgencyAssigned = objTaxNoticeIndex.Assigned_Client_Tax_ID_Agency_Assigned__c;
				String strPartnerTier = objTaxNoticeIndex.Partner_Tier__c;
				String strQueryDuplicateFalsePositive = prepareTaxResConfigQuery(DUPLICATE_NOTICE_FALSE_POSITIVE_FILTERS);
				String strQueryDuplicateClosed = prepareTaxResConfigQuery(DUPLCIATE_NOTICE_CLOSED_CASE_FILTERS);
				String strQueryDuplicateInProgress = prepareTaxResConfigQuery(DUPLICATE_NOTICE_INPROGRESS_CASE_FILTERS);
				String strQueryCaseRecord = prepareTaxResConfigQuery(STR_DUPLICATE_CASE_FILTER);
				Id idManualIndexingRecordTypeId = TaxNoticeIndexOCRUtil.TAX_NOTICE_INDEX_RECTYPE_MANUAL;

				if (String.isNotBlank(strQueryDuplicateFalsePositive)) {
					list_TNDCs = Database.query(strQueryDuplicateFalsePositive);

					if (list_TNDCs?.size() > 0) {
						strDuplicateNoticeType = DUPLICATE_NOTICE_FALSE_POSITIVE_CHECK;
					} else if (list_TNDCs?.size() == 0 && String.isNotBlank(strQueryDuplicateClosed)) {
						list_TNDCs = Database.query(strQueryDuplicateClosed);
						strDuplicateNoticeType = TaxResAutoSolveUtil.DUPLICATE_NOTICE_CLOSED_CASE_AUTO_SOLVE_PACKAGE;
						if (list_TNDCs?.size() == 0 && String.isNotBlank(strQueryDuplicateInProgress)) {
							list_TNDCs = Database.query(strQueryDuplicateInProgress);
							strDuplicateNoticeType = TaxResAutoSolveUtil.DUPLICATE_NOTICE_INPROGRESS_CASE_AUTO_SOLVE_PACKAGE;
						}
					}
				}

				if (list_TNDCs?.size() > 0) {
					Id idCaseObj = list_TNDCs[0].Case__c;
					list_Cases = Database.query(strQueryCaseRecord);
				}

				if (list_Cases.size() > 0) {
					objParentCase = list_Cases[0];
				}
			}

			return objParentCase;
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'TaxResNoticeIndexDetailsController',
				'retrieveDuplicateNoticeCase',
				objException.getMessage(),
				objException.getStackTraceString() + '. line number: ' + objException.getLineNumber()
			);
			return null;
		}
	}

	public static Case processCaseForRouting(List<Case> list_cases, Case objCase) {
		String strSkillPatternToStamp = '';
		List<Tax_Form_Number__c> list_TaxFormNumbers = new List<Tax_Form_Number__c>();
		String strDebitCredit = '';
		Decimal decTaxAmountTotal;
		String strThresholdValue = '';
		String strTier = '';
		String strPartnerTier = '';
		String strFormNumberComplexity = '';
		String strFormNumber;
		String strAgencyId = list_cases[0]?.Tax_Notice_Indexs__r[0]?.Agency_Information__c;

		// Validate if Tax Form Number is alphanumeric
		strFormNumber = list_cases[0]?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Form_Number__c;
		strFormNumber = strFormNumber?.toUpperCase();

		if (String.isNotBlank(strFormNumber) && !strFormNumber?.isAlphanumeric()) {
			throw new AuraHandledException(ERROR_FORMNUMBERVALIDATION);
		} else if (String.isNotBlank(strFormNumber) && strFormNumber?.isAlphanumeric()) {
			// Convert to uppercase and assign to tax notice form number
			objCase.Tax_Notice_Form_Number__c = strFormNumber;
			list_TaxFormNumbers = [
				SELECT Id, Form_Number_Complexity__c
				FROM Tax_Form_Number__c
				WHERE Form_Number__c != NULL AND Form_Number__c = :strFormNumber AND Agency_Information__c = :strAgencyId
				LIMIT 1
			];
		}

		if (list_cases[0]?.Tax_Notice_Indexs__r[0]?.Tax_Notice_Amount_Total__c != null) {
			decTaxAmountTotal = Math.abs(list_cases[0].Tax_Notice_Indexs__r[0].Tax_Notice_Amount_Total__c);
		}

		if (list_cases[0].Tax_Notice_Indexs__r[0].Tax_Notice_Amount_Total__c != null) {
			// D = +, C= -, N = 0
			if (list_cases[0].Tax_Notice_Indexs__r[0].Tax_Notice_Amount_Total__c == 0) {
				strDebitCredit = 'N';
			} else if (list_cases[0].Tax_Notice_Indexs__r[0].Tax_Notice_Amount_Total__c < 0) {
				strDebitCredit = 'C';
			} else if (list_cases[0].Tax_Notice_Indexs__r[0].Tax_Notice_Amount_Total__c > 0) {
				strDebitCredit = 'D';
			}

			// 0 = 0, 0-50 = 50,0-1500 = 1500, 0-10000 = 10000,10000+ = 10000+
			if (decTaxAmountTotal == 0) {
				strThresholdValue = '0';
			} else if (decTaxAmountTotal > 0 && decTaxAmountTotal <= 50) {
				strThresholdValue = '50';
			} else if (decTaxAmountTotal > 50 && decTaxAmountTotal <= 1500) {
				strThresholdValue = '1500';
			} else if (decTaxAmountTotal > 1500 && decTaxAmountTotal <= 10000) {
				strThresholdValue = '10000';
			} else if (decTaxAmountTotal > 10000) {
				strThresholdValue = '10000+';
			}
		}

		// Getting the Tier/Partner Tier value from related Account
		if (String.isNotBlank(list_cases[0].Tax_Notice_Indexs__r[0].Client_Name__r.Tier__c)) {
			//Service Tier + Partner Tier as NA
			strTier = list_cases[0].Tax_Notice_Indexs__r[0].Client_Name__r.Tier__c;
			strPartnerTier = 'NA';
		} else if (String.isNotBlank(list_cases[0].Tax_Notice_Indexs__r[0].Client_Name__r.AM_Tier__c)) {
			//Service Tier as NA + Partner Tier
			strTier = 'NA';
			strPartnerTier = list_cases[0].Tax_Notice_Indexs__r[0].Client_Name__r.AM_Tier__c;
		}

		if (list_TaxFormNumbers?.size() > 0) {
			strFormNumberComplexity = list_TaxFormNumbers?.get(0).Form_Number_Complexity__c;
		}

		strSkillPatternToStamp = list_cases[0].Tax_Notice_Indexs__r[0].Agency_Information__r.Agency_Abbreviation__c;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + list_cases[0].Tax_Notice_Indexs__r[0].Agency_Information__r.Agency_Complexity__c;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + list_cases[0].Tax_Notice_Indexs__r[0].Tax_Notice_Type__c;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + strFormNumberComplexity;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + strDebitCredit;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + strThresholdValue;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + strTier;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + strPartnerTier;
		strSkillPatternToStamp = strSkillPatternToStamp + '|' + list_cases[0].Tax_Notice_Indexs__r[0].Multi_Yr_Qtr_Indicator__c;

		if (!list_cases[0].Tax_Notice_Indexs__r[0].No_Notice_Attached__c) {
			objCase.Agency_Information__c = list_cases[0].Tax_Notice_Indexs__r[0].Agency_Information__c;
			objCase.Physical_Mail__c = list_cases[0].Tax_Notice_Indexs__r[0].Gusto_Is_Addressee_Of_Record__c;
			//assign pattern
			objCase.Skill_Pattern__c = strSkillPatternToStamp;
		}

		return objCase;
	}

	public static string getQuarterAndYear(Date dtDateParm) {
		String strFinalVal = '';
		if (dtDateParm != null) {
			Integer intQuarter = Integer.valueOf(Math.ceil(dtDateParm.month() / 3));
			strFinalVal = 'Q' + intQuarter + ' ' + dtDateParm.year();
		}

		return strFinalVal;
	}

	/*
	 * @author:        Anand Singh
	 * @description:    get First and last date of the quarter
	 * @param:          strNP [Case Notice period]
	 * @return:			List of date [First and last date of the quarter/year]
	 */
	public static List<Date> getQuarterMonthLastDate(String strNP, Boolean blnBeforeGusto) {
		List<Date> list_FirstAndLastDates = new List<Date>();
		if (strNP != null) {
			//get last day of the notice period
			Map<Integer, Integer> mapGetLastMonthOfQuarter = new Map<Integer, Integer>{ 1 => 3, 2 => 6, 3 => 9, 4 => 12 };
			Map<Integer, Integer> mapGetStartMonthOfQuarter = new Map<Integer, Integer>{ 1 => 1, 2 => 4, 3 => 7, 4 => 10 };
			Integer intYear = null;
			Integer intLastMonth = null;
			Integer intStartMonth = null;
			Integer intQuarter = null;
			Date dtCurrentDate = Date.Today();
			Date dtLastDate = null;

			if (blnBeforeGusto) {
				strNP = strNP.replace('Monthly', '').Trim();
				if (strNP.indexOf('Q') > -1) {
					strNP = strNP.right(4);
				}
				intYear = Integer.valueof(strNP);
				intLastMonth = 12;
				intStartMonth = 1;
				dtLastDate = Date.newInstance(intYear, intLastMonth, 31);
			} else {
				//In case of Quaterly
				if (strNP.indexOf('Q') > -1) {
					intYear = Integer.valueof(strNP.split(' ')[1]);
					intQuarter = Integer.valueof(strNP.split(' ')[0].replace('Q', ''));
					intLastMonth = mapGetLastMonthOfQuarter.get(intQuarter);
					intStartMonth = mapGetStartMonthOfQuarter.get(intQuarter);
				} else {
					//In Case of yearly
					strNP = strNP.replace('Monthly', '').Trim();
					intYear = Integer.valueof(strNP);
					intLastMonth = 12;
					intStartMonth = 1;
					dtLastDate = Date.newInstance(intYear, intLastMonth, 31);
				}

				if (dtLastDate == null) {
					dtLastDate = Date.newInstance(intYear, intLastMonth, 1).addMonths(1).toStartofMonth().addDays(-1);
				}
			}
			Date dtFirstDate = Date.newInstance(intYear, intStartMonth, 1).toStartofMonth();
			list_FirstAndLastDates.add(dtFirstDate);
			list_FirstAndLastDates.add(dtLastDate);
		}
		return list_FirstAndLastDates;
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    return record of Case object based on parameter Id
	 * @param:          strCaseId [Case record Id]
	 * @return:			Instance of Case
	 */
	@AuraEnabled
	public static List<Tax_Rate__c> getTaxRatesForAgency(String strAgencyId, String strTNDCId) {
		return [
			SELECT Id, ZP_Tax_Rate_Name__c, Name, (SELECT Id, Rate_Decimal__c FROM Tax_Rate_Values__r WHERE Tax_Notice_Index__c = :strTNDCId)
			FROM Tax_Rate__c
			WHERE Agency_Information__c = :strAgencyId
			ORDER BY NAME ASC
		];
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    return record of Case object based on parameter Id
	 * @param:          strCaseId [Case record Id]
	 * @return:			Instance of Case
	 */
	@AuraEnabled
	public static List<Tax_Rate_Values__c> getTaxRatesValuesTNDC(String strTNDCId, String strAgencyId) {
		return [
			SELECT Id, Rate_Decimal__c, Tax_Rate_Type__c
			FROM Tax_Rate_Values__c
			WHERE Tax_Notice_Index__c = :strTNDCId AND Tax_Rate_Type__r.Agency_Information__c = :strAgencyId
			ORDER BY NAME ASC
		];
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    return record of Case object based on parameter Id
	 * @param:          strCaseId [Case record Id]
	 * @return:			Instance of Case
	 */
	@AuraEnabled
	public static void syncTaxRateValuesForTNDC(String strTNDCId, List<String> list_TaxRateValues) {
		if (String.isNotBlank(strTNDCId) && list_TaxRateValues?.size() > 0) {
			//Delete existing Tax rate values
			delete [SELECT Id FROM Tax_Rate_Values__c WHERE Tax_Notice_Index__c = :strTNDCId];
			List<Tax_Rate_Values__c> list_TaxRateValuesTemp = new List<Tax_Rate_Values__c>();
			for (String strTaxRate : list_TaxRateValues) {
				String strTaxRateId = strTaxRate.split('=>')[0];
				String strTaxRateValue = strTaxRate.split('=>')[1];
				if (strTaxRateValue != null && String.isNotBlank(strTaxRateValue)) {
					Tax_Rate_Values__c objTaxRateVal = new Tax_Rate_Values__c();
					objTaxRateVal.Tax_Notice_Index__c = strTNDCId;
					objTaxRateVal.Tax_Rate_Type__c = strTaxRateId;
					objTaxRateVal.Rate_Decimal__c = decimal.valueOf(strTaxRateValue);
					list_TaxRateValuesTemp.add(objTaxRateVal);
				}
			}

			try {
				insert list_TaxRateValuesTemp;
			} catch (Exception objExcep) {
				throw new AuraHandledException(objExcep.getMessage());
			}
		}
	}

	/*
	 * @author:         Rushi R
	 * @description:    Return Case and TNDC records by Ids
	 * @param:          List of Case Ids
	 * @return:         List of Cases with TNDC
	 */
	public static List<Case> getCasesWithTNDC(List<Id> list_caseIds) {
		List<Case> list_Cases = new List<Case>();
		list_Cases = [
			SELECT
				Id,
				Agency_Information__c,
				Agency_Information__r.Name,
				Agency_Information__r.OCR_Enabled__c,
				Agency_Information__r.AutoSolve_Enabled__c,
				Notice_Period__c,
				Status,
				ParentId,
				Related_Case__c,
				Customer_Journey__c,
				Root_Cause__c,
				Sub_Root_Cause__c,
				Mass_Email_Step__c,
				Automation_Message_Follow_Up__c,
				OwnerId,
				ContactId,
				AccountId,
				Account.Name,
				Tax_Notice_Date__c,
				Tax_Notice_Amount_Total__c,
				Tax_Notice_Numeration__c,
				Account.Joined_Date_Panda__c,
				Related_Company__c,
				CaseNumber,
				Solved_Closed_Date_Time__c,
				Auto_Solve_Error_Message__c,
				Multi_YR_QTR_Indicator__c,
				Penalty_amount__c,
				Tax_Notice_Type__c,
				Physical_Mail__c,
				Routing_Case_Reason_Classification__r.Name,
				Origin,
				(
					SELECT
						Id,
						Agency_Information__c,
						Agency_Information__r.Name,
						Agency_Information__r.OCR_Enabled__c,
						Agency_Information__r.AutoSolve_Enabled__c,
						Yr_Qtr__c,
						Tax_Notice_Type__c,
						Tax_Notice_Due_Date__c,
						Tax_Notice_Date__c,
						Tax_Notice_Form_Number__c,
						Tax_Notice_Numeration__c,
						Tax_Notice_Amount_Total__c,
						Multi_Yr_Qtr_Indicator__c,
						Assigned_Client_Tax_ID_Agency_Assigned__c,
						Client_Name__c,
						Client_Name__r.Name,
						Client_Name__r.Joined_Date_Panda__c,
						Client_Name__r.ZP_Company_ID__c,
						Client_Name__r.Tier__c,
						Client_Name__r.AM_Tier__c,
						Notes_Field__c,
						No_Notice_Attached__c,
						SUI_Rate_Effective_Date__c,
						Segment__c,
						Tier__c,
						Partner_Tier__c,
						Tax_Notice_Tax_Amount__c,
						Gusto_is_addressee_of_record__c,
						Agency_Information__r.Agency_Abbreviation__c,
						Agency_Information__r.Agency_Complexity__c,
						RAF_Indicator__c,
						Late_Deposit_Amount__c,
						Penalty_Amount_Due__c,
						Interest_Amount_Due__c,
						Manually_Indexed__c,
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
						Year_Quarter_Conf_Score_Reason__c
					FROM Tax_Notice_Indexs__r
					WHERE RecordType.Name = 'Manual Indexing'
					LIMIT 1
				)
			FROM Case
			WHERE Id IN :list_caseIds
		];

		return list_Cases;
	}

	/*
	 * @author:         Elavarasan N
	 * @description:    Populate the auto solve package details based on FBED/Physical Email/Regular
	 * @param:          Case object record, package name
	 * @return:         String (Package Name)
	 */
	public static String populateAutoSolvePackageDetails(Case objCaseRecord, String strBasicPackageName) {
		String strPackageName;
		Boolean blnGustoIsAddresseeOfRecord = (objCaseRecord.Physical_Mail__c || objCaseRecord.Tax_Notice_Indexs__r[0].Gusto_is_addressee_of_record__c);
		String strPackageNameBED = strBasicPackageName + ' - ' + CaseUtils.ORIGIN_BED;
		String strPackageNamePhysicalEmail = strBasicPackageName + ' - ' + CaseUtils.STRING_PHYSICAL_MAIL;

		if (objCaseRecord.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE) {
			strPackageName = strPackageNameBED;
		} else if (blnGustoIsAddresseeOfRecord) {
			strPackageName = strPackageNamePhysicalEmail;
		} else {
			strPackageName = strBasicPackageName;
		}
		return strPackageName;
	}

	/*
	 * @author:         Pravesh R
	 * @description:    populate ZP_Company_Id and Account map map_AccountContactDetails
	 * @param:          set of ZP_COmpany_Ids
	 * @return:         N/A
	 */
	public static void getAccountDetails(Set<String> set_ZPCompanyIds) {
		map_AccountContactDetails = new Map<String, Account>();

		if (set_ZPCompanyIds?.size() > 0) {
			for (Account objAccount : [
				SELECT Id, ZP_Company_Id__c, Name, (SELECT ID FROM Contacts WHERE ZP_User_Role__c INCLUDES ('Primary Payroll Admin'))
				FROM Account
				WHERE ZP_Company_Id__c IN :set_ZPCompanyIds AND ZP_Company_Id__c != NULL
			]) {
				map_AccountContactDetails.put(objAccount.ZP_Company_Id__c, objAccount);
			}
		}
	}

	/*
		* @author:         Shyam Nasare
		* @description:    To get the Oldest Open Case for DE6601/DE2176 Merge
		* @param:          tax notice index record
		* @return:         List of tax notice index record with case info
	*/
	public static List<Tax_Notice_Index__c> getTNDCWithOldestOpenCase(Tax_Notice_Index__c objNoticeIndex) {
		String strAgencyId = objNoticeIndex.Agency_Information__c;
		String strYrQtr = objNoticeIndex.Yr_Qtr__c;
		String strAgencyAssignedClientId = objNoticeIndex.Assigned_Client_Tax_ID_Agency_Assigned__c;

		return [SELECT Id, Case__c, Assigned_Client_Tax_ID_Agency_Assigned__c
				FROM Tax_Notice_Index__c
				WHERE RecordTypeId = :CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL AND
				Yr_Qtr__c = :strYrQtr AND
				Assigned_Client_Tax_ID_Agency_Assigned__c = :strAgencyAssignedClientId AND
				Tax_Notice_Form_Number__c IN :set_MergeFormNumbers AND
				Case__r.Agency_Information__c = :strAgencyId AND
				Case__r.Status IN :set_DNInProgressFilters
				ORDER BY Case__r.CreatedDate ASC
				LIMIT 1];
	}

	/*
		* @author:         Shyam Nasare
		* @description:    To check the given yr/qtr is prior to gusto
		* @param:          Yr/Qtr, Company Joined Date
		* @return:         true if prior to gusto else false
	*/
	public static Boolean checkPriorToGusto(String strYrQtr, Date dtJoinedDate) {
		Map<Integer, List<Integer>> map_QtrMonths = new Map<Integer, List<Integer>>{
			1 => new List<Integer>{1,2,3},
			2 => new List<Integer>{4,5,6},
			3 => new List<Integer>{7,8,9},
			4 => new List<Integer>{10,11,12}
		};
		Integer intQtr = null;
		Integer intYr = null;
			
		if (strYrQtr != null && dtJoinedDate != null) {
			if (strYrQtr.contains('Q')) {
				strYrQtr = strYrQtr.replace('Q', '');
				intQtr = Integer.valueOf(strYrQtr.split(' ')[0]);
				intYr = Integer.valueOf(strYrQtr.split(' ')[1]);
			} else {
				intYr = Integer.valueOf(strYrQtr.trim());
			}
			
			if (dtJoinedDate.year() > intYr) {
				return true;
			} else if (dtJoinedDate.year() == intYr && intQtr != null) {
				for (Integer i=1; i<=4; i++) {
					if(map_QtrMonths.get(i).contains(dtJoinedDate.month())) {
						if (i > intQtr) {
							return true;
						}
					}
				}
			}
		}
		return false;
	}

	/*
		* @author:         Shyam Nasare
		* @description:    To get the Tax Notice Type for given Agency Information
		* @param:          Agency Information Id
		* @return:         List of Tax Notice types
	*/
	@AuraEnabled
	public static List<String> getTaxNoticeTypes(String strAgencyId) {
		Agency_Information__c objAgency = [SELECT Id, Name, Tax_Notice_Type__c FROM Agency_Information__c WHERE Id = :strAgencyId];
		List<String> list_TaxNoticeTypes = new List<String>();
		if (objAgency.Tax_Notice_Type__c != null) {
			list_TaxNoticeTypes = objAgency.Tax_Notice_Type__c?.split(';');
		}
		return list_TaxNoticeTypes;
	}
}