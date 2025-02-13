/**
 * @name         HIGroupEventTerminationCases
 * @author       Rushi R
 * @Date         31 May 2023
 * @description  This class handles creation of Termination Cases based on group_termination_case event
 * @test class   HIGroupEventTerminationCasesTest.cls
 **/
public without sharing class HIGroupEventTerminationCases {
	public static Boolean blnTestException = false;
	public static Map<String, String> map_FixedCarriers = new Map<String, String>{'basic' => Label.BASIC_Carrier };
	public static Map<String, Carrier__c> map_Carriers = new Map<String, Carrier__c>();
	public static Set<String> set_UpdatedTerminationType = new Set<String> {CaseUtils.TYPE_RESCIND_TERMINATE, HIGroupEventUtil.TYPE_PARTIAL_COVERAGE_TERMINATION};

	/**
	 * @Author      : Rushi R
	 * @Description : Process HIGroupEvents and create Group Termination cases.
	 * @Parm        : List of HIGroupEvent__c records.
	 **/
	public static void processEvents(List<HIGroupEvent__c> list_Events) {
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_ApplicationIds = new Set<String>();
		Set<String> set_CarrierKeys = new Set<String>(map_FixedCarriers.values());
		Map<String, String> map_GroupTermIdEventId = new Map<String, String>();
		Map<String, HIGroupEvent__c> map_HIGroupEvents = new Map<String, HIGroupEvent__c>();
		Map<String, Account> map_Accounts = new Map<String, Account>();
		Map<String, List<Case>> map_Cases = new Map<String, List<Case>>();

		if (list_Events == null || list_Events.isEmpty()) {
			return;
		}

		Set<String> set_ValidReasons = new Set<String>();
		for (Schema.PicklistEntry objPle : Case.Reason_for_Leaving__c.getDescribe().getPicklistValues()) {
			set_ValidReasons.add(objPle.getValue());
		}

		for (HIGroupEvent__c objEvent : list_Events) {
			if (String.isBlank(objEvent.Event_Info__c)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EVENT_INFO_MISSING, objEvent);
				continue;
			}

			try {
				HIGroupTerminationCaseJSON objEventInfo = (HIGroupTerminationCaseJSON) JSON.deserialize(objEvent.Event_Info__c, HIGroupTerminationCaseJSON.class);
				if (String.isNotBlank(objEventInfo.event_id)) {
					objEvent.Event_Id__c = objEventInfo.event_id;
				} else {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EVENT_ID_MISSING, objEvent);
					continue;
				}

				if (String.isBlank(objEvent.Company_Id__c)) {
					if (String.isBlank(objEventInfo.company_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_COMPANY_ID_MISSING, objEvent);
						continue;
					}
					objEvent.Company_Id__c = objEventInfo.company_id;
				}
				set_CompanyIds.add(objEvent.Company_Id__c);

				if (String.isBlank(objEvent.Application_Id__c) && String.isNotBlank(objEventInfo.application_id)) {
					objEvent.Application_Id__c = objEventInfo.application_id;
				}

				if (String.isNotBlank(objEventInfo.termination_reason) && !set_ValidReasons.contains(objEventInfo.termination_reason)) {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_INVALID_TERM_REASON, objEvent);
					continue;
				}

				if (
					String.isNotBlank(objEventInfo.termination_type) &&
					set_UpdatedTerminationType.contains(objEventInfo.termination_type) &&
					String.isNotBlank(objEventInfo.group_termination_event_id)
				) {
					map_GroupTermIdEventId.put(objEventInfo.group_termination_event_id, objEvent.Event_Id__c);
				}

				if (String.isNotBlank(objEventInfo.new_provider_key)) {
					set_CarrierKeys.add(objEventInfo.new_provider_key);
				}

				if (String.isNotBlank(objEventInfo.terminating_provider_key)) {
					set_CarrierKeys.add(objEventInfo.terminating_provider_key);
				}

				map_HIGroupEvents.put(objEvent.Event_Id__c, objEvent);
			} catch (Exception objEx) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Error while parsing Event Info: ' + objEx.getMessage(), objEvent);
				ExceptionLogUtil.logException('HIGroupEventTerminationCases', 'processEvents', objEx);
			}
		}

		if (!set_CompanyIds.isEmpty()) {
			map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_CompanyIds);
			for (HIGroupEvent__c objEvent : map_HIGroupEvents.values()) {
				if (!map_Accounts.containsKey(objEvent.Company_Id__c)) {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.COMPANY_DOES_NOT_EXIST, objEvent);
					map_HIGroupEvents.remove(objEvent.Event_Id__c);
					continue;
				}
			}
		}

		if (map_HIGroupEvents.isEmpty()) {
			return;
		}

		if (!set_CarrierKeys.isEmpty()) {
			for (Carrier__c objCarrier : [SELECT Id, Name, Key__c FROM Carrier__c WHERE Key__c IN :set_CarrierKeys OR Id IN :set_CarrierKeys]) {
				String str15CharId = String.valueOf(objCarrier.Id).left(15);
				String strMapKey = ((str15CharId == Label.BASIC_Carrier) ? 'basic' : objCarrier.Key__c);
				map_Carriers.put(strMapKey, objCarrier);
			}
		}

		Set<String> set_EventIdExistingCase = new Set<String>();
		if (!map_GroupTermIdEventId.isEmpty()) {
			map_Cases = getCasesbyEventIds(map_GroupTermIdEventId.keySet());
			for (String strValue : map_GroupTermIdEventId.keySet()) {
				if (map_Cases.containsKey(strValue)) {
					set_EventIdExistingCase.add(map_GroupTermIdEventId.get(strValue));
				}
			}
		}

		List<HIGroupEvent__c> list_EventsToCreateCase = new List<HIGroupEvent__c>();
		List<HIGroupEvent__c> list_EventsToUpdateCase = new List<HIGroupEvent__c>();
		for (HIGroupEvent__c objEvent : map_HIGroupEvents.values()) {
			if (set_EventIdExistingCase.contains(objEvent.Event_Id__c)) {
				list_EventsToUpdateCase.add(objEvent);
			} else {
				list_EventsToCreateCase.add(objEvent);
			}
		}

		List<Case> list_CasesToUpsert = new List<Case>();
		if (!list_EventsToCreateCase.isEmpty() && !map_Accounts.isEmpty()) {
			list_CasesToUpsert.addAll(createCases(list_EventsToCreateCase, map_Accounts));
		}

		if (!list_EventsToUpdateCase.isEmpty() && !map_Cases.isEmpty()) {
			list_CasesToUpsert.addAll(updateCases(list_EventsToUpdateCase, map_Cases, map_Accounts));
		}

		Map<String, String> map_CasesDMLStatus = new Map<String, String>();
		if (!list_CasesToUpsert.isEmpty()) {
			try {
				if (Test.isRunningTest() && blnTestException) {
					Integer intException = 1 / 0;
				}

				CaseTriggerHelper.skipTrigger = true;
				List<Database.UpsertResult> saveResult = Database.Upsert(list_CasesToUpsert, false);
				map_CasesDMLStatus = Utils.processUpsertResult(saveResult, list_CasesToUpsert, 'Integration_Id__c', true, 'HIGroupEventTerminationCases-upsertCases');
				CaseTriggerHelper.skipTrigger = false;
			} catch (Exception objEx) {
				ExceptionLogUtil.logException('HIGroupEventTerminationCases', 'processEvents', objEx);
			}
		}

		for (HIGroupEvent__c objEvent : map_HIGroupEvents.values()) {
			if (map_CasesDMLStatus.containsKey(objEvent.Event_Id__c)) {
				String strErrorMessage = 'Unable to process HI Group Event record' + '\n' + map_CasesDMLStatus.get(objEvent.Event_Id__c);
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, strErrorMessage, objEvent);
			} else {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, 'HI Group Event processed successfully', objEvent);
			}
		}
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Create Group Termination Cases
	 * @Parm        : List of HIGroupEvent__c records to process
	                : Map of Account with Company_Id__c as Key
	 * @Return      : List of Cases to be inserted
	 **/
	static List<Case> createCases(List<HIGroupEvent__c> list_HIGroupEvents, Map<String, Account> map_Accounts) {
		Set<String> set_ContactIds = new Set<String>();
		Set<String> set_BenefitOrderKey = new Set<String>();
		Set<String> set_CarrierOrderKey = new Set<String>();

		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		Map<String, Benefit_Order__c> map_BenefitOrders = new Map<String, Benefit_Order__c>();
		Map<String, Carrier_Order__c> map_CarrierOrders = new Map<String, Carrier_Order__c>();

		Map<String, String> map_TypeDescriptionMap = new Map<String, String> {
			CaseUtils.TYPE_TOTAL_GROUP_TERMINATE.toLowerCase() => Label.Group_Term_Total_Group_Term_Description,
			CaseUtils.TYPE_BENEFITS_SUSPEND.toLowerCase() => Label.Group_Term_Benefit_Suspend_Description,
			CaseUtils.TYPE_TERMINATE_CARRIER.toLowerCase() => Label.Group_Term_Terminate_Carrier_Description,
			CaseUtils.TYPE_CARRIER_SWITCH.toLowerCase() => Label.Group_Term_Carrier_Switch_Term_Description,
			CaseUtils.TYPE_RESCIND_TERMINATE.toLowerCase() => Label.Group_Term_Rescind_Term_Description,
			CaseUtils.TYPE_BOR_TERMINATE.toLowerCase() => Label.Group_Term_BoR_Termination_Description
		};

		for (HIGroupEvent__c objEvent : list_HIGroupEvents) {
			HIGroupTerminationCaseJSON objEventInfo = (HIGroupTerminationCaseJSON) JSON.deserialize(objEvent.Event_Info__c, HIGroupTerminationCaseJSON.class);

			if (String.isNotBlank(objEventInfo.contact_id)) {
				set_ContactIds.add(objEventInfo.contact_id);
			}

			if (String.isNotBlank(objEventInfo.application_id)) {
				String strBOKey, strCOKey;
				if (String.isNotBlank(objEventInfo.application_type)) {
					strBOKey = objEventInfo.application_id + '#' + objEventInfo.application_type;
					set_BenefitOrderKey.add(strBOKey);

					if (String.isNotBlank(objEventInfo.new_provider_key)) {
						String strIdValue = objEventInfo.new_provider_key;
						if (map_FixedCarriers.containsKey(objEventInfo.new_provider_key)) {
							strIdValue = map_FixedCarriers.get(objEventInfo.new_provider_key);
						}
						strCOKey = strBOKey + '#' + strIdValue;
						set_CarrierOrderKey.add(strCOKey);
					}
				}
			}
		}

		if (!set_ContactIds.isEmpty()) {
			for (Contact objContact : [SELECT Id, ZP_User_Id__c FROM Contact WHERE ZP_User_Id__c IN :set_ContactIds]) {
				map_Contacts.put(objContact.ZP_User_Id__c, objContact);
			}
		}

		if (!set_BenefitOrderKey.isEmpty()) {
			Set<String> set_ApplicationIds = new Set<String>();
			Set<String> set_ApplicationTypes = new Set<String>();

			for (String objString : set_BenefitOrderKey) {
				List<String> list_SplitString = objString.split('#');
				set_ApplicationIds.add(list_SplitString[0]);
				set_ApplicationTypes.add(list_SplitString[1]);
			}

			for (Benefit_Order__c objBO : [
				SELECT Id, Name, Application_Id__c, Application_Type__c
				FROM Benefit_Order__c
				WHERE Application_Id__c IN :set_ApplicationIds AND Application_Type__c IN :set_ApplicationTypes
			]) {
				map_BenefitOrders.put(objBO.Application_Id__c + '#' + objBO.Application_Type__c, objBO);
			}
		}

		if (!set_CarrierOrderKey.isEmpty()) {
			Set<String> set_ApplicationIds = new Set<String>();
			Set<String> set_ApplicationTypes = new Set<String>();
			Set<String> set_TempCarrierIds = new Set<String>();

			for (String objString : set_CarrierOrderKey) {
				List<String> list_SplitString = objString.split('#');
				set_ApplicationIds.add(list_SplitString[0]);
				set_ApplicationTypes.add(list_SplitString[1]);

				String strCarrierId = list_SplitString[2];
				if (map_Carriers.containsKey(list_SplitString[2])) {
					strCarrierId = map_Carriers.get(list_SplitString[2]).Id;
				}
				set_TempCarrierIds.add(strCarrierId);
			}

			for (Carrier_Order__c objCO : [
				SELECT Id, Name, Application_Id__c, Application_Type__c, Carrier__c
				FROM Carrier_Order__c
				WHERE Application_Id__c IN :set_ApplicationIds AND Application_Type__c IN :set_ApplicationTypes AND Carrier__c IN :set_TempCarrierIds
			]) {
				map_CarrierOrders.put(objCO.Application_Id__c + '#' + objCO.Application_Type__c + '#' + objCO.Carrier__c, objCO);
			}
		}

		List<Case> list_CasesToInsert = new List<Case>();
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_ApplicationIds = new Set<String>();
		
		for (HIGroupEvent__c objEventData : list_HIGroupEvents) {
		  if (objEventData.Processing_State__c == IntegrationUtils.ERROR_STATE) {
			continue;
		  }
		  
		  if (String.isNotBlank(objEventData.Company_Id__c)) {
			set_CompanyIds.add(objEventData.Company_Id__c);
		  }
		  
		  if (String.isNotBlank(objEventData.Application_Id__c)) {
			set_ApplicationIds.add(objEventData.Application_Id__c);
		  }
		}
		
		Map<String, String> map_ExistingOpportunity = new Map<String, String>();
		if(!set_ApplicationIds.isEmpty()){
		  for (Opportunity opportunity : [
		    SELECT Id, Application_Id__c, ZP_Company_ID_from_Account__c
			FROM Opportunity
			WHERE
			RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
			AND ZP_Company_ID_from_Account__c IN :set_CompanyIds
			AND Application_Id__c IN :set_ApplicationIds
		  ]) {
			map_ExistingOpportunity.put(
			opportunity.ZP_Company_ID_from_Account__c + '-' + opportunity.Application_Id__c,
			opportunity.Id
			);
		  }
		}
		
		for (HIGroupEvent__c objEvent : list_HIGroupEvents) {
			HIGroupTerminationCaseJSON objEventInfo = (HIGroupTerminationCaseJSON) JSON.deserialize(objEvent.Event_Info__c, HIGroupTerminationCaseJSON.class);

			Account objAccount;
			if (!map_Accounts.isEmpty() && map_Accounts.containsKey(objEvent.Company_Id__c)) {
				objAccount = map_Accounts.get(objEvent.Company_Id__c);
			}

			Contact objContact;
			if (!map_Contacts.isEmpty() && String.isNotBlank(objEventInfo.contact_id) && map_Contacts.containsKey(objEventInfo.contact_id)) {
				objContact = map_Contacts.get(objEventInfo.contact_id);
			}

			Carrier__c objCarrier;
			if (!map_Carriers.isEmpty() && String.isNotBlank(objEventInfo.terminating_provider_key) && map_Carriers.containsKey(objEventInfo.terminating_provider_key)) {
				objCarrier = map_Carriers.get(objEventInfo.terminating_provider_key);
			}

			Benefit_Order__c objBO;
			Carrier_Order__c objCO;
			if (String.isNotBlank(objEventInfo.application_id)) {
				String strBOKey, strCOKey;
				if (String.isNotBlank(objEventInfo.application_type)) {
					strBOKey = objEventInfo.application_id + '#' + objEventInfo.application_type;
					if (String.isNotBlank(objEventInfo.new_provider_key)) {
						String strIdValue = objEventInfo.new_provider_key;
						if (map_Carriers.containsKey(objEventInfo.new_provider_key)) {
							strIdValue = map_Carriers.get(objEventInfo.new_provider_key).Id;
						}
						strCOKey = strBOKey + '#' + strIdValue;
					}
				}

				if (!map_BenefitOrders.isEmpty() && String.isNotBlank(strBOKey) && map_BenefitOrders.containsKey(strBOKey)) {
					objBO = map_BenefitOrders.get(strBOKey);
				}

				if (!map_CarrierOrders.isEmpty() && String.isNotBlank(strCOKey) && map_CarrierOrders.containsKey(strCOKey)) {
					objCO = map_CarrierOrders.get(strCOKey);
				}
			}

			Date dtCoverateEndDate = String.isNotBlank(objEventInfo.coverage_end_date) ? Date.valueOf(objEventInfo.coverage_end_date) : null;
			Date dtTerminationEndDate = String.isNotBlank(objEventInfo.termination_deadline) ? Date.valueOf(objEventInfo.termination_deadline) : null;

			String strBenefitType = !objEventInfo.benefit_types.isEmpty() ? String.join(objEventInfo.benefit_types, '; ') : null;
			String strCaseDescription = '';
			String strTerminationType = String.isNotBlank(objEventInfo.termination_type) ? objEventInfo.termination_type.toLowerCase() : null;
			if (String.isNotBlank(strTerminationType) && map_TypeDescriptionMap.containsKey(strTerminationType)) {
				strCaseDescription = String.format(
					map_TypeDescriptionMap.get(strTerminationType),
					new List<String>{ objAccount?.Name, objCarrier?.Name, String.valueOf(dtCoverateEndDate), String.valueOf(dtTerminationEndDate), objEventInfo.form_link }
				);
			} else if (HIGroupEventUtil.TYPE_PARTIAL_COVERAGE_TERMINATION == strTerminationType) {
				strCaseDescription = String.format(
					Label.Group_Termination_Partial_Coverage_Termination_Case_Descriptions,
					new List<String>{ objAccount?.Name, objCarrier?.Name, strBenefitType.replaceAll(';', ',') }
				);
			}

			Case objCase = new Case(
				RecordTypeId = CaseUtils.RECTYPE_GROUP_TERMINATION,
				Integration_Id__c = objEventInfo.event_id,
				Event_Id__c = objEventInfo.group_termination_event_id,
				Type = String.isNotBlank(objEventInfo.termination_type) ? objEventInfo.termination_type : null,
				Reason_for_Leaving__c = String.isNotBlank(objEventInfo.termination_reason) ? objEventInfo.termination_reason : null,
				Subject = objAccount?.Name + ': ' + objCarrier?.Name + ': ' + 'Group Termination',
				AccountId = objAccount?.Id,
				Opportunity__c = !map_ExistingOpportunity.isEmpty() && map_ExistingOpportunity.containsKey(objEventInfo.company_id + '-' + objEventInfo.application_id) ? Id.valueof(map_ExistingOpportunity.get(objEventInfo.company_id + '-' + objEventInfo.application_id)) : null,
				Company_Id__c = objEvent?.Company_Id__c,
				Benefit_Order__c = objBO?.Id,
				Carrier_Order__c = objCO?.Id,
				Carrier__c = objCarrier?.Id,
				MF_Group_Number__c = objEventInfo.group_number,
				Benefit_Types__c = strBenefitType,
				Termination_Date__c = dtTerminationEndDate,
				MF_Coverage_End_Date__c = dtCoverateEndDate,
				ContactId = objContact?.Id,
				Origin = 'Hippo',
				Description = strCaseDescription
			);
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			objCase.setOptions(dmo);
			list_CasesToInsert.add(objCase);
		}

		return list_CasesToInsert;
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Update Group Termination Cases
	 * @Parm        : List of HIGroupEvent__c records to process
	                : Map of Cases with group_termination_event_id as Key
	 * @Return      : List of Cases to be inserted
	 **/
	static List<Case> updateCases(List<HIGroupEvent__c> list_HIGroupEvents, Map<String, List<Case>> map_Cases, Map<String, Account> map_Accounts) {
		Set<String> set_ChangeStatus = new Set<String>{ CaseUtils.STATUS_NEW, CaseUtils.CASE_STATUS_PENDING, CaseUtils.STATUS_SUBMITTED };
		Set<String> set_ChangeType = new Set<String>{ CaseUtils.STATUS_SUBMITTED, CaseUtils.STATUS_CLOSED };

		List<Case> list_CasesToUpdate = new List<Case>();
		for (HIGroupEvent__c objEvent : list_HIGroupEvents) {
			HIGroupTerminationCaseJSON objEventInfo = (HIGroupTerminationCaseJSON) JSON.deserialize(objEvent.Event_Info__c, HIGroupTerminationCaseJSON.class);
			if (objEventInfo?.termination_type != null && !set_UpdatedTerminationType.contains(objEventInfo.termination_type)) {
				continue;
			}

			Account objAccount;
			if (!map_Accounts.isEmpty() && map_Accounts.containsKey(objEvent.Company_Id__c)) {
				objAccount = map_Accounts.get(objEvent.Company_Id__c);
			}
						
			Carrier__c objCarrier;
			if (!map_Carriers.isEmpty() && String.isNotBlank(objEventInfo.terminating_provider_key) && map_Carriers.containsKey(objEventInfo.terminating_provider_key)) {
				objCarrier = map_Carriers.get(objEventInfo.terminating_provider_key);
			}
			
			String strBenefitType = !objEventInfo.benefit_types.isEmpty() ? String.join(objEventInfo.benefit_types, ', ') : null;
			List<Case> list_Cases = map_Cases.get(objEventInfo.group_termination_event_id);
			if (list_Cases != null && !list_Cases.isEmpty()) {
				Id idCarrierId = null;
				if (!map_Carriers.isEmpty() && String.isNotBlank(objEventInfo.terminating_provider_key) && map_Carriers.containsKey(objEventInfo.terminating_provider_key)) {
					idCarrierId = map_Carriers.get(objEventInfo.terminating_provider_key).Id;
				}

				for (Case objCase : list_Cases) {
					Boolean blnUpdateCase = false;
					Boolean blnCarrierMatch = (idCarrierId == null || (idCarrierId != null && objCase.Carrier__c != null && objCase.Carrier__c == idCarrierId));

					if (set_ChangeType.contains(objCase.Status)) {
						objCase.Type = objEventInfo.termination_type;
						blnUpdateCase = true;
					}

					if (set_ChangeStatus.contains(objCase.Status)) {
						objCase.Status = CaseUtils.STATUS_CANCELLED;
						blnUpdateCase = true;
					}

					if (objEventInfo?.termination_type?.equalsIgnoreCase(HIGroupEventUtil.TYPE_PARTIAL_COVERAGE_TERMINATION)) {
						objCase.Type = HIGroupEventUtil.TYPE_PARTIAL_COVERAGE_TERMINATION;
						blnUpdateCase = true;
					}

					if (blnUpdateCase && blnCarrierMatch) {
						objCase.Description = Label.Group_Term_Rescind_Term_Description;
						if (objCase.Type == HIGroupEventUtil.TYPE_PARTIAL_COVERAGE_TERMINATION) {
							objCase.Description = String.format(
								Label.Group_Termination_Partial_Coverage_Termination_Case_Descriptions,
								new List<String>{ objAccount?.Name, objCarrier?.Name, strBenefitType }
							);
						}
						list_CasesToUpdate.add(objCase);
					}
				}
			}
		}

		return list_CasesToUpdate;
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Get Group Termination Cases by Event Ids
	 * @Parm        : Set of Event Id from the Payload
	 * @Return      : Map of Case by Event Id
	 **/
	static Map<String, List<Case>> getCasesbyEventIds(Set<String> set_EventIds) {
		Map<String, List<Case>> map_Cases = new Map<String, List<Case>>();
		for (Case objCase : [SELECT Id, Event_Id__c, Status, Type, Carrier__c FROM Case WHERE RecordTypeId = :CaseUtils.RECTYPE_GROUP_TERMINATION AND Event_Id__c IN :set_EventIds]) {
			if (map_Cases.containsKey(objCase.Event_Id__c)) {
				map_Cases.get(objCase.Event_Id__c).add(objCase);
			} else {
				map_Cases.put(objCase.Event_Id__c, new List<Case>{ objCase });
			}
		}
		return map_Cases;
	}
}