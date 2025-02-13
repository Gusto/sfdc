public with sharing class EmailCarrierRecoveryCaseExtension {
	public Case theCase { get; private set; }
	public String email { get; private set; }

	public EmailCarrierRecoveryCaseExtension(ApexPages.StandardController controller) {
		email = '';
		theCase = (Case) controller.getRecord();
		theCase = [SELECT Id, Carrier__c, carrier__r.Submission_Email__c, Contact.Email, AccountId, (SELECT Id, ParentId, MemberId FROM TeamMembers) FROM Case WHERE Id = :theCase.id];
		email = theCase.Contact.Email != null ? theCase.Contact.Email : null;

		Set<Id> setMemberIds = new Set<Id>();
		for (CaseTeamMember objCaseTeamMember : theCase.TeamMembers) {
			setMemberIds.add(objCaseTeamMember.MemberId);
		}

		for (Contact objContact : [SELECT Id, Email FROM Contact WHERE Id IN :setMemberIds]) {
			if (objContact.Email != null) {
				if (email.indexOf(objContact.Email) > -1) {
					continue;
				}
				email = (email == '') ? objContact.Email : email + ';' + objContact.Email;
			}
		}
		Set<String> userIdSet = new Set<String>();
		for (ZP_User_Role__c role : [
			SELECT Id, User_Id__c
			FROM ZP_User_Role__c
			WHERE Company_Id__c = :theCase.AccountId AND Type__c IN ('Role::PayrollAdmin', 'Role::Signatory') AND User_Id__c != NULL AND User_Id__c != ''
		]) {
			userIdSet.add(role.User_Id__c);
		}
		for (ZP_User__c user : [SELECT Email__c FROM ZP_User__c WHERE Id__c IN :userIdSet AND Email__c != NULL AND Email__c != '']) {
			if (email.indexOf(user.Email__c) > -1) {
				continue;
			}
			email = (email == '') ? user.Email__c : email + ';' + user.Email__c;
		}
	}
}