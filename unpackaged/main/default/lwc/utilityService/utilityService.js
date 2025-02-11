/* Import Standard Events */
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

/*
 * Display Toast Notification to the User
 * self - reference to the class that calls this utility method
 * title - The title of the toast, displayed as a heading.
 * message - A string representing the body of the message.
 * variant - Changes the appearance of the notice. Valid values are: info (default), success, warning, and error.
 * mode - Determines how persistent the toast is. Valid values are dismissable, pester, sticky.
 */
const displayToast = (self, title, message, variant = TOAST_PARAMS.TYPE.INFO, mode = TOAST_PARAMS.MODE.DISMISSIBLE, messageData) => {
	const objToastParams = {
		title,
		variant,
		message,
		mode
	};

	if (messageData && messageData?.length) {
		objToastParams.messageData = messageData;
	}

	self.dispatchEvent(new ShowToastEvent(objToastParams));
};

/*
 * Display Toast Notification to the User
 * self - reference to the class that calls this utility method
 * objToastParams - contains all the Toast Params.
 */
const displayToastWithParams = (self, objToastParams) => {
	self.dispatchEvent(new ShowToastEvent(objToastParams));
};

/*
 * This event enables you to navigate to an sObject record specified by recordId
 * self - reference to the class that calls this utility method
 * Id - Record Id
 * type - If it is an app page or record page etc
 * objectName - sObject API Name
 * accessLevel - whether it is view, edit etc
 */
const navigateToSObject = (self, id, type, objectName, accessLevel) => {
	self[NavigationMixin.Navigate]({
		type: type,
		attributes: {
			recordId: id,
			objectApiName: objectName,
			actionName: accessLevel
		}
	});
};

/*
 * Fires Custom Events for Child to Parent Communication
 * self - reference to the class that calls this utility method
 * data - data that needs to be passed from parent to child
 * name - name of the event
 */
const fireCustomEvent = (self, data, name) => {
	// Creates the event with the data.
	const eventToFire = new CustomEvent(name, { detail: data });
	// Dispatches the event.
	self.dispatchEvent(eventToFire);
};

/*
 * Fires Custom Events to Parent Aura Component
 * self - reference to the class that calls this utility method
 * data - data that needs to be passed from child LWC to Parent Aura
 * name - name of the event
 */
const sendAuraEvent = (self, data, name) => {
	const auraEvent = new CustomEvent(name, {
		detail: { data }
	});
	// Send Aura auraEvent
	self.dispatchEvent(auraEvent);
};

const getQueryParameters = () => {
	let params = {};
	let search = location.search.substring(1);

	if (search) {
		params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
			return key === "" ? value : decodeURIComponent(value);
		});
	}
	return params;
};

/*
 * Added a utility method to String Prototype.
 * Checks if the String contains Substring ignoring case.
 * strSubstring - Substring which needs to be checked if the main String has it.
 */
if (!String.prototype.containsIgnoreCase) {
	String.prototype.containsIgnoreCase = function (strSubstring) {
		return this.toUpperCase().includes(strSubstring.toUpperCase());
	};
}

/*
 * Added a utility method to String Prototype.
 * Checks if the String equals Substring ignoring case.
 * strSubstring - Substring which needs to be checked if the main String has it.
 */
if (!String.prototype.equalsIgnoreCase) {
	String.prototype.equalsIgnoreCase = function (strSubstring) {
		return this.toUpperCase() === strSubstring.toUpperCase();
	};
}

/*
 * Added a utility method to String Prototype.
 * Checks if the String starts with Substring ignoring case.
 * strSubstring - Substring which needs to be checked if the main String has it.
 */
if (!String.prototype.startsWithIgnoreCase) {
	String.prototype.startsWithIgnoreCase = function (strSubstring) {
		return this.toUpperCase().startsWith(strSubstring.toUpperCase());
	};
}

/*
 * Class for Picklist Option which has variables label & value.
 */
class PicklistOption {
	constructor(label, value) {
		this.label = label;
		this.value = value;
	}

	static OPTION_NONE = "None";

	static setLabelAndValue(label) {
		return new PicklistOption(label, label);
	}
}

/*
 * Object to store all the Toast related parameters.
 */
const TOAST_PARAMS = {
	TYPE: {
		ERROR: "error",
		SUCCESS: "success",
		WARNING: "warning",
		INFO: "info"
	},
	MODE: {
		STICKY: "sticky",
		DISMISSIBLE: "dismissible"
	},
	MESSAGE: {
		SUCCESS: "SUCCESS",
		ERROR: "ERROR"
	}
};

/*
 * Object to store all the Field types.
 */
const FIELD_TYPE = {
	PICKLIST: "PICKLIST",
	MULTIPICKLIST: "MULTIPICKLIST",
	TEXTAREA: "TEXTAREA"
};

const checkInputValidity = (validSoFar, inputCmp) => {
	if (typeof inputCmp.value === "string") {
		inputCmp.value = inputCmp.value?.trim();
	}
	inputCmp.reportValidity();
	return validSoFar && inputCmp.checkValidity();
};

const checkInputFieldValidity = (validSoFar, inputCmp) => {
	if (typeof inputCmp.value === "string") {
		inputCmp.value = inputCmp.value?.trim();
	}
	inputCmp.reportValidity();
	return validSoFar;
};

export {
	displayToast,
	displayToastWithParams,
	navigateToSObject,
	fireCustomEvent,
	sendAuraEvent,
	getQueryParameters,
	PicklistOption,
	TOAST_PARAMS,
	FIELD_TYPE,
	checkInputValidity,
	checkInputFieldValidity
};