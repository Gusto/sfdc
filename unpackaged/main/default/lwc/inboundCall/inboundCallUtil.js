const OPEN_PANDA = "Open Panda";

const opportunityColumns = [
	{
		label: "Link To Task",
		type: "button-icon",
		initialWidth: 100,
		typeAttributes: {
			iconName: "utility:forward_up",
			title: "Link To Task",
			variant: "brand",
			alternativeText: "View",
			size: "xx-small"
		}
	},
	{
		label: "Name",
		fieldName: "Name",
		type: "openSubTab",
		typeAttributes: {
			objRecordName: { fieldName: "Name" },
			objRecordId: { fieldName: "Id" }
		}
	},
	{
		label: "Stage Name",
		fieldName: "StageName",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Owner Name",
		fieldName: "OwnerName",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Overall Status",
		fieldName: "AccountZP_Company_Overall_Status__c",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Filing State",
		fieldName: "AccountBillingState",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Anchor Pay Date",
		fieldName: "AccountAnchor_Pay_Date__c",
		sortable: false,
		type: "date",
		typeAttributes: {
			day: "numeric",
			month: "numeric",
			year: "numeric"
		},
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Joined Date",
		fieldName: "AccountJoined_Date_Panda__c",
		type: "date",
		typeAttributes: {
			day: "numeric",
			month: "numeric",
			year: "numeric"
		},
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: OPEN_PANDA,
		sortable: false,
		type: "button-icon",
		initialWidth: 100,
		typeAttributes: {
			iconName: "utility:animal_and_nature",
			title: OPEN_PANDA,
			variant: "brand",
			alternativeText: OPEN_PANDA,
			size: "xx-small"
		}
	},
	{
		label: " RFI Page",
		fieldName: "AccountRFI_Page__c",
		type: "url",
		typeAttributes: {
			label: "RFI Page",
			target: "_blank"
		},
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Sold By",
		fieldName: "Sold_By__c",
		sortable: false,
		cellAttributes: { alignment: "left" },
		type: "url",
		typeAttributes: {
			label: {
				fieldName: "SoldByName"
			},
			target: "_blank"
		}
	},
	{
		label: "Referred By",
		fieldName: "Referred_By__c",
		sortable: false,
		cellAttributes: { alignment: "left" },
		type: "url",
		typeAttributes: {
			label: {
				fieldName: "ReferredByName"
			},
			target: "_blank"
		}
	}
];

const contactColumns = [
	{
		label: "Link To Task",
		type: "button-icon",
		initialWidth: 100,
		typeAttributes: {
			iconName: "utility:forward_up",
			title: "Link To Task",
			variant: "brand",
			alternativeText: "View",
			size: "xx-small"
		}
	},
	{
		label: "Name",
		fieldName: "Name",
		type: "openSubTab",
		typeAttributes: {
			objRecordName: { fieldName: "Name" },
			objRecordId: { fieldName: "Id" }
		}
	},

	{ label: "Email", fieldName: "Email", type: "email" },

	{
		label: "Account",
		fieldName: "deactivateStatus",
		type: "clickButton",
		typeAttributes: {
			objRecordName: { fieldName: "Company" },
			objRecordId: { fieldName: "AccountId" },
			rowRecordId: { fieldName: "Id" }
		}
	},
	{
		label: OPEN_PANDA,
		sortable: false,
		type: "button-icon",
		initialWidth: 100,
		typeAttributes: {
			iconName: "utility:animal_and_nature",
			title: OPEN_PANDA,
			variant: "brand",
			alternativeText: OPEN_PANDA,
			size: "xx-small"
		}
	},
	{
		label: "Phone",
		fieldName: "Phone",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Mobile Phone",
		fieldName: "MobilePhone",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Other Phone",
		fieldName: "Normalized_Mobile_Phone__c",
		sortable: false,
		cellAttributes: { alignment: "left" }
	}
];

