/**
 * @description  Test sending lead to RingLead
 * @author       Aviinandaan Dutta
 * @date         02-29-2024
 **/
@isTest
public with sharing class SendLeadToRingLeadTest {
	/**
	 * @description Test sending lead to RingLead
	 **/
	@isTest
	static void testSendLeadToRingLead() {
		AccountTriggerHelper.skipTrigger = true;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('fnamelname@gusto.com')
			.setPhone('123456789')
			.setCompany('Routing company')
			.setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		insert objLead;

		Test.startTest();
		System.enqueueJob(new SendLeadToRingLead(new Map<Id, Lead>{ objLead.Id => objLead }));
		Test.stopTest();

		// assert if lead route count is updated
		Lead objLeadAssert = [SELECT Id, Lead_Route_Count__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(2, objLeadAssert.Lead_Route_Count__c, 'Lead route count not updated correctly');
	}
}