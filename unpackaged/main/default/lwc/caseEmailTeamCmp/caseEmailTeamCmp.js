import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { CloseActionScreenEvent } from "lightning/actions";
import getCaseTeamMemberIds from "@salesforce/apex/CaseEmailTeamController.getCaseTeamMemberIds";
import getCurrentUserSignature from "@salesforce/apex/CaseEmailTeamController.getCurrentUserSignature";

export default class CaseEmailTeamCmp extends NavigationMixin(LightningElement) {
	@api recordId;
	blnIsLoading = true;
	signature;

	@wire(getCaseTeamMemberIds, { idCase: "$recordId" })
	loadCaseData(objResponse) {
		if (objResponse.data) {
			let strToAddresses = "";
			if (objResponse.data.length > 0) {
				strToAddresses = objResponse.data.join(",");
			}
			this.handleNewEmailCaseTeam(strToAddresses);
		} else if (objResponse.error) {
			console.log(objResponse.error);
			this.blnIsLoading = false;
		}
	}

	closeQuickAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	handleNewEmailCaseTeam(strToAddresses) {
		this.blnIsLoading = false;
		let objPageRef = {
			type: "standard__quickAction",
			attributes: {
				apiName: "Case.SendEmailLTE"
			},
			state: {
				recordId: this.recordId,
				defaultFieldValues: encodeDefaultFieldValues({
					HtmlBody: "<br/><br/> " + this.signature,
					Subject: "",
					ToIds: strToAddresses
				})
			}
		};
		this[NavigationMixin.Navigate](objPageRef);
		this.closeQuickAction();
	}

	@wire(getCurrentUserSignature)
	signatureResult({ error, data }) {
		if (data) {
			this.signature = data;
		} else if (error) {
			this.signature = undefined;
			console.error("Error retrieving signature:", error);
		}
	}
}