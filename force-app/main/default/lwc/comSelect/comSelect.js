import { LightningElement, track, api, wire } from "lwc";

import * as util from "./comSelectUtil.js";

export default class ComLookup extends LightningElement {
	/********** @tracks ***********/

	@track showCombobox = true;
	@track setCssOnMultipleSelectTrue = "slds-is-relative";
	@track dropdownOptions = [];

	/********** @apis ***********/

	@api sObjectName;
	@api fieldLevelHelpText; // pass value to set field Level help text
	@api labelFor; // For eg: labelFor = 'Contact';
	@api lookupIcon; // For eg: lookupIcon = 'standard:contact';
	@api iconColor; // for eg: 65CAE4
	@api isLabelHidden = false; // to show label or not on Ui.
	@api isRequired;
	@api selOption = "";
	@api picklistOptionMap = new Map();
	@api categoryOptions = [];
	@api recordtype;

	@api
	validateCombobox() {
		return [...this.template.querySelectorAll('[data-combobox-name="options-combobox"]')].reduce(util.checkInputValidity, true);
	}

	bgColor;
	hasCategoryFocus = false;

	get isComboboxDisabled() {
		return !this.sObjectName;
	}

	renderedCallback() {}

	connectedCallback(preventTracking) {
		try {
			if (Array.isArray(this.categoryOptions) && this.categoryOptions?.length) {
				this.sortCategoryOptions();

				if (!this.sObjectName) {
					this.sObjectName = this.categoryOptions[0].value;
				}

				this.isLabelHidden = this.setBooleanValue(this.isLabelHidden);
				this.setLookUpProperties();
				this.setDropdownOptions();
			}
		} catch (err) {
			let error = err.name + ": " + err.message;
			util.showToast(util.TOAST_PARAMS.MESSAGE.ERROR, util.TOAST_PARAMS.TYPE.ERROR, error, null, null, this);
		}
	}

	sortCategoryOptions() {
		let [listA, listB] = this.categoryOptions.reduce(([p, f], e) => (e["value"] === "User" ? [[...p, e], f] : [p, [...f, e]]), [[], []]);
		this.categoryOptions = [...listA, ...listB];
	}

	setLookUpProperties() {
		const sobjName = this.sObjectName;
		const sobjectDetail = this.categoryOptions.find((cur) => cur.value === sobjName);
		if (sobjectDetail) {
			this.setIconProz(sobjectDetail);
		}
	}

	setDropdownOptions() {
		// if object is account and record type is company - include payroll opportunity and all open benefits opportunities
		if (this.sObjectName == 'Account' && this.recordtype == 'Company') {
			this.dropdownOptions = [];
			// picklistOptionMap is map of object name and list of records
			// iterate over each object name and add all records to be visible in the dropdown list
			this.picklistOptionMap.forEach((value, key) => {
				value.forEach((cur) => {
					let duplicateElement = this.dropdownOptions.some((cur1) => cur1.label === cur.label);
					// do not add duplicate element in drop down
					if (!duplicateElement) {
						this.dropdownOptions.push(cur);
					}
				});

			});
		} else {
			this.dropdownOptions = this.sObjectName && this.picklistOptionMap?.has(this.sObjectName) ? this.picklistOptionMap.get(this.sObjectName) : [{ label: "--None--", value: "" }];
		}
	}

	// Set Boolean value in this.multipleSelect if user passed string value
	setBooleanValue(inputValue) {
		const blnMap = new Map().set("true", true).set("false", false);

		if (typeof inputValue === "string") {
			let lowerCaseInputValue = inputValue?.toLowerCase();

			if (blnMap.has(lowerCaseInputValue)) {
				inputValue = blnMap.get(lowerCaseInputValue);
			} else if (inputValue) {
				let strErrMessage = "You have passed the wrong " + inputValue + " value.";
				strErrMessage += " Please pass either true or false in boolean or string format.";

				util.showToast(util.TOAST_PARAMS.MESSAGE.ERROR, util.TOAST_PARAMS.TYPE.ERROR, strErrMessage, null, "6000ms", this);

				this.showCombobox = false;
				return;
			}
		}
		return inputValue;
	}

	setIconProz(objIcon) {
		this.lookupIcon = objIcon.url;
		this.setBgColor(objIcon.color);
	}

	setBgColor(color) {
		this.bgColor = `background-color : #${color} !important`;
	}

	openDropDownList(event) {
		try {
			event.stopPropagation();
			this.template.querySelector('[data-combobox-name="category-combobox"]')?.classList.toggle("slds-is-open");
		} catch (error) {
			util.javaScriptError(error, this);
		}
	}

	handleBlur() {
		try {
			if (!this.hasCategoryFocus) {
				this.dropDownCloseHandler();
			}
		} catch (error) {
			util.javaScriptError(error, this);
		}
	}

	handleMouseleave() {
		try {
			this.hasCategoryFocus = false;
		} catch (error) {
			util.javaScriptError(error, this);
		}
	}

	handleMouseEnter() {
		try {
			this.hasCategoryFocus = true;
		} catch (error) {
			util.javaScriptError(error, this);
		}
	}

	dropDownCloseHandler() {
		try {
			this.template.querySelector('[data-combobox-name="category-combobox"]').classList.toggle("slds-is-open");
		} catch (error) {
			util.javaScriptError(error, this);
		}
	}

	handleSelection(event) {
		try {
			event.stopPropagation();
			this.dropDownCloseHandler();

			const sObjectName = event.currentTarget.dataset.value;

			if (this.sObjectName !== sObjectName) {
				this.selOption = "";
			}

			this.sObjectName = sObjectName;

			this.categoryOptions.forEach((cur) => {
				if (sObjectName === cur.value) {
					this.setLookUpProperties();
				}
			});

			this.setDropdownOptions();
		} catch (error) {
			util.javaScriptError(error, this);
		}
	}

	handleDropdownChange(event) {
		try {
			this.selOption = event.detail.value;
			fireSelectedOptionEvent(this);
		} catch (error) {
			util.javaScriptError(error, this);
		}
	}
}

const fireSelectedOptionEvent = (thisArg) => {
	try {
		thisArg.dispatchEvent(
			new CustomEvent("selectoptionchange", {
				detail: {
					selOption: thisArg.selOption,
					sObjectName: thisArg.sObjectName
				}
			})
		);
	} catch (err) {
		util.showToast(util.TOAST_PARAMS.MESSAGE.ERROR, util.TOAST_PARAMS.TYPE.ERROR, `${err.name}: ${err.message}`, null, null, this);
	}
};