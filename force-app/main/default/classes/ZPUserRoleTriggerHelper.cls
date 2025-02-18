/**
 * @description  Refactored ZPUserRoleTriggerHelper. Used for creating company and reseller contacts, creating oppty contact roles etc
 * @author       Praveen Sethu
 * @date         02-12-2021
 * @see          ZPUserRoleTriggerHelperTest
 **/
public class ZPUserRoleTriggerHelper {
	public static Boolean skipTrigger = false;

	// Constants referred in other classes. Hence cannot move over to ZPUserRoleUtil
	public static String PRIMARY_PAYROLL_ADMIN = Label.Primary_Payroll_Admin;
	public static String PAYROLL_ADMIN = Label.Payroll_Admin;
	public static String BENEFIT_SIGNATORY = Label.Benefits_Signatory;
	public static String SIGNATORY = Label.Signatory;
	public static String BENEFITS_ADMIN = Label.Benefits_Admin;
	public static String ACCOUNTANT = Label.Accountant;
	public static String EMPLOYEE = Label.Employee;
	public static String CONTRACTOR = Label.Contractor;
	public static String OTHER_EXTERNAL_COLLABORATOR = Label.Other_External_Collaborator;
	public static String EXTERNAL_ACCOUNTANT = Label.External_Accountant;
	public static String EXTERNAL_BOOKKEEPER = Label.External_Bookkeeper;

	/*** All Map Variables ***/
	private Map<String, List<ZP_User_Role__c>> map_CompanyIdToZPUserRoles;
	private Map<String, List<ZP_User_Role__c>> map_ZPUserIdToZPUserRoles;
	private Map<String, ZP_User_Role__c> map_ZPUserIdToABCRole;
	private Map<String, ZP_User_Role__c> map_ZPUserIdToAccountantRole;
	private Map<String, ZP_User_Role__c> map_ZPUserIdToEmployeeRole;
	private Map<String, ZP_User_Role__c> map_ZPUserIdToPayrollAdminRole;
	private Map<String, ZP_User_Role__c> map_ZPUserIdToContractorRole;
	private Map<String, ZP_User_Role__c> map_ZPUserIdToSignatoryRole;
	private Map<String, Set<String>> map_UserIdToRoleNamesSet;
	private Map<String, List<ZP_User_Role__c>> map_UserIdToRoles;
	private Map<String, ZP_User__c> map_ZPUserIdToZPUser;
	private Map<String, Account> map_ZPCompanyIdToAccount;
	private Map<String, Account> map_ZPAccFirmToAccount;
	private Map<String, ZP_Employee__c> map_EmployeeIds;
	private Map<Id, ZP_User__c> map_UsersToReProcess;
	private Map<String, Contact> map_ZPUserIdToContact;
	private Map<String, Contact> map_EmailToContact;
	private Map<String, Contact> map_UniqueEmailToContact;
	private Map<String, Lead> map_EmailToLead;
	private Map<Id, Contact> map_ContactsToUpdate;
	private Map<Id, Account> map_AccountsToUpdate;
	private Map<Id, Lead> map_LeadsToUpdate;
	private Map<Id, ZP_User_Role__c> map_UserRolesToUpdate;
	private Map<String, Contact> map_ZPUserIdNewContact;
	private Map<String, String> map_ContactDMLErrors;
	private Map<String, Account> map_EmailDomainToAccounts;
	private Map<Id, Set<String>> map_AccountIdToContactRoleSet;
	private Map<Id, Set<String>> map_AccountIdToDeleteContactRoleSet;
	private Map<String, OpportunityContactRole> map_ConIdRoleToOppConRole;
	private static Map<Id, OpportunityContactRole> map_OppConRoleToDelete;

	/*** All Set Variables ***/
	private Set<String> set_UserIds;
	private Set<String> set_CompanyIds;
	private Set<String> set_AllCompanyIds;
	private Set<String> set_AccountingFirmIds;
	private Set<String> set_EmployeeIds;
	private Set<Id> set_UserRoleIds;
	private Set<String> set_ZPUserEmails;
	private Set<String> set_ZPUserEmailDomains;
	private Set<String> set_ZPUserIdsToReProcess;
	private Set<String> set_UserRoleNames;
	private Set<Id> set_prioritizedRoleIds;

	/*** All List Variables ***/
	private List<ZP_User_Role__c> list_UserRolesToUpdate;
	private List<OpportunityContactRole> list_OppConRolesToInsert;
	public static final List<String> PRIORITIZED_ROLES = System.Label.ZP_User_Role_Prioritized_Roles.split(',');

	public static final String DEAD_STATE = 'Dead';
	public static final String MANUAL_ENQUEUE = 'Manually Enqueued';

	// Constructor:
	public ZPUserRoleTriggerHelper() {
		/*** All Map Variables ***/
		map_CompanyIdToZPUserRoles = new Map<String, List<ZP_User_Role__c>>();
		map_ZPUserIdToZPUserRoles = new Map<String, List<ZP_User_Role__c>>();
		map_ZPUserIdToABCRole = new Map<String, ZP_User_Role__c>();
		map_ZPUserIdToAccountantRole = new Map<String, ZP_User_Role__c>();
		map_ZPUserIdToEmployeeRole = new Map<String, ZP_User_Role__c>();
		map_ZPUserIdToPayrollAdminRole = new Map<String, ZP_User_Role__c>();
		map_ZPUserIdToContractorRole = new Map<String, ZP_User_Role__c>();
		map_ZPUserIdToSignatoryRole = new Map<String, ZP_User_Role__c>();
		map_UserIdToRoleNamesSet = new Map<String, Set<String>>();
		map_UserIdToRoles = new Map<String, List<ZP_User_Role__c>>();
		map_ZPUserIdToZPUser = new Map<String, ZP_User__c>();
		map_ZPCompanyIdToAccount = new Map<String, Account>();
		map_ZPAccFirmToAccount = new Map<String, Account>();
		map_EmployeeIds = new Map<String, ZP_Employee__c>();
		map_UsersToReProcess = new Map<Id, ZP_User__c>();
		map_ZPUserIdToContact = new Map<String, Contact>();
		map_EmailToContact = new Map<String, Contact>();
		map_UniqueEmailToContact = new Map<String, Contact>();
		map_EmailToLead = new Map<String, Lead>();
		map_ContactsToUpdate = new Map<Id, Contact>();
		map_AccountsToUpdate = new Map<Id, Account>();
		map_UserRolesToUpdate = new Map<Id, ZP_User_Role__c>();
		map_LeadsToUpdate = new Map<Id, Lead>();
		map_ZPUserIdNewContact = new Map<String, Contact>();
		map_ContactDMLErrors = new Map<String, String>();
		map_EmailDomainToAccounts = new Map<String, Account>();
		map_AccountIdToContactRoleSet = new Map<Id, Set<String>>();
		map_AccountIdToDeleteContactRoleSet = new Map<Id, Set<String>>();
		map_ConIdRoleToOppConRole = new Map<String, OpportunityContactRole>();
		map_OppConRoleToDelete = new Map<Id, OpportunityContactRole>();

		/*** All Set Variables ***/
		set_UserIds = new Set<String>();
		set_CompanyIds = new Set<String>();
		set_AllCompanyIds = new Set<String>();
		set_AccountingFirmIds = new Set<String>();
		set_UserRoleIds = new Set<Id>();
		set_ZPUserEmails = new Set<String>();
		set_ZPUserEmailDomains = new Set<String>();
		set_EmployeeIds = new Set<String>();
		set_ZPUserIdsToReProcess = new Set<String>();
		set_UserRoleNames = new Set<String>();
		set_prioritizedRoleIds = new Set<Id>();

		/*** All List Variables ***/
		list_UserRolesToUpdate = new List<ZP_User_Role__c>();
		list_OppConRolesToInsert = new List<OpportunityContactRole>();
	}

	/**
	 * @description Handles before insert functionaluty. Sets record to Queued status
	 * @author      Praveen Sethu
	 * @param       list_ZPUserRoles - List from Trigger.new
	 * @return      NA
	 **/
	public void processBeforeInsert(List<ZP_User_Role__c> list_ZPUserRoles) {
		// On insert only change processing state to Queued
		// for processing it'll be picked up by batch job.
		for (ZP_User_Role__c objZPUserRole : list_ZPUserRoles) {
			objZPUserRole.Processing_State__c = IntegrationUtils.QUEUED_STATE;
		}
	}

	/**
	 * @description Handles after insert functionality.
	 * @param       list_ZPUserRoles - List from Trigger.new
	 * @return      NA
	 **/
	public void processAfterInsert(List<ZP_User_Role__c> list_ZPUserRoles) {
		//Add prioritized roles if any to set for immediate batch processing
		for (ZP_User_Role__c objZPUserRole : list_ZPUserRoles) {
			if (PRIORITIZED_ROLES != null && PRIORITIZED_ROLES.contains(objZPUserRole.Role_Name__c)) {
				set_prioritizedRoleIds.add(objZPUserRole.Id);
			}
		}
		if (!set_prioritizedRoleIds.isEmpty()) {
			processPrioritizedRoles();
		}
	}

