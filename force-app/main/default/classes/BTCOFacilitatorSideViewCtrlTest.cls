/**
 * @name         BTCOFacilitatorSideViewCtrlTest
 * @author       Vinay
 * @date         27-02-2020
 * @description  Test class for BTCOFacilitatorSideViewCtrl class . VF page - BTCOFacilitatorSideView
 **/

@isTest
public class BTCOFacilitatorSideViewCtrlTest {
	static testMethod void testMethod1() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Account acc1 = TestUtility.CompanyAccount();

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
		Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
		boRec.Qualification_Follow_Up_Date__c = date.newInstance(2019, 10, 21);
		borec.Order_Status__c = 'Ready for Document Collection';
		borec.End_Date__c = System.today();
		update borec;

		Carrier__c obj_Carrier = new Carrier__c();
		obj_Carrier.Name = 'Test';
		obj_Carrier.Termination_Effective_Date__c = 'On the Date';
		insert obj_Carrier;

		Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
		obj_CarrierOrder.Carrier__c = obj_Carrier.Id;
		obj_CarrierOrder.Start_Date__c = System.today() - 50;
		obj_CarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		obj_CarrierOrder.Implementation_Stage__c = 'Plans Confirmed';
		obj_CarrierOrder.Facilitator_2_Plan_Build__c = 'Y';
		obj_CarrierOrder.Resign_Required__c = 'No';
		obj_CarrierOrder.Contribution_per_the_ER__c = 'test';
		obj_CarrierOrder.Follow_Up_Notes__c = ' sample data';
		obj_CarrierOrder.Follow_Up_Date__c = Date.newInstance(2019, 10, 21);
		obj_CarrierOrder.Plan_Review_Completed_Date_Time__c = Datetime.now();
		obj_CarrierOrder.Enrollment_Review_Completed_Date_Time__c = Datetime.now();
		obj_CarrierOrder.OwnerId = UserInfo.getUserId();
		obj_CarrierOrder.Is_Multi_EIN__c = true;
		insert obj_CarrierOrder;

		Ticket__c t1 = new Ticket__c();
		t1.Carrier_Order__c = obj_CarrierOrder.id;
		t1.Account__c = acc1.Id;
		t1.Carrier__c = obj_Carrier.Id;
		t1.Description__c = 'Test';
		insert t1;

		ApexPages.Standardcontroller carrierOrderStd = new ApexPages.Standardcontroller(obj_CarrierOrder);
		ApexPages.currentPage().getParameters().put('strCarrierOrderId', obj_CarrierOrder.id);
		BTCOFacilitatorSideViewCtrl bt1 = new BTCOFacilitatorSideViewCtrl(carrierOrderStd);

		bt1.objCarrierOrder.Follow_Up_Date__c = Date.newInstance(2020, 10, 21);

		bt1.blnIsTaskCompleted = true;
		bt1.UpdateStatus();

		// Check that the Implementation Stage should be updated
		Carrier_Order__c updatedCarrierOrder = [SELECT Implementation_Stage__c, Follow_Up_Date__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
		System.assertEquals('Collecting Documents', updatedCarrierOrder.Implementation_Stage__c, 'The Implementation Stage should be updated correctly');

		bt1.objCarrierOrder.Implementation_Stage__c = 'Implementing Plans';
		bt1.saveForFacilitator2();

		bt1.objCarrierOrder.Implementation_Stage__c = 'Enrollment Review Entry in Progress';
		bt1.saveForFacilitator2();

		bt1.rejectCOByFacilitator2();
		// Check that the Implementation Stage should be updated
		System.assertEquals('Ready for Implementing Plans', bt1.objCarrierOrder.Implementation_Stage__c, 'Implementation Stage should be updated correctly');

		bt1.objCarrierOrder.Implementation_Stage__c = 'Ready for Implementing Plans';
		bt1.getCarrierOrderDetails();

		bt1.objCarrierOrder.Implementation_Stage__c = 'Ready for Document Collection';
		bt1.getCarrierOrderDetails();
	}

	static testMethod void testMethod3() {
		Carrier_Order__c obj_CarrierOrder2 = new Carrier_Order__c();

		ApexPages.Standardcontroller carrierOrderStd2 = new ApexPages.Standardcontroller(obj_CarrierOrder2);
		BTCOFacilitatorSideViewCtrl bt3 = new BTCOFacilitatorSideViewCtrl(carrierOrderStd2);

		bt3.UpdateStatus();
		// Check that the Implementation Stage should be updated
		System.assertEquals('Collecting Documents', bt3.objCarrierOrder.Implementation_Stage__c, 'The Implementation Stage should be updated correctly');

		bt3.rejectCOByFacilitator2();
		// Check that the Implementation Stage should be updated
		System.assertEquals('Ready for Implementing Plans', bt3.objCarrierOrder.Implementation_Stage__c, 'Implementation Stage should be updated correctly');
	}
}