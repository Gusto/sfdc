@isTest
private class HIFulfillmentEOIFollowupTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);
		EncryptionUtils.generateKey('Master');
		List<Account> list_Account = new List<Account>();
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('11111').setName('Test Account 1').build());
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('7757616923548552').setName('Test Account 2').build());
		insert list_Account;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Guardian').setUniqueName('Guardian').setState('CA').setCarrierId('48').setKey('guardian_ca').setId('24').build();
		insert objCarrier;

		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : insert Hi Fulfilment Record of type eoi_followup
	 **/
	static testMethod void insertEOIFollowUp() {
		HIFulfillmentEventTriggerHelper.queue = true;
		EmailMessageTriggerHelper.skipTrigger = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('eoi_followup')
			.setOpsOwner('member_fulfillment')
			.setEventInfo(
				'{"selection":{"id":781541,"policy_id":85505,"benefit_type":"voluntary_life","subscriber_id":"67960571","processing_status":"processed","start_date":"2019-01-22","end_date":"2019-12-31","enrollment_id":368236,"employee_id":7757869432518714,"dependent_ids":[86213,86217],"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/selections/781541","guaranteed_issue":"100000.0","voluntary_benefit_amount":"100000.0","total_benefit_amount":"100000.0"},"policy":{"id":85505,"name":"Guardian - Voluntary Life \u0026 AD\u0026D - Sila Nanotechnologies","benefit_type":"voluntary_life","group_number":"70247800","policy_number":null,"plan_id":13994,"visible":true,"termination_policy":"last_day_of_employment","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923548552/policies/85505"},"employee":{"id":7757869432518714,"first_name":"Renate","last_name":"Keeling","middle_initial":null,"status":"Active","ssn":"123456789","birthday":"1984-07-09","company_id":7757616923548552,"hired_at":"2019-01-22","employment_status":"full_time","home_address":{"id":7757869432685256,"fax":"6536223026","zip":"94501","city":"Alameda","phone":"2251536222","state":"CA","country":"USA","inactive":false,"street_1":"945 Spencer Summit","street_2":"Apt. 280","created_at":"2018-12-31T16:23:31.000-08:00","updated_at":"2019-03-12T14:23:09.000-07:00","county_name":"Alameda","work_address":false},"work_address":{"id":7757727713142867,"fax":"5562703451","zip":"94501","city":"Alameda","phone":"5719209244","state":"CA","country":"USA","inactive":false,"street_1":"92351 Corrin Islands","street_2":"Suite 975","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true},"email":"imogenebernier@kautzerrohan.name","gender":"male","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923548552/employees/7757869432518714","hippo_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714"},"company":{"id":7757616923548552,"name":"Reynolds-Weimann","email":"virgiemccullough@gislason.io","salesforce_account_id":"0011600001sg2vaAAA","work_states":["CA","NH","VA"],"sic_code":"3999","mailing_address":{"id":7757727713142867,"fax":"6837311285","zip":"94501","city":"Alameda","phone":"5734550370","state":"CA","country":"USA","inactive":false,"street_1":"4892 Pfeffer Haven","street_2":"Apt. 662","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"filing_address":{"id":7757727713142867,"fax":"3020493736","zip":"94501","city":"Alameda","phone":"8465163034","state":"CA","country":"USA","inactive":false,"street_1":"25690 Von Oval","street_2":"Suite 368","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"benefits_address":{"id":7757727713142867,"fax":"3020493736","zip":"94501","city":"Alameda","phone":"8465163034","state":"CA","country":"USA","inactive":false,"street_1":"25690 Von Oval","street_2":"Suite 368","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"number_of_eligible_ees":119,"number_of_ineligible_ees":8,"has_federal_cobra":false,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923548552","hippo_url":"http://localhost:4001/companies/7757616923548552"},"state_carrier":{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22"},"eoi_details":{"selection_id":781541,"benefit_amount":"500000.0","guaranteed_issue":"100000.0","eoi_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/eois/processing_dashboard","effective_date":"2019-01-01","dependent_participants":[{"name":"Foster Batz","dependent_type":"spouse","benefit_amount":"250000.0","guaranteed_issue":"25000.0"},{"name":"Moses Durgan","dependent_type":"child","benefit_amount":null,"guaranteed_issue":null}],"document_id":343446},"benefits_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/benefits"}'
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
	 * @Description : update Hi Fulfilment Record of type eoi_followup
	 **/
	static testMethod void updateEOIFollowUp() {
		HIFulfillmentEventTriggerHelper.queue = true;
		EmailMessageTriggerHelper.skipTrigger = true;
		Test.startTest();
		HIFulfillmentEventTriggerHelper.skipTrigger = true;
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('eoi_followup')
			.setOpsOwner('member_fulfillment')
			.setEventInfo(
				'{"selection":{"id":781541,"policy_id":85505,"benefit_type":"voluntary_life","subscriber_id":"67960571","processing_status":"processed","start_date":"2019-01-22","end_date":"2019-12-31","enrollment_id":368236,"employee_id":7757869432518714,"dependent_ids":[86213,86217],"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/selections/781541","guaranteed_issue":"100000.0","voluntary_benefit_amount":"100000.0","total_benefit_amount":"100000.0"},"policy":{"id":85505,"name":"Guardian - Voluntary Life \u0026 AD\u0026D - Sila Nanotechnologies","benefit_type":"voluntary_life","group_number":"70247800","policy_number":null,"plan_id":13994,"visible":true,"termination_policy":"last_day_of_employment","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923548552/policies/85505"},"employee":{"id":7757869432518714,"first_name":"Renate","last_name":"Keeling","middle_initial":null,"status":"Active","ssn":"123456789","birthday":"1984-07-09","company_id":7757616923548552,"hired_at":"2019-01-22","employment_status":"full_time","home_address":{"id":7757869432685256,"fax":"6536223026","zip":"94501","city":"Alameda","phone":"2251536222","state":"CA","country":"USA","inactive":false,"street_1":"945 Spencer Summit","street_2":"Apt. 280","created_at":"2018-12-31T16:23:31.000-08:00","updated_at":"2019-03-12T14:23:09.000-07:00","county_name":"Alameda","work_address":false},"work_address":{"id":7757727713142867,"fax":"5562703451","zip":"94501","city":"Alameda","phone":"5719209244","state":"CA","country":"USA","inactive":false,"street_1":"92351 Corrin Islands","street_2":"Suite 975","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true},"email":"imogenebernier@kautzerrohan.name","gender":"male","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923548552/employees/7757869432518714","hippo_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714"},"company":{"id":7757616923548552,"name":"Reynolds-Weimann","email":"virgiemccullough@gislason.io","salesforce_account_id":"0011600001sg2vaAAA","work_states":["CA","NH","VA"],"sic_code":"3999","mailing_address":{"id":7757727713142867,"fax":"6837311285","zip":"94501","city":"Alameda","phone":"5734550370","state":"CA","country":"USA","inactive":false,"street_1":"4892 Pfeffer Haven","street_2":"Apt. 662","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"filing_address":{"id":7757727713142867,"fax":"3020493736","zip":"94501","city":"Alameda","phone":"8465163034","state":"CA","country":"USA","inactive":false,"street_1":"25690 Von Oval","street_2":"Suite 368","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"benefits_address":{"id":7757727713142867,"fax":"3020493736","zip":"94501","city":"Alameda","phone":"8465163034","state":"CA","country":"USA","inactive":false,"street_1":"25690 Von Oval","street_2":"Suite 368","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"number_of_eligible_ees":119,"number_of_ineligible_ees":8,"has_federal_cobra":false,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923548552","hippo_url":"http://localhost:4001/companies/7757616923548552"},"state_carrier":{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22"},"eoi_details":{"selection_id":781541,"benefit_amount":"500000.0","guaranteed_issue":"100000.0","eoi_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/eois/processing_dashboard","effective_date":"2019-01-01","dependent_participants":[{"name":"Foster Batz","dependent_type":"spouse","benefit_amount":"250000.0","guaranteed_issue":"25000.0"},{"name":"Moses Durgan","dependent_type":"child","benefit_amount":null,"guaranteed_issue":null}],"document_id":343446},"benefits_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/benefits"}'
			)
			.build();
		insert objHiEvent;

		HIFulfillmentEventTriggerHelper.skipTrigger = false;
		update objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Contact.Email, RecordType.Name FROM Case WHERE Account.ZP_Company_ID__c = '7757616923548552'];
		System.assertEquals('MF NHE', list_Cases[0].RecordType.Name, 'MF NHE case record is not created.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Search existing contact with respect to EmployeeId and map with Case records
	 * @Parm        : N/A
	 * @Return      : void
	 **/
	@isTest
	static void mapExistingContactWithEmployeeId() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '7757616923548552' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Renate')
			.setLastName('Keeling')
			.setEmail('renatekeeling@gmail.com')
			.setEmployeeId('7757869432518714')
			.build();
		insert objContact;
		Utils.skipTrigger(false);

		Test.startTest();
		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c();
		objHIEvent.id__c = 'Test321';
		objHIEvent.Event_Type__c = 'eoi_followup';
		objHIEvent.Event_Info__c = '{"selection":{"id":781541,"policy_id":85505,"benefit_type":"voluntary_life","subscriber_id":"67960571","processing_status":"processed","start_date":"2019-01-22","end_date":"2019-12-31","enrollment_id":368236,"employee_id":7757869432518714,"dependent_ids":[86213,86217],"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/selections/781541","guaranteed_issue":"100000.0","voluntary_benefit_amount":"100000.0","total_benefit_amount":"100000.0"},"policy":{"id":85505,"name":"Guardian - Voluntary Life \u0026 AD\u0026D - Sila Nanotechnologies","benefit_type":"voluntary_life","group_number":"70247800","policy_number":null,"plan_id":13994,"visible":true,"termination_policy":"last_day_of_employment","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923548552/policies/85505"},"employee":{"id":7757869432518714,"first_name":"Renate","last_name":"Keeling","middle_initial":null,"status":"Active","ssn":"123456789","birthday":"1984-07-09","company_id":7757616923548552,"hired_at":"2019-01-22","employment_status":"full_time","home_address":{"id":7757869432685256,"fax":"6536223026","zip":"94501","city":"Alameda","phone":"2251536222","state":"CA","country":"USA","inactive":false,"street_1":"945 Spencer Summit","street_2":"Apt. 280","created_at":"2018-12-31T16:23:31.000-08:00","updated_at":"2019-03-12T14:23:09.000-07:00","county_name":"Alameda","work_address":false},"work_address":{"id":7757727713142867,"fax":"5562703451","zip":"94501","city":"Alameda","phone":"5719209244","state":"CA","country":"USA","inactive":false,"street_1":"92351 Corrin Islands","street_2":"Suite 975","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true},"email":"imogenebernier@kautzerrohan.name","gender":"male","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923548552/employees/7757869432518714","hippo_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714"},"company":{"id":7757616923548552,"name":"Reynolds-Weimann","email":"virgiemccullough@gislason.io","salesforce_account_id":"0011600001sg2vaAAA","work_states":["CA","NH","VA"],"sic_code":"3999","mailing_address":{"id":7757727713142867,"fax":"6837311285","zip":"94501","city":"Alameda","phone":"5734550370","state":"CA","country":"USA","inactive":false,"street_1":"4892 Pfeffer Haven","street_2":"Apt. 662","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"filing_address":{"id":7757727713142867,"fax":"3020493736","zip":"94501","city":"Alameda","phone":"8465163034","state":"CA","country":"USA","inactive":false,"street_1":"25690 Von Oval","street_2":"Suite 368","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"benefits_address":{"id":7757727713142867,"fax":"3020493736","zip":"94501","city":"Alameda","phone":"8465163034","state":"CA","country":"USA","inactive":false,"street_1":"25690 Von Oval","street_2":"Suite 368","created_at":"2015-11-13T16:24:26.000-08:00","updated_at":"2017-10-12T09:18:21.000-07:00","county_name":"Alameda","work_address":true,"employee_count":173},"number_of_eligible_ees":119,"number_of_ineligible_ees":8,"has_federal_cobra":false,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923548552","hippo_url":"http://localhost:4001/companies/7757616923548552"},"state_carrier":{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22"},"eoi_details":{"selection_id":781541,"benefit_amount":"500000.0","guaranteed_issue":"100000.0","eoi_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/eois/processing_dashboard","effective_date":"2019-01-01","dependent_participants":[{"name":"Foster Batz","dependent_type":"spouse","benefit_amount":"250000.0","guaranteed_issue":"25000.0"},{"name":"Moses Durgan","dependent_type":"child","benefit_amount":null,"guaranteed_issue":null}],"document_id":343446},"benefits_url":"http://localhost:4001/companies/7757616923548552/employees/7757869432518714/benefits"}';
		objHIEvent.Ops_Owner__c = 'member_fulfillment';
		insert objHIEvent;

		List<Case> list_Cases = [SELECT Id, Contact.Email, RecordType.Name FROM Case WHERE AccountId = :objAccount.Id];

		Test.stopTest();

		System.assertEquals('MF NHE', list_Cases[0].RecordType.Name, 'MF NHE case record is not created.');
		System.assertEquals(objContact.Email, list_Cases[0].Contact.Email, 'Unable to search Contact on the basis of Employee id and map with Case.');
	}
}