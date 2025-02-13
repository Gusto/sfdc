import { LightningElement, api } from "lwc";

export default class InboundCallColumnButton extends LightningElement {
	@api objRecordName;
	@api objRecordId;
	@api rowRecordId;

	get blnRowRecordIdBlank() {
		if (!this.rowRecordId) {
			return false;
		} else {
			return true;
		}
	}
	onClickHandler() {
		const eventnew = CustomEvent("selectedrec", {
			composed: true,
			bubbles: true,
			cancelable: true,
			detail: {
				value: { objRecordName: this.objRecordName, objRecordId: this.objRecordId, rowRecordId: this.rowRecordId }
			}
		});
		this.dispatchEvent(eventnew);
	}
}