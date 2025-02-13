@isTest
public class RelatedCasesTest {
	static testMethod void testMethod1() {
		Case cas = new Case(Status = 'New', Priority = 'Medium', Origin = 'Email');
		insert cas;

		Test.StartTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(cas);
		RelatedCases testAccPlan = new RelatedCases(sc);

		PageReference pageRef = Page.RelatedCasesOfContact; // Add your VF page Name here
		pageRef.getParameters().put('id', String.valueOf(cas.Id));
		Test.setCurrentPage(Page.RelatedCasesOfContact);
		testAccPlan.getCases();
		testAccPlan.getRelatedAccountBORCases();
		Test.StopTest();

		System.assertEquals(1, [SELECT COUNT() FROM case]);
	}
}