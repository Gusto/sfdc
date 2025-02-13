import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
/* Imported Methods from Utility Service */
import { displayToast, sendAuraEvent } from "c/utilityService";
import getUpdatableCaseFields from "@salesforce/apex/TaxResCaseActionsController.getUpdatableCaseFields";

export default class TaxResCaseUpdateCmp extends LightningElement {
	@api recordId;
	@track blnView;
	@track blnEdit;

	blnIsLoading = true;
	list_EditableFieldAPINames;
	blnIsSendEmail = false;

	/**get the fields to be displayed from field set*/
	@wire(getUpdatableCaseFields, { strCaseId: "$recordId" })
	wiredCases({ error, data }) {
		if (data) {
			console.log("data: ", data);
			this.list_EditableFieldAPINames = data;
			console.log("this.list_EditableFieldAPINames: ", this.list_EditableFieldAPINames);
			this.blnIsLoading = false;
			this.blnView = true;
			this.blnEdit = false;
		}
	}

	/**method is called on click of "Edit" button */
	handleEditBtnClick() {
		this.blnIsLoading = true;
		this.blnView = false;
		this.blnEdit = true;
		this.blnIsLoading = false;
	}

	/**called on click of "save" button */
	handleUpdateBtnClick() {
		this.blnIsLoading = true;
	}

	/**called on click of "Cancel" button */
	handleCancelBtnClick() {
		this.blnIsLoading = true;
		this.blnEdit = false;
		this.blnView = true;
		this.blnIsLoading = false;
	}

	/**called when submit button is clicked */
	handleCaseUpdate(event) {
		event.preventDefault();
		const fields = event.detail.fields;
		this.template.querySelector("lightning-record-edit-form").submit(fields);
	}

	/**called when submit event is successfully executed */
	handleUpdateSuccess(event) {
		this.showMessage("Success!", "The Case's record has been successfully updated.", "success", null);
		this.blnIsLoading = false;
		this.blnView = true;
		this.blnEdit = false;
		location.reload();
	}

	handleError(event) {
		this.showMessage("Error!", event?.detail?.detail, "error");
		this.blnIsLoading = false;
	}

	/**handles copy to clipboard functionality */
	copyToClipBoard() {
		const objElement = document.createElement("textarea");
		objElement.value = window.location.origin + "/lightning/r/Case/" + this.recordId + "/view";
		document.body.appendChild(objElement);
		objElement.select();
		document.execCommand("copy");
		document.body.removeChild(objElement);
		displayToast(this, "Case URL copied to clipboard!", "", "success", "");
	}

	/* showMessage displays
	 * success, error or warning
	 * messages. depending on the strClassName,
	 * type fo messages will vary.
	 */
	showMessage(strTitle, strMessage, strVariant, strMode) {
		if (strMode === null) {
			strMode = "dismissible";
		}

		const evt = new ShowToastEvent({
			title: strTitle,
			message: strMessage,
			variant: strVariant,
			mode: strMode
		});

		this.dispatchEvent(evt);
	}
}