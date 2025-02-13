@isTest
private class HIFulfillmentErrorEditingSelectionTest {
	@TestSetup
	static void createTestData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.SkipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		Blob key = EncryptionUtils.generateKey('Master');

		Account objAcc = new Account(ZP_Company_ID__c = '7757616923594875', Name = 'Test Account');
		insert objAcc;

		Carrier__c objCarrier = new Carrier__c(Key__c = 'bcbs_ma', Name = 'Test Carrier', State__c = 'AL', Id__c = '51');
		insert objCarrier;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAcc.Id)
			.setFirstName('Test')
			.setLastName('Test')
			.setEmail('test@test.com')
			.setPhone('123456')
			.setEmployeeId('7757869432536783')
			.build();
		insert objContact;

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'MF NHE');
		objCase.AccountId = objAcc.Id;
		objCase.ContactId = objContact.id;
		objCase.Carrier__c = objCarrier.id;
		objCase.Status = 'Submitted';
		objCase.Submission_Method__c = 'Carrier Portal';
		insert objCase;

		Case_Fulfillment_Selection_Status__c objSelectionStatus = new Case_Fulfillment_Selection_Status__c();
		objSelectionStatus.Case__c = objCase.Id;
		objSelectionStatus.Selection_Id__c = '51928';
		objSelectionStatus.Selection_UUID__c = 'a1441e46-7f0b-415e-b0c3-cddc09c88f74';
		insert objSelectionStatus;
	}

	/*
	 *@Description	: Test HI Fulfillment Event with Selection Id specified in request and populated on Case Fulfillment Selection Status record
	 */
	@isTest
	static void testHIFulfillEventRecordWithSelectionId() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		Test.startTest();

		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c();
		objHIEvent.Id__c = 'Test321';
		objHIEvent.Event_Type__c = 'error_editing_selection';
		objHIEvent.Event_Info__c = '{\"selection_id\":51928,\"benefit_type\":\"medical\",\"state_carrier_id\":38,\"error_type\":\"ResourceError\",\"error_message\":\"base: This employee has an active HSA. This is test\",\"employee_id\":7757869432536783,\"company_id\":7757616923594875,\"type\":\"Termination\"}';
		insert objHIEvent;

		Case objCase = [SELECT Id, Status FROM Case LIMIT 1];

		update objHIEvent;
		delete objHIEvent;
		undelete objHIEvent;

		Test.stopTest();

		System.assertEquals(objCase.Status, CaseUtils.STATUS_NEW, 'Case status should be new.');
	}

	/*
	 *@Author		: Neha Dabas
	 *@Description	: Test HI Fulfillment Event with Selection UUId specified in request and populated on Case Fulfillment Selection Status record
	 */
	@isTest
	static void testHIFulfillEventRecordWithSelectionUUId() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		Test.startTest();

		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c();
		objHIEvent.Id__c = 'Test321';
		objHIEvent.Event_Type__c = 'error_editing_selection';
		objHIEvent.Event_Info__c = '{\"selection_uuid\": \"a1441e46-7f0b-415e-b0c3-cddc09c88f74\",\"benefit_type\":\"medical\",\"state_carrier_id\": 38,\"error_type\":\"ResourceError\",\"error_message\":\"base: This employee has an active HSA. This is test\",\"employee_id\":7757869432536783,\"company_id\":7757616923594875,\"type\":\"Termination\"}';
		insert objHIEvent;

		Case objCase = [SELECT Id, Status FROM Case LIMIT 1];

		Test.stopTest();

		System.assertEquals(objCase.Status, CaseUtils.STATUS_NEW, 'Case status should be new.');
	}

	/*
	 *@Author		: Neha Dabas
	 *@Description	: Test HI Fulfillment Event without Selection UUId and Selection Id.
	 */
	@isTest
	static void testHIFulfillEventRecordWithoutIds() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		Test.startTest();

		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c();
		objHIEvent.Id__c = 'Test321';
		objHIEvent.Event_Type__c = 'error_editing_selection';
		objHIEvent.Event_Info__c = '{\"benefit_type\":\"medical\",\"state_carrier_id\": 38,\"error_type\":\"ResourceError\",\"error_message\":\"base: This employee has an active HSA. This is test\",\"employee_id\":7757869432536783,\"company_id\":7757616923594875,\"type\":\"Termination\"}';
		insert objHIEvent;

		Case objCase = [SELECT Id, Status FROM Case LIMIT 1];

		Test.stopTest();

		System.assert(objCase.Status != CaseUtils.STATUS_NEW, 'Case Status should not be new');
	}
}