@isTest
public class HIAasmEventQueueTest {
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
	static void HINewPlanApplicationTest() {
		HIAasmEventTriggerHelper.queue = false;
		Account accRec = new Account();
		accRec.ZP_Company_Id__c = 'company321';
		accRec.Name = 'Gusto HINewPlanApplication Test';
		insert accRec;

		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c);

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

		Opportunity opportunityRec = TestUtility.createOpportunity('Benefits New Plan', accRec.Id);
		opportunityRec.Pricebook2Id = bk.id;
		opportunityRec.StageName = 'SAL';
		opportunityRec.NumberOfEmployees__c = 5;
		opportunityRec.Source_Id__c = 'hawaiian_ice-new_plans_application-321';
		opportunityRec.Benefits_State__c = 'CA';
		insert opportunityRec;

		list<HI_Aasm_Event__c> aasmList = new List<HI_Aasm_Event__c>();

		HI_Aasm_Event__c hiaasmEventRec = new HI_Aasm_Event__c();
		hiaasmEventRec.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec.Recordable_Id__c = '321';
		hiaasmEventRec.From__c = 'receiving_medical_education';
		hiaasmEventRec.To__c = 'receiving_medical_education';
		hiaasmEventRec.created_at__c = system.now();
		aasmList.add(hiaasmEventRec);

		HI_Aasm_Event__c hiaasmEventRec2 = new HI_Aasm_Event__c();
		hiaasmEventRec2.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec2.Recordable_Id__c = '321';
		hiaasmEventRec2.From__c = 'selecting_base_plan';
		hiaasmEventRec2.To__c = 'selecting_base_plan';
		hiaasmEventRec2.created_at__c = system.now();
		aasmList.add(hiaasmEventRec2);

		HI_Aasm_Event__c hiaasmEventRec3 = new HI_Aasm_Event__c();
		hiaasmEventRec3.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec3.Recordable_Id__c = '321';
		hiaasmEventRec3.From__c = 'selecting_complementary_plans';
		hiaasmEventRec3.To__c = 'selecting_complementary_plans';
		hiaasmEventRec3.created_at__c = system.now();
		aasmList.add(hiaasmEventRec3);

		HI_Aasm_Event__c hiaasmEventRec4 = new HI_Aasm_Event__c();
		hiaasmEventRec4.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec4.Recordable_Id__c = '321';
		hiaasmEventRec4.From__c = 'setting_sic_code_for_dental';
		hiaasmEventRec4.To__c = 'setting_sic_code_for_dental';
		hiaasmEventRec4.created_at__c = system.now();
		aasmList.add(hiaasmEventRec4);

		HI_Aasm_Event__c hiaasmEventRec5 = new HI_Aasm_Event__c();
		hiaasmEventRec5.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec5.Recordable_Id__c = '321';
		hiaasmEventRec5.From__c = 'selecting_dental';
		hiaasmEventRec5.To__c = 'selecting_dental';
		hiaasmEventRec5.created_at__c = system.now();
		aasmList.add(hiaasmEventRec5);

		HI_Aasm_Event__c hiaasmEventRec6 = new HI_Aasm_Event__c();
		hiaasmEventRec6.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec6.Recordable_Id__c = '321';
		hiaasmEventRec6.From__c = 'selecting_vision';
		hiaasmEventRec6.To__c = 'selecting_vision';
		hiaasmEventRec6.created_at__c = system.now();
		aasmList.add(hiaasmEventRec6);

		HI_Aasm_Event__c hiaasmEventRec7 = new HI_Aasm_Event__c();
		hiaasmEventRec7.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec7.Recordable_Id__c = '321';
		hiaasmEventRec7.From__c = 'collecting_company_information';
		hiaasmEventRec7.To__c = 'collecting_company_information';
		hiaasmEventRec7.created_at__c = system.now();
		aasmList.add(hiaasmEventRec7);

		HI_Aasm_Event__c hiaasmEventRec8 = new HI_Aasm_Event__c();
		hiaasmEventRec8.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec8.Recordable_Id__c = '321';
		hiaasmEventRec8.From__c = 'reviewing_summary';
		hiaasmEventRec8.To__c = 'reviewing_summary';
		hiaasmEventRec8.created_at__c = system.now();
		aasmList.add(hiaasmEventRec8);

		HI_Aasm_Event__c hiaasmEventRec9 = new HI_Aasm_Event__c();
		hiaasmEventRec9.Recordable_Type__c = 'NewPlansApplication';
		hiaasmEventRec9.Recordable_Id__c = '321';
		hiaasmEventRec9.From__c = 'verifying_eligibility';
		hiaasmEventRec9.To__c = 'verifying_eligibility';
		hiaasmEventRec9.created_at__c = system.now();
		aasmList.add(hiaasmEventRec9);

		list<HI_New_Plans_Application__c> listnewPlan = new List<HI_New_Plans_Application__c>();

		HI_New_Plans_Application__c hiNewPlansApplicationRec = new HI_New_Plans_Application__c();
		hiNewPlansApplicationRec.Company_Id__c = 'company321';
		hiNewPlansApplicationRec.External_Key__c = 'hawaiian_ice-new_plans_application-321';
		hiNewPlansApplicationRec.Id__c = '321';
		hiNewPlansApplicationRec.Requested_Start_Date__c = system.today();
		listnewPlan.add(hiNewPlansApplicationRec);

		HI_New_Plans_Application__c hiNewPlansApplicationRec1 = new HI_New_Plans_Application__c();
		hiNewPlansApplicationRec1.Company_Id__c = 'company321';
		//hiNewPlansApplicationRec1.External_Key__c = 'Opportunity322';
		hiNewPlansApplicationRec1.Id__c = '322';
		hiNewPlansApplicationRec1.Requested_Start_Date__c = system.today();
		listnewPlan.add(hiNewPlansApplicationRec1);

		insert listnewPlan;

		insert aasmList;
	}
}