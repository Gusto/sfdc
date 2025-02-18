/**
 * @name         HITaDaEnrollmentEventTest
 * @author
 * @date         12th Jan 2021
 * @description  Process TADA Enrollment Events and update/create relevant cases.
 * @Classes      HITaDaEnrollmentEvent
 * @revisions    Date ------------ Name ------------ Comments
 */
@isTest
public class HITaDaSelectionCancelledEventTest {  
	public static String strTADASelectionCancelledJSON = '{"created_at":"2021-01-12T14:01:15-08:00","selection":{"uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9","benefit_type":"fsa","start_date":"2019-03-01","provider_key": "alegeus"},"employee":{"id":7757869431976033,"first_name":"Gerard","last_name":"Hintz","middle_initial":"","ssn":"123456789","email":"rubye@hahn.biz","birthday":"1982-01-12","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431976033","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431976033","benefits_eligibility_date":"2018-01-02","lost_coverage_date":"2018-01-02"},"company":{"id":7757616923645172,"name":"Homenick Inc","email":"simonne@purdy.org","phone":"2578265084","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923645172","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172"}}';
	public static String strTADASelectionCancelledJSON1 = '{"created_at":"2021-01-12T14:01:15-08:00","selection":{"uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9","benefit_type":"fsa","start_date":"2019-03-01","provider_key": "alegeus"},"employee":{"id":7757869431976033,"first_name":"Gerard","last_name":"Hintz","middle_initial":"","ssn":"123456789","email":"rubye@hahn.biz","birthday":"1982-01-12","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431976033","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431976033","benefits_eligibility_date":"2018-01-02","lost_coverage_date":null},"company":{"id":7757616923645172,"name":"Homenick Inc","email":"simonne@purdy.org","phone":"2578265084","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923645172","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172"}}';
    public static String strTADAEnrollmentJSON = '{"error_message":null,"enrollment":{"id":940283,"employee_id":7757869431976033,"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869431976033/enrollments/940223"},"recent_qles":[],"enrollment_source":{"type":"open_enrollment_start"},"employee":{"id":7757869431976033,"first_name":"Dylan","last_name":"Torp","middle_initial":"Z","ssn":"123456789","email":"illa_okuneva@berniertromp.io","gender":"male","home_address":{"id":801052781517681,"fax":"2686707838","zip":"21763-1905","city":"Port Trumanburgh","phone":"2797913010","state":"SC","country":"Northern Mariana Islands","inactive":false,"street_1":"1758 Harber Vista","street_2":"Suite 310","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"New Luther","work_address":null},"annual_salary":"175000.0","birthday":"1988-06-22","hired_at":"2018-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431976033","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431976033","benefits_eligibility_date":"2018-06-25","employment_status":"full_time"},"company":{"id":7757616923645172,"name":"Hamill Group","email":"victor@kihn.name","phone":"7935208442","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923645172","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172"},"dependents":[{"id":"fd73d3b3-e236-4097-ad7b-99bf13638fd0","first_name":"Willy","last_name":"Hermiston","ssn":"123456789","birthday":"1995-01-22","gender":"male","dependent_type":"spouse","url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/dependents/143617"},{"id":"3165e6f9-5b58-4318-a75c-8d08874c619b","first_name":"Rusty","last_name":"Sipes","ssn":"123456789","birthday":"1943-02-04","gender":"female","dependent_type":"child","url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/dependents/143618"}],"benefits_url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/benefits","enrollments_url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/enrollments","tada":{"dca":{"provider_key": "alegeus","benefit_items":{"current":{"id":2147288,"policy_id":268104,"policy_uuid":"5febfd96-b32f-4fd6-8f71-3e79220466fe","benefit_type":"dca","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869431976033,"employee_alegeus_id":524863288,"dependent_ids":[143618],"url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/selections/2147288","uuid":"45153311-4f2a-44c7-ad48-491c381f31b4","estimated_start_date":"2021-01-01","ops_owner":"member_fulfillment"},"overlapping":[{"id":1344866,"policy_id":268104,"policy_uuid":"5febfd96-b32f-4fd6-8f71-3e79220466fe","benefit_type":"dca","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869431976033,"employee_alegeus_id":524863288,"dependent_ids":[143618],"url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/subscriptions/1344866","uuid":null}],"previous":[{"id":833692,"policy_id":157557,"policy_uuid":"160bb4ba-7cb3-4d91-a14d-1292673cf2ac","benefit_type":"dca","subscriber_id":"47878419","start_date":"2020-01-01","end_date":"2020-12-31","processing_status":"processed","enrollment_id":614328,"employee_id":7757869431976033,"employee_alegeus_id":524863288,"dependent_ids":[143618],"url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/subscriptions/833692","uuid":null}]},"policies":[{"id":268104,"name":"Dependent Care FSA","benefit_type":"dca","company_alegeus_id":400273005,"visible":true,"termination_policy":"last_day_of_employment","url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/policies/268104","uuid":"5febfd96-b32f-4fd6-8f71-3e79220466fe"}]},"fsa":{"provider_key": "alegeus","benefit_items":{"current":{"id":2147269,"policy_id":268103,"policy_uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9","benefit_type":"fsa","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869431976033,"employee_alegeus_id":524863288,"dependent_ids":[143618,143617],"url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/selections/2147269","uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9","estimated_start_date":"2021-01-01","ops_owner":"member_fulfillment"},"overlapping":[{"id":1344853,"policy_id":268103,"policy_uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9","benefit_type":"fsa","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869431976033,"employee_alegeus_id":524863288,"dependent_ids":[143618,143617],"url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/subscriptions/1344853","uuid":null}],"previous":[{"id":924742,"policy_id":154353,"policy_uuid":"edadac0f-9668-4a7f-bb67-5aa9e8a601aa","benefit_type":"fsa","subscriber_id":"59733973","start_date":"2020-01-01","end_date":"2020-12-31","processing_status":"processed","enrollment_id":607889,"employee_id":7757869431976033,"employee_alegeus_id":524863288,"dependent_ids":[143618,143617],"url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/employees/7757869431976033/subscriptions/924742","uuid":null}]},"policies":[{"id":268103,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":400273005,"visible":true,"termination_policy":"last_day_of_employment","url":"http://hippo.gusto-dev.com:4001/companies/7757616923645172/policies/268103","uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9"}]}}}';

