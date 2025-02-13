/**
 * @name         AccountTriggerBypassServiceTest
 * @author       Praveen Sethu
 * @description  Test class to validate if account trigger is skipped
 **/
@isTest
public class AccountTriggerBypassServiceTest {
	@isTest
	private static void testAccountTriggerByPass() {
		// Create request
		AccountTriggerBypassService.TransactionRequest objRequest = new AccountTriggerBypassService.TransactionRequest();
		objRequest.skiptrigger = true;
		AccountTriggerBypassService.AccountData objAccountData = new AccountTriggerBypassService.AccountData();

		// Insert company account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('1234567890').build();
		insert objCompanyAccount;

		// Set account Rank
		objAccountData.Id = objCompanyAccount.Id;
		objAccountData.dblAccountRank = 1.0;
		// Set to list of accounts
		objRequest.list_Accounts = new List<AccountTriggerBypassService.AccountData>{ objAccountData };
		// Serialize request into JSON string
		String strJsonBody = JSON.serialize(objRequest);

		Test.startTest();
		// Create REST request
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/TriggerBypass'; //Request URL
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueof(strJsonBody);

		RestContext.request = req;
		RestContext.response = res;

		AccountTriggerBypassService.bypassAccountTrigger();
		Test.stopTest();

		Account objAccAssert = [SELECT Id, Account_Rank__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertEquals(1.0, objAccAssert.Account_Rank__c);
	}
}