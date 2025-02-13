/*
 * @name         BulkUserCSVDataTriggerHelper
 * @author       Gaurav Khare
 * @date         4/23/2019
 * @description  Creates or updates users in bulk
 * @test classes BulkUserUploadControllerTest
 */
public class BulkUserCSVDataTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Integer counter = 0;
	public static Boolean queue = false;

	// To keep all intermediate errors
	Map<String, String> dmlAllErrorsMap = new Map<String, String>();

	// Map Email (from CSV) to HR Worker Info object
	Map<String, HR_Worker_Information__c> mapEmailToHRWorkerInfo = new Map<String, HR_Worker_Information__c>();
	// Map Clone_from_User (from CSV) to HR Worker Info object
	Map<String, HR_Worker_Information__c> mapCloneEmailToHRWorkerInfo = new Map<String, HR_Worker_Information__c>();

	// Map Team (Team + Subteam from CSV) to HR Worker Info object
	Map<String, HR_Worker_Information__c> mapTeamsToHrWorkerInfo = new Map<String, HR_Worker_Information__c>();
	// Map email that we get from Team (Team + SubTeam => HR WorkerInfo => Email) and Email (from csv in case of Upadte user)
	Map<String, User> mapEmailToSFUser = new Map<String, User>();

	// Set of Email (from csv)
	Set<String> setHRWorkerEmail = new Set<String>();
	// Set of Email of manager (from latest person in teams)
	Set<String> setHRWorkerManagerEmail = new Set<String>();

	Map<Id, List<Id>> mapUserIdToListPermSetId = new Map<Id, List<Id>>();
	Map<Id, List<Id>> mapUserIdToListGroupId = new Map<Id, List<Id>>();

	Map<Id, List<PermissionSetAssignment>> userIdToListPermSetAssignmentMap = new Map<Id, List<PermissionSetAssignment>>();
	Map<Id, List<GroupMember>> userIdToListGrpMemberMap = new Map<Id, List<GroupMember>>();
	List<User> listUsersToUpdatePermSet = new List<User>();
	Set<Id> setOfUpdatedUserIds = new Set<Id>();
	public static Set<Id> recIds = new Set<Id>();

	public void OnBeforeInsert(List<Bulk_User_CSV_Data__c> recList) {
		counter++;
		if (!queue) {
			for (Bulk_User_CSV_Data__c rec : recList) {
				rec.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, Bulk_User_CSV_Data__c> newMap) {
		if (queue == false) {
			for (Bulk_User_CSV_Data__c rec : newMap.values()) {
				recIds.add(rec.id);
			}
			BulkUserCSVDataTriggerQueue processRec = new BulkUserCSVDataTriggerQueue(recIds, null, 'ProcessRecords');
			ID jobID = System.enqueueJob(processRec);
		}
	}

	// Create new User / Update existing User based on "Create New User" flag
	// Update processing status Async to avoid Setup and Non Setup dml operation at same time error
	public void processInformation(Set<Id> bulkRecIdsSet) {
		List<Bulk_User_CSV_Data__c> listBulkData = [
			SELECT Id, Email__c, Team__c, Sub_Team__c, Create_New_User__c, Processing_State__c, Last_Processed__c, Message__c, Clone_From_User__c
			FROM Bulk_User_CSV_Data__c
			WHERE Id IN :bulkRecIdsSet
		];

		Map<Id, Bulk_User_CSV_Data__c> mapCreateUser = new Map<Id, Bulk_User_CSV_Data__c>();
		Map<Id, Bulk_User_CSV_Data__c> mapUpdateUser = new Map<Id, Bulk_User_CSV_Data__c>();

		Set<String> setUserEmailId = new Set<String>(); // Used in User Update , This would exist in both table but we are interested in SF User table
		Set<String> setHRWorkerEmailId = new Set<String>(); // Used in User Creation, This would exist in HR table
		Set<String> setTeams = new Set<String>();
		Set<String> setSubTeams = new Set<String>();
		Set<String> setCloneFromUserEmail = new Set<String>();

		for (Bulk_User_CSV_Data__c objCsvObj : listBulkData) {
			if (objCsvObj.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (objCsvObj.Processing_State__c != IntegrationUtils.QUEUED_STATE) {
				objCsvObj.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
			if (objCsvObj.Create_New_User__c) {
				mapCreateUser.put(objCsvObj.Id, objCsvObj);
				setHRWorkerEmailId.add(objCsvObj.Email__c);
			} else {
				mapUpdateUser.put(objCsvObj.Id, objCsvObj);
				setUserEmailId.add(objCsvObj.Email__c);
			}
			// To update user having this email Id
			// Get Clone from User
			// Now If Clone_From_User is supplied then we wont go for team-SubTeam combination approach
			// to get latest clone user, rather we directly use
			if (objCsvObj.Clone_From_User__c != null) {
				setCloneFromUserEmail.add(objCsvObj.Clone_From_User__c);
			}

			if (String.isNotBlank(objCsvObj.Team__c)) {
				setTeams.add(objCsvObj.Team__c);
			}
			if (String.isNotBlank(objCsvObj.Sub_Team__c)) {
				setSubTeams.add(objCsvObj.Sub_Team__c);
			}
		}

		// Get the HR Info of the user to be created in SF (based on Email Provided in CSV)
		mapEmailToHRWorkerInfo = fetchHRWorkerInfoByEmail(setHRWorkerEmailId); // search HR Info
		// Get the HR Info of the user to be Cloned from (based on Clone_From_User__c Provided in CSV)
		mapCloneEmailToHRWorkerInfo = fetchHRWorkerInfoByEmail(setCloneFromUserEmail); // search HR Info
		// Get the HR Info of the user (created latest 15 days back) (based on Teams Provided in CSV)
		// This user will be used as Cloned By User in Both Create User and Update User
		mapTeamsToHrWorkerInfo = fetchHRWorkerInforByTeams(setTeams, setSubTeams);
		// Now based on above email from HR Info, And also Email (from CSV) for update Users get the SF User Info
		Set<String> setAllEmail = new Set<String>();
		// This maild Id will come from HR WorkerInfo tables based on teams (i.e recently created user before 15 days)
		if (setHRWorkerEmail.size() > 0) {
			setAllEmail.addAll(setHRWorkerEmail);
		}
		// This manager maild Id will come from HR WorkerInfo tables based on teams (i.e recently created user before 15 days)
		if (setHRWorkerManagerEmail.size() > 0) {
			setAllEmail.addAll(setHRWorkerManagerEmail);
		}
		// This maild Id as recieved from csv (Email) in update user case.
		if (setUserEmailId.size() > 0) {
			setAllEmail.addAll(setUserEmailId);
		}
		// Get the SF User Info for those records where Clone_From_User is supplied
		if (setCloneFromUserEmail.size() > 0) {
			setAllEmail.addAll(setCloneFromUserEmail);
		}
		// Get the SF User details from above emails
		if (setAllEmail.size() > 0) {
			mapEmailToSFUser = fetchSFUserByEmail(setAllEmail);
		}
		// Clone From User + Update user's permisionSets
		mapUserIdToListPermSetId = fetchPermSetByUser(mapEmailToSFUser.values());
		// Clone From User + Update user's Groups/Queues
		mapUserIdToListGroupId = fetchGroupsByUser(mapEmailToSFUser.values());

		if (mapCreateUser.size() > 0) {
			createNewUser(mapCreateUser);
		}
		if (mapUpdateUser.size() > 0) {
			updateUser(mapUpdateUser);
		}

		// Update permission set, All user records succesfully created/Update will contain bulkUserCSVData Id
		assignPermissionSet(bulkRecIdsSet);

		assignGroupQueues(bulkRecIdsSet);

		BulkUserCSVDataTriggerQueue updateSts = new BulkUserCSVDataTriggerQueue(bulkRecIdsSet, dmlAllErrorsMap, 'UpdateStatus');
		if (!Test.isRunningTest()) {
			// To avoid Max stack depth error from test class
			ID jobID = System.enqueueJob(updateSts);
		}
	}

	// Create new User with help of first name & last name
	// Fetch personal details from HR WORKER INFORMATION based on first name & last name
	// (fetch latest user based on created date)
	// Fetch permission related Info from USER with help of CloneFromUser email
	public void createNewUser(map<Id, Bulk_User_CSV_Data__c> createUserMap) {
		User objUser;
		List<User> listUsersToInsert = new List<User>();
		for (Bulk_User_CSV_Data__c csvRecord : createUserMap.values()) {
			if (mapEmailToHRWorkerInfo == null || !mapEmailToHRWorkerInfo.containsKey(csvRecord.Email__c)) {
				dmlAllErrorsMap.put(csvRecord.id, 'No matching user found based on email in HRWorkerInfo ' + csvRecord.Email__c);
				continue; // goto next record
			}
			// If Clone_From_User__c is supplied check if relavent user is found in User table based on Clone_From_User__c
			if (csvRecord.Clone_From_User__c != null) {
				if (mapEmailToSFUser == null || !mapEmailToSFUser.containsKey(csvRecord.Clone_From_User__c)) {
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in User table based Clone_From_User__c ' + csvRecord.Clone_From_User__c);
					continue; // goto next record
				}
			} else {
				// Check if the any person was found based on Team subTeam. This person would be used for Clone from user.
				if (mapTeamsToHrWorkerInfo == null || !mapTeamsToHrWorkerInfo.containsKey(csvRecord.Team__c + '-' + csvRecord.Sub_Team__c)) {
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in HR Worker Info based on Teams  ' + csvRecord.Team__c + ', ' + csvRecord.Sub_Team__c);
					continue; // goto next record
				}
			}
			// Check if above person (Clone from) has a record in SF User table
			// Email to serach in User table (as obtained from HR Worker table based on Team + Sub Team)
			HR_Worker_Information__c objHRWorkerInfoForClone;
			if (csvRecord.Clone_From_User__c != null) {
				objHRWorkerInfoForClone = mapCloneEmailToHRWorkerInfo.get(csvRecord.Clone_From_User__c);
			} else {
				objHRWorkerInfoForClone = mapTeamsToHrWorkerInfo.get(csvRecord.Team__c + '-' + csvRecord.Sub_Team__c);
			}
			if (objHRWorkerInfoForClone == null) {
				if (csvRecord.Clone_From_User__c != null) {
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in HRWorkerInfo table based Clone_From_User__c ' + csvRecord.Clone_From_User__c);
				} else {
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in HRWorkerInfo table based Team subteam ' + csvRecord.Team__c + '-' + csvRecord.Sub_Team__c);
				}
				continue; // goto next record
			}
			String emailId = objHRWorkerInfoForClone.Email__c;
			if (mapEmailToSFUser == null || !mapEmailToSFUser.containsKey(emailId)) {
				dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in User table based on Teams  ' + csvRecord.Team__c + ', ' + csvRecord.Sub_Team__c + ' Or Email ' + emailId);
				continue; // goto next record
			}

			objUser = new User();
			// This HR Worker we feteched from Email in CSV (to create user) to fetch other details like name etc
			HR_Worker_Information__c objHRWorkerInfo = mapEmailToHRWorkerInfo.get(csvRecord.Email__c);
			// We could get this directly in case of clone from User but this would be generic
			User clonedFromUser = mapEmailToSFUser.get(objHRWorkerInfoForClone.Email__c);
			User objManager = mapEmailToSFUser.get(objHRWorkerInfoForClone.Manager_Email__c);
			String alias = String.ValueOf(objHRWorkerInfo.First_Name__c).substring(0, 1);

			if (objHRWorkerInfo.Last_Name__c.length() > 4) {
				alias += String.ValueOf(objHRWorkerInfo.Last_Name__c).substring(0, 4);
			} else {
				alias += String.ValueOf(objHRWorkerInfo.Last_Name__c);
			}

			objUser.FirstName = objHRWorkerInfo.First_Name__c;
			objUser.LastName = objHRWorkerInfo.Last_Name__c;
			objUser.Email = objHRWorkerInfo.Email__c;
			objUser.EmployeeNumber = objHRWorkerInfo.Employee_id__c;
			objUser.Team__c = objHRWorkerInfoForClone.Team__c;
			objUser.Sub_Team__c = objHRWorkerInfoForClone.Sub_Team__c;
			objUser.Username = objHRWorkerInfo.Email__c;
			objUser.Alias = alias;
			objUser.Department = objHRWorkerInfo.Departnment__c;
			objUser.isActive = true;
			objUser.ProfileId = clonedFromUser.ProfileId;
			objUser.UserRoleId = clonedFromUser.UserRoleId;
			objUser.UserPermissionsSupportUser = clonedFromUser.UserPermissionsSupportUser;
			objUser.UserPreferencesContentNoEmail = clonedFromUser.UserPreferencesContentNoEmail;
			objUser.UserPreferencesContentEmailAsAndWhen = clonedFromUser.UserPreferencesContentEmailAsAndWhen;
			objUser.CallCenterId = clonedFromUser.CallCenterId;
			objUser.UserPermissionsMarketingUser = clonedFromUser.UserPermissionsMarketingUser;
			objUser.TimeZoneSidKey = clonedFromUser.TimeZoneSidKey;
			objUser.LanguageLocaleKey = clonedFromUser.LanguageLocaleKey;
			objUser.EmailEncodingKey = clonedFromUser.EmailEncodingKey;
			objUser.LocaleSidKey = clonedFromUser.LocaleSidKey;
			objUser.BulkUserCSVDataId__c = csvRecord.Id; // BulkUserCSVData Id
			objUser.ManagerId = (objManager != null ? objManager.Id : null);
			if (mapUserIdToListPermSetId.containsKey(clonedFromUser.Id)) {
				List<Id> listPermSetIds = mapUserIdToListPermSetId.get(clonedFromUser.Id);
				if (listPermSetIds != null && listPermSetIds.size() > 0) {
					objUser.PermissionSetIds__c = string.join(listPermSetIds, ',');
				}
			}
			if (mapUserIdToListGroupId.containsKey(clonedFromUser.Id)) {
				List<Id> listGroupIds = mapUserIdToListGroupId.get(clonedFromUser.Id);
				if (listGroupIds != null && listGroupIds.size() > 0) {
					objUser.GroupIds__c = string.join(listGroupIds, ',');
				}
			}
			objUser.cloned_From_User__c = clonedFromUser.Name + ' (' + clonedFromUser.Email + ')' + ' (Id: ' + clonedFromUser.Id + ')';
			listUsersToInsert.add(objUser);
		}

		// Insert Users: We could have used Upsert but DMLOptions cannot be used as a parameter with
		// Databse.upsert
		// DMLOptions is required as we dont want to send email
		Map<String, String> dmlInsertErrorsMap = new Map<String, String>();
		if (listUsersToInsert.size() > 0) {
			Database.DMLOptions dmlo = new Database.DMLOptions();
			dmlo.EmailHeader.triggerUserEmail = false;
			List<Database.SaveResult> saveResult = database.insert(listUsersToInsert, dmlo);
			dmlInsertErrorsMap = Utils.processSaveResult(saveResult, listUsersToInsert, 'BulkUserCSVDataId__c', false, 'BulkUserCSVDataTriggerHelper-createNewUser');
		}
		dmlAllErrorsMap.putAll(dmlInsertErrorsMap);
	}

	// Update existing User (based on Email field fetch USER details)
	// with another user (based on CloneFromUser email fetch USER details)
	public void updateUser(map<Id, Bulk_User_CSV_Data__c> updateUserMap) {
		User objUser;
		User clonedFromUser;
		List<User> listUsersToUpdate = new List<User>();
		for (Bulk_User_CSV_Data__c csvRecord : updateUserMap.values()) {
			// If Clone_From_User__c is supplied check if relavent user is found in User table based on Clone_From_User__c
			if (csvRecord.Clone_From_User__c != null) {
				if (mapEmailToSFUser == null || !mapEmailToSFUser.containsKey(csvRecord.Clone_From_User__c)) {
					// setProcessingState(IntegrationUtils.ERROR_STATE, 'No matching record found in User table based on Teams  ' + csvRecord.Team__c + ', ' +csvRecord.Sub_Team__c + ' Or Email ' + emailId,csvRecord);
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in User table based Clone_From_User__c ' + csvRecord.Clone_From_User__c);
					continue; // goto next record
				}
			} else {
				// Check if the any person was found based on Team subTeam. This person would be used for Clone from user.
				if (mapTeamsToHrWorkerInfo == null || !mapTeamsToHrWorkerInfo.containsKey(csvRecord.Team__c + '-' + csvRecord.Sub_Team__c)) {
					// setProcessingState(IntegrationUtils.ERROR_STATE, 'No matching record found in HR Worker Info based on Teams  ' + csvRecord.Team__c + ', ' +csvRecord.Sub_Team__c ,csvRecord);
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in HR Worker Info based on Teams  ' + csvRecord.Team__c + ', ' + csvRecord.Sub_Team__c);
					continue; // goto next record
				}
			}
			// Check if above person (Clone from) has a record in SF User table
			// Email to serach in User table (as obtained from HR Worker table based on Team + Sub Team)
			HR_Worker_Information__c objHRWorkerInfoForClone;
			if (csvRecord.Clone_From_User__c != null) {
				objHRWorkerInfoForClone = mapCloneEmailToHRWorkerInfo.get(csvRecord.Clone_From_User__c);
			} else {
				objHRWorkerInfoForClone = mapTeamsToHrWorkerInfo.get(csvRecord.Team__c + '-' + csvRecord.Sub_Team__c);
			}
			if (objHRWorkerInfoForClone == null) {
				if (csvRecord.Clone_From_User__c != null) {
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in HRWorkerInfo table based Clone_From_User__c ' + csvRecord.Clone_From_User__c);
				} else {
					dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in HRWorkerInfo table based Team subteam ' + csvRecord.Team__c + '-' + csvRecord.Sub_Team__c);
				}
				continue; // goto next record
			}
			String emailId = objHRWorkerInfoForClone.Email__c;
			if (mapEmailToSFUser == null || !mapEmailToSFUser.containsKey(emailId)) {
				//  setProcessingState(IntegrationUtils.ERROR_STATE, 'No matching record found in User table based on Teams  ' + csvRecord.Team__c + ', ' +csvRecord.Sub_Team__c + ' Or Email ' + emailId,csvRecord);
				dmlAllErrorsMap.put(csvRecord.id, 'No matching record found in User table based on Teams  ' + csvRecord.Team__c + ', ' + csvRecord.Sub_Team__c + ' Or Email ' + emailId);
				continue; // goto next record
			}

			objUser = mapEmailToSFUser.get(csvRecord.Email__c);

			clonedFromUser = mapEmailToSFUser.get(objHRWorkerInfoForClone.Email__c);
			User objManager = mapEmailToSFUser.get(objHRWorkerInfoForClone.Manager_Email__c);

			objUser.Department = clonedFromUser.Department;
			objUser.Title = clonedFromUser.Title;
			objUser.ProfileId = clonedFromUser.ProfileId;
			objUser.UserRoleId = clonedFromUser.UserRoleId;
			objUser.ProfileId = clonedFromUser.ProfileId;
			objUser.UserRoleId = clonedFromUser.UserRoleId;
			objUser.ManagerId = (objManager != null ? objManager.Id : null);
			objUser.Team__c = objHRWorkerInfoForClone.Team__c;
			objUser.Sub_Team__c = objHRWorkerInfoForClone.Sub_Team__c;
			objUser.UserPermissionsSupportUser = clonedFromUser.UserPermissionsSupportUser;
			objUser.UserPreferencesContentNoEmail = clonedFromUser.UserPreferencesContentNoEmail;
			objUser.UserPreferencesContentEmailAsAndWhen = clonedFromUser.UserPreferencesContentEmailAsAndWhen;
			objUser.BulkUserCSVDataId__c = csvRecord.Id; // BulkUserCSVData Id
			if (mapUserIdToListPermSetId.containsKey(clonedFromUser.Id)) {
				List<Id> listPermSetIds = mapUserIdToListPermSetId.get(clonedFromUser.Id);
				if (listPermSetIds != null && listPermSetIds.size() > 0) {
					objUser.PermissionSetIds__c = string.join(listPermSetIds, ',');
				}
			}
			if (mapUserIdToListGroupId.containsKey(clonedFromUser.Id)) {
				List<Id> listGroupIds = mapUserIdToListGroupId.get(clonedFromUser.Id);
				if (listGroupIds != null && listGroupIds.size() > 0) {
					objUser.GroupIds__c = string.join(listGroupIds, ',');
				}
			}
			objUser.cloned_From_User__c = clonedFromUser.Name + ' (' + clonedFromUser.Email + ')' + ' (Id: ' + clonedFromUser.Id + ')';
			setOfUpdatedUserIds.add(objUser.Id);
			listUsersToUpdate.add(objUser);
		}
		// Update Users: We could have used Upsert but DMLOptions cannot be used as a parameter with Databse.upsert
		// DMLOptions is required as we dont want to send email
		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
		if (listUsersToUpdate.size() > 0) {
			Database.DMLOptions dmlo = new Database.DMLOptions();
			dmlo.EmailHeader.triggerUserEmail = false;
			List<Database.SaveResult> saveResult = database.update(listUsersToUpdate, dmlo);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, listUsersToUpdate, 'BulkUserCSVDataId__c', false, 'BulkUserCSVDataTriggerHelper-updateUser');
		}
		dmlAllErrorsMap.putAll(dmlUpdateErrorsMap);
	}

	// Delete existing users permission set and insert all permission set for new and existing user
	public void assignPermissionSet(Set<Id> bulkRecIdsSet) {
		List<PermissionSetAssignment> listPermSetAssignToInsert = new List<PermissionSetAssignment>();
		List<PermissionSetAssignment> listPermSetAssignToDelete = new List<PermissionSetAssignment>();
		Set<Id> existingPermSetIds = new Set<Id>();
		Set<Id> toCopyPermSetIds = new Set<Id>();

		PermissionSetAssignment objPermSetAssignment;
		List<User> listUsers = [SELECT Id, PermissionSetIds__c FROM User WHERE BulkUserCSVDataId__c IN :bulkRecIdsSet];

		for (User objUser : listUsers) {
			if (objUser.PermissionSetIds__c != null) {
				List<String> permSetIdList = objUser.PermissionSetIds__c.split(',');
				for (Id permSetId : permSetIdList) {
					toCopyPermSetIds.add(permSetId);
				}
			}
			// Create a List to delete extra Permset Ids which are not present in toCopyPermSetIds
			if (setOfUpdatedUserIds.contains(objUser.Id)) {
				// Updated User
				if (userIdToListPermSetAssignmentMap.containsKey(objUser.Id)) {
					// and if it has any existing permission set
					//listPermSetAssignToDelete.addAll(userIdToListPermSetAssignmentMap.get(objUser.Id));
					for (PermissionSetAssignment permset : userIdToListPermSetAssignmentMap.get(objUser.Id)) {
						if (!toCopyPermSetIds.contains(permset.PermissionSetId)) {
							listPermSetAssignToDelete.add(permset);
						}
						existingPermSetIds.add(permset.PermissionSetId);
					}
				}
			}
			// Insert only new permission set Ids which are not already present
			if (objUser.PermissionSetIds__c != null) {
				List<String> permSetIdList = objUser.PermissionSetIds__c.split(',');
				for (Id permSetId : permSetIdList) {
					if (!existingPermSetIds.contains(permSetId)) {
						objPermSetAssignment = new PermissionSetAssignment();
						objPermSetAssignment.AssigneeId = objUser.Id;
						objPermSetAssignment.PermissionSetId = permSetId;
						listPermSetAssignToInsert.add(objPermSetAssignment);
					}
				}
			}
		}
		if (listPermSetAssignToDelete.size() > 0) {
			if (!Test.isRunningTest()) {
				Database.delete(listPermSetAssignToDelete, false);
			}
		}
		if (listPermSetAssignToInsert.size() > 0) {
			if (!Test.isRunningTest()) {
				Database.insert(listPermSetAssignToInsert, false);
			}
		}
	}

	// Delete existing groupsmembers set and insert all group members for new and existing user
	public void assignGroupQueues(Set<Id> bulkRecIdsSet) {
		List<GroupMember> listGroupQueueToInsert = new List<GroupMember>();
		List<GroupMember> listGroupQueueToDelete = new List<GroupMember>();
		Set<Id> existingGroupIds = new Set<Id>();
		Set<Id> toCopyGroupIds = new Set<Id>();
		GroupMember member;
		List<User> listUsers = [SELECT Id, GroupIds__c FROM User WHERE BulkUserCSVDataId__c IN :bulkRecIdsSet];

		for (User objUser : listUsers) {
			if (objUser.GroupIds__c != null) {
				List<String> groupIdsList = objUser.GroupIds__c.split(',');
				for (Id groupId : groupIdsList) {
					toCopyGroupIds.add(groupId);
				}
			}
			// Create a List to delete extra Groups which are not present in toCopyGroupIds
			if (setOfUpdatedUserIds.contains(objUser.Id)) {
				// Updated User
				if (userIdToListGrpMemberMap.containsKey(objUser.Id)) {
					// and if it has any existing group/Queues assigned
					for (GroupMember grpmember : userIdToListGrpMemberMap.get(objUser.Id)) {
						if (!toCopyGroupIds.contains(grpmember.GroupId)) {
							listGroupQueueToDelete.add(grpmember);
						}
						existingGroupIds.add(grpmember.GroupId);
					}
				}
			}
			if (objUser.GroupIds__c != null) {
				List<String> groupIdsList = objUser.GroupIds__c.split(',');
				for (Id groupId : groupIdsList) {
					if (!existingGroupIds.contains(groupId)) {
						member = new GroupMember();
						member.UserOrGroupId = objUser.Id;
						member.GroupId = groupId;
						listGroupQueueToInsert.add(member);
					}
				}
			}
		}
		if (listGroupQueueToDelete.size() > 0) {
			Database.delete(listGroupQueueToDelete, false);
		}
		if (listGroupQueueToInsert.size() > 0) {
			Database.insert(listGroupQueueToInsert, false);
		}
	}
	// Fetch HR Worker Info by Email brovided in CSV (Email for user to be created)
	public map<String, HR_Worker_Information__c> fetchHRWorkerInfoByEmail(Set<String> emailIdSet) {
		// Retrieve limited information where combinations contain fisrt and last names
		Map<String, HR_Worker_Information__c> emailToHrWorkerInfo = new Map<String, HR_Worker_Information__c>();
		Set<String> setmanagerEmail = new Set<String>();
		List<HR_Worker_Information__c> hrWorkers = [
			SELECT
				First_Name__c,
				Last_Name__c,
				Employee_id__c,
				Departnment__c,
				Job_Title__c, //Division__c,
				Email__c,
				Manager_Name__c,
				Manager_Email__c,
				Team__c,
				Sub_Team__c
			FROM HR_Worker_Information__c
			WHERE Email__c IN :emailIdSet
			ORDER BY CreatedDate ASC
		]; // Asc : so latest one overwrites
		// map for duplicate names

		for (HR_Worker_Information__c hrw : hrWorkers) {
			if (!String.isBlank(hrw.Email__c)) {
				emailToHrWorkerInfo.put(hrw.Email__c, hrw);
			}
			// When this method is called for Clone_from_User email then we also need its manager email
			if (!String.IsEmpty(hrw.Manager_Email__c)) {
				setHRWorkerManagerEmail.add(hrw.Manager_Email__c); // Also fetch this user from SF User table to set manager look up
			}
		}

		return emailToHrWorkerInfo;
	}

	// Fetch HR Worker Info Users Info by Teams and 15 days back
	// As of now we need only email but there could be other fields neede later
	public map<String, HR_Worker_Information__c> fetchHRWorkerInforByTeams(Set<String> teamsSet, Set<String> subTeamsSet) {
		Map<String, HR_Worker_Information__c> teamsToHrWorkerInfo = new Map<String, HR_Worker_Information__c>();
		Set<String> setmanagerEmail = new Set<String>();
		Date before2weeks = Date.Today().addDays(-15);
		// before2weeks = Date.Today().addDays(2); // for testing
		if (Test.isRunningTest()) {
			before2weeks = Date.Today().addDays(2);
		}
		List<HR_Worker_Information__c> hrWorkers = [
			SELECT Team__c, Sub_Team__c, Email__c, Manager_Email__c
			FROM HR_Worker_Information__c
			WHERE Team__c IN :teamsSet OR Sub_Team__c IN :subTeamsSet
			ORDER BY CreatedDate DESC
		];

		for (HR_Worker_Information__c hrw : hrWorkers) {
			if (!String.isBlank(hrw.Team__c) && !String.isBlank(hrw.Sub_Team__c)) {
				if (!teamsToHrWorkerInfo.containsKey(hrw.Team__c + '-' + hrw.Sub_Team__c)) {
					teamsToHrWorkerInfo.put(hrw.Team__c + '-' + hrw.Sub_Team__c, hrw);
				}
				setHRWorkerEmail.add(hrw.Email__c); // We will fetch SF User details by this email
				if (!String.IsEmpty(hrw.Manager_Email__c)) {
					setHRWorkerManagerEmail.add(hrw.Manager_Email__c); // Also fetch this user from SF User table to set manager look up
				}
			}
		}

		return teamsToHrWorkerInfo;
	}

	// Fetch Users Info by Email
	public map<String, User> fetchSFUserByEmail(Set<String> emailIdSet) {
		Map<String, User> emailToUserMap = new Map<String, User>();
		List<User> users = [
			SELECT
				Id,
				Name,
				profileId,
				UserRoleId,
				Department,
				Title,
				Email,
				CallCenterId,
				ManagerId,
				UserPermissionsSupportUser, //Service Cloud User
				UserPreferencesContentNoEmail, // Receive Salesforce CRM Content Email Alerts
				UserPreferencesContentEmailAsAndWhen, // Receive Salesforce CRM Content Alerts as Daily Digest
				UserPermissionsMarketingUser, // Marketing User
				TimeZoneSidKey,
				LanguageLocaleKey,
				EmailEncodingKey,
				LocaleSidKey
			FROM User
			WHERE Email IN :emailIdSet
			ORDER BY CreatedDate ASC
		];
		for (User u : users) {
			emailToUserMap.put(u.Email, u); // for users having same email, user will override with latest user
		}

		return emailToUserMap;
	}

	public map<Id, List<Id>> fetchPermSetByUser(List<User> listUsers) {
		Set<Id> setUserIds = new Set<Id>();
		Map<Id, List<Id>> userToListPermSetMap = new Map<Id, List<Id>>();
		for (User objUser : listUsers) {
			setUserIds.add(objUser.Id); // To Update & Cloned From Users Ids
		}
		List<PermissionSetAssignment> listPermSetAssignment = [
			SELECT Id, PermissionSetId, AssigneeId
			FROM PermissionSetAssignment
			WHERE AssigneeId IN :setUserIds AND PermissionSetId IN (SELECT Id FROM PermissionSet WHERE IsOwnedByProfile = FALSE)
		];
		for (PermissionSetAssignment objPerSetAssignment : listPermSetAssignment) {
			if (!userToListPermSetMap.containsKey(objPerSetAssignment.AssigneeId)) {
				userToListPermSetMap.put(objPerSetAssignment.AssigneeId, new List<Id>{ objPerSetAssignment.PermissionSetId });
			} else {
				userToListPermSetMap.get(objPerSetAssignment.AssigneeId).add(objPerSetAssignment.PermissionSetId);
			}
			// also create a map that will help delete existing perm Set Ids for update users
			if (!userIdToListPermSetAssignmentMap.containsKey(objPerSetAssignment.AssigneeId)) {
				userIdToListPermSetAssignmentMap.put(objPerSetAssignment.AssigneeId, new List<PermissionSetAssignment>{ objPerSetAssignment });
			} else {
				userIdToListPermSetAssignmentMap.get(objPerSetAssignment.AssigneeId).add(objPerSetAssignment);
			}
		}
		return userToListPermSetMap;
	}

	public map<Id, List<Id>> fetchGroupsByUser(List<User> listUsers) {
		Set<Id> setUserIds = new Set<Id>();
		Map<Id, List<Id>> userIdToListGrpIdMap = new Map<Id, List<Id>>();
		for (User objUser : listUsers) {
			setUserIds.add(objUser.Id); // To Update & Cloned From Users Ids
		}
		List<GroupMember> listGroupMembers = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :setUserIds];

		for (GroupMember member : listGroupMembers) {
			if (!userIdToListGrpIdMap.containsKey(member.UserOrGroupId)) {
				userIdToListGrpIdMap.put(member.UserOrGroupId, new List<Id>{ member.GroupId });
			} else {
				userIdToListGrpIdMap.get(member.UserOrGroupId).add(member.GroupId);
			}
			// also create a map that will help delete existing group members for update users
			if (!userIdToListGrpMemberMap.containsKey(member.UserOrGroupId)) {
				userIdToListGrpMemberMap.put(member.UserOrGroupId, new List<GroupMember>{ member });
			} else {
				userIdToListGrpMemberMap.get(member.UserOrGroupId).add(member);
			}
		}
		return userIdToListGrpIdMap;
	}

	// Update Status through Quable to avoid mixed dml operation.
	public void updateStatus(Map<String, String> dmlErrorsMap, Set<Id> bulkRecIdsSet) {
		List<Bulk_User_CSV_Data__c> listBulkData = [
			SELECT Id, First_Name__c, Last_Name__c, Email__c, Clone_From_User__c, Create_New_User__c, Processing_State__c, Last_Processed__c, Message__c
			FROM Bulk_User_CSV_Data__c
			WHERE Id IN :bulkRecIdsSet
		];

		List<Bulk_User_CSV_Data__c> listBulkCSBDataToUpdate = new List<Bulk_User_CSV_Data__c>();
		for (Bulk_User_CSV_Data__c objCsvObj : listBulkData) {
			if (dmlErrorsMap != null && dmlErrorsMap.containsKey(objCsvObj.Id)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlErrorsMap.get(objCsvObj.Id), objCsvObj);
			} else if (objCsvObj.processing_state__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, objCsvObj);
			}
			listBulkCSBDataToUpdate.add(objCsvObj);
		}
		if (listBulkCSBDataToUpdate.size() > 0) {
			update listBulkCSBDataToUpdate;
		}
	}
	// Set processing state along with error message if any
	private Bulk_User_CSV_Data__c setProcessingState(String state, String message, Bulk_User_CSV_Data__c rec) {
		rec.Processing_State__c = state;
		rec.Message__c = message;
		rec.Last_Processed__c = System.now();
		return rec;
	}
}