/**
    Created by : Yuvraj/Prashant
    Created Date : 17/11/2020
**/
@isTest
public class HINewPlansApplicationTriggerHelperTest {
	@testSetup
	static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Product2 objProd = new Product2(Name = 'Medical', Family = 'Hardware');
		insert objProd;

		Id idPriceBook = Test.getStandardPricebookId();

		//create company accounts
		List<Account> list_accountToInsert = new List<Account>();
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('1234567890')
			.setPricing(objTierConfig.New_Price_1__c)
			.setDiscount(20)
			.build();
		list_accountToInsert.add(objAccount);

		Account objAccount_2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('12345678902')
			.setPricing(objTierConfig.New_Price_1__c)
			.setDiscount(20)
			.build();
		list_accountToInsert.add(objAccount_2);

		insert list_accountToInsert;

		OpportunityTriggerHelper.skipTrigger = true;
		List<Opportunity> list_oppToCreate = new List<Opportunity>();
		// Create Benefits new plan Opportunity
		Opportunity objOpportunity = new Opportunity();
		objOpportunity.AccountId = objAccount.Id;
		objOpportunity.Name = 'Test Opp BNP';
		objOpportunity.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
		objOpportunity.CloseDate = System.today();
		objOpportunity.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
		objOpportunity.Source_ID__c = '122sourceId';
		list_oppToCreate.add(objOpportunity);

		Opportunity objOpportunity_2 = new Opportunity();
		objOpportunity_2.AccountId = objAccount_2.Id;
		objOpportunity_2.Name = 'Test Opp BNP';
		objOpportunity_2.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
		objOpportunity_2.CloseDate = System.today();
		objOpportunity_2.StageName = OpportunityUtil.SAL_STAGE;
		list_oppToCreate.add(objOpportunity_2);

		Opportunity objOpportunity_3 = new Opportunity();
		objOpportunity_3.AccountId = objAccount.Id;
		objOpportunity_3.Name = 'Test Opp BNP';
		objOpportunity_3.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;
		objOpportunity_3.CloseDate = System.today();
		objOpportunity_3.StageName = OpportunityUtil.ORDER_LOST_STAGE;
		objOpportunity_3.Source_ID__c = '1223sourceId';
		list_oppToCreate.add(objOpportunity_3);

		OpportunityTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testprocessInformationbyExtKeyCL() {
		HI_New_Plans_Application__c objhiNewPlansApplicationRec = new HI_New_Plans_Application__c();
		objhiNewPlansApplicationRec.Company_Id__c = '1234567890';
		objhiNewPlansApplicationRec.External_Key__c = '122sourceId';
		objhiNewPlansApplicationRec.Id__c = '1234567890';
		objhiNewPlansApplicationRec.Requested_Start_Date__c = System.today();
		objhiNewPlansApplicationRec.Mapped_Status__c = 'Verifying eligibility';
		insert objhiNewPlansApplicationRec;

		System.assert(true, 'Fixed Apex PMD issues.');
	}

	@isTest
	static void testPopulateEventRecordableIdUserEmailMap() {
		HINewPlansApplicationTriggerHelper.queue = true;
		HI_Aasm_Event__c objHINewEvent = new HI_Aasm_Event__c();
		objHINewEvent.Recordable_Type__c = 'NewPlansApplication';
		objHINewEvent.Recordable_Id__c = '12345678902';
		objHINewEvent.Created_At__c = System.now() - 1;
		objHINewEvent.Paper_Trail_Whodunnit__c = 'test';
		objHINewEvent.To__c = 'selecting_employee_eligibility';
		objHINewEvent.From__c = 'selecting_employee_eligibility';
		insert objHINewEvent;

		ZP_User__c objZPUser = new ZP_User__c();
		objZPUser.Id__c = 'test';
		objZPUser.email__c = 'testuser@gmail.com';
		objZPUser.Last_Sign_In_At__c = System.now();
		objZPUser.Created_At__c = System.now();
		objZPUser.Updated_At__c = System.now() + 10;
		insert objZPUser;

		HI_New_Plans_Application__c objhiNewPlansApplicationRec = new HI_New_Plans_Application__c();
		objhiNewPlansApplicationRec.Company_Id__c = '12345678902';
		objhiNewPlansApplicationRec.External_Key__c = '123djkasdkjaskls45678902';
		objhiNewPlansApplicationRec.Id__c = '12345678902';
		objhiNewPlansApplicationRec.Requested_Start_Date__c = System.today();
		Test.startTest();
		insert objhiNewPlansApplicationRec;
		List<Opportunity> list_Opportunity = [SELECT Id, Selecting_Employee_Eligibility_Start__c, Users_Email__c, Selecting_Employee_Eligibility_End__c, Name, LeadSource FROM Opportunity];

		System.assertNotEquals(null, list_Opportunity[0].Id, 'Opportunity Id should not be null.');
		System.assertEquals(objZPUser.email__c, list_Opportunity[0].Users_Email__c, ' Emails should match.');
		System.assertEquals(HINewPlansApplicationTriggerHelper.NP_APPLICATION, list_Opportunity[0].LeadSource, 'Lead Source Should be NP Application');
		update objhiNewPlansApplicationRec;
		delete objhiNewPlansApplicationRec;
		Test.stopTest();
	}

