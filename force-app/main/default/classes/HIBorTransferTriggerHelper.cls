public with sharing class HIBorTransferTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer counter = 0;
	public static Boolean queue = false;

	public static Id borTransferRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
	public static String BOR_Transfer = 'BoR Transfer';
	public static Map<String, String> eventRecordableIdUserEmailMap = new Map<String, String>();
	public static Map<String, String> setupStepMap = new Map<String, String>{
		'created' => '1',
		'benefits_selected' => '2',
		'carriers_selected' => '3',
		'additional_questions_answered' => '4',
		'forms_created' => '5',
		'forms_signed' => '6',
		'blocked' => '7'
	};

	public void OnBeforeInsert(List<HI_BoR_Transfer__c> borTransfers) {
		counter++;
		if (queue == true) {
			processInformation(borTransfers);
		} else {
			for (HI_BoR_Transfer__c borRec : borTransfers) {
				borRec.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, HI_BoR_Transfer__c> borTransferMap) {
		if (queue == false) {
			HIBorTransferQueue updateJob = new HIBorTransferQueue(borTransferMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public void OnBeforeUpdate(Map<ID, HI_BoR_Transfer__c> oldBorTransferMap, Map<ID, HI_BoR_Transfer__c> newBorTransferMap) {
		counter++;

		if (queue == true) {
			processInformation(newBorTransferMap.values());
		} else {
			for (HI_BoR_Transfer__c borRec : newBorTransferMap.values()) {
				borRec.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				if (oldBorTransferMap.containsKey(borRec.Id)) {
					borRec.Previous_Status__c = oldBorTransferMap.get(borRec.Id).Status__c;
				}
			}
		}
	}

	public void OnAfterUpdate(Map<ID, HI_BoR_Transfer__c> oldBorTransferMap, Map<ID, HI_BoR_Transfer__c> newBorTransferMap) {
		if (queue == false) {
			HIBorTransferQueue updateJob = new HIBorTransferQueue(newBorTransferMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedBorTransferIDs) {
	}

	public void OnBeforeDelete(HI_BoR_Transfer__c[] borTransferToDelete, Map<ID, HI_BoR_Transfer__c> oldBorTransferMap) {
		counter++;
	}

	public void OnAfterDelete(HI_BoR_Transfer__c[] deletedBorTransfers, Map<ID, HI_BoR_Transfer__c> oldBorTransferMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedBorTransferIDs) {
	}

	public void OnUndelete(HI_BoR_Transfer__c[] restoredBorTransfers) {
		counter++;
	}

	public Opportunity mapOpportunityFields(HI_BoR_Transfer__c hiBorTransfer, Account acc, map<string, Opportunity> opportunityMap, map<String, List<HI_Aasm_Event__c>> asamEvents) {
		Opportunity opp = new Opportunity();
		if (opportunityMap.containsKey(hiBorTransfer.External_Key__c) == false) {
			opp.StageName = 'Raw';
		}
		opp = mapEventData(opp, hiBorTransfer.Id__c, asamEvents);
		opp.RecordTypeId = borTransferRecordTypeId;
		opp.AccountId = acc.Id;
		opp.Source_ID__c = hiBorTransfer.External_Key__c;
		opp.Name = StringUtils.getOppName(acc.Name, 'Benefits BoR');
		opp.Id__c = 'HIBORTRANSFER' + hiBorTransfer.Id__c;
		opp.Initiated_BoR__c = true;
		if (opportunityMap.containsKey(hiBorTransfer.External_Key__c) == false) {
			opp.Medical_Renewal_Date__c = hiBorTransfer.Medical_Renewal_Month__c;
			opp.LeadSource = BOR_Transfer;
			opp.Dental_Renewal_Date__c = hiBorTransfer.Dental_Renewal_Month__c;
			opp.Vision_Renewal_Date__c = hiBorTransfer.Vision_Renewal_Month__c;
		} else {
			Opportunity existingOpp = opportunityMap.get(hiBorTransfer.External_Key__c);
			if (existingOpp.Medical_Renewal_Date__c == opp.Medical_Renewal_Date__c) {
				opp.Medical_Renewal_Date__c = hiBorTransfer.Medical_Renewal_Month__c;
			}
			if (existingOpp.Dental_Renewal_Date__c == opp.Dental_Renewal_Date__c) {
				opp.Dental_Renewal_Date__c = hiBorTransfer.Dental_Renewal_Month__c;
			}
			if (existingOpp.Vision_Renewal_Date__c == opp.Vision_Renewal_Date__c) {
				opp.Vision_Renewal_Date__c = hiBorTransfer.Vision_Renewal_Month__c;
			}
			if (existingOpp.LeadSource == null) {
				opp.LeadSource = BOR_Transfer;
			}
		}
		opp.Blocked_Reason__c = hiBorTransfer.Blocked_Reason__c;
		opp.Initiated_BoR_Timestamp__c = hiBorTransfer.Created_At__c;
		opp.Selecting_Benefits_Started_Timestamp__c = hiBorTransfer.Created_At__c;
		opp.Benefits_Current_Setup_Step__c = Utils.humanize(hiBorTransfer.Mapped_Status__c);
		if (hiBorTransfer.Benefit_Types__c != null && hiBorTransfer.Benefit_Types__c != '') {
			if (hiBorTransfer.Benefit_Types__c.IndexOf('"fsa"') > -1) {
				opp.Offers_FSA__c = true;
			} else {
				opp.Offers_FSA__c = false;
			}
		} else {
			opp.Offers_FSA__c = false;
		}
		if (setupStepMap.containsKey(hiBorTransfer.Status__c)) {
			opp.Benefits_Setup_Steps_Completed__c = setupStepMap.get(hiBorTransfer.Status__c);
		}
		opp.HI_BOR_App_Status__c = hiBorTransfer.Status__c;
		return opp;
	}

	private void processInformation(List<HI_BoR_Transfer__c> borTransferList) {
		Set<String> set_BoRTransferStatusUpdates = new Set<String>();
		set<string> borTransferIDSet = new Set<string>();
		set<string> companyIDSet = new Set<string>();
		set<string> opportunityIdSet = new Set<string>();
		map<String, HI_BoR_Transfer__c> hiBorTransferMap = new Map<String, HI_BoR_Transfer__c>();

		list<Opportunity> toUpsertOpportunityList = new List<Opportunity>();

		list<Opportunity> updateSourceIdOpportunityList = new List<Opportunity>();

		for (HI_BoR_Transfer__c borTransfer : borTransferList) {
			hiBorTransferMap.put(borTransfer.Id__c, borTransfer);
			if (borTransfer.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (borTransfer.External_Key__c == null) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'External Key: field value is missing in the record.', borTransfer);
				continue;
			}

			if (borTransfer.Company_Id__c == null) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Company Id: field value is missing in the record.', borTransfer);
				continue;
			}
			borTransfer.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			companyIDSet.add(borTransfer.Company_Id__c);
			opportunityIdSet.add(borTransfer.External_Key__c);
			borTransferIDSet.add(borTransfer.Id__c);

			if (borTransfer.Previous_Status__c != borTransfer.Status__c) {
				set_BoRTransferStatusUpdates.add(borTransfer.Id__c);
			}
		}

		Map<String, List<HI_Aasm_Event__c>> asamEvents = getEventData(borTransferIDSet);

		if (companyIDSet.size() > 0) {
			Map<String, Map<String, Opportunity>> opportunityRecordMap = getOpportunityData(companyIDSet);
			Map<String, Account> companyIdRecordMap = getCompanyData(companyIDSet);
			for (HI_BoR_Transfer__c borTransfer : borTransferList) {
				if (borTransfer.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}
				if (opportunityRecordMap.containsKey(borTransfer.External_Key__c)) {
					continue;
				}
				Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();

				if (opportunityRecordMap.containsKey(borTransfer.Company_Id__c)) {
					opportunityMap = opportunityRecordMap.get(borTransfer.Company_Id__c);
					if (opportunityMap.containsKey(borTransfer.External_Key__c)) {
						Opportunity existingOpp = opportunityMap.get(borTransfer.External_Key__c);
						String borStatus = (borTransfer.Status__c != null ? Utils.humanize(borTransfer.Status__c.replaceAll('_', ' ')) : borTransfer.Status__c);
						if (
							existingOpp.IsClosed &&
							!existingOpp.IsWon &&
							(existingOpp.StageName == 'Order Lost') &&
							borStatus != 'Cancelled' &&
							borStatus != 'cancelled' &&
							borTransfer.Deleted_At__c == null &&
							existingOpp.Benefits_Current_Setup_Step__c != borStatus
						) {
							existingOpp.Source_ID__c = null;
							existingOpp.ID__c = null;
							updateSourceIdOpportunityList.add(existingOpp);
						}
					} else if (opportunityMap.containsKey(borTransfer.Company_Id__c)) {
						Opportunity existingOpp = opportunityMap.get(borTransfer.Company_Id__c);
						if (existingOpp.IsWon == false) {
							existingOpp.Source_ID__c = borTransfer.External_Key__c;
							updateSourceIdOpportunityList.add(existingOpp);
						}
					}
				}
			}

			if (updateSourceIdOpportunityList.size() > 0) {
				// update updateSourceIdOpportunityList;
				// Added by Praveen to avoid Duplicates in Source Id Issue
				Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
				List<Database.SaveResult> saveResult = Database.update(updateSourceIdOpportunityList, false);
				dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, updateSourceIdOpportunityList, 'Source_ID__c', false, 'HIBorTransferTriggerHelper-processInformation');

				if (!dmlUpdateErrorsMap.isEmpty()) {
					for (HI_BoR_Transfer__c borTransfer : borTransferList) {
						if (!String.isNotBlank(borTransfer.External_Key__c)) {
							if (dmlUpdateErrorsMap.containsKey(borTransfer.External_Key__c)) {
								setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpdateErrorsMap.get(borTransfer.External_Key__c), borTransfer);
							}
						}
					}
				}
			}

			opportunityRecordMap = getOpportunityData(companyIDSet);

			for (HI_BoR_Transfer__c borTransfer : borTransferList) {
				Opportunity toUpsertOpportunityRec = new Opportunity();
				Account toUpsertAccountRec = new Account();

				if (borTransfer.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}

				if (companyIdRecordMap.containsKey(borTransfer.Company_Id__c)) {
					toUpsertAccountRec = companyIdRecordMap.get(borTransfer.Company_Id__c);
				} else {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Company record does not exit.', borTransfer);
					continue;
				}
				Map<String, Opportunity> opportunityMap = opportunityRecordMap.get(borTransfer.Company_Id__c);

				toUpsertOpportunityRec = mapOpportunityFields(borTransfer, toUpsertAccountRec, opportunityMap, asamEvents);
				toUpsertOpportunityList.add(toUpsertOpportunityRec);
			}

			Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
			if (toUpsertOpportunityList.size() > 0) {
				List<Database.UpsertResult> saveResult = database.upsert(toUpsertOpportunityList, Opportunity.Fields.Source_ID__c, false);
				dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, toUpsertOpportunityList, 'Source_ID__c', false, 'HIBorTransferTriggerHelper-processInformation');
				for (HI_BoR_Transfer__c borTransfer : borTransferList) {
					if (string.isblank(borTransfer.External_Key__c)) {
						setProcessingState(IntegrationUtils.ERROR_STATE, 'Opportunity Id is missing in the record.', borTransfer);
						continue;
					}

					if (dmlUpsertErrorsMap.containsKey(borTransfer.External_Key__c)) {
						setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(borTransfer.External_Key__c), borTransfer);
					} else if (borTransfer.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
						setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Processed', borTransfer);
					}
				}
			}
		}

		Set<String> set_ExcludeStage = new Set<String>{ 'Canceled', 'Closed Admin' };
		List<Benefit_Order__c> lstBTForUpdate = [
			SELECT
				Id,
				Application_Status__c,
				BoR_Id__c,
				(SELECT Id, Carrier__c,Carrier__r.Partner_Type__c, Benefit_Order__c, Implementation_Stage__c, TAdA__c FROM Carrier_Orders__r WHERE Implementation_Stage__c NOT IN :set_ExcludeStage)
			FROM Benefit_Order__c
			WHERE RecordType.Name = 'Benefits BoR' AND BoR_Id__c IN :set_BoRTransferStatusUpdates AND Opportunity__r.Id__c != NULL AND Opportunity__r.Id__c != '' AND Application_Status__c != 'Blocked'
		];

		if (lstBTForUpdate.size() > 0) {
			BenefitOrderHelperFunctions.updateBoRApplicationStatus(hiBorTransferMap, lstBTForUpdate);
			List<Carrier_Order__c> lst_COForUpdateWithoutSkipTrigger = new List<Carrier_Order__c>();
			Map<Id, String> map_BOApplicationStatus = new Map<Id, String>();
			Map<String, String> map_ApplicationStatusEffectBOAndCO = new Map<String, String>{
				'Pending Plan Confirmation' => 'Plan Review Sent',
				'Plans Confirmed' => 'Plans Confirmed',
				'Blocked Plan Confirmation' => 'Blocked Plan Review',
				'Pending Employee Details Confirmation' => 'Enrollment Review Sent',
				'Employee Details Confirmed' => 'Enrollment Confirmed',
				'BoR Complete' => 'Approved'
			};

			Set<Carrier_Order__c> set_AllCarrierOrders = new Set<Carrier_Order__c>();
			for (Benefit_Order__c objBO : lstBTForUpdate) {
				if (map_ApplicationStatusEffectBOAndCO.containsKey(objBO.Application_Status__c)) {
					map_BOApplicationStatus.put(objBO.Id, objBO.Application_Status__c);
					set_AllCarrierOrders.addAll(objBO.Carrier_Orders__r);
				}
			}

			if (!set_AllCarrierOrders.isEmpty()) {
				for (Carrier_Order__c objCO : set_AllCarrierOrders) {
					if (
						(objCO.Carrier__r.Partner_Type__c == '' || objCO.Carrier__r.Partner_Type__c != CarrierOrderUtil.PARTNER_TYPE_TADA) &&
						map_BOApplicationStatus.containsKey(objCO.Benefit_Order__c) &&
						map_ApplicationStatusEffectBOAndCO.containsKey(map_BOApplicationStatus.get(objCO.Benefit_Order__c))
					) {
						objCO.Implementation_Stage__c = map_ApplicationStatusEffectBOAndCO.get(map_BOApplicationStatus.get(objCO.Benefit_Order__c));
						lst_COForUpdateWithoutSkipTrigger.add(objCO);
					}
				}
			}
			if (!lst_COForUpdateWithoutSkipTrigger.isEmpty()) {
				Database.update(lst_COForUpdateWithoutSkipTrigger, false);
			}
			if (!lstBTForUpdate.isEmpty()) {
				//Skiping the benefit order trigger as we are not doing any thing on the Application status on BenefitOrderTrigger helper
				Boolean isSkipTrigger = BenefitOrderHelper.skipTrigger;
				BenefitOrderHelper.skipTrigger = true;
				List<Database.SaveResult> lstSaveData = Database.update(lstBTForUpdate, false);
				BenefitOrderHelper.skipTrigger = isSkipTrigger;
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
						SELECT
							Id,
							Source_Id__c,
							Id__c,
							Name,
							RecordTypeId,
							StageName,
							IsClosed,
							IsWon,
							Benefits_Current_Setup_Step__c,
							Users_Email__c,
							Medical_Renewal_Date__c,
							Dental_Renewal_Date__c,
							Vision_Renewal_Date__c,
							LeadSource
						FROM Opportunities
						WHERE RecordTypeId = :borTransferRecordTypeId
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
	private Map<String, Account> getCompanyData(Set<String> accountIdSet) {
		Map<String, Account> toReturnIdAccountRecMap = new Map<String, Account>();
		if (accountIdSet != null && accountIdSet.size() > 0) {
			for (Account accRec : [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :accountIdSet AND ZP_Company_ID__c != NULL]) {
				toReturnIdAccountRecMap.put(accRec.ZP_Company_ID__c, accRec);
			}
		}
		return toReturnIdAccountRecMap;
	}

	public static Map<String, List<HI_Aasm_Event__c>> getEventData(Set<String> applicationIds) {
		Map<String, List<HI_Aasm_Event__c>> asamEvents = new Map<String, List<HI_Aasm_Event__c>>();
		Map<String, String> recordableIdWhoDunnitIdMap = new Map<String, String>();
		Map<String, DateTime> recordableIdLatestCreatedDateMap = new Map<String, DateTime>();

		for (HI_Aasm_Event__c event : [
			SELECT Id, Created_At__c, Deleted_At__c, External_Key__c, From__c, Id__c, Paper_Trail_Whodunnit__c, Recordable_Id__c, Recordable_Type__c, To__c, Updated_At__c
			FROM HI_Aasm_Event__c
			WHERE Recordable_Type__c = 'BorTransfer' AND Recordable_Id__c IN :applicationIds
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
				if (tempOpp == null) {
					continue;
				}
				if (event.To__c == 'benefits_selected') {
					tempOpp.Selecting_Carriers_Started_Timestamp__c = event.created_at__c;
				}
				if (event.To__c == 'carriers_selected') {
					tempOpp.Additional_Info_Started_Timestamp__c = event.created_at__c;
				}
				if (event.To__c == 'forms_created') {
					tempOpp.Signing_Forms_Started_Timestamp__c = event.created_at__c;
				}
				if (event.To__c == 'forms_signed') {
					tempOpp.Signing_Forms_Completed_Timestamp__c = event.created_at__c;
				}
				if (event.To__c == 'blocked') {
					tempOpp.Last_Blocked_Timestamp__c = event.created_at__c;
				}
				if (setupStepMap.containsKey(event.To__c)) {
					tempOpp.Benefits_Setup_Last_Updated__c = event.created_at__c;
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
		eventRecordableIdUserEmailMap = new Map<string, string>();

		if (recordableIdWhoDunnitIdMap != null && recordableIdWhoDunnitIdMap.keyset().size() > 0) {
			set<string> tempWhoDunnitIdSet = new Set<string>();
			tempWhoDunnitIdSet.addAll(recordableIdWhoDunnitIdMap.values());
			set<string> nullSet = new Set<string>();
			nullSet.add(null);
			tempWhoDunnitIdSet.removeAll(nullSet);

			if (tempWhoDunnitIdSet.size() > 0) {
				for (ZP_User__c usr : [SELECT Id, Id__c, Email__c FROM Zp_user__c WHERE Id__c IN :tempWhoDunnitIdSet]) {
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

	// populating HI_BoR_Transfer__c object fields
	private HI_BoR_Transfer__c setProcessingState(String ProcessingState, String message, HI_BoR_Transfer__c botTransfer) {
		botTransfer.Processing_State__c = ProcessingState;
		botTransfer.Message__c = message;
		botTransfer.Processed_At__c = System.now();
		return botTransfer;
	}
}