	/**
	 * @description Prioritized roles are chunked for processing immediately.
	 * @param       None - Uses global set variable.
	 * @return      NA
	 * @see			ZPUserRoleTriggerHelperTest.testPrioritizedRolesProcessing
	 **/
	public void processPrioritizedRoles() {
		String strBatchSize = System.Label.ZP_User_Role_Prioritized_Roles_Batch_Size;
		Integer intBatch = String.isNotBlank(strBatchSize) && Integer.valueOf(strBatchSize) != 0 ? Integer.valueOf(strBatchSize) : 25;
		// If the prioritized roles are less than batch size, process them immediately
		if (set_prioritizedRoleIds.size() <= intBatch && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
			Id idQueueJobId = System.enqueueJob(new BatchCleanUpZPUserRoles.BatchCleanUpZPUserRolesQueuable(new BatchCleanUpZPUserRoles(set_prioritizedRoleIds)));
		} else {
			// If the prioritized roles are more than batch size, split them into batches and process
			Set<Id> set_RoleIdsSplit = new Set<Id>();
			Set<Id> set_RoleIdsRemaining = new Set<Id>();
			Integer intSplitCount = 0;
			// Initiliaze a new split, loop through the prioritized roles and add to it. If the batch size is reached, enqueue the batch job, reset the split count and split set.
			// If the queuable limit is reached, add the remaining roles to a set for logging.
			for (Id idRole : set_prioritizedRoleIds) {
				// Enqueue queueable job only if the limit is not reached
				if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
					if (intSplitCount < intBatch) {
						set_RoleIdsSplit.add(idRole);
						intSplitCount++;
					} else {
						Id idQueueJobId = System.enqueueJob(new BatchCleanUpZPUserRoles.BatchCleanUpZPUserRolesQueuable(new BatchCleanUpZPUserRoles(set_RoleIdsSplit)));
						// Reset count after every batch is enqueued
						intSplitCount = 0;
						set_RoleIdsSplit = new Set<Id>();
					}
				} else {
					set_RoleIdsRemaining.add(idRole);
				}
			}
			// If the split set is not empty after loop ends, enqueue the batch job
			if (!set_RoleIdsSplit.isEmpty()) {
				Id idQueueJobId = System.enqueueJob(new BatchCleanUpZPUserRoles.BatchCleanUpZPUserRolesQueuable(new BatchCleanUpZPUserRoles(set_RoleIdsSplit)));
			}
			// If there are roles left to be processed, log them
			if (!set_RoleIdsRemaining.isEmpty()) {
				System.debug('*****ZP User role processing were left to be prioritized for ' + set_RoleIdsRemaining.size() + '*****');
			}
		}
	}

	/**
	 * @description Handles before insert functionaluty. Validates processing state and sets record to Queued status
	 * @author      Praveen Sethu
	 * @param       map_ZPUserRoles - Map from Trigger.newMap
	 * @param       map_OldZPUserRoles - Map from Trigger.oldMap
	 * @return      NA
	 **/
	public void processBeforeUpdate(Map<Id, ZP_User_Role__c> map_ZPUserRoles, Map<Id, ZP_User_Role__c> map_OldZPUserRoles) {
		Boolean blnIsManuallyEnqueued = !map_ZPUserRoles.isEmpty() && map_ZPUserRoles.values().get(0).Processing_State__c == IntegrationUtils.MANUAL_ENQUEUE;

		if (!blnIsManuallyEnqueued) {
			// Not manually Enqueued (Mimim update usually caused by Workato)
			for (ZP_User_Role__c objZPUserRole : map_ZPUserRoles.values()) {
				ZP_User_Role__c objOldZPUserRole = map_OldZPUserRoles.get(objZPUserRole.Id);

				// Allow records to be in Backlog or Dead instead of defaulting to queued for every update
				if (objOldZPUserRole.Processing_State__c != IntegrationUtils.BACKLOG && objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG) {
					objZPUserRole.Processing_State__c = IntegrationUtils.BACKLOG;
				} else if (objOldZPUserRole.Processing_State__c != IntegrationUtils.DEAD_STATE && objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					objZPUserRole.Processing_State__c = IntegrationUtils.DEAD_STATE;
				} else {
					objZPUserRole.Processing_State__c = IntegrationUtils.QUEUED_STATE; //set status to queued
					// Reset message field
					objZPUserRole.Message__c = '';
				}

				// Observe if user id changes and reset lookup fields
				if (objZPUserRole.User_Id__c != null && objOldZPUserRole.User_Id__c != objZPUserRole.User_Id__c) {
					objZPUserRole.Accounting_Firm_Account__c = null;
					objZPUserRole.Company_Account__c = null;
					objZPUserRole.Contact__c = null;
					objZPUserRole.Zp_User__c = null;
					objZPUserRole.Previous_User_Id__c = objOldZPUserRole.User_Id__c;
				}
			}
		} else {
			processUserRoleInformation(map_ZPUserRoles.values());
		}
	}

	/**
	 * @description Sets collection for before update and also validates for basic input data
	 * @author      Praveen Sethu
	 * @param       list_NewRoles - List of new user roles
	 * @return      NA
	 **/
	public void setCollectionsBeforeUpdate(List<ZP_User_Role__c> list_NewRoles) {
		for (ZP_User_Role__c objRole : list_NewRoles) {
			objRole.Message__c = '';
			set_UserRoleIds.add(objRole.Id);

			if (String.isBlank(objRole.User_Id__c)) {
				setProcessingStateAndMessage(objRole, IntegrationUtils.DEAD_STATE, ZPUserRoleUtil.USER_ID_MISSING_ON_USER_ROLE);
				continue;
			}

			// Set default last name if last name is blank
			if (objRole.Deleted_At__c == null && String.isBlank(objRole.Last_Name__c)) {
				objRole.Last_Name__c = ZPUserRoleUtil.DEFAULT_LAST_NAME;
			}

			// Set of User Ids
			if (String.isNotBlank(objRole.User_Id__c)) {
				set_UserIds.add(objRole.User_Id__c);
			}

			// Set of Company Ids
			if (String.isNotBlank(objRole.Company_Id__c)) {
				set_AllCompanyIds.add(objRole.Company_Id__c);
				set_CompanyIds.add(objRole.Company_Id__c);
			}

			// Set of Accounting Firm Ids
			if (String.isNotBlank(objRole.Accounting_Firm_Id__c)) {
				set_AccountingFirmIds.add(objRole.Accounting_Firm_Id__c);
			}

			// Set of Employee Ids
			if (String.isNotBlank(objRole.Employee_Id__c)) {
				set_EmployeeIds.add(objRole.Employee_Id__c);
			}
		}

		// Build a map of company Id and user roles
		if (!set_CompanyIds.isEmpty()) {
			getUserRolesByCompanyId(set_CompanyIds);
		}
		// Build a map of user id and user roles and also set different maps for different roles
		if (!set_UserIds.isEmpty()) {
			seggregateUserRoles(set_UserIds);

			// Build a map of User Id and User
			for (ZP_User__c objZPUser : queryZPUsers(set_UserIds)) {
				map_ZPUserIdToZPUser.put(objZPUser.Id__c, objZPUser);

				// Re-process users if they are backlogged or Dead
				if (objZPUser.Processing_State__c == IntegrationUtils.BACKLOG || objZPUser.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					if (
						objZPUser.Processing_State__c == IntegrationUtils.DEAD_STATE &&
						String.isNotBlank(objZPUser.Message__c) &&
						objZPUser.Message__c.containsIgnoreCase(ZPUserRoleUtil.INVALID_EMAIL_ADDRESS_ERROR)
					) {
						continue;
					}

					map_UsersToReProcess.put(objZPUser.Id, objZPUser);
				}

				if (String.isNotBlank(objZPUser.Email__c)) {
					set_ZPUserEmails.add(objZPUser.Email__c);
					set_ZPUserEmailDomains.add(objZPUser.Email__c.split('@')[1]);
				}
			}
		}

		// Build a map of reseller and company accounts with acc firm id and company id
		setAccountCollections();

		if (!set_EmployeeIds.isEmpty()) {
			// Build a map of Employee Id and User
			for (ZP_Employee__c objEmployee : queryEmployees(set_EmployeeIds)) {
				map_EmployeeIds.put(objEmployee.Id__c, objEmployee);
			}
		}

		// Query contacts by user id and email addresses and built different maps of contacts
		if (!set_UserIds.isEmpty() || !set_ZPUserEmails.isEmpty()) {
			for (Contact objContact : queryContacts(set_UserIds, set_ZPUserEmails)) {
				if (String.isNotBlank(objContact.ZP_User_Id__c)) {
					map_ZPUserIdToContact.put(objContact.ZP_User_Id__c, objContact);
				}

				if (String.isNotBlank(objContact.Email)) {
					map_EmailToContact.put(objContact.Email, objContact);
				}

				if (String.isNotBlank(objContact.Unique_Email_Address_Contact__c)) {
					map_UniqueEmailToContact.put(objContact.Unique_Email_Address_Contact__c, objContact);
				}
			}
		}

		if (!set_ZPUserEmails.isEmpty()) {
			for (Lead objLead : queryLeads(set_ZPUserEmails)) {
				map_EmailToLead.put(objLead.Email, objLead);
			}
		}

		if (!set_ZPUserEmailDomains.isEmpty()) {
			for (Account_Email_Domain__c objAccEmailDomain : queryAccountEmailDomains(set_ZPUserEmailDomains)) {
				map_EmailDomainToAccounts.put(objAccEmailDomain.Name, objAccEmailDomain.Account__r);
			}
		}
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Build a map of reseller and company accounts with acc firm id and company id
	 * @param       : objZPUserRole - New ZPUserRole
	 * @return      : N/A
	 **/
	public void setAccountCollections() {
		if (!set_AllCompanyIds.isEmpty() || !set_AccountingFirmIds.isEmpty()) {
			for (Account objAccount : queryAccounts(set_AllCompanyIds, set_AccountingFirmIds)) {
				if (objAccount.RecordTypeId == ZPUserRoleUtil.ACCOUNT_COMPANY_RT_ID || objAccount.RecordTypeId == ZPUserRoleUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID) {
					map_ZPCompanyIdToAccount.put(objAccount.ZP_Company_ID__c, objAccount);
				} else if (objAccount.RecordTypeId == ZPUserRoleUtil.ACCOUNT_RESELLER_RT_ID) {
					map_ZPAccFirmToAccount.put(objAccount.ZP_Firm_ID__c, objAccount);
				}
			}
		}
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Builds different maps of user id and user roles
	 * @param       : Set<String> - Set of User Ids
	 * @return      : N/A
	 **/
	public void seggregateUserRoles(Set<String> set_UserIds) {
		for (ZP_User_Role__c objZPUserRole : queryZpUserRoleByUserId(set_UserIds)) {
			// Build a map of User Id and User Roles
			if (map_ZPUserIdToZPUserRoles.containsKey(objZPUserRole.User_Id__c)) {
				map_ZPUserIdToZPUserRoles.get(objZPUserRole.User_Id__c).add(objZPUserRole);
			} else {
				map_ZPUserIdToZPUserRoles.put(objZPUserRole.User_Id__c, new List<ZP_User_Role__c>{ objZPUserRole });
			}

			if (String.isNotBlank(objZPUserRole.Company_Id__c)) {
				set_AllCompanyIds.add(objZPUserRole.Company_Id__c);
			}

			if (String.isNotBlank(objZPUserRole.Accounting_Firm_Id__c)) {
				set_AccountingFirmIds.add(objZPUserRole.Accounting_Firm_Id__c);
			}

			Set<String> set_RoleNames = new Set<String>();
			List<ZP_User_Role__c> list_Roles = new List<ZP_User_Role__c>();

			if (map_UserIdToRoleNamesSet.containsKey(objZPUserRole.User_Id__c)) {
				set_RoleNames = map_UserIdToRoleNamesSet.get(objZPUserRole.User_Id__c);
				list_Roles = map_UserIdToRoles.get(objZPUserRole.User_Id__c);
			}

			// Build different maps of user id and roles
			if (String.isNotBlank(objZPUserRole.Role_Name__c)) {
				if (
					objZPUserRole.Role_Name__c == ZPUserRoleUtil.PAYROLL_ADMIN &&
					(objZPUserRole.Collaborator_Type__c == ZPUserRoleUtil.EXTERNAL_BOOKKEEPER ||
					objZPUserRole.Collaborator_Type__c == ZPUserRoleUtil.EXTERNAL_ACCOUNTANT)
				) {
					map_ZPUserIdToABCRole.put(objZPUserRole.User_Id__c, objZPUserRole);
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.ACCOUNTANT) {
					map_ZPUserIdToAccountantRole.put(objZPUserRole.User_Id__c, objZPUserRole);
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.PAYROLL_ADMIN || objZPUserRole.Role_Name__c == ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN) {
					map_ZPUserIdToPayrollAdminRole.put(objZPUserRole.User_Id__c, objZPUserRole);
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.EMPLOYEE) {
					map_ZPUserIdToEmployeeRole.put(objZPUserRole.User_Id__c, objZPUserRole);
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.CONTRACTOR) {
					map_ZPUserIdToContractorRole.put(objZPUserRole.User_Id__c, objZPUserRole);
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.SIGNATORY) {
					map_ZPUserIdToSignatoryRole.put(objZPUserRole.User_Id__c, objZPUserRole);
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.INTERNATIONAL_CONTRACTOR) {
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.COMPANY_MEMBER && objZPUserRole.Employment_Type__c == ZPUserRoleUtil.INTERNATIONALEMPLOYEE) {
					set_RoleNames.add(ZPUserRoleUtil.INTERNATIONAL_EMPLOYEE);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.COMPANY_MEMBER && objZPUserRole.Employment_Type__c == ZPUserRoleUtil.INTERNATIONALCONTRACTOR) {
					set_RoleNames.add(ZPUserRoleUtil.INTERNATIONAL_CONTRACTOR);
					list_Roles.add(objZPUserRole);
				}

				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.INTERNATIONAL_EMPLOYEE) {
					set_RoleNames.add(objZPUserRole.Role_Name__c);
					list_Roles.add(objZPUserRole);
				}

				// Do not add user role from trigger context
				if (!set_UserRoleIds.contains(objZPUserRole.Id)) {
					list_UserRolesToUpdate.add(objZPUserRole);
				}
				map_UserIdToRoleNamesSet.put(objZPUserRole.User_Id__c, set_RoleNames);
				map_UserIdToRoles.put(objZPUserRole.User_Id__c, list_Roles);
			}
		}
	}

	/**
	 * @description Handles all business logic. Upserts contacts, Oppty Contact Roles and Updates Leads
	 * @author      Praveen Sethu
	 * @param       list_NewRoles - List of new user roles
	 * @return      NA
	 **/
	public void processUserRoleInformation(List<ZP_User_Role__c> list_NewRoles) {
		setCollectionsBeforeUpdate(list_NewRoles);

		for (ZP_User_Role__c objZPUserRole : list_NewRoles) {
			// Set ZP User Lookup
			setZPUser(objZPUserRole);

			if (objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			// Set Company Account Lookup
			setZPCompany(objZPUserRole);
			// Set Accounting Firm Lookup
			setAccountingFirm(objZPUserRole);
			// Upsert Reseller/Company Contacts
			processContactInformation(objZPUserRole);
			// Update Lead Information
			setLeadInformation(objZPUserRole);
			// Set Payment method from ZP Employee
			setPaymentMethod(objZPUserRole);
			// Update Has Accountant
			setHasAccountant(objZPUserRole);
		}

		// Set Accounting Firm on Related User Roles
		setUserRoleAccountingFirmInfo();

		// Process all contact update and insert into one DML
		List<Contact> list_ContactsToUpsert = new List<Contact>();

		if (!map_ZPUserIdNewContact.isEmpty()) {
			list_ContactsToUpsert.addAll(map_ZPUserIdNewContact.values());
		}
		if (!map_ContactsToUpdate.isEmpty()) {
			list_ContactsToUpsert.addAll(map_ContactsToUpdate.values());
		}

		if (!list_ContactsToUpsert.isEmpty()) {
			Database.upsert(list_ContactsToUpsert, false);
		}

		for (Contact objContact : queryContacts(set_UserIds, set_ZPUserEmails)) {
			if (String.isNotBlank(objContact.ZP_User_Id__c)) {
				map_ZPUserIdToContact.put(objContact.ZP_User_Id__c, objContact);
			}
		}

		// Set Contact Lookup
		for (ZP_User_Role__c objZPUserRole : list_NewRoles) {
			if (
				objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG ||
				objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE ||
				objZPUserRole.Deleted_At__c != null ||
				objZPUserRole.Message__c == ZPUserRoleUtil.LEAD_CONVERT_PENDING
			) {
				continue;
			}
			objZPUserRole.Contact__c = null;
			if (String.isNotBlank(objZPUserRole.User_Id__c)) {
				if (map_ZPUserIdToContact.containsKey(objZPUserRole.User_Id__c)) {
					objZPUserRole.Contact__c = map_ZPUserIdToContact.get(objZPUserRole.User_Id__c).Id;
				} else {
					setProcessingStateAndMessage(objZPUserRole, IntegrationUtils.ERROR_STATE, ZPUserRoleUtil.CONTACT_ID_NOT_EXIST);
				}
			}
		}
		// Re-process related user roles
		reProcessUserRoles(list_UserRolesToUpdate);

		// Insert or delete Opportunity Contact Roles (run only after Contact__c lookup has been set on user role)
		setOpportunityContactRelationship(list_NewRoles);

		// Re-process ZP Users
		if (!map_UsersToReProcess.isEmpty()) {
			update map_UsersToReProcess.values();
		}

		// Update Accounts
		if (!map_AccountsToUpdate.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			update map_AccountsToUpdate.values();
			AccountTriggerHelper.skipTrigger = false;
		}

		// Update Leads
		if (!map_LeadsToUpdate.isEmpty()) {
			update map_LeadsToUpdate.values();
		}

		// Update User Roles
		if (!map_UserRolesToUpdate.isEmpty()) {
			update map_UserRolesToUpdate.values();
		}

		// Create new contact roles
		if (!list_OppConRolesToInsert.isEmpty()) {
			OpportunityTriggerHelper.skipTrigger = true;
			insert list_OppConRolesToInsert;
		}

		// Delete existing conatct roles
		if (!map_OppConRoleToDelete.isEmpty()) {
			OpportunityTriggerHelper.skipTrigger = true;
			delete map_OppConRoleToDelete.values();
		}

		// Update Processing State to Processed if there are no errors in DML
		for (ZP_User_Role__c objRole : list_NewRoles) {
			if (map_ContactDMLErrors.containsKey(objRole.User_Id__c)) {
				setProcessingStateAndMessage(objRole, IntegrationUtils.ERROR_STATE, map_ContactDMLErrors.get(objRole.User_Id__c));
			} else if (objRole.Processing_State__c == IntegrationUtils.QUEUED_STATE || objRole.Processing_State__c == IntegrationUtils.MANUAL_ENQUEUE) {
				setProcessingStateAndMessage(objRole, IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE);
			}

			// Finally reset fields if user role is deleted
			resetFieldsIfDeleted(objRole);
		}
	}

	/**
	 * @description Set ZP User Lookup field based on User Id
	 * @author      Praveen Sethu
	 * @param       objRole - User role from Trigger context
	 * @return      NA
	 **/
	public void setZPUser(ZP_User_Role__c objZPUserRole) {
		if (String.isNotBlank(objZPUserRole.User_Id__c) && map_ZPUserIdToZPUser.containsKey(objZPUserRole.User_Id__c)) {
			ZP_User__c objZPUser = map_ZPUserIdToZPUser.get(objZPUserRole.User_Id__c);
			objZPUserRole.ZP_User__c = objZPUser.Id;

			// If user exists but no email, backlog record and set error message
			if (String.isBlank(objZPUser.Email__c)) {
				setProcessingStateAndMessage(objZPUserRole, IntegrationUtils.BACKLOG, ZPUserRoleUtil.USER_DOES_NOT_HAVE_EMAIL);
			}
		}
		// If lookup field is still null, backlog record and set error message
		if (String.isNotBlank(objZPUserRole.User_Id__c) && objZPUserRole.ZP_User__c == null) {
			setProcessingStateAndMessage(objZPUserRole, IntegrationUtils.BACKLOG, ZPUserRoleUtil.USER_ID_DOES_NOT_EXIST_IN_ZP_USER);
		}
	}

	/**
	 * @description Set Company Account Lookup field based on Company Id
	 * @author      Praveen Sethu
	 * @param       objZPUserRole - User role from Trigger context
	 * @return      NA
	 **/
	public void setZPCompany(ZP_User_Role__c objZPUserRole) {
		// Do not process dead or backlog records
		if (objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
			return;
		}
		objZPUserRole.Company_Account__c = null;
		if (String.isNotBlank(objZPUserRole.Company_Id__c) && map_ZPCompanyIdToAccount.containsKey(objZPUserRole.Company_Id__c)) {
			Account objCompAccount = map_ZPCompanyIdToAccount.get(objZPUserRole.Company_Id__c);
			objZPUserRole.Company_Account__c = objCompAccount.Id;
		}
		// If lookup field is still null, backlog record and set error message
		if (String.isNotBlank(objZPUserRole.Company_Id__c) && objZPUserRole.Company_Account__c == null) {
			setProcessingStateAndMessage(objZPUserRole, IntegrationUtils.BACKLOG, ZPUserRoleUtil.COMPANY_ID_DOES_NOT_EXIST);
		}
	}

	/**
	 * @description Set Accounting Firm Lookup field based on Accounting Firm Id
	 * @author      Praveen Sethu
	 * @param       objZPUserRole - User role from Trigger context
	 * @return      NA
	 **/
	public void setAccountingFirm(ZP_User_Role__c objZPUserRole) {
		// Do not process dead or backlog records
		if (objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
			return;
		}
		objZPUserRole.Accounting_Firm_Account__c = null;
		objZPUserRole.Is_Accountant__c = false;
		if (String.isNotBlank(objZPUserRole.Accounting_Firm_Id__c)) {
			objZPUserRole.Is_Accountant__c = true;
			if (map_ZPAccFirmToAccount.containsKey(objZPUserRole.Accounting_Firm_Id__c)) {
				Account objResellerAcct = map_ZPAccFirmToAccount.get(objZPUserRole.Accounting_Firm_Id__c);
				objZPUserRole.Accounting_Firm_Account__c = objResellerAcct.Id;
			}
			// If lookup field is still null, backlog record and set error message
			if (objZPUserRole.Accounting_Firm_Account__c == null) {
				setProcessingStateAndMessage(objZPUserRole, IntegrationUtils.BACKLOG, ZPUserRoleUtil.ACC_FIRM_DOES_NOT_EXIST);
			}
		}
	}

	public void reProcessUserRoles(List<ZP_User_Role__c> list_Roles) {
		for (ZP_User_Role__c objRole : list_Roles) {
			Boolean blnUpdate = false;
			if (objRole.Processing_State__c == IntegrationUtils.DEAD_STATE || objRole.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			// Set Contact Lookup if not already set
			if (String.isNotBlank(objRole.User_Id__c) && map_ZPUserIdToContact.containsKey(objRole.User_Id__c)) {
				Contact objCon = map_ZPUserIdToContact.get(objRole.User_Id__c);
				if (objRole.Contact__c != objCon.Id) {
					objRole.Contact__c = objCon.Id;
					blnUpdate = true;
				}
			}
			// Set Company Account Lookup if not already set
			if (String.isNotBlank(objRole.Company_Id__c) && objRole.Company_Account__c == null && map_ZPCompanyIdToAccount.containsKey(objRole.Company_Id__c)) {
				Account objAcc = map_ZPCompanyIdToAccount.get(objRole.Company_Id__c);

				if (objRole.Company_Account__c != objAcc.Id) {
					objRole.Company_Account__c = objAcc.Id;
					blnUpdate = true;
				}
			}

			// Set Accounting Firm Account Lookup if not already set
			if (String.isNotBlank(objRole.Accounting_Firm_Id__c) && objRole.Accounting_Firm_Account__c == null && map_ZPAccFirmToAccount.containsKey(objRole.Accounting_Firm_Id__c)) {
				Account objAcc = map_ZPAccFirmToAccount.get(objRole.Accounting_Firm_Id__c);

				if (objRole.Accounting_Firm_Account__c != objAcc.Id) {
					objRole.Accounting_Firm_Account__c = objAcc.Id;
					objRole.Is_Accountant__c = true;
					blnUpdate = true;
				}
			}

			if (objRole.Accounting_Firm_Account__c == null && String.isNotBlank(objRole.User_Id__c) && map_ZPUserIdToAccountantRole.containsKey(objRole.User_Id__c)) {
				ZP_User_Role__c objAccRole = map_ZPUserIdToAccountantRole.get(objRole.User_Id__c);
				if (objAccRole.Accounting_Firm_Account__c != null) {
					objRole.Accounting_Firm_Account__c = objAccRole.Accounting_Firm_Account__c;
					objRole.Is_Accountant__c = true;
					map_UserRolesToUpdate.put(objRole.Id, objRole);
				}
			}

			if (blnUpdate) {
				map_UserRolesToUpdate.put(objRole.Id, objRole);
			}
		}
	}

	/**
	 * @description Set Accounting Firm on Related User Roles
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public void setUserRoleAccountingFirmInfo() {
		if (!map_ZPUserIdToAccountantRole.isEmpty()) {
			for (ZP_User_Role__c objAccRole : map_ZPUserIdToAccountantRole.values()) {
				if (
					!set_UserRoleIds.contains(objAccRole.Id) &&
					String.isNotBlank(objAccRole.Accounting_Firm_Id__c) &&
					objAccRole.Accounting_Firm_Account__c == null &&
					map_ZPAccFirmToAccount.containsKey(objAccRole.Accounting_Firm_Id__c)
				) {
					objAccRole.Accounting_Firm_Account__c = map_ZPAccFirmToAccount.get(objAccRole.Accounting_Firm_Id__c).Id;
					objAccRole.Is_Accountant__c = true;
					map_UserRolesToUpdate.put(objAccRole.Id, objAccRole);
				}

				if (map_ZPUserIdToPayrollAdminRole.containsKey(objAccRole.User_Id__c)) {
					ZP_User_Role__c objPayrollAdminRole = map_ZPUserIdToPayrollAdminRole.get(objAccRole.User_Id__c);

					if (
						!set_UserRoleIds.contains(objPayrollAdminRole.Id) &&
						String.isNotBlank(objPayrollAdminRole.Accounting_Firm_Id__c) &&
						objPayrollAdminRole.Accounting_Firm_Account__c == null &&
						map_ZPAccFirmToAccount.containsKey(objPayrollAdminRole.Accounting_Firm_Id__c)
					) {
						objPayrollAdminRole.Accounting_Firm_Account__c = map_ZPAccFirmToAccount.get(objPayrollAdminRole.Accounting_Firm_Id__c).Id;
						objPayrollAdminRole.Is_Accountant__c = true;
						map_UserRolesToUpdate.put(objPayrollAdminRole.Id, objPayrollAdminRole);
					}
				}

				if (map_ZPUserIdToSignatoryRole.containsKey(objAccRole.User_Id__c)) {
					ZP_User_Role__c objSignatoryRole = map_ZPUserIdToSignatoryRole.get(objAccRole.User_Id__c);

					if (
						!set_UserRoleIds.contains(objSignatoryRole.Id) &&
						String.isNotBlank(objSignatoryRole.Accounting_Firm_Id__c) &&
						objSignatoryRole.Accounting_Firm_Account__c == null &&
						map_ZPAccFirmToAccount.containsKey(objSignatoryRole.Accounting_Firm_Id__c)
					) {
						objSignatoryRole.Accounting_Firm_Account__c = map_ZPAccFirmToAccount.get(objSignatoryRole.Accounting_Firm_Id__c).Id;
						objSignatoryRole.Is_Accountant__c = true;
						map_UserRolesToUpdate.put(objSignatoryRole.Id, objSignatoryRole);
					}
				}
			}
		}
	}

	/**
	 * @description Insert or delete opportunity contact roles
	 * @author      Praveen Sethu
	 * @param       objZPUserRole - User role from Trigger context
	 * @return      NA
	 **/
	public void setOpportunityContactRelationship(List<ZP_User_Role__c> list_NewRoles) {
		Set<String> set_AllowedRoles = getRolesSet('ZPUserRoleTriggerHelper');
		Set<Id> set_AccountIds = new Set<Id>();
		Set<Id> set_OppRecordTypeIds = new Set<Id>();

		// Data setup. Create a map of account and available contact roles
		for (ZP_User_Role__c objUserRole : list_NewRoles) {
			// Do not process dead or backlog records
			if (objUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (!set_AllowedRoles.contains(objUserRole.Role_Name__c)) {
				continue;
			}

			if (String.isNotBlank(objUserRole.Role_Name__c)) {
				set_UserRoleNames.add(objUserRole.Role_Name__c);
			}
			String strContactRoleNameKey = objUserRole.Contact__c + '-' + objUserRole.Role_Name__c;
			// Opportunity Contact Roles to be Inserted
			if (objUserRole.Company_Account__c != null && objUserRole.Deleted_At__c == null) {
				if (!map_AccountIdToContactRoleSet.containsKey(objUserRole.Company_Account__c)) {
					map_AccountIdToContactRoleSet.put(objUserRole.Company_Account__c, new Set<String>{ strContactRoleNameKey });
				} else {
					map_AccountIdToContactRoleSet.get(objUserRole.Company_Account__c).add(strContactRoleNameKey);
				}
				set_AccountIds.add(objUserRole.Company_Account__c);
			}

			// Opportunity Contact Roles to be Deleted
			if (objUserRole.Company_Account__c != null && objUserRole.Deleted_At__c != null) {
				if (!map_AccountIdToDeleteContactRoleSet.containsKey(objUserRole.Company_Account__c)) {
					map_AccountIdToDeleteContactRoleSet.put(objUserRole.Company_Account__c, new Set<String>{ strContactRoleNameKey });
				} else {
					map_AccountIdToDeleteContactRoleSet.get(objUserRole.Company_Account__c).add(strContactRoleNameKey);
				}
				set_AccountIds.add(objUserRole.Company_Account__c);
			}
		}

		// Create set of opportunity record types
		if (
			set_UserRoleNames.contains(PRIMARY_PAYROLL_ADMIN) ||
			set_UserRoleNames.contains(PAYROLL_ADMIN) ||
			set_UserRoleNames.contains(ACCOUNTANT) ||
			set_UserRoleNames.contains(SIGNATORY) ||
			set_UserRoleNames.contains(BENEFIT_SIGNATORY) ||
			set_UserRoleNames.contains(BENEFITS_ADMIN)
		) {
			set_OppRecordTypeIds.add(ZPUserRoleUtil.COMPANY_OPPTY_RT_ID);
			set_OppRecordTypeIds.add(ZPUserRoleUtil.CUSTOMER_SUCCESS_RT_ID);
			set_OppRecordTypeIds.add(ZPUserRoleUtil.BENEFITS_BOR_OPPTY_RT_ID);
			set_OppRecordTypeIds.add(ZPUserRoleUtil.BENEFITS_CHANGE_OPPTY_RT_ID);
			set_OppRecordTypeIds.add(ZPUserRoleUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID);
			set_OppRecordTypeIds.add(ZPUserRoleUtil.BENEFITS_RENEWAL_OPPTY_RT_ID);
			set_OppRecordTypeIds.add(ZPUserRoleUtil.BENEFITS_BYOB_OPPTY_RT_ID);
			set_OppRecordTypeIds.add(ZPUserRoleUtil.ACQUISITION_OPPTY_RT_ID);
		}


		for (Opportunity objOpportunity : queryOpportunities(set_AccountIds, set_OppRecordTypeIds, set_AllowedRoles)) {
			for (OpportunityContactRole objOppConRole : objOpportunity.OpportunityContactRoles) {
				if (String.isNotBlank(objOppConRole.Role)) {
					map_ConIdRoleToOppConRole.put(objOppConRole.ContactId + '-' + objOppConRole.Role, objOppConRole);
				} else {
					map_ConIdRoleToOppConRole.put(objOppConRole.ContactId, objOppConRole);
				}
			}

			if (map_AccountIdToContactRoleSet.containsKey(objOpportunity.AccountId)) {
				for (String strConRoleKey : map_AccountIdToContactRoleSet.get(objOpportunity.AccountId)) {
					List<String> list_ContactIdRoles = strConRoleKey.split('-');
					String strContactId = '';
					String strConRole = '';

					if (list_ContactIdRoles.size() > 1) {
						strContactId = list_ContactIdRoles[0];
						strConRole = list_ContactIdRoles[1];
					}
					if (map_ConIdRoleToOppConRole.containsKey(strConRoleKey)) {
						continue;
					} else if (map_ConIdRoleToOppConRole.containsKey(strContactId + '-')) {
					} else {
						if (String.isNotBlank(strContactId) && strContactId != 'null') {
							list_OppConRolesToInsert.add(new OpportunityContactRole(OpportunityId = objOpportunity.Id, ContactId = strContactId, Role = strConRole));
						}
					}
				}
			}

			//to delete records
			if (map_AccountIdToDeleteContactRoleSet.containsKey(objOpportunity.AccountId)) {
				for (String strConRoleKey : map_AccountIdToDeleteContactRoleSet.get(objOpportunity.AccountId)) {
					if (map_ConIdRoleToOppConRole.containsKey(strConRoleKey)) {
						map_OppConRoleToDelete.put(map_ConIdRoleToOppConRole.get(strConRoleKey).Id, map_ConIdRoleToOppConRole.get(strConRoleKey));
					}
				}
			}
		}
	}

	/**
	 * @description Updates Payment Method from ZP Employee
	 * @author      Praveen Sethu
	 * @param       objZPUserRole - User role from Trigger context
	 * @return      NA
	 **/
	public void setPaymentMethod(ZP_User_Role__c objZPUserRole) {
		// Do not process dead or backlog records
		if (objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
			return;
		}
		if (map_EmployeeIds.containsKey(objZPUserRole.Employee_Id__c)) {
			objZPUserRole.Payment_Method_Type__c = map_EmployeeIds.get(objZPUserRole.Employee_Id__c).Payment_Method_Type__c;
		}
	}

	/**
	 * @description Updates Has Accountant on Company Account
	 * @author      Praveen Sethu
	 * @param       objZPUserRole - User role from Trigger context
	 * @return      NA
	 **/
	public void setHasAccountant(ZP_User_Role__c objZPUserRole) {
		// Do not process dead or backlog records
		if (objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
			return;
		}
		String strHasAccountant = '';
		// Set Is Accountant = true if any accountant role is associated with user role
		if (objZPUserRole.Accounting_Firm_Account__c == null && String.isNotBlank(objZPUserRole.User_Id__c) && map_ZPUserIdToAccountantRole.containsKey(objZPUserRole.User_Id__c)) {
			ZP_User_Role__c objAccRole = map_ZPUserIdToAccountantRole.get(objZPUserRole.User_Id__c);

			if (objAccRole.Accounting_Firm_Account__c != null) {
				objZPUserRole.Accounting_Firm_Account__c = objAccRole.Accounting_Firm_Account__c;
			}
			objZPUserRole.Is_Accountant__c = true;
		}

		// Logic to update Has Accountant on Account
		if (map_CompanyIdToZPUserRoles.containsKey(objZPUserRole.Company_Id__c)) {
			for (ZP_User_Role__c objUserRoleIterator : map_CompanyIdToZPUserRoles.get(objZPUserRole.Company_Id__c)) {
				// Take data from trigger.new instead of query for current record
				ZP_User_Role__c objUserRole = objZPUserRole.Id == objUserRoleIterator.Id ? objZPUserRole : objUserRoleIterator;

				ZP_User__c objZPUser = map_ZPUserIdToZPUser.containsKey(objUserRole.User_Id__c) ? map_ZPUserIdToZPUser.get(objUserRole.User_Id__c) : null;

				// Set Has Accountant based on Collaborator Type
				if (
					objUserRole.Is_Accountant__c &&
					objUserRole.Deleted_At__c == null &&
					objZPUser != null &&
					objZPUser.Deleted_At__c == null &&
					map_ZPCompanyIdToAccount.containsKey(objUserRole.Company_Id__c) &&
					String.isNotBlank(objUserRole.Collaborator_Type__c)
				) {
					if (objUserRole.Collaborator_Type__c.containsIgnoreCase(ZPUserRoleUtil.HAS_ACCOUNTANT_EXTERNAL)) {
						strHasAccountant = String.isBlank(strHasAccountant)
							? ZPUserRoleUtil.HAS_ACCOUNTANT_EXTERNAL
							: (strHasAccountant.containsIgnoreCase(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL) ? ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL_EXTERNAL : strHasAccountant);
					} else if (objUserRole.Collaborator_Type__c.containsIgnoreCase(ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL)) {
						strHasAccountant = String.isBlank(strHasAccountant)
							? ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL
							: (strHasAccountant.containsIgnoreCase(ZPUserRoleUtil.HAS_ACCOUNTANT_EXTERNAL) ? ZPUserRoleUtil.HAS_ACCOUNTANT_INTERNAL_EXTERNAL : strHasAccountant);
					}
				}
			}
		}

		// Update Has Accountant on Account
		if (map_ZPCompanyIdToAccount.containsKey(objZPUserRole.Company_Id__c)) {
			Account objCompAccount = map_ZPCompanyIdToAccount.get(objZPUserRole.Company_Id__c);
			Account objAccountToUpdate = map_AccountsToUpdate.containsKey(objCompAccount.Id) ? map_AccountsToUpdate.get(objCompAccount.Id) : objCompAccount;

			if (objAccountToUpdate != null && objAccountToUpdate.Has_Accountant__c != strHasAccountant) {
				objAccountToUpdate.Has_Accountant__c = strHasAccountant;
				map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
			}
		}
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Update ABC Lead Match and Referred By on unconverted leads
	 * @param       : objZPUserRole - New ZPUserRole
	 * @return      : N/A
	 **/
	public void setLeadInformation(ZP_User_Role__c objZPUserRole) {
		// Do not process dead or backlog records
		if (objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
			return;
		}
		if (
			objZPUserRole.Role_Name__c != ZPUserRoleUtil.ACCOUNTANT &&
			(objZPUserRole.Collaborator_Type__c == ZPUserRoleUtil.EXTERNAL_ACCOUNTANT ||
			objZPUserRole.Collaborator_Type__c == ZPUserRoleUtil.EXTERNAL_BOOKKEEPER) &&
			objZPUserRole.Created_At__c > (System.today() - 90)
		) {
			ZP_User__c objZPUser = map_ZPUserIdToZPUser.containsKey(objZPUserRole.User_Id__c) ? map_ZPUserIdToZPUser.get(objZPUserRole.User_Id__c) : null;

			if (objZPUser != null && String.isNotBlank(objZPUser.Email__c)) {
				if (map_EmailToContact.containsKey(objZPUser.Email__c)) {
					return;
				}

				String strEmailDomain = objZPUser.Email__c.split('@')[1];

				if (map_EmailToLead.containsKey(objZPUser.Email__c)) {
					Lead objLead = map_EmailToLead.get(objZPUser.Email__c);
					if (objLead.RecordTypeId == ZPUserRoleUtil.LEAD_RESELLER_RT_ID) {
						objLead = map_LeadsToUpdate.containsKey(objLead.Id) ? map_LeadsToUpdate.get(objLead.Id) : objLead;

						Boolean blnLeadUpdate = false;

						if (objLead.IsConverted) {
							return;
						} else if (objLead.ABC_Lead_Match__c) {
							if (objLead.ZP_User_Id__c != objZPUserRole.User_Id__c) {
								objLead.ZP_User_Id__c = objZPUserRole.User_Id__c;
								blnLeadUpdate = true;
							}
						} else {
							if (objLead.ZP_User_Id__c != objZPUserRole.User_Id__c) {
								objLead.ZP_User_Id__c = objZPUserRole.User_Id__c;
								blnLeadUpdate = true;
							}

							if (map_EmailDomainToAccounts.containsKey(strEmailDomain)) {
								Account objAccount = map_EmailDomainToAccounts.get(strEmailDomain);

								if (!objLead.ABC_Lead_Match__c) {
									objLead.ABC_Lead_Match__c = true;
									blnLeadUpdate = true;
								}
								if (objLead.ABC_Match_Account__c != objAccount.Id) {
									objLead.ABC_Match_Account__c = objAccount.Id;
									blnLeadUpdate = true;
								}
							}
						}

						if (objLead.Referred_By__c == null && String.isNotBlank(objZPUserRole.Company_Id__c) && map_ZPCompanyIdToAccount.containsKey(objZPUserRole.Company_Id__c)) {
							objLead.Referred_By__c = map_ZPCompanyIdToAccount.get(objZPUserRole.Company_Id__c).Id;
							blnLeadUpdate = true;
						}

						if (blnLeadUpdate) {
							map_LeadsToUpdate.put(objLead.Id, objLead);
						}
					}
				}
			}
		}
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Upserts Reseller and Company Contacts
	 * @param       : objZPUserRole - New ZPUserRole
	 * @return      : N/A
	 **/
	public void processContactInformation(ZP_User_Role__c objZPUserRole) {
		// Do not process dead or backlog records
		if (objZPUserRole.Processing_State__c == IntegrationUtils.BACKLOG || objZPUserRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
			return;
		}
		if (
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.ACCOUNTANT ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.PAYROLL_ADMIN ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.SIGNATORY ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.EMPLOYEE ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.CONTRACTOR ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.INTERNATIONAL_CONTRACTOR ||
			objZPUserRole.Employment_Type__c == ZPUserRoleUtil.INTERNATIONALCONTRACTOR ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.COMPANY_MEMBER ||
			objZPUserRole.Employment_Type__c == ZPUserRoleUtil.INTERNATIONALEMPLOYEE ||
			objZPUserRole.Role_Name__c == ZPUserRoleUtil.INTERNATIONAL_EMPLOYEE ||
			objZPUserRole.Type__c == 'Role::CompanyMember'
		) {
			ZP_User__c objZPUser = map_ZPUserIdToZPUser.containsKey(objZPUserRole.User_Id__c) ? map_ZPUserIdToZPUser.get(objZPUserRole.User_Id__c) : new ZP_User__c();

			Contact objContact = new Contact();
			// Get contact based on user id or email or unique email address
			if (map_ZPUserIdToContact.containsKey(objZPUserRole.User_Id__c)) {
				objContact = map_ZPUserIdToContact.get(objZPUserRole.User_Id__c);
			} else if (objZPUser != null && (map_EmailToContact.containsKey(objZPUser.Email__c) || map_UniqueEmailToContact.containsKey(objZPUser.Email__c))) {
				objContact = map_EmailToContact.containsKey(objZPUser.Email__c) ? map_EmailToContact.get(objZPUser.Email__c) : map_UniqueEmailToContact.get(objZPUser.Email__c);
			}

			// convert if any unconverted leads found based on matching email address from zp user
			// Also check if there are no existing contacts based on user id and email address
			if (objZPUser != null && String.isNotBlank(objZPUser.Email__c) && map_EmailToLead.containsKey(objZPUser.Email__c) && objContact.Id == null) {
				Lead objLead = map_EmailToLead.get(objZPUser.Email__c);
				Account objAccount;
				// Get accounting firm id or company id
				if (String.isNotBlank(objZPUserRole.Company_Id__c) && map_ZPCompanyIdToAccount.containsKey(objZPUserRole.Company_Id__c)) {
					objAccount = map_ZPCompanyIdToAccount.get(objZPUserRole.Company_Id__c);
				} else if (String.isNotBlank(objZPUserRole.Accounting_Firm_Id__c) && map_ZPAccFirmToAccount.containsKey(objZPUserRole.Accounting_Firm_Id__c)) {
					objAccount = map_ZPAccFirmToAccount.get(objZPUserRole.Accounting_Firm_Id__c);
				}
				// check if account and lead exists. lead must be unconverted and lead/account record type must match
				if (
					objAccount != null &&
					objAccount.Id != null &&
					objLead.Id != null &&
					!objLead.IsConverted &&
					objLead.RecordType.Name == objAccount.RecordType.Name &&
					objLead.LeadSource != ZPUserRoleUtil.LEAD_SOURCE_ABC
				) {
					setProcessingStateAndMessage(objZPUserRole, IntegrationUtils.ERROR_STATE, ZPUserRoleUtil.LEAD_CONVERT_PENDING);
					// send leads to convert and skip further transaction
					return;
				}
			}

			// If user is not deleted and contact is inactive, re-activate contact
			if (objZPUser != null && objZPUser.Deleted_At__c == null && objContact.Inactive_Zp_User__c == true) {
				objContact.Inactive_Zp_User__c = false;
				objContact.ZP_User_Id__c = objZPUser.Id__c;
				objContact.Email = objZPUser.Email__c;
				objContact.Unique_Email_Address_Contact__c = objZPUser.Email__c;
			}

			if (objContact.Id != null) {
				objContact = map_ContactsToUpdate.containsKey(objContact.Id) ? map_ContactsToUpdate.get(objContact.Id) : objContact;
			}

			// Re-process user if user role contact does not match with user contact
			if (objZPUserRole.Deleted_At__c != null || (objContact.Id != null && objZPUser.Contact__c != objContact.Id)) {
				set_ZPUserIdsToReProcess.add(objZPUserRole.User_Id__c);
				if (objZPUser != null) {
					map_UsersToReProcess.put(objZPUser.Id, objZPUser);
				}
			}
			// Set processing state to Backlog if accounting firm and company id are missing and no contacts are associated
			if (objContact?.Id == null && objZPUserRole.Accounting_Firm_Id__c == null && objZPUserRole.Company_Id__c == null) {
				setProcessingStateAndMessage(objZPUserRole, IntegrationUtils.BACKLOG, ZPUserRoleUtil.ACC_FIRM_COMPANY_ID_MISSING);
			}

			setContactInformation(objContact, objZPUserRole, objZPUser);

			// Re-process zp user for newly created contacts
			if (objContact.Id == null) {
				if (String.isNotBlank(objZPUserRole.User_Id__c)) {
					map_ZPUserIdNewContact.put(objZPUserRole.User_Id__c, objContact);
					set_ZPUserIdsToReProcess.add(objZPUserRole.User_Id__c);
				}
			} else {
				if (!map_ContactsToUpdate.containsKey(objContact.Id)) {
					map_ContactsToUpdate.put(objContact.Id, objContact);
				}
			}
		}
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Updates different fields on Contact.
	 * @param       : objZPUserRole - New ZPUserRole
	 * @param       : objContact - Contact to be upserted
	 * @param       : objZPUser - ZP User from User Role
	 * @return      : N/A
	 **/
	public void setContactInformation(Contact objContact, ZP_User_Role__c objZPUserRole, ZP_User__c objZPUser) {
		ZP_User_Role__c objAccountantRole = map_ZPUserIdToAccountantRole.containsKey(objZPUserRole.User_Id__c) ? map_ZPUserIdToAccountantRole.get(objZPUserRole.User_Id__c) : new ZP_User_Role__c();
		Account objAccount;
		ZP_User_Role__c objLatestQueryRole;
		ZP_User_Role__c objNameRoleInfo;
		ZP_User_Role__c objEmployeeRole = map_ZPUserIdToEmployeeRole.containsKey(objZPUserRole.User_Id__c) ? map_ZPUserIdToEmployeeRole.get(objZPUserRole.User_Id__c) : new ZP_User_Role__c();
		ZP_User_Role__c objPayrollAdminRole = map_ZPUserIdToPayrollAdminRole.containsKey(objZPUserRole.User_Id__c)
			? map_ZPUserIdToPayrollAdminRole.get(objZPUserRole.User_Id__c)
			: new ZP_User_Role__c();

		Boolean blnAccountSet = false;

		if (objZPUserRole.Deleted_At__c != null && objContact.Id == null) {
			return;
		}

		// Initialze Account instance based on different priority
		if (String.isNotBlank(objAccountantRole.Accounting_Firm_Id__c) && map_ZPAccFirmToAccount.containsKey(objAccountantRole.Accounting_Firm_Id__c)) {
			objAccount = map_ZPAccFirmToAccount.get(objAccountantRole.Accounting_Firm_Id__c);
		} else if (String.isNotBlank(objEmployeeRole.Accounting_Firm_Id__c) && map_ZPAccFirmToAccount.containsKey(objEmployeeRole.Accounting_Firm_Id__c)) {
			objAccount = map_ZPAccFirmToAccount.get(objEmployeeRole.Company_Id__c);
		} else if (String.isNotBlank(objPayrollAdminRole.Company_Id__c) && map_ZPCompanyIdToAccount.containsKey(objPayrollAdminRole.Company_Id__c)) {
			objAccount = map_ZPCompanyIdToAccount.get(objPayrollAdminRole.Company_Id__c);
		} else if (String.isNotBlank(objEmployeeRole.Company_Id__c) && map_ZPCompanyIdToAccount.containsKey(objEmployeeRole.Company_Id__c)) {
			objAccount = map_ZPCompanyIdToAccount.get(objEmployeeRole.Company_Id__c);
		} else if (String.isNotBlank(objZPUserRole.Company_Id__c) && map_ZPCompanyIdToAccount.containsKey(objZPUserRole.Company_Id__c)) {
			objAccount = map_ZPCompanyIdToAccount.get(objZPUserRole.Company_Id__c);
		} else if (String.isNotBlank(objZPUserRole.Accounting_Firm_Id__c) && map_ZPAccFirmToAccount.containsKey(objZPUserRole.Accounting_Firm_Id__c)) {
			objAccount = map_ZPAccFirmToAccount.get(objZPUserRole.Accounting_Firm_Id__c);
		}

		if (objAccount != null) {
			// Set owner of contact as same owner of account - ONLY on insert
			if (objContact.Id == null) {
				objContact.OwnerId = objAccount.OwnerId;
			}

			// Set account id on contact
			objContact.AccountId = objAccount.Id;
			blnAccountSet = true;

			// Match account and contact record type
			if (objAccount.RecordTypeId == ZPUserRoleUtil.ACCOUNT_RESELLER_RT_ID) {
				objContact.RecordTypeId = ZPUserRoleUtil.CONTACT_RESELLER_RT_ID;
			} else if (objAccount.RecordTypeId == ZPUserRoleUtil.ACCOUNT_COMPANY_RT_ID) {
				objContact.RecordTypeId = ZPUserRoleUtil.CONTACT_COMPANY_RT_ID;
			}
		}

		// Set employee id
		if (String.isNotBlank(objZPUserRole.Employee_Id__c) && objZPUserRole.Role_Name__c == EMPLOYEE) {
			objContact.Employee_Id__c = objZPUserRole.Employee_Id__c;
		}

		// Set contractor id
		if (String.isNotBlank(objZPUserRole.Contractor_Id__c) && objZPUserRole.Role_Name__c == CONTRACTOR) {
			objContact.Contractor_Id__c = objZPUserRole.Contractor_Id__c;
		}

		if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.CONTRACTOR || objZPUserRole.Role_Name__c == ZPUserRoleUtil.SIGNATORY || objZPUserRole.Role_Name__c == ZPUserRoleUtil.EMPLOYEE) {
			if (map_ZPUserIdToPayrollAdminRole.containsKey(objZPUserRole.User_Id__c)) {
				objNameRoleInfo = map_ZPUserIdToPayrollAdminRole.get(objZPUserRole.User_Id__c);
			} else if (map_ZPUserIdToAccountantRole.containsKey(objZPUserRole.User_Id__c)) {
				objNameRoleInfo = map_ZPUserIdToAccountantRole.get(objZPUserRole.User_Id__c);
			} else if (map_ZPUserIdToEmployeeRole.containsKey(objZPUserRole.User_Id__c)) {
				objNameRoleInfo = map_ZPUserIdToEmployeeRole.get(objZPUserRole.User_Id__c);
			}

			if (objNameRoleInfo == null) {
				if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.CONTRACTOR && map_ZPUserIdToContractorRole.containsKey(objZPUserRole.User_Id__c)) {
					objNameRoleInfo = map_ZPUserIdToContractorRole.get(objZPUserRole.User_Id__c);
				} else if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.SIGNATORY && map_ZPUserIdToSignatoryRole.containsKey(objZPUserRole.User_Id__c)) {
					objNameRoleInfo = map_ZPUserIdToSignatoryRole.get(objZPUserRole.User_Id__c);
				}
			}
		}

		if (objZPUserRole.Role_Name__c == ZPUserRoleUtil.CONTRACTOR || objZPUserRole.Role_Name__c == ZPUserRoleUtil.EMPLOYEE) {
			objContact.Is_UX_Active__c = objZPUserRole.Is_UX_Active__c ? true : false;
		}
		objContact.Accountant_Client_Invitation_Link__c = objZPUserRole.Accountant_Client_Invitation_Link__c;

		setContactBasicInfo(objZPUserRole, objNameRoleInfo, objContact);

		objContact.Email = objZPUser.Email__c;
		objContact.Disable_Email__c = objZPUser.Disable_Emails__c;
		objContact.Unique_Email_Address_Contact__c = objZPUser.Email__c;
		objContact.ZP_User_Id__c = objZPUser.Id__c;
		objContact.Referral_Token__c = objZPUser.Referral_Token__c;

		// Override only if contact does not have any value
		if (objContact.Cashout_Eligible_at__c == null) {
			objContact.Cashout_Eligible_at__c = objZPUserRole.Cashout_Eligible_at__c;
		}

		if (objContact.Cashout_Invited_at__c == null) {
			objContact.Cashout_Invited_At__c = objZPUserRole.Cashout_Invited_At__c;
		}

		if (objContact.Cashout_Enrolled_At__c == null) {
			objContact.Cashout_Enrolled_At__c = objZPUserRole.Cashout_Enrolled_At__c;
		}

		if (objContact.Cashout_Disqualified_At__c == null) {
			objContact.Cashout_Disqualified_At__c = objZPUserRole.Cashout_Disqualified_At__c;
		}

		if (String.isBlank(objContact.Cashout_Disqualification_Reasons__c)) {
			objContact.Cashout_Disqualification_Reasons__c = objZPUserRole.Cashout_Disqualification_Reasons__c;
		}

		if (objZPUserRole.Latest_Cashout_Date__c != null) {
			objContact.Latest_Cashout_Date__c = objZPUserRole.Latest_Cashout_Date__c;
		}

		if (objZPUserRole.Is_Millennial__c && objZPUserRole.Role_Name__c == ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN) {
			objContact.Is_Jessica__c = true;
		} else if (objZPUserRole.Role_Name__c == PAYROLL_ADMIN) {
			objContact.Is_Jessica__c = false;
		}

		objContact.Legal_Name__c = String.isNotBlank(objZPUserRole.First_Name__c) ? objZPUserRole.First_Name__c : objContact.Legal_Name__c;

		if (objContact.Id == null && String.isNotBlank(objZPUserRole.Preferred_Name__c)) {
			objContact.FirstName = objZPUserRole.Preferred_Name__c;
		} else if (objContact.ZP_User_Roles__r != null && !objContact.ZP_User_Roles__r.isEmpty()) {
			// Keeping First Name on Contact as Preferred name of most recently created non-signatory Role
			objLatestQueryRole = objContact.ZP_User_Roles__r[0];
			objContact.FirstName = (objZPUserRole.Role_Name__c != SIGNATORY &&
				objZPUserRole.CreatedDate > objLatestQueryRole.CreatedDate &&
				String.isNotBlank(objZPUserRole.Preferred_Name__c))
				? objZPUserRole.Preferred_Name__c
				: objLatestQueryRole.Preferred_Name__c;
		}

		if (String.isNotBlank(objContact.FirstName) && objContact.FirstName.length() > 40 && String.isNotBlank(objZPUserRole.First_Name__c)) {
			objContact.FirstName = objZPUserRole.First_Name__c.length() > 40 ? objZPUserRole.First_Name__c.substring(0, 40) : objZPUserRole.First_Name__c;
		}

		if (String.isBlank(objContact.LastName)) {
			objContact.LastName = ZPUserRoleUtil.DEFAULT_LAST_NAME;
		}

		objContact.Is_Billing_Admin__c = false;
		objContact.Freelance_Accountant__c = false;

		if (map_UserIdToRoles.containsKey(objZPUserRole.User_Id__c)) {
			for (ZP_User_Role__c objIteratorRole : map_UserIdToRoles.get(objZPUserRole.User_Id__c)) {
				ZP_User_Role__c objRole = objIteratorRole.Id == objZPUserRole.Id ? objZPUserRole : objIteratorRole;

				if (objRole.Deleted_At__c == null) {
					if (!objContact.Is_Billing_Admin__c) {
						objContact.Is_Billing_Admin__c = objRole.Billing_Admin__c && String.isNotBlank(objRole.Role_Name__c) && objRole.Role_Name__c == ZPUserRoleUtil.ACCOUNTANT;
					}

					if (!objContact.Freelance_Accountant__c) {
						// Update if User is Freelance Accountant
						objContact.Freelance_Accountant__c = objRole.Collaborator_Type__c == ZPUserRoleUtil.EXTERNAL_ACCOUNTANT;
					}
				}
			}
		}

		if (!blnAccountSet) {
			// If account id is not set based on prioritized logic above, use this method to set account based on recent non-deleted user role
			// Set Account Id on Contact as company id of most recent non deleted user role
			objContact = setAccountIdOnContact(objContact, objZPUserRole);
		}

		// Set User Role an User Role text on Contact
		if (map_UserIdToRoleNamesSet.containsKey(objZPUserRole.User_Id__c)) {
			objContact.ZP_User_Role__c = objContact.ZP_User_Role_Text__c = String.join(new List<String>(map_UserIdToRoleNamesSet.get(objZPUserRole.User_Id__c)), ';');
		}
	}

	/**
	 * @description Sets basic info on Contact like first name, last name and email
	 * @author      Praveen Sethu
	 * @param       ZP_User_Role__c User role in context
	 * @param       ZP_User_Role__c objNameRoleInfo - user role to take name information from
	 * @param       Contact record to be updated
	 * @return      NA
	 **/
	public void setContactBasicInfo(ZP_User_Role__c objZPUserRole, ZP_User_Role__c objNameRoleInfo, Contact objContact) {
		if (objNameRoleInfo != null) {
			objContact.FirstName = getSubstring(objNameRoleInfo.First_Name__c, 40);
			objContact.LastName = getSubstring(objNameRoleInfo.Last_Name__c, 80);
			objContact.ZP_Phone__c = objNameRoleInfo.Phone__c;
			objContact.SSN_Last_4__c = objNameRoleInfo.Last_Four_SSN__c;
		} else {
			objContact.FirstName = getSubstring(objZPUserRole.First_Name__c, 40);
			objContact.LastName = getSubstring(objZPUserRole.Last_Name__c, 80);
			if (String.isNotBlank(objZPUserRole.Last_Four_SSN__c)) {
				objContact.SSN_Last_4__c = objZPUserRole.Last_Four_SSN__c;
			}
			objContact.ZP_Phone__c = objZPUserRole.Phone__c;
		}

		// Check if Contact still doesn't have a phone number and current role has phone number
		if (String.isBlank(objContact.ZP_Phone__c) && String.isNotBlank(objZPUserRole.Phone__c)) {
			objContact.ZP_Phone__c = objZPUserRole.Phone__c;
		}
	}

	/**
	 * @description Set Account on Contact as Company Id on most recent non-deleted user role
	 * @author      Praveen Sethu
	 * @param       Contact objCon
	 * @param       ZP_User_Role__c objRole
	 * @return      Contact instance after setting right account id
	 **/
	public Contact setAccountIdOnContact(Contact objCon, ZP_user_Role__c objRole) {
		if (
			objCon != null &&
			objCon.Id != null &&
			objCon.RecordTypeId == ZPUserRoleUtil.CONTACT_COMPANY_RT_ID &&
			String.isNotBlank(objRole.User_Id__c) &&
			map_ZPUserIdToZPUserRoles.containsKey(objRole.User_Id__c)
		) {
			// Iterate over all user roles and find the most recent non-deleted user role
			ZP_user_Role__c objLatestRole;
			Id idLatestAccount;
			for (ZP_user_Role__c objRoleIterator : map_ZPUserIdToZPUserRoles.get(objRole.User_Id__c)) {
				// Assume trigger context record has the latest data
				if (objRoleIterator.Id == objRole.Id) {
					objRoleIterator = objRole;
				}

				if (
					objRoleIterator.Deleted_At__c == null &&
					String.isNotBlank(objRoleIterator.Company_Id__c) &&
					map_ZPCompanyIdToAccount != null &&
					map_ZPCompanyIdToAccount.containsKey(objRoleIterator.Company_Id__c) &&
					(objLatestRole == null ||
					objRoleIterator.CreatedDate >= objLatestRole.CreatedDate)
				) {
					objLatestRole = objRoleIterator;
					idLatestAccount = map_ZPCompanyIdToAccount.get(objRoleIterator.Company_Id__c).Id;
				}
			}

			if (idLatestAccount != null) {
				objCon.Inactive_ZP_User__c = false;
				objCon.AccountId = idLatestAccount;
			}
		}
		return objCon;
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Reset fields on user role if record is deleted
	 * @param       : objZPUserRole - New ZPUserRole
	 * @return      : N/A
	 **/
	public void resetFieldsIfDeleted(ZP_User_Role__c objZPUserRole) {
		if (objZPUserRole.Deleted_At__c != null) {
			objZPUserRole.Contact__c = null;
			objZPUserRole.ZP_User__c = null;
			objZPUserRole.Company_Account__c = null;
			objZPUserRole.Accounting_Firm_Account__c = null;
		}
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Update Tier update status on Account
	 * @param       : objZPUserRole - New ZPUserRole
	 * @return      : N/A
	 **/
	public void updateAccountForConciergeBatch(List<ZP_User_Role__c> list_NewRoles) {
		Set<String> set_Companies = new Set<String>();
		List<Account> list_AccountsToUpdate = new List<Account>();

		// Update Tier Update status once on insert and delete
		for (ZP_User_Role__c objRole : list_NewRoles) {
			if (Trigger.isInsert && String.isNotblank(objRole.Company_Id__c) && objRole.Deleted_At__c == null) {
				set_Companies.add(objRole.Company_Id__c);
			}
			if (Trigger.isUpdate && objRole.Deleted_At__c != null) {
				set_Companies.add(objRole.Company_Id__c);
			}
		}

		if (!set_Companies.isEmpty()) {
			for (Account objAcc : queryAccounts(set_Companies, new Set<String>())) {
				// Update Tier Update Status if its already processed
				if (objAcc.Tier_Update_Status__c == ZPUserRoleUtil.TIER_UPDATE_PROCESSED) {
					objAcc.Tier_Update_Status__c = ZPUserRoleUtil.TIER_UPDATE_NOT_PROCESSED;
					list_AccountsToUpdate.add(objAcc);
				}
			}

			if (!list_AccountsToUpdate.isEmpty()) {
				AccountTriggerHelper.skipTrigger = true;
				update list_AccountsToUpdate;
			}
		}
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Returns sub string based on given length
	 * @param       : String strValue
	 * @param       : Integer - intLen
	 * @return      : String - Substring
	 **/
	private String getSubstring(String strValue, Integer intLen) {
		if (String.isNotBlank(strValue) && strValue.length() > intLen) {
			strValue = strValue.substring(0, intLen);
		}
		return strValue;
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Handles change in Processing_State__c & Message__c.
	 * @param       : objZPUserRole - New ZPUserRole
	 * @return      : N/A
	 **/
	public void setProcessingStateAndMessage(ZP_User_Role__c objZPUserRole, String strProcessingState, String strMessage) {
		objZPUserRole.Processing_State__c = strProcessingState;
		objZPUserRole.Last_Processed__c = System.now();

		if (strProcessingState == IntegrationUtils.PROCESSED_STATE) {
			objZPUserRole.Message__c = strProcessingState;
		} else {
			objZPUserRole.Message__c = String.isNotBlank(objZPUserRole.Message__c) ? objZPUserRole.Message__c + ' - ' + strMessage : strMessage;
		}

		if (objZPUserRole.Message__c?.length() > 255) {
			objZPUserRole.Message__c = objZPUserRole.Message__c.substring(0, 255);
		}
	}

	// All queries start here
	/**
	 * @author      : Praveen Sethu
	 * @description : Build a map of company id and user roles
	 * @param       : Set<String> = Set of company ids
	 * @return      : NA
	 **/
	public void getUserRolesByCompanyId(Set<String> set_CompanyIds) {
		if (!set_CompanyIds.isEmpty()) {
			for (ZP_User_Role__c objRole : [
				SELECT
					Id,
					CreatedDate,
					Type__c,
					First_Name__c,
					Last_Name__c,
					Is_Primary__c,
					Collaborator_Type__c,
					User_Id__c,
					Accounting_Firm_Id__c,
					Accounting_Firm_Account__c,
					Company_Id__c,
					Deleted_At__c,
					Company_Account__c,
					Phone__c,
					Last_Four_SSN__c,
					Contact__c,
					Role_Name__c,
					Processing_State__c,
					Contractor_Id__c,
					Employee_Id__c,
					Is_Accountant__c
				FROM ZP_User_Role__c
				WHERE Company_Id__c IN :set_CompanyIds AND Deleted_At__c = NULL
			]) {
				// Build a map of Company Id and User Roles
				if (map_CompanyIdToZPUserRoles.containsKey(objRole.Company_Id__c)) {
					map_CompanyIdToZPUserRoles.get(objRole.Company_Id__c).add(objRole);
				} else {
					map_CompanyIdToZPUserRoles.put(objRole.Company_Id__c, new List<ZP_User_Role__c>{ objRole });
				}
			}
		}
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Query ZP User Roles By Id
	 * @param       : set_UserIds - Set of user ids
	 * @return      : List of ZP User Roles
	 **/
	private List<ZP_User_Role__c> queryZpUserRoleByUserId(Set<String> set_UserIds) {
		List<ZP_User_Role__c> list_Roles = new List<ZP_User_Role__c>();
		for (ZP_User_Role__c objRole : [
			SELECT
				Id,
				CreatedDate,
				Type__c,
				First_Name__c,
				Last_Name__c,
				Is_Primary__c,
				Collaborator_Type__c,
				User_Id__c,
				Accounting_Firm_Id__c,
				Accounting_Firm_Account__c,
				Company_Id__c,
				Deleted_At__c,
				Company_Account__c,
				Phone__c,
				Last_Four_SSN__c,
				Contact__c,
				Role_Name__c,
				Processing_State__c,
				Contractor_Id__c,
				Employee_Id__c,
				Is_Accountant__c,
				Billing_Admin__c,
				Employment_Type__c
			FROM ZP_User_Role__c
			WHERE User_Id__c IN :set_UserIds AND Deleted_At__c = NULL
		]) {
			list_Roles.add(objRole);
		}
		return list_Roles;
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Query ZP Users by Id
	 * @param       : set_UserIds - Set of user ids
	 * @return      : List of users
	 **/
	public static List<ZP_User__c> queryZPUsers(Set<String> set_UserIds) {
		return [SELECT Id, Email__c, Id__c, Disable_Emails__c, Deleted_At__c, Contact__c, Referral_Token__c, Processing_State__c, Message__c FROM ZP_User__c WHERE Id__c IN :set_UserIds];
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Query accounts based on company ids and accounting firm ids
	 * @param       : set_CompanyIds - Set of Company Ids
	 * @param       : set_AccFirmIds - Set of Accounting Firm Ids
	 * @return      : List of company and reseller accounts
	 **/
	public static List<Account> queryAccounts(Set<String> set_CompanyIds, Set<String> set_AccFirmIds) {
		return [
			SELECT Id, Name, ZP_Company_ID__c, ZP_Firm_ID__c, OwnerId, Has_Accountant__c, RecordTypeId, Tier_Update_Status__c, RecordType.Name
			FROM Account
			WHERE
				((RecordTypeId = :ZPUserRoleUtil.ACCOUNT_COMPANY_RT_ID
				OR RecordTypeId = :ZPUserRoleUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID)
				AND ZP_Company_ID__c != NULL
				AND ZP_Company_ID__c IN :set_CompanyIds)
				OR (RecordTypeId = :ZPUserRoleUtil.ACCOUNT_RESELLER_RT_ID
				AND ZP_Firm_ID__c != NULL
				AND ZP_Firm_ID__c IN :set_AccFirmIds)
		];
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Returns list of employees by employee ids
	 * @param       : set_EmployeeIds - Set of Employee Ids from ZP_User_Role__c
	 * @return      : Returns list of employees by employee ids
	 **/
	public List<ZP_Employee__c> queryEmployees(Set<String> set_EmployeeIds) {
		return [SELECT Id, Id__c, Payment_Method_Type__c FROM ZP_Employee__c WHERE Id__c IN :set_EmployeeIds];
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Query contacts by user id and email addresses
	 * @param       : set_UserIds - Set of ZP User Ids
	 * @param       : set_ZPUserEmails - Set of Contacts
	 * @return      : Returns list of contacts
	 **/
	public static List<Contact> queryContacts(Set<String> set_UserIds, Set<String> set_ZPUserEmails) {
		return [
			SELECT
				Id,
				FirstName,
				LastName,
				ZP_User_Id__c,
				Email,
				RecordTypeId,
				RecordType.Name,
				LeadSource,
				Inactive_Zp_User__c,
				ZP_User_Role__c,
				Is_UX_Active__c,
				Cashout_Eligible_at__c,
				Cashout_Invited_at__c,
				Cashout_Enrolled_At__c,
				Cashout_Disqualified_At__c,
				Cashout_Disqualification_Reasons__c,
				Latest_Cashout_Date__c,
				Unique_Email_Address_Contact__c,
				Legal_Name__c,
				(
					SELECT Id, Preferred_Name__c, CreatedDate
					FROM ZP_User_Roles__r
					WHERE Preferred_Name__c != NULL AND Role_Name__c != :SIGNATORY AND Deleted_At__c = NULL
					ORDER BY CreatedDate DESC
					LIMIT 1
				)
			FROM Contact
			WHERE ZP_User_Id__c IN :set_UserIds OR Email IN :set_ZPUserEmails OR Unique_Email_Address_Contact__c IN :set_ZPUserEmails
		];
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Query leads by email address
	 * @param       : set_ZPUserEmails - Set of Email addresses
	 * @return      : Returns list of leads
	 **/
	public static List<Lead> queryLeads(Set<String> set_ZPUserEmails) {
		return [
			SELECT Id, FirstName, LastName, ZP_User_Id__c, Email, RecordTypeId, Referred_By__c, RecordType.Name, IsConverted, ABC_Lead_Match__c, ABC_Match_Account__c, LeadSource
			FROM Lead
			WHERE Email IN :set_ZPUserEmails
		];
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Query account email domain records
	 * @param       : set_ZPUserEmailDomains - Set of Email domains
	 * @return      : Returns list of account email domains
	 **/
	public static List<Account_Email_Domain__c> queryAccountEmailDomains(Set<String> set_ZPUserEmailDomains) {
		Id idResellerRType = ZPUserRoleUtil.ACCOUNT_RESELLER_RT_ID;
		return [
			SELECT Id, Name, Account__c, Account__r.Id, Account__r.Name, Account__r.OwnerId
			FROM Account_Email_Domain__c
			WHERE Name IN :set_ZPUserEmailDomains AND Account__r.RecordTypeId = :idResellerRType
		];
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Get list of allowed roles
	 * @param       : strComponent - Name of component
	 * @return      : Returns list of allowed roles
	 **/
	public static Set<String> getRolesSet(String strComponent) {
		Map<String, Rolesets__c> map_RoleSets = Rolesets__c.getAll();
		Set<String> set_AllowedRoles = new Set<String>();
		for (Rolesets__c objRoleSet : map_RoleSets.values()) {
			List<String> list_Components = objRoleSet.Components__C.split('\\r\\n');
			Set<String> set_Components = new Set<String>();
			set_Components.addAll(list_Components);
			if (set_Components.contains(strComponent)) {
				List<String> list_AllowedRoles = objRoleSet.Roles__c.split('\\r\\n');
				set_AllowedRoles.addAll(list_AllowedRoles);
				break;
			}
		}
		return set_AllowedRoles;
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Query opportunity and contact roles
	 * @param       : set_AccountIds - Set of account ids
	 * @param       : set_RecTypes - Set of record type ids
	 * @param       : set_AllowedRoles - set of allowed role
	 * @return      : Returns list of opportunities and contact roles
	 **/
	public static List<Opportunity> queryOpportunities(Set<Id> set_AccountIds, Set<Id> set_RecTypes, Set<String> set_AllowedRoles) {
		return [
			SELECT Id, AccountId, (SELECT Id, Role, ContactId, OpportunityId FROM OpportunityContactRoles WHERE Role IN :set_AllowedRoles)
			FROM Opportunity
			WHERE RecordTypeId IN :set_RecTypes AND AccountId IN :set_AccountIds AND IsClosed = FALSE
		];
	}
}