@isTest
public class ZPCompanySuspensionQueueTest {
	@isTest
	static void testSuspensionQueue() {
		ZP_Company__c objZpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState('Error')
			.setCreatedAtDate(System.today())
			.build();

		insert objZpCompany;

		List<ZP_Company__c> companyList = new List<ZP_Company__c>();
		companyList.add(objZpCompany);

		ZP_Company_Suspension__c suspension = new ZP_Company_Suspension__c();
		suspension.Id__c = '22233344553';
		suspension.Company_Id__c = '11111111111111';
		suspension.Reason__c = 'Leaving for other vendor';
		suspension.Suspended_At__c = Date.today();
		suspension.Processing_State__c = 'Queued';
		insert suspension;
		List<ZP_Company_Suspension__c> suspList = new List<ZP_Company_Suspension__c>();
		suspList.add(suspension);

		Test.startTest();
		System.enqueueJob(new ZPCompanySuspensionQueue(suspList));
		Test.stopTest();

		suspension = [SELECT Id, Processing_State__c FROM ZP_Company_Suspension__c WHERE id = :suspension.Id];
        System.assertEquals(suspension.Processing_State__c, 'Processed', 'The Processing_State__c of ZP_Company_Suspension__c records should be Processed.');

	}
}