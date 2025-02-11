/*
 * Description: General LWC to show the label and result of the soql stored in General Query Counter Metadata per custom permission
 * Author: Omar Benitez
 * Date: 08/01/2024
 */
import { LightningElement, wire, track, api } from "lwc";
import loadCmp from "@salesforce/apex/GeneralQueryCounterController.loadCmp";

export default class GeneralQueryCounterCmp extends LightningElement {
	blnIsLoading = true;
	blnShowCmp = false;
	@track list_response;
	@api title;

	get titleLabel() {
		return this.title ? this.title : "General Query Counter";
	}

	@wire(loadCmp)
	load(objResponse) {
		if (objResponse.data) {
			if (Object.keys(objResponse.data).length > 0) {
				this.blnShowCmp = true;
				let list_obj = [];
				for (const [key, value] of Object.entries(objResponse.data)) {
					list_obj.push({
						label: key,
						value: value,
						style: value > 0 ? "slds-theme_success" : "slds-badge_lightest"
					});
				}
				this.list_response = list_obj;
			}
		} else if (objResponse.error) {
			console.log(objResponse.error);
			this.blnIsLoading = false;
		}
	}
}