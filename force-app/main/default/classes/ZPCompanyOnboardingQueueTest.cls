@isTest
public class ZPCompanyOnboardingQueueTest {
	@isTest
    static void testFunnelQueue() { 
        
        ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
        funnel.company_id__c = '11111111111111';
        funnel.add_addresses_completed__c=true;
        funnel.Sign__c = 'Test';
        insert funnel;
        System.assertEquals(funnel.Processing_State__c, null, 'The Processing_State__c of ZP_Company_Onboarding_Funnel__c records should be null.');

    }
}