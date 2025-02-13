/**
 * @name         HIEnrollmentEventUtility
 * @author
 * @date         15th December 2020
 * @description  Utility class holding common methods for processing Enrollment Events.
 * @test class   HISelectionSubmittedEventTest, HISelectionCancelledEventTest, HITadaEnrollmentEventTest, HITadaSelectionCancelledEventTest, HIContinuationElectionEventTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public class HIEnrollmentEventUtility {
	public static final String CASE_RT_ID_BENEFITS_CARE = Cache.getRecordTypeId('Case', 'Benefits Care');
	public static final String CASE_RT_ID_MF_MEMBER_GROUP_UPDATES = Cache.getRecordTypeId('Case', 'MF Member/Group Updates');
	public static final String HI_EVENT_CONTINUATION_ELECTION = 'continuation_election';
	public static final String CASE_TYPE_CONTINUATION_ENROLLMENT = 'Continuation Enrollment';
	public static final String HI_EVENT_COMPANY_UPDATE = 'company_update';
	public static final String SUBSCRIPTION_INFO_NOT_EXIST = 'Subscription information does not exist.';
	public static final String UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER = 'two_percent_shareholder';
	public static final String UPDATE_TYPE_HOME_ADDRESS = 'home_address';
	public static final String UPDATE_TYPE_FILING_ADDRESS = 'filing_address';
	public static final String UPDATE_TYPE_MAILING_ADDRESS = 'mailing_address';
	public static final String UPDATE_TYPE_BANK_ACCOUNT = 'bank_account';
	public static final String UPDATE_TYPE_SSN = 'ssn';
	public static final String UPDATE_TYPE_FIRST_NAME = 'first_name';
	public static final String UPDATE_TYPE_LAST_NAME = 'last_name';
	public static final String UPDATE_TYPE_BIRTHDAY = 'birthday';
	public static final String UPDATE_TYPE_HIRED_AT = 'hired_at';
	public static final String UPDATE_TYPE_FLSA_STATUS = 'flsa_status';
	public static final String UPDATE_TYPE_EXTRAPOLATED_ANNUAL_SALARY = 'extrapolated_annual_salary';
	public static final String CURRENT_ADDRESS_HEADING = '\nCurrent Address :: ';
	public static final String PREVIOUS_ADDRESS_HEADING = '\nPrevious Address :: ';
	public static final String PREVIOUS_INFO_HEADING = '\nPrevious Info :: ';
	public static final String CURRENT_INFO_HEADING = '\nCurrent Info :: ';
	public static final String HOME_ADDRESS_HEADING = 'Home Address';
	public static final String MAILING_ADDRESS_HEADING = 'Mailing Address';
	public static final String FILING_ADDRESS_HEADING = 'Filing Address';
	public static final String CASE_RECORDTYPE_MF_MEMEBER_GROUP_UPDATE = 'MF Member/Group Updates';
	public static final String CASE_STATUS_PENDING = 'Pending';

	static Map<String, String> map_QLEEventType;

	public static final String TERMINATION_CASE_MESSAGE = 'EE terminated before coverage effective date.Check to see if enrollment was submitted to the carrier. If so send a termination request.';
	public static final String NEW_SUBSCRIPTION_HEADING = '\n\n***** New Subscription *****';
	public static final String OVERLAPPING_SUBSCRIPTION_HEADING = '\n\n***** Overlapping Subscription *****';

	public static final String ETYPE_TADA_ENR_READY_FOR_PROCESSING = 'tada_enrollment_ready_for_processing';
	public static final String ETYPE_SELECTION_SUBMITTED = 'selections_submitted';
	public static final String ETYPE_TADA_SELECTION_CANCELLED = 'tada_selection_cancelled';
	public static final String ETYPE_SELECTION_CANCELLED = 'selection_cancelled';
	public static final String ETYPE_OPSOWNER_UPDATED = 'ops_owner_updated';
	public static final String ENROLLMENT_SOURCE_BoR = 'bor_transfer';
	public static final String OPS_OWNER_BOR = 'bor_transfer';
	public static final String OPS_OWNER_NEW_RENWALS = 'new_plans_renewals';
	public static final String TADA_ENROLLMENT_RFP_MSG = 'Case not generated due to ops owner';
	public static final String OPS_OWNER_MEMBER_FULFILLMENT = 'member_fulfillment';
	public static final String ETYPE_EMP_HSA_ENROLLMENT_AUTO_PROCESS = 'employee_hsa_enrollment_auto_process';
	public static final String ETYPE_EMP_HSA_ENROLLMENT = 'employee_hsa_enrollment';

	public static final Id COMPANY_ACCOUNT_RT_ID = Cache.getRecordTypeId('Account', 'Company');

	public static final String JSON_IS_INVALID = 'JSON not parsed correctly';
	public static final String ENROLLMENT_SOURCE_BOR_MESSAGE = 'As enrollment source is bor_transfer, we didnot process this event';
	public static final String EVENT_TYPE_IS_MISSING = 'HI Fulfillment Event Type: field value is missing in the record.';
	public static final String EVENT_ID_IS_MISSING = 'HI Fulfillment Event Id: field value is missing in the record.';
	public static final String COMPANY_ID_IS_MISSING = 'HI Company Id: field value is missing in the record.';
	public static final String COMPANY_DOES_NOT_EXIST = 'Company does not exist.';
	public static final String STATE_CARRIER_IS_MISSING = 'State Carrier information does not exist.';
	public static final String CARRIER_DOESNOT_EXIST = 'Carrier does not exist in salesforce.';
	public static final String SELECTION_INFO_MISSING = 'Selection Info is missing in the record.';
	public static final String UUID_MISSING = 'UUID is missing in the record.';
	public static final String PROVIDER_KEY_MISSING = 'Provider key is missing in the record.';
	public static final String ENROLLMENT_INFO_MISSING = 'Enrollment Info is missing';
	public static final String EMAIL_ID_IS_MISSING = 'Employee email is missing in the record.';
	public static final String STATE_CARRIER_KEY_MISSING = 'State Carrier Key: field value is missing in the record.';
	public static final String EXCEPTION_WHILE_PROCESSING = 'An exception occurred while processing the event';
	public static final String SUCCESS_MESSAGE = 'Data successfully Processed';
	public static final String TAdA_INFO_MISSING = 'Tada Info is missing.';
	public static final String FSA_HSA_MISSING = 'Both FSA and HSA information are missing.';
	public static final String EMPLOYEE_DOES_NOT_EXIST = 'Employee record does not exist.';
	public static final String BENEFIT_ITEM_MISSING = 'Benefit Item is missing in the record.';

	public static final String CASE_RECORDTYPE_NAME_NHE = 'MF NHE';
	public static final String CASE_RECORD_TYPE_QLE = 'MF QLE';
	public static final String CASE_RECORD_TYPE_BENFITS_BOR = 'Benefits BoR';
	public static final String BO_RECORD_TYPE_BENFITS_BOR = 'Benefits BoR';
	public static final String CONTACT_COMPANY_RT_ID = Cache.getRecordTypeId('Contact', 'Company');
	public static final String PII_INFO_ATTACHMENT_NAME = 'encFile.txt';
	public static final String UUID_FIELD_NAME_SUFFIX = '_UUID__c';
	public static final String ACTION_NEEDED_CASE_SUBJECT = '[Action Needed]: Review your Benefits with Gusto';
	public static final Set<String> set_CreateCaseForStatus = new Set<String>{
		'Plans Confirmed',
		'Enrollment Review Entry in Progress',
		'Ready to Send Enrollment Review',
		'Enrollment Review Sent',
		'Enrollment Confirmed',
		'Implementing TAdA Plans',
		'Ready for Balance Collection',
		'Balance Collection',
		'Transferring Balances',
		'BOR complete pending TAdAs'
	};
	public static final Set<String> set_ValidCaseRecTypes = new Set<String>{ CASE_RECORDTYPE_NAME_NHE, CASE_RECORD_TYPE_QLE, CASE_RECORD_TYPE_BENFITS_BOR };

	public static final String CASE_STATUS_NEW = 'New', CASE_STATUS_DRAFT = 'Draft';
	public static final String CASE_STATUS_HOLD = 'On Hold', CASE_STATUS_CLOSED = 'Closed';
	public static final String CASE_STATUS_CANCELLED = 'Cancelled';

	public static final String EVENT_SOURCE_QLE = 'qualifying_life_event';
	public static final String EVENT_SOURCE_NHE = 'new_hire_event';
	public static final String EVENT_SOURCE_OPEN_ENROLLMENT = 'open_enrollment_start';
	public static final String UNKNOWN_SOURCE = 'unknown';

	public static final String ADD = 'Add';
	public static final String REMOVE = 'Remove';

	public static final String CASE_TYPE_CANCELLATION = 'Cancellation';

	public static final String TAdA_BENEFIT_TYPE_HSA = 'hsa';
	public static final String TAdA_BENEFIT_TYPE_FSA = 'fsa';
	public static final String TAdA_BENEFIT_TYPE_DCA = 'dca';
	public static final String TAdA_FULFILLMENT_TYPE_HSA = 'HSA Enrollment';
	public static final String TAdA_FULFILLMENT_TYPE_FSA_DCA = 'FSA/DCA Enrollment';

	public static final Set<String> set_UnsubmittedCaseStatuses = new Set<String>{ CASE_STATUS_NEW, CASE_STATUS_DRAFT, CASE_STATUS_HOLD };

	public static final Id CASE_RT_ID_MF_CANCELLATION = Cache.getRecordTypeId('Case', 'MF Cancellation');
	public static final Id CASE_RT_ID_MF_TERMINATION = Cache.getRecordTypeId('Case', 'MF Termination');
	public static final Id CASE_RT_ID_MF_NHE = Cache.getRecordTypeId('Case', 'MF NHE');
	public static final Id CASE_RT_ID_MF_QLE = Cache.getRecordTypeId('Case', 'MF QLE');
	public static final Id CASE_RT_ID_BENEFITS_BOR = Cache.getRecordTypeId('Case', 'Benefits BoR');

	public static final String CASE_TYPE_NHE = 'NHE';
	public static final String CASE_TYPE_QLE = 'QLE';

	public static final String QUEUE_MF = 'Member Fulfillment';
	public static final String QUEUE_MF_FOLLOWUP = 'MF Followup';
	public static final String QUEUE_FORM_AUTO = 'Form Automation';
	public static final String QUEUE_MF_AUTO = 'MF Automation';
	public static final String QUEUE_MF_AUTO_FOLLOWUP = 'MF Automation Follow Up';

	public static final String DESC_SEPARATOR = '--------------------------------------------------';

	public static final String WAIVED_EVENT = 'waived';
	public static final String ENROLLING_EVENT = 'enrolling';

	public static Map<String, Id> map_QueueNameToId;
	public static Set<String> set_CaseFieldAPINames;

	public static final String BENEFIT_TYPE_MEDICAL = 'Medical';
	public static final String BENEFIT_TYPE_DENTAL = 'Dental';
	public static final String BENEFIT_TYPE_VISION = 'Vision';
	public static final String BENEFIT_TYPE_LIFE = 'Life';
	public static final String BENEFIT_TYPE_LTD = 'Long Term Disability';
	public static final String BENEFIT_TYPE_STD = 'Short Term Disability';
	public static final String BENEFIT_TYPE_LTD_1 = 'Long_Term_Disability';
	public static final String BENEFIT_TYPE_STD_1 = 'Short_Term_Disability';

	public static final String COMPANY_SUSPENSION_AUDIT = 'company_suspension_audit';
	public static final String BENEFITS_STATUS_AUDIT = 'benefits_status_audit';
	public static final String COMPANY_SUSPENSION_AUDIT_SUBJECT = 'This company has a suspended payroll, but their benefits have not yet been suspended.';
	public static final String AUDIT_CASE_ALREADY_EXIST = 'Audit case already exist.';

	public static final String PAYROLL_SUSPENSION_AUDIT_DESCRIPTION = 'Please make at least 3 attempts to reach all Full Access admins on this group’s Gusto account, and give them adequate time to respond to our request. This will help ensure we offboard this group’s benefits in a compliant manner. For more information on how to process this, see the following Wiki article on Payroll Suspension Audits. https://confluence.gustocorp.com/pages/viewpage.action?spaceKey=hitops&title=Payroll+Suspension+Audit';

	public static final String SUBMITTED_CASE_MESSAGE = 'This employee has made changes to their benefits. Please refer to hippo to confirm this EE\'s selections. If the EE no longer has benefits with this Carrier, send a termination';

	public static final Set<String> set_UnsubmittedCaseStatusesForEmpUpdates = new Set<String>{ CASE_STATUS_NEW, CASE_STATUS_DRAFT, CASE_STATUS_PENDING, CASE_STATUS_HOLD };
	public static final Set<String> set_ValidCaseRecTypesForEmpUpdates = new Set<String>{ CASE_RECORDTYPE_NAME_NHE, CASE_RECORDTYPE_MF_MEMEBER_GROUP_UPDATE };

	public static String strBOErrorMsg = 'Benefit Order is Unfulfilled.';
	public static final Id CASE_RT_ID_MF_AUDIT = Cache.getRecordTypeId('Case', 'MF Audit');
	public static final String MF_TERMINATION = 'MF Termination';
	public static final String MF_NHE = 'MF NHE';
	public static final String MF_QLE = 'MF QLE';
	public static final String BENEFIT_ORDER = 'Benefit Order';
	public static final String CARRIER_ORDER = 'Carrier Order';
	public static String MASTER = 'Master';
	public static String strFileName = 'encFile.txt';
	public static String NOT_AVAILABLE = 'not available';
	public static String PAYROLL_SUSPENSION_AUDIT = 'Payroll Suspension Audit';
	public static String YES = 'Yes';
	public static String SUSPENSION_AUDIT = 'Suspension Audit';
	public static String AUDIT = 'Audit';
	public static String NEW_PLAN = 'new_plan';
	public static String CASE_ALREADY_OPEN = ' - Case already open ';
	public static final String ERROR_PROCESSING_SUBSCRIPTION = 'Error Processing Subscription';
	public static final String RECONCILIATION = 'Reconciliation';
	public static final String GROUP_LEVEL = 'Group level';
	public static string strDestroyReason = ''; //BBO-1456

	public final static Map<String, String> map_BenefitTypesWithFieldAPI = new Map<String, String>{
		'Medical' => 'Medical_UUID__c',
		'Life' => 'Life_UUID__c',
		'Dental' => 'Dental_UUID__c',
		'Long Term Disability' => 'Long_Term_Disability_UUID__c',
		'Short Term Disability' => 'Short_Term_Disability_UUID__c',
		'Vision' => 'Vision_UUID__c',
		'HSA' => 'HSA_UUID__c',
		'DCA' => 'DCA_UUID__c',
		'FSA' => 'FSA_UUID__c'
	};

	public static final String MOPS_BASE_QUERY = 'SELECT Id,Status,Type,Medical_UUID__c,Life_UUID__c,Dental_UUID__c,Long_Term_Disability_UUID__c,Short_Term_Disability_UUID__c,Vision_UUID__c,HSA_UUID__c,DCA_UUID__c,FSA_UUID__c,Description,Employee_Id__c,RecordTypeId,RecordType.Name,Carrier__r.Key__c,Selection_UUIDs__c,Benefit_Types__c,AccountId,ContactId,Subject,Carrier__c,Integration_Id__c,Integration_Key__c,Anticipated_Effective_Date__c,Selection_Ids__c,ParentId,Parent.RecordTypeId,Parent.Selection_UUIDs__c,Parent.Integration_Id__c,Parent.Integration_Key__c,ZP_Company_Id__c,Contact_Employee_Id__c,State_Carrier_Id__c,Account.ZP_Company_ID__c FROM Case WHERE Integration_Id__c != NULL AND Integration_Key__c != NULL ';

	/*
	 *  Fetch custom settings for QLE event type names and create a map
	 */
	public static Map<String, String> fetchQLEEventTypeMap() {
		if (map_QLEEventType == null) {
			map_QLEEventType = new Map<String, String>();
		}

		if (map_QLEEventType.isEmpty()) {
			List<QLE_Event_Type_Map__c> list_QLEEventTypes = QLE_Event_Type_Map__c.getall().values();

			for (QLE_Event_Type_Map__c type : list_QLEEventTypes) {
				map_QLEEventType.put(type.Name, type.Salesforce_Value__c);
			}
		}
		return map_QLEEventType;
	}

	/*
	 *  Validate HI_Fulfillment_Event record and set initial processing state
	 */
	public static Map<String, HI_Fulfillment_Event__c> validateAndSetProcessingState(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvent) {
		Map<String, HI_Fulfillment_Event__c> map_ValidEvents = new Map<String, HI_Fulfillment_Event__c>();

		for (HI_Fulfillment_Event__c objHIFulfill : list_HIFulfillmentEvent) {
			if (objHIFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			// if Event Type of HI Fulfillment record is blank
			if (String.isBlank(objHIFulfill.Event_Type__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, EVENT_TYPE_IS_MISSING, objHIFulfill);
				continue;
			}

			if (String.isBlank(objHIFulfill.Id__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, EVENT_ID_IS_MISSING, objHIFulfill);
				continue;
			}

			objHIFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfill.Message__c = '';

			map_ValidEvents.put(objHIFulfill.Id__c, objHIFulfill);
		}
		return map_ValidEvents;
	}

	/*
	 *  Upsert cases and update HI_Fulfillment_Event record's status
	 */
	public static void upsertCasesAndSetProcessingState(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvent, List<Case> list_CasesToUpsert, String strMethodName) {
		if (!list_CasesToUpsert.isEmpty()) {
			try {
				Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();
				List<Database.UpsertResult> saveResult = database.upsert(list_CasesToUpsert, false);
				dmlCaseUpsertErrorsMap = Utils.processUpsertResult(saveResult, list_CasesToUpsert, 'Integration_Id__c', true, strMethodName);

				for (HI_Fulfillment_Event__c objEvent : list_HIFulfillmentEvent) {
					if (objEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
						continue;
					}

					if (dmlCaseUpsertErrorsMap.containsKey(objEvent.Id__c)) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlCaseUpsertErrorsMap.get(objEvent.Id__c), objEvent);
						continue;
					} else {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, SUCCESS_MESSAGE, objEvent);
					}
				}
			} catch (Exception e) {
				ExceptionLogUtil.logException(strMethodName, 'upsertCasesAndSetProcessingState', e.getMessage(), e.getStackTraceString());

				for (HI_Fulfillment_Event__c objEvent : list_HIFulfillmentEvent) {
					if (objEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
						continue;
					}

					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, e.getMessage(), objEvent);
				}
			}
		}
	}

	public static Map<String, DependentInfo> getDependentsMap(List<DependentInfo> list_Dependents) {
		Map<String, DependentInfo> map_Dependents = new Map<String, DependentInfo>();

		if (!list_Dependents.isEmpty()) {
			for (HIEnrollmentEventUtility.DependentInfo objDependent : list_Dependents) {
				map_Dependents.put('' + objDependent.id, objDependent);
			}
		}
		return map_Dependents;
	}

	public static Case updateUUIDOnCase(String strBenefitType, Case objCase, String strUUID, String strAddOrRemove) {
		if (String.isNotBlank(strBenefitType)) {
			switch on strBenefitType.toLowerCase() {
				when 'medical' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.Medical_UUID__c = strUUID;
					} else if (objCase.Medical_UUID__c == strUUID) {
						objCase.Medical_UUID__c = null;
					}
				}
				when 'dental' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.Dental_UUID__c = strUUID;
					} else if (objCase.Dental_UUID__c == strUUID) {
						objCase.Dental_UUID__c = null;
					}
				}
				when 'life' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.Life_UUID__c = strUUID;
					} else if (objCase.Life_UUID__c == strUUID) {
						objCase.Life_UUID__c = null;
					}
				}
				when 'vision' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.Vision_UUID__c = strUUID;
					} else if (objCase.Vision_UUID__c == strUUID) {
						objCase.Vision_UUID__c = null;
					}
				}
				when 'long_term_disability' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.Long_Term_Disability_UUID__c = strUUID;
					} else if (objCase.Long_Term_Disability_UUID__c == strUUID) {
						objCase.Long_Term_Disability_UUID__c = null;
					}
				}
				when 'short_term_disability' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.Short_Term_Disability_UUID__c = strUUID;
					} else if (objCase.Short_Term_Disability_UUID__c == strUUID) {
						objCase.Short_Term_Disability_UUID__c = null;
					}
				}
				when 'dca' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.DCA_UUID__c = strUUID;
					} else if (objCase.DCA_UUID__c == strUUID) {
						objCase.DCA_UUID__c = null;
					}
				}
				when 'fsa' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.FSA_UUID__c = strUUID;
					} else if (objCase.FSA_UUID__c == strUUID) {
						objCase.FSA_UUID__c = null;
					}
				}
				when 'hsa' {
					if (strAddOrRemove.equalsIgnoreCase('Add')) {
						objCase.HSA_UUID__c = strUUID;
					} else if (objCase.HSA_UUID__c == strUUID) {
						objCase.HSA_UUID__c = null;
					}
				}
			}
		}
		return objCase;
	}

	// if Contact is not present in salesforce then create new one
	public static Map<String, Contact> processContactInformation(
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvent,
		Map<String, HISelectionsSubmittedEventJSON> map_SelectionSubmittedInfo,
		Map<String, HITaDaEnrollmentEventJSON> map_TadaEnrollmentInfo,
		Map<String, Account> map_Account,
		Map<String, Contact> map_Contact,
		Set<String> set_EmployeeEmail,
		String strEventType
	) {
		List<Contact> list_ContactToBeInserted = new List<Contact>();
		String strExceptionClassName = '';
		Map<String, String> map_EventIdToEmployeeEmail = new Map<String, String>();

		for (HI_Fulfillment_Event__c objFulfillmentEvent : list_HIFulfillmentEvent) {
			if (objFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			CompanyInfo objCompany;
			EmployeeInfo objEmployee;

			if (strEventType.equalsIgnoreCase(ETYPE_SELECTION_SUBMITTED)) {
				HISelectionsSubmittedEventJSON objSubmittedEventJSON = map_SelectionSubmittedInfo.get(objFulfillmentEvent.Id__c);
				objCompany = objSubmittedEventJSON.company;
				objEmployee = objSubmittedEventJSON.employee;

				if (String.isBlank(strExceptionClassName)) {
					strExceptionClassName = 'HISelectionSubmittedEvent-processContactInformation';
				}
			} else if (strEventType.equalsIgnoreCase(ETYPE_TADA_ENR_READY_FOR_PROCESSING)) {
				HITaDaEnrollmentEventJSON objTadaEventJSON = map_TadaEnrollmentInfo.get(objFulfillmentEvent.Id__c);
				objCompany = objTadaEventJSON.company;
				objEmployee = objTadaEventJSON.employee;
				if (String.isBlank(strExceptionClassName)) {
					strExceptionClassName = 'HITaDaEnrollmentEvent-processContactInformation';
				}
			}

			if (objCompany == null || objEmployee == null) {
				continue;
			}

			map_EventIdToEmployeeEmail.put(objFulfillmentEvent.Id__c, objEmployee.email);

			if (!map_Account.containsKey('' + objCompany.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objFulfillmentEvent);
				continue;
			}

			if (!map_Contact.containsKey(objCompany.id + '-' + objEmployee.email) && !map_Contact.containsKey(objEmployee.email)) {
				Contact objContact = new Contact();
				objContact.AccountId = map_Account.get('' + objCompany.id).Id;
				objContact.FirstName = objEmployee.first_Name;
				objContact.LastName = objEmployee.last_name;
				objContact.Email = objEmployee.email;
				objContact.RecordTypeId = HIEnrollmentEventUtility.CONTACT_COMPANY_RT_ID;
				objContact.Employee_Id__c = String.valueOf(objEmployee.id);
				list_ContactToBeInserted.add(objContact);
			}
		}

		if (list_ContactToBeInserted.size() > 0) {
			Map<String, String> map_DMLContactInsertErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResult = database.insert(list_ContactToBeInserted, false);
			map_DMLContactInsertErrors = Utils.processSaveResult(list_SaveResult, list_ContactToBeInserted, 'email', false, strExceptionClassName);
			for (HI_Fulfillment_Event__c objFulfillmentEvent : list_HIFulfillmentEvent) {
				String strEmployeeEmail = map_EventIdToEmployeeEmail.containsKey(objFulfillmentEvent.Id__c) ? map_EventIdToEmployeeEmail.get(objFulfillmentEvent.Id__c) : '';

				if (map_DMLContactInsertErrors.containsKey(strEmployeeEmail)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLContactInsertErrors.get(strEmployeeEmail), objFulfillmentEvent);
					continue;
				}
			}

			//update the map as new contact is created
			map_Contact = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);
		}
		return map_Contact;
	}

	public static Map<String, Object> fetchCases(Set<String> set_UUIDs) {
		Map<String, Object> map_Result = new Map<String, Object>();
		Map<String, Case> map_Cases = new Map<String, Case>();
		Map<String, Case> map_ExistingTerminationCases = new Map<String, Case>();
		Map<String, Case> map_ExistingCancellationCases = new Map<String, Case>();
		Set<Id> set_CancelledTerminatedCases = new Set<Id>{ HIEnrollmentEventUtility.CASE_RT_ID_MF_CANCELLATION, HIEnrollmentEventUtility.CASE_RT_ID_MF_TERMINATION };

		if (set_UUIDs != null && !set_UUIDs.isEmpty()) {
			for (Case objCase : [
				SELECT
					Status,
					Medical_UUID__c,
					Life_UUID__c,
					Dental_UUID__c,
					Long_Term_Disability_UUID__c,
					Short_Term_Disability_UUID__c,
					Vision_UUID__c,
					HSA_UUID__c,
					DCA_UUID__c,
					FSA_UUID__c,
					Description,
					Employee_Id__c,
					Integration_Key__c,
					Integration_Id__c,
					RecordTypeId,
					RecordType.Name,
					Carrier__r.Key__c,
					Selection_UUIDs__c,
					Benefit_Types__c,
					Enrollment_Modified__c,
					Enrollment_Message__c,
					Fulfillment_Event_Encrypted_JSON__c,
					Subscription_Information__c,
					AccountId,
					ContactId,
					Subject,
					Carrier__c,
					Fulfillment_Sub_Type__c,
					OwnerId
				FROM Case
				WHERE
					Integration_Id__c != NULL
					AND Integration_Key__c != NULL
					AND Employee_Id__c != NULL
					AND Carrier__c != NULL
					AND ((RecordType.Name IN :HIEnrollmentEventUtility.set_ValidCaseRecTypes
					AND (Medical_UUID__c IN :set_UUIDs
					OR Life_UUID__c IN :set_UUIDs
					OR Dental_UUID__c IN :set_UUIDs
					OR Long_Term_Disability_UUID__c IN :set_UUIDs
					OR Short_Term_Disability_UUID__c IN :set_UUIDs
					OR Vision_UUID__c IN :set_UUIDs
					OR HSA_UUID__c IN :set_UUIDs
					OR FSA_UUID__c IN :set_UUIDs
					OR DCA_UUID__c IN :set_UUIDs))
					OR (RecordTypeId IN :set_CancelledTerminatedCases
					AND Status IN :HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses))
			]) {
				if (HIEnrollmentEventUtility.set_ValidCaseRecTypes.contains(objCase.RecordType.Name)) {
					if (set_UUIDs.contains(objCase.Medical_UUID__c)) {
						map_Cases.put(objCase.Medical_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.Vision_UUID__c)) {
						map_Cases.put(objCase.Vision_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.Dental_UUID__c)) {
						map_Cases.put(objCase.Dental_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.Life_UUID__c)) {
						map_Cases.put(objCase.Life_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.Short_Term_Disability_UUID__c)) {
						map_Cases.put(objCase.Short_Term_Disability_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.Long_Term_Disability_UUID__c)) {
						map_Cases.put(objCase.Long_Term_Disability_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.HSA_UUID__c)) {
						map_Cases.put(objCase.HSA_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.FSA_UUID__c)) {
						map_Cases.put(objCase.FSA_UUID__c, objCase);
					} else if (set_UUIDs.contains(objCase.DCA_UUID__c)) {
						map_Cases.put(objCase.DCA_UUID__c, objCase);
					}
				} else if (objCase.RecordTypeId == HIEnrollmentEventUtility.CASE_RT_ID_MF_TERMINATION) {
					map_ExistingTerminationCases.put(objCase.Employee_Id__c + '-' + objCase.Carrier__r.Key__c, objCase);
				} else if (objCase.RecordTypeId == HIEnrollmentEventUtility.CASE_RT_ID_MF_CANCELLATION) {
					map_ExistingCancellationCases.put(objCase.Employee_Id__c + '-' + objCase.Carrier__r.Key__c, objCase);
				}
			}
		}

		map_Result.put('NHEQLECases', map_Cases);
		map_Result.put('Termination', map_ExistingTerminationCases);
		map_Result.put('Cancellation', map_ExistingCancellationCases);
		return map_Result;
	}

	public static Case updateCaseOwner(Case objCase, Boolean blnSubmitted) {
		Set<String> set_QueueNames = new Set<String>{ QUEUE_MF, QUEUE_MF_FOLLOWUP, QUEUE_FORM_AUTO, QUEUE_MF_AUTO, QUEUE_MF_AUTO_FOLLOWUP };
		map_QueueNameToId = GlobalQueryHelper.getNameQueueMap(set_QueueNames);

		if (
			objCase != null &&
			map_QueueNameToId != null &&
			(map_QueueNameToId.get(QUEUE_FORM_AUTO) == objCase.OwnerId ||
			map_QueueNameToId.get(QUEUE_MF_AUTO) == objCase.OwnerId ||
			map_QueueNameToId.get(QUEUE_MF_AUTO_FOLLOWUP) == objCase.OwnerId)
		) {
			if (blnSubmitted) {
				objCase.OwnerId = map_QueueNameToId.get(QUEUE_MF_FOLLOWUP);
			} else if (map_QueueNameToId.get(QUEUE_MF_AUTO) != objCase.OwnerId) {
				objCase.OwnerId = map_QueueNameToId.get(QUEUE_MF);
			}
		}

		return objCase;
	}

	public static Case createCaseRecordForSelectionCancelled(
		Map<String, Case> map_ExistingCases,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Map<String, Carrier__c> map_Carrier,
		String strKey,
		String strCompanyId,
		String strEmployeeId,
		String strCarrierKey,
		String strCarrierId,
		String strUUID,
		String strBenefitTypeUIValue,
		String strBenefitType,
		String strEventId,
		Database.DMLOptions objDMLOption
	) {
		Case objCase;
		if (map_ExistingCases != null && map_ExistingCases.containsKey(strKey)) {
			objCase = map_ExistingCases.get(strKey);

			if (objCase != null) {
				//BBO-1456 Start
				if (strDestroyReason == 'cancellation_qle') {
					objCase.Fulfillment_Type__c = 'Canceled due to QLE';
				} else if (strDestroyReason == 'changed_policy_selection') {
					objCase.Fulfillment_Type__c = 'Changed Plan Selection';
				} else if (strDestroyReason == 'employee_terminated') {
					objCase.Fulfillment_Type__c = 'Employee Terminated';
				} else if (strDestroyReason == 'enrollment_destroyed') {
					objCase.Fulfillment_Type__c = 'Enrollment Destroyed';
				} else if (strDestroyReason == 'enrollment_reset_to_modify_dependent') {
					objCase.Fulfillment_Type__c = 'Enrollment Reset';
				} else if (strDestroyReason == 'waived_previously_selected_benefit') {
					objCase.Fulfillment_Type__c = 'Waived Previously Selected Benefit';
				}
				//BBO-1456 End
				if (strBenefitTypeUIValue != null && objCase.Benefit_Types__c != null && !objCase.Benefit_Types__c?.containsIgnoreCase(strBenefitTypeUIValue)) {
					objCase.Benefit_Types__c += ';' + strBenefitTypeUIValue;
					objCase.Selection_UUIds__c += ';' + strUUID;
				} else {
					String strUUIDFieldAPIName = strBenefitType + UUID_FIELD_NAME_SUFFIX;

					if (strUUIDFieldAPIName != UUID_FIELD_NAME_SUFFIX) {
						String strUUIDToRemove = String.valueOf(objCase.get(strUUIDFieldAPIName));

						if (String.isNotBlank(strUUIDToRemove)) {
							objCase = updateUUIDOnCase(strBenefitType, objCase, strUUIDToRemove, 'Remove');
						}

						if (String.isNotBlank(strUUIDToRemove) && String.isNotBlank(objCase?.Selection_UUIds__c) && objCase.Selection_UUIds__c.contains(strUUIDToRemove)) {
							objCase.Selection_UUIds__c = objCase.Selection_UUIds__c.replace(strUUIDToRemove, '');
							objCase.Selection_UUIds__c = objCase.Selection_UUIds__c.replace(';;', ';') == ';' ? '' : objCase.Selection_UUIds__c.replace(';;', ';');
						}
					}

					if (String.isNotBlank(objCase.Selection_UUIds__c)) {
						objCase.Selection_UUIds__c += ';' + strUUID;
					} else {
						objCase.Selection_UUIds__c = strUUID;
					}
				}
			}
		} else {
			objCase = new Case(
				Employee_Id__c = strEmployeeId,
				Integration_Id__c = strEventId,
				Benefit_Types__c = strBenefitTypeUIValue,
				Selection_UUIds__c = strUUID,
				Status = HIEnrollmentEventUtility.CASE_STATUS_NEW
			);

			objCase.Integration_Key__c = (strEventId + '-' + strCarrierKey);
			//BBO-1456 Start
			if (strDestroyReason == 'cancellation_qle') {
				objCase.Fulfillment_Type__c = 'Canceled due to QLE';
			} else if (strDestroyReason == 'changed_policy_selection') {
				objCase.Fulfillment_Type__c = 'Changed Plan Selection';
			} else if (strDestroyReason == 'employee_terminated') {
				objCase.Fulfillment_Type__c = 'Employee Terminated';
			} else if (strDestroyReason == 'enrollment_destroyed') {
				objCase.Fulfillment_Type__c = 'Enrollment Destroyed';
			} else if (strDestroyReason == 'enrollment_reset_to_modify_dependent') {
				objCase.Fulfillment_Type__c = 'Enrollment Reset';
			} else if (strDestroyReason == 'waived_previously_selected_benefit') {
				objCase.Fulfillment_Type__c = 'Waived Previously Selected Benefit';
			}
			//BBO-1456 Ends
			objCase.setOptions(objDMLOption);
		}

		if (strCarrierId == '' && strCarrierKey != null) {
			objCase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(strCarrierKey)) ? map_Carrier.get(strCarrierKey).Id : null;
		} else {
			objCase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(strCarrierId)) ? map_Carrier.get(strCarrierId).Id : null;
		}

		objCase = updateUUIDOnCase(strBenefitType, objCase, strUUID, 'Add');

		String strCaseSubject = '';

		if (String.isBlank(objCase.AccountId) && map_Accounts.containsKey(strCompanyId)) {
			objCase.AccountId = map_Accounts.get(strCompanyId).Id;
			strCaseSubject = map_Accounts.get(strCompanyId).Name;
		}

		if (String.isBlank(objCase.ContactId) && map_Contacts.containsKey(strEmployeeId)) {
			objCase.ContactId = map_Contacts.get(strEmployeeId).Id;
			strCaseSubject += ':' + map_Contacts.get(strEmployeeId).Name;
		}

		objCase.Subject = String.isBlank(objCase.Subject) ? strCaseSubject : objCase.Subject;
		return objCase;
	}

	public static String getEmployeeInformation(EmployeeInfo objEmployee, String strCompanyName, String strStateCarrierName, String strCarrierEnrollmentURL) {
		//get the home address
		HomeAddress objEmployeeHomeAddress = new HomeAddress();
		if (objEmployee.home_address != null) {
			objEmployeeHomeAddress = objEmployee.home_address;
		}

		String strEmployeeDescription = '';
		String strEmployeeName = HIFulfillmentEventHelperFunctions.getName(objEmployee.first_Name, objEmployee.last_Name, objEmployee.middle_initial);

		strEmployeeDescription += '\n\n' + strEmployeeName + ' of ' + strCompanyName + ' would like to enroll in the following ' + strStateCarrierName + ' plans:';

		if (String.isNotBlank(strCarrierEnrollmentURL)) {
			strEmployeeDescription += '\nLink to carrier enrollment data: ' + strCarrierEnrollmentURL;
		}

		strEmployeeDescription += '\nLink to employee\'s subscriptions: ' + objEmployee.hippo_url + '/subscriptions';
		strEmployeeDescription += '\nLink to employee\'s enrollments: ' + objEmployee.hippo_url + '/enrollments';
		strEmployeeDescription += '\nEE Panda Link: ' + objEmployee.panda_url;

		return strEmployeeDescription;
	}

	//parse enrollment_source information and add to case description
	public static String getEnrollmentSourceInfo(EnrollmentSourceInfo objEnrollmentSource) {
		String strEnrollmentInfo = '';

		if (objEnrollmentSource != null) {
			if (String.isNotBlank(objEnrollmentSource.type)) {
				if (objEnrollmentSource.type == EVENT_SOURCE_QLE) {
					if (!map_QLEEventType.isEmpty() && String.isNotBlank(objEnrollmentSource.event_type) && map_QLEEventType.containsKey(objEnrollmentSource.event_type)) {
						strEnrollmentInfo += '\nEvent Type: ' + Utils.humanize(map_QLEEventType.get(objEnrollmentSource.event_type));
					}
				} else {
					strEnrollmentInfo += '\nEvent Type: ' + Utils.humanize(objEnrollmentSource.type);
				}
			}

			if (String.isNotBlank(objEnrollmentSource.event_date)) {
				strEnrollmentInfo += '\nEvent Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objEnrollmentSource.event_date);
			}

			if (objEnrollmentSource.file_upload_urls != null && !objEnrollmentSource.file_upload_urls.isEmpty()) {
				String strFileUploadURLs = '';

				for (String strURL : objEnrollmentSource.file_upload_urls) {
					strFileUploadURLs += strURL + ',\n';
				}

				strFileUploadURLs = strFileUploadURLs.removeEnd(',\n');
				strEnrollmentInfo += '\nFile Upload URLs:\n' + strFileUploadURLs;
			}
		}

		return strEnrollmentInfo;
	}

	public static String getPIIInformation(EmployeeInfo objEmployee, List<DependentInfo> list_Dependents) {
		String strPIIInfo = '';

		//PII information for each employee
		if (objEmployee != null) {
			strPIIInfo += 'Employee Info:';
			strPIIInfo += '<br/>- Name: ' + HIFulfillmentEventHelperFunctions.getName(objEmployee.first_Name, objEmployee.last_Name, objEmployee.middle_initial);
			strPIIInfo += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN(objEmployee.ssn);
			strPIIInfo += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objEmployee.birthday);
		}

		if (list_Dependents != null && !list_Dependents.isEmpty()) {
			strPIIInfo += '<br/>Employee Info:';

			for (DependentInfo objDep : list_Dependents) {
				strPIIInfo += '<br/>- Name: ' + HIFulfillmentEventHelperFunctions.getName(objDep.first_Name, objDep.last_Name, '');
				strPIIInfo += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN(objDep.ssn);
				strPIIInfo += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objDep.birthday);
			}
		}

		return strPIIInfo;
	}

	public static void createAttachment(List<Case> list_Cases, Map<String, String> map_PIIInfo) {
		List<Attachment> list_attachments = new List<Attachment>();
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');

		Set<Id> set_CaseIds = new Set<Id>();

		for (Case objCase : list_Cases) {
			if (objCase.Id != null) {
				set_CaseIds.add(objCase.Id);
			}
		}

		if (set_CaseIds.isEmpty())
			return;

		Set<Id> set_CaseIdsWithAttachment = getExistingAttachmentCase(set_CaseIds);

		for (Case objCase : list_Cases) {
			if (objCase.Id != null && !set_CaseIdsWithAttachment.contains(objCase.Id)) {
				if (map_PIIInfo.containsKey(objCase.Integration_Key__c)) {
					Attachment atch = new Attachment();
					atch.ParentId = objCase.Id;
					atch.Body = EncryptionUtils.getEncryptedBlob(encryptionKey, map_PIIInfo.get(objCase.Integration_Key__c));
					atch.Name = PII_INFO_ATTACHMENT_NAME;
					list_attachments.add(atch);
				}
			}
		}

		if (list_attachments.size() > 0) {
			insert list_attachments;
		}
	}

	static Set<Id> getExistingAttachmentCase(Set<Id> set_CaseIds) {
		Set<Id> set_ParentIds = new Set<Id>();

		if (set_CaseIds != null && !set_CaseIds.isEmpty()) {
			for (Attachment objAtt : [SELECT ParentId FROM Attachment WHERE ParentId IN :set_CAseIds AND Name = :PII_INFO_ATTACHMENT_NAME]) {
				set_ParentIds.add(objAtt.ParentId);
			}
		}

		return set_ParentIds;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to get the map of MF_Audit_Descriptions__mdt with redpect to Audit_Type__c and Description__c
	 * @param        null
	 * @return       Map of Audit_Type__c and Description__c of MF_Audit_Descriptions__mdt
	 **/

	public static Map<String, MF_Audit_Descriptions__mdt> getMFAuditDescrptions() {
		Map<String, MF_Audit_Descriptions__mdt> map_MFAuditDescriptions = new Map<String, MF_Audit_Descriptions__mdt>();

		for (MF_Audit_Descriptions__mdt objMFAudit : [SELECT Audit_Type__c, Description__c, Relative_Object__c, Parent_Cases__c, TAdA_Type__c, Audit_Payload__c FROM MF_Audit_Descriptions__mdt]) {
			map_MFAuditDescriptions.put(objMFAudit.Audit_Type__c, objMFAudit);
		}

		return map_MFAuditDescriptions;
	}

	public class DependentInfo {
		public String id;
		public String first_name;
		public String last_name;
		public String ssn;
		public String birthday;
		public String gender;
		public String dependent_type;
		public String url;
	}

	public class HomeAddress {
		public Long id;
		public String fax;
		public String zip;
		public String city;
		public String phone;
		public String state;
		public String country;
		public Boolean inactive;
		public String street_1;
		public String street_2;
		public String created_at;
		public String updated_at;
		public String county_name;
		public Boolean work_address;
	}

	public class CompanyInfo {
		public Long id;
		public String name;
		public String email;
		public String phone; //@BS 11 Jan 2021 .In case of "selections_submitted" request phone number is required
		public String panda_url;
		public String hippo_url;
	}

	public class EmployeeInfo {
		public Long id;
		public String first_name;
		public String last_name;
		public String middle_initial;
		public String ssn;
		public String birthday;
		public String email;
		public String employment_status;
		public HomeAddress home_address;
		public String annual_salary;
		public String gender;
		public String hired_at;
		public String benefits_eligibility_date;
		public String terminated_at;
		public String panda_url;
		public String hippo_url;
	}

	public class EnrollmentSourceInfo {
		public String type;
		public String event_type;
		public String event_date;
		public String[] file_upload_urls;
	}
}