/**
 * @name         HISelectionCancelledEventTest
 * @author
 * @date         5th Jan 2021
 * @description  Process Selection Submitted Events and update/create relevant cases.
 * @Classes      HISelectionCancelledEvent , HIEnrollmentEventUtility
 * @revisions    Date ------------ Name ------------ Comments
 */

@isTest
private class HISelectionCancelledEventTest {
	public static String strSubmissionJSON = '{"created_at": "2020-12-23T15:22:26-08:00","error_message": null,"selections": [{ "uuid": "39cae52e-fb8a-4354-b18d-835ed37db19d", "url": " http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/selections/169997","status": "enrolling", "enrollment_information": { "policy_id": "16e1d2db-ad5e-4fe1-9b60-930bd6e256a0","dependent_ids": ["90c22511-ac84-4a47-9a5c-1207a1aa6cbc"], "state_carrier_id": 25}, "subscriber_id": "56416470", "start_date": "2017-10-01", "end_date": "2017-10-31", "estimated_total_premium": 560.61,"estimated_employee_premium": 560.61, "estimated_dependents_premium": 0.0, "ops_owner": "member_fulfillment" }, {"uuid": "872610b8-21ea-4922-bdb7-43773aa3bfce", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/selections/169998","status": "enrolling", "enrollment_information": { "policy_id": "ed80c286-4941-4c80-8b85-06b49a996e8c","dependent_ids": ["90c22511-ac84-4a47-9a5c-3333a1aa6cbc"], "state_carrier_id": 259}, "subscriber_id": "41111746", "start_date": "2017-10-01", "end_date": "2017-10-31", "estimated_total_premium": 63.83,"estimated_employee_premium": 63.83, "estimated_dependents_premium": 0.0, "ops_owner": "member_fulfillment" },{"uuid": "15395b6d-3d34-4000-96a1-eab79f961a6e", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/selections/169999","status": "enrolling","enrollment_information": {"policy_id": "fda23a77-d743-4850-8ae2-b9089f706227","dependent_ids": [],"state_carrier_id": 22},"subscriber_id": "35441130", "start_date": "2017-10-01", "end_date": "2017-10-31", "estimated_total_premium": 11.51,"estimated_employee_premium": 11.51, "estimated_dependents_premium": 0.0, "ops_owner": "member_fulfillment"} ], "enrollment_source": { "type": "new_hire_event" }, "employee": {"id": 7757869431844438, "first_name": "Kemberly", "last_name": "Hudson", "middle_initial": "P","ssn": "123456789", "email": "tobias@streich.io", "gender": "male", "home_address": { "id": 514549487225296,"fax": "9152318310", "zip": "96705", "city": "Port Greg", "phone": "3133071249", "state": "WA", "country": "Burkina Faso","inactive": false, "street_1": "4131 Salvador Tunnel", "street_2": "Suite 405", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "West Ethylton", "work_address": null }, "annual_salary": "150000.0", "birthday": "1960-06-20","hired_at": "2017-09-18", "panda_url": "http://manage.gusto-dev.com:3000/employees/7757869431844438", "hippo_url": "http://hippo.gusto-dev.com:4001/employees/7757869431844438", "benefits_eligibility_date": "2017-09-18", "employment_status": "full_time" }, "company": { "id": 7757616923611861, "name": "Kassulke, Bergstrom and Kohler","email": "joseph_tromp@cummerata.com", "phone": "7794987807", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923611861", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923611861" }, "state_carriers": [ { "id": 25, "name": "UnitedHealthcare", "state": "CA", "key": "united_healthcare_ca" }, { "id": 259, "name": "Beam", "state": "CA", "key": "beam_dental_ca" }, { "id": 22, "name": "Guardian", "state": "CA", "key": "guardian_ca" } ], "dependents": [ { "id": "90c22511-ac84-4a47-9a5c-1207a1aa6cbc", "first_name": "Marla", "last_name": "Rolfson", "ssn": "123456789", "birthday": "1978-05-23", "gender": "female", "dependent_type": "spouse", "url": "  http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/dependents/29489" }, { "id": "90c22511-ac84-4a47-9a5c-3333a1aa6cbc", "first_name": "Edith", "last_name": "Rolfson", "ssn": "123456789", "birthday": "1998-05-23", "gender": "female", "dependent_type": "child", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/dependents/29489" } ], "policies": [  { "id": "16e1d2db-ad5e-4fe1-9b60-930bd6e256a0", "name": "Select Plus Platinum 15/20% AKRV w/403", "benefit_type": "medical", "group_number": "30399058", "policy_number": "06X4030" }, { "id": "ed80c286-4941-4c80-8b85-06b49a996e8c", "name": "CA Beam Smart Premium Select 100/100/60/50-2000 (CS-CA)", "benefit_type": "dental", "group_number": "73202650", "policy_number": null }, { "id": "fda23a77-d743-4850-8ae2-b9089f706227","name": "Guardian EM Vision 12", "benefit_type": "vision", "group_number": "83232343", "policy_number": null } ],"forms": [ { "id": 126296, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": ["form.signed_at", "form.signature", "form.signed_at", "form.signature" ], "name": "Guardian Enrollment Form","signed_at": "2017-09-27T15:47:40.431-07:00", "state_carrier_id": 22, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/126296" }, {"id": 126295, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": [ "form.signed_at", "form.signature", "form.signed_at", "form.signature" ], "name": "UnitedHealthcare Enrollment Form", "signed_at": "2017-09-27T15:47:42.539-07:00", "state_carrier_id": 25, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/126295" }, { "id": 126294, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": [ "form.signed_at","form.signature", "form.signed_at", "form.signature" ], "name": "Beam Dental Enrollment Form", "signed_at": "2017-09-27T15:47:47.081-07:00", "state_carrier_id": 259, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/126294"} ], "answers": [] }';

