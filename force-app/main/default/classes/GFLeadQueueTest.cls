/**
 * @name         GFLeadQueueTest
 * @author       David (Dato) Tsamalashvili
 * @date         05/12/2022
 * @description  New Refactored GFLeadQueueTest Class
 * @see GFLeadQueue
 **/
@isTest
public class GFLeadQueueTest {
	@isTest
	static void testGfLeadQueue() {
		GFLeadTriggerHelper.queue = false;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('Test')
			.setLastName('Test')
			.setEmail('test.test@gusto.com')
			.setCompany('Test')
			.setLeadSource('Web')
			.build();
		insert objLead;

		Test.startTest();
		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test')
			.setLName('test')
			.setCompanyName('Test')
			.setEmail('test.test@gusto.com')
			.setSessionId('12345')
			.setVisitorId('12345')
			.setProcessingState('Queued')
			.setSource('Web')
			.build();
		insert objGFLead;

		GF_Lead__c objGFLeadAssert = [SELECT Id, Processing_State__c FROM GF_Lead__c WHERE Id = :objGFLead.id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objGFLeadAssert.Processing_State__c);
		Test.stopTest();
	}
}