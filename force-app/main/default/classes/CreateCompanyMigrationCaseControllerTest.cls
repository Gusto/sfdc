@istest
public class CreateCompanyMigrationCaseControllerTest {
	@isTest
	static void CreateNewCompanyMigration() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		Account account = new TestDataFactory.AccountBuilder()
			.setName('Test Account')
			.setRecordTypeId(Cache.getRecordTypeId('Account', 'Company'))
			.setZPCompanyId('11111111')
			.build();
		insert account;

		ZP_Company_Migration__c zpMigration = new ZP_Company_Migration__c();
		zpMigration.Company_Id__c = account.ZP_Company_ID__c;
		zpMigration.Id__c = '12345';
		zpMigration.External_Key__c = 'ZP_CM_12345';
		insert zpMigration;
		List<Order> orderList = new List<Order>([SELECT Id, Status FROM Order WHERE AccountId = :account.Id AND External_Key__c = 'ZP_CM_12345']);
		System.assert(orderList != null, 'orderList should not be null.');

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
		cse.AccountId = account.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.Origin = 'Email';
		cse.SuppliedEmail = 'test.test1@test.com';
		cse.Authorized_User__c = 'No';
		cse.Formating_Status__c = 'Pending';
		cse.Integration_Key__c = zpMigration.External_Key__c;
		insert cse;

		Order order = new TestDataFactory.OrderBuilder()
			.setAccountId(account.Id)
			.setExternalKey(zpMigration.External_Key__c)
			.setEffectiveDate(Date.today())
			.setStatus('Drafted')
			.build();
		upsert order;
		ApexPages.currentPage().getParameters().put('MigrationId', zpMigration.External_Key__c);
		CreateCompanyMigrationCaseController cont = new CreateCompanyMigrationCaseController();
		cont.cancelAction();
		List<Case> caseList = [SELECT Id FROM Case WHERE Integration_Key__c = :zpMigration.External_Key__c];
		System.assertEquals(1, caseList.size(), 'There should be one case');

		CaseTriggerHelper.skipTrigger = true;
		delete cse;
		CaseTriggerHelper.skipTrigger = true;
		cont.createCase();
	}
}