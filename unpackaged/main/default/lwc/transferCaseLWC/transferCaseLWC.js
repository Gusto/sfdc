import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import transferCase from "@salesforce/apex/InboundCallController.transferCase";

import { displayToast, TOAST_PARAMS, checkInputValidity } from "c/utilityService";
import * as routeUtil from "c/salesCaseViewLwcCmp";

export default class TransferCaseLWC extends LightningElement {
	@api strTaskId;
	strCaseType = "";
	blnSpinner = false;

	get list_CaseTypeOptions() {
		return routeUtil.list_CaseTypeOptions;
	}

	handleCaseTypeChange(event) {
		this.strCaseType = event.detail.value;
	}

	handleTransferCase() {
		const blnRoute = [...this.template.querySelectorAll(`[data-name="Route To"]`)].reduce(checkInputValidity, true);
		console.log(this.strTaskId);

		if (blnRoute) {
			this.blnSpinner = true;
			transferCase({ strTaskId: this.strTaskId, strCaseType: this.strCaseType })
				.then((result) => {
					this.dispatchEvent(
						new ShowToastEvent({
							title: TOAST_PARAMS.MESSAGE.SUCCESS,
							variant: TOAST_PARAMS.TYPE.SUCCESS,
							message: "Case {0} was created!",
							messageData: [
								{
									url: `/${result.Id}`,
									label: result.CaseNumber
								}
							]
						})
					);
					this.handleCancel();
				})
				.catch((error) => {
					let strErrMsg = error.body?.message || error.message;
					console.error(strErrMsg);
					displayToast(this, strErrMsg, "", TOAST_PARAMS.TYPE.ERROR, "");
				})
				.finally(() => {
					this.blnSpinner = false;
				});
		}
	}

	handleCancel() {
		this.dispatchEvent(new CustomEvent("closeQuickAction"));
	}
}