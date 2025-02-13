@isTest
private class HIBenefitChangeApplicationTrgrHelperTest {
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

	static testMethod void benefitChangeDMLTest() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c);

		Account accRec = new Account();
		accRec.ZP_Company_Id__c = 'HiBCAcompany321';
		accRec.Name = 'Gusto HIBenefitChangeApplication Test';
		insert accRec;

		PriceBook2 bk = new PriceBook2();
		bk.Name = objTierConfig.New_Price_1__c;
		bk.IsActive = true;
		insert bk;

		Product2 productRec = TestUtility.createTestProduct('Dental', 'Benefit', false);
		insert productRec;

		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		pbeList.add(TestUtility.createTestPriceBookEntry(productRec.Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(productRec.Id, 5, bk.id, false));
		insert pbeList;

		State__c state = (State__c) State__c.SObjectType.newSObject();
		state.Abbreviation__c = 'CA';
		state.Name = 'TEST STATE';
		insert state;

		list<Opportunity> toInsertOpportunityList = new List<Opportunity>();

		Opportunity opportunityRec = TestUtility.createOpportunity('Benefits Change', accRec.Id);
		opportunityRec.Pricebook2Id = bk.id;
		opportunityRec.StageName = 'SAL';
		opportunityRec.NumberOfEmployees__c = 5;
		opportunityRec.Source_Id__c = 'hawaiian_ice-benefit_change_application-321';
		opportunityRec.Benefits_State__c = 'CA';
		opportunityRec.stageName = 'Expired';
		opportunityRec.Stage_Detail__c = 'Closed Lost';
		toInsertOpportunityList.add(opportunityRec);

		Opportunity opportunityRec2 = TestUtility.createOpportunity('Benefits Change', accRec.Id);
		opportunityRec2.Pricebook2Id = bk.id;
		opportunityRec2.StageName = 'SAL';
		opportunityRec2.NumberOfEmployees__c = 5;
		opportunityRec2.Source_Id__c = 'hawaiian_ice-benefit_change_application-3211';
		opportunityRec2.Benefits_State__c = 'CA';
		toInsertOpportunityList.add(opportunityRec2);

		insert toInsertOpportunityList;

		list<HI_Aasm_Event__c> toInsertHiAasmEventList = new List<HI_Aasm_Event__c>();

		HI_Aasm_Event__c aasmEventRec = new HI_Aasm_Event__c();
		aasmEventRec.Recordable_Type__c = 'BorTransfer';
		aasmEventRec.Recordable_Id__c = '321';
		toInsertHiAasmEventList.add(aasmEventRec);

		HI_Aasm_Event__c aasmEventRec2 = new HI_Aasm_Event__c();
		aasmEventRec2.Recordable_Type__c = 'Change';
		aasmEventRec2.Recordable_Id__c = '321';
		aasmEventRec2.From__c = 'answering_survey';
		aasmEventRec2.To__c = 'awaiting_offerings';
		toInsertHiAasmEventList.add(aasmEventRec2);

		HI_Aasm_Event__c aasmEventRec3 = new HI_Aasm_Event__c();
		aasmEventRec3.Recordable_Type__c = 'Change';
		aasmEventRec3.Recordable_Id__c = '321';
		aasmEventRec3.From__c = 'reviewing_summary';
		aasmEventRec3.To__c = 'complete';
		toInsertHiAasmEventList.add(aasmEventRec3);

		insert toInsertHiAasmEventList;

		List<HI_Aasm_Event__c> aasmList = new List<HI_Aasm_Event__c>();
		HI_Aasm_Event__c event1 = new HI_Aasm_Event__c();
		event1.From__c = 'Started';
		event1.To__c = 'answering_survey';
		event1.created_at__c = system.now();
		event1.Recordable_Id__c = '321';
		event1.Created_At__c = system.today();
		event1.Recordable_Type__c = 'BenefitChangeApplication';
		aasmList.add(event1);
		event1 = new HI_Aasm_Event__c();
		event1.From__c = 'answering_survey';
		event1.To__c = 'awaiting_offerings';
		event1.created_at__c = system.now();
		event1.Recordable_Id__c = '321';
		event1.Created_At__c = system.today();
		event1.Recordable_Type__c = 'BenefitChangeApplication';
		aasmList.add(event1);
		event1 = new HI_Aasm_Event__c();
		event1.From__c = 'awaiting_offerings';
		event1.To__c = 'receiving_education';
		event1.created_at__c = system.now();
		event1.Recordable_Id__c = '321';
		event1.Created_At__c = system.today();
		event1.Recordable_Type__c = 'BenefitChangeApplication';
		aasmList.add(event1);
		event1 = new HI_Aasm_Event__c();
		event1.From__c = 'receiving_education';
		event1.To__c = 'selecting_offerings';
		event1.created_at__c = system.now();
		event1.Recordable_Id__c = '321';
		event1.Created_At__c = system.today();
		event1.Recordable_Type__c = 'BenefitChangeApplication';
		aasmList.add(event1);
		event1 = new HI_Aasm_Event__c();
		event1.From__c = 'selecting_offerings';
		event1.To__c = 'reviewing_summary';
		event1.created_at__c = system.now();
		event1.Recordable_Id__c = '321';
		event1.Created_At__c = system.today();
		event1.Recordable_Type__c = 'BenefitChangeApplication';
		aasmList.add(event1);
		event1 = new HI_Aasm_Event__c();
		event1.From__c = 'reviewing_summary';
		event1.To__c = 'complete';
		event1.created_at__c = system.now();
		event1.Recordable_Id__c = '321';
		event1.Created_At__c = system.today();
		event1.Recordable_Type__c = 'BenefitChangeApplication';
		aasmList.add(event1);
		insert aasmList;

		list<HI_Benefit_Change_Application__c> toInsertHiBCAList = new List<HI_Benefit_Change_Application__c>();

		HI_Benefit_Change_Application__c benefitChangeRec = new HI_Benefit_Change_Application__c();
		benefitChangeRec.External_Key__c = 'Opportunity321';
		benefitChangeRec.Company_Id__c = 'HiBCAcompany321';
		benefitChangeRec.Id__c = '321';
		benefitChangeRec.Enrollees__c = 2;
		benefitChangeRec.Application_Deadline__c = system.today();
		toInsertHiBCAList.add(benefitChangeRec);

		HI_Benefit_Change_Application__c benefitChangeRec2 = new HI_Benefit_Change_Application__c();
		benefitChangeRec2.External_Key__c = 'Opportunity32';
		benefitChangeRec2.Company_Id__c = 'HiBCAcompany321';
		benefitChangeRec2.Id__c = '3211';
		benefitChangeRec2.Enrollees__c = 2;
		benefitChangeRec2.Application_Deadline__c = system.today();
		toInsertHiBCAList.add(benefitChangeRec2);

		test.startTest();
		//insert toInsertHiBCAList;
		insert benefitChangeRec;
		insert benefitChangeRec2;

		id changeRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change');

		list<Account> listAccount = [
			SELECT id, (SELECT id, NumberOfEmployees__c, Application_Deadline__c FROM Opportunities WHERE RecordTypeId = :changeRecordTypeId)
			FROM Account
			WHERE ZP_Company_ID__c = :benefitChangeRec.Company_Id__c
		];

		if (listAccount != null && listAccount.size() > 0) {
			Opportunity oppRec = listAccount.get(0).Opportunities.get(0);
			if (oppRec.NumberOfEmployees__c != null) {
				system.assert(oppRec.NumberOfEmployees__c == 5);
			}
		}

		update toInsertHiBCAList;

		test.stopTest();

		delete toInsertHiBCAList;
	}
}