import { LightningElement, track, wire } from "lwc";
import Id from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import userOutOfOffice from "@salesforce/schema/User.Out_Of_Office__c";

export default class UserBannerAlerts extends LightningElement {
	blnIsOOO = false;
	@track currentUserAlias;

	@wire(getRecord, { recordId: Id, fields: [userOutOfOffice] })
	currentUserInfo({ error, data }) {
		if (data) {
			this.blnIsOOO = data.fields.Out_Of_Office__c.value;
		} else if (error) {
			this.error = error;
		}
	}
}