/**
 * @author       Deepika Saini
 * @date         16th June 2022
 * @description  This class is used to test the CarrierOrderMoveToRPAExt class functionality.
 **/
@isTest
public with sharing class CarrierOrderMoveToRPACtrlTest {
	/**
	 * @author      Deepika Saini
	 * @description This method used to create test data.
	 * @param       NA
	 * @return      NA
	 */
	@TestSetup
	static void setUpData() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;
		CarrierTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		List<RPA_Submission_Automation_rules__mdt> list_SubmissionMetadata = TestUtility.getSubmissionMetadata(Utils.RPA_ONLY);
		Carrier__c objCarrier1 = new TestDataFactory.CarrierBuilder()
			.setName('Blue Shield of California')
			.setUniqueName('Blue Shield of California')
			.setCarrierId(list_SubmissionMetadata[0].Carrier_Id__c)
			.setState('CA')
			.build();
		objCarrier1.Id__c = list_SubmissionMetadata[0].HI_Carrier_Id__c.split(';').get(0);
		insert objCarrier1;

		Account objAccountCompany = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Company Account 1').build();
		insert objAccountCompany;
		Opportunity objCompanyOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setAccountId(objAccountCompany.Id)
			.setName('Test Company')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.build();
		insert objCompanyOpportunity;

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID)
			.setName('Test Benefit Order')
			.setAccount(objAccountCompany.Id)
			.setOpp(objCompanyOpportunity.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenefitOrder;

		Carrier_Order__c objCO1 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test CO1')
			.setRecordTypeId(cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setImplementationStage('Ready for Qualification')
			.setOwnerID(UserInfo.getUserId())
			.setCarrier(objCarrier1.Id)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOrderType(list_SubmissionMetadata[0].Order_Type__c.split(';').get(0))
			.build();
		objCO1.Order_Assignment__c = list_SubmissionMetadata[0].Order_Type__c.split(';').get(0);
		objCO1.Group_Submission_Date__c = System.today().addMonths(1);
		objCO1.Member_Submission_Date__c = System.today().addMonths(1);
		objCO1.Submission_Deadline__c = System.today().addMonths(1);
		insert objCO1;

		Policy__c objPolicy = new Policy__c();
		objPolicy.Name = 'Test Policy';
		objPolicy.Opportunity__c = objCompanyOpportunity.Id;
		objPolicy.Carrier_Order__c = objCO1.Id;
		objPolicy.Carrier__c = objCarrier1.Id;
		insert objPolicy;

		Carrier_Order__c objCO2 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test CO2')
			.setRecordTypeId(cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setImplementationStage('Ready for Qualification')
			.setOwnerID(UserInfo.getUserId())
			.setCarrier(objCarrier1.Id)
			.build();
		objCO2.Order_Assignment__c = list_SubmissionMetadata[0].Order_Type__c.split(';').get(0);
		objCO2.Is_Multi_EIN__c = true;
		insert objCO2;
		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
		BenefitOrderHelper.skipTrigger = false;
		PolicyHelper.skipTrigger = false;
		CarrierTriggerHelper.skipTrigger = false;
		CarrierOrderTriggerHelper.skipTrigger = false;
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to test the Queue Assignmnet for Negative scenario.
	 * @param       NA
	 * @return      NA
	 */
	@isTest
	static void testQueueAssignmentNeg() {
		Carrier_Order__c objCO1 = [SELECT Id, Name, Implementation_Stage__c, OwnerId FROM Carrier_Order__c WHERE Name = 'Test CO1' LIMIT 1];
		Carrier_Order__c objCO2 = [SELECT Id, Name, Implementation_Stage__c, OwnerId FROM Carrier_Order__c WHERE Name = 'Test CO2' LIMIT 1];
		Test.startTest();
		String strMessage1 = CarrierOrderMoveToRPACtrl.assignAutomationQueue(objCO1.Id);
		String strMessage2 = CarrierOrderMoveToRPACtrl.assignAutomationQueue(objCO2.Id);
		Test.stopTest();
		System.assertEquals(strMessage1, CarrierOrderMoveToRPACtrl.STR_ERROR1_MESSAGE);
		System.assertEquals(strMessage2, CarrierOrderMoveToRPACtrl.STR_ERROR2_MESSAGE);
	}
    /**
	 * @author      Omar Benitez
	 * @description This method used to test the Queue Assignmnet for Negative scenario from LWC
	 * @param       NA
	 * @return      NA
	 */
	@isTest
	static void testQueueAssignmentNegFromLWC() {
		Carrier_Order__c objCO1 = [SELECT Id, Name, Implementation_Stage__c, OwnerId FROM Carrier_Order__c WHERE Name = 'Test CO1' LIMIT 1];
		Carrier_Order__c objCO2 = [SELECT Id, Name, Implementation_Stage__c, OwnerId FROM Carrier_Order__c WHERE Name = 'Test CO2' LIMIT 1];
		Test.startTest();
		String strMessage1 = CarrierOrderMoveToRPACtrl.assignAutomationQueueWrapper(objCO1.Id);
		String strMessage2 = CarrierOrderMoveToRPACtrl.assignAutomationQueueWrapper(objCO2.Id);
		Test.stopTest();
		System.assertEquals(strMessage1, CarrierOrderMoveToRPACtrl.STR_ERROR1_MESSAGE, 'it should return the error msg1');
		System.assertEquals(strMessage2, CarrierOrderMoveToRPACtrl.STR_ERROR2_MESSAGE, 'it should return the error msg2');
	}
	/**
	 * @author      Omar Benitez
	 * @description This method used to test the Queue Assignmnet from LWC with error handled
	 * @param       NA
	 * @return      NA
	 */
	@isTest
	static void testQueueAssignmentCatchFromLWC() {
        Test.startTest();
        try{
            String strMessage1 = CarrierOrderMoveToRPACtrl.assignAutomationQueueWrapper('NotAnId');
            System.assert(false);
        }catch(AuraHandledException e){
            System.assert(true);
        }
		Test.stopTest();
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to test the Queue Assignmnet for Positive scenario.
	 * @param       NA
	 * @return      NA
	 */
	@isTest
	static void testQueueAssignmentPos() {
		Carrier_Order__c objCO = [
			SELECT
				Id,
				Name,
				Implementation_Stage__c,
				OwnerId,
				Carrier__r.Carrier_Id__c,
				Order_Assignment__c,
				Carrier__r.Id__c,
				Submitted_Completed_Datetime__c,
				Group_Number__c,
				Benefit_Order__r.Transition_To_Fulfillment__r.Do_they_have_affiliates__c,
				(SELECT id FROM Policies__r),
				(SELECT Id, Contribution_Change__c, Carrier_Order__c, Benefits_selected_Carrier__r.Id__c, Lines_Of_Coverage__c FROM QA_Lines_Of_Coverage__r),
				Parent_Carrier_Order__c,
				Is_Multi_EIN__c,
				Submission_Deadline_Date__c
			FROM Carrier_Order__c
			WHERE Name = 'Test CO1'
			LIMIT 1
		];

		objCO.Implementation_Stage__c = 'Ready for Submission Prep';
		objCO.Group_Number__c = 'Test';
		CarrierOrderTriggerHelper.skipTrigger = true;
		update objCO;
		CarrierOrderTriggerHelper.skipTrigger = false;
		Test.startTest();
		String strMessage1 = CarrierOrderMoveToRPACtrl.assignAutomationQueue(objCO.Id);
		String strMessage2 = CarrierOrderMoveToRPACtrl.assignAutomationQueue(objCO.Id);
		CarrierOrderMoveToRPACtrl objRPACtrl = new CarrierOrderMoveToRPACtrl();
		objRPACtrl.discard(); 
		Test.stopTest();
		Carrier_Order__c objCO1 = [SELECT Id, OwnerId, HI_Carrier_Id__c, Order_Assignment__c FROM Carrier_Order__c WHERE Id = :objCO.Id];
		//System.assertEquals(objCO1.OwnerId, GlobalQueryHelper.getQueueIdByName(CarrierOrderMoveToRPACtrl.STR_AUTOMATION_QUEUE)); 
		//System.assertEquals(strMessage2, 'Carrier Order already routed to the Automation Queue.');
	}
}