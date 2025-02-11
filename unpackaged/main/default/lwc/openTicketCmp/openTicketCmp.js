import { LightningElement, api, track, wire } from "lwc";
/* Import Apex Methods */
import getOpenTicketIdWithCO from "@salesforce/apex/RelatedRecordsCtrl.getOpenTicketIdWithCO";
import { IsConsoleNavigation, openSubtab, getTabInfo, EnclosingTabId } from "lightning/platformWorkspaceApi";

export default class OpenTicketCmp extends LightningElement {
	@api recordId;
	@track strOpenTicketId = "";
	@track strOpenTicketName = "";
	
	@wire(IsConsoleNavigation) blnConsoleNavigation;

	@wire(EnclosingTabId) idParentTab;

	connectedCallback() {
		/* If any open ticket exist with carrier order then open it as a subtab */
		getOpenTicketIdWithCO({
			idCORecord: this.recordId
		}).then((result) => {
			this.strOpenTicketId = result.Id;
			this.strOpenTicketName = result.Name;
			this.openticket();
		});
	}

	/*Open ticket record as a subtab */
	async openticket() {
		const objTabInfo = await getTabInfo(this.idParentTab);
		const idPrimaryTab = objTabInfo.isSubtab ? objTabInfo.parentTabId : this.idParentTab;

		if (this.blnConsoleNavigation) {
			if (this.strOpenTicketId) {
				await openSubtab(idPrimaryTab, {
					url: "/lightning/r/Ticket__c/" + this.strOpenTicketId + "/view",
					label: this.strOpenTicketName,
					focus: true
				}).catch((error) => {
					console.log("Error in openTicketCmp LWC Component----->" + error);
				});
			}
		}
	}
}