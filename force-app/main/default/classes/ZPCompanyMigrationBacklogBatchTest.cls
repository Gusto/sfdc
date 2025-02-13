/**
 * @name         ZPCompanyMigrationBacklogBatchTest
 * @author       Praveen Sethu
 * @date         06/27/2021
 * @description  Testing Process Migration Backlog Items
 * @test classes NA
 **/
@isTest
public class ZPCompanyMigrationBacklogBatchTest {
	/*
	 * @author:         Praveen Sethu
	 * @description:    Test if Backlog Migration records are processed successfully
	 * @parm:           NA
	 * @return:         NA
	 */
	@isTest
	static void testCompanyMigrationBacklogRecords() {
		ZP_Company_Migration__c objMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
			.setZPCompanyId('12345')
			.setMigrationId('456789')
			.setExternalKey('EXT-KEY')
			.setProcessingState(IntegrationUtils.BACKLOG)
			.build();
		insert objMigration;

		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId(objMigration.Company_Id__c).setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).build();
		insert objAccount;

		// Dynamically scheduling jobs for next year
		Integer intNextYear = Date.today().year() + 1;
		Test.startTest();
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;
		ZPCompanyMigrationBatchScheduler objScheduler = new ZPCompanyMigrationBatchScheduler();
		String strJobId = System.schedule('ZP Company Migration Backlog Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		ZP_Company_Migration__c objMigrationAssert = [SELECT Id, Processing_State__c FROM ZP_Company_Migration__c WHERE Id = :objMigration.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objMigrationAssert.Processing_State__c);
	}
}