/**
* @name         UserRoleTriggerHelper
* @Created By   Anand Singh
* @Modify By    Bhagat Singh 31 July 2020
* @Test Class   UserRoleTriggerHelperTest
* @description  If user will assigned in ['Qualification','Implementation Advocate','Submission','Confirmation'] team then 
					we will add user in "Flexer_Onboarding_Group" public group and also assigned "Flexible_Workforce" permission set.
				Else
					we will removed user from "Flexer_Onboarding_Group" public group also removed "Flexible_Workforce" permission set
*/
public class UserRoleTriggerHelper {
	public static boolean skipTrigger = false;
	public static set<string> set_FlexibleTeam = UtilitiesFactory.set_FlexibleTeam;
	public static Map<String, Group> map_AllGroups = GlobalQueryHelper.getAllRegularGroupsMap();
	public static Group FWOnboardingGroup = map_AllGroups.get('Flexer_Onboarding_Group');
	public static Map<String, PermissionSet> map_AllPermissionSets = GlobalQueryHelper.getAllPermissionSetsMap();
	public static PermissionSet objPermissionSet = map_AllPermissionSets.get('Flexible_Workforce');
	public static PermissionSet objCarrierIOPermissionSet = map_AllPermissionSets.get('Carrier_IO');
	public static PermissionSet objSubAutomationPermissionSet = map_AllPermissionSets.get('Submission_Manual_Automation');
	public static List<User_Skill__c> list_AllUserSkill = new List<User_Skill__c>();
	public static Set<Id> set_RenewalSpecialistUserRoles = new Set<Id>();
	public static String strCarrierIO = 'Carrier IO';
	public void OnBeforeInsert(List<User_Role__c> list_UserRoleTemp) {
		for (User_Role__c objNewUserRole : list_UserRoleTemp) {
			if (objNewUserRole.User__c != null) {
				objNewUserRole.Unique_Id__C = objNewUserRole.User__c;
			}
		}
	}

	public void OnAfterInsert(Map<ID, User_Role__c> map_NewUserRoleTemp) {
	}

	public void OnBeforeUpdate(Map<ID, User_Role__c> map_OldUserRoleTemp, Map<ID, User_Role__c> map_NewUserRoleTemp) {
		String strNewRole = '';
		Set<Id> set_BenefitsAdvisingUserRoleIds = new Set<Id>();

		for (User_Role__c objNewUserRole : map_NewUserRoleTemp.values()) {
			User_Role__c objOldUserRole = map_OldUserRoleTemp.get(objNewUserRole.Id);

			if (objNewUserRole.User__c != null && objNewUserRole.User__c != objOldUserRole.User__c) {
				objNewUserRole.Unique_Id__C = objNewUserRole.User__c;
			}

			if (String.isNotBlank(objNewUserRole.User_Skill_Team__c) && String.isNotBlank(objNewUserRole.User_Skill_Type__c)) {
				if (objNewUserRole.User_Skill_Team__c == FWManageRoleUtil.TEAM_ADVISING) {
					set_BenefitsAdvisingUserRoleIds.add(objNewUserRole.Id);
				}

				if (String.isBlank(objOldUserRole.Original_Team_Type__c)) {
					//Case-1: If first time user assigned in Flexible Team. Then set "Original Team Type"
					if (objOldUserRole.User_Skill_Team__c != null && set_FlexibleTeam.contains(objOldUserRole.User_Skill_Team__c)) {
						objNewUserRole.Original_Team_Type__c = objOldUserRole.User_Skill_Team__c + '-' + objOldUserRole.User_Skill_Type__c;
					} else if (objNewUserRole.User_Skill_Team__c != null && set_FlexibleTeam.contains(objNewUserRole.User_Skill_Team__c)) {
						objNewUserRole.Original_Team_Type__c = objNewUserRole.User_Skill_Team__c + '-' + objNewUserRole.User_Skill_Type__c;
					}
				} else if (String.isNotBlank(objNewUserRole.Original_Team_Type__c)) {
					//If Team or skill will change then below mentioned block of code will execute.
					if (objNewUserRole.User_Skill_Team__c != objOldUserRole.User_Skill_Team__c || objNewUserRole.User_Skill_Type__c != objOldUserRole.User_Skill_Type__c) {
						strNewRole = objNewUserRole.User_Skill_Team__c + '-' + objNewUserRole.User_Skill_Type__c;

						if (objNewUserRole.Original_Team_Type__c == strNewRole) {
							//Case-2: If user roll-back to it's first-time assigned flexible-team then set "Original Team Type" as blank.
							objNewUserRole.Original_Team_Type__c = '';
						} else if (!(set_FlexibleTeam.contains(objNewUserRole.User_Skill_Team__c))) {
							//Case-3: If user assigned in Non-Flexible-Team then set "Original Team Type" as blank.
							objNewUserRole.Original_Team_Type__c = '';
						}
						//Case-4: If user assigned in other Flexible-Team then do nothing
					}
				}
			}
		}

		if (!set_BenefitsAdvisingUserRoleIds.isEmpty()) {
			for (User_Skill__c objUserSkill : [
				SELECT Id, User_Role__c
				FROM User_Skill__c
				WHERE User_Role__c IN :set_BenefitsAdvisingUserRoleIds AND User_Skill_Role_Name__c = :FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST
			]) {
				set_RenewalSpecialistUserRoles.add(objUserSkill.User_Role__c);
			}
		}
	}

