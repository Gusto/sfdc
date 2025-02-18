/**
 * @name         TicketUtil
 * @author       Deepika Saini
 * @date         13-Apr-2021
 * @description  Utility class to hold constants and common data
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class TicketUtil {
	public static final String PERFIX_USER = '005';
	public static final String LABEL_ALL = 'All';
	public static final String LABEL_MY = 'My';
	public static final String TICKET_LOST_OUT_OF_BUSINESS = 'Out of business';

	public static final String TICKET_STATUS_CLOSED = 'Closed';
	public static final String TICKET_STATUS_INPROGRESS = 'InProgress';
	public static final String TICKET_STATUS_ESCALATED = 'Escalated';
	public static final String TICKET_STATUS_INCOMPLETE = 'Incomplete';
	public static final String TICKET_STATUS_ER_OUTREACH_REQ = 'ER Outreach Required';
	public static final String TICKET_OWNER_ROLE_TYPE_CORE = 'Core';
	public static final String TICKET_STATUS_LOST = 'Lost';
	public static final String TICKET_STATUS_DATA_LOAD = 'Data Load';
	public static final String TICKET_STATUS_SOLVED = 'Solved';
	public static final String TICKET_STATUS_COMPLETE = 'Complete';
	public static final String TICKET_STATUS_RESOLVED = 'Resolved';
	public static final String TICKET_STATUS_REPORT_CREATION = 'Report Creation';
	public static final String TICKET_STATUS_CALC_APPROVAL_PENDING = 'Calc Approval Pending';
	public static final String TICKET_STATUS_REVIEW = 'In Review';

	public static final Set<String> set_StatusDone = new Set<String>{ TICKET_STATUS_CLOSED, TICKET_STATUS_SOLVED, TICKET_STATUS_COMPLETE, TICKET_STATUS_RESOLVED };

	public static final String BEFORE_EVENT = 'Before';
	public static final String BEFORE_ONWARD_EVENT = 'BeforeOnward';
	public static final String AFTER_EVENT = 'After';
	public static final String TICKET_PRIORITY_LOW = 'Low';
	public static final String TICKET_PRIORITY_MEDIUM = 'Medium';
	public static final String TICKET_PRIORITY_HIGH = 'High';
	public static final String TICKET_PRIORITY_URGENT = 'Urgent';

	//RecordTypes
	public static final Id BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding NewPlans');
	public static final Id BENEFITS_ONBOARDING_RENEWAL_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Benefits Onboarding Renewals');
	public static final Id ADVISING_FULFILLMENT_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Advising Fulfillment');
	public static final Id NEW_PLAN_SALES_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'New Plan Sales');
	public static final Id BENEFITS_COMPLIANCE_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Benefits Compliance');
	public static final Id MEMBER_OPERATIONS_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Member Operations');
	public static final Id ADVISING_FULFILLMENT_CARE_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Advising Fulfillment Care');
	public static final Id PAYROLL_AUDIT_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Payroll Audit');
	public static final Id QUALIFICATION_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Qualification');
	public static final Id BENEFITS_TRANSFER_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Benefits Transfer');
	public static final Id BENEFITS_BYB_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Benefits BYB');
	public static final Id ARDIUS_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Ardius');
	public static final Id MB_COMPLIANCE_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'MB Compliance');
	public static final Id CARRIER_SUPPORT_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Carrier Support Follow Up');
	public static final Id CREDIT_COLLECTIONS_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Credit & Collections');
	public static final Id FINANCIAL_CRIMES_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Financial Crimes Operations');
	public static final Id GUSTO_LEARN_SUPPORT_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'GustoLearn Support');
	public static final Id MEMBER_FULFILLMENT_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Member Fulfillment');
	public static final Id NEW_PLAN_FULFILLMENT_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'New Plan Fulfillment');
	public static final Id PAYROLL_TRANSFER_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Payroll Transfer');
	public static final Id RISK_INVESTIGATION_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Risk Investigation');
	public static final Id SALES_ESCALATION_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Sales Escalation');
	public static final Id API_INTEGRATION_ESCALATION_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'API Integration Escalation');
	public static final Id PAYROLL_SALES_ESCALATION_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Payroll Sales Escalation');
	public static final Id SOLUTION_ENGINEER_REQUEST_TICKET_RT_ID = Cache.getRecordTypeId('Ticket__c', 'Solution Engineer Request');

	public static final String CLOSED = 'Closed';
	public static final String SUBMISSION = 'Submission';
	public static final String FULFILLED = 'Fulfilled';
	public static final String APPROVED = 'Approved';
	public static final String APPROVED_PENDING_EE_AUDIT = 'Approved Pending EE Audit';
	public static final String CARRIER_IMPLEMENTATION_QUEUE_ID = GlobalQueryHelper.getQueueIdByName('Carrier Implementation Queue');
	public static final String TICKET_STATUS_ERROR_MESSAGE = 'Carrier Order does not have an owner, please reach out to Fulfillment team.';

	public static final String AWAITING_ER_STATUS = 'Awaiting ER response - Pending Item';
	public static final String TERMINATED_ORDER = 'Terminated Order';
	public static final String CONTROL_GROUP = 'Control Group';

	public static Set<Id> set_BenefitsOnboardingRelatedTickets = new Set<Id>{
		ADVISING_FULFILLMENT_TICKET_RT_ID,
		BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID,
		BENEFITS_ONBOARDING_RENEWAL_TICKET_RT_ID,
		NEW_PLAN_SALES_TICKET_RT_ID
	};

	//Role Names
	public static final string TICKET_ROLE_QUALIFICATION = 'Qualification';
	public static final string TICKET_ROLE_FULFILLMENT = 'Fulfillment';
	public static final String TICKET_ROLE_IMPLEMENTATION = 'Implementation Advocate';
	public static final String TICKET_ROLE_IMPLEMENTATION_PE = 'Implementation Advocate - PE';
	public static final String TICKET_ROLE_IMPLEMENTATION_AMPLIFIER = 'Implementation Advocate - Amplifier';
	public static final String TICKET_ROLE_CARRIER_IO = 'Carrier IO';
	public static final String TICKET_ROLE_CORE_COMPLETE = 'Core & Complete';
	public static final String TICKET_ROLE_DEDICATED_SUPPORT = 'Dedicated Support';
	public static final String TICKET_ROLE_MODERN_BANK = 'Modern Bank';

	//Ticket Teams
	public static final String TICKET_TEAM_GROUPS_OPS = 'Group Ops';
	public static final String TICKET_TEAM_ADVISING = 'Benefits Advising';
	public static final String TICKET_TEAM_NEW_PLAN_SALES = 'New Plan Sales';
	public static final String TICKET_TEAM_FULL_STACK_SALES = 'Full Stack Sales';
	public static final String TICKET_TEAM_BOR_SALES = 'BoR Sales';
	public static final String TICKET_TEAM_BYB_MEMBER_OPS = 'BYB Member Ops';
	public static final String TICKET_TEAM_ONBOARDING = 'Onboarding';
	public static final String TICKET_TEAM_BENEFIT_COMPLAINCE = 'Benefits Compliance';
	public static final String TICKET_MEMBER_PROCESSING = 'Member Processing';
	public static final String TICKET_MEMBER_OPERATIONS = 'Member Operations';
	public static final String TICKET_BENEFIT_TRANSFER = 'Benefits Transfer';
	public static final String TICKET_SUB_TEAM_AUDIT = 'Audit';
	public static final String OBJECT_QC_ERROR = 'QA_Errors__c';
	public static final String OBJECT_TICKET = 'Ticket__c';
	public static final String QA_ERROR_TEAM_ADVISING = 'Advising Fulfillment';

	//Messages
	public static final String ERR_CARRIER_ORDER_HAS_OPEN_TASK = 'Closing this ticket will move the Carrier Order to ‘Approved’. This order is unable to be approved as there is an open task on the carrier order. Please complete any open tasks, then close this ticket.';
	public static final String REQ_MSG_QC_ERROR_TYPE_DETAIL = 'Please select QC Error Type Detail.';
	public static final String REQ_MSG_QC_ERROR_TYPE = 'Please select QC Error Type.';
	public static final String REQ_MSG_TICKET_AMPLIFIER = 'Ticket Amplifier is required.';
	public static final String REQ_MSG_TICKET_REASON = 'Please select Ticket Reason.';
	public static final String REQ_MSG_SUB_TEAM = 'Please select Sub Team.';
	public static final String REQ_MSG_TICKET_REASON_DETAIL = 'Please select Ticket Reason Detail.';
	public static final String REQ_MSG_ASSOCIATED_CARRIER = 'Tickets for Fulfillment Sub Team must have associated Carrier Order which is assigned to Carrier Order Owner.';
	public static final String REQ_MSG_ASSOCIATED_CARRIER_CONFIRM = 'Tickets for Fulfillment Sub Team must have associated Carrier Order which is assigned to Carrier Order Owner.';
	public static final String REQ_MSG_CARRIER = 'Please select Carrier.';
	public static final String REQ_MSG_STATES = 'Please select States.';
	public static final String REQ_MSG_PRIORITY = 'Please select Priority.';
	public static final String REQ_MSG_DESCRIPTION = 'Please add Description.';
	public static final String REQ_MSG_ATTACHMENT = 'Please add Attachment.';
	public static final String REQ_MSG_QC_ERROR_OWNER = 'QC Error Owner Required.';
	public static final String REQ_MSG_QC_ERROR_TEAM = 'Please select QC Error Team.';
	public static final String MSG_ERROR_IN_TICKET_CREATION = 'Error in Ticket creation.';
	public static final String REQ_MSG_ERROR_TYPE = 'Please select Error Type.';
	public static final String REQ_MSG_ERROR_ORIGIN = 'Please select Error Origin.';
	public static final String REQ_MSG_ERROR_ORIGIN_DATE = 'Please select Error Origin Date.';
	public static final String REQ_MSG_IMREBURSEMENT_AMT_REQ = 'Please select Reimbursement Amount Requested.';
	public static final String REQ_MSG_DISCOUNT_MONTH_REQ = 'Please select Number of Discounted Months Requested.';
	public static final String REQ_MSG_DISCOUNT_AMT_REQ = 'Please select Discount Amount Requested.';
	public static final String REQ_MSG_BROKERS_NAME = 'Please select Brokers Name.';
	public static final String REQ_MSG_BROKERS_TEAM = 'Please select Brokers Team.';
	public static final String REQ_MSG_BROKERS_HOME_STATE = 'Please select Brokers Home State.';
	public final static String REQ_MSG_DUE_DATE = 'Please select Due Date.';
	public static final String REQ_MSG_SUMMARY = 'Summary: You must enter a value';
	public static final String REQ_MSG_NOT_ALLOWED_TO_CREATE_TICKET = 'You are not allowed to create ticket/QC Error';
	public static final String REQ_MSG_CO_REQUIRED = 'QC Error For Fulfillment Sub Team must have associated Carrier Order which is assigned to Carrier Order Owner.';
	public static final String TICKET_OWNER_MSG = 'Please change the ticket owner from a queue to a user';
	public static final String TICKET_OWNER_IS_NOT_POPULATED = 'Please refresh the page, the ticket owner did not save correctly';

	public final static String PICKLIST_VALUE_YES = 'Y';

	public static final String QUEUE_ADVISNG_INBOUND_SUPPORT = 'Advising_Inbound_Support';
	public static final String QUEUE_MEMBER_FULFILLMENT_BYB = 'Member_Ops_BYB';
	public static final String QUEUE_NAME_MEMBER_FULFILLMENT_BYB = 'Member Ops - BYB';
	public static final String QUEUE_MEMBER_OPS = 'Member Fulfillment';
	public static final String QUEUE_ADVISING_FULFILLMENT = 'Advising Fulfillment';
	public static final String QUEUE_NAME_PAYROLL_AUDIT = 'Payroll Audit';
	public static final String QUEUE_NAME_QUALIFICATION = 'Qualification';
	public static final String QUEUE_NAME_BENEFIT_TRANSFER = 'Benefit Transfer';
	public static final String QUEUE_NAME_MB_COMPLIANCE = 'MB Compliance';
	public static final String QUEUE_NAME_BENEFITS_COMPLIANCE = 'Benefits Compliance Queue';
	public static final String QUEUE_NAME_CARE_ESCALATIONS = 'Care Escalations Queue';
	public static final String QUEUE_NAME_CARE_QUESTION = 'Care Question Queue';
	public static final String QUEUE_NAME_CREDIT_COLLECTIONS = 'Credit & Collections';
	public static final String QUEUE_NAME_FINANCIAL_CRIMES = 'Financial Crimes';
	public static final String QUEUE_NAME_GUSTO_LEARN_SUPPORT = 'GustoLearn Support';
	public static final String QUEUE_NAME_NEW_PLAN_FULFILLMENT = 'New Plan Fulfillment';
	public static final String QUEUE_NAME_NEW_PLAN_SALES = 'New Plan Sales';
	public static final String QUEUE_NAME_PAYROLL_TRANSFER = 'Payroll Transfer';
	public static final String QUEUE_NAME_RISK_INVESTIGATION = 'Risk Investigation';
	public static final String QUEUE_NAME_SALES_ESCALATION = 'Sales Escalation';
	public static final String QUEUE_NAME_TAX_OPS = 'Tax Ops';
	public static final String QUEUE_NAME_BIZ_DEV = 'BizDev';

	public static final Set<String> set_AdvisingQueueNames = new Set<String>{ QUEUE_ADVISNG_INBOUND_SUPPORT, QUEUE_MEMBER_FULFILLMENT_BYB };
	public static Map<String, Id> map_AdvisingQueue = GlobalQueryHelper.getQueueNameAndIdMap(set_AdvisingQueueNames);

	public static final String ORDER_STATUS_BACK_TO_PRIOR = 'Back to status prior to ticket creation';
	public static final String TICKET_ORDER_STATUS_PENDING_ITEM = 'Pending Item';
	public static final String TICKET_ORDER_STATUS_BLOCKED = 'Blocked';
	public static final String TICKET_REASON_PENDING_AUDIT = 'Pending Audit';
	public static final String TICKET_REASON_TADA_TERMINATION = 'TAdA Termination';
	public static final String TICKET_REASON_FEIN_INVALID = 'FEIN Invalid Pill Blocking Onboarding';
	public static final String FIELD_TO_SUB_TEAM = 'To_Sub_team__c';
	public static final String AUTOMATED_QC_ERROR_REQUIRED_VALUE_OPPORTUNITY = 'Opportunity Owner';
	public static final String AUTOMATED_QC_ERROR_REQUIRED_VALUE_YES = 'Yes';

	public static final String CASE_TYPE_CARRIER_SUBMISSION = 'Carrier Submission';
	public static final String CASE_TYPE_NEW_PLAN = 'Benefits New Plan';
	public static final String CASE_TYPE_RENEWAL = 'Benefits Renewal';
	public static final String CASE_TYPE_BYOB = 'BYOB';
	public static final String TICKET_STATUS_NEW = 'New';
	public static final String TICKET_ORDER_STATUS_NO_IMPACT = 'No Impact on Status';
	public static final String TICKET_ORDER_STATUS_REQUIRES_ER_OUTREACH = 'Requires ER Outreach';
	public static final String TICKET_REASON_AUDIT_ERROR = 'Audit Error Found';
	public static final String TICKET_REASON_RECERTIFICATION = 'Recertification';
	public static final String TICKET_REASON_EXISTING_GROUP = 'Existing Group Coverage/BoR';
	public static final String TICKET_REASON_CARE_ESCALATION = 'Care Escalation';
	public static final String TICKET_REASON_CARE_QUESTION = 'Care Question';
	public static final String TICKET_REASON_ATO = 'ATO';
	public static final String TICKET_REASON_REPLY_ATO_EMAIL = 'Reply to ATO Email';
	public static final String TICKET_REASON_TWO_FACTOR_ACTIVITY = 'Two-Factor Activity';
	public static final String TICKET_REASON_COMPANY_ONBOARDING = 'Company Onboarding';
	public static final String TICKET_REASON_GENERAL_RISK = 'General Risk';
	public static final String TICKET_REASON_BUSINESS_DISPUTE = 'Business Dispute';
	public static final String TICKET_REASON_LEGAL_REQUESTS = 'Legal Requests';
	public static final String TICKET_REASON_TWO_DAY_PAYROLL = '2-Day Payroll';
	public static final String TICKET_REASON_EXPEDITED_PAYROLL = 'Expedited Payroll';
	public static final String STR_ONLY_AFFECTED_CO = 'Only Affected CO';
	public static final String RECERT_STATUS_ADVISOR_ACTION_NEEDED = 'Advisor action needed';
	public static final String EMAIL_AUTOMATION_FAILED = 'Email Automation Failed';
	public static final String RECERT_STATUS_RECERT_FAILED = 'Recert Failed';

	public static final String ICP_FIT_COMPLETE = 'Complete';
	public static final String ICP_FIT_WORKABLE = 'Workable';

	//Ticket Template Type
	public static final String ARDIUS_TICKET_TEMPLATE = 'Ardius';
	public static final String TICKET_TEMPLATE_FV_AMENDMENT_ELIGIBLE = 'FV_Amendment_Eligible';
	public static final String TICKET_TEMPLATE_EC_FV_AMENDMENT_ELIGIBLE = 'EC FV_Amendment_Eligible';

	public static final String STR_ORDER = 'Order';
	public static final String STR_AUDIT = 'Audit';
	public static final String STR_POST_PLAY = 'Post Play';
	public static final String STR_FACILITATOR_1 = 'Facilitator 1';
	public static final String STR_FACILITATOR_2 = 'Facilitator 2';

	//Qualification Status
	public static final String QUALIFICATION_STATUS_DISQUALIFIED = 'disqualified';
	public static final String QUALIFICATION_STATUS_QUALIFIED = 'Qualified';

	//Object prefixes
	public static final String USER_PREFIX = User.sObjectType.getDescribe().getKeyPrefix();
	public static final String GROUP_PREFIX = Group.sObjectType.getDescribe().getKeyPrefix();

	//Expreiment Code Field Value on Ticket
	public static final String STR_TICKET_EXPERIMENT_CODE_VALUE = 'Fall Ownership';

	public static final Set<String> set_CanceledStatus = new Set<String>{ 'Canceled', 'Closed Lost', 'Closed Admin' };
	public static final Set<String> set_ClosedStatuses = new Set<String>{ 'Canceled', 'Closed Admin' };

	public static final Set<String> set_EventTypes = new Set<String>{ STR_ORDER, STR_AUDIT };

	public static final Set<String> set_QueueNames = new Set<String>{
		QUEUE_NAME_PAYROLL_AUDIT,
		QUEUE_NAME_MEMBER_FULFILLMENT_BYB,
		QUEUE_NAME_BENEFIT_TRANSFER,
		QUEUE_ADVISING_FULFILLMENT,
		QUEUE_NAME_QUALIFICATION,
		QUEUE_NAME_MB_COMPLIANCE,
		QUEUE_NAME_BENEFITS_COMPLIANCE,
		QUEUE_NAME_CARE_ESCALATIONS,
		QUEUE_NAME_CARE_QUESTION,
		QUEUE_NAME_CREDIT_COLLECTIONS,
		QUEUE_NAME_FINANCIAL_CRIMES,
		QUEUE_NAME_GUSTO_LEARN_SUPPORT,
		QUEUE_NAME_NEW_PLAN_SALES,
		QUEUE_NAME_PAYROLL_TRANSFER,
		QUEUE_NAME_RISK_INVESTIGATION,
		QUEUE_NAME_SALES_ESCALATION,
		QUEUE_NAME_BIZ_DEV
	};

	//Ticket Statuses Where Tasks TO Be Excluded From Owner Change
	public static final Set<String> set_TICKET_STATUS_EXCLUDED_FROM_OWNER_CHANGE = new Set<String>{ TICKET_STATUS_DATA_LOAD, TICKET_STATUS_REPORT_CREATION, TICKET_STATUS_CALC_APPROVAL_PENDING };

	//Ticket Communication Status
	public final static String COMM_STATUS_IN_PROGRESS = 'In Progress';
	public final static String COMM_STATUS_AWAITING_RESPONSE = 'Awaiting Response';
	public final static String COMM_STATUS_RESPONSE_RECEIVED = 'Response Received';

	//Task Field API Names
	public final static String TASK_FIELD_PRIORITY = 'Priority';
	public final static String TASK_FIELD_STATUS = 'Status';
	public final static String TASK_FIELD_TYPE = 'Type';

	//Ticket Responsive identifiers
	public final static String RI_UN_RESPONSIVE = 'UN_RESPONSIVE';
	public final static String RI_RESPONSIVE = 'RESPONSIVE';

	public static String getLoggedInUserRoleName() {
		User objUser = GlobalQueryHelper.getUserInfoById(UserInfo.getUserId());
		return objUser?.UserRole?.Name;
	}

	/**
	 * @description Returns set of integration user ids who creates Ardius tickets
	 * @return      `Set<Id>`
	 */
	public static Set<Id> getArdiusTicketIntegrationUsers() {
		Ardius_Configuration__c objArdiusConfiguration = Ardius_Configuration__c.getInstance();
		Set<Id> set_IntegrationUserIds = new Set<Id>();
		if (objArdiusConfiguration.Ticket_Integration_Users__c != null) {
			for (String strUserId : objArdiusConfiguration.Ticket_Integration_Users__c.split(';')) {
				set_IntegrationUserIds.add(strUserId);
			}
		}
		return set_IntegrationUserIds;
	}

	/**
	 * @description Returns set of ticket statuses for which opportunity should be updated to 'closed won'
	 * @return      `Set<String>`
	 */
	public static Set<String> getArdiusTicketStatusesToUpdateOppty() {
		Ardius_Configuration__c objArdiusConfiguration = Ardius_Configuration__c.getInstance();
		Set<String> set_TicketStatuses = new Set<String>();
		if (objArdiusConfiguration.Client_Approval_Tracking_Ticket_Statuses__c != null) {
			for (String strTicketStatus : objArdiusConfiguration.Client_Approval_Tracking_Ticket_Statuses__c.split(';')) {
				set_TicketStatuses.add(strTicketStatus);
			}
		}
		return set_TicketStatuses;
	}

	/**
	 * @description Returns set of ticket statuses for which opportunity should be updated to 'Closed Lost'
	 * @return      `Set<String>`
	 */
	public static Set<String> getArdiusTicketStatusToUpdateOppToCloseLost() {
		set<String> set_TicketStatuses = new Set<String>();
		set_TicketStatuses.add(TICKET_STATUS_LOST);
		return set_TicketStatuses;
	}
}