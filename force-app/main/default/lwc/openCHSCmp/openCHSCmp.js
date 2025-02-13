import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getCHSRecordId from "@salesforce/apex/OpenCustomerHealthScoreController.getCHSRecordId";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class OpenCHSCmp extends NavigationMixin(LightningElement) {
	@api recordId;
	@track blnShowMessage = false;

	@api invoke() {
		//Call the function to get CHS record and navigate
		this.openCHS();
	}

	openCHS() {
		getCHSRecordId({ idRecord: this.recordId })
			.then((result) => {
				this.navigateToRecord(result);
			})
			.catch((error) => {
				console.log("error..." + error);
				this.showToast("Error !", "No Customer Health Score record found for this Account.", "error");
			});
	}

	navigateToRecord(recId) {
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: recId,
				actionName: "view"
			}
		});
	}

	showToast(title, message, variantType) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variantType
		});
		this.dispatchEvent(event);
	}
}