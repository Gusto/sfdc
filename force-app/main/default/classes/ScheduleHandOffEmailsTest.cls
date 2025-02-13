@isTest
public class ScheduleHandOffEmailsTest {
	/* @author        Praveen Sethu
	 * @description	  Setup method to insert tier config custom settings
	 * @param         void
	 * @return        void
	 **/
	@testSetup
	static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
	}

	@isTest
	static void testAsyncMethods() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New_Price_1__c should not be null.');

		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Test Account Waiting_Period__c Coverage_Effective_Date__cTestAccountWaiting Test')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objAccount1;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setFirstName('Test')
			.setLastName('Company Contact')
			.setAccountId(objAccount1.Id)
			.setEmail('testuer@abccompany.com')
			.setInferFitScore('D')
			.build();
		insert objContact;

		Opportunity objOpp1 = TestUtility.BenefitsNewPlanOpportunity();
		objOpp1.StageName = 'Pending PR';
		objOpp1.Order_Generated__c = true;
		update objOpp1;
		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', objOpp1.Id, 'Test Benefit Order', false);
		benefitOrdr1.Type__c = 'New to Gusto';
		insert benefitOrdr1;

		OpportunityContactRole ocr = new OpportunityContactRole();
		ocr.ContactId = objContact.Id;
		ocr.OpportunityId = objOpp1.Id;
		ocr.IsPrimary = true;
		insert ocr;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		cse.AccountId = objContact.AccountId;
		cse.Benefit_Order__c = benefitOrdr1.Id;
		cse.ContactId = objContact.Id;
		cse.Subject = 'Test Relation';
		cse.Description = 'Test Relation';
		cse.SuppliedEmail = 'CasetriggerHelper@gusto.com';
		cse.Type = 'Sales';
		cse.Opportunity__c = objOpp1.Id;
		cse.Origin = 'Hippo';
		insert cse;
		Carrier__c carrier1 = TestUtility.Carrier();

		Policy__c pol1 = TestUtility.createTestPolicy(objOpp1.Id, carrier1.Id, true, 'Test Policy1', null, false);
		pol1.Benefit_Type__c = 'Dental';
		pol1.Is_Selected__c = true;
		insert pol1;

		test.startTest();
		ScheduleHandOffEmails objSchedule = new ScheduleHandOffEmails();
		objSchedule.execute(null);
		test.stopTest();
		//System.assertEquals(true, cse);
	}
}