	//This method create set of userId and assigned/removed permission from user.
	public void OnAfterUpdate(Map<ID, User_Role__c> map_OldUserRoleTemp, List<User_Role__c> list_UserRoleTemp) {
		Set<String> set_RemoveUserId = new Set<String>();
		Set<String> set_AddUserInGroup = new Set<String>();
		Set<String> set_RemoveUserInGroup = new Set<String>();
		Set<String> set_RemoveCarrierIOIds = new Set<String>();
		Set<String> set_RemoveSubAutomationIds = new Set<String>();
		Map<String, String> map_UserIdPermissions = new Map<String, String>();
		Map<String, String> map_UserIdPermissionsToDelete = new Map<String, String>();
		String strvalue = '';
		for (User_Role__c usr : list_UserRoleTemp) {
			User_Role__c objOldUsr = map_OldUserRoleTemp.get(usr.id);

			if (
				usr.User_Skill_Team__c != null &&
				(usr.User_Skill_Team__c != objOldUsr.User_Skill_Team__c ||
				usr.User_Skill_Type__c != objOldUsr.User_Skill_Type__c)
			) {
				//In Case of Adding Flexible Workforce role
				if (set_FlexibleTeam.contains(usr.User_Skill_Team__c)) {
					map_UserIdPermissions.put(usr.User__c, objPermissionSet.id);
					set_AddUserInGroup.add(usr.User__c);
				}
				//In Case if we assign in non flexible role on user role
				if (set_FlexibleTeam.contains(usr.User_Skill_Team__c) == false || String.isBlank(usr.Original_Team_Type__c)) {
					map_UserIdPermissionsToDelete.put(usr.User__c, objPermissionSet.Id);
					set_RemoveUserId.add(usr.User__c);
					set_RemoveUserInGroup.add(usr.User__c);
				}

				//In case if we assign Caarier IO role on user role
				if (usr.User_Skill_Team__c == strCarrierIO) {
					map_UserIdPermissions.put(usr.User__c, objCarrierIOPermissionSet.Id);
				} else {
					map_UserIdPermissionsToDelete.put(usr.User__c, objCarrierIOPermissionSet.Id);
					set_RemoveCarrierIOIds.add(usr.User__c);
				}
			} else if (String.isBlank(objOldUsr.Original_Team_Type__c) && String.isNotBlank(usr.Original_Team_Type__c)) {
				//It means first time user assigned in Flexible Team.
				if (set_FlexibleTeam.contains(usr.User_Skill_Team__c)) {
					map_UserIdPermissions.put(usr.User__c, objPermissionSet.Id);
					set_AddUserInGroup.add(usr.User__c);
				}
			}

			if (!set_RenewalSpecialistUserRoles.isEmpty() && set_RenewalSpecialistUserRoles.contains(usr.Id) && usr.User__c != null) {
				map_UserIdPermissions.put(usr.User__c, objPermissionSet.Id);
				set_AddUserInGroup.add(usr.User__c);
			}
		}

		if (!map_UserIdPermissionsToDelete.isEmpty() && map_UserIdPermissionsToDelete.size() > 0) {
			RemovePermissionSet(map_UserIdPermissionsToDelete, null);
		}

		//Assign or Remove Flexible_Workforce permission set to user.
		if (map_UserIdPermissions.size() > 0) {
			AddPermissionSet(map_UserIdPermissions);
		}

		//Add or Remove user in public group : FW_Onboarding_Group.
		if (FWOnboardingGroup != null) {
			if (set_AddUserInGroup.size() > 0) {
				String key = '';
				//If already exist in public group then remove from set : set_AddUserInGroup.
				for (GroupMember objMember : [SELECT id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :FWOnboardingGroup.Id AND UserOrGroupId IN :set_AddUserInGroup]) {
					key = objMember.UserOrGroupId;
					if (set_AddUserInGroup.contains(key)) {
						set_AddUserInGroup.remove(key);
					}
				}
				if (set_AddUserInGroup.size() > 0) {
					AddUserInGroup(set_AddUserInGroup);
				}
			}
			if (set_RemoveUserInGroup.size() > 0) {
				RemoveUserInGroup(set_RemoveUserInGroup);
			}
		}
	}

