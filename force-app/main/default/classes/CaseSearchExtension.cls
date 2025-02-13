public with sharing class CaseSearchExtension {
	public Case theCase { get; private set; }
	public String searchString { get; set; }
	public List<Case> caseList { get; private set; }
	public String relatedCase { get; set; }

	public CaseSearchExtension(ApexPages.StandardController controller) {
		relatedCase = '';
		caseList = new List<Case>();
		theCase = (Case) controller.getRecord();
		theCase = [SELECT Id, Carrier__c, carrier__r.Submission_Email__c, Contact.Email FROM Case WHERE Id = :theCase.id];
	}

	public PageReference searchCase() {
		caseList = new List<Case>(
			[SELECT id, Subject, CaseNumber, AccountId, Account.Name, ContactId, Contact.Name, Type, Status FROM Case WHERE subject LIKE :searchString + '%' ORDER BY CaseNumber LIMIT 1000]
		);
		return null;
	}

	public PageReference linkCase() {
		if (Apexpages.currentPage().getParameters().get('relatedCase') != null && Apexpages.currentPage().getParameters().get('relatedCase') != '') {
			theCase.Related_Case__c = Apexpages.currentPage().getParameters().get('relatedCase');
			update theCase;
		}
		return null;
	}
}