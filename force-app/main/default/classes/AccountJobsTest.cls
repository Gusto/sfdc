/**
 * @name         AccountJobsTest
 * @date         05-06-2024
 * @description  Test class for AccountJobs. Contains test methods for AccountJobs class; test methods for different operations.
 * @see          AccountJobs
 **/

@isTest
public class AccountJobsTest {
	// Method to setup test data
	@testSetup
	static void setup() {
		Test.startTest();
		// Create test accounts
		List<Account> list_testAccounts = new List<Account>();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account 1').setZPFirmId('987456123').build();
		Account objResellerAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account 2').setZPFirmId('987456124').build();
		list_testAccounts.add(objResellerAccount);
		list_testAccounts.add(objResellerAccount2);
		insert list_testAccounts;
		list_testAccounts.clear();
		for (Integer i = 0; i < 25; i++) {
			Account objCompanyAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account ' + i)
				.setSoldBy(objResellerAccount.Id)
				.build();
			list_testAccounts.add(objCompanyAccount);
		}
		for (Integer i = 0; i < 10; i++) {
			Account objCompanyAccount = new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Company Account ' + i * 20)
				.setSoldBy(objResellerAccount2.Id)
				.build();
			list_testAccounts.add(objCompanyAccount);
		}
		insert list_testAccounts;
		Test.stopTest();
	}

	// Test the batch job with specific operation and parameters
	@isTest
	static void testUpdatePartnerChildAccountsBatch() {
		Account objResellerAccount = [SELECT Id FROM Account WHERE Name = 'Reseller Account 1' LIMIT 1];
		objResellerAccount.Benefits_Email_Opt_Out__c = '401k';
		objResellerAccount.Benefits_Opt_Out_Details__c = 'No Cross-Selling to clients';
		objResellerAccount.Apply_to_all_clients__c = true;
		List<Account> list_partnerAccounts = [SELECT Id FROM Account WHERE Sold_By__c = :objResellerAccount.Id];
		Assert.areNotEqual(0, list_partnerAccounts.size(), 'Partner accounts should exist.');
		Test.startTest();
		update objResellerAccount;
		Test.stopTest();

		// Asserts to verify that the batch job processed records correctly
		List<Account> list_updatedAccounts = [SELECT Id, Benefits_Email_Opt_Out__c, Benefits_Opt_Out_Details__c FROM Account WHERE Sold_By__c = :objResellerAccount.Id];
		for (Account objClientAccount : list_updatedAccounts) {
			Assert.areEqual('401k', objClientAccount.Benefits_Email_Opt_Out__c, 'Email opt-out match');
			Assert.areEqual('No Cross-Selling to clients', objClientAccount.Benefits_Opt_Out_Details__c, 'Opt-out details should match.');
		}
	}

	// Test the batch job with specific operation and parameters
	@isTest
	static void testUpdatePartnerChildAccounts() {
		Account objResellerAccount = [SELECT Id FROM Account WHERE Name = 'Reseller Account 2' LIMIT 1];
		objResellerAccount.Benefits_Email_Opt_Out__c = '401k';
		objResellerAccount.Benefits_Opt_Out_Details__c = 'No Cross-Selling to clients';
		objResellerAccount.Apply_to_all_clients__c = true;
		update objResellerAccount;

		// Asserts to verify that the batch job processed records correctly
		List<Account> list_updatedAccounts = [SELECT Id, Benefits_Email_Opt_Out__c, Benefits_Opt_Out_Details__c FROM Account WHERE Sold_By__c = :objResellerAccount.Id];
		for (Account objClientAccount : list_updatedAccounts) {
			Assert.areEqual('401k', objClientAccount.Benefits_Email_Opt_Out__c, 'Email opt-out match');
			Assert.areEqual('No Cross-Selling to clients', objClientAccount.Benefits_Opt_Out_Details__c, 'Opt-out details should match.');
		}
	}

	// Test the batch job's exception handling
	@isTest
	static void testExceptionHandling() {
		Account objResellerAccount = [SELECT Id FROM Account WHERE Name = 'Reseller Account 1' LIMIT 1];
		objResellerAccount.Benefits_Email_Opt_Out__c = '401k';
		objResellerAccount.Benefits_Opt_Out_Details__c = 'No Cross-Selling to clients';
		objResellerAccount.Apply_to_all_clients__c = true;
		List<Account> list_testAccounts = [SELECT Id FROM Account WHERE Sold_By__c = :objResellerAccount.Id];
		Test.startTest();
		AccountJobs batch = new AccountJobs(AccountJobs.UPDATE_PARTNER_CHILD_ACCOUNTS, new Map<Account, List<Account>>{ objResellerAccount => list_testAccounts });
		AccountJobs.blnTestException = true; // Simulate an exception
		Database.executeBatch(batch);
		batch.updatePartnerChildAccounts(new List<Account>{ objResellerAccount }, batch.map_childAccountsToUpdate);
		Test.stopTest();

		// Verify that the exception was logged
		List<Exception_Log__c> logs = [SELECT Id, Message__c FROM Exception_Log__c];
		System.assertNotEquals(0, logs.size(), 'Exceptions should be logged.');
	}
}