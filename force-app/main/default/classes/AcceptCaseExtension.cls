public class AcceptCaseExtension {
	public Case theCase { get; private set; }

	public AcceptCaseExtension(ApexPages.StandardController controller) {
		theCase = (Case) controller.getRecord();
		theCase = [
			SELECT Id, OwnerId, Subject, Description, Reason, Status, Status_Detail__c, Requires_Action__c, Zendesk_Id__c
			FROM Case
			WHERE Id = :theCase.Id
			FOR UPDATE
		];
	}

	public pageReference backToCase() {
		PageReference pgref = new PageReference('/' + theCase.id);
		return pgref;
	}

	public pageReference acceptCase() {
		String caseOwnerId = theCase.OwnerId;
		if (caseOwnerId.indexOf('00G') < 0) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Case is not owned by a queue'));
			return null;
		}
		theCase.OwnerId = UserInfo.getUserId();
		Database.SaveResult result = Database.update(theCase);
		if (result.success) {
			PageReference pgref = new PageReference('/' + theCase.id);
			return pgref;
		} else {
			PageReference pgref = new PageReference('/apex/AcceptCaseViewPage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		}
	}
}