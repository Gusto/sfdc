public class HIFulfillmentEventEnrollment {
	Map<String, integer> fulfillmentSubscriptionCountMap = new Map<String, integer>();
	Map<String, List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>> stateCarrierBenefitTypeNewSubscriptionMap = new Map<String, List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>>();
	Map<String, List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>> stateCarrierBenefitTypeOverlappingSubscriptionMap = new Map<String, List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>>();
	Map<String, Map<String, set<String>>> stateCarrierNewDependentIdMap = new Map<String, Map<String, set<String>>>();
	Map<String, Map<String, set<String>>> stateCarrierOverlapingDependentIdMap = new Map<String, Map<String, set<String>>>();
	Map<String, String> effectiveDateMap = new Map<String, String>();
	String effectiveDate = '';
	Map<String, set<String>> stateCarrierSubscriptionIdMap = new Map<String, set<String>>();
	Map<String, set<String>> enrollmentEnrollmentKeyMap = new Map<String, set<String>>();
	Map<String, String> phiInfoMap = new Map<String, String>();
	map<String, List<HIFulfillmentEnrollmentEventJSON.Form>> map_stateCarrierIdForm;
	map<String, Map<String, Object>> map_stateCarrierIdFormMappings;
	String selectionIds = '';
	String policyGroupNumber = '';
	String policyNumber = '';
	String strSelectionUUIDs = '';

	public void processInformation(List<HI_Fulfillment_Event__c> fulfillmentList) {
		CaseTriggerHelper.context = 'FulfillmentEvent';
		Set<String> hiFulfillmentIDSet = new Set<String>();
		List<HI_Fulfillment_Event__c> toUpsertFulfillmentList = new List<HI_Fulfillment_Event__c>();
		List<Case> caseList = new List<Case>();
		Set<String> carrierKeySet = new Set<String>();
		Set<String> accountIdZPSet = new Set<String>();
		Set<String> employeeEmailSet = new Set<String>();
		Map<String, String> mapCarrierKeyToId = new Map<String, String>();
		Map<String, String> mapAccountZPToId = new Map<String, String>();
		Map<String, String> mapContactEmailToId = new Map<String, String>();
		Map<String, HIFulfillmentEnrollmentEventJSON> evenIdInfoMap = new Map<String, HIFulfillmentEnrollmentEventJSON>();
		Map<String, CaseDataWrapper> caseWrapperMap = new Map<String, CaseDataWrapper>();
		enrollmentEnrollmentKeyMap = new Map<String, set<String>>();

		List<Contact> listContact = new List<Contact>();
		Set<String> setNewContactEmails = new Set<String>();
		Set<String> companyIdSet = new Set<String>();
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
				HIFulfillmentEnrollmentEventJSON hiEventInfoParsed;
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

				if ((hiEventInfoParsed.State_carriers == null || hiEventInfoParsed.State_carriers.size() == 0) && hiEventInfoParsed.alegeus == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'State Carrier information does not exist.', hiFulfill);
					continue;
				}
				if (hiEventInfoParsed.benefit_items == null && hiEventInfoParsed.alegeus == null) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Subscription information does not exist.', hiFulfill);
					continue;
				}
				accountIdZPSet.add(String.valueOf(hiEventInfoParsed.company.id));
				employeeEmailSet.add(hiEventInfoParsed.employee.email);

				Map<String, HIFulfillmentEnrollmentEventJSON.Dependent> mapDependents = new Map<String, HIFulfillmentEnrollmentEventJSON.Dependent>();
				if (hiEventInfoParsed.dependents != null && hiEventInfoParsed.dependents.size() > 0) {
					for (HIFulfillmentEnrollmentEventJSON.Dependent dependent : hiEventInfoParsed.dependents) {
						mapDependents.put('' + dependent.id, dependent);
					}
				}
				evenIdInfoMap.put(hiFulfill.Id__c, hiEventInfoParsed);
				Map<String, Set<String>> mapCarrierToDependentId = new Map<String, Set<String>>();
				Map<String, List<HIFulfillmentEnrollmentEventJSON.subscriptions>> mapCarrierToSubscriptionList = new Map<String, List<HIFulfillmentEnrollmentEventJSON.subscriptions>>();
				map<String, HIFulfillmentEnrollmentEventJSON.Policy> policyIdMap = new Map<String, HIFulfillmentEnrollmentEventJSON.Policy>();

				if (hiEventInfoParsed.policies != null && hiEventInfoParsed.policies.size() > 0) {
					for (HIFulfillmentEnrollmentEventJSON.Policy objPolicy : hiEventInfoParsed.policies) {
						policyIdMap.put('' + objPolicy.id, objPolicy);
					}
				}
				map_stateCarrierIdForm = new Map<String, List<HIFulfillmentEnrollmentEventJSON.Form>>(); // key is State CarrierId and value is Form
				map_stateCarrierIdFormMappings = new Map<String, Map<String, Object>>();
				if (hiEventInfoParsed.forms != null && hiEventInfoParsed.forms.size() > 0) {
					for (HIFulfillmentEnrollmentEventJSON.Form objForm : hiEventInfoParsed.forms) {
						String strKey = '' + objForm.state_carrier_id;
						List<HIFulfillmentEnrollmentEventJSON.Form> list_forms;
						if (map_stateCarrierIdForm.containsKey(strKey)) {
							list_forms = map_stateCarrierIdForm.get(strKey);
						} else {
							list_forms = new List<HIFulfillmentEnrollmentEventJSON.Form>();
						}
						list_forms.add(objForm);
						map_stateCarrierIdForm.put(strKey, list_forms);
					}
				}
				stateCarrierBenefitTypeNewSubscriptionMap = new Map<String, List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>>();
				stateCarrierBenefitTypeOverlappingSubscriptionMap = new Map<String, List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>>();
				stateCarrierNewDependentIdMap = new Map<String, Map<String, set<String>>>();
				stateCarrierOverlapingDependentIdMap = new Map<String, Map<String, set<String>>>();
				effectiveDateMap = new Map<String, String>();
				effectiveDate = '';
				stateCarrierSubscriptionIdMap = new Map<String, set<String>>();

				setCarrierTypeSubscriptionInfo(hiEventInfoParsed.benefit_items);
				HIFulfillmentEnrollmentEventJSON.HomeAddress employeeHomeAddress = hiEventInfoParsed.employee.home_address;
				HIFulfillmentEnrollmentEventJSON.Address companyBenefitAddress = hiEventInfoParsed.company.benefits_address;
				boolean stateCarrierError = false;

				for (HIFulfillmentEnrollmentEventJSON.StateCarrier stateCarrier : hiEventInfoParsed.State_carriers) {
					carrierKeySet.add(stateCarrier.key);
					String caseDescription = '', strSubscriptionInfo = '';
					String piiInformation = '';

					if (stateCarrier.key == null || stateCarrier.key == '') {
						stateCarrierError = true;
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'State Carrier Key: field value is missing in the record.', hiFulfill);
						continue;
					}

					List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo> newSubscriptionList = new List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>();
					List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo> OverlappingSubscriptionList = new List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>();

					Map<String, set<String>> benefitTypeNewDependentMap = new Map<String, set<String>>();
					Map<String, set<String>> benefitTypeOverlappingDependentMap = new Map<String, set<String>>();
                    
					if (stateCarrierBenefitTypeNewSubscriptionMap.containsKey('' + stateCarrier.id)) {
						newSubscriptionList = stateCarrierBenefitTypeNewSubscriptionMap.get('' + stateCarrier.id);
					}
					if (stateCarrierBenefitTypeOverlappingSubscriptionMap.containsKey('' + stateCarrier.id)) {
						OverlappingSubscriptionList = stateCarrierBenefitTypeOverlappingSubscriptionMap.get('' + stateCarrier.id);
					}
					hiFulfill.Message__c += '<<' + stateCarrierBenefitTypeNewSubscriptionMap.size() + '>>';
					if (newSubscriptionList.size() == 0 && OverlappingSubscriptionList.size() == 0) {
						stateCarrierError = true;
						hiFulfill.Message__c += 'Both New and Overlapping subscription does not exist.' + stateCarrier.id + '-';
                        
						continue;
					} else {
						hiFulfill.Message__c += '~~' + stateCarrier.id + '-' + newSubscriptionList.size();
					}

					if (stateCarrierNewDependentIdMap.containsKey('' + stateCarrier.id)) {
						benefitTypeNewDependentMap = stateCarrierNewDependentIdMap.get('' + stateCarrier.id);
					}
					if (stateCarrierOverlapingDependentIdMap.containsKey('' + stateCarrier.id)) {
						benefitTypeOverlappingDependentMap = stateCarrierOverlapingDependentIdMap.get('' + stateCarrier.id);
					}
					if (effectiveDateMap.containsKey('' + stateCarrier.id)) {
						effectiveDate = effectiveDateMap.get('' + stateCarrier.id);
					}
					Date effDate;
                    
					if (effectiveDate != null && effectiveDate != '') {
						effDate = Date.valueOf(effectiveDate);
					}
					if (hiEventInfoParsed.recent_qles != null && hiEventInfoParsed.recent_qles.size() > 0) {
						for (HIFulfillmentEnrollmentEventJSON.RecentQle qle : hiEventInfoParsed.recent_qles) {
							caseDescription += '\nEvent Type: ' + Utils.humanize(qle.event);
							caseDescription += '\nEvent Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(qle.date_of_event);
							caseDescription += '\nFile Upload Url\'s: ' + qle.file_upload_urls;
						}
					}
					String employeeName = HIFulfillmentEventHelperFunctions.getName(
						hiEventInfoParsed.employee.first_Name,
						hiEventInfoParsed.employee.last_Name,
						hiEventInfoParsed.employee.middle_initial
					);
					caseDescription += '\n\n' + employeeName + ' of ' + hiEventInfoParsed.company.name + ' would like to enroll in the following ' + stateCarrier.name + ' plans:';
					caseDescription += '\nEffective Date : ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(effectiveDate);
					caseDescription += '\n\nLink to carrier enrollment data: ' + hiEventInfoParsed.enrollment.url + '/' + stateCarrier.key;
					caseDescription += '\nLink to employee\'s subscriptions: ' + hiEventInfoParsed.employee.hippo_url + '/subscriptions';
					caseDescription += '\nLink to employee\'s enrollments: ' + hiEventInfoParsed.employee.hippo_url + '/enrollments';
					caseDescription += '\nEE Panda Link: ' + hiEventInfoParsed.employee.panda_url;
					caseDescription += '\n\nCarrier';
					caseDescription += '\n- Carrier: ' + stateCarrier.name;
					caseDescription += '\n- Carrier State: ' + stateCarrier.state;
					caseDescription += '\n\n***** New Subscription *****';
					string groupIds = '';
					integer i = 1;
					String oppsOwner = '';

					piiInformation += 'Employee Info:';
					piiInformation += '<br/>- Name: ' + employeeName;
					piiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN(hiEventInfoParsed.employee.ssn);
					piiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);

					Map<String, String> map_BenefitTypeToUUID = new Map<String, String>();
					for (HIFulfillmentEnrollmentEventJSON.SubscriptionInfo subscInfo : newSubscriptionList) {
						HIFulfillmentEnrollmentEventJSON.Policy policy = policyIdMap.get('' + subscInfo.policy_id);
						if (policy == null) {
							continue;
						}
						if (policy.group_number != null && policy.group_number != '') {
							if (groupIds != '') {
								groupIds += ',';
							}
							groupIds += policy.group_number;
						}
						if (String.isNotBlank(subscInfo.benefit_type)) {
							map_BenefitTypeToUUID.put(subscInfo.benefit_type, subscInfo.uuid);
						}
						strSubscriptionInfo += '\n' + i + '. ' + subscInfo.benefit_type + ': ' + policy.name;
						strSubscriptionInfo += '\n- Estimated Start Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(subscInfo.estimated_start_date);
						strSubscriptionInfo += '\n- Group ID: ' + policy.group_number;
						strSubscriptionInfo += '\n- Policy Number: ' + policy.policy_number;
						Set<String> dependentSet = new Set<String>();
						if (benefitTypeNewDependentMap.containsKey(subscInfo.benefit_type)) {
							dependentSet = benefitTypeNewDependentMap.get(subscInfo.benefit_type);
						}
						strSubscriptionInfo += '\n\n- Number of Active Dependents: ' + dependentSet.size();
						strSubscriptionInfo += '\n- EE estimated premium: ' + subscInfo.estimated_employee_premium;
						strSubscriptionInfo += '\n- Dependents estimated premium: ' + subscInfo.estimated_dependents_premium;
						strSubscriptionInfo += '\n- Total estimated premium: ' + subscInfo.estimated_total_premium;
						i += 1;
						if (subscInfo.ops_owner != null && subscInfo.ops_owner != '') {
							oppsOwner = subscInfo.ops_owner;
						}
					}
					caseDescription += strSubscriptionInfo;
					caseDescription += '\n\n***** Overlapping Subscription *****';
					i = 1;
					for (HIFulfillmentEnrollmentEventJSON.SubscriptionInfo subscInfo : OverlappingSubscriptionList) {
						HIFulfillmentEnrollmentEventJSON.Policy policy = policyIdMap.get('' + subscInfo.policy_id);
						String policyName = '';
						String groupnumber = '';
						String policyNumber = '';
						if (policy != null) {
							policyName = policy.name;
							groupnumber = policy.group_number;
							policyNumber = policy.policy_number;
						}
						caseDescription += '\n' + i + '. ' + subscInfo.benefit_type + ': ' + policyName;
						caseDescription += '\n- Group ID: ' + groupnumber;
						caseDescription += '\n- Policy Number: ' + policyNumber;
						Set<String> dependentSet = new Set<String>();
						if (benefitTypeNewDependentMap.containsKey(subscInfo.benefit_type)) {
							dependentSet = benefitTypeNewDependentMap.get(subscInfo.benefit_type);
						}
						caseDescription += '\n- Number of Active Dependents: ' + dependentSet.size();
						i += 1;
						if (subscInfo.ops_owner != null && subscInfo.ops_owner != '') {
							oppsOwner = subscInfo.ops_owner;
						}
					}

					piiInformation += '<br/> Dependent Information';
					for (HIFulfillmentEnrollmentEventJSON.Dependent dependent : hiEventInfoParsed.dependents) {
						piiInformation += '<br/>- Name: ' + HIFulfillmentEventHelperFunctions.getName(dependent.first_Name, dependent.last_Name, '');
						piiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN(hiEventInfoParsed.employee.ssn);
						piiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);
					}
                    
					Set<String> subscriptionIdSet = stateCarrierSubscriptionIdMap.get('' + stateCarrier.id);
					string subscriptionStr = '';
					if (subscriptionIdSet != null) {
						for (String subscrId : subscriptionIdSet) {
							subscriptionStr += subscrId + ',';
						}
					}
					caseDescription += '\n\nPlease submit ALL linked forms to the carrier\nForms ' + getForms(stateCarrier.id);
					selectionIds = '';
					strSelectionUUIDs = '';
					policyGroupNumber = '';
					policyNumber = '';
					String botJson = getCarrierBotJson(hiEventInfoParsed, stateCarrier.id, encryptionKey);

					caseDataWrapper caseWrapper = new caseDataWrapper(
						hiFulfill.Id__c,
						stateCarrier.key,
						hiFulfill.Event_Type__c,
						hiEventInfoParsed.company.id,
						hiEventInfoParsed.employee.email,
						caseDescription,
						subscriptionStr,
						effDate,
						groupIds,
						oppsOwner,
						hiEventInfoParsed,
						piiInformation,
						botJson,
						selectionIds,
						policyGroupNumber,
						policyNumber,
						strSubscriptionInfo,
						strSelectionUUIDs,
						map_BenefitTypeToUUID
					);

					caseWrapperMap.put(hiFulfill.id__c + '-' + stateCarrier.key, caseWrapper);
				}

				if (hiEventInfoParsed.alegeus != null) {
					String oppsOwner = '';
					List<HIFulfillmentEnrollmentEventJSON.ABHPSubscription> abhpalegeusSubscList = new List<HIFulfillmentEnrollmentEventJSON.ABHPSubscription>();
					if (hiEventInfoParsed.alegeus.fsa != null) {
						abhpalegeusSubscList.add(hiEventInfoParsed.alegeus.fsa);
						if (hiEventInfoParsed.alegeus.fsa.policies != null) {
							for (HIFulfillmentEnrollmentEventJSON.policy objPolicy : hiEventInfoParsed.alegeus.fsa.policies) {
								policyIdMap.put('' + objPolicy.id, objPolicy);
							}
						}
					}
					if (hiEventInfoParsed.alegeus.dca != null) {
						abhpalegeusSubscList.add(hiEventInfoParsed.alegeus.dca);
						if (hiEventInfoParsed.alegeus.dca.policies != null) {
							for (HIFulfillmentEnrollmentEventJSON.policy objPolicy : hiEventInfoParsed.alegeus.dca.policies) {
								policyIdMap.put('' + objPolicy.id, objPolicy);
							}
						}
					}

					String caseDescription = '';
					string subscriptionStr = '';
					Date effDate;
					integer i = 1;
					for (HIFulfillmentEnrollmentEventJSON.ABHPSubscription alegeusInfo : abhpalegeusSubscList) {
						List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo> newSubscriptionList = new List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>();
						List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo> OverlappingSubscriptionList = new List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>();

						if (alegeusInfo.benefit_items.current != null) {
							if (
								alegeusInfo.benefit_items.current.ops_owner == null ||
								alegeusInfo.benefit_items.current.ops_owner == '' ||
								Label.Enrollment_Ready_For_Processing.indexOf(alegeusInfo.benefit_items.current.ops_owner) < 0
							) {
								continue;
							}
							oppsOwner = 'member_fulfillment';
							newSubscriptionList.add(alegeusInfo.benefit_items.current);
							subscriptionStr += alegeusInfo.benefit_items.current.id + ',';
						}
						if (alegeusInfo.benefit_items.overlapping != null) {
							for (HIFulfillmentEnrollmentEventJSON.SubscriptionInfo overlapInfo : alegeusInfo.benefit_items.overlapping) {
								OverlappingSubscriptionList.add(overlapInfo);
								subscriptionStr += overlapInfo.id + ',';
							}
						}
                        
						if (newSubscriptionList.size() == 0 && OverlappingSubscriptionList.size() == 0) {
							stateCarrierError = true;
							hiFulfill.Message__c = 'Both New and Overlapping subscription does not exist.';
                            
							continue;
						}
                        
						effectiveDate = '';
						if (newSubscriptionList.size() > 0) {
							if (newSubscriptionList[0].estimated_start_date != null) {
								effectiveDate = newSubscriptionList[0].estimated_start_date;
							}
						}
                        
						if (effectiveDate != null && effectiveDate != '') {
							effDate = Date.valueOf(effectiveDate);
						}
                        
						if (hiEventInfoParsed.recent_qles != null && hiEventInfoParsed.recent_qles.size() > 0) {
							for (HIFulfillmentEnrollmentEventJSON.RecentQle qle : hiEventInfoParsed.recent_qles) {
								caseDescription += '\nEvent Type: ' + Utils.humanize(qle.event);
								caseDescription += '\nEvent Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(qle.date_of_event);
								caseDescription += '\nFile Upload Url\'s: ' + qle.file_upload_urls;
							}
						}

						for (HIFulfillmentEnrollmentEventJSON.SubscriptionInfo subscInfo : newSubscriptionList) {
							HIFulfillmentEnrollmentEventJSON.Policy policy = policyIdMap.get('' + subscInfo.policy_id);
							caseDescription += '\n\n***** New Subscription *****';
							caseDescription += '\n' + i + '. ' + subscInfo.benefit_type + ': ' + policy.name;
							caseDescription += '\n- Estimated Start Date: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(subscInfo.estimated_start_date);
							caseDescription += '\n- Group ID: ' + policy.group_number;
							caseDescription += '\n- Policy Number: ' + policy.policy_number;
							caseDescription += '\n- EE estimated premium: ' + subscInfo.estimated_employee_premium;
							caseDescription += '\n- Dependents estimated premium: ' + subscInfo.estimated_dependents_premium;
							caseDescription += '\n- Total estimated premium: ' + subscInfo.estimated_total_premium;
							i += 1;
							if (subscInfo.ops_owner != null && subscInfo.ops_owner != '') {
								oppsOwner = subscInfo.ops_owner;
							}
						}
                        
						for (HIFulfillmentEnrollmentEventJSON.SubscriptionInfo subscInfo : OverlappingSubscriptionList) {
							caseDescription += '\n\n***** Overlapping Subscription *****';
							HIFulfillmentEnrollmentEventJSON.Policy policy = policyIdMap.get('' + subscInfo.policy_id);
							caseDescription += '\n' + i + '. ' + subscInfo.benefit_type + ': ' + policy.name;
							caseDescription += '\n- Group ID: ' + policy.group_number;
							caseDescription += '\n- Policy Number: ' + policy.policy_number;
							i += 1;
							if (subscInfo.ops_owner != null && subscInfo.ops_owner != '') {
								oppsOwner = subscInfo.ops_owner;
							}
						}
					}

					if (caseDescription != '' || hiEventInfoParsed.alegeus.hsa != null) {
						String employeeName = HIFulfillmentEventHelperFunctions.getName(
							hiEventInfoParsed.employee.first_Name,
							hiEventInfoParsed.employee.last_Name,
							hiEventInfoParsed.employee.middle_initial
						);
						String newCaseDescription = '\n\n' + employeeName + ' of ' + hiEventInfoParsed.company.name + ' would like to enroll in the following Alegeus plans:';
						newCaseDescription += '\nEffective Date : ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(effectiveDate);
						newCaseDescription += '\nLink to employee\'s subscriptions: ' + hiEventInfoParsed.employee.hippo_url + '/subscriptions';
						newCaseDescription += '\nLink to employee\'s enrollments: ' + hiEventInfoParsed.employee.hippo_url + '/enrollments';
						newCaseDescription += '\nEE Panda Link: ' + hiEventInfoParsed.employee.panda_url;
						newCaseDescription += '\n\nCarrier';
						newCaseDescription += '\n- Carrier: Alegeus';

						caseDescription = newCaseDescription + caseDescription;

						if (hiEventInfoParsed.alegeus.hsa != null) {
							caseDescription += '\n\n HSA Policy Url: ' + hiEventInfoParsed.alegeus.hsa.hsa_benefit.url;
						}

						String piiInformation = 'Employee Info:';
						piiInformation += '<br/>- Name: ' + employeeName;
						piiInformation += '<br/>- SSN: ' + HIFulfillmentEventHelperFunctions.getFormatedSSN(hiEventInfoParsed.employee.ssn);
						piiInformation += '<br/>- DOB: ' + HIFulfillmentEventHelperFunctions.getChangeDateFormat(hiEventInfoParsed.employee.birthday);

						caseDataWrapper caseWrapper = new caseDataWrapper(
							hiFulfill.Id__c,
							'alegeus',
							hiFulfill.Event_Type__c,
							hiEventInfoParsed.company.id,
							hiEventInfoParsed.employee.email,
							caseDescription,
							subscriptionStr,
							effDate,
							'',
							oppsOwner,
							hiEventInfoParsed,
							piiInformation,
							'',
							'',
							'',
							'',
							'',
							'',
							null
						);

						caseWrapperMap.put(hiFulfill.id__c + '-' + 'alegeus', caseWrapper);
					}
				}
			}
		}

		map<String, Account> accountMap = HIFulfillmentEventHelperFunctions.getAccounts(accountIdZPSet);
		map<String, Contact> contactMap = HIFulfillmentEventHelperFunctions.getContacts(employeeEmailSet);
		map<String, Carrier__c> carrierMap = HIFulfillmentEventHelperFunctions.getCarrierInfo(carrierKeySet);
		map<String, Benefit_Order__c> benefitOrderMap = HIFulfillmentEventHelperFunctions.getBenefitOrderMap(accountIdZPSet);

		processContactInformation(fulfillmentList, evenIdInfoMap, accountMap, contactMap);

		contactMap = HIFulfillmentEventHelperFunctions.getContacts(employeeEmailSet);

		List<Case> caseListForUpsert = getCaseInformation(caseWrapperMap, fulfillmentList, evenIdInfoMap, accountMap, contactMap, carrierMap, benefitOrderMap);
        
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
					Attachment atch = new Attachment();
					atch.ParentId = c.Id;
					atch.Body = EncryptionUtils.getEncryptedBlob(encryptionKey, wrapper.piiInformation);
					atch.Name = 'encFile.txt';
					attachmentList.add(atch);
				}
			}
		}
		if (attachmentList.size() > 0) {
			insert attachmentList;
		}
	}

	//calling HIFulfillmentEnrollmentEventJSON class for parsing data
	public static HIFulfillmentEnrollmentEventJSON getJSONParsedData(String jsonString) {
		HIFulfillmentEnrollmentEventJSON parsedData = (HIFulfillmentEnrollmentEventJSON) JSON.deserialize(jsonString, HIFulfillmentEnrollmentEventJSON.class);
		return parsedData;
	}

	private void processContactInformation(
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentEnrollmentEventJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Contact> contactListForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			HIFulfillmentEnrollmentEventJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);

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
				HIFulfillmentEnrollmentEventJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
				if (dmlContactInsertErrorsMap.containsKey(hiEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlContactInsertErrorsMap.get(hiEventInfo.employee.email), hiFulfill);
					continue;
				}
			}
		}
	}

	private void setCarrierTypeSubscriptionInfo(HIFulfillmentEnrollmentEventJSON.Subscriptions subscriptions) {
		system.debug('subscriptions :: ' + subscriptions);
		List<HIFulfillmentEnrollmentEventJSON.CarrierTypeSubscription> carrierTypeSubscriptionList = new List<HIFulfillmentEnrollmentEventJSON.CarrierTypeSubscription>();
		if (subscriptions != null) {
			if (subscriptions.medical != null) {
				carrierTypeSubscriptionList.add(subscriptions.medical);
			}
			if (subscriptions.dental != null) {
				carrierTypeSubscriptionList.add(subscriptions.dental);
			}
			if (subscriptions.vision != null) {
				carrierTypeSubscriptionList.add(subscriptions.vision);
			}
			if (subscriptions.life != null) {
				carrierTypeSubscriptionList.add(subscriptions.life);
			}
			if (subscriptions.long_term_disability != null) {
				carrierTypeSubscriptionList.add(subscriptions.long_term_disability);
			}
			if (subscriptions.short_term_disability != null) {
				carrierTypeSubscriptionList.add(subscriptions.short_term_disability);
			}
			if (subscriptions.voluntary_short_term_disability != null) {
				carrierTypeSubscriptionList.add(subscriptions.voluntary_short_term_disability);
			}
			if (subscriptions.voluntary_long_term_disability != null) {
				carrierTypeSubscriptionList.add(subscriptions.voluntary_long_term_disability);
			}
			if (subscriptions.voluntary_life != null) {
				carrierTypeSubscriptionList.add(subscriptions.voluntary_life);
			}
		}
        
		for (HIFulfillmentEnrollmentEventJSON.CarrierTypeSubscription carrerTypeSubscr : carrierTypeSubscriptionList) {
			if (carrerTypeSubscr.current != null) {
				HIFulfillmentEnrollmentEventJSON.SubscriptionInfo subscrInfo = carrerTypeSubscr.current;
				List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo> subscrInfoList = new List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>();
				Map<String, set<String>> benefitTypeDependentMap = new Map<String, set<String>>();
				if (stateCarrierBenefitTypeNewSubscriptionMap.containsKey('' + subscrInfo.state_carrier_id)) {
					subscrInfoList = stateCarrierBenefitTypeNewSubscriptionMap.get('' + subscrInfo.state_carrier_id);
				}
				if (stateCarrierNewDependentIdMap.containsKey('' + subscrInfo.state_carrier_id)) {
					benefitTypeDependentMap = stateCarrierNewDependentIdMap.get('' + subscrInfo.state_carrier_id);
				}
				if (carrerTypeSubscr.current.benefit_type != null) {
					effectiveDateMap.put('' + subscrInfo.state_carrier_id, carrerTypeSubscr.current.estimated_start_date);
					effectiveDate = carrerTypeSubscr.current.estimated_start_date;

					if (subscrInfo.ops_owner != null && subscrInfo.ops_owner != '' && Label.Enrollment_Ready_For_Processing.indexOf(subscrInfo.ops_owner) > -1) {
						subscrInfoList.add(carrerTypeSubscr.current);
						stateCarrierBenefitTypeNewSubscriptionMap.put('' + subscrInfo.state_carrier_id, subscrInfoList);
					} else {
						continue;
					}

					if (carrerTypeSubscr.current.dependent_ids != null && carrerTypeSubscr.current.dependent_ids.size() > 0) {
						Set<String> dependentIdList = new Set<String>();
						if (benefitTypeDependentMap.containsKey(carrerTypeSubscr.current.benefit_type)) {
							dependentIdList = benefitTypeDependentMap.get(carrerTypeSubscr.current.benefit_type);
						}
						for (Long depId : carrerTypeSubscr.current.dependent_ids) {
							dependentIdList.add('' + depId);
						}
						benefitTypeDependentMap.put(carrerTypeSubscr.current.benefit_type, dependentIdList);
						stateCarrierNewDependentIdMap.put('' + subscrInfo.state_carrier_id, benefitTypeDependentMap);
					}
				}

				Set<String> subscriptionIdSet = new Set<String>();
				if (stateCarrierSubscriptionIdMap.containsKey('' + subscrInfo.state_carrier_id)) {
					subscriptionIdSet = stateCarrierSubscriptionIdMap.get('' + subscrInfo.state_carrier_id);
				}
				subscriptionIdSet.add('' + carrerTypeSubscr.current.id);
				stateCarrierSubscriptionIdMap.put('' + subscrInfo.state_carrier_id, subscriptionIdSet);
			}
            
			if (carrerTypeSubscr.overlapping != null) {
				for (HIFulfillmentEnrollmentEventJSON.SubscriptionInfo subscrInfo : carrerTypeSubscr.overlapping) {
					List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo> subscrInfoList = new List<HIFulfillmentEnrollmentEventJSON.SubscriptionInfo>();
					Map<String, set<String>> benefitTypeDependentMap = new Map<String, set<String>>();

					if (stateCarrierBenefitTypeOverlappingSubscriptionMap.containsKey('' + subscrInfo.state_carrier_id)) {
						subscrInfoList = stateCarrierBenefitTypeOverlappingSubscriptionMap.get('' + subscrInfo.state_carrier_id);
					}
					if (stateCarrierOverlapingDependentIdMap.containsKey('' + subscrInfo.state_carrier_id)) {
						benefitTypeDependentMap = stateCarrierOverlapingDependentIdMap.get('' + subscrInfo.state_carrier_id);
					}
					if (subscrInfo.benefit_type != null) {
						if (carrerTypeSubscr.current == null && !effectiveDateMap.containsKey('' + subscrInfo.state_carrier_id) && subscrInfo.start_date != null) {
							effectiveDateMap.put('' + subscrInfo.state_carrier_id, subscrInfo.start_date);
						}
						subscrInfoList.add(subscrInfo);

						stateCarrierBenefitTypeOverlappingSubscriptionMap.put('' + subscrInfo.state_carrier_id, subscrInfoList);

						if (subscrInfo.dependent_ids != null && subscrInfo.dependent_ids.size() > 0) {
							Set<String> dependentIdList = new Set<String>();
							if (benefitTypeDependentMap.containsKey(subscrInfo.benefit_type)) {
								dependentIdList = benefitTypeDependentMap.get(subscrInfo.benefit_type);
							}
							for (Long depId : subscrInfo.dependent_ids) {
								dependentIdList.add('' + depId);
							}
							benefitTypeDependentMap.put(subscrInfo.benefit_type, dependentIdList);
							stateCarrierNewDependentIdMap.put('' + subscrInfo.state_carrier_id, benefitTypeDependentMap);
						}

						Set<String> subscriptionIdSet = new Set<String>();
						if (stateCarrierSubscriptionIdMap.containsKey('' + subscrInfo.state_carrier_id)) {
							subscriptionIdSet = stateCarrierSubscriptionIdMap.get('' + subscrInfo.state_carrier_id);
						}
						subscriptionIdSet.add('' + subscrInfo.id);
						stateCarrierSubscriptionIdMap.put('' + subscrInfo.state_carrier_id, subscriptionIdSet);
					}
				}
			}
		}
	}

	private List<Case> getCaseInformation(
		map<String, caseDataWrapper> caseWrapperMap,
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentEnrollmentEventJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap,
		map<String, Carrier__c> carrierMap,
		map<String, Benefit_Order__c> benefitOrderMap
	) {
		List<QLE_Event_Type_Map__c> QleEventTypeList = QLE_Event_Type_Map__c.getall().values();
		map<String, String> qleEventTypeMap = new Map<String, String>();
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

		for (QLE_Event_Type_Map__c type : QleEventTypeList) {
			qleEventTypeMap.put(type.Name, type.Salesforce_Value__c);
		}

		set<string> hiIdCarrierIdUniqueKeySet = new Set<string>();
		map<String, String> caseInfoMap = new Map<String, String>();
		Set<String> enrollmentKeyset = new Set<String>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			HIFulfillmentEnrollmentEventJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (hiEventInfo == null) {
				continue;
			}
			for (HIFulfillmentEnrollmentEventJSON.StateCarrier stateCarrier : hiEventInfo.state_carriers) {
				if (hiFulfill.Event_Type__c == 'voluntary_lidi_ready_for_processing') {
					enrollmentKeyset.add(hiEventInfo.enrollment.id + '-' + stateCarrier.Key + '-vl');
				} else {
					enrollmentKeyset.add(hiEventInfo.enrollment.id + '-' + stateCarrier.Key);
				}
			}

			//by: PR, 2/8/2019, Moved the logic from Policied to Benefit Items and based on related Carrier Id
			if (hiEventInfo.benefit_items != null) {
				if (
					hiEventInfo.benefit_items.voluntary_short_term_disability != null &&
					hiEventInfo.benefit_items.voluntary_short_term_disability.current != null &&
					hiEventInfo.benefit_items.voluntary_short_term_disability.current.state_carrier_id != null
				) {
					hiIdCarrierIdUniqueKeySet.add(hiFulFill.Id__c + hiEventInfo.benefit_items.voluntary_short_term_disability.current.state_carrier_id);
				}

				if (
					hiEventInfo.benefit_items.voluntary_long_term_disability != null &&
					hiEventInfo.benefit_items.voluntary_long_term_disability.current != null &&
					hiEventInfo.benefit_items.voluntary_long_term_disability.current.state_carrier_id != null
				) {
					hiIdCarrierIdUniqueKeySet.add(hiFulFill.Id__c + hiEventInfo.benefit_items.voluntary_long_term_disability.current.state_carrier_id);
				}

				if (
					hiEventInfo.benefit_items.voluntary_life != null &&
					hiEventInfo.benefit_items.voluntary_life.current != null &&
					hiEventInfo.benefit_items.voluntary_life.current.state_carrier_id != null
				) {
					hiIdCarrierIdUniqueKeySet.add(hiFulFill.Id__c + hiEventInfo.benefit_items.voluntary_life.current.state_carrier_id);
				}
			}
		}

		for (Case c : [SELECT Id, Status, Enrollment_key__c FROM case WHERE Enrollment_Key__c IN :enrollmentKeyset]) {
			caseInfoMap.put(c.Enrollment_Key__c, c.Status);
		}
        
		List<Case> caseInsertList = new List<Case>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentEnrollmentEventJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);

			Account acc = accountMap.get('' + hiEventInfo.company.id);
			Benefit_Order__c order = new Benefit_Order__c();
			Contact c;
			if (contactMap.containsKey(hiFulfill.Id__c + '-' + hiEventInfo.employee.email)) {
				c = contactMap.get(hiFulfill.Id__c + '-' + hiEventInfo.employee.email);
			} else if (contactMap.containsKey(hiEventInfo.employee.email)) {
				c = contactMap.get(hiEventInfo.employee.email);
			}
            
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Database.DMLOptions dmoNoRule = new Database.DMLOptions();
			dmoNoRule.assignmentRuleHeader.useDefaultRule = false;
            
			for (HIFulfillmentEnrollmentEventJSON.StateCarrier stateCarrier : hiEventInfo.state_carriers) {
				if (!caseWrapperMap.containsKey(hiFulfill.Id__c + '-' + stateCarrier.Key)) {
					continue;
				}
				//Case should not be created if enrollment source is bor_transfer_source
				if (hiFulfill.Event_Type__c == 'enrollment_ready_for_processing' && 'bor_transfer_source'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
					continue;
				}
				CaseDataWrapper objCaseWrap = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key);

				Case cse = new Case();
				cse.Integration_Id__c = hiFulfill.Id__c;
				cse.Integration_Key__c = hiFulfill.Id__c + '-' + stateCarrier.Key;
				if (hiFulfill.Event_Type__c == 'voluntary_lidi_ready_for_processing') {
					cse.Enrollment_Key__c = hiEventInfo.enrollment.id + '-' + stateCarrier.Key + '-vl';
				} else {
					cse.Enrollment_Key__c = hiEventInfo.enrollment.id + '-' + stateCarrier.Key;
				}

				//@Neha Jan 6,2021 : Populate UUIDs on case based on Benefit Types
				cse.Benefit_Types__c = '';
				if (objCaseWrap.map_BenefitTypeToUUID != null && !objCaseWrap.map_BenefitTypeToUUID.isEmpty()) {
					for (String strBenefitType : objCaseWrap.map_BenefitTypeToUUID.keySet()) {
						String strUUID = objCaseWrap.map_BenefitTypeToUUID.get(strBenefitType);
						switch on strBenefitType {
							when 'dental' {
								cse.Dental_UUID__c = strUUID;
								if (!cse.Benefit_Types__c.containsIgnoreCase('Dental')) {
									cse.Benefit_Types__c += 'Dental;';
								}
							}
							when 'vision' {
								cse.Vision_UUID__c = strUUID;
								if (!cse.Benefit_Types__c.containsIgnoreCase('Vision')) {
									cse.Benefit_Types__c += 'Vision;';
								}
							}
							when 'medical' {
								cse.Medical_UUID__c = strUUID;
								if (!cse.Benefit_Types__c.containsIgnoreCase('Medical')) {
									cse.Benefit_Types__c += 'Medical;';
								}
							}
							when 'long_term_disability' {
								cse.Long_Term_Disability_UUID__c = strUUID;
								if (!cse.Benefit_Types__c.containsIgnoreCase('Long Term Disability')) {
									cse.Benefit_Types__c += 'Long Term Disability;';
								}
							}
							when 'short_term_disability' {
								cse.Short_Term_Disability_UUID__c = strUUID;
								if (!cse.Benefit_Types__c.containsIgnoreCase('Short Term Disability')) {
									cse.Benefit_Types__c += 'Short Term Disability;';
								}
							}
							when 'life' {
								cse.Life_UUID__c = strUUID;
								if (!cse.Benefit_Types__c.containsIgnoreCase('Life')) {
									cse.Benefit_Types__c += 'Life;';
								}
							}
						}
					}
				}
				// if condition introduced by: PR. Date: 2/8/2019. // logic is based on Carrier Id in Benefit items which we are getting from Json
				string uniqueKeyStr = hiFulFill.Id__c + stateCarrier.id;
				if (
					(hiFulfill.Event_Type__c == 'enrollment_ready_for_processing' || hiFulfill.Event_Type__c == 'voluntary_lidi_ready_for_processing') &&
					hiIdCarrierIdUniqueKeySet.contains(uniqueKeyStr)
				) {
					cse.Fulfillment_Type__c = 'Voluntary Life and Disability Enrollment';
				}

				cse.Enrollment_Id__c = '' + hiEventInfo.enrollment.id;
				cse.Description = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).caseDescription;
				cse.MF_Group_Number__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).groupNumber;
				cse.MF_Policy_Number__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).policyNumber;
				cse.Fulfillment_Event_Encrypted_JSON__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).encryptedJson;
				cse.Selection_Ids__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).selectionIds;
				cse.Selection_UUIDs__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).strSelectionUUIDs;
				cse.Group_Ids__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).groupIds;
				cse.Company_ID__c = '' + hiEventInfo.company.id;
				cse.Employee_Ids__c = '' + hiEventInfo.employee.id;
				cse.Employee_Id__c = '' + hiEventInfo.employee.id;
				cse.AccountId = acc.id;
				if (hiEventInfo.Employee.hired_at != null && hiEventInfo.Employee.hired_at != '') {
					cse.Hire_Date__c = Date.valueOf(hiEventInfo.Employee.hired_at);
				}
				if (hiEventInfo.Employee.benefits_eligibility_date != null && hiEventInfo.Employee.benefits_eligibility_date != '') {
					cse.Benefits_Eligibility_Date__c = Date.valueOf(hiEventInfo.Employee.benefits_eligibility_date);
				}
				if (c != null) {
					cse.ContactId = c.Id;
				}
				if (benefitOrderMap.containsKey('' + hiEventInfo.company.id)) {
					order = benefitOrderMap.get('' + hiEventInfo.company.id);
					cse.Benefit_Order__c = order.id;
					cse.Special_Instructions__c += 'Benefit Order exists with status ' + order.Order_Status__c;
				}
				cse.Anticipated_Effective_Date__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).effectiveDate;
				cse.Subscription_Ids__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).subscriptionIds;
				if (carrierMap.containsKey(stateCarrier.key)) {
					cse.Carrier__c = carrierMap.get(stateCarrier.key).id;
				}

				if (caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).oppsOwner == 'bor_transfer' && benefitOrderMap.containsKey('' + hiEventInfo.company.id)) {
					cse.Opps_Owner__c = 'bor_transfer';
					cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
					if ('new_hire_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.Type = 'NHE';
					} else if ('qualifying_life_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.Type = 'QLE';
						for (HIFulfillmentEnrollmentEventJSON.RecentQle recentQle : hiEventInfo.recent_qles) {
							if (qleEventTypeMap.containsKey(recentQle.event)) {
								cse.QLE_Event_Type__c = qleEventTypeMap.get(recentQle.event);
							}
						}
					}
                    
					if (string.valueof(order.OwnerId).indexOf('00G') < 0) {
						cse.OwnerId = order.OwnerId;
					} else {
						cse.setOptions(dmo);
					}
				} else {
					cse.setOptions(dmo);
					cse.Opps_Owner__c = 'member_fulfillment';
					if (hiFulfill.Event_Type__c == 'enrollment_ready_for_processing') {
						if ('qualifying_life_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
							cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
							cse.Type = 'QLE';
							for (HIFulfillmentEnrollmentEventJSON.RecentQle recentQle : hiEventInfo.recent_qles) {
								if (qleEventTypeMap.containsKey(recentQle.event)) {
									cse.QLE_Event_Type__c = qleEventTypeMap.get(recentQle.event);
								}
							}
						} else {
							cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');
							cse.Type = 'NHE';
							if ('open_enrollment_start'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
								cse.Enrollment_Source__c = 'OE';
							}
							if (map_stateCarrierIdFormMappings != null && map_stateCarrierIdFormMappings.containsKey('' + stateCarrier.id)) {
								Map<String, Object> map_FormMapping = map_stateCarrierIdFormMappings.get('' + stateCarrier.id);
								if (map_FormMapping != null) {
									if (map_FormMapping.containsKey('fullymapped')) {
										cse.Form_Fully_Mapped__c = (Boolean) map_FormMapping.get('fullymapped');
									}
									if (map_FormMapping.containsKey('missingattributes')) {
										cse.Missing_Form_Attributes__c = (String) map_FormMapping.get('missingattributes');
									}
									if (map_FormMapping.containsKey('fitsdependents')) {
										cse.Form_Fits_Dependents__c = (Boolean) map_FormMapping.get('fitsdependents');
									}
								}
							}
							if (map_stateCarrierIdForm != null && map_stateCarrierIdForm.containsKey('' + stateCarrier.id) && map_stateCarrierIdForm.get('' + stateCarrier.id) != null) {
								cse.Number_of_Forms__c = map_stateCarrierIdForm.get('' + stateCarrier.id).size();
							} else {
								cse.Number_of_Forms__c = 0;
							}
							cse.Subscription_Information__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + stateCarrier.Key).strSubscriptionInfo;
						}
					}
				}
				if (caseInfoMap.containsKey(hiEventInfo.enrollment.id + '-' + stateCarrier.Key)) {
					String status = caseInfoMap.get(hiEventInfo.enrollment.id + '-' + stateCarrier.Key);
					if (status == 'Cancelled') {
						cse.Status = 'New';
						cse.OwnerId = label.Member_Fulfillment_Queue; //@Neha Dabas June 1 2020, Assign reopened cases to Member Fulfillment Queue
						cse.setOptions(dmoNoRule);
					}
				}
				// SJay - 03/27/2020 - Added check for Benefit Order Status. If BO status is plans confirmed or higher route it to MF QLE.
				if (order != null && order.RecordType.DeveloperName == 'Benefits_BoR' && set_CreateCaseForStatus.contains(order.Order_Status__c)) {
					if ('new_hire_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');
						cse.Type = 'NHE';
					} else if ('qualifying_life_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
						cse.Type = 'QLE';
					}
					cse.OwnerId = label.Member_Fulfillment_Queue;
					cse.Status = 'New';
				}
				//For NHE Cases, copy error_message sent from HIPPO to Case
				if (String.IsNotBlank(hiEventInfo.error_Message) && cse.RecordTypeId == cache.getRecordTypeId('Case', 'MF NHE')) {
					cse.HI_Integration_Error_Message__c = hiEventInfo.error_Message;
				}
				caseInsertList.add(cse);
			}
			if (hiEventInfo.alegeus != null) {
				if (!caseWrapperMap.containsKey(hiFulfill.Id__c + '-' + 'alegeus')) {
					continue;
				}
				Case cse = new Case();
				cse.setOptions(dmo);
				cse.Integration_Id__c = hiFulfill.Id__c;
				cse.Integration_Key__c = hiFulfill.Id__c + '-' + 'alegeus';
				cse.Enrollment_Key__c = hiEventInfo.enrollment.id + '-' + 'alegeus';
				cse.Enrollment_Id__c = '' + hiEventInfo.enrollment.id;
				cse.Description = caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').caseDescription;
				cse.MF_Group_Number__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').groupNumber;
				cse.MF_Policy_Number__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').policyNumber;
				cse.Employee_Ids__c = '' + hiEventInfo.employee.id;
				cse.Employee_Id__c = '' + hiEventInfo.employee.id;
				cse.AccountId = acc.id;
				cse.Fulfillment_Type__c = 'FSA/DCA Enrollment';
				if (hiEventInfo.Employee.benefits_eligibility_date != null && hiEventInfo.Employee.benefits_eligibility_date != '') {
					cse.Benefits_Eligibility_Date__c = Date.valueOf(hiEventInfo.Employee.benefits_eligibility_date);
				}

				if (c != null) {
					cse.ContactId = c.Id;
				}
				if (benefitOrderMap.containsKey('' + hiEventInfo.company.id)) {
					order = benefitOrderMap.get('' + hiEventInfo.company.id);
					cse.Benefit_Order__c = order.id;
					cse.Special_Instructions__c += 'Benefit Order exists with status ' + order.Order_Status__c;
				}
				cse.Anticipated_Effective_Date__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').effectiveDate;
				cse.Subscription_Ids__c = caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').subscriptionIds;
				cse.Carrier__c = Label.alegeus;

				if (caseWrapperMap.get(hiFulfill.Id__c + '-' + 'alegeus').oppsOwner == 'bor_transfer' && benefitOrderMap.containsKey('' + hiEventInfo.company.id)) {
					cse.Opps_Owner__c = 'bor_transfer';
					if ('new_hire_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');
						cse.Type = 'NHE';
					} else if ('qualifying_life_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
						cse.Type = 'QLE';
					}
					cse.Benefit_Order__c = order.id;
					if (string.valueof(order.OwnerId).indexOf('00G') < 0) {
						cse.OwnerId = order.OwnerId;
					} else {
						cse.setOptions(dmo);
					}
				} else {
					cse.Opps_Owner__c = 'member_fulfillment';
					if ('qualifying_life_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
						cse.Type = 'QLE';
					} else {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');
						cse.Type = 'NHE';
						if ('open_enrollment_start'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
							cse.Enrollment_Source__c = 'OE';
						}
					}
				}
				if (caseInfoMap.containsKey(hiEventInfo.enrollment.id + '-' + 'alegeus')) {
					String status = caseInfoMap.get(hiEventInfo.enrollment.id + '-' + 'alegeus');
					if (status == 'Cancelled') {
						cse.Status = 'New';
						cse.OwnerId = label.Member_Fulfillment_Queue; //@Neha Dabas June 1 2020, Assign reopened cases to Member Fulfillment Queue
						cse.setOptions(dmoNoRule);
					}
				}
				// SJay - 03/27/2020 - Added check for Benefit Order Status. If BO status is plans confirmed or higher route it to MF QLE.
				// SJay - 06/23/2020 - Added Case type check to route to either MF NHE or MF QLE based on the recent qles from json.
				if (order != null && order.RecordType.DeveloperName == 'Benefits_BoR' && set_CreateCaseForStatus.contains(order.Order_Status__c)) {
					if ('new_hire_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF NHE');
						cse.Type = 'NHE';
					} else if ('qualifying_life_event'.equalsIgnoreCase(hiEventInfo.enrollment_source)) {
						cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
						cse.Type = 'QLE';
					}
					cse.OwnerId = label.Member_Fulfillment_Queue;
					cse.Status = 'New';
				}

				//For NHE Cases, copy error_message sent from HIPPO to Case
				if (String.IsNotBlank(hiEventInfo.error_Message) && cse.RecordTypeId == cache.getRecordTypeId('Case', 'MF NHE')) {
					cse.HI_Integration_Error_Message__c = hiEventInfo.error_Message;
				}
				caseInsertList.add(cse);
			}
		}
		return caseInsertList;
	}

	private String getCarrierBotJson(HIFulfillmentEnrollmentEventJSON enrollmentJson, Long carrierId, Blob encryptionKey) {
		HIFulfillmentBotEnrollmentJSON botJson = new HIFulfillmentBotEnrollmentJSON();
		botJson.control_info = new HIFulfillmentBotEnrollmentJSON.control_info();
		botJson.control_info.case_id = '';
		botJson.enrollment = (HIFulfillmentBotEnrollmentJSON.enrollment) System.JSON.deserialize('' + JSON.serialize(enrollmentJson.enrollment), HIFulfillmentBotEnrollmentJSON.enrollment.class);
		if (enrollmentJson.recent_qles.size() > 0) {
			botJson.recent_qles = new List<HIFulfillmentBotEnrollmentJSON.RecentQle>();
			for (HIFulfillmentEnrollmentEventJSON.RecentQle qle : enrollmentJson.recent_qles) {
				HIFulfillmentBotEnrollmentJSON.RecentQle recQle = (HIFulfillmentBotEnrollmentJSON.RecentQle) System.JSON.deserialize(
					'' + JSON.serialize(qle),
					HIFulfillmentBotEnrollmentJSON.RecentQle.class
				);
				botJson.recent_qles.add(recQle);
			}
		} else {
			botJson.recent_qles = new List<HIFulfillmentBotEnrollmentJSON.RecentQle>();
		}
		botJson.carrier_directory = enrollmentJson.carrier_directory;
		botJson.employee = (HIFulfillmentBotEnrollmentJSON.employee) System.JSON.deserialize('' + JSON.serialize(enrollmentJson.employee), HIFulfillmentBotEnrollmentJSON.employee.class);
		botJson.company = (HIFulfillmentBotEnrollmentJSON.company) System.JSON.deserialize('' + JSON.serialize(enrollmentJson.company), HIFulfillmentBotEnrollmentJSON.company.class);
		for (HIFulfillmentEnrollmentEventJSON.StateCarrier carrier : enrollmentJson.state_carriers) {
			if (carrier.id == carrierId) {
				botJson.state_carrier = (HIFulfillmentBotEnrollmentJSON.state_carrier) System.JSON.deserialize('' + JSON.serialize(carrier), HIFulfillmentBotEnrollmentJSON.state_carrier.class);
			}
		}
		botJson.policies = new List<HIFulfillmentBotEnrollmentJSON.Policy>();
		Set<Long> policySet = new Set<Long>();
		for (HIFulfillmentEnrollmentEventJSON.Policy pol : enrollmentJson.policies) {
			if (pol.state_carrier_id == carrierId) {
				policySet.add(pol.id);
				//Neha Jan 4,2021 As JSON Structure is modified to have String Id at policy level, manually parsing policy
				HIFulfillmentBotEnrollmentJSON.Policy newPol = new HIFulfillmentBotEnrollmentJSON.Policy();
				newPol.id = String.valueOf(pol.id);
				newPol.name = pol.name;
				newPol.benefit_type = pol.benefit_type;
				newPol.group_number = pol.group_number;
				newPol.policy_number = pol.policy_number;
				newPol.plan_id = Integer.valueOf(pol.plan_id);
				newPol.visible = pol.visible;
				newPol.termination_policy = pol.termination_policy;
				newPol.state_carrier_id = Integer.valueOf(pol.state_carrier_id);
				newPol.url = pol.url;
				botJson.policies.add(newPol);
				if (String.isNotBlank(newPol.group_number)) {
					policyGroupNumber = newPol.group_number;
				}
				if (String.isNotBlank(newPol.policy_number)) {
					policyNumber = newPol.policy_number;
				}
			}
		}
		botJson.benefit_items = new HIFulfillmentBotEnrollmentJSON.benefit_items();
		Set<String> dependentIdSet = new Set<String>();
		if (enrollmentJson.benefit_items != null) {
			if (enrollmentJson.benefit_items.medical != null) {
				botJson.benefit_items.medical = getBotSubscriptionInfo(enrollmentJson.benefit_items.medical, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.medical, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.dental != null) {
				botJson.benefit_items.dental = getBotSubscriptionInfo(enrollmentJson.benefit_items.dental, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.dental, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.vision != null) {
				botJson.benefit_items.vision = getBotSubscriptionInfo(enrollmentJson.benefit_items.vision, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.vision, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.life != null) {
				botJson.benefit_items.life = getBotSubscriptionInfo(enrollmentJson.benefit_items.life, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.life, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.long_term_disability != null) {
				botJson.benefit_items.long_term_disability = getBotSubscriptionInfo(enrollmentJson.benefit_items.long_term_disability, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.long_term_disability, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.short_term_disability != null) {
				botJson.benefit_items.short_term_disability = getBotSubscriptionInfo(enrollmentJson.benefit_items.short_term_disability, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.short_term_disability, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.voluntary_short_term_disability != null) {
				botJson.benefit_items.voluntary_short_term_disability = getBotSubscriptionInfo(enrollmentJson.benefit_items.voluntary_short_term_disability, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.voluntary_short_term_disability, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.voluntary_long_term_disability != null) {
				botJson.benefit_items.voluntary_long_term_disability = getBotSubscriptionInfo(enrollmentJson.benefit_items.voluntary_long_term_disability, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.voluntary_long_term_disability, dependentIdSet);
			}
			if (enrollmentJson.benefit_items.voluntary_life != null) {
				botJson.benefit_items.voluntary_life = getBotSubscriptionInfo(enrollmentJson.benefit_items.voluntary_life, policySet);
				dependentIdSet = getDependentIds(botJson.benefit_items.voluntary_life, dependentIdSet);
			}
		}
		if (enrollmentJson.dependents.size() > 0) {
			botJson.dependents = new List<HIFulfillmentBotEnrollmentJSON.Dependent>();
			for (HIFulfillmentEnrollmentEventJSON.Dependent dep : enrollmentJson.dependents) {
				String strDepId = String.valueOf(dep.id);
				if (dependentIdSet.contains(strDepId)) {
					//Neha Jan 4,2021 As JSON Structure is modified to have String Id at Dependent level, manually parsing dependent
					HIFulfillmentBotEnrollmentJSON.Dependent newDep = new HIFulfillmentBotEnrollmentJSON.Dependent();
					newDep.id = strDepId;
					newDep.first_name = dep.first_name;
					newDep.last_name = dep.last_name;
					newDep.ssn = dep.ssn;
					newDep.birthday = dep.birthday;
					newDep.gender = dep.gender;
					newDep.dependent_type = dep.dependent_type;
					newDep.employee_id = dep.employee_id;
					newDep.url = dep.url;
					botJson.dependents.add(newDep);
				}
			}
		} else {
			botJson.dependents = new List<HIFulfillmentBotEnrollmentJSON.Dependent>();
		}
		botJson.benefits_url = enrollmentJson.benefits_url;
		botJson.enrollments_url = enrollmentJson.enrollments_url;

		String signedAt = '';
		for (HIFulfillmentEnrollmentEventJSON.Form frm : enrollmentJson.forms) {
			if (signedAt == '' && frm.signed_at != null && frm.signed_at != '') {
				signedAt = frm.signed_at;
			}
		}
		botJson.state_carrier.signed_at = signedAt;
		Blob botEncryptedBlob = EncryptionUtils.getEncryptedBlob(encryptionKey, '' + JSON.serialize(botJson));
		String botJsonString = EncodingUtil.base64Encode(botEncryptedBlob);
        
		return botJsonString;
	}

	private set<String> getDependentIds(HIFulfillmentBotEnrollmentJSON.SubscriptionInfo subscriptionInfo, set<String> dependentIdSet) {
		if (subscriptionInfo != null) {
			if (subscriptionInfo.dependent_ids != null) {
				dependentIdSet.addAll(subscriptionInfo.dependent_ids);
			}
		}
		return dependentIdSet;
	}

	private HIFulfillmentBotEnrollmentJSON.SubscriptionInfo getBotSubscriptionInfo(HIFulfillmentEnrollmentEventJSON.CarrierTypeSubscription carrierSubscription, Set<Long> policySet) {
		HIFulfillmentBotEnrollmentJSON.SubscriptionInfo subInfo = null;
		boolean valueSet = false;
		if (carrierSubscription.current != null && carrierSubscription.current.id != null) {
			if (policySet.contains(carrierSubscription.current.policy_id)) {
				subInfo = (HIFulfillmentBotEnrollmentJSON.SubscriptionInfo) System.JSON.deserialize(
					'' + JSON.serialize(carrierSubscription.current),
					HIFulfillmentBotEnrollmentJSON.SubscriptionInfo.class
				);
				selectionIds += '' + subInfo.Id + ';';
				strSelectionUUIDs += '' + subInfo.uuid + ';';
				valueSet = true;
			}
		}
		if (valueSet == false) {
			for (HIFulfillmentEnrollmentEventJSON.SubscriptionInfo enrollSubInfo : carrierSubscription.overlapping) {
				if (policySet.contains(enrollSubInfo.policy_id)) {
					subInfo = (HIFulfillmentBotEnrollmentJSON.SubscriptionInfo) System.JSON.deserialize('' + JSON.serialize(enrollSubInfo), HIFulfillmentBotEnrollmentJSON.SubscriptionInfo.class);
					selectionIds += '' + subInfo.Id + ';';
					strSelectionUUIDs += '' + subInfo.uuid + ';';
				}
			}
		}
		return subInfo;
	}
	//Get forms information
	private String getForms(Long stateCarrierid) {
		string formsInfo = '';
		if (map_stateCarrierIdForm == null || !map_stateCarrierIdForm.containsKey('' + stateCarrierid)) {
			formsInfo = ' not available';
		} else {
			String strMissingFormAttributes = '';
			Boolean blnFullyMapped = true, blnFitsDependents = true;
			Set<String> set_missingattributes = new Set<String>();
			for (HIFulfillmentEnrollmentEventJSON.Form form : map_stateCarrierIdForm.get('' + stateCarrierid)) {
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
			map_stateCarrierIdFormMappings.put('' + stateCarrierid, map_formMapping);
		}
		return formsInfo;
	}
	public class caseDataWrapper {
		public Map<String, String> map_BenefitTypeToUUID;
		public String eventId { get; set; }
		public String stateCarrierKey { get; set; }
		public String eventType { get; set; }
		public Long zPCompanyId { get; set; }
		public String employeeEmail { get; set; }
		public String caseDescription { get; set; }
		public String subscriptionIds { get; set; }
		public Date effectiveDate { get; set; }
		public String groupIds { get; set; }
		public String oppsOwner { get; set; }
		public HIFulfillmentEnrollmentEventJSON hiEventInfo { get; set; }
		public String piiInformation { get; set; }
		public String encryptedJson { get; set; }
		public String selectionIds { get; set; }
		public String groupNumber { get; set; }
		public String policyNumber { get; set; }
		public String strSubscriptionInfo { get; set; }
		public String strSelectionUUIDs { get; set; }
		public caseDataWrapper(
			String eeventId,
			String carrierKey,
			String eventT,
			Long companyId,
			String eEmail,
			String caseDesc,
			String eSubscriptionIds,
			Date eeffectiveDate,
			String eGroupIds,
			String eoppsOwner,
			HIFulfillmentEnrollmentEventJSON hiEventInfoParsed,
			String piiInfo,
			String sEncryptedJson,
			String sSelectionIds,
			String groupNumberString,
			String policyNumberString,
			String strSubscriptionInfo,
			String strSelectionUUIDs,
			Map<String, String> map_BenefitTypeToUUID
		) {
			eventId = eeventId;
			stateCarrierKey = carrierKey;
			eventType = eventT;
			zPCompanyId = companyId;
			employeeEmail = eEmail;
			caseDescription = caseDesc;
			subscriptionIds = eSubscriptionIds;
			effectiveDate = eeffectiveDate;
			groupIds = eGroupIds;
			oppsOwner = eoppsOwner;
			hiEventInfo = hiEventInfoParsed;
			piiInformation = piiInfo;
			encryptedJson = sEncryptedJson;
			selectionIds = sSelectionIds;
			groupNumber = groupNumberString;
			policyNumber = policyNumberString;
			this.strSubscriptionInfo = strSubscriptionInfo;
			this.strSelectionUUIDs = strSelectionUUIDs;
			this.map_BenefitTypeToUUID = map_BenefitTypeToUUID;
		}
	}
}