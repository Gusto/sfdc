/*
    By: PR
    Date: Jan 6,2020
    Description: 
*/
public with sharing class HIHealthPolicyDetailTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	public static boolean queue = false;

	public HIHealthPolicyDetailTriggerHelper() {
	}

	public void OnBeforeInsert(List<HI_Health_Policy_Detail__c> states) {
		counter++;
		if (queue == true) {
			processInformation(states);
		} else {
			for (HI_Health_Policy_Detail__c state : states) {
				state.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, HI_Health_Policy_Detail__c> newStateMap) {
		if (queue == false) {
			//HIHealthPolicyDetailQueue updateJob = new HIHealthPolicyDetailQueue(newStateMap.values());
			//ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedCompanyIDs) {
	}

	public void OnBeforeUpdate(Map<ID, HI_Health_Policy_Detail__c> oldStateMap, Map<ID, HI_Health_Policy_Detail__c> newStateMap) {
		counter++;
		if (queue == true) {
			processInformation(newStateMap.values());
		} else {
			for (HI_Health_Policy_Detail__c state : newStateMap.values()) {
				state.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, HI_Health_Policy_Detail__c> oldStateMap, Map<ID, HI_Health_Policy_Detail__c> newStateMap) {
		if (queue == false) {
			//HIHealthPolicyDetailQueue updateJob = new HIHealthPolicyDetailQueue(newStateMap.values());
			//ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedCompantIDs) {
	}

	public void OnBeforeDelete(HI_Health_Policy_Detail__c[] companytToDelete, Map<ID, HI_Health_Policy_Detail__c> oldCompanyMap) {
		counter++;
	}

	public void OnAfterDelete(HI_Health_Policy_Detail__c[] deletedCompanys, Map<ID, HI_Health_Policy_Detail__c> oldCompanyMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedCompanyIDs) {
	}

	public void OnUndelete(HI_Health_Policy_Detail__c[] restoredCompanys) {
		counter++;
	}

	public void processInformation(List<HI_Health_Policy_Detail__c> lst_healthPolicys) {
		map<string, HI_Health_Policy_Detail__c> map_PolicyIdPolicyRecord = new Map<String, HI_Health_Policy_Detail__c>();

		if (lst_healthPolicys != null && lst_healthPolicys.size() > 0) {
			for (HI_Health_Policy_Detail__c obj_policyRec : lst_healthPolicys) {
				map_PolicyIdPolicyRecord.put(obj_policyRec.Id__c, obj_policyRec);
			}

			updateGroupNumberOnPolicy(map_PolicyIdPolicyRecord);
		}
	}

	//By: PR, Date:Jan 6,2020, Desc: following method is syncing GroupNumber field value between "hi health Policy detail" and relatec "Hi Policy" record
	public void updateGroupNumberOnPolicy(map<string, HI_Health_Policy_Detail__c> map_PolicyIdPolicyRecord) {
		list<HI_Policy__c> lst_toUpdatePolicyRecords = new List<HI_Policy__c>();

		if (map_PolicyIdPolicyRecord != null && map_PolicyIdPolicyRecord.size() > 0) {
			for (HI_Policy__c obj_policy : [
				SELECT Id, Group_Number__c, policy_number__c, Policy_Detail_Id__c
				FROM HI_Policy__c
				WHERE
					Policy_Detail_Type__c = 'HealthPolicyDetail'
					AND Policy_Detail_Id__c != NULL
					AND Policy_Detail_Id__c IN :map_PolicyIdPolicyRecord.Keyset()
					AND (Group_Number__c = NULL
					OR policy_number__c = NULL)
			]) {
				if (map_PolicyIdPolicyRecord.containsKey(obj_policy.Policy_Detail_Id__c)) {
					if (obj_policy.Group_Number__c == null){
						obj_policy.Group_Number__c = map_PolicyIdPolicyRecord.get(obj_policy.Policy_Detail_Id__c).Group_Number__c;
                    }

					if (obj_policy.policy_number__c == null) {
						obj_policy.policy_number__c = map_PolicyIdPolicyRecord.get(obj_policy.Policy_Detail_Id__c).policy_number__c;
                    }

					lst_toUpdatePolicyRecords.add(obj_policy);
				}
			}

			Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
			if (lst_toUpdatePolicyRecords.size() > 0) {
				List<Database.SaveResult> saveResult = database.update(lst_toUpdatePolicyRecords, false);
				dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, lst_toUpdatePolicyRecords, 'Policy_Detail_Id__c', true, 'HIHealthPolicyDetailTriggerHelper-updateGroupNumberOnPolicy');
			}

			for (HI_Health_Policy_Detail__c hiPolicyDetail : map_PolicyIdPolicyRecord.Values()) {
				if (dmlUpdateErrorsMap.containsKey(hiPolicyDetail.Id__c)) {
					setProcessingPolicy(IntegrationUtils.ERROR_STATE, dmlUpdateErrorsMap.get(hiPolicyDetail.Id__c), hiPolicyDetail);
				} else {
					setProcessingPolicy(IntegrationUtils.PROCESSED_STATE, 'Processed', hiPolicyDetail);
				}
			}
		}
	}

	// populating HI_Health_Policy_Detail__c object fields
	private HI_Health_Policy_Detail__c setProcessingPolicy(String ProcessingState, String message, HI_Health_Policy_Detail__c hiPolicy) {
		hiPolicy.Processing_State__c = ProcessingState;
		hiPolicy.Message__c = message.left(250);
		hiPolicy.Last_Processed__c = System.now();
		return hiPolicy;
	}
}