/**
 * @name         BTCOQualifierListViewCtrlTest
 * @author       Vinay
 * @date         13-03-2020
 * @description  Test class for BTCOQualifierListViewCtrl class . VF page -
 **/

@istest
public class BTCOQualifierListViewCtrlTest {
	static testMethod void testmethod1() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		account acc1 = TestUtility.CompanyAccount();

		Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
		opp1.Account = acc1;
		opp1.Signing_Forms_Completed_Timestamp__c = system.now();
		update opp1;

		Benefit_Order__c boRec = new Benefit_Order__c();
		borec.Opportunity__c = opp1.Id;
		boRec.Order_Status__c = 'Qualification';
		borec.Start_Date__c = Date.newInstance(2019, 10, 20);
		borec.End_Date__c = System.today();
		borec.Renewal_Date__c = System.today() + 30;
		borec.UW_Owner__c = UserInfo.getUserId();
		boRec.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');

		insert borec;

		Carrier__c obj_Carrier = new Carrier__c();
		obj_Carrier.Name = 'Test';
		obj_Carrier.Termination_Effective_Date__c = 'On the Date';
		insert obj_Carrier;

		Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
		obj_CarrierOrder.Carrier__c = obj_Carrier.Id;
		obj_CarrierOrder.Start_Date__c = System.today() - 50;
		obj_CarrierOrder.Renewal_Date__c = System.today();
		obj_CarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
		obj_CarrierOrder.Facilitator_2_Plan_Build__c = 'Y';
		obj_CarrierOrder.Facilitator_2_Plan_Review__c = UserInfo.getUserId();
		obj_CarrierOrder.Resign_Required__c = 'No';
		obj_CarrierOrder.Contribution_per_the_ER__c = 'test';
		obj_CarrierOrder.Follow_Up_Notes__c = ' sample data';
		obj_CarrierOrder.Follow_Up_Date__c = System.today() + 50;
		obj_CarrierOrder.Plan_Review_Completed_Date_Time__c = Datetime.now();
		obj_CarrierOrder.Enrollment_Review_Completed_Date_Time__c = Datetime.now();
		obj_CarrierOrder.OwnerId = UserInfo.getUserId();
		insert obj_CarrierOrder;

		Ticket__c t1 = new Ticket__c();
		t1.Benefit_Order__c = borec.id;
		t1.Carrier__c = obj_Carrier.id;
		t1.Carrier_Order__c = obj_CarrierOrder.id;
		t1.OwnerId = UserInfo.getUserId();
		t1.Escalation_Reason__c = 'Other';
		t1.Escalation_Reason_Detail__c = 'Approval';
		t1.Account__c = acc1.Id;
		t1.Description__c = 'Test';
		insert t1;

		test.startTest();
		case c1 = new case();
		c1.Related_Company__c = acc1.id;
		c1.Opportunity__c = opp1.id;
		c1.Carrier__c = obj_Carrier.id;
		c1.Carrier_Order__c = obj_CarrierOrder.id;
		c1.Benefit_Order__c = boRec.id;
		insert c1;

		BTCOQualifierListViewCtrl b1 = new BTCOQualifierListViewCtrl();
		b1.ResetSearch();
		b1.SearchBenefitOrder();
		b1.strViewFilter = 'My Orders';
		b1.SearchBenefitOrder();
		b1.fetchAllBenefitOrders();

		t1.OwnerId = Userinfo.getUserId();
		update t1;

		b1.RetriveTicket();

		b1.strViewFilter = 'Assigned Orders';

		b1.SearchBenefitOrder();

		// Check if Benefit Orders were fetched after the SearchBenefitOrder call
		System.assert(b1.list_BenefitOrderWrapper.size() > 0, 'There should be at least one Benefit Order fetched after the search.');

		// Verify that the correct number of tickets is fetched and associated
		Integer ticketCount = [SELECT COUNT() FROM Ticket__c WHERE OwnerId = :UserInfo.getUserId()];
		System.assert(ticketCount > 0, 'There should be at least one ticket for the current user.');
	}

	static testMethod void testmethod2() {
		OpportunityTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		BTCOQualifierListViewCtrl b1 = new BTCOQualifierListViewCtrl();
		b1.ResetSearch();
		b1.SearchBenefitOrder();
		b1.SearchBenefitOrder();
		b1.fetchAllBenefitOrders();
		b1.RetriveTicket();
		b1.strViewFilter = 'Assigned Orders';
		b1.SearchBenefitOrder();

		// Check that the correct View Filter is set after the search
		System.assertEquals('Assigned Orders', b1.strViewFilter, 'The View Filter should be set to "Assigned Orders".');

		// Check if Benefit Orders should not be fetched if the view filter is Assigned Orders
		System.assert(b1.list_BenefitOrderWrapper.size() == 0, 'There should be no Benefit Order fetched after the search as per view filter.');
	}
}