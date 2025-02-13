public with sharing class LogSmartCallingUtil {
	public static final String LOG_SMART_CALL_CONTR_LEX_CLS = 'LogSmartCallingControllerLEX';

	public static final String SOBJECT_API_NAME_BENEFIT_ORDER = 'Benefit_Order__c';
	public static final String SOBJECT_API_NAME_ACCOUNT = 'Account';
	public static final String SOBJECT_API_NAME_OPPORTUNITY = 'Opportunity';
	public static final String SOBJECT_API_NAME_LEAD = 'Lead';
	public static final String SOBJECT_API_NAME_TICKET = 'Ticket__c';
	public static final String SOBJECT_API_NAME_PRODUCT_UPSELL = 'Partnership_Interest__c';

	public static final Id callRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId();
	public static final Id SCT_RECTYPE_BENEFITS_ONBOARDING = Cache.getRecordTypeId('Sales_Call_Tracking__c', 'Benefits Onboarding');
	public static final Id SCT_RECTYPE_SALES = Cache.getRecordTypeId('Sales_Call_tracking__c', 'Sales');

	public static final Id STANDARD_TASK_RT_ID = Cache.getRecordTypeId('Task', 'Standard');
	public static final Id CALL_TASK_RT_ID = Cache.getRecordTypeId('Task', 'Call');

	public static final Id COMPANY_OPPTY_RT_ID = Cache.getRecordTypeId(SOBJECT_API_NAME_OPPORTUNITY, 'Company Opportunity');
	public static final Id UPSELL_OPPTY_RT_ID = Cache.getRecordTypeId(SOBJECT_API_NAME_OPPORTUNITY, 'Tier Upsell Opportunity');

	public final static Id BENEFITS_NEW_PLAN_OPPTY_RT_ID = Cache.getRecordTypeId(SOBJECT_API_NAME_OPPORTUNITY, 'Benefits New Plan');
	public final static Id BENEFITS_BOR_OPPTY_RT_ID = Cache.getRecordTypeId(SOBJECT_API_NAME_OPPORTUNITY, 'Benefits BoR');
	public final static Id BENEFITS_BYOB_OPPTY_RT_ID = Cache.getRecordTypeId(SOBJECT_API_NAME_OPPORTUNITY, 'Benefits BYOB');

	public final static Id PRODUCT_UPSELL_RT_ID_CUSTOMER_SUCCESS = Cache.getRecordTypeId(SOBJECT_API_NAME_PRODUCT_UPSELL, 'Customer Success');
	public final static Id PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET = Cache.getRecordTypeId(SOBJECT_API_NAME_PRODUCT_UPSELL, 'New Partnership Interest');

	public final static Id COMPANY_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Company');
	public final static Id RESELLER_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Reseller');

	public static final String CALL_TYPE_INBOUND = 'Inbound';
	public static final String CALL_TYPE_OUTBOUND = 'Outbound';

	public static final String TASK_SUBJECT_CALL = 'Call';
	public static final String TASK_SUBJECT_FOLLOW_UP_TASK = 'Follow Up Task';

	public static final String TASK_DISPOSITION_CONNECT = 'Connect';
	public static final String TASK_DISPOSITION_NO_CALL = 'No Call';

	public static final String TASK_STATUS_ATTEMPT = 'Attempt';
	public static final String TASK_STATUS_COMPLETED = 'Completed';
	public static final String TASK_STATUS_OPEN = 'Open';
	public static final String TASK_STATUS_SCHEDULED = 'Scheduled';

	public static final String TASK_TYPE_OUTBOUND_CALL = 'Outbound Call';
	public static final String TASK_TYPE_INBOUND_CALL = 'Inbound Call';
	public static final String TASK_TYPE_EMAIL = 'Email';
	public static final String TASK_TYPE_CALL = 'Call';

	public static final String TASK_PARTNER_SALES_TYPE_ADMIN = 'Admin';

	public static final String TASK_PRIORITY_HIGH = 'High';

	public static final String OBJ_BENEFIT_ORDER = 'Benefit Order';
	public static final String INTEGRATION_ID_PREFIX = 'hippo-%';

	public static final String UNDEFINED_VALUE = 'undefined';

	public static final String WHITE_SPACE = ' ';
	public static final String BLANK_SPACE = '';
	public static final String UNDERSCORE = '_';
	public static final String HYPHEN = '-';
	public static final String NEXT_LINE = '\n';

	public static final String PROFILE_CX_USER = 'CX User';
	public static final String PROFILE_BENEFITS_USER = 'Benefits User';
	public static final String PROFILE_MMPR_USER = 'MMPR User';
	public static final String PROFILE_MDR = 'Gusto Direct MDR';
	public static final String PROFILE_DEL_ZP_PARTNER_AE = '_del_ZP Partner AE';
	public static final String PROFILE_ARDIUS_BASE_USER = 'Ardius Base User';

	public static final String ROLE_PAYROLL_ADMIN = 'Payroll Admin';
	public static final String ROLE_PRIMARY_PAYROLL_ADMIN = 'Primary Payroll Admin';
	public static final String ROLE_ACCOUNTANT = 'Accountant';
	public static final String ROLE_PARTNER = 'Partner';
	public static final String ROLE_SALES_SB_OB_XX = 'sales_sb_ob_xx';
	public static final String ROLE_SALES_SB_OB_SME = 'sales_sb_ob_sme';
	public static final String ROLE_SALES_MM_PR_XX = 'sales_mm_pr_xx';
	public final static String ROLE_SALES_BDR_XX_XX = 'sales_bdr_xx_xx';
	public final static String ROLE_SALES_SDR_MM_MGR_XX = 'sales_sdr_mm_mgr_xx';
	public final static String ROLE_SALES_SDR_MM_XX = 'sales_sdr_mm_xx';
	public final static String ROLE_SALES_SDR_PARTNER_MGR_XX = 'sales_sdr_partner_mgr_xx';
	public final static String ROLE_SALES_SDR_PARTNER_XX = 'sales_sdr_partner_xx';
	public static final String ROLE_SALES_PARTNER_AE_XX = 'sales_partner_ae_xx';
	public static final String ROLE_ARDIUS = 'Ardius';
	public static final String ROLE_CUSTOMER_SUCCESS = 'Customer_Success';

	public static final String SUCCESS = 'success';

	public static final String FIELD_API_STAGE_NAME = 'StageName';
	public static final String FIELD_API_NUMBER_OF_EMPLOYEES = 'NumberOfEmployees__c';
	public static final String FIELD_API_SKIP_EMPLOYEE_CHANGE = 'Skip_Employee_Change__c';
	public static final String FIELD_API_LIKELIHOOD_TO_STAY_WITH_GUSTO = 'Likelihood_to_Stay_with_Gusto__c';
	public static final String FIELD_API_GUSTO_RETENTION_NOTES = 'Gusto_Retention_Notes__c';
	public static final String FIELD_API_WORKERS_COMP_NOTES = 'Workers_Comp_Notes__c';
	public static final String FIELD_API_401K_NOTES = 'X401k_Notes__c';
	public static final String FIELD_API_529_NOTES = 'X529_Notes__c';
	public static final String FIELD_API_ACCOUNTING_PARTNER = 'Accounting_Partner__c';
	public static final String FIELD_API_BENEFIT_NOTES = 'Benefits_Notes__c';
	public static final String FIELD_API_POINT_OF_CONTACT = 'Point_Of_Contact__c';

	public static final String HI_OPP_TYPE_HI_BENEFITS_NEW_PLAN = 'HI Benefits New Plan';
	public static final String HI_OPP_TYPE_HI_BENEFITS_BOR = 'HI Benefits BoR';
	public static final String HI_OPP_TYPE_BENEFITS_BYOB = 'Benefits BYOB';

	public static final String ARD_OPP_CLOSED_WON = 'Closed Won';
	public static final String ARD_OPP_CLOSED_LOST = 'Closed Lost';

	public static final String HI_OPP_SUFFIX_NEW_PLAN = ' - New Plan';
	public static final String HI_OPP_SUFFIX_BOR = ' - BoR';
	public static final String HI_OPP_SUFFIX_BYOB = ' - BYOB';

	public static final String RANDOM_ID_PREFIX = 'FK-';

	public static final String DML_TYPE_INSERT = 'insert';
	public static final String DML_TYPE_UPDATE = 'update';
	public static final String DML_TYPE_UPSERT = 'upsert';

	public static final String DATETIME_FORMATTED = System.now().format('MM/dd/yyyy, hh:mm:ss a');

	public static final String ERROR_MSG_UNABLE_TO_LOCK_ROW = 'UNABLE_TO_LOCK_ROW';
	public static final String ERROR_MSG_LEAD_CANT_GO_BACK_TO_MQL_AQL = 'A lead in Unqualified cannot go back to MQL or AQL';
	public static final String ERROR_MSG_TEST_EXCEPTION = 'TEST EXCEPTION';

	public static final String LEAD_STATUS_UNQUALIFIED = 'Unqualified';
	public static final String LEAD_STATUS_AQL = 'AQL';
	public static final String LEAD_STATUS_MQL = 'MQL';

	public static final String LEAD_STATUS_DETAIL_BAD_PHONE = 'Bad Phone';

	public static final String ADDITIONAL_INFO = '_Additional_Info';
	public static final String FIELD_X401K_INTEREST_TYPE = 'X401K_Interest_Type__c';
	public static final String FIELD_X529_INTEREST = 'X529_Interest__c';
	public static final String FIELD_ARDIUS = 'Ardius__c';
	public static final String FIELD_ARDIUS_NOTES = 'Ardius_Notes__c';
	public static final String FIELD_WORKERS_COMP_INTEREST = 'Workers_Comp_Interest__c';
	public static final String FIELD_WORKERS_COMP_INTERESTPICKLIST = 'Workers_Comp_InterestPicklist__c';
	public static final String TYPE_401K = 'Type_401K';
	public static final String TYPE_529 = 'Type_529';
	public static final String TYPE_ARDIUS = 'Type_Ardius';
	public static final String TYPE_TAXCREDITS = 'Type_TaxCredits';
	public static final String TYPE_WORKERSCOMP = 'Type_WorkersComp';
	public static final String GUIDELINE = 'Guideline';
	public static final String HUMAN_INTEREST = 'Human Interest';
	public static final String BETTERMENT = 'Betterment';
	public static final String VESTWELL = 'Vestwell';
	public static final String Vender_401k = '401k';
	public static final String Vender_529 = '529';
	public static final String Vender_Worker = 'Worker';
	public static final String Vender_Ardius = 'Ardius';
	public static final String Vender_TaxCredits = 'Tax Credits';
	public static final String INTERNATIONAL_PAYROLL_LOG_A_CALL = 'international_payroll_logacall';
	public static final String INTERNATIONAL_CONTRACTOR_PAYMENT_LOGACALL = 'international_contractor_payment_logacall';
	public static final String PROCESSED_STATE = 'Processed';
	public static final String RETRY_STATE = 'Retry';
	public static final String ERROR_STATE = 'Error';
	public static final String INTERNATIONAL_PAYROLL = 'International Payroll';
	public static final String CROSS_SELL_OPPORTUNITY_FOR_ICP_ALREADY_EXISTS = 'Cross Sell Opportunity for International Contractor Payment Already exists in Closed Won Status.';
	public static final String UPSELL_OPPORTUNITY_FOR_EMPLOYER_ALREADY_EXISTS = 'UpSell Opportunity for Employer of record Already exists in Closed Won Status.';
	public static final String BENEFITS_OPPORTUNITY_CONTACT_ROLE = 'Benefits Admin';

	public static Map<String, Schema.SObjectType> map_GlobalDescribe {
		get {
			if (map_GlobalDescribe == null) {
				map_GlobalDescribe = Schema.getGlobalDescribe();
			}
			return map_GlobalDescribe;
		}
		private set;
	}

	public static List<Schema.FieldSetMember> getFieldsInFieldSet(String strObjectName, String strFieldSetName) {
		Schema.SObjectType objSObjectType = map_GlobalDescribe.get(strObjectName);
		Schema.DescribeSObjectResult objDescribeSObjectResult = objSObjectType.getDescribe();
		Schema.FieldSet objFieldSet = objDescribeSObjectResult.FieldSets.getMap().get(strFieldSetName);
		return objFieldSet?.getFields();
	}
}