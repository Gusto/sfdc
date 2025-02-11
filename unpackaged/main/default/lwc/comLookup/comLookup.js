import { LightningElement, track, api, wire } from "lwc";

import { javaScriptError, setObjectRecord, keyMaker, apexCaller, showErrorToast, sortList, showToast, whatIdList, whoIdList } from "c/comBase";

import getSobjectName from "@salesforce/apex/ComLookupController.getSobjectName";
import getRecordsList from "@salesforce/apex/ComLookupController.getRecordsList";
import getSelectedRecordsList from "@salesforce/apex/ComLookupController.getSelectedRecordsList";

export default class ComLookup extends LightningElement {
	sObjectName; // system will auto set based on current selection

	/********** @tracks ***********/

	@track sObjectList = [];
	@api selectedSObjectList = [];
	@track searchText = "";
	@track showSearchInputBox = true;
	@track setCssOnPills;
	@track setCssOnMultipleSelectTrue = "slds-is-relative";
	@track setCssOnInputSearchBox = "slds-input slds-combobox__input";
	@track setCssOnShowListDiv = "slds-is-absolute";
	@track isShowSpinner;

	/********** @apis ***********/

	@api parentObjApiName; // pass objectName
	@api refFieldApiName; // pass fieldName
	@api placeholderText; // pass value to set placeholder value in lookup
	@api fieldLevelHelpText; // pass value to set field Level help text
	@api isView; // To show only in read only
	@api labelFor; // For eg: labelFor = 'Contact';
	@api lookupIcon; // For eg: lookupIcon = 'standard:contact';
	@api iconColor; // for eg: 65CAE4
	@api showFieldApiName; // For eg: showFieldApiName = 'Name';
	@api idFieldApiName = "Id"; // For eg: idFieldApiName = 'Id';
	@api searchFieldApiName; // For eg: searchFieldApiName = 'LastName';
	@api whereConditions; // For eg: whereConditions = "FirstName = 'Andy'";
	@api selectedRecordIds; // For eg: selectedRecordIds = ['',''] or
	@api multipleSelect = false; // For eg: multipleSelect = false --> if user want to be select multiple record
	@api labelHidden = false; // to show label or not on Ui.
	@api queryFieldApiNamesStr; // api name of query fields
	@api queryFieldsApiName = []; // pass array as field
	@api required;
	@api isDisabled; // when we want to show value only readonly
	@api setFocus;
	@api hideCreateNewRecordButton;

	onInit = true;

	@track dropDownOptions = [];
	bgColor;

	/********** private non-reactive instance ***********/

	salesforceObjectList;
	selectedSalesforceSobject;
	isSelectRecordActionCall;
	showQueryInModal;
	get isSlctdSobjLst() {
		if (this.selectedSObjectList && this.selectedSObjectList.length > 0) {
			return true;
		}
		return false;
	}

	get readOnlyValue() {
		if (this.selectedSObjectList && this.selectedSObjectList.length > 0) {
			let value = `<a href="/${this.selectedSObjectList[0]["Id"]}" target="_blank"><b>${this.selectedSObjectList[0]["Name"]}</b></a>`;
			return this.selectedSObjectList.length > 1 ? `${value} + ${this.selectedSObjectList.length}` : value;
		}
		return null;
	}

	showInputBoxFocusRendered = true;
	showPillFocusRendered = true;

