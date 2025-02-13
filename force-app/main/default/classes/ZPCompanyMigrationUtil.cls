/**
    Created by : Anand K Singh
    Created Date : 28/12/2021
    Description: ZPCompany related Utilities for reuse
**/
public class ZPCompanyMigrationUtil {
	public final static Id COMPANYMIGRATION_ORDER_RT_ID = Cache.getRecordTypeId('Order', 'Company Migration');
	public final static Id COMPANY_OPPORTUNITY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
	public static final Id RECTYPE_PAYROLL_TRANSFER_CASE = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
	public static final String STATUS_CLOSED_PAYROLL_RUN = 'Closed: Payroll Run';
	public static final String STATUS_CLOSED_CANCELED = 'Closed: Canceled';
	public static final String TYPE_NEW_CUSTOMER_ONBOARDING = 'New Customer Onboarding';
	public static final String MSG_PROCESSED = 'Processed';
}