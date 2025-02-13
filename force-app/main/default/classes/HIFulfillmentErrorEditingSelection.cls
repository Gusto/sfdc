public class HIFulfillmentErrorEditingSelection {
	static final String QUEUE_MEMBER_FULFILLMENT = 'Member_Fulfillment';

	public void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents) {
		Map<String, HIFulfillmentErrorEditingSelectionJSON> map_selectionId = new Map<String, HIFulfillmentErrorEditingSelectionJSON>();
		Map<String, HIFulfillmentErrorEditingSelectionJSON> map_parsedJSON = new Map<String, HIFulfillmentErrorEditingSelectionJSON>();
		Map<String, HIFulfillmentErrorEditingSelectionJSON> map_selectionUUId = new Map<String, HIFulfillmentErrorEditingSelectionJSON>();

		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');

		for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
			if (objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			objHIFulfillmentEvent.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfillmentEvent.Message__c = '';

			if (objHIFulfillmentEvent.Id__c == null) {
				continue;
			}

			Blob decryptedBlob = EncodingUtil.base64Decode(objHIFulfillmentEvent.Event_Info_Encrypted__c);
			String deCryptedText = EncryptionUtils.getDecryptedText(encryptionKey, decryptedBlob);
			HIFulfillmentErrorEditingSelectionJSON objParsedEventInfo = getJSONParsedData(deCryptedText);

			map_parsedJSON.put(objHIFulfillmentEvent.Id__c, objParsedEventInfo);
			map_selectionId.put('' + objParsedEventInfo.selection_id, objParsedEventInfo);

			if (String.isNotBlank(objParsedEventInfo.selection_uuid)) {
				map_selectionUUId.put(objParsedEventInfo.selection_uuid, objParsedEventInfo);
			}
		}

		if (map_selectionId.isEmpty() && map_selectionUUId.isEmpty()) {
			return;
		}

		Map<String, Set<String>> map_SelectionIdsPerCase = new Map<String, Set<String>>();
		List<Case> list_CasesToUpdate = new List<Case>();
		Map<String, String> map_selectionIdToCaseId = new Map<String, String>();
		Map<String, String> map_selectionUUIdToCaseId = new Map<String, String>();

		Set<Id> set_caseIds = new Set<Id>();
		List<Case_Fulfillment_Selection_Status__c> list_selectionStatuses = new List<Case_Fulfillment_Selection_Status__c>(
			[
				SELECT Id, Selection_UUID__c, Selection_id__c, Case__c, Case__r.Status
				FROM Case_Fulfillment_Selection_Status__c
				WHERE
					Selection_Id__c IN :map_selectionId.keySet()
					OR Selection_UUID__c IN :map_selectionUUId.keySet()
			]
		);

		List<Group> list_MemberFulfillmentQueue = GlobalQueryHelper.getGroupsByName(QUEUE_MEMBER_FULFILLMENT);

		for (Case_Fulfillment_Selection_Status__c objSelectionStatus : list_selectionStatuses) {
			Set<String> set_SelectionIds = new Set<String>();

			if (map_SelectionIdsPerCase.containsKey(objSelectionStatus.Case__c)) {
				set_SelectionIds = map_SelectionIdsPerCase.get(objSelectionStatus.Case__c);
			}
			set_SelectionIds.add(objSelectionStatus.Selection_id__c);
			map_SelectionIdsPerCase.put(objSelectionStatus.Case__c, set_SelectionIds);

			map_selectionIdToCaseId.put(objSelectionStatus.Selection_id__c, objSelectionStatus.Case__c);

			if (String.isNotBlank(objSelectionStatus.Selection_UUID__c)) {
				map_selectionUUIdToCaseId.put(objSelectionStatus.Selection_UUID__c, objSelectionStatus.Case__c);
			}

			if (!set_caseIds.contains(objSelectionStatus.Case__c)) {
				Case objCase = new Case(Id = objSelectionStatus.Case__c, Status = CaseUtils.STATUS_NEW);

				if (!list_MemberFulfillmentQueue.isEmpty()) {
					objCase.OwnerId = list_MemberFulfillmentQueue[0].Id;
				}

				list_CasesToUpdate.add(objCase);

				set_caseIds.add(objSelectionStatus.Case__c);
			}
		}

		Map<String, String> dmlCaseUpdateErrorsMap = new Map<String, String>();
		if (list_CasesToUpdate.size() > 0) {
			List<Database.SaveResult> saveResult = database.update(list_CasesToUpdate, false);
			dmlCaseUpdateErrorsMap = Utils.processSaveResult(
				saveResult,
				list_CasesToUpdate,
				'Id',
				true,
				'HIFulfillmentErrorEditingSelection-processInformation'
			);
		}

		List<EmailMessage> list_EmailMessages = new List<EmailMessage>();

		for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
			if (
				objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE ||
				objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE
			) {
				continue;
			}

			HIFulfillmentErrorEditingSelectionJSON objFulfillmentEventJSON = map_parsedJSON.get(
				objHIFulfillmentEvent.id__c
			);

			String strCaseId = '';

			if (map_selectionIdToCaseId.containsKey('' + objFulfillmentEventJSON.selection_id)) {
				strCaseId = map_selectionIdToCaseId.get('' + objFulfillmentEventJSON.selection_id);
			} else if (map_selectionUUIdToCaseId.containsKey('' + objFulfillmentEventJSON.selection_uuid)) {
				strCaseId = map_selectionUUIdToCaseId.get('' + objFulfillmentEventJSON.selection_uuid);
			}

			if (String.isNotBlank(strCaseId) && dmlCaseUpdateErrorsMap.containsKey(strCaseId)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(
					IntegrationUtils.ERROR_STATE,
					dmlCaseUpdateErrorsMap.get(strCaseId),
					objHIFulfillmentEvent
				);
				continue;
			} else {
				if (String.isNotBlank(strCaseId)) {
					EmailMessage objEmailMessage = new EmailMessage();
					objEmailMessage.ParentId = strCaseId;
					objEmailMessage.Incoming = true;
					objEmailMessage.TextBody =
						'Error occured in processing selection ' + objFulfillmentEventJSON.error_message;

					list_EmailMessages.add(objEmailMessage);
				}

				HIFulfillmentEventTriggerHelper.setProcessingState(
					IntegrationUtils.PROCESSED_STATE,
					'Data successfully Processed',
					objHIFulfillmentEvent
				);
			}
		}

		if (!list_EmailMessages.isEmpty()) {
			insert list_EmailMessages;
		}
	}

	private HIFulfillmentErrorEditingSelectionJSON getJSONParsedData(String jsonString) {
		HIFulfillmentErrorEditingSelectionJSON parsedData = (HIFulfillmentErrorEditingSelectionJSON) JSON.deserialize(
			jsonString,
			HIFulfillmentErrorEditingSelectionJSON.class
		);
		return parsedData;
	}
}