/**
  Author:        Robin Grover
  Company:       Gusto
  Description:   This is a test class for HiFulfillmentEventHandler 
  **/
@isTest
private class HiFulfillmentEventHandlerTest {
	@TestSetup
	static void makeData() {
		Account objAcct = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').setZPCompanyId('1370368242490000').build();
		insert objAcct;

		insert new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setZPUserId('7757869431795591')
			.setAccountId(objAcct.Id)
			.setFirstName('First')
			.setLastName('Last')
			.setEmail('first.last@company.test')
			.build();

		insert new TestDataFactory.CarrierBuilder().setName('Test Carrier').setKey('bcbs_ma').setState('AL').build();
	}

	@isTest
	static void createNewHIFulfillmentRecTest() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Blob blobEncryptionKey = EncryptionUtils.generateKey('Master');

		String event_id = '10001';
		String event_type = 'selections_submitted';
		String company_id = '7757616923611861';
		String employee_id = '7757869431844438';
		String event_info = '{"created_at":"2020-12-23T15:22:26-08:00","error_message": null,"selections":[{"uuid":"39cae52e-fb8a-4354-b18d-835ed37db19d","url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/selections/169997","status":"enrolling","enrollment_information":{"policy_id":"16e1d2db-ad5e-4fe1-9b60-930bd6e256a0","dependent_ids":["90c22511-ac84-4a47-9a5c-1207a1aa6cbc"],"state_carrier_id":25},"subscriber_id":"56416470","start_date":"2017-10-01","end_date":"2017-10-31","estimated_total_premium":560.61,"estimated_employee_premium":560.61,"estimated_dependents_premium":0.0,"ops_owner":"member_fulfillment"},{"uuid":"872610b8-21ea-4922-bdb7-43773aa3bfce","url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/selections/169998","status":"enrolling","enrollment_information":{"policy_id":"ed80c286-4941-4c80-8b85-06b49a996e8c","dependent_ids":["90c22511-ac84-4a47-9a5c-3333a1aa6cbc"],"state_carrier_id":259},"subscriber_id":"41111746","start_date":"2017-10-01","end_date":"2017-10-31","estimated_total_premium": 63.83,"estimated_employee_premium":63.83,"estimated_dependents_premium":0.0,"ops_owner":"member_fulfillment"},{"uuid":"15395b6d-3d34-4000-96a1-eab79f961a6e","url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/selections/169999","status":"enrolling","enrollment_information":{"policy_id":"fda23a77-d743-4850-8ae2-b9089f706227","dependent_ids":[],"state_carrier_id":22},"subscriber_id":"35441130","start_date":"2017-10-01","end_date":"2017-10-31","estimated_total_premium": 11.51,"estimated_employee_premium":11.51,"estimated_dependents_premium":0.0,"ops_owner":"member_fulfillment"}],"enrollment_source":{"type":"new_hire_event"},"employee": {"id": 7757869431844438,"first_name":"Kemberly","last_name":"Hudson","middle_initial":"P","ssn":"123456789","email":"tobias@streich.io","gender":"male","home_address": {"id": 514549487225296,"fax":"9152318310","zip":"96705","city":"Port Greg","phone":"3133071249","state":"WA","country":"Burkina Faso","inactive": false,"street_1":"4131 Salvador Tunnel","street_2":"Suite 405","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"West Ethylton","work_address": null },"annual_salary":"150000.0","birthday":"1960-06-20","hired_at":"2017-09-18","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869431844438","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869431844438","benefits_eligibility_date":"2017-09-18","employment_status":"full_time"},"company": {"id": 7757616923611861,"name":"Kassulke, Bergstrom and Kohler","email":"joseph_tromp@cummerata.com","phone":"7794987807","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923611861","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861"},"state_carriers": [ {"id": 25,"name":"UnitedHealthcare","state":"CA","key":"united_healthcare_ca"}, {"id": 259,"name":"Beam","state":"CA","key":"beam_dental_ca"}, {"id": 22,"name":"Guardian","state":"CA","key":"guardian_ca"} ],"dependents": [ {"id":"90c22511-ac84-4a47-9a5c-1207a1aa6cbc","first_name":"Marla","last_name":"Rolfson","ssn":"123456789","birthday":"1978-05-23","gender":"female","dependent_type":"spouse","url":" http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/dependents/29489"}, {"id":"90c22511-ac84-4a47-9a5c-3333a1aa6cbc","first_name":"Edith","last_name":"Rolfson","ssn":"123456789","birthday":"1998-05-23","gender":"female","dependent_type":"child","url":"http://hippo.gusto-dev.com:4001/companies/7757616923611861/employees/7757869431844438/dependents/29489"} ],"policies": [  {"id":"16e1d2db-ad5e-4fe1-9b60-930bd6e256a0","name":"Select Plus Platinum 15/20% AKRV w/403","benefit_type":"medical","group_number":"30399058","policy_number":"06X4030"}, {"id":"ed80c286-4941-4c80-8b85-06b49a996e8c","name":"CA Beam Smart Premium Select 100/100/60/50-2000 (CS-CA)","benefit_type":"dental","group_number":"73202650","policy_number": null }, {"id":"fda23a77-d743-4850-8ae2-b9089f706227","name":"Guardian EM Vision 12","benefit_type":"vision","group_number":"83232343","policy_number": null } ],"forms": [ {"id": 126296,"form_includes_all_dependents": true,"fully_mapped": false,"missing_values_by_path": ["form.signed_at","form.signature","form.signed_at","form.signature"],"name":"Guardian Enrollment Form","signed_at":"2017-09-27T15:47:40.431-07:00","state_carrier_id": 22,"url":"http://hippo.gusto-dev.com:4001/attachments/forms/126296"}, {"id": 126295,"form_includes_all_dependents": true,"fully_mapped": false,"missing_values_by_path": ["form.signed_at","form.signature","form.signed_at","form.signature"],"name":"UnitedHealthcare Enrollment Form","signed_at":"2017-09-27T15:47:42.539-07:00","state_carrier_id": 25,"url":"http://hippo.gusto-dev.com:4001/attachments/forms/126295"}, {"id": 126294,"form_includes_all_dependents": true,"fully_mapped": false,"missing_values_by_path": ["form.signed_at","form.signature","form.signed_at","form.signature"],"name":"Beam Dental Enrollment Form","signed_at":"2017-09-27T15:47:47.081-07:00","state_carrier_id": 259,"url":"http://hippo.gusto-dev.com:4001/attachments/forms/126294"}],"answers":[]}';

		Test.startTest();
		HiFulfillmentEventHandler.createNewCase(event_id, event_type, event_info, company_id, '', employee_id);

		HI_Fulfillment_Event__c testEvent = [SELECT Id, Processing_State__c, Event_Info_Encrypted__c FROM HI_Fulfillment_Event__c WHERE Id__c = :event_id];
		System.assertNotEquals(IntegrationUtils.QUEUED_STATE, testEvent.Processing_State__c, 'Processing State does not match');

		Blob blobDecryptedBlob = EncodingUtil.base64Decode(testEvent.Event_Info_Encrypted__c);
		String strDecryptedJSON = EncryptionUtils.getDecryptedText(blobEncryptionKey, blobDecryptedBlob);
		HISelectionsSubmittedEventJSON objParsedInfoEvent = HISelectionSubmittedEvent.getJSONParsedData(strDecryptedJSON);
		String strSelections = (String) JSON.serialize(objParsedInfoEvent.selections[0]);
		System.assertEquals(false, strSelections.contains('subscriber_id'), 'Subscriber ID found in JSON');
		Test.stopTest();
	}
}