public with sharing class HIFulfillmentEventAudit {
	public static Map<String, MF_Audit_Descriptions__mdt> map_MFAuditDescriptions = HIEnrollmentEventUtility.getMFAuditDescrptions();
	public static Set<String> set_ClosedCaseStatus = new Set<String>{ CaseUtils.STATUS_CLOSED };
	public static String strSpecialInstructions = System.Label.SpecialInstructions_MOps_Audit_Case;
	public static String strReconciliationSpecialInstructions = System.Label.SpecialInstructions_reconciliation_MOps_Audit_Case;
	public static final Set<Id> set_ValidCaseRecTypeIds = new Set<Id>();
	public static final Set<Id> set_MFTerminationRecTypeIds = new Set<Id>();
	public static final String strNullCheck = 'null';
	public static final String TODAYDATE = 'TODAYDATE';

	public void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents) {
		Set<String> set_HIFulfillmentIds = new Set<String>();
		List<Case> list_Cases = new List<Case>();
		Set<String> set_CarrierIds = new Set<String>();
		Set<String> set_ZPAccountIds = new Set<String>();
		Set<String> set_EmployeeSearchKey = new Set<String>();
		Map<String, HIFulfillmentEventAuditJSON> map_EventIdsToInfo = new Map<String, HIFulfillmentEventAuditJSON>();
		Map<String, CaseDataWrapper> map_EventIdsToCaseWrapper = new Map<String, CaseDataWrapper>();
		Map<String, Benefit_Order__c> map_BenefitOrders = new Map<String, Benefit_Order__c>();
		Map<String, Carrier_Order__c> map_CarrierOrders = new Map<String, Carrier_Order__c>();
		List<Contact> list_Contacts = new List<Contact>();

		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');

		for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
			if (objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			objHIFulfillmentEvent.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfillmentEvent.Message__c = '';

			if (objHIFulfillmentEvent.Id__c == null) {
				continue;
			}

			set_HIFulfillmentIds.add(objHIFulfillmentEvent.Id__c);
		}

		Map<String, Account> map_Accounts = new Map<String, Account>();
		Map<String, Carrier__c> map_Carriers;

		if (!set_HIFulfillmentIds?.isEmpty()) {
			for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
				HIFulfillmentEventAuditJSON objHIEventInfoParsed;

				try {
					Blob blobDecryptedInfo = EncodingUtil.base64Decode(objHIFulfillmentEvent.Event_Info_Encrypted__c);
					String strDecryptedText = EncryptionUtils.getDecryptedText(blobEncryptionKey, blobDecryptedInfo);
					objHIEventInfoParsed = getJSONParsedData(strDecryptedText);
				} catch (Exception objEx) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulfillmentEvent);
					continue;
				}

				if (objHIEventInfoParsed.items != null && objHIEventInfoParsed.items.size() > 0) {
					for (HIFulfillmentEventAuditJSON.item objItem : objHIEventInfoParsed.items) {
						if (objItem.state_carrier_id != null) {
							set_CarrierIds.add('' + objItem.state_carrier_id);
						}
					}
				}

				if (objHIEventInfoParsed.policies != null && objHIEventInfoParsed.policies.size() > 0) {
					for (HIFulfillmentEventAuditJSON.policies objPolicy : objHIEventInfoParsed.policies) {
						if (objPolicy.state_carrier_id != null) {
							set_CarrierIds.add('' + objPolicy.state_carrier_id);
						}
					}
				}

				if (objHIEventInfoParsed.state_carriers != null && objHIEventInfoParsed.state_carriers.size() > 0) {
					for (HIFulfillmentEventAuditJSON.state_carriers objCarrier : objHIEventInfoParsed.state_carriers) {
						if (objCarrier.id != null) {
							set_CarrierIds.add('' + objCarrier.id);
						}
					}
				}

				if (objHIEventInfoParsed?.employee?.email != null) {
					set_EmployeeSearchKey.add(objHIEventInfoParsed.employee.email);
				}

				if (objHIEventInfoParsed?.employee?.id != null) {
					set_EmployeeSearchKey.add(objHIEventInfoParsed.employee.id + '');
				}

				set_ZPAccountIds.add(String.valueOf(objHIEventInfoParsed.company.id));
			}

			map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_ZPAccountIds);
			map_Carriers = HIFulfillmentEventHelperFunctions.getCarrierInfoById(set_CarrierIds);
			//Parsing events
			for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
				if (!set_HIFulfillmentIds.contains(objHIFulfillmentEvent.Id__c)) {
					continue;
				}

				HIFulfillmentEventAuditJSON objHIEventInfoParsed;

				try {
					Blob blobDecryptedInfo = EncodingUtil.base64Decode(objHIFulfillmentEvent.Event_Info_Encrypted__c);
					String strDecryptedText = EncryptionUtils.getDecryptedText(blobEncryptionKey, blobDecryptedInfo);
					objHIEventInfoParsed = getJSONParsedData(strDecryptedText);
				} catch (Exception objEx) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulfillmentEvent);
					continue;
				}

				if (objHIEventInfoParsed == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objHIFulfillmentEvent);
					continue;
				}

				if (objHIFulfillmentEvent.Event_Type__c == null || objHIFulfillmentEvent.Event_Type__c == '') {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EVENT_TYPE_IS_MISSING, objHIFulfillmentEvent);
					continue;
				}

				if (objHIEventInfoParsed.company.id == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING, objHIFulfillmentEvent);
					continue;
				}

				if (String.isBlank(objHIFulfillmentEvent.Application_Id__c) && objHIEventInfoParsed.policies != null && !objHIEventInfoParsed.policies.isEmpty()) {
					if (objHIEventInfoParsed.policies[0].application_id != null) {
						objHIFulfillmentEvent.Application_Id__c = objHIEventInfoParsed.policies[0].application_id + '';
					}
				}

				if(String.isNotBlank(objHIEventInfoParsed.audit_type)) {
					objHIFulfillmentEvent.Event_Sub_Type__c = objHIEventInfoParsed.audit_type;
				}

				map_EventIdsToInfo.put(objHIFulfillmentEvent.Id__c, objHIEventInfoParsed);
				map_BenefitOrders = HIFulfillmentEventHelperFunctions.getBenefitOrderMap(set_ZPAccountIds);

				if (!map_BenefitOrders.isEmpty() && checkValidValue(objHIFulfillmentEvent.Application_Id__c)) {
					for (String strKey : map_BenefitOrders.keySet()) {
						Benefit_Order__c objBO = map_BenefitOrders.get(strKey);
						for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
							map_CarrierOrders.put(strKey + objCO.Carrier__r.Id__c, objCO);
						}
					}
				}

				if (!map_Accounts.containsKey('' + objHIEventInfoParsed.company.id)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objHIFulfillmentEvent);
					continue;
				}
				if (checkValidValue(objHIFulfillmentEvent.Application_Id__c)) {
					String strSearchKey = objHIEventInfoParsed.company.id + objHIFulfillmentEvent.Application_Id__c;
					if (
						(map_BenefitOrders.containsKey('' + strSearchKey) && map_BenefitOrders.get('' + strSearchKey).Order_Status__c != BenefitOrderUtil.STATUS_FULFILLED) &&
						map_MFAuditDescriptions.containsKey(objHIEventInfoParsed.audit_type)
					) {
						objHIFulfillmentEvent.Deleted_At__c = System.now();
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.strBOErrorMsg, objHIFulfillmentEvent);
						continue;
					}
				}

				caseDataWrapper objCaseWrapper;

				if (objHIEventInfoParsed.audit_type == HIEnrollmentEventUtility.COMPANY_SUSPENSION_AUDIT) {
					String strSubject = HIEnrollmentEventUtility.COMPANY_SUSPENSION_AUDIT_SUBJECT;
					String strCaseDescription = HIEnrollmentEventUtility.PAYROLL_SUSPENSION_AUDIT_DESCRIPTION + ' \n\nCompany Hippo Link: ' + objHIEventInfoParsed.company.hippo_url;
					objCaseWrapper = new caseDataWrapper(
						objHIFulfillmentEvent.Id__c,
						'',
						objHIEventInfoParsed.audit_type,
						objHIEventInfoParsed.company.id,
						'',
						strSubject,
						strCaseDescription,
						objHIEventInfoParsed,
						''
					);
					map_EventIdsToCaseWrapper.put(objHIFulfillmentEvent.id__c, objCaseWrapper);

					continue;
				}

				if (objHIEventInfoParsed.audit_type == HIEnrollmentEventUtility.BENEFITS_STATUS_AUDIT) {
					String strSubject = '[Benefits Status Audit]' + objHIEventInfoParsed.company.name + ': Mismatched current benefits status period and current employment';
					String strCaseDescription = 'Company Hippo URL: ' + objHIEventInfoParsed.company.hippo_url;
					strCaseDescription += '\nEmployee Hippo URL: ' + objHIEventInfoParsed.employee.hippo_url;
					objCaseWrapper = new caseDataWrapper(
						objHIFulfillmentEvent.Id__c,
						'',
						objHIEventInfoParsed.audit_type,
						objHIEventInfoParsed.company.id,
						'',
						strSubject,
						strCaseDescription,
						objHIEventInfoParsed,
						''
					);
					map_EventIdsToCaseWrapper.put(objHIFulfillmentEvent.id__c, objCaseWrapper);

					continue;
				}

				if (
					map_MFAuditDescriptions.containsKey(objHIEventInfoParsed.audit_type) &&
					map_MFAuditDescriptions.get(objHIEventInfoParsed.audit_type).Audit_Payload__c != HIEnrollmentEventUtility.GROUP_LEVEL
				) {
					Map<Integer, String> map_UUIDToDescriptions = new Map<Integer, String>();
					String strSubject = objHIEventInfoParsed.subject;
					map_UUIDToDescriptions = setCaseDescription(objHIEventInfoParsed, objHIFulfillmentEvent, map_Carriers);

					for (Integer intStateCarrierId : map_UUIDToDescriptions.keySet()) {
						objCaseWrapper = new caseDataWrapper(
							objHIFulfillmentEvent.Id__c,
							'',
							objHIEventInfoParsed.audit_type,
							objHIEventInfoParsed.company.id,
							'',
							strSubject,
							map_UUIDToDescriptions.get(intStateCarrierId),
							objHIEventInfoParsed,
							''
						);
						map_EventIdsToCaseWrapper.put(objHIFulfillmentEvent.Id__c + intStateCarrierId, objCaseWrapper);
					}

					continue;
				}

				if (
					map_MFAuditDescriptions.containsKey(objHIEventInfoParsed.audit_type) &&
					map_MFAuditDescriptions.get(objHIEventInfoParsed.audit_type).Audit_Payload__c == HIEnrollmentEventUtility.GROUP_LEVEL &&
					objHIEventInfoParsed.company != null
				) {
					Map<Integer, String> map_StateCarrierIdToDescriptions = new Map<Integer, String>();
					String strSubject = objHIEventInfoParsed.subject;
					map_StateCarrierIdToDescriptions = setCaseDescriptionByCompany(objHIEventInfoParsed, map_Carriers);
					for (Integer intStateCarrierId : map_StateCarrierIdToDescriptions.keySet()) {
						objCaseWrapper = new caseDataWrapper(
							objHIFulfillmentEvent.Id__c,
							'',
							objHIEventInfoParsed.audit_type,
							objHIEventInfoParsed.company.id,
							'',
							strSubject,
							map_StateCarrierIdToDescriptions.get(intStateCarrierId),
							objHIEventInfoParsed,
							''
						);
						map_EventIdsToCaseWrapper.put(objHIFulfillmentEvent.Id__c + intStateCarrierId, objCaseWrapper);
					}
					continue;
				}
				if (objHIEventInfoParsed.items != null && objHIEventInfoParsed.items.size() > 0) {
					for (HIFulfillmentEventAuditJSON.item objItem : objHIEventInfoParsed.items) {
						HIFulfillmentEventAuditJSON.work_address objCompanyBenefitAddress = objHIEventInfoParsed.company.benefits_address;
						String strCarrierKey = '';
						String strEmployeeInformation = '';
						String strCaseDescription = objHIEventInfoParsed.subject;
						strCaseDescription = '\n' + objHIEventInfoParsed.instructions;
						strCaseDescription += '\n' + objHIEventInfoParsed.audit_type;

						if (objItem.state_carrier_id != null) {
							Carrier__c objCarrier = map_Carriers.get('' + objItem.state_carrier_id);
							if (objCarrier != null) {
								strCaseDescription += '\n\nCarrier\nCarrier: ' + objCarrier.Name;
								strCaseDescription += '\nCarrier State: ' + objCarrier.State__c;
								strCarrierKey = objCarrier.Key__c;
							}
						}

						if (String.isNotBlank(objItem.url)) {
							strCaseDescription += '\nurl: ' + objItem.url;
						}

						HIFulfillmentEventAuditJSON.home_address objEmployeeHomeAddress = objHIEventInfoParsed.employee.home_address;
						strCaseDescription +=
							'\n\nEmployee Info' +
							'\n- Name: ' +
							HIFulfillmentEventHelperFunctions.getName(objHIEventInfoParsed.employee.first_name, objHIEventInfoParsed.employee.middle_initial, objHIEventInfoParsed.employee.last_name) +
							'\n- SSN: ' +
							HIFulfillmentEventHelperFunctions.getMaskedSSN('' + objHIEventInfoParsed.employee.ssn) +
							'\n- DOB: ' +
							HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday) +
							'\n- Date of hire: ' +
							HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.hired_at) +
							'\n- Home Address: ' +
							HIFulfillmentEventHelperFunctions.getAddress(
								objEmployeeHomeAddress.street_1,
								objEmployeeHomeAddress.street_2,
								objEmployeeHomeAddress.city,
								objEmployeeHomeAddress.county_name,
								objEmployeeHomeAddress.state,
								objEmployeeHomeAddress.zip,
								objEmployeeHomeAddress.country
							);
						strCaseDescription += '\n- EE Panda Link: ' + objHIEventInfoParsed.employee.panda_url;
						strCaseDescription += '\n- EE Hippo Link: ' + objHIEventInfoParsed.employee.hippo_url;
						strCaseDescription +=
							'\n\n- Company Name: ' +
							objHIEventInfoParsed.company.name +
							'\n- Company Address:' +
							HIFulfillmentEventHelperFunctions.getAddress(
								objCompanyBenefitAddress.street_1,
								objCompanyBenefitAddress.street_2,
								objCompanyBenefitAddress.city,
								objCompanyBenefitAddress.county_name,
								objCompanyBenefitAddress.state,
								objCompanyBenefitAddress.zip,
								objCompanyBenefitAddress.country
							) +
							'\n\nPlease review and submit the required documents to the carrier.';

						strCaseDescription += '\n\n- COBRA Activated: ' + objHIEventInfoParsed.company.has_federal_cobra;
						strCaseDescription += '\n\nAudit Info';

						if (objItem.benefit_type != null) {
							strCaseDescription += '\nBenefit Type: ' + utils.humanize(objItem.benefit_type);
						}

						if (objItem.start_date != null) {
							strCaseDescription += '\nStart Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objItem.start_date);
						}

						if (objItem.end_date != null) {
							strCaseDescription += '\nEnd Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objItem.end_date);
						}

						if (objItem.enrollment_id != null) {
							strCaseDescription += '\nEnrollment Id: ' + objItem.enrollment_id;
						}

						strEmployeeInformation = 'Employee Info:';
						strEmployeeInformation +=
							'<br/>- Name: ' +
							HIFulfillmentEventHelperFunctions.getName(objHIEventInfoParsed.employee.first_name, objHIEventInfoParsed.employee.middle_initial, objHIEventInfoParsed.employee.last_name);
						strEmployeeInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHIEventInfoParsed.employee.ssn);
						strEmployeeInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday);

						objCaseWrapper = new caseDataWrapper(
							objHIFulfillmentEvent.Id__c,
							strCarrierKey,
							objHIFulfillmentEvent.Event_Type__c,
							objHIEventInfoParsed.company.id,
							'',
							'',
							strCaseDescription,
							objHIEventInfoParsed,
							strEmployeeInformation
						);

						map_EventIdsToCaseWrapper.put(objHIFulfillmentEvent.Id__c + '-' + objItem.id, objCaseWrapper);
					}
				}

				if (objHIEventInfoParsed.state_carriers != null && objHIEventInfoParsed.state_carriers.size() > 0) {
					Map<String, List<HIFulfillmentEventAuditJSON.benefit_items>> map_CarrierToSubscriptionLists = new Map<String, List<HIFulfillmentEventAuditJSON.benefit_items>>();
					Map<String, HIFulfillmentEventAuditJSON.policies> map_Policys = new Map<String, HIFulfillmentEventAuditJSON.policies>();
					Map<String, HIFulfillmentEventAuditJSON.forms> map_Forms = new Map<String, HIFulfillmentEventAuditJSON.forms>();
					Map<String, Set<String>> map_CarrierToDependentIds = new Map<String, Set<String>>();
					Map<String, HIFulfillmentEventAuditJSON.benefits_status_periods> map_SourceStatusPeriods = new Map<String, HIFulfillmentEventAuditJSON.benefits_status_periods>();
					Map<String, HIFulfillmentEventAuditJSON.benefits_status_periods> map_TargetStatusPeriods = new Map<String, HIFulfillmentEventAuditJSON.benefits_status_periods>();

					String strEnrollmentId = '';

					if (objHIEventInfoParsed.source_benefits_status_periods != null && objHIEventInfoParsed.source_benefits_status_periods.size() > 0) {
						for (HIFulfillmentEventAuditJSON.benefits_status_periods objPeriod : objHIEventInfoParsed.source_benefits_status_periods) {
							map_SourceStatusPeriods.put('' + objPeriod.id, objPeriod);
						}
					}

					if (!objHIEventInfoParsed.target_benefits_status_periods?.isEmpty()) {
						for (HIFulfillmentEventAuditJSON.benefits_status_periods objPeriod : objHIEventInfoParsed.target_benefits_status_periods) {
							map_TargetStatusPeriods.put('' + objPeriod.id, objPeriod);
						}
					}

					String strStatusPeriod = '\n';

					for (String strPeriodId : map_SourceStatusPeriods.keySet()) {
						HIFulfillmentEventAuditJSON.benefits_status_periods objPeriod = map_SourceStatusPeriods.get(strPeriodId);
						strStatusPeriod += '\nSource Benefit Status : ' + objPeriod.benefits_status;
						strStatusPeriod += '\nSource Benefit Status date : ' + objPeriod.start_date;

						if (map_TargetStatusPeriods.containsKey(strPeriodId)) {
							HIFulfillmentEventAuditJSON.benefits_status_periods objTargetPeriod = map_TargetStatusPeriods.get(strPeriodId);
							strStatusPeriod += '\nTarget Benefit Status : ' + objTargetPeriod.benefits_status;
							strStatusPeriod += '\nTarget Benefit Status date : ' + objTargetPeriod.start_date;
						}

						strStatusPeriod += '\n';
					}

					if (objHIEventInfoParsed.policies != null && objHIEventInfoParsed.policies.size() > 0) {
						for (HIFulfillmentEventAuditJSON.policies objPolicy : objHIEventInfoParsed.policies) {
							map_Policys.put('' + objPolicy.id, objPolicy);
						}
					}

					if (objHIEventInfoParsed.forms != null && objHIEventInfoParsed.forms.size() > 0) {
						for (HIFulfillmentEventAuditJSON.forms objForm : objHIEventInfoParsed.forms) {
							map_Forms.put('' + objForm.id, objForm);
						}
					}

					if (objHIEventInfoParsed.benefit_items != null && objHIEventInfoParsed.benefit_items.size() > 0) {
						for (HIFulfillmentEventAuditJSON.benefit_items objSubscription : objHIEventInfoParsed.benefit_items) {
							List<HIFulfillmentEventAuditJSON.benefit_items> list_Subscriptions = new List<HIFulfillmentEventAuditJSON.benefit_items>();

							if (map_CarrierToSubscriptionLists.containsKey('' + objSubscription.state_carrier_id)) {
								list_Subscriptions = map_CarrierToSubscriptionLists.get('' + objSubscription.state_carrier_id);
							}

							list_Subscriptions.add(objSubscription);
							map_CarrierToSubscriptionLists.put('' + objSubscription.state_carrier_id, list_Subscriptions);

							Set<String> set_DependentIds = new Set<String>();

							if (map_CarrierToDependentIds.containsKey('' + objSubscription.state_carrier_id)) {
								set_DependentIds = map_CarrierToDependentIds.get('' + objSubscription.state_carrier_id);
							}

							if (objSubscription.dependent_ids != null && objSubscription.dependent_ids.size() > 0) {
								for (Long lngDependentId : objSubscription.dependent_ids) {
									set_DependentIds.add('' + lngDependentId);
								}
							}

							map_CarrierToDependentIds.put('' + objSubscription.state_carrier_id, set_DependentIds);
						}
					}

					HIFulfillmentEventAuditJSON.home_address objEmployeeHomeAddress = objHIEventInfoParsed.employee.home_address;
					HIFulfillmentEventAuditJSON.work_address objCompanyBenefitAddress = objHIEventInfoParsed.company.benefits_address;

					if (objHIEventInfoParsed.State_carriers.size() > 0) {
						for (HIFulfillmentEventAuditJSON.state_carriers objStateCarrier : objHIEventInfoParsed.State_carriers) {
							String strCaseDescription = '';
							strEnrollmentId = '';

							strCaseDescription +=
								'General Info' +
								'\n- Employee Loosing Eligibility Audit ' +
								'\n- Subscriptions link: ' +
								objHIEventInfoParsed.benefits_url +
								'\n- EE Panda Link: ' +
								objHIEventInfoParsed.employee.panda_url +
								'\n- Carrier Directory: ' +
								objStateCarrier.url +
								'\n\n- COBRA Activated: ' +
								objHIEventInfoParsed.company.has_federal_cobra +
								'\n\nEmployee Info' +
								'\n- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(
									objHIEventInfoParsed.employee.first_name,
									objHIEventInfoParsed.employee.middle_initial,
									objHIEventInfoParsed.employee.last_name
								) +
								'\n- SSN: ' +
								HIFulfillmentEventHelperFunctions.getMaskedSSN('' + objHIEventInfoParsed.employee.ssn) +
								'\n- DOB: ' +
								HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday) +
								'\n- Date of hire: ' +
								HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.hired_at) +
								'\n- Home Address: ' +
								HIFulfillmentEventHelperFunctions.getAddress(
									objEmployeeHomeAddress.street_1,
									objEmployeeHomeAddress.street_2,
									objEmployeeHomeAddress.city,
									objEmployeeHomeAddress.county_name,
									objEmployeeHomeAddress.state,
									objEmployeeHomeAddress.zip,
									objEmployeeHomeAddress.country
								) +
								'\n\nCarrier' +
								'\n- Carrier: ' +
								objStateCarrier.name +
								'\n- Carrier State: ' +
								objStateCarrier.state +
								'\n\nTermination Forms' +
								getForms(objStateCarrier.forms, map_Forms) +
								'\n\nCompany Info' +
								'\n- Company Name: ' +
								objHIEventInfoParsed.company.name +
								'\n- Company Address:' +
								HIFulfillmentEventHelperFunctions.getAddress(
									objCompanyBenefitAddress.street_1,
									objCompanyBenefitAddress.street_2,
									objCompanyBenefitAddress.city,
									objCompanyBenefitAddress.county_name,
									objCompanyBenefitAddress.state,
									objCompanyBenefitAddress.zip,
									objCompanyBenefitAddress.country
								) +
								'\n\n\n- Period status: ' +
								strStatusPeriod +
								'-' +
								'\n\nPlease review and submit the required documents to the carrier.';

							String strEmployeeInformation = 'Employee Info:';
							strEmployeeInformation +=
								'<br/>- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(
									objHIEventInfoParsed.employee.first_name,
									objHIEventInfoParsed.employee.middle_initial,
									objHIEventInfoParsed.employee.last_name
								);
							strEmployeeInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHIEventInfoParsed.employee.ssn);
							strEmployeeInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday);

							String enrollmentKey = strEnrollmentId + '-' + objStateCarrier.key + '-' + objHIEventInfoParsed.employee.id;

							objCaseWrapper = new caseDataWrapper(
								objHIFulfillmentEvent.Id__c,
								objStateCarrier.key,
								objHIFulfillmentEvent.Event_Type__c,
								objHIEventInfoParsed.company.id,
								'',
								'',
								strCaseDescription,
								objHIEventInfoParsed,
								strEmployeeInformation
							);

							map_EventIdsToCaseWrapper.put(objHIFulfillmentEvent.id__c + '-' + objStateCarrier.key, objCaseWrapper);
						}
					}
				}
			}
		}

		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);

		if (!set_EmployeeSearchKey.isEmpty()) {
			map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);

			processContactInformation(list_HIFulfillmentEvents, map_EventIdsToInfo, map_Accounts, map_Contacts);

			map_Contacts = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeSearchKey);
		}

		List<Case> list_CasesToBeUpsert = getCaseInformation(
			map_EventIdsToCaseWrapper,
			list_HIFulfillmentEvents,
			map_EventIdsToInfo,
			map_Accounts,
			map_Contacts,
			map_Carriers,
			map_BenefitOrders,
			map_CarrierOrders
		);
		Map<String, String> map_DMLCaseUpsertErrors = new Map<String, String>();

		if (!list_CasesToBeUpsert.isEmpty()) {
			List<Database.UpsertResult> list_SaveResults = database.upsert(list_CasesToBeUpsert, Case.Fields.Integration_Key__c, false);
			map_DMLCaseUpsertErrors = Utils.processUpsertResult(list_SaveResults, list_CasesToBeUpsert, 'Integration_Id__c', true, 'HIFulfillmentEventTermination-processInformation');
		}

		createAttachment(list_CasesToBeUpsert, map_EventIdsToCaseWrapper);

		for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
			if (
				objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE ||
				objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE ||
				objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.PROCESSED_STATE
			) {
				continue;
			}

			if (map_DMLCaseUpsertErrors.containsKey(objHIFulfillmentEvent.Id__c)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLCaseUpsertErrors.get(objHIFulfillmentEvent.Id__c), objHIFulfillmentEvent);
				continue;
			} else {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIEnrollmentEventUtility.SUCCESS_MESSAGE, objHIFulfillmentEvent);
			}
		}
	}

	/**
	 * @description  This method is used to create an attachment for the cases which are goin to be upserted.
	 * @param        List of cases which are to be upserted,
	 *               Map of event id with case wrapper
	 * @return       NA
	 **/
	public static void createAttachment(List<Case> list_CasesToBeUpsert, Map<String, CaseDataWrapper> map_EventIdsToCaseWrapper) {
		List<Attachment> list_Attachments = new List<Attachment>();
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey(HIEnrollmentEventUtility.MASTER);
		for (Case objCase : list_CasesToBeUpsert) {
			if (objCase.Id != null) {
				if (map_EventIdsToCaseWrapper.containsKey(objCase.Integration_Key__c)) {
					CaseDataWrapper objCaseDataWrapper = map_EventIdsToCaseWrapper.get(objCase.Integration_Key__c);

					if (objCaseDataWrapper.strEmployeeInformation != null && objCaseDataWrapper.strEmployeeInformation != '') {
						Attachment objAttachment = new Attachment();
						objAttachment.ParentId = objCase.Id;
						objAttachment.Body = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, objCaseDataWrapper.strEmployeeInformation);
						objAttachment.Name = HIEnrollmentEventUtility.strFileName;
						list_Attachments.add(objAttachment);
					}
				}
			}
		}

		if (list_Attachments.size() > 0) {
			insert list_Attachments;
		}
	}

	//calling HIFulfillmentTerminationEvenJSON class for parsing data
	private HIFulfillmentEventAuditJSON getJSONParsedData(String strJSON) {
		HIFulfillmentEventAuditJSON objJSONParsedData = (HIFulfillmentEventAuditJSON) JSON.deserialize(strJSON, HIFulfillmentEventAuditJSON.class);
		return objJSONParsedData;
	}

	//Get forms information
	private String getForms(Long[] lngForms, Map<String, HIFulfillmentEventAuditJSON.forms> map_Forms) {
		string strFormsInfo = '';

		if (lngForms == null) {
			strFormsInfo = HIEnrollmentEventUtility.NOT_AVAILABLE;
		} else {
			for (Long lngFormId : lngForms) {
				if (map_Forms.containsKey('' + lngFormId)) {
					HIFulfillmentEventAuditJSON.forms objForm = map_Forms.get('' + lngFormId);
					strFormsInfo += '\n' + objForm.url;
				}
			}
		}

		return strFormsInfo;
	}

	/**
	 * @description  This method is used to create new contacts for the Account when account does not have matching contact.
	 * @param        List of HI_Fulfillment_Event__c records,
	 *               Map of event Id with Parsed Event Info,
	 *               Map of Accounts,
	 *               Map of Contacts
	 * @return       NA
	 **/
	private void processContactInformation(
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents,
		Map<string, HIFulfillmentEventAuditJSON> map_EventIdsToInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts
	) {
		List<Contact> list_ContactsToBeInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
			if (objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentEventAuditJSON objHIEventInfo = map_EventIdsToInfo.get(objHIFulfillmentEvent.Id__c);

			if (objHIEventInfo.employee == null || objHIEventInfo.employee.company_id == null || !map_Accounts.containsKey('' + objHIEventInfo.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objHIFulfillmentEvent);
				continue;
			}

			if (
				!map_Contacts.containsKey(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.email) &&
				!map_Contacts.containsKey(objHIEventInfo.employee.email) &&
				!map_Contacts.containsKey(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.id)
			) {
				Contact objContact = new Contact();
				objContact.AccountId = map_Accounts.get('' + objHIEventInfo.employee.company_id).Id;
				objContact.FirstName = objHIEventInfo.employee.first_Name;
				objContact.LastName = objHIEventInfo.employee.last_name;

				if (objHIEventInfo.employee.email != null) {
					objContact.Email = objHIEventInfo.employee.email.trim();
				}

				objContact.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
				list_ContactsToBeInsert.add(objContact);
			}
		}

		if (!list_ContactsToBeInsert.isEmpty()) {
			Map<String, String> map_DMLContactInsertErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = database.insert(list_ContactsToBeInsert, false);
			map_DMLContactInsertErrors = Utils.processSaveResult(list_SaveResults, list_ContactsToBeInsert, 'email', true, 'HIFulfillmentEventTermination-processContactInformation');

			for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
				HIFulfillmentEventAuditJSON objHIEventInfo = map_EventIdsToInfo.get(objHIFulfillmentEvent.Id__c);

				if (map_DMLContactInsertErrors.containsKey(objHIEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLContactInsertErrors.get(objHIEventInfo.employee.email), objHIFulfillmentEvent);
					continue;
				}
			}
		}
	}

	/**
	 * @description  This method is used to get the existing cases baesd on the ContactId.
	 * @param        Set of Contact Ids
	 * @return       Map of Cases
	 **/
	private Map<String, Case> getContactCaseMap(Set<Id> set_ContactIds) {
		Map<String, Case> map_Cases = new Map<String, Case>();

		for (Case objCase : [SELECT Id, ContactId, Type, Carrier__c FROM Case WHERE contactId != NULL AND contactId IN :set_ContactIds AND isClosed = FALSE]) {
			map_Cases.put(objCase.ContactId + '-' + objCase.Type + '-' + objCase.Carrier__c, objCase);
		}

		return map_Cases;
	}

	/**
	 * @description  This method is used to create new cases and update the exisitnf cases related with account and contact.
	 * @param        Map of event Id with case wrapper,
	 *               List of HI_Fulfillment_Event__c records,
	 *               Map of event Id with parsed event info,
	 *               Map of Accounts,
	 *               Map of Contacts,
	 *               Map of Carriers,
	 *               Map of Benefit Orders,
	 *               Map of Carrier Orders
	 * @return       String of subscription insformation
	 **/
	private List<Case> getCaseInformation(
		Map<String, caseDataWrapper> map_EventIdsToCaseWrapper,
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents,
		Map<string, HIFulfillmentEventAuditJSON> map_EventIdsToInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Map<String, Carrier__c> map_Carriers,
		Map<String, Benefit_Order__c> map_BenefitOrders,
		Map<String, Carrier_Order__c> map_CarrierOrders
	) {
		List<Case> list_CasesToBeInsert = new List<Case>();
		Set<Id> set_ContactIds = new Set<Id>();

		if (strReconciliationSpecialInstructions.contains(TODAYDATE)) {
			strReconciliationSpecialInstructions = strReconciliationSpecialInstructions.replace(TODAYDATE, String.valueOf(System.today()));
		}

		for (Contact objContact : map_Contacts.values()) {
			set_ContactIds.add(objContact.id);
		}

		Map<String, Case> map_ExistingCases = getContactCaseMap(set_ContactIds);
		Map<String, String> map_UUIDsWithBenefitType = new Map<String, String>();
		Map<String, String> map_UUIDsWithAuditType = new Map<String, String>();
		Map<String, String> map_SelectionIdsWithUUIds = new Map<String, String>();
		Map<String, Set<String>> map_CompanyEmpIdAndSelectionIds = new Map<String, Set<String>>();
		Map<String, String> map_StateCarrierIdsWithAuditType = new Map<String, String>();
		for (HI_Fulfillment_Event__c objHIFulFill : list_HIFulfillmentEvents) {
			HIFulfillmentEventAuditJSON objHIEventInfo = map_EventIdsToInfo.get(objHIFulFill.Id__c);
			MF_Audit_Descriptions__mdt objMDT = map_MFAuditDescriptions?.get(objHIEventInfo.audit_type);

			if (objHIEventInfo?.items != null && objHIEventInfo.items.size() > 0) {
				for (HIFulfillmentEventAuditJSON.item objItem : objHIEventInfo.items) {
					if (String.isNotBlank(objItem.uuid) && !objItem.uuid.equalsIgnoreCase(strNullCheck) && String.isNotBlank(objItem.benefit_type)) {
						map_UUIDsWithBenefitType.put(objItem.uuid, objItem.benefit_type);

						if (String.isNotBlank(objHIEventInfo.audit_type)) {
							map_UUIDsWithAuditType.put(objItem.uuid, objHIEventInfo.audit_type);
						}

						if (objItem.id != null && objMDT != null && String.isNotBlank(objMDT.Parent_Cases__c) && objMDT.Parent_Cases__c.containsIgnoreCase(HIEnrollmentEventUtility.MF_TERMINATION)) {
							map_SelectionIdsWithUUIds.put(objItem.id + '', objItem.uuid);

							Set<String> set_SelectionIds = map_CompanyEmpIdAndSelectionIds.get('' + objHIEventInfo.company.id + objHIEventInfo.employee.id);
							if (set_SelectionIds == null) {
								set_SelectionIds = new Set<String>();
							}
							set_SelectionIds.add(objItem.id + '');
							map_CompanyEmpIdAndSelectionIds.put('' + objHIEventInfo?.company?.id + objHIEventInfo?.employee?.id, set_SelectionIds);
						}
					}
				}
			}

			if (objHIEventInfo.company != null && String.isNotBlank(objHIEventInfo.audit_type) && objMDT != null && objMDT.Audit_Payload__c == HIEnrollmentEventUtility.GROUP_LEVEL) {
				if (objHIEventInfo.policies != null && objHIEventInfo.policies.size() > 0) {
					for (HIFulfillmentEventAuditJSON.policies objPolicy : objHIEventInfo.policies) {
						map_StateCarrierIdsWithAuditType.put(String.valueOf(objPolicy.state_carrier_id) + '~' + objHIEventInfo.company.Id, objHIEventInfo.audit_type);
					}
				}
			}
		}

		Map<String, Case> map_ExistingCaseWithUUID = new Map<String, Case>();
		Map<String, Case> map_ExistingCaseWithCarrierId = new Map<String, Case>();
		//querying the existing cases based on UUID, benefits type and audit type
		if (!map_UUIDsWithBenefitType?.isEmpty()) {
			map_ExistingCaseWithUUID = fetchCases(map_UUIDsWithBenefitType, map_UUIDsWithAuditType);
		}

		if (!map_StateCarrierIdsWithAuditType?.isEmpty()) {
			map_ExistingCaseWithCarrierId = fetchCasesOnCompanyId(map_StateCarrierIdsWithAuditType);
		}

		if (!set_MFTerminationRecTypeIds?.isEmpty() && !map_SelectionIdsWithUUIds?.isEmpty()) {
			map_ExistingCaseWithUUID = fetchMFTerminationCases(map_ExistingCaseWithUUID, map_SelectionIdsWithUUIds, map_CompanyEmpIdAndSelectionIds);
		}

		for (HI_Fulfillment_Event__c objHIFulfillmentEvent : list_HIFulfillmentEvents) {
			if (objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentEventAuditJSON objHIEventInfo = map_EventIdsToInfo.get(objHIFulfillmentEvent.Id__c);

			if (!map_Accounts.containsKey('' + objHIEventInfo.company.id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_DOES_NOT_EXIST, objHIFulfillmentEvent);
				continue;
			}

			Account objAccount = map_Accounts.get('' + objHIEventInfo.company.id);
			Contact objContact;

			if (!map_Contacts.isEmpty()) {
				if (objHIFulfillmentEvent.Event_Type__c != HIEnrollmentEventUtility.HI_EVENT_COMPANY_UPDATE && objHIEventInfo.audit_type != HIEnrollmentEventUtility.COMPANY_SUSPENSION_AUDIT) {
					if (map_Contacts.containsKey(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.email)) {
						objContact = map_Contacts.get(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.email);
					} else if (map_Contacts.containsKey(objHIEventInfo.employee.email)) {
						objContact = map_Contacts.get(objHIEventInfo.employee.email);
					} else if (map_Contacts.containsKey(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.id)) {
						objContact = map_Contacts.get(objHIEventInfo.employee.company_id + '-' + objHIEventInfo.employee.id);
					}
				}
			}

			Database.DMLOptions objDMLOption = new Database.DMLOptions();
			objDMLOption.assignmentRuleHeader.useDefaultRule = true;
			// creating a case for company suspension audit type
			if (objHIEventInfo.audit_type == HIEnrollmentEventUtility.COMPANY_SUSPENSION_AUDIT) {
				Case objCase = new Case();
				objCase.setOptions(objDMLOption);
				objCase.Integration_Id__c = objHIFulfillmentEvent.Id__c;
				objCase.Integration_Key__c = objHIFulfillmentEvent.Id__c;
				objCase.Description = map_EventIdsToCaseWrapper.get(objHIFulfillmentEvent.Id__c).strCaseDescription;
				objCase.AccountId = objAccount.id;
				objCase.Routing_Case_Reason__c = HIEnrollmentEventUtility.PAYROLL_SUSPENSION_AUDIT;
				objCase.Answer_IQ_Processed__c = HIEnrollmentEventUtility.YES;
				objCase.Subject = HIEnrollmentEventUtility.ACTION_NEEDED_CASE_SUBJECT;

				if (objContact != null) {
					objCase.ContactId = objContact.Id;
				}

				objCase.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
				objCase.Type = CaseUtils.BENEFITS_CASE_PILLAR;

				if(!list_CasesToBeInsert.contains(objCase)) {
					list_CasesToBeInsert.add(objCase);
				}
				continue;
			}

			// creating a case for benefits status audit type
			if (objHIEventInfo.audit_type == HIEnrollmentEventUtility.BENEFITS_STATUS_AUDIT) {
				Case objCase = new Case();
				objCase.setOptions(objDMLOption);
				objCase.Integration_Id__c = objHIFulfillmentEvent.Id__c;
				objCase.Integration_Key__c = objHIFulfillmentEvent.Id__c;
				objCase.Description = map_EventIdsToCaseWrapper.get(objHIFulfillmentEvent.Id__c).strCaseDescription;
				objCase.AccountId = objAccount.id;
				objCase.Type = HIEnrollmentEventUtility.AUDIT;
				objCase.Opps_Owner__c = HIEnrollmentEventUtility.NEW_PLAN;
				objCase.RecordTypeId = CaseUtils.RECTYPE_NEW_PLAN;

				if (objContact != null) {
					objCase.ContactId = objContact.Id;
				}

				if (map_BenefitOrders.containsKey('' + objHIEventInfo.company.id)) {
					Benefit_Order__c objBenefitOrder = map_BenefitOrders.get('' + objHIEventInfo.company.id);
					objCase.Benefit_Order__c = objBenefitOrder.id;
					objCase.OwnerId = objBenefitOrder.OwnerId;
				} else {
					objCase.setOptions(objDMLOption);
				}
				if(!list_CasesToBeInsert.contains(objCase)) {
					list_CasesToBeInsert.add(objCase);
				}
				continue;
			}

			if (
				objHIEventInfo.company != null &&
				String.isNotBlank(objHIEventInfo.audit_type) &&
				map_MFAuditDescriptions.containsKey(objHIEventInfo.audit_type) &&
				map_MFAuditDescriptions.get(objHIEventInfo.audit_type).Audit_Payload__c == HIEnrollmentEventUtility.GROUP_LEVEL &&
				(objHIEventInfo?.items == null || objHIEventInfo.items.size() == 0)
			) {
				list_CasesToBeInsert = createCaseForGroupLevelPayload(
					objHIEventInfo,
					map_ExistingCaseWithCarrierId,
					objAccount,
					objContact,
					objHIFulfillmentEvent,
					list_CasesToBeInsert,
					map_EventIdsToCaseWrapper,
					map_Carriers,
					map_BenefitOrders,
					map_CarrierOrders
				);
			}

			// this newly added audit type and audit type mappings have been stored in MF_Audit_Descriptions__mdt metadata
			if (
				map_MFAuditDescriptions.containsKey(objHIEventInfo.audit_type) &&
				objHIEventInfo?.items != null &&
				objHIEventInfo.items.size() > 0
			) {
				List<Case> list_MFAuditCasesToBeInsert = new List<Case>();
				String strErrorMessage = '';
				MF_Audit_Descriptions__mdt objMFAuditMDT = map_MFAuditDescriptions.get(objHIEventInfo.audit_type);
				Map<String, List<HIFulfillmentEventAuditJSON.item>> map_StateCarrierIdTOItems = new Map<String, List<HIFulfillmentEventAuditJSON.item>>();
				List<HIFulfillmentEventAuditJSON.item> list_Items = new List<HIFulfillmentEventAuditJSON.item>();

				for (HIFulfillmentEventAuditJSON.item objItem : objHIEventInfo.items) {
					list_Items = new List<HIFulfillmentEventAuditJSON.item>();

					if (map_StateCarrierIdTOItems.containsKey(objHIFulfillmentEvent.Id__c + objItem.state_carrier_id)) {
						list_Items = map_StateCarrierIdTOItems.get(objHIFulfillmentEvent.Id__c + objItem.state_carrier_id);
					}

					list_Items.add(objItem);
					map_StateCarrierIdTOItems.put(objHIFulfillmentEvent.Id__c + objItem.state_carrier_id, list_Items);
				}

				if (map_StateCarrierIdTOItems.isEmpty()) {
					continue;
				}

				Boolean blnIsBO = false;
				Boolean blnIsCO = false;
				Benefit_Order__c objBenefitOrder = new Benefit_Order__c();
				String strRelativeObject = map_MFAuditDescriptions.get(objHIEventInfo.audit_type).Relative_Object__c;

				//checking for mathcing Benefit order and carrier order based on application id and carrier id.
				if (String.isNotBlank(strRelativeObject)) {
					blnIsBO = (strRelativeObject == HIEnrollmentEventUtility.BENEFIT_ORDER);
					blnIsCO = (strRelativeObject == HIEnrollmentEventUtility.CARRIER_ORDER);
				}

				// filling the case details
				for (String strKey : map_StateCarrierIdTOItems.keySet()) {
					Case objCase = new Case();
					objCase.setOptions(objDMLOption);
					//descriptions have been stored in metadata MF_Audit_Descriptions__mdt
					objCase.Description = map_EventIdsToCaseWrapper.get(strKey).strCaseDescription;
					objCase.AccountId = objAccount.id;
					objCase.Type = objHIEventInfo.audit_type;

					if (objHIEventInfo.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)) {
						objCase.First_Response_Time_Deadline__c = objHIEventInfo.deadline_date;
					}
					objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_AUDIT;

					if (objContact != null) {
						objCase.ContactId = objContact.Id;
					}
					// generate the integration key from event id and UUID.
					objCase.Integration_Id__c = objHIFulfillmentEvent.Id__c;
					objCase.Integration_Key__c = objHIFulfillmentEvent.Id__c;
					objCase.Selection_UUIDs__c = '';
					objCase.Benefit_Types__c = '';
					String strCarrierId = '';
					Case objExistingCase = new Case();
					String strSearchKey = '';
					Boolean blnSearchWithAuditType = false;

					for (HIFulfillmentEventAuditJSON.item objItem : map_StateCarrierIdTOItems.get(strKey)) {
						objCase.Integration_Id__c += '~' + objItem.uuid;
						objCase.Integration_Key__c += '~' + objItem.uuid;
						objCase = setBenefitTypeWithUUID(objCase, objItem.benefit_type, objItem.uuid);
						strCarrierId = objItem.state_carrier_id + '';
						strSearchKey = objHIEventInfo.audit_type + '~' + objItem.uuid;

						if (objExistingCase.Id == null && map_ExistingCaseWithUUID.containsKey(strSearchKey)) {
							objExistingCase = map_ExistingCaseWithUUID.get(strSearchKey);
							blnSearchWithAuditType = true;
							continue;
						}

						if (!blnSearchWithAuditType && objExistingCase.Id == null) {
							strSearchKey = '';
							//matching the existing audit cases with current audit type.
							if (String.isNotBlank(objMFAuditMDT.Parent_Cases__c)) {
								for (String strParent : objMFAuditMDT.Parent_Cases__c.split(';')) {
									strParent = strParent.trim();
									if (HIEnrollmentEventUtility.MF_NHE.equalsIgnoreCase(strParent)) {
										strSearchKey = HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE + '~' + objItem.uuid;
									} else if (HIEnrollmentEventUtility.MF_QLE.equalsIgnoreCase(strParent)) {
										strSearchKey = HIEnrollmentEventUtility.CASE_RT_ID_MF_QLE + '~' + objItem.uuid;
									} else if (HIEnrollmentEventUtility.MF_TERMINATION.equalsIgnoreCase(strParent)) {
										strSearchKey = HIEnrollmentEventUtility.CASE_RT_ID_MF_TERMINATION + '~' + objItem.uuid;
									}

									if (String.isNotBlank(strSearchKey) && map_ExistingCaseWithUUID.containsKey(strSearchKey)) {
										objExistingCase = map_ExistingCaseWithUUID.get(strSearchKey);
										break;
									}
								}
							}
						}
					}

					if(String.isNotBlank(objCase.Integration_Id__c) && objCase.Integration_Id__c.length() > 255 ){
						objCase.Integration_Id__c = objCase.Integration_Id__c.substring(0, 255);
					}

					if(String.isNotBlank(objCase.Integration_Key__c) && objCase.Integration_Key__c.length() > 255 ){
						objCase.Integration_Key__c = objCase.Integration_Key__c.substring(0, 255);
					}
					
					if (String.isNotBlank(objCase.Selection_UUIDs__c)) {
						objCase.Selection_UUIDs__c = objCase.Selection_UUIDs__c.removeEnd(';');
					}
					// attach the BO & CO to the case
					if (checkValidValue(objHIFulfillmentEvent.Application_Id__c)) {
						if (blnIsBO || blnIsCO) {
							if (map_BenefitOrders.containsKey('' + objHIEventInfo.company.id + objHIFulfillmentEvent.Application_Id__c)) {
								objBenefitOrder = map_BenefitOrders.get('' + objHIEventInfo.company.id + objHIFulfillmentEvent.Application_Id__c);
								objCase.Benefit_Order__c = objBenefitOrder.Id;
							}
						}

						if (blnIsCO) {
							String strCOSearchKey = '';
							strCOSearchKey = objHIEventInfo.company.id + objHIFulfillmentEvent.Application_Id__c + strCarrierId;
							if (map_CarrierOrders.containsKey(strCOSearchKey)) {
								objCase.Carrier_Order__c = map_CarrierOrders.get(strCOSearchKey).Id;
							}
						}
					}

					if (map_Carriers.containsKey(strCarrierId)) {
						objCase.Carrier__c = map_Carriers.get(strCarrierId).id;
					}

					//Check duplicate Case records
					if (objExistingCase.Id != null) {
						if (blnSearchWithAuditType) {
							if (
								(objExistingCase.Status != null && set_ClosedCaseStatus.contains(objExistingCase.Status)) ||
								(String.isNotBlank(objHIEventInfo.audit_type) && objHIEventInfo.audit_type.equalsIgnoreCase(HIEnrollmentEventUtility.ERROR_PROCESSING_SUBSCRIPTION))
							) {
								objCase.ParentId = objExistingCase.Id;
								objCase.Anticipated_Effective_Date__c = objExistingCase.Anticipated_Effective_Date__c;
								objCase.Special_Instructions__c = objHIEventInfo.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)
									? strReconciliationSpecialInstructions
									: strSpecialInstructions;
								objExistingCase = resetUUIdsInParentCase(objCase, objExistingCase, objCase.Benefit_Types__c);
								list_MFAuditCasesToBeInsert.add(objExistingCase);
							} else {
								objCase.Id = objExistingCase.Id;
								objCase.Integration_Id__c = objExistingCase.Integration_Id__c;
								objCase.Integration_Key__c = objExistingCase.Integration_Key__c;
								if (objHIEventInfo.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)) {
									objCase.Special_Instructions__c = strReconciliationSpecialInstructions;
								}
								if (String.isNotBlank(objExistingCase.Benefit_Types__c)) {
									for (String strValue : objExistingCase.Benefit_Types__c.split(';')) {
										if (String.isNotBlank(strValue) && !objCase.Benefit_Types__c.contains(strValue)) {
											objCase.Benefit_Types__c += strValue + ';';
										}
									}
								}
								if (objExistingCase.ParentId != null && objExistingCase.Parent.RecordTypeId == HIEnrollmentEventUtility.CASE_RT_ID_MF_AUDIT) {
									objExistingCase = resetUUIdsInParentCase(
										objCase,
										new Case(
											Id = objExistingCase.ParentId,
											Selection_UUIDs__c = objExistingCase.Parent.Selection_UUIDs__c,
											Integration_Id__c = objExistingCase.Parent.Integration_Id__c,
											Integration_Key__c = objExistingCase.Parent.Integration_Key__c
										),
										objCase.Benefit_Types__c
									);
									list_MFAuditCasesToBeInsert.add(objExistingCase);
								}
							}
						} else {
							if (
								(objExistingCase.Status != null && set_ClosedCaseStatus.contains(objExistingCase.Status)) ||
								(String.isNotBlank(objHIEventInfo.audit_type) && objHIEventInfo.audit_type.equalsIgnoreCase(HIEnrollmentEventUtility.ERROR_PROCESSING_SUBSCRIPTION))
							) {
								objCase.ParentId = objExistingCase.Id;
								objCase.Anticipated_Effective_Date__c = objExistingCase.Anticipated_Effective_Date__c;
								objCase.Special_Instructions__c = objHIEventInfo.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)
									? strReconciliationSpecialInstructions
									: strSpecialInstructions;
							} else {
								strErrorMessage = objExistingCase.RecordType.Name + HIEnrollmentEventUtility.CASE_ALREADY_OPEN + objExistingCase.Id;
							}
						}
					}
					if(!list_MFAuditCasesToBeInsert.contains(objCase)) {
						list_MFAuditCasesToBeInsert.add(objCase);
					}
				}

				if (String.isBlank(strErrorMessage)) {
					list_CasesToBeInsert.addAll(list_MFAuditCasesToBeInsert);
				} else {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, strErrorMessage, objHIFulfillmentEvent);
				}

				continue;
			}

			if (objHIEventInfo.items != null && objHIEventInfo.items.size() > 0) {
				for (HIFulfillmentEventAuditJSON.item objItem : objHIEventInfo.items) {
					Case objCase = new Case();
					objCase.Integration_Id__c = objHIFulfillmentEvent.Id__c;
					objCase.Integration_Key__c = objHIFulfillmentEvent.Id__c + '-' + objItem.id;
					objCase.Description = map_EventIdsToCaseWrapper.get(objHIFulfillmentEvent.Id__c + '-' + objItem.id).strCaseDescription;
					objCase.AccountId = objAccount.id;

					if (objContact != null) {
						objCase.ContactId = objContact.Id;
					}

					if (objItem.state_carrier_id != null && map_Carriers.containsKey('' + objItem.state_carrier_id)) {
						objCase.Carrier__c = map_Carriers.get('' + objItem.state_carrier_id).id;
					}

					if (map_ExistingCases.containsKey(objCase.ContactId + '-' + HIEnrollmentEventUtility.AUDIT + '-' + objCase.Carrier__c)) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.AUDIT_CASE_ALREADY_EXIST, objHIFulfillmentEvent);
						continue;
					}

					objCase.RecordTypeId = CaseUtils.RECTYPE_MF_AUDIT;
					objCase.setOptions(objDMLOption);
					if(!list_CasesToBeInsert.contains(objCase)) {
						list_CasesToBeInsert.add(objCase);
					}
				}
			}

			if (objHIEventInfo.State_carriers != null && objHIEventInfo.State_carriers.size() > 0) {
				for (HIFulfillmentEventAuditJSON.state_carriers objStateCarrier : objHIEventInfo.State_carriers) {
					Case objCase = new Case();
					objCase.setOptions(objDMLOption);
					objCase.Integration_Id__c = objHIFulfillmentEvent.Id__c;
					objCase.Integration_Key__c = objHIFulfillmentEvent.Id__c + '-' + objStateCarrier.Key;
					objCase.Description = map_EventIdsToCaseWrapper.get(objHIFulfillmentEvent.Id__c + '-' + objStateCarrier.Key).strCaseDescription;
					objCase.AccountId = objAccount.id;

					if (objContact != null) {
						objCase.ContactId = objContact.Id;
					}

					if (map_Carriers.containsKey('' + objStateCarrier.id)) {
						objCase.Carrier__c = map_Carriers.get('' + objStateCarrier.id).id;
					}

					if (map_ExistingCases.containsKey(objCase.ContactId + '-' + HIEnrollmentEventUtility.AUDIT + '-' + objCase.Carrier__c)) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIEnrollmentEventUtility.AUDIT_CASE_ALREADY_EXIST, objHIFulfillmentEvent);
						continue;
					}

					objCase.RecordTypeId = CaseUtils.RECTYPE_MF_AUDIT;
					if (objHIEventInfo.audit_type != null) {
						if (objHIEventInfo.audit_type == HIEnrollmentEventUtility.BENEFITS_STATUS_AUDIT) {
							if (map_BenefitOrders.containsKey('' + objHIEventInfo.company.id)) {
								Benefit_Order__c objBenefitOrder = map_BenefitOrders.get('' + objHIEventInfo.company.id);
								objCase.Benefit_Order__c = objBenefitOrder.id;
								objCase.OwnerId = objBenefitOrder.OwnerId;
								objCase.Type = HIEnrollmentEventUtility.AUDIT;
								objCase.Opps_Owner__c = HIEnrollmentEventUtility.NEW_PLAN;
								objCase.RecordTypeId = CaseUtils.RECTYPE_NEW_PLAN;
							} else {
								objCase.setOptions(objDMLOption);
							}
						} else {
							objCase.setOptions(objDMLOption);
						}
					} else {
						objCase.setOptions(objDMLOption);
					}
					if(!list_CasesToBeInsert.contains(objCase)) {
						list_CasesToBeInsert.add(objCase);
					}
				}
			}
		}

		return list_CasesToBeInsert;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to get the map of existing cases with companyId
	 * @param        HIFulfillmentEventAuditJSON,
	 *               Map of companiIds With Audit Type,
	 *               Instance of Account, Instance of Contact,
	 *               Object of HI_Fulfillment_Event__c,
	 *               list_CasesToBeInsert list of Case,
	 *               Map of event id with case wrapper
	 *               Map of String and Carrier
	 * @return       List of Case.
	 **/
	public List<Case> createCaseForGroupLevelPayload(
		HIFulfillmentEventAuditJSON objHIEventInfo,
		Map<String, Case> map_ExistingCaseWithCarrierId,
		Account objAccount,
		Contact objContact,
		HI_Fulfillment_Event__c objHIFulfillmentEvent,
		List<Case> list_CasesToBeInsert,
		Map<String, CaseDataWrapper> map_EventIdsToCaseWrapper,
		Map<String, Carrier__c> map_Carriers,
		Map<String, Benefit_Order__c> map_BenefitOrders,
		Map<String, Carrier_Order__c> map_CarrierOrders
	) {
		Map<String, List<HIFulfillmentEventAuditJSON.policies>> map_StateCarrierIdTOPolicies = new Map<String, List<HIFulfillmentEventAuditJSON.policies>>();
		if (objHIEventInfo.policies != null) {
			for (HIFulfillmentEventAuditJSON.policies objPolicy : objHIEventInfo.policies) {
				if (!map_StateCarrierIdTOPolicies.isEmpty() && map_StateCarrierIdTOPolicies.containsKey(objHIFulfillmentEvent.Id__c + objPolicy.state_carrier_id)) {
					map_StateCarrierIdTOPolicies.get(objHIFulfillmentEvent.Id__c + objPolicy.state_carrier_id).add(objPolicy);
				} else {
					map_StateCarrierIdTOPolicies.put(objHIFulfillmentEvent.Id__c + objPolicy.state_carrier_id, new List<HIFulfillmentEventAuditJSON.policies>{ objPolicy });
				}
			}
		}

		Boolean blnIsBO = false;
		Boolean blnIsCO = false;
		String strRelativeObject = map_MFAuditDescriptions.get(objHIEventInfo.audit_type).Relative_Object__c;
		//checking for mathcing Benefit order and carrier order based on application id and carrier id.
		if (String.isNotBlank(strRelativeObject)) {
			blnIsBO = (strRelativeObject == HIEnrollmentEventUtility.BENEFIT_ORDER);
			blnIsCO = (strRelativeObject == HIEnrollmentEventUtility.CARRIER_ORDER);
		}

		for (String strKey : map_StateCarrierIdTOPolicies.keySet()) {
			Case objCase = new Case();
			Database.DMLOptions objDMLOption = new Database.DMLOptions();
			objDMLOption.assignmentRuleHeader.useDefaultRule = true;
			objCase.setOptions(objDMLOption);

			objCase.Description = !map_EventIdsToCaseWrapper.isEmpty() && map_EventIdsToCaseWrapper.containsKey(strKey) ? map_EventIdsToCaseWrapper.get(strKey).strCaseDescription : '';
			objCase.AccountId = objAccount.id;
			objCase.Type = objHIEventInfo.audit_type;
			if (objHIEventInfo.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)) {
				objCase.First_Response_Time_Deadline__c = objHIEventInfo.deadline_date;
			}

			objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_AUDIT;
			if (objContact != null) {
				objCase.ContactId = objContact.Id;
			}
			objCase.Company_ID__c = String.valueOf(objHIEventInfo.company.Id);
			// generate the integration key from event id and UUID.
			objCase.Integration_Id__c = objHIFulfillmentEvent.Id__c;
			objCase.Integration_Key__c = objHIFulfillmentEvent.Id__c;
			objCase.Selection_UUIDs__c = '';
			objCase.Benefit_Types__c = '';
			String strCarrierId = '';
			Case objExistingCase = new Case();
			String strSearchKey = '';
			for (HIFulfillmentEventAuditJSON.policies objPolicy : map_StateCarrierIdTOPolicies.get(strKey)) {
				objCase.Integration_Id__c += '~' + objPolicy.state_carrier_id;
				objCase.Integration_Key__c += '~' + objPolicy.state_carrier_id;
				strSearchKey = objHIEventInfo.audit_type + '~' + objPolicy.state_carrier_id+ '~' + objHIEventInfo.company.Id;
				if (!map_ExistingCaseWithCarrierId.isEmpty() && map_ExistingCaseWithCarrierId.containsKey(strSearchKey)) {
					if (objExistingCase.Id == null) {
						objExistingCase = map_ExistingCaseWithCarrierId.get(strSearchKey);
					}
				}
				strCarrierId = '' + objPolicy.state_carrier_id;
				if (map_Carriers.containsKey(strCarrierId)) {
					objCase.Carrier__c = map_Carriers.get(strCarrierId).id;
				}
				if (checkValidValue(objHIFulfillmentEvent.Application_Id__c)) {
					if (!map_BenefitOrders.isEmpty() && map_BenefitOrders.containsKey('' + objHIEventInfo.company.id + objHIFulfillmentEvent.Application_Id__c) && (blnIsBO || blnIsCO)) {
						Benefit_Order__c objBenefitOrder = map_BenefitOrders.get('' + objHIEventInfo.company.id + objHIFulfillmentEvent.Application_Id__c);
						objCase.Benefit_Order__c = objBenefitOrder.Id;
					}
					if (blnIsCO) {
						String strCOSearchKey = '';
						strCOSearchKey = objHIEventInfo.company.id + objHIFulfillmentEvent.Application_Id__c + strCarrierId;
						if (map_CarrierOrders.containsKey(strCOSearchKey)) {
							objCase.Carrier_Order__c = map_CarrierOrders.get(strCOSearchKey).Id;
						}
					}
				}
				//Check duplicate Case records
				if (objExistingCase.Id != null) {
					if (objExistingCase.Status != null && set_ClosedCaseStatus.contains(objExistingCase.Status)) {
						objCase.ParentId = objExistingCase.Id;
						objCase.Anticipated_Effective_Date__c = objExistingCase.Anticipated_Effective_Date__c;
						objCase.Special_Instructions__c = objHIEventInfo.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION) ? strReconciliationSpecialInstructions : strSpecialInstructions;
						if(!list_CasesToBeInsert.contains(objExistingCase)) {
							list_CasesToBeInsert.add(objExistingCase);
						}
					} else {
						objCase.Id = objExistingCase.Id;
						objCase.Integration_Id__c = objExistingCase.Integration_Id__c;
						objCase.Integration_Key__c = objExistingCase.Integration_Key__c;
						if (objHIEventInfo.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)) {
							objCase.Special_Instructions__c = strReconciliationSpecialInstructions;
						}
						if (String.isNotBlank(objExistingCase.Benefit_Types__c)) {
							for (String strValue : objExistingCase.Benefit_Types__c.split(';')) {
								if (String.isNotBlank(strValue) && !objCase.Benefit_Types__c.contains(strValue)) {
									objCase.Benefit_Types__c += strValue + ';';
								}
							}
						}

						if (objExistingCase.ParentId != null && objExistingCase.Parent.RecordTypeId == HIEnrollmentEventUtility.CASE_RT_ID_MF_AUDIT) {
							objExistingCase = resetUUIdsInParentCase(
								objCase,
								new Case(
									Id = objExistingCase.ParentId,
									Selection_UUIDs__c = objExistingCase.Parent.Selection_UUIDs__c,
									Integration_Id__c = objExistingCase.Parent.Integration_Id__c,
									Integration_Key__c = objExistingCase.Parent.Integration_Key__c
								),
								objCase.Benefit_Types__c
							);
							if(!list_CasesToBeInsert.contains(objExistingCase)) {
								list_CasesToBeInsert.add(objExistingCase);
							}
						}
					}
				}
				if(!list_CasesToBeInsert.contains(objCase)) {
					list_CasesToBeInsert.add(objCase);
				}
			}
		}
		return list_CasesToBeInsert;
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to reset the Selection UUIDs on Parent Case
	 * @param        String of existing case selection id,
	 *               New case uuid
	 * @return       String of uuids.
	 **/
	public static String resetSelectionUUID(String strSelectionUUID, String strUUID) {
		String strKey = strUUID + ';';

		if (strSelectionUUID.contains(strKey)) {
			strSelectionUUID = strSelectionUUID.replace(strKey, '');
		} else if (strSelectionUUID.contains(strUUID)) {
			strSelectionUUID = strSelectionUUID.replace(strUUID, '');
		}

		strSelectionUUID = strSelectionUUID.trim();

		return strSelectionUUID;
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to reset the uuids on Parent Case
	 * @param        Object of new Case,
	 *               Object of existing Case
	 *               String of Benefit type
	 * @return       Object of parent Case.
	 **/
	public static Case resetUUIdsInParentCase(Case objNewCase, Case objExistingCase, String strBenefitTypes) {
		String strFieldAPI = '';

		if (String.isBlank(strBenefitTypes)) {
			return objExistingCase;
		}

		for (String strType : strBenefitTypes.split(';')) {
			strType = strType.trim();

			if (String.isBlank(strType) || !HIEnrollmentEventUtility.map_BenefitTypesWithFieldAPI.containsKey(strType)) {
				continue;
			}

			if (String.isNotBlank(strType) && HIEnrollmentEventUtility.map_BenefitTypesWithFieldAPI.containsKey(strType)) {
				strFieldAPI = HIEnrollmentEventUtility.map_BenefitTypesWithFieldAPI.get(strType);
				objExistingCase.put(strFieldAPI, '');

				if (String.isNotBlank(objExistingCase.Selection_UUIDs__c)) {
					objExistingCase.Selection_UUIDs__c = resetSelectionUUID(objExistingCase.Selection_UUIDs__c, objNewCase.get(strFieldAPI) + '');
				}
			}
		}

		return objExistingCase;
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to get the map of existing MF Termination cases with selectionIds
	 * @param        Map of Existing Cases with UUIds
	 * 				 Map of SelectionIds With UUIds
	 * @return       Map of uuid with Case.
	 **/
	public static Map<String, Case> fetchMFTerminationCases(
		Map<String, Case> map_ExistingCaseWithUUID,
		Map<String, String> map_SelectionIdsWithUUIds,
		Map<String, Set<String>> map_CompanyEmpIdAndSelectionIds
	) {
		Set<String> set_SelectionIds = map_SelectionIdsWithUUIds?.keySet();

		if (set_SelectionIds == null) {
			return map_ExistingCaseWithUUID;
		}

		String strAuditCasesBaseSOQL = HIEnrollmentEventUtility.MOPS_BASE_QUERY + ' AND RecordTypeId IN :set_MFTerminationRecTypeIds AND ';
		String strWhereClause = '(';

		for (String strSelectionIds : set_SelectionIds) {
			strWhereClause += ' OR Selection_Ids__c like \'%' + strSelectionIds + '%\' ';
		}
		strWhereClause += ')';
		strWhereClause = strWhereClause.replaceFirst('OR', '');
		String strFinalQuery = strAuditCasesBaseSOQL + strWhereClause + ' Order By CreatedDate desc';

		String strUUId = '';
		for (Case objCase : Database.query(strFinalQuery)) {
			if (String.isNotBlank(objCase.Selection_Ids__c)) {
				Set<String> set_SelectionIdFromJSON = map_CompanyEmpIdAndSelectionIds?.get(objCase.ZP_Company_Id__c + objCase.Contact_Employee_Id__c);

				if (set_SelectionIdFromJSON == null) {
					continue;
				}

				Boolean blnExactMatch = true;

				for (String strJSONSelectionId : set_SelectionIdFromJSON) {
					if (!objCase.Selection_Ids__c.contains(strJSONSelectionId)) {
						blnExactMatch = false;
						break;
					}
				}

				if (blnExactMatch) {
					for (String strKey : objCase.Selection_Ids__c.split(';')) {
						if (String.isNotBlank(strKey) && map_SelectionIdsWithUUIds?.containsKey(strKey)) {
							strUUId = map_SelectionIdsWithUUIds?.get(strKey);
							if (!map_ExistingCaseWithUUID?.containsKey(objCase.RecordTypeId + '~' + strUUId)) {
								map_ExistingCaseWithUUID.put(objCase.RecordTypeId + '~' + strUUId, objCase);
							}
						}
					}
				}
			}
		}

		return map_ExistingCaseWithUUID;
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to get the map of existing cases with uuids
	 * @param        Map of uuids With Benefit Type
	 * 				 Set of uuids
	 * @return       Map of uuid with Case.
	 **/
	public static Map<String, Case> fetchCases(Map<String, String> map_UUIDsWithBenefitType, Map<String, String> map_UUIDsWithAuditType) {
		Set<String> set_UUIDs = new Set<String>();
		String strAuditCasesBaseSOQL = HIEnrollmentEventUtility.MOPS_BASE_QUERY + ' AND RecordTypeId IN :set_ValidCaseRecTypeIds ';
		String strWhereClauseForBenefitTypes = '';
		List<String> list_UUIDWhereClauses = new List<String>();
		for (String strUUID : map_UUIDsWithBenefitType.keySet()) {
			String strBenefitType = map_UUIDsWithBenefitType?.get(strUUID);
			if (String.isNotBlank(strBenefitType)) {
				if (strBenefitType.equalsIgnoreCase('fsa')) {
					list_UUIDWhereClauses.add('FSA_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('vision')) {
					list_UUIDWhereClauses.add('Vision_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('life')) {
					list_UUIDWhereClauses.add('Life_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('dental')) {
					list_UUIDWhereClauses.add('Dental_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('medical')) {
					list_UUIDWhereClauses.add('Medical_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('hsa')) {
					list_UUIDWhereClauses.add('HSA_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('dca')) {
					list_UUIDWhereClauses.add('DCA_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('short_term_disability')) {
					list_UUIDWhereClauses.add('Short_Term_Disability_UUID__c IN :set_UUIDs');
				} else if (strBenefitType.equalsIgnoreCase('long_term_disability')) {
					list_UUIDWhereClauses.add('Long_Term_Disability_UUID__c IN :set_UUIDs');
				}
				set_UUIDs.add(strUUID);
			}

			strWhereClauseForBenefitTypes = String.join(list_UUIDWhereClauses, ' OR ');
			if (String.isNotBlank(strWhereClauseForBenefitTypes)) {
				strWhereClauseForBenefitTypes = ' AND (' + strWhereClauseForBenefitTypes + ')';
			}
			String strAuditType = map_UUIDsWithAuditType.get(strUUID);
			set_ValidCaseRecTypeIds.add(HIEnrollmentEventUtility.CASE_RT_ID_MF_AUDIT);
			if (map_MFAuditDescriptions?.containsKey(strAuditType)) {
				String strParentCaseRecordType = map_MFAuditDescriptions?.get(strAuditType)?.Parent_Cases__c;
				// creating the query to fetch the existing cases based in record types.
				if (String.isNotBlank(strParentCaseRecordType)) {
					if (strParentCaseRecordType.containsIgnoreCase(HIEnrollmentEventUtility.MF_TERMINATION)) {
						set_MFTerminationRecTypeIds.add(HIEnrollmentEventUtility.CASE_RT_ID_MF_TERMINATION);
						set_ValidCaseRecTypeIds.add(HIEnrollmentEventUtility.CASE_RT_ID_MF_TERMINATION);
					}

					if (strParentCaseRecordType.containsIgnoreCase(HIEnrollmentEventUtility.MF_NHE)) {
						set_ValidCaseRecTypeIds.add(HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE);
					}

					if (strParentCaseRecordType.containsIgnoreCase(HIEnrollmentEventUtility.MF_QLE)) {
						set_ValidCaseRecTypeIds.add(HIEnrollmentEventUtility.CASE_RT_ID_MF_QLE);
					}
				}
			}
		}

		String strFinalQuery = strAuditCasesBaseSOQL + strWhereClauseForBenefitTypes;
		Set<String> set_AuditType = map_MFAuditDescriptions?.keySet();
		Map<String, Case> map_Cases = new Map<String, Case>();

		if (set_AuditType == null) {
			return map_Cases;
		}

		if (set_UUIDs != null && !set_UUIDs.isEmpty()) {
			for (Case objCase : Database.query(strFinalQuery)) {
				if (set_UUIDs.contains(objCase.Medical_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.Medical_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.Medical_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.Vision_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.Vision_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.Vision_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.Dental_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.Dental_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.Dental_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.Life_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.Life_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.Life_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.Short_Term_Disability_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.Short_Term_Disability_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.Short_Term_Disability_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.Long_Term_Disability_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.Long_Term_Disability_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.Long_Term_Disability_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.HSA_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.HSA_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.HSA_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.FSA_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.FSA_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.FSA_UUID__c, objCase);
					}
				} else if (set_UUIDs.contains(objCase.DCA_UUID__c)) {
					map_Cases.put(objCase.RecordTypeId + '~' + objCase.DCA_UUID__c, objCase);
					if (String.isNotBlank(objCase.Type) && set_AuditType.contains(objCase.Type)) {
						map_Cases.put(objCase.Type + '~' + objCase.DCA_UUID__c, objCase);
					}
				}
			}
		}

		return map_Cases;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to get the map of existing cases with companyId
	 * @param        Map of companiIds With Audit Type
	 * @return       Map of casetype with Case.
	 **/
	public static Map<String, Case> fetchCasesOnCompanyId(Map<String, String> map_StateCarrierIdsWithAuditType) {
		Set<String> set_CarrierIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		List<String> list_AuditType = map_StateCarrierIdsWithAuditType.values();
		String strAuditCasesBaseSOQL = HIEnrollmentEventUtility.MOPS_BASE_QUERY + ' AND RecordTypeId IN :set_ValidCaseRecTypeIds ';
		String str_CarrierIdsWhereClause = ' State_Carrier_Id__c IN : set_CarrierIds AND Account.ZP_Company_ID__c IN : set_CompanyIds ';
		String str_AuditTypeWhereClause = ' Type IN : list_AuditType';

		for (String stateCarrierId : map_StateCarrierIdsWithAuditType.keySet()) {
			set_CarrierIds.add(stateCarrierId.split('~')[0]);
			set_CompanyIds.add(stateCarrierId.split('~')[1]);
		}

		set_ValidCaseRecTypeIds.add(HIEnrollmentEventUtility.CASE_RT_ID_MF_AUDIT);
		String strFinalQuery = strAuditCasesBaseSOQL + ' AND ' + str_CarrierIdsWhereClause + ' AND ' + str_AuditTypeWhereClause;
		Map<String, Case> map_Cases = new Map<String, Case>();

		if (set_CarrierIds != null && !set_CarrierIds.isEmpty()) {
			for (Case objCase : Database.query(strFinalQuery)) {
				if (String.isNotBlank(objCase.Type)) {
					map_Cases.put(objCase.Type + '~' + objCase.State_Carrier_Id__c+ '~' + objCase.Account.ZP_Company_ID__c, objCase);
				}
			}
		}
		return map_Cases;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to set the Case Description.
	 * @param        HIFulfillmentEventAuditJSON,
	 *               Object of HI_Fulfillment_Event__c,
	 *               Map<String,Carrier__c>
	 * @return       map of uuid and Case Descrption
	 **/

	private Map<Integer, String> setCaseDescription(HIFulfillmentEventAuditJSON objHiEventInfoParsed, HI_Fulfillment_Event__c objHIFulfillmentEvent, Map<String, Carrier__c> map_Carriers) {
		Map<Integer, String> map_UUIDToDescriptions = new Map<Integer, String>();
		Map<Integer, String> map_StateCarrierIdToPolicyInfos = new Map<Integer, String>();
		Map<String, HIFulfillmentEventAuditJSON.policies> map_PolicyIds = new Map<String, HIFulfillmentEventAuditJSON.policies>();

		if (objHiEventInfoParsed.policies != null && objHiEventInfoParsed.policies.size() > 0) {
			for (HIFulfillmentEventAuditJSON.policies objPolicy : objHiEventInfoParsed.policies) {
				map_PolicyIds.put('' + objPolicy.id, objPolicy);
			}
		}

		HIFulfillmentEventAuditJSON.work_address objCompanyBenefitAddress = objHiEventInfoParsed.company.benefits_address;

		for (HIFulfillmentEventAuditJSON.item objItem : objHiEventInfoParsed.items) {
			String strCaseDescription = '';
			strCaseDescription = map_MFAuditDescriptions.get(objHiEventInfoParsed.audit_type).Description__c;
			if (objHiEventInfoParsed.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)) {
				strCaseDescription += '\n\n- Reconciliation Link: ' + objHIEventInfoParsed.company.reconciliation_url;
			}
			strCaseDescription += '\n\nCarrier Information : ';

			if (objItem.state_carrier_id != null) {
				Carrier__c objCarrier = map_Carriers.get('' + objItem.state_carrier_id);

				if (objCarrier != null) {
					strCaseDescription += '\n- Carrier : ' + objCarrier.Name;
					strCaseDescription += '\n- Carrier State: ' + objCarrier.State__c;
				}

				if (String.isNotBlank(objItem.url)) {
					strCaseDescription += '\n- url: ' + objItem.url;
				}
			}

			HIFulfillmentEventAuditJSON.home_address objEmployeeHomeAddress = objHIEventInfoParsed.employee.home_address;
			strCaseDescription += '\n- EE Panda Link: ' + objHIEventInfoParsed.employee.panda_url;
			strCaseDescription += '\n- EE Hippo Link: ' + objHIEventInfoParsed.employee.hippo_url;

			strCaseDescription += '\n\nCompany Information : ';
			strCaseDescription +=
				'\n- Company Name: ' +
				objHiEventInfoParsed.company.name +
				'\n- Company Address:' +
				HIFulfillmentEventHelperFunctions.getAddress(
					objCompanyBenefitAddress.street_1,
					objCompanyBenefitAddress.street_2,
					objCompanyBenefitAddress.city,
					objCompanyBenefitAddress.county_name,
					objCompanyBenefitAddress.state,
					objCompanyBenefitAddress.zip,
					objCompanyBenefitAddress.country
				);

			strCaseDescription += '\n\nAudit Information : ';
			strCaseDescription += '\n- Audit Type : ' + objHiEventInfoParsed.audit_type;
			map_UUIDToDescriptions.put(objItem.state_carrier_id, strCaseDescription);
		}

		return map_UUIDToDescriptions;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to set the Case Description.
	 * @param        HIFulfillmentEventAuditJSON,
	 *               Map of string and carrier
	 * @return       case description
	 **/
	private Map<Integer, String> setCaseDescriptionByCompany(HIFulfillmentEventAuditJSON objHiEventInfoParsed, Map<String, Carrier__c> map_Carriers) {
		Map<Integer, String> map_StateCarrieIdToDescriptions = new Map<Integer, String>();
		HIFulfillmentEventAuditJSON.work_address objCompanyBenefitAddress = objHiEventInfoParsed.company.benefits_address;
		if (objHiEventInfoParsed.policies != null && objHiEventInfoParsed.policies.size() > 0) {
			for (HIFulfillmentEventAuditJSON.policies objPolicy : objHiEventInfoParsed.policies) {
				String strCaseDescription = '';
				String strPolicyDescription = '';
				strCaseDescription = map_MFAuditDescriptions.get(objHiEventInfoParsed.audit_type).Description__c;
				if (objHiEventInfoParsed.audit_type.contains(HIEnrollmentEventUtility.RECONCILIATION)) {
					strCaseDescription += '\n\n- Reconciliation Link: ' + objHIEventInfoParsed.company.reconciliation_url;
				}
				strCaseDescription += '\n\nCarrier Information : ';
				if (objPolicy.state_carrier_id != null) {
					Carrier__c objCarrier = map_Carriers.get('' + objPolicy.state_carrier_id);

					if (objCarrier != null) {
						strCaseDescription += '\n- Carrier : ' + objCarrier.Name;
						strCaseDescription += '\n- Carrier State: ' + objCarrier.State__c;
					}

					if (String.isNotBlank(objPolicy.url)) {
						strCaseDescription += '\n- url: ' + objPolicy.url;
					}
				}

				if (objHiEventInfoParsed.employee != null) {
					HIFulfillmentEventAuditJSON.home_address objEmployeeHomeAddress = objHIEventInfoParsed.employee.home_address;
					strCaseDescription +=
						'\n\nEmployee Information' +
						'\n- Name: ' +
						HIFulfillmentEventHelperFunctions.getName(objHIEventInfoParsed.employee.first_name, objHIEventInfoParsed.employee.middle_initial, objHIEventInfoParsed.employee.last_name) +
						'\n- SSN: ' +
						HIFulfillmentEventHelperFunctions.getMaskedSSN('' + objHIEventInfoParsed.employee.ssn) +
						'\n- DOB: ' +
						HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.birthday) +
						'\n- Date of hire: ' +
						HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHIEventInfoParsed.employee.hired_at);

					if (objEmployeeHomeAddress != null) {
						strCaseDescription +=
							'\n- Home Address: ' +
							HIFulfillmentEventHelperFunctions.getAddress(
								objEmployeeHomeAddress.street_1,
								objEmployeeHomeAddress.street_2,
								objEmployeeHomeAddress.city,
								objEmployeeHomeAddress.county_name,
								objEmployeeHomeAddress.state,
								objEmployeeHomeAddress.zip,
								objEmployeeHomeAddress.country
							);
					}
				}

				strCaseDescription += '\n\nCompany Information : ';
				strCaseDescription +=
					'\n- Company Name: ' +
					objHiEventInfoParsed.company.name +
					'\n- Company Address:' +
					HIFulfillmentEventHelperFunctions.getAddress(
						objCompanyBenefitAddress.street_1,
						objCompanyBenefitAddress.street_2,
						objCompanyBenefitAddress.city,
						objCompanyBenefitAddress.county_name,
						objCompanyBenefitAddress.state,
						objCompanyBenefitAddress.zip,
						objCompanyBenefitAddress.country
					);
				strCaseDescription += '\n\nPolicy Information : ';
				strCaseDescription += '\n- Policy Name : ' + objPolicy.name;
				strCaseDescription += '\n- Benefit Type : ' + objPolicy.benefit_type;
				strCaseDescription += '\n- Group ID : ' + objPolicy.group_number;
				strCaseDescription += '\n\nAudit Information : ';
				strCaseDescription += '\n- Audit Type : ' + objHiEventInfoParsed.audit_type;
				map_StateCarrieIdToDescriptions.put(objPolicy.state_carrier_id, strCaseDescription);
			}
		}
		return map_StateCarrieIdToDescriptions;
	}
	/**
	 * @author       Deepika Saini
	 * @description  This method is used to set the Benefit type , uuid and Selection_UUIDs__c of case
	 * @param        instance of case,
	 *               String of Benefit type,
	 *               String of UUId.
	 * @return       Case
	 **/
	public Case setBenefitTypeWithUUID(Case objCase, String strBenefitType, String strUUID) {
		objCase.Selection_UUIDs__c += strUUID + ';';

		switch on strBenefitType {
			when 'dental' {
				objCase.Dental_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL + ';';
				}
			}
			when 'vision' {
				objCase.Vision_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_VISION)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_VISION + ';';
				}
			}
			when 'medical' {
				objCase.Medical_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL + ';';
				}
			}
			when 'long_term_disability' {
				objCase.Long_Term_Disability_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_LTD)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_LTD + ';';
				}
			}
			when 'short_term_disability' {
				objCase.Short_Term_Disability_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_STD)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_STD + ';';
				}
			}
			when 'life' {
				objCase.Life_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE + ';';
				}
			}
			when 'hsa' {
				objCase.HSA_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_HSA)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_HSA.toUpperCase() + ';';
				}
			}
			when 'flexible_spending_account_medical' {
				objCase.FSA_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_FSA)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_FSA.toUpperCase() + ';';
				}
			}
			when 'fsa' {
				objCase.FSA_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_FSA)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_FSA.toUpperCase() + ';';
				}
			}
			when 'flexible_spending_account_dependent_care' {
				objCase.DCA_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_DCA)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_DCA.toUpperCase() + ';';
				}
			}
			when 'dca' {
				objCase.DCA_UUID__c = strUUID;
				if (!objCase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_DCA)) {
					objCase.Benefit_Types__c += HIEnrollmentEventUtility.TAdA_BENEFIT_TYPE_DCA.toUpperCase() + ';';
				}
			}
		}

		return objCase;
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is check input string have some valid values or not
	 * @param        String
	 * @return       Boolean
	 **/
	public Boolean checkValidValue(String strValue) {
		Boolean blnFlag = false;
		if (String.isNotBlank(strValue) && strValue != strNullCheck) {
			blnFlag = true;
		}
		return blnFlag;
	}

	public class caseDataWrapper {
		public String strEventId { get; set; }
		public String strStateCarrierKey { get; set; }
		public String strEventType { get; set; }
		public Long lngZPCompanyId { get; set; }
		public String strEmployeeEmail { get; set; }
		public String strCaseSubject { get; set; }
		public String strCaseDescription { get; set; }
		public HIFulfillmentEventAuditJSON objHIEventInfo { get; set; }
		public String strEmployeeInformation { get; set; }

		public caseDataWrapper(
			String strEventId,
			String strCarrierKey,
			String strEventType,
			Long lngCompanyId,
			String strEmail,
			String strCaseSubj,
			String strCaseDesc,
			HIFulfillmentEventAuditJSON objHIEventInfoParsed,
			String strEmpInfo
		) {
			strEventId = strEventId;
			strStateCarrierKey = strCarrierKey;
			strEventType = strEventType;
			lngZPCompanyId = lngCompanyId;
			strEmployeeEmail = strEmail;
			strCaseSubject = strCaseSubj;
			strCaseDescription = strCaseDesc;
			objHIEventInfo = objHIEventInfoParsed;
			strEmployeeInformation = strEmpInfo;
		}
	}
}