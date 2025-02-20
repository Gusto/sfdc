import { displayToast, PicklistOption, TOAST_PARAMS, FIELD_TYPE, checkInputValidity, checkInputFieldValidity } from "c/utilityService";

import TASK_CALL_PICKLIST from "@salesforce/label/c.Task_Call_Picklist";
import TAX_YEAR_LABEL from "@salesforce/label/c.CurrentTaxYear";

const TASK_CALL_DISPOSITION = {
	ATTEMPT: "Attempt",
	VOICEMAIL: "Voicemail",
	CONNECT: "Connect",
	NO_CALL: "No Call",
	NO_SHOW: "No Show"
};
const USER_PROFILE = { BENEFITS_USER: "Benefits User", MMPR_USER: "MMPR User", CX_USER: "CX User", ARD_BASE_USER: "Ardius Base User" };
const USER_ROLE = { SALES_SB_OB_XX: "sales_sb_ob_xx", SALES_SB_OB_SME: "sales_sb_ob_sme", PARTNER: "Partner" };
const TASK_PRIORITY = { HIGH: "High", NORMAL: "Normal", LOW: "Low" };
const HI_OPPORTUNITY_TYPE = { HI_BENEFITS_NEW_PLAN: "HI Benefits New Plan", HI_BENEFITS_BOR: "HI Benefits BoR", BENEFITS_BYOB: "Benefits BYOB" };

const TASK_SUBJECT = { FOLLOW_UP_CALL: "Follow up Call" };
const OPP_STAGE = { RAW: "Raw" };
const ARDIUS_OPP_STAGE = { NEW: "New" };
const TAX_CREDIT_TYPE = { NB: "New Business" };
const TAX_YEAR = TAX_YEAR_LABEL;
const TASK_TYPE = {
	NEW_COLD_CALL: "New Cold Call",
	REGURAL_CALL: "Regular Call",
	PITCH_DEMO: "Pitch/Demo",
	CALL: "Call",
	PITCH_W_O_DEMO: "Pitch w/o Demo",
	DEMO: "Demo",
	OUTBOUND_CALL: "Outbound Call",
	INBOUND_CALL: "Inbound Call",
	EMAIL: "Email",
	IN_APP_SCHEDULER: "In-App Scheduler",
	SCHEDULED_CALL: "Scheduled Call",
	DEMO_ONLY: "Demo Only",
	PITCH_ONLY: "Pitch Only",
	PITCH_AND_DEMO: "Pitch & Demo"
};
const PRODUCT_UPSELL_RT_NAME = { CUSTOMER_SUCCESS: "Customer Success" };
const SOBJECT_NAME = {
	Opportunity: "Opportunity",
	Account: "Account",
	Lead: "Lead",
	Benefit_Order__c: "Benefit_Order__c",
	Ticket__c: "Ticket__c"
};

const LEAD_STATUS = {
	FUTURE_OPPORTUNITY: "Future Opportunity",
	UNQUALIFIED: "Unqualified",
	AQL: "AQL",
	MQL: "MQL"
};

const FEATURE_REQUEST_TYPE = {
	PTO: "Time Tracking / PTO",
	PAYROLL_EXP_REIMB: "Payroll, Expenses/Reimbursements",
	REPORTING: "Reporting",
	COMMS: "Comms (emails/todo notifications)",
	PPREMISSIONS_ORGCHART_DEPT: "Permissions, Org chart, Departments",
	PREFORMANCE_TOOLS: "Performance tools",
	HIRING_DISMISSING_TOOLS: "Hiring / Dismissing tools",
	GUSTO_MANAGED_BENEFITS: "Gusto Managed Benefits (Benefits)",
	BYB: "BYB (Benefits)",
	OTHER: "Other"
};

const LEAD_STATUS_DETAIL = { FEATURE_NOT_LISTED: "Feature Not Listed", OTHER: "Other" };
const DETAIL = "Detail";
const ADDITIONAL_INFO = "Additional Info";
const NOTES = "Notes:";
const ACTION_ITEMS = "Action Items:";

