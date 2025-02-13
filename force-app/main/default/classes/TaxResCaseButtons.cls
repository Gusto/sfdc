/**
 * @name             TaxResCaseButtons.cls
 * @author           Bhagat Singh
 * @date             July-6-2021
 * @description      methods for Care Lightning components
 * @Covered class    TaxResCaseButtonsTest
 * @revisions        Date ------------ Name ------------ Comments
 **/
public with sharing class TaxResCaseButtons {
	public static String TAXRES_ACC_SPECIALIST_GROUP_NAME = 'TaxRes Change Account Specialist Group';
	public static Set<String> set_AllNestedGroupMemberIds = new Set<String>();
	public static List<GroupMember> list_GroupMembers;
	public static List<String> list_ChangeAccSpecialistGroup = new List<String>{ TAXRES_ACC_SPECIALIST_GROUP_NAME };
	public static string GROUP_NAME_TAXRES_VIEW_TACKLEBOX = 'TaxRes View Tacklebox';
	public static string GROUP_TYPE = 'Regular';
	/**
	 * Desc: query case based on an id
	 */
	@AuraEnabled
	public static Case queryCase(String strId) {
		return CareCaseButtons.queryCase(strId);
	}

	/**
	 * @description Check if the user is added to the tax res tacklebox view Group or not
	 * @author      AKS
	 * @param       NA
	 * @return      Boolean
	 **/
	@AuraEnabled
	public static Boolean getMemberToAccessTackleLink() {
		Set<Id> set_UserIdsFromGroup = new Set<Id>();
		Set<Id> set_RoleIdsFromGroup = new Set<Id>();
		Map<String, Set<Id>> map_AllTackleboxMembers = new Map<String, Set<Id>>();
		map_AllTackleboxMembers = GlobalQueryHelper.getGroupMembersByName(GROUP_NAME_TAXRES_VIEW_TACKLEBOX);
		if (map_AllTackleboxMembers != null && map_AllTackleboxMembers.size() > 0) {
			// This will give you the roles/groups present in the Tacklebox group.
			set_RoleIdsFromGroup = map_AllTackleboxMembers?.get('00G');
			// This will give you the users present in the Tacklebox group.
			set_UserIdsFromGroup.addAll(map_AllTackleboxMembers?.get('005'));
		}

		if (set_UserIdsFromGroup != null && set_UserIdsFromGroup.size() > 0 && set_UserIdsFromGroup.contains(UserInfo.getUserId())) {
			return true;
		} else {
			// This will give you the users present in the roles that are present in a group.
			AggregateResult[] objResult = [
				SELECT COUNT(Id) usercount
				FROM User
				WHERE UserRoleId IN (SELECT RelatedId FROM Group WHERE Type = 'Role' AND Id IN :set_RoleIdsFromGroup) AND Id = :UserInfo.getUserId()
			];
			Object objUserCount = objResult?.get(0).get('usercount');

			if (objUserCount != null && (Integer) objUserCount > 0) {
				return true;
			} else {
				return false;
			}
		}
	}

	/**
	 * Desc: query user based on an logged in user id
	 */
	@AuraEnabled
	public static User getLoggedInUser() {
		return [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
	}

	@AuraEnabled
	public static Boolean canUserChangeOwner() {
		List<String> list_PublicGroups = new List<String>();
		String strChangeOwnerGroups = Label.Change_Owner_Groups;
		if (String.isNotBlank(strChangeOwnerGroups)) {
			list_PublicGroups = strChangeOwnerGroups.split(',');
		}

		return checkUserInPublicGroup(list_PublicGroups);
	}

	/**
	 * Desc: method to check if the logged in user can change Account Specialist
	 */
	@AuraEnabled
	public static Boolean canUserChangeAccSpecialist() {
		return checkUserInPublicGroup(list_ChangeAccSpecialistGroup);
	}

	/**
	 * Desc: method that returns whether logged in user is a group member or not
	 */
	private static Boolean checkUserInPublicGroup(List<String> list_PublicGroups) {
		List<GroupMember> list_groupMember = [SELECT Id, Group.Name FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId() AND Group.Name IN :list_PublicGroups];
		if (!list_groupMember.isEmpty()) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Desc: change the case owner
	 */
	@AuraEnabled
	public static void changeOwner(String strCaseId, String strOwnerId) {
		CareCaseButtons.changeOwner(strCaseId, strOwnerId);
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = new Case(Id = strCaseId);
		objCase.Owner_Last_Modified_By__c = UserInfo.getName() + ' - ' + System.now();
		update objCase;
	}

	/**
	 * Desc: update the Case's Account
	 */
	@AuraEnabled
	public static void updateAccount(String strCaseId, String strAccountId) {
		CareCaseButtons.updateAccount(strCaseId, strAccountId);
	}

	/**
	 * Desc: update the case's contact
	 */
	@AuraEnabled
	public static void updateContact(String strCaseId, String strContactId) {
		CareCaseButtons.updateContact(strCaseId, strContactId);
	}

	/**
	 * Desc: update the Case's Agency Info
	 */
	@AuraEnabled
	public static void updateAgencyInfo(String strCaseId, String strAgencyInfoId) {
		if (String.isNotBlank(strCaseId) && String.isNotBlank(strAgencyInfoId)) {
			Case objCase = new Case(Id = strCaseId, Agency_Information__c = strAgencyInfoId);
			update objCase;
		}
	}

	/**
	 * Desc: set the record type on a Case, set to open, and blank our Closed Reason
	 */
	@AuraEnabled
	public static void updateCaseOnUnmerge(String strCaseId, String strRecordTypeName, Boolean blnIsClosed) {
		CareCaseButtons.updateCaseOnUnmerge(strCaseId, strRecordTypeName, blnIsClosed);
	}
}