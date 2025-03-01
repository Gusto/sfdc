import { api, LightningElement, track, wire } from "lwc";

import { CloseActionScreenEvent } from "lightning/actions";
import { displayToast } from "c/utilityService";
import updateAccount from "@salesforce/apex/UpdateAccountController.updateAccount";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import FILING_STATE from "@salesforce/schema/Account.BillingState";
import EXCLUSION_FIELD from "@salesforce/schema/Account.IsExcludedFromRealign";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
const FIELDS = [FILING_STATE, EXCLUSION_FIELD];

export default class ReRouteHIOwnerCmp extends LightningElement {
	@api recordId;
	@track strMessage = "";
	@track strTypeOfHI = "";
	@track showOptions = true;
	blnIsExcluded = false;
	strFilingState = "";

	@wire(getRecord, { recordId: "$recordId", fields: FIELDS })
	getUserRecord({ error, data }) {
		if (error) {
			console.log("error", error);
		} else if (data) {
			this.blnIsExcluded = getFieldValue(data, EXCLUSION_FIELD);
			this.strFilingState = getFieldValue(data, FILING_STATE);
		}
	}

	get options() {
		return [
			{ label: "SBIZ Broker", value: "BSB" },
			{ label: "MM Broker", value: "BMM" },
			{ label: "SBIZ New Plan", value: "SBNP" },
			{ label: "MM New Plan", value: "MMNP" }
		];
	}

	handleChange(event) {
		this.strTypeOfHI = event.detail.value;
	}

	validateData() {
		let bValid = true;
		const allValid = [...this.template.querySelectorAll("lightning-combobox")].reduce((validSoFar, inputCmp) => {
			if (!inputCmp.reportValidity()) bValid = false;
			return validSoFar;
		}, true);
		if (bValid == false) {
			return bValid;
		}
		return bValid;
	}

	handleRender() {
		if (this.validateData()) {
			this.showOptions = false;
			// set message to display
			this.strMessage = "Requesting for HI Owner Assignment...";

			// check if user has permissions to update account by setting HI Owner to null
			let account = {
				Id: this.recordId,
				HI_Owner__c: null
			};

			// update account to set HI Owner as null
			updateAccount({
				objAccount: account,
				strTypeOfHI: this.strTypeOfHI
			})
				.then((result) => {
					// if result is successful, display success message
					if (result.blnSuccess) {
						displayToast(this, "Request to assign HI Owner is successfully submitted!", "", "success", "");
						this.dispatchEvent(new CloseActionScreenEvent());
					} else {
						// show error message from apex
						displayToast(this, "Error", result.strMessage, "error", "");
						this.dispatchEvent(new CloseActionScreenEvent());
					}
				})
				.catch((error) => {
					// catch exception and show error message
					this.error = error;
					displayToast(this, "Error", error.body.message, "error", "");
					this.dispatchEvent(new CloseActionScreenEvent());
				});
		}
	}
}