/**
 * @name         BTTADACheckListCtrlTest
 * @author       Vinay
 * @date         26-02-2020
 * @description  Test class for BTTADACheckListCtrl class . VF page - BTTADACheckList
 **/

@isTest
public class BTTADACheckListCtrlTest {
	static testMethod void testMethod1() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
		opp1.NumberOfEmployees__c = 12;
		update opp1;

		Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
		Transition_to_Fulfillment__c ttfRecord = new Transition_to_Fulfillment__c();
		ttfRecord.Opportunity__c = opp1.Id;
		insert ttfRecord;

		Carrier__c objCarrier = new Carrier__c();
		objCarrier.Name = 'TestCarrier';
		objCarrier.State__c = 'NY;CA';
		insert objCarrier;

		Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
		obj_CarrierOrder.Carrier__c = objCarrier.Id;
		obj_CarrierOrder.Start_Date__c = System.today();
		obj_CarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		obj_CarrierOrder.Implementation_Stage__c = 'implementing Tada Plans';
		obj_CarrierOrder.Facilitator_2_Plan_Build__c = 'Y';
		obj_CarrierOrder.Resign_Required__c = 'No';
		obj_CarrierOrder.Contribution_per_the_ER__c = 'test';
		insert obj_CarrierOrder;

		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(obj_CarrierOrder);
		ApexPages.currentPage().getParameters().put('COID', obj_CarrierOrder.id);

		Carrier_Order_Line_Item__c objCarrieOrderLineItem = new Carrier_Order_Line_Item__c();
		objCarrieOrderLineItem.Carrier_Order__c = obj_CarrierOrder.Id;
		objCarrieOrderLineItem.Benefit_Types__c = 'Flexible Spending Account - Medical';
		insert objCarrieOrderLineItem;

		BOR_Master_Checklist__c objBORCheckPOints = new BOR_Master_Checklist__c();
		objBORCheckPOints.Mandatory__c = false;
		objBORCheckPOints.Optional_Checklist__c = false;
		insert objBORCheckPOints;

		BOR_Checklist__c BOR_Checklist = new BOR_Checklist__c();
		BOR_Checklist.Carrier_Order_Line_Item__c = objCarrieOrderLineItem.Id;
		BOR_Checklist.BOR_Checkpoints__c = objBORCheckPOints.Id;
		BOR_Checklist.TADA_Status__c = 'Implementing TAdA Plans';
		BOR_Checklist.IsCheckPointImplemented__c = false;
		insert BOR_Checklist;

		test.startTest();
		BTTADACheckListCtrl b1 = new BTTADACheckListCtrl();

		// Check initial conditions for obj_CarrierOrder and Implementation_Stage__c
		System.assertEquals(b1.obj_CarrierOrder.Id, obj_CarrierOrder.Id, 'Carrier Order ID should match');
		System.assertEquals(b1.obj_CarrierOrder.Implementation_Stage__c, 'Implementing TAdA Plans', 'Implementation Stage should be "Implementing TAdA Plans"');

		b1.SaveChecklist();
		b1.SaveAndSubmitChecklist();

		// Assert that after Save and Submit the checklist points are saved
		List<BOR_Checklist__c> list_borChecklist = [SELECT Id, IsCheckPointImplemented__c FROM BOR_Checklist__c WHERE Carrier_Order_Line_Item__c = :objCarrieOrderLineItem.Id];
		System.assertNotEquals(list_borChecklist.size(), 0, 'BOR Checklists should be saved');
		System.assertEquals(list_borChecklist[0].IsCheckPointImplemented__c, false, 'Checkpoint should not be implemented yet');

		obj_CarrierOrder.Implementation_Stage__c = 'Balance Collection';
		update obj_CarrierOrder;

		// Check that the Implementation_Stage__c value is updated
		Carrier_Order__c updatedCarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
		System.assertEquals(updatedCarrierOrder.Implementation_Stage__c, 'Balance Collection', 'Implementation Stage should be updated to "Balance Collection"');

		ApexPages.currentPage().getParameters().put('costage', 'Active');
		b1.GetStageChecklistValue();

		test.stopTest();
	}

	static testMethod void testMethod2() {
		BTTADACheckListCtrl b2 = new BTTADACheckListCtrl();
		b2.SaveChecklist();
		b2.SaveAndSubmitChecklist();
		b2.MarkComplete();
		b2.updateImplementationStage(false, false);

		// Assert that the updateImplementationStage should return false
		System.assertEquals(false, b2.updateImplementationStage(false, false), 'The updateImplementationStage should return false');
	}
}