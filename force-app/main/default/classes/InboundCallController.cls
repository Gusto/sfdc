/**
 * @name         : InboundCallController
 * @author       : Nigam Goyal
 * @date         : 06-22-2022
 * @description  : InboundCall Related Actions
 * @test classes : InboundCallControllerTest
 **/
public without sharing class InboundCallController {
	public static Boolean blnTestTaskDMLException = false;
	public static Boolean blnTestCaseDMLException = false;
	public static Boolean blnTestDMLException = false;
	public static final String QUEUE_SALES_CASE_QUEUE = 'Sales_Case_Queue';

	// Task Status:
	public static final String TASK_STATUS_TO_DO = 'To Do';
	public static final String TASK_STATUS_OPEN = 'Open';
	public static final String TASK_STATUS_IN_PROGRESS = 'In Progress';
	public static final String TASK_STATUS_COMPLETED = 'Completed';

	// Case Status:
	public static final String CASE_STATUS_NEW = 'New';
	public static final String CASE_STATUS_OPEN = 'Open';
	public static final String CASE_STATUS_PENDING = 'Pending';
	public static final String CASE_STATUS_CLOSED = 'Closed';

	public static final String CASE_DIRECTION_INBOUND = 'Inbound';

	// SObject Names:
	public static final String SOBJECT_NAME_ACCOUNT = 'Account';
	public static final String SOBJECT_NAME_LEAD = 'Lead';
	public static final String SOBJECT_NAME_CONTACT = 'Contact';
	public static final String SOBJECT_NAME_OPPORTUNITY = 'Opportunity';
	public static final String SOBJECT_NAME_CASE = 'Case';

	// Case Type:
	public static final String CASE_TYPE_SALES_EMAIL = 'Sales Email';
	public static final String CASE_TYPE_SALES_VOICEMAIL = 'Sales Voicemail';
	public static final String CASE_TYPE_TASK = 'Task';
	public static final String CASE_TYPE_SALES_CALL = 'Sales Call';
	public static final String CASE_TYPE_SALES_CASES = 'Sales Cases';
	public static final String CASE_TYPE_PAYROLL_CARE = 'Payroll Care';

	// Task Type:
	public final static String TASK_TYPE_DEMO = 'Demo';
	public final static String TASK_TYPE_EMAIL = 'Email';
	public final static String TASK_TYPE_CALL = 'Call';
	public final static String TASK_TYPE_FOLLOW_UP = 'Follow Up';
	public static final String TASK_TYPE_INBOUND_CALL = 'Inbound Call';
	public static final String TASK_TYPE_OUTBOUND_CALL = 'Outbound Call';
	public static final String TASK_TYPE_OTHER = 'Other';
	public static final String TASK_TYPE_PITCH_W_O_DEMO = 'Pitch w/o Demo';
	public static final String TASK_TYPE_PITCH_DEMO = 'Pitch/Demo';
	public static final String TASK_TYPE_QUALIFICATION_CALL = 'Qualification Call';
	public static final String TASK_TYPE_SCHEDULED_CALL = 'Scheduled Call';

	public static final String TASK_PRIMARY_CALL_REASON_TRANSFER = 'Transfer';
	public static final String TASK_SUB_CONTACT_REASON_BAD_TRANSFER = 'Bad Transfer from Care (not an FEIN change)';
	public static final String TASK_SUB_CONTACT_REASON_TRANSFER_TO_CARE = 'Transfer to Care';

	public static final String ERROR_MSG_CONTACT_ADMIN = 'Something went wrong. Please contact Administrator.';

	// App Names:
	public static final String APP_NAME_PANDA = 'Panda';

	// Environment Names:
	public static final String ENV_DEV = 'Dev';
	public static final String ENV_PROD = 'Prod';

	public static final Map<String, String> map_StatusMapping = new Map<String, String>{
		TASK_STATUS_TO_DO => CASE_STATUS_NEW,
		TASK_STATUS_OPEN => CASE_STATUS_OPEN,
		TASK_STATUS_IN_PROGRESS => CASE_STATUS_PENDING,
		TASK_STATUS_COMPLETED => CASE_STATUS_CLOSED
	};
	public static final Map<String, String> map_TypeMapping = new Map<String, String>{
		TASK_TYPE_DEMO => CASE_TYPE_TASK,
		TASK_TYPE_EMAIL => CASE_TYPE_SALES_EMAIL,
		TASK_TYPE_FOLLOW_UP => CASE_TYPE_SALES_EMAIL,
		TASK_TYPE_INBOUND_CALL => CASE_TYPE_TASK,
		TASK_TYPE_OTHER => CASE_TYPE_SALES_VOICEMAIL,
		TASK_TYPE_PITCH_W_O_DEMO => CASE_TYPE_TASK,
		TASK_TYPE_CALL => CASE_TYPE_TASK,
		TASK_TYPE_PITCH_DEMO => CASE_TYPE_TASK,
		TASK_TYPE_QUALIFICATION_CALL => CASE_TYPE_TASK,
		TASK_TYPE_SCHEDULED_CALL => CASE_TYPE_TASK
	};

	/**
	 * @Author      : Nigam Goyal
	 * @Description : create or insert task record base on Genesys_Interaction_Id__c field
	 * @Parm        : Task taskObj, String phone
	 * @Return      : Created/Updated Task Object
	 **/
	@AuraEnabled
	public static Task upsertTask(Task objTask, String strPhone, String strleadSourceValue, String strLeadSourceDetailValue) {
		
		try {
			if (String.isBlank(objTask.Subject)) {
				objTask.Subject = strPhone + ' Incoming call at ' + System.now().format();
			}
			if (String.isBlank(objTask.Genesys_Interaction_Id__c)) {
				return objTask;
			}
			objTask.Type = TaskUtil.TASK_TYPE_INBOUND_CALL;
			Id idTaskCallRecordTypeId = TaskUtil.TASK_CALL_RT_ID;
			objTask.recordTypeId = idTaskCallRecordTypeId;
			objTask.ActivityDate = Date.today();

			objTask.Status = TaskUtil.TASK_STATUS_CONNECT;
			if (
				objTask.WhatId != null &&
				String.valueOf(objTask.WhatId)?.startsWith(CaseUtils.CASE_ID_PREFIX) &&
				objTask.Primary_Call_Reason__c == TASK_PRIMARY_CALL_REASON_TRANSFER &&
				objTask.Secondary_Call_Reason__c == TASK_SUB_CONTACT_REASON_BAD_TRANSFER
			) {
				objTask.Status = TaskUtil.TASK_STATUS_COMPLETE;
				Case objCaseToUpdate = new Case(Id = objTask.WhatId);
				try {
					CaseUtils.caseRouting(CaseUtils.TYPE_ENGAGEMENT, objCaseToUpdate);
				} catch (Exception objEx) {
					throw new AuraHandledException(objEx.getMessage());
				}
			}

			List<Task> list_ExistingTasks = [SELECT Id, Date_Completed__c FROM Task WHERE Genesys_Interaction_Id__c = :objTask.Genesys_Interaction_Id__c FOR UPDATE];
			if (list_ExistingTasks.size() > 0) {
				objTask.Id = list_ExistingTasks[0].Id;
				if (list_ExistingTasks[0].Date_Completed__c == null) {
					objTask.Date_Completed__c = Datetime.now();
				}
				update objTask;
			} else {
				// set who Id and what id only 1 matching contact or lead is found
				// check for existing contacts or leads based on phone number
				if (String.isNotBlank(strPhone)) {
					List<Contact> list_Contacts = [
						SELECT Id, AccountId
						FROM Contact
						WHERE (Phone = :strPhone OR Normalized_Phone__c = :strPhone OR Normalized_Other_Phone__c = :strPhone OR Normalized_Mobile_Phone__c = :strPhone) AND AccountId != NULL
						LIMIT 2
					];

					// Check if only 1 contact is found with matching phone number
					if (!list_Contacts.isEmpty() && list_Contacts.size() == 1) {
						// if only 1 contact is found, set who id and what Id
						Contact objContact = list_Contacts.get(0);
						objTask.WhoId = objContact.Id;
						objTask.WhatId = objContact.AccountId;
					}

					// If Who Id is not set, check for existing leads with matching phone number and no contact exists
					if (objTask.WhoId == null && list_Contacts.size() == 0) {
						List<Lead> list_Leads = [
							SELECT Id
							FROM Lead
							WHERE Phone = :strPhone OR Normalized_Phone__c = :strPhone OR Normalized_Alternate_Phone__c = :strPhone OR Normalized_Mobile_Phone__c = :strPhone
							LIMIT 2
						];

						// Check if only 1 lead is found with matching phone number
						if (!list_Leads.isEmpty() && list_Leads.size() == 1) {
							// if only 1 lead is found, set who id and what Id
							Lead objLead = list_Leads.get(0);
							objTask.WhoId = objLead.Id;
						}
					}
				}
				objTask.Date_Completed__c = Datetime.now();
				insert objTask;
			}
			List<Task> list_Tasks = [
				SELECT Id, CallObject, Genesys_Interaction_Id__c, Subject, Type, recordTypeId, ActivityDate, Status, Description, Primary_Call_Reason__c, Secondary_Call_Reason__c, WhoId, WhatId
				FROM Task
				WHERE Genesys_Interaction_Id__c = :objTask.Genesys_Interaction_Id__c
			];

			if (!list_Tasks.isEmpty()) {
				String strWhoSObjectName = list_Tasks[0].WhoId?.getSObjectType().getDescribe().getName();
				String strWhatSObjectName = list_Tasks[0].WhatId?.getSObjectType().getDescribe().getName();

				if (strWhoSObjectName == SOBJECT_NAME_LEAD) {
					updateLead(list_Tasks[0], strleadSourceValue, strLeadSourceDetailValue);
				} else if (strWhatSObjectName == SOBJECT_NAME_OPPORTUNITY) {
					updateOpportunity(list_Tasks[0]);
				}

				return list_Tasks[0];
			}
			return objTask;
		} catch (Exception objException) {
			// Create an instance of the event and store it in the newsEvent variable
			Exception_Log_Event__e newsEvent = new Exception_Log_Event__e(
				Class_Name__c = 'InboundCallController',
				Message__c = objException.getMessage().left(131072),
				Method_Name__c = 'upsertTask',
				Stack_Trace__c = objException.getStackTraceString().left(131072),
				Type__c = objException.getTypeName()
			);
			// Call method to publish events
			Database.SaveResult sr = EventBus.publish(newsEvent);
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/**
	 * @description : Method to update selected Lead record.
	 * @param       : objTask - Task created.
	 * @return      : NA.
	 **/
	public static void updateLead(Task objTask, String strleadSourceValue, String strLeadSourceDetailValue) {
		List<Lead> list_Leads = [SELECT Id, MDR_Notes__c,LeadSource,Lead_Source_Detail__c FROM Lead WHERE Id = :objTask.WhoId];
		if (!list_Leads.isEmpty()) {
			Boolean blnIsLeadUpdated = false;

			String strDateTime = String.valueOf(System.now().format('MM/dd/yyyy, hh:mm:ss a'));
			String strCommentsPrefix = TASK_TYPE_INBOUND_CALL + ' || ' + strDateTime + ' || ' + UserInfo.getName() + ' ';
			String strDescription;

			if (String.isNotBlank(objTask.Description)) {
				strDescription = strCommentsPrefix + objTask.Description;
				list_Leads[0].MDR_Notes__c = String.isNotBlank(list_Leads[0].MDR_Notes__c) ? strDescription + '\n\n' + list_Leads[0].MDR_Notes__c : strDescription;
				blnIsLeadUpdated = true;
			}

			if (blnTestDMLException) {
				list_Leads[0].LastName = null;
				blnIsLeadUpdated = true;
			}

			if (String.isBlank(list_Leads[0].LeadSource)) {
				list_Leads[0].LeadSource = strleadSourceValue;
				blnIsLeadUpdated = true;
			}

			if (String.isBlank(list_Leads[0].Lead_Source_Detail__c)) {
				list_Leads[0].Lead_Source_Detail__c = strLeadSourceDetailValue;
				blnIsLeadUpdated = true;
			}

			if (blnIsLeadUpdated) {
				LeadTriggerHelper.skipTrigger = true;
				Database.SaveResult list_SaveResults = Database.update(list_Leads[0], false);
				if (!list_SaveResults.isSuccess()) {
					Database.Error[] list_Errors = list_SaveResults.getErrors();
					ExceptionLogUtil.logException('InboundCallController', 'updateLead', list_Errors[0].getMessage(), '');
					throw new AuraHandledException(list_Errors[0].getMessage());
				}
			}
		}
	}

	/**
	 * @description : Method to update selected Opportunity record.
	 * @param       : objTask - Task created.
	 * @return      : NA.
	 **/
	public static void updateOpportunity(Task objTask) {
		List<Opportunity> list_Opportunity = [SELECT Id, Description FROM Opportunity WHERE Id = :objTask.WhatId];

		if (!list_Opportunity.isEmpty()) {
			Boolean blnIsOppUpdated = false;

			String strDateTime = String.valueOf(System.now().format('MM/dd/yyyy, hh:mm:ss a'));
			String strCommentsPrefix = TASK_TYPE_INBOUND_CALL + ' || ' + strDateTime + ' || ' + UserInfo.getName() + ' ';
			String strDescription;

			if (String.isNotBlank(objTask.Description)) {
				strDescription = strCommentsPrefix + objTask.Description;
				list_Opportunity[0].Description = String.isNotBlank(list_Opportunity[0].Description) ? strDescription + '\n\n' + list_Opportunity[0].Description : strDescription;
				blnIsOppUpdated = true;
			}

			if (blnTestDMLException) {
				list_Opportunity[0].CloseDate = null;
				blnIsOppUpdated = true;
			}

			if (blnIsOppUpdated) {
				OpportunityTriggerHelper.skipTrigger = true;
				Database.SaveResult list_SaveResults = Database.update(list_Opportunity[0], false);
				if (!list_SaveResults.isSuccess()) {
					Database.Error[] list_Errors = list_SaveResults.getErrors();
					ExceptionLogUtil.logException('InboundCallController', 'updateOpportunity', list_Errors[0].getMessage(), '');
					throw new AuraHandledException(list_Errors[0].getMessage());
				}
			}
		}
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : search Contact Records
	 * @Parm        : String firstName, String lastName,String accountName,String phone,String email
	 * @Return      : List of Contacts
	 **/
	@AuraEnabled
	public static List<Contact> searchContact(String strFirstName, String strLastName, String strAccountName, String strPhone, String strEmail) {
		try {
			String strQuery = '';
			String strQueryFilter = 'WHERE LastName != null';
			String strFirstNameWithDelimiter = '';
			String strLastNameWithDelimiter = '';
			String strEmailWithDelimiter = '';
			String strAccountNameWithDelimiter = '';
			String strPhoneQuery = '';

			Set<String> set_QueryFields = new Set<String>{
				'Id',
				'Name',
				'FirstName',
				'ZP_Phone__c',
				'Phone',
				'Account.RecordType.Name',
				'Account.Owner.Name',
				'Account.Joined_Date_Panda__c',
				'Otherphone',
				'LastName',
				'SSN_Last_4__c',
				'RecordType.Name',
				'Email',
				'AccountId',
				'Account.Name',
				'Normalized_Phone__c',
				'Normalized_Other_Phone__c',
				'MobilePhone',
				'Normalized_Mobile_Phone__c',
				'OwnerId',
				'Owner.Name',
				'Account.ZP_Company_ID__c',
				'Account.ZP_Firm_ID__c'
			};

			if (!String.isBlank(strFirstName)) {
				if (strFirstName.contains('\'')) {
					strFirstNameWithDelimiter = specialCharacterSearch(strFirstName);
				} else {
					strFirstNameWithDelimiter = '%' + String.escapeSingleQuotes(strFirstName) + '%';
				}
				strQueryFilter += ' AND FirstName LIKE \'' + strFirstNameWithDelimiter + '\'';
			}
			if (!String.isBlank(strLastName)) {
				if (strLastName.contains('\'')) {
					strLastNameWithDelimiter = specialCharacterSearch(strLastName);
				} else {
					strLastNameWithDelimiter = '%' + String.escapeSingleQuotes(strLastName) + '%';
				}
				strQueryFilter += ' AND LastName LIKE \'' + strLastNameWithDelimiter + '\'';
			}
			if (!String.isBlank(strEmail) && String.isBlank(strPhone)) {
				strEmailWithDelimiter = '%' + String.escapeSingleQuotes(strEmail) + '%';
				strQueryFilter += ' AND Email LIKE \'' + strEmailWithDelimiter + '\'';
			}
			if (!String.isBlank(strAccountName)) {
				if (strAccountName.contains('\'')) {
					strAccountNameWithDelimiter = specialCharacterSearch(strAccountName);
				} else {
					strAccountNameWithDelimiter = '%' + String.escapeSingleQuotes(strAccountName) + '%';
				}

				strQueryFilter += ' AND Account.Name LIKE \'' + strAccountNameWithDelimiter + '\'';
			}
			if (!String.isBlank(strPhone) && String.isBlank(strEmail)) {
				strPhoneQuery = '%' + String.escapeSingleQuotes(strPhone) + '%';

				strQueryFilter +=
					' AND (Normalized_Phone__c LIKE \'' +
					strPhoneQuery +
					'\' OR Normalized_Other_Phone__c LIKE  \'' +
					strPhoneQuery +
					'\' OR Normalized_Mobile_Phone__c LIKE \'' +
					strPhoneQuery +
					'\' OR ZP_Phone__c LIKE \'' +
					strPhoneQuery +
					'\' OR Additional_Phone_Numbers__c LIKE \'' +
					strPhoneQuery +
					'\')';
			}
			if (!String.isBlank(strEmail) && !String.isBlank(strPhone)) {
				strEmailWithDelimiter = '%' + String.escapeSingleQuotes(strEmail) + '%';
				strQueryFilter += ' AND ( Email LIKE \'' + strEmailWithDelimiter + '\'';
				strPhoneQuery = '%' + String.escapeSingleQuotes(strPhone) + '%';

				strQueryFilter +=
					' OR (Normalized_Phone__c LIKE \'' +
					strPhoneQuery +
					'\' OR Normalized_Other_Phone__c LIKE  \'' +
					strPhoneQuery +
					'\' OR Normalized_Mobile_Phone__c LIKE \'' +
					strPhoneQuery +
					'\' OR ZP_Phone__c LIKE \'' +
					strPhoneQuery +
					'\' OR Additional_Phone_Numbers__c LIKE \'' +
					strPhoneQuery +
					'\') )';
			}

			strQuery = 'SELECT ';
			strQuery += String.join(new List<String>(set_QueryFields), ', ');
			strQuery += ' FROM Contact ';

			if (String.isNotBlank(strQueryFilter)) {
				strQuery += (strQueryFilter + ' LIMIT 20');
			}

			return Database.query(strQuery);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @Author      : Nigam Goyal
	 * @Description : search Leads Records
	 * @Parm        : String strFirstName, String strLastName, String strAccountName, String strPhone, String strEmail
	 * @Return      : List of Leads
	 **/
	@AuraEnabled
	public static List<Lead> searchLead(String strFirstName, String strLastName, String strAccountName, String strPhone, String strEmail) {
		try {
			String strLeadQuery = '';
			String strLeadFilter = 'WHERE isConverted=false AND lastName !=null  AND Status != \'SAL\'';
			String firstNameWithDelimiter = '';
			String strLastNameWithDelimiter = '';
			String strEmailWithDelimiter = '';
			String strAccountNameWithDelimiter = '';
			String strPhoneQuery = '';

			Set<String> set_QueryFields = new Set<String>{
				'Id',
				'Name',
				'FirstName',
				'Phone',
				'LastName',
				'Company',
				'Status',
				'RecordType.Name',
				'LeadSource',
				'Lead_Source_Detail__c',
				'Email',
				'Normalized_Alternate_Phone__c',
				'MobilePhone',
				'Normalized_Mobile_Phone__c',
				'Normalized_Secondary_Phone__c',
				'Normalized_Phone__c',
				'OwnerId',
				'Owner.Name',
				'ZP_Firm_ID__c',
				'ZP_Company_ID__c'
			};

			if (!String.isBlank(strFirstName)) {
				if (strFirstName.contains('\'')) {
					firstNameWithDelimiter = specialCharacterSearch(strFirstName);
				} else {
					firstNameWithDelimiter = '%' + String.escapeSingleQuotes(strFirstName) + '%';
				}
				strLeadFilter = strLeadFilter + ' AND FirstName LIKE \'' + firstNameWithDelimiter + '\'';
			}
			if (!String.isBlank(strLastName)) {
				if (strLastName.contains('\'')) {
					strLastNameWithDelimiter = specialCharacterSearch(strLastName);
				} else {
					strLastNameWithDelimiter = '%' + String.escapeSingleQuotes(strLastName) + '%';
				}
				strleadFilter = strleadFilter + ' AND LastName LIKE \'' + strLastNameWithDelimiter + '\'';
			}
			if (!String.isBlank(strEmail) && String.isBlank(strPhone)) {
				strEmailWithDelimiter = '%' + String.escapeSingleQuotes(strEmail) + '%';
				strleadFilter = strleadFilter + ' AND Email != null AND Email LIKE :strEmailWithDelimiter';
			}
			if (!String.isBlank(strAccountName)) {
				if (strAccountName.contains('\'')) {
					strAccountNameWithDelimiter = specialCharacterSearch(strAccountName);
				} else {
					strAccountNameWithDelimiter = '%' + String.escapeSingleQuotes(strAccountName) + '%';
				}
				strleadFilter = strleadFilter + ' AND Company LIKE \'' + strAccountNameWithDelimiter + '\'';
			}
			if (!String.isBlank(strPhone) && String.isBlank(strEmail)) {
				strPhoneQuery = '%' + String.escapeSingleQuotes(strPhone) + '%';
				strleadFilter =
					strleadFilter +
					' AND (Phone LIKE :strPhoneQuery OR Normalized_Phone__c LIKE :strPhoneQuery OR Normalized_Alternate_Phone__c LIKE :strPhoneQuery OR Normalized_Mobile_Phone__c LIKE :strPhoneQuery OR Normalized_Secondary_Phone__c LIKE :strPhoneQuery)';
			}
			if (!String.isBlank(strPhone) && !String.isBlank(strEmail)) {
				strEmailWithDelimiter = '%' + String.escapeSingleQuotes(strEmail) + '%';
				strleadFilter = strleadFilter + ' AND (Email LIKE :strEmailWithDelimiter';
				strPhoneQuery = '%' + String.escapeSingleQuotes(strPhone) + '%';
				strleadFilter =
					strleadFilter +
					' OR (Phone LIKE :strPhoneQuery OR Normalized_Phone__c LIKE :strPhoneQuery OR Normalized_Alternate_Phone__c LIKE :strPhoneQuery OR Normalized_Mobile_Phone__c LIKE :strPhoneQuery OR Normalized_Secondary_Phone__c LIKE :strPhoneQuery))';
			}
			strLeadQuery = 'SELECT ';
			strLeadQuery += String.join(new List<String>(set_QueryFields), ', ');
			strLeadQuery += ' FROM Lead ';

			if (!String.isBlank(strleadFilter)) {
				strLeadQuery += (strleadFilter + ' LIMIT 20');
			}
			List<Lead> list_Leads = Database.query(strLeadQuery);
			return list_Leads;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : get Opportunities related to selected accoundId in UI
	 * @Parm        :String accountId
	 * @Return      : List of Opportunity
	 **/
	@AuraEnabled
	public static List<Opportunity> getOpportunities(String strAccountId) {
		try {
			List<Account> list_Accounts = [SELECT id, Name, RecordType.name FROM Account WHERE Id = :strAccountId];

			Account objAccount = list_Accounts[0];
			Id idAccount = objAccount.id;
			Id idOppPayrollRecordType = OpportunityUtil.COMPANY_OPPTY_RT_ID;
			Id idOppBenefitRecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
			Id idOppBORRecordTypeId = OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID;
			if (list_Accounts.size() == 0) {
				return new List<Opportunity>();
			}
			String strOppQuery = 'SELECT Id, Name, StageName, Recordtype.Name, Account.name, Owner.Name, Sold_By__c, Sold_By__r.Name, Referred_By__c, Referred_By__r.Name, ';
			strOppQuery += ' Account.ZP_Company_Overall_Status__c, Account.BillingState, Account.Owner.Name, Account.Anchor_Pay_Date__c, Account.ZP_Company_ID__c,';
			strOppQuery += ' Account.Joined_Date_Panda__c, Account.Link_Company__c, Account.RFI_Page__c, Account.RecordType.Name FROM Opportunity';

			if (objAccount.RecordType.Name == AccountUtil.RESELLER_ACCOUNT_TYPE) {
				strOppQuery += ' WHERE (Sold_By__c = :idAccount OR Referred_By__c = :idAccount) AND RecordTypeId = :idOppPayrollRecordType ';
			} else {
				strOppQuery += ' WHERE Account.Id = :idAccount AND (RecordTypeId = :idOppPayrollRecordType OR RecordTypeId = :idOppBenefitRecordTypeId OR RecordTypeId = :idOppBORRecordTypeId) ';
			}
			strOppQuery += ' LIMIT 20';
			return Database.query(strOppQuery);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @Author      : Lalitha Kasturi
	 * @Description : get Cases related to selected Contact Reason and Sub-Contact reason
	 * @Parm        : contact reason, sub contact reason and phone details are input params
	 * @Return      : List of Case
	 **/
	@AuraEnabled
	public static List<Case> getCases(String strPhone) {
		List<Case> list_CasesResult = new List<Case>();
		try {
			if (String.isNotBlank(strPhone)) {
				String strCaseQuery = 'SELECT Id, Status, RecordType.Name, CaseNumber, ContactId, Contact.Name, ContactPhone, ContactEmail, AccountId, Account.Name FROM Case';
				strCaseQuery += ' WHERE ContactPhone = :strPhone ';
				list_CasesResult = Database.query(strCaseQuery);
			}
		} catch (Exception objEx) {
			throw new AuraHandledException(objEx.getMessage());
		}
		return list_CasesResult;
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : remove special Char
	 * @Parm        : val
	 * @Return      : clean string
	 **/
	public static String specialCharacterSearch(String strVal) {
		String strFormated = '';
		String strPre = strVal.substringBefore('\'');
		String strAfter = strVal.substringAfter('\'');
		strFormated = '%' + strPre + '\\' + '\'' + strAfter + '%';
		return strFormated;
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Transfer Case
	 * @Parm        : strTaskId - Task Id
	 * @Return      : NA
	 **/
	@AuraEnabled
	public static Case transferCase(String strTaskId, String strCaseType) {
		Case objCase;
		Task objTask = [
			SELECT
				OwnerId,
				Case__c,
				WhatId,
				Primary_Call_Reason__c,
				Secondary_Call_Reason__c,
				Status,
				Subject,
				Description,
				CreatedById,
				CallDurationInSeconds,
				RecordTypeId,
				WhoId,
				Type,
				CompletedDateTime,
				LastModifiedById,
				Priority
			FROM Task
			WHERE Id = :strTaskId
		];

		Case objCaseToInsert = new Case(
			Subject = objTask.Subject,
			Description = objTask.Description,
			Duration_in_Seconds__c = objTask.CallDurationInSeconds,
			ClosedDate = objTask.CompletedDateTime,
			Priority = objTask.Priority,
			Direction__c = CASE_DIRECTION_INBOUND,
			RecordTypeId = CaseUtils.RECTYPE_SALES_CASES,
			Primary_Call_Reason__c = objTask.Primary_Call_Reason__c,
			Secondary_Call_Reason__c = objTask.Secondary_Call_Reason__c
		);

		objCaseToInsert.Case_Reason_L1__c = TASK_PRIMARY_CALL_REASON_TRANSFER;

		// Status:
		objCaseToInsert.Status = map_StatusMapping.containsKey(objTask.Status) ? map_StatusMapping.get(objTask.Status) : CASE_STATUS_NEW;

		// Type:
		objCaseToInsert.Type = map_TypeMapping.containsKey(objTask.Type) ? map_TypeMapping.get(objTask.Type) : CASE_TYPE_SALES_CALL;

		String strWhoSObjectName = objTask.WhoId?.getSObjectType().getDescribe().getName();
		String strWhatSObjectName = objTask.WhatId?.getSObjectType().getDescribe().getName();

		if (strWhoSObjectName == SOBJECT_NAME_CONTACT) {
			Contact objContact = queryContact(objTask.WhoId);

			objCaseToInsert.ContactId = objContact.Id;
			objCaseToInsert.SuppliedPhone = objContact.Phone;
			objCaseToInsert.SuppliedEmail = objContact.Email;
		} else if (strWhoSObjectName == SOBJECT_NAME_LEAD) {
			Lead objLead = queryLead(objTask.WhoId);

			objCaseToInsert.Lead__c = objLead.Id;
			objCaseToInsert.SuppliedPhone = objLead.Phone;
			objCaseToInsert.SuppliedEmail = objLead.Email;
		}

		if (strWhatSObjectName == SOBJECT_NAME_ACCOUNT) {
			objCaseToInsert.AccountId = objTask.WhatId;
		} else if (strWhatSObjectName == SOBJECT_NAME_OPPORTUNITY) {
			Opportunity objOpportunity = queryOpportunity(objTask.WhatId);
			objCaseToInsert.AccountId = objOpportunity.AccountId;
			objCaseToInsert.Opportunity__c = objOpportunity.Id;
		}
		if (objCaseToInsert != null && objTask.Primary_Call_Reason__c == TASK_PRIMARY_CALL_REASON_TRANSFER && objTask.Secondary_Call_Reason__c == TASK_SUB_CONTACT_REASON_TRANSFER_TO_CARE) {
			strCaseType = CaseUtils.TYPE_ENGAGEMENT;
		}

		Savepoint objSavepoint = Database.setSavepoint();

		if (blnTestCaseDMLException) {
			objCaseToInsert.Case_Reason_L1__c = 'test';
		}

		try {
			CaseUtils.caseRouting(strCaseType, objCaseToInsert);

			if (objCaseToInsert.Id == null) {
				// Cause DMLException
				DmlException objDmlException = new DmlException();
				objDmlException.setMessage(ERROR_MSG_CONTACT_ADMIN);

				throw objDmlException;
			}

			objCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :objCaseToInsert.Id];

			objTask.Primary_Call_Reason__c = TASK_PRIMARY_CALL_REASON_TRANSFER;
			objTask.Case__c = objCase.Id;

			if (blnTestTaskDMLException) {
				objTask.Primary_Call_Objective__c = 'test';
			}

			Database.SaveResult objTaskSaveResult = Database.update(objTask, false);
			if (!objTaskSaveResult.isSuccess()) {
				List<Database.Error> list_TaskSaveErrors = objTaskSaveResult.getErrors();
				ExceptionLogUtil.logException('InboundCallController', 'transferCase', list_TaskSaveErrors[0].getMessage(), '');

				if (!Test.isRunningTest()) {
					// Rollback to no Case insertion.
					Database.rollback(objSavepoint);
					throw new AuraHandledException(list_TaskSaveErrors[0].getMessage());
				}
			}
			return objCase;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('InboundCallController', 'transferCase', objException.getMessage(), objException.getStackTraceString());

			if (!Test.isRunningTest()) {
				throw new AuraHandledException(objException.getMessage());
			}
		}
		return null;
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : query config record that stores App name and base URLs.
	 * @Return      : App_URL_Map record.
	 **/
	@AuraEnabled(cacheable=true)
	public static List<App_URL_Map__c> getAppUrlMaps() {
		// check if instance is a Sandbox or Production
		Boolean blnIsSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;

		// Create a new environment variable
		String strEnvironment = blnIsSandbox ? ENV_DEV : ENV_PROD;

		return [SELECT Id, URL__c FROM App_URL_Map__c WHERE App_Name__c = :APP_NAME_PANDA AND Environment__c = :strEnvironment ORDER BY CreatedDate DESC LIMIT 1];
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Query Contact based on Contact Id
	 * @Parm        : idContactId - Contact Id
	 * @Return      : Contact
	 **/
	public static Contact queryContact(Id idContactId) {
		return [SELECT Id, Phone, Email FROM Contact WHERE Id = :idContactId];
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Query Lead based on Lead Id
	 * @Parm        : idLeadId - Lead Id
	 * @Return      : Lead
	 **/
	public static Lead queryLead(Id idLeadId) {
		return [SELECT Id, Phone, Email FROM Lead WHERE Id = :idLeadId];
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Query Opportunity based on Opportunity Id
	 * @Parm        : idOpportunityId - Opportunity Id
	 * @Return      : Opportunity
	 **/
	public static Opportunity queryOpportunity(Id idOpportunityId) {
		return [SELECT Id, AccountId FROM Opportunity WHERE Id = :idOpportunityId];
	}

	/**
	 * @Description : Query sales interaction record
	 * @Parm        : idRecord - Record Id of the Sales Interaction
	 * @Return      : Opportunity
	 **/
	@AuraEnabled
	public static Sales_Interaction__c querySalesInteraction(Id idRecord) {
		try {
			return [SELECT Id, DNIS__c, ANI__c, CCID__c FROM Sales_Interaction__c WHERE Id = :idRecord];
		} catch (Exception ex) {
			return null;
		}
	}
}