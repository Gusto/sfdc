/**
 * @description  Test Class for OpenCustomerHealthScoreController
 * @author       Debasmita Rawooth
 * @date         03-12-2024
 **/
@isTest
public with sharing class OpenCustomerHealthScoreControllerTest {
	@isTest
	public static void testOpenCHSPositive() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account CHS').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.CUSTOMER_SUCCESS_RT_ID)
			.setName('CS Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('New')
			.setCloseDate(System.today())
			.build();
		insert objOpportunity;

		Customer_Health__c objCustHealth = new TestDataFactory.CustomerHealthBuilder()
			.setCompanyId('1111111111')
			.setUpgradePropensity('medium upgrade propensity')
			.setHINPRank(0.5)
			.setChurnScore(0.2)
			.build();

		insert objCustHealth;

		Test.startTest();
		Id idCHSRecId = OpenCustomerHealthScoreController.getCHSRecordId(objOpportunity.Id);
		Customer_Health__c objCHSAssert = [SELECT Id, Name, Account__c FROM Customer_Health__c WHERE Id = :idCHSRecId];
		Test.stopTest();

		System.assertEquals(objOpportunity.AccountId, objCHSAssert.Account__c, 'CHS record Id is not fetched correctly.');
	}
	@isTest
	public static void testOpenCHSNegative() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account CHS').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.CUSTOMER_SUCCESS_RT_ID)
			.setName('CS Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('New')
			.setCloseDate(System.today())
			.build();
		insert objOpportunity;

		Test.startTest();
		Id idCHSRecId;
		try {
			idCHSRecId = OpenCustomerHealthScoreController.getCHSRecordId(objOpportunity.Id);
		} catch (Exception objEx) {
			//Testing exception scenario
		}
		Test.stopTest();

		System.assertEquals(idCHSRecId, null, 'Exception Handling did not work correctly');
	}
}