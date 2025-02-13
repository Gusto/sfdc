/**
 * @name         : GFTicketUtil
 * @author       : Alex Xiong
 * @date         : 04/20/2021
 * @description  : The utility class for GF Tickets
 * @test classes : GFTicketTriggerHelperTest
 **/
public class GFTicketUtil {
	//Case Types
	public final static String DEFER_REPAYMENT_CASE_TYPE = 'Defer Repayment';
	public final static String EOY_SPOT_CHECK_CASE_TYPE = 'EOY Spot Check';
	public final static String SHAREHOLDER_AUDIT_CASE_TYPE = 'Shareholder Audit';
	public final static String DOCUMENT_MAPPING_CASE_TYPE = 'Document Mapping';
	public final static String PAYROLL_CASE_TYPE = 'Payroll';

	//Case Reasons
	public final static String ACH_FAILURE_REASON = 'ACH Failure';
	public final static String EOY_SPOT_CHECK_SQUAD_ACTION_REQUIRED_REASON = 'EoY Spot Check Squad Action Required';
	public final static String SUSPEND_ACCOUNT_REASON = 'Suspend Account';
	public final static String BACKDATEDADDRESSCHANGE_REASON = 'Backdated Employee Address Change';
	public final static String BACKDATEDADDRESSCHANGE_REASONCODE = 'backdated_employee_address_change';

	//Case Origins
	public final static String GUSTO_ORIGIN = 'Gusto';
	public final static String HIPPO_ORIGIN = 'Hippo';
	public final static String GUSTO_WALLET_ORIGIN = 'Gusto Wallet';

	// Case Pillar
	public final static String TYPE_PAYROLL = 'Payroll';
	public final static String TYPE_BENEFITS = 'Benefits';
	public final static String TYPE_TAXES = 'Taxes';

	// Support Levels
	public final static String SUPPORTLEVEL_TIER1 = 'Tier 1';
	public final static String SUPPORTLEVEL_TIER2 = 'Tier 2';
	
	//Case Record Type Names
	public final static String ENGAGEMENT_RECORD_TYPE = 'Engagement';
	public final static String PAYROLL_CARE_RECORD_TYPE = 'Payroll Care';
	public final static String BENEFITS_CARE_RECORD_TYPE = 'Benefits Care';
	public final static String PAYROLL_TRANSFER_CASE_RECORD_TYPE = 'Payroll Transfer Case';
	public final static String TAX_RES_CASE_RECORD_TYPE = 'Tax Res';
	public final static String MODERN_BANK_CASE_RECORD_TYPE = 'Modern Bank';

	//Ticket Tags
	public final static String IN_APP_SUSPENSION_TAG = 'in_app_suspension_request';

	//Ticket Types
	public final static String EOY_SPOT_CHECK_TICKET_TYPE = 'eoy_spot_check';
	public final static String SUPPORT_FORM_TICKET_TYPE = 'support_form';
	public final static String DOCUMENT_MAPPING_TICKET_TYPE = 'document_mapping';
	public final static String ACH_UPDATE_FAILED_TICKET_TYPE = 'ach_update_failed';
	public final static String DEFER_PAYMENTS_TICKET_TYPE = 'defer_payments';
	public final static String ADDRESS_CHANGE_TICKET_TYPE = 'backdated_address_changes';

	//Record Type Ids. From Cache class
	public final static Id ENGAGEMENT_RT_ID = Cache.getRecordTypeId('Case', ENGAGEMENT_RECORD_TYPE);
	public final static Id PAYROLL_CARE_RT_ID = Cache.getRecordTypeId('Case', PAYROLL_CARE_RECORD_TYPE);
	public final static Id BENEFITS_CARE_RT_ID = Cache.getRecordTypeId('Case', BENEFITS_CARE_RECORD_TYPE);
	public final static Id PAYROLL_TRANSFER_CASE_RT_ID = Cache.getRecordTypeId('Case', PAYROLL_TRANSFER_CASE_RECORD_TYPE);
	public final static Id MODERN_BANK_RT_ID = Cache.getRecordTypeId('Case', MODERN_BANK_CASE_RECORD_TYPE);

	//Queue Developer Names
	public final static String DEFAULT_ROUTING_QUEUE = 'Default_Routing_Queue';
}