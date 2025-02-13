/**
 * @description Automatic send reminder & retire users if not logged in for long time period
 * @author      Ajay Krishna P U
 * @since       2024-05-01
 * @see         UserAuditBatchTest
 */
public class UserAuditBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
	public enum OPERATION_TYPE {
		OPERATION_DEACTIVATE_GUSTO_DESK_USER,
		OPERATION_SEND_NOTIFY_GUSTO_DESK_USER,
		OPERATION_DEACTIVATE_OTHER_USERS,
		OPERATION_SEND_NOTIFY_OTHER_USERS
	}
    
	//Date and Datetime values for User Last Login Activity
	private final static Date DT_TODAY = Date.today();
	private final static Date DT_PAST_90_DAYS = DT_TODAY.addDays(-90);
	private final static Date DT_PAST_60_DAYS = DT_TODAY.addDays(-60);
	private final static Datetime DTM_PAST_60_DAYS = Datetime.now().addDays(-60);

	//Constants
	private final static String HR_WORKER_INFO_STATUS_TERMINATED = 'Terminated';
	private final static String HR_WORKER_INFO_STATUS_LEAVE = 'On Leave';

	private final static String EMAIL_TEMPLATE_FOR_NOTIFY_GUSTO = 'Gusto_Desk_User_Audit';
	private final static String EMAIL_TEMPLATE_FOR_NOTIFY = 'Internal_User_Audit';

	//Custom Setting
	private final static User_Audit_Configuration__c USER_AUDIT_CONFIG = User_Audit_Configuration__c.getInstance();
	private final static Integer GUSTO_DESK_DEACTIVATION_DAYS = Integer.valueOf(USER_AUDIT_CONFIG.Gusto_Desk_Deactivation_Days__c) ?? 180; //~6Months
	private final static Set<Integer> SET_GUSTO_DESK_REMAINDER_DAYS = toIntegerSet(USER_AUDIT_CONFIG.Gusto_Desk_Remainder_Days_Collection__c ?? '150;173');

	private final static Integer INTERNAL_DEACTIVATION_DAYS = Integer.valueOf(USER_AUDIT_CONFIG.Internal_Deactivation_Days__c) ?? 90; //~3Months
	private final static Integer INTERNAL_MIN_REMAINDER_DAYS = Integer.valueOf(USER_AUDIT_CONFIG.Internal_Min_Remainder_Days__c) ?? 60; //~2Months
	private final static Set<Integer> SET_INTERNAL_REMAINDER_DAYS = toIntegerSet(USER_AUDIT_CONFIG.Internal_Remainder_Days_Collection__c ?? '60;69;76;83');
	
	public final static Integer CUSTOM_BATCH_SIZE = Integer.valueOf(USER_AUDIT_CONFIG.User_Audit_Batch_Size__c) ?? 10;
	public final static Integer CUSTOM_QUEUE_BATCH_SIZE = Integer.valueOf(USER_AUDIT_CONFIG.User_Update_Queue_batch_size__c) ?? 10;

	public final static String USER_ROLE_GUSTO_DESK = USER_AUDIT_CONFIG.User_Role_Gusto_Desk__c ?? 'Gusto Desk Partner Community User';
	private final static Set<String> SET_SKIP_USER_ROLES = new Set<String>((USER_AUDIT_CONFIG.Skip_User_Roles_Collection__c ?? 'admin;Integration User;UX Researcher Mng').split(';'));
	private final static Set<String> SET_USER_TYPES = new Set<String>((USER_AUDIT_CONFIG.User_Types_Collection__c ?? 'Standard;PowerPartner').split(';'));

	public final static String NOTE_FOR_DEACTIVATE = USER_AUDIT_CONFIG.Note_for_Deactivate__c ?? 'Deactivated by [User Audit Batch] - Due to no recent login.';
	public final static String NOTE_FOR_NOTIFY = USER_AUDIT_CONFIG.Note_for_Notify__c ?? 'User Audit Email Notification Sent.';

	private final static String GUSTO_DESK_SENDER_EMAIL_ADDRESS = USER_AUDIT_CONFIG.Gusto_Desk_Sender_Address__c ?? 'no-reply@gusto.com';
	private final static String INTERNAL_SENDER_EMAIL_ADDRESS = USER_AUDIT_CONFIG.Internal_Sender_Address__c ?? 'no-reply@gusto.com';

	//Instance variables
	private List<User> list_UsersToUpdate = new List<User>();
	private Map<String, Id> map_EmailTemplateNameToId = new Map<String, Id>();
	private Map<String, Id> map_OrgWideEmailAddressToId = new Map<String, Id>();
	private String strQuery;

	/**
	 * @description Default constructor
	 */
	public UserAuditBatch() {
		populateDefaults();
	}

	/**
	 * @description    Dynamic query supported constructor
	 * @param strQuery Query
	 */
	public UserAuditBatch(String strQuery) {
		this.strQuery = strQuery;
		populateDefaults();
	}

	/**
	 * @description Populate Integer set
	 * @return      `set_IntArray`
	 */
	public static Set<Integer> toIntegerSet(String strIntArray) {
		Set<Integer> set_IntArray = new Set<Integer>();
		if (strIntArray != null) {
			for (String strArray : strIntArray.split(';')) {
				set_IntArray.add(Integer.valueOf(strArray));
			}
		}	
		return set_IntArray;
	}

	/**
	 * @description Populates default
	 */
	private void populateDefaults() {
		Map<String, Id> map_EmailTemplateNameToId = new Map<String, Id>();
		Map<String, Id> map_OrgWideEmailAddressToId = new Map<String, Id>();

		for (EmailTemplate objTemplate : [
			SELECT Id, DeveloperName
			FROM EmailTemplate
			WHERE DeveloperName IN :new List<String>{ EMAIL_TEMPLATE_FOR_NOTIFY_GUSTO, EMAIL_TEMPLATE_FOR_NOTIFY }
		]) {
			map_EmailTemplateNameToId.put(objTemplate.DeveloperName, objTemplate.Id);
		}
		this.map_EmailTemplateNameToId = map_EmailTemplateNameToId;

		for (OrgWideEmailAddress objOrgWideEmailAddress : [
			SELECT Id, Address 
			FROM OrgWideEmailAddress
			WHERE Address IN :new Set<String>{ GUSTO_DESK_SENDER_EMAIL_ADDRESS, INTERNAL_SENDER_EMAIL_ADDRESS }
		]) {
			map_OrgWideEmailAddressToId.put(objOrgWideEmailAddress.Address, objOrgWideEmailAddress.Id);
		}
		this.map_OrgWideEmailAddressToId = map_OrgWideEmailAddressToId;
	}

	/**
	 * @description      Batch start method
	 * @param objContext Batch Context
	 * @return           `Database.QueryLocator`
	 */
	public Database.QueryLocator start(Database.BatchableContext objContext) {
		if (strQuery != null) {
			return Database.getQueryLocator(strQuery);
		}

		return Database.getQueryLocator(
			[
				SELECT Id, LastLoginDate, CreatedDate, HR_Worker_Information_Status__c, IsActive, Last_Updated_At__c, User_Role_Identifier__c, UserType
				FROM User
				WHERE
					IsActive = TRUE
					AND HR_Worker_Information_Status__c != :HR_WORKER_INFO_STATUS_LEAVE
					AND User_Role_Identifier__c NOT IN :SET_SKIP_USER_ROLES
					AND CreatedDate <= :DTM_PAST_60_DAYS
					AND (LastLoginDate = NULL
					OR LastLoginDate <= :DTM_PAST_60_DAYS)
					AND UserType IN :SET_USER_TYPES
			]
		);
	}

	/**
	 * @description      Batch job execute method
	 * @param objContext batch Context
	 * @param list_Users List of User to process
	 */
	public void execute(Database.BatchableContext objContext, List<User> list_Users) {
		List<Messaging.SingleEmailMessage> list_EmailMessages = new List<Messaging.SingleEmailMessage>();
		for (User objUser : list_Users) {
			OPERATION_TYPE enOpType = identifyOperation(objUser, objUser.CreatedDate, objUser.LastLoginDate, objUser.User_Role_Identifier__c);

			switch on enOpType {
				when OPERATION_DEACTIVATE_GUSTO_DESK_USER, OPERATION_DEACTIVATE_OTHER_USERS {
					objUser.IsActive = false;
					objUser.Notes__c = NOTE_FOR_DEACTIVATE;
					list_UsersToUpdate.add(objUser);
				}
				when OPERATION_SEND_NOTIFY_GUSTO_DESK_USER, OPERATION_SEND_NOTIFY_OTHER_USERS {
					list_EmailMessages.add(getEmailMessage(objUser.Id, enOpType));
					objUser.Notes__c = NOTE_FOR_NOTIFY;
					list_UsersToUpdate.add(objUser);
				}
			}
		}

		if (!list_EmailMessages.isEmpty()) {
			List<Messaging.SendEmailResult> list_EmailResults = Messaging.sendEmail(list_EmailMessages, false);
			List<Exception_Log__c> list_EmailExceptions = processEmailResults(list_EmailResults);
			if (!list_EmailExceptions.isEmpty()) {
				Database.insert(list_EmailExceptions, false);
			}
		}
	}

	/**
	 * @description Batch finish method
	 * @param objContext Batch context
	 */
	public void finish(Database.BatchableContext objContext) {
		// Update the user records
		if (!list_UsersToUpdate.isEmpty()) {
			System.enqueueJob(new BatchUserUpdateQueue(list_UsersToUpdate, CUSTOM_QUEUE_BATCH_SIZE));
		}
	}

	/**
	 * @description    Generate Email Message
	 * @param idUser   Id of the user to send email
	 * @param enOpType Operation Type
	 * @return         `EmailMessage`
	 */
	@testVisible
	private Messaging.SingleEmailMessage getEmailMessage(Id idUser, OPERATION_TYPE enOpType) {
		Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
		objEmail.setTargetObjectId(idUser);
		objEmail.setSaveAsActivity(false);
		if (USER_AUDIT_CONFIG.ccAddress__c != null){
			objEmail.setCcAddresses(USER_AUDIT_CONFIG.ccAddress__c.split(';'));
		}
		
		switch on enOpType {
			when OPERATION_SEND_NOTIFY_GUSTO_DESK_USER {
				objEmail.setTemplateId(this.map_EmailTemplateNameToId.get(EMAIL_TEMPLATE_FOR_NOTIFY_GUSTO));
				objEmail.setOrgWideEmailAddressId(this.map_OrgWideEmailAddressToId.get(GUSTO_DESK_SENDER_EMAIL_ADDRESS));
			}
			when else {
				objEmail.setTemplateId(this.map_EmailTemplateNameToId.get(EMAIL_TEMPLATE_FOR_NOTIFY));
				objEmail.setOrgWideEmailAddressId(this.map_OrgWideEmailAddressToId.get(INTERNAL_SENDER_EMAIL_ADDRESS));
			}
		}

		return objEmail;
	}

	/**
	 * @description                Identify the operation (Deactivate / Send Remainder)
	 * The function accepts CreatedDate, LastLoginDate and User role as function parameter for easy testing all scenarios in test class
	 * @param objUser               User Record
	 * @param dtmCreatedDate        CreatedDate, datetime at which user created.
	 * @param dtmLastLoginDate      LastLoginDate, datetime at which user last login
	 * @param strUserRoleIdentifier User role
	 * @return                      `OPERATION_TYPE`
	 */
	@testVisible
	private static OPERATION_TYPE identifyOperation(User objUser, Datetime dtmCreatedDate, Datetime dtmLastLoginDate, String strUserRoleIdentifier) {
		Date dtCreatedDate = dtmCreatedDate != null ? dtmCreatedDate.date() : null;
		Date dtLastLoginDate = dtmLastLoginDate != null ? dtmLastLoginDate.date() : null;

		Integer intNoOfDaysSinceLastLogin = dtLastLoginDate != null ? dtLastLoginDate.daysBetween(DT_TODAY) : dtCreatedDate.daysBetween(DT_TODAY);

		//Gusto Desk User
		if (strUserRoleIdentifier == USER_ROLE_GUSTO_DESK) {
			if (intNoOfDaysSinceLastLogin >= GUSTO_DESK_DEACTIVATION_DAYS) {
				//Not logged in for 6 months --> Deactivate Gusto Desk
				return OPERATION_TYPE.OPERATION_DEACTIVATE_GUSTO_DESK_USER;
			} else if (SET_GUSTO_DESK_REMAINDER_DAYS.contains(intNoOfDaysSinceLastLogin)) {
				//30days before 6Months and 7 days before 6 Months ==> Send Remainder
				return OPERATION_TYPE.OPERATION_SEND_NOTIFY_GUSTO_DESK_USER;
			}

			return null;
		}

		//Other Users
		Integer intNoOfDaysSinceUpdated = objUser.Last_Updated_At__c == null ? null : objUser.Last_Updated_At__c.daysBetween(DT_TODAY);

		// Not logged in for 3Months and WorkerInfo not updated for 3Months --> Deactivate
		if (
			intNoOfDaysSinceLastLogin >= INTERNAL_DEACTIVATION_DAYS &&
			(intNoOfDaysSinceUpdated == null ||
			intNoOfDaysSinceUpdated >= INTERNAL_DEACTIVATION_DAYS ||
			objUser.HR_Worker_Information_Status__c == HR_WORKER_INFO_STATUS_TERMINATED)
		) {
			return OPERATION_TYPE.OPERATION_DEACTIVATE_OTHER_USERS;

			//Not Logged for 2 Months and WorkerInfo  not updated for 2Months --> Send Email
		} else if (
			intNoOfDaysSinceLastLogin >= INTERNAL_MIN_REMAINDER_DAYS &&
			objUser.HR_Worker_Information_Status__c != HR_WORKER_INFO_STATUS_TERMINATED &&
			(intNoOfDaysSinceUpdated == null ||
			intNoOfDaysSinceUpdated >= INTERNAL_MIN_REMAINDER_DAYS)
		) {
			// Send email on every week like before 30 days, 21 days, 14 days and 7 days
			if (SET_INTERNAL_REMAINDER_DAYS.contains(intNoOfDaysSinceLastLogin)) {
				return OPERATION_TYPE.OPERATION_SEND_NOTIFY_OTHER_USERS;
			}
		}
		return null;
	}

	/**
	 * @description Schedulable Execute method
	 * @param objContext
	 */
	public void execute(SchedulableContext objContext) {
		Database.executeBatch(new UserAuditBatch(), CUSTOM_BATCH_SIZE);
	}

	/**
	 * @description             Process email results and generate exception logs
	 * @param list_EmailResults Email Results
	 * @return                  `List<Exception_Log__c>`
	 */
	@testVisible
	private List<Exception_Log__c> processEmailResults(List<Messaging.SendEmailResult> list_EmailResults) {
		List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();

		for (Messaging.SendEmailResult objEmailResult : list_EmailResults) {
			if (!objEmailResult.isSuccess()) {
				for (Messaging.SendEmailError objError : objEmailResult.getErrors()) {
					Exception_Log__c objLog = new Exception_Log__c(
						Class_Name__c = 'UserAuditBatch',
						Method_Name__c = 'ExceptionCreateQueue',
						Message__c = objError.getMessage(),
						Type__c = String.valueOf(objError.getStatusCode())
					);
					list_ExceptionLogs.add(objLog);
				}
			}
		}

		return list_ExceptionLogs;
	}

	/**
	 * Queue job to update User object - to avoid Mixed DML issues
	 * The queue support batchable solution as well
	 */
	public class BatchUserUpdateQueue implements Queueable {
		private List<User> list_Users;
		private Integer intBatchSize;
		private List<Exception_Log__c> list_ExceptionToInsert = new List<Exception_Log__c>();

		public BatchUserUpdateQueue() {
		}
		public BatchUserUpdateQueue(List<User> list_Users, Integer intBatchSize) {
			this.list_Users = list_Users;
			this.intBatchSize = intBatchSize;
		}

		/**
		 * @description   Queueable Execute method
		 * @param objContext
		 */
		public void execute(QueueableContext objContext) {
			if (list_Users == null || list_Users.isEmpty()) {
				return;
			}

			List<User> list_BatchRecords = new List<User>();

			//Extract batch of records
			BatchUserUpdateQueue objFollowupJob = null;
			if (list_Users.size() > intBatchSize) {
				for (integer i = 0; i < intBatchSize; ++i) {
					list_BatchRecords.add(this.list_Users.remove(0));
				}
				objFollowupJob = new UserAuditBatch.BatchUserUpdateQueue(this.list_Users, this.intBatchSize);
			} else {
				list_BatchRecords = list_Users;
			}

			//Do Update
			List<Database.SaveResult> list_SaveResult = Database.update(list_BatchRecords, false);
			List<Exception_Log__c> list_Exceptions = processSaveResults(list_SaveResult);
			list_ExceptionToInsert.addAll(list_Exceptions);

			if (objFollowupJob != null) {
				objFollowupJob.list_ExceptionToInsert = list_ExceptionToInsert;
				System.enqueueJob(objFollowupJob);
			} else {
				if (!list_ExceptionToInsert.isEmpty()) {
					System.enqueueJob(new ExceptionCreateQueue(list_ExceptionToInsert));
				}
			}
		}

		/**
		 * @description           Process DML errors
		 * @param list_SaveResult Save Results
		 * @return                `List<Exception_Log__c>`
		 */
		@testVisible
		private List<Exception_Log__c> processSaveResults(Database.SaveResult[] list_SaveResult) {
			List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();

			for (Database.SaveResult objSaveResult : list_SaveResult) {
				if (!objSaveResult.isSuccess()) {
					Id idFailedRecord = objSaveResult.getId();
					for (Database.Error objError : objSaveResult.getErrors()) {
						Exception_Log__c objLog = new Exception_Log__c(
							Class_Name__c = 'UserAuditBatch',
							Method_Name__c = 'BatchUserUpdateQueue',
							Record_ID__c = idFailedRecord,
							Message__c = objError.getMessage(),
							Type__c = String.valueOf(objError.getStatusCode())
						);
						list_ExceptionLogs.add(objLog);
					}
				}
			}

			return list_ExceptionLogs;
		}
	}

	/**
	 * Exception Creation Batch -to avoid Mixed DML
	 */
	public class ExceptionCreateQueue implements Queueable {
		private List<Exception_Log__c> list_Exceptions;

		public ExceptionCreateQueue(List<Exception_Log__c> list_Exceptions) {
			this.list_Exceptions = list_Exceptions;
		}

		/**
		 * @description   Queueable Execute method
		 * @param objContext
		 */
		public void execute(QueueableContext objContext) {
			if (!this.list_Exceptions.isEmpty()) {
				Database.insert(this.list_Exceptions, false);
			}
		}
	}
}