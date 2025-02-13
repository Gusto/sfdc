/**
 * @name         HISelectionSubmittedEvent
 * @author
 * @date         15th December 2020
 * @description  Process Selection Submitted Events and update/create relevant cases.
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 */
public class HISelectionSubmittedEvent {
	static Map<String, HIEnrollmentEventUtility.DependentInfo> map_Dependents = new Map<String, HIEnrollmentEventUtility.DependentInfo>();
	static Map<String, HISelectionsSubmittedEventJSON.PolicyInfo> map_PolicyId = new Map<String, HISelectionsSubmittedEventJSON.PolicyInfo>();
	static Map<String, HISelectionsSubmittedEventJSON.StateCarrierInfo> map_StateCarrier = new Map<String, HISelectionsSubmittedEventJSON.StateCarrierInfo>();
	static Map<String, List<HISelectionsSubmittedEventJSON.FormInfo>> map_stateCarrierForms;
	static Map<String, Map<String, Object>> map_stateCarrierIdFormMappings;
	static map<String, Benefit_Order__c> map_BO;
	static map<String, String> map_PIIInfo;
	static Map<String, String> map_QLEEventType;

	public static void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvent) {
		// declaring variables
		List<Exception> list_Exceptions = new List<Exception>();
		Set<String> set_ZPCompanyId = new Set<String>();
		Set<String> set_EmployeeEmail = new Set<String>();
		Set<String> set_StateCarrierKey = new Set<String>();
		Set<String> set_EmployeeIDs = new Set<String>();
		Set<Date> set_StartDate = new Set<Date>();
		Map<String, Account> map_Account = new Map<String, Account>();
		Map<String, Contact> map_Contact = new Map<String, Contact>();
		Map<String, Carrier__c> map_Carrier = new Map<String, Carrier__c>();
		Map<String, HISelectionsSubmittedEventJSON> map_EventIdInfo = new Map<String, HISelectionsSubmittedEventJSON>();
		Map<String, HISelectionsSubmittedEventJSON.SelectionInfo> map_SelectionInfo = new Map<String, HISelectionsSubmittedEventJSON.SelectionInfo>();
		Map<String, CaseDataWrapper> map_CaseDataUsingSelection = new Map<String, CaseDataWrapper>();
		String strCaseType = '';

		map_QLEEventType = HIEnrollmentEventUtility.fetchQLEEventTypeMap();
		map_PIIInfo = new Map<String, String>();

		if (list_HIFulfillmentEvent == null || list_HIFulfillmentEvent.isEmpty()) {
			return;
		}

		Map<String, HI_Fulfillment_Event__c> map_ValidEvents = HIEnrollmentEventUtility.validateAndSetProcessingState(list_HIFulfillmentEvent);

		if (map_ValidEvents.isEmpty()) {
			return;
		}

		Blob blbEncryptionKey = EncryptionUtils.getEncryptionKey('Master');

		map_stateCarrierIdFormMappings = new Map<String, Map<String, Object>>();
		map_stateCarrierForms = new Map<String, List<HISelectionsSubmittedEventJSON.FormInfo>>();

		//Fetch json related data of HI fulfillment submitted event
		for (HI_Fulfillment_Event__c objFulfillmentSubmitEvent : map_ValidEvents.values()) {
			HISelectionsSubmittedEventJSON objParsedInfoEvent;

			try {
				Blob blobDecryptedInfo = EncodingUtil.base64Decode(objFulfillmentSubmitEvent.Event_Info_Encrypted__c);
				String strDecryptedInfo = EncryptionUtils.getDecryptedText(blbEncryptionKey, blobDecryptedInfo);
				objParsedInfoEvent = getJSONParsedData(strDecryptedInfo);

				if (!validateParsedEventInfo(objParsedInfoEvent, objFulfillmentSubmitEvent)) {
					continue;
				}

				if (objParsedInfoEvent.enrollment_source != null && HIEnrollmentEventUtility.ENROLLMENT_SOURCE_BoR.equalsIgnoreCase(objParsedInfoEvent.enrollment_source.event_type)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIEnrollmentEventUtility.ENROLLMENT_SOURCE_BOR_MESSAGE, objFulfillmentSubmitEvent);
					map_ValidEvents.remove(objFulfillmentSubmitEvent.Id__c);
					continue;
				}

				Boolean blnQLEEvent = (objParsedInfoEvent.enrollment_source.type == HIEnrollmentEventUtility.EVENT_SOURCE_QLE) ? true : false;
				if (objParsedInfoEvent.enrollment_source != null && objParsedInfoEvent.enrollment_source.type != null) {
					objFulfillmentSubmitEvent.Event_Sub_Type__c = objParsedInfoEvent.enrollment_source.type;
				}

				if (!blnQLEEvent) {
					strCaseType = HIEnrollmentEventUtility.CASE_TYPE_NHE;
				}

				//add all the ZP Compamy id  and Email address of the employee in the set
				set_ZPCompanyId.add(String.valueOf(objParsedInfoEvent.company.id));
				set_EmployeeEmail.add(objParsedInfoEvent.employee.email);
				set_EmployeeIDs.add('' + objParsedInfoEvent.employee.id);

				//get the dependent of employee
				Map<String, List<HISelectionsSubmittedEventJSON.FormInfo>> map_stateCarrierIdForm = new Map<String, List<HISelectionsSubmittedEventJSON.FormInfo>>(); // key is State CarrierId and value is Form

				if (objParsedInfoEvent.forms != null && objParsedInfoEvent.forms.size() > 0) {
					for (HISelectionsSubmittedEventJSON.FormInfo objForm : objParsedInfoEvent.forms) {
						String strKey = '' + objForm.state_carrier_id;
						List<HISelectionsSubmittedEventJSON.FormInfo> list_forms;

						if (map_stateCarrierIdForm.containsKey(strKey)) {
							list_forms = map_stateCarrierIdForm.get(strKey);
						} else {
							list_forms = new List<HISelectionsSubmittedEventJSON.FormInfo>();
						}
						list_forms.add(objForm);
						map_stateCarrierIdForm.put(strKey, list_forms);
						map_stateCarrierForms.put(objFulfillmentSubmitEvent.Id__c + '-' + strKey, list_forms);
					}
				}
				//PII information for each employee
				String strPIIInfo = HIEnrollmentEventUtility.getPIIInformation(objParsedInfoEvent.employee, objParsedInfoEvent.dependents);

				map_Dependents = HIEnrollmentEventUtility.getDependentsMap(objParsedInfoEvent.dependents);

				//get the policy from the JSON
				if (!objParsedInfoEvent.policies.isEmpty()) {
					for (HISelectionsSubmittedEventJSON.PolicyInfo objPolicy : objParsedInfoEvent.policies) {
						map_PolicyId.put('' + objPolicy.id, objPolicy);
					}
				}
				//get the State Carrier from the JSON
				Map<String, String> map_CaseDescriptionPerCarrier = new Map<String, String>(), map_SubscriptionInfoPerCarrier = new Map<String, String>();

				if (!objParsedInfoEvent.state_carriers.isEmpty()) {
					for (HISelectionsSubmittedEventJSON.StateCarrierInfo objStateCarrier : objParsedInfoEvent.state_carriers) {
						if (String.isBlank(objStateCarrier.key)) {
							HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.STATE_CARRIER_KEY_MISSING, objFulfillmentSubmitEvent);
							continue;
						}

						set_StateCarrierKey.add(objStateCarrier.key);
						map_StateCarrier.put('' + objStateCarrier.id, objStateCarrier);
						//CaseDescrption
						String strCaseDescription = '', strGroupIDs = '';
						strCaseDescription = getCaseDescription(objParsedInfoEvent, objStateCarrier, objFulfillmentSubmitEvent.Id__c, map_stateCarrierIdForm);
						map_CaseDescriptionPerCarrier.put(String.valueOf(objStateCarrier.id), strCaseDescription);

						String strSubscriptionInfo = getCaseDescriptionSelectionPolicy(objParsedInfoEvent, objStateCarrier.id, strGroupIDs);
						map_SubscriptionInfoPerCarrier.put(String.valueOf(objStateCarrier.id), strSubscriptionInfo);
					}
				}
				//get the selectionInfo from the JSON
				if (!objParsedInfoEvent.selections.isEmpty()) {
					for (HISelectionsSubmittedEventJSON.SelectionInfo objSelection : objParsedInfoEvent.selections) {
						if (String.isBlank(objSelection.uuid)) {
							HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.UUID_MISSING, objFulfillmentSubmitEvent);
							continue;
						}

						if (HIEnrollmentEventUtility.OPS_OWNER_NEW_RENWALS.equalsIgnoreCase(objSelection.ops_owner)) {
							continue;
						}

						if (objSelection.status != HIEnrollmentEventUtility.ENROLLING_EVENT && !blnQLEEvent) {
							continue;
						}
						map_SelectionInfo.put('' + objSelection.uuid, objSelection);
						set_StartDate.add(Date.valueOf(objSelection.start_date));
						// populate the values in the Case wrapper which is used to save the data

						//State Carrier Key
						String strStateCarrierKey = '';
						String strStateCarrierName = '';

						String strStateCarrierId = '', strPolicyId = '';

						if (objSelection.Status != HIEnrollmentEventUtility.WAIVED_EVENT && objSelection.enrollment_information != null) {
							strStateCarrierId = objSelection.enrollment_information.state_carrier_id != null ? String.valueOf(objSelection.enrollment_information.state_carrier_id) : '';

							strPolicyId = objSelection.enrollment_information.policy_id != null ? String.valueOf(objSelection.enrollment_information.policy_id) : '';
						} else if (objSelection.Status == HIEnrollmentEventUtility.WAIVED_EVENT && objSelection.overlapping_subscription != null) {
							strStateCarrierId = objSelection.overlapping_subscription.state_carrier_id != null ? String.valueOf(objSelection.overlapping_subscription.state_carrier_id) : '';

							strPolicyId = objSelection.overlapping_subscription.policy_id != null ? String.valueOf(objSelection.overlapping_subscription.policy_id) : '';
						}

						if (!map_StateCarrier.isEmpty() && map_StateCarrier.containsKey(strStateCarrierId)) {
							strStateCarrierKey = map_StateCarrier.get(strStateCarrierId).key;
							strStateCarrierName = map_StateCarrier.get(strStateCarrierId).name;
						}

						String strKey = objParsedInfoEvent.employee.id + '~~' + strStateCarrierKey + '~~' + objSelection.start_date;
						CaseDataWrapper objCaseData = null;

						//Get Bot JSON for Each selection.
						String strBOTJson = objSelection.Status != HIEnrollmentEventUtility.WAIVED_EVENT ? getCarrierBotJson(objParsedInfoEvent, objSelection, blbEncryptionKey) : '';

						if (map_CaseDataUsingSelection.containsKey(strKey)) {
							objCaseData = map_CaseDataUsingSelection.get(strKey);

							//if One state carrier having multiple policy. Then this method will be executed and update bot json in wrapper class.
							if (objSelection.Status != HIEnrollmentEventUtility.WAIVED_EVENT && String.isNotBlank(strBOTJson)) {
								objCaseData.strEncryptedJson = String.isNotBlank(objCaseData.strEncryptedJson)
									? updateExistingBotJSON(objCaseData.strEncryptedJson, strBOTJson, blbEncryptionKey)
									: strBOTJson;
							}
						} else {
							String strGroupNumber = '';
							String strPolicyNumber = '';

							if (String.isNotBlank(strPolicyId) && !map_PolicyId.isEmpty() && map_PolicyId.containsKey(strPolicyId)) {
								if (String.isNotBlank(map_PolicyId.get(strPolicyId).group_number)) {
									strGroupNumber = map_PolicyId.get(strPolicyId).group_number;
								}
								if (String.isNotBlank(map_PolicyId.get(strPolicyId).policy_number)) {
									strPolicyNumber = map_PolicyId.get(strPolicyId).policy_number;
								}
							}

							objCaseData = new CaseDataWrapper(
								strStateCarrierKey,
								objParsedInfoEvent.enrollment_source.event_type,
								String.valueOf(objParsedInfoEvent.company.id),
								objParsedInfoEvent.employee.email,
								map_CaseDescriptionPerCarrier.get(strStateCarrierId),
								Date.valueOf(objSelection.start_date),
								'',
								objSelection.ops_owner,
								objParsedInfoEvent,
								strBOTJson,
								'',
								String.valueOf(objParsedInfoEvent.employee.id),
								strGroupNumber,
								strPolicyNumber,
								map_SubscriptionInfoPerCarrier.get(strStateCarrierId),
								strPIIInfo
							);
						}

						if (map_PolicyId.containsKey(strPolicyId)) {
							objCaseData = updateUUIDInCaseData(map_PolicyId.get(strPolicyId), objCaseData, objSelection.uuid);
						}

						map_CaseDataUsingSelection.put(strKey, objCaseData);
					}
				}

				map_EventIdInfo.put(objFulfillmentSubmitEvent.Id__c, objParsedInfoEvent);
			} catch (JSONException objJSONExcep) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objFulfillmentSubmitEvent);
			} catch (Exception e) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EXCEPTION_WHILE_PROCESSING, objFulfillmentSubmitEvent);
				list_Exceptions.add(e);
			}
		}
		try {
			if (!set_ZPCompanyId.isEmpty()) {
				map_Account = HIFulfillmentEventHelperFunctions.getAccounts(set_ZPCompanyId);
				map_BO = HIFulfillmentEventHelperFunctions.getBenefitOrderMap(set_ZPCompanyId);
			}

			if (!set_EmployeeEmail.isEmpty()) {
				map_Contact = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);
			}

			if (!set_StateCarrierKey.isEmpty()) {
				map_Carrier = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_StateCarrierKey);
			}

			//Check whether Contact is present in salesforce or not, if not then create new one
			map_Contact = HIEnrollmentEventUtility.processContactInformation(
				list_HIFulfillmentEvent,
				map_EventIdInfo,
				null,
				map_Account,
				map_Contact,
				set_EmployeeEmail,
				HIEnrollmentEventUtility.ETYPE_SELECTION_SUBMITTED
			);

			if (!map_SelectionInfo.isEmpty()) {
				Map<String, Case> map_ExistingCases = fetchExistingCases(set_EmployeeIDs, set_StateCarrierKey, set_StartDate, strCaseType);
				List<Case> list_CasesToUpsert = createOrUpdateCases(map_ValidEvents.values(), map_ExistingCases, map_Account, map_Contact, map_Carrier, map_CaseDataUsingSelection, map_EventIdInfo);

				if (!list_CasesToUpsert.isEmpty()) {
					HIEnrollmentEventUtility.upsertCasesAndSetProcessingState(map_ValidEvents.values(), list_CasesToUpsert, 'HISelectionSubmittedEvent-processInformation');

					HIEnrollmentEventUtility.createAttachment(list_CasesToUpsert, map_PIIInfo);
				}
			}
		} catch (Exception e) {
			list_Exceptions.add(e);
		}

		//insert Exception log for Exceptions
		if (!list_Exceptions.isEmpty()) {
			ExceptionLogUtil.logException('Error', 'HISelectionSubmittedEvent', 'processInformation', list_Exceptions);
		}
	}
	//Get forms information
	static String getForms(String strSTCarrierId, String strEventId, Map<String, List<HISelectionsSubmittedEventJSON.FormInfo>> map_stateCarrierIdForm) {
		String strFormsInfo = '';

		if (map_stateCarrierIdForm == null || !map_stateCarrierIdForm.containsKey(strSTCarrierId)) {
			strFormsInfo = ' not available';
		} else {
			String strMissingFormAttributes = '';
			Boolean blnFullyMapped = true, blnFitsDependents = true;
			Set<String> set_missingattributes = new Set<String>();

			for (HISelectionsSubmittedEventJSON.FormInfo form : map_stateCarrierIdForm.get(strSTCarrierId)) {
				strFormsInfo += '\n- ' + form.url;

				//Check for form flags, if any of the forms has fully_mapped set to false, it is set as false at case level
				if (blnFullyMapped && (form.fully_mapped == false || form.fully_mapped == null)) {
					blnFullyMapped = false;
				}
				//Check for form flags, if any of the forms has fits dependents set to false, it is set as false at case level
				if (blnFitsDependents && (form.form_includes_all_dependents == false || form.form_includes_all_dependents == null)) {
					blnFitsDependents = false;
				}
				//Get all missing values in forms and store them at case level in comma separated format
				if (form.missing_values_by_path != null && !form.missing_values_by_path.isEmpty()) {
					set_missingattributes.addAll(form.missing_values_by_path);
				}
			}

			if (!set_missingattributes.isEmpty()) {
				List<String> list_MissingFormAttr = new List<String>(set_missingattributes);
				strMissingFormAttributes = String.join(list_MissingFormAttr, ',\n');
			}

			Map<String, Object> map_formMapping = new Map<String, Object>();

			map_formMapping.put('fullymapped', blnFullyMapped);
			map_formMapping.put('missingattributes', strMissingFormAttributes);
			map_formMapping.put('fitsdependents', blnFitsDependents);

			map_stateCarrierIdFormMappings.put(strEventId + '-' + strSTCarrierId, map_formMapping);
		}
		return strFormsInfo;
	}
	static List<Case> createOrUpdateCases(
		List<HI_Fulfillment_Event__c> list_HIEvents,
		Map<String, Case> map_ExistingCases,
		Map<String, Account> map_Account,
		Map<String, Contact> map_Contact,
		Map<String, Carrier__c> map_Carrier,
		Map<String, CaseDataWrapper> map_CaseDataUsingSelection,
		Map<String, HISelectionsSubmittedEventJSON> map_EventIdInfo
	) {
		Blob blbEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Map<String, Case> map_CasesToUpsert = new Map<String, Case>();

		Database.DMLOptions objDMLOption = new Database.DMLOptions(), objDMLOptionEscapeAssignment = new Database.DMLOptions();
		objDMLOption.assignmentRuleHeader.useDefaultRule = true;
		objDMLOptionEscapeAssignment.AssignmentRuleHeader.UseDefaultRule = false;

		for (HI_Fulfillment_Event__c objEvent : list_HIEvents) {
			if (map_EventIdInfo.containsKey(objEvent.Id__c) && !map_Account.isEmpty() && map_Account.containsKey(objEvent.Company_Id__c)) {
				HISelectionsSubmittedEventJSON objParsedInfoEvent = map_EventIdInfo.get(objEvent.Id__c);
				Boolean blnQLEEvent = (objParsedInfoEvent.enrollment_source.type == HIEnrollmentEventUtility.EVENT_SOURCE_QLE) ? true : false;
				for (HISelectionsSubmittedEventJSON.SelectionInfo objSelection : objParsedInfoEvent.selections) {
					if (objSelection.status == HIEnrollmentEventUtility.ENROLLING_EVENT || blnQLEEvent) {
						String strCarrierId = '';

						if (objSelection.Status != HIEnrollmentEventUtility.WAIVED_EVENT && objSelection.enrollment_information != null) {
							strCarrierId = objSelection.enrollment_information.state_carrier_id != null ? String.valueOf(objSelection.enrollment_information.state_carrier_id) : '';
						} else if (objSelection.Status == HIEnrollmentEventUtility.WAIVED_EVENT && objSelection.overlapping_subscription != null) {
							strCarrierId = objSelection.overlapping_subscription.state_carrier_id != null ? String.valueOf(objSelection.overlapping_subscription.state_carrier_id) : '';
						}

						if (String.isBlank(strCarrierId)) {
							continue;
						}

						String strCarrierKey = '';
						Boolean blnBybAutomationAuth = false;
						if (map_StateCarrier?.containsKey(strCarrierId)) {
							HISelectionsSubmittedEventJSON.StateCarrierInfo objCarrierInfo = map_StateCarrier.get(strCarrierId);
							if (objCarrierInfo != null) {
								if (String.isNotBlank(objCarrierInfo.key)) {
									strCarrierKey = objCarrierInfo.key;
								}

								if (objCarrierInfo.byb_automation_authorized != null) {
									blnBybAutomationAuth = Boolean.valueOf(objCarrierInfo.byb_automation_authorized);
								}
							}
						}

						String strKey = objParsedInfoEvent.employee.id + '~~' + strCarrierKey + '~~' + objSelection.start_date;

						if (map_CaseDataUsingSelection == null || !map_CaseDataUsingSelection.containsKey(strKey) || map_CasesToUpsert.containsKey(strKey)) {
							continue;
						}
						Case objCase;
						CaseDataWrapper objWrap = map_CaseDataUsingSelection.get(strKey);

						if (map_ExistingCases != null && map_ExistingCases.containsKey(strKey)) {
							objCase = map_ExistingCases.get(strKey);
							if (objEvent.Event_Type__c == 'selections_submitted') {
								objCase.BYB_Automation_Authorized__c = blnBybAutomationAuth ? blnBybAutomationAuth : objCase.BYB_Automation_Authorized__c;
								objCase.Description = objCase.Description != objWrap.strCaseDescription ? objWrap.strCaseDescription : objCase.Description;
							}
							if (objCase.Special_Instructions__c == null) {
								objCase.Special_Instructions__c = CaseUtils.SPECIAL_INSTRUCTIONS_MESSAGE;
							}

						} else {
							objCase = new Case();
							objCase.RecordTypeId = blnQLEEvent ? HIEnrollmentEventUtility.CASE_RT_ID_MF_QLE : HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE;
							objCase.Type = blnQLEEvent ? HIEnrollmentEventUtility.CASE_TYPE_QLE : HIEnrollmentEventUtility.CASE_TYPE_NHE;
							objCase.Integration_Key__c = objEvent.Id__c + '-' + strCarrierKey;
							objCase.Integration_Id__c = objEvent.Id__c;
							objCase.Anticipated_Effective_Date__c = String.isNotBlank(objSelection.start_date) ? Date.valueOf(objSelection.start_date) : null;
							objCase.MF_Coverage_Start_Date__c = objCase.Anticipated_Effective_Date__c;

							objCase.Enrollment_Source__c = HIEnrollmentEventUtility.EVENT_SOURCE_NHE;
							if (objEvent.Event_Type__c == 'selections_submitted' && blnBybAutomationAuth == true) {
								objCase.BYB_Automation_Authorized__c = blnBybAutomationAuth;
							}
							if (
								objParsedInfoEvent.enrollment_source != null &&
								String.isNotBlank(objParsedInfoEvent.enrollment_source.type) &&
								!HIEnrollmentEventUtility.UNKNOWN_SOURCE.equalsIgnoreCase(objParsedInfoEvent.enrollment_source.type)
							) {
								objCase.Enrollment_Source__c = objParsedInfoEvent.enrollment_source.type;
							}

							objCase.Description = objWrap.strCaseDescription;
							objCase.Opps_Owner__c = objWrap.strOppsOwner;
							map_PIIInfo.put(objCase.Integration_Key__c, objWrap.strPIIInformation);
							Benefit_Order__c objBO;

							if (map_BO != null && map_BO.containsKey(objWrap.strZPCompanyID)) {
								objBO = map_BO.get(objWrap.strZPCompanyID);
								objCase.Benefit_Order__c = objBO.Id;
							}

							if (
								HIEnrollmentEventUtility.OPS_OWNER_BOR.equalsIgnoreCase(objWrap.strOppsOwner) &&
								objBO != null &&
								HIEnrollmentEventUtility.BO_RECORD_TYPE_BENFITS_BOR.equalsIgnoreCase(objBO.RecordType.Name)
							) {
								if (!HIEnrollmentEventUtility.set_CreateCaseForStatus.contains(objBO.Order_Status__c)) {
									objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_BENEFITS_BOR;
									if (String.valueof(objBO.OwnerId).indexOf('00G') < 0) {
										objCase.OwnerId = objBO.OwnerId;
										objCase.setOptions(objDMLOptionEscapeAssignment);
									} else {
										objCase.setOptions(objDMLOption);
									}
								} else {
									objCase.setOptions(objDMLOption);
								}
							} else {
								objCase.setOptions(objDMLOption);
							}
						}
						String strContactKey = objWrap.strZPCompanyID + '-' + objWrap.strEmployeeEmail;

						if (map_Contact == null || (!map_Contact.containsKey(objWrap.strEmployeeEmail) && !map_Contact.containsKey(strContactKey))) {
							HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EMPLOYEE_DOES_NOT_EXIST, objEvent);
							continue;
						}

						if (
							blnQLEEvent &&
							!map_QLEEventType.isEmpty() &&
							String.isNotBlank(objParsedInfoEvent.enrollment_source.event_type) &&
							map_QLEEventType.containsKey(objParsedInfoEvent.enrollment_source.event_type)
						) {
							objCase.QLE_Event_Type__c = map_QLEEventType.get(objParsedInfoEvent.enrollment_source.event_type);
						}

						if (String.isBlank(objCase.Subscription_Information__c)) {
							objCase.Subscription_Information__c = '';
						}
						
						if (objWrap != null && objWrap.strSubscriptionInfo != null && objCase.Subscription_Information__c.indexOf(objWrap.strSubscriptionInfo) == -1) {
							objCase.Subscription_Information__c += objWrap.strSubscriptionInfo;
						}

						objCase.MF_Group_Number__c = objWrap.strGroupNumber;
						objCase.MF_Policy_Number__c = objWrap.strPolicyNumber;

						if (objSelection.Status != HIEnrollmentEventUtility.WAIVED_EVENT) {
							if (String.isBlank(objCase.Fulfillment_Event_Encrypted_JSON__c) || objCase.Id == null) {
								objCase.Fulfillment_Event_Encrypted_JSON__c = objWrap.strEncryptedJson;
							} else {
								//Update existing BOT JSON
								objCase.Fulfillment_Event_Encrypted_JSON__c = updateExistingBotJSON(objCase.Fulfillment_Event_Encrypted_JSON__c, objWrap.strEncryptedJson, blbEncryptionKey);
							}
						}

						objCase.Selection_Ids__c = objWrap.strSelectionIds;
						objCase.Group_Ids__c = objWrap.strGroupIds;
						objCase.Company_ID__c = objWrap.strZPCompanyID;
						objCase.Employee_Ids__c = objWrap.strEmployeeId;
						objCase.Employee_Id__c = objWrap.strEmployeeId;

						if (String.isNotBlank(objParsedInfoEvent.employee.hired_at)) {
							objCase.Hire_Date__c = Date.valueOf(objParsedInfoEvent.employee.hired_at);
						}

						if (String.isNotBlank(objParsedInfoEvent.employee.benefits_eligibility_date)) {
							objCase.Benefits_Eligibility_Date__c = Date.valueOf(objParsedInfoEvent.employee.benefits_eligibility_date);
						}

						if (String.isBlank(objCase.Selection_UUIDs__c)) {
							objCase.Selection_UUIDs__c = '';
						} else if (objCase.Selection_UUIDs__c.right(1) != ';') {
							objCase.Selection_UUIDs__c += ';';
						}

						if (String.isBlank(objCase.Benefit_Types__c)) {
							objCase.Benefit_Types__c = '';
						} else if (objCase.Benefit_Types__c.right(1) != ';') {
							objCase.Benefit_Types__c += ';';
						}

						if (String.isNotBlank(objWrap.strMedicalUUID)) {
							objCase.Medical_UUID__c = objWrap.strMedicalUUID;
							if (objCase.Selection_UUIDs__c.indexOf(objWrap.strMedicalUUID) == -1) {
								objCase.Selection_UUIDs__c += objWrap.strMedicalUUID + ';';
							}

							if (objCase.Benefit_Types__c.indexOf(HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL) == -1) {
								objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL + ';';
							}
						}

						if (String.isNotBlank(objWrap.strDentalUUID)) {
							objCase.Dental_UUID__c = objWrap.strDentalUUID;
							if (objCase.Selection_UUIDs__c.indexOf(objWrap.strDentalUUID) == -1) {
								objCase.Selection_UUIDs__c += objWrap.strDentalUUID + ';';
							}
							if (objCase.Benefit_Types__c.indexOf(HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL) == -1) {
								objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL + ';';
							}
						}

						if (String.isNotBlank(objWrap.strVisionUUID)) {
							objCase.Vision_UUID__c = objWrap.strVisionUUID;
							if (objCase.Selection_UUIDs__c.indexOf(objWrap.strVisionUUID) == -1) {
								objCase.Selection_UUIDs__c += objWrap.strVisionUUID + ';';
							}
							if (objCase.Benefit_Types__c.indexOf(HIEnrollmentEventUtility.BENEFIT_TYPE_VISION) == -1) {
								objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_VISION + ';';
							}
						}

						if (String.isNotBlank(objWrap.strLTDUUID)) {
							objCase.Long_Term_Disability_UUID__c = objWrap.strLTDUUID;
							if (objCase.Selection_UUIDs__c.indexOf(objWrap.strLTDUUID) == -1) {
								objCase.Selection_UUIDs__c += objWrap.strLTDUUID + ';';
							}
							if (objCase.Benefit_Types__c.indexOf(HIEnrollmentEventUtility.BENEFIT_TYPE_LTD) == -1) {
								objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_LTD + ';';
							}
						}

						if (String.isNotBlank(objWrap.strSTDUUID)) {
							objCase.Short_Term_Disability_UUID__c = objWrap.strSTDUUID;
							if (objCase.Selection_UUIDs__c.indexOf(objWrap.strSTDUUID) == -1) {
								objCase.Selection_UUIDs__c += objWrap.strSTDUUID + ';';
							}
							if (objCase.Benefit_Types__c.indexOf(HIEnrollmentEventUtility.BENEFIT_TYPE_STD) != -1) {
								objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_STD + ';';
							}
						}

						if (String.isNotBlank(objWrap.strLifeUUID)) {
							objCase.Life_UUID__c = objWrap.strLifeUUID;
							if (objCase.Selection_UUIDs__c.indexOf(objWrap.strLifeUUID) == -1) {
								objCase.Selection_UUIDs__c += objWrap.strLifeUUID + ';';
							}
							if (objCase.Benefit_Types__c.indexOf(HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE) == -1) {
								objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE + ';';
							}
						}

						objCase.ContactId = (map_Contact.containsKey(objWrap.strEmployeeEmail)) ? map_Contact.get(objWrap.strEmployeeEmail).Id : map_Contact.get(strContactKey).Id;
						objCase.AccountId = map_Account.get(objWrap.strZPCompanyID).Id;
						objCase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(strCarrierKey)) ? map_Carrier.get(strCarrierKey).Id : null;

						String strEventIdStCarrierId = objEvent.Id__c + '-' + strCarrierId;

						if (map_stateCarrierIdFormMappings != null && map_stateCarrierIdFormMappings.containsKey(strEventIdStCarrierId)) {
							Map<String, Object> map_FormMapping = map_stateCarrierIdFormMappings.get(strEventIdStCarrierId);

							if (map_FormMapping != null) {
								if (map_FormMapping.containsKey('fullymapped')) {
									objCase.Form_Fully_Mapped__c = (Boolean) map_FormMapping.get('fullymapped');
								}
								if (map_FormMapping.containsKey('missingattributes')) {
									objCase.Missing_Form_Attributes__c = (String) map_FormMapping.get('missingattributes');
								}
								if (map_FormMapping.containsKey('fitsdependents')) {
									objCase.Form_Fits_Dependents__c = (Boolean) map_FormMapping.get('fitsdependents');
								}
							}
						}

						if (map_stateCarrierForms != null && map_stateCarrierForms.containsKey(strEventIdStCarrierId) && map_stateCarrierForms.get(strEventIdStCarrierId) != null) {
							objCase.Number_of_Forms__c = map_stateCarrierForms.get(strEventIdStCarrierId).size();
						} else {
							objCase.Number_of_Forms__c = 0;
						}

						map_ExistingCases.put(strKey, objCase);
						map_CasesToUpsert.put(strKey, objCase);
					}
				}
			}
		}
		return map_CasesToUpsert.values();
	}
	static Map<String, Case> fetchExistingCases(Set<String> set_EmployeeIds, Set<String> set_StateCarrierKey, Set<Date> set_StartDate, String strCaseType) {
		Map<String, Case> map_ExistingCases = new Map<String, Case>();

		if (!set_EmployeeIds.isEmpty() && !set_StateCarrierKey.isEmpty() && !set_StartDate.isEmpty()) {
			for (Case objCase : [
				SELECT
					Status,
					Medical_UUID__c,
					Life_UUID__c,
					Dental_UUID__c,
					Long_Term_Disability_UUID__c,
					Short_Term_Disability_UUID__c,
					Vision_UUID__c,
					Integration_Key__c,
					Integration_Id__c,
					Employee_Id__c,
					Anticipated_Effective_Date__c,
					Carrier__r.Key__c,
					Selection_UUIDs__c,
					Benefit_Types__c,
					Subscription_Information__c,
					Description,
					Fulfillment_Event_Encrypted_JSON__c,
					OwnerId,
					RecordType.Name,
					Type,
					BYB_Automation_Authorized__c,
					Special_Instructions__c
				FROM Case
				WHERE
					Integration_Key__c != NULL
					AND Carrier__c != NULL
					AND Employee_Id__c != NULL
					AND RecordType.Name IN :HIEnrollmentEventUtility.set_ValidCaseRecTypes
					AND Status IN :HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses
					AND Carrier__r.Key__c IN :set_StateCarrierKey
					AND Employee_Id__c IN :set_EmployeeIds
					AND Anticipated_Effective_Date__c IN :set_StartDate
			]) {
				String strStartDate = String.valueOf(objCase.Anticipated_Effective_Date__c).removeEnd(' 00:00:00');
				String strKey = objCase.Employee_Id__c + '~~' + objCase.Carrier__r.Key__c + '~~' + strStartDate;
				if (!String.isBlank(strCaseType)) {
					if (strCaseType == objCase.Type) {
						map_ExistingCases.put(strKey, objCase);
					}
				} else {
					map_ExistingCases.put(strKey, objCase);
				}
			}
		}
		return map_ExistingCases;
	}

	//check wheather the parsed data is valid or not
	private static Boolean validateParsedEventInfo(HISelectionsSubmittedEventJSON objParsedInfoEvent, HI_Fulfillment_Event__c objFulfillmentEvent) {
		// if JSON is Blank
		if (objParsedInfoEvent == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objFulfillmentEvent);
			return false;
		}
		//if Company id is blank in the JSON
		if (objParsedInfoEvent.company == null || objParsedInfoEvent.company.id == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING, objFulfillmentEvent);
			return false;
		}
		//if Selection is blank
		if (objParsedInfoEvent.selections == null || objParsedInfoEvent.selections.size() == 0) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.SELECTION_INFO_MISSING, objFulfillmentEvent);
			return false;
		}
		//if State Carrier information is blank
		if ((objParsedInfoEvent.State_carriers == null || objParsedInfoEvent.State_carriers.size() == 0)) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.STATE_CARRIER_IS_MISSING, objFulfillmentEvent);
			return false;
		}
		//if Employee Email id is blank
		if (objParsedInfoEvent.employee == null || objParsedInfoEvent.employee.email == null || objParsedInfoEvent.employee.email == '') {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EMAIL_ID_IS_MISSING, objFulfillmentEvent);
			return false;
		}
		return true;
	}

	//calling HISelectionsSubmittedEventJSON class for parsing data
	public static HISelectionsSubmittedEventJSON getJSONParsedData(String strJSONData) {
		HISelectionsSubmittedEventJSON objParsedData = (HISelectionsSubmittedEventJSON) JSON.deserialize(strJSONData, HISelectionsSubmittedEventJSON.class);
		return objParsedData;
	}

	static CaseDataWrapper updateUUIDInCaseData(HISelectionsSubmittedEventJSON.PolicyInfo objPolicyInfo, CaseDataWrapper objCaseData, String strUUID) {
		if (objPolicyInfo != null && String.isNotBlank(objPolicyInfo.benefit_type)) {
			switch on objPolicyInfo.benefit_type {
				when 'medical' {
					objCaseData.strMedicalUUID = strUUID;
				}
				when 'dental' {
					objCaseData.strDentalUUID = strUUID;
				}
				when 'life' {
					objCaseData.strLifeUUID = strUUID;
				}
				when 'vision' {
					objCaseData.strVisionUUID = strUUID;
				}
				when 'long_term_disability' {
					objCaseData.strLTDUUID = strUUID;
				}
				when 'short_term_disability' {
					objCaseData.strSTDUUID = strUUID;
				}
			}
		}
		return objCaseData;
	}

	static string getCaseDescription(
		HISelectionsSubmittedEventJSON objParsedInfoEvent,
		HISelectionsSubmittedEventJSON.StateCarrierInfo objStateCarrier,
		String strEventId,
		Map<String, List<HISelectionsSubmittedEventJSON.FormInfo>> map_stateCarrierIdForm
	) {
		String strCaseDescription = '';
		//State Carrier Key
		String strStateCarrierKey = objStateCarrier.key;
		String strStateCarrierName = objStateCarrier.name;

		//add Event type detail to Case description
		strCaseDescription += HIEnrollmentEventUtility.getEnrollmentSourceInfo(objParsedInfoEvent.enrollment_source);
		strCaseDescription += HIEnrollmentEventUtility.getEmployeeInformation(
			objParsedInfoEvent.employee,
			objParsedInfoEvent.company.name,
			strStateCarrierName,
			objStateCarrier.carrier_enrollment_url
		);

		strCaseDescription += '\n\nPlease submit ALL linked forms to the carrier\nForms' + getForms(String.valueOf(objStateCarrier.id), strEventId, map_stateCarrierIdForm);
		strCaseDescription += '\n\nCarrier';
		strCaseDescription += '\n- Carrier: ' + strStateCarrierName;
		
		return strCaseDescription;
	}

	static string getCaseDescriptionSelectionPolicy(HISelectionsSubmittedEventJSON objParsedInfoEvent, Long strStateCarrier, String strGroupIDs) {
		String strSelectionPolicy = '';

		for (HISelectionsSubmittedEventJSON.SelectionInfo objSelectionInfo : objParsedInfoEvent.selections) {
			//get the policy related to that particular state Carrier
			if (
				objSelectionInfo.enrollment_information != null &&
				objSelectionInfo.enrollment_information.policy_id != null &&
				objSelectionInfo.enrollment_information.state_carrier_id != null &&
				objSelectionInfo.enrollment_information.state_carrier_id == strStateCarrier
			) {
				HISelectionsSubmittedEventJSON.PolicyInfo objPolicy = map_PolicyId.get('' + objSelectionInfo.enrollment_information.policy_id);

				if (objPolicy == null) {
					continue;
				}

				if (objPolicy.group_number != null && objPolicy.group_number != '') {
					if (strGroupIDs != '') {
						strGroupIDs += ',';
					}
					strGroupIDs += objPolicy.group_number;
				}

				strSelectionPolicy += '\n' + objPolicy.benefit_type + ': ' + objPolicy.name;
				strSelectionPolicy += '\n- Estimated Start Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objSelectionInfo.start_date);
				strSelectionPolicy += '\n- Group ID: ' + objPolicy.group_number;
				strSelectionPolicy += '\n- Policy Number: ' + objPolicy.policy_number;

				//get the dependent Count
				Integer intDependentSize = 0;
				if (objSelectionInfo.enrollment_information.dependent_ids != null) {
					intDependentSize = objSelectionInfo.enrollment_information.dependent_ids.size();
				}

				strSelectionPolicy += '\n\n- Number of Active Dependents: ' + intDependentSize;
				strSelectionPolicy += '\n- EE estimated premium: ' + objSelectionInfo.estimated_employee_premium;
				strSelectionPolicy += '\n- Dependents estimated premium: ' + objSelectionInfo.estimated_dependents_premium;
				strSelectionPolicy += '\n- Total estimated premium: ' + objSelectionInfo.estimated_total_premium;
				strSelectionPolicy += '\n' + HIEnrollmentEventUtility.DESC_SEPARATOR;
			}
		}
		return strSelectionPolicy;
	}

	private static String getCarrierBotJson(HISelectionsSubmittedEventJSON selSubmittedJson, HISelectionsSubmittedEventJSON.SelectionInfo objSelection, Blob blbEncryptionKey) {
		String botJsonString = '';

		if (objSelection.enrollment_information != null) {
			Long strStateCarrierId = objSelection.enrollment_information.state_carrier_id;
			String strPolicyStateCarrierId = objSelection.enrollment_information.policy_id;
			HIFulfillmentBotEnrollmentJSON botJson = new HIFulfillmentBotEnrollmentJSON();
			String strBenefitType = '';

			botJson.control_info = new HIFulfillmentBotEnrollmentJSON.control_info();
			botJson.enrollment = new HIFulfillmentBotEnrollmentJSON.enrollment();
			botJson.control_info.case_id = '';
			botJson.recent_qles = new List<HIFulfillmentBotEnrollmentJSON.RecentQle>();
			botJson.carrier_directory = '';
			botJson.employee = (HIFulfillmentBotEnrollmentJSON.employee) System.JSON.deserialize('' + JSON.serialize(selSubmittedJson.employee), HIFulfillmentBotEnrollmentJSON.employee.class);
			botJson.enrollment.employee_id = botJson.employee.id;
			botJson.enrollment.url = botJson.employee.hippo_url;

			botJson.company = (HIFulfillmentBotEnrollmentJSON.company) System.JSON.deserialize('' + JSON.serialize(selSubmittedJson.company), HIFulfillmentBotEnrollmentJSON.company.class);

			for (HISelectionsSubmittedEventJSON.StateCarrierInfo carrier : selSubmittedJson.state_carriers) {
				if (carrier.id == strStateCarrierId) {
					botJson.state_carrier = (HIFulfillmentBotEnrollmentJSON.state_carrier) System.JSON.deserialize('' + JSON.serialize(carrier), HIFulfillmentBotEnrollmentJSON.state_carrier.class);
				}
			}
			botJson.policies = new List<HIFulfillmentBotEnrollmentJSON.Policy>();
			
			for (HISelectionsSubmittedEventJSON.PolicyInfo pol : selSubmittedJson.policies) {
				if (pol.id == strPolicyStateCarrierId) {
					HIFulfillmentBotEnrollmentJSON.Policy newPol = (HIFulfillmentBotEnrollmentJSON.Policy) System.JSON.deserialize(
						'' + JSON.serialize(pol),
						HIFulfillmentBotEnrollmentJSON.Policy.class
					);

					newPol.state_carrier_id = Integer.valueOf(strStateCarrierId);
					botJson.policies.add(newPol);
					//Get benefit type
					strBenefitType = newPol.benefit_type;
				}
			}

			botJson.benefit_items = new HIFulfillmentBotEnrollmentJSON.benefit_items();

			HIFulfillmentBotEnrollmentJSON.SubscriptionInfo objSubscriptionInfo = new HIFulfillmentBotEnrollmentJSON.SubscriptionInfo();
			objSubscriptionInfo.id = objSelection.uuid;
			objSubscriptionInfo.uuid = objSelection.uuid;
			objSubscriptionInfo.url = objSelection.url;
			objSubscriptionInfo.estimated_total_premium = objSelection.estimated_total_premium;
			objSubscriptionInfo.estimated_employee_premium = objSelection.estimated_employee_premium;

			if (String.isNotBlank(objSelection.start_date)) {
				objSubscriptionInfo.start_date = Date.valueOf(objSelection.start_date);
				objSubscriptionInfo.estimated_start_date = objSelection.start_date;
			}

			if (String.isNotBlank(objSelection.end_date)) {
				objSubscriptionInfo.end_date = Date.valueOf(objSelection.end_date);
			}

			objSubscriptionInfo.ops_owner = objSelection.ops_owner;
			objSubscriptionInfo.benefit_type = strBenefitType;
			objSubscriptionInfo.state_carrier_id = Integer.valueOf(strStateCarrierId);
			objSubscriptionInfo.employee_id = selSubmittedJson.employee.id;

			if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL) {
				botJson.benefit_items.medical = objSubscriptionInfo;
			} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL) {
				botJson.benefit_items.dental = objSubscriptionInfo;
			} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_VISION) {
				botJson.benefit_items.vision = objSubscriptionInfo;
			} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE) {
				botJson.benefit_items.life = objSubscriptionInfo;
			} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_LTD_1) {
				botJson.benefit_items.long_term_disability = objSubscriptionInfo;
			} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_STD_1) {
				botJson.benefit_items.short_term_disability = objSubscriptionInfo;
			}

			botJson.dependents = new List<HIFulfillmentBotEnrollmentJSON.Dependent>();
			Set<String> set_dependentId = new Set<String>();

			if (objSelection.enrollment_information != null && objSelection.enrollment_information.dependent_ids != null && objSelection.enrollment_information.dependent_ids.size() > 0) {
				for (String strDepedentId : objSelection.enrollment_information.dependent_ids) {
					if (String.isNotBlank(strDepedentId)) {
						set_dependentId.add(strDepedentId);
					}
				}
			}

			List<String> set_dependentIdToBenfitItem = new List<String>();

			//Using set_dependentId, map dependent in bot json
			if (selSubmittedJson.dependents.size() > 0) {
				botJson.dependents = new List<HIFulfillmentBotEnrollmentJSON.Dependent>();
				for (HIEnrollmentEventUtility.DependentInfo dep : selSubmittedJson.dependents) {
					if (set_dependentId.contains(dep.id)) {
						HIFulfillmentBotEnrollmentJSON.Dependent newDep = (HIFulfillmentBotEnrollmentJSON.Dependent) System.JSON.deserialize(
							'' + JSON.serialize(dep),
							HIFulfillmentBotEnrollmentJSON.Dependent.class
						);
						botJson.dependents.add(newDep);

						set_dependentIdToBenfitItem.add(dep.id);
					}
				}
			}

			objSubscriptionInfo.dependent_ids = set_dependentIdToBenfitItem;
			objSubscriptionInfo.policy_id = strPolicyStateCarrierId;

			botJson.benefits_url = '';
			botJson.enrollments_url = '';

			String signedAt = '';

			for (HISelectionsSubmittedEventJSON.FormInfo frm : selSubmittedJson.forms) {
				if (signedAt == '' && frm.signed_at != null && frm.signed_at != '') {
					signedAt = frm.signed_at;
				}
			}
			botJson.state_carrier.signed_at = signedAt;
			Blob blbBotEncrypted = EncryptionUtils.getEncryptedBlob(blbEncryptionKey, '' + JSON.serialize(botJson));
			botJsonString = EncodingUtil.base64Encode(blbBotEncrypted);
		}
		return botJsonString;
	}

	public static String updateExistingBotJSON(String strExisingBotJson, String strNewBotJson, Blob blbEncryptionKey) {
		//Default value
		String strUpdatedBotJSON = strNewBotJson, strDecryptedInfo = '';
		Blob blbDecryptedInfo;
		HIFulfillmentBotEnrollmentJSON objExistingBOTJSON;

		//Get Existing BOT JSON
		if (String.isNotBlank(strExisingBotJson)) {
			blbDecryptedInfo = EncodingUtil.base64Decode(strExisingBotJson);
			strDecryptedInfo = EncryptionUtils.getDecryptedText(blbEncryptionKey, blbDecryptedInfo);
			objExistingBOTJSON = (HIFulfillmentBotEnrollmentJSON) JSON.deserialize(strDecryptedInfo, HIFulfillmentBotEnrollmentJSON.class);
		} else {
			objExistingBOTJSON = new HIFulfillmentBotEnrollmentJSON();
		}

		//Get Existing New BOT JSON
		blbDecryptedInfo = EncodingUtil.base64Decode(strNewBotJson);
		strDecryptedInfo = EncryptionUtils.getDecryptedText(blbEncryptionKey, blbDecryptedInfo);
		HIFulfillmentBotEnrollmentJSON objNewBOTJSON = (HIFulfillmentBotEnrollmentJSON) JSON.deserialize(strDecryptedInfo, HIFulfillmentBotEnrollmentJSON.class);

		//This if condition check, existing json is in proper format.
		if (objExistingBOTJSON.employee != null && objExistingBOTJSON.employee.id != null) {
			//fetch policy from existing bot json
			Set<String> set_ExistingPolicy = new Set<String>();
			if (objExistingBOTJSON.policies == null) {
				objExistingBOTJSON.policies = new List<HIFulfillmentBotEnrollmentJSON.Policy>();
			}
			if (objExistingBOTJSON.policies.size() > 0) {
				for (HIFulfillmentBotEnrollmentJSON.Policy objPolicy : objExistingBOTJSON.policies) {
					set_ExistingPolicy.add(objPolicy.id);
				}
			}
			//fetch dependents from existing bot json
			Set<String> set_dependents = new Set<String>();
			if (objExistingBOTJSON.dependents == null) {
				objExistingBOTJSON.dependents = new List<HIFulfillmentBotEnrollmentJSON.Dependent>();
			}
			if (objExistingBOTJSON.dependents.size() > 0) {
				for (HIFulfillmentBotEnrollmentJSON.Dependent objDependent : objExistingBOTJSON.dependents) {
					set_dependents.add(objDependent.id);
				}
			}

			//Update policy, dependent and benefit_item in existing bot json
			String strBenefitType = '';
			if (objNewBOTJSON.policies != null && objNewBOTJSON.policies.size() > 0) {
				if (objExistingBOTJSON.benefit_items == null) {
					objExistingBOTJSON.benefit_items = new HIFulfillmentBotEnrollmentJSON.benefit_items();
				}
				for (HIFulfillmentBotEnrollmentJSON.Policy objPolicy : objNewBOTJSON.policies) {
					if (!set_ExistingPolicy.contains(objPolicy.id)) {
						objExistingBOTJSON.policies.add(objPolicy);
						strBenefitType = objPolicy.benefit_type;

						if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL) {
							objExistingBOTJSON.benefit_items.medical = objNewBOTJSON.benefit_items.medical;
						} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL) {
							objExistingBOTJSON.benefit_items.dental = objNewBOTJSON.benefit_items.dental;
						} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_VISION) {
							objExistingBOTJSON.benefit_items.vision = objNewBOTJSON.benefit_items.vision;
						} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE) {
							objExistingBOTJSON.benefit_items.life = objNewBOTJSON.benefit_items.life;
						} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_LTD_1) {
							objExistingBOTJSON.benefit_items.long_term_disability = objNewBOTJSON.benefit_items.long_term_disability;
						} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_STD_1) {
							objExistingBOTJSON.benefit_items.short_term_disability = objNewBOTJSON.benefit_items.short_term_disability;
						}
					}
				}

				if (objNewBOTJSON.dependents != null && objNewBOTJSON.dependents.size() > 0) {
					for (HIFulfillmentBotEnrollmentJSON.Dependent objDependent : objNewBOTJSON.dependents) {
						if (!set_dependents.contains(objDependent.id)) {
							objExistingBOTJSON.dependents.add(objDependent);
						}
					}
				}

				Blob blbBotEncrypted = EncryptionUtils.getEncryptedBlob(blbEncryptionKey, '' + JSON.serialize(objExistingBOTJSON));
				strUpdatedBotJSON = EncodingUtil.base64Encode(blbBotEncrypted);
			}
		}

		return strUpdatedBotJSON;
	}

	public class CaseDataWrapper {
		public String strMedicalUUID;
		public String strLifeUUID;
		public String strDentalUUID;
		public String strVisionUUID;
		public String strLTDUUID;
		public String strSTDUUID;
		public String strStateCarrierKey;
		public String strEventType;
		public String strZPCompanyID;
		public String strEmployeeEmail;
		public String strEmployeeId;
		public String strCaseDescription;
		public String strSubscriptionInfo;
		public Date strEffectiveDate;
		public String strGroupIds;
		public String strOppsOwner;
		public HISelectionsSubmittedEventJSON objHIEventInfo;
		public String strEncryptedJson;
		public String strSelectionIds;
		public String strGroupNumber;
		public String strPolicyNumber;
		public String strPIIInformation;

		public CaseDataWrapper(
			String strStateCarrierKeyTemp,
			String strEventTypeTemp,
			String strZPCompanyIDTemp,
			String strEmployeeEmailTemp,
			String strCaseDescriptionTemp,
			Date strEffectiveDateTemp,
			String strGroupIdsTemp,
			String strOppsOwnerTemp,
			HISelectionsSubmittedEventJSON objHIEventInfoTemp,
			String strEncryptedJsonTemp,
			String strSelectionIdsTemp,
			String strEmployeeIdTemp,
			String strGroupNumberTemp,
			String strPolicyNumberTemp,
			String strSubscriptionInfo,
			String strPIIInfo
		) {
			this.strStateCarrierKey = strStateCarrierKeyTemp;
			this.strEventType = strEventTypeTemp;
			this.strZPCompanyID = strZPCompanyIDTemp;
			this.strEmployeeEmail = strEmployeeEmailTemp;
			this.strEmployeeId = strEmployeeIdTemp;
			this.strCaseDescription = strCaseDescriptionTemp;
			this.strEffectiveDate = strEffectiveDateTemp;
			this.strGroupIds = strGroupIdsTemp;
			this.strOppsOwner = strOppsOwnerTemp;
			this.objHIEventInfo = objHIEventInfoTemp;
			this.strEncryptedJson = strEncryptedJsonTemp;
			this.strSelectionIds = strSelectionIdsTemp;
			this.strGroupNumber = strGroupNumberTemp;
			this.strPolicyNumber = strPolicyNumberTemp;
			this.strSubscriptionInfo = strSubscriptionInfo;
			this.strPIIInformation = strPIIInfo;
		}
	}
}