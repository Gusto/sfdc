/**
 * @name         : TaskTriggerHelper
 * @author       : Praveen Sethu & Veeresh
 * @date         : 06/05/2021
 * @description  : New Refactored TaskTriggerHelper Class
 * @test classes : TaskTriggerHelperTest
 **/
public without sharing class TaskTriggerHelper {
	// ------------ EXISTING STATIC VARIABLES STARTS HERE ----------
	// Developer Notes - Not renaming static variable names as these could be used in so many places
	// Static Variable used to skip Task Triggers
	public static Boolean skipTrigger = false;
	public static Integer counter = 0;
	public static Boolean createCase = false;
	// ------------ EXISTING STATIC VARIABLES END HERE ----------
	//********************* New Code ************************************************
	/*** All Static Strng Variables ***/
	public static String strMDRRoleId = Label.MDR_Role_ID;

	/*** All Static Map Variables ***/
	public static Map<Id, Account> map_AccountsToUpdate;
	public static Map<Id, Case> map_CasesToUpdate;
	public static Map<Id, Contact> map_ContactsToUpdate;
	public static Map<Id, Lead> map_LeadsToUpdate;
	public static Map<Id, Opportunity> map_OpptysToUpdate;
	public static Map<String, Lead_Related_Tracking__c> map_LeadRelatedTrackingsToUpsert;
	public static Map<String, Account_Related_Tracking__c> map_AccountRelatedTrackingsToUpsert;
	public static Map<String, Case_Audit_Log__c> map_CaseAuditLogsToUpsert;
	public static Map<String, String> map_TaskConversationIdToURLs;

	/*** All Static List Variables ***/
	public static List<FeedItem> list_FeedItemsToInsert;
	public static List<Case> list_CasesToInsert;

	/*** All Static Boolean Variables ***/
	public static Boolean blnTestExceptions = false;

	/*** All Instance Variables Start here ***/
	/*** All objects ***/
	public User objCurrentUser;
	OppRelatedTrackingClass objOppTrackClass;

	/*** All set variables ***/
	public Set<String> set_GeneysisAniPhoneNos;
	public Set<String> set_MatchedContactPhoneNos;
	public Set<String> set_ClosedStatuses;
	public Set<String> set_GenesysIds;
	public Set<Id> set_AccountIds;
	public Set<Id> set_ContactIds;
	public Set<Id> set_LeadIds;
	public Set<Id> set_CaseIds;
	public Set<Id> set_OpportunityIds;
	public Set<Id> set_OwnerIds;
	public Set<Id> set_CaseIdsWithAdvisingCalls;
	public Set<Id> set_OppIdsWithAdvisingCalls;
	public Set<Id> set_TicketIds;
	public Set<Id> set_CustomerRevisionTicketIds;
	public Set<String> set_StatusHaveArdiusTemplates;
	public Set<Id> set_AccIdsWithOppToQuery;
	public Set<Id> set_TaskIdToReassign;

	/*** All Map variables ***/
	public Map<String, Case_Audit_Log__c> map_ExternalIdToCaseAuditLogs;
	public Map<Id, Lead> map_Leads;
	public Map<Id, Account> map_Accounts;
	public Map<Id, Opportunity> map_Opportunities;
	public Map<Id, Contact> map_Contacts;
	public Map<Id, User> map_Users;
	public Map<Id, List<Case>> map_LeadCases;
	public Map<Id, Lead_Related_Tracking__c> map_LeadIdToTracking;
	public Map<String, Case> map_CaseGenesysCallIdToCase;
	public Map<Id, Id> map_CaseIdWithOpportunityIds;
	public Map<Id, Ticket__c> map_TicketWithTasks;
	public Map<Id, Ticket__c> map_Tickets;
	public Map<Id, Ticket__c> map_ArdiusTickets;
	public Map<Id, Account> map_AccountWithOpportunities;

	/*** All List Variables ***/
	List<Ticket__c> list_TicketsToBeUpdated;
	List<Ticket__c> list_CustomerRevisionTicketsToBeUpdated;
	List<TaskTemplateUtil.TemplateType> list_TaskTemplateTypes;

	public TaskTriggerHelper() {
		/*** All set variables ***/
		set_GeneysisAniPhoneNos = new Set<String>();
		set_MatchedContactPhoneNos = new Set<String>();
		set_ClosedStatuses = new Set<String>();
		set_GenesysIds = new Set<String>();
		set_AccountIds = new Set<Id>();
		set_ContactIds = new Set<Id>();
		set_LeadIds = new Set<Id>();
		set_CaseIds = new Set<Id>();
		set_OpportunityIds = new Set<Id>();
		set_OwnerIds = new Set<Id>{ UserInfo.getUserId() };
		set_CaseIdsWithAdvisingCalls = new Set<Id>();
		set_OppIdsWithAdvisingCalls = new Set<Id>();
		set_TicketIds = new Set<Id>();
		set_CustomerRevisionTicketIds = new Set<Id>();
		set_StatusHaveArdiusTemplates = new Set<String>();
		set_AccIdsWithOppToQuery = new Set<Id>();
		set_TaskIdToReassign = new Set<Id>();

		/*** All Map variables ***/
		map_ExternalIdToCaseAuditLogs = new Map<String, Case_Audit_Log__c>();
		map_Leads = new Map<Id, Lead>();
		map_Accounts = new Map<Id, Account>();
		map_Opportunities = new Map<Id, Opportunity>();
		map_CaseIdWithOpportunityIds = new Map<Id, Id>();
		map_TicketWithTasks = new Map<Id, Ticket__c>();
		map_Contacts = new Map<Id, Contact>();
		map_Users = new Map<Id, User>();
		map_LeadCases = new Map<Id, List<Case>>();
		map_LeadIdToTracking = new Map<Id, Lead_Related_Tracking__c>();
		map_CaseGenesysCallIdToCase = new Map<String, Case>();
		map_Tickets = new Map<Id, Ticket__c>();
		map_ArdiusTickets = new Map<Id, Ticket__c>();
		map_AccountWithOpportunities = new Map<Id, Account>();

		/*** All List Variables ***/
		list_TicketsToBeUpdated = new List<Ticket__c>();
		list_CustomerRevisionTicketsToBeUpdated = new List<Ticket__c>();
		list_TaskTemplateTypes = new List<TaskTemplateUtil.TemplateType>();

		/*** All Object Variables ***/
		objOppTrackClass = new OppRelatedTrackingClass();
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Handles Before Insert Context
	 * @Parm        : list_Tasks - List of Tasks from Trigger.new
	 * @Return      : N/A
	 **/
	public void processBeforeInsert(List<Task> list_Tasks) {
		initializeStaticVariables();
		setCollectionsBefore(list_Tasks);

		for (Task objTask : list_Tasks) {
			setDefaultsOnCreate(objTask);
			createFeedItem(objTask);
			updateDurationFields(objTask, null);
			setCaseInformation(objTask);
			setCaseAndOpportunityIds(objTask);
			populateNICERecordType(objTask);
			setNBAFieldsOnTask(objTask);
			setOwnerAssignedToTaskTime(objTask, null);
			setRecordType(objTask); // Added by sujan for BPO-1990
			assignPrevTaxYearOpptyAsTaskOwner(objTask, null);
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Handles After Insert Context
	 * @Parm        : map_NewTasks - Map of Task Id and Task Object from Trigger.newMap
	 * @Return      : N/A
	 **/
	public void processAfterInsert(Map<Id, Task> map_NewTasks) {
		setCollectionsAfter(map_NewTasks.values());

		for (Task objTask : map_NewTasks.values()) {
			populateActivityDatesOnAccLeadOpp(objTask, null);
			upsertLeadRelatedTrackingRec(objTask);
			updateMQLDateOnLeadRelatedTracking(objTask);
			upsertAccountRelatedTrackingRec(objTask);
			updateHIRepFirstTouchOnAccount(objTask);
			updateEngagementBizOnContactAndLead(objTask);
			updateLastCallConnectDetails(objTask);
			processGenesysTaskDuration(objTask, null);
			updateCaseCallbackFromTask(objTask);
			setLeadInitiatedDateAndFormSubmitDate(objTask);
			setAdvisingCallRelatedObject(objTask);
			identifyAutoCreateTasks(objTask, null);
		}

		calculateAdvisingTouchpoints();
		populateLastActivityDateOnTicket();
		processDMLOperation(true);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Handles Before Update Context
	 * @Parm        : map_NewTasks - Map of Task Id and Task Object from Trigger.newMap
	 * @Parm        : map_OldTasks - Map of Task Id and Task Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processBeforeUpdate(Map<Id, Task> map_NewTasks, Map<Id, Task> map_OldTasks) {
		initializeStaticVariables();
		setCollectionsBefore(map_NewTasks.values());

		for (Task objNewTask : map_NewTasks.values()) {
			Task objOldTask = map_OldTasks.containsKey(objNewTask.Id) ? map_OldTasks.get(objNewTask.Id) : null;

			setDefaultsOnUpdate(objNewTask, objOldTask);
			setCaseInformation(objNewTask);
			createFeedItem(objNewTask);
			updateDurationFields(objNewTask, objOldTask);
			processNICETasks(objNewTask, objOldTask);
			setCaseAndOpportunityIds(objNewTask);
			setOwnerAssignedToTaskTime(objNewTask, objOldTask);
			assignPrevTaxYearOpptyAsTaskOwner(objNewTask, objOldTask);
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Handles After Update Context
	 * @Parm        : map_NewTasks - Map of Task Id and Task Object from Trigger.newMap
	 * @Parm        : map_OldTasks - Map of Task Id and Task Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processAfterUpdate(Map<Id, Task> map_NewTasks, Map<Id, Task> map_OldTasks) {
		setCollectionsAfter(map_NewTasks.values());

		for (Task objNewTask : map_NewTasks.values()) {
			Task objOldTask = map_OldTasks.containsKey(objNewTask.Id) ? map_OldTasks.get(objNewTask.Id) : null;
			populateActivityDatesOnAccLeadOpp(objNewTask, objOldTask);
			upsertLeadRelatedTrackingRec(objNewTask);
			upsertAccountRelatedTrackingRec(objNewTask);
			processGenesysTaskDuration(objNewTask, objOldTask);
			updateCaseCallbackFromTask(objNewTask);
			updateLastCallConnectDetails(objNewTask);
			markTicketClosedAfterTaskCompleted(objOldTask);
			identifyAutoCreateTasks(objNewTask, objOldTask);
		}

		populateLastActivityDateOnTicket();
		processDMLOperation(false);
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Handles Before Delete Context
	 * @Parm        : map_OldTasks - Map of Task Id and Task Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processBeforeDelete(Map<Id, Task> map_OldTasks) {
		for (Task objOldTask : map_OldTasks.values()) {
			preventDeletion(objOldTask);
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Queries data and create collections required for BEFORE context
	 * @Parm        : list_Tasks - List of Tasks from Trigger.new
	 * @Return      : N/A
	 **/
	public void setCollectionsBefore(List<Task> list_Tasks) {
		Set<Id> set_CaseIdsToAdvisingCall = new Set<Id>();
		Set<Id> set_ArdiusIntegrationUserIds = TicketUtil.getArdiusTicketIntegrationUsers();
		for (Task objTask : list_Tasks) {
			if (String.isNotBlank(objTask.Type) && String.isNotBlank(objTask.Genesys_Ani__c) && objTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_CALL) && objTask.Genesys_Ani__c.length() >= 10) {
				set_GeneysisAniPhoneNos.add(objTask.Genesys_Ani__c);
			}

			if (String.isNotBlank(objTask.CallObject)) {
				set_GenesysIds.add(objTask.CallObject);
			}

			if (checkIfWhoIsLead(objTask)) {
				set_LeadIds.add(objTask.WhoId);
			}

			if (checkIfWhatIsOpportunity(objTask)) {
				set_OpportunityIds.add(objTask.WhatId);
			}

			if (objTask.RecordTypeId == TaskUtil.TASK_ADVISING_CALL_RT_ID) {
				if (checkIfWhatIsCase(objTask)) {
					set_CaseIdsToAdvisingCall.add(objTask.WhatId);
				}

				if (objTask.Case__c != null) {
					set_CaseIdsToAdvisingCall.add(objTask.Case__c);
				}
			}

			if (checkIfWhatIsTicket(objTask)) {
				set_TicketIds.add(objTask.WhatId);
			}

			if (
				objTask.Feature_Request__c == TaskUtil.TASK_RD_EVALUATION_CALL &&
				objTask.Status == TaskUtil.TASK_STATUS_OPEN &&
				checkIfWhatIsAccount(objTask) &&
				set_ArdiusIntegrationUserIds.contains(objTask.OwnerId)
			) {
				set_AccIdsWithOppToQuery.add(objTask.WhatId);
				set_TaskIdToReassign.add(objTask.Id);
			}
		}

		for (User objUser : queryUsers(set_OwnerIds)) {
			if (objUser.Id == UserInfo.getUserId()) {
				objCurrentUser = objUser;
			}
			map_Users.put(objUser.Id, objUser);
		}

		for (TaskStatus objTaskStatus : queryTaskStatus()) {
			set_ClosedStatuses.add(objTaskStatus.MasterLabel);
		}

		if (!set_GeneysisAniPhoneNos.isEmpty() || !set_ContactIds.isEmpty()) {
			for (Contact objContact : queryContacts(set_GeneysisAniPhoneNos, set_ContactIds)) {
				for (String strField : TaskUtil.list_ContactPhoneFields) {
					if (objContact.get(strField) != null) {
						set_MatchedContactPhoneNos.add(String.valueOf(objContact.get(strField)));
					}
				}
				map_Contacts.put(objContact.Id, objContact);
			}
		}

		if (!set_GenesysIds.isEmpty()) {
			for (Case_Audit_Log__c objAuditLog : queryCaseAuditLogs(set_GenesysIds)) {
				map_ExternalIdToCaseAuditLogs.put(objAuditLog.External_Id__c, objAuditLog);
			}
		}

		if (!set_LeadIds.isEmpty()) {
			map_Leads = queryLeads(set_LeadIds);
		}

		if (!set_OpportunityIds.isEmpty()) {
			map_Opportunities = queryOpportunities(set_OpportunityIds);
		}

		if (set_CaseIdsToAdvisingCall.size() > 0) {
			for (Case objCase : queryCases(new Set<Id>(), new Set<Id>(), new Set<String>(), set_CaseIdsToAdvisingCall)) {
				map_CaseIdWithOpportunityIds.put(objCase.Id, objCase.Opportunity__c);
			}
		}

		if (!set_TicketIds.isEmpty()) {
			map_Tickets = new Map<Id, Ticket__c>(queryTickets(set_TicketIds, new List<Id>{ TaskUtil.ARDIUS_TICKET_RT_ID }));
		}

		if (!set_AccIdsWithOppToQuery.isEmpty()) {
			map_AccountWithOpportunities = queryAccountsWithRelatedOpptys(set_AccIdsWithOppToQuery);
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Queries data and create collections required for after context
	 * @Parm        : list_Tasks - List of Tasks from Trigger.new
	 * @Return      : N/A
	 **/
	public void setCollectionsAfter(List<Task> list_Tasks) {
		for (Task objTask : list_Tasks) {
			if (String.isNotBlank(objTask.Type) && String.isNotBlank(objTask.Genesys_Ani__c) && objTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_CALL) && objTask.Genesys_Ani__c.length() >= 10) {
				set_GeneysisAniPhoneNos.add(objTask.Genesys_Ani__c);
			}

			if (String.isNotBlank(objTask.CallObject)) {
				set_GenesysIds.add(objTask.CallObject);
			}

			if (checkIfWhatIsAccount(objTask)) {
				set_AccountIds.add(objTask.WhatId);
			}
			// Task gets AccountId even when WhatId is Opportunity
			if (objTask.AccountId != null) {
				set_AccountIds.add(objTask.AccountId);
			}

			if (checkIfWhatIsOpportunity(objTask)) {
				set_OpportunityIds.add(objTask.WhatId);
			}

			if (checkIfWhoIsContact(objTask)) {
				set_ContactIds.add(objTask.WhoId);
			}

			if (checkIfWhoIsLead(objTask)) {
				set_LeadIds.add(objTask.WhoId);
			}

			if (checkIfWhatIsTicketCustomerRevision(objTask)) {
				set_CustomerRevisionTicketIds.add(objTask.WhatId);
			}

			if (checkIfWhatIsTicket(objTask)) {
				set_TicketIds.add(objTask.WhatId);
			}

			set_OwnerIds.add(objTask.OwnerId);
		}

		for (User objUser : queryUsers(set_OwnerIds)) {
			if (objUser.Id == UserInfo.getUserId()) {
				objCurrentUser = objUser;
			}
			map_Users.put(objUser.Id, objUser);
		}

		for (TaskStatus objTaskStatus : queryTaskStatus()) {
			set_ClosedStatuses.add(objTaskStatus.MasterLabel);
		}

		if (!set_GeneysisAniPhoneNos.isEmpty() || !set_ContactIds.isEmpty()) {
			for (Contact objContact : queryContacts(set_GeneysisAniPhoneNos, set_ContactIds)) {
				map_Contacts.put(objContact.Id, objContact);
			}
		}

		if (!set_ContactIds.isEmpty() || !set_LeadIds.isEmpty() || !set_GenesysIds.isEmpty()) {
			for (Case objCase : queryCases(set_ContactIds, set_LeadIds, set_GenesysIds, new Set<Id>())) {
				if (objCase.Lead__c != null) {
					if (map_LeadCases.containsKey(objCase.Lead__c)) {
						map_LeadCases.get(objCase.Lead__c).add(objCase);
					} else {
						map_LeadCases.put(objCase.Lead__c, new List<Case>{ objCase });
					}
				}

				if (String.isNotBlank(objCase.Genesys_Call_Id__c)) {
					map_CaseGenesysCallIdToCase.put(objCase.Genesys_Call_Id__c, objCase);
				}
			}
		}

		if (!set_LeadIds.isEmpty()) {
			map_Leads = queryLeads(set_LeadIds);

			for (Lead_Related_Tracking__c objTracking : queryLeadRelatedrackings(set_LeadIds)) {
				map_LeadIdToTracking.put(objTracking.Lead__c, objTracking);
			}
		}

		if (!set_AccountIds.isEmpty()) {
			map_Accounts = queryAccounts(set_AccountIds);
		}

		if (!set_OpportunityIds.isEmpty()) {
			map_Opportunities = queryOpportunities(set_OpportunityIds);
		}

		if (!set_TicketIds.isEmpty()) {
			list_TicketsToBeUpdated = queryTickets(set_TicketIds, new List<Id>{ TaskUtil.ARDIUS_TICKET_RT_ID });
			map_ArdiusTickets = new Map<Id, Ticket__c>(list_TicketsToBeUpdated);
			set_StatusHaveArdiusTemplates = TaskTemplateUtil.getTemplateSubTypes(TaskUtil.ARDIUS_TASK_TEMPLATE);
		}

		if (!set_CustomerRevisionTicketIds.isEmpty()) {
			list_CustomerRevisionTicketsToBeUpdated = queryTickets(set_CustomerRevisionTicketIds, new List<Id>{ TaskUtil.ARDIUS_TICKET_RT_ID });
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Intitalize static variables during BEFORE context
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	private void initializeStaticVariables() {
		/*** All Static List variables ***/
		list_FeedItemsToInsert = new List<FeedItem>();
		list_CasesToInsert = new List<Case>();

		/*** All Static Map variables ***/
		map_AccountsToUpdate = new Map<Id, Account>();
		map_CasesToUpdate = new Map<Id, Case>();
		map_ContactsToUpdate = new Map<Id, Contact>();
		map_LeadsToUpdate = new Map<Id, Lead>();
		map_OpptysToUpdate = new Map<Id, Opportunity>();
		map_LeadRelatedTrackingsToUpsert = new Map<String, Lead_Related_Tracking__c>();
		map_AccountRelatedTrackingsToUpsert = new Map<String, Account_Related_Tracking__c>();
		map_CaseAuditLogsToUpsert = new Map<String, Case_Audit_Log__c>();
		map_TaskConversationIdToURLs = new Map<String, String>();
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Sets Default Values when Task is Inserted
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void setDefaultsOnCreate(Task objTask) {
		setLeadInfo(objTask);
		setOpportunityInfo(objTask);
		setNextBusinessDay(objTask);
		setBookedBy(objTask, null);
		setClosedDate(objTask);
		setOwnerPrefixedFields(objTask);
		setRelatedTicketStatus(objTask);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Sets Default Values when Task is Updated
	 * @Parm        : objTask - New Task
	 * @Parm        : objTask - Old Task
	 * @Return      : N/A
	 **/
	private void setDefaultsOnUpdate(Task objNewTask, Task objOldTask) {
		setLeadInfo(objNewTask);
		setOpportunityInfo(objNewTask);
		setNextBusinessDay(objNewTask);
		setClosedDate(objNewTask);
		setBookedBy(objNewTask, objOldTask);
		setClosedOwnerRole(objNewTask, objOldTask);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Checks if WhoId is Lead, then sets Lead__c
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setLeadInfo(Task objTask) {
		if (checkIfWhoIsLead(objTask)) {
			objTask.Lead__c = objTask.WhoId;
		}
	}
	/**
	 * @Author      :Sujan
	 * @Description : Checks if Profile is Tax Ops, then sets RecordType
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 * TODO - deprecate and replace with Cxone Incontact setting after managed package upgrade to version > 24.x . x
	 **/
	public void setRecordType(Task objTask) {
		if (queryPermissionSet() && objTask.Type == TaskUtil.TASK_TYPE_CALL && runningUserCallCenter() == TaskUtil.NICE_CXONE_CLASSIC) {
			objTask.RecordTypeId = TaskUtil.TASK_CALL_RT_ID;
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Checks if WhoId is Opportunity, then sets Opportunity__c
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setOpportunityInfo(Task objTask) {
		if (checkIfWhatIsOpportunity(objTask)) {
			objTask.Opportunity__c = objTask.WhatId;
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Checks if WhatId is Account
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhatIsAccount(Task objTask) {
		return objTask.WhatId != null && String.valueOf(objTask.WhatId).startsWithIgnoreCase(TaskUtil.ACCOUNT_PREFIX);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Checks if WhoId is Contact
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhoIsContact(Task objTask) {
		return objTask.WhoId != null && String.valueOf(objTask.WhoId).startsWithIgnoreCase(TaskUtil.CONTACT_PREFIX);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Checks if WhoId is Lead
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhoIsLead(Task objTask) {
		return objTask.WhoId != null && String.valueOf(objTask.WhoId).startsWithIgnoreCase(TaskUtil.LEAD_PREFIX);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Checks if WhatId is Opportunity
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhatIsOpportunity(Task objTask) {
		return objTask.WhatId != null && String.valueOf(objTask.WhatId).startsWithIgnoreCase(TaskUtil.OPPORTUNITY_PREFIX);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Checks if WhatId is Case
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public Boolean checkIfWhatIsCase(Task objTask) {
		return objTask.WhatId != null && String.valueOf(objTask.WhatId).startsWithIgnoreCase(TaskUtil.CASE_PREFIX);
	}

	/**
	 * @Author      : Ajay Krishna PU
	 * @Description : Checks if WhatId is Ticket
	 * @Parm        : objTask - New Task
	 * @Return      : true, if Task related to Ticket
	 **/
	public Boolean checkIfWhatIsTicket(Task objTask) {
		return objTask.WhatId != null && String.valueOf(objTask.WhatId).startsWithIgnoreCase(TaskUtil.TICKET_PREFIX);
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : Checks if WhatId is Ticket and subtype is Customer Revision Requested
	 * @Parm        : objTask - New Task
	 * @Return      : true, if Task related to Ticket and  subtype is Customer Revision Requested
	 **/
	public Boolean checkIfWhatIsTicketCustomerRevision(Task objTask) {
		return objTask.WhatId != null &&
			String.valueOf(objTask.WhatId).startsWithIgnoreCase(TaskUtil.TICKET_PREFIX) &&
			objTask.Subject == TaskUtil.TASK_SUBJECT_REQUESTED &&
			objTask.Status == TaskUtil.TASK_STATUS_COMPLETE;
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Sets Next_Business_Day__c based on current Date
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setNextBusinessDay(Task objTask) {
		objTask.Next_Business_Day__c = Utils.getNextBusinessDay();
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Sets Booked_By__c field if Task is created by MDR User
	 * @Parm        : objTask - New Task
	 * @Parm        : objTask - Old Task
	 * @Return      : N/A
	 **/
	public void setBookedBy(Task objNewTask, Task objOldTask) {
		if (objOldTask == null) {
			if (String.isNotBlank(strMDRRoleId) && UserInfo.getUserRoleId() == strMDRRoleId) {
				objNewTask.Booked_By__c = UserInfo.getUserId();
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Sets CloseDate__c as Current Time if type of the Task is Closed or Logged In User is Standard User.
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setClosedDate(Task objTask) {
		if (objTask.isClosed || UserInfo.getUserType().equalsIgnoreCase(TaskUtil.USER_TYPE_STANDARD)) {
			objTask.CloseDate__c = System.now();
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Sets Closed_Owner_Role__c with role of owner during task closure for historical user reporting
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setClosedOwnerRole(Task objNewTask, Task objOldTask) {
		if (objNewTask.Status != objOldTask.Status && !TaskUtil.set_TaskClosureStatus.contains(objOldTask.Status) && TaskUtil.set_TaskClosureStatus.contains(objNewTask.Status)) {
			objNewTask.Closed_Owner_Role__c = UserUtils.getUserRoleName(objNewTask.OwnerId);
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Creates new feed Items based on Task Description
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void createFeedItem(Task objTask) {
		String strProfileName = objCurrentUser?.Profile?.Name;
		if (
			String.isNotBlank(strProfileName) &&
			(strProfileName.equalsIgnoreCase(TaskUtil.USER_PROFILE_NAME_BENEFITS_CARE) ||
			strProfileName.equalsIgnoreCase(TaskUtil.USER_PROFILE_NAME_PAYROLL_CARE) ||
			strProfileName.equalsIgnoreCase(TaskUtil.USER_PROFILE_NAME_TAX_RES) ||
			strProfileName.equalsIgnoreCase(TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR))
		) {
			if (!objTask.Feed_Created__c && objTask.WhatId != null && String.isNotBlank(objTask.CallObject) && String.isNotBlank(objTask.Description)) {
				FeedItem objFeedItem = new FeedItem(
					ParentId = objTask.WhatId,
					Type = TaskUtil.FEED_ITEM_TYPE_TEXTPOST,
					Body = 'Call log ::\n' + objTask.Description,
					Visibility = TaskUtil.FEED_ITEM_VISIBILITY_ALLUSERS
				);

				list_FeedItemsToInsert.add(objFeedItem);
				objTask.Feed_Created__c = true;
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Update Duration Fields(Date Start and Date Completed) Related Fields
	 * @Parm        : objNewTask - New Task
	 * @Parm        : objOldTask - Old Task
	 * @Return      : N/A
	 **/
	public void updateDurationFields(Task objNewTask, Task objOldTask) {
		Boolean blnTaskClosed = isTaskClosed(objNewTask);

		if (objNewTask.Type != null) {
			if (objOldTask != null && objNewTask.Status == TaskUtil.TASK_STATUS_IN_PROGRESS && objOldTask.Status == TaskUtil.TASK_STATUS_COMPLETE) {
				resetTaskFields(objNewTask);
				objNewTask.Reopened__c = true;
				// objNewTask.Status_Detail__c = TaskUtil.TASK_STATUS_DETAIL_REOPENED;
			} else if (objNewTask.Status == TaskUtil.TASK_STATUS_NOT_STARTED) {
				resetTaskFields(objNewTask);
				objNewTask.Start_Date__c = null;
			} else if (blnTaskClosed && objNewTask.Start_Date__c == null) {
				objNewTask.Duration_in_Days__c = objNewTask.Duration_in_Hours__c = objNewTask.Duration_in_Minutes__c = null;
				objNewTask.Date_Completed__c = objNewTask.Start_Date__c = System.now();
			} else if (blnTaskClosed && objNewTask.Start_Date__c != null) {
				if (objNewTask.Date_Completed__c == null) {
					objNewTask.Date_Completed__c = System.now();
				}
				objNewTask.Duration_in_Days__c = Utils.getTimeStampDiff(objNewTask.Start_Date__c, objNewTask.Date_Completed__c, Utils.DAYS);
				objNewTask.Duration_in_Hours__c = Utils.getTimeStampDiff(objNewTask.Start_Date__c, objNewTask.Date_Completed__c, Utils.HOURS);
				objNewTask.Duration_in_Minutes__c = Utils.getTimeStampDiff(objNewTask.Start_Date__c, objNewTask.Date_Completed__c, Utils.MINUTES);
			} else if (!blnTaskClosed && objNewTask.Status != TaskUtil.TASK_STATUS_NOT_STARTED) {
				resetTaskFields(objNewTask);
				objNewTask.Start_Date__c = objNewTask.Start_Date__c == null ? System.now() : objNewTask.Start_Date__c;
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Sets Owner_* fields if an Owner exists for a task
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setOwnerPrefixedFields(Task objTask) {
		if (objTask.OwnerId != null && objCurrentUser != null) {
			objTask.Owner_Department__c = objCurrentUser.Department;
			objTask.Owner_Division__c = objCurrentUser.Division;
			objTask.Owner_Title__c = objCurrentUser.Title;
			//Closed Owner Role mapping for historical user reporting
			objTask.Closed_Owner_Role__c = UserUtils.getUserRoleName(objTask.OwnerId);
		}
	}

	/**
	 * @Author      : Ajay Krishna P U
	 * @Description : Sets Ticket Status If Task Related to a Ardius Ticket
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setRelatedTicketStatus(Task objTask) {
		if (checkIfWhatIsTicket(objTask) && map_Tickets?.containsKey(objTask.WhatId) == true) {
			objTask.Ticket_Status__c = map_Tickets.get(objTask.WhatId).Status__c;
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Reset Fields on Task to null
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void resetTaskFields(Task objTask) {
		objTask.Date_Completed__c = null;
		objTask.Duration_in_Days__c = objTask.Duration_in_Hours__c = objTask.Duration_in_Minutes__c = null;
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Set Case Information
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setCaseInformation(Task objTask) {
		if (String.isNotBlank(objTask.CallObject) && (objTask.WhatId == null || checkIfWhatIsCase(objTask)) && !checkIfWhoIsLead(objTask)) {
			if (map_ExternalIdToCaseAuditLogs.containsKey(objTask.CallObject)) {
				objTask.WhatId = map_ExternalIdToCaseAuditLogs.get(objTask.CallObject).Case__c;

				Case objCase = map_CasesToUpdate.containsKey(objTask.WhatId) ? map_CasesToUpdate.get(objTask.WhatId) : new Case(Id = objTask.WhatId);
				setAuthRelatedFieldsOnCase(objTask, objCase);
				map_CasesToUpdate.put(objCase.Id, objCase);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Populate Activity Dates on Lead, Account and Opportunity
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void populateActivityDatesOnAccLeadOpp(Task objNewTask, Task objOldTask) {
		if (
			String.isNotBlank(objNewTask.Type) &&
			String.isNotBlank(objNewTask.Status) &&
			map_Users.containsKey(objNewTask.OwnerId) &&
			String.isNotBlank(map_Users.get(objNewTask.OwnerId).UserRole?.Name)
		) {
			if (!isMarketoUser() && isTaskClosed(objNewTask)) {
				Account objAccount = map_Accounts.get(objNewTask.WhatId);
				Opportunity objOpportunity = map_Opportunities.get(objNewTask.WhatId);
				Lead objLead = map_Leads.get(objNewTask.WhoId);
				Contact objContact = map_Contacts.get(objNewTask.WhoId);

				String strOwnerRoleName = map_Users.get(objNewTask.OwnerId).UserRole?.Name;

				Boolean blnIsActivityDateChanged = objOldTask == null || objNewTask.ActivityDate != objOldTask.ActivityDate;
				Boolean blnIsStatusChanged = objOldTask == null || objNewTask.Status != objOldTask.Status;
				Boolean blnIsTypeChanged = objOldTask == null || objNewTask.Type != objOldTask.Type;

				// Account Update
				if (objAccount != null) {
					Boolean blnAccntUpdate = false;

					// Update Last Activity Type
					if (String.isBlank(objAccount.Last_Activity_Type__c) || objAccount.Last_Activity_Type__c != objNewTask.Type) {
						objAccount.Last_Activity_Type__c = objNewTask.Type;
						blnAccntUpdate = true;
					}

					if (objNewTask.Type != TaskUtil.TASK_TYPE_AUTOMATED_MAIL) {
						// Update Last Sales Activity Type
						if (
							String.isNotBlank(strOwnerRoleName) &&
							strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES) &&
							(String.isBlank(objAccount.Last_Sales_Activity_Type__c) || objAccount.Last_Sales_Activity_Type__c != objNewTask.Type)
						) {
							objAccount.Last_Sales_Activity_Type__c = objNewTask.Type;
							blnAccntUpdate = true;
						}

						// Update Last Activity Date
						if (
							objAccount.Last_Activity_Date__c == null ||
							objAccount.Last_Activity_Date__c != objNewTask.ActivityDate && (blnIsActivityDateChanged || blnIsStatusChanged || blnIsTypeChanged)
						) {
							objAccount.Last_Activity_Date__c = objNewTask.ActivityDate;
							blnAccntUpdate = true;
						}
						//Update reseller account of the company account -
						//If a call task is created new OR activity date/status/type is updated and activity date is latest
						if (
							(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
							(blnIsActivityDateChanged ||
							blnIsStatusChanged ||
							blnIsTypeChanged) &&
							objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
							(String.isNotBlank(strOwnerRoleName) && (strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC) || strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES))) &&
							objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
							objAccount.Sold_By__c != null &&
							(objAccount.Sold_By__r.Last_Activity_Date__c == null ||
							objAccount.Sold_By__r.Last_Activity_Date__c < objNewTask.ActivityDate)
						) {
							Account objResellerAccountToUpdate = new Account(Id = objAccount.Sold_By__c, Last_Activity_Date__c = objNewTask.ActivityDate);
							if (map_AccountsToUpdate.containsKey(objResellerAccountToUpdate.Id)) {
								objResellerAccountToUpdate = map_AccountsToUpdate.get(objResellerAccountToUpdate.Id);
								objResellerAccountToUpdate.Last_Activity_Date__c = objNewTask.ActivityDate;
								map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
							} else {
								map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
							}
						}

						if (
							(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
							objNewTask.Status == TaskUtil.TASK_STATUS_CONNECT &&
							(blnIsActivityDateChanged ||
							blnIsStatusChanged ||
							blnIsTypeChanged) &&
							objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
							(String.isNotBlank(strOwnerRoleName) && (strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC) || strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES))) &&
							objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
							objAccount.Sold_By__c != null &&
							(objAccount.Sold_By__r.Last_Call_Connect__c == null ||
							objAccount.Sold_By__r.Last_Call_Connect__c < objNewTask.ActivityDate)
						) {
							Account objResellerAccountToUpdate = new Account(Id = objAccount.Sold_By__c, Last_Call_Connect__c = objNewTask.ActivityDate);
							if (map_AccountsToUpdate.containsKey(objResellerAccountToUpdate.Id)) {
								objResellerAccountToUpdate = map_AccountsToUpdate.get(objResellerAccountToUpdate.Id);
								objResellerAccountToUpdate.Last_Call_Connect__c = objNewTask.ActivityDate;
								map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
							} else {
								map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
							}
						}
					}

					// Update Last Account Activity Date
					if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							(objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_CALL) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_PITCH) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_DEMO))
						) {
							if (objAccount.Last_Account_Activity_Date__c == null || objAccount.Last_Account_Activity_Date__c != objNewTask.ActivityDate) {
								objAccount.Last_Account_Activity_Date__c = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}

							if (objAccount.Last_Rep_Activity_Date_New__c == null || objAccount.Last_Rep_Activity_Date_New__c != objNewTask.ActivityDate) {
								objAccount.Last_Rep_Activity_Date_New__c = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}
						}
					}

					if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							objNewTask.Type.containsIgnoreCase(TaskUtil.TASK_TYPE_EMAIL) &&
							String.isNotBlank(objNewTask.Subject) &&
							objNewTask.Subject.startsWithIgnoreCase(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
						) {
							if (objAccount.Last_Account_Activity_Date__c == null || objAccount.Last_Account_Activity_Date__c != objNewTask.ActivityDate) {
								objAccount.Last_Account_Activity_Date__c = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}
						}
					}

					if (blnAccntUpdate) {
						map_AccountsToUpdate.put(objAccount.Id, objAccount);
					}
				}

				// Account Update if WhoId is Contact
				if (objContact != null && objContact.AccountId != null) {
					Boolean blnAccntUpdate = false;
					Date dtLastAccountActivityDate;
					Date dtLastAccountActivityDateNew;

					// Update Related Account Last Activity Date
					if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							(objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_CALL) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_PITCH) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_DEMO))
						) {
							if (objContact.Account.Last_Account_Activity_Date__c == null || objContact.Account.Last_Account_Activity_Date__c != objNewTask.ActivityDate) {
								dtLastAccountActivityDate = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}

							if (objContact.Account.Last_Rep_Activity_Date_New__c == null || objContact.Account.Last_Rep_Activity_Date_New__c != objNewTask.ActivityDate) {
								dtLastAccountActivityDateNew = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}
						}
					} else if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							objNewTask.Type.containsIgnoreCase(TaskUtil.TASK_TYPE_EMAIL) &&
							String.isNotBlank(objNewTask.Subject) &&
							objNewTask.Subject.startsWithIgnoreCase(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
						) {
							if (objContact.Account.Last_Account_Activity_Date__c == null || objContact.Account.Last_Account_Activity_Date__c != objNewTask.ActivityDate) {
								dtLastAccountActivityDate = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}
						}
					}

					if (blnAccntUpdate) {
						Account objAcc = map_AccountsToUpdate.containsKey(objContact.AccountId) ? map_AccountsToUpdate.get(objContact.AccountId) : new Account(Id = objContact.AccountId);

						objAcc.Last_Account_Activity_Date__c = dtLastAccountActivityDate != null ? dtLastAccountActivityDate : objAcc.Last_Account_Activity_Date__c;
						objAcc.Last_Rep_Activity_Date_New__c = dtLastAccountActivityDateNew != null ? dtLastAccountActivityDateNew : objAcc.Last_Rep_Activity_Date_New__c;
						map_AccountsToUpdate.put(objAcc.Id, objAcc);
					}

					//Update reseller account of contact when the contact is related directly or via a company account.
					//If a call task is created new OR activity date/status/type is updated and activity date is latest
					if (
						objNewTask.Type != TaskUtil.TASK_TYPE_AUTOMATED_MAIL &&
						objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME &&
						(blnIsActivityDateChanged ||
						blnIsStatusChanged ||
						blnIsTypeChanged) &&
						objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
						(String.isNotBlank(strOwnerRoleName) && (strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC) || strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES)))
					) {
						if (objNewTask.WhatId == null) {
							Account objResellerAccountToUpdate;
							if (
								objContact.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
								objContact.Account.Sold_By__c != null &&
								(objContact.Account.Sold_By__r.Last_Activity_Date__c == null ||
								objContact.Account.Sold_By__r.Last_Activity_Date__c < objNewTask.ActivityDate)
							) {
								objResellerAccountToUpdate = new Account(Id = objContact.Account.Sold_By__c, Last_Activity_Date__c = objNewTask.ActivityDate);
							} else if (
								objContact.Account.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
								(objContact.Account.Last_Activity_Date__c == null ||
								objContact.Account.Last_Activity_Date__c < objNewTask.ActivityDate)
							) {
								objResellerAccountToUpdate = new Account(Id = objContact.AccountId, Last_Activity_Date__c = objNewTask.ActivityDate);
							}
							if (objResellerAccountToUpdate != null) {
								if (map_AccountsToUpdate.containsKey(objResellerAccountToUpdate.Id)) {
									objResellerAccountToUpdate = map_AccountsToUpdate.get(objResellerAccountToUpdate.Id);
									objResellerAccountToUpdate.Last_Activity_Date__c = objNewTask.ActivityDate;
									map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
								} else {
									map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
								}
							}
						}
						if (objContact.Last_Contact_Activity__c == null || objContact.Last_Contact_Activity__c < objNewTask.ActivityDate) {
							objContact.Last_Contact_Activity__c = objNewTask.ActivityDate;
							if (map_ContactsToUpdate.containsKey(objContact.Id)) {
								map_ContactsToUpdate.get(objContact.Id).Last_Contact_Activity__c = objNewTask.ActivityDate;
							} else {
								map_ContactsToUpdate.put(objContact.Id, new Contact(Id = objContact.Id, Last_Contact_Activity__c = objNewTask.ActivityDate));
							}
						}
					}

					if (
						objNewTask.Type != TaskUtil.TASK_TYPE_AUTOMATED_MAIL &&
						objNewTask.Status == TaskUtil.TASK_STATUS_CONNECT &&
						objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME &&
						(blnIsActivityDateChanged ||
						blnIsStatusChanged ||
						blnIsTypeChanged) &&
						objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
						(String.isNotBlank(strOwnerRoleName) && (strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC) || strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES)))
					) {
						if (objNewTask.WhatId == null) {
							Account objResellerAccountToUpdate;
							if (
								objContact.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
								objContact.Account.Sold_By__c != null &&
								(objContact.Account.Sold_By__r.Last_Call_Connect__c == null ||
								objContact.Account.Sold_By__r.Last_Call_Connect__c < objNewTask.ActivityDate)
							) {
								objResellerAccountToUpdate = new Account(Id = objContact.Account.Sold_By__c, Last_Call_Connect__c = objNewTask.ActivityDate);
							} else if (
								objContact.Account.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
								(objContact.Account.Last_Call_Connect__c == null ||
								objContact.Account.Last_Call_Connect__c < objNewTask.ActivityDate)
							) {
								objResellerAccountToUpdate = new Account(Id = objContact.AccountId, Last_Call_Connect__c = objNewTask.ActivityDate);
							}
							if (objResellerAccountToUpdate != null) {
								if (map_AccountsToUpdate.containsKey(objResellerAccountToUpdate.Id)) {
									objResellerAccountToUpdate = map_AccountsToUpdate.get(objResellerAccountToUpdate.Id);
									objResellerAccountToUpdate.Last_Call_Connect__c = objNewTask.ActivityDate;
									map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
								} else {
									map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
								}
							}
						}
						if (objContact.Last_Contact_Connect__c == null || objContact.Last_Contact_Connect__c < objNewTask.ActivityDate) {
							objContact.Last_Contact_Connect__c = objNewTask.ActivityDate;
							if (map_ContactsToUpdate.containsKey(objContact.Id)) {
								map_ContactsToUpdate.get(objContact.Id).Last_Contact_Connect__c = objNewTask.ActivityDate;
							} else {
								map_ContactsToUpdate.put(objContact.Id, new Contact(Id = objContact.Id, Last_Contact_Connect__c = objNewTask.ActivityDate));
							}
						}
					}
				}

				// Account Update if WhatId is Opportunity
				if (objOpportunity != null && objOpportunity.AccountId != null) {
					Boolean blnAccntUpdate = false;
					Date dtLastAccountActivityDate;
					Date dtLastAccountActivityDateNew;

					// Update Related Account Last Activity Date

					if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							(objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_CALL) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_PITCH) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_DEMO))
						) {
							if (objOpportunity.Account.Last_Account_Activity_Date__c == null || objOpportunity.Account.Last_Account_Activity_Date__c != objNewTask.ActivityDate) {
								dtLastAccountActivityDate = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}

							if (objOpportunity.Account.Last_Rep_Activity_Date_New__c == null || objOpportunity.Account.Last_Rep_Activity_Date_New__c != objNewTask.ActivityDate) {
								dtLastAccountActivityDateNew = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}
						}
					} else if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							objNewTask.Type.containsIgnoreCase(TaskUtil.TASK_TYPE_EMAIL) &&
							String.isNotBlank(objNewTask.Subject) &&
							objNewTask.Subject.startsWithIgnoreCase(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
						) {
							if (objOpportunity.Account.Last_Account_Activity_Date__c == null || objOpportunity.Account.Last_Account_Activity_Date__c != objNewTask.ActivityDate) {
								dtLastAccountActivityDate = objNewTask.ActivityDate;
								blnAccntUpdate = true;
							}
						}
					}

					if (blnAccntUpdate) {
						Account objAcc = map_AccountsToUpdate.containsKey(objOpportunity.AccountId) ? map_AccountsToUpdate.get(objOpportunity.AccountId) : new Account(Id = objOpportunity.AccountId);

						objAcc.Last_Account_Activity_Date__c = dtLastAccountActivityDate != null ? dtLastAccountActivityDate : objAcc.Last_Account_Activity_Date__c;
						objAcc.Last_Rep_Activity_Date_New__c = dtLastAccountActivityDateNew != null ? dtLastAccountActivityDateNew : objAcc.Last_Rep_Activity_Date_New__c;
						map_AccountsToUpdate.put(objAcc.Id, objAcc);
					}
				}

				// Opportunity Update
				if (objOpportunity != null) {
					Boolean blnOpptyUpdate = false;

					if (objNewTask.Type != TaskUtil.TASK_TYPE_AUTOMATED_MAIL) {
						if ((objOpportunity.Last_Activity_Date__c == null || objOpportunity.Last_Activity_Date__c < objNewTask.ActivityDate) && (blnIsActivityDateChanged || blnIsTypeChanged)) {
							objOpportunity.Last_Activity_Date__c = objNewTask.ActivityDate;
							blnOpptyUpdate = true;
						}
					}
					//Update reseller account of opportunity if a call task is created new on opportunity OR activity date/status/type is updated and activity date is latest
					if (
						objNewTask.Type != TaskUtil.TASK_TYPE_AUTOMATED_MAIL &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						(blnIsActivityDateChanged ||
						blnIsStatusChanged ||
						blnIsTypeChanged) &&
						objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
						(String.isNotBlank(strOwnerRoleName) && (strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC) || strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES))) &&
						objOpportunity.Account?.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objOpportunity.Account.Sold_By__c != null &&
						(objOpportunity.Account.Sold_By__r.Last_Activity_Date__c == null ||
						objOpportunity.Account.Sold_By__r.Last_Activity_Date__c < objNewTask.ActivityDate)
					) {
						Account objResellerAccountToUpdate = new Account(Id = objOpportunity.Account.Sold_By__c, Last_Activity_Date__c = objNewTask.ActivityDate);
						if (map_AccountsToUpdate.containsKey(objResellerAccountToUpdate.Id)) {
							objResellerAccountToUpdate = map_AccountsToUpdate.get(objResellerAccountToUpdate.Id);
							objResellerAccountToUpdate.Last_Activity_Date__c = objNewTask.ActivityDate;
							map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
						} else {
							map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
						}
					}
					if (
						objNewTask.Type != TaskUtil.TASK_TYPE_AUTOMATED_MAIL &&
						objNewTask.Status == TaskUtil.TASK_STATUS_CONNECT &&
						(objContact == null || (objContact != null && objContact.RecordType.Name == ContactUtil.RESELLER_RT_NAME)) &&
						(blnIsActivityDateChanged ||
						blnIsStatusChanged ||
						blnIsTypeChanged) &&
						objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
						(String.isNotBlank(strOwnerRoleName) && (strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC) || strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES))) &&
						objOpportunity.Account?.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objOpportunity.Account.Sold_By__c != null &&
						(objOpportunity.Account.Sold_By__r.Last_Call_Connect__c == null ||
						objOpportunity.Account.Sold_By__r.Last_Call_Connect__c < objNewTask.ActivityDate)
					) {
						Account objResellerAccountToUpdate = new Account(Id = objOpportunity.Account.Sold_By__c, Last_Call_Connect__c = objNewTask.ActivityDate);
						if (map_AccountsToUpdate.containsKey(objResellerAccountToUpdate.Id)) {
							objResellerAccountToUpdate = map_AccountsToUpdate.get(objResellerAccountToUpdate.Id);
							objResellerAccountToUpdate.Last_Call_Connect__c = objNewTask.ActivityDate;
							map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
						} else {
							map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
						}
					}

					if (
						objNewTask.ActivityDate != null &&
						objNewTask.Status == TaskUtil.TASK_STATUS_CONNECT &&
						(objOpportunity.Last_Call_Connect__c == null ||
						objNewTask.ActivityDate >= objOpportunity.Last_Call_Connect__c)
					) {
						objOpportunity.Last_Call_Connect__c = objNewTask.ActivityDate;
						blnOpptyUpdate = true;

						// update last call connect on account if last call connect on opportunity is updated
						if (
							(objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
							objOpportunity.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) &&
							objOpportunity.AccountId != null &&
							(objOpportunity.Account.Last_Call_Connect__c == null ||
							objOpportunity.Last_Call_Connect__c > objOpportunity.Account.Last_Call_Connect__c)
						) {
							// get account from map of accounts to update
							Account objAcc = map_AccountsToUpdate.containsKey(objOpportunity.AccountId)
								? map_AccountsToUpdate.get(objOpportunity.AccountId)
								: new Account(Id = objOpportunity.AccountId);

							// set last call connect on account the same as last call connect on opportunity
							objAcc.Last_Call_Connect__c = objOpportunity.Last_Call_Connect__c;
							// add it to list of accounts to be updated
							map_AccountsToUpdate.put(objAcc.Id, objAcc);
						}
					}

					if (
						objNewTask.ActivityDate != null &&
						(objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID ||
						objNewTask.RecordTypeId == TaskUtil.TASK_DEMO_PITCH_RT_ID) &&
						(objOpportunity.Last_Call__c == null ||
						objNewTask.ActivityDate >= objOpportunity.Last_Call__c)
					) {
						objOpportunity.Last_Call__c = objNewTask.ActivityDate;
						blnOpptyUpdate = true;
					}

					if (blnOpptyUpdate) {
						map_OpptysToUpdate.put(objOpportunity.Id, objOpportunity);
					}
				}

				// Lead Update
				if (objLead != null) {
					Boolean blnLeadUpdate = false;

					// Update Last Rep Activity Date
					if (objNewTask.Type != TaskUtil.TASK_TYPE_AUTOMATED_MAIL) {
						if (objLead.Last_Rep_Activity_Date__c == null && objNewTask.ActivityDate != null && (blnIsActivityDateChanged || blnIsTypeChanged)) {
							objLead.Last_Rep_Activity_Date__c = objNewTask.ActivityDate;
							blnLeadUpdate = true;
						}
					}

					// Update Last Call Connect
					if (
						objNewTask.ActivityDate != null &&
						objNewTask.Status == TaskUtil.TASK_STATUS_CONNECT &&
						(objLead.Last_Call_Connect__c == null ||
						objNewTask.ActivityDate >= objLead.Last_Call_Connect__c)
					) {
						objLead.Last_Call_Connect__c = objNewTask.ActivityDate;
						blnLeadUpdate = true;
					}

					// Update Last Call
					if (
						objNewTask.ActivityDate != null &&
						(objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID ||
						objNewTask.RecordTypeId == TaskUtil.TASK_DEMO_PITCH_RT_ID) &&
						(objLead.Last_Call__c == null ||
						objNewTask.ActivityDate >= objLead.Last_Call__c)
					) {
						objLead.Last_Call__c = objNewTask.ActivityDate;
						blnLeadUpdate = true;
					}

					// Update Last Lead Activity Date
					if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_SALES)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							(objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_CALL) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_PITCH) ||
							objNewTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_DEMO))
						) {
							if (objLead.Last_Lead_Activity_Date__c == null || objLead.Last_Lead_Activity_Date__c != objNewTask.ActivityDate) {
								objLead.Last_Lead_Activity_Date__c = objNewTask.ActivityDate;
								blnLeadUpdate = true;
							}

							if (objLead.Last_Rep_Activity_Date_New__c == null || objLead.Last_Rep_Activity_Date_New__c != objNewTask.ActivityDate) {
								objLead.Last_Rep_Activity_Date_New__c = objNewTask.ActivityDate;
								blnLeadUpdate = true;
							}
						}
					}

					if (String.isNotBlank(strOwnerRoleName) && strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_EXEC)) {
						if (
							String.isNotBlank(objNewTask.Type) &&
							objNewTask.Type.containsIgnoreCase(TaskUtil.TASK_TYPE_EMAIL) &&
							String.isNotBlank(objNewTask.Subject) &&
							objNewTask.Subject.startsWithIgnoreCase(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM)
						) {
							if (objLead.Last_Lead_Activity_Date__c == null || objLead.Last_Lead_Activity_Date__c != objNewTask.ActivityDate) {
								objLead.Last_Lead_Activity_Date__c = objNewTask.ActivityDate;
								blnLeadUpdate = true;
							}
						}
					}

					if (blnLeadUpdate) {
						map_LeadsToUpdate.put(objLead.Id, objLead);
					}
				}
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Set Auth Fields on Case
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void setAuthRelatedFieldsOnCase(Task objTask, Case objCase) {
		if (String.isNotBlank(objTask.NumberOfAuthTries__c)) {
			objCase.NumberOfAuthTries__c = objTask.NumberOfAuthTries__c;
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Parse Task object and set case and opportunity field value.
	 * @Parm        : Object of Task
	 * @Return      : N/A
	 **/
	public void setCaseAndOpportunityIds(Task objTask) {
		if (objTask.RecordTypeId == TaskUtil.TASK_ADVISING_CALL_RT_ID) {
			if (checkIfWhatIsOpportunity(objTask)) {
				objTask.Opportunity__c = objTask.WhatId;
			} else if (objTask.WhatId != null && checkIfWhatIsCase(objTask)) {
				objTask.Case__c = objTask.WhatId;
			} else if (objTask.WhatId == null && objTask.Case__c != null) {
				objTask.WhatId = objTask.Case__c;
			}

			if (map_CaseIdWithOpportunityIds.containsKey(objTask.WhatId)) {
				objTask.Opportunity__c = map_CaseIdWithOpportunityIds.get(objTask.WhatId);
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Query on Task record.
	 * @Parm        : Id of Task RecordType
	 				: Set of Opportunity Ids
					: Set of Case Ids
	 * @Return      : List of Task records
	 **/
	public List<Task> queryTask(Id idRecordType, Set<Id> set_OppIds, Set<Id> set_CaseIds) {
		return [
			SELECT Id, Opportunity__c, Case__c
			FROM Task
			WHERE RecordTypeId = :idRecordType AND ((Opportunity__c != NULL AND Opportunity__c IN :set_OppIds) OR (Case__c != NULL AND Case__c IN :set_CaseIds)) AND Case__r.IsClosed = FALSE
			WITH SECURITY_ENFORCED
		];
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Count total Advising-Touchpoints, related to Opportunity and Case.
	 * @Parm        : Object of Task
	 * @Return      : N/A
	 **/
	public void calculateAdvisingTouchpoints() {
		if (set_CaseIdsWithAdvisingCalls.size() > 0 || set_OppIdsWithAdvisingCalls.size() > 0) {
			Id idCaseAdvisingCallRT = TaskUtil.TASK_ADVISING_CALL_RT_ID;
			Map<Id, Integer> map_OppAndTaskCount = new Map<Id, Integer>();
			Map<Id, Integer> map_CaseAndTaskCount = new Map<Id, Integer>();
			Integer intRecordCount = 0;

			for (Id idOpp : set_OppIdsWithAdvisingCalls) {
				map_OppAndTaskCount.put(idOpp, 0);
			}

			for (Id idOpp : set_CaseIdsWithAdvisingCalls) {
				map_CaseAndTaskCount.put(idOpp, 0);
			}

			for (Task objTask : queryTask(idCaseAdvisingCallRT, set_OppIdsWithAdvisingCalls, set_CaseIdsWithAdvisingCalls)) {
				intRecordCount = 0;
				if (objTask.Opportunity__c != null) {
					if (map_OppAndTaskCount.containsKey(objTask.Opportunity__c)) {
						intRecordCount = map_OppAndTaskCount.get(objTask.Opportunity__c);
					}

					intRecordCount = intRecordCount + 1;
					map_OppAndTaskCount.put(objTask.Opportunity__c, intRecordCount);
				}

				intRecordCount = 0;
				if (objTask.Case__c != null) {
					if (map_CaseAndTaskCount.containsKey(objTask.Case__c)) {
						intRecordCount = map_CaseAndTaskCount.get(objTask.Case__c);
					}

					intRecordCount = intRecordCount + 1;
					map_CaseAndTaskCount.put(objTask.Case__c, intRecordCount);
				}
			}

			for (Id idOpportunity : map_OppAndTaskCount.keySet()) {
				Opportunity objOpp = map_OpptysToUpdate.containsKey(idOpportunity) ? map_OpptysToUpdate.get(idOpportunity) : new Opportunity(Id = idOpportunity);
				objOpp.Advising_Touchpoints__c = map_OppAndTaskCount.get(idOpportunity);
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			for (Id idCase : map_CaseAndTaskCount.keySet()) {
				Case objCase = map_CasesToUpdate.containsKey(idCase) ? map_CasesToUpdate.get(idCase) : new Case(Id = idCase);
				objCase.Advising_Touchpoints__c = map_CaseAndTaskCount.get(idCase);
				map_CasesToUpdate.put(objCase.Id, objCase);
			}
		}
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Prevents NICE to overwrite certain task fields for outbound phone calls.
	 * @Parm        : new task, old task
	 * @Return      : NA
	 **/
	private void processNICETasks(Task objNewTask, Task objOldTask) {
		if (String.isNotBlank(objOldTask.Genesys_Interaction_Id__c) && String.isNotBlank(objOldTask.Type) && objOldTask.Type != TaskUtil.TASK_TYPE_CALL) {
			objNewTask.Type = objOldTask.Type;
			objNewTask.Status = objOldTask.Status;
			objNewTask.Priority = objOldTask.Priority;
			objNewTask.CallDisposition = objOldTask.CallDisposition;
			objNewTask.RecordTypeId = TaskUtil.TASK_CALL_RT_ID;
		}
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Sets Record Type to Call for NICE activities.
	 * @Parm        : new task
	 * @Return      : NA
	 **/
	private void populateNICERecordType(Task objNewTask) {
		if (String.isNotBlank(objNewTask.Genesys_Interaction_Id__c)) {
			objNewTask.RecordTypeId = TaskUtil.TASK_CALL_RT_ID;
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Set NBA fields on Lead or Opportunity to Task if record is served within the last 1 hour
	 * @Parm        : New task from trigger context
	 **/
	private void setNBAFieldsOnTask(Task objNewTask) {
		Integer intThresholdMinutes = System.Label.NBA_Task_Automation_Threshold_Minutes != null ? Integer.valueOf(System.Label.NBA_Task_Automation_Threshold_Minutes) : 60;
		String strNBATaskTypes = System.Label.NBA_Task_Types;
		// Set NBA fields only for Call Tasks
		if (objNewTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID && String.isNotBlank(strNBATaskTypes) && String.isNotBlank(objNewTask.Type) && strNBATaskTypes.containsIgnoreCase(objNewTask.Type)) {
			if (checkIfWhoIsLead(objNewTask)) {
				if (map_Leads.containsKey(objNewTask.WhoId)) {
					Lead objLead = map_Leads.get(objNewTask.WhoId);
					// check if record is served through NBA
					if (objLead.Served_Up_Time__c != null && String.isNotBlank(objLead.Served_Up_Rule__c) && objLead.Served_Up_Time__c <= System.now()) {
						Integer intMinutes = Utils.getTimeStampDiff(objLead.Served_Up_Time__c, System.now(), Utils.MINUTES);
						// If record is served within last 60 minutes (configurable), copy over NBA fields from Lead to Task
						if (intMinutes < intThresholdMinutes) {
							objNewTask.Served_Up_Time__c = objLead.Served_Up_Time__c;
							objNewTask.Served_Other_Rules__c = objLead.Served_Other_Rules__c;
							objNewTask.Served_Up_Rule__c = objLead.Served_Up_Rule__c;
						}
					}
				}
			} else if (checkIfWhatIsOpportunity(objNewTask)) {
				if (map_Opportunities.containsKey(objNewTask.WhatId)) {
					Opportunity objOppty = map_Opportunities.get(objNewTask.WhatId);
					// check if record is served through NBA and served up time is in the future
					if (objOppty.Served_Up_Time__c != null && String.isNotBlank(objOppty.Served_Up_Rule__c) && objOppty.Served_Up_Time__c <= System.now()) {
						Integer intMinutes = Utils.getTimeStampDiff(objOppty.Served_Up_Time__c, System.now(), Utils.MINUTES);
						// If record is served within last 60 minutes (configurable), copy over NBA fields from Opportunity to Task
						if (intMinutes < intThresholdMinutes) {
							objNewTask.Served_Up_Time__c = objOppty.Served_Up_Time__c;
							objNewTask.Served_Other_Rules__c = objOppty.Served_Other_Rules__c;
							objNewTask.Served_Up_Rule__c = objOppty.Served_Up_Rule__c;
						}
					}
				}
			}
		}
	}

	/**
	 * @Author      : Jayesh Gawande
	 * @Description : Set Owner_Assigned_as_User__c Date/Time on Task if record is owned by User.
	 * @param objNewTask The new version of Task
	 * @param objOldTask The old Version of task
	 **/
	private void setOwnerAssignedToTaskTime(Task objNewTask, Task objOldTask) {
		Boolean blnIsInsert = objOldTask == null;

		if (String.valueOf(objNewTask.OwnerId).startsWithIgnoreCase(TaskUtil.USER_PREFIX) && (blnIsInsert || objNewTask.OwnerId != objOldTask.OwnerId)) {
			objNewTask.Owner_Assigned_as_User__c = System.now();
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Check if Task is Related to a Lead,
	 * 				  Creates or updates existing Lead Related Tracking Record
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void upsertLeadRelatedTrackingRec(Task objTask) {
		if (checkIfWhoIsLead(objTask)) {
			Lead_Related_Tracking__c objLeadRelTrack = map_LeadRelatedTrackingsToUpsert.containsKey(objTask.WhoId)
				? map_LeadRelatedTrackingsToUpsert.get(objTask.WhoId)
				: new Lead_Related_Tracking__c();

			objLeadRelTrack.Lead__c = objTask.WhoId;
			objLeadRelTrack.Unique_Lead_Id__c = objTask.WhoId;

			if (!map_LeadIdToTracking.containsKey(objTask.WhoId)) {
				objLeadRelTrack.Created_At__c = System.now();
			}

			if (String.isNotBlank(objLeadRelTrack.Unique_Lead_Id__c)) {
				map_LeadRelatedTrackingsToUpsert.put(objLeadRelTrack.Unique_Lead_Id__c, objLeadRelTrack);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Update MDR First Call Date is updated on LRT if Lead is MQL and Owned by MDR
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public void updateMQLDateOnLeadRelatedTracking(Task objTask) {
		if (checkIfWhoIsLead(objTask) && String.isNotBlank(objTask.Status) && TaskUtil.set_TaskStatusLeadRelatedTracking.contains(objTask.Status) && map_LeadIdToTracking.containsKey(objTask.WhoId)) {
			Lead_Related_Tracking__c objLeadTrack = map_LeadIdToTracking.get(objTask.WhoId);
			String strLeadOwnerRoleName = objLeadTrack?.Lead__r?.Owner_Role_Formula__c;
			String strLeadStatus = objLeadTrack?.Lead__r?.Status;
			Set<String> set_UserRoles = new Set<String>{
				TaskUtil.USER_ROLE_NAME_SALES_SDR_MM_MGR_XX,
				TaskUtil.USER_ROLE_NAME_SALES_SDR_MM_XX,
				TaskUtil.USER_ROLE_NAME_SALES_BDR_XX_XX,
				TaskUtil.USER_ROLE_NAME_SALES_SDR_PARTNER_MGR_XX,
				TaskUtil.USER_ROLE_NAME_SALES_SDR_PARTNER_XX,
				TaskUtil.USER_ROLE_NAME_SALES_MDR_XX_XX
			};
			if (
				String.isNotBlank(strLeadOwnerRoleName) &&
				String.isNotBlank(strLeadStatus) &&
				set_UserRoles.contains(strLeadOwnerRoleName) &&
				strLeadStatus.equalsIgnoreCase(LeadUtil.LEAD_STATUS_MQL) &&
				objLeadTrack.MDR_First_Call_Date__c == null
			) {
				objLeadTrack = map_LeadRelatedTrackingsToUpsert.containsKey(objTask.WhoId) ? map_LeadRelatedTrackingsToUpsert.get(objTask.WhoId) : objLeadTrack;
				objLeadTrack.MDR_First_Call_Date__c = System.now();

				if (String.isNotBlank(objLeadTrack.Unique_Lead_Id__c)) {
					map_LeadRelatedTrackingsToUpsert.put(objLeadTrack.Unique_Lead_Id__c, objLeadTrack);
				}
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : If Task is Related to Account, Upsert Account Related Tracking Record
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void upsertAccountRelatedTrackingRec(Task objTask) {
		if (objTask.AccountId != null) {
			map_AccountRelatedTrackingsToUpsert.put(objTask.AccountId, new Account_Related_Tracking__c(Account__c = objTask.AccountId, Unique_Account_Id__c = objTask.AccountId));
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Update Date Time Submitted, Callback and Date Time End on Case
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void updateCaseCallbackFromTask(Task objTask) {
		if (
			String.isNotBlank(objTask.Type) &&
			objTask.Type == TaskUtil.TASK_TYPE_INBOUND_CALL &&
			String.isNotBlank(objTask.Status) &&
			(objTask.Status == TaskUtil.TASK_STATUS_CONNECT ||
			objTask.Status == TaskUtil.TASK_STATUS_VOICEMAIL) &&
			String.isNotBlank(objTask.CallObject) &&
			map_CaseGenesysCallIdToCase.containsKey(objTask.CallObject)
		) {
			Case objCase = map_CaseGenesysCallIdToCase.get(objTask.CallObject);
			objCase = map_CasesToUpdate.containsKey(objCase.Id) ? map_CasesToUpdate.get(objCase.Id) : objCase;

			objCase.Date_Time_Submitted__c = objTask.CreatedDate;
			if (objTask.CallDurationInSeconds != null) {
				objCase.Date_Time_End__c = objTask.CreatedDate.addSeconds(objTask.CallDurationInSeconds);
			}

			if (String.isNotBlank(objTask.Subject) && objTask.Subject.containsIgnoreCase(TaskUtil.TASK_SUBJECT_CALLBACK)) {
				objCase.Callback__c = true;
			}

			map_CasesToUpdate.put(objCase.Id, objCase);
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Update Lead Initiated & Form Submitted Date
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void setLeadInitiatedDateAndFormSubmitDate(Task objTask) {
		if (
			checkIfWhoIsLead(objTask) &&
			(String.isNotBlank(objTask.Subject) &&
			objTask.Subject.containsIgnoreCase(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM) &&
			!objTask.Subject.containsIgnoreCase(TaskUtil.TASK_SUBJECT_BUYERZONE_BLIND_FORM_SUBMIT)) ||
			(objTask.Case__c != null) ||
			(objTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID && objTask.Status == TaskUtil.TASK_STATUS_CONNECT) && map_Leads.containsKey(objTask.WhoId)
		) {
			Boolean blnLeadUpdate = false;
			List<DateTime> list_minDates;
			Lead objLead = map_Leads.get(objTask.WhoId);

			if (objLead != null && objLead.Lead_Initiated_Date__c == null) {
				if (objLead.Lead_Creation_Offer__c == LeadUtil.LEADCREATION_OFFER_LIST_UPL) {
					list_minDates = new List<DateTime>();
					if (objLead.Account_Created_Date__c != null) {
						//Account created date
						list_minDates.add(objLead.Account_Created_Date__c);
					}
					if (objLead.ConvertedDate != null) {
						//Lead Converted Date
						list_minDates.add(objLead.ConvertedDate);
					}

					// Form filled out & Chat activity & Phone Activity
					for (Task objLeadTask : objLead.Tasks) {
						if (
							(String.isNotBlank(objLeadTask.Subject) &&
							objLeadTask.Subject.containsIgnoreCase(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM) &&
							!objLeadTask.Subject.containsIgnoreCase(TaskUtil.TASK_SUBJECT_BUYERZONE_BLIND_FORM_SUBMIT)) ||
							(objLeadTask.Case__c != null) ||
							(objLeadTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
							objLeadTask.Status == TaskUtil.TASK_STATUS_CONNECT)
						) {
							list_minDates.add(objLeadTask.CreatedDate);
						}
					}

					// Include current activity
					list_minDates.add(objTask.CreatedDate);

					if (list_minDates.size() > 0) {
						list_minDates.sort(); //this will sort List to Assending order
						objLead.Lead_Initiated_Date__c = list_minDates[0];
					}
				} else {
					objLead.Lead_Initiated_Date__c = objLead.CreatedDate;
				}

				blnLeadUpdate = true;
			}

			if (objLead != null && objLead.Form_Submitted_Date__c == null) {
				if (TaskUtil.set_LeadCreationOffers.contains(objLead.Lead_Creation_Offer__c)) {
					list_minDates = new List<DateTime>();

					if (objLead.Account_Created_Date__c != null) {
						//Account created date
						list_minDates.add(objLead.Account_Created_Date__c);
					}
					if (objLead.ConvertedDate != null) {
						//Lead Converted Date
						list_minDates.add(objLead.ConvertedDate);
					}

					// Form filled out & Chat activity - Exclude Phone Activity
					for (Task objLeadTask : objLead.Tasks) {
						if (
							(String.isNotBlank(objLeadTask.Subject) &&
							objLeadTask.Subject.containsIgnoreCase(TaskUtil.TASK_SUBJECT_FILLED_OUT_FORM) &&
							!objLeadTask.Subject.containsIgnoreCase(TaskUtil.TASK_SUBJECT_BUYERZONE_BLIND_FORM_SUBMIT)) ||
							(objLeadTask.Case__c != null) ||
							!(objLeadTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID &&
							objLeadTask.Status == TaskUtil.TASK_STATUS_CONNECT)
						) {
							list_minDates.add(objLeadTask.CreatedDate);
						}
					}

					// Include current activity
					list_minDates.add(objTask.CreatedDate);

					if (list_minDates.size() > 0) {
						list_minDates.sort(); //this will sort List to Assending order
						objLead.Form_Submitted_Date__c = list_minDates[0];
					}
				} else {
					objLead.Form_Submitted_Date__c = objLead.CreatedDate;
				}
				blnLeadUpdate = true;
			}

			if (blnLeadUpdate) {
				map_LeadsToUpdate.put(objLead.Id, objLead);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Update HI_Rep_First_Touch__c on Account for Benefits New Plan and Transfer Opportunities
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void updateHIRepFirstTouchOnAccount(Task objTask) {
		if (checkIfWhatIsOpportunity(objTask) && map_Opportunities.containsKey(objTask.WhatId)) {
			Opportunity objOpportunity = map_Opportunities.get(objTask.WhatId);
			if (
				(objOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
				objOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) &&
				objOpportunity.AccountId != null &&
				objOpportunity.Account.HI_Rep_First_Touch__c == null
			) {
				Account objAccount = map_AccountsToUpdate.containsKey(objOpportunity.AccountId) ? map_AccountsToUpdate.get(objOpportunity.AccountId) : new Account(Id = objOpportunity.AccountId);
				objAccount.HI_Rep_First_Touch__c = System.now();

				map_AccountsToUpdate.put(objAccount.Id, objAccount);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Update Small_Biz_Engagement__c on Contact and Lead If Task is Created By Small Biz Users
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void updateEngagementBizOnContactAndLead(Task objTask) {
		if (checkIfWhoIsLead(objTask) || checkIfWhoIsContact(objTask)) {
			String strOwnerRoleName = map_Users.get(objTask.OwnerId)?.UserRole.Name;

			if (
				String.isNotBlank(objTask.Status) &&
				objTask.Status == TaskUtil.TASK_STATUS_CONNECT &&
				String.isNotBlank(strOwnerRoleName) &&
				(strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_NAME_SALES_SB_OB_SME) ||
				strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_NAME_SALES_SB_IB_SME) ||
				strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_NAME_SALES_SB_OB_XX) ||
				strOwnerRoleName.containsIgnoreCase(TaskUtil.USER_ROLE_NAME_SALES_SB_IB_XX))
			) {
				if (map_Leads.containsKey(objTask.WhoId)) {
					Lead objLead = map_Leads.get(objTask.WhoId);
					if (!objLead.Small_Biz_Engagement__c) {
						objLead.Small_Biz_Engagement__c = true;
						map_LeadsToUpdate.put(objLead.Id, objLead);
					}
				} else if (map_Contacts.containsKey(objTask.WhoId)) {
					Contact objContact = map_Contacts.get(objTask.WhoId);
					if (!objContact.Small_Biz_Engagement__c) {
						objContact.Small_Biz_Engagement__c = true;
						map_ContactsToUpdate.put(objContact.Id, objContact);
					}
				}
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Update Last_Call_Connect__c and Last_Call_Connect_by_Owner__c is updated on Account
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void updateLastCallConnectDetails(Task objTask) {
		if (
			String.isNotBlank(objTask.Type) &&
			(objTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_INBOUND_CALL) || objTask.Type.equalsIgnoreCase(TaskUtil.TASK_TYPE_OUTBOUND_CALL)) &&
			String.isNotBlank(objTask.Status) &&
			objTask.Status.equalsIgnoreCase(TaskUtil.TASK_STATUS_CONNECT) &&
			objTask.AccountId != null &&
			map_Accounts.containskey(objTask.AccountId)
		) {
			Account objAccount = map_Accounts.get(objTask.AccountId);
			String strOwnerName = map_Users.get(objTask.OwnerId)?.Name;
			Boolean blnIsChanged = false;

			if (objTask.ActivityDate != null && (objAccount.Last_Call_Connect__c == null || objTask.ActivityDate >= objAccount.Last_Call_Connect__c)) {
				objAccount.Last_Call_Connect__c = objTask.ActivityDate;
				blnIsChanged = true;
			}

			if (objAccount.OwnerId == objTask.OwnerId && objAccount.Last_Call_Connect_by_Owner__c != strOwnerName) {
				objAccount.Last_Call_Connect_by_Owner__c = strOwnerName;
				blnIsChanged = true;
			}

			if (blnIsChanged) {
				map_AccountsToUpdate.put(objAccount.Id, objAccount);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Upsert Related Case Audit Log Record For Genysys Tasks
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void processGenesysTaskDuration(Task objNewTask, Task objOldTask) {
		if (
			String.isNotBlank(objNewTask.CallObject) &&
			objNewTask.WhatId != null &&
			objNewTask.CallDurationInSeconds != null &&
			objNewTask.CallDurationInSeconds != 0 &&
			String.isNotBlank(objNewTask.CallType) &&
			objNewTask.CallType != TaskUtil.TASK_TYPE_OUTBOUND &&
			(objOldTask == null ||
			objNewTask.CallDurationInSeconds != objOldTask.CallDurationInSeconds) &&
			(checkIfWhatIsCase(objNewTask) || objNewTask.Case__c != null)
		) {
			Case_Audit_Log__c objCaseAuditLog = map_CaseAuditLogsToUpsert.containsKey(objNewTask.CallObject) ? map_CaseAuditLogsToUpsert.get(objNewTask.CallObject) : new Case_Audit_Log__c();

			objCaseAuditLog.External_Id__c = objNewTask.CallObject;
			objCaseAuditLog.Genesys_Id__c = objNewTask.CallObject;

			//BSS-1774 - Activity fields Cleanup Activity. Commenting for now as field needs final confimation before deletion on production
			/*if (String.isNotBlank(objNewTask.Workato_Integration_Id__c)) {
				objCaseAuditLog.External_Id__c = objNewTask.Workato_Integration_Id__c;
			}*/

			objCaseAuditLog.Case__c = checkIfWhatIsCase(objNewTask) ? objNewTask.WhatId : objNewTask.Case__c;
			objCaseAuditLog.Advocate__c = objNewTask.OwnerId;
			objCaseAuditLog.Event_Type__c = 'Phone';
			objCaseAuditLog.Direction__c = objNewTask.Genesys_ani__c == TaskUtil.TASK_TYPE_INBOUND ? TaskUtil.TASK_TYPE_OUTBOUND : TaskUtil.TASK_TYPE_INBOUND;
			objCaseAuditLog.Duration_In_Seconds__c = objNewTask.CallDurationInSeconds;
			objCaseAuditLog.Duration_In_Seconds_Adjusted__c = objNewTask.CallDurationInSeconds;

			if (String.isNotBlank(objCaseAuditLog.External_Id__c)) {
				map_CaseAuditLogsToUpsert.put(objCaseAuditLog.External_Id__c, objCaseAuditLog);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Post Trigger DML Inserts and Updates
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	private void processDMLOperation(Boolean blnInsert) {
		if (blnInsert) {
			if (!list_FeedItemsToInsert.isEmpty()) {
				insert list_FeedItemsToInsert;
			}

			if (!list_CasesToInsert.isEmpty()) {
				insert list_CasesToInsert;
			}

			if (!map_OpptysToUpdate.isEmpty()) {
				OpportunityTriggerHelper.skipTrigger = true;
				update map_OpptysToUpdate.values();
				OpportunityTriggerHelper.skipTrigger = false;
			}

			if (!map_LeadsToUpdate.isEmpty()) {
				LeadTriggerHelper.skipTrigger = true;
				update map_LeadsToUpdate.values();
				LeadTriggerHelper.skipTrigger = false;
			}

			if (!map_ContactsToUpdate.isEmpty()) {
				ContactTriggerHelper.skipTrigger = true;
				update map_ContactsToUpdate.values();
				ContactTriggerHelper.skipTrigger = false;
			}

			if (!map_LeadRelatedTrackingsToUpsert.isEmpty()) {
				upsert map_LeadRelatedTrackingsToUpsert.values() Unique_Lead_Id__c;
			}

			if (!map_AccountRelatedTrackingsToUpsert.isEmpty()) {
				upsert map_AccountRelatedTrackingsToUpsert.values() Unique_Account_Id__c;
			}

			if (!set_OpportunityIds.isEmpty() && objOppTrackClass != null && UserInfo.getName() != TaskUtil.OUTREACH_APPLICATION) {
				objOppTrackClass.processInformation(set_OpportunityIds);
			}

			if (!map_CaseAuditLogsToUpsert.isEmpty()) {
				upsert map_CaseAuditLogsToUpsert.values() External_Id__c;
			}

			if (!map_CasesToUpdate.isEmpty()) {
				update map_CasesToUpdate.values();
			}

			if (!map_AccountsToUpdate.isEmpty()) {
				AccountTriggerHelper.skipTrigger = true;
				update map_AccountsToUpdate.values();
				AccountTriggerHelper.skipTrigger = false;
			}
		} else {
			if (!map_OpptysToUpdate.isEmpty()) {
				OpportunityTriggerHelper.skipTrigger = true;
				update map_OpptysToUpdate.values();
				OpportunityTriggerHelper.skipTrigger = false;
			}

			if (!map_LeadsToUpdate.isEmpty()) {
				LeadTriggerHelper.skipTrigger = true;
				update map_LeadsToUpdate.values();
				LeadTriggerHelper.skipTrigger = false;
			}

			if (!map_CasesToUpdate.isEmpty()) {
				update map_CasesToUpdate.values();
			}

			if (!map_LeadRelatedTrackingsToUpsert.isEmpty()) {
				upsert map_LeadRelatedTrackingsToUpsert.values() Unique_Lead_Id__c;
			}

			if (!map_AccountRelatedTrackingsToUpsert.isEmpty()) {
				upsert map_AccountRelatedTrackingsToUpsert.values() Unique_Account_Id__c;
			}

			if (!set_OpportunityIds.isEmpty() && objOppTrackClass != null) {
				objOppTrackClass.processInformation(set_OpportunityIds);
			}

			if (!map_AccountsToUpdate.isEmpty()) {
				AccountTriggerHelper.skipTrigger = true;
				update map_AccountsToUpdate.values();
				AccountTriggerHelper.skipTrigger = false;
			}

			if (!map_ContactsToUpdate.isEmpty()) {
				ContactTriggerHelper.skipTrigger = true;
				update map_ContactsToUpdate.values();
				ContactTriggerHelper.skipTrigger = false;
			}
		}

		/** Insert or Update Operation*/
		if (!map_TicketWithTasks.values().isEmpty()) {
			update map_TicketWithTasks.values();
		}

		if (!list_TaskTemplateTypes.isEmpty()) {
			List<Task> list_TaskToInsert = TaskTemplateUtil.generateTasks(list_TaskTemplateTypes, TicketUtil.OBJECT_TICKET);
			insert list_TaskToInsert;
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Check if Logged In User is Marketo
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public Boolean isMarketoUser() {
		String strUserFullName = UserInfo.getName();
		return String.isNotBlank(strUserFullName) && strUserFullName.containsIgnoreCase(TaskUtil.USER_NAME_MARKETO);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Check if Task is Closed
	 * @Parm        : objTask - New Task
	 * @Return      : N/A
	 **/
	public Boolean isTaskClosed(Task objTask) {
		return String.isNotBlank(objTask.Status) && !set_ClosedStatuses.isEmpty() && set_ClosedStatuses.contains(objTask.Status);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : If Task record type is Advising Call and Task record is inserted or deleted. Then this code will execute.
	 * @Parm        : object of Task record
	 * @Return      : N/A
	 **/
	public void setAdvisingCallRelatedObject(Task objTask) {
		if (objTask.RecordTypeId == TaskUtil.TASK_ADVISING_CALL_RT_ID) {
			if (objTask.Opportunity__c != null) {
				set_OppIdsWithAdvisingCalls.add(objTask.Opportunity__c);
			}

			if (objTask.Case__c != null) {
				set_CaseIdsWithAdvisingCalls.add(objTask.Case__c);
			}
		}
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : If not admin tries to delete Task throw an error
	 * @Parm        : object of old Task record
	 * @Return      : N/A
	 **/
	public void preventDeletion(Task objOldTask) {
		if (!UserUtils.isAdminIntgUser(UserInfo.getUserId()) || !Test.isRunningTest()) {
			//Add Error
			objOldTask.addError(TaskUtil.DELETE_EXCEPTION);
		}
	}

	/**
	 * @Author      : Ajay Krishna PU
	 * @Description : Populate Last Activity Date on Ardius Tickets
	 * @Return      : N/A
	 **/
	public void populateLastActivityDateOnTicket() {
		if (list_TicketsToBeUpdated.isEmpty()) {
			return;
		}

		//Update Last_Activity_Date__c as NOW
		DateTime dtNow = DateTime.now();
		for (Ticket__c objTicket : list_TicketsToBeUpdated) {
			if (map_TicketWithTasks.containsKey(objTicket.Id)) {
				map_TicketWithTasks.get(objTicket.Id).Last_Activity_Date__c = dtNow;
			} else {
				objTicket.Last_Activity_Date__c = dtNow;
				map_TicketWithTasks.put(objTicket.Id, objTicket);
			}
		}
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : Mark ticket as closed if task is completed
	 * @Return      : N/A
	 **/
	public void markTicketClosedAfterTaskCompleted(Task oldTask) {
		if (list_CustomerRevisionTicketsToBeUpdated == null || list_CustomerRevisionTicketsToBeUpdated.isEmpty()) {
			return;
		}

		for (Ticket__c objTicket : list_CustomerRevisionTicketsToBeUpdated) {
			if (oldTask.Status != TaskUtil.TASK_STATUS_COMPLETE) {
				objTicket.Status__c = TicketUtil.CLOSED;
				objTicket.Revisions_Required__c = false;
				map_TicketWithTasks.put(objTicket.Id, objTicket);
			}
		}
	}

	/**
	 * @author	Ajay Krishna P U
	 * @description      Identify Auto Create Ardius task
	 * @param objNewTask The new version of Task
	 * @param objOldTask The old Version of task
	 */
	private void identifyAutoCreateTasks(Task objNewTask, Task objOldTask) {
		Boolean blnIsInsert = objOldTask == null;

		if (
			this.map_ArdiusTickets.containsKey(objNewTask.WhatId) &&
			this.map_ArdiusTickets.get(objNewTask.WhatId).Status__c != TicketUtil.TICKET_STATUS_LOST &&
			objNewTask.Status == TaskUtil.TASK_STATUS_COMPLETE &&
			(blnIsInsert || objOldTask.Status != objNewTask.Status) &&
			set_StatusHaveArdiusTemplates.contains(objNewTask.Feature_Request__c)
		) {
			list_TaskTemplateTypes.add(new TaskTemplateUtil.TemplateType(objNewTask.WhatId, TaskUtil.ARDIUS_TASK_TEMPLATE, objNewTask.Feature_Request__c, new Map<String, String>()));
		}
	}

	/**
	 * @description Reassign the Task to Previous Oportunity Owner
	 * @param objNewTask New Task
	 * @param objOldTask Old task
	 */
	private void assignPrevTaxYearOpptyAsTaskOwner(Task objNewTask, Task objOldTask) {
		Boolean blnIsInsert = objOldTask == null;
		Set<Id> set_CoreCsRnDGustieUserIds = TaskUtil.getCoreCSRnDGusties();

		if (set_TaskIdToReassign.contains(objNewTask.Id) && (blnIsInsert || objOldTask.Status != objNewTask.Status || objOldTask.OwnerId != objNewTask.OwnerId)) {
			Account objAccount = map_AccountWithOpportunities?.get(objNewTask.WhatId);
			if (objAccount == null) {
				return;
			}

			Id idPreviousTaxYearOpptyOwner;
			for (Opportunity objOppty : objAccount.Opportunities) {
				if (objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID && objOppty.Tax_Year__c != null && set_CoreCsRnDGustieUserIds.contains(objOppty.OwnerId)) {
					idPreviousTaxYearOpptyOwner = objOppty.Owner.IsActive ? objOppty.OwnerId : null;
					break;
				}
			}

			if (idPreviousTaxYearOpptyOwner != null) {
				objNewTask.OwnerId = idPreviousTaxYearOpptyOwner;
			}
		}
	}

	/**** All SOQL Queries Start Here  ****/
	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Contacts
	 * @Parm        : set_GeneysisAniPhoneNos - Set of Phone numbers from Contact
	 * @Parm        : set_ContactIds - Set of Contact Ids related to Task
	 * @Return      : N/A
	 **/
	public List<Contact> queryContacts(Set<String> set_GeneysisAniPhoneNos, Set<Id> set_ContactIds) {
		return [
			SELECT
				Id,
				Normalized_Phone__c,
				Normalized_Other_Phone__c,
				Normalized_Mobile_Phone__c,
				ZP_Phone__c,
				AccountId,
				Last_Contact_Connect__c,
				Last_Contact_Activity__c,
				Account.RecordTypeId,
				Account.Reseller_Type__c,
				Account.Owner.UserRoleId,
				Account.Last_Account_Activity_Date__c,
				Account.Last_Rep_Activity_Date_New__c,
				Account.Sold_By__c,
				Account.Sold_By__r.Last_Activity_Date__c,
				Account.Last_Activity_Date__c,
				Account.Sales_Engagement_Status__c,
				Account.Sales_Engagement_Status_Detail__c,
				Small_Biz_Engagement__c,
				RecordTypeId,
				RecordType.Name,
				Account.Last_Call_Connect__c,
				Account.Sold_By__r.Last_Call_Connect__c
			FROM Contact
			WHERE
				(Normalized_Phone__c != NULL
				AND Normalized_Phone__c IN :set_GeneysisAniPhoneNos)
				OR (Normalized_Other_Phone__c != NULL
				AND Normalized_Other_Phone__c IN :set_GeneysisAniPhoneNos)
				OR (Normalized_Mobile_Phone__c != NULL
				AND Normalized_Mobile_Phone__c IN :set_GeneysisAniPhoneNos)
				OR (ZP_Phone__c != NULL
				AND ZP_Phone__c IN :set_GeneysisAniPhoneNos)
				OR Id IN :set_ContactIds
		];
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Users
	 * @Parm        : set_OwnerIds - Set of Task Owner Ids
	 * @Return      : N/A
	 **/
	public List<User> queryUsers(Set<Id> set_OwnerIds) {
		return [SELECT Id, Name, Department, Division, Title, ProfileId, Profile.Name, UserRole.Name FROM User WHERE Id IN :set_OwnerIds];
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Closed Task Statuses
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public List<TaskStatus> queryTaskStatus() {
		return [SELECT MasterLabel FROM TaskStatus WHERE IsClosed = TRUE];
	}
	/**
	 * @Author      : Sujan
	 * @Description : Query CallCenter
	 * @Parm        : N/A
	 * @Return      : N/A
	 * TODO - deprecate and replace with Cxone Incontact setting after managed package upgrade to version > 24.x . x
	 **/
	public String runningUserCallCenter() {
		List<CallCenter> callCenter = [SELECT Name FROM CallCenter WHERE id IN (SELECT CallCenterId FROM User WHERE Id = :UserInfo.getUserID())];
		return callCenter.isEmpty() ? null : callCenter[0].Name;
	}

	/**
	 * @Author      : Sujan
	 * @Description : Query PermissionSet
	 * @Parm        : N/A
	 * @Return      : N/A
	 * TODO - deprecate and replace with Cxone Incontact setting after managed package upgrade to version > 24.x . x
	 **/
	public Boolean queryPermissionSet() {
		List<String> list_TaskRecordTypePSA = new List<String>{ TaskUtil.USER_PERMISSION_SET_TASK_RECORD_TYPE_UPDATE };
		List<PermissionSetAssignment> list_Assignment = GlobalQueryHelper.getPermSetAssignments(list_TaskRecordTypePSA);
		if (!list_Assignment.isEmpty()) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Case Audit Logs
	 * @Parm        : set_GenesysIds - Set of Genesys Ids
	 * @Return      : N/A
	 **/
	public List<Case_Audit_Log__c> queryCaseAuditLogs(Set<String> set_GenesysIds) {
		return [
			SELECT Id, Case__c, External_Id__c, Case__r.origin, Case__r.Integration_Id__c, Case__r.Genesys_Call_Id__c
			FROM Case_Audit_Log__c
			WHERE External_Id__c != NULL AND External_Id__c IN :set_GenesysIds AND Case__r.IsClosed = FALSE
		];
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Leads
	 * @Parm        : set_LeadIds - Set of Lead Ids related to Task
	 * @Return      : N/A
	 **/
	public Map<Id, Lead> queryLeads(Set<Id> set_LeadIds) {
		return new Map<Id, Lead>(
			[
				SELECT
					Id,
					Name,
					Email,
					IsConverted,
					ConvertedContactId,
					ConvertedAccountId,
					Last_Rep_Activity_Date__c,
					Last_Lead_Activity_Date__c,
					Last_Rep_Activity_Date_New__c,
					Last_Call__c,
					Last_Call_Connect__c,
					Status,
					Small_Biz_Engagement__c,
					Lead_Initiated_Date__c,
					Form_Submitted_Date__c,
					Lead_Creation_Offer__c,
					Account_Created_Date__c,
					CreatedDate,
					ConvertedDate,
					Served_Up_Time__c,
					Served_Up_Rule__c,
					Served_Other_Rules__c,
					(SELECT Id, Subject, WhoId, Type, Case__c, RecordTypeId, CreatedDate, ActivityDate, Status FROM Tasks)
				FROM Lead
				WHERE Id IN :set_LeadIds
			]
		);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Accounts
	 * @Parm        : set_AccountIds - Set of Account Ids related to Task
	 * @Return      : N/A
	 **/
	public Map<Id, Account> queryAccounts(Set<Id> set_AccountIds) {
		return new Map<Id, Account>(
			[
				SELECT
					Id,
					OwnerId,
					Last_Rep_Activity_Date_New__c,
					Last_Account_Activity_Date__c,
					Last_Activity_Date__c,
					Last_Activity_Type__c,
					Last_Sales_Activity_Type__c,
					Last_Call_Connect__c,
					Last_Call_Connect_by_Owner__c,
					Sold_By__c,
					Sold_By__r.Last_Activity_Date__c,
					RecordTypeId,
					Sold_By__r.Last_Call_Connect__c
				FROM Account
				WHERE Id IN :set_AccountIds
			]
		);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Opportunities
	 * @Parm        : set_OpportunityIds - Set of Opportunity Ids related to Task
	 * @Return      : N/A
	 **/
	public Map<Id, Opportunity> queryOpportunities(Set<Id> set_OpportunityIds) {
		return new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					AccountId,
					Account.Last_Activity_Date__c,
					Account.Last_Account_Activity_Date__c,
					Account.Last_Rep_Activity_Date_New__c,
					Account.Last_Call_Connect__c,
					Last_Activity_Date__c,
					Last_Call__c,
					Last_Call_Connect__c,
					Account.HI_Rep_First_Touch__c,
					RecordTypeId,
					Served_Up_Time__c,
					Served_Up_Rule__c,
					Served_Other_Rules__c,
					Account.RecordTypeId,
					Account.Sold_By__c,
					Account.Sold_By__r.Last_Activity_Date__c,
					Account.Sold_By__r.Last_Call_Connect__c
				FROM Opportunity
				WHERE Id IN :set_OpportunityIds
			]
		);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Cases
	 * @Parm        : set_ContactIds - Set of Contact Ids related to Task
	 * @Parm        : set_LeadIds - Set of Lead Ids related to Task
	 * @Parm        : set_GenesysIds - Set of Genysys Ids mappint to Task CallObject
	 * @Return      : N/A
	 **/
	public List<Case> queryCases(Set<Id> set_ContactIds, Set<Id> set_LeadIds, Set<String> set_GenesysIds, Set<Id> set_CaseIds) {
		return [
			SELECT Id, Subject, SB_Survey_Mail_Sent__c, ContactId, Lead__c, Chat_Closure_Reason_Drift__c, RecordTypeId, Type, Drift_Conversation_Id__c, Genesys_Call_Id__c, Opportunity__c
			FROM Case
			WHERE
				((Type = :CaseUtils.TYPE_SALES_CHAT
				AND ContactId != NULL
				AND ContactId IN :set_ContactIds)
				OR (Lead__c != NULL
				AND Lead__c IN :set_LeadIds)
				OR (Genesys_Call_Id__c != NULL
				AND Genesys_Call_Id__c IN :set_GenesysIds)
				OR (Id IN :set_CaseIds
				AND Opportunity__c != NULL))
				AND IsClosed = FALSE
		];
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Query Lead Related Trackings
	 * @Parm        : set_LeadIds - Set of Lead Ids related to Task
	 * @Return      : N/A
	 **/
	public List<Lead_Related_Tracking__c> queryLeadRelatedrackings(Set<Id> set_LeadIds) {
		return [
			SELECT
				Id,
				First_Call_Date__c,
				First_Activity_Date__c,
				Lead__c,
				Unique_Lead_Id__c,
				Lead__r.Status,
				Lead__r.OwnerId,
				Lead__r.Owner.UserRoleId,
				Lead__r.Owner_Role_Formula__c,
				MDR_First_Call_Date__c
			FROM Lead_Related_Tracking__c
			WHERE Lead__c IN :set_LeadIds AND Unique_Lead_Id__c != NULL
		];
	}

	/**
	 * @Author      : Ajay Krishna PU
	 * @Description : Query Tickets
	 * @Parm        : set_TicketIds - Set of Ticket Ids related to Task
	 * @Parm        : list_RecordTypeIds - List of RecordType Ids
	 * @Return      : List of Tickets having Id @set_TicketIds and RecordTypeId @list_RecordTypeIds
	 **/
	public List<Ticket__c> queryTickets(Set<Id> set_TicketIds, List<Id> list_RecordTypeIds) {
		return [SELECT Id, RecordTypeId, Last_Activity_Date__c, Status__c, Revisions_Required__c FROM Ticket__c WHERE Id IN :set_TicketIds AND RecordTypeId IN :list_RecordTypeIds];
	}

	/**
	 * @description Query Account s with Opportunities
	 * @param set_AccountIds Set of Account Ids
	 * @return ` Map<Id, Account>`
	 */
	public Map<Id, Account> queryAccountsWithRelatedOpptys(Set<Id> set_AccountIds) {
		return new Map<Id, Account>(
			[
				SELECT
					Id,
					OwnerId,
					(
						SELECT Id, RecordTypeId, CreatedDate, CloseDate, StageName, Tax_Year__c, OwnerId, Owner.IsActive
						FROM Opportunities
						ORDER BY CreatedDate DESC
					)
				FROM Account
				WHERE Id IN :set_AccountIds
			]
		);
	}
}