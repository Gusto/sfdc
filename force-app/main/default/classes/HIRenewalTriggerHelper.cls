public with sharing class HIRenewalTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	public static boolean queue = false;

	public static Id renewalRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
	public static map<string, string> eventRecordableIdUserEmailMap = new Map<string, string>();

	public void OnBeforeInsert(List<HI_Renewal__c> renewals) {
		counter++;
		if (queue == true) {
			processInformation(renewals);
		} else {
			for (HI_Renewal__c state : renewals) {
				state.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, HI_Renewal__c> renewalMap) {
		if (queue == false) {
			HIRenewalQueue updateJob = new HIRenewalQueue(renewalMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedRenewalIDs) {
	}

	public void OnBeforeUpdate(Map<ID, HI_Renewal__c> oldRenewalMap, Map<ID, HI_Renewal__c> newRenewalMap) {
		counter++;
		if (queue == true) {
			processInformation(newRenewalMap.values());
		} else {
			for (HI_Renewal__c stateCarrier : newRenewalMap.values()) {
				HI_Renewal__c oldRewObj = oldRenewalMap.get(stateCarrier.Id);
				stateCarrier.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, HI_Renewal__c> oldRenewalMap, Map<ID, HI_Renewal__c> newRenewalMap) {
		if (queue == false) {
			HIRenewalQueue updateJob = new HIRenewalQueue(newRenewalMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedCompantIDs) {
	}

	public void OnBeforeDelete(HI_Renewal__c[] renewalToDelete, Map<ID, HI_Renewal__c> oldRenewalMap) {
		counter++;
	}

	public void OnAfterDelete(HI_Renewal__c[] deletedRenewals, Map<ID, HI_Renewal__c> oldRenewalMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedCompanyIDs) {
	}

	public void OnUndelete(HI_Renewal__c[] restoredRenewals) {
		counter++;
	}

	private Opportunity mapOpportunityFields(HI_Renewal__c hiRenewal, Account acc, Map<String, Opportunity> opportunityMap, Map<String, List<HI_Aasm_Event__c>> asamEvents) {
		Opportunity opp = new Opportunity();
		if (opportunityMap.containsKey(hiRenewal.External_Key__c) == false) {
			opp.StageName = 'SAL';
		}
		opp = mapEventData(opp, hiRenewal.Id__c, asamEvents);
		opp.RecordTypeId = renewalRecordTypeId;
		opp.AccountId = acc.id;
		opp.Source_ID__c = hiRenewal.External_Key__c;
		opp.Maestro__c = hiRenewal.Maestro__c;
		opp.Name = StringUtils.getOppName(acc.Name, 'Benefits Renewal');
		opp.Id__c = 'HIRENEWAL' + hiRenewal.Id__c;
		//Added by AKS dated 21st Jan 2021 to check if account is part of multi EIN then mark multi-EIn on opp as true
		if (acc != null && (acc.ParentId != null || (acc.ChildAccounts != null && acc.ChildAccounts.size() > 0))) {
			opp.Is_Multi_EIN__c = true;
		}
		opp.Offering_Selection_Deadline__c = hiRenewal.Selection_Deadline__c;
		if (hiRenewal.Benefit_Types__c != null && hiRenewal.Benefit_Types__c != '') {
			Set<String> tempBTSet = new Set<String>();
			tempBTSet.addAll(hiRenewal.Benefit_Types__c.replaceAll(' ', '').replace('[', '').replace(']', '').replaceAll('"', '').trim().split(','));

			if (tempBTSet.contains('medical')) {
				opp.Medical_Renewal__c = true;
			}
			if (tempBTSet.contains('dental')) {
				opp.Dental_Renewal__c = true;
			}
			if (tempBTSet.contains('vision')) {
				opp.Vision_Renewal__c = true;
			}
			if (tempBTSet.contains('life')) {
				opp.Life_Renewal__c = true;
			}
			if (tempBTSet.contains('long_term_disability')) {
				opp.Long_Term_Disability_Renewal__c = true;
			}
			if (tempBTSet.contains('short_term_disability')) {
				opp.Short_Term_Disability_Renewal__c = true;
			}
			if (tempBTSet.contains('fsa')) {
				opp.FSA_Renewal__c = true;
			}
			if (tempBTSet.contains('dca')) {
				opp.DCA_Renewal__c = true;
			}
			if (tempBTSet.contains('hsa')) {
				opp.HSA_Renewal__c = true;
			}
			if (tempBTSet.contains('voluntary_life')) {
				opp.Voluntary_Life__c = true;
			}
		} else {
			opp.Medical_Renewal__c = false;
			opp.Dental_Renewal__c = false;
			opp.Vision_Renewal__c = false;
			opp.Life_Renewal__c = false;
			opp.Long_Term_Disability_Renewal__c = false;
			opp.Short_Term_Disability_Renewal__c = false;
			opp.FSA_Renewal__c = false;
			opp.HSA_Renewal__c = false;
			opp.DCA_Renewal__c = false;
			opp.Voluntary_Life__c = false;
		}
		opp.Async_Renewal__c = hiRenewal.Async_Renewal__c;
		opp.Needs_Successors__c = hiRenewal.Needs_Successors__c;
		opp.Renewal_Date__c = hiRenewal.Renewal_Date__c;
		opp.Benefits_Current_Setup_Step__c = hiRenewal.Mapped_Status__c;

		return opp;
	}

	private void processInformation(List<HI_Renewal__c> renewalList) {
		Set<string> renewalIDSet = new Set<String>();
		Set<string> companyIDSet = new Set<String>();
		Set<string> benefitsPackageIDSet = new Set<String>();
		Set<string> opportunityIdSet = new Set<String>();
		List<Opportunity> toUpsertOpportunityList = new List<Opportunity>();

		List<Opportunity> updateSourceIdOpportunityList = new List<Opportunity>();

		for (HI_Renewal__c renewal : renewalList) {
			if (renewal.Processing_State__c == IntegrationUtils.DEAD_STATE || renewal.Updated_At__c < (system.today() - 20)) {
				continue;
			}
			if (renewal.Updated_At__c < renewal.Processed_At__c && renewal.Updated_At__c < (system.now() - 24)) {
				setProcessingRenewal(IntegrationUtils.PROCESSED_STATE, 'Information is already processed.', renewal);
				continue;
			}

			if (renewal.External_Key__c == null) {
				setProcessingRenewal(IntegrationUtils.ERROR_STATE, 'External Key: field value is missing in the record.', renewal);
				continue;
			}

			if (renewal.Company_Id__c == null) {
				setProcessingRenewal(IntegrationUtils.ERROR_STATE, 'Company Id: field value is missing in the record.', renewal);
				continue;
			}
			if (renewal.Benefits_Package_Id__c != null && renewal.Benefits_Package_Id__c != '') {
				benefitsPackageIDSet.add(renewal.Benefits_Package_Id__c);
			}
			companyIDSet.add(renewal.Company_Id__c);
			opportunityIdSet.add(renewal.External_Key__c);
			renewalIDSet.add(renewal.Id__c);
		}

		Map<String, List<HI_Aasm_Event__c>> asamEvents = getEventData(renewalIDSet);
		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
        
		if (companyIDSet.size() > 0) {
			Map<String, Map<String, Opportunity>> opportunityRecordMap = getOpportunityData(companyIDSet);
			Map<String, Account> companyIdRecordMap = getCompanyData(companyIDSet);
			for (HI_Renewal__c hiRenewal : renewalList) {
				if (hiRenewal.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}
				if (opportunityRecordMap.containsKey(hiRenewal.External_Key__c)) {
					continue;
				}
				Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
				if (opportunityRecordMap.containsKey(hiRenewal.Company_Id__c)) {
					opportunityMap = opportunityRecordMap.get(hiRenewal.Company_Id__c);
					if (opportunityMap.containsKey(hiRenewal.External_Key__c)) {
						Opportunity existingOpp = opportunityMap.get(hiRenewal.External_Key__c);
						if (
							existingOpp.IsClosed &&
							!existingOpp.IsWon &&
							(existingOpp.StageName == 'Order Lost' &&
							hiRenewal.Mapped_Status__c != 'Dismissed' &&
							hiRenewal.Deleted_At__c == null &&
							hiRenewal.Mapped_Status__c != existingOpp.Benefits_Current_Setup_Step__c)
						) {
							existingOpp.Source_ID__c = null;
							existingOpp.ID__c = null;
							updateSourceIdOpportunityList.add(existingOpp);
						}
					}
				}
			}
			if (updateSourceIdOpportunityList.size() > 0) {
				update updateSourceIdOpportunityList;
			}

			opportunityRecordMap = getOpportunityData(companyIDSet);

			for (HI_Renewal__c hiRenewal : renewalList) {
				Opportunity toUpsertOpportunityRec = new Opportunity();
				Account toUpsertAccountRec = new Account();

				if (hiRenewal.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}
                
				if (companyIdRecordMap.containsKey(hiRenewal.Company_Id__c)) {
					toUpsertAccountRec = companyIdRecordMap.get(hiRenewal.Company_Id__c);
				} else {
					setProcessingRenewal(IntegrationUtils.ERROR_STATE, 'Company record does not exit.', hiRenewal);
					continue;
				}
				Map<String, Opportunity> opportunityMap = opportunityRecordMap.get(hiRenewal.Company_Id__c);
                
				toUpsertOpportunityRec = mapOpportunityFields(hiRenewal, toUpsertAccountRec, opportunityMap, asamEvents);
				toUpsertOpportunityList.add(toUpsertOpportunityRec);
			}

			if (toUpsertOpportunityList.size() > 0) {
				List<Database.UpsertResult> saveResult = database.upsert(toUpsertOpportunityList, Opportunity.Fields.Source_ID__c, false);
				dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, toUpsertOpportunityList, 'Source_ID__c', false, 'HIRenewalTriggerHelper-processInformation');
			}
		}

		for (HI_Renewal__c hiRenewal : renewalList) {
			if (string.isblank(hiRenewal.External_Key__c)) {
				setProcessingRenewal(IntegrationUtils.ERROR_STATE, 'Opportunity Id is missing in the record.', hiRenewal);
				continue;
			}

			if (dmlUpsertErrorsMap.containsKey(hiRenewal.External_Key__c)) {
				setProcessingRenewal(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(hiRenewal.External_Key__c), hiRenewal);
			} else if (hiRenewal.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingRenewal(IntegrationUtils.PROCESSED_STATE, 'Processed', hiRenewal);
			}
		}
		/*By: Deepak Tyagi, Dec 5, 2018 Desc: Renewal Survey Requirements: Create Survey for HI Renewal.*/
		HIRenewalSurvey hiRenewalSurveyObj = new HIRenewalSurvey();
		hiRenewalSurveyObj.processInformation(renewalList);
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
						SELECT Id, Is_Multi_EIN__c, Source_Id__c, Id__c, Name, RecordTypeId, StageName, IsClosed, IsWon, Benefits_Current_Setup_Step__c, Users_Email__c
						FROM Opportunities
						WHERE RecordTypeId = :renewalRecordTypeId
					)
				FROM Account
				WHERE ZP_Company_ID__c IN :companyIdSet
			]) {
				map<String, Opportunity> oppMap = new Map<String, Opportunity>();
				if (acc.Opportunities != null) {
					for (Opportunity opp : acc.Opportunities) {
						if (opp.Source_ID__c != null && opp.Source_ID__c != '') {
							oppMap.put(opp.Source_ID__c, opp);
							if (opp.IsClosed == false) {
								oppMap.put(acc.ZP_Company_ID__c, opp);
							}
						} else {
							oppMap.put(acc.ZP_Company_ID__c, opp);
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
		Map<String, Account> toReturnIdAccountRecMap = new Map<String, Account>();
		if (accountIdSet != null && accountIdSet.size() > 0) {
			//Added Parent id and Child accounts as sub query by AKS dated 21/1/2021 to mark Multi-EIN on opp level as true
			for (Account accRec : [
				SELECT id, Name, ZP_Company_ID__c, ParentId, (SELECT id FROM ChildAccounts LIMIT 1)
				FROM Account
				WHERE ZP_Company_ID__c IN :accountIdSet AND ZP_Company_ID__c != NULL
			]) {
				toReturnIdAccountRecMap.put(accRec.ZP_Company_ID__c, accRec);
			}
		}
		return toReturnIdAccountRecMap;
	}

	// populating HI_State_carrier__c object fields
	private HI_Renewal__c setProcessingRenewal(String ProcessingState, String message, HI_Renewal__c renewal) {
		renewal.Processing_State__c = ProcessingState;
		renewal.Message__c = message;
		if (ProcessingState == IntegrationUtils.PROCESSED_STATE) {
			renewal.Processed_At__c = System.now();
		}
		return renewal;
	}

	public static map<String, List<HI_Aasm_Event__c>> getEventData(Set<String> applicationIds) {
		Map<String, List<HI_Aasm_Event__c>> asamEvents = new Map<String, List<HI_Aasm_Event__c>>();
		Map<String, String> recordableIdWhoDunnitIdMap = new Map<String, String>();
		Map<String, DateTime> recordableIdLatestCreatedDateMap = new Map<String, DateTime>();

		for (HI_Aasm_Event__c event : [
			SELECT Id, Created_At__c, Deleted_At__c, External_Key__c, From__c, Id__c, Paper_Trail_Whodunnit__c, Recordable_Id__c, Recordable_Type__c, To__c, Updated_At__c
			FROM HI_Aasm_Event__c
			WHERE Recordable_Type__c = 'Renewal' AND Recordable_Id__c IN :applicationIds
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
				dateTime oldRecDate = recordableIdLatestCreatedDateMap.get(event.Recordable_Id__c);
				if (event.Created_At__c > oldRecDate) {
					recordableIdWhoDunnitIdMap.put(event.Recordable_Id__c, event.Paper_Trail_Whodunnit__c);
					recordableIdLatestCreatedDateMap.put(event.Recordable_Id__c, event.Created_At__c);
				}
			} else {
				recordableIdWhoDunnitIdMap.put(event.Recordable_Id__c, event.Paper_Trail_Whodunnit__c);
				recordableIdLatestCreatedDateMap.put(event.Recordable_Id__c, event.Created_At__c);
			}
		}

		if (recordableIdWhoDunnitIdMap.keyset().size() > 0) {
			populateEventRecordableIdUserEmailMap(recordableIdWhoDunnitIdMap);
		}

		return asamEvents;
	}

	public static Opportunity mapEventData(Opportunity tempOpp, String applicationId, Map<String, List<HI_Aasm_Event__c>> asamEvents) {
		if (asamEvents.containsKey(applicationId)) {
			List<HI_Aasm_Event__c> asamList = asamEvents.get(applicationId);
			for (HI_Aasm_Event__c event : asamList) {
				if (event.To__c == 'answering_survey') {
					tempOpp.Answering_Survey_Start__c = event.created_at__c;
				}
				if (event.From__c == 'answering_survey') {
					tempOpp.Answering_Survey_End__c = event.created_at__c;
				}
				if (event.To__c == 'awaiting_offerings') {
					tempOpp.Awaiting_Offerings_Start__c = event.created_at__c;
				}
				if (event.From__c == 'awaiting_offerings') {
					tempOpp.Awaiting_Offerings_End__c = event.created_at__c;
				}

				if (event.To__c == 'awaiting_education') {
					tempOpp.Awaiting_Education_Start__c = event.created_at__c;
				}
				if (event.From__c == 'awaiting_education') {
					tempOpp.Awaiting_Education_End__c = event.created_at__c;
				}

				if (event.To__c == 'receiving_education') {
					tempOpp.Receiving_Education_Start__c = event.created_at__c;
				}
				if (event.From__c == 'receiving_education') {
					tempOpp.Receiving_Education_End__c = event.created_at__c;
				}
				if (event.To__c == 'selecting_offerings') {
					tempOpp.Selecting_Offerings_Start__c = event.created_at__c;
				}
				if (event.From__c == 'selecting_offerings') {
					tempOpp.Selecting_Offerings_End__c = event.created_at__c;
				}
				if (event.To__c == 'signing_forms') {
					tempOpp.Signing_Forms_Started_Timestamp__c = event.created_at__c;
				}
				if (event.From__c == 'signing_forms') {
					tempOpp.Signing_Forms_Completed_Timestamp__c = event.created_at__c;
				}
				if (event.To__c == 'reviewing_summary') {
					tempOpp.Reviewing_Summary_Start__c = event.created_at__c;
				}
				if (event.From__c == 'reviewing_summary') {
					tempOpp.Reviewing_Summary_End__c = event.created_at__c;
				}
				if (event.To__c == 'complete') {
					tempOpp.Completed__c = event.created_at__c;
				}
				if (event.To__c == 'dismissed') {
					tempOpp.Dismissed__c = event.created_at__c;
				}
				if (tempOpp.Users_Email__c == null && eventRecordableIdUserEmailMap != null && eventRecordableIdUserEmailMap.containsKey(applicationId)) {
					tempOpp.Users_Email__c = eventRecordableIdUserEmailMap.get(applicationId);
				}
			}
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
	public static void populateEventRecordableIdUserEmailMap(Map<String, String> recordableIdWhoDunnitIdMap) {
		Map<String, String> userIdEmailMap = new Map<String, String>();
		eventRecordableIdUserEmailMap = new Map<String, String>();

		if (recordableIdWhoDunnitIdMap != null && recordableIdWhoDunnitIdMap.keyset().size() > 0) {
			Set<String> tempWhoDunnitIdSet = new Set<String>();
			tempWhoDunnitIdSet.addAll(recordableIdWhoDunnitIdMap.values());
			Set<String> nullSet = new Set<String>();
			nullSet.add(null);
			tempWhoDunnitIdSet.removeAll(nullSet);

			if (tempWhoDunnitIdSet.size() > 0) {
				for (ZP_User__c usr : [SELECT Id, Id__c, Email__c FROM Zp_user__c WHERE Id__c IN :tempWhoDunnitIdSet]) {
					if (usr.Email__c != null) {
						userIdEmailMap.put(usr.Id__c, usr.Email__c);
					}
				}

				for (String rId : recordableIdWhoDunnitIdMap.keyset()) {
					String userId = recordableIdWhoDunnitIdMap.get(rId);
					if (userIdEmailMap.containsKey(userId)) {
						eventRecordableIdUserEmailMap.put(rId, userIdEmailMap.get(userId));
					}
				}
			}
		}
	}
}