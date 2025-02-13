public class OpportunityRelatedAccountCases {
	private Opportunity opp;

	public OpportunityRelatedAccountCases(ApexPages.StandardController controller) {
		opp = (Opportunity) controller.getRecord();
		opp = [SELECT Id, AccountId FROM Opportunity WHERE id = :opp.Id];
	}

	public List<Case> getCases() {
		return [SELECT Id, CaseNumber, Subject, status, type, Status_Detail__c, Owner.name FROM Case WHERE AccountId = :opp.AccountId AND AccountId != NULL];
	}
}