import { api, LightningElement, wire } from "lwc";
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from "lightning/platformWorkspaceApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

export default class CaseCreateEngagementCaseWrapperCmp extends NavigationMixin(LightningElement) {
	inputVariables;
	blnIsLoading = true;
	@wire(IsConsoleNavigation) isConsoleNavigation;

	@api set recordId(value) {
		this._recordId = value;
		this.inputVariables = [
			{
				name: "recordId",
				type: "String",
				value: value
			},
			{
				name: "isFromCase",
				type: "Boolean",
				value: value.substring(0, 3) === "500" ? true : false
			}
		];
		this.blnIsLoading = false;
	}

	get recordId() {
		return this._recordId;
	}

	async closeMainTab() {
		if (!this.isConsoleNavigation) {
			return;
		}
		const { tabId } = await getFocusedTabInfo();
		await closeTab(tabId);
	}
	async handleStatusChange(event) {
		if (event.detail.status === "FINISHED") {
			const outputVariables = event.detail.outputVariables;
			let newCaseId = "";
			let newCaseNumber = "";
			for (let i = 0; i < outputVariables.length; i++) {
				const outputVar = outputVariables[i];
				if (outputVar.name == "newCaseId") {
					newCaseId = outputVar.value;
				}
				if (outputVar.name == "newCaseNumber") {
					newCaseNumber = outputVar.value;
				}
			}
			this[NavigationMixin.GenerateUrl]({
				type: "standard__recordPage",
				attributes: {
					recordId: newCaseId,
					actionName: "view"
				}
			}).then((url) => {
				const event = new ShowToastEvent({
					title: "Success!",
					variant: "success",
					mode: 'sticky',
					message: "Engagement case created. Case Number: {0}.",
					messageData: [
						{
							url,
							label: newCaseNumber
						}
					]
				});
				this.dispatchEvent(event);
				this.closeMainTab();
			});
		}
		if (event.detail.status === "ERROR") {
			console.log("Flow error");
			const evt = new ShowToastEvent({
				title: "Error",
				message: "Error creating case, please contact your administrator",
				variant: "error"
			});
			this.dispatchEvent(evt);
		}
	}
}