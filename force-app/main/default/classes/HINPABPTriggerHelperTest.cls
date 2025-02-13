/*
 * @name         : HINPABPTriggerHelperTest
 * @author       : Sanjay Paryani
 * @date         : 06-04-2021
 * @description  : Test class for HINPABPTriggerHelper
 */
@isTest
public class HINPABPTriggerHelperTest {
	public static boolean blnRunCatchTest = false;
	public static boolean blnRunCatchHandlerTest = false;

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Setup Data.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@TestSetup
	static void setupData() {
		skipTrigger(true);
		HI_Benefits_Package__c objBenefitsPackage = new TestDataFactory.HIBenefitsPackageBuilder()
			.setId('Benefits321')
			.setCompanyId('company321')
			.build();
		insert objBenefitsPackage;

		HI_Benefit_Change_Application__c objBCA = new TestDataFactory.HIBenefitChangeApplicationBuilder()
			.setBenefitPackageId('Benefits321')
			.setExternalKey('hawaiian_ice-new_plans_application-O321')
			.build();
		insert objBCA;

		State__c objState = new TestDataFactory.StateBuilder()
			.setName('California')
			.setId('California')
			.setAbbreviation('CA')
			.build();
		insert objState;

		HI_Renewal__c objRenewal = new TestDataFactory.HIRenewalBuilder()
			.setBenefitPackageId('Benefits321')
			.setExternalKey('hawaiian_ice-new_plans_application-O321')
			.build();
		insert objRenewal;

		Carrier__c objCarrier = TestUtility.createTestCarrier('Carrier', 'CA', false);
		objCarrier.Carrier_Id__c = 'carrier321';
		insert objCarrier;

		PriceBook2 objPB = TestUtility.createCompanyPriceBookInformation();

		State__c objState2 = new TestDataFactory.StateBuilder()
			.setName('Alabama')
			.setId('Alabama')
			.setAbbreviation('AL')
			.build();
		insert objState2;

		HI_Company_Contribution__c objCompanyContribution = new TestDataFactory.HICompanyContributionBuilder()
			.setId('compcont1')
			.setCompanyId('company321')
			.setType('HealthCompanyContribution')
			.setCalculatorInputs(
				'{"type"=>"employee_and_dependents", "employee_calculator"=>{"type"=>"percentage", "percentage"=>"0.5"}, "dependents_calculator"=>{"type"=>"percentage", "percentage"=>"0.25"}}'
			)
			.build();
		insert objCompanyContribution;

		Opportunity objOpportunity = TestUtility.BenefitsNewPlanOpportunity();
		objOpportunity.Pricebook2Id = objPB.id;
		objOpportunity.StageName = 'SAL';
		objOpportunity.NumberOfEmployees__c = 5;
		objOpportunity.Source_Id__c = 'hawaiian_ice-new_plans_application-O321';
		objOpportunity.Benefits_State__c = 'CA';
		update objOpportunity;

		Account objAcc = new Account(Id = objOpportunity.AccountId);
		objAcc.ZP_Company_Id__c = 'company321';
		update objAcc;

		HI_Policy_Contribution__c objPolicyContribution = new TestDataFactory.HIPolicyContributionBuilder()
			.setCompanyContributionId('compcont1')
			.setPolicyId('hiPolicy321')
			.build();
		insert objPolicyContribution;

		Policy__c objPolicy = TestUtility.createTestPolicy(
			objOpportunity.Id,
			objCarrier.Id,
			true,
			'Test Policy1',
			null,
			false
		);
		objPolicy.External_Key__c = 'External321';
		objPolicy.Benefit_Type__c = 'Dental';
		objPolicy.State__c = objState2.id;
		insert objPolicy;

		HI_Health_Plan_Detail__c objHealthPlanDetail = new TestDataFactory.HIHealthPlanDetailBuilder()
			.setBenefitsPlanId('Plan321')
			.build();
		insert objHealthPlanDetail;

		HI_Benefits_Plan__c objBenefitsPlan = new TestDataFactory.HIBenefitsPlanBuilder()
			.setNationalCarrierId('carrier321')
			.setId('Plan321')
			.setState('CA')
			.build();
		insert objBenefitsPlan;

		HI_Health_Policy_Detail__c objHealthPolicyDetailRec = new TestDataFactory.HIHealthPolicyDetailBuilder()
			.setId('Policy321')
			.build();
		insert objHealthPolicyDetailRec;

		HI_Lidi_Policy_Detail__c objLidiPolicyDetail = new TestDataFactory.HILidiPolicyDetailBuilder()
			.setId('Policy321')
			.build();
		insert objLidiPolicyDetail;

		HI_Policy__c objHIExistingPolicyRec = new TestDataFactory.HIPolicyBuilder()
			.setBenefitsPackageId('Benefits321')
			.setPlanId('Plan321')
			.setState('State321')
			.setPolicyDetailId('Policy321')
			.setExternalKey('External3211')
			.setId('hiPolicy3211')
			.setPolicyDetailType('HealthPolicyDetail')
			.setEffectiveDate(System.today() - 265)
			.setExpirationDate(System.today() + 100)
			.setVisible(true)
			.setProcessingState('Backlog')
			.setMessage('New Plan Opp does not exist.')
			.build();
		insert objHIExistingPolicyRec;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Reprocess HI Policy : Positive Case.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testReprocessHIPolicyPositiveCase() {
		Test.startTest();
		HI_New_Plans_ApplicationsBenefitsPackage__c objNPABPackage = new TestDataFactory.HINPApplicationsBenefitsPackageBuilder()
			.setId('Benefits321')
			.setBenefitsPackageId('Benefits321')
			.setNewPlansApplicationId('O321')
			.build();
		insert objNPABPackage;

		Test.stopTest();

		objNPABPackage = [
			SELECT Id, Processing_State__c, Id__c, Benefits_Package_Id__c
			FROM HI_New_Plans_ApplicationsBenefitsPackage__c
			WHERE Id = :objNPABPackage.Id
		];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objNPABPackage.Processing_State__c);

		HI_Policy__c objExistingPolicy = [
			SELECT Id, Processing_State__c, Id__c
			FROM HI_Policy__c
			WHERE Benefits_Package_Id__c = :objNPABPackage.Benefits_Package_Id__c
		];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objExistingPolicy.Processing_State__c);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Reprocess HI Policy : Negative Case.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testReprocessHIPolicyNegativeCase() {
		Test.startTest();
		blnRunCatchTest = true;
		HI_New_Plans_ApplicationsBenefitsPackage__c objNPABPackage = new TestDataFactory.HINPApplicationsBenefitsPackageBuilder()
			.setId('Benefits321')
			.setBenefitsPackageId('Benefits321')
			.setNewPlansApplicationId('O321')
			.build();
		insert objNPABPackage;

		Test.stopTest();

		List<HI_Benefits_Package__c> list_BenefitsPackages = [
			SELECT Id, Processing_State__c, Id__c
			FROM HI_Benefits_Package__c
		];
		System.assertEquals(1, list_BenefitsPackages.size());

		List<Exception_Log__c> list_ExceptionLogs = [
			SELECT Id, Message__c, Method_Name__c
			FROM Exception_Log__c
			WHERE Method_Name__c = 'reprocessHIPolicy'
		];
		System.assertEquals(1, list_ExceptionLogs.size());
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Reprocess HI Policy : By Pass Trigger.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testBypassTrigger() {
		Test.startTest();
		HINPABPTriggerHelper.skipTrigger = true;
		HIBenefitsPackageTriggerHelper.skipTrigger = true;
		HI_New_Plans_ApplicationsBenefitsPackage__c objNPABPackage = new TestDataFactory.HINPApplicationsBenefitsPackageBuilder()
			.setId('Benefits321')
			.setBenefitsPackageId('Benefits321')
			.setNewPlansApplicationId('O321')
			.build();
		insert objNPABPackage;

		Test.stopTest();

		objNPABPackage = [
			SELECT Id, Processing_State__c, Id__c, Benefits_Package_Id__c
			FROM HI_New_Plans_ApplicationsBenefitsPackage__c
			WHERE Id = :objNPABPackage.Id
		];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objNPABPackage.Processing_State__c);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Reprocess HI Policy : Handle Exception.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testHandlerCatchStatements() {
		Test.startTest();
		HINPABPTriggerHelperTest.blnRunCatchHandlerTest = true;
		HI_New_Plans_ApplicationsBenefitsPackage__c objNPABPackage = new TestDataFactory.HINPApplicationsBenefitsPackageBuilder()
			.setId('Benefits321')
			.setBenefitsPackageId('Benefits321')
			.setNewPlansApplicationId('O321')
			.build();
		insert objNPABPackage;

		Test.stopTest();

		System.assert([SELECT Id, Class_Name__c FROM Exception_Log__c].size() > 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		ZPCompanyTriggerHelper.queue = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
	}
}