	@testSetup
	static void testSetup() {
		Blob key = EncryptionUtils.generateKey('Master');
		AccountTriggerHelper.SkipTrigger = true;
		ContactTriggerHelper.SkipTrigger = true;

		List<Carrier__c> list_Carrier = new List<Carrier__c>();

		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('alegeus').setKey('alegeus').setPartnerType('TAdA').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('elevate').setKey('elevate').setPartnerType('TAdA').build());

		insert list_Carrier;

		List<Account> list_Accounts = new List<Account>();

		Account objAcc1 = new Account(ZP_Company_ID__c = '7757616923639580', Name = 'Freshco');
		list_Accounts.add(objAcc1);

		Account objAcc2 = new Account(ZP_Company_ID__c = '7757616923645172', Name = 'Test Account');
		list_Accounts.add(objAcc2);

		insert list_Accounts;

		Contact conObj = new Contact(
			AccountId = objAcc2.Id,
			FirstName = 'Test',
			LastName = 'Account',
			email = 'testaccount@gmail.com',
			Employee_Id__c = '7757869431976033'
		);
		insert conObj;
	}

	static void createSelectionSubmittedEvent() {
		HIFulfillmentEventTriggerHelper.queue = true;

		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.Id__c = '10001';
		objSubmit.Company_Id__c = '7757616923645172';
		objSubmit.Employee_Id__c = '7757869431976033';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'tada_enrollment_ready_for_processing';
		objSubmit.Event_Info__c = strTADAEnrollmentJSON;
		insert objSubmit;
	}

	static testMethod void testTADAEnrollment() {
		createSelectionSubmittedEvent();

		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.Id__c = '10001';
		objSubmit.Company_Id__c = '7757616923645172';
		objSubmit.Employee_Id__c = '7757869431976033';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'tada_selection_cancelled';
		objSubmit.Event_Info__c = strTADASelectionCancelledJSON;
		insert objSubmit;
		Test.stopTest();

		List<Case> list_Case = [
			SELECT Id, RecordType.Name
			FROM Case
			WHERE Account.ZP_Company_ID__c = '7757616923645172' AND RecordType.Name = 'MF NHE'
		];

        System.assertEquals(list_Case.size(), 1);
	}

	static testMethod void testTADAEnrollment1() {
		createSelectionSubmittedEvent();

		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.Id__c = '10002';
		objSubmit.Company_Id__c = '7757616923645172';
		objSubmit.Employee_Id__c = '7757869431976033';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'tada_selection_cancelled';
		objSubmit.Event_Info__c = strTADASelectionCancelledJSON1;
		insert objSubmit;

		List<Case> list_Case = [
			SELECT
				id,
				OwnerId,
				Status,
				Benefit_Types__c,
				Selection_UUIds__c,
				Medical_UUID__c,
				Dental_UUID__c,
				Life_UUID__c,
				Vision_UUID__c,
				Long_Term_Disability_UUID__c,
				Short_Term_Disability_UUID__c
			FROM Case
			WHERE Account.ZP_Company_ID__c = '7757616923645172'
		];

		HI_Fulfillment_Event__c objSubmit1 = new HI_Fulfillment_Event__c();
		objSubmit1.Id__c = '10003';
		objSubmit1.Company_Id__c = '7757616923645172';
		objSubmit1.Employee_Id__c = '7757869431976033';
		objSubmit1.Processing_State__c = 'Queued';
		objSubmit1.Event_Type__c = 'tada_selection_cancelled';
		objSubmit1.Event_Info__c = strTADASelectionCancelledJSON1;
		insert objSubmit1;
		Test.stopTest();

		List<Case> list_Case1 = [
			SELECT Id, RecordType.Name
			FROM Case
			WHERE Account.ZP_Company_ID__c = '7757616923645172' AND RecordType.Name = 'MF NHE'
		];

        System.assertEquals(list_Case1.size(), 1);
	}

	static @IsTest
	void testTadaCancellationWithHSA() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;

		CaseTriggerHelper.skipTrigger = true;

		String strTaDaEnrollmentEventJSON = '{"error_message":null,"enrollment":{"id":1023432,"employee_id":7757869432847385,"url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/enrollments/1023432"},"recent_qles":[],"enrollment_source":{"type":"open_enrollment_start"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"},"dependents":[],"benefits_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/benefits","enrollments_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/enrollments","tada":{"hsa":{"provider_key": "alegeus","hsa_selection":{"id":15815,"employee_id":7757869432847385,"hsa_benefit_id":3889,"max_contribution_cents":"360000.0","url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/hsa_subscriptions/selections/15815","uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","effective_date":"2021-01-01","ops_owner":"member_fulfillment"},"hsa_benefit":{"benefit_type":"hsa","id":3889,"name":"Health Savings Account","company_id":7757616923639580,"effective_date":"2021-01-01","expiration_date":"2021-12-31","status":"visible","url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/policies"}}}}';

		HI_Fulfillment_Event__c objHIEvent = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26345',
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_enrollment_ready_for_processing',
			Event_Info__c = strTaDaEnrollmentEventJSON
		);
		insert objHIEvent;

        System.debug('Data Message 3 : '+[SELECT Id, Processing_State__c, Message__c FROM HI_Fulfillment_Event__c WHERE Id__c = '10002-eyrvg26345']);

        System.assert(
            [
                SELECT COUNT()
                FROM HI_Fulfillment_Event__c
                WHERE Id__c = '10002-eyrvg26345' AND Processing_State__c = 'Processed'
            ] == 1
        );
        System.assert([SELECT COUNT() FROM Contact WHERE Account.ZP_Company_Id__c = '7757616923639580'] == 1);
        System.assert([SELECT COUNT() FROM Case WHERE Account.ZP_Company_Id__c = '7757616923639580'] == 1);

		//Cancellation Event
		String strTaDaCancellationEventJSON = '{"selection":{"uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","start_date":"2021-01-11","benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';

		HI_Fulfillment_Event__c objHIEventCancel = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26346',
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel;

        System.assert(
            [
                SELECT COUNT()
                FROM Case
                WHERE Account.ZP_Company_Id__c = '7757616923639580' AND Status = 'Cancelled'
            ] == 1
        );
		Test.stopTest();
	}

	static @IsTest
	void testTadaCancellationWithoutEnrollingEvent() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;

		CaseTriggerHelper.skipTrigger = true;

		//Cancellation Event
		String strTaDaCancellationEventJSON = '{"selection":{"uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","start_date":"2021-01-11","benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';

		HI_Fulfillment_Event__c objHIEventCancel = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26346',
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel;

		System.assert(
			[
				SELECT COUNT()
				FROM Case
				WHERE Account.ZP_Company_Id__c = '7757616923639580' AND RecordType.Name = 'MF Cancellation'
			] == 1
		);

		String strTaDaCancellationEventJSONDup = '{"selection":{"uuid":"b5ec060-2b40-4591-bc4a-7123906abebe","start_date":"2021-01-11","benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';
		HI_Fulfillment_Event__c objHIEventCancelDup = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26347',
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSONDup
		);
		insert objHIEventCancelDup;

		System.assert([SELECT COUNT() FROM Case WHERE HSA_UUID__c = 'b5ec060-2b40-4591-bc4a-7123906abebe'] == 1);
		Test.stopTest();
	}

	static @IsTest
	void testTadaCancellationInvalidJSON() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		//Cancellation Event
		String strTaDaCancellationEventJSON = 'selection:{"uuid":123,"start_date":2021,"benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":"7757869432847385","first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';

		HI_Fulfillment_Event__c objHIEventCancel = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26346',
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel;

		System.assert([SELECT COUNT() FROM HI_Fulfillment_Event__c WHERE Processing_State__c = 'Error'] == 1);
		Test.stopTest();
	}

	static @isTest
	void testTadaCancellationNOSelection() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;

		//Cancellation Event
		String strTaDaCancellationEventJSON = '{"selection":null,"start_date":"2021-01-11","benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';

		HI_Fulfillment_Event__c objHIEventCancel = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26346',
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel;
		Test.stopTest();

		System.assert(
			[
				SELECT COUNT()
				FROM HI_Fulfillment_Event__c
				WHERE Processing_State__c = 'Error' AND Id__c = '10002-eyrvg26346'
			] == 1
		);
	}

	static @isTest
	void testTadaCancellationNOCompanyId() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;

		//Cancellation Event
		String strTaDaCancellationEventJSON = '{"selection":{"uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","start_date":"2021-01-11","benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';
		HI_Fulfillment_Event__c objHIEventCancel = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26346',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel;
		Test.stopTest();

		System.assert(
			[
				SELECT COUNT()
				FROM HI_Fulfillment_Event__c
				WHERE Processing_State__c = 'Error' AND Id__c = '10002-eyrvg26346'
			] == 1
		);
	}

	static @isTest
	void testTadaCancellationMissingUUID() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;

		//Cancellation Event
		String strTaDaCancellationEventJSON = '{"selection":{"start_date":"2021-01-11","benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';

		HI_Fulfillment_Event__c objHIEventCancel = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26346',
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel;
		Test.stopTest();

		System.assert(
			[
				SELECT COUNT()
				FROM HI_Fulfillment_Event__c
				WHERE Processing_State__c = 'Error' AND Id__c = '10002-eyrvg26346'
			] == 1
		);
	}

	static @isTest
	void testTadaCancellationMissingEventId() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;

		//Cancellation Event
		String strTaDaCancellationEventJSON = '{"selection":{"uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","start_date":"2021-01-11","benefit_type":"hsa","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';
		HI_Fulfillment_Event__c objHIEventCancel = new HI_Fulfillment_Event__c(
			Company_Id__c = '7757616923639580',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel;
		Test.stopTest();

		System.assert(
			[
				SELECT COUNT()
				FROM HI_Fulfillment_Event__c
				WHERE Processing_State__c = 'Error' AND Employee_Id__c = '7757869432847385'
			] == 1
		);
	}

	/**
     * @author      Deepika Saini
     * @description This Method is used for alegeus.
     * @param       null
     * @return      null
	 **/
	@isTest
	static void testTadaSelectionProviderKey() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		String strTaDaCancellationEventJSON = '{"selection":{"uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","benefit_type": "fsa", "start_date": "2019-03-01","provider_key": "alegeus"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923645172,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';
		HI_Fulfillment_Event__c objHIEventCancel1 = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26347',
			Company_Id__c = '7757616923645172',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel1;
		Test.stopTest();
		System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Account.ZP_Company_Id__c = '7757616923645172' ], 'Alegeus case need to be created');
	}

	/**
     * @author      Deepika Saini
     * @description This Method is used for elevate.
     * @param       null
     * @return      null
	 **/
	@isTest
	static void testTadaSelectionProviderKeyElevate() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		String strTaDaCancellationEventJSON = '{"selection":{"uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","benefit_type": "fsa", "start_date": "2019-03-01","provider_key": "elevate"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923645172,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';
		HI_Fulfillment_Event__c objHIEventCancel2 = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26347',
			Company_Id__c = '7757616923645172',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel2;
		Test.stopTest();
		System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Account.ZP_Company_Id__c = '7757616923645172' ], 'elevate case need to be created');
	}

	/**
     * @author      Deepika Saini
     * @description This Method used for check Provider key is missing
     * @param       null
     * @return      null
	 **/
	@isTest
	static void testTadaSelectionMissingProviderKey() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		String strTaDaCancellationEventJSON = '{"selection":{"uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","benefit_type": "fsa", "start_date": "2019-03-01"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923645172,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"}}';
		HI_Fulfillment_Event__c objHIEventCancel2 = new HI_Fulfillment_Event__c(
			Id__c = '10002-eyrvg26347',
			Company_Id__c = '7757616923645172',
			Employee_Id__c = '7757869432847385',
			Processing_State__c = 'Queued',
			Event_Type__c = 'tada_selection_cancelled',
			Event_Info__c = strTaDaCancellationEventJSON
		);
		insert objHIEventCancel2;
		Test.stopTest();

		System.assertEquals(
			HIEnrollmentEventUtility.PROVIDER_KEY_MISSING, 
			[SELECT Message__c FROM HI_Fulfillment_Event__c WHERE Processing_State__c = 'Error' AND Employee_Id__c = '7757869432847385' LIMIT 1].Message__c, 
			'Provider key should be there'
		);
	}
}