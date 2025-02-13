@isTest
private class HIRenewalTriggerHelperTest {
	/* @author        Praveen Sethu
	 * @description	  Setup method to insert tier config custom settings
	 **/
	@testSetup
	static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Utils.skipTrigger(true);
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Gusto HIRenewal Test').setZPCompanyId('company321').build();
		insert objAccount;

		Pricebook2 objPriceBook = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPriceBook;

		Product2 objProduct2 = TestUtility.createTestProduct('Dental', 'Benefit', false);
		insert objProduct2;

		List<PricebookEntry> pbeList = new List<PricebookEntry>{
			TestUtility.createTestPriceBookEntry(objProduct2.Id, 5, Test.getStandardPriceBookId(), false),
			TestUtility.createTestPriceBookEntry(objProduct2.Id, 5, objPriceBook.id, false)
		};
		insert pbeList;

		State__c objState = new TestDataFactory.StateBuilder().setName('California').setAbbreviation('CA').setId('12').build();
		insert objState;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID).setName('TEST OPPTY - Renewal').setStage('Expired')
			.setPriceBookId(objPriceBook.Id).setAccountId(objAccount.Id).setNumberOfEE(5).setBenefitsState('CA')
			.setSourceID('hawaiian_ice-renewal-321').setStageDetail('Closed Lost').setCloseDate(System.today())
			.build();
		insert objOpportunity;

		list<HI_Aasm_Event__c> list_HIAasmEvents = new List<HI_Aasm_Event__c>{
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321').setRecordableType('Renewal').setCreatedAt(System.today())
				.setId('11111111').setFrom('answering_survey').setTo('awaiting_offerings')
				.build(),
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321').setRecordableType('Renewal').setCreatedAt(System.today())
				.setId('11111112').setFrom('awaiting_offerings').setTo('dismissed')
				.build(),
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321').setRecordableType('Renewal').setCreatedAt(System.today())
				.setId('11111113').setFrom('reviewing_summary').setTo('reviewing_summary')
				.build(),
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321').setRecordableType('Renewal').setCreatedAt(System.today())
				.setId('11111114').setFrom('selecting_offerings').setTo('dismissed')
				.build()
		};
		insert list_HIAasmEvents;
		Utils.skipTrigger(false);
	}

	@isTest
	static void hiRenewalTriggerTest() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();

		list<HI_Renewal__c> list_hiRenewals = new List<HI_Renewal__c> {
			new TestDataFactory.HIRenewalBuilder()
				.setId('321').setCompanyId('company321').setExternalKey('Opportunity321')
                .setBenefitTypes('medical,dental,vision,life,long,hsa,fsa,dca')
				.setSurveyAnswers('{"comment"=>"Test", "address_on_file"=>"2450 Mariner Square Loop, Alameda, CA 94501", "interested_benefit_types"=>{"dental"=>true, "long term disability"=>false}, "carrier_providers_coverage"=>{"24"=>"Yes"}, "line_of_coverage_improvement"=>"Keep everything roughly the same"}')
				.build()
		};
		HIRenewalTriggerHelper.queue = true;

		Test.startTest();
		insert list_hiRenewals;

		List<Account> list_accounts = [SELECT Id, (SELECT Id, Async_Renewal__c FROM Opportunities) FROM Account WHERE ZP_Company_Id__c = 'company321'];
		if (list_accounts.get(0).Opportunities.get(0).Async_Renewal__c != null) {
			System.assertEquals(false, list_accounts.get(0).Opportunities.get(0).Async_Renewal__c, 'Async Renwal flag does not match');
		}
		HIRenewalTriggerHelper.queue = false;

		update list_hiRenewals;
		Test.stopTest();

		Renewal_Survey__c objRenewalSurvey = [SELECT Id, Interest_in_Adding_Benefits__c, Carrier_Satisfaction_Yes__c FROM Renewal_Survey__c WHERE Id__c = '321'];
		System.assertNotEquals(null, objRenewalSurvey.Interest_in_Adding_Benefits__c, 'Dental Benefits should be Yes');
		System.assertEquals(null, objRenewalSurvey.Carrier_Satisfaction_Yes__c, 'Carries Satisfaction should be null');

		delete list_hiRenewals;
		System.assertEquals(0, [SELECT Id FROM HI_Renewal__c].size(), 'Renwals should be deleted');
	}
}