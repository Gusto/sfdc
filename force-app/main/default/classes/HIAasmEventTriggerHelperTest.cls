@isTest
private class HIAasmEventTriggerHelperTest {
	static {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();

		HIAasmEventTriggerHelper.queue = true;
		Account accRec = new Account(Name = 'Gusto HI Test', ZP_Company_Id__c = 'company321');
		insert accRec;

		PriceBook2 pbk = new PriceBook2(Name = objTierConfig.New_Price_1__c, IsActive = true);
		insert pbk;

		Product2 productRec = TestUtility.createTestProduct('Dental', 'Benefit', false);
		insert productRec;

		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		pbeList.add(TestUtility.createTestPriceBookEntry(productRec.Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(productRec.Id, 5, pbk.id, false));
		insert pbeList;

		State__c state = (State__c) State__c.SObjectType.newSObject();
		state.Abbreviation__c = 'CA';
		state.Name = 'TEST STATE';
		insert state;
	}

	@isTest
	static void HINewPlanApplicationTest() {
		HIAasmEventTriggerHelper.queue = true;

		Test.startTest();
		Account accRec = [SELECT Id FROM Account LIMIT 1];
		Opportunity opportunityRec = TestUtility.createOpportunity('Benefits New Plan', accRec.Id);
		opportunityRec.Pricebook2Id = [SELECT Id FROM PriceBook2 LIMIT 1].Id;
		opportunityRec.StageName = 'SAL';
		opportunityRec.NumberOfEmployees__c = 5;
		opportunityRec.Source_Id__c = 'hawaiian_ice-new_plans_application-321';
		opportunityRec.Benefits_State__c = 'CA';
		insert opportunityRec;

		list<String> eventStates = new List<String>{
			'receiving_medical_education',
			'selecting_base_plan',
			'selecting_complementary_plans',
			'setting_sic_code_for_dental',
			'selecting_dental',
			'selecting_vision',
			'collecting_company_information',
			'reviewing_summary',
			'verifying_eligibility'
		};
		list<HI_Aasm_Event__c> aasmList = new List<HI_Aasm_Event__c>();
		for (String eachState : eventStates) {
			aasmList.add(new HI_Aasm_Event__c(Recordable_Id__c = '321', Recordable_Type__c = 'NewPlansApplication', From__c = eachState, To__c = eachState, Created_at__c = system.now()));
		}

		list<HI_New_Plans_Application__c> listnewPlan = new List<HI_New_Plans_Application__c>{
			new HI_New_Plans_Application__c(Id__c = '321', Company_Id__c = 'company321', External_Key__c = 'hawaiian_ice-new_plans_application-321', Requested_Start_Date__c = system.today()),
			new HI_New_Plans_Application__c(Id__c = '322', Company_Id__c = 'company321', Requested_Start_Date__c = system.today())
		};
		insert listnewPlan;

		insert aasmList;
		update aasmList;
		delete aasmList;
		Test.stopTest();

		list<Account> accList = [SELECT Id, (SELECT Id, Users_Email__c FROM Opportunities) FROM Account WHERE ZP_Company_Id__c = 'company321'];
		system.assert(accList.get(0).Opportunities.get(0).Users_Email__c == null);
	}

	@isTest
	static void hiRenewalTest() {
		HIAasmEventTriggerHelper.queue = true;

		Test.startTest();
		Account accRec = [SELECT Id FROM Account LIMIT 1];
		Opportunity opportunityRec = TestUtility.createOpportunity('Benefits Renewal', accRec.Id);
		opportunityRec.Pricebook2Id = [SELECT Id FROM PriceBook2 LIMIT 1].Id;
		opportunityRec.StageName = 'SAL';
		opportunityRec.NumberOfEmployees__c = 5;
		opportunityRec.Source_Id__c = 'hawaiian_ice-renewal-newPlan321';
		opportunityRec.Benefits_State__c = 'CA';
		opportunityRec.stageName = 'Expired';
		insert opportunityRec;

		list<HI_Aasm_Event__c> toInsertEventList = new List<HI_Aasm_Event__c>{
			new HI_Aasm_Event__c(Recordable_Type__c = 'Renewal', Recordable_Id__c = 'newPlan321', From__c = 'answering_survey', To__c = 'awaiting_offerings'),
			new HI_Aasm_Event__c(Recordable_Type__c = 'Renewal', Recordable_Id__c = 'newPlan321', From__c = 'awaiting_offerings', To__c = 'answering_survey')
		};
		insert toInsertEventList;

		list<HI_Renewal__c> renewalList = new List<HI_Renewal__c>{
			new HI_Renewal__c(Id__c = 'newPlan321', Company_Id__c = 'company321', External_Key__c = 'Opportunity321', Benefit_Types__c = 'medical,dental,vision,life,long', Async_Renewal__c = false),
			new HI_Renewal__c(Id__c = 'newPlan322', Company_Id__c = 'company321', Benefit_Types__c = 'medical,dental,vision,life,long', Async_Renewal__c = false)
		};
		insert renewalList;
		Test.stopTest();

		list<Account> accList = [SELECT Id, (SELECT Id, Async_Renewal__c FROM Opportunities) FROM Account WHERE ZP_Company_Id__c = 'company321'];

		if (accList.get(0).Opportunities.get(0).Async_Renewal__c != null) {
			system.assert(accList.get(0).Opportunities.get(0).Async_Renewal__c == false);
		}
	}

	@isTest
	static void benefitChangeTest() {
		HIAasmEventTriggerHelper.queue = true;
		list<Opportunity> toInsertOpportunityList = new List<Opportunity>();

		Test.startTest();
		Account accRec = [SELECT Id FROM Account LIMIT 1];
		Opportunity opportunityBor = TestUtility.createOpportunity('Benefits Change', accRec.Id);
		opportunityBor.Pricebook2Id = [SELECT Id FROM PriceBook2 LIMIT 1].Id;
		opportunityBor.StageName = 'SAL';
		opportunityBor.NumberOfEmployees__c = 5;
		opportunityBor.Source_Id__c = 'hawaiian_ice-bor_transfer-benefitChange321';
		opportunityBor.Benefits_State__c = 'CA';
		opportunityBor.stageName = 'Expired';
		toInsertOpportunityList.add(opportunityBor);

		Opportunity opportunityChg = TestUtility.createOpportunity('Benefits Change', accRec.Id);
		opportunityChg.Pricebook2Id = [SELECT Id FROM PriceBook2 LIMIT 1].Id;
		opportunityChg.StageName = 'SAL';
		opportunityChg.NumberOfEmployees__c = 5;
		opportunityChg.Source_Id__c = 'hawaiian_ice-benefit_change_application-benefitChange321';
		opportunityChg.Benefits_State__c = 'CA';
		toInsertOpportunityList.add(opportunityChg);

		insert toInsertOpportunityList;

		list<HI_Aasm_Event__c> toInsertHiAasmEventList = new List<HI_Aasm_Event__c>{
			new HI_Aasm_Event__c(Recordable_Type__c = 'BorTransfer', Recordable_Id__c = 'benefitChange321'),
			new HI_Aasm_Event__c(Recordable_Type__c = 'Change', Recordable_Id__c = 'benefitChange321', From__c = 'answering_survey', To__c = 'awaiting_offerings'),
			new HI_Aasm_Event__c(Recordable_Type__c = 'Change', Recordable_Id__c = 'benefitChangeApplication32', From__c = 'reviewing_summary', To__c = 'complete')
		};
		insert toInsertHiAasmEventList;

		List<HI_Aasm_Event__c> aasmList = new List<HI_Aasm_Event__c>{
			new HI_Aasm_Event__c(From__c = 'Started', To__c = 'answering_survey', Created_at__c = System.now(), Recordable_Id__c = 'benefitChange321', Recordable_Type__c = 'BenefitChangeApplication'),
			new HI_Aasm_Event__c(
				From__c = 'answering_survey',
				To__c = 'awaiting_offerings',
				Created_at__c = system.now(),
				Recordable_Id__c = 'benefitChange321',
				Recordable_Type__c = 'BenefitChangeApplication'
			),
			new HI_Aasm_Event__c(
				From__c = 'awaiting_offerings',
				To__c = 'receiving_education',
				Created_at__c = system.now(),
				Recordable_Id__c = 'benefitChange321',
				Recordable_Type__c = 'BenefitChangeApplication'
			),
			new HI_Aasm_Event__c(
				From__c = 'receiving_education',
				To__c = 'selecting_offerings',
				Created_at__c = system.now(),
				Recordable_Id__c = 'benefitChange321',
				Recordable_Type__c = 'BenefitChangeApplication'
			),
			new HI_Aasm_Event__c(
				From__c = 'selecting_offerings',
				To__c = 'reviewing_summary',
				Created_at__c = system.now(),
				Recordable_Id__c = 'benefitChange321',
				Recordable_Type__c = 'BenefitChangeApplication'
			),
			new HI_Aasm_Event__c(
				From__c = 'reviewing_summary',
				To__c = 'complete',
				Created_at__c = system.now(),
				Recordable_Id__c = 'benefitChange321',
				Recordable_Type__c = 'BenefitChangeApplication'
			)
		};
		insert aasmList;

		list<HI_Benefit_Change_Application__c> toInsertHiBCAList = new List<HI_Benefit_Change_Application__c>{
			new HI_Benefit_Change_Application__c(
				Id__c = 'benefitChange321',
				External_Key__c = 'Opportunity321',
				Company_Id__c = 'HiBCAcompany321',
				Enrollees__c = 2,
				Application_Deadline__c = System.today()
			),
			new HI_Benefit_Change_Application__c(
				Id__c = 'benefitChangeApplication322',
				External_Key__c = 'Opportunity32',
				Company_Id__c = 'HiBCAcompany321',
				Enrollees__c = 2,
				Application_Deadline__c = System.today()
			)
		};
		insert toInsertHiBCAList;
		Test.stopTest();

		id changeRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change');
		list<Account> listAccount = [SELECT Id, (SELECT Id, NumberOfEmployees__c FROM Opportunities WHERE RecordTypeId = :changeRecordTypeId) FROM Account WHERE ZP_Company_ID__c = 'HiBCAcompany321'];

		if (listAccount != null && listAccount.size() > 0) {
			Opportunity oppRec = listAccount.get(0).Opportunities.get(0);
			if (oppRec.NumberOfEmployees__c != null) {
				system.assert(oppRec.NumberOfEmployees__c == 5);
			}
		}
	}

	/**
	 * @name         hiRenewalAwaitingOfferingTest
	 * @description  Test when a Renewal Opp is updated to awaiting_offerings
	 */
	@isTest(SeeAllData=true) // required for the test of chatter FeedItem
	static void hiRenewalAwaitingOfferingTest() {
		HIAasmEventTriggerHelper.queue = true;

		Test.startTest();
		Account accRec = [SELECT Id FROM Account LIMIT 1];
		Opportunity opportunityRec = TestUtility.createOpportunity('Benefits Renewal', accRec.Id);
		opportunityRec.Pricebook2Id = [SELECT Id FROM PriceBook2 LIMIT 1].Id;
		opportunityRec.StageName = 'SAL';
		opportunityRec.NumberOfEmployees__c = 5;
		opportunityRec.Source_Id__c = 'hawaiian_ice-renewal-renewaltest12';
		opportunityRec.Benefits_State__c = 'CA';
		opportunityRec.Benefits_Designer__c = UserInfo.getUserId();
		insert opportunityRec;

		insert new HI_Renewal__c(
			Id__c = 'newPlan321',
			Company_Id__c = 'company321',
			External_Key__c = 'Opportunity321',
			Benefit_Types__c = 'medical,dental,vision,life,long',
			Async_Renewal__c = false
		);

		insert new HI_Aasm_Event__c(Recordable_Type__c = 'Renewal', Recordable_Id__c = 'renewaltest12', From__c = 'awaiting_offerings', To__c = 'receiving_education', Created_at__c = system.now());
		HIAasmEventTriggerHelper.queue = false;

		insert new HI_Aasm_Event__c(
			Recordable_Type__c = 'Renewal',
			Recordable_Id__c = 'renewaltest12',
			From__c = 'answering_survey',
			To__c = 'awaiting_offerings',
			Paper_Trail_Whodunnit__c = '0',
			Processing_State__c = 'Queued'
		);
		Test.stopTest();

		System.assert(![SELECT Id FROM FeedItem WHERE ParentId = :opportunityRec.Id].isEmpty());
	}

	/**
	 * @name         hiRenewalAwaitingOfferingNegativeCase
	 * @description  Test when a Renewal Opp is updated to awaiting_offerings
	 */
	@isTest(SeeAllData=true) // required for the test of chatter FeedItem
	static void hiRenewalAwaitingOfferingNegativeCase() {
		HIAasmEventTriggerHelper.queue = true;

		Test.startTest();
		Account accRec = [SELECT Id FROM Account LIMIT 1];
		Opportunity opportunityRec = TestUtility.createOpportunity('Benefits Renewal', accRec.Id);
		opportunityRec.Pricebook2Id = [SELECT Id FROM PriceBook2 LIMIT 1].Id;
		opportunityRec.StageName = 'SAL';
		opportunityRec.NumberOfEmployees__c = 5;
		opportunityRec.Source_Id__c = 'hawaiian_ice-renewal-renewaltest12';
		opportunityRec.Benefits_State__c = 'CA';
		insert opportunityRec;

		insert new HI_Renewal__c(
			Id__c = 'newPlan321',
			Company_Id__c = 'company321',
			External_Key__c = 'Opportunity321',
			Benefit_Types__c = 'medical,dental,vision,life,long',
			Async_Renewal__c = false
		);

		insert new HI_Aasm_Event__c(Recordable_Type__c = 'Renewal', Recordable_Id__c = 'renewaltest12', From__c = 'awaiting_offerings', To__c = 'receiving_education', Created_at__c = system.now());
		HIAasmEventTriggerHelper.queue = false;

		insert new HI_Aasm_Event__c(
			Recordable_Type__c = 'Renewal',
			Recordable_Id__c = 'renewaltest12',
			From__c = 'answering_survey',
			To__c = 'awaiting_offerings',
			Paper_Trail_Whodunnit__c = '0',
			Processing_State__c = 'Queued'
		);
		Test.stopTest();

		System.assert([SELECT Id FROM FeedItem WHERE ParentId = :opportunityRec.Id].isEmpty());
	}
}