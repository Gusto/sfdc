/**
 * The TethrCallTriggerHelper handles business logic - Links Tethr Calls to Accounts and Opportunities.
 * Test class: TethrEventTriggerHelperTest
 */
public without sharing class TethrCallTriggerHelper {
	// Maps to hold task interactions, accounts
	Map<String, Task> map_TaskInteractions = new Map<String, Task>();

	/**
	 * Runs before insert logic.
	 *
	 * @param list_NewCalls List of new calls
	 */
	public void processBeforeInsert(List<Tethr__Tethr_Call__c> list_NewCalls) {
		setDataCollections(list_NewCalls);

		for (Tethr__Tethr_Call__c objCall : list_NewCalls) {
			if (String.isNotBlank(objCall.Tethr__Master_Id__c)) {
				setDefaultsFromTask(objCall);
			}
		}
	}

	/**
	 * Sets data collections based on the new Tethr calls.
	 *
	 * @param map_NewEvents List of new calls
	 */
	public void setDataCollections(List<Tethr__Tethr_Call__c> list_NewCalls) {
		Set<String> set_MasterIds = new Set<String>();

		// Gather data from the new calls
		for (Tethr__Tethr_Call__c objCall : list_NewCalls) {
			if (String.isNotBlank(objCall.Tethr__Master_Id__c)) {
				set_MasterIds.add(objCall.Tethr__Master_Id__c);
			}
		}

		// Query tasks based on interaction IDs and populate task interactions map
		if (!set_MasterIds.isEmpty()) {
			for (Task objTask : [
				SELECT Id, AccountId, Genesys_Interaction_Id__c, CreatedById, What.Type, WhatId, WhoId, Who.Type
				FROM Task
				WHERE Genesys_Interaction_Id__c IN :set_MasterIds
				ORDER BY CreatedDate ASC
			]) {
				map_TaskInteractions.put(objTask.Genesys_Interaction_Id__c, objTask);
			}
		}
	}

	/**
	 * Links tethr calls to accounts and opportunities based on the task.
	 *
	 * @param objCall Each call recor
	 */
	public void setDefaultsFromTask(Tethr__Tethr_Call__c objCall) {
		Task objTask = map_TaskInteractions.get(objCall.Tethr__Master_Id__c);

		if (objTask != null) {
			// Link Tethr Call to Account
			if (objTask.AccountId != null) {
				objCall.Tethr__Account__c = objTask.AccountId;
			}

			// Update the Tethr call with the task's WhatId if it is an Opportunity, or Case
			if (objTask.WhatId != null) {
				if (objTask.What.Type == 'Opportunity') {
					objCall.Tethr__Opportunity__c = objTask.WhatId;
				} else if (objTask.What.Type == 'Case') {
					objCall.Tethr__Case__c = objTask.WhatId;
				}
			}
		}
	}
}