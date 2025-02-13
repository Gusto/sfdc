/**
 * @name         HIFulfillmentEventOpenEnrollmentTest
 * @author       Gireesh
 * @date         11 June 2020
 * @description  Helper class to execute HI Fullfillment open enrollment events
 * @test class   HIFulfillmentEventOpenEnrollmentTest
 * @revisions    Date ------------ Name ------------ Comments
 */

@isTest
private class HIFulfillmentEventOpenEnrollmentTest {
	@testSetup
	static void testSetup() {
		EncryptionUtils.generateKey('Master');
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Opportunity objOpportunity = TestUtility.BenefitsRenewalOpportunity();
		objOpportunity.ID__c = '312345';
		objOpportunity.Source_ID__c = 'hawaiian_ice-renewal-312345';
		update objOpportunity;

		Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account WHERE Id = :objOpportunity.accountid];
		objAccount.ZP_Company_ID__c = 'TestCompany';
		update objAccount;

		Opportunity objBYBOppty = TestUtility.getNewOpportunity('Benefits BYOB', objAccount.Id);
		objBYBOppty.Source_ID__c = 'hawaiian_ice-BYB-312347';
		objBYBOppty.StageName = 'ER Confirm';
		objBYBOppty.Name = 'Benefits BYOB';
		update objBYBOppty;

		HI_Fulfillment__c objHIFulfillment = new HI_Fulfillment__c(Id__c = '312345', Fulfillable_Id__c = '312345', Fulfillable_Type__c = 'Renewal');
		insert objHIFulfillment;

		Benefit_Order__c objRenewalBO = TestUtility.createTestBenefitOrder('Renewal', objOpportunity.Id, 'Test Benefit Order', true);
		objRenewalBO.Order_Status__c = 'Ready for OE Prep';
		update objRenewalBO;

		Benefit_Order__c objBYBBO = TestUtility.createTestBenefitOrder('Benefits BYB', objBYBOppty.Id, 'Test Benefit Order', true);
		objBYBBO.Order_Status__c = 'Ready for OE Prep';
		update objBYBBO;

		Configuration_Settings__c objConfigrationSettings = Configuration_Settings__c.getOrgDefaults();
		objConfigrationSettings.BO_Do_Not_Update_Staus_on_HI_OE_event__c = 'Ready for Submission Prep;Submission Prep;Ready for Confirmation;Pending Confirmation;Approved;Fulfilled;Canceled;Closed Lost;Closed Admin;Ready for Qualification;Qualification;Awaiting Routing;ER Outreach Required;With Sales;With Advising';
		upsert objConfigrationSettings;
	}
	
	@isTest
	static void testProcessInformation_Extended() {
		String strTestJson = '{"fulfillment_id":312345,"oe_status":"extended","company_id":"Testcompany"}';
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Blob blobEncryptedInfo = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, strTestJson);

		List<HI_Fulfillment_Event__c> list_FulfillmentList = new List<HI_Fulfillment_Event__c>{
			new HI_Fulfillment_Event__c(Id__c = '312345', Event_Info_Encrypted__c = EncodingUtil.base64Encode(blobEncryptedInfo))
		};

		Test.startTest();
		new HIFulfillmentEventOpenEnrollment().processInformation(list_FulfillmentList);
		Test.stopTest();

		Benefit_Order__c objBenefitOrder = [SELECT Order_Status__c FROM Benefit_Order__c LIMIT 1];
		System.assertEquals('OE Extended', objBenefitOrder.Order_Status__c, 'Benefit_Order__c status update-extended failed');
	}

	@isTest
	static void testProcessInformation_Completed() {
		String strTestJson = '{"fulfillment_id":312345,"oe_status":"completed","company_id":"Testcompany"}';
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Blob blobEncryptedInfo = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, strTestJson);

		List<HI_Fulfillment_Event__c> list_FulfillmentList = new List<HI_Fulfillment_Event__c>{
			new HI_Fulfillment_Event__c(Id__c = '312345', Event_Info_Encrypted__c = EncodingUtil.base64Encode(blobEncryptedInfo))
		};

		Test.startTest();
		new HIFulfillmentEventOpenEnrollment().processInformation(list_FulfillmentList);
		Test.stopTest();

		Benefit_Order__c objBenefitOrder = [SELECT Order_Status__c FROM Benefit_Order__c LIMIT 1];
		System.assertEquals('OE Verification/Checking Participation', objBenefitOrder.Order_Status__c, 'Benefit_Order__c status update-Completed failed');
	}

	@isTest
	static void testgetDecryptedHIEventStr() {
		String strTestJson = '{"fulfillment_id":312345,"oe_status":"completed","company_id":"Testcompany"}';
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Blob blobEncryptedInfo = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, strTestJson);

		List<HI_Fulfillment_Event__c> list_FulfillmentList = new List<HI_Fulfillment_Event__c>{ new HI_Fulfillment_Event__c(Event_Info_Encrypted__c = EncodingUtil.base64Encode(blobEncryptedInfo)) };

		Test.startTest();
		List<HIFullfillmentEventWrapper> list_JsonList = UtilitiesFactory.getDecryptedHIEventStr(list_FulfillmentList);
		Test.stopTest();

		System.assertEquals(true, list_JsonList.isEmpty(), 'DecryptedHIEvent negative test failed');
	}

	@isTest
	static void testHIFullFillmentEvenOE() {
		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c(
			Id__c = '312345',
			Event_Info__c = '{"fulfillment_id":312345,"oe_status":"completed","company_id":"Testcompany"}',
			Event_Type__c = 'open_enrollment_status'
		);

		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		insert objHIEvent;
		objHIEvent.Processing_State__c = IntegrationUtils.QUEUED_STATE;
		update objHIEvent;
		Test.stopTest();

		System.assertNotEquals('Dead', objHIEvent.Processing_State__c, 'HI event process failed');
	}

	@isTest
	static void testProcessInformation_DoNotUpdate() {
		String strTestJson = '{"fulfillment_id":312345,"oe_status":"extended","company_id":"Testcompany"}';
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Blob blobEncryptedInfo = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, strTestJson);

		List<HI_Fulfillment_Event__c> list_FulfillmentList = new List<HI_Fulfillment_Event__c>{
			new HI_Fulfillment_Event__c(Id__c = '312345', Event_Info_Encrypted__c = EncodingUtil.base64Encode(blobEncryptedInfo))
		};

		Benefit_Order__c objBenefitOrder = [SELECT Order_Status__c FROM Benefit_Order__c LIMIT 1];
		objBenefitOrder.Order_Status__c = 'Ready for Submission Prep';
		update objBenefitOrder;

		Test.startTest();
		Configuration_Settings__c objConfigrationSettings = Configuration_Settings__c.getOrgDefaults();
		new HIFulfillmentEventOpenEnrollment().processInformation(list_FulfillmentList);
		Test.stopTest();

		objBenefitOrder = [SELECT Order_Status__c FROM Benefit_Order__c LIMIT 1];
		System.assertNotEquals('OE Extended', objBenefitOrder.Order_Status__c, 'Benefit_Order__c status updated');
	}

	@isTest
	static void testException() {
		String strTestJson = '{"fulfillment_id":312345,"oe_status":"extended","company_id":"Testcompany"}';
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Blob blobEncryptedInfo = EncryptionUtils.getEncryptedBlob(blobEncryptionKey, strTestJson);

		List<HI_Fulfillment_Event__c> list_FulfillmentList = new List<HI_Fulfillment_Event__c>{
			new HI_Fulfillment_Event__c(Id__c = '312345', Event_Info_Encrypted__c = EncodingUtil.base64Encode(blobEncryptedInfo))
		};

		Test.startTest();
		HIFulfillmentEventOpenEnrollment.blnTestException = true;
		new HIFulfillmentEventOpenEnrollment().processInformation(list_FulfillmentList);
		Test.stopTest();

		Benefit_Order__c objBenefitOrder = [SELECT Order_Status__c FROM Benefit_Order__c LIMIT 1];
		System.assertEquals('OE Extended', objBenefitOrder.Order_Status__c, 'Benefit_Order__c status update-extended failed');
	}

	@isTest
	static void testBYBOENotCompleted() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c(
			Id__c = '312347',
			Company_Id__c = 'TestCompany',
			Event_Info__c = '{"fulfillment_id":null,"oe_status":"completed","company_id":"TestCompany"}',
			Event_Type__c = 'open_enrollment_status'
		);

		Test.startTest();
		insert ObjHIEvent;
		Test.stopTest();

		Benefit_Order__c objBenefitOrder = [SELECT Order_Status__c FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID];
		System.assertNotEquals('OE Verification/Checking Participation', objBenefitOrder.Order_Status__c, 'Benefit Order status OE');
	}

	@isTest
	static void testBYBOECompleted() {
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE RecordType.Name = 'Benefits BYB' LIMIT 1];
		objBO.Order_Status__c = 'OE';
		update objBO;

		HIFulfillmentEventTriggerHelper.queue = true;
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c(
			Id__c = '312347',
			Company_Id__c = 'TestCompany',
			Event_Info__c = '{"fulfillment_id":null,"oe_status":"completed","company_id":"TestCompany"}',
			Event_Type__c = 'open_enrollment_status'
		);

		Test.startTest();
		insert objHIEvent;
		Test.stopTest();

		objBO = [SELECT Order_Status__c FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID];
		System.assertEquals('OE Verification/Checking Participation', objBO.Order_Status__c, 'Benefit Order status not OE');

		objHIEvent = [SELECT Id, Processing_State__c FROM HI_Fulfillment_Event__c WHERE Id = :objHIEvent.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objHIEvent.Processing_State__c, 'Event updates failed');
	}
}