public without sharing class AdminPermissions {
	/**
	 * Author: Alex
	 * Date: 9/11/2020
	 * Desc: Find Case Contact's ZP User Roles and put their User Permissions in a
	 * friendly to read list of strings
	 */
	@AuraEnabled
	public static List<String> queryAdminPerms(Id idCase) {
		String strSObjectType = idCase.getSObjectType().getDescribe().getName();
		if (strSObjectType.equals('LiveChatTranscript')) {
			idCase = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :idCase].CaseId;
		}

		Case objCase;
		List<String> list_Permissions = new List<String>();
		if (idCase != null) {
			objCase = [SELECT Id, Contact.ZP_User_Id__c, SuppliedEmail FROM Case WHERE Id = :idCase];
		}

		if (objCase != null) {
			String strUserId = '';
			String strEmail = '';

			if (objCase.Contact != null) {
				strUserId = objCase.Contact.ZP_User_Id__c;
			}
			if (objCase.SuppliedEmail != null) {
				strEmail = objCase.SuppliedEmail;
			}

			list<ZP_User__c> list_Users = new List<ZP_User__c>();

			//if no user id from contact record, look for a zp user where email matches case's supplied email
			//and get its id__c instead
			if (strUserId == '' && strEmail != '') {
				list_Users = [SELECT Id__c, Email__c, Deleted_At__c FROM ZP_User__c WHERE Email__c = :strEmail];
				if (list_Users.size() > 0) {
					strUserId = list_Users.get(0).Id__c;
				}
			}

			//build a running list of permissions from each zp user role
			if (String.isNotBlank(strUserId)) {
				List<String> list_AllPerms = new List<String>();
				for (ZP_User_Role__c roleRec : [SELECT Id, User_Permissions__c FROM ZP_User_Role__c WHERE User_Id__c = :strUserId AND Company_Id__c != NULL AND Deleted_At__c = NULL]) {
					if (roleRec.User_Permissions__c != null) {
						String strFormattedPerms = roleRec.User_Permissions__c.replace('_', ' ');
						list_AllPerms.addAll(strFormattedPerms.split(','));
					}
				}
				Set<String> set_Permissions = new Set<String>();

				//for each permission, capitalize first letters of each word
				List<String> list_PermElements = new List<String>();
				for (String strPerm : list_AllPerms) {
					list_PermElements = strPerm.split(' ');
					String strCapPerm = ' ';
					for (Integer i = 0; i < list_PermElements.size(); i++) {
						if (i == list_PermElements.size() - 1) {
							strCapPerm += list_PermElements[i].capitalize();
						} else
							strCapPerm += list_PermElements[i].capitalize() + ' ';
					}
					set_Permissions.add(strCapPerm);
				}
				list_Permissions.addAll(set_Permissions);
			}
		}

		return list_Permissions;
	}

	/**
	 * Author: Alex
	 * Date: 9/11/2020
	 * Desc: Get Case Contact's ZP User Roles and put their Role Names in a friendly to read
	 * list of strings
	 */
	@AuraEnabled
	public static List<String> queryUserRoles(Id idCase) {
		String strSObjectType = idCase.getSObjectType().getDescribe().getName();
		if (strSObjectType.equals('LiveChatTranscript')) {
			idCase = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :idCase].CaseId;
		}

		Case objCase;
		List<String> list_Roles;
		if (idCase != null) {
			objCase = [SELECT Id, Contact.ZP_User_Id__c, SuppliedEmail FROM Case WHERE Id = :idCase];
		}

		if (objCase != null) {
			String strUserId = '';
			String strEmail = '';

			if (objCase.Contact != null) {
				strUserId = objCase.Contact.ZP_User_Id__c;
			}
			if (objCase.SuppliedEmail != null) {
				strEmail = objCase.SuppliedEmail;
			}

			list<ZP_User__c> list_Users = new List<ZP_User__c>();

			//if no user id from contact record, look for a zp user where email matches case's supplied email
			//and get its id__c instead
			if (strUserId == '' && strEmail != '') {
				list_Users = [SELECT Id__c, Email__c, Deleted_At__c FROM ZP_User__c WHERE Email__c = :strEmail];
				if (list_Users.size() > 0) {
					strUserId = list_Users.get(0).Id__c;
				}
			}

			//build a running list of user roles from each zp user role
			if (String.isNotBlank(strUserId)) {
				Set<String> set_AllRoles = new Set<String>();
				for (ZP_User_Role__c roleRec : [SELECT Id, Role_Name__c FROM ZP_User_Role__c WHERE User_Id__c = :strUserId AND Company_Id__c != NULL AND Deleted_At__c = NULL]) {
					if (set_AllRoles.isEmpty()) {
						if (roleRec.Role_Name__c != null && String.isNotBlank(roleRec.Role_Name__c)) {
							set_AllRoles.add(roleRec.Role_Name__c);
						}
					} else {
						if (roleRec.Role_Name__c != null && String.isNotBlank(roleRec.Role_Name__c)) {
							set_AllRoles.add(' ' + roleRec.Role_Name__c);
						}
					}
				}
				list_Roles = new List<String>(set_AllRoles);
			}
		}

		return list_Roles;
	}
}