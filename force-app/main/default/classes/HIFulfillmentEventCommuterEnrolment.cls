public class HIFulfillmentEventCommuterEnrolment {
	public void processInformation(List<HI_Fulfillment_Event__c> fulfillmentList) {
		Set<String> hiFulfillmentIDSet = new Set<String>();
		List<HI_Fulfillment_Event__c> toUpsertFulfillmentList = new List<HI_Fulfillment_Event__c>();
		List<Case> caseList = new List<Case>();
		Set<String> accountIdZPSet = new Set<String>();
		Set<String> employeeEmailSet = new Set<String>();
		Map<String, String> mapAccountZPToId = new Map<String, String>();
		Map<String, String> mapContactEmailToId = new Map<String, String>();
		Map<String, set<String>> enrollmentEnrollmentKeyMap = new Map<String, set<String>>();
		Map<String, HIFulfillmentEventCommuterEnrolmentJSON> evenIdInfoMap = new Map<String, HIFulfillmentEventCommuterEnrolmentJSON>();
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

		//Loop on HI Fulfillment Event to fetch json related data
		if (hiFulfillmentIDSet.size() > 0) {
			for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
				if (!hiFulfillmentIDSet.contains(hiFulfill.Id__c)) {
					continue;
				}
				HIFulfillmentEventCommuterEnrolmentJSON hiEventInfoParsed;
				try {
					Blob decryptedBlob = EncodingUtil.base64Decode(hiFulfill.Event_Info_Encrypted__c);
					String deCryptedText = EncryptionUtils.getDecryptedText(encryptionKey, decryptedBlob);
					hiEventInfoParsed = getJSONParsedData(deCryptedText);
				} catch (Exception e) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', hiFulfill);
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

				if (hiEventInfoParsed.employee.email == null || hiEventInfoParsed.employee.email == '') {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Employee email is missing in the record.', hiFulfill);
					continue;
				}

				accountIdZPSet.add(String.valueOf(hiEventInfoParsed.company.id));
				employeeEmailSet.add(hiEventInfoParsed.employee.email);

				evenIdInfoMap.put(hiFulfill.Id__c, hiEventInfoParsed);

				HIFulfillmentEventCommuterEnrolmentJSON.Home_Address employeeHomeAddress = hiEventInfoParsed.employee.home_address;
				HIFulfillmentEventCommuterEnrolmentJSON.Work_Address companyBenefitAddress = hiEventInfoParsed.company.benefits_address;
				Date effDate;
                
				if (hiEventInfoParsed.commuter_employee_benefit.start_date != null && hiEventInfoParsed.commuter_employee_benefit.start_date != '') {
					effDate = Date.valueOf(hiEventInfoParsed.commuter_employee_benefit.start_date);
				}

				String caseDescription = '';
				String piiInformation = '';

				caseDescription += '\nEvent Type: Commuter Enrollment';
				caseDescription += '\nEvent Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.commuter_employee_benefit.start_date);

				String employeeName = HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_Name, hiEventInfoParsed.employee.last_Name, hiEventInfoParsed.employee.middle_initial);
				caseDescription += '\n\n' + employeeName + ' of ' + hiEventInfoParsed.company.name + ' would like to enroll in the following Alegeus plans:';
				caseDescription += '\nEffective Date : ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.commuter_employee_benefit.start_date);
				caseDescription += '\nLink to employee\'s subscriptions: ' + hiEventInfoParsed.employee.hippo_url + '/subscriptions';
				caseDescription += '\nLink to employee\'s enrollments: ' + hiEventInfoParsed.employee.hippo_url + '/enrollments';
				caseDescription += '\nEE Panda Link: ' + hiEventInfoParsed.employee.panda_url;
				caseDescription += '\n\nCarrier';
				caseDescription += '\n- Carrier: Alegeus';

				caseDescription += '\nWaiting Period: ' + hiEventInfoParsed.commuter_benefit.waiting_period;
				caseDescription += '\nTransit Monthly Election: ' + hiEventInfoParsed.commuter_employee_benefit.transit_monthly_election;
				caseDescription += '\nTransit Monthly Contribution: ' + hiEventInfoParsed.commuter_employee_benefit.transit_monthly_contribution;
				caseDescription += '\nTransit Monthly Deduction: ' + hiEventInfoParsed.commuter_employee_benefit.transit_monthly_deduction;
				caseDescription += '\nParking Monthly Election: ' + hiEventInfoParsed.commuter_employee_benefit.parking_monthly_election;
				caseDescription += '\nParking Monthly Contribution: ' + hiEventInfoParsed.commuter_employee_benefit.parking_monthly_contribution;
				caseDescription += '\nParking Monthly Deduction: ' + hiEventInfoParsed.commuter_employee_benefit.parking_monthly_deduction;

				piiInformation = 'Employee Info:';
				piiInformation +=
					'<br/>- Name: ' + HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name);
				piiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + hiEventInfoParsed.employee.ssn);
				piiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);

				caseDataWrapper caseWrapper = new caseDataWrapper(
					hiFulfill.Id__c,
					'alegeus',
					hiFulfill.Event_Type__c,
					hiEventInfoParsed.company.id,
					hiEventInfoParsed.employee.email,
					caseDescription,
					effDate,
					hiEventInfoParsed,
					piiInformation
				);

				caseWrapperMap.put(hiFulfill.id__c + '-' + 'alegeus', caseWrapper);
			}
		}

		map<String, Account> accountMap = HIFulfillmentEventHelperFunctions.getAccounts(accountIdZPSet);
		map<String, Contact> contactMap = HIFulfillmentEventHelperFunctions.getContacts(employeeEmailSet);

		processContactInformation(fulfillmentList, evenIdInfoMap, accountMap, contactMap);

		contactMap = HIFulfillmentEventHelperFunctions.getContacts(employeeEmailSet);

		List<Case> caseListForUpsert = getCaseInformation(caseWrapperMap, fulfillmentList, evenIdInfoMap, accountMap, contactMap);
		Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();
		if (caseListForUpsert.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(caseListForUpsert, Case.Fields.Enrollment_Key__c, false);
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
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, hiFulfill.Message__c + ' Data successfully Processed', hiFulfill);
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

	//calling HIFulfillmentEnrollmentEventJSON class for parsing data
	public static HIFulfillmentEventCommuterEnrolmentJSON getJSONParsedData(String jsonString) {
		HIFulfillmentEventCommuterEnrolmentJSON parsedData = (HIFulfillmentEventCommuterEnrolmentJSON) JSON.deserialize(jsonString, HIFulfillmentEventCommuterEnrolmentJSON.class);
		return parsedData;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentEventCommuterEnrolmentJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Contact> contactListForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEventCommuterEnrolmentJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!accountMap.containsKey('' + hiEventInfo.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', hiFulfill);
				continue;
			}

			if (!contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.email) && !contactMap.containsKey(hiEventInfo.employee.email)) {
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
				HIFulfillmentEventCommuterEnrolmentJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
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
		map<string, HIFulfillmentEventCommuterEnrolmentJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		map<String, String> caseInfoMap = new Map<String, String>();
		Set<String> enrollmentKeyset = new Set<String>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (evenIdInfoMap.containsKey(hiFulfill.Id__c)) {
				continue;
			}
			HIFulfillmentEventCommuterEnrolmentJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (hiEventInfo == null) {
				continue;
			}
			enrollmentKeyset.add('commuter-' + hiEventInfo.commuter_employee_benefit.id + '-' + 'alegeus');
		}

		for (Case c : [SELECT Id, Status, Enrollment_key__c FROM case WHERE Enrollment_Key__c IN :enrollmentKeyset]) {
			caseInfoMap.put(c.Enrollment_Key__c, c.Status);
		}

		List<Case> caseInsertList = new List<Case>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			system.debug('hiFulfill.Processing_State__chiFulfill.Processing_State__c :: ' + hiFulfill.Processing_State__c);
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEventCommuterEnrolmentJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);

			Account acc = accountMap.get('' + hiEventInfo.company.id);
			Contact c;
			if (contactMap.containsKey(hiFulfill.Id__c + '-' + hiEventInfo.employee.email)) {
				c = contactMap.get(hiFulfill.Id__c + '-' + hiEventInfo.employee.email);
			} else if (contactMap.containsKey(hiEventInfo.employee.email)) {
				c = contactMap.get(hiEventInfo.employee.email);
			}
            
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;

			if (!caseWrapperMap.containsKey(hiFulfill.Id__c + '-' + 'alegeus')) {
				continue;
			}
			Case cse = new Case();
			cse.setOptions(dmo);
			cse.Integration_Id__c = hiFulfill.Id__c;
			cse.Integration_Key__c = hiFulfill.Id__c + '-' + 'alegeus';
			cse.Enrollment_Key__c = 'commuter-' + hiEventInfo.commuter_employee_benefit.id + '-' + 'alegeus';
			cse.Enrollment_Id__c = 'commuter-' + hiEventInfo.commuter_employee_benefit.id;
			cse.Description = caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').caseDescription;
			cse.AccountId = acc.id;
			cse.Fulfillment_Type__c = 'Commuter Benefit Enrollment';
			if (c != null) {
				cse.ContactId = c.Id;
			}
			cse.Anticipated_Effective_Date__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').effectiveDate;
			cse.Carrier__c = Label.alegeus;

			cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');

			if (caseInfoMap.containsKey('commuter-' + hiEventInfo.commuter_employee_benefit.id + '-' + 'alegeus')) {
				String status = caseInfoMap.get('commuter-' + hiEventInfo.commuter_employee_benefit.id + '-' + 'alegeus');
				if (status == 'Cancelled') {
					cse.Status = 'New';
				}
			}
			caseInsertList.add(cse);
		}
		return caseInsertList;
	}

	public class caseDataWrapper {
		public String eventId { get; set; }
		public String stateCarrierKey { get; set; }
		public String eventType { get; set; }
		public Long zPCompanyId { get; set; }
		public String employeeEmail { get; set; }
		public String caseDescription { get; set; }
		public Date effectiveDate { get; set; }
		public HIFulfillmentEventCommuterEnrolmentJSON hiEventInfo { get; set; }
		public String piiInformation { get; set; }

		public caseDataWrapper(
			String eeventId,
			String carrierKey,
			String eventT,
			Long companyId,
			String eEmail,
			String caseDesc,
			Date eeffectiveDate,
			HIFulfillmentEventCommuterEnrolmentJSON hiEventInfoParsed,
			String piiInfo
		) {
			eventId = eeventId;
			stateCarrierKey = carrierKey;
			eventType = eventT;
			zPCompanyId = companyId;
			employeeEmail = eEmail;
			caseDescription = caseDesc;
			effectiveDate = eeffectiveDate;
			hiEventInfo = hiEventInfoParsed;
			piiInformation = piiInfo;
		}
	}
}