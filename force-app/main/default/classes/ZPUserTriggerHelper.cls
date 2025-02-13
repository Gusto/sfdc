/**
 * @name         : ZPUserTriggerHelper
 * @author       : Aurobind Ravichandran
 * @date         : 04-05-2017
 * @description  : Functionality to process ZP User information on Contact/Lead/Account
 * @test classes : ZPUserTriggerHelperTest
 **/
public class ZPUserTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Integer counter = 0;
	public static Boolean queue = false;
	public static Map<String, ZP_User_Role__c> AccountantRoleMap;
	public static Map<String, ZP_User_Role__c> PayrollAdminRoleMap;
	public static Set<String> companyIdSet;
	public static Set<String> firmIdSet;
	public static final String PRIMARY_PAYROLL_ADMIN = Label.Primary_Payroll_Admin;
	public static final String PAYROLL_ADMIN = Label.Payroll_Admin;
	public static final String ACCOUNTANT = Label.Accountant;
	public static Map<String, List<ZP_User_Role__c>> map_zpUserIdZpUserRoles;

	public static Map<Id, Contact> map_Contacts;

	public static final String ERROR_STATE = 'Error';
	public static final String QUEUED_STATE = 'Queued';
	public static final String PROCESSED_STATE = 'Processed';
	public static final String DEAD_STATE = 'Dead';
	public static final String BACKLOG = 'Backlog';
	public static final String MANUAL_ENQUEUE = 'Manually Enqueued';

	public static Boolean blnSkipTestAccountDmlError = true;
	public static Boolean blnSkipTestContactDmlError = true;
	public static Boolean blnSkipTestLeadDmlError = true;
	public static final Set<String> set_AllowChangeFields = new Set<String>{
		'processing_state__c',
		'is_changed__c',
		'updated_at__c',
		'kafka_upserted_datetime__c',
		'mulesoft_bulk_job_id__c',
		'mulesoft_job_id__c'
	};
	public static final Set<String> set_InactiveStatus = new Set<String>{ IntegrationUtils.ERROR_STATE, IntegrationUtils.DEAD_STATE, IntegrationUtils.BACKLOG };

	public void processBeforeInsert(List<ZP_User__c> list_ZPUsers) {
		//On insert only change processing state to Queued
		//for processing it'll be picked up by batch job.
		if (!skipTrigger && !validateStatus(list_ZPUsers)) {
			for (ZP_User__c objZPUser : list_ZPUsers) {
				objZPUser.Processing_State__c = QUEUED_STATE;
				objZPUser.Is_Changed__c = true;

				if (objZPUser.Last_Sign_In_At__c != null) {
					objZPUser.Sign_In_Changed__c = true;
				}
			}
		}
	}

	public void processBeforeUpdate(Map<Id, ZP_User__c> map_ZPUsers, Map<Id, ZP_User__c> map_OldZPUsers) {
		//if updated by inegration - change processing state to queued
		if (!skipTrigger && !validateStatus(map_ZPUsers.values())) {
			List<String> list_UserFields = new List<String>(ZP_User__c.SObjectType.getDescribe().fields.getMap().keySet());

			for (ZP_User__c objZPUser : map_ZPUsers.values()) {
				ZP_User__c objOldZPUser = map_OldZPUsers.get(objZPUser.Id);

				// Allow records to be in Backlog or Dead instead of defaulting to queued for every update
				if (objOldZPUser != null && objOldZPUser.Processing_State__c != BACKLOG && objZPUser.Processing_State__c == BACKLOG) {
					objZPUser.Processing_State__c = BACKLOG;
				} else if (objOldZPUser != null && objOldZPUser.Processing_State__c != DEAD_STATE && objZPUser.Processing_State__c == DEAD_STATE) {
					objZPUser.Processing_State__c = DEAD_STATE;
				} else {
					objZPUser.Processing_State__c = QUEUED_STATE; //set status to queued
				}

				if (objZPUser.Email__c != null && objOldZPUser.Email__c != objZPUser.Email__c) {
					objZPUser.Previous_Email__c = objOldZPUser.Email__c;
				}

				// Identify if there was any change to any fields on ZP User
				if (!objZPUser.Is_Changed__c && !set_InactiveStatus.contains(objZPUser.Processing_State__c) && objOldZPUser != null) {
					for (String strField : list_UserFields) {
						// processing_state__c and is_changed__c are custom fields that are manipulated by code. Hence ignoring these two fields
						if (String.isNotBlank(strField) && !set_AllowChangeFields.contains(strField.toLowerCase())) {
							if (objZPUser.get(strField) != objOldZPUser.get(strField)) {
								objZPUser.Is_Changed__c = true;
							}
						}
					}
				}

				// check for change in last sign in at
				if (objZPUser.Last_Sign_In_At__c != null && objOldZPUser.Last_Sign_In_At__c != objZPUser.Last_Sign_In_At__c) {
					// Check if user role contains payroll admin or primary payroll admin or accountant
					if (
						String.isNotBlank(objZPUser.User_Roles__c) &&
						(objZPUser.User_Roles__c.containsIgnoreCase(PAYROLL_ADMIN) ||
						objZPUser.User_Roles__c.containsIgnoreCase(PRIMARY_PAYROLL_ADMIN) ||
						objZPUser.User_Roles__c.containsIgnoreCase(ACCOUNTANT))
					) {
						objZPUser.Sign_In_Changed__c = true;
					} else {
						// reset sign in changed flag if user role is not admin or accountant
						objZPUser.Sign_In_Changed__c = false;
						objZPUser.Is_Changed__c = false;
					}
				}

				if (!objZPUser.Is_Changed__c && !set_InactiveStatus.contains(objZPUser.Processing_State__c)) {
					objZPUser.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
					objZPUser.Message__c = IntegrationUtils.PROCESSED_STATE;
					objZPUser.No_Update_Counter__c = objZPUser.No_Update_Counter__c == null ? 1 : objZPUser.No_Update_Counter__c + 1;
				}
			}
		} else if (validateStatus(map_ZPUsers.values())) {
			//for manual processing - run in real time.
			processInformation(map_ZPUsers.values());
		}
	}

	//returns true if manual processing
	public Boolean validateStatus(List<ZP_User__c> list_ZPUsers) {
		ZP_User__c objZPUser = list_ZPUsers[0];

		if (objZPUser.Processing_State__c == MANUAL_ENQUEUE)
			return true;

		return false;
	}

	public void processInformation(List<ZP_User__c> list_NewUsers) {
		List<Contact> contactList = new List<Contact>();
		Set<String> userIdSet = new Set<String>();
		Set<String> emailSet = new Set<String>();
		Map<String, ZP_User__c> emailUserMap = new Map<String, ZP_User__c>();
		Map<String, ZP_User__c> map_EmailUserIdToUser = new Map<String, ZP_User__c>();
		Map<String, ZP_User__c> userIdUserMap = new Map<String, ZP_User__c>();
		Map<String, Contact> userIdContactMap = new Map<String, Contact>();
		Map<Id, ZP_User_Role__c> map_RolesToReProcess = new Map<Id, ZP_User_Role__c>();
		Set<String> set_ReferralTokens = new Set<String>();
		Map<String, List<ZP_User__c>> map_RefTokenToUsers = new Map<String, List<ZP_User__c>>();
		List<Exception_Log__c> list_exeptionLogs = new List<Exception_Log__c>();
		Map<Id, ZP_User__c> map_UsersToProcess = new Map<Id, ZP_User__c>();

		map_Contacts = new Map<Id, Contact>();
		// Filters fraud records and marks them as Dead
		list_NewUsers = returnRecordsToProcess(list_NewUsers);

		for (ZP_User__c user : list_NewUsers) {
			if (String.isBlank(user.Email__c)) {
				setProcessingState(DEAD_STATE, 'Email missing on ZP User', user);
			}

			if (user.Processing_State__c == DEAD_STATE) {
				continue;
			}
			user.Processing_State__c = QUEUED_STATE;

			if (String.isNotBlank(user.Email__c)) {
				emailSet.add(user.Email__c);
				emailUserMap.put(user.email__c, user);
				map_EmailUserIdToUser.put(user.email__c + '-' + user.Id__c, user);
			}

			if (String.isNotBlank(user.Id__c)) {
				userIdSet.add(user.Id__c);
				userIdUserMap.put(user.Id__c, user);
			}

			if (String.isNotBlank(user.Referral_Token__c)) {
				set_ReferralTokens.add(user.Referral_Token__c);
			}

			// Update Referral Token if the User Record was Deleted. This avoids Duplicate Referral Token issues on Contact.
			if (user.Deleted_At__c != null && String.isNotBlank(user.Referral_Token__c)) {
				user.Referral_Token__c = '';
			}
		}

		if (!set_ReferralTokens.isEmpty()) {
			map_RefTokenToUsers = queryUsersByToken(set_ReferralTokens);
		}

		contactList = new List<Contact>();
		List<Lead> leadList = new List<Lead>();

		map_zpUserIdZpUserRoles = new Map<String, List<ZP_User_Role__c>>();

		for (ZP_User_Role__c objRole : [SELECT Id, Accounting_Firm_Id__c, Company_Id__c, Type__c, User_Id__c, Role_Name__c, Processing_State__c FROM ZP_User_Role__c WHERE User_Id__c IN :userIdSet]) {
			List<ZP_User_Role__c> list_roles = new List<ZP_User_Role__c>();
			if (map_zpUserIdZpUserRoles.containsKey(objRole.User_Id__c))
				list_roles = map_zpUserIdZpUserRoles.get(objRole.User_Id__c);

			list_roles.add(objRole);
			map_zpUserIdZpUserRoles.put(objRole.User_Id__c, list_roles);

			// Process any role that was backlogged or dead
			if (objRole.Processing_State__c == IntegrationUtils.BACKLOG || objRole.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				objRole.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				map_RolesToReProcess.put(objRole.Id, objRole);
			}
		}

		// Check if there are any roles associated with user. If not, set them to Backlog
		for (ZP_User__c objUser : list_NewUsers) {
			if (objUser.Processing_State__c == DEAD_STATE) {
				continue;
			}

			// Remove users with duplicate referral tokens
			if (String.isNotBlank(objUser.Referral_Token__c) && map_RefTokenToUsers.containsKey(objUser.Referral_Token__c)) {
				List<ZP_User__c> list_Users = map_RefTokenToUsers.get(objUser.Referral_Token__c);

				// If more than one user is found with same referral token, set referral token as blank on already processed ones
				if (list_Users.size() > 1) {
					for (ZP_User__c objRefUser : list_Users) {
						if (objRefUser.Contact__c != null) {
							objRefUser.Referral_Token__c = '';
							objRefUser.Processing_State__c = MANUAL_ENQUEUE;
							map_UsersToProcess.put(objRefUser.Id, objRefUser);
						}
					}
				}
			}

			if (!map_zpUserIdZpUserRoles.containsKey(objUser.Id__c)) {
				setProcessingState(BACKLOG, 'User Roles missing on ZP User', objUser);
			}
		}

		contactList = [
			SELECT
				Id,
				Email,
				Last_Login_Date_Time__c,
				ZP_User_Id__c,
				Inactive_ZP_User__c,
				Unique_Email_Address_Contact__c,
				UUID__c,
				OwnerId,
				AccountId,
				Account.Name,
				Account.RecordTypeId,
				Account.RecordType.Name,
				RecordType.Name,
				Account.ZP_Company_id__c,
				Account.ZP_Firm_id__c,
				Account.Cohort_Date__c,
				Account.Last_Login_Details__c,
				Normalized_Email_Domain__c,
				Normalized_Alternate_Email_Domain__c,
				FirstName,
				LastName,
				Phone,
				Lead_Status__c,
				Account.Joined_Date_Panda__c,
				Account.Last_Login_Time__c,
				CreatedDate,
				(
					SELECT Id, StageName, CreatedDate, Account.Last_Activity_Date__c, Order__r.Status, Isclosed, Order__c, Stage_Detail__c, IsWon
					FROM Opportunities
					WHERE RecordType.Name = 'Company Opportunity'
				),
				(SELECT Id, Owner_Role_Formula__c, Status, Type, ActivityDate FROM Tasks WHERE Owner_Role_Formula__c LIKE 'sales%' AND ActivityDate >= LAST_N_DAYS:60 ORDER BY ActivityDate DESC),
				(SELECT Id, Type__c FROM ZP_user_roles__r LIMIT 1)
			FROM Contact
			WHERE Email IN :emailSet OR Unique_Email_Address_Contact__c IN :emailSet OR ZP_User_Id__c IN :userIdSet
		];

		Map<String, Id> map_UserIdToContactId = new Map<String, Id>();
		Map<String, Id> map_EmailToContactId = new Map<String, Id>();
		for (Contact c : contactList) {
			map_Contacts.put(c.Id, c);

			if (!String.isBlank(c.ZP_User_Id__c)) {
				map_UserIdToContactId.put(c.ZP_User_Id__c, c.Id);
			}

			if (String.isNotBlank(c.Email)) {
				map_EmailToContactId.put(c.Email, c.Id);
			} else if (String.isNotBlank(c.Unique_Email_Address_Contact__c)) {
				map_EmailToContactId.put(c.Unique_Email_Address_Contact__c, c.Id);
			}
		}

		Map<String, ZP_User__c> map_EmailToRecentZPUser = new Map<String, ZP_User__c>();
		for (ZP_User__c objZPUser : queryZPUsersByEmail(map_EmailToContactId.keySet())) {
			if (!map_EmailToRecentZPUser.containsKey(objZPUser.Email__c)) {
				map_EmailToRecentZPUser.put(objZPUser.Email__c, objZPUser);
			} else {
				// get the most recent user
				ZP_User__c objMostRecentUser = map_EmailToRecentZPUser.get(objZPUser.Email__c);
				// if email on the most recent user is null and email on the current user is not null, replace the most recent user with the current user
				if (objZPUser.Previous_Email__c != null && objMostRecentUser.Previous_Email__c == null) {
					map_EmailToRecentZPUser.put(objZPUser.Email__c, objZPUser);
				}
			}
		}

		List<Contact> lstContactToUpdate = new List<Contact>();
		List<Contact> list_EmailContacts = new List<Contact>();
		for (Contact c : contactList) {
			if (emailUserMap.containsKey(c.email)) {
				ZP_User__c usr = emailUserMap.get(c.email);

				ZP_User__c objMostRecentZPUser = map_EmailToRecentZPUser.get(c.email);
				if (objMostRecentZPUser != null && objMostRecentZPUser.Id__c != c.ZP_User_Id__c && map_UserIdToContactId.containsKey(objMostRecentZPUser.Id__c)) {
					c.Unique_Email_Address_Contact__c = null;
					list_EmailContacts.add(c);
					continue;
				} else if (c.ZP_user_roles__r.isEmpty()) {
					// if no user role is linked with contact - reset unique email address
					c.Unique_Email_Address_Contact__c = null;
					list_EmailContacts.add(c);
				}

				// 06.19.2020 - Handles situation where there is more then 1 contact with the same email.
				if (!String.isBlank(c.ZP_User_Id__c)) {
					if (map_EmailUserIdToUser.containsKey(c.Email + '-' + c.ZP_User_Id__c)) {
						usr = map_EmailUserIdToUser.get(c.Email + '-' + c.ZP_User_Id__c);
					} else {
						continue;
					}
				} else {
					if (map_UserIdToContactId.containsKey(usr.Id__c)) {
						Id contactId = map_UserIdToContactId.get(usr.Id__c);

						if (contactId != c.Id) {
							continue;
						}
					}
				}

				if (c.ZP_User_Id__c == null || c.ZP_User_Id__c == '' || (c.ZP_User_Id__c == usr.Id__c || (c.Inactive_ZP_User__c && c.ZP_User_Id__c != usr.Id__c))) {
					c.Last_Login_Date_Time__c = usr.Last_Sign_In_At__c;
					if (usr.Last_Sign_In_At__c != null && usr.Current_Sign_In_At__c != null && usr.Current_Sign_In_At__c > usr.Last_Sign_In_At__c) {
						c.Last_Login_Date_Time__c = usr.Current_Sign_In_At__c;
					}
					if (c.Last_Login_Date_Time__c != null && usr.Current_Sign_In_At__c >= (system.today() - 1)) {
						c = GFLeadTriggerHelper.getContactInfoForUpdate(c, 'User signed in');
					}
					c.ZP_User_Id__c = usr.Id__c;
					c.Referral_Token__c = usr.Processing_State__c == BACKLOG ? '' : usr.Referral_Token__c;
					c.Disable_Email__c = usr.Disable_Emails__c;

					if (c.Inactive_ZP_User__c) {
						c.Inactive_ZP_User__c = false;
					}
					if (usr.Deleted_At__c != null && c.Inactive_Zp_User__c == false) {
						c.Inactive_Zp_User__c = true;
					}
					c.UUID__c = usr.UUID__c;
					c.Accountant_Referral_Token__c = usr.Accountant_Referral_Token__c;
					c.Partner_Referral_Token__c = usr.Partner_Referral_Token__c;
					c.User_Referral_Reward__c = usr.User_Referral_Reward__c;
					lstContactToUpdate.add(c);
				} else if (c.ZP_User_Id__c != null && c.ZP_User_Id__c != '' && c.ZP_User_Id__c != usr.Id__c) {
					setProcessingState(ERROR_STATE, 'User Id did not match between contact and ZP User.', usr);
				}
			} else if (userIdUserMap.containsKey(c.ZP_User_Id__c)) {
				ZP_User__c usr = userIdUserMap.get(c.ZP_User_Id__c);
				if (c.ZP_User_Id__c != null && c.ZP_User_Id__c != '' && c.ZP_User_Id__c == usr.Id__c) {
					c.Last_Login_Date_Time__c = usr.Last_Sign_In_At__c;
					if (usr.Last_Sign_In_At__c != null && usr.Current_Sign_In_At__c != null && usr.Current_Sign_In_At__c > usr.Last_Sign_In_At__c) {
						c.Last_Login_Date_Time__c = usr.Current_Sign_In_At__c;
					}
					if (c.Last_Login_Date_Time__c != null && c.Last_Login_Date_Time__c >= (system.today() - 1)) {
						c = GFLeadTriggerHelper.getContactInfoForUpdate(c, 'User signed in');
					}
					c.UUID__c = usr.UUID__c;
					c.Email = usr.Email__c;
					c.Unique_Email_Address_Contact__c = usr.Email__c;
					c.Referral_Token__c = usr.Processing_State__c == BACKLOG ? '' : usr.Referral_Token__c;
					c.Disable_Email__c = usr.Disable_Emails__c;
					if (usr.Deleted_At__c != null && c.Inactive_Zp_User__c == false) {
						c.Inactive_Zp_User__c = true;
					}
					c.Accountant_Referral_Token__c = usr.Accountant_Referral_Token__c;
					c.Partner_Referral_Token__c = usr.Partner_Referral_Token__c;
					c.User_Referral_Reward__c = usr.User_Referral_Reward__c;
					lstContactToUpdate.add(c);
				}
				userIdContactMap.put(c.ZP_User_Id__c, c);
			} else if (emailUserMap.containsKey(c.Unique_Email_Address_Contact__c) && c.Inactive_ZP_User__c == true) {
				ZP_User__c usr = emailUserMap.get(c.Unique_Email_Address_Contact__c);

				// 06.19.2020 - Handles situation where there is more then 1 contact with the same email.
				if (!String.isBlank(c.ZP_User_Id__c)) {
					if (map_EmailUserIdToUser.containsKey(c.Email + '-' + c.ZP_User_Id__c)) {
						usr = map_EmailUserIdToUser.get(c.Email + '-' + c.ZP_User_Id__c);
					} else {
						continue;
					}
				}

				if (usr.Deleted_At__c == null) {
					c.Inactive_Zp_User__c = false;
					c.ZP_User_Id__c = usr.Id__c;
					c.email = usr.Email__c;
					c.Unique_Email_Address_Contact__c = usr.Email__c;
					lstContactToUpdate.add(c);
				}
			}
		}

		// Process users with duplicate referral tokens
		if (!map_UsersToProcess.isEmpty()) {
			update map_UsersToProcess.values();
		}

		if (!list_EmailContacts.isEmpty()) {
			ContactTriggerHelper.skiptrigger = true;
			update list_EmailContacts;
			ContactTriggerHelper.skiptrigger = false;
		}

		if (lstContactToUpdate.size() > 0) {
			if (Test.isRunningTest() && !blnSkipTestContactDmlError) {
				lstContactToUpdate[0].LastName = null;
			}

			Boolean contTriggerSkip = ContactTriggerHelper.skiptrigger;
			ContactTriggerHelper.skiptrigger = true;
			List<Database.SaveResult> resultList = Database.update(lstContactToUpdate, false);
			for (Integer i = 0; i < resultList.size(); i++) {
				Database.SaveResult result = resultList[i];
				Contact contactInfo = lstContactToUpdate[i];
				ZP_User__c userInfo = null;
				if (emailUserMap.containsKey(contactInfo.email)) {
					userInfo = emailUserMap.get(contactInfo.email);
					if (map_EmailUserIdToUser.containsKey(contactInfo.Email + '-' + contactInfo.ZP_User_Id__c)) {
						userInfo = map_EmailUserIdToUser.get(contactInfo.Email + '-' + contactInfo.ZP_User_Id__c);
					}
				} else if (userIdUserMap.containsKey(contactInfo.ZP_User_Id__c)) {
					userInfo = userIdUserMap.get(contactInfo.ZP_User_Id__c);
				}

				if (result.isSuccess()) {
					if (userInfo.Processing_State__c == QUEUED_STATE) {
						userInfo.Contact__c = contactInfo.Id;
						setProcessingState(PROCESSED_STATE, 'Information successfully processed', userInfo);
						userInfo.Is_Changed__c = false;
					}
				} else {
					String error = '';
					for (Database.Error objErr : result.getErrors()) {
						error = objErr.getStatusCode() + ': ' + objErr.getMessage();
						String message = objErr.getMessage();
						message = message.length() > 255 ? message.substring(0, 254) : message;

						// set processing state to Dead if user has invalid email address
						if (String.isNotBlank(message) && message.containsIgnoreCase(ZPUserRoleUtil.INVALID_EMAIL_ADDRESS_ERROR)) {
							setProcessingState(DEAD_STATE, ZPUserRoleUtil.INVALID_EMAIL_ADDRESS_ERROR, userInfo);
							continue;
						} else if (String.isNotBlank(message) && message.containsIgnoreCase(ZPUserRoleUtil.DUPLICATE) && message.containsIgnoreCase(ZPUserRoleUtil.REFERRAL_TOKEN)) {
							continue;
						}

						Exception_Log__c log = new Exception_Log__c(
							Type__c = 'Error',
							Class_Name__c = 'ZPUserTriggerHelper',
							Method_Name__c = 'process information - Contact update',
							Message__c = message
						);
						list_exeptionLogs.add(log);
					}

					if (userInfo.Processing_State__c != DEAD_STATE) {
						setProcessingState(ERROR_STATE, error.left(255), userInfo);
					}
				}
			}
			ContactTriggerHelper.skiptrigger = contTriggerSkip;
		}

		for (ZP_user__c usr : list_NewUsers) {
			if (userIdContactMap.containsKey(usr.Id__c)) {
				usr.Contact__c = userIdContactMap.get(usr.Id__c).Id;
			}

			// Re-process user roles when contact does not exist
			if (!userIdContactMap.containsKey(usr.Id__c) && !map_EmailToContactId.containsKey(usr.Email__c) && map_zpUserIdZpUserRoles.containsKey(usr.Id__c)) {
				for (ZP_User_Role__c objRole : map_zpUserIdZpUserRoles.get(usr.Id__c)) {
					objRole.Processing_State__c = IntegrationUtils.QUEUED_STATE;
					map_RolesToReProcess.put(objRole.Id, objRole);
				}
			}

			if (usr.Processing_State__c == null || usr.Processing_State__c == 'Queued') {
				setProcessingState(ERROR_STATE, 'Email did not match with lead or contact', usr);
			}
		}

		if (list_exeptionLogs.size() > 0) {
			insert list_exeptionLogs;
		}

		if (!map_RolesToReProcess.isEmpty()) {
			ZPUserRoleTriggerHelper.skipTrigger = true;
			update map_RolesToReProcess.values();
			ZPUserRoleTriggerHelper.skipTrigger = false;
		}
	}

	/**
	 * @Description : Query ZP Users by Email
	 * @Parm        : set_Emails - Set of emails
	 * @Return      : List of queried ZP Users
	 **/
	public List<ZP_User__c> queryZPUsersByEmail(Set<String> set_Emails) {
		return [SELECT Id, Email__c, Id__c, Previous_Email__c FROM ZP_User__c WHERE Email__c IN :set_Emails ORDER BY CreatedDate DESC];
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Update Last Login Date on Account & Lead
	 * @Parm        : list_NewUsers - List of ZP Users
	 * @Return      : void
	 **/
	public void processLastSignIn(List<ZP_User__c> list_NewUsers) {
		Set<String> set_Roles = new Set<String>{ PAYROLL_ADMIN, PRIMARY_PAYROLL_ADMIN, ACCOUNTANT };

		Map<Id, Lead> map_LeadsToUpdate = new Map<Id, Lead>();
		Map<String, ZP_User__c> map_UserEmails = new Map<String, ZP_User__c>();
		Map<String, ZP_User__c> map_ZPUsers = new Map<String, ZP_User__c>();
		Map<String, Set<String>> map_FirmUsers = new Map<String, Set<String>>();
		Map<String, Set<String>> map_CompanyUsers = new Map<String, Set<String>>();
		Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();

		// Iterate over all user and extract user Ids
		for (ZP_User__c objUser : list_NewUsers) {
			if (String.isNotBlank(objUser.Id__c)) {
				map_ZPUsers.put(objUser.Id__c, objUser);
			}

			if (String.isNotBlank(objUser.Email__c)) {
				map_UserEmails.put(objUser.Email__c, objUser);
			}
		}

		// query only payroll admins & accountant roles related to user ids
		for (ZP_User_Role__c objRole : [
			SELECT Id, Accounting_Firm_Id__c, Company_Id__c, Type__c, User_Id__c, Role_Name__c, Processing_State__c
			FROM ZP_User_Role__c
			WHERE User_Id__c IN :map_ZPUsers.keySet() AND Role_Name__c != :ZPUserRoleUtil.INTERNATIONAL_CONTRACTOR AND Role_Name__c IN :set_Roles
		]) {
			if (String.isNotBlank(objRole.Accounting_Firm_Id__c) && objRole.Role_Name__c == ACCOUNTANT) {
				if (!map_FirmUsers.containsKey(objRole.Accounting_Firm_Id__c)) {
					map_FirmUsers.put(objRole.Accounting_Firm_Id__c, new Set<String>{ objRole.User_Id__c });
				} else {
					map_FirmUsers.get(objRole.Accounting_Firm_Id__c).add(objRole.User_Id__c);
				}
			}
			if (String.isNotBlank(objRole.Company_Id__c) && (objRole.Role_Name__c == PAYROLL_ADMIN || objRole.Role_Name__c == PRIMARY_PAYROLL_ADMIN)) {
				if (!map_CompanyUsers.containsKey(objRole.Company_Id__c)) {
					map_CompanyUsers.put(objRole.Company_Id__c, new Set<String>{ objRole.User_Id__c });
				} else {
					map_CompanyUsers.get(objRole.Company_Id__c).add(objRole.User_Id__c);
				}
			}
		}

		List<Account> listAccounts = [
			SELECT Id, ZP_Company_ID__c, ZP_Firm_ID__c, Last_Login_Details__c, Last_Login_Time__c
			FROM Account
			WHERE ZP_Company_ID__c IN :map_CompanyUsers.KeySet() OR ZP_Firm_ID__c IN :map_FirmUsers.KeySet()
		];

		for (Account objAcc : listAccounts) {
			// update last sign in information on reseller account
			if (objAcc != null && String.isNotBlank(objAcc.ZP_Firm_ID__c) && map_FirmUsers.containsKey(objAcc.ZP_Firm_ID__c)) {
				// get list of all accountant user ids for the firm
				for (String strUserId : map_FirmUsers.get(objAcc.ZP_Firm_ID__c)) {
					// set last login in info on reseller account
					if (objAcc.Last_Login_Time__c == null && map_ZPUsers.containsKey(strUserId)) {
						objAcc = updateAccountLastLogin(objAcc, map_ZPUsers, strUserId);
						if (objAcc != null) {
							map_AccountsToUpdate.put(objAcc.Id, objAcc);
						}
					} else {
						// set last login in info ONLY when account last login in is less than user last sign in
						if (map_ZPUsers.containsKey(strUserId) && objAcc.Last_Login_Time__c < map_ZPUsers.get(strUserId).Last_Sign_In_At__c) {
							objAcc = updateAccountLastLogin(objAcc, map_ZPUsers, strUserId);
							if (objAcc != null) {
								map_AccountsToUpdate.put(objAcc.Id, objAcc);
							}
						}
					}
				}
			}

			// update last sign in information on company account
			if (objAcc != null && String.isNotBlank(objAcc.ZP_Company_ID__c) && map_CompanyUsers.containsKey(objAcc.ZP_Company_ID__c)) {
				// get all payroll admin user ids for company account
				for (String strUserId : map_CompanyUsers.get(objAcc.ZP_Company_ID__c)) {
					// set last login in info on company account
					if (objAcc.Last_Login_Time__c == null) {
						if (map_ZPUsers.containsKey(strUserId)) {
							objAcc = updateAccountLastLogin(objAcc, map_ZPUsers, strUserId);
							if (objAcc != null) {
								map_AccountsToUpdate.put(objAcc.Id, objAcc);
							}
						}
					} else {
						if (map_ZPUsers.containsKey(strUserId)) {
							// set last login in info ONLY when account last login in is less than user last sign in
							if (objAcc.Last_Login_Time__c < map_ZPUsers.get(strUserId).Last_Sign_In_At__c) {
								objAcc = updateAccountLastLogin(objAcc, map_ZPUsers, strUserId);

								if (objAcc != null) {
									map_AccountsToUpdate.put(objAcc.Id, objAcc);
								}
							}
						}
					}
				}
			}
		}
		// update company and reseller accounts and skip trigger
		if (map_AccountsToUpdate.size() > 0) {
			List<Exception_Log__c> list_exeptionLogs = new List<Exception_Log__c>();
			AccountTriggerHelper.skiptrigger = true;
			List<Database.SaveResult> resultList = Database.update(map_AccountsToUpdate.values(), false);
			for (Integer i = 0; i < resultList.size(); i++) {
				Database.SaveResult result = resultList[i];
				if (!result.isSuccess()) {
					String error = '';
					for (Database.Error objErr : result.getErrors()) {
						error = objErr.getStatusCode() + ': ' + objErr.getMessage();
						String message = objErr.getMessage();
						message = message.length() > 255 ? message.substring(0, 254) : message;
						Exception_Log__c log = new Exception_Log__c(Type__c = 'Error', Class_Name__c = 'ZPUserTriggerHelper', Method_Name__c = 'processLastSignIn', Message__c = message);
						list_exeptionLogs.add(log);
					}
				}
			}
			if (list_exeptionLogs.size() > 0) {
				insert list_exeptionLogs;
			}
		}

		// query unconverted leads and update last login date time
		for (Lead objLead : [SELECT Id, Email, Last_Login_Date_Time__c FROM Lead WHERE Email IN :map_UserEmails.keySet() AND IsConverted = FALSE]) {
			if (map_UserEmails.containsKey(objLead.Email)) {
				ZP_User__c objUser = map_UserEmails.get(objLead.Email);

				DateTime dtmLastSignIn = objUser.Last_Sign_In_At__c;

				if (objUser.Last_Sign_In_At__c != null && objUser.Current_Sign_In_At__c != null && objUser.Current_Sign_In_At__c > objUser.Last_Sign_In_At__c) {
					dtmLastSignIn = objUser.Current_Sign_In_At__c;
				}

				if (objLead.Last_Login_Date_Time__c != dtmLastSignIn) {
					objLead.Last_Login_Date_Time__c = objUser.Last_Sign_In_At__c;
					map_LeadsToUpdate.put(objLead.Id, objLead);
				}
			}
		}

		// update last login date/time on unconverted lead
		if (!map_LeadsToUpdate.isEmpty()) {
			LeadTriggerHelper.skipTrigger = true;
			Database.update(map_LeadsToUpdate.values(), false);
		}

		for (ZP_User__c objUser : list_NewUsers) {
			objUser.Sign_In_Changed__c = false;
			objUser.Is_Changed__c = false;
		}
	}

	public ZP_User__c setProcessingState(String state, String message, ZP_User__c user) {
		user.Processing_State__c = state;
		user.Message__c = message;
		user.Last_Processed__c = System.now();
		return user;
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Filters list of ZP Users and removes Fraudulent records
	 * @Parm        : List<ZP_User__c> - Unfiltered List
	 * @Return      : List<ZP_User__c> - Filtered List
	 **/
	public List<ZP_User__c> returnRecordsToProcess(List<ZP_User__c> list_Users) {
		// List to contain filtered list of ZP Users to Process
		List<ZP_User__c> list_UsersToProcess = new List<ZP_User__c>();
		Set<String> set_FraudEmails = new Set<String>();

		// Fetch all fraudulent email domains from custom metadata
		Map<String, Fraud_Settings__mdt> map_FraudSettings = Fraud_Settings__mdt.getAll();
		for (String strKey : map_FraudSettings.keySet()) {
			String strEmailDomain = map_FraudSettings.get(strKey).Email_Domain__c;
			if (String.isNotBlank(strEmailDomain)) {
				set_FraudEmails.add(strEmailDomain);
			}
		}

		for (ZP_User__c objUser : list_Users) {
			if (objUser.Processing_State__c != IntegrationUtils.DEAD_STATE) {
				objUser.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}

			// Logic to remove fraudulent records and mark them as Dead
			for (String strFraudEmail : set_FraudEmails) {
				if (String.isNotBlank(objUser.Email__c) && objUser.Email__c.containsIgnoreCase(strFraudEmail)) {
					objUser.Processing_State__c = IntegrationUtils.DEAD_STATE;
					objUser.Message__c = 'Fraudulent record';
				}
			}
		}

		// Add any record whose processing state is not Dead to list of ZP Users to Process
		for (ZP_User__c objUser : list_Users) {
			if (objUser.Processing_State__c != IntegrationUtils.DEAD_STATE) {
				list_UsersToProcess.add(objUser);
			}
		}

		// Return filtered list of records to process
		return list_UsersToProcess;
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Returns a map of referral token and list of users
	 * @Parm        : Set of Referral Tokens
	 * @Return      : Map of Referral Token and Users
	 **/
	public Map<String, List<ZP_User__c>> queryUsersByToken(Set<String> set_RefTokens) {
		Map<String, List<ZP_User__c>> map_RefTokenToUsers = new Map<String, List<ZP_User__c>>();

		// Query all users having same referral token and order them in ascending order of their created date
		for (ZP_User__c objUser : [SELECT Id, Referral_Token__c, Contact__c FROM ZP_User__c WHERE Referral_Token__c IN :set_RefTokens]) {
			if (map_RefTokenToUsers.containsKey(objUser.Referral_Token__c)) {
				map_RefTokenToUsers.get(objUser.Referral_Token__c).add(objUser);
			} else {
				map_RefTokenToUsers.put(objUser.Referral_Token__c, new List<ZP_User__c>{ objUser });
			}
		}

		return map_RefTokenToUsers;
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Updates last login info from Account
	 * @Parm        : Account - account record to update
	 * @Parm        : map_LoginZPUsers - map of zp users
	 * @Parm        : strUserId - user id
	 * @Return      : returns account record with latest login info
	 **/
	public Account updateAccountLastLogin(Account objAcc, Map<String, ZP_User__c> map_LoginZPUsers, String strUserId) {
		Boolean blnAccUpdate = false;
		if (map_LoginZPUsers.containsKey(strUserId)) {
			String strLastLoginDetails = map_LoginZPUsers.get(strUserId).Email__c;
			DateTime dtmLastLoginTime = map_LoginZPUsers.get(strUserId).Last_Sign_In_At__c;

			if (
				map_LoginZPUsers.get(strUserId).Last_Sign_In_At__c != null &&
				map_LoginZPUsers.get(strUserId).Current_Sign_In_At__c != null &&
				map_LoginZPUsers.get(strUserId).Current_Sign_In_At__c > map_LoginZPUsers.get(strUserId).Last_Sign_In_At__c
			) {
				dtmLastLoginTime = map_LoginZPUsers.get(strUserId).Current_Sign_In_At__c;
			}

			// Update Account only if details do not match on Account
			if (objAcc.Last_Login_Details__c != strLastLoginDetails || objAcc.Last_Login_Time__c != dtmLastLoginTime) {
				objAcc.Last_Login_Details__c = strLastLoginDetails;
				objAcc.Last_Login_Time__c = dtmLastLoginTime;
				blnAccUpdate = true;
			}
		}

		if (blnAccUpdate) {
			return objAcc;
		} else {
			return null;
		}
	}
}