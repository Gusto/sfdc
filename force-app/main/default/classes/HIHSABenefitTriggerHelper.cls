public with sharing class HIHSABenefitTriggerHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	public static boolean queue = false;
	public static final String strNewPlanSourceKey = 'hawaiian_ice-new_plans_application-';
	public static final String strRenewalSourceKey = 'hawaiian_ice-renewal-';
	public static final String strBenefitChangesSourceKey = 'hawaiian_ice-benefit_change_application-';
	public static final String strBORTransferSourceKey = 'hawaiian_ice-bor_transfer-';
	public static final String strRenewalSourceType = 'Renewal';
	public static final String strNewPlanSourceType = 'NewPlansApplication';
	public static final String strBenefitChangesType = 'BenefitChangeApplication';
	public static final String strBORTransferType = 'BorTransfer';
	public static Set<String> set_ValidSourceType = new Set<String>{ strRenewalSourceType, strNewPlanSourceType, strBenefitChangesType, strBORTransferType };
	public static String strRequiredSourceId = 'Source Id & Source Type should not be blank.';
	public static String strInvalidSourceType = 'Invalid Source Type.';
	public static String strRequiredExternalKey = 'External key is empty.';
	public static String strHSA = 'HSA';
    	//Added for BBO-1967
    	public static String strGeneralHSAPOlicyName = 'HSA Benefit';

	public HIHSABenefitTriggerHelper() {
		super('HIHSABenefitTriggerHelper');
	}

	public override void beforeInsert() {
		List<HI_HSA_Benefit__c> list_benefits = (List<HI_HSA_Benefit__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_benefits);
		} else {
			for (HI_HSA_Benefit__c objBenefit : list_benefits) {
				objBenefit.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_HSA_Benefit__c> list_benefits = (List<HI_HSA_Benefit__c>) Trigger.new;
		if (queue == false) {
			HIHSABenefitQueue updateJob = new HIHSABenefitQueue(list_benefits);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public override void beforeUpdate() {
		List<HI_HSA_Benefit__c> list_benefits = (List<HI_HSA_Benefit__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_benefits);
		} else {
			for (HI_HSA_Benefit__c objBenefit : list_benefits) {
				objBenefit.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_HSA_Benefit__c> list_benefits = (List<HI_HSA_Benefit__c>) Trigger.new;
		if (queue == false) {
			HIHSABenefitQueue updateJob = new HIHSABenefitQueue(list_benefits);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	private Policy__c mapPolicyFields(HI_HSA_Benefit__c objBenefit, Policy__c objToUpdatePolicy, String strIdOpportunity) {
		objToUpdatePolicy.Id__c = 'hsa-' + objBenefit.Id__c;
	        List<Carrier__c> listOfCarriers = New List<Carrier__c>();
	        //BBO-1967 Start
	        if(objBenefit.Provider_Key__c != '' && objBenefit.Provider_Key__c != null){
	            listOfCarriers = [select Id from Carrier__c where Key__c =: objBenefit.Provider_Key__c];
	            if(listOfCarriers != null && listOfCarriers.size() > 0){
	                objToUpdatePolicy.Carrier__c = listOfCarriers[0].Id;
	            }
	        }
	        objToUpdatePolicy.Name = strGeneralHSAPOlicyName;
	        //BBO 1967 Ends
		if (objToUpdatePolicy.Opportunity__c == null) {
			objToUpdatePolicy.Opportunity__c = strIdOpportunity;
		}
		objToUpdatePolicy.Benefit_Type__c = strHSA;
		objToUpdatePolicy.External_Key__c = objBenefit.External_Key__c;
		return objToUpdatePolicy;
	}

	private void processInformation(List<HI_HSA_Benefit__c> list_HIBenefits) {
		Set<String> set_HIBenefitKeys = new Set<String>();
		Set<String> set_ApplicationKeys = new Set<String>();
		List<Policy__c> list_PolicyUpsert = new List<Policy__c>();
		Map<String, String> map_DmlUpsertErrors = new Map<String, String>();

		for (HI_HSA_Benefit__c objBenefit : list_HIBenefits) {
			if (objBenefit.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			objBenefit.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objBenefit.Message__c = '';

			if (String.isBlank(objBenefit.Source_Id__c) || String.isBlank(objBenefit.Source_Type__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, strRequiredSourceId, objBenefit);
				continue;
			} else if (!set_ValidSourceType.contains(objBenefit.Source_Type__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, strInvalidSourceType, objBenefit);
				continue;
			}

			if (objBenefit.External_Key__c == null) {
				setProcessingState(IntegrationUtils.ERROR_STATE, strRequiredExternalKey, objBenefit);
				continue;
			}

			set_HIBenefitKeys.add(objBenefit.External_Key__c);
			if (strRenewalSourceType == objBenefit.Source_Type__c) {
				set_ApplicationKeys.add(strRenewalSourceKey + objBenefit.Source_Id__c);
			} else if (strNewPlanSourceType == objBenefit.Source_Type__c) {
				set_ApplicationKeys.add(strNewPlanSourceKey + objBenefit.Source_Id__c);
			} else if (strBenefitChangesType == objBenefit.Source_Type__c) {
				set_ApplicationKeys.add(strBenefitChangesSourceKey + objBenefit.Source_Id__c);
			} else if (strBORTransferType == objBenefit.Source_Type__c) {
				set_ApplicationKeys.add(strBORTransferSourceKey + objBenefit.Source_Id__c);
			}
		}

		String strKey = '';
		Map<String, Opportunity> map_Opportunity = getOpportunityMap(set_ApplicationKeys);
		if (set_HIBenefitKeys.size() > 0) {
			for (HI_HSA_Benefit__c objBenefit : list_HIBenefits) {
				strKey = '';
				if (objBenefit.Processing_State__c == IntegrationUtils.DEAD_STATE || objBenefit.Processing_State__c == IntegrationUtils.ERROR_STATE) {
					continue;
				}

				if (strRenewalSourceType == objBenefit.Source_Type__c) {
					strKey = strRenewalSourceKey + objBenefit.Source_Id__c;
				} else if (strNewPlanSourceType == objBenefit.Source_Type__c) {
					strKey = strNewPlanSourceKey + objBenefit.Source_Id__c;
				} else if (strBenefitChangesType == objBenefit.Source_Type__c) {
					strKey = strBenefitChangesSourceKey + objBenefit.Source_Id__c;
				} else if (strBORTransferType == objBenefit.Source_Type__c) {
					strKey = strBORTransferSourceKey + objBenefit.Source_Id__c;
				}

				if (String.isNotBlank(strKey) && map_Opportunity.containsKey(strKey)) {
					Opportunity objOpp = map_Opportunity.get(strKey);
					Policy__c objPolicy = new Policy__c();
		                    //Added for BBO-1967
		                    if(objBenefit.Provider_Key__c == null || objBenefit.Provider_Key__c == ''){
		                        setProcessingState(IntegrationUtils.ERROR_STATE, 'Provider Key is blank.', objBenefit);
		                    }
		                    else{
		                        objPolicy = mapPolicyFields(objBenefit, objPolicy, objOpp.Id);
		                        list_PolicyUpsert.add(objPolicy);
		                    }
				} else {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Opportunity does not exist.', objBenefit);
				}
			}

			if (list_PolicyUpsert.size() > 0) {
				List<Database.UpsertResult> list_SaveResult = Database.upsert(list_PolicyUpsert, Policy__c.Fields.External_Key__c, false);
				map_DmlUpsertErrors = Utils.processUpsertResult(list_SaveResult, list_PolicyUpsert, 'External_Key__c', true, 'HIHSABenefitTriggerHelper-processInformation');
			}
		}

		for (HI_HSA_Benefit__c objBenefit : list_HIBenefits) {
			if (objBenefit.Processing_State__c == IntegrationUtils.DEAD_STATE || objBenefit.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (map_DmlUpsertErrors.containsKey(objBenefit.External_Key__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DmlUpsertErrors.get(objBenefit.External_Key__c), objBenefit);
			} else {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Processed', objBenefit);
			}
		}
	}

	private static Map<String, Opportunity> getOpportunityMap(Set<String> set_SourceIds) {
		Map<String, Opportunity> map_Opportunity = new Map<String, Opportunity>();
		for (Opportunity objOpp : [SELECT Id, Source_Id__c, Name FROM Opportunity WHERE Source_Id__c IN :set_SourceIds]) {
			map_Opportunity.put(objOpp.Source_Id__c, objOpp);
		}
		return map_Opportunity;
	}

	public HI_HSA_Benefit__c setProcessingState(String strProcessingState, String strMessage, HI_HSA_Benefit__c objBenefit) {
		objBenefit.Processing_State__c = strProcessingState;
		objBenefit.Message__c = objBenefit.Message__c + '-' + strMessage;
		objBenefit.Last_Processed__c = System.now();
		return objBenefit;
	}
}