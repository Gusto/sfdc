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
        objCompanyAccount.BillingState = 'California';
        objCompanyAccount.ZP_Company_Overall_Status__c = 'Active';
        update objCompanyAccount;
		Test.stopTest();

        Account objAccQuery = [SELECT Id, Territory__c FROM Account WHERE Id = :objCompanyAccount.Id];
        System.assertEquals(true, String.isNotBlank(objAccQuery.Territory__c), 'Territory not assigned');
	}
}