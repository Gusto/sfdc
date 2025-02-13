public with sharing class HIBenefitChangeApplicationTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	public static boolean queue = false;

	public static Id changeRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change');
	//private static map<String,List<HI_Aasm_Event__c>> asamEvents;
	public static map<string, string> eventRecordableIdUserEmailMap = new Map<string, string>();
	private map<integer, String> monthMap = new Map<integer, String>{
		1 => 'January',
		2 => 'February',
		3 => 'March',
		4 => 'April',
		5 => 'May',
		6 => 'June',
		7 => 'July',
		8 => 'August',
		9 => 'September',
		10 => 'October',
		11 => 'November',
		12 => 'December'
	};

	public void OnBeforeInsert(List<HI_Benefit_Change_Application__c> changes) {
		counter++;
		if (queue == true) {
			processInformation(changes);
		} else {
			for (HI_Benefit_Change_Application__c change : changes) {
				change.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, HI_Benefit_Change_Application__c> changeMap) {
		if (queue == false) {
			HIBenefitChangeApplicationQueue updateJob = new HIBenefitChangeApplicationQueue(changeMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedChangeIDs) {
	}

	public void OnBeforeUpdate(Map<ID, HI_Benefit_Change_Application__c> oldChangeMap, Map<ID, HI_Benefit_Change_Application__c> newChangeMap) {
		counter++;

		if (queue == true) {
			processInformation(newChangeMap.values());
		} else {
			for (HI_Benefit_Change_Application__c change : newChangeMap.values()) {
				change.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, HI_Benefit_Change_Application__c> oldChangeMap, Map<ID, HI_Benefit_Change_Application__c> newChangeMap) {
		if (queue == false) {
			HIBenefitChangeApplicationQueue updateJob = new HIBenefitChangeApplicationQueue(newChangeMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedChangeIDs) {
	}

	public void OnBeforeDelete(HI_Benefit_Change_Application__c[] changesToDelete, Map<ID, HI_Benefit_Change_Application__c> oldChangeMap) {
		counter++;
	}

	public void OnAfterDelete(HI_Benefit_Change_Application__c[] deletedChanges, Map<ID, HI_Benefit_Change_Application__c> oldChangeMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedChangeIDs) {
	}

	public void OnUndelete(HI_Benefit_Change_Application__c[] restoredChanges) {
		counter++;
	}

	private Opportunity mapOpportunityFields(HI_Benefit_Change_Application__c hiChange, Account acc, map<string, Opportunity> opportunityMap, map<String, List<HI_Aasm_Event__c>> asamEvents) {
		Opportunity opp = new Opportunity();

		if (opportunityMap.containsKey(hiChange.External_Key__c) == false) {
			opp.StageName = 'SAL';
			opp.CloseDate = hiChange.Requested_Start_Date__c;
			opp.NumberOfEmployees__c = acc.Benefits_Employees__c;
			if (acc.Policies__r != null) {
				for (Policy__c policy : acc.Policies__r) {
					if (policy.Expiration_Date__c != null) {
						integer mth = policy.Expiration_Date__c.month();
						opp.Medical_Renewal_Date__c = monthMap.get(mth);
					}
				}
			}
		}
		opp = mapEventData(opp, hiChange.Id__c, asamEvents);
		opp.RecordTypeId = changeRecordTypeId;
		opp.AccountId = acc.id;
		opp.Source_ID__c = hiChange.External_Key__c;
		opp.Maestro__c = hiChange.Maestro__c;
		opp.Name = StringUtils.getOppName(acc.Name, 'Benefits Change');
		opp.Id__c = 'HIBENEFITCHANGE' + hiChange.Id__c;
		opp.Application_Started__c = hiChange.Created_At__c;
		opp.HI_Effective_Date__c = hiChange.Requested_Start_Date__c;
		opp.NumberOfEmployees__c = hiChange.Enrollees__c;
		opp.Benefits_Current_Setup_Step__c = Utils.humanize(hiChange.Mapped_Status__c);
		opp.Application_Deadline__c = hiChange.Application_Deadline__c;
		opp.Waiting_Period__c = Utils.humanize(hiChange.Waiting_Period__c);
		opp.application_type__c = Utils.humanize(hiChange.Application_Type__c);

		return opp;
	}

	private void processInformation(List<HI_Benefit_Change_Application__c> changeList) {
		set<string> newPlanIDSet = new Set<string>();
		set<string> companyIDSet = new Set<string>();
		set<string> opportunityIdSet = new Set<string>();
		set<string> benefitsPackageIDSet = new Set<string>();
		list<Opportunity> toUpsertOpportunityList = new List<Opportunity>();

		list<Opportunity> updateSourceIdOpportunityList = new List<Opportunity>();

		for (HI_Benefit_Change_Application__c change : changeList) {
			if (change.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			change.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
			change.Message__c = '';

			if (change.External_Key__c == null) {
				setProcessingChange(IntegrationUtils.ERROR_STATE, 'External Key: field value is missing in the record.', change);
				continue;
			}

			if (change.Company_Id__c == null) {
				setProcessingChange(IntegrationUtils.ERROR_STATE, 'Company Id: field value is missing in the record.', change);
				continue;
			}
			if (change.Benefits_Package_Id__c != null && change.Benefits_Package_Id__c != '') {
				benefitsPackageIDSet.add(change.Benefits_Package_Id__c);
			}
			companyIDSet.add(change.Company_Id__c);
			opportunityIdSet.add(change.External_Key__c);
			newPlanIDSet.add(change.Id__c);
		}

		map<String, List<HI_Aasm_Event__c>> asamEvents = getEventData(newPlanIDSet);
		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();

		if (companyIDSet.size() > 0) {
			map<string, map<String, Opportunity>> opportunityRecordMap = getOpportunityData(companyIDSet);
			map<string, Account> companyIdRecordMap = getCompanyData(companyIDSet);
			for (HI_Benefit_Change_Application__c hiChange : changeList) {
				if (hiChange.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}
				if (opportunityRecordMap.containsKey(hiChange.External_Key__c)) {
					continue;
				}
				map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
				if (opportunityRecordMap.containsKey(hiChange.Company_Id__c)) {
					opportunityMap = opportunityRecordMap.get(hiChange.Company_Id__c);
					if (opportunityMap.containsKey(hiChange.External_Key__c)) {
						Opportunity existingOpp = opportunityMap.get(hiChange.External_Key__c);
						if (
							existingOpp.IsClosed &&
							!existingOpp.IsWon &&
							(existingOpp.StageName == 'Order Lost' &&
							Utils.humanize(hiChange.Mapped_Status__c) != 'Dismissed') &&
							hiChange.Deleted_At__c == null &&
							existingOpp.Benefits_Current_Setup_Step__c != Utils.humanize(hiChange.Mapped_Status__c)
						) {
							existingOpp.Source_ID__c = null;
							existingOpp.ID__c = null;
							updateSourceIdOpportunityList.add(existingOpp);
						}
					} else if (opportunityMap.containsKey(hiChange.Company_Id__c)) {
						Opportunity existingOpp = opportunityMap.get(hiChange.Company_Id__c);
						if (existingOpp.IsWon == false && existingOpp.type != 'New TAdA Plan' && existingOpp.type != 'Transfer TAdA Plan') {
							existingOpp.Source_ID__c = hiChange.External_Key__c;
							updateSourceIdOpportunityList.add(existingOpp);
						}
					}
				}
			}
			if (updateSourceIdOpportunityList.size() > 0) {
				update updateSourceIdOpportunityList;
			}

			opportunityRecordMap = getOpportunityData(companyIDSet);

			for (HI_Benefit_Change_Application__c hiChange : changeList) {
				Opportunity toUpsertOpportunityRec = new Opportunity();
				Account toUpsertAccountRec = new Account();

				if (hiChange.Processing_State__c == IntegrationUtils.DEAD_STATE || hichange.Updated_At__c < (system.today() - 20)) {
					continue;
				}

				if (companyIdRecordMap.containsKey(hiChange.Company_Id__c)) {
					toUpsertAccountRec = companyIdRecordMap.get(hiChange.Company_Id__c);
				} else {
					setProcessingChange(IntegrationUtils.ERROR_STATE, 'Company record does not exit.', hiChange);
					continue;
				}
				map<String, Opportunity> opportunityMap = opportunityRecordMap.get(hiChange.Company_Id__c);

				toUpsertOpportunityRec = mapOpportunityFields(hiChange, toUpsertAccountRec, opportunityMap, asamEvents);
				toUpsertOpportunityList.add(toUpsertOpportunityRec);
			}

			if (toUpsertOpportunityList.size() > 0) {
				List<Database.UpsertResult> saveResult = database.upsert(toUpsertOpportunityList, Opportunity.Fields.Source_ID__c, false);
				dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, toUpsertOpportunityList, 'Source_ID__c', false, 'HIBenefitChangeApplicationTriggerHelper-processInformation');
			}
		}
		
		for (HI_Benefit_Change_Application__c hiChange : changeList) {
			if (string.isblank(hiChange.External_Key__c)) {
				setProcessingChange(IntegrationUtils.ERROR_STATE, 'Opportunity Id is missing in the record.', hiChange);
				continue;
			}

			if (dmlUpsertErrorsMap.containsKey(hiChange.External_Key__c)) {
				setProcessingChange(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(hiChange.External_Key__c), hiChange);
			} else if (hiChange.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingChange(IntegrationUtils.PROCESSED_STATE, 'Processed', hiChange);
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
						SELECT Id, Type, Source_Id__c, Id__c, Name, RecordTypeId, StageName, IsClosed, IsWon, Benefits_Current_Setup_Step__c, Users_Email__c
						FROM Opportunities
						WHERE RecordTypeId = :changeRecordTypeId
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
		map<string, Account> toReturnIdAccountRecMap = new Map<string, Account>();
		if (accountIdSet != null && accountIdSet.size() > 0) {
			for (Account accRec : [
				SELECT
					id,
					Name,
					ZP_Company_ID__c,
					Benefits_Employees__c,
					(SELECT Id, Expiration_Date__c FROM Policies__r WHERE Is_Selected__c = TRUE AND Benefit_Type__c = 'Medical' AND Expiration_Date__c > :System.today())
				FROM Account
				WHERE ZP_Company_ID__c IN :accountIdSet AND ZP_Company_ID__c != NULL
			]) {
				toReturnIdAccountRecMap.put(accRec.ZP_Company_ID__c, accRec);
			}
		}
		return toReturnIdAccountRecMap;
	}

	// populating HI_State_carrier__c object fields
	private HI_Benefit_Change_Application__c setProcessingChange(String ProcessingState, String message, HI_Benefit_Change_Application__c change) {
		change.Processing_State__c = ProcessingState;
		change.Message__c = message;
		if (ProcessingState == IntegrationUtils.PROCESSED_STATE) {
			change.Processed_At__c = System.now();
		}
		return change;
	}

	public static map<String, List<HI_Aasm_Event__c>> getEventData(Set<String> applicationIds) {
		map<String, List<HI_Aasm_Event__c>> asamEvents = new Map<String, List<HI_Aasm_Event__c>>();
		map<string, string> recordableIdWhoDunnitIdMap = new Map<string, string>();
		map<string, dateTime> recordableIdLatestCreatedDateMap = new Map<string, dateTime>();

		for (HI_Aasm_Event__c event : [
			SELECT Id, Created_At__c, Deleted_At__c, External_Key__c, From__c, Id__c, Paper_Trail_Whodunnit__c, Recordable_Id__c, Recordable_Type__c, To__c, Updated_At__c
			FROM HI_Aasm_Event__c
			WHERE Recordable_Type__c = 'BenefitChangeApplication' AND Recordable_Id__c IN :applicationIds
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

	public static Opportunity mapEventData(Opportunity tempOpp, String applicationId, map<String, List<HI_Aasm_Event__c>> asamEvents) {
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

				/*
                    BY: PR
                    At this point we are populating  Users_Email__c field of Opportunity, with the Email address of the 
                    latest WhoDunnit User, using static map "eventRecordableIdUserEmailMap" of this class
                    which we are populating in "populateEventRecordableIdUserEmailMap" method. 
                */
				if (tempOpp.Users_Email__c == null && eventRecordableIdUserEmailMap != null && eventRecordableIdUserEmailMap.containsKey(applicationId)) {
					//
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