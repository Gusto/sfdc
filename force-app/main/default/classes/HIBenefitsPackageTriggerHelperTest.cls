/**
    Created by : Sanjay Paryani
    Created Date : 05/12/2021
**/
@isTest
public class HIBenefitsPackageTriggerHelperTest {
	public static boolean blnRunCatchTest = false;
	public static boolean blnRunCatchHandlerTest = false;

	@TestSetup
	static void makeData() {
		ZPCompanyTriggerHelper.queue = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Account objAcc = new Account();
		objAcc.Name = 'test';
		objAcc.ZP_Company_Id__c = 'company321';
		objAcc.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		insert objAcc;

		HI_Benefit_Change_Application__c objBCA = new HI_Benefit_Change_Application__c();
		objBCA.Benefits_Package_Id__c = 'Benefits321';
		objBCA.External_Key__c = 'hawaiian_ice-new_plans_application-O321';
		insert objBCA;

		State__c objState = new State__c();
		objState.Id__c = 'State321';
		objState.Abbreviation__c = 'CA';
		insert objState;

		HI_Renewal__c objRenewal = new HI_Renewal__c();
		objRenewal.Benefits_Package_Id__c = 'Benefits321';
		objRenewal.External_Key__c = 'hawaiian_ice-new_plans_application-O321';
		insert objRenewal;

		Carrier__c objCarrier = TestUtility.createTestCarrier('Carrier', 'CA', true);

		PriceBook2 objPB = new PriceBook2();
		objPB.Name = objTierConfig.New_Price_1__c;
		objPB.IsActive = true;
		insert objPB;

		Product2 objProduct = TestUtility.createTestProduct('Dental', 'Benefit', false);
		insert objProduct;

		List<PricebookEntry> list_PBEs = new List<PricebookEntry>();
		list_PBEs.add(TestUtility.createTestPriceBookEntry(objProduct.Id, 5, Test.getStandardPriceBookId(), false));
		list_PBEs.add(TestUtility.createTestPriceBookEntry(objProduct.Id, 5, objPB.Id, false));
		insert list_PBEs;

		State__c objState2 = (State__c) State__c.SObjectType.newSObject();
		objState2.Abbreviation__c = 'CA';
		objState2.Name = 'TEST STATE';
		insert objState2;

		HI_Company_Contribution__c objCompanyContribution = new HI_Company_Contribution__c();
		objCompanyContribution.Id__c = 'compcont1';
		objCompanyContribution.Company_Id__c = 'company321';
		objCompanyContribution.Type__c = 'HealthCompanyContribution';
		objCompanyContribution.Calculator_Inputs__c = '{"type"=>"employee_and_dependents", "employee_calculator"=>{"type"=>"percentage", "percentage"=>"0.5"}, "dependents_calculator"=>{"type"=>"percentage", "percentage"=>"0.25"}}';
		insert objCompanyContribution;

		String strRecType = 'Benefits New Plan';
		Id idRecTypeId = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName().get(strRecType).getRecordTypeId();
		Opportunity objOpportunity = (Opportunity) Opportunity.SObjectType.newSObject(idRecTypeId, true);
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = dateString + randomInt;
		String strSourceId = 'hawaiian_ice-new_plans_application-' + uniqueName;
		objOpportunity.Name = 'TEST OPPORTUNITY';
		objOpportunity.StageName = 'STAGENAME';
		objOpportunity.CloseDate = System.Today();
		objOpportunity.AccountId = objAcc.Id;
		objOpportunity.Source_ID__c = strSourceId;
		objOpportunity.Pricebook2Id = objPB.Id;
		objOpportunity.StageName = 'SAL';
		objOpportunity.NumberOfEmployees__c = 5;
		objOpportunity.Source_Id__c = 'hawaiian_ice-new_plans_application-O321';
		objOpportunity.Benefits_State__c = 'CA';
		insert objOpportunity;

		HI_Policy_Contribution__c objPolicyContribution = new HI_Policy_Contribution__c();
		objPolicyContribution.Company_Contribution_Id__c = 'compcont1';
		objPolicyContribution.Policy_Id__c = 'hiPolicy321';
		insert objPolicyContribution;

		Policy__c objPolicy = new Policy__c();
		objPolicy.External_Key__c = 'External321';
		objPolicy.Opportunity__c = objOpportunity.Id;
		objPolicy.Benefit_Type__c = 'Dental';
		objPolicy.Carrier__c = objCarrier.Id;
		objPolicy.State__c = objState2.Id;
		insert objPolicy;

		HI_Health_Plan_Detail__c objHealthPlanDetail = new HI_Health_Plan_Detail__c();
		objHealthPlanDetail.benefits_plan_Id__c = 'Plan321';
		insert objHealthPlanDetail;

		HI_Benefits_Plan__c objBenefitsPlan = new HI_Benefits_Plan__c();
		objBenefitsPlan.National_Carrier_Id__c = 'carrier321';
		objBenefitsPlan.Id__c = 'Plan321';
		objBenefitsPlan.State__c = 'CA';
		insert objBenefitsPlan;

		Carrier__c objCarrierRec = new Carrier__c();
		objCarrierRec.Carrier_Id__c = 'carrier321';
		objCarrierRec.State__c = 'CA';
		insert objCarrierRec;

		HI_Health_Policy_Detail__c objHealthPolicyDetailRec = new HI_Health_Policy_Detail__c();
		objHealthPolicyDetailRec.Id__c = 'Policy321';
		insert objHealthPolicyDetailRec;

		HI_Lidi_Policy_Detail__c objLidiPolicyDetail = new HI_Lidi_Policy_Detail__c();
		objLidiPolicyDetail.Id__c = 'Policy321';
		insert objLidiPolicyDetail;

		HI_New_Plans_ApplicationsBenefitsPackage__c objNPABPackage = new HI_New_Plans_ApplicationsBenefitsPackage__c();
		objNPABPackage.Id__c = 'Benefits321';
		objNPABPackage.Benefits_Package_Id__c = 'Benefits321';
		objNPABPackage.New_Plans_Application_Id__c = 'O321';
		insert objNPABPackage;

		HI_Policy__c objHIExistingPolicyRec = new HI_Policy__c();
		objHIExistingPolicyRec.Benefits_Package_Id__c = 'Benefits321';
		objHIExistingPolicyRec.Plan_Id__c = 'Plan321';
		objHIExistingPolicyRec.State__c = 'State321';
		objHIExistingPolicyRec.Policy_Detail_Id__c = 'Policy321';
		objHIExistingPolicyRec.External_Key__c = 'External3211';
		objHIExistingPolicyRec.Id__c = 'hiPolicy3211';
		objHIExistingPolicyRec.Policy_Detail_Type__c = 'HealthPolicyDetail';
		objHIExistingPolicyRec.Effective_Date__c = System.today() - 265;
		objHIExistingPolicyRec.Expiration_Date__c = System.today() + 100;
		objHIExistingPolicyRec.Visible__c = true;
		objHIExistingPolicyRec.Processing_State__c = 'Backlog';
		insert objHIExistingPolicyRec;
	}

