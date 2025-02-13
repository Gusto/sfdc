/*
 *   By : Pravesh Rana
 *   Created Date : 06-05-2017
 *
 */
public with sharing class HIStateTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	public static boolean queue = false;

	public HIStateTriggerHelper() {
	}

	public void OnBeforeInsert(List<HI_State__c> states) {
		counter++;
		processInformation(states);
	}

	public void OnBeforeUpdate(Map<ID, HI_State__c> oldStateMap, Map<ID, HI_State__c> newStateMap) {
		counter++;
		processInformation(newStateMap.values());
	}

	// maping all the related fields
	private State__c mapStateFields(HI_State__c hiState, State__c toUpdateStateRec, map<string, State__c> stateIdRecordMap) {
		if (stateIdRecordMap != null && stateIdRecordMap.keyset().size() > 0 && stateIdRecordMap.containsKey(hiState.Id__c)) {
			toUpdateStateRec = stateIdRecordMap.get(hiState.Id__c);
		}

		if (toUpdateStateRec.Id__c == null) {
			toUpdateStateRec.Id__c = hiState.Id__c;
		}

		toUpdateStateRec.Abbreviation__c = hiState.Key__c;
		toUpdateStateRec.Key__c = hiState.Key__c;
		toUpdateStateRec.Name = hiState.Name__c;

		return toUpdateStateRec;
	}

	private void processInformation(List<HI_State__c> stateList) {
		Set<String> hiStateIDSet = new Set<String>();
		List<State__c> toUpsertStateList = new List<State__c>();

		for (HI_State__c state : stateList) {
			if (state.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			state.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
			state.Message__c = '';

			if (state.Id__c == null) {
				continue;
			}
			hiStateIDSet.add(state.Id__c);
		}

		// if External Id set contains some value
		if (hiStateIDSet.size() > 0) {
			map<string, State__c> stateIdRecordMap = getStateData(hiStateIDSet);

			for (HI_State__c hiState : stateList) {
				if (hiState.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}

				State__c toUpdateStateRec = new State__c();
				toUpdateStateRec = mapStateFields(hiState, toUpdateStateRec, stateIdRecordMap);
				toUpsertStateList.add(toUpdateStateRec);
			}

			Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
			if (toUpsertStateList.size() > 0) {
				List<Database.UpsertResult> saveResult = database.upsert(toUpsertStateList, State__c.Fields.Id__c, false);
				dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, toUpsertStateList, 'Id__c', true, 'HIStateTriggerHelper-processInformation');

				if (dmlUpsertErrorsMap.keySet().size() > 0) {
					for (HI_State__c hiState : stateList) {
						if (string.isblank(hiState.ID__c)) {
							setProcessingState(IntegrationUtils.ERROR_STATE, 'State Id is missing in the record.', hiState);
							continue;
						}

						if (dmlUpsertErrorsMap.containsKey(hiState.ID__c)) {
							setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(hiState.ID__c), hiState);
						}
					}
				}
			}
		}
	}

	// querying State object records present in the org using ID__c field
	private Map<String, State__c> getStateData(Set<String> stateIdSet) {
		Map<String, State__c> toReturnIdStateRecMap = new Map<String, State__c>();

		if (stateIdSet != null && stateIdSet.size() > 0) {
			for (State__c state : [SELECT Id, Id__c, Abbreviation__c, Key__c, Name FROM State__c WHERE Id__c IN :stateIdSet AND Id__c != NULL]) {
				toReturnIdStateRecMap.put(state.Id__c, state);
			}
		}

		return toReturnIdStateRecMap;
	}

	// populating HI_State__c object fields
	public HI_State__c setProcessingState(String ProcessingState, String message, HI_State__c state) {
		state.Processing_State__c = ProcessingState;
		state.Message__c = message;
		state.Last_Processed__c = System.now();
		return state;
	}
}