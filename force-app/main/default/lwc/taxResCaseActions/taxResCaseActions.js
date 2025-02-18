import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { displayToast } from "c/utilityService";
import getNBusinessDaysAfterFromToday from "@salesforce/apex/CaseUtils.getNBusinessDaysAfter";
import getLoggedInUserRole from "@salesforce/apex/TaxResChecklistController.getLoggedInUserRoleDetails";
import TransferToLSI from "@salesforce/apex/TaxResChecklistController.TransferToLSI";
import getCaseDetails from "@salesforce/apex/TaxResNoticeIndexDetailsController.getCaseDetails";
import updateCaseForPI from "@salesforce/apex/TaxResChecklistController.updateCaseForPILateDepositAutosolve";
import LateDepositAmountErrorMsg from '@salesforce/label/c.P_I_Late_Deposit_Amount_Error_Message';


const list_ShelvingFields = ["Shelved_Reason__c", "Follow_Up_Date__c"];
const PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED = "P&I Late Deposit/Amendment Partial Auto-Solve Fired";
const label = { LateDepositAmountErrorMsg };

export default class TaxResCaseActions extends LightningElement {
	@api recordId;
	//spinner boolean
	blnIsLoading = false;
	list_ShelvingFields = list_ShelvingFields;
	//Check if logged in user role is Either Coordinator or AS
	blnIsAS = false;
	blnValidate = false;
	blnIsJira = false;
	blnIsPILateDepositAutosolveEligible = false;

