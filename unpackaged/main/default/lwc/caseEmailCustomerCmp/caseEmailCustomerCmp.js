/*
 * Description: LWC component to create an email with the proper customer email
 * Author: Omar Benitez
 * Date: 11/07/2024
 */
import { LightningElement, api } from "lwc";
import createEmailCustomer from "@salesforce/apex/CaseEmailTeamController.createEmailCustomer";
import { CloseActionScreenEvent } from "lightning/actions";
import { getFocusedTabInfo, refreshTab } from "lightning/platformWorkspaceApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CaseEmailCustomerCmp extends LightningElement {
	_recordId;

	@api set recordId(value) {
		this._recordId = value;
		this.showModal();
	}

	get recordId() {
		return this._recordId;
	}

	blnIsLoading = true;

	showModal() {
		this.blnIsLoading = false;
	}

	async handleEmailCustomer() {
		this.blnIsLoading = true;
		try {
			await createEmailCustomer({ strCaseId: this.recordId });
			const { tabId } = await getFocusedTabInfo();
			const evt = new ShowToastEvent({
				title: "Success",
				message: 'Please click "Write and Email to continue." below the Email Tab',
				variant: "success"
			});
			this.dispatchEvent(evt);
			await refreshTab(tabId, {
				includeAllSubtabs: true
			});
		} catch (e) {
			console.log(e);
			const evt = new ShowToastEvent({
				title: "Error",
				message: "An error occurred while creating the email. Please try again. If the problem persists, contact your system administrator.",
				variant: "error"
			});
			this.dispatchEvent(evt);
		}
		this.dispatchEvent(new CloseActionScreenEvent());
		this.blnIsLoading = false;
	}

	handleCancelClick() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}