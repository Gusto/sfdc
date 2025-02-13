public without sharing class HIFulfillmentEventEmployeeUpdate {
	Map<String, Integer> map_FulfillmentSubscriptionCount = new Map<String, Integer>();
	Map<String, List<HIFulfillmentEventEmployeeUpdateJSON.cls_forms>> map_StateCarrierIdForm;
	Map<String, Map<String, Object>> map_StateCarrierIdFormMappings;
	Map<String, Case> map_ExistingAllCase = new Map<String, Case>();
	Map<String, String> map_UpdateInfoPerEvent = new Map<String, String>();
	Map<String, Boolean> map_IsFilingStateChangedPerEvent = new Map<String, Boolean>();
	String strSelectionIds = '';
	String strPolicyGroupNumber = '';
	String strPolicyNumber = '';
	String STR_FIRST_NAME = 'first_name';
	String STR_LAST_NAME = 'last_name';
	String STR_HIRED_AT = 'hired_at';
	String STR_HOME_ADDRESS = 'home_address';
	String STR_BIRTH_DAY = 'birthday';
	String STR_SSN = 'ssn';

	public void processInformation(List<HI_Fulfillment_Event__c> list_Fulfillments) {
		Set<String> set_HiFulfillmentIds = new Set<String>();
		List<HI_Fulfillment_Employee_Info__c> list_EmployeeInfo = new List<HI_Fulfillment_Employee_Info__c>();
		Set<String> set_CarrierKeys = new Set<String>();
		Set<String> set_AccountZpIds = new Set<String>();
		Set<String> set_EmployeeEmail = new Set<String>();
		Map<String, HIFulfillmentEventEmployeeUpdateJSON> map_EventIdInfo = new Map<String, HIFulfillmentEventEmployeeUpdateJSON>();
		Map<String, CaseDataWrapper> map_CaseWrapper = new Map<String, CaseDataWrapper>();
		map_FulfillmentSubscriptionCount = new Map<String, Integer>();
		Blob blbEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Map<String, Account> map_Accounts = new Map<String, Account>();

		for (HI_Fulfillment_Event__c objHIFulfill : list_Fulfillments) {
			if (objHIFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			objHIFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfill.Message__c = '';

			if (objHIFulfill.Id__c == null) {
				continue;
			}
			set_HiFulfillmentIds.add(objHIFulfill.Id__c);
		}

		//Loop on HI Fulfillment Event to fetch json related data
		if (set_HiFulfillmentIds.size() > 0) {
			for (HI_Fulfillment_Event__c objHIFulFillment : list_Fulfillments) {
				HIFulfillmentEventEmployeeUpdateJSON objHiEventInfoParsed;

				try {
					Blob blbDecrypted = EncodingUtil.base64Decode(objHIFulFillment.Event_Info_Encrypted__c);
					String strDeCryptedText = EncryptionUtils.getDecryptedText(blbEncryptionKey, blbDecrypted);
					objHiEventInfoParsed = getJSONParsedData(strDeCryptedText);
				} catch (Exception objEx) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulFillment);
					continue;
				}

				set_AccountZpIds.add(String.valueOf(objHiEventInfoParsed.company.id));

				if (String.isNotBlank(objHiEventInfoParsed.sent_at)) {
					objHIFulFillment.Sent_at__c = HIFulfillmentEventHelperFunctions.getDateTimeFromString(objHiEventInfoParsed.sent_at);
					objHIFulFillment.HI_Sent_At_Str__c = objHiEventInfoParsed.sent_at;
				}
			}
			
			map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_AccountZpIds);

			for (HI_Fulfillment_Event__c objHIFulFillment : list_Fulfillments) {
				HIFulfillmentEventEmployeeUpdateJSON objHiEventInfoParsed;
				Map<String, Set<String>> map_CarrierToDependentId = new Map<String, Set<String>>();
				Map<String, List<HIFulfillmentEventEmployeeUpdateJSON.benefit_item>> map_CarrierToSubscriptionList = new Map<String, List<HIFulfillmentEventEmployeeUpdateJSON.benefit_item>>();
				Map<String, HIFulfillmentEventEmployeeUpdateJSON.policy> map_PolicyIds = new Map<String, HIFulfillmentEventEmployeeUpdateJSON.policy>();
				String strEventType = objHIFulFillment.Event_Type__c;
				CaseDataWrapper objCaseWrapper;
				Boolean blnIsStateCarrierError = false;
				String strBenefitsAddress = '';

				if (!set_HiFulfillmentIds.contains(objHIFulFillment.Id__c)) {
					continue;
				}

				try {
					Blob blbDecrypted = EncodingUtil.base64Decode(objHIFulFillment.Event_Info_Encrypted__c);
					String strDeCryptedText = EncryptionUtils.getDecryptedText(blbEncryptionKey, blbDecrypted);
					objHiEventInfoParsed = getJSONParsedData(strDeCryptedText);
				} catch (Exception objEx) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulFillment);
					continue;
				}

				if (objHiEventInfoParsed == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulFillment);
					continue;
				}

				if (objHIFulFillment.Event_Type__c == null || objHIFulFillment.Event_Type__c == '') {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EVENT_TYPE_IS_MISSING, objHIFulFillment);
					continue;
				}

				if (objHiEventInfoParsed.company.id == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING, objHIFulFillment);
					continue;
				}

				if ((objHiEventInfoParsed.State_carriers == null || objHiEventInfoParsed.State_carriers.size() == 0)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.STATE_CARRIER_IS_MISSING, objHIFulFillment);
					continue;
				}

				if (
					(objHiEventInfoParsed.benefit_items == null || objHiEventInfoParsed.benefit_items.size() == 0) && objHIFulFillment.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE
				) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.SUBSCRIPTION_INFO_NOT_EXIST, objHIFulFillment);
					continue;
				}

				if (
					objHIFulFillment.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE &&
					objHiEventInfoParsed.employee != null &&
					String.isNotBlank(objHiEventInfoParsed.employee.email)
				) {
					set_EmployeeEmail.add(objHiEventInfoParsed.employee.email);
				}

				map_EventIdInfo.put(objHIFulFillment.Id__c, objHiEventInfoParsed);

				if (objHiEventInfoParsed.policies != null && objHiEventInfoParsed.policies.size() > 0) {
					for (HIFulfillmentEventEmployeeUpdateJSON.Policy objPolicy : objHiEventInfoParsed.policies) {
						map_PolicyIds.put('' + objPolicy.id, objPolicy);
					}
				}

				map_StateCarrierIdForm = new Map<String, List<HIFulfillmentEventEmployeeUpdateJSON.cls_forms>>(); // key is State CarrierId and value is Form
				map_StateCarrierIdFormMappings = new Map<String, Map<String, Object>>();
				if (objHiEventInfoParsed.forms != null && objHiEventInfoParsed.forms.size() > 0) {
					for (HIFulfillmentEventEmployeeUpdateJSON.cls_forms objForm : objHiEventInfoParsed.forms) {
						List<HIFulfillmentEventEmployeeUpdateJSON.cls_forms> list_Forms;

						String strKey = '' + objForm.state_carrier_id;
						if (map_StateCarrierIdForm.containsKey(strKey)) {
							list_Forms = map_StateCarrierIdForm.get(strKey);
						} else {
							list_Forms = new List<HIFulfillmentEventEmployeeUpdateJSON.cls_forms>();
						}
						list_Forms.add(objForm);
						map_StateCarrierIdForm.put(strKey, list_Forms);
					}
				}

				if (objHiEventInfoParsed.benefit_items != null && objHiEventInfoParsed.benefit_items.size() > 0) {
					map_FulfillmentSubscriptionCount.put(objHIFulFillment.Id__c, objHiEventInfoParsed.benefit_items.size());

					for (HIFulfillmentEventEmployeeUpdateJSON.benefit_item objSubscription : objHiEventInfoParsed.benefit_items) {
						List<HIFulfillmentEventEmployeeUpdateJSON.benefit_item> list_Subscriptions = new List<HIFulfillmentEventEmployeeUpdateJSON.benefit_item>();
						Set<String> set_DependentIds = new Set<String>();

						if (map_CarrierToSubscriptionList.containsKey('' + objSubscription.state_carrier_id)) {
							list_Subscriptions = map_CarrierToSubscriptionList.get('' + objSubscription.state_carrier_id);
						}
						list_Subscriptions.add(objSubscription);
						map_CarrierToSubscriptionList.put('' + objSubscription.state_carrier_id, list_Subscriptions);

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
					map_FulfillmentSubscriptionCount.put(objHIFulFillment.Id__c, 0);
				}

				if (objHiEventInfoParsed.updates.size() > 0) {
					if (objHiEventInfoParsed.updates[0].type == HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER) {
						strEventType = HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER;
					}
					if (objHiEventInfoParsed.updates[0].type == HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS) {
						strEventType = HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS;
					}
				}

				UpdateInformation objUpInformation = getUpdateInformation(objHiEventInfoParsed);

				map_UpdateInfoPerEvent.put(objHIFulFillment.Id__c, objUpInformation.strUpdateInfo);

				map_IsFilingStateChangedPerEvent.put(objHIFulFillment.Id__c, objUpInformation.blnIsFilingStateChanged);

				if (objUpInformation.objEmployeeInfo != null) {
					list_EmployeeInfo.add(objUpInformation.objEmployeeInfo);
				}

				if (strEventType == HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER) {
					String strSubject = '[EE ' + objHiEventInfoParsed.employee.id + '] Two Percent Shareholder status has been updated';
					String strCaseDescription = 'Employee Url : ' + objHiEventInfoParsed.employee.hippo_url;

					strCaseDescription += objUpInformation.strUpdateInfo;
					objCaseWrapper = new CaseDataWrapper(
						objHIFulFillment.Id__c,
						'',
						HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER,
						objHiEventInfoParsed.company.id,
						'',
						strSubject,
						strCaseDescription,
						null,
						objHiEventInfoParsed,
						'',
						'',
						'',
						'',
						''
					);
					map_CaseWrapper.put(objHIFulFillment.id__c, objCaseWrapper);

					continue;
				} else if (strEventType == HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS) {
					String strSubject = '[EE ' + objHiEventInfoParsed.employee.id + '] FLSA status has been updated';
					String strCaseDescription = 'Employee Url : ' + objHiEventInfoParsed.employee.hippo_url;
					strCaseDescription += objUpInformation.strUpdateInfo;
					objCaseWrapper = new CaseDataWrapper(
						objHIFulFillment.Id__c,
						'',
						HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS,
						objHiEventInfoParsed.company.id,
						'',
						strSubject,
						strCaseDescription,
						null,
						objHiEventInfoParsed,
						'',
						'',
						'',
						'',
						''
					);
					map_CaseWrapper.put(objHIFulFillment.id__c, objCaseWrapper);

					continue;
				}

				HIFulfillmentEventEmployeeUpdateJSON.address objCompanyBenefitAddress = objHiEventInfoParsed.company.benefits_address;
				if (objCompanyBenefitAddress != null) {
					strBenefitsAddress = HIFulfillmentEventHelperFunctions.getAddress(
						objCompanyBenefitAddress.street_1,
						objCompanyBenefitAddress.street_2,
						objCompanyBenefitAddress.city,
						objCompanyBenefitAddress.county_name,
						objCompanyBenefitAddress.state,
						objCompanyBenefitAddress.zip,
						objCompanyBenefitAddress.country
					);
				}
				
				if (objHiEventInfoParsed.State_carriers.size() > 0) {
					for (HIFulfillmentEventEmployeeUpdateJSON.state_carrier objStateCarrier : objHiEventInfoParsed.State_carriers) {
						String strCaseDescription = '';
						String strPiiInformation = '';
						set_CarrierKeys.add(objStateCarrier.key);
						strSelectionIds = '';

						if (objStateCarrier.key == null || objStateCarrier.key == '') {
							blnIsStateCarrierError = true;
							HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.STATE_CARRIER_KEY_MISSING, objHIFulFillment);
							continue;
						}
						strPolicyGroupNumber = '';
						strPolicyNumber = '';
						String strBotJson = getCarrierBotJson(objHiEventInfoParsed, objStateCarrier.id, blbEncryptionKey);

						if (strEventType != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE) {
							HIFulfillmentEventEmployeeUpdateJSON.home_address objEmployeeHomeAddress = objHiEventInfoParsed.employee.home_address;

							strCaseDescription +=
								'General Info' +
								'\n- Employee information : Change on ' +
								HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.updated_at) +
								'\n- Subscriptions link: ' +
								objHiEventInfoParsed.benefits_url +
								'\n- Company HIPPO link: ' +
								objHiEventInfoParsed.company.hippo_url;

							strCaseDescription += '\n- EE Panda Link: ' + objHiEventInfoParsed.employee.panda_url;

							strPiiInformation = 'Employee Info:';
							strPiiInformation +=
								'<br/>- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(
									objHiEventInfoParsed.employee.first_name,
									objHiEventInfoParsed.employee.middle_initial,
									objHiEventInfoParsed.employee.last_name
								);
							strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHiEventInfoParsed.employee.ssn);
							strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.employee.birthday);
						} else {
							strCaseDescription +=
								'General Info' +
								'\n- Company information : Change on ' +
								HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.updated_at) +
								'\n- Company HIPPO link: ' +
								objHiEventInfoParsed.company.hippo_url;
							//'\n- Subscriptions link: '+objHiEventInfoParsed.subscriptions_url;
						}
						strCaseDescription += '\n\n- COBRA Activated: ' + objHiEventInfoParsed.company.has_federal_cobra;
						strCaseDescription += objUpInformation.strUpdateInfo + '\n\nCarrier' + '\n- Carrier: ' + objStateCarrier.name + '\n- Carrier State: ' + objStateCarrier.state;

						if (objHIFulFillment.Event_Type__c == HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE) {
							if (String.isNotBlank(strPolicyGroupNumber)) {
								strCaseDescription += '\n- Group Number: ' + strPolicyGroupNumber;
							}

							if (String.isNotBlank(strPolicyNumber)) {
								strCaseDescription += '\n- Policy Number: ' + strPolicyNumber;
							}
						}

						strCaseDescription += '\n\nPlease submit ALL linked forms to the carrier\nForms ' + getForms(objStateCarrier.id);
						strCaseDescription +=
							'\n\nCompany Info' +
							'\n- Company Name: ' +
							objHiEventInfoParsed.company.name +
							'\n- Company Address:' +
							strBenefitsAddress +
							'\n\nPlease review and submit the required documents to the carrier.';

						Date dtUpdatedAt = Date.valueOf(objHiEventInfoParsed.updated_at);
						if (objHIFulFillment.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE) {
							objCaseWrapper = new CaseDataWrapper(
								objHIFulFillment.Id__c,
								objStateCarrier.key,
								objHIFulFillment.Event_Type__c,
								objHiEventInfoParsed.company.id,
								objHiEventInfoParsed.employee.email,
								'',
								strCaseDescription,
								dtUpdatedAt,
								objHiEventInfoParsed,
								strPiiInformation,
								strBotJson,
								strSelectionIds,
								strPolicyGroupNumber,
								strPolicyNumber
							);
						} else {
							objCaseWrapper = new CaseDataWrapper(
								objHIFulFillment.Id__c,
								objStateCarrier.key,
								objHIFulFillment.Event_Type__c,
								objHiEventInfoParsed.company.id,
								'',
								'',
								strCaseDescription,
								dtUpdatedAt,
								objHiEventInfoParsed,
								'',
								strBotJson,
								strSelectionIds,
								strPolicyGroupNumber,
								strPolicyNumber
							);
						}

						map_CaseWrapper.put(objHIFulFillment.id__c + '-' + objStateCarrier.key, objCaseWrapper);
					}
				}
			}
		}

		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);
		Map<String, Carrier__c> map_Carriers = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKeys);

		if (set_EmployeeEmail.size() > 0) {
			map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);

			processContactInformation(list_Fulfillments, map_EventIdInfo, map_Accounts, map_Contacts);

			map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);
		}

		Map<String, Case> map_ExistingCases = new Map<String, Case>();
		if (map_Contacts.keySet().size() > 0) {
			map_ExistingCases = getExistingOpenCaseMap(map_Contacts);
		}

		List<Case> list_CasesToBeUpsert = getCaseInformation(map_CaseWrapper, list_Fulfillments, map_EventIdInfo, map_Accounts, map_Contacts, map_Carriers, map_ExistingCases);
		
		Map<String, String> map_CasesUpsertError = new Map<String, String>();
		if (list_CasesToBeUpsert.size() > 0) {
			List<Database.UpsertResult> list_SaveResults = Database.upsert(list_CasesToBeUpsert, Case.Fields.Integration_Key__c, false);
			map_CasesUpsertError = Utils.processUpsertRecords(list_SaveResults, list_CasesToBeUpsert, 'Integration_Id__c', true, 'HIFulfillmentEventEmployeeUpdate', 'processInformation');
		}

		List<EmailMessage> list_EmailMessages = getCaseEmailMessageInformation(map_CaseWrapper, list_Fulfillments, map_EventIdInfo, map_Accounts, map_Contacts, map_Carriers, map_ExistingCases);
		if (list_EmailMessages.size() > 0) {
			Database.upsert(list_EmailMessages, EmailMessage.Fields.Ticket_Id__c, false);
			List<Case> list_UpdateCases = new List<Case>();
			for (EmailMessage objEmailMsg : list_EmailMessages) {
				Case objCase = map_ExistingAllCase.get('' + objEmailMsg.ParentId);
				objCase.Group_Member_Update_Type__c = objCase.Group_Member_Update_Type__c + getAdditionalUpdateTypes(objCase.Group_Member_Update_Type__c, objEmailMsg.Additional_Info__c);
				objCase.Requires_Action__c = true;
				list_UpdateCases.add(objCase);
			}
			update list_UpdateCases;
		}
		
		if (list_EmployeeInfo.size() > 0) {
			List<Database.UpsertResult> list_EmpInfoSaveResult = Database.upsert(list_EmployeeInfo, HI_Fulfillment_Employee_Info__c.Fields.employee_id__c, false);
		}
		
		createAttachment(list_CasesToBeUpsert, map_CaseWrapper);
		for (HI_Fulfillment_Event__c objHIFulFillment : list_Fulfillments) {
			if (objHIFulFillment.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulFillment.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (map_CasesUpsertError.containsKey(objHIFulFillment.Id__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_CasesUpsertError.get(objHIFulFillment.Id__c), objHIFulFillment);
				continue;
			} else {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIEnrollmentEventUtility.SUCCESS_MESSAGE, objHIFulFillment);
			}
		}
	}

	private String getAdditionalUpdateTypes(String strCaseUpdateTypes, String strNewUpdateTypes) {
		String strUpdateTypes = '';
		if (strCaseUpdateTypes != null && strNewUpdateTypes != null) {
			for (String strTypes : strNewUpdateTypes.split(';')) {
				strTypes = strTypes.trim();
				if (strCaseUpdateTypes.indexOf(strTypes) < 0) {
					strUpdateTypes += ';' + strTypes;
				}
			}
		}

		return strUpdateTypes;
	}

	public static void createAttachment(List<Case> list_CasesToBeUpsert, Map<String, CaseDataWrapper> map_CaseWrapper) {
		List<Attachment> list_Attachment = new List<Attachment>();
		Blob blbEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (Case objCase : list_CasesToBeUpsert) {
			if (objCase.Id != null) {
				if (map_CaseWrapper.containsKey(objCase.Integration_Key__c)) {
					CaseDataWrapper objCaseDataWrapper = map_CaseWrapper.get(objCase.Integration_Key__c);
					if (objCaseDataWrapper.strPiiInformation != null && objCaseDataWrapper.strPiiInformation != '') {
						Attachment objAttachment = new Attachment();
						objAttachment.ParentId = objCase.Id;
						objAttachment.Body = EncryptionUtils.getEncryptedBlob(blbEncryptionKey, objCaseDataWrapper.strPiiInformation);
						objAttachment.Name = 'encFile.txt';
						list_Attachment.add(objAttachment);
					}
				}
			}
		}
		if (list_Attachment.size() > 0) {
			insert list_Attachment;
		}
	}

	private String getCarrierBotJson(HIFulfillmentEventEmployeeUpdateJSON objUpdatedJson, Long lngCarrierId, Blob blbEncryptionKey) {
		HIFulfillmentBotResponseJSON objBotJson = new HIFulfillmentBotResponseJSON();
		objBotJson.control_info = new HIFulfillmentBotResponseJSON.control_info();
		objBotJson.control_info.case_id = '';
		objBotJson.employee = (HIFulfillmentBotResponseJSON.employee) System.JSON.deserialize('' + JSON.serialize(objUpdatedJson.employee), HIFulfillmentBotResponseJSON.employee.class);
		objBotJson.company = (HIFulfillmentBotResponseJSON.company) System.JSON.deserialize('' + JSON.serialize(objUpdatedJson.company), HIFulfillmentBotResponseJSON.company.class);
		for (HIFulfillmentEventEmployeeUpdateJSON.state_carrier objStateCarrier : objUpdatedJson.state_carriers) {
			if (objStateCarrier.id == lngCarrierId) {
				objBotJson.state_carrier = (HIFulfillmentBotResponseJSON.state_carrier) System.JSON.deserialize('' + JSON.serialize(objStateCarrier), HIFulfillmentBotResponseJSON.state_carrier.class);
			}
		}

		String member_level_event_uuids = '';
		if(objUpdatedJson != null && objUpdatedJson.member_level_events != null){
			for (HIFulfillmentEventEmployeeUpdateJSON.member_level_event objMemberLevelEvent : objUpdatedJson.member_level_events) {
				if (objMemberLevelEvent.carrier_id == lngCarrierId) {
					member_level_event_uuids += objMemberLevelEvent.uuid + ',';
				}
			}
		}
		if(String.isNotBlank(member_level_event_uuids)){
			objBotJson.member_level_event_uuids = member_level_event_uuids.substring(0, member_level_event_uuids.length() - 1);
		}

		objBotJson.related_benefit_items = new List<HIFulfillmentBotResponseJSON.related_benefit_items>();
		if (objUpdatedJson.benefit_items != null) {
			for (HIFulfillmentEventEmployeeUpdateJSON.benefit_item objBenefitItem : objUpdatedJson.benefit_items) {
				if (objBenefitItem.state_carrier_id == lngCarrierId) {
					HIFulfillmentBotResponseJSON.related_benefit_items objRelatedBenefitItem = (HIFulfillmentBotResponseJSON.related_benefit_items) System.JSON.deserialize(
						'' + JSON.serialize(objBenefitItem),
						HIFulfillmentBotResponseJSON.related_benefit_items.class
					);
					objBotJson.related_benefit_items.add(objRelatedBenefitItem);
					strSelectionIds += '' + objBenefitItem.Id + ';';
				}
			}
		}
		objBotJson.policies = new List<HIFulfillmentBotResponseJSON.Policy>();
		for (HIFulfillmentEventEmployeeUpdateJSON.Policy objPolicy : objUpdatedJson.policies) {
			if (objPolicy.state_carrier_id == lngCarrierId) {
				HIFulfillmentBotResponseJSON.Policy objNewPolicy = (HIFulfillmentBotResponseJSON.Policy) System.JSON.deserialize(
					'' + JSON.serialize(objPolicy),
					HIFulfillmentBotResponseJSON.Policy.class
				);
				objBotJson.policies.add(objNewPolicy);
				if (String.isNotBlank(objNewPolicy.group_number)) {
					strPolicyGroupNumber = objNewPolicy.group_number;
				}
				if (String.isNotBlank(objNewPolicy.policy_number)) {
					strPolicyNumber = objNewPolicy.policy_number;
				}
			}
		}

		objBotJson.member_updates = new List<HIFulfillmentBotResponseJSON.member_update>();
		for (HIFulfillmentEventEmployeeUpdateJSON.updates objUpdate : objUpdatedJson.updates) {
			HIFulfillmentBotResponseJSON.member_update objMemberUpdate = new HIFulfillmentBotResponseJSON.member_update();
			objMemberUpdate.type = objUpdate.type;
			HIFulfillmentBotResponseJSON.member_update_info objMemberUpdateInfo = (HIFulfillmentBotResponseJSON.member_update_info) System.JSON.deserialize(
				'' + JSON.serialize(objUpdate.current),
				HIFulfillmentBotResponseJSON.member_update_info.class
			);
			
			objMemberUpdate.member_update_info = objMemberUpdateInfo;
			objBotJson.member_updates.add(objMemberUpdate);
		}

		objBotJson.benefits_url = objUpdatedJson.benefits_url;

		Blob blbBotEncrypted = EncryptionUtils.getEncryptedBlob(blbEncryptionKey, '' + JSON.serialize(objBotJson));
		String strBotJson = EncodingUtil.base64Encode(blbBotEncrypted);
		return strBotJson;
	}

	//calling HIFulfillmentEventEmployeeUpdateJSON class for parsing data
	private HIFulfillmentEventEmployeeUpdateJSON getJSONParsedData(String strJson) {
		HIFulfillmentEventEmployeeUpdateJSON objParsedData = (HIFulfillmentEventEmployeeUpdateJSON) JSON.deserialize(strJson, HIFulfillmentEventEmployeeUpdateJSON.class);
		return objParsedData;
	}

	private UpdateInformation getUpdateInformation(HIFulfillmentEventEmployeeUpdateJSON objJsonInfo) {
		List<HIFulfillmentEventEmployeeUpdateJSON.updates> list_UpdateInfo = objJsonInfo.updates;

		UpdateInformation objUpdatedInfo = new UpdateInformation();
		HI_Fulfillment_Employee_Info__c objEmployeeInfo = new HI_Fulfillment_Employee_Info__c();
		Boolean blnIsFilingStateChangedTemp = false;

		String strUpdateInfo = '\n';
		for (HIFulfillmentEventEmployeeUpdateJSON.updates objInfoUpdate : list_UpdateInfo) {
			if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_HOME_ADDRESS) {
				strUpdateInfo += '\n\n/***********Home Address Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_ADDRESS_HEADING;
					strUpdateInfo += getAddressinfo(objInfoUpdate.previous.home_address, null, HIEnrollmentEventUtility.HOME_ADDRESS_HEADING);
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_ADDRESS_HEADING;
					strUpdateInfo += getAddressinfo(objInfoUpdate.current.home_address, objEmployeeInfo, HIEnrollmentEventUtility.HOME_ADDRESS_HEADING);
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_FILING_ADDRESS) {
				strUpdateInfo += '\n\n/***********Filing Address Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_ADDRESS_HEADING;
					strUpdateInfo += getAddressinfo(objInfoUpdate.previous.filing_address, null, HIEnrollmentEventUtility.FILING_ADDRESS_HEADING);
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_ADDRESS_HEADING;
					strUpdateInfo += getAddressinfo(objInfoUpdate.current.filing_address, objEmployeeInfo, HIEnrollmentEventUtility.FILING_ADDRESS_HEADING);
				}

				if (
					objInfoUpdate.previous != null &&
					objInfoUpdate.current != null &&
					objInfoUpdate.previous.filing_address != null &&
					objInfoUpdate.current.filing_address != null &&
					objInfoUpdate.previous.filing_address.state != null &&
					objInfoUpdate.current.filing_address.state != null &&
					objInfoUpdate.previous.filing_address.state != objInfoUpdate.current.filing_address.state
				) {
					blnIsFilingStateChangedTemp = true;
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_MAILING_ADDRESS) {
				strUpdateInfo += '\n\n/***********Mailing Address Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_ADDRESS_HEADING;
					strUpdateInfo += getAddressinfo(objInfoUpdate.previous.mailing_address, null, HIEnrollmentEventUtility.MAILING_ADDRESS_HEADING);
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_ADDRESS_HEADING;
					strUpdateInfo += getAddressinfo(objInfoUpdate.current.mailing_address, objEmployeeInfo, HIEnrollmentEventUtility.MAILING_ADDRESS_HEADING);
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_BANK_ACCOUNT) {
				strUpdateInfo += '\n\n/***********Bank Account Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += getBankinfo(objInfoUpdate.previous.bank_account);
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += getBankinfo(objInfoUpdate.current.bank_account);
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_SSN) {
				strUpdateInfo += '\n\n/***********SSN Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.previous.ssn;
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.current.ssn;
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_FIRST_NAME) {
				strUpdateInfo += '\n\n/***********First Name Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.previous.first_name;
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.current.first_name;
					objEmployeeInfo.first_name__c = objInfoUpdate.current.first_name;
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_LAST_NAME) {
				strUpdateInfo += '\n\n/***********Last Name Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.previous.last_name;
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.current.last_name;
					objEmployeeInfo.last_name__c = objInfoUpdate.current.last_name;
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_BIRTHDAY) {
				strUpdateInfo += '\n\n/***********Birthday Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += HIFulfillmentEventHelperFunctions.getChangeDateFormat(objInfoUpdate.previous.birthday);
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += HIFulfillmentEventHelperFunctions.getChangeDateFormat(objInfoUpdate.current.birthday);
					objEmployeeInfo.birth_date__c = HIFulfillmentEventHelperFunctions.getDateFromString(objInfoUpdate.current.birthday);
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_HIRED_AT) {
				strUpdateInfo += '\n\n/***********Hire Date Update*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += HIFulfillmentEventHelperFunctions.getChangeDateFormat(objInfoUpdate.previous.hired_at);
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += HIFulfillmentEventHelperFunctions.getChangeDateFormat(objInfoUpdate.current.hired_at);
					objEmployeeInfo.Hire_Date__c = HIFulfillmentEventHelperFunctions.getDateFromString(objInfoUpdate.current.hired_at);
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER) {
				strUpdateInfo += '\n\n/***********Two percent shareholder*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.previous.two_percent_shareholder;
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.current.two_percent_shareholder;
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS) {
				strUpdateInfo += '\n\n/***********Flsa Status*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.previous.flsa_status;
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.current.flsa_status;
				}
			} else if (objInfoUpdate.type == HIEnrollmentEventUtility.UPDATE_TYPE_EXTRAPOLATED_ANNUAL_SALARY) {
				strUpdateInfo += '\n\n/*********** SALARY*********/';
				if (objInfoUpdate.previous != null) {
					strUpdateInfo += HIEnrollmentEventUtility.PREVIOUS_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.previous.extrapolated_annual_salary;
				}
				if (objInfoUpdate.current != null) {
					strUpdateInfo += HIEnrollmentEventUtility.CURRENT_INFO_HEADING;
					strUpdateInfo += objInfoUpdate.current.extrapolated_annual_salary;
				}
			}
		}
		if (objJsonInfo.sent_at != null && objJsonInfo.employee != null) {
			objEmployeeInfo.employee_id__c = '' + objJsonInfo.employee.id;
			objEmployeeInfo.Updated_at__c = HIFulfillmentEventHelperFunctions.getDateTimeFromString(objJsonInfo.sent_at);
			objEmployeeInfo.HI_Sent_At__c = objJsonInfo.sent_at;
		} else {
			objEmployeeInfo = null;
		}

		objUpdatedInfo.objEmployeeInfo = objEmployeeInfo;
		objUpdatedInfo.strUpdateInfo = strUpdateInfo;
		objUpdatedInfo.blnIsFilingStateChanged = blnIsFilingStateChangedTemp;
		
		return objUpdatedInfo;
	}

	private String getUpdateTypes(List<HIFulfillmentEventEmployeeUpdateJSON.updates> list_UpdateInfo) {
		String strUpdateTypes = '';
		for (HIFulfillmentEventEmployeeUpdateJSON.updates objUpdates : list_UpdateInfo) {
			if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_HOME_ADDRESS) {
				strUpdateTypes += 'Home Address Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_FILING_ADDRESS) {
				strUpdateTypes += 'Filing Address Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_MAILING_ADDRESS) {
				strUpdateTypes += 'Mailing Address Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_BANK_ACCOUNT) {
				strUpdateTypes += 'Bank Account Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_SSN) {
				strUpdateTypes += 'SSN Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_FIRST_NAME) {
				strUpdateTypes += 'First Name Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_LAST_NAME) {
				strUpdateTypes += 'Last Name Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_BIRTHDAY) {
				strUpdateTypes += 'Birthday Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_HIRED_AT) {
				strUpdateTypes += 'Hire Date Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER) {
				strUpdateTypes += 'Two Percent Shareholder Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS) {
				strUpdateTypes += 'FLSA Status Update;';
			} else if (objUpdates.type == HIEnrollmentEventUtility.UPDATE_TYPE_EXTRAPOLATED_ANNUAL_SALARY) {
				strUpdateTypes += 'Salary Update;';
			}
		}
		return strUpdateTypes;
	}

	private String getBankinfo(HIFulfillmentEventEmployeeUpdateJSON.bank_info objBankInfo) {
		if (objBankInfo == null) {
			return null;
		}
		String strBankInfo = '';
		if (objBankInfo.account_type != null) {
			strBankInfo += '\nAccount Type :: ' + objBankInfo.account_type;
		}
		if (objBankInfo.bank_name != null) {
			strBankInfo += '\nBank Name :: ' + objBankInfo.bank_name;
		}
		if (objBankInfo.account_or_routing_number_changed != null) {
			strBankInfo += '\nAccount/Routing number changed :: ' + objBankInfo.account_or_routing_number_changed;
		}
		if (objBankInfo.bank_account_last_four != null) {
			strBankInfo += '\nBank Account last four :: ' + objBankInfo.bank_account_last_four;
		}
		return strBankInfo;
	}

	private String getAddressinfo(HIFulfillmentEventEmployeeUpdateJSON.address objAddress, HI_Fulfillment_Employee_Info__c objEmployeeInfo, String strAddressType) {
		String strFullAddress = '';
		if (objAddress == null) {
			return strFullAddress;
		}
		if (objEmployeeInfo != null) {
			if (strAddressType == HIEnrollmentEventUtility.HOME_ADDRESS_HEADING) {
				objEmployeeInfo.Home_Street_1__c = objAddress.street_1;
				objEmployeeInfo.Home_Street_2__c = objAddress.street_2;
				objEmployeeInfo.Home_City__c = objAddress.city;
				objEmployeeInfo.Home_State__c = objAddress.state;
				objEmployeeInfo.Home_County__c = objAddress.county_name;
				objEmployeeInfo.Home_Country__c = objAddress.country;
				objEmployeeInfo.Home_zip__c = objAddress.zip;
			} else if (strAddressType == HIEnrollmentEventUtility.MAILING_ADDRESS_HEADING) {
				objEmployeeInfo.Mailing_Street_1__c = objAddress.street_1;
				objEmployeeInfo.Mailing_Street_2__c = objAddress.street_2;
				objEmployeeInfo.Mailing_City__c = objAddress.city;
				objEmployeeInfo.Mailing_State__c = objAddress.state;
				objEmployeeInfo.Mailing_County__c = objAddress.county_name;
				objEmployeeInfo.Mailing_Country__c = objAddress.country;
				objEmployeeInfo.Mailing_zip__c = objAddress.zip;
			} else if (strAddressType == HIEnrollmentEventUtility.FILING_ADDRESS_HEADING) {
				objEmployeeInfo.Filing_Street_1__c = objAddress.street_1;
				objEmployeeInfo.Filing_Street_2__c = objAddress.street_2;
				objEmployeeInfo.Filing_City__c = objAddress.city;
				objEmployeeInfo.Filing_State__c = objAddress.state;
				objEmployeeInfo.Filing_County__c = objAddress.county_name;
				objEmployeeInfo.Filing_Country__c = objAddress.country;
				objEmployeeInfo.Filing_zip__c = objAddress.zip;
			}
		}
		if (objAddress.street_1 != null) {
			strFullAddress += '\n' + objAddress.street_1;
		}
		if (objAddress.street_2 != null) {
			strFullAddress += ', ' + objAddress.street_2;
		}
		if (objAddress.city != null) {
			strFullAddress += '\n' + objAddress.city;
		}
		if (objAddress.county_name != null) {
			strFullAddress += ', ' + objAddress.county_name;
		}
		if (objAddress.state != null) {
			strFullAddress += ', ' + objAddress.state;
		}
		if (objAddress.country != null) {
			strFullAddress += ', ' + objAddress.country;
		}
		if (objAddress.zip != null) {
			strFullAddress += ' ' + objAddress.zip;
		}
		return strFullAddress;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> list_Fulfillments,
		Map<String, HIFulfillmentEventEmployeeUpdateJSON> map_EventIdInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts
	) {
		List<Contact> list_ContactsToBeInserted = new List<Contact>();
		for (HI_Fulfillment_Event__c objHIFulFillment : list_Fulfillments) {
			if (objHIFulFillment.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulFillment.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEventEmployeeUpdateJSON objEmployeeUpdateJson = map_EventIdInfo.get(objHIFulFillment.Id__c);
			if (!map_Accounts.containsKey('' + objEmployeeUpdateJson.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objHIFulFillment);
				continue;
			}

			if (!map_Contacts.containsKey(objEmployeeUpdateJson.employee.company_id + '-' + objEmployeeUpdateJson.employee.email) && !map_Contacts.containsKey(objEmployeeUpdateJson.employee.email)) {
				Contact objContact = new Contact();
				objContact.AccountId = map_Accounts.get('' + objEmployeeUpdateJson.employee.company_id).Id;
				objContact.FirstName = objEmployeeUpdateJson.employee.first_Name;
				objContact.LastName = objEmployeeUpdateJson.employee.last_name;
				objContact.Email = objEmployeeUpdateJson.employee.email;
				objContact.RecordTypeId = HIEnrollmentEventUtility.CONTACT_COMPANY_RT_ID;
				list_ContactsToBeInserted.add(objContact);
			}
		}
		if (list_ContactsToBeInserted.size() > 0) {
			Map<String, String> map_ContactInsertErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = Database.insert(list_ContactsToBeInserted, false);
			map_ContactInsertErrors = Utils.processSaveRecords(list_SaveResults, list_ContactsToBeInserted, 'email', true, 'HIFulfillmentEventEmployeeUpdate', 'processContactInformation');
			for (HI_Fulfillment_Event__c objHIFulFillment : list_Fulfillments) {
				HIFulfillmentEventEmployeeUpdateJSON objHIEventInfo = map_EventIdInfo.get(objHIFulFillment.Id__c);
				if (map_ContactInsertErrors.containsKey(objHIEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_ContactInsertErrors.get(objHIEventInfo.employee.email), objHIFulFillment);
					continue;
				}
			}
		}
	}

	private Map<String, Case> getExistingOpenCaseMap(Map<String, Contact> map_Contacts) {
		Map<String, Case> map_ExistingCases = new Map<String, Case>();
		Set<Id> set_ContactIds = new Set<Id>();
		for (Contact objContact : map_Contacts.values()) {
			set_ContactIds.add(objContact.Id);
		}
		
		for (Case objCase : [
			SELECT Id, Description, RecordType.Name, RecordTypeId, Carrier__c, ContactId, Enrollment_Id__c, Integration_key__c, Group_Member_Update_Type__c, Integration_Id__c, Fulfillment_Event_Encrypted_JSON__c
			FROM Case
			WHERE
				isClosed = FALSE
				AND ContactId IN :set_ContactIds
				AND ContactId != NULL
				AND Carrier__c != NULL
				AND RecordType.name IN :HIEnrollmentEventUtility.set_ValidCaseRecTypesForEmpUpdates
				AND status IN :HIEnrollmentEventUtility.set_UnsubmittedCaseStatusesForEmpUpdates
		]) {
			map_ExistingCases.put(objCase.contactid + '-' + objCase.carrier__c, objCase);
			map_ExistingCases.put(objCase.Integration_key__c, objCase);
			map_ExistingAllCase.put(objCase.Id, objCase);
		}
		
		return map_ExistingCases;
	}

	private List<Case> getCaseInformation(
		Map<String, CaseDataWrapper> map_CaseWrapper,
		List<HI_Fulfillment_Event__c> list_Fulfillments,
		Map<String, HIFulfillmentEventEmployeeUpdateJSON> map_EventIdInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Map<String, Carrier__c> map_Carriers,
		Map<String, Case> map_ExistingCases
	) {
		List<Case> list_CaseInserted = new List<Case>();
		for (HI_Fulfillment_Event__c objHIFulFillment : list_Fulfillments) {
			if (objHIFulFillment.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulFillment.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentEventEmployeeUpdateJSON objHIEventInfo = map_EventIdInfo.get(objHIFulFillment.Id__c);
			if (!map_Accounts.containsKey('' + objHIEventInfo.company.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objHIFulFillment);
				continue;
			}
			Account objAccount = map_Accounts.get('' + objHIEventInfo.company.id);
			Contact objContact;
			if (objHIFulFillment.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE) {
				if (map_Contacts.containsKey(objHIFulFillment.Id__c + '-' + objHIEventInfo.employee.email)) {
					objContact = map_Contacts.get(objHIFulFillment.Id__c + '-' + objHIEventInfo.employee.email);
				} else if (map_Contacts.containsKey(objHIEventInfo.employee.email)) {
					objContact = map_Contacts.get(objHIEventInfo.employee.email);
				}
			}
			String strUpdateTypes = getUpdateTypes(objHIEventInfo.updates);

			Database.DMLOptions objDmlOption = new Database.DMLOptions();
			objDmlOption.assignmentRuleHeader.useDefaultRule = true;
			String strEventType = objHIFulFillment.Event_Type__c;
			if (objHIEventInfo.updates.size() > 0) {
				if (
					objHIEventInfo.updates[0].type == HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER ||
					objHIEventInfo.updates[0].type == HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS
				) {
					strEventType = HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER;
					Case objCase = new Case();
					objCase.setOptions(objDmlOption);
					objCase.Integration_Id__c = objHIFulFillment.Id__c;
					objCase.Integration_Key__c = objHIFulFillment.Id__c;
					objCase.Description = map_CaseWrapper.get(objHIFulFillment.Id__c).strCaseDescription;
					objCase.Subject = map_CaseWrapper.get(objHIFulFillment.Id__c).strCaseSubject;
					objCase.AccountId = objAccount.id;
					objCase.MF_Group_Number__c = map_CaseWrapper.get(objHIFulFillment.Id__c).strGroupNumber;
					objCase.MF_Policy_Number__c = map_CaseWrapper.get(objHIFulFillment.Id__c).strPolicyNumber;
					objCase.HI_Integration_Error_Message__c = objHIEventInfo.error_message;

					if (objContact != null) {
						objCase.ContactId = objContact.Id;
					}

					objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_BENEFITS_CARE;
					if (objHIEventInfo.updates[0].type == HIEnrollmentEventUtility.UPDATE_TYPE_TWO_PERCENT_SHAREHOLDER) {
						objCase.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
						objCase.Type = CaseUtils.BENEFITS_CASE_PILLAR;
						objCase.Support_Level__c = CaseUtils.TIER_2;
					} else if (objHIEventInfo.updates[0].type == HIEnrollmentEventUtility.UPDATE_TYPE_FLSA_STATUS) {
						objCase.Type = 'Owner Status audit';
					}
					list_CaseInserted.add(objCase);
					continue;
				}
			}

			if (objHIEventInfo.State_carriers.size() > 0) {
				for (HIFulfillmentEventEmployeeUpdateJSON.state_carrier objStateCarrier : objHIEventInfo.State_carriers) {
					Case objCase = new Case();
					objCase.setOptions(objDmlOption);
					objCase.Integration_Id__c = objHIFulFillment.Id__c;
					objCase.Integration_Key__c = objHIFulFillment.Id__c + '-' + objStateCarrier.Key;
					objCase.Description = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key).strCaseDescription;
					objCase.MF_Group_Number__c = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key).strGroupNumber;
					objCase.MF_Policy_Number__c = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key).strPolicyNumber;
					objCase.AccountId = objAccount.id;
					objCase.HI_Integration_Error_Message__c = objHIEventInfo.error_message;

					if (objHIEventInfo.updated_at != null && objHIEventInfo.updated_at != '') {
						objCase.Anticipated_Effective_Date__c = Date.valueOf(objHIEventInfo.updated_at);
					}
					if (objContact != null) {
						objCase.ContactId = objContact.Id;
					}
					if (map_Carriers.containsKey(objStateCarrier.key)) {
						objCase.Carrier__c = map_Carriers.get(objStateCarrier.key).id;
					}
					objCase.Fulfillment_Event_Encrypted_JSON__c = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key).strEncryptedJson;
					objCase.Selection_Ids__c = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key).strSelectionIds;

					objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_MEMBER_GROUP_UPDATES;
					if (strUpdateTypes != null) {
						if (strUpdateTypes.indexOf('Hire Date Update') > -1) {
							objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE;
						}
					}
					if (objStateCarrier.byb_automation_authorized == true) {
						objCase.BYB_Automation_Authorized__c = objStateCarrier.byb_automation_authorized;
					}			
					if (objHIFulFillment.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE) {
						objCase.Type = 'Member Updates';
						objCase.Fulfillment_Type__c = 'Member Update';
						objCase.Employee_Ids__c = '' + objHIEventInfo.employee.id;
						objCase.Employee_Id__c = '' + objHIEventInfo.employee.id;

						if (
							objCase.ContactId != null &&
							objCase.carrier__c != null &&
							map_ExistingCases.containsKey(objCase.ContactId + '-' + objCase.carrier__c) &&
							!map_ExistingCases.containsKey(objCase.Integration_key__c)
						) {
							if (objHIFulFillment.Event_Type__c == 'employee_update') {
								objCase = map_ExistingCases.get(objCase.ContactId + '-' + objCase.carrier__c);
								String strUpdateEncryptedJSON = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key).strEncryptedJson;
								objCase.Fulfillment_Event_Encrypted_JSON__c = updateBOTJSON(objCase.Fulfillment_Event_Encrypted_JSON__c, strUpdateEncryptedJSON);
								if (objStateCarrier.byb_automation_authorized == true) {
									objCase.BYB_Automation_Authorized__c = objStateCarrier.byb_automation_authorized;
								}
								String payloadDescription = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key)?.strCaseDescription;
								if(map_CaseWrapper.containsKey(objHIFulFillment.Id__c + '-' + objStateCarrier.Key) && String.isNotBlank(payloadDescription) && objCase.Description != payloadDescription) {
									objCase.Description = payloadDescription;
								}
								list_CaseInserted.add(objCase);
							}

							continue;
						}
					} else {
						objCase.Type = 'Group Updates';
						objCase.Fulfillment_Type__c = 'Group Update';
					}
					objCase.Group_Member_Update_Type__c = strUpdateTypes;
					objCase.Group_Member_Update_Type_Text__c = strUpdateTypes.replaceAll(';', ',').removeEnd(',');

					if (map_StateCarrierIdFormMappings != null && map_StateCarrierIdFormMappings.containsKey('' + objStateCarrier.id)) {
						Map<String, Object> map_FormMapping = map_StateCarrierIdFormMappings.get('' + objStateCarrier.id);
						if (map_FormMapping != null) {
							if (map_FormMapping.containsKey('fullymapped')) {
								objCase.Form_Fully_Mapped__c = (Boolean) map_FormMapping.get('fullymapped');
							}
							if (map_FormMapping.containsKey('missingattributes')) {
								objCase.Missing_Form_Attributes__c = (String) map_FormMapping.get('missingattributes');
							}
							if (map_FormMapping.containsKey('fitsdependents')) {
								objCase.Form_Fits_Dependents__c = (Boolean) map_FormMapping.get('fitsdependents');
							}
						}
					}
					if (map_StateCarrierIdForm != null && map_StateCarrierIdForm.containsKey('' + objStateCarrier.id) && map_StateCarrierIdForm.get('' + objStateCarrier.id) != null) {
						objCase.Number_of_Forms__c = map_StateCarrierIdForm.get('' + objStateCarrier.id).size();
					} else {
						objCase.Number_of_Forms__c = 0;
					}
					if (map_UpdateInfoPerEvent != null && map_UpdateInfoPerEvent.containsKey(objHIFulFillment.Id__c)) {
						objCase.Update_Information__c = map_UpdateInfoPerEvent.get(objHIFulFillment.Id__c);
					}
					if (map_IsFilingStateChangedPerEvent != null && map_IsFilingStateChangedPerEvent.containsKey(objHIFulFillment.Id__c)) {
						objCase.Filing_State_Change__c = map_IsFilingStateChangedPerEvent.get(objHIFulFillment.Id__c);
					}
					list_CaseInserted.add(objCase);
				}
			}
		}
		return list_CaseInserted;
	}

	private List<EmailMessage> getCaseEmailMessageInformation(
		Map<String, CaseDataWrapper> map_CaseWrapper,
		List<HI_Fulfillment_Event__c> list_Fulfillments,
		Map<String, HIFulfillmentEventEmployeeUpdateJSON> map_EventIdInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Map<String, Carrier__c> map_Carriers,
		Map<String, Case> map_ExistingCases
	) {
		List<EmailMessage> list_EmailMessages = new List<EmailMessage>();
		for (HI_Fulfillment_Event__c objHIFulFillment : list_Fulfillments) {
			if (objHIFulFillment.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulFillment.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentEventEmployeeUpdateJSON objHIEventInfo = map_EventIdInfo.get(objHIFulFillment.Id__c);
			if (!map_Accounts.containsKey('' + objHIEventInfo.company.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objHIFulFillment);
				continue;
			}
			Account objAccount = map_Accounts.get('' + objHIEventInfo.company.id);
			Contact objContact;
			if (objHIFulFillment.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE) {
				if (map_Contacts.containsKey(objHIFulFillment.Id__c + '-' + objHIEventInfo.employee.email)) {
					objContact = map_Contacts.get(objHIFulFillment.Id__c + '-' + objHIEventInfo.employee.email);
				} else if (map_Contacts.containsKey(objHIEventInfo.employee.email)) {
					objContact = map_Contacts.get(objHIEventInfo.employee.email);
				}
			}

			String strUpdateTypes = getUpdateTypes(objHIEventInfo.updates);

			if (objHIEventInfo.State_carriers.size() > 0) {
				for (HIFulfillmentEventEmployeeUpdateJSON.state_carrier objStateCarrier : objHIEventInfo.State_carriers) {
					String strContactId = '';
					if (objContact != null) {
						strContactId = objContact.Id;
					}
					String strCarrierId = '';
					if (map_Carriers.containsKey(objStateCarrier.key)) {
						strCarrierId = map_Carriers.get(objStateCarrier.key).id;
					}

					if (objHIFulFillment.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE) {
						if (strContactId != null && strCarrierId != null && map_ExistingCases.containsKey(strContactId + '-' + strCarrierId)) {
							Case objCase = map_ExistingCases.get(strContactId + '-' + strCarrierId);
							EmailMessage objEmailMsg = new EmailMessage();
							objEmailMsg.ParentId = map_ExistingCases.get(strContactId + '-' + strCarrierId).id;
							objEmailMsg.Subject = 'Member update information for the case';
							objEmailMsg.TextBody = map_CaseWrapper.get(objHIFulFillment.Id__c + '-' + objStateCarrier.Key).strCaseDescription;
							objEmailMsg.Ticket_Id__c = objHIFulFillment.Id__c + '-' + objStateCarrier.Key;
							objEmailMsg.Additional_Info__c = strUpdateTypes;
							list_EmailMessages.add(objEmailMsg);
						}
					}
				}
			}
		}
		return list_EmailMessages;
	}

	//Get forms information
	private String getForms(Long lngStateCarrierId) {
		String strFormsInfo = '';
		if (map_StateCarrierIdForm == null || !map_StateCarrierIdForm.containsKey('' + lngStateCarrierId)) {
			strFormsInfo = ' not available';
		} else {
			String strMissingFormAttributes = '';
			Boolean blnFullyMapped = true, blnFitsDependents = true;
			Set<String> set_MissingAttributes = new Set<String>();
			for (HIFulfillmentEventEmployeeUpdateJSON.cls_forms objClsForm : map_StateCarrierIdForm.get('' + lngStateCarrierId)) {
				strFormsInfo += '\n- ' + objClsForm.url;

				//Check for form flags, if any of the forms has fully_mapped set to false, it is set as false at case level
				if (blnFullyMapped && (objClsForm.fully_mapped == false || objClsForm.fully_mapped == null)) {
					blnFullyMapped = false;
				}
				//Check for form flags, if any of the forms has fits dependents set to false, it is set as false at case level
				if (blnFitsDependents && (objClsForm.form_includes_all_dependents == false || objClsForm.form_includes_all_dependents == null)) {
					blnFitsDependents = false;
				}
				//Get all missing values in forms and store them at case level in comma separated format
				if (objClsForm.missing_values_by_path != null && !objClsForm.missing_values_by_path.isEmpty()) {
					set_MissingAttributes.addAll(objClsForm.missing_values_by_path);
				}
			}
			if (!set_MissingAttributes.isEmpty()) {
				List<String> list_MissingFormAttr = new List<String>(set_MissingAttributes);
				strMissingFormAttributes = String.join(list_MissingFormAttr, ',\n');
			}
			Map<String, Object> map_formMapping = new Map<String, Object>();
			map_formMapping.put('fullymapped', blnFullyMapped);
			map_formMapping.put('missingattributes', strMissingFormAttributes);
			map_formMapping.put('fitsdependents', blnFitsDependents);
			map_StateCarrierIdFormMappings.put('' + lngStateCarrierId, map_formMapping);
		}
		return strFormsInfo;
	}

	/*
		Author      : Bhagat Singh
		Date        : 13 June 2022
		Description : Update member_updates tags in BOT JSON.
		@Parm       : Existing Encrypted BOT JSON 
					: New Encrypted BOT JSON 
		@Return     : N/A
    */
	public String updateBOTJSON(String strExistingEncryptedJSON, String strNewJSON) {
		String strFinalBOTJSON = '';
		if (String.isBlank(strExistingEncryptedJSON)) {
			strFinalBOTJSON = strNewJSON;
		} else if (String.isBlank(strNewJSON)) {
			strFinalBOTJSON = strExistingEncryptedJSON;
		} else {
			Blob blbEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
			String strDeCryptedText = '';
			Blob blbDecryptedBlob = EncodingUtil.base64Decode(strExistingEncryptedJSON);
			strDeCryptedText = EncryptionUtils.getDecryptedText(blbEncryptionKey, blbDecryptedBlob);
			HIFulfillmentBotResponseJSON objExisitngCaseBOT = (HIFulfillmentBotResponseJSON) JSON.deserialize(strDeCryptedText, HIFulfillmentBotResponseJSON.class);

			blbDecryptedBlob = EncodingUtil.base64Decode(strNewJSON);
			strDeCryptedText = EncryptionUtils.getDecryptedText(blbEncryptionKey, blbDecryptedBlob);
			HIFulfillmentBotResponseJSON objNewCaseBOT = (HIFulfillmentBotResponseJSON) JSON.deserialize(strDeCryptedText, HIFulfillmentBotResponseJSON.class);

			if (objExisitngCaseBOT != null && objNewCaseBOT != null) {
				for (HIFulfillmentBotResponseJSON.member_update objNewInfo : objNewCaseBOT.member_updates) {
					if (String.isNotBlank(objNewInfo.type)) {
						if (STR_FIRST_NAME == objNewInfo.type) {
							objExisitngCaseBOT.employee.first_name = objNewInfo.member_update_info.first_name;
						} else if (STR_LAST_NAME == objNewInfo.type) {
							objExisitngCaseBOT.employee.last_name = objNewInfo.member_update_info.last_name;
						} else if (STR_HIRED_AT == objNewInfo.type) {
							objExisitngCaseBOT.employee.hired_at = objNewInfo.member_update_info.hired_at;
						} else if (STR_HOME_ADDRESS == objNewInfo.type) {
							HIFulfillmentBotResponseJSON.work_address objAddress = objNewInfo.member_update_info.home_address;
							String strAddressJSON = JSON.serialize(objAddress);
							HIFulfillmentBotResponseJSON.home_address objHomeAddress = (HIFulfillmentBotResponseJSON.home_address) JSON.deserialize(
								strAddressJSON,
								HIFulfillmentBotResponseJSON.home_address.class
							);
							objExisitngCaseBOT.employee.home_address = objHomeAddress;
						} else if (STR_BIRTH_DAY == objNewInfo.type) {
							objExisitngCaseBOT.employee.birthday = objNewInfo.member_update_info.birthday;
						} else if (STR_SSN == objNewInfo.type) {
							objExisitngCaseBOT.employee.ssn = objNewInfo.member_update_info.ssn;
						}
					}
				}
				Set<String> set_ExistingMLEUUIDs = new Set<String>();
				if (String.isNotBlank(objExisitngCaseBOT.member_level_event_uuids) && String.isNotBlank(objNewCaseBOT.member_level_event_uuids)) {
					set_ExistingMLEUUIDs.addAll(objExisitngCaseBOT.member_level_event_uuids.split(','));
					List<String> list_newMLEUUIDs = objNewCaseBOT.member_level_event_uuids.split(',');
					for (String steMLEUUID : list_newMLEUUIDs) {
						if (!set_ExistingMLEUUIDs.contains(steMLEUUID)) {
							set_ExistingMLEUUIDs.add(steMLEUUID);
						}
					}
					objExisitngCaseBOT.member_level_event_uuids = String.join(new List<String>(set_ExistingMLEUUIDs), ',');
				} else if (String.isNotBlank(objNewCaseBOT.member_level_event_uuids)) {
					objExisitngCaseBOT.member_level_event_uuids = objNewCaseBOT.member_level_event_uuids;
				}
			}

			Blob blbBotEncrypted = EncryptionUtils.getEncryptedBlob(blbEncryptionKey, '' + JSON.serialize(objExisitngCaseBOT));
			strFinalBOTJSON = EncodingUtil.base64Encode(blbBotEncrypted);
		}

		return strFinalBOTJSON;
	}

	public class UpdateInformation {
		public String strUpdateInfo { get; set; }
		public HI_Fulfillment_Employee_Info__c objEmployeeInfo { get; set; }
		public Boolean blnIsFilingStateChanged { get; set; }
	}

	public class CaseDataWrapper {
		public String strEventId { get; set; }
		public String strStateCarrierKey { get; set; }
		public String strEventType { get; set; }
		public Long lngZpCompanyId { get; set; }
		public String strEmployeeEmail { get; set; }
		public String strCaseSubject { get; set; }
		public String strCaseDescription { get; set; }
		public Date dtEffectiveDate { get; set; }
		public HIFulfillmentEventEmployeeUpdateJSON objHIEventInfo { get; set; }
		public String strPiiInformation { get; set; }
		public String strEncryptedJson { get; set; }
		public String strSelectionIds { get; set; }
		public String strGroupNumber { get; set; }
		public String strPolicyNumber { get; set; }

		public CaseDataWrapper(
			String strEventIdTemp,
			String strStateCarrierKeyTemp,
			String strEventTypeTemp,
			Long lngZpCompanyIdTemp,
			String strEmployeeEmailTemp,
			String strCaseSubjectTemp,
			String strCaseDescriptionTemp,
			Date dtEffectiveDateTemp,
			HIFulfillmentEventEmployeeUpdateJSON objHiEventInfoParsed,
			String strPiiInformationTemp,
			String strEncryptedJsonTemp,
			String strSelectionIdsTemp,
			String strGroupNumberTemp,
			String strPolicyNumberTemp
		) {
			strEventId = strEventIdTemp;
			strStateCarrierKey = strStateCarrierKeyTemp;
			strEventType = strEventTypeTemp;
			lngZpCompanyId = lngZpCompanyIdTemp;
			strEmployeeEmail = strEmployeeEmailTemp;
			strCaseSubject = strCaseSubjectTemp;
			strCaseDescription = strCaseDescriptionTemp;
			dtEffectiveDate = dtEffectiveDateTemp;
			objHIEventInfo = objHiEventInfoParsed;
			strPiiInformation = strPiiInformationTemp;
			strEncryptedJson = strEncryptedJsonTemp;
			strSelectionIds = strSelectionIdsTemp;
			strGroupNumber = strGroupNumberTemp;
			strPolicyNumber = strPolicyNumberTemp;
		}
	}
}