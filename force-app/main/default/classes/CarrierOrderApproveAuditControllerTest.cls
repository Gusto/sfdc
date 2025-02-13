/*
 * Description: Test Class for CarrierOrderApproveAuditController
 * Author: Omar Benitez
 * Date: 05/05/2024
 */
@isTest
public class CarrierOrderApproveAuditControllerTest {
	@testSetup
	static void setUp() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		Opportunity objOpp1 = TestUtility.BenefitsNewPlanOpportunity();

		Benefit_Order__c objBenefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', objOpp1.Id, 'Test Benefit Order', true);

		objBenefitOrdr1.Order_Status__c = 'OE';
		objBenefitOrdr1.Coverage_Effective_Date__c = System.today();
		objBenefitOrdr1.Open_Enrollment_Start_Date__c = System.today();
		objBenefitOrdr1.Open_Enrollment_End_Date__c = System.today();
		objBenefitOrdr1.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrdr1;

		Carrier__c objTestCarrier = TestUtility.Carrier();

		List<Carrier_Order__c> lst_CarrierOrder = new List<Carrier_Order__c>();
		Carrier_Order__c objCarOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarOrder.Name = 'TEST CARRIER ORDER';
		objCarOrder.Carrier__c = objTestCarrier.Id;
		objCarOrder.Benefit_Order__c = objBenefitOrdr1.Id;
		objCarOrder.Implementation_Stage__c = 'With Advising';
		objCarOrder.Order_Type__c = 'TAdA: Pre OE Setup';
		objCarOrder.Stage_Detail__c = 'TAdA Setup Complete';
		lst_CarrierOrder.add(objCarOrder);

		Carrier_Order__c objCarOrder1 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarOrder1.Name = 'TEST CARRIER ORDER 1';
		objCarOrder1.Carrier__c = objTestCarrier.Id;
		objCarOrder1.Benefit_Order__c = objBenefitOrdr1.Id;
		objCarOrder1.Implementation_Stage__c = 'Approved';
		objCarOrder1.OwnerId = UserInfo.getUserId();
		objCarOrder1.Stage_Detail__c = 'TAdA Setup Complete';
		lst_CarrierOrder.add(objCarOrder1);

		Carrier_Order__c objCarOrder2 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarOrder2.Name = 'TEST CARRIER ORDER 2';
		objCarOrder2.Carrier__c = objTestCarrier.Id;
		objCarOrder2.Benefit_Order__c = objBenefitOrdr1.Id;
		objCarOrder2.Implementation_Stage__c = 'Approved';
		objCarOrder2.OwnerId = UserInfo.getUserId();
		objCarOrder2.Stage_Detail__c = 'TAdA Setup Complete';
		lst_CarrierOrder.add(objCarOrder2);
		insert lst_CarrierOrder;

