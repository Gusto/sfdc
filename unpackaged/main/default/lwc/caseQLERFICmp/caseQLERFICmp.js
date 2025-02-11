import { LightningElement, api } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import sendFirstRFI from "@salesforce/apex/CaseQLERFIController.sendFirstRFI";
import updateCase from "@salesforce/apex/CaseQLERFIController.updateCase";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getFocusedTabInfo, refreshTab } from "lightning/platformWorkspaceApi";

export default class CaseQLERFICmp extends LightningElement {
	@api recordId;
	blnIsLoading = true;
	blnIsDisabled = true;
	blnOnlySave = false;

	handleOnLoad() {
		this.blnIsLoading = false;
		this.validateFields();
	}

	handleCancelClick() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	validateFields() {
		const caseRecord = {};
		const inputFields = this.template.querySelectorAll("lightning-input-field");
		if (inputFields) {
			for (let field of inputFields) {
				if (field.value === undefined || field.value === null || field.value === "") {
					this.blnIsDisabled = true;
					if (!this.blnOnlySave) {
						return null;
					}
					caseRecord[field.name] = null;
				} else {
					caseRecord[field.name] = field.value;
				}
			}
		}
		caseRecord.Id = this.recordId;
		this.blnIsDisabled = false;
		return caseRecord;
	}

	async handleSend() {
		try {
			const { tabId } = await getFocusedTabInfo();
			this.blnIsLoading = true;
			this.blnOnlySave = false;
			const caseRecord = this.validateFields();
			if (caseRecord) {
				await sendFirstRFI({ objCaseForUpdate: caseRecord });
				this.dispatchEvent(new CloseActionScreenEvent());
				const evt = new ShowToastEvent({
					title: "Success",
					message: "RFI sent successfully",
					variant: "success"
				});
				this.dispatchEvent(evt);
			}
			await refreshTab(tabId, {
				includeAllSubtabs: true
			});
			this.blnIsLoading = false;
		} catch (e) {
			console.log(e);
			const evt = new ShowToastEvent({
				title: "Error",
				message: e.body.message,
				variant: "error"
			});
			this.dispatchEvent(evt);
		}
	}

	async handleSave() {
		try {
			const { tabId } = await getFocusedTabInfo();
			this.blnIsLoading = true;
			this.blnOnlySave = true;
			const caseRecord = this.validateFields();
			if (caseRecord) {
				await updateCase({ objCase: caseRecord });
				this.dispatchEvent(new CloseActionScreenEvent());
				const evt = new ShowToastEvent({
					title: "Success",
					message: "Case updated successfully",
					variant: "success"
				});
				this.dispatchEvent(evt);
			}
			await refreshTab(tabId, {
				includeAllSubtabs: true
			});
			this.blnOnlySave = false;
			this.blnIsLoading = false;
		} catch (e) {
			console.log(e);
			const evt = new ShowToastEvent({
				title: "Error",
				message: e.body.message,
				variant: "error"
			});
			this.dispatchEvent(evt);
		}
	}
}