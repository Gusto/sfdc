import { LightningElement, wire, api, track } from "lwc";
import getCarrierOptions from "@salesforce/apex/CaseEmailTeamController.getCarrierOptions";
import getEmailOptions from "@salesforce/apex/CaseEmailTeamController.getEmailOptions";
import updateDraft from "@salesforce/apex/CaseEmailTeamController.updateDraft";
import { CloseActionScreenEvent } from "lightning/actions";
import { getFocusedTabInfo, refreshTab } from "lightning/platformWorkspaceApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";
const FIELDS = ["Carrier__c.State__c"];

export default class CaseSendEmailToCarrierCmp extends LightningElement {
	@api recordId;
	blnIsLoading = true;
	selectedCarrier = null;
	selectedEmail;
	disableNext = true;
	fromEmail = null;

	@track
	emailOptions;

	displayInfo = {
		additionalFields: ["State__c"]
	};

	@wire(getRecord, { recordId: "$selectedCarrier", fields: FIELDS })
	carrierRecord;

	get state() {
		return this.carrierRecord?.data?.fields?.State__c?.value;
	}

	@wire(getCarrierOptions, { idCase: "$recordId" })
	loadCaseData(objResponse) {
		if (objResponse.data) {
			this.selectedEmail = null;
			this.selectedCarrier = objResponse.data.carrierId;
			this.fromEmail = objResponse.data.fromEmail;
			this.handleEmailOptions(objResponse.data.carrierId);
		} else if (objResponse.error) {
			console.log(objResponse.error);
			this.blnIsLoading = false;
		}
	}

	async handleEmailOptions(strCarrierId) {
		try {
			this.selectedEmail = null;
			let response = await getEmailOptions({ strCarrierId: strCarrierId });
			let optionsMap = [];
			for (const [key, value] of Object.entries(response)) {
				let opt = { label: value, value: key };
				optionsMap.push(opt);
			}
			this.emailOptions = optionsMap;
		} catch (e) {
			console.log(e);
		} finally {
			this.blnIsLoading = false;
		}
	}

	handleCarrierChange(event) {
		this.selectedCarrier = event.detail.recordId;
		this.handleEmailOptions(event.detail.recordId);
	}

	handleEmailChange(event) {
		this.selectedEmail = event.detail.value;
		if (this.selectedEmail !== null) {
			this.disableNext = false;
		}
	}

	async handleNewEmailCaseTeam() {
		this.blnIsLoading = true;
		try {
			let toAddress = this.selectedEmail.replaceAll(",", ";");
			let fromAddress = this.fromEmail.substring(0, this.fromEmail.indexOf(","));
			await updateDraft({ strCarrierId: this.recordId, strToAddress: toAddress, strFrom: fromAddress });
			const { tabId } = await getFocusedTabInfo();
			const evt = new ShowToastEvent({
				title: "Success",
				message: 'Please click "Write and Email to continue." below the Email Tab',
				variant: "success"
			});
			this.dispatchEvent(evt);
			this.closeQuickAction();
			await refreshTab(tabId, {
				includeAllSubtabs: true
			});
		} catch (e) {
			console.log(e);
		}
		this.blnIsLoading = false;
	}

	closeQuickAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}