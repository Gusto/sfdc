/**
 * @name         BTAdvocateViewCtrlTest
 * @author       Vinay
 * @date         03-13-2020
 * @description  Test class for BTAdvocateViewCtrl class
 * @revisions    Date ------------ Name ------------ Comments
 **/
@istest
public class BTAdvocateViewCtrlTest {
	static testMethod void testBTAdvocateViewCtrl() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Account acc1 = TestUtility.CompanyAccount();

		Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
		opp1.Account = acc1;
		update opp1;

		Benefit_Order__c boRec = new Benefit_Order__c();
		borec.Opportunity__c = opp1.Id;
		borec.Order_Status__c = 'Alignment Approved';
		borec.Application_Status__c = 'Plans Confirmed';
		boRec.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
		borec.Renewal_Date__c = System.today();
		boRec.Out_Of_Office_Notes__c = 'Test';
		insert borec;

		Carrier__c obj_Carrier = new Carrier__c();
		obj_Carrier.Name = 'Test';
		obj_Carrier.Termination_Effective_Date__c = 'On the Date';
		insert obj_Carrier;

		Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
		obj_CarrierOrder.Carrier__c = obj_Carrier.Id;
		obj_CarrierOrder.Start_Date__c = System.today() - 50;
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
		t1.Carrier_Order__c = obj_CarrierOrder.id;
		t1.Account__c = acc1.Id;
		t1.Description__c = 'Test';
		t1.Carrier__c = obj_Carrier.id;
		insert t1;

		Test.startTest();
		case c1 = new case();
		c1.Related_Company__c = acc1.id;
		c1.Opportunity__c = opp1.id;
		c1.Carrier__c = obj_Carrier.id;
		c1.Carrier_Order__c = obj_CarrierOrder.id;
		c1.Benefit_Order__c = boRec.id;
		c1.Status = 'Closed';
		insert c1;

		BTAdvocateViewCtrl b1 = new BTAdvocateViewCtrl();
		b1.CallOnBTMyCohort();
		b1.PopulateHippoStatus();
		b1.CallOnOOOView();
		b1.ResetSearch();
		b1.SaveOOONotes();
		b1.ReasignBOOnOOO();
		b1.CallOnBTOpenTask();
		b1.ShowCustomerCommunication();
		b1.ShowCustomerCommunicationMoreThan5Days();
		b1.ShowCarrierCommunication();
		b1.updateRequireStatus();
		b1.ShowTicketOwnedByMe();
		b1.ShowClosedTicket();
		System.assertEquals(b1.intNoOfTicketCreated, 1, 'No of created ticket is not equal to 1');
		Test.stopTest();
	}
}