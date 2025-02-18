import { LightningElement, api, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import fetchSubCaseReasonList from "@salesforce/apex/EngagementCaseViewExtension_LEX.getConfirmSubCaseReasonByCaseReason";
import updateCase from "@salesforce/apex/EngagementCaseViewExtension_LEX.saveCaseRecord";
import loadCaseInfo from "@salesforce/apex/EngagementCaseViewExtension_LEX.setCaseActionInfo";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import Audience from "@salesforce/schema/Case.Audience__c";
import State from "@salesforce/schema/Case.State__c";
import GustoGlobalCountry from "@salesforce/schema/Case.Gusto_Global_Country__c";
import EngagementRecordTypeId from "@salesforce/label/c.EngagementRecordTypeId";
import { NavigationMixin } from "lightning/navigation";
import PartnerAccountCaseReasons from '@salesforce/label/c.Partner_Account_Case_Reasons';
import StateCaseReasons from '@salesforce/label/c.State_Case_Reasons';
import CountryCaseReasons from '@salesforce/label/c.Country_Case_Reasons';
/* Imported Methods from Utility Service */
import { displayToast, sendAuraEvent } from "c/utilityService";
export default class CaseClosurelwc extends NavigationMixin(LightningElement) {
	@api recordId;
	@track objCaseInfo = {};
	/* @api variables grouped together */
	@api strCaseRecordTypes;
	@api strProductAreaEnabledRecordTypes;
	/* @track variables grouped together */
	/* Used to disable showing options on mouseover */
	/* Indicates if component is loading (shows a spinner icon) */
	@track blnIsLoading;
	/* case object */
	@track objCase = {};
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
	/* Flag to indicate if component has completed rendering */
	@track blnIsRendered = false;
	/* Id of the case that the user currently views */
	@track idCase;
	/* Current Record Type Id of the Case */
	idCurrentRecordTypeId;
	/* Flag to indicate if users selected "Other" as Confirm Case Reason */
	@track blnIsOtherCaseReasonAvailable = false;
	/* Flag to indicate if users selected "Other" is required. Confirm Case Reason = Other, Other Case Description is required. Sub Case Reason = Other, Other Case Description is not required */
	@track blnIsOtherCaseReasonRequired = false;
	/* Flag to indicate if sub case reason drop down value needs to be visible */
	@track blnIsSubCaseReasonVisible = false;
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
	/* list of case reasons that require partner account*/
	@track list_PartnerAccountCaseReasons = [];
	/* Flag to indicate if partner account drop down value needs to be visible*/
	@track blnIsPartnerAccountVisible = false;
	/* list of case reasons that require state*/
	@track list_StateCaseReasons = [];
	/* list of case reasons that require Country*/
	@track list_CountryCaseReasons = [];
	blnIsStateRequiredVal = false;
	blnIsCaseReasonRequiredval = true;
	list_CaseRecordTypes;
	productArea;
	subProductArea;
	stateBoolean = false;
	map_caseReasonIdToTypeMap;
	@track selectedProductAreaId = "";
	@track selectedSubproductAreaId = "";
	@track blnShowProductAreaInputbox;
	groupCaseData;
	initLoad = true;
	@track reasonValue = "";
	@track caseReasonError = false;
	@track subReasonError = false;
	@track blnAudienceError = false;
	@track partnerAccountError = false;
	@track stateError = false;
	@track blnhandleCaseReasonSelectedLoaded = false;
	countryError = false;
	countryBoolean = false;
	status;
	@wire(getPicklistValues, {
		recordTypeId: EngagementRecordTypeId, //pass id dynamically
		fieldApiName: Audience
	})
	audienceValues;
	@wire(getPicklistValues, {
		recordTypeId: EngagementRecordTypeId, //pass id dynamically
		fieldApiName: State
	})
	stateValues;
	@wire(getPicklistValues, {
		recordTypeId: EngagementRecordTypeId, //pass id dynamically
		fieldApiName: GustoGlobalCountry
	})
	countryValues;
	handleChange(event) {
		this.objCase.Audience__c = event.target.value;
	}

	validateAudience() {
		if (this.objCase.Audience__c == "" || this.objCase.Audience__c == null) {
			this.blnAudienceError = true;
		} else {
			this.blnAudienceError = false;
		}
	}
	handleStateChange(event) {
		this.objCase.State__c = event.target.value;
	}
	handleCountryChange(event) {
		this.objCase.Gusto_Global_Country__c = event.target.value;
	}
	handleFollowUpDateChange(event) {
		this.objCase.Follow_Up_Date__c = event.target.value;
	}
	@wire(getObjectInfo, { objectApiName: "Case" })
	objCaseInfo;
	connectedCallback() {
		this.blnIsLoading = true;
		this.objCase.Id = this.recordId;
		this.blnIsCaseReasonRequiredval = true;
		if (this.strCaseRecordTypes) {
			this.list_CaseRecordTypes = this.strCaseRecordTypes?.split(",");
		}

		this.list_PartnerAccountCaseReasons = PartnerAccountCaseReasons?.split(",").map(function (strRecordType) {
			return strRecordType.trim();
		});

		this.list_StateCaseReasons = StateCaseReasons?.split(",").map(function(strRecordType) {
			return strRecordType.trim();
		});

		this.list_CountryCaseReasons = CountryCaseReasons?.split(",").map(function(strRecordType) {
			return strRecordType.trim();
		});
	}
	// Load Case Info = get case reason classification, get sub case reasons, get case data etc
	@wire(loadCaseInfo, {
		idCase: "$recordId",
		strProductAreaName: "$selectedProductAreaId",
		strSubProductAreaName: "$selectedSubproductAreaId",
		blnIsInitLoadValue: "$initLoad",
		blnIsCalledFromRoutingCmp: false
	})
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
			if (!this.stateBoolean) {
				if (this.objCase.Type == "Taxes") {
					this.stateBoolean = true;
				} else {
					this.stateBoolean = false;
				}
		    }
			this.idCase = this.objCase.Id;

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
			// Check if map_RequiredFieldsByCaseReason has data
			if (data.map_RequiredFieldsByCaseReason) {
				this.map_RequiredFieldsByCaseReason = data.map_RequiredFieldsByCaseReason;
			}

			if (this.objCase.Confirm_Case_Reason__c != undefined && !this.blnhandleCaseReasonSelectedLoaded) {
				this.handleCaseReasonSelected();
			}
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
		this.objCase.Status = "Closed";
		if (this.reasonValue != null && this.reasonValue != "" && this.reasonValue != undefined) {
			this.objCase.Confirm_Case_Reason_Classification__c = this.reasonValue;
		}
		this.validateCaseReasonGroup();
		this.validateSubReasonGroup();
		this.validateAudience();
		if (this.blnIsPartnerAccountVisible) {
		this.validatePartnerAccount();
		}
		if (this.stateBoolean && this.objCase.Type != "Taxes") {
			this.validateState();
		}
		if (this.countryBoolean) {
			this.validateCountry();
		}
		if (!this.subReasonError && !this.blnAudienceError && !this.caseReasonError && !this.partnerAccountError && !this.stateError && !this.countryError) {
			//if(!this.subReasonError){
			updateCase({
				objCaseToUpdate: this.objCase,
				strRecordType: this.strCurrentRecordType
			})
				.then((result) => {
					// Check if result is successful, show message
					if (result.blnIsSuccess) {
						this.updateRecordView();
						displayToast(this, 'Case Closed Successfully', '', 'success', 'dismissible');
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
					this.closeModal();
				})
				.catch((error) => {
					// If there is an Exception, Show Error Message on the UI
					console.error("Error in caseClosurelwc - handleSave ", error);
					this.error = error;
					this.blnIsLoading = false;
				});
		} else {
			this.blnIsLoading = false;
		}
	}
	updateRecordView() {
		setTimeout(() => {
			eval("$A.get('e.force:refreshView').fire();");
		}, 1000);
	}
	resetcondata() {
		this.selectedValapi = null;
		this.selectedVal = null;
		this.items = this.arritems;
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
			if (eachField.api === event.target.dataset.id) {
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
		this.objCase.Confirm_Sub_Case_Reason__c = event.target.value;
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
		this.blnhandleCaseReasonSelectedLoaded = true;
		this.Openbox = false;
		this.initLoad = false;
		this.blnIsRequiredFieldsDisplayed = false;
		this.list_subCaseReasons = [];

		if (event != undefined) {
			this.objCase.Confirm_Case_Reason__c = event.detail.reason;
			this.reasonValue = event.detail.id;
		} else {
			this.objCase.Confirm_Case_Reason__c = this.objCase.Confirm_Case_Reason__c;
			this.reasonValue = this.objCase.Confirm_Case_Reason_Classification__c;
		}

		// Check if there are any fields required for the selected case reason
		if (this.map_RequiredFieldsByCaseReason[this.reasonValue]) {
			let map_Temp = [];
			let map_FieldsTemp = [];
			map_Temp = this.map_RequiredFieldsByCaseReason[this.reasonValue];
			for (const [strKey, strValue] of Object.entries(map_Temp)) {
				map_FieldsTemp.push({ key: strKey, value: strValue });
			}
			this.map_RequiredFields = map_FieldsTemp;
			this.blnIsRequiredFieldsDisplayed = true;
		}

		if (!this.objCase.Confirm_Case_Reason__c) {
			this.objCase.Confirm_Case_Reason__c = event.detail.reason;
		}
		this.showPartnerAccount();
		this.showState();
		this.showCountry();
		
		//make sure confirm case reason is actually set to blank
		if (!this.objCase.Confirm_Case_Reason_Classification__c) {
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
			strCaseReasonId: this.reasonValue
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
				this.blnIsSubCaseReasonVisible = this.list_subCaseReasons.length > 0 ? true : false;
				//if no sub case reasons available, blank it out
				if (!this.blnIsSubCaseReasonVisible) {
					this.strSubCaseReason = "";
					this.objCase.Confirm_Sub_Case_Reason__c = "";
				}
				this.blnIsOtherCaseReasonAvailable = this.objCase.Confirm_Case_Reason_Classification__c === "Other" ? true : false;
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
			})
			.catch((error) => {
				displayToast(this, error, "", "Error!!", "");
				this.blnIsLoading = false;
			});
	}

	validateSubReasonGroup() {
		if (this.blnIsSubCaseReasonVisible && (this.objCase.Confirm_Sub_Case_Reason__c == "" || this.objCase.Confirm_Sub_Case_Reason__c == null)) {
			this.subReasonError = true;
		} else {
			this.subReasonError = false;
		}
	}

	validateCaseReasonGroup() {
		if (this.objCase.Confirm_Case_Reason__c == "" || this.objCase.Confirm_Case_Reason__c == null) {
			this.caseReasonError = true;
		} else {
			this.caseReasonError = false;
		}
	}

	validatePartnerAccount() {
		if (this.objCase.Partner_Account__c == "" || this.objCase.Partner_Account__c == null) {
			this.partnerAccountError = true;
		} else {
			this.partnerAccountError = false;
		}
	}

	validateState() {
		if (this.objCase.State__c == "" || this.objCase.State__c == null) {
			this.stateError = true;
		} else {
			this.stateError = false;
		}
	}

	validateCountry() {
		if (this.objCase.Gusto_Global_Country__c == "" || this.objCase.Gusto_Global_Country__c == null) {
			this.countryError = true;
		} else {
			this.countryError = false;
		}
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
	closeModal() {
		// Dispatch a custom event to close the modal
		this.dispatchEvent(new CloseActionScreenEvent());
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

	//show State based on Confirm Case Reason
	showState() {
		if (this.list_StateCaseReasons.includes(this.objCase.Confirm_Case_Reason__c)) {
			this.stateBoolean = true;
			this.blnIsStateRequiredVal = true;
		} else {
			this.stateBoolean = false;
			this.objCase.State__c = null;
		}
	}

	//show Country based on Confirm Case Reason
	showCountry() {
		if (this.list_CountryCaseReasons.includes(this.objCase.Confirm_Case_Reason__c)) {
			this.countryBoolean = true;
		} else {
			this.countryBoolean = false;
			this.objCase.Gusto_Global_Country__c = null;
		}
	}
}