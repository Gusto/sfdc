import { LightningElement, track, wire, api } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import ESCALATIONCASE_OBJECT from "@salesforce/schema/Case_Escalation__c";
import escalateCaseRecord from "@salesforce/apex/PlayModeCaseListControllerLightning.escalateCaseRecord";
import ESCALATIONREASONS_FIELD from "@salesforce/schema/Case_Escalation__c.Escalation_Reason__c";
import strOutOfScopeReasonField from "@salesforce/schema/Case_Escalation__c.Out_of_Scope_Reason__c";
import strTeamField from "@salesforce/schema/Case_Escalation__c.Team__c";
import strCaseTypeField from "@salesforce/schema/Case_Escalation__c.Case_Type__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CaseEscalationComponent extends LightningElement {
	/* To store the picklist values of escalation reasons*/
	@track list_EscalationReasonValues;
	/* To store the escalation reason selected*/
	@track strEscalationReasonValue;

	//out of scope reason picklist values
	@track list_OutOfScopeReasonValues;
	//value of Out of Scope Reason chosen
	strOutOfScopeReasonValue;

	//Team field values
	@track list_TeamValues;
	//value of team chosen
	strTeamValue;

	//Case Type values
	@track list_CaseTypes;
	//value of Case Type chosen
	strCaseType;

	//was Incorrect Routing chosen
	blnIsIncorrectRouting = false;
	//was Out of Scope chosen
	blnIsOutOfScope = false;

	/* Flag to open the modal for escalation case */
	@api blnOpenModal;
	/* To store the case Id*/
	@api strRecordId;
	/*To store the escalation comments */
	@track strEscalationComment;
	/* Flag to show Spinner*/
	@track blnIsLoading = false;

	@wire(getObjectInfo, { objectApiName: ESCALATIONCASE_OBJECT })
	objectInfo;

	blnEnableReroute = false;

	//get Escalation Reason picklist values
	@wire(getPicklistValues, {
		recordTypeId: "$objectInfo.data.defaultRecordTypeId",
		fieldApiName: ESCALATIONREASONS_FIELD
	})
	escalationReasonPicklistValues({ data, error }) {
		if (data) {
			console.log("--", data.values);
			this.list_EscalationReasonValues = data.values;
		}

		if (error) {
			console.log("error" + error);
		}
	}

	//get Team picklist values
	@wire(getPicklistValues, {
		recordTypeId: "$objectInfo.data.defaultRecordTypeId",
		fieldApiName: strTeamField
	})
	getTeams({ data, error }) {
		if (data) {
			this.list_TeamValues = data.values;
		}

		if (error) {
			console.log("error from team: " + error);
		}
	}

	//get Out of Scope Reason picklist values
	@wire(getPicklistValues, {
		recordTypeId: "$objectInfo.data.defaultRecordTypeId",
		fieldApiName: strOutOfScopeReasonField
	})
	getOutOfScopeReasons({ data, error }) {
		if (data) {
			this.list_OutOfScopeReasonValues = data.values;
		}

		if (error) {
			console.log("error from out of scope: " + error);
		}
	}

	//get Case Type picklist values
	@wire(getPicklistValues, {
		recordTypeId: "$objectInfo.data.defaultRecordTypeId",
		fieldApiName: strCaseTypeField
	})
	getCaseTypes({ data, error }) {
		if (data) {
			this.list_CaseTypes = data.values;
		}

		if (error) {
			console.log("error from out of scope: " + error);
		}
	}

	//handle when Escalation Reason changes
	handleEscalationReasonChange(event) {
		this.strEscalationReasonValue = event.detail.value;

		//clear out fields so as to not save them accidentally in Apex
		this.strOutOfScopeReasonValue = this.strTeamValue = this.strCaseType = null;

		if (this.strEscalationReasonValue === "Incorrect Routing") {
			this.blnIsIncorrectRouting = true;
			this.blnIsOutOfScope = false;
		} else if (this.strEscalationReasonValue === "Out of Scope") {
			this.blnIsOutOfScope = true;
			this.blnIsIncorrectRouting = false;
		} else {
			this.blnIsOutOfScope = false;
			this.blnIsIncorrectRouting = false;
		}
		this.validateFields();
	}

	//set Team value
	handleTeamChange(event) {
		this.strTeamValue = event.detail.value;
		this.validateFields();
	}

	//set Out of Scope Reason value
	handleOutOfScopeReasonChange(event) {
		this.strOutOfScopeReasonValue = event.detail.value;
		this.validateFields();
	}

	//set Escalation Comment value
	handleEscalationComment(event) {
		this.strEscalationComment = event.detail.value;
		this.validateFields();
	}

	//set Escalation Comment value
	handleCaseTypeChange(event) {
		this.strCaseType = event.detail.value;
		this.validateFields();
	}

	//handle when the cancel button is clicked
	handleCancel() {
		this.blnOpenModal = false;
		this.dispatchEvent(
			new CustomEvent("closemodal", {
				detail: { closeModal: this.blnOpenModal }
			})
		);
	}

	//check to see if available fields are all filled in
	validateFields() {
		this.blnEnableReroute = false;
		//first check if we have a Reason and Comment
		if (!(this.strEscalationReasonValue && this.strEscalationComment)) {
			this.blnEnableReroute = false;
		} else if (this.strEscalationReasonValue === "Incorrect Routing") {
			//if Incorrect Routing is selected, make sure team is selected
			if (this.strTeamValue) {
				this.blnEnableReroute = true;
			}
		} else if (this.strEscalationReasonValue === "Out of Scope") {
			//if Out of Scope is selected, make sure Case Type and Out of Scope Reason are selected
			if (this.strCaseType && this.strOutOfScopeReasonValue) {
				this.blnEnableReroute = true;
			}
		} else if (this.strEscalationReasonValue === "Customer Requested") {
			this.blnEnableReroute = true;
		}
	}

	//handle save
	handleEscalate() {
		this.blnIsLoading = true;
		escalateCaseRecord({
			idCase: this.strRecordId,
			strComments: this.strEscalationComment,
			strReasons: this.strEscalationReasonValue,
			strTeam: this.strTeamValue,
			strOutOfScopeReason: this.strOutOfScopeReasonValue,
			strCaseType: this.strCaseType
		})
			.then((result) => {
				this.blnOpenModal = false;

				console.log("--working fine");
				this.blnIsLoading = false;
				const evt = new ShowToastEvent({
					title: "Success",
					message: "Case has been rerouted",
					variant: "success",
					mode: "dismissable"
				});
				this.dispatchEvent(evt);
				this.dispatchEvent(
					new CustomEvent("closemodal", {
						detail: { closeModal: this.blnOpenModal }
					})
				);
			})
			.catch((error) => {
				console.log("--error--" + JSON.stringify(error));
			});
	}
}