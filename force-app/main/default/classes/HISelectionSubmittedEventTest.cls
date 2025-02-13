/**
 * @name         HISelectionSubmittedEventTest
 * @author
 * @date         5th Jan 2021
 * @description  Process Selection Submitted Events and update/create relevant cases.
 * @Classes      HISelectionSubmittedEvent , HIEnrollmentEventUtility
 * @revisions    Date ------------ Name ------------ Comments
 */
@isTest
private class HISelectionSubmittedEventTest {
	@testSetup
	static void testSetup() {
		Blob key = EncryptionUtils.generateKey('Master');

		Account accObj1 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyId('7757616923583061').setName('Test Account1').build();
		insert accObj1;

		Account accObj2 = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyId('7757616923639614').setName('Test Account2').build();
		insert accObj2;

		List<Contact> list_Contacts = new List<Contact>{
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(accObj1.Id)
				.setFirstName('Test')
				.setLastName('Contact1')
				.setEmail('testContact1@gmail.com')
				.setEmployeeId('7757869434243585')
				.build(),
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(accObj2.Id)
				.setFirstName('Test')
				.setLastName('Contact2')
				.setEmail('testContact2@gmail.com')
				.setEmployeeId('7757869434243585')
				.build()
		};
		insert list_Contacts;

		List<Carrier__c> list_Carriers = new List<Carrier__c>{
			new TestDataFactory.CarrierBuilder().setName('UnitedHealthcare').setId('246').setKey('united_healthcare_ma').setState('MA').build(),
			new TestDataFactory.CarrierBuilder().setName('Blue Shield of California').setId('22').setKey('guardian_ca').setState('CA').build(),
			new TestDataFactory.CarrierBuilder().setName('Guardian').setId('2').setKey('blue_shield_ca').setState('CA').build()
		};
		insert list_Carriers;
	}

	@isTest
	static void testHISelectionsSubmitted() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;

		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.Id__c = '10001';
		objSubmit.Company_Id__c = '7757616923583061';
		objSubmit.Employee_Id__c = '7757869434243585';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'selections_submitted';
		objSubmit.Event_Info__c = '{"created_at":"2020-12-23T11:40:09-08:00","error_message":null,"selections":[{"uuid":"81e3c23c-45b1-4690-a549-4337cf8efb76","url":"http://hippo.gusto-dev.com:4001/companies/7757616923583061/employees/7757869434243585/selections/2143100","status":"enrolling","enrollment_information":{"policy_id":"c5dec856-ffdb-4d3d-bd32-aa7b21ff47d9","dependent_ids":[],"state_carrier_id":246},"subscriber_id":null,"start_date":"2020-11-01","end_date":"2021-07-31","estimated_total_premium":941.98,"estimated_employee_premium":941.98,"estimated_dependents_premium":0,"ops_owner":"member_fulfillment"},{"uuid":"1a46799b-c2d5-4e01-98ac-1583290752c9","url":"http://hippo.gusto-dev.com:4001/companies/7757616923583061/employees/7757869434243585/selections/2143102","status":"enrolling","enrollment_information":{"policy_id":"affefcf0-3f5b-4d09-a047-f6e926db2c1a","dependent_ids":[],"state_carrier_id":246},"subscriber_id":null,"start_date":"2020-11-01","end_date":"2021-07-31","estimated_total_premium":29.99,"estimated_employee_premium":29.99,"estimated_dependents_premium":0,"ops_owner":"member_fulfillment"},{"uuid":"f7d56f37-b005-4c3a-a7df-91bc8b1a6ed3","url":"http://hippo.gusto-dev.com:4001/companies/7757616923583061/employees/7757869434243585/selections/2143104","status":"enrolling","enrollment_information":{"policy_id":"6a1e3b9a-b7df-4132-9a7d-c0735b67f39f","dependent_ids":[],"state_carrier_id":246},"subscriber_id":null,"start_date":"2020-11-01","end_date":"2021-07-31","estimated_total_premium":5.16,"estimated_employee_premium":5.16,"estimated_dependents_premium":0,"ops_owner":"member_fulfillment"},{"uuid":"85c2ada0-f288-4210-95db-c7589845e49f","url":"http://hippo.gusto-dev.com:4001/companies/7757616923583061/employees/7757869434243585/selections/2143110","status":"enrolling","enrollment_information":{"policy_id":"6a1b5d82-dd04-40d0-a0e6-dc5353f4f2c4","dependent_ids":[],"state_carrier_id":237},"subscriber_id":null,"start_date":"2020-11-01","end_date":"2021-07-31","estimated_total_premium":8.5,"estimated_employee_premium":8.5,"estimated_dependents_premium":0,"ops_owner":"member_fulfillment"},{"uuid":"5f3a20e1-64fe-484d-b470-4224b6726d97","url":"http://hippo.gusto-dev.com:4001/companies/7757616923583061/employees/7757869434243585/selections/2143111","status":"enrolling","enrollment_information":{"policy_id":"bda42c8b-294a-41da-9200-cc91a3a99cc6","dependent_ids":[],"state_carrier_id":237},"subscriber_id":null,"start_date":"2020-11-01","end_date":"2021-07-31","estimated_total_premium":11.4,"estimated_employee_premium":11.4,"estimated_dependents_premium":0,"ops_owner":"member_fulfillment"},{"uuid":"957961a4-b4fe-4953-91ac-6ff5c70dfac3","url":"http://hippo.gusto-dev.com:4001/companies/7757616923583061/employees/7757869434243585/selections/2143112","status":"enrolling","enrollment_information":{"policy_id":"9dc55de2-f6d4-442e-b968-99438fd9aece","dependent_ids":[],"state_carrier_id":237},"subscriber_id":null,"start_date":"2020-11-01","end_date":"2021-07-31","estimated_total_premium":52.5,"estimated_employee_premium":52.5,"estimated_dependents_premium":0,"ops_owner":"member_fulfillment"}],"enrollment_source":{"type":"new_hire_event","file_upload_urls":["test1","test2"]},"employee":{"id":7757869434243585,"first_name":"Leonora","last_name":"Pouros","middle_initial":"G ","ssn":"123456789","email":"rosendo@franecki.biz","gender":"male","home_address":{"id":399873689266585,"fax":"5911194602 ","zip":"76715 ","city":"Kuhichaven","phone":"8140650570","state":"MD","country":"Mauritania","inactive":false,"street_1 ":"81244 Vandervort Cliff","street_2 ":"Apt .943 ","created_at ":"2000-01-01","updated_at":"2000-01-01","county_name":"Port Alix ","work_address":null},"annual_salary":"140000.0","birthday":"1992-07-11","hired_at":"2020-11-01","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869434243585","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869434243585","benefits_eligibility_date":"2020-11-01","employment_status":"full_time"},"company":{"id":7757616923583061,"name":"Prosacco LLC","email":"carol_bogisich@gutkowskiwaelchi.net","phone":"4042271534","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923583061","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923583061"},"state_carriers":[{"id":246,"name":"UnitedHealthcare","state":"MA","key":"united_healthcare_ma"},{"id":237,"name":"Guardian","state":"MA","key":"guardian_ma"}],"dependents":[],"policies":[{"id":"c5dec856-ffdb-4d3d-bd32-aa7b21ff47d9","name":"UnitedHealthcare Choice Plus Platinum $0 BRFK 961","benefit_type":"medical","group_number":"28335669","policy_number":"04W7517"},{"id":"affefcf0-3f5b-4d09-a047-f6e926db2c1a","name":"Options PPO 30 (P2632)","benefit_type":"dental","group_number":"95980211","policy_number":null},{"id":"6a1e3b9a-b7df-4132-9a7d-c0735b67f39f","name":"UHC Vision Plan V1010","benefit_type":"vision","group_number":"76808611","policy_number":null},{"id":"6a1b5d82-dd04-40d0-a0e6-dc5353f4f2c4","name":"Guardian EM Life 1F","benefit_type":"life","group_number":"60022418","policy_number":null},{"id":"bda42c8b-294a-41da-9200-cc91a3a99cc6","name":"Guardian EM LTD 1a","benefit_type":"long_term_disability","group_number":"22034929","policy_number":null},{"id":"9dc55de2-f6d4-442e-b968-99438fd9aece","name":"Guardian EM STD 1b - 13 week","benefit_type":"short_term_disability","group_number":"69582697","policy_number":null}],"forms":[{"id":1987501,"form_includes_all_dependents":true,"fully_mapped":true,"missing_values_by_path":["form.signed_at","company.group_number.primary","form.signature","employee.benefits_eligibility_date","employee.benefits_eligibility_date","company.group_number.primary"],"name":"2017 UHC MA Employee Enrollment","signed_at":"2020-11-10T08:09:00.409-08:00","state_carrier_id":246,"url":"http://hippo.gusto-dev.com:4001/attachments/forms/1987501"}],"answers":[]}';
		insert objSubmit;
		Test.stopTest();

		//Result: Case should be created related to Company Id.
		List<Case> list_Case = [SELECT Id FROM Case WHERE Account_Company_Id__c = :objSubmit.Company_Id__c];
		System.assert(list_Case.size() > 0);
		objSubmit = [SELECT Id, Event_Sub_Type__c FROM HI_Fulfillment_Event__c WHERE Id = :objSubmit.Id];
		System.assertEquals('new_hire_event', objSubmit.Event_Sub_Type__c, 'Event sub type field value not set correctly.');
	}

	@isTest
	static void testHISelectionsSubmittedQLE() {
		HIFulfillmentEventTriggerHelper.queue = true;

		QLE_Event_Type_Map__c objQLEEType = new QLE_Event_Type_Map__c(Name = 'adoption_of_child', Salesforce_Value__c = 'Birth of a Child/Adoption');
		insert objQLEEType;

		Test.startTest();
		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.id__c = '10001';
		objSubmit.Company_Id__c = '7757616923583061';
		objSubmit.Employee_Id__c = '7757869434243585';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'selections_submitted';
		objSubmit.Event_Info__c = '{"created_at":"2021-01-07T11:24:19-08:00","error_message":null,"selections":[{"uuid":"30afd95d-f03e-4331-98d0-6825b1b3db90","url":"http://hippo.gusto-dev.com:4001/companies/7757616923652950/employees/7757869432365229/selections/2145735","status":"enrolling","enrollment_information":{"policy_id":"20ba9d3c-c3f8-4339-8f01-6ddebeed6c65","dependent_ids":["f4d8f713-f3d4-4f8b-b0a7-d1a42d773b8d","c39c67f7-c72d-4866-80ac-05cc75c4de00","f4558f55-68ce-42e9-9513-926646d51b30"],"state_carrier_id":234},"subscriber_id":null,"start_date":"2020-09-30","end_date":"2021-02-28","estimated_total_premium":1661.38,"estimated_employee_premium":582.94,"estimated_dependents_premium":1078.44,"ops_owner":"member_fulfillment"},{"uuid":"ea64b732-5f73-4a76-858c-0d7b17f8ca8f","url":"http://hippo.gusto-dev.com:4001/companies/7757616923652950/employees/7757869432365229/selections/2145747","status":"enrolling","enrollment_information":{"policy_id":"bc5eee2b-a782-488a-8202-3a28a900ee94","dependent_ids":["f4558f55-68ce-42e9-9513-926646d51b30","f4d8f713-f3d4-4f8b-b0a7-d1a42d773b8d","c39c67f7-c72d-4866-80ac-05cc75c4de00"],"state_carrier_id":234},"subscriber_id":null,"start_date":"2020-09-30","end_date":"2021-02-28","estimated_total_premium":99.91,"estimated_employee_premium":39.96,"estimated_dependents_premium":59.95,"ops_owner":"member_fulfillment"}],"enrollment_source":{"type":"qualifying_life_event","event_date":"2020-09-30","event_type":"adoption_of_child","file_upload_urls":["form.signed_at","form.signature"]},"employee":{"id":7757869434243585,"first_name":"Ardis","last_name":"Zieme","middle_initial":"","ssn":"123456789","email":"almeta_christiansen@hilll.info","gender":"male","home_address":{"id":812543422267822,"fax":"9947501914","zip":"77012","city":"Lake Jonathan","phone":"1325016278","state":"DE","country":"Grenada","inactive":false,"street_1":"12872 Marti Rapids","street_2":"Apt. 669","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Port Rosaville","work_address":null},"annual_salary":"130000.0","birthday":"1949-12-02","hired_at":"2018-10-01","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432365229","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432365229","benefits_eligibility_date":"2018-10-01","employment_status":"full_time"},"company":{"id":7757616923583061,"name":"Veum and Sons","email":"alfonzo@carter.name","phone":"7866735913","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923652950","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923652950"},"state_carriers":[{"id":234,"name":"Blue Cross Blue Shield","state":"MA","key":"bcbs_ma","carrier_enrollment_url":"http://hippo.gusto-dev.com:4001/companies/7757616923652950/employees/7757869432365229/enrollments/945371/bcbs_ma"}],"dependents":[{"id":"c39c67f7-c72d-4866-80ac-05cc75c4de00","first_name":"Houston","last_name":"Green","ssn":"123456789","birthday":"1957-09-09","gender":"female","dependent_type":"child","url":"http://hippo.gusto-dev.com:4001/companies/7757616923652950/employees/7757869432365229/dependents/189484"},{"id":"f4d8f713-f3d4-4f8b-b0a7-d1a42d773b8d","first_name":"Lucio","last_name":"Lemke","ssn":"123456789","birthday":"1994-11-27","gender":"male","dependent_type":"child","url":"http://hippo.gusto-dev.com:4001/companies/7757616923652950/employees/7757869432365229/dependents/221232"},{"id":"f4558f55-68ce-42e9-9513-926646d51b30","first_name":"Lorene","last_name":"Corkery","ssn":"123456789","birthday":"1960-03-20","gender":"male","dependent_type":"partner","url":"http://hippo.gusto-dev.com:4001/companies/7757616923652950/employees/7757869432365229/dependents/221231"}],"policies":[{"id":"20ba9d3c-c3f8-4339-8f01-6ddebeed6c65","name":"HMO Blue NE $1,000 Deductible with Copayment","benefit_type":"medical","group_number":"15384409","policy_number":null},{"id":"bc5eee2b-a782-488a-8202-3a28a900ee94","name":"Dental Blue Pediatric + Adult","benefit_type":"dental","group_number":"77997118","policy_number":null}],"forms":[{"id":1990871,"form_includes_all_dependents":true,"fully_mapped":false,"missing_values_by_path":["form.signed_at","form.signature"],"name":"Blue Cross Blue Shield Enrollment Form","signed_at":"2020-11-10T18:31:00.048-08:00","state_carrier_id":234,"url":"http://hippo.gusto-dev.com:4001/attachments/forms/1990871"}],"answers":[]}';
		insert objSubmit;
		Test.stopTest();

		//Result: Case should be created related to Company Id.
		List<Case> list_Case = [SELECT Id FROM Case WHERE Account_Company_Id__c = :objSubmit.Company_Id__c];
		System.assert(list_Case.size() > 0);
		objSubmit = [SELECT Id, Event_Sub_Type__c FROM HI_Fulfillment_Event__c WHERE Id = :objSubmit.Id];
		System.assertEquals('qualifying_life_event', objSubmit.Event_Sub_Type__c, 'Event sub type field value not set correctly.');
	}

	@isTest
	static void testSelectionSubmittedMultipleEvents() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		List<HI_Fulfillment_Event__c> list_Events = new List<HI_Fulfillment_Event__c>();
		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c(
			id__c = 'kshkhfksehf-sdkgfhskgh-10001',
			Company_Id__c = '77576169235999',
			Employee_Id__c = '775786943424999',
			Processing_State__c = 'Queued',
			Event_Type__c = 'selections_submitted',
			Event_Info__c = '{ "created_at": "2020-12-23T11:40:09-08:00", "error_message": null, "selections": [{ "uuid": "81e3c23c-45b1-4690-a549-4337cf8efb99", "url": "http://hippo.gusto-dev.com:4001/companies/77576169235999/employees/7757869434243585/selections/2143100", "status": "enrolling", "enrollment_information": { "policy_id": "c5dec856-ffdb-4d3d-bd32-aa7b21ff47d9", "dependent_ids": [], "state_carrier_id": 246 }, "subscriber_id": null, "start_date": "2020-11-01", "end_date": "2021-07-31", "estimated_total_premium": 941.98, "estimated_employee_premium": 941.98, "estimated_dependents_premium": 0.0, "ops_owner": "member_fulfillment" }], "enrollment_source": { "type": "new_hire_event" }, "employee": { "id": 775786943424999, "first_name": "Leonora", "last_name": "Pouros", "middle_initial": "G", "ssn": "123459789", "email": "rosendo@franeck99i.biz", "gender": "male", "home_address": { "id": 39987368929985, "fax": "5911194602", "zip": "76715", "city": "Kuhichaven", "phone": "8148750570", "state": "MD", "country": "Mauritania", "inactive": false, "street_1": "81244 Vandervort Cliff", "street_2": "Apt. 943", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "Port Alix", "work_address": null }, "annual_salary": "140000.0", "birthday": "1992-07-11", "hired_at": "2020-11-01", "panda_url": "http://manage.gusto-dev.com:3000/employees/7757869434243585", "hippo_url": "http://hippo.gusto-dev.com:4001/employees/7757869434243585", "benefits_eligibility_date": "2020-11-01", "employment_status": "full_time" }, "company": { "id": 77576169235999, "name": "Prosacco LLC", "email": "carol_bogisich@gutkowskiwaelchi.net", "phone": "4042271534", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923583061", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923583061" }, "state_carriers": [{ "id": 246, "name": "UnitedHealthcare", "state": "MA", "key": "united_healthcare_ma" }, { "id": 237, "name": "Guardian", "state": "MA", "key": "guardian_ma" }], "dependents": [], "policies": [{ "id": "c5dec856-ffdb-4d3d-bd32-aa7b21ff47d9", "name": "UnitedHealthcare Choice Plus Platinum $0 BRFK 961", "benefit_type": "medical", "group_number": "28335669", "policy_number": "04W7517" }], "forms": [{ "id": 1987501, "form_includes_all_dependents": true, "fully_mapped": true, "missing_values_by_path": ["form.signed_at", "company.group_number.primary", "form.signature", "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "company.group_number.primary"], "name": "2017 UHC MA Employee Enrollment", "signed_at": "2020-11-10T08:09:00.409-08:00", "state_carrier_id": 246, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/1987501" }], "answers": [] }'
		);
		list_Events.add(objSubmit);

		HI_Fulfillment_Event__c objEvent2 = new HI_Fulfillment_Event__C(
			id__c = 'kshkhfksehf-sdkgfhskgh-10002',
			Company_Id__c = '77576169235998',
			Employee_Id__c = '775786943424998',
			Processing_State__c = 'Queued',
			Event_Type__c = 'selections_submitted',
			Event_Info__c = '{ "created_at": "2020-12-23T11:40:09-08:00", "error_message": null, "selections": [{ "uuid": "81e3c23c-45b1-4690-a549-4337cf8efc543", "url": "http://hippo.gusto-dev.com:4001/companies/77576169235998/employees/7757869434243585/selections/2143100", "status": "enrolling", "enrollment_information": { "policy_id": "c5dec856-ffdb-4d3d-bd32-aa7b21ff4798", "dependent_ids": [], "state_carrier_id": 246 }, "subscriber_id": null, "start_date": "2020-11-01", "end_date": "2021-07-31", "estimated_total_premium": 941.98, "estimated_employee_premium": 941.98, "estimated_dependents_premium": 0.0, "ops_owner": "member_fulfillment" }], "enrollment_source": { "type": "new_hire_event" }, "employee": { "id": 775786943424998, "first_name": "Leonora", "last_name": "Pouros", "middle_initial": "G", "ssn": "123456879", "email": "rosendo@franeck98i.biz", "gender": "male", "home_address": { "id": 399873689234585, "fax": "5911194602", "zip": "76715", "city": "Kuhichaven", "phone": "8140870570", "state": "MD", "country": "Mauritania", "inactive": false, "street_1": "81244 Vandervort Cliff", "street_2": "Apt. 943", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "Port Alix", "work_address": null }, "annual_salary": "140000.0", "birthday": "1992-07-11", "hired_at": "2020-11-01", "panda_url": "http://manage.gusto-dev.com:3000/employees/7757869434243585", "hippo_url": "http://hippo.gusto-dev.com:4001/employees/7757869434243585", "benefits_eligibility_date": "2020-11-01", "employment_status": "full_time" }, "company": { "id": 77576169235998, "name": "Prosacco LLC", "email": "carol_bogisich@gutkowskiwaelchi.net", "phone": "4042271534", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923583061", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923583061" }, "state_carriers": [{ "id": 246, "name": "UnitedHealthcare", "state": "MA", "key": "united_healthcare_ma" }, { "id": 237, "name": "Guardian", "state": "MA", "key": "guardian_ma" }], "dependents": [], "policies": [{ "id": "c5dec856-ffdb-4d3d-bd32-aa7b21ff4798", "name": "UnitedHealthcare Choice Plus Platinum $0 BRFK 961", "benefit_type": "medical", "group_number": "28335669", "policy_number": "04W7517" }], "forms": [{ "id": 1987501, "form_includes_all_dependents": true, "fully_mapped": true, "missing_values_by_path": ["form.signed_at", "company.group_number.primary", "form.signature", "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "company.group_number.primary"], "name": "2017 UHC MA Employee Enrollment", "signed_at": "2020-11-10T08:09:00.409-08:00", "state_carrier_id": 246, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/1987501" }], "answers": [] }'
		);
		list_Events.add(objEvent2);
		insert list_Events;
		Test.stopTest();

		System.assert([SELECT COUNT() FROM HI_Fulfillment_Event__c WHERE Processing_State__c = 'Error'] == 2);
	}

	@isTest
	static void testSelectionCaseFulfillments() {
		List<Case> list_Case = new List<Case>();
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.Id__c = '10001-X01';
		objSubmit.Company_Id__c = '7757616923639614';
		objSubmit.Employee_Id__c = '7757869432028764';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'selections_submitted';
		objSubmit.Event_Info__c = '{"created_at":"2023-01-30T10:08:05-08:00","error_message":null,"selections":[{"uuid":"6310265e-3d70-4e2c-b030-eae6872104a9","url":"http://hippo.gusto-dev.com:4001/companies/7757616923639614/employees/7757869432028764/selections/283681","status":"enrolling","enrollment_information":{"policy_id":"78a11605-9704-403c-bc43-f67af7174843","dependent_ids":[],"state_carrier_id":22},"subscriber_id":"XXX-XX-6748","start_date":"2023-02-01","end_date":"2023-12-31","estimated_total_premium":51.57,"estimated_employee_premium":51.57,"estimated_dependents_premium":0.0,"ops_owner":"member_fulfillment"},{"uuid":"7cb4460a-b879-40b5-a355-0504327a4f6f","url":"http://hippo.gusto-dev.com:4001/companies/7757616923639614/employees/7757869432028764/selections/283683","status":"enrolling","enrollment_information":{"policy_id":"7b350bd9-fb47-4205-88b5-553eb97b29d3","dependent_ids":[],"state_carrier_id":22},"subscriber_id":"XXX-XX-2806","start_date":"2023-02-01","end_date":"2023-12-31","estimated_total_premium":14.26,"estimated_employee_premium":14.26,"estimated_dependents_premium":0.0,"ops_owner":"member_fulfillment"},{"uuid":"b7928213-cab9-4c4e-b8ba-fa950a642cd0","url":"http://hippo.gusto-dev.com:4001/companies/7757616923639614/employees/7757869432028764/selections/286737","status":"enrolling","enrollment_information":{"policy_id":"aa58891c-d205-4fd5-b48a-6e6cac41a4e1","dependent_ids":[],"state_carrier_id":2},"subscriber_id":"XXX-XX-7734","start_date":"2023-02-01","end_date":"2023-12-31","estimated_total_premium":383.19,"estimated_employee_premium":383.19,"estimated_dependents_premium":0.0,"ops_owner":"member_fulfillment"}],"enrollment_source":{"type":"new_hire_event"},"employee":{"id":7757869432028764,"first_name":"Joey","last_name":"Mueller","middle_initial":"C","ssn":null,"email":"merle.schneider@mohr-boehm.io","gender":"male","home_address":{"id":754587756047157,"fax":null,"zip":"15012-0817","city":"Shantayfort","phone":null,"state":"MS","country":"Seychelles","inactive":false,"street_1":"12501 Heller Station","street_2":"Apt. 659","created_at":"2023-01-29","updated_at":"2023-01-29","county_name":"East Peimouth","work_address":null},"annual_salary":"91500.0","birthday":"1999-06-23","hired_at":"2019-11-04","panda_url":"http://app.gusto-dev.com:3000/employees/7757869432028764","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639614/employees/7757869432028764","benefits_eligibility_date":"2018-02-12","employment_status":"full_time"},"company":{"id":7757616923639614,"name":"Roob, Brakus and Halvorson","email":"edmundo@wisoky.org","phone":"9615238416","panda_url":"http://app.gusto-dev.com:3000/companies/7757616923639614","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639614"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","byb_automation_authorized":true,"carrier_enrollment_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639614/employees/7757869432028764/enrollments/99571/guardian_ca"},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","byb_automation_authorized":false,"carrier_enrollment_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639614/employees/7757869432028764/enrollments/99571/blue_shield_ca"}],"dependents":[],"policies":[{"id":"78a11605-9704-403c-bc43-f67af7174843","name":"Guardian EM Dental 15","benefit_type":"dental","group_number":"42055013","policy_number":null},{"id":"7b350bd9-fb47-4205-88b5-553eb97b29d3","name":"CA Guardian EM Vision 14","benefit_type":"vision","group_number":"53532535","policy_number":null},{"id":"aa58891c-d205-4fd5-b48a-6e6cac41a4e1","name":"Silver Full PPO 1700/55 OffEx","benefit_type":"medical","group_number":"74098394","policy_number":null}],"forms":[{"id":212027,"form_includes_all_dependents":true,"fully_mapped":true,"missing_values_by_path":["form.signed_at","company.group_number.primary","form.signature"],"name":"Guardian Employee Enrollment Form","signed_at":"2022-12-15T19:37:27.951-08:00","state_carrier_id":22,"url":"http://hippo.gusto-dev.com:4001/attachments/forms/212027"},{"id":212028,"form_includes_all_dependents":true,"fully_mapped":false,"missing_values_by_path":["form.signed_at","form.signature","employee.benefits_eligibility_date"],"name":"Blue Shield of CA Enrollment Form","signed_at":"2022-12-15T19:37:20.013-08:00","state_carrier_id":2,"url":"http://hippo.gusto-dev.com:4001/attachments/forms/212028"}],"answers":[]}] }';
		insert objSubmit;
		list_Case = [SELECT Id, Selection_UUIds__c, Automation_Status__c FROM Case WHERE Integration_Id__c = '10001-X01' AND BYB_Automation_Authorized__c = TRUE];
		Test.stopTest();
		
		System.assertEquals(1, list_Case.size(), 'Case has been generated successfully.');
		CaseTriggerHelper.skipTrigger = false;

		list_Case[0].Automation_Status__c = 'Completed';
		
		update list_Case[0];

		List<Case_Fulfillment_Selection_Status__c> list_Fulfillment = [
			SELECT Id, Case__c, Selection_Id__c, Selection_UUID__c, Processing_State__c
			FROM Case_Fulfillment_Selection_Status__c
			WHERE Case__c = :list_Case[0].Id
		];
		System.assertEquals(2, list_Fulfillment.size(), 'Fulfillment selection statuses have been populated successfully.');
	}

	@isTest
	static void testSelectionsSubmittedEvent() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		String strDate = String.valueOf(Date.today().addDays(10));
		strDate = strDate.substring(0,10);
		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.Id__c = 'a98f2732-cc98-4712-8049-324fa6b53e76';
		objSubmit.Company_Id__c = '7757616923639614';
		objSubmit.Employee_Id__c = '7757869432028764';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'selections_submitted';
		objSubmit.Event_Info__c =
			'{"created_at":"2023-11-17T04:38:42-08:00","error_message":null,"selections":[{"uuid":"2c23b1bb-2e75-4e4c-9f3d-822b09a01369","url":"https://hippo.gusto.com/companies/7757616923639614/employees/7757869432028764/selections/7165443","status":"enrolling","enrollment_information":{"policy_id":"5e702482-7acb-474b-a872-f63d5410089d","dependent_ids":["eb4a66d5-b537-4028-8b3f-059189fcd861","6e02feb6-ddc0-4854-80cf-d8916b682f5b","889a516f-4362-4657-abb3-4e5e17a29a3c"],"state_carrier_id":1},' +
			'"start_date":"' +
			strDate +
			'","end_date":"' +
			strDate +
			'","estimated_total_premium":2441.05,"estimated_employee_premium":776.92,"estimated_dependents_premium":1664.13,"ops_owner":"member_fulfillment"}],"enrollment_source":{"type":"new_hire_event"},"employee":{"id":7757869432028764,"first_name":"Deborah","last_name":"Hamill","middle_initial":"S","ssn":"432530089","email":"hamillds@gmail.com","gender":"female","home_address":{"fax":null,"zip":"53593","city":"Verona","phone":null,"state":"WI","country":"USA","inactive":false,"street_1":"9414 Silverstone Ln","street_2":"","created_at":"2023-11-13T18:03:13.000-08:00","updated_at":"2023-11-13T18:03:13.000-08:00","county_name":"Dane","work_address":false},"annual_salary":"230000.0","birthday":"1978-11-10","hired_at":"2023-11-13","panda_url":"https://app.gusto.com/panda/employees/7757869432028764","hippo_url":"https://hippo.gusto.com/companies/7757616923639614/employees/7757869432028764","benefits_eligibility_date":"2023-11-13","employment_status":"full_time"},"company":{"id":7757616923639614,"name":"Boldr","email":"mparker@boldrimpact.com","phone":"3104052026","panda_url":"https://app.gusto.com/panda/companies/7757616923639614","hippo_url":"https://hippo.gusto.com/companies/7757616923639614"},"state_carriers":[{"id":1,"name":"Anthem Blue Cross of California","state":"CA","key":"anthem_ca","byb_automation_authorized":false,"carrier_enrollment_url":"https://hippo.gusto.com/companies/7757616923639614/employees/7757869432028764/enrollments/3073529/anthem_ca"}],"dependents":[{"id":"889a516f-4362-4657-abb3-4e5e17a29a3c","first_name":"Luca","last_name":"Fitzgerald","ssn":"714734566","birthday":"2019-02-07","gender":"male","dependent_type":"child","url":"https://hippo.gusto.com/companies/7757616923639614/employees/7757869432028764/dependents/632878"},{"id":"6e02feb6-ddc0-4854-80cf-d8916b682f5b","first_name":"Sebastian","last_name":"Fitzgerald","ssn":"148674364","birthday":"2016-12-04","gender":"male","dependent_type":"child","url":"https://hippo.gusto.com/companies/7757616923639614/employees/7757869432028764/dependents/632875"},{"id":"eb4a66d5-b537-4028-8b3f-059189fcd861","first_name":"Alicia","last_name":"Fitzgerald","ssn":"230498106","birthday":"1976-08-23","gender":"female","dependent_type":"spouse","url":"https://hippo.gusto.com/companies/7757616923639614/employees/7757869432028764/dependents/632863"}],"policies":[{"id":"5e702482-7acb-474b-a872-f63d5410089d","name":"Anthem Platinum PPO 15/250/10% 6RG6","benefit_type":"medical","group_number":null,"policy_number":null}],"forms":[{"id":7615820,"form_includes_all_dependents":true,"fully_mapped":true,"missing_values_by_path":["company.group_number.primary","company.group_number.primary"],"name":"2023 CA Anthem EE Enrollment Form","signed_at":"2023-11-15T08:17:00.469-08:00","state_carrier_id":1,"url":"https://hippo.gusto.com/attachments/forms/7615820"}],"answers":[]}';
		insert objSubmit;

		Test.stopTest();

		Case objCase = [SELECT Id, Status, MF_Group_Number__c FROM Case WHERE Integration_Id__c = 'a98f2732-cc98-4712-8049-324fa6b53e76' LIMIT 1];
		System.assertEquals(CaseUtils.STATUS_ON_HOLD, objCase.Status, 'Case status has not be set as On Hold.');
	}
}