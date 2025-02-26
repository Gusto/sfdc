/**
 * @description Utility class for getting information about users
 * @author Sandeep Golla
 * @author David Schach
 * @group Utilities
 * @since 11-24-2021
 * @see UserUtilsTest
 * @group Utilities
 **/
public without sharing class UserUtils {
	public final static String LABEL_INTEGRATION = 'integration';
	public final static String LABEL_ADMIN = 'admin';
	public final static String LABEL_WORKATO = 'Workato';
	public final static String LABEL_PGUSTO = 'Penny at Gusto';
	public final static String LABEL_APIHEROKU = 'API Heroku';
	public final static String LABEL_APIINTEGRATION = 'BizTech Integrations';
	public final static String LABEL_RPA_AUTOMATION = 'RPA Automation';
	public final static String OT_CARRIER_SWITCH = 'Carrier switch';
	public static String STATUS_CLOSED = 'Closed';
	public static String STATUS_SOLVED = 'Solved';
	public static String MARKETO_PROFILE = 'Marketo Integration';

	public final static String LABEL_ARDIUS = 'Ardius';
	public final static String LABEL_ARDIUSTEAM = 'Ardius Team';
	public final static Id ID_CURRENT_USER = UserInfo.getUserId();

	private static User currentUser;

	public static List<BusinessHours> list_BusinessHours {
		get {
			if (list_BusinessHours == null) {
				list_BusinessHours = GlobalQueryHelper.getAllBusinessHoursList();
			}
			return list_BusinessHours;
		}
		set;
	}

	public static Map<String, UserRole> map_NameToUserRole {
		get {
			if (map_NameToUserRole == null) {
				map_NameToUserRole = GlobalQueryHelper.getNameUserRoleMap();
			}
			return map_NameToUserRole;
		}
		private set;
	}

	public static Map<Id, User> map_UserIdToUserMap {
		get {
			if (map_UserIdToUserMap == null) {
				map_UserIdToUserMap = GlobalQueryHelper.queryActiveUsers();
			}
			return map_UserIdToUserMap;
		}
		private set;
	}

	private static Map<Id, User> mapUserDirectory {
		get {
			if (mapUserDirectory == null) {
				mapUserDirectory = new Map<Id, User>(
					[
						SELECT Id, FirstName, LastName, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, IsActive, Email, Slack_Id__c, Is_Api_Integration__c, Exempt_from_Validation_Rules__c
						FROM User
					]
				);
			}
			return mapUserDirectory;
		}
		private set;
	}

	private static Map<Id, Group> mapGroupDirectory {
		get {
			if (mapGroupDirectory == null) {
				mapGroupDirectory = new Map<Id, Group>();
				List<Group> allGroups = [SELECT Id, Name FROM Group];
				if (allGroups.isEmpty()) {
					return mapGroupDirectory;
				}
				mapGroupDirectory.putAll(allGroups);
			}
			return mapGroupDirectory;
		}
		private set;
	}

	/**
	 * Group name to group id map
	 * @author Krishna Bodala
	 */
	public static Map<String, Id> mapGroupNameToId {
		get {
			if (mapGroupNameToId == null) {
				mapGroupNameToId = new Map<String, Id>();
				for (Group groupVar : [SELECT Id, DeveloperName FROM Group]) {
					mapGroupNameToId.put(groupVar.DeveloperName, groupVar.Id);
				}
			}
			return mapGroupNameToId;
		}
		set;
	}

	public static Boolean isActive(Id userId) {
		if (String.isBlank(userId)) {
			return null;
		}
		return mapUserDirectory.get(userId).IsActive;
	}

	public static Boolean isUser(Id userId) {
		if (String.isBlank(userId)) {
			return null;
		}
		return (Schema.User.SObjectType == userId.getSobjectType());
	}

	public static Boolean isGroup(Id userId) {
		if (String.isBlank(userId)) {
			return null;
		}
		return (Schema.Group.SObjectType == userId.getSobjectType());
	}

	public static String getUserRoleName(Id userId) {
		if (String.isBlank(userId) || (!mapUserDirectory.containsKey(userId) || (mapUserDirectory.containsKey(userId) && mapUserDirectory.get(userId).UserRoleId == null))) {
			return null;
		}
		return mapUserDirectory.get(userId).UserRole.Name;
	}

	public static String getProfileName(Id userId) {
		if (String.isBlank(userId) || !mapUserDirectory.containsKey(userId)) {
			return null;
		}

		return mapUserDirectory.get(userId).Profile.Name;
	}

	public static String getSlackId(Id userId) {
		if (String.isBlank(userId)) {
			return null;
		}

		return mapUserDirectory.get(userId).Slack_Id__c;
	}

	public static String getName(Id userId) {
		String returnName;
		if (String.isNotBlank(userId)) {
			if (Schema.User.SObjectType == userId.getSobjectType()) {
				User user = mapUserDirectory.get(userId);
				returnName = User.Name;
			} else if (Schema.Group.SObjectType == userId.getSobjectType()) {
				Group grp = mapGroupDirectory.get(userId);
				returnName = grp.Name;
			}
		}
		return returnName;
	}

	/**
	 * @description Lazy load the current user
	 *
	 * @return      Specific fields on the running User record
	 */
	public static User returnLoggedInUser() {
		if (currentUser == null) {
			currentUser = [SELECT Id, Is_Api_Integration__c, Exempt_from_Validation_Rules__c, Data_Migration_Validation__c, Name, UserRoleId, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
		}
		return currentUser;
	}

	/*** Integration/Admin Users ***/
	public final static Set<String> setIntegrationAdminUsers {
		get {
			if (setIntegrationAdminUsers == null) {
				return generateIntAdminUsers();
			}
			return setIntegrationAdminUsers;
		}
	}

	public static Boolean isAdminIntgUser(Id idUser) {
		if (setIntegrationAdminUsers.contains(idUser)) {
			return true;
		}
		return false;
	}

	/**** get all admin and integration users ****/
	public static Set<String> generateIntAdminUsers() {
		Set<String> set_Result = new Set<String>();
		for (User us : map_UserIdToUserMap.values()) {
			if (us.UserRoleId != null && us.UserRole != null && (us.UserRole.Name.containsIgnoreCase(LABEL_INTEGRATION) || us.UserRole.Name.containsIgnoreCase(LABEL_ADMIN))) {
				set_Result.add(us.Id);
			}

			if (us.ProfileId != null && us.Profile.Name != null && (us.Profile.Name.containsIgnoreCase(LABEL_INTEGRATION) || us.Profile.Name.containsIgnoreCase(LABEL_ADMIN))) {
				set_Result.add(us.Id);
			}
		}
		return set_Result;
	}

	/**
	 * @author      Pradeep Chary
	 * @description Get Ardius users into a set
	 * @return      `Set<String>`
	 **/
	public final static Set<String> setArdiusUsers {
		get {
			if (setArdiusUsers == null) {
				return generateArdiusUsers();
			}
			return setArdiusUsers;
		}
	}

	public static Boolean isArdiusUser(Id idUser) {
		if (setArdiusUsers.contains(idUser)) {
			return true;
		}
		return false;
	}

	/**** get all Ardius users ****/
	public static Set<String> generateArdiusUsers() {
		Set<String> set_UserIds = new Set<String>();
		for (User objUser : map_UserIdToUserMap.values()) {
			if (objUser.UserRoleId != null && objUser.UserRole != null && (objUser.UserRole.Name.containsIgnoreCase(LABEL_ARDIUS) || objUser.UserRole.Name.containsIgnoreCase(LABEL_ARDIUSTEAM))) {
				set_UserIds.add(objUser.Id);
			}

			if (objUser.ProfileId != null && objUser.Profile.Name != null && (objUser.Profile.Name.containsIgnoreCase(LABEL_ARDIUS) || objUser.Profile.Name.containsIgnoreCase(MARKETO_PROFILE))) {
				set_UserIds.add(objUser.Id);
			}
		}
		return set_UserIds;
	}

	/**
	 * @author      Sandeep Golla
	 * @description Get specific Integration users into a set
	 * @return      `Set<String>`
	 **/
	public static Set<String> setIntegrationUsers {
		get {
			if (setIntegrationUsers == null) {
				Set<String> set_Result = new Set<String>();
				for (User us : map_UserIdToUserMap.values()) {
					if (String.isNotBlank(us.Name) && (us.Name.containsIgnoreCase(LABEL_WORKATO) || us.Name.containsIgnoreCase(LABEL_PGUSTO) || us.Name.containsIgnoreCase(LABEL_APIHEROKU) || us.Name.containsIgnoreCase(LABEL_APIINTEGRATION))) {
						set_Result.add(us.Id);
					}
				}
				setIntegrationUsers = set_Result;
			}
			return setIntegrationUsers;
		}
		set;
	}

	/**
	 * @author      Sandeep Golla
	 * @description Check if the user in the Specific Integrations
	 * @parm        `idUser` user record Id
	 * @return      `Boolean` true or false
	 **/
	public static Boolean isIntgUser(Id idUser) {
		if (setIntegrationUsers.contains(idUser)) {
			return true;
		}
		return false;
	}

	/**
	 * @description Get specific Admin users into a set
	 * @return      `Set<String>`
	 **/
	public static Set<String> setAdminUsers {
		get {
			if (setAdminUsers == null) {
				Set<String> set_Result = new Set<String>();
				for (User us : map_UserIdToUserMap.values()) {
					if (us.ProfileId != null && us.Profile.Name != null && (us.Profile.Name.containsIgnoreCase(LABEL_INTEGRATION) || us.Profile.Name.containsIgnoreCase(LABEL_ADMIN))) {
						set_Result.add(us.Id);
					}
				}
				setAdminUsers = set_Result;
			}
			return setAdminUsers;
		}
		set;
	}

	/**
	 * @description Check if the user in the Specific Admins
	 * @parm        `idUser` user record Id
	 * @return      `Boolean` true or false
	 **/
	public static Boolean isAdminUser(Id idUser) {
		if (setAdminUsers.contains(idUser)) {
			return true;
		}
		return false;
	}

	public static String getCurrentUserRoleName() {
		return getCurrentOwnerRoleName(UserInfo.getUserId());
	}

	public static User getOwnerUsrInfo(Id idOwner) {
		if (map_UserIdToUserMap.size() > 0 && map_UserIdToUserMap.containsKey(idOwner)) {
			return map_UserIdToUserMap.get(idOwner);
		}
		return null;
	}

	public static Id getUserRoleId(String strRoleName) {
		UserRole objUserRole = map_NameToUserRole.containsKey(strRoleName) ? map_NameToUserRole.get(strRoleName) : null;
		if (objUserRole != null) {
			return objUserRole.Id;
		}

		return null;
	}

	public static String getCurrentOwnerRoleName(Id idOwnUserId) {
		User objCrntUsr = getOwnerUsrInfo(idOwnUserId);
		if (objCrntUsr != null && objCrntUsr.UserRoleId != null) {
			return objCrntUsr.UserRole.Name;
		}

		return '';
	}

	/**
	 * @author      Deepika Saini
	 * @description Update the Benefit Order And Carrier Order when a ticket is opend for Inactive Users
	 * @parm        `set_UserIds` set of user Ids
	 * @return      NA
	 **/
	public static void updateRequireRoutingOnBOCO(Set<Id> set_UserIds) {
		BenefitOrderHelper.SkipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		Set<Id> set_COIds = new Set<Id>();
		Set<Id> set_BOIds = new Set<Id>();
		Set<String> set_SubTeams = new Set<String>{ TicketUtil.TICKET_ROLE_FULFILLMENT };
		List<Carrier_Order__c> list_COsToUpdate = new List<Carrier_Order__c>();
		List<Benefit_Order__c> list_BOsToUpdate = new List<Benefit_Order__c>();
		List<Ticket__c> list_OpenTickets = [
			SELECT Id, Sub_Team__c, Status__c, OwnerId, Carrier_Order__c, Benefit_Order__c, Carrier_Order__r.Requires_Routing__c
			FROM Ticket__c
			WHERE OwnerId IN :set_UserIds AND Status__c != :TicketUtil.TICKET_STATUS_CLOSED AND Sub_Team__c IN :set_SubTeams
		];

		for (Ticket__c objTicket : list_OpenTickets) {
			if (objTicket.Sub_Team__c == TicketUtil.TICKET_ROLE_FULFILLMENT && objTicket.Carrier_Order__r.Requires_Routing__c != true) {
				set_COIds.add(objTicket.Carrier_Order__c);
			}
		}

		if (!set_COIds.isEmpty()) {
			for (Id idCO : set_COIds) {
				Carrier_Order__c objCO = new Carrier_Order__c(Id = idCO);
				objCO.Requires_Routing__c = true;
				list_COsToUpdate.add(objCO);
			}
			update list_COsToUpdate;
		}

		BenefitOrderHelper.SkipTrigger = false;
		CarrierOrderTriggerHelper.skipTrigger = false;
	}

	/**
	 * @author      Bhagat Singh
	 * @description Get specific MOps Integration user Id into a set
	 * @return      Set<String>
	 **/
	public static Set<Id> setMOpsIntegrationUsers {
		get {
			if (setMOpsIntegrationUsers == null) {
				Set<Id> set_Result = new Set<Id>();
				for (User objUser : map_UserIdToUserMap.values()) {
					if (
						String.isNotBlank(objUser.Name) &&
						(objUser.Name.containsIgnoreCase(LABEL_WORKATO) ||
						objUser.Name.containsIgnoreCase(LABEL_RPA_AUTOMATION) ||
						objUser.Name.containsIgnoreCase(LABEL_APIHEROKU))
					) {
						set_Result.add(objUser.Id);
					}
				}
				setMOpsIntegrationUsers = set_Result;
			}
			return setMOpsIntegrationUsers;
		}
		set;
	}

	/**
	 * @description Get specific user role ids into a set based on role names passed
	 * @return      Set<String> - set of user role ids
	 **/
	public static Set<String> getUserRoleIds(Set<String> set_StrRoleNames) {
		Set<String> set_StrRoleIds = new Set<String>();
		for (String strRoleName : set_StrRoleNames) {
			UserRole objUserRole = map_NameToUserRole.containsKey(strRoleName) ? map_NameToUserRole.get(strRoleName) : null;
			if (objUserRole != null) {
				set_StrRoleIds.add(objUserRole.Id);
			}
		}
		if (!set_StrRoleIds.isEmpty()) {
			return set_StrRoleIds;
		}
		return null;
	}
}