import { LightningElement, track, api } from "lwc";
import { displayToast } from "c/utilityService";

import showWelcomeMat from "@salesforce/apex/WelcomeMatController.showWelcomeMat";
import updateWelcomeMatPreference from "@salesforce/apex/WelcomeMatController.updateWelcomeMatPreference";

export default class SalesLightningWelcomeMatCmp extends LightningElement {
	/** decides whether welcome mat needs to be visible  **/
	@track blnShowMat = false;
	/** spinner bar for loading symbol  **/
	@track blnIsLoading = false;
	/** user preference on whether to show welcome mat again  **/
	@track blnWelcomeMatPreference = false;

	/** config object that contains content to be displayed on welcome mat  **/
	@track objConfig = {};

	@api strTeamName;
	@track blnIsSales = false;
	@track blnIsPT = false;

	connectedCallback() {
		this.blnIsLoading = true;
		showWelcomeMat({ strConfig: this.strTeamName })
			.then((result) => {
				this.blnShowMat = result.blnSuccess;
				this.blnIsLoading = false;
				this.objConfig = result.objConfig;
				this.blnIsSales = result.blnIsSales;
				this.blnIsPT = result.blnIsPT;

				if (result.blnSuccess == false && result.strMessage) {
					displayToast(this, "Error in showing welcome mat. Reason - " + result.strMessage, "", "error", "");
				}
			})
			.catch((error) => {
				// If there is an Exception, Show Error Message on the UI
				console.error("Error in SalesLightningWelcomeMatCmp - handleSave ", error);
				displayToast(this, "Error in showing welcome mat " + error.body.message, "", "error", "");
				this.blnIsLoading = false;
			});
	}

	updateWelcomeMatPreference() {
		this.blnIsLoading = true;
		updateWelcomeMatPreference({
			blnPreference: true
		})
			.then((result) => {
				displayToast(this, "Your preferences have been updated!", "", "success", "");
				this.blnIsLoading = false;
				this.blnShowMat = false;
			})
			.catch((error) => {
				// If there is an Exception, Show Error Message on the UI
				console.error("Error in SalesLightningWelcomeMatCmp - handleSave ", error);
				this.blnIsLoading = false;
			});
	}

	hideWelcomeMat() {
		if (this.blnWelcomeMatPreference) {
			this.updateWelcomeMatPreference();
		}
		this.blnShowMat = false;
	}

	handleLearnMore() {
		window.open("https://trailhead.salesforce.com/en/content/learn/modules/lightning-experience-for-salesforce-classic-users", "_blank");
	}

	handlePreferenceChange(event) {
		this.blnWelcomeMatPreference = event.target.checked;
	}
}