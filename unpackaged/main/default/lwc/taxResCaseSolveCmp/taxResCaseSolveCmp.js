import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { displayToast } from "c/utilityService";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import getSolveCaseFields from "@salesforce/apex/TaxResCaseActionsController.getSolveCaseFields";
import getEmailTemplateBody from "@salesforce/apex/TaxResCaseActionsController.getEmailTemplateBody";
import defaultTemplate from "@salesforce/label/c.TaxRes_Solve_Case_Generic_EmailTemplate";

import USER_ID from "@salesforce/user/Id";
import CASE_OWNER from "@salesforce/schema/Case.OwnerId";
import CASE_ACCOUNT_SPECIALIST from "@salesforce/schema/Case.Account_Specialist__c";
import CASE_CUSTOMER_JOURNEY from "@salesforce/schema/Case.Customer_Journey__c";

const DEFAULT_EMAIL_TEMPLATE_NAME = defaultTemplate;
const SOLVE_CASE = "Solve";
const SAVE_CASE = "Save";
const CUSTOMER_JOURNEY_LARGE_SCALE_ISSUE = "Large Scale Issue";
const CASE_FIELD_CUSTOMER_JOURNEY = "Customer_Journey__c";
const RECORD_TYPE = "RecordType";
const fields = [CASE_OWNER, CASE_ACCOUNT_SPECIALIST, CASE_CUSTOMER_JOURNEY, RECORD_TYPE];

export default class TaxResCaseSolveCmp extends LightningElement {
	@api recordId;
	blnIsLoading = true;
	blnIsSaveClick = false;
	recordTypeName;
	@track list_EditableFieldAPINames = [];
	@track list_EditableFieldAPINames_Original;
	@track strButtonLabel = SOLVE_CASE;
	strButtonLabel = SOLVE_CASE;
	blnShowModal = false;
	list_SelectedFiles = [];
	list_SelectedAttachments;

	@wire(getRecord, { recordId: "$recordId", fields })
	caseObj({ data, error }) {
		if (data) {
			this.recordTypeName = data.recordTypeInfo.name;
		}
	}

	@wire(getSolveCaseFields)
	wiredCases({ error, data }) {
		if (data) {
			this.list_EditableFieldAPINames_Original = data;
			this.list_EditableFieldAPINames = data;
			if (this.customerJourney != CUSTOMER_JOURNEY_LARGE_SCALE_ISSUE) {
				this.list_EditableFieldAPINames = this.list_EditableFieldAPINames.filter((eachField) => eachField != "Large_Scale_Issue_Classification__c");
			}
			this.blnIsLoading = false;
		}
	}

	handleOnLoad(event) {
		var record = event.detail.records;
		var fields = record[this.recordId].fields;
		if (fields[CASE_FIELD_CUSTOMER_JOURNEY].value == CUSTOMER_JOURNEY_LARGE_SCALE_ISSUE) {
			this.list_EditableFieldAPINames = this.list_EditableFieldAPINames_Original;
		}
	}

	get caseOwner() {
		return this.caseObj.data ? getFieldValue(this.caseObj.data, CASE_OWNER) : "";
	}

	get accountSpecialist() {
		return this.caseObj.data ? getFieldValue(this.caseObj.data, CASE_ACCOUNT_SPECIALIST) : "";
	}

	get customerJourney() {
		return this.caseObj.data ? getFieldValue(this.caseObj.data, CASE_CUSTOMER_JOURNEY) : "";
	}

	handleSolveBtnClick() {
		this.blnIsSaveClick = false;
		this.blnIsLoading = true;
	}

	handleSaveBtnClick() {
		this.blnIsLoading = true;
		this.blnIsSaveClick = true;
	}

	handleCustomSolveEvent(event) {
		this.strButtonLabel = SOLVE_CASE;
	}

	/* This method is fired whenever user updates any field */
	handleDataChange(event) {
		// Set case object and update tracked field changes
		if (event.target.fieldName == CASE_FIELD_CUSTOMER_JOURNEY) {
			if (event.detail.value == CUSTOMER_JOURNEY_LARGE_SCALE_ISSUE) {
				this.list_EditableFieldAPINames = this.list_EditableFieldAPINames_Original;
			} else {
				this.list_EditableFieldAPINames = this.list_EditableFieldAPINames.filter((eachField) => eachField != "Large_Scale_Issue_Classification__c");
			}
		}
	}

	handleCaseSolve(event) {
		event.preventDefault();
		const fields = event.detail.fields;
		var confirmSendEmail = false;
		var saveRecord = false;
		confirmSendEmail = confirm("Please make sure to send the email.");
		if (confirmSendEmail) {
			saveRecord = true;
		}

		if (this.blnIsSaveClick == false) {
			if (saveRecord) {
				fields.Status = "Solved";
				this.template.querySelector("lightning-record-edit-form").submit(fields);
			} else {
				this.blnIsLoading = false;
			}
		} else {
			this.template.querySelector("lightning-record-edit-form").submit(fields);
		}
	}

	handleSolveError(event) {
		this.blnIsLoading = false;
	}

	handleSolveSuccess(event) {
		if (this.blnIsSaveClick == false) {
			displayToast(this, "Success!", "The Case's record has been successfully solved.", "success", "");
			this.blnIsLoading = false;
			//this.openEmailPublisher();
			if (this.recordTypeName == "Tax Res") {
				this.blnShowModal = true;
			} else {
				this.openEmailPublisher();
			}
		} else {
			this.blnIsLoading = false;
			displayToast(this, "Success!", "The Case's record has been successfully Saved", "success", "");
		}
	}

	openEmailPublisher() {
		this.blnIsLoading = true;
		getEmailTemplateBody({
			strEmailUniqueName: DEFAULT_EMAIL_TEMPLATE_NAME
		})
			.then((result) => {
				if (result?.Id) {
					let evtOpenTab = new CustomEvent("opentab", {
						detail: {
							fullhtmlbody: result.HtmlValue.toString(),
							caseId: this.recordId,
							list_SelectedDocIds: this.list_SelectedFiles,
							list_SelectedAttachmentIds: this.list_SelectedAttachments
						}
					});
					// Fire the custom event
					this.dispatchEvent(evtOpenTab);
				}
			})
			.catch((error) => {
				displayToast(this, "Error!", error.body.message, "error", "");
			})
			.finally(() => {
				this.blnIsLoading = false;
			});
	}

	closeModal(event) {
		this.list_SelectedFiles = [];
		this.list_SelectedAttachments = [];
		this.openEmailPublisher();
		this.blnShowModal = false;
	}

	handleOk(event) {
		event.preventDefault();
		this.list_SelectedFiles = [];
		this.list_SelectedAttachments = [];

		event.detail.selectedFiles.forEach((element) => {
			this.list_SelectedFiles.push(element);
		});
		event.detail.selectedAttachments.forEach((element) => {
			this.list_SelectedAttachments.push(element);
		});
		this.openEmailPublisher();
		this.blnShowModal = false;
	}
}