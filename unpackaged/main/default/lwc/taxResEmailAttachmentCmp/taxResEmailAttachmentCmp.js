import { LightningElement, wire, api } from "lwc";
import getFiles from "@salesforce/apex/TaxResCaseActionsController.getAvailableFiles";

export default class TaxResEmailAttachmentCmp extends LightningElement {
	@api recordId;
	list_AvailableFiles;
	list_SelectedFiles;
	list_SelectedAttachments;
	columns = [{ label: "Name", fieldName: "fileUrl", type: "url", typeAttributes: { label: { fieldName: "Name" }, target: "_blank" } }];

	async connectedCallback() {
		try {
			let result = await getFiles({ strCaseId: this.recordId });
			let tempData = [];
			for (var key in result) {
				let objFile = {};
				let tempList = result[key].split("=");
				objFile.Id = key;
				objFile.Name = tempList[1];
				objFile.fileUrl = "/" + key;
				objFile.Type = tempList[0];
				tempData.push(objFile);
			}
			this.list_AvailableFiles = tempData;
		} catch (error) {
			displayToast(this, "Error!", error.body.message, "error", "");
		}
	}

	getSelectedFiles(event) {
		this.list_SelectedAttachments = [];
		this.list_SelectedFiles = [];
		const selectedRows = event.detail.selectedRows;
		selectedRows.forEach((item) => {
			if (item.Type == "Attachment") {
				this.list_SelectedAttachments.push(item.Id);
			} else {
				this.list_SelectedFiles.push(item.Id);
			}
		});
	}

	closeModal(event) {
		event.preventDefault();
		const closeEvent = new CustomEvent("closemodalpopup", {});
		this.dispatchEvent(closeEvent);
	}

	handleOk(event) {
		event.preventDefault();
		const okEvent = new CustomEvent("handleokpopup", {
			detail: {
				selectedFiles: this.list_SelectedFiles,
				selectedAttachments: this.list_SelectedAttachments
			}
		});
		this.dispatchEvent(okEvent);
	}
}