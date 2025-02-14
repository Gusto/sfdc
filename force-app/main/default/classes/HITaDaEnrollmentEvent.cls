/**
 * @name         HITaDaEnrollmentEvent
 * @author       Neha Dabas
 * @date         4th Jan 2021
 * @description  Process Tada Enrollment Events Events and update/create relevant cases.
 * @test class   HITaDaEnrollmentEventTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public class HITaDaEnrollmentEvent {
	static Map<String, HIEnrollmentEventUtility.DependentInfo> map_Dependents = new Map<String, HIEnrollmentEventUtility.DependentInfo>();
	static Map<String, HITaDaEnrollmentEventJSON.Policy> map_PolicyId = new Map<String, HITaDaEnrollmentEventJSON.Policy>();
	static Map<String, HITaDaEnrollmentEventJSON> map_ParsedEventInfo = new Map<String, HITaDaEnrollmentEventJSON>();

	static Map<String, String> map_QLEEventType;
	static map<String, String> map_PIIInfo;
	static Map<String, Carrier__c> map_Carrier = new Map<String, Carrier__c>();

	public static void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvent) {
		List<Exception> list_Exceptions = new List<Exception>();
		Set<String> set_ZPCompanyId = new Set<String>();
		Set<String> set_EmployeeEmail = new Set<String>();
		Set<String> set_StateCarrierKey = new Set<String>();
		Set<String> set_EmployeeIDs = new Set<String>();
		Set<Date> set_StartDate = new Set<Date>();
		Map<String, Account> map_Account = new Map<String, Account>();
		Map<String, Contact> map_Contact = new Map<String, Contact>();
		Map<String, CaseWrapper> map_CaseWrapper = new Map<String, CaseWrapper>();
		Set<String> set_CarrierKey = new Set<String>();

		map_PIIInfo = new Map<String, String>();

		if (list_HIFulfillmentEvent == null || list_HIFulfillmentEvent.isEmpty()) {
			return;
		}

		Map<String, HI_Fulfillment_Event__c> map_ValidEvents = HIEnrollmentEventUtility.validateAndSetProcessingState(list_HIFulfillmentEvent);

		if (map_ValidEvents.isEmpty()) {
			return;
		}

		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
		map_QLEEventType = HIEnrollmentEventUtility.fetchQLEEventTypeMap();

		//Fetch json related data of HI Tada Enrollment event
		for (HI_Fulfillment_Event__c objFulfillmentEvent : map_ValidEvents.values()) {
			HITaDaEnrollmentEventJSON objParsedInfoEvent;
			try {
				Blob blobDecryptedInfo = EncodingUtil.base64Decode(objFulfillmentEvent.Event_Info_Encrypted__c);
				String strDecryptedInfo = EncryptionUtils.getDecryptedText(encryptionKey, blobDecryptedInfo);
				objParsedInfoEvent = getJSONParsedData(strDecryptedInfo);

				if (!validateParsedEventInfo(objParsedInfoEvent, objFulfillmentEvent)) {
					map_ValidEvents.remove(objFulfillmentEvent.Id__c);
					continue;
				}

				//parsed event info for each event
				map_ParsedEventInfo.put(objFulfillmentEvent.Id__c, objParsedInfoEvent);

				set_ZPCompanyId.add(String.valueOf(objParsedInfoEvent.company.id));
				set_EmployeeEmail.add(objParsedInfoEvent.employee.email);
				set_EmployeeIDs.add('' + objParsedInfoEvent.employee.id);
				if (String.isNotBlank(objParsedInfoEvent?.tada?.hsa?.provider_key)) {
					set_CarrierKey.add(objParsedInfoEvent.tada.hsa.provider_key);
				}
				if (String.isNotBlank(objParsedInfoEvent?.tada?.fsa?.provider_key)) {
					set_CarrierKey.add(objParsedInfoEvent.tada.fsa.provider_key);
				}
				if (String.isNotBlank(objParsedInfoEvent?.tada?.dca?.provider_key)) {
					set_CarrierKey.add(objParsedInfoEvent.tada.dca.provider_key);
				}

				if (
					(objParsedInfoEvent?.tada?.hsa != null && String.isBlank(objParsedInfoEvent.tada.hsa.provider_key)) ||
					(objParsedInfoEvent?.tada?.fsa != null && String.isBlank(objParsedInfoEvent.tada.fsa.provider_key)) ||
					(objParsedInfoEvent?.tada?.dca != null && String.isBlank(objParsedInfoEvent.tada.dca.provider_key))
				) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.PROVIDER_KEY_MISSING, objFulfillmentEvent);
					continue;
				}

				if (
					objParsedInfoEvent?.tada?.fsa != null &&
					objParsedInfoEvent.tada.fsa.benefit_items == null &&
					objParsedInfoEvent?.tada?.dca != null &&
					objParsedInfoEvent.tada.dca.benefit_items == null
				) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.BENEFIT_ITEM_MISSING, objFulfillmentEvent);
					continue;
				}
			} catch (JSONException objJSONExcep) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objFulfillmentEvent);
			} catch (Exception e) {
				list_Exceptions.add(e);
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EXCEPTION_WHILE_PROCESSING, objFulfillmentEvent);
			}
		}

		if (!set_CarrierKey.isEmpty()) {
			map_Carrier = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKey);
		}

		for (HI_Fulfillment_Event__c objFulfillmentEvent : map_ValidEvents.values()) {
			HITaDaEnrollmentEventJSON objParsedInfoEvent;
			try {
				if (objFulfillmentEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objFulfillmentEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
					continue;
				}

				Blob blobDecryptedInfo = EncodingUtil.base64Decode(objFulfillmentEvent.Event_Info_Encrypted__c);
				String strDecryptedInfo = EncryptionUtils.getDecryptedText(encryptionKey, blobDecryptedInfo);
				objParsedInfoEvent = getJSONParsedData(strDecryptedInfo);

				//dependent id => dependentInfo
				map_Dependents = HIEnrollmentEventUtility.getDependentsMap(objParsedInfoEvent.dependents);
				//PII information for each employee
				String strPIIInfo = HIEnrollmentEventUtility.getPIIInformation(objParsedInfoEvent.employee, objParsedInfoEvent.dependents);

				String strFSADCADescription = '', strHSADescription = '', strCaseDescription = '', strOpsOwner = '', strStartDate = '';
				Date dtStartDate;
				//General case description
				//strCaseDescription = getCaseDescription(objParsedInfoEvent);

				List<HIEnrollmentEventUtility.DependentInfo> list_Dependents = new List<HIEnrollmentEventUtility.DependentInfo>();
				Set<HITaDaEnrollmentEventJSON.SubscriptionInfo> set_CurrentSubscriptions = new Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>(),
					set_OverlappingSubscriptions = new Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>();
				Map<String, Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>> map_CurrentSubscriptions = new Map<String, Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>>();
				Map<String, Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>> map_OverlappingSubscriptions = new Map<String, Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>>();

				Boolean blnFSABenefitItemPresent = false;
				Boolean blnDCABenefitItemPresent = false;
				Boolean blnBenefitItemPresent = false;
				//Segregate Current and overlapping subscription info and dependent info for FSA & DCA
				if (objParsedInfoEvent.tada.fsa != null || objParsedInfoEvent.tada.dca != null) {
					if (objParsedInfoEvent.tada.fsa != null) {
						set_CurrentSubscriptions = map_CurrentSubscriptions.containsKey(objParsedInfoEvent.tada.fsa.provider_key)
							? map_CurrentSubscriptions.get(objParsedInfoEvent.tada.fsa.provider_key)
							: new Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>();
						set_OverlappingSubscriptions = map_OverlappingSubscriptions.containsKey(objParsedInfoEvent.tada.fsa.provider_key)
							? map_OverlappingSubscriptions.get(objParsedInfoEvent.tada.fsa.provider_key)
							: new Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>();
						if (objParsedInfoEvent.tada.fsa.policies != null && !objParsedInfoEvent.tada.fsa.policies.isEmpty()) {
							for (HITaDaEnrollmentEventJSON.Policy objPolicy : objParsedInfoEvent.tada.fsa.policies) {
								map_PolicyId.put(String.valueOf(objPolicy.id), objPolicy);
							}
						}
						if (objParsedInfoEvent.tada.fsa.benefit_items != null) {
							if (objParsedInfoEvent.tada.fsa.benefit_items.current != null) {
								set_CurrentSubscriptions.add(objParsedInfoEvent.tada.fsa.benefit_items.current);
							}
							if (objParsedInfoEvent.tada.fsa.benefit_items.overlapping != null && !objParsedInfoEvent.tada.fsa.benefit_items.overlapping.isEmpty()) {
								set_OverlappingSubscriptions.addAll(objParsedInfoEvent.tada.fsa.benefit_items.overlapping);
							}
						}
						map_CurrentSubscriptions.put(objParsedInfoEvent.tada.fsa.provider_key, set_CurrentSubscriptions);
						map_OverlappingSubscriptions.put(objParsedInfoEvent.tada.fsa.provider_key, set_OverlappingSubscriptions);
					}
					if (objParsedInfoEvent.tada.dca != null) {
						set_CurrentSubscriptions = map_CurrentSubscriptions.containsKey(objParsedInfoEvent.tada.dca.provider_key)
							? map_CurrentSubscriptions.get(objParsedInfoEvent.tada.dca.provider_key)
							: new Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>();
						set_OverlappingSubscriptions = map_OverlappingSubscriptions.containsKey(objParsedInfoEvent.tada.dca.provider_key)
							? map_OverlappingSubscriptions.get(objParsedInfoEvent.tada.dca.provider_key)
							: new Set<HITaDaEnrollmentEventJSON.SubscriptionInfo>();
						if (objParsedInfoEvent.tada.dca.policies != null && !objParsedInfoEvent.tada.dca.policies.isEmpty()) {
							for (HITaDaEnrollmentEventJSON.Policy objPolicy : objParsedInfoEvent.tada.dca.policies) {
								map_PolicyId.put(String.valueOf(objPolicy.id), objPolicy);
							}
						}
						if (objParsedInfoEvent.tada.dca.benefit_items != null) {
							if (objParsedInfoEvent.tada.dca.benefit_items.current != null) {
								set_CurrentSubscriptions.add(objParsedInfoEvent.tada.dca.benefit_items.current);
							}
							if (objParsedInfoEvent.tada.dca.benefit_items.overlapping != null && !objParsedInfoEvent.tada.dca.benefit_items.overlapping.isEmpty()) {
								set_OverlappingSubscriptions.addAll(objParsedInfoEvent.tada.dca.benefit_items.overlapping);
							}
						}
						map_CurrentSubscriptions.put(objParsedInfoEvent.tada.dca.provider_key, set_CurrentSubscriptions);
						map_OverlappingSubscriptions.put(objParsedInfoEvent.tada.dca.provider_key, set_OverlappingSubscriptions);
					}

					if (objParsedInfoEvent.tada.fsa != null) {
						if (objParsedInfoEvent.tada.fsa.benefit_items != null) {
							if (objParsedInfoEvent.tada.fsa.benefit_items.current != null) {
								blnFSABenefitItemPresent = true;
								if (String.isNotBlank(objParsedInfoEvent.tada.fsa.benefit_items.current.estimated_start_date)) {
									strStartDate = objParsedInfoEvent.tada.fsa.benefit_items.current.estimated_start_date;
									dtStartDate = Date.valueOf(strStartDate);

									set_StartDate.add(dtStartDate);
								}

								if (
									map_Dependents != null &&
									!map_Dependents.isEmpty() &&
									objParsedInfoEvent.tada.fsa.benefit_items.current.dependent_ids != null &&
									!objParsedInfoEvent.tada.fsa.benefit_items.current.dependent_ids.isEmpty()
								) {
									for (String strDepId : objParsedInfoEvent.tada.fsa.benefit_items.current.dependent_ids) {
										if (map_Dependents.containsKey(strDepId)) {
											list_Dependents.add(map_Dependents.get(strDepId));
										}
									}
								}

								strOpsOwner = objParsedInfoEvent.tada.fsa.benefit_items.current.ops_owner;
							}
							if (objParsedInfoEvent.tada.fsa.benefit_items.overlapping != null && !objParsedInfoEvent.tada.fsa.benefit_items.overlapping.isEmpty()) {
								blnFSABenefitItemPresent = true;

								if (String.isBlank(strStartDate) && String.isNotBlank(objParsedInfoEvent.tada.fsa.benefit_items.overlapping[0].start_date)) {
									strStartDate = objParsedInfoEvent.tada.fsa.benefit_items.overlapping[0].start_date;
									dtStartDate = Date.valueOf(strStartDate);
									set_StartDate.add(dtStartDate);
								}
							}
							if (objParsedInfoEvent.tada.fsa.benefit_items.previous != null && !objParsedInfoEvent.tada.fsa.benefit_items.previous.isEmpty()) {
								blnFSABenefitItemPresent = true;

								if (String.isBlank(strStartDate) && String.isNotBlank(objParsedInfoEvent.tada.fsa.benefit_items.previous[0].start_date)) {
									strStartDate = objParsedInfoEvent.tada.fsa.benefit_items.previous[0].start_date;
									dtStartDate = Date.valueOf(strStartDate);
									set_StartDate.add(dtStartDate);
								}
							}
						}
						if (blnFSABenefitItemPresent) {
							strFSADCADescription = getFSADCADescription(
								map_CurrentSubscriptions.get(objParsedInfoEvent.tada.fsa.provider_key),
								map_OverlappingSubscriptions.get(objParsedInfoEvent.tada.fsa.provider_key)
							);
							//case wrap with details for FSA and DCA Benefit Types
							CaseWrapper objWrap = new CaseWrapper(
								'',
								strFSADCADescription,
								strOpsOwner,
								null,
								objParsedInfoEvent.tada.fsa,
								null,
								HIEnrollmentEventUtility.ALEGEUS_FULFILLMENT_TYPE_FSA_DCA,
								objFulfillmentEvent.Id__c,
								String.valueOf(objParsedInfoEvent.employee.id),
								String.valueOf(objParsedInfoEvent.company.id),
								dtStartDate,
								strPIIInfo
							);

							String strKey =
								objParsedInfoEvent.employee.id +
								'~~' +
								HIEnrollmentEventUtility.ALEGEUS_FULFILLMENT_TYPE_FSA_DCA +
								'~~' +
								strStartDate +
								'~~' +
								objParsedInfoEvent.tada.fsa.provider_key +
								'>>FSA';
							map_CaseWrapper.put(strKey, objWrap);
						}
					}
					if (objParsedInfoEvent.tada.dca != null) {
						if (objParsedInfoEvent.tada.dca.benefit_items != null) {
							if (objParsedInfoEvent.tada.dca.benefit_items.current != null) {
								blnDCABenefitItemPresent = true;
								if (String.isNotBlank(objParsedInfoEvent.tada.dca.benefit_items.current.estimated_start_date)) {
									strStartDate = objParsedInfoEvent.tada.dca.benefit_items.current.estimated_start_date;
									dtStartDate = Date.valueOf(strStartDate);

									set_StartDate.add(dtStartDate);
								}

								if (
									map_Dependents != null &&
									!map_Dependents.isEmpty() &&
									objParsedInfoEvent.tada.dca.benefit_items.current.dependent_ids != null &&
									!objParsedInfoEvent.tada.dca.benefit_items.current.dependent_ids.isEmpty()
								) {
									for (String strDepId : objParsedInfoEvent.tada.dca.benefit_items.current.dependent_ids) {
										if (map_Dependents.containsKey(strDepId)) {
											list_Dependents.add(map_Dependents.get(strDepId));
										}
									}
								}

								if (String.isBlank(strOpsOwner)) {
									strOpsOwner = objParsedInfoEvent.tada.dca.benefit_items.current.ops_owner;
								}
							}
							if (objParsedInfoEvent.tada.dca.benefit_items.overlapping != null && objParsedInfoEvent.tada.dca.benefit_items.overlapping.size() > 0) {
								blnDCABenefitItemPresent = true;

								if (String.isBlank(strStartDate) && String.isNotBlank(objParsedInfoEvent.tada.dca.benefit_items.overlapping[0].start_date)) {
									strStartDate = objParsedInfoEvent.tada.dca.benefit_items.overlapping[0].start_date;
									dtStartDate = Date.valueOf(strStartDate);
									set_StartDate.add(dtStartDate);
								}
							}
							if (objParsedInfoEvent.tada.dca.benefit_items.previous != null && !objParsedInfoEvent.tada.dca.benefit_items.previous.isEmpty()) {
								blnDCABenefitItemPresent = true;

								if (String.isBlank(strStartDate) && String.isNotBlank(objParsedInfoEvent.tada.dca.benefit_items.previous[0].start_date)) {
									strStartDate = objParsedInfoEvent.tada.dca.benefit_items.previous[0].start_date;
									dtStartDate = Date.valueOf(strStartDate);
									set_StartDate.add(dtStartDate);
								}
							}
						}

						if (blnDCABenefitItemPresent) {
							strFSADCADescription = getFSADCADescription(
								map_CurrentSubscriptions.get(objParsedInfoEvent.tada.dca.provider_key),
								map_OverlappingSubscriptions.get(objParsedInfoEvent.tada.dca.provider_key)
							);
							//case wrap with details for FSA and DCA Benefit Types
							CaseWrapper objWrap = new CaseWrapper(
								'',
								strFSADCADescription,
								strOpsOwner,
								null,
								null,
								objParsedInfoEvent.tada.dca,
								HIEnrollmentEventUtility.ALEGEUS_FULFILLMENT_TYPE_FSA_DCA,
								objFulfillmentEvent.Id__c,
								String.valueOf(objParsedInfoEvent.employee.id),
								String.valueOf(objParsedInfoEvent.company.id),
								dtStartDate,
								strPIIInfo
							);

							String strKey =
								objParsedInfoEvent.employee.id +
								'~~' +
								HIEnrollmentEventUtility.ALEGEUS_FULFILLMENT_TYPE_FSA_DCA +
								'~~' +
								strStartDate +
								'~~' +
								objParsedInfoEvent.tada.dca.provider_key +
								'>>DCA';
							map_CaseWrapper.put(strKey, objWrap);
						}
					} else if ((objParsedInfoEvent.tada.dca != null && !blnDCABenefitItemPresent) || (objParsedInfoEvent.tada.fsa != null && !blnFSABenefitItemPresent)) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIEnrollmentEventUtility.FSA_HSA_MISSING, objFulfillmentEvent);
					}
				}

				//process HSA Benefit
				if (objParsedInfoEvent.tada.hsa != null && objParsedInfoEvent.tada.hsa.hsa_benefit != null) {
					if (String.isNotBlank(objParsedInfoEvent.tada.hsa.hsa_benefit.effective_date)) {
						set_StartDate.add(Date.valueOf(objParsedInfoEvent.tada.hsa.hsa_benefit.effective_date));
					}
					strHSADescription = getHSADescription(objParsedInfoEvent.tada.hsa);
					Date dtEffectiveDate = String.isNotBlank(objParsedInfoEvent?.tada?.hsa?.hsa_benefit?.effective_date) ? Date.valueOf(objParsedInfoEvent.tada.hsa.hsa_benefit.effective_date) : null;

					CaseWrapper objWrap = new CaseWrapper(
						strHSADescription,
						'',
						objParsedInfoEvent?.tada?.hsa?.hsa_selection?.ops_owner,
						objParsedInfoEvent?.tada?.hsa,
						null,
						null,
						HIEnrollmentEventUtility.ALEGEUS_FULFILLMENT_TYPE_HSA,
						objFulfillmentEvent.Id__c,
						String.valueOf(objParsedInfoEvent.employee.id),
						String.valueOf(objParsedInfoEvent.company.id),
						dtEffectiveDate,
						strPIIInfo
					);

					String strKey =
						objParsedInfoEvent.employee.id +
						'~~' +
						HIEnrollmentEventUtility.ALEGEUS_FULFILLMENT_TYPE_HSA +
						'~~' +
						objParsedInfoEvent.tada.hsa.hsa_benefit.effective_date +
						'~~' +
						objParsedInfoEvent.tada.hsa.provider_key;
					map_CaseWrapper.put(strKey, objWrap);
				} else if (!blnBenefitItemPresent) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIEnrollmentEventUtility.FSA_HSA_MISSING, objFulfillmentEvent);
				}
			} catch (JSONException objJSONExcep) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objFulfillmentEvent);
			} catch (Exception e) {
				list_Exceptions.add(e);
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EXCEPTION_WHILE_PROCESSING, objFulfillmentEvent);
			}
		}
		try {
			if (!set_CarrierKey.isEmpty()) {
				map_Carrier = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKey);
			}
			if (!set_ZPCompanyId.isEmpty()) {
				map_Account = HIFulfillmentEventHelperFunctions.getAccounts(set_ZPCompanyId);
			}
			if (!set_EmployeeEmail.isEmpty()) {
				map_Contact = HIFulfillmentEventHelperFunctions.getContacts(set_EmployeeEmail);

				map_Contact = HIEnrollmentEventUtility.processContactInformation(
					list_HIFulfillmentEvent,
					null,
					map_ParsedEventInfo,
					map_Account,
					map_Contact,
					set_EmployeeEmail,
					HIEnrollmentEventUtility.ETYPE_TADA_ENR_READY_FOR_PROCESSING
				);
			}
			Map<String, Case> map_ExistingCases = fetchExistingCases(set_EmployeeIDs, set_StartDate);

			List<Case> list_CasesToUpsert = createOrUpdateCases(map_ValidEvents, map_ExistingCases, map_Account, map_Contact, map_CaseWrapper);
			if (!list_CasesToUpsert.isEmpty()) {
				HIEnrollmentEventUtility.upsertCasesAndSetProcessingState(map_ValidEvents.values(), list_CasesToUpsert, 'HITaDaEnrollmentEvent-processInformation');
				HIEnrollmentEventUtility.createAttachment(list_CasesToUpsert, map_PIIInfo);
			}

			for (String strKey : map_CaseWrapper.keySet()) {
				CaseWrapper objWrapper = map_CaseWrapper.get(strKey);
				if (HIEnrollmentEventUtility.OPS_OWNER_NEW_RENWALS.equalsIgnoreCase(objWrapper.strOpsOwner)) {
					if (map_ValidEvents.containsKey(objWrapper.strHIEventId)) {
						HI_Fulfillment_Event__c objFulfillmentEvent = map_ValidEvents.get(objWrapper.strHIEventId);
						objFulfillmentEvent.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
						objFulfillmentEvent.Message__c = HIEnrollmentEventUtility.TADA_ENROLLMENT_RFP_MSG;
					}
				}
			}
		} catch (Exception e) {
			list_Exceptions.add(e);
		}
		//insert Exception log for Exceptions
		if (!list_Exceptions.isEmpty()) {
			ExceptionLogUtil.logException('Error', 'HITaDaEnrollmentEvent', 'processInformation', list_Exceptions);
		}
	}
	/*
	 * Copy Event info to new/existing cases
	 */
	static List<Case> createOrUpdateCases(
		Map<String, HI_Fulfillment_Event__c> map_HIEvents,
		Map<String, Case> map_ExistingCases,
		Map<String, Account> map_Account,
		Map<String, Contact> map_Contact,
		Map<String, CaseWrapper> map_CaseWrapper
	) {
		Map<String, Case> map_CasesToUpsert = new Map<String, Case>();
		Database.DMLOptions objDMLOption = new Database.DMLOptions();
		objDMLOption.assignmentRuleHeader.useDefaultRule = true;
		for (String strKey : map_CaseWrapper.keySet()) {
			CaseWrapper objWrap = map_CaseWrapper.get(strKey);
			if (HIEnrollmentEventUtility.OPS_OWNER_NEW_RENWALS.equalsIgnoreCase(objWrap.strOpsOwner)) {
				continue;
			}
			HITaDaEnrollmentEventJSON objParsedEventInfo = map_ParsedEventInfo.get(objWrap.strHIEventId);
			Case objCase;
			String strTempKey = strKey;
			if (strTempKey.contains('>>DCA')) {
				strTempKey = strTempKey.removeEndIgnoreCase('>>DCA');
			}
			if (strTempKey.contains('>>FSA')) {
				strTempKey = strTempKey.removeEndIgnoreCase('>>FSA');
			}
			if (map_ExistingCases != null && map_ExistingCases.containsKey(strTempKey)) {
				objCase = map_ExistingCases.get(strTempKey);
			} else {
				objCase = new Case();
				objCase.Anticipated_Effective_Date__c = objWrap.dtEffectiveDate;
				objCase.MF_Coverage_Start_Date__c = objCase.Anticipated_Effective_Date__c;

				objCase.Enrollment_Source__c = HIEnrollmentEventUtility.EVENT_SOURCE_NHE;

				if (
					objParsedEventInfo.enrollment_source != null &&
					String.isNotBlank(objParsedEventInfo.enrollment_source.type) &&
					!HIEnrollmentEventUtility.UNKNOWN_SOURCE.equalsIgnoreCase(objParsedEventInfo.enrollment_source.type)
				)
					objCase.Enrollment_Source__c = objParsedEventInfo.enrollment_source.type;

				objCase.Selection_UUIDs__c = '';
				objCase.Subscription_Information__c = '';
				objCase.Enrollment_Id__c = '' + objParsedEventInfo.enrollment.id;

				if (
					HIEnrollmentEventUtility.EVENT_SOURCE_NHE.equalsIgnoreCase(objCase.Enrollment_Source__c) ||
					HIEnrollmentEventUtility.EVENT_SOURCE_OPEN_ENROLLMENT.equalsIgnoreCase(objCase.Enrollment_Source__c)
				) {
					objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE;
					objCase.Type = 'NHE';
				} else if (HIEnrollmentEventUtility.EVENT_SOURCE_QLE.equalsIgnoreCase(objCase.Enrollment_Source__c)) {
					objCase.RecordTypeId = HIEnrollmentEventUtility.CASE_RT_ID_MF_QLE;
					objCase.Type = 'QLE';
				}

				objCase.Fulfillment_Type__c = objWrap.strBenefitType;
				objCase.setOptions(objDMLOption);
			}
			if (
				HIEnrollmentEventUtility.EVENT_SOURCE_QLE.equalsIgnoreCase(objCase.Enrollment_Source__c) &&
				!map_QLEEventType.isEmpty() &&
				String.isNotBlank(objParsedEventInfo.enrollment_source.event_type) &&
				map_QLEEventType.containsKey(objParsedEventInfo.enrollment_source.event_type)
			) {
				objCase.QLE_Event_Type__c = map_QLEEventType.get(objParsedEventInfo.enrollment_source.event_type);
			}

			if (String.isBlank(objCase.Benefit_Types__c)) {
				objCase.Benefit_Types__c = '';
			} else if (objCase.Benefit_Types__c.right(1) != ';') {
				objCase.Benefit_Types__c += ';';
			}
			if (String.isBlank(objCase.Fulfillment_Sub_Type__c)) {
				objCase.Fulfillment_Sub_Type__c = '';
			} else if (objCase.Fulfillment_Sub_Type__c.right(1) != ';') {
				objCase.Fulfillment_Sub_Type__c += ';';
			}
			map_PIIInfo.put(objCase.Integration_Key__c, objWrap.strPIIInformation);
			String strContactKey = objWrap.strCompanyId + '-' + objParsedEventInfo.employee.email;
			objCase.Employee_Id__c = objWrap.strEmployeeId;
			objCase.ContactId = (map_Contact != null && map_Contact.containsKey(strContactKey)) ? map_Contact.get(strContactKey).Id : null;
			objCase.AccountId = (map_Account != null && map_Account.containsKey(objWrap.strCompanyId)) ? map_Account.get(objWrap.strCompanyID).Id : null;

			if (objWrap.objFSA != null && objWrap.objFSA.benefit_items != null && objWrap.objFSA.benefit_items.current != null && objWrap.objFSA.provider_key != null) {
				Case objFSACase = new Case();
				if (map_CasesToUpsert != null && map_CasesToUpsert.containsKey(strTempKey)) {
					objFSACase = map_CasesToUpsert.get(strTempKey);
				} else {
					objFSACase = objCase;
					String strCaseDescription = getCaseDescription(objParsedEventInfo, objWrap.objFSA.provider_key);
					objFSACase.Description = strCaseDescription;
					objFSACase.Integration_Key__c = objWrap.strHIEventId + '-' + objWrap.objFSA.provider_key;
					objFSACase.Integration_Id__c = objWrap.strHIEventId + '-' + objWrap.objFSA.provider_key;
					objFSACase.Enrollment_Key__c = objParsedEventInfo.enrollment.id + '-' + objWrap.objFSA.provider_key;
				}

				if (!objFSACase.Description.containsIgnoreCase(objWrap.strFSADCADescription)) {
					objFSACase.Description += objWrap.strFSADCADescription;
				}
				objFSACase.FSA_UUID__c = objWrap.objFSA.benefit_items.current.uuid;
				if (String.isNotBlank(objFSACase.Selection_UUIDs__c) && !objFSACase.Selection_UUIDs__c.containsIgnoreCase(objFSACase.FSA_UUID__c)) {
					objFSACase.Selection_UUIDs__c += objFSACase.FSA_UUID__c + ';';
				}

				if (!objFSACase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA)) {
					objFSACase.Benefit_Types__c += HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA + ';';
				}
				if (!objFSACase.Fulfillment_Sub_Type__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA)) {
					objFSACase.Fulfillment_Sub_Type__c += HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA + ';';
				}
				if (!objFSACase.Enrollment_Key__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA)) {
					objFSACase.Enrollment_Key__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA + ';';
				}
				if (!objFSACase.Integration_Key__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA)) {
					objFSACase.Integration_Key__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA + ';';
				}
				if (!objFSACase.Integration_Id__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA)) {
					objFSACase.Integration_Id__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_FSA + ';';
				}
				objFSACase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(objWrap.objFSA.provider_key)) ? map_Carrier.get(objWrap.objFSA.provider_key).Id : null;
				map_CasesToUpsert.put(strTempKey, objFSACase);
				map_ExistingCases.put(strTempKey, objFSACase);
			}
			if (objWrap.objHSA != null && objWrap.objHSA.hsa_selection != null && objWrap.objHSA.provider_key != null) {
				Case objHSACase = new Case();
				if (map_CasesToUpsert != null && map_CasesToUpsert.containsKey(strTempKey)) {
					objHSACase = map_CasesToUpsert.get(strTempKey);
				} else {
					objHSACase = objCase;
					String strCaseDescription = getCaseDescription(objParsedEventInfo, objWrap.objHSA.provider_key);
					objHSACase.Description = strCaseDescription;
					objHSACase.Integration_Key__c = objWrap.strHIEventId + '-' + objWrap.objHSA.provider_key;
					objHSACase.Integration_Id__c = objWrap.strHIEventId + '-' + objWrap.objHSA.provider_key;
					objHSACase.Enrollment_Key__c = objParsedEventInfo.enrollment.id + '-' + objWrap.objHSA.provider_key;
				}

				if (!objHSACase.Description.containsIgnoreCase(objWrap.strHSADescription)) {
					objHSACase.Description += objWrap.strHSADescription;
				}
				objHSACase.HSA_UUID__c = objWrap.objHSA.hsa_selection.uuid;

				if (!objHSACase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA)) {
					objHSACase.Benefit_Types__c += HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA + ';';
				}
				if (!objHSACase.Fulfillment_Sub_Type__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA)) {
					objHSACase.Fulfillment_Sub_Type__c += HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA + ';';
				}
				if (!objHSACase.Enrollment_Key__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA)) {
					objHSACase.Enrollment_Key__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA + ';';
				}
				if (!objHSACase.Integration_Key__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA)) {
					objHSACase.Integration_Key__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA + ';';
				}
				if (!objHSACase.Integration_Id__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA)) {
					objHSACase.Integration_Id__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_HSA + ';';
				}
				objHSACase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(objWrap.objHSA.provider_key)) ? map_Carrier.get(objWrap.objHSA.provider_key).Id : null;
				map_CasesToUpsert.put(strTempKey, objHSACase);
				map_ExistingCases.put(strTempKey, objHSACase);
			}
			if (objWrap.objDCA != null && objWrap.objDCA.benefit_items != null && objWrap.objDCA.benefit_items.current != null && objWrap.objDCA.provider_key != null) {
				Case objDCACase = new Case();
				if (map_CasesToUpsert != null && map_CasesToUpsert.containsKey(strTempKey)) {
					objDCACase = map_CasesToUpsert.get(strTempKey);
				} else {
					objDCACase = objCase;
					String strCaseDescription = getCaseDescription(objParsedEventInfo, objWrap.objDCA.provider_key);
					objDCACase.Description = strCaseDescription;
					objDCACase.Integration_Key__c = objWrap.strHIEventId + '-' + objWrap.objDCA.provider_key;
					objDCACase.Integration_Id__c = objWrap.strHIEventId + '-' + objWrap.objDCA.provider_key;
					objDCACase.Enrollment_Key__c = objParsedEventInfo.enrollment.id + '-' + objWrap.objDCA.provider_key;
				}

				if (!objDCACase.Description.containsIgnoreCase(objWrap.strFSADCADescription)) {
					objDCACase.Description += objWrap.strFSADCADescription;
				}
				objDCACase.DCA_UUID__c = objWrap.objDCA.benefit_items.current.uuid;
				if (String.isNotBlank(objDCACase.Selection_UUIDs__c) && !objDCACase.Selection_UUIDs__c.containsIgnoreCase(objDCACase.DCA_UUID__c)) {
					objDCACase.Selection_UUIDs__c += objDCACase.DCA_UUID__c + ';';
				}
				if (!objDCACase.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA)) {
					objDCACase.Benefit_Types__c += HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA + ';';
				}
				if (!objDCACase.Fulfillment_Sub_Type__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA)) {
					objDCACase.Fulfillment_Sub_Type__c += HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA + ';';
				}
				if (!objDCACase.Enrollment_Key__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA)) {
					objDCACase.Enrollment_Key__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA + ';';
				}
				if (!objDCACase.Integration_Key__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA)) {
					objDCACase.Integration_Key__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA + ';';
				}
				if (!objDCACase.Integration_Id__c.containsIgnoreCase(HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA)) {
					objDCACase.Integration_Id__c += '-' + HIEnrollmentEventUtility.ALEGEUS_BENEFIT_TYPE_DCA + ';';
				}

				objDCACase.Carrier__c = (map_Carrier != null && map_Carrier.containsKey(objWrap.objDCA.provider_key)) ? map_Carrier.get(objWrap.objDCA.provider_key).Id : null;
				map_CasesToUpsert.put(strTempKey, objDCACase);
				map_ExistingCases.put(strTempKey, objDCACase);
			}
		}
		return map_CasesToUpsert.values();
	}
	//check wheather the parsed data is valid or not
	private static Boolean validateParsedEventInfo(HITaDaEnrollmentEventJSON objParsedInfoEvent, HI_Fulfillment_Event__c objFulfillmentEvent) {
		// if JSON is Blank
		if (objParsedInfoEvent == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.JSON_IS_INVALID, objFulfillmentEvent);
			return false;
		}
		//if Company id is blank in the JSON
		if (objParsedInfoEvent.company.id == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING, objFulfillmentEvent);
			return false;
		}

		//if Employee Email id is blank
		if (objParsedInfoEvent.employee.email == null || objParsedInfoEvent.employee.email == '') {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.EMAIL_ID_IS_MISSING, objFulfillmentEvent);
			return false;
		}
		if (objParsedInfoEvent.tada == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.ALEGEUS_INFO_MISSING, objFulfillmentEvent);
			return false;
		}
		if (objParsedInfoEvent.tada.fsa == null && objParsedInfoEvent.tada.dca == null && objParsedInfoEvent.tada.hsa == null) {
			HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.FSA_HSA_MISSING, objFulfillmentEvent);
			return false;
		}
		return true;
	}
	//Parse JSON
	static HITaDaEnrollmentEventJSON getJSONParsedData(String strJSONData) {
		HITaDaEnrollmentEventJSON objParsedData = (HITaDaEnrollmentEventJSON) JSON.deserialize(strJSONData, HITaDaEnrollmentEventJSON.class);
		return objParsedData;
	}
	/*
	 * Get existing Open Alegeus cases for Employee and Anitcipated Effective date combination
	 */
	static Map<String, Case> fetchExistingCases(Set<String> set_EmployeeIds, Set<Date> set_StartDate) {
		Map<String, Case> map_ExistingCases = new Map<String, Case>();
		Set<String> set_CarrierKey = new Set<String>();
		if (!map_Carrier.isEmpty()) {
			set_CarrierKey = map_Carrier.keySet();
		}

		if (!set_EmployeeIds.isEmpty() && !set_StartDate.isEmpty() && !set_CarrierKey.isEmpty()) {
			for (Case objCase : [
				SELECT
					Status,
					Medical_UUID__c,
					Life_UUID__c,
					Dental_UUID__c,
					Long_Term_Disability_UUID__c,
					Short_Term_Disability_UUID__c,
					Vision_UUID__c,
					Integration_Key__c,
					Employee_Id__c,
					Anticipated_Effective_Date__c,
					Selection_UUIDs__c,
					Benefit_Types__c,
					Subscription_Information__c,
					Description,
					Fulfillment_Type__c,
					Fulfillment_Sub_Type__c,
					Enrollment_Source__c,
					Enrollment_Key__c,
					Enrollment_Id__c,
					Carrier__r.Key__c,
					Carrier__c,
					Integration_Id__c
				FROM Case
				WHERE
					Integration_Key__c != NULL
					AND Carrier__c != NULL
					AND Employee_Id__c != NULL
					AND RecordType.Name IN :HIEnrollmentEventUtility.set_ValidCaseRecTypes
					AND Status IN :HIEnrollmentEventUtility.set_UnsubmittedCaseStatuses
					AND Carrier__r.Key__c IN :set_CarrierKey
					AND Employee_Id__c IN :set_EmployeeIds
					AND Anticipated_Effective_Date__c IN :set_StartDate
			]) {
				String strStartDate = String.valueOf(objCase.Anticipated_Effective_Date__c).removeEnd(' 00:00:00');
				String strKey = objCase.Employee_Id__c + '~~' + objCase.Fulfillment_Type__c + '~~' + strStartDate + '~~' + objCase.Carrier__r.Key__c;
				map_ExistingCases.put(strKey, objCase);
			}
		}
		return map_ExistingCases;
	}
	/*
	 * Construct FSA/DCA Description based on Subscription Info
	 */
	static String getFSADCADescription(Set<HITaDaEnrollmentEventJSON.SubscriptionInfo> set_CurrentSubscriptions, Set<HITaDaEnrollmentEventJSON.SubscriptionInfo> set_OverlappingSubscriptions) {
		String strDescription = '';

		if (!set_CurrentSubscriptions.isEmpty()) {
			strDescription += HIEnrollmentEventUtility.NEW_SUBSCRIPTION_HEADING;
			for (HITaDaEnrollmentEventJSON.SubscriptionInfo objSubsInfo : set_CurrentSubscriptions) {
				HITaDaEnrollmentEventJSON.Policy objPolicy;
				if (objSubsInfo.policy_id != null && map_PolicyId != null && map_PolicyId.containsKey('' + objSubsInfo.policy_id)) {
					objPolicy = map_PolicyId.get('' + objSubsInfo.policy_id);
				}
				String strPolicyName = (objPolicy != null) ? objPolicy.name : '';

				strDescription += '\n ' + objSubsInfo.benefit_type + ' : ' + strPolicyName;

				strDescription += '\n- Estimated Start Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objSubsInfo.estimated_start_date);
				strDescription += '\n' + HIEnrollmentEventUtility.DESC_SEPARATOR;
			}
		}
		if (!set_OverlappingSubscriptions.isEmpty()) {
			strDescription += HIEnrollmentEventUtility.OVERLAPPING_SUBSCRIPTION_HEADING;
			for (HITaDaEnrollmentEventJSON.SubscriptionInfo objSubsInfo : set_OverlappingSubscriptions) {
				HITaDaEnrollmentEventJSON.Policy objPolicy;
				if (objSubsInfo.policy_id != null && map_PolicyId != null && map_PolicyId.containsKey('' + objSubsInfo.policy_id)) {
					objPolicy = map_PolicyId.get('' + objSubsInfo.policy_id);
				}
				String strPolicyName = (objPolicy != null) ? objPolicy.name : '';

				strDescription += '\n ' + objSubsInfo.benefit_type + ' : ' + strPolicyName;

				strDescription += '\n- Estimated Start Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objSubsInfo.estimated_start_date);
				strDescription += '\n' + HIEnrollmentEventUtility.DESC_SEPARATOR;
			}
		}
		return strDescription;
	}
	/*
	 * Construct HSA Description
	 */
	static String getHSADescription(HITaDaEnrollmentEventJSON.HSAInfo objHSAInfo) {
		String strHSADescription = '';

		if (objHSAInfo != null) {
			strHSADescription += '\n' + objHSAInfo.hsa_benefit.benefit_type + ' : ' + objHSAInfo.hsa_benefit.name;
			strHSADescription += '\n HSA Policy Url: ' + objHSAInfo.hsa_benefit.url;

			strHSADescription += '\n' + HIEnrollmentEventUtility.DESC_SEPARATOR;
		}
		return strHSADescription;
	}
	/*
	 * Construct General Case Description based on Event and Carrier Info
	 */
	static string getCaseDescription(HITaDaEnrollmentEventJSON objParsedInfoEvent, String strProvider_key) {
		String strCaseDescription = '';
		String strCarrierName = (map_Carrier != null && map_Carrier.containsKey(strProvider_key)) ? map_Carrier.get(strProvider_key).Name : '';
		//add Event type detail to Case description
		strCaseDescription += HIEnrollmentEventUtility.getEnrollmentSourceInfo(objParsedInfoEvent.enrollment_source);

		strCaseDescription += HIEnrollmentEventUtility.getEmployeeInformation(objParsedInfoEvent.employee, objParsedInfoEvent.company.name, strCarrierName, '');
		strCaseDescription += '\n\nCarrier';
		strCaseDescription += '\n- Carrier: ' + strCarrierName;

		if (objParsedInfoEvent.recent_qles != null && objParsedInfoEvent.recent_qles.size() > 0) {
			for (HITaDaEnrollmentEventJSON.RecentQLEInfo objQLE : objParsedInfoEvent.recent_qles) {
				strCaseDescription += '\nEvent Type: ' + Utils.humanize(objQLE.event);
				strCaseDescription += '\nEvent Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objQLE.date_of_event);
				strCaseDescription += '\nFile Upload Url\'s: ' + objQLE.file_upload_urls;
			}
		}
		return strCaseDescription;
	}

	/*
	 *Wrapper to hold event data per selection
	 */
	class CaseWrapper {
		String strHSADescription;
		String strFSADCADescription;
		String strOpsOwner;
		HITaDaEnrollmentEventJSON.HSAInfo objHSA;
		HITaDaEnrollmentEventJSON.FSAInfo objFSA;
		HITaDaEnrollmentEventJSON.FSAInfo objDCA;
		String strBenefitType;
		String strHIEventId;
		String strEmployeeId;
		String strCompanyId;
		Date dtEffectiveDate;
		String strPIIInformation;
		CaseWrapper(
			String strHSADescription,
			String strFSADCADescription,
			String opsOwner,
			HITaDaEnrollmentEventJSON.HSAInfo objHSA,
			HITaDaEnrollmentEventJSON.FSAInfo objFSA,
			HITaDaEnrollmentEventJSON.FSAInfo objDCA,
			String strBenefitType,
			String strHIEventId,
			String strEmployeeId,
			String strCompanyId,
			Date dtEffectiveDate,
			String strPIIInfo
		) {
			this.strOpsOwner = opsOwner;
			this.objHSA = objHSA;
			this.objFSA = objFSA;
			this.objDCA = objDCA;
			this.dtEffectiveDate = dtEffectiveDate;
			this.strBenefitType = strBenefitType;
			this.strHIEventId = strHIEventId;
			this.strEmployeeId = strEmployeeId;
			this.strCompanyId = strCompanyId;
			this.strHSADescription = strHSADescription;
			this.strFSADCADescription = strFSADCADescription;
			this.strPIIInformation = strPIIInfo;
		}
	}
}