@isTest
public class UpdateOrderStatusExtTest {
	@testSetup
	private static void create_Test_Data() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);

		benefitOrdr1.Order_Status__c = 'OE';
		benefitOrdr1.ownerID = UserInfo.getUserId();
		benefitOrdr1.Coverage_Effective_Date__c = System.today();
		benefitOrdr1.Open_Enrollment_Start_Date__c = System.today();
		benefitOrdr1.Open_Enrollment_End_Date__c = System.today();
		benefitOrdr1.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update benefitOrdr1;

		Carrier__c testCarrier = TestUtility.Carrier();

		List<Carrier_Order__c> lstCarrierOrder = new List<Carrier_Order__c>();
		Carrier_Order__c carOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder.Name = 'TEST CARRIER ORDER';
		carOrder.Carrier__c = testCarrier.Id;
		carOrder.Benefit_Order__c = benefitOrdr1.Id;
		carOrder.Implementation_Stage__c = 'With Advising';
		lstCarrierOrder.add(carOrder);

		Carrier_Order__c carOrder1 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder1.Name = 'TEST CARRIER ORDER 1';
		carOrder1.Carrier__c = testCarrier.Id;
		carOrder1.Benefit_Order__c = benefitOrdr1.Id;
		carOrder1.Implementation_Stage__c = 'With Sales';
		lstCarrierOrder.add(carOrder1);

		Carrier_Order__c carOrder2 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder2.Name = 'TEST CARRIER ORDER 2';
		carOrder2.Carrier__c = testCarrier.Id;
		carOrder2.Benefit_Order__c = benefitOrdr1.Id;
		carOrder2.RecordTypeId = cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		carOrder2.Implementation_Stage__c = 'With Advising';
		carOrder2.Order_Type__c = 'TAdA: Pre OE Setup';
		lstCarrierOrder.add(carOrder2);
		Carrier_Order__c carOrder3 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder3.Name = 'TEST CARRIER ORDER 3';
		carOrder3.Carrier__c = testCarrier.Id;
		carOrder3.Benefit_Order__c = benefitOrdr1.Id;
		carOrder3.Implementation_Stage__c = 'With Advising';
		carOrder3.Benefit_Types__c = 'HSA';
		lstCarrierOrder.add(carOrder3);

		insert lstCarrierOrder;
	}

	static testMethod void testUpdateCarrier() {
		List<Benefit_Order__c> boList = [SELECT Id FROM Benefit_Order__c];
		List<Carrier_Order__c> coList = [SELECT Id, Benefit_Types__c FROM Carrier_Order__c];
		Test.startTest();
		ApexPages.CurrentPage().getparameters().put('id', boList[0].Id);
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(coList);
		stdController.setSelected(coList);
		UpdateOrderStatusExt extension = new UpdateOrderStatusExt(stdController);
		extension.objNonTadaCO.Implementation_Stage__c = 'With Advising';
		extension.objTadaCO.Implementation_Stage__c = 'Approved';
		extension.objTadaCO.Implementation_Stage__c = 'TAdA Setup Complete';
		extension.updateStatus();
		Test.stopTest();

		Benefit_Order__c boObj = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Id = :boList[0].Id];
		system.assertEquals(boObj.Order_Status__c, 'With Advising');
	}
	static testMethod void testSelectedUpdateCarrier() {
		List<Benefit_Order__c> boList = [SELECT Id FROM Benefit_Order__c];
		Test.startTest();
		ApexPages.CurrentPage().getparameters().put('id', boList[0].Id);
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(new List<Carrier_Order__c>());
		UpdateOrderStatusExt extension = new UpdateOrderStatusExt(stdController);
		Test.stopTest();
	}
	static testMethod void testCanceledCO() {
		List<Benefit_Order__c> boList = [SELECT Id FROM Benefit_Order__c];
		List<Carrier_Order__c> coList = [SELECT Id, Benefit_Types__c FROM Carrier_Order__c];
		Test.startTest();
		ApexPages.CurrentPage().getparameters().put('id', boList[0].Id);
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(coList);
		stdController.setSelected(coList);
		UpdateOrderStatusExt extension = new UpdateOrderStatusExt(stdController);
		extension.objNonTadaCO.Implementation_Stage__c = 'Canceled';
		extension.objNonTadaCO.Stage_Detail__c = '	Owner only group';
		extension.objTadaCO.Implementation_Stage__c = 'Canceled';
		extension.objTadaCO.Stage_Detail__c = '	Owner only group';
		extension.updateStatus();
		Test.stopTest();
		UpdateOrderStatusExt extension1 = new UpdateOrderStatusExt(stdController);
		extension1.objNonTadaCO.Implementation_Stage__c = 'Ready for Qualification';
		extension1.objTadaCO.Implementation_Stage__c = 'Ready for Qualification';
		extension1.coTerObj.Implementation_Stage__c = 'Ready for Qualification';
		extension1.updateStatus();
	}
	static testMethod void testBenefitsBoRCO() {
		Test.startTest();
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		Opportunity opp1 = TestUtility.BenefitsBoROpportunity();

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('Benefits BoR', opp1.Id, 'Test Benefit Order', false);
		benefitOrdr1.ownerID = UserInfo.getUserId();
		benefitOrdr1.Order_Status__c = 'Ready for Qualification';
		insert benefitOrdr1;

		Carrier__c testCarrier = TestUtility.Carrier();
		List<Carrier_Order__c> lstCarrierOrder = new List<Carrier_Order__c>();
		// / createTestCarrierOrder(Id carrierId, String name, Id benefitOrderId, Boolean isInsert
		Carrier_Order__c carOrder = TestUtility.createTestCarrierOrder(testCarrier.Id, 'Test Benefit Order', benefitOrdr1.Id, false);
		carOrder.Implementation_Stage__c = 'Ready for Qualification';
		insert carOrder;
		lstCarrierOrder.add(carOrder);
		ApexPages.CurrentPage().getparameters().put('id', benefitOrdr1.Id);
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(lstCarrierOrder);
		stdController.setSelected(new List<Carrier_Order__c>(lstCarrierOrder));
		UpdateOrderStatusExt extension = new UpdateOrderStatusExt(stdController);
		extension.objNonTadaCO.Implementation_Stage__c = 'Canceled';
		extension.GetNonTadaStageDetail();
		extension.objNonTadaCO.Stage_Detail__c = '	Owner only group';
		extension.objTadaCO.Implementation_Stage__c = 'Canceled';
		extension.GetTadaStageDetail();
		extension.objTadaCO.Stage_Detail__c = '	Owner only group';
		extension.updateStatus();
		Test.stopTest();
	}
	static testMethod void testBenefitsBoRCOWithCanceledOrder() {
		Test.startTest();
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		Opportunity opp1 = TestUtility.BenefitsBoROpportunity();

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('Benefits BoR', opp1.Id, 'Test Benefit Order', false);
		benefitOrdr1.ownerID = UserInfo.getUserId();
		benefitOrdr1.Order_Status__c = 'Ready for Qualification';
		insert benefitOrdr1;

		Carrier__c testCarrier = TestUtility.Carrier();
		List<Carrier_Order__c> lstCarrierOrder = new List<Carrier_Order__c>();
		// / createTestCarrierOrder(Id carrierId, String name, Id benefitOrderId, Boolean isInsert
		Carrier_Order__c carOrder = TestUtility.createTestCarrierOrder(testCarrier.Id, 'Test Benefit Order', benefitOrdr1.Id, false);
		carOrder.Implementation_Stage__c = 'Ready for Qualification';
		insert carOrder;
		lstCarrierOrder.add(carOrder);
		ApexPages.CurrentPage().getparameters().put('id', benefitOrdr1.Id);
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(lstCarrierOrder);
		stdController.setSelected(new List<Carrier_Order__c>(lstCarrierOrder));
		UpdateOrderStatusExt extension = new UpdateOrderStatusExt(stdController);
		extension.objNonTadaCO.Implementation_Stage__c = 'Canceled';
		extension.GetNonTadaStageDetail();
		extension.objNonTadaCO.Stage_Detail__c = 'Other';
		extension.objTadaCO.Implementation_Stage__c = 'Canceled';
		extension.GetTadaStageDetail();
		extension.objTadaCO.Stage_Detail__c = '	Other';
		extension.updateStatus();

		extension.objNonTadaCO.Additional_Details__c = 'Test';
		extension.objTadaCO.Additional_Details__c = 'Test';
		CarrierOrderTriggerHelper.skipTrigger = false;
		BenefitOrderHelper.skipTrigger = false;
		extension.updateStatus();
		Test.stopTest();
	}
}