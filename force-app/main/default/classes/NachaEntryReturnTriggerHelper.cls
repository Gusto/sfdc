public with sharing class NachaEntryReturnTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;
	map<string, Case> map_caseIdRecordToUpdate = new Map<string, Case>();

	public void OnBeforeInsert(List<Nacha_Entry_Return__c> nachaReturns) {
		counter++;
	}

	public void OnAfterInsert(Map<ID, Nacha_Entry_Return__c> newNachaReturnsMap) {
		rollUpAmountToCase(newNachaReturnsMap.values());
		//By: PR, Date:6/20/19, Desc: we want to call the method even if the passing list has no records.
		list<string> lst_CaseEligibleForClassAssignment = new List<string>();
		for (Nacha_Entry_Return__c rec : newNachaReturnsMap.values()) {
			if (rec.Case__c != null) {
				lst_CaseEligibleForClassAssignment.add(rec.Case__c);
			}
		}

		if (lst_CaseEligibleForClassAssignment.size() > 0) {
			calculateClassAndUpdateCase(lst_CaseEligibleForClassAssignment);
		}
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedNachaReturnsIDs) {
	}

	public void OnBeforeUpdate(Map<ID, Nacha_Entry_Return__c> oldNachaReturnsMap, Map<ID, Nacha_Entry_Return__c> newNachaReturnsMap) {
		counter++;
	}

	public void OnAfterUpdate(Map<ID, Nacha_Entry_Return__c> oldNachaReturnsMap, Map<ID, Nacha_Entry_Return__c> newNachaReturnsMap) {
		list<Nacha_Entry_Return__c> changedAmountRecords = new List<Nacha_Entry_Return__c>();
		list<string> lst_changedErrorCodes = new List<string>();

		for (Nacha_Entry_Return__c newRec : newNachaReturnsMap.values()) {
			Nacha_Entry_Return__c oldRec = oldNachaReturnsMap.get(newRec.id);

			if (newRec.Amount__c != oldRec.Amount__c) {
				changedAmountRecords.add(newRec);
			}

			if (
				(newRec.Error_Code__c != oldRec.Error_Code__c &&
				newRec.Error_Code__c != null) ||
				(newRec.Case__c != oldRec.Case__c &&
				newRec.Case__c != null) ||
				(newRec.Amount__c != oldRec.Amount__c &&
				newRec.Amount__c != null)
			) {
				lst_changedErrorCodes.add(newRec.Case__c);
			}
		}

		if (changedAmountRecords.size() > 0) {
			rollUpAmountToCase(changedAmountRecords);
		}

		//By: PR, Date:6/20/19, Desc: we want to call the method even if the passing list has no records.
		calculateClassAndUpdateCase(lst_changedErrorCodes);
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedNachaReturnsIDs) {
	}

	public void OnBeforeDelete(Nacha_Entry_Return__c[] nachaReturnsToDelete, Map<ID, Nacha_Entry_Return__c> oldNachaReturnsMap) {
		counter++;
	}

	public void OnAfterDelete(Nacha_Entry_Return__c[] deletedNachaReturns, Map<ID, Nacha_Entry_Return__c> oldNachaReturnsMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedNachaReturnsIDs) {
	}

	public void OnUndelete(Nacha_Entry_Return__c[] restoredNachaReturns) {
		counter++;
	}

	/*  
        This method is called from AfterInsert and AfterUpdate trigger instances
        This method is accepting List of "Nacha Entry Return" record list as parameter
        In this method we are rolling up the amount to case based on matching "Event Id" to "Integration Key"
        But we are rolling up to cases where Recovery_Case_ID__c = null
    */
	public void rollUpAmountToCase(list<Nacha_Entry_Return__c> nachaRecords) {
		if (nachaRecords != null && nachaRecords.size() > 0) {
			map<string, decimal> caseIdTotalAmtMap = new Map<string, decimal>();
			list<case> toUpdateCaseList = new List<case>();

			updateFirstTimeNacha(nachaRecords);

			for (Nacha_Entry_Return__c rec : nachaRecords) {
				caseIdTotalAmtMap.put(rec.Case__c, 0);
			}

			for (Nacha_Entry_Return__c rec : [
				SELECT id, Event_Id__c, Amount__c, Case__c
				FROM Nacha_Entry_Return__c
				WHERE Case__c IN :caseIdTotalAmtMap.keyset() AND First_Debit_Failure_Nacha__c = FALSE
			]) {
				decimal amt = (rec.Amount__c != null ? rec.Amount__c : 0) + caseIdTotalAmtMap.get(rec.Case__c);
				caseIdTotalAmtMap.put(rec.Case__c, amt);
			}

			map<id, Case> caseIdRecMap = new Map<id, case>();

			set<id> caseAlreadyProcessed = new Set<id>();
			for (Case caseRec : [
				SELECT id, Initial_Recovery_Amount__c, Recovery_Case_ID__c, Bank_error_code__c, Expedite_Reason__c, Class__c, OwnerId, Event_Type__c
				FROM Case
				WHERE id IN :caseIdTotalAmtMap.keyset() AND Recovery_Case_ID__c = NULL
			]) {
				caseRec.Initial_Recovery_Amount__c = caseIdTotalAmtMap.get(caseRec.id);

				map_caseIdRecordToUpdate.put(caseRec.id, caseRec);
			}
		}
	}

	public void updateFirstTimeNacha(list<Nacha_Entry_Return__c> nachaList) {
		map<string, string> map_eventIdCaseId = new Map<string, string>();
		list<Nacha_Entry_Return__c> lst_toUpdateNacha = new List<Nacha_Entry_Return__c>();
		if (nachaList != null && nachaList.size() > 0) {
			for (Nacha_Entry_Return__c reC : nachaList) {
				if (rec.Event_id__c != null && rec.Case__c != null) {
					map_eventIdCaseId.put(rec.Event_id__c, rec.Case__c);
				}
			}

			if (map_eventIdCaseId.keyset().size() > 0) {
				for (Nacha_Entry_Return__c nachaObj : [SELECT id, Case__c, Event_Id__c FROM Nacha_Entry_Return__c WHERE Event_id__c IN :map_eventIdCaseId.keyset() AND Case__c = NULL]) {
					if (map_eventIdCaseId.containsKey(nachaObj.Event_Id__c)) {
						nachaObj.Case__c = map_eventIdCaseId.get(nachaObj.Event_Id__c);
						lst_toUpdateNacha.add(nachaObj);
					}
				}

				if (lst_toUpdateNacha.size() > 0) {
					try {
						NachaEntryReturnTriggerHelper.SkipTrigger = true;
						update lst_toUpdateNacha;
						NachaEntryReturnTriggerHelper.SkipTrigger = false;
					} catch (exception ex) {
					}
				}
			}
		}
	}

	//BY:PR, Date:6/20/19, Desc:
	public void calculateClassAndUpdateCase(list<string> lst_caseId) {
		if (lst_caseId != null && lst_caseId.size() > 0) {
			for (Case objCase : [SELECT id, Bank_error_code__c, Initial_Recovery_Amount__c, Class__c, Expedite_Reason__c, ownerId, Event_Type__c FROM Case WHERE id IN :lst_caseId]) {
				if (!map_caseIdRecordToUpdate.containsKey(objCase.id)) {
					map_caseIdRecordToUpdate.put(objCase.id, objCase);
				}
			}
		}

		if (map_caseIdRecordToUpdate.keySet().size() > 0) {
			//Alex: assign cases to Recovery Faster Contractor Payments queue instead of assignment logic if event type = contractor payment
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Group grpContractorPayments = [SELECT Id FROM Group WHERE Name = 'Recovery Faster Contractor Payments'];

			for (case objCase : map_caseIdRecordToUpdate.values()) {
				objCase.Class__c = getCorrectClassValue(objCase);
				if (objCase.OwnerId != null && string.valueof(objCase.OwnerId).indexOf('00G') == 0) {
					if (grpContractorPayments != null && objCase.Event_Type__c == 'ContractorPayment') {
						objCase.OwnerId = grpContractorPayments.Id;
					} else {
						objCase.setOptions(dmo);
					}
				}
			}

			try {
				CaseTriggerHelper.skipTrigger = true;
				update map_caseIdRecordToUpdate.values();
				CaseTriggerHelper.skipTrigger = false;
			} catch (exception ex) {
				ExceptionLogUtil.logException('NachaEntryReturnTriggerHelper', 'calculateClassAndUpdateCase', ex.getMessage(), ex.getStackTraceString());
			}
		}
	}

	// custom setting list used to contain records for the logic implementation
	list<Recovery_Case_Class_Assignment_Setting__c> list_classAssigment;

	/*
        BY: PR, Date: 5/30/19, Description: In below method we are trying to find appropriate case's "Class" field value based on custom setting record.
    */
	public string getCorrectClassValue(Case objRecoveryCases) {
		if (objRecoveryCases != null && string.isNotBlank(objRecoveryCases.Bank_Error_Code__c) && objRecoveryCases.Initial_Recovery_Amount__c != null) {
			if (list_classAssigment == null) {
				list_classAssigment = new List<Recovery_Case_Class_Assignment_Setting__c>();
				list_classAssigment = Recovery_Case_Class_Assignment_Setting__c.getAll().values();
			}

			for (Recovery_Case_Class_Assignment_Setting__c settingRec : list_classAssigment) {
				set<string> set_settingErrorCodes = new Set<string>();
				set<string> set_caseBankErrorCodes = new Set<string>();

				if (string.isBlank(settingRec.Error_Code__c)) {
					continue;
				}

				set_settingErrorCodes.addAll(settingRec.Error_Code__c.trim().replaceAll(' ', '').split(','));
				set_caseBankErrorCodes.addAll(objRecoveryCases.Bank_Error_Code__c.trim().split(','));

				//if setting's expedite reason != null, continue with index of case's expedite reason
				//if setting's expedite reason == null, don't search case's expedite reason
				if (
					objRecoveryCases.Initial_Recovery_Amount__c != null &&
					settingRec.Error_Code__c != null &&
					set_settingErrorCodes.containsAll(set_caseBankErrorCodes) &&
					objRecoveryCases.Initial_Recovery_Amount__c >= settingRec.Recovery_Amount_Starting_Limit__c &&
					(settingRec.Expedite_Reason__c == null || (objRecoveryCases.Expedite_Reason__c != null && settingRec.Expedite_Reason__c.IndexOf(objRecoveryCases.Expedite_Reason__c) > -1))
				) {
					if (settingRec.Recovery_Amount_End_Limit__c == 0) {
						return settingRec.Eligible_Class__c;
					} else if (objRecoveryCases.Initial_Recovery_Amount__c <= settingRec.Recovery_Amount_End_Limit__c) {
						return settingRec.Eligible_Class__c;
					}
				}
			}
		}

		return null;
	}
}