const leadColumns = [
	{
		label: "Link To Task",
		type: "button-icon",
		initialWidth: 100,
		typeAttributes: {
			iconName: "utility:forward_up",
			title: "Link To Task",
			variant: "brand",
			alternativeText: "View",
			size: "xx-small"
		}
	},
	{
		label: "Name",
		fieldName: "Name",
		type: "openSubTab",
		typeAttributes: {
			objRecordName: { fieldName: "Name" },
			objRecordId: { fieldName: "Id" }
		}
	},
	{
		label: "Email",
		fieldName: "Email",
		sortable: false,
		type: "email",
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Company",
		fieldName: "Company",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: OPEN_PANDA,
		sortable: false,
		type: "button-icon",
		initialWidth: 100,
		typeAttributes: {
			iconName: "utility:animal_and_nature",
			title: OPEN_PANDA,
			variant: "brand",
			alternativeText: OPEN_PANDA,
			size: "xx-small"
		}
	},
	{
		label: "Phone",
		fieldName: "Phone",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Mobile Phone",
		fieldName: "Normalized_Mobile_Phone__c",
		sortable: false,
		cellAttributes: { alignment: "left" }
	},
	{
		label: "Other Phone",
		fieldName: "Normalized_Alternate_Phone__c",
		sortable: false,
		cellAttributes: { alignment: "left" }
	}
];

const caseColumns = [
	{
		label: "Link To Task",
		type: "button-icon",
		initialWidth: 100,
		typeAttributes: {
			iconName: "utility:forward_up",
			title: "Link To Task",
			variant: "brand",
			alternativeText: "View",
			size: "xx-small"
		}
	},
	{
		label: "Case Number",
		fieldName: "CaseNumber",
		type: "openSubTab",
		typeAttributes: {
			objRecordName: { fieldName: "CaseNumber" },
			objRecordId: { fieldName: "Id" }
		}
	},
	{ label: "Status", fieldName: "Status", sortable: false, cellAttributes: { alignment: "left" } },
	{ label: "RecordType Name", fieldName: "recordtypeName", sortable: false, cellAttributes: { alignment: "left" } },

	{ label: "Email", fieldName: "ContactEmail", type: "email" },

	{
		label: "Contact",
		fieldName: "deactivateStatus",
		type: "clickButton",
		typeAttributes: {
			objRecordName: { fieldName: "Contact" },
			objRecordId: { fieldName: "ContactId" }
		}
	},

	{
		label: "Account",
		fieldName: "deactivateStatus",
		type: "clickButton",
		typeAttributes: {
			objRecordName: { fieldName: "Company" },
			objRecordId: { fieldName: "AccountId" }
		}
	},
	{
		label: "Phone",
		fieldName: "ContactPhone",
		sortable: false,
		cellAttributes: { alignment: "left" }
	}
];

const CONTACT_REASON_TRANSFER = "Transfer";
const CONTACT_REASON_SALES = "Sales";
const SUB_CONTACT_REASON_BAD_TRANSFER = "Bad Transfer from Care (not an FEIN change)";
const SUB_CONTACT_REASON_TRANSFER_TO_CARE = "Transfer to Care";

const REC_TYPE_NAME_COMPANY = "Company";
const REC_TYPE_NAME_RESELLER = "Reseller";

const PANDA_URL_PREFIX_COMPANY = "/panda/companies/";
const PANDA_URL_PREFIX_RESELLER = "/panda/accounting_firms/";

const ERROR_MSG_SAVE_TASK_PRIOR_TO_TRANSFER = "Task needs to be saved prior to transfer.";
const ERROR_MSG_URL_NOT_CONFIGURED = "URL has not yet been configured for the environment. Please contact your Salesforce admin!";
const ERROR_MSG_SOMETHING_WENT_WRONG = "Something went wrong. Please contact your Salesforce admin!";
const ERROR_MSG_COMPANY_ID_MISSING = "Company Id is missing!";
const ERROR_MSG_FIRM_ID_MISSING = "Firm Id is missing!";

export {
	OPEN_PANDA,
	opportunityColumns,
	contactColumns,
	leadColumns,
	caseColumns,
	CONTACT_REASON_TRANSFER,
	CONTACT_REASON_SALES,
	SUB_CONTACT_REASON_BAD_TRANSFER,
	SUB_CONTACT_REASON_TRANSFER_TO_CARE,
	REC_TYPE_NAME_COMPANY,
	REC_TYPE_NAME_RESELLER,
	PANDA_URL_PREFIX_COMPANY,
	PANDA_URL_PREFIX_RESELLER,
	ERROR_MSG_SAVE_TASK_PRIOR_TO_TRANSFER,
	ERROR_MSG_URL_NOT_CONFIGURED,
	ERROR_MSG_SOMETHING_WENT_WRONG,
	ERROR_MSG_COMPANY_ID_MISSING,
	ERROR_MSG_FIRM_ID_MISSING
};