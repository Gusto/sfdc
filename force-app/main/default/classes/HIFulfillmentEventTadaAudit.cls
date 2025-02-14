/**
 * @name         HIFulfillmentEventTadaAudit
 * @author		 PR
 * @date          June/19/2020
 * @description  This class contains code which handles "HI Fulfillment Event" object records where Event Type = 'tada_audit'.
 * @test class   HIFulfillmentEventTadaAuditTest
 */
public with sharing class HIFulfillmentEventTadaAudit {
	Map<String, Case> map_OpenCases = new Map<String, Case>(); //contains open case info
	public static String TADA_FAILURE = 'Tada Failure';
	public static String TADA_FAILURE_NHE = 'Tada Failure NHE';
	public static String TADA_FAILURE_OE = 'Tada Failure OE';
	public static String UNPROCESSED_OE_SELECTION = 'Unprocessed OE FSA/DCA Selection';
	public static String UNPROCESSED_NHE_SELECTION = 'Unprocessed NHE FSA/DCA Selection';
	public static String HSA_CONTRIBUTION_LIMIT_RECORD_MISSING = 'HSA Contribution Limit Record Missing';
	public static String SUBMISSION_METHOD_CARRIER_PORTAL = 'Carrier Portal';
	public static String SUB_TYPE_HSA = 'HSA';
	public static String ERROR_INFO_DOES_NOT_EXIST = 'Error information does not exist.';
	public static String strEmailDetailsValue = 'EmailDetails';
	public static String strErrorsValue = 'Errors';
	public static String strElectionValue = 'Election';
	public static String strEffectiveDateValue = 'EffectiveDate';
	public static String strFulfillmentSubTypeValue = 'strFulfillmentSubType';

	public static Map<String, MF_Audit_Descriptions__mdt> map_HSAMFAuditDescriptions = HIEnrollmentEventUtility.getMFAuditDescrptions();

	public HIFulfillmentEventTadaAudit() {
	}

	public void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents) {
		CaseTriggerHelper.context = 'FulfillmentEvent';

		Set<String> set_HIFulfillmentEventIds = new Set<String>();
		Set<String> set_AccountZPIds = new Set<String>();
		Set<String> set_EmployeeEmails = new Set<String>();
		Set<String> set_EmployeeIds = new Set<String>();
		Map<String, List<HI_Fulfillment_Event__c>> map_CompanyEmployeeIdKeyEvents = new Map<String, List<HI_Fulfillment_Event__c>>();
		Map<String, HIFulfillmentEnrollmentTadaAuditJSON> map_EventIdsToInfo = new Map<String, HIFulfillmentEnrollmentTadaAuditJSON>();
		Map<String, CaseDataWrapper> map_EventIdsToCaseWrapper = new Map<String, CaseDataWrapper>();
		Set<String> set_EnrollmentIds = new Set<String>();
		Map<String, String> map_KeysToDescription = new Map<String, String>();
		Set<String> set_CarrierKey = new Set<String>();
		Map<String, Carrier__c> map_Carrier = new Map<String, Carrier__c>();
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (HI_Fulfillment_Event__c objHIFulfillEvent : list_HIFulfillmentEvents) {
			if (objHIFulfillEvent.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			objHIFulfillEvent.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfillEvent.Message__c = '';

			if (objHIFulfillEvent.Id__c == null) {
				continue;
			}

			HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed;
			//code to decrypt the Event JSON
			try {
				Blob blobDecryptedKey = EncodingUtil.base64Decode(objHIFulfillEvent.Event_Info_Encrypted__c);
				String strDeCryptedText = EncryptionUtils.getDecryptedText(blobEncryptionKey, blobDecryptedKey);
				objHIEventInfoParsed = getJSONParsedData(strDeCryptedText);
			} catch (Exception objEx) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulfillEvent);
			}

			if (objHIEventInfoParsed == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulfillEvent);
				continue;
			}

			if (String.isBlank(objHIFulfillEvent.Company_Id__c)) {
				if (objHIEventInfoParsed.company == null || objHIEventInfoParsed.company.id == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING, objHIFulfillEvent);
					continue;
				} else {
					objHIFulfillEvent.Company_Id__c = objHIEventInfoParsed.company.id + '';
				}
			}

			if (objHIEventInfoParsed.audit_type != HSA_CONTRIBUTION_LIMIT_RECORD_MISSING) {
				if (objHIEventInfoParsed.company.id == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING, objHIFulfillEvent);
					continue;
				}

				if (objHIEventInfoParsed.employee.email == null || objHIEventInfoParsed.employee.email == '') {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EMAIL_ID_IS_MISSING, objHIFulfillEvent);
					continue;
				}

				set_EmployeeEmails.add(objHIEventInfoParsed.employee.email);
			}

			if (objHIEventInfoParsed.errors == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, ERROR_INFO_DOES_NOT_EXIST, objHIFulfillEvent);
				continue;
			}

			if (String.isNotBlank(objHIFulfillEvent.Id__c)) {
				map_EventIdsToInfo.put(objHIFulfillEvent.Id__c, objHIEventInfoParsed);
				set_HIFulfillmentEventIds.add(objHIFulfillEvent.Id__c);
			}
			if (String.isNotBlank(objHIFulfillEvent.Company_Id__c)) {
				set_AccountZPIds.add(objHIFulfillEvent.Company_Id__c);
			}
			if (String.isNotBlank(objHIFulfillEvent.Employee_Id__c)) {
				set_EmployeeIds.add(objHIFulfillEvent.Employee_Id__c);
			}

			String strType = getType(objHIEventInfoParsed);
			String strEnrollmentId = objHIFulfillEvent.Employee_Id__c + '-' + objHIFulfillEvent.Company_Id__c + '-' + objHIEventInfoParsed.employee_benefits.provider_key + strType;
			set_EnrollmentIds.add(strEnrollmentId);
			set_CarrierKey.add(objHIEventInfoParsed.employee_benefits.provider_key);
		}

		if (set_HIFulfillmentEventIds.isEmpty()) {
			return;
		}

		if (!set_CarrierKey.isEmpty()) {
			map_Carrier = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKey);
		}

		//Loop on HI Fulfillment Event to fetch json related data
		map_CompanyEmployeeIdKeyEvents = getRelatedEventRecords(set_AccountZPIds, set_EmployeeIds, set_HIFulfillmentEventIds);
		for (Case objCase : [
			SELECT Id, Status, Enrollment_key__c, Enrollment_Id__c, Integration_Id__c, Integration_Key__c, createdDate, Tada_Audit_Event_Ids__c
			FROM Case
			WHERE Enrollment_Id__c != NULL AND Enrollment_Id__c IN :set_EnrollmentIds AND (Status = :HIEnrollmentEventUtility.CASE_STATUS_NEW OR Status = :HIEnrollmentEventUtility.CASE_STATUS_DRAFT)
		]) {
			map_OpenCases.put(objCase.Enrollment_Id__c, objCase);
		}

		for (HI_Fulfillment_Event__c objHIFulfillEvent : list_HIFulfillmentEvents) {
			if (!set_HIFulfillmentEventIds.contains(objHIFulfillEvent.Id__c)) {
				continue;
			}

			HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed = map_EventIdsToInfo.get(objHIFulfillEvent.Id__c);

			//populating Dependents data in a seperate map
			Map<String, HIFulfillmentEnrollmentTadaAuditJSON.Dependent> map_Dependents = new Map<String, HIFulfillmentEnrollmentTadaAuditJSON.Dependent>();
			if (objHIEventInfoParsed.dependents != null && objHIEventInfoParsed.dependents.size() > 0) {
				for (HIFulfillmentEnrollmentTadaAuditJSON.Dependent objDependent : objHIEventInfoParsed.dependents) {
					map_Dependents.put('' + objDependent.id, objDependent);
				}
			}

			String strEffectiveDate = (objHIEventInfoParsed.employee_benefits != null
				? HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee_benefits.effective_date)
				: null);
			Date dtEffectiveDate = (strEffectiveDate != null
				? Date.newInstance(Integer.valueOf(strEffectiveDate.split('-')[2]), Integer.valueOf(strEffectiveDate.split('-')[0]), Integer.valueOf(strEffectiveDate.split('-')[1]))
				: null);
			String strFulfillmentSubType;
			if (objHIEventInfoParsed.employee_benefits != null) {
				strFulfillmentSubType = (objHIEventInfoParsed.employee_benefits.benefit_type.equalsIgnoreCase('commuter')
					? 'Commuter'
					: objHIEventInfoParsed.employee_benefits.benefit_type.toUpperCase());
			}
			String strCaseDescription = '';
			String strDependentDetails = '';
			String strType = getType(objHIEventInfoParsed);

			if (map_HSAMFAuditDescriptions.containskey(objHIEventInfoParsed.audit_type) && map_HSAMFAuditDescriptions.get(objHIEventInfoParsed.audit_type).Alegeus_Type__c == SUB_TYPE_HSA) {
				strCaseDescription += setHSACaseDescription(objHIEventInfoParsed);
				map_KeysToDescription = getPreviousDescription(
					objHIFulfillEvent,
					map_CompanyEmployeeIdKeyEvents,
					dtEffectiveDate,
					strType,
					strFulfillmentSubType,
					objHIEventInfoParsed.employee_benefits.provider_key
				);

				if (map_KeysToDescription != null) {
					if (map_KeysToDescription.containsKey(strEmailDetailsValue)) {
						strCaseDescription += map_KeysToDescription.get(strEmailDetailsValue);
					}

					if (map_KeysToDescription.containsKey(strFulfillmentSubTypeValue)) {
						strFulfillmentSubType = map_KeysToDescription.get(strFulfillmentSubTypeValue);
					}
				}
			} else {
				HIFulfillmentEnrollmentTadaAuditJSON.HomeAddress ObjEmployeeHomeAddress = objHIEventInfoParsed.employee.home_address;
				HIFulfillmentEnrollmentTadaAuditJSON.Address ObjCompanyBenefitAddress = objHIEventInfoParsed.company.benefits_address;

				strCaseDescription += '\n- Event Type: ' + Utils.humanize(objHIEventInfoParsed.sub_type);

				String strEmployeeName = HIFulfillmentEventHelperFunctions.getName(
					objHIEventInfoParsed.employee.first_Name,
					objHIEventInfoParsed.employee.last_Name,
					objHIEventInfoParsed.employee.middle_initial
				);
				String strNewCaseDescription = '\n\n' + strEmployeeName + ' of ' + objHIEventInfoParsed.company.name + ' would like to enroll in the following Alegeus plans:';
				strNewCaseDescription += '\n\nLink to Employee\'s Benefits: ' + objHIEventInfoParsed.employee.hippo_url + '/subscriptions';
				strNewCaseDescription += '\n- Hippo URL: ' + objHIEventInfoParsed.employee.hippo_url;

				strCaseDescription = strNewCaseDescription + strCaseDescription;

				// logic to append all the "tada_audit" type events error information together=====STARTS====
				String strErrors = '\n\nErrors';
				String strElection = '\n\n**********Election & Effective Date**********';

				if (objHIEventInfoParsed.errors != null) {
					strErrors += getErrorStr(objHIEventInfoParsed);
				}

				if (objHIEventInfoParsed.employee_benefits != null) {
					strElection += getElectionStr(objHIEventInfoParsed);
				}

				map_KeysToDescription = getPreviousDescription(
					objHIFulfillEvent,
					map_CompanyEmployeeIdKeyEvents,
					dtEffectiveDate,
					strType,
					strFulfillmentSubType,
					objHIEventInfoParsed.employee_benefits.provider_key
				);

				if (String.isNotBlank(strDependentDetails)) {
					strCaseDescription += strDependentDetails;
				}
				String strCarrierName = map_Carrier.get(objHIEventInfoParsed.employee_benefits.provider_key) != null ? map_Carrier.get(objHIEventInfoParsed.employee_benefits.provider_key).Name : '';
				strCaseDescription += '\n\nCarrier: ' + strCarrierName;

				if (map_KeysToDescription != null && map_KeysToDescription.values().size() > 0) {
					if (map_KeysToDescription.containsKey(strEmailDetailsValue)) {
						strCaseDescription += map_KeysToDescription.get(strEmailDetailsValue);
					}

					if (map_KeysToDescription.containsKey(strErrorsValue)) {
						strCaseDescription += map_KeysToDescription.get(strErrorsValue);
					}

					if (map_KeysToDescription.containsKey(strElectionValue)) {
						strCaseDescription += map_KeysToDescription.get(strElectionValue);
					}

					if (map_KeysToDescription.containsKey(strEffectiveDateValue)) {
						String strDateValue = map_KeysToDescription.get(strEffectiveDateValue);
						dtEffectiveDate = Date.valueOf(strDateValue);
					}

					if (map_KeysToDescription.containsKey(strFulfillmentSubTypeValue)) {
						strFulfillmentSubType = map_KeysToDescription.get(strFulfillmentSubTypeValue);
					}
				}
			}

			// logic to append all the "tada_audit" type events error information together=====ENDS====

			caseDataWrapper objCaseWrapper;
			if (objHIEventInfoParsed.audit_type != null && objHIEventInfoParsed.audit_type == HSA_CONTRIBUTION_LIMIT_RECORD_MISSING) {
				objCaseWrapper = new caseDataWrapper(
					objHIFulfillEvent.Id__c,
					objHIEventInfoParsed.employee_benefits.provider_key,
					objHIFulfillEvent.Event_Type__c,
					null,
					'',
					strCaseDescription,
					'',
					dtEffectiveDate,
					'',
					'',
					objHIEventInfoParsed,
					'',
					'',
					'',
					SUB_TYPE_HSA
				);
			} else {
				objCaseWrapper = new caseDataWrapper(
					objHIFulfillEvent.Id__c,
					objHIEventInfoParsed.employee_benefits.provider_key,
					objHIFulfillEvent.Event_Type__c,
					objHIEventInfoParsed.company.id,
					objHIEventInfoParsed.employee.email,
					strCaseDescription,
					'',
					dtEffectiveDate,
					'',
					'',
					objHIEventInfoParsed,
					'',
					'',
					'',
					strFulfillmentSubType
				);
			}

			map_EventIdsToCaseWrapper.put(objHIFulfillEvent.id__c, objCaseWrapper);
		} //for ends

		Map<String, Account> map_Accounts = new Map<String, Account>();
		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		Map<String, Benefit_Order__c> map_BenefitOrders = new Map<String, Benefit_Order__c>();

		map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_AccountZPIds);
		map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmails);
		map_BenefitOrders = HIFulfillmentEventHelperFunctions.getBenefitOrderMap(set_AccountZPIds);

		processContactInformation(list_HIFulfillmentEvents, map_EventIdsToInfo, map_Accounts, map_Contacts);

		map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmails);

		List<Case> list_CasesToUpsert = getCaseInformation(map_EventIdsToCaseWrapper, list_HIFulfillmentEvents, map_EventIdsToInfo, map_Accounts, map_Contacts, map_BenefitOrders, map_Carrier);

		Map<String, String> map_DMLCasesUpsertErrors = new Map<String, String>();
		if (list_CasesToUpsert.size() > 0) {
			List<Database.UpsertResult> list_SaveResults = Database.upsert(list_CasesToUpsert, Case.Fields.Enrollment_Key__c, false);
			map_DMLCasesUpsertErrors = Utils.processUpsertResult(list_SaveResults, list_CasesToUpsert, 'Integration_Id__c', false, 'HIFulfillmentEventSyncFailed-processInformation');
		}

		for (HI_Fulfillment_Event__c objHIFulfillEvent : list_HIFulfillmentEvents) {
			if (objHIFulfillEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulfillEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			if (map_DMLCasesUpsertErrors.containsKey(objHIFulfillEvent.Id__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLCasesUpsertErrors.get(objHIFulfillEvent.Id__c), objHIFulfillEvent);
				continue;
			} else {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, objHIFulfillEvent.Message__c + HIEnrollmentEventUtility.SUCCESS_MESSAGE, objHIFulfillEvent);
			}
		}
	}

	//following method returns Error part of Description String for different related Event records
	public String getErrorStr(HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed) {
		String strErrors = ' ';
		strErrors += '\n- ' + (objHIEventInfoParsed.employee_benefits != null ? objHIEventInfoParsed.employee_benefits.benefit_type.toUpperCase() : '');
		strErrors += ': Error Reason: ' + objHIEventInfoParsed.errors.error_reason;
		return strErrors;
	}

	//following method returns Election part of Description String for different related Event records
	public String getElectionStr(HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed) {
		String strElection = ' ';

		if (objHIEventInfoParsed.employee_benefits.benefit_type == 'hsa') {
			strElection += '\n\n HSA Policy Url: ' + objHIEventInfoParsed.employee_benefits.hippo_url;
			strElection += '\n Effective Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee_benefits.effective_date);
			strElection += '\n Amount: ' + (objHIEventInfoParsed.employee_benefits.election == null ? '0.0' : objHIEventInfoParsed.employee_benefits.election);
		}

		if (objHIEventInfoParsed.employee_benefits.benefit_type == 'dca') {
			strElection += '\n\n DCA Policy Url: ' + objHIEventInfoParsed.employee_benefits.hippo_url;
			strElection += '\n Effective Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee_benefits.effective_date);
			strElection += '\n Amount: ' + (objHIEventInfoParsed.employee_benefits.election == null ? '0.0' : objHIEventInfoParsed.employee_benefits.election);
		}

		if (objHIEventInfoParsed.employee_benefits.benefit_type == 'fsa') {
			strElection += '\n\n FSA Policy Url: ' + objHIEventInfoParsed.employee_benefits.hippo_url;
			strElection += '\n Effective Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee_benefits.effective_date);
			strElection += '\n Amount: ' + (objHIEventInfoParsed.employee_benefits.election == null ? '0.0' : objHIEventInfoParsed.employee_benefits.election);
		}

		if (objHIEventInfoParsed.employee_benefits.benefit_type == 'commuter') {
			strElection += '\n\n Commuter Policy Url: ' + objHIEventInfoParsed.employee_benefits.hippo_url;
			strElection += '\n Effective Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee_benefits.effective_date);
			strElection += '\n Transit Amount: ' + (objHIEventInfoParsed.employee_benefits.transit_monthly_election == null ? '0.0' : objHIEventInfoParsed.employee_benefits.transit_monthly_election);
			strElection += '\n Parking Amount: ' + (objHIEventInfoParsed.employee_benefits.parking_monthly_election == null ? '0.0' : objHIEventInfoParsed.employee_benefits.parking_monthly_election);
		}

		return strElection;
	}

	//this method maps all the related information on the Case fields.
	public List<Case> getCaseInformation(
		Map<String, caseDataWrapper> map_EventIdsToCaseWrapper,
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents,
		Map<String, HIFulfillmentEnrollmentTadaAuditJSON> map_EventIdsToInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Map<String, Benefit_Order__c> map_BenefitOrders,
		Map<String, Carrier__c> map_Carrier
	) {
		List<Case> list_CasesToUpsert = new List<Case>();

		for (HI_Fulfillment_Event__c objHIFulfillEvent : list_HIFulfillmentEvents) {
			HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfo = map_EventIdsToInfo.get(objHIFulfillEvent.Id__c);
			String strCarrierkey = objHIEventInfo.employee_benefits.provider_key;

			Account objAccount = new Account();
			if (objHIEventInfo.company != null && objHIEventInfo.company.id != null && map_Accounts != null && map_Accounts.containsKey('' + objHIEventInfo.company.id)) {
				objAccount = map_Accounts.get('' + objHIEventInfo.company.id);
			}

			Benefit_Order__c objBenefitOrder = new Benefit_Order__c();
			Contact objContact;

			Database.DMLOptions objDMLOption = new Database.DMLOptions();
			objDMLOption.assignmentRuleHeader.useDefaultRule = true;

			Case objCase = new Case();
			String strType = getType(objHIEventInfo);

			if (objHIEventInfo.audit_type != HSA_CONTRIBUTION_LIMIT_RECORD_MISSING) {
				if (map_Contacts.containsKey(String.valueOf(objHIEventInfo.company.id) + '-' + objHIEventInfo.employee.email)) {
					objContact = map_Contacts.get(String.valueOf(objHIEventInfo.company.id) + '-' + objHIEventInfo.employee.email);
				} else if (map_Contacts.containsKey(objHIEventInfo.employee.email)) {
					objContact = map_Contacts.get(objHIEventInfo.employee.email);
				}
				objCase.Enrollment_Id__c = '' + objHIEventInfo.employee.id + '-' + objHIEventInfo.company.id + '-' + strCarrierkey + strType;
			}

			//if open Case with matching EnrollmentId is present we want to update the same case
			if (map_OpenCases.containsKey(objCase.Enrollment_Id__c)) {
				Case objExisitngCase = map_OpenCases.get(objCase.Enrollment_Id__c);
				objCase.Id = objExisitngCase.Id;
				objCase.Enrollment_Key__c = objExisitngCase.Enrollment_key__c;
				objCase.Integration_Id__c = objExisitngCase.Integration_Id__c;
				objCase.Integration_Key__c = objExisitngCase.Integration_Key__c;
				if (objExisitngCase.Tada_Audit_Event_Ids__c != null && !(objExisitngCase.Tada_Audit_Event_Ids__c.IndexOf(objHIFulfillEvent.Id__c) > -1)) {
					objCase.Tada_Audit_Event_Ids__c = objExisitngCase.Tada_Audit_Event_Ids__c + ';' + objHIFulfillEvent.Id__c;
				}
			} else {
				//create New Case is no open case is present in the org for the Enrollment ID
				if (objHIEventInfo.audit_type == HSA_CONTRIBUTION_LIMIT_RECORD_MISSING) {
					objCase.Enrollment_Key__c = strCarrierkey + TADA_FAILURE + objHIFulfillEvent.Id__c;
				} else {
					objCase.Enrollment_Key__c = objHIEventInfo.employee.id + '-' + objHIEventInfo.company.id + '-' + strCarrierkey + TADA_FAILURE + objHIFulfillEvent.Id__c;
				}
				objCase.Integration_Id__c = objHIFulfillEvent.Id__c;
				objCase.Integration_Key__c = objHIFulfillEvent.Id__c + '-' + strCarrierkey;
				objCase.Tada_Audit_Event_Ids__c = objHIFulfillEvent.Id__c;
			}

			if (map_HSAMFAuditDescriptions.containskey(objHIEventInfo.audit_type) && map_HSAMFAuditDescriptions.get(objHIEventInfo.audit_type).Alegeus_Type__c == SUB_TYPE_HSA) {
				objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_AUDIT;
				objCase.Type = strType;
			} else {
				if (map_BenefitOrders.containsKey('' + objHIEventInfo.company.id)) {
					objBenefitOrder = map_BenefitOrders.get('' + objHIEventInfo.company.id);
					objCase.Benefit_Order__c = objBenefitOrder.Id;
					objCase.Special_Instructions__c += 'Benefit Order exists with status ' + objBenefitOrder.Order_Status__c;
				}

				if (objHIEventInfo.Employee.benefits_eligibility_date != null && objHIEventInfo.Employee.benefits_eligibility_date != '') {
					objCase.Benefits_Eligibility_Date__c = Date.valueOf(objHIEventInfo.Employee.benefits_eligibility_date);
				}

				objCase.Anticipated_Effective_Date__c = map_EventIdsToCaseWrapper?.get(objHIFulfillEvent.Id__c).effectiveDate;
				objCase.Subscription_Ids__c = map_EventIdsToCaseWrapper?.get(objHIFulfillEvent.Id__c).subscriptionIds;
				objCase.Type = strType;
				objCase.Submission_Method__c = SUBMISSION_METHOD_CARRIER_PORTAL;
				objCase.Employee_Ids__c = '' + objHIEventInfo.employee.id;
				objCase.Employee_Id__c = '' + objHIEventInfo.employee.id;
				objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE;
				objCase.Opps_Owner__c = HIEnrollmentEventUtility.OPS_OWNER_MEMBER_FULFILLMENT;
			}

			objCase.Description = map_EventIdsToCaseWrapper?.get(objHIFulfillEvent.Id__c).strCaseDescription;

			if (objAccount != null) {
				objCase.AccountId = objAccount.Id;
			}

			if (objContact != null) {
				objCase.ContactId = objContact.Id;
			}
			objCase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(strCarrierkey)) ? map_Carrier.get(strCarrierkey).Id : null;
			objCase.setOptions(objDMLOption);
			objCase.Status = HIEnrollmentEventUtility.CASE_STATUS_NEW;
			objCase.Fulfillment_Sub_Type__c = map_EventIdsToCaseWrapper?.get(objHIFulfillEvent.Id__c).subType;

			list_CasesToUpsert.add(objCase);
		}

		return list_CasesToUpsert;
	}

	//following method checks for all the contacts based on Email and if Contact is missing then we are creating Contact records
	private void processContactInformation(
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents,
		Map<String, HIFulfillmentEnrollmentTadaAuditJSON> map_EventIdsToInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts
	) {
		List<Contact> list_ContactsToInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c objHIFulfillEvent : list_HIFulfillmentEvents) {
			if (objHIFulfillEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulfillEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfo = map_EventIdsToInfo.get(objHIFulfillEvent.Id__c);
			if (objHIEventInfo.audit_type != HSA_CONTRIBUTION_LIMIT_RECORD_MISSING) {
				if (!map_Accounts.containsKey('' + objHIEventInfo.employee.company_id)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objHIFulfillEvent);
					continue;
				}

				if (!map_Contacts.containsKey(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.email) && !map_Contacts.containsKey(objHIEventInfo.employee.email)) {
					Contact objContact = new Contact();
					objContact.AccountId = map_Accounts.get('' + objHIEventInfo.employee.company_id).Id;
					objContact.FirstName = objHIEventInfo.employee.first_Name;
					objContact.LastName = objHIEventInfo.employee.last_name;
					objContact.Email = objHIEventInfo.employee.email;
					objContact.RecordTypeId = HIEnrollmentEventUtility.CONTACT_COMPANY_RT_ID;
					list_ContactsToInsert.add(objContact);
				}
			}
		}

		if (list_ContactsToInsert.size() > 0) {
			Map<String, String> dmlContactInsertErrorsMap = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = Database.insert(list_ContactsToInsert, false);
			dmlContactInsertErrorsMap = Utils.processSaveResult(list_SaveResults, list_ContactsToInsert, 'email', false, 'HIFulfillmentEventSyncFailed-processContactInformation');
			for (HI_Fulfillment_Event__c objHIFulfillEvent : list_HIFulfillmentEvents) {
				HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfo = map_EventIdsToInfo.get(objHIFulfillEvent.Id__c);
				if (dmlContactInsertErrorsMap.containsKey(objHIEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlContactInsertErrorsMap.get(objHIEventInfo.employee.email), objHIFulfillEvent);
					continue;
				}
			}
		}
	}

	//calling HIFulfillmentEnrollmentEventJSON class for parsing data
	public static HIFulfillmentEnrollmentTadaAuditJSON getJSONParsedData(String strJSON) {
		HIFulfillmentEnrollmentTadaAuditJSON objParsedData = (HIFulfillmentEnrollmentTadaAuditJSON) JSON.deserialize(strJSON, HIFulfillmentEnrollmentTadaAuditJSON.class);
		return objParsedData;
	}

	//this method queries related event records based on matching company Id, Employee Id, and of event type = 'tada_audit'
	public Map<String, List<HI_Fulfillment_Event__c>> getRelatedEventRecords(Set<String> set_ZPCompanyIds, Set<String> set_EmployeeIds, Set<String> set_EventIdsToExclude) {
		Map<String, List<HI_Fulfillment_Event__c>> map_CompanyEmpIdsToEventTemp = new Map<String, List<HI_Fulfillment_Event__c>>();

		if (set_ZPCompanyIds != null && set_ZPCompanyIds.size() > 0 && set_EmployeeIds != null && set_EmployeeIds.size() > 0 && set_EventIdsToExclude != null && set_EventIdsToExclude.size() > 0) {
			for (HI_Fulfillment_Event__c objEvent : [
				SELECT Id, Id__c, Company_Id__c, Employee_Id__c, Event_Info_Encrypted__c, createdDate
				FROM HI_Fulfillment_Event__c
				WHERE Company_Id__c IN :set_ZPCompanyIds AND Employee_Id__c IN :set_EmployeeIds AND Id__c NOT IN :set_EventIdsToExclude AND Event_Type__c = 'tada_audit'
			]) {
				String strKey = objEvent.Company_Id__c + objEvent.Employee_Id__c;
				List<HI_Fulfillment_Event__c> list_TempEvents = new List<HI_Fulfillment_Event__c>();
				if (map_CompanyEmpIdsToEventTemp.containskey(strKey)) {
					list_TempEvents = map_CompanyEmpIdsToEventTemp.get(strKey);
				}
				list_TempEvents.add(objEvent);
				map_CompanyEmpIdsToEventTemp.put(strKey, list_TempEvents);
			}
		}

		return map_CompanyEmpIdsToEventTemp;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to set the Case Description.
	 * @param        HIFulfillmentEnrollmentTadaAuditJSON,
	 *               Object of HI_Fulfillment_Event__c,
	 *               Map<String,Carrier__c>
	 * @return       map of uuid and Case Descrption
	 **/
	private String setHSACaseDescription(HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed) {
		String strCaseDescription = '';

		if (objHIEventInfoParsed.audit_type != HSA_CONTRIBUTION_LIMIT_RECORD_MISSING) {
			HIFulfillmentEnrollmentTadaAuditJSON.HomeAddress objEmployeeHomeAddress = objHIEventInfoParsed.employee.home_address;
			HIFulfillmentEnrollmentTadaAuditJSON.Address objCompanyBenefitAddress = objHIEventInfoParsed.company.benefits_address;

			strCaseDescription +=
				'\n\nEmployee Information' +
				'\n- Name: ' +
				HIFulfillmentEventHelperFunctions.getName(objHIEventInfoParsed.employee.first_name, objHIEventInfoParsed.employee.middle_initial, objHIEventInfoParsed.employee.last_name) +
				'\n- SSN: ' +
				HIFulfillmentEventHelperFunctions.getMaskedSSN('' + objHIEventInfoParsed.employee.ssn) +
				'\n- DOB: ' +
				HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday) +
				'\n- Date of hire: ' +
				HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.hired_at) +
				'\n- Home Address: ' +
				HIFulfillmentEventHelperFunctions.getAddress(
					objEmployeeHomeAddress.street_1,
					objEmployeeHomeAddress.street_2,
					objEmployeeHomeAddress.city,
					objEmployeeHomeAddress.county_name,
					objEmployeeHomeAddress.state,
					objEmployeeHomeAddress.zip,
					objEmployeeHomeAddress.country
				);
			strCaseDescription += '\n- EE Panda Link: ' + objHIEventInfoParsed.employee.panda_url;
			strCaseDescription += '\n- EE Hippo Link: ' + objHIEventInfoParsed.employee.hippo_url;

			strCaseDescription += '\n\nCompany Information - ';
			strCaseDescription +=
				'\n- Company Name: ' +
				objHIEventInfoParsed.company.name +
				'\n- Company Address:' +
				HIFulfillmentEventHelperFunctions.getAddress(
					objCompanyBenefitAddress.street_1,
					objCompanyBenefitAddress.street_2,
					objCompanyBenefitAddress.city,
					objCompanyBenefitAddress.county_name,
					objCompanyBenefitAddress.state,
					objCompanyBenefitAddress.zip,
					objCompanyBenefitAddress.country
				);
		}

		strCaseDescription += '\n\nAudit Information :';

		if (objHIEventInfoParsed.employee_benefits != null) {
			HIFulfillmentEnrollmentTadaAuditJSON.employee_benefit objEmpBenefits = objHIEventInfoParsed.employee_benefits;
			strCaseDescription += '\n- Benefit Type : ' + objEmpBenefits.benefit_type;
			strCaseDescription += '\n- Hippo URL : ' + objEmpBenefits.hippo_url;
			strCaseDescription += '\n- Effective Date : ' + objEmpBenefits.effective_date;
		}
		strCaseDescription += '\n- Audit Type : ' + objHIEventInfoParsed.audit_type;
		strCaseDescription += '\n- Error Reason : ' + objHIEventInfoParsed.errors.error_reason;

		return strCaseDescription;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to get the description of related HI Event matching with Company and Employee Ids.
	 * @param        String which contain the description,
	 *               Object of HI_Fulfillment_Event__c,
	 *               Map<String, List<HI_Fulfillment_Event__c>>,
	 * 				 Date which contain effective date
	 * 				 String which contain audit type
	 * 				 String which contain sub type.
	 * 				 String which contain provider key
	 * @return       map of uuid and Case Descrption
	 **/

	public Map<String, String> getPreviousDescription(
		HI_Fulfillment_Event__c objHIFulfillEvent,
		Map<String, List<HI_Fulfillment_Event__c>> map_CompanyEmployeeIdKeyEvents,
		Date dtEffectiveDate,
		String strType,
		String strFulfillmentSubType,
		String strProviderKey
	) {
		String strPrevEmailDetails = '';
		String strPrevErrors = '';
		String strPrevElection = '';
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Map<String, String> map_KeysToDescription = new Map<String, String>();
		if (
			map_CompanyEmployeeIdKeyEvents.containsKey(objHIFulfillEvent.Company_Id__c + objHIFulfillEvent.Employee_Id__c) &&
			map_OpenCases.containsKey(objHIFulfillEvent.Employee_Id__c + '-' + objHIFulfillEvent.Company_Id__c + '-' + strProviderKey + strType)
		) {
			for (HI_Fulfillment_Event__c objHIFulfillTemp : map_CompanyEmployeeIdKeyEvents.get(objHIFulfillEvent.Company_Id__c + objHIFulfillEvent.Employee_Id__c)) {
				Case objCase = map_OpenCases.get(objHIFulfillEvent.Employee_Id__c + '-' + objHIFulfillEvent.Company_Id__c + '-' + strProviderKey + strType);
				if (objCase.Tada_Audit_Event_Ids__c != null && !(objCase.Tada_Audit_Event_Ids__c.IndexOf(objHIFulfillTemp.Id__c) > -1)) {
					continue;
				}

				HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsedTemp;
				try {
					Blob blobDecryptedKey = EncodingUtil.base64Decode(objHIFulfillTemp.Event_Info_Encrypted__c);
					String strDeCryptedText = EncryptionUtils.getDecryptedText(blobEncryptionKey, blobDecryptedKey);
					objHIEventInfoParsedTemp = getJSONParsedData(strDeCryptedText);
				} catch (Exception objEx) {
					continue;
				}

				if (objHIEventInfoParsedTemp.errors != null) {
					strPrevErrors += getErrorStr(objHIEventInfoParsedTemp);
				}
				map_KeysToDescription.put(strErrorsValue, strPrevErrors);

				if (objHIEventInfoParsedTemp.employee_benefits != null) {
					strPrevElection += getElectionStr(objHIEventInfoParsedTemp);
				}
				map_KeysToDescription.put(strElectionValue, strPrevElection);

				if (objHIEventInfoParsedTemp.employee != null) {
					strPrevEmailDetails +=
						'\n\n- Home Address: ' +
						HIFulfillmentEventHelperFunctions.getAddress(
							objHIEventInfoParsedTemp.employee.home_address.street_1,
							objHIEventInfoParsedTemp.employee.home_address.street_2,
							objHIEventInfoParsedTemp.employee.home_address.city,
							objHIEventInfoParsedTemp.employee.home_address.county_name,
							objHIEventInfoParsedTemp.employee.home_address.state,
							objHIEventInfoParsedTemp.employee.home_address.zip,
							objHIEventInfoParsedTemp.employee.home_address.country
						);
					strPrevEmailDetails += '\n- Hippo URL: ' + objHIEventInfoParsedTemp.employee.hippo_url;
					strPrevEmailDetails += '\n- Event Type: ' + Utils.humanize(objHIEventInfoParsedTemp.sub_type);
				}
				map_KeysToDescription.put(strEmailDetailsValue, strPrevEmailDetails);
				String strEffectiveDateTemp = (objHIEventInfoParsedTemp.employee_benefits != null
					? HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsedTemp.employee_benefits.effective_date)
					: '');
				if (String.isNotBlank(strEffectiveDateTemp)) {
					Date dtPrevEffectiveDate = Date.newInstance(
						Integer.valueOf(strEffectiveDateTemp.split('-')[2]),
						Integer.valueOf(strEffectiveDateTemp.split('-')[0]),
						Integer.valueOf(strEffectiveDateTemp.split('-')[1])
					);
					if (dtPrevEffectiveDate < dtEffectiveDate) {
						dtEffectiveDate = dtPrevEffectiveDate;
					}
				}

				map_KeysToDescription.put(strEffectiveDateValue, '' + dtEffectiveDate);

				if (objHIEventInfoParsedTemp.employee_benefits != null) {
					String strTempSubType = (objHIEventInfoParsedTemp.employee_benefits.benefit_type.equalsIgnoreCase('commuter')
						? 'Commuter'
						: objHIEventInfoParsedTemp.employee_benefits.benefit_type.toUpperCase());
					if (strFulfillmentSubType.indexOf(strTempSubType) == -1) {
						//Do not want to add duplicate values
						strFulfillmentSubType += ';' + strTempSubType;
					}
					map_KeysToDescription.put(strFulfillmentSubTypeValue, strFulfillmentSubType);
				}
			}
		}

		return map_KeysToDescription;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to get the description of related HI Event matching with Company and Employee Ids.
	 * @param        instance of HIFulfillmentEnrollmentTadaAuditJSON
	 * @return       String which contain type of Case
	 **/
	private String getType(HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed) {
		String strType = '';
		if (map_HSAMFAuditDescriptions.containsKey(objHIEventInfoParsed.audit_type) && map_HSAMFAuditDescriptions.get(objHIEventInfoParsed.audit_type).Alegeus_Type__c == SUB_TYPE_HSA) {
			strType = objHIEventInfoParsed.audit_type;
		} else {
			if (objHIEventInfoParsed.audit_type == UNPROCESSED_OE_SELECTION) {
				strType = TADA_FAILURE_OE;
			} else if (objHIEventInfoParsed.audit_type == UNPROCESSED_NHE_SELECTION) {
				strType = TADA_FAILURE_NHE;
			} else {
				strType = TADA_FAILURE;
			}
		}
		return strType;
	}

	public class caseDataWrapper {
		public String eventId { get; set; }
		public String stateCarrierKey { get; set; }
		public String eventType { get; set; }
		public Long zPCompanyId { get; set; }
		public String employeeEmail { get; set; }
		public String strCaseDescription { get; set; }
		public String subscriptionIds { get; set; }
		public Date effectiveDate { get; set; }
		public String oppsOwner { get; set; }
		public HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfo { get; set; }
		public String piiInformation { get; set; }
		public String encryptedJson { get; set; }
		public String selectionIds { get; set; }
		public String subType { get; set; }

		public caseDataWrapper(
			String eeventId,
			String carrierKey,
			String eventT,
			Long companyId,
			String eEmail,
			String caseDesc,
			String eSubscriptionIds,
			Date eeffectiveDate,
			String eGroupIds,
			String eoppsOwner,
			HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed,
			String piiInfo,
			String sEncryptedJson,
			String sSelectionIds,
			String strSubType
		) {
			eventId = eeventId;
			stateCarrierKey = carrierKey;
			eventType = eventT;
			zPCompanyId = companyId;
			employeeEmail = eEmail;
			strCaseDescription = caseDesc;
			subscriptionIds = eSubscriptionIds;
			effectiveDate = eeffectiveDate;
			oppsOwner = eoppsOwner;
			objHIEventInfo = objHIEventInfoParsed;
			piiInformation = piiInfo;
			encryptedJson = sEncryptedJson;
			selectionIds = sSelectionIds;
			subType = strSubType;
		}
	}
}