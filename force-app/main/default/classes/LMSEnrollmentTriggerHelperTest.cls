/*
 * @name         LMSEnrollmentTriggerHelperTest
 * @author       Prity Kumari
 * @date         2022-07-19
 * @description  Testing LMSEnrollmentsTriggerHelper
 */
@isTest
public with sharing class LMSEnrollmentTriggerHelperTest {
	/*
	 * @author:         Prity Kumari
	 * @description:    Setup test data
	 * @parm:           NA
	 * @return:         NA
	 */
	@testSetup
	static void setupData() {
		TriggerHandler.bypass(new List<String>{ 'ContactTriggerHandler', 'AccountTriggerHandler' });
		// Create a new Reseller Account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Company Account Test Builder').setZPCompanyId('1234567890').build();

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Company Account Test Builder1').setZPCompanyId('1234567891').build();
		insert new List<Account>{ objAccount, objAccount1 };

		// Create new Reseller Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Reseller')
			.setAccountId(objAccount.Id)
			.setFirstName('Intellum')
			.setLastName('Admin')
			.setEmail('intellum.admin@gusto.com')
			.setUUID('5GTRD_GT643')
			.setZPUserRole('Accountant')
			.build();

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Reseller')
			.setAccountId(objAccount1.Id)
			.setFirstName('Intellum')
			.setLastName('Admin1')
			.setEmail('intellum.admin1@gusto.com')
			.setUUID('5GTRD_GT643_uuid')
			.setZPUserRole('Accountant;Employee')
			.build();
		insert new List<Contact>{ objContact, objContact1 };
		TriggerHandler.clearAllBypasses();

		// Create new course
		intellumapp__IntellumActivity__c objCourse = new TestDataFactory.IntellumCourseBuilder()
			.setId(1234)
			.setName('Gusto People Advisory')
			.setLearningTrack('People Advisory')
			.setProgramType('Certification')
			.build();

		List<String> list_Courses = Label.Getting_Started_With_Gusto_Pro.split(',');

		intellumapp__IntellumActivity__c objCourse1 = new TestDataFactory.IntellumCourseBuilder()
			.setId(Decimal.valueOf(list_Courses[0]))
			.setName(Label.Getting_Started_With_Gusto_Pro)
			.setLearningTrack('Payroll Essentials')
			.setProgramType('Course')
			.build();

		intellumapp__IntellumActivity__c objCourse2 = new TestDataFactory.IntellumCourseBuilder()
			.setId(1236)
			.setName('Gusto Practise Mangagement')
			.setLearningTrack('Practice Management')
			.setProgramType('Certification')
			.build();
		intellumapp__IntellumActivity__c objCourse3 = new TestDataFactory.IntellumCourseBuilder()
			.setId(1235)
			.setName('Gusto Payroll Essentials')
			.setLearningTrack('Payroll Essentials')
			.setProgramType('Certification')
			.build();
		insert new List<intellumapp__IntellumActivity__c>{ objCourse, objCourse2, objCourse1, objCourse3 };

		// Create new user
		intellumapp__IntellumUser__c objUser = new TestDataFactory.IntellumUserBuilder().setId(99999).setName('Intellum Admin').setUUID('5GTRD_GT643').setEmail('intellum.admin@gusto.com').build();

		// Create new user
		intellumapp__IntellumUser__c objUser1 = new TestDataFactory.IntellumUserBuilder()
			.setId(88888)
			.setName('Intellum Admin1')
			.setUUID('5GTRD_GT643_uuid')
			.setEmail('intellum.admin1@gusto.com')
			.build();
		insert new List<intellumapp__IntellumUser__c>{ objUser, objUser1 };
	}
	/*
	 * @author:         Prity Kumari
	 * @description:    Assert that Contact Lookup field on LMSEnrollment is not set on Insert for a different UUID
	 * @parm:           NA
	 * @return:         NA
	 */
	@isTest
	static void testEnrollmentContactLookupOnInsertPositive() {
		List<String> list_Course = Label.Getting_Started_With_Gusto_Pro.split(',');
		Decimal decCourseId = Decimal.valueOf(list_Course[0]);
		List<intellumapp__IntellumActivity__c> list_Courses = [SELECT Id, intellumapp__id__c FROM intellumapp__IntellumActivity__c WHERE intellumapp__id__c IN (1234, 1236, :decCourseId, 1235)];
		List<intellumapp__IntellumUser__c> list_User = [SELECT Id, intellumapp__id__c FROM intellumapp__IntellumUser__c WHERE intellumapp__id__c IN (99999, 88888)];

		Test.startTest();
		intellumapp__IntellumEnrollment__c objEnrollment = new TestDataFactory.IntellumEnrollmentBuilder()
			.setId(545232)
			.setUser(list_User[0].Id)
			.setActivity(list_Courses[0].Id) //people advisory
			.setStatus('in-progress')
			.setStartDate(System.now().addDays(-1))
			.setTime(System.now())
			.build();

		intellumapp__IntellumEnrollment__c objEnrollment1 = new TestDataFactory.IntellumEnrollmentBuilder()
			.setId(545235)
			.setUser(list_User[0].Id)
			.setActivity(list_Courses[1].Id) //practice management
			.setStatus('passed')
			.setCompletedTime(System.now())
			.setStartDate(System.now().addDays(-2))
			.setTime(System.now().addDays(-1))
			.build();

		intellumapp__IntellumEnrollment__c objEnrollment2 = new TestDataFactory.IntellumEnrollmentBuilder()
			.setId(545233)
			.setUser(list_User[1].Id)
			.setActivity(list_Courses[2].Id) //getting started
			.setStatus('passed')
			.setTime(System.now())
			.setCompletedTime(System.now())
			.setStartDate(System.now().addDays(-1))
			.build();

		intellumapp__IntellumEnrollment__c objEnrollment3 = new TestDataFactory.IntellumEnrollmentBuilder()
			.setId(545234)
			.setUser(list_User[1].Id)
			.setActivity(list_Courses[3].Id) // payroll essentials
			.setStatus('no-show')
			.setTime(System.now().addDays(-1))
			.setStartDate(System.now().addDays(-1))
			.build();

		insert new List<intellumapp__IntellumEnrollment__c>{ objEnrollment, objEnrollment1, objEnrollment2, objEnrollment3 };
		Test.stopTest();
		Map<Id, intellumapp__IntellumEnrollment__c> map_EnrollmentAssert = new Map<Id, intellumapp__IntellumEnrollment__c>(
			[
				SELECT Id, Contact__r.Id, intellumapp__status__c, intellumapp__IntellumActivity__r.intellumapp__custom_a__c, intellumapp__IntellumActivity__r.intellumapp__custom_c__c
				FROM intellumapp__IntellumEnrollment__c
				WHERE intellumapp__id__c IN (545232, 545235, 545233, 545234)
			]
		);
		for (Account objAccountAssert : [
			SELECT
				Id,
				of_accountants_cert_Gusto_Payroll__c,
				of_accountants_cert_Accelerator__c,
				of_accountants_cert_People_Advisory__c,
				Getting_started_with_gusto_pro__c,
				Accounting_Firm_Certification_Status__c,
				firm_certified_date__c,
				firm_accelerator_status__c,
				firm_people_advisory_status__c,
				firm_payroll_essentials_status__c,
				Num_Accountants_Certified__c,
				num_accountants_at_firm__c,
				num_total_users__c,
				num_users_certified__c,
				(
					SELECT
						Id,
						AccountId,
						Inactive_ZP_User__c,
						ZP_User_Role__c,
						UUID__c,
						Accountant_Accelerator_Status__c,
						Gusto_Payroll_Certification_Status__c,
						People_advisory_Certification_Status__c,
						Completed_Getting_Started_With_Gusto_Pro__c,
						Accountant_Certifications_Status__c,
						accountant_certified_date__c,
						accountant_accelerator_completion_date__c,
						Accountant_gusto_payroll_completion_date__c,
						accountant_people_advisory_complete_date__c,
						people_advisory_lastopened_date__c,
						accelerator_lastopened_date__c,
						gusto_payroll_lastopened_date__c,
						people_advisory_start_date__c,
						accelerator_start_date__c,
						gusto_payroll_start_date__c
					FROM Contacts
					WHERE Inactive_ZP_User__c = FALSE AND UUID__c IN ('5GTRD_GT643', '5GTRD_GT643_uuid')
				)
			FROM Account
		]) {
			for (Contact objContactAssert : objAccountAssert.Contacts) {
				if (objContactAssert.UUID__c == '5GTRD_GT643') {
					//account level assertions
					System.assertEquals(objAccountAssert.Accounting_Firm_Certification_Status__c.toLowerCase(), 'passed');
					System.assertEquals(objAccountAssert.firm_accelerator_status__c.toLowerCase(), 'passed');
					System.assertEquals(objAccountAssert.firm_people_advisory_status__c.toLowerCase(), 'in-progress');
					System.assertEquals(objAccountAssert.firm_payroll_essentials_status__c, null);
					System.assertEquals(objAccountAssert.of_accountants_cert_Gusto_Payroll__c, 0);
					System.assertEquals(objAccountAssert.of_accountants_cert_Accelerator__c, 100);
					System.assertEquals(objAccountAssert.of_accountants_cert_People_Advisory__c, 0);
					System.assertEquals(objAccountAssert.Getting_started_with_gusto_pro__c, 0);
					System.assertEquals(objAccountAssert.Num_Accountants_At_Firm__c, 1);
					System.assertEquals(objAccountAssert.Num_Accountants_Certified__c, 1);
					System.assertEquals(objAccountAssert.firm_certified_date__c, System.today());

					//contact level assertions
					System.assertEquals(objContactAssert.Accountant_Certifications_Status__c.toLowerCase(), 'passed');
					System.assertEquals(objContactAssert.Accountant_Accelerator_Status__c.toLowerCase(), 'passed');
					System.assertEquals(objContactAssert.Gusto_Payroll_Certification_Status__c, null);
					System.assertEquals(objContactAssert.People_advisory_Certification_Status__c, 'in-progress');
					System.assertEquals(objContactAssert.Completed_Getting_Started_With_Gusto_Pro__c, false);
					System.assertEquals(objContactAssert.accountant_certified_date__c, System.today());
					System.assertEquals(objContactAssert.Accountant_gusto_payroll_completion_date__c, null);
					System.assertEquals(objContactAssert.accountant_people_advisory_complete_date__c, null);
					System.assertEquals(objContactAssert.accountant_accelerator_completion_date__c, System.today());

					System.assertEquals(objContactAssert.people_advisory_lastopened_date__c, System.today());
					System.assertEquals(objContactAssert.accelerator_lastopened_date__c, System.today().addDays(-1));
					System.assertEquals(objContactAssert.gusto_payroll_lastopened_date__c, null);
					System.assertEquals(objContactAssert.people_advisory_start_date__c, System.today().addDays(-1));
					System.assertEquals(objContactAssert.accelerator_start_date__c, System.today().addDays(-2));
					System.assertEquals(objContactAssert.gusto_payroll_start_date__c, null);
				} else {
					//account level assertions
					System.assertEquals(objAccountAssert.Accounting_Firm_Certification_Status__c.toLowerCase(), 'no-show');
					System.assertEquals(objAccountAssert.firm_accelerator_status__c, null);
					System.assertEquals(objAccountAssert.firm_people_advisory_status__c, null);
					System.assertEquals(objAccountAssert.firm_payroll_essentials_status__c.toLowerCase(), 'no-show');
					System.assertEquals(objAccountAssert.of_accountants_cert_Gusto_Payroll__c, 0);
					System.assertEquals(objAccountAssert.of_accountants_cert_Accelerator__c, 0);
					System.assertEquals(objAccountAssert.of_accountants_cert_People_Advisory__c, 0);
					System.assertEquals(objAccountAssert.Getting_started_with_gusto_pro__c, 100);
					System.assertEquals(objAccountAssert.Num_Accountants_At_Firm__c, 1);
					System.assertEquals(objAccountAssert.Num_Accountants_Certified__c, 0);
					System.assertEquals(objAccountAssert.firm_certified_date__c, null);

					//contact level assertions
					System.assertEquals(objContactAssert.Accountant_Certifications_Status__c.toLowerCase(), 'no-show');
					System.assertEquals(objContactAssert.Accountant_Accelerator_Status__c, null);
					System.assertEquals(objContactAssert.Gusto_Payroll_Certification_Status__c.toLowerCase(), 'no-show');
					System.assertEquals(objContactAssert.Completed_Getting_Started_With_Gusto_Pro__c, true);
					System.assertEquals(objContactAssert.accountant_certified_date__c, null);
					System.assertEquals(objContactAssert.Accountant_gusto_payroll_completion_date__c, null);
					System.assertEquals(objContactAssert.accountant_people_advisory_complete_date__c, null);
					System.assertEquals(objContactAssert.accountant_accelerator_completion_date__c, null);

					System.assertEquals(objContactAssert.people_advisory_lastopened_date__c, null);
					System.assertEquals(objContactAssert.accelerator_lastopened_date__c, null);
					System.assertEquals(objContactAssert.gusto_payroll_lastopened_date__c, System.today().addDays(-1));
					System.assertEquals(objContactAssert.people_advisory_start_date__c, null);
					System.assertEquals(objContactAssert.accelerator_start_date__c, null);
					System.assertEquals(objContactAssert.gusto_payroll_start_date__c, System.today().addDays(-1));
				}
			}
		}
		checkForExceptions(false);

		LMSEnrollmentTriggerHelper.blnSkipTrigger = true;
		update map_EnrollmentAssert.values();
		LMSEnrollmentTriggerHelper.blnSkipTrigger = false;
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    Assert if Contact Lookup field on Enrollment is set on Insert
	 * @parm:           NA
	 * @return:         NA
	 */
	@isTest
	static void testEnrollmentContactLookupOnInsertNegative() {
		intellumapp__IntellumActivity__c objCourse = [SELECT Id FROM intellumapp__IntellumActivity__c WHERE intellumapp__id__c = 1234];
		intellumapp__IntellumUser__c objUser = [SELECT Id FROM intellumapp__IntellumUser__c WHERE intellumapp__id__c = 99999];
		Contact objContact = [SELECT Id FROM Contact WHERE UUID__c = '5GTRD_GT643'];
		objContact.UUID__c = '5GTRD_GT6465';
		update objContact;

		Test.startTest();
		intellumapp__IntellumEnrollment__c objEnrollment = new TestDataFactory.IntellumEnrollmentBuilder().setId(545232).setUser(objUser.Id).setActivity(objCourse.Id).build();
		insert objEnrollment;
		objEnrollment.intellumapp__status__c = 'passed';
		update objEnrollment;
		Test.stopTest();

		intellumapp__IntellumEnrollment__c objEnrollmentAssert = [SELECT Id, Contact__C FROM intellumapp__IntellumEnrollment__c WHERE intellumapp__id__c = 545232];
		System.assertNotEquals(objContact.Id, objEnrollmentAssert.Contact__c);
	}

	/**
	 * @author       Prity Kumari
	 * @description  Test if exceptions are logged
	 **/
	public static void checkForExceptions(Boolean blnHasException) {
		// Assert exceptions are logged from Task Trigger
		Integer intExceptions = [SELECT COUNT() FROM Exception_Log__c WHERE Class_Name__c IN ('LMSEnrollmentTriggerHelper', 'LMSEnrollmentTriggerHandler')];
		if (blnHasException) {
			System.assertNotEquals(0, intExceptions);
		} else {
			System.assertEquals(0, intExceptions);
		}
	}
}