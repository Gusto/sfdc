import { LightningElement, api, track, wire } from "lwc";
import getOpenTask from "@salesforce/apex/RelatedRecordsCtrl.getOpenTaskWithCO";
import { IsConsoleNavigation, openSubtab, getTabInfo, EnclosingTabId } from "lightning/platformWorkspaceApi";
export default class ShowAllTaskOnCO extends LightningElement {
	@api recordId;
	@track listTask = [];
	@track strValue = "";
	@track strSubject = "";
	@wire(IsConsoleNavigation) blnConsoleNavigation;
	@wire(EnclosingTabId) idParentTab;
	@track intTaskCount = 0;
	blnLoading = true;
	error = '';

	connectedCallback() {
		getOpenTask({
			idCORecord: this.recordId
		})
		.then((result) => {
			this.listTask = result;
			this.intTaskCount = this.listTask.length;
			this.blnLoading = false;
			this.error = "";
		})
		.catch((error) => {
			this.blnLoading = false;
			this.error = "Error loading tasks: " + error.body.message;
		});
	}

	/*Open Task record as a subtab */
	async openTask(event) {
		this.strValue = event.target.name;
		const objTabInfo = await getTabInfo(this.idParentTab);
		const idPrimaryTab = objTabInfo.isSubtab ? objTabInfo.parentTabId : this.idParentTab;
		if (this.strValue) {
			for (let intIndex = 0; intIndex < this.listTask.length; intIndex++) {
				if (this.listTask[intIndex].idTask == this.strValue) {
					this.strSubject = this.listTask[intIndex].strSubject;
				}
			}

			await openSubtab(idPrimaryTab, {
				url: "/lightning/r/Task/" + this.strValue + "/view",
				label: this.strSubject,
				focus: true
			}).catch((error) => {
				console.log("Error in showAllTaskOnCO LWC Component----->" + error);
			});
		}
	}
}