	//query User_role__c record of the logged in user to confirm if logged in user is Captain or not
	getLoggedInUserDetails() {
		return new Promise((resolve, reject) => {
			this.blnIsLoading = true;
			this.blnIsAS = false;

			getLoggedInUserRole({})
				.then((result) => {
					//if record is retrieved successfully
					if (result?.Id) {
						if (result.User_Skill_Team__c == "Account Specialist") {
							this.blnIsAS = true;
						}
					}
					resolve("done");
				})
				.catch((error) => {
					this.showMessage("Error!", "Error while retrieving user role data.", "error", null);
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

	//Get current case details
	getCurrentCaseDetails() {
		return new Promise((resolve, reject) => {
			this.blnIsLoading = true;
			
			getCaseDetails({strCaseId : this.recordId})
				.then((result) => {
					//if record is retrieved successfully
					if (result) {
						if (result.Mass_Email_Step__c != null && result.Mass_Email_Step__c != "" && (result.Mass_Email_Step__c).includes(PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED)) {
							this.blnIsPILateDepositAutosolveEligible = true;
						}
					}
					resolve("done");
				})
				.catch((error) => {
					displayToast(this, "Error!", "Error while retrieving Case data.", "error", "");
					console.log(error)
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

	//gets called after the page load
	connectedCallback() {
		this.getLoggedInUserDetails();
		this.getCurrentCaseDetails();
	}

	/**handle UI events like: onClick, onChange */
	handleEvents(event) {
		if (event.target.name === "cancelBtn") {
		}
		if (event.target.name === "transferToLSI") {
			this.TranferCaseToLSI();
		}

		if (event.target.name === "Shelved_Reason__c") {
			if (event.target.value === "Waiting for JIRA") {
				this.blnIsJira = true;
			} else {
				this.blnIsJira = false;
			}
		}

		if (event.target.name === "confirmAutosolve" || event.target.name === "declineAutosolve") {
			this.confirmDeclineAutosolve(event.target.name);
		}
	}

	confirmDeclineAutosolve(action) {
		return new Promise((resolve, reject) => {
			this.blnIsLoading = true;
			
			getCaseDetails({strCaseId : this.recordId})
				.then((result) => {
					//if record is retrieved successfully
					if (result) {
						if (action === "confirmAutosolve" && 
						(result.Tax_Notice_Indexs__r[0].Late_Deposit_Amount__c == null || result.Tax_Notice_Indexs__r[0].Late_Deposit_Amount__c == "")) {
							displayToast(this, "Error!", label.LateDepositAmountErrorMsg, "error", "sticky");
							this.blnIsLoading = false;
						} else {
							this.confirmAutosolve(action);
						}
					}
					resolve("done");
				})
				.catch((error) => {
					displayToast(this, "Error!", "Error while retrieving Case data.", "error", "");
					this.blnIsLoading = false;
					console.log(error)
				})
		});
	}

	confirmAutosolve(action) {
		this.blnIsLoading = true;

		updateCaseForPI({
			strAction : action,
			strObjCaseId : this.recordId
		})
		.then((result) => {
			if(result === "success") {
				displayToast(this, "Success!", "Record Updated Successfully.", "success", "");
				location.reload();
			} else {
				displayToast(this, "Error!", result, "error", "sticky");
			}
		})
		.catch((error) => {
			let errorMessage = ERROR_PROCESS;
			if (error.body && error.body.message) {
				errorMessage = error.body.message;
			}
			displayToast(this, "Error!", errorMessage, "error", "sticky");
		})
		.finally(() => {
			this.blnIsLoading = false;
		});
	}

	TranferCaseToLSI() {
		this.blnIsLoading = true;
		return new Promise((resolve, reject) => {
			TransferToLSI({
				strObjCaseId: this.recordId
			})
				.then((result) => {
					if (result === "success") {
						displayToast(this, "Success!", "The Case's has been successfully transferred.", "success", "");
					} else {
						displayToast(this, "Error!", result, "error", "");
					}
					resolve("done");
				})
				.catch((error) => {
					displayToast(this, "Error!", "Error while creating Coordinator checklists.", "error", "");
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

	//gets called on click of submit button to start the loader screen
	handleSubmitBtnClick() {
		this.blnIsLoading = true;
	}

	//methods executes on click of submit button
	handleSubmit(event) {
		event.preventDefault();
		var dt7BusinessDaysAfter;
		getNBusinessDaysAfterFromToday({ intDaysAfterBusinessDays: 7 })
			.then((result) => {
				dt7BusinessDaysAfter = result;
				const fields = event.detail.fields;
				this.blnIsLoading = true;
				this.blnValidate = false;
				//validation
				if (!fields.Shelved_Reason__c) {
					displayToast(this, "Error!", "Please select shelved reason", "error", "");
					this.blnValidate = true;
				} else if (!fields.Follow_Up_Date__c) {
					displayToast(this, "Error!", "Please enter follow up date", "error", "");
					this.blnValidate = true;
				}

				if (!this.blnValidate && fields.Follow_Up_Date__c) {
					var dtCurrentDate = new Date();
					dt7BusinessDaysAfter = new Date(dt7BusinessDaysAfter);
					var dtFollowUpDate = fields.Follow_Up_Date__c;
					dtFollowUpDate = new Date(dtFollowUpDate);
					if (fields.Shelved_Reason__c != "Waiting for customer action" && dtFollowUpDate <= dtCurrentDate) {
						displayToast(this, "Error!", "Follow up date should be greater than today", "error", "");
						this.blnValidate = true;
					} else if (fields != null && fields.Shelved_Reason__c == "Waiting for customer action" && dtFollowUpDate <= dt7BusinessDaysAfter) {
						displayToast(this, "Error!", "Follow up date should be 7 business days greater than today", "error", "");
						this.blnValidate = true;
					}
				}

				if (this.blnValidate) {
					this.blnIsLoading = false;
				}

				if (!this.blnValidate) {
					fields.Status = "Shelved";
					this.template.querySelector("lightning-record-edit-form").submit(fields);
				}
			})
			.catch((error) => {
				this.showMessage("Error!", "Error while retrieving Business hours", "error", null);
				this.blnIsLoading = false;
			});
	}

	//method is called when record is saved successfully
	handleSuccess(event) {
		if (!this.blnValidate) {
			const evt = new ShowToastEvent({
				title: "Success!",
				message: "The Case's record has been successfully shelved.",
				variant: "success"
			});
			this.dispatchEvent(evt);
			this.blnDisplaySpinner = false;
		}
		this.blnIsLoading = false;
		this.refreshFocusedTab();
	}

	//method is called when error occurs while saving the record
	handleError(event){
		this.blnIsLoading = false;
		let message = event.detail.detail;
		displayToast(this, "Error!", message, "error", "");
	}

	//method calls parent aura component method to refresh the page
	refreshFocusedTab() {
		const evtRefreshPage = new CustomEvent("refreshfocusedtab", {
			detail: { caseId: this.recordId }
		});
		// Fire the custom event
		this.dispatchEvent(evtRefreshPage);
	}
}