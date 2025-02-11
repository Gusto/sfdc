import { LightningElement, track, api } from "lwc";
import getAttachments from "@salesforce/apex/ViewArchivedFileController.getAttachments";
import { NavigationMixin } from "lightning/navigation";
import { sendAuraEvent } from "c/utilityService";

// This component is used to view archived files related to a record
export default class ViewArchivedFileCmp extends NavigationMixin(LightningElement) {
	// Public property to hold the record ID
	@api recordId;

	// Tracked properties to hold lists of email messages and record attachments
	@track list_EmailMessages = [];
	@track list_AllEmailMessages = [];
	@track noAttachmentsFound = false;
	@track list_RecordAttachments = [];
	@track emailView = true;
	@track blnLoading = false;
	strSobject;
	isCaseObject;
	@track emailsCheckbox = false;

	// Local properties
	viewValue = "Email";
	activeSections = [];
	attachmentExists = true;

	// Getter to provide options for the view selection
	get viewoptions() {
		return [
			{ label: "Email attachments", value: "Email" },
			{ label: "Case attachments", value: "Case" }
		];
	}

	// Lifecycle hook that is called when the component is inserted into the DOM
	connectedCallback() {
		let messageList = [];
		let attachmentList = [];
		this.blnLoading = true;

		// Call the Apex method to get attachments related to the record
		getAttachments({
			idRecord: this.recordId
		})
			.then((result) => {
				this.blnLoading = false;
				let list_EmailAttachments = result.list_Emails;
				let list_RecordAttachments = result.list_RecordAttachments;
				this.strSobject = result.strObjectType;
				this.isCaseObject = this.strSobject === "Case";
				console.log("result new ", result);

				// Process email attachments
				list_EmailAttachments.forEach((element) => {
					let clone = JSON.parse(JSON.stringify(element));
					let accordionTitle = "";
					if (clone.blnIncoming) {
						accordionTitle = "Received an incoming email from " + clone.strFromName + " at " + new Date(clone.dtMessageDate).toLocaleString();
					} else {
						accordionTitle = "Outbound email from " + clone.strFromName + " to " + clone.strToEmailAddress + " at " + new Date(clone.dtMessageDate).toLocaleString();
					}
					clone.accordionTitle = accordionTitle;
					clone.filesExists = clone.list_Files.length > 0;
					messageList.push(clone);
				});

				console.log("result ", messageList);
				// Process record attachments
				list_RecordAttachments.forEach((element) => {
					let clone = JSON.parse(JSON.stringify(element));
					attachmentList.push(clone);
				});

				// Update tracked properties with the processed lists
				this.list_EmailMessages = messageList;
				this.list_AllEmailMessages = messageList;
				this.list_RecordAttachments = attachmentList;

				// Determine if any attachments exist	
				this.attachmentExists = this.list_RecordAttachments.length > 0 || this.list_AllEmailMessages.length > 0;

				// If all email attachments don't have files, then set attachmentExists to false
				if (this.attachmentExists && this.list_AllEmailMessages.length > 0 && this.list_RecordAttachments.length == 0) {
					let fileExists = false;
					this.list_AllEmailMessages.forEach((element) => {
						if (element.filesExists) {
							fileExists = true;
						}
					});
					this.attachmentExists = fileExists;
				}


				if (this.attachmentExists) {
					this.viewValue = this.list_AllEmailMessages.length > 0 ? "Email" : "Case";
					this.emailView = this.viewValue === "Email";
					this.noAttachmentsFound = this.emailView ? this.list_EmailMessages.length === 0 : this.list_RecordAttachments.length === 0;
				}
			})
			.catch((error) => {
				this.blnLoading = false;
				console.error("Error in getting emails: ", error);
			});
	}

	// Handle the preview of a file
	handlePreview(event) {
		sendAuraEvent(this, event.target.dataset.id, "filepreview");
	}

	// Handle the download of a file
	handleDownload(event) {
		sendAuraEvent(this, event.target.dataset.id, "filedownload");
	}

	// Handle the change of the checkbox to filter email messages with attachments
	handleCheckboxChange(event) {
		this.emailsCheckbox = event.target.checked;
		let messageList = [];
		this.list_AllEmailMessages.forEach((element) => {
			if (event.target.checked) {
				if (element.list_Files.length > 0) {
					messageList.push(element);
				}
			} else {
				messageList.push(element);
			}
		});
		this.list_EmailMessages = messageList;
		this.noAttachmentsFound = this.list_EmailMessages.length === 0;
	}

	// Handle the change of the radio button to switch between email and case attachments
	handleRadioChange(event) {
		this.viewValue = event.detail.value;
		this.emailView = this.viewValue === "Email";
		this.noAttachmentsFound = this.emailView ? this.list_EmailMessages.length === 0 : this.list_RecordAttachments.length === 0;
	}
}