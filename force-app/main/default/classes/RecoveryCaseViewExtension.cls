public class RecoveryCaseViewExtension {
	public Case theCase { get; private set; }
	public List<String> userRoleList { get; private set; }
	public boolean isFullAccess { get; private set; }
	public boolean isAdmin { get; private set; }
	public String strEventType { get; set; }

	public RecoveryCaseViewExtension(ApexPages.StandardController controller) {
		theCase = (Case) controller.getRecord();
		if (theCase != null && String.isNotBlank(theCase.Id)) {
			theCase = [
			SELECT
				Id,
				SuppliedEmail,
				Description,
				Status,
				Recovery_Case_ID__c,
				Payment_Investigation_ID__c,
				Event_ID__c,
				AccountId,
				Account.ZP_Company_Id__c,
				Event_Type__c,
				Recovery_Status__c,
				Contact.ZP_User_Id__c,
				Initial_Recovery_Amount__c,
				Outstanding_Balance__c,
				Created_At_Date__c,
				Requires_Action__c,
				Reminder_Notification__c,
				Follow_Up_Date__c,
				Payment_Event__c,
				Bad_Debt__c,
				Bank_Error_Code__c,
				Expedite_Reason__c,
				Next_Steps__c
			FROM Case
			WHERE Id = :theCase.Id
			FOR UPDATE
			];
		}		

		userRoleList = new List<String>();
		if (theCase != null) {
			if (theCase.Event_Type__c != null && theCase.Event_Type__c == 'ContractorPayment') {
				strEventType = 'Contractor_Payment';
			} else
				strEventType = theCase.Event_Type__c;
		}
		for (ZP_User_Role__c role : [
			SELECT Id, User_Id__c, First_Name__c, Last_Name__c, Phone__c
			FROM ZP_User_Role__c
			WHERE Company_Id__c = :theCase.Account.ZP_Company_id__c AND Type__c IN ('Role::Signatory') AND User_Id__c != NULL AND User_Id__c != ''
		]) {
			if (role.phone__c != null) {
				String info = '';
				if (role.First_Name__c != null && role.First_Name__c != '') {
					info = role.First_Name__c;
				}
				if (role.Last_Name__c != null && role.Last_Name__c != '') {
					info = ' ' + role.Last_Name__c;
				}
				if (role.Phone__c != null && role.Phone__c != '') {
					info = ' (' + role.Phone__c + ')';
				}
			}
		}

		setAccessPermission(thecase.Contact.ZP_User_Id__c, theCase.SuppliedEmail);
	}

	private void setAccessPermission(string userId, string email) {
		list<ZP_User_Role__c> zpUserRoles;

		list<ZP_User__c> userList = new List<ZP_User__c>();
		if (userId == '' && email != '') {
			userList = [SELECT Id__c, Email__c, Deleted_At__c FROM ZP_User__c WHERE Email__c != null AND Email__c = :email];
			if (userList.size() > 0) {
				userId = userList.get(0).Id__c;
			}
		}

		map<string, boolean> companyVisePermissionMap = new Map<string, boolean>();
		isAdmin = false;
		if (userId != null) {
			for (ZP_User_Role__c roleRec : [
				SELECT id, User_Permissions__c, Company_Id__c, User_Id__c, Type__c
				FROM ZP_User_Role__c
				WHERE User_Id__c = :userId AND Company_Id__c != NULL AND Deleted_At__c = NULL
			]) {
				string companyUniqueKey = roleRec.Company_Id__c + roleRec.User_Id__c;

				if (roleRec.Type__c.indexOf('PayrollAdmin') > -1) {
					isAdmin = true;
				}

				if (roleRec.User_Permissions__c != null) {
					if (roleRec.User_Permissions__c.indexOf('full_access') > -1) {
						companyVisePermissionMap.put(companyUniqueKey, true);
					}
				}

				if (!companyVisePermissionMap.containsKey(companyUniqueKey)) {
					companyVisePermissionMap.put(companyUniqueKey, false);
				}
			}
		}

		integer fullAccessCount = 0;
		for (boolean permission : companyVisePermissionMap.values()) {
			if (permission) {
				fullAccessCount++;
			}
		}

		if (fullAccessCount == companyVisePermissionMap.keyset().size()) {
			isFullAccess = true;
		} else {
			isFullAccess = false;
		}
	}

	public pageReference SaveRecoveryCase() {
		theCase.OwnerId = UserInfo.getUserId();
		Database.SaveResult result = Database.update(theCase);
		if (result.success) {
			PageReference pgref = new PageReference('/apex/RecoveryCasePage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}
}