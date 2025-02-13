@isTest
private class HINewPlanApplicationTriggerHelperTest {
	/* @author        Praveen Sethu
	 * @description	  Setup method to insert tier config custom settings
	 * @param         void
	 * @return        void
	 **/
	@testSetup
	static void setup() {
		Utils.skipTrigger(true);
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('560001').setName('Gusto HINewPlanApplication Test').build();
		insert objAccount;

		PriceBook2 objPB = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPB;

		Product2 objProduct = new TestDataFactory.ProductBuilder().setName('Dental').setFamily('Benefit').build();
		insert objProduct;

		List<PricebookEntry> list_PBEntries = new List<PricebookEntry>();
		list_PBEntries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objProduct.Id).setPriceBookId(Test.getStandardPriceBookId()).setUnitPrice(5).setIsActive(true).build());
		list_PBEntries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objProduct.Id).setPriceBookId(objPB.id).setUnitPrice(5).setIsActive(true).build());
		insert list_PBEntries;

		State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('5').setAbbreviation('CA').build();
		insert objState;

		Opportunity objOppBOR = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Benefits New Plan')
			.setPriceBookId(objPB.Id)
			.setAccountId(objAccount.Id)
			.setNumberOfEE(5)
			.setSourceID('hawaiian_ice-new_plans_application-321')
			.setId('aasmEvent321')
			.setBenefitsState('CA')
			.setStage('SAL')
			.setCloseDate(System.today().addDays(30))
			.setBenefitsState('CA')
			.build();
		insert objOppBOR;

		list<HI_Aasm_Event__c> list_HIASMEvents = new List<HI_Aasm_Event__c>();
		list<HI_Aasm_Event__c> list_HIAasmEvents = new List<HI_Aasm_Event__c>();
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('receiving_medical_education')
				.setFrom('receiving_medical_education')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('selecting_base_plan')
				.setFrom('selecting_base_plan')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('selecting_complementary_plans')
				.setFrom('selecting_complementary_plans')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('setting_sic_code_for_dental')
				.setFrom('setting_sic_code_for_dental')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('selecting_dental')
				.setFrom('selecting_dental')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('selecting_vision')
				.setFrom('selecting_vision')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('collecting_company_information')
				.setFrom('collecting_company_information')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('reviewing_summary')
				.setFrom('reviewing_summary')
				.setCreatedAt(System.today())
				.build()
		);
		list_HIAasmEvents.add(
			new TestDataFactory.HIAasmEventBuilder()
				.setRecordableId('321')
				.setRecordableType('NewPlansApplication')
				.setTo('verifying_eligibility')
				.setFrom('verifying_eligibility')
				.setCreatedAt(System.today())
				.build()
		);
		insert list_HIAasmEvents;

		Utils.skipTrigger(false);
	}

	/**`
	 * @author       Bhagat Singh
	 * @description  This method is used to test insert HI_New_Plans_Application__c record
	 **/
	@isTest
	static void insertHINewPlanApplication() {
		Test.startTest();
		HINewPlansApplicationTriggerHelper.queue = true;
		HI_New_Plans_Application__c objHINewPlansApp = new TestDataFactory.HINewPlansApplicationBuilder()
			.setId('321')
			.setCompanyId('560001')
			.setExternalKey('hawaiian_ice-new_plans_application-321')
			.setReqStartDate(System.today())
			.build();
		insert objHINewPlansApp;

		Test.stopTest();

		list<Opportunity> list_Opps = [SELECT Id, RecordType.Name, HI_Effective_Date__c FROM Opportunity WHERE Account.ZP_Company_ID__c = '560001'];
		System.assertEquals(list_Opps[0].RecordType.Name, 'Benefits New Plan', 'Opportunity record will be created as Record Type - Benefits New Plan');
		System.assertEquals(list_Opps[0].HI_Effective_Date__c, objHINewPlansApp.Requested_Start_Date__c, 'Opportunity record, HI Effective Date will be same as Requested Start Date');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test update HI_New_Plans_Application__c record
	 **/
	@isTest
	static void updateHINewPlanApplication() {
		Test.startTest();
		HINewPlansApplicationTriggerHelper.queue = true;
		HINewPlansApplicationTriggerHelper.skipTrigger = true;
		HI_New_Plans_Application__c objHINewPlansApp = new TestDataFactory.HINewPlansApplicationBuilder()
			.setId('321')
			.setCompanyId('560001')
			.setExternalKey('hawaiian_ice-new_plans_application-321')
			.setReqStartDate(System.today())
			.build();
		insert objHINewPlansApp;

		HINewPlansApplicationTriggerHelper.skipTrigger = false;
		update objHINewPlansApp;

		Test.stopTest();

		list<Opportunity> list_Opps = [SELECT Id, RecordType.Name, HI_Effective_Date__c FROM Opportunity WHERE Account.ZP_Company_ID__c = '560001'];
		System.assertEquals(list_Opps[0].RecordType.Name, 'Benefits New Plan', 'Opportunity record will be created as Record Type - Benefits New Plan');
		System.assertEquals(list_Opps[0].HI_Effective_Date__c, objHINewPlansApp.Requested_Start_Date__c, 'Opportunity record, HI Effective Date will be same as Requested Start Date');
	}

	/**`
	 * @author       Bhagat Singh
	 * @description  This method is used to test validate HI_New_Plans_Application__c record
	 **/
	@isTest
	static void validateHINewPlanApplication() {
		Test.startTest();
		HINewPlansApplicationTriggerHelper.queue = true;
		HI_New_Plans_Application__c objHINewPlansApp = new TestDataFactory.HINewPlansApplicationBuilder()
			.setId('321')
			.setCompanyId('')
			.setExternalKey('hawaiian_ice-new_plans_application-321')
			.setReqStartDate(System.today())
			.build();
		insert objHINewPlansApp;

		Test.stopTest();

		list<HI_New_Plans_Application__c> list_HINewPlansApps = [SELECT Id, Processing_State__c, Message__c FROM HI_New_Plans_Application__c WHERE Id = :objHINewPlansApp.Id];
		System.assertEquals(list_HINewPlansApps[0].Processing_State__c, IntegrationUtils.ERROR_STATE, 'Company Id invalid');
		System.assertEquals(list_HINewPlansApps[0].Message__c, 'Company Id: field value is missing in the record.', 'Company Id invalid');
	}
}