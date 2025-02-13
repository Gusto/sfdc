public without sharing class HIFulfillmentDependentAgingOut {
	public void processInformation(List<HI_Fulfillment_Event__c> fulfillmentList) {
		Set<String> hiFulfillmentIDSet = new Set<String>();
		List<HI_Fulfillment_Event__c> toUpsertFulfillmentList = new List<HI_Fulfillment_Event__c>();
		List<Case> caseList = new List<Case>();
		Set<String> accountIdZPSet = new Set<String>();
		Set<String> set_EmployeeSearchKey = new Set<String>();
		Map<String, String> mapAccountZPToId = new Map<String, String>();
		Map<String, String> mapContactEmailToId = new Map<String, String>();
		Map<String, HIFulfillmentDependentAgingOutJSON> evenIdInfoMap = new Map<String, HIFulfillmentDependentAgingOutJSON>();
		Map<String, CaseDataWrapper> caseWrapperMap = new Map<String, CaseDataWrapper>();
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
				HIFulfillmentDependentAgingOutJSON hiEventInfoParsed;
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
				HIFulfillmentDependentAgingOutJSON hiEventInfoParsed;
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

				if (hiEventInfoParsed.employee.email != null) {
					set_EmployeeSearchKey.add(hiEventInfoParsed.employee.email);
				}

				if (hiEventInfoParsed.employee.id != null) {
					set_EmployeeSearchKey.add(hiEventInfoParsed.employee.id + '');
				}

				evenIdInfoMap.put(hiFulfill.Id__c, hiEventInfoParsed);

				HIFulfillmentDependentAgingOutJSON.cls_work_address companyBenefitAddress = hiEventInfoParsed.company.benefits_address;

				caseDataWrapper caseWrapper;
				HIFulfillmentDependentAgingOutJSON.cls_home_address employeeHomeAddress = hiEventInfoParsed.employee.home_address;
				String caseDescription = 'Dependent aging out';
				caseDescription +=
					'\n\nEmployee Info' +
					'\n- Name: ' +
					HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name) +
					'\n- SSN: ' +
					HIFulfillmentEventHelperFunctions.getMaskedSSN('' + hiEventInfoParsed.employee.ssn) +
					'\n- DOB: ' +
					HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday) +
					'\n- Date of hire: ' +
					HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.hired_at) +
					'\n- Home Address: ' +
					HIFulfillmentEventHelperFunctions.getAddress(
						employeeHomeAddress.street_1,
						employeeHomeAddress.street_2,
						employeeHomeAddress.city,
						employeeHomeAddress.county_name,
						employeeHomeAddress.state,
						employeeHomeAddress.zip,
						employeeHomeAddress.country
					) +
					'\n- Panda URL: ' +
					hiEventInfoParsed.employee.panda_url +
					'\n- Hippo URL: ' +
					hiEventInfoParsed.employee.hippo_url;
				String piiInformation = 'Employee Info:';
				piiInformation +=
					'<br/>- Name: ' + HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name);
				piiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + hiEventInfoParsed.employee.ssn);
				piiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);

				caseDescription +=
					'\n\nDependent Info' +
					'\n- Name: ' +
					HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.dependent.first_name, hiEventInfoParsed.dependent.middle_initial, hiEventInfoParsed.dependent.last_name) +
					'\n- SSN: ' +
					HIFulfillmentEventHelperFunctions.getMaskedSSN('' + hiEventInfoParsed.dependent.ssn) +
					'\n- DOB: ' +
					HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.dependent.birthday);
				piiInformation +=
					'<br/><br/>Dependent Info' +
					'<br/>- Name: ' +
					HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.dependent.first_name, hiEventInfoParsed.dependent.middle_initial, hiEventInfoParsed.dependent.last_name) +
					'<br/>- SSN: ' +
					HIFulfillmentEventHelperFunctions.getMaskedSSN('' + hiEventInfoParsed.dependent.ssn) +
					'<br/>- DOB: ' +
					HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.dependent.birthday);

				Date terminationDate = system.today();
				if (hiEventInfoParsed.dependent.birthday != null) {
					String[] dateArray = hiEventInfoParsed.dependent.birthday.split('-');
					terminationDate = Date.newInstance(terminationDate.year(), Integer.ValueOf(dateArray[1]), Integer.ValueOf(dateArray[2]));
				}
				caseWrapper = new caseDataWrapper(
					hiFulfill.Id__c,
					hiFulfill.Event_Type__c,
					hiEventInfoParsed.company.id,
					hiEventInfoParsed.employee.email,
					caseDescription,
					terminationDate,
					hiEventInfoParsed,
					piiInformation
				);
				caseWrapperMap.put(hiFulfill.id__c, caseWrapper);
			}
		}

		Map<String, Contact> contactMap = new Map<String, Contact>();
		if (set_EmployeeSearchKey.size() > 0) {
			contactMap = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);

			processContactInformation(fulfillmentList, evenIdInfoMap, accountMap, contactMap);

			contactMap = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);
		}

		List<Case> caseListForUpsert = getCaseInformation(caseWrapperMap, fulfillmentList, evenIdInfoMap, accountMap, contactMap);
		Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();
		if (caseListForUpsert.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(caseListForUpsert, Case.Fields.Integration_Key__c, false);
			dmlCaseUpsertErrorsMap = Utils.processUpsertResult(saveResult, caseListForUpsert, 'Integration_Id__c', true, 'HIFulfillmentEventTermination-processInformation');
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

	//calling HIFulfillmentTerminationEvenJSON class for parsing data
	private HIFulfillmentDependentAgingOutJSON getJSONParsedData(String jsonString) {
		HIFulfillmentDependentAgingOutJSON parsedData = (HIFulfillmentDependentAgingOutJSON) JSON.deserialize(jsonString, HIFulfillmentDependentAgingOutJSON.class);
		return parsedData;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentDependentAgingOutJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Contact> contactListForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentDependentAgingOutJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
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
				HIFulfillmentDependentAgingOutJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
				if (dmlContactInsertErrorsMap.containsKey(hiEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlContactInsertErrorsMap.get(hiEventInfo.employee.email), hiFulfill);
					continue;
				}
			}
		}
	}

	private List<Case> getCaseInformation(
		map<String, caseDataWrapper> caseWrapperMap,
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentDependentAgingOutJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Case> caseInsertList = new List<Case>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentDependentAgingOutJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!accountMap.containsKey('' + hiEventInfo.company.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', hiFulfill);
				continue;
			}
			Account acc = accountMap.get('' + hiEventInfo.company.id);
			Contact c;
			if (contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.email)) {
				c = contactMap.get(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.email);
			} else if (contactMap.containsKey(hiEventInfo.employee.email)) {
				c = contactMap.get(hiEventInfo.employee.email);
			} else if (contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.Id)) {
				c = contactMap.get(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.Id);
			}

			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Case cse = new Case();
			cse.setOptions(dmo);
			cse.Integration_Id__c = hiFulfill.Id__c;
			cse.Integration_Key__c = hiFulfill.Id__c;
			cse.Description = caseWrapperMap.get(hiFulfill.Id__c).caseDescription;
			cse.AccountId = acc.id;
            
			if (c != null) {
				cse.ContactId = c.Id;
			}
			cse.Termination_Date__c = caseWrapperMap.get(hiFulfill.Id__c).terminationDate;
			cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination');

			caseInsertList.add(cse);
		}
		return caseInsertList;
	}

	public class caseDataWrapper {
		public String eventId { get; set; }
		public String eventType { get; set; }
		public Long zPCompanyId { get; set; }
		public String employeeEmail { get; set; }
		public String caseDescription { get; set; }
		public Date terminationDate { get; set; }
		public HIFulfillmentDependentAgingOutJSON hiEventInfo { get; set; }
		public String piiInformation { get; set; }

		public caseDataWrapper(
			String eeventId,
			String eventT,
			Long companyId,
			String eEmail,
			String caseDesc,
			Date eterminationDate,
			HIFulfillmentDependentAgingOutJSON hiEventInfoParsed,
			String piiInfo
		) {
			eventId = eeventId;
			eventType = eventT;
			zPCompanyId = companyId;
			employeeEmail = eEmail;
			caseDescription = caseDesc;
			terminationDate = eterminationDate;
			hiEventInfo = hiEventInfoParsed;
			piiInformation = piiInfo;
		}
	}
}