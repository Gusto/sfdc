/**
 * @name         TTQServiceTest
 * @author       Gireesh
 * @date         10 August 2020
 * @description  Test class to fro TTQService
 * @revisions    Date ------------ Name ------------ Comments
 */
@isTest
private class TTQServiceTest {
	@testSetup
	private static void createTestData() {
		AccounttriggerHelper.skiptrigger = true;
		List<Account> list_Accounts = new List<Account>();
		list_Accounts.add(new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build());
		insert list_Accounts;
		Opportunity objOpp = TestUtility.createOpportunity('Benefits New Plan', list_Accounts[0].Id);
		Benefit_Order__c objBenefitOrder = TestUtility.createTestBenefitOrder('New Plan', objOpp.Id, 'Benefit Order', true);
		Transition_to_Fulfillment__c objTTQ = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setRecordTypeId(cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan'))
			.setBenefitsPointOfContact('Test')
			.setAddressNotes('Test')
			.setOpportunityId(objOpp.Id)
			.setRenewalException('Yes')
			.setRenewalDate(Date.today())
			.setMedicalNewCarrier('aa')
			.setDentalCarrier('aa')
			.setVisionCarrier('aa')
			.setLiDiCarrier('aa')
			.setFSAHSA401K('aa')
			.build();

		TransitiontoFulfilmentTriggerHelper.SkipTrigger = true;
		insert objTTQ;
	}
	@isTest
	private static void testTTQService() {
		Transition_to_Fulfillment__c objTTQ = [SELECT id FROM Transition_to_Fulfillment__c LIMIT 1];
		RestRequest objRequest = new RestRequest();
		objRequest.requestUri = 'https://my.salesforce.com/services/apexrest/TTQService/?sf_record_id=' + objTTQ.Id;
		objRequest.addParameter('sf_record_id', objTTQ.Id);
		objRequest.httpMethod = 'GET';
		RestContext.request = objRequest;
		Test.startTest();
		String strTtq = TTQService.getTTQ();
		Test.stopTest();
		System.assertEquals(true, strTtq.contains('sf_record_id'), 'TTQ service failed');
	}

	@isTest
	private static void testTTQService_negative() {
		RestRequest objRequest = new RestRequest();
		objRequest.requestUri = 'https://my.salesforce.com/services/apexrest/TTQService/?sf_record_id=';
		objRequest.httpMethod = 'GET';
		RestContext.request = objRequest;
		try {
			Test.startTest();
			String strTtq = TTQService.getTTQ();
			Test.stopTest();
		} catch (Exception objException) {
			System.assertEquals(true, objException.getMessage().contains('Salesforce record Id is missing'), 'TTQ service returning result without record id');
		}
	}
}