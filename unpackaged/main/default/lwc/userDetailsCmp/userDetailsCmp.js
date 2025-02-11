import { LightningElement, track, wire } from "lwc";
import updateUser from "@salesforce/apex/UserDetailsComponentController_LEX.updateUser";
import getUserData from "@salesforce/apex/UserDetailsComponentController_LEX.getUserData";

export default class UserDetailsComponent extends LightningElement {
	/* To track whether Out of Office Checkbox is checked or not */
	@track blnIsCheck;
	/* Flag for Spinner*/
	@track blnIsLoading = false;
	@track strMessage;
	@track blnIsError = false;
	@track blnIsMessageVisible = false;
	/* Base Class String variable - error, warning and success classes will be appended to the end */
	@track strMessageClassBase = "slds-notify_alert slds-theme_alert-texture ";

	connectedCallback() {
		// Fetches the data for logged in User every time the component is open
		this.blnIsLoading = true;
		getUserData()
			.then((result) => {
				if (result.blnIsSuccess) {
					this.blnIsCheck = result.objUser.Out_Of_Office__c;
					this.blnIsMessageVisible = false;
				} else {
					this.showMessage("Error: Reason - " + result.strMessage, "slds-theme_error");
				}
				this.blnIsError = result.blnIsSuccess;
				this.blnIsLoading = false;
			})
			.catch((error) => {
				this.blnIsLoading = false;
			});
	}

	// To check and capture whether out of office checbox is checked or not
	handleCheck(event) {
		this.blnIsCheck = event.target.checked;
	}

	//Use to update the user record
	handleUpdate() {
		this.blnIsLoading = true;
		updateUser({
			blnIsUsrOutOfOffice: this.blnIsCheck
		})
			.then((result) => {
				if (!result.blnIsSuccess) {
					this.strMessage = result.strMessage;
					this.showMessage("Error: Reason - " + result.strMessage, "slds-theme_error");
				} else {
					this.showMessage("My details updated successfully!", "slds-theme_success");
				}
				this.blnIsError = result.blnIsSuccess;
				this.blnIsLoading = false;
			})
			.catch((error) => {
				this.blnIsLoading = false;
			});
	}

	/* showMessage displays
	 * success, error or warning
	 * messages. depending on the strClassName,
	 * type fo messages will vary.
	 */
	showMessage(strMessage, strClassName) {
		this.blnIsMessageVisible = true;
		this.strMessageClass = this.strMessageClassBase + strClassName;
		this.strMessage = strMessage;
	}
}