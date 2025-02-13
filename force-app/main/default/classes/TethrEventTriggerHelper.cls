/**
 * The TethrEventTriggerHelper class is responsible for processing Tethr events
 * and creating Benefits BoR Opportunities based on the events.
 * Test class: TethrEventTriggerHelperTest
 */
public without sharing class TethrEventTriggerHelper {
	// Constants for the Benefits BoR Opportunity Record Type ID and Lead Source
	public final static Id BENEFITS_BOR_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
	public final static Id BENEFITS_NEW_PLAN_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
	public final static Id BENEFITS_BYOB_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits BYOB');

	public final static String LEAD_SOURCE_TEHR = 'Tethr-BOR';
	public final static String PARTNER_BOR_OPP_EVT = 'Automated BoR Opportunities';

	// Sets to hold interaction IDs and accounts with Benefits BoR Opportunities
	public Set<String> set_InteractionIds = new Set<String>();
	public Set<Id> set_AccountsWithBoROpps = new Set<Id>();

	// Maps to hold task interactions, accounts, and Tethr calls
	Map<String, Task> map_TaskInteractions = new Map<String, Task>();
	Map<String, Account> map_Accounts = new Map<String, Account>();
	Map<Id, Tethr__Tethr_Call__c> map_TethrCalls = new Map<Id, Tethr__Tethr_Call__c>();

	// Maps to hold Opportunities to be inserted and Tethr calls to be updated
	Map<Id, Opportunity> map_OppsToInsert = new Map<Id, Opportunity>();
	Map<Id, Tethr__Tethr_Call__c> map_TethrCallsToUpdate = new Map<Id, Tethr__Tethr_Call__c>();

	/**
	 * Processes the after insert context for Tethr events.
	 *
	 * @param map_NewEvents Map of new Tethr events
	 */
	public void processAfterInsert(Map<Id, Tethr__Tethr_Event__c> map_NewEvents) {
		// Set data collections based on the new events
		setDataCollections(map_NewEvents);

		// Create Benefits BoR Opportunities for each event
		for (Tethr__Tethr_Event__c objEvent : map_NewEvents.values()) {
			if (objEvent.Name == PARTNER_BOR_OPP_EVT) {
				// Create Benefits Opportunity only for Partner BoR events
				createBenefitsBoROpportunity(objEvent);
			}
		}

		// Insert the Opportunities if there are any to insert
		if (!map_OppsToInsert.isEmpty()) {
			insert map_OppsToInsert.values();

			// Update Tethr calls with the newly created Opportunity IDs
			for (Id idCall : map_OppsToInsert.keySet()) {
				if (map_TethrCallsToUpdate.containsKey(idCall)) {
					map_TethrCallsToUpdate.get(idCall).Tethr__Opportunity__c = map_OppsToInsert.get(idCall).Id;
				} else {
					map_TethrCallsToUpdate.put(idCall, new Tethr__Tethr_Call__c(Id = idCall, Tethr__Opportunity__c = map_OppsToInsert.get(idCall).Id));
				}
			}
		}

		// Update the Tethr calls if there are any to update
		if (!map_TethrCallsToUpdate.isEmpty()) {
			update map_TethrCallsToUpdate.values();
		}
	}

	/**
	 * Sets data collections based on the new Tethr events.
	 *
	 * @param map_NewEvents Map of new Tethr events
	 */
	public void setDataCollections(Map<Id, Tethr__Tethr_Event__c> map_NewEvents) {
		Set<Id> set_AccountIds = new Set<Id>();
		Set<Id> set_TethrCallIds = new Set<Id>();

		// Gather data from the new events
		for (Tethr__Tethr_Event__c objEvent : map_NewEvents.values()) {
			if (String.isNotBlank(objEvent.Contact_ID__c)) {
				set_InteractionIds.add(objEvent.Contact_ID__c);
			}

			if (objEvent.Tethr__Call__c != null) {
				set_TethrCallIds.add(objEvent.Tethr__Call__c);
			}
		}

		// Query tasks based on interaction IDs and populate task interactions map
		if (!set_InteractionIds.isEmpty()) {
			for (Task objTask : [
				SELECT Id, AccountId, Genesys_Interaction_Id__c, CreatedById, What.Type, WhatId, WhoId, Who.Type
				FROM Task
				WHERE Genesys_Interaction_Id__c IN :set_InteractionIds
				ORDER BY CreatedDate ASC
			]) {
				map_TaskInteractions.put(objTask.Genesys_Interaction_Id__c, objTask);

				if (objTask.AccountId != null) {
					set_AccountIds.add(objTask.AccountId);
				}
			}
		}

		// Query Tethr calls based on call IDs and populate Tethr calls map
		if (!set_TethrCallIds.isEmpty()) {
			for (Tethr__Tethr_Call__c objCall : [SELECT Id, Tethr__Account__c, Tethr__Case__c, Tethr__Opportunity__c, Tethr__Lead__c FROM Tethr__Tethr_Call__c WHERE Id IN :set_TethrCallIds]) {
				map_TethrCalls.put(objCall.Id, objCall);
			}
		}

		// Query accounts based on account IDs and populate accounts map
		if (!set_AccountIds.isEmpty()) {
			for (Account objAcc : [SELECT Id, BillingState, BillingStateCode, (SELECT Id, RecordTypeId, IsClosed FROM Opportunities) FROM Account WHERE Id IN :set_AccountIds]) {
				map_Accounts.put(objAcc.Id, objAcc);
			}
		}
	}

	/**
	 * Creates Benefits BoR Opportunities based on the Tethr event.
	 *
	 * @param objEvent The Tethr event
	 */
	public void createBenefitsBoROpportunity(Tethr__Tethr_Event__c objEvent) {
		Task objTask = map_TaskInteractions.get(objEvent.Contact_ID__c);

		// Check if the task and account exist and if the account does not already have a Benefits BoR Opportunity
		if (objTask != null && objTask.AccountId != null && map_Accounts.containsKey(objTask.AccountId) && !set_AccountsWithBoROpps.contains(objTask.AccountId)) {
			Account objAcc = map_Accounts.get(objTask.AccountId);
			Boolean blnOpenBoRFound = false;
			Boolean blnSupportedState = false;

			// Check if the account's billing state is supported
			if (String.isNotBlank(objAcc.BillingState)) {
				State_Name_to_abbreviations_Mapping__c objStateMapping = State_Name_to_abbreviations_Mapping__c.getInstance(objAcc.BillingState);
				if (objStateMapping != null) {
					blnSupportedState = objStateMapping.HI_Active__c;
				}
			}

			// Check if there is an open Benefits BoR Opportunity for the account
			for (Opportunity objOpp : objAcc.Opportunities) {
				if (
					(objOpp.RecordTypeId == BENEFITS_BOR_OPPTY_RT_ID || objOpp.RecordTypeId == BENEFITS_NEW_PLAN_OPPTY_RT_ID || objOpp.RecordTypeId == BENEFITS_BYOB_OPPTY_RT_ID) &&
					objOpp.IsClosed == false
				) {
					blnOpenBoRFound = true;
					break;
				}
			}

			// Logic to set HI Lead Pass fields
			Id idLeadPassUser = null;
			String strLeadPassRole = '';

			String strUserRoleName = UserUtils.getUserRoleName(objTask.CreatedById);
			List<String> list_HIRoles = OpportunityUtil.HI_SALES_CS_ROLES.split(',');

			if (list_HIRoles.contains(strUserRoleName)) {
				idLeadPassUser = objTask.CreatedById;
				strLeadPassRole = strUserRoleName;
			}

			// If no open Benefits BoR Opportunity is found and the state is supported, create a new one
			if (blnOpenBoRFound == false && blnSupportedState == true) {
				map_OppsToInsert.put(
					objEvent.Tethr__Call__c,
					new Opportunity(
						AccountId = objAcc.Id,
						LeadSource = LEAD_SOURCE_TEHR,
						RecordTypeId = BENEFITS_BOR_OPPTY_RT_ID,
						Sent_to_Gusto_User__c = idLeadPassUser,
						HI_Lead_Pass_Role__c = strLeadPassRole
					)
				);
				set_AccountsWithBoROpps.add(objAcc.Id);
			}
		}
	}
}