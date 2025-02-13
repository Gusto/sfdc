/**
 * @name         HIContinuationElectionEvent
 * @test class   HIContinuationElectionEventTest
 * @author		 Bhagat Singh
 * @date         6th April 2021
 * @description  Process Continuation Election Events and update/create relevant cases.
 * @revisions    Date ------------ Name ------------ Comments
 */
public class HIContinuationElectionEvent {
	public static final String FULLY_MAPPED = 'fullymapped';
	public static final String MISSING_ATTRIBUTE = 'missingattributes';
	public static final String FIRST_DEPENDENT = 'fitsdependents';
	static Map<String, HIEnrollmentEventUtility.DependentInfo> map_Dependents = new Map<String, HIEnrollmentEventUtility.DependentInfo>();
	static Map<String, HIContinuationElectionEventJSON.PolicyInfo> map_PolicyIds = new Map<String, HIContinuationElectionEventJSON.PolicyInfo>();
	static Map<String, HIContinuationElectionEventJSON.StateCarrierInfo> map_StateCarriers = new Map<String, HIContinuationElectionEventJSON.StateCarrierInfo>();
	static Map<String, List<HIContinuationElectionEventJSON.FormInfo>> map_StateCarrierForms = new Map<String, List<HIContinuationElectionEventJSON.FormInfo>>();
	static Map<String, Map<String, Object>> map_StateCarrierIdFormMappings = new Map<String, Map<String, Object>>();
	static Map<String, Benefit_Order__c> map_BOs = new Map<String, Benefit_Order__c>();
	static Map<String, String> map_PIIInfos = new Map<String, String>();
	static Blob blbEncryptionKey = EncryptionUtils.getEncryptionKey('Master');

