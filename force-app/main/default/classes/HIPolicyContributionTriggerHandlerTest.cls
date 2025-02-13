/*
 * @name         : HIPolicyContributionTriggerHandlerTest
 * @author       : Rushi Ravisaheb
 * @date         : 12-22-2021
 */
@isTest
public class HIPolicyContributionTriggerHandlerTest {
	public static Boolean blnRunCatchTest = false;

	@testSetup
	static void makeData() {
		Utils.skipTrigger(true);

		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(Cache.getRecordTypeId('Account', 'Company')).setZPCompanyId('company321').setName('test').build();
		insert objAcc;

		State__c objState = new State__c(Abbreviation__c = 'CA', Name = 'California', Id__c = '5', Key__c = 'CA');
		insert objState;

		PriceBook2 objPB = TestUtility.createCompanyPriceBookInformation();

		Carrier__c objCarrier = TestUtility.createTestCarrier('Carrier', 'CA', true);

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('TEST OPPORTUNITY')
			.setAccountId(objAcc.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.setSourceID('hawaiian_ice-new_plans_application-O321')
			.build();
		objOpportunity.Pricebook2Id = objPB.id;
		objOpportunity.NumberOfEmployees__c = 35;
		objOpportunity.Benefits_State__c = 'CA';
		insert objOpportunity;

		insert new TestDataFactory.HIHealthPlanDetailBuilder().setBenefitsPlanId('Plan321').build();

		insert new TestDataFactory.HIBenefitsPlanBuilder().setNationalCarrierId('carrier321').setId('Plan321').setState('CA').build();

		insert new TestDataFactory.HICompanyContributionBuilder()
			.setId('compcont1')
			.setCompanyId('company321')
			.setType('HealthCompanyContribution')
			.setCalculatorInputs(
				'{"type"=>"employee_and_dependents", "employee_calculator"=>{"type"=>"percentage", "percentage"=>"0.5"}, "dependents_calculator"=>{"type"=>"percentage", "percentage"=>"0.25"}}'
			)
			.build();

		insert new TestDataFactory.HIBenefitsPackageBuilder().setId('Benefits321').setCompanyId('company321').build();

		insert new TestDataFactory.HIHealthPolicyDetailBuilder().setId('Policy321').build();

		insert new TestDataFactory.HILidiPolicyDetailBuilder().setId('Policy321').build();

		insert new TestDataFactory.HINPApplicationsBenefitsPackageBuilder().setId('Benefits321').setBenefitsPackageId('Benefits321').setNewPlansApplicationId('O321').build();

		insert new TestDataFactory.HIPolicyBuilder()
			.setBenefitsPackageId('Benefits321')
			.setPlanId('Plan321')
			.setState('CA')
			.setPolicyDetailId('Policy321')
			.setExternalKey('External321')
			.setId('hiPolicy321')
			.setPolicyDetailType('HealthPolicyDetail')
			.setEffectiveDate(system.today() - 265)
			.setExpirationDate(system.today() + 100)
			.setVisible(true)
			.setProcessingState('Backlog')
			.build();

		insert new Policy__c(
			External_Key__c = 'External321',
			Opportunity__c = objOpportunity.Id,
			Benefit_Type__c = 'Dental',
			Carrier__c = objCarrier.Id,
			State__c = objState.Id,
			Id__c = 'hiPolicy321'
		);

		insert new Carrier__c(Carrier_Id__c = 'carrier321', State__c = 'CA');
		Utils.skipTrigger(false);
	}

	/**
	 * @author      : Rushi Ravisaheb
	 * @description : Validate the Policy gets updated upon Policy Contribution inserts
	 **/
	@isTest
	static void testHIPolicyContributionAfter() {
		Test.startTest();
		insert new TestDataFactory.HIPolicyContributionBuilder().setCompanyContributionId('compcont1').setPolicyId('hiPolicy321').build();
		Test.stopTest();

		System.assertEquals(IntegrationUtils.PROCESSED_STATE, [SELECT Id, Processing_State__c FROM HI_Policy__c WHERE Id__c = 'hiPolicy321'].Processing_State__c);
		System.assertNotEquals(null, [SELECT Id, Contribution_Scheme_Type__c FROM Policy__c WHERE Id__c = 'hiPolicy321'].Contribution_Scheme_Type__c);
	}

	/**
	 * @author      : Rushi Ravisaheb
	 * @description : Validate the helper skips updates if the Contribution is already populated
	 **/
	@isTest
	static void testHIPolicyContributionBefore() {
		Policy__c objPolicy = [SELECT Id, Contribution_Scheme_Type__c FROM Policy__c WHERE Id__c = 'hiPolicy321'];
		objPolicy.Contribution_Scheme_Type__c = 'HealthTest';
		update objPolicy;

		Test.startTest();
		insert new TestDataFactory.HIPolicyContributionBuilder().setCompanyContributionId('compcont1').setPolicyId('hiPolicy321').build();
		Test.stopTest();

		System.assertEquals(null, [SELECT Id, Contribution_for_EEs__c FROM Policy__c WHERE Id__c = 'hiPolicy321'].Contribution_for_EEs__c);
	}

	/**
	 * @author      : Rushi Ravisaheb
	 * @description : Validate the Bypass Trigger logic
	 **/
	@isTest
	static void testBypassTrigger() {
		Test.startTest();
		HIPolicyContributionTriggerHandler.skipTrigger = true;
		insert new TestDataFactory.HIPolicyContributionBuilder().setCompanyContributionId('compcont1').setPolicyId('hiPolicy321').build();
		Test.stopTest();

		System.assertEquals(null, [SELECT Id, Contribution_Scheme_Type__c FROM Policy__c WHERE Id__c = 'hiPolicy321'].Contribution_Scheme_Type__c);
	}

	/**
	 * @author      : Rushi Ravisaheb
	 * @description : Validate the Exception logic for Trigger
	 **/
	@isTest
	static void testReprocessException() {
		Test.startTest();
		blnRunCatchTest = true;
		insert new TestDataFactory.HIPolicyContributionBuilder().setCompanyContributionId('compcont1').setPolicyId('hiPolicy321').build();
		Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM HI_Policy_Contribution__c].size());
		System.assertEquals(1, [SELECT Id FROM Exception_Log__c WHERE Method_Name__c = 'reprocessHIPolicy'].size());
	}
}