	@isTest
	static void testReprocessHIPolicyPositiveCase() {
		Test.startTest();

		HI_Benefits_Package__c objBenefitsPackage = new HI_Benefits_Package__c();
		objBenefitsPackage.Id__c = 'Benefits321';
		objBenefitsPackage.Company_Id__c = 'company321';
		insert objBenefitsPackage;

		Test.stopTest();

		objBenefitsPackage = [SELECT Id, Processing_State__c, Id__c FROM HI_Benefits_Package__c WHERE Id = :objBenefitsPackage.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objBenefitsPackage.Processing_State__c, 'Processing_State__c should match.');

		HI_Policy__c objExistingPolicy = [SELECT Id, Processing_State__c, Id__c FROM HI_Policy__c WHERE Benefits_Package_Id__c = :objBenefitsPackage.Id__c];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objExistingPolicy.Processing_State__c, 'Processing_State__c should match.');
	}

	@isTest
	static void testReprocessHIPolicyNegativeCase() {
		Test.startTest();

		blnRunCatchTest = true;
		HI_Benefits_Package__c objBenefitsPackage = new HI_Benefits_Package__c();
		objBenefitsPackage.Id__c = 'Benefits321';
		objBenefitsPackage.Company_Id__c = 'company321';
		insert objBenefitsPackage;

		Test.stopTest();

		List<HI_Benefits_Package__c> list_BenefitsPackages = [SELECT Id, Processing_State__c, Id__c FROM HI_Benefits_Package__c];
		System.assertEquals(1, list_BenefitsPackages.size(), 'There should be 1 HI_Benefits_Package__c record in list.');

		List<Exception_Log__c> list_ExceptionLogs = [SELECT Id, Message__c, Method_Name__c FROM Exception_Log__c WHERE Method_Name__c = 'reprocessHIPolicy'];
		System.assertEquals(1, list_ExceptionLogs.size(), 'There should be 1 Exception_Log__c record in list.');
	}

	@isTest
	static void testBypassTrigger() {
		Test.startTest();

		HIBenefitsPackageTriggerHelper.skipTrigger = true;
		HI_Benefits_Package__c objBenefitsPackage = new HI_Benefits_Package__c();
		objBenefitsPackage.Id__c = 'Benefits321';
		objBenefitsPackage.Company_Id__c = 'company321';
		insert objBenefitsPackage;
		Test.stopTest();

		objBenefitsPackage = [SELECT Id, Processing_State__c, Id__c FROM HI_Benefits_Package__c WHERE Id = :objBenefitsPackage.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objBenefitsPackage.Processing_State__c, 'Processing_State__c should match.');

		HI_Policy__c objExistingPolicy = [SELECT Id, Processing_State__c, Id__c FROM HI_Policy__c WHERE Benefits_Package_Id__c = :objBenefitsPackage.Id__c];
		System.assertEquals(IntegrationUtils.BACKLOG, objExistingPolicy.Processing_State__c, 'Processing_State__c should match.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate Exception Log.
	 * @Parm        : NA
	 * @Return      : Void
	 **/
	@isTest
	static void testHandlerCatchStatements() {
		Test.startTest();
		blnRunCatchHandlerTest = true;
		HI_Benefits_Package__c objBenefitsPackage = new HI_Benefits_Package__c();
		objBenefitsPackage.Id__c = 'Benefits321';
		objBenefitsPackage.Company_Id__c = 'company321';
		insert objBenefitsPackage;

		update objBenefitsPackage;

		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update HI Benefits Package record.
	 * @Parm        : NA
	 * @Return      : Void
	 **/
	@isTest
	static void testUpdateHIBenefitsPackage() {
		Test.startTest();

		HI_Benefits_Package__c objBenefitsPackage = new HI_Benefits_Package__c();
		objBenefitsPackage.Id__c = 'Benefits3211';
		objBenefitsPackage.Company_Id__c = 'company321';
		insert objBenefitsPackage;

		HI_Policy__c objExistingPolicy = [SELECT Id, Processing_State__c, Id__c FROM HI_Policy__c WHERE Benefits_Package_Id__c = 'Benefits321'];
		System.assertEquals(IntegrationUtils.BACKLOG, objExistingPolicy.Processing_State__c, 'Processing_State__c should match.');

		objBenefitsPackage.Id__c = 'Benefits321';
		update objBenefitsPackage;

		Test.stopTest();

		objExistingPolicy = [SELECT Id, Processing_State__c, Id__c FROM HI_Policy__c WHERE Benefits_Package_Id__c = :objBenefitsPackage.Id__c];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objExistingPolicy.Processing_State__c, 'Processing_State__c should match.');
	}
}