	public void OnBeforeDelete(List<User_Role__c> list_UserRoleTemp, Map<ID, User_Role__c> map_OldUserRoleTemp) {
		cacheData(map_OldUserRoleTemp);
	}

	public void OnAfterDelete(List<User_Role__c> list_UserRoleTemp, Map<ID, User_Role__c> map_OldUserRoleTemp) {
		//DS[19-08-2020] Delete user role : it should delete all user skill, Permission set, Public group etc
		DeleteRelatedListOnUserRoleDelete(map_OldUserRoleTemp);
	}

	public void OnUndelete(List<User_Role__c> list_UserRoleTemp) {
	}

	private static void cacheData(Map<ID, User_Role__c> map_OldUserRoleTemp) {
		if (map_OldUserRoleTemp != null && map_OldUserRoleTemp.size() > 0) {
			//Get all the User skills related to User Role
			list_AllUserSkill = [SELECT Id FROM User_Skill__c WHERE User_Role__c != NULL AND User_Role__c IN :map_OldUserRoleTemp.keySet()];
		}
	}

	//DS[19-08-2020]Delete user role : it should delete all user skill, Permission set, Public group etc
	public static void DeleteRelatedListOnUserRoleDelete(Map<ID, User_Role__c> map_OldUserRoleTemp) {
		if (map_OldUserRoleTemp != null && map_OldUserRoleTemp.size() > 0) {
			Set<string> set_RemoveUserId = new Set<string>();
			//Getting the User Id from the User role
			//to remove the user from Premission set and Public group
			for (User_Role__c objOldUserRole : map_OldUserRoleTemp.values()) {
				set_RemoveUserId.add(objOldUserRole.User__c);
			}
			Savepoint objSavePoint = Database.setSavepoint();
			try {
				Boolean blnIsErrorWhileDeleting = false;
				//Delete all the User skills related to User Role
				if (list_AllUserSkill != null && list_AllUserSkill.size() > 0) {
					List<Database.DeleteResult> list_DeleteResult = Database.delete(list_AllUserSkill);
					for (Database.DeleteResult objResult : list_DeleteResult) {
						if (!objResult.isSuccess()) {
							blnIsErrorWhileDeleting = true;
						}
					}
				}

				if (!blnIsErrorWhileDeleting && set_RemoveUserId != null && set_RemoveUserId.size() > 0) {
					RemovePermissionSet(null, set_RemoveUserId);
					RemoveUserInGroup(set_RemoveUserId);
				}
			} catch (Exception ex) {
				Database.RollBack(objSavePoint);
			}
		}
	}

