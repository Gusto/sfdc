public class HIFulfillmentEventHSAEnrolment {
	//Added for BBO-1966
	public void processInformation(List<HI_Fulfillment_Event__c> list_HIEvents) {
		Set<String> set_HIFulfillmentIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_EmployeeIds = new Set<String>();
		Map<String, HIFulfillmentEventHSAEnrolmentJSON> map_EventIdInfo = new Map<String, HIFulfillmentEventHSAEnrolmentJSON>();
		Map<String, CaseDataWrapper> map_CaseWrapper = new Map<String, CaseDataWrapper>();
		Set<String> set_CarrierKey = new Set<String>();
		Map<String, Carrier__c> map_Carrier = new Map<String, Carrier__c>();
		Blob objEncryptionKey = EncryptionUtils.getEncryptionKey('Master');

		for (HI_Fulfillment_Event__c objHIFulfill : list_HIEvents) {
			if (objHIFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			objHIFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfill.Message__c = '';

			if (objHIFulfill.Id__c == null) {
				continue;
			}
			set_HIFulfillmentIds.add(objHIFulfill.Id__c);
		}

		//Loop on HI Fulfillment Event to fetch json related data
		if (set_HIFulfillmentIds.size() > 0) {
			for (HI_Fulfillment_Event__c objHIFulfill : list_HIEvents) {
				if (!set_HIFulfillmentIds.contains(objHIFulfill.Id__c)) {
					continue;
				}
				HIFulfillmentEventHSAEnrolmentJSON objHIEventInfoParsed;
				try {
					Blob objDecryptedBlob = EncodingUtil.base64Decode(objHIFulfill.Event_Info_Encrypted__c);
					String strDeCryptedText = EncryptionUtils.getDecryptedText(objEncryptionKey, objDecryptedBlob);
					objHIEventInfoParsed = getJSONParsedData(strDeCryptedText);
				} catch (Exception objExp) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', objHIFulfill);
				}

				if (objHIEventInfoParsed == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', objHIFulfill);
					continue;
				}
				if (objHIFulfill.Event_Type__c == null || objHIFulfill.Event_Type__c == '') {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Fulfillment Event Type: field value is missing in the record.', objHIFulfill);
					continue;
				}
				if (objHIEventInfoParsed.company.id == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Company Id: field value is missing in the record.', objHIFulfill);
					continue;
				}

				if (objHIEventInfoParsed.employee.email == null || objHIEventInfoParsed.employee.email == '') {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Employee email is missing in the record.', objHIFulfill);
					continue;
				}

				set_CompanyIds.add(String.valueOf(objHIEventInfoParsed.company.id));
				set_EmployeeIds.add(objHIEventInfoParsed.employee.email);
				set_CarrierKey.add(objHIEventInfoParsed.hsa_benefit.provider_key);

				map_EventIdInfo.put(objHIFulfill.Id__c, objHIEventInfoParsed);

				HIFulfillmentEventHSAEnrolmentJSON.Address employeeHomeAddress = objHIEventInfoParsed.employee.home_address;
				HIFulfillmentEventHSAEnrolmentJSON.Address companyBenefitAddress = objHIEventInfoParsed.company.benefits_address;
				Date dtEffectiveDate;

				if (objHIEventInfoParsed.hsa_benefit.effective_date != null && objHIEventInfoParsed.hsa_benefit.effective_date != '') {
					dtEffectiveDate = Date.valueOf(objHIEventInfoParsed.hsa_benefit.effective_date);
				}

				String strCaseDescription = '';
				String strPiiInformation = '';
				String strCarrierName = map_Carrier.get(objHIEventInfoParsed.hsa_benefit.provider_key) != null ? map_Carrier.get(objHIEventInfoParsed.hsa_benefit.provider_key).Name : '';
				if (objHIFulfill.Event_Type__c == HIEnrollmentEventUtility.ETYPE_EMP_HSA_ENROLLMENT_AUTO_PROCESS) {
					strCaseDescription += '\nEvent Type: HSA Enrollment Auto Process Failure';
				} else {
					strCaseDescription += '\nEvent Type: HSA Enrollment';
				}

				strCaseDescription += '\nEvent Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.hsa_benefit.effective_date);

				String strEmployeeName = HIFulfillmentEventHelperFunctions.getName(
					objHIEventInfoParsed.employee.first_Name,
					objHIEventInfoParsed.employee.last_Name,
					objHIEventInfoParsed.employee.middle_initial
				);
				strCaseDescription += '\n\n' + strEmployeeName + ' of ' + objHIEventInfoParsed.company.name + ' would like to enroll in the following ' + strCarrierName + ' plans:';
				strCaseDescription += '\nEffective Date : ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.hsa_benefit.effective_date);
				strCaseDescription += '\nLink to employee\'s subscriptions: ' + objHIEventInfoParsed.employee.hippo_url + '/subscriptions';
				strCaseDescription += '\nLink to employee\'s enrollments: ' + objHIEventInfoParsed.employee.hippo_url + '/enrollments';
				strCaseDescription += '\nEE Panda Link: ' + objHIEventInfoParsed.employee.panda_url;
				strCaseDescription += '\n\nCarrier';
				strCaseDescription += '\n- Carrier: ' + strCarrierName;

				strCaseDescription += '\nPolicy Url: ' + objHIEventInfoParsed.hsa_benefit.url;
				strPiiInformation = 'Employee Info:';
				strPiiInformation +=
					'<br/>- Name: ' +
					HIFulfillmentEventHelperFunctions.getName(objHIEventInfoParsed.employee.first_name, objHIEventInfoParsed.employee.middle_initial, objHIEventInfoParsed.employee.last_name);
				strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHIEventInfoParsed.employee.ssn);
				strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday);

				caseDataWrapper objCaseWrapper = new caseDataWrapper(
					objHIFulfill.Id__c,
					objHIEventInfoParsed.hsa_benefit.provider_key,
					objHIFulfill.Event_Type__c,
					objHIEventInfoParsed.company.id,
					objHIEventInfoParsed.employee.email,
					strCaseDescription,
					dtEffectiveDate,
					objHIEventInfoParsed,
					strPiiInformation
				);

				map_CaseWrapper.put(objHIFulfill.Id__c + '-' + objHIEventInfoParsed.hsa_benefit.provider_key, objCaseWrapper);
			}
		}

		if (!set_CarrierKey.isEmpty()) {
			map_Carrier = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKey);
		}

		map<String, Account> map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_CompanyIds);
		map<String, Contact> map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeIds);

		processContactInformation(list_HIEvents, map_EventIdInfo, map_Accounts, map_Contacts);

		map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeIds);

		List<Case> list_CaseForUpsert = getCaseInformation(map_CaseWrapper, list_HIEvents, map_EventIdInfo, map_Accounts, map_Contacts, map_Carrier);
		Map<String, String> map_DMLCaseUpsertErrors = new Map<String, String>();
		if (list_CaseForUpsert.size() > 0) {
			List<Database.UpsertResult> list_SaveResults = database.upsert(list_CaseForUpsert, Case.Fields.Enrollment_Key__c, false);
			map_DMLCaseUpsertErrors = Utils.processUpsertResult(list_SaveResults, list_CaseForUpsert, 'Integration_Id__c', true, 'HIFulfillmentEventTermination-processInformation');
		}

		createAttachment(list_CaseForUpsert, map_CaseWrapper);
		for (HI_Fulfillment_Event__c objHIFulfill : list_HIEvents) {
			if (objHIFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (map_DMLCaseUpsertErrors.containsKey(objHIFulfill.Id__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLCaseUpsertErrors.get(objHIFulfill.Id__c), objHIFulfill);
				continue;
			} else {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, objHIFulfill.Message__c + ' Data successfully Processed', objHIFulfill);
			}
		}
	}

	public static void createAttachment(List<Case> list_CaseForUpsert, map<String, CaseDataWrapper> map_CaseWrapper) {
		List<Attachment> list_Attachments = new List<Attachment>();
		Blob objEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (Case objCase : list_CaseForUpsert) {
			if (objCase.Id != null) {
				if (map_CaseWrapper.containsKey(objCase.Integration_Key__c)) {
					CaseDataWrapper objWrapper = map_CaseWrapper.get(objCase.Integration_Key__c);
					if (objWrapper.strPiiInformation != null && objWrapper.strPiiInformation != '') {
						Attachment objAttachment = new Attachment();
						objAttachment.ParentId = objCase.Id;
						objAttachment.Body = EncryptionUtils.getEncryptedBlob(objEncryptionKey, objWrapper.strPiiInformation);
						objAttachment.Name = 'encFile.txt';
						list_Attachments.add(objAttachment);
					}
				}
			}
		}
		if (list_Attachments.size() > 0) {
			insert list_Attachments;
		}
	}

	//calling HIFulfillmentEnrollmentEventJSON class for parsing data
	public static HIFulfillmentEventHSAEnrolmentJSON getJSONParsedData(String strJSON) {
		HIFulfillmentEventHSAEnrolmentJSON objParsedData = (HIFulfillmentEventHSAEnrolmentJSON) JSON.deserialize(strJSON, HIFulfillmentEventHSAEnrolmentJSON.class);
		return objParsedData;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> list_HIEvents,
		map<string, HIFulfillmentEventHSAEnrolmentJSON> map_EventIdInfo,
		map<String, Account> map_Accounts,
		map<String, Contact> map_Contacts
	) {
		List<Contact> list_ContactForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c objHIFulfill : list_HIEvents) {
			if (objHIFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEventHSAEnrolmentJSON objHIEventInfo = map_EventIdInfo.get(objHIFulfill.Id__c);
			if (!map_Accounts.containsKey('' + objHIEventInfo.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', objHIFulfill);
				continue;
			}

			if (!map_Contacts.containsKey(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.email) && !map_Contacts.containsKey(objHIEventInfo.employee.email)) {
				Contact objContact = new Contact();
				objContact.AccountId = map_Accounts.get('' + objHIEventInfo.employee.company_id).Id;
				objContact.FirstName = objHIEventInfo.employee.first_Name;
				objContact.LastName = objHIEventInfo.employee.last_name;
				objContact.Email = objHIEventInfo.employee.email;
				objContact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
				list_ContactForInsert.add(objContact);
			}
		}
		if (list_ContactForInsert.size() > 0) {
			Map<String, String> map_DMLContactInsertErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = Database.insert(list_ContactForInsert, false);
			map_DMLContactInsertErrors = Utils.processSaveResult(list_SaveResults, list_ContactForInsert, 'email', true, 'HIFulfillmentEventTermination-processContactInformation');
			for (HI_Fulfillment_Event__c objHIFulfillment : list_HIEvents) {
				HIFulfillmentEventHSAEnrolmentJSON objHIEventInfo = map_EventIdInfo.get(objHIFulfillment.Id__c);
				if (map_DMLContactInsertErrors.containsKey(objHIEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLContactInsertErrors.get(objHIEventInfo.employee.email), objHIFulfillment);
					continue;
				}
			}
		}
	}

	private List<Case> getCaseInformation(
		map<String, caseDataWrapper> map_CaseWrapper,
		List<HI_Fulfillment_Event__c> list_HIEvents,
		map<string, HIFulfillmentEventHSAEnrolmentJSON> map_EventIdInfo,
		map<String, Account> map_Accounts,
		map<String, Contact> map_Contacts,
		Map<String, Carrier__c> map_Carrier
	) {
		map<String, String> map_CaseInfo = new Map<String, String>();
		Set<String> set_enrollmentKey = new Set<String>();
		for (HI_Fulfillment_Event__c objHIFulfill : list_HIEvents) {
			if (map_EventIdInfo.containsKey(objHIFulfill.Id__c)) {
				continue;
			}
			HIFulfillmentEventHSAEnrolmentJSON objHIEventInfo = map_EventIdInfo.get(objHIFulfill.Id__c);
			if (objHIEventInfo == null) {
				continue;
			}
			set_enrollmentKey.add('hsa-' + objHIEventInfo.hsa_selection.id + '-' + objHIEventInfo.hsa_benefit.provider_key);
		}

		for (Case objCase : [SELECT Id, Status, Enrollment_key__c FROM Case WHERE Enrollment_Key__c IN :set_enrollmentKey]) {
			map_CaseInfo.put(objCase.Enrollment_Key__c, objCase.Status);
		}

		List<Case> list_CaseInsert = new List<Case>();
		for (HI_Fulfillment_Event__c objHIFulfill : list_HIEvents) {
			if (objHIFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEventHSAEnrolmentJSON objHIEventInfo = map_EventIdInfo.get(objHIFulfill.Id__c);
			String strCarrierkey = objHIEventInfo.hsa_benefit.provider_key;

			Account acc = map_Accounts.get('' + objHIEventInfo.company.id);
			Contact objContact;
			if (map_Contacts.containsKey(objHIFulfill.Id__c + '-' + objHIEventInfo.employee.email)) {
				objContact = map_Contacts.get(objHIFulfill.Id__c + '-' + objHIEventInfo.employee.email);
			} else if (map_Contacts.containsKey(objHIEventInfo.employee.email)) {
				objContact = map_Contacts.get(objHIEventInfo.employee.email);
			}
			Database.DMLOptions objDMO = new Database.DMLOptions();
			objDMO.assignmentRuleHeader.useDefaultRule = true;

			if (!map_CaseWrapper.containsKey(objHIFulfill.Id__c + '-' + strCarrierkey)) {
				continue;
			}
			Case objCase = new Case();
			objCase.setOptions(objDMO);
			objCase.Integration_Id__c = objHIFulfill.Id__c;
			objCase.Integration_Key__c = objHIFulfill.Id__c + '-' + strCarrierkey;
			objCase.Enrollment_Key__c = 'hsa-' + objHIEventInfo.hsa_selection.id + '-' + strCarrierkey;
			objCase.Enrollment_Id__c = 'hsa-' + objHIEventInfo.hsa_selection.id;
			objCase.Description = map_CaseWrapper.get(objHIFulfill.Id__c + '-' + strCarrierkey).strCaseDescription;
			objCase.AccountId = acc.id;
			objCase.Fulfillment_Type__c = 'HSA Enrollment';
			objCase.Type = CaseUtils.TYPE_NHE;
			objCase.Origin = CaseUtils.ORIGIN_WEB;
			
			if (objContact != null) {
				objCase.ContactId = objContact.Id;
			}
			objCase.Anticipated_Effective_Date__c = map_CaseWrapper.get(objHIFulfill.Id__c + '-' + strCarrierkey).dtEffectiveDate;
			objCase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(strCarrierkey)) ? map_Carrier.get(strCarrierkey).Id : null;

			objCase.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');

			if (map_CaseInfo.containsKey('hsa-' + objHIEventInfo.hsa_selection.id + '-' + strCarrierkey)) {
				String strStatus = map_CaseInfo.get('hsa-' + objHIEventInfo.hsa_selection.id + '-' + strCarrierkey);
				if (strStatus == 'Cancelled') {
					objCase.Status = 'New';
				}
			}
			//End BBO-1966
			list_CaseInsert.add(objCase);
		}
		return list_CaseInsert;
	}

	public class caseDataWrapper {
		public String strEventId { get; set; }
		public String strStateCarrierKey { get; set; }
		public String stEventType { get; set; }
		public Long lnCompanyId { get; set; }
		public String strEmployeeEmail { get; set; }
		public String strCaseDescription { get; set; }
		public Date dtEffectiveDate { get; set; }
		public HIFulfillmentEventHSAEnrolmentJSON objHIEventInfo { get; set; }
		public String strPiiInformation { get; set; }

		public caseDataWrapper(
			String strEventId,
			String strStateCarrierKey,
			String stEventType,
			Long lnCompanyId,
			String strEmployeeEmail,
			String strCaseDescription,
			Date dtEffectiveDate,
			HIFulfillmentEventHSAEnrolmentJSON objHIEventInfoParsed,
			String strPiiInformation
		) {
			this.strEventId = strEventId;
			this.strStateCarrierKey = strStateCarrierKey;
			this.stEventType = stEventType;
			this.lnCompanyId = lnCompanyId;
			this.strEmployeeEmail = strEmployeeEmail;
			this.strCaseDescription = strCaseDescription;
			this.dtEffectiveDate = dtEffectiveDate;
			this.objHIEventInfo = objHIEventInfoParsed;
			this.strPiiInformation = strPiiInformation;
		}
	}
}