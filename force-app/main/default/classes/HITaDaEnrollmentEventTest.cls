/**
 * @name         HITaDaEnrollmentEventTest
 * @author
 * @date         12th Jan 2021
 * @description  Unit Tests for HITaDaEnrollmentEvent.
 * @Classes      HITaDaEnrollmentEvent
 * @revisions    Date ------------ Name ------------ Comments
 */
@isTest
public class HITaDaEnrollmentEventTest {
	public static String strTADAEnrollmentJSON = '{"error_message":null,"enrollment":{"id":940283,"employee_id":7757869432210241,"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/enrollments/940223"},"recent_qles":[],"enrollment_source":{"type":"open_enrollment_start"},"employee":{"id":7757869432210241,"first_name":"","last_name":"saini","middle_initial":"Z","ssn":"123456789","email":"rickey_harris@morar.name","gender":"male","home_address":{"id":801052781517681,"fax":"2686707838","zip":"21763-1905","city":"PortTrumanburgh","phone":"2797913010","state":"SC","country":"NorthernMarianaIslands","inactive":false,"street_1":"1758HarberVista","street_2":"Suite310","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"NewLuther","work_address":null},"annual_salary":"175000.0","birthday":"1988-06-22","hired_at":"2018-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432210241","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432210241","benefits_eligibility_date":"2018-06-25","employment_status":"full_time"},"company":{"id":1385484787107154,"name":"HamillGroup","email":"victor@kihn.name","phone":"7935208442","panda_url":"http://manage.gusto-dev.com:3000/companies/1385484787107154","hippo_url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154"},"dependents":[{"id":"fd73d3b3-e236-4097-ad7b-99bf13638fd0","first_name":"Willy","last_name":"Hermiston","ssn":"123456789","birthday":"1995-01-22","gender":"male","dependent_type":"spouse","url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/dependents/143617"},{"id":"3165e6f9-5b58-4318-a75c-8d08874c619b","first_name":"Rusty","last_name":"Sipes","ssn":"123456789","birthday":"1943-02-04","gender":"female","dependent_type":"child","url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/dependents/143618"}],"benefits_url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/benefits","enrollments_url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/enrollments","tada":{"dca":{"provider_key":"alegeus","benefit_items":{"current":{"id":2147288,"policy_id":268104,"policy_uuid":"5febfd96-b32f-4fd6-8f71-3e79220466fe","benefit_type":"dca","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869432210241,"employee_alegeus_id":524863288,"dependent_ids":[143618],"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/selections/2147288","uuid":"45153311-4f2a-44c7-ad48-491c381f31b4","estimated_start_date":"2021-01-01","ops_owner":"member_fulfillment"},"overlapping":[{"id":1344866,"policy_id":268104,"policy_uuid":"5febfd96-b32f-4fd6-8f71-3e79220466fe","benefit_type":"dca","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869432210241,"employee_alegeus_id":524863288,"dependent_ids":[143618],"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/subscriptions/1344866","uuid":null}],"previous":[{"id":833692,"policy_id":157557,"policy_uuid":"160bb4ba-7cb3-4d91-a14d-1292673cf2ac","benefit_type":"dca","subscriber_id":"47878419","start_date":"2020-01-01","end_date":"2020-12-31","processing_status":"processed","enrollment_id":614328,"employee_id":7757869432210241,"employee_alegeus_id":524863288,"dependent_ids":[143618],"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/subscriptions/833692","uuid":null}]},"policies":[{"id":268104,"name":"DependentCareFSA","benefit_type":"dca","company_alegeus_id":400273005,"visible":true,"termination_policy":"last_day_of_employment","url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/policies/268104","uuid":"5febfd96-b32f-4fd6-8f71-3e79220466fe"}]},"fsa":{"provider_key":"alegeus","benefit_items":{"current":{"id":2147269,"policy_id":268103,"policy_uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9","benefit_type":"fsa","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869432210241,"employee_alegeus_id":524863288,"dependent_ids":[143618,143617],"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/selections/2147269","uuid":"18f81ea6-5d74-44e2-9a95-39d12dbc2ffe","estimated_start_date":"2021-01-01","ops_owner":"member_fulfillment"},"overlapping":[{"id":1344853,"policy_id":268103,"policy_uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9","benefit_type":"fsa","subscriber_id":null,"start_date":"2021-01-01","end_date":"2021-12-31","processing_status":"processed","enrollment_id":940223,"employee_id":7757869432210241,"employee_alegeus_id":524863288,"dependent_ids":[143618,143617],"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/subscriptions/1344853","uuid":null}],"previous":[{"id":924742,"policy_id":154353,"policy_uuid":"edadac0f-9668-4a7f-bb67-5aa9e8a601aa","benefit_type":"fsa","subscriber_id":"59733973","start_date":"2020-01-01","end_date":"2020-12-31","processing_status":"processed","enrollment_id":607889,"employee_id":7757869432210241,"employee_alegeus_id":524863288,"dependent_ids":[143618,143617],"url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/subscriptions/924742","uuid":null}]},"policies":[{"id":268103,"name":"HealthFSA","benefit_type":"fsa","company_alegeus_id":400273005,"visible":true,"termination_policy":"last_day_of_employment","url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/policies/268103","uuid":"61d79cc7-d699-4c4c-aaf4-5cf683176af9"}]},"hsa":{"provider_key":"alegeus","hsa_benefit":{"benefit_type":"hsa","id":21847,"name":"HealthSavingsAccount","company_id":7757616923625514,"effective_date":"2024-01-01","expiration_date":"2024-12-31","status":"visible","url":"http://hippo.gusto-dev.com:4001/companies/7757616923625514/policies","provider_key":"elevate"},"hsa_selection":{"id":76732,"employee_id":7757869440859028,"hsa_benefit_id":21847,"max_contribution_cents":"40000.0","url":"http://hippo.gusto-dev.com:4001/companies/7757616923625514/employees/7757869440859028/hsa_subscriptions/selections/76732","uuid":"becd1393-72fc-425e-9dad-741859c27e19"}}}}';
	public static String strTADAEnrollmentJSON1 = '{"error_message":null,"enrollment":{"id":1023432,"employee_id":7757869432210241,"url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432210241/enrollments/1023432"},"recent_qles":[],"enrollment_source":{"type":"open_enrollment_start"},"employee":{"id":7757869432210241,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432210241","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432210241","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"},"dependents":[],"benefits_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432210241/benefits","enrollments_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432210241/enrollments","tada":{"hsa":{"hsa_selection":{"id":15815,"employee_id":7757869432210241,"hsa_benefit_id":3889,"max_contribution_cents":"360000.0","url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/employees/7757869432210241/hsa_subscriptions/selections/15815","uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","effective_date":"2021-01-01","ops_owner":"member_fulfillment"},"hsa_benefit":{"benefit_type":"hsa","id":3889,"name":"Health Savings Account","company_id":1385484787107154,"effective_date":"2021-01-01","expiration_date":"2021-12-31","status":"visible","url":"http://hippo.gusto-dev.com:4001/companies/1385484787107154/policies"}}}}';

	@testSetup
	static void testSetup() {
		Blob objKey = EncryptionUtils.generateKey('Master');
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').setZPCompanyId('1385484787107154').build();
		insert objAccount;
		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('User1')
			.setEmail('testaccount@gmail.com')
			.setEmployeeId('7757869432210241')
			.build();
		insert objCompanyContact;

		List<Carrier__c> list_Carrier = new List<Carrier__c>();

		Carrier__c objCarrierAlegeus = new TestDataFactory.CarrierBuilder().setName('alegeus').setKey('alegeus').build();
		Carrier__c objCarrierElevate = new TestDataFactory.CarrierBuilder().setName('elevate').setKey('elevate').build();
		list_Carrier.add(objCarrierElevate);
		list_Carrier.add(objCarrierAlegeus);
		insert list_Carrier;
	}
	static testMethod void testTADAEnrollment() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('10001')
			.setCompanyId('1385484787107154')
			.setEmployeeId('7757869432210241')
			.setEventType('tada_enrollment_ready_for_processing')
			.setprocessingstate('Queued')
			.setEventInfo(strTADAEnrollmentJSON)
			.build();

		insert objHiEvent;
		List<Case> list_Case = [SELECT Id, DCA_UUID__c FROM Case WHERE Account.ZP_Company_ID__c = '1385484787107154'];
		System.assertEquals(list_Case.size(), 2);
	}
	static testMethod void testTADAEnrollmentHSA() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('10001')
			.setCompanyId('1385484787107154')
			.setEmployeeId('7757869432210241')
			.setEventType('tada_enrollment_ready_for_processing')
			.setprocessingstate('Queued')
			.setEventInfo(strTADAEnrollmentJSON1)
			.build();
		insert objHiEvent;
		HI_Fulfillment_Event__c objHIFulfillment = [SELECT ID, Processing_State__c, Message__c FROM HI_Fulfillment_Event__c WHERE id__c = '10001' LIMIT 1];
		System.assertEquals('Error', objHIFulfillment.Processing_State__c);
	}

	static testMethod void testTadaEnrollmentWithHSAWithNoAccount() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;

		String strTaDaEnrollmentEventJSON = '{"error_message":null,"enrollment":{"id":1023432,"employee_id":7757869432847385,"url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/enrollments/1023432"},"recent_qles":[],"enrollment_source":{"type":"open_enrollment_start"},"employee":{"id":7757869432847385,"first_name":"Zula","last_name":"Hudson","middle_initial":null,"ssn":"123456789","email":"lavone_okuneva@cruickshank.com","gender":"male","home_address":{"id":772964610732016,"fax":"7841448630","zip":"76056-4918","city":"New Evelinaville","phone":"2417965311","state":"MI","country":"Netherlands","inactive":false,"street_1":"688 Mohamed Trace","street_2":"Apt. 707","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Lake Palmira","work_address":null},"annual_salary":"84000.0","birthday":"1973-04-08","hired_at":"2019-06-25","panda_url":"http://manage.gusto-dev.com:3000/employees/7757869432847385","hippo_url":"http://hippo.gusto-dev.com:4001/employees/7757869432847385","benefits_eligibility_date":"2019-06-25","employment_status":"full_time"},"company":{"id":7757616923639580,"name":"Stroman-Grant","email":"houston_walker@weber.info","phone":"7347719947","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923639580","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580"},"dependents":[],"benefits_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/benefits","enrollments_url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/enrollments","tada":{"hsa":{"hsa_selection":{"id":15815,"employee_id":7757869432847385,"hsa_benefit_id":3889,"max_contribution_cents":"360000.0","url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/employees/7757869432847385/hsa_subscriptions/selections/15815","uuid":"b75ec060-2b40-4591-bc4a-7123906abebe","effective_date":"2021-01-01","ops_owner":"member_fulfillment"},"hsa_benefit":{"benefit_type":"hsa","id":3889,"name":"Health Savings Account","company_id":7757616923639580,"effective_date":"2021-01-01","expiration_date":"2021-12-31","status":"visible","url":"http://hippo.gusto-dev.com:4001/companies/7757616923639580/policies"}}}}';
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('10002-eyrvg26345')
			.setCompanyId('7757616923645172')
			.setEmployeeId('7757869431976033')
			.setEventType('tada_enrollment_ready_for_processing')
			.setprocessingstate('Queued')
			.setEventInfo(strTaDaEnrollmentEventJSON)
			.build();
		insert objHiEvent;

		Test.stopTest();
		System.assert([SELECT COUNT() FROM HI_Fulfillment_Event__c WHERE Id__c = '10002-eyrvg26345' AND Processing_State__c = 'Error'] == 1);
	}
	static testMethod void testTADAEnrollmentHSA1() {
	}
}