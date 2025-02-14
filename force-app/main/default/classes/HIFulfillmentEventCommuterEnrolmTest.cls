/**
  Author:        Robin Grover
  Company:       Gusto
  Description:   This is a test class for HIFulfillmentEventCommuterEnrolmTest

  History
  7/11/2017    Robin Grover     Initial Implementation
  **/
@isTest
private class HIFulfillmentEventCommuterEnrolmTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);
		EncryptionUtils.generateKey('Master');
		List<Account> list_Account = new List<Account>();
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('652058429284').setName('Test Account 1').build());
		insert list_Account;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setKey('alegeus').setState('AL').build();
		insert objCarrier;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Account[0].Id)
			.setRecordTypeId('MF NHE')
			.setType('Audit')
			.setSubject('Test Case Owner Change Ben Admin Update Member Ops')
			.setOrigin('Phone')
			.setStatus('Working')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.build();
		insert objCase;
		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : insert Hi Fulfilment Record with event type employee_commuter_enrollment
	 **/
	@isTest
	static void insertHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_commuter_enrollment')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"employee":{"id":1,"first_name":"Jeanie","last_name":"Mayer","middle_initial":"C","status":"Active","ssn":"680111739","birthday":"1992-07-28","company_id":652058429284,"hired_at":"2017-07-28","employment_status":"full_time","home_address":{"id":704880222638,"street_1":"33270 Letha Point","street_2":"Suite 356","employee_count":1,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"33270 Letha Point, Suite 356"},"work_address":{"id":217178279283,"street_1":"1781 Hank Dam","street_2":"Suite 767","employee_count":5,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"1781 Hank Dam, Suite 767"},"email":"employee_email@example.com","gender":"female","panda_url":"https://app.zentest.com/companies/652058429284/employees/1","hippo_url":"https://hippo.zentest.com/companies/652058429284/employees/1"},"company":{"id":652058429284,"name":"Blanda Group","email":"company_email@example.com","salesforce_account_id":null,"work_states":null,"sic_code":"3999","mailing_address":{"id":857608442577,"street_1":"31025 Madelynn Cove","street_2":"Suite 321","employee_count":2,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"31025 Madelynn Cove, Suite 321"},"filing_address":{"id":166012536522,"street_1":"731 Cayla Bridge","street_2":"Apt. 928","employee_count":6,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"731 Cayla Bridge, Apt. 928"},"benefits_address":{"id":166012536522,"street_1":"731 Cayla Bridge","street_2":"Apt. 928","employee_count":6,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"731 Cayla Bridge, Apt. 928"},"number_of_eligible_ees":1,"number_of_ineligible_ees":0,"has_federal_cobra":null,"is_suspended":false,"panda_url":"https://app.zentest.com/companies/652058429284","hippo_url":"https://hippo.zentest.com/companies/652058429284"},"commuter_benefit":{"id":1,"company_id":652058429284,"status":"created","start_date":"2017-07-01","end_date":null,"upcoming":false,"active":false,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"waterfall","contribution_amount":"100.00"},"url":"https://hippo.zentest.com/companies/652058429284/commuter_benefits/1"},"commuter_employee_benefit":{"id":1,"employee_id":1,"commuter_benefit_id":1,"status":"created","start_date":"2017-07-01","transit_monthly_election":"125.0","transit_monthly_contribution":"100.0","transit_monthly_deduction":"25.0","parking_monthly_election":"50.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"50.0","url":"https://hippo.zentest.com/companies/652058429284/employees/1/commuter_employee_benefits/1","commuter_benefit_url":"https://hippo.zentest.com/companies/652058429284/commuter_benefits/1"},"policies_url":"https://hippo.zentest.com/companies/652058429284/policies","subscriptions_url":"https://hippo.zentest.com/companies/652058429284/employees/1/subscriptions"}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<HI_Fulfillment_Event__c> list_HIEvents = [SELECT Message__c, Processing_State__c FROM HI_Fulfillment_Event__c WHERE ID = :objHiEvent.Id];
		System.assertEquals('Data successfully Processed', list_HIEvents[0].Message__c, 'Event unable to processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, list_HIEvents[0].Processing_State__c, 'Event unable to processed');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : update Hi Fulfilment Record with event type employee_commuter_enrollment
	 **/
	@isTest
	static void updateHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HIFulfillmentEventTriggerHelper.skipTrigger = true;
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_commuter_enrollment')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"employee":{"id":1,"first_name":"Jeanie","last_name":"Mayer","middle_initial":"C","status":"Active","ssn":"680111739","birthday":"1992-07-28","company_id":652058429284,"hired_at":"2017-07-28","employment_status":"full_time","home_address":{"id":704880222638,"street_1":"33270 Letha Point","street_2":"Suite 356","employee_count":1,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"33270 Letha Point, Suite 356"},"work_address":{"id":217178279283,"street_1":"1781 Hank Dam","street_2":"Suite 767","employee_count":5,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"1781 Hank Dam, Suite 767"},"email":"employee_email@example.com","gender":"female","panda_url":"https://app.zentest.com/companies/652058429284/employees/1","hippo_url":"https://hippo.zentest.com/companies/652058429284/employees/1"},"company":{"id":652058429284,"name":"Blanda Group","email":"company_email@example.com","salesforce_account_id":null,"work_states":null,"sic_code":"3999","mailing_address":{"id":857608442577,"street_1":"31025 Madelynn Cove","street_2":"Suite 321","employee_count":2,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"31025 Madelynn Cove, Suite 321"},"filing_address":{"id":166012536522,"street_1":"731 Cayla Bridge","street_2":"Apt. 928","employee_count":6,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"731 Cayla Bridge, Apt. 928"},"benefits_address":{"id":166012536522,"street_1":"731 Cayla Bridge","street_2":"Apt. 928","employee_count":6,"city":"Edmundtown","state":"CA","county_name":"San Francisco","country":"USA","zip":"94107","phone":"4051234567","single_line_street":"731 Cayla Bridge, Apt. 928"},"number_of_eligible_ees":1,"number_of_ineligible_ees":0,"has_federal_cobra":null,"is_suspended":false,"panda_url":"https://app.zentest.com/companies/652058429284","hippo_url":"https://hippo.zentest.com/companies/652058429284"},"commuter_benefit":{"id":1,"company_id":652058429284,"status":"created","start_date":"2017-07-01","end_date":null,"upcoming":false,"active":false,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"waterfall","contribution_amount":"100.00"},"url":"https://hippo.zentest.com/companies/652058429284/commuter_benefits/1"},"commuter_employee_benefit":{"id":1,"employee_id":1,"commuter_benefit_id":1,"status":"created","start_date":"2017-07-01","transit_monthly_election":"125.0","transit_monthly_contribution":"100.0","transit_monthly_deduction":"25.0","parking_monthly_election":"50.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"50.0","url":"https://hippo.zentest.com/companies/652058429284/employees/1/commuter_employee_benefits/1","commuter_benefit_url":"https://hippo.zentest.com/companies/652058429284/commuter_benefits/1"},"policies_url":"https://hippo.zentest.com/companies/652058429284/policies","subscriptions_url":"https://hippo.zentest.com/companies/652058429284/employees/1/subscriptions"}'
			)
			.build();
		insert objHiEvent;

		HIFulfillmentEventTriggerHelper.skipTrigger = false;
		update objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Contact.Email, RecordType.Name FROM Case WHERE Account.ZP_Company_ID__c = '652058429284'];
		System.assertEquals('MF NHE', list_Cases[0].RecordType.Name, 'MF NHE case record is not created.');
	}
}