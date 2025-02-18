/**
 * @description This is a test class for the CreateICPBatch class.
 *              It contains test methods to verify the functionality of the batch job.
 * @author Anurag Gautam
 * @date 08/22/2024
 * @version 1.0
 */

@isTest
private class CreateICPBatchTest {
	@TestSetup
	static void setupTestData() {
		// Create test accounts
		List<Account> list_Accounts = new List<Account>();

		// Account with Product_Interest__c including 'international_contractor' and without related Opportunity
		list_Accounts.add(new Account(Name = 'Test Account 1'));

		// Account with Product_Interest__c excluding 'international_contractor' and without related Opportunity
		list_Accounts.add(new Account(Name = 'Test Account 2'));

		// Account with Product_Interest__c including 'international_contractor' and with related Opportunity
		Account accWithOpp = new Account(Name = 'Test Account 3');
        list_Accounts.add(accWithOpp);

		insert list_Accounts;
	}

	@isTest
	static void testBatchJob() {
		// Ensure AccountTriggerHelper.skipTrigger is set up correctly
		AccountTriggerHelper.skipTrigger = true;
        List<Account> list_Accounts = [SELECT Id, Product_Interest__c FROM Account WHERE Name IN ('Test Account 1', 'Test Account 2', 'Test Account 3') ORDER BY Name];

        System.assertEquals(3, list_Accounts.size());

        list_Accounts[0].Product_Interest__c = 'international_contractor_payment_onboarding;international_payroll_add_iee';
        list_Accounts[1].Product_Interest__c = 'international_payroll_add_iee;';
        list_Accounts[2].Product_Interest__c = 'international_contractor_payment_onboarding;international_contractor_payment_landing_page';

        AccountTriggerHelper.skipTrigger = false;

		// Execute the batch job with batch size of 1
		Test.startTest();
		CreateICPBatch batchJob = new CreateICPBatch();
		Database.executeBatch(batchJob, 3);
		Test.stopTest();

        List<Account> list_AccountsAfterBatch = [SELECT Id, Name, Product_Interest__c FROM Account WHERE Name IN ('Test Account 1', 'Test Account 2', 'Test Account 3') ORDER BY Name];

        System.debug('list_AccountsAfterBatch: ' + list_AccountsAfterBatch);
        System.debug('list_AccountsAfterBatch[0].Product_Interest__c: ' + list_AccountsAfterBatch[0].Product_Interest__c);
        System.debug('list_AccountsAfterBatch[1].Product_Interest__c: ' + list_AccountsAfterBatch[1].Product_Interest__c);
        System.debug('list_AccountsAfterBatch[2].Product_Interest__c: ' + list_AccountsAfterBatch[2].Product_Interest__c);
        
		// Verify the first account (Test Account 1)
		//System.assertEquals('international_payroll_add_iee', updatedAccounts[0].Product_Interest__c, 'Test Account 1 Product_Interest__c should be updated to exclude international_contractor');
	}
}