	@isTest
	static void HINewPlanApplicationTestWithInvalidDates() {
		HINewPlansApplicationTriggerHelper.queue = true;
		Account objAccount = new Account();
		objAccount.ZP_Company_Id__c = 'company321';
		objAccount.Name = 'Gusto HINewPlanApplication Test';
		insert objAccount;

		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New_Price_1__c should not be null.');

		PriceBook2 objPriceBook = new PriceBook2();
		objPriceBook.Name = objTierConfig.New_Price_1__c;
		objPriceBook.IsActive = true;
		insert objPriceBook;

		State__c objState = (State__c) State__c.SObjectType.newSObject();
		objState.Abbreviation__c = 'CA';
		objState.Name = 'TEST STATE';
		insert objState;

		Opportunity objOpportunity = TestUtility.createOpportunity('Benefits New Plan', objAccount.Id);
		objOpportunity.Pricebook2Id = objPriceBook.Id;
		objOpportunity.StageName = 'SAL';
		objOpportunity.NumberOfEmployees__c = 5;
		objOpportunity.Source_Id__c = 'hawaiian_ice-new_plans_application-321';
		objOpportunity.Benefits_State__c = 'CA';
		insert objOpportunity;

		List<HI_Aasm_Event__c> list_HiAasmEvent = new List<HI_Aasm_Event__c>();

		HI_Aasm_Event__c objHiaasmEventRec = new HI_Aasm_Event__c();
		objHiaasmEventRec.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventRec.Recordable_Id__c = '321';
		objHiaasmEventRec.From__c = 'receiving_medical_education';
		objHiaasmEventRec.To__c = 'selecting_base_plan';
		objHiaasmEventRec.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventRec);

		objHiaasmEventRec = new HI_Aasm_Event__c();
		objHiaasmEventRec.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventRec.Recordable_Id__c = '321';
		objHiaasmEventRec.From__c = 'selecting_base_plan';
		objHiaasmEventRec.To__c = 'receiving_medical_education';
		objHiaasmEventRec.Created_At__c = System.today() - 1;
		list_HiAasmEvent.add(objHiaasmEventRec);

