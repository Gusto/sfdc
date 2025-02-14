/**
 * @name         HIFulfillmentEventTadaAuditTest
 * @author
 * @date
 * @description  This class is used test fucntionality of HIFulfillmentEventTadaAudit class.
 */
@isTest
private class HIFulfillmentEventTadaAuditTest {
	@TestSetup
	static void TestDataSetupMethod() {
		Blob blobKey = EncryptionUtils.generateKey('Master');
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		Id idCompanyRecordType = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Company').getRecordTypeId();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('TEST ACCOUNT').setJoinedDate(System.today()).setZPCompanyId('1394673155367486').setRecordTypeId('Company').build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setAccountId(objAccount.Id)
			.setLastName('tadaauditCase')
			.setEmail('tadaaudit@testGusto.com')
			.setEmployeeId('1394673445619257')
			.build();
		insert objContact;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder()
			.setName('alegeus')
			.setState(
				'AL; AK; AZ; AR; CA; CO; CT; DC; DE; FL; GA; HI; ID; IL; IN; IA; KS; KY; LA; ME; MD; MA; MI; MN; MS; MO; MT; NE; NV; NH; NJ; NM; NY; NC; ND; OH; OK; OR; PA; RI; SC; SD; TN; TX; UT; VT; VA; WA; WV; WI; WY'
			)
			.build();
		objCarrier.Key__c = 'alegeus';
		List<Carrier__c> list_Carrier = new List<Carrier__c>();
		list_Carrier.add(objCarrier);
		Carrier__c testCarrier2 = new Carrier__c(Key__c = 'elevate', Name = 'elevate');
		list_Carrier.add(testCarrier2);
		upsert list_Carrier;

		HI_Fulfillment_Event__c objEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('tadaAuditTest123')
			.setCompanyId('1394673155367486')
			.setEmployeeId('1394673445619257')
			.setEventType('tada_audit')
			.setEventInfo(
				'{"sub_type": "commuter_enrollment_sync_failed", "company": {"id": 1394673155367486, "name": "Reilly-Hudson", "email": "hoyt_hintz@emmerich.co", "salesforce_account_id": "001G000001hSuoBIAS",  "work_states": [ "CA",  "CT", "NY"], "sic_code": "7379",' +
				'"mailing_address": {"id": 7757869432052154,"fax": "8646653901","zip": "95066","city": "Scotts Valley","phone": "7633198177","state": "CA","country": "USA","inactive": false,"street_1": "64748 Vandervort Stream","street_2": "Suite 269","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"filing_address": {"id": 7757869432052154,"fax": "1093858905","zip": "95066","city": "Scotts Valley","phone": "7715238878","state": "CA","country": "USA","inactive": false,"street_1": "35400 Brendon Neck","street_2": "Apt. 747","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"benefits_address": {"id": 7757869432052154,"fax": "1093858905","zip": "95066","city": "Scotts Valley","phone": "7715238878","state": "CA","country": "USA","inactive": false,"street_1": "35400 Brendon Neck","street_2": "Apt. 747","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"number_of_eligible_ees": 31,"number_of_ineligible_ees": 1,"has_federal_cobra": true,"is_suspended": false,"panda_url": "http://manage.gusto-dev.com:3000/companies/1394673155367486","hippo_url": "http://hippo.gusto-dev.com:4001/companies/1394673155367486","google_drive_folder_url": ""},' +
				'"employee": {"id": 1394673445619257,"first_name": "Jerrell","last_name": "Witting","middle_initial": "","status": "Active","ssn": "123456789","birthday": "1964-05-08","company_id": 1394673155367486,' +
				'"hired_at": "2014-03-03","employment_status": "full_time", "home_address": {"id": null,"fax": "2689571272","zip": "95060","city": "Santa Cruz","phone": "3059994266","state": "CA","country": "USA","inactive": false,"street_1": "3049 Alisa Knoll","street_2": "Suite 261","created_at": "2020-05-05T13:48:12.000-07:00","updated_at": "2020-05-05T13:48:12.000-07:00","county_name": "Santa Cruz",' +
				'"work_address": false},"work_address": {"id": 7757869432052154,"fax": "3016427718","zip": "95066","city": "Scotts Valley","phone": "3681788800","state": "CA","country": "USA","inactive": false,"street_1": "2763 Rohan Mills","street_2": "Apt. 589","created_at": "2018-06-05T08:49:51.000-07:00","updated_at": "2018-06-05T08:49:51.000-07:00","county_name": "Santa Cruz",' +
				'"work_address": true},"email": "tadaaudit@testGusto.com","gender": "male","annual_salary": "240000.0","benefits_eligibility_date": "2014-03-03","panda_url": "http://manage.gusto-dev.com:3000/companies/1394673155367486/employees/1394673445619257","hippo_url": "http://hippo.gusto-dev.com:4001/companies/1394673155367486/employees/1394673445619257"},' +
				'"dependents": [{"id": 180814,"first_name": "Levi","last_name": "Rutherford","ssn": "123456789","birthday": "1981-11-14","gender": "male","dependent_type": "spouse","employee_id": 7757869432828510,"url": "http://hippo.gusto-dev.com:4001/companies/7755926912729207/employees/7757869432828510/dependents/180814"}],' +
				'"employee_benefits": {"provider_key":"alegeus","benefit_type": "commuter","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7755926912729207/employees/7757869432828510/benefits","effective_date": "2020-06-01","election": 1002},"errors": {"error_code": "921010","error_reason": "Flex Name not found"}}'
			)
			.build();
		insert objEvent;
	}

	/**
	 * @description  This method is used to test the case creation with the HI fulfillment event record.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void createTadaAuditEvent() {
		Test.startTest();
		HI_Fulfillment_Event__c objEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('tadaAuditTest1')
			.setCompanyId('1394673155367486')
			.setEmployeeId('1394673445619257')
			.setEventType('tada_audit')
			.setEventInfo(
				'{"sub_type": "hsa_enrollment_sync_failed", "company": {"id": 1394673155367486, "name": "Reilly-Hudson", "email": "hoyt_hintz@emmerich.co", "salesforce_account_id": "001G000001hSuoBIAS",  "work_states": [ "CA",  "CT", "NY"], "sic_code": "7379",' +
				'"mailing_address": {"id": 7757869432052154,"fax": "8646653901","zip": "95066","city": "Scotts Valley","phone": "7633198177","state": "CA","country": "USA","inactive": false,"street_1": "64748 Vandervort Stream","street_2": "Suite 269","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"filing_address": {"id": 7757869432052154,"fax": "1093858905","zip": "95066","city": "Scotts Valley","phone": "7715238878","state": "CA","country": "USA","inactive": false,"street_1": "35400 Brendon Neck","street_2": "Apt. 747","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"benefits_address": {"id": 7757869432052154,"fax": "1093858905","zip": "95066","city": "Scotts Valley","phone": "7715238878","state": "CA","country": "USA","inactive": false,"street_1": "35400 Brendon Neck","street_2": "Apt. 747","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"number_of_eligible_ees": 31,"number_of_ineligible_ees": 1,"has_federal_cobra": true,"is_suspended": false,"panda_url": "http://manage.gusto-dev.com:3000/companies/1394673155367486","hippo_url": "http://hippo.gusto-dev.com:4001/companies/1394673155367486","google_drive_folder_url": ""},' +
				'"employee": {"id": 1394673445619257,"first_name": "Jerrell","last_name": "Witting","middle_initial": "","status": "Active","ssn": "123456789","birthday": "1964-05-08","company_id": 1394673155367486,' +
				'"hired_at": "2014-03-03","employment_status": "full_time", "home_address": {"id": null,"fax": "2689571272","zip": "95060","city": "Santa Cruz","phone": "3059994266","state": "CA","country": "USA","inactive": false,"street_1": "3049 Alisa Knoll","street_2": "Suite 261","created_at": "2020-05-05T13:48:12.000-07:00","updated_at": "2020-05-05T13:48:12.000-07:00","county_name": "Santa Cruz",' +
				'"work_address": false},"work_address": {"id": 7757869432052154,"fax": "3016427718","zip": "95066","city": "Scotts Valley","phone": "3681788800","state": "CA","country": "USA","inactive": false,"street_1": "2763 Rohan Mills","street_2": "Apt. 589","created_at": "2018-06-05T08:49:51.000-07:00","updated_at": "2018-06-05T08:49:51.000-07:00","county_name": "Santa Cruz",' +
				'"work_address": true},"email": "tadaaudit@testGusto.com","gender": "male","annual_salary": "240000.0","benefits_eligibility_date": "2014-03-03","panda_url": "http://manage.gusto-dev.com:3000/companies/1394673155367486/employees/1394673445619257","hippo_url": "http://hippo.gusto-dev.com:4001/companies/1394673155367486/employees/1394673445619257"},' +
				'"dependents": [{"id": 180814,"first_name": "Levi","last_name": "Rutherford","ssn": "123456789","birthday": "1981-11-14","gender": "male","dependent_type": "spouse","employee_id": 7757869432828510,"url": "http://hippo.gusto-dev.com:4001/companies/7755926912729207/employees/7757869432828510/dependents/180814"}],' +
				'"employee_benefits": {"provider_key":"alegeus","benefit_type": "hsa","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7755926912729207/employees/7757869432828510/benefits","effective_date": "2020-06-01","election": 1002},"errors": {"error_code": "921010","error_reason": "Flex account not found"}}'
			)
			.build();
		insert objEvent;

		HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed = new HIFulfillmentEnrollmentTadaAuditJSON();
		Test.stopTest();

		list<HI_Fulfillment_Event__c> list_HIFulfillEvents = [
			SELECT Id, Id__c, Company_Id__c, Employee_Id__c, Event_Info_Encrypted__c, Processing_State__c, Message__c, Processed_At__c, Event_Type__c
			FROM HI_Fulfillment_Event__c
			WHERE Id__c = 'tadaAuditTest1'
		];
		HIFulfillmentEventTadaAudit objHIFulfillmentEventTadaAudit = new HIFulfillmentEventTadaAudit();
		objHIFulfillmentEventTadaAudit.processInformation(list_HIFulfillEvents);
		System.assert([SELECT Id, Type, RecordType.Name FROM Case WHERE Integration_Id__c = 'tadaAuditTest1'] != null, 'Case is created with Integration_Id__c is tadaAuditTest1');
	}

	/**
	 * @description  This method is used to test the case upadtion with exising case for the HI fulfillment event record.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void SecondTadaCheckMethods() {
		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder().setOrigin('Hippo').setRecordTypeId('MF NHE').setEnrollmentId('1394673445619257-1394673155367486-alegeusTada Failure').build();
		insert objCase;

		HI_Fulfillment_Event__c objEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('tadaAuditTest12')
			.setCompanyId('1394673155367486')
			.setEmployeeId('1394673445619257')
			.setEventType('tada_audit')
			.setEventInfo(
				'{"sub_type": "dca_enrollment_sync_failed", "company": {"id": 1394673155367486, "name": "Reilly-Hudson", "email": "hoyt_hintz@emmerich.co", "salesforce_account_id": "001G000001hSuoBIAS",  "work_states": [ "CA",  "CT", "NY"], "sic_code": "7379",' +
				'"mailing_address": {"id": 7757869432052154,"fax": "8646653901","zip": "95066","city": "Scotts Valley","phone": "7633198177","state": "CA","country": "USA","inactive": false,"street_1": "64748 Vandervort Stream","street_2": "Suite 269","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"filing_address": {"id": 7757869432052154,"fax": "1093858905","zip": "95066","city": "Scotts Valley","phone": "7715238878","state": "CA","country": "USA","inactive": false,"street_1": "35400 Brendon Neck","street_2": "Apt. 747","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"benefits_address": {"id": 7757869432052154,"fax": "1093858905","zip": "95066","city": "Scotts Valley","phone": "7715238878","state": "CA","country": "USA","inactive": false,"street_1": "35400 Brendon Neck","street_2": "Apt. 747","created_at": "2018-06-05 08:49:51 -0700","updated_at": "2018-06-05 08:49:51 -0700","county_name": "Santa Cruz","work_address": true,"employee_count": 52},' +
				'"number_of_eligible_ees": 31,"number_of_ineligible_ees": 1,"has_federal_cobra": true,"is_suspended": false,"panda_url": "http://manage.gusto-dev.com:3000/companies/1394673155367486","hippo_url": "http://hippo.gusto-dev.com:4001/companies/1394673155367486","google_drive_folder_url": ""},' +
				'"employee": {"id": 1394673445619257,"first_name": "Jerrell","last_name": "Witting","middle_initial": "","status": "Active","ssn": "123456789","birthday": "1964-05-08","company_id": 1394673155367486,' +
				'"hired_at": "2014-03-03","employment_status": "full_time", "home_address": {"id": null,"fax": "2689571272","zip": "95060","city": "Santa Cruz","phone": "3059994266","state": "CA","country": "USA","inactive": false,"street_1": "3049 Alisa Knoll","street_2": "Suite 261","created_at": "2020-05-05T13:48:12.000-07:00","updated_at": "2020-05-05T13:48:12.000-07:00","county_name": "Santa Cruz",' +
				'"work_address": false},"work_address": {"id": 7757869432052154,"fax": "3016427718","zip": "95066","city": "Scotts Valley","phone": "3681788800","state": "CA","country": "USA","inactive": false,"street_1": "2763 Rohan Mills","street_2": "Apt. 589","created_at": "2018-06-05T08:49:51.000-07:00","updated_at": "2018-06-05T08:49:51.000-07:00","county_name": "Santa Cruz",' +
				'"work_address": true},"email": "tadaaudit@testGusto.com","gender": "male","annual_salary": "240000.0","benefits_eligibility_date": "2014-03-03","panda_url": "http://manage.gusto-dev.com:3000/companies/1394673155367486/employees/1394673445619257","hippo_url": "http://hippo.gusto-dev.com:4001/companies/1394673155367486/employees/1394673445619257"},' +
				'"dependents": [{"id": 180814,"first_name": "Levi","last_name": "Rutherford","ssn": "123456789","birthday": "1981-11-14","gender": "male","dependent_type": "spouse","employee_id": 7757869432828510,"url": "http://hippo.gusto-dev.com:4001/companies/7755926912729207/employees/7757869432828510/dependents/180814"}],' +
				'"employee_benefits": {"provider_key":"alegeus","benefit_type": "dca","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7755926912729207/employees/7757869432828510/benefits","effective_date": "2020-06-01","election": 1002},"errors": {"error_code": "921010","error_reason": "Flex Name not found"}}'
			)
			.build();
		insert objEvent;
		HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed = new HIFulfillmentEnrollmentTadaAuditJSON();
		Test.stopTest();

		list<HI_Fulfillment_Event__c> list_HIFulfillEvents = [
			SELECT Id, Id__c, Company_Id__c, Employee_Id__c, Event_Info_Encrypted__c, Processing_State__c, Message__c, Processed_At__c, Event_Type__c
			FROM HI_Fulfillment_Event__c
			WHERE Id__c != 'tadaAuditTest12'
		];
		HIFulfillmentEventTadaAudit objHIFulfillmentEventTadaAudit = new HIFulfillmentEventTadaAudit();
		objHIFulfillmentEventTadaAudit.processInformation(list_HIFulfillEvents);
		System.assert([SELECT Id, Type, RecordType.Name FROM Case WHERE Integration_Id__c = 'tadaAuditTest12'] != null, 'Case is created with Integration_Id__c is tadaAuditTest12');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using MF Audit Types for HSA (HSA Missing Medical Selection).
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testHSAAuditTypeCaseCreationPositive() {
		Test.startTest();
		HI_Fulfillment_Event__c objEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('HSAtadaAuditTest1')
			.setCompanyId('1394673155367486')
			.setEmployeeId('1394673445619257')
			.setEventType('tada_audit')
			.setEventInfo(
				'{"sub_type": "hsa_enrollment_sync_failed","employee": {"id": 1394673445619257,"first_name": "Catherin","last_name": "Aguele","middle_initial": "N","status": "Terminated","ssn": null,"birthday": "1994-05-14","company_id": 1394673155367486,"hired_at": "2020-09-21","employment_status": "full_time",' +
				'"home_address": {"id": 812339459717681,"fax": null,"zip": "94585","city": "North Moises","phone": null,"state": "AL","country": "Seychelles","inactive": false,"street_1": "BBBBBBBBB Tunnel","street_2": "Apt. 872","created_at": "2000-01-01","updated_at": "2000-01-01","county_name": "West Drema","work_address": null},' +
				'"work_address": {"id": 728734583952242,"fax": null,"zip": "81883","city": "North Marline","phone": "9129770376","state": "SD","country": "Guinea-Bissau","inactive": false,"street_1": "4166 Mike Islands","street_2": "Suite 661","created_at": "2000-01-01", "updated_at": "2000-01-01","county_name": "Cormierton","work_address": null},' +
				'"email": "caguele@gmail.com.invalid","gender": "male","annual_salary": "212733.63","benefits_eligibility_date": "2020-09-21","panda_url": "http://app.gusto-dev.com:3000/companies/7757616923842769/employees/7757869434035101","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101"},' +
				'"company": {"id": 1394673155367486,"name": "Aguele Pvt Ltd","email": "jarred@deckow-mayer.biz","salesforce_account_id": "","work_states": ["AZ","CA","CO","CT","DC","DE","FL","GA","IA","IL","IN","MD","MN","MO","NC","NJ","NY","OH","OK","OR","PA","RI","TX","VA","VT","WV"],"sic_code": "7371",' +
				'"mailing_address": {"id": 7757869460539174,"fax": "6251844827","zip": "20903","city": "Silver Spring","phone": "7263865585","state": "MD","country": "USA","inactive": false,"street_1": "906 Jenkins Vista","street_2": "Suite 900","created_at": "2022-01-28T12:32:47-08:00","updated_at": "2022-01-28T12:32:47-08:00","county_name": "Montgomery","work_address": true,"employee_count": 47},' +
				'"filing_address": {"id": 7757869460539174,"fax": "7365235014","zip": "20903","city": "Silver Spring","phone": "1069755742","state": "MD","country": "USA","inactive": false,"street_1": "476 Marisol Walks","street_2": "Suite 617","created_at": "2022-01-28T12:32:47-08:00","updated_at": "2022-01-28T12:32:47-08:00","county_name": "Montgomery","work_address": true,"employee_count": 47},' +
				'"benefits_address": {"id": 7757869460539174,"fax": "7365235014","zip": "20903","city": "Silver Spring","phone": "1069755742","state": "MD","country": "USA","inactive": false,"street_1": "476 Marisol Walks","street_2": "Suite 617","created_at": "2022-01-28T12:32:47-08:00","updated_at": "2022-01-28T12:32:47-08:00","county_name": "Montgomery","work_address": true,"employee_count": 47},' +
				'"number_of_eligible_ees": 102,"number_of_ineligible_ees": 11,"has_federal_cobra": true,"is_suspended": false,"panda_url": "http://app.gusto-dev.com:3000/companies/7757616923842769","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769","google_drive_folder_url": "No Google Drive folder set up"},' +
				'"dependents": [{"id": 205783,"first_name": "Era","last_name": "Schaefer","ssn": "123456789","birthday": "1948-02-07","gender": "male","dependent_type": "spouse","employee_id": 7757869434035101,"url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101/dependents/205783"}],' +
				'"employee_benefits": {"provider_key":"alegeus","benefit_type": "hsa","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101/benefits","effective_date": "2022-09-01","id": 35785,"uuid": "8a4fc0bb-5c7a-482e-969c-f3a8339367b9","policy_id": null,"policy_uuid": null,"election": "8300.00"},' +
				'"errors": {"error_code": "null","error_reason": "[<http://hippo.gusto-dev.com:4001/companies/7757616923842769|ER 7757616923842769> <http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101|EE 7757869434035101>]: HsaEmployeeBenefit ID 35785 is missing a medical selection for March"},"audit_type": "HSA Missing Medical Selection"}'
			)
			.build();
		insert objEvent;

		HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed = new HIFulfillmentEnrollmentTadaAuditJSON();
		Test.stopTest();

		list<HI_Fulfillment_Event__c> list_HIFulfillEvents = [
			SELECT Id, Id__c, Company_Id__c, Employee_Id__c, Event_Info_Encrypted__c, Processing_State__c, Message__c, Processed_At__c, Event_Type__c
			FROM HI_Fulfillment_Event__c
			WHERE Id__c = 'HSAtadaAuditTest1'
		];
		HIFulfillmentEventTadaAudit objHIFulfillmentEventTadaAudit = new HIFulfillmentEventTadaAudit();
		objHIFulfillmentEventTadaAudit.processInformation(list_HIFulfillEvents);
		Case objCase = [SELECT Id, Type, RecordType.Name, Carrier__r.Name FROM Case WHERE Integration_Id__c = 'HSAtadaAuditTest1' LIMIT 1];
		System.assertNotEquals(objCase.Id, null, 'Case is created with Integration_Id__c as HSAtadaAuditTest1');
		System.assertEquals(objCase.Type, 'HSA Missing Medical Selection', 'Case Type Autopopulated as : HSA Missing Medical Selection');
		System.assertEquals(objCase.Carrier__r.Name, 'alegeus', 'Carrier should be alegeus');
		System.assertEquals(objCase.RecordType.Name, 'MF Audit', 'Case created with RecordType Name : MF Audit');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using MF Audit Types for HSA (HSA Contribution Limit Record Missing ).
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testHSAAuditTypeCaseCreationPositive2() {
		Test.startTest();
		HI_Fulfillment_Event__c objEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('HSAtadaAuditTest2')
			.setCompanyId('1394673155367486')
			.setEmployeeId('1394673445619257')
			.setEventType('tada_audit')
			.setEventInfo(
				'{ "employee_benefits": {"provider_key":"alegeus","benefit_type": "hsa","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101/benefits","effective_date": "2022-09-01","id": 35785,"uuid": "8a4fc0bb-5c7a-482e-969c-f3a8339367b9","policy_id": null,"policy_uuid": null,"election": "8300.00"}, "audit_type": "HSA Contribution Limit Record Missing","errors": {"error_reason": "The HsaContributionLimit record for 2024 in development is missing"}}'
			)
			.build();
		insert objEvent;

		HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed = new HIFulfillmentEnrollmentTadaAuditJSON();
		Test.stopTest();

		list<HI_Fulfillment_Event__c> list_HIFulfillEvents = [
			SELECT Id, Id__c, Company_Id__c, Employee_Id__c, Event_Info_Encrypted__c, Processing_State__c, Message__c, Processed_At__c, Event_Type__c
			FROM HI_Fulfillment_Event__c
			WHERE Id__c = 'HSAtadaAuditTest2'
		];
		HIFulfillmentEventTadaAudit objHIFulfillmentEventTadaAudit = new HIFulfillmentEventTadaAudit();
		objHIFulfillmentEventTadaAudit.processInformation(list_HIFulfillEvents);
		Case objCase = [SELECT Id, Type, RecordType.Name FROM Case WHERE Integration_Id__c = 'HSAtadaAuditTest2' LIMIT 1];
		System.assertNotEquals(objCase.Id, null, 'Case is created with Integration_Id__c is HSAtadaAuditTest2');
		System.assertEquals(objCase.Type, 'HSA Contribution Limit Record Missing', 'Created case Type is matching with expected type : HSA Contribution Limit Record Missing');
		System.assertEquals(objCase.RecordType.Name, 'MF Audit', 'Case created with RecordType Name : MF Audit');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using MF Audit Types for HSA (HSA Missing Medical Selection) when provider key is for elevate carrier
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testHSAAuditTypeCaseCreationPositiveElevate() {
		Test.startTest();
		HI_Fulfillment_Event__c objEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('HSAtadaAuditTest1')
			.setCompanyId('1394673155367486')
			.setEmployeeId('1394673445619257')
			.setEventType('tada_audit')
			.setEventInfo(
				'{"sub_type": "hsa_enrollment_sync_failed","employee": {"id": 1394673445619257,"first_name": "Catherin","last_name": "Aguele","middle_initial": "N","status": "Terminated","ssn": null,"birthday": "1994-05-14","company_id": 1394673155367486,"hired_at": "2020-09-21","employment_status": "full_time",' +
				'"home_address": {"id": 812339459717681,"fax": null,"zip": "94585","city": "North Moises","phone": null,"state": "AL","country": "Seychelles","inactive": false,"street_1": "BBBBBBBBB Tunnel","street_2": "Apt. 872","created_at": "2000-01-01","updated_at": "2000-01-01","county_name": "West Drema","work_address": null},' +
				'"work_address": {"id": 728734583952242,"fax": null,"zip": "81883","city": "North Marline","phone": "9129770376","state": "SD","country": "Guinea-Bissau","inactive": false,"street_1": "4166 Mike Islands","street_2": "Suite 661","created_at": "2000-01-01", "updated_at": "2000-01-01","county_name": "Cormierton","work_address": null},' +
				'"email": "caguele@gmail.com.invalid","gender": "male","annual_salary": "212733.63","benefits_eligibility_date": "2020-09-21","panda_url": "http://app.gusto-dev.com:3000/companies/7757616923842769/employees/7757869434035101","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101"},' +
				'"company": {"id": 1394673155367486,"name": "Aguele Pvt Ltd","email": "jarred@deckow-mayer.biz","salesforce_account_id": "","work_states": ["AZ","CA","CO","CT","DC","DE","FL","GA","IA","IL","IN","MD","MN","MO","NC","NJ","NY","OH","OK","OR","PA","RI","TX","VA","VT","WV"],"sic_code": "7371",' +
				'"mailing_address": {"id": 7757869460539174,"fax": "6251844827","zip": "20903","city": "Silver Spring","phone": "7263865585","state": "MD","country": "USA","inactive": false,"street_1": "906 Jenkins Vista","street_2": "Suite 900","created_at": "2022-01-28T12:32:47-08:00","updated_at": "2022-01-28T12:32:47-08:00","county_name": "Montgomery","work_address": true,"employee_count": 47},' +
				'"filing_address": {"id": 7757869460539174,"fax": "7365235014","zip": "20903","city": "Silver Spring","phone": "1069755742","state": "MD","country": "USA","inactive": false,"street_1": "476 Marisol Walks","street_2": "Suite 617","created_at": "2022-01-28T12:32:47-08:00","updated_at": "2022-01-28T12:32:47-08:00","county_name": "Montgomery","work_address": true,"employee_count": 47},' +
				'"benefits_address": {"id": 7757869460539174,"fax": "7365235014","zip": "20903","city": "Silver Spring","phone": "1069755742","state": "MD","country": "USA","inactive": false,"street_1": "476 Marisol Walks","street_2": "Suite 617","created_at": "2022-01-28T12:32:47-08:00","updated_at": "2022-01-28T12:32:47-08:00","county_name": "Montgomery","work_address": true,"employee_count": 47},' +
				'"number_of_eligible_ees": 102,"number_of_ineligible_ees": 11,"has_federal_cobra": true,"is_suspended": false,"panda_url": "http://app.gusto-dev.com:3000/companies/7757616923842769","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769","google_drive_folder_url": "No Google Drive folder set up"},' +
				'"dependents": [{"id": 205783,"first_name": "Era","last_name": "Schaefer","ssn": "123456789","birthday": "1948-02-07","gender": "male","dependent_type": "spouse","employee_id": 7757869434035101,"url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101/dependents/205783"}],' +
				'"employee_benefits": {"provider_key":"elevate","benefit_type": "hsa","hippo_url": "http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101/benefits","effective_date": "2022-09-01","id": 35785,"uuid": "8a4fc0bb-5c7a-482e-969c-f3a8339367b9","policy_id": null,"policy_uuid": null,"election": "8300.00"},' +
				'"errors": {"error_code": "null","error_reason": "[<http://hippo.gusto-dev.com:4001/companies/7757616923842769|ER 7757616923842769> <http://hippo.gusto-dev.com:4001/companies/7757616923842769/employees/7757869434035101|EE 7757869434035101>]: HsaEmployeeBenefit ID 35785 is missing a medical selection for March"},"audit_type": "HSA Missing Medical Selection"}'
			)
			.build();
		insert objEvent;

		HIFulfillmentEnrollmentTadaAuditJSON objHIEventInfoParsed = new HIFulfillmentEnrollmentTadaAuditJSON();
		Test.stopTest();

		list<HI_Fulfillment_Event__c> list_HIFulfillEvents = [
			SELECT Id, Id__c, Company_Id__c, Employee_Id__c, Event_Info_Encrypted__c, Processing_State__c, Message__c, Processed_At__c, Event_Type__c
			FROM HI_Fulfillment_Event__c
			WHERE Id__c = 'HSAtadaAuditTest1'
		];
		HIFulfillmentEventTadaAudit objHIFulfillmentEventTadaAudit = new HIFulfillmentEventTadaAudit();
		objHIFulfillmentEventTadaAudit.processInformation(list_HIFulfillEvents);
		Case objCase = [SELECT Id, Type, RecordType.Name, Carrier__r.Name FROM Case WHERE Integration_Id__c = 'HSAtadaAuditTest1' LIMIT 1];
		System.assertNotEquals(objCase.Id, null, 'Case is created with Integration_Id__c as HSAtadaAuditTest1');
		System.assertEquals(objCase.Type, 'HSA Missing Medical Selection', 'Case Type Autopopulated as : HSA Missing Medical Selection');
		System.assertEquals(objCase.Carrier__r.Name, 'elevate', 'Carrier should be elevate');
		System.assertEquals(objCase.RecordType.Name, 'MF Audit', 'Case created with RecordType Name : MF Audit');
	}
}