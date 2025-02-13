@isTest
private class UpdateOpportunityToClosedWonTest {
	static testMethod void myUnitTest() {
		Opportunity oppRec = TestUtility.BenefitsNewPlanOpportunity();

		ApexPages.currentPage().getParameters().put('id', oppRec.id);
		apexPages.standardController sc = new apexPages.standardController(oppRec);
		UpateOpportunityToClosedWonController controller = new UpateOpportunityToClosedWonController(sc);
		UpateOpportunityToClosedWonController.updateOpportunity();
		controller.queryOpportunityRecord();
		System.assert(controller.opportunityRec.StageName == 'STAGENAME');
		controller.backToOpportunity();
	}
}