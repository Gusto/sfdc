import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createErrorLog from "@salesforce/apex/ComBaseController.createErrorLog";
import getSObjectName from "@salesforce/apex/ComBaseController.getSObjectName";

const apexCaller = function (methodName, params, thisArg, resCb, errCb, isElegantError) {
	methodName(params)
		.then((response) => {
			try {
				resCb && resCb.call(thisArg, response);
			} catch (err) {
				javaScriptError(err, thisArg);
			}
		})
		.catch((error) => {
			apexError(error, thisArg, null, null, isElegantError);
			thisArg.isShowSpinner = false;
			errCb && errCb.call(thisArg, error);
		});
};

const apexError = function (error, thisArg, mode, duration, isElegantError) {
	let message;
	if (error && error.statusText && error.body && error.body.message) {
		if (isElegantError) {
			message = `${error.body.message}`;
		} else {
			message = `${error.statusText}: ${error.body.message}`;
		}
	} else {
		message = "Unknown error";
	}

	showToast("Error!", "error", message, mode, duration, thisArg);
};

const showErrorToast = (errorList, thisArg) => {
	errorList.forEach((cur) => {
		showToast("Error!", "error", cur.message, null, null, thisArg);
	});
};

const showToast = function (title, variant, message, mode, duration, thisArg, messageData) {
	const event = new ShowToastEvent({
		title: title,
		variant: variant,
		message: message,
		mode: mode || "dismissible",
		duration: duration || "4000ms",
		messageData: messageData || []
	});
	thisArg.dispatchEvent(event);
};

const javaScriptError = function (error, thisArg, mode, duration, componentName, methodName) {
	let message = error.name + ": " + error.message;
	const params = { message: JSON.stringify(error.stack), componentName, methodName };
	apexCaller(createErrorLog, params, thisArg, () => {});
	showToast("Error!", "error", message, mode, duration, thisArg);
};

const setObjectRecord = (objRecord, thisArg) => {
	try {
		if (thisArg.fieldReference.trim()) {
			let fieldReference = thisArg.fieldReference.split(".");
			fieldReference.forEach((curRef) => {
				if (curRef) {
					objRecord = objRecord[curRef];
				}
			});
		}
		return objRecord;
	} catch (error) {
		javaScriptError(error, thisArg);
	}
};

const keyMaker = (length) => {
	var result = "";
	var characters = "!@#$%^&*()ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()";
	var charactersLength = characters.length;
	for (var i = 0; i < length; i++) {
		result += characters.charAt(Math.floor(Math.random() * charactersLength));
	}
	return result + Number(new Date().getTime()).toString(16);
};
const prefixUrl = "/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&versionId=";

const sortList = (response, keys, isDecimal) => {
	const propertyValue = (property, keys) => {
		keys.forEach((curKey) => {
			property = property[curKey];
		});
		return property;
	};

	let sortList = response;
	sortList.sort(function (a, b) {
		let x = propertyValue(a, keys);
		let y = propertyValue(b, keys);
		if (isDecimal) {
			x = parseInt(x);
			y = parseInt(y);
		} else {
			if (x) {
				x = x + "";
				x = x.toLowerCase();
			}
			if (y) {
				y = y + "";
				y = y.toLowerCase();
			}
		}

		if (x < y) {
			return -1;
		}
		if (x > y) {
			return 1;
		}
	});
	return sortList;
};
const performSortingOnPicklistOptions = (response) => {
	response = sortList(response, ["label"]);
	return response;
};

const filterFieldOptionsBasedOnFieldType = (fieldOptions, unfilter) => {
	fieldOptions = fieldOptions.filter((cur) => (cur["type"].toLowerCase() == "textarea" && cur["length"] <= 255) || !unfilter.includes(cur["type"].toLowerCase()));
	return fieldOptions;
};

const setDateTimeHelp = () => {
	let options = { dateStyle: "short", timeStyle: "short" };
	return `Either choose Date Literals or enter date(format should be ${new Date().toLocaleDateString()} or ${new Date().toLocaleString("en-US", options)})`;
};
const setDateHelp = () => {
	let options = { dateStyle: "short" };
	return `Date format should be (${new Date().toLocaleDateString()})`;
};