const ERROR_MSGS = {
	NO_ALL_SMART_CALLING_METADATA: "No AllSmartCalling metadata record found for your profile and this object. Please contact a BizTech admin.",
	REQUIRED_FIELDS_MISSING: "Required Fields are missing",
	CALL_NOT_FINISHED_PROCESSING: "Call not finished processing.",
	WAIT_AND_TRY_AGAIN: "Please wait a moment before trying again.",
	PROVIDE_ADDITNL_CONTXT_FOR_CLOSED_REASONS: "Please provide additional context about the closed reasons for this lead",
	LEAD_STATUS_DETAIL_REQUIRED: "Lead Status Detail is required",
	LEAD_CANT_GO_BACK_TO_MQL_AQL: "A lead in Unqualified cannot go back to MQL or AQL",
	SELECT_CONTACT_BEFORE_SAVING: "Please select a contact before saving.",
	SELECT_DIFFERENT_SEC_CONTACT: "Secondary contact should not be same as the Contact Name selected above.",
	TAX_YEAR_LENGTH: "Tax year should be 4 digits long.",
	PRODUCT_INTEREST_COUNTRIES_REQUIRED: "Product Interest Countries are required if add product interest is checked.",
	LEAD_PASS_FIELDS_REQUIRED: "Please select at least one country in the Product Interest Countries or Additional Countries to Save this Lead Pass.",
	LEAD_PASS_NOT_AVAILABLE: "This action is not available for your user role and profile. Please contact your PE if you feel this is an error.",
	CROSS_SELL_OPPORTUNITY_FOR_ICP_ALREADY_EXISTS: "An ICP Opportunity cannot be created because this Account already has an existing ICP Opportunity.",
	WORKERS_COMP_INTEREST_REQUIRED: "Please select a value in Workers Comp Interest before saving.",
	CONTACT_EMAIL_REQUIRED_FOR_NEXT: "The selected Contact is missing an email address. Please ensure an email is added to proceed.",
	UPSELL_OPPORTUNITY_FOR_EMPLOYER_ALREADY_EXISTS: "UpSell Opportunity for Employer of record Already exists in Open / Closed Won Status."
};

const SUCCESS_MSGS = {
	RECORDS_UPDATED: "Records updated",
	TASK_CREATED: "Task was created successfully.",
	LEAD_PASS_SUCCESS: "Lead Pass successfully created."
};

const DISPOSITION_HELP_TEXT = "When 'No Call' is chosen, no Activity is created. Log Zoom or other calls as 'Connect'.";

const FOLLOWUPDATE_HELP_TEXT = "Creates a task on your calendar for the date specified.";

const FOLLOWUPSUBJECT_HELP_TEXT = "Sets the subject line for the new task.";

const DONOTCALL_HELP_TEXT = "On Leads, this sets the lead status to unqualified. Otherwise, this marks the Contact record for the chosen Contact as Do Not Call.";

const HINOTES_HELP_TEXT = "Notes to pass internally to Gusto's Benefits Sales team";

const RELATEDTO_HELP_TEXT = "Choose the object for which this call will be recorded (in the object's Activity feed).";

const SECONDARYPOC_HELP_TEXT = "Share an additional Contact Name with NEXT Insurance for the submitted lead pass.";

const COMPONENT_NAME = "logSmartCallingLwcCmp";

const TASK_RT_NAME = { CALL: "Call" };

const list_DispositionOptions = [
	PicklistOption.setLabelAndValue(""),
	PicklistOption.setLabelAndValue(TASK_CALL_DISPOSITION.ATTEMPT),
	PicklistOption.setLabelAndValue(TASK_CALL_DISPOSITION.VOICEMAIL),
	PicklistOption.setLabelAndValue(TASK_CALL_DISPOSITION.CONNECT),
	PicklistOption.setLabelAndValue(TASK_CALL_DISPOSITION.NO_CALL)
];

const list_FeatureRequestTypeOptions = [
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.PTO),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.PAYROLL_EXP_REIMB),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.REPORTING),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.COMMS),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.PPREMISSIONS_ORGCHART_DEPT),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.PREFORMANCE_TOOLS),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.HIRING_DISMISSING_TOOLS),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.GUSTO_MANAGED_BENEFITS),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.BYB),
	PicklistOption.setLabelAndValue(FEATURE_REQUEST_TYPE.OTHER)
];

const list_TaskTypeOptions = [PicklistOption.setLabelAndValue(TASK_TYPE.CALL), PicklistOption.setLabelAndValue(TASK_TYPE.EMAIL)];

