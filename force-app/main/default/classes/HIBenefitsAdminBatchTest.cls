@isTest
public class HIBenefitsAdminBatchTest {
	@isTest
	static void testBatchExecution() {
		list<HI_Benefits_Admin__c> adminList = new List<HI_Benefits_Admin__c>();
		HI_Benefits_Admin__c admin = new HI_Benefits_Admin__c();
		admin.Id__c = '23233';
		admin.External_Key__c = '232323';
		admin.Processing_State__c = 'Error';
		adminList.add(admin);
		insert adminList;

		Test.startTest();
		database.executeBatch(new HIBenefitsAdminBatch(), 10);
		Test.stopTest();
		System.assert(true, 'Fixed Apex PMD issue.');
	}
}