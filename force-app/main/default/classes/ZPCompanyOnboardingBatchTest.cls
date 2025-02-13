@isTest
public class ZPCompanyOnboardingBatchTest {
	@isTest
	static void testBatchExecution() {
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;
		ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.company_id__c = '11111111111111';
		funnel.add_addresses_completed__c = true;
		funnel.Sign__c = 'Test';
		funnel.Processing_State__c = 'Error';
		insert funnel;

		test.startTest();
		funnel = [SELECT Id, Processing_State__c FROM ZP_Company_Onboarding_Funnel__c];
		System.assertEquals(funnel.Processing_State__c, 'Queued', 'The Processing_State__c of ZP_Company_Onboarding_Funnel__c records should be Queued.');
		database.executeBatch(new ZPCompanyOnboardingBatch(), 10);
		test.stopTest();
		funnel = [SELECT Id, Processing_State__c FROM ZP_Company_Onboarding_Funnel__c];
		System.assertEquals(funnel.Processing_State__c, 'Error', 'The Processing_State__c of ZP_Company_Onboarding_Funnel__c records should be Error.');
	}
}