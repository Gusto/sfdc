/**
 * @name         HIFulfillmentBORNewHire
 * @author       Aurobind Ravichandran
 * @date         12/15/2017
 * @description
 * @revisions    Date ------------ Name ------------ Comments
 *				1/2/2020		  Anand         Replace the BOR transfer Code to BO (BOR record type) code
 **/
public class HIFulfillmentBORNewHire {
	public void processInformation(List<HI_Fulfillment_Event__c> fulfillmentList) {
		Set<String> hiFulfillmentIDSet = new Set<String>();
		List<HI_Fulfillment_Event__c> toUpsertFulfillmentList = new List<HI_Fulfillment_Event__c>();
		List<Case> caseList = new List<Case>();
		Set<String> accountIdZPSet = new Set<String>();
		Set<String> set_EmployeeSearchKey = new Set<String>();
		Map<String, String> mapAccountZPToId = new Map<String, String>();
		Map<String, String> mapContactEmailToId = new Map<String, String>();
		Map<String, set<String>> enrollmentEnrollmentKeyMap = new Map<String, set<String>>();
		Map<String, HIFulfillmentBORNewHireJSON> evenIdInfoMap = new Map<String, HIFulfillmentBORNewHireJSON>();
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
				HIFulfillmentBORNewHireJSON hiEventInfoParsed;
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

				accountIdZPSet.add(String.valueOf(hiEventInfoParsed.company.id));
				if (hiEventInfoParsed.employee.email != null && hiEventInfoParsed.employee.email != '') {
					set_EmployeeSearchKey.add(hiEventInfoParsed.employee.email);
				}

				if (hiEventInfoParsed.employee.id != null) {
					set_EmployeeSearchKey.add(hiEventInfoParsed.employee.id + '');
				}

				evenIdInfoMap.put(hiFulfill.Id__c, hiEventInfoParsed);

				HIFulfillmentBORNewHireJSON.cls_Address employeeHomeAddress = hiEventInfoParsed.employee.home_address;
				HIFulfillmentBORNewHireJSON.cls_Address companyBenefitAddress = hiEventInfoParsed.company.benefits_address;
				Date hireDate;
                
				if (hiEventInfoParsed.employee.hired_at != null && hiEventInfoParsed.employee.hired_at != '') {
					hireDate = Date.valueOf(hiEventInfoParsed.employee.hired_at);
				}

				String caseDescription = '';

				caseDescription += '\nEvent Type: New hire during BOR';
				caseDescription += '\nHire Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.hired_at);

				String employeeName = HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_Name, hiEventInfoParsed.employee.last_Name, hiEventInfoParsed.employee.middle_initial);
				caseDescription += '\n\n' + employeeName + ' of ' + hiEventInfoParsed.company.name + ' would like to enroll in the following Alegeus plans:';
				caseDescription += '\nLink to employee: ' + hiEventInfoParsed.employee.hippo_url;
				caseDescription += '\nEE Panda Link: ' + hiEventInfoParsed.employee.panda_url;

