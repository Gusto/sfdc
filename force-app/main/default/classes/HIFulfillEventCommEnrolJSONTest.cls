@isTest
private class HIFulfillEventCommEnrolJSONTest {
	static testMethod void testMethod1() {
		Test.StartTest();
		HIFulfillmentEventCommuterEnrolmentJSON obj = new HIFulfillmentEventCommuterEnrolmentJSON();
		Test.stopTest();

		System.assertEquals(null, obj.benefits_url, 'The benefits_url parameter should be null.');
		System.assertEquals(null, obj.commuter_benefit, 'The commuter_benefit parameter should be null.');
		System.assertEquals(null, obj.company, 'The company parameter should be null.');
	}
}