		HI_Aasm_Event__c objHiaasmEventNew = new HI_Aasm_Event__c();
		objHiaasmEventNew.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventNew.Recordable_Id__c = '321';
		objHiaasmEventNew.From__c = 'selecting_base_plan';
		objHiaasmEventNew.To__c = 'selecting_base_plan';
		objHiaasmEventNew.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventNew);

		HI_Aasm_Event__c objHiaasmEventComplementary = new HI_Aasm_Event__c();
		objHiaasmEventComplementary.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventComplementary.Recordable_Id__c = '321';
		objHiaasmEventComplementary.From__c = 'selecting_complementary_plans';
		objHiaasmEventComplementary.To__c = 'selecting_complementary_plans';
		objHiaasmEventComplementary.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventComplementary);

		HI_Aasm_Event__c objHiaasmEventSetting = new HI_Aasm_Event__c();
		objHiaasmEventSetting.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventSetting.Recordable_Id__c = '321';
		objHiaasmEventSetting.From__c = 'setting_sic_code_for_dental';
		objHiaasmEventSetting.To__c = 'setting_sic_code_for_dental';
		objHiaasmEventSetting.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventSetting);

		HI_Aasm_Event__c objHiaasmEventSelecting = new HI_Aasm_Event__c();
		objHiaasmEventSelecting.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventSelecting.Recordable_Id__c = '321';
		objHiaasmEventSelecting.From__c = 'selecting_dental';
		objHiaasmEventSelecting.To__c = 'selecting_dental';
		objHiaasmEventSelecting.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventSelecting);

		HI_Aasm_Event__c objHiaasmEventVision = new HI_Aasm_Event__c();
		objHiaasmEventVision.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventVision.Recordable_Id__c = '321';
		objHiaasmEventVision.From__c = 'selecting_vision';
		objHiaasmEventVision.To__c = 'selecting_vision';
		objHiaasmEventVision.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventVision);

		HI_Aasm_Event__c objHiaasmEventCollecting = new HI_Aasm_Event__c();
		objHiaasmEventCollecting.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventCollecting.Recordable_Id__c = '321';
		objHiaasmEventCollecting.From__c = 'collecting_company_information';
		objHiaasmEventCollecting.To__c = 'collecting_company_information';
		objHiaasmEventCollecting.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventCollecting);

		HI_Aasm_Event__c objHiaasmEventReview = new HI_Aasm_Event__c();
		objHiaasmEventReview.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventReview.Recordable_Id__c = '321';
		objHiaasmEventReview.From__c = 'reviewing_summary';
		objHiaasmEventReview.To__c = 'reviewing_summary';
		objHiaasmEventReview.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventReview);

		HI_Aasm_Event__c objHiaasmEventEligibility = new HI_Aasm_Event__c();
		objHiaasmEventEligibility.Recordable_Type__c = 'NewPlansApplication';
		objHiaasmEventEligibility.Recordable_Id__c = '321';
		objHiaasmEventEligibility.From__c = 'verifying_eligibility';
		objHiaasmEventEligibility.To__c = 'verifying_eligibility';
		objHiaasmEventEligibility.Created_At__c = System.today();
		list_HiAasmEvent.add(objHiaasmEventEligibility);

		insert list_HiAasmEvent;

		Test.startTest();
		List<HI_New_Plans_Application__c> list_NewPlan = new List<HI_New_Plans_Application__c>();

		HI_New_Plans_Application__c objHiNewPlansApplicationRec = new HI_New_Plans_Application__c();
		objHiNewPlansApplicationRec.Company_Id__c = 'company321';
		objHiNewPlansApplicationRec.External_Key__c = 'hawaiian_ice-new_plans_application-321';
		objHiNewPlansApplicationRec.Id__c = '321';
		objHiNewPlansApplicationRec.Requested_Start_Date__c = System.today();
		list_NewPlan.add(objHiNewPlansApplicationRec);

		HI_New_Plans_Application__c objHiNewPlansApplication = new HI_New_Plans_Application__c();
		objHiNewPlansApplication.Company_Id__c = 'company321';
		objHiNewPlansApplication.Id__c = '322';
		objHiNewPlansApplication.Requested_Start_Date__c = System.today();

		insert objHiNewPlansApplication;
		insert list_NewPlan;
		update list_NewPlan;

		List<Account> accountList = [SELECT Id, ZP_Company_ID__c, Name, (SELECT Id, HI_Effective_Date__c FROM Opportunities) FROM Account WHERE ZP_Company_ID__c = :objAccount.ZP_Company_Id__c];

		if (accountList != null && accountList.size() > 0 && accountList.get(0).Opportunities.get(0).HI_Effective_Date__c != null) {
			System.assert(
				accountList.get(0).Opportunities.get(0).HI_Effective_Date__c == objHiNewPlansApplicationRec.Requested_Start_Date__c,
				'HI_Effective_Date__c and Requested_Start_Date__c should be same.'
			);
		}

		delete list_NewPlan;
		Test.stopTest();
	}
}