				String piiInformation = 'Employee Info:';
				piiInformation +=
					'<br/>- Name: ' + HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name);
				piiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + hiEventInfoParsed.employee.ssn);
				piiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);

				caseDataWrapper caseWrapper = new caseDataWrapper(
					hiFulfill.Id__c,
					'',
					hiFulfill.Event_Type__c,
					hiEventInfoParsed.company.id,
					hiEventInfoParsed.employee.email,
					caseDescription,
					hireDate,
					hiEventInfoParsed,
					piiInformation
				);

				caseWrapperMap.put(hiFulfill.id__c, caseWrapper);
			}
		}

		map<String, Account> accountMap = HIFulfillmentEventHelperFunctions.getAccounts(accountIdZPSet);
		map<String, Contact> contactMap = new Map<String, Contact>();
		if (set_EmployeeSearchKey.size() > 0) {
			contactMap = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);
		}

		processContactInformation(fulfillmentList, evenIdInfoMap, accountMap, contactMap);
		if (set_EmployeeSearchKey.size() > 0) {
			contactMap = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);
		}
		List<Case> caseListForUpsert = getCaseInformation(caseWrapperMap, fulfillmentList, evenIdInfoMap, accountMap, contactMap);
		Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();

		if (caseListForUpsert.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(caseListForUpsert, Case.Fields.Integration_Id__c, false);
			dmlCaseUpsertErrorsMap = Utils.processUpsertResult(saveResult, caseListForUpsert, 'Integration_Id__c', true, 'HIFulfillmentBORNewHire-processInformation');
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
	public static HIFulfillmentBORNewHireJSON getJSONParsedData(String jsonString) {
		HIFulfillmentBORNewHireJSON parsedData = (HIFulfillmentBORNewHireJSON) JSON.deserialize(jsonString, HIFulfillmentBORNewHireJSON.class);
		return parsedData;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentBORNewHireJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Contact> contactListForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentBORNewHireJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
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
			dmlContactInsertErrorsMap = Utils.processSaveResult(saveResult, contactListForInsert, 'email', true, 'HIFulfillmentBORNewHire-processContactInformation');
			for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
				HIFulfillmentBORNewHireJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
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
		map<string, HIFulfillmentBORNewHireJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		map<String, String> caseInfoMap = new Map<String, String>();
		Set<String> borIdSet = new Set<String>();
		Set<String> set_CreateCaseForStatus = new Set<String>{
			'Plans Confirmed',
			'Enrollment Review Entry in Progress',
			'Ready to Send Enrollment Review',
			'Enrollment Review Sent',
			'Enrollment Confirmed',
			'Implementing TAdA Plans',
			'Ready for Balance Collection',
			'Balance Collection',
			'Transferring Balances',
			'BOR complete pending TAdAs'
		};
        
		Map<String, Benefit_Order__c> map_BenefitOrderBOR = new Map<String, Benefit_Order__c>();

		for (HIFulfillmentBORNewHireJSON hiFulfill : evenIdInfoMap.values()) {
			borIdSet.add('' + hiFulfill.bor_transfer.id);
		}

		for (Benefit_Order__c objBenefitOrder : [SELECT Id, BoR_Id__c, OwnerId, Order_Status__c, RecordType.DeveloperName FROM Benefit_Order__c WHERE BoR_Id__c IN :borIdSet]) {
			map_BenefitOrderBOR.put(objBenefitOrder.BoR_Id__c, objBenefitOrder);
		}

		List<Case> caseInsertList = new List<Case>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentBORNewHireJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!map_BenefitOrderBOR.containsKey('' + hiEventInfo.bor_transfer.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'BOR Transfer record does not exist', hiFulfill);
				continue;
			}

			Benefit_Order__c objBTBenefitOrder = map_BenefitOrderBOR.get('' + hiEventInfo.bor_transfer.id);

			Account acc = accountMap.get('' + hiEventInfo.company.id);
			Contact c;
			if (hiEventInfo.employee.email != null && hiEventInfo.employee.email != '') {
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

			if (!caseWrapperMap.containsKey(hiFulfill.Id__c)) {
				continue;
			}
			// SJay - 03/24/2020 - Added check for BO status to be in Plans Confirmed or higher to create a BOR New Hire case.
			if (set_CreateCaseForStatus.contains(objBTBenefitOrder.Order_Status__c) && objBTBenefitOrder.RecordType.DeveloperName == 'Benefits_BoR') {
				Case cse = new Case();
				cse.OwnerId = label.Member_Fulfillment_Queue;
				cse.Integration_Id__c = hiFulfill.Id__c;
				cse.Integration_Key__c = hiFulfill.Id__c;
				cse.Description = caseWrapperMap.get(hiFulfill.Id__c).caseDescription;
				cse.AccountId = acc.id;
				cse.Benefit_Order__c = objBTBenefitOrder.id;
				if (c != null) {
					cse.ContactId = c.Id;
				}
				cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');
				cse.Type = 'NHE';
				cse.Status = 'New';
				caseInsertList.add(cse);
			}
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
		public Date hireDate { get; set; }
		public HIFulfillmentBORNewHireJSON hiEventInfo { get; set; }
		public String piiInformation { get; set; }

		public caseDataWrapper(
			String eeventId,
			String carrierKey,
			String eventT,
			Long companyId,
			String eEmail,
			String caseDesc,
			Date ehireDate,
			HIFulfillmentBORNewHireJSON hiEventInfoParsed,
			String piiInfo
		) {
			eventId = eeventId;
			stateCarrierKey = carrierKey;
			eventType = eventT;
			zPCompanyId = companyId;
			employeeEmail = eEmail;
			caseDescription = caseDesc;
			hireDate = ehireDate;
			hiEventInfo = hiEventInfoParsed;
			piiInformation = piiInfo;
		}
	}
}