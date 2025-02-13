@isTest
public class ScheduleToCreateCOAgainstBOTest {
	static testMethod void testAsyncMethods() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
		opp1.StageName = 'Pending PR';
		opp1.Order_Generated__c = true;
		update opp1;

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', false);
		benefitOrdr1.Type__c = 'New to Gusto';
		insert benefitOrdr1;

		Carrier__c carrier1 = TestUtility.Carrier();

		Policy__c pol1 = TestUtility.createTestPolicy(opp1.Id, carrier1.Id, true, 'Test Policy1', null, false);
		pol1.Benefit_Type__c = 'Dental';
		pol1.Is_Selected__c = true;
		insert pol1;

		//insert new Configuration_Settings__c(Submission_Deadline_Days__c = 5);BBO-1937

		test.startTest();
		ScheduleToCreateCarrierOrderAgainstBO objCreateCarrierOrder = new ScheduleToCreateCarrierOrderAgainstBO();
		objCreateCarrierOrder.execute(null);
		test.stopTest();
	}
}