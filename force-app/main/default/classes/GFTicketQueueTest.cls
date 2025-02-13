@isTest
private class GFTicketQueueTest {
	@isTest
	static void testGFTicketQueue() {
		GF_Ticket__c gfTicket = new TestDataFactory.GFTicketBuilder().setExternalId('11111111111111').setCompanyId('222222222222').setProcessingState('Error').build();
		insert gfTicket;

		List<GF_Ticket__c> gfTicketList = new List<GF_Ticket__c>();
		gfTicketList.add(gfTicket);

		Test.startTest();
		System.enqueueJob(new GFTicketQueue(gfTicketList));
		Test.stopTest();

		gfTicket = [SELECT Id, Processing_State__c FROM GF_Ticket__c WHERE id = :gfTicket.Id];
		System.assertNotEquals(IntegrationUtils.PROCESSED_STATE, gfTicket.Processing_State__c, 'Processing State should not match.');
	}
}