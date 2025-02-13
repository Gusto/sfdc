public without sharing class HIAasmEventTriggerHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	public static boolean queue = false;

	public HIAasmEventTriggerHelper() {
		super('HIAasmEventTriggerHelper');
	}

	public override void beforeInsert() {
		List<HI_Aasm_Event__c> events = (List<HI_Aasm_Event__c>) Trigger.new;
		if (queue == true) {
			processInformation(events);
		} else {
			for (HI_Aasm_Event__c event : events) {
				event.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_Aasm_Event__c> events = (List<HI_Aasm_Event__c>) Trigger.new;
		if (queue == false) {
			HIAasmEventQueue updateJob = new HIAasmEventQueue(events);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public override void beforeUpdate() {
		List<HI_Aasm_Event__c> events = (List<HI_Aasm_Event__c>) Trigger.new;
		if (queue == true) {
			processInformation(events);
		} else {
			for (HI_Aasm_Event__c event : events) {
				event.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_Aasm_Event__c> events = (List<HI_Aasm_Event__c>) Trigger.new;
		if (queue == false) {
			HIAasmEventQueue updateJob = new HIAasmEventQueue(events);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public void processInformation(List<HI_Aasm_Event__c> eventsList) {
		Set<String> sourceIdSet = new Set<String>();
		map<String, String> eventIdSourceIdMap = new Map<String, String>();
		Set<String> newPlanIdSet = new Set<String>();
		Set<String> benefitChangeIdSet = new Set<String>();
		Set<String> renewalIdSet = new Set<String>();
		Set<String> borIdSet = new Set<String>();
		Map<String, String> map_AWEvents = new Map<String, String>();

		for (HI_Aasm_Event__c event : eventsList) {
			if (event.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			event.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			String prefix = '';
			if (event.Recordable_Type__c == 'NewPlansApplication') {
				prefix = 'hawaiian_ice-new_plans_application-';
				newPlanIdSet.add(event.Recordable_Id__c);
			} else if (event.Recordable_Type__c == 'BenefitChangeApplication') {
				prefix = 'hawaiian_ice-benefit_change_application-';
				benefitChangeIdSet.add(event.Recordable_Id__c);
			} else if (event.Recordable_Type__c == 'BorTransfer') {
				prefix = 'hawaiian_ice-bor_transfer-';
				borIdSet.add(event.Recordable_Id__c);
			} else if (event.Recordable_Type__c == 'Renewal') {
				prefix = 'hawaiian_ice-renewal-';
				renewalIdSet.add(event.Recordable_Id__c);
			} else {
				event.Processing_State__c = IntegrationUtils.DEAD_STATE;
				continue;
			}
			String sourceId = prefix + event.Recordable_Id__c;
			sourceIdSet.add(sourceId);
			eventIdSourceIdMap.put(event.Id__c, sourceId);

			if (
				(event.To__c != null && event.To__c.equalsIgnoreCase('awaiting_offerings')) &&
				(event.Paper_Trail_Whodunnit__c != null && event.Paper_Trail_Whodunnit__c?.equalsIgnoreCase('0')) &&
				(event.Recordable_Type__c != null && event.Recordable_Type__c?.equalsIgnoreCase('Renewal'))
			) {
				map_AWEvents.put(event.Recordable_Id__c, sourceId);
			}
		}

		map<string, Opportunity> oppMap = getOpportunityDetail(sourceIdSet);
		map<String, List<HI_Aasm_Event__c>> newPlanEventMap = new Map<String, List<HI_Aasm_Event__c>>();
		map<String, List<HI_Aasm_Event__c>> benefitChangeEventMap = new Map<String, List<HI_Aasm_Event__c>>();
		map<String, List<HI_Aasm_Event__c>> renewalEventMap = new Map<String, List<HI_Aasm_Event__c>>();
		map<String, List<HI_Aasm_Event__c>> borEventMap = new Map<String, List<HI_Aasm_Event__c>>();

		if (newPlanIdSet.size() > 0) {
			newPlanEventMap = HINewPlansApplicationTriggerHelper.getEventData(newPlanIdSet);
		}
		if (benefitChangeIdSet.size() > 0) {
			benefitChangeEventMap = HIBenefitChangeApplicationTriggerHelper.getEventData(benefitChangeIdSet);
		}
		if (renewalIdSet.size() > 0) {
			renewalEventMap = HIRenewalTriggerHelper.getEventData(renewalIdSet);
		}
		if (borIdSet.size() > 0) {
			borEventMap = HIBorTransferTriggerHelper.getEventData(borIdSet);
		}

		if (map_AWEvents.size() > 0) {
			Map<String, Integer> map_RecordIdCount = new Map<String, Integer>();
			for (AggregateResult objAggrResult : [
				SELECT Recordable_Id__c recId, COUNT(Id) recCnt
				FROM HI_Aasm_Event__c
				WHERE Recordable_Id__c IN :map_AWEvents.keySet() AND From__c = 'awaiting_offerings'
				GROUP BY Recordable_Id__c
			]) {
				map_RecordIdCount.put((String) objAggrResult.get('recId'), (Integer) objAggrResult.get('recCnt'));
			}

			for (String objEventId : map_AWEvents.keySet()) {
				if (!map_RecordIdCount.containsKey(objEventId)) {
					map_AWEvents.remove(objEventId);
				}
			}
		}

		Set<String> awAlertOppSourceIds = new Set<String>(map_AWEvents.values());
		Map<String, Opportunity> sourceIdOppMap = new Map<String, Opportunity>();
		for (HI_Aasm_Event__c event : eventsList) {
			if (event.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			Opportunity opp = new Opportunity();
			String prefix = '';
			String sourceId = '';
			if (event.Recordable_Type__c == 'NewPlansApplication') {
				prefix = 'hawaiian_ice-new_plans_application-';
				sourceId = prefix + event.Recordable_Id__c;
				if (oppMap.containsKey(sourceId)) {
					opp = oppMap.get(sourceId);
					opp = HINewPlansApplicationTriggerHelper.mapEventData(opp, event.Recordable_Id__c, newPlanEventMap);
				}
			} else if (event.Recordable_Type__c == 'BenefitChangeApplication') {
				prefix = 'hawaiian_ice-benefit_change_application-';
				sourceId = prefix + event.Recordable_Id__c;
				if (oppMap.containsKey(sourceId)) {
					opp = oppMap.get(sourceId);
					opp = HIBenefitChangeApplicationTriggerHelper.mapEventData(opp, event.Recordable_Id__c, benefitChangeEventMap);
				}
			} else if (event.Recordable_Type__c == 'BorTransfer') {
				prefix = 'hawaiian_ice-bor_transfer-';
				sourceId = prefix + event.Recordable_Id__c;
				if (oppMap.containsKey(sourceId)) {
					opp = oppMap.get(sourceId);
					opp = HIBorTransferTriggerHelper.mapEventData(opp, event.Recordable_Id__c, borEventMap);
				}
			} else if (event.Recordable_Type__c == 'Renewal') {
				prefix = 'hawaiian_ice-renewal-';
				sourceId = prefix + event.Recordable_Id__c;
				if (oppMap.containsKey(sourceId)) {
					opp = oppMap.get(sourceId);
					opp = HIRenewalTriggerHelper.mapEventData(opp, event.Recordable_Id__c, renewalEventMap);
				}
			}

			if (!oppMap.containsKey(sourceId)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Opportunity does not exist', event);
				continue;
			}
			if (sourceIdOppMap.containsKey(sourceId)) {
				continue;
			} else {
				sourceIdOppMap.put(sourceId, opp);
			}

			if (awAlertOppSourceIds.contains(sourceId)) {
				if (opp.RecordType.Name == 'Benefits Renewal' && opp.Benefits_Designer__c != null) {
					postToChatter(opp);
				}
			}
		}

		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
		if (sourceIdOppMap.size() > 0) {
			List<Database.SaveResult> saveResult = database.update(sourceIdOppMap.values(), false);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, sourceIdOppMap.values(), 'Source_ID__c', true, 'HIAasmEventTriggerHelper-processInformation');
		}

		for (HI_Aasm_Event__c event : eventsList) {
			String sourceid = eventIdSourceIdMap.get(event.Id__c);
			if (dmlUpdateErrorsMap.containsKey(sourceid)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpdateErrorsMap.get(sourceid), event);
				continue;
			}
			if (event.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Processed', event);
				continue;
			}
		}
	}

	/**
	 * ModBy       Date          Desc
	 * Prashant    23-july-2020   To add required fields for HINewPlansApplicationTriggerHelper.mapEventData(opp, event.Recordable_Id__c, newPlanEventMap) method
	 */
	private map<string, Opportunity> getOpportunityDetail(set<String> sourceIdSet) {
		map<string, Opportunity> toReturnOppMap = new Map<string, Opportunity>();

		for (Opportunity opp : [
			SELECT
				Id,
				Name,
				RecordType.Name,
				Source_Id__c,
				Users_Email__c,
				Selecting_Employee_Eligibility_Start__c,
				Selecting_Employee_Eligibility_End__c,
				Receiving_Medical_Education_Start__c,
				Receiving_Medical_Education_End__c,
				Selecting_Base_Tier_Start__c,
				Selecting_Base_Tier_End__c,
				Selecting_Base_Plan_Start__c,
				Selecting_Base_Plan_End__c,
				Selecting_Non_Medical_Plans_Start__c,
				Selecting_Non_Medical_Plans_End__c,
				Selecting_Complementary_Plans_Start__c,
				Selecting_Complementary_Plans_End__c,
				Collecting_Company_information_Start__c,
				Collecting_Company_information_End__c,
				Reviewing_Summary_Start__c,
				Reviewing_Summary_End__c,
				Verifying_Eligibility_Start__c,
				Verifying_Eligibility_End__c,
				Completed__c,
				Answering_Survey_Start__c,
				Answering_Survey_End__c,
				Awaiting_Offerings_Start__c,
				Awaiting_Offerings_End__c,
				Receiving_Education_Start__c,
				Receiving_Education_End__c,
				Selecting_Offerings_Start__c,
				Selecting_Offerings_End__c,
				Dismissed__c,
				Selecting_Carriers_Started_Timestamp__c,
				Additional_Info_Started_Timestamp__c,
				Signing_Forms_Started_Timestamp__c,
				Signing_Forms_Completed_Timestamp__c,
				Last_Blocked_Timestamp__c,
				Benefits_Setup_Last_Updated__c,
				Benefits_Designer__c
			FROM Opportunity
			WHERE Source_Id__c IN :sourceIdSet AND Source_Id__c != NULL
		]) {
			toReturnOppMap.put(opp.Source_Id__c, opp);
		}
		return toReturnOppMap;
	}

	// populating HI_Policy__c object fields
	private HI_Aasm_Event__c setProcessingState(String ProcessingState, String message, HI_Aasm_Event__c hiEvent) {
		hiEvent.Processing_State__c = ProcessingState;
		hiEvent.Message__c = message;
		hiEvent.Last_Processed__c = System.now();
		return hiEvent;
	}

	/**
	 * @name         postToChatter
	 * @description  Creates chatter post for the given Opportunity's Benefit Designer
	 * @input        Opportunity Record
	 */
	private static void postToChatter(Opportunity objOpp) {
		ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
		ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
		messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

		messageBodyInput.messageSegments.add(getTextInputFromString('[Action Required] '));
		messageBodyInput.messageSegments.add(getRefInputFromId(objOpp.Benefits_Designer__c));
		messageBodyInput.messageSegments.add(getTextInputFromString(' Opportunity - '));
		messageBodyInput.messageSegments.add(getRefInputFromId(objOpp.Id));
		messageBodyInput.messageSegments.add(getTextInputFromString(' has been set back to \'awaiting offerings\' please update HIPPO.'));

		feedItemInput.body = messageBodyInput;
		feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
		feedItemInput.subjectId = objOpp.Id;

		ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
	}

	/**
	 * @name         getTextInputFromString
	 * @description  Formates string and returns TextSegmentInput
	 * @input        String
	 * @returns      ConnectApi.TextSegmentInput
	 */
	private static ConnectApi.TextSegmentInput getTextInputFromString(String strInput) {
		ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
		textSegmentInput.text = strInput;
		return textSegmentInput;
	}

	/**
	 * @name         getTextInputFromString
	 * @description  Accepts Id and returns embedded EntityLinkSegmentInput
	 * @input        Object Id
	 * @returns      ConnectApi.EntityLinkSegmentInput
	 */
	private static ConnectApi.EntityLinkSegmentInput getRefInputFromId(Id idRecId) {
		ConnectApi.EntityLinkSegmentInput entityLinkInput = new ConnectApi.EntityLinkSegmentInput();
		entityLinkInput.entityId = idRecId;
		return entityLinkInput;
	}
}