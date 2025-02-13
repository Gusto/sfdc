@isTest
/*
 * To cover unit test scenarios of BTNotificationCmpCtrl
 */
private class BTNotificationCmpCtrlTest {
	private static void setupTestData() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		//Benefit Order

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
		opp1.NumberOfEmployees__c = 12;
		update opp1;
		Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', opp1.Id, 'Test Benefit Order', true);

		//Carrier
		Carrier__c objCarrier = new Carrier__c();
		objCarrier.Name = 'TestCarrier';
		objCarrier.State__c = 'AL;AK';
		insert objCarrier;

		//Carrier Order
		Carrier_Order__c objCarrierOrder = new Carrier_Order__c();
		objCarrierOrder.Name = 'TestCarrierOrder';
		objCarrierOrder.Carrier__c = objCarrier.Id;
		objCarrierOrder.Start_Date__c = System.today();
		objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		objCarrierOrder.Implementation_Stage__c = 'Qualification';
		objCarrierOrder.Facilitator_2_Plan_Build__c = 'Y';
		objCarrierOrder.Resign_Required__c = 'No';
		objCarrierOrder.Contribution_per_the_ER__c = 'test';
		objCarrierOrder.Benefit_Order__c = objBO.Id;
		insert objCarrierOrder;

		//CO Line Item
		Carrier_Order_Line_Item__c objCarrieOrderLineItem = new Carrier_Order_Line_Item__c();
		objCarrieOrderLineItem.Carrier_Order__c = objCarrierOrder.Id;
		objCarrieOrderLineItem.Benefit_Types__c = 'Flexible Spending Account - Medical';
		objCarrieOrderLineItem.Renewal_Date__c = system.today().addDays(10);

		insert objCarrieOrderLineItem;
	}
	@isTest
	private static void testBTNotificationCmpCtrlWithCarrierInfo() {
		test.startTest();
		setupTestData();
		BTNotificationCmpCtrl ctrl = new BTNotificationCmpCtrl();
		ctrl.strInfoNeeded = 'Benefits type with carrier';
		ctrl.strObjectToBeQueried = 'Carrier_Order__c';
		ctrl.strFieldNameToCompare = 'Benefit_Order__c';

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordType.Name = 'Benefits BoR' LIMIT 1];
		ctrl.strRecordIdToCompare = objBO.Id;

		Map<String, Object> map_Res = ctrl.mapResults;

		system.assert(map_Res != null, 'Map cannot be null');
		test.stopTest();
	}
	@isTest
	private static void testBTNotificationCmpCtrlWithRenewalInfo() {
		test.startTest();
		setupTestData();
		BTNotificationCmpCtrl ctrl = new BTNotificationCmpCtrl();
		ctrl.strInfoNeeded = 'Benefits type with renewal month';
		ctrl.strObjectToBeQueried = 'Carrier_Order__c';
		ctrl.strFieldNameToCompare = 'Benefit_Order__c';

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordType.Name = 'Benefits BoR' LIMIT 1];
		ctrl.strRecordIdToCompare = objBO.Id;

		Map<String, Object> map_Res = ctrl.mapResults;

		system.assert(map_Res != null, 'Map cannot be null');
		test.stopTest();
	}
	@isTest
	private static void testBTNotificationCmpCtrlNegativeWithoutObjName() {
		test.startTest();
		BTNotificationCmpCtrl ctrl = new BTNotificationCmpCtrl();

		Map<String, Object> map_Res = ctrl.mapResults;

		system.assert(map_Res.size() == 0, 'Incorrect Map Size');
		test.stopTest();
	}
	@isTest
	private static void testBTNotificationCmpCtrlNegativeWithObjName() {
		test.startTest();
		BTNotificationCmpCtrl ctrl = new BTNotificationCmpCtrl();
		ctrl.strInfoNeeded = 'Benefits type with renewal month';
		ctrl.strObjectToBeQueried = 'Carrier_Order__c';
		Map<String, Object> map_Res = ctrl.mapResults;
		ctrl.getTodayPlusFiveBusinessDays();

		system.assert(map_Res.size() == 0, 'Incorrect Map Size');
		test.stopTest();
	}
}