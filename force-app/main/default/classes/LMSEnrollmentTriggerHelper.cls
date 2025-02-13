/*
 * @name         LMSEnrollmentTriggerHelper
 * @author       Prity Kumari
 * @date         2022-07-19
 * @description  Handles multiple context events related to intellumapp__IntellumEnrollment__c records
 * @test classes LMSEnrollmentTriggerHelperTest
 */
public with sharing class LMSEnrollmentTriggerHelper {
	public static Boolean blnSkipTrigger = false; // Skip Trigger Flag
	//All sets initialized
	public Set<Id> set_IntellumUser;
	public Set<String> set_UUID;
	public Set<Id> set_AccountIds;

	//All maps initialized
	public Map<Id, Contact> map_ContactUpdate;
	public Map<Id, Intellumapp__IntellumUser__c> map_UUID;
	public static Map<String, Contact> map_UUIDContacts = new Map<String, Contact>();
	public Map<Id, Account> map_AccountIdToObjAccount;
	public Map<Id, Account> map_AccountsToUpdate;

	public LMSEnrollmentTriggerHelper() {
		//All sets initialized
		set_IntellumUser = new Set<Id>();
		set_UUID = new Set<String>();
		set_AccountIds = new Set<Id>();

		//All maps initialized
		map_ContactUpdate = new Map<Id, Contact>();
		map_UUID = new Map<Id, Intellumapp__IntellumUser__c>();
		map_AccountIdToObjAccount = new Map<Id, Account>();
		map_AccountsToUpdate = new Map<Id, Account>();
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    processBeforeInsert
	 * @parm:           List of new enrollments from Trigger.new
	 * @return:         NA
	 */
	public void processBeforeInsert(List<intellumapp__IntellumEnrollment__c> list_Enrollments) {
		// Create Collections Before
		createCollectionsBefore(list_Enrollments);

		// Iterating over list of new records, updating Contact lookup based on UUID/ Code on Intellum
		for (intellumapp__IntellumEnrollment__c objEnrollment : list_Enrollments) {
			setContact(objEnrollment);
		}
	}
	/*
	 * @author:         Prity Kumari
	 * @description:    processAfterInsert
	 * @parm:           List of new enrollments from Trigger.new
	 * @return:         NA
	 */
	public void processAfterInsert(List<intellumapp__IntellumEnrollment__c> list_Enrollments) {
		//set contact certification values
		setContactValues();
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    processBeforeUpdate
	 * @parm:           List of new enrollments from Trigger.new
	 * @parm:           Map of old enrollments from Trigger.oldMap
	 * @return:         NA
	 */
	public void processBeforeUpdate(List<intellumapp__IntellumEnrollment__c> list_Enrollments, Map<Id, intellumapp__IntellumEnrollment__c> map_OldEnrollments) {
		List<intellumapp__IntellumEnrollment__c> list_EnrollmentContact = new List<intellumapp__IntellumEnrollment__c>();

		// Create Collections Before
		createCollectionsBefore(list_Enrollments);

		for (intellumapp__IntellumEnrollment__c objEnrollment : list_Enrollments) {
			if (objEnrollment.Contact__c == null) {
				setContact(objEnrollment);
			}
		}
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    processAfterUpdate
	 * @parm:           List of new enrollments from Trigger.new
	 * @parm:           Map of old enrollments from Trigger.oldMap
	 * @return:         NA
	 */
	public void processAfterUpdate(List<intellumapp__IntellumEnrollment__c> list_Enrollments, Map<Id, intellumapp__IntellumEnrollment__c> map_OldEnrollments) {
		//set contact certification values
		setContactValues();
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    creating Collections needed for Before Trigger Context
	 * @parm:           List of new enrollments from Trigger.new
	 * @return:         NA
	 */
	public void createCollectionsBefore(List<intellumapp__IntellumEnrollment__c> list_Enrollments) {
		for (intellumapp__IntellumEnrollment__c objEnroll : list_Enrollments) {
			set_IntellumUser.add(objEnroll.intellumapp__IntellumUser__c);
		}
		for (intellumapp__IntellumUser__c objUser : [SELECT Id, intellumapp__code__c FROM intellumapp__IntellumUser__c WHERE Id IN :set_IntellumUser]) {
			if (String.isNotBlank(objUser.intellumapp__code__c)) {
				map_UUID.put(objUser.ID, objUser);
				set_UUID.add(objUser.intellumapp__code__c);
			}
		}

		for (Contact objContact : [SELECT Id, UUID__c, AccountId, Inactive_ZP_User__c FROM Contact WHERE UUID__c IN :set_UUID AND Inactive_ZP_User__c = FALSE]) {
			map_UUIDContacts.put(objContact.UUID__c, objContact);
		}
	}
	/*
	 * @author:         Prity Kumari
	 * @description:    reating Collections needed for Before Trigger Context
	 * @parm:           List of new enrollments from Trigger.new
	 * @return:         NA
	 */
	public void createCollectionsAfter(Set<Id> set_AccountIds) {
		if (!set_AccountIds.isEmpty()) {
			map_AccountIdToObjAccount = new Map<Id, Account>(
				[
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
							WHERE Inactive_ZP_User__c = FALSE
							ORDER BY CreatedDate ASC
						)
					FROM Account
					WHERE Id IN :set_AccountIds
				]
			);
		}
	}
	/*
	 * @author:         Prity Kumari
	 * @description:    set contact lookup on enrollments
	 * @parm:           List of new enrollments from Trigger.new
	 * @parm:           Map of old enrollments from Trigger.oldMap
	 * @return:         NA
	 */
	public void setContact(intellumapp__IntellumEnrollment__c objNewEnrollment) {
		if (map_UUID?.containsKey(objNewEnrollment.intellumapp__IntellumUser__c)) {
			intellumapp__IntellumUser__c objUser = map_UUID.get(objNewEnrollment.intellumapp__IntellumUser__c);
			objNewEnrollment.Contact__c = map_UUIDContacts?.get(objUser.intellumapp__code__c)?.Id;
		}
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    set contact certification values
	 * @return:         NA
	 */
	public void setContactValues() {
		Date dtCompleted = null;
		Boolean blnPEEnrollmentPassed = false;
		Boolean blnPAEnrollmentPassed = false;
		Boolean blnPMEnrollmentPassed = false;
		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
		List<String> list_Status = new List<String>();
		List<String> list_Courses = new List<String>();
		list_Status = Label.Enrollment_Status.split(',');
		list_Courses = Label.Getting_Started_With_Gusto_Pro.split(',');
		for (intellumapp__IntellumEnrollment__c objEnroll : [
			SELECT
				Id,
				Contact__r.UUID__c,
				Contact__r.AccountId,
				Contact__r.Inactive_ZP_User__c,
				Contact__r.Accountant_Certified_Date__c,
				Contact__r.Accountant_Certifications_Status__c,
				intellumapp__IntellumActivity__r.intellumapp__custom_a__c,
				intellumapp__IntellumActivity__r.intellumapp__custom_c__c,
				intellumapp__enrolled_on__c,
				intellumapp__completed_on__c,
				intellumapp__last_opened_on__c,
				intellumapp__started_on__c,
				intellumapp__status__c,
				intellumapp__IntellumActivity__r.Name,
				intellumapp__IntellumActivity__r.intellumapp__id__c
			FROM intellumapp__IntellumEnrollment__c
			WHERE Contact__r.UUID__c IN :map_UUIDContacts.keyset() AND (intellumapp__expires_on__c = NULL OR intellumapp__expires_on__c > TODAY) AND Contact__r.Inactive_ZP_User__c = FALSE
			ORDER BY Contact__c, intellumapp__last_opened_on__c
		]) {
			Contact objContact = map_UUIDContacts.get(objEnroll.Contact__r.UUID__c);
			if (objContact != null) {
				if (!map_ContactUpdate?.containsKey(objContact.Id)) {
					blnPEEnrollmentPassed = false;
					blnPAEnrollmentPassed = false;
					blnPMEnrollmentPassed = false;
					objContact.Completed_Getting_Started_With_Gusto_Pro__c = false;
					objContact.Accountant_Certifications_Status__c = '';
					objContact.Gusto_Payroll_Certification_Status__c = '';
					objContact.People_advisory_Certification_Status__c = '';
					objContact.Accountant_Accelerator_Status__c = '';
					objContact.Accountant_Certified_Date__c = null;
					objContact.accountant_accelerator_completion_date__c = null;
					objContact.accountant_gusto_payroll_completion_date__c = null;
					objContact.accountant_people_advisory_complete_date__c = null;
					objContact.people_advisory_lastopened_date__c = null;
					objContact.accelerator_lastopened_date__c = null;
					objContact.gusto_payroll_lastopened_date__c = null;
					objContact.people_advisory_start_date__c = null;
					objContact.accelerator_start_date__c = null;
					objContact.gusto_payroll_start_date__c = null;
				}
				if (
					list_Courses.contains(String.valueOf(objEnroll.intellumapp__IntellumActivity__r?.intellumapp__id__c)) &&
					String.isNotBlank(objEnroll.intellumapp__status__c) &&
					list_Status.contains(objEnroll.intellumapp__status__c) &&
					!objContact.Completed_Getting_Started_With_Gusto_Pro__c
				) {
					objContact.Completed_Getting_Started_With_Gusto_Pro__c = true;
				}
				if (
					String.isNotBlank(objEnroll.intellumapp__IntellumActivity__r?.intellumapp__custom_a__c) &&
					String.isNotBlank(objEnroll.intellumapp__status__c) &&
					objEnroll.intellumapp__IntellumActivity__r?.intellumapp__custom_c__c == ContactUtil.PROGRAM_TYPE_CERTIFICATION
				) {
					if (
						(String.isBlank(objContact.Accountant_Certifications_Status__c) ||
						(ContactUtil.map_Status.get(objContact.Accountant_Certifications_Status__c?.toLowercase()) < ContactUtil.map_Status.get(objEnroll.intellumapp__status__c?.toLowercase())))
					) {
						objContact.Accountant_Certifications_Status__c = objEnroll.intellumapp__status__c?.toLowercase();
					}
					// If enrollement status is passed, take the earliest date completed and stamp it on Contact
					if (objEnroll.intellumapp__completed_on__c != null) {
						// Convert Date/Time to Date
						dtCompleted = Date.newInstance(objEnroll.intellumapp__completed_on__c.year(), objEnroll.intellumapp__completed_on__c.month(), objEnroll.intellumapp__completed_on__c.day());
						if (objContact.Accountant_Certified_Date__c == null || dtCompleted < objContact.Accountant_Certified_Date__c) {
							objContact.Accountant_Certified_Date__c = dtCompleted;
						}
					}
					//values for payroll essentials
					if (objEnroll.intellumapp__IntellumActivity__r.intellumapp__custom_a__c.contains(ContactUtil.LT_PAYROLL_ESSENTIAL)) {
						if (objContact.Gusto_Payroll_Certification_Status__c != objEnroll.intellumapp__status__c && !blnPEEnrollmentPassed) {
							objContact.Gusto_Payroll_Certification_Status__c = objEnroll.intellumapp__status__c;
							blnPEEnrollmentPassed = list_Status.contains(objEnroll.intellumapp__status__c) ? true : false;
						}
						if (objEnroll.intellumapp__last_opened_on__c != null) {
							objContact.gusto_payroll_lastopened_date__c = Date.newInstance(
								objEnroll.intellumapp__last_opened_on__c.year(),
								objEnroll.intellumapp__last_opened_on__c.month(),
								objEnroll.intellumapp__last_opened_on__c.day()
							);
						}
						if (objEnroll.intellumapp__started_on__c != null) {
							Date dtOpened = Date.newInstance(objEnroll.intellumapp__started_on__c.year(), objEnroll.intellumapp__started_on__c.month(), objEnroll.intellumapp__started_on__c.day());
							objContact.gusto_payroll_start_date__c = objContact.gusto_payroll_start_date__c == null ||
								objContact.gusto_payroll_start_date__c > dtOpened
								? dtOpened
								: objContact.gusto_payroll_start_date__c;
						}
						if (objEnroll.intellumapp__completed_on__c != null && list_Status.contains(objEnroll.intellumapp__status__c)) {
							// Convert Date/Time to Date
							Date dtPECompleted = Date.newInstance(
								objEnroll.intellumapp__completed_on__c.year(),
								objEnroll.intellumapp__completed_on__c.month(),
								objEnroll.intellumapp__completed_on__c.day()
							);
							if (objContact.accountant_gusto_payroll_completion_date__c == null || dtPECompleted < objContact.accountant_gusto_payroll_completion_date__c) {
								objContact.accountant_gusto_payroll_completion_date__c = dtPECompleted;
							}
						}
						//values for people advisory
					} else if (objEnroll.intellumapp__IntellumActivity__r.intellumapp__custom_a__c.contains(ContactUtil.LT_PEOPLE_ADVISORY)) {
						if (objContact.People_advisory_Certification_Status__c != objEnroll.intellumapp__status__c && !blnPAEnrollmentPassed) {
							objContact.People_advisory_Certification_Status__c = objEnroll.intellumapp__status__c;
							blnPAEnrollmentPassed = list_Status.contains(objEnroll.intellumapp__status__c) ? true : false;
						}
						if (objEnroll.intellumapp__started_on__c != null) {
							Date dtOpened = Date.newInstance(objEnroll.intellumapp__started_on__c.year(), objEnroll.intellumapp__started_on__c.month(), objEnroll.intellumapp__started_on__c.day());
							objContact.people_advisory_start_date__c = objContact.people_advisory_start_date__c == null ||
								objContact.people_advisory_start_date__c > dtOpened
								? dtOpened
								: objContact.people_advisory_start_date__c;
						}
						if (objEnroll.intellumapp__last_opened_on__c != null) {
							objContact.people_advisory_lastopened_date__c = Date.newInstance(
								objEnroll.intellumapp__last_opened_on__c.year(),
								objEnroll.intellumapp__last_opened_on__c.month(),
								objEnroll.intellumapp__last_opened_on__c.day()
							);
						}
						if (objEnroll.intellumapp__completed_on__c != null && list_Status.contains(objEnroll.intellumapp__status__c)) {
							// Convert Date/Time to Date
							Date dtPACompleted = Date.newInstance(
								objEnroll.intellumapp__completed_on__c.year(),
								objEnroll.intellumapp__completed_on__c.month(),
								objEnroll.intellumapp__completed_on__c.day()
							);
							if (objContact.accountant_people_advisory_complete_date__c == null || dtPACompleted < objContact.accountant_people_advisory_complete_date__c) {
								objContact.accountant_people_advisory_complete_date__c = dtPACompleted;
							}
						}
					} else if (objEnroll.intellumapp__IntellumActivity__r.intellumapp__custom_a__c.contains(ContactUtil.LT_PRACTICE_MANAGEMENT)) {
						if (objContact.Accountant_Accelerator_Status__c != objEnroll.intellumapp__status__c && !blnPMEnrollmentPassed) {
							objContact.Accountant_Accelerator_Status__c = objEnroll.intellumapp__status__c;
							blnPMEnrollmentPassed = list_Status.contains(objEnroll.intellumapp__status__c) ? true : false;
						}
						if (objEnroll.intellumapp__started_on__c != null) {
							Date dtOpened = Date.newInstance(objEnroll.intellumapp__started_on__c.year(), objEnroll.intellumapp__started_on__c.month(), objEnroll.intellumapp__started_on__c.day());
							objContact.accelerator_start_date__c = objContact.accelerator_start_date__c == null ||
								objContact.accelerator_start_date__c > dtOpened
								? dtOpened
								: objContact.accelerator_start_date__c;
						}
						if (objEnroll.intellumapp__last_opened_on__c != null) {
							objContact.accelerator_lastopened_date__c = Date.newInstance(
								objEnroll.intellumapp__last_opened_on__c.year(),
								objEnroll.intellumapp__last_opened_on__c.month(),
								objEnroll.intellumapp__last_opened_on__c.day()
							);
						}
						if (objEnroll.intellumapp__completed_on__c != null && list_Status.contains(objEnroll.intellumapp__status__c)) {
							// Convert Date/Time to Date
							Date dtPMCompleted = Date.newInstance(
								objEnroll.intellumapp__completed_on__c.year(),
								objEnroll.intellumapp__completed_on__c.month(),
								objEnroll.intellumapp__completed_on__c.day()
							);
							if (objContact.accountant_accelerator_completion_date__c == null || dtPMCompleted < objContact.accountant_accelerator_completion_date__c) {
								objContact.accountant_accelerator_completion_date__c = dtPMCompleted;
							}
						}
					}
				}
				map_ContactUpdate.put(objContact.Id, objContact);
				if (objContact.AccountId != null)
					set_AccountIds.add(objContact.AccountId);
			}
		}
		TriggerHandler.bypass(new List<String>{ 'ContactTriggerHandler', 'AccountTriggerHandler' });
		if (!map_ContactUpdate.values().isEmpty()) {
			List<Database.SaveResult> saveResult = Database.update(map_ContactUpdate.values(), false);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, map_ContactUpdate.values(), 'Id', true, 'LMSEnrollmentTriggerHelper-processAfterInsert-updatecontact');
			//Update Number of Contacts Certified and In Progress at Account Level
			createCollectionsAfter(set_AccountIds);
			for (Contact objContact : map_ContactUpdate.values()) {
				setAccountCertificationInformation(objContact);
			}
			if (!map_AccountsToUpdate.values().isEmpty()) {
				List<Database.SaveResult> result = Database.update(map_AccountsToUpdate.values(), false);
				dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, map_AccountsToUpdate.values(), 'Id', true, 'LMSEnrollmentTriggerHelper-processAfterInsert-updateAccount');
			}
		}
		TriggerHandler.clearAllBypasses();
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    set account certification values
	 * @return:         NA
	 */
	/**** Update Number of Contacts Certified and In Progress at Account Level ****/
	public void setAccountCertificationInformation(Contact objNewContact) {
		// Check if Account Map has Contact's Account Id
		if (map_AccountIdToObjAccount.containsKey(objNewContact.AccountId)) {
			// Declare total variables
			Date dtCertified = null;
			Integer intTotalAccountants = 0;
			Integer intTotalContacts = 0;
			Integer intTotalPayrollCertified = 0;
			Integer intTotalAdvisoryCertified = 0;
			Integer intTotalAcceleratorCertified = 0;
			Integer intTotalGettingStartedWitGustoProCertified = 0;
			Integer intTotalAccountantCertified = 0;
			Integer intTotalUsersCertified = 0;
			String strFirmCertificationStatus = '';
			String strPayrollEssentialsCertificationStatus = '';
			String strPeopleAdvisoryCertificationStatus = '';
			String strAcceleratorCertificationStatus = '';

			// Fetch the Account
			Account objAccount = map_AccountIdToObjAccount.get(objNewContact.AccountId);
			List<String> list_EnrollmentStatus = Label.Enrollment_Status.split(',');

			// Iterate over contact's Accounts
			for (Contact objEachContact : objAccount.Contacts) {
				if (!objEachContact.Inactive_ZP_User__c) {
					intTotalContacts++;
					if (String.isNotBlank(objEachContact.Accountant_Certifications_Status__c) && list_EnrollmentStatus.contains(objEachContact.Accountant_Certifications_Status__c)) {
						intTotalUsersCertified++;
					}
					//calculating only for accountants
					if (objEachContact.ZP_User_Role__c != null && objEachContact.ZP_User_Role__c.contains('Accountant')) {
						// Increase total number of contacts
						intTotalAccountants++;

						// Check Certification Status and increase count respectively
						if (String.isNotBlank(objEachContact.Gusto_Payroll_Certification_Status__c)) {
							intTotalPayrollCertified = list_EnrollmentStatus.contains(objEachContact.Gusto_Payroll_Certification_Status__c) ? ++intTotalPayrollCertified : intTotalPayrollCertified;
							strPayrollEssentialsCertificationStatus = (ContactUtil.map_Status.get(objEachContact?.Gusto_Payroll_Certification_Status__c?.toLowercase()) >
								ContactUtil.map_Status.get(strPayrollEssentialsCertificationStatus?.toLowercase()))
								? objEachContact.Gusto_Payroll_Certification_Status__c
								: strPayrollEssentialsCertificationStatus;
						}
						if (String.isNotBlank(objEachContact.People_advisory_Certification_Status__c)) {
							intTotalAdvisoryCertified = list_EnrollmentStatus.contains(objEachContact.People_advisory_Certification_Status__c)
								? ++intTotalAdvisoryCertified
								: intTotalAdvisoryCertified;
							strPeopleAdvisoryCertificationStatus = (ContactUtil.map_Status.get(objEachContact?.People_advisory_Certification_Status__c?.toLowercase()) >
								ContactUtil.map_Status.get(strPeopleAdvisoryCertificationStatus?.toLowercase()))
								? objEachContact.People_advisory_Certification_Status__c
								: strPeopleAdvisoryCertificationStatus;
						}
						if (String.isNotBlank(objEachContact.Accountant_Accelerator_Status__c)) {
							intTotalAcceleratorCertified = list_EnrollmentStatus.contains(objEachContact.Accountant_Accelerator_Status__c)
								? ++intTotalAcceleratorCertified
								: intTotalAcceleratorCertified;
							strAcceleratorCertificationStatus = (ContactUtil.map_Status.get(objEachContact?.Accountant_Accelerator_Status__c?.toLowercase()) >
								ContactUtil.map_Status.get(strAcceleratorCertificationStatus?.toLowercase()))
								? objEachContact.Accountant_Accelerator_Status__c
								: strAcceleratorCertificationStatus;
						}

						if (objEachContact.Completed_Getting_Started_With_Gusto_Pro__c) {
							intTotalGettingStartedWitGustoProCertified++;
						}
						if (String.isNotBlank(objEachContact?.Accountant_Certifications_Status__c)) {
							intTotalAccountantCertified = list_EnrollmentStatus.contains(objEachContact.Accountant_Certifications_Status__c)
								? ++intTotalAccountantCertified
								: intTotalAccountantCertified;
							strFirmCertificationStatus = (ContactUtil.map_Status.get(objEachContact?.Accountant_Certifications_Status__c?.toLowercase()) >
								ContactUtil.map_Status.get(strFirmCertificationStatus?.toLowercase()))
								? objEachContact.Accountant_Certifications_Status__c?.toLowerCase()
								: strFirmCertificationStatus?.toLowercase();
						}

						if ((dtCertified == null && objEachContact.accountant_certified_date__c != null) || dtCertified > objEachContact.Accountant_Certified_Date__c) {
							dtCertified = objEachContact.Accountant_Certified_Date__c;
						}
					}
				}
			}

			// check if any contacts have completed certifications
			if (intTotalContacts > 0) {
				Account objAccountToUpdate = map_AccountsToUpdate.containsKey(objAccount.Id) ? map_AccountsToUpdate.get(objAccount.Id) : new Account(Id = objAccount.Id);
				Boolean blnUpdateAccount = false;

				// Calculate percentage of contacts related to an account that have completed a specific certification
				Decimal decPercentagePayrollCert = 0;
				Decimal decPercentageAcceleratorCert = 0;
				Decimal decPercentageAdvisoryCert = 0;
				Decimal decGettingStartedWitGustoProCert = 0;

				if (intTotalAccountants > 0) {
					decPercentagePayrollCert = intTotalPayrollCertified > 0 ? ((Decimal) intTotalPayrollCertified / (Decimal) intTotalAccountants) * 100 : 0;
					decPercentageAdvisoryCert = intTotalAdvisoryCertified > 0 ? ((Decimal) intTotalAdvisoryCertified / (Decimal) intTotalAccountants) * 100 : 0;
					decPercentageAcceleratorCert = intTotalAcceleratorCertified > 0 ? ((Decimal) intTotalAcceleratorCertified / (Decimal) intTotalAccountants) * 100 : 0;
					decGettingStartedWitGustoProCert = intTotalGettingStartedWitGustoProCertified > 0
						? ((Decimal) intTotalGettingStartedWitGustoProCertified / (Decimal) intTotalAccountants) * 100
						: 0;
				}
				// check if Gusto Payroll certification percentage has changed
				if (objAccount.of_accountants_cert_Gusto_Payroll__c != decPercentagePayrollCert && decPercentagePayrollCert != null) {
					objAccountToUpdate.of_accountants_cert_Gusto_Payroll__c = decPercentagePayrollCert;
					blnUpdateAccount = true;
				}
				// check if Gusto Accelerator certification percentage has changed
				if (objAccount.of_accountants_cert_Accelerator__c != decPercentageAcceleratorCert && decPercentageAcceleratorCert != null) {
					objAccountToUpdate.of_accountants_cert_Accelerator__c = decPercentageAcceleratorCert;
					blnUpdateAccount = true;
				}
				// check if Gusto Advisory certification percentage has changed
				if (objAccount.of_accountants_cert_People_Advisory__c != decPercentageAdvisoryCert && decPercentageAdvisoryCert != null) {
					objAccountToUpdate.of_accountants_cert_People_Advisory__c = decPercentageAdvisoryCert;
					blnUpdateAccount = true;
				}
				// check if Getting_started_with_gusto_pro__c percentage has changed
				if (objAccount.Getting_started_with_gusto_pro__c != decGettingStartedWitGustoProCert && decGettingStartedWitGustoProCert != null) {
					objAccountToUpdate.Getting_started_with_gusto_pro__c = decGettingStartedWitGustoProCert;
					blnUpdateAccount = true;
				}
				// check if firm certification status has changed
				if (strFirmCertificationStatus != objAccountToUpdate.Accounting_Firm_Certification_Status__c) {
					objAccountToUpdate.Accounting_Firm_Certification_Status__c = strFirmCertificationStatus;
					blnUpdateAccount = true;
				}
				if (strPayrollEssentialsCertificationStatus != objAccountToUpdate.firm_payroll_essentials_status__c) {
					objAccountToUpdate.firm_payroll_essentials_status__c = strPayrollEssentialsCertificationStatus;
					blnUpdateAccount = true;
				}
				if (strPeopleAdvisoryCertificationStatus != objAccountToUpdate.firm_people_advisory_status__c) {
					objAccountToUpdate.firm_people_advisory_status__c = strPeopleAdvisoryCertificationStatus;
					blnUpdateAccount = true;
				}
				if (strAcceleratorCertificationStatus != objAccountToUpdate.firm_accelerator_status__c) {
					objAccountToUpdate.firm_accelerator_status__c = strAcceleratorCertificationStatus;
					blnUpdateAccount = true;
				}
				// check if Getting_started_with_gusto_pro__c percentage has changed
				if (objAccount.Num_Accountants_At_Firm__c != intTotalAccountants) {
					objAccountToUpdate.Num_Accountants_At_Firm__c = intTotalAccountants;
					blnUpdateAccount = true;
				}
				if (objAccount.Num_Accountants_Certified__c != intTotalAccountantCertified) {
					objAccountToUpdate.Num_Accountants_Certified__c = intTotalAccountantCertified;
					blnUpdateAccount = true;
				}

				if (objAccount.num_total_users__c != intTotalContacts) {
					objAccountToUpdate.num_total_users__c = intTotalContacts;
					blnUpdateAccount = true;
				}
				if (objAccount.num_users_certified__c != intTotalUsersCertified) {
					objAccountToUpdate.num_users_certified__c = intTotalUsersCertified;
					blnUpdateAccount = true;
				}
				if (objAccount.firm_certified_date__c != dtCertified) {
					objAccountToUpdate.firm_certified_date__c = dtCertified;
					blnUpdateAccount = true;
				}
				if (blnUpdateAccount) {
					map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
				}
			}
		}
	}
}