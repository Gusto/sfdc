/**
 * @name         HITaDaSelectionCancelledEvent
 * @author       Neha Dabas
 * @date         8th Jan 2021
 * @description  Process Tada Selection Cancelled Events and update/create relevant cases.
 * @test class   HITaDaSelectionCancelledEventTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class HITaDaSelectionCancelledEvent {
	static Database.DMLOptions objDMLOption = new Database.DMLOptions();

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
		HITaDaSelectionCancelledEventJSON objParsedInfoEvent = new HITaDaSelectionCancelledEventJSON();
		Set<String> set_CarrierKey = new Set<String>();
		Map<String, Carrier__c> map_Carrier = new Map<String, Carrier__c>();
		for (HI_Fulfillment_Event__c objFulfillmentEvent : map_ValidEvents.values()) {
			try {
				Blob blobDecryptedInfo = EncodingUtil.base64Decode(objFulfillmentEvent.Event_Info_Encrypted__c);
				String strDecryptedInfo = EncryptionUtils.getDecryptedText(blbEncryptionKey, blobDecryptedInfo);
				objParsedInfoEvent = getJSONParsedData(strDecryptedInfo);

				if (!validateParsedEventInfo(objParsedInfoEvent, objFulfillmentEvent)) {
					continue;
				}

				set_ZPCompanyId.add(String.valueOf(objParsedInfoEvent.company.id));
				set_EmployeeId.add(String.valueOf(objParsedInfoEvent.employee.id));
				map_EventWrapper.put(objParsedInfoEvent.selection.uuid, new EventWrapper(objFulfillmentEvent.Id__c, objParsedInfoEvent));
				set_CarrierKey.add(objParsedInfoEvent.selection.provider_key);
			} 
			catch (JSONException objJSONExcep) {
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
			
			if (!set_CarrierKey.isEmpty()) {
				map_Carrier = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKey);
			}

			if (!map_EventWrapper.isEmpty()) {
				Map<String, Object> map_Result = HIEnrollmentEventUtility.fetchCases(map_EventWrapper.keySet());
				Map<String, Case> map_ExistingCases = new Map<String, Case>(), map_ExistingTerminationCases = new Map<String, Case>(), map_ExistingCancellationCases = new Map<String, Case>();

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

					Case objExistingCase;
					String strCompanyId = String.valueOf(objEventWrap.objParsedInfoEvent.company.id);
					String strEmployeeId = String.valueOf(objEventWrap.objParsedInfoEvent.employee.id);
					String strBenefitType = objEventWrap.objParsedInfoEvent.selection.benefit_type;
					String strCarrierkey = objEventWrap.objParsedInfoEvent.selection.provider_key;
					String strKey = strEmployeeId + '-' + strCarrierkey;
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
							strUUID,
							strBenefitType,
							objEventWrap,
							strCarrierkey
						);
						objMFTerminationCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_TERMINATION;
						objMFTerminationCase.Termination_Date__c = Date.valueOf(objEventWrap.objParsedInfoEvent.employee.lost_coverage_date);
						objMFTerminationCase.Type = HIEnrollmentEventUtility.CASE_TYPE_CANCELLATION;
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
							strUUID,
							strBenefitType,
							objEventWrap,
							strCarrierkey
						);
						objMFCancellationCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_CANCELLATION;
						if (String.isNotBlank(objEventWrap.objParsedInfoEvent.selection.start_date)) {
							objMFCancellationCase.Anticipated_Effective_Date__c = Date.valueOf(objEventWrap.objParsedInfoEvent.selection.start_date);
						}
						objMFCancellationCase.Enrollment_Message__c = HIEnrollmentEventUtility.SUBMITTED_CASE_MESSAGE;
						map_ExistingCancellationCases.put(strKey, objMFCancellationCase);
						map_CancellationCases.put(strKey, objMFCancellationCase);
					} else if (
						objExistingCase != null &&
						HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses != null &&
						HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses.contains(objExistingCase.Status)
					) {
						//Case not submitted to Carrier
						String strProperCaseBenefitType = strBenefitType.toUpperCase();

						if (String.isNotBlank(objExistingCase.Benefit_Types__c) && objExistingCase.Benefit_Types__c.containsIgnoreCase(strBenefitType)) {
							objExistingCase.Benefit_Types__c = objExistingCase.Benefit_Types__c.replace(strProperCaseBenefitType, '');
							objExistingCase.Benefit_Types__c = objExistingCase.Benefit_Types__c.replace(';;', ';') == ';' ? '' : objExistingCase.Benefit_Types__c.replace(';;', ';');
						}

						if (String.isNotBlank(objExistingCase.Fulfillment_Sub_Type__c) && objExistingCase.Fulfillment_Sub_Type__c.containsIgnoreCase(strBenefitType)) {
							objExistingCase.Fulfillment_Sub_Type__c = objExistingCase.Fulfillment_Sub_Type__c.replace(strProperCaseBenefitType, '');
							objExistingCase.Fulfillment_Sub_Type__c = objExistingCase.Fulfillment_Sub_Type__c.replace(';;', ';') == ';'
								? ''
								: objExistingCase.Fulfillment_Sub_Type__c.replace(';;', ';');
						}

						if (String.isNotBlank(objExistingCase.Selection_UUIds__c) && objExistingCase.Selection_UUIds__c.contains(strUUID)) {
							objExistingCase.Selection_UUIds__c = objExistingCase.Selection_UUIds__c.replace(strUUID, '');
							objExistingCase.Selection_UUIds__c = objExistingCase.Selection_UUIds__c.replace(';;', ';') == ';' ? '' : objExistingCase.Selection_UUIds__c.replace(';;', ';');
						}

						if (String.isNotBlank(objExistingCase.Description) && objExistingCase.Description.containsIgnoreCase(strBenefitType)) {
							objExistingCase.Description = removeSelectionInfo(objExistingCase.Description, strBenefitType);
						}

						if (String.isBlank(objExistingCase.Benefit_Types__c) && String.isBlank(objExistingCase.Selection_UUIds__c)) {
							objExistingCase.Status = HIEnrollmentEventUtility.CASE_STATUS_CANCELLED;
						} else {
							objExistingCase = HIEnrollmentEventUtility.updateCaseOwner(objExistingCase, false);
						}

						objExistingCase.Enrollment_Modified__c = true;
						objExistingCase = HIEnrollmentEventUtility.updateUUIDOnCase(strBenefitType, objExistingCase, strUUID, 'Remove');
						map_ExistingCases.put(strUUID, objExistingCase);
						map_NHEQLECasesToUpdate.put(objExistingCase.Id, objExistingCase);
					} else {
						//Case exists and its submitted
						objExistingCase = HIEnrollmentEventUtility.updateCaseOwner(objExistingCase, true);
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
					HIEnrollmentEventUtility.upsertCasesAndSetProcessingState(list_HIFulfillmentEvent, list_CasesToUpsert, 'HITaDaSelectionCancelledEvent-processInformation');
				}
			}
		} catch (Exception e) {
			list_Exceptions.add(e);
		}
		//insert Exception log for Exceptions
		if (!list_Exceptions.isEmpty()) {
			ExceptionLogUtil.logException('Error', 'HITadaSelectionCancelledEvent', 'ProcessInformation', list_Exceptions);
		}
	}

	static String removeSelectionInfo(String strSelectionData, String strBenefitType) {
		Integer intStartIndex = strSelectionData.indexOf(strBenefitType);
		if (intStartIndex != -1) {
			intStartIndex = (intStartIndex == 0) ? intStartIndex : intStartIndex - 1;
			String strNewSelectionData = (intStartIndex == 0) ? '' : strSelectionData.subString(0, intStartIndex);
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
		String strUUID,
		String strBenefitType,
		EventWrapper objEventWrap,
		String strCarrierkey

	) {
		Case objCase = HIEnrollmentEventUtility.createCaseRecordForSelectionCancelled(
			map_ExistingCases,
			map_Accounts,
			map_Contacts,
			map_Carrier, 
			strKey,
			strCompanyId,
			strEmployeeId,
			strCarrierkey,
			'',
			strUUID,
			strBenefitType,
			strBenefitType,
			true,
			objEventWrap.strEventId,
			objDMLOption
		);

		objCase = updateDescription(objCase, objEventWrap.objParsedInfoEvent);
		return objCase;
	}

	static Case updateDescription(Case objCase, HITaDaSelectionCancelledEventJSON objParsedInfoEvent) {
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
				'\n\nPlease review and submit the required documents to the carrier for following Selection Cancellations.' +
				'\n\nSelection Info';
		}
		strCaseDescription += '\n' + objParsedInfoEvent.selection.benefit_type + '\n- Carrier: ' + objParsedInfoEvent.selection.provider_key;
		objCase.Description += strCaseDescription;
		return objCase;
	}

	private static Boolean validateParsedEventInfo(HITaDaSelectionCancelledEventJSON objParsedInfoEvent, HI_Fulfillment_Event__c objFulfillmentEvent) {
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

		if (String.isBlank(objParsedInfoEvent.selection.provider_key)) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.PROVIDER_KEY_MISSING, objFulfillmentEvent);
			return false;
		}
		return true;
	}

	public static HITaDaSelectionCancelledEventJSON getJSONParsedData(String jsonString) {
		HITaDaSelectionCancelledEventJSON parsedData = (HITaDaSelectionCancelledEventJSON) JSON.deserialize(jsonString, HITaDaSelectionCancelledEventJSON.class);
		return parsedData;
	}

	public class EventWrapper {
		public String strEventId;
		public HITaDaSelectionCancelledEventJSON objParsedInfoEvent;
		public EventWrapper(String strEId, HITaDaSelectionCancelledEventJSON objParsedJSON) {
			this.strEventId = strEId;
			this.objParsedInfoEvent = objParsedJSON;
		}
	}
}