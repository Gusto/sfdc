public class HIFulfillmentEventEnrllmentUnlock {
	public void processInformation(List<HI_Fulfillment_Event__c> fulfillmentList) {
		Set<String> hiFulfillmentIDSet = new Set<String>();
		Map<String, HIFulfillmentEnrollmentEventJSON> enrollmentJsonMap = new Map<String, HIFulfillmentEnrollmentEventJSON>();
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
        
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			hiFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			hiFulfill.Message__c = '';

			HIFulfillmentEnrollmentEventJSON hiEventInfoParsed;
			try {
				Blob decryptedBlob = EncodingUtil.base64Decode(hiFulfill.Event_Info_Encrypted__c);
				String deCryptedText = EncryptionUtils.getDecryptedText(encryptionKey, decryptedBlob);
				hiEventInfoParsed = HIFulfillmentEventEnrollment.getJSONParsedData(deCryptedText);
			} catch (Exception e) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', hiFulfill);
			}

			enrollmentJsonMap.put(hiFulfill.Id__c, hiEventInfoParsed);

			if (hiEventInfoParsed.enrollment.id == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Enrollment Id does not exist', hiFulfill);
				continue;
			} else {
				hiFulfillmentIDSet.add('' + hiEventInfoParsed.enrollment.id);
			}
		}

		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
		if (hiFulfillmentIDSet.size() > 0) {
			List<Case> matchingCaseList = getMatchingCases(hiFulfillmentIDSet);
			if (matchingCaseList.size() > 0) {
				List<Database.SaveResult> saveResult = database.update(matchingCaseList, false);
				dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, matchingCaseList, 'Enrollment_Id__c', true, 'HIFulfillmentEventEnrllmentUnlock-processInformation');
			}
		}

		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEnrollmentEventJSON hiEventInfoParsed = enrollmentJsonMap.get(hiFulfill.Id__c);
			if (dmlUpdateErrorsMap.containsKey('' + hiEventInfoParsed.enrollment.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpdateErrorsMap.get('' + hiEventInfoParsed.enrollment.id), hiFulfill);
				continue;
			}
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Processed', hiFulfill);
		}
	}

	private List<Case> getMatchingCases(Set<String> hiFulfillmentIDSet) {
		List<Case> caseList = new List<Case>(
			[
				SELECT Id, Enrollment_Id__c, Status
				FROM Case
				WHERE
					Enrollment_Id__c IN :hiFulfillmentIDSet
					AND Status != 'Closed'
					AND (RecordTypeId = :Cache.getRecordTypeId('Case', 'MF NHE')
					OR RecordTypeId = :Cache.getRecordTypeId('Case', 'MF QLE'))
			]
		);
		for (Case cse : caseList) {
			cse.status = 'Cancelled';
			cse.requires_action__c = true;
		}
		return caseList;
	}
}