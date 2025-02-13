public without sharing class ViewOppRenewalCaseExtension {
	public Opportunity theOpportunity { get; private set; }
	public Case renewalCase { get; private set; }
	public List<Case> caseList { get; private set; }

	public ViewOppRenewalCaseExtension(ApexPages.StandardController controller) {
		theOpportunity = (Opportunity) controller.getRecord();
		caseList = [SELECT Id, CaseNumber, Opportunity__c FROM Case WHERE Opportunity__c = :theOpportunity.id AND RecordType.Name = 'Benefits Renewal Case' AND Origin = 'Hippo'];
        
		if (caseList.size() > 0) {
			renewalCase = caseList[0];
		} else {
			renewalCase = new Case();
		}
	}
}