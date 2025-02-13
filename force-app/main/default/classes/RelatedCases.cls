public class RelatedCases {
	private Case cs;

	public RelatedCases(ApexPages.StandardController controller) {
		cs = (Case) controller.getRecord();
	}

	public List<Case> getCases() {
		//@Neha, September 15,2020 : Added CreatedDate field as a part of QSEHRA changes
		return [SELECT Id, CaseNumber, Subject, status, type, Status_Detail__c, Owner.name, CreatedDate FROM Case WHERE ContactId = :cs.ContactId AND ContactId != NULL];
	}

	public List<Case> getRelatedAccountBORCases() {
		cs = [SELECT Id, AccountId, contactId FROM Case WHERE id = :cs.id];
		return [SELECT Id, CaseNumber, Subject, status, type, Status_Detail__c, Owner.name, Account.id FROM Case WHERE AccountId = :cs.AccountId AND RecordType.Name LIKE '%BOR%'];
	}
}