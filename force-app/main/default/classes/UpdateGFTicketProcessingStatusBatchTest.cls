/**
 * @name         : UpdateGFTicketProcessingStatusBatchTest
 * @date         : 08-30-2023
 * @description  : Handle test cases to update GF Ticket process state error records to queued
 **/
@isTest
public class UpdateGFTicketProcessingStatusBatchTest {
	/**
	 * @description Setup Test Data
	 **/
	@testSetup
	static void setupData() {
		GF_Ticket__c objGFTicket = new TestDataFactory.GFTicketBuilder()
			.setExternalId('11111111111114')
			.setCompanyId('222222222222')
			.setSubject(GFTicketUtil.ADDRESS_CHANGE_TICKET_TYPE)
			.setEmail('test@test.com')
			.setTicketType(GFTicketUtil.ADDRESS_CHANGE_TICKET_TYPE)
			.setProcessingState('Error')
			.build();

		GFTicketTriggerHelper.skipTrigger = true;

		insert objGFTicket;
	}

	/**
	 * @description Update Error GF Ticket records to queue postivie case
	 **/
	@isTest
	static void testUpdateGFTicketProcessingStateToQueuePositive() {
		GFTicketTriggerHelper.skipTrigger = true;
		Test.startTest();
		Database.executeBatch(new UpdateGFTicketProcessingStatusBatch());
		Test.stopTest();

		for (GF_Ticket__c objGFTicket : [
			SELECT Id, Processing_State__c
			FROM GF_Ticket__c
		]) {
			System.assertEquals('Queued', objGFTicket.Processing_State__c, 'Processing state should be queued');
		}
	}

	/**
	 * @description Update Error GF Ticket records to queue negative case
	 **/
	@isTest
	static void testUpdateGFTicketProcessingStateToQueueNegative() {
		GFTicketTriggerHelper.skipTrigger = false;
		GFTicketTriggerHandler.blnTestException = true;
		Test.startTest();
		Database.executeBatch(new UpdateGFTicketProcessingStatusBatch());
		Test.stopTest();

		System.assertEquals([SELECT Id FROM Exception_Log__c].size(), 1, 'There should be a exceptionlog record');
	}
}