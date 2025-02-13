public without sharing class HIFulfillmentEOIFollowup {
	public void processInformation(List<HI_Fulfillment_Event__c> fulfillmentList) {
		Set<String> hiFulfillmentIDSet = new Set<String>();
		//List<HI_Fulfillment_Event__c> toUpsertFulfillmentList = new List<HI_Fulfillment_Event__c>();
		List<Case> caseList = new List<Case>();
		Set<String> carrierKeySet = new Set<String>();
		Set<String> accountIdZPSet = new Set<String>();
		Set<String> set_EmployeeSearchKey = new Set<String>();
		Map<String, String> mapCarrierKeyToId = new Map<String, String>();
		Map<String, String> mapAccountZPToId = new Map<String, String>();
		Map<String, String> mapContactEmailToId = new Map<String, String>();
		Map<String, HIFulfillmentEOIFollowupJSON> evenIdInfoMap = new Map<String, HIFulfillmentEOIFollowupJSON>();
		Map<String, CaseDataWrapper> caseWrapperMap = new Map<String, CaseDataWrapper>();
		Map<long, HIFulfillmentEOIFollowupJSON.cls_selection> selectionIdMap = new Map<long, HIFulfillmentEOIFollowupJSON.cls_selection>();
		Set<String> documentIdSet = new Set<String>();
		List<Contact> listContact = new List<Contact>();
		Set<String> setNewContactEmails = new Set<String>();
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');

		for (HI_Fulfillment_Event__c objHIFulfill : fulfillmentList) {
			if (objHIFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			objHIFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfill.Message__c = '';

			if (objHIFulfill.Id__c == null) {
				continue;
			}
			hiFulfillmentIDSet.add(objHIFulfill.Id__c);
		}
		map<String, Account> accountMap = new Map<String, Account>();

		//Loop on HI Fulfillment Event to fetch json related data
		if (hiFulfillmentIDSet.size() > 0) {
			for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
				HIFulfillmentEOIFollowupJSON hiEventInfoParsed;
				try {
					Blob decryptedBlob = EncodingUtil.base64Decode(hiFulfill.Event_Info_Encrypted__c);
					String deCryptedText = EncryptionUtils.getDecryptedText(encryptionKey, decryptedBlob);
					hiEventInfoParsed = getJSONParsedData(deCryptedText);
				} catch (Exception e) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', hiFulfill);
					continue;
				}
				accountIdZPSet.add(String.valueOf(hiEventInfoParsed.company.id));
			}
            
			accountMap = HIFulfillmentEventHelperFunctions.getAccounts(accountIdZPSet);

			for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
				if (!hiFulfillmentIDSet.contains(hiFulfill.Id__c)) {
					continue;
				}
				HIFulfillmentEOIFollowupJSON hiEventInfoParsed;
				try {
					Blob decryptedBlob = EncodingUtil.base64Decode(hiFulfill.Event_Info_Encrypted__c);
					String deCryptedText = EncryptionUtils.getDecryptedText(encryptionKey, decryptedBlob);
					hiEventInfoParsed = getJSONParsedData(deCryptedText);
				} catch (Exception e) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', hiFulfill);
					continue;
				}

				if (hiEventInfoParsed == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', hiFulfill);
					continue;
				}
				if (hiFulfill.Event_Type__c == null || hiFulfill.Event_Type__c == '') {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Fulfillment Event Type: field value is missing in the record.', hiFulfill);
					continue;
				}
				if (hiEventInfoParsed.company.id == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Company Id: field value is missing in the record.', hiFulfill);
					continue;
				}

				if (hiEventInfoParsed.State_carrier == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'State Carrier information does not exist.', hiFulfill);
					continue;
				}

				if (hiEventInfoParsed.employee.email != null) {
					set_EmployeeSearchKey.add(hiEventInfoParsed.employee.email);
				}

				if (hiEventInfoParsed.employee.id != null) {
					set_EmployeeSearchKey.add(hiEventInfoParsed.employee.id + '');
				}

				evenIdInfoMap.put(hiFulfill.Id__c, hiEventInfoParsed);
				documentIdSet.add('EOI-' + hiEventInfoParsed.eoi_details.document_id);
				caseDataWrapper caseWrapper;
				HIFulfillmentEOIFollowupJSON.cls_home_address employeeHomeAddress = hiEventInfoParsed.employee.home_address;

				carrierKeySet.add(hiEventInfoParsed.state_carrier.key);
				String caseDescription = 'Event Type: EOI Followup';
				String piiInformation = '';

				caseDescription +=
					'\nAn EOI for ' +
					HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name) +
					' of ' +
					hiEventInfoParsed.company.name +
					' has been submitted to ' +
					hiEventInfoParsed.state_carrier.name +
					'. Please confirm whether it has been approved or declined and process in Hippo.' +
					'\n\nEffective date: ' +
					HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.eoi_details.effective_date) +
					'\n\nLink to EOI: ' +
					hiEventInfoParsed.eoi_details.eoi_url +
					'\nLink to employee’s subscriptions: ' +
					hiEventInfoParsed.benefits_url +
					'\n\nFulfillment Type: EOI Followup ' +
					'\n\nCarrier ' +
					'\nCarrier: ' +
					hiEventInfoParsed.state_carrier.name +
					'\nCarrier State: ' +
					hiEventInfoParsed.state_carrier.state +
					'\n\n*****New Subscription*****' +
					'\n\n' +
					hiEventInfoParsed.policy.benefit_type +
					' [' +
					hiEventInfoParsed.policy.name +
					']' +
					'\n- Group ID: ' +
					hiEventInfoParsed.policy.group_number +
					'\nEmployee' +
					'\n- Name: ' +
					HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name) +
					'\n- EE Guaranteed issue ' +
					hiEventInfoParsed.eoi_details.guaranteed_issue +
					'\n- EE Benefit amount ' +
					hiEventInfoParsed.eoi_details.benefit_amount;

				piiInformation = 'Employee Info:';
				piiInformation +=
					'<br/>- Name: ' + HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name);
				piiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + hiEventInfoParsed.employee.ssn);
				piiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);
                
				caseWrapper = new caseDataWrapper(
					hiFulfill.Id__c,
					hiEventInfoParsed.state_carrier.key,
					hiFulfill.Event_Type__c,
					hiEventInfoParsed.company.id,
					'',
					'',
					caseDescription,
					null,
					hiEventInfoParsed,
					piiInformation
				);

				caseWrapperMap.put(hiFulfill.id__c, caseWrapper);
			}
		}

		map<String, Contact> contactMap = new Map<String, Contact>();
		HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);
		map<String, Carrier__c> carrierMap = HIFulfillmentEventHelperFunctions.getCarrierInfo(carrierKeySet);

		if (set_EmployeeSearchKey.size() > 0) {
			contactMap = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);

			processContactInformation(fulfillmentList, evenIdInfoMap, accountMap, contactMap);

			contactMap = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);
		}

		map<String, Case> existingCaseMap = new Map<String, Case>();
		if (documentIdSet.size() > 0) {
			existingCaseMap = getExistingOpenCaseMap(documentIdSet);
		}

		List<Case> caseListForUpsert = getCaseInformation(caseWrapperMap, fulfillmentList, evenIdInfoMap, accountMap, contactMap, carrierMap, existingCaseMap);
		Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();
		if (caseListForUpsert.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(caseListForUpsert, Case.Fields.Integration_Key__c, false);
			dmlCaseUpsertErrorsMap = Utils.processUpsertResult(saveResult, caseListForUpsert, 'Integration_Id__c', true, 'HIFulfillmentEventEoiFollowup-processInformation');
		}

		List<EmailMessage> msgList = getCaseEmailMessageInformation(caseWrapperMap, fulfillmentList, evenIdInfoMap, accountMap, contactMap, carrierMap, existingCaseMap);
		if (msgList.size() > 0) {
			insert msgList;
		}

		createAttachment(caseListForUpsert, caseWrapperMap);
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (dmlCaseUpsertErrorsMap.containsKey(hiFulfill.Id__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlCaseUpsertErrorsMap.get(hiFulfill.Id__c), hiFulfill);
				continue;
			} else {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Data successfully Processed', hiFulfill);
			}
		}
	}

	public static void createAttachment(List<Case> caseListForUpsert, map<String, CaseDataWrapper> caseWrapperMap) {
		List<Attachment> attachmentList = new List<Attachment>();
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (Case c : caseListForUpsert) {
			if (c.Id != null) {
				if (caseWrapperMap.containsKey(c.Integration_Key__c)) {
					CaseDataWrapper wrapper = caseWrapperMap.get(c.Integration_Key__c);
					if (wrapper.piiInformation != null && wrapper.piiInformation != '') {
						Attachment atch = new Attachment();
						atch.ParentId = c.Id;
						atch.Body = EncryptionUtils.getEncryptedBlob(encryptionKey, wrapper.piiInformation);
						atch.Name = 'encFile.txt';
						attachmentList.add(atch);
					}
				}
			}
		}
		if (attachmentList.size() > 0) {
			insert attachmentList;
		}
	}
	//calling HIFulfillmentEOIFollowupJSON class for parsing data
	private HIFulfillmentEOIFollowupJSON getJSONParsedData(String jsonString) {
		HIFulfillmentEOIFollowupJSON parsedData = (HIFulfillmentEOIFollowupJSON) JSON.deserialize(jsonString, HIFulfillmentEOIFollowupJSON.class);
		return parsedData;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentEOIFollowupJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Contact> contactListForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEOIFollowupJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!accountMap.containsKey('' + hiEventInfo.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', hiFulfill);
				continue;
			}

			if (
				!contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.email) &&
				!contactMap.containsKey(hiEventInfo.employee.email) &&
				!contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.id)
			) {
				Contact c = new Contact();
				c.AccountId = accountMap.get('' + hiEventInfo.employee.company_id).Id;
				c.FirstName = hiEventInfo.employee.first_Name;
				c.LastName = hiEventInfo.employee.last_name;
				c.Email = hiEventInfo.employee.email;
				c.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
				contactListForInsert.add(c);
			}
		}
        
		if (contactListForInsert.size() > 0) {
			Map<String, String> dmlContactInsertErrorsMap = new Map<String, String>();
			List<Database.SaveResult> saveResult = database.insert(contactListForInsert, false);
			dmlContactInsertErrorsMap = Utils.processSaveResult(saveResult, contactListForInsert, 'email', true, 'HIFulfillmentEventTermination-processContactInformation');
			for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
				HIFulfillmentEOIFollowupJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
				if (dmlContactInsertErrorsMap.containsKey(hiEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlContactInsertErrorsMap.get(hiEventInfo.employee.email), hiFulfill);
					continue;
				}
			}
		}
	}

	private map<String, Case> getExistingOpenCaseMap(Set<String> documentIdSet) {
		map<String, Case> existingCaseMap = new Map<String, Case>();
		for (Case c : [SELECT Id, Enrollment_Id__c FROM Case WHERE isClosed = FALSE AND Enrollment_Id__c IN :documentIdSet]) {
			existingCaseMap.put(c.Enrollment_Id__c, c);
		}
		return existingCaseMap;
	}

	private List<Case> getCaseInformation(
		map<String, caseDataWrapper> caseWrapperMap,
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentEOIFollowupJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap,
		map<String, Carrier__c> carrierMap,
		map<String, Case> existingCaseMap
	) {
		List<Case> caseInsertList = new List<Case>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentEOIFollowupJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!accountMap.containsKey('' + hiEventInfo.company.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', hiFulfill);
				continue;
			}
			if (existingCaseMap.containsKey('EOI-' + hiEventInfo.eoi_details.document_id)) {
				continue;
			}

			Account acc = accountMap.get('' + hiEventInfo.company.id);
			Contact c;
			if (hiFulfill.Event_Type__c != 'company_update') {
				if (contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.email)) {
					c = contactMap.get(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.email);
				} else if (contactMap.containsKey(hiEventInfo.employee.email)) {
					c = contactMap.get(hiEventInfo.employee.email);
				} else if (contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.id)) {
					c = contactMap.get(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.id);
				}
			}

			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			String eventType = hiFulfill.Event_Type__c;

			Case cse = new Case();
			cse.setOptions(dmo);
			cse.Integration_Id__c = hiFulfill.Id__c;
			cse.Integration_Key__c = hiFulfill.Id__c;
			cse.Description = caseWrapperMap.get(hiFulfill.Id__c).caseDescription;
			cse.AccountId = acc.id;

			if (c != null) {
				cse.ContactId = c.Id;
			}
			if (carrierMap.containsKey(caseWrapperMap.get(hiFulfill.Id__c).stateCarrierKey)) {
				cse.Carrier__c = carrierMap.get(caseWrapperMap.get(hiFulfill.Id__c).stateCarrierKey).id;
			}
			cse.Anticipated_Effective_Date__c = caseWrapperMap.get(hiFulfill.Id__c).effectivedate;

			if (hiFulfill.Ops_Owner__c == 'member_fulfillment') {
				cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');
				cse.Type = 'NHE';
			} else if (hiFulfill.Ops_Owner__c == 'bor') {
				cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
				cse.Type = 'NHE';
			} else if (hiFulfill.Ops_Owner__c == 'new_plan') {
				cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits New Plan Case');
			} else if (hiFulfill.Ops_Owner__c == 'renewal') {
				cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Renewal Case');
			}

			cse.Fulfillment_Type__c = 'EOI Followup';

			caseInsertList.add(cse);
		}
		return caseInsertList;
	}

	private List<EmailMessage> getCaseEmailMessageInformation(
		map<String, caseDataWrapper> caseWrapperMap,
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentEOIFollowupJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap,
		map<String, Carrier__c> carrierMap,
		map<String, Case> existingCaseMap
	) {
		List<EmailMessage> emailMessageList = new List<EmailMessage>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentEOIFollowupJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!accountMap.containsKey('' + hiEventInfo.company.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', hiFulfill);
				continue;
			}
			if (!existingCaseMap.containsKey('EOI-' + hiEventInfo.eoi_details.document_id)) {
				continue;
			}

			EmailMessage msg = new EmailMessage();
			msg.ParentId = existingCaseMap.get('EOI-' + hiEventInfo.eoi_details.document_id).id;
			msg.Subject = 'New EOI submission message for case';
			msg.TextBody = caseWrapperMap.get(hiFulfill.Id__c).caseDescription;

			emailMessageList.add(msg);
		}
		return emailMessageList;
	}

	public class caseDataWrapper {
		public String eventId { get; set; }
		public String stateCarrierKey { get; set; }
		public String eventType { get; set; }
		public Long zPCompanyId { get; set; }
		public String employeeEmail { get; set; }
		public String caseSubject { get; set; }
		public String caseDescription { get; set; }
		public Date effectiveDate { get; set; }
		public HIFulfillmentEOIFollowupJSON hiEventInfo { get; set; }
		public String piiInformation { get; set; }

		public caseDataWrapper(
			String eeventId,
			String carrierKey,
			String eventT,
			Long companyId,
			String eEmail,
			String caseSubj,
			String caseDesc,
			Date eeffectiveDate,
			HIFulfillmentEOIFollowupJSON hiEventInfoParsed,
			String piiInfo
		) {
			eventId = eeventId;
			stateCarrierKey = carrierKey;
			eventType = eventT;
			zPCompanyId = companyId;
			employeeEmail = eEmail;
			caseSubject = caseSubj;
			caseDescription = caseDesc;
			effectiveDate = eeffectiveDate;
			hiEventInfo = hiEventInfoParsed;
			piiInformation = piiInfo;
		}
	}
}