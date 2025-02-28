/**
 * @description  Test class for testing territory assignment rules
 * @author       Praveen Sethu
 * @see          AccountTriggerHelperTest
 **/
@isTest
public without sharing class RunTerritoryRulesTest {
	// Test method to test territory assignment rules - SellAllData is intentionally enabled to see territory models in the org
	@isTest(SeeAllData=true)
	static void testTerritoryAssignmentRules() {
		Test.setMock(HttpCalloutMock.class, new RingLeadMockResponseTest());
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();
		insert objCompanyAccount;

		Test.startTest();
		objCompanyAccount.BillingCountry = 'United States';
		objCompanyAccount.BillingState = 'Colorado';
		objCompanyAccount.Benefits_Effective_Date__c = Date.today();
		objCompanyAccount.Medical_Deductions__c = true;
		update objCompanyAccount;
		Test.stopTest();

		Account objAccQuery = [SELECT Id, Territory__c FROM Account WHERE ZP_Company_ID__c = 'testhirouting'];
		System.assertEquals(true, String.isNotBlank(objAccQuery.Territory__c), 'Territory not assigned');
	}
}