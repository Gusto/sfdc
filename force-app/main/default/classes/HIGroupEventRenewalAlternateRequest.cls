/**
 * @name         HIGroupEventRenewalAlternateRequest
 * @author       Bhagat Singh
 * @Date         22 July 2021
 * @description  This class  notified when a customer has requested alternate plans by completing the in-app survey.
 * @test class   HIGroupEventRenewalAlternateRequestTest.cls
 **/
public class HIGroupEventRenewalAlternateRequest {
	public static final String OPP_RT_BENEFITS_RENEWAL = 'Benefits Renewal';
	public static final String OPP_STAGE_NAME = 'Alternates Requested';
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Process HIGroupEvents (type = renewal_alternates_requested) and update Opportunity stage.
	 * @Parm        : List of HIGroupEvent__c records.
	 * @Return      : void
	 **/
	public static void processEvents(List<HIGroupEvent__c> list_Events) {
		Set<String> set_ApplicationIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents = new Map<String, HIGroupEvent__c>();
		Map<String, OpportunityInfoWrapper> map_OpportunityInfoWraps = new Map<String, OpportunityInfoWrapper>();

		if (list_Events == null || list_Events.isEmpty()) {
			return;
		}

		for (HIGroupEvent__c objEvent : list_Events) {
			if (String.isBlank(objEvent.Event_Info__c)) {
				HIGroupEventTriggerHelper.setProcessingState(
					IntegrationUtils.ERROR_STATE,
					HIGroupEventUtil.ERROR_EVENT_INFO_MISSING,
					objEvent
				);
				continue;
			}

			try {
				HIGroupEventRenewalAlternateRequestJSON objEventInfoJSON = (HIGroupEventRenewalAlternateRequestJSON) JSON.deserialize(
					objEvent.Event_Info__c,
					HIGroupEventRenewalAlternateRequestJSON.class
				);

				if (String.isBlank(objEvent.Application_Id__c)) {
					if (String.isBlank(objEventInfoJSON.application_id)) {
						HIGroupEventTriggerHelper.setProcessingState(
							IntegrationUtils.ERROR_STATE,
							HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING,
							objEvent
						);
						continue;
					}

					objEvent.Application_Id__c = objEventInfoJSON.application_id;
				}

				if (String.isBlank(objEventInfoJSON.alternate_packages_requested_timestamp)) {
					HIGroupEventTriggerHelper.setProcessingState(
						IntegrationUtils.ERROR_STATE,
						HIGroupEventUtil.ERROR_ALTERNATE_REQ_DATE,
						objEvent
					);
					continue;
				}

				if (String.isBlank(objEvent.Company_Id__c)) {
					if (String.isBlank(objEventInfoJSON.company_id)) {
						HIGroupEventTriggerHelper.setProcessingState(
							IntegrationUtils.ERROR_STATE,
							HIGroupEventUtil.ERROR_COMPANY_ID_MISSING,
							objEvent
						);
						continue;
					}

					objEvent.Company_Id__c = objEventInfoJSON.company_id;
				}

				set_ApplicationIds.add(objEvent.Application_Id__c);
				set_CompanyIds.add(objEvent.Company_Id__c);

				String strKey =
					objEvent.Company_Id__c +
					'-' +
					objEvent.Application_Id__c +
					'-' +
					OPP_RT_BENEFITS_RENEWAL;

				String strUnixDateTime = objEventInfoJSON.alternate_packages_requested_timestamp;
				strUnixDateTime = strUnixDateTime.trim();
				if (String.isNotBlank(strUnixDateTime)) {
					while (strUnixDateTime.length() < 13) {
						strUnixDateTime = strUnixDateTime + '0';
					}
				}

				map_EventIdHIGrpEvents.put(objEvent.Event_Id__c, objEvent);
				OpportunityInfoWrapper objOppWrap = new OpportunityInfoWrapper(
					strUnixDateTime,
					objEvent.Event_Id__c
				);
				map_OpportunityInfoWraps.put(strKey, objOppWrap);
			} catch (Exception objEx) {
				HIGroupEventTriggerHelper.setProcessingState(
					IntegrationUtils.ERROR_STATE,
					'Error while parsing Event Info: ' + objEx.getMessage(),
					objEvent
				);
			}
		}

		try {
			if (map_EventIdHIGrpEvents.isEmpty() || set_ApplicationIds.isEmpty() || set_CompanyIds.isEmpty()) {
				return;
			}

			updateOpportunityStage(
				map_EventIdHIGrpEvents,
				map_OpportunityInfoWraps,
				set_ApplicationIds,
				set_CompanyIds
			);
		} catch (Exception objEx) {
			createErrorLog(objEx);
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update Opportunity Stage as 'Alternates Requested'.
	 * @Parm        : Map of Event Id with HIGroupEvent__c object
					: Map of "Company_Id__c +  Application_Id__c + OPP_RT_BENEFITS_RENEWAL" with HIGroupEvent__c object
	  				: Set of Application_Id__c
	  				: Set of Company_Id__c
	 * @Return      : void  
	 **/
	static void updateOpportunityStage(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents,
		Map<String, OpportunityInfoWrapper> map_OpportunityInfoWraps,
		Set<String> set_ApplicationIds,
		Set<String> set_CompanyIds
	) {
		Map<String, String> map_EventIdToBenefitOrders = new Map<String, String>();
		List<Opportunity> list_OppsToUpdate = new List<Opportunity>();

		for (Opportunity objOpp : [
			SELECT
				Id,
				StageName,
				RecordType.Name,
				Account.ZP_Company_Id__c,
				Application_Id__c,
				Alternates_Requested_Timestamp__c
			FROM Opportunity
			WHERE
				AccountId != null
				AND Account.ZP_Company_Id__c != null
				AND Account.ZP_Company_Id__c IN :set_CompanyIds
				AND Application_Id__c != null
				AND RecordTypeId != null
				AND Application_Id__c IN :set_ApplicationIds
				AND RecordType.Name = :OPP_RT_BENEFITS_RENEWAL
			FOR UPDATE
		]) {
			String strKey =
				objOpp.Account.ZP_Company_Id__c +
				'-' +
				objOpp.Application_Id__c +
				'-' +
				objOpp.RecordType.Name;

			if (map_OpportunityInfoWraps.containsKey(strKey)) {
				OpportunityInfoWrapper objOppWrapper = map_OpportunityInfoWraps.get(strKey);

				map_EventIdToBenefitOrders.put(objOppWrapper.strEventId, objOpp.Id);
				objOpp.StageName = OPP_STAGE_NAME;
				objOpp.Alternates_Requested_Timestamp__c = objOppWrapper.dtAlternatePackage;
				list_OppsToUpdate.add(objOpp);
			}
		}

		if (!list_OppsToUpdate.isEmpty()) {
			try {
				Database.SaveResult[] objResults = Database.update(list_OppsToUpdate, false);

				Map<String, String> map_BOUpdateErrors = new Map<String, String>();
				map_BOUpdateErrors = Utils.processSaveRecords(
					objResults,
					list_OppsToUpdate,
					'Id',
					true,
					'HIGroupEventRenewalAlternateRequest',
					'updateOpportunityStage'
				);

				for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvents.values()) {
					String strBenefitOrderId;

					if (
						objEvent.Processing_State__c == IntegrationUtils.DEAD_STATE ||
						objEvent.Processing_State__c == IntegrationUtils.ERROR_STATE
					) {
						continue;
					}

					if (!map_EventIdToBenefitOrders.containsKey(objEvent.Event_Id__c)) {
						HIGroupEventTriggerHelper.setProcessingState(
							IntegrationUtils.ERROR_STATE,
							HIGroupEventUtil.ERROR_UNPROCESSED_EVENT_OPP_UPDATE,
							objEvent
						);
						continue;
					}

					strBenefitOrderId = map_EventIdToBenefitOrders.get(objEvent.Event_Id__c);

					if (map_BOUpdateErrors.containsKey(strBenefitOrderId)) {
						HIGroupEventTriggerHelper.setProcessingState(
							IntegrationUtils.ERROR_STATE,
							map_BOUpdateErrors.get(strBenefitOrderId),
							objEvent
						);
						continue;
					} else {
						HIGroupEventTriggerHelper.setProcessingState(
							IntegrationUtils.PROCESSED_STATE,
							HIGroupEventUtil.GROUP_RENEWAL_PROCESSED_MESSAGE,
							objEvent
						);
					}
				}
			} catch (Exception objEx) {
				createErrorLog(objEx);
			}
		} else {
			for (String strEventId : map_EventIdHIGrpEvents.keySet()) {
				if (map_EventIdHIGrpEvents.containsKey(strEventId) == false) {
					continue;
				}

				HIGroupEventTriggerHelper.setProcessingState(
					IntegrationUtils.DEAD_STATE,
					HIGroupEventUtil.RENEWAL_DEAD_UNPROCESSED_EVENT,
					map_EventIdHIGrpEvents.get(strEventId)
				);
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Error Logs.
	 * @Parm        : Exception object.
	 * @Return      : void
	 **/
	public static void createErrorLog(Exception objEx) {
		ExceptionLogUtil.logException(
			'HIGroupEventRenewalAlternateRequest',
			'updateOpportunity',
			'Exception On Line ' +
			objEx.getLineNumber() +
			'-' +
			objEx.getMessage(),
			objEx.getStackTraceString()
		);
	}

	/**
	 * @name         OpportunityInfoWrapper
	 * @author       Bhagat Singh
	 * @Date         23 July 2021
	 * @description  This class handles the Opportunity Info getting from json response
	 * @test class   HIGroupEventRenewalAlternateRequest.cls
	 **/
	class OpportunityInfoWrapper {
		DateTime dtAlternatePackage;
		String strEventId;
		OpportunityInfoWrapper(String strUnixDateTime, String strEvent) {
			if (String.isNotBlank(strUnixDateTime)) {
				this.dtAlternatePackage = DateTime.newInstance(Long.valueOf(strUnixDateTime));
			}
			this.strEventId = strEvent;
		}
	}
}