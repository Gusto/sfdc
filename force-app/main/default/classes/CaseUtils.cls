public without sharing class CaseUtils {
	//Statuses
	public static String CASE_OBJ_NAME = 'Case';
	public static String STATUS_OPEN = 'Open';
	public static String STATUS_NEW = 'New';
	public static String STATUS_CLOSED = 'Closed';
	public static String STATUS_ASSIGNED = 'Assigned';
	public static String STATUS_IN_PROCESS = 'In Process';
	public static String STATUS_CANCELLED = 'Cancelled';
	public static String STATUS_ON_HOLD = 'On Hold';
	public static String STATUS_RESPONSE_RECEIVED = 'Response Received';
	public static String STATUS_SOLVED = 'Solved';
	public static String STATUS_AWAITING_RESPONSE = 'Awaiting Response';
	public static String STATUS_AWAITING_EXTERNAL_SUPPORT = 'Awaiting External Support';
	public static String STATUS_AWAITING_INTERNAL_SUPPORT = 'Awaiting Internal Support';
	public static String STATUS_WAITING_FOR_COORDINATOR = 'Waiting for Coordinator';
	public static final String STATUS_SUBMITTED = 'Submitted';
	public static final String STATUS_COMPLETED = 'Completed';
	public static final String STATUS_FAILED = 'Failed';
	public static final String STR_EMAIL_SENT_TO_CARRIER = 'Email sent to carrier';
	public static final String CASE_STATUS_READY_FOR_RESEARCH = 'Ready for Research';
	public static final String CASE_STATUS_RESEARCH_IN_PROGRESS = 'Research in progress';
	public static final String CASE_STATUS_READY_FOR_DATA_CAPTURE = 'Ready for Data Capture';
	public static final String CASE_STATUS_DATA_CAPTURE_COMPLETE = 'Data Capture Complete';
	public static final String CASE_STATUS_BLANK_STATUS = 'BLANK_STATUS';
	public static final String CASE_STATUS_FOLLOWUP_COMPLETED = 'Followup Completed';
	public static final String CASE_STATUS_PENDING = 'Pending';
	public static final String CASE_STATUS_INVOICE_RECOM_COMPLETED = 'Invoice Reconciliation Completed';
	public static final String CASE_STATUS_DATA_CAPTURE_IN_PROGRESS = 'Data Capture in Progress';
	public static final String CASE_STATUS_SHELVED = 'Shelved';
	public static final String SPECIAL_INSTRUCTIONS_MESSAGE = 'This employee has made changes to their benefits. Please check the EE’s benefit and enrollment pages in Hippo to confirm which lines of coverage this EE has selected with this carrier. The enrollment link may only reflect partial benefit information and/or outdated benefits.';
	public static final String CASE_STATUS_READY_FOR_OCR_CAPTURE = 'Ready for OCR Capture';
	public static final string CASE_STATUS_OCR_CAPTURE_COMPLETE = 'OCR Capture Complete';
	public static final string CASE_STATUS_OCR_CAPTUREINPROGRESS = 'OCR Capture in Progress';
	public static final String CASE_CLASS_CLASS_0 = 'Class 0';
	public static final String STATUS_IN_PROGRESS = 'In Progress';
	public static final String STATUS_DRAFT = 'Draft';
	public static final String MERGE_DUPLICATE = 'Merged Duplicate';
	public static final String CASE_AUTO_SOLVE_ERROR_MULTIPLE_ATTACHMENTS = 'The case has multiple attachments so could not auto close the case';
	public static final String STATUS_PI_AUTOSOLVE_STATUS_APPROVED = 'P&I Approved';
	public static final String STATUS_PI_AUTOSOLVE_STATUS_DENIED = 'P&I Denied';
	public static final String STATUS_ACTIVE = 'Active';
	public static final String STATUS_WORKING = 'Working';
	public static final String GEP_CX_AUTO_CLOSE_EMAIL_TEMPLATE = 'NotifyrequesterautocloseGEPCXLeakagecase';
	public static final String EMAIL_ADDRESS_BOUNCED_ERROR_MSG = 'The Contact email address is marked as bounced';
	//User Names
	public static final String SYSTEM_USER = 'System';
	public static final String WORKATO_USER = 'Workato Integration';
	public static final String BIZTECH_INTEGRATION_USER = 'BizTech Integrations';
	public static final String API_HEROKU_USER = 'API Heroku';

	//Email Status
	public static String EMAILSTATUS_OPEN = 'Open';
	public static final String EMAILSTATUS_RESPONSE_RECEIVED = 'Response Received';
	public static final String EMAILSTATUS_IN_PROGRESS = 'In progress';
	public static final String EMAILSTATUS_AWAITING_RESPONSE = 'Awaiting response';

	//Case Audit Log Event Type
	public static String STATUS_CHANGE = 'Status Change';
	public static String EMAIL_STATUS_CHANGE = 'Email Status Change';
	public static String OWNER_CHANGE = 'Owner Change';

	//Type fields
	public static final String TYPE_ASSURANCE = 'Assurance';
	public static final String TYPE_BENEFITS_RENEWAL_ALLIGNMENT = 'Benefits Renewal alignment';
	public static final String TYPE_CARRIER_SUBMISSION = 'Carrier Submission';
	public static final String TYPE_BOR = 'BOR';
	public static final String TYPE_BENEFITS_BOR_CARRIER = 'Benefits BOR Carrier Case';
	public static final String TYPE_BENEFITS_CARE = 'Benefits Care';
	public static final String TYPE_PAYROLL_CARE = 'Payroll Care';
	public static string strPAYROLLOPS_AUDIT = 'PayrollOps Audit';
	public static final String TYPE_SALES_CHAT = 'Sales Chat';
	public static final String TYPE_SALES = 'Sales';
	public static final String TYPE_GEP_PAYROLL = 'GEP Payroll';
	public static final String TYPE_GEP_TAX_RES = 'GEP Tax Res';
	public static final String TYPE_MEMBER_UPDATES = 'Member Updates';
	public static final String TYPE_GROUP_UPDATES = 'Group Updates';
	public static final String TYPE_NHE = 'NHE';
	public static final String TYPE_QLE = 'QLE';
	public static final String TYPE_TERMINATION = 'Termination';
	public static final String TYPE_VIKING_MASTER = 'Viking Master';
	public static final String TYPE_EMPLOYEE_TERMINATION = 'Employee Termination';
	public static final String TYPE_EMPLOYEE_STATUS_CHANGE = 'Employee Status Change';
	public static final String TYPE_DEP_QLE_LEGAL_SEPERATAION = 'Dependent QLE - Legal Separation';
	public static final String TYPE_DEP_QLE_COURT_ORDER = 'Dependent QLE - Court Order';
	public static final String TYPE_DEP_QLE_AGESS_OUT = 'Dependent QLE - Ages Out';
	public static final String TYPE_CANCELLATION = 'Cancellation';
	public static final String TYPE_AUDIT = 'Audit';
	public static final String TYPE_TADA_FAILURE = 'Tada Failure';
	public static final String TYPE_MEMBER_PROCESSING_EMAIL = 'Member Processing Email';
	public static final String TYPE_SALES_EMAIL = 'Sales Email';
	public static final String REC_TYPE_STR_MF_AUDIT = 'MF Audit';
	public static final String REC_TYPE_STR_MF_TERMINATION = 'MF Termination';
	public static final String REC_TYPE_STR_MF_SUBMISSION = 'MF Submission';
	public static final String REC_TYPE_STR_MF_MEMBER_GROUP_UPDATES = 'MF Member/Group Updates';
	public static final String REC_TYPE_STR_BENEFITS_NEW_PLAN = 'Benefits New Plan Case';
	public static final String TYPE_TADA = 'TAdA';

	// Origin
	public static final String ORIGIN_PHONE = 'Phone';
	public static final String ORIGIN_CHAT = 'Chat';
	public static final String ORIGIN_EMAIL = 'Email';
	public static final String ORIGIN_FOLLOW_UP_EMAIL = 'Follow Up Email';
	public static final String ORIGIN_ESCALATION = 'Escalation';
	public static final String ORIGIN_GUSTO = 'Gusto';
	public static final String ORIGIN_WEB = 'Web';
	public static final String ORIGIN_PARTNER_SETUP = 'Partner Setup';
	public static final String ORIGIN_ELECTRONIC_NOTICE = 'Electronic Notice';
	public static final String ORIGIN_BED = 'BED';
	public static final String STRING_PHYSICAL_MAIL = 'Physical Mail';
	public static final String ORIGIN_COBRA_EMAIL = 'Cobra Email';

	//Case Persona
	public static final String ADMIN_PERSONA = 'Admin';
	public static final String MEMBER_PERSONA = 'Member';
	public static final String ACCOUNTANT_PERSONA = 'Accountant';

	//Answer IQ Processed values
	public static final String ANSWER_IQ_PROCESSED_YES = 'Yes';
	//Solve Processed values 
	public static final String SOLVE_PROCESSED_NO = 'No';
	//Internal AI Solve Processed values
	public static final String INTERNAL_SOLVE_PROCESSED_NO = 'No';
	public static final String INTERNAL_VALID_REQUEST = 'valid_request';
	public static final String AUTO_SOLVE_STATUS_ELIGIBLE = 'Eligible';
	public static final String AUTO_SOLVE_STATUS_INELIGIBLE = 'Ineligible';
	public static final String AUTO_SOLVE_STATUS_ATTEMPTED = 'Attempted';
	public static final String AUTO_SOLVE_STATUS_CUSTOMER_RESPONDED = 'Customer Responded';

	//Company Size
	public static final String COMPANY_SIZE_MICRO = 'Micro 0-4';

	//Routing Team
	public static final String EXTERNAL_TEAM = 'External';
	public static final String INTERNAL_TEAM = 'Internal';

	// Priority
	public static final String PRIORITY_LOW = 'Low';
	public static final String PRIORITY_HIGH = 'High';

	//Case reasons
	public static final String SPAM_CASE_REASON = 'Spam';
	public static final String UNAUTHORIZED_USER_CASE_REASON = 'Unauthorized User';
	public static final String BENEFIT_REVERSAL_CASE_REASON = 'Benefit Reversal';
	public static final String MIDDESK_REGISTRATION = 'Middesk State Tax Registration';

	//Authorized user values
	public static final String AUTHORIZED_USER_NO = 'No';

	//Tax-Res role type
	public static String TAXRES_ACCOUNT_SPECIALIST = 'Account Specialist';
	public static String TAXRES_COORDINATOR = 'Coordinator';
	public static final String TAXRES_PRIMARY_PAYROLL_ADMIN = 'Primary Payroll Admin';

	//Id Prefixes
	public static String CASE_ID_PREFIX = '500';
	public static String USER_ID_PREFIX = '005';
	public static String QUEUE_ID_PREFIX = '00G';

	public static Map<String, String> map_CaseRecordTypeCarrierId;
	public static final String CONFIG_TAXRESPILOTAGENCIES = 'RingLead_Pilot_Agencies';

	//SMS Utils
	public static String SMS_DIRECTION_OB = 'Outgoing';
	public static String SMS_STATUS_QUEUED = 'Queued';
	public static String SMS_TEXT_FNAME = '<<firstName>>';
	public static String SMS_TEXT_FNAME_GUSTO = 'Gusto';
	public static String SMS_TEXT_CASE_ID = '<<caseId>>';
	public static String SMS_TEXT_OWNER_ID = '<<ownerid>>';

	//Channel
	public static String CHANNEL_PHONE = 'Phone';
	public static String CHANNEL_EMAIL = 'Email';
	public static String NO_REPLY_EMAIL = 'no-reply@gusto.com';
	//Record Type
	public static final Id RECTYPE_BENEFITS_CARE = Cache.getRecordTypeId('Case', 'Benefits Care');
	public static final Id RECTYPE_BENEFITS_CARE_READ_ONLY = Cache.getRecordTypeId('Case', 'Benefits Care - Read Only');
	public static final Id RECTYPE_PAYROLL_CARE = Cache.getRecordTypeId('Case', 'Payroll Care');
	public static final Id RECTYPE_PAYROLL_CARE_READ_ONLY = Cache.getRecordTypeId('Case', 'Payroll Care - Read Only');
	public static final Id RECTYPE_NEW_PLAN = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
	public static final Id RECTYPE_RENEWAL = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
	public static final Id RECTYPE_CHANGE = Cache.getRecordTypeId('Case', 'Benefits Change Case');
	public static final Id RECTYPE_BOR = Cache.getRecordTypeId('Case', 'Benefits BoR');
	public static final Id RECTYPE_BYB = Cache.getRecordTypeId('Case', 'Benefits BYB');
	public static final Id RECTYPE_MF_NHE = Cache.getRecordTypeId('Case', 'MF NHE');
	public static final Id RECTYPE_MF_QLE = Cache.getRecordTypeId('Case', 'MF QLE');
	public static final Id RECTYPE_MF_TERMINATION = Cache.getRecordTypeId('Case', 'MF Termination');
	public static final Id RECTYPE_MF_CANCELLATION = Cache.getRecordTypeId('Case', 'MF Cancellation');
	public static final Id RECTYPE_MF_MEMBER_GROUP_UPDATES = Cache.getRecordTypeId('Case', 'MF Member/Group Updates');
	public static final Id RECTYPE_MF_AUDIT = Cache.getRecordTypeId('Case', 'MF Audit');
	public static final Id RECTYPE_SALES_CASES_CLOSED = Cache.getRecordTypeId('Case', 'Sales Cases - Closed');
	public static final Id RECTYPE_SALES_CASES = Cache.getRecordTypeId('Case', 'Sales Cases');
	public static final Id RECTYPE_RECOVERY = Cache.getRecordTypeId('Case', 'Recovery Cases');
	public static final Id RECTYPE_TAXRES = Cache.getRecordTypeId('Case', 'Tax Res');
	public static final Id RECTYPE_TAXRES_READ_ONLY = Cache.getRecordTypeId('Case', 'Tax Res - Read Only');
	public static final Id RECTYPE_GEP_CX = Cache.getRecordTypeId('Case', 'GEP CX');
	public static final Id RECTYPE_PAYROLL_TRANSFER_CASE = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
	public static final Id RECTYPE_TAX_OPS = Cache.getRecordTypeId('Case', 'Tax Ops');
	public static final Id RECTYPE_TAX_OPS_READ_ONLY = Cache.getRecordTypeId('Case', 'Tax Ops - Read Only');
	public static final Id RECTYPE_MODERN_BANK = Cache.getRecordTypeId('Case', 'Modern Bank');
	public static final Id RECTYPE_MODERN_BANK_READ_ONLY = Cache.getRecordTypeId('Case', 'Modern Bank - Read Only');
	public static final Id RECTYPE_RISK_ASSURANCE = Cache.getRecordTypeId('Case', 'Risk Assurance');
	public static final Id RECTYPE_RISK_ASSURANCE_READ_ONLY = Cache.getRecordTypeId('Case', 'Risk Assurance - Read Only');
	public static final Id RECTYPE_PAYROLLOPS_AUDIT = Cache.getRecordTypeId('Case', 'PayrollOps Audit');
	public static final Id RECTYPE_PAYROLLOPS_AUDIT_READ_ONLY = Cache.getRecordTypeId('Case', 'PayrollOps Audit - Read Only');
	public static final Id RECTYPE_PAYROLL_COMPLIANCE = Cache.getRecordTypeId('Case', 'Payroll Compliance');
	public static final Id RECTYPE_GROUP_TERMINATION = Cache.getRecordTypeId('Case', 'Group Termination');
	public static final Id RECTYPE_R_D_TAX_CREDITS = RecordTypes.getRecordTypeIdFromDeveloperName('Case', 'R_D_Tax_Credits');
	public static final Id TAX_NOTICE_INDEX_RECTYPE_OCR = Cache.getRecordTypeId('Tax_Notice_Index__c', 'IDP Indexing');
	public static final Id TAX_NOTICE_INDEX_RECTYPE_MANUAL = Cache.getRecordTypeId('Tax_Notice_Index__c', 'Manual Indexing');
	public static final Id RECTYPE_ENGAGEMENT = Cache.getRecordTypeId('Case', 'Engagement');
	public static final Id RECTYPE_CASE_COMPLIANCE = Cache.getRecordTypeId('Case', 'Compliance');
	public static final Id R_D_TAX_CREDITS = Cache.getRecordTypeId('Case', 'R&D Tax Credits');
	public static final Set<String> set_EngagementRecordTypes = new Set<String>{ RECTYPE_PAYROLL_CARE, RECTYPE_ENGAGEMENT };
	public static final Id RECTYPE_CLIENT_RELATIONS = Cache.getRecordTypeId('Case', 'Client Relations');

	//Record Type Name:
	public static final String RECTYPE_NAME_SALES_CASES = 'Sales Cases';
	public static final String RECTYPE_NAME_GEP_CX = 'GEP CX';
	public static final String RECTYPE_NAME_TAXRES = 'Tax_Res';
	public static final String RECTYPE_NAME_MAINTENACE_QUESTIONNAIRE = 'Maintenance Questionnaire';

	// Queue Names
	public static final String QUEUE_NAME_PAYROLL_CARE_AUTO_CLOSE = 'Payroll_Care_Auto_Close';
	public static final String QUEUE_NAME_NEWPLAN_BENEFITS_OPERATIONS = 'New_Plan_Benefits_Operations';
	public static final String QUEUE_NAME_RISK_UNAUTHORIZED = 'Risk_Unauthorized_Queue';
	public static final String QUEUE_NAME_MODERN_BANK_AUTO_CLOSE = 'Modern_Bank_Auto_Close';
	public static final String QUEUE_NAME_TAX_OPS_AUTO_CLOSE = 'TaxOps_Auto_Closed_Queue';
	public static final String QUEUE_NAME_SALES_CASE = 'Sales_Case_Queue';
	public static final String QUEUE_NAME_SALES_PARTNER_TRANSFER_QUEUE = 'Sales_Partner_Transfer_Queue';
	public static final String QUEUE_NAME_ENGAGEMENT_CASES = 'Engagement_Cases';
	public static final String QUEUE_NAME_PAYROLL_CARE_NON_ACTIONABLE = 'Payroll_Care_Non_Actionable';
	public static final String QUEUE_NAME_ENGAGEMENT_CANCELED_CHATS = 'Engagement_Canceled_Chats';
	public static final String QUEUE_NAME_CARE_VISITOR_ABANDONED_CHATS = 'Care_Visitor_Abandoned_Chats';
	public static final String QUEUE_NAME_GEP_CX_QUEUE = 'GEP_CX_Queue';
	public static final String QUEUE_NAME_MODERN_BANK_ROUTING = 'Modern_Bank_Routing';

	//Case Specialization Values
	public static final String COBRA_SPECIALIZATION = 'COBRA';
	public static final String SPANISH_SPECIALIZATION = 'Spanish';

	public static Id ID_ENGAGEMENT_CASES_QUEUE = GlobalQueryHelper.getQueueIdByDevName(QUEUE_NAME_ENGAGEMENT_CASES);

	//Profile names
	public static final String PROFILE_VENDOR_CX_USER = 'Vendor CX';

	//Permission set names
	public static final String SOCIAL_ESCALATION_PERMISSION_SET = 'Social_Escalation_Case_Permissions';

	//specialist round robin variable
	public static final String TEXT_ROUND_ROBIN = 'Round_Robin';
	public static final Set<String> set_OpenCaseStatuses = new Set<String>{ CaseUtils.CASE_STATUS_READY_FOR_RESEARCH, CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS, 'Shelved', 'Blocked' };
	public static final Set<String> set_ClosedCaseStatuses = new Set<String>{ CaseUtils.STATUS_CLOSED, 'Request Denied', 'Will not support', 'Reject', 'Informational' };

	public static final String MEMBER_OPS_QUEUE = 'Member Ops';
	//Case Types
	public static final String TYPE_BENEFITS_COMPLIANCE = 'Benefits Compliance';
	public static final String TYPE_TAX_RES = 'Tax Res';
	public static final String TYPE_TAX_OPS = 'Tax Ops';
	public static final String TYPE_MODERN_BANK = 'Modern Bank';
	public static final String TYPE_PAYROLL_COMPLIANCE = 'Payroll Compliance';
	public static final String TYPE_PAYROLL_COMPLIANCE_INQUIRY = 'Payroll Compliance Inquiry';
	public static final String TYPE_RISK_ASSURANCE = 'Risk Assurance';
	public static final String TYPE_SALES_CASES = 'Sales Cases';
	public static final String TYPE_BENEFITS_BOR = 'Benefits BoR';
	public static final String TYPE_PAYROLLOPS_AUDIT = 'PayrollOps Audit';
	public static final String TYPE_BENEFITS_CHANGE_CASE = 'Benefits Change Case';
	public static final String TYPE_BENEFITS_NEW_PLAN_CASE = 'Benefits New Plan Case';
	public static final String TYPE_BENEFITS_NEW_PLAN = 'Benefits New Plan';
	public static final String TYPE_BENEFITS_RENEWAL_CASE = 'Benefits Renewal Case';
	public static final String TYPE_MEMEBER_FULFILLMENT_EMAILS = 'Member Fulfillment Emails';
	public static final String TYPE_COMPLIANCE = 'Compliance';
	public static final String TYPE_DOC_MAPPING = 'Document Mapping';
	public static final String TYPE_TOTAL_GROUP_TERMINATE = 'Total Group Termination';
	public static final String TYPE_BENEFITS_SUSPEND = 'Benefits Suspension Only';
	public static final String TYPE_TERMINATE_CARRIER = 'Terminate Carrier';
	public static final String TYPE_CARRIER_SWITCH = 'Carrier Switch Termination';
	public static final String TYPE_RESCIND_TERMINATE = 'Rescind Termination';
	public static final String TYPE_BOR_TERMINATE = 'Bor Termination';
	public static final String TYPE_ENGAGEMENT = 'Engagement';
	public static final String TYPE_INVESTIGATIONS = 'Investigations';

	public static final String CONTEXT_TRANSFER = 'Transfer';
	public static final String TYPE_COBRA = 'Cobra';
	public static final String NOT_ELIGIBLE_AUTO_RESPONSE = 'Not Eligible - Parent has Auto Response';

	public static final String INACTIONABLE_REQ_STATUS_DETAIL = 'Inactionable Request';
	public static final String ONE_TIME_PASSCODE_SUBJECT = 'Your one-time passcode to view the message';
	public static String STR_FBED_SUBJECT = System.Label.Tax_Res_FBED_Subject;

	//compliance related data
	public static final String STR_OBJ_NAME_TAX_QUESTIONNAIRE = 'Tax_Questionnaire__c';
	public static final String STR_OBJ_NAME_TAX_COMPLIANCE = 'Tax_Compliance__c';
	public static final String STR_ID = 'Id';
	public static final String STR_OBJ_NAME_AGENCY_INFORMATION = 'Agency_Information__c';
	public static final String STR_V = 'V';
	public static final String STR_ALLUSERS = 'AllUsers';
	public static final String STR_COMPLIANCE = 'Compliance';
	public static final String STR_NO_LONGER_NEEDED = 'No Longer Needed';
	public static final String STR_DELETE = 'Delete';
	public static final String STR_UN_SUPPORTED = 'Unsupported';
	public static final String STR_NO_CHANGE = 'No Change';
	public static final String STR_SUCCESSFULLY_CASE_CREATED_IN_ASANA = 'Successfully created in Asana';

	//Tax Compliance Email Handler
	public static final String STRG_TAX_COMPLIANCE_EMAIL = 'taxcompliance@gusto.com';
	public static final String STRG_MEDIUM = 'Medium';
	public static final String STRG_QUEUE = 'Queue';
	public static final String STRG_PAYROLL_COMP_QUEUE = 'Payroll Product Compliance';
	public static final String STRG_TAX_COMP_QUEUE = 'Tax Filing Compliance';
	public static final String STRG_REG_AFF_QUEUE = 'Regulatory Affairs';
	public static final String STRG_RECORDTYPE = 'RecordType';
	public static final String STRG_PRIORITY = 'Priority';
	public static final String STRG_ORIGIN = 'Origin';
	public static final String STRG_NEW = 'New';
	public static final String STRG_PAYROLL_COMP_INQUIRY = 'Payroll Compliance Inquiry';
	public static final String STRG_VIEWER = 'V';
	public static final String STRG_OCR_MSG = 'Created from Email to Case';
	public static final String STRG_OCR_CREATED_FROM_CLONE_MSG = 'Created from Email to Case';
	public static final String STRG_TIER = 'Tier 4-System Enhancement';
	public static final String STRG_FREQUENCT_OF_UPDATE = 'One time Task';
	public static final String STRG_FREQUENCT_OF_UPDATE_ANNUAL = 'Annual Task';
	public static final String STRG_FREQUENCT_OF_UPDATE_QUARTERLY = 'Quarterly Task';
	public static final String STRG_FREQUENCT_OF_UPDATE_BI_ANNUAL = 'Bi Annual';
	public static final String STRG_ClASSIFICATION_TYPE = 'Compliance Requirement';
	public static final List<String> LIST_HIGH_PRIORITY = new List<String>{ 'Urgent', 'Important' };

	//PayrollProductComplaince Email Handler
	public static final String STRG_PAYROLL_PRODUCT_COMPLIANCE_EMAIL = 'payroll_product_compliance@gusto.com';
	public static final String STRG_COMPLIANCE = 'Compliance';

	//Case Type Pillars
	public static final String PAYROLL_CASE_PILLAR = 'Payroll';
	public static final String BENEFITS_CASE_PILLAR = 'Benefits';
	public static final String TAXES_CASE_PILLAR = 'Taxes';
	//Case Sub Pillars
    public static final String CARE_PREMIER_PAYROLL = 'Care Premier Payroll';
    public static final String CARE_PREMIER_TAXES ='Care Premier Taxes';
    public static final String CARE_MEMBERS ='Care Members';
    public static final String CARE_PREMIER_BENEFITS ='Care Premier Benefits';

	//Support Levels
	public static final String TIER_1 = 'Tier 1';
	public static final String TIER_2 = 'Tier 2';

	//CX Experiment values
	public static final String TAM_CX_EXPERIMENT = 'TAM';

	//Email Domains
	public static final String MIDDESK_EMAIL_DOMAIN = 'middesk.com';

	// Instabase
	public static string STR_BASIC = 'BASIC';
	public static string STR_SFDC_SUCCESS_MSG = 'SFDC - Passed';
	public static string STR_IB_SUCCESS_MSG = 'OCR Passed';
	public static string STR_IB_FAILED_MSG = 'OCR Failed';
	public static string STR_IB_ATTACHMENTNOTFOUND_MSG = 'Attachment not found';
	public static string STR_IB_NOINDEXREQD_MSG = 'No indexing required';
	public static string STR_IB_OCR_SUCCESSFULLY_CREATED_TNDC = 'OCR successfully created TNDC';
	public static string STR_IB_OCRFLOWERROR_MSG = 'OCR flow error';
	public static string STR_IB_OCRFLOWNORESPONSE_MSG = 'OCR flow response with no pages';
	public static string STR_IB_FAILED_STATUS = 'Failed';
	public static string STR_IB_SUCCESS_STATUS = 'Completed';
	public static string STR_SFDC_ERROR_ACCOUNTNOTFOUND_MSG = 'SFDC - unable to find account name';
	public static string STR_SFDC_ERROR_ATTACHMENTNOTFOUND_MSG = 'SFDC - Failed to create TNDC as attachment not found';
	public static string STR_SFDC_ERROR_NOINDEXREQS_MSG = 'SFDC - No indexing required';
	public static string STR_SUCCESS_MSG_TNDC_CREATED = 'SFDC - TNDC Record Created';
	public static string STR_AUTO_SOLVED_CASE_REASON = 'Auto-Solved';
	public static string STR_NO_ACTION_OR_WRONG_EMAIL_CASE_REASON = 'No Action or Wrong Email';
	public static string STR_GEP_ER_AUTOCLOSE_CASE_REASON = 'GEP ER - Autoclose';
	public static final String STR_CARRIER_PORTAL = 'Carrier Portal';
	public static string AGENCY_IRS = 'Internal Revenue Service';
	public static string PROCESSINGSTATE_PROCESSED = 'Processed';
	public static string PROCESSINGSTATE_ERROR = 'Error';
	public static final Set<String> set_OCRCaptureStatuses = new Set<String>{ CASE_STATUS_OCR_CAPTURE_COMPLETE };
	public static final Set<String> set_OCRErrorMessages = new Set<String>{ STR_IB_ATTACHMENTNOTFOUND_MSG, STR_IB_OCRFLOWERROR_MSG, STR_IB_OCRFLOWNORESPONSE_MSG };
	public static final Set<String> set_ProcessingStatesToIgnore = new Set<String>{ PROCESSINGSTATE_PROCESSED, PROCESSINGSTATE_ERROR };
	public static Map<String, Agency_Information__c> map_AllAgencies = GlobalQueryHelper.getAllAgencyNamesWithAgencyInformation();

	public static Set<String> set_SalesQueues = new Set<String>{ QUEUE_NAME_SALES_CASE, QUEUE_NAME_SALES_PARTNER_TRANSFER_QUEUE };
	public static Map<String, Id> map_SalesCasesQueues = GlobalQueryHelper.getQueueNameAndIdMap(set_SalesQueues);

	public static final String AGENCY_CAEDD = 'CA-EDD';

	//Case Direction
	public static final String DIRECTION_INBOUND = 'Inbound';

	//String to identify a read only record type
	public static final String READ_ONLY_RECORD_TYPE = 'Read Only';

	//Tax Notice Index Default values
	public static Id IRS_AGENCY_ID_DEFAULT = getAgencyId(AGENCY_IRS);
	static String AGENCY_ASSIGNED_DEFAULT = 'FEIN';
	static String TAX_NOTICE_TYPE_DEFAULT = '941';
	static Date TAX_NOTICE_DATE_DEFAULT = System.today();
	static Date TAX_NOTICE_DUE_DATE_DEFAULT = System.today();
	static String TAX_NOTICE_FORM_NUMBER_DEFAULT = 'NOFORMNUMBER';
	static String TAX_NOTICE_NUMERATION_DEFAULT = '2nd';
	public static Integer TAX_NOTICE_AMOUNT_TOTAL_DEFAULT = 0;
	public static Integer TAX_NOTICE_TAX_AMOUNT_DEFAULT = 0;
	static Integer TAX_NOTICE_PI_DEFAULT = 0;
	static String TAX_NOTICE_YR_QTR_DEFAULT = TaxResNoticeIndexDetailsController.getQuarterAndYear(System.today());
	public static String TAX_NOTICE_MULTI_YR_QTR_DEFAULT = 'N';
	public static final String CARRIER_FLORIDA_BLUE = 'Florida Blue';
	public static Id ID_MF_MF_FOLLOW_UP_QUEUE = GlobalQueryHelper.getQueueIdByDevName('MF_Followup');
	public static Id ID_TAX_RES_DATA_CAPTURE_QUEUE = GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue');
	public static final String STR_SUI_FORM_TYPE = 'SUI';
	public static final String STR_TAX_FORM_TYPE = 'TAX';
	public static final String TAX_NOTICE_NUMERATION_FINAL = 'FINAL';

	//OCR Default Values
	public static final String TAXRES_OCR_CAPTURE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('OCR_Capture_queue');

	//Benefits Renewal/Change auto close constants
	public static String NO_REPLY_GLIC = 'noreply@glic.com';
	public static String GUARDIAN_BIZ_SUBJECT = 'Your Guardian Business Associate Agreement';
	public static String AUTO_RESPONDER_SUBJECT = 'AutoResponder:';
	public static String SBS_HUMANA = 'sbsales@humana.com';
	public static String THANK_YOU_SUBJECT = 'Thank you for your submission.';

	public static final String QUEUE_MF_COMPLETED = 'MF_Completed';
	public static final String QUEUE_MF_FOLLOWUP = 'MF_Followup';
	public static final String QUEUE_FORM_AUTOMATION = 'Form_Automation';
	public static final String QUEUE_MEMBER_OPS_BYB = 'Member_Ops_BYB';
	public static final String QUEUE_MEMBER_FULFILLMENT = 'Member_Fulfillment';
	public static final String QUEUE_MF_AUTOMATION_FOLLOWUP = 'MF_Automation_Follow_Up';
	public static final String QUEUE_MF_INVOICE_RECONCILATION = 'MF_Invoice_Reconciliation';
	public static final String QUEUE_TAM_CASE_QUEUE = 'TAM_Case_Queue';
	public static final String QUEUE_ENGAGEMENT_ESCALATIONS = 'Engagement_Escalations';
	public static final String QUEUE_RISK_FCI = 'Risk - FCI';
	public static final String STR_NON_MAPPED_FORM = 'Non Mapped Form';
	public static final String STR_MILESTONE_PENDING_DEADLINE = 'Pending Deadline';
	public static final String STR_MILESTONE_SUBMISSION_DEADLINE = 'Submission Deadline';
	public static final String STR_EXPEDITE = 'expedite';

	public static final String STR_INBOUND = 'Inbound';
	public static final String STR_OUTBOUND = 'Outbound';

	//Case Audience values
	public static final String AUDIENCE_OTHER = 'Other/Unknown';

	//Case Internal Support Requested From
	public static final String ENGAGEMENT_PARKED = 'Engagement - Parked';
	public static final String CAPTAIN_SME = 'Captain/SME';

	public static final Set<String> set_EligibleClosedTypes = new Set<String>{
		TYPE_NHE,
		TYPE_QLE,
		TYPE_TERMINATION,
		TYPE_EMPLOYEE_TERMINATION,
		TYPE_EMPLOYEE_STATUS_CHANGE,
		TYPE_DEP_QLE_LEGAL_SEPERATAION,
		TYPE_DEP_QLE_COURT_ORDER,
		TYPE_DEP_QLE_AGESS_OUT,
		TYPE_MEMBER_UPDATES,
		TYPE_GROUP_UPDATES,
		TYPE_MEMBER_PROCESSING_EMAIL,
		TYPE_AUDIT,
		TYPE_TADA_FAILURE,
		TYPE_CANCELLATION
	};

	public static final Set<Id> set_RTAutomationStatusFailed = new Set<Id>{ RECTYPE_MF_MEMBER_GROUP_UPDATES, RECTYPE_MF_NHE, RECTYPE_MF_TERMINATION };
	public static final Set<Id> set_RTAutomationStatusCompleted = new Set<Id>{ RECTYPE_MF_MEMBER_GROUP_UPDATES, RECTYPE_MF_NHE, RECTYPE_MF_TERMINATION, RECTYPE_MF_QLE };

	public static final Set<Id> set_ReopenInQueueRecordTypes = new Set<Id>{ RECTYPE_PAYROLL_CARE, RECTYPE_BENEFITS_CARE, RECTYPE_MODERN_BANK };

	public static final Set<Id> set_RenewInQueueRecordTypes = new Set<Id>{ RECTYPE_TAX_OPS, RECTYPE_RISK_ASSURANCE, RECTYPE_PAYROLL_COMPLIANCE };

	public static final String ALEGEUS_FRESHDESK = 'support@alegeus.freshdesk.com';
	public static final List<String> list_TaxResOBMsgTriggerSubjects = new List<String>{
		'[Action Required]: Please sign Power of Attorney',
		'FYI: Gusto updated your federal deposit schedule to Semiweekly',
		'FYI: Gusto updated your federal tax filing form to quarterly Form 941',
		'FYI: Gusto updated your federal tax filing form and deposit schedule',
		'[Action required]: Review filing requirement for Q1 2020',
		'[Action required]: Review and update your 2020 state unemployment rate',
		'Action required by 10/6: Update your state unemployment rate',
		'Gusto Account Information'
	};

	//Case Resolutions
	public static final String RESOLUTION_CUSTOMER_UNRESPONSIVE = 'Customer Unresponsive';
	public static final String RESOLUTION_ISSUE_RESOLVED = 'Issue Resolved';

	/**
	 * @Author      : Pravesh Rana
	 * @Description : retrieve agency information from agency name
	 * @Parm        : strAgencyName - Agency Name
	 * @Return      : Id - Agency SFDC ID
	 **/
	static Id getAgencyId(String strAgencyName) {
		Id idAgency;
		if (map_AllAgencies?.size() > 0 && map_AllAgencies?.containsKey(strAgencyName)) {
			idAgency = map_AllAgencies?.get(strAgencyName)?.Id;
		}

		return idAgency;
	}

	public final static Set<String> set_CaseTypes = new Set<String>{
		TYPE_TAX_RES,
		TYPE_PAYROLL_CARE,
		TYPE_MODERN_BANK,
		TYPE_BENEFITS_COMPLIANCE,
		TYPE_BENEFITS_CARE,
		TYPE_RISK_ASSURANCE,
		TYPE_PAYROLLOPS_AUDIT
	};

	public static final Set<String> set_SMSRecordTypes = new Set<String>{ RECTYPE_ENGAGEMENT, RECTYPE_PAYROLL_CARE, RECTYPE_BENEFITS_CARE, RECTYPE_TAXRES, RECTYPE_MODERN_BANK, RECTYPE_GEP_CX };

	public static final Set<String> set_DatTimeSolveRecordTypes = new Set<String>{
		RECTYPE_PAYROLL_CARE,
		RECTYPE_BENEFITS_CARE,
		RECTYPE_TAXRES,
		RECTYPE_RISK_ASSURANCE,
		RECTYPE_MODERN_BANK,
		RECTYPE_PAYROLLOPS_AUDIT,
		RECTYPE_PAYROLL_CARE_READ_ONLY,
		RECTYPE_BENEFITS_CARE_READ_ONLY,
		RECTYPE_TAXRES_READ_ONLY,
		RECTYPE_RISK_ASSURANCE_READ_ONLY,
		RECTYPE_MODERN_BANK_READ_ONLY,
		RECTYPE_PAYROLLOPS_AUDIT_READ_ONLY,
		RECTYPE_GEP_CX,
		RECTYPE_R_D_TAX_CREDITS
	};

	//Custom Settings
	public static Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
	public static final String BELOW_TOLERANCE_THRESHOLD_CUSTOM_SETTING = 'Below Tolerance - Total Amount Due';
	public static final String BELOW_TOLERANCE_CASE_TYPES_CUSTOM_SETTING = 'Below Tolerance Case Types';
	public static final String MERGE_FORM_NUMBERS_CUSTOM_SETTING = 'Merge Form Numbers';
	public static final String PI_LATE_DEPOSIT_FORM_NUMBERS_CUSTOM_SETTING = 'P&I Late Deposit - Tax Form Numbers';
	public static final String PI_LATE_DEPOSIT_CASE_TYPES_CUSTOM_SETTING = 'P&I Late Deposit - Case Types';

	public static void RouteCaseToTaxRes(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res');
		c.Type = 'Tax Res';
	}

	//DS[27-Oct-2020] : add PayrollOps Audit case to route
	public static void RouteCaseToPayrollAudit(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', strPAYROLLOPS_AUDIT);
		c.Type = 'Onboarding State Tax Audit';
		//update c;
	}

	public static void RouteCaseToPayrollCare(Case c) {
		c.RecordTypeId = RECTYPE_PAYROLL_CARE;
		c.Type = 'Payroll Care';
		//update c;
	}

	public static void RouteCaseToModernBank(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Modern Bank');
		c.Type = 'Modern Bank';
		//update c;
	}

	//Routing case to Benefits Compliance
	public static void RouteCaseToBenefitsCompliance(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Compliance');
		c.Type = 'Benefits Compliance';
		//update c;
	}

	public static void RouteCaseToBenefitsCare(Case c) {
		c.RecordTypeId = RECTYPE_BENEFITS_CARE;
		c.Type = 'Benefits Care';
		//update c;
	}

	public static void RouteCaseToRisk(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Risk Assurance');
		//update c;
	}

	public static void RouteCaseToPayrollCompliance(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Compliance');
		c.Type = 'Payroll Compliance Inquiry';
		//update c;
	}

	public static void RouteCaseToTaxOps(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Ops');
		c.Type = '';
		//update c;
	}

	public static void RouteCaseToSales(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Sales Cases');
		c.Type = 'Sales Email';
		//update c;
	}

	public static void RouteCaseToBenefitsBoR(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits BoR');
		c.Type = 'BOR';
		//update c;
	}

	public static void RouteCaseToBenefitsChangeCase(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Change Case');
		c.Type = 'Benefits Change';
		//update c;
	}

	public static void RouteCaseToBenefitsNewPlanCase(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		c.Type = 'Benefits New Plan';
		//update c;
	}

	public static void RouteCaseToBenefitsRenewalCase(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		c.Type = 'Benefits Renewal';
		//update c;
	}

	public static void RouteCaseToMemberFulfillmentCase(Case c) {
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Member Fulfillment Emails');
		c.Type = 'Member Processing Email';
		//update c;
	}

	public static void RouteCaseToEngagement(Case objCase) {
		objCase.RecordTypeId = RECTYPE_ENGAGEMENT;
		objCase.Type = PAYROLL_CASE_PILLAR;
		objCase.Support_Level__c = TIER_1;
		if (EngagementCaseViewExtension.blnIsCaseRoute) {
			objCase.Case_In_Route__c = true;
			if (String.isNotBlank(ID_ENGAGEMENT_CASES_QUEUE)) {
				objCase.OwnerId = ID_ENGAGEMENT_CASES_QUEUE;
			}

			EngagementCaseViewExtension.blnIsCaseRoute = false;
		}
	}

	private static void removeCaseContext(case cse) {
		CaseTriggerHelper.skipTrigger = true;
		Case c = new Case(Id = cse.Id);
		c.Context__c = '';
		update c;
	}

	/**
	 * @description			Method to route case depending case type without redirection
	 * @author              Sandeep Golla
	 * @param strCaseType 		Case Types Option
	 * @param objCase    	Case Record
	 */
	public static void caseRouting(String strCaseType, Case objCase) {
		//payroll and Benefits care exception asked by BS on Feb/6/19
		if (set_CaseTypes.contains(strCaseType) || strCaseType != objCase.RecordType?.Name || objCase.Id == null) {
			Boolean blnRemoveCaseContext = false;
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			objCase.setOptions(dmo);
			objCase.Context__c = CONTEXT_TRANSFER;
			if (strCaseType == TYPE_SALES_CASES) {
				CaseUtils.RouteCaseToSales(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_TAX_RES) {
				if (!objCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					objCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Confirm_Case_Reason__c = '';
					objCase.Routing_Case_Reason__c = '';
				}

				CaseUtils.RouteCaseToTaxRes(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_PAYROLLOPS_AUDIT) {
				if (!objCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					objCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Confirm_Case_Reason__c = '';
					objCase.Routing_Case_Reason__c = '';
				}

				CaseUtils.RouteCaseToPayrollAudit(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_PAYROLL_CARE) {
				if (!objCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					objCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Confirm_Case_Reason__c = '';
					objCase.Routing_Case_Reason__c = '';
					objCase.Class__c = '';
				}

				CaseUtils.RouteCaseToPayrollCare(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_MODERN_BANK) {
				if (!objCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					objCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Confirm_Case_Reason__c = '';
					objCase.Routing_Case_Reason__c = '';
					objCase.Class__c = '';
				}

				CaseUtils.RouteCaseToModernBank(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_BENEFITS_COMPLIANCE) {
				if (!objCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					objCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Confirm_Case_Reason__c = '';
					objCase.Routing_Case_Reason__c = '';
					objCase.Class__c = '';
				}

				CaseUtils.RouteCaseToBenefitsCompliance(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_BENEFITS_CARE) {
				if (!objCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					objCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Confirm_Case_Reason__c = '';
					objCase.Routing_Case_Reason__c = '';
					objCase.Class__c = '';
				}

				if (objCase.type != TYPE_COBRA) {
					CaseUtils.RouteCaseToBenefitsCare(objCase);
				}

				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_TAX_OPS) {
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Routing_Case_Reason__c = '';
					objCase.Reason = '';
				}

				CaseUtils.RouteCaseToTaxOps(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_PAYROLL_COMPLIANCE) {
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Routing_Case_Reason__c = '';
					objCase.Reason = '';
				}
				CaseUtils.RouteCaseToPayrollCompliance(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_RISK_ASSURANCE) {
				CaseUtils.RouteCaseToRisk(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_BENEFITS_BOR) {
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Routing_Case_Reason__c = '';
					objCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsBOR(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_BENEFITS_CHANGE_CASE) {
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Routing_Case_Reason__c = '';
					objCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsChangeCase(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_BENEFITS_NEW_PLAN_CASE) {
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Routing_Case_Reason__c = '';
					objCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsNewPlanCase(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_BENEFITS_RENEWAL_CASE) {
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Routing_Case_Reason__c = '';
					objCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsRenewalCase(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_MEMEBER_FULFILLMENT_EMAILS) {
				if (strCaseType != objCase.RecordType.Name) {
					objCase.Routing_Case_Reason__c = '';
					objCase.Reason = '';
				}
				CaseUtils.RouteCaseToMemberFulfillmentCase(objCase);
				blnRemoveCaseContext = true;
			} else if (strCaseType == TYPE_ENGAGEMENT) {
				CaseUtils.RouteCaseToEngagement(objCase);
				blnRemoveCaseContext = true;
			}

			CaseTriggerHelper.skipTrigger = true;
			Database.UpsertResult objCaseUpsertResult = Database.upsert(objCase, false);
			CaseTriggerHelper.skipTrigger = false;
			if (objCaseUpsertResult.isSuccess()) {
				if (blnRemoveCaseContext) {
					removeCaseContext(objCase);
				}
			} else {
				List<Database.Error> list_CaseUpsertErrors = objCaseUpsertResult.getErrors();
				ExceptionLogUtil.logException('CaseUtils', 'caseRouting', list_CaseUpsertErrors[0].getMessage(), '');
			}
		}
	}

	public static pageReference routeCase(String caseType, Case theCase) {
		//payroll and Benefits care exception asked by BS on Feb/6/19
		if (
			caseType == 'Tax Res' ||
			caseType == 'Payroll Care' ||
			caseType == 'Modern Bank' ||
			caseType == 'Benefits Compliance' ||
			caseType == 'Benefits Care' ||
			caseType == 'Risk Assurance' ||
			caseType == strPAYROLLOPS_AUDIT ||
			caseType == 'Engagement' ||
			caseType != theCase.RecordType.Name
		) {
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			theCase.setOptions(dmo);
			theCase.Context__c = 'Transfer';
			if (caseType == 'Sales Cases') {
				CaseUtils.RouteCaseToSales(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/SalesCaseViewPage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			}
			if (caseType == 'Tax Res') {
				if (!theCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					theCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (caseType != theCase.RecordType.Name) {
					theCase.Confirm_Case_Reason__c = '';
					theCase.Routing_Case_Reason__c = '';
				}

				CaseUtils.RouteCaseToTaxRes(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/TaxResCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == strPAYROLLOPS_AUDIT) {
				//DS[27-Oct-2020] : add PayrollOps Audit case to route
				if (!theCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					theCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (caseType != theCase.RecordType.Name) {
					theCase.Confirm_Case_Reason__c = '';
					theCase.Routing_Case_Reason__c = '';
				}

				CaseUtils.RouteCaseToPayrollAudit(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/PayrollAuditCase?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Payroll Care') {
				if (!theCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					theCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (caseType != theCase.RecordType.Name) {
					theCase.Confirm_Case_Reason__c = '';
					theCase.Routing_Case_Reason__c = '';
					theCase.Class__c = '';
				}

				CaseUtils.RouteCaseToPayrollCare(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/PayrollCareCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Modern Bank') {
				if (!theCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					theCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (caseType != theCase.RecordType.Name) {
					theCase.Confirm_Case_Reason__c = '';
					theCase.Routing_Case_Reason__c = '';
					theCase.Class__c = '';
				}

				CaseUtils.RouteCaseToModernBank(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/ModernBankCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Benefits Compliance') {
				if (!theCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					theCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (caseType != theCase.RecordType.Name) {
					theCase.Confirm_Case_Reason__c = '';
					theCase.Routing_Case_Reason__c = '';
					theCase.Class__c = '';
				}

				CaseUtils.RouteCaseToBenefitsCompliance(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/BenefitsComplianceCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Benefits Care') {
				if (!theCase.Reviewed_by_Dedicated_Support__c && checkForDedicateUser()) {
					theCase.Reviewed_by_Dedicated_Support__c = true;
				}
				if (caseType != theCase.RecordType.Name) {
					theCase.Confirm_Case_Reason__c = '';
					theCase.Routing_Case_Reason__c = '';
					theCase.Class__c = '';
				}

				if (theCase.type != 'Cobra') {
					CaseUtils.RouteCaseToBenefitsCare(theCase);
				}

				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/BenefitsCareCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Tax Ops') {
				if (caseType != theCase.RecordType.Name) {
					theCase.Routing_Case_Reason__c = '';
					theCase.Reason = '';
				}

				CaseUtils.RouteCaseToTaxOps(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/TaxOpsCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Payroll Compliance') {
				if (caseType != theCase.RecordType.Name) {
					theCase.Routing_Case_Reason__c = '';
					theCase.Reason = '';
				}
				CaseUtils.RouteCaseToPayrollCompliance(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/PayrollComplianceCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Risk Assurance') {
				CaseUtils.RouteCaseToRisk(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/RiskAssuranceCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			} else if (caseType == 'Benefits BoR') {
				if (caseType != theCase.RecordType.Name) {
					theCase.Routing_Case_Reason__c = '';
					theCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsBOR(theCase);
				update theCase;
				removeCaseContext(theCase);
				return null;
			} else if (caseType == 'Benefits Change Case') {
				if (caseType != theCase.RecordType.Name) {
					theCase.Routing_Case_Reason__c = '';
					theCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsChangeCase(theCase);
				update theCase;
				removeCaseContext(theCase);
				return null;
			} else if (caseType == 'Benefits New Plan Case') {
				if (caseType != theCase.RecordType.Name) {
					theCase.Routing_Case_Reason__c = '';
					theCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsNewPlanCase(theCase);
				update theCase;
				removeCaseContext(theCase);
				return null;
			} else if (caseType == 'Benefits Renewal Case') {
				if (caseType != theCase.RecordType.Name) {
					theCase.Routing_Case_Reason__c = '';
					theCase.Reason = '';
				}
				CaseUtils.RouteCaseToBenefitsRenewalCase(theCase);
				update theCase;
				removeCaseContext(theCase);
				return null;
			} else if (caseType == 'Member Fulfillment Emails') {
				if (caseType != theCase.RecordType.Name) {
					theCase.Routing_Case_Reason__c = '';
					theCase.Reason = '';
				}
				CaseUtils.RouteCaseToMemberFulfillmentCase(theCase);
				update theCase;
				removeCaseContext(theCase);
				return null;
			} else if (caseType == 'Engagement') {
				CaseUtils.RouteCaseToEngagement(theCase);
				update theCase;
				removeCaseContext(theCase);
				PageReference pgref = new PageReference('/apex/EngagementCasePage?id=' + theCase.id + '&refreshPage=true');
				return pgref;
			}
		}

		return null;
	}

	public static List<SelectOption> caseTypeOptionList() {
		List<SelectOption> caseTypeOption = new List<SelectOption>();
		caseTypeOption.add(new SelectOption('Engagement', 'Engagement'));
		caseTypeOption.add(new SelectOption('Tax Res', 'Tax Res'));
		caseTypeOption.add(new SelectOption('Tax Ops', 'Tax Ops'));
		caseTypeOption.add(new SelectOption('Modern Bank', 'Modern Bank'));
		caseTypeOption.add(new SelectOption('Payroll Compliance', 'Payroll Compliance'));
		caseTypeOption.add(new SelectOption('Risk Assurance', 'Risk Assurance'));
		caseTypeOption.add(new SelectOption('Sales Cases', 'Sales Cases'));
		caseTypeOption.add(new SelectOption('Benefits BoR', 'Benefits BoR'));
		//DS[27-Oct-2020] : add PayrollOps Audit case to route
		caseTypeOption.add(new SelectOption(strPAYROLLOPS_AUDIT, strPAYROLLOPS_AUDIT));
		caseTypeOption.add(new SelectOption('Benefits Change Case', 'Benefits Change Case'));
		caseTypeOption.add(new SelectOption('Benefits New Plan Case', 'Benefits New Plan Case'));
		caseTypeOption.add(new SelectOption('Benefits Renewal Case', 'Benefits Renewal Case'));
		caseTypeOption.add(new SelectOption('Member Fulfillment Emails', 'Member Fulfillment Emails'));

		return caseTypeOption;
	}

	public static List<SelectOption> caseEngagementTypeOptionList() {
		List<SelectOption> caseEngagementTypeOptionList = new List<SelectOption>();
		caseEngagementTypeOptionList.add(new SelectOption('Engagement', 'Engagement'));
		caseEngagementTypeOptionList.add(new SelectOption('Tax Res', 'Tax Res'));
		caseEngagementTypeOptionList.add(new SelectOption('Tax Ops', 'Tax Ops'));
		caseEngagementTypeOptionList.add(new SelectOption('Modern Bank', 'Modern Bank'));
		caseEngagementTypeOptionList.add(new SelectOption('Risk Assurance', 'Risk Assurance'));
		caseEngagementTypeOptionList.add(new SelectOption('Sales Cases', 'Sales Cases'));

		return caseEngagementTypeOptionList;
	}

	public static List<SelectOption> caseStatusOptionList() {
		List<SelectOption> caseStatusOption = new List<SelectOption>();
		caseStatusOption.add(new SelectOption('New', 'New'));
		caseStatusOption.add(new SelectOption('Open', 'Open'));
		caseStatusOption.add(new SelectOption('In Progress', 'In Progress'));
		caseStatusOption.add(new SelectOption('Awaiting Response', 'Awaiting Response'));
		caseStatusOption.add(new SelectOption('Response Received', 'Response Received'));
		caseStatusOption.add(new SelectOption('Solved', 'Solved'));
		return caseStatusOption;
	}

	public static List<SelectOption> caseStatusDetailOptionList() {
		List<SelectOption> caseStatusDetailOption = new List<SelectOption>();
		caseStatusDetailOption.add(new SelectOption('', '--Select--'));
		caseStatusDetailOption.add(new SelectOption('Researching', 'Researching'));
		caseStatusDetailOption.add(new SelectOption('Contacting Agency', 'Contacting Agency'));
		caseStatusDetailOption.add(new SelectOption('Processing Corrections', 'Processing Corrections'));
		caseStatusDetailOption.add(new SelectOption('Waiting/Need Info Agency', 'Waiting/Need Info Agency'));
		caseStatusDetailOption.add(new SelectOption('Waiting/Need Info Bank', 'Waiting/Need Info Bank'));
		caseStatusDetailOption.add(new SelectOption('Waiting/Need Info Client', 'Waiting/Need Info Client'));
		caseStatusDetailOption.add(new SelectOption('Waiting/Need Info Gusto', 'Waiting/Need Info Gusto'));
		return caseStatusDetailOption;
	}

	//DS[27-Oct-2020] : add PayrollOps Audit case to route
	public static List<SelectOption> casePayrollAuditStatusDetailOptionList() {
		List<SelectOption> caseStatusDetailOption = new List<SelectOption>();
		caseStatusDetailOption.add(new SelectOption('', '--Select--'));
		caseStatusDetailOption.add(new SelectOption('Researching', 'Researching'));
		caseStatusDetailOption.add(new SelectOption('Contacting Agency', 'Contacting Agency'));
		caseStatusDetailOption.add(new SelectOption('Awaiting Info', 'Awaiting Info'));
		return caseStatusDetailOption;
	}

	public static boolean checkForDedicateUser() {
		List<User> usrList = [SELECT id, UserRole.Name FROM User WHERE id = :UserInfo.getUserId()];

		if (usrList.size() > 0 && usrList.get(0).UserRole.Name != null && usrList.get(0).UserRole.Name.contains('Dedicated Support')) {
			return true;
		}

		return false;
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Get Tax_Res_Play_Mode_Configuration__mdt records based on developer name
	 * @Parm        : String Developer Name
	 * @Return      : Map of Metadata records.
	 **/
	public static Tax_Res_Play_Mode_Configuration__mdt getQueryConfigurationRecords(String strConfigurationName) {
		Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_ConfigurationsMetadata = new Map<String, Tax_Res_Play_Mode_Configuration__mdt>();
		for (Tax_Res_Play_Mode_Configuration__mdt objConfig : [
			SELECT Id, Active__c, Filter_Value__c, DeveloperName, Team__c
			FROM Tax_Res_Play_Mode_Configuration__mdt
			WHERE DeveloperName = :strConfigurationName AND Active__c = TRUE
		]) {
			map_ConfigurationsMetadata.put(objConfig.DeveloperName, objConfig);
		}

		return map_ConfigurationsMetadata.get(strConfigurationName);
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Get Set of agency names which are supported by RingLead routing
	 * @Parm        : N/A
	 * @Return      : Map of Metadata records.
	 **/
	public static Set<String> getRingLeadEligibleAgencies() {
		List<String> list_PilotAgencies = new List<String>();
		Set<String> set_PilotAgencies = new Set<String>();
		Tax_Res_Play_Mode_Configuration__mdt objPilotAgenciesConfig = new Tax_Res_Play_Mode_Configuration__mdt();
		objPilotAgenciesConfig = getQueryConfigurationRecords(CONFIG_TAXRESPILOTAGENCIES);
		list_PilotAgencies = objPilotAgenciesConfig?.Filter_Value__c?.split(';');
		if (list_PilotAgencies?.size() > 0) {
			set_PilotAgencies.addAll(list_PilotAgencies);
		}

		return set_PilotAgencies;
	}

	/**
	 * @Author      : Elavarasan Nagarathinam
	 * @Description : Get the date of n business days from today
	 * @Parm        : Integer (how many busisness days)
	 * @Return      : Date
	 **/
	@AuraEnabled
	public static Date getNBusinessDaysAfter(Integer intDaysAfterBusinessDays) {
		BusinessHours objBusinessHourObj = Utils.objDefaultBuinessHourRec;
		Datetime dtmDateAfterNBusinessDays = BusinessHours.add(objBusinessHourObj.Id, System.now(), intDaysAfterBusinessDays * 9 * 60 * 60 * 1000);
		Date dtReturnedDate = dtmDateAfterNBusinessDays != null ? Date.valueof(dtmDateAfterNBusinessDays) : System.today();
		return dtReturnedDate;
	}

	/**
	 * @Author      : Ela Nagarathinam
	 * @Sescription : Update case ownership of taxres cases based on if the case is already indexed or not
	 * @Param       : Map of Cases to be updated
	 * @Return      : N/A
	 */
	public static void taxResCaseOwnerUpdate(Map<Id, Case> map_Cases, List<CaseHistory> list_CaseHistory) {
		Map<Id, Boolean> map_CaseIndexedMap = new Map<Id, Boolean>();
		if (map_Cases == null || map_Cases.isEmpty()) {
			return;
		}

		if (list_CaseHistory == null || list_CaseHistory.isEmpty()) {
			list_CaseHistory = GlobalQueryHelper.getCaseHistoryByUpdatedField(map_Cases.keySet(), 'Status');
		}

		Set<Id> set_CaseIds = new Set<Id>();
		for (CaseHistory objCaseHistory : list_CaseHistory) {
			set_CaseIds.add(objCaseHistory.CaseId);
			Boolean blnCaseIndexed = objCaseHistory.NewValue == CASE_STATUS_DATA_CAPTURE_COMPLETE ? true : false;
			if (!blnCaseIndexed && map_Cases.containsKey(objCaseHistory.CaseId)) {
				blnCaseIndexed = map_Cases.get(objCaseHistory.CaseId).Status == CASE_STATUS_DATA_CAPTURE_COMPLETE;
			}

			if (map_CaseIndexedMap.containsKey(objCaseHistory.CaseId) && !map_CaseIndexedMap.get(objCaseHistory.CaseId) && blnCaseIndexed) {
				map_CaseIndexedMap.put(objCaseHistory.CaseId, true);
			} else if (!map_CaseIndexedMap.containsKey(objCaseHistory.CaseId) && blnCaseIndexed) {
				map_CaseIndexedMap.put(objCaseHistory.CaseId, true);
			} else if (!map_CaseIndexedMap.containsKey(objCaseHistory.CaseId) && !blnCaseIndexed) {
				map_CaseIndexedMap.put(objCaseHistory.CaseId, false);
			}
		}

		for (Case objCase : map_Cases.values()) {
			// if case is already indexed, assign it to ready for research status
			// if not indexed before, then assign it to data capture queue
			if (map_CaseIndexedMap != null && map_CaseIndexedMap.containsKey(objCase.Id) && map_CaseIndexedMap.get(objCase.Id)) {
				objCase.Status = CASE_STATUS_READY_FOR_RESEARCH;
			} else {
				objCase.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
				objCase.OwnerId = ID_TAX_RES_DATA_CAPTURE_QUEUE;
				objCase.Type = TYPE_TAX_RES;
			}
		}
	}

	/**
	 * @Author      : Ankit C
	 * @Sescription : This method is invoked from flow to update the pillar fields on Case
	 * @Param       : list_Cases - List of Cases to be updated
	 * @Return      : List of cases
	 */
	@InvocableMethod(label='Update Case Pillar' description='Updates the pillar fields on Case' category='Case')
	public static List<Case> updateCasePillarFields(List<Case> list_Cases) {
		Case objCase = new Case();
		if (!list_Cases.isEmpty()) {
			objCase = list_Cases.get(0);
			CaseTriggerHelper.updateCasePillar(objCase, null);
		}

		return new List<Case> { objCase };
	}
}