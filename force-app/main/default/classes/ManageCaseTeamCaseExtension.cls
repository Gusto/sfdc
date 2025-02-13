public with sharing class ManageCaseTeamCaseExtension {
	public Case theCase { get; private set; }
	public Contact theContact { get; set; }
	public List<CaseTeamMember> caseTeamList { get; private set; }
	private static CaseTeamRole customerContactRole = [SELECT Id, Name FROM CaseTeamRole WHERE Name = 'Customer Contact'];
	public CaseTeamMember theMember { get; set; }
	public Id memberId { get; set; }

	public ManageCaseTeamCaseExtension(ApexPages.StandardController controller) {
		theCase = (Case) controller.getRecord();
		theCase = [SELECT id, Subject, ContactId, AccountId FROM Case WHERE id = :theCase.id];
		setCaseTeamList();
		theContact = new Contact();
		if (theCase.AccountId != null) {
			theContact.AccountId = theCase.AccountId;
		}
		theMember = new CaseTeamMember();
		theMember.ParentId = theCase.id;
		theMember.TeamRoleId = customerContactRole.Id;
	}

	public PageReference saveContact() {
		if (theContact.Email == null || theContact.Email == '') {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Email is required'));
			return null;
		}
		if (theContact.LastName == null || theContact.LastName == '') {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Last Name is required'));
			return null;
		}
		if (theContact.AccountId == null) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Account is required'));
			return null;
		}
		List<Contact> contactList = new List<Contact>([SELECT id, Name, Email FROM Contact WHERE email = :theContact.Email]);
		if (contactList.size() > 0) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Another contact ' + contactList[0].Name + ' exists with this email'));
			return null;
		}
		Database.SaveResult res = database.insert(theContact, false);
		if (res.isSuccess() == false) {
			String error = Utils.ConsolidateErrors(res.getErrors());
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, error));
			return null;
		}
		CaseTeamMember member = new CaseTeamMember();
		member.MemberId = theContact.id;
		member.ParentId = theCase.id;
		member.TeamRoleId = customerContactRole.Id;
		insert member;
		setCaseTeamList();
		theContact = new Contact();
		if (theCase.AccountId != null) {
			theContact.AccountId = theCase.AccountId;
		}
		return null;
	}

	public PageReference addMember() {
		Database.SaveResult res = database.insert(theMember, false);
		if (res.isSuccess() == false) {
			String error = Utils.ConsolidateErrors(res.getErrors());
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, error));
			return null;
		}

		setCaseTeamList();
		theMember = new CaseTeamMember();
		theMember.ParentId = theCase.id;
		theMember.TeamRoleId = customerContactRole.Id;
		return null;
	}

	public pageReference deleteCaseTeamMember() {
		if (memberId != null) {
			CaseTeamMember caseMember = new CaseTeamMember(id = memberId);
			delete caseMember;
			setCaseTeamList();
		}
		return null;
	}

	private void setCaseTeamList() {
		caseTeamList = new List<CaseTeamMember>([SELECT Id, Member.Name, Member.Email FROM CaseTeamMember WHERE ParentId = :theCase.id]);
	}
}