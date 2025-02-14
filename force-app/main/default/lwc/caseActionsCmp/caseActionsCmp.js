import { LightningElement, api, track, wire } from "lwc";

/* Import Apex Classes and Methods */
import updateCase from "@salesforce/apex/EngagementCaseViewExtension_LEX.saveCaseRecord";
import loadCaseInfo from "@salesforce/apex/EngagementCaseViewExtension_LEX.setCaseActionInfo";
import loadCurrentCaseInfo from "@salesforce/apex/EngagementCaseViewExtension_LEX.getCurrentCaseInfo";

import fetchSubCaseReasonList from "@salesforce/apex/EngagementCaseViewExtension_LEX.getConfirmSubCaseReasonByCaseReason";
import fetchDynamicFieldList from "@salesforce/apex/EngagementCaseViewExtension_LEX.renderDynamicFields";
import fetchProductSubproductArea from "@salesforce/apex/EngagementCaseViewExtension_LEX.getProductSubproductArea";
import fetchCaseReasonDetails from "@salesforce/apex/EngagementCaseViewExtension_LEX.getCaseReasonDetails";
import assignCases from "@salesforce/apex/PlayModeCaseListControllerLightning.handleNextButton";

import { getRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { refreshApex } from "@salesforce/apex";

/* Imported Methods from Utility Service */
import { displayToast, sendAuraEvent } from "c/utilityService";

/* Import Standard Events */
import { NavigationMixin } from "lightning/navigation";

export default class CaseActionsCmp extends NavigationMixin(LightningElement) {
	/* @api variables grouped together */
	@api recordId;
	@api strCaseRecordTypes;
	@api strPartnerAccountCaseReasons;
	@api strCaseStatuses;
	@api strProductAreaEnabledRecordTypes;

	/* @track variables grouped together */
	/* Used to disable showing options on mouseover */
	@track blnDisableMouseover = true;
	/* Indicates if component is loading (shows a spinner icon) */
	@track blnIsLoading;
	/* case object */
	@track objCase = {};
	/* Used for chevron up and down arrows */
	@track blnIsShowMore = false;
	/* Map of case Type and case reasons */
	@track map_caseReasonToGroupMap = [];
	/* Master Map of case Type and case reasons */
	@track map_totalCaseReasonToGroup = [];
	/* Map of Case Reason and list of required fields */
	map_RequiredFieldsByCaseReason = [];
	/* Decides whether to show auto complete options. else it shows that no case reasons are blnIsFound */
	@track blnIsCaseReasonFound = true;
	/* List of Case fields dynamically rendered based on case record type */
	@track list_dynamicFields = [];
	/* Boolean flag to show if dynamic fields need to be visible */
	@track blnIsDynamicFieldsAvailable = false;
	/* list of sub case reasons related to a particular confirm case reason */
	@track list_subCaseReasons = [];
	/* List of fields required to solve the case */
	@track map_RequiredFields = [];
	/* Decides whether solve button should be disabled. the button will be disabled if all required fields are not completed */
	@track blnIsSolveDisabled = true;
	/* Decides whether save button should be disabled. the button will be disabled if all required fields are not completed */
	@track blnIsSaveDisabled = false;
	/* Decides whether save button is primary or neutral variant */
	@track strSaveButtonVariant = "neutral";
	/* Flag to indicate if component has completed rendering */
	@track blnIsRendered = false;
	/* Flag to check if the case is assigned via play mode */
	@track blnIsPlayMode = false;
	/* Flag to indicate if it is the last case on list cases assigned via play mode. if flag is true and users click Save and Next, more cases are served */
	@track blnIsLastCase = false;
	/* Id of the next case to be served */
	@track idNextCaseToServe;
	/* Id of the case that the user currently views */
	@track idCase;
	/* list of case reasons that require partner account*/
	@track list_PartnerAccountCaseReasons = [];

	/* Current Record Type Id of the Case */
	idCurrentRecordTypeId;
	/* Flag to indicate if users selected "Other" as Confirm Case Reason */
	@track blnIsOtherCaseReasonAvailable = false;
	/* Flag to indicate if users selected "Other" is required. Confirm Case Reason = Other, Other Case Description is required. Sub Case Reason = Other, Other Case Description is not required */
	@track blnIsOtherCaseReasonRequired = false;
	/* Flag to indicate if sub case reason drop down value needs to be visible */
	@track blnIsSubCaseReasonVisible = false;
	/* Flag to indicate if chevron down button is clicked - this change is done to avoid lightning record view form refresh */
	@track blnIsChevronDownClicked = false;
	/* Flag to Show/Hide the required fields to solve the case */
	@track blnIsRequiredFieldsDisplayed = false;
	/* non-track variables grouped together */
	/* record type of the confirm case reason that user selects. It is used to re-render ui dynamic fields when record type changes */
	strCurrentRecordType;
	/* object that contains all the changes that user does from front end */
	objTrackedFieldChange = {};
	/* To store the Case object metadata info */
	@track objCaseInfo = {};
	/* flag to show the fields only when origin is phone */
	@track blnIsPhoneOriginFieldsAvailable = false;
	/* map of case reasons to record type map */
	map_caseReasonToRecordTypeMap = {};
	/* Decides whether to include slds-box wrapper surrounding the component */
	strBoxWrapperClass = "";
	/* Flag to check if case is read only - all fields are disabled for read only cases. all buttons are not visible */
	blnIsReadOnlyCase = false;
	/* Flag to execute renderedCallback method */

	blnIsSubCaseReasonRequired = true;
	list_CaseRecordTypes;
	blnIsPartnerAccountVisible;
	productArea;
	subProductArea;
	refreshSetCaseData;
	map_caseReasonIdToTypeMap;
	@track selectedProductAreaId = "";
	@track selectedSubproductAreaId = "";
	@track list_strProductAreas = [];
	@track list_strSubproductAreas = [];
	@track strSelectedProductArea = "";
	@track strSelectedSubproductArea = "";
	@track blnShowProductAreaInputbox;
	list_strProductAreasMaster;
	list_strSubproductAreasMaster;
	list_strSubproductAreaCurrentList;
	groupCaseData;
	initLoad = true;
	/* wire methods grouped together */
	@wire(getRecord, { recordId: "$recordId", fields: ["Case.Status", "Case.RecordType.Name"] })
	getCaseRecord({ data, error }) {
		if (data) {
			this.objCase.Status = data.fields["Status"].value;
			let strCaseRecordTypeName = data.fields["RecordType"].displayValue.toLowerCase();
			let list_EnabledRecordTypes = this.strProductAreaEnabledRecordTypes ? this.strProductAreaEnabledRecordTypes.toLowerCase().split(",") : [];
			list_EnabledRecordTypes?.forEach(function (item, index) {
				this[index] = item.trim();
			}, list_EnabledRecordTypes);
			this.blnShowProductAreaInputbox = list_EnabledRecordTypes?.indexOf(strCaseRecordTypeName) !== -1 ? true : false;
		}
	}
	@wire(getObjectInfo, { objectApiName: "Case" })
	objCaseInfo;
	// Get all the sub product are which we need on inital load to have multi level filter selections
	@wire(fetchProductSubproductArea)
	getProductSubproductArea({ data, error }) {
		this.list_strProductAreasMaster = data?.list_ProductArea;
		this.list_strSubproductAreasMaster = data?.list_SubproductArea;
		this.list_strSubproductAreaCurrentList = data?.list_SubproductArea;
		this.list_strProductAreas = this.getFullProductAreas();
		this.list_strSubproductAreas = this.getFullSubproductAreas();
	}
	// Get all the product are which we need on inital load to have multi level filter selections
	// all product areas should be available for selection on initial load
	getFullProductAreas() {
		let list_strProductAreas = [];
		if (this.list_strProductAreasMaster) {
			this.list_strProductAreasMaster.forEach(function (item) {
				list_strProductAreas.push(item.Name);
			});
		}
		return list_strProductAreas;
	}
	// Get all the sub product are which we need on inital load to have multi level filter selections
	// all sub product areas should be available for selection on initial load
	getFullSubproductAreas() {
		let list_strSubproductAreas = [];
		if (this.list_strSubproductAreasMaster) {
			this.list_strSubproductAreasMaster.forEach(function (item) {
				list_strSubproductAreas.push(item.Name);
			});
		}
		return list_strSubproductAreas;
	}
	//method called when product area is selected
	handleFilterSelected(event) {
		this.blnIsLoading = true;
		let targetLabel = event.target.label;
		this.initLoad = false;
		this.updateDependentValues(event.detail, targetLabel);
		refreshApex(this.groupCaseData);
	}
	//method called when product area is selected to get the related dependant values
	updateDependentValues(value, targetFieldLabel) {
		if (value && targetFieldLabel === "Product Area (Optional)") {
			this.strSelectedSubproductArea = "";
			this.selectedSubproductAreaId = "";
			this.strSelectedProductArea = value;
			this.selectedProductAreaId = this.list_strProductAreasMaster.filter((prodArea) => prodArea.Name === value)[0].Id;
			this.filterSubProductArea();
		} else if (!value && targetFieldLabel === "Product Area (Optional)") {
			this.strSelectedSubproductArea = "";
			this.selectedSubproductAreaId = "";
			this.strSelectedProductArea = "";
			this.selectedProductAreaId = "";
			this.list_strProductAreas = this.getFullProductAreas();
			this.list_strSubproductAreaCurrentList = this.list_strSubproductAreasMaster;
			this.list_strSubproductAreas = this.getFullSubproductAreas();
			if (this.template.querySelector('c-auto-complete-cmp[data-id="subproductcmp"]')) {
				this.template.querySelector('c-auto-complete-cmp[data-id="subproductcmp"]').strTextInput = "";
			}
		}

		if (value && targetFieldLabel === "Sub Product Area (Optional)") {
			let selectedSubproductArea;
			selectedSubproductArea = this.list_strSubproductAreasMaster.filter((subprodArea) => subprodArea.Name === value)[0];
			this.strSelectedProductArea = selectedSubproductArea.Product_Area__r.Name;
			this.selectedProductAreaId = selectedSubproductArea.Product_Area__c;
			this.strSelectedSubproductArea = value;
			this.selectedSubproductAreaId = selectedSubproductArea.Id;
		} else if (!value && targetFieldLabel === "Sub Product Area (Optional)") {
			this.strSelectedSubproductArea = "";
			this.selectedSubproductAreaId = "";
		}
		this.objCase.Confirm_Case_Reason__c = !this.initLoad ? "" : this.objCase.Confirm_Case_Reason__c;
	}

	// method to filter the sub product area
	filterSubProductArea() {
		let filterdSubProductArea = [];
		let currentSubProductArea = [];
		this.list_strSubproductAreasMaster.forEach((subprodArea) => {
			if (subprodArea.Product_Area__r.Name === this.strSelectedProductArea) {
				filterdSubProductArea.push(subprodArea.Name);
				currentSubProductArea.push(subprodArea);
			}
		});
		this.list_strSubproductAreas = filterdSubProductArea;
		this.list_strSubproductAreaCurrentList = currentSubProductArea;
	}

	//Product area initial list of values
	handleFilterList(event) {
		let targetLabel = event.target.label;
		let value = event.detail ?? "";
		let list_arrFieldSearch = [];
		let list_master = [];
		if (targetLabel === "Product Area (Optional)") {
			list_master = this.list_strProductAreasMaster;
		}
		if (targetLabel === "Sub Product Area (Optional)") {
			list_master = this.list_strSubproductAreaCurrentList;
		}
		if (value) {
			list_master.forEach((detail) => {
				if (detail.Name.toLowerCase().includes(value.toLowerCase())) {
					list_arrFieldSearch.push(detail.Name);
				}
			});
			if (targetLabel === "Product Area (Optional)") {
				this.strSelectedProductArea = value;
				this.list_strProductAreas = list_arrFieldSearch;
			}
			if (targetLabel === "Sub Product Area (Optional)") {
				this.strSelectedSubproductArea = value;
				this.list_strSubproductAreas = list_arrFieldSearch;
			}
		} else if (targetLabel === "Sub Product Area (Optional)") {
			list_master.forEach((detail) => {
				list_arrFieldSearch.push(detail.Name);
			});
			this.list_strSubproductAreas = list_arrFieldSearch;
		}
	}
	// Different list of Case Status values, advocates can select
	get statusoptions() {
		var list_Statuses = [];

		if (this.strCaseStatuses) {
			let list_Values = this.strCaseStatuses.split(",");
			for (let strStatus of list_Values) {
				list_Statuses.push({ label: strStatus, value: strStatus });
			}
		}

		return list_Statuses;
	}

	connectedCallback() {
		this.objCase.Id = this.recordId;
		// Check if component is placed in LiveChatTranscript or Case Page
		if (window.location.href.includes("LiveChatTranscript")) {
			this.strBoxWrapperClass = "slds-box slds-theme_default";
		} else {
			this.strBoxWrapperClass = "slds-theme_default";
		}

		if (this.strCaseRecordTypes) {
			this.list_CaseRecordTypes = this.strCaseRecordTypes?.split(",");
		}

		this.list_PartnerAccountCaseReasons = this.strPartnerAccountCaseReasons?.split(",").map(function (strRecordType) {
			return strRecordType.trim();
		});
	}
	// Load Case Info = get case reason classification, get sub case reasons, get case data etc
	@wire(loadCaseInfo, { idCase: "$recordId", strProductAreaName: "$selectedProductAreaId", strSubProductAreaName: "$selectedSubproductAreaId", blnIsInitLoadValue: "$initLoad", blnIsCalledFromRoutingCmp: false})
	loadCaseData(value) {
		this.groupCaseData = value;
		// Show Spinner
		let result = JSON.parse(JSON.stringify(value));
		let data = result.data;
		let error = result.error;

		if (data) {
			this.objCase = this.initLoad ? data.objCase : this.objCase;
			// Set current record type - Will be used when a confirm reason is selected
			this.strCurrentRecordType = this.objCase.Confirm_Case_Reason__c && this.strCurrentRecordType ? this.strCurrentRecordType : data.objCase.Record_Type_Name__c;
			// If case record type ends with read only, set blnIsReadOnlyCase to True
			if (this.strCurrentRecordType?.endsWith("Read Only")) {
				this.blnIsReadOnlyCase = true;
			}

			this.idCase = this.objCase.Id;

			if (this.objCase && (this.objCase.RecordType.Name == 'Benefits Care' || this.objCase.RecordType.Name == 'Payroll Care') && (this.objCase.Origin == 'Phone' || (this.objCase.Origin == 'Gusto' && this.objCase.Channel__c == 'Phone'))) {
				this.blnIsPhoneOriginFieldsAvailable = true;
			}

			if (!this.selectedProductAreaId && this.initLoad) {
				this.strSelectedProductArea = this.objCase.Product_Area__c ? this.objCase.Product_Area__r.Name : "";
				this.selectedProductAreaId = this.objCase.Product_Area__c ?? "";
				this.updateDependentValues(this.strSelectedProductArea, "Product Area (Optional)");
			}

			if (!this.selectedSubproductAreaId && this.initLoad) {
				this.strSelectedSubproductArea = this.objCase.Sub_Product_Area__c ? this.objCase.Sub_Product_Area__r.Name : "";
				this.selectedSubproductAreaId = this.objCase.Sub_Product_Area__c ?? "";
				this.updateDependentValues(this.strSelectedSubproductArea, "Sub Product Area (Optional)");
			}

			// Fetch case action config
			if (data.list_caseActionField) {
				// deserialize the list
				let list_arrFields = JSON.parse(data.list_caseActionField.Configuration_Json__c);
				// check if size is set, use override labels if required
				list_arrFields.forEach((objEachField) => {
					objEachField.size = objEachField.size ? objEachField.size : "6";
					objEachField.label = objEachField.overrideLabel ? objEachField.overrideLabel : objEachField.label;
				});

				// set to dynamic field list
				this.list_dynamicFields = list_arrFields;

				if (this.list_dynamicFields.length > 0) {
					this.blnIsDynamicFieldsAvailable = true;
				}
			}
			// Set list of sub reasons if available
			if (data.list_subCaseReasons && this.initLoad) {
				let list_arrSubCaseReasons = [];
				data.list_subCaseReasons.forEach((eachSubCaseReason) => {
					list_arrSubCaseReasons.push({
						label: eachSubCaseReason,
						value: eachSubCaseReason
					});
				});
				this.list_subCaseReasons = list_arrSubCaseReasons;

				if (this.list_CaseRecordTypes && this.initLoad) {
					this.blnIsSubCaseReasonRequired = !this.list_CaseRecordTypes?.includes(this.strCurrentRecordType);
				}
				// Conditionally decide to show sub case reasons
				if (this.initLoad) {
					this.blnIsSubCaseReasonVisible = this.list_subCaseReasons.length > 0 ? true : false;
				}
			}

			if (data.map_caseReasonIdToTypeMap) {
				this.map_caseReasonIdToTypeMap = data.map_caseReasonIdToTypeMap;
			}

			// Filtered list of case reason classification
			if (data.map_caseReasonToGroupMap) {
				let list_arrCaseReasons = [];
				for (const strRecordType in data.map_caseReasonToGroupMap) {
					let list_caseReasonClassifications = [];
					let objCaseReason = {};
					objCaseReason.group = strRecordType;
					for (let idCaseReason in data.map_caseReasonToGroupMap[strRecordType]) {
						list_caseReasonClassifications.push({
							label: data.map_caseReasonToGroupMap[strRecordType][idCaseReason],
							key: idCaseReason
						});
					}

					objCaseReason.value = list_caseReasonClassifications;

					list_arrCaseReasons.push(objCaseReason);
					if (objCaseReason.value) {
						objCaseReason.value.forEach((objValue) => {
							this.map_caseReasonToRecordTypeMap[objValue] = strRecordType;
						});
					}
				}

				this.map_totalCaseReasonToGroup = list_arrCaseReasons;
				if (list_arrCaseReasons.length === 0) {
					this.blnIsCaseReasonFound = false;
				}
				// Conditionally decide to show if Other case reason needs to be displayed
				this.blnIsOtherCaseReasonAvailable = this.objCase.Confirm_Case_Reason__c === "Other" ? true : false;
				if (this.blnIsOtherCaseReasonAvailable) {
					this.blnIsOtherCaseReasonRequired = true;
				}
				// If Confirm Case Reason is not Other, Check if Sub Case Reason has Other
				if (!this.blnIsOtherCaseReasonAvailable) {
					let strSubCaseReason = this.objCase.Confirm_Sub_Case_Reason__c;
					if (strSubCaseReason) {
						this.blnIsOtherCaseReasonAvailable = strSubCaseReason.toLowerCase().includes("other") ? true : false;
						if (this.blnIsOtherCaseReasonAvailable) {
							this.blnIsOtherCaseReasonRequired = false;
						}
					}
				}
			}

			// Check user preference object and see if current record id matches user preference's case play selected cases field
			if (data.objUserPreference) {
				data.objUserPreference.Case_Play_Selected_Cases__c = data.objUserPreference.Case_Play_Selected_Cases__c ? data.objUserPreference.Case_Play_Selected_Cases__c : "";
				this.blnIsPlayMode = data.objUserPreference.Case_Play_Selected_Cases__c.includes(this.recordId) ? true : false;
				if (this.blnIsPlayMode) {
					let intCounter = 1;
					let list_casesSplit = data.objUserPreference.Case_Play_Selected_Cases__c.split(",");
					list_casesSplit.forEach((objEachCase) => {
						if (objEachCase === this.recordId) {
							this.blnIsLastCase = intCounter === list_casesSplit.length ? true : false;
							this.idNextCaseToServe = list_casesSplit[intCounter];
						}
						intCounter = intCounter + 1;
					});
				}
			}

			// Check if map_RequiredFieldsByCaseReason has data
			if (data.map_RequiredFieldsByCaseReason) {
				this.map_RequiredFieldsByCaseReason = data.map_RequiredFieldsByCaseReason;
			}

			//Check if the Case has a case reason
			if (this.objCase.Confirm_Case_Reason_Classification__c) {
				if (this.map_RequiredFieldsByCaseReason[this.objCase.Confirm_Case_Reason_Classification__c]) {
					let map_CaseFields = [];
					let map_Temp = [];
					map_CaseFields = this.map_RequiredFieldsByCaseReason[this.objCase.Confirm_Case_Reason_Classification__c];
					for (const [strKey, strValue] of Object.entries(map_CaseFields)) {
						map_Temp.push({ key: strKey, value: strValue });
					}
					this.map_RequiredFields = map_Temp;
					this.blnIsRequiredFieldsDisplayed = true;
				}
			}

			this.showPartnerAccount();

			this.idCurrentRecordTypeId = this.objCase.RecordTypeId;

			// End showing spinner
			this.blnIsLoading = false;
			this.blnIsRendered = false;
		} else if (error) {
			// If there is an Exception, Show Error Message on the UI
			this.error = error;
			this.blnIsLoading = false;
		}
		this.blnIsLoading = false;
	}
	// saves case record to salesforce
	handleSave() {
		this.blnIsLoading = true;
		this.objCase.Product_Area__c = this.selectedProductAreaId;
		this.objCase.Sub_Product_Area__c = this.selectedSubproductAreaId;

		// objCase is the data from Apex, which includes the Contact field.
		// If another component updates the Contact field, it might not refresh and will revert back.
		// To prevent this, we remove the Contact attributes from the object.
		const objCaseToUpdate = { ...this.objCase };
		delete objCaseToUpdate.Contact;
		delete objCaseToUpdate.ContactId;

		updateCase({
			objCaseToUpdate: objCaseToUpdate,
			strRecordType: this.strCurrentRecordType
		})
			.then((result) => {
				// Check if result is successful, show message
				if (result.blnIsSuccess) {
					displayToast(this, result.strMessage, "", "success", "");
					// send an aura event to reload other tabs that have the same case Id opened
					sendAuraEvent(
						this,
						{
							idCase: this.idCase,
							objTrackedFieldChanges: this.objTrackedFieldChange
						},
						"reloadcase"
					);
					// Set trackFieldChanges to {}
					this.objTrackedFieldChange = {};
				} else {
					displayToast(this, result.strMessage, "", "error", "");
				}
				this.blnIsLoading = false;
			})
			.catch((error) => {
				// If there is an Exception, Show Error Message on the UI
				console.error("Error in caseActionsCmp - handleSave ", error);
				this.error = error;
				this.blnIsLoading = false;
			});
	}

	/* This method is fired whenever user updates any field */
	handleDataChange(event) {
		// Set case object and update tracked field changes
		if (event.detail.value !== undefined) {
			this.objCase[event.target.dataset.api] = event.detail.value ? event.detail.value.toString() : null;
			this.objTrackedFieldChange[event.target.dataset.api] = event.detail.value ? event.detail.value.toString() : null;
		} else if (event.detail.checked !== this.objCase[event.target.dataset.api]) {
			this.objCase[event.target.dataset.api] = event.detail.checked;
			this.objTrackedFieldChange[event.target.dataset.api] = event.detail.checked;
		}

		// set value on dynamic field list
		this.list_dynamicFields.forEach((eachField) => {
			if (eachField.api === event.target.dataset.api) {
				if (event.detail.value !== undefined) {
					eachField.value = event.detail.value;
				}
			}
		});
		// check if all required fields are filled
		this.checkValidity();

		// Check if Confirm Sub Case Reason has Other
		let strSubCaseReason = this.objCase.Confirm_Sub_Case_Reason__c;
		if (strSubCaseReason) {
			this.blnIsOtherCaseReasonAvailable = strSubCaseReason.toLowerCase().includes("other") ? true : false;
			if (this.blnIsOtherCaseReasonAvailable) {
				this.blnIsOtherCaseReasonRequired = false;
			}
		}
	}

	/* Handles when user clicks chevron down button */
	handleShowMore() {
		let objHiddenFields = this.template.querySelector('[data-id="hidden-fields"]');
		let objChevronDownButton = this.template.querySelector('[data-id="chevron-down"]');
		let objChevronUpButton = this.template.querySelector('[data-id="chevron-up"]');

		// Hide Down Button
		if (objChevronDownButton) {
			objChevronDownButton.classList.add("hide");
		}
		// Show up button
		if (objChevronUpButton) {
			objChevronUpButton.classList.remove("hide");
		}
		if (objHiddenFields) {
			this.template.querySelector('[data-id="hidden-fields"]').classList.remove("hide");
		}
		// Check if chevron button was not clicked before, then set it to true. This will only be set once.
		if (!this.blnIsChevronDownClicked) {
			this.blnIsChevronDownClicked = true;
		}
	}

	/* Handles when user clicks chevron up button */
	handleHideDetails() {
		let objHiddenFields = this.template.querySelector('[data-id="hidden-fields"]');
		let objChevronDownButton = this.template.querySelector('[data-id="chevron-down"]');
		let objChevronUpButton = this.template.querySelector('[data-id="chevron-up"]');

		if (objChevronDownButton) {
			objChevronDownButton.classList.remove("hide");
		}

		if (objChevronUpButton) {
			objChevronUpButton.classList.add("hide");
		}

		if (objHiddenFields) {
			this.template.querySelector('[data-id="hidden-fields"]').classList.add("hide");
		}
	}

	escapeRegex(string) {
		return string.replace(/[^a-zA-Z0-9]/g, "");
	}

	// This method is responsible for showing filtered case reason for auto complete
	handleFilterCaseReason(event) {
		// Get input
		let strinput = event.detail;
		// Check if strinput has a value else set to blank
		strinput = strinput ? strinput : "";
		// If strinput is blank, solve button should be disabled
		if (strinput === "") {
			this.blnIsSolveDisabled = true;
			this.strSaveButtonVariant = "brand";
		}
		let map_totalCaseReasons = this.map_totalCaseReasonToGroup;
		let list_arrCaseReasons = [];
		let intCounter = 0;
		map_totalCaseReasons.forEach((caseReason) => {
			let objCaseReasonsToAdd = {};
			let list_sortedCaseReasons = [];
			let blnIsFound = false;
			objCaseReasonsToAdd.group = caseReason.group;
			caseReason.value.forEach((objEachValue) => {
				if (this.escapeRegex(objEachValue.label.toLowerCase()).includes(this.escapeRegex(strinput.toLowerCase()))) {
					if (intCounter < 30) {
						list_sortedCaseReasons.push(objEachValue);
						blnIsFound = true;
					}
					intCounter = intCounter + 1;
				}
			});
			if (blnIsFound) {
				objCaseReasonsToAdd.value = list_sortedCaseReasons.sort();
				list_arrCaseReasons.push(objCaseReasonsToAdd);
			}
		});
		this.map_caseReasonToGroupMap = list_arrCaseReasons;
		if (list_arrCaseReasons.length === 0) {
			this.blnIsCaseReasonFound = false;
		} else {
			this.blnIsCaseReasonFound = true;
		}
	}

	// When a case reason is selected from auto complete
	handleCaseReasonSelected(event) {
		this.initLoad = false;
		this.blnIsRequiredFieldsDisplayed = false;
		this.list_subCaseReasons = [];

		// Check if there are any fields required for the selected case reason
		if (this.map_RequiredFieldsByCaseReason[event.detail.id]) {
			let map_Temp = [];
			let map_FieldsTemp = [];
			map_Temp = this.map_RequiredFieldsByCaseReason[event.detail.id];
			for (const [strKey, strValue] of Object.entries(map_Temp)) {
				map_FieldsTemp.push({ key: strKey, value: strValue });
			}
			this.map_RequiredFields = map_FieldsTemp;
			this.blnIsRequiredFieldsDisplayed = true;
		}

		this.objCase.Confirm_Case_Reason__c = event.detail.reason;

		this.showPartnerAccount();

		//make sure confirm case reason is actually set to blank
		if (!this.objCase.Confirm_Case_Reason__c) {
			this.objCase.Confirm_Case_Reason__c = "";
			//setting the required fields to blank if case reason is empty
			for (let objField of this.map_RequiredFields) {
				if (objField.value) {
					// Reset values for non checkbox fields
					this.objCase[objField.key] = "";
				} else if (this.objCase[objField.key]) {
					//Check if checkbox is true and reset value
					this.objCase[objField.key] = !this.objCase[objField.key];
				}
			}
		}
		// Check if all required fields are filled out
		this.checkValidity();
		this.blnIsLoading = true;
		fetchSubCaseReasonList({
			strCaseReasonId: event.detail.id
		})
			.then((result) => {
				let list_arrSubCaseReasons = [];
				result.forEach((objEachSubCaseReason) => {
					list_arrSubCaseReasons.push({
						label: objEachSubCaseReason,
						value: objEachSubCaseReason
					});
				});

				this.list_subCaseReasons = list_arrSubCaseReasons;
				this.blnIsSubCaseReasonRequired = !this.list_CaseRecordTypes?.includes(event.detail.type);
				this.blnIsSubCaseReasonVisible = this.list_subCaseReasons.length > 0 ? true : false;

				//if no sub case reasons available, blank it out
				if (!this.blnIsSubCaseReasonVisible) {
					this.strSubCaseReason = "";
					this.objCase.Confirm_Sub_Case_Reason__c = "";
				}
				this.blnIsOtherCaseReasonAvailable = this.objCase.Confirm_Case_Reason__c === "Other" ? true : false;
				if (this.blnIsOtherCaseReasonAvailable) {
					this.blnIsOtherCaseReasonRequired = true;
				}

				// Check if Confirm Sub Case Reason is Other
				if (!this.blnIsOtherCaseReasonAvailable) {
					let strSubCaseReason = this.objCase.Confirm_Sub_Case_Reason__c;
					if (strSubCaseReason) {
						this.blnIsOtherCaseReasonAvailable = strSubCaseReason.toLowerCase().includes("other") ? true : false;
						if (this.blnIsOtherCaseReasonAvailable) {
							this.blnIsOtherCaseReasonRequired = false;
						}
					}
				}

				this.checkValidity();
				this.blnIsLoading = false;
				this.blnIsRendered = false;
				let strRecordTypeToChange = this.map_caseReasonIdToTypeMap?.[event.detail.id];
				// If record type changes = re-render dynamic fields
				if (strRecordTypeToChange) {
					if (this.strCurrentRecordType !== strRecordTypeToChange) {
						this.strCurrentRecordType = strRecordTypeToChange;
						let list_RecordTypeInfos = this.objCaseInfo.data.recordTypeInfos;
						this.idCurrentRecordTypeId = Object.keys(list_RecordTypeInfos).find((idRT) => list_RecordTypeInfos[idRT].name === this.strCurrentRecordType);
						this.objCase.Error_Origin__c = "";
						this.reRenderDynamicFields(strRecordTypeToChange);
					}
				}
			})
			.catch((error) => {
				displayToast(this, error, "", "Error!!", "");
				this.blnIsLoading = false;
			});

		if (!this.strSelectedProductArea && this.blnShowProductAreaInputbox && event.detail?.id) {
			fetchCaseReasonDetails({
				idCaseReason: event.detail.id
			})
				.then((result) => {
					if (result.Product_Area__c) {
						this.strSelectedProductArea = result.Product_Area__r.Name;
						this.selectedProductAreaId = result.Product_Area__c;
						this.filterSubProductArea();
					}
					if (result.Sub_Product_Area__c) {
						this.strSelectedSubproductArea = result.Sub_Product_Area__r.Name;
						this.selectedSubproductAreaId = result.Sub_Product_Area__c;
					}
				})
				.catch((error) => {
					console.error("Error in CaseActionsCmp - handleCaseReasonSelected ", error);
				});
		}
	}
	/* Re render dynamic fields when a case reason is selected */
	reRenderDynamicFields(strRecordTypeToChange) {
		let objCase = {
			Record_Type_Name__c: strRecordTypeToChange
		};
		this.blnIsLoading = true;
		/* Fetch dynamic fields */
		fetchDynamicFieldList({
			objCase: objCase,
			idCase: this.objCase.Id
		})
			.then((result) => {
				if (result) {
					let list_arrFields = JSON.parse(result.Configuration_Json__c);
					list_arrFields.forEach((objEachField) => {
						objEachField.size = objEachField.size ? objEachField.size : "6";
						objEachField.label = objEachField.overrideLabel ? objEachField.overrideLabel : objEachField.label;
						objEachField.value = this.objCase[objEachField.api];
					});
					this.list_dynamicFields = list_arrFields;
					if (this.list_dynamicFields.length > 0) {
						this.blnIsDynamicFieldsAvailable = true;
					}

					this.checkValidity();
				}
				this.blnIsLoading = false;
			})
			.catch((error) => {
				console.error("Error in caseActionsCmp - reRenderDynamicFields ", error);
				this.blnIsLoading = false;
			});
	}

	/* It is used for refreshing the UI. when the same case is opened in multiple tabs */
	@api loadCaseRecord(idRecord, objTrackedFieldChange) {
		if (idRecord === this.idCase) {
			this.blnIsLoading = true;
			loadCurrentCaseInfo({
				idCase: this.idCase
			})
				.then((result) => {
					if (result) {
						this.objCase = result;
						this.list_dynamicFields.forEach((objEachField) => {
							if (objTrackedFieldChange[objEachField.api]) {
								objEachField.value = objTrackedFieldChange[objEachField.api];
								this.objCase[objEachField.api] = objTrackedFieldChange[objEachField.api];
							}
						});
					}
					this.blnIsLoading = false;
				})
				.catch((error) => {
					console.error("Error in caseActionsCmp - loadCaseRecord ", error);
					this.blnIsLoading = false;
				});
		}
	}
	/* Used for Saving current case and getting next case on the play mode */
	@api saveAndNext() {
		this.handleSave();
	}

	/* Used when user clicks Solve a Case */
	handleSolveCase() {
		// Validate form before solving a case
		let blnIsValid = true;
		const allValid = [...this.template.querySelectorAll("lightning-input-field")].reduce((validSoFar, inputCmp) => {
			if (!inputCmp.reportValidity()) blnIsValid = false;
			return validSoFar;
		}, true);

		// If the form is valid, update case status to Solved
		if (blnIsValid) {
			this.blnIsLoading = true;
			this.objCase.Product_Area__c = this.selectedProductAreaId;
			this.objCase.Sub_Product_Area__c = this.selectedSubproductAreaId;
			this.objCase.Status = "Solved";

			// objCase is the data from Apex, which includes the Contact field.
			// If another component updates the Contact field, it might not refresh and will revert back.
			// To prevent this, we remove the Contact attributes from the object.
			const objCaseToUpdate = { ...this.objCase };
			delete objCaseToUpdate.Contact;
			delete objCaseToUpdate.ContactId;

			updateCase({
				objCaseToUpdate: objCaseToUpdate,
				strRecordType: this.strCurrentRecordType
			})
				.then((result) => {
					if (result.blnIsSuccess) {
						displayToast(this, "Case solved successfully!", "", "success", "");
						if (!window.location.href.includes("LiveChatTranscript")) {
							if (!this.blnIsPlayMode) {
								// Close focussed tab, if the case is not play mode and not on live chat transcript page
								const evtCloseTab = new CustomEvent("closefocustab", {
									detail: {}
								});
								// Fire the custom event
								this.dispatchEvent(evtCloseTab);
							} else {
								// If user solves a case that is in play mode, serve next case
								//this.handleSaveAndNext();
								const evtCloseTab = new CustomEvent("closefocustab", {
									detail: {}
								});
								// Fire the custom event
								this.dispatchEvent(evtCloseTab);
							}
						}
					} else {
						displayToast(this, result.strMessage, "", "error", "");
					}
					this.blnIsLoading = false;
				})
				.catch((error) => {
					// If there is an Exception, Show Error Message on the UI
					console.log("Error in caseActionsCmp - solveCase ", error);
					this.error = error;
					this.blnIsLoading = false;
				});
		} else {
			this.blnIsSolveDisabled = true;
			this.blnIsSaveDisabled = true;
		}
	}
	handleCustomLookupOut(event) {
		this.template.querySelectorAll("c-custom-lookup-cmp").forEach((element) => {
			element.hideDropDown();
		});
	}
	/* Checks if all required fields are filled properly */
	checkValidity() {
		let blnIsValid = true;
		const allValid = [...this.template.querySelectorAll("lightning-input-field,lightning-input,lightning-combobox")].reduce((validSoFar, inputCmp) => {
			// Check if required fields are filled out only for fields that are above the chevron
			if (inputCmp.getAttribute("data-visibility") === "true") {
				if (inputCmp.getAttribute("data-input-field") === "true") {
					if (!inputCmp.reportValidity()) {
						blnIsValid = false;
					}
				} else {
					if (!inputCmp.checkValidity()) {
						inputCmp.reportValidity();
						blnIsValid = false;
					}
				}
			}
			return validSoFar;
		}, true);
		this.blnIsSolveDisabled = !blnIsValid;
		this.blnIsSaveDisabled = !blnIsValid;
		this.strSaveButtonVariant = "neutral";
		if (!this.objCase.Confirm_Case_Reason__c) {
			this.blnIsSolveDisabled = true; //don't disable save button
		}
		if (this.objCase.Confirm_Case_Reason__c === "Other" && !this.objCase.Other_Case_Reason_Description__c) {
			this.blnIsSolveDisabled = true;
			this.blnIsSaveDisabled = true;
			this.strSaveButtonVariant = "neutral";
		}
		if (this.objCase.Status === "Solved" && !this.objCase.Confirm_Case_Reason__c) {
			this.blnIsSaveDisabled = true;
		}
	}

	/* Copying Case Id to Clipboard */
	copyToClipBoard() {
		const objElement = document.createElement("textarea");
		objElement.value = window.location.origin + "/lightning/r/Case/" + this.objCase.Id + "/view";
		document.body.appendChild(objElement);
		objElement.select();
		document.execCommand("copy");
		document.body.removeChild(objElement);
		displayToast(this, "Case URL copied to clipboard!", "", "success", "");
	}

	/* Users click Save and Next on a case that is assigned via play mode */
	handleSaveAndNext() {
		// Checks it is last case. then serve more cases
		if (this.blnIsLastCase) {
			this.blnIsLoading = true;
			assignCases()
				.then((result) => {
					this.blnIsLoading = false;
					let intCounter = result.list_cases.length;
					if (intCounter === 1) {
						displayToast(this, result.list_cases[0].CaseNumber + " assigned to you successfully", "", "success", "sticky");
					} else if (intCounter > 1) {
						displayToast(this, result.list_cases[0].CaseNumber + " and " + (intCounter - 1) + " other cases assigned to you successfully", "", "success", "sticky");
					}
					this.idNextCaseToServe = result.list_cases[0].Id;
					this.fireCloseTabEvent();
				})
				.catch((error) => {
					this.blnIsLoading = false;
				});
		} else {
			this.fireCloseTabEvent();
		}
	}

	/* Fire Close Tab event to Close Current Case, Save Current Case and Open next case in Play Mode */
	fireCloseTabEvent() {
		const evtCloseTab = new CustomEvent("closetab", {
			detail: {
				idNextCaseToServe: this.idNextCaseToServe,
				idTabToClose: this.recordId,
				objCase: this.objCase
			}
		});
		// Fire the custom event
		this.dispatchEvent(evtCloseTab);
	}

	/* Set Status method is used when answers component updates status and sends the data through application event */
	@api setStatus(status) {
		this.objCase.Status = status;
	}

	/* handling save case */
	@api saveCase(objCase) {
		this.objCase = objCase;
		this.handleSave();
	}

	/* To display the Case Sub Reason values in the dropdown without being truncated */
	renderedCallback() {
		if (this.blnIsRendered) {
			return;
		}
		if (this.template.querySelector(".custom-dropdown")) {
			this.blnIsRendered = true;
			const style = document.createElement("style");
			style.innerText = `
                .slds-dropdown lightning-base-combobox-item .slds-media__body .slds-truncate {
                    white-space : pre-wrap;
                }
            `;
			this.template.querySelector(".custom-dropdown").appendChild(style);
		}
	}

	//show Partner Account based on Confirm Case Reason
	showPartnerAccount() {
		if (this.list_PartnerAccountCaseReasons.includes(this.objCase.Confirm_Case_Reason__c)) {
			this.blnIsPartnerAccountVisible = true;
		} else {
			this.blnIsPartnerAccountVisible = false;
			this.objCase.Partner_Account__c = null;
		}
	}
}