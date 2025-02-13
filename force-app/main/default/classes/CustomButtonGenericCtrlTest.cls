/**
 * Description 	: 	This class contains unit tests for validating the behavior of CustomButtonGenericCtrl
 * Created By	:	Neha Dabas
 * Created Date	: 	1 August 2019
 */
@isTest
private class CustomButtonGenericCtrlTest {
	static Id setupTestData() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		Opportunity objOpportunities = TestUtility.BenefitsNewPlanOpportunity();

		Benefit_Order__c objBenefitOrder = TestUtility.createTestBenefitOrder('New Plan', objOpportunities.Id, 'Test Benefit Order', true);

		objBenefitOrder.Order_Status__c = 'OE';
		objBenefitOrder.ownerID = UserInfo.getUserId();
		objBenefitOrder.Coverage_Effective_Date__c = System.today();
		objBenefitOrder.Open_Enrollment_Start_Date__c = System.today();
		objBenefitOrder.Open_Enrollment_End_Date__c = System.today();
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier__c objCarrier = TestUtility.Carrier();

		Carrier_Order__c objCarrierOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder.Name = 'TEST CARRIER ORDER';
		objCarrierOrder.Carrier__c = objCarrier.Id;
		objCarrierOrder.Benefit_Order__c = objBenefitOrder.Id;
		objCarrierOrder.Order_Type__c = 'New to Gusto';
		objCarrierOrder.OwnerId = UserInfo.getUserId();
		insert objCarrierOrder;

		Ticket__c objTicket = new Ticket__c(
			Carrier_Order__c = objCarrierOrder.Id,
			Escalation_Reason__c = 'Pending Items',
			Escalation_Reason_Detail__c = 'Pending Item - ER Contact Required',
			Summary__c = 'Test Ticket',
			Description__c = 'Ticket Description',
			Opportunity__c = objOpportunities.Id,
			Benefit_Order__c = objBenefitOrder.Id,
			Team__c = 'Onboarding',
			Sub_Team__c = 'Implementation Advocate',
			RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans')
		);

		insert objTicket;

		return objTicket.Id;
	}

	//test ER button Action for valid ticket record
	@isTest
	static void eRButtonClickTestPositive() {
		Id IdTkt = setupTestData();
		// TO DO: implement unit test
		Test.setCurrentPageReference(new PageReference('Page.CustomButtonGenericPage'));
		System.currentPageReference().getParameters().put('source', 'EROutreach');
		System.currentPageReference().getParameters().put('entityName', 'Ticket');
		System.currentPageReference().getParameters().put('entityId', IdTkt);
		System.currentPageReference().getParameters().put('returnURL', '/' + IdTkt);

		test.startTest();
		CustomButtonGenericCtrl ctrl = new CustomButtonGenericCtrl();

		ctrl.buttonAction();
		ctrl.initiateEROutreach();
		test.stopTest();

		system.assert([SELECT COUNT() FROM Ticket__c WHERE Id = :IdTkt AND ER_Outreach_Count__c = 1] == 1, 'Record Count should be 1.');
	}

	//test ER button Action for invalid ticket record
	@isTest
	static void eRButtonClickTestNegative() {
		// TO DO: implement unit test
		Test.setCurrentPageReference(new PageReference('Page.CustomButtonGenericPage'));
		System.currentPageReference().getParameters().put('source', 'EROutreach');
		System.currentPageReference().getParameters().put('entityName', 'Ticket');
		System.currentPageReference().getParameters().put('entityId', 'a8a82gdte536378dhd');
		System.currentPageReference().getParameters().put('returnURL', '/a8a82gdte536378dhd');

		test.startTest();
		CustomButtonGenericCtrl ctrl = new CustomButtonGenericCtrl();

		ctrl.buttonAction();
		test.stopTest();

		system.assert([SELECT COUNT() FROM Ticket__c WHERE ER_Outreach_Count__c = 1] == 0, 'Record Count should be 0.');
	}

	//test Ready for PI Submission button Action for valid ticket record
	@isTest
	static void pIButtonClickTestPositive() {
		Id IdTkt = setupTestData();
		// TO DO: implement unit test
		Test.setCurrentPageReference(new PageReference('Page.CustomButtonGenericPage'));
		System.currentPageReference().getParameters().put('source', 'PISubmission');
		System.currentPageReference().getParameters().put('entityName', 'Ticket');
		System.currentPageReference().getParameters().put('entityId', IdTkt);
		System.currentPageReference().getParameters().put('returnURL', '/' + IdTkt);

		test.startTest();
		CustomButtonGenericCtrl ctrl = new CustomButtonGenericCtrl();

		ctrl.buttonAction();
		ctrl.readyForPISubmissionAction();
		test.stopTest();
		system.assert([SELECT COUNT() FROM Ticket__c WHERE Id = :IdTkt AND PI_Submission_Date__c != NULL] == 1, 'Record Count should be 1.');
	}

	//test Ready for PI Submission button Action for invalid ticket record
	@isTest
	static void pIButtonClickTestNegative() {
		Id IdTkt = setupTestData();
		// TO DO: implement unit test
		Test.setCurrentPageReference(new PageReference('Page.CustomButtonGenericPage'));
		System.currentPageReference().getParameters().put('source', 'PISubmission');
		System.currentPageReference().getParameters().put('entityName', 'Ticket');
		System.currentPageReference().getParameters().put('entityId', 'a8a82gdte536378dhd');
		System.currentPageReference().getParameters().put('returnURL', 'a8a82gdte536378dhd');

		test.startTest();
		CustomButtonGenericCtrl ctrl = new CustomButtonGenericCtrl();

		ctrl.buttonAction();
		ctrl.readyForPISubmissionAction();
		test.stopTest();
		system.assert([SELECT COUNT() FROM Ticket__c WHERE PI_Submission_Date__c != NULL] == 0, 'Record Count should be 0.');
	}
}