public with sharing class EmailCaseTeamExtension {
	public Case objCase { get; private set; }
	public String strToEmail { get; private set; }
	public String strCCEmails { get; private set; }
	public String strFromEmails { get; private set; }
	public static final String OWD_EMAIL_RENEWALS = 'renewals@gusto.com, connect-broker@gusto.com';
	public static final String OWD_EMAIL_NEWPLANS = 'newplans@gusto.com';
	public static final String OWD_EMAIL_BORTRANSFER = 'benefits-onboarding@gusto.com';

	public EmailCaseTeamExtension(ApexPages.StandardController controller) {
		objCase = (Case) controller.getRecord();
		strToEmail = '';
		objCase = [
			SELECT Id, SuppliedEmail, Carrier__c, RecordType.Name, Carrier__r.Submission_Email__c, Contact.Email, Order__c, Order__r.Agent_Email__c, (SELECT Id, ParentId, MemberId FROM TeamMembers)
			FROM Case
			WHERE Id = :objCase.id
		];
		strFromEmails = getFromEmailAddress(objCase);
		strToEmail = objCase.Contact.Email != null ? objCase.Contact.Email : '';
		strCCEmails = objCase.Order__c != null ? objCase.Order__r.Agent_Email__c : '';
		if (objCase.SuppliedEmail != null && strToEmail.indexOf(objCase.SuppliedEmail) < 0) {
			strToEmail = (strToEmail == '') ? objCase.SuppliedEmail : strToEmail + ';' + objCase.SuppliedEmail;
		}

		Set<Id> set_MemberIds = new Set<Id>();
		for (CaseTeamMember objCaseTeamMember : objCase.TeamMembers) {
			set_MemberIds.add(objCaseTeamMember.MemberId);
		}

		for (Contact objContact : [SELECT Id, Email FROM Contact WHERE Id IN :set_MemberIds]) {
			if (objContact.Email != null && strToEmail.indexOf(objContact.Email) < 0) {
				strToEmail = (strToEmail == '') ? objContact.Email : strToEmail + ';' + objContact.Email;
			}
		}
	}

	public static String getFromEmailAddress(Case objCase) {
		String strFromEmailAddress = '';
		if (objCase.RecordType.Name.indexOf('New Plan') > -1) {
			strFromEmailAddress = OWD_EMAIL_NEWPLANS;
		} else if (objCase.RecordType.Name.indexOf('Renewal') > -1 || objCase.RecordType.Name.indexOf('Change') > -1) {
			strFromEmailAddress = OWD_EMAIL_RENEWALS;
		} else if (objCase.RecordType.Name.indexOf('Benefits BoR') > -1) {
			strFromEmailAddress = OWD_EMAIL_BORTRANSFER;
		}

		return strFromEmailAddress;
	}
}