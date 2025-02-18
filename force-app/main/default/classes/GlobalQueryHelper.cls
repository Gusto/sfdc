/**
 * Helper class for queries - lazy loaded whenever possible
 *
 * @group Utilities
 */
public without sharing class GlobalQueryHelper {
	public static List<BusinessHours> listBusinessHours;
	public static Map<Id, User> allIdUserMap;
	public static Map<Id, User> map_ActiveUsers;
	public static Map<Id, UserRole> allIdUserRoleMap;
	public static Map<String, UserRole> allNameUserRoleMap;
	public static Map<Id, Group> allIdQueueMap;
	public static Map<String, Group> allRegularGroupsMap;
	public static Map<String, Group> map_AllQueuesByDevNameMap;
	public static Map<String, PermissionSet> allPermissionSetsMap;
	// This map gives you a mapping of 005 => UserIds, 00G => Group/Role Ids. 00G can mean either Regular Group,Role,RoleAndSubordinates,RoleAndSubordinatesInternal.
	public static Map<String, Set<Id>> map_AllGroupMembers;
	public static List<Group> allGroups;
	public static List<OrgWideEmailAddress> listOrgWideAddresses;
	public static List<RecordType> list_recordTypes;
	public static List<CollaborationGroup> list_collabGrp;
	public static Integer int_FYMonth;
	public static List<PermissionSetAssignment> list_Assignment;
	public static final String USER_PREFIX = '005';
	public static final String GROUP_PREFIX = '00G';
	private static final String BENEFITS_COMPLIANCE_PROFILE = 'Benefits Compliance';
	public static Map<Id, Agency_Information__c> map_Agency;
	public static List<Case_Reason_Classification__c> list_CaseReasonClassification;
	public static List<Sub_Case_Reason_Classification__c> list_SubCaseReasonClassifications;
	public static Map<String, BusinessHours> map_AllBusinessHours;
	public static List<Tax_Rate__c> list_TaxResTaxRates = new List<Tax_Rate__c>();
	public static Map<Id, User_Role__c> map_SpecialistUserRoles;
	public static Map<String, CaseTeamRole> map_CaseTeamRole;
	public static Map<String, String> map_MRRReasonIndexingStatus;

    public static Map<String, String> getMRRReasonIndexingStatusMap() {
        if(map_MRRReasonIndexingStatus == null) {
            map_MRRReasonIndexingStatus = new Map<String, String>();
            for(AutoIndexingStatus_Based_On_MRR__mdt objReasonIndexingStatus : AutoIndexingStatus_Based_On_MRR__mdt.getAll().values()) {
                system.debug('objReasonIndexingStatus.MRR_Reason__c ***** '+objReasonIndexingStatus.MRR_Reason__c + '-->'+objReasonIndexingStatus.Auto_Index_Status__c);
                if(String.isNotBlank(objReasonIndexingStatus.MRR_Reason__c )) {
                    for(String strMRRReason : objReasonIndexingStatus.MRR_Reason__c.split(';')) {
                        map_MRRReasonIndexingStatus.put(strMRRReason, objReasonIndexingStatus.Auto_Index_Status__c );
                    }
                }
            }
        }
        return map_MRRReasonIndexingStatus;
    }

	public static Map<Id, UserRole> getIdUserRoleMap() {
		if (allIdUserRoleMap == null) {
			allIdUserRoleMap = new Map<Id, UserRole>([SELECT Id, Name, DeveloperName FROM UserRole]);
		}
		return allIdUserRoleMap;
	}

	public static Map<String, UserRole> getNameUserRoleMap() {
		if (allNameUserRoleMap == null) {
			allNameUserRoleMap = new Map<String, UserRole>();
			Map<Id, UserRole> tempAllUserRoleMap = getIdUserRoleMap();
			for (UserRole role : tempAllUserRoleMap.values()) {
				allNameUserRoleMap.put(role.Name, role);
			}
		}
		return allNameUserRoleMap;
	}
	public static Map<Id, User> map_BenefitsComplianceUser;

	/**
	 * @author      Pravesh
	 * @description Get all User_Role__c records
	 * @param       N/A
	 * @return      map of Record Id and User_Role__c
	 **/
	public static Map<Id, User_Role__c> getSpecialistUserRoleMap() {
		if (map_SpecialistUserRoles == null) {
			map_SpecialistUserRoles = new Map<Id, User_Role__c>([SELECT Id, User__c, User_Full_Name__c FROM User_Role__c WHERE User_Skill_team__c = :CaseUtils.TAXRES_ACCOUNT_SPECIALIST]);
		}
		return map_SpecialistUserRoles;
	}

	/**
	 * @author      Yogesh
	 * @description Get all Benefits Compliance User records
	 * @param       set_UserIds - Set of User Ids
	 * @return      map of Record Id Benefits Compliance User
	 **/
	public static Map<Id, User> getBenefitsComplianceUserMap(Set<Id> set_UserIds) {
		if (map_BenefitsComplianceUser == null) {
			map_BenefitsComplianceUser = new Map<Id, User>(
				[
					SELECT Id
					FROM User
					WHERE Id IN :set_UserIds AND Profile.Name = :BENEFITS_COMPLIANCE_PROFILE
				]
			);
		}
		return map_BenefitsComplianceUser;
	}

	/**
     * @description     Method to get getGroupIdByQueueName
     * @Author          Sindhu
     * @param String    NA
     * @return          String strCaseQueue
     */
    public static Id getGroupIdByQueueName(String strCaseQueue) {
        Id groupId;
        List<Group> list_Groups = [SELECT Id FROM Group WHERE Type = :CaseUtils.STRG_QUEUE AND Name = :strCaseQueue LIMIT 1];
        if (!list_Groups.isEmpty()) {
            groupId = list_Groups[0].Id;
        }
        return groupId;
    }

	/**
	 * @author      Ankit CS
	 * @description Get all the Sub-ordinate roles under a given role.
	 * @param       set_RoleIds - Set of Role Ids
	 * @return      set_AllSubordinateRoles - Set of all Sub-ordinate Role Ids
	 **/
	public static Set<Id> getSubordinateRoles(Set<Id> set_RoleIds) {
		Set<Id> set_AllSubordinateRoles = new Set<Id>();
		for (UserRole objUserRole : [SELECT Id, Name FROM UserRole WHERE ParentRoleId != NULL AND ParentRoleId IN :set_RoleIds]) {
			set_AllSubordinateRoles.add(objUserRole.Id);
		}

		if (!set_AllSubordinateRoles.isEmpty()) {
			set_AllSubordinateRoles.addAll(getSubordinateRoles(set_AllSubordinateRoles));
		}

		return set_AllSubordinateRoles;
	}

	public static List<BusinessHours> getAllBusinessHoursList() {
		if (listBusinessHours == null) {
			listBusinessHours = [SELECT Id, Name, TimeZoneSidKey, IsDefault FROM BusinessHours];
		}
		return listBusinessHours;
	}

	private static BusinessHours defaultBusinessHour;

	public static BusinessHours getDefaultBusinessHour() {
		if (defaultBusinessHour != null) {
			return defaultBusinessHour;
		}
		for (BusinessHours bh : getAllBusinessHoursList()) {
			if (bh.isDefault == true) {
				defaultBusinessHour = bh;
			}
		}
		return defaultBusinessHour;
	}

	/**
	 * @description   To query all business hours on basis of BusinessHours Name
	 * @author        Sanjay Paryani
	 * @param 		  N/A
	 * @return        Map<String, BusinessHours> of all active BusinessHours from our org
	 */
	public static Map<String, BusinessHours> getAllBusinessHoursMap() {
		if (map_AllBusinessHours == null) {
			map_AllBusinessHours = new Map<String, BusinessHours>();
			for (BusinessHours objBusinessHour : [SELECT Id, Name, TimeZoneSidKey, IsDefault, IsActive FROM BusinessHours WHERE IsActive = TRUE]) {
				map_AllBusinessHours.put(objBusinessHour.Name, objBusinessHour);
			}
		}

		return map_AllBusinessHours;
	}

	/**
	 * @description   To query all business hours on basis of BusinessHours Name
	 * @author        Sanjay Paryani
	 * @param 		  strBusinessHourName BusinessHours Name
	 * @return        BusinessHours object
	 */
	public static BusinessHours getBusinessHoursByName(String strBusinessHourName) {
		Map<String, BusinessHours> map_BusinessHours = getAllBusinessHoursMap();
		return map_BusinessHours.get(strBusinessHourName);
	}

	/**
	 * @description Query only active users
	 * @author Praveen Sethu
	 * @return   Query only active users
	 */
	public static Map<Id, User> queryActiveUsers() {
		if (map_ActiveUsers == null) {
			map_ActiveUsers = new Map<Id, User>(
				[
					SELECT
						Id,
						Name,
						Alias,
						Calendar_Link__c,
						Data_Migration_Validation__c,
						Department,
						Division,
						Email,
						Exempt_from_Validation_Rules__c,
						FirstName,
						Is_Api_Integration__c,
						IsActive,
						LastName,
						ManagerId,
						Profile.Name,
						ProfileId,
						Secondary_Role__c,
						Slack_Id__c,
						TimeZoneSidKey,
						Title,
						UserRole.DeveloperName,
						UserRole.Name,
						UserRoleId,
						Out_Of_Office__c,
						Class_Queue__c,
						Benefits_Class__c
					FROM User
					WHERE IsActive = TRUE
				]
			);
		}
		return map_ActiveUsers;
	}

	public static Map<Id, User> getUsersByIdMap(Set<Id> userIdSet) {
		Map<Id, User> userMap = queryActiveUsers();
		Map<Id, User> selectdUserMap = new Map<Id, User>();
		for (Id userId : userIdSet) {
			if (userMap.containsKey(userId)) {
				selectdUserMap.put(userId, userMap.get(userId));
			}
		}
		return selectdUserMap;
	}

	public static User getUserInfoById(Id userId) {
		Map<Id, User> userMap = queryActiveUsers();
		return userMap != null && userMap.containsKey(userId) ? userMap.get(userId) : null;
	}

	public static List<User> getUsersInfoBySetOfIds(Set<Id> list_userId) {
		Map<Id, User> userMap = queryActiveUsers();
		List<user> list_users = new List<User>();
		for (Id userid : list_userId) {
			list_users.add(userMap.get(userid));
		}
		return list_users;
	}

	public static List<user> getListOfUserbyEmail(String emailId) {
		Map<Id, User> userMap = queryActiveUsers();
		List<User> list_Users = new List<user>();
		for (User u : userMap.values()) {
			if (u.Email == emailId) {
				list_Users.add(u);
			}
		}
		return list_Users;
	}

	public static Map<String, PermissionSet> getAllPermissionSetsMap() {
		if (allPermissionSetsMap == null) {
			allPermissionSetsMap = new Map<String, PermissionSet>();
			for (PermissionSet ObjPermissionSet : [SELECT Id, Name FROM PermissionSet]) {
				allPermissionSetsMap.put(ObjPermissionSet.Name, ObjPermissionSet);
			}
		}
		return allPermissionSetsMap;
	}

	public static Map<String, Group> getAllRegularGroupsMap() {
		if (allRegularGroupsMap == null) {
			allRegularGroupsMap = new Map<String, Group>();
			for (Group ObjGroup : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Regular']) {
				allRegularGroupsMap.put(ObjGroup.DeveloperName, ObjGroup);
			}
		}
		return allRegularGroupsMap;
	}

	public static Map<Id, Group> getAllGroupQueueMap() {
		if (allIdQueueMap == null) {
			allIdQueueMap = new Map<Id, Group>([SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue']);
		}
		return allIdQueueMap;
	}

	/**
	 * @description   To query Queues and store as Deveoper Name and Group
	 * @author        Sanjay Paryani
	 * @param 		  N/A
	 * @return        Map<String, Group> of all groups of type Queue with key as Developer name of Queue and value as the group object
	 */
	public static Map<String, Group> getAllQueuesByDevNameMap() {
		if (map_AllQueuesByDevNameMap == null) {
			map_AllQueuesByDevNameMap = new Map<String, Group>();
			for (Group objGroup : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue']) {
				map_AllQueuesByDevNameMap.put(objGroup.DeveloperName, objGroup);
			}
		}

		return map_AllQueuesByDevNameMap;
	}

	public static List<Group> getAllTheGroups() {
		if (allGroups == null) {
			allGroups = [SELECT Id, Type, Name, DeveloperName FROM Group];
		}
		return allGroups;
	}

	public static List<Group> getGroupsByType(String queueType) {
		List<Group> listOfGroups = getAllTheGroups();
		List<Group> listofQueueGrp = new List<Group>();
		for (Group grp : listOfGroups) {
			if (grp.Type == queueType) {
				listofQueueGrp.add(grp);
			}
		}

		return listofQueueGrp;
	}

	/**
	 * @description   To query Queue on basis of developer name
	 *
	 * @author        Yuvraj
	 * @since         13 July 2020
	 * @param devName Group DeveloperName
	 * @return        `List<Group>` All Groups (only one will be returned) with that DeveloperName
	 */
	public static List<Group> getGroupsByName(String devName) {
		Map<Id, Group> listOfGroups = getAllGroupQueueMap();
		List<Group> listofQueueGrp = new List<Group>();

		if (!listOfGroups.isEmpty()) {
			for (Group grp : listOfGroups.values()) {
				if (grp.DeveloperName == devName) {
					listofQueueGrp.add(grp);
				}
			}
		}

		return listofQueueGrp;
	}

	/**
	 * @description   To query Group Members on basis of Group name
	 * @author        Sanjay Paryani
	 * @param 		  strGroupName Group Name
	 * @return        'Map<String, Set<Id>> of All user ids and/or role/group ids
	 */
	public static Map<String, Set<Id>> getGroupMembersByName(String strGroupName) {
		map_AllGroupMembers = new Map<String, Set<Id>>();

		for (GroupMember objMember : [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = :strGroupName AND Group.Type = 'Regular']) {
			if (String.valueof(objMember.UserOrGroupId).startsWith(USER_PREFIX)) {
				if (map_AllGroupMembers.containsKey(USER_PREFIX)) {
					map_AllGroupMembers.get(USER_PREFIX).add(objMember.UserOrGroupId);
				} else {
					map_AllGroupMembers.put(USER_PREFIX, new Set<Id>{ objMember.UserOrGroupId });
				}
			} else if (String.valueof(objMember.UserOrGroupId).startsWith(GROUP_PREFIX)) {
				if (map_AllGroupMembers.containsKey(GROUP_PREFIX)) {
					map_AllGroupMembers.get(GROUP_PREFIX).add(objMember.UserOrGroupId);
				} else {
					map_AllGroupMembers.put(GROUP_PREFIX, new Set<Id>{ objMember.UserOrGroupId });
				}
			}
		}

		return map_AllGroupMembers;
	}

	public static List<OrgWideEmailAddress> queryTogetOrgWideEmail(Set<String> set_Address) {
		List<OrgWideEmailAddress> list_orgWideAddress = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :set_Address];
		return list_orgWideAddress;
	}

	public static List<OrgWideEmailAddress> getOrgWideEmailByAdd(String address) {
		if (listOrgWideAddresses == null) {
			Set<String> set_Address = new Set<String>();
			set_Address.add(address);
			listOrgWideAddresses = queryTogetOrgWideEmail(set_Address);
		}

		return listOrgWideAddresses;
	}

	public static List<RecordType> queryRecordType(String sobjectName) {
		List<RecordType> list_recordType = [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SobjectType = :sobjectName];
		return list_recordType;
	}
	public static List<RecordType> getRecordTypeBySObjectName(String sobjectName) {
		if (list_recordTypes == null) {
			list_recordTypes = queryRecordType(sobjectName);
		}

		return list_recordTypes;
	}

	/**
	 * @description Get 'Queue'Name and Id
	 * @author Anurag Gautam
	 * @param  setQueueNames Set of 'Queue'Names (not developername)
	 * @return               Map of 'Queue'Name to 'Queue'Id
	 */
	public static Map<String, Id> getNameQueueMap(Set<String> setQueueNames) {
		Map<String, Id> allNameQueueMap = new Map<String, Id>();
		Map<Id, Group> allQueueMap = getAllGroupQueueMap();
		for (Group queueObj : allQueueMap.values()) {
			if (!setQueueNames.isEmpty() && setQueueNames.contains(queueObj.Name)) {
				allNameQueueMap.put(queueObj.Name, queueObj.Id);
			}
		}
		return allNameQueueMap;
	}

	/**
	 * @author         Anurag Gautam
	 * @description    Get 'Queue'Name and Id
	 * @param          set_QueueDevNames Set of 'Queue'DeveloperNames
	 * @return         Map of 'Queue'DeveloperName to 'Queue' Id
	 */
	public static Map<String, Id> getQueueNameAndIdMap(Set<String> set_QueueDevNames) {
		Map<String, Id> map_QueueDevNameAndId = new Map<String, Id>();
		Map<Id, Group> map_QueueIdAndQueue = getAllGroupQueueMap();
		for (Group objQueue : map_QueueIdAndQueue.values()) {
			if (!set_QueueDevNames.isEmpty() && set_QueueDevNames.contains(objQueue.DeveloperName)) {
				map_QueueDevNameAndId.put(objQueue.DeveloperName, objQueue.Id);
			}
		}
		return map_QueueDevNameAndId;
	}

	/**
	 * @author         Anurag Gautam
	 * @description    Get Profile Name and Id
	 * @param          NA
	 * @return         Map of Profile Name and Id
	 */
	public static Map<String, Id> getProfileNameAndIdMap() {
		Map<String, Id> map_ProfileNameAndId = new Map<String, Id>();
		for (Profile objProfile : [SELECT Id, Name FROM Profile]) {
			map_ProfileNameAndId.put(objProfile.Name, objProfile.Id);
		}
		return map_ProfileNameAndId;
	}

	/**
	 * @author       Anurag Gautam
	 * @description  This method returns the queue Id based on name
	 * @param        strQueueName Name
	 * @return       Queue Id
	 **/
	public static String getQueueIdByName(String strQueueName) {
		Set<String> set_QueueName = new Set<String>{ strQueueName };
		return GlobalQueryHelper.getNameQueueMap(set_QueueName).get(strQueueName);
	}

	/**
	 * @author       Sanjay Paryani
	 * @description  This method returns the queue Id based on developer name
	 * @param        strQueueDevName Name
	 * @return       Queue Id
	 **/
	public static String getQueueIdByDevName(String strQueueDevName) {
		Set<String> set_QueueName = new Set<String>{ strQueueDevName };
		return GlobalQueryHelper.getQueueNameAndIdMap(set_QueueName).get(strQueueDevName);
	}

	public static List<CollaborationGroup> queryCollaborationGroup(String Groupname) {
		list_collabGrp = new List<CollaborationGroup>();
		for (CollaborationGroup collabGroup : [SELECT Id, Name FROM CollaborationGroup WHERE Name = :Groupname]) {
			list_collabGrp.add(collabGroup);
		}

		return list_collabGrp;
	}

	public static List<CollaborationGroup> getCollaborationGroup(String grpName) {
		if (list_collabGrp == null) {
			list_collabGrp = queryCollaborationGroup(grpName);
		}
		return list_collabGrp;
	}

	/**
	 * Use OrganizationUtilities method because it memoizes Organization info
	 * @author prashant, David Schach
	 * @since  24-03-2020
	 */
	public static Integer getFiscalYearStartMonth() {
		return OrganizationUtilities.getFiscalYearStartMonth();
	}

	/**
	 * @author Alex
	 * @since  9/14/2020
	 * Get permission set assignments for current user from list of permission set assignment names
	 */
	public static List<PermissionSetAssignment> getPermSetAssignments(List<String> list_PermNames) {
		if (list_Assignment == null) {
			list_Assignment = queryPermSetAssignments(list_PermNames);
		}

		return list_Assignment;
	}

	/**
	 * @author Alex Xiong
	 * @description get permission set assignments for the current user
	 * @param list_PermNames - list of permission set names
	 * @return list of permission assignments
	 */
	public static List<PermissionSetAssignment> queryPermSetAssignments(List<String> list_PermNames) {
		/**
		 * have list of permission set names
		 * get permission set groups containing these sets with permission set group components
		 * get permission set assignments
		 */
		List<PermissionSetAssignment> list_PSA = new List<PermissionSetAssignment>();
		List<PermissionSet> list_PermSet = [SELECT Id, Name, (SELECT Id, PermissionSetGroupId FROM PermissionSetGroupComponents) FROM PermissionSet WHERE Name IN :list_PermNames];
		List<Id> list_PSGIds = new List<Id>();

		for (PermissionSet objPS : list_PermSet) {
			for (PermissionSetGroupComponent objPSGC : objPS.PermissionSetGroupComponents) {
				list_PSGIds.add(objPSGC.PermissionSetGroupId);
			}
		}

		for (PermissionSetAssignment objPSA : [
			SELECT Id, AssigneeId, PermissionSet.Name
			FROM PermissionSetAssignment
			WHERE AssigneeId = :UserInfo.getUserId() AND (PermissionSet.Name IN :list_PermNames OR PermissionSetGroupId IN :list_PSGIds)
		]) {
			list_PSA.add(objPSA);
		}

		return list_PSA;
	}

	/**
	 * @description Query only specific active users
	 * @author Veeresh Kumar
	 * @return   Query only specific active users
	 */
	public static Map<Id, User> queryActiveUsers(Set<Id> set_UserIds) {
		return new Map<Id, User>(
			[
				SELECT
					Id,
					Name,
					Alias,
					Calendar_Link__c,
					Data_Migration_Validation__c,
					Department,
					Division,
					Email,
					Exempt_from_Validation_Rules__c,
					FirstName,
					Is_Api_Integration__c,
					IsActive,
					LastName,
					ManagerId,
					Profile.Name,
					ProfileId,
					Secondary_Role__c,
					Slack_Id__c,
					TimeZoneSidKey,
					Title,
					UserRole.DeveloperName,
					UserRole.Name,
					UserRoleId,
					Out_Of_Office__c
				FROM User
				WHERE IsActive = TRUE AND Id IN :set_UserIds
			]
		);
	}

	//Shyam : Added "OCR_Enabled__c, AutoSolve_Enabled__c" fields in the query
	public static Map<Id, Agency_Information__c> getAllAgencyInformation() {
		if (map_Agency == null || Test.isRunningTest()) {
			map_Agency = new Map<Id, Agency_Information__c>(
				[
					SELECT Id, Name, Tax_Type__c, State__c, Routing_Queue__c, SLA_Business_Days__c, Domain__c, Email__c, Agency_Rep__c, SUI_Rate_Form_Numbers__c, OCR_Enabled__c, AutoSolve_Enabled__c
					FROM Agency_Information__c
				]
			);
		}

		return map_Agency;
	}

	/**
	 * @description   To query Case Team Role
	 * @author        Deepika Saini
	 * @param 		  N/A
	 * @return        'Map<String, CaseTeamRole> of All Case Team Role With Name As Key
	 */
	public static Map<String, CaseTeamRole> getCaseTeamRole() {
		if (map_CaseTeamRole == null) {
			map_CaseTeamRole = new Map<String, CaseTeamRole>();
			for (CaseTeamRole objCaseTeamRole : [SELECT Id, Name FROM CaseTeamRole]) {
				map_CaseTeamRole.put(objCaseTeamRole.Name, objCaseTeamRole);
			}
		}

		return map_CaseTeamRole;
	}
	/**
	 * @description   To query Agency Information records and store map of names as keys
	 * @author        Sanjay Paryani
	 * @param 		  N/A
	 * @return        'Map<String, Agency_Information__c> of All Agency Info records with Agency Name as key
	 */
	public static Map<String, Agency_Information__c> getAllAgencyNamesWithAgencyInformation() {
		Map<String, Agency_Information__c> map_AgencyNameWithAgencyRecords = new Map<String, Agency_Information__c>();
		Map<Id, Agency_Information__c> map_AgencyInformation = getAllAgencyInformation();
		for (Agency_Information__c objAgency : map_AgencyInformation.values()) {
			if (!map_AgencyNameWithAgencyRecords.containsKey(objAgency.Name)) {
				map_AgencyNameWithAgencyRecords.put(objAgency.Name, objAgency);
			}
		}

		return map_AgencyNameWithAgencyRecords;
	}

	public static List<Case_Reason_Classification__c> getAllCaseReasonClassification() {
		if (list_CaseReasonClassification == null) {
			list_CaseReasonClassification = [
				SELECT
					Id,
					Name,
					Class__c,
					type__c,
					Priority__c,
					Task_Us__c,
					Survey_Eligible__c,
					Do_not_Auto_Solve__c,
					Active__c,
					Reason_Category__c,
					Reason_Category__r.Name,
					Auto_Email_Behavior__c,
					Email_Content__c,
					Do_Not_Auto_Solve_for_Auto_Email__c,
					Confidence_Threshold__c,
					Reason_Code__c,
					Email_Signature__c,
					Override_Email_Signature__c,
					Case_Type_Pillar__c,
					Support_Level__c,
					Specialization__c,
					Routing_Team__c
				FROM Case_Reason_Classification__c
				ORDER BY Type__c ASC
			];
		}

		return list_CaseReasonClassification;
	}

	/**
	 * @description     Method to get all sub case reasons
	 * @Author          Priya S
	 * @param void     void
	 * @return Boolean       returns the sub case reason list
	 */
	public static List<Sub_Case_Reason_Classification__c> getAllSubCaseReasons() {
		if (list_SubCaseReasonClassifications == null) {
			list_SubCaseReasonClassifications = [SELECT Id, Case_Reason__c FROM Sub_Case_Reason_Classification__c WHERE Case_Reason__c != NULL AND Active__c = TRUE LIMIT 5000];
		}

		return list_SubCaseReasonClassifications;
	}

	/**
	 * @description     Method to check if logged in user or user role part of group
	 * @Author          Swati Arya
	 * @param String    Group name
	 * @return Boolean       returns if user or user role group member
	 */
	public static Boolean getLoggedUserOrRoleGroupMember(String strGroupName) {
		Set<Id> set_UserIdsFromGroup = new Set<Id>();
		Set<Id> set_RoleIdsFromGroup = new Set<Id>();
		Map<String, Set<Id>> map_GroupMembersRecords = new Map<String, Set<Id>>();
		map_GroupMembersRecords = GlobalQueryHelper.getGroupMembersByName(strGroupName);
		if (!map_GroupMembersRecords.isEmpty()) {
			// This will give you the roles/groups present in the group.
			if (map_GroupMembersRecords.containsKey(GROUP_PREFIX)) {
				set_RoleIdsFromGroup = map_GroupMembersRecords?.get(GROUP_PREFIX);
			}
			// This will give you the users present in the group.
			if (map_GroupMembersRecords.containsKey(USER_PREFIX)) {
				set_UserIdsFromGroup.addAll(map_GroupMembersRecords?.get(USER_PREFIX));
			}
		}

		if (!set_UserIdsFromGroup.isEmpty() && set_UserIdsFromGroup.contains(UserInfo.getUserId())) {
			return true;
		} else {
			// This will give you the users present in the roles that are present in a group.
			AggregateResult[] objResult = [
				SELECT COUNT(Id) usercount
				FROM User
				WHERE UserRoleId IN (SELECT RelatedId FROM Group WHERE Type = 'Role' AND Id IN :set_RoleIdsFromGroup) AND Id = :UserInfo.getUserId()
			];
			Object objUserCount = objResult?.get(0)?.get('usercount');

			if (objUserCount != null && (Integer) objUserCount > 0) {
				return true;
			} else {
				return false;
			}
		}
	}

	/**
	 * @description     Method to get all tax rates
	 * @Author          Elavarasan N
	 * @param String    NA
	 * @return          List<Tax_Rate__c>
	 */
	public static List<Tax_Rate__c> getAllTaxRates() {
		if (list_TaxResTaxRates == null || list_TaxResTaxRates.isEmpty()) {
			list_TaxResTaxRates = [SELECT Id, Name, Agency_Information__c, ZP_Tax_Rate_Name__c FROM Tax_Rate__c];
		}
		return list_TaxResTaxRates;
	}

	/*
	 * @Description    Get Case Hitory by Field or otherwise
	 * @Author         Elavarasan N
	 * @Param          Set of Case Ids
	 * @Param          Field Updated [OPTIONAL]
	 * @return         List of Case History
	 */
	public static List<CaseHistory> getCaseHistoryByUpdatedField(Set<Id> set_CaseIds, String strFieldUpdated) {
		List<CaseHistory> list_CaseHistory = new List<CaseHistory>();
		for (CaseHistory objCaseHistory : [SELECT CaseId, Field, OldValue, NewValue, CreatedDate FROM CaseHistory WHERE CaseId IN :set_CaseIds]) {
			if (String.isNotBlank(strFieldUpdated) && objCaseHistory.Field == strFieldUpdated) {
				list_CaseHistory.add(objCaseHistory);
			} else if (String.isBlank(strFieldUpdated)) {
				list_CaseHistory.add(objCaseHistory);
			}
		}
		return list_CaseHistory;
	}

	/**
	 * @author Deepesh
	 * @since  8/09/2023
	 * Get permission set assignments for specific user from list of permission set assignment names
	 */
	public static Map<String, Set<Id>> getPermissionSetUsers(Set<String> set_PermissionSetNames, List<User> list_UserRecs) {
		List<PermissionSetAssignment> list_PermissionSetAssignments = new List<PermissionSetAssignment>();
		if (list_UserRecs != null && !list_UserRecs.isEmpty()) {
			list_PermissionSetAssignments = [
				SELECT Id, AssigneeId, PermissionSet.Name
				FROM PermissionSetAssignment
				WHERE PermissionSet.Name IN :set_PermissionSetNames AND AssigneeId != NULL AND AssigneeId IN :list_UserRecs
			];
		} else {
			list_PermissionSetAssignments = [SELECT Id, AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name IN :set_PermissionSetNames];
		}

		Map<String, Set<Id>> map_PermissionSetUsers = new Map<String, Set<Id>>();

		if (list_PermissionSetAssignments != null && !list_PermissionSetAssignments.isEmpty()) {
			for (PermissionSetAssignment objAssignmentRecord : list_PermissionSetAssignments) {
				if (map_PermissionSetUsers.containsKey(objAssignmentRecord.PermissionSet.Name)) {
					map_PermissionSetUsers.get(objAssignmentRecord.PermissionSet.Name).add(objAssignmentRecord.AssigneeId);
				} else {
					map_PermissionSetUsers.put(objAssignmentRecord.PermissionSet.Name, new Set<Id>{ objAssignmentRecord.AssigneeId });
				}
			}
		}
		return map_PermissionSetUsers;
	}
}