	connectedCallback(preventTracking) {
		const self = this;
		try {
			this.selectedSObjectList = [];
			this.setSelectedRecordIdsAndVerifyIdsSize();
			const params = {
				list_SelectedRecordIds: this.selectedRecordIds ? this.selectedRecordIds : null
			};
			if (this.selectedRecordIds && this.selectedRecordIds.length) {
				this.isShowSpinner = true;
				apexCaller(getSobjectName, params, self, function (result) {
					this.isShowSpinner = false;
					try {
						this.sObjectName = result;
						this.performActionOnGetSelectedObjFieldsRes(preventTracking);
					} catch (error) {
						javaScriptError(error, this);
					}
				});
			} else {
				this.performActionOnGetSelectedObjFieldsRes(preventTracking);
			}

			if (this.iconColor) {
				this.setBgColor(this.iconColor);
			}
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}

	performActionOnGetSelectedObjFieldsRes(preventTracking) {
		if (this.refFieldApiName == "WhatId") {
			var fieldWrapList = whatIdList;
		}

		if (this.refFieldApiName == "WhoId") {
			fieldWrapList = whoIdList;
		}
		if (fieldWrapList) {
			this.dropDownOptions = fieldWrapList;
			this.sortSobjectList();
		}
		if (this.dropDownOptions && this.dropDownOptions.length) {
			if (!this.sObjectName) {
				this.sObjectName = this.dropDownOptions[0].value;
			}

			this.setLookUpProperties();
		}
		this.initializeLookUp(preventTracking);
	}

	sortSobjectList() {
		let [listA, listB] = this.dropDownOptions.reduce(([p, f], e) => (e["value"] === "User" ? [[...p, e], f] : [p, [...f, e]]), [[], []]);
		this.dropDownOptions = [...listA, ...listB];
	}

	setLookUpProperties(isMultiple) {
		const sobjName = this.sObjectName;
		const sobjectDetail = this.dropDownOptions.find((cur) => cur["value"] === sobjName);
		if (sobjectDetail) {
			this.setIconProz(sobjectDetail);
		}
	}

	// if user set multiple select is false and pass array of ids and then it will show error
	setSelectedRecordIdsAndVerifyIdsSize() {
		if (this.multipleSelect) {
			if (this.selectedRecordIds && !Array.isArray(this.selectedRecordIds)) {
				this.selectedRecordIds = [this.selectedRecordIds];
			}
		} else {
			if (this.selectedRecordIds) {
				if (Array.isArray(this.selectedRecordIds)) {
					this.selectedRecordIds = JSON.parse(JSON.stringify(this.selectedRecordIds));
					if (selectedRecordIds && this.selectedRecordIds.length > 0) {
						let message = "You have set multipleSelect equal to false and passing multiple record Ids.";
						showToast("Error!", "error", message, null, "6000ms", this);
						this.showSearchInputBox = false;
						return;
					}
				} else {
					this.selectedRecordIds = [this.selectedRecordIds];
				}
			}
		}
	}

	initializeLookUp(preventTracking) {
		const self = this;
		try {
			this.multipleSelect = this.setBooleanValue(this.multipleSelect);

			// Set Boolean value in this.labelHidden if user passed string value
			this.labelHidden = this.setBooleanValue(this.labelHidden);

			// Add CSS
			this.setCss();

			if (this.queryFieldApiNamesStr) this.queryFieldsApiName = this.queryFieldApiNamesStr.split(",");

			if (!this.selectedRecordIds) {
				setTimeout(() => {
					self.setFocusOnLightningInput();
				}, 100);
			}
			/* Fetch pre-selected records and show on the UI*/
			this.getPreSelectedRecords(preventTracking);
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}

	setFocusOnLightningInput() {
		if (this.setFocus) {
			const lightningInputs = this.template.querySelectorAll("input.slds-input");
			if (lightningInputs) {
				lightningInputs.forEach((curLghtngInpt) => {
					curLghtngInpt.focus();
					this.showInputBoxFocusRendered = true;
				});
			}
		}
	}

	// Set Boolean value in this.multipleSelect if user passed string value
	setBooleanValue(element) {
		if (typeof element == "string") {
			if (element && element.toLowerCase() == "true") element = true;
			else if (element && element.toLowerCase() == "false") element = false;
			else if (element) {
				let message = "You have passed the wrong " + element + " value.";
				message += " Please pass either true or false in boolean or string format.";
				showToast("Error!", "error", message, null, "6000ms", this);
				this.showSearchInputBox = false;
				return;
			}
		}
		return element;
	}

	/* Fetch pre-selected records and show on the UI*/

	getPreSelectedRecords(preventTracking) {
		if (this.sObjectName) {
			let selectedRecordIds;
			if (this.selectedRecordIds) {
				if (Array.isArray(this.selectedRecordIds)) {
					selectedRecordIds = JSON.parse(JSON.stringify(this.selectedRecordIds));
				} else {
					selectedRecordIds = [this.selectedRecordIds];
				}
			}
			if (selectedRecordIds && selectedRecordIds.length > 0) {
				this.getSelectedRecordsListAction(selectedRecordIds, preventTracking);
			}
		}
	}

	getSelectedRecordsListAction(selectedRecordIds, preventTracking) {
		const self = this;
		const params = {
			strObjectName: this.sObjectName,
			strShowFieldApiName: this.showFieldApiName,
			strFieldApiName: this.idFieldApiName,
			list_SelectedRecordIds: selectedRecordIds,
			list_QueryFieldsApiNames: this.queryFieldsApiName
		};

		this.isShowSpinner = true;
		apexCaller(getSelectedRecordsList, params, self, function (response) {
			this.isShowSpinner = false;
			try {
				if (response.strLabel && !this.labelFor) {
					this.labelFor = response.strLabel;
				}

				if (response.strShowAndSrchFieldApiName) {
					if (!this.showFieldApiName) {
						this.showFieldApiName = response.strShowAndSrchFieldApiName;
					}
					if (!this.searchFieldApiName) {
						this.searchFieldApiName = response.strShowAndSrchFieldApiName;
					}
				}
				if (response.list_Sobjects && response.list_Sobjects.length > 0) {
					this.salesforceObjectList = response.list_Sobjects;

					let selectedSObjectList = [];
					response.list_Sobjects.forEach((cur) => {
						selectedSObjectList.push(this.setSObject(cur));
					});
					this.selectedSObjectList = selectedSObjectList;
					this.showPillFocusRendered = false;
					if (!this.multipleSelect) {
						this.showSearchInputBox = false;
					}
				} else {
					this.salesforceObjectList = [];
					this.selectedSObjectList = [];
				}
				if (this.selectedSObjectList && this.selectedSObjectList.length > 0 && !this.onInit && !preventTracking) {
					fireSelectedRecordIdsChangeEvent(selectedRecordIds, this);
				}
			} catch (err) {
				javaScriptError(err, this);
			}
		});
	}

	setIconProz(iconPropz) {
		this.lookupIcon = iconPropz.url;
		this.setBgColor(iconPropz.color);
	}

	setBgColor(color) {
		this.bgColor = "background-color : #" + color + "!important";
	}

	setSObject(cur) {
		try {
			let sObject = { Id: "", Name: "" };
			sObject.Id = cur[this.idFieldApiName];
			sObject.Name = cur[this.showFieldApiName];

			if (this.sObjectName === "Contact" && cur["Account"] && cur["Account"]["Name"]) {
				let accountName = cur["Account"]["Name"];
				if (accountName && accountName.length > 20) {
					accountName = accountName.substring(0, 20) + "...";
				}
				sObject.AccName = accountName;
			}
			return sObject;
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}

	// Set Css
	setCss() {
		var node = document.createElement("style");
		node.type = "text/css";
		if (this.multipleSelect) {
			this.setCssOnMultipleSelectTrue = "  slds-is-relative ";
			this.setCssOnInputSearchBox = "slds-input slds-combobox__input slds-p-horizontal_xxx-small slds-input-has-icon_right";
			this.setCssOnPills = "custom-block ";
			node.innerHTML = ".custom-block[comlookup_comlookup] .slds-pill__action{padding: 5px 27px;}";
			node.innerHTML += " .custom-block[comlookup_comlookup] .slds-pill{padding: 5px 2px;}";
			node.innerHTML += " .custom-block[comlookup_comlookup] .slds-pill__icon_container{ padding-left: 2px;}";
		} else {
			// add custom css for lightning pill container so that its work properly in multiple select mode false.
			this.setCssOnPills = "custom-block slds-show";
			this.setCssOnShowListDiv = "slds-is-absolute setRightProperty ";

			node.innerHTML = ".custom-block.slds-show[comlookup_comlookup] .slds-pill__action{ display:block; padding: 5px 27px;}";
			node.innerHTML += " .custom-block.slds-show[comlookup_comlookup] .slds-pill__icon_container{ padding-left: 2px;}";
			node.innerHTML += " .custom-block.slds-show[comlookup_comlookup] .slds-pill{ width: 100%; padding: 5px 2px;}";
			node.innerHTML += " .custom-block.slds-show[comlookup_comlookup] .slds-pill__remove{ margin-left: auto;}";
		}
		document.getElementsByTagName("head")[0].appendChild(node);
	}

	openDropDownList(event) {
		try {
			event.stopPropagation();
			let sldsCombobox = this.template.querySelector(".slds-combobox");
			sldsCombobox.classList.add("slds-is-open");
		} catch (error) {
			javaScriptError(error, this);
		}
	}

	focus = false;

	handleBlur() {
		try {
			if (!this.focus) {
				this.dropDownCloseHandler();
			}
		} catch (error) {
			javaScriptError(error, this);
		}
	}
	handleMouseleave() {
		try {
			this.focus = false;
		} catch (error) {
			javaScriptError(error, this);
		}
	}
	handleMouseEnter() {
		try {
			this.focus = true;
		} catch (error) {
			javaScriptError(error, this);
		}
	}

	showInputBoxFocusRendered = true;
	showPillFocusRendered = true;
	renderedCallback() {
		if (!this.showInputBoxFocusRendered) {
			this.setFocusOnLightningInput();
		}
		if (!this.showPillFocusRendered && this.setFocus) {
			const lightningPill = this.template.querySelector("lightning-pill");
			if (lightningPill) {
				lightningPill.focus();
				this.showPillFocusRendered = true;
			}
		}
	}

	dropDownCloseHandler() {
		try {
			let sldsCombobox = this.template.querySelector(".slds-combobox");
			sldsCombobox.classList.remove("slds-is-open");
		} catch (error) {
			javaScriptError(error, this);
		}
	}

	handleSelection(event) {
		try {
			event.stopPropagation();
			this.dropDownCloseHandler();
			let { value } = event.currentTarget.dataset;
			this.sObjectName = value;
			this.dropDownOptions.forEach((cur) => {
				if (this.sObjectName == cur.value) {
					this.setLookUpProperties(true);
				}
			});
		} catch (error) {
			javaScriptError(error, this);
		}
	}

	@track showRecents;
	@api
	handleSearchTextChangeAction(event) {
		const self = this;
		if (event) {
			event.stopPropagation();
			if (event.key === "Escape") return;
			this.searchText = event.currentTarget.value;
		}
		/* Fetch records based on the search text*/
		try {
			if (this.refFieldApiName == "RecordTypeId") {
				this.whereConditions = ` SobjectType = '${this.parentObjApiName}'`;
			}

			if (this.sObjectName && this.idFieldApiName) {
				const params = {
					strSobjectName: this.sObjectName,
					strShowFieldApiName: this.showFieldApiName,
					strFieldApiName: this.idFieldApiName,
					strSearchFieldApiName: this.searchFieldApiName,
					strSearchText: this.searchText,
					list_SelectedRecordIds: this.selectedRecordIds,
					strWhereConditions: this.whereConditions,
					list_QueryFieldsApiNames: this.queryFieldsApiName
				};
				apexCaller(getRecordsList, params, self, function (response) {
					try {
						if (this.searchText && this.searchText.trim()) {
							this.showRecents = false;
						} else {
							this.showRecents = true;
						}
						if (response) {
							this.salesforceObjectList = response;
							let sObjectList = [];
							response.forEach((cur) => {
								sObjectList.push(this.setSObject(cur));
							});

							if (!this.hideCreateNewRecordButton) {
								sObjectList.push({
									Id: "Create New Record",
									Name: "Create New Record",
									isNew: true
								});
							}

							this.sObjectList = sObjectList;
						}
					} catch (error) {
						javaScriptError(error, this);
					}
				});
			} else {
				this.sObjectList = [];
			}
			this.handleValidationAction();
			const showList = this.template.querySelector('div[data-show-list="showList"]');
			if (showList && event && event.target) {
				showList.style.width = event.target.offsetWidth + "px";
			}
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}

	@api
	handleValidationAction(callback) {
		const self = this;
		let allValid = true;
		const inputContainer = this.template.querySelector("div.inputContainer>input");
		if (inputContainer) {
			if (this.required) {
				if (this.multipleSelect) {
					if (!this.selectedRecordIds || (this.selectedRecordIds && this.selectedRecordIds.length <= 0)) {
						inputContainer.classList.add("slds-has-error");
						allValid = false;
					} else {
						inputContainer.classList.remove("slds-has-error");
					}
				} else {
					if (!this.selectedRecordIds || (this.selectedRecordIds && this.selectedRecordIds.length <= 0)) {
						inputContainer.classList.add("slds-has-error");
						allValid = false;
					} else {
						inputContainer.classList.remove("slds-has-error");
					}
				}
			} else {
				inputContainer.classList.remove("slds-has-error");
			}
		}
		if (callback) callback.call(this, allValid);
	}

	handleHidePicklistOnBlur(event) {
		const self = this;
		try {
			this.handleValidationAction();
			if (!this.focus) {
				this.handleHidePicklist();
			} else {
				this.setSobjLstEmpty();
			}
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}

	handleHidePicklist(event) {
		const self = this;
		try {
			this.setSobjLstEmpty();
			this.dispatchEventHidePopOver();
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}
	setSobjLstEmpty() {
		const self = this;
		setTimeout(function () {
			if (!self.isSelectRecordActionCall) {
				self.sObjectList = [];
			}
			self.isSelectRecordActionCall = false;
		}, 200);
	}

	dispatchEventHidePopOver() {
		const self = this;
		setTimeout(() => {
			/*
        Use this event to hide-popover if we will use in datatable
      */
			self.dispatchEvent(new CustomEvent("hidepopover", { detail: "" }));
		}, 300);
	}

	@track sobjectRecord;
	handleOnSelectRecordAction(event) {
		const self = this;
		try {
			this.isSelectRecordActionCall = true;
			if (event && event.currentTarget && event.currentTarget.dataset && event.currentTarget.dataset.id && event.currentTarget.dataset.name) {
				if (event.currentTarget.dataset.name == "Create New Record") {
					// we will add logic later for this
					return;
				}
				let sObject = { Id: "", Name: "" };
				sObject.Id = event.currentTarget.dataset.id;
				sObject.Name = event.currentTarget.dataset.name;

				let selectedSObjList = JSON.parse(JSON.stringify(this.selectedSObjectList));
				selectedSObjList.push(sObject);

				this.selectedSObjectList = selectedSObjList;
				let selectedRecordIds;
				if (this.selectedRecordIds) {
					selectedRecordIds = JSON.parse(JSON.stringify(this.selectedRecordIds));
				}
				if (this.multipleSelect) {
					if (!selectedRecordIds) {
						selectedRecordIds = [];
					}
					selectedRecordIds.push(sObject.Id);
				} else {
					selectedRecordIds = [sObject.Id];
					this.selectedSalesforceSobject = this.salesforceObjectList.filter((salesforceObj) => {
						return salesforceObj.Id == sObject.Id;
					});
					this.showSearchInputBox = false;
				}

				this.selectedRecordIds = selectedRecordIds;
				this.sObjectList = [];
				this.searchText = null;
				const searchBox = this.template.querySelector('input[data-search-box="searchBox"]');
				if (searchBox) {
					searchBox.value = null;
				}
				fireSelectedRecordIdsChangeEvent(this.selectedRecordIds, this);
			}
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}

	handleRemoveSelectedRec(event) {
		event.stopPropagation();
		/*Remove the selected record from the selected-sObject-list records*/
		try {
			if (event && event.currentTarget && event.currentTarget.name) {
				this.preventEventHidePopOver = true;
				const currRecordId = event.currentTarget.name;
				this.removeSelectedRec(currRecordId);
			}
		} catch (err) {
			let error = err.name + ": " + err.message;
			showToast("Error!", "error", error, null, null, this);
		}
	}

	@api
	removeSelectedRec(currRecordId) {
		this.selectedSObjectList = this.selectedSObjectList.filter((cur) => cur.Id != currRecordId);
		if (this.multipleSelect) this.selectedRecordIds = this.selectedRecordIds.filter((cur) => cur != currRecordId);
		else {
			this.showSearchInputBox = true;
			this.selectedRecordIds = [];
			this.selectedSalesforceSobject = [];
			this.showInputBoxFocusRendered = false;
		}
		fireSelectedRecordIdsChangeEvent(this.selectedRecordIds, this);
	}

	@api
	setSelectedRecId(recId, preventTracking) {
		const inputContainer = this.template.querySelector(".inputContainer");
		if (inputContainer) {
			inputContainer.querySelector("input").value = null;
		}
		this.showSearchInputBox = true;
		this.selectedRecordIds = recId;
		this.onInit = false;
		this.showFieldApiName = null;		
		this.selectedSalesforceSobject = [];
		this.connectedCallback(preventTracking);
		fireSelectedRecordIdsChangeEvent(this.selectedRecordIds, this);
	}
}
const fireSelectedRecordIdsChangeEvent = (selectedRecordIds, thisArg) => {
	try {
		if (thisArg.multipleSelect == false) {
			if (selectedRecordIds && selectedRecordIds.length > 0) {
				selectedRecordIds = selectedRecordIds[0];
			} else {
				selectedRecordIds = null;
			}
			if (thisArg.selectedSalesforceSobject && thisArg.selectedSalesforceSobject.length > 0) {
				var selectedSalesforceSobject = thisArg.selectedSalesforceSobject[0];
			}
		}
		const detail = {
			selectedRecordIds: selectedRecordIds,
			selectedSalesforceSobject: selectedSalesforceSobject,
			selectedSObjList: thisArg.selectedSObjectList,
			sObjectName: thisArg.sObjectName,
			refFieldApiName: thisArg.refFieldApiName
		};
		thisArg.dispatchEvent(
			new CustomEvent("selectedrecordidlistchange", {
				detail: detail
			})
		);
		thisArg.value = selectedRecordIds;
	} catch (err) {
		let error = err.name + ": " + err.message;
		showToast("Error!", "error", error, null, null, this);
	}
};