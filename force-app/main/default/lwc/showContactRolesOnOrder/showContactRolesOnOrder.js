import { LightningElement, api, wire, track } from "lwc";
import getContactRolesByOrder from "@salesforce/apex/OpportunityContactRolesController.getContactRolesByOrder";
import updatePrimaryContactOnOrder from "@salesforce/apex/OpportunityContactRolesController.updatePrimaryContactOnOrder";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CustomContactRoleTable extends LightningElement {
	@api recordId;
	@track contactRoles = [];

	@wire(getContactRolesByOrder, { orderId: "$recordId" })
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
		this.contactRoles = this.contactRoles.map((contact) => ({
			...contact,
			isPrimaryContact: contact.ContactId === selectedId
		}));
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
					isPrimaryContact: isChecked ? false : contact.isPrimaryContact
				};
			}
			return contact;
		});
	}

	handleSave() {
		const primaryContact = this.contactRoles.find((contact) => contact.isPrimaryContact);

		if (!primaryContact) {
			this.showToast("Error", "Please select a Primary Contact.", "error");
			return;
		}

		const additionalContacts = this.contactRoles.filter((contact) => contact.isAdditionalContact).map((contact) => contact.ContactId);

		updatePrimaryContactOnOrder({
			orderId: this.recordId,
			primaryContactId: primaryContact.ContactId,
			additionalContactIds: additionalContacts
		})
			.then(() => {
				this.showToast("Success", "Contact Roles updated successfully.", "success");
			})
			.catch((error) => {
				console.error("Error updating Primary Contact:", error.body.message);
				this.showToast("Error", error.body.message, "error");
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