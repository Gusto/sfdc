/**
 * @name         HIGroupEventTerminationCasesTest
 * @author       Rushi R
 * @date         31 May 2023
 * @description  Test class for HIGroupEventTerminationCases class.
 **/
@isTest
private class HIGroupEventTerminationCasesTest {
	/**
	 * @Author      : Rushi R
	 * @Description : Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		BenefitOrderHelperTests.skipTrigger(true);

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		State__c objState = new TestDataFactory.StateBuilder().setName('California').setAbbreviation('CA').build();
		insert objState;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Gusto Test').setZPCompanyId('510202021721').build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder().setRecordTypeId('Company').setAccountId(objAccount.Id)
			.setFirstName('First Name').setLastName('Last Name').setEmail('first.last@test.net').setZPUserId('187654321100').build();
		insert objContact;

		List<Carrier__c> list_Carriers = new List<Carrier__c>{
			new TestDataFactory.CarrierBuilder().setName('Test-CA').setKey('test_ca').setId('234').setState('CA').build(),
			new TestDataFactory.CarrierBuilder().setName('Test-CO').setKey('test_co').setId('456').setState('CO').build()
		};
		insert list_Carriers;

		PriceBook2 objPB = TestUtility.createCompanyPriceBookInformation();

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder().setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('Opp - Renewal').setAccountId(objAccount.Id).setCloseDate(System.today().addDays(30))
			.setSourceID('hawaiian_ice-renewal-24643').setPriceBookId(objPB.id).setStage('Raw').build();
		insert objOppty;

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder().setName('Test BO').setOpp(objOppty.Id)
			.setRecordType(BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID).setAccount(objAccount.Id).setType('Renewal')
			.setStatus('Ready for Qualification').setOwnerId(UserInfo.getUserId()).build();
		insert objBO;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder().setName('Test CO').setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(CarrierOrderUtil.RECTYPE_RENEWAL).setCarrier(list_Carriers[0].Id).setBenefitOrder(objBO.Id).build();
		insert objCO;

		BenefitOrderHelperTests.skipTrigger(false);
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Missing Event Info
	 **/
	@isTest
	static void testMissingEventInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-01')
			.setApplicationType('Renewal')
			.setCompanyId('786780989909')
			.setEventId('293iwk-oweif')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Processing State should be Error');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Missing Event Id
	 **/
	@isTest
	static void testChangeEventId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-02')
			.setApplicationType('Renewal')
			.setCompanyId('786780989909')
			.setEventId('test-data')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Carrier Switch Termination","termination_reason":null,"group_termination_event_id":"03980","company_id":"786780989909","application_id":"78090-02","application_type":"Renewal","company_hippo_link":null,"terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"78809987809","form_link":null}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Id, Processing_State__c, Event_Id__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals('293iwk-oweif', objHIGroupEvent.Event_Id__c, 'Event Id should be updated from JSON');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Missing Company Id
	 **/
	@isTest
	static void testMissingCompanyId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-03')
			.setApplicationType('Renewal')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Carrier Switch Termination","termination_reason":null,"group_termination_event_id":"03980","application_id":"78090-03","application_type":"Renewal","company_hippo_link":null,"terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"78809987809","form_link":null}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Processing State should be Error');
		System.assertEquals(HIGroupEventUtil.ERROR_COMPANY_ID_MISSING, objHIGroupEvent.Message__c, 'Error Message does not match');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Invalid Company Id
	 **/
	@isTest
	static void testInvalidCompanyId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('780900-04')
			.setApplicationType('Renewal')
			.setCompanyId('786780989909')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Carrier Switch Termination","termination_reason":null,"group_termination_event_id":"03980","company_id":"786780989909","application_id":"78090-04","application_type":"Renewal","company_hippo_link":null,"terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"78809987809","form_link":null}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Processing State should be Error');
		System.assertEquals(HIBenefitsUtil.COMPANY_DOES_NOT_EXIST, objHIGroupEvent.Message__c, 'Error Message does not match');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Json Parser Exception
	 **/
	@isTest
	static void testJsonParserError() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-05')
			.setApplicationType('Renewal')
			.setCompanyId('786780989909')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Carrier Switch Termination","termination_reason":null,"group_termination_event_id":"03980","company_id":"786780989909","application_id":"78090-05","application_type":"Renewal","company_hippo_link":null,"terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"78809987809",}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Processing State should be Error');
		System.assert(objHIGroupEvent.Message__c.contains('Error while parsing Event Info'), 'Error Message does not match');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Exception during Case creation
	 **/
	@isTest
	static void testExceptionCase() {
		Test.startTest();
		HIGroupEventTerminationCases.blnTestException = true;
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-06')
			.setApplicationType('Renewal')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Carrier Switch Termination","termination_reason":null,"group_termination_event_id":"03980","company_id":"510202021721","application_id":"78090-06","application_type":"Renewal","company_hippo_link":null,"terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"78809987809","form_link":null}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Carrier__c, Benefit_Order__c, Carrier_Order__c FROM Case];
		System.assert(list_Cases.isEmpty(), 'For Exceptions, the cases should not be created');
		System.assert(![SELECT Id FROM Exception_Log__c].isEmpty(), 'Exception should be thrown');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Positive Scenario, excluding BO and CO
	 **/
	@isTest
	static void testPositiveNoBOCOCase() {
		List<Carrier__c> list_Carriers = [SELECT Id, Name FROM Carrier__C WHERE Id__c = '234'];

		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-07')
			.setApplicationType('Renewal')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Total Group Termination","termination_reason":null,"group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental", "Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, RecordType.Name, Subject, Benefit_Types__c, Carrier__c, Integration_Id__c, Description FROM Case];

		System.assertEquals(1, list_Cases.size(), 'Only one case should be created');
		System.assertEquals(CaseUtils.RECTYPE_GROUP_TERMINATION, list_Cases[0].RecordTypeId, 'Group Termination Record Type does not match');
		System.assertEquals('Gusto Test: Test-CA: Group Termination', list_Cases[0].Subject, 'Case Subject to have Name, Acct and Type');
		System.assertEquals(true, list_Cases[0].Description.contains('Test-CA'), 'Carrier name should be Test-CA');
		System.assertEquals('Dental;Vision', list_Cases[0].Benefit_Types__c, 'All Benefit Types needs to render');
		System.assertEquals(list_Carriers[0].Id, list_Cases[0].Carrier__c, 'Carrier Id should be linked on Case');
		System.assertEquals('293iwk-oweif', list_Cases[0].Integration_Id__c, 'Integration Id should be set on Case');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Positive Scenario, including BO and CO
	 **/
	@isTest
	static void testPositiveCase() {
		List<Carrier__c> list_Carriers = [SELECT Id FROM Carrier__c ORDER BY Id__c];

		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-08')
			.setApplicationType('Renewal')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Terminate Carrier","termination_reason":"The company is being dissolved.","group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_co","new_provider_key":"test_ca","group_number":"9X780980","benefit_types":["Dental","Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Carrier__c, Benefit_Order__c, Carrier_Order__c, Reason_for_Leaving__c FROM Case];
		System.assertEquals(1, list_Cases.size(), 'Only one case should be created');
		System.assertEquals(list_Carriers[1].Id, list_Cases[0].Carrier__c, 'Carrier Id should be linked on Case');
		System.assertEquals('The company is being dissolved.', list_Cases[0].Reason_for_Leaving__c, 'Reason for Leaving does not match');
		System.assertEquals([SELECT Id FROM Benefit_Order__c LIMIT 1].Id, list_Cases[0].Benefit_Order__c, 'Benefit Order should be linked on Case');
		System.assertEquals([SELECT Id FROM Carrier_Order__c LIMIT 1].Id, list_Cases[0].Carrier_Order__c, 'Carrier Order should be linked on Case');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Rescind Termination
	 **/
	@isTest
	static void testCancelCase() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-09')
			.setApplicationType('Renewal')
			.setEventId('293iwk-01')
			.setEventInfo('{"event_id":"293iwk-01","event_type":"group_termination_case","termination_type":"Carrier Switch Termination","termination_reason":null,"group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental", "Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;

		List<Case> list_Cases = [SELECT Id, Status, Description, Event_Id__c, Reason_for_Leaving__c FROM Case];
		System.assertEquals(1, list_Cases.size(), 'Only one case should be created');
		System.assertEquals(null, list_Cases[0].Reason_for_Leaving__c, 'Reason for Leaving should be null');
		System.assertEquals('03980', list_Cases[0].Event_Id__c, 'Event Id should be set on Case');
		System.assertEquals(CaseUtils.STATUS_NEW, list_Cases[0].Status, 'Case Status should be New');
		System.assertEquals(true, list_Cases[0].Description.contains('Gusto Test'), 'Description does not match');

		list_Cases[0].Status = CaseUtils.STATUS_SUBMITTED;
		CaseTriggerHelper.skipTrigger = true;
		update list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-10')
			.setApplicationType('Renewal')
			.setEventId('293iwk-02')
			.setEventInfo('{"event_id":"293iwk-02","event_type":"group_termination_case","termination_type":"Rescind Termination","termination_reason":"The company has decided to no longer offer benefits.","group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental", "Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		list_Cases = [SELECT Id, Type, Status, Description, Event_Id__c FROM Case];
		System.assertEquals(1, list_Cases.size(), 'Only one case should exist');
		System.assertEquals('03980', list_Cases[0].Event_Id__c, 'Event Id should be set on Case');
		System.assertEquals(CaseUtils.STATUS_CANCELLED, list_Cases[0].Status, 'Case Status should be Cancelled');
		System.assertEquals(CaseUtils.TYPE_RESCIND_TERMINATE, list_Cases[0].Type, 'Type should be updated from Payload');
		System.assertEquals(Label.Group_Term_Rescind_Term_Description, list_Cases[0].Description, 'Description does not match');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Invalid Termination Reason
	 **/
	@isTest
	static void testInvalidTermReason() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('780900-04')
			.setApplicationType('Renewal')
			.setCompanyId('786780989909')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Carrier Switch Termination","termination_reason":"Invalid reason","group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental", "Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIGroupEvent.Processing_State__c, 'Processing State should be Error');
		System.assertEquals(HIGroupEventUtil.ERROR_INVALID_TERM_REASON, objHIGroupEvent.Message__c, 'Error Message does not match');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Multiple Cases
	 **/
	@isTest
	static void testCancelMultipleCases() {
		Test.startTest();
		List<HIGroupEvent__c> list_HIGroupEvents = new List<HIGroupEvent__c> {
			new TestDataFactory.HIGroupEventBuilder()
				.setApplicationId('78090-09-01')
				.setApplicationType('Renewal')
				.setEventId('293iwk-01')
				.setEventInfo('{"event_id":"293iwk-01","event_type":"group_termination_case","termination_type":"Suspend Only","termination_reason":null,"group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
				.setEventType('group_termination_case')
				.build(),
			new TestDataFactory.HIGroupEventBuilder()
				.setApplicationId('78090-09-02')
				.setApplicationType('Renewal')
				.setEventId('293iwk-02')
				.setEventInfo('{"event_id":"293iwk-02","event_type":"group_termination_case","termination_type":"Terminate Carrier","termination_reason":null,"group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_co","new_provider_key":"test_ca","group_number":"9X780980","benefit_types":["Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
				.setEventType('group_termination_case')
				.build()
		};
		insert list_HIGroupEvents;

		List<Case> list_Cases = [SELECT Id, Status, Event_Id__c FROM Case];
		System.assertEquals(2, list_Cases.size(), 'Two cases should be created');

		list_Cases[0].Status = CaseUtils.STATUS_SUBMITTED;
		list_Cases[1].Status = CaseUtils.STATUS_SUBMITTED;
		CaseTriggerHelper.skipTrigger = true;
		update list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-09-03')
			.setApplicationType('Renewal')
			.setEventId('293iwk-03')
			.setEventInfo('{"event_id":"293iwk-02","event_type":"group_termination_case","termination_type":"Rescind Termination","termination_reason":null,"group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_ca","new_provider_key":"test_co","group_number":"9X780980","benefit_types":["Dental", "Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		list_Cases = [SELECT Id, Type, Status, Event_Id__c FROM Case];
		System.assertEquals('03980', list_Cases[0].Event_Id__c, 'Event Id should be set on Case');
		System.assertEquals(CaseUtils.STATUS_CANCELLED, list_Cases[0].Status, 'Case Status should be Cancelled');
		System.assertEquals(CaseUtils.TYPE_RESCIND_TERMINATE, list_Cases[0].Type, 'Type should be updated from Payload');
		System.assertNotEquals(CaseUtils.STATUS_CANCELLED, list_Cases[1].Status, 'Case Status should not be Cancelled');
	}

	/**
	 * @Author      : Rushi R
	 * @Description : Test Case for Bor Termination Scenario
	 **/
	@isTest
	static void testBorTerminationCase() {
		List<Carrier__c> list_Carriers = [SELECT Id FROM Carrier__c ORDER BY Id__c];

		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('78090-08')
			.setApplicationType('Renewal')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Bor Termination","termination_reason":"The company is being dissolved.","group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_co","new_provider_key":"test_ca","group_number":"9X780980","benefit_types":["Dental","Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Type, Description FROM Case];
		System.assertEquals(1, list_Cases.size(), 'Only one case should be created');
		System.assertEquals('Bor Termination', list_Cases[0].Type, 'Case Type should be set to Bor Termination');
		System.assert(list_Cases[0].Description.contains('moving to a new broker of record'), 'Description does not match');
	}

	/**
	 * @Author      : Bhagat singh
	 * @Description : Test Case for type 'Partial Coverage Termination'
	 **/
	@isTest
	static void testPartialCoverageTerminationCase() {
		List<Carrier__c> list_Carriers = [SELECT Id FROM Carrier__c ORDER BY Id__c];

		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setApplicationId('24643')
			.setApplicationType('Renewal')
			.setEventId('293iwk-oweif')
			.setEventInfo('{"event_id":"293iwk-oweif","event_type":"group_termination_case","termination_type":"Partial Coverage Termination","termination_reason":"The company is being dissolved.","group_termination_event_id":"03980","company_id":"510202021721","application_id":"24643","application_type":"Renewal","company_hippo_link":"http://gusto.staging.com/510202021721","terminating_provider_key":"test_co","new_provider_key":"test_ca","group_number":"9X780980","benefit_types":["Dental","Vision"],"termination_deadline":"2023-05-27","coverage_end_date":"2023-06-01","contact_id":"187654321100","form_link":"http://web.url"}')
			.setEventType('group_termination_case')
			.build();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Type, Description FROM Case];
		System.assertEquals(HIGroupEventUtil.TYPE_PARTIAL_COVERAGE_TERMINATION, list_Cases[0].Type, 'Case Type should be set to Partial Coverage Termination');
	}
}