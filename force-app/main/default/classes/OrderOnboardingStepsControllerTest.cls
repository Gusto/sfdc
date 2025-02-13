/**
 * @description  Get Onboarding Steps from Order
 * @author       Praveen Sethu
 * @date         12-1-2022
 **/
@isTest
public with sharing class OrderOnboardingStepsControllerTest {
	@isTest
	public static void testGetOnboardingSteps() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objBOROpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('BOR Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objBYBOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setName('BYOB Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		Opportunity objNPOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('NP Opp')
			.setAccountId(objCompAccount.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		insert new List<Opportunity>{ objOpportunity, objBOROpportunity, objBYBOpportunity, objNPOpportunity };

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setAccountId(objCompAccount.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Drafted')
			.setOwnerId(UserInfo.getUserId())
			.setEffectiveDate(Date.today())
			.build();
		insert objOrder;

		Test.startTest();
		Opportunity objOrderAssert = OrderOnboardingStepsController.getOnboardingSteps(objOrder.Id);
		Opportunity objOpptyAssert = OrderOnboardingStepsController.getOnboardingSteps(objOpportunity.Id);
		Opportunity objBOROpportunityAssert = OrderOnboardingStepsController.getOnboardingSteps(objBOROpportunity.Id);
		Opportunity objBYBOpportunityAssert = OrderOnboardingStepsController.getOnboardingSteps(objBYBOpportunity.Id);
		Opportunity objNPOpportunityAssert = OrderOnboardingStepsController.getOnboardingSteps(objNPOpportunity.Id);
		Test.stopTest();

		System.assertEquals(objOpportunity.Id, objOrderAssert.Id, 'Fetched opportunity is not company opportunity');
		System.assertEquals(objOpportunity.Id, objOrderAssert.Id, 'Fetched opportunity is not company opportunity');
		System.assertEquals(objOpportunity.Id, objBOROpportunityAssert.Id, 'Fetched opportunity is not company opportunity');
		System.assertEquals(objOpportunity.Id, objBYBOpportunityAssert.Id, 'Fetched opportunity is not company opportunity');
		System.assertEquals(objOpportunity.Id, objNPOpportunityAssert.Id, 'Fetched opportunity is not company opportunity');
	}
}