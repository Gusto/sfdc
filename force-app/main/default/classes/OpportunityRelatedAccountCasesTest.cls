@isTest
public class OpportunityRelatedAccountCasesTest {
	static testMethod void testMethod1() {
		Account acc = TestUtility.CompanyAccount();

		Opportunity opp = new Opportunity();
		opp.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		opp.AccountId = acc.id;
		insert opp;

		Case cas = new Case(Status = 'New', Priority = 'Medium', Origin = 'Email', AccountId = acc.id);
		insert cas;

		Test.StartTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(opp);
		OpportunityRelatedAccountCases testAccPlan = new OpportunityRelatedAccountCases(sc);

		PageReference pageRef = Page.OpportunityRelatedAccountCasesPage; // Add your VF page Name here
		pageRef.getParameters().put('id', String.valueOf(opp.Id));
		Test.setCurrentPage(Page.OpportunityRelatedAccountCasesPage);
		List<Case> caseList = testAccPlan.getCases();
		Test.StopTest();

		System.assertEquals(1, caseList.size());
	}
}