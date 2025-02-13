@isTest
public class OrderUtilsTest {
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

		Carrier_Order__c coRec = TestUtility.createTestCarrierOrder(carrier1.id, 'CarrierORderHandlerTest', benefitOrdr1.id, true);

		test.startTest();
		OrderUtils.createCarrierOrderAgainstBO();
		test.stopTest();
	}
	static testMethod void testTransactionTemplates() {
		Transition_to_Fulfillment__c objTTF = new Transition_to_Fulfillment__c();
		objTTF.Other_OE_Blocker__c = 'er_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__c\ntest\test\n';
		Set<String> setFieldnames = new Set<String>{ 'Other_OE_Blocker__c' };
		Map<String, Integer> mapTest = OrderUtils.setRowCountOfTextArea(objTTF, setFieldnames, new Map<String, Integer>());
		List<Transition_to_Fulfillment__c> lstTTF = new List<Transition_to_Fulfillment__c>();
		lstTTF.add(objTTF);
		Map<String, Map<String, Integer>> mapTest1 = OrderUtils.setRowCountForTextArea(lstTTF, setFieldnames, new Map<String, Map<String, Integer>>());

		Set<String> setlineOfCoverage = new Set<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'STD', 'LTD' };
		for (String objLine : setlineOfCoverage) {
			Set<String> set_getFields = OrderUtils.getTTQFieldsAsPerCOOrderAssignment(objLine);
		}
		String strFieldLabel = OrderUtils.getFieldAPIName('Account', 'Name');
	}
}