		objCarOrder2.Parent_Carrier_Order__c = lst_CarrierOrder[1].Id;
		update objCarOrder2;
	}
	/*
	 * Description: Test Method for getOptions
	 * Author: Omar Benitez
	 * Date: 05/05/2024
	 */
	@isTest
	static void testGetOptions() {
		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c WHERE Name = 'TEST CARRIER ORDER' LIMIT 1];
		Test.startTest();
		Map<String, Object> map_response = CarrierOrderApproveAuditController.getOptions(objCarrierOrder.Id);
		Test.stopTest();
		Map<String, String> map_ImplementationStage = (Map<String, String>) map_response.get('implementationStageOptions');
		Map<String, String> map_implementationStageDetailOptions = (Map<String, String>) map_response.get('implementationStageDetailOptions');
		String strImplementationStage = (String) map_response.get('implementationStage');
		Carrier_Order__c objCarrierOrderRes = (Carrier_Order__c) map_response.get('objCarrierOrder');
		Boolean blnHasTadaOrder = (Boolean) map_response.get('blnHasTadaOrder');
		System.assertNotEquals(0, map_ImplementationStage.size(), 'Options should not be empty');
		System.assertNotEquals(0, map_implementationStageDetailOptions.size(), 'Options should not be empty');
		System.assertEquals('Approved', strImplementationStage, 'It should be Approved');
		System.assertNotEquals(null, objCarrierOrderRes, 'CO should not be null');
		System.assertEquals(true, blnHasTadaOrder, 'tada should be true');
	}

	/*
	 * Description: Test Method for getOptions with TAdA Selected
	 * Author: Omar Benitez
	 * Date: 05/05/2024
	 */
	@isTest
	static void testGetOptionsNotTAdA() {
		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c WHERE Name = 'TEST CARRIER ORDER 1' LIMIT 1];
		Test.startTest();
		Map<String, Object> map_response = CarrierOrderApproveAuditController.getOptions(objCarrierOrder.Id);
		Test.stopTest();
		Map<String, String> map_ImplementationStage = (Map<String, String>) map_response.get('implementationStageOptions');
		Map<String, String> map_implementationStageDetailOptions = (Map<String, String>) map_response.get('implementationStageDetailOptions');
		String strImplementationStage = (String) map_response.get('implementationStage');
		Carrier_Order__c objCarrierOrderRes = (Carrier_Order__c) map_response.get('objCarrierOrder');
		Boolean blnHasTadaOrder = (Boolean) map_response.get('blnHasTadaOrder');
		System.assertNotEquals(0, map_ImplementationStage.size(), 'Options should not be empty');
		System.assertNotEquals(0, map_implementationStageDetailOptions.size(), 'Options should not be empty');
		System.assertEquals('Approved', strImplementationStage, 'It should be Approved');
		System.assertNotEquals(null, objCarrierOrderRes, 'CO should not be null');
		System.assertEquals(false, blnHasTadaOrder, 'tada should be false');
	}

	/*
	 * Description: Test Method for save order
	 * Author: Omar Benitez
	 * Date: 05/05/2024
	 */
	@isTest
	static void testSaveOrder() {
		Carrier_Order__c objCarrierOrder = [
			SELECT Id, Implementation_Stage__c, Stage_Detail__c, Order_Type__c, Approval_Notes__c, Approval_Method__c, Benefit_Order__c, RecordTypeId
			FROM Carrier_Order__c
			WHERE Name = 'TEST CARRIER ORDER 1'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Approved';
		objCarrierOrder.Approval_Notes__c = 'The note';
		Test.startTest();
		Object response = CarrierOrderApproveAuditController.saveOrder(objCarrierOrder);
		objCarrierOrder = [
			SELECT Id, Implementation_Stage__c, Stage_Detail__c, Order_Type__c, Approval_Notes__c, Approval_Method__c, Benefit_Order__c, RecordTypeId
			FROM Carrier_Order__c
			WHERE Name = 'TEST CARRIER ORDER 1'
			LIMIT 1
		];
		Test.stopTest();
		System.assertEquals(null, response, 'Response should be null');
		System.assertEquals('Approved', objCarrierOrder.Implementation_Stage__c, 'Implementation Stage should be approved');
		System.assertEquals('The note', objCarrierOrder.Approval_Notes__c, 'Approved Notes should be the note');
	}

	/*
	 * Description: Test Method for save order with TAdA selected
	 * Author: Omar Benitez
	 * Date: 05/05/2024
	 */
	@isTest
	static void testSaveOrderTAdA() {
		Carrier_Order__c objCarrierOrder = [
			SELECT Id, Implementation_Stage__c, Stage_Detail__c, Order_Type__c, Approval_Notes__c, Approval_Method__c, Benefit_Order__c, RecordTypeId
			FROM Carrier_Order__c
			WHERE Name = 'TEST CARRIER ORDER'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Approved';
		objCarrierOrder.Approval_Notes__c = 'The note';
		Test.startTest();
		Object saveOrderResponse = CarrierOrderApproveAuditController.saveOrder(objCarrierOrder);
		objCarrierOrder = [
			SELECT Id, Implementation_Stage__c, Stage_Detail__c, Order_Type__c, Approval_Notes__c, Approval_Method__c, Benefit_Order__c, RecordTypeId
			FROM Carrier_Order__c
			WHERE Name = 'TEST CARRIER ORDER'
			LIMIT 1
		];
		Test.stopTest();
		System.assertEquals(null, saveOrderResponse, 'Response should be null');
		System.assertEquals('Approved', objCarrierOrder.Implementation_Stage__c, 'Implementation Stage should be approved');
		System.assertEquals('The note', objCarrierOrder.Approval_Notes__c, 'Approved Notes should be the note');
	}
}