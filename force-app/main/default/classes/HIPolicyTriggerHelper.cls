/**
 * @description HI Policy Trigger Logic
 * @see HIPolicyTriggerHelperTest
 */
public without sharing class HIPolicyTriggerHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	public static boolean queue = false;

	private Map<String, Map<String, Policy__c>> opportunityPolicyMapByName = new Map<String, Map<String, Policy__c>>();
	private Map<String, Map<String, Policy__c>> opportunityPolicyMapById = new Map<String, Map<String, Policy__c>>();

	private Map<String, Map<String, Map<String, List<Policy__c>>>> companyIdCarrierPolicyMap = new Map<String, Map<String, Map<String, List<Policy__c>>>>();
	public static final String MSG_BOR_ID_POPULATED = 'Bor Transfer Id is populated for Big Desk, support to be added later.';

	public HIPolicyTriggerHelper() {
		super('HIPolicyTriggerHelper');
	}

	public override void beforeInsert() {
		List<HI_Policy__c> states = (List<HI_Policy__c>) Trigger.new;
		if (queue == true || test.isRunningTest()) {
			processInformation(states);
		} else {
			for (HI_Policy__c state : states) {
				state.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_Policy__c> states = (List<HI_Policy__c>) Trigger.new;
		if (queue == false && !test.isRunningTest()) {
			HIPolicyQueue updateJob = new HIPolicyQueue(states);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public override void beforeUpdate() {
		List<HI_Policy__c> states = (List<HI_Policy__c>) Trigger.new;
		if (queue == true || test.isRunningTest()) {
			processInformation(states);
		} else {
			for (HI_Policy__c state : states) {
				state.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_Policy__c> states = (List<HI_Policy__c>) Trigger.new;
		if (queue == false && !test.isRunningTest()) {
			HIPolicyQueue updateJob = new HIPolicyQueue(states);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public void processInformation(List<HI_Policy__c> policyList) {
		List<Policy__c> policyListForInsert = new List<Policy__c>();
		List<Policy__c> policyListForUpdate = new List<Policy__c>();
		Set<String> benPkgIDSet = new Set<String>();

		Set<String> policyKeySet = new Set<String>();
		Set<String> policyIdSet = new Set<String>();
		Set<String> planIDSet = new Set<String>();
		Set<String> stateIDSet = new Set<String>();
		Set<String> accountIDSet = new Set<String>();
		Set<String> carrierIDSet = new Set<String>();
		Set<String> borIDSet = new Set<String>();
		Set<String> oppSourceIdSet = new Set<String>();
		Set<String> policyDetailIdSet = new Set<String>();

		Map<String, State__c> stateMap = getAllStateData();
		Set<String> set_PolicyDetailId = new Set<String>(); // Added for BBO-1968
        List<HI_Fsa_Policy_Detail__c> list_FsaPolicies = new List<HI_Fsa_Policy_Detail__c>();//Added for BBO-1968
		for (HI_Policy__c hiPolicy : policyList) {
            //Added for BBO-1968 Starts
            if(!String.isBlank(hiPolicy.Policy_Detail_Id__c)){
                set_PolicyDetailId.add(hiPolicy.Policy_Detail_Id__c);
            }
            //BBO-1968 Ends
			if (hiPolicy.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			} else {
				hiPolicy.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}

			if (hiPolicy.Id__c == null) {
				continue;
			}

			benPkgIDSet.add(hiPolicy.Benefits_Package_Id__c);
			planIDSet.add(hiPolicy.Plan_Id__c);
			stateIDSet.add(hiPolicy.State__c);
			policyDetailIdSet.add(hiPolicy.Policy_Detail_Id__c);
			policyKeySet.add(hiPolicy.External_Key__c);
			policyIdSet.add(hiPolicy.Id__c);

			if (hiPolicy.Bor_Transfer_Id__c != null && hiPolicy.Bor_Transfer_Id__c != '') {
				borIDSet.add(hiPolicy.Bor_Transfer_Id__c);
			}
		}
        //Added for BBO-1968 Starts
		list_FsaPolicies = [SELECT Id,Id__c,Provider_Key__c FROM HI_Fsa_Policy_Detail__c WHERE Id__c IN: set_PolicyDetailId];
        Map<String,String> map_IdWithProviderKey = new Map<String,String>();
        Map<String,Carrier__c> map_KeyWithCarrierOrder = new Map<String,Carrier__c>();
        if(list_FsaPolicies != null && list_FsaPolicies.size() > 0){
            for(HI_Fsa_Policy_Detail__c fsaPolicyDetail : list_FsaPolicies){
                map_IdWithProviderKey.put(fsaPolicyDetail.Id__c,fsaPolicyDetail.Provider_Key__c);
            }
        }
        if(map_IdWithProviderKey != null && map_IdWithProviderKey.values() != null && map_IdWithProviderKey.values().size() > 0){
            for(Carrier__c carrier : [SELECT Id,Key__c FROM Carrier__c WHERE Key__c IN : map_IdWithProviderKey.values()]){
                map_KeyWithCarrierOrder.put(carrier.Key__c,carrier);
            }
        }
        //BBO-1968 Ends
		if (policyKeySet.size() > 0) {
			Map<String, HI_Benefits_Package__c> benPkgMap = getBenefitPackageData(benPkgIDSet);
			for (HI_Benefits_Package__c pkg : benPkgMap.values()) {
				accountIDSet.add(pkg.Company_Id__c);
			}
		}
		List<HI_Policy__c> existingPolicyList = new List<HI_Policy__c>();
		if (accountIDSet.size() > 0) {
			existingPolicyList = getPolicyList(accountIDSet);
			for (HI_Policy__c plcy : existingPolicyList) {
				benPkgIDSet.add(plcy.Benefits_Package_Id__c);
				planIDSet.add(plcy.Plan_Id__c);
				stateIDSet.add(plcy.State__c);
				policyDetailIdSet.add(plcy.Policy_Detail_Id__c);

				policyKeySet.add(plcy.External_Key__c);
				policyIdSet.add(plcy.Id__c);
			}
		}
		Map<String, contributionInformation> policyIdContributionInfoMap = getPolicyContributionInfo(policyIDSet);
		// if External Id Set contains some value
		if (policyKeySet.size() > 0) {
			Map<String, HI_Benefits_Package__c> benPkgMap = getBenefitPackageData(benPkgIDSet);
			for (HI_Benefits_Package__c pkg : benPkgMap.values()) {
				accountIDSet.add(pkg.Company_Id__c);
			}
			Map<String, Hi_Benefits_Plan__c> benefitPlanIdRecordMap = getBenefitPlanData(planIDSet);
			for (Hi_Benefits_Plan__c plan : benefitPlanIdRecordMap.values()) {
				carrierIDSet.add(plan.National_Carrier_Id__c);
			}

			Map<String, Policy__c> policyIdRecordMap = getPolicyData(policyKeySet);
			Map<String, State__c> stateIdRecordMap = getStateData(stateIDSet);

			// SJay - 08/14/2020 - Added size check to avoid unnecessary queries.
			Map<String, Account> accountIdRecordMap = new Map<String, Account>();
			if (accountIDSet.size() > 0) {
				accountIdRecordMap = getAccountData(accountIDSet);
			}
			Map<String, HI_Benefit_Change_Application__c> changeMap = getBenefitsChangeByPackageId(benPkgIDSet);
			for (HI_Benefit_Change_Application__c change : changeMap.values()) {
				oppSourceIdSet.add(change.External_Key__c);
			}
			Map<String, HI_Renewal__c> renewalMap = getRenewalsByPackageId(benPkgIDSet);
			for (HI_Renewal__c renewal : renewalMap.values()) {
				oppSourceIdSet.add(renewal.External_Key__c);
			}
			Map<String, HI_New_Plans_ApplicationsBenefitsPackage__c> newPlanMap = getNewPlanBenefitPackageData(benPkgIDSet);
			for (HI_New_Plans_ApplicationsBenefitsPackage__c newPlan : newPlanMap.values()) {
				oppSourceIdSet.add('hawaiian_ice-new_plans_application-' + newPlan.New_Plans_Application_Id__c);
			}

			Map<String, HI_BoR_Transfer__c> borTransferMap = new Map<String, HI_BoR_Transfer__c>();
			if (borIDSet.size() > 0) {
				borTransferMap = getBORByBORId(borIDSet);
			}
			for (HI_BoR_Transfer__c transfer : borTransferMap.values()) {
				oppSourceIdSet.add('hawaiian_ice-bor_transfer-' + transfer.Id__c);
			}

			Map<String, HI_Health_Plan_Detail__c> healthPlanDetailMap = getHealthPlanDetail(planIdSet);
			Map<String, Carrier__c> carrierMap = getCarrierDetail(carrierIDSet);
			Map<String, Opportunity> opportunityMap = getOpportunityDetail(oppSourceIdSet);
			Map<String, HI_Health_Policy_Detail__c> healthPoicyDetailMap = getHealthPolicyDetail(policyDetailIdSet);
			Map<String, HI_Lidi_Policy_Detail__c> lidiPoicyDetailMap = getLidiPolicyDetail(policyDetailIdSet);

			/* Set existing policy Map */
			SetExistingPolicyInfoMap(
				existingPolicyList,
				benPkgMap,
				benefitPlanIdRecordMap,
				policyIdRecordMap,
				stateIdRecordMap,
				accountIdRecordMap,
				renewalMap,
				healthPlanDetailMap,
				carrierMap,
				healthPoicyDetailMap,
				lidiPoicyDetailMap,
				policyIdContributionInfoMap
			);
			for (HI_Policy__c hiPolicy : policyList) {
				if (hiPolicy.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}

				if (hiPolicy.Benefits_Package_Id__c == null || hiPolicy.Benefits_Package_Id__c == '' || !benPkgMap.containsKey(hiPolicy.Benefits_Package_Id__c)) {
					setProcessingPolicy(IntegrationUtils.BACKLOG, 'Benefits Package does not exist.', hiPolicy, null);
					continue;
				}

				if (hiPolicy.Bor_Transfer_Id__c != null && hiPolicy.Bor_Transfer_Id__c != '') {
					setProcessingPolicy(IntegrationUtils.PROCESSED_STATE, MSG_BOR_ID_POPULATED, hiPolicy, null);
					continue;
				}
				//BBO-1968 Starts
				if((hiPolicy.Policy_Detail_Type__c == 'DcaPolicyDetail' || hiPolicy.Policy_Detail_Type__c == 'FsaPolicyDetail') && (map_IdWithProviderKey.get(hiPolicy.Policy_Detail_Id__c) == null 
                       		|| map_IdWithProviderKey.get(hiPolicy.Policy_Detail_Id__c) == '')){
                		setProcessingPolicy(IntegrationUtils.DEAD_STATE, 'Provider Key is blank.', hiPolicy, null);
						continue;
                }
                //BBO-1968 Ends
				if (
					!changeMap.containsKey(hiPolicy.Benefits_Package_Id__c) &&
					!renewalMap.containsKey(hiPolicy.Benefits_Package_Id__c) &&
					!newPlanMap.containsKey(hiPolicy.Benefits_Package_Id__c) &&
					!borTransferMap.containsKey(hiPolicy.Bor_Transfer_Id__c)
				) {
					if (hiPolicy.Created_At__c < system.now() - 2) {
						setProcessingPolicy(IntegrationUtils.DEAD_STATE, 'Policy not associated with any application types.', hiPolicy, null);
						continue;
					} else {
						setProcessingPolicy(IntegrationUtils.ERROR_STATE, 'Policy not associated with any application types.', hiPolicy, null);
						continue;
					}
				}
				if (!benPkgMap.containsKey(hiPolicy.Benefits_Package_Id__c)) {
					setProcessingPolicy(IntegrationUtils.BACKLOG, 'Benefits Package does not exist.', hiPolicy, null);
					continue;
				}
				HI_Benefits_Package__c benefitsPackage = benPkgMap.get(hiPolicy.Benefits_Package_Id__c);

				if (benefitsPackage.Company_Id__c == null || benefitsPackage.Company_Id__c == '') {
					setProcessingPolicy(IntegrationUtils.ERROR_STATE, 'Benefits Package Company Id does not exist.', hiPolicy, null);
					continue;
				}

				// SJay - 08/14/2020 - Added null check
				if (accountIdRecordMap != null && !accountIdRecordMap.containsKey(benefitsPackage.Company_Id__c)) {
					setProcessingPolicy(IntegrationUtils.ERROR_STATE, 'Corresponding company account does not exist.', hiPolicy, null);
					continue;
				}

				contributionInformation policyContributionInfo;
				if (policyIdContributionInfoMap.containsKey(hiPolicy.Id__c)) {
					policyContributionInfo = policyIdContributionInfoMap.get(hiPolicy.Id__c);
				}

				// SJay - 08/14/2020 - Added null checks.
				Account acc = new Account();
				if (benefitsPackage != null && accountIdRecordMap != null && accountIdRecordMap.containsKey(benefitsPackage.Company_Id__c)) {
					acc = accountIdRecordMap.get(benefitsPackage.Company_Id__c);
				}

				Opportunity opp = new Opportunity();
				if (newPlanMap.containsKey(hiPolicy.Benefits_Package_Id__c)) {
					HI_New_Plans_ApplicationsBenefitsPackage__c newPlan = newPlanMap.get(hiPolicy.Benefits_Package_Id__c);
					String sourceId = 'hawaiian_ice-new_plans_application-' + newPlan.New_Plans_Application_Id__c;
					if (opportunityMap.containsKey(sourceId)) {
						opp = opportunityMap.get(sourceId);
					} else {
						setProcessingPolicy(IntegrationUtils.BACKLOG, 'New Plan Opp does not exist.', hiPolicy, null);
						continue;
					}
				}

				if (renewalMap.containsKey(hiPolicy.Benefits_Package_Id__c)) {
					HI_Renewal__c renewal = renewalMap.get(hiPolicy.Benefits_Package_Id__c);
					String sourceId = renewal.External_Key__c;
					if (opportunityMap.containsKey(sourceId)) {
						opp = opportunityMap.get(sourceId);
					} else {
						setProcessingPolicy(IntegrationUtils.BACKLOG, 'Renewal Opp does not exist.', hiPolicy, null);
						continue;
					}
				}

				if (changeMap.containsKey(hiPolicy.Benefits_Package_Id__c)) {
					HI_Benefit_Change_Application__c renewal = changeMap.get(hiPolicy.Benefits_Package_Id__c);
					String sourceId = renewal.External_Key__c;
					if (opportunityMap.containsKey(sourceId)) {
						opp = opportunityMap.get(sourceId);
					} else {
						setProcessingPolicy(IntegrationUtils.BACKLOG, 'Benefit Change Opp does not exist.', hiPolicy, null);
						continue;
					}
				}

				if (borTransferMap.containsKey(hiPolicy.Bor_Transfer_Id__c)) {
					//HI_Bor_Transfer__c transfer = borTransferMap.get(hiPolicy.Bor_Transfer_Id__c);
					String sourceId = 'hawaiian_ice-bor_transfer-' + hiPolicy.Bor_Transfer_Id__c;
					if (opportunityMap.containsKey(sourceId)) {
						opp = opportunityMap.get(sourceId);
					} else {
						setProcessingPolicy(IntegrationUtils.BACKLOG, 'BOR Transfer does not exist.', hiPolicy, null);
						continue;
					}
				}

				HI_Health_Policy_Detail__c healthPolicyDetail = new HI_Health_Policy_Detail__c();
				if (hiPolicy.Policy_Detail_Type__c == 'HealthPolicyDetail') {
					if (healthPoicyDetailMap.containsKey(hiPolicy.Policy_Detail_Id__c)) {
						healthPolicyDetail = healthPoicyDetailMap.get(hiPolicy.Policy_Detail_Id__c);
					} else {
						setProcessingPolicy(IntegrationUtils.BACKLOG, 'Health Policy Detail does not exist.', hiPolicy, null);
						continue;
					}
				}
				HI_Lidi_Policy_Detail__c lidiPolicyDetail = new HI_Lidi_Policy_Detail__c();
				if (hiPolicy.Policy_Detail_Type__c == 'LiDiPolicyDetail') {
					if (lidiPoicyDetailMap.containsKey(hiPolicy.Policy_Detail_Id__c)) {
						lidiPolicyDetail = lidiPoicyDetailMap.get(hiPolicy.Policy_Detail_Id__c);
					} else {
						setProcessingPolicy(IntegrationUtils.BACKLOG, 'Lidi Policy Detail does not exist.', hiPolicy, null);
						continue;
					}
				}

				if (!benefitPlanIdRecordMap.containsKey(hipolicy.Plan_Id__c) && hiPolicy.Policy_Detail_Type__c != 'DcaPolicyDetail' && hiPolicy.Policy_Detail_Type__c != 'FsaPolicyDetail') {
					setProcessingPolicy(IntegrationUtils.BACKLOG, 'Corresponding plan does not exist.', hiPolicy, null);
					continue;
				}
				Hi_Benefits_Plan__c benefitPlan = benefitPlanIdRecordMap.get(hipolicy.Plan_Id__c);
				Hi_Health_Plan_Detail__c healthPlanDetail = new Hi_Health_Plan_Detail__c();
				if (hiPolicy.Policy_Detail_Type__c != 'DcaPolicyDetail' && hiPolicy.Policy_Detail_Type__c != 'FsaPolicyDetail' && benefitPlan.Type__c == 'HealthPlan') {
					if (!healthPlanDetailMap.containsKey(hipolicy.Plan_Id__c)) {
						setProcessingPolicy(IntegrationUtils.BACKLOG, 'Health Plan Detail does not exist.', hiPolicy, null);
						continue;
					} else {
						healthPlanDetail = healthPlanDetailMap.get(hipolicy.Plan_Id__c);
					}
				}

				if (
					hiPolicy.Policy_Detail_Type__c != 'DcaPolicyDetail' &&
					hiPolicy.Policy_Detail_Type__c != 'FsaPolicyDetail' &&
					!carrierMap.containsKey(benefitPlan.National_Carrier_Id__c + '-' + benefitPlan.State__c)
				) {
					setProcessingPolicy(IntegrationUtils.BACKLOG, 'Carrier does not exist.', hiPolicy, null);
					continue;
				}

				Policy__c policy = new Policy__c();
				Map<String, Policy__c> policyMapById = new Map<String, Policy__c>();
				Map<String, Policy__c> policyMapByName = new Map<String, Policy__c>();
				if (opportunityPolicyMapById.containsKey(opp.Source_ID__c)) {
					policyMapById = opportunityPolicyMapById.get(opp.Source_ID__c);
				}
				if (opportunityPolicyMapByName.containsKey(opp.Source_ID__c)) {
					policyMapByName = opportunityPolicyMapByName.get(opp.Source_ID__c);
				}
				policy.Opportunity__c = opp.Id;
				policy.Id__c = hiPolicy.Id__c;
				policy.Is_Base__c = hiPolicy.Is_Base__c;
				policy.Expiration_Date__c = hiPolicy.Expiration_Date__c;
				policy.Coverage_Effective_Date__c = hiPolicy.Effective_Date__c;
				policy.Visible__c = hiPolicy.Visible__c;
				policy.External_Key__c = hiPolicy.External_Key__c;

				if (acc != null && acc.Id != null) {
					policy.Account__c = acc.Id;
				}

				if (hiPolicy.Deleted_At__c == null) {
					policy.Is_Selected__c = true;
				} else {
					policy.Is_Selected__c = false;
					policy.Carrier_Order__c = null;
				}
				if (hiPolicy.Policy_Detail_Type__c != 'DcaPolicyDetail' && hiPolicy.Policy_Detail_Type__c != 'FsaPolicyDetail') {
                    if (policyMapById.containsKey(hiPolicy.Id__c)) {
						policy = policyMapById.get(hiPolicy.Id__c);
					} else if (policyMapByName.containsKey(benefitPlan.Name__c)) {
						//ExceptionLogUtil.logException('HIPolicyTriggerHelper', 'BeforeInsert', 'Policy Id: ' + hiPolicy.Id + '- Opportunity Id' + opp.Id, '');
					}

					Carrier__c carrier = carrierMap.get(benefitPlan.National_Carrier_Id__c + '-' + benefitPlan.State__c);
					policy.Carrier__c = carrier.Id;
					policy.State__c = stateMap.get(benefitPlan.State__c).Id;
					policy.Plan_Type__c = Utils.humanize(healthPlanDetail.Plan_Type__c);
					policy.Plan_Tier__c = Utils.humanize(healthPlanDetail.Metal_Tier__c);
					policy.Carrier_Plan_IDs__c = benefitPlan.Carrier_Plan_IDs__c;
					policy.Package_Identifiers__c = healthPlanDetail.Package_Identifiers__c;

					String policyName = '';
					if (benefitPlan.Name__c != null) {
						policyName = benefitPlan.Name__c;
					}
					if (policyName.length() > 80) {
						policy.Name = policyName.left(80);
					} else {
						policy.Name = policyName;
					}
					policy.Expiration_Date__c = hiPolicy.Expiration_Date__c;

					if (hiPolicy.Policy_Detail_Type__c == 'HealthPolicyDetail') {
						policy.Group_Number__c = healthPolicyDetail.Group_Number__c;
						policy.Policy_Number__c = healthPolicyDetail.Policy_Number__c;
						policy.Plan_Document_Link__c = healthPolicyDetail.Plan_Document_Link__c;
					} else if (hiPolicy.Policy_Detail_Type__c == 'LiDiPolicyDetail') {
						policy.Group_Number__c = lidiPolicyDetail.Group_Number__c;
						policy.Policy_Number__c = lidiPolicyDetail.Policy_Number__c;
						policy.Plan_Document_Link__c = lidiPolicyDetail.Plan_Document_Link__c;
					}

					if (benefitPlan.Type__c == 'HealthPlan') {
						policy.Benefit_Type__c = Utils.humanize(healthPlanDetail.Insurance_Type__c);
					} else {
						policy.Benefit_Type__c = IntegrationUtils.getIntegrationValueMap('Policy__c', 'Benefit_Type__c').get(benefitPlan.Type__c);
					}

					policy = SetPolicyRequestType(policy, benefitsPackage.Company_Id__c);
				} else if (hiPolicy.Policy_Detail_Type__c == 'DcaPolicyDetail' || hiPolicy.Policy_Detail_Type__c == 'FsaPolicyDetail') {
                    if (policyMapById.containsKey(hiPolicy.Id__c)) {
						policy = policyMapById.get(hiPolicy.Id__c);
					}
                    //BBO-1968 Starts
                    String strProviderKey = '';
                    if(map_IdWithProviderKey != null && map_IdWithProviderKey.containsKey(hiPolicy.Policy_Detail_Id__c) 
                       && (map_IdWithProviderKey.get(hiPolicy.Policy_Detail_Id__c) != null 
                       && map_IdWithProviderKey.get(hiPolicy.Policy_Detail_Id__c) != '')){
                        strProviderKey = map_IdWithProviderKey.get(hiPolicy.Policy_Detail_Id__c);
                        if(strProviderKey != '' && map_KeyWithCarrierOrder != null && map_KeyWithCarrierOrder.containsKey(strProviderKey)){
                        	policy.Carrier__c = map_KeyWithCarrierOrder.get(strProviderKey).Id;
                    	}
                    }
                    //BBO-1968 Ends
					if (hiPolicy.Policy_Detail_Type__c == 'DcaPolicyDetail') {
						policy.Name = 'Flexible Spending Account - Dependent Care';
						policy.Benefit_Type__c = 'Flexible Spending Account - Dependent Care';
					}
					if (hiPolicy.Policy_Detail_Type__c == 'FsaPolicyDetail') {
						policy.Name = 'Flexible Spending Account - Medical';
						policy.Benefit_Type__c = 'Flexible Spending Account - Medical';
					}
				}
				if (hiPolicy.Deleted_At__c == null) {
					policy.Is_Selected__c = true;
				} else {
					policy.Is_Selected__c = false;
					policy.Carrier_Order__c = null;
				}
				policy.External_Key__c = hiPolicy.External_Key__c;

				// SJay - 08/26/2020 - Moved this section so Waiting_Period__c fields get updated for every policy type.
				Map<String, String> waitingPeriodMap = IntegrationUtils.getIntegrationValueMap('Opportunity', 'Waiting_Period__c');
				if (waitingPeriodMap.containsKey(hiPolicy.Waiting_Period__c)) {
					policy.Waiting_Period__c = waitingPeriodMap.get(hiPolicy.Waiting_Period__c);
				}

				// SJay - 07/19/2020 - Moved this section so contribution scheme fields get updated for every policy type.
				if (policyContributionInfo != null) {
					policy.Contribution_Scheme_Type__c = policyContributionInfo.type;
					if (policyContributionInfo.eePercentage != null) {
						policy.Contribution_for_EEs__c = '' + policyContributionInfo.eePercentage * 100;
					}
					if (policyContributionInfo.dependentPercentage != null) {
						policy.Contribution_for_Dependents__c = '' + policyContributionInfo.dependentPercentage * 100;
					}
				}
				if (policy.id == null) {
					policyListForInsert.add(policy);
				} else {
					policyListForUpdate.add(policy);
				}
			}
			Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
			if (policyListForInsert.size() > 0) {
				List<Database.UpsertResult> saveResult = database.upsert(policyListForInsert, Policy__c.Fields.External_Key__c, false);
				dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, policyListForInsert, 'External_Key__c', false, 'HIPolicyTriggerHelper-processInformation');
			}
			Map<String, Policy__c> hiPolicyMapUpdated = new Map<String, Policy__c>();
			for (Policy__c polcy : policyListForInsert) {
				hiPolicyMapUpdated.put(polcy.External_Key__c, polcy);
			}

			Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
			if (policyListForUpdate.size() > 0) {
				List<Database.SaveResult> saveResult = database.update(policyListForUpdate, false);
				dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, policyListForUpdate, 'External_Key__c', false, 'HIPolicyTriggerHelper-processInformation');
			}

			for (Policy__c polcy : policyListForUpdate) {
				hiPolicyMapUpdated.put(polcy.External_Key__c, polcy);
			}

			for (HI_Policy__c hiPolicy : policyList) {
				if (dmlUpsertErrorsMap.containsKey(hiPolicy.External_Key__c)) {
					setProcessingPolicy(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(hiPolicy.External_Key__c), hiPolicy, null);
				} else if (dmlUpdateErrorsMap.containsKey(hiPolicy.External_Key__c)) {
					setProcessingPolicy(IntegrationUtils.ERROR_STATE, dmlUpdateErrorsMap.get(hiPolicy.External_Key__c), hiPolicy, null);
				} else if (hiPolicy.Processing_State__c == 'Queued') {
					Policy__c plcy = new Policy__c();
					if (hiPolicyMapUpdated.containsKey(hiPolicy.External_Key__c)) {
						plcy = hiPolicyMapUpdated.get(hiPolicy.External_Key__c);
					}
					setProcessingPolicy(IntegrationUtils.PROCESSED_STATE, 'Processed', hiPolicy, plcy.id);
				}
			}
		}
	}

	// querying State object records present in the org using ID__c field
	private Map<String, Policy__c> getPolicyData(Set<String> policyIdSet) {
		Map<String, Policy__c> toReturnIdPolicyRecMap = new Map<String, Policy__c>();
		if (policyIdSet != null && policyIdSet.size() > 0) {
			for (Policy__c policy : [SELECT id, Id__c, External_Key__c, Name FROM Policy__c WHERE External_Key__c IN :policyIdSet AND External_Key__c != NULL]) {
				toReturnIdPolicyRecMap.put(policy.External_Key__c, policy);
			}
		}
		return toReturnIdPolicyRecMap;
	}

	// querying State object records present in the org using ID__c field
	private Map<String, State__c> getStateData(Set<String> stateIdSet) {
		Map<String, State__c> toReturnIdStateRecMap = new Map<String, State__c>();
		if (stateIdSet != null && stateIdSet.size() > 0) {
			for (State__c state : [SELECT id, Id__c, Name FROM State__c WHERE Id__c IN :stateIdSet AND Id__c != NULL]) {
				toReturnIdStateRecMap.put(state.Id__c, state);
			}
		}
		return toReturnIdStateRecMap;
	}

	private Map<String, State__c> getAllStateData() {
		Map<String, State__c> toReturnIdStateRecMap = new Map<String, State__c>();
		for (State__c state : [SELECT id, Id__c, Name, Abbreviation__c FROM State__c]) {
			toReturnIdStateRecMap.put(state.Abbreviation__c, state);
		}

		return toReturnIdStateRecMap;
	}

	private Map<String, Opportunity> getOpportunityDetail(Set<String> sourceIdSet) {
		Map<String, Opportunity> toReturnOppMap = new Map<String, Opportunity>();

		for (Opportunity opp : [SELECT Id, Source_Id__c, (SELECT Id, Name, Id__c, Request_Type__c, Waiting_Period__c,
                 Contribution_Scheme_Type__c, Contribution_for_EEs__c, Contribution_for_Dependents__c, Plan_Type__c
                 FROM Policies__r) FROM Opportunity WHERE Source_Id__c != NULL AND Source_Id__c IN :sourceIdSet]) {
			toReturnOppMap.put(opp.Source_Id__c, opp);
			Map<String, Policy__c> policyMapByName = new Map<String, Policy__c>();
			Map<String, Policy__c> policyMapById = new Map<String, Policy__c>();
			if (opp.Policies__r != null) {
				for (Policy__c policy : opp.Policies__r) {
					policyMapByName.put(policy.Name, policy);
					policyMapById.put(policy.Id__c, policy);
				}
			}
			opportunityPolicyMapByName.put(opp.Source_Id__c, policyMapByName);
			opportunityPolicyMapById.put(opp.Source_Id__c, policyMapById);
		}
		return toReturnOppMap;
	}

	private Map<String, Carrier__c> getCarrierDetail(Set<String> carrierIdSet) {
		Map<String, Carrier__c> toReturnCarrierMap = new Map<String, Carrier__c>();
		for (Carrier__c carrier : [
			SELECT Id, Id__c, Name, Key__c, Carrier_Id__c, State__c, New_Plan_Submission_Event__c, New_Plan_Variation_Num1__c, New_Plan_Variation_Num2__c
			FROM Carrier__c
			WHERE Carrier_Id__c != NULL AND Carrier_Id__c IN :carrierIdSet
		]) {
			toReturnCarrierMap.put(carrier.Carrier_Id__c + '-' + carrier.State__c, carrier);
		}
		return toReturnCarrierMap;
	}

	private Map<String, HI_Health_Plan_Detail__c> getHealthPlanDetail(Set<String> planIdSet) {
		Map<String, HI_Health_Plan_Detail__c> toReturnPlanMap = new Map<String, HI_Health_Plan_Detail__c>();
		for (HI_Health_Plan_Detail__c plan : [
			SELECT Id, benefits_plan_Id__c, Id__c, Deleted_At__c, Insurance_Type__c, Plan_Type__c, Metal_Tier__c, Package_Identifiers__c
			FROM HI_Health_Plan_Detail__c
			WHERE benefits_plan_Id__c != NULL AND benefits_plan_Id__c IN :planIdSet
		]) {
			toReturnPlanMap.put(plan.benefits_plan_Id__c, plan);
		}
		return toReturnPlanMap;
	}

	private Map<String, HI_Health_Policy_Detail__c> getHealthPolicyDetail(Set<String> policyDetailIdSet) {
		Map<String, HI_Health_Policy_Detail__c> toReturnPolicyMap = new Map<String, HI_Health_Policy_Detail__c>();
		for (HI_Health_Policy_Detail__c policy : [
			SELECT Id, Id__c, Group_Number__c, Policy_Number__c, Secondary_Group_Number__c, Plan_Document_Link__c
			FROM HI_Health_Policy_Detail__c
			WHERE Id__c != NULL AND Id__c IN :policyDetailIdSet
		]) {
			toReturnPolicyMap.put(policy.Id__c, policy);
		}
		return toReturnPolicyMap;
	}

	private Map<String, HI_Lidi_Policy_Detail__c> getLidiPolicyDetail(Set<String> policyDetailIdSet) {
		Map<String, HI_Lidi_Policy_Detail__c> toReturnPolicyMap = new Map<String, HI_Lidi_Policy_Detail__c>();
		for (HI_Lidi_Policy_Detail__c policy : [
			SELECT Id, Id__c, Group_Number__c, Policy_Number__c, Secondary_Group_Number__c, Plan_Document_Link__c
			FROM HI_Lidi_Policy_Detail__c
			WHERE Id__c != NULL AND Id__c IN :policyDetailIdSet
		]) {
			toReturnPolicyMap.put(policy.Id__c, policy);
		}
		return toReturnPolicyMap;
	}

	private Map<String, HI_Benefit_Change_Application__c> getBenefitsChangeByPackageId(Set<String> packageIdSet) {
		Map<String, HI_Benefit_Change_Application__c> toReturnChangeMap = new Map<String, HI_Benefit_Change_Application__c>();
		for (HI_Benefit_Change_Application__c change : [
			SELECT Id, Benefits_Package_Id__c, Id__c, Deleted_At__c, External_Key__c
			FROM HI_Benefit_Change_Application__c
			WHERE Benefits_Package_Id__c != NULL AND Benefits_Package_Id__c IN :packageIdSet
		]) {
			toReturnChangeMap.put(change.Benefits_Package_Id__c, change);
		}
		return toReturnChangeMap;
	}

	private Map<String, HI_BoR_Transfer__c> getBORByBORId(Set<String> borIdSet) {
		Map<String, HI_BoR_Transfer__c> toReturnBORMap = new Map<String, HI_BoR_Transfer__c>();
		for (HI_BoR_Transfer__c bor : [SELECT Id, Id__c, Deleted_At__c, External_Key__c FROM HI_BoR_Transfer__c WHERE Id__c != NULL AND Id__c IN :borIdSet]) {
			toReturnBORMap.put(bor.Id__c, bor);
		}
		return toReturnBORMap;
	}

	private Map<String, HI_Renewal__c> getRenewalsByPackageId(Set<String> packageIdSet) {
		Map<String, HI_Renewal__c> toReturnRenewalMap = new Map<String, HI_Renewal__c>();
		for (HI_Renewal__c renewal : [
			SELECT Id, Benefits_Package_Id__c, Id__c, Deleted_At__c, External_Key__c
			FROM HI_Renewal__c
			WHERE Benefits_Package_Id__c != NULL AND Benefits_Package_Id__c IN :packageIdSet
		]) {
			toReturnRenewalMap.put(renewal.Benefits_Package_Id__c, renewal);
		}
		return toReturnRenewalMap;
	}

	private Map<String, HI_New_Plans_ApplicationsBenefitsPackage__c> getNewPlanBenefitPackageData(Set<String> packageIdSet) {
		Map<String, HI_New_Plans_ApplicationsBenefitsPackage__c> toReturnPackageRecMap = new Map<String, HI_New_Plans_ApplicationsBenefitsPackage__c>();
		for (HI_New_Plans_ApplicationsBenefitsPackage__c benPackage : [
			SELECT Id, Benefits_Package_Id__c, Id__c, New_Plans_Application_Id__c
			FROM HI_New_Plans_ApplicationsBenefitsPackage__c
			WHERE Benefits_Package_Id__c != NULL AND Benefits_Package_Id__c IN :packageIdSet
		]) {
			toReturnPackageRecMap.put(benPackage.Benefits_Package_Id__c, benPackage);
		}
		return toReturnPackageRecMap;
	}

	private Map<String, HI_Benefits_Package__c> getBenefitPackageData(Set<String> packageIdSet) {
		Map<String, HI_Benefits_Package__c> toReturnPackageRecMap = new Map<String, HI_Benefits_Package__c>();
		for (HI_Benefits_Package__c benPackage : [SELECT Id, Id__c, Company_Id__c FROM HI_Benefits_Package__c WHERE Id__c != NULL AND Id__c IN :packageIdSet]) {
			toReturnPackageRecMap.put(benPackage.Id__c, benPackage);
		}
		return toReturnPackageRecMap;
	}

	private Map<String, HI_Benefits_Plan__c> getBenefitPlanData(Set<String> planIdSet) {
		Map<String, HI_Benefits_Plan__c> toReturnPlanRecMap = new Map<String, HI_Benefits_Plan__c>();
		for (HI_Benefits_Plan__c benPlan : [
			SELECT Id, Id__c, State__c, National_Carrier_Id__c, Type__c, Name__c, Carrier_Plan_IDs__c
			FROM HI_Benefits_Plan__c
			WHERE Id__c != NULL AND Id__c IN :planIdSet
		]) {
			toReturnPlanRecMap.put(benPlan.Id__c, benPlan);
		}
		return toReturnPlanRecMap;
	}

	// querying Account object records present in the org using External_Key__c field
	// SJay - 08/14/2020 - Added a null check for ZP Company Id. This will avoid the 'Non-selective query' errors.
	private Map<String, Account> getAccountData(Set<String> accountIdSet) {
		Map<String, Account> toReturnIdAccountRecMap = new Map<String, Account>();
		if (accountIdSet != null && accountIdSet.size() > 0) {
			for (Account accRec : [SELECT Id, ZP_Company_Id__c, Name FROM Account WHERE ZP_Company_Id__c != NULL AND ZP_Company_Id__c IN :accountIdSet]) {
				toReturnIdAccountRecMap.put(accRec.ZP_Company_Id__c, accRec);
			}
		}
		return toReturnIdAccountRecMap;
	}

	private Map<String, contributionInformation> getPolicyContributionInfo(Set<String> policyIdSet) {
		Map<String, contributionInformation> toReturnContributionMap = new Map<String, contributionInformation>();
		Map<String, String> policyIdCompanyContributionIdMap = new Map<String, String>();
		Set<String> companyContributionSet = new Set<String>();
		for (HI_Policy_Contribution__c contribution : [
			SELECT Id, Company_Contribution_Id__c, Policy_Id__c
			FROM HI_Policy_Contribution__c
			WHERE Policy_Id__c != NULL AND Policy_Id__c IN :policyIdSet
		]) {
			policyIdCompanyContributionIdMap.put(contribution.Policy_Id__c, contribution.Company_Contribution_Id__c);
			companyContributionSet.add(contribution.Company_Contribution_Id__c);
		}

		Map<String, contributionInformation> compContributionMap = new Map<String, contributionInformation>();

		if (companyContributionSet.size() > 0) {
			for (HI_Company_Contribution__c contribution : [SELECT Id__c, Calculator_Inputs__c, Type__c FROM HI_Company_Contribution__c WHERE Id__c != NULL AND Id__c IN :companyContributionSet]) {
				if (
					(contribution.type__c == 'HealthCompanyContribution' ||
					contribution.type__c == 'LidiCompanyContribution') &&
					contribution.Calculator_Inputs__c != null &&
					contribution.Calculator_Inputs__c != ''
				) {
					HIContributionInfoJSON parsedData = getJSONParsedData(contribution.Calculator_Inputs__c);
					contributionInformation contributionInputInfo = new contributionInformation();
					if (parsedData.employee_calculator != null) {
						contributionInputInfo.type = Utils.humanize(parsedData.employee_calculator.type);
						contributionInputInfo.eePercentage = parsedData.employee_calculator.percentage;
					}
					if (parsedData.dependents_calculator != null) {
						contributionInputInfo.dependentPercentage = parsedData.dependents_calculator.percentage;
					}
					compContributionMap.put(contribution.Id__c, contributionInputInfo);
				}
			}
		}

		for (String policyId : policyIdSet) {
			if (policyIdCompanyContributionIdMap.containsKey(policyId)) {
				String contributionId = policyIdCompanyContributionIdMap.get(policyId);
				if (compContributionMap.containsKey(contributionId)) {
					toReturnContributionMap.put(policyId, compContributionMap.get(contributionId));
				}
			}
		}
		return toReturnContributionMap;
	}

	private Policy__c SetPolicyRequestType(Policy__c policy, String companyId) {
		boolean waitingPeriodChange = false;
		boolean contributionChange = false;
		boolean planTypeExists = false;

		Map<String, Map<String, List<Policy__c>>> benTypeCarrierPolicyListMap = new Map<String, Map<String, List<Policy__c>>>();
		if (!companyIdCarrierPolicyMap.containsKey(companyId)) {
			return policy;
		}
		benTypeCarrierPolicyListMap = companyIdCarrierPolicyMap.get(companyId);

		Map<String, List<Policy__c>> CarrierPolicyListMap = new Map<String, List<Policy__c>>();
		if (!benTypeCarrierPolicyListMap.containsKey(policy.Benefit_Type__c)) {
			return policy;
		}

		Set<String> set_requestType = new Set<String>();
		CarrierPolicyListMap = benTypeCarrierPolicyListMap.get(policy.Benefit_Type__c);
		if (policy.Request_Type__c != null) {
			set_requestType.addAll(policy.Request_Type__c.split(';'));
		}

		//List<Policy__c> policyList = new List<Policy__c>();
		if (policy.Carrier__c != null && !CarrierPolicyListMap.containsKey(policy.Carrier__c)) {
			if (set_requestType.contains('Carrier Switch')) {
				return policy;
			} else {
				set_requestType.add('Carrier Switch');
			}
		} else {
			List<Policy__c> existingCarrierPolicies = CarrierPolicyListMap.get(policy.Carrier__c);
			for (Policy__c plcy : existingCarrierPolicies) {
				if (policy.Waiting_Period__c != plcy.Waiting_Period__c) {
					waitingPeriodChange = true;
				}
				if (
					policy.Contribution_Scheme_Type__c != plcy.Contribution_Scheme_Type__c ||
					policy.Contribution_for_EEs__c != plcy.Contribution_for_EEs__c ||
					policy.Contribution_for_Dependents__c != plcy.Contribution_for_Dependents__c
				) {
					contributionChange = true;
				}
				if (policy.Plan_Type__c == plcy.Plan_Type__c) {
					planTypeExists = true;
				}
			}
		}

		if (waitingPeriodChange == true) {
			set_requestType.add('Waiting Period Change');
		}

		if (contributionChange == true) {
			set_requestType.add('Contribution Scheme Change');
		}

		if (planTypeExists == false) {
			set_requestType.add('Plan Change');
		}

		if (!set_requestType.isEmpty()) {
			policy.Request_Type__c = String.join(new List<String>(set_requestType), ';');
		}
		return policy;
	}

	private void SetExistingPolicyInfoMap(
		List<HI_Policy__c> existingPolicyList,
		Map<String, HI_Benefits_Package__c> benPkgMap,
		Map<String, Hi_Benefits_Plan__c> benefitPlanIdRecordMap,
		Map<String, Policy__c> policyIdRecordMap,
		Map<String, State__c> stateIdRecordMap,
		Map<String, Account> accountIdRecordMap,
		Map<String, HI_Renewal__c> renewalMap,
		Map<String, HI_Health_Plan_Detail__c> healthPlanDetailMap,
		Map<String, Carrier__c> carrierMap,
		Map<String, HI_Health_Policy_Detail__c> healthPoicyDetailMap,
		Map<String, HI_Lidi_Policy_Detail__c> lidiPoicyDetailMap,
		Map<String, contributionInformation> policyIdContributionInfoMap
	) {
		companyIdCarrierPolicyMap = new Map<String, Map<String, Map<String, List<Policy__c>>>>();
		for (HI_Policy__c hiPolicy : existingPolicyList) {
			Policy__c policy = new Policy__c();
			contributionInformation policyContributionInfo;
			if (policyIdContributionInfoMap.containsKey(hiPolicy.Id__c)) {
				policyContributionInfo = policyIdContributionInfoMap.get(hiPolicy.Id__c);
			}
			if (!benPkgMap.containsKey(hiPolicy.Benefits_Package_Id__c)) {
				continue;
			}
			HI_Benefits_Package__c benefitsPackage = benPkgMap.get(hiPolicy.Benefits_Package_Id__c);

			Account acc = new Account();
			if (benefitsPackage != null && accountIdRecordMap != null && accountIdRecordMap.containsKey(benefitsPackage.Company_Id__c)) {
				acc = accountIdRecordMap.get(benefitsPackage.Company_Id__c);
			}

			if (hiPolicy.Policy_Detail_Type__c == 'DcaPolicyDetail' || hiPolicy.Policy_Detail_Type__c == 'FsaPolicyDetail') {
				continue;
			}

			if (!benefitPlanIdRecordMap.containsKey(hipolicy.Plan_Id__c)) {
				continue;
			}

			Hi_Benefits_Plan__c benefitPlan = benefitPlanIdRecordMap.get(hipolicy.Plan_Id__c);

			if (!carrierMap.containsKey(benefitPlan.National_Carrier_Id__c + '-' + benefitPlan.State__c)) {
				continue;
			}

			Hi_Health_Plan_Detail__c healthPlanDetail = new Hi_Health_Plan_Detail__c();
			if (hiPolicy.Policy_Detail_Type__c != 'DcaPolicyDetail' && hiPolicy.Policy_Detail_Type__c != 'FsaPolicyDetail' && benefitPlan.Type__c == 'HealthPlan') {
				if (!healthPlanDetailMap.containsKey(hipolicy.Plan_Id__c)) {
					continue;
				} else {
					healthPlanDetail = healthPlanDetailMap.get(hipolicy.Plan_Id__c);
				}
			}

			if (
				hiPolicy.Policy_Detail_Type__c != 'DcaPolicyDetail' &&
				hiPolicy.Policy_Detail_Type__c != 'FsaPolicyDetail' &&
				!carrierMap.containsKey(benefitPlan.National_Carrier_Id__c + '-' + benefitPlan.State__c)
			) {
				continue;
			}

			Map<String, Map<String, List<Policy__c>>> benTypeCarrierPolicyListMap = new Map<String, Map<String, List<Policy__c>>>();
			if (companyIdCarrierPolicyMap.containsKey(benefitsPackage.Company_Id__c)) {
				benTypeCarrierPolicyListMap = companyIdCarrierPolicyMap.get(benefitsPackage.Company_Id__c);
			}

			if (benefitPlan.Type__c == 'HealthPlan') {
				policy.Benefit_Type__c = Utils.humanize(healthPlanDetail.Insurance_Type__c);
			} else {
				policy.Benefit_Type__c = IntegrationUtils.getIntegrationValueMap('Policy__c', 'Benefit_Type__c').get(benefitPlan.Type__c);
			}

			Carrier__c carrier = carrierMap.get(benefitPlan.National_Carrier_Id__c + '-' + benefitPlan.State__c);
			policy.Carrier__c = carrier.id;
			policy.Plan_Type__c = Utils.humanize(healthPlanDetail.Plan_Type__c);
			policy.Plan_Tier__c = Utils.humanize(healthPlanDetail.Metal_Tier__c);

			Map<String, List<Policy__c>> carrierPolicyListMap = new Map<String, List<Policy__c>>();
			if (benTypeCarrierPolicyListMap.containsKey(policy.Carrier__c)) {
				carrierPolicyListMap = benTypeCarrierPolicyListMap.get(policy.Benefit_Type__c);
			}

			List<Policy__c> policyList = new List<Policy__c>();
			if (carrierPolicyListMap.containsKey(policy.Carrier__c)) {
				policyList = carrierPolicyListMap.get(policy.Carrier__c);
			}

			// SJay - 08/26/2020 - Moved this section so Waiting_Period__c fields get updated for every policy type. Removed space from "Waiting_Period__c"
			Map<String, String> waitingPeriodMap = IntegrationUtils.getIntegrationValueMap('Opportunity', 'Waiting_Period__c');
			if (waitingPeriodMap.containsKey(hiPolicy.Waiting_Period__c)) {
				policy.Waiting_Period__c = waitingPeriodMap.get(hiPolicy.Waiting_Period__c);
			}

			// SJay - 07/19/2020 - Moved this section so contribution scheme fields get updated for every policy type.
			if (policyContributionInfo != null) {
				policy.Contribution_Scheme_Type__c = policyContributionInfo.type;
				if (policyContributionInfo.eePercentage != null) {
					policy.Contribution_for_EEs__c = '' + policyContributionInfo.eePercentage * 100;
				}
				if (policyContributionInfo.dependentPercentage != null) {
					policy.Contribution_for_Dependents__c = '' + policyContributionInfo.dependentPercentage * 100;
				}
			}
			policyList.add(policy);
			carrierPolicyListMap.put(policy.Carrier__c, policyList);
			benTypeCarrierPolicyListMap.put(policy.Benefit_Type__c, carrierPolicyListMap);
			companyIdCarrierPolicyMap.put(benefitsPackage.Company_Id__c, benTypeCarrierPolicyListMap);
		}
	}

	private List<HI_Policy__c> getPolicyList(Set<String> companyIDSet) {
		List<HI_Policy__c> policyList = new List<HI_Policy__c>();
		Set<String> benPkgIdSet = new Set<String>();
		Map<String, String> pkgCompanyMap = new Map<String, String>();
		for (HI_Benefits_Package__c bpg : [SELECT Id__c, Company_Id__c FROM HI_Benefits_Package__c WHERE Company_Id__c != NULL AND Company_Id__c IN :companyIDSet]) {
			benPkgIdSet.add(bpg.Id__c);
			pkgCompanyMap.put(bpg.Id__c, bpg.Company_Id__c);
		}

		if (benPkgIdSet.size() > 0) {
			policyList = new List<HI_Policy__c>(
				[
					SELECT
						Benefits_Package_Id__c,
						Bor_Transfer_Id__c,
						Carrier_Id__c,
						Company_Id__c,
						Created_At__c,
						Deleted_At__c,
						Dental__c,
						Effective_Date__c,
						Expiration_Date__c,
						External_Key__c,
						FSA__c,
						Group_Number__c,
						Id,
						Id__c,
						IsDeleted,
						Is_Base__c,
						Is_Renewal__c,
						Last_Processed__c,
						Medical__c,
						Message__c,
						Name,
						Name__c,
						OwnerId,
						Plan_Document_Link__c,
						Plan_Id__c,
						Plan_Type__c,
						Policy_Detail_Id__c,
						Policy_Detail_Type__c,
						Policy_Number__c,
						Policy__c,
						Portal_Access_Status__c,
						Processed_At__c,
						Processing_State__c,
						Renewal_Id__c,
						Secondary_Group_Number__c,
						State__c,
						Termination_Policy__c,
						Updated_At__c,
						Visible__c,
						Vision__c,
						Waiting_Period__c
					FROM HI_Policy__c
					WHERE
						Effective_Date__c < :System.today()
						AND Expiration_Date__c > :System.today()
						AND visible__c = TRUE
						AND Benefits_Package_Id__c != NULL
						AND Benefits_Package_Id__c IN :benPkgIdSet
				]
			);
			companyIdCarrierPolicyMap = new Map<String, Map<String, Map<String, List<Policy__c>>>>();
		}
		return policyList;
	}

	// populating HI_Policy__c object fields
	private HI_Policy__c setProcessingPolicy(String ProcessingState, String message, HI_Policy__c hiPolicy, String policyId) {
		hiPolicy.Processing_State__c = ProcessingState;
		hiPolicy.Message__c = message.left(250);
		hiPolicy.Last_Processed__c = System.now();
		hiPolicy.Policy__c = policyId;
		return hiPolicy;
	}

	private HIContributionInfoJSON getJSONParsedData(String jsonString) {
		HIContributionInfoJSON parsedData = (HIContributionInfoJSON) JSON.deserialize(jsonString.replace('=>', ':'), HIContributionInfoJSON.class);
		return parsedData;
	}

	public class contributionInformation {
		public String type;
		public decimal eePercentage;
		public decimal dependentPercentage;
	}

	public class HIContributionInfoJSON {
		public String type;
		public CalculatorJSON employee_calculator;
		public CalculatorJSON dependents_calculator;
	}

	public class CalculatorJSON {
		public String type;
		public decimal percentage;
		public long base_policy_id;
	}
}