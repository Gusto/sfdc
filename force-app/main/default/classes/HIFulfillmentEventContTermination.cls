/**
 * @name         HIFulfillmentEventContTermination
 * @author       Chaitanya Kurra
 * @date         09-28-2020
 * @description  HIFulfillmentEventContTermination handles case creation porcess for State Continuation Termination.
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class HIFulfillmentEventContTermination {
	Map<String, integer> map_FulfillmentSubscriptionCount = new Map<String, integer>();
	map<String, List<HIFulfillmentContTerminationEventJSON.cls_forms>> map_StateCarrierIdForm;
	map<String, Map<String, Object>> map_StateCarrierIdFormMappings;
	String strEnrollmentId = '';
	String strSelectionIds = '';
	String strPolicyGroupNumber = '';
	String strPolicyNumber = '';
	Set<String> set_CreateTermBORCaseForStatuses = new Set<String>{ 'Enrollment Confirmed', 'Fulfilled', 'BOR complete pending TAdAs' };

	public void processInformation(List<HI_Fulfillment_Event__c> list_Fulfillments) {
		List<HI_Fulfillment_Event__c> list_UpsertFulfillment = new List<HI_Fulfillment_Event__c>();
		List<Case> list_Case = new List<Case>();
		Set<String> set_CarrierKey = new Set<String>();
		Set<String> set_AccountIdZP = new Set<String>();
		Set<String> set_EmployeeEmail = new Set<String>();
		Map<String, DateTime> map_TermCancelEmployeeId = new Map<String, DateTime>();
		Set<String> set_EemployeeId = new Set<String>();
		Map<String, String> map_CarrierKeyToId = new Map<String, String>();
		Map<String, String> map_AccountZPToId = new Map<String, String>();
		Map<String, String> map_ContactEmailToId = new Map<String, String>();
		Map<String, HIFulfillmentContTerminationEventJSON> map_EvenIdInfo = new Map<String, HIFulfillmentContTerminationEventJSON>();
		Map<String, CaseDataWrapper> map_CaseWrapper = new Map<String, CaseDataWrapper>();
		map_FulfillmentSubscriptionCount = new Map<String, integer>();
		List<Contact> list_Contact = new List<Contact>();
		Set<String> set_NewContactEmails = new Set<String>();
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		map<String, Account> map_Account = new Map<String, Account>();
		map<String, Benefit_Order__c> map_BenefitOrder = new Map<String, Benefit_Order__c>();

		//Loop on HI Fulfillment Event to fetch json related data
		for (HI_Fulfillment_Event__c ObjHiFulfill : list_Fulfillments) {
			if (ObjHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			ObjHiFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			ObjHiFulfill.Message__c = '';

			HIFulfillmentContTerminationEventJSON hiEventInfoParsed;
			try {
				Blob blob_Decrypted = EncodingUtil.base64Decode(ObjHiFulfill.Event_Info_Encrypted__c);
				String strDeCryptedText = EncryptionUtils.getDecryptedText(blobEncryptionKey, blob_Decrypted);
				hiEventInfoParsed = getJSONParsedData(strDeCryptedText);
			} catch (Exception e) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', ObjHiFulfill);
				continue;
			}
			set_AccountIdZP.add(String.valueOf(hiEventInfoParsed.company.id));
			if (string.isNotBlank(ObjHiFulfill.Employee_Id__c)) {
				set_EemployeeId.add(ObjHiFulfill.Employee_Id__c);
			}

			if (hiEventInfoParsed.losing_benefits_reason == 'employee_continuation_termination') {
				//Leave this commnented
				map_TermCancelEmployeeId.put('' + hiEventInfoParsed.Employee.id, ObjHiFulfill.sent_at__c);
			}
		}

		if (set_AccountIdZP != null && set_AccountIdZP.size() > 0) {
			map_Account = HIFulfillmentEventHelperFunctions.getAccounts(set_AccountIdZP);
			map_BenefitOrder = HIFulfillmentEventHelperFunctions.getBenefitOrderMap(set_AccountIdZP);
		}

		Set<String> set_ExistingTermCase = new Set<String>();
		if (map_TermCancelEmployeeId.size() > 0) {
			existingTrminationCaseWrapper objTermWrapper = getCaseCaseInfoByEmployeeId(map_TermCancelEmployeeId);
			set_ExistingTermCase = objTermWrapper.set_EmployeeIdCarrierKey;
		}

		for (HI_Fulfillment_Event__c ObjHiFulfill : list_Fulfillments) {
			if (ObjHiFulfill.Id__c == null) {
				continue;
			}
			HIFulfillmentContTerminationEventJSON objHIEventInfoParsed;
			try {
				Blob blob_Decrypted = EncodingUtil.base64Decode(ObjHiFulfill.Event_Info_Encrypted__c);
				String strDeCryptedText = EncryptionUtils.getDecryptedText(blobEncryptionKey, blob_Decrypted);
				objHIEventInfoParsed = getJSONParsedData(strDeCryptedText);
			} catch (Exception e) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', ObjHiFulfill);
				continue;
			}

			if (String.isNotBlank(objHIEventInfoParsed.sent_at)) {
				ObjHiFulfill.Sent_at__c = HIFulfillmentEventHelperFunctions.getDateTimeFromString(objHIEventInfoParsed.sent_at);
			}

			if (objHIEventInfoParsed == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', ObjHiFulfill);
				continue;
			}
			if (ObjHiFulfill.Event_Type__c == null || ObjHiFulfill.Event_Type__c == '') {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Fulfillment Event Type: field value is missing in the record.', ObjHiFulfill);
				continue;
			}
			if (objHIEventInfoParsed.company.id == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Company Id: field value is missing in the record.', ObjHiFulfill);
				continue;
			}
			if (objHIEventInfoParsed.employee.id == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI employee Id: field value is missing in the record.', ObjHiFulfill);
				continue;
			}
            
			if (objHIEventInfoParsed.employee.email != null) {
				set_EmployeeEmail.add(objHIEventInfoParsed.employee.email);
			}
			if (objHIEventInfoParsed.employee.Id != null) {
				set_EemployeeId.add('' + objHIEventInfoParsed.employee.Id);
			}

			Map<String, HIFulfillmentContTerminationEventJSON.cls_dependents> map_Dependents = new Map<String, HIFulfillmentContTerminationEventJSON.cls_dependents>();
			if (objHIEventInfoParsed.dependents != null && objHIEventInfoParsed.dependents.size() > 0) {
				for (HIFulfillmentContTerminationEventJSON.cls_dependents dependent : objHIEventInfoParsed.dependents) {
					map_Dependents.put('' + dependent.id, dependent);
				}
			}
			map_EvenIdInfo.put(ObjHiFulfill.Id__c, objHIEventInfoParsed);
			Map<String, Set<String>> map_CarrierToDependentId = new Map<String, Set<String>>();
			Map<String, List<HIFulfillmentContTerminationEventJSON.cls_benefit_items>> map_CarrierToSubscriptionList = new Map<String, List<HIFulfillmentContTerminationEventJSON.cls_benefit_items>>();
			map<String, HIFulfillmentContTerminationEventJSON.cls_policies> map_PolicyId = new Map<String, HIFulfillmentContTerminationEventJSON.cls_policies>();
			map_StateCarrierIdForm = new Map<String, List<HIFulfillmentContTerminationEventJSON.cls_forms>>(); // key is State CarrierId and value is Form
			map_StateCarrierIdFormMappings = new Map<String, Map<String, Object>>();
			if (objHIEventInfoParsed.forms != null && objHIEventInfoParsed.forms.size() > 0) {
				for (HIFulfillmentContTerminationEventJSON.cls_forms objForm : objHIEventInfoParsed.forms) {
					String strKey = '' + objForm.state_carrier_id;
					List<HIFulfillmentContTerminationEventJSON.cls_forms> list_forms;
					if (String.isNotBlank(strKey) && map_StateCarrierIdForm.containsKey(strKey)) {
						list_forms = map_StateCarrierIdForm.get(strKey);
					} else {
						list_forms = new List<HIFulfillmentContTerminationEventJSON.cls_forms>();
					}
					list_forms.add(objForm);
					map_StateCarrierIdForm.put(strKey, list_forms);
				}
			}
			Map<String, Set<String>> map_terminationPolicyPerCarrier = new Map<String, Set<String>>();

			if (objHIEventInfoParsed.policies != null && objHIEventInfoParsed.policies.size() > 0) {
				for (HIFulfillmentContTerminationEventJSON.cls_policies objPolicy : objHIEventInfoParsed.policies) {
					map_PolicyId.put('' + objPolicy.id, objPolicy);

					Set<String> set_TermPolicy;

					if (map_terminationPolicyPerCarrier.containsKey('' + objPolicy.state_carrier_id)) {
						set_TermPolicy = map_terminationPolicyPerCarrier.get('' + objPolicy.state_carrier_id);
					} else {
						set_TermPolicy = new Set<String>();
					}
					set_TermPolicy.add(objPolicy.termination_policy);
					map_terminationPolicyPerCarrier.put('' + objPolicy.state_carrier_id, set_TermPolicy);
				}
			}

			if (objHIEventInfoParsed.subscriptions != null && objHIEventInfoParsed.subscriptions.size() > 0) {
				map_FulfillmentSubscriptionCount.put(ObjHiFulfill.Id__c, objHIEventInfoParsed.subscriptions.size());

				for (HIFulfillmentContTerminationEventJSON.cls_benefit_items objSubscription : objHIEventInfoParsed.subscriptions) {
					List<HIFulfillmentContTerminationEventJSON.cls_benefit_items> list_subscription = new List<HIFulfillmentContTerminationEventJSON.cls_benefit_items>();
					if (map_CarrierToSubscriptionList.containsKey('' + objSubscription.state_carrier_id)) {
						list_subscription = map_CarrierToSubscriptionList.get('' + objSubscription.state_carrier_id);
					}
					list_subscription.add(objSubscription);
					map_CarrierToSubscriptionList.put('' + objSubscription.state_carrier_id, list_subscription);

					Set<String> set_DependentIds = new Set<String>();
					if (map_CarrierToDependentId.containsKey('' + objSubscription.state_carrier_id)) {
						set_DependentIds = map_CarrierToDependentId.get('' + objSubscription.state_carrier_id);
					}

					if (objSubscription.dependent_ids != null && objSubscription.dependent_ids.size() > 0) {
						for (Long lngDependentId : objSubscription.dependent_ids) {
							set_DependentIds.add('' + lngDependentId);
						}
					}
					map_CarrierToDependentId.put('' + objSubscription.state_carrier_id, set_DependentIds);
				}
			} else {
				map_FulfillmentSubscriptionCount.put(ObjHiFulfill.Id__c, 0);
			}

			HIFulfillmentContTerminationEventJSON.cls_home_address employeeHomeAddress = objHIEventInfoParsed.employee.home_address;
			HIFulfillmentContTerminationEventJSON.cls_address companyBenefitAddress = objHIEventInfoParsed.company.benefits_address;
			caseDataWrapper objCaseWrapper;
			boolean blnStateCarrierError = false;
			if (objHIEventInfoParsed.State_carriers != null && objHIEventInfoParsed.State_carriers.size() > 0) {
				for (HIFulfillmentContTerminationEventJSON.cls_state_carriers objStateCarrier : objHIEventInfoParsed.State_carriers) {
					String strCaseDescription = '';
					strEnrollmentId = '';

					if (objStateCarrier.key == null || objStateCarrier.key == '') {
						blnStateCarrierError = true;
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'State Carrier Key: field value is missing in the record.', ObjHiFulfill);
						continue;
					}

					if (objStateCarrier.key != null)
						set_CarrierKey.add(objStateCarrier.key);

					String strEnrollmentKey = strEnrollmentId + '-' + objStateCarrier.key + '-' + objHIEventInfoParsed.employee.id;

					if (objHIEventInfoParsed.losing_benefits_reason == 'employee_continuation_termination') {
						strCaseDescription += 'CONTINUATION TERMINATION \n\n';
						if (set_ExistingTermCase.contains(strEnrollmentKey)) {
							continue;
						}
					}
					strSelectionIds = '';
					strPolicyGroupNumber = '';
					strPolicyNumber = '';
					String strBotJson = getCarrierBotJson(objHIEventInfoParsed, objStateCarrier.id, blobEncryptionKey);

					strCaseDescription +=
						'General Info' +
						'\n- Triggering Event and Date: Continuation Subscription End on ' +
						HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.losing_benefits_date) +
						'\n- Continuation Subscriptions link: ' +
						objHIEventInfoParsed.subscriptions_url +
						'\n- EE Panda Link: ' +
						objHIEventInfoParsed.employee.panda_url +
						'\n- Carrier Directory: ' +
						objHIEventInfoParsed.carrier_directory +
						'\n\n- COBRA Activated: ' +
						objHIEventInfoParsed.company.has_federal_cobra +
						'\n\nCarrier' +
						'\n- Carrier: ' +
						objStateCarrier.name +
						'\n- Carrier State: ' +
						objStateCarrier.state +
						'\n\nTermination Forms' +
						getForms(objStateCarrier.id) +
						'\n\nCompany Info' +
						'\n- Company Name: ' +
						objHIEventInfoParsed.company.name +
						'\n- Company Address:' +
						HIFulfillmentEventHelperFunctions.getAddress(
							companyBenefitAddress.street_1,
							companyBenefitAddress.street_2,
							companyBenefitAddress.city,
							companyBenefitAddress.county_name,
							companyBenefitAddress.state,
							companyBenefitAddress.zip,
							companyBenefitAddress.country
						) +
						'\n\nPlease review and submit the required documents to the carrier.';

					String strPiiInformation = 'Employee Info:';
					strPiiInformation +=
						'<br/>- Name: ' +
						HIFulfillmentEventHelperFunctions.getName(objHIEventInfoParsed.employee.first_name, objHIEventInfoParsed.employee.middle_initial, objHIEventInfoParsed.employee.last_name);
					strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHIEventInfoParsed.employee.ssn);
					strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday);

					Date dtCoverageStartDate = getCoverageStartDate('' + objStateCarrier.id, map_CarrierToSubscriptionList, map_PolicyId);

					Date dtTerminationDate = Date.valueOf(objHIEventInfoParsed.losing_benefits_date);

					Set<String> set_terminationPolicy;
					if (map_terminationPolicyPerCarrier.containsKey('' + objStateCarrier.id)) {
						set_terminationPolicy = map_terminationPolicyPerCarrier.get('' + objStateCarrier.id);
					}

					objCaseWrapper = new caseDataWrapper(
						ObjHiFulfill.Id__c,
						objStateCarrier.key,
						ObjHiFulfill.Event_Type__c,
						objHIEventInfoParsed.company.id,
						objHIEventInfoParsed.employee.email,
						strCaseDescription,
						dtTerminationDate,
						strEnrollmentId,
						strEnrollmentKey,
						objHIEventInfoParsed,
						strPiiInformation,
						strBotJson,
						strSelectionIds,
						strPolicyGroupNumber,
						strPolicyNumber,
						dtCoverageStartDate,
						set_terminationPolicy
					);

					map_CaseWrapper.put(ObjHiFulfill.id__c + '-' + objStateCarrier.key, objCaseWrapper);
				}
			}
		}

		map<String, Contact> map_ContactString = new Map<String, Contact>();
		if (set_EmployeeEmail.size() > 0) {
			map_ContactString = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);
		}

		map<String, Carrier__c> map_CarrierString = new Map<String, Carrier__c>();
		if (set_CarrierKey != null && set_CarrierKey.size() > 0) {
			map_CarrierString = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKey);
		}

		processContactInformation(list_Fulfillments, map_EvenIdInfo, map_Account, map_ContactString);

		if (set_EmployeeEmail.size() > 0) {
			map_ContactString = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);
		}

		List<Case> list_CasesForUpsert = getCaseInformation(map_CaseWrapper, list_Fulfillments, map_EvenIdInfo, map_Account, map_ContactString, map_CarrierString, map_BenefitOrder);
		Map<String, String> map_DMLCaseUpsertErrors = new Map<String, String>();
		if (list_CasesForUpsert.size() > 0) {
			List<Database.UpsertResult> list_SaveResults = database.upsert(list_CasesForUpsert, Case.Fields.Enrollment_Key__c, false);
			map_DMLCaseUpsertErrors = Utils.processUpsertResult(list_SaveResults, list_CasesForUpsert, 'Integration_Id__c', true, 'HIFulfillmentEventTermination-processInformation');
		}
		createAttachment(list_CasesForUpsert, map_CaseWrapper);
		for (HI_Fulfillment_Event__c ObjHiFulfill : list_Fulfillments) {
			if (ObjHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || ObjHiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (map_DMLCaseUpsertErrors.containsKey(ObjHiFulfill.Id__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLCaseUpsertErrors.get(ObjHiFulfill.Id__c), ObjHiFulfill);
				continue;
			} else {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Data successfully Processed', ObjHiFulfill);
			}
		}
	}

	public static void createAttachment(List<Case> list_CasesForUpsert, map<String, CaseDataWrapper> map_CaseWrapper) {
		List<Attachment> list_Attachments = new List<Attachment>();
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (Case objCase : list_CasesForUpsert) {
			if (objCase.Id != null) {
				if (map_CaseWrapper.containsKey(objCase.Integration_Key__c)) {
					CaseDataWrapper objCaseDataWrapper = map_CaseWrapper.get(objCase.Integration_Key__c);
					Attachment objAttachment = new Attachment();
					objAttachment.ParentId = objCase.Id;
					objAttachment.Body = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, objCaseDataWrapper.strPiiInformation);
					objAttachment.Name = 'encFile.txt';
					list_Attachments.add(objAttachment);
				}
			}
		}
		if (list_Attachments.size() > 0) {
			insert list_Attachments;
		}
	}

	//calling HIFulfillmentContTerminationEventJSON class for parsing data
	private HIFulfillmentContTerminationEventJSON getJSONParsedData(String strJSON) {
		HIFulfillmentContTerminationEventJSON parsedData = (HIFulfillmentContTerminationEventJSON) JSON.deserialize(strJSON, HIFulfillmentContTerminationEventJSON.class);
		return parsedData;
	}

	private Date getCoverageStartDate(
		String strCarrierId,
		Map<String, List<HIFulfillmentContTerminationEventJSON.cls_benefit_items>> map_CarrierToSubscriptionList,
		map<String, HIFulfillmentContTerminationEventJSON.cls_policies> map_PolicyId
	) {
		Date dtCoverageStartDate = null;

		if (map_CarrierToSubscriptionList.containsKey(strCarrierId)) {
			for (HIFulfillmentContTerminationEventJSON.cls_benefit_items objSubscription : map_CarrierToSubscriptionList.get(strCarrierId)) {
				if (objSubscription.start_date != null && objSubscription.start_date != '') {
					if (dtCoverageStartDate == null) {
						dtCoverageStartDate = Date.valueOf(objSubscription.start_date);
					} else if (dtCoverageStartDate > Date.valueOf(objSubscription.start_date)) {
						dtCoverageStartDate = Date.valueOf(objSubscription.start_date);
					}
				}
			}
		}
		return dtCoverageStartDate;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> list_Fulfillments,
		map<string, HIFulfillmentContTerminationEventJSON> map_EvenIdInfo,
		map<String, Account> map_Account,
		map<String, Contact> map_ContactString
	) {
		List<Contact> list_ContactsToInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c ObjHiFulfill : list_Fulfillments) {
			if (ObjHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || ObjHiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentContTerminationEventJSON objHIEventInfo = new HIFulfillmentContTerminationEventJSON();

			if (ObjHiFulfill.Id__c != null && map_EvenIdInfo.containsKey(ObjHiFulfill.Id__c)) {
				objHIEventInfo = map_EvenIdInfo.get(ObjHiFulfill.Id__c);
			}
			if (!map_Account.containsKey('' + objHIEventInfo.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', ObjHiFulfill);
				continue;
			}

			if (
				objHIEventInfo.employee.email != null &&
				!map_ContactString.containsKey(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.email) &&
				!map_ContactString.containsKey(objHIEventInfo.employee.email)
			) {
				Contact objContact = new Contact();
				objContact.AccountId = map_Account.get('' + objHIEventInfo.employee.company_id).Id;
				objContact.FirstName = objHIEventInfo.employee.first_Name;
				objContact.LastName = objHIEventInfo.employee.last_name;
				objContact.Email = objHIEventInfo.employee.email;
				objContact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
				list_ContactsToInsert.add(objContact);
			}
		}
		if (list_ContactsToInsert.size() > 0) {
			Map<String, String> map_DMLContactInsertErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = database.insert(list_ContactsToInsert, false);
			map_DMLContactInsertErrors = Utils.processSaveResult(list_SaveResults, list_ContactsToInsert, 'email', true, 'HIFulfillmentEventTermination-processContactInformation');
			for (HI_Fulfillment_Event__c ObjHIFulfill : list_Fulfillments) {
				HIFulfillmentContTerminationEventJSON objHIEventInfo = map_EvenIdInfo.get(ObjHIFulfill.Id__c);
				if (map_DMLContactInsertErrors.containsKey(objHIEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLContactInsertErrors.get(objHIEventInfo.employee.email), ObjHIFulfill);
					continue;
				}
			}
		}
	}

	//Get forms information
	private String getForms(Long lngStateCarrierid) {
		string strFormInfo = '';
		if (map_StateCarrierIdForm == null || !map_StateCarrierIdForm.containsKey('' + lngStateCarrierid)) {
			strFormInfo = ' not available';
		} else {
			String strMissingFormAttributes = '';
			Boolean blnFullyMapped = true, blnFitsDependents = true;
			Set<String> set_missingattributes = new Set<String>();
			for (HIFulfillmentContTerminationEventJSON.cls_forms objForm : map_StateCarrierIdForm.get('' + lngStateCarrierid)) {
				strFormInfo += '\n- ' + objForm.url;

				//Check for form flags, if any of the forms has fully_mapped set to false, it is set as false at case level
				if (blnFullyMapped && (objForm.fully_mapped == false || objForm.fully_mapped == null)) {
					blnFullyMapped = false;
				}
				//Check for form flags, if any of the forms has fits dependents set to false, it is set as false at case level
				if (blnFitsDependents && (objForm.form_includes_all_dependents == false || objForm.form_includes_all_dependents == null)) {
					blnFitsDependents = false;
				}
				//Get all missing values in forms and store them at case level in comma separated format
				if (objForm.missing_values_by_path != null && !objForm.missing_values_by_path.isEmpty()) {
					set_missingattributes.addAll(objForm.missing_values_by_path);
				}
			}
			if (!set_missingattributes.isEmpty()) {
				List<String> list_MissingFormAttr = new List<String>(set_missingattributes);
				strMissingFormAttributes = String.join(list_MissingFormAttr, ',\n');
			}
			Map<String, Object> map_formMapping = new Map<String, Object>();
			map_formMapping.put('fullymapped', blnFullyMapped);
			map_formMapping.put('missingattributes', strMissingFormAttributes);
			map_formMapping.put('fitsdependents', blnFitsDependents);
			map_StateCarrierIdFormMappings.put('' + lngStateCarrierid, map_formMapping);
		}
		return strFormInfo;
	}

	private List<Case> getCaseInformation(
		map<String, caseDataWrapper> map_CaseWrapper,
		List<HI_Fulfillment_Event__c> list_Fulfillments,
		map<string, HIFulfillmentContTerminationEventJSON> map_EvenIdInfo,
		map<String, Account> map_Account,
		map<String, Contact> map_ContactString,
		map<String, Carrier__c> map_CarrierString,
		map<String, Benefit_Order__c> map_BenefitOrder
	) {
		List<Case> list_CasesToInsert = new List<Case>();

		for (HI_Fulfillment_Event__c ObjHiFulfill : list_Fulfillments) {
			Database.DMLOptions dmoNoRule = new Database.DMLOptions();
			dmoNoRule.assignmentRuleHeader.useDefaultRule = false;
			if (ObjHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || ObjHiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentContTerminationEventJSON objHIEventInfo = map_EvenIdInfo.get(ObjHiFulfill.Id__c);

			Account objAccount = map_Account.get('' + objHIEventInfo.company.id);
			Contact objContact;
			if (map_ContactString.containsKey(ObjHiFulfill.Id__c + '-' + objHIEventInfo.employee.email)) {
				objContact = map_ContactString.get(ObjHiFulfill.Id__c + '-' + objHIEventInfo.employee.email);
			} else if (map_ContactString.containsKey(objHIEventInfo.employee.email)) {
				objContact = map_ContactString.get(objHIEventInfo.employee.email);
			}

			if (objHIEventInfo.State_carriers != null && objHIEventInfo.State_carriers.size() > 0) {
				for (HIFulfillmentContTerminationEventJSON.cls_state_carriers stateCarrier : objHIEventInfo.State_carriers) {
					if (!map_CaseWrapper.containsKey(ObjHiFulfill.Id__c + '-' + stateCarrier.Key)) {
						continue;
					}

					Case objCase = new Case();
					objCase.Integration_Id__c = ObjHiFulfill.Id__c;
					objCase.Integration_Key__c = ObjHiFulfill.Id__c + '-' + stateCarrier.Key;
					objCase.Description = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strCaseDescription;
					objCase.MF_Group_Number__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strGroupNumber;
					objCase.MF_Policy_Number__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strPolicyNumber;
					objCase.AccountId = objAccount.id;
					objCase.Company_ID__c = '' + objHIEventInfo.company.id;
					objCase.Employee_Ids__c = '' + objHIEventInfo.employee.id;
					objCase.Employee_Id__c = '' + objHIEventInfo.employee.id;
					objCase.Hi_Sent_at__c = ObjHiFulfill.Sent_at__c;

					objCase.Termination_Reason__c = ObjHiFulfill.Event_Sub_Type__c;
					objCase.Enrollment_Id__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strEnrollmentId;
					if (objHIEventInfo.losing_benefits_reason == 'employee_continuation_termination') {
						objCase.Enrollment_Key__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strEnrollmentKey + '-' + ObjHiFulfill.Name;
					} else {
						objCase.Enrollment_Key__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strEnrollmentKey;
					}
					objCase.Subscription_End_Date__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).dtTerminationDate;
					objCase.MF_Coverage_Start_Date__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).dtCoverageStartDate;
					objCase.Fulfillment_Event_Encrypted_JSON__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strEncryptedJSON;
					objCase.Selection_Ids__c = map_CaseWrapper.get(ObjHiFulfill.Id__c + '-' + stateCarrier.Key).strSelectionIds;

					if (objContact != null)
						objCase.ContactId = objContact.Id;
					if (map_BenefitOrder.containsKey('' + objHIEventInfo.company.id)) {
						Benefit_Order__c objBenefitOrder = map_BenefitOrder.get('' + objHIEventInfo.company.id);
						objCase.Benefit_Order__c = objBenefitOrder.id;
					}
					if (map_CarrierString.containsKey(stateCarrier.key)) {
						objCase.Carrier__c = map_CarrierString.get(stateCarrier.key).id;
					}

					objCase.Opps_Owner__c = 'member_fulfillment';
					objCase = this.setCaseOwnerAndType(objAccount, objCase, map_BenefitOrder);
					if (objCase != null) {
						list_CasesToInsert.add(objCase);
					}
				}
			}
		}
		return list_CasesToInsert;
	}

	// Method for setting case Owner and Type
	private Case setCaseOwnerAndType(Account objAccount, Case objCase, map<String, Benefit_Order__c> map_BenefitOrder) {
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		Database.DMLOptions dmoNoRule = new Database.DMLOptions();
		dmoNoRule.assignmentRuleHeader.useDefaultRule = false;

		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination');
		objCase.OwnerId = label.Benefit_Care_Cobra_Queue != null ? label.Benefit_Care_Cobra_Queue : objCase.OwnerId;
		objCase.setOptions(dmoNoRule);
		objCase.Status = 'New';
		objCase.Type = 'Continuation Termination'; // New Type for Continuation Termination

		if (map_BenefitOrder.containsKey(objAccount.ZP_Company_ID__c)) {
			objCase.Benefit_Order__c = map_BenefitOrder.get(objAccount.ZP_Company_ID__c).Id;
		}

		return objCase;
	}

	private String getCarrierBotJson(HIFulfillmentContTerminationEventJSON terminationJson, Long lngCarrierId, Blob blobEncryptionKey) {
		HIFulfillmentBotTerminationEventJSON objBotJSON = new HIFulfillmentBotTerminationEventJSON();
		objBotJSON.control_info = new HIFulfillmentBotTerminationEventJSON.control_info();
		objBotJSON.control_info.case_id = '';
		objBotJSON.losing_benefits_date = terminationJson.losing_benefits_date;
		objBotJSON.losing_benefits_reason = terminationJson.losing_benefits_reason;
		objBotJSON.carrier_directory = terminationJson.carrier_directory;
		objBotJSON.employee = (HIFulfillmentBotTerminationEventJSON.cls_employee) System.JSON.deserialize(
			'' + JSON.serialize(terminationJson.employee),
			HIFulfillmentBotTerminationEventJSON.cls_employee.class
		);
		objBotJSON.company = (HIFulfillmentBotTerminationEventJSON.cls_company) System.JSON.deserialize(
			'' + JSON.serialize(terminationJson.company),
			HIFulfillmentBotTerminationEventJSON.cls_company.class
		);
		for (HIFulfillmentContTerminationEventJSON.cls_state_carriers objCarrier : terminationJson.state_carriers) {
			if (objCarrier.id == lngCarrierId) {
				objBotJSON.state_carrier = (HIFulfillmentBotTerminationEventJSON.cls_state_carrier) System.JSON.deserialize(
					'' + JSON.serialize(objCarrier),
					HIFulfillmentBotTerminationEventJSON.cls_state_carrier.class
				);
			}
		}
		objBotJSON.terminated_benefit_items = new List<HIFulfillmentBotTerminationEventJSON.cls_benefit_items>();
		if (terminationJson.subscriptions != null) {
			for (HIFulfillmentContTerminationEventJSON.cls_benefit_items objBenefitItem : terminationJson.subscriptions) {
				if (objBenefitItem.state_carrier_id == lngCarrierId) {
					HIFulfillmentBotTerminationEventJSON.cls_benefit_items objBotBenefitItem = (HIFulfillmentBotTerminationEventJSON.cls_benefit_items) System.JSON.deserialize(
						'' + JSON.serialize(objBenefitItem),
						HIFulfillmentBotTerminationEventJSON.cls_benefit_items.class
					);
					objBotJSON.terminated_benefit_items.add(objBotBenefitItem);
					strSelectionIds += '' + objBenefitItem.Id + ';';
				}
			}
		}
		objBotJSON.policies = new List<HIFulfillmentBotTerminationEventJSON.cls_policies>();
		for (HIFulfillmentContTerminationEventJSON.cls_policies objPolicy : terminationJson.policies) {
			if (objPolicy.state_carrier_id == lngCarrierId) {
				HIFulfillmentBotTerminationEventJSON.cls_policies objNewPolicy = (HIFulfillmentBotTerminationEventJSON.cls_policies) System.JSON.deserialize(
					'' + JSON.serialize(objPolicy),
					HIFulfillmentBotTerminationEventJSON.cls_policies.class
				);
				objBotJSON.policies.add(objNewPolicy);
				if (String.isNotBlank(objNewPolicy.group_number)) {
					strPolicyGroupNumber = objNewPolicy.group_number;
				}
				if (String.isNotBlank(objNewPolicy.policy_number)) {
					strPolicyNumber = objNewPolicy.policy_number;
				}
			}
		}
		if (terminationJson.dependents.size() > 0) {
			objBotJSON.dependents = new List<HIFulfillmentBotTerminationEventJSON.cls_dependents>();
			for (HIFulfillmentContTerminationEventJSON.cls_dependents objDependent : terminationJson.dependents) {
				HIFulfillmentBotTerminationEventJSON.cls_dependents objNewDependent = (HIFulfillmentBotTerminationEventJSON.cls_dependents) System.JSON.deserialize(
					'' + JSON.serialize(objDependent),
					HIFulfillmentBotTerminationEventJSON.cls_dependents.class
				);
				objBotJSON.dependents.add(objNewDependent);
			}
		} else {
			objBotJSON.dependents = new List<HIFulfillmentBotTerminationEventJSON.cls_dependents>();
		}
		objBotJSON.benefits_url = terminationJson.subscriptions_url;
		objBotJSON.dependents_url = terminationJson.dependents_url;

		Blob blobBotEncrypted = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, '' + JSON.serialize(objBotJSON));
		String strBotJSON = EncodingUtil.base64Encode(blobBotEncrypted);
		return strBotJSON;
	}

	@TestVisible
	private existingTrminationCaseWrapper getCaseCaseInfoByEmployeeId(Map<String, DateTime> map_EmployeeIdsWithSentAtTime) {
		existingTrminationCaseWrapper objTermCaseWrapper = new existingTrminationCaseWrapper();
		set<String> set_EmployeeIdCarrierKeys = new Set<String>();
		list<Case> list_Case = new List<Case>();
		for (Case objCase : [
			SELECT id, Employee_id__c, Carrier__c, Enrollment_Key__c, Carrier__r.Key__c, Closed_Reason__c, HI_Sent_at__c, Status
			FROM Case
			WHERE
				Termination_Reason__c != 'Cancel termination'
				AND Type = 'Termination'
				AND Enrollment_Key__c != NULL
				AND Status IN ('Draft', 'New', 'Cancelled')
				AND Carrier__c != NULL
				AND createddate = LAST_N_DAYS:364
				AND Employee_id__c IN :map_EmployeeIdsWithSentAtTime.keySet()
		]) {
			if (
				(objCase.Closed_Reason__c == 'Termination Cancelled' || objCase.Status == 'New' || objCase.Status == 'Draft') &&
				(objCase.HI_Sent_At__c == null ||
				objCase.HI_Sent_At__c <= map_EmployeeIdsWithSentAtTime.get(objCase.Employee_id__c))
			) {
				set_EmployeeIdCarrierKeys.add(objCase.Employee_id__c + '-' + objCase.Enrollment_Key__c);
			}
			if (
				String.isNotBlank(objCase.Employee_id__c) &&
				objCase.Status != 'Cancelled' &&
				(objCase.HI_Sent_At__c == null ||
				objCase.HI_Sent_At__c <= map_EmployeeIdsWithSentAtTime.get(objCase.Employee_id__c))
			) {
				objCase.Status = 'Cancelled';
				objCase.Closed_Reason__c = 'Termination Cancelled';
				list_Case.add(objCase);
			}
		}
		objTermCaseWrapper.set_EmployeeIdCarrierKey = set_EmployeeIdCarrierKeys;
		objTermCaseWrapper.list_Case = list_Case;
		return objTermCaseWrapper;
	}

	public class existingTrminationCaseWrapper {
		public set<String> set_EmployeeIdCarrierKey { get; set; }
		public list<Case> list_Case { get; set; }
	}

	public class caseDataWrapper {
		public String strEventId { get; set; }
		public String strStateCarrierKey { get; set; }
		public String strEventType { get; set; }
		public Long lngZPCompanyId { get; set; }
		public String strEmployeeEmail { get; set; }
		public String strCaseDescription { get; set; }
		public Date dtTerminationDate { get; set; }
		public String strEnrollmentId { get; set; }
		public String strEnrollmentKey { get; set; }
		public HIFulfillmentContTerminationEventJSON objHIEventInfo { get; set; }
		public String strPiiInformation { get; set; }
		public String strEncryptedJSON { get; set; }
		public String strSelectionIds { get; set; }
		public String strGroupNumber { get; set; }
		public String strPolicyNumber { get; set; }
		public Date dtCoverageStartDate { get; set; }
		public Set<String> set_Termination_Policies { get; set; }

		public caseDataWrapper(
			String strEEventId,
			String strCarrierKey,
			String strEventT,
			Long lngCompanyId,
			String strEEmail,
			String strCaseDesc,
			Date dtETerminationDate,
			String strEEnrollmentId,
			String strEEnrollmentKey,
			HIFulfillmentContTerminationEventJSON objHIEventInfoParsed,
			String strPIIInfo,
			String strEncryptedJSONPayload,
			String strSelectionId,
			String strGroupNum,
			String strPolicyNum,
			Date dtCoverageStDate,
			Set<String> set_TermPolicy
		) {
			strEventId = strEEventId;
			strStateCarrierKey = strCarrierKey;
			strEventType = strEventT;
			lngZPCompanyId = lngCompanyId;
			strEmployeeEmail = strEEmail;
			strCaseDescription = strCaseDesc;
			dtTerminationDate = dtETerminationDate;
			strEnrollmentId = strEEnrollmentId;
			strEnrollmentKey = strEEnrollmentKey;
			objHIEventInfo = objHIEventInfoParsed;
			strPiiInformation = strPIIInfo;
			strEncryptedJSON = strEncryptedJSONPayload;
			strSelectionIds = strSelectionId;
			strGroupNumber = strGroupNum;
			strPolicyNumber = strPolicyNum;
			dtCoverageStartDate = dtCoverageStDate;
			set_Termination_Policies = set_TermPolicy;
		}
	}
}