	public static void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents) {
		List<Exception> list_Exceptions = new List<Exception>();
		Set<String> set_ZPCompanyIds = new Set<String>();
		Set<String> set_EmployeeEmails = new Set<String>();
		Set<String> set_StateCarrierKeys = new Set<String>();
		Set<String> set_EmployeeIDs = new Set<String>();
		Set<Date> set_StartDates = new Set<Date>();
		Map<String, Account> map_Accounts = new Map<String, Account>();
		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		Map<String, Carrier__c> map_Carriers = new Map<String, Carrier__c>();
		Map<String, HIContinuationElectionEventJSON> map_EventIdInfos = new Map<String, HIContinuationElectionEventJSON>();
		Map<String, HIContinuationElectionEventJSON.SubscriptionsInfo> map_SubscriptionsInfos = new Map<String, HIContinuationElectionEventJSON.SubscriptionsInfo>();
		Map<String, CaseDataWrapper> map_CaseDataUsingSelections = new Map<String, CaseDataWrapper>();
		map_PIIInfos = new Map<String, String>();

		if (list_HIFulfillmentEvents == null || list_HIFulfillmentEvents.isEmpty()) {
			return;
		}

		Map<String, HI_Fulfillment_Event__c> map_ValidEvents = HIEnrollmentEventUtility.validateAndSetProcessingState(
			list_HIFulfillmentEvents
		);

		if (map_ValidEvents.isEmpty()) {
			return;
		}

		map_StateCarrierIdFormMappings = new Map<String, Map<String, Object>>();
		map_StateCarrierForms = new Map<String, List<HIContinuationElectionEventJSON.FormInfo>>();

		for (HI_Fulfillment_Event__c objFulfillmentSubmitEvent : map_ValidEvents.values()) {
			HIContinuationElectionEventJSON objParsedInfoEvent;

			try {
				Blob blobDecryptedInfo = EncodingUtil.base64Decode(
					objFulfillmentSubmitEvent.Event_Info_Encrypted__c
				);
				String strDecryptedInfo = EncryptionUtils.getDecryptedText(
					HIContinuationElectionEvent.blbEncryptionKey,
					blobDecryptedInfo
				);
				objParsedInfoEvent = getJSONParsedData(strDecryptedInfo);

				if (!validateParsedEventInfo(objParsedInfoEvent, objFulfillmentSubmitEvent)) {
					continue;
				}

				set_ZPCompanyIds.add(String.valueOf(objParsedInfoEvent.company.id));
				set_EmployeeEmails.add(objParsedInfoEvent.employee.email);
				set_EmployeeIDs.add('' + objParsedInfoEvent.employee.id);
				Map<String, List<HIContinuationElectionEventJSON.FormInfo>> map_StateCarrierIdForms = new Map<String, List<HIContinuationElectionEventJSON.FormInfo>>(); // key is State CarrierId and value is Form

				if (objParsedInfoEvent.forms != null && objParsedInfoEvent.forms.size() > 0) {
					for (HIContinuationElectionEventJSON.FormInfo objForm : objParsedInfoEvent.forms) {
						String strKey = '' + objForm.state_carrier_id;
						List<HIContinuationElectionEventJSON.FormInfo> list_forms;

						if (map_StateCarrierIdForms.containsKey(strKey)) {
							list_forms = map_StateCarrierIdForms.get(strKey);
						} else {
							list_forms = new List<HIContinuationElectionEventJSON.FormInfo>();
						}

						list_forms.add(objForm);
						map_StateCarrierIdForms.put(strKey, list_forms);
						map_StateCarrierForms.put(objFulfillmentSubmitEvent.Id__c + '-' + strKey, list_forms);
					}
				}

				String strPIIInfo = HIEnrollmentEventUtility.getPIIInformation(
					objParsedInfoEvent.employee,
					objParsedInfoEvent.dependents
				);
				map_Dependents = HIEnrollmentEventUtility.getDependentsMap(objParsedInfoEvent.dependents);

				if (!objParsedInfoEvent.policies.isEmpty()) {
					for (HIContinuationElectionEventJSON.PolicyInfo objPolicy : objParsedInfoEvent.policies) {
						map_PolicyIds.put('' + objPolicy.id, objPolicy);
					}
				}

				Map<String, String> map_CaseDescriptionPerCarriers = new Map<String, String>();
				Map<String, String> map_SubscriptionInfoPerCarriers = new Map<String, String>();

				if (!objParsedInfoEvent.state_carriers.isEmpty()) {
					for (
						HIContinuationElectionEventJSON.StateCarrierInfo objStateCarrier : objParsedInfoEvent.state_carriers
					) {
						if (String.isBlank(objStateCarrier.key)) {
							HIFulfillmentEventTriggerHelper.setProcessingState(
								IntegrationUtils.ERROR_STATE,
								HIEnrollmentEventUtility.STATE_CARRIER_KEY_MISSING,
								objFulfillmentSubmitEvent
							);
							continue;
						}

						set_StateCarrierKeys.add(objStateCarrier.key);
						map_StateCarriers.put('' + objStateCarrier.id, objStateCarrier);
						String strCaseDescription = '';
						String strGroupIDs = '';
						strCaseDescription = getCaseDescription(
							objParsedInfoEvent,
							objStateCarrier,
							objFulfillmentSubmitEvent.Id__c,
							map_StateCarrierIdForms
						);
						map_CaseDescriptionPerCarriers.put(
							String.valueOf(objStateCarrier.id),
							strCaseDescription
						);

						String strSubscriptionInfo = getCaseDescriptionSelectionPolicy(
							objParsedInfoEvent,
							objStateCarrier.id,
							strGroupIDs
						);
						map_SubscriptionInfoPerCarriers.put(
							String.valueOf(objStateCarrier.id),
							strSubscriptionInfo
						);
					}
				}

				if (!objParsedInfoEvent.continuation_subscriptions.isEmpty()) {
					for (
						HIContinuationElectionEventJSON.SubscriptionsInfo objSelection : objParsedInfoEvent.continuation_subscriptions
					) {
						map_SubscriptionsInfos.put(
							'' + objSelection.enrollment_information.state_carrier_id,
							objSelection
						);
						set_StartDates.add(Date.valueOf(objSelection.start_date));

						String strStateCarrierKey = '';
						String strStateCarrierName = '';
						String strStateCarrierId = '';
						String strPolicyId = '';

						if (objSelection.enrollment_information != null) {
							strStateCarrierId = objSelection.enrollment_information.state_carrier_id != null
								? String.valueOf(objSelection.enrollment_information.state_carrier_id)
								: '';

							strPolicyId = objSelection.enrollment_information.policy_id != null
								? String.valueOf(objSelection.enrollment_information.policy_id)
								: '';
						}

						if (!map_StateCarriers.isEmpty() && map_StateCarriers.containsKey(strStateCarrierId)) {
							strStateCarrierKey = map_StateCarriers.get(strStateCarrierId).key;
							strStateCarrierName = map_StateCarriers.get(strStateCarrierId).name;
						}

						String strKey =
							objParsedInfoEvent.employee.id +
							'~~' +
							strStateCarrierKey +
							'~~' +
							objSelection.start_date;
						CaseDataWrapper objCaseData = null;

						String strBOTJson = '';

						if (map_CaseDataUsingSelections.containsKey(strKey)) {
							objCaseData = map_CaseDataUsingSelections.get(strKey);
						} else {
							String strGroupNumber = '';
							String strPolicyNumber = '';

							if (
								String.isNotBlank(strPolicyId) &&
								!map_PolicyIds.isEmpty() &&
								map_PolicyIds.containsKey(strPolicyId)
							) {
								if (String.isNotBlank(map_PolicyIds.get(strPolicyId).group_number)) {
									strGroupNumber = map_PolicyIds.get(strPolicyId).group_number;
								}

								if (String.isNotBlank(map_PolicyIds.get(strPolicyId).policy_number)) {
									strPolicyNumber = map_PolicyIds.get(strPolicyId).policy_number;
								}
							}

							objCaseData = new CaseDataWrapper(
								strStateCarrierKey,
								'',
								String.valueOf(objParsedInfoEvent.company.id),
								objParsedInfoEvent.employee.email,
								map_CaseDescriptionPerCarriers.get(strStateCarrierId),
								Date.valueOf(objSelection.start_date),
								'',
								'',
								objParsedInfoEvent,
								strBOTJson,
								'',
								String.valueOf(objParsedInfoEvent.employee.id),
								strGroupNumber,
								strPolicyNumber,
								map_SubscriptionInfoPerCarriers.get(strStateCarrierId),
								strPIIInfo
							);
						}
						map_CaseDataUsingSelections.put(strKey, objCaseData);
					}
				}

				map_EventIdInfos.put(objFulfillmentSubmitEvent.Id__c, objParsedInfoEvent);
			} catch (JSONException objJSONExcep) {
				HIFulfillmentEventTriggerHelper.setProcessingState(
					IntegrationUtils.ERROR_STATE,
					HIEnrollmentEventUtility.JSON_IS_INVALID,
					objFulfillmentSubmitEvent
				);
			} catch (Exception objException) {
				HIFulfillmentEventTriggerHelper.setProcessingState(
					IntegrationUtils.ERROR_STATE,
					HIEnrollmentEventUtility.EXCEPTION_WHILE_PROCESSING,
					objFulfillmentSubmitEvent
				);

				list_Exceptions.add(objException);
			}
		}

		try {
			if (!set_ZPCompanyIds.isEmpty()) {
				map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_ZPCompanyIds);
				map_BOs = HIFulfillmentEventHelperFunctions.getBenefitOrderMap(set_ZPCompanyIds);
			}

			if (!set_EmployeeEmails.isEmpty()) {
				map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmails);
			}

			if (!set_StateCarrierKeys.isEmpty()) {
				map_Carriers = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_StateCarrierKeys);
			}

			map_Contacts = HIContinuationElectionEvent.processContactInformation(
				list_HIFulfillmentEvents,
				map_EventIdInfos,
				map_Accounts,
				map_Contacts,
				set_EmployeeEmails,
				HIEnrollmentEventUtility.HI_EVENT_CONTINUATION_ELECTION
			);

			if (!map_SubscriptionsInfos.isEmpty()) {
				Map<String, Case> map_ExistingCases = fetchExistingCases(
					set_EmployeeIDs,
					set_StateCarrierKeys,
					set_StartDates
				);

				List<Case> list_CasesToUpsert = createOrUpdateCases(
					map_ValidEvents.values(),
					map_ExistingCases,
					map_Accounts,
					map_Contacts,
					map_Carriers,
					map_CaseDataUsingSelections,
					map_EventIdInfos
				);

				if (!list_CasesToUpsert.isEmpty()) {
					HIEnrollmentEventUtility.upsertCasesAndSetProcessingState(
						map_ValidEvents.values(),
						list_CasesToUpsert,
						'HIContinuationElectionEvent-processInformation'
					);

					HIEnrollmentEventUtility.createAttachment(list_CasesToUpsert, map_PIIInfos);
				}
			}
		} catch (Exception objException) {
			list_Exceptions.add(objException);
		}

		if (!list_Exceptions.isEmpty()) {
			ExceptionLogUtil.logException(
				'Error',
				'HIContinuationElectionEvent',
				'processInformation',
				list_Exceptions
			);
		}
	}

	static String getForms(
		String strSTCarrierId,
		String strEventId,
		Map<String, List<HIContinuationElectionEventJSON.FormInfo>> map_StateCarrierIdForms
	) {
		String strFormsInfo = '';

		if (map_StateCarrierIdForms == null || !map_StateCarrierIdForms.containsKey(strSTCarrierId)) {
			strFormsInfo = ' not available';
		} else {
			String strMissingFormAttributes = '';
			Boolean blnFullyMapped = true;
			Boolean blnFitsDependents = true;
			Set<String> set_MissingAttributes = new Set<String>();

			for (
				HIContinuationElectionEventJSON.FormInfo objFormInfo : map_StateCarrierIdForms.get(strSTCarrierId)
			) {
				strFormsInfo += '\n- ' + objFormInfo.url;

				if (blnFullyMapped && (objFormInfo.fully_mapped == false || objFormInfo.fully_mapped == null)) {
					blnFullyMapped = false;
				}

				if (
					blnFitsDependents &&
					(objFormInfo.form_includes_all_dependents == false ||
					objFormInfo.form_includes_all_dependents == null)
				) {
					blnFitsDependents = false;
				}

				if (objFormInfo.missing_values_by_path != null && !objFormInfo.missing_values_by_path.isEmpty()) {
					set_MissingAttributes.addAll(objFormInfo.missing_values_by_path);
				}
			}

			if (!set_MissingAttributes.isEmpty()) {
				List<String> list_MissingFormTags = new List<String>(set_MissingAttributes);
				strMissingFormAttributes = String.join(list_MissingFormTags, ',\n');
			}

			Map<String, Object> map_FormMappings = new Map<String, Object>();
			map_FormMappings.put(FULLY_MAPPED, blnFullyMapped);
			map_FormMappings.put(MISSING_ATTRIBUTE, strMissingFormAttributes);
			map_FormMappings.put(FIRST_DEPENDENT, blnFitsDependents);

			map_StateCarrierIdFormMappings.put(strEventId + '-' + strSTCarrierId, map_FormMappings);
		}

		return strFormsInfo;
	}

	static List<Case> createOrUpdateCases(
		List<HI_Fulfillment_Event__c> list_HIEvents,
		Map<String, Case> map_ExistingCases,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Map<String, Carrier__c> map_Carriers,
		Map<String, CaseDataWrapper> map_CaseDataUsingSelections,
		Map<String, HIContinuationElectionEventJSON> map_EventIdInfos
	) {
		Map<String, Case> map_CasesToUpsert = new Map<String, Case>();
		Database.DMLOptions objDMLOption = new Database.DMLOptions();
		Database.DMLOptions objDMLOptionEscapeAssignment = new Database.DMLOptions();
		objDMLOption.assignmentRuleHeader.useDefaultRule = true;
		objDMLOptionEscapeAssignment.assignmentRuleHeader.useDefaultRule = false;

		for (HI_Fulfillment_Event__c objEvent : list_HIEvents) {
			if (
				map_EventIdInfos.containsKey(objEvent.Id__c) &&
				!map_Accounts.isEmpty() &&
				map_Accounts.containsKey(objEvent.Company_Id__c)
			) {
				HIContinuationElectionEventJSON objParsedInfoEvent = map_EventIdInfos.get(objEvent.Id__c);

				for (
					HIContinuationElectionEventJSON.SubscriptionsInfo objSelection : objParsedInfoEvent.continuation_subscriptions
				) {
					String strCarrierId = '';

					if (objSelection.enrollment_information != null) {
						strCarrierId = objSelection.enrollment_information.state_carrier_id != null
							? String.valueOf(objSelection.enrollment_information.state_carrier_id)
							: '';
					}

					if (String.isBlank(strCarrierId)) {
						continue;
					}

					String strCarrierKey = (map_StateCarriers != null &&
						map_StateCarriers.containsKey(strCarrierId))
						? map_StateCarriers.get(strCarrierId).key
						: '';
					String strKey =
						objParsedInfoEvent.employee.id +
						'~~' +
						strCarrierKey +
						'~~' +
						objSelection.start_date;

					if (
						map_CaseDataUsingSelections == null ||
						!map_CaseDataUsingSelections.containsKey(strKey) ||
						map_CasesToUpsert.containsKey(strKey)
					) {
						continue;
					}

					Case objCase;
					CaseDataWrapper objWrap = map_CaseDataUsingSelections.get(strKey);

					if (map_ExistingCases != null && map_ExistingCases.containsKey(strKey)) {
						objCase = map_ExistingCases.get(strKey);

					} else {
						objCase = new Case();
						objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE;

						objCase.Type = HIEnrollmentEventUtility.CASE_TYPE_CONTINUATION_ENROLLMENT;

						objCase.Integration_Key__c = objEvent.Id__c + '-' + strCarrierKey;
						objCase.Integration_Id__c = objEvent.Id__c;
						objCase.Anticipated_Effective_Date__c = String.isNotBlank(objSelection.start_date)
							? Date.valueOf(objSelection.start_date)
							: null;
						objCase.MF_Coverage_Start_Date__c = objCase.Anticipated_Effective_Date__c;

						objCase.Description = objWrap.strCaseDescription;

						objCase.Opps_Owner__c = objWrap.strOppsOwner;
						objCase.setOptions(objDMLOption);
						map_PIIInfos.put(objCase.Integration_Key__c, objWrap.strPIIInformation);

						Benefit_Order__c objBO;

						if (map_BOs != null && map_BOs.containsKey(objWrap.strZPCompanyID)) {
							objBO = map_BOs.get(objWrap.strZPCompanyID);
							objCase.Benefit_Order__c = objBO.Id;
						}

						if (
							HIEnrollmentEventUtility.OPS_OWNER_BOR.equalsIgnoreCase(objWrap.strOppsOwner) &&
							objBO != null &&
							HIEnrollmentEventUtility.BO_RECORD_TYPE_BENFITS_BOR.equalsIgnoreCase(
								objBO.RecordType.Name
							)
						) {
							if (
								!HIEnrollmentEventUtility.set_CreateCaseForStatus.contains(
									objBO.Order_Status__c
								)
							) {
								objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_BENEFITS_BOR;

								if (String.valueof(objBO.OwnerId).indexOf('00G') < 0) {
									objCase.OwnerId = objBO.OwnerId;
									objCase.setOptions(objDMLOptionEscapeAssignment);
								}
							}
						}
					}

					String strContactKey = objWrap.strZPCompanyID + '-' + objWrap.strEmployeeEmail;
					if (
						map_Contacts == null ||
						(!map_Contacts.containsKey(objWrap.strEmployeeEmail) &&
						!map_Contacts.containsKey(strContactKey))
					) {
						HIFulfillmentEventTriggerHelper.setProcessingState(
							IntegrationUtils.ERROR_STATE,
							HIEnrollmentEventUtility.EMPLOYEE_DOES_NOT_EXIST,
							objEvent
						);
						continue;
					}

					if (String.isBlank(objCase.Subscription_Information__c)) {
						objCase.Subscription_Information__c = '';
					}

					if (objCase.Subscription_Information__c.indexOf(objWrap.strSubscriptionInfo) == -1) {
						objCase.Subscription_Information__c += objWrap.strSubscriptionInfo;
					}

					objCase.MF_Group_Number__c = objWrap.strGroupNumber;
					objCase.MF_Policy_Number__c = objWrap.strPolicyNumber;

					objCase.Selection_Ids__c = objWrap.strSelectionIds;
					objCase.Group_Ids__c = objWrap.strGroupIds;
					objCase.Company_ID__c = objWrap.strZPCompanyID;
					objCase.Employee_Ids__c = objWrap.strEmployeeId;
					objCase.Employee_Id__c = objWrap.strEmployeeId;

					if (String.isNotBlank(objParsedInfoEvent.employee.hired_at)) {
						objCase.Hire_Date__c = Date.valueOf(objParsedInfoEvent.employee.hired_at);
					}

					if (String.isNotBlank(objParsedInfoEvent.employee.benefits_eligibility_date)) {
						objCase.Benefits_Eligibility_Date__c = Date.valueOf(
							objParsedInfoEvent.employee.benefits_eligibility_date
						);
					}

					if (String.isBlank(objCase.Benefit_Types__c)) {
						objCase.Benefit_Types__c = '';
					} else if (objCase.Benefit_Types__c.right(1) != ';') {
						objCase.Benefit_Types__c += ';';
					}

					objCase.ContactId = (map_Contacts.containsKey(objWrap.strEmployeeEmail))
						? map_Contacts.get(objWrap.strEmployeeEmail).Id
						: map_Contacts.get(strContactKey).Id;
					objCase.AccountId = map_Accounts.get(objWrap.strZPCompanyID).Id;
					objCase.Carrier__c = (map_Carriers != null && map_Carriers.containsKey(strCarrierKey))
						? map_Carriers.get(strCarrierKey).Id
						: null;

					String strEventIdStCarrierId = objEvent.Id__c + '-' + strCarrierId;

					if (
						map_StateCarrierIdFormMappings != null &&
						map_StateCarrierIdFormMappings.containsKey(strEventIdStCarrierId)
					) {
						Map<String, Object> map_FormMapping = map_StateCarrierIdFormMappings.get(
							strEventIdStCarrierId
						);

						if (map_FormMapping != null) {
							if (map_FormMapping.containsKey(FULLY_MAPPED)) {
								objCase.Form_Fully_Mapped__c = (Boolean) map_FormMapping.get(FULLY_MAPPED);
							}

							if (map_FormMapping.containsKey(MISSING_ATTRIBUTE)) {
								objCase.Missing_Form_Attributes__c = (String) map_FormMapping.get(
									MISSING_ATTRIBUTE
								);
							}

							if (map_FormMapping.containsKey(FIRST_DEPENDENT)) {
								objCase.Form_Fits_Dependents__c = (Boolean) map_FormMapping.get(
									FIRST_DEPENDENT
								);
							}
						}
					}

					objCase.Number_of_Forms__c = 0;

					if (
						map_StateCarrierForms != null &&
						map_StateCarrierForms.containsKey(strEventIdStCarrierId) &&
						map_StateCarrierForms.get(strEventIdStCarrierId) != null
					) {
						objCase.Number_of_Forms__c = map_StateCarrierForms.get(strEventIdStCarrierId).size();
					}

					map_ExistingCases.put(strKey, objCase);
					map_CasesToUpsert.put(strKey, objCase);
				}
			}
		}

		return map_CasesToUpsert.values();
	}

	static Map<String, Case> fetchExistingCases(
		Set<String> set_EmployeeIds,
		Set<String> set_StateCarrierKeys,
		Set<Date> set_StartDates
	) {
		Map<String, Case> map_ExistingCases = new Map<String, Case>();

		if (!set_EmployeeIds.isEmpty() && !set_StateCarrierKeys.isEmpty() && !set_StartDates.isEmpty()) {
			for (Case objCase : [
				SELECT
					Status,
					Integration_Key__c,
					Employee_Id__c,
					Anticipated_Effective_Date__c,
					Carrier__r.Key__c,
					Benefit_Types__c,
					Subscription_Information__c,
					Description,
					Fulfillment_Event_Encrypted_JSON__c,
					OwnerId
				FROM Case
				WHERE
					Integration_Key__c != NULL
					AND Carrier__c != NULL
					AND Employee_Id__c != NULL
					AND Status != NULL
					AND Carrier__r.Key__c != NULL
					AND Anticipated_Effective_Date__c != NULL
					AND RecordTypeId = :HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE
					AND Status IN :HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses
					AND Carrier__r.Key__c IN :set_StateCarrierKeys
					AND Employee_Id__c IN :set_EmployeeIds
					AND Anticipated_Effective_Date__c IN :set_StartDates
			]) {
				String strStartDate = String.valueOf(objCase.Anticipated_Effective_Date__c).removeEnd(' 00:00:00');
				String strKey = objCase.Employee_Id__c + '~~' + objCase.Carrier__r.Key__c + '~~' + strStartDate;
				map_ExistingCases.put(strKey, objCase);
			}
		}

		return map_ExistingCases;
	}

	private static Boolean validateParsedEventInfo(
		HIContinuationElectionEventJSON objParsedInfoEvent,
		HI_Fulfillment_Event__c objFulfillmentEvent
	) {
		if (objParsedInfoEvent == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(
				IntegrationUtils.ERROR_STATE,
				HIEnrollmentEventUtility.JSON_IS_INVALID,
				objFulfillmentEvent
			);
			return false;
		}

		if (objParsedInfoEvent.company == null || objParsedInfoEvent.company.id == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(
				IntegrationUtils.ERROR_STATE,
				HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING,
				objFulfillmentEvent
			);
			return false;
		}

		if (
			objParsedInfoEvent.continuation_subscriptions == null ||
			objParsedInfoEvent.continuation_subscriptions.size() == 0
		) {
			HIFulfillmentEventTriggerHelper.setProcessingState(
				IntegrationUtils.ERROR_STATE,
				HIEnrollmentEventUtility.SELECTION_INFO_MISSING,
				objFulfillmentEvent
			);
			return false;
		}

		if ((objParsedInfoEvent.State_carriers == null || objParsedInfoEvent.State_carriers.size() == 0)) {
			HIFulfillmentEventTriggerHelper.setProcessingState(
				IntegrationUtils.DEAD_STATE,
				HIEnrollmentEventUtility.STATE_CARRIER_IS_MISSING,
				objFulfillmentEvent
			);
			return false;
		}

		if (
			objParsedInfoEvent.employee == null ||
			objParsedInfoEvent.employee.email == null ||
			objParsedInfoEvent.employee.email == ''
		) {
			HIFulfillmentEventTriggerHelper.setProcessingState(
				IntegrationUtils.ERROR_STATE,
				HIEnrollmentEventUtility.EMAIL_ID_IS_MISSING,
				objFulfillmentEvent
			);
			return false;
		}

		return true;
	}

	public static HIContinuationElectionEventJSON getJSONParsedData(String strJSONData) {
		HIContinuationElectionEventJSON objParsedData = (HIContinuationElectionEventJSON) JSON.deserialize(
			strJSONData,
			HIContinuationElectionEventJSON.class
		);

		return objParsedData;
	}

	static string getCaseDescription(
		HIContinuationElectionEventJSON objParsedInfoEvent,
		HIContinuationElectionEventJSON.StateCarrierInfo objStateCarrier,
		String strEventId,
		Map<String, List<HIContinuationElectionEventJSON.FormInfo>> map_StateCarrierIdForms
	) {
		String strCaseDescription = '';
		//State Carrier Key
		String strStateCarrierKey = objStateCarrier.key;
		String strStateCarrierName = objStateCarrier.name;

		//add Event type detail to Case description
		strCaseDescription += HIEnrollmentEventUtility.getEmployeeInformation(
			objParsedInfoEvent.employee,
			objParsedInfoEvent.company.name,
			strStateCarrierName,
			''
		);

		strCaseDescription +=
			'\n\nPlease submit ALL linked forms to the carrier\nForms' +
			getForms(String.valueOf(objStateCarrier.id), strEventId, map_StateCarrierIdForms);
		strCaseDescription += '\n\nCarrier';
		strCaseDescription += '\n- Carrier: ' + strStateCarrierName;

		return strCaseDescription;
	}

	static string getCaseDescriptionSelectionPolicy(
		HIContinuationElectionEventJSON objParsedInfoEvent,
		Long strStateCarrier,
		String strGroupIDs
	) {
		String strSelectionPolicy = '';

		for (
			HIContinuationElectionEventJSON.SubscriptionsInfo objSubscriptionsInfo : objParsedInfoEvent.continuation_subscriptions
		) {
			if (
				objSubscriptionsInfo.enrollment_information != null &&
				objSubscriptionsInfo.enrollment_information.policy_id != null &&
				objSubscriptionsInfo.enrollment_information.state_carrier_id != null &&
				objSubscriptionsInfo.enrollment_information.state_carrier_id == strStateCarrier
			) {
				HIContinuationElectionEventJSON.PolicyInfo objPolicy = map_PolicyIds.get(
					'' + objSubscriptionsInfo.enrollment_information.policy_id
				);

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
				strSelectionPolicy +=
					'\n- Estimated Start Date: ' +
					HIFulfillmentEventHelperFunctions.getChangeDateFormat(objSubscriptionsInfo.start_date);
				strSelectionPolicy += '\n- Group ID: ' + objPolicy.group_number;
				strSelectionPolicy += '\n- Policy Number: ' + objPolicy.policy_number;

				Integer intDependentSize = 0;
				if (
					objSubscriptionsInfo.enrollment_information != null &&
					objSubscriptionsInfo.enrollment_information.dependent_ids != null
				) {
					intDependentSize = objSubscriptionsInfo.enrollment_information.dependent_ids.size();
				}

				strSelectionPolicy += '\n';
				if (objSubscriptionsInfo.enrollment_information != null) {
					strSelectionPolicy +=
						'\n- Employee enrolling: ' +
						objSubscriptionsInfo.enrollment_information.employee_enrolled;
				}

				strSelectionPolicy += '\n- Number of Active Dependents: ' + intDependentSize;
				strSelectionPolicy +=
					'\n- EE estimated premium: ' + objSubscriptionsInfo.estimated_employee_premium;
				strSelectionPolicy +=
					'\n- Dependents estimated premium: ' + objSubscriptionsInfo.estimated_dependents_premium;
				strSelectionPolicy +=
					'\n- Total estimated premium: ' + objSubscriptionsInfo.estimated_total_premium;
				strSelectionPolicy += '\n' + HIEnrollmentEventUtility.DESC_SEPARATOR;
			}
		}

		return strSelectionPolicy;
	}

	public static Map<String, Contact> processContactInformation(
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents,
		Map<String, HIContinuationElectionEventJSON> map_ContinuationElectionInfos,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Set<String> set_EmployeeEmails,
		String strEventType
	) {
		List<Contact> list_ContactsToBeInserted = new List<Contact>();
		String strExceptionClassName = '';
		Map<String, String> map_EventIdToEmployeeEmails = new Map<String, String>();

		for (HI_Fulfillment_Event__c objFulfillmentEvent : list_HIFulfillmentEvents) {
			if (
				objFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE ||
				objFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE
			) {
				continue;
			}

			HIEnrollmentEventUtility.CompanyInfo objCompany;
			HIEnrollmentEventUtility.EmployeeInfo objEmployee;

			HIContinuationElectionEventJSON objElectionEventJSON = map_ContinuationElectionInfos.get(
				objFulfillmentEvent.Id__c
			);
			objCompany = objElectionEventJSON.company;
			objEmployee = objElectionEventJSON.employee;

			if (String.isBlank(strExceptionClassName)) {
				strExceptionClassName = 'HIContinuationElectionEvent-processContactInformation';
			}

			if (objCompany == null || objEmployee == null) {
				continue;
			}

			map_EventIdToEmployeeEmails.put(objFulfillmentEvent.Id__c, objEmployee.email);

			if (!map_Accounts.containsKey('' + objCompany.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(
					IntegrationUtils.ERROR_STATE,
					HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST,
					objFulfillmentEvent
				);
				continue;
			}

			if (
				!map_Contacts.containsKey(objCompany.id + '-' + objEmployee.email) &&
				!map_Contacts.containsKey(objEmployee.email)
			) {
				Contact objContact = new Contact();
				objContact.AccountId = map_Accounts.get('' + objCompany.id).Id;
				objContact.FirstName = objEmployee.first_Name;
				objContact.LastName = objEmployee.last_name;
				objContact.Email = objEmployee.email;
				objContact.RecordTypeId = HIEnrollmentEventUtility.CONTACT_COMPANY_RT_ID;
				objContact.Employee_Id__c = String.valueOf(objEmployee.id);
				list_ContactsToBeInserted.add(objContact);
			}
		}

		if (list_ContactsToBeInserted.size() > 0) {
			Map<String, String> map_DMLContactInsertErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = Database.insert(list_ContactsToBeInserted, false);
			map_DMLContactInsertErrors = Utils.processSaveResult(
				list_SaveResults,
				list_ContactsToBeInserted,
				'email',
				true,
				strExceptionClassName
			);

			for (HI_Fulfillment_Event__c objFulfillmentEvent : list_HIFulfillmentEvents) {
				String strEmployeeEmail = map_EventIdToEmployeeEmails.containsKey(objFulfillmentEvent.Id__c)
					? map_EventIdToEmployeeEmails.get(objFulfillmentEvent.Id__c)
					: '';

				if (map_DMLContactInsertErrors.containsKey(strEmployeeEmail)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(
						IntegrationUtils.ERROR_STATE,
						map_DMLContactInsertErrors.get(strEmployeeEmail),
						objFulfillmentEvent
					);
					continue;
				}
			}

			map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmails);
		}

		return map_Contacts;
	}

	public class CaseDataWrapper {
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
		public HIContinuationElectionEventJSON objHIEventInfo;
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
			HIContinuationElectionEventJSON objHIEventInfoTemp,
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