@isTest
public class ZPCompanyMigrationQueueTest {
	@isTest
	static void CreateNewCompanyMigration() {
		ZPCompanyMigrationTriggerHelper.queue = false;
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test')
			.setRecordTypeId('Company')
			.setZPCompanyId('11111111')
			.build();

		insert objAccount;

		ZP_Company_Migration__c objZpMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
			.setZPCompanyId(objAccount.ZP_Company_ID__c)
			.setMigrationId('12345')
			.setExternalKey('ZP_CM_12345')
			.build();

		insert objZpMigration;
		objZpMigration = [SELECT Id,Processing_State__c FROM ZP_Company_Migration__c];
        System.assertEquals(objZpMigration.Processing_State__c, 'Queued', 'The Processing_State__c of ZP_Company_Migration__c records should be Queued.');
		
	}
}