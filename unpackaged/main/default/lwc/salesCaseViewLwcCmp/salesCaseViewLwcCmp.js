import { LightningElement, track, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { displayToast } from "c/utilityService";
import doCaseRouting from "@salesforce/apex/SalesCaseViewController.doRouting";

import * as util from "./salesCaseViewLwcCmpUtil.js";

export * from "./salesCaseViewLwcCmpUtil.js";

export default class SalesCaseViewLwcCmp extends LightningElement {
	@api recordId;
	caseType = "";
	@track isLoading = false;
	@track blnDisabled = true;

	get list_CaseTypeOptions() {
		return util.list_CaseTypeOptions;
	}

	handleCaseTypeChange(event) {
		this.caseType = event.detail.value;

		// enable route button ONLY if case type is selected
		if (this.caseType)
			this.blnDisabled = false;
		else
			this.blnDisabled = true;
	}

	handleCaseRouting(event) {
		const blnRoute = [...this.template.querySelectorAll(`[data-name="route"]`)].reduce(util.checkInputValidity, true);
		if (blnRoute) {
			this.isLoading = true;
			// Calling the imperative Apex method
			doCaseRouting({
				idCase: this.recordId,
				strCaseType: this.caseType
			})
				.then(() => {
					displayToast(this, "SUCCESS", "Records updated", "success", "");
					this.updateRecordView();
				})
				.catch((error) => {
					if (error?.body?.message) {
						console.error(error.body.message);
						displayToast(this, error.body.message, "", "error", "sticky");
					} else if (error?.message) {
						console.error(error.message);
						displayToast(this, error.message, "", "error", "sticky");
					}
				})
				.finally(() => {
					this.isLoading = false;
				});
		}
	}

	updateRecordView() {
		setTimeout(() => {
			eval("$A.get('e.force:refreshView').fire();");
		}, 1000);
	}
}