const setTimeHelp = () => {
	let today = new Date();
	let time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds() + "." + today.getMilliseconds();
	return `Time format should be ${time})`;
};
const setEmailHelp = () => {
	return `Please enter a valid email address.`;
};
const setUrlHelp = () => {
	return `Please enter a valid url.`;
};
const setIdHelp = () => {
	return `Id should be either 15 or 18 char.`;
};

const helpText = {
	dateTimeHelp: setDateTimeHelp(),
	dateHelp: setDateHelp(),
	timeHelp: setTimeHelp(),
	emailHelp: setEmailHelp(),
	urlHelp: setUrlHelp(),
	idHelp: setIdHelp()
};

const createObjectRecord = function (apiName, fields, thisArg, callback) {
	const recordInput = { apiName: apiName, fields };
	createRecord(recordInput)
		.then((response) => {
			callback.call(thisArg, response);
		})
		.catch((error) => {
			apexError(error, thisArg);
		});
};

const apexMethods = {
	getSObjectName
};

// text - pass text that system will be compile and replace fieldApiName to fieldValue
// evaluate conditions
// record - in which pass single objectRecord
// System will be compile these parameters . For eg:
const compileText = (text, record) => {
	if (!text) return;
	let fieldToValueMap = new Map();
	let fieldApiNames = text.match(/{(.*?)}/g);
	fieldApiNames &&
		fieldApiNames.forEach((curField) => {
			let fieldPath = curField.replace("}", "").replace("{", "").split(".");
			let value = JSON.parse(JSON.stringify(record));
			for (let i = 0; i < fieldPath.length; i++) {
				if (value[fieldPath[i]] || typeof value[fieldPath[i]] === "boolean") {
					value = value[fieldPath[i]];
				} else {
					value = null;
					break;
				}
			}
			fieldToValueMap.set(curField, value);
		});

	[...fieldToValueMap.keys()].forEach((curKey) => {
		text = text.replaceAll(curKey, fieldToValueMap.get(curKey));
	});
	let parametersToValueMap = new Map();
	let parameters = text.match(/eval\((.*?)\)|cond\((.*?)\)/g);
	parameters &&
		parameters.forEach((curParameter) => {
			let value;
			if (curParameter.startsWith("eval(")) {
				value = curParameter.replace("eval(", "").replace(")", "");
			} else if (curParameter.startsWith("cond(")) {
				let expr = curParameter.replace("cond(", "").replace(")", "");
				expr = expr.split(",");
				if (expr.length >= 2) {
					let cond = expr[0];
					value = eval(cond) ? expr[1] : expr[2];
				}
			}

			parametersToValueMap.set(curParameter, value);
		});

	[...parametersToValueMap.keys()].forEach((curKey) => {
		text = text.replaceAll(curKey, parametersToValueMap.get(curKey));
	});

	return text;
};

const handleValidationAction = (thisArg, callback) => {
	let allValid = true;

	allValid = fieldValidationChecker("lightning-input", thisArg);
	allValid = fieldValidationChecker("lightning-combobox", thisArg) && allValid ? true : false;
	allValid = fieldValidationChecker("lightning-input-location", thisArg) && allValid ? true : false;

	allValid = fieldValidationChecker("lightning-textarea", thisArg) && allValid ? true : false;

	const isMultipicklistValid = validationOnMultipicklist(thisArg);

	allValid = isMultipicklistValid && allValid ? true : false;

	thisArg.template.querySelectorAll("c-data-table-look-up").forEach((cur) => {
		cur.handleValidationAction((isValid) => {
			if (allValid) {
				allValid = isValid;
			}
		});
	});

	thisArg.template.querySelectorAll("c-com-search-picklist").forEach((cur) => {
		cur.handleValidation((isValid) => {
			if (allValid) {
				allValid = isValid;
			}
		});
	});
	if (callback) {
		callback.call(thisArg, allValid);
	} else {
		return allValid;
	}
};

const validationOnMultipicklist = (thisArg) => {
	let checkboxFauxes = thisArg.template.querySelectorAll(".slds-checkbox_faux");
	if (thisArg.required && checkboxFauxes && checkboxFauxes.length) {
		if (!thisArg.value) {
			checkboxFauxes.forEach((cur) => {
				cur.style.borderColor = "red";
			});
			return false;
		} else {
			checkboxFauxes.forEach((cur) => {
				cur.style.borderColor = "rgb(201 199 197)";
			});
			return true;
		}
	}
	return true;
};

