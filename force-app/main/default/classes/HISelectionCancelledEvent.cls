/**
 * @name         HISelectionCancelledEvent
 * @author
 * @date         15th December 2020
 * @description  Process Selection Cancelled Events and update/create relevant cases.
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 */
public class HISelectionCancelledEvent {
	static Database.DMLOptions objDMLOption = new Database.DMLOptions();
	public static string strDestroyReason = ''; //BBO-1456
	public static void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvent) {
		List<Exception> list_Exceptions = new List<Exception>();

		if (list_HIFulfillmentEvent == null || list_HIFulfillmentEvent.isEmpty()) {
			return;
		}

		Map<String, HI_Fulfillment_Event__c> map_ValidEvents = HIEnrollmentEventUtility.validateAndSetProcessingState(list_HIFulfillmentEvent);

		if (map_ValidEvents.isEmpty()) {
			return;
		}

		Blob blbEncryptionKey = EncryptionUtils.getEncryptionKey('Master');

		Set<String> set_ZPCompanyId = new Set<String>(), set_EmployeeId = new Set<String>(), set_CarrierId = new Set<String>();
		Map<String, Account> map_Accounts = new Map<String, Account>();
		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		Map<String, EventWrapper> map_EventWrapper = new Map<String, EventWrapper>();

		HISelectionsCancelledEventJSON objParsedInfoEvent = new HISelectionsCancelledEventJSON();

		for (HI_Fulfillment_Event__c objFulfillmentEvent : map_ValidEvents.values()) {
			try {
				Blob blobDecryptedInfo = EncodingUtil.base64Decode(objFulfillmentEvent.Event_Info_Encrypted__c);
				String strDecryptedInfo = EncryptionUtils.getDecryptedText(blbEncryptionKey, blobDecryptedInfo);
				objParsedInfoEvent = getJSONParsedData(strDecryptedInfo);

				if (objParsedInfoEvent.selection.status == HIEnrollmentEventUtility.WAIVED_EVENT) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIEnrollmentEventUtility.SUCCESS_MESSAGE, objFulfillmentEvent);
					continue;
				}
				if (!validateParsedEventInfo(objParsedInfoEvent, objFulfillmentEvent)) {
					continue;
				}

				set_ZPCompanyId.add(String.valueOf(objParsedInfoEvent.company.id));
				set_EmployeeId.add(String.valueOf(objParsedInfoEvent.employee.id));
				set_CarrierId.add(String.valueOf(objParsedInfoEvent.selection.enrollment_information.state_carrier.id));

				map_EventWrapper.put(objParsedInfoEvent.selection.uuid, new EventWrapper(objFulfillmentEvent.Id__c, objParsedInfoEvent));
			} catch (JSONException objJSONExcep) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objFulfillmentEvent);
			} catch (Exception e) {
				list_Exceptions.add(e);
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EXCEPTION_WHILE_PROCESSING, objFulfillmentEvent);
			}
		}
		try {
			if (!set_ZPCompanyId.isEmpty()) {
				map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_ZPCompanyId);
			}

			if (!set_EmployeeId.isEmpty()) {
				map_Contacts = HIFulfillmentEventHelperFunctions.getContactsForEmployeeID(set_EmployeeID);
			}

			Map<String, Carrier__c> map_Carrier = HIFulfillmentEventHelperFunctions.getCarrierInfoById(set_CarrierId); // Key is CarrierId value is Carrier record

			if (!map_EventWrapper.isEmpty()) {
				Map<String, Object> map_Result = HIEnrollmentEventUtility.fetchCases(map_EventWrapper.keySet());
				Map<String, Case> map_ExistingCases = new Map<String, Case>();
				Map<String, Case> map_ExistingTerminationCases = new Map<String, Case>();
				Map<String, Case> map_ExistingCancellationCases = new Map<String, Case>();

				if (map_Result != null && !map_Result.isEmpty()) {
					if (map_Result.containsKey('NHEQLECases')) {
						map_ExistingCases = (Map<String, Case>) map_Result.get('NHEQLECases');
					}

					if (map_Result.containsKey('Termination')) {
						map_ExistingTerminationCases = (Map<String, Case>) map_Result.get('Termination');
					}

					if (map_Result.containsKey('Cancellation')) {
						map_ExistingCancellationCases = (Map<String, Case>) map_Result.get('Cancellation');
					}
				}

				Map<String, Case> map_TerminationCases = new Map<String, Case>(), map_CancellationCases = new Map<String, Case>();
				Map<Id, Case> map_NHEQLECasesToUpdate = new Map<Id, Case>();

				objDMLOption.assignmentRuleHeader.useDefaultRule = true;

				for (String strUUID : map_EventWrapper.keySet()) {
					EventWrapper objEventWrap = map_EventWrapper.get(strUUID);

					if (objEventWrap.objParsedInfoEvent.selection.status != HIEnrollmentEventUtility.ENROLLING_EVENT) {
						continue;
					}
					Case objExistingCase;

					String strCompanyId = String.valueOf(objEventWrap.objParsedInfoEvent.company.id);
					String strEmployeeId = String.valueOf(objEventWrap.objParsedInfoEvent.employee.id);
					String strCarrierId = String.valueOf(objEventWrap.objParsedInfoEvent.selection.enrollment_information.state_carrier.id);
					String strBenefitType = objEventWrap.objParsedInfoEvent.selection.enrollment_information.policy.benefit_type;
					strDestroyReason = String.valueOf(objEventWrap.objParsedInfoEvent.destroy_reason); //BBO-1456
					String strCarrierKey;

					if (map_Carrier != null && map_Carrier.containsKey(strCarrierId)) {
						strCarrierKey = map_Carrier.get(strCarrierId).Key__c;
					} else {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.CARRIER_DOESNOT_EXIST, map_ValidEvents.get(objEventWrap.strEventId));
						continue;
					}

					String strKey = strEmployeeId + '-' + strCarrierKey;
					String strProperCaseBenefitType;

					if (strBenefitType.equalsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL)) {
						strProperCaseBenefitType = HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL;
					} else if (strBenefitType.equalsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL)) {
						strProperCaseBenefitType = HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL;
					} else if (strBenefitType.equalsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_VISION)) {
						strProperCaseBenefitType = HIEnrollmentEventUtility.BENEFIT_TYPE_VISION;
					} else if (strBenefitType.equalsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE)) {
						strProperCaseBenefitType = HIEnrollmentEventUtility.BENEFIT_TYPE_VISION;
					} else if (strBenefitType.equalsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_LTD_1)) {
						strProperCaseBenefitType = HIEnrollmentEventUtility.BENEFIT_TYPE_LTD;
					} else if (strBenefitType.equalsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_STD_1)) {
						strProperCaseBenefitType = HIEnrollmentEventUtility.BENEFIT_TYPE_STD;
					}

					if (map_ExistingCases != null && map_ExistingCases.containsKey(strUUID)) {
						//update existing case
						objExistingCase = map_ExistingCases.get(strUUID);
					}

					//Create MF Termination case if lost_coverage_date is populated
					if (objEventWrap.objParsedInfoEvent.employee.lost_coverage_date != null) {
						Case objMFTerminationCase = createCaseRecord(
							map_ExistingTerminationCases,
							map_Accounts,
							map_Contacts,
							map_Carrier,
							strKey,
							strCompanyId,
							strEmployeeId,
							strCarrierKey,
							strCarrierId,
							strUUID,
							strProperCaseBenefitType,
							strBenefitType,
							objEventWrap
						);
						objMFTerminationCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_TERMINATION;
						objMFTerminationCase.Termination_Date__c = Date.valueOf(objEventWrap.objParsedInfoEvent.employee.lost_coverage_date);
						objMFTerminationCase.Type = HIEnrollmentEventUtility.CASE_TYPE_CANCELLATION;
						objMFTerminationCase.Enrollment_Message__c = HIEnrollmentEventUtility.TERMINATION_CASE_MESSAGE;

						map_ExistingTerminationCases.put(strKey, objMFTerminationCase);
						map_TerminationCases.put(strKey, objMFTerminationCase);

						if (objExistingCase != null) {
							objExistingCase.Status = HIEnrollmentEventUtility.CASE_STATUS_CANCELLED;
							map_ExistingCases.put(strUUID, objExistingCase);
							map_NHEQLECasesToUpdate.put(objExistingCase.Id, objExistingCase);
						}
					} else if (objExistingCase == null || objExistingCase.Status == HIEnrollmentEventUtility.CASE_STATUS_CLOSED) {
						//Create New MF Cancellation Case as no exisiting NHE/QLE case was found or Existing case is Closed
						Case objMFCancellationCase = createCaseRecord(
							map_ExistingCancellationCases,
							map_Accounts,
							map_Contacts,
							map_Carrier,
							strKey,
							strCompanyId,
							strEmployeeId,
							strCarrierKey,
							strCarrierId,
							strUUID,
							strProperCaseBenefitType,
							strBenefitType,
							objEventWrap
						);

						if (String.isNotBlank(objEventWrap.objParsedInfoEvent.selection.start_date)) {
							objMFCancellationCase.Anticipated_Effective_Date__c = Date.valueOf(objEventWrap.objParsedInfoEvent.selection.start_date);
						}

						objMFCancellationCase.Enrollment_Message__c = HIEnrollmentEventUtility.SUBMITTED_CASE_MESSAGE;
						objMFCancellationCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_CANCELLATION;

						map_ExistingCancellationCases.put(strKey, objMFCancellationCase);
						map_CancellationCases.put(strKey, objMFCancellationCase);
					} else if (
						objExistingCase != null &&
						HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses != null &&
						HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses.contains(objExistingCase.Status)
					) {
						//Case not submitted to Carrier
						if (String.isNotBlank(objExistingCase.Benefit_Types__c) && objExistingCase.Benefit_Types__c.containsIgnoreCase(strProperCaseBenefitType)) {
							objExistingCase.Benefit_Types__c = objExistingCase.Benefit_Types__c.replace(strProperCaseBenefitType, '');
							objExistingCase.Benefit_Types__c = objExistingCase.Benefit_Types__c.replace(';;', ';') == ';' ? '' : objExistingCase.Benefit_Types__c.replace(';;', ';');
						}

						if (String.isNotBlank(objExistingCase.Selection_UUIds__c) && objExistingCase.Selection_UUIds__c.contains(strUUID)) {
							objExistingCase.Selection_UUIds__c = objExistingCase.Selection_UUIds__c.replace(strUUID, '');
							objExistingCase.Selection_UUIds__c = objExistingCase.Selection_UUIds__c.replace(';;', ';') == ';' ? '' : objExistingCase.Selection_UUIds__c.replace(';;', ';');
						}

						if (String.isNotBlank(objExistingCase.Description) && objExistingCase.Description.containsIgnoreCase(strBenefitType)) {
							objExistingCase.Description = removeSelectionInfo(objExistingCase.Description, strBenefitType);
						}

						if (String.isNotBlank(objExistingCase.Subscription_Information__c) && objExistingCase.Subscription_Information__c.containsIgnoreCase(strBenefitType)) {
							objExistingCase.Subscription_Information__c = removeSelectionInfo(objExistingCase.Subscription_Information__c, strBenefitType);
						}

						if (String.isBlank(objExistingCase.Benefit_Types__c) && String.isBlank(objExistingCase.Selection_UUIds__c)) {
							objExistingCase.Status = HIEnrollmentEventUtility.CASE_STATUS_CANCELLED;
						} else {
							objExistingCase = HIEnrollmentEventUtility.updateCaseOwner(objExistingCase, false);
						}

						objExistingCase.Enrollment_Modified__c = true;
						objExistingCase = HIEnrollmentEventUtility.updateUUIDOnCase(strBenefitType, objExistingCase, strUUID, 'Remove');
						//Create Bot JSON for cancel event.
						objExistingCase.Fulfillment_Event_Encrypted_JSON__c = getCarrierBotJson(
							objParsedInfoEvent,
							objParsedInfoEvent.selection,
							blbEncryptionKey,
							objExistingCase.Fulfillment_Event_Encrypted_JSON__c
						);

						map_ExistingCases.put(strUUID, objExistingCase);
						map_NHEQLECasesToUpdate.put(objExistingCase.Id, objExistingCase);
					} else {
						//Case exists and its submitted
						objExistingCase.Status = CaseUtils.STATUS_NEW;
						objExistingCase.Enrollment_Modified__c = true;
						objExistingCase.Enrollment_Message__c = HIEnrollmentEventUtility.SUBMITTED_CASE_MESSAGE;

						map_ExistingCases.put(strUUID, objExistingCase);
						map_NHEQLECasesToUpdate.put(objExistingCase.Id, objExistingCase);
					}
				}

				List<Case> list_CasesToUpsert = new List<Case>();
				if (!map_TerminationCases.isEmpty()) {
					list_CasesToUpsert.addAll(map_TerminationCases.values());
				}
				if (!map_CancellationCases.isEmpty()) {
					list_CasesToUpsert.addAll(map_CancellationCases.values());
				}
				if (!map_NHEQLECasesToUpdate.isEmpty()) {
					list_CasesToUpsert.addAll(map_NHEQLECasesToUpdate.values());
				}
				if (!list_CasesToUpsert.isEmpty()) {
					HIEnrollmentEventUtility.upsertCasesAndSetProcessingState(list_HIFulfillmentEvent, list_CasesToUpsert, 'HISelectionCancelledEvent-processInformation');
				}
			}
		} catch (Exception e) {
			list_Exceptions.add(e);
		}

		//insert Exception log for Exceptions
		if (!list_Exceptions.isEmpty()) {
			ExceptionLogUtil.logException('Error', 'HISelectionCancelledEvent', 'ProcessInformation', list_Exceptions);
		}
	}

	static String removeSelectionInfo(String strSelectionData, String strBenefitType) {
		Integer intStartIndex = strSelectionData.indexOf(strBenefitType);

		if (intStartIndex != -1) {
			intStartIndex = intStartIndex == 0 ? intStartIndex : intStartIndex - 1;

			String strNewSelectionData = intStartIndex == 0 ? '' : strSelectionData.subString(0, intStartIndex);
			String strDescriptionToRemove = strSelectionData.subString(intStartIndex);

			if (String.isNotBlank(strDescriptionToRemove)) {
				strNewSelectionData += strDescriptionToRemove.substringAfter(HIEnrollmentEventUtility.DESC_SEPARATOR);
			}

			return strNewSelectionData;
		}
		return strSelectionData;
	}

	static Case createCaseRecord(
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
		EventWrapper objEventWrap
	) {
		HIEnrollmentEventUtility.strDestroyReason = strDestroyReason; //BBO-1456
		Case objCase = HIEnrollmentEventUtility.createCaseRecordForSelectionCancelled(
			map_ExistingCases,
			map_Accounts,
			map_Contacts,
			map_Carrier,
			strKey,
			strCompanyId,
			strEmployeeId,
			strCarrierKey,
			strCarrierId,
			strUUID,
			strBenefitTypeUIValue,
			strBenefitType,
			objEventWrap.strEventId,
			objDMLOption
		);
		objCase = updateDescription(objCase, objEventWrap.objParsedInfoEvent);
		return objCase;
	}

	static Case updateDescription(Case objCase, HISelectionsCancelledEventJSON objParsedInfoEvent) {
		String strCaseDescription = '';

		if (String.isBlank(objCase.Description)) {
			objCase.Description = '';
			strCaseDescription = 'General Info';

			if (objParsedInfoEvent.employee.lost_coverage_date != null) {
				strCaseDescription += '\n- Triggering Event and Date: Termination on ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objParsedInfoEvent.employee.lost_coverage_date);
			}

			strCaseDescription +=
				'\n- EE Hippo Link: ' +
				objParsedInfoEvent.employee.hippo_url +
				'\n- EE Panda Link: ' +
				objParsedInfoEvent.employee.panda_url +
				'\n\nCompany Info' +
				'\n- Company Name: ' +
				objParsedInfoEvent.company.name +
				'\n\nPlease review and submit the required documents to the carrier for following Selection Cancellations.' +
				'\n\nSelection Info';
		}

		strCaseDescription +=
			'\n' +
			objParsedInfoEvent.selection.enrollment_information.policy.benefit_type +
			': ' +
			objParsedInfoEvent.selection.enrollment_information.policy.name +
			'\n- Group ID: ' +
			objParsedInfoEvent.selection.enrollment_information.policy.group_number +
			'\n- Policy Number: ' +
			objParsedInfoEvent.selection.enrollment_information.policy.policy_number +
			'\n- Carrier: ' +
			objParsedInfoEvent.selection.enrollment_information.state_carrier.name +
			'\n- Carrier State: ' +
			objParsedInfoEvent.selection.enrollment_information.state_carrier.state;

		objCase.Description += strCaseDescription;
		return objCase;
	}

	private static Boolean validateParsedEventInfo(HISelectionsCancelledEventJSON objParsedInfoEvent, HI_Fulfillment_Event__c objFulfillmentEvent) {
		if (objParsedInfoEvent.company.id == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING, objFulfillmentEvent);
			return false;
		}

		if (objParsedInfoEvent.selection == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.SELECTION_INFO_MISSING, objFulfillmentEvent);
			return false;
		}

		if (String.isBlank(objParsedInfoEvent.selection.uuid)) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.UUID_MISSING, objFulfillmentEvent);
			return false;
		}

		if (objParsedInfoEvent.selection.status == HIEnrollmentEventUtility.ENROLLING_EVENT) {
			if (objParsedInfoEvent.selection.enrollment_information == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.ENROLLMENT_INFO_MISSING, objFulfillmentEvent);
				return false;
			}

			if (objParsedInfoEvent.selection.enrollment_information.state_carrier == null || objParsedInfoEvent.selection.enrollment_information.state_carrier.id == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.STATE_CARRIER_IS_MISSING, objFulfillmentEvent);
				return false;
			}
		}
		return true;
	}
	public static HISelectionsCancelledEventJSON getJSONParsedData(String jsonString) {
		HISelectionsCancelledEventJSON parsedData = (HISelectionsCancelledEventJSON) JSON.deserialize(jsonString, HISelectionsCancelledEventJSON.class);
		return parsedData;
	}

	private static String getCarrierBotJson(HISelectionsCancelledEventJSON selCancelJson, HISelectionsCancelledEventJSON.SelectionInfo objSelection, Blob blbEncryptionKey, String strExistingBotJson) {
		String strBotJson = '';

		try {
			if (String.isNotBlank(strExistingBotJson)) {
				//update existing BOT JSON and return it.
				Blob blobDecryptedInfo = EncodingUtil.base64Decode(strExistingBotJson);
				String strDecryptedInfo = EncryptionUtils.getDecryptedText(blbEncryptionKey, blobDecryptedInfo);
				HIFulfillmentBotEnrollmentJSON objExistingBOTJSON = (HIFulfillmentBotEnrollmentJSON) JSON.deserialize(strDecryptedInfo, HIFulfillmentBotEnrollmentJSON.class);

				String strPolicyId = '';
				String strBenefitType = '';

				if (selCancelJson.selection != null) {
					if (selCancelJson.selection.enrollment_information != null) {
						if (selCancelJson.selection.enrollment_information.policy != null) {
							strPolicyId = selCancelJson.selection.enrollment_information.policy.group_number;
							strBenefitType = selCancelJson.selection.enrollment_information.policy.benefit_type;
						}
					}
				}

				//Remove policy from existing Bot JSON.
				Integer intIndex = 0;
				Boolean blnRecordFound = false;

				if (String.IsNotBlank(strPolicyId) && objExistingBOTJSON.policies != null && objExistingBOTJSON.policies.size() > 0) {
					for (HIFulfillmentBotEnrollmentJSON.Policy pol : objExistingBOTJSON.policies) {
						if (pol.group_number == strPolicyId) {
							blnRecordFound = true;
							break;
						}
						intIndex = intIndex + 1;
					}
					if (blnRecordFound) {
						objExistingBOTJSON.policies.remove(intIndex);
					}
				}

				//Remove benefit_items from existing Bot JSON.
				if (String.isNotBlank(strBenefitType)) {
					if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL) {
						objExistingBOTJSON.benefit_items.medical = null;
					} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL) {
						objExistingBOTJSON.benefit_items.dental = null;
					} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_VISION) {
						objExistingBOTJSON.benefit_items.vision = null;
					} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE) {
						objExistingBOTJSON.benefit_items.life = null;
					} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_LTD_1) {
						objExistingBOTJSON.benefit_items.long_term_disability = null;
					} else if (strBenefitType == HIEnrollmentEventUtility.BENEFIT_TYPE_STD_1) {
						objExistingBOTJSON.benefit_items.short_term_disability = null;
					}
				}

				//return ''+JSON.serialize(objExistingBOTJSON);
				Blob botEncryptedBlob = EncryptionUtils.getEncryptedBlob(blbEncryptionKey, '' + JSON.serialize(objExistingBOTJSON));
				strBotJson = EncodingUtil.base64Encode(botEncryptedBlob);
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('HISelectionCancelledEvent', 'getCarrierBotJson', ex);
		}
		return strBotJson;
	}

	public class EventWrapper {
		public String strEventId;
		public HISelectionsCancelledEventJSON objParsedInfoEvent;

		public EventWrapper(String strEId, HISelectionsCancelledEventJSON objParsedJSON) {
			this.strEventId = strEId;
			this.objParsedInfoEvent = objParsedJSON;
		}
	}
}