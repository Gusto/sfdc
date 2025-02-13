/**
 * @description  Test sending account to RingLead
 * @author       Praveen Sethu
 * @date         11-11-2022
 **/
@isTest
public with sharing class SendAccountToRingLeadTest {
	/**
	 * @description Test sending account to RingLead
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testSendLeadToRingLead() {
		RingLead_Routing_Credentials__c objCredential = new RingLead_Routing_Credentials__c(Send_Account_Endpoint__c = 'https://ringlead.sendaccount.com/send', API_Token__c = 'api-token');
		insert objCredential;

		AccountTriggerHelper.skipTrigger = true;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Test Reseller Account 1').build();
		insert objAccount;

		Test.startTest();
		SendAccountToRingLead.sendAccountToRingLead(new List<SendAccountToRingLead.RequestWrapper>{ new SendAccountToRingLead.RequestWrapper(objAccount.Id) });
		Test.stopTest();

		// assert if account route count is updated
		Account objAccAssert = [SELECT Id, Account_Route_Count__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(2, objAccAssert.Account_Route_Count__c);
	}
}