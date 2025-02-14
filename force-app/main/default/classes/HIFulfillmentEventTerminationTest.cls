/**
 * @name         HIFulfillmentEventTerminationTest
 * @author       Bhagat Singh
 * @date         24 Feb 2022
 * @description  Test class for HIFulfillmentEventTermination class.
 **/
@isTest
private class HIFulfillmentEventTerminationTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);
		Blob blbkey = EncryptionUtils.generateKey('Master');
		List<Account> list_Account = new List<Account>();
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('7757616923607181').setName('Test Account').build());
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('1370368242490000').setName('Test Account').build());
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('7757616923718325').setName('Test Account').build());
		insert list_Account;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Principal').setUniqueName('Principal').setState('AL').setCarrierId('48').setKey('principal_ca').setId('24').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Principal').setUniqueName('Principal').setState('CO').setCarrierId('48').setKey('principal_co').setId('73').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Beam').setUniqueName('Beam').setState('CA').setCarrierId('64').setKey('beam_dental_ca').setId('259').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Guardian').setUniqueName('Guardian').setState('MA').setCarrierId('24').setKey('guardian_ma').setId('237').build());
		insert list_Carriers;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
			.setName('Benefits Change')
			.setAccountId(list_Account[1].Id)
			.setNumberOfEE(5)
			.setId('aasmEvent321')
			.setBenefitsState('CA')
			.setStage('SAL')
			.setType('New TAdA Plan')
			.setCloseDate(System.today().addDays(30))
			.build();
		insert objOpp;

		List<Benefit_Order__c> list_BenefitOrder = new List<Benefit_Order__c>();
		list_BenefitOrder.add(
			new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR'))
				.setName('Test Benefit BOR')
				.setAccount(list_Account[1].id)
				.setOpp(objOpp.Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('Ready for Qualification')
				.setBORId('aasmEvent321')
				.setStatusDetail('Owner only group')
				.build()
		);
		list_BenefitOrder.add(
			new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR'))
				.setName('Test Benefit BOR')
				.setAccount(list_Account[0].id)
				.setOpp(objOpp.Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('Ready for Qualification')
				.setBORId('aasmEvent321')
				.setStatusDetail('Owner only group')
				.build()
		);
		insert list_BenefitOrder;

		Map<String, Id> map_Carriers = new Map<String, Id>();
		for (Carrier__c objCarrier : [SELECT Id, Key__c FROM Carrier__c]) {
			map_Carriers.put(objCarrier.Key__c, objCarrier.Id);
		}

		List<Contact> list_Contact = new List<Contact>();
		list_Contact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(list_Account[1].Id)
				.setFirstName('Alex')
				.setLastName('Test01')
				.setEmail('testalex01@gmail.com')
				.setEmployeeId('7330104')
				.build()
		);
		list_Contact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(list_Account[1].Id)
				.setFirstName('Danielle')
				.setLastName('Test02')
				.setEmail('testdanielle02@gmail.com')
				.setEmployeeId('7230103')
				.build()
		);
		insert list_Contact;

		List<Case> list_Cases = new List<Case>();
		list_Cases.add(
			new TestDataFactory.CaseBuilder()
				.setAccountId(list_Account[1].Id)
				.setContactId(list_Contact[0].Id)
				.setRecordTypeId('MF Termination')
				.setType('Termination')
				.setSubject('Test Case')
				.setOrigin('Email')
				.setStatus('New')
				.setSuppliedEmail('test1@gusto.com')
				.setDescription('Test Case')
				.setIdCarrier(map_Carriers.get('principal_co'))
				.setEmployeeId('7330104')
				.setTerminationDate(Date.today())
				.setMFCoverageEndDate(Date.today())
				.setSelectionIds('5596986;5597002;')
				.build()
		);
		list_Cases.add(
			new TestDataFactory.CaseBuilder()
				.setAccountId(list_Account[1].Id)
				.setContactId(list_Contact[0].Id)
				.setRecordTypeId('MF Termination')
				.setType('Termination')
				.setSubject('Test Case')
				.setOrigin('Email')
				.setStatus('New')
				.setSuppliedEmail('test1@gusto.com')
				.setDescription('Test Case')
				.setIdCarrier(map_Carriers.get('beam_dental_ca'))
				.setEmployeeId('7330104')
				.setTerminationDate(Date.today())
				.setMFCoverageEndDate(Date.today())
				.setSelectionIds('4994358;5621553;')
				.build()
		);
		list_Cases.add(
			new TestDataFactory.CaseBuilder()
				.setAccountId(list_Account[1].Id)
				.setContactId(list_Contact[0].Id)
				.setRecordTypeId('MF Termination')
				.setType('Termination')
				.setSubject('Test Case')
				.setOrigin('Email')
				.setStatus('New')
				.setSuppliedEmail('test1@gusto.com')
				.setDescription('Test Case')
				.setIdCarrier(map_Carriers.get('guardian_ma'))
				.setEmployeeId('7330104')
				.setTerminationDate(Date.today())
				.setMFCoverageEndDate(Date.today())
				.setSelectionIds('4994365;4994369;4994382;')
				.build()
		);
		insert list_Cases;

		Utils.skipTrigger(false);
	}

	/**
	 * @description test SelectionUUID field value during termination
	 * @author Nigam Goyal | 02-22-2023
	 **/
	@isTest
	static void hIFulfillEventWithSubscriptionUUID() {
		Utils.skipTrigger(true);
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'principal_ca' LIMIT 1];
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1370368242490000' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('tamia@uptonreynolds.com')
			.setEmployeeId('7757869431795591')
			.build();
		insert objContact;

		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setCompanyId('1370368242490000')
			.setEmployeeId('7757869431795591')
			.setEventType('employee_losing_eligibility')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"state_carriers":[{"id":1299,"name":"Anthem Blue Cross Blue Shield of Connecticut","state":"CT","key":"anthem_ct","url":"http://hippo.gusto-dev.com:4001/national_carriers/4/state_carriers/1299","byb_automation_authorized":false,"forms":[]},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma","url":"http://hippo.gusto-dev.com:4001/national_carriers/24/state_carriers/237","byb_automation_authorized":true,"forms":[]}],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[],"losing_benefits_reason":"Termination","benefits_eligibility_end_date":"2022-07-05","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7757869431795592","middle_initial":"M","last_name":"Test01","id":7757869431795592,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7757869431795592","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7757869431795592/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7757869431795592/benefits","benefit_items":[{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":1299,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":1299,"coverage_end_date":"2022-10-10","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<CASE> list_Cases = [
			SELECT
				Id,
				Integration_Id__c,
				Integration_Key__c,
				Selection_Ids__c,
				Termination_Date__c,
				MF_Coverage_End_Date__c,
				Selection_UUIDs__c,
				Medical_UUID__c,
				Dental_UUID__c,
				Life_UUID__c,
				Vision_UUID__c,
				Long_Term_Disability_UUID__c,
				Short_Term_Disability_UUID__c,
				Benefit_Types__c
			FROM CASE
			WHERE Company_ID__c = '1370368242490000'
		];

		System.assertEquals('Processed', [SELECT Id, Processing_State__c FROM HI_Fulfillment_Event__c WHERE Id = :objHiEvent.Id].Processing_State__c, 'Not Processed');
		System.assertEquals(2, list_Cases.size(), 'No. of cases should be two');
		System.assertEquals(null, list_Cases[0].Selection_UUIDs__c, 'Selection UUID does not match value');
		System.assertEquals('a3a79762-70b1-4a40-b1bb-f80392cd7a4d;9d8f38a6-e033-4995-a277-9cc8366355d7', list_Cases[0].Medical_UUID__c, 'Medical_UUID__c does not match value');
		System.assertEquals('da70ea8e-3e58-46b7-ab35-493c8ad13d69', list_Cases[1].Dental_UUID__c, 'Dental_UUID__c does not match value');
		System.assertEquals('5ab6c540-5ef2-4712-8a20-bed568c9ddd7', list_Cases[1].Vision_UUID__c, 'Vision_UUID__c does not match value');
		System.assertEquals('7fd36f2b-17e6-46fe-839f-119c1862434d', list_Cases[1].Long_Term_Disability_UUID__c, 'Long_Term_Disability_UUID__c does not match value');
		System.assertEquals(Date.newInstance(2022, 7, 5), list_Cases[0].Termination_Date__c, 'Termination Date is not changed');
		System.assertEquals(Date.newInstance(2022, 10, 10), list_Cases[0].MF_Coverage_End_Date__c, 'MF Coverage End Date is not changed');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Hi Fulfilment Record of type employee_losing_eligibility with Subscription
	 **/
	@isTest
	static void hIFulfillEventWithSubscription() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();

		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setEventInfo(
				'{"benefits_eligibility_end_date":"2017-07-27","losing_benefits_reason":"Termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":1370368242490000,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000","hippo_url":"http://localhost:4001/companies/1370368242490000"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22","forms":[]},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2","forms":[]}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/policies/8401"}],"dependents":[],"forms":[],"alegeus":{"dca":{"subscriptions":[],"policies":[]},"fsa":{"subscriptions":[{"id":103302,"policy_id":26484,"benefit_type":"fsa","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"employee_alegeus_id":218828899,"dependent_ids":[],"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103302"}],"policies":[{"id":26484,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":964954019,"visible":true,"termination_policy":"last_day_of_employment","url":"http://localhost:4001/companies/1370368242490000/policies/26484"}]},"hsa":{}},"subscriptions_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/dependents","commuter_benefit":{"id":3,"company_id":1408063107892611,"status":"processed","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3","provider_key": "alegeus"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"}}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		System.assert([SELECT Id, Processing_State__c FROM HI_Fulfillment_Event__c WHERE Id = :objHiEvent.Id].Processing_State__c == 'Processed', 'Event is not Processed');
	}

	@isTest
	static void hIFulfillEventWithTada() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();

		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setEventInfo(
				'{"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Maya","last_name":"Angelou","middle_initial":null,"status":"Active","ssn":"124031020","birthday":"1928-04-04","company_id":1370368242490000,"hired_at":"2024-12-23","employment_status":"full_time","home_address":{"fax":null,"zip":"94107","city":"SanFrancisco","phone":null,"state":"CA","country":"US","inactive":false,"street_1":"21StillmanStreet","street_2":"","created_at":"2024-12-1609:56:31-0800","updated_at":"2024-12-1609:56:31-0800","county_name":"SanFrancisco","work_address":false,"employee_count":0},"work_address":{"id":7757869470074221,"fax":null,"zip":"95113","city":"SanJose","phone":"5725554362","state":"CA","country":"US","inactive":false,"street_1":"200ESantaClaraSt","street_2":"Suite200","created_at":"2024-12-1609:53:19-0800","updated_at":"2024-12-1609:53:19-0800","county_name":"SantaClara","work_address":true,"employee_count":13},"email":"maya1370368242490000@hotmail.com","gender":null,"annual_salary":"85000.0","benefits_eligibility_date":"2024-12-23","panda_url":"https://app.gusto-staging.com/panda/companies/1370368242490000/employees/7757869431795591","hippo_url":"https://hippo.gusto-staging.com/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Sanford-Carter","email":"nu@wolf.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"0821","mailing_address":{"id":7757869470074221,"fax":null,"zip":"95113","city":"SanJose","phone":"5725554362","state":"CA","country":"US","inactive":false,"street_1":"200ESantaClaraSt","street_2":"Suite200","created_at":"2024-12-16T09:53:19-08:00","updated_at":"2024-12-16T09:53:22-08:00","county_name":"SantaClara","work_address":true,"employee_count":13},"filing_address":{"id":7757869470074221,"fax":null,"zip":"95113","city":"SanJose","phone":"5725554362","state":"CA","country":"US","inactive":false,"street_1":"200ESantaClaraSt","street_2":"Suite200","created_at":"2024-12-16T09:53:19-08:00","updated_at":"2024-12-16T09:53:22-08:00","county_name":"SantaClara","work_address":true,"employee_count":13},"benefits_address":{"id":7757869470074221,"fax":null,"zip":"95113","city":"SanJose","phone":"5725554362","state":"CA","country":"US","inactive":false,"street_1":"200ESantaClaraSt","street_2":"Suite200","created_at":"2024-12-16T09:53:19-08:00","updated_at":"2024-12-16T09:53:22-08:00","county_name":"SantaClara","work_address":true,"employee_count":13},"number_of_eligible_ees":13,"number_of_ineligible_ees":0,"has_federal_cobra":false,"is_suspended":false,"panda_url":"https://app.gusto-staging.com/panda/companies/1370368242490000","hippo_url":"https://hippo.gusto-staging.com/companies/1370368242490000","google_drive_folder_url":"NoGoogleDrivefoldersetup"},"state_carriers":[],"benefit_items":[],"policies":[],"dependents":[],"forms":[],"benefits_url":"https://hippo.gusto-staging.com/companies/1370368242490000/employees/7757869431795591/benefits","dependents_url":"https://hippo.gusto-staging.com/companies/1370368242490000/employees/7757869431795591/dependents","sent_at":"2024-12-17T10:42:40.171-08:00","alegeus":{"fsa":{"benefit_items":[{"id":8303592,"policy_id":926271,"policy_uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","benefit_type":"fsa","start_date":"2024-11-01","end_date":"2025-02-16","processing_status":"processed","enrollment_id":3578786,"employee_id":7757869431795591,"employee_alegeus_id":490637226,"dependent_ids":[],"url":"https://hippo.gusto-staging.com/companies/1370368242490000/employees/7757869431795591/selections/8303592","uuid":"115b745f-05c7-46e6-9d3b-444c62fd989c"}],"policies":[{"id":926271,"name":"HealthFSA","benefit_type":"fsa","application_id":null,"application_type":null,"company_alegeus_id":null,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","url":"https://hippo.gusto-staging.com/companies/1370368242490000/policies/926271","uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","provider_key":"alegeus"}]}},"tada":{"fsa":{"benefit_items":[{"id":8303592,"policy_id":926271,"policy_uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","benefit_type":"fsa","start_date":"2024-11-01","end_date":"2025-02-16","processing_status":"processed","enrollment_id":3578786,"employee_id":7757869431795591,"employee_alegeus_id":490637226,"dependent_ids":[],"url":"https://hippo.gusto-staging.com/companies/1370368242490000/employees/7757869431795591/selections/8303592","uuid":"115b745f-05c7-46e6-9d3b-444c62fd989c"}],"policies":[{"id":926271,"name":"HealthFSA","benefit_type":"fsa","application_id":null,"application_type":null,"company_alegeus_id":null,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","url":"https://hippo.gusto-staging.com/companies/1370368242490000/policies/926271","uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","provider_key":"alegeus"}]},"hsa":{"benefit_items":[{"id":8303592,"policy_id":926271,"policy_uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","benefit_type":"hsa","start_date":"2024-11-01","end_date":"2025-02-16","processing_status":"processed","enrollment_id":3578786,"employee_id":7757869431795591,"employee_alegeus_id":490637226,"dependent_ids":[],"url":"https://hippo.gusto-staging.com/companies/1370368242490000/employees/7757869431795591/selections/8303592","uuid":"115b745f-05c7-46e6-9d3b-444c62fd989c"}],"policies":[{"id":926271,"name":"HealthFSA","benefit_type":"hsa","application_id":null,"application_type":null,"company_alegeus_id":null,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","url":"https://hippo.gusto-staging.com/companies/1370368242490000/policies/926271","uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","provider_key":"elevate"}]},"dca":{"benefit_items":[{"id":8303592,"policy_id":926271,"policy_uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","benefit_type":"dca","start_date":"2024-11-01","end_date":"2025-02-16","processing_status":"processed","enrollment_id":3578786,"employee_id":7757869431795591,"employee_alegeus_id":490637226,"dependent_ids":[],"url":"https://hippo.gusto-staging.com/companies/1370368242490000/employees/7757869431795591/selections/8303592","uuid":"115b745f-05c7-46e6-9d3b-444c62fd989c"}],"policies":[{"id":926271,"name":"HealthFSA","benefit_type":"dca","application_id":null,"application_type":null,"company_alegeus_id":null,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","url":"https://hippo.gusto-staging.com/companies/1370368242490000/policies/926271","uuid":"da4b79ff-4fa2-411b-a97e-03a563e59ea7","provider_key":"alegeus"}]}},"benefits_eligibility_end_date":"2024-12-14","losing_benefits_date":"2024-12-14","losing_benefits_reason":"Termination"}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		System.assert([SELECT Id, Processing_State__c FROM HI_Fulfillment_Event__c WHERE Id = :objHiEvent.Id].Processing_State__c == 'Processed', 'Event is not Processed');
	}

	@isTest
	static void hIFulfillEventWithCommuterEligibility() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();

		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_commuter_eligibility')
			.setEventInfo(
				'{"benefits_eligibility_end_date":"2017-07-27","losing_benefits_reason":"Termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":1370368242490000,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000","hippo_url":"http://localhost:4001/companies/1370368242490000"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22","forms":[]},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2","forms":[]}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/policies/8401"}],"dependents":[],"forms":[],"alegeus":{"dca":{"subscriptions":[],"policies":[]},"fsa":{"subscriptions":[{"id":103302,"policy_id":26484,"benefit_type":"fsa","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"employee_alegeus_id":218828899,"dependent_ids":[],"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103302"}],"policies":[{"id":26484,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":964954019,"visible":true,"termination_policy":"last_day_of_employment","url":"http://localhost:4001/companies/1370368242490000/policies/26484"}]},"hsa":{}},"subscriptions_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/dependents","commuter_benefit":{"id":3,"company_id":1408063107892611,"status":"processed","provider_key": "alegeus","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"}}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		System.assert([SELECT Id, Processing_State__c FROM HI_Fulfillment_Event__c WHERE Id = :objHiEvent.Id].Processing_State__c == 'Processed', 'Event is not Processed');
	}
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Hi Fulfilment Record of type employee_losing_eligibility with No Subscription
	 **/
	@isTest
	static void hIFulfillEventWithNoSubscription() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setEventInfo(
				'{"benefits_eligibility_end_date":"2017-07-27","losing_benefits_reason":"Termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":1370368242490000,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000","hippo_url":"http://localhost:4001/companies/1370368242490000"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22","forms":[]},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2","forms":[]}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/policies/8401"}],"dependents":[],"forms":[],"subscriptions_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/dependents","commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"}, "benefit_items":[{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":1299,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":1299,"coverage_end_date":"2022-10-10","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();
		System.assert([SELECT Id, Message__c FROM HI_Fulfillment_Event__c WHERE Id = :objHiEvent.Id].Message__c == 'Data successfully Processed', 'Message does not match');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Hi Fulfilment Record of type employee_losing_eligibility with Commuter
	 **/
	@isTest
	static void hIFulfillEventWithCommuter() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();

		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setEventInfo(
				'{"benefits_eligibility_end_date":"2017-09-25","losing_benefits_reason":"Termination","employee":{"id":7757869431686263,"first_name":"James","last_name":"Harland-Smith","middle_initial":"","status":"Active","ssn":"688487039","birthday":"1985-04-07","company_id":7757616923607181,"hired_at":"2017-03-06","employment_status":"full_time","home_address":{"id":7757727713827231,"street_1":"209 Anita Rd","street_2":"APT 7","city":"Burlingame","county_name":"San Mateo","state":"CA","zip":"94010","country":"USA","phone":null,"created_at":"2017-03-07T10:19:16.000-08:00","updated_at":"2017-03-07T10:19:16.000-08:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":7757727713732050,"street_1":"665 3rd St","street_2":"Suite 535","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"4155415331","created_at":"2017-01-08T17:32:34.000-08:00","updated_at":"2017-01-08T17:33:22.000-08:00","fax":null,"inactive":false,"work_address":true,"employee_count":17},"email":"james@notablelabs.com","gender":null,"panda_url":"https://app.gusto.com/panda/companies/7757616923607181/employees/7757869431686263","hippo_url":"https://hippo.gusto.com/companies/7757616923607181/employees/7757869431686263"},"company":{"id":7757616923607181,"name":"StemCycle Inc.","email":"pete@notablelabs.com","salesforce_account_id":"001G000001hSumWIAS","work_states":["CA","GA"],"sic_code":"8734","mailing_address":{"id":1408063207480754,"street_1":"1 Letterman Dr","street_2":"Building C Suite 400","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"7034070506","created_at":"2014-08-14T17:40:07.000-07:00","updated_at":"2014-08-14T17:40:07.000-07:00","fax":"","inactive":false,"work_address":true,"employee_count":2},"filing_address":{"id":1408063207480754,"street_1":"1 Letterman Dr","street_2":"Building C Suite 400","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"7034070506","created_at":"2014-08-14T17:40:07.000-07:00","updated_at":"2014-08-14T17:40:07.000-07:00","fax":"","inactive":false,"work_address":true,"employee_count":2},"benefits_address":{"id":1408063207480754,"street_1":"1 Letterman Dr","street_2":"Building C Suite 400","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94129","country":"USA","phone":"7034070506","created_at":"2014-08-14T17:40:07.000-07:00","updated_at":"2014-08-14T17:40:07.000-07:00","fax":"","inactive":false,"work_address":true,"employee_count":2},"number_of_eligible_ees":20,"number_of_ineligible_ees":0,"has_federal_cobra":null,"is_suspended":false,"panda_url":"https://app.gusto.com/panda/companies/7757616923607181","hippo_url":"https://hippo.gusto.com/companies/7757616923607181"},"commuter_benefit":{"id":3,"company_id":7757616923607181,"status":"processed","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/7757616923607181/commuter_benefits/3","provider_key": "alegeus"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/7757616923607181/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/7757616923607181/commuter_benefits/3"}}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		System.assert([SELECT Id, Processing_State__c FROM HI_Fulfillment_Event__c WHERE Id = :objHiEvent.Id].Processing_State__c == 'Processed', 'Event is not Processed');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Hi Fulfilment Record. Update email on existing Contact
	 **/
	@isTest
	static void terminationCasesMapWithExistingContact() {
		Utils.skipTrigger(true);
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1370368242490000' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('tamia@uptonreynolds.com')
			.setEmployeeId('7757869431795591')
			.build();
		insert objContact;

		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setEventInfo(
				'{"benefits_eligibility_end_date":"2017-07-27","losing_benefits_reason":"Termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":1370368242490000,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000","hippo_url":"http://localhost:4001/companies/1370368242490000"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22","forms":[]},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2","forms":[]}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/policies/8401"}],"dependents":[],"forms":[],"alegeus":{"dca":{"subscriptions":[],"policies":[]},"fsa":{"subscriptions":[{"id":103302,"policy_id":26484,"benefit_type":"fsa","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"employee_alegeus_id":218828899,"dependent_ids":[],"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103302"}],"policies":[{"id":26484,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":964954019,"visible":true,"termination_policy":"last_day_of_employment","url":"http://localhost:4001/companies/1370368242490000/policies/26484"}]},"hsa":{}},"subscriptions_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/dependents","commuter_benefit":{"id":3,"company_id":1408063107892611,"status":"processed","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3","provider_key": "alegeus"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"}}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		System.assertEquals(false, [SELECT Id, Contact.Email FROM Case WHERE AccountId = :objAccount.Id AND Contact.Email LIKE 'tamia%'].isEmpty(), 'Case is not created');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Hi Fulfilment Record with losing_benefits_reason as 'Cancel termination'.
	 **/
	@isTest
	static void hIFulfillEventWithCancelTerminationReason() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setEventInfo(
				'{"benefits_eligibility_end_date":"2017-07-27","losing_benefits_reason":"Cancel termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":1370368242490000,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000","hippo_url":"http://localhost:4001/companies/1370368242490000"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22","forms":[]},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2","forms":[]}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/policies/8401"}],"dependents":[],"forms":[],"alegeus":{"dca":{"subscriptions":[],"policies":[]},"fsa":{"subscriptions":[{"id":103302,"policy_id":26484,"benefit_type":"fsa","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"employee_alegeus_id":218828899,"dependent_ids":[],"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103302"}],"policies":[{"id":26484,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":964954019,"visible":true,"termination_policy":"last_day_of_employment","url":"http://localhost:4001/companies/1370368242490000/policies/26484"}]},"hsa":{}},"subscriptions_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/dependents","commuter_benefit":{"id":3,"company_id":1408063107892611,"status":"processed","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"benefit_items":[{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":1299,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":1299,"coverage_end_date":"2022-10-10","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-10","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		System.assert([SELECT Id, Status FROM Case WHERE Closed_Reason__c = 'Termination Cancelled'].size() == 0, 'Case is not terminated');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Hi Fulfilment Record with losing_benefits_reason and sun type Termination Date Changed
	 **/
	@isTest
	static void hiTerminationDateChanged() {
		Utils.skipTrigger(true);
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'principal_ca' LIMIT 1];
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1370368242490000' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('tamia@uptonreynolds.com')
			.setEmployeeId('7757869431795592')
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId('MF Termination')
			.setType('Termination')
			.setSubject('Test Case Owner Change Ben Admin Update Member Ops')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.setIdCarrier(list_Carrier[0].Id)
			.setEmployeeId('7757869431795592')
			.build();
		insert objCase;

		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setCompanyId('1370368242490000')
			.setEmployeeId('7757869431795592')
			.setEventSubType('Termination date changed')
			.setEventInfo(
				'{"state_carriers":[],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[],"losing_benefits_reason":"Termination date changed","benefits_eligibility_end_date":"2022-07-05","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7757869431795592","middle_initial":"M","last_name":"Test01","id":7757869431795592,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7757869431795592","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7757869431795592/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7757869461247539,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7757869431795592/benefits","benefit_items":[]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		System.assert([SELECT Id, Status FROM Case WHERE Id = :objCase.Id].Status == 'New', 'Case is not created');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update Existing Cases when Termination Date Changed
	 **/
	@isTest
	static void updateExistingCasesForTerminationDateChanged() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		String strSubType = 'Termination date changed';
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setCompanyId('1370368242490000')
			.setEmployeeId('7330104')
			.setEventSubType(strSubType)
			.setEventInfo(
				'{"state_carriers":[{"url":"https://hippo.gusto.com/national_carriers/48/state_carriers/24","state":"CO","name":"Principal","key":"principal_co","id":73,"forms":[6541282],"byb_automation_authorized":false},{"id":259,"name":"Beam","state":"CA","key":"beam_dental_ca","url":"http://hippo.gusto-dev.com:4001/national_carriers/4/state_carriers/259","byb_automation_authorized":false,"forms":[]},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma","url":"http://hippo.gusto-dev.com:4001/national_carriers/24/state_carriers/237","byb_automation_authorized":true,"forms":[]}],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632828","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":2374,"name":"Principal Life 50,000 - CA","id":632828,"group_number":"1061525","benefit_type":"life"},{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632829","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":4099,"name":"Long Term Disability [Brand Knew]","id":632829,"group_number":"1061525","benefit_type":"long_term_disability"}],"losing_benefits_reason":"' +
					strSubType +
					'","benefits_eligibility_end_date":"2022-07-14","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7330104","middle_initial":"M","last_name":"Test01","id":7330104,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/benefits","benefit_items":[{"uuid":"a00c9526-211c-4baa-a51d-e5aa94f77de7","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5596986","total_premium":4.9,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"5f05200a-325b-4b30-886c-e9588273fa4c","policy_id":632828,"id":5596986,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"life"},{"uuid":"c002ecd4-dca2-40ff-ad7b-1eeaa17d4908","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5597002","total_premium":10.5,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"fec1a2e5-0c3f-4eee-8dae-7555ca18c07f","policy_id":632829,"id":5597002,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"long_term_disability"},{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-18","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":259,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":259,"coverage_end_date":"2022-10-18","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<Case> list_UpdatedCases = [
			SELECT Id, Status, Special_Instructions__c, Termination_Date__c, MF_Coverage_End_Date__c, OwnerId, Integration_Id__c, Integration_Key__c
			FROM Case
			WHERE Carrier__r.Key__c = 'principal_co'
		];

		System.assertEquals(Date.newInstance(2022, 7, 14), list_UpdatedCases[0].Termination_Date__c, 'Case termination date is not updated.');
		System.assertEquals(Date.newInstance(2023, 5, 17), list_UpdatedCases[0].MF_Coverage_End_Date__c, 'Case MF Coverage End Date is not updated.');
		System.assertEquals('Test321', list_UpdatedCases[0].Integration_Id__c, 'Case Integration Id is not updated.');
		System.assertEquals('Test321-principal_co', list_UpdatedCases[0].Integration_Key__c, 'Case Integration Key is not updated.');
		System.assert(list_UpdatedCases[0].Special_Instructions__c.contains(Label.HI_Term_Special_Instructions_with_Other), 'Special Instructions is not updated.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Cases record when Termination Date Changed
	 **/
	@isTest
	static void createCasesForTerminationDateChanged() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		Map<String, Case> map_ExistingCases = new Map<String, Case>();
		for (Case objCase : [
			SELECT Id, Status, Selection_Ids__c, Carrier__r.Key__c, Fulfillment_Event_Encrypted_JSON__c
			FROM Case
			WHERE Carrier__r.Key__c = 'principal_co' OR Carrier__r.Key__c = 'beam_dental_ca' OR Carrier__r.Key__c = 'guardian_ma'
		]) {
			objCase.Status = 'Closed';
			map_ExistingCases.put(objCase.Carrier__r.Key__c, objCase);
		}
		update map_ExistingCases.values();

		String strSubType = 'Termination date changed';
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setCompanyId('1370368242490000')
			.setEmployeeId('7330104')
			.setEventSubType(strSubType)
			.setEventInfo(
				'{"state_carriers":[{"url":"https://hippo.gusto.com/national_carriers/48/state_carriers/24","state":"CO","name":"Principal","key":"principal_co","id":73,"forms":[6541282],"byb_automation_authorized":false},{"id":259,"name":"Beam","state":"CA","key":"beam_dental_ca","url":"http://hippo.gusto-dev.com:4001/national_carriers/4/state_carriers/259","byb_automation_authorized":false,"forms":[]},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma","url":"http://hippo.gusto-dev.com:4001/national_carriers/24/state_carriers/237","byb_automation_authorized":true,"forms":[]}],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632828","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":2374,"name":"Principal Life 50,000 - CA","id":632828,"group_number":"1061525","benefit_type":"life"},{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632829","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":4099,"name":"Long Term Disability [Brand Knew]","id":632829,"group_number":"1061525","benefit_type":"long_term_disability"}],"losing_benefits_reason":"' +
					strSubType +
					'","benefits_eligibility_end_date":"2022-07-14","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7330104","middle_initial":"M","last_name":"Test01","id":7330104,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/benefits","benefit_items":[{"uuid":"a00c9526-211c-4baa-a51d-e5aa94f77de7","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5596986","total_premium":4.9,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"5f05200a-325b-4b30-886c-e9588273fa4c","policy_id":632828,"id":5596986,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"life"},{"uuid":"c002ecd4-dca2-40ff-ad7b-1eeaa17d4908","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5597002","total_premium":10.5,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"fec1a2e5-0c3f-4eee-8dae-7555ca18c07f","policy_id":632829,"id":5597002,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"long_term_disability"},{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-18","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":259,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":259,"coverage_end_date":"2022-10-18","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		Case objExistingCase = map_ExistingCases.get('principal_co');
		List<Case> list_NewCreatedCases = [
			SELECT Id, Selection_Ids__c, Fulfillment_Event_Encrypted_JSON__c
			FROM Case
			WHERE Carrier__r.Key__c = 'principal_co' AND Status != 'Closed'
		];
		System.assertNotEquals(objExistingCase.Id, list_NewCreatedCases[0].Id, 'New termination case is not created.');
		System.assertEquals(objExistingCase.Selection_Ids__c, list_NewCreatedCases[0].Selection_Ids__c, 'There is no existing case related to Selection Ids.');

		objHiEvent.Event_Info__c = '{"state_carriers":[{"url":"https://hippo.gusto.com/national_carriers/48/state_carriers/24","state":"CO","name":"Principal","key":"principal_co","id":73,"forms":[6541282],"byb_automation_authorized":false},{"id":259,"name":"Beam","state":"CA","key":"beam_dental_ca","url":"http://hippo.gusto-dev.com:4001/national_carriers/4/state_carriers/259","byb_automation_authorized":false,"forms":[]},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma","url":"http://hippo.gusto-dev.com:4001/national_carriers/24/state_carriers/237","byb_automation_authorized":true,"forms":[]}],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632828","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":2374,"name":"Principal Life 50,000 - CA","id":632828,"group_number":"1061525","benefit_type":"life"},{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632829","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":4099,"name":"Long Term Disability [Brand Knew]","id":632829,"group_number":"1061525","benefit_type":"long_term_disability"}],"losing_benefits_reason":"' +
					strSubType +
					'","benefits_eligibility_end_date":"2022-07-25","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7330104","middle_initial":"M","last_name":"Test01","id":7330104,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/benefits","benefit_items":[{"uuid":"a00c9526-211c-4baa-a51d-e5aa94f77de7","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5596986","total_premium":4.9,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"5f05200a-325b-4b30-886c-e9588273fa4c","policy_id":632828,"id":5596986,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"life"},{"uuid":"c002ecd4-dca2-40ff-ad7b-1eeaa17d4908","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5597002","total_premium":10.5,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"fec1a2e5-0c3f-4eee-8dae-7555ca18c07f","policy_id":632829,"id":5597002,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"long_term_disability"},{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-18","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":259,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":259,"coverage_end_date":"2022-10-18","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}';
		update objHiEvent;

		list_NewCreatedCases = [
			SELECT Id, Selection_Ids__c, Fulfillment_Event_Encrypted_JSON__c
			FROM Case
			WHERE Carrier__r.Key__c = 'principal_co' AND Status != 'Closed'
		];
		Blob blbDecrypted = EncodingUtil.base64Decode(list_NewCreatedCases[0].Fulfillment_Event_Encrypted_JSON__c);
		String strDeCryptedText = EncryptionUtils.getDecryptedText(EncryptionUtils.getEncryptionKey('Master'), blbDecrypted);
		strDeCryptedText = strDeCryptedText.removeStart('"');
		strDeCryptedText = strDeCryptedText.removeEnd('"');	
		HIFulfillmentBotTerminationEventJSON objBOTJson = (HIFulfillmentBotTerminationEventJSON) System.JSON.deserialize(strDeCryptedText, HIFulfillmentBotTerminationEventJSON.class);
		System.assertEquals(objBOTJson.losing_benefits_date, '2022-07-25' ,'Termination date is not updated.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update Existing Cases when Cancel termination
	 **/
	@isTest
	static void updateExistingCasesForCancelTermination() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		String strSubType = 'Cancel termination';
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setCompanyId('1370368242490000')
			.setEmployeeId('7330104')
			.setEventSubType(strSubType)
			.setEventInfo(
				'{"state_carriers":[{"url":"https://hippo.gusto.com/national_carriers/48/state_carriers/24","state":"CO","name":"Principal","key":"principal_co","id":73,"forms":[6541282],"byb_automation_authorized":false},{"id":259,"name":"Beam","state":"CA","key":"beam_dental_ca","url":"http://hippo.gusto-dev.com:4001/national_carriers/4/state_carriers/259","byb_automation_authorized":false,"forms":[]},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma","url":"http://hippo.gusto-dev.com:4001/national_carriers/24/state_carriers/237","byb_automation_authorized":true,"forms":[]}],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632828","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":2374,"name":"Principal Life 50,000 - CA","id":632828,"group_number":"1061525","benefit_type":"life"},{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632829","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":4099,"name":"Long Term Disability [Brand Knew]","id":632829,"group_number":"1061525","benefit_type":"long_term_disability"}],"losing_benefits_reason":"' +
					strSubType +
					'","benefits_eligibility_end_date":"2022-07-14","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7330104","middle_initial":"M","last_name":"Test01","id":7330104,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/benefits","benefit_items":[{"uuid":"a00c9526-211c-4baa-a51d-e5aa94f77de7","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5596986","total_premium":4.9,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"5f05200a-325b-4b30-886c-e9588273fa4c","policy_id":632828,"id":5596986,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"life"},{"uuid":"c002ecd4-dca2-40ff-ad7b-1eeaa17d4908","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5597002","total_premium":10.5,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"fec1a2e5-0c3f-4eee-8dae-7555ca18c07f","policy_id":632829,"id":5597002,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"long_term_disability"},{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-18","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":259,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":259,"coverage_end_date":"2022-10-18","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<Case> list_UpdatedCases = [
			SELECT Id, Status, Special_Instructions__c, Termination_Date__c, MF_Coverage_End_Date__c, OwnerId, Integration_Id__c, Integration_Key__c
			FROM Case
			WHERE Carrier__r.Key__c = 'beam_dental_ca'
		];
		System.assertEquals(null, list_UpdatedCases[0].Termination_Date__c, 'Case termination date is not updated.');
		System.assertEquals(null, list_UpdatedCases[0].MF_Coverage_End_Date__c, 'Case MF Coverage End Date is not updated.');
		System.assertEquals('Test321', list_UpdatedCases[0].Integration_Id__c, 'Case Integration Id is not updated.');
		System.assertEquals('Test321-beam_dental_ca', list_UpdatedCases[0].Integration_Key__c, 'Case Integration Key is not updated.');
		System.assertEquals(HIFulfillmentEventTermination.strMemberFulfillmentQueue, list_UpdatedCases[0].OwnerId, 'Owner should be Member Fulfillment Queue');
		System.assert(list_UpdatedCases[0].Special_Instructions__c.contains(Label.HI_Term_Cancel_Terminations_with_Other), 'Special Instructions is not updated.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update Existing Cases when Cancel termination - Negative Case
	 **/
	@isTest
	static void cancelTerminationEventNegativeCase() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		String strSubType = 'Cancel termination';
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setCompanyId('1370368242490000')
			.setEmployeeId('7230103')
			.setEventSubType(strSubType)
			.setEventInfo(
				'{"state_carriers":[{"url":"https://hippo.gusto.com/national_carriers/48/state_carriers/24","state":"CO","name":"Principal","key":"principal_co","id":73,"forms":[6541282],"byb_automation_authorized":false},{"id":259,"name":"Beam","state":"CA","key":"beam_dental_ca","url":"http://hippo.gusto-dev.com:4001/national_carriers/4/state_carriers/259","byb_automation_authorized":false,"forms":[]},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma","url":"http://hippo.gusto-dev.com:4001/national_carriers/24/state_carriers/237","byb_automation_authorized":true,"forms":[]}],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632828","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":2374,"name":"Principal Life 50,000 - CA","id":632828,"group_number":"1061525","benefit_type":"life"},{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632829","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":4099,"name":"Long Term Disability [Brand Knew]","id":632829,"group_number":"1061525","benefit_type":"long_term_disability"}],"losing_benefits_reason":"' +
					strSubType +
					'","benefits_eligibility_end_date":"2022-07-14","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7230103,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7230103","middle_initial":"M","last_name":"Test01","id":7230103,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7230103","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7230103/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7230103,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7230103,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7230103,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7230103/benefits","benefit_items":[{"uuid":"a00c9526-211c-4baa-a51d-e5aa94f77de7","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7230103/selections/5596986","total_premium":4.9,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"5f05200a-325b-4b30-886c-e9588273fa4c","policy_id":632828,"id":5596986,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7230103,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"life"},{"uuid":"c002ecd4-dca2-40ff-ad7b-1eeaa17d4908","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7230103/selections/5597002","total_premium":10.5,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"fec1a2e5-0c3f-4eee-8dae-7555ca18c07f","policy_id":632829,"id":5597002,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7230103,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"long_term_disability"},{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-18","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":259,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":259,"coverage_end_date":"2022-10-18","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<Case> list_UpdatedCases = [
			SELECT Id, Status, Special_Instructions__c, Termination_Date__c, MF_Coverage_End_Date__c, OwnerId, Integration_Id__c, Integration_Key__c
			FROM Case
			WHERE Carrier__r.Key__c = 'beam_dental_ca'
		];
		System.assertNotEquals(null, list_UpdatedCases[0].Termination_Date__c, 'Case termination date is updated.');
		System.assertNotEquals(null, list_UpdatedCases[0].MF_Coverage_End_Date__c, 'Case MF Coverage End Date is updated.');
		System.assertNotEquals('Test321', list_UpdatedCases[0].Integration_Id__c, 'Case Integration Id is updated.');
		System.assertNotEquals('Test321-beam_dental_ca', list_UpdatedCases[0].Integration_Key__c, 'Case Integration Key is updated.');
		System.assert(String.isBlank(list_UpdatedCases[0].Special_Instructions__c), 'Special Instructions is updated.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update Closed Cases for Cancel termination
	 **/
	@isTest
	static void updateClosedCasesForCancelTermination() {
		Utils.skipTrigger(true);
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		Map<String, Case> map_ExistingCases = new Map<String, Case>();
		for (Case objCase : [
			SELECT Id, Status, Selection_Ids__c, Carrier__r.Key__c
			FROM Case
			WHERE Carrier__r.Key__c = 'principal_co' OR Carrier__r.Key__c = 'beam_dental_ca' OR Carrier__r.Key__c = 'guardian_ma'
		]) {
			objCase.Status = 'Closed';
			map_ExistingCases.put(objCase.Carrier__r.Key__c, objCase);
		}
		update map_ExistingCases.values();

		String strSubType = 'Cancel termination';
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_losing_eligibility')
			.setCompanyId('1370368242490000')
			.setEmployeeId('7330104')
			.setEventSubType(strSubType)
			.setEventInfo(
				'{"state_carriers":[{"url":"https://hippo.gusto.com/national_carriers/48/state_carriers/24","state":"CO","name":"Principal","key":"principal_co","id":73,"forms":[6541282],"byb_automation_authorized":false},{"id":259,"name":"Beam","state":"CA","key":"beam_dental_ca","url":"http://hippo.gusto-dev.com:4001/national_carriers/4/state_carriers/259","byb_automation_authorized":false,"forms":[]},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma","url":"http://hippo.gusto-dev.com:4001/national_carriers/24/state_carriers/237","byb_automation_authorized":true,"forms":[]}],"sent_at":"2022-07-11T15:27:00.234-07:00","policies":[{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632828","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":2374,"name":"Principal Life 50,000 - CA","id":632828,"group_number":"1061525","benefit_type":"life"},{"visible":true,"url":"https://hippo.gusto.com/companies/1370368242490000/policies/632829","termination_policy":"last_day_of_employment","state_carrier_id":73,"policy_number":null,"plan_id":4099,"name":"Long Term Disability [Brand Knew]","id":632829,"group_number":"1061525","benefit_type":"long_term_disability"}],"losing_benefits_reason":"' +
					strSubType +
					'","benefits_eligibility_end_date":"2022-07-14","forms":[],"employee":{"work_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04 17:43:32 -0700","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04 17:43:32 -0700","county_name":"Maricopa","country":"USA","city":"Tempe"},"status":"Active","ssn":531027157,"payroll_type":"Exempt","panda_url":"https://app.gusto.com/panda/companies/1370368242490000/employees/7330104","middle_initial":"M","last_name":"Test01","id":7330104,"home_address":{"zip":"85027","work_address":false,"updated_at":"2022-06-08 07:07:56 -0700","street_2":"Apt 1023","street_1":"18811 N 19th Ave","state":"AZ","phone":null,"inactive":false,"id":null,"fax":null,"created_at":"2022-06-08 07:07:56 -0700","county_name":"Maricopa","country":"USA","city":"Phoenix"},"hired_at":"2022-04-08","hippo_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104","gender":null,"first_name":"Alex","employment_status":"full_time","email":"testalex01@gmail.com","company_id":1370368242490000,"birthday":"1986-04-22"},"dependents_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/dependents","dependents":[],"company":{"work_states":["AZ"],"sic_code":null,"salesforce_account_id":null,"panda_url":"https://app.gusto.com/panda/companies/1370368242490000","number_of_ineligible_ees":6,"number_of_eligible_ees":1,"name":"Simply Smashing LLC","mailing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"is_suspended":false,"id":1370368242490000,"hippo_url":"https://hippo.gusto.com/companies/1370368242490000","has_federal_cobra":false,"filing_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"},"email":"brian@experttaxaz.com","benefits_address":{"zip":"85282","work_address":true,"updated_at":"2022-04-04T17:43:32-07:00","street_2":"suite 120","street_1":"1845 E Broadway Rd","state":"AZ","phone":"6029091996","inactive":false,"id":7330104,"fax":null,"employee_count":11,"created_at":"2022-04-04T17:43:32-07:00","county_name":"Maricopa","country":"USA","city":"Tempe"}},"commuter_employee_benefit":null,"commuter_benefit":null,"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","benefits_url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/benefits","benefit_items":[{"uuid":"a00c9526-211c-4baa-a51d-e5aa94f77de7","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5596986","total_premium":4.9,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"5f05200a-325b-4b30-886c-e9588273fa4c","policy_id":632828,"id":5596986,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"life"},{"uuid":"c002ecd4-dca2-40ff-ad7b-1eeaa17d4908","url":"https://hippo.gusto.com/companies/1370368242490000/employees/7330104/selections/5597002","total_premium":10.5,"state_carrier_id":73,"start_date":"2023-02-01","processed":null,"policy_uuid":"fec1a2e5-0c3f-4eee-8dae-7555ca18c07f","policy_id":632829,"id":5597002,"enrollment_id":2381011,"end_date":"2024-01-31","employee_id":7330104,"coverage_end_date":"2023-05-17","dependent_ids":[],"benefit_type":"long_term_disability"},{"id":4994358,"policy_id":498434,"policy_uuid":"","benefit_type":"medical","subscriber_id":"XXX-XX-1106","processing_status":"processed","coverage_end_date":"2022-10-18","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":259,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994358","uuid":"a3a79762-70b1-4a40-b1bb-f80392cd7a4d","total_premium":741.06},{"uuid":"9d8f38a6-e033-4995-a277-9cc8366355d7","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924849566/employees/7757869437611775/selections/5621553","total_premium":395.65,"state_carrier_id":259,"coverage_end_date":"2022-10-18","start_date":"2023-02-01","processed":null,"policy_uuid":"03c4b27a-a5b7-497c-90c4-7994e5c3286a","policy_id":628124,"id":5621553,"enrollment_id":2415237,"end_date":"2024-01-31","employee_id":7757869431795591,"dependent_ids":[],"benefit_type":"medical"},{"id":4994365,"policy_id":488257,"policy_uuid":"7f087a4a-e441-4159-996d-49a7b8c4e974","benefit_type":"dental","subscriber_id":"XXX-XX-6878","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994365","uuid":"da70ea8e-3e58-46b7-ab35-493c8ad13d69","total_premium":52.75},{"id":4994369,"policy_id":488258,"policy_uuid":"52e97577-7921-444f-a5e0-4fba83e57ada","benefit_type":"vision","subscriber_id":"XXX-XX-1672","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994369","uuid":"5ab6c540-5ef2-4712-8a20-bed568c9ddd7","total_premium":11.18},{"id":4994382,"policy_id":445608,"policy_uuid":"8492e7ad-acd1-4794-b59a-9e3745d55c0f","benefit_type":"long_term_disability","subscriber_id":"XXX-XX-1727","processing_status":"processed","coverage_end_date":"2022-10-19","start_date":"2022-10-01","end_date":"2023-03-31","enrollment_id":2139604,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":237,"url":"http://hippo.gusto-dev.com:4001/companies/7757616924088320/employees/7757869431795591/selections/4994382","uuid":"7fd36f2b-17e6-46fe-839f-119c1862434d","total_premium":2.4}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<Case> list_UpdatedCases = [
			SELECT Id, Status, Special_Instructions__c, OwnerId, Integration_Id__c, Integration_Key__c
			FROM Case
			WHERE Carrier__r.Key__c = 'beam_dental_ca'
		];
		System.assertEquals('New', list_UpdatedCases[0].Status, 'Case Status is not updated.');
		System.assertEquals('Test321', list_UpdatedCases[0].Integration_Id__c, 'Case Integration Id is not updated.');
		System.assertEquals('Test321-beam_dental_ca', list_UpdatedCases[0].Integration_Key__c, 'Case Integration Key is not updated.');
		System.assert(list_UpdatedCases[0].Special_Instructions__c.contains(Label.HI_Term_Cancel_Terminations_with_Submitted), 'Special Instructions is not updated.');
	}
}