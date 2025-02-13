/*
 * @name         ZPCompanyUtil
 * @author       Praveen Sethu
 * @date         08-10-2021
 * @description  Utility class to store list of constant variables and re-usuable methods.
 * @test classes ZPCompanyTriggerHelperTest
 */

public with sharing class ZPCompanyUtil {
	public final static String BILLING_PARTNER_BILLED = 'partner_billed';
	public final static String BILLING_CLIENT_BILLED = 'client_billed';
	public final static String BILLING_ACCOUNTANT_BILLED = 'Accountant Billed';
	public final static String CLIENT_BILLED = 'Client Billed';

	public static final String LEAD_CONVERSION = 'LeadConversion';
	public static final String LEAD_NAME_NA = 'NA';

	public static final String ONBOARDING_COMPANIES_SERVICE = 'onboarding_companies_service';
	public static final String UNSURE = 'Unsure';
	public static final String ASAP = 'ASAP';
	public static final String SMALL_GROUP_HEALTH_INSURANCE = 'SMALL_GROUP_HEALTH_INSURANCE';
	public static final String MANUALLY_ENQUEUE_STATE = 'Manually Enqueued';
	public static final String LAST_NAME_NA = 'NA';
	public static final String PRIORITY_SUPPORT_EXPERIMENT_FLAT_FEE = 'priority_support_flat_fee_$120';
	public static final String ASYNC_LEAD_CONVERSION_PENDING = 'Async Lead Conversion Pending';
	public static final String RETRY_STATUS = 'Retry';

	// NOTE: please add fields as all lower case
	public static final List<String> set_AllowChangeFields = Label.ZP_Company_Allow_Change_Fields.toLowerCase().split(',');
	public static final Set<String> set_InactiveStatus = new Set<String>{ IntegrationUtils.ERROR_STATE, IntegrationUtils.DEAD_STATE, IntegrationUtils.BACKLOG, RETRY_STATUS };
	public static final String INTERNATIONAL_PAYROLL_LOG_A_CALL = 'international_payroll_logacall';
}