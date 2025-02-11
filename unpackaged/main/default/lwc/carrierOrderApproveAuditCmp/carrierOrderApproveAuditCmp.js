import { LightningElement, api, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOptions from "@salesforce/apex/CarrierOrderApproveAuditController.getOptions";
import saveOrder from "@salesforce/apex/CarrierOrderApproveAuditController.saveOrder";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from "lightning/platformWorkspaceApi";
import { reduceErrors } from "c/ldsUtils";
export default class CarrierOrderApproveAuditCmp extends LightningElement {
	_recordId;
	blnIsLoading = true;
	@track
	impStageOpts;
	@track
	impStageDetailOpts;
	selectedStage = null;
	selectedStageDetail = null;
	carrierOrder = null;
	blnHasTadaOrder = false;
	@api set recordId(value) {
		this._recordId = value;
		this.handleGetOpts();
	}

	get recordId() {
		return this._recordId;
	}

	@wire(IsConsoleNavigation) isConsoleNavigation;

	async closeTab() {
		if (!this.isConsoleNavigation) {
			return;
		}
		const { tabId } = await getFocusedTabInfo();
		await closeTab(tabId);
	}

	async handleGetOpts() {
		try {
			let response = await getOptions({ strCarrierOrderId: this._recordId });
			if (response.error !== undefined) {
				const evt = new ShowToastEvent({
					title: "Error",
					message: response.error,
					variant: "error"
				});
				this.dispatchEvent(evt);
				this.closeQuickAction();
				return;
			}

			this.selectedStage = response.implementationStage;
			let optionsMap = [];
			for (const [key, value] of Object.entries(response.implementationStageOptions)) {
				let opt = { label: value, value: key };
				optionsMap.push(opt);
			}
			this.impStageOpts = optionsMap;
			optionsMap = [];
			for (const [key, value] of Object.entries(response.implementationStageDetailOptions)) {
				let opt = { label: value, value: key };
				optionsMap.push(opt);
			}
			this.impStageDetailOpts = optionsMap;
			this.carrierOrder = response.objCarrierOrder;
			this.blnHasTadaOrder = response.blnHasTadaOrder;
		} catch (e) {
			console.log(e);
		} finally {
			this.blnIsLoading = false;
		}
	}

	async save() {
		this.blnIsLoading = true;
		let orderToSave = JSON.parse(JSON.stringify(this.carrierOrder));
		orderToSave.Implementation_Stage__c = this.selectedStage;
		orderToSave.Stage_Detail__c = this.selectedStageDetail;
		let inp = this.template.querySelectorAll("lightning-input-field");
		inp.forEach(function (element) {
			if (element.name === "notes") {
				orderToSave.Approval_Notes__c = element.value;
			} else if (element.name === "method") {
				orderToSave.Approval_Method__c = element.value;
			}
		});
		let response = await saveOrder({ objCarrierOrder: orderToSave });
		if (response !== null) {
			let errorMessages = reduceErrors(response);

			if (Array.isArray(errorMessages)) {
				errorMessages = errorMessages.join();
			}

			errorMessages = errorMessages.substring(errorMessages.indexOf("This"), errorMessages.length);
			errorMessages = errorMessages.substring(0, errorMessages.lastIndexOf(":"));
			const evt = new ShowToastEvent({
				title: "Error",
				message: errorMessages,
				variant: "error"
			});
			this.dispatchEvent(evt);
		} else {
			const evt = new ShowToastEvent({
				title: "Success",
				message: "Order updated",
				variant: "success"
			});
			this.dispatchEvent(evt);
			await notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
			this.closeQuickAction();
		}
		this.blnIsLoading = false;
	}

	closeQuickAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	handleImpStageChange(event) {
		this.selectedStage = event.detail.value;
	}

	handleImpStageDetailChange(event) {
		this.selectedStageDetail = event.detail.value;
	}
}