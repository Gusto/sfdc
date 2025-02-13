/**
    Author:        Bhagat Singh
    Company:       Gusto
    Description:   This is a test class for HIFulfillmentEventCommuterEnrolmTest
**/
@isTest
public class HIFulfillmentEventHSAEnrolmentTest {
	public static final String strAlegeus = 'alegeus';
	public static final String strElevate = 'elevate';
	public static String strFirstJSON =
		'{"employee": {"id": 101, "first_name": "Bonnie", "last_name": "Robel", "middle_initial": "D", "status": "Active", "ssn": "241541227", "birthday": "2017-06-28", "company_id": 742157482339, "hired_at": "2017-06-28", "employment_status": "full_time", "home_address": {"id": 492427006170, "street_1": "58860 Blake Curve", "street_2": "Suite 126", "employee_count": 4, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "58860 Blake Curve, Suite 126"}, "work_address": {"id": 377682428964, "street_1": "52341 Jast Haven", "street_2": "Suite 692", "employee_count": 3, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "52341 Jast Haven, Suite 692"}, "email": "employee_email@example.com", "gender": "female", "panda_url": "https://app.zentest.com/companies/742157482339/employees/1", "hippo_url": "https://hippo.zentest.com/companies/742157482339/employees/1"}, "company": {"id": 742157482339, "name": "Walker, Quigley and Gutmann", "email": "company_email@example.com", "salesforce_account_id": null, "work_states": null, "sic_code": "3999", "mailing_address": {"id": 239513024030, "street_1": "5914 Katheryn Land", "street_2": "Suite 966", "employee_count": 9, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "5914 Katheryn Land, Suite 966"}, "filing_address": {"id": 901064782608, "street_1": "7554 Hessel Groves", "street_2": "Apt. 969", "employee_count": 8, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "7554 Hessel Groves, Apt. 969"}, "benefits_address": {"id": 901064782608, "street_1": "7554 Hessel Groves", "street_2": "Apt. 969", "employee_count": 8, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "7554 Hessel Groves, Apt. 969"}, "number_of_eligible_ees": 1, "number_of_ineligible_ees": 0, "has_federal_cobra": null, "is_suspended": false, "panda_url": "https://app.zentest.com/companies/742157482339", "hippo_url": "https://hippo.zentest.com/companies/742157482339"}, "hsa_benefit": {"id": 1, "company_id": 742157482339, "effective_date": "2017-06-28", "expiration_date": "2017-06-28", "status": "visible", "url": "https://hippo.zentest.com/companies/742157482339/policies","provider_key":"' +
		strAlegeus +
		'"}, "hsa_selection": {"id": 1, "employee_id": 1, "hsa_benefit_id": 1, "max_contribution_cents": 10000, "url": "https://hippo.zentest.com/companies/742157482339/employees/1/hsa_subscriptions/1"}, "policies_url": "https://hippo.zentest.com/companies/742157482339/policies", "subscriptions_url": "https://hippo.zentest.com/companies/742157482339/employees/1/subscriptions"}';
	public static String strSecondJSON =
		'{"employee": {"id": 101, "first_name": "Bonnie", "last_name": "Robel", "middle_initial": "D", "status": "Active", "ssn": "241541227", "birthday": "2017-06-28", "company_id": 742157482339, "hired_at": "2017-06-28", "employment_status": "full_time", "home_address": {"id": 492427006170, "street_1": "58860 Blake Curve", "street_2": "Suite 126", "employee_count": 4, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "58860 Blake Curve, Suite 126"}, "work_address": {"id": 377682428964, "street_1": "52341 Jast Haven", "street_2": "Suite 692", "employee_count": 3, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "52341 Jast Haven, Suite 692"}, "email": "employee_email@example.com", "gender": "female", "panda_url": "https://app.zentest.com/companies/742157482339/employees/1", "hippo_url": "https://hippo.zentest.com/companies/742157482339/employees/1"}, "company": {"id": 742157482339, "name": "Walker, Quigley and Gutmann", "email": "company_email@example.com", "salesforce_account_id": null, "work_states": null, "sic_code": "3999", "mailing_address": {"id": 239513024030, "street_1": "5914 Katheryn Land", "street_2": "Suite 966", "employee_count": 9, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "5914 Katheryn Land, Suite 966"}, "filing_address": {"id": 901064782608, "street_1": "7554 Hessel Groves", "street_2": "Apt. 969", "employee_count": 8, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "7554 Hessel Groves, Apt. 969"}, "benefits_address": {"id": 901064782608, "street_1": "7554 Hessel Groves", "street_2": "Apt. 969", "employee_count": 8, "city": "Samsonside", "state": "CA", "county_name": "San Francisco", "country": "USA", "zip": "94107", "phone": "4051234567", "single_line_street": "7554 Hessel Groves, Apt. 969"}, "number_of_eligible_ees": 1, "number_of_ineligible_ees": 0, "has_federal_cobra": null, "is_suspended": false, "panda_url": "https://app.zentest.com/companies/742157482339", "hippo_url": "https://hippo.zentest.com/companies/742157482339"}, "hsa_benefit": {"id": 1, "company_id": 742157482339, "effective_date": "2017-06-28", "expiration_date": "2017-06-28", "status": "visible", "url": "https://hippo.zentest.com/companies/742157482339/policies","provider_key":"' +
		strElevate +
		'"}, "hsa_selection": {"id": 1, "employee_id": 1, "hsa_benefit_id": 1, "max_contribution_cents": 10000, "url": "https://hippo.zentest.com/companies/742157482339/employees/1/hsa_subscriptions/1"}, "policies_url": "https://hippo.zentest.com/companies/742157482339/policies", "subscriptions_url": "https://hippo.zentest.com/companies/742157482339/employees/1/subscriptions"}';

	@testSetup
	static void setUp() {
		Utils.skipTrigger(true);
		Blob key = EncryptionUtils.generateKey('Master');
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('742157482339')
			.setTier('simple')
			.setSetUpSteps(20.0)
			.build();
		insert objCompanyAccount;

		List<Carrier__c> list_Carrier = new List<Carrier__c>();
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName(strAlegeus).setUniqueName(strAlegeus).setKey(strAlegeus).setState('AL').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName(strElevate).setUniqueName(strElevate).setKey(strElevate).setState('CA').build());
		insert list_Carrier;

		Utils.skipTrigger(false);
	}

	/**
	 * @author       Bhagat Singh
	 * @description  Test method for employee_hsa_enrollment HI Event
	 **/
	@isTest
	static void testEmployeeHSAEnrollment() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setCompanyId('742157482339')
			.setEmployeeId('101')
			.setEventType('employee_hsa_enrollment')
			.build();
		insert objHiEvent;

		objHiEvent.Event_Info__c = strFirstJSON;
		update objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, RecordType.Name, Origin, Carrier__r.Name FROM Case WHERE Account.ZP_Company_ID__c = '742157482339'];
		System.assertEquals('MF NHE', list_Cases[0].RecordType.Name, 'MF NHE Case not created scussfully');
		System.assertEquals(strAlegeus, list_Cases[0].Carrier__r.Name, 'Carrier not correctly assigned');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  Test method for employee_hsa_enrollment_auto_process HI Event
	 **/
	@isTest
	static void testEmployeeHSAEnrollmentAutoProcess() {
		Test.startTest();
		HIFulfillmentEventTriggerHelper.queue = true;
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setCompanyId('742157482339')
			.setEmployeeId('101')
			.setEventType('employee_hsa_enrollment_auto_process')
			.build();
		insert objHiEvent;

		objHiEvent.Event_Info__c = strSecondJSON;
		update objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, RecordType.Name, Origin, Type, Carrier__r.Name FROM Case WHERE Account.ZP_Company_ID__c = '742157482339'];
		System.assertEquals('NHE', list_Cases[0].Type, 'NHE Case not created scussfully');
		System.assertEquals(strElevate, list_Cases[0].Carrier__r.Name, 'Carrier not correctly assigned');
		System.assertEquals(CaseUtils.ORIGIN_WEB, list_Cases[0].Origin, 'Origin not correctly assigned');
	}
}