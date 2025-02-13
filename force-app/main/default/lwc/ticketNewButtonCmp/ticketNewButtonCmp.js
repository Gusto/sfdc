import { LightningElement, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import UserId from "@salesforce/user/Id";
import ProfileName from "@salesforce/schema/User.Profile.Name";
import validProfiles from "@salesforce/label/c.Disable_Ticket_New_Profiles";
// Disable_Ticket_New_Profiles: Benefits Care,Payroll Care,Vendor CX
import errorMessage from "@salesforce/label/c.Ticket_New_Button_Skip_Message";
// Ticket_New_Button_Skip_Message: Action Restricted: Please create a ticket....

export default class TicketNewButtonCmp extends NavigationMixin(LightningElement) {
	strObjectApi = "Ticket__c";
	strRecordTypeId;
	strUserProfileName;
	strMessage = errorMessage;
	blnEnable = false;
	blnShowMessage = false;

	/** Retrieves the record type Id from the URL */
	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			this.strRecordTypeId = currentPageReference.state?.recordTypeId;
		}
	}

	/** Retrieves the Profile Name of the logged-in User and check for access */
	@wire(getRecord, { recordId: UserId, fields: [ProfileName] })
	userDetails({ error, data }) {
		if (error) {
			this.strMessage = error;
			this.blnShowMessage = true;
		} else if (data) {
			if (data.fields.Profile.value != null) {
				this.strUserProfileName = data.fields.Profile.value.fields.Name.value;
				if (validProfiles.indexOf(this.strUserProfileName) > -1) {
					this.blnShowMessage = true;
				} else {
					this.blnEnable = true;
				}
			}
		}
	}

	/** On Record save navigate to the Record detail page */
	handleSuccess(event) {
		const evt = new ShowToastEvent({
			title: "Record created",
			variant: "success"
		});
		this.dispatchEvent(evt);

		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: event.detail.id,
				actionName: "view"
			}
		});

		this.handleTabClose();
	}

	/** On cancel navigate to the object home page */
	handleReset(event) {
		this[NavigationMixin.Navigate]({
			type: "standard__objectPage",
			attributes: {
				objectApiName: "Ticket__c",
				actionName: "home"
			}
		});

		this.handleTabClose();
	}

	/** Close the current tab on record save or cancel */
	handleTabClose() {
		let blnClose = true;
		const event = new CustomEvent("closeclicked", {
			detail: { blnClose }
		});

		// Fire the custom event
		this.dispatchEvent(event);
	}
}