/**
  Author:        Robin Grover
  Company:       Gusto
  Description:   This is a test class for HIFulfillmentEventEmployeeUpdateTest

  History
  9/4/2017    Robin Grover     Initial Implementation
  11/9/2020   Rushi Ravisaheb  Fixed 101 SOQL error and formatted class
  **/
@isTest
private class HIFulfillmentDependentAgingOutTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);
		EncryptionUtils.generateKey('Master');
		List<Account> list_Account = new List<Account>();
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('1403814155979215').setName('Test Account 1').build());
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('1404257697994579').setName('Test Account 2').build());
		insert list_Account;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Principal').setUniqueName('Principal').setState('AL').setCarrierId('48').setKey('principal_ca').setId('24').build();
		insert objCarrier;
		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : insert Hi Fulfilment Record of type dependent_aging_out
	 **/
	@isTest
	static void insertDpendentAgingOut() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('dependent_aging_out')
			.setEventInfo(
				'{"employee":{"id":1403814289845323,"first_name":"Samantha","last_name":"Fay","middle_initial":"","status":"Active","ssn":"123456789",' +
				'"birthday":"1975-01-21","company_id":1403814155979215,"hired_at":"2011-04-01","employment_status":"full_time","home_address":{"id":1403814337566789,' +
				'"street_1":"126 Conn Fields","street_2":"Apt. 945","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":null,' +
				'"created_at":"2014-06-26T13:25:37.000-07:00","updated_at":"2014-06-26T13:25:37.000-07:00","fax":null,"inactive":false,"work_address":false},' +
				'"work_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA",' +
				'"zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00",' +
				'"fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"email":"helen1403814290162314@bauch.name","gender":"male",' +
				'"panda_url":"http://manage.zenpayroll.dev:3000/companies/1403814155979215/employees/1403814289845323",' +
				'"hippo_url":"http://localhost:4001/companies/1403814155979215/employees/1403814289845323"},"company":{"id":1403814155979215,"name":"Keebler Inc",' +
				'"email":"chesley.little1403814155945538@auer.com","salesforce_account_id":null,"work_states":["CA"],"sic_code":"7379","mailing_address":{"id":1403814205717482,' +
				'"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":"4626259268",' +
				'"created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00","fax":"8496074826","inactive":false,"work_address":true,' +
				'"employee_count":21},"filing_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange",' +
				'"state":"CA","zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00",' +
				'"fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"benefits_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs",' +
				'"street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00",' +
				'"updated_at":"2014-06-26T13:23:25.000-07:00","fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"number_of_eligible_ees":7,' +
				'"number_of_ineligible_ees":1,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1403814155979215",' +
				'"hippo_url":"http://localhost:4001/companies/1403814155979215"},"dependent":{"id":3,"first_name":"Darrell","last_name":"Lakin","ssn":"123456789",' +
				'"birthday":"2006-07-30","gender":"female","dependent_type":"child","employee_id":1403814289845323,' +
				'"url":"http://localhost:4001/companies/1403814155979215/employees/1403814289845323/dependents/3","disabled":false}}'
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
	 * @Description : update Hi Fulfilment Record of type dependent_aging_out
	 **/
	@isTest
	static void updateDpendentAgingOut() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HIFulfillmentEventTriggerHelper.skipTrigger = true;
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('dependent_aging_out')
			.setEventInfo(
				'{"employee":{"id":1403814289845323,"first_name":"Samantha","last_name":"Fay","middle_initial":"","status":"Active","ssn":"123456789",' +
				'"birthday":"1975-01-21","company_id":1403814155979215,"hired_at":"2011-04-01","employment_status":"full_time","home_address":{"id":1403814337566789,' +
				'"street_1":"126 Conn Fields","street_2":"Apt. 945","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":null,' +
				'"created_at":"2014-06-26T13:25:37.000-07:00","updated_at":"2014-06-26T13:25:37.000-07:00","fax":null,"inactive":false,"work_address":false},' +
				'"work_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA",' +
				'"zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00",' +
				'"fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"email":"helen1403814290162314@bauch.name","gender":"male",' +
				'"panda_url":"http://manage.zenpayroll.dev:3000/companies/1403814155979215/employees/1403814289845323",' +
				'"hippo_url":"http://localhost:4001/companies/1403814155979215/employees/1403814289845323"},"company":{"id":1403814155979215,"name":"Keebler Inc",' +
				'"email":"chesley.little1403814155945538@auer.com","salesforce_account_id":null,"work_states":["CA"],"sic_code":"7379","mailing_address":{"id":1403814205717482,' +
				'"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":"4626259268",' +
				'"created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00","fax":"8496074826","inactive":false,"work_address":true,' +
				'"employee_count":21},"filing_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange",' +
				'"state":"CA","zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00",' +
				'"fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"benefits_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs",' +
				'"street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00",' +
				'"updated_at":"2014-06-26T13:23:25.000-07:00","fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"number_of_eligible_ees":7,' +
				'"number_of_ineligible_ees":1,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1403814155979215",' +
				'"hippo_url":"http://localhost:4001/companies/1403814155979215"},"dependent":{"id":3,"first_name":"Darrell","last_name":"Lakin","ssn":"123456789",' +
				'"birthday":"2006-07-30","gender":"female","dependent_type":"child","employee_id":1403814289845323,' +
				'"url":"http://localhost:4001/companies/1403814155979215/employees/1403814289845323/dependents/3","disabled":false}}'
			)
			.build();
		insert objHiEvent;

		HIFulfillmentEventTriggerHelper.skipTrigger = false;
		update objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Contact.Email, RecordType.Name FROM Case WHERE Account.ZP_Company_ID__c = '1403814155979215'];
		System.assertEquals('MF Termination', list_Cases[0].RecordType.Name, 'MF Termination case record is not created.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Search existing contact with respect to EmployeeId and map with Case records
	 **/
	@isTest
	static void mapExistingContactWithEmployeeId() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1403814155979215' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Samantha')
			.setLastName('Fay')
			.setEmail('samanthafay@gmail.com')
			.setEmployeeId('1403814289845323')
			.build();
		insert objContact;
		Utils.skipTrigger(false);

		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('dependent_aging_out')
			.setEventInfo(
				'{"employee":{"id":1403814289845323,"first_name":"Samantha","last_name":"Fay","middle_initial":"","status":"Active","ssn":"123456789",' +
				'"birthday":"1975-01-21","company_id":1403814155979215,"hired_at":"2011-04-01","employment_status":"full_time","home_address":{"id":1403814337566789,' +
				'"street_1":"126 Conn Fields","street_2":"Apt. 945","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":null,' +
				'"created_at":"2014-06-26T13:25:37.000-07:00","updated_at":"2014-06-26T13:25:37.000-07:00","fax":null,"inactive":false,"work_address":false},' +
				'"work_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA",' +
				'"zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00",' +
				'"fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"email":"helen1403814290162314@bauch.name","gender":"male",' +
				'"panda_url":"http://manage.zenpayroll.dev:3000/companies/1403814155979215/employees/1403814289845323",' +
				'"hippo_url":"http://localhost:4001/companies/1403814155979215/employees/1403814289845323"},"company":{"id":1403814155979215,"name":"Keebler Inc",' +
				'"email":"chesley.little1403814155945538@auer.com","salesforce_account_id":null,"work_states":["CA"],"sic_code":"7379","mailing_address":{"id":1403814205717482,' +
				'"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":"4626259268",' +
				'"created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00","fax":"8496074826","inactive":false,"work_address":true,' +
				'"employee_count":21},"filing_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs","street_2":"Apt. 933","city":"Anaheim","county_name":"Orange",' +
				'"state":"CA","zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00","updated_at":"2014-06-26T13:23:25.000-07:00",' +
				'"fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"benefits_address":{"id":1403814205717482,"street_1":"387 Huel Cliffs",' +
				'"street_2":"Apt. 933","city":"Anaheim","county_name":"Orange","state":"CA","zip":"92807","country":"USA","phone":"4626259268","created_at":"2014-06-26T13:23:25.000-07:00",' +
				'"updated_at":"2014-06-26T13:23:25.000-07:00","fax":"8496074826","inactive":false,"work_address":true,"employee_count":21},"number_of_eligible_ees":7,' +
				'"number_of_ineligible_ees":1,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1403814155979215",' +
				'"hippo_url":"http://localhost:4001/companies/1403814155979215"},"dependent":{"id":3,"first_name":"Darrell","last_name":"Lakin","ssn":"123456789",' +
				'"birthday":"2006-07-30","gender":"female","dependent_type":"child","employee_id":1403814289845323,' +
				'"url":"http://localhost:4001/companies/1403814155979215/employees/1403814289845323/dependents/3","disabled":false}}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Contact.Email, RecordType.Name FROM Case WHERE AccountId = :objAccount.Id];
		System.assertEquals('MF Termination', list_Cases[0].RecordType.Name, 'MF Termination case record is not created');
		System.assertEquals(objContact.Email, list_Cases[0].Contact.Email, 'Unable to search Contact on the basis of Employee id and map with Case.');
	}
}