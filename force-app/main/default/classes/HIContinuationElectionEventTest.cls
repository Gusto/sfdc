/**
 * @name         HIContinuationElectionEventTest
 * @author 		 Bhagat Singh
 * @date         8th Apr 2021
 * @description  Process Continuation Election Events and update/create relevant cases.
 * @Classes      HIContinuationElectionEvent
 * @revisions    Date ------------ Name ------------ Comments
 */
@isTest
private class HIContinuationElectionEventTest {
	public static final String HI_EVENT_STATUS_PROCESSED = 'Processed';
	public static final String HI_EVENT_STATUS_ERROR = 'Error';
	public static final String strContinuationElectionJSON = '{ "continuation_subscriptions": [ { "url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778/selections/944416", "enrollment_information": { "policy_id": "26346aa1-62c3-4745-b5c4-068e593e501e", "employee_enrolled": true,  "dependent_ids": ["ed8c6d28-9a4c-4b97-a8ef-e10771c315d7"], "state_carrier_id": 25 }, "estimated_total_premium": 325.63, "estimated_employee_premium": 325.63, "estimated_dependents_premium": 0.0, "start_date": "2020-10-27", "end_date": "2021-08-25" } ], "employee": { "id": 775786943433345, "first_name": "Capelli Test", "last_name": "Christiansen", "middle_initial": "", "ssn": "123456789", "birthday": "1988-01-02", "email": "capellipvtltd@gusto.com", "employment_status": "full_time", "home_address":{ "id": 384247876498560, "fax": "4798709884", "zip": "34232", "city": "Lake Vernon", "phone": "4496179450", "state": "NY", "country": "Myanmar", "inactive": false, "street_1": "685 Ankunding Ramp", "street_2": "Suite 748", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "Watsicaton", "work_address": null }, "gender": "male", "hired_at": "2016-04-02", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028/employees/7757869434078778", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778" }, "company": { "id": 7757616924033330,  "name": "Capelli Pvt Ltd", "email": "capellipvtltd@gusto.com", "phone": "5716433475", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028" }, "state_carriers": [ { "id": 25, "name": "UnitedHealthcare", "state": "CA", "key": "united_healthcare_ca" } ], "policies": [ { "id": "26346aa1-62c3-4745-b5c4-068e593e501e", "name": "Select Plus Gold BHCK / 852 [1/2/3/4]", "benefit_type": "medical", "group_number": "67523901", "policy_number": "05U6993" } ], "dependents": [ { "id": "ed8c6d28-9a4c-4b97-a8ef-e10771c315d7", "first_name": "Cordell", "last_name": "Weimann", "ssn": "123456789", "birthday": "1995-04-14", "gender": "male", "dependent_type": "spouse", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923617935/employees/7757869432045461/dependents/39681" } ], "forms": [ { "id": 876124, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": [ "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "form.signed_at", "form.signature", "form.signature", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signature", "form.signature" ], "name": "UnitedHealthcare", "state_carrier_id": 25, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/876124" } ] }';

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void testSetup() {
		Blob key = EncryptionUtils.generateKey('Master');

		Account objAccount = new Account(ZP_Company_ID__c = '7757616924033330', Name = 'Capelli Pvt Ltd');
		insert objAccount;

		Carrier__c objCarrier = new Carrier__c(
			Key__c = 'united_healthcare_ma',
			Id__c = '25',
			Name = 'UnitedHealthcare',
			State__c = 'MA'
		);
		insert objCarrier;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test HI Continuation Election Event: Postive case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testHIContinuationElection() {
		Test.startTest();
		HI_Fulfillment_Event__c objSubmit = createHIContinuationElectionEvent(strContinuationElectionJSON);

		Test.stopTest();

		System.assert([SELECT Id FROM Case WHERE Account_Company_Id__c = :objSubmit.Company_Id__c].size() > 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test HI Continuation Election Event: Negative case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testHIContinuationElectionNegativeCase() {
		Test.startTest();
		String strJSON = HIContinuationElectionEventTest.strContinuationElectionJSON;
		if (String.isNotBlank(strJSON)) {
			strJSON = strJSON.replace('7757616924033330', '200001');
		}

		HI_Fulfillment_Event__c objSubmit = createHIContinuationElectionEvent(strJSON);

		Test.stopTest();

		System.assert([SELECT Id FROM Case WHERE Account_Company_Id__c = :objSubmit.Company_Id__c].size() == 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : Company Id required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHICEValidationCompnayId() {
		Test.startTest();
		String strCEFirstJSON = '{ "continuation_subscriptions": [ { "url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778/selections/944416", "enrollment_information": { "policy_id": "26346aa1-62c3-4745-b5c4-068e593e501e", "employee_enrolled": true,  "dependent_ids": ["ed8c6d28-9a4c-4b97-a8ef-e10771c315d7"], "state_carrier_id": 25 }, "estimated_total_premium": 325.63, "estimated_employee_premium": 325.63, "estimated_dependents_premium": 0.0, "start_date": "2020-10-27", "end_date": "2021-08-25" } ], "employee": { "id": 775786943433345, "first_name": "Capelli Test", "last_name": "Christiansen", "middle_initial": "", "ssn": "123456789", "birthday": "1988-01-02", "email": "capellipvtltd@gusto.com", "employment_status": "full_time", "home_address":{ "id": 384247876498560, "fax": "4798709884", "zip": "34232", "city": "Lake Vernon", "phone": "4496179450", "state": "NY", "country": "Myanmar", "inactive": false, "street_1": "685 Ankunding Ramp", "street_2": "Suite 748", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "Watsicaton", "work_address": null }, "gender": "male", "hired_at": "2016-04-02", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028/employees/7757869434078778", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778" }, "state_carriers": [ { "id": 25, "name": "UnitedHealthcare", "state": "CA", "key": "united_healthcare_ca" } ], "policies": [ { "id": "26346aa1-62c3-4745-b5c4-068e593e501e", "name": "Select Plus Gold BHCK / 852 [1/2/3/4]", "benefit_type": "medical", "group_number": "67523901", "policy_number": "05U6993" } ], "dependents": [ { "id": "ed8c6d28-9a4c-4b97-a8ef-e10771c315d7", "first_name": "Cordell", "last_name": "Weimann", "ssn": "123456789", "birthday": "1995-04-14", "gender": "male", "dependent_type": "spouse", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923617935/employees/7757869432045461/dependents/39681" } ], "forms": [ { "id": 876124, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": [ "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "form.signed_at", "form.signature", "form.signature", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signature", "form.signature" ], "name": "UnitedHealthcare", "state_carrier_id": 25, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/876124" } ] }';
		HI_Fulfillment_Event__c objSubmit = createHIContinuationElectionEvent(strCEFirstJSON);

		Test.stopTest();

		System.assert(
			[SELECT Message__c FROM HI_Fulfillment_Event__c WHERE Id = :objSubmit.Id].Message__c ==
			HIEnrollmentEventUtility.COMPANY_ID_IS_MISSING
		);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : Email Id required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHICEValidationEmailId() {
		Test.startTest();
		String strCESecondJSON = '{ "continuation_subscriptions": [ { "url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778/selections/944416", "enrollment_information": { "policy_id": "26346aa1-62c3-4745-b5c4-068e593e501e", "employee_enrolled": true,  "dependent_ids": ["ed8c6d28-9a4c-4b97-a8ef-e10771c315d7"], "state_carrier_id": 25 }, "estimated_total_premium": 325.63, "estimated_employee_premium": 325.63, "estimated_dependents_premium": 0.0, "start_date": "2020-10-27", "end_date": "2021-08-25" } ], "employee": { "id": 775786943433345, "first_name": "Capelli Test", "last_name": "Christiansen", "middle_initial": "", "ssn": "123456789", "birthday": "1988-01-02", "email": "", "employment_status": "full_time", "home_address":{ "id": 384247876498560, "fax": "4798709884", "zip": "34232", "city": "Lake Vernon", "phone": "4496179450", "state": "NY", "country": "Myanmar", "inactive": false, "street_1": "685 Ankunding Ramp", "street_2": "Suite 748", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "Watsicaton", "work_address": null }, "gender": "male", "hired_at": "2016-04-02", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028/employees/7757869434078778", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778" }, "company": { "id": 7757616924033330,  "name": "Capelli Pvt Ltd", "email": "capellipvtltd@gusto.com", "phone": "5716433475", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028" }, "state_carriers": [ { "id": 25, "name": "UnitedHealthcare", "state": "CA", "key": "united_healthcare_ca" } ], "policies": [ { "id": "26346aa1-62c3-4745-b5c4-068e593e501e", "name": "Select Plus Gold BHCK / 852 [1/2/3/4]", "benefit_type": "medical", "group_number": "67523901", "policy_number": "05U6993" } ], "dependents": [ { "id": "ed8c6d28-9a4c-4b97-a8ef-e10771c315d7", "first_name": "Cordell", "last_name": "Weimann", "ssn": "123456789", "birthday": "1995-04-14", "gender": "male", "dependent_type": "spouse", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923617935/employees/7757869432045461/dependents/39681" } ], "forms": [ { "id": 876124, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": [ "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "form.signed_at", "form.signature", "form.signature", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signature", "form.signature" ], "name": "UnitedHealthcare", "state_carrier_id": 25, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/876124" } ] }';
		HI_Fulfillment_Event__c objSubmit = createHIContinuationElectionEvent(strCESecondJSON);

		Test.stopTest();

		System.assert(
			[SELECT Message__c FROM HI_Fulfillment_Event__c WHERE Id = :objSubmit.Id].Message__c ==
			HIEnrollmentEventUtility.EMAIL_ID_IS_MISSING
		);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : State Carrier.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHICEValidationStateCarriers() {
		Test.startTest();
		String strCEThirdJSON = '{ "continuation_subscriptions": [ { "url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778/selections/944416", "enrollment_information": { "policy_id": "26346aa1-62c3-4745-b5c4-068e593e501e", "employee_enrolled": true,  "dependent_ids": ["ed8c6d28-9a4c-4b97-a8ef-e10771c315d7"], "state_carrier_id": 25 }, "estimated_total_premium": 325.63, "estimated_employee_premium": 325.63, "estimated_dependents_premium": 0.0, "start_date": "2020-10-27", "end_date": "2021-08-25" } ], "employee": { "id": 775786943433345, "first_name": "Capelli Test", "last_name": "Christiansen", "middle_initial": "", "ssn": "123456789", "birthday": "1988-01-02", "email": "capellipvtltd@gusto.com", "employment_status": "full_time", "home_address":{ "id": 384247876498560, "fax": "4798709884", "zip": "34232", "city": "Lake Vernon", "phone": "4496179450", "state": "NY", "country": "Myanmar", "inactive": false, "street_1": "685 Ankunding Ramp", "street_2": "Suite 748", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "Watsicaton", "work_address": null }, "gender": "male", "hired_at": "2016-04-02", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028/employees/7757869434078778", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778" }, "company": { "id": 7757616924033330,  "name": "Capelli Pvt Ltd", "email": "capellipvtltd@gusto.com", "phone": "5716433475", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028" }, "policies": [ { "id": "26346aa1-62c3-4745-b5c4-068e593e501e", "name": "Select Plus Gold BHCK / 852 [1/2/3/4]", "benefit_type": "medical", "group_number": "67523901", "policy_number": "05U6993" } ], "dependents": [ { "id": "ed8c6d28-9a4c-4b97-a8ef-e10771c315d7", "first_name": "Cordell", "last_name": "Weimann", "ssn": "123456789", "birthday": "1995-04-14", "gender": "male", "dependent_type": "spouse", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923617935/employees/7757869432045461/dependents/39681" } ], "forms": [ { "id": 876124, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": [ "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "form.signed_at", "form.signature", "form.signature", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signature", "form.signature" ], "name": "UnitedHealthcare", "state_carrier_id": 25, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/876124" } ] }';
		HI_Fulfillment_Event__c objSubmit = createHIContinuationElectionEvent(strCEThirdJSON);

		Test.stopTest();

		System.assert(
			[SELECT Message__c FROM HI_Fulfillment_Event__c WHERE Id = :objSubmit.Id].Message__c ==
			HIEnrollmentEventUtility.STATE_CARRIER_IS_MISSING
		);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : Selection Info.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHICEValidationSelectionInfo() {
		Test.startTest();
		String strCEFourthJSON = '{ "employee": { "id": 775786943433345, "first_name": "Capelli Test", "last_name": "Christiansen", "middle_initial": "", "ssn": "123456789", "birthday": "1988-01-02", "email": "capellipvtltd@gusto.com", "employment_status": "full_time", "home_address":{ "id": 384247876498560, "fax": "4798709884", "zip": "34232", "city": "Lake Vernon", "phone": "4496179450", "state": "NY", "country": "Myanmar", "inactive": false, "street_1": "685 Ankunding Ramp", "street_2": "Suite 748", "created_at": "2000-01-01", "updated_at": "2000-01-01", "county_name": "Watsicaton", "work_address": null }, "gender": "male", "hired_at": "2016-04-02", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028/employees/7757869434078778", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028/employees/7757869434078778" }, "company": { "id": 7757616924033330,  "name": "Capelli Pvt Ltd", "email": "capellipvtltd@gusto.com", "phone": "5716433475", "panda_url": "http://manage.gusto-dev.com:3000/companies/7757616923655028", "hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923655028" }, "state_carriers": [ { "id": 25, "name": "UnitedHealthcare", "state": "CA", "key": "united_healthcare_ca" } ], "policies": [ { "id": "26346aa1-62c3-4745-b5c4-068e593e501e", "name": "Select Plus Gold BHCK / 852 [1/2/3/4]", "benefit_type": "medical", "group_number": "67523901", "policy_number": "05U6993" } ], "dependents": [ { "id": "ed8c6d28-9a4c-4b97-a8ef-e10771c315d7", "first_name": "Cordell", "last_name": "Weimann", "ssn": "123456789", "birthday": "1995-04-14", "gender": "male", "dependent_type": "spouse", "url": "http://hippo.gusto-dev.com:4001/companies/7757616923617935/employees/7757869432045461/dependents/39681" } ], "forms": [ { "id": 876124, "form_includes_all_dependents": true, "fully_mapped": false, "missing_values_by_path": [ "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "employee.benefits_eligibility_date", "form.signed_at", "form.signature", "form.signature", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signed_at", "form.signature", "form.signature" ], "name": "UnitedHealthcare", "state_carrier_id": 25, "url": "http://hippo.gusto-dev.com:4001/attachments/forms/876124" } ] }';
		HI_Fulfillment_Event__c objSubmit = createHIContinuationElectionEvent(strCEFourthJSON);

		Test.stopTest();

		System.assert(
			[SELECT Message__c FROM HI_Fulfillment_Event__c WHERE Id = :objSubmit.Id].Message__c ==
			HIEnrollmentEventUtility.SELECTION_INFO_MISSING
		);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create HI Continuation Election Event
	 * @Parm        : String in JSON format.
	 * @Return      : Object of HI_Fulfillment_Event__c record
	 **/
	public static HI_Fulfillment_Event__c createHIContinuationElectionEvent(String strJSON) {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objSubmit = new HI_Fulfillment_Event__c();
		objSubmit.Id__c = '7757616924033330';
		objSubmit.Company_Id__c = '7757616924033330';
		objSubmit.Employee_Id__c = '775786943433345';
		objSubmit.Processing_State__c = 'Queued';
		objSubmit.Event_Type__c = 'continuation_election';
		objSubmit.Event_Info__c = strJSON;
		insert objSubmit;

		return objSubmit;
	}
}