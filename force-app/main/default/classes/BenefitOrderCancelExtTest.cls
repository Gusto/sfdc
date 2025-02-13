@isTest
private class BenefitOrderCancelExtTest {
	@testSetup
	static void setup() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OrdertriggerHelper.SkipTrigger = true;
		TicketTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		Opportunity objOppty = TestUtility.BenefitsBoROpportunity();

		Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', objOppty.Id, 'Test BO ', false);
		objBO.Status_Detail__c = 'STATUS DETAIL';
		insert objBO;

		Account objAccChange = new Account(Name = 'test acc2', ZP_Company_Id__c = '100989002');

		Opportunity objOpportunityChange = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change'));
		objOpportunityChange.AccountId = objAccChange.Id;
		objOpportunityChange.StageName = 'SAL';
		objOpportunityChange.Name = 'test';
		objOpportunityChange.CloseDate = System.today();
		insert objOpportunityChange;

		Benefit_Order__c objBenefitOrderChange = TestUtility.createTestBenefitOrder('Change', objOpportunityChange.Id, 'Test Change Benefit Order', false);
		objBenefitOrderChange.OwnerId = UserInfo.getUserId();
		insert objBenefitOrderChange;

		Ticket__c objTicket = new Ticket__c();
		objTicket.Benefit_Order__c = objBenefitOrderChange.Id;
		objTicket.Status__c = 'New';
		objTicket.OwnerId = UserInfo.getUserId();
		objTicket.Escalation_Reason__c = null;
		objTicket.Escalation_Reason_Detail__c = null;
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
		insert objTicket;

		BenefitOrderHelper.skipTrigger = false;
	}

	@isTest
	private static void cancel_benefit_order() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, RecordTypeId, OwnerId, Opportunity__r.OwnerId FROM Benefit_Order__c WHERE Name = 'Test BO' LIMIT 1];

		ApexPages.StandardController objController = new ApexPages.StandardController(objBO);
		BenefitOrderCancelExt objBOCancelExtension = new BenefitOrderCancelExt(objController);
		objBOCancelExtension.cancelBenefitOrder();

		Test.stopTest();

		objBO = [SELECT Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id LIMIT 1];
		System.assertEquals('Canceled', objBO.Order_Status__c);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, if there exist any open ticket for bo then we can not Canceled the order
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testBODoesNotCanceledWithOpenTicket() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, RecordTypeId, OwnerId, Opportunity__r.OwnerId FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];

		ApexPages.StandardController objController = new ApexPages.StandardController(objBO);
		BenefitOrderCancelExt objBOCancelExtension = new BenefitOrderCancelExt(objController);
		objBOCancelExtension.cancelBenefitOrder();

		Test.stopTest();

		objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test Change Benefit Order' LIMIT 1];
		System.assertNotEquals(objBO.Order_Status__c, BenefitOrderUtil.STATUS_CANCELLED);
	}
}