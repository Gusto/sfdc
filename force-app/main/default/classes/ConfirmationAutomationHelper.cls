/**
 * @name         ConfirmationAutomationHelper
 * @author       Neha Dabas
 * @date         28-Sept-2020
 * @description  Utility class for Confirmation Automation on Carrier Orders
 * @test classes HIGroupEventTriggerHelperTest,CarrierOrderTriggerHelperTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class ConfirmationAutomationHelper {
	static final String STATE_CARRIER_ID_KEY = 'EligibleStateCarrierIds';
	static final String CARRIER_ID_KEY = 'EligibleCarrierIds';
	static final String STATUS_UNABLE_TO_AUDIT = 'Unable to audit';
	static final String STATUS_CARRIER_DATA_NOT_AVAILABLE = 'Carrier data not available yet';
	static final String STATUS_PENDING_AUDIT = 'Pending audit';
	static final String STATUS_FAILED = 'Failed';
	static final String STATUS_SUCCESS = 'Success';
	static final String CO_STATUS_APPROVED = 'Approved';
	static final String CO_STATUS_APPROVED_PENDING_EE_AUDIT = 'Approved Pending EE Audit';
	static final String CO_STATUS_READY_FOR_CONFIRMATION = 'Ready for Confirmation';

	/*
	 * Check the implementation stage history table to see if CO was ealier moved to Ready for confirmation stage
	 */
	public static void checkIfCOWereMovedToReadyForConfirmationEarlier(Map<Id, Carrier_Order__c> map_COs) {
		if (map_COs.isEmpty()) {
			return;
		}
		List<Carrier_Order_Stage_History__c> list_COStageHistory = new List<Carrier_Order_Stage_History__c>();
		list_COStageHistory = [
			SELECT Carrier_Order__c
			FROM Carrier_Order_Stage_History__c
			WHERE Carrier_Order__c IN :map_COs.keySet() AND To_Stage__c = :CO_STATUS_READY_FOR_CONFIRMATION
		];
		if (!list_COStageHistory.isEmpty()) {
			for (Carrier_Order_Stage_History__c objCOHistory : list_COStageHistory) {
				Carrier_Order__c objCO = map_COs.get(objCOHistory.Carrier_Order__c);
				objCO.Order_Moved_Back_To_Confirmation__c = true;
			}
		}
	}
	/*
	 * Desctiption : On change of CO Implementation Stage, check if it is eligible for Automation
	 */
	public static void makeCOsEligibleForConfirmationAutomation(Map<Id, Carrier_Order__c> map_COs) {
		if (map_COs == null || map_COs.isEmpty()) {
			return;
		}
		Map<String, Object> map_Results = fetchEligibleCarrierInfo();
		Set<String> set_StateCarrierIds, set_CarrierIds;
		if (map_Results == null || map_Results.isEmpty()) {
			return;
		}
		if (map_Results.containsKey(STATE_CARRIER_ID_KEY)) {
			set_StateCarrierIds = (Set<String>) map_Results.get(STATE_CARRIER_ID_KEY);
		}
		if (map_Results.containsKey(CARRIER_ID_KEY)) {
			set_CarrierIds = (Set<String>) map_Results.get(CARRIER_ID_KEY);
		}

		for (Carrier_Order__c objCO : [
			SELECT Eligible_for_Confirmation_Automation__c, Order_Playable_Date__c, Follow_Up_Date__c
			FROM Carrier_Order__c
			WHERE
				Id IN :map_COs.keySet()
				AND Eligible_for_Confirmation_Automation__c = FALSE
				AND Benefit_Order__c != NULL
				AND Benefit_Order__r.Is_Multi_EIN__c = FALSE
				AND Benefit_Order__r.Parent_Benefit_Order__c = NULL
				AND Carrier__r.Carrier_Id__c != NULL
				AND Carrier__r.Id__c != NULL
				AND (Carrier__r.Carrier_Id__c IN :set_CarrierIds
				OR Carrier__r.Id__c IN :set_StateCarrierIds)
		]) {
			Carrier_Order__c objEligibleCO = map_COs.get(objCO.Id);
			if (objEligibleCO.Order_Playable_Date__c >= system.today() || objEligibleCO.Follow_Up_Date__c >= system.today()) {
				objEligibleCO.Eligible_for_Confirmation_Automation__c = true;
			}
		}
	}

	public static Map<String, Object> fetchEligibleCarrierInfo() {
		Map<String, Object> map_Results = new Map<String, Object>();
		// Fetch custom setting data for Agency and state info i.e. other config settings
		Set<String> set_StateCarrierIds = new Set<String>(), set_CarrierIds = new Set<String>();

		for (Confirmation_Automation_Eligible_Carrier__mdt objCarrierConfiguration : [
			SELECT MasterLabel, Carrier_Id__c, Applicable_to_All_States__c, State_Carrier_Ids__c
			FROM Confirmation_Automation_Eligible_Carrier__mdt
			WHERE Carrier_Id__c != NULL
		]) {
			if (objCarrierConfiguration.Applicable_to_All_States__c == true) {
				set_CarrierIds.add(objCarrierConfiguration.Carrier_Id__c);
			} else if (String.isNotBlank(objCarrierConfiguration.State_Carrier_Ids__c)) {
				set_StateCarrierIds.addAll(objCarrierConfiguration.State_Carrier_Ids__c.split(';'));
			}
		}

		map_Results.put(STATE_CARRIER_ID_KEY, set_StateCarrierIds);
		map_Results.put(CARRIER_ID_KEY, set_CarrierIds);

		return map_Results;
	}

	public static void processConfirmationAutomationEvents(List<HIGroupEvent__c> list_Events) {
		Set<String> set_ApplicationIds = new Set<String>(), set_CompanyIds = new Set<String>(), set_applicationType = new Set<String>(), set_StateCarrierIds = new Set<String>();
		if (list_Events == null || list_Events.isEmpty()) {
			return;
		}
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvent = new Map<String, HIGroupEvent__c>();
		Map<String, CarrierOrderInfoWrapper> map_COInfoWrapper = new Map<String, CarrierOrderInfoWrapper>();
		for (HIGroupEvent__c objEvent : list_Events) {
			if (String.isBlank(objEvent.Event_Info__c)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Event Info is blank', objEvent);
				continue;
			}
			try {
				ConfirmationAutomationJSON objEventInfoJSON = (ConfirmationAutomationJSON) JSON.deserialize(objEvent.Event_Info__c, ConfirmationAutomationJSON.class);

				if (String.isBlank(objEvent.State_Carrier_Id__c)) {
					if (String.isBlank(objEventInfoJSON.state_carrier_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'State Carrier Id is blank', objEvent);
						continue;
					}
					objEvent.State_Carrier_Id__c = objEventInfoJSON.state_carrier_id;
				}
				if (String.isBlank(objEvent.Application_Id__c)) {
					if (String.isBlank(objEventInfoJSON.application_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Application Id is blank', objEvent);
						continue;
					}
					objEvent.Application_Id__c = objEventInfoJSON.application_id;
				}
				if (String.isBlank(objEvent.Application_type__c)) {
					if (String.isBlank(objEventInfoJSON.application_type)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Application Type is blank', objEvent);
						continue;
					}
					objEvent.Application_type__c = objEventInfoJSON.application_type;
				}
				if (String.isBlank(objEvent.Company_Id__c)) {
					if (String.isBlank(objEventInfoJSON.company_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company Id is blank', objEvent);
						continue;
					}
					objEvent.Company_Id__c = objEventInfoJSON.company_id;
				}

				set_ApplicationIds.add(objEvent.Application_Id__c);
				set_CompanyIds.add(objEvent.Company_Id__c);
				set_applicationType.add(objEvent.Application_type__c);
				set_StateCarrierIds.add(objEvent.State_Carrier_Id__c);

				String strKey = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + objEvent.Application_type__c + '-' + objEvent.State_Carrier_Id__c;

				CarrierOrderInfoWrapper objCOWrapper = new CarrierOrderInfoWrapper();
				objCOWrapper.strEventId = objEvent.Event_Id__c;

				if (String.isNotBlank(objEvent.HI_Error_Message__c) || String.isNotBlank(objEventInfoJSON.error_message)) {
					objEvent.HI_Error_Message__c = objEventInfoJSON.error_message;
					objCOWrapper.strConfirmationAutomationStatus = STATUS_UNABLE_TO_AUDIT;
					objCOWrapper.strConfirmationAutomationMessage = objEventInfoJSON.error_message;
				} else if (objEventInfoJSON.policies != null && !objEventInfoJSON.policies.isEmpty()) {
					for (ConfirmationAutomationJSON.Policy objPolicy : objEventInfoJSON.policies) {
						if (String.isNotBlank(objPolicy.hi_confirmation_automation_status)) {
							if (objPolicy.hi_confirmation_automation_status.equalsIgnoreCase(STATUS_UNABLE_TO_AUDIT)) {
								objCOWrapper.strConfirmationAutomationStatus = objPolicy.hi_confirmation_automation_status;
							} else if (
								objPolicy.hi_confirmation_automation_status.equalsIgnoreCase(STATUS_CARRIER_DATA_NOT_AVAILABLE) &&
								!objCOWrapper.strConfirmationAutomationStatus.equalsIgnoreCase(STATUS_UNABLE_TO_AUDIT)
							) {
								objCOWrapper.strConfirmationAutomationStatus = objPolicy.hi_confirmation_automation_status;
							} else if (
								objPolicy.hi_confirmation_automation_status.equalsIgnoreCase(STATUS_FAILED) &&
								!objCOWrapper.strConfirmationAutomationStatus.equalsIgnoreCase(STATUS_UNABLE_TO_AUDIT) &&
								!objCOWrapper.strConfirmationAutomationStatus.equalsIgnoreCase(STATUS_CARRIER_DATA_NOT_AVAILABLE)
							) {
								objCOWrapper.strConfirmationAutomationStatus = objPolicy.hi_confirmation_automation_status;
							} else if (
								objPolicy.hi_confirmation_automation_status.equalsIgnoreCase(STATUS_PENDING_AUDIT) &&
								!objCOWrapper.strConfirmationAutomationStatus.equalsIgnoreCase(STATUS_UNABLE_TO_AUDIT) &&
								!objCOWrapper.strConfirmationAutomationStatus.equalsIgnoreCase(STATUS_CARRIER_DATA_NOT_AVAILABLE) &&
								!objCOWrapper.strConfirmationAutomationStatus.equalsIgnoreCase(STATUS_FAILED)
							) {
								objCOWrapper.strConfirmationAutomationStatus = objPolicy.hi_confirmation_automation_status;
							} else if (objPolicy.hi_confirmation_automation_status.equalsIgnoreCase(STATUS_SUCCESS)) {
								if (String.isBlank(objCOWrapper.strConfirmationAutomationStatus)) {
									objCOWrapper.strConfirmationAutomationStatus = objPolicy.hi_confirmation_automation_status;
								}
								if (objCOWrapper.strConfirmationAutomationStatus.equalsIgnoreCase(STATUS_SUCCESS)) {
									objCOWrapper.strApprovalNotes += objPolicy.name + ', ';
								}
							}
						}
						String strMessage = '\n';
						strMessage +=
							'\nBenefit Type           : ' +
							objPolicy.benefit_type +
							'\nPlan Name              : ' +
							objPolicy.name +
							'\nPolicy Id              : ' +
							objPolicy.id +
							'\nStatus                 : ' +
							objPolicy.hi_confirmation_automation_status +
							'\nMessage                : ' +
							objPolicy.hi_confirmation_automation_message +
							'\nConfirmation Page Link : ' +
							objPolicy.hi_confirmation_page_link;
						objCOWrapper.strConfirmationAutomationMessage += strMessage;
					}
				}
				map_EventIdHIGrpEvent.put(objEvent.Event_Id__c, objEvent);
				map_COInfoWrapper.put(strKey, objCOWrapper);
			} catch (Exception objEx) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Error while parsing Event Info: ' + objEx.getMessage(), objEvent);
			}
		}

		if (
			map_EventIdHIGrpEvent.isEmpty() ||
			set_ApplicationIds.isEmpty() ||
			set_CompanyIds.isEmpty() ||
			set_applicationType.isEmpty() ||
			set_StateCarrierIds.isEmpty() ||
			map_COInfoWrapper.isEmpty()
		) {
			return;
		}
		updateCarrierOrders(map_EventIdHIGrpEvent, map_COInfoWrapper, set_ApplicationIds, set_CompanyIds, set_applicationType, set_StateCarrierIds);

		for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvent.values()) {
			if (objEvent.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Either relevant Carrier Order was not found or there was an error while updating it', objEvent);
			}
		}
	}

	static void updateCarrierOrders(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvent,
		Map<String, CarrierOrderInfoWrapper> map_COInfoWrapper,
		Set<String> set_ApplicationIds,
		Set<String> set_CompanyIds,
		Set<String> set_applicationType,
		Set<String> set_StateCarrierIds
	) {
		List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();

		Set<String> set_EligibleCORecTypes = new Set<String>{ 'Benefit Change', 'New Plan', 'Renewal' };
		Map<String, Carrier_Order__c> map_CarrierOrders = new Map<String, Carrier_Order__c>();
		List<Carrier_Order__c> list_COToUpdate = new List<Carrier_Order__c>();

		for (Carrier_Order__c objCO : [
			SELECT
				HI_Confirmation_Automation_Message__c,
				HI_Confirmation_Automation_Status__c,
				Carrier__r.Id__c,
				Benefit_Order__r.Application_Id__c,
				Benefit_Order__r.RecordType.Name,
				Benefit_Order__r.Account__r.ZP_Company_Id__c,
				Order_Type__c,
				Eligible_for_Confirmation_Automation__c
			FROM Carrier_Order__c
			WHERE
				Carrier__c != NULL
				AND Carrier__r.Id__c IN :set_StateCarrierIds
				AND Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c IN :set_CompanyIds
				AND Benefit_Order__r.Application_Id__c != NULL
				AND Benefit_Order__r.Application_Id__c IN :set_ApplicationIds
				AND Benefit_Order__r.RecordType.Name IN :set_applicationType
				AND (Implementation_Stage__c = :CO_STATUS_READY_FOR_CONFIRMATION
				OR Implementation_Stage__c = :CO_STATUS_APPROVED_PENDING_EE_AUDIT)
				AND RecordType.Name IN :set_EligibleCORecTypes
		]) {
			String strKey =
				objCO.Benefit_Order__r.Account__r.ZP_Company_Id__c +
				'-' +
				objCO.Benefit_Order__r.Application_Id__c +
				'-' +
				objCO.Benefit_Order__r.RecordType.Name +
				'-' +
				objCO.Carrier__r.Id__c;
			map_CarrierOrders.put(strKey, objCO);

			if (map_COInfoWrapper.containsKey(strKey)) {
				CarrierOrderInfoWrapper objCOWrapper = map_COInfoWrapper.get(strKey);
				objCO.HI_Confirmation_Automation_Message__c = objCOWrapper.strConfirmationAutomationMessage;
				objCO.HI_Confirmation_Automation_Status__c = objCOWrapper.strConfirmationAutomationStatus;

				if (String.isNotBlank(objCO.HI_Confirmation_Automation_Status__c)) {
					if (STATUS_PENDING_AUDIT.equalsIgnoreCase(objCO.HI_Confirmation_Automation_Status__c)) {
						objCO.Implementation_Stage__c = CO_STATUS_APPROVED_PENDING_EE_AUDIT;
					} else if (STATUS_SUCCESS.equalsIgnoreCase(objCO.HI_Confirmation_Automation_Status__c)) {
						objCO.Implementation_Stage__c = CO_STATUS_APPROVED;
						objCO.HI_Confirmation_Automation_End_Date_Time__c = System.now();

						if (String.isNotBlank(objCOWrapper.strApprovalNotes)) {
							objCOWrapper.strApprovalNotes = objCOWrapper.strApprovalNotes.removeEnd(', ') + ' approved via HI automation';
							objCO.Approval_Notes__c = objCOWrapper.strApprovalNotes;
						}
						objCO.Approval_Method__c = 'Approved using HI automation';
					} else if (STATUS_UNABLE_TO_AUDIT.equalsIgnoreCase(objCO.HI_Confirmation_Automation_Status__c)) {
						objCO.Eligible_for_Confirmation_Automation__c = false;
						objCO.HI_Confirmation_Automation_End_Date_Time__c = System.now();
					}
				}

				list_COToUpdate.add(objCO);

				if (String.isNotBlank(objCOWrapper.strEventId) && map_EventIdHIGrpEvent != null && map_EventIdHIGrpEvent.containsKey(objCOWrapper.strEventId)) {
					map_EventIdHIGrpEvent.get(objCOWrapper.strEventId).Processing_State__c = IntegrationUtils.PROCESSED_STATE;
				}
			}
		}
		if (!list_COToUpdate.isEmpty()) {
			try {
				Database.SaveResult[] objResults = Database.update(list_COToUpdate, true);
			} catch (Exception objEx) {
				ExceptionLogUtil.logException('ConfirmationAutomationHelper', 'updateCarrierOrders', objEx.getMessage(), objEx.getStackTraceString());
			}
		}
	}

	class CarrierOrderInfoWrapper {
		String strConfirmationAutomationStatus;
		String strConfirmationAutomationMessage;
		String strApprovalNotes;
		String strEventId;
		CarrierOrderInfoWrapper() {
			strConfirmationAutomationStatus = '';
			strConfirmationAutomationMessage = '';
			strApprovalNotes = '';
			strEventId = '';
		}
	}
}