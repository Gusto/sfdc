/*
 * Created By Praveen Sethu, Jun 19th, 2019
 * It is used to fetch queue assigned to logged in user and assign x number of cases to the logged in user
 */
public with sharing class PlayModeCaseListControllerLightning {
	public static Integer numberOfCasesAssigned = 0;
	public static String CASE_TAXRES_LSI_QUEUE = GlobalQueryHelper.getQueueIdByName('TaxRes LSI');

	/*
	 * Wrapper Class to share data
	 * between Apex and LWC.
	 */
	public class PlayModeCaseListWrapper {
		/* All variables that are exposed to LWC are annotated as @AuraEnabled */

		/* Map of Queue Id and Queue Names */
		@AuraEnabled
		public Map<String, String> map_caseQueueIdToName;

		/* Indicates if transaction is success or failure */
		@AuraEnabled
		public Boolean blnIsSuccess;

		/* If there are any exceptions, exception message will be returned back to the UI */
		@AuraEnabled
		public String strMessage;

		/* Returns number of pending cases for particular queue */
		@AuraEnabled
		public Integer intPendingCases;

		/* Returns list of assigned cases */
		@AuraEnabled
		public List<Case> list_cases;

		/* Parameterized Constructor - Instantiates an object of this nested wrapper class */
		public PlayModeCaseListWrapper(Map<String, String> map_caseQueueIdToName, Boolean blnIsSuccess, String strMessage) {
			this.map_caseQueueIdToName = map_caseQueueIdToName;
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
		}

		/* Parameterized Constructor - Instantiates an object of this nested wrapper class */
		public PlayModeCaseListWrapper(Boolean blnIsSuccess, Integer intPendingCases) {
			this.blnIsSuccess = blnIsSuccess;
			this.intPendingCases = intPendingCases;
		}

		/* Parameterized Constructor - Instantiates an object of this nested wrapper class */
		public PlayModeCaseListWrapper(Boolean blnIsSuccess, List<Case> list_cases, String strMessage) {
			this.blnIsSuccess = blnIsSuccess;
			this.list_cases = list_cases;
			this.strMessage = strMessage;
		}
	}

	/* Gets a list of Queues
	 * configured for logged in user.
	 */
	@AuraEnabled
	public static PlayModeCaseListWrapper getcaseQueueList() {
		/* Declare All Variables before Try Block */
		Map<String, String> map_caseQueueIdToName = new Map<String, String>();
		/* Start Try Block */
		try {
			/* Fetch User Record - Logged In User */
			User objUserRecord = fetchLoggedInUserInfo();

			/* Check if User has All Queues Configured */
			if (objUserRecord.All_Queues__c != null && objUserRecord.All_Queues__c.length() > 0) {
				map_caseQueueIdToName.put('All', 'All Queues');
			}

			/* Check if User has Individual Queue field Configured */
			if (objUserRecord.Individual_Queues__c != null && objUserRecord.Individual_Queues__c.length() > 0) {
				/* Fetch all Queues based on user's individual queue field - add them to queue map */
				for (Group objQueueRec : [SELECT Type, Name, Id FROM Group WHERE Type = 'Queue' AND Name IN :objUserRecord.Individual_Queues__c.split(';')]) {
					map_caseQueueIdToName.put(objQueueRec.id, objQueueRec.Name);
				}
			}

			/* Return Wrapper Object back to UI with Case Queue Map - Set isSuccess as True */
			return new PlayModeCaseListWrapper(map_caseQueueIdToName, true, null);
		} catch (Exception objException) {
			/* If there are any exceptions, set isSuccess as False - return exception message back to UI */
			ExceptionLogUtil.logException('PlayModeCaseListControllerLightning', 'getcaseQueueList', objException.getMessage(), objException.getStackTraceString());
			return new PlayModeCaseListWrapper(null, false, 'Error: Reason - ' + objException.getMessage());
		}
	}

	/* Returns number of
	 * cases assigned to a
	 * particular queue
	 */
	@AuraEnabled
	public static PlayModeCaseListWrapper getNumberOfPendingCases(String idQueue) {
		Set<String> set_queueId = new Set<String>();
		String strAllQueueId = '';
		Integer intPendingCasesCount = 0;

		try {
			if (idQueue.equals('All')) {
				/* Fetch User Record - Logged In User */
				User objUserRecord = fetchLoggedInUserInfo();

				// Fetch All Queue Id's Configured to a particular User
				strAllQueueId = returnAllQueueId(objUserRecord);

				set_queueId.addAll(strAllQueueId.split(';'));
			} else {
				set_queueId.add(idQueue);
			}

			// For TaxRes LSI queue
			if (set_queueId.contains(CASE_TAXRES_LSI_QUEUE)) {
				// SOQL query that returns number of cases owned by a particular idQueue
				intPendingCasesCount = [
					SELECT COUNT()
					FROM Case
					WHERE Status NOT IN (:CaseUtils.STATUS_CLOSED, :CaseUtils.STATUS_SOLVED) AND RecordTypeId = :CaseUtils.RECTYPE_TAXRES AND OwnerId IN :set_queueId AND Owner.Type = 'Queue'
				];
			} else {
				intPendingCasesCount = [
					SELECT COUNT()
					FROM Case
					WHERE
						OwnerId IN :set_queueId
						AND Owner.Type = 'Queue'
						AND Id NOT IN (SELECT Case__c FROM Case_Skip_History__c WHERE Case__r.OwnerId IN :set_queueId AND User__c = :UserInfo.getUserId())
				];
			}

			return new PlayModeCaseListWrapper(true, intPendingCasesCount);
		} catch (Exception objException) {
			// If there are exceptions, return them back to the UI
			ExceptionLogUtil.logException('PlayModeCaseListControllerLightning', 'getNumberOfPendingCases', objException.getMessage(), objException.getStackTraceString());
			return new PlayModeCaseListWrapper(null, false, 'Error: Reason - ' + objException.getMessage());
		}
	}

	/* assigns "intNumberToServeUp" number
	 * of "queueId" cases to logged in user id.
	 * Param - queueId = Id of Case Queue or It can return 'All'
	 * Param - intNumberToServeUp = number of cases to be assigned
	 * Param - list_CaseStatuses - Status values for which Status should not be updated to In Progress.
	 */
	@AuraEnabled
	public static PlayModeCaseListWrapper assignCaseFromQueue(String idQueue, Integer intNumberToServeUp, List<String> list_CaseStatuses) {
		/* Declare list of variables */
		List<Case> list_cases = new List<Case>();
		User_Preference__c objUserPreference = new User_Preference__c();
		String strAllQueueId = '';
		Set<string> set_queueId = new Set<String>();
		List<Case> list_AdditionalCases = new List<Case>();

		try {
			// Retrieve or create a new instance of User_Preference__c record
			objUserPreference = fetchUserPreference();

			// Check if Selected Queue Id is 'All Queues'
			if (idQueue.equals('All')) {
				/* Fetch User Record - Logged In User */
				User objUserRecord = fetchLoggedInUserInfo();

				// Fetch All Queue Id's Configured to a particular User
				strAllQueueId = returnAllQueueId(objUserRecord);
				objUserPreference.Case_Play_Selected_Queues__c = strAllQueueId;
			} else {
				objUserPreference.Case_Play_Selected_Queues__c = idQueue;
			}

			objUserPreference.Number_to_Serve_Up__c = intNumberToServeUp;

			// Check if User Preference Case_Play_Selected_Queues__c has ; - which means - user selected All Queues
			if (objUserPreference.Case_Play_Selected_Queues__c.indexof(';') > 0) {
				set_queueId.addAll(objUserPreference.Case_Play_Selected_Queues__c.split(';'));
			} else {
				set_queueId.add(objUserPreference.Case_Play_Selected_Queues__c);
			}

			// Find the first primary case based on priority date and age
			Case objPrimaryCase = assignPrimaryCase(objUserPreference, set_queueId, list_CaseStatuses);

			// If primary case is not null and check routing case
			// Find all other cases that have the same routing case reason as primary case
			if (objPrimaryCase != null) {
				list_cases.add(objPrimaryCase);
				// Check if primary case has routing case reason
				String strRoutingReason = [SELECT Routing_Case_Reason__c FROM Case WHERE Id = :objPrimaryCase.Id].Routing_Case_Reason__c;
				if (String.isNotBlank(strRoutingReason)) {
					// List of Additional Cases that have the same routing case reason
					list_AdditionalCases = [
						SELECT Id, CaseNumber, RecordTypeId, Status
						FROM Case
						WHERE
							OwnerId IN :set_queueId
							AND Owner.Type = 'Queue'
							AND Routing_Case_Reason__c = :strRoutingReason
							AND Id NOT IN (SELECT Case__c FROM Case_Skip_History__c WHERE Case__r.OwnerId IN :set_queueId AND User__c = :UserInfo.getUserId())
						ORDER BY Priority_Number__c, CreatedDate ASC
						LIMIT :(intNumberToServeUp - 1)
					];

					// Iterate over all cases that has similar routing case reasons
					for (Case objCase : list_AdditionalCases) {
						// Skip any cases which are solved or closed for Tax Res
						if (
							(objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES || objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES_READ_ONLY) &&
							(objCase.Status == CaseUtils.STATUS_SOLVED ||
							objCase.Status == CaseUtils.STATUS_CLOSED)
						) {
							continue;
						}
						// SOQL will also return primary case
						// Ensure you are not adding duplicate records
						if (objCase.Id != objPrimaryCase.Id) {
							objCase.OwnerId = UserInfo.getUserId();
							objCase.Assigned_by_Play_Mode__c = true;
							objCase.Play_Mode_Type__c = CaseConstants.CASE_PLAY_MODE_TYPE_SWIMLANE;
							list_cases.add(objCase);
						}
					}
				}
				String strCaseId = '';
				for (Case objCase : list_cases) {
					strCaseId = strCaseId + objCase.Id + ',';
				}

				strCaseId = strCaseId.removeEnd(',');
				objUserPreference.Case_Play_Selected_Cases__c = strCaseId;
				// If User Preference Record does not exist, create a new one or else update existing user
				upsert objUserPreference;

				// If case list is not empty, iterate over every case and change owner Id
				if (!list_cases.isEmpty()) {
					// Update Case List
					if (!list_AdditionalCases.isEmpty()) {
						update list_AdditionalCases;
					}
					// Return back with Success Message
					return new PlayModeCaseListWrapper(true, list_cases, list_cases.size() + ' case(s) assigned successfully! ');
				} else {
					// If there are no cases, return back with error message
					return new PlayModeCaseListWrapper(null, false, 'No cases found. Please select a different queue');
				}
			} else {
				return new PlayModeCaseListWrapper(null, false, 'No cases found. Please select a different queue');
			}
		} catch (Exception objException) {
			/* If there are any exceptions, set isSuccess as False - return exception message back to UI */
			ExceptionLogUtil.logException('PlayModeCaseListControllerLightning', 'assignCaseFromQueue', objException.getMessage(), objException.getStackTraceString());
			return new PlayModeCaseListWrapper(null, false, 'Error: Reason - ' + objException.getMessage());
		}
	}

	/* Returns User Preference
	 * record. If record does not exist,
	 * creates a new instance for logged in user Id
	 */
	public static User_Preference__c fetchUserPreference() {
		User_Preference__c objUserPreference = new User_Preference__c();
		// SOQL to check if User Preference already exists
		List<User_Preference__c> list_userPreferences = [
			SELECT Id, Case_Play_Selected_Queues__c, Number_to_Serve_Up__c, Case_Play_Selected_Cases__c
			FROM User_Preference__c
			WHERE User__c = :UserInfo.getUserId()
		];
		// If already exists, return first record from arrray
		if (!list_userPreferences.isEmpty()) {
			objUserPreference = list_userPreferences.get(0);
		} else {
			// Else, create a new instance
			objUserPreference.User__c = UserInfo.getUserId();
		}
		return objUserPreference;
	}

	/* Returns list of
	 * All Queue Ids
	 */
	public static String returnAllQueueId(User objUserRecord) {
		/* Queue Id String to Return */
		String strAllQueueId = '';

		/* SOQL on Group to fetch all queues */
		for (Group objQueueRec : [SELECT Type, Name, Id FROM Group WHERE Type = 'Queue' AND Name IN :objUserRecord.All_Queues__c.split(';')]) {
			if (string.isBlank(strAllQueueId))
				strAllQueueId = objQueueRec.Id;
			else
				strAllQueueId += ';' + objQueueRec.Id;
		}
		return strAllQueueId;
	}

	/* Returns Logged In User Info
	 * Fetchs details such as
	 * Individual Queues and
	 * All Queues custom field values
	 */
	public static User fetchLoggedInUserInfo() {
		// SOQL to fetch fields for Logged In User
		return [SELECT Id, All_Queues__c, Individual_Queues__c FROM User WHERE Id = :UserInfo.getUserId()];
	}

	/*
	 * Used To create a new Record in Case_Esclation__c
	 * object and case when Escalate Case is created
	 */
	@AuraEnabled
	public static void escalateCaseRecord(Id idCase, String strComments, String strReasons, String strTeam, String strOutOfScopeReason, String strCaseType) {
		Case_Escalation__c objCaseEscalation = new Case_Escalation__c();
		objCaseEscalation.Case__c = idCase;
		objCaseEscalation.Escalation_Reason__c = strReasons;
		objCaseEscalation.Escalation_Comments__c = strComments;
		objCaseEscalation.Type__c = 'Task Us Escalation';
		objCaseEscalation.Team__c = strTeam;
		objCaseEscalation.Out_of_Scope_Reason__c = strOutOfScopeReason;
		objCaseEscalation.Case_Type__c = strCaseType;
		insert objCaseEscalation;

		Case objCaseRec = new case(Id = idCase, Escalated_By_Task_Us__c = true);

		try {
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Database.update(objCaseRec, dmo);
		} catch (exception objException) {
			ExceptionLogUtil.logException('PlayModeCaseListControllerLightning', 'escalateCaseRecord', objException.getMessage(), objException.getStackTraceString());
			return;
		}
	}

	/* Find the first primary case
	 * order them by priority date
	 * and created date
	 */
	public static Case assignPrimaryCase(User_Preference__c objUserPreference, Set<string> set_queueId, List<String> list_CaseStatuses) {
		// Case To Return = Primary Case
		Case objCaseToReturn;
		List<Case> list_cases = new List<Case>();
		List<Case> list_casesToUpdate = new List<Case>();

		if (set_queueId.contains(CASE_TAXRES_LSI_QUEUE)) {
			// TaxRes LSI SOQL on Case, Order by Priority Date and Created Date
			list_cases = [
				SELECT Id, Priority_Number__c, CreatedDate, OwnerId, Routing_Case_Reason__c, CaseNumber, Email_Status__c, RecordTypeId, Status
				FROM Case
				WHERE Status NOT IN (:CaseUtils.STATUS_CLOSED, :CaseUtils.STATUS_SOLVED) AND RecordTypeId = :CaseUtils.RECTYPE_TAXRES AND OwnerId IN :set_queueId
				ORDER BY Priority_Number__c, CreatedDate ASC
				LIMIT 20
			];
		} else {
			// SOQL on Case, Order by Priority Date and Created Date
			list_cases = [
				SELECT Id, Priority_Number__c, CreatedDate, OwnerId, Routing_Case_Reason__c, CaseNumber, Email_Status__c, RecordTypeId, Status
				FROM Case
				WHERE OwnerId IN :set_queueId AND Id NOT IN (SELECT Case__c FROM Case_Skip_History__c WHERE Case__r.OwnerId IN :set_queueId AND User__c = :userInfo.getUserId())
				ORDER BY Priority_Number__c, CreatedDate ASC
				LIMIT 20
			];
		}

		// Iterate over case, check if Case Owner is a Group and check Case Owner Id is not equal to User Id
		for (Case objCase : list_cases) {
			if (list_cases.size() > 0 && String.valueof(objCase.OwnerId).StartsWith('00G') && objCase.OwnerId != userInfo.getUserId()) {
				CaseTriggerHelper.playmode = true;

				objCase.OwnerId = UserInfo.getUserId();

				// Skip any cases which are solved or closed for Tax Res
				if (
					(objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES || objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES_READ_ONLY) &&
					(objCase.Status == CaseUtils.STATUS_SOLVED ||
					objCase.Status == CaseUtils.STATUS_CLOSED)
				) {
					continue;
				}

				if (objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
					//objCase.Status = CaseUtils.CASE_STATUS_CHECKLIST_IN_PROGRESS;
					objCase.Email_Status__c = CaseUtils.EMAILSTATUS_IN_PROGRESS;
				} else if (!list_CaseStatuses.contains(objCase.Status)) {
					objCase.Status = CaseConstants.CASE_STATUS_IN_PROGRESS;
				}

				objCase.Assigned_by_Play_Mode__c = true;
				objCase.Play_Mode_Type__c = CaseConstants.CASE_PLAY_MODE_TYPE_SWIMLANE;
				list_casesToUpdate.add(objCase);
				break;
			}
		}
		try {
			update list_casesToUpdate;
			//Safely access the first updated case
			if (list_casesToUpdate.size() > 0) {
				objCaseToReturn = list_casesToUpdate[0];
			}
		} catch (Exception ex) {
		}
		return objCaseToReturn;
	}

	@AuraEnabled
	public static PlayModeCaseListWrapper handleNextButton() {
		User_Preference__c objUserPreference = fetchUserPreference();
		// If selected queue contains comma separated value, queue Id is All
		String idQueue = objUserPreference.Case_Play_Selected_Queues__c.contains(',') ? 'All' : objUserPreference.Case_Play_Selected_Queues__c;
		Integer intNumberToServeUp = Integer.valueOf(objUserPreference.Number_to_Serve_Up__c);

		return assignCaseFromQueue(idQueue, intNumberToServeUp, new List<String>());
	}
}