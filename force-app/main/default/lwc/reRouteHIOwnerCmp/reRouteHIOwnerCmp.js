import { api, LightningElement, track } from "lwc";

import { CloseActionScreenEvent } from "lightning/actions";
import { displayToast } from "c/utilityService";
import updateAccount from "@salesforce/apex/UpdateAccountController.updateAccount";

export default class ReRouteHIOwnerCmp extends LightningElement {
	@api recordId;
	@track strMessage = "";
	@track strTypeOfHI = "";
	@track showOptions = true;

	get options() {
		return [
			{ label: "SBIZ Broker", value: "SBIZ Broker" },
			{ label: "MM Broker", value: "MM Broker" },
			{ label: "SBIZ New Plan", value: "SBIZ New Plan" },
			{ label: "MM New Plan", value: "MM New Plan" }
		];
	}

	handleChange(event) {
		this.strTypeOfHI = event.detail.value;
	}

	handleRender() {
		this.showOptions = false;
		// set message to display
		this.strMessage = "Checking permissions for HI Owner Assignment...";

		// check if user has permissions to update account by setting HI Owner to null
		let account = {
			Id: this.recordId,
			HI_Owner__c: null
		};

		// update account to set HI Owner as null
		updateAccount({
			objAccount: account
		})
			.then((result) => {
				// if result is successful, request for HI Owner Assignment
				if (result.blnSuccess) {
					// set message to display
					this.strMessage = "Requesting for HI Owner Assignment...";

					// set HI routing reason to "Manual Request for Routing". This will trigger HI routing
					account = {
						Id: this.recordId,
						HI_Owner__c: null,
						HI_Routing_Reason__c: "Manual Request for Routing - " + this.strTypeOfHI
					};

					// call apex method to update account
					updateAccount({
						objAccount: account
					})
						.then((result) => {
							// if result is successful, display success message
							if (result.blnSuccess) {
								displayToast(this, "Request to assign HI Owner is successfully submitted!", "", "success", "");
								this.dispatchEvent(new CloseActionScreenEvent());
							} else {
								// show error message from apex
								displayToast(this, "Error", result.strMessage, "error", "");
								this.dispatchEvent(new CloseActionScreenEvent());
							}
						})
						.catch((error) => {
							// catch exception and show error message
							this.error = error;
							displayToast(this, "Error", error.body.message, "error", "");
							this.dispatchEvent(new CloseActionScreenEvent());
						});
				} else {
					// show error message from apex
					displayToast(this, "Error", result.strMessage, "error", "");
					this.dispatchEvent(new CloseActionScreenEvent());
				}
			})
			.catch((error) => {
				// catch exception and show error message
				this.error = error;
				displayToast(this, "Error", error.body.message, "error", "");
				this.dispatchEvent(new CloseActionScreenEvent());
			});
	}
}