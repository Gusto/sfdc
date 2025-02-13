@isTest
public class ZPCompanyMigrationBatchTest {
	@isTest
	static void testAccountingFirmBatch() {
		ZPCompanyTriggerHelper.queue = false;
		ZP_Company__c objZpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState('Error')
			.setCreatedAtDate(System.today())
			.build();

		insert objZpCompany;

		ZPCompanyMigrationTriggerHelper.queue = false;
		ZP_Company_Migration__c objZpCompanyMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
			.setMigrationId('11111111111111')
			.setZPCompanyId('11111111111111')
			.setProcessingState('Error')
			.setCreatedAtDate(System.today())
			.build();

		insert objZpCompanyMigration;

		Test.startTest();
		objZpCompanyMigration = [SELECT Id, Processing_State__c FROM ZP_Company_Migration__c];
		System.assertEquals(objZpCompanyMigration.Processing_State__c, 'Queued', 'The Processing_State__c of ZP_Company_Migration__c records should be Queued.');
		Database.executeBatch(new ZPCompanyMigrationBatch('Select Id from ZP_Company_Migration__c'), 10);
		Test.stopTest();
		objZpCompanyMigration = [SELECT Id, Processing_State__c FROM ZP_Company_Migration__c];
		System.assertEquals(objZpCompanyMigration.Processing_State__c, 'Error', 'The Processing_State__c of ZP_Company_Migration__c records should be Error.');
	}
}