import { LightningElement, api, wire, track } from "lwc";
import getContactRolesByOrder from "@salesforce/apex/OpportunityContactRolesController.getContactRolesByOrder";
import updatePrimaryContactOnOrder from "@salesforce/apex/OpportunityContactRolesController.updatePrimaryContactOnOrder";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CustomContactRoleTable extends LightningElement {
	@api recordId;
	@track contactRoles = [];
	blnSpinner = false;

	@wire(getContactRolesByOrder, { idOrder: "$recordId" })
	wiredContactRoles({ error, data }) {
		if (data) {
			this.contactRoles = data.map((role) => ({
				Id: role.Id,
				ContactId: role.ContactId,
				ContactName: role.Contact.Name,
				Role: role.Role,
				isPrimaryContact: role.IsPrimary,
				isAdditionalContact: role.Check_Additional_POC__c
			}));
		} else if (error) {
			console.error("Error fetching contact roles:", error);
		}
	}

	handlePrimaryCheckboxChange(event) {
		const selectedId = event.target.dataset.id;

		// Update contact roles to ensure only one primary contact is selected
		this.contactRoles = this.contactRoles.map((contact) => {
			if (contact.ContactId === selectedId) {
				return { ...contact, isPrimaryContact: true, isAdditionalContact: false };
			}
			return { ...contact, isPrimaryContact: false };
		});
	}

	handleAdditionalCheckboxChange(event) {
		const selectedId = event.target.dataset.id;
		const isChecked = event.target.checked;

		// Update the selected contact's additional contact status
		this.contactRoles = this.contactRoles.map((contact) => {
			if (contact.ContactId === selectedId) {
				return {
					...contact,
					isAdditionalContact: isChecked,
					// If an additional contact is selected, uncheck the primary contact
					isPrimaryContact: isChecked ? false : contact.isPrimaryContact
				};
			}
			return contact;
		});
	}

	handleSave() {
		this.blnSpinner = true;
		const primaryContact = this.contactRoles.find((contact) => contact.isPrimaryContact);

		if (!primaryContact) {
			this.showToast("Please select a Primary Contact", "", "error");
			this.blnSpinner = false;
			return;
		}

		console.log("primaryContact ", primaryContact);
		let additionalContacts = this.contactRoles.filter((contact) => contact.isAdditionalContact).map((contact) => contact.ContactId);
		let uniqueContactsList = [...new Set(additionalContacts)];

		updatePrimaryContactOnOrder({
			idOrder: this.recordId,
			idPrimaryContact: primaryContact.ContactId,
			list_additionalContactIds: uniqueContactsList
		})
			.then(() => {
				this.showToast("Contact Roles updated successfully.", "", "success");
			})
			.catch((error) => {
				let strErrMsg = error.body?.message || error.message;
				console.error(strErrMsg);
				util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			})
			.finally(() => {
				this.blnSpinner = false;
			});
	}

	showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title,
			message,
			variant
		});
		this.dispatchEvent(event);
	}
}