function populateTaskType(strUserProfileName, strCurrentUserRole) {
	let list_TaskTypeOptionsByProfile = [];

	list_TaskTypeOptionsByProfile = [
		PicklistOption.setLabelAndValue(TASK_TYPE.INBOUND_CALL),
		PicklistOption.setLabelAndValue(TASK_TYPE.OUTBOUND_CALL),
		PicklistOption.setLabelAndValue(TASK_TYPE.NEW_COLD_CALL),
		PicklistOption.setLabelAndValue(TASK_TYPE.SCHEDULED_CALL),
		new PicklistOption(TASK_TYPE.PITCH_ONLY, TASK_TYPE.PITCH_W_O_DEMO),
		new PicklistOption(TASK_TYPE.DEMO_ONLY, TASK_TYPE.DEMO),
		new PicklistOption(TASK_TYPE.PITCH_AND_DEMO, TASK_TYPE.PITCH_DEMO),
		PicklistOption.setLabelAndValue(TASK_TYPE.REGURAL_CALL)
	];

	return list_TaskTypeOptionsByProfile;
}

const list_PriorityOptions = [PicklistOption.setLabelAndValue(TASK_PRIORITY.NORMAL), PicklistOption.setLabelAndValue(TASK_PRIORITY.LOW), PicklistOption.setLabelAndValue(TASK_PRIORITY.HIGH)];

const list_HIOptyTypeOptions = [
	PicklistOption.setLabelAndValue(HI_OPPORTUNITY_TYPE.HI_BENEFITS_NEW_PLAN),
	PicklistOption.setLabelAndValue(HI_OPPORTUNITY_TYPE.HI_BENEFITS_BOR),
	PicklistOption.setLabelAndValue(HI_OPPORTUNITY_TYPE.BENEFITS_BYOB)
];

const labels = {
	TASK_CALL_PICKLIST: TASK_CALL_PICKLIST,
	TAX_YEAR_LABEL: TAX_YEAR_LABEL
};

const REC_TYPE_NAMES = {
	Account: {
		COMPANY: "Company",
		RESELLER: "Reseller"
	}
};

const categoryOptions = [
	{
		value: "Account",
		url: `${window.location.origin}/img/icon/t4v35/standard/account_120.png`,
		label: "Account",
		fieldApiName: "Name",
		color: "7F8DE1",
		bgColor: "background-color : #7F8DE1!important"
	},
	{
		value: "Opportunity",
		url: `${window.location.origin}/img/icon/t4v35/standard/opportunity_120.png`,
		label: "Opportunity",
		fieldApiName: "Name",
		color: "FCB95B",
		bgColor: "background-color : #FCB95B!important"
	}
];

export {
	PicklistOption,
	displayToast,
	TOAST_PARAMS,
	FIELD_TYPE,
	checkInputValidity,
	checkInputFieldValidity,
	USER_PROFILE,
	USER_ROLE,
	TASK_SUBJECT,
	TASK_PRIORITY,
	OPP_STAGE,
	ARDIUS_OPP_STAGE,
	TASK_TYPE,
	PRODUCT_UPSELL_RT_NAME,
	SOBJECT_NAME,
	DETAIL,
	ADDITIONAL_INFO,
	NOTES,
	ACTION_ITEMS,
	LEAD_STATUS,
	LEAD_STATUS_DETAIL,
	ERROR_MSGS,
	SUCCESS_MSGS,
	COMPONENT_NAME,
	TASK_RT_NAME,
	TASK_CALL_DISPOSITION,
	list_DispositionOptions,
	list_FeatureRequestTypeOptions,
	list_TaskTypeOptions,
	populateTaskType,
	list_PriorityOptions,
	list_HIOptyTypeOptions,
	labels,
	DISPOSITION_HELP_TEXT,
	REC_TYPE_NAMES,
	categoryOptions,
	TAX_CREDIT_TYPE,
	FOLLOWUPDATE_HELP_TEXT,
	FOLLOWUPSUBJECT_HELP_TEXT,
	DONOTCALL_HELP_TEXT,
	HINOTES_HELP_TEXT,
	RELATEDTO_HELP_TEXT,
	SECONDARYPOC_HELP_TEXT
};