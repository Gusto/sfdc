import { LightningElement, api, wire } from "lwc";
import { displayToast } from "c/utilityService";

export default class TaxResAddAttachmentButtonCmp extends LightningElement {
	@api recordId;
	blnShowModal = false;
	blnIsLoading = false;
	list_SelectedFiles = [];
	list_SelectedAttachments = [];
	strEmailBody;

	openEmailPublisher() {
		try {
			let evtOpenTab = new CustomEvent("opentab", {
				detail: { caseId: this.recordId, list_SelectedDocIds: this.list_SelectedFiles, list_SelectedAttachmentIds: this.list_SelectedAttachments }
			});
			this.dispatchEvent(evtOpenTab);
		} catch (error) {
			displayToast(this, "Error!", error.body.message, "error", "");
		} finally {
			this.blnIsLoading = false;
		}
	}

	closeModal(event) {
		this.list_SelectedFiles = [];
		this.list_SelectedAttachments = [];
		this.blnShowModal = false;
		this.blnIsLoading = false;
	}

	handleOk(event) {
		event.preventDefault();
		this.list_SelectedFiles = [];
		this.list_SelectedAttachments = [];

		event.detail.selectedFiles.forEach((element) => {
			this.list_SelectedFiles.push(element);
		});
		event.detail.selectedAttachments.forEach((element) => {
			this.list_SelectedAttachments.push(element);
		});
		this.openEmailPublisher();
		this.blnShowModal = false;
	}

	handleClick() {
		this.blnShowModal = true;
		this.blnIsLoading = true;
	}
}