	//DML operation on setup object is not permitted. That's why we have created future method.
	//This method assingned permission set(Flexible_Workforce) to user.
	@future
	public static void AddPermissionSet(Map<String, String> map_UserIdPermissions) {
		Map<String, Set<String>> map_UserIdPermissionsTemp = new Map<String, Set<String>>();
		String strKey = '';
		Set<String> set_PermissionIds = new Set<String>();

		for (String strvalue : map_UserIdPermissions.keySet()) {
			String strPermissionId = map_UserIdPermissions.get(strvalue);
			if (strPermissionId.Contains(';')) {
				for (String str : strPermissionId.split(';')) {
					if (map_UserIdPermissionsTemp.containsKey(strvalue)) {
						map_UserIdPermissionsTemp.get(strvalue).add(str);
					} else {
						map_UserIdPermissionsTemp.put(strvalue, new Set<String>{ str });
					}
					set_PermissionIds.add(str);
				}
			} else {
				if (map_UserIdPermissionsTemp.containsKey(strvalue)) {
					map_UserIdPermissionsTemp.get(strvalue).add(strPermissionId);
				} else {
					map_UserIdPermissionsTemp.put(strvalue, new Set<String>{ strPermissionId });
				}
				set_PermissionIds.add(strPermissionId);
			}
		}
		for (PermissionSetAssignment objPermission : [
			SELECT Id, AssigneeId, PermissionSet.Id
			FROM PermissionSetAssignment
			WHERE PermissionSet.Id IN :set_PermissionIds AND AssigneeId IN :map_UserIdPermissionsTemp.keySet()
		]) {
			strKey = objPermission.AssigneeId;

			if (map_UserIdPermissionsTemp.containsKey(strKey) && map_UserIdPermissionsTemp.get(strKey).contains(objPermission.PermissionSet.Id)) {
				Set<String> set_PermissionSetIds = map_UserIdPermissionsTemp.get(strKey);
				set_PermissionSetIds.remove(objPermission.PermissionSet.Id);
				if (!set_PermissionSetIds.isEmpty()) {
					map_UserIdPermissionsTemp.put(strKey, set_PermissionSetIds);
				} else {
					map_UserIdPermissionsTemp.remove(strKey);
				}
			}
		}

		try {
			List<PermissionSetAssignment> list_PermissionSetAssignment = new List<PermissionSetAssignment>();
			if ((objPermissionSet != null && objPermissionSet.id != null) || (objCarrierIOPermissionSet != null && objCarrierIOPermissionSet.id != null)) {
				for (String strUserId : map_UserIdPermissionsTemp.keySet()) {
					for (String strPErmissionSetId : map_UserIdPermissionsTemp.get(strUserId)) {
						PermissionSetAssignment objAssignPermission = new PermissionSetAssignment();
						objAssignPermission.PermissionSetId = strPErmissionSetId;
						objAssignPermission.AssigneeId = strUserId;
						list_PermissionSetAssignment.add(objAssignPermission);
					}
				}

				if (list_PermissionSetAssignment != null && list_PermissionSetAssignment.size() > 0) {
					insert list_PermissionSetAssignment;
				}
			}
		} catch (Exception objEx) {
			System.debug('Exception ===>' + objEx);
		}
	}

	//DML operation on setup object is not permitted. That's why we have created future method.
	//This method removed permission set(Flexible_Workforce) to user.
	@future
	public static void RemovePermissionSet(Map<String, String> map_UserIdPermissionsToDelete, Set<string> set_UserIdTemp) {
		try {
			List<SObject> list_Permission = new List<SObject>();
			if (map_UserIdPermissionsToDelete != null) {
				for (SObject objPermission : [
					SELECT Id
					FROM PermissionSetAssignment
					WHERE PermissionSet.Id IN :map_UserIdPermissionsToDelete.values() AND AssigneeId IN :map_UserIdPermissionsToDelete.keySet()
				]) {
					list_Permission.add(objPermission);
				}
			} else if (set_UserIdTemp != null) {
				for (SObject objPermission : [
					SELECT Id
					FROM PermissionSetAssignment
					WHERE PermissionSet.Name IN ('Flexible_Workforce', 'Carrier_IO', 'Submission_Manual_Automation') AND AssigneeId IN :set_UserIdTemp
				]) {
					list_Permission.add(objPermission);
				}
			}

			if (list_Permission.size() > 0) {
				delete list_Permission;
			}
		} catch (Exception ex) {
			System.debug('Exception ===>' + ex);
		}
	}

	//DML operation on setup object is not permitted. That's why we have created future method.
	//This method Add user in public group(Flexer_Onboarding_Group)
	@future
	public static void AddUserInGroup(Set<string> set_UserIdTemp) {
		try {
			List<GroupMember> list_GroupMember = new List<GroupMember>();
			for (string userId : set_UserIdTemp) {
				GroupMember objMember = new GroupMember();
				objMember.GroupId = FWOnboardingGroup.Id;
				objMember.UserOrGroupId = userId;
				list_GroupMember.add(objMember);
			}
			if (list_GroupMember.size() > 0) {
				insert list_GroupMember;
			}
		} catch (Exception ex) {
			System.debug('Exception ===>' + ex);
		}
	}

	//DML operation on setup object is not permitted. That's why we have created future method.
	//This method removed user from public group(Flexer_Onboarding_Group)
	@future
	public static void RemoveUserInGroup(Set<string> set_UserIdTemp) {
		try {
			List<SObject> list_GroupMember = new List<SObject>();
			for (SObject sObj : [SELECT id FROM GroupMember WHERE GroupId = :FWOnboardingGroup.Id AND UserOrGroupId IN :set_UserIdTemp]) {
				list_GroupMember.add(sObj);
			}
			if (list_GroupMember.size() > 0) {
				delete list_GroupMember;
			}
		} catch (Exception ex) {
			System.debug('Exception ===>' + ex);
		}
	}
}