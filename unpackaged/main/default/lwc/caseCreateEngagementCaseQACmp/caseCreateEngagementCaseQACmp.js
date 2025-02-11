import { api, LightningElement } from "lwc";
import { getFocusedTabInfo, openSubtab } from "lightning/platformWorkspaceApi";

export default class CaseCreateEngagementCaseQACmp extends LightningElement {
	@api recordId;
	renderedCallback() {
		getFocusedTabInfo().then((tabInfo) => {
			let cmpDef = {
				componentDef: "c:caseCreateEngagementCaseWrapperCmp",
				attributes: {
					recordId: this.recordId
				}
			};
			let parentTabId = (tabInfo.parentTabId != null) ? tabInfo.parentTabId : tabInfo.tabId;
			let encodedDef = btoa(JSON.stringify(cmpDef));
			openSubtab(parentTabId, { url: "/one/one.app#" + encodedDef, icon: "utility:case", label: "Create Engagement Case" })
				.then((result) => {
					console.log("result", result);
				})
				.catch((error) => {
					console.log("error", error);
				});
		});
	}
}