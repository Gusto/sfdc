import { getRecord } from "lightning/uiRecordApi";
import { LightningElement, api, wire } from "lwc";
import OOO_FIELD from "@salesforce/schema/User.Out_Of_Office__c";
import updateUserOOO from "@salesforce/apex/UserOOOController.updateUserOOO";
import { IsConsoleNavigation, getFocusedTabInfo, refreshTab } from "lightning/platformWorkspaceApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class UserOOOCmp extends LightningElement {
	@api recordId;
	blnOOO;
	blnIsLoading = true;
	@wire(IsConsoleNavigation) isConsoleNavigation;
	btnStyle = "";
	btnLabel = "";

	@wire(getRecord, { recordId: "$recordId", fields: [OOO_FIELD] })
	getUserRecord({ error, data }) {
		if (error) {
			console.log("error", error);
		} else if (data) {
			this.blnOOO = data?.fields?.Out_Of_Office__c?.value;
			this.btnStyle = this.blnOOO ? "success" : "destructive";
			this.btnLabel = this.blnOOO ? "Unset OOO" : "Set OOO";
			this.blnIsLoading = false;
		}
	}

	handleCheck(event) {
		this.blnOOO = event.target.checked;
	}

	async handleUpdate() {
		try {
			let blnNewOOOValue = !this.blnOOO;
			this.blnIsLoading = true;
			await updateUserOOO({ strUserId: this.recordId, blnIsOOO: blnNewOOOValue });
			if (!this.isConsoleNavigation) {
				return;
			}
			const evt = new ShowToastEvent({
				title: "Success",
				message: "OOO was updated",
				variant: "success"
			});
			this.dispatchEvent(evt);
			const { tabId } = await getFocusedTabInfo();
			await refreshTab(tabId, {
				includeAllSubtabs: true
			});
		} catch (error) {
			console.log("error", error);
			const evt = new ShowToastEvent({
				title: "Error",
				message: "There was an error, please contact to your admin",
				variant: "error"
			});
			this.dispatchEvent(evt);
		} finally {
			this.blnIsLoading = false;
		}
	}
}