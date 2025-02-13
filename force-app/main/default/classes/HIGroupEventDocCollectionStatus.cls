/**
 * @name         HIGroupEventDocCollectionStatus
 * @author       Deepika Saini
 * @Date         02/09/2021
 * @description  This class handles the messages sent to kafka topic document_collection via Workato and writes it to the HIGroupEvent__c object
 * @test class   HIGroupEventDocCollectionStatusTest.cls
 **/
public class HIGroupEventDocCollectionStatus {
	/*
	 * Process HIGroupEvents and copy information to Benefit Orders
	 */
	public static void processEvents(List<HIGroupEvent__c> list_Events) {
		Set<String> set_ApplicationIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_ApplicationType = new Set<String>();
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvent = new Map<String, HIGroupEvent__c>();
		Map<String, BenefitOrderInfoWrapper> map_BenefitOrderInfoWrap = new Map<String, BenefitOrderInfoWrapper>();

		if (list_Events == null || list_Events.isEmpty()) {
			return;
		}

		for (HIGroupEvent__c objEvent : list_Events) {
			if (String.isBlank(objEvent.Event_Info__c)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EVENT_INFO_MISSING, objEvent);
				continue;
			}

			try {
				HIGroupEventDocCollectionJSON objEventInfoJSON = (HIGroupEventDocCollectionJSON) JSON.deserialize(objEvent.Event_Info__c, HIGroupEventDocCollectionJSON.class);
				if (String.isBlank(objEvent.Application_Id__c)) {
					if (String.isBlank(objEventInfoJSON.application_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING, objEvent);
						continue;
					}

					objEvent.Application_Id__c = objEventInfoJSON.application_id;
				}

				if (String.isBlank(objEvent.Application_type__c)) {
					if (String.isBlank(objEventInfoJSON.application_type)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_APPLICATION_TYPE_MISSING, objEvent);
						continue;
					}

					objEvent.Application_type__c = objEventInfoJSON.application_type;
				}

				if (String.isBlank(objEvent.Company_Id__c)) {
					if (String.isBlank(objEventInfoJSON.company_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_COMPANY_ID_MISSING, objEvent);
						continue;
					}

					objEvent.Company_Id__c = objEventInfoJSON.company_id;
				}

				if (String.isBlank(objEvent.Documents_Status__c)) {
					if (String.isBlank(objEventInfoJSON.documents_status)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_DOC_COLLECTION_STATUS_MISSING, objEvent);
						continue;
					}

					objEvent.Documents_Status__c = objEventInfoJSON.documents_status;
				}

				set_ApplicationIds.add(objEvent.Application_Id__c);
				set_CompanyIds.add(objEvent.Company_Id__c);
				set_ApplicationType.add(objEvent.Application_type__c);

				String strKey = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + objEvent.Application_type__c;

				map_EventIdHIGrpEvent.put(objEvent.Event_Id__c, objEvent);
				BenefitOrderInfoWrapper objBOWrap = new BenefitOrderInfoWrapper(objEventInfoJSON.documents_status, objEvent.Event_Id__c);
				map_BenefitOrderInfoWrap.put(strKey, objBOWrap);
			} catch (Exception objEx) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Error while parsing Event Info: ' + objEx.getMessage(), objEvent);
			}
		}

		try {
			if (map_EventIdHIGrpEvent.isEmpty() || set_ApplicationIds.isEmpty() || set_CompanyIds.isEmpty() || set_ApplicationType.isEmpty()) {
				return;
			}

			updateBenefitOrders(map_EventIdHIGrpEvent, map_BenefitOrderInfoWrap, set_ApplicationIds, set_CompanyIds, set_ApplicationType);
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('HIGroupEventDocCollectionStatus', 'processEvents', objEx);
		}
	}

	/**Update Document Collection Status on Benefit Orders */
	static void updateBenefitOrders(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvent,
		Map<String, BenefitOrderInfoWrapper> map_BenefitOrderInfoWrap,
		Set<String> set_ApplicationIds,
		Set<String> set_CompanyIds,
		Set<String> set_ApplicationType
	) {
		Map<String, String> map_EventIdToBenefitOrder = new Map<String, String>();
		List<Benefit_Order__c> list_BOToUpdate = new List<Benefit_Order__c>();

		for (Benefit_Order__c objBO : [
			SELECT Application_Id__c, RecordType.Name, Account__r.ZP_Company_Id__c, Type__c, Order_Status__c, Coverage_Effective_Date__c
			FROM Benefit_Order__c
			WHERE
				Account__c != NULL
				AND Account__r.ZP_Company_Id__c != NULL
				AND Account__r.ZP_Company_Id__c IN :set_CompanyIds
				AND Application_Id__c != NULL
				AND Application_Id__c IN :set_ApplicationIds
				AND RecordType.Name IN :set_applicationType
			FOR UPDATE
		]) {
			String strKey = objBO.Account__r.ZP_Company_Id__c + '-' + objBO.Application_Id__c + '-' + objBO.RecordType.Name;
			if (map_BenefitOrderInfoWrap.containsKey(strKey)) {
				BenefitOrderInfoWrapper objBOWrapper = map_BenefitOrderInfoWrap.get(strKey);

				map_EventIdToBenefitOrder.put(objBOWrapper.strEventId, objBO.Id);
				if (String.isNotBlank(objBOWrapper.strDocCollectionStatus)) {
					objBO.Documents_Status__c = objBOWrapper.strDocCollectionStatus;
					list_BOToUpdate.add(objBO);
				}
			}
		}
		
		if (!list_BOToUpdate.isEmpty()) {
			try {
				Database.SaveResult[] objResults = Database.update(list_BOToUpdate, false);

				Map<String, String> map_BOUpdateErrors = new Map<String, String>();
				map_BOUpdateErrors = Utils.processSaveRecords(objResults, list_BOToUpdate, 'Id', true, 'HIGroupEventDocCollectionStatus', 'updateBenefitOrders');

				for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvent.values()) {
					String strBenefitOrderId;

					if (objEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
						continue;
					}

					if (!map_EventIdToBenefitOrder.containsKey(objEvent.Event_Id__c)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.DOC_COLLECTION_ERROR_UNPROCESSED_EVENT, objEvent);
						continue;
					}

					strBenefitOrderId = map_EventIdToBenefitOrder.get(objEvent.Event_Id__c);

					if (map_BOUpdateErrors.containsKey(strBenefitOrderId)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_BOUpdateErrors.get(strBenefitOrderId), objEvent);
						continue;
					} else {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIGroupEventUtil.DOC_COLLECTION_PROCESSED_MESSAGE, objEvent);
					}
				}
			} catch (Exception objEx) {
				ExceptionLogUtil.logException('HIGroupEventDocCollectionStatus', 'updateBenefitOrders', objEx);
			}
		} else {
			for (String strEventId : map_EventIdHIGrpEvent.keySet()) {
				if (map_EventIdHIGrpEvent.containsKey(strEventId) == false) {
					continue;
				}

				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIGroupEventUtil.DOC_COLLECTION_DEAD_UNPROCESSED_EVENT, map_EventIdHIGrpEvent.get(strEventId));
			}
		}
	}

	class BenefitOrderInfoWrapper {
		String strDocCollectionStatus;
		String strEventId;
		BenefitOrderInfoWrapper(String strStatus, String strEvent) {
			strDocCollectionStatus = strStatus;
			strEventId = strEvent;
		}
	}
}