const fieldValidationChecker = (lightning_type, thisArg) => {
	return [...thisArg.template.querySelectorAll(lightning_type)].reduce((validSoFar, inputCmp) => {
		inputCmp.reportValidity();
		const isValid = validSoFar && inputCmp.checkValidity();
		if (!isValid) {
			inputCmp.scrollIntoView();
		}
		return isValid;
	}, true);
};

const whatIdList = [
	{
		value: "Account",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/account_120.png",
		label: "Account",
		fieldApiName: "Name",
		color: "7F8DE1",
		bgColor: "background-color : #7F8DE1!important"
	},
	{
		value: "agentsync__Agent_ID__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom15_120.png",
		label: "Agent ID",
		fieldApiName: "Name",
		color: "f77e75",
		bgColor: "background-color : #f77e75!important"
	},
	{
		value: "Asset",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/asset_object_120.png",
		label: "Asset",
		fieldApiName: "Name",
		color: "317992",
		bgColor: "background-color : #317992!important"
	},
	{
		value: "AssetRelationship",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/asset_relationship_120.png",
		label: "Asset Relationship",
		fieldApiName: "AssetRelationshipNumber ",
		color: "FA975C",
		bgColor: "background-color : #FA975C!important"
	},
	{
		value: "Benefit_Order__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Benefit Order",
		fieldApiName: "Name",
		color: "931638",
		bgColor: "background-color : #931638!important"
	},
	{
		value: "BRNSHRK__BrainsharkPresentation__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Brainshark Presentation",
		fieldApiName: "Name",
		color: "00B2AA",
		bgColor: "background-color : #00B2AA!important"
	},
	{
		value: "Bulk_Migration_Request__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom64_120.png",
		label: "Bulk Migration Request",
		fieldApiName: "Name",
		color: "618fd8",
		bgColor: "background-color : #618fd8!important"
	},
	{
		value: "Campaign",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/campaign_120.png",
		label: "Campaign",
		fieldApiName: "Name",
		color: "F49756",
		bgColor: "background-color : #F49756!important"
	},
	{
		value: "Carrier__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Carrier",
		fieldApiName: "Name",
		color: "931638",
		bgColor: "background-color : #931638!important"
	},
	{
		value: "Carrier_Order__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Carrier Order",
		fieldApiName: "Name",
		color: "B58C0A",
		bgColor: "background-color : #B58C0A!important"
	},
	{
		value: "Carrier_Order_Line_Item__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom19_120.png",
		label: "Carrier Order Line Item",
		fieldApiName: "Name",
		color: "3abeb1",
		bgColor: "background-color : #3abeb1!important"
	},
	{
		value: "Case",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/case_120.png",
		label: "Case",
		fieldApiName: "CaseNumber",
		color: "F2CF5B",
		bgColor: "background-color : #F2CF5B!important"
	},
	{
		value: "Case_Action_Fields__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom67_120.png",
		label: "Case Action Fields",
		fieldApiName: "Name",
		color: "f87d76",
		bgColor: "background-color : #f87d76!important"
	},
	{
		value: "Case_Quality_Assurance__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom18_120.png",
		label: "Case Quality Assurance",
		fieldApiName: "Name",
		color: "4dca76",
		bgColor: "background-color : #4dca76!important"
	},
	{
		value: "LiveAgentSession",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/agent_session_120.png",
		label: "Chat Session",
		fieldApiName: "Name",
		color: "F88960",
		bgColor: "background-color : #F88960!important"
	},
	{
		value: "LiveChatTranscript",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/live_chat_120.png",
		label: "Chat Transcript",
		fieldApiName: "Name",
		color: "F88962",
		bgColor: "background-color : #F88962!important"
	},
	{
		value: "CommSubscriptionConsent",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom15_120.png",
		label: "Communication Subscription Consent",
		fieldApiName: "Name",
		color: "f77e75",
		bgColor: "background-color : #f77e75!important"
	},
	{
		value: "Company_Level_Documents__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Company Level Documents",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Company_Migration__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Company Migration",
		fieldApiName: "Name",
		color: "F28411",
		bgColor: "background-color : #F28411!important"
	},
	{
		value: "APXT_BPM__Conductor__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Conga Conductor",
		fieldApiName: "Name",
		color: "56AA1C",
		bgColor: "background-color : #56AA1C!important"
	},
	{
		value: "APXTConga4__Conga_Email_Staging__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Conga Email Staging",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "APXTConga4__Conga_Email_Template__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Conga Email Template",
		fieldApiName: "Name",
		color: "003049",
		bgColor: "background-color : #003049!important"
	},
	{
		value: "APXTConga4__Composer_QuickMerge__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Conga Global Merge",
		fieldApiName: "Name",
		color: "003049",
		bgColor: "background-color : #003049!important"
	},
	{
		value: "ContactRequest",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/contact_request_120.png",
		label: "Contact Request",
		fieldApiName: "Name",
		color: "4dca76",
		bgColor: "background-color : #4dca76!important"
	},
	{
		value: "agentsync__Continuing_Education_Assignment__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom45_120.png",
		label: "Continuing Education Assignment",
		fieldApiName: "Name",
		color: "d95879",
		bgColor: "background-color : #d95879!important"
	},
	{
		value: "agentsync__Continuing_Education_Course__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom33_120.png",
		label: "Continuing Education Course",
		fieldApiName: "Name",
		color: "97cf5d",
		bgColor: "background-color : #97cf5d!important"
	},
	{
		value: "Contract",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/contract_120.png",
		label: "Contract",
		fieldApiName: "Name",
		color: "6EC06E",
		bgColor: "background-color : #6EC06E!important"
	},
	{
		value: "ContractLineItem",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/contract_line_item_120.png",
		label: "Contract Line Item",
		fieldApiName: "Name",
		color: "6EC06E",
		bgColor: "background-color : #6EC06E!important"
	},
	{
		value: "Gong__Gong_Call__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Conversation",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "dsfs__CustomParameterMap__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Custom Parameter Map",
		fieldApiName: "Name",
		color: "5B77CC",
		bgColor: "background-color : #5B77CC!important"
	},
	{
		value: "Customer_Health__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom8_120.png",
		label: "Customer Health",
		fieldApiName: "Name",
		color: "50ceb9",
		bgColor: "background-color : #50ceb9!important"
	},
	{
		value: "dsfs__EnvelopeConfiguration__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "DocuSign Envelope Configuration",
		fieldApiName: "Name",
		color: "5B77CC",
		bgColor: "background-color : #5B77CC!important"
	},
	{
		value: "dsfs__DocuSign_Recipient_Status__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "DocuSign Recipient Status",
		fieldApiName: "Name",
		color: "5B77CC",
		bgColor: "background-color : #5B77CC!important"
	},
	{
		value: "dsfs__DocuSign_Status__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "DocuSign Status",
		fieldApiName: "Name",
		color: "5B77CC",
		bgColor: "background-color : #5B77CC!important"
	},
	{
		value: "Entitlement",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/entitlement_120.png",
		label: "Entitlement",
		fieldApiName: "Name",
		color: "7E8BE4",
		bgColor: "background-color : #7E8BE4!important"
	},
	{
		value: "DelegatedAccount",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/delegated_account_120.png",
		label: "External Managed Account",
		fieldApiName: "Name",
		color: "04844b",
		bgColor: "background-color : #04844b!important"
	},
	{
		value: "Mogli_SMS__GatewayToUserJunc__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom15_120.png",
		label: "Gateway User",
		fieldApiName: "Name",
		color: "f77e75",
		bgColor: "background-color : #f77e75!important"
	},
	{
		value: "Gong__Related_Account__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Gong Related Accounts",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "Gong__Related_Contact__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Gong Related Contacts",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "Gong__Related_Lead__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Gong Related Leads",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "Gong__Related_Opportunity__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Gong Related Opportunities",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "Gong__Gong_Scorecard__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Gong Scorecard",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "Guided_Case_Flow__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/case_120.png",
		label: "Guided Case Flow",
		fieldApiName: "Name",
		color: "F2CF5B",
		bgColor: "background-color : #F2CF5B!important"
	},
	{
		value: "HIGroupEvent__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom16_120.png",
		label: "HIGroupEvent",
		fieldApiName: "Name",
		color: "e9af67",
		bgColor: "background-color : #e9af67!important"
	},
	{
		value: "Image",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/maintenance_plan_120.png",
		label: "Image",
		fieldApiName: "Name",
		color: "2A739E",
		bgColor: "background-color : #2A739E!important"
	},
	{
		value: "Insurance_Quote__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom6_120.png",
		label: "Insurance Quote",
		fieldApiName: "Name",
		color: "bf5a88",
		bgColor: "background-color : #bf5a88!important"
	},
	{
		value: "Gong__Call_Stat__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Interaction Stats",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Gong__Call_Invitee__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Invitee",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "INVOCA_FOR_SF__Invoca_Call_Log__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom22_120.png",
		label: "Invoca Call Log",
		fieldApiName: "Name",
		color: "8b85f9",
		bgColor: "background-color : #8b85f9!important"
	},
	{
		value: "IVR_Intent_Grouping__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom17_120.png",
		label: "IVR Intent Grouping",
		fieldApiName: "Name",
		color: "4dca76",
		bgColor: "background-color : #4dca76!important"
	},
	{
		value: "IVR_Routing_Log__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom22_120.png",
		label: "IVR Routing Log",
		fieldApiName: "Name",
		color: "8b85f9",
		bgColor: "background-color : #8b85f9!important"
	},
	{
		value: "Kaiser_Groups_Info__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Kaiser Groups Info",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Kaiser_Member_Info__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Kaiser Member Info",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "agentsync__Learn_Bundle__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Learn Bundle",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "agentsync__Learn_Bundled_Course__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Learn Bundled Course",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "agentsync__Learn_Course__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom55_120.png",
		label: "Learn Course",
		fieldApiName: "Name",
		color: "F2CF5B",
		bgColor: "background-color : #F2CF5B!important"
	},
	{
		value: "agentsync__Learn_Report_Card__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom53_120.png",
		label: "Learn Report Card",
		fieldApiName: "Name",
		color: "f36e83",
		bgColor: "background-color : #f36e83!important"
	},
	{
		value: "agentsync__Learn_Report_Card_Bundle__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Learn Report Card Bundle",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "agentsync__Learn_Report_Card_Bundled_Course__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom13_120.png",
		label: "Learn Report Card Bundled Course",
		fieldApiName: "Name",
		color: "df6184",
		bgColor: "background-color : #df6184!important"
	},
	{
		value: "agentsync__License__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom91_120.png",
		label: "License",
		fieldApiName: "Name",
		color: "bf7b66",
		bgColor: "background-color : #bf7b66!important"
	},
	{
		value: "ListEmail",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/list_email_120.png",
		label: "List Email",
		fieldApiName: "Name",
		color: "8BAEB5",
		bgColor: "background-color : #8BAEB5!important"
	},
	{
		value: "Location",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/location_120.png",
		label: "Location",
		fieldApiName: "Name",
		color: "4BC076",
		bgColor: "background-color : #4BC076!important"
	},
	{
		value: "Master_Company_Level_Documents__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom42_120.png",
		label: "Master Company Level Documents",
		fieldApiName: "Name",
		color: "cfd05b",
		bgColor: "background-color : #cfd05b!important"
	},
	{
		value: "Nacha_Entry_Return__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Nacha Entry Return",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "NICE_Interaction__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom22_120.png",
		label: "NICE Interaction",
		fieldApiName: "Name",
		color: "8b85f9",
		bgColor: "background-color : #8b85f9!important"
	},
	{
		value: "Gong__Note__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Note",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Opportunity",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/opportunity_120.png",
		label: "Opportunity",
		fieldApiName: "Name",
		color: "FCB95B",
		bgColor: "background-color : #FCB95B!important"
	},
	{
		value: "Order",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/orders_120.png",
		label: "Order",
		fieldApiName: "Name",
		color: "769ED9",
		bgColor: "background-color : #769ED9!important"
	},
	{
		value: "Gong__Call_Participant__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Participant",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "PartyConsent",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/individual_120.png",
		label: "Party Consent",
		fieldApiName: "Name",
		color: "3C97DD",
		bgColor: "background-color : #3C97DD!important"
	},
	{
		value: "Payroll_Audit__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom27_120.png",
		label: "Payroll Audit",
		fieldApiName: "Name",
		color: "5ab0d2",
		bgColor: "background-color : #5ab0d2!important"
	},
	{
		value: "ProcessException",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/process_exception_120.png",
		label: "Process Exception",
		fieldApiName: "Name",
		color: "2A739E",
		bgColor: "background-color : #2A739E!important"
	},
	{
		value: "agentsync__Producer_Assignment__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom64_120.png",
		label: "Producer Assignment",
		fieldApiName: "Name",
		color: "618fd8",
		bgColor: "background-color : #618fd8!important"
	},
	{
		value: "agentsync__Producer_Compliance_Scorecard__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom62_120.png",
		label: "Producer Compliance Scorecard",
		fieldApiName: "Name",
		color: "6b92dc",
		bgColor: "background-color : #6b92dc!important"
	},
	{
		value: "agentsync__Producer_Detail__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom15_120.png",
		label: "Producer Detail",
		fieldApiName: "Name",
		color: "f77e75",
		bgColor: "background-color : #f77e75!important"
	},
	{
		value: "agentsync__Producer_Licensing__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom64_120.png",
		label: "Producer Licensing",
		fieldApiName: "Name",
		color: "618fd8",
		bgColor: "background-color : #618fd8!important"
	},
	{
		value: "Product2",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/product_120.png",
		label: "Product",
		fieldApiName: "Name",
		color: "B781D3",
		bgColor: "background-color : #B781D3!important"
	},
	{
		value: "Promoter_IO_Result__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Promoter IO Result",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "purecloud__PureCloud_Contact_List_Request__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "PureCloud Contact List Request",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "purecloud__PureCloud_Routing_Request__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "PureCloud Routing Request",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "QA_Lines_Of_Coverage__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "QA Lines Of Coverage",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "QA_Sheet__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "QA Sheet",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "QA_Errors__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "QC Error",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Referral__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Referral",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Region_POD__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom40_120.png",
		label: "Region POD",
		fieldApiName: "Name",
		color: "83c75e",
		bgColor: "background-color : #83c75e!important"
	},
	{
		value: "Region_POD_mapping__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom40_120.png",
		label: "Region POD mapping",
		fieldApiName: "Name",
		color: "83c75e",
		bgColor: "background-color : #83c75e!important"
	},
	{
		value: "agentsync__Regulatory_Action__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom26_120.png",
		label: "Regulatory Action",
		fieldApiName: "Name",
		color: "7698f0",
		bgColor: "background-color : #7698f0!important"
	},
	{
		value: "Research_Configuration__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom50_120.png",
		label: "Research Configuration",
		fieldApiName: "Name",
		color: "49bcd3",
		bgColor: "background-color : #49bcd3!important"
	},
	{
		value: "Research_Email_Template__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Research Email Template",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Research_Project_Detail__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom78_120.png",
		label: "Research Project Detail",
		fieldApiName: "Name",
		color: "5a95dd",
		bgColor: "background-color : #5a95dd!important"
	},
	{
		value: "Research_Project_Teams__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Research Project Teams",
		fieldApiName: "Name",
		color: "00A0C4",
		bgColor: "background-color : #00A0C4!important"
	},
	{
		value: "Research_Survey_Response__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Research Survey Response",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Sales_Call_Tracking__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Sales Call Tracking",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "ServiceContract",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/service_contract_120.png",
		label: "Service Contract",
		fieldApiName: "Name",
		color: "8A76F0",
		bgColor: "background-color : #8A76F0!important"
	},
	{
		value: "ServiceResource",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/service_resource_120.png",
		label: "Service Resource",
		fieldApiName: "Name",
		color: "7E8BE4",
		bgColor: "background-color : #7E8BE4!important"
	},
	{
		value: "metazoa3__snapshot_asset__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom19_120.png",
		label: "Snapshot Asset",
		fieldApiName: "Name",
		color: "3abeb1",
		bgColor: "background-color : #3abeb1!important"
	},
	{
		value: "metazoa3__snapshot_push__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom19_120.png",
		label: "Snapshot Deployment",
		fieldApiName: "Name",
		color: "3abeb1",
		bgColor: "background-color : #3abeb1!important"
	},
	{
		value: "metazoa3__snapshot_sprint__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom44_120.png",
		label: "Snapshot Sprint",
		fieldApiName: "Name",
		color: "c8ca58",
		bgColor: "background-color : #c8ca58!important"
	},
	{
		value: "metazoa3__snapshot_story__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom75_120.png",
		label: "Snapshot Story",
		fieldApiName: "Name",
		color: "cd9f65",
		bgColor: "background-color : #cd9f65!important"
	},
	{
		value: "Solution",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/solution_120.png",
		label: "Solution",
		fieldApiName: "Name",
		color: "8FC972",
		bgColor: "background-color : #8FC972!important"
	},
	{
		value: "Gong__Agenda__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Structure",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "Customer_Feedback__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Submitted Feedback",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "Tax_Ops_Failed_Filing__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom18_120.png",
		label: "Tax Ops Failed Filing",
		fieldApiName: "Name",
		color: "4dca76",
		bgColor: "background-color : #4dca76!important"
	},
	{
		value: "Tax_Ops_Failed_Record__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom51_120.png",
		label: "Tax Ops Failed Record",
		fieldApiName: "Name",
		color: "d8c760",
		bgColor: "background-color : #d8c760!important"
	},
	{
		value: "Tax_Ops_Task__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom29_120.png",
		label: "Tax Ops Task",
		fieldApiName: "Name",
		color: "bdd25f",
		bgColor: "background-color : #bdd25f!important"
	},
	{
		value: "Tax_POA_Form__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom39_120.png",
		label: "Tax POA Form",
		fieldApiName: "Name",
		color: "4fbe75",
		bgColor: "background-color : #4fbe75!important"
	},
	{
		value: "Gong__Topic__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Topic",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "Gong__Tracker__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Tracker",
		fieldApiName: "Name",
		color: "CE007C",
		bgColor: "background-color : #CE007C!important"
	},
	{
		value: "User_Time_Off__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "User Time Off",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "UXR_CSV_Staging__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "UXR CSV Staging",
		fieldApiName: "Name",
		color: "00A0C4",
		bgColor: "background-color : #00A0C4!important"
	},
	{
		value: "Research_Project_Master__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "UXR Scout",
		fieldApiName: "Name",
		color: "00A0C4",
		bgColor: "background-color : #00A0C4!important"
	},
	{
		value: "WFM_Request__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom16_120.png",
		label: "WFM Request",
		fieldApiName: "Name",
		color: "e9af67",
		bgColor: "background-color : #e9af67!important"
	},
	{
		value: "Zendesk__Zendesk_Bulk_Sync_Response__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Zendesk Bulk Sync Response",
		fieldApiName: "Name",
		color: "282821",
		bgColor: "background-color : #282821!important"
	},
	{
		value: "Zendesk__Zendesk_Ticket__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Zendesk Support Ticket",
		fieldApiName: "Name",
		color: "566B21",
		bgColor: "background-color : #566B21!important"
	},
	{
		value: "Zendesk__Zendesk_Sync_Job__c",
		url: "https://gusto.my.salesforce.com/img/icon/custom16.png",
		label: "Zendesk Sync Job",
		fieldApiName: "Name",
		color: "747E96",
		bgColor: "background-color : #747E96!important"
	},
	{
		value: "ZP_Nacha_Entry_Returns__c",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/custom/custom52_120.png",
		label: "ZP Nacha Entry Return",
		fieldApiName: "Name",
		color: "ee8e6f",
		bgColor: "background-color : #ee8e6f!important"
	}
];

const whoIdList = [
	{
		value: "Contact",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/contact_120.png",
		label: "Contact",
		fieldApiName: "Name",
		color: "A094ED",
		bgColor: "background-color : #A094ED!important"
	},
	{
		value: "Lead",
		url: "https://gusto.my.salesforce.com/img/icon/t4v35/standard/lead_120.png",
		label: "Lead",
		fieldApiName: "Name",
		color: "F88962",
		bgColor: "background-color : #F88962!important"
	}
];

export {
	showToast,
	javaScriptError,
	setObjectRecord,
	keyMaker,
	apexCaller,
	prefixUrl,
	showErrorToast,
	sortList,
	performSortingOnPicklistOptions,
	filterFieldOptionsBasedOnFieldType,
	helpText,
	createObjectRecord,
	apexMethods,
	compileText,
	handleValidationAction,
	fieldValidationChecker,
	whatIdList,
	whoIdList
};