/**
 * @name         HIFulfillmentBORNewHireTest
 * @author       Bhagat Singh
 * @date         12/15/2017
 * @description  Test class for HIFulfillmentBORNewHire class.
 **/
@isTest
private class HIFulfillmentBORNewHireTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);
		Blob key = EncryptionUtils.generateKey('Master');
		List<Account> list_Account = new List<Account>();
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('1157616923622041').setName('Test Account 1').build());
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('1370368242490000').setName('Test Account 2').build());
		insert list_Account;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test Carrier').setKey('bcbs_ma').setState('AL').build();
		insert objCarrier;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Benefits Bor')
			.setAccountId(list_Account[0].Id)
			.setNumberOfEE(5)
			.setId('HIBORTRANSFER6582')
			.setBenefitsState('CA')
			.setStage('SAL')
			.setCloseDate(System.today().addDays(30))
			.setOrderGenerated(false)
			.build();
		insert objOpp;

		List<Benefit_Order__c> list_BenefitOrder = new List<Benefit_Order__c>();
		list_BenefitOrder.add(
			new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR'))
				.setName('Test Benefit BOR')
				.setAccount(list_Account[0].id)
				.setOpp(objOpp.Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('Ready for Balance Collection')
				.setBORId('6582')
				.setStatusDetail('Owner only group')
				.build()
		);
		insert list_BenefitOrder;
		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Insert Hi Fulfilment Record with event type new_hire_before_bor_implemented
	 **/
	@isTest
	static void insertHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setCompanyId('1157616923622041')
			.setEmployeeId('7757869431943859')
			.setEventType('new_hire_before_bor_implemented')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"company":{"id":1157616923622041,"name":"aaaa","email":"neela@livebungalow.com","salesforce_account_id":"00116000025E5dAAAS","work_states":["CA","NY","WA"],"sic_code":"8999","mailing_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":13,"number_of_ineligible_ees":0,"has_federal_cobra":null,"is_suspended":false,"panda_url":"https://app.gusto.com/panda/companies/1157616923622041","hippo_url":"https://hippo.gusto.com/companies/1157616923622041"},"bor_transfer":{"id":6582,"company_id":1157616923622041,"status":"bor_processed_by_all_carriers","submitted_at":"2017-10-23","authorized_date":"2017-11-01","hippo_url":"https://hippo.gusto.com/companies/1157616923622041/bor_transfers/6582"},"employee":{"id":7757869431943859,"first_name":"Morgan","last_name":"Brown","middle_initial":"","status":"Active","ssn":"183708429","birthday":"1989-03-25","company_id":1157616923622041,"hired_at":"2017-12-04","employment_status":"full_time","home_address":{"id":7757869431579201,"street_1":"1801 Wyoming Ave NW #5","street_2":"","city":"Washington","county_name":"District of Columbia","state":"DC","zip":"20009","country":"USA","phone":null,"created_at":"2017-11-30T11:42:35.000-08:00","updated_at":"2017-11-30T11:42:35.000-08:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":12},"email":"mlhartman89@gmail.com","gender":null,"panda_url":"https://app.gusto.com/panda/companies/1157616923622041/employees/7757869431943859","hippo_url":"https://hippo.gusto.com/companies/1157616923622041/employees/7757869431943859"}}'
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
	 * @Description : Update Hi Fulfilment Record with event type new_hire_before_bor_implemented
	 **/
	@isTest
	static void updateHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HIFulfillmentEventTriggerHelper.skipTrigger = true;
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setCompanyId('1157616923622041')
			.setEmployeeId('7757869431943859')
			.setEventType('new_hire_before_bor_implemented')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"company":{"id":1157616923622041,"name":"aaaa","email":"neela@livebungalow.com","salesforce_account_id":"00116000025E5dAAAS","work_states":["CA","NY","WA"],"sic_code":"8999","mailing_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":13,"number_of_ineligible_ees":0,"has_federal_cobra":null,"is_suspended":false,"panda_url":"https://app.gusto.com/panda/companies/1157616923622041","hippo_url":"https://hippo.gusto.com/companies/1157616923622041"},"bor_transfer":{"id":6582,"company_id":1157616923622041,"status":"bor_processed_by_all_carriers","submitted_at":"2017-10-23","authorized_date":"2017-11-01","hippo_url":"https://hippo.gusto.com/companies/1157616923622041/bor_transfers/6582"},"employee":{"id":7757869431943859,"first_name":"Morgan","last_name":"Brown","middle_initial":"","status":"Active","ssn":"183708429","birthday":"1989-03-25","company_id":1157616923622041,"hired_at":"2017-12-04","employment_status":"full_time","home_address":{"id":7757869431579201,"street_1":"1801 Wyoming Ave NW #5","street_2":"","city":"Washington","county_name":"District of Columbia","state":"DC","zip":"20009","country":"USA","phone":null,"created_at":"2017-11-30T11:42:35.000-08:00","updated_at":"2017-11-30T11:42:35.000-08:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":12},"email":"mlhartman89@gmail.com","gender":null,"panda_url":"https://app.gusto.com/panda/companies/1157616923622041/employees/7757869431943859","hippo_url":"https://hippo.gusto.com/companies/1157616923622041/employees/7757869431943859"}}'
			)
			.build();
		insert objHiEvent;

		HIFulfillmentEventTriggerHelper.skipTrigger = false;
		update objHiEvent;

		Test.stopTest();

		List<HI_Fulfillment_Event__c> list_HIEvents = [SELECT Message__c, Processing_State__c FROM HI_Fulfillment_Event__c WHERE ID = :objHiEvent.Id];
		System.assertEquals('Data successfully Processed', list_HIEvents[0].Message__c, 'Event unable to processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, list_HIEvents[0].Processing_State__c, 'Event unable to processed');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Search existing contact with respect to EmployeeId and map with Case records
	 **/
	@isTest
	static void mapExistingContactWithEmployeeId() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1157616923622041' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Morgan')
			.setLastName('Brown')
			.setEmail('mlhartman892323@gmail.com')
			.setEmployeeId('7757869431943859')
			.build();
		insert objContact;
		Utils.skipTrigger(false);

		Test.startTest();

		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setCompanyId('1157616923622041')
			.setEmployeeId('7757869431943859')
			.setEventType('new_hire_before_bor_implemented')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"company":{"id":1157616923622041,"name":"aaaa","email":"neela@livebungalow.com","salesforce_account_id":"00116000025E5dAAAS","work_states":["CA","NY","WA"],"sic_code":"8999","mailing_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":13,"number_of_ineligible_ees":0,"has_federal_cobra":null,"is_suspended":false,"panda_url":"https://app.gusto.com/panda/companies/1157616923622041","hippo_url":"https://hippo.gusto.com/companies/1157616923622041"},"bor_transfer":{"id":6582,"company_id":1157616923622041,"status":"bor_processed_by_all_carriers","submitted_at":"2017-10-23","authorized_date":"2017-11-01","hippo_url":"https://hippo.gusto.com/companies/1157616923622041/bor_transfers/6582"},"employee":{"id":7757869431943859,"first_name":"Morgan","last_name":"Brown","middle_initial":"","status":"Active","ssn":"183708429","birthday":"1989-03-25","company_id":1157616923622041,"hired_at":"2017-12-04","employment_status":"full_time","home_address":{"id":7757869431579201,"street_1":"1801 Wyoming Ave NW #5","street_2":"","city":"Washington","county_name":"District of Columbia","state":"DC","zip":"20009","country":"USA","phone":null,"created_at":"2017-11-30T11:42:35.000-08:00","updated_at":"2017-11-30T11:42:35.000-08:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":7757727713955738,"street_1":"1 Letterman","street_2":"C-3500","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"4156121900","created_at":"2017-05-31T10:15:57.000-07:00","updated_at":"2017-05-31T10:15:57.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":12},"email":"mlhartman89@gmail.com","gender":null,"panda_url":"https://app.gusto.com/panda/companies/1157616923622041/employees/7757869431943859","hippo_url":"https://hippo.gusto.com/companies/1157616923622041/employees/7757869431943859"}}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Contact.Email, RecordType.Name FROM Case WHERE AccountId = :objAccount.Id];
		System.assertEquals('MF NHE', list_Cases[0].RecordType.Name, 'MF NHE case record is not created.');
		System.assertEquals(objContact.Email, list_Cases[0].Contact.Email, 'Unable to search Contact on the basis of Employee id and map with Case.');
	}
}