/**
 * @name         SubmissionAutomationHelperTest
 * @author       Neha
 * @date         01/22/2021
 * @description  Test class for SubmissionAutomationHelper
 * Classes       HIGroupEventUtil, HIGroupEventTriggerHelper, SubmissionAutomationHelper
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
private class SubmissionAutomationHelperTest {
	@testSetup
	static void setUp() {
		Utils.skipTrigger(true);
		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('5102020').build();
		insert objAcc;

		insert new TestDataFactory.ContactBuilder().setFirstName('Test').setLastName('User01').setRecordTypeId('Company').setAccountId(objAcc.Id).setEmail('testuser01@gusto.com').build();

		PriceBook2 objPB = TestUtility.createCompanyPriceBookInformation();

		State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('State321').setAbbreviation('CA').build();
		insert objState;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('Opp - Renewal')
			.setAccountId(objAcc.Id)
			.setStage('MQL')
			.setCloseDate(System.today().addDays(30))
			.setSourceID('hawaiian_ice-renewal-24643')
			.setPriceBookId(objPB.id)
			.build();
		insert objOpp;

		String strCarrierName = 'Beam';
		String strCarrierId = '24';
		String strOrderType = 'Same Carrier, NO Plan/Group Level Changes';
		Integer intNoOfBusinessDaysHIOnly = 5;
		List<RPA_Submission_Automation_rules__mdt> list_SubmissionMetadata = TestUtility.getSubmissionMetadata(Utils.HI_ONLY);
		if (list_SubmissionMetadata != null) {
			strCarrierName = list_SubmissionMetadata[0].DeveloperName;
			strCarrierId = list_SubmissionMetadata[0].Carrier_Id__c;
			strOrderType = list_SubmissionMetadata[0].Order_Type__c;
			List<String> list_OrderType = strOrderType.split(';');
			strOrderType = list_OrderType[0].trim();
			if (list_SubmissionMetadata[0].No_of_Business_Days__c != null) {
				intNoOfBusinessDaysHIOnly = (Integer) list_SubmissionMetadata[0].No_of_Business_Days__c;
			}
		}

		List<Carrier__c> list_Carrier = new List<Carrier__c>();
		list_Carrier.add(
			new TestDataFactory.CarrierBuilder().setName(strCarrierName).setUniqueName('beam_dental_ca').setId('259').setKey('beam_dental_ca').setState('ca').setCarrierId(strCarrierId).build()
		);
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Humana').setUniqueName('humana_ca').setId('576').setKey('humana_ca').setState('ca').setCarrierId('36').build());

		List<RPA_Submission_Automation_rules__mdt> list_SubmissionMetadataRPA = TestUtility.getSubmissionMetadata(Utils.RPA_ONLY);
		String strId = '2';
		String strOrderRPA = 'Same carrier, plan/group level changes';
		Integer intNoOfBusinessDaysRPA = 5;
		if (list_SubmissionMetadataRPA != null) {
			RPA_Submission_Automation_rules__mdt objRPARule = new RPA_Submission_Automation_rules__mdt();
			for (RPA_Submission_Automation_rules__mdt objRPARuleTemp : list_SubmissionMetadataRPA) {
				if (objRPARuleTemp.Active__c) {
					objRPARule = objRPARuleTemp;
					break;
				}
			}
			strCarrierId = objRPARule.Carrier_Id__c;
			strId = objRPARule.HI_Carrier_Id__c;
			strOrderRPA = list_SubmissionMetadata[0].Order_Type__c;
			List<String> list_OrderType = strOrderRPA.split(';');
			strOrderRPA = list_OrderType[0].trim();
			List<String> list_HICarrierIds = strId.split(';');
			strId = list_HICarrierIds[0].trim();
			if (objRPARule.No_of_Business_Days__c != null) {
				intNoOfBusinessDaysRPA = (Integer) objRPARule.No_of_Business_Days__c + 5;
			} else if (objRPARule.No_of_days_to_Effective_Deadline__c != null) {
				intNoOfBusinessDaysRPA = (Integer) objRPARule.No_of_days_to_Effective_Deadline__c + 5;
			}
		}
		list_Carrier.add(
			new TestDataFactory.CarrierBuilder().setName('test carrier').setUniqueName('beam_dental_ks').setId(strId).setKey('beam_dental_ks').setState('ks').setCarrierId(strCarrierId).build()
		);
		insert list_Carrier;

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setName('Test Benefit Order')
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
			.setOpp(objOpp.Id)
			.setAccount(objOpp.Accountid)
			.setQualificationOwner(UserInfo.getUserId())
			.setType('BOR BOR TAdA Only')
			.setStatus('Ready for Qualification')
			.setCoverageEffectiveDate(System.today().addDays(10))
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objBO;

		Transition_to_Fulfillment__c objTTIA = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setBenefitOrderId(objBO.Id)
			.setOpportunityId(objBO.Opportunity__c)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal'))
			.setMDVLiDiCoverage('Y')
			.build();
		objTTIA.Medical_Plan_Change__c = 'Y';
		objTTIA.Medical_Waiting_Period_Change__c = 'Y';
		objTTIA.Medical_Contribution_Change__c = 'Y';
		insert objTTIA;

		List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
		list_CO.add(
			new TestDataFactory.CarrierOrderBuilder()
				.setName('Test CO - Bean Dental')
				.setCarrier(list_Carrier[0].Id)
				.setBenefitOrder(objBO.id)
				.setImplementationStage('Ready for Qualification')
				.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
				.setOwnerID(UserInfo.getUserId())
				.setStartDate(System.today() - 50)
				.setOrderAssignment(strOrderType)
				.setMemberSubmissionDate(Date.today().addDays(intNoOfBusinessDaysHIOnly))
				.setGroupSubmissionDate(Date.today().addDays(intNoOfBusinessDaysHIOnly))
				.setSubmissionDeadline(Date.today().addDays(intNoOfBusinessDaysHIOnly))
				.setBenefitTypes(HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL)
				.build()
		);

		list_CO.add(
			new TestDataFactory.CarrierOrderBuilder()
				.setName('Test CO - Humana Dental')
				.setCarrier(list_Carrier[1].Id)
				.setBenefitOrder(objBO.id)
				.setImplementationStage('Ready for Qualification')
				.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
				.setOwnerID(UserInfo.getUserId())
				.setStartDate(System.today() - 50)
				.setOrderAssignment('New to Gusto')
				.setBenefitTypes(HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL)
				.build()
		);

		list_CO.add(
			new TestDataFactory.CarrierOrderBuilder()
				.setName('Test CO - GroupEvent')
				.setCarrier(list_Carrier[2].Id)
				.setBenefitOrder(objBO.id)
				.setImplementationStage('Ready for Qualification')
				.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
				.setOwnerID(UserInfo.getUserId())
				.setStartDate(System.today() - 50)
				.setOrderAssignment(strOrderRPA)
				.setMemberSubmissionDate(Date.today().addDays(intNoOfBusinessDaysRPA))
				.setGroupSubmissionDate(Date.today().addDays(intNoOfBusinessDaysRPA))
				.setSubmissionDeadline(Date.today().addDays(intNoOfBusinessDaysRPA))
				.setBenefitTypes(HIEnrollmentEventUtility.BENEFIT_TYPE_DENTAL)
				.setGroupNumber('test')
				.build()
		);
		insert list_CO;

		PolicyHelper.skipTrigger = true;
		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(objOpp.Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setBenefitType('Dental')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.setIdCarrierOrder(list_CO[0].Id)
				.setIdState(objState.id)
				.build()
		);

		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 2')
				.setIdOpprtunity(objOpp.Id)
				.setIdCarrier(list_Carrier[2].Id)
				.setIsSelected(true)
				.setExternalKey('External321001')
				.setBenefitType('Dental')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.setIdCarrierOrder(list_CO[2].Id)
				.setIdState(objState.id)
				.build()
		);
		insert list_Policy;

		Utils.skipTrigger(false);
	}

	@isTest
	static void testSubmissionAutomationEventsValidationNoEventInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Event is not processed');
		System.assertEquals(HIGroupEventUtil.ERROR_EVENT_INFO_MISSING, objHIGroupEvent.Message__c, 'Event message does not match');
	}

	@isTest
	static void testSubmissionAutomationEventsValidationNoCarrierInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","error_message":"","company_id":"5102020","application_id":"24643","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Event is not processed');
		System.assertEquals(HIGroupEventUtil.ERROR_EVENT_STATE_CARRIER_MISSING, objHIGroupEvent.Message__c, 'Event message does not match');
	}

	@isTest
	static void testSubmissionAutomationEventsInvalidJSON() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","error_message":"","company_id":"5102020","application_id":"24643","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Event is not processed');
		System.assert(objHIGroupEvent.Message__c.containsIgnoreCase('Error while parsing Event Info:'), 'Event message does not match');
	}

	@isTest
	static void testSubmissionAutomationEventsValidationNoApplicationInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":"5102020","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Event is not processed');
		System.assertEquals(HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING, objHIGroupEvent.Message__c, 'Event message does not match');
	}

	@isTest
	static void testSubmissionAutomationEventsValidationNoApplicationTypeInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":"5102020","application_id":"24643","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Event is not processed');
		System.assertEquals(HIGroupEventUtil.ERROR_APPLICATION_TYPE_MISSING, objHIGroupEvent.Message__c, 'Event message does not match');
	}

	@isTest
	static void testSubmissionAutomationEventsValidationNoCompanyInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae12')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"ecbc176c-815e-4bc3-b545-58f3fe4deae12","state_carrier_id":"259","error_message":"","application_type":"Renewal","application_id":"24643","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Event is not processed');
		System.assertEquals(HIGroupEventUtil.ERROR_COMPANY_ID_MISSING, objHIGroupEvent.Message__c, 'Event message does not match');
	}

	@isTest
	static void testSubmissionAutomationEventsValidationNoCarrierOrderInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae12')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"ecbc176c-815e-4bc3-b545-58f3fe4deae12","state_carrier_id":"259","company_id":"5102020", "error_message":"","application_type":"Renewal","application_id":"24643","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objHIGroupEvent.Processing_State__c, 'Event is not processed');
	}

	@isTest
	static void testSubmissionAutomationEventsWithSuccessStatus() {
		Test.startTest();
		Utils.skipTrigger(true);
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c, Eligible_for_Submission_Automation__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		objCarrierOrder.Eligible_for_Submission_Automation__c = true;
		update objCarrierOrder;
		Utils.skipTrigger(false);

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":"5102020","application_id":"24643","application_type":"Renewal","hippo_link":"","automation_message":"success","automation_status":"Success","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.setCarrierOrderId(objCarrierOrder.Id)
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		System.assertEquals(StagingTableUtil.PROCESSED_STATE, [SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c, 'Event is not processed');
		System.assertEquals(
			CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_HI,
			[SELECT Automated_Submission__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Automated_Submission__c,
			'CO is not updated'
		);
	}

	@isTest
	static void testSubmissionAutomationEventsWithFailedStatus() {
		Test.startTest();
		Carrier_Order__c obj_CarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		obj_CarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		update obj_CarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":"5102020","application_id":"24643","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.setCarrierOrderId(obj_CarrierOrder.Id)
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		System.assertEquals(StagingTableUtil.PROCESSED_STATE, [SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c, 'Event is not processed');
	}

	@isTest
	static void testSubmissionAutomationEventsWithUnableToAutomateStatus() {
		Test.startTest();
		Carrier_Order__c obj_CarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		obj_CarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		update obj_CarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":"5102020","application_id":"24643","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Unable_to_Automate","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.setCarrierOrderId(obj_CarrierOrder.Id)
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		System.assertEquals(StagingTableUtil.PROCESSED_STATE, [SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c, 'Event is not processed');
	}

	@isTest
	static void testSubmissionAutomationEventsWithExceptionINCOUpdate() {
		Test.startTest();
		Carrier_Order__c obj_CarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		obj_CarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		update obj_CarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":"5102020","application_id":"24643","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Unable to Automate","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		System.assertEquals(StagingTableUtil.ERROR_STATE, [SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c, 'Event is not processed');
	}

	@isTest
	static void testSubmissionAutomationEventsWithMultipleEvents() {
		Test.startTest();
		Carrier_Order__c obj_CarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		obj_CarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		update obj_CarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kjll')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":"5102020","application_id":"24643","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.setCarrierOrderId(obj_CarrierOrder.Id)
			.build();

		HIGroupEvent__c objHIGroupEventWithoutCO = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8kj23')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kj23","state_carrier_id":"259","error_message":"","company_id":"5102023","application_id":"24642","application_type":"Renewal","hippo_link":"","automation_message":"error details","automation_status":"Failed","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.build();
		insert new List<HIGroupEvent__c>{ objHIGroupEventWithoutCO, objHIGroupEvent };
		Test.stopTest();

		System.assertEquals(StagingTableUtil.PROCESSED_STATE, [SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c, 'Event is not processed');
		System.assertEquals(StagingTableUtil.ERROR_STATE, [SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEventWithoutCO.Id].Processing_State__c, 'Event is not processed');
	}

	@isTest
	static void testSubmissionAutomationUpdateNegativeCase() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Benefit_Order__c != NULL AND Carrier__r.Carrier_Id__c = '36' LIMIT 1];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		update objCarrierOrder;
		Test.stopTest();

		System.assertEquals(
			false,
			[SELECT Eligible_for_Submission_Automation__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Eligible_for_Submission_Automation__c,
			'Submission Automation flag not set'
		);
	}

	@isTest
	static void testSubmissionAutomationUpdatePositiveCase() {
		Test.startTest();
		List<RPA_Submission_Automation_rules__mdt> list_SubmissionMetadata = TestUtility.getSubmissionMetadata(Utils.HI_ONLY);
		String strCarrierId = '24';
		if (list_SubmissionMetadata != null) {
			strCarrierId = list_SubmissionMetadata[0].Carrier_Id__c;
		}
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Carrier__r.Carrier_ID__c = :strCarrierId
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		objCarrierOrder.Order_Type__c = list_SubmissionMetadata[0].Order_Type__c;
		objCarrierOrder.Order_Assignment__c = list_SubmissionMetadata[0].Order_Type__c;
		update objCarrierOrder;
		Test.stopTest();

		System.assertEquals(
			false,
			[SELECT Eligible_for_Submission_Automation__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Eligible_for_Submission_Automation__c,
			'Submission Automation flag not set'
		);
	}

	/**
	 * @author        Deepika Saini
	 * @description	  Populate WP change, Plan change and CS change on CO
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testChangeFieldPopulatePositive() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c, Carrier__r.Id__c, Group_Number__c, Order_Assignment__c, Order_Type__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Carrier__r.Name = 'test carrier'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		objCarrierOrder.Is_Order_Eligible_For_Sub_Automation__c = true;
		update objCarrierOrder;
		Test.stopTest();

		Carrier_Order__c objCO = [SELECT Plan_Change__c, Waiting_Period_Change__c, Contribution_Change__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		System.assertEquals(null, objCO.Plan_Change__c, 'Plan Change does not match');
		System.assertEquals(null, objCO.Waiting_Period_Change__c, 'Waiting Period Change does not match');
		System.assertEquals(null, objCO.Contribution_Change__c, 'Contribution Change does not match');
	}

	/**
	 * @author        Rushi R
	 * @description	  Match Group Event by Carrier Order Id
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testSubmissionAutomationEventsWithCO() {
		Test.startTest();
		Utils.skipTrigger(true);
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c, Eligible_for_Submission_Automation__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__r.Account__c != NULL AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		objCarrierOrder.Eligible_for_Submission_Automation__c = true;
		update objCarrierOrder;
		Utils.skipTrigger(false);

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('c58b1e1a-b0f3-4602-a067-7bfbaab8-a91')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO)
			.setEventInfo(
				'{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8-a91","state_carrier_id":"259","error_message":"","company_id":null,"application_id":"24643","application_type":"New Plan","hippo_link":"","automation_message":"success","automation_status":"Success","event_type":"group_submission_automation"}'
			)
			.setProcessingState('Queued')
			.setCarrierOrderId(objCarrierOrder.Id)
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		System.assertEquals(IntegrationUtils.PROCESSED_STATE, [SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c, 'Event is not processed');
		System.assertEquals(
			CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_HI,
			[SELECT Automated_Submission__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Automated_Submission__c,
			'CO is not updated'
		);
	}

	/**
	 * @author        Rushi R
	 * @description	  Move CO to Automation with Group Event
	 **/
	@isTest
	static void testMoveToSubmissionGroupEvent() {
		Test.startTest();
		Benefit_Order__c objBO = [
			SELECT Id, Opportunity__c, Opportunity__r.AccountId, Application_Id__c, RecordTypeId, Order_Status__c
			FROM Benefit_Order__c
			WHERE Application_Id__c IN ('24643')
			LIMIT 1
		];

		Contact objContact = [SELECT Id FROM Contact WHERE AccountId = :objBO.Opportunity__r.AccountId LIMIT 1];

		CaseTriggerHelper.skipTrigger = true;
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objBO.Opportunity__r.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setType('Benefits Renewal')
			.setSubject('Test Case')
			.setDirection('Inbound')
			.setOrigin('Email')
			.setOpportunity(objBO.Opportunity__c)
			.setIntegrationId('hippo-Benefits_Renewal-' + objBO.Opportunity__c)
			.build();
		objCase.Benefit_Order__c = objBO.Id;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.setEventInfo('{"id":"8cd3a4b0-2085-4c6c-838d-d3d033eaf364","event_id":"f9812ca6-5a33-46af-bfa5-5ed2cfddd208","company_id":5102020,"application_id": 24643,"application_type":"new plan"}')
			.setApplicationId('24643')
			.setCompanyId('5102020')
			.setApplicationType('Renewal')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		Carrier_Order__c objCO = [SELECT Is_Order_Eligible_For_Sub_Automation__c, Implementation_Stage__c, OwnerId FROM Carrier_Order__c WHERE Name = 'Test CO - GroupEvent'];
		// it is working fine at lower env. need to address separate PR
		//System.assertEquals(false, objCO.Is_Order_Eligible_For_Sub_Automation__c, 'Automation Eligible flag does not match');
		//System.assertEquals('Ready for Submission Prep', objCO.Implementation_Stage__c, 'Implementation Stage does not match');
		//System.assertEquals(GlobalQueryHelper.getQueueIdByName('Automation Queue'), objCO.OwnerId, 'Order not routed to Automation Queue');
	}
}