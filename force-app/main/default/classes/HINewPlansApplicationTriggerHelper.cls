public without sharing class HINewPlansApplicationTriggerHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	public static boolean queue = false;
	public static String NP_APPLICATION = 'NP application';
	public static Id newPlanRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
	public static map<string, string> eventRecordableIdUserEmailMap = new Map<string, string>();
	public static Map<Id, HI_New_Plans_Application__c> map_npApplicationsOld = null;

	public HINewPlansApplicationTriggerHelper() {
		super('HINewPlansApplicationTriggerHelper');
	}

	public override void beforeInsert() {
		List<HI_New_Plans_Application__c> list_npApps = (List<HI_New_Plans_Application__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_npApps);
		} else {
			for (HI_New_Plans_Application__c application : list_npApps) {
				application.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_New_Plans_Application__c> list_npApps = (List<HI_New_Plans_Application__c>) Trigger.new;
		if (queue == false) {
			Map<Id, HI_New_Plans_Application__c> map_npApplicationsOld = Trigger.newMap != null ? (Map<Id, HI_New_Plans_Application__c>) Trigger.newMap : null;
			HINewPlansApplicationQueue updateJob = new HINewPlansApplicationQueue(list_npApps, map_npApplicationsOld);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public override void beforeUpdate() {
		List<HI_New_Plans_Application__c> list_npApps = (List<HI_New_Plans_Application__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_npApps);
		} else {
			for (HI_New_Plans_Application__c application : list_npApps) {
				application.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_New_Plans_Application__c> list_npApps = (List<HI_New_Plans_Application__c>) Trigger.new;
		if (queue == false) {
			Map<Id, HI_New_Plans_Application__c> map_npApplicationsOld = Trigger.oldMap != null ? (Map<Id, HI_New_Plans_Application__c>) Trigger.oldMap : null;
			HINewPlansApplicationQueue updateJob = new HINewPlansApplicationQueue(list_npApps, map_npApplicationsOld);
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public Opportunity mapOpportunityFields(HI_New_Plans_Application__c hiNPApplication, Account acc, map<string, Opportunity> opportunityMap, map<String, List<HI_Aasm_Event__c>> asamEvents) {
		Opportunity opp = new Opportunity();
		if (opportunityMap.containsKey(hiNPApplication.External_Key__c) == false) {
			opp.StageName = 'Raw';
			opp.LeadSource = NP_APPLICATION;
		} else {
			if (String.IsBlank(opportunityMap.get(hiNPApplication.External_Key__c).LeadSource)) {
				opp.LeadSource = NP_APPLICATION;
			}
		}
		opp = mapEventData(opp, hiNPApplication.Id__c, asamEvents);
		opp.RecordTypeId = newPlanRecordTypeId;
		opp.AccountId = acc.id;
		opp.Benefits_Current_Setup_Step__c = (hiNPApplication.Status__c != null ? Utils.humanize(hiNPApplication.Status__c.replaceAll('_', ' ')) : hiNPApplication.Status__c);
		opp.Source_ID__c = hiNPApplication.External_Key__c;
		opp.Name = StringUtils.getOppName(acc.Name, 'Benefits New Plan');
		opp.Id__c = 'HINEWPLANSAPPLICATION' + hiNPApplication.Id__c;
		opp.Waiting_Period__c = getWaitingPeriodInfo(hiNPApplication.Company_Information__c);
		opp.Selecting_Employee_Eligibility__c = hiNPApplication.Created_At__c;
		opp.HI_Effective_Date__c = hiNPApplication.Requested_Start_Date__c;
		opp.Unsupported_SIC_Code__c = hiNPApplication.Unsupported_SIC_Code__c;
		opp.Maestro__c = hiNPApplication.Maestro__c;
		// if (hiNPApplication.Dismissal_Reason__c != null) {
		// 	opp.Application_Dismissal_Reason__c = hiNPApplication.Dismissal_Reason__c;
		// }
		opp.HI_New_Plan_App_Status__c = hiNPApplication.Status__c;
		opp.Keep_Opportunity_Open_On_Dismissal__c = hiNPApplication.Keep_Opportunity_Open_On_Dismissal__c;
		return opp;
	}

	private void processInformation(List<HI_New_Plans_Application__c> npApplicationList) {
		set<string> newPlanIDSet = new Set<string>();
		set<string> companyIDSet = new Set<string>();
		set<string> benefitsPackageIDSet = new Set<string>();
		set<string> opportunityIdSet = new Set<string>();
		set<id> oppIdForPolicySync = new Set<id>();
		list<Opportunity> toUpsertOpportunityList = new List<Opportunity>();
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();

		for (HI_New_Plans_Application__c npApplication : npApplicationList) {
			if (npApplication.Processing_State__c == IntegrationUtils.DEAD_STATE || npApplication.Updated_At__c < (system.today() - 20)) {
				continue;
			}
			if (npApplication.Updated_At__c < npApplication.Processed_At__c && npApplication.Updated_At__c < (system.now() - 24)) {
				setProcessingNPApplication(IntegrationUtils.PROCESSED_STATE, 'Information is already processed.', npApplication);
				continue;
			}
			npApplication.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			npApplication.Message__c = '';

			if (npApplication.External_Key__c == null) {
				setProcessingNPApplication(IntegrationUtils.ERROR_STATE, 'External Key: field value is missing in the record.', npApplication);
				continue;
			}

			if (npApplication.Company_Id__c == null) {
				setProcessingNPApplication(IntegrationUtils.ERROR_STATE, 'Company Id: field value is missing in the record.', npApplication);
				continue;
			}
			companyIDSet.add(npApplication.Company_Id__c);
			opportunityIdSet.add(npApplication.External_Key__c);
			newPlanIDSet.add(npApplication.Id__c);
		}
		benefitsPackageIdSet = getNewPlanBenefitPackageData(newPlanIDSet);
		map<String, List<HI_Aasm_Event__c>> asamEvents = getEventData(newPlanIDSet);

		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
		if (companyIDSet.size() > 0) {
			map<string, map<String, Opportunity>> opportunityRecordMap = getOpportunityData(companyIDSet);
			map<string, Account> companyIdRecordMap = getCompanyData(companyIDSet);
			for (HI_New_Plans_Application__c hiNPApplication : npApplicationList) {
				if (hiNPApplication.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}
				if (opportunityRecordMap.containsKey(hiNPApplication.External_Key__c)) {
					continue;
				}
				map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
				if (opportunityRecordMap.containsKey(hiNPApplication.Company_Id__c)) {
					opportunityMap = opportunityRecordMap.get(hiNPApplication.Company_Id__c);
					if (opportunityMap.containsKey(hiNPApplication.External_Key__c)) {
						Opportunity existingOpp = opportunityMap.get(hiNPApplication.External_Key__c);
						string npStatus = (hiNPApplication.Status__c != null ? Utils.humanize(hiNPApplication.Status__c.replaceAll('_', ' ')) : hiNPApplication.Status__c);
						if (
							existingOpp.IsClosed &&
							!existingOpp.IsWon &&
							(existingOpp.StageName == 'Order Lost') &&
							npStatus != 'Dismissed' &&
							npStatus != 'dismissed' &&
							hiNPApplication.Deleted_At__c == null &&
							existingOpp.Benefits_Current_Setup_Step__c != npStatus
						) {
							existingOpp.Benefits_Current_Setup_Step__c = null;
							map_OpptysToUpdate.put(existingOpp.Id, existingOpp);
						} else if (existingOpp.IsClosed && !existingOpp.IsWon && existingOpp.StageName == 'Closed Lost') {
							if (hiNPApplication.Mapped_Status__c == 'Verifying eligibility' || hiNPApplication.Mapped_Status__c == 'Completed') {
								oppIdForPolicySync.add(existingOpp.id);
							}
							if (hiNPApplication.Status__c != null && hiNPApplication.Status__c != map_npApplicationsOld?.get(hiNPApplication.Id)?.Status__c) {
								existingOpp.Benefits_Current_Setup_Step__c = null;
								// existingOpp.StageName = 'Raw';
								map_OpptysToUpdate.put(existingOpp.Id, existingOpp);
							}
						}
					} else if (opportunityMap.containsKey(hiNPApplication.Company_Id__c)) {
						Opportunity existingOpp = opportunityMap.get(hiNPApplication.Company_Id__c);
						if (!existingOpp.IsClosed && String.isBlank(existingOpp.Source_ID__c)) {
							existingOpp.Source_ID__c = hiNPApplication.External_Key__c;
							map_OpptysToUpdate.put(existingOpp.Id, existingOpp);
						}
					}
				}
			}
			if (oppIdForPolicySync.size() > 0) {
				List<Policy__c> policyList = new List<Policy__c>([SELECT Id FROM Policy__c WHERE Opportunity__c IN :oppIdForPolicySync AND Is_Selected__c = TRUE]);
				PolicyHelper.forceLineItemLogic = true;
				update policyList;
			}
			if (!map_OpptysToUpdate.isEmpty()) {
				update map_OpptysToUpdate.values();
			}
			opportunityRecordMap = getOpportunityData(companyIDSet);

			for (HI_New_Plans_Application__c hiNPApplication : npApplicationList) {
				Opportunity toUpsertOpportunityRec = new Opportunity();
				Account toUpsertAccountRec = new Account();

				if (hiNPApplication.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}

				if (companyIdRecordMap.containsKey(hiNPApplication.Company_Id__c)) {
					toUpsertAccountRec = companyIdRecordMap.get(hiNPApplication.Company_Id__c);
				} else {
					setProcessingNPApplication(IntegrationUtils.ERROR_STATE, 'Company record does not exit.', hiNPApplication);
					continue;
				}
				map<String, Opportunity> opportunityMap = opportunityRecordMap.get(hiNPApplication.Company_Id__c);

				toUpsertOpportunityRec = mapOpportunityFields(hiNPApplication, toUpsertAccountRec, opportunityMap, asamEvents);
				toUpsertOpportunityList.add(toUpsertOpportunityRec);
			}

			if (toUpsertOpportunityList.size() > 0) {
				List<Database.UpsertResult> saveResult = database.upsert(toUpsertOpportunityList, Opportunity.Fields.Source_ID__c, false);
				dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, toUpsertOpportunityList, 'Source_ID__c', false, 'HINewPlansApplicationTriggerHelper-processInformation');
			}
		}

		for (HI_New_Plans_Application__c hiNPApplication : npApplicationList) {
			if (string.isblank(hiNPApplication.External_Key__c)) {
				setProcessingNPApplication(IntegrationUtils.ERROR_STATE, 'Opportunity Id is missing in the record.', hiNPApplication);
				continue;
			}

			if (dmlUpsertErrorsMap.containsKey(hiNPApplication.External_Key__c)) {
				setProcessingNPApplication(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(hiNPApplication.External_Key__c), hiNPApplication);
			} else if (hiNPApplication.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingNPApplication(IntegrationUtils.PROCESSED_STATE, 'Processed', hiNPApplication);
			}
		}
		if (queue == true && benefitsPackageIDSet.size() > 0) {
			if (queue == true) {
				HIPolicyTriggerHelper.queue = true;
			} else {
				HIPolicyTriggerHelper.queue = false;
			}
		}
	}

	// querying State object records present in the org using ID__c field
	private Map<string, Map<String, Opportunity>> getOpportunityData(set<string> companyIdSet) {
		map<string, Map<String, Opportunity>> companyIdOppInfoMap = new Map<string, Map<String, Opportunity>>();
		if (companyIdSet != null && companyIdSet.size() > 0) {
			for (Account acc : [
				SELECT
					Id,
					ZP_Company_ID__c,
					Name,
					(
						SELECT Id, Source_Id__c, Id__c, Name, RecordTypeId, StageName, IsClosed, IsWon, Benefits_Current_Setup_Step__c, Application_Dismissal_Reason__c, 
						Users_Email__c, LeadSource
						FROM Opportunities
						WHERE RecordTypeId = :newPlanRecordTypeId
					)
				FROM Account
				WHERE ZP_Company_ID__c IN :companyIdSet
			]) {
				map<String, Opportunity> oppMap = new Map<String, Opportunity>();
				if (acc.Opportunities != null) {
					for (Opportunity opp : acc.Opportunities) {
						if (opp.Source_ID__c != null && opp.Source_ID__c != '') {
							oppMap.put(opp.Source_ID__c, opp);
						} else {
							if (opp.IsClosed == false) {
								oppMap.put(acc.ZP_Company_ID__c, opp);
							}
						}
					}
				}
				companyIdOppInfoMap.put(acc.ZP_Company_ID__c, oppMap);
			}
		}
		return companyIdOppInfoMap;
	}

	// querying State object records present in the org using ID__c field
	private Map<string, Account> getCompanyData(set<string> accountIdSet) {
		map<string, Account> toReturnIdAccountRecMap = new Map<string, Account>();
		if (accountIdSet != null && accountIdSet.size() > 0) {
			for (Account accRec : [SELECT id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :accountIdSet AND ZP_Company_ID__c != NULL]) {
				toReturnIdAccountRecMap.put(accRec.ZP_Company_ID__c, accRec);
			}
		}
		return toReturnIdAccountRecMap;
	}

	// populating HI_State_carrier__c object fields
	public HI_New_Plans_Application__c setProcessingNPApplication(String ProcessingState, String message, HI_New_Plans_Application__c npApplication) {
		npApplication.Processing_State__c = ProcessingState;
		npApplication.Message__c = message;
		if (ProcessingState == IntegrationUtils.PROCESSED_STATE) {
			npApplication.Processed_At__c = System.now();
		}
		return npApplication;
	}

	private string getWaitingPeriodInfo(String companyInformation) {
		String waitingPeriod = '';
		map<String, String> valueMap = IntegrationUtils.getIntegrationValueMap('Opportunity', 'Waiting_Period__c');
		if (valueMap.containsKey(waitingPeriod)) {
			waitingPeriod = valueMap.get(waitingPeriod);
		}
		waitingPeriod = IntegrationUtils.getJsonParsedMap(companyInformation, 'waiting_period');
		return waitingPeriod;
	}

	public static map<String, List<HI_Aasm_Event__c>> getEventData(Set<String> applicationIds) {
		Map<String, List<HI_Aasm_Event__c>> asamEvents = new Map<String, List<HI_Aasm_Event__c>>();
		Map<String, String> recordableIdWhoDunnitIdMap = new Map<String, String>();
		Map<String, DateTime> recordableIdLatestCreatedDateMap = new Map<String, DateTime>();
		Map<String, String> recordableIdWhoDunnitIdOldMap = new Map<String, String>();

		for (HI_Aasm_Event__c event : [
			SELECT Id, Created_At__c, Deleted_At__c, External_Key__c, From__c, Id__c, Paper_Trail_Whodunnit__c, Recordable_Id__c, Recordable_Type__c, To__c, Updated_At__c
			FROM HI_Aasm_Event__c
			WHERE Recordable_Type__c = 'NewPlansApplication' AND Recordable_Id__c IN :applicationIds
			ORDER BY Created_At__c ASC
		]) {
			List<HI_Aasm_Event__c> asamList = new List<HI_Aasm_Event__c>();
			if (asamEvents.containsKey(event.Recordable_Id__c)) {
				asamList = asamEvents.get(event.Recordable_Id__c);
			}
			asamList.add(event);
			asamEvents.put(event.Recordable_Id__c, asamList);

			/*
                Using the following code we want to get the Whodunnit id of the latest event for every unique
                Recordable_id value
            */

			if (recordableIdLatestCreatedDateMap.containsKey(event.Recordable_Id__c)) {
				DateTime oldRecDate = recordableIdLatestCreatedDateMap.get(event.Recordable_Id__c);
				if (event.Created_At__c > oldRecDate && event.Paper_Trail_Whodunnit__c != '0') {
					recordableIdWhoDunnitIdMap.put(event.Recordable_Id__c, event.Paper_Trail_Whodunnit__c);
					recordableIdLatestCreatedDateMap.put(event.Recordable_Id__c, event.Created_At__c);
				} else {
					if (recordableIdWhoDunnitIdOldMap.containsKey(event.Recordable_Id__c)) {
						recordableIdWhoDunnitIdMap.put(event.Recordable_Id__c, recordableIdWhoDunnitIdOldMap.get(event.Recordable_Id__c));
					}
				}
			} else {
				if (event.Paper_Trail_Whodunnit__c != '0') {
					recordableIdWhoDunnitIdMap.put(event.Recordable_Id__c, event.Paper_Trail_Whodunnit__c);
				}
				recordableIdLatestCreatedDateMap.put(event.Recordable_Id__c, event.Created_At__c);
			}

			if (event.Paper_Trail_Whodunnit__c != '0') {
				recordableIdWhoDunnitIdOldMap.put(event.Recordable_Id__c, event.Paper_Trail_Whodunnit__c);
			}
		}

		if (recordableIdWhoDunnitIdMap.keyset().size() > 0) {
			populateEventRecordableIdUserEmailMap(recordableIdWhoDunnitIdMap);
		}

		return asamEvents;
	}

	private Set<string> getNewPlanBenefitPackageData(set<string> applicationIdSet) {
		Set<string> pkgIdSet = new Set<string>();
		for (HI_New_Plans_ApplicationsBenefitsPackage__c benPackage : [
			SELECT Id, Benefits_Package_Id__c, Id__c, New_Plans_Application_Id__c
			FROM HI_New_Plans_ApplicationsBenefitsPackage__c
			WHERE New_Plans_Application_Id__c IN :applicationIdSet
		]) {
			pkgIdSet.add(benPackage.Benefits_Package_Id__c);
		}
		return pkgIdSet;
	}

	public static Opportunity mapEventData(Opportunity tempOpp, String applicationId, map<String, List<HI_Aasm_Event__c>> asamEvents) {
		if (asamEvents.containsKey(applicationId)) {
			List<HI_Aasm_Event__c> asamList = asamEvents.get(applicationId);
			for (HI_Aasm_Event__c event : asamList) {
				if (event.To__c == 'selecting_employee_eligibility') {
					tempOpp.Selecting_Employee_Eligibility_Start__c = event.created_at__c;
				}
				if (event.From__c == 'selecting_employee_eligibility') {
					tempOpp.Selecting_Employee_Eligibility_End__c = event.created_at__c;
				}
				if (event.To__c == 'receiving_medical_education') {
					tempOpp.Receiving_Medical_Education_Start__c = event.created_at__c;
					//tempOpp.Selecting_Base_Tier_Start__c = event.created_at__c;
				}
				if (event.From__c == 'receiving_medical_education') {
					tempOpp.Receiving_Medical_Education_End__c = event.created_at__c;
				}
				if (event.To__c == 'selecting_base_tier') {
					tempOpp.Selecting_Base_Tier_Start__c = event.created_at__c;
				}
				if (event.From__c == 'selecting_base_tier') {
					tempOpp.Selecting_Base_Tier_End__c = event.created_at__c;
				}
				if (event.To__c == 'selecting_base_plan') {
					tempOpp.Selecting_Base_Plan_Start__c = event.created_at__c;
				}
				if (event.From__c == 'selecting_base_plan') {
					tempOpp.Selecting_Base_Plan_End__c = event.created_at__c;
				}
				if (event.To__c == 'selecting_non_medical_plans') {
					tempOpp.Selecting_Non_Medical_Plans_Start__c = event.created_at__c;
				}
				if (event.From__c == 'selecting_non_medical_plans') {
					tempOpp.Selecting_Non_Medical_Plans_End__c = event.created_at__c;
				}
				if (event.To__c == 'selecting_complementary_plans') {
					tempOpp.Selecting_Complementary_Plans_Start__c = event.created_at__c;
				}
				if (event.From__c == 'selecting_complementary_plans') {
					tempOpp.Selecting_Complementary_Plans_End__c = event.created_at__c;
				}
				if (event.To__c == 'collecting_company_information') {
					tempOpp.Collecting_Company_information_Start__c = event.created_at__c;
				}
				if (event.From__c == 'collecting_company_information') {
					tempOpp.Collecting_Company_information_End__c = event.created_at__c;
				}
				if (event.To__c == 'reviewing_summary') {
					tempOpp.Reviewing_Summary_Start__c = event.created_at__c;
				}
				if (event.From__c == 'reviewing_summary') {
					tempOpp.Reviewing_Summary_End__c = event.created_at__c;
				}
				if (event.To__c == 'verifying_eligibility') {
					tempOpp.Verifying_Eligibility_Start__c = event.created_at__c;
				}
				if (event.From__c == 'verifying_eligibility') {
					tempOpp.Verifying_Eligibility_End__c = event.created_at__c;
				}
				if (event.To__c == 'completed') {
					tempOpp.Completed__c = event.created_at__c;
				}

				/*
                    BY: PR
                    At this point we are populating  Users_Email__c field of Opportunity, with the Email address of the 
                    latest WhoDunnit User, using static map "eventRecordableIdUserEmailMap" of this class
                    which we are populating in "populateEventRecordableIdUserEmailMap" method. 
                */
				if (tempOpp.Users_Email__c == null && eventRecordableIdUserEmailMap != null && eventRecordableIdUserEmailMap.containsKey(applicationId)) {
					tempOpp.Users_Email__c = eventRecordableIdUserEmailMap.get(applicationId);
				}
			}
		}
		if (
			tempOpp.Selecting_Employee_Eligibility_Start__c != null &&
			tempOpp.Selecting_Employee_Eligibility_End__c != null &&
			tempOpp.Selecting_Employee_Eligibility_End__c < tempOpp.Selecting_Employee_Eligibility_Start__c
		) {
			tempOpp.Selecting_Employee_Eligibility_End__c = null;
		}
		if (
			tempOpp.Receiving_Medical_Education_Start__c != null &&
			tempOpp.Receiving_Medical_Education_End__c != null &&
			tempOpp.Receiving_Medical_Education_End__c < tempOpp.Receiving_Medical_Education_Start__c
		) {
			tempOpp.Receiving_Medical_Education_End__c = null;
		}
		if (tempOpp.Selecting_Base_Tier_Start__c != null && tempOpp.Selecting_Base_Tier_End__c != null && tempOpp.Selecting_Base_Tier_End__c < tempOpp.Selecting_Base_Tier_Start__c) {
			tempOpp.Selecting_Base_Tier_End__c = null;
		}
		if (tempOpp.Selecting_Base_Plan_Start__c != null && tempOpp.Selecting_Base_Plan_End__c != null && tempOpp.Selecting_Base_Plan_End__c < tempOpp.Selecting_Base_Plan_Start__c) {
			tempOpp.Selecting_Base_Plan_End__c = null;
		}
		if (
			tempOpp.Selecting_Non_Medical_Plans_Start__c != null &&
			tempOpp.Selecting_Non_Medical_Plans_End__c != null &&
			tempOpp.Selecting_Non_Medical_Plans_End__c < tempOpp.Selecting_Non_Medical_Plans_Start__c
		) {
			tempOpp.Selecting_Non_Medical_Plans_End__c = null;
		}
		if (
			tempOpp.Selecting_Complementary_Plans_Start__c != null &&
			tempOpp.Selecting_Complementary_Plans_End__c != null &&
			tempOpp.Selecting_Complementary_Plans_End__c < tempOpp.Selecting_Complementary_Plans_Start__c
		) {
			tempOpp.Selecting_Complementary_Plans_End__c = null;
		}
		if (
			tempOpp.Collecting_Company_information_Start__c != null &&
			tempOpp.Collecting_Company_information_End__c != null &&
			tempOpp.Collecting_Company_information_End__c < tempOpp.Collecting_Company_information_Start__c
		) {
			tempOpp.Collecting_Company_information_End__c = null;
		}
		if (tempOpp.Reviewing_Summary_Start__c != null && tempOpp.Reviewing_Summary_End__c != null && tempOpp.Reviewing_Summary_End__c < tempOpp.Reviewing_Summary_Start__c) {
			tempOpp.Reviewing_Summary_End__c = null;
		}
		if (tempOpp.Verifying_Eligibility_Start__c != null && tempOpp.Verifying_Eligibility_End__c != null && tempOpp.Verifying_Eligibility_End__c < tempOpp.Verifying_Eligibility_Start__c) {
			tempOpp.Verifying_Eligibility_End__c = null;
		}
		return tempOpp;
	}

	/*
        By: PR
        Date: Nov,13,2018
        Description: Following method is receiving a map of unique recordable Id(as a keyset) and latest whoDunnitId as a parameter
         In the method we are querying the ZP_User__c records based on WhoDunnitId.
         Finally we are populating the static map "eventRecordableIdUserEmailMap" of this Class with unique RecordableId
         and latest WhodunnitId related Email Address.   
    */
	public static void populateEventRecordableIdUserEmailMap(map<String, string> recordableIdWhoDunnitIdMap) {
		map<string, string> userIdEmailMap = new Map<string, string>();
		eventRecordableIdUserEmailMap = new Map<string, string>();

		if (recordableIdWhoDunnitIdMap != null && recordableIdWhoDunnitIdMap.keyset().size() > 0) {
			set<string> tempWhoDunnitIdSet = new Set<string>();
			tempWhoDunnitIdSet.addAll(recordableIdWhoDunnitIdMap.values());
			set<string> nullSet = new Set<string>();
			nullSet.add(null);
			tempWhoDunnitIdSet.removeAll(nullSet);

			if (tempWhoDunnitIdSet.size() > 0) {
				for (ZP_User__c usr : [SELECT id, Id__c, Email__c FROM Zp_user__c WHERE Id__c IN :tempWhoDunnitIdSet]) {
					if (usr.Email__c != null) {
						userIdEmailMap.put(usr.Id__c, usr.Email__c);
					}
				}

				for (string rId : recordableIdWhoDunnitIdMap.keyset()) {
					string userId = recordableIdWhoDunnitIdMap.get(rId);
					if (userIdEmailMap.containsKey(userId)) {
						eventRecordableIdUserEmailMap.put(rId, userIdEmailMap.get(userId));
					}
				}
			}
		}
	}
}