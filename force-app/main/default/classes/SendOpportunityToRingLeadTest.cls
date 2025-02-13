/**
 * @description  Test sending opportunity to RingLead
 * @author       Praveen Sethu
 **/
@isTest
public with sharing class SendOpportunityToRingLeadTest {
	/**
	 * @description Test sending opportunity to RingLead
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testSendOpportunityToRingLead() {
		RingLead_Routing_Credentials__c objCredential = new RingLead_Routing_Credentials__c(Send_Opportunity_Endpoint__c = 'https://ringlead.sendopportunity.com/send', API_Token__c = 'api-token');
		insert objCredential;

		AccountTriggerHelper.skipTrigger = true;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());

		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('123456789').build();
		insert objCompAccount;

		Opportunity objCompanyOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setAccountId(objCompAccount.Id)
			.setCloseDate(Date.today())
			.setStage(OpportunityUtil.MQL_STAGE)
			.setName('Payroll Opportunity')
			.build();
		insert objCompanyOppty;

		Test.startTest();
		new SendOpportunityToRingLead(new Set<Id>{ objCompanyOppty.Id }).sendOpportunityToRingLead();
		Test.stopTest();

		// assert if opportunity got updated
		Opportunity objOpportunityAssert = [SELECT Id, Name FROM Opportunity WHERE Id = :objCompanyOppty.Id];
		System.assertEquals('Opportunity Routed Successfully', objOpportunityAssert.Name);
	}
}