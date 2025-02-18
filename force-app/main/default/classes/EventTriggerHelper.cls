public without sharing class EventTriggerHelper extends TriggerHandler {
	public static Boolean skipTrigger = false;

	/*** All set variables ***/
	public Set<Id> set_AccountIds;
	public Set<Id> set_OpportunityIds;
	public Set<Id> set_LeadIds;

	/*** All Map Variables ***/
	public Map<Id, Account> map_Accounts;
	public Map<Id, Opportunity> map_Opportunities;
	public Map<Id, Lead> map_Leads;
	public static Map<Id, Account> map_AccountsToUpdate;
	public static Map<Id, Opportunity> map_OpportunitiesToUpdate;
	public static Map<Id, Lead> map_LeadsToUpdate;

	Map<Id, Event> map_LeadIdToEvent;

	public EventTriggerHelper() {
		super('EventTriggerHelper');

		/*** All set variables ***/
		set_AccountIds = new Set<Id>();
		set_OpportunityIds = new Set<Id>();
		set_LeadIds = new Set<Id>();

		/*** All Map variables ***/
		map_Accounts = new Map<Id, Account>();
		map_AccountsToUpdate = new Map<Id, Account>();
		map_Opportunities = new Map<Id, Opportunity>();
		map_OpportunitiesToUpdate = new Map<Id, Opportunity>();
		map_Leads = new Map<Id, Lead>();
		map_LeadsToUpdate = new Map<Id, Lead>();
		map_LeadIdToEvent = new Map<Id, Event>();
	}

	public override void beforeInsert() {
		List<Event> list_newEvents = (List<Event>) Trigger.new;
		updateEventRecordType(list_newEvents);
		chilliPipperEventUtility(list_newEvents);
		updateEventType(list_newEvents);
		setRelatedTicketStatusForEvent(list_newEvents);
		updateClosedOwnerRole(list_newEvents, null);
		Set<Id> set_LeadId = getLeads(list_newEvents);
		if (set_LeadId.size() > 0) {
			changeLeadOwner(set_LeadId);
		}
	}

	public override void afterInsert() {
		List<Event> list_newEvents = (List<Event>) Trigger.new;
		setCollectionsAfter(list_newEvents);

		//BY:Prashant :24-june-2020 :https://app.asana.com/0/1165890935117693/1174138650528440
		populateActivityDatesOnAccLead(list_newEvents);
		populateLastActivityDateOnTicket(list_newEvents);
		updateLastCallConnectDetails(list_newEvents);
		processDMLOperation(false);
	}

	public override void beforeUpdate() {
		List<Event> list_newEvents = (List<Event>) Trigger.new;
		Map<Id, Event> map_oldEvents = (Map<Id, Event>) Trigger.oldMap;

		updateEventType(list_newEvents);
		updateEventNoShow(list_newEvents, map_oldEvents);
		updateClosedOwnerRole(list_newEvents, map_oldEvents);
	}

	public override void afterUpdate() {
		List<Event> list_newEvents = (List<Event>) Trigger.new;
		setCollectionsAfter(list_newEvents);
		populateLastActivityDateOnTicket(list_newEvents);
		updateLastCallConnectDetails(list_newEvents);
		processDMLOperation(false);
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Queries data and creates collections required for after context
	 * @Parm        : list_Events
	 * @Return      : N/A
	 **/
	public void setCollectionsAfter(List<Event> list_Events) {
		for (Event objEvent : list_Events) {
			if (objEvent.WhatId != null && checkIfWhatIsAccount(objEvent)) {
				set_AccountIds.add(objEvent.WhatId);
			}

			if (objEvent.WhatId == null && objEvent.WhoId != null && checkIfWhoIsContact(objEvent) && objEvent.AccountId != null) {
				set_AccountIds.add(objEvent.AccountId);
			}

			if (objEvent.WhatId != null && checkIfWhatIsOpportunity(objEvent)) {
				set_OpportunityIds.add(objEvent.WhatId);
			}

			if (objEvent.WhoId != null && checkIfWhoIsLead(objEvent)) {
				set_LeadIds.add(objEvent.WhoId);
			}

			if (!set_AccountIds.isEmpty()) {
				map_Accounts = queryAccounts(set_AccountIds);
			}

			if (!set_OpportunityIds.isEmpty()) {
				map_Opportunities = queryOpportunities(set_OpportunityIds);
			}

			if (!set_LeadIds.isEmpty()) {
				map_Leads = queryLeads(set_LeadIds);
			}
		}
	}

	private Set<Id> getLeads(List<Event> list_Events) {
		//To convert lead on event creation by ChiliPiper on Lead
		Set<Id> set_LeadId = new Set<Id>();
		String strLeadPrefix = Schema.SObjectType.Lead.getKeyPrefix();

		for (Event objEvent : list_Events) {
			String strWhoId = objEvent.WhoId;
			// If event is "AE Demo" and whiId is not null and created on Lead
			if (
				strWhoId != null &&
				objEvent.RecordTypeId == EventUtil.AE_DEMO_EVENT_RT_ID &&
				strWhoId.startsWith(strLeadPrefix) &&
				objEvent.Queue_Name_CP__c != null &&
				objEvent.Queue_Name_CP__c != ''
			) {
				set_LeadId.add(objEvent.WhoId);
				map_LeadIdToEvent.put(objEvent.WhoId, objEvent);
			}
		}
		return set_LeadId;
	}

	private void chilliPipperEventUtility(List<Event> list_newEvents) {
		Set<Id> set_WhoIds = new Set<Id>();
		Map<Id, Id> map_ContactIdOpptyId = new Map<Id, Id>();
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
		// map of contact id and benefits opportunities
		Map<Id, Opportunity> map_NewPlanOppty = new Map<Id, Opportunity>();
		Map<Id, Opportunity> map_BoROppty = new Map<Id, Opportunity>();

		for (Event objEvent : list_newEvents) {
			if (objEvent.RecordTypeId == EventUtil.AE_DEMO_EVENT_RT_ID) {
				set_WhoIds.add(objEvent.WhoId);
			}
		}

		/* Querying contact role object for events created through Chili Piper*/
		for (OpportunityContactRole objContactRole : [
			SELECT ContactId, OpportunityId, CreatedDate, Opportunity.RecordTypeId, Opportunity.CreatedDate
			FROM OpportunityContactRole
			WHERE ContactId IN :set_WhoIds AND IsDeleted = FALSE AND Opportunity.IsClosed = FALSE
			ORDER BY CreatedDate DESC
		]) {
			if (objContactRole == null) {
				continue;
			}

			if (objContactRole.Opportunity?.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID) {
				// get new plan opportunity created date
				DateTime dtmOpptyCreatedDate = objContactRole.Opportunity.CreatedDate;
				// create an instance of the opportunity
				Opportunity objOppty = new Opportunity(Id = objContactRole.OpportunityId, CreatedDate = objContactRole.Opportunity.CreatedDate);

				// check if map already contains contact role's contact id
				if (map_NewPlanOppty.containsKey(objContactRole.ContactId)) {
					// check if its most recent created opportunity, then update map
					if (dtmOpptyCreatedDate > map_NewPlanOppty.get(objContactRole.ContactId).CreatedDate) {
						map_NewPlanOppty.put(objContactRole.ContactId, objOppty);
					}
				} else {
					// update new plan map
					map_NewPlanOppty.put(objContactRole.ContactId, objOppty);
				}
			} else if (objContactRole.Opportunity?.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) {
				// get BoR opportunity created date
				DateTime dtmOpptyCreatedDate = objContactRole.Opportunity.CreatedDate;
				// create an instance of the opportunity
				Opportunity objOppty = new Opportunity(Id = objContactRole.OpportunityId, CreatedDate = objContactRole.Opportunity.CreatedDate);

				// check if map already contains contact role's contact id
				if (map_BoROppty.containsKey(objContactRole.ContactId)) {
					// check if its most recent created opportunity, then update map
					if (dtmOpptyCreatedDate > map_BoROppty.get(objContactRole.ContactId).CreatedDate) {
						map_BoROppty.put(objContactRole.ContactId, objOppty);
					}
				} else {
					// update BoR map
					map_BoROppty.put(objContactRole.ContactId, objOppty);
				}
			} else {
				map_ContactIdOpptyId.put(objContactRole.ContactId, objContactRole.OpportunityId);
			}
		}

		/* Assigning Opportunity Id as related to for the AE Demo events and adding Opportunity id and owner id for opportunity ownership assignment*/
		for (Event objEvent : list_newEvents) {
			if (
				objEvent.WhoId != null &&
				objEvent.RecordtypeId == EventUtil.AE_DEMO_EVENT_RT_ID &&
				(objEvent.Meeting_Type_CP__c == EventUtil.PAYROLL_ONLY_DEMO ||
				objEvent.Meeting_Type_CP__c == EventUtil.PAYROLL_ONLY_PITCH ||
				objEvent.Meeting_Type_CP__c == EventUtil.PAYROLL_BENEFITS_DEMO ||
				objEvent.Meeting_Type_CP__c == EventUtil.PAYROLL_BENEFITS_PATCH ||
				objEvent.Meeting_Type_CP__c == EventUtil.PARTNER_RESELLER_PASS ||
				objEvent.Meeting_Type_CP__c == EventUtil.PARTNER_LIVE_TRANSFER_PASS ||
				objEvent.Meeting_Type_CP__c == EventUtil.HI_OPPTY_NEW_PLAN ||
				objEvent.Meeting_Type_CP__c == EventUtil.HI_OPPTY_BOR)
			) {
				if (objEvent.Meeting_Type_CP__c == EventUtil.HI_OPPTY_NEW_PLAN && map_NewPlanOppty.containsKey(objEvent.WhoId)) {
					Opportunity objOppty = map_NewPlanOppty.get(objEvent.WhoId);
					objEvent.WhatId = objOppty.Id;
					objOppty.OwnerId = objEvent.OwnerId;
					map_OpptysToUpdate.put(objOppty.Id, objOppty);
				} else if (objEvent.Meeting_Type_CP__c == EventUtil.HI_OPPTY_BOR && map_BoROppty.containsKey(objEvent.WhoId)) {
					Opportunity objOppty = map_BoROppty.get(objEvent.WhoId);
					objEvent.WhatId = objOppty.Id;
					objOppty.OwnerId = objEvent.OwnerId;
					map_OpptysToUpdate.put(objOppty.Id, objOppty);
				} else if (map_ContactIdOpptyId.containsKey(objEvent.WhoId)) {
					objEvent.WhatId = map_ContactIdOpptyId.get(objEvent.WhoId);
					Opportunity objOppty = new Opportunity(Id = objEvent.WhatId, OwnerId = objEvent.OwnerId);
					map_OpptysToUpdate.put(objOppty.Id, objOppty);
				}
			}
		}

		if (!map_OpptysToUpdate.isEmpty()) {
			try {
				update map_OpptysToUpdate.values();
			} catch (exception ex) {
				ExceptionLogUtil.logException('EventTriggerHelper', 'chilliPipperEventUtility', ex.getMessage(), 'Medium');
			}
		}
	}

	/*
        By: Gaurav Khare
        Date:  15-May-2019
        Desc:  Before Lead Conversion change Lead owner to event owner
        @Comments: David (Dato) Tsamalashvili - in case Lead is reseller change owner to Event owner 
        but don't convert. Convert company lead only.
    */
	private void changeLeadOwner(Set<Id> set_LeadId) {
		List<Lead> list_LeadToUpdate = new List<Lead>();
		for (Lead objLead : [SELECT Id, OwnerId FROM Lead WHERE Id IN :set_LeadId AND isConverted = FALSE]) {
			objLead.Lead_Owner_Change__c = true;
			objLead.OwnerId = map_LeadIdToEvent.get(objLead.Id).OwnerId;
			list_LeadToUpdate.add(objLead);
		}

		if (list_LeadToUpdate.size() > 0) {
			LeadTriggerHelper.skipTrigger = true;
			update list_LeadToUpdate;
			LeadTriggerHelper.skipTrigger = false;
		}
	}

	/*
	 * @author : Prashant
	 * @Date Created  : 24-june-2020
	 * @Asana : https://app.asana.com/0/1165890935117693/1174138650528440
	 * Desc: Update Lead & Account fields - Last time Lead/Account interacted with Gusto && Last time rep interacted with lead/Account
	 * @modified : 03-07-2020 : If Contact or opportunity is present then update related account activity fields
	 */
	private void populateActivityDatesOnAccLead(List<Event> list_newEvents) {
		Map<Id, User> map_allUsers = GlobalQueryHelper.queryActiveUsers();
		Map<Id, String> map_ownerUserRole = new Map<Id, String>();
		Set<Id> set_AcctId = new Set<Id>();
		Set<Id> set_LeadId = new Set<Id>();
		Set<Id> set_ContactId = new Set<Id>();
		Set<Id> set_OpptyId = new Set<Id>();
		Set<String> set_strMeetingType = new Set<String>{ 'Partner Reseller Pass', 'Payroll Only-Demo', 'Partner Live Transfer Pass' };

		for (Event objEvent : list_newEvents) {
			if (String.isNotBlank(objEvent.WhatId)) {
				String strWhatIdChars = String.valueOf(objEvent.WhatId).SubString(0, 3);
				if (strWhatIdChars == '001') {
					set_AcctId.add(objEvent.WhatId);
				}

				if (strWhatIdChars == '006') {
					set_OpptyId.add(objEvent.WhatId);
				}
			}

			if (String.isNotBlank(objEvent.WhoId)) {
				String strWhoIdChars = String.valueOf(objEvent.WhoId).SubString(0, 3);
				if (strWhoIdChars == '00Q') {
					set_LeadId.add(objEvent.WhoId);
				}

				if (strWhoIdChars == '003') {
					set_ContactId.add(objEvent.WhoId);
				}
			}

			if (map_allUsers.containsKey(objEvent.OwnerId)) {
				map_ownerUserRole.put(objEvent.OwnerId, map_allUsers.get(objEvent.OwnerId).UserRole.Name);
			}
		}

		Map<Id, Account> map_Account = new Map<Id, Account>();
		Map<Id, Lead> map_Lead = new Map<Id, Lead>();
		Map<Id, Contact> map_Contact = new Map<Id, Contact>();
		Map<Id, Opportunity> map_Oppty = new Map<Id, Opportunity>();
		if (set_AcctId.size() > 0) {
			map_Account = new Map<Id, Account>(
				[
					SELECT
						Id,
						OwnerId,
						RecordTypeId,
						Last_Rep_Activity_Date_New__c,
						Last_Account_Activity_Date__c,
						Sales_Engagement_Status__c,
						Sales_Engagement_Status_Detail__c,
						Last_Activity_Date__c,
						Sold_By__c,
						Last_Call_Connect__c,
						Sold_By__r.Last_Activity_Date__c,
						Sold_By__r.Last_Call_Connect__c
					FROM Account
					WHERE Id IN :set_AcctId
				]
			);
		}

		if (set_LeadId.size() > 0) {
			map_Lead = new Map<Id, Lead>(
				[SELECT Id, Last_Rep_Activity_Date__c, Last_Lead_Activity_Date__c, Last_Rep_Activity_Date_New__c, Last_Call__c, Last_Call_Connect__c FROM Lead WHERE Id IN :set_LeadId]
			);
		}

		if (set_ContactId.size() > 0) {
			map_Contact = new Map<Id, Contact>(
				[
					SELECT
						Id,
						AccountId,
						RecordType.Name,
						Last_Contact_Connect__c,
						Last_Contact_Activity__c,
						Account.RecordTypeId,
						Account.Sold_By__c,
						Account.Sold_By__r.Last_Activity_Date__c,
						Account.Last_Activity_Date__c,
						Account.Last_Call_Connect__c,
						Account.Sold_By__r.Last_Call_Connect__c
					FROM Contact
					WHERE Id IN :set_ContactId
				]
			);
		}

		if (set_OpptyId.size() > 0) {
			map_Oppty = new Map<Id, Opportunity>(
				[
					SELECT Id, AccountId, Account.RecordTypeId, Account.Sold_By__c, Account.Sold_By__r.Last_Activity_Date__c, Account.Last_Call_Connect__c, Account.Sold_By__r.Last_Call_Connect__c
					FROM Opportunity
					WHERE Id IN :set_OpptyId
				]
			);
		}

		Map<Id, Account> map_AcctToUpdate = new Map<Id, Account>();
		Map<Id, Lead> map_LeadToUpdate = new Map<Id, Lead>();
		Map<Id, Contact> map_ContactsToUpdate = new Map<Id, Contact>();

		for (Event objEvent : list_newEvents) {
			Account objAcc = null;
			Lead objLead = null;
			Contact objContact = null;
			Opportunity objOppty = null;
			String strWhoIdChars = null;
			String strWhatIdChars = null;

			if (String.isNotBlank(objEvent.WhoId)) {
				strWhoIdChars = String.valueOf(objEvent.WhoId).SubString(0, 3);
			}

			if (String.isNotBlank(objEvent.WhatId)) {
				strWhatIdChars = String.valueOf(objEvent.WhatId).SubString(0, 3);
			}

			if (map_Account.containsKey(objEvent.WhatId)) {
				objAcc = map_Account.get(objEvent.WhatId);
			}

			if (map_Lead.containsKey(objEvent.WhoId)) {
				objLead = map_Lead.get(objEvent.WhoId);
			}

			if (map_Contact.containsKey(objEvent.WhoId)) {
				objContact = map_Contact.get(objEvent.WhoId);
			}

			if (map_Oppty.containsKey(objEvent.WhatId)) {
				objOppty = map_Oppty.get(objEvent.WhatId);
			}

			if (map_ownerUserRole.containsKey(objEvent.OwnerId)) {
				if (
					map_ownerUserRole.get(objEvent.OwnerId).containsIgnoreCase('Sales') &&
					(objEvent.Type.ContainsIgnoreCase('Pitch') ||
					objEvent.Type.ContainsIgnoreCase('demo') ||
					(objEvent.Type.ContainsIgnoreCase('Meeting') && set_strMeetingType.contains(objEvent.meeting_type_cp__c)))
				) {
					if (objEvent.Event_Status__c == 'Connect' || objEvent.Event_Status__c == 'Completed') {
						if (objAcc != null && String.isNotBlank(strWhatIdChars) && strWhatIdChars == '001') {
							//update account fields
							objAcc.Last_Rep_Activity_Date_New__c = objEvent.ActivityDate;
							objAcc.Last_Account_Activity_Date__c = objEvent.ActivityDate;
							map_AcctToUpdate.put(objAcc.Id, objAcc);
						} else if (objLead != null && String.isNotBlank(strWhoIdChars) && strWhoIdChars == '00Q') {
							//update Lead fields
							objLead.Last_Rep_Activity_Date_New__c = objEvent.ActivityDate;
							objLead.Last_Lead_Activity_Date__c = objEvent.ActivityDate;
							map_LeadToUpdate.put(objLead.Id, objLead);
						} else if (objContact != null && String.isNotBlank(strWhoIdChars) && strWhoIdChars == '003') {
							map_AcctToUpdate.put(
								objContact.AccountId,
								new Account(Id = objContact.AccountId, Last_Rep_Activity_Date_New__c = objEvent.ActivityDate, Last_Account_Activity_Date__c = objEvent.ActivityDate)
							);
						} else if (objOppty != null && String.isNotBlank(strWhatIdChars) && strWhatIdChars == '006') {
							map_AcctToUpdate.put(
								objOppty.AccountId,
								new Account(Id = objOppty.AccountId, Last_Rep_Activity_Date_New__c = objEvent.ActivityDate, Last_Account_Activity_Date__c = objEvent.ActivityDate)
							);
						}
					}
				}

				if (
					map_ownerUserRole.get(objEvent.OwnerId).containsIgnoreCase(EventUtil.USER_ROLE_SALES) &&
					(objEvent.Event_Status__c == EventUtil.STATUS_CONNECT ||
					objEvent.Event_Status__c == EventUtil.STATUS_ATTEMPT ||
					objEvent.Event_Status__c == EventUtil.STATUS_SCHEDULED)
				) {
					if (
						objAcc != null &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						objAcc.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objAcc.Sold_By__c != null &&
						(objAcc.Sold_By__r.Last_Activity_Date__c == null ||
						objAcc.Sold_By__r.Last_Activity_Date__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objAcc.Sold_By__c)) {
							map_AcctToUpdate.get(objAcc.Sold_By__c).Last_Activity_Date__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objAcc.Sold_By__c, new Account(Id = objAcc.Sold_By__c, Last_Activity_Date__c = objEvent.ActivityDate));
						}
					}
					if (
						objAcc != null &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						objAcc.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
						(objAcc.Last_Activity_Date__c == null ||
						objAcc.Last_Activity_Date__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objAcc.Id)) {
							map_AcctToUpdate.get(objAcc.Id).Last_Activity_Date__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objAcc.Id, new Account(Id = objAcc.Id, Last_Activity_Date__c = objEvent.ActivityDate));
						}
					}
					if (
						objContact != null &&
						(objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME &&
						objEvent.WhatId == null) &&
						objContact.Account.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
						(objContact.Account.Last_Activity_Date__c == null ||
						objContact.Account.Last_Activity_Date__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objContact.AccountId)) {
							map_AcctToUpdate.get(objContact.AccountId).Last_Activity_Date__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objContact.AccountId, new Account(Id = objContact.AccountId, Last_Activity_Date__c = objEvent.ActivityDate));
						}
					}
					if (
						objContact != null &&
						(objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME &&
						objEvent.WhatId == null) &&
						objContact.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objContact.Account.Sold_By__c != null &&
						(objContact.Account.Sold_By__r.Last_Activity_Date__c == null ||
						objContact.Account.Sold_By__r.Last_Activity_Date__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objContact.Account.Sold_By__c)) {
							map_AcctToUpdate.get(objContact.Account.Sold_By__c).Last_Activity_Date__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objContact.Account.Sold_By__c, new Account(Id = objContact.Account.Sold_By__c, Last_Activity_Date__c = objEvent.ActivityDate));
						}
					}
					if (
						objOppty != null &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						objOppty.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objOppty.Account.Sold_By__c != null &&
						(objOppty.Account.Sold_By__r.Last_Activity_Date__c == null ||
						objOppty.Account.Sold_By__r.Last_Activity_Date__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objOppty.Account.Sold_By__c)) {
							map_AcctToUpdate.get(objOppty.Account.Sold_By__c).Last_Activity_Date__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objOppty.Account.Sold_By__c, new Account(Id = objOppty.Account.Sold_By__c, Last_Activity_Date__c = objEvent.ActivityDate));
						}
					}
					if (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME) {
						if (objContact.Last_Contact_Activity__c == null || objContact.Last_Contact_Activity__c < objEvent.ActivityDate) {
							objContact.Last_Contact_Activity__c = objEvent.ActivityDate;
							if (map_ContactsToUpdate.containsKey(objContact.Id)) {
								map_ContactsToUpdate.get(objContact.Id).Last_Contact_Activity__c = objEvent.ActivityDate;
							} else {
								map_ContactsToUpdate.put(objContact.Id, new Contact(Id = objContact.Id, Last_Contact_Activity__c = objEvent.ActivityDate));
							}
						}
					}
				}

				if (map_ownerUserRole.get(objEvent.OwnerId).containsIgnoreCase(EventUtil.USER_ROLE_SALES) && objEvent.Event_Status__c == EventUtil.STATUS_CONNECT) {
					if (
						objAcc != null &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						objAcc.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objAcc.Sold_By__c != null &&
						(objAcc.Sold_By__r.Last_Call_Connect__c == null ||
						objAcc.Sold_By__r.Last_Call_Connect__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objAcc.Sold_By__c)) {
							map_AcctToUpdate.get(objAcc.Sold_By__c).Last_Call_Connect__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objAcc.Sold_By__c, new Account(Id = objAcc.Sold_By__c, Last_Call_Connect__c = objEvent.ActivityDate));
						}
					}
					if (
						objAcc != null &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						objAcc.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
						(objAcc.Last_Call_Connect__c == null ||
						objAcc.Last_Call_Connect__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objAcc.Id)) {
							map_AcctToUpdate.get(objAcc.Id).Last_Call_Connect__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objAcc.Id, new Account(Id = objAcc.Id, Last_Call_Connect__c = objEvent.ActivityDate));
						}
					}
					if (
						objContact != null &&
						(objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME &&
						objEvent.WhatId == null) &&
						objContact.Account.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
						(objContact.Account.Last_Call_Connect__c == null ||
						objContact.Account.Last_Call_Connect__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objContact.AccountId)) {
							map_AcctToUpdate.get(objContact.AccountId).Last_Call_Connect__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objContact.AccountId, new Account(Id = objContact.AccountId, Last_Call_Connect__c = objEvent.ActivityDate));
						}
					}
					if (
						objContact != null &&
						(objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME &&
						objEvent.WhatId == null) &&
						objContact.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objContact.Account.Sold_By__c != null &&
						(objContact.Account.Sold_By__r.Last_Call_Connect__c == null ||
						objContact.Account.Sold_By__r.Last_Call_Connect__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objContact.Account.Sold_By__c)) {
							map_AcctToUpdate.get(objContact.Account.Sold_By__c).Last_Call_Connect__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objContact.Account.Sold_By__c, new Account(Id = objContact.Account.Sold_By__c, Last_Call_Connect__c = objEvent.ActivityDate));
						}
					}
					if (
						objOppty != null &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						objOppty.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objOppty.Account.Sold_By__c != null &&
						(objOppty.Account.Sold_By__r.Last_Call_Connect__c == null ||
						objOppty.Account.Sold_By__r.Last_Call_Connect__c < objEvent.ActivityDate)
					) {
						if (map_AcctToUpdate.containsKey(objOppty.Account.Sold_By__c)) {
							map_AcctToUpdate.get(objOppty.Account.Sold_By__c).Last_Call_Connect__c = objEvent.ActivityDate;
						} else {
							map_AcctToUpdate.put(objOppty.Account.Sold_By__c, new Account(Id = objOppty.Account.Sold_By__c, Last_Call_Connect__c = objEvent.ActivityDate));
						}
					}
					if (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME) {
						if (objContact.Last_Contact_Connect__c == null || objContact.Last_Contact_Connect__c < objEvent.ActivityDate) {
							objContact.Last_Contact_Connect__c = objEvent.ActivityDate;
							if (map_ContactsToUpdate.containsKey(objContact.Id)) {
								map_ContactsToUpdate.get(objContact.Id).Last_Contact_Connect__c = objEvent.ActivityDate;
							} else {
								map_ContactsToUpdate.put(objContact.Id, new Contact(Id = objContact.Id, Last_Contact_Connect__c = objEvent.ActivityDate));
							}
						}
					}
				}
			}

			//BTA-200 & BTA-221 ChilliPiper Event Automations
			if (
				objEvent.RecordtypeId == EventUtil.AE_DEMO_EVENT_RT_ID &&
				objEvent.Meeting_Type_CP__c == EventUtil.MEETING_TYPE &&
				objEvent.Booked_By__c != null &&
				map_allUsers.containsKey(objEvent.Booked_By__c) &&
				map_allUsers.get(objEvent.Booked_By__c).Name == EventUtil.LABEL_CHILIPIPER
			) {
				//Account updates
				if (objAcc != null && objAcc.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
					//Sales Enagement Status Updates
					if (
						(map_allUsers?.get(objEvent.OwnerId)?.UserRole?.Name == AccountUtil.SALES_MDR_MGR_ROLE ||
						map_allUsers?.get(objEvent.OwnerId)?.UserRole?.Name == AccountUtil.SALES_PARTNER_AE_ROLE) && (objAcc.OwnerId != objEvent.OwnerId)
					) {
						objAcc.OwnerId = objEvent.OwnerId;
						map_AcctToUpdate.put(objAcc.Id, objAcc);
					}
				}
			}
		}

		if (map_AcctToUpdate.size() > 0) {
			//Dont want to skip Account Trigger because of ownership updates on Account need to reflect on related contacts
			update map_AcctToUpdate.values();
		}

		if (map_LeadToUpdate.size() > 0) {
			LeadTriggerHelper.skipTrigger = true;
			update map_LeadToUpdate.values();
			LeadTriggerHelper.skipTrigger = false;
		}

		if (!map_ContactsToUpdate.isEmpty()) {
			ContactTriggerHelper.skipTrigger = true;
			update map_ContactsToUpdate.values();
			ContactTriggerHelper.skipTrigger = true;
		}
	}

	/**
	 * @author : Yuvraj
	 * @Date Created  : 29-june-2020
	 * @Asana : https://app.asana.com/0/1165890935117693/1182251234335985
	 * Desc: Update event record type if (Queue_Name_CP__c) is not null and is not empty and Event record type is not "AE Demo"
	 */
	private void updateEventRecordType(List<Event> list_newEvents) {
		for (Event objEvent : list_newEvents) {
			if (!String.isBlank(objEvent.Queue_Name_CP__c) && objEvent.RecordTypeId != EventUtil.AE_DEMO_EVENT_RT_ID) {
				objEvent.RecordTypeId = EventUtil.AE_DEMO_EVENT_RT_ID;
			}
		}
	}

	/**
	 * @author 			   Ajay Krishna PU
	 * @description        Updates Last Activity Date of Ardius tickets related to New events
	 * @param list_newEvents New event records
	 */
	private static void populateLastActivityDateOnTicket(List<Event> list_newEvents) {
		Set<Id> set_TicketIds = new Set<Id>();

		//Find all Events related to Ticket__c
		for (Event objEvent : list_newEvents) {
			if (objEvent.WhatId != null && String.valueOf(objEvent.WhatId).startsWithIgnoreCase(EventUtil.TICKET_PREFIX)) {
				set_TicketIds.add(objEvent.WhatId);
			}
		}

		//Stop processing If no Event related to Tickets
		if (set_TicketIds.isEmpty()) {
			return;
		}

		//Identify all Ardius tickets related to events
		List<Ticket__c> list_TicketsToBeUpdated = new List<Ticket__c>();
		//Update all identified Ardius tickets
		DateTime dtNow = DateTime.now();
		for (Ticket__c objTicket : [SELECT Id, RecordTypeId, Last_Activity_Date__c FROM Ticket__c WHERE Id IN :set_TicketIds AND RecordTypeId = :EventUtil.ARDIUS_TICKET_RT_ID]) {
			objTicket.Last_Activity_Date__c = dtNow;
			list_TicketsToBeUpdated.add(objTicket);
		}

		if (!list_TicketsToBeUpdated.isEmpty()) {
			update list_TicketsToBeUpdated;
		}
	}

	/**
	 * @author	Ajay Krishna PU
	 * @description	Sets Ticket Status If Event Related to a Ardius Ticket
	 * @param list_newEvents New event records
	 */
	private void setRelatedTicketStatusForEvent(List<Event> list_newEvents) {
		Set<Id> set_TicketIds = new Set<Id>();
		Map<Id, Ticket__c> map_Tickets = new Map<Id, Ticket__c>();

		//Find all Events related to Ticket__c
		for (Event objEvent : list_newEvents) {
			if (checkIfWhatIsTicket(objEvent)) {
				set_TicketIds.add(objEvent.WhatId);
			}
		}

		//Stop processing If no Event related to Tickets,
		//If Event related to Ticket, add it to map_Tickets
		if (set_TicketIds.isEmpty()) {
			return;
		} else {
			map_Tickets = new Map<Id, Ticket__c>(queryTickets(set_TicketIds, new List<Id>{ EventUtil.ARDIUS_TICKET_RT_ID }));
		}

		//Populate Ticket Status for those Events related to Ardius tickets
		for (Event objEvent : list_newEvents) {
			if (checkIfWhatIsTicket(objEvent) && map_Tickets?.containsKey(objEvent.WhatId) == true) {
				objEvent.Ticket_Status__c = map_Tickets.get(objEvent.WhatId).Status__c;
			}
		}
	}

	/**
	 * @author        Rushi R
	 * @description   Update Event Type, migrating Workflow Rule
	 * @param         list_newEvents - New event records in list
	 */
	private void updateEventType(List<Event> list_newEvents) {
		for (Event objEvent : list_newEvents) {
			if (String.isNotBlank(objEvent.Meeting_Type_CP__c) && objEvent.RecordTypeId == EventUtil.AE_DEMO_EVENT_RT_ID) {
				objEvent.Type = EventUtil.PITCH_TYPE;
			}
		}
	}

	/**
	 * @author        Rushi R
	 * @description   Update Event No Show and Status (Process Builder)
	 * @param         list_newEvents - New event records in list
	 *                map_oldEvents  - Old event records in map
	 */
	private void updateEventNoShow(List<Event> list_newEvents, Map<Id, Event> map_oldEvents) {
		for (Event objEvent : list_newEvents) {
			if (String.isBlank(objEvent.Event_Status__c)) {
				continue;
			}

			Event objOldEvent;
			Boolean blnStatusChanged = false;
			Boolean blnNoShowChanged = false;
			String strStatus = null;

			if (String.isNotBlank(objEvent.Event_Status__c)) {
				strStatus = objEvent.Event_Status__c;
			}

			if (map_oldEvents != null && map_oldEvents.containsKey(objEvent.Id)) {
				objOldEvent = map_oldEvents.get(objEvent.Id);

				if (String.isBlank(strStatus)) {
					blnStatusChanged = false;
				} else if (objOldEvent?.Event_Status__c != strStatus) {
					blnStatusChanged = true;
				}

				if (objOldEvent?.No_Show_CP__c != objEvent.No_Show_CP__c) {
					blnNoShowChanged = true;
				}
			}

			if (blnStatusChanged && (strStatus == EventUtil.STATUS_SCHEDULED || strStatus == EventUtil.STATUS_CONNECT)) {
				objEvent.No_Show_CP__c = false;
			} else if (blnNoShowChanged && objEvent.No_Show_CP__c && (blnStatusChanged && (strStatus == EventUtil.STATUS_ATTEMPT || strStatus == EventUtil.STATUS_CANCELED))) {
				// Runs After Save flow to send No Show Email
			} else if (blnNoShowChanged && !objEvent.No_Show_CP__c) {
				objEvent.Event_Status__c = null;
			}
		}
	}

	/**
	 * @author        Debasmita Rawooth
	 * @description   Sets Closed_Owner_Role__c with role of owner during event creation and closure for historical user reporting
	 * @param         list_newEvents - New event records in list
	 *          	  map_oldEvents  - Old event records in map
	 **/
	private void updateClosedOwnerRole(List<Event> list_newEvents, Map<Id, Event> map_oldEvents) {
		if (map_oldEvents == null) {
			for (Event objEvent : list_newEvents) {
				objEvent.Closed_Owner_Role__c = UserUtils.getUserRoleName(objEvent.OwnerId);
			}
		} else {
			for (Event objEvent : list_newEvents) {
				if (
					map_oldEvents.containsKey(objEvent.Id) &&
					objEvent.Event_Status__c != map_oldEvents.get(objEvent.Id).Event_Status__c &&
					!EventUtil.set_EventClosureStatus.contains(map_oldEvents.get(objEvent.Id).Event_Status__c) &&
					EventUtil.set_EventClosureStatus.contains(objEvent.Event_Status__c)
				) {
					objEvent.Closed_Owner_Role__c = UserUtils.getUserRoleName(objEvent.OwnerId);
				}
			}
		}
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Checks if WhatId is Account
	 * @Parm        : objEvent
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhatIsAccount(Event objEvent) {
		return objEvent.WhatId != null && String.valueOf(objEvent.WhatId).startsWithIgnoreCase(EventUtil.ACCOUNT_PREFIX);
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Checks if WhoId is Contact
	 * @Parm        : objEvent
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhoIsContact(Event objEvent) {
		return objEvent.WhoId != null && String.valueOf(objEvent.WhoId).startsWithIgnoreCase(EventUtil.CONTACT_PREFIX);
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Checks if WhatId is Opportunity
	 * @Parm        : objEvent
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhatIsOpportunity(Event objEvent) {
		return objEvent.WhatId != null && String.valueOf(objEvent.WhatId).startsWithIgnoreCase(EventUtil.OPPORTUNITY_PREFIX);
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Checks if WhoId is Lead
	 * @Parm        : objEvent
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhoIsLead(Event objEvent) {
		return objEvent.WhoId != null && String.valueOf(objEvent.WhoId).startsWithIgnoreCase(EventUtil.LEAD_PREFIX);
	}

	/**
	 * @description    Checks if WhatId is Ticket
	 * @author Ajay Krishna PU
	 * @param objEvent New version of event
	 * @return         `Boolean` true, if Event related to Ticket
	 */
	public Boolean checkIfWhatIsTicket(Event objEvent) {
		return objEvent.WhatId != null && String.valueOf(objEvent.WhatId).startsWithIgnoreCase(EventUtil.TICKET_PREFIX);
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Update Last_Call_Connect__c on Account, Opportunity and Lead
	 * @Parm        : objEvent
	 * @Return      : N/A
	 **/
	private void updateLastCallConnectDetails(List<Event> list_newEvents) {
		for (Event objEvent : list_newEvents) {
			Account objAccount = map_Accounts.containsKey(objEvent.AccountId) ? map_Accounts.get(objEvent.AccountId) : null;
			Opportunity objOpportunity = map_Opportunities.containsKey(objEvent.WhatId) ? map_Opportunities.get(objEvent.WhatId) : null;
			Lead objLead = map_Leads.containsKey(objEvent.WhoId) ? map_Leads.get(objEvent.WhoId) : null;

			if (objEvent.ActivityDate != null && String.isNotBlank(objEvent.Event_Status__c) && objEvent.Event_Status__c.equalsIgnoreCase(EventUtil.STATUS_CONNECT)) {
				if (objAccount != null && (objAccount.Last_Call_Connect__c == null || objEvent.ActivityDate >= objAccount.Last_Call_Connect__c)) {
					objAccount.Last_Call_Connect__c = objEvent.ActivityDate;
					map_AccountsToUpdate.put(objAccount.Id, objAccount);
				}
				if (objOpportunity != null && (objOpportunity.Last_Call_Connect__c == null || objEvent.ActivityDate >= objOpportunity.Last_Call_Connect__c)) {
					objOpportunity.Last_Call_Connect__c = objEvent.ActivityDate;
					map_OpportunitiesToUpdate.put(objOpportunity.Id, objOpportunity);

					// update last call connect on account if last call connect on opportunity is updated
					if (
						(objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
						objOpportunity.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) &&
						objOpportunity.AccountId != null &&
						(objOpportunity.Account.Last_Call_Connect__c == null ||
						objOpportunity.Last_Call_Connect__c > objOpportunity.Account.Last_Call_Connect__c)
					) {
						// get account from map of accounts to update
						Account objAcc = map_AccountsToUpdate.containsKey(objOpportunity.AccountId) ? map_AccountsToUpdate.get(objOpportunity.AccountId) : new Account(Id = objOpportunity.AccountId);

						// set last call connect on account the same as last call connect on opportunity
						objAcc.Last_Call_Connect__c = objOpportunity.Last_Call_Connect__c;
						// add it to list of accounts to be updated
						map_AccountsToUpdate.put(objAcc.Id, objAcc);
					}
				}
				if (objLead != null && (objLead.Last_Call_Connect__c == null || objEvent.ActivityDate >= objLead.Last_Call_Connect__c)) {
					objLead.Last_Call_Connect__c = objEvent.ActivityDate;
					map_LeadsToUpdate.put(objLead.Id, objLead);
				}
			}
		}
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Query Accounts
	 * @Parm        : set_AccountIds
	 * @Return      : N/A
	 **/
	public Map<Id, Account> queryAccounts(Set<Id> set_AccountIds) {
		return new Map<Id, Account>([SELECT Id, Last_Call_Connect__c FROM Account WHERE Id IN :set_AccountIds]);
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Query Opportunities
	 * @Parm        : set_OpportunityIds
	 * @Return      : N/A
	 **/
	public Map<Id, Opportunity> queryOpportunities(Set<Id> set_OpportunityIds) {
		return new Map<Id, Opportunity>([SELECT Id, AccountId, Account.Last_Call_Connect__c, Last_Call_Connect__c, RecordTypeId FROM Opportunity WHERE Id IN :set_OpportunityIds]);
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Query Leads
	 * @Parm        : set_LeadIds
	 * @Return      : N/A
	 **/
	public Map<Id, Lead> queryLeads(Set<Id> set_LeadIds) {
		return new Map<Id, Lead>([SELECT Id, Last_Call_Connect__c FROM Lead WHERE Id IN :set_LeadIds]);
	}

	/**
	 * @description	Query Tickets
	 * @author	Ajay Krishna PU
	 * @param set_TicketIds      Ticket Ids to be query
	 * @param list_RecordTypeIds List of RecordType Ids
	 * @return                   `List<Ticket__c>` ist of Tickets having Id @set_TicketIds and RecordTypeId @list_RecordTypeIds
	 */
	public List<Ticket__c> queryTickets(Set<Id> set_TicketIds, List<Id> list_RecordTypeIds) {
		return [SELECT Id, RecordTypeId, Status__c FROM Ticket__c WHERE Id IN :set_TicketIds AND RecordTypeId IN :list_RecordTypeIds];
	}

	/**
	 * @Author      : Debasmita
	 * @Description : Post Trigger DML Inserts and Updates
	 * @Parm        : blnInsert - Falg to check insert or update operation
	 * @Return      : N/A
	 **/
	private void processDMLOperation(Boolean blnInsert) {
		if (!blnInsert) {
			try {
				if (!map_AccountsToUpdate.isEmpty()) {
					AccountTriggerHelper.skipTrigger = true;
					update map_AccountsToUpdate.values();
					AccountTriggerHelper.skipTrigger = false;
				}
				if (!map_OpportunitiesToUpdate.isEmpty()) {
					OpportunityTriggerHelper.skipTrigger = true;
					update map_OpportunitiesToUpdate.values();
					OpportunityTriggerHelper.skipTrigger = false;
				}
				if (!map_LeadsToUpdate.isEmpty()) {
					LeadTriggerHelper.skipTrigger = true;
					update map_LeadsToUpdate.values();
					LeadTriggerHelper.skipTrigger = false;
				}
			} catch (exception objEx) {
				ExceptionLogUtil.logException('EventTriggerHelper', 'processDMLOperation', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
			}
		}
	}
}