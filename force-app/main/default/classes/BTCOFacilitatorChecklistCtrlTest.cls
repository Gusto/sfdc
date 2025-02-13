/**
 * @name         BTCOFacilitatorChecklistCtrlTest
 * @author       Deepika, Bhagat
 * @date         24-01-2020
 * @description  Test class for BTCOFacilitatorChecklistCtrl
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
public class BTCOFacilitatorChecklistCtrlTest {
	@TestSetup
	static void setupData() {
		Carrier__c objCarrier = new Carrier__c();
		objCarrier.Name = 'TestCarrier';
		objCarrier.State__c = 'AL;AK';
		insert objCarrier;

		Carrier_Order__c objCarrierOrder = new Carrier_Order__c();
		objCarrierOrder.Name = 'TestParentCarrierOrder';
		objCarrierOrder.Carrier__c = objCarrier.Id;
		objCarrierOrder.Is_Multi_EIN__c = true;
		objCarrierOrder.Start_Date__c = System.today();
		objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		objCarrierOrder.Implementation_Stage__c = 'Qualification';
		objCarrierOrder.Facilitator_2_Plan_Build__c = 'Y';
		objCarrierOrder.Resign_Required__c = 'yes';
		objCarrierOrder.Resign_Required_Reason__c = 'yes';
		objCarrierOrder.Contribution_per_the_ER__c = 'test';
		insert objCarrierOrder;

		Carrier_Order_Line_Item__c objCarrieOrderLineItem = new Carrier_Order_Line_Item__c();
		objCarrieOrderLineItem.Carrier_Order__c = objCarrierOrder.Id;
		objCarrieOrderLineItem.Benefit_Types__c = 'Flexible Spending Account - Medical';
		insert objCarrieOrderLineItem;

		BOR_Master_Checklist__c objBORCheckPOints = new BOR_Master_Checklist__c();
		objBORCheckPOints.RecordTypeId = Cache.getRecordTypeId('BOR_Master_Checklist__c', 'Benefits');
		objBORCheckPOints.Mandatory__c = false;
		objBORCheckPOints.Optional_Checklist__c = false;
		insert objBORCheckPOints;
        
		BOR_Checklist__c objBORChecklist = new BOR_Checklist__c();
		objBORChecklist.Carrier_Order_Line_Item__c = objCarrieOrderLineItem.Id;
		objBORChecklist.BOR_Checkpoints__c = objBORCheckPOints.Id;
		insert objBORChecklist;

		Carrier__c objCarrier1 = new Carrier__c();
		objCarrier1.Name = 'TestCarrier';
		objCarrier1.State__c = 'AL;AK';
		insert objCarrier1;

		Carrier_Order__c objCarrierOrder1 = new Carrier_Order__c();
		objCarrierOrder1.Name = 'TestChildCarrierOrder';
		objCarrierOrder1.Carrier__c = objCarrier1.Id;
		objCarrierOrder1.Is_Multi_EIN__c = false;
		objCarrierOrder1.Parent_Carrier_Order__c = objCarrierOrder.Id;
		objCarrierOrder1.Start_Date__c = System.today();
		objCarrierOrder1.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		objCarrierOrder1.Implementation_Stage__c = 'Qualification';
		objCarrierOrder1.Facilitator_2_Plan_Build__c = 'Y';
		objCarrierOrder1.Resign_Required__c = 'yes';
		objCarrierOrder1.Resign_Required_Reason__c = 'yes';
		objCarrierOrder1.Contribution_per_the_ER__c = 'test';
		insert objCarrierOrder1;

		Carrier_Order_Line_Item__c objCarrieOrderLineItem1 = new Carrier_Order_Line_Item__c();
		objCarrieOrderLineItem1.Carrier_Order__c = objCarrierOrder1.Id;
		objCarrieOrderLineItem1.Benefit_Types__c = 'Flexible Spending Account - Medical';
		insert objCarrieOrderLineItem1;

		BOR_Master_Checklist__c objBORCheckPOints1 = new BOR_Master_Checklist__c();
		objBORCheckPOints1.RecordTypeId = Cache.getRecordTypeId('BOR_Master_Checklist__c', 'Benefits');
		objBORCheckPOints1.Mandatory__c = false;
		objBORCheckPOints1.Optional_Checklist__c = false;
		insert objBORCheckPOints1;

		BOR_Checklist__c objBORChecklist1 = new BOR_Checklist__c();
		objBORChecklist1.Carrier_Order_Line_Item__c = objCarrieOrderLineItem1.Id;
		objBORChecklist1.BOR_Checkpoints__c = objBORCheckPOints1.Id;
		insert objBORChecklist1;
	}

	static testMethod void testParentCarrierOrder() {
		Test.StartTest();
		List<Carrier_Order__c> coList = [SELECT id FROM Carrier_Order__c WHERE Name = 'TestParentCarrierOrder'];
		PageReference pageRef = Page.BTCOFacilitatorChecklist;
		pageRef.getParameters().put('id', coList[0].Id);
		Test.setCurrentPage(pageRef);

		BTCOFacilitatorChecklistCtrl ctrl_BTCOfacilitatorChecklist = new BTCOFacilitatorChecklistCtrl();
		ctrl_BTCOfacilitatorChecklist.saveDocument();

		BTCOFacilitatorChecklistCtrl ctrl_BTCOfacilitatorChecklist1 = new BTCOFacilitatorChecklistCtrl();
		ctrl_BTCOfacilitatorChecklist1.categorizeDocument('Required for Plan/Policy Build', 'policy');
		ctrl_BTCOfacilitatorChecklist1.objCarrierOrder.Resign_Required__c = 'yes';
		ctrl_BTCOfacilitatorChecklist1.objCarrierOrder.Resign_Required_Reason__c = 'yes';
		update ctrl_BTCOfacilitatorChecklist1.objCarrierOrder;
		ctrl_BTCOfacilitatorChecklist1.saveDocument();
		System.assertEquals('Qualification', ctrl_BTCOfacilitatorChecklist1.objCarrierOrder.Implementation_Stage__c, 'Implementation stage is not updated');
		Test.stopTest();
	}

	static testMethod void testParentChildOrder() {
		Test.StartTest();
		List<Carrier_Order__c> coList = [SELECT id FROM Carrier_Order__c WHERE Name = 'TestChildCarrierOrder'];
		PageReference pageRef = Page.BTCOFacilitatorChecklist;
		pageRef.getParameters().put('id', coList[0].Id);
		Test.setCurrentPage(pageRef);

		BTCOFacilitatorChecklistCtrl ctrl_BTCOfacilitatorChecklist = new BTCOFacilitatorChecklistCtrl();
		ctrl_BTCOfacilitatorChecklist.saveDocument();

		BTCOFacilitatorChecklistCtrl ctrl_BTCOfacilitatorChecklist1 = new BTCOFacilitatorChecklistCtrl();
		ctrl_BTCOfacilitatorChecklist1.categorizeDocument('Required for Plan/Policy Build', 'policy');
		ctrl_BTCOfacilitatorChecklist1.objCarrierOrder.Resign_Required__c = 'yes';
		ctrl_BTCOfacilitatorChecklist1.objCarrierOrder.Resign_Required_Reason__c = 'yes';
		update ctrl_BTCOfacilitatorChecklist1.objCarrierOrder;
		ctrl_BTCOfacilitatorChecklist1.saveDocument();
		ctrl_BTCOfacilitatorChecklist1.UpdateAllCOStatus(ctrl_BTCOfacilitatorChecklist1.objCarrierOrder.Parent_Carrier_Order__c);
		System.assertEquals('Qualification', ctrl_BTCOfacilitatorChecklist1.objCarrierOrder.Implementation_Stage__c, 'Implementation stage is not updated');
		Test.stopTest();
	}
}