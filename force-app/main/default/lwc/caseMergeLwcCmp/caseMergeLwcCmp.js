import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { updateRecord } from "lightning/uiRecordApi";
import { createRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import activateCaseAssignmentRules from "@salesforce/apex/CaseMergeLightningController.activateCaseAssignmentRules";
import insertChatterFeed from "@salesforce/apex/CaseMergeLightningController.insertChatterFeed";
import insertCaseChatterNotes from "@salesforce/apex/CaseMergeLightningController.insertCaseChatterNotes";
import ACCOUNT_FIELD from "@salesforce/schema/Case.AccountId";
import CONTACT_FIELD from "@salesforce/schema/Case.ContactId";
import ORIGIN_FIELD from "@salesforce/schema/Case.Origin";
import DIRECTION_FIELD from "@salesforce/schema/Case.Direction__c";
import SUBJECT_FIELD from "@salesforce/schema/Case.Subject";
import DESCRIPTION_FIELD from "@salesforce/schema/Case.Description";
import RECORDTYPEID_FIELD from "@salesforce/schema/Case.RecordTypeId";
import CASEREASONTYPE_FIELD from "@salesforce/schema/Case.Type";
import CASEREASONCLASS_FIELD from "@salesforce/schema/Case.Class__c";
import CASEREASONSURVEYELIGIBLE_FIELD from "@salesforce/schema/Case.Send_Survey__c";
import CASEROUTINGCASEREASON_FIELD from "@salesforce/schema/Case.Routing_Case_Reason__c";
import CASEROUTINGCASEREASONCLASSIFICATION_FIELD from "@salesforce/schema/Case.Routing_Case_Reason_Classification__c";
import CASEREASONTASKUS_FIELD from "@salesforce/schema/Case.Task_Us__c";
import CASEREASONDONOTAUTOSOLVE_FIELD from "@salesforce/schema/Case.Do_not_Auto_Solve__c";
import CASEREASONPRIORITY_FIELD from "@salesforce/schema/Case.Priority";
import SKIPSURVEY_FIELD from "@salesforce/schema/Case.Skip_Survey__c";
import OWNERID_FIELD from "@salesforce/schema/Case.OwnerId";
import PARENTID_FIELD from "@salesforce/schema/Case.ParentId";
import CASESTATUS_FIELD from "@salesforce/schema/Case.Status";
import CLOSED_REASON from "@salesforce/schema/Case.Closed_Reason__c";
import FOLLLOWUPDATETIME_FIELD from "@salesforce/schema/Case.Follow_Up_Date_Time__c";
import ID_FIELD from "@salesforce/schema/Case.Id";
import COMPLAINT_TYPE_FIELD from "@salesforce/schema/Case.Complaint_Type__c";
import Id from "@salesforce/user/Id";
import CASE_OBJECT from "@salesforce/schema/Case";
const MODERN_BANK = "Modern Bank";
export default class CaseMergeComponent extends NavigationMixin(LightningElement) {
	/** Declaring variables */
	@api openModal;
	@api recordId;
	@api strCaseReasonsToSkip;

	@track strSubject;
	@track strDescription;
	@track idLoggedInUser = Id;
	@track blnIsToggle;
	@track blnIsMergeToggle = false;
	@track blnIsLoading = false;
	@track strCaseReasonClass;
	@track blnIsCreateDisabled = true;
	@track strCaseReasonType;
	@track strCaseRecordType;
	@track blnIsRoutingEntered = false;
	@track blnCaseReasonDoNotAutoSolve;
	@track blnCaseReasonSurveyEligible;
	@track strCaseRoutingReason;
	@track strCaseReasonRoutingClassClassification;
	@track strCaseReasonPriority;
	@track strcaseReasonTaskUs;
	@track dtmFollowUpDateTime;
	@track strCustomerQuery;
	@track strActionNeeded;
	@track strOtherRelevantLinks;
	@track strReasonForFollowup;
	@track strRecordTypeName;

	//getting the data from the database

	@wire(getRecord, { recordId: "$recordId", fields: [ACCOUNT_FIELD, CONTACT_FIELD, COMPLAINT_TYPE_FIELD, SUBJECT_FIELD] })
	objOriginalCaseData;

	get strAccount() {
		return getFieldValue(this.objOriginalCaseData.data, ACCOUNT_FIELD);
	}

	get strContact() {
		return getFieldValue(this.objOriginalCaseData.data, CONTACT_FIELD);
	}

	get strComplaintType() {
		return getFieldValue(this.objOriginalCaseData.data, COMPLAINT_TYPE_FIELD);
	}

	get list_FollowUpReasons() {
		return [
			{ label: "Out of Scope", value: "Out of Scope" },
			{ label: "Information/Action Needed Beyond Phone Call", value: "Information/Action Needed Beyond Phone Call" },
			{ label: "Mineral HR", value: "Mineral HR" }
		];
	}

	@wire(getObjectInfo, { objectApiName: CASE_OBJECT })
	objectInfo;

	getRecordTypeId(recordTypeName) {
		// Returns a map of record type Ids
		const rtis = this.objectInfo.data.recordTypeInfos;
		this.strRecordTypeName = recordTypeName;
		return Object.keys(rtis).find((rti) => rtis[rti].name === recordTypeName);
	}

	handleCreate() {
		//Submit information on Server
		this.blnIsLoading = true;
		const fields = {};
		fields[ACCOUNT_FIELD.fieldApiName] = this.strAccount;
		fields[CONTACT_FIELD.fieldApiName] = this.strContact;
		fields[SUBJECT_FIELD.fieldApiName] = this.strSubject;
		fields[DESCRIPTION_FIELD.fieldApiName] = this.strDescription;
		fields[ORIGIN_FIELD.fieldApiName] = "Follow Up Email";
		fields[DIRECTION_FIELD.fieldApiName] = "Outbound";
		if (this.blnIsToggle === false) {
			fields[OWNERID_FIELD.fieldApiName] = this.idLoggedInUser;
		}
		fields[RECORDTYPEID_FIELD.fieldApiName] = this.strCaseRecordType;
		fields[CASEREASONCLASS_FIELD.fieldApiName] = this.strCaseReasonClass;
		fields[CASEREASONTYPE_FIELD.fieldApiName] = this.strCaseReasonType;
		fields[CASEREASONPRIORITY_FIELD.fieldApiName] = this.strCaseReasonPriority;
		fields[CASEREASONDONOTAUTOSOLVE_FIELD.fieldApiName] = this.blnCaseReasonDoNotAutoSolve;
		fields[CASEREASONTASKUS_FIELD.fieldApiName] = this.strcaseReasonTaskUs;
		fields[CASEREASONSURVEYELIGIBLE_FIELD.fieldApiName] = this.blnCaseReasonSurveyEligible;
		fields[CASEROUTINGCASEREASONCLASSIFICATION_FIELD.fieldApiName] = this.strCaseReasonRoutingClassClassification;
		fields[CASEROUTINGCASEREASON_FIELD.fieldApiName] = this.strCaseRoutingReason;
		fields[PARENTID_FIELD.fieldApiName] = this.recordId;
		fields[FOLLLOWUPDATETIME_FIELD.fieldApiName] = this.dtmFollowUpDateTime;
		fields["Customer_Query_Request__c"] = this.strCustomerQuery;
		fields["Action_Correction_Needed__c"] = this.strActionNeeded;
		fields["Other_Relevant_Panda_Hippo_Link__c"] = this.strOtherRelevantLinks;
		fields["Reason_for_Follow_up_Case__c"] = this.strReasonForFollowup;
		fields[COMPLAINT_TYPE_FIELD.fieldApiName] = this.strComplaintType;

		const recordInput = { apiName: CASE_OBJECT.objectApiName, fields };

		createRecord(recordInput)
			.then((result) => {
				try {
					//Create chatter post with required fields
					insertCaseChatterNotes({ strOriginalCaseId: this.recordId, strNewCaseId: result.id, map_CaseFields: fields })
						.then(() => {})
						.catch(() => {});

					if (this.blnIsToggle === true) {
						activateCaseAssignmentRules({ idCase: result.id })
							.then(() => {})
							.catch(() => {});
					}
				} catch (error) {}
				this.openModal = false;
				try {
					fields[ID_FIELD.fieldApiName] = this.recordId;

					if (this.blnIsMergeToggle === true) {
						fields[CASESTATUS_FIELD.fieldApiName] = "Closed";
						fields[SKIPSURVEY_FIELD.fieldApiName] = true;
						fields[CLOSED_REASON.fieldApiName] = "Merged Follow up Case";

						//if case is Modern Bank and Complaint Type is blank, set it to No Complaint
						if (this.strRecordTypeName === MODERN_BANK && !fields[COMPLAINT_TYPE_FIELD.fieldApiName]) {
							fields[COMPLAINT_TYPE_FIELD.fieldApiName] = "No Complaint";
						}

						//don't overwrite fields of original case
						fields[PARENTID_FIELD.fieldApiName] = null;
						delete fields[SUBJECT_FIELD.fieldApiName];
						delete fields[ORIGIN_FIELD.fieldApiName];
						delete fields[DESCRIPTION_FIELD.fieldApiName];
						delete fields["Customer_Query_Request__c"];
						delete fields["Action_Correction_Needed__c"];
						delete fields["Other_Relevant_Panda_Hippo_Link__c"];
						delete fields["Reason_for_Follow_up_Case__c"];
						const originalCaseInput = { fields };
						
						updateRecord(originalCaseInput);
					}

					let newCaseId = result.id;
					let newCaseNumber = result.fields.CaseNumber.value;
					if (this.blnIsMergeToggle === true) {
						insertChatterFeed({ idCase: this.recordId, strCaseNumber: result.fields.CaseNumber.value, strNewCaseId: newCaseId })
							.then((result) => {
								const evt = new ShowToastEvent({
									title: "Case Merged",
									message: JSON.stringify(result),
									variant: "success",
									mode: "sticky"
								});
								this.dispatchEvent(evt);
								//}
							})
							.catch(() => {});
					}
					const openprimarytab = new CustomEvent("openprimarytab", {
						detail: { newCaseId, newCaseNumber, closeAfterCreate: this.openModal }
					});
					this.dispatchEvent(openprimarytab);
				} catch (error) {}
				this.blnIsLoading = false;
			})
			.catch(() => {});
	}

	handleCancel() {
		this.openModal = false;
		this.dispatchEvent(
			new CustomEvent("closemodal", {
				detail: { closeModal: this.openModal }
			})
		);
	}

	handleClosed() {
		this.blnIsCreateDisabled = true;
	}

	closeModalForChange() {
		this.openModal = false;
	}

	handleToggle(event) {
		if (event.target.checked === true) {
			this.blnIsToggle = true;
		} else {
			this.blnIsToggle = false;
		}
	}

	handleMergeToggle(event) {
		if (event.target.checked === true) {
			this.blnIsMergeToggle = true;
		} else {
			this.blnIsMergeToggle = false;
		}
	}

	handleCaseReason(event) {
		if (event.detail.caseReasonType) {
			this.blnIsRoutingEntered = true;
			this.strCaseReasonClass = event.detail.caseReasonClass;
			this.strCaseReasonType = event.detail.caseReasonType;
			this.strcaseReasonTaskUs = event.detail.caseReasonTaskUs;
			this.blnCaseReasonSurveyEligible = event.detail.caseReasonSurveyEligible;
			this.blnCaseReasonDoNotAutoSolve = event.detail.caseReasonDoNotAutoSolve;
			this.strCaseReasonPriority = event.detail.caseReasonPriority;
			this.strCaseReasonRoutingClassClassification = event.detail.routingCaseReasonClassificationId;
			this.strCaseRoutingReason = event.detail.caseRoutingReason;
			this.strCaseRecordType = this.getRecordTypeId(event.detail.caseReasonType);
		} else {
			this.blnIsRoutingEntered = false;
		}

		this.handleOnBlur();
	}

	handleOnBlur() {
		const blnIsAllValid = [...this.template.querySelectorAll("lightning-input, lightning-textarea, lightning-combobox")].reduce((validSoFar, inputCmp) => {
			return validSoFar && inputCmp.checkValidity();
		}, true);

		if (blnIsAllValid && this.blnIsRoutingEntered) {
			this.blnIsCreateDisabled = false;
		} else {
			this.blnIsCreateDisabled = true;
		}
	}

	handleDataChange(event) {
		let strTargetName = event.target.name;
		let strValue = event.detail.value;
		switch (strTargetName) {
			case "customer-query":
				this.strCustomerQuery = strValue;
				break;
			case "action-needed":
				this.strActionNeeded = strValue;
				break;
			case "other-links":
				this.strOtherRelevantLinks = strValue;
				break;
			case "followup-reason":
				this.handleOnBlur();
				this.strReasonForFollowup = strValue;
				break;
			case "subject":
				this.strSubject = strValue;
				break;
			case "description":
				this.strDescription = strValue;
				break;
			case "followup-date":
				this.dtmFollowUpDateTime = strValue;
				break;
		}
	}
}