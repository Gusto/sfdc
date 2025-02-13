/*
    By: Pravesh Rana
    Date: 5/20/19
    Desc: Below class code handles the HiFulfillment Records where type = "Add_to_Basic_Pacific".
*/
public with sharing class HIFulfillmentAddToBasicPacific {
	public static final String BASIC_CARRIER = 'BASIC';

	string basicCarrierId;
	Set<String> accountIdZPSet = new Set<String>();
	Set<String> employeeEmailSet = new Set<String>();
	Map<String, HIFulfillmentAddToBasicPacificJSON> evenIdInfoMap = new Map<String, HIFulfillmentAddToBasicPacificJSON>();
	Map<String, CaseDataWrapper> caseWrapperMap = new Map<String, CaseDataWrapper>();

	public HIFulfillmentAddToBasicPacific() {
		list<Carrier__c> carrierList = [SELECT id FROM Carrier__c WHERE name = :BASIC_CARRIER LIMIT 1];
		if (carrierList.size() > 0) {
			basicCarrierId = carrierList.get(0).id;
		}
	}

	public void processInformation(List<HI_Fulfillment_Event__c> fulfillmentList) {
		Set<String> hiFulfillmentIDSet = new Set<String>();
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

		if (hiFulfillmentIDSet.size() > 0) {
			//Loop on HI Fulfillment Event to fetch json related data
			for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
				if (hiFulfill.Id__c == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'ID__c does not exist.', hiFulfill);
					continue;
				}

				HIFulfillmentAddToBasicPacificJSON hiEventInfoParsed;
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

				HIFulfillmentAddToBasicPacificJSON hiEventInfoParsed;
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
					employeeEmailSet.add(hiEventInfoParsed.employee.email);
				}

				evenIdInfoMap.put(hiFulfill.Id__c, hiEventInfoParsed);

				HIFulfillmentAddToBasicPacificJSON.cls_mailing_address companyBenefitAddress = hiEventInfoParsed.company.benefits_address;
				caseDataWrapper caseWrapper = new caseDataWrapper();
				String caseDescription;
				for (HIFulfillmentAddToBasicPacificJSON.cls_enrollees employeeRec : hiEventInfoParsed.enrollees) {
					if (string.isBlank(employeeRec.dependent_type) && string.isNotBlank(employeeRec.hippo_url)) {
						caseWrapper.employeeHippoURL = employeeRec.hippo_url;
					} else if (employeeRec.dependent_type == 'spouse' && string.isNotBlank(employeeRec.url)) {
						caseWrapper.spouseURL = employeeRec.url;
					} else if (employeeRec.dependent_type == 'child' && string.isNotBlank(employeeRec.url)) {
						if (string.isBlank(caseWrapper.childURL)) {
							caseWrapper.childURL = employeeRec.url;
						} else {
							caseWrapper.childURL += '\n' + employeeRec.url;
						}
					}

					if (string.isBlank(employeeRec.dependent_type)) {
						if (string.isBlank(caseWrapper.dependentInfo)) {
							caseWrapper.dependentInfo =
								'\n\n Dependent Info' +
								'\n- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(employeeRec.first_name, employeeRec.middle_initial, employeeRec.last_name) +
								'\n- SSN: ' +
								HIFulfillmentEventHelperFunctions.getMaskedSSN('' + employeeRec.ssn) +
								'\n- DOB: ' +
								HIFulfillmentEventHelperFunctions.getChangeDateFormat(employeeRec.birthday);
						} else {
							caseWrapper.dependentInfo +=
								'\n\n- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(employeeRec.first_name, employeeRec.middle_initial, employeeRec.last_name) +
								'\n- SSN: ' +
								HIFulfillmentEventHelperFunctions.getMaskedSSN('' + employeeRec.ssn) +
								'\n- DOB: ' +
								HIFulfillmentEventHelperFunctions.getChangeDateFormat(employeeRec.birthday);
						}
					}
				}

				for (HIFulfillmentAddToBasicPacificJSON.cls_subscriptions subscriptionRec : hiEventInfoParsed.subscriptions) {
					if (string.isBlank(caseWrapper.subscriptionLinks)) {
						caseWrapper.subscriptionLinks = ' \n- ' + subscriptionRec.benefit_type + ': ' + subscriptionRec.url;
					} else {
						caseWrapper.subscriptionLinks += ' \n- ' + subscriptionRec.benefit_type + ': ' + subscriptionRec.url;
					}
				}

				caseDescription =
					'Please add ONLY the following QBs in the BASIC portal \n\nQualified Beneficiaries:' +
					'\n- EE: ' +
					caseWrapper.employeeHippoURL +
					'\n- Spouse: ' +
					(caseWrapper.spouseURL != null ? caseWrapper.spouseURL : '') +
					'\n- Child: ' +
					(caseWrapper.childURL != null ? caseWrapper.childURL : '');
				caseDescription += '\n\n Event Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.event_date);
				caseDescription += '\n Event Type: ' + hiEventInfoParsed.event_type;
				caseDescription += '\n\n Subscriptions Link: ' + caseWrapper.subscriptionLinks;
				caseDescription += '\n\n EE Details: ' + hiEventInfoParsed.employee.hippo_url;
				caseDescription +=
					'\n\n Dependent Details: ' +
					'\n- Spouse: ' +
					(caseWrapper.spouseURL != null ? caseWrapper.spouseURL : '') +
					'\n- Child: ' +
					(caseWrapper.childURL != null ? caseWrapper.childURL : '');
				caseDescription +=
					'\n\nPlease visit the BASIC portal and input the following information: ' +
					'\n\n Company Info ' +
					'\n- Company Name: ' +
					hiEventInfoParsed.company.name +
					'\n- Company Address: ' +
					HIFulfillmentEventHelperFunctions.getAddress(
						companyBenefitAddress.street_1,
						companyBenefitAddress.street_2,
						companyBenefitAddress.city,
						companyBenefitAddress.county_name,
						companyBenefitAddress.state,
						companyBenefitAddress.zip,
						companyBenefitAddress.country
					);

				String piiInformationStr = 'Employee Info:';
				piiInformationStr +=
					'\n- Name: ' + HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name);
				piiInformationStr += '\n- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + hiEventInfoParsed.employee.ssn);
				piiInformationStr += '\n- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);
				piiInformationStr += caseWrapper.dependentInfo;

				caseWrapper.subjectStr =
					hiEventInfoParsed.company.name +
					' : ' +
					HIFulfillmentEventHelperFunctions.getName(hiEventInfoParsed.employee.first_name, hiEventInfoParsed.employee.middle_initial, hiEventInfoParsed.employee.last_name) +
					' : BASIC : Add to BASIC Pacific';
				caseWrapper.piiInformation = piiInformationStr;
				caseWrapper.caseDescription = caseDescription;
				caseWrapper.eventType = hiEventInfoParsed.event_type;

				string termination_date = hiEventInfoParsed.event_date;
				if (string.isNotBlank(termination_date)) {
					list<string> lst_DateFormat = termination_date.split('-');
					caseWrapper.terminationDate = date.newinstance(integer.valueof(lst_DateFormat.get(0)), integer.valueOf(lst_DateFormat.get(1)), integer.valueOf(lst_DateFormat.get(2)));
				}

				caseWrapperMap.put(hiFulfill.id__c, caseWrapper);
			}
		}

		map<String, Contact> contactMap = new Map<String, Contact>();

		if (employeeEmailSet.size() > 0) {
			contactMap = HIFulfillmentEventHelperFunctions.getContacts(employeeEmailSet);
			// using following method we are inserting Contact records in case Contact is not present in the org.
			HIFulfillmentEventHelperFunctions.processContactInformation(fulfillmentList, evenIdInfoMap, accountMap, contactMap);
			contactMap = HIFulfillmentEventHelperFunctions.getContacts(employeeEmailSet);
		}

		// getting the list of case object instances with all the related fields populated with proper values.
		List<Case> caseListForUpsert = getCaseInformation(caseWrapperMap, fulfillmentList, evenIdInfoMap, accountMap, contactMap);
		Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();

		// saving case records
		if (caseListForUpsert.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(caseListForUpsert, Case.Fields.Integration_Key__c, false);
			dmlCaseUpsertErrorsMap = Utils.processUpsertResult(saveResult, caseListForUpsert, 'Integration_Id__c', true, 'HIFulfillmentAddToBasicPacific-processInformation');
		}

		//save employee/dpenedent info in attachment in encrpted format.
		HIFulfillmentEventHelperFunctions.createAttachment(caseListForUpsert, caseWrapperMap);

		// Hi Fulfillment Event error handling/status updating code
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

	// this method is mapping Case fields with related information from CaseWrapper
	private List<Case> getCaseInformation(
		map<String, caseDataWrapper> caseWrapperMap,
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentAddToBasicPacificJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Case> caseInsertList = new List<Case>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentAddToBasicPacificJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!accountMap.containsKey('' + hiEventInfo.company.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', hiFulfill);
				continue;
			}
			Account acc = accountMap.get('' + hiEventInfo.company.id);
			Contact c;
			if (contactMap.containsKey(hiFulfill.Id__c + '-' + hiEventInfo.employee.email)) {
				c = contactMap.get(hiFulfill.Id__c + '-' + hiEventInfo.employee.email);
			} else if (contactMap.containsKey(hiEventInfo.employee.email)) {
				c = contactMap.get(hiEventInfo.employee.email);
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
			cse.Type = caseWrapperMap.get(hiFulfill.Id__c).eventType;
			cse.Tax_Id__c = label.Case_AddToBasicPacific_TaxId;
			if (string.isNotBlank(basicCarrierId)) {
				cse.Carrier__c = basicCarrierId;
			}
			cse.Subject = caseWrapperMap.get(hiFulfill.Id__c).subjectStr;
			cse.status = 'New';
			cse.Google_Drive_URL__c = hiEventInfo.company.google_drive_folder_url;
			caseInsertList.add(cse);
		}
		return caseInsertList;
	}

	//calling HIFulfillmentTerminationEvenJSON class for parsing data
	private HIFulfillmentAddToBasicPacificJSON getJSONParsedData(String jsonString) {
		HIFulfillmentAddToBasicPacificJSON parsedData = (HIFulfillmentAddToBasicPacificJSON) JSON.deserialize(jsonString, HIFulfillmentAddToBasicPacificJSON.class);
		return parsedData;
	}

	public class caseDataWrapper {
		public Long zPCompanyId { get; set; }
		public String subjectStr { get; set; }
		public string status { get; set; }
		public string statusDetails { get; set; }
		public string requirdAction { get; set; }
		public String caseDescription { get; set; }
		public Date terminationDate { get; set; }
		public string followUpMethod { get; set; }
		public string employeeInfo { get; set; }
		public string taxInfo { get; set; }
		public HIFulfillmentAddToBasicPacificJSON hiEventInfo { get; set; }
		public string employeeHippoURL { get; set; }
		public string spouseURL { get; set; }
		public string childURL { get; set; }
		public string subscriptionLinks { get; set; }
		public string piiInformation { get; set; }
		public string dependentInfo { get; set; }
		public string eventType { get; set; }

		public caseDataWrapper() {
		}
	}
}