	public static String strCancelJSON = '{"created_at":"2020-12-22T14:24:10-08:00","selection":{"uuid":"39cae52e-fb8a-4354-b18d-835ed37db19d","ops_owner":"new_plans_renewals","status":"enrolling","enrollment_information":{"policy":{"name":"Select Plus Platinum 15/20% AKRV w/403","benefit_type":"medical","group_number":"30399058","policy_number":null},"state_carrier":{"id":25,"name":"UnitedHealthcare","state":"CA","answers":[]}},"start_date":"2017-10-01"},"employee":{"id":7757869431844438,"first_name":"Kemberly","last_name":"Hudson","middle_initial":"P","ssn":"123456789","email":"tobias@streich.io","birthday":"1960-06-20","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431844438","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431844438","benefits_eligibility_date":"2017-03-01","lost_coverage_date":null},"company":{"id":7757616923611861,"name":"Kassulke, Bergstrom and Kohler","email":"joseph_tromp@cummerata.com","phone":"2259435542","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923611861","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861","destroy_reason":"changed_policy_selection"}}';

	@testSetup
	static void testSetup() {
		Blob key = EncryptionUtils.generateKey('Master');

		Account accObj = new Account(ZP_Company_ID__c = '7757616923611861', Name = 'Test Account');
		insert accObj;

		Contact conObj = new Contact(AccountId = accObj.Id, FirstName = 'Test', LastName = 'Account', email = 'testaccount@gmail.com', Employee_Id__c = '7757869431844438');
		insert conObj;

		Carrier__c testCarrier = new Carrier__c(Key__c = 'united_healthcare_ca', Id__c = '25', Name = 'UnitedHealthcare', State__c = 'CA');

		insert testCarrier;

		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;
		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.id__c = '10001';
		objSubmit.Company_Id__c = '7757616923611861';
		objSubmit.Employee_Id__c = '7757869431844438';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'selections_submitted';
		objSubmit.Event_Info__c = strSubmissionJSON;
		insert objSubmit;
	}

	static testMethod void testHISelectionsCancelledEventWithLostCoverageDate() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		String strCancelledJSONWithLostCoverage = '{"created_at":"2020-12-22T14:24:10-08:00","selection":{"uuid":"39cae52e-fb8a-4354-b18d-835ed37db19d","ops_owner":"new_plans_renewals","status":"enrolling","enrollment_information":{"policy":{"name":"Select Plus Platinum 15/20% AKRV w/403","benefit_type":"medical","group_number":"30399058","policy_number":null},"state_carrier":{"id":25,"name":"UnitedHealthcare","state":"CA","answers":[]}},"start_date":"2017-10-01"},"employee":{"id":7757869431844438,"first_name":"Kemberly","last_name":"Hudson","middle_initial":"P","ssn":"123456789","email":"tobias@streich.io","birthday":"1960-06-20","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431844438","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431844438","benefits_eligibility_date":"2017-03-01","lost_coverage_date":"2021-01-01"},"company":{"id":7757616923611861,"name":"Kassulke, Bergstrom and Kohler","email":"joseph_tromp@cummerata.com","phone":"2259435542","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923611861","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861"}}';

		HI_Fulfillment_Event__c objCancel = new HI_Fulfillment_Event__c();
		objCancel.id__c = '10002';
		objCancel.Company_Id__c = '7757616923611861';
		objCancel.Employee_Id__c = '7757869431844438';
		objCancel.Processing_State__c = 'Queued';
		objCancel.Event_Type__c = 'selection_cancelled';
		objCancel.Event_Info__c = strCancelledJSONWithLostCoverage;
		insert objCancel;

		Test.stopTest();

		System.assert([SELECT COUNT() FROM Case WHERE RecordType.Name = 'MF Termination'] == 1);
	}

	static testMethod void testHISelectionsCancelledEventNoCompanyId() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		String strCancelledJSONInvalid = '{"created_at":"2020-12-22T14:24:10-08:00","selection":{"uuid":"39cae52e-fb8a-4354-b18d-835ed37db19d","ops_owner":"new_plans_renewals","status":"enrolling","enrollment_information":{"policy":{"name":"Select Plus Platinum 15/20% AKRV w/403","benefit_type":"medical","group_number":"30399058","policy_number":null},"state_carrier":{"id":25,"name":"UnitedHealthcare","state":"CA","answers":[]}},"start_date":"2017-10-01"},"employee":{"id":7757869431844438,"first_name":"Kemberly","last_name":"Hudson","middle_initial":"P","ssn":"123456789","email":"tobias@streich.io","birthday":"1960-06-20","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431844438","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431844438","benefits_eligibility_date":"2017-03-01","lost_coverage_date":"2021-01-01"},"company":{"name":"Kassulke, Bergstrom and Kohler","email":"joseph_tromp@cummerata.com","phone":"2259435542","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923611861","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861"}}';

		HI_Fulfillment_Event__c objCancel = new HI_Fulfillment_Event__c();
		objCancel.id__c = '10002';
		objCancel.Employee_Id__c = '7757869431844438';
		objCancel.Processing_State__c = 'Queued';
		objCancel.Event_Type__c = 'selection_cancelled';
		objCancel.Event_Info__c = strCancelledJSONInvalid;
		insert objCancel;
		Test.stopTest();

		System.assert([SELECT COUNT() FROM HI_Fulfillment_Event__c WHERE Processing_State__c = 'Error'] == 1);
	}

	static testMethod void testHISelectionsCancelledEventNoSelection() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		String strCancelledJSONInvalid = '{"created_at":"2020-12-22T14:24:10-08:00","selection":null,"employee":{"id":7757869431844438,"first_name":"Kemberly","last_name":"Hudson","middle_initial":"P","ssn":"123456789","email":"tobias@streich.io","birthday":"1960-06-20","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431844438","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431844438","benefits_eligibility_date":"2017-03-01","lost_coverage_date":"2021-01-01"},"company":{"id":7757616923611861,"name":"Kassulke, Bergstrom and Kohler","email":"joseph_tromp@cummerata.com","phone":"2259435542","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923611861","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861"}}';

		HI_Fulfillment_Event__c objCancel = new HI_Fulfillment_Event__c();
		objCancel.id__c = '10002';
		objCancel.Company_Id__c = '7757616923611861';
		objCancel.Employee_Id__c = '7757869431844438';
		objCancel.Processing_State__c = 'Queued';
		objCancel.Event_Type__c = 'selection_cancelled';
		objCancel.Event_Info__c = strCancelledJSONInvalid;
		insert objCancel;
		Test.stopTest();

		System.assert([SELECT COUNT() FROM HI_Fulfillment_Event__c WHERE Processing_State__c = 'Error'] == 1);
	}
	static testMethod void testHISelectionsCancelledEventNOUUID() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		String strCancelledJSONWithLostCoverage = '{"created_at":"2020-12-22T14:24:10-08:00","selection":{"uuid":null,"ops_owner":"new_plans_renewals","status":"enrolling","enrollment_information":{"policy":{"name":"Select Plus Platinum 15/20% AKRV w/403","benefit_type":"medical","group_number":"30399058","policy_number":null},"state_carrier":{"id":25,"name":"UnitedHealthcare","state":"CA","answers":[]}},"start_date":"2017-10-01"},"employee":{"id":7757869431844438,"first_name":"Kemberly","last_name":"Hudson","middle_initial":"P","ssn":"123456789","email":"tobias@streich.io","birthday":"1960-06-20","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431844438","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431844438","benefits_eligibility_date":"2017-03-01","lost_coverage_date":"2021-01-01"},"company":{"id":7757616923611861,"name":"Kassulke, Bergstrom and Kohler","email":"joseph_tromp@cummerata.com","phone":"2259435542","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923611861","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861"}}';

		HI_Fulfillment_Event__c objCancel = new HI_Fulfillment_Event__c();
		objCancel.id__c = '10002';
		objCancel.Company_Id__c = '7757616923611861';
		objCancel.Employee_Id__c = '7757869431844438';
		objCancel.Processing_State__c = 'Queued';
		objCancel.Event_Type__c = 'selection_cancelled';
		objCancel.Event_Info__c = strCancelledJSONWithLostCoverage;
		insert objCancel;
		Test.stopTest();

		System.assert([SELECT COUNT() FROM HI_Fulfillment_Event__c WHERE Processing_State__c = 'Error'] == 1);
	}
	static testMethod void testHISelectionsCancelledEventJSONInvalid() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		String strCancelledJSONInvalid = '{"created_at":2020-12-22T14:24:10-08:00,"selection":{"uuid":null,"ops_owner":"new_plans_renewals","status":"waived","enrollment_information":"policy":{"name":"Select Plus Platinum 15/20% AKRV w/403","benefit_type":"medical","group_number":"30399058","policy_number":null},"state_carrier":{"id":25,"name":"UnitedHealthcare","state":"CA","answers":[]}},"start_date":"2017-10-01"},"employee":{"id":7757869431844438,"first_name":"Kemberly","last_name":"Hudson","middle_initial":"P","ssn":"123456789","email":"tobias@streich.io","birthday":"1960-06-20","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431844438","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431844438","benefits_eligibility_date":"2017-03-01","lost_coverage_date":"2021-01-01"},"company":{"id":7757616923611861,"name":"Kassulke, Bergstrom and Kohler","email":"joseph_tromp@cummerata.com","phone":"2259435542","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923611861","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861"}}';

		HI_Fulfillment_Event__c objCancel = new HI_Fulfillment_Event__c();
		objCancel.id__c = '10002';
		objCancel.Company_Id__c = '7757616923611861';
		objCancel.Employee_Id__c = '7757869431844438';
		objCancel.Processing_State__c = 'Queued';
		objCancel.Event_Type__c = 'selection_cancelled';
		objCancel.Event_Info__c = strCancelledJSONInvalid;
		insert objCancel;
		Test.stopTest();

		System.assert([SELECT COUNT() FROM HI_Fulfillment_Event__c WHERE Processing_State__c = 'Error'] == 1);
	}

	static testMethod void testHISelectionsCancelled() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objCancel = new HI_Fulfillment_Event__c();
		objCancel.id__c = '10001';
		objCancel.Company_Id__c = '7757616923611861';
		objCancel.Employee_Id__c = '7757869431844438';
		objCancel.Processing_State__c = 'Queued';
		objCancel.Event_Type__c = 'selection_cancelled';
		objCancel.Event_Info__c = strCancelJSON;
		insert objCancel;

		List<Case> list_Case = [
			SELECT id, OwnerId, Status, Benefit_Types__c, Selection_UUIds__c, Medical_UUID__c, Dental_UUID__c, Life_UUID__c, Vision_UUID__c, Long_Term_Disability_UUID__c, Short_Term_Disability_UUID__c
			FROM Case
			WHERE Account.ZP_Company_ID__c = :objCancel.Company_Id__c
		];

		//Result: Case should be created related to Company Id.
		System.assert(list_Case.size() > 0);

		if (list_Case.size() > 0) {
			for (Case objCase : list_Case) {
				objCase.Status = 'Closed';
			}

			update list_Case;
		}

		HI_Fulfillment_Event__c objCancel1 = new HI_Fulfillment_Event__c();
		objCancel1.id__c = '10001';
		objCancel1.Company_Id__c = '7757616923611861';
		objCancel1.Employee_Id__c = '7757869431844438';
		objCancel1.Processing_State__c = 'Queued';
		objCancel1.Event_Type__c = 'selection_cancelled';
		objCancel1.Event_Info__c = strCancelJSON;
		insert objCancel1;
		Test.stopTest();

		list_Case = [SELECT id FROM Case WHERE Account.ZP_Company_ID__c = :objCancel.Company_Id__c];
		System.assert(list_Case.size() > 0);
	}

	static testMethod void testHISelectionsCancelledWithSubmittedCase() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
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
				Short_Term_Disability_UUID__c,
				Carrier__c
			FROM Case
			WHERE Account.ZP_Company_ID__c = '7757616923611861'
		];

		//Result: Case should be created related to Company Id.
		System.assert(list_Case.size() > 0);
		if (list_Case.size() > 0) {
			for (Case objCase : list_Case) {
				objCase.Status = 'Submitted';
				objCase.Submission_Method__c = 'Mapped Form';
			}
			update list_Case;
		}

		HI_Fulfillment_Event__c objCancel = new HI_Fulfillment_Event__c();
		objCancel.id__c = '10002';
		objCancel.Company_Id__c = '7757616923611861';
		objCancel.Employee_Id__c = '7757869431844438';
		objCancel.Processing_State__c = 'Queued';
		objCancel.Event_Type__c = 'selection_cancelled';
		objCancel.Event_Info__c = strCancelJSON;
		insert objCancel;
        HIEnrollmentEventUtility.updateCaseOwner(list_Case[0],false);
        HIEnrollmentEventUtility.updateCaseOwner(list_Case[0],true);
        HIEnrollmentEventUtility.updateUUIDOnCase('dental', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('hsa', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('hsa', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Remove');
        HIEnrollmentEventUtility.updateUUIDOnCase('fsa', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('fsa', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Remove');
        HIEnrollmentEventUtility.updateUUIDOnCase('dca', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('dca', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Remove');
        HIEnrollmentEventUtility.updateUUIDOnCase('short_term_disability', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('short_term_disability', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Remove');
        HIEnrollmentEventUtility.updateUUIDOnCase('long_term_disability', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('long_term_disability', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Remove');
        HIEnrollmentEventUtility.updateUUIDOnCase('vision', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('vision', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Remove');
        HIEnrollmentEventUtility.updateUUIDOnCase('life', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Add');
        HIEnrollmentEventUtility.updateUUIDOnCase('life', list_Case[0], '39cae52e-fb8a-4354-b18d-835ed37db19d','Remove');
        HIEnrollmentEventUtility.getMFAuditDescrptions();
		Test.stopTest();

		list_Case = [SELECT id FROM Case WHERE Account.ZP_Company_ID__c = :objCancel.Company_Id__c];
		//Result: Case should be created related to Company Id.
		System.assert(list_Case.size() > 0);
	}
}