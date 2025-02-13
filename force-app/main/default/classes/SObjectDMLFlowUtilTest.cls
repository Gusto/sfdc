/**
 * @description Test class for SObjectDMLFlowUtil
 * @author      Ajay Krishna P U
 * @since       2024-03-26
 */
@isTest
public with sharing class SObjectDMLFlowUtilTest {
	/**
	 * @description Set up data
	 */
	@testSetup
	static void setup() {
		//create company account
		Account compAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Employer Account').setZPCompanyId('1234567890').build();
		insert compAccount;
	}

	/**
	 * @description Test do DML Operation
	 */
	@isTest
	static void testDML() {
		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		System.assertEquals(1, list_Accounts.size(), 'Invalid Test data');

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Opp1')
			.setAccountId(list_Accounts[0].Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();

		Test.startTest();

		//Insert test
		SObjectDMLFlowUtil.Request objRequest = new SObjectDMLFlowUtil.Request(objOpportunity, 'INSERT', 'OpportunityTriggerHelper');
		SObjectDMLFlowUtil.doDML(new List<SObjectDMLFlowUtil.Request>{ objRequest });

		List<Opportunity> list_Opportunities = [SELECT Id FROM Opportunity WHERE StageName = :'MQL'];
		System.assertEquals(1, list_Opportunities.size(), 'Failed, Opportunity did not created');

		//Update Test
		objOpportunity = list_Opportunities[0];
		objOpportunity.Name = 'Test2';
		objRequest = new SObjectDMLFlowUtil.Request(objOpportunity, 'UPDATE', 'OpportunityTriggerHelper');
		SObjectDMLFlowUtil.doDML(new List<SObjectDMLFlowUtil.Request>{ objRequest });

		objOpportunity = [SELECT Id, Name FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals('Test2', objOpportunity.Name, 'Failed, Opportunity did not updated');

		//Delete test
		objRequest = new SObjectDMLFlowUtil.Request(objOpportunity, 'DELETE', 'OpportunityTriggerHelper');
		SObjectDMLFlowUtil.doDML(new List<SObjectDMLFlowUtil.Request>{ objRequest });

		list_Opportunities = [SELECT Id, Name FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(0, list_Opportunities.size(), 'Failed, Opportunity did not deleted');

		Test.stopTest();
	}

	/**
	 * @description Test do DML Operation
	 */
	@isTest
	static void testDMLMultiple() {
		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Employer Account').setZPCompanyId('1234567892').build();
		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Employer Account').setZPCompanyId('1234567891').build();

		List<Account> list_Accounts = new List<Account>{ objAccount1, objAccount2 };
		Test.startTest();

		//Insert test
		SObjectDMLFlowUtil.Request objRequest = new SObjectDMLFlowUtil.Request(list_Accounts, 'INSERT', 'AccountTriggerHandler');
		SObjectDMLFlowUtil.doDML(new List<SObjectDMLFlowUtil.Request>{ objRequest });

		Boolean blnHaveException = false;
		try {
			AccountTriggerHandler.blnTestException = true;

			objRequest = new SObjectDMLFlowUtil.Request(list_Accounts, 'DELETE', 'AccountTriggerHandler;OpportunityTriggerHandler');
			SObjectDMLFlowUtil.doDML(new List<SObjectDMLFlowUtil.Request>{ objRequest });

			List<Account> list_QueriedAccounts = [SELECT Id FROM Account WHERE Id IN :new Map<Id, Account>(list_Accounts).keySet()];
			System.assertEquals(0, list_QueriedAccounts.size(), 'DML failed DELETE');
		} catch (Exception objEx) {
			blnHaveException = true;
		}

		System.assertEquals(false, blnHaveException, 'Bypass failed');

		Test.stopTest();
	}
}