/**
 * @description  ZPUserRoleUtil - used for commonly used constants in ZPUserRoleTriggerHelper
 * @author       Praveen Sethu
 * @date         02-12-2021
 * @see          ZPUserRoleTriggerHelper
 **/
public with sharing class ZPUserRoleUtil {
	public static final String HAS_ACCOUNTANT_INTERNAL = 'Internal';
	public static final String HAS_ACCOUNTANT_EXTERNAL = 'External';
	public static final String HAS_ACCOUNTANT_INTERNAL_EXTERNAL = 'Internal + External';
	public static final String DEFAULT_LAST_NAME = '-';
	public static final String TIER_UPDATE_NOT_PROCESSED = 'Not Processed';
	public static final String TIER_UPDATE_PROCESSED = 'Processed';

	// Different role names
	public static final String PRIMARY_PAYROLL_ADMIN = 'Primary Payroll Admin';
	public static final String PAYROLL_ADMIN = 'Payroll Admin';
	public static final String BENEFIT_SIGNATORY = 'Benefits Signatory';
	public static final String SIGNATORY = 'Signatory';
	public static final String BENEFITS_ADMIN = 'Benefits Admin';
	public static final String ACCOUNTANT = 'Accountant';
	public static final String EMPLOYEE = 'Employee';
	public static final String CONTRACTOR = 'Contractor';
	public static final String OTHER_EXTERNAL_COLLABORATOR = 'Other External Collaborator';
	public static final String EXTERNAL_ACCOUNTANT = 'External Accountant';
	public static final String EXTERNAL_BOOKKEEPER = 'External Bookkeeper';
	public static final String INTERNATIONAL_CONTRACTOR = 'International Contractor';
	public static final String INTERNATIONALCONTRACTOR = 'InternationalContractor';
	public static final String COMPANY_MEMBER = 'Company Member';
	public static final String INTERNATIONAL_EMPLOYEE = 'International Employee';
	public static final String INTERNATIONALEMPLOYEE = 'InternationalEmployee';

	// Type
	public static final String TYPE_ROLE_PAYROLL_ADMIN = 'Role::PayrollAdmin';
	public static final String TYPE_ROLE_ACCOUNTANT = 'Role::Accountant';
	public static final String TYPE_INTERNATIONAL_CONTRACTOR = 'Role::InternationalContractor';

	// All error messages
	public static final String USER_ID_MISSING_ON_USER_ROLE = 'User Id is missing on ZP User Role';
	public static final String USER_ID_DOES_NOT_EXIST_IN_ZP_USER = 'User does not exist in ZP User object';
	public static final String USER_DOES_NOT_HAVE_EMAIL = 'User does not have an email';
	public static final String COMPANY_ID_DOES_NOT_EXIST = 'Company Id does not exist';
	public static final String ACC_FIRM_DOES_NOT_EXIST = 'Accounting Firm does not exist';
	public static final String ACC_FIRM_COMPANY_ID_MISSING = 'Accounting Firm Id and Company Id are missing on ZP User Role';
	public static final String CONTACT_ID_NOT_EXIST = 'Contact Id does not exist';
	public static final String LEAD_CONVERT_PROGRESS = 'Lead Conversion In Progress';
	public static final String LEAD_CONVERT_SUCCESSFUL = 'Lead Conversion Successful';
	public static final String LEAD_CONVERT_PENDING = 'Lead Conversion Pending';
	public static final String BACKLOG_INTERNATIONAL_CONTRACTOR = 'Backlogged due to International Contractor Role';
	public static final String INVALID_EMAIL_ADDRESS_ERROR = 'invalid email address';
	public static final String DUPLICATE = 'duplicate';
	public static final String REFERRAL_TOKEN = 'Referral_Token__c';

	// Account record types
	public static final Id ACCOUNT_COMPANY_RT_ID = Cache.getRecordTypeId('Account', 'Company');
	public static final Id ACCOUNT_RESELLER_RT_ID = Cache.getRecordTypeId('Account', 'Reseller');
	public final static Id EMBEDDED_COMPANY_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Embedded_Company');

	// Contact record types
	public static final Id CONTACT_COMPANY_RT_ID = Cache.getRecordTypeId('Contact', 'Company');
	public static final Id CONTACT_RESELLER_RT_ID = Cache.getRecordTypeId('Contact', 'Reseller');

	// Opportunity record types
	public final static Id COMPANY_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
	public final static Id BENEFITS_NEW_PLAN_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
	public final static Id BENEFITS_BOR_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
	public final static Id BENEFITS_CHANGE_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits Change');
	public final static Id BENEFITS_RENEWAL_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
	public final static Id CUSTOMER_SUCCESS_RT_ID = Cache.getRecordTypeId('Opportunity', 'Customer Success');
	public final static Id BENEFITS_BYOB_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits BYOB');
	public final static Id ACQUISITION_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Acquisition');

	// Lead record types
	public static final Id LEAD_RESELLER_RT_ID = Cache.getRecordTypeId('Lead', 'Reseller');

	// Lead sources
	public static final String LEAD_SOURCE_ABC = 'Added by Client';
}