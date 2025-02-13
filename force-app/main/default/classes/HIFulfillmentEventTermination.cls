public class HIFulfillmentEventTermination {
	Map<String, Integer> map_FulfillmentSubscriptionsCount = new Map<String, Integer>();
	Map<String, List<HIFulfillmentTerminationEvenJSON.cls_forms>> map_stateCarrierIdsForm;
	Map<String, Map<String, Object>> map_stateCarrierIdsFormMappings;
	String strEnrollmentId = '';
	String strSelectionIds = '';
	String strPolicyGroupNumber = '';
	String strPolicyNumber = '';
	Set<String> set_CreateTermBORCaseForStatuses = new Set<String>{ 'Enrollment Confirmed', 'Fulfilled', 'BOR complete pending TAdAs' };
	public static String strEventSubType = 'Termination date changed';
	public static String strCancelTermination = 'Cancel termination';
	public static String strMemberFulfillmentQueue = GlobalQueryHelper.getQueueIdByDevName('Member_Fulfillment');
	public static String strMemberOpsBYBQueue = GlobalQueryHelper.getQueueIdByDevName('Member_Ops_BYB');
	public Set<String> set_OpenCaseStatus = new Set<String>{ 'Draft', 'New', 'On Hold' };
	public Set<String> set_CancelTerminationCarrier = new Set<String>();
	public Set<String> set_OtherCarrier = new Set<String>();
	public Map<String, List<String>> map_AllCarrierWithEmployeeIds = new Map<String, List<String>>();
	public Map<String, HIFulfillmentEventWrapper> map_HIFulfillments = new Map<String, HIFulfillmentEventWrapper>();
	public Map<String, Case> map_ExistingCases = new Map<String, Case>();
	public Map<String, String> map_StateCarrierWithCoverageEndDate = new Map<String, String>();
	public Set<String> set_CarrierProviderKeys = new Set<String>();
	private Static Blob ENCRYPTION_KEY = EncryptionUtils.getEncryptionKey('Master');

	public void processInformation(List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents) {
		Set<String> set_HiFulfillmentIds = new Set<String>();
		List<Case> list_Cases = new List<Case>();
		Set<String> set_CarrierKeys = new Set<String>();
		Set<String> set_ZPAccountIds = new Set<String>();
		Set<String> set_employeeEmails = new Set<String>();

		Map<String, Date> map_TermChangeEmployeeIds = new Map<String, Date>();
		Set<String> set_EmployeeIds = new Set<String>();
		Map<String, HIFulfillmentTerminationEvenJSON> map_EvenIdsInfo = new Map<String, HIFulfillmentTerminationEvenJSON>();
		Map<String, CaseDataWrapper> map_CaseWrapper = new Map<String, CaseDataWrapper>();
		map_FulfillmentSubscriptionsCount = new Map<String, Integer>();
		Map<String, Account> map_Accounts = new Map<String, Account>();
		Map<String, Benefit_Order__c> map_BenefitOrders = new Map<String, Benefit_Order__c>();
		for (HI_Fulfillment_Event__c objHIFulfillment : list_HIFulfillmentEvents) {
			if (objHIFulfillment.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			objHIFulfillment.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHIFulfillment.Message__c = '';

			if (objHIFulfillment.Id__c == null) {
				continue;
			}

			HIFulfillmentTerminationEvenJSON objHiEventInfoParsed;
			try {
				Blob blbDecrypted = EncodingUtil.base64Decode(objHiFulfillment.Event_Info_Encrypted__c);
				String strDeCryptedText = EncryptionUtils.getDecryptedText(ENCRYPTION_KEY, blbDecrypted);
				objHiEventInfoParsed = getJSONParsedData(strDeCryptedText);
			} catch (Exception e) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', objHiFulfillment);
				continue;
			}
			
			if (objHiEventInfoParsed?.tada?.dca?.policies != null && !objHiEventInfoParsed?.tada?.dca?.policies.isEmpty()) {
				for (Integer i = 0; i < objHiEventInfoParsed.tada.dca.policies.size(); i++) {
					set_CarrierKeys.add(objHiEventInfoParsed.tada.dca.policies[i].provider_key);
					set_CarrierProviderKeys.add(objHiEventInfoParsed.tada.dca.policies[i].provider_key);
				}
			}

			if (objHiEventInfoParsed?.tada?.fsa?.policies != null && !objHiEventInfoParsed?.tada?.fsa?.policies.isEmpty()) {
				for (Integer i = 0; i < objHiEventInfoParsed.tada.fsa.policies.size(); i++) {
					set_CarrierKeys.add(objHiEventInfoParsed.tada.fsa.policies[i].provider_key);
					set_CarrierProviderKeys.add(objHiEventInfoParsed.tada.fsa.policies[i].provider_key);
				}
			}

			if (objHiEventInfoParsed?.tada?.hsa?.policies != null && !objHiEventInfoParsed?.tada?.hsa?.policies.isEmpty()) {
				for (Integer i = 0; i < objHiEventInfoParsed.tada.hsa.policies.size(); i++) {
					set_CarrierKeys.add(objHiEventInfoParsed.tada.hsa.policies[i].provider_key);
					set_CarrierProviderKeys.add(objHiEventInfoParsed.tada.hsa.policies[i].provider_key);
				}
			}
			if (String.isNotBlank(objHiEventInfoParsed?.commuter_benefit?.provider_key)) {
				set_CarrierKeys.add(objHiEventInfoParsed.commuter_benefit.provider_key);
				set_CarrierProviderKeys.add(objHiEventInfoParsed.commuter_benefit.provider_key);
			}
			if (objHiEventInfoParsed == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', objHiFulfillment);
				continue;
			}

			if (objHiFulfillment.Event_Type__c == null || objHiFulfillment.Event_Type__c == '') {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Fulfillment Event Type: field value is missing in the record.', objHiFulfillment);
				continue;
			}

			if (objHiEventInfoParsed.company.id == null) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Company Id: field value is missing in the record.', objHiFulfillment);
				continue;
			}

			if (
				(objHiEventInfoParsed.State_carriers == null ||
				objHiEventInfoParsed.State_carriers.size() == 0) &&
				!map_BenefitOrders.containsKey(String.valueOf(objHiEventInfoParsed.company.id)) &&
				objHiEventInfoParsed.tada == null &&
				objHiEventInfoParsed.commuter_benefit == null &&
				strEventSubType != objHiEventInfoParsed.losing_benefits_reason
			) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'State Carrier information does not exist.', objHiFulfillment);
				continue;
			}

			if (
				(objHiEventInfoParsed.benefit_items == null ||
				objHiEventInfoParsed.benefit_items.size() == 0) &&
				objHiEventInfoParsed.tada == null &&
				objHiEventInfoParsed.commuter_benefit == null &&
				objHiFulfillment.Ops_Owner__c != 'bor_transfer_fulfillment' &&
				strEventSubType != objHiEventInfoParsed.losing_benefits_reason
			) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Subscription information does not exist.', objHiFulfillment);
				continue;
			}

			if (objHiEventInfoParsed?.tada?.hsa?.policies != null && !objHiEventInfoParsed?.tada?.hsa?.policies.isEmpty()) {
				for (Integer i = 0; i < objHiEventInfoParsed.tada.hsa.policies.size(); i++) {
					if (objHiEventInfoParsed.tada.hsa.policies[i].provider_key == null) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.PROVIDER_KEY_MISSING, objHiFulfillment);
						continue;
					}
				}
			}

			if (objHiEventInfoParsed?.tada?.fsa?.policies != null && !objHiEventInfoParsed?.tada?.fsa?.policies.isEmpty()) {
				for (Integer i = 0; i < objHiEventInfoParsed.tada.fsa.policies.size(); i++) {
					if (objHiEventInfoParsed.tada.fsa.policies[i].provider_key == null) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.PROVIDER_KEY_MISSING, objHiFulfillment);
						continue;
					}
				}
			}
			if (objHiEventInfoParsed?.tada?.dca?.policies != null && !objHiEventInfoParsed?.tada?.dca?.policies.isEmpty()) {
				for (Integer i = 0; i < objHiEventInfoParsed.tada.dca.policies.size(); i++) {
					if (objHiEventInfoParsed.tada.dca.policies[i].provider_key == null) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.PROVIDER_KEY_MISSING, objHiFulfillment);
						continue;
					}
				}
			}
			if (objHiEventInfoParsed?.commuter_benefit != null && String.isBlank(objHiEventInfoParsed.commuter_benefit?.provider_key)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIEnrollmentEventUtility.PROVIDER_KEY_MISSING, objHiFulfillment);
				continue;
			}
			set_HiFulfillmentIds.add(objHIFulfillment.Id__c);
			set_ZPAccountIds.add(String.valueOf(objHiEventInfoParsed.company.id));
			if (string.isNotBlank(objHiFulfillment.Employee_Id__c)) {
				set_EmployeeIds.add(objHiFulfillment.Employee_Id__c);
			}

			String strKey = '';
			Date dtBenefitsEligibilityEndDate = null;
			if (String.isNotBlank(objHiEventInfoParsed.benefits_eligibility_end_date)) {
				dtBenefitsEligibilityEndDate = Date.valueOf(objHiEventInfoParsed.benefits_eligibility_end_date);
			}

			Date dtCoverageEndDate = null;
			List<String> list_SelectionIds = new List<String>();
			if (objHiEventInfoParsed.state_carriers != null && objHiEventInfoParsed.state_carriers.size() > 0) {
				if (objHiEventInfoParsed.benefit_items != null && objHiEventInfoParsed.benefit_items.size() > 0) {
					for (HIFulfillmentTerminationEvenJSON.cls_benefit_items objBenefitItem : objHiEventInfoParsed.benefit_items) {
						dtCoverageEndDate = null;
						if (String.isNotBlank(objBenefitItem.coverage_end_date)) {
							strKey = objHIFulfillment.Id__c + '-' + objBenefitItem.state_carrier_id;
							if (map_StateCarrierWithCoverageEndDate.containsKey(strKey)) {
								dtCoverageEndDate = Date.valueOf(map_StateCarrierWithCoverageEndDate.get(strKey));
							}

							if (dtCoverageEndDate == null) {
								map_StateCarrierWithCoverageEndDate.put(strKey, objBenefitItem.coverage_end_date);
							} else if (dtCoverageEndDate > Date.valueOf(objBenefitItem.coverage_end_date)) {
								map_StateCarrierWithCoverageEndDate.put(strKey, objBenefitItem.coverage_end_date);
							}
						}
					}
				}

				for (HIFulfillmentTerminationEvenJSON.cls_state_carriers objStateCarrier : objHiEventInfoParsed.state_carriers) {
					dtCoverageEndDate = null;
					strKey = objHIFulfillment.Id__c + '-' + objStateCarrier.id;
					if (map_StateCarrierWithCoverageEndDate.containsKey(strKey)) {
						String strCoverageEndDate = map_StateCarrierWithCoverageEndDate.get(strKey);
						if (String.isNotBlank(strCoverageEndDate)) {
							dtCoverageEndDate = Date.valueOf(strCoverageEndDate);
						}
					}

					strKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + objStateCarrier.key;
					if (objHiEventInfoParsed.losing_benefits_reason == strCancelTermination) {
						set_CancelTerminationCarrier.add(strKey);
					} else {
						set_OtherCarrier.add(strKey);
					}

					list_SelectionIds = getSelectionId(objStateCarrier.id, objHiEventInfoParsed.benefit_items);
					map_AllCarrierWithEmployeeIds.put(strKey, list_SelectionIds);

					map_HIFulfillments.put(
						strKey,
						new HIFulfillmentEventWrapper(
							objHIFulfillment.Id__c,
							objHiEventInfoParsed.employee.company_id + '',
							objHiEventInfoParsed.employee.id + '',
							objStateCarrier.key,
							dtBenefitsEligibilityEndDate,
							dtCoverageEndDate
						)
					);
				}
			}

			if (objHiEventInfoParsed.tada != null) {
				if (objHiEventInfoParsed?.tada?.fsa?.policies != null && !objHiEventInfoParsed?.tada?.fsa?.policies.isEmpty()) {
					for (Integer i = 0; i < objHiEventInfoParsed.tada.fsa.policies.size(); i++) {
						String provider_key = (objHiEventInfoParsed.tada.fsa.policies[i].provider_key).toString();
						getTadaJsonInfo(objHiEventInfoParsed, objHIFulfillment, dtBenefitsEligibilityEndDate, provider_key, '-fsa');
					}
				}

				if (objHiEventInfoParsed?.tada?.hsa?.policies != null && !objHiEventInfoParsed?.tada?.hsa?.policies.isEmpty()) {
					for (Integer i = 0; i < objHiEventInfoParsed.tada.hsa.policies.size(); i++) {
						String provider_key = (objHiEventInfoParsed.tada.hsa.policies[i].provider_key).toString();
						getTadaJsonInfo(objHiEventInfoParsed, objHIFulfillment, dtBenefitsEligibilityEndDate, provider_key, '-hsa');
					}
				}
				if (objHiEventInfoParsed?.tada?.dca?.policies != null && !objHiEventInfoParsed?.tada?.dca?.policies.isEmpty()) {
					for (Integer i = 0; i < objHiEventInfoParsed.tada.dca.policies.size(); i++) {
						String provider_key = (objHiEventInfoParsed.tada.dca.policies[i].provider_key).toString();
						getTadaJsonInfo(objHiEventInfoParsed, objHIFulfillment, dtBenefitsEligibilityEndDate, provider_key, '-dca');
					}
				}
			}

			if (objHiEventInfoParsed.commuter_benefit != null && objHiEventInfoParsed.commuter_benefit.provider_key != null) {
				strKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + objHiEventInfoParsed.commuter_benefit.provider_key + '-commuter';
				if (objHiEventInfoParsed.losing_benefits_reason == strCancelTermination) {
					set_CancelTerminationCarrier.add(strKey);
				} else {
					set_OtherCarrier.add(strKey);
				}
				map_AllCarrierWithEmployeeIds.put(strKey, new List<String>());

				dtCoverageEndDate = null;
				if (objHiEventInfoParsed.tada != null) {
					dtCoverageEndDate = getCoverageEndDate(objHiEventInfoParsed.tada);
				}
				map_HIFulfillments.put(
					strKey,
					new HIFulfillmentEventWrapper(
						objHIFulfillment.Id__c,
						objHiEventInfoParsed.employee.company_id + '',
						objHiEventInfoParsed.employee.id + '',
						objHiEventInfoParsed.commuter_benefit.provider_key,
						dtBenefitsEligibilityEndDate,
						dtCoverageEndDate
					)
				);
			}
		}

		if (set_HiFulfillmentIds.size() > 0) {
			list_Cases = new List<Case>();
			Set<String> set_ExistingTermCase = new Set<String>();
			map_Accounts = HIFulfillmentEventHelperFunctions.getAccounts(set_ZPAccountIds);
			map_BenefitOrders = HIFulfillmentEventHelperFunctions.getbenefitOrderMap(set_ZPAccountIds);
			map_ExistingCases = getExistingCaseInfomation(set_EmployeeIds, set_ZPAccountIds);

			//Check to see if we have any existing termination cases for that account+contact++state carrier id+selection id then update it.
			Set<Id> set_ToUpdateCaseIds = new Set<Id>();
			for (String strHIEventKey : map_AllCarrierWithEmployeeIds.keySet()) {
				String strSearchKey = strHIEventKey;
				List<String> list_SelectionItemIds = map_AllCarrierWithEmployeeIds.get(strHIEventKey);
				if (list_SelectionItemIds.size() > 0) {
					for (String strId : list_SelectionItemIds) {
						strSearchKey = strHIEventKey + '-' + strId;
					}
				}

				if (map_ExistingCases.containsKey(strSearchKey) && map_HIFulfillments.containsKey(strHIEventKey)) {
					Case objCase = map_ExistingCases.get(strSearchKey);
					Boolean blnCriteriaMatch = false;

					if (!set_ToUpdateCaseIds.contains(objCase.Id)) {
						set_ToUpdateCaseIds.add(objCase.Id);
						HIFulfillmentEventWrapper objHIWrapper = map_HIFulfillments.get(strHIEventKey);
						objCase.Integration_Id__c = objHIWrapper.strEventId;
						objCase.Integration_Key__c = objHIWrapper.strEventId + '-' + objHIWrapper.strCarrierKey;

						if (set_OpenCaseStatus.contains(objCase.Status)) {
							if (set_CancelTerminationCarrier.contains(strHIEventKey)) {
								objCase.Termination_Date__c = null;
								objCase.MF_Coverage_End_Date__c = null;
								objCase.Special_Instructions__c = Label.HI_Term_Cancel_Terminations_with_Other;
								objCase.OwnerId = objCase.BYOB_Customer__c ? strMemberOpsBYBQueue : strMemberFulfillmentQueue;
							} else {
								objCase.Termination_Date__c = objHIWrapper.dtBenefitsEligibilityEndDate;
								objCase.MF_Coverage_End_Date__c = objHIWrapper.dtCoverageEndDate;
								objCase.Special_Instructions__c = Label.HI_Term_Special_Instructions_with_Other;
								set_ExistingTermCase.add(strHIEventKey);
								objCase = populateFulfillmentEventEncryptedJSON(objCase, objHIWrapper);
							}
							blnCriteriaMatch = true;
						} else if (set_CancelTerminationCarrier.contains(strHIEventKey) && (objCase.Status == CaseUtils.STATUS_SUBMITTED || objCase.Status == CaseUtils.STATUS_CLOSED)) {
							objCase.Status = 'New';
							objCase.Special_Instructions__c = Label.HI_Term_Cancel_Terminations_with_Submitted;
							objCase.OwnerId = objCase.BYOB_Customer__c ? strMemberOpsBYBQueue : strMemberFulfillmentQueue;
							blnCriteriaMatch = true;
						} else if (set_OtherCarrier.contains(strHIEventKey) && objCase.Status == CaseUtils.STATUS_SUBMITTED) {
							objCase.Status = 'New';
							objCase.Special_Instructions__c = Label.HI_Term_Special_Instructions_with_Submitted;
							objCase.Termination_Date__c = objHIWrapper.dtBenefitsEligibilityEndDate;
							objCase.MF_Coverage_End_Date__c = objHIWrapper.dtCoverageEndDate;
							objCase.OwnerId = objCase.BYOB_Customer__c ? strMemberOpsBYBQueue : strMemberFulfillmentQueue;
							set_ExistingTermCase.add(strHIEventKey);
							blnCriteriaMatch = true;
							objCase = populateFulfillmentEventEncryptedJSON(objCase, objHIWrapper);
						}

						if (blnCriteriaMatch) {
							list_Cases.add(objCase);
						}
					}
				}
			}

			if (list_Cases.size() > 0) {
				try {
					CaseTriggerHelper.SkipTrigger = true;
					update list_Cases;
					CaseTriggerHelper.SkipTrigger = false;
				} catch (Exception objException) {
					ExceptionLogUtil.logException(
						'HIFulfillmentEventTermination',
						'update case::process existing cancel termination cases',
						objException.getMessage(),
						objException.getStackTraceString()
					);
				}
			}

			//Validate & Create New Termination cases
			String strSearchKey = '';
			for (HI_Fulfillment_Event__c objHiFulfill : list_HIFulfillmentEvents) {
				if (!set_HiFulfillmentIds.contains(objHiFulfill.Id__c)) {
					continue;
				}
				HIFulfillmentTerminationEvenJSON objHiEventInfoParsed;
				try {
					Blob blbDecrypted = EncodingUtil.base64Decode(objHiFulfill.Event_Info_Encrypted__c);
					String strDeCryptedText = EncryptionUtils.getDecryptedText(ENCRYPTION_KEY, blbDecrypted);
					objHiEventInfoParsed = getJSONParsedData(strDeCryptedText);
				} catch (Exception e) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'JSON not parsed correctly.', objHiFulfill);
					continue;
				}

				if (objHiEventInfoParsed.losing_benefits_reason == strCancelTermination) {
					continue;
				}

				objHiFulfill.Event_Sub_Type__c = objHiEventInfoParsed.losing_benefits_reason;
				if (String.isNotBlank(objHiEventInfoParsed.sent_at)) {
					objHiFulfill.Sent_at__c = HIFulfillmentEventHelperFunctions.getDateTimeFromString(objHiEventInfoParsed.sent_at);
				}

				if (objHiEventInfoParsed.employee.email != null) {
					set_employeeEmails.add(objHiEventInfoParsed.employee.email);
				}
				if (objHiEventInfoParsed.employee.Id != null) {
					set_EmployeeIds.add('' + objHiEventInfoParsed.employee.Id);
					set_employeeEmails.add('' + objHiEventInfoParsed.employee.Id);
				}

				Map<String, HIFulfillmentTerminationEvenJSON.cls_dependents> mapDependents = new Map<String, HIFulfillmentTerminationEvenJSON.cls_dependents>();
				if (objHiEventInfoParsed.dependents != null && objHiEventInfoParsed.dependents.size() > 0) {
					for (HIFulfillmentTerminationEvenJSON.cls_dependents dependent : objHiEventInfoParsed.dependents) {
						mapDependents.put('' + dependent.id, dependent);
					}
				}
				map_EvenIdsInfo.put(objHiFulfill.Id__c, objHiEventInfoParsed);
				Map<String, Set<String>> map_CarrierToDependentIds = new Map<String, Set<String>>();
				Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>> map_CarrierToSubscriptionList = new Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>>();
				Map<String, HIFulfillmentTerminationEvenJSON.cls_policies> map_Policy = new Map<String, HIFulfillmentTerminationEvenJSON.cls_policies>();
				map_stateCarrierIdsForm = new Map<String, List<HIFulfillmentTerminationEvenJSON.cls_forms>>(); // key is State CarrierId and value is Form
				map_stateCarrierIdsFormMappings = new Map<String, Map<String, Object>>();
				if (objHiEventInfoParsed.forms != null && objHiEventInfoParsed.forms.size() > 0) {
					for (HIFulfillmentTerminationEvenJSON.cls_forms objForm : objHiEventInfoParsed.forms) {
						String strKey = '' + objForm.state_carrier_id;
						List<HIFulfillmentTerminationEvenJSON.cls_forms> list_forms;
						if (map_stateCarrierIdsForm.containsKey(strKey)) {
							list_forms = map_stateCarrierIdsForm.get(strKey);
						} else {
							list_forms = new List<HIFulfillmentTerminationEvenJSON.cls_forms>();
						}
						list_forms.add(objForm);
						map_stateCarrierIdsForm.put(strKey, list_forms);
					}
				}
				Map<String, Set<String>> map_terminationPolicyPerCarrier = new Map<String, Set<String>>();

				if (objHiEventInfoParsed.policies != null && objHiEventInfoParsed.policies.size() > 0) {
					for (HIFulfillmentTerminationEvenJSON.cls_policies objPolicy : objHiEventInfoParsed.policies) {
						map_Policy.put('' + objPolicy.id, objPolicy);

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

				if (objHiEventInfoParsed.benefit_items != null && objHiEventInfoParsed.benefit_items.size() > 0) {
					map_FulfillmentSubscriptionsCount.put(objHiFulfill.Id__c, objHiEventInfoParsed.benefit_items.size());

					for (HIFulfillmentTerminationEvenJSON.cls_benefit_items objSubscription : objHiEventInfoParsed.benefit_items) {
						List<HIFulfillmentTerminationEvenJSON.cls_benefit_items> list_Subscription = new List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>();
						if (map_CarrierToSubscriptionList.containsKey('' + objSubscription.state_carrier_id)) {
							list_Subscription = map_CarrierToSubscriptionList.get('' + objSubscription.state_carrier_id);
						}
						list_Subscription.add(objSubscription);
						map_CarrierToSubscriptionList.put('' + objSubscription.state_carrier_id, list_Subscription);

						Set<String> set_DependentIds = new Set<String>();
						if (map_CarrierToDependentIds.containsKey('' + objSubscription.state_carrier_id)) {
							set_DependentIds = map_CarrierToDependentIds.get('' + objSubscription.state_carrier_id);
						}

						if (objSubscription.dependent_ids != null && objSubscription.dependent_ids.size() > 0) {
							for (Long dependentId : objSubscription.dependent_ids) {
								set_DependentIds.add('' + dependentId);
							}
						}
						map_CarrierToDependentIds.put('' + objSubscription.state_carrier_id, set_DependentIds);
					}
				} else {
					map_FulfillmentSubscriptionsCount.put(objHiFulfill.Id__c, 0);
				}

				HIFulfillmentTerminationEvenJSON.cls_home_address objEmployeeHomeAddress = objHiEventInfoParsed.employee.home_address;
				HIFulfillmentTerminationEvenJSON.cls_address objCompanyBenefitAddress = objHiEventInfoParsed.company.benefits_address;
				CaseDataWrapper objCaseWrapper;
				if (objHiEventInfoParsed.State_carriers != null && objHiEventInfoParsed.State_carriers.size() > 0) {
					for (HIFulfillmentTerminationEvenJSON.cls_state_carriers stateCarrier : objHiEventInfoParsed.State_carriers) {
						set_CarrierKeys.add(stateCarrier.key);
						String strCaseDescription = '';
						strEnrollmentId = '';

						if (stateCarrier.key == null || stateCarrier.key == '') {
							HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'State Carrier Key: field value is missing in the record.', objHiFulfill);
							continue;
						}

						String strEnrollmentKey = strEnrollmentId + '-' + stateCarrier.key + '-' + objHiEventInfoParsed.employee.id;
						strSearchKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + stateCarrier.key;
						
						String strExistingCaseKey;
						Case objCase;
						List<String> list_SelectionItemIds = map_AllCarrierWithEmployeeIds.get(strSearchKey);
						for (String strId : list_SelectionItemIds) {
							strExistingCaseKey = strSearchKey + '-' + strId;
							objCase = map_ExistingCases.get(strSearchKey);
						}

						strSelectionIds = '';
						strPolicyGroupNumber = '';
						strPolicyNumber = '';
						String strBOTJson = getCarrierBotJson(objHiEventInfoParsed, stateCarrier.id, ENCRYPTION_KEY);

						strCaseDescription +=
							'General Info' +
							'\n- Subscriptions link: ' +
							objHiEventInfoParsed.benefits_url +
							'\n- EE Panda Link: ' +
							objHiEventInfoParsed.employee.panda_url +
							'\n- Carrier Directory: ' +
							objHiEventInfoParsed.carrier_directory +
							'\n\n- COBRA Activated: ' +
							objHiEventInfoParsed.company.has_federal_cobra +
							'\n\nCarrier' +
							'\n- Carrier: ' +
							stateCarrier.name +
							'\n- Carrier State: ' +
							stateCarrier.state +
							'\n\nTermination Forms' +
							getForms(stateCarrier.id) +
							'\n\nCompany Info' +
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
							) +
							'\n\nPlease review and submit the required documents to the carrier.';
						if (set_ExistingTermCase.contains(strSearchKey) && (objCase != null && objCase.Description == strCaseDescription && objCase.Status != 'Closed')) {
							continue;
						}

						String strPiiInformation = 'Employee Info:';
						strPiiInformation +=
							'<br/>- Name: ' +
							HIFulfillmentEventHelperFunctions.getName(objHiEventInfoParsed.employee.first_name, objHiEventInfoParsed.employee.middle_initial, objHiEventInfoParsed.employee.last_name);
						strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHiEventInfoParsed.employee.ssn);
						strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.employee.birthday);

						Date dtCoverageStartDate = getCoverageStartDate('' + stateCarrier.id, map_CarrierToSubscriptionList, map_Policy);
						Date dtTerminationDate = String.isNotBlank(objHiEventInfoParsed.benefits_eligibility_end_date) ? Date.valueOf(objHiEventInfoParsed.benefits_eligibility_end_date) : null;

						Set<String> set_terminationPolicy;
						if (map_terminationPolicyPerCarrier.containsKey('' + stateCarrier.id)) {
							set_terminationPolicy = map_terminationPolicyPerCarrier.get('' + stateCarrier.id);
						}

						objCaseWrapper = new caseDataWrapper(
							objHiFulfill.Id__c,
							stateCarrier.key,
							objHiFulfill.Event_Type__c,
							objHiEventInfoParsed.company.id,
							objHiEventInfoParsed.employee.email,
							strCaseDescription,
							dtTerminationDate,
							strEnrollmentId,
							strEnrollmentKey,
							objHiEventInfoParsed,
							strPiiInformation,
							strBOTJson,
							strSelectionIds,
							strPolicyGroupNumber,
							strPolicyNumber,
							dtCoverageStartDate,
							set_terminationPolicy
						);

						map_CaseWrapper.put(objHiFulfill.id__c + '-' + stateCarrier.key, objCaseWrapper);
					}
				} else {
					String strCaseDescription = '';
					String strEnrollmentKey = strEnrollmentId + '-' + '-' + '-' + objHiEventInfoParsed.employee.id;
					strSearchKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-';

					if (set_ExistingTermCase.contains(strSearchKey)) {
						continue;
					}

					strCaseDescription +=
						'General Info' +
						'\n- EE Panda Link: ' +
						objHiEventInfoParsed.employee.panda_url +
						'\n- Carrier Directory: ' +
						objHiEventInfoParsed.carrier_directory +
						'\n\n- COBRA Activated: ' +
						objHiEventInfoParsed.company.has_federal_cobra +
						'\n\nCompany Info' +
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
						) +
						'\n\nPlease review and submit the required documents to the carrier.';

					String strPiiInformation = 'Employee Info:';
					strPiiInformation +=
						'<br/>- Name: ' +
						HIFulfillmentEventHelperFunctions.getName(objHiEventInfoParsed.employee.first_name, objHiEventInfoParsed.employee.middle_initial, objHiEventInfoParsed.employee.last_name);
					strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHiEventInfoParsed.employee.ssn);
					strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.employee.birthday);

					Date dtTerminationDate = String.isNotBlank(objHiEventInfoParsed.benefits_eligibility_end_date) ? Date.valueOf(objHiEventInfoParsed.benefits_eligibility_end_date) : null;

					objCaseWrapper = new caseDataWrapper(
						objHiFulfill.Id__c,
						'',
						objHiFulfill.Event_Type__c,
						objHiEventInfoParsed.company.id,
						objHiEventInfoParsed.employee.email,
						strCaseDescription,
						dtTerminationDate,
						strEnrollmentId,
						strEnrollmentKey,
						objHiEventInfoParsed,
						strPiiInformation,
						'',
						'',
						strPolicyGroupNumber,
						strPolicyNumber,
						null,
						null
					);

					map_CaseWrapper.put(objHiFulfill.id__c, objCaseWrapper);
				}

				if (objHiEventInfoParsed.tada != null) {
					if (objHiEventInfoParsed?.tada?.fsa?.policies != null && !objHiEventInfoParsed?.tada?.fsa?.policies.isEmpty()) {
						for (Integer i = 0; i < objHiEventInfoParsed.tada.fsa.policies.size(); i++) {
							String strCaseDescription = '';
							String strEnrollmentKey = strEnrollmentId + '-' + objHiEventInfoParsed.tada.fsa.policies[i].provider_key + '-' + objHiEventInfoParsed.employee.id;
							strSearchKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + objHiEventInfoParsed.tada.fsa.policies[i].provider_key + '-fsa';

							if (set_ExistingTermCase.contains(strSearchKey)) {
								continue;
							}

							List<HIFulfillmentTerminationEvenJSON.cls_benefit_items> list_TadasSubscription = new List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>();
							if (objHiEventInfoParsed.tada.fsa != null) {
								if (objHiEventInfoParsed.tada.fsa.benefit_items != null) {
									list_TadasSubscription.addAll(objHiEventInfoParsed.tada.fsa.benefit_items);
								}
								if (objHiEventInfoParsed.tada.fsa.policies != null) {
									for (HIFulfillmentTerminationEvenJSON.cls_policies objPolicy : objHiEventInfoParsed.tada.fsa.policies) {
										map_Policy.put('' + objPolicy.id, objPolicy);
									}
								}
							}
							Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>> map_TadasSubsc = new Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>>();
							map_TadasSubsc.put(objHiEventInfoParsed.tada.fsa.policies[i].provider_key, list_TadasSubscription);

							strCaseDescription +=
								'General Info' +
								'\n- Subscriptions link: ' +
								objHiEventInfoParsed.benefits_url +
								'\n- EE Panda Link: ' +
								objHiEventInfoParsed.employee.panda_url +
								'\n- Carrier Directory: ' +
								objHiEventInfoParsed.carrier_directory +
								'\n\n- COBRA Activated: ' +
								objHiEventInfoParsed.company.has_federal_cobra +
								'\n\nCarrier' +
								'\n- Carrier: ' +
								objHiEventInfoParsed.tada.fsa.policies[i].provider_key;

							Date dtCoverageStartDate = getCoverageStartDate(objHiEventInfoParsed.tada.fsa.policies[i].provider_key, map_TadasSubsc, map_Policy);
							if (objHiEventInfoParsed.commuter_benefit != null && objHiEventInfoParsed.commuter_benefit.provider_key != null) {
								strCaseDescription += '\n\n' + objHiEventInfoParsed.commuter_benefit.provider_key + ' commuter benefit:';
							}
							strCaseDescription +=
								'\nBenefit URL: ' +
								'https://hippo.gusto.com/companies/' +
								objHiEventInfoParsed.company.id +
								'/employees/' +
								objHiEventInfoParsed.employee.id +
								'/commuter_employee_benefits';
							strCaseDescription +=
								'\n\nCompany Info' +
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
								) +
								'\n\nPlease review and submit the required documents to the carrier.';
							String strPiiInformation = 'Employee Info:';
							strPiiInformation +=
								'<br/>- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(
									objHiEventInfoParsed.employee.first_name,
									objHiEventInfoParsed.employee.middle_initial,
									objHiEventInfoParsed.employee.last_name
								);
							strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHiEventInfoParsed.employee.ssn);
							strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.employee.birthday);

							Date dtTerminationDate = String.isNotBlank(objHiEventInfoParsed.benefits_eligibility_end_date) ? Date.valueOf(objHiEventInfoParsed.benefits_eligibility_end_date) : null;
							objCaseWrapper = new caseDataWrapper(
								objHiFulfill.Id__c,
								objHiEventInfoParsed.tada.fsa.policies[i].provider_key,
								objHiFulfill.Event_Type__c,
								objHiEventInfoParsed.company.id,
								objHiEventInfoParsed.employee.email,
								strCaseDescription,
								dtTerminationDate,
								strEnrollmentId + '-' + objHiEventInfoParsed.tada.fsa.policies[i].provider_key,
								strEnrollmentKey + '-' + objHiEventInfoParsed.tada.fsa.policies[i].provider_key,
								objHiEventInfoParsed,
								strPiiInformation,
								'',
								'',
								strPolicyGroupNumber,
								strPolicyNumber,
								dtCoverageStartDate,
								null
							);

							map_CaseWrapper.put(objHiFulfill.id__c + '-' + objHiEventInfoParsed.tada.fsa.policies[i].provider_key, objCaseWrapper);
						}
					}

					if (objHiEventInfoParsed?.tada?.dca?.policies != null && !objHiEventInfoParsed?.tada?.dca?.policies.isEmpty()) {
						for (Integer i = 0; i < objHiEventInfoParsed.tada.dca.policies.size(); i++) {
							String strCaseDescription = '';
							String strEnrollmentKey = strEnrollmentId + '-' + objHiEventInfoParsed.tada.dca.policies[i].provider_key + '-' + objHiEventInfoParsed.employee.id;
							strSearchKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + objHiEventInfoParsed.tada.dca.policies[i].provider_key + '-dca';

							if (set_ExistingTermCase.contains(strSearchKey)) {
								continue;
							}

							List<HIFulfillmentTerminationEvenJSON.cls_benefit_items> list_TadasSubscription = new List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>();
							if (objHiEventInfoParsed.tada.dca != null) {
								if (objHiEventInfoParsed.tada.dca.benefit_items != null) {
									list_TadasSubscription.addAll(objHiEventInfoParsed.tada.dca.benefit_items);
								}

								if (objHiEventInfoParsed.tada.dca.policies != null) {
									for (HIFulfillmentTerminationEvenJSON.cls_policies objPolicy : objHiEventInfoParsed.tada.dca.policies) {
										map_Policy.put('' + objPolicy.id, objPolicy);
									}
								}
							}
							Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>> map_TadasSubsc = new Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>>();
							map_TadasSubsc.put(objHiEventInfoParsed.tada.dca.policies[i].provider_key, list_TadasSubscription);

							strCaseDescription +=
								'General Info' +
								'\n- Subscriptions link: ' +
								objHiEventInfoParsed.benefits_url +
								'\n- EE Panda Link: ' +
								objHiEventInfoParsed.employee.panda_url +
								'\n- Carrier Directory: ' +
								objHiEventInfoParsed.carrier_directory +
								'\n\n- COBRA Activated: ' +
								objHiEventInfoParsed.company.has_federal_cobra +
								'\n\nCarrier' +
								'\n- Carrier: ' +
								objHiEventInfoParsed.tada.dca.policies[i].provider_key;

							Date dtCoverageStartDate = getCoverageStartDate(objHiEventInfoParsed.tada.dca.policies[i].provider_key, map_TadasSubsc, map_Policy);
							if (objHiEventInfoParsed.commuter_benefit != null && objHiEventInfoParsed.commuter_benefit.provider_key != null) {
								strCaseDescription += '\n\n' + objHiEventInfoParsed.commuter_benefit.provider_key + ' commuter benefit:';
							}
							strCaseDescription +=
								'\nBenefit URL: ' +
								'https://hippo.gusto.com/companies/' +
								objHiEventInfoParsed.company.id +
								'/employees/' +
								objHiEventInfoParsed.employee.id +
								'/commuter_employee_benefits';
							strCaseDescription +=
								'\n\nCompany Info' +
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
								) +
								'\n\nPlease review and submit the required documents to the carrier.';
							String strPiiInformation = 'Employee Info:';
							strPiiInformation +=
								'<br/>- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(
									objHiEventInfoParsed.employee.first_name,
									objHiEventInfoParsed.employee.middle_initial,
									objHiEventInfoParsed.employee.last_name
								);
							strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHiEventInfoParsed.employee.ssn);
							strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.employee.birthday);

							Date dtTerminationDate = String.isNotBlank(objHiEventInfoParsed.benefits_eligibility_end_date) ? Date.valueOf(objHiEventInfoParsed.benefits_eligibility_end_date) : null;
							objCaseWrapper = new caseDataWrapper(
								objHiFulfill.Id__c,
								objHiEventInfoParsed.tada.dca.policies[i].provider_key,
								objHiFulfill.Event_Type__c,
								objHiEventInfoParsed.company.id,
								objHiEventInfoParsed.employee.email,
								strCaseDescription,
								dtTerminationDate,
								strEnrollmentId + '-' + objHiEventInfoParsed.tada.dca.policies[i].provider_key,
								strEnrollmentKey + '-' + objHiEventInfoParsed.tada.dca.policies[i].provider_key,
								objHiEventInfoParsed,
								strPiiInformation,
								'',
								'',
								strPolicyGroupNumber,
								strPolicyNumber,
								dtCoverageStartDate,
								null
							);

							map_CaseWrapper.put(objHiFulfill.id__c + '-' + objHiEventInfoParsed.tada.dca.policies[i].provider_key, objCaseWrapper);
						}
					}

					if (objHiEventInfoParsed?.tada?.hsa?.policies != null && !objHiEventInfoParsed?.tada?.hsa?.policies.isEmpty()) {
						for (Integer i = 0; i < objHiEventInfoParsed.tada.hsa.policies.size(); i++) {
							String strCaseDescription = '';
							String strEnrollmentKey = strEnrollmentId + '-' + objHiEventInfoParsed.tada.hsa.policies[i].provider_key + '-' + objHiEventInfoParsed.employee.id;
							strSearchKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + objHiEventInfoParsed.tada.hsa.policies[i].provider_key;

							if (set_ExistingTermCase.contains(strSearchKey)) {
								continue;
							}

							List<HIFulfillmentTerminationEvenJSON.cls_benefit_items> list_TadasSubscription = new List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>();

							Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>> map_TadasSubsc = new Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>>();
							map_TadasSubsc.put(objHiEventInfoParsed.tada.hsa.policies[i].provider_key, list_TadasSubscription);

							strCaseDescription +=
								'General Info' +
								'\n- Subscriptions link: ' +
								objHiEventInfoParsed.benefits_url +
								'\n- EE Panda Link: ' +
								objHiEventInfoParsed.employee.panda_url +
								'\n- Carrier Directory: ' +
								objHiEventInfoParsed.carrier_directory +
								'\n\n- COBRA Activated: ' +
								objHiEventInfoParsed.company.has_federal_cobra +
								'\n\nCarrier' +
								'\n- Carrier: ' +
								objHiEventInfoParsed.tada.hsa.policies[i].provider_key;

							Date dtCoverageStartDate = getCoverageStartDate(objHiEventInfoParsed.tada.hsa.policies[i].provider_key, map_TadasSubsc, map_Policy);
							if (objHiEventInfoParsed.commuter_benefit != null && objHiEventInfoParsed.commuter_benefit.provider_key != null) {
								strCaseDescription += '\n\n' + objHiEventInfoParsed.commuter_benefit.provider_key + ' commuter benefit:';
							}
							strCaseDescription +=
								'\nBenefit URL: ' +
								'https://hippo.gusto.com/companies/' +
								objHiEventInfoParsed.company.id +
								'/employees/' +
								objHiEventInfoParsed.employee.id +
								'/commuter_employee_benefits';
							strCaseDescription +=
								'\n\nCompany Info' +
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
								) +
								'\n\nPlease review and submit the required documents to the carrier.';

							String strPiiInformation = 'Employee Info:';
							strPiiInformation +=
								'<br/>- Name: ' +
								HIFulfillmentEventHelperFunctions.getName(
									objHiEventInfoParsed.employee.first_name,
									objHiEventInfoParsed.employee.middle_initial,
									objHiEventInfoParsed.employee.last_name
								);
							strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHiEventInfoParsed.employee.ssn);
							strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.employee.birthday);

							Date dtTerminationDate = String.isNotBlank(objHiEventInfoParsed.benefits_eligibility_end_date) ? Date.valueOf(objHiEventInfoParsed.benefits_eligibility_end_date) : null;
							objCaseWrapper = new caseDataWrapper(
								objHiFulfill.Id__c,
								objHiEventInfoParsed.tada.hsa.policies[i].provider_key,
								objHiFulfill.Event_Type__c,
								objHiEventInfoParsed.company.id,
								objHiEventInfoParsed.employee.email,
								strCaseDescription,
								dtTerminationDate,
								strEnrollmentId + '-' + objHiEventInfoParsed.tada.hsa.policies[i].provider_key,
								strEnrollmentKey + '-' + objHiEventInfoParsed.tada.hsa.policies[i].provider_key,
								objHiEventInfoParsed,
								strPiiInformation,
								'',
								'',
								strPolicyGroupNumber,
								strPolicyNumber,
								dtCoverageStartDate,
								null
							);

							map_CaseWrapper.put(objHiFulfill.id__c + '-' + objHiEventInfoParsed.tada.hsa.policies[i].provider_key, objCaseWrapper);
						}
					}
				}
				/******* Commuter Termination ********/
				if (objHiEventInfoParsed.commuter_benefit != null && objHiEventInfoParsed.commuter_benefit.provider_key != null && objHiEventInfoParsed.tada == null) {
					String strCaseDescription = '';
					String strEnrollmentKey = strEnrollmentId + '-' + objHiEventInfoParsed.commuter_benefit.provider_key + '-' + objHiEventInfoParsed.employee.id;
					strSearchKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + objHiEventInfoParsed.commuter_benefit.provider_key;

					if (set_ExistingTermCase.contains(strSearchKey)) {
						continue;
					}

					strCaseDescription +=
						'General Info' +
						'\n- Subscriptions link: ' +
						objHiEventInfoParsed.benefits_url +
						'\n- EE Panda Link: ' +
						objHiEventInfoParsed.employee.panda_url +
						'\n- Carrier Directory: ' +
						objHiEventInfoParsed.carrier_directory +
						'\n\n- COBRA Activated: ' +
						objHiEventInfoParsed.company.has_federal_cobra +
						'\n\nCarrier' +
						'\n- Carrier: ' +
						objHiEventInfoParsed.commuter_benefit.provider_key +
						' Commuter Benefit';

					strCaseDescription +=
						'\n\nBenefit URL: ' +
						'https://hippo.gusto.com/companies/' +
						objHiEventInfoParsed.company.id +
						'/employees/' +
						objHiEventInfoParsed.employee.id +
						'/commuter_employee_benefits';

					strCaseDescription +=
						'\n\nCompany Info' +
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
						) +
						'\n\nPlease review and submit the required documents to the carrier.';

					String strPiiInformation = 'Employee Info:';
					strPiiInformation +=
						'<br/>- Name: ' +
						HIFulfillmentEventHelperFunctions.getName(objHiEventInfoParsed.employee.first_name, objHiEventInfoParsed.employee.middle_initial, objHiEventInfoParsed.employee.last_name);
					strPiiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN('' + objHiEventInfoParsed.employee.ssn);
					strPiiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(objHiEventInfoParsed.employee.birthday);

					Date dtTerminationDate = String.isNotBlank(objHiEventInfoParsed.benefits_eligibility_end_date) ? Date.valueOf(objHiEventInfoParsed.benefits_eligibility_end_date) : null;

					objCaseWrapper = new caseDataWrapper(
						objHiFulfill.Id__c,
						objHiEventInfoParsed.commuter_benefit.provider_key,
						objHiFulfill.Event_Type__c,
						objHiEventInfoParsed.company.id,
						objHiEventInfoParsed.employee.email,
						strCaseDescription,
						dtTerminationDate,
						strEnrollmentId + '-' + objHiEventInfoParsed.commuter_benefit.provider_key,
						strEnrollmentKey + '-' + objHiEventInfoParsed.commuter_benefit.provider_key,
						objHiEventInfoParsed,
						strPiiInformation,
						'',
						'',
						'',
						'',
						null,
						null
					);

					map_CaseWrapper.put(objHiFulfill.id__c + '-' + objHiEventInfoParsed.commuter_benefit.provider_key, objCaseWrapper);
				}
			}

			Map<String, Contact> map_Contacts = new Map<String, Contact>();
			if (set_employeeEmails.size() > 0) {
				map_Contacts = HIFulfillmentEventHelperFunctions.getContactWithEmailAndEmployeeId(set_employeeEmails);
			}
			Map<String, Carrier__c> map_Carriers = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_CarrierKeys);

			List<Contact> list_Contacts = processContactInformation(list_HIFulfillmentEvents, map_EvenIdsInfo, map_Accounts, map_Contacts);

			if (list_Contacts.size() > 0) {
				for (Contact objContact : list_Contacts) {
					if (String.isNotBlank(objContact.Email)) {
						map_Contacts.put(objContact.Email, objContact);
					}

					if (String.isNotBlank(objContact.Employee_Id__c)) {
						map_Contacts.put(objContact.Employee_Id__c, objContact);
					}
				}
			}

			List<Case> list_CasesForUpsert = getCaseInformation(map_CaseWrapper, list_HIFulfillmentEvents, map_EvenIdsInfo, map_Accounts, map_Contacts, map_Carriers, map_BenefitOrders);
			Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();
			if (list_CasesForUpsert.size() > 0) {
				List<Database.UpsertResult> saveResult = database.upsert(list_CasesForUpsert, Case.Fields.Enrollment_Key__c, false);
				dmlCaseUpsertErrorsMap = Utils.processUpsertResult(saveResult, list_CasesForUpsert, 'Enrollment_Key__c', true, 'HIFulfillmentEventTermination-processInformation');
				createAttachment(list_CasesForUpsert, map_CaseWrapper);
			}

			for (HI_Fulfillment_Event__c objHiFulfill : list_HIFulfillmentEvents) {
				if (objHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || objHiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
					continue;
				}
				if (dmlCaseUpsertErrorsMap.containsKey(objHiFulfill.Id__c)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlCaseUpsertErrorsMap.get(objHiFulfill.Id__c), objHiFulfill);
					continue;
				} else {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Data successfully Processed', objHiFulfill);
				}
			}
		}
	}

	public void getTadaJsonInfo(HIFulfillmentTerminationEvenJSON objHiEventInfoParsed, HI_Fulfillment_Event__c objHIFulfillment, Date dtBenefitsEligibilityEndDate, String provider_key, String str) {
		String strKey = objHiEventInfoParsed.employee.company_id + '-' + objHiEventInfoParsed.employee.id + '-' + provider_key + str;

		if (objHiEventInfoParsed.losing_benefits_reason == strCancelTermination) {
			set_CancelTerminationCarrier.add(strKey);
		} else {
			set_OtherCarrier.add(strKey);
		}
		map_AllCarrierWithEmployeeIds.put(strKey, new List<String>());

		Date dtCoverageEndDate = null;
		if (objHiEventInfoParsed.tada != null) {
			dtCoverageEndDate = getCoverageEndDate(objHiEventInfoParsed.tada);
		}

		map_HIFulfillments.put(
			strKey,
			new HIFulfillmentEventWrapper(
				objHIFulfillment.Id__c,
				objHiEventInfoParsed.employee.company_id + '',
				objHiEventInfoParsed.employee.id + '',
				provider_key,
				dtBenefitsEligibilityEndDate,
				dtCoverageEndDate
			)
		);
	}

	public static void createAttachment(List<Case> list_CasesForUpsert, Map<String, CaseDataWrapper> map_CaseWrapper) {
		List<Attachment> attachmentList = new List<Attachment>();
		for (Case objCase : list_CasesForUpsert) {
			if (objCase.Id != null) {
				if (map_CaseWrapper.containsKey(objCase.Integration_Key__c)) {
					CaseDataWrapper objCaseWrapper = map_CaseWrapper.get(objCase.Integration_Key__c);
					Attachment atch = new Attachment();
					atch.ParentId = objCase.Id;
					atch.Body = EncryptionUtils.getEncryptedBlob(ENCRYPTION_KEY, objCaseWrapper.strPiiInformation);
					atch.Name = 'encFile.txt';
					attachmentList.add(atch);
				}
			}
		}
		if (attachmentList.size() > 0) {
			insert attachmentList;
		}
	}

	//calling HIFulfillmentTerminationEvenJSON class for parsing data
	private HIFulfillmentTerminationEvenJSON getJSONParsedData(String jsonString) {
		HIFulfillmentTerminationEvenJSON objParsedData = (HIFulfillmentTerminationEvenJSON) JSON.deserialize(jsonString, HIFulfillmentTerminationEvenJSON.class);

		return objParsedData;
	}

	private Date getCoverageStartDate(
		String carrierId,
		Map<String, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>> map_CarrierToSubscriptionList,
		Map<String, HIFulfillmentTerminationEvenJSON.cls_policies> map_Policy
	) {
		Date dtCoverageStartDate = null;
		if (map_CarrierToSubscriptionList.containsKey(carrierId)) {
			for (HIFulfillmentTerminationEvenJSON.cls_benefit_items subscription : map_CarrierToSubscriptionList.get(carrierId)) {
				if (subscription.start_date != null && subscription.start_date != '') {
					if (dtCoverageStartDate == null) {
						dtCoverageStartDate = Date.valueOf(subscription.start_date);
					} else if (dtCoverageStartDate > Date.valueOf(subscription.start_date)) {
						dtCoverageStartDate = Date.valueOf(subscription.start_date);
					}
				}
			}
		}
		return dtCoverageStartDate;
	}

	private List<Contact> processContactInformation(
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents,
		Map<string, HIFulfillmentTerminationEvenJSON> map_EvenIdsInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts
	) {
		List<Contact> list_ContactForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c objHiFulfill : list_HIFulfillmentEvents) {
			if (objHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || objHiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (!map_EvenIdsInfo.containsKey(objHiFulfill.Id__c)) {
				continue;
			}

			HIFulfillmentTerminationEvenJSON objHiEventInfo = map_EvenIdsInfo.get(objHiFulfill.Id__c);
			if (!map_Accounts.containsKey('' + objHiEventInfo.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', objHiFulfill);
				continue;
			}

			if (
				objHiEventInfo.employee.email != null &&
				!map_Contacts.containsKey(objHiEventInfo.employee.company_id + '-' + objHiEventInfo.employee.email) &&
				!map_Contacts.containsKey(objHiEventInfo.employee.email) &&
				!map_Contacts.containsKey(objHiEventInfo.employee.company_id + '-' + objHiEventInfo.employee.Id)
			) {
				Contact objContact = new Contact();
				objContact.AccountId = map_Accounts.get('' + objHiEventInfo.employee.company_id).Id;
				objContact.FirstName = objHiEventInfo.employee.first_Name;
				objContact.LastName = objHiEventInfo.employee.last_name;
				objContact.Email = objHiEventInfo.employee.email;
				objContact.Unique_Email_Address_Contact__c = objHiEventInfo.employee.email;
				objContact.Employee_Id__c = objHiEventInfo.employee.Id + '';
				objContact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
				list_ContactForInsert.add(objContact);
			}
		}
		if (list_ContactForInsert.size() > 0) {
			Map<String, String> map_DMLContactInsertErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResult = database.insert(list_ContactForInsert, false);
			map_DMLContactInsertErrors = Utils.processSaveResult(list_SaveResult, list_ContactForInsert, 'email', true, 'HIFulfillmentEventTermination-processContactInformation');
			for (HI_Fulfillment_Event__c objHiFulfill : list_HIFulfillmentEvents) {
				HIFulfillmentTerminationEvenJSON objHiEventInfo = map_EvenIdsInfo.get(objHiFulfill.Id__c);
				if (map_DMLContactInsertErrors.containsKey(objHiEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLContactInsertErrors.get(objHiEventInfo.employee.email), objHiFulfill);
					continue;
				}
			}
		}

		return list_ContactForInsert;
	}

	//Get forms information
	private String getForms(Long stateCarrierid) {
		string formsInfo = '';
		if (map_stateCarrierIdsForm == null || !map_stateCarrierIdsForm.containsKey('' + stateCarrierid)) {
			formsInfo = ' not available';
		} else {
			String strMissingFormAttributes = '';
			Boolean blnFullyMapped = true, blnFitsDependents = true;
			Set<String> set_missingattributes = new Set<String>();
			for (HIFulfillmentTerminationEvenJSON.cls_forms form : map_stateCarrierIdsForm.get('' + stateCarrierid)) {
				formsInfo += '\n- ' + form.url;

				//Check for form flags, if any of the forms has fully_mapped set to false, it is set as false at case level
				if (blnFullyMapped && (form.fully_mapped == false || form.fully_mapped == null)) {
					blnFullyMapped = false;
				}
				//Check for form flags, if any of the forms has fits dependents set to false, it is set as false at case level
				if (blnFitsDependents && (form.form_includes_all_dependents == false || form.form_includes_all_dependents == null)) {
					blnFitsDependents = false;
				}
				//Get all missing values in forms and store them at case level in comma separated format
				if (form.missing_values_by_path != null && !form.missing_values_by_path.isEmpty()) {
					set_missingattributes.addAll(form.missing_values_by_path);
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
			map_stateCarrierIdsFormMappings.put('' + stateCarrierid, map_formMapping);
		}
		return formsInfo;
	}

	private List<Case> getCaseInformation(
		Map<String, caseDataWrapper> map_CaseWrapper,
		List<HI_Fulfillment_Event__c> list_HIFulfillmentEvents,
		Map<string, HIFulfillmentTerminationEvenJSON> map_EvenIdsInfo,
		Map<String, Account> map_Accounts,
		Map<String, Contact> map_Contacts,
		Map<String, Carrier__c> map_Carriers,
		Map<String, Benefit_Order__c> map_BenefitOrders
	) {
		List<Contact> list_ContactToUpdateEmail = new List<Contact>();
		List<Case> caseInsertList = new List<Case>();
		for (HI_Fulfillment_Event__c objHiFulfill : list_HIFulfillmentEvents) {
			if (objHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || objHiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (!map_EvenIdsInfo.containsKey(objHiFulfill.Id__c)) {
				continue;
			}
			HIFulfillmentTerminationEvenJSON objHiEventInfo = map_EvenIdsInfo.get(objHiFulfill.Id__c);

			Account objAccount = map_Accounts.get('' + objHiEventInfo.company.id);
			Contact objContact; // = new Contact();
			if (map_Contacts.containsKey(objHiFulfill.Id__c + '-' + objHiEventInfo.employee.email)) {
				objContact = map_Contacts.get(objHiFulfill.Id__c + '-' + objHiEventInfo.employee.email);
			} else if (map_Contacts.containsKey(objHiEventInfo.employee.email)) {
				objContact = map_Contacts.get(objHiEventInfo.employee.email);
			} else if (map_Contacts.containsKey(objHiEventInfo.employee.company_id + '-' + objHiEventInfo.employee.Id)) {
				objContact = map_Contacts.get(objHiEventInfo.employee.company_id + '-' + objHiEventInfo.employee.Id);
				objContact.Email = objHiEventInfo.employee.email;
				objContact.Unique_Email_Address_Contact__c = objHiEventInfo.employee.email;
				list_ContactToUpdateEmail.add(objContact);
			} else if (map_Contacts.containsKey('' + objHiEventInfo.employee.Id)) {
				objContact = map_Contacts.get('' + objHiEventInfo.employee.Id);
			}

			Database.DMLOptions objDMLOption = new Database.DMLOptions();
			objDMLOption.assignmentRuleHeader.useDefaultRule = true;
			Database.DMLOptions objDMLONoRule = new Database.DMLOptions();
			objDMLONoRule.assignmentRuleHeader.useDefaultRule = false;
			if (objHiEventInfo.State_carriers != null && objHiEventInfo.State_carriers.size() > 0) {
				for (HIFulfillmentTerminationEvenJSON.cls_state_carriers stateCarrier : objHiEventInfo.State_carriers) {
					if (!map_CaseWrapper.containsKey(objHiFulfill.Id__c + '-' + stateCarrier.Key)) {
						continue;
					}
					Case objCase = new Case();
					//   Setting UUID and Benefit Type Value
					if (objHiEventInfo.benefit_items != null) {
						objCase = setCaseUUIDAndTypeFields(objHiEventInfo, objCase, stateCarrier.id);
					}
					objCase.setOptions(objDMLOption);
					objCase.Integration_Id__c = objHiFulfill.Id__c;
					objCase.Integration_Key__c = objHiFulfill.Id__c + '-' + stateCarrier.Key;
					objCase.Description = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strCaseDescription;
					objCase.MF_Group_Number__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strGroupNumber;
					objCase.MF_Policy_Number__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strPolicyNumber;
					objCase.AccountId = objAccount.id;
					objCase.Company_ID__c = '' + objHiEventInfo.company.id;
					objCase.Employee_Ids__c = '' + objHiEventInfo.employee.id;
					objCase.Employee_Id__c = '' + objHiEventInfo.employee.id;
					objCase.Hi_Sent_at__c = objHiFulfill.Sent_at__c;
					objCase.Termination_Reason__c = objHiFulfill.Event_Sub_Type__c;
					objCase.Enrollment_Id__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strEnrollmentId;
					objCase.Enrollment_Key__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strEnrollmentKey + '-' + objHiFulfill.Name;
					objCase.Termination_Date__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).dtTerminationDate;
					objCase.MF_Coverage_Start_Date__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).dtCoverageStartDate;
					objCase.Fulfillment_Event_Encrypted_JSON__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strEncryptedJson;
					objCase.Selection_Ids__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strSelectionIds;

					if (objHiFulfill.Event_Type__c.equalsIgnoreCase('employee_losing_eligibility')) {
						if (stateCarrier.byb_automation_authorized == true) {
							objCase.BYB_Automation_Authorized__c = stateCarrier.byb_automation_authorized;
						}

						if (map_stateCarrierIdsFormMappings != null && map_stateCarrierIdsFormMappings.containsKey('' + stateCarrier.id)) {
							Set<String> set_terminationPolicy = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).set_TerminationPolicies;
							if (set_terminationPolicy != null && set_terminationPolicy.contains('last_day_of_employment') && set_terminationPolicy.size() == 1) {
								//If termination policy is Last_day_of_work then add 1 day to Termination Date
								objCase.First_Day_Without_Coverage__c = objCase.Termination_Date__c.addDays(1);
							} else {
								// Add 1 day to last day of termination month
								Integer intDaysInMonth = Date.daysInMonth(objCase.Termination_Date__c.Year(), objCase.Termination_Date__c.Month());
								objCase.First_Day_Without_Coverage__c = Date.newInstance(objCase.Termination_Date__c.Year(), objCase.Termination_Date__c.Month(), intDaysInMonth).addDays(1);
							}
							Map<String, Object> map_FormMapping = map_stateCarrierIdsFormMappings.get('' + stateCarrier.id);
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
						if (map_stateCarrierIdsForm != null && map_stateCarrierIdsForm.containsKey('' + stateCarrier.id) && map_stateCarrierIdsForm.get('' + stateCarrier.id) != null) {
							objCase.Number_of_Forms__c = map_stateCarrierIdsForm.get('' + stateCarrier.id).size();
						} else {
							objCase.Number_of_Forms__c = 0;
						}
					}
					if (objContact != null) {
						objCase.ContactId = objContact.Id;
					}
					if (map_BenefitOrders.containsKey('' + objHiEventInfo.company.id)) {
						Benefit_Order__c order = map_BenefitOrders.get('' + objHiEventInfo.company.id);
						objCase.Benefit_Order__c = order.id;
						objCase.Special_Instructions__c += 'Benefit Order exists with status ' + order.Order_Status__c;
						//SJay - 4/14/Case objCase - Only if BO Record Type is not Benefits BoR route the case through assignment logic
						if (map_BenefitOrders.get('' + objHiEventInfo.company.id).RecordType.DeveloperName != 'Benefits_BoR') {
							objCase.setOptions(objDMLOption);
						}
					}
					if (map_Carriers.containsKey(stateCarrier.key)) {
						objCase.Carrier__c = map_Carriers.get(stateCarrier.key).id;
					}
					objCase.RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination');
					objCase.Opps_Owner__c = 'member_fulfillment';

					objCase = this.setCaseOwnerAndType(objAccount, objHiFulfill, objCase, map_BenefitOrders);
					//SJay - 03/24/Case objCase
					if (objCase != null) {
						if (map_FulfillmentSubscriptionsCount.get(objHiFulfill.Id__c) <= 0) {
							if (map_BenefitOrders.containsKey(objAccount.ZP_Company_ID__c)) {
								objCase.Special_Instructions__c = 'There are no subscriptions and a BOR transfer record exists';
							} else {
								objCase.Special_Instructions__c = 'There are no subscriptions and a BOR transfer record does not exists';
							}
						}
					}
					objCase = populateCaseKeyFields(objCase, objHiEventInfo, stateCarrier, objHiFulfill, map_CaseWrapper);
					caseInsertList.add(objCase);
				}
			}
			if (objHiEventInfo.tada != null) {
				for (String strProviderKey : set_CarrierProviderKeys) {
					if (!map_CaseWrapper.containsKey(objHiFulfill.Id__c + '-' + strProviderKey)) {
						continue;
					}
					Case objCase = new Case();
					objCase.setOptions(objDMLOption);
					objCase.Integration_Id__c = objHiFulfill.Id__c;
					objCase.Integration_Key__c = objHiFulfill.Id__c + '-' + strProviderKey;
					objCase.Description = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + strProviderKey).strCaseDescription;
					objCase.MF_Group_Number__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + strProviderKey).strGroupNumber;
					objCase.MF_Policy_Number__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + strProviderKey).strPolicyNumber;
					objCase.AccountId = objAccount.id;
					objCase.Company_ID__c = '' + objHiEventInfo.company.id;
					objCase.Employee_Ids__c = '' + objHiEventInfo.employee.id;
					objCase.Employee_Id__c = '' + objHiEventInfo.employee.id;
					objCase.Termination_Reason__c = objHiFulfill.Event_Sub_Type__c;
					objCase.Enrollment_Id__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + strProviderKey).strEnrollmentId;
					objCase.Enrollment_Key__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + strProviderKey).strEnrollmentKey + '-' + objHiFulfill.Name;
					objCase.Termination_Date__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + strProviderKey).dtTerminationDate;
					objCase.MF_Coverage_Start_Date__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + strProviderKey).dtCoverageStartDate;
					objCase.Hi_Sent_at__c = objHiFulfill.Sent_at__c;

					if (objContact != null) {
						objCase.ContactId = objContact.Id;
					}

					if (map_BenefitOrders.containsKey('' + objHiEventInfo.company.id)) {
						Benefit_Order__c order = map_BenefitOrders.get('' + objHiEventInfo.company.id);
						objCase.Benefit_Order__c = order.id;
						objCase.Special_Instructions__c += 'Benefit Order exists with status ' + order.Order_Status__c;
						//SJay - 4/14/Case objCase - Only if BO Record Type is not Benefits BoR route the case through assignment logic
						if (map_BenefitOrders.get('' + objHiEventInfo.company.id).RecordType.DeveloperName != 'Benefits_BoR') {
							objCase.setOptions(objDMLOption);
						}
					}
					//if(map_Carriers.containsKey(stateCarrier.key)){
					objCase.Carrier__c = (map_Carriers != null && map_Carriers.containsKey(strProviderKey)) ? map_Carriers.get(strProviderKey).Id : null;
					//}
					objCase.RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination');
					objCase.Opps_Owner__c = 'member_fulfillment';
					objCase = this.setCaseOwnerAndType(objAccount, objHiFulfill, objCase, map_BenefitOrders);

					//SJay - 03/24/Case objCase
					if (objCase != null) {
						caseInsertList.add(objCase);
					}
				}
			}

			if (objHiEventInfo.tada == null && objHiEventInfo.commuter_benefit != null && objHiEventInfo.commuter_benefit.provider_key != null) {
				if (!map_CaseWrapper.containsKey(objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key)) {
					continue;
				}
				Case objCase = new Case();
				objCase.setOptions(objDMLOption);
				objCase.Integration_Id__c = objHiFulfill.Id__c;
				objCase.Integration_Key__c = objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key + 'commuter';
				objCase.Description = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key).strCaseDescription;
				objCase.MF_Group_Number__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key).strGroupNumber;
				objCase.MF_Policy_Number__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key).strPolicyNumber;
				objCase.AccountId = objAccount.id;
				objCase.Company_ID__c = '' + objHiEventInfo.company.id;
				objCase.Employee_Ids__c = '' + objHiEventInfo.employee.id;
				objCase.Employee_Id__c = '' + objHiEventInfo.employee.id;
				objCase.Termination_Reason__c = objHiFulfill.Event_Sub_Type__c;
				objCase.Enrollment_Id__c = objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key + 'commuter';
				objCase.Enrollment_Key__c = objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key + 'commuter';
				objCase.Termination_Date__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key).dtTerminationDate;
				objCase.MF_Coverage_Start_Date__c = map_CaseWrapper.get(objHiFulfill.Id__c + '-' + objHiEventInfo.commuter_benefit.provider_key).dtCoverageStartDate;
				objCase.Hi_Sent_at__c = objHiFulfill.Sent_at__c;

				if (objContact != null) {
					objCase.ContactId = objContact.Id;
				}

				if (map_BenefitOrders.containsKey('' + objHiEventInfo.company.id)) {
					Benefit_Order__c order = map_BenefitOrders.get('' + objHiEventInfo.company.id);
					objCase.Benefit_Order__c = order.id;
					objCase.Special_Instructions__c += 'Benefit Order exists with status ' + order.Order_Status__c;
					//SJay - 4/14/Case objCase - Only if BO Record Type is not Benefits BoR route the case through assignment logic
					if (map_BenefitOrders.get('' + objHiEventInfo.company.id).RecordType.DeveloperName != 'Benefits_BoR') {
						objCase.setOptions(objDMLOption);
					}
				}
				//if(map_Carriers.containsKey(stateCarrier.key)){
				objCase.Carrier__c = (map_Carriers != null && map_Carriers.containsKey(objHiEventInfo.commuter_benefit.provider_key))
					? map_Carriers.get(objHiEventInfo.commuter_benefit.provider_key).Id
					: null;
				//}
				objCase.RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination');
				objCase.Opps_Owner__c = 'member_fulfillment';

				objCase = this.setCaseOwnerAndType(objAccount, objHiFulfill, objCase, map_BenefitOrders);
				//SJay - 03/24/Case objCase
				if (objCase != null) {
					caseInsertList.add(objCase);
				}
			}
		}

		if (list_ContactToUpdateEmail.size() > 0) {
			Utils.processUpsertResult(Database.upsert(list_ContactToUpdateEmail, false), list_ContactToUpdateEmail, 'Email', true, 'HIFulfillmentEventTermination-processInformation');
		}

		return caseInsertList;
	}

	private Case setCaseOwnerAndType(Account objAccount, HI_Fulfillment_Event__c objHiFulfill, Case objCase, Map<String, Benefit_Order__c> map_BenefitOrders) {
		Database.DMLOptions objDMLOption = new Database.DMLOptions();
		objDMLOption.assignmentRuleHeader.useDefaultRule = true;
		Database.DMLOptions objDMLONoRule = new Database.DMLOptions();
		objDMLONoRule.assignmentRuleHeader.useDefaultRule = false;

		string boOwnerId = '';
		if (map_BenefitOrders != null && map_BenefitOrders.containsKey(objAccount.ZP_Company_ID__c)) {
			boOwnerId = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).OwnerId;
		}
		// SJay - 03/27/Case objCase - Added employee_losing_eligibility event.
		// employee_losing_eligibility and sub type Termination.
		if (
			objHiFulfill.Event_Type__c == 'employee_losing_eligibility' &&
			objHiFulfill.Event_Sub_Type__c == 'Termination' &&
			map_BenefitOrders != null &&
			map_BenefitOrders.containsKey(objAccount.ZP_Company_ID__c) &&
			map_BenefitOrders.get(objAccount.ZP_Company_ID__c).RecordType.Name == 'Benefits BoR'
		) {
			// SJay - 03/24/Case objCase - Added check for BO status to be prior to Plans Confirmed to create a BOR Term case.
			if (!set_CreateTermBORCaseForStatuses.contains(map_BenefitOrders.get(objAccount.ZP_Company_ID__c).Order_Status__c)) {
				objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR - Termination');
				objCase.Type = 'Termination';
				objCase.Benefit_Order__c = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).Id;

				if (String.isNotBlank(boOwnerId) && boOwnerId.indexOf('00G') < 0) {
					objCase.OwnerId = boOwnerId;
					objCase.setOptions(objDMLONoRule);
				} else {
					objDMLOption = new Database.DMLOptions();
					objCase.setOptions(objDMLOption);
				}
				return objCase;
			} else {
				// After Plans Confirmed:
				objCase.RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination');
				objCase.setOptions(objDMLOption);
				objCase.Status = 'New';
				objCase.Type = 'Termination';
				objCase.Benefit_Order__c = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).Id;
				return objCase;
			}
		}

		if (objHiFulfill.Event_Type__c == 'employee_losing_eligibility_during_bor') {
			if (map_BenefitOrders.containsKey(objAccount.ZP_Company_ID__c) || objHiFulfill.Ops_Owner__c == 'bor_transfer_fulfillment') {
				objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR - Termination');
				objCase.Opps_Owner__c = 'bor_transfer';

				objCase.Benefit_Order__c = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).Id;

				if (boOwnerId.indexOf('00G') < 0) {
					objCase.OwnerId = boOwnerId;
				} else {
					objDMLOption = new Database.DMLOptions();
					objCase.setOptions(objDMLOption);
				}
			}
		}
		if (objHiFulfill.Event_Type__c == 'employee_losing_eligibility_during_new_plans') {
			if (map_BenefitOrders.containsKey(objAccount.ZP_Company_ID__c)) {
				objCase.Benefit_Order__c = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).Id;
				objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits New Plan Case');
				objCase.Type = 'Termination';
				objCase.Opps_Owner__c = 'new_plan';
				objCase.OwnerId = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).OwnerId;
				objCase.setOptions(objDMLOption);
				return objCase;
			}
		}

		if (objHiFulfill.Event_Type__c == 'employee_losing_eligibility_during_renewals') {
			if (map_BenefitOrders.containsKey(objAccount.ZP_Company_ID__c)) {
				objCase.Benefit_Order__c = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).Id;
				objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Renewal Case');
				objCase.Type = 'Termination';
				objCase.Opps_Owner__c = 'renewal';
				objCase.OwnerId = map_BenefitOrders.get(objAccount.ZP_Company_ID__c).OwnerId;
				objCase.setOptions(objDMLOption);
				return objCase;
			}
		}
		return objCase;
	}

	/**
	 * @description setting up various case fields like Medical_UUID__c,Dental_UUID__c from objBenefitItem.policy_uuid
	 * @author Nigam Goyal | 02-22-2023
	 * @param objHiEventInfo
	 * @param objCase
	 * @param strStateCarrierId
	 * @return Case
	 **/
	private Case setCaseUUIDAndTypeFields(HIFulfillmentTerminationEvenJSON objHiEventInfo, Case objCase, Long strStateCarrierId) {
		Set<String> set_BenefitTypes = new Set<String>();
		Set<String> set_SelectionUUIDs = new Set<String>();
		Set<String> set_MedicalUUIDs = new Set<String>();
		Set<String> set_DentalUUIDs = new Set<String>();
		Set<String> set_LifeUUIDs = new Set<String>();
		Set<String> set_VisionUUIDs = new Set<String>();
		Set<String> set_LTDUUIDs = new Set<String>();
		Set<String> set_STDUUIDs = new Set<String>();

		for (HIFulfillmentTerminationEvenJSON.cls_benefit_items objBenefitItem : objHiEventInfo.benefit_items) {
			if (String.isBlank(objBenefitItem.uuid)) {
				continue;
			}

			if (objBenefitItem.state_carrier_id == strStateCarrierId) {
				switch on objBenefitItem.benefit_type {
					when 'medical' {
						set_MedicalUUIDs.add(objBenefitItem.uuid);
						set_BenefitTypes.add(HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL);
						set_SelectionUUIDs.add(objCase.Medical_UUID__c);
					}
					when 'dental' {
						set_DentalUUIDs.add(objBenefitItem.uuid);
						set_BenefitTypes.add(HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL);
						set_SelectionUUIDs.add(objCase.Dental_UUID__c);
					}
					when 'life' {
						set_LifeUUIDs.add(objBenefitItem.uuid);
						set_BenefitTypes.add(HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE);
						set_SelectionUUIDs.add(objCase.Life_UUID__c);
					}
					when 'vision' {
						set_VisionUUIDs.add(objBenefitItem.uuid);
						set_BenefitTypes.add(HIEnrollmentEventUtility.BENEFIT_TYPE_VISION);
						set_SelectionUUIDs.add(objCase.Vision_UUID__c);
					}
					when 'long_term_disability' {
						set_LTDUUIDs.add(objBenefitItem.uuid);
						set_BenefitTypes.add(HIEnrollmentEventUtility.BENEFIT_TYPE_LTD);
						set_SelectionUUIDs.add(objCase.Long_Term_Disability_UUID__c);
					}
					when 'short_term_disability' {
						set_STDUUIDs.add(objBenefitItem.uuid);
						set_BenefitTypes.add(HIEnrollmentEventUtility.BENEFIT_TYPE_STD);
						set_SelectionUUIDs.add(objCase.Short_Term_Disability_UUID__c);
					}
				}

				if (String.isNotBlank(objBenefitItem.coverage_end_date)) {
					objCase.MF_Coverage_End_Date__c = Date.valueOf(objBenefitItem.coverage_end_date);
				}
			}
		}

		// objCase.Selection_UUIDs__c = String.join(new List<String>(set_SelectionUUIDs), ';');
		objCase.Benefit_Types__c = String.join(new List<String>(set_BenefitTypes), ';').trim().left(255);
		objCase.Medical_UUID__c = !set_MedicalUUIDs.isEmpty() ? String.join(new List<String>(set_MedicalUUIDs), ';').trim().left(255) : null;
		objCase.Dental_UUID__c = !set_DentalUUIDs.isEmpty() ? String.join(new List<String>(set_DentalUUIDs), ';').trim().left(255) : null;
		objCase.Life_UUID__c = !set_LifeUUIDs.isEmpty() ? String.join(new List<String>(set_LifeUUIDs), ';').trim().left(255) : null;
		objCase.Vision_UUID__c = !set_VisionUUIDs.isEmpty() ? String.join(new List<String>(set_VisionUUIDs), ';').trim().left(255) : null;
		objCase.Long_Term_Disability_UUID__c = !set_LTDUUIDs.isEmpty() ? String.join(new List<String>(set_LTDUUIDs), ';').trim().left(255) : null;
		objCase.Short_Term_Disability_UUID__c = !set_STDUUIDs.isEmpty() ? String.join(new List<String>(set_STDUUIDs), ';').trim().left(255) : null;

		return objCase;
	}

	private String getCarrierBotJson(HIFulfillmentTerminationEvenJSON terminationJson, Long carrierId, Blob blbEncryptionKey) {
		HIFulfillmentBotTerminationEventJSON objBOTJson = new HIFulfillmentBotTerminationEventJSON();
		objBOTJson.control_info = new HIFulfillmentBotTerminationEventJSON.control_info();
		objBOTJson.control_info.case_id = '';
		objBOTJson.losing_benefits_date = terminationJson.benefits_eligibility_end_date;
		objBOTJson.losing_benefits_reason = terminationJson.losing_benefits_reason;
		objBOTJson.carrier_directory = terminationJson.carrier_directory;
		objBOTJson.employee = (HIFulfillmentBotTerminationEventJSON.cls_employee) System.JSON.deserialize(
			'' + JSON.serialize(terminationJson.employee),
			HIFulfillmentBotTerminationEventJSON.cls_employee.class
		);
		objBOTJson.company = (HIFulfillmentBotTerminationEventJSON.cls_company) System.JSON.deserialize(
			'' + JSON.serialize(terminationJson.company),
			HIFulfillmentBotTerminationEventJSON.cls_company.class
		);
		for (HIFulfillmentTerminationEvenJSON.cls_state_carriers objCarrier : terminationJson.state_carriers) {
			if (objCarrier.id == carrierId) {
				objBOTJson.state_carrier = (HIFulfillmentBotTerminationEventJSON.cls_state_carrier) System.JSON.deserialize(
					'' + JSON.serialize(objCarrier),
					HIFulfillmentBotTerminationEventJSON.cls_state_carrier.class
				);
			}
		}
		objBOTJson.terminated_benefit_items = new List<HIFulfillmentBotTerminationEventJSON.cls_benefit_items>();
		if (terminationJson.benefit_items != null) {
			for (HIFulfillmentTerminationEvenJSON.cls_benefit_items objBenefitItem : terminationJson.benefit_items) {
				if (objBenefitItem.state_carrier_id == carrierId) {
					HIFulfillmentBotTerminationEventJSON.cls_benefit_items benItem = (HIFulfillmentBotTerminationEventJSON.cls_benefit_items) System.JSON.deserialize(
						'' + JSON.serialize(objBenefitItem),
						HIFulfillmentBotTerminationEventJSON.cls_benefit_items.class
					);
					objBOTJson.terminated_benefit_items.add(benItem);
					strSelectionIds += '' + objBenefitItem.Id + ';';
				}
			}
		}
		objBOTJson.policies = new List<HIFulfillmentBotTerminationEventJSON.cls_policies>();
		for (HIFulfillmentTerminationEvenJSON.cls_policies objPolicy : terminationJson.policies) {
			if (objPolicy.state_carrier_id == carrierId) {
				HIFulfillmentBotTerminationEventJSON.cls_policies objNewPolicy = (HIFulfillmentBotTerminationEventJSON.cls_policies) System.JSON.deserialize(
					'' + JSON.serialize(objPolicy),
					HIFulfillmentBotTerminationEventJSON.cls_policies.class
				);
				objBOTJson.policies.add(objNewPolicy);
				if (String.isNotBlank(objNewPolicy.group_number)) {
					strPolicyGroupNumber = objNewPolicy.group_number;
				}
				if (String.isNotBlank(objNewPolicy.policy_number)) {
					strPolicyNumber = objNewPolicy.policy_number;
				}
			}
		}
		if (terminationJson.dependents.size() > 0) {
			objBOTJson.dependents = new List<HIFulfillmentBotTerminationEventJSON.cls_dependents>();
			for (HIFulfillmentTerminationEvenJSON.cls_dependents objDependent : terminationJson.dependents) {
				HIFulfillmentBotTerminationEventJSON.cls_dependents newDep = (HIFulfillmentBotTerminationEventJSON.cls_dependents) System.JSON.deserialize(
					'' + JSON.serialize(objDependent),
					HIFulfillmentBotTerminationEventJSON.cls_dependents.class
				);
				objBOTJson.dependents.add(newDep);
			}

			//objBOTJson.dependents=(List<HIFulfillmentBotEnrollmentJSON.Dependent>)System.JSON.deserialize(''+JSON.serialize(enrollmentJson.dependents), HIFulfillmentBotEnrollmentJSON.dependents.class);
		} else {
			objBOTJson.dependents = new List<HIFulfillmentBotTerminationEventJSON.cls_dependents>();
		}
		objBOTJson.benefits_url = terminationJson.benefits_url;
		objBOTJson.dependents_url = terminationJson.dependents_url;

		Blob blbBOTEncrypted = EncryptionUtils.getEncryptedBlob(blbEncryptionKey, '' + JSON.serialize(objBOTJson));
		String strBOTJsonString = EncodingUtil.base64Encode(blbBOTEncrypted);

		return strBOTJsonString;
	}

	public Map<String, Case> getExistingCaseInfomation(Set<String> set_EmployeeIds, Set<String> set_ZPCompanyIds) {
		Map<String, Case> map_CancelTerminationCases = new Map<String, Case>();
		String strKey = '';
		for (Case objCase : [
			SELECT
				id,
				Employee_id__c,
				Carrier__c,
				Carrier__r.Name,
				Carrier__r.Partner_type__c,
				Account.ZP_Company_Id__c,
				Enrollment_Key__c,
				Carrier__r.Key__c,
				Closed_Reason__c,
				HI_Sent_at__c,
				Status,
				Description,
				BYOB_Customer__c,
				Selection_Ids__c,
				Fulfillment_Event_Encrypted_JSON__c
			FROM Case
			WHERE
				Carrier__c != NULL
				AND Account.ZP_Company_Id__c IN :set_ZPCompanyIds
				AND Employee_id__c IN :set_EmployeeIds
				AND Type = 'Termination'
				AND Status IN ('Draft', 'New', 'On Hold', 'Submitted', 'Closed')
				AND CreatedDate = LAST_N_DAYS:364
		]) {
			strKey = objCase.Account.ZP_Company_Id__c + '-' + objCase.Employee_id__c + '-' + objCase.Carrier__r.Key__c;
			if (map_AllCarrierWithEmployeeIds.containsKey(strKey)) {
				if (objCase.Carrier__r.Partner_type__c == 'TAdA') {
					if (!map_CancelTerminationCases.containsKey(strKey) || objCase.Status != 'Closed') {
						map_CancelTerminationCases.put(strKey, objCase);
					}
				} else {
					if (String.isNotBlank(objCase.Selection_Ids__c)) {
						for (String strSelectionsId : map_AllCarrierWithEmployeeIds.get(strKey)) {
							if (objCase.Selection_Ids__c.contains(strSelectionsId)) {
								if (!map_CancelTerminationCases.containsKey(strKey + '-' + strSelectionsId) || objCase.Status != 'Closed') {
									map_CancelTerminationCases.put(strKey + '-' + strSelectionsId, objCase);
								}
							}
						}
					}
				}
			}
		}

		return map_CancelTerminationCases;
	}

	public static List<String> getSelectionId(Long lngCarrierId, List<HIFulfillmentTerminationEvenJSON.cls_benefit_items> list_BenefitItems) {
		List<String> list_SelectionIds = new List<String>();
		if (list_BenefitItems != null) {
			for (HIFulfillmentTerminationEvenJSON.cls_benefit_items objBenefitItem : list_BenefitItems) {
				if (objBenefitItem.state_carrier_id == lngCarrierId) {
					list_SelectionIds.add(objBenefitItem.id + '');
				}
			}
		}

		return list_SelectionIds;
	}

	public Date getCoverageEndDate(HIFulfillmentTerminationEvenJSON.cls_tada objTadas) {
		Date dtCoverageEndDate = null;

		List<HIFulfillmentTerminationEvenJSON.cls_benefit_items> list_TadasSubscription = new List<HIFulfillmentTerminationEvenJSON.cls_benefit_items>();
		if (objTadas.fsa != null) {
			if (objTadas.fsa.benefit_items != null) {
				list_TadasSubscription.addAll(objTadas.fsa.benefit_items);
			}
		}
		if (objTadas.dca != null) {
			if (objTadas.dca.benefit_items != null) {
				list_TadasSubscription.addAll(objTadas.dca.benefit_items);
			}
		}

		if (list_TadasSubscription.size() > 0) {
			for (HIFulfillmentTerminationEvenJSON.cls_benefit_items objSubscription : list_TadasSubscription) {
				if (String.isNotBlank(objSubscription.coverage_end_date)) {
					if (dtCoverageEndDate == null) {
						dtCoverageEndDate = Date.valueOf(objSubscription.coverage_end_date);
					} else if (dtCoverageEndDate > Date.valueOf(objSubscription.coverage_end_date)) {
						dtCoverageEndDate = Date.valueOf(objSubscription.coverage_end_date);
					}
				}
			}
		}

		return dtCoverageEndDate;
	}

	public class ExistingTerminationCaseWrapper {
		public set<String> set_EmployeeIds_CarrierKeys { get; set; }
		public list<Case> list_Cases { get; set; }
	}

	public class caseDataWrapper {
		public String strEventId { get; set; }
		public String strStateCarrierKey { get; set; }
		public String strEventType { get; set; }
		public Long lngZPCompanyId { get; set; }
		public String strEemployeeEmail { get; set; }
		public String strCaseDescription { get; set; }
		public Date dtTerminationDate { get; set; }
		public String strEnrollmentId { get; set; }
		public String strEnrollmentKey { get; set; }
		public HIFulfillmentTerminationEvenJSON objHIEventInfo { get; set; }
		public String strPiiInformation { get; set; }
		public String strEncryptedJson { get; set; }
		public String strSelectionIds { get; set; }
		public String strGroupNumber { get; set; }
		public String strPolicyNumber { get; set; }
		public Date dtCoverageStartDate { get; set; }
		public Set<String> set_TerminationPolicies { get; set; }

		public caseDataWrapper(
			String strEventId,
			String strStateCarrierKey,
			String strEventType,
			Long lngZPCompanyId,
			String strEemployeeEmail,
			String strCaseDescription,
			Date dtTerminationDate,
			String strEnrollmentId,
			String strEnrollmentKey,
			HIFulfillmentTerminationEvenJSON objHIEventInfo,
			String strPiiInformation,
			String strEncryptedJson,
			String strSelectionIds,
			String strGroupNumber,
			String strPolicyNumber,
			Date dtCoverageStartDate,
			Set<String> set_TerminationPolicies
		) {
			this.strEventId = strEventId;
			this.strStateCarrierKey = strStateCarrierKey;
			this.strEventType = strEventType;
			this.lngZPCompanyId = lngZPCompanyId;
			this.strEemployeeEmail = strEemployeeEmail;
			this.strCaseDescription = strCaseDescription;
			this.dtTerminationDate = dtTerminationDate;
			this.strEnrollmentId = strEnrollmentId;
			this.strEnrollmentKey = strEnrollmentKey;
			this.objHIEventInfo = objHIEventInfo;
			this.strPiiInformation = strPiiInformation;
			this.strEncryptedJson = strEncryptedJson;
			this.strSelectionIds = strSelectionIds;
			this.strGroupNumber = strGroupNumber;
			this.strPolicyNumber = strPolicyNumber;
			this.dtCoverageStartDate = dtCoverageStartDate;
			this.set_TerminationPolicies = set_TerminationPolicies;
		}
	}

	public class HIFulfillmentEventWrapper {
		public String strEventId;
		public String strCompanyId { get; set; }
		public String strEmployeeId { get; set; }
		public String strCarrierKey { get; set; }
		public Date dtBenefitsEligibilityEndDate { get; set; }
		public Date dtCoverageEndDate { get; set; }

		public HIFulfillmentEventWrapper(String strEventId, String strCompanyId, String strEmployeeId, String strCarrierKey, Date dtBenefitsEligibilityEndDate, Date dtCoverageEndDate) {
			this.strEventId = strEventId;
			this.strCompanyId = strCompanyId;
			this.strEmployeeId = strEmployeeId;
			this.strCarrierKey = strCarrierKey;
			this.dtBenefitsEligibilityEndDate = dtBenefitsEligibilityEndDate;
			this.dtCoverageEndDate = dtCoverageEndDate;
		}
	}
	/**
	 * Description populates Case - Fulfillment_Event_Encrypted_JSON__c for existing cases
	 * @param objCase Holds the case record
	 * @param objHIWrapper Holds the HIFulfillmentEventWrapper
	 * @return Case - with updated Fulfillment_Event_Encrypted_JSON__c
	 */
	private Case populateFulfillmentEventEncryptedJSON(Case objCase, HIFulfillmentEventWrapper objHIWrapper) {
		if(String.isNotBlank(objCase.Fulfillment_Event_Encrypted_JSON__c)) {
			Blob blbDecrypted = EncodingUtil.base64Decode(objCase.Fulfillment_Event_Encrypted_JSON__c);
			String strDeCryptedText = EncryptionUtils.getDecryptedText(ENCRYPTION_KEY, blbDecrypted);
			strDeCryptedText = strDeCryptedText.removeStart('"');
			strDeCryptedText = strDeCryptedText.removeEnd('"');
			HIFulfillmentBotTerminationEventJSON objBOTJson = (HIFulfillmentBotTerminationEventJSON) System.JSON.deserialize(strDeCryptedText, HIFulfillmentBotTerminationEventJSON.class);
			objBOTJson.losing_benefits_date = String.valueOf(objHIWrapper.dtBenefitsEligibilityEndDate);
			Blob blbBOTEncrypted = EncryptionUtils.getEncryptedBlob(ENCRYPTION_KEY, JSON.serialize(objBOTJson));
			String strBOTJsonString = EncodingUtil.base64Encode(blbBOTEncrypted);
			objCase.Fulfillment_Event_Encrypted_JSON__c = strBOTJsonString;
		}
		return objCase;
	}

	/**
	 * Description populates Case - Key Field based on Existing case 
	 * if it exists in system to make sure system updated existing case
	 * @param objCase Holds the case record
	 * @param objHiEventInfo Holds the HIFulfillmentEventWrapper
	 * @param stateCarrier Holds the HIFulfillmentEventWrapper
	 * @param objHiFulfill Holds the HIFulfillmentEventWrapper
	 * @param map_CaseWrapper Holds the HIFulfillmentEventWrapper
	 * @return Case - with updated Key fields
	 */
	private Case populateCaseKeyFields(Case objCase, HIFulfillmentTerminationEvenJSON objHiEventInfo, HIFulfillmentTerminationEvenJSON.cls_state_carriers stateCarrier, HI_Fulfillment_Event__c objHiFulfill, Map<String, caseDataWrapper> map_CaseWrapper) {
		String strSearchKey = objHiEventInfo.employee.company_id + '-' + objHiEventInfo.employee.id + '-' + stateCarrier.key;
		List<String> list_SelectionItemIds = map_AllCarrierWithEmployeeIds.get(strSearchKey);
		for (String strId : list_SelectionItemIds) {
			String strExistingCaseKey = strSearchKey + '-' + strId;
			Case existingObjCase = map_ExistingCases.get(strExistingCaseKey);
			Boolean updateSenario = existingObjCase!= null && existingObjCase.Status != 'Closed';
			objCase.Integration_Id__c = updateSenario ? existingObjCase.Integration_Id__c : objHiFulfill.Id__c;
			objCase.Integration_Key__c = updateSenario ? existingObjCase.Integration_Key__c : objHiFulfill.Id__c + '-' + stateCarrier.Key;
			objCase.Enrollment_Id__c = updateSenario ? existingObjCase.Enrollment_Key__c : map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strEnrollmentId;
			objCase.Enrollment_Key__c = updateSenario ? existingObjCase.Enrollment_Key__c : map_CaseWrapper.get(objHiFulfill.Id__c + '-' + stateCarrier.Key).strEnrollmentKey + '-' + objHiFulfill.